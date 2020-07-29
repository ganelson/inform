[Kinds::] Kinds.

To build tree structures which represent Inform's universe of kinds.

@h Definitions.

@ Inform has a rich universe of kinds: "number", "list of texts",
"relation of texts to lists of times", and so on. We can regard
each valid kind as the outcome of a series of constructions performed on
existing kinds. Here, for example, we get to out destination with four
constructions in a row:
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
is the "arity" of the construction. These four steps have arities 0, 0, 1, 2.

@d MAX_KIND_CONSTRUCTION_ARITY 2

@ Inform stores the possible constructions in |kind_constructor| structures;
about 40 of these are used to provide the built-in range of kinds, and come
in a mixture of arities. (The four constructions above all use built-in
constructors.) Further constructors are added each time the source text
creates a new kind. For example,

>> A weight is a kind of value. A mammal is a kind of animal.

creates two new constructors:
= (text)
	(nothing) --> weight
	(nothing) --> animal
=
At present these additional constructors all have arity 0. High-level Inform 7
source is not currently able to define new constructors of higher arity;
I6 template code can do this (and that's how the built-in set is defined),
and it may be that future developments of Inform will bring this ability up
to source text level.

@ A given kind is represented in Inform by a pointer to a |kind| tree.
A |NULL| pointer is a valid kind, and means "unknown".

Each node in the tree has a pointer (|->construct|) to the kind constructor
used to make it; this is never null. In the case of two special
constructors, there are further annotations (see below). The number of
downward branches at the node is equal to the arity of the constructor
being used; so the kind "number" is represented by a single leaf node:
= (text)
	number
=
whereas "relation of texts to lists of times" is represented by a tree of
four nodes like so:
= (text)
	relation of K to L
		text
		list of K
			time
=
@ We will often use the word "base" to refer to arity-0 constructors
(or to the kinds which use them): thus, "text" and "time" are bases,
but "list of K" is not. We call constructors of higher arity "proper".

It would be neat if there were exactly one |kind| structure somewhere in
memory for each different kind -- if that were true then we could compare
two kinds for equality simply by comparing pointers, and by definition it
would use the least possible memory. But in practice we don't do this,
because (i) it's too slow and tricky to arrange, (ii) we want to abstract
the testing process with the |Kinds::Compare::eq| function in case of later changes,
and (iii) careful use of caches where access is fast enable us to reduce
memory waste, mostly through intermediates but sometimes constructors, to
only a very small percentage in typical Inform usage -- say about 2K on a
medium-sized source text like "Bronze", which is not worth economising.

@ In principle we could imagine constructors needing arbitrarily large
arity, or needing different arity in different usages, so the scheme of
having fixed arities in the range 0 to 2 looks limited. In practice we get
around that by using "punctuation nodes" in the tree. For example,
= (text)
	function K -> L
		CON_TUPLE_ENTRY
			text
			CON_TUPLE_ENTRY
				text
				CON_NIL
		number
=
represents |function (text, text) -> number|. Note two special constructors
used here: |CON_TUPLE_ENTRY| and |CON_NIL|. These are called "punctuation";
they cannot appear in isolation -- see below.

@ In the Inform source code, we're clearly going to need to refer to some
of these kinds. The compiler provides support for, say, parsing times of
day, or for indexing scenes, which go beyond the generic facilities it
provides for kinds created in source text. We adopt two naming conventions:

(i) Kinds are written as |K_source_text_name|, that is, |K_| followed by
the name of the kind in I7 source text, with spaces made into underscores.
For instance, |K_number|. These are all |kind *| global variables
which are initially |NULL|, but which, once set, are never changed.

(ii) Constructors are likewise written as |CON_source_text_name| if they can
be created in source text; or by |CON_TEMPLATE_NAME|, that is, |CON_|
followed by the constructor's identifier as given in the I6 template file
which created it (but with the |_TY| suffix removed) if not. For instance,
|CON_list_of| means the constructor able to make, e.g., "list of texts";
|CON_TUPLE_ENTRY| refers to the constructor created by the |TUPLE_ENTRY_TY|
block in the |Load-Core.i6t| template file. These are all |kind_constructor
*| global variables which are initially |NULL|, but which, once set, are
never changed.

We will now define all of the |K_...| and |CON_...| used by the core of
Inform. (Others are created and used within specific plugins.)

@ We begin with some base kinds which are "kinds of kinds" useful in
generic programming.

|K_value| is a superhero, or perhaps a supervillain: it matches values of
every kind. Not being a kind in its own right, it can't be the kind of a
variable -- which is just as well, since no use of such a variable could
ever be safe.

The finer distinctions |K_word_value| and |K_pointer_value| are used to
divide all run-time data into two very different storage implementations:
(a) those where instances are stored as word-value data, where a single I6 value
holds the whole thing, like "number";
(b) those where instances are stored as pointers to larger blocks of data on the
heap, like "stored action".

= (early code)
kind *K_value = NULL;
kind *K_word_value = NULL;
kind *K_pointer_value = NULL;
kind *K_sayable_value = NULL;

@ The following refer to values subject to arithmetic operations (drawn with a
little calculator icon in the Kinds index), and those which are implemented as
enumerations of named constants. (This includes, e.g., scenes and figure names
but not objects, whose run-time storage is not a simple numerical enumeration,
or truth states, which are stored as 0 and 1 not 1 and 2. In particular, it
isn't the same thing as having a finite range in the Kinds index.)

= (early code)
kind *K_arithmetic_value = NULL;
kind *K_real_arithmetic_value = NULL; /* those using real, not integer, arithmetic */
kind *K_enumerated_value = NULL;

@h Next, the two constructors used to punctuate tuples, that is, collections
$(K_1, K_2, ..., K_n)$ of kinds of value. |CON_NIL| represents the empty
tuple, where $n=0$; while |CON_TUPLE_ENTRY| behaves like a kind constructor
with arity 2, its two bases being the first item and the rest, respectively.
Thus we store $(A, B, C)$ as
= (text)
	CON_TUPLE_ENTRY(A, CON_TUPLE_ENTRY(B, CON_TUPLE_ENTRY(C, CON_NIL)))
=
This traditional LISP-like device enables us to store tuples of arbitrary
size without need for any constructor of arity greater than 2.

(a) Inform has no "nil" or "void" kind visible to the writer of source
text, though it does occasionally use a kind it calls |K_nil| internally
to represent this idea -- for instance for a rulebook producing nothing;
|K_nil| is the kind constructed by |CON_NIL|.

(b) Inform does allow combinations, but they're identified by trees headed
by the constructor |CON_combination|, which then uses punctuation in its own
subtree. You might guess that an ordered pair of a text and a time would be
represented by the |CON_TUPLE_ENTRY| constructor on its own, but it isn't.

= (early code)
kind *K_nil = NULL;
kind_constructor *CON_NIL = NULL;
kind_constructor *CON_TUPLE_ENTRY = NULL;

@ It was mentioned above that two special constructors carry additional
annotations with them. The first of these is |CON_INTERMEDIATE|, used to
represent kinds which are brought into being through uncompleted arithmetic
operations: see "Dimensions.w" for a full discussion. Such a node in a
kind tree might represent "area divided by time squared", say, and it must
be annotated to show exactly which intermediate kind is meant.

=
kind_constructor *CON_INTERMEDIATE = NULL;

@ While that doesn't significantly change the kinds system, the second special
constructor certainly does. This is |CON_KIND_VARIABLE|, annotated to show
which of the 26 kind variables it represents in any given situation. These
variables are, in effect, wildcards; each is marked with a "kind of kind"
as its range of possible values. (Thus a typical use of this constructor
might result in a kind node labelled as L, which can be any kind matching
"arithmetic value".)

= (early code)
kind_constructor *CON_KIND_VARIABLE = NULL;

@ So much for the exotica: back onto familiar ground for anyone who uses
Inform. Some standard kinds:

= (early code)
kind *K_action_name = NULL;
kind *K_equation = NULL;
kind *K_grammatical_gender = NULL;
kind *K_natural_language = NULL;
kind *K_number = NULL;
kind *K_object = NULL;
kind *K_real_number = NULL;
kind *K_response = NULL;
kind *K_snippet = NULL;
kind *K_stored_action = NULL;
kind *K_table = NULL;
kind *K_text = NULL;
kind *K_truth_state = NULL;
kind *K_unicode_character = NULL;
kind *K_use_option = NULL;
kind *K_verb = NULL;

@ And here are two more standard kinds, but which most Inform uses don't
realise are there, because they are omitted from the Kinds index:

(a) |K_rulebook_outcome|. Rulebooks end in success, failure, no outcome, or
possibly one of a range of named alternative outcomes. These all share a
single namespace, and the names in question share a single kind of value.
It's not a very elegant system, and we really don't want people storing
these in variables; we want them to be used only as part of the process of
receiving the outcome back. So although there's no technical reason why this
kind shouldn't be used for storage, it's hidden from the user.

(b) |K_understanding| is used to hold the result of a grammar token. An actual
constant value specification of this kind stores a |grammar_verb *| pointer.
It's an untidy internal device which may well be removed later.

= (early code)
kind *K_rulebook_outcome = NULL;
kind *K_understanding = NULL;

@ Finally, the constructors used by Inform authors:

= (early code)
kind_constructor *CON_list_of = NULL;
kind_constructor *CON_description = NULL;
kind_constructor *CON_relation = NULL;
kind_constructor *CON_rule = NULL;
kind_constructor *CON_rulebook = NULL;
kind_constructor *CON_activity = NULL;
kind_constructor *CON_phrase = NULL;
kind_constructor *CON_property = NULL;
kind_constructor *CON_table_column = NULL;
kind_constructor *CON_combination = NULL;
kind_constructor *CON_variable = NULL;

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
		if ((X->construct == CON_TUPLE_ENTRY) && (X->kc_args[0] == K_nil))
			internal_error("nil nil");
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
	int i;
	for (i=no_args-1; i>=0; i--)
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
	int i;
	for (i=0; i<MAX_KIND_CONSTRUCTION_ARITY; i++)
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
kind *Kinds::substitute(kind *K, kind **meanings, int *changed) {
	if (meanings == NULL) meanings = values_of_kind_variables;
	int N = Kinds::get_variable_number(K);
	if (N > 0) {
		*changed = TRUE;
		return meanings[N];
	}
	if (Kinds::is_proper_constructor(K)) {
		kind *X = NULL, *X_after = NULL, *Y = NULL, *Y_after = NULL;
		int tx = FALSE, ty = FALSE;
		int a = Kinds::arity_of_constructor(K);
		if (a == 1) {
			X = Kinds::unary_construction_material(K);
			X_after = Kinds::substitute(X, meanings, &tx);
			if (tx) {
				*changed = TRUE;
				return Kinds::unary_construction(K->construct, X_after);
			}
		} else {
			Kinds::binary_construction_material(K, &X, &Y);
			X_after = Kinds::substitute(X, meanings, &tx);
			Y_after = Kinds::substitute(Y, meanings, &ty);
			if ((tx) || (ty)) {
				*changed = TRUE;
				return Kinds::binary_construction(K->construct, X_after, Y_after);
			}
		}
	}
	return K;
}

@h Weakening.
This operation corresponds to rounding kinds up to "object": that is, any
subkind of "object" is replaced by "object".

=
kind *Kinds::weaken(kind *K) {
	if (Kinds::is_proper_constructor(K)) {
		kind *X = NULL, *Y = NULL;
		int a = Kinds::arity_of_constructor(K);
		if (a == 1) {
			X = Kinds::unary_construction_material(K);
			return Kinds::unary_construction(K->construct, Kinds::weaken(X));
		} else {
			Kinds::binary_construction_material(K, &X, &Y);
			return Kinds::binary_construction(K->construct, Kinds::weaken(X), Kinds::weaken(Y));
		}
	} else {
		if ((K) && (Kinds::Compare::lt(K, K_object))) return K_object;
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

@ Inform builds "natural language" in so that it can create an instance for
each natural language whose bundle it can find. "Grammatical gender" is used
as a kind whose name coincides with a property.

=
<notable-linguistic-kinds> ::=
	natural language |
	grammatical gender |
	grammatical tense |
	narrative viewpoint |
	grammatical case

@h Creating new base kind constructors.
Inform's whole stock of constructors comes from two routes: this one, from the
source text, and another we shall see later, from the Kind Interpreter. The
following is called in response to sentences like:

>> Texture is a kind of value. A musical instrument is a kind of thing.

The word range is the name ("texture", "musical instrument"), and |super|
is the super-kind ("value", "thing").

=
int no_kinds_of_object = 1;
kind *Kinds::new_base(parse_node_tree *T, wording W, kind *super) {
	#ifdef PROTECTED_MODEL_PROCEDURE
	PROTECTED_MODEL_PROCEDURE;
	#endif

	kind *K = Kinds::base_construction(
		Kinds::Constructors::new(T, Kinds::get_construct(super), NULL, I"#NEW"));
	@<Renew the subject if necessary to cope with an early subject creation@>;

	#ifdef CORE_MODULE
	if (Kinds::Compare::le(super, K_object))
		InferenceSubjects::falls_within(Kinds::Knowledge::as_subject(K), Kinds::Knowledge::as_subject(super));
	#endif

	@<Use the source-text name to attach a noun to the constructor@>;

	if (<notable-linguistic-kinds>(W)) {
		Kinds::Constructors::mark_as_linguistic(K->construct);
		switch (<<r>>) {
			case 0: K_natural_language = K;
				#ifdef NOTIFY_NATURAL_LANGUAGE_KINDS_CALLBACK
				NOTIFY_NATURAL_LANGUAGE_KINDS_CALLBACK(K);
				#endif
				break;
			case 1: K_grammatical_gender = K; break;
		}
	}

	#ifdef CORE_MODULE
	if (<property-name>(W)) {
		property *P = <<rp>>;
		Properties::Valued::set_kind(P, K);
		Instances::make_kind_coincident(K, P);
		if (Kinds::Compare::eq(K, K_grammatical_gender)) P_grammatical_gender = P;
	}
	#endif

	#ifdef NEW_BASE_KIND_NOTIFY
	Plugins::Call::new_base_kind_notify(K, Kinds::Behaviour::get_name_in_template_code(K), W);
	#endif
	latest_base_kind_of_value = K;
	LOGIF(KIND_CREATIONS, "Created base kind $u\n", K);
	return K;
}

@ This is used to overcome a timing problem. A few inference subjects need to
be defined early in Inform's run to set up relations -- "thing", for example.
So when we do finally create "thing" as a kind of object, it needs to be
matched up with the inference subject already existing.

@<Renew the subject if necessary to cope with an early subject creation@> =
	#ifdef CORE_MODULE
	inference_subject *revised = NULL;
	if (Wordings::nonempty(W)) Plugins::Call::name_to_early_infs(W, &revised);
	if (revised) {
		InferenceSubjects::renew(revised,
			Kinds::Knowledge::as_subject(super), KIND_SUB, STORE_POINTER_kind_constructor(K->construct), LIKELY_CE);
		Kinds::Knowledge::set_subject(K, revised);
	}
	#endif

@<Use the source-text name to attach a noun to the constructor@> =
	unsigned int mc = KIND_SLOW_MC;
	if (Kinds::Compare::le(super, K_object)) mc = NOUN_MC;
	NATURAL_LANGUAGE_WORDS_TYPE *L = NULL;
	#ifdef CORE_MODULE
	L = Task::language_of_syntax();
	#endif
	noun *nt = Nouns::new_common_noun(W, NEUTER_GENDER,
		ADD_TO_LEXICON_NTOPT + WITH_PLURAL_FORMS_NTOPT,
		KIND_SLOW_MC, STORE_POINTER_kind_constructor(K->construct), L);
	Sentences::Headings::initialise_noun_resolution(nt);
	Kinds::Constructors::attach_noun(K->construct, nt);
 	if (Kinds::Compare::le(super, K_object))
 		Kinds::Behaviour::set_range_number(K, no_kinds_of_object++);

@h Kind names in the I6 template.
We defined some "constant" kinds and constructors above, to provide
values like |K_number| for use in this C source code. We will also want to
refer to these kinds in the Inform 6 source code for the template, where
they will have identifiers such as |NUMBER_TY|. (If anything it's the other
way round, since the template creates these kinds at run-time, using the
kind interpreter -- of which, more later.)

So we need a way of pairing up names in these two source codes, and here
it is. There is no need for speed here.

@d IDENTIFIERS_CORRESPOND(text_of_I6_name, pointer_to_I7_structure)
	if ((sn) && (Str::eq_narrow_string(sn, text_of_I6_name))) return pointer_to_I7_structure;

=
kind_constructor **Kinds::known_constructor_name(text_stream *sn) {
	IDENTIFIERS_CORRESPOND("ACTIVITY_TY", &CON_activity);
	IDENTIFIERS_CORRESPOND("COMBINATION_TY", &CON_combination);
	IDENTIFIERS_CORRESPOND("DESCRIPTION_OF_TY", &CON_description);
	IDENTIFIERS_CORRESPOND("INTERMEDIATE_TY", &CON_INTERMEDIATE);
	IDENTIFIERS_CORRESPOND("KIND_VARIABLE_TY", &CON_KIND_VARIABLE);
	IDENTIFIERS_CORRESPOND("LIST_OF_TY", &CON_list_of);
	IDENTIFIERS_CORRESPOND("PHRASE_TY", &CON_phrase);
	IDENTIFIERS_CORRESPOND("NIL_TY", &CON_NIL);
	IDENTIFIERS_CORRESPOND("PROPERTY_TY", &CON_property);
	IDENTIFIERS_CORRESPOND("RELATION_TY", &CON_relation);
	IDENTIFIERS_CORRESPOND("RULE_TY", &CON_rule);
	IDENTIFIERS_CORRESPOND("RULEBOOK_TY", &CON_rulebook);
	IDENTIFIERS_CORRESPOND("TABLE_COLUMN_TY", &CON_table_column);
	IDENTIFIERS_CORRESPOND("TUPLE_ENTRY_TY", &CON_TUPLE_ENTRY);
	IDENTIFIERS_CORRESPOND("VARIABLE_TY", &CON_variable);
	return NULL;
}

kind **Kinds::known_kind_name(text_stream *sn) {
	IDENTIFIERS_CORRESPOND("ARITHMETIC_VALUE_TY", &K_arithmetic_value);
	IDENTIFIERS_CORRESPOND("ENUMERATED_VALUE_TY", &K_enumerated_value);
	IDENTIFIERS_CORRESPOND("EQUATION_TY", &K_equation);
	IDENTIFIERS_CORRESPOND("TEXT_TY", &K_text);
	IDENTIFIERS_CORRESPOND("NUMBER_TY", &K_number);
	IDENTIFIERS_CORRESPOND("OBJECT_TY", &K_object);
	IDENTIFIERS_CORRESPOND("POINTER_VALUE_TY", &K_pointer_value);
	IDENTIFIERS_CORRESPOND("REAL_ARITHMETIC_VALUE_TY", &K_real_arithmetic_value);
	IDENTIFIERS_CORRESPOND("REAL_NUMBER_TY", &K_real_number);
	IDENTIFIERS_CORRESPOND("RESPONSE_TY", &K_response);
	IDENTIFIERS_CORRESPOND("RULEBOOK_OUTCOME_TY", &K_rulebook_outcome);
	IDENTIFIERS_CORRESPOND("SAYABLE_VALUE_TY", &K_sayable_value);
	IDENTIFIERS_CORRESPOND("SNIPPET_TY", &K_snippet);
	IDENTIFIERS_CORRESPOND("TABLE_TY", &K_table);
	IDENTIFIERS_CORRESPOND("TRUTH_STATE_TY", &K_truth_state);
	IDENTIFIERS_CORRESPOND("UNDERSTANDING_TY", &K_understanding);
	IDENTIFIERS_CORRESPOND("UNICODE_CHARACTER_TY", &K_unicode_character);
	IDENTIFIERS_CORRESPOND("USE_OPTION_TY", &K_use_option);
	IDENTIFIERS_CORRESPOND("VALUE_TY", &K_value);
	IDENTIFIERS_CORRESPOND("VERB_TY", &K_verb);
	IDENTIFIERS_CORRESPOND("WORD_VALUE_TY", &K_word_value);
	IDENTIFIERS_CORRESPOND("NIL_TY", &K_nil);
	return NULL;
}

int Kinds::known_name(text_stream *sn) {
	if (Kinds::known_constructor_name(sn)) return TRUE;
	if (Kinds::known_kind_name(sn)) return TRUE;
	return FALSE;
}

@h Annotating vocabulary.

=
#ifdef KINDS_MODULE
kind *Kinds::read_kind_marking_from_vocabulary(vocabulary_entry *ve) {
	return ve->means.one_word_kind;
}
void Kinds::mark_vocabulary_as_kind(vocabulary_entry *ve, kind *K) {
	ve->means.one_word_kind = K;
	Vocabulary::set_flags(ve, KIND_FAST_MC);
	NTI::mark_vocabulary(ve, <k-kind>);
}
#endif

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

@h Errors.

@e DimensionRedundant_KINDERROR from 1
@e DimensionNotBaseKOV_KINDERROR
@e NonDimensional_KINDERROR
@e UnitSequenceOverflow_KINDERROR
@e DimensionsInconsistent_KINDERROR
@e KindUnalterable_KINDERROR
@e KindsCircular_KINDERROR
@e LPCantScaleYet_KINDERROR
@e LPCantScaleTwice_KINDERROR

@ Some tools using this module will want to push simple error messages out to
the command line; others will want to translate them into elaborate problem
texts in HTML. So the client is allowed to define |KINDS_PROBLEM_HANDLER|
to some routine of her own, gazumping this one.

=
void Kinds::problem_handler(int err_no, parse_node *pn, kind *K1, kind *K2) {
	#ifdef KINDS_PROBLEM_HANDLER
	KINDS_PROBLEM_HANDLER(err_no, pn, K1, K2);
	#endif
	#ifndef KINDS_PROBLEM_HANDLER
	TEMPORARY_TEXT(text)
	WRITE_TO(text, "%+W", Node::get_text(pn));
	switch (err_no) {
		case DimensionRedundant_KINDERROR:
			Errors::with_text("multiplication rule given twice: %S", text);
			break;
		case DimensionNotBaseKOV_KINDERROR:
			Errors::with_text("multiplication rule too complex: %S", text);
			break;
		case NonDimensional_KINDERROR:
			Errors::with_text("multiplication rule quotes non-numerical kinds: %S", text);
			break;
		case UnitSequenceOverflow_KINDERROR:
			Errors::with_text("multiplication rule far too complex: %S", text);
			break;
		case DimensionsInconsistent_KINDERROR:
			Errors::with_text("multiplication rule creates inconsistency: %S", text);
			break;
		case KindUnalterable_KINDERROR:
			Errors::with_text("making this subkind would lead to a contradiction: %S", text);
			break;
		case KindsCircular_KINDERROR:
			Errors::with_text("making this subkind would lead to a circularity: %S", text);
			break;
		case LPCantScaleYet_KINDERROR:
			Errors::with_text("tries to scale a value with no point of reference: %S", text);
			break;
		case LPCantScaleTwice_KINDERROR:
			Errors::with_text("tries to scale a value which has already been scaled: %S", text);
			break;
		default: internal_error("unimplemented problem message");
	}
	DISCARD_TEXT(text)
	#endif
}

