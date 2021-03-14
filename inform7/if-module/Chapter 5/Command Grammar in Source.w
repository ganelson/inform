[CommandGrammarSource::] Command Grammar in Source.

Here we handle quoted command grammar arising in source text.

@ All quoted command grammar in the source text, whether from an Understand
sentence, a table column of topics, or a condition to match snippets of
commands, ends up here: see //Understand Sentences// for how.

The reference |ur| tells us what the grammar should refer to; it is non-|NULL|
for grammar originating in Understand sentences, but |NULL| for grammar
originating elsewhere. In that case, the reference is understood to be to the
special consultation grammar.

=
void CommandGrammarSource::in(wording W, understanding_reference *ur, wording WHENW) {
	int cg_is = CG_IS_COMMAND;
	if (ur == NULL) {
		UnderstandGeneralTokens::prepare_consultation_gv();
		cg_is = CG_IS_CONSULT;
	}

	int reversed = FALSE, mistake_text_at = 0, mistakenly = FALSE, pluralised = FALSE;
	wording file_under = EMPTY_WORDING;
	wording XW = EMPTY_WORDING;
	kind *K = NULL;
	action_name *an = NULL;
	cg_line *cgl = NULL;
	parse_node *to_pn = NULL;
	inference_subject *subj = NULL;
	property *cg_prn = NULL;
	parse_node *cgl_value = NULL;
	pcalc_prop *u_prop = NULL;

	mistake_text_at = 0;
	mistakenly = FALSE;
	if (ur) {
		an = ur->an_reference;
		pluralised = ur->pluralised_reference;
		reversed = ur->reversed_reference;
		if (ur->mword >= 0) mistake_text_at = ur->mword;
		if (ur->mistaken) mistakenly = TRUE;
		cg_is = ur->cg_result;
		if (cg_is == CG_IS_OBJECT) {
			cg_is = CG_IS_COMMAND;
			if (an == NULL) {
				instance *target;
				parse_node *spec = ur->spec_reference;
				target = Specifications::object_exactly_described_if_any(spec);
				if (target) {
					subj = Instances::as_subject(target);
					cg_is = CG_IS_OBJECT;
					if (Descriptions::is_qualified(spec)) {
						LOG("Offending description: $T", spec);
						StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_UnderstandAsQualified),
							"I cannot understand text as meaning an object "
							"qualified by relative clauses or properties",
							"only a specific thing, a specific value or a kind. "
							"(But the same effect can usually be achieved with "
							"a 'when' clause. For instance, although 'Understand "
							"\"bad luck\" as the broken mirror' is not allowed, "
							"'Understand \"bad luck\" as the mirror when the "
							"mirror is broken' produces the desired effect.)");
						return;
					}
				} else {
					RetryValue:
					LOGIF(GRAMMAR_CONSTRUCTION, "Understand as specification: $T", spec);
					if ((Specifications::is_kind_like(spec)) &&
						(Kinds::Behaviour::is_object(Specifications::to_kind(spec)) == FALSE)) goto ImpreciseProblemMessage;
					if (Specifications::is_phrasal(spec)) goto ImpreciseProblemMessage;
					if (Rvalues::is_nothing_object_constant(spec)) goto ImpreciseProblemMessage;
					if (Rvalues::is_rvalue(spec)) {
						K = Node::get_kind_of_value(spec);
						if (Kinds::Behaviour::request_I6_GPR(K)) {
							cgl_value = spec;
							cg_is = CG_IS_VALUE;
						} else {
							if (Kinds::get_construct(K) == CON_activity)
							StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_UnderstandAsActivity),
								"this 'understand ... as ...' gives text "
								"meaning an activity",
								"rather than an action. Since activities "
								"happen when Inform decides they need to "
								"happen, not in response to typed commands, "
								"this doesn't make sense.");
							else
							StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_UnderstandAsBadValue),
								"'understand ... as ...' gives text "
								"meaning a value whose kind is not allowed",
								"and should be a value such as 100.");
							return;
						}
					} else if (Specifications::is_description(spec)) {
						if ((Descriptions::to_instance(spec) == NULL) &&
							(Kinds::Behaviour::is_subkind_of_object(Specifications::to_kind(spec)) == FALSE)
							&& (Descriptions::number_of_adjectives_applied_to(spec) == 1)
							&& (AdjectivalPredicates::parity(Propositions::first_unary_predicate(Specifications::to_proposition(spec), NULL)))) {
							adjective *aph =
								AdjectivalPredicates::to_adjective(Propositions::first_unary_predicate(Specifications::to_proposition(spec), NULL));
							instance *q = AdjectiveAmbiguity::has_enumerative_meaning(aph);
							if (q) {
								spec = Rvalues::from_instance(q);
								goto RetryValue;
							}
							property *prn = AdjectiveAmbiguity::has_either_or_property_meaning(aph, NULL);
							if (prn) {
								cg_is = CG_IS_PROPERTY_NAME;
								cg_prn = prn;
								LOGIF(GRAMMAR_CONSTRUCTION, "Grammar confirmed for property $Y\n", cg_prn);
							}
						}
						if ((Descriptions::is_qualified(spec)) && (cg_prn == NULL)) {
							u_prop = Propositions::copy(Descriptions::to_proposition(spec));
							spec = Specifications::from_kind(Specifications::to_kind(spec));
						}
						kind *K = Specifications::to_kind(spec);
						if ((K) && (Kinds::Behaviour::is_subkind_of_object(K))) {
							subj = KindSubjects::from_kind(K);
							cg_is = CG_IS_OBJECT;
						} else if (cg_prn == NULL) goto ImpreciseProblemMessage;
					} else {
						ImpreciseProblemMessage:
						LOG("Offending pseudo-meaning is: $T", spec);
						Understand::issue_PM_UnderstandVague();
						return;
					}
				}
			}
		}
	}

	if ((pluralised) && (cg_is != CG_IS_OBJECT)) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_UnderstandPluralValue),
			"'understand' as a plural can only apply to things, rooms or kinds "
			"of things or rooms",
			"so 'Understand \"paperwork\" as the plural of a document.' is "
			"fine (assuming a document is a kind of thing), but 'Understand "
			"\"dozens\" as the plural of 12' is not.");
		return;
	}

	int i, skip = FALSE, literal_punct = FALSE; wchar_t *p = Lexer::word_text(Wordings::first_wn(W));
	for (i=0; p[i]; i++) {
		if (p[i] == '[') skip = TRUE;
		if (p[i] == ']') skip = FALSE;
		if (skip) continue;
		if ((p[i] == '.') || (p[i] == ',') ||
			(p[i] == '!') || (p[i] == '?') || (p[i] == ':') || (p[i] == ';'))
			literal_punct = TRUE;
	}
	if (literal_punct) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_LiteralPunctuation),
			"'understand' text cannot contain literal punctuation",
			"or more specifically cannot contain any of these: . , ! ? : ; "
			"since they are already used in various ways by the parser, and "
			"would not correctly match here.");
		return;
	}

	XW = Feeds::feed_C_string_full(Lexer::word_text(Wordings::first_wn(W)), TRUE, GRAMMAR_PUNCTUATION_MARKS);
	to_pn = Diagrams::new_UNPARSED_NOUN(W);
	UnderstandTokens::break_into_tokens(to_pn, XW);
	if (to_pn->down == NULL) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_UnderstandEmptyText),
			"'understand' should be followed by text which contains at least "
			"one word or square-bracketed token",
			"so for instance 'understand \"take [something]\" as taking' "
			"is fine, but 'understand \"\" as the fog' is not. The same "
			"applies to the contents of 'topic' columns in tables, since "
			"those are also instructions for understanding.");
		return;
	}
	if (cg_is == CG_IS_COMMAND) {
		LOGIF(GRAMMAR_CONSTRUCTION, "Command grammar: $T\n", to_pn);

		LOOP_THROUGH_WORDING(i, XW)
			if (i < Wordings::last_wn(XW))
				if ((compare_word(i, COMMA_V)) && (compare_word(i+1, COMMA_V))) {
					StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_UnderstandCommaCommand),
						"'understand' as an action cannot involve a comma",
						"since a command leading to an action never does. "
						"(Although Inform understands commands like 'PETE, LOOK' "
						"only the part after the comma is read as an action command: "
						"the part before the comma is read as the name of someone, "
						"according to the usual rules for parsing a name.) "
						"Because of the way Inform processes text with square "
						"brackets, this problem message is also sometimes seen "
						"if empty square brackets are used, as in 'Understand "
						"\"bless []\" as blessing.'");
					return;
				}

		if (UnderstandTokens::is_literal(to_pn->down) == FALSE)
			file_under = EMPTY_WORDING; /* this will go into the no verb verb */
		else file_under = Wordings::first_word(Node::get_text(to_pn->down));
	}
	LOGIF(GRAMMAR, "CG is %d, an is $l, file under is %W\n", cg_is, an, file_under);
	if (cg_is != CG_IS_COMMAND) cgl = UnderstandLines::new(Wordings::first_wn(W), NULL, to_pn, reversed, pluralised);
	else cgl = UnderstandLines::new(Wordings::first_wn(W), an, to_pn, reversed, pluralised);
	if (mistakenly) UnderstandLines::set_mistake(cgl, mistake_text_at);
	if (Wordings::nonempty(WHENW)) {
		UnderstandLines::set_understand_when(cgl, WHENW);
		if (cg_is == CG_IS_CONSULT) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(BelievedImpossible), /* at present, I7 syntax prevents this anyway */
				"'when' cannot be used with this kind of 'Understand'",
				"for the time being at least.");
			return;
		}
	}
	if (Wordings::nonempty(WHENW)) {
		UnderstandLines::set_understand_when(cgl, WHENW);
		if (cg_is == CG_IS_CONSULT) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(BelievedImpossible), /* at present, I7 syntax prevents this anyway */
				"'when' cannot be used with this kind of 'Understand'",
				"for the time being at least.");
			return;
		}
	}
	if (u_prop) {
		UnderstandLines::set_understand_prop(cgl, u_prop);
		if (cg_is == CG_IS_CONSULT) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(BelievedImpossible), /* at present, I7 syntax prevents this anyway */
				"'when' cannot be used with this kind of 'Understand'",
				"for the time being at least.");
			return;
		}
	}

	switch(cg_is) {
		case CG_IS_TOKEN:
			XW = Feeds::feed_C_string_full(Lexer::word_text(Wordings::first_wn(ur->reference_text)), TRUE, GRAMMAR_PUNCTUATION_MARKS);
			LOGIF(GRAMMAR_CONSTRUCTION, "CG_IS_TOKEN as words: %W\n", XW);
			if (CommandGrammarSource::valid_new_token_name(XW) == FALSE) {
				StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_UnderstandAsCompoundText),
					"if 'understand ... as ...' gives the meaning as text "
					"then it must describe a single new token",
					"so that 'Understand \"group four/five/six\" as "
					"\"[department]\"' is legal (defining a new token "
					"\"[department]\", or adding to its definition if it "
					"already existed) but 'Understand \"take [thing]\" "
					"as \"drop [thing]\"' is not allowed, and would not "
					"make sense, because \"drop [thing]\" is a combination "
					"of two existing tokens - not a single new one.");
			}
			CommandGrammars::add_line(CommandGrammars::named_token_new(Wordings::trim_both_ends(Wordings::trim_both_ends(XW))), cgl);
			break;
		case CG_IS_COMMAND:
			CommandGrammars::add_line(CommandGrammars::find_or_create_command(file_under), cgl);
			break;
		case CG_IS_OBJECT:
			CommandGrammars::add_line(CommandGrammars::for_subject(subj), cgl);
			break;
		case CG_IS_VALUE:
			UnderstandLines::set_single_type(cgl, cgl_value);
			CommandGrammars::add_line(CommandGrammars::for_kind(K), cgl);
			break;
		case CG_IS_PROPERTY_NAME:
			CommandGrammars::add_line(CommandGrammars::for_prn(cg_prn), cgl);
			break;
		case CG_IS_CONSULT:
			UnderstandLines::set_single_type(cgl, cgl_value);
			CommandGrammars::add_line(
				UnderstandGeneralTokens::get_consultation_gv(), cgl);
			break;
	}
}

int CommandGrammarSource::valid_new_token_name(wording W) {
	int cc=0;
	LOOP_THROUGH_WORDING(i, W)
		if (compare_word(i, COMMA_V)) cc++;
	Word::dequote(Wordings::first_wn(W));
	if (*(Lexer::word_text(Wordings::first_wn(W))) != 0) return FALSE;
	Word::dequote(Wordings::last_wn(W));
	if (*(Lexer::word_text(Wordings::last_wn(W))) != 0) return FALSE;
	if (cc != 2) return FALSE;
	return TRUE;
}

