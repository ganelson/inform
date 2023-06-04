[RTCommandGrammars::] Command Grammars.

Runtime support for CGs.

@h Generic constants.
Here, |REPARSE_CODE| is a magic value used in //CommandParserKit// to
signal that some code which ought to have been parsing a command has in
fact rewritten it, so that the whole command must be re-parsed afresh.

=
void RTCommandGrammars::compile_generic_constants(void) {
	target_vm *VM = Task::vm();
	if (TargetVMs::is_16_bit(VM)) {
		RTCommandGrammars::grammar_constant(REPARSE_CODE_HL, 10000);
	} else {
		RTCommandGrammars::grammar_constant(REPARSE_CODE_HL, 0x40000000);
	}
	RTCommandGrammars::grammar_constant(VERB_DIRECTIVE_META_HL, 1);
	RTCommandGrammars::grammar_constant(VERB_DIRECTIVE_NOUN_FILTER_HL, 1);
	RTCommandGrammars::grammar_constant(VERB_DIRECTIVE_SCOPE_FILTER_HL, 1);
	RTCommandGrammars::grammar_constant(VERB_DIRECTIVE_REVERSE_HL, 1);
	RTCommandGrammars::grammar_constant(VERB_DIRECTIVE_SLASH_HL, 1);
	RTCommandGrammars::grammar_constant(VERB_DIRECTIVE_DIVIDER_HL, 1);
	RTCommandGrammars::grammar_constant(VERB_DIRECTIVE_RESULT_HL, 2);
	RTCommandGrammars::grammar_constant(VERB_DIRECTIVE_SPECIAL_HL, 3);
	RTCommandGrammars::grammar_constant(VERB_DIRECTIVE_NUMBER_HL, 4);
	RTCommandGrammars::grammar_constant(VERB_DIRECTIVE_NOUN_HL, 5);
	RTCommandGrammars::grammar_constant(VERB_DIRECTIVE_MULTI_HL, 6);
	RTCommandGrammars::grammar_constant(VERB_DIRECTIVE_MULTIINSIDE_HL, 7);
	RTCommandGrammars::grammar_constant(VERB_DIRECTIVE_MULTIHELD_HL, 8);
	RTCommandGrammars::grammar_constant(VERB_DIRECTIVE_HELD_HL, 9);
	RTCommandGrammars::grammar_constant(VERB_DIRECTIVE_CREATURE_HL, 10);
	RTCommandGrammars::grammar_constant(VERB_DIRECTIVE_TOPIC_HL, 11);
	RTCommandGrammars::grammar_constant(VERB_DIRECTIVE_MULTIEXCEPT_HL, 12);
}

@ This one is compiled later, since it depends (potentially) on a use option:

=
void RTCommandGrammars::compile_non_generic_constants(void) {
	RTCommandGrammars::grammar_constant(DICT_WORD_SIZE_HL,
		global_compilation_settings.dictionary_resolution);
	if (TargetVMs::is_16_bit(Task::vm()))
		RTCommandGrammars::grammar_constant(DICT_ENTRY_BYTES_HL, 8);
}

@

=
inter_name *RTCommandGrammars::iname_for_I6_parser_token(cg_token *cgt) {
	switch (cgt->grammar_token_code) {
		case NOUN_TOKEN_GTC:        return Hierarchy::find(VERB_DIRECTIVE_NOUN_HL);
		case MULTI_TOKEN_GTC:       return Hierarchy::find(VERB_DIRECTIVE_MULTI_HL);
		case MULTIINSIDE_TOKEN_GTC: return Hierarchy::find(VERB_DIRECTIVE_MULTIINSIDE_HL);
		case MULTIHELD_TOKEN_GTC:   return Hierarchy::find(VERB_DIRECTIVE_MULTIHELD_HL);
		case HELD_TOKEN_GTC:        return Hierarchy::find(VERB_DIRECTIVE_HELD_HL);
		case CREATURE_TOKEN_GTC:    return Hierarchy::find(VERB_DIRECTIVE_CREATURE_HL);
		case TOPIC_TOKEN_GTC:       return Hierarchy::find(VERB_DIRECTIVE_TOPIC_HL);
		case MULTIEXCEPT_TOKEN_GTC: return Hierarchy::find(VERB_DIRECTIVE_MULTIEXCEPT_HL);
		default: internal_error("tried to find inter name for invalid GTC");
	}
	return NULL; /* to prevent a compiler error: never reached */
}

inter_name *RTCommandGrammars::grammar_constant(int N, int V) {
	inter_name *iname = Hierarchy::find(N);
	Emit::numeric_constant(iname, (inter_ti) V);
	Hierarchy::make_available(iname);
	return iname;
}

@h Compilation data.
Each |command_grammar| object contains this data:

=
typedef struct cg_compilation_data {
	struct package_request *cg_package;

	struct inter_name *cg_token_iname; /* |CG_IS_TOKEN| */

	struct inter_name *property_GPR_fn_iname; /* CG_IS_PROPERTY_NAME| */
	struct text_stream *CG_IS_TOKEN_identifier; /* CG_IS_PROPERTY_NAME| */

	struct inter_name *consult_fn_iname; /* CG_IS_CONSULT| */
} cg_compilation_data;

cg_compilation_data RTCommandGrammars::new_compilation_data(command_grammar *cg) {
	cg_compilation_data cgcd;
	cgcd.cg_package = NULL;
	cgcd.consult_fn_iname = NULL;
	cgcd.property_GPR_fn_iname = NULL;
	cgcd.cg_token_iname = NULL;
	cgcd.CG_IS_TOKEN_identifier = Str::new();
	return cgcd;
}

@ In fact, however, only four of the six CG types live in their own packages,
so the following is not used for |CG_IS_VALUE| or |CG_IS_SUBJECT| grammars.

=
package_request *RTCommandGrammars::package(command_grammar *cg) {
	if (cg->compilation_data.cg_package == NULL)
		cg->compilation_data.cg_package =
			Hierarchy::completion_package(COMMAND_GRAMMARS_HAP);
	return cg->compilation_data.cg_package;
}

@ |CG_IS_PROPERTY_NAME| packages contain a function to match the value of
that property:

=
inter_name *RTCommandGrammars::get_property_GPR_fn_iname(command_grammar *cg) {
	if ((cg == NULL) || (cg->cg_is != CG_IS_PROPERTY_NAME))
		internal_error("prn_iname unavailable");
	if (cg->compilation_data.property_GPR_fn_iname == NULL)
		cg->compilation_data.property_GPR_fn_iname =
			Hierarchy::make_iname_in(PROPERTY_GPR_FN_HL,
				RTCommandGrammars::package(cg));
	return cg->compilation_data.property_GPR_fn_iname;
}

@ |CG_IS_TOKEN| packages contain a function to match that token. Note that these
can be translated in order to have a particular identifier.

=
inter_name *RTCommandGrammars::get_cg_token_iname(command_grammar *cg) {
	if ((cg == NULL) || (cg->cg_is != CG_IS_TOKEN))
		internal_error("cg_token_iname unavailable");
	if (cg->compilation_data.cg_token_iname == NULL) {
		if (Str::len(cg->compilation_data.CG_IS_TOKEN_identifier) > 0)
			cg->compilation_data.cg_token_iname =
				HierarchyLocations::find_by_name(Emit::tree(),
					cg->compilation_data.CG_IS_TOKEN_identifier);
		else
			cg->compilation_data.cg_token_iname =
				Hierarchy::make_iname_in(PARSE_LINE_FN_HL,
					RTCommandGrammars::package(cg));
	}
	return cg->compilation_data.cg_token_iname;
}

void RTCommandGrammars::set_CG_IS_TOKEN_identifier(command_grammar *cg, wording W) {
	if (cg->compilation_data.cg_token_iname) internal_error("too late to translate");
	WRITE_TO(cg->compilation_data.CG_IS_TOKEN_identifier, "%N", Wordings::first_wn(W));
}

@ |CG_IS_CONSULT| packages contain a function which matches a snippet:

=
inter_name *RTCommandGrammars::get_consult_fn_iname(command_grammar *cg) {
	if ((cg == NULL) || (cg->cg_is != CG_IS_CONSULT))
		internal_error("cg_token_iname unavailable");
	if (cg->compilation_data.consult_fn_iname == NULL)
		cg->compilation_data.consult_fn_iname =
			Hierarchy::make_iname_in(CONSULT_FN_HL, RTCommandGrammars::package(cg));
	return cg->compilation_data.consult_fn_iname;
}

@h Queued compilation.
As noted above, not all types of command grammar have their own packages. For
those which do, we queue compilation requests with suitable agents.

=
void RTCommandGrammars::compile_all(void) {
	command_grammar *cg;

	LOOP_OVER(cg, command_grammar)
		if (cg->cg_is == CG_IS_TOKEN) {
			text_stream *desc = Str::new();
			WRITE_TO(desc, "command grammar for token");
			Sequence::queue_at(&RTCommandGrammars::token_agent,
				STORE_POINTER_command_grammar(cg), desc, cg->where_cg_created);
		}

	LOOP_OVER(cg, command_grammar)
		if (cg->cg_is == CG_IS_COMMAND) {
			text_stream *desc = Str::new();
			WRITE_TO(desc, "command grammar for command '%W'", cg->command);
			Sequence::queue_at(&RTCommandGrammars::command_agent,
				STORE_POINTER_command_grammar(cg), desc, cg->where_cg_created);
		}

	LOOP_OVER(cg, command_grammar)
		if (cg->cg_is == CG_IS_CONSULT) {
			text_stream *desc = Str::new();
			WRITE_TO(desc, "command grammar for consult at '%W'",
				Node::get_text(cg->where_cg_created));
			Sequence::queue_at(&RTCommandGrammars::consult_agent,
				STORE_POINTER_command_grammar(cg), desc, cg->where_cg_created);
		}

	LOOP_OVER(cg, command_grammar)
		if (cg->cg_is == CG_IS_PROPERTY_NAME) {
			text_stream *desc = Str::new();
			WRITE_TO(desc, "command grammar for property '%W'",
				cg->prn_understood->name);
			Sequence::queue_at(&RTCommandGrammars::property_agent,
				STORE_POINTER_command_grammar(cg), desc, cg->where_cg_created);
		}
}

@h Compiling CG_IS_TOKEN grammars.

=
void RTCommandGrammars::token_agent(compilation_subtask *t) {
	command_grammar *cg = RETRIEVE_POINTER_command_grammar(t->data);
	if (CGLines::list_length(cg) == 0) return;
	LOGIF(GRAMMAR, "Compiling command grammar $G\n", cg);

	gpr_kit kit = GPRs::new_kit();
	inter_name *iname = RTCommandGrammars::get_cg_token_iname(cg);
	packaging_state save = Functions::begin(iname);
	GPRs::add_original_var(&kit);
	GPRs::add_standard_vars(&kit);
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, kit.original_wn_s);
		EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
	EmitCode::up();
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, kit.rv_s);
		EmitCode::val_iname(K_value, Hierarchy::find(GPR_PREPOSITION_HL));
	EmitCode::up();
	RTCommandGrammars::compile_general(&kit, cg);
	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
		EmitCode::val_iname(K_value, Hierarchy::find(GPR_FAIL_HL));
	EmitCode::up();
	Functions::end(save);
}

@h Compiling CG_IS_COMMAND grammars.

=
void RTCommandGrammars::command_agent(compilation_subtask *t) {
	command_grammar *cg = RETRIEVE_POINTER_command_grammar(t->data);
	if (CGLines::list_length(cg) == 0) return;
	LOGIF(GRAMMAR, "Compiling command grammar $G\n", cg);

	package_request *PR = Hierarchy::completion_package(COMMANDS_HAP);
	inter_name *array_iname = Hierarchy::make_iname_in(VERB_DECLARATION_ARRAY_HL, PR);
	packaging_state save = EmitArrays::begin_verb(array_iname, K_value);
	if (Wordings::empty(cg->command)) {
		EmitArrays::dword_entry(I"no.verb");
	} else {
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
	RTCommandGrammars::compile_general(NULL, cg);
	EmitArrays::end(save);

	if (Wordings::empty(cg->command)) {
		Emit::numeric_constant(Hierarchy::make_iname_in(NO_VERB_VERB_DEFINED_HL, PR),
			(inter_ti) 1);
	}
}

@h Compiling CG_IS_CONSULT grammars.

=
void RTCommandGrammars::consult_agent(compilation_subtask *t) {
	command_grammar *cg = RETRIEVE_POINTER_command_grammar(t->data);
	if (CGLines::list_length(cg) == 0) return;
	LOGIF(GRAMMAR, "Compiling command grammar $G\n", cg);

	gpr_kit kit = GPRs::new_kit();
	inter_name *iname = RTCommandGrammars::get_consult_fn_iname(cg);
	packaging_state save = Functions::begin(iname);
	GPRs::add_range_vars(&kit);
	GPRs::add_original_var(&kit);
	GPRs::add_standard_vars(&kit);
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
		EmitCode::val_symbol(K_value, kit.range_from_s);
	EmitCode::up();
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, kit.original_wn_s);
		EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
	EmitCode::up();
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, kit.rv_s);
		EmitCode::val_iname(K_value, Hierarchy::find(GPR_PREPOSITION_HL));
	EmitCode::up();
	RTCommandGrammars::compile_general(&kit, cg);
	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
		EmitCode::val_iname(K_value, Hierarchy::find(GPR_FAIL_HL));
	EmitCode::up();
	Functions::end(save);
}

@h Compiling CG_IS_PROPERTY grammars.

=
void RTCommandGrammars::property_agent(compilation_subtask *t) {
	command_grammar *cg = RETRIEVE_POINTER_command_grammar(t->data);
	if (CGLines::list_length(cg) == 0) return;
	LOGIF(GRAMMAR, "Compiling command grammar $G\n", cg);

	gpr_kit kit = GPRs::new_kit();
	inter_name *iname = RTCommandGrammars::get_property_GPR_fn_iname(cg);
	packaging_state save = Functions::begin(iname);
	GPRs::add_original_var(&kit);
	GPRs::add_standard_vars(&kit);
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, kit.original_wn_s);
		EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
	EmitCode::up();
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, kit.rv_s);
		EmitCode::val_iname(K_value, Hierarchy::find(GPR_PREPOSITION_HL));
	EmitCode::up();
	RTCommandGrammars::compile_general(&kit, cg);
	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
		EmitCode::val_iname(K_value, Hierarchy::find(GPR_FAIL_HL));
	EmitCode::up();
	Functions::end(save);
}

@h Compiling CG_IS_VALUE grammars.
These are not compiled into their own packages, but into the body of GPRs
to parse values of given kinds. So the following assumes that we are already
in the middle of a GPR being compiled.

=
void RTCommandGrammars::compile_for_value_GPR(gpr_kit *kit, command_grammar *cg) {
	if (cg->cg_is != CG_IS_VALUE) internal_error("not CG_IS_VALUE");

	if (CGLines::list_length(cg) > 0) {
		LOGIF(GRAMMAR, "Compiling command grammar $G\n", cg);
		current_sentence = cg->where_cg_created;
		RTCommandGrammars::compile_general(kit, cg);
	}
}

@h Compiling CG_IS_SUBJECT grammars.
Again, these are not compiled into their own packages, but into the body of
GPRs: in fact, they will be functions used as |parse_name| property values.

Each CG_IS_SUBJECT grammar is attached to an inference subject, and when we
compile them we recurse up the subject hierarchy: thus if the red ball is of
kind ball which is of kind thing, then the |parse_name| for the red ball
consists of grammar lines specified for the red ball, then those specified for
all balls, and lastly those specified for all things.

The order of these is important: by getting in first, grammar for the instance
takes priority; its immediate kind has next priority, and so on up the
hierarchy.

=
void RTCommandGrammars::compile_for_subject_GPR(gpr_kit *kit, command_grammar *cg) {
	if (cg->cg_is != CG_IS_SUBJECT) internal_error("not CG_IS_SUBJECT");
	inference_subject *subj = cg->subj_understood;
	if (PARSING_DATA_FOR_SUBJ(subj)->understand_as_this_subject != cg)
		internal_error("link between subject and CG broken");

	LOGIF(GRAMMAR, "Parse_name content for $j:\n", subj);
	RTCommandGrammars::compile_general(kit,
		PARSING_DATA_FOR_SUBJ(subj)->understand_as_this_subject);

	inference_subject *infs;
	for (infs = InferenceSubjects::narrowest_broader_subject(subj);
		infs; infs = InferenceSubjects::narrowest_broader_subject(infs)) {
		if (PARSING_DATA_FOR_SUBJ(infs))
			if (PARSING_DATA_FOR_SUBJ(infs)->understand_as_this_subject) {
				LOGIF(GRAMMAR, "And parse_name content inherited from $j:\n", infs);
				RTCommandGrammars::compile_general(kit,
					PARSING_DATA_FOR_SUBJ(infs)->understand_as_this_subject);
			}
	}
}

@h Compiling all grammars.
And so all of the above functions ultimately funnel down to this one.

At this level we compile the list of CGLs in sorted order: this is what the
sorting was all for. In certain cases, we skip any CGLs marked as "one word":
these are cases arising from, e.g., "Understand "frog" as the toad.",
where we noticed that the CGL was a single word and included it in the |name|
property instead. This is faster and more flexible, besides writing tidier
code.

The need for this is not immediately obvious. After all, shouldn't we have
simply deleted the CGL in the first place, rather than leaving it in but
marking it? The answer is no, because of the way inheritance works differently
for the |name| property as opposed to |parse_name| functions.

=
void RTCommandGrammars::compile_general(gpr_kit *kit, command_grammar *cg) {
	RTCommandGrammarLines::list_assert_ownership(cg);
	CommandGrammars::sort_command_grammar(cg);
	
	LOG_INDENT;
	LOOP_THROUGH_SORTED_CG_LINES(cgl, cg)
		if (cgl->compilation_data.suppress_compilation == FALSE)
			RTCommandGrammarLines::compile_cg_line(kit, cgl, cg->cg_is,
				CommandGrammars::cg_is_genuinely_verbal(cg));
	LOG_OUTDENT;
	
	package_request *pack = RTCommandGrammars::package(cg);
	int hl = -1;
	if (cg->cg_is == CG_IS_COMMAND) hl = CG_IS_COMMAND_MD_HL;
	if (cg->cg_is == CG_IS_TOKEN) hl = CG_IS_TOKEN_MD_HL;
	if (cg->cg_is == CG_IS_SUBJECT) hl = CG_IS_SUBJECT_MD_HL;
	if (cg->cg_is == CG_IS_VALUE) hl = CG_IS_VALUE_MD_HL;
	if (cg->cg_is == CG_IS_CONSULT) hl = CG_IS_CONSULT_MD_HL;
	if (cg->cg_is == CG_IS_PROPERTY_NAME) hl = CG_IS_PROPERTY_NAME_MD_HL;
	if (hl >= 0) Hierarchy::apply_metadata_from_number(pack, hl, 1);	
	Hierarchy::apply_metadata_from_number(pack, CG_AT_MD_HL,
		(inter_ti) Wordings::first_wn(Node::get_text(cg->where_cg_created)));
	if (cg->cg_is == CG_IS_TOKEN)
		Hierarchy::apply_metadata_from_raw_wording(pack, CG_NAME_MD_HL, cg->token_name);
	if (cg->cg_is == CG_IS_COMMAND) {
		if (Wordings::nonempty(cg->command))
			Hierarchy::apply_metadata_from_wording(pack, CG_COMMAND_MD_HL, cg->command);
		for (int i=0; i<cg->no_aliased_commands; i++) {
			package_request *alias = Hierarchy::package_within(CG_COMMAND_ALIASES_HAP, pack);
			Hierarchy::apply_metadata_from_wording(alias, CG_ALIAS_MD_HL, cg->aliased_command[i]);
		}
	}
	LOOP_THROUGH_SORTED_CG_LINES(cgl, cg)
		if (cgl->compilation_data.belongs_to_cg) {
			package_request *line = Hierarchy::package_within(CG_LINES_HAP, pack);
			cgl->compilation_data.metadata_package = line;
			cgl->compilation_data.xref_iname =
				Hierarchy::make_iname_in(CG_XREF_SYMBOL_HL, line);
			Emit::numeric_constant(cgl->compilation_data.xref_iname, 561);
			
			if (cgl->resulting_action) {
				package_request *R = Hierarchy::package_within(CG_LINES_PRODUCING_HAP,
					RTActions::package(cgl->resulting_action));
				Hierarchy::apply_metadata_from_iname(R, CG_LINE_PRODUCING_MD_HL,
					cgl->compilation_data.xref_iname);
			}

			wording VW = CommandGrammars::get_verb_text(cgl->compilation_data.belongs_to_cg);
			if (cgl->resulting_action)
				Hierarchy::apply_metadata_from_iname(line, CG_ACTION_MD_HL,
					RTActions::double_sharp(cgl->resulting_action));
			if (Wordings::nonempty(VW))
				Hierarchy::apply_metadata_from_wording(line, CG_TRUE_VERB_MD_HL, VW);
			TEMPORARY_TEXT(text)
			WRITE_TO(text, "%w", Lexer::word_text(cgl->original_text));
			Hierarchy::apply_metadata(line, CG_LINE_TEXT_MD_HL, text);
			DISCARD_TEXT(text)
			Hierarchy::apply_metadata_from_number(line, CG_LINE_AT_MD_HL,
				(inter_ti) cgl->original_text);
			if (cgl->reversed) 
				Hierarchy::apply_metadata_from_number(line, CG_LINE_REVERSED_MD_HL, 1);
		}
}
