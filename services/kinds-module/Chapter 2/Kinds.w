[Kinds::] Kinds.

To build tree structures which represent Inform's universe of kinds.

@ Finally, then, it's time to define what a kind node looks like:

=
typedef struct kind {
	struct kind_constructor *construct; /* which can never be |NULL| */
	int kind_variable_number; /* only used if construct is |CON_KIND_VARIABLE| */
	struct unit_sequence *intermediate_result; /* only used if construct is |CON_INTERMEDIATE| */
	struct kind *kc_args[MAX_KIND_CONSTRUCTION_ARITY]; /* used if arity positive, or for |CON_KIND_VARIABLE| */
} kind;

@ We keep some statistics for tracking memory usage:

=
int no_base_kinds_created = 0;
int no_intermediate_kinds_created = 0;
int no_constructed_kinds_created = 0;

@h Constructing kinds.
All kind structures are obtained by one of the following. First, a base
construction, one with arity 0. This makes a kind tree with a single leaf
node, of course, and that's something we need very often. So we create it
only on the first request, and cache the pointer to it with the constructor;
we can then use that same pointer on all subsequent requests.

=
kind *Kinds::base_construction(kind_constructor *con) {
	if (con == NULL) internal_error("impossible construction");
	if ((con == CON_KIND_VARIABLE) || (con == CON_INTERMEDIATE))
		internal_error("forbidden construction");
	switch (Kinds::Constructors::arity(con)) {
		case 1:
			if (con == CON_list_of) return Kinds::unary_construction(con, NULL);
			return Kinds::unary_construction(con, K_value);
		case 2: return Kinds::binary_construction(con, K_value, K_value);
	}
	kind **cache = Kinds::Constructors::cache_location(con);
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

@ Kind variables A to Z (where |N| is 1 to 26 below) can usually stand for
any kind, but can also be marked with a "declaration", usually
constraining what kind of value they are allowed to hold. For example, K
might be marked as being an arithmetical kind of value. See "Kind
Checking.w".

=
kind *Kinds::variable_construction(int N, kind *declaration) {
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
	Kinds::unary_construction(CON_list_of, K_number)
=
produces a kind structure meaning "list of numbers". This is not cached
anywhere, so a second request for the same thing will produce a different copy
in memory of the same structure. Profiling shows that little memory is in
practice wasted.

=
kind *Kinds::unary_construction(kind_constructor *con, kind *X) {
	kind *K;
	if (Kinds::Constructors::arity(con) != 1) internal_error("bad unary construction");
	@<Create a raw kind structure@>;
	K->construct = con; K->kc_args[0] = X;
	no_constructed_kinds_created++;
	return K;
}

kind *Kinds::binary_construction(kind_constructor *con, kind *X, kind *Y) {
	kind *K;
	if (Kinds::Constructors::arity(con) != 2) internal_error("bad binary construction");
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
			CON_NIL
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
	kind *arguments_K = K_nil;
	for (int i=no_args-1; i>=0; i--)
		arguments_K = Kinds::binary_construction(CON_TUPLE_ENTRY, args[i], arguments_K);
	if (return_K == NULL) return_K = K_nil;
	return Kinds::binary_construction(CON_phrase, arguments_K, return_K);
}

@h Constructing kinds for pairs.
Similarly, but more simply, here is the kind for an ordered pair of values:

=
kind *Kinds::pair_kind(kind *X, kind *Y) {
	return Kinds::binary_construction(CON_combination, X, Y);
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
	if (K) return Kinds::Constructors::arity(K->construct);
	return 0;
}

@ Given, say, "list of numbers", the following returns "number":

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
		if ((contra) && (way_in == CONTRAVARIANT) && (Kinds::Compare::eq(meanings[N], K_value)))
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
				Kinds::Constructors::variance(Kinds::get_construct(K), 0));
			if (tx) {
				*changed = TRUE;
				return Kinds::unary_construction(K->construct, X_after);
			}
		} else {
			Kinds::binary_construction_material(K, &X, &Y);
			int vx = Kinds::Constructors::variance(Kinds::get_construct(K), 0);
			int vy = Kinds::Constructors::variance(Kinds::get_construct(K), 1);
			if (Kinds::get_construct(K) == CON_TUPLE_ENTRY) {
				vx = way_in; vy = way_in;
			}
			X_after = Kinds::substitute_inner(X, meanings, &tx, contra, vx);
			Y_after = Kinds::substitute_inner(Y, meanings, &ty, contra, vy);
			if ((tx) || (ty)) {
				*changed = TRUE;
				return Kinds::binary_construction(K->construct, X_after, Y_after);
			}
		}
	}
	return K;
}

@h Weakening.
This operation corresponds to rounding kinds up to |W|: that is, any
subkind of |W| is replaced by |W|.

=
kind *Kinds::weaken(kind *K, kind *W) {
	if (Kinds::is_proper_constructor(K)) {
		kind *X = NULL, *Y = NULL;
		int a = Kinds::arity_of_constructor(K);
		if (a == 1) {
			X = Kinds::unary_construction_material(K);
			return Kinds::unary_construction(K->construct, Kinds::weaken(X, W));
		} else {
			Kinds::binary_construction_material(K, &X, &Y);
			return Kinds::binary_construction(K->construct, Kinds::weaken(X, W), Kinds::weaken(Y, W));
		}
	} else {
		if ((K) && (Kinds::Compare::lt(K, W))) return W;
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
			return Kinds::unary_construction(K->construct,
				Kinds::dereference_properties(X));
		} else {
			Kinds::binary_construction_material(K, &X, &Y);
			return Kinds::binary_construction(K->construct,
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
kind *Kinds::new_base(parse_node_tree *T, wording W, kind *super) {
	#ifdef PROTECTED_MODEL_PROCEDURE
	PROTECTED_MODEL_PROCEDURE;
	#endif

	kind *K = Kinds::base_construction(
		Kinds::Constructors::new(T, Kinds::get_construct(super), NULL, I"#NEW"));

	@<Use the source-text name to attach a noun to the constructor@>;

	FamiliarKinds::notice_new_kind(K, W);
	#ifdef NEW_BASE_KINDS_CALLBACK
	NEW_BASE_KINDS_CALLBACK(K, super, Kinds::Behaviour::get_name_in_template_code(K), W);
	#endif

	#ifdef HIERARCHY_MOVE_KINDS_CALLBACK
	HIERARCHY_MOVE_KINDS_CALLBACK(K, super);
	#endif

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
	Kinds::Constructors::attach_noun(K->construct, nt);

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
Sometimes we need to kmow the current values of the 26 kind variables, A
to Z: that depemds on a much wider context than the |kinds| module can see,
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
