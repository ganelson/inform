[RTCommandGrammarLines::] Command Grammar Lines.

Compiling lines of command parser grammar.

@h Compilation data.
Each |cg_line| object contains this data, though except for the |suppress_compilation|
flag, most of it is rarely used:

=
typedef struct cg_line_compilation_data {
	struct package_request *metadata_package;
	struct inter_name *xref_iname;
	int suppress_compilation; /* has been compiled in a single grammar token already? */
	struct inter_name *cond_token_iname; /* for its |Cond_Token_*| routine, if any */
	int cond_token_compiled;
	struct inter_name *mistake_iname; /* for its |Mistake_Token_*| routine, if any */
	struct cg_line *next_with_action; /* used when indexing actions */
	struct command_grammar *belongs_to_cg; /* similarly, used only in indexing */
} cg_line_compilation_data;

cg_line_compilation_data RTCommandGrammarLines::new_compilation_data(cg_line *cg) {
	cg_line_compilation_data cglcd;
	cglcd.metadata_package = NULL;
	cglcd.xref_iname = NULL;
	cglcd.suppress_compilation = FALSE;
	cglcd.cond_token_iname = NULL;
	cglcd.cond_token_compiled = FALSE;
	cglcd.mistake_iname = NULL;
	cglcd.belongs_to_cg = NULL;
	cglcd.next_with_action = NULL;
	return cglcd;
}

@ So this is where some lines in a command grammar's list are flagged to be
suppressed.

It's called when the |name| property array is being compiled, and what it
does is to notice when a line contains just a single word, and if so, compile
that as an extra entry for the |name| array, then mark it to be skipped when
a |parse_name| function is being compiled. Effectively, then, it moves this
content from |parse_name| to |name|, an optimisation which is just a little
faster for the command parser to deal with, and saves a few bytes at runtime.

=
void RTCommandGrammarLines::list_take_out_one_word_grammar(command_grammar *cg) {
	if (cg->cg_is != CG_IS_SUBJECT)
		internal_error("One-word optimisation applies only to CG_IS_SUBJECT");
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

@ These inames are used only by two special forms of CG line: see below. For the
great majority of lines, both will remain |NULL|.

=
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

@ Grammar lines are typically indexed twice: the other time is when all
grammar lines belonging to a given action are tabulated. Special linked
lists are kept for this purpose, and this is where we unravel them and
print to the index. The question of sorted vs unsorted is meaningless
here, since the CGLs appearing in such a list will typically belong to
several different CGs. (As it happens, they appear in order of creation,
i.e., in source text order.)

Tiresomely, all of this means that we need to store "uphill" pointers
in CGLs: back up to the CGs that own them. The following routine does
this for a whole list of CGLs:

=
void RTCommandGrammarLines::list_assert_ownership(command_grammar *cg) {
	LOOP_THROUGH_UNSORTED_CG_LINES(cgl, cg)
		cgl->compilation_data.belongs_to_cg = cg;
}

@ And this routine accumulates the per-action lists of CGLs:

=
void RTCommandGrammarLines::list_with_action_add(cg_line *list_head, cg_line *cgl) {
	if (list_head == NULL) internal_error("tried to add to null action list");
	while (list_head->compilation_data.next_with_action)
		list_head = list_head->compilation_data.next_with_action;
	list_head->compilation_data.next_with_action = cgl;
}

@h Compilation.
Some grammar lines compile as a run of array entries (those for CG_IS_COMMAND),
and others are compiled into code which matches them.

"Genuinely verbal" grammar is grammar beginning with a command verb; that will
be most, but not all, CG_IS_COMMAND grammars, and no others.

=
void RTCommandGrammarLines::compile_cg_line(gpr_kit *kit, cg_line *cgl, int cg_is,
	int genuinely_verbal) {
	LOGIF(GRAMMAR, "Compiling grammar line: $g\n", cgl);

	current_sentence = cgl->where_grammar_specified;
	GPRs::begin_line(kit);

	if (cg_is == CG_IS_COMMAND) @<Compile CG_IS_COMMAND line-starting material@>;
	if (cg_is == CG_IS_VALUE) @<Compile CG_IS_VALUE line-starting material@>;
	if (CGLines::conditional(cgl))
		RTCommandGrammarLines::cgl_compile_extra_token_for_condition(kit, cgl, cg_is);
	if (cgl->mistaken)
		RTCommandGrammarLines::cgl_compile_extra_token_for_mistake(cgl, cg_is);

	cg_token *token_from = NULL, *token_to = NULL;
	@<Find the token range@>;

	if (problem_count == 0)
		RTCommandGrammarLines::compile_token_range(kit, token_from, token_to,
			cg_is, NULL);

	if (cg_is == CG_IS_COMMAND) @<Compile CG_IS_COMMAND line-ending material@>;
	if ((cg_is == CG_IS_PROPERTY_NAME) || (cg_is == CG_IS_TOKEN))
		@<Compile CG_IS_PROPERTY_NAME or CG_IS_TOKEN line-ending material@>;
	if (cg_is == CG_IS_CONSULT) @<Compile CG_IS_CONSULT line-ending material@>;
	if (cg_is == CG_IS_SUBJECT) @<Compile CG_IS_SUBJECT line-ending material@>;
	if (cg_is == CG_IS_VALUE) @<Compile CG_IS_VALUE line-ending material@>;
}

@<Compile CG_IS_COMMAND line-starting material@> =
	EmitArrays::iname_entry(Hierarchy::find(VERB_DIRECTIVE_DIVIDER_HL));

@<Compile CG_IS_VALUE line-starting material@> =
	if (kit->GV_IS_VALUE_instance_mode) {
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

@<Find the token range@> =
	cg_token *token = cgl->tokens;
	if ((genuinely_verbal) && (token)) token = token->next_token; /* skip command word */
	token_from = token; token_to = token;
	for (; token; token = token->next_token) token_to = token;

@<Compile CG_IS_COMMAND line-ending material@> =
	if (RTCommandGrammarLines::cgl_compile_result_of_mistake(kit, cgl) == FALSE) {
		EmitArrays::iname_entry(Hierarchy::find(VERB_DIRECTIVE_RESULT_HL));
		EmitArrays::iname_entry(RTActions::double_sharp(cgl->resulting_action));
		if (cgl->reversed) {
			EmitArrays::iname_entry(Hierarchy::find(VERB_DIRECTIVE_REVERSE_HL));
		}
	}

@<Compile CG_IS_PROPERTY_NAME or CG_IS_TOKEN line-ending material@> =
	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
		EmitCode::val_symbol(K_value, kit->rv_s);
	EmitCode::up();
	EmitCode::place_label(kit->fail_label);
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

@<Compile CG_IS_CONSULT line-ending material@> =
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

	EmitCode::place_label(kit->fail_label);
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

@<Compile CG_IS_SUBJECT line-ending material@> =
	ParseName::compile_reset_code_after_failed_line(kit, cgl->pluralised);

@<Compile CG_IS_VALUE line-ending material@> =
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_iname(K_value, Hierarchy::find(PARSED_NUMBER_HL));
		CompileValues::to_code_val(cgl->cgl_type.term[0].what);
	EmitCode::up();
	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
		EmitCode::val_iname(K_object, Hierarchy::find(GPR_NUMBER_HL));
	EmitCode::up();
	EmitCode::place_label(kit->fail_label);
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
		EmitCode::val_symbol(K_value, kit->original_wn_s);
	EmitCode::up();

	if (kit->GV_IS_VALUE_instance_mode) {
		EmitCode::up(); EmitCode::up();
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
	EmitArrays::iname_entry(RTCommandGrammarLines::get_mistake_iname(cgl));
	text_stream *desc = Str::new();
	WRITE_TO(desc, "mistake token %d", 100 + cgl->allocation_id);
	Sequence::queue(&RTCommandGrammarLines::mistake_agent, STORE_POINTER_cg_line(cgl), desc);
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
	InterNames::annotate_b(ma_iname, ACTION_IANN, 1);
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
	int cg_is) {
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
					EmitCode::lab(kit->fail_label);
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

@h Slash GPRs.
These are functions which match exactly one of the tokens in the given range;
so, for example, |fish/fowl/duck/drake| could be handled by a slash GPR.

=
typedef struct slash_gpr {
	struct cg_token *first_choice;
	struct cg_token *last_choice;
	struct inter_name *sgpr_iname;
	CLASS_DEFINITION
} slash_gpr;

@ =
inter_name *RTCommandGrammarLines::slash(cg_token *from_token, cg_token *to_token) {
	slash_gpr *sgpr = CREATE(slash_gpr);
	sgpr->first_choice = from_token;
	sgpr->last_choice = to_token;
	package_request *PR = Hierarchy::local_package(SLASH_TOKENS_HAP);
	sgpr->sgpr_iname = Hierarchy::make_iname_in(SLASH_FN_HL, PR);
	text_stream *desc = Str::new();
	WRITE_TO(desc, "slash GPR %d", sgpr->allocation_id);
	Sequence::queue(&RTCommandGrammarLines::slash_GPR_agent, STORE_POINTER_slash_gpr(sgpr), desc);
	return sgpr->sgpr_iname;
}

void RTCommandGrammarLines::slash_GPR_agent(compilation_subtask *t) {
	slash_gpr *sgpr = RETRIEVE_POINTER_slash_gpr(t->data);
	packaging_state save = Functions::begin(sgpr->sgpr_iname);
	gpr_kit kit = GPRs::new_kit();
	GPRs::add_original_var(&kit);
	GPRs::add_standard_vars(&kit);
	RTCommandGrammarLines::compile_token_range(&kit,
		sgpr->first_choice, sgpr->last_choice, CG_IS_TOKEN, kit.group_wn_s);
	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
		EmitCode::val_iname(K_value, Hierarchy::find(GPR_PREPOSITION_HL));
	EmitCode::up();
	Functions::end(save);
}

@h Compiling token ranges.
This all looks festooned with complexity, but in fact it's almost the same as
looping through the tokens in sequence and calling //RTCommandGrammarTokens::compile//
on each in turn. The complications come from "slash classes", i.e., the ability
to specify a disjunction like |A/B/C/D|: this looks like a range of 4 tokens.

=
void RTCommandGrammarLines::compile_token_range(gpr_kit *kit,
	cg_token *token_from, cg_token *token_to, int cg_is, inter_symbol *group_wn_s) {
	int code_mode = TRUE; if (cg_is == CG_IS_COMMAND) code_mode = FALSE;
	int slash_equivalence_class = 0;
	int alternative_number = 0;
	int empty_text_allowed_in_class = FALSE;
	inter_symbol *next_reserved_label = NULL;
	inter_symbol *eog_reserved_label = NULL;
	LOGIF(GRAMMAR_CONSTRUCTION, "Compiling token range $c -> $c\n", token_from, token_to);
	LOG_INDENT;
	for (cg_token *token = token_from;
		((token) && (token != token_to->next_token));
		token = token->next_token) {
		LOGIF(GRAMMAR_CONSTRUCTION, "Compiling token $c\n", token);
		int first_token_in_class = TRUE, last_token_in_class = TRUE;

		if (token->slash_class != 0) @<This token is part of a slashed class@>
		else @<This token is not part of a class@>;
		if (first_token_in_class) alternative_number = 1;
		else alternative_number++;

		inter_symbol *jump_on_fail = NULL;
		if (kit) jump_on_fail = kit->fail_label;

		if (slash_equivalence_class > 0) @<Pretoken matter within a slash-class@>;

		if ((empty_text_allowed_in_class) && (code_mode == FALSE)) {
			@<Absorb the whole slash-class as a GPR@>;
		} else {
			int consult_mode = (cg_is == CG_IS_CONSULT)?TRUE:FALSE;
			if (problem_count == 0)
				RTCommandGrammarTokens::compile(kit, token, code_mode,
					jump_on_fail, consult_mode);
		}

		if (slash_equivalence_class > 0) @<Posttoken matter within a slash-class@>;
	}
	LOG_OUTDENT;
}

@<This token is part of a slashed class@> =
	first_token_in_class = FALSE;
	last_token_in_class = FALSE;
	if ((token->next_token == NULL) ||
		(token->next_token->slash_class != token->slash_class))
		last_token_in_class = TRUE;
	if (token->slash_class != slash_equivalence_class) {
		first_token_in_class = TRUE;
		empty_text_allowed_in_class = token->slash_dash_dash;
	}
	slash_equivalence_class = token->slash_class;

@<This token is not part of a class@> =
	slash_equivalence_class = 0;
	empty_text_allowed_in_class = FALSE;

@<Pretoken matter within a slash-class@> =
	if (code_mode) {
		if (first_token_in_class) {
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, kit->group_wn_s);
				EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
			EmitCode::up();
		}
		if (next_reserved_label) EmitCode::place_label(next_reserved_label);
		TEMPORARY_TEXT(L)
		WRITE_TO(L, ".class_%d_%d_%d", kit->current_grammar_block,
			slash_equivalence_class, alternative_number+1);
		next_reserved_label = EmitCode::reserve_label(L);
		DISCARD_TEXT(L)

		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
			EmitCode::val_symbol(K_value, kit->group_wn_s);
		EmitCode::up();

		if ((last_token_in_class == FALSE) || (empty_text_allowed_in_class)) {
			jump_on_fail = next_reserved_label;
		}
	}

@<Absorb the whole slash-class as a GPR@> =
	struct cg_token *first_choice = token;
	struct cg_token *last_choice = token;
	while ((token->next_token) &&
			(token->next_token->slash_class == token->slash_class))
		token = token->next_token;
	last_choice = token;
	inter_name *iname = RTCommandGrammarLines::slash(first_choice, last_choice);
	EmitArrays::iname_entry(iname);
	last_token_in_class = TRUE;

@<Posttoken matter within a slash-class@> =
	if (code_mode) {
		if (last_token_in_class) {
			if (empty_text_allowed_in_class) {
				@<Jump to end of class@>;
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
			@<Jump to end of class@>;
		}
	} else {
		if (last_token_in_class == FALSE)
			EmitArrays::iname_entry(Hierarchy::find(VERB_DIRECTIVE_SLASH_HL));
	}

@<Jump to end of class@> =
	if (eog_reserved_label == NULL) {
		TEMPORARY_TEXT(L)
		WRITE_TO(L, ".class_%d_%d_end",
			kit->current_grammar_block, slash_equivalence_class);
		eog_reserved_label = EmitCode::reserve_label(L);
	}
	EmitCode::inv(JUMP_BIP);
	EmitCode::down();
		EmitCode::lab(eog_reserved_label);
	EmitCode::up();
