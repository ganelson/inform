[ToPhraseFamily::] To Phrase Family.

Imperative definitions of "To..." phrases.

@

=
imperative_defn_family *TO_PHRASE_EFF_family = NULL; /* "To award (some - number) points: ..." */

@

=
typedef struct to_family_data {
	struct wording pattern;
	struct wording prototype_text;
	struct wording constant_name;
	struct wording ph_documentation_symbol; /* the documentation reference, if any */
	struct constant_phrase *constant_phrase_holder;
	int explicit_name_used_in_maths; /* if so, this flag means it's like |log()| or |sin()| */
	struct wording explicit_name_for_inverse; /* e.g. |exp| for |log| */
	int to_begin; /* used in Basic mode only: this is to be the main phrase */
	CLASS_DEFINITION
} to_family_data;

@

=
void ToPhraseFamily::create_family(void) {
	TO_PHRASE_EFF_family            = ImperativeDefinitionFamilies::new(I"TO_PHRASE_EFF", TRUE);
	METHOD_ADD(TO_PHRASE_EFF_family, IDENTIFY_IMP_DEFN_MTID, ToPhraseFamily::claim);
	METHOD_ADD(TO_PHRASE_EFF_family, ASSESS_IMP_DEFN_MTID, ToPhraseFamily::assess);
	METHOD_ADD(TO_PHRASE_EFF_family, REGISTER_IMP_DEFN_MTID, ToPhraseFamily::register);
	METHOD_ADD(TO_PHRASE_EFF_family, GIVEN_BODY_IMP_DEFN_MTID, ToPhraseFamily::given_body);
	METHOD_ADD(TO_PHRASE_EFF_family, ALLOWS_INLINE_IMP_DEFN_MTID, ToPhraseFamily::allows_inline);
	METHOD_ADD(TO_PHRASE_EFF_family, COMPILE_IMP_DEFN_MTID, ToPhraseFamily::compile);
	METHOD_ADD(TO_PHRASE_EFF_family, COMPILE_AS_NEEDED_IMP_DEFN_MTID, ToPhraseFamily::compile_as_needed);
	METHOD_ADD(TO_PHRASE_EFF_family, PHRASEBOOK_INDEX_IMP_DEFN_MTID, ToPhraseFamily::include_in_Phrasebook_index);
}

@ =
<to-phrase-preamble> ::=
	{to} |                                                    ==> @<Issue PM_BareTo problem@>
	to ... ( called ... ) |                                   ==> @<Issue PM_DontCallPhrasesWithCalled problem@>
	{to ...} ( this is the {### function} inverse to ### ) |  ==> { 1, - }
	{to ...} ( this is the {### function} ) |                 ==> { 2, - }
	{to ...} ( this is ... ) |                                ==> { 3, - }
	{to ...}                                                  ==> { 4, - }

@<Issue PM_BareTo problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_BareTo),
		"'to' what? No name is given",
		"which means that this would not define a new phrase.");
	==> { 4, - };

@<Issue PM_DontCallPhrasesWithCalled problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_DontCallPhrasesWithCalled),
		"phrases aren't named using 'called'",
		"and instead use 'this is...'. For example, 'To salute (called saluting)' "
		"isn't allowed, but 'To salute (this is saluting)' is.");
	==> { 4, - };

@ 

=
int no_now_phrases = 0;

void ToPhraseFamily::claim(imperative_defn_family *self, imperative_defn *id) {
	wording W = Node::get_text(id->at);
	if (<to-phrase-preamble>(W)) {
		id->family = TO_PHRASE_EFF_family;
		to_family_data *tfd = CREATE(to_family_data);
		tfd->constant_name = EMPTY_WORDING;
		tfd->explicit_name_used_in_maths = FALSE;
		tfd->explicit_name_for_inverse = EMPTY_WORDING;
		tfd->constant_phrase_holder = NULL;
		id->family_specific_data = STORE_POINTER_to_family_data(tfd);
		int form = <<r>>;
		if (form != 4) {
			wording RW = GET_RW(<to-phrase-preamble>, 2);
			if (<s-type-expression>(RW)) {
				StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_PhraseNameDuplicated),
					"that name for this new phrase is not allowed",
					"because it already has a meaning.");
			} else {
				tfd->constant_name = RW;
				if (ToPhraseFamily::parse_constant(RW) == NULL)
					ToPhraseFamily::create_constant(RW, GET_RW(<to-phrase-preamble>, 1));
			}
			if ((form == 1) || (form == 2)) tfd->explicit_name_used_in_maths = TRUE;
			if (form == 1) tfd->explicit_name_for_inverse = Wordings::first_word(GET_RW(<to-phrase-preamble>, 3));
		}
		wording PW = GET_RW(<to-phrase-preamble>, 1);
		tfd->ph_documentation_symbol = Index::DocReferences::position_of_symbol(&PW);
		tfd->prototype_text = PW;
	}
}

@ As a safety measure, to avoid ambiguities, Inform only allows one phrase
definition to begin with "now". It recognises such phrases as those whose
preambles match:

=
<now-phrase-preamble> ::=
	to now ...

@ In basic mode (only), the To phrase "to begin" acts as something like
|main| in a C-like language, so we need to take note of where it's defined:

=
<begin-phrase-preamble> ::=
	to begin

@ =
void ToPhraseFamily::assess(imperative_defn_family *self, imperative_defn *id) {
	to_family_data *tfd = RETRIEVE_POINTER_to_family_data(id->family_specific_data);
	wording W = tfd->prototype_text;

	if (Wordings::nonempty(tfd->constant_name)) @<The preamble parses to a named To phrase@>;
	if (<now-phrase-preamble>(W)) {
		if (no_now_phrases++ == 1) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_RedefinedNow),
				"creating new variants on 'now' is not allowed",
				"because 'now' plays a special role in the language. "
				"It has a wide-ranging ability to make a condition "
				"become immediately true. (To give it wider abilities, "
				"the idea is to create new relations.)");
		}
	}
	if (<begin-phrase-preamble>(W)) {
		tfd->to_begin = TRUE;
	}
}

@ When we parse a named phrase in coarse mode, we need to make sure that
name is registered as a constant value; when we parse it again in fine
mode, we can get that value back again if we look it up by name.

@<The preamble parses to a named To phrase@> =
	wording NW = tfd->constant_name;

	constant_phrase *cphr = ToPhraseFamily::parse_constant(NW);
	if (Kinds::Behaviour::definite(cphr->cphr_kind) == FALSE) {
		phrase *ph = ToPhraseFamily::body_of_constant(cphr);
		if (ph) current_sentence = Phrases::declaration_node(ph);
		Problems::quote_source(1, Diagrams::new_UNPARSED_NOUN(Nouns::nominative_singular(cphr->name)));
		Problems::quote_wording(2, Nouns::nominative_singular(cphr->name));
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_NamedGeneric));
		Problems::issue_problem_segment(
			"I can't allow %1, because the phrase it gives a name to "
			"is generic, that is, it has a kind which is too vague. "
			"That means there isn't any single phrase which '%2' "
			"could refer to - there would have to be different versions "
			"for every setting where it might be needed, and we can't "
			"predict in advance which one '%2' might need to be.");
		Problems::issue_problem_end();
		LOG("CPHR failed at %d, %u\n", cphr->allocation_id, cphr->cphr_kind);
	}
	tfd->constant_phrase_holder = cphr;

@

=
void ToPhraseFamily::register(imperative_defn_family *self) {
	Routines::ToPhrases::register_all();
}

void ToPhraseFamily::given_body(imperative_defn_family *self, imperative_defn *id) {
	to_family_data *tfd = RETRIEVE_POINTER_to_family_data(id->family_specific_data);
	if (tfd->to_begin) id->body_of_defn->to_begin = TRUE;

	wording XW = ToPhraseFamily::get_prototype_text(id);
	wording OW = EMPTY_WORDING;
	Phrases::TypeData::Textual::parse(&(id->body_of_defn->type_data), XW, &OW);
	Phrases::Options::parse_declared_options(&(id->body_of_defn->options_data), OW);

	Routines::ToPhrases::new(id->body_of_defn);
}

int ToPhraseFamily::allows_inline(imperative_defn_family *self, imperative_defn *id) {
	return TRUE;
}

int ToPhraseFamily::include_in_Phrasebook_index(imperative_defn_family *self, imperative_defn *id) {
	return TRUE;
}

phrase *ToPhraseFamily::inverse(imperative_defn *id) {
	if (id->family != TO_PHRASE_EFF_family) return NULL;
	to_family_data *tfd = RETRIEVE_POINTER_to_family_data(id->family_specific_data);
	if (Wordings::nonempty(tfd->explicit_name_for_inverse)) {
		phrase *ph;
		LOOP_OVER(ph, phrase) {
			wording W = ToPhraseFamily::get_equation_form(ph->from);
			if (Wordings::nonempty(W))
				if (Wordings::match(W, tfd->explicit_name_for_inverse))
					return ph;
		}
	}
	return NULL;
}

constant_phrase *ToPhraseFamily::constant_phrase(imperative_defn *id) {
	if (id->family != TO_PHRASE_EFF_family) return NULL;
	to_family_data *tfd = RETRIEVE_POINTER_to_family_data(id->family_specific_data);
	return tfd->constant_phrase_holder;
}

wording ToPhraseFamily::constant_name(imperative_defn *id) {
	if (id->family != TO_PHRASE_EFF_family) return EMPTY_WORDING;
	to_family_data *tfd = RETRIEVE_POINTER_to_family_data(id->family_specific_data);
	return tfd->constant_name;
}

int ToPhraseFamily::has_name_as_constant(imperative_defn *id) {
	if (id->family != TO_PHRASE_EFF_family) return FALSE;
	to_family_data *tfd = RETRIEVE_POINTER_to_family_data(id->family_specific_data);
	if ((tfd->constant_phrase_holder) &&
		(tfd->explicit_name_used_in_maths == FALSE) &&
		(Wordings::nonempty(Nouns::nominative_singular(tfd->constant_phrase_holder->name)))) return TRUE;
	return FALSE;
}

wording ToPhraseFamily::get_equation_form(imperative_defn *id) {
	if (id->family != TO_PHRASE_EFF_family) return EMPTY_WORDING;
	to_family_data *tfd = RETRIEVE_POINTER_to_family_data(id->family_specific_data);
	if (tfd->explicit_name_used_in_maths)
		return Wordings::first_word(Nouns::nominative_singular(tfd->constant_phrase_holder->name));
	return EMPTY_WORDING;
}

wording ToPhraseFamily::doc_ref(imperative_defn *id) {
	if (id->family != TO_PHRASE_EFF_family) return EMPTY_WORDING;
	to_family_data *tfd = RETRIEVE_POINTER_to_family_data(id->family_specific_data);
	return tfd->ph_documentation_symbol;
}

@h Extracting the stem.
A couple of routines to read but not really parse the stem and the bud.

=
wording ToPhraseFamily::get_prototype_text(imperative_defn *id) {
	if (id->family != TO_PHRASE_EFF_family) return EMPTY_WORDING;
	to_family_data *tfd = RETRIEVE_POINTER_to_family_data(id->family_specific_data);
	return tfd->prototype_text;
}

void ToPhraseFamily::compile(imperative_defn_family *self,
	int *total_phrases_compiled, int total_phrases_to_compile) {
	@<Mark To... phrases which have definite kinds for future compilation@>;
	@<Throw problems for phrases with return kinds too vaguely defined@>;
	@<Throw problems for inline phrases named as constants@>;
}

@ As we'll see, it's legal in Inform to define "To..." phrases with vague
kinds: "To expose (X - a value)", for example. This can't be compiled as
vaguely as the definition implies, since there would be no way to know how
to store X. Instead, for each different kind of X which is actually needed,
a fresh version of the phrase is compiled -- one where X is a number, one
where it's a text, and so on. This is handled by making a "request" for the
phrase, indicating that a compiled version of it will be needed.

Since "To..." phrases are only compiled on request, we must remember to
request the boring ones with straightforward kinds ("To award (N - a number)
points", say). This is where we do it:

@<Mark To... phrases which have definite kinds for future compilation@> =
	phrase *ph;
	LOOP_OVER(ph, phrase) {
		kind *K = Phrases::TypeData::kind(&(ph->type_data));
		if (Kinds::Behaviour::definite(K)) {
			if (ph->at_least_one_compiled_form_needed)
				Routines::ToPhrases::make_request(ph, K, NULL, EMPTY_WORDING);
		}
	}

@<Throw problems for phrases with return kinds too vaguely defined@> =
	phrase *ph;
	LOOP_OVER(ph, phrase) {
		kind *KR = Phrases::TypeData::get_return_kind(&(ph->type_data));
		if ((Kinds::Behaviour::semidefinite(KR) == FALSE) &&
			(Phrases::TypeData::arithmetic_operation(ph) == -1)) {
			current_sentence = Phrases::declaration_node(ph);
			Problems::quote_source(1, current_sentence);
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ReturnKindVague));
			Problems::issue_problem_segment(
				"The declaration %1 tries to set up a phrase which decides a "
				"value which is too vaguely described. For example, 'To decide "
				"which number is the target: ...' is fine, because 'number' "
				"is clear about what kind of value should emerge; but 'To "
				"decide which value is the target: ...' is not clear enough.");
			Problems::issue_problem_end();
		}
		for (int k=1; k<=26; k++)
			if ((Kinds::Behaviour::involves_var(KR, k)) &&
				(Phrases::TypeData::tokens_contain_variable(&(ph->type_data), k) == FALSE)) {
				current_sentence = Phrases::declaration_node(ph);
				TEMPORARY_TEXT(var_letter)
				PUT_TO(var_letter, 'A'+k-1);
				Problems::quote_source(1, current_sentence);
				Problems::quote_stream(2, var_letter);
				StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ReturnKindUndetermined));
				Problems::issue_problem_segment(
					"The declaration %1 tries to set up a phrase which decides a "
					"value which is too vaguely described, because it involves "
					"a kind variable (%2) which it can't determine through "
					"usage.");
				Problems::issue_problem_end();
				DISCARD_TEXT(var_letter)
		}
	}

@<Throw problems for inline phrases named as constants@> =
	phrase *ph;
	LOOP_OVER(ph, phrase)
		if ((Phrases::TypeData::invoked_inline(ph)) &&
			(ToPhraseFamily::has_name_as_constant(ph->from))) {
			current_sentence = Phrases::declaration_node(ph);
			Problems::quote_source(1, current_sentence);
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_NamedInline));
			Problems::issue_problem_segment(
				"The declaration %1 tries to give a name to a phrase which is "
				"defined using inline Inform 6 code in (- markers -). Such "
				"phrases can't be named and used as constants because they "
				"have no independent existence, being instead made fresh "
				"each time they are used.");
			Problems::issue_problem_end();
		}

@ The twilight gathers, but our work is far from done. Recall that we have
accumulated compilation requests for "To..." phrases, but haven't actually
acted on them yet.

We have to do this in quite an open-ended way, because compiling one phrase
can easily generate fresh requests for others. For instance, suppose we have
the definition "To expose (X - a value)" in play, and suppose that when
compiling the phrase "To advertise", Inform runs into the line "expose the
hoarding text". This causes it to issue a compilation request for "To expose
(X - a text)". Perhaps we've compiled such a form already, but perhaps we
haven't. Compilation therefore goes on until all requests have been dealt
with.

Compiling phrases also produces the need for other pieces of code to be
generated -- for example, suppose our phrase being compiled, "To advertise",
includes the text:

>> let Z be "Two for the price of one! Just [expose price]!";

We are going to need to compile "Two for the price of one! Just [expose price]!"
later on, in its own text substitution routine; but notice that it contains
the need for "To expose (X - a number)", and that will generate a further
phrase request.

Because of this and similar problems, it's impossible to compile all the
phrases alone: we must compile phrases, then things arising from them, then
phrases arising from those, then things arising from the phrases arising
from those, and so on, until we're done. The process is therefore structured
as a set of "coroutines" which each carry out as much as they can and then
hand over to the others to generate more work.


=
void ToPhraseFamily::compile_as_needed(imperative_defn_family *self,
	int *total_phrases_compiled, int total_phrases_to_compile) {
	int repeat = TRUE;
	while (repeat) {
		repeat = FALSE;
		if (Routines::ToPhrases::compilation_coroutine(
			total_phrases_compiled, total_phrases_to_compile) > 0)
			repeat = TRUE;
		if (ListTogether::compilation_coroutine() > 0)
			repeat = TRUE;
		#ifdef IF_MODULE
		if (LoopingOverScope::compilation_coroutine() > 0)
			repeat = TRUE;
		#endif
		if (Strings::TextSubstitutions::compilation_coroutine(FALSE) > 0)
			repeat = TRUE;
		if (Propositions::Deferred::compilation_coroutine() > 0)
			repeat = TRUE;
	}
}

@ A few "To..." phrases have names, and can therefore be used as values in their
own right, a functional-programming sort of device. For example:

>> To decide what number is double (N - a number) (this is doubling):

has the name "doubling". Such a name is recorded here:

=
typedef struct constant_phrase {
	struct noun *name;
	struct phrase *phrase_meant; /* if known at this point */
	struct kind *cphr_kind; /* ditto */
	struct inter_name *cphr_iname;
	struct wording associated_preamble_text;
	CLASS_DEFINITION
} constant_phrase;

@ Here we create a new named phrase ("doubling", say):

=
constant_phrase *ToPhraseFamily::create_constant(wording NW, wording RW) {
	constant_phrase *cphr = CREATE(constant_phrase);
	cphr->phrase_meant = NULL; /* we won't know until later */
	cphr->cphr_kind = NULL; /* nor this */
	cphr->associated_preamble_text = RW;
	cphr->name = Nouns::new_proper_noun(NW, NEUTER_GENDER, ADD_TO_LEXICON_NTOPT,
		PHRASE_CONSTANT_MC, Rvalues::from_constant_phrase(cphr), Task::language_of_syntax());
	cphr->cphr_iname = NULL;
	return cphr;
}

@ ...and parse for an existing one:

=
constant_phrase *ToPhraseFamily::parse_constant(wording NW) {
	if (<s-value>(NW)) {
		parse_node *spec = <<rp>>;
		if (Rvalues::is_CONSTANT_construction(spec, CON_phrase)) {
			constant_phrase *cphr = Rvalues::to_constant_phrase(spec);
			ToPhraseFamily::kind(cphr);
			return cphr;
		}
	}
	return NULL;
}

@ As often happens with Inform constants, the kind of a constant phrase can't
be known when its name first comes up, and must be filled in later. (In
particular, before the second traverse many kinds do not yet exist.) So
the following takes a patch-it-later approach.

=
kind *ToPhraseFamily::kind(constant_phrase *cphr) {
	if (cphr == NULL) return NULL;
	if (global_pass_state.pass < 2) return Kinds::binary_con(CON_phrase, K_value, K_value);
	if (cphr->cphr_kind == NULL) {
		wording OW = EMPTY_WORDING;
		ph_type_data phtd = Phrases::TypeData::new();
		Phrases::TypeData::Textual::parse(&phtd,
			cphr->associated_preamble_text, &OW);
		cphr->cphr_kind = Phrases::TypeData::kind(&phtd);
	}
	return cphr->cphr_kind;
}

@ And similarly for the |phrase| structure this name corresponds to.

=
phrase *ToPhraseFamily::body_of_constant(constant_phrase *cphr) {
	if (cphr == NULL) internal_error("null cphr");
	if (cphr->phrase_meant == NULL) {
		imperative_defn *id;
		LOOP_OVER(id, imperative_defn) {
			if (ToPhraseFamily::constant_phrase(id) == cphr) {
				cphr->phrase_meant = id->body_of_defn;
				break;
			}
		}
	}
	return cphr->phrase_meant;
}
