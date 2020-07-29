[Translations::] Translation Requests.

Three unrelated senses of "X translates into Y as Z" sentences.

@h Translation into natural languages.
The sentence "X translates into Y as Z" has this sense provided Y matches:

=
<translation-target-language> ::=
	<natural-language>  ==> { pass 1 }

@ =
int Translations::translates_into_language_as_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	wording O2W = (NPs)?(NPs[2]):EMPTY_WORDING;
	switch (task) { /* "Thing translates into French as chose" */
		case ACCEPT_SMFT:
			if (<translation-target-language>(O2W)) {
				inform_language *nl = (inform_language *) (<<rp>>);
				<np-articled>(SW);
				V->next = <<rp>>;
				<np-articled>(OW);
				V->next->next = <<rp>>;
				Node::set_defn_language(V->next->next, nl);
				return TRUE;
			}
			break;
		case TRAVERSE1_SMFT:
			@<Parse subject phrase and send the translation to the linguistics module@>;
			break;
	}
	return FALSE;
}

@ The subject phrase can only be parsed on traverse 1, since it only makes
sense once kinds and instances exist.

@d TRANS_KIND 1
@d TRANS_INSTANCE 2

=
<translates-into-language-sentence-subject> ::=
	<k-kind> |  ==> { TRANS_KIND, RP[1] }
	<instance>  ==> { TRANS_INSTANCE, RP[1] }

@<Parse subject phrase and send the translation to the linguistics module@> =
	inform_language *L = Node::get_defn_language(V->next->next);
	int g = Annotations::read_int(V->next->next, explicit_gender_marker_ANNOT);
	if (L == NULL) internal_error("No such NL");
	if (L == DefaultLanguage::get(NULL)) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_CantTranslateIntoEnglish),
			"you can't translate from a language into itself",
			"only from the current language to a different one.");
		return FALSE;
	}

	if ((<translates-into-language-sentence-subject>(Node::get_text(V->next))) == FALSE) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_CantTranslateValue),
			"this isn't something which can be translated",
			"that is, it isn't a kind or instance.");
		return FALSE;
	}

	switch (<<r>>) {
		case TRANS_INSTANCE: {
			instance *I = <<rp>>;
			noun *t = Instances::get_noun(I);
			if (t == NULL) internal_error("stuck on instance name");
			Nouns::supply_text(t, Node::get_text(V->next->next), L, g,
				SINGULAR_NUMBER, ADD_TO_LEXICON_NTOPT);
			break;
		}
		case TRANS_KIND: {
			kind *K = <<rp>>;
			kind_constructor *KC = Kinds::get_construct(K);
			if (KC == NULL) internal_error("stuck on kind name");
			noun *t = Kinds::Constructors::get_noun(KC);
			if (t == NULL) internal_error("further stuck on kind name");
			Nouns::supply_text(t, Node::get_text(V->next->next), L, g,
				SINGULAR_NUMBER, ADD_TO_LEXICON_NTOPT + WITH_PLURAL_FORMS_NTOPT);
			break;
		}
		default: internal_error("bad translation category");
	}

@h Translation into Unicode.
The sentence "X translates into Y as Z" has this sense provided Y matches:

=
<translation-target-unicode> ::=
	unicode

@ =
int Translations::translates_into_unicode_as_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	wording O2W = (NPs)?(NPs[2]):EMPTY_WORDING;
	switch (task) { /* "Black king chess piece translates into Unicode as 9818" */
		case ACCEPT_SMFT:
			if (<translation-target-unicode>(O2W)) {
				<np-articled>(SW);
				V->next = <<rp>>;
				<np-articled>(OW);
				V->next->next = <<rp>>;
				return TRUE;
			}
			break;
		case TRAVERSE2_SMFT:
			UnicodeTranslations::unicode_translates(V);
			break;
	}
	return FALSE;
}

@h Translation into Inter.
The sentence "X translates into Y as Z" has this sense provided Y matches the
following. Before the coming of Inter code, the only conceivable compilation
target was Inform 6, but these now set Inter identifiers, so really the first
wording is to be preferred.

=
<translation-target-i6> ::=
	inter |
	i6 |
	inform 6

@ =
int Translations::translates_into_Inter_as_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	wording O2W = (NPs)?(NPs[2]):EMPTY_WORDING;
	switch (task) { /* "The taking inventory action translates into Inter as "Inv"" */
		case ACCEPT_SMFT:
			if (<translation-target-i6>(O2W)) {
				<np-articled>(SW);
				V->next = <<rp>>;
				<np-articled>(OW);
				V->next->next = <<rp>>;
				return TRUE;
			}
			break;
		case TRAVERSE1_SMFT:
		case TRAVERSE2_SMFT:
			IdentifierTranslations::as(V);
			break;
	}
	return FALSE;
}
