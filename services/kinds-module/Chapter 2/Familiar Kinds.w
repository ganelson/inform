[FamiliarKinds::] Familiar Kinds.

To recognise certain kind names as familiar built-in ones.

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

@ Next, the two constructors used to punctuate tuples, that is, collections
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

= (early code)
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
kind_constructor **FamiliarKinds::known_con(text_stream *sn) {
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

kind **FamiliarKinds::known_kind(text_stream *sn) {
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

int FamiliarKinds::is_known(text_stream *sn) {
	if (FamiliarKinds::known_con(sn)) return TRUE;
	if (FamiliarKinds::known_kind(sn)) return TRUE;
	return FALSE;
}

@h Kind names in source text.
Inform creates the "natural language" kind in source text, not by loading it
from a file, but we still need to refer to it in the compiler. Similarly for
"grammatical gender". The others here are only 

=
<notable-linguistic-kinds> ::=
	natural language |
	grammatical gender |
	grammatical tense |
	narrative viewpoint |
	grammatical case

@ =
void FamiliarKinds::notice_new_kind(kind *K, wording W) {
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
}
