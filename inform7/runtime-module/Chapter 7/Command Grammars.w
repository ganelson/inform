[RTCommandGrammars::] Command Grammars.

Runtime support for CGs.

@

=
typedef struct cg_compilation_data {
	struct inter_name *cg_token_iname; /* |CG_IS_TOKEN| */
	struct inter_name *cg_parse_name_iname; /* |CG_IS_VALUE| */
	struct inter_name *cg_prn_iname; /* CG_IS_PROPERTY_NAME|: the relevant GPR is called this */
	struct inter_name *cg_consult_iname; /* for the consult parsing routine if needed */
	struct text_stream *cg_I6_identifier; /* when a token is delegated to an I6 routine */
} cg_compilation_data;

cg_compilation_data RTCommandGrammars::new_compilation_data(void) {
	cg_compilation_data cgcd;
	cgcd.cg_parse_name_iname = NULL;
	cgcd.cg_consult_iname = NULL;
	cgcd.cg_prn_iname = NULL;
	cgcd.cg_token_iname = NULL;
	cgcd.cg_I6_identifier = Str::new();
	return cgcd;
}

inter_name *RTCommandGrammars::i6_token_as_iname(command_grammar *cg) {
	if (Str::len(cg->compilation_data.cg_I6_identifier) > 0)
		return Produce::find_by_name(Emit::tree(), cg->compilation_data.cg_I6_identifier);
	if (cg->compilation_data.cg_token_iname == NULL) internal_error("no token GPR");
	return cg->compilation_data.cg_token_iname;
}

void RTCommandGrammars::new_CG_IS_PROPERTY_NAME(command_grammar *cg, property *prn) {
	cg->compilation_data.cg_prn_iname =
		Hierarchy::make_iname_in(EITHER_OR_GPR_FN_HL, RTProperties::package(prn));
}

void RTCommandGrammars::new_CG_IS_TOKEN(command_grammar *cg, wording W) {
	package_request *PR = Hierarchy::local_package(NAMED_TOKENS_HAP);
	cg->compilation_data.cg_token_iname = Hierarchy::make_iname_in(PARSE_LINE_FN_HL, PR);
}

void RTCommandGrammars::set_CG_IS_TOKEN_identifier(command_grammar *cg, wording W) {
	WRITE_TO(cg->compilation_data.cg_I6_identifier, "%N", Wordings::first_wn(W));
}

void RTCommandGrammars::create_no_verb_verb(command_grammar *cg) {
	inter_name *iname = Hierarchy::find(NO_VERB_VERB_DEFINED_HL);
	Emit::numeric_constant(iname, (inter_ti) 1);
	global_compilation_settings.no_verb_verb_exists = TRUE;
}

@h Phases III and IV: Sort and Compile Grammar.
At this highest level phases III and IV are intermingled, in that Phase III
always precedes Phase IV for any given list of grammar lines, but each CG
goes through both Phase III and IV before the next begins Phase III. So it
would not be appropriate to print banners like "Phase III begins here"
in the debugging log.

Finally, though, some substantive work to do: because it is the CG which
records the purpose of the grammar in question, we must compile a suitable
I6 context for the grammar to appear within.

Four of the five kinds of CG are compiled by the routine below: the fifth
kind is compiled in "Tokens Parsing Values", in response to different
|.i6t| commands, because the token routines are needed at a different position
in the final I6 output.

Sequence is important here: in particular the GPRs must exist before the
|Verb| directives, because otherwise I6 will throw not-declared-yet errors.

=
inter_name *VERB_DIRECTIVE_REVERSE_iname = NULL;
inter_name *VERB_DIRECTIVE_SLASH_iname = NULL;
inter_name *VERB_DIRECTIVE_DIVIDER_iname = NULL;
inter_name *VERB_DIRECTIVE_RESULT_iname = NULL;
inter_name *VERB_DIRECTIVE_SPECIAL_iname = NULL;
inter_name *VERB_DIRECTIVE_NUMBER_iname = NULL;
inter_name *VERB_DIRECTIVE_NOUN_iname = NULL;
inter_name *VERB_DIRECTIVE_MULTI_iname = NULL;
inter_name *VERB_DIRECTIVE_MULTIINSIDE_iname = NULL;
inter_name *VERB_DIRECTIVE_MULTIHELD_iname = NULL;
inter_name *VERB_DIRECTIVE_HELD_iname = NULL;
inter_name *VERB_DIRECTIVE_CREATURE_iname = NULL;
inter_name *VERB_DIRECTIVE_TOPIC_iname = NULL;
inter_name *VERB_DIRECTIVE_MULTIEXCEPT_iname = NULL;

void RTCommandGrammars::compile_generic_constants(void) {
	VERB_DIRECTIVE_REVERSE_iname = RTCommandGrammars::grammar_constant(VERB_DIRECTIVE_REVERSE_HL, 1);
	VERB_DIRECTIVE_SLASH_iname = RTCommandGrammars::grammar_constant(VERB_DIRECTIVE_SLASH_HL, 1);
	VERB_DIRECTIVE_DIVIDER_iname = RTCommandGrammars::grammar_constant(VERB_DIRECTIVE_DIVIDER_HL, 1);
	VERB_DIRECTIVE_RESULT_iname = RTCommandGrammars::grammar_constant(VERB_DIRECTIVE_RESULT_HL, 2);
	VERB_DIRECTIVE_SPECIAL_iname = RTCommandGrammars::grammar_constant(VERB_DIRECTIVE_SPECIAL_HL, 3);
	VERB_DIRECTIVE_NUMBER_iname = RTCommandGrammars::grammar_constant(VERB_DIRECTIVE_NUMBER_HL, 4);
	VERB_DIRECTIVE_NOUN_iname = RTCommandGrammars::grammar_constant(VERB_DIRECTIVE_NOUN_HL, 5);
	VERB_DIRECTIVE_MULTI_iname = RTCommandGrammars::grammar_constant(VERB_DIRECTIVE_MULTI_HL, 6);
	VERB_DIRECTIVE_MULTIINSIDE_iname = RTCommandGrammars::grammar_constant(VERB_DIRECTIVE_MULTIINSIDE_HL, 7);
	VERB_DIRECTIVE_MULTIHELD_iname = RTCommandGrammars::grammar_constant(VERB_DIRECTIVE_MULTIHELD_HL, 8);
	VERB_DIRECTIVE_HELD_iname = RTCommandGrammars::grammar_constant(VERB_DIRECTIVE_HELD_HL, 9);
	VERB_DIRECTIVE_CREATURE_iname = RTCommandGrammars::grammar_constant(VERB_DIRECTIVE_CREATURE_HL, 10);
	VERB_DIRECTIVE_TOPIC_iname = RTCommandGrammars::grammar_constant(VERB_DIRECTIVE_TOPIC_HL, 11);
	VERB_DIRECTIVE_MULTIEXCEPT_iname = RTCommandGrammars::grammar_constant(VERB_DIRECTIVE_MULTIEXCEPT_HL, 12);
}

inter_name *RTCommandGrammars::iname_for_I6_parser_token(cg_token *cgt) {
	switch (cgt->grammar_token_code) {
		case NOUN_TOKEN_GTC: return VERB_DIRECTIVE_NOUN_iname;
		case MULTI_TOKEN_GTC: return VERB_DIRECTIVE_MULTI_iname;
		case MULTIINSIDE_TOKEN_GTC: return VERB_DIRECTIVE_MULTIINSIDE_iname;
		case MULTIHELD_TOKEN_GTC: return VERB_DIRECTIVE_MULTIHELD_iname;
		case HELD_TOKEN_GTC: return VERB_DIRECTIVE_HELD_iname;
		case CREATURE_TOKEN_GTC: return VERB_DIRECTIVE_CREATURE_iname;
		case TOPIC_TOKEN_GTC: return VERB_DIRECTIVE_TOPIC_iname;
		case MULTIEXCEPT_TOKEN_GTC: return VERB_DIRECTIVE_MULTIEXCEPT_iname;
		default: internal_error("tried to find inter name for invalid GTC");
	}
	return NULL; /* to prevent a gcc error: never reached */
}

inter_name *RTCommandGrammars::grammar_constant(int N, int V) {
	inter_name *iname = Hierarchy::find(N);
	Emit::numeric_constant(iname, 1);
	Hierarchy::make_available(iname);
	return iname;
}

void RTCommandGrammars::compile_all(void) {
	command_grammar *cg;
	CommandGrammars::prepare();

	Log::new_stage(I"Sorting and compiling non-value grammar (G3, G4)");


	LOOP_OVER(cg, command_grammar)
		if (cg->cg_is == CG_IS_TOKEN)
			RTCommandGrammars::compile(cg); /* makes GPRs for designed tokens */

	LOOP_OVER(cg, command_grammar)
		if (cg->cg_is == CG_IS_COMMAND)
			RTCommandGrammars::compile(cg); /* makes |Verb| directives */

	LOOP_OVER(cg, command_grammar)
		if (cg->cg_is == CG_IS_SUBJECT)
			RTCommandGrammars::compile(cg); /* makes routines for use in |parse_name| */

	LOOP_OVER(cg, command_grammar)
		if (cg->cg_is == CG_IS_CONSULT)
			RTCommandGrammars::compile(cg); /* routines to parse snippets, used as values */

	LOOP_OVER(cg, command_grammar)
		if (cg->cg_is == CG_IS_PROPERTY_NAME)
			RTCommandGrammars::compile(cg); /* makes routines for use in |parse_name| */

	RTCommandGrammarLines::compile_slash_gprs();
}

@ Some tokens require suitable I6 routines to have already been compiled,
if they are to work nicely: the following routine goes through the tokens
by exploring each CG in turn.

=
void RTCommandGrammars::compile_conditions(void) {
	command_grammar *cg;
	LOOP_OVER(cg, command_grammar)	{
		current_sentence = cg->where_cg_created;
		LOOP_THROUGH_UNSORTED_CG_LINES(cgl, cg) {
			RTCommandGrammarLines::cgl_compile_condition_token_as_needed(cgl);
			RTCommandGrammarLines::cgl_compile_mistake_token_as_needed(cgl);
		}
	}
}

@ Command CGs are destined to be compiled into |Verb| directives, as follows.

=
packaging_state RTCommandGrammars::cg_compile_Verb_directive_header(command_grammar *cg, inter_name *array_iname) {
	if (cg->cg_is != CG_IS_COMMAND)
		internal_error("tried to compile Verb from non-command CG");
	if (CGLines::list_length(cg) == 0)
		internal_error("compiling Verb for empty grammar");

	packaging_state save = EmitArrays::begin_late_verb(array_iname, K_value);

	if (Wordings::empty(cg->command))
		EmitArrays::dword_entry(I"no.verb");
	else {
		TEMPORARY_TEXT(WD)
		WRITE_TO(WD, "%N", Wordings::first_wn(cg->command));
		EmitArrays::dword_entry(WD);
		DISCARD_TEXT(WD)
		for (int i=0; i<cg->no_aliased_commands; i++) {
			TEMPORARY_TEXT(WD)
			WRITE_TO(WD, "%N", Wordings::first_wn(cg->aliased_command[i]));
			EmitArrays::dword_entry(WD);
			DISCARD_TEXT(WD)
		}
	}
	return save;
}

@ The special thing about |CG_IS_SUBJECT| grammars is that each is attached
to an inference subject, and when we compile them we recurse up the subject
hierarchy: thus if the red ball is of kind ball which is of kind thing,
then the |parse_name| for the red ball consists of grammar lines specified
for the red ball, then those specified for all balls, and lastly those
specified for all things. (This mimics I6 class-to-instance inheritance.)

=
void RTCommandGrammars::cg_compile_parse_name_lines(gpr_kit *gprk, command_grammar *cg) {
	inference_subject *subj = cg->subj_understood;

	if (PARSING_DATA_FOR_SUBJ(subj)->understand_as_this_subject != cg)
		internal_error("link between subject and CG broken");

	LOGIF(GRAMMAR, "Parse_name content for $j:\n", subj);
	RTCommandGrammars::cg_compile_lines(gprk, PARSING_DATA_FOR_SUBJ(subj)->understand_as_this_subject);

	inference_subject *infs;
	for (infs = InferenceSubjects::narrowest_broader_subject(subj);
		infs; infs = InferenceSubjects::narrowest_broader_subject(infs)) {
		if (PARSING_DATA_FOR_SUBJ(infs))
			if (PARSING_DATA_FOR_SUBJ(infs)->understand_as_this_subject) {
				LOGIF(GRAMMAR, "And parse_name content inherited from $j:\n", infs);
				RTCommandGrammars::cg_compile_lines(gprk, PARSING_DATA_FOR_SUBJ(infs)->understand_as_this_subject);
			}
	}
}

@ All other grammars are compiled just as they are:

=
void RTCommandGrammars::cg_compile_lines(gpr_kit *gprk, command_grammar *cg) {
	CommandsIndex::list_assert_ownership(cg); /* Mark for later indexing */
	CommandGrammars::sort_command_grammar(cg); /* Phase III for the CGLs in the CG happens here */
	RTCommandGrammarLines::sorted_line_list_compile(gprk,
		cg->cg_is, cg, CommandGrammars::cg_is_genuinely_verbal(cg)); /* And Phase IV here */
}

@ The following function unites, so far as possible, the different forms of
CG by compiling each of them as a sandwich: top slice, filling, bottom slice.

The interesting case is of a CG representing names for an object: the
name-behaviour needs to be inherited from the object's kind, and so on up
the kinds hierarchy, but this is a case where I7's kind hierarchy does not
agree with I6's class hierarchy. I6 has no (nice) way to inherit |parse_name|
behaviour from a class to an instance. So we will simply pile up extra
fillings into the sandwich. The order of these is important: by getting
in first, grammar for the instance takes priority; its immediate kind has
next priority, and so on up the hierarchy.

=
void RTCommandGrammars::compile(command_grammar *cg) {
	if (CGLines::list_length(cg) == 0) return;

	LOGIF(GRAMMAR, "Compiling command grammar $G\n", cg);

	current_sentence = cg->where_cg_created;

	RTCommandGrammarLines::reset_labels();
	switch(cg->cg_is) {
		case CG_IS_COMMAND: {
			package_request *PR = Hierarchy::completion_package(COMMANDS_HAP);
			inter_name *array_iname = Hierarchy::make_iname_in(VERB_DECLARATION_ARRAY_HL, PR);
			packaging_state save = RTCommandGrammars::cg_compile_Verb_directive_header(cg, array_iname);
			RTCommandGrammars::cg_compile_lines(NULL, cg);
			EmitArrays::end(save);
			break;
		}
		case CG_IS_TOKEN: {
			gpr_kit gprk = GPRs::new_kit();
			if (cg->compilation_data.cg_token_iname == NULL) internal_error("cg token not ready");
			packaging_state save = Functions::begin(cg->compilation_data.cg_token_iname);
			GPRs::add_original_var(&gprk);
			GPRs::add_standard_vars(&gprk);
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, gprk.original_wn_s);
				EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
			EmitCode::up();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, gprk.rv_s);
				EmitCode::val_iname(K_value, Hierarchy::find(GPR_PREPOSITION_HL));
			EmitCode::up();
			RTCommandGrammars::cg_compile_lines(&gprk, cg);
			EmitCode::inv(RETURN_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_value, Hierarchy::find(GPR_FAIL_HL));
			EmitCode::up();
			Functions::end(save);
			break;
		}
		case CG_IS_CONSULT: {
			gpr_kit gprk = GPRs::new_kit();
			inter_name *iname = RTCommandGrammars::consult_iname(cg);
			packaging_state save = Functions::begin(iname);
			GPRs::add_range_vars(&gprk);
			GPRs::add_original_var(&gprk);
			GPRs::add_standard_vars(&gprk);
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
				EmitCode::val_symbol(K_value, gprk.range_from_s);
			EmitCode::up();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, gprk.original_wn_s);
				EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
			EmitCode::up();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, gprk.rv_s);
				EmitCode::val_iname(K_value, Hierarchy::find(GPR_PREPOSITION_HL));
			EmitCode::up();
			RTCommandGrammars::cg_compile_lines(&gprk, cg);
			EmitCode::inv(RETURN_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_value, Hierarchy::find(GPR_FAIL_HL));
			EmitCode::up();
			Functions::end(save);
			break;
		}
		case CG_IS_SUBJECT:
			break;
		case CG_IS_VALUE:
			internal_error("iv");
			break;
		case CG_IS_PROPERTY_NAME: {
			gpr_kit gprk = GPRs::new_kit();
			if (cg->compilation_data.cg_prn_iname == NULL) internal_error("PRN PN not ready");
			packaging_state save = Functions::begin(cg->compilation_data.cg_prn_iname);
			GPRs::add_original_var(&gprk);
			GPRs::add_standard_vars(&gprk);
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, gprk.original_wn_s);
				EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
			EmitCode::up();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, gprk.rv_s);
				EmitCode::val_iname(K_value, Hierarchy::find(GPR_PREPOSITION_HL));
			EmitCode::up();
			RTCommandGrammars::cg_compile_lines(&gprk, cg);
			EmitCode::inv(RETURN_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_value, Hierarchy::find(GPR_FAIL_HL));
			EmitCode::up();
			Functions::end(save);
			break;
		}
	}
}

void RTCommandGrammars::compile_iv(gpr_kit *gprk, command_grammar *cg) {
	if (CGLines::list_length(cg) > 0) {
		LOGIF(GRAMMAR, "Compiling command grammar $G\n", cg);
		current_sentence = cg->where_cg_created;
		RTCommandGrammarLines::reset_labels();
		if (cg->cg_is != CG_IS_VALUE) internal_error("not iv");
		RTCommandGrammars::cg_compile_lines(gprk, cg);
	}
}

void RTCommandGrammars::emit_determination_type(determination_type *gty) {
	CompileValues::to_code_val(gty->term[0].what);
}

@ These are used to parse an explicit range of words (such as traditionally
found in the CONSULT command) at run time, and they are not I6 grammar
tokens, and do not appear in |Verb| declarations: otherwise, such
routines are very similar to GPRs.

First, we need to look after a pointer to the CG used to hold the grammar
being matched against the snippet of words.

=
inter_name *RTCommandGrammars::consult_iname(command_grammar *cg) {
	if (cg == NULL) return NULL;
	if (cg->compilation_data.cg_consult_iname == NULL) {
		current_sentence = cg->where_cg_created;
		package_request *PR = Hierarchy::local_package(CONSULT_TOKENS_HAP);
		cg->compilation_data.cg_consult_iname = Hierarchy::make_iname_in(CONSULT_FN_HL, PR);
	}
	return cg->compilation_data.cg_consult_iname;
}
