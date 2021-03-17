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
		packaging_state save = Routines::begin(cgl->compilation_data.mistake_iname);

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

		Routines::end(save);
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
	packaging_state save = Routines::begin(Hierarchy::make_iname_in(MISTAKEACTIONSUB_HL, MAP));

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
								Specifications::Compiler::emit_constant_to_kind_as_val(spec, K_text);
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

	Routines::end(save);
	
	MistakeAction_iname = Hierarchy::make_iname_in(MISTAKEACTION_HL, MAP);
	Emit::named_pseudo_numeric_constant(MistakeAction_iname, K_action_name, 10000);
	Produce::annotate_i(MistakeAction_iname, ACTION_IANN, 1);
	Hierarchy::make_available(Emit::tree(), MistakeAction_iname);
}

void RTCommandGrammarLines::cgl_compile_condition_token_as_needed(cg_line *cgl) {
	if (UnderstandLines::conditional(cgl)) {
		current_sentence = cgl->where_grammar_specified;

		package_request *PR = Hierarchy::local_package(COND_TOKENS_HAP);
		cgl->compilation_data.cond_token_iname = Hierarchy::make_iname_in(CONDITIONAL_TOKEN_FN_HL, PR);

		packaging_state save = Routines::begin(cgl->compilation_data.cond_token_iname);

		parse_node *spec = UnderstandLines::get_understand_cond(cgl);
		pcalc_prop *prop = cgl->understand_when_prop;

		if ((spec) || (prop)) {
			Produce::inv_primitive(Emit::tree(), IF_BIP);
			Produce::down(Emit::tree());
				if ((spec) && (prop)) {
					Produce::inv_primitive(Emit::tree(), AND_BIP);
					Produce::down(Emit::tree());
				}
				if (spec) Specifications::Compiler::emit_as_val(K_truth_state, spec);
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

		Routines::end(save);
	}
}

void RTCommandGrammarLines::cgl_compile_extra_token_for_condition(gpr_kit *gprk, cg_line *cgl,
	int cg_is, inter_symbol *current_label) {
	if (UnderstandLines::conditional(cgl)) {
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
	LOOP_THROUGH_SORTED_CG_LINES(cgl, cg)
		if (cgl->compilation_data.suppress_compilation == FALSE)
			RTCommandGrammarLines::compile_cg_line(gprk, cgl, cg_is, cg, genuinely_verbal);
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
	parse_node *pn;
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

	pn = cgl->tokens->down;
	if ((genuinely_verbal) && (pn)) {
		if (Annotations::read_int(pn, slash_class_ANNOT) != 0) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_SlashedCommand),
				"at present you're not allowed to use a / between command "
				"words at the start of a line",
				"so 'put/interpose/insert [something]' is out.");
			return;
		}
		pn = pn->next; /* skip command word: the |Verb| header contains it already */
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

	parse_node *pn_from = pn, *pn_to = pn_from;
	for (; pn; pn = pn->next) pn_to = pn;

	RTCommandGrammarLines::compile_token_line(gprk, code_mode, pn_from, pn_to, cg_is, consult_mode, &token_values, token_value_kinds, NULL, fail_label);

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
	struct parse_node *first_choice;
	struct parse_node *last_choice;
	struct inter_name *sgpr_iname;
	CLASS_DEFINITION
} slash_gpr;

@ =
void RTCommandGrammarLines::compile_token_line(gpr_kit *gprk, int code_mode, parse_node *pn, parse_node *pn_to, int cg_is, int consult_mode,
	int *token_values, kind **token_value_kinds, inter_symbol *group_wn_s, inter_symbol *fail_label) {
	int lexeme_equivalence_class = 0;
	int alternative_number = 0;
	int empty_text_allowed_in_lexeme = FALSE;

	inter_symbol *next_reserved_label = NULL;
	inter_symbol *eog_reserved_label = NULL;
	for (; pn; pn = pn->next) {
		if ((UnderstandTokens::is_text(pn)) && (pn->next) &&
			(UnderstandTokens::is_literal(pn->next) == FALSE)) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TextFollowedBy),
				"a '[text]' token must either match the end of some text, or "
				"be followed by definitely known wording",
				"since otherwise the run-time parser isn't good enough to "
				"make sense of things.");
		}

		if ((Node::get_grammar_token_relation(pn)) && (cg_is != CG_IS_SUBJECT)) {
			if (problem_count == 0)
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_GrammarObjectlessRelation),
				"a grammar token in an 'Understand...' can only be based "
				"on a relation if it is to understand the name of a room or thing",
				"since otherwise there is nothing for the relation to be with.");
			continue;
		}

		int first_token_in_lexeme = FALSE, last_token_in_lexeme = FALSE;

		if (Annotations::read_int(pn, slash_class_ANNOT) != 0) { /* in a multi-token lexeme */
			if ((pn->next == NULL) ||
				(Annotations::read_int(pn->next, slash_class_ANNOT) !=
					Annotations::read_int(pn, slash_class_ANNOT)))
				last_token_in_lexeme = TRUE;
			if (Annotations::read_int(pn, slash_class_ANNOT) != lexeme_equivalence_class) {
				first_token_in_lexeme = TRUE;
				empty_text_allowed_in_lexeme =
					Annotations::read_int(pn, slash_dash_dash_ANNOT);
			}
			lexeme_equivalence_class = Annotations::read_int(pn, slash_class_ANNOT);
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
			sgpr->first_choice = pn;
			while ((pn->next) &&
					(Annotations::read_int(pn->next, slash_class_ANNOT) ==
					Annotations::read_int(pn, slash_class_ANNOT))) pn = pn->next;
			sgpr->last_choice = pn;
			package_request *PR = Hierarchy::local_package(SLASH_TOKENS_HAP);
			sgpr->sgpr_iname = Hierarchy::make_iname_in(SLASH_FN_HL, PR);
			Emit::array_iname_entry(sgpr->sgpr_iname);
			last_token_in_lexeme = TRUE;
		} else {
			kind *grammar_token_kind =
				UnderstandTokens::compile(gprk, pn, code_mode, jump_on_fail, consult_mode);
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

		if (pn == pn_to) break;
	}
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
		packaging_state save = Routines::begin(sgpr->sgpr_iname);
		gpr_kit gprk = UnderstandValueTokens::new_kit();
		UnderstandValueTokens::add_original(&gprk);
		UnderstandValueTokens::add_standard_set(&gprk);

		RTCommandGrammarLines::compile_token_line(&gprk, TRUE, sgpr->first_choice, sgpr->last_choice, CG_IS_TOKEN, FALSE, NULL, NULL, gprk.group_wn_s, NULL);
		Produce::inv_primitive(Emit::tree(), RETURN_BIP);
		Produce::down(Emit::tree());
			Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(GPR_PREPOSITION_HL));
		Produce::up(Emit::tree());
		Routines::end(save);
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
		int wn = UnderstandLines::cgl_contains_single_unconditional_word(cgl);
		if (wn >= 0) {
			TEMPORARY_TEXT(content)
			WRITE_TO(content, "%w", Lexer::word_text(wn));
			Emit::array_dword_entry(content);
			DISCARD_TEXT(content)
			cgl->compilation_data.suppress_compilation = TRUE;
		}
	}
}
