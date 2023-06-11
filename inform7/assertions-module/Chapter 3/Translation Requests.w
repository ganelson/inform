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
		case PASS_1_SMFT:
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
	wording SP = Node::get_text(V->next);
	wording OP = Node::get_text(V->next->next);
	inform_language *L = Node::get_defn_language(V->next->next);
	int g = Annotations::read_int(V->next->next, explicit_gender_marker_ANNOT);
	if (L == NULL) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_CantTranslateValue),
			"you can only translate into a language used by the current project",
			"such as the language it is played, written or indexed in.");
		return FALSE;
	}
	if (L == DefaultLanguage::get(NULL)) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_CantTranslateIntoEnglish),
			"you can't translate from a language into itself",
			"only from the current language to a different one.");
		return FALSE;
	}

	if ((<translates-into-language-sentence-subject>(SP)) == FALSE) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(Untestable),
			"this isn't something which can be translated",
			"that is, it isn't a kind or instance.");
		return FALSE;
	}

	switch (<<r>>) {
		case TRANS_INSTANCE: {
			instance *I = <<rp>>;
			noun *t = Instances::get_noun(I);
			if (t == NULL) internal_error("stuck on instance name");
			Nouns::supply_text(t, OP, L, g, SINGULAR_NUMBER, ADD_TO_LEXICON_NTOPT);
			break;
		}
		case TRANS_KIND: {
			kind *K = <<rp>>;
			kind_constructor *KC = Kinds::get_construct(K);
			if (KC == NULL) internal_error("stuck on kind name");
			noun *t = KindConstructors::get_noun(KC);
			if (t == NULL) internal_error("further stuck on kind name");
			Nouns::supply_text(t, OP, L, g, SINGULAR_NUMBER,
				ADD_TO_LEXICON_NTOPT + WITH_PLURAL_FORMS_NTOPT);
			break;
		}
		default: internal_error("bad translation category");
	}

@h Translation into Unicode.
The following sentence form is now deprecated:

>> leftwards harpoon with barb upwards translates into Unicode as 8636.

Until Inform 10.1, this equated a Unicode name to its code point value; see
IE-0005 and //values: Unicode Literals// for what now happens instead.

The sentence "X translates into Y as Z" has this sense provided Y matches:

=
<translation-target-unicode> ::=
	unicode

@ =
int PM_UnicodeDeprecated_thrown = FALSE;
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
		case PASS_2_SMFT:
			if (PM_UnicodeDeprecated_thrown == FALSE) {
				PM_UnicodeDeprecated_thrown = TRUE;
				StandardProblems::sentence_problem(Task::syntax_tree(),
					_p_(PM_UnicodeDeprecated),
					"the sentence 'X translates into Unicode as Y' has been removed "
					"from the Inform language",
					"because it is now redundant. Inform already knows all the names "
					"in the Unicode standard. If you're getting this problem message "
					"because you included the extension 'Unicode Full Character Names' "
					"or 'Unicode Character Names', all you need do is to not include it.");
			}
			break;
	}
	return FALSE;
}

@h Translation into Inter.
There are three sentences here, but the first is now deprecated: it has split
off into two different meanings, each with its own wording for clarity.

@d TRANSLATION_DEPRECATED_FORM 1
@d TRANSLATION_DEFINED_BY_FORM 2
@d TRANSLATION_ACCESSIBLE_TO_FORM 3

@ The sentence "X translates into Y as Z" has this sense provided Y matches the
following. Before the coming of Inter code, the only conceivable compilation
target was Inform 6, but these now set Inter identifiers, so really the first
wording is to be preferred.

=
<translation-target-i6> ::=
	inter |
	i6 |
	inform 6

@ 

@e INTER_NAMING_SMFT

=
void Translations::traverse_for_late_namings(void) {
	SyntaxTree::traverse(Task::syntax_tree(), Translations::visit_to_name);
}

void Translations::visit_to_name(parse_node *p) {
	if ((Node::get_type(p) == SENTENCE_NT) && (p->down))
		MajorNodes::try_special_meaning(INTER_NAMING_SMFT, p->down);
}

@ =
int Translations::translates_into_Inter_as_SMF(int task, parse_node *V, wording *NPs) {
	int translates_into_verb = TRANSLATION_DEPRECATED_FORM;
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
		case PASS_1_SMFT:
		case PASS_2_SMFT:
			@<Act on the Inter translation@>;
			break;
		case INTER_NAMING_SMFT:
			@<Act on late naming@>;
			break;
	}
	return FALSE;
}

@

=
<defined-by-inter-sentence-object> ::=
	defined by inter as ...

@

=
int Translations::defined_by_Inter_as_SMF(int task, parse_node *V, wording *NPs) {
	int translates_into_verb = TRANSLATION_DEFINED_BY_FORM;
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* The seed random number generator rule is defined by Inter as "SEED_RANDOM_NUMBER_GENERATOR_R". */
		case ACCEPT_SMFT:
			if (<defined-by-inter-sentence-object>(OW)) {
				OW = GET_RW(<defined-by-inter-sentence-object>, 1);
				<np-articled>(SW);
				V->next = <<rp>>;
				<np-articled>(OW);
				V->next->next = <<rp>>;
				return TRUE;
			}
			break;
		case PASS_1_SMFT:
		case PASS_2_SMFT:
			@<Act on the Inter translation@>;
			break;
		case INTER_NAMING_SMFT:
			@<Act on late naming@>;
			break;
	}
	return FALSE;
}

@

=
<accessible-to-inter-sentence-object> ::=
	accessible to inter as ...

@

=
int Translations::accessible_to_Inter_as_SMF(int task, parse_node *V, wording *NPs) {
	int translates_into_verb = TRANSLATION_ACCESSIBLE_TO_FORM;
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* The time advancing rule is accessible to Inter as "TIME_ADV_RULE". */
		case ACCEPT_SMFT:
			if (<accessible-to-inter-sentence-object>(OW)) {
				OW = GET_RW(<accessible-to-inter-sentence-object>, 1);
				<np-articled>(SW);
				V->next = <<rp>>;
				<np-articled>(OW);
				V->next->next = <<rp>>;
				return TRUE;
			}
			break;
		case PASS_1_SMFT:
		case PASS_2_SMFT:
			@<Act on the Inter translation@>;
			break;
		case INTER_NAMING_SMFT:
			@<Act on late naming@>;
			break;
	}
	return FALSE;
}

@ Translations can be made in a number of contexts:

@d INVALID_I6TR -1
@d PROPERTY_I6TR 0      /* "The open property translates into I6 as "open"." */
@d NOUN_I6TR 1          /* "The north object translates into I6 as "n_obj"." */
@d RULE_I6TR 2          /* "The baffling rule translates into I6 as "BAFFLING_R"." */
@d RULEBOOK_I6TR 3      /* "The high security rules translates into I6 as "SECURITY_RULEBOOK". */
@d ACTIVITY_I6TR 4      /* "The draining something activity translates into I6 as "DRAINING_ACTIVITY". */
@d VARIABLE_I6TR 5      /* "The sludge count variable translates into I6 as "sldgc". */
@d ACTION_I6TR 6        /* "The taking action translates into I6 as "Take". */
@d GRAMMAR_TOKEN_I6TR 7 /* "The grammar token "[whatever]" translates into I6 as "WHATEVER". */

=
<translates-into-i6-sentence-subject> ::=
	... property |          ==> { PROPERTY_I6TR, - }
	... object/kind |       ==> { NOUN_I6TR, - }
	{... rule} |            ==> { RULE_I6TR, - }
	{... rules/rulebook} |  ==> { RULEBOOK_I6TR, - }
	{... activity} |        ==> { ACTIVITY_I6TR, - }
	... variable |          ==> { VARIABLE_I6TR, - }
	... action |            ==> { ACTION_I6TR, - }
	understand token ... |  ==> { GRAMMAR_TOKEN_I6TR, - }
	...                     ==> @<Issue PM_TranslatedUnknownCategory problem@>

@<Issue PM_TranslatedUnknownCategory problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TranslatedUnknownCategory),
		"that isn't one of the things which can be translated to I6",
		"and should be '... variable', '... property', '... object', "
		"'... kind', '... rule', or '... action'. For instance, 'The yourself "
		"object translates into I6 as \"selfobj\".'");
	==> { INVALID_I6TR, - };

@ The object noun phrase is usually just an I6 identifier in quotation marks,
but it's also possible to list literal texts (for the benefit of rules).
Following the optional "with" is an articled list, each entry of which
will be required to pass |<extra-response>|.

=
<translates-into-i6-sentence-object> ::=
	<quoted-text> with <np-articled-list> |    ==> { R[1], RP[2] }
	<quoted-text>                              ==> { R[1], NULL }

@<Act on the Inter translation@> =
	parse_node *p1 = V->next;
	parse_node *p2 = V->next->next;
	parse_node *responses_list = NULL;
	int category = INVALID_I6TR;
	<translates-into-i6-sentence-subject>(Node::get_text(p1));
	category = <<r>>;
	if (category != INVALID_I6TR) {
		wording W = GET_RW(<translates-into-i6-sentence-subject>, 1);

		if (global_pass_state.pass == 1) {
			Annotations::write_int(V, category_of_I6_translation_ANNOT, INVALID_I6TR);
			@<Ensure that we are translating to a quoted I6 identifier@>;
			Annotations::write_int(V, category_of_I6_translation_ANNOT, category);
			if (responses_list) SyntaxTree::graft(Task::syntax_tree(), responses_list, p2);
		} else category = Annotations::read_int(V, category_of_I6_translation_ANNOT);

		@<Take action in pass 1 or 2 where possible@>;
	}

@<Ensure that we are translating to a quoted I6 identifier@> =
	int valid = TRUE;
	if (<translates-into-i6-sentence-object>(Node::get_text(p2)) == FALSE) valid = FALSE;
	else responses_list = <<rp>>;
	if (valid) @<Dequote it and see if it's valid@>;
	if (valid == FALSE) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_TranslatedToNonIdentifier),
			"Inform 7 constructions can only translate into quoted I6 identifiers",
			"which must be strings of 1 to 31 characters drawn from 1, 2, ..., 9, "
			"a or A, b or B, ..., z or Z, or underscore '_', except that the "
			"first character is not allowed to be a digit.");
		return FALSE;
	}

@ If it turns out not to be, we simply set |valid| to false.

@<Dequote it and see if it's valid@> =
	int wn = Wordings::first_wn(Node::get_text(p2));
	Node::set_text(p2, Wordings::one_word(wn));
	Word::dequote(wn);
	if (valid) valid = Identifiers::valid(Lexer::word_text(wn));

@ In some cases, we act on pass 1, but in others pass 2, and in the case of
|NOUN_I6TR|, later even than that. There are messy timing issues here.

@<Take action in pass 1 or 2 where possible@> =
	switch(category) {
		case PROPERTY_I6TR:
			if (translates_into_verb == TRANSLATION_DEPRECATED_FORM)
				translates_into_verb = TRANSLATION_DEFINED_BY_FORM;
			@<Do not use the translates-into form@>;
			if (translates_into_verb == TRANSLATION_ACCESSIBLE_TO_FORM) {
				if (global_pass_state.pass == 2) Properties::accessible_as(W, p2);
			} else {
				Properties::translates(W, p2);
				Annotations::write_int(V, category_of_I6_translation_ANNOT, INVALID_I6TR);
			}
			break;
		case NOUN_I6TR: break;
		case RULE_I6TR:
			if (translates_into_verb == TRANSLATION_DEPRECATED_FORM)
				translates_into_verb = TRANSLATION_DEFINED_BY_FORM;
			@<Require the defined-by form@>;
			if (global_pass_state.pass == 1)
				Rules::declare_Inter_rule(W, Node::get_text(p2));
			if ((global_pass_state.pass == 2) && (p2->down) && (<rule-name>(W)))
				Translations::plus_responses(p2->down, <<rp>>);
			break;
		case RULEBOOK_I6TR:
			@<Require the accessible-to form@>;
			if (global_pass_state.pass == 2) Rulebooks::translates(W, p2);
			break;
		case ACTIVITY_I6TR:
			@<Require the accessible-to form@>;
			if (global_pass_state.pass == 2) Activities::translates(W, p2);
			break;
		case VARIABLE_I6TR:
			if (translates_into_verb == TRANSLATION_DEPRECATED_FORM)
				translates_into_verb = TRANSLATION_DEFINED_BY_FORM;
			@<Require the defined-by form@>;
			if (global_pass_state.pass == 2) NonlocalVariables::translates(W, p2);
			break;
		case ACTION_I6TR:
			if (translates_into_verb == TRANSLATION_DEPRECATED_FORM)
				translates_into_verb = TRANSLATION_ACCESSIBLE_TO_FORM;
			@<Require the accessible-to form@>;
			if (global_pass_state.pass == 2) Actions::translates(W, p2);
			break;
		case GRAMMAR_TOKEN_I6TR:
			if (translates_into_verb == TRANSLATION_DEPRECATED_FORM)
				translates_into_verb = TRANSLATION_DEFINED_BY_FORM;
			@<Require the defined-by form@>;
			if (global_pass_state.pass == 2) CommandGrammars::new_translated_token(W, p2);
			break;
	}

@<Require the accessible-to form@> =
	if (translates_into_verb != TRANSLATION_ACCESSIBLE_TO_FORM) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(...),
			"this is a language construct which cannot be defined in Inter code",
			"so although you can say 'X is accessible to Inter as Y' to give it "
			"an Inter identifier, you cannot say 'X translates into Inter as Y' or "
			"'X is defined by Inter as Y'.");
	}

@<Require the defined-by form@> =
	if (translates_into_verb != TRANSLATION_DEFINED_BY_FORM) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(...),
			"this is a language construct which cannot be given an Inter name "
			"except by defining it from Inter",
			"so although you can say 'X is defined by Inter as Y' to make "
			"this available to source text, you cannot say 'X translates into "
			"Inter as Y' or 'X is accessible to Inter as Y'.");
	}

@<Do not use the translates-into form@> =
	if (translates_into_verb == TRANSLATION_DEPRECATED_FORM) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(...),
			"the verb 'X translates into Inter as Y' (or '... into I6...') "
			"has been removed from Inform",
			"and should either be 'X is defined by Inter as Y' if Y is something "
			"whose definition is given in Inter - for example, for a rule defined in "
			"a kit - or else 'X is accessible to Inter as Y', if you just want a "
			"a name you can use from Inter code to refer to an X created by Inform.");
	}

@ Extra responses look just as they would in running code.

=
<extra-response> ::=
	<quoted-text> ( <response-letter> )  ==> { pass 2 }

@ =
void Translations::plus_responses(parse_node *p, rule *R) {
	if (Node::get_type(p) == AND_NT) {
		Translations::plus_responses(p->down, R);
		Translations::plus_responses(p->down->next, R);
	} else {
		if (<extra-response>(Node::get_text(p))) {
			int marker = <<r>>;
			Responses::set_via_translation(R, marker, Node::get_text(p));
		} else {
			StandardProblems::sentence_problem(Task::syntax_tree(),
				_p_(PM_I6ResponsesAwry),
				"additional information about I6 translation of a rule can "
				"only take the form of a list of responses",
				"each quoted and followed by a bracketed letter.");
		}
	}
}

@ As noted above, |NOUN_I6TR| renamings happen much later on.

@<Act on late naming@> =
	wording SP = Node::get_text(V->next);
	wording OP = Node::get_text(V->next->next);
	int category = Annotations::read_int(V, category_of_I6_translation_ANNOT);
	switch(category) {
		case NOUN_I6TR: {
			wording W = Wordings::trim_last_word(SP);
			parse_node *res = Lexicon::retrieve(NOUN_MC, W);
			if (res) {
				if (translates_into_verb == TRANSLATION_DEPRECATED_FORM)
					translates_into_verb = TRANSLATION_ACCESSIBLE_TO_FORM;
				@<Require the accessible-to form@>;
				noun_usage *nu = Nouns::disambiguate(res, FALSE);
				noun *nt = (nu)?(nu->noun_used):NULL;
				if (nt) {
					TEMPORARY_TEXT(i6r)
					WRITE_TO(i6r, "%N", Wordings::first_wn(OP));
					NounIdentifiers::noun_set_translation(nt, i6r);
					DISCARD_TEXT(i6r)
				}
			} else {
				if (<k-kind>(W)) {
					kind *K = (kind *) <<rp>>;
					@<Translate a kind@>;
				} else {
					LOG("So W = %W\n", W);
					StandardProblems::sentence_problem(Task::syntax_tree(),
						_p_(PM_BadObjectTranslation),
						"there is no such object or kind of object",
						"so its name will never be translated into an Inter "
						"identifier in any event.");
				}
			}
			break;
		}
	}

@<Translate a kind@> =
	@<Require the accessible-to form@>;
	TEMPORARY_TEXT(i6r)
	WRITE_TO(i6r, "%N", Wordings::first_wn(OP));
	if (Str::get_first_char(i6r) == '"') Str::delete_first_character(i6r);
	if (Str::get_last_char(i6r) == '"') Str::delete_last_character(i6r);
	inter_name *iname = RTKindDeclarations::iname(K);
	if (iname) {
		InterNames::set_translation(iname, i6r);
		InterNames::clear_flag(iname, MAKE_NAME_UNIQUE_ISYMF);
		Hierarchy::make_available(iname);
	}
	DISCARD_TEXT(i6r)
