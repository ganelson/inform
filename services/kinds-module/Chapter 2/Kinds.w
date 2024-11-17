[Kinds::] Kinds.

To build tree structures which represent Inform's universe of kinds.

@h Construction.
Kinds are represented by pointers to trees made up of //kind// objects, like so:

=
typedef struct kind {
	struct kind_constructor *construct; /* which can never be |NULL| */
	int kind_variable_number; /* only used if construct is |CON_KIND_VARIABLE| */
	struct unit_sequence *intermediate_result; /* only used if construct is |CON_INTERMEDIATE| */
	struct kind *kc_args[MAX_KIND_CONSTRUCTION_ARITY]; /* used if arity positive, or for |CON_KIND_VARIABLE| */
} kind;

@ Some kinds, like |number|, are atomic while others, like |relation of numbers to texts|,
are composite. Each //kind// object is formally a "construction" resulting from
applying a //kind_constructor// to other kinds. Each different possible constructor
has a fixed "arity", the number of other kinds it builds on. For example, to make
the kind |relation of texts to lists of times|, we need four constructions in
a row:
= (text)
	(nothing) --> text
	(nothing) --> time
	time --> list of times
	text, list of times --> relation of texts to lists of times
=
At each step there is only a finite choice of possible "kind constructions"
which can be made, but since there can in principle be an unlimited number
of steps, the set of all possible kinds is infinite. At each step we make
use of 0, 1 or 2 existing kinds to make a new one: this number (0, 1 or 2)
is the "arity" of the construction. These four steps have arities 0, 0, 1, 2,
and use the constructors "text", "time", "list of ..." and "relation of ... to ...".

We will often use the word "base" to refer to arity-0 constructors
(or to the kinds which use them): thus, "text" and "time" are bases,
but "list of ..." is not. We call constructors of higher arity "proper".

@ Here is //kinds-test// exercising the construction system. Note that
it has "functions" to extract the first and second term of a construction.
(The REPL language of //kinds-test// has quite a number of functions like
this, for testing different features of //kinds//.)

= (text from Figures/construction.txt as REPL)

@ In principle we could imagine constructors needing arbitrarily large
arity, or needing different arity in different usages, so the scheme of
having fixed arities in the range 0 to 2 looks limited. In practice we get
around that by using "punctuation nodes" in a kind tree. For example,
= (text)
	function ... -> ...
		CON_TUPLE_ENTRY
			text
			CON_TUPLE_ENTRY
				text
				CON_VOID
		number
=
represents |function (text, text) -> number|. Note two special constructors
used here: |CON_TUPLE_ENTRY| and |CON_NIL|. These cannot occur in isolation.
No Inform variable can have kind |CON_TUPLE_ENTRY|, for example.

@ We keep some statistics for tracking memory usage:

=
int no_base_kinds_created = 0;
int no_intermediate_kinds_created = 0;
int no_constructed_kinds_created = 0;

@ All kind structures are obtained by one of the following. First, a base
construction, one with arity 0. This makes a kind tree with a single leaf
node, of course, and that's something we need very often. So we create it
only on the first request, and cache the pointer to it with the constructor;
we can then use that same pointer on all subsequent requests.

=
kind *Kinds::base_construction(kind_constructor *con) {
	if (con == NULL) internal_error("impossible construction");
	if ((con == CON_KIND_VARIABLE) || (con == CON_INTERMEDIATE))
		internal_error("forbidden construction");
	switch (KindConstructors::arity(con)) {
		case 1:
			if (con == CON_list_of) return Kinds::unary_con(con, NULL);
			return Kinds::unary_con(con, K_value);
		case 2: return Kinds::binary_con(con, K_value, K_value);
	}
	kind **cache = KindConstructors::cache_location(con);
	if (cache) { if (*cache) return *cache; }
	kind *K;
	@<Create a raw kind structure@>;
	K->construct = con;
	if (cache) *cache = K;
	no_base_kinds_created++;
	return K;
}

@ As noted above, |CON_INTERMEDIATE| is used to store intermediate results
of calculations that are never accessible to outside source text, and have
kinds which couldn't be represented there. For example, if we evaluate
$$ E = mc^2 $$
then we may have perfectly good kinds of value to store energy, mass and
velocity, but have no kind of value for $c^2$, a velocity squared. Such
evanescent kinds are given the special constructor |CON_INTERMEDIATE|.
These are needed relatively seldom and are not cached.

=
kind *Kinds::intermediate_construction(unit_sequence *ik) {
	if (ik == NULL) internal_error("made unknown as Kinds::intermediate_construction");
	kind *K;
	@<Create a raw kind structure@>;
	K->construct = CON_INTERMEDIATE;
	K->intermediate_result = CREATE(unit_sequence);
	*(K->intermediate_result) = *ik;
	no_intermediate_kinds_created++;
	return K;
}

@ The following constructs "formal variables", that is, placeholders for the
kinds whose values will be stored in the kind variables |A| to |Z|.

=
kind *Kinds::var_construction(int N, kind *declaration) {
	if ((N == 0) || (N > MAX_KIND_VARIABLES)) internal_error("bad kind variable");
	kind *K;
	@<Create a raw kind structure@>;
	K->construct = CON_KIND_VARIABLE;
	K->kind_variable_number = N;
	K->kc_args[0] = declaration;
	return K;
}

@ That completes the possible base constructions. Proper constructions are made
using the following. For example,
= (text)
	Kinds::unary_con(CON_list_of, K_number)
=
produces a kind structure meaning "list of numbers". This is not cached
anywhere, so a second request for the same thing will produce a different copy
in memory of the same structure. Profiling shows that little memory is in
practice wasted.

=
kind *Kinds::unary_con(kind_constructor *con, kind *X) {
	kind *K;
	if (KindConstructors::arity(con) != 1) internal_error("bad unary construction");
	@<Create a raw kind structure@>;
	K->construct = con; K->kc_args[0] = X;
	no_constructed_kinds_created++;
	return K;
}

kind *Kinds::binary_con(kind_constructor *con, kind *X, kind *Y) {
	kind *K;
	if (KindConstructors::arity(con) != 2) internal_error("bad binary construction");
	@<Create a raw kind structure@>;
	K->construct = con; K->kc_args[0] = X; K->kc_args[1] = Y;
	no_constructed_kinds_created++;
	if (con == CON_phrase) {
		if ((X == NULL) || (Y == NULL)) internal_error("bad function kind");
		if (Y->construct == CON_TUPLE_ENTRY) internal_error("bizarre");
	}
	return K;
}

@ We've now seen the only ways to create a kind structure, and they share the
following initialisation:

@<Create a raw kind structure@> =
	K = CREATE(kind);
	K->construct = NULL;
	K->intermediate_result = NULL;
	K->kind_variable_number = 0;
	int i;
	for (i=0; i<MAX_KIND_CONSTRUCTION_ARITY; i++) K->kc_args[i] = NULL;

@h Constructing kinds for functions.
The following uses the above methods to put together the kind of a function,
making use of the punctuation nodes |CON_TUPLE_ENTRY| and |CON_NIL|. Note
that we use |K_nil| to represent the absence of a return kind (the "nothing"
in a function to nothing). Note also that a function from X to Y, with just
one argument, comes out as:
= (text)
	CON_phrase
		CON_TUPLE_ENTRY
			X
			CON_VOID
		Y
=
rather than as:
= (text)
	CON_phrase
		X
		Y
=
(It's more convenient to have a predictable form than to save on kind nodes.)

=
kind *Kinds::function_kind(int no_args, kind **args, kind *return_K) {
	kind *arguments_K = K_void;
	for (int i=no_args-1; i>=0; i--)
		arguments_K = Kinds::binary_con(CON_TUPLE_ENTRY, args[i], arguments_K);
	if (return_K == NULL) return_K = K_nil;
	return Kinds::binary_con(CON_phrase, arguments_K, return_K);
}

@h Constructing kinds for pairs.
Similarly, but more simply, here is the kind for an ordered pair of values:

=
kind *Kinds::pair_kind(kind *X, kind *Y) {
	return Kinds::binary_con(CON_combination, X, Y);
}

@h Iterating through kinds.
It's clearly not literally possible to iterate through kinds (there are
infinitely many) or even through base kinds (since intermediate and variable
constructions confuse the picture), but it does turn out to be convenient
to iterate through all possible constructions, wrapped up into base kind
format. Thus:

@d LOOP_OVER_BASE_KINDS(K)
	for (K=Kinds::first_base_k(); K; K = Kinds::next_base_k(K))

@ This requires the following iterator routines. Note that these will
produce base constructions using constructors of higher arity than that
(for example, it will make "list of K" as a base kind, with no arguments);
this would be unsuitable as the kind of any data, but is convenient for
drawing up the index, and so on.

=
kind *Kinds::first_base_k(void) {
	kind_constructor *con;
	LOOP_OVER(con, kind_constructor)
		if ((con != CON_KIND_VARIABLE) && (con != CON_INTERMEDIATE))
			return Kinds::base_construction(con);
	return NULL;
}

kind *Kinds::next_base_k(kind *K) {
	if (K == NULL) return NULL;
	kind_constructor *con = K->construct;
	do {
		con = NEXT_OBJECT(con, kind_constructor);
	} while ((con == CON_KIND_VARIABLE) || (con == CON_INTERMEDIATE));
	if (con == NULL) return NULL;
	return Kinds::base_construction(con);
}

@h Annotations of kinds.
Most of the time, the only annotation of a kind node is the constructor used:

=
kind_constructor *Kinds::get_construct(kind *K) {
	if (K) return K->construct;
	return NULL;
}

@ But for the benefit of intermediate and variable kind nodes, we also need:

=
int Kinds::is_intermediate(kind *K) {
	if ((K) && (K->construct == CON_INTERMEDIATE)) return TRUE;
	return FALSE;
}

int Kinds::get_variable_number(kind *K) {
	if ((K) && (K->construct == CON_KIND_VARIABLE)) return K->kind_variable_number;
	return -1;
}

kind *Kinds::get_variable_stipulation(kind *K) {
	if ((K) && (K->construct == CON_KIND_VARIABLE)) return K->kc_args[0];
	return NULL;
}

@ Two convenient wrappers for talking about the constructor used:

=
int Kinds::is_proper_constructor(kind *K) {
	if (Kinds::arity_of_constructor(K) > 0) return TRUE;
	return FALSE;
}

int Kinds::arity_of_constructor(kind *K) {
	if (K) return KindConstructors::arity(K->construct);
	return 0;
}

@ Given, say, |list of numbers|, the following returns |number|:

=
kind *Kinds::unary_construction_material(kind *K) {
	if (Kinds::arity_of_constructor(K) != 1) return NULL;
	return K->kc_args[0];
}

@ More awkwardly:

=
void Kinds::binary_construction_material(kind *K, kind **X, kind **Y) {
	if (Kinds::arity_of_constructor(K) != 2) {
		if (X) *X = NULL;
		if (Y) *Y = NULL;
	} else {
		if (X) *X = K->kc_args[0];
		if (Y) *Y = K->kc_args[1];
	}
}

@h Traversing the tree.
Here we look through a kind tree in search of a given constructor at any node.

=
int Kinds::contains(kind *K, kind_constructor *con) {
	if (K == NULL) return FALSE;
	if (K->construct == con) return TRUE;
	for (int i=0; i<MAX_KIND_CONSTRUCTION_ARITY; i++)
		if (Kinds::contains(K->kc_args[i], con))
			return TRUE;
	return FALSE;
}

@h Kind variable substitution.
Once we have determined what the kind variables stand for, we sometimes want
to perform substitution to convert (say) "relation of K to list of K" to
(say) "relation of numbers to list of numbers".

However, in order to ensure that caches are never invalidated, we are careful
never to alter a |kind| structure once it has been created; instead,
we return a different structure imitating the shape of the original.

We set the flag indicated by |changed| to |TRUE| if we make any change,
assuming that it was originally |FALSE| before the first use of this function.

=
kind *Kinds::substitute(kind *K, kind **meanings, int *changed, int contra) {
	return Kinds::substitute_inner(K, meanings, changed, contra, COVARIANT);
}
kind *Kinds::substitute_inner(kind *K, kind **meanings, int *changed, int contra,
	int way_in) {
	if (meanings == NULL) meanings = values_of_kind_variables;
	int N = Kinds::get_variable_number(K);
	if (N > 0) {
		*changed = TRUE;
		if ((contra) && (way_in == CONTRAVARIANT) && (Kinds::eq(meanings[N], K_value)))
			return K_nil;
		return meanings[N];
	}
	if (Kinds::is_proper_constructor(K)) {
		kind *X = NULL, *X_after = NULL, *Y = NULL, *Y_after = NULL;
		int tx = FALSE, ty = FALSE;
		int a = Kinds::arity_of_constructor(K);
		if (a == 1) {
			X = Kinds::unary_construction_material(K);
			X_after = Kinds::substitute_inner(X, meanings, &tx, contra,
				KindConstructors::variance(Kinds::get_construct(K), 0));
			if (tx) {
				*changed = TRUE;
				return Kinds::unary_con(K->construct, X_after);
			}
		} else {
			Kinds::binary_construction_material(K, &X, &Y);
			int vx = KindConstructors::variance(Kinds::get_construct(K), 0);
			int vy = KindConstructors::variance(Kinds::get_construct(K), 1);
			if (Kinds::get_construct(K) == CON_TUPLE_ENTRY) {
				vx = way_in; vy = way_in;
			}
			X_after = Kinds::substitute_inner(X, meanings, &tx, contra, vx);
			Y_after = Kinds::substitute_inner(Y, meanings, &ty, contra, vy);
			if ((tx) || (ty)) {
				*changed = TRUE;
				return Kinds::binary_con(K->construct, X_after, Y_after);
			}
		}
	}
	return K;
}

@h Weakening.
This operation corresponds to rounding kinds up to |W|: that is, any
subkind of |W| is replaced by |W|.

We do need to be careful over contravariance: the kind "object based rulebook
producing a number" is stronger than "thing based rulebook producing a number",
not weaker, because the K term for "K based rulebook producing L" is contravariant.

=
kind *Kinds::weaken(kind *K, kind *W) {
	if (Kinds::is_proper_constructor(K)) {
		kind *X = NULL, *Y = NULL;
		int a = Kinds::arity_of_constructor(K);
		if (a == 1) {
			X = Kinds::unary_construction_material(K);
			kind *WX = X;
			if (KindConstructors::variance(K->construct, 0) == COVARIANT) WX = Kinds::weaken(X, W);
			return Kinds::unary_con(K->construct, WX);
		} else {
			Kinds::binary_construction_material(K, &X, &Y);
			kind *WX = X, *WY = Y;
			if (KindConstructors::variance(K->construct, 0) == COVARIANT) WX = Kinds::weaken(X, W);
			if (KindConstructors::variance(K->construct, 1) == COVARIANT) WY = Kinds::weaken(Y, W);
			return Kinds::binary_con(K->construct, WX, WY);
		}
	} else {
		if ((K) && (Kinds::conforms_to(K, W)) && (Kinds::eq(K, K_nil) == FALSE) &&
			(Kinds::eq(K, K_void) == FALSE)) return W;
	}
	return K;
}

@h Property dereferencing.
Properties are sometimes nouns referring to themselves, and sometimes nouns
referring to their values, and these have different kinds. So:

=
kind *Kinds::dereference_properties(kind *K) {
	if ((K) && (K->construct == CON_property))
		return Kinds::unary_construction_material(K);
	if (Kinds::is_proper_constructor(K)) {
		kind *X = NULL, *Y = NULL;
		int a = Kinds::arity_of_constructor(K);
		if (a == 1) {
			X = Kinds::unary_construction_material(K);
			return Kinds::unary_con(K->construct,
				Kinds::dereference_properties(X));
		} else {
			Kinds::binary_construction_material(K, &X, &Y);
			return Kinds::binary_con(K->construct,
				Kinds::dereference_properties(X), Kinds::dereference_properties(Y));
		}
	}
	return K;
}

@h Creating new base kind constructors.
Inform's whole stock of constructors comes from two routes: this one, from the
source text, and another we shall see later, from the Kind Interpreter. The
following is called in response to sentences like:

>> Texture is a kind of value. A musical instrument is a kind of thing.

The word range is the name ("texture", "musical instrument"), and |super|
is the super-kind ("value", "thing").

=
kind *Kinds::new_base(wording W, kind *super) {
	#ifdef PROTECTED_MODEL_PROCEDURE
	PROTECTED_MODEL_PROCEDURE;
	#endif

	kind *K = Kinds::base_construction(
		KindConstructors::new(Kinds::get_construct(super), NULL, I"#NEW",
			BASE_CONSTRUCTOR_GRP));

	@<Use the source-text name to attach a noun to the constructor@>;

	FamiliarKinds::notice_new_kind(K, W);
	#ifdef NEW_BASE_KINDS_CALLBACK
	NEW_BASE_KINDS_CALLBACK(K, super, Kinds::Behaviour::get_identifier(K), W);
	#endif

	Kinds::make_subkind_inner(K, super);

	latest_base_kind_of_value = K;
	LOGIF(KIND_CREATIONS, "Created base kind %u\n", K);
	return K;
}

@<Use the source-text name to attach a noun to the constructor@> =
	noun *nt = NULL;
	#ifdef REGISTER_NOUN_KINDS_CALLBACK
	nt = REGISTER_NOUN_KINDS_CALLBACK(K, super, W, STORE_POINTER_kind_constructor(K->construct));
	#endif
	#ifndef REGISTER_NOUN_KINDS_CALLBACK
	nt = Nouns::new_common_noun(W, NEUTER_GENDER,
		ADD_TO_LEXICON_NTOPT + WITH_PLURAL_FORMS_NTOPT,
		KIND_SLOW_MC, STORE_POINTER_kind_constructor(K->construct), NULL);
	#endif
	KindConstructors::attach_noun(K->construct, nt);

@h Making subkinds.
This does not need to be done at creation time.

=
void Kinds::make_subkind(kind *sub, kind *super) {
	#ifdef PROTECTED_MODEL_PROCEDURE
	PROTECTED_MODEL_PROCEDURE;
	#endif
	if (sub == NULL) {
		LOG("Tried to set kind to %u\n", super);
		internal_error("Tried to set the kind of a null kind");
	}
	#ifdef HIERARCHY_VETO_MOVE_KINDS_CALLBACK
	if (HIERARCHY_VETO_MOVE_KINDS_CALLBACK(sub, super)) return;
	#endif
	kind *existing = Latticework::super(sub);
	switch (Kinds::compatible(existing, super)) {
		case NEVER_MATCH:
			LOG("Tried to make %u a kind of %u\n", sub, super);
			if (problem_count == 0)
				KindsModule::problem_handler(KindUnalterable_KINDERROR,
					Kinds::Behaviour::get_superkind_set_at(sub), NULL, super, existing);
			break;
		case SOMETIMES_MATCH:
			Kinds::make_subkind_inner(sub, super);
			break;
	}
}

void Kinds::make_subkind_inner(kind *sub, kind *super) {
	if (Kinds::eq(super, sub)) {
		if (problem_count == 0)
			KindsModule::problem_handler(KindsCircular2_KINDERROR,
				Kinds::Behaviour::get_superkind_set_at(sub), NULL, super, sub);
		return;
	}
	kind *K = super;
	while (K) {
		if (Kinds::eq(K, sub)) {
			if (problem_count == 0)
				KindsModule::problem_handler(KindsCircular_KINDERROR,
					Kinds::Behaviour::get_superkind_set_at(super), NULL, super,
					Latticework::super(sub));
			return;
		}
		K = Latticework::super(K);
	}
	#ifdef HIERARCHY_MOVE_KINDS_CALLBACK
	HIERARCHY_MOVE_KINDS_CALLBACK(sub, super);
	#endif
	Kinds::Behaviour::set_superkind_set_at(sub, current_sentence);
	LOGIF(KIND_CHANGES, "Making %u a subkind of %u\n", sub, super);
}

@h Annotating vocabulary.

=
kind *Kinds::read_kind_marking_from_vocabulary(vocabulary_entry *ve) {
	return ve->means.one_word_kind;
}
void Kinds::mark_vocabulary_as_kind(vocabulary_entry *ve, kind *K) {
	ve->means.one_word_kind = K;
	Vocabulary::set_flags(ve, KIND_FAST_MC);
	NTI::mark_vocabulary(ve, <k-kind>);
}

@h From context.
Sometimes we need to know the current values of the 26 kind variables, A
to Z: that depends on a much wider context than the |kinds| module can see,
so we need the client to help us. |v| is in the range 1 to 26. Returning
|NULL| means there is no current meaning; so if the client provides no
function to tell us, then all variables are permanently unset.

=
kind *Kinds::variable_from_context(int v) {
	#ifdef KIND_VARIABLE_FROM_CONTEXT
	return KIND_VARIABLE_FROM_CONTEXT(v);
	#endif
	#ifndef KIND_VARIABLE_FROM_CONTEXT
	return NULL;
	#endif
}

@h Equality.
It may well happen that there are two different //kind// structures in memory
which both mean (say) "list of texts", so we cannot simply test if two
|kind *| pointers are equal when we want to ask if they represent the same
kind.

The following determines whether or not two kinds are the same. Clearly
all base kinds are different from each other, but in some programming
languages it's an interesting question whether different sequences of
constructors applied to these bases can ever produce an equivalent kind.
Most of the interesting cases are to do with unions (which Inform
disallows as type unsafe) and records (which Inform supports only by its
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
int Kinds::eq(kind *K1, kind *K2) {
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
	for (int i=0; i<MAX_KIND_CONSTRUCTION_ARITY; i++)
		if (Kinds::eq(K1->kc_args[i], K2->kc_args[i]) == FALSE)
			return FALSE;
	return TRUE;
}

int Kinds::ne(kind *K1, kind *K2) {
	return (Kinds::eq(K1, K2))?FALSE:TRUE;
}

@h Conformance and compatibility.
For the distinction between these, see //What This Module Does//.

@d ALWAYS_MATCH    2 /* provably correct at compile time */
@d SOMETIMES_MATCH 1 /* provably reduced to a check feasible at run-time */
@d NEVER_MATCH     0 /* provably incorrect at compile time */

=
int Kinds::conforms_to(kind *from, kind *to) {
	if (Latticework::order_relation(from, to, FALSE) == ALWAYS_MATCH)
		return TRUE;
	return FALSE;
}

int Kinds::compatible(kind *from, kind *to) {
	if (Kinds::eq(from, to)) return ALWAYS_MATCH;

	LOGIF(KIND_CHECKING, "(Is the kind %u compatible with %u?", from, to);
	switch(Latticework::order_relation(from, to, TRUE)) {
		case NEVER_MATCH: LOGIF(KIND_CHECKING, " No)\n"); return NEVER_MATCH;
		case ALWAYS_MATCH: LOGIF(KIND_CHECKING, " Yes)\n"); return ALWAYS_MATCH;
		case SOMETIMES_MATCH: LOGIF(KIND_CHECKING, " Sometimes)\n"); return SOMETIMES_MATCH;
	}

	internal_error("bad return value from Kinds::compatible"); return NEVER_MATCH;
}
