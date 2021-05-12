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

		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(NE_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_object, Hierarchy::find(ACTOR_HL));
				EmitCode::val_iname(K_object, Hierarchy::find(PLAYER_HL));
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
				EmitCode::inv(RETURN_BIP);
				EmitCode::down();
					EmitCode::val_iname(K_value, Hierarchy::find(GPR_FAIL_HL));
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();

		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_iname(K_number, Hierarchy::find(UNDERSTAND_AS_MISTAKE_NUMBER_HL));
			EmitCode::val_number((inter_ti) (100 + cgl->allocation_id));
		EmitCode::up();

		EmitCode::inv(RETURN_BIP);
		EmitCode::down();
			EmitCode::val_iname(K_value, Hierarchy::find(GPR_PREPOSITION_HL));
		EmitCode::up();

		Functions::end(save);
	}
}

void RTCommandGrammarLines::cgl_compile_extra_token_for_mistake(cg_line *cgl, int cg_is) {
	if (cgl->mistaken) {
		if (cg_is == CG_IS_COMMAND) {
			EmitArrays::iname_entry(cgl->compilation_data.mistake_iname);
		} else
			internal_error("CGLs may only be mistaken in command grammar");
	}
}

inter_name *MistakeAction_iname = NULL;

int RTCommandGrammarLines::cgl_compile_result_of_mistake(gpr_kit *gprk, cg_line *cgl) {
	if (cgl->mistaken) {
		if (MistakeAction_iname == NULL) internal_error("no MistakeAction yet");
		EmitArrays::iname_entry(VERB_DIRECTIVE_RESULT_iname);
		EmitArrays::iname_entry(MistakeAction_iname);
		return TRUE;
	}
	return FALSE;
}

void RTCommandGrammarLines::MistakeActionSub_routine(void) {
	inter_name *iname = Hierarchy::find(MISTAKEACTIONSUB_HL);
	packaging_state save = Functions::begin(iname);

	EmitCode::inv(SWITCH_BIP);
	EmitCode::down();
		EmitCode::val_iname(K_value, Hierarchy::find(UNDERSTAND_AS_MISTAKE_NUMBER_HL));
		EmitCode::code();
		EmitCode::down();
			cg_line *cgl;
			LOOP_OVER(cgl, cg_line)
				if (cgl->mistaken) {
					current_sentence = cgl->where_grammar_specified;
					parse_node *spec = NULL;
					if (Wordings::empty(cgl->mistake_response_text))
						spec = Specifications::new_UNKNOWN(cgl->mistake_response_text);
					else if (<s-value>(cgl->mistake_response_text)) spec = <<rp>>;
					else spec = Specifications::new_UNKNOWN(cgl->mistake_response_text);
					EmitCode::inv(CASE_BIP);
					EmitCode::down();
						EmitCode::val_number((inter_ti) (100+cgl->allocation_id));
						EmitCode::code();
						EmitCode::down();
							EmitCode::call(Hierarchy::find(PARSERERROR_HL));
							EmitCode::down();
								CompileValues::to_code_val_of_kind(spec, K_text);
							EmitCode::up();
						EmitCode::up();
					EmitCode::up();
				}

			EmitCode::inv(DEFAULT_BIP);
			EmitCode::down();
				EmitCode::code();
				EmitCode::down();
					EmitCode::inv(PRINT_BIP);
					EmitCode::down();
						EmitCode::val_text(I"I didn't understand that sentence.\n");
					EmitCode::up();
					EmitCode::rtrue();
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();

	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_iname(K_number, Hierarchy::find(SAY__P_HL));
		EmitCode::val_number(1);
	EmitCode::up();

	Functions::end(save);
	
	MistakeAction_iname = Hierarchy::find(MISTAKEACTION_HL);
	Emit::unchecked_numeric_constant(MistakeAction_iname, 10000);
	Produce::annotate_i(MistakeAction_iname, ACTION_IANN, 1);
	Hierarchy::make_available(MistakeAction_iname);
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
			EmitCode::inv(IF_BIP);
			EmitCode::down();
				if ((spec) && (prop)) {
					EmitCode::inv(AND_BIP);
					EmitCode::down();
				}
				if (spec) CompileValues::to_code_val_of_kind(spec, K_truth_state);
				if (prop) CompilePropositions::to_test_as_condition(Rvalues::new_self_object_constant(), prop);
				if ((spec) && (prop)) {
					EmitCode::up();
				}
				EmitCode::code();
				EmitCode::down();
					EmitCode::inv(RETURN_BIP);
					EmitCode::down();
						EmitCode::val_iname(K_value, Hierarchy::find(GPR_PREPOSITION_HL));
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
		}
		EmitCode::inv(RETURN_BIP);
		EmitCode::down();
			EmitCode::val_iname(K_value, Hierarchy::find(GPR_FAIL_HL));
		EmitCode::up();

		Functions::end(save);
	}
}

void RTCommandGrammarLines::cgl_compile_extra_token_for_condition(gpr_kit *gprk, cg_line *cgl,
	int cg_is, inter_symbol *current_label) {
	if (CGLines::conditional(cgl)) {
		if (cgl->compilation_data.cond_token_iname == NULL) internal_error("CGL cond token not ready");
		if (cg_is == CG_IS_COMMAND) {
			EmitArrays::iname_entry(cgl->compilation_data.cond_token_iname);
		} else {
			EmitCode::inv(IF_BIP);
			EmitCode::down();
				EmitCode::inv(EQ_BIP);
				EmitCode::down();
					EmitCode::call(cgl->compilation_data.cond_token_iname);
					EmitCode::val_iname(K_value, Hierarchy::find(GPR_FAIL_HL));
				EmitCode::up();
				EmitCode::code();
				EmitCode::down();
					EmitCode::inv(JUMP_BIP);
					EmitCode::down();
						EmitCode::lab(current_label);
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
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

	if (code_mode == FALSE) EmitArrays::iname_entry(VERB_DIRECTIVE_DIVIDER_iname);

	inter_symbol *fail_label = NULL;

	if (gprk) {
		TEMPORARY_TEXT(L)
		WRITE_TO(L, ".Fail_%d", current_label);
		fail_label = EmitCode::reserve_label(L);
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
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, gprk->instance_s);
				RTCommandGrammars::emit_determination_type(&(cgl->cgl_type));
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
	}

	cg_token *cgt_from = cgt, *cgt_to = cgt_from;
	for (; cgt; cgt = cgt->next_token) cgt_to = cgt;
	RTCommandGrammarLines::compile_token_line(gprk, code_mode, cgt_from, cgt_to, cg_is, consult_mode, &token_values, token_value_kinds, NULL, fail_label);

	switch (cg_is) {
		case CG_IS_COMMAND:
			if (RTCommandGrammarLines::cgl_compile_result_of_mistake(gprk, cgl)) break;
			EmitArrays::iname_entry(VERB_DIRECTIVE_RESULT_iname);
			EmitArrays::iname_entry(RTActions::double_sharp(cgl->resulting_action));

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
				EmitArrays::iname_entry(VERB_DIRECTIVE_REVERSE_iname);
			}

			ActionSemantics::check_valid_application(cgl->resulting_action, token_values,
				token_value_kinds);
			break;
		case CG_IS_PROPERTY_NAME:
		case CG_IS_TOKEN:
			EmitCode::inv(RETURN_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, gprk->rv_s);
			EmitCode::up();
			EmitCode::place_label(fail_label);
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, gprk->rv_s);
				EmitCode::val_iname(K_value, Hierarchy::find(GPR_PREPOSITION_HL));
			EmitCode::up();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
				EmitCode::val_symbol(K_value, gprk->original_wn_s);
			EmitCode::up();
			break;
		case CG_IS_CONSULT:
			EmitCode::inv(IF_BIP);
			EmitCode::down();
				EmitCode::inv(OR_BIP);
				EmitCode::down();
					EmitCode::inv(EQ_BIP);
					EmitCode::down();
						EmitCode::val_symbol(K_value, gprk->range_words_s);
						EmitCode::val_number(0);
					EmitCode::up();
					EmitCode::inv(EQ_BIP);
					EmitCode::down();
						EmitCode::inv(MINUS_BIP);
						EmitCode::down();
							EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
							EmitCode::val_symbol(K_value, gprk->range_from_s);
						EmitCode::up();
						EmitCode::val_symbol(K_value, gprk->range_words_s);
					EmitCode::up();
				EmitCode::up();
				EmitCode::code();
				EmitCode::down();
					EmitCode::inv(RETURN_BIP);
					EmitCode::down();
						EmitCode::val_symbol(K_value, gprk->rv_s);
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();

			EmitCode::place_label(fail_label);
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, gprk->rv_s);
				EmitCode::val_iname(K_value, Hierarchy::find(GPR_PREPOSITION_HL));
			EmitCode::up();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
				EmitCode::val_symbol(K_value, gprk->original_wn_s);
			EmitCode::up();
			break;
		case CG_IS_SUBJECT:
			UnderstandGeneralTokens::after_gl_failed(gprk, fail_label, cgl->pluralised);
			break;
		case CG_IS_VALUE:
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_iname(K_value, Hierarchy::find(PARSED_NUMBER_HL));
				RTCommandGrammars::emit_determination_type(&(cgl->cgl_type));
			EmitCode::up();
			EmitCode::inv(RETURN_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_object, Hierarchy::find(GPR_NUMBER_HL));
			EmitCode::up();
			EmitCode::place_label(fail_label);
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
				EmitCode::val_symbol(K_value, gprk->original_wn_s);
			EmitCode::up();
			break;
	}

	if ((cg_is == CG_IS_VALUE) && (GV_IS_VALUE_instance_mode)) {
			EmitCode::up();
		EmitCode::up();
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
					EmitCode::inv(STORE_BIP);
					EmitCode::down();
						EmitCode::ref_symbol(K_value, gprk->group_wn_s);
						EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
					EmitCode::up();
				}
				if (next_reserved_label) EmitCode::place_label(next_reserved_label);
				TEMPORARY_TEXT(L)
				WRITE_TO(L, ".group_%d_%d_%d", current_grammar_block, lexeme_equivalence_class, alternative_number+1);
				next_reserved_label = EmitCode::reserve_label(L);
				DISCARD_TEXT(L)

				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
					EmitCode::val_symbol(K_value, gprk->group_wn_s);
				EmitCode::up();

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
			EmitArrays::iname_entry(sgpr->sgpr_iname);
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
							EmitCode::place_label(next_reserved_label);
						next_reserved_label = NULL;
						EmitCode::inv(STORE_BIP);
						EmitCode::down();
							EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
							EmitCode::val_symbol(K_value, gprk->group_wn_s);
						EmitCode::up();
					}
					if (eog_reserved_label) EmitCode::place_label(eog_reserved_label);
					eog_reserved_label = NULL;
				} else {
					@<Jump to end of group@>;
				}
			} else {
				if (last_token_in_lexeme == FALSE) EmitArrays::iname_entry(VERB_DIRECTIVE_SLASH_iname);
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
		eog_reserved_label = EmitCode::reserve_label(L);
	}
	EmitCode::inv(JUMP_BIP);
	EmitCode::down();
		EmitCode::lab(eog_reserved_label);
	EmitCode::up();

@ =
void RTCommandGrammarLines::compile_slash_gprs(void) {
	slash_gpr *sgpr;
	LOOP_OVER(sgpr, slash_gpr) {
		packaging_state save = Functions::begin(sgpr->sgpr_iname);
		gpr_kit gprk = UnderstandValueTokens::new_kit();
		UnderstandValueTokens::add_original(&gprk);
		UnderstandValueTokens::add_standard_set(&gprk);

		RTCommandGrammarLines::compile_token_line(&gprk, TRUE, sgpr->first_choice, sgpr->last_choice, CG_IS_TOKEN, FALSE, NULL, NULL, gprk.group_wn_s, NULL);
		EmitCode::inv(RETURN_BIP);
		EmitCode::down();
			EmitCode::val_iname(K_value, Hierarchy::find(GPR_PREPOSITION_HL));
		EmitCode::up();
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
			EmitArrays::dword_entry(content);
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
			EmitCode::inv(IF_BIP);
			EmitCode::down();
				EmitCode::inv(NE_BIP);
				EmitCode::down();
					EmitCode::call(Hierarchy::find(NEXTWORDSTOPPED_HL));
					TEMPORARY_TEXT(N)
					WRITE_TO(N, "%N", wn);
					EmitCode::val_dword(N);
					DISCARD_TEXT(N)
				EmitCode::up();
				@<Then jump to our doom@>;
			EmitCode::up();
		} else {
			TEMPORARY_TEXT(WT)
			WRITE_TO(WT, "%N", wn);
			EmitArrays::dword_entry(WT);
			DISCARD_TEXT(WT)
		}
		return NULL;
	}

	bp = cgt->token_relation;
	if (bp) {
		EmitCode::call(Hierarchy::find(ARTICLEDESCRIPTORS_HL));
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, gprk->w_s);
			EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
		EmitCode::up();
		if (bp == R_containment) {
			EmitCode::inv(IF_BIP);
			EmitCode::down();
				EmitCode::inv(NOT_BIP);
				EmitCode::down();
					EmitCode::inv(HAS_BIP);
					EmitCode::down();
						EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
						EmitCode::val_iname(K_value, Hierarchy::find(CONTAINER_HL));
					EmitCode::up();
				EmitCode::up();
				@<Then jump to our doom@>;
			EmitCode::up();
		}
		if (bp == R_support) {
			EmitCode::inv(IF_BIP);
			EmitCode::down();
				EmitCode::inv(NOT_BIP);
				EmitCode::down();
					EmitCode::inv(HAS_BIP);
					EmitCode::down();
						EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
						EmitCode::val_iname(K_value, Hierarchy::find(SUPPORTER_HL));
					EmitCode::up();
				EmitCode::up();
				@<Then jump to our doom@>;
			EmitCode::up();
		}
		if ((bp == a_has_b_predicate) || (bp == R_wearing) ||
			(bp == R_carrying)) {
			EmitCode::inv(IF_BIP);
			EmitCode::down();
				EmitCode::inv(NOT_BIP);
				EmitCode::down();
					EmitCode::inv(HAS_BIP);
					EmitCode::down();
						EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
						EmitCode::val_iname(K_value, Hierarchy::find(ANIMATE_HL));
					EmitCode::up();
				EmitCode::up();
				@<Then jump to our doom@>;
			EmitCode::up();
		}
		if ((bp == R_containment) ||
			(bp == R_support) ||
			(bp == a_has_b_predicate) ||
			(bp == R_wearing) ||
			(bp == R_carrying)) {
			TEMPORARY_TEXT(L)
			WRITE_TO(L, ".ol_mm_%d", ol_loop_counter++);
			inter_symbol *exit_label = EmitCode::reserve_label(L);
			DISCARD_TEXT(L)

			EmitCode::inv(OBJECTLOOP_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, gprk->rv_s);
				EmitCode::val_iname(K_value, RTKinds::I6_classname(K_object));
				EmitCode::inv(IN_BIP);
				EmitCode::down();
					EmitCode::val_symbol(K_value, gprk->rv_s);
					EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
				EmitCode::up();
				EmitCode::code();
				EmitCode::down();
					if (bp == R_carrying) {
						EmitCode::inv(IF_BIP);
						EmitCode::down();
							EmitCode::inv(HAS_BIP);
							EmitCode::down();
								EmitCode::val_symbol(K_value, gprk->rv_s);
								EmitCode::val_iname(K_value, RTProperties::iname(P_worn));
							EmitCode::up();
							EmitCode::code();
							EmitCode::down();
								EmitCode::inv(CONTINUE_BIP);
							EmitCode::up();
						EmitCode::up();
					}
					if (bp == R_wearing) {
						EmitCode::inv(IF_BIP);
						EmitCode::down();
							EmitCode::inv(NOT_BIP);
							EmitCode::down();
								EmitCode::inv(HAS_BIP);
								EmitCode::down();
									EmitCode::val_symbol(K_value, gprk->rv_s);
									EmitCode::val_iname(K_value, RTProperties::iname(P_worn));
								EmitCode::up();
							EmitCode::up();
							EmitCode::code();
							EmitCode::down();
								EmitCode::inv(CONTINUE_BIP);
							EmitCode::up();
						EmitCode::up();
					}
					EmitCode::inv(STORE_BIP);
					EmitCode::down();
						EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
						EmitCode::val_symbol(K_value, gprk->w_s);
					EmitCode::up();
					EmitCode::inv(STORE_BIP);
					EmitCode::down();
						EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
						EmitCode::inv(PLUS_BIP);
						EmitCode::down();
							EmitCode::val_symbol(K_value, gprk->w_s);
							EmitCode::call(Hierarchy::find(TRYGIVENOBJECT_HL));
							EmitCode::down();
								EmitCode::val_symbol(K_value, gprk->rv_s);
								EmitCode::val_true();
							EmitCode::up();
						EmitCode::up();
					EmitCode::up();
					EmitCode::inv(IF_BIP);
					EmitCode::down();
						EmitCode::inv(GT_BIP);
						EmitCode::down();
							EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
							EmitCode::val_symbol(K_value, gprk->w_s);
						EmitCode::up();
						EmitCode::code();
						EmitCode::down();
							EmitCode::inv(JUMP_BIP);
							EmitCode::down();
								EmitCode::lab(exit_label);
							EmitCode::up();
						EmitCode::up();
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, gprk->rv_s);
				EmitCode::val_number(0);
			EmitCode::up();
			@<Jump to our doom@>;
			EmitCode::place_label(exit_label);
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, gprk->rv_s);
				EmitCode::val_number(0);
			EmitCode::up();
		} else if (bp == R_incorporation) {
			TEMPORARY_TEXT(L)
			WRITE_TO(L, ".ol_mm_%d", ol_loop_counter++);
			inter_symbol *exit_label = EmitCode::reserve_label(L);
			DISCARD_TEXT(L)
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, gprk->rv_s);
				EmitCode::inv(PROPERTYVALUE_BIP);
				EmitCode::down();
					EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
					EmitCode::val_iname(K_value, Hierarchy::find(COMPONENT_CHILD_HL));
				EmitCode::up();
			EmitCode::up();
			EmitCode::inv(WHILE_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, gprk->rv_s);
				EmitCode::code();
				EmitCode::down();
					EmitCode::inv(STORE_BIP);
					EmitCode::down();
						EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
						EmitCode::val_symbol(K_value, gprk->w_s);
					EmitCode::up();
					EmitCode::inv(STORE_BIP);
					EmitCode::down();
						EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
						EmitCode::inv(PLUS_BIP);
						EmitCode::down();
							EmitCode::val_symbol(K_value, gprk->w_s);
							EmitCode::call(Hierarchy::find(TRYGIVENOBJECT_HL));
							EmitCode::down();
								EmitCode::val_symbol(K_value, gprk->rv_s);
								EmitCode::val_true();
							EmitCode::up();
						EmitCode::up();
					EmitCode::up();
					EmitCode::inv(IF_BIP);
					EmitCode::down();
						EmitCode::inv(GT_BIP);
						EmitCode::down();
							EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
							EmitCode::val_symbol(K_value, gprk->w_s);
						EmitCode::up();
						EmitCode::code();
						EmitCode::down();
							EmitCode::inv(JUMP_BIP);
							EmitCode::down();
								EmitCode::lab(exit_label);
							EmitCode::up();
						EmitCode::up();
					EmitCode::up();
					EmitCode::inv(STORE_BIP);
					EmitCode::down();
						EmitCode::ref_symbol(K_value, gprk->rv_s);
						EmitCode::inv(PROPERTYVALUE_BIP);
						EmitCode::down();
							EmitCode::val_symbol(K_value, gprk->rv_s);
							EmitCode::val_iname(K_value, Hierarchy::find(COMPONENT_SIBLING_HL));
						EmitCode::up();
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, gprk->rv_s);
				EmitCode::val_number(0);
			EmitCode::up();
			@<Jump to our doom@>;
			EmitCode::place_label(exit_label);
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, gprk->rv_s);
				EmitCode::val_number(0);
			EmitCode::up();
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
				EmitCode::inv(IF_BIP);
				EmitCode::down();
					EmitCode::inv(HAS_BIP);
					EmitCode::down();
						EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
						EmitCode::val_iname(K_value, RTProperties::iname(P_worn));
					EmitCode::up();
					@<Then jump to our doom@>;
				EmitCode::up();
			}
			if (BinaryPredicates::get_reversal(bp) == R_wearing) {
				EmitCode::inv(IF_BIP);
				EmitCode::down();
					EmitCode::inv(NOT_BIP);
					EmitCode::down();
						EmitCode::inv(HAS_BIP);
						EmitCode::down();
							EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
							EmitCode::val_iname(K_value, RTProperties::iname(P_worn));
						EmitCode::up();
					EmitCode::up();
					@<Then jump to our doom@>;
				EmitCode::up();
			}
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, gprk->rv_s);
				EmitCode::call_symbol(Emit::get_veneer_symbol(PARENT_VSYMB));
				EmitCode::down();
					EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
				EmitCode::up();
			EmitCode::up();

			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
				EmitCode::val_symbol(K_value, gprk->w_s);
			EmitCode::up();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
				EmitCode::inv(PLUS_BIP);
				EmitCode::down();
					EmitCode::val_symbol(K_value, gprk->w_s);
					EmitCode::call(Hierarchy::find(TRYGIVENOBJECT_HL));
					EmitCode::down();
						EmitCode::val_symbol(K_value, gprk->rv_s);
						EmitCode::val_true();
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
			EmitCode::inv(IF_BIP);
			EmitCode::down();
				EmitCode::inv(EQ_BIP);
				EmitCode::down();
					EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
					EmitCode::val_symbol(K_value, gprk->w_s);
				EmitCode::up();
				@<Then jump to our doom@>;
			EmitCode::up();
		} else if (BinaryPredicates::get_reversal(bp) == R_incorporation) {
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, gprk->rv_s);
				EmitCode::inv(PROPERTYVALUE_BIP);
				EmitCode::down();
					EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
					EmitCode::val_iname(K_value, Hierarchy::find(COMPONENT_PARENT_HL));
				EmitCode::up();
			EmitCode::up();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
				EmitCode::val_symbol(K_value, gprk->w_s);
			EmitCode::up();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
				EmitCode::inv(PLUS_BIP);
				EmitCode::down();
					EmitCode::val_symbol(K_value, gprk->w_s);
					EmitCode::call(Hierarchy::find(TRYGIVENOBJECT_HL));
					EmitCode::down();
						EmitCode::val_symbol(K_value, gprk->rv_s);
						EmitCode::val_true();
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
			EmitCode::inv(IF_BIP);
			EmitCode::down();
				EmitCode::inv(EQ_BIP);
				EmitCode::down();
					EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
					EmitCode::val_symbol(K_value, gprk->w_s);
				EmitCode::up();
				@<Then jump to our doom@>;
			EmitCode::up();
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
					EmitCode::inv(OBJECTLOOPX_BIP);
					EmitCode::down();
						EmitCode::ref_symbol(K_value, gprk->rv_s);
						EmitCode::val_iname(K_value, RTKinds::I6_classname(K));
						EmitCode::code();
						EmitCode::down();
							EmitCode::inv(IF_BIP);
							EmitCode::down();
								EmitCode::inv(EQ_BIP);
								EmitCode::down();
									pcalc_term rv_term = Terms::new_constant(
										Lvalues::new_LOCAL_VARIABLE(EMPTY_WORDING, gprk->rv_lv));
									pcalc_term self_term = Terms::new_constant(
										Rvalues::new_self_object_constant());
									if (reverse)
										CompileSchemas::from_terms_in_val_context(i6s, &rv_term, &self_term);
									else
										CompileSchemas::from_terms_in_val_context(i6s, &self_term, &rv_term);
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
				property *prn = ExplicitRelations::get_i6_storage_property(bp);
				reverse = FALSE;
				if (BinaryPredicates::is_the_wrong_way_round(bp)) reverse = TRUE;
				if (ExplicitRelations::get_form_of_relation(bp) == Relation_VtoO) {
					if (reverse) reverse = FALSE; else reverse = TRUE;
				}
				if (prn) {
					if (reverse) {
						EmitCode::inv(IF_BIP);
						EmitCode::down();
							EmitCode::inv(PROVIDES_BIP);
							EmitCode::down();
								EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
								EmitCode::val_iname(K_value, RTProperties::iname(prn));
							EmitCode::up();
							EmitCode::code();
							EmitCode::down();

								EmitCode::inv(STORE_BIP);
								EmitCode::down();
									EmitCode::ref_symbol(K_value, gprk->rv_s);
									EmitCode::inv(PROPERTYVALUE_BIP);
									EmitCode::down();
										EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
										EmitCode::val_iname(K_value, RTProperties::iname(prn));
									EmitCode::up();
								EmitCode::up();
								EmitCode::inv(IF_BIP);
								EmitCode::down();
									EmitCode::inv(EQ_BIP);
									EmitCode::down();
										EmitCode::val_symbol(K_value, gprk->rv_s);

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
						EmitCode::inv(OBJECTLOOPX_BIP);
						EmitCode::down();
							EmitCode::ref_symbol(K_value, gprk->rv_s);
							EmitCode::val_iname(K_value, RTKinds::I6_classname(K));
							EmitCode::code();
							EmitCode::down();
								EmitCode::inv(IF_BIP);
								EmitCode::down();
									EmitCode::inv(EQ_BIP);
									EmitCode::down();
										EmitCode::inv(AND_BIP);
										EmitCode::down();
											EmitCode::inv(PROVIDES_BIP);
											EmitCode::down();
												EmitCode::val_symbol(K_value, gprk->rv_s);
												EmitCode::val_iname(K_value, RTProperties::iname(prn));
											EmitCode::up();
											EmitCode::inv(EQ_BIP);
											EmitCode::down();
												EmitCode::inv(PROPERTYVALUE_BIP);
												EmitCode::down();
													EmitCode::val_symbol(K_value, gprk->rv_s);
													EmitCode::val_iname(K_value, RTProperties::iname(prn));
												EmitCode::up();
												EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
											EmitCode::up();
										EmitCode::up();
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

								EmitCode::val_false();
							EmitCode::up();
							EmitCode::code();
							EmitCode::down();
								if (continue_loop_on_fail == FALSE) {
									@<Jump to our doom@>;
								} else {
									EmitCode::inv(CONTINUE_BIP);
								}
							EmitCode::up();
						EmitCode::up();

						EmitCode::inv(STORE_BIP);
						EmitCode::down();
							EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
							EmitCode::val_symbol(K_value, gprk->w_s);
						EmitCode::up();
						EmitCode::inv(STORE_BIP);
						EmitCode::down();
							EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
							EmitCode::inv(PLUS_BIP);
							EmitCode::down();
								EmitCode::val_symbol(K_value, gprk->w_s);
								EmitCode::call(Hierarchy::find(TRYGIVENOBJECT_HL));
								EmitCode::down();
									EmitCode::val_symbol(K_value, gprk->rv_s);
									EmitCode::val_true();
								EmitCode::up();
							EmitCode::up();
						EmitCode::up();

						TEMPORARY_TEXT(L)
						WRITE_TO(L, ".ol_mm_%d", ol_loop_counter++);
						inter_symbol *exit_label = EmitCode::reserve_label(L);
						DISCARD_TEXT(L)

						EmitCode::inv(IF_BIP);
						EmitCode::down();
							EmitCode::inv(GT_BIP);
							EmitCode::down();
								EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
								EmitCode::val_symbol(K_value, gprk->w_s);
							EmitCode::up();
							EmitCode::code();
							EmitCode::down();
								EmitCode::inv(JUMP_BIP);
								EmitCode::down();
									EmitCode::lab(exit_label);
								EmitCode::up();
							EmitCode::up();
						EmitCode::up();

					EmitCode::up();
				EmitCode::up();
				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_symbol(K_value, gprk->rv_s);
					EmitCode::val_number(0);
				EmitCode::up();
				@<Jump to our doom@>;
				EmitCode::place_label(exit_label);
				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_symbol(K_value, gprk->rv_s);
					EmitCode::val_number(0);
				EmitCode::up();
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
					EmitCode::inv(STORE_BIP);
					EmitCode::down();
						EmitCode::ref_symbol(K_value, gprk->w_s);
						EmitCode::call(Hierarchy::find(PARSETOKENSTOPPED_HL));
						EmitCode::down();
							EmitCode::val_iname(K_value, Hierarchy::find(GPR_TT_HL));
							if (Str::len(i6_gpr_name) > 0)
								EmitCode::val_iname(K_value, Produce::find_by_name(Emit::tree(), i6_gpr_name));
							else
								EmitCode::val_iname(K_value, RTKinds::get_kind_GPR_iname(K));
						EmitCode::up();
					EmitCode::up();
					EmitCode::inv(IF_BIP);
					EmitCode::down();
						EmitCode::inv(NE_BIP);
						EmitCode::down();
							EmitCode::val_symbol(K_value, gprk->w_s);
							EmitCode::val_iname(K_number, Hierarchy::find(GPR_NUMBER_HL));
						EmitCode::up();
						@<Then jump to our doom@>;
					EmitCode::up();
					EmitCode::inv(STORE_BIP);
					EmitCode::down();
						EmitCode::ref_symbol(K_value, gprk->rv_s);
						EmitCode::val_iname(K_number, Hierarchy::find(GPR_NUMBER_HL));
					EmitCode::up();
				} else {
					if (Str::len(i6_gpr_name) > 0)
						EmitArrays::iname_entry(Produce::find_by_name(Emit::tree(), i6_gpr_name));
					else
						EmitArrays::iname_entry(RTKinds::get_kind_GPR_iname(K));
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
				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_symbol(K_value, gprk->w_s);
					EmitCode::call(Hierarchy::find(PARSETOKENSTOPPED_HL));
					EmitCode::down();
						EmitCode::val_iname(K_value, Hierarchy::find(ELEMENTARY_TT_HL));
						EmitCode::val_iname(K_value, i6_token_iname);
					EmitCode::up();
				EmitCode::up();
				EmitCode::inv(IF_BIP);
				EmitCode::down();
					EmitCode::inv(EQ_BIP);
					EmitCode::down();
						EmitCode::val_symbol(K_value, gprk->w_s);
						EmitCode::val_iname(K_number, Hierarchy::find(GPR_FAIL_HL));
					EmitCode::up();
					@<Then jump to our doom@>;
				EmitCode::up();
				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_symbol(K_value, gprk->rv_s);
					EmitCode::val_symbol(K_value, gprk->w_s);
				EmitCode::up();
			} else {
				EmitArrays::iname_entry(i6_token_iname);
			}
		} else {
			if (Specifications::is_description(spec)) {
				K = Specifications::to_kind(spec);
				if (Descriptions::is_qualified(spec)) {
 					if (code_mode) {
		 				EmitCode::inv(STORE_BIP);
						EmitCode::down();
							EmitCode::ref_symbol(K_value, gprk->w_s);
							EmitCode::call(Hierarchy::find(PARSETOKENSTOPPED_HL));
							EmitCode::down();
								UnderstandFilterTokens::compile_id(cgt->noun_filter);
							EmitCode::up();
						EmitCode::up();
						EmitCode::inv(IF_BIP);
						EmitCode::down();
							EmitCode::inv(EQ_BIP);
							EmitCode::down();
								EmitCode::val_symbol(K_value, gprk->w_s);
								EmitCode::val_iname(K_number, Hierarchy::find(GPR_FAIL_HL));
							EmitCode::up();
							@<Then jump to our doom@>;
						EmitCode::up();
						EmitCode::inv(STORE_BIP);
						EmitCode::down();
							EmitCode::ref_symbol(K_value, gprk->rv_s);
							EmitCode::val_symbol(K_value, gprk->w_s);
						EmitCode::up();
					} else {
						UnderstandFilterTokens::emit_id(cgt->noun_filter);
					}
				} else {
					if (Kinds::Behaviour::offers_I6_GPR(K)) {
						text_stream *i6_gpr_name = Kinds::Behaviour::get_explicit_I6_GPR(K);
						if (code_mode) {
							EmitCode::inv(STORE_BIP);
							EmitCode::down();
								EmitCode::ref_symbol(K_value, gprk->w_s);
								EmitCode::call(Hierarchy::find(PARSETOKENSTOPPED_HL));
								EmitCode::down();
									EmitCode::val_iname(K_value, Hierarchy::find(GPR_TT_HL));
									if (Str::len(i6_gpr_name) > 0)
										EmitCode::val_iname(K_value, Produce::find_by_name(Emit::tree(), i6_gpr_name));
									else
										EmitCode::val_iname(K_value, RTKinds::get_kind_GPR_iname(K));
								EmitCode::up();
							EmitCode::up();
							EmitCode::inv(IF_BIP);
							EmitCode::down();
								EmitCode::inv(NE_BIP);
								EmitCode::down();
									EmitCode::val_symbol(K_value, gprk->w_s);
									EmitCode::val_iname(K_number, Hierarchy::find(GPR_NUMBER_HL));
								EmitCode::up();
								@<Then jump to our doom@>;
							EmitCode::up();
							EmitCode::inv(STORE_BIP);
							EmitCode::down();
								EmitCode::ref_symbol(K_value, gprk->rv_s);
								EmitCode::val_iname(K_number, Hierarchy::find(GPR_NUMBER_HL));
							EmitCode::up();
						} else {
							if (Str::len(i6_gpr_name) > 0)
								EmitArrays::iname_entry(Produce::find_by_name(Emit::tree(), i6_gpr_name));
							else
								EmitArrays::iname_entry(RTKinds::get_kind_GPR_iname(K));
						}
					} else if (Kinds::Behaviour::is_object(K)) {
						if (code_mode) {
							EmitCode::inv(STORE_BIP);
							EmitCode::down();
								EmitCode::ref_symbol(K_value, gprk->w_s);
								EmitCode::call(Hierarchy::find(PARSETOKENSTOPPED_HL));
								EmitCode::down();
									UnderstandFilterTokens::compile_id(cgt->noun_filter);
								EmitCode::up();
							EmitCode::up();
							EmitCode::inv(IF_BIP);
							EmitCode::down();
								EmitCode::inv(EQ_BIP);
								EmitCode::down();
									EmitCode::val_symbol(K_value, gprk->w_s);
									EmitCode::val_iname(K_number, Hierarchy::find(GPR_FAIL_HL));
								EmitCode::up();
								@<Then jump to our doom@>;
							EmitCode::up();
							EmitCode::inv(STORE_BIP);
							EmitCode::down();
								EmitCode::ref_symbol(K_value, gprk->rv_s);
								EmitCode::val_symbol(K_value, gprk->w_s);
							EmitCode::up();
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
							EmitCode::inv(STORE_BIP);
							EmitCode::down();
								EmitCode::ref_symbol(K_value, gprk->w_s);
								EmitCode::call(Hierarchy::find(PARSETOKENSTOPPED_HL));
								EmitCode::down();
									EmitCode::val_iname(K_value, Hierarchy::find(GPR_TT_HL));
									EmitCode::val_iname(K_value, RTCommandGrammars::i6_token_as_iname(cg));
								EmitCode::up();
							EmitCode::up();
							EmitCode::inv(IF_BIP);
							EmitCode::down();
								EmitCode::inv(EQ_BIP);
								EmitCode::down();
									EmitCode::val_symbol(K_value, gprk->w_s);
									EmitCode::val_iname(K_number, Hierarchy::find(GPR_FAIL_HL));
								EmitCode::up();
								@<Then jump to our doom@>;
							EmitCode::up();

							EmitCode::inv(IF_BIP);
							EmitCode::down();
								EmitCode::inv(NE_BIP);
								EmitCode::down();
									EmitCode::val_symbol(K_value, gprk->w_s);
									EmitCode::val_iname(K_number, Hierarchy::find(GPR_PREPOSITION_HL));
								EmitCode::up();
								EmitCode::code();
								EmitCode::down();
									EmitCode::inv(STORE_BIP);
									EmitCode::down();
										EmitCode::ref_symbol(K_value, gprk->rv_s);
										EmitCode::val_symbol(K_value, gprk->w_s);
									EmitCode::up();
								EmitCode::up();
							EmitCode::up();
						} else {
							EmitArrays::iname_entry(RTCommandGrammars::i6_token_as_iname(cg));
						}
						K = CommandGrammars::get_kind_matched(cg);
					} else
				if (Node::is(spec, CONSTANT_NT)) {
					if (Rvalues::is_object(spec)) {
						if (code_mode) {
							EmitCode::inv(STORE_BIP);
							EmitCode::down();
								EmitCode::ref_symbol(K_value, gprk->w_s);
								EmitCode::call(Hierarchy::find(PARSETOKENSTOPPED_HL));
								EmitCode::down();
									UnderstandFilterTokens::compile_id(cgt->noun_filter);
								EmitCode::up();
							EmitCode::up();
							EmitCode::inv(IF_BIP);
							EmitCode::down();
								EmitCode::inv(EQ_BIP);
								EmitCode::down();
									EmitCode::val_symbol(K_value, gprk->w_s);
									EmitCode::val_iname(K_number, Hierarchy::find(GPR_FAIL_HL));
								EmitCode::up();
								@<Then jump to our doom@>;
							EmitCode::up();
							EmitCode::inv(STORE_BIP);
							EmitCode::down();
								EmitCode::ref_symbol(K_value, gprk->rv_s);
								EmitCode::val_symbol(K_value, gprk->w_s);
							EmitCode::up();
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
	EmitCode::code();
	EmitCode::down();
		@<Jump to our doom@>;
	EmitCode::up();

@<Jump to our doom@> =
	EmitCode::inv(JUMP_BIP);
	EmitCode::down();
		EmitCode::lab(failure_label);
	EmitCode::up();
