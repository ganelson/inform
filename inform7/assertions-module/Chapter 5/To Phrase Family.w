[ToPhraseFamily::] To Phrase Family.

Imperative definitions of "To..." phrases.

@

=
imperative_defn_family *TO_PHRASE_EFF_family = NULL; /* "To award (some - number) points: ..." */

typedef struct to_family_data {
	struct wording pattern;
	struct wording prototype_text;
	struct wording constant_name;
	struct constant_phrase *constant_phrase_holder;
	int explicit_name_used_in_maths; /* if so, this flag means it's like |log()| or |sin()| */
	struct wording explicit_name_for_inverse; /* e.g. |exp| for |log| */
	int to_begin; /* used in Basic mode only: this is to be the main phrase */
	CLASS_DEFINITION
} to_family_data;

@

=
void ToPhraseFamily::create_family(void) {
	TO_PHRASE_EFF_family            = ImperativeDefinitions::new_family(I"TO_PHRASE_EFF");
	METHOD_ADD(TO_PHRASE_EFF_family, CLAIM_IMP_DEFN_MTID, ToPhraseFamily::claim);
	METHOD_ADD(TO_PHRASE_EFF_family, ASSESS_IMP_DEFN_MTID, ToPhraseFamily::assess);
	METHOD_ADD(TO_PHRASE_EFF_family, NEW_PHRASE_IMP_DEFN_MTID, ToPhraseFamily::new_phrase);
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
				if (Phrases::Constants::parse(RW) == NULL)
					Phrases::Constants::create(RW, GET_RW(<to-phrase-preamble>, 1));
			}
			if ((form == 1) || (form == 2)) tfd->explicit_name_used_in_maths = TRUE;
			if (form == 1) tfd->explicit_name_for_inverse = Wordings::first_word(GET_RW(<to-phrase-preamble>, 3));
		}
		tfd->prototype_text = GET_RW(<to-phrase-preamble>, 1);
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

	constant_phrase *cphr = Phrases::Constants::parse(NW);
	if (Kinds::Behaviour::definite(cphr->cphr_kind) == FALSE) {
		phrase *ph = Phrases::Constants::as_phrase(cphr);
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
void ToPhraseFamily::new_phrase(imperative_defn_family *self, imperative_defn *id, phrase *new_ph) {
	to_family_data *tfd = RETRIEVE_POINTER_to_family_data(id->family_specific_data);
	if (tfd->to_begin) new_ph->to_begin = TRUE;
	Routines::ToPhrases::new(new_ph);
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

@h Extracting the stem.
A couple of routines to read but not really parse the stem and the bud.

=
wording ToPhraseFamily::get_prototype_text(imperative_defn *id) {
	if (id->family != TO_PHRASE_EFF_family) return EMPTY_WORDING;
	to_family_data *tfd = RETRIEVE_POINTER_to_family_data(id->family_specific_data);
	return tfd->prototype_text;
}

