[RTCommandGrammarLines::] Command Grammar Lines.

Runtime support for CGLs.

@

=
typedef struct cg_line_compilation_data {
	int suppress_compilation; /* has been compiled in a single I6 grammar token already? */
	struct inter_name *cond_token_iname; /* for its |Cond_Token_*| routine, if any */
	struct inter_name *mistake_iname; /* for its |Mistake_Token_*| routine, if any */
} cg_line_compilation_data;

cg_line_compilation_data RTCommandGrammarLines::new_cd(cg_line *cg) {
	cg_line_compilation_data cglcd;
	cglcd.suppress_compilation = FALSE;
	cglcd.cond_token_iname = NULL;
	cglcd.mistake_iname = NULL;
	return cglcd;
}

@ These are grammar lines used in command CGs for commands which are accepted
but only in order to print nicely worded rejections. A number of schemes
were tried for this, for instance producing parser errors and setting |pe|
to some high value, but the method now used is for a mistaken line to
produce a successful parse at the I6 level, resulting in the (I6 only)
action |##MistakeAction|. The tricky part is to send information to the
I6 action routine |MistakeActionSub| indicating what the mistake was,
exactly: we do this by including, in the I6 grammar, a token which
matches empty text and returns a "preposition", so that it has no
direct result, but which also sets a special global variable as a
side-effect. Thus a mistaken line "act [thing]" comes out as something
like:

|* Mistake_Token_12 'act' noun -> MistakeAction|

Since the I6 parser accepts the first command which matches, and since
none of this can be recursive, the value of this variable at the end of
I6 parsing is guaranteed to be the one set during the line causing
the mistake.

=
void RTCommandGrammarLines::set_mistake(cg_line *cgl, wording MW) {
	if (cgl->compilation_data.mistake_iname == NULL) {
		package_request *PR = Hierarchy::local_package(MISTAKES_HAP);
		cgl->compilation_data.mistake_iname = Hierarchy::make_iname_in(MISTAKE_FN_HL, PR);
	}
}

void RTCommandGrammarLines::cgl_compile_mistake_token_as_needed(cg_line *cgl) {
	if (cgl->mistaken) {
		packaging_state save = Functions::begin(cgl->compilation_data.mistake_iname);

		Produce::inv_primitive(Emit::tree(), IF_BIP);
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), NE_BIP);
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(ACTOR_HL));
				Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(PLAYER_HL));
			Produce::up(Emit::tree());
			Produce::code(Emit::tree());
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), RETURN_BIP);
				Produce::down(Emit::tree());
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(GPR_FAIL_HL));
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());

		Produce::inv_primitive(Emit::tree(), STORE_BIP);
		Produce::down(Emit::tree());
			Produce::ref_iname(Emit::tree(), K_number, Hierarchy::find(UNDERSTAND_AS_MISTAKE_NUMBER_HL));
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) (100 + cgl->allocation_id));
		Produce::up(Emit::tree());

		Produce::inv_primitive(Emit::tree(), RETURN_BIP);
		Produce::down(Emit::tree());
			Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(GPR_PREPOSITION_HL));
		Produce::up(Emit::tree());

		Functions::end(save);
	}
}

void RTCommandGrammarLines::cgl_compile_extra_token_for_mistake(cg_line *cgl, int cg_is) {
	if (cgl->mistaken) {
		if (cg_is == CG_IS_COMMAND) {
			Emit::array_iname_entry(cgl->compilation_data.mistake_iname);
		} else
			internal_error("CGLs may only be mistaken in command grammar");
	}
}

inter_name *MistakeAction_iname = NULL;

int RTCommandGrammarLines::cgl_compile_result_of_mistake(gpr_kit *gprk, cg_line *cgl) {
	if (cgl->mistaken) {
		if (MistakeAction_iname == NULL) internal_error("no MistakeAction yet");
		Emit::array_iname_entry(VERB_DIRECTIVE_RESULT_iname);
		Emit::array_iname_entry(MistakeAction_iname);
		return TRUE;
	}
	return FALSE;
}

void RTCommandGrammarLines::MistakeActionSub_routine(void) {
	package_request *MAP = Hierarchy::synoptic_package(SACTIONS_HAP);
	packaging_state save = Functions::begin(Hierarchy::make_iname_in(MISTAKEACTIONSUB_HL, MAP));

	Produce::inv_primitive(Emit::tree(), SWITCH_BIP);
	Produce::down(Emit::tree());
		Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(UNDERSTAND_AS_MISTAKE_NUMBER_HL));
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			cg_line *cgl;
			LOOP_OVER(cgl, cg_line)
				if (cgl->mistaken) {
					current_sentence = cgl->where_grammar_specified;
					parse_node *spec = NULL;
					if (Wordings::empty(cgl->mistake_response_text))
						spec = Specifications::new_UNKNOWN(cgl->mistake_response_text);
					else if (<s-value>(cgl->mistake_response_text)) spec = <<rp>>;
					else spec = Specifications::new_UNKNOWN(cgl->mistake_response_text);
					Produce::inv_primitive(Emit::tree(), CASE_BIP);
					Produce::down(Emit::tree());
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) (100+cgl->allocation_id));
						Produce::code(Emit::tree());
						Produce::down(Emit::tree());
							Produce::inv_call_iname(Emit::tree(), Hierarchy::find(PARSERERROR_HL));
							Produce::down(Emit::tree());
								CompileValues::to_code_val_of_kind(spec, K_text);
							Produce::up(Emit::tree());
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
				}

			Produce::inv_primitive(Emit::tree(), DEFAULT_BIP);
			Produce::down(Emit::tree());
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), PRINT_BIP);
					Produce::down(Emit::tree());
						Produce::val_text(Emit::tree(), I"I didn't understand that sentence.\n");
					Produce::up(Emit::tree());
					Produce::rtrue(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Produce::down(Emit::tree());
		Produce::ref_iname(Emit::tree(), K_number, Hierarchy::find(SAY__P_HL));
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1);
	Produce::up(Emit::tree());

	Functions::end(save);
	
	MistakeAction_iname = Hierarchy::make_iname_in(MISTAKEACTION_HL, MAP);
	Emit::named_pseudo_numeric_constant(MistakeAction_iname, K_action_name, 10000);
	Produce::annotate_i(MistakeAction_iname, ACTION_IANN, 1);
	Hierarchy::make_available(Emit::tree(), MistakeAction_iname);
}

void RTCommandGrammarLines::cgl_compile_condition_token_as_needed(cg_line *cgl) {
	if (CGLines::conditional(cgl)) {
		current_sentence = cgl->where_grammar_specified;

		package_request *PR = Hierarchy::local_package(COND_TOKENS_HAP);
		cgl->compilation_data.cond_token_iname = Hierarchy::make_iname_in(CONDITIONAL_TOKEN_FN_HL, PR);

		packaging_state save = Functions::begin(cgl->compilation_data.cond_token_iname);

		parse_node *spec = CGLines::get_understand_cond(cgl);
		pcalc_prop *prop = cgl->understand_when_prop;

		if ((spec) || (prop)) {
			Produce::inv_primitive(Emit::tree(), IF_BIP);
			Produce::down(Emit::tree());
				if ((spec) && (prop)) {
					Produce::inv_primitive(Emit::tree(), AND_BIP);
					Produce::down(Emit::tree());
				}
				if (spec) CompileValues::to_code_val_of_kind(spec, K_truth_state);
				if (prop) Calculus::Deferrals::emit_test_of_proposition(Rvalues::new_self_object_constant(), prop);
				if ((spec) && (prop)) {
					Produce::up(Emit::tree());
				}
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), RETURN_BIP);
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(GPR_PREPOSITION_HL));
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		}
		Produce::inv_primitive(Emit::tree(), RETURN_BIP);
		Produce::down(Emit::tree());
			Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(GPR_FAIL_HL));
		Produce::up(Emit::tree());

		Functions::end(save);
	}
}

void RTCommandGrammarLines::cgl_compile_extra_token_for_condition(gpr_kit *gprk, cg_line *cgl,
	int cg_is, inter_symbol *current_label) {
	if (CGLines::conditional(cgl)) {
		if (cgl->compilation_data.cond_token_iname == NULL) internal_error("CGL cond token not ready");
		if (cg_is == CG_IS_COMMAND) {
			Emit::array_iname_entry(cgl->compilation_data.cond_token_iname);
		} else {
			Produce::inv_primitive(Emit::tree(), IF_BIP);
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), EQ_BIP);
				Produce::down(Emit::tree());
					Produce::inv_call_iname(Emit::tree(), cgl->compilation_data.cond_token_iname);
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(GPR_FAIL_HL));
				Produce::up(Emit::tree());
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), JUMP_BIP);
					Produce::down(Emit::tree());
						Produce::lab(Emit::tree(), current_label);
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		}
	}
}

@h Phase IV: Compile Grammar.
At this level we compile the list of CGLs in sorted order: this is what the
sorting was all for. In certain cases, we skip any CGLs marked as "one word":
these are cases arising from, e.g., "Understand "frog" as the toad.",
where we noticed that the CGL was a single word and included it in the |name|
property instead. This is faster and more flexible, besides writing tidier
code.

The need for this is not immediately obvious. After all, shouldn't we have
simply deleted the CGL in the first place, rather than leaving it in but
marking it? The answer is no, because of the way inheritance works: values
of the |name| property accumulate from class to instance in I6, since
|name| is additive, but grammar doesn't.

=
void RTCommandGrammarLines::sorted_line_list_compile(gpr_kit *gprk,
	int cg_is, command_grammar *cg, int genuinely_verbal) {
	LOG_INDENT;
	LOOP_THROUGH_SORTED_CG_LINES(cgl, cg)
		if (cgl->compilation_data.suppress_compilation == FALSE)
			RTCommandGrammarLines::compile_cg_line(gprk, cgl, cg_is, cg, genuinely_verbal);
	LOG_OUTDENT;
}

@ The following apparently global variables are used to provide a persistent
state for the routine below, but are not accessed elsewhere. The label
counter is reset at the start of each CG's compilation, though this is a
purely cosmetic effect.

=
int current_grammar_block = 0;
int current_label = 1;
int GV_IS_VALUE_instance_mode = FALSE;

void RTCommandGrammarLines::reset_labels(void) {
	current_label = 1;
}

@ As fancy as the following routine may look, it contains very little.
What complexity there is comes from the fact that command CGs are compiled
very differently to all others (most grammars are compiled in "code mode",
generating procedural I6 statements, but command CGs are compiled to lines
in |Verb| directives) and that CGLs resulting in actions (i.e., CGLs in
command CGs) have not yet been type-checked, whereas all others have.

=
void RTCommandGrammarLines::compile_cg_line(gpr_kit *gprk, cg_line *cgl, int cg_is, command_grammar *cg,
	int genuinely_verbal) {
	int i;
	int token_values;
	kind *token_value_kinds[2];
	int code_mode, consult_mode;

	LOGIF(GRAMMAR, "Compiling grammar line: $g\n", cgl);

	current_sentence = cgl->where_grammar_specified;

	if (cg_is == CG_IS_COMMAND) code_mode = FALSE; else code_mode = TRUE;
	if (cg_is == CG_IS_CONSULT) consult_mode = TRUE; else consult_mode = FALSE;

	switch (cg_is) {
		case CG_IS_COMMAND:
		case CG_IS_TOKEN:
		case CG_IS_CONSULT:
		case CG_IS_SUBJECT:
		case CG_IS_VALUE:
		case CG_IS_PROPERTY_NAME:
			break;
		default: internal_error("tried to compile unknown CG type");
	}

	current_grammar_block++;
	token_values = 0;
	for (i=0; i<2; i++) token_value_kinds[i] = NULL;

	if (code_mode == FALSE) Emit::array_iname_entry(VERB_DIRECTIVE_DIVIDER_iname);

	inter_symbol *fail_label = NULL;

	if (gprk) {
		TEMPORARY_TEXT(L)
		WRITE_TO(L, ".Fail_%d", current_label);
		fail_label = Produce::reserve_label(Emit::tree(), L);
		DISCARD_TEXT(L)
	}

	RTCommandGrammarLines::cgl_compile_extra_token_for_condition(gprk, cgl, cg_is, fail_label);
	RTCommandGrammarLines::cgl_compile_extra_token_for_mistake(cgl, cg_is);

	cg_token *cgt = cgl->tokens;
	if ((genuinely_verbal) && (cgt)) {
		if (cgt->slash_class != 0) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_SlashedCommand),
				"at present you're not allowed to use a / between command "
				"words at the start of a line",
				"so 'put/interpose/insert [something]' is out.");
			return;
		}
		cgt = cgt->next_token; /* skip command word: the |Verb| header contains it already */
	}

	if ((cg_is == CG_IS_VALUE) && (GV_IS_VALUE_instance_mode)) {
		Produce::inv_primitive(Emit::tree(), IF_BIP);
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), EQ_BIP);
			Produce::down(Emit::tree());
				Produce::val_symbol(Emit::tree(), K_value, gprk->instance_s);
				RTCommandGrammars::emit_determination_type(&(cgl->cgl_type));
			Produce::up(Emit::tree());
			Produce::code(Emit::tree());
			Produce::down(Emit::tree());
	}

	cg_token *cgt_from = cgt, *cgt_to = cgt_from;
	for (; cgt; cgt = cgt->next_token) cgt_to = cgt;
	RTCommandGrammarLines::compile_token_line(gprk, code_mode, cgt_from, cgt_to, cg_is, consult_mode, &token_values, token_value_kinds, NULL, fail_label);

	switch (cg_is) {
		case CG_IS_COMMAND:
			if (RTCommandGrammarLines::cgl_compile_result_of_mistake(gprk, cgl)) break;
			Emit::array_iname_entry(VERB_DIRECTIVE_RESULT_iname);
			Emit::array_action_entry(cgl->resulting_action);

			if (cgl->reversed) {
				if (token_values < 2) {
					StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_CantReverseOne),
						"you can't use a 'reversed' action when you supply fewer "
						"than two values for it to apply to",
						"since reversal is the process of exchanging them.");
					return;
				}
				kind *swap = token_value_kinds[0];
				token_value_kinds[0] = token_value_kinds[1];
				token_value_kinds[1] = swap;
				Emit::array_iname_entry(VERB_DIRECTIVE_REVERSE_iname);
			}

			ActionSemantics::check_valid_application(cgl->resulting_action, token_values,
				token_value_kinds);
			break;
		case CG_IS_PROPERTY_NAME:
		case CG_IS_TOKEN:
			Produce::inv_primitive(Emit::tree(), RETURN_BIP);
			Produce::down(Emit::tree());
				Produce::val_symbol(Emit::tree(), K_value, gprk->rv_s);
			Produce::up(Emit::tree());
			Produce::place_label(Emit::tree(), fail_label);
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Produce::down(Emit::tree());
				Produce::ref_symbol(Emit::tree(), K_value, gprk->rv_s);
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(GPR_PREPOSITION_HL));
			Produce::up(Emit::tree());
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Produce::down(Emit::tree());
				Produce::ref_iname(Emit::tree(), K_value, Hierarchy::find(WN_HL));
				Produce::val_symbol(Emit::tree(), K_value, gprk->original_wn_s);
			Produce::up(Emit::tree());
			break;
		case CG_IS_CONSULT:
			Produce::inv_primitive(Emit::tree(), IF_BIP);
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), OR_BIP);
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), EQ_BIP);
					Produce::down(Emit::tree());
						Produce::val_symbol(Emit::tree(), K_value, gprk->range_words_s);
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
					Produce::up(Emit::tree());
					Produce::inv_primitive(Emit::tree(), EQ_BIP);
					Produce::down(Emit::tree());
						Produce::inv_primitive(Emit::tree(), MINUS_BIP);
						Produce::down(Emit::tree());
							Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(WN_HL));
							Produce::val_symbol(Emit::tree(), K_value, gprk->range_from_s);
						Produce::up(Emit::tree());
						Produce::val_symbol(Emit::tree(), K_value, gprk->range_words_s);
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), RETURN_BIP);
					Produce::down(Emit::tree());
						Produce::val_symbol(Emit::tree(), K_value, gprk->rv_s);
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());

			Produce::place_label(Emit::tree(), fail_label);
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Produce::down(Emit::tree());
				Produce::ref_symbol(Emit::tree(), K_value, gprk->rv_s);
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(GPR_PREPOSITION_HL));
			Produce::up(Emit::tree());
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Produce::down(Emit::tree());
				Produce::ref_iname(Emit::tree(), K_value, Hierarchy::find(WN_HL));
				Produce::val_symbol(Emit::tree(), K_value, gprk->original_wn_s);
			Produce::up(Emit::tree());
			break;
		case CG_IS_SUBJECT:
			UnderstandGeneralTokens::after_gl_failed(gprk, fail_label, cgl->pluralised);
			break;
		case CG_IS_VALUE:
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Produce::down(Emit::tree());
				Produce::ref_iname(Emit::tree(), K_value, Hierarchy::find(PARSED_NUMBER_HL));
				RTCommandGrammars::emit_determination_type(&(cgl->cgl_type));
			Produce::up(Emit::tree());
			Produce::inv_primitive(Emit::tree(), RETURN_BIP);
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(GPR_NUMBER_HL));
			Produce::up(Emit::tree());
			Produce::place_label(Emit::tree(), fail_label);
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Produce::down(Emit::tree());
				Produce::ref_iname(Emit::tree(), K_value, Hierarchy::find(WN_HL));
				Produce::val_symbol(Emit::tree(), K_value, gprk->original_wn_s);
			Produce::up(Emit::tree());
			break;
	}

	if ((cg_is == CG_IS_VALUE) && (GV_IS_VALUE_instance_mode)) {
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
	}

	current_label++;
}

@ =
typedef struct slash_gpr {
	struct cg_token *first_choice;
	struct cg_token *last_choice;
	struct inter_name *sgpr_iname;
	CLASS_DEFINITION
} slash_gpr;

@ =
void RTCommandGrammarLines::compile_token_line(gpr_kit *gprk, int code_mode, cg_token *cgt, cg_token *cgt_to, int cg_is, int consult_mode,
	int *token_values, kind **token_value_kinds, inter_symbol *group_wn_s, inter_symbol *fail_label) {
	int lexeme_equivalence_class = 0;
	int alternative_number = 0;
	int empty_text_allowed_in_lexeme = FALSE;
	inter_symbol *next_reserved_label = NULL;
	inter_symbol *eog_reserved_label = NULL;
	LOGIF(GRAMMAR_CONSTRUCTION, "Compiling token range $c -> $c\n", cgt, cgt_to);
	LOG_INDENT;
	for (; cgt; cgt = cgt->next_token) {
		LOGIF(GRAMMAR_CONSTRUCTION, "Compiling token $c\n", cgt);
		if ((CGTokens::is_topic(cgt)) && (cgt->next_token) &&
			(CGTokens::is_literal(cgt->next_token) == FALSE)) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TextFollowedBy),
				"a '[text]' token must either match the end of some text, or "
				"be followed by definitely known wording",
				"since otherwise the run-time parser isn't good enough to "
				"make sense of things.");
		}

		if ((cgt->token_relation) && (cg_is != CG_IS_SUBJECT)) {
			if (problem_count == 0)
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_GrammarObjectlessRelation),
				"a grammar token in an 'Understand...' can only be based "
				"on a relation if it is to understand the name of a room or thing",
				"since otherwise there is nothing for the relation to be with.");
			continue;
		}

		int first_token_in_lexeme = FALSE, last_token_in_lexeme = FALSE;

		if (cgt->slash_class != 0) { /* in a multi-token lexeme */
			if ((cgt->next_token == NULL) ||
				(cgt->next_token->slash_class != cgt->slash_class))
				last_token_in_lexeme = TRUE;
			if (cgt->slash_class != lexeme_equivalence_class) {
				first_token_in_lexeme = TRUE;
				empty_text_allowed_in_lexeme = cgt->slash_dash_dash;
			}
			lexeme_equivalence_class = cgt->slash_class;
			if (first_token_in_lexeme) alternative_number = 1;
			else alternative_number++;
		} else { /* in a single-token lexeme */
			lexeme_equivalence_class = 0;
			first_token_in_lexeme = TRUE;
			last_token_in_lexeme = TRUE;
			empty_text_allowed_in_lexeme = FALSE;
			alternative_number = 1;
		}

		inter_symbol *jump_on_fail = fail_label;

		if (lexeme_equivalence_class > 0) {
			if (code_mode) {
				if (first_token_in_lexeme) {
					Produce::inv_primitive(Emit::tree(), STORE_BIP);
					Produce::down(Emit::tree());
						Produce::ref_symbol(Emit::tree(), K_value, gprk->group_wn_s);
						Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(WN_HL));
					Produce::up(Emit::tree());
				}
				if (next_reserved_label) Produce::place_label(Emit::tree(), next_reserved_label);
				TEMPORARY_TEXT(L)
				WRITE_TO(L, ".group_%d_%d_%d", current_grammar_block, lexeme_equivalence_class, alternative_number+1);
				next_reserved_label = Produce::reserve_label(Emit::tree(), L);
				DISCARD_TEXT(L)

				Produce::inv_primitive(Emit::tree(), STORE_BIP);
				Produce::down(Emit::tree());
					Produce::ref_iname(Emit::tree(), K_value, Hierarchy::find(WN_HL));
					Produce::val_symbol(Emit::tree(), K_value, gprk->group_wn_s);
				Produce::up(Emit::tree());

				if ((last_token_in_lexeme == FALSE) || (empty_text_allowed_in_lexeme)) {
					jump_on_fail = next_reserved_label;
				}
			}
		}

		if ((empty_text_allowed_in_lexeme) && (code_mode == FALSE)) {
			slash_gpr *sgpr = CREATE(slash_gpr);
			sgpr->first_choice = cgt;
			while ((cgt->next_token) &&
					(cgt->next_token->slash_class ==
					cgt->slash_class)) cgt = cgt->next_token;
			sgpr->last_choice = cgt;
			package_request *PR = Hierarchy::local_package(SLASH_TOKENS_HAP);
			sgpr->sgpr_iname = Hierarchy::make_iname_in(SLASH_FN_HL, PR);
			Emit::array_iname_entry(sgpr->sgpr_iname);
			last_token_in_lexeme = TRUE;
		} else {
			kind *grammar_token_kind =
				RTCommandGrammarLines::compile_token(gprk, cgt, code_mode, jump_on_fail, consult_mode);
			if (grammar_token_kind) {
				if (token_values) {
					if (*token_values == 2) {
						internal_error(
							"There can be at most two value-producing tokens and this "
							"should have been detected earlier.");
						return;
					}
					token_value_kinds[(*token_values)++] = grammar_token_kind;
				}
			}
		}

		if (lexeme_equivalence_class > 0) {
			if (code_mode) {
				if (last_token_in_lexeme) {
					if (empty_text_allowed_in_lexeme) {
						@<Jump to end of group@>;
						if (next_reserved_label)
							Produce::place_label(Emit::tree(), next_reserved_label);
						next_reserved_label = NULL;
						Produce::inv_primitive(Emit::tree(), STORE_BIP);
						Produce::down(Emit::tree());
							Produce::ref_iname(Emit::tree(), K_value, Hierarchy::find(WN_HL));
							Produce::val_symbol(Emit::tree(), K_value, gprk->group_wn_s);
						Produce::up(Emit::tree());
					}
					if (eog_reserved_label) Produce::place_label(Emit::tree(), eog_reserved_label);
					eog_reserved_label = NULL;
				} else {
					@<Jump to end of group@>;
				}
			} else {
				if (last_token_in_lexeme == FALSE) Emit::array_iname_entry(VERB_DIRECTIVE_SLASH_iname);
			}
		}

		if (cgt == cgt_to) break;
	}
	LOG_OUTDENT;
}

@<Jump to end of group@> =
	if (eog_reserved_label == NULL) {
		TEMPORARY_TEXT(L)
		WRITE_TO(L, ".group_%d_%d_end",
			current_grammar_block, lexeme_equivalence_class);
		eog_reserved_label = Produce::reserve_label(Emit::tree(), L);
	}
	Produce::inv_primitive(Emit::tree(), JUMP_BIP);
	Produce::down(Emit::tree());
		Produce::lab(Emit::tree(), eog_reserved_label);
	Produce::up(Emit::tree());

@ =
void RTCommandGrammarLines::compile_slash_gprs(void) {
	slash_gpr *sgpr;
	LOOP_OVER(sgpr, slash_gpr) {
		packaging_state save = Functions::begin(sgpr->sgpr_iname);
		gpr_kit gprk = UnderstandValueTokens::new_kit();
		UnderstandValueTokens::add_original(&gprk);
		UnderstandValueTokens::add_standard_set(&gprk);

		RTCommandGrammarLines::compile_token_line(&gprk, TRUE, sgpr->first_choice, sgpr->last_choice, CG_IS_TOKEN, FALSE, NULL, NULL, gprk.group_wn_s, NULL);
		Produce::inv_primitive(Emit::tree(), RETURN_BIP);
		Produce::down(Emit::tree());
			Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(GPR_PREPOSITION_HL));
		Produce::up(Emit::tree());
		Functions::end(save);
	}
}

@ This function looks through a CGL list and marks to suppress all those
CGLs consisting only of single unconditional words, which means they
will not be compiled into a |parse_name| routine (or anywhere else).
If the |of| file handle is set, then the words in question are emitted as
a stream of dictionary words. In practice, this is done when
compiling the |name| property, so that a single scan achieves both
the transfer into |name| and the exclusion from |parse_name| of
affected CGLs.

=
void RTCommandGrammarLines::list_take_out_one_word_grammar(command_grammar *cg) {
	LOOP_THROUGH_UNSORTED_CG_LINES(cgl, cg) {
		int wn = CGLines::cgl_contains_single_unconditional_word(cgl);
		if (wn >= 0) {
			TEMPORARY_TEXT(content)
			WRITE_TO(content, "%w", Lexer::word_text(wn));
			Emit::array_dword_entry(content);
			DISCARD_TEXT(content)
			cgl->compilation_data.suppress_compilation = TRUE;
		}
	}
}


@h Tokens.
In code mode, we compile a test that the token matches, jumping to the
failure label if it doesn't, and setting the I6 local variable |rv| to a
suitable GPR return value if it does match and produces an outcome.
We are allowed to use the I6 local |w| for temporary storage, but
nothing else.

=
int ol_loop_counter = 0;
kind *RTCommandGrammarLines::compile_token(gpr_kit *gprk, cg_token *cgt, int code_mode,
	inter_symbol *failure_label, int consult_mode) {
	int wn = Wordings::first_wn(CGTokens::text(cgt));
	parse_node *spec;
	binary_predicate *bp;
	command_grammar *cg;
	if (CGTokens::is_literal(cgt)) {
		if (code_mode) {
			Produce::inv_primitive(Emit::tree(), IF_BIP);
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), NE_BIP);
				Produce::down(Emit::tree());
					Produce::inv_call_iname(Emit::tree(), Hierarchy::find(NEXTWORDSTOPPED_HL));
					TEMPORARY_TEXT(N)
					WRITE_TO(N, "%N", wn);
					Produce::val_dword(Emit::tree(), N);
					DISCARD_TEXT(N)
				Produce::up(Emit::tree());
				@<Then jump to our doom@>;
			Produce::up(Emit::tree());
		} else {
			TEMPORARY_TEXT(WT)
			WRITE_TO(WT, "%N", wn);
			Emit::array_dword_entry(WT);
			DISCARD_TEXT(WT)
		}
		return NULL;
	}

	bp = cgt->token_relation;
	if (bp) {
		Produce::inv_call_iname(Emit::tree(), Hierarchy::find(ARTICLEDESCRIPTORS_HL));
		Produce::inv_primitive(Emit::tree(), STORE_BIP);
		Produce::down(Emit::tree());
			Produce::ref_symbol(Emit::tree(), K_value, gprk->w_s);
			Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(WN_HL));
		Produce::up(Emit::tree());
		if (bp == R_containment) {
			Produce::inv_primitive(Emit::tree(), IF_BIP);
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), NOT_BIP);
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), HAS_BIP);
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(SELF_HL));
						Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(CONTAINER_HL));
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
				@<Then jump to our doom@>;
			Produce::up(Emit::tree());
		}
		if (bp == R_support) {
			Produce::inv_primitive(Emit::tree(), IF_BIP);
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), NOT_BIP);
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), HAS_BIP);
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(SELF_HL));
						Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(SUPPORTER_HL));
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
				@<Then jump to our doom@>;
			Produce::up(Emit::tree());
		}
		if ((bp == a_has_b_predicate) || (bp == R_wearing) ||
			(bp == R_carrying)) {
			Produce::inv_primitive(Emit::tree(), IF_BIP);
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), NOT_BIP);
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), HAS_BIP);
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(SELF_HL));
						Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(ANIMATE_HL));
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
				@<Then jump to our doom@>;
			Produce::up(Emit::tree());
		}
		if ((bp == R_containment) ||
			(bp == R_support) ||
			(bp == a_has_b_predicate) ||
			(bp == R_wearing) ||
			(bp == R_carrying)) {
			TEMPORARY_TEXT(L)
			WRITE_TO(L, ".ol_mm_%d", ol_loop_counter++);
			inter_symbol *exit_label = Produce::reserve_label(Emit::tree(), L);
			DISCARD_TEXT(L)

			Produce::inv_primitive(Emit::tree(), OBJECTLOOP_BIP);
			Produce::down(Emit::tree());
				Produce::ref_symbol(Emit::tree(), K_value, gprk->rv_s);
				Produce::val_iname(Emit::tree(), K_value, RTKinds::I6_classname(K_object));
				Produce::inv_primitive(Emit::tree(), IN_BIP);
				Produce::down(Emit::tree());
					Produce::val_symbol(Emit::tree(), K_value, gprk->rv_s);
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(SELF_HL));
				Produce::up(Emit::tree());
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					if (bp == R_carrying) {
						Produce::inv_primitive(Emit::tree(), IF_BIP);
						Produce::down(Emit::tree());
							Produce::inv_primitive(Emit::tree(), HAS_BIP);
							Produce::down(Emit::tree());
								Produce::val_symbol(Emit::tree(), K_value, gprk->rv_s);
								Produce::val_iname(Emit::tree(), K_value, RTProperties::iname(P_worn));
							Produce::up(Emit::tree());
							Produce::code(Emit::tree());
							Produce::down(Emit::tree());
								Produce::inv_primitive(Emit::tree(), CONTINUE_BIP);
							Produce::up(Emit::tree());
						Produce::up(Emit::tree());
					}
					if (bp == R_wearing) {
						Produce::inv_primitive(Emit::tree(), IF_BIP);
						Produce::down(Emit::tree());
							Produce::inv_primitive(Emit::tree(), NOT_BIP);
							Produce::down(Emit::tree());
								Produce::inv_primitive(Emit::tree(), HAS_BIP);
								Produce::down(Emit::tree());
									Produce::val_symbol(Emit::tree(), K_value, gprk->rv_s);
									Produce::val_iname(Emit::tree(), K_value, RTProperties::iname(P_worn));
								Produce::up(Emit::tree());
							Produce::up(Emit::tree());
							Produce::code(Emit::tree());
							Produce::down(Emit::tree());
								Produce::inv_primitive(Emit::tree(), CONTINUE_BIP);
							Produce::up(Emit::tree());
						Produce::up(Emit::tree());
					}
					Produce::inv_primitive(Emit::tree(), STORE_BIP);
					Produce::down(Emit::tree());
						Produce::ref_iname(Emit::tree(), K_value, Hierarchy::find(WN_HL));
						Produce::val_symbol(Emit::tree(), K_value, gprk->w_s);
					Produce::up(Emit::tree());
					Produce::inv_primitive(Emit::tree(), STORE_BIP);
					Produce::down(Emit::tree());
						Produce::ref_iname(Emit::tree(), K_value, Hierarchy::find(WN_HL));
						Produce::inv_primitive(Emit::tree(), PLUS_BIP);
						Produce::down(Emit::tree());
							Produce::val_symbol(Emit::tree(), K_value, gprk->w_s);
							Produce::inv_call_iname(Emit::tree(), Hierarchy::find(TRYGIVENOBJECT_HL));
							Produce::down(Emit::tree());
								Produce::val_symbol(Emit::tree(), K_value, gprk->rv_s);
								Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1);
							Produce::up(Emit::tree());
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
					Produce::inv_primitive(Emit::tree(), IF_BIP);
					Produce::down(Emit::tree());
						Produce::inv_primitive(Emit::tree(), GT_BIP);
						Produce::down(Emit::tree());
							Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(WN_HL));
							Produce::val_symbol(Emit::tree(), K_value, gprk->w_s);
						Produce::up(Emit::tree());
						Produce::code(Emit::tree());
						Produce::down(Emit::tree());
							Produce::inv_primitive(Emit::tree(), JUMP_BIP);
							Produce::down(Emit::tree());
								Produce::lab(Emit::tree(), exit_label);
							Produce::up(Emit::tree());
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Produce::down(Emit::tree());
				Produce::ref_symbol(Emit::tree(), K_value, gprk->rv_s);
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
			Produce::up(Emit::tree());
			@<Jump to our doom@>;
			Produce::place_label(Emit::tree(), exit_label);
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Produce::down(Emit::tree());
				Produce::ref_symbol(Emit::tree(), K_value, gprk->rv_s);
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
			Produce::up(Emit::tree());
		} else if (bp == R_incorporation) {
			TEMPORARY_TEXT(L)
			WRITE_TO(L, ".ol_mm_%d", ol_loop_counter++);
			inter_symbol *exit_label = Produce::reserve_label(Emit::tree(), L);
			DISCARD_TEXT(L)
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Produce::down(Emit::tree());
				Produce::ref_symbol(Emit::tree(), K_value, gprk->rv_s);
				Produce::inv_primitive(Emit::tree(), PROPERTYVALUE_BIP);
				Produce::down(Emit::tree());
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(SELF_HL));
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(COMPONENT_CHILD_HL));
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
			Produce::inv_primitive(Emit::tree(), WHILE_BIP);
			Produce::down(Emit::tree());
				Produce::val_symbol(Emit::tree(), K_value, gprk->rv_s);
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), STORE_BIP);
					Produce::down(Emit::tree());
						Produce::ref_iname(Emit::tree(), K_value, Hierarchy::find(WN_HL));
						Produce::val_symbol(Emit::tree(), K_value, gprk->w_s);
					Produce::up(Emit::tree());
					Produce::inv_primitive(Emit::tree(), STORE_BIP);
					Produce::down(Emit::tree());
						Produce::ref_iname(Emit::tree(), K_value, Hierarchy::find(WN_HL));
						Produce::inv_primitive(Emit::tree(), PLUS_BIP);
						Produce::down(Emit::tree());
							Produce::val_symbol(Emit::tree(), K_value, gprk->w_s);
							Produce::inv_call_iname(Emit::tree(), Hierarchy::find(TRYGIVENOBJECT_HL));
							Produce::down(Emit::tree());
								Produce::val_symbol(Emit::tree(), K_value, gprk->rv_s);
								Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1);
							Produce::up(Emit::tree());
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
					Produce::inv_primitive(Emit::tree(), IF_BIP);
					Produce::down(Emit::tree());
						Produce::inv_primitive(Emit::tree(), GT_BIP);
						Produce::down(Emit::tree());
							Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(WN_HL));
							Produce::val_symbol(Emit::tree(), K_value, gprk->w_s);
						Produce::up(Emit::tree());
						Produce::code(Emit::tree());
						Produce::down(Emit::tree());
							Produce::inv_primitive(Emit::tree(), JUMP_BIP);
							Produce::down(Emit::tree());
								Produce::lab(Emit::tree(), exit_label);
							Produce::up(Emit::tree());
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
					Produce::inv_primitive(Emit::tree(), STORE_BIP);
					Produce::down(Emit::tree());
						Produce::ref_symbol(Emit::tree(), K_value, gprk->rv_s);
						Produce::inv_primitive(Emit::tree(), PROPERTYVALUE_BIP);
						Produce::down(Emit::tree());
							Produce::val_symbol(Emit::tree(), K_value, gprk->rv_s);
							Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(COMPONENT_SIBLING_HL));
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Produce::down(Emit::tree());
				Produce::ref_symbol(Emit::tree(), K_value, gprk->rv_s);
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
			Produce::up(Emit::tree());
			@<Jump to our doom@>;
			Produce::place_label(Emit::tree(), exit_label);
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Produce::down(Emit::tree());
				Produce::ref_symbol(Emit::tree(), K_value, gprk->rv_s);
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
			Produce::up(Emit::tree());
		} else if (bp == R_equality) {
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, CGTokens::text(cgt));
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_RelatedByEquality));
			Problems::issue_problem_segment(
				"The grammar you give in %1 contains a token %2 which would "
				"create a circularity. To follow this, I'd have to compute "
				"forever.");
			Problems::issue_problem_end();
			return K_object;
		} else if ((BinaryPredicates::get_reversal(bp) == R_containment) ||
			(BinaryPredicates::get_reversal(bp) == R_support) ||
			(BinaryPredicates::get_reversal(bp) == a_has_b_predicate) ||
			(BinaryPredicates::get_reversal(bp) == R_wearing) ||
			(BinaryPredicates::get_reversal(bp) == R_carrying)) {
			if (BinaryPredicates::get_reversal(bp) == R_carrying) {
				Produce::inv_primitive(Emit::tree(), IF_BIP);
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), HAS_BIP);
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(SELF_HL));
						Produce::val_iname(Emit::tree(), K_value, RTProperties::iname(P_worn));
					Produce::up(Emit::tree());
					@<Then jump to our doom@>;
				Produce::up(Emit::tree());
			}
			if (BinaryPredicates::get_reversal(bp) == R_wearing) {
				Produce::inv_primitive(Emit::tree(), IF_BIP);
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), NOT_BIP);
					Produce::down(Emit::tree());
						Produce::inv_primitive(Emit::tree(), HAS_BIP);
						Produce::down(Emit::tree());
							Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(SELF_HL));
							Produce::val_iname(Emit::tree(), K_value, RTProperties::iname(P_worn));
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
					@<Then jump to our doom@>;
				Produce::up(Emit::tree());
			}
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Produce::down(Emit::tree());
				Produce::ref_symbol(Emit::tree(), K_value, gprk->rv_s);
				Produce::inv_call(Emit::tree(), Site::veneer_symbol(Emit::tree(), PARENT_VSYMB));
				Produce::down(Emit::tree());
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(SELF_HL));
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());

			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Produce::down(Emit::tree());
				Produce::ref_iname(Emit::tree(), K_value, Hierarchy::find(WN_HL));
				Produce::val_symbol(Emit::tree(), K_value, gprk->w_s);
			Produce::up(Emit::tree());
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Produce::down(Emit::tree());
				Produce::ref_iname(Emit::tree(), K_value, Hierarchy::find(WN_HL));
				Produce::inv_primitive(Emit::tree(), PLUS_BIP);
				Produce::down(Emit::tree());
					Produce::val_symbol(Emit::tree(), K_value, gprk->w_s);
					Produce::inv_call_iname(Emit::tree(), Hierarchy::find(TRYGIVENOBJECT_HL));
					Produce::down(Emit::tree());
						Produce::val_symbol(Emit::tree(), K_value, gprk->rv_s);
						Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1);
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
			Produce::inv_primitive(Emit::tree(), IF_BIP);
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), EQ_BIP);
				Produce::down(Emit::tree());
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(WN_HL));
					Produce::val_symbol(Emit::tree(), K_value, gprk->w_s);
				Produce::up(Emit::tree());
				@<Then jump to our doom@>;
			Produce::up(Emit::tree());
		} else if (BinaryPredicates::get_reversal(bp) == R_incorporation) {
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Produce::down(Emit::tree());
				Produce::ref_symbol(Emit::tree(), K_value, gprk->rv_s);
				Produce::inv_primitive(Emit::tree(), PROPERTYVALUE_BIP);
				Produce::down(Emit::tree());
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(SELF_HL));
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(COMPONENT_PARENT_HL));
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Produce::down(Emit::tree());
				Produce::ref_iname(Emit::tree(), K_value, Hierarchy::find(WN_HL));
				Produce::val_symbol(Emit::tree(), K_value, gprk->w_s);
			Produce::up(Emit::tree());
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Produce::down(Emit::tree());
				Produce::ref_iname(Emit::tree(), K_value, Hierarchy::find(WN_HL));
				Produce::inv_primitive(Emit::tree(), PLUS_BIP);
				Produce::down(Emit::tree());
					Produce::val_symbol(Emit::tree(), K_value, gprk->w_s);
					Produce::inv_call_iname(Emit::tree(), Hierarchy::find(TRYGIVENOBJECT_HL));
					Produce::down(Emit::tree());
						Produce::val_symbol(Emit::tree(), K_value, gprk->rv_s);
						Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1);
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
			Produce::inv_primitive(Emit::tree(), IF_BIP);
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), EQ_BIP);
				Produce::down(Emit::tree());
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(WN_HL));
					Produce::val_symbol(Emit::tree(), K_value, gprk->w_s);
				Produce::up(Emit::tree());
				@<Then jump to our doom@>;
			Produce::up(Emit::tree());
		} else {
			i6_schema *i6s;
			int reverse = FALSE;
			int continue_loop_on_fail = TRUE;

			i6s = BinaryPredicates::get_test_function(bp);
			LOGIF(GRAMMAR_CONSTRUCTION, "Read I6s $i from $2\n", i6s, bp);
			if ((i6s == NULL) && (BinaryPredicates::get_test_function(BinaryPredicates::get_reversal(bp)))) {
				reverse = TRUE;
				i6s = BinaryPredicates::get_test_function(BinaryPredicates::get_reversal(bp));
				LOGIF(GRAMMAR_CONSTRUCTION, "But read I6s $i from reversal\n", i6s);
			}

			if (i6s) {
				kind *K = BinaryPredicates::term_kind(bp, 1);
				if (Kinds::Behaviour::is_subkind_of_object(K)) {
					LOGIF(GRAMMAR_CONSTRUCTION, "Term 1 of BP is %u\n", K);
					Produce::inv_primitive(Emit::tree(), OBJECTLOOPX_BIP);
					Produce::down(Emit::tree());
						Produce::ref_symbol(Emit::tree(), K_value, gprk->rv_s);
						Produce::val_iname(Emit::tree(), K_value, RTKinds::I6_classname(K));
						Produce::code(Emit::tree());
						Produce::down(Emit::tree());
							Produce::inv_primitive(Emit::tree(), IF_BIP);
							Produce::down(Emit::tree());
								Produce::inv_primitive(Emit::tree(), EQ_BIP);
								Produce::down(Emit::tree());
									pcalc_term rv_term = Terms::new_constant(
										Lvalues::new_LOCAL_VARIABLE(EMPTY_WORDING, gprk->rv_lv));
									pcalc_term self_term = Terms::new_constant(
										Rvalues::new_self_object_constant());
									if (reverse)
										EmitSchemas::emit_val_expand_from_terms(i6s, &rv_term, &self_term);
									else
										EmitSchemas::emit_val_expand_from_terms(i6s, &self_term, &rv_term);
					continue_loop_on_fail = TRUE;
				} else {
					Problems::quote_source(1, current_sentence);
					Problems::quote_wording(2, CGTokens::text(cgt));
					StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_GrammarValueRelation));
					Problems::issue_problem_segment(
						"The grammar you give in %1 contains a token "
						"which relates things to values - %2. At present, "
						"this is not allowed: only relations between kinds "
						"of object can be used in 'Understand' tokens.");
					Problems::issue_problem_end();
					return K_object;
				}
			} else {
				property *prn = Relations::Explicit::get_i6_storage_property(bp);
				reverse = FALSE;
				if (BinaryPredicates::is_the_wrong_way_round(bp)) reverse = TRUE;
				if (Relations::Explicit::get_form_of_relation(bp) == Relation_VtoO) {
					if (reverse) reverse = FALSE; else reverse = TRUE;
				}
				if (prn) {
					if (reverse) {
						Produce::inv_primitive(Emit::tree(), IF_BIP);
						Produce::down(Emit::tree());
							Produce::inv_primitive(Emit::tree(), PROVIDES_BIP);
							Produce::down(Emit::tree());
								Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(SELF_HL));
								Produce::val_iname(Emit::tree(), K_value, RTProperties::iname(prn));
							Produce::up(Emit::tree());
							Produce::code(Emit::tree());
							Produce::down(Emit::tree());

								Produce::inv_primitive(Emit::tree(), STORE_BIP);
								Produce::down(Emit::tree());
									Produce::ref_symbol(Emit::tree(), K_value, gprk->rv_s);
									Produce::inv_primitive(Emit::tree(), PROPERTYVALUE_BIP);
									Produce::down(Emit::tree());
										Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(SELF_HL));
										Produce::val_iname(Emit::tree(), K_value, RTProperties::iname(prn));
									Produce::up(Emit::tree());
								Produce::up(Emit::tree());
								Produce::inv_primitive(Emit::tree(), IF_BIP);
								Produce::down(Emit::tree());
									Produce::inv_primitive(Emit::tree(), EQ_BIP);
									Produce::down(Emit::tree());
										Produce::val_symbol(Emit::tree(), K_value, gprk->rv_s);

						continue_loop_on_fail = FALSE;
					} else {
						kind *K = BinaryPredicates::term_kind(bp, 1);
						if (Kinds::Behaviour::is_object(K) == FALSE) {
							Problems::quote_source(1, current_sentence);
							Problems::quote_wording(2, CGTokens::text(cgt));
							Problems::quote_kind(3, K);
							StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_GrammarValueRelation2));
							Problems::issue_problem_segment(
								"The grammar you give in %1 contains a token "
								"which relates things to values - %2. (It would "
								"need to match the name of %3, which isn't a kind "
								"of thing.) At present, this is not allowed: only "
								"relations between kinds of object can be used in "
								"'Understand' tokens.");
							Problems::issue_problem_end();
							return K_object;
						}
						Produce::inv_primitive(Emit::tree(), OBJECTLOOPX_BIP);
						Produce::down(Emit::tree());
							Produce::ref_symbol(Emit::tree(), K_value, gprk->rv_s);
							Produce::val_iname(Emit::tree(), K_value, RTKinds::I6_classname(K));
							Produce::code(Emit::tree());
							Produce::down(Emit::tree());
								Produce::inv_primitive(Emit::tree(), IF_BIP);
								Produce::down(Emit::tree());
									Produce::inv_primitive(Emit::tree(), EQ_BIP);
									Produce::down(Emit::tree());
										Produce::inv_primitive(Emit::tree(), AND_BIP);
										Produce::down(Emit::tree());
											Produce::inv_primitive(Emit::tree(), PROVIDES_BIP);
											Produce::down(Emit::tree());
												Produce::val_symbol(Emit::tree(), K_value, gprk->rv_s);
												Produce::val_iname(Emit::tree(), K_value, RTProperties::iname(prn));
											Produce::up(Emit::tree());
											Produce::inv_primitive(Emit::tree(), EQ_BIP);
											Produce::down(Emit::tree());
												Produce::inv_primitive(Emit::tree(), PROPERTYVALUE_BIP);
												Produce::down(Emit::tree());
													Produce::val_symbol(Emit::tree(), K_value, gprk->rv_s);
													Produce::val_iname(Emit::tree(), K_value, RTProperties::iname(prn));
												Produce::up(Emit::tree());
												Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(SELF_HL));
											Produce::up(Emit::tree());
										Produce::up(Emit::tree());
						continue_loop_on_fail = TRUE;
					}
				} else {
					LOG("Trouble with: $2\n", bp);
					LOG("Whose reversal is: $2\n", BinaryPredicates::get_reversal(bp));
					Problems::quote_source(1, current_sentence);
					Problems::quote_wording(2, CGTokens::text(cgt));
					StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_GrammarTokenCowardice));
					Problems::issue_problem_segment(
						"The grammar you give in %1 contains a token "
						"which uses a relation I'm unable to test - %2.");
					Problems::issue_problem_end();
					return K_object;
				}
			}

								Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 0);
							Produce::up(Emit::tree());
							Produce::code(Emit::tree());
							Produce::down(Emit::tree());
								if (continue_loop_on_fail == FALSE) {
									@<Jump to our doom@>;
								} else {
									Produce::inv_primitive(Emit::tree(), CONTINUE_BIP);
								}
							Produce::up(Emit::tree());
						Produce::up(Emit::tree());

						Produce::inv_primitive(Emit::tree(), STORE_BIP);
						Produce::down(Emit::tree());
							Produce::ref_iname(Emit::tree(), K_value, Hierarchy::find(WN_HL));
							Produce::val_symbol(Emit::tree(), K_value, gprk->w_s);
						Produce::up(Emit::tree());
						Produce::inv_primitive(Emit::tree(), STORE_BIP);
						Produce::down(Emit::tree());
							Produce::ref_iname(Emit::tree(), K_value, Hierarchy::find(WN_HL));
							Produce::inv_primitive(Emit::tree(), PLUS_BIP);
							Produce::down(Emit::tree());
								Produce::val_symbol(Emit::tree(), K_value, gprk->w_s);
								Produce::inv_call_iname(Emit::tree(), Hierarchy::find(TRYGIVENOBJECT_HL));
								Produce::down(Emit::tree());
									Produce::val_symbol(Emit::tree(), K_value, gprk->rv_s);
									Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1);
								Produce::up(Emit::tree());
							Produce::up(Emit::tree());
						Produce::up(Emit::tree());

						TEMPORARY_TEXT(L)
						WRITE_TO(L, ".ol_mm_%d", ol_loop_counter++);
						inter_symbol *exit_label = Produce::reserve_label(Emit::tree(), L);
						DISCARD_TEXT(L)

						Produce::inv_primitive(Emit::tree(), IF_BIP);
						Produce::down(Emit::tree());
							Produce::inv_primitive(Emit::tree(), GT_BIP);
							Produce::down(Emit::tree());
								Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(WN_HL));
								Produce::val_symbol(Emit::tree(), K_value, gprk->w_s);
							Produce::up(Emit::tree());
							Produce::code(Emit::tree());
							Produce::down(Emit::tree());
								Produce::inv_primitive(Emit::tree(), JUMP_BIP);
								Produce::down(Emit::tree());
									Produce::lab(Emit::tree(), exit_label);
								Produce::up(Emit::tree());
							Produce::up(Emit::tree());
						Produce::up(Emit::tree());

					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
				Produce::inv_primitive(Emit::tree(), STORE_BIP);
				Produce::down(Emit::tree());
					Produce::ref_symbol(Emit::tree(), K_value, gprk->rv_s);
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
				Produce::up(Emit::tree());
				@<Jump to our doom@>;
				Produce::place_label(Emit::tree(), exit_label);
				Produce::inv_primitive(Emit::tree(), STORE_BIP);
				Produce::down(Emit::tree());
					Produce::ref_symbol(Emit::tree(), K_value, gprk->rv_s);
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
				Produce::up(Emit::tree());
			}
			return NULL;
		}

	spec = cgt->what_token_describes;
	if (cgt->defined_by) spec = ParsingPlugin::rvalue_from_command_grammar(cgt->defined_by);

	if (Specifications::is_kind_like(spec)) {
		kind *K = Node::get_kind_of_value(spec);
		if ((K_understanding) &&
			(Kinds::Behaviour::is_object(K) == FALSE) &&
			(Kinds::eq(K, K_understanding) == FALSE)) {
			if (Kinds::Behaviour::offers_I6_GPR(K)) {
				text_stream *i6_gpr_name = Kinds::Behaviour::get_explicit_I6_GPR(K);
				if (code_mode) {
					Produce::inv_primitive(Emit::tree(), STORE_BIP);
					Produce::down(Emit::tree());
						Produce::ref_symbol(Emit::tree(), K_value, gprk->w_s);
						Produce::inv_call_iname(Emit::tree(), Hierarchy::find(PARSETOKENSTOPPED_HL));
						Produce::down(Emit::tree());
							Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(GPR_TT_HL));
							if (Str::len(i6_gpr_name) > 0)
								Produce::val_iname(Emit::tree(), K_value, Produce::find_by_name(Emit::tree(), i6_gpr_name));
							else
								Produce::val_iname(Emit::tree(), K_value, RTKinds::get_kind_GPR_iname(K));
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
					Produce::inv_primitive(Emit::tree(), IF_BIP);
					Produce::down(Emit::tree());
						Produce::inv_primitive(Emit::tree(), NE_BIP);
						Produce::down(Emit::tree());
							Produce::val_symbol(Emit::tree(), K_value, gprk->w_s);
							Produce::val_iname(Emit::tree(), K_number, Hierarchy::find(GPR_NUMBER_HL));
						Produce::up(Emit::tree());
						@<Then jump to our doom@>;
					Produce::up(Emit::tree());
					Produce::inv_primitive(Emit::tree(), STORE_BIP);
					Produce::down(Emit::tree());
						Produce::ref_symbol(Emit::tree(), K_value, gprk->rv_s);
						Produce::val_iname(Emit::tree(), K_number, Hierarchy::find(GPR_NUMBER_HL));
					Produce::up(Emit::tree());
				} else {
					if (Str::len(i6_gpr_name) > 0)
						Emit::array_iname_entry(Produce::find_by_name(Emit::tree(), i6_gpr_name));
					else
						Emit::array_iname_entry(RTKinds::get_kind_GPR_iname(K));
				}
				return K;
			}
			/* internal_error("Let an invalid type token through"); */
		}
	}

	if (Descriptions::is_complex(spec)) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, CGTokens::text(cgt));
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_OverComplexToken));
		Problems::issue_problem_segment(
			"The grammar you give in %1 contains a token "
			"which is just too complicated - %2. %PFor instance, a "
			"token using subordinate clauses - such as '[a person who "
			"can see the player]' will probably not be allowed.");
		Problems::issue_problem_end();
		return K_object;
	} else {
		kind *K = NULL;
		if (CGTokens::is_I6_parser_token(cgt)) {
			inter_name *i6_token_iname = RTCommandGrammars::iname_for_I6_parser_token(cgt);
			K = Descriptions::explicit_kind(cgt->what_token_describes);
			if (code_mode) {
				if ((consult_mode) && (CGTokens::is_topic(cgt))) {
					StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TextTokenRestricted),
						"the '[text]' token is not allowed with 'matches' "
						"or in table columns",
						"as it is just too complicated to sort out: a "
						"'[text]' is supposed to extract a snippet from "
						"the player's command, but here we already have "
						"a snippet, and don't want to snip it further.");
				}
				Produce::inv_primitive(Emit::tree(), STORE_BIP);
				Produce::down(Emit::tree());
					Produce::ref_symbol(Emit::tree(), K_value, gprk->w_s);
					Produce::inv_call_iname(Emit::tree(), Hierarchy::find(PARSETOKENSTOPPED_HL));
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(ELEMENTARY_TT_HL));
						Produce::val_iname(Emit::tree(), K_value, i6_token_iname);
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
				Produce::inv_primitive(Emit::tree(), IF_BIP);
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), EQ_BIP);
					Produce::down(Emit::tree());
						Produce::val_symbol(Emit::tree(), K_value, gprk->w_s);
						Produce::val_iname(Emit::tree(), K_number, Hierarchy::find(GPR_FAIL_HL));
					Produce::up(Emit::tree());
					@<Then jump to our doom@>;
				Produce::up(Emit::tree());
				Produce::inv_primitive(Emit::tree(), STORE_BIP);
				Produce::down(Emit::tree());
					Produce::ref_symbol(Emit::tree(), K_value, gprk->rv_s);
					Produce::val_symbol(Emit::tree(), K_value, gprk->w_s);
				Produce::up(Emit::tree());
			} else {
				Emit::array_iname_entry(i6_token_iname);
			}
		} else {
			if (Specifications::is_description(spec)) {
				K = Specifications::to_kind(spec);
				if (Descriptions::is_qualified(spec)) {
 					if (code_mode) {
		 				Produce::inv_primitive(Emit::tree(), STORE_BIP);
						Produce::down(Emit::tree());
							Produce::ref_symbol(Emit::tree(), K_value, gprk->w_s);
							Produce::inv_call_iname(Emit::tree(), Hierarchy::find(PARSETOKENSTOPPED_HL));
							Produce::down(Emit::tree());
								UnderstandFilterTokens::compile_id(cgt->noun_filter);
							Produce::up(Emit::tree());
						Produce::up(Emit::tree());
						Produce::inv_primitive(Emit::tree(), IF_BIP);
						Produce::down(Emit::tree());
							Produce::inv_primitive(Emit::tree(), EQ_BIP);
							Produce::down(Emit::tree());
								Produce::val_symbol(Emit::tree(), K_value, gprk->w_s);
								Produce::val_iname(Emit::tree(), K_number, Hierarchy::find(GPR_FAIL_HL));
							Produce::up(Emit::tree());
							@<Then jump to our doom@>;
						Produce::up(Emit::tree());
						Produce::inv_primitive(Emit::tree(), STORE_BIP);
						Produce::down(Emit::tree());
							Produce::ref_symbol(Emit::tree(), K_value, gprk->rv_s);
							Produce::val_symbol(Emit::tree(), K_value, gprk->w_s);
						Produce::up(Emit::tree());
					} else {
						UnderstandFilterTokens::emit_id(cgt->noun_filter);
					}
				} else {
					if (Kinds::Behaviour::offers_I6_GPR(K)) {
						text_stream *i6_gpr_name = Kinds::Behaviour::get_explicit_I6_GPR(K);
						if (code_mode) {
							Produce::inv_primitive(Emit::tree(), STORE_BIP);
							Produce::down(Emit::tree());
								Produce::ref_symbol(Emit::tree(), K_value, gprk->w_s);
								Produce::inv_call_iname(Emit::tree(), Hierarchy::find(PARSETOKENSTOPPED_HL));
								Produce::down(Emit::tree());
									Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(GPR_TT_HL));
									if (Str::len(i6_gpr_name) > 0)
										Produce::val_iname(Emit::tree(), K_value, Produce::find_by_name(Emit::tree(), i6_gpr_name));
									else
										Produce::val_iname(Emit::tree(), K_value, RTKinds::get_kind_GPR_iname(K));
								Produce::up(Emit::tree());
							Produce::up(Emit::tree());
							Produce::inv_primitive(Emit::tree(), IF_BIP);
							Produce::down(Emit::tree());
								Produce::inv_primitive(Emit::tree(), NE_BIP);
								Produce::down(Emit::tree());
									Produce::val_symbol(Emit::tree(), K_value, gprk->w_s);
									Produce::val_iname(Emit::tree(), K_number, Hierarchy::find(GPR_NUMBER_HL));
								Produce::up(Emit::tree());
								@<Then jump to our doom@>;
							Produce::up(Emit::tree());
							Produce::inv_primitive(Emit::tree(), STORE_BIP);
							Produce::down(Emit::tree());
								Produce::ref_symbol(Emit::tree(), K_value, gprk->rv_s);
								Produce::val_iname(Emit::tree(), K_number, Hierarchy::find(GPR_NUMBER_HL));
							Produce::up(Emit::tree());
						} else {
							if (Str::len(i6_gpr_name) > 0)
								Emit::array_iname_entry(Produce::find_by_name(Emit::tree(), i6_gpr_name));
							else
								Emit::array_iname_entry(RTKinds::get_kind_GPR_iname(K));
						}
					} else if (Kinds::Behaviour::is_object(K)) {
						if (code_mode) {
							Produce::inv_primitive(Emit::tree(), STORE_BIP);
							Produce::down(Emit::tree());
								Produce::ref_symbol(Emit::tree(), K_value, gprk->w_s);
								Produce::inv_call_iname(Emit::tree(), Hierarchy::find(PARSETOKENSTOPPED_HL));
								Produce::down(Emit::tree());
									UnderstandFilterTokens::compile_id(cgt->noun_filter);
								Produce::up(Emit::tree());
							Produce::up(Emit::tree());
							Produce::inv_primitive(Emit::tree(), IF_BIP);
							Produce::down(Emit::tree());
								Produce::inv_primitive(Emit::tree(), EQ_BIP);
								Produce::down(Emit::tree());
									Produce::val_symbol(Emit::tree(), K_value, gprk->w_s);
									Produce::val_iname(Emit::tree(), K_number, Hierarchy::find(GPR_FAIL_HL));
								Produce::up(Emit::tree());
								@<Then jump to our doom@>;
							Produce::up(Emit::tree());
							Produce::inv_primitive(Emit::tree(), STORE_BIP);
							Produce::down(Emit::tree());
								Produce::ref_symbol(Emit::tree(), K_value, gprk->rv_s);
								Produce::val_symbol(Emit::tree(), K_value, gprk->w_s);
							Produce::up(Emit::tree());
						} else {
							UnderstandFilterTokens::emit_id(cgt->noun_filter);
						}
						K = K_object;
					} else internal_error("no token for description");
				}
			} else {
					if (cgt->defined_by) {
						cg = cgt->defined_by;
						if (code_mode) {
							Produce::inv_primitive(Emit::tree(), STORE_BIP);
							Produce::down(Emit::tree());
								Produce::ref_symbol(Emit::tree(), K_value, gprk->w_s);
								Produce::inv_call_iname(Emit::tree(), Hierarchy::find(PARSETOKENSTOPPED_HL));
								Produce::down(Emit::tree());
									Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(GPR_TT_HL));
									Produce::val_iname(Emit::tree(), K_value, RTCommandGrammars::i6_token_as_iname(cg));
								Produce::up(Emit::tree());
							Produce::up(Emit::tree());
							Produce::inv_primitive(Emit::tree(), IF_BIP);
							Produce::down(Emit::tree());
								Produce::inv_primitive(Emit::tree(), EQ_BIP);
								Produce::down(Emit::tree());
									Produce::val_symbol(Emit::tree(), K_value, gprk->w_s);
									Produce::val_iname(Emit::tree(), K_number, Hierarchy::find(GPR_FAIL_HL));
								Produce::up(Emit::tree());
								@<Then jump to our doom@>;
							Produce::up(Emit::tree());

							Produce::inv_primitive(Emit::tree(), IF_BIP);
							Produce::down(Emit::tree());
								Produce::inv_primitive(Emit::tree(), NE_BIP);
								Produce::down(Emit::tree());
									Produce::val_symbol(Emit::tree(), K_value, gprk->w_s);
									Produce::val_iname(Emit::tree(), K_number, Hierarchy::find(GPR_PREPOSITION_HL));
								Produce::up(Emit::tree());
								Produce::code(Emit::tree());
								Produce::down(Emit::tree());
									Produce::inv_primitive(Emit::tree(), STORE_BIP);
									Produce::down(Emit::tree());
										Produce::ref_symbol(Emit::tree(), K_value, gprk->rv_s);
										Produce::val_symbol(Emit::tree(), K_value, gprk->w_s);
									Produce::up(Emit::tree());
								Produce::up(Emit::tree());
							Produce::up(Emit::tree());
						} else {
							Emit::array_iname_entry(RTCommandGrammars::i6_token_as_iname(cg));
						}
						K = CommandGrammars::get_kind_matched(cg);
					} else
				if (Node::is(spec, CONSTANT_NT)) {
					if (Rvalues::is_object(spec)) {
						if (code_mode) {
							Produce::inv_primitive(Emit::tree(), STORE_BIP);
							Produce::down(Emit::tree());
								Produce::ref_symbol(Emit::tree(), K_value, gprk->w_s);
								Produce::inv_call_iname(Emit::tree(), Hierarchy::find(PARSETOKENSTOPPED_HL));
								Produce::down(Emit::tree());
									UnderstandFilterTokens::compile_id(cgt->noun_filter);
								Produce::up(Emit::tree());
							Produce::up(Emit::tree());
							Produce::inv_primitive(Emit::tree(), IF_BIP);
							Produce::down(Emit::tree());
								Produce::inv_primitive(Emit::tree(), EQ_BIP);
								Produce::down(Emit::tree());
									Produce::val_symbol(Emit::tree(), K_value, gprk->w_s);
									Produce::val_iname(Emit::tree(), K_number, Hierarchy::find(GPR_FAIL_HL));
								Produce::up(Emit::tree());
								@<Then jump to our doom@>;
							Produce::up(Emit::tree());
							Produce::inv_primitive(Emit::tree(), STORE_BIP);
							Produce::down(Emit::tree());
								Produce::ref_symbol(Emit::tree(), K_value, gprk->rv_s);
								Produce::val_symbol(Emit::tree(), K_value, gprk->w_s);
							Produce::up(Emit::tree());
						} else {
							UnderstandFilterTokens::emit_id(cgt->noun_filter);
						}
						K = K_object;
					}
				} else K = K_object;
			}
		}
		return K;
	}
}

@<Then jump to our doom@> =
	Produce::code(Emit::tree());
	Produce::down(Emit::tree());
		@<Jump to our doom@>;
	Produce::up(Emit::tree());

@<Jump to our doom@> =
	Produce::inv_primitive(Emit::tree(), JUMP_BIP);
	Produce::down(Emit::tree());
		Produce::lab(Emit::tree(), failure_label);
	Produce::up(Emit::tree());
