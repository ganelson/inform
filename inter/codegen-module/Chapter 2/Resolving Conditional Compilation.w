[CodeGen::RCC::] Resolving Conditional Compilation.

To generate the initial state of storage for variables.

@h Pipeline stage.

=
void CodeGen::RCC::create_pipeline_stage(void) {
	CodeGen::Stage::new(I"resolve-conditional-compilation", CodeGen::RCC::run_pipeline_stage, NO_STAGE_ARG, FALSE);
}

int CodeGen::RCC::run_pipeline_stage(pipeline_step *step) {
	CodeGen::RCC::resolve(step->repository);
	return TRUE;
}

@h Resolution.

@d MAX_CC_STACK_SIZE 32

=
typedef struct rcc_state {
	struct dictionary *I6_level_symbols;
	int cc_stack[MAX_CC_STACK_SIZE];
	int cc_sp;
} rcc_state;

void CodeGen::RCC::resolve(inter_repository *I) {
	rcc_state state;
	state.I6_level_symbols = Dictionaries::new(1024, TRUE);
	state.cc_sp = 0;
	Inter::traverse_tree(I, CodeGen::RCC::visitor, &state, NULL, 0);
	if (state.cc_sp != 0)
		TemplateReader::error("conditional compilation is wrongly structured in the template: not enough #endif", NULL);
}

void CodeGen::RCC::visitor(inter_repository *I, inter_frame P, void *v_state) {
	rcc_state *state = (rcc_state *) v_state;
	int allow = TRUE;
	for (int i=0; i<state->cc_sp; i++) if (state->cc_stack[i] == FALSE) allow = FALSE;
	inter_package *outer = Inter::Packages::container(P);
	if ((outer == NULL) || (Inter::Packages::is_codelike(outer) == FALSE)) {
		if (P.data[ID_IFLD] == SPLAT_IST) {
			text_stream *S = Inter::get_text(P.repo_segment->owning_repo, P.data[MATTER_SPLAT_IFLD]);
			switch (P.data[PLM_SPLAT_IFLD]) {
				case CONSTANT_PLM:
				case GLOBAL_PLM:
				case ARRAY_PLM:
				case ROUTINE_PLM:
				case DEFAULT_PLM:
				case STUB_PLM:
					if (allow) @<Symbol definition@>;
					break;
				case IFDEF_PLM: @<Deal with an IFDEF@>; break;
				case IFNDEF_PLM: @<Deal with an IFNDEF@>; break;
				case IFTRUE_PLM: @<Deal with an IFTRUE@>; break;
				case IFNOT_PLM: @<Deal with an IFNOT@>; break;
				case ENDIF_PLM: @<Deal with an ENDIF@>; break;
			}
		}
	}
	if (allow == FALSE) Inter::Frame::remove_from_tree(P);
}

@<Extract second token into ident@> =
	int tcount = 0;
	LOOP_THROUGH_TEXT(pos, S) {
		wchar_t c = Str::get(pos);
		if ((c == ' ') || (c == '\t') || (c == '\n')) {
			if (tcount == 1) tcount = 2;
			else if (tcount == 2) break;
		} else {
			if (tcount == 0) tcount = 1;
			if ((c == ';') || (c == '-')) break;
			if (tcount == 2) PUT_TO(ident, c);
		}
	}

@<Extract rest of text into ident@> =
	int tcount = 0;
	LOOP_THROUGH_TEXT(pos, S) {
		wchar_t c = Str::get(pos);
		if ((c == ' ') || (c == '\t') || (c == '\n')) {
			if (tcount == 1) tcount = 2;
		} else {
			if (tcount == 0) tcount = 1;
			if ((c == ';') || (c == '-')) break;
			if (tcount == 2) PUT_TO(ident, c);
		}
	}

@<Symbol definition@> =
	TEMPORARY_TEXT(ident);
	@<Extract second token into ident@>;
	LOGIF(RESOLVING_CONDITIONAL_COMPILATION, "I6 defines %S here\n", ident);
	Dictionaries::create(state->I6_level_symbols, ident);
	DISCARD_TEXT(ident);

@<Deal with an IFDEF@> =
	TEMPORARY_TEXT(ident);
	@<Extract rest of text into ident@>;
	int result = FALSE;
	text_stream *symbol_name = ident;
	@<Decide whether symbol defined@>;
	@<Stack up the result@>;
	allow = FALSE;
	DISCARD_TEXT(ident);

@<Deal with an IFNDEF@> =
	TEMPORARY_TEXT(ident);
	@<Extract rest of text into ident@>;
	int result = FALSE;
	text_stream *symbol_name = ident;
	@<Decide whether symbol defined@>;
	result = (result)?FALSE:TRUE;
	@<Stack up the result@>;
	allow = FALSE;
	DISCARD_TEXT(ident);

@<Decide whether symbol defined@> =
	inter_symbol *symbol = Inter::SymbolsTables::symbol_from_name_in_main_or_basics(I, symbol_name);
	if (symbol) {
		result = TRUE;
		if (Inter::Symbols::is_extern(symbol)) result = FALSE;
	} else if (Dictionaries::find(state->I6_level_symbols, symbol_name)) result = TRUE;
	LOGIF(RESOLVING_CONDITIONAL_COMPILATION, "Must decide if %S defined: %s\n", symbol_name, (result)?"yes":"no");
	if (Log::aspect_switched_on(RESOLVING_CONDITIONAL_COMPILATION_DA)) LOG_INDENT;

@<Deal with an IFTRUE@> =
	TEMPORARY_TEXT(ident);
	@<Extract rest of text into ident@>;
	int result = NOT_APPLICABLE;
	text_stream *cond = ident;
	match_results mr2 = Regexp::create_mr();
	if (Regexp::match(&mr2, cond, L" *(%C+?) *== *(%d+) *")) {
		text_stream *identifier = mr2.exp[0];
		inter_symbol *symbol = Inter::SymbolsTables::symbol_from_name_in_main_or_basics(I, identifier);
		if (symbol) {
			inter_frame P = Inter::Symbols::defining_frame(symbol);
			if ((Inter::Frame::valid(&P)) &&
				(P.data[ID_IFLD] == CONSTANT_IST) &&
				(P.data[FORMAT_CONST_IFLD] == CONSTANT_DIRECT) &&
				(P.data[DATA_CONST_IFLD] == LITERAL_IVAL)) {
				int V = (int) P.data[DATA_CONST_IFLD + 1];
				int W = Str::atoi(mr2.exp[1], 0);
				if (V == W) result = TRUE; else result = FALSE;
			}
		}
	}
	if (result == NOT_APPLICABLE) {
		TemplateReader::error("conditional compilation is too difficult in the template: #iftrue on %S", cond);
		result = FALSE;
	}
	LOGIF(RESOLVING_CONDITIONAL_COMPILATION, "Must decide if %S: ", cond);
	LOGIF(RESOLVING_CONDITIONAL_COMPILATION, "%s\n", (result)?"true":"false");
	if (Log::aspect_switched_on(RESOLVING_CONDITIONAL_COMPILATION_DA)) LOG_INDENT;
	@<Stack up the result@>;
	allow = FALSE;
	DISCARD_TEXT(ident);

@<Stack up the result@> =
	if (state->cc_sp >= MAX_CC_STACK_SIZE) {
		state->cc_sp = MAX_CC_STACK_SIZE; TemplateReader::error("conditional compilation is wrongly structured in the template: too many nested #ifdef or #iftrue", NULL);
	} else {
		state->cc_stack[state->cc_sp++] = result;
	}

@<Deal with an IFNOT@> =
	LOGIF(RESOLVING_CONDITIONAL_COMPILATION, "ifnot\n");
	if (state->cc_sp == 0) TemplateReader::error("conditional compilation is wrongly structured in the template: #ifnot at top level", NULL);
	else state->cc_stack[state->cc_sp-1] = (state->cc_stack[state->cc_sp-1])?FALSE:TRUE;
	allow = FALSE;

@<Deal with an ENDIF@> =
	if (Log::aspect_switched_on(RESOLVING_CONDITIONAL_COMPILATION_DA)) LOG_OUTDENT;
	LOGIF(RESOLVING_CONDITIONAL_COMPILATION, "endif\n");
	state->cc_sp--;
	if (state->cc_sp < 0) { state->cc_sp = 0; TemplateReader::error("conditional compilation is wrongly structured in the template: too many #endif", NULL); }
	allow = FALSE;
