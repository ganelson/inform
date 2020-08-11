[Latticework::] The Lattice of Kinds.

Placing a partial order on kinds according to whether one conforms to another.

@ We say that a kind $K_L$ is a subkind of $K_R$ if its values can
be used without modification at run-time in code which expects a value of
$K_R$, and write
$$ K_L \leq K_R. $$
There are many pairs of kinds where neither is compatible with the other:
for instance, it is true neither that rulebook $\leq$ text nor that text $\leq$ rulebook. So
we're using the notation $\leq$ here by analogy with partially-ordered sets
rather than with numbers. The universe of kinds does indeed form a poset
under this relation:

(a) it is reflexive ($K\leq K$);
(b) it is antisymmetric ($K\leq L$ and $L\leq K$ imply $K=L$);
(c) it is transitive ($K\leq L$ and $L\leq M$ imply $K\leq M$).

@ To say that $K_L$ is compatible with $K_R$ is a weaker statement.
This is the test Inform uses to see whether it will allow $K_L$ values to
be used where $K_R$ values are expected. Clearly if $K_L\leq K_R$ then
they must be compatible, but there are other possibilities. For example,
snippets can be used as texts if suitably modified ("cast")
at run-time, but snippet is not $\leq$ text. Compatibility lacks the
elegant formal properties of $\leq$: for example, "value" is compatible
with "text" which is in turn compatible with "value".

This test is performed by |Kinds::compatible|. As we will see, the two
relations are similarly defined, and they share most of the code.

@ A function $f$ on kinds is covariant if $K\leq L$ implies $f(K)\leq f(L)$,
and contravariant if $K\leq L$ implies $f(L)\leq f(K)$. Of course there's
no reason a function needs to be either, but the ones provided by our
kind constructors (such "list of", which maps K to list of K) always are.

@d COVARIANT 1
@d CONTRAVARIANT -1

@ Kind checking can happen for many reasons, but the most difficult case
occurs when matching phrase prototypes (a task carried out by the main
specification matcher in the next chapter). This is difficult because
it involves kind variables:

>> To add (new entry - K) to (L - list of values of kind K) ...

This matches "add 23 to L" if "L" is a list of numbers, but not if it
is a list of times.

Since kind variables can be changed only when matching phrase prototypes,
and this is not a recursive process, we can store the current definitions
of A to Z in a single array.

@d MAX_KIND_VARIABLES 27 /* we number them from 1 (A) to 26 (Z) */

= (early code)
kind *values_of_kind_variables[MAX_KIND_VARIABLES];

@ In theory the kind-checker only needs to read the values of A to Z, not
to write them. If Q is currently equal to "number", then it should check
kinds against Q exactly as if it were checking against "number". It can
indeed do this -- that's the |MATCH_KIND_VARIABLES_AS_VALUES| mode. It can
also ignore the values of kind variables and treat them as names, so that
Q matches only against Q, regardless of its current value; that's the
|MATCH_KIND_VARIABLES_AS_SYMBOLS| mode. Or it can match anything
against Q, which is |MATCH_KIND_VARIABLES_AS_UNIVERSAL| mode.

More interestingly, the kind-checker can also set the values of A to Z.
This is convenient since checking their correctness is more or less the same
thing as inferring what they seem to be in a given situation. So this is
|MATCH_KIND_VARIABLES_INFERRING_VALUES| mode.

@d MATCH_KIND_VARIABLES_AS_SYMBOLS 0
@d MATCH_KIND_VARIABLES_INFERRING_VALUES 1
@d MATCH_KIND_VARIABLES_AS_VALUES 2
@d MATCH_KIND_VARIABLES_AS_UNIVERSAL 3

=
int kind_checker_mode = MATCH_KIND_VARIABLES_AS_SYMBOLS;

@ When the kind-checker does choose a value for a variable, it not only
sets the relevant entry in the above array but also creates a note that
this has been done. (If a phrase is correctly matched by the specification
matcher, a linked list of these notes is attached to the results: thus
a match of "add 23 to L" in the example above would produce a successful
result plus a note that K has to be "list of numbers".)

=
typedef struct kind_variable_declaration {
	int kv_number; /* must be from 1 to 26 */
	struct kind *kv_value; /* must be a definite non-|NULL| kind */
	struct kind_variable_declaration *next;
	CLASS_DEFINITION
} kind_variable_declaration;

@ It turns out to be useful to be able to "increment" a kind $K$, by trying to
find the $S$ such that $K < S$ but there is no $S'$ with $K<S'<S$. This is only
well-defined for kinds of object, and otherwise returns |NULL|.

=
kind *Latticework::super(kind *K) {
	if (Kinds::eq(K, K_real_arithmetic_value)) return K_arithmetic_value;
	if (Kinds::eq(K, K_enumerated_value)) return K_sayable_value;
	if (Kinds::eq(K, K_arithmetic_value)) return K_sayable_value;
	if (Kinds::eq(K, K_pointer_value)) return K_sayable_value;
	if (Kinds::eq(K, K_sayable_value)) return K_stored_value;
	if (Kinds::eq(K, K_stored_value)) return K_value;
	if (Kinds::eq(K, K_value)) return NULL;
	if (Kinds::eq(K, K_nil)) return NULL;
	if (Kinds::eq(K, K_void)) return NULL;
	#ifdef HIERARCHY_GET_SUPER_KINDS_CALLBACK
	kind *S = HIERARCHY_GET_SUPER_KINDS_CALLBACK(K);
	if (S) return S;
	#endif
	if (Kinds::Constructors::compatible(K->construct, K_real_arithmetic_value->construct, FALSE))
		return K_real_arithmetic_value;
	if (Kinds::Constructors::compatible(K->construct, K_enumerated_value->construct, FALSE))
		return K_enumerated_value;
	if (Kinds::Constructors::compatible(K->construct, K_arithmetic_value->construct, FALSE))
		return K_arithmetic_value;
	if (Kinds::Constructors::compatible(K->construct, K_pointer_value->construct, FALSE))
		return K_pointer_value;
	if (Kinds::Constructors::compatible(K->construct, K_sayable_value->construct, FALSE))
		return K_sayable_value;
	if (Kinds::Constructors::compatible(K->construct, K_stored_value->construct, FALSE))
		return K_stored_value;
	return K_value;
}

@ The join of $K_1\lor K_2$ is by definition the kind $M$ such that
$K_1\leq M$ and $K_2\leq M$, and there is no $M'<M$ with the same property.
Note however:
(a) If one of $K_1$, $K_2$ uses floating-point and the other doesn't, then
we promote the one which doesn't before taking the join. This is useful
when inferring the kind of a constant list or column which mixes floating-point
and integer literals; recall that |number| $\not\leq$ |real number|, so
without this promotion there would be no way to join such kinds.
(b) The set of kinds is not entirely a semilattice and therefore some joins
can't be performed: in such cases we give up and return |value|, which at
least is $\geq K_1, K_2$.

=
kind *Latticework::join(kind *K1, kind *K2) {
	return Latticework::j_or_m(K1, K2, 1);
}

kind *Latticework::meet(kind *K1, kind *K2) {
	return Latticework::j_or_m(K1, K2, -1);
}

kind *Latticework::j_or_m(kind *K1, kind *K2, int direction) {
	if (K1 == NULL) return K2;
	if (K2 == NULL) return K1;
	kind_constructor *con = K1->construct;
	int a1 = Kinds::Constructors::arity(con), a2 = Kinds::Constructors::arity(K2->construct);
	if ((a1 > 0) || (a2 > 0)) {
		if (K2->construct != con) return K_value;
		kind *ka[MAX_KIND_CONSTRUCTION_ARITY];
		for (int i=0; i<a1; i++)
			if (con->variance[i] == COVARIANT)
				ka[i] = Latticework::j_or_m(K1->kc_args[i], K2->kc_args[i], direction);
			else
				ka[i] = Latticework::j_or_m(K1->kc_args[i], K2->kc_args[i], -direction);
		if (a1 == 1) return Kinds::unary_construction(con, ka[0]);
		else return Kinds::binary_construction(con, ka[0], ka[1]);
	} else {
		if ((Kinds::eq(K1, K_nil))) return (direction > 0)?K2:K1;
		if ((Kinds::eq(K2, K_nil))) return (direction > 0)?K1:K2;
		if ((Kinds::FloatingPoint::uses_floating_point(K1) == FALSE) &&
			(Kinds::FloatingPoint::uses_floating_point(K2)) &&
			(Kinds::eq(Kinds::FloatingPoint::real_equivalent(K1), K2)))
			return (direction > 0)?K2:K1;
		if ((Kinds::FloatingPoint::uses_floating_point(K2) == FALSE) &&
			(Kinds::FloatingPoint::uses_floating_point(K1)) &&
			(Kinds::eq(Kinds::FloatingPoint::real_equivalent(K2), K1)))
			return (direction > 0)?K1:K2;
		if (Kinds::conforms_to(K1, K2)) return (direction > 0)?K2:K1;
		if (Kinds::conforms_to(K2, K1)) return (direction > 0)?K1:K2;
		if (direction > 0)
			for (kind *K = K1; K; K = Latticework::super(K))
				if (Kinds::conforms_to(K2, K))
					return K;
	}
	return (direction > 0)?K_value:K_nil;
}

@h Common code.
So the following routine tests $\leq$ if |comp| is |FALSE|, returning
|ALWAYS_MATCH| if and only if $\leq$ holds; and otherwise it tests compatibility.

=
int Latticework::order_relation(kind *from, kind *to, int allow_casts) {
	if (Kinds::get_variable_number(to) > 0) {
		kind *var_k = to, *other_k = from;
		@<Deal separately with matches against kind variables@>;
	}
	if (Kinds::get_variable_number(from) > 0) {
		kind *var_k = from, *other_k = to;
		@<Deal separately with matches against kind variables@>;
	}
	@<Deal separately with the sayability of lists@>;
	@<Deal separately with the special role of value@>;
	@<Deal separately with the special role of the unknown kind@>;
	@<The general case of compatibility@>;
}

@ A list is sayable if and only if it is empty, or its contents are sayable.

@<Deal separately with the sayability of lists@> =
	if ((Kinds::get_construct(from) == CON_list_of) &&
		(Kinds::eq(to, K_sayable_value))) {
		kind *CK = Kinds::unary_construction_material(from);
		if (Kinds::eq(CK, K_nil)) return ALWAYS_MATCH;
		if (CK == NULL) return ALWAYS_MATCH; /* for an internal test case making dodgy lists */
		return Latticework::order_relation(CK, K_sayable_value, allow_casts);
	}

@ "Value" is special because, for every kind $K$, we have $K\leq V$ -- it
represents a supremum in our partially ordered set of kinds.

But it is also used in Inform to mark places where type safety has
deliberately been put aside. For compatibility purposes, then, giving
something the kind "value" is a way of saying that we don't care what its
kind is, and we always allow the usage. So "value" is compatible with
everything -- which is one reason compatibility isn't a partial ordering:
"value" is compatible with "number" and vice versa, yet they are
different kinds.

@<Deal separately with the special role of value@> =
	if (Kinds::eq(to, K_value)) return ALWAYS_MATCH;
	if (Kinds::eq(from, K_nil)) return ALWAYS_MATCH;

@ |NULL| as a kind means "unknown". It's compatible only with itself
and, of course, "value".

@<Deal separately with the special role of the unknown kind@> =
	if ((to == NULL) && (from == NULL)) return ALWAYS_MATCH;
	if ((to == NULL) || (from == NULL)) return NEVER_MATCH;

@<The general case of compatibility@> =
	int f_a = Kinds::Constructors::arity(from->construct);
	int t_a = Kinds::Constructors::arity(to->construct);
	int arity = (f_a < t_a)?f_a:t_a;
	int o = ALWAYS_MATCH;
	if (from->construct != to->construct)
		o = Latticework::construct_viable(from, to, allow_casts);
	int i, this_o = NEVER_MATCH, fallen = FALSE;
	for (i=0; i<arity; i++) {
		if (Kinds::Constructors::variance(from->construct, i) == COVARIANT)
			this_o = Latticework::order_relation(from->kc_args[i], to->kc_args[i], allow_casts);
		else {
			this_o = Latticework::order_relation(to->kc_args[i], from->kc_args[i], allow_casts);
		}
		switch (this_o) {
			case NEVER_MATCH: o = this_o; break;
			case SOMETIMES_MATCH: if (o != NEVER_MATCH) { o = this_o; fallen = TRUE; } break;
		}
	}
	if ((o == fallen) && (to->construct != CON_list_of)) return NEVER_MATCH;
	return o;

@ =
int Latticework::construct_viable(kind *from, kind *to, int allow_casts) {
	kind *K = from;
	while (K) {
		if (Kinds::eq(K, to)) return ALWAYS_MATCH;
		K = Latticework::super(K);
	}
	if ((allow_casts) && (Kinds::Constructors::find_cast(from->construct, to->construct)))
		return ALWAYS_MATCH;
	K = to;
	while (K) {
		if (Kinds::eq(K, from)) {
			#ifdef HIERARCHY_ALLOWS_SOMETIMES_MATCH_KINDS_CALLBACK
			if (HIERARCHY_ALLOWS_SOMETIMES_MATCH_KINDS_CALLBACK(from))
				return SOMETIMES_MATCH;
			#endif
			#ifndef HIERARCHY_ALLOWS_SOMETIMES_MATCH_KINDS_CALLBACK
			return SOMETIMES_MATCH;
			#endif
		}
		K = Latticework::super(K);
	}
	return NEVER_MATCH;
}

@ Recall that kind variables are identified by a number in the range 1 ("A")
to 26 ("Z"), and that it is also possible to assign them a domain, or a
"declaration". This marks that they are free to take on a value, within
that domain. For example, in

>> To add (new entry - K) to (L - list of values of kind K) ...

the first appearance of "K" will be an ordinary use of a kind variable,
whereas the second has the declaration "value" -- meaning that it can
become any kind matching "value". (It could alternatively have had a
more restrictive declaration like "arithmetic value".)

@<Deal separately with matches against kind variables@> =
	switch(kind_checker_mode) {
		case MATCH_KIND_VARIABLES_AS_SYMBOLS:
			if (Kinds::get_variable_number(other_k) ==
				Kinds::get_variable_number(var_k)) return ALWAYS_MATCH;
			return NEVER_MATCH;
		case MATCH_KIND_VARIABLES_AS_UNIVERSAL: return ALWAYS_MATCH;
		default: {
			int vn = Kinds::get_variable_number(var_k);
			if (Kinds::get_variable_stipulation(var_k))
				@<Act on a declaration usage, where inference is allowed@>
			else
				@<Act on an ordinary usage, where inference is not allowed@>;
		}
	}

@ When the specification matcher works on matching text such as

>> add 23 to the scores list;

it works through the prototype:

>> To add (new entry - K) to (L - list of values of kind K) ...

in two passes. On the first pass, it tries to match the tokens "23" and
"scores list" against "K" and "list of values of kind K" respectively
in |MATCH_KIND_VARIABLES_INFERRING_VALUES| mode; on the second pass, it
does the same in |MATCH_KIND_VARIABLES_AS_VALUES| mode. In this example,
on the first pass we infer (from the kind of "scores list", which is
indeed a list of numbers) that K must be "number"; on the second pass
we verify that "23" is a K.

The following shows what happens matching "values of kind K", which is
a declaration usage of the variable K.

@<Act on a declaration usage, where inference is allowed@> =
	switch(kind_checker_mode) {
		case MATCH_KIND_VARIABLES_INFERRING_VALUES:
			if (Latticework::order_relation(other_k,
				Kinds::get_variable_stipulation(var_k), allow_casts) != ALWAYS_MATCH)
				return NEVER_MATCH;
			LOGIF(KIND_CHECKING, "Inferring kind variable %d from %u (declaration %u)\n",
				vn, other_k, Kinds::get_variable_stipulation(var_k));
			values_of_kind_variables[vn] = other_k;
			kind_variable_declaration *kvd = CREATE(kind_variable_declaration);
			kvd->kv_number = vn;
			kvd->kv_value = other_k;
			kvd->next = NULL;
			return ALWAYS_MATCH;
		case MATCH_KIND_VARIABLES_AS_VALUES: return ALWAYS_MATCH;
	}

@ Whereas this is what happens when matching just "K". On the inference pass,
we always make a match, which is legitimate because we know we are going to
make a value-checking pass later.

@<Act on an ordinary usage, where inference is not allowed@> =
	switch(kind_checker_mode) {
		case MATCH_KIND_VARIABLES_INFERRING_VALUES: return ALWAYS_MATCH;
		case MATCH_KIND_VARIABLES_AS_VALUES:
			LOGIF(KIND_CHECKING, "Checking %u against kind variable %d (=%u)\n",
				other_k, vn, values_of_kind_variables[vn]);
			if (Latticework::order_relation(other_k, values_of_kind_variables[vn], allow_casts) == NEVER_MATCH)
				return NEVER_MATCH;
			else
				return ALWAYS_MATCH;
	}

@

=
void Latticework::show_variables(void) {
	LOG("Variables: ");
	int i;
	for (i=1; i<=26; i++) {
		kind *K = values_of_kind_variables[i];
		if (K == NULL) continue;
		LOG("%c=%u ", 'A'+i-1, K);
	}
	LOG("\n");
}

void Latticework::show_frame_variables(void) {
	int shown = 0;
	for (int i=1; i<=26; i++) {
		kind *K = Kinds::variable_from_context(i);
		if (K) {
			if (shown++ == 0) LOGIF(MATCHING, "Stack frame uses kind variables: ");
			LOGIF(MATCHING, "%c=%u ", 'A'+i-1, K);
		}
	}
	if (shown == 0) LOGIF(MATCHING, "Stack frame sets no kind variables");
	LOGIF(MATCHING, "\n");
}
