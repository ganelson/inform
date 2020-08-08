[Kinds::Compare::] Kind Checking.

To test whether two kinds are equivalent to each other, or failing
that, whether they are compatible with each other.

@h Definitions.

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

We test compatibility with the routine |Kinds::Compare::le|, and for convenience
we also have |Kinds::Compare::eq| to test equality and |Kinds::Compare::lt| for the case
when $K\leq L$ but $K\noteq L$, that is, for $K<L$. The main aim of this
section is to define those routines.

@ To say that $K_L$ is compatible with $K_R$ is a weaker statement.
This is the test Inform uses to see whether it will allow $K_L$ values to
be used where $K_R$ values are expected. Clearly if $K_L\leq K_R$ then
they must be compatible, but there are other possibilities. For example,
snippets can be used as texts if suitably modified ("cast")
at run-time, but snippet is not $\leq$ text. Compatibility lacks the
elegant formal properties of $\leq$: for example, "value" is compatible
with "text" which is in turn compatible with "value".

This test is performed by |Kinds::Compare::compatible|. As we will see, the two
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

@ The following constants will be used to represent the results of kind
checking:

@d ALWAYS_MATCH    2 /* provably correct at compile time */
@d SOMETIMES_MATCH 1 /* provably reduced to a check feasible at run-time */
@d NEVER_MATCH     0 /* provably incorrect at compile time */
@d NO_DECISION_ON_MATCH     -1 /* none of the above */

@h Subkinds.

=
int Kinds::Compare::le(kind *from, kind *to) {
	if (Kinds::Compare::test_kind_relation(from, to, FALSE) == ALWAYS_MATCH) return TRUE;
	return FALSE;
}

int Kinds::Compare::lt(kind *from, kind *to) {
	if (Kinds::Compare::eq(from, to)) return FALSE;
	return Kinds::Compare::le(from, to);
}

@ The following determines whether or not two kinds are the same. Clearly
all base kinds are different from each other, but in some programming
languages it's an interesting question whether different sequences of
constructors applied to these bases can ever produce an equivalent kind.
Most of the interesting cases are to do with unions (which Inform
disallows as type unsafe) and records (which Inform supports by its
"combination" operator). For example, is "combination (number, text)"
the same as "combination (text, number)"? One might also consider
whether |->| (function mapping) ought to be an associative operation, as
it would be in a language like Haskell which curried all functions.

At any rate, for Inform the answer is no: every different sequence of kind
constructors produces a different kind.

With kind variables, we take the "name" approach rather than the
"structural" approach: that is, the kind "X" (a variable) is not equivalent
to the kind "number" even if that's the current value of X.

=
int Kinds::Compare::eq(kind *K1, kind *K2) {
	int i;
	if (K1 == NULL) { if (K2 == NULL) return TRUE; return FALSE; }
	if (K2 == NULL) return FALSE;
	if (K1->construct != K2->construct) return FALSE;
	if ((K1->intermediate_result) && (K2->intermediate_result == NULL)) return FALSE;
	if ((K1->intermediate_result == NULL) && (K2->intermediate_result)) return FALSE;
	if ((K1->intermediate_result) &&
		(Kinds::Dimensions::compare_unit_sequences(
			K1->intermediate_result, K2->intermediate_result) == FALSE)) return FALSE;
	if (Kinds::get_variable_number(K1) != Kinds::get_variable_number(K2))
		return FALSE;
	for (i=0; i<MAX_KIND_CONSTRUCTION_ARITY; i++)
		if (Kinds::Compare::eq(K1->kc_args[i], K2->kc_args[i]) == FALSE)
			return FALSE;
	return TRUE;
}

@ It turns out to be useful to be able to "increment" a kind $K$, by trying to
find the $S$ such that $K < S$ but there is no $S'$ with $K<S'<S$. This is only
well-defined for kinds of object, and otherwise returns |NULL|.

=
kind *Kinds::Compare::super(kind *K) {
	#ifdef KINDS_SUPER
	return KINDS_SUPER(K);
	#else
	return NULL;
	#endif
}

@ The maximum of $K_1$ and $K_2$ is by definition the kind $M$ such that
$K_1\leq M$ and $K_2\leq M$, and there is no $M'<M$ with the same property.
This is similarly not well-defined in some cases, in which case we simply
return "value" as a safe answer.

=
kind *Kinds::Compare::max(kind *K1, kind *K2) {
	if ((Kinds::FloatingPoint::uses_floating_point(K1) == FALSE) &&
		(Kinds::FloatingPoint::uses_floating_point(K2)) &&
		(Kinds::Compare::eq(Kinds::FloatingPoint::real_equivalent(K1), K2)))
		return K2;
	if ((Kinds::FloatingPoint::uses_floating_point(K2) == FALSE) &&
		(Kinds::FloatingPoint::uses_floating_point(K1)) &&
		(Kinds::Compare::eq(Kinds::FloatingPoint::real_equivalent(K2), K1)))
		return K1;
	return Kinds::Compare::traverse_kind_poset(K1, K2, 1);
}

kind *Kinds::Compare::traverse_kind_poset(kind *K1, kind *K2, int direction) {
	if (K1 == NULL) return K2;
	if (K2 == NULL) return K1;
	kind_constructor *con = K1->construct;
	int a1 = Kinds::Constructors::arity(con), a2 = Kinds::Constructors::arity(K2->construct);
	if ((a1 > 0) || (a2 > 0)) {
		if (K2->construct != con) return K_value;
		int i;
		kind *ka[MAX_KIND_CONSTRUCTION_ARITY];
		for (i=0; i<a1; i++)
			if (con->variance[i] == COVARIANT)
				ka[i] = Kinds::Compare::traverse_kind_poset(K1->kc_args[i], K2->kc_args[i], direction);
			else
				ka[i] = Kinds::Compare::traverse_kind_poset(K1->kc_args[i], K2->kc_args[i], -direction);
		if (a1 == 1) return Kinds::unary_construction(con, ka[0]);
		else return Kinds::binary_construction(con, ka[0], ka[1]);
	} else {
		if (Kinds::Compare::le(K1, K2)) return (direction > 0)?K2:K1;
		if (Kinds::Compare::le(K2, K1)) return (direction > 0)?K1:K2;
		if (direction > 0) {
			if ((Kinds::Compare::le(K1, K_object)) && (Kinds::Compare::le(K2, K_object))) {
				kind *K;
				for (K = K1; K; K = Kinds::Compare::super(K))
					if (Kinds::Compare::le(K2, K))
						return K;
			}
		}
	}
	return K_value;
}

@ A variation on this is the accumulated maximum, used for example when
inferring the kinds of table columns by looking through entries one by one.
This is needed because the empty list has kind "list of values", and yet
should be considered for these purposes as a subkind of "list of texts".

=
kind *Kinds::Compare::accumulative_max(kind *K1, kind *K2) {
	if ((Kinds::Behaviour::definite(K1) == TRUE) && (Kinds::Behaviour::definite(K2) == FALSE) &&
		(Kinds::Compare::compatible(K2, K1) == ALWAYS_MATCH)) return K1;
	else if ((Kinds::Behaviour::definite(K2) == TRUE) && (Kinds::Behaviour::definite(K1) == FALSE) &&
		(Kinds::Compare::compatible(K1, K2) == ALWAYS_MATCH)) return K2;
	return Kinds::Compare::max(K1, K2);
}

@h Kind compatibility.
Now for a more interesting question. If $K_F$ and $K_T$ are kinds, what
values do they have in common? |Kinds::Compare::compatible| returns

(a) |ALWAYS_MATCH| if a value of kind $K_F$ can always be used when a value
of kind $K_T$ is expected,
(b) |SOMETIMES_MATCH| if it sometimes can, but this needs to be protected
by run-time checking in individual cases, or
(c) |NEVER_MATCH| if it never can.

For example, a value of kind "vehicle" can always be used when a value of
kind "object" is expected; a value of kind "object" can only sometimes
be used when a "vehicle" is expected, and any attempt to use it should
be guarded by run-time checking that is indeed a vehicle; a value of kind
"number" can never be used when a "scene" is expected.

The outer routine is just a logging mechanism for the real routine. Cases
where $K_F = K_T$ are frequent and not interesting enough to be logged.

=
int Kinds::Compare::compatible(kind *from, kind *to) {
	if (Kinds::Compare::eq(from, to)) return ALWAYS_MATCH;

	LOGIF(KIND_CHECKING, "(Is the kind $u compatible with $u?", from, to);

	switch(Kinds::Compare::test_kind_relation(from, to, TRUE)) {
		case NEVER_MATCH: LOGIF(KIND_CHECKING, " No)\n"); return NEVER_MATCH;
		case ALWAYS_MATCH: LOGIF(KIND_CHECKING, " Yes)\n"); return ALWAYS_MATCH;
		case SOMETIMES_MATCH: LOGIF(KIND_CHECKING, " Sometimes)\n"); return SOMETIMES_MATCH;
	}

	internal_error("bad return value from Kinds::Compare::compatible"); return NEVER_MATCH;
}

@h Common code.
So the following routine tests $\leq$ if |comp| is |FALSE|, returning
|ALWAYS_MATCH| if and only if $\leq$ holds; and otherwise it tests compatibility.

=
int Kinds::Compare::test_kind_relation(kind *from, kind *to, int comp) {
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
	@<Deal separately with compatibility within the objects hierarchy@>;
	@<The general case of compatibility@>;
}

@ A list is sayable if and only if its contents are.

@<Deal separately with the sayability of lists@> =
	if ((Kinds::get_construct(from) == CON_list_of) &&
		(Kinds::Compare::eq(to, K_sayable_value)))
		return Kinds::Compare::test_kind_relation(
			Kinds::unary_construction_material(from), K_sayable_value, comp);

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
	if (Kinds::Compare::eq(to, K_value)) return ALWAYS_MATCH;
	if ((comp) && (Kinds::Compare::eq(from, K_value))) return ALWAYS_MATCH;

@ |NULL| as a kind means "unknown". It's compatible only with itself
and, of course, "value".

@<Deal separately with the special role of the unknown kind@> =
	if ((to == NULL) && (from == NULL)) return ALWAYS_MATCH;
	if ((to == NULL) || (from == NULL)) return NEVER_MATCH;

@ Here both our kinds are $\leq$ "object".

@<Deal separately with compatibility within the objects hierarchy@> =
	#ifdef KINDS_COMPATIBLE
	int m = KINDS_COMPATIBLE(from, to);
	if (m != NO_DECISION_ON_MATCH) return m;
	#endif

@<The general case of compatibility@> =
	if (Kinds::Constructors::compatible(from->construct, to->construct, comp) == FALSE)
		return NEVER_MATCH;
	int f_a = Kinds::Constructors::arity(from->construct);
	int t_a = Kinds::Constructors::arity(to->construct);
	int arity = (f_a < t_a)?f_a:t_a;
	int i, o = ALWAYS_MATCH, this_o = NEVER_MATCH;
	for (i=0; i<arity; i++) {
		if (Kinds::Constructors::variance(from->construct, i) == COVARIANT)
			this_o = Kinds::Compare::test_kind_relation(from->kc_args[i], to->kc_args[i], comp);
		else
			this_o = Kinds::Compare::test_kind_relation(to->kc_args[i], from->kc_args[i], comp);
		switch (this_o) {
			case NEVER_MATCH: o = this_o; break;
			case SOMETIMES_MATCH: if (o != NEVER_MATCH) o = this_o; break;
		}
	}
	if ((o == SOMETIMES_MATCH) && (to->construct != CON_list_of)) return NEVER_MATCH;
	return o;

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
			if (Kinds::Compare::test_kind_relation(other_k,
				Kinds::get_variable_stipulation(var_k), comp) != ALWAYS_MATCH)
				return NEVER_MATCH;
			LOGIF(KIND_CHECKING, "Inferring kind variable %d from $u (declaration $u)\n",
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
			LOGIF(KIND_CHECKING, "Checking $u against kind variable %d (=$u)\n",
				other_k, vn, values_of_kind_variables[vn]);
			if (Kinds::Compare::test_kind_relation(other_k, values_of_kind_variables[vn], comp) == NEVER_MATCH)
				return NEVER_MATCH;
			else
				return ALWAYS_MATCH;
	}

@ =
void Kinds::Compare::show_variables(void) {
	LOG("Variables: ");
	int i;
	for (i=1; i<=26; i++) {
		kind *K = values_of_kind_variables[i];
		if (K == NULL) continue;
		LOG("%c=$u ", 'A'+i-1, K);
	}
	LOG("\n");
}

void Kinds::Compare::show_frame_variables(void) {
	int shown = 0;
	for (int i=1; i<=26; i++) {
		kind *K = Kinds::variable_from_context(i);
		if (K) {
			if (shown++ == 0) LOGIF(MATCHING, "Stack frame uses kind variables: ");
			LOGIF(MATCHING, "%c=$u ", 'A'+i-1, K);
		}
	}
	if (shown == 0) LOGIF(MATCHING, "Stack frame sets no kind variables");
	LOGIF(MATCHING, "\n");
}

@ =
void Kinds::Compare::make_subkind(kind *sub, kind *super) {
	#ifdef PROTECTED_MODEL_PROCEDURE
	PROTECTED_MODEL_PROCEDURE;
	#endif
	if (sub == NULL) {
		LOG("Tried to set kind to $u\n", super);
		internal_error("Tried to set the kind of a null kind");
	}
	if (Kinds::Compare::lt(sub, K_object) == FALSE) return;
	#ifdef NEW_SUBKIND_NOTIFY
	if (NEW_SUBKIND_NOTIFY(sub, super)) return;
	#endif
	kind *existing = Kinds::Compare::super(sub);
	switch (Kinds::Compare::compatible(existing, super)) {
		case NEVER_MATCH:
			LOG("Tried to make $u a kind of $u\n", sub, super);
			if (problem_count == 0)
				Kinds::problem_handler(KindUnalterable_KINDERROR,
					Kinds::Behaviour::get_superkind_set_at(sub), super, existing);
			return;
		case SOMETIMES_MATCH:
			#ifdef KINDS_TEST_WITHIN
			if (KINDS_TEST_WITHIN(super, sub)) {
				if (problem_count == 0)
					Kinds::problem_handler(KindsCircular_KINDERROR,
						Kinds::Behaviour::get_superkind_set_at(super), super, existing);
				return;
			}
			#endif
			#ifdef KINDS_MOVE_WITHIN
			KINDS_MOVE_WITHIN(sub, super);
			#endif
			Kinds::Behaviour::set_superkind_set_at(sub, current_sentence);
			LOGIF(KIND_CHANGES, "Making $u a subkind of $u\n", sub, super);
	}
}

@h Unit tests.
Some internal test cases check that the hierarchy of kinds is behaving as we expect:

=
void Kinds::Compare::log_poset(int n) {
	switch (n) {
		case 1: @<Display the subkind relation of base kinds@>; break;
		case 2: @<Display the compatibility relation of base kinds@>; break;
		case 3: @<Display the results of the superkind function@>; break;
		case 4: @<Check for poset violations@>; break;
		case 5: @<Check the maximum function@>; break;
		case 6: @<Some miscellaneous tests with a grab bag of kinds@>; break;
	}
}

@<Display the subkind relation of base kinds@> =
	LOG("The subkind relation on (base) kinds:\n");
	kind *A, *B;
	LOOP_OVER_BASE_KINDS(A) {
		int c = 0;
		LOOP_OVER_BASE_KINDS(B) {
			if ((Kinds::Compare::le(A, B)) && (Kinds::Compare::eq(A, B) == FALSE)) {
				if (c++ == 0) LOG("$u <= ", A); else LOG(", ");
				LOG("$u", B);
			}
		}
		if (c > 0) LOG("\n");
	}

@<Display the compatibility relation of base kinds@> =
	LOG("The (always) compatibility relation on (base) kinds, where it differs from <=:\n");
	kind *A, *B;
	LOOP_OVER_BASE_KINDS(A) {
		int c = 0;
		LOOP_OVER_BASE_KINDS(B) {
			if ((Kinds::Compare::compatible(A, B) == ALWAYS_MATCH) &&
				(Kinds::Compare::le(A, B) == FALSE) &&
				(Kinds::Compare::eq(A, K_value) == FALSE)) {
				if (c++ == 0) LOG("$u --> ", A); else LOG(", ");
				LOG("$u", B);
			}
		}
		if (c > 0) LOG("\n");
	}

@<Display the results of the superkind function@> =
	LOG("The superkind function applied to base kinds:\n");
	kind *A, *B;
	LOOP_OVER_BASE_KINDS(A) {
		for (B = A; B; B = Kinds::Compare::super(B))
			LOG("$u -> ", B);
		LOG("\n");
	}

@<Check for poset violations@> =
	LOG("Looking for partially ordered set violations.\n");
	kind *A, *B, *C;
	LOOP_OVER_BASE_KINDS(A)
		if (Kinds::Compare::le(A, A) == FALSE)
			LOG("Reflexivity violated: $u\n", A);
	LOOP_OVER_BASE_KINDS(A)
		LOOP_OVER_BASE_KINDS(B)
			if ((Kinds::Compare::le(A, B)) && (Kinds::Compare::le(B, A)) && (Kinds::Compare::eq(A, B) == FALSE))
				LOG("Antisymmetry violated: $u, $u\n", A, B);
	LOOP_OVER_BASE_KINDS(A)
		LOOP_OVER_BASE_KINDS(B)
			LOOP_OVER_BASE_KINDS(C)
				if ((Kinds::Compare::le(A, B)) && (Kinds::Compare::le(B, C)) && (Kinds::Compare::le(A, C) == FALSE))
					LOG("Transitivity violated: $u, $u, $u\n", A, B, C);

@<Check the maximum function@> =
	LOG("Looking for maximum violations.\n");
	kind *A, *B;
	LOOP_OVER_BASE_KINDS(A)
		LOOP_OVER_BASE_KINDS(B)
			if (Kinds::Compare::eq(Kinds::Compare::max(A, B), Kinds::Compare::max(B, A)) == FALSE)
				LOG("Fail symmetry: max($u, $u) = $u, but max($u, $u) = $u\n",
					A, B, Kinds::Compare::max(A, B), B, A, Kinds::Compare::max(B, A));
	LOOP_OVER_BASE_KINDS(A)
		LOOP_OVER_BASE_KINDS(B)
			if (Kinds::Compare::le(A, Kinds::Compare::max(A, B)) == FALSE)
				LOG("Fail maximality(A): max($u, $u) = $u\n", A, B, Kinds::Compare::max(A, B));
	LOOP_OVER_BASE_KINDS(A)
		LOOP_OVER_BASE_KINDS(B)
			if (Kinds::Compare::le(B, Kinds::Compare::max(A, B)) == FALSE)
				LOG("Fail maximality(B): max($u, $u) = $u\n", A, B, Kinds::Compare::max(A, B));
	LOOP_OVER_BASE_KINDS(A)
		if (Kinds::Compare::eq(Kinds::Compare::max(A, A), A) == FALSE)
				LOG("Fail: max($u, $u) = $u\n",
					A, A, Kinds::Compare::max(A, A));

@

@d SIZE_OF_GRAB_BAG 11

@<Some miscellaneous tests with a grab bag of kinds@> =
	#ifdef IF_MODULE
	kind *tests[SIZE_OF_GRAB_BAG];
	tests[0] = K_number;
	tests[1] = K_container;
	tests[2] = K_door;
	tests[3] = K_thing;
	tests[4] = Kinds::unary_construction(CON_list_of, K_container);
	tests[5] = Kinds::unary_construction(CON_list_of, K_door);
	tests[6] = Kinds::unary_construction(CON_list_of, K_person);
	tests[7] = Kinds::unary_construction(CON_list_of, K_thing);
	tests[8] = Kinds::binary_construction(CON_phrase,
		Kinds::binary_construction(CON_TUPLE_ENTRY, K_door, K_nil), K_object);
	tests[9] = Kinds::binary_construction(CON_phrase,
		Kinds::binary_construction(CON_TUPLE_ENTRY, K_object, K_nil), K_door);
	tests[10] = Kinds::binary_construction(CON_phrase,
		Kinds::binary_construction(CON_TUPLE_ENTRY, K_object, K_nil), K_object);
	int i, j;
	for (i=0; i<SIZE_OF_GRAB_BAG; i++) for (j=i+1; j<SIZE_OF_GRAB_BAG; j++) {
		if (Kinds::Compare::le(tests[i], tests[j])) LOG("$u <= $u\n", tests[i], tests[j]);
		if (Kinds::Compare::le(tests[j], tests[i])) LOG("$u <= $u\n", tests[j], tests[i]);
		kind *M = Kinds::Compare::max(tests[i], tests[j]);
		if (Kinds::Compare::eq(M, K_value) == FALSE) LOG("max($u, $u) = $u\n", tests[i], tests[j], M);
	}
	#endif
