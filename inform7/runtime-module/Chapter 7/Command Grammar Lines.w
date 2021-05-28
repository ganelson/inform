[RTCommandGrammarLines::] Command Grammar Lines.

Compiling lines of command parser grammar.

@h Compilation data.
Each |cg_line| object contains this data:

=
typedef struct cg_line_compilation_data {
	int suppress_compilation; /* has been compiled in a single I6 grammar token already? */
	struct inter_name *cond_token_iname; /* for its |Cond_Token_*| routine, if any */
	int cond_token_compiled;
	struct inter_name *mistake_iname; /* for its |Mistake_Token_*| routine, if any */
} cg_line_compilation_data;

cg_line_compilation_data RTCommandGrammarLines::new_compilation_data(cg_line *cg) {
	cg_line_compilation_data cglcd;
	cglcd.suppress_compilation = FALSE;
	cglcd.cond_token_iname = NULL;
	cglcd.cond_token_compiled = FALSE;
	cglcd.mistake_iname = NULL;
	return cglcd;
}

@ =
inter_name *RTCommandGrammarLines::get_cond_token_iname(cg_line *cgl) {
	if (cgl->compilation_data.cond_token_iname == NULL)
		cgl->compilation_data.cond_token_iname =
			Hierarchy::make_iname_in(CONDITIONAL_TOKEN_FN_HL,
				Hierarchy::completion_package(COND_TOKENS_HAP));
	return cgl->compilation_data.cond_token_iname;
}

inter_name *RTCommandGrammarLines::get_mistake_iname(cg_line *cgl) {
	if (cgl->compilation_data.mistake_iname == NULL)
		cgl->compilation_data.mistake_iname =
			Hierarchy::make_iname_in(MISTAKE_FN_HL,
				Hierarchy::completion_package(MISTAKES_HAP));
	return cgl->compilation_data.mistake_iname;
}

@h Compilation.
The following apparently global variables are used to provide a persistent
state for the routine below, but are not accessed elsewhere. The label
counter is reset at the start of each CG's compilation, though this is a
purely cosmetic effect.

=
typedef struct command_grammar_compilation {
	int current_grammar_block;
	int current_label;
	int GV_IS_VALUE_instance_mode;
} command_grammar_compilation;

int next_cg_block_id = 1;
command_grammar_compilation RTCommandGrammarLines::new_cgc(void) {
	command_grammar_compilation cgc;
	cgc.current_label = 1;
//	cgc.current_grammar_block = next_cg_block_id++;
	cgc.current_grammar_block = 0;
	cgc.GV_IS_VALUE_instance_mode = FALSE;
	return cgc;
}

@ As fancy as the following routine may look, it contains very little.
What complexity there is comes from the fact that command CGs are compiled
very differently to all others (most grammars are compiled in "code mode",
generating procedural I6 statements, but command CGs are compiled to lines
in |Verb| directives) and that CGLs resulting in actions (i.e., CGLs in
command CGs) have not yet been type-checked, whereas all others have.

=
void RTCommandGrammarLines::compile_cg_line(gpr_kit *kit, cg_line *cgl, int cg_is,
	int genuinely_verbal, command_grammar_compilation *cgc) {
	current_sentence = cgl->where_grammar_specified;
	int code_mode = TRUE; if (cg_is == CG_IS_COMMAND) code_mode = FALSE;
	LOGIF(GRAMMAR, "Compiling grammar line: $g (%s)\n", cgl, (code_mode)?"code":"array");

//	if (cg_is == CG_IS_COMMAND) code_mode = FALSE; else code_mode = TRUE;
//	if (cg_is == CG_IS_CONSULT) consult_mode = TRUE; else consult_mode = FALSE;

	inter_symbol *fail_label = NULL;
	if (kit) {
		TEMPORARY_TEXT(L)
		WRITE_TO(L, ".Fail_%d", cgc->current_label);
		fail_label = EmitCode::reserve_label(L);
		DISCARD_TEXT(L)
	}

	int token_values = 0;
	kind *token_value_kinds[2];
	for (int i=0; i<2; i++) token_value_kinds[i] = NULL;

	if (code_mode == FALSE) EmitArrays::iname_entry(Hierarchy::find(VERB_DIRECTIVE_DIVIDER_HL));

	RTCommandGrammarLines::cgl_compile_extra_token_for_condition(kit, cgl, cg_is, fail_label);
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

	if ((cg_is == CG_IS_VALUE) && (cgc->GV_IS_VALUE_instance_mode)) {
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, kit->instance_s);
				CompileValues::to_code_val(cgl->cgl_type.term[0].what);
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
	}

	cg_token *cgt_from = cgt, *cgt_to = cgt_from;
	for (; cgt; cgt = cgt->next_token) cgt_to = cgt;
	RTCommandGrammarLines::compile_token_line(kit, code_mode, cgt_from, cgt_to, cg_is, &token_values, token_value_kinds, NULL, fail_label, cgc);

	switch (cg_is) {
		case CG_IS_COMMAND:
			if (RTCommandGrammarLines::cgl_compile_result_of_mistake(kit, cgl)) break;
			EmitArrays::iname_entry(Hierarchy::find(VERB_DIRECTIVE_RESULT_HL));
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
				EmitArrays::iname_entry(Hierarchy::find(VERB_DIRECTIVE_REVERSE_HL));
			}

			ActionSemantics::check_valid_application(cgl->resulting_action, token_values,
				token_value_kinds);
			break;
		case CG_IS_PROPERTY_NAME:
		case CG_IS_TOKEN:
			EmitCode::inv(RETURN_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, kit->rv_s);
			EmitCode::up();
			EmitCode::place_label(fail_label);
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, kit->rv_s);
				EmitCode::val_iname(K_value, Hierarchy::find(GPR_PREPOSITION_HL));
			EmitCode::up();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
				EmitCode::val_symbol(K_value, kit->original_wn_s);
			EmitCode::up();
			break;
		case CG_IS_CONSULT:
			EmitCode::inv(IF_BIP);
			EmitCode::down();
				EmitCode::inv(OR_BIP);
				EmitCode::down();
					EmitCode::inv(EQ_BIP);
					EmitCode::down();
						EmitCode::val_symbol(K_value, kit->range_words_s);
						EmitCode::val_number(0);
					EmitCode::up();
					EmitCode::inv(EQ_BIP);
					EmitCode::down();
						EmitCode::inv(MINUS_BIP);
						EmitCode::down();
							EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
							EmitCode::val_symbol(K_value, kit->range_from_s);
						EmitCode::up();
						EmitCode::val_symbol(K_value, kit->range_words_s);
					EmitCode::up();
				EmitCode::up();
				EmitCode::code();
				EmitCode::down();
					EmitCode::inv(RETURN_BIP);
					EmitCode::down();
						EmitCode::val_symbol(K_value, kit->rv_s);
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();

			EmitCode::place_label(fail_label);
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, kit->rv_s);
				EmitCode::val_iname(K_value, Hierarchy::find(GPR_PREPOSITION_HL));
			EmitCode::up();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
				EmitCode::val_symbol(K_value, kit->original_wn_s);
			EmitCode::up();
			break;
		case CG_IS_SUBJECT:
			ParseName::compile_reset_code_after_failed_line(kit, fail_label, cgl->pluralised);
			break;
		case CG_IS_VALUE:
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_iname(K_value, Hierarchy::find(PARSED_NUMBER_HL));
				CompileValues::to_code_val(cgl->cgl_type.term[0].what);
			EmitCode::up();
			EmitCode::inv(RETURN_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_object, Hierarchy::find(GPR_NUMBER_HL));
			EmitCode::up();
			EmitCode::place_label(fail_label);
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
				EmitCode::val_symbol(K_value, kit->original_wn_s);
			EmitCode::up();
			break;
	}

	if ((cg_is == CG_IS_VALUE) && (cgc->GV_IS_VALUE_instance_mode)) {
			EmitCode::up();
		EmitCode::up();
	}

	cgc->current_label++;
}

@ =
typedef struct slash_gpr {
	struct cg_token *first_choice;
	struct cg_token *last_choice;
	struct inter_name *sgpr_iname;
	CLASS_DEFINITION
} slash_gpr;

@ =
void RTCommandGrammarLines::compile_token_line(gpr_kit *kit, int code_mode, cg_token *cgt, cg_token *cgt_to, int cg_is,
	int *token_values, kind **token_value_kinds, inter_symbol *group_wn_s, inter_symbol *fail_label, command_grammar_compilation *cgc) {
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
						EmitCode::ref_symbol(K_value, kit->group_wn_s);
						EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
					EmitCode::up();
				}
				if (next_reserved_label) EmitCode::place_label(next_reserved_label);
				TEMPORARY_TEXT(L)
				WRITE_TO(L, ".group_%d_%d_%d", cgc->current_grammar_block,
					lexeme_equivalence_class, alternative_number+1);
				next_reserved_label = EmitCode::reserve_label(L);
				DISCARD_TEXT(L)

				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
					EmitCode::val_symbol(K_value, kit->group_wn_s);
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
			text_stream *desc = Str::new();
			WRITE_TO(desc, "slash GPR %d", sgpr->allocation_id);
			Sequence::queue(&RTCommandGrammarLines::slash_GPR_agent,
				STORE_POINTER_slash_gpr(sgpr), desc);
		} else {
			int consult_mode = (cg_is == CG_IS_CONSULT)?TRUE:FALSE;
			kind *grammar_token_kind =
				RTCommandGrammarTokens::compile(kit, cgt, code_mode, jump_on_fail, consult_mode);
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
							EmitCode::val_symbol(K_value, kit->group_wn_s);
						EmitCode::up();
					}
					if (eog_reserved_label) EmitCode::place_label(eog_reserved_label);
					eog_reserved_label = NULL;
				} else {
					@<Jump to end of group@>;
				}
			} else {
				if (last_token_in_lexeme == FALSE)
					EmitArrays::iname_entry(Hierarchy::find(VERB_DIRECTIVE_SLASH_HL));
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
			cgc->current_grammar_block, lexeme_equivalence_class);
		eog_reserved_label = EmitCode::reserve_label(L);
	}
	EmitCode::inv(JUMP_BIP);
	EmitCode::down();
		EmitCode::lab(eog_reserved_label);
	EmitCode::up();

@ =
void RTCommandGrammarLines::slash_GPR_agent(compilation_subtask *t) {
	slash_gpr *sgpr = RETRIEVE_POINTER_slash_gpr(t->data);
	packaging_state save = Functions::begin(sgpr->sgpr_iname);
	gpr_kit kit = GPRs::new_kit();
	GPRs::add_original_var(&kit);
	GPRs::add_standard_vars(&kit);
	command_grammar_compilation cgc = RTCommandGrammarLines::new_cgc();

	RTCommandGrammarLines::compile_token_line(&kit, TRUE, sgpr->first_choice, sgpr->last_choice, CG_IS_TOKEN, NULL, NULL, kit.group_wn_s, NULL, &cgc);



	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
		EmitCode::val_iname(K_value, Hierarchy::find(GPR_PREPOSITION_HL));
	EmitCode::up();
	Functions::end(save);
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



@h Mistaken grammar lines.
"Mistaken" lines are command which can be matched, but only in order to
print nicely worded rejections. A number of implementations were tried for
this, for instance producing parser errors and setting |pe| to some high
value, but the method now used is for a mistaken line to produce a successful
parse but result in the (fake) action |##MistakeAction|. The hard part is to
send information to the processing function for that action, |MistakeActionSub|,
indicating what the mistake was, exactly. We do this by beginning the line
with an additional token matching the empty text (and thus, always matching)
but with the side-effect of setting a special global variable. Thus a mistaken
line |act [thing]| comes out as something like:
= (text)
* Mistake_Token_12 'act' noun -> MistakeAction
=
Since the command parser accepts the first command which matches, and since
none of this can be recursive, the value of this variable at the end of
command parsing is guaranteed to be the one set during the line causing the
mistake.

The following compiles a simple GPR to perform this "match":

=
void RTCommandGrammarLines::cgl_compile_extra_token_for_mistake(cg_line *cgl, int cg_is) {
	if (cgl->mistaken) {
		EmitArrays::iname_entry(RTCommandGrammarLines::get_mistake_iname(cgl));
		text_stream *desc = Str::new();
		WRITE_TO(desc, "mistake token %d", 100 + cgl->allocation_id);
		Sequence::queue(&RTCommandGrammarLines::mistake_agent, STORE_POINTER_cg_line(cgl), desc);
	}
}
void RTCommandGrammarLines::mistake_agent(compilation_subtask *t) {
	cg_line *cgl = RETRIEVE_POINTER_cg_line(t->data);
	packaging_state save = Functions::begin(RTCommandGrammarLines::get_mistake_iname(cgl));

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

@ At the far end of the grammar line, we also have to give the nonstandard
result, the "MistakeAction".

=
int RTCommandGrammarLines::cgl_compile_result_of_mistake(gpr_kit *kit, cg_line *cgl) {
	if (cgl->mistaken) {
		EmitArrays::iname_entry(Hierarchy::find(VERB_DIRECTIVE_RESULT_HL));
		EmitArrays::iname_entry(Hierarchy::find(MISTAKEACTION_HL));
		return TRUE;
	}
	return FALSE;
}

@ Because //CommandParserKit// needs to be able to discuss |MistakeAction|,
we need to compile this constant even if there are, in fact, no mistaken
grammar lines; and since this is a fake action, it needs a |MistakeActionSub|
function to process it.

=
void RTCommandGrammarLines::MistakeActionSub(void) {
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
	
	inter_name *ma_iname = Hierarchy::find(MISTAKEACTION_HL);
	Emit::unchecked_numeric_constant(ma_iname, 10000);
	Produce::annotate_i(ma_iname, ACTION_IANN, 1);
	Hierarchy::make_available(ma_iname);
}

@h Conditional grammar lines.
Conditional lines are those which match only if some condition holds, and that
can be any condition expressed in Inform 7 source text.

Once again we do this by means of an additional token at the start of the line,
which matches no text, but which matches successfully only if the condition holds.
Note that the remaining tokens in the line are therefore not even looked at if
the condition fails; this of course is faster than if the test were placed at
the end.

Unlike the case of mistaken tokens, a conditional token can appear in any grammar,
not only in CG_IS_COMMAND grammar, so (a) we sometimes must compile code and not
just an extra array entry, and (b) we must be careful about the unusual but not
impossible case of the same grammar line being compiled twice, which can happen
because of |parse_name| inheritance with CG_IS_SUBJECT grammars.

=
void RTCommandGrammarLines::cgl_compile_extra_token_for_condition(gpr_kit *kit, cg_line *cgl,
	int cg_is, inter_symbol *current_label) {
	if (CGLines::conditional(cgl)) {
		if (cg_is == CG_IS_COMMAND) {
			EmitArrays::iname_entry(RTCommandGrammarLines::get_cond_token_iname(cgl));
		} else {
			EmitCode::inv(IF_BIP);
			EmitCode::down();
				EmitCode::inv(EQ_BIP);
				EmitCode::down();
					EmitCode::call(RTCommandGrammarLines::get_cond_token_iname(cgl));
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
		if (cgl->compilation_data.cond_token_compiled == FALSE) {
			cgl->compilation_data.cond_token_compiled = TRUE;
			text_stream *desc = Str::new();
			WRITE_TO(desc, "conditional token %W", Node::get_text(CGLines::get_understand_cond(cgl)));
			Sequence::queue(&RTCommandGrammarLines::cond_agent, STORE_POINTER_cg_line(cgl), desc);
		}
	}
}

@ So, then, the code above ensures that this GPR function is compiled exactly
once per conditional grammar line:

=
void RTCommandGrammarLines::cond_agent(compilation_subtask *t) {
	cg_line *cgl = RETRIEVE_POINTER_cg_line(t->data);
	current_sentence = cgl->where_grammar_specified;

	packaging_state save = Functions::begin(RTCommandGrammarLines::get_cond_token_iname(cgl));

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
