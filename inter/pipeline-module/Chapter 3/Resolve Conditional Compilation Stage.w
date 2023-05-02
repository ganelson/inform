[ResolveConditionalsStage::] Resolve Conditional Compilation Stage.

To generate the initial state of storage for variables.

@h Pipeline stage.
This stage is intended to run immediately after |load-kit-source|. That will
have produced a sequence of |SPLAT_IST| nodes corresponding to directives,
and some of those will be conditional compilation directives. For example,
we might see a sequence like this:
= (text)
	IFDEF_PLM
	ROUTINE_PLM
	IFNOT_PLM
	ARRAY_PLM
	ROUTINE_PLM
	ENDIF_PLM
=
Clearly this either means a function (the first |ROUTINE_PLM|), or a different
function plus an array. We have to decide that now, because optimisation, code
generation and so on need to know exactly what they are dealing with.

If we allowed kit sources to contain arbitrary conditional compilations, that
would be impossible. But in practice they only need to depend on the constants
which are defined by the VM architecture -- whether 16 or 32 bit; whether
debugging is enabled. And we do know the architecture now. (This is why a kit
has a different binary form for each different architecture supported.) So this
stage collapses the above to either:
= (text)
	ROUTINE_PLM
=
or:
= (text)
	ARRAY_PLM
	ROUTINE_PLM
=
depending on which way the |IFDEF_PLM| comes out. At the end of this stage,
then, none of the directives |IFDEF_PLM|, |IFNDEF_PLM|, |IFTRUE_PLM|,
|IFNOT_PLM| or |ENDIF_PLM| appear anywhere in the tree, and all compilation
is therefore unconditional.

=
void ResolveConditionalsStage::create_pipeline_stage(void) {
	ParsingPipelines::new_stage(I"resolve-conditional-compilation",
		ResolveConditionalsStage::run, NO_STAGE_ARG, FALSE);
}

int ResolveConditionalsStage::run(pipeline_step *step) {
	ResolveConditionalsStage::resolve(step->ephemera.tree);
	return TRUE;
}

@h Resolution.
While traversing the tree for conditionals, we need to keep track of the current
state, which we do with the following stack. Each time we pass over the start
of an active conditional, we push its state.

The standard Inform kits never exceed
a nesting depth of about 3, so the following maximum is plenty:

@d MAX_CC_STACK_SIZE 32

=
typedef struct rcc_state {
	struct dictionary *I6_level_symbols;
	int cc_stack[MAX_CC_STACK_SIZE];
	int cc_sp;
} rcc_state;

void ResolveConditionalsStage::resolve(inter_tree *I) {
	rcc_state state;
	state.I6_level_symbols = Dictionaries::new(1024, TRUE);
	state.cc_sp = 0;
	InterTree::traverse(I, ResolveConditionalsStage::visitor, &state, NULL, 0);
	if (state.cc_sp != 0)
		I6Errors::issue(
			"conditional compilation wrongly structured: not enough #endif", NULL);
	I6Errors::clear_current_location();
}

@ Note that when the top of the stack is a block whose body is not to be compiled,
we delete each node we traverse through. (The |InterTree::traverse| function
is written such that this can safely be done.)

=
void ResolveConditionalsStage::visitor(inter_tree *I, inter_tree_node *P, void *v_state) {
	rcc_state *state = (rcc_state *) v_state;
	int compile_this = TRUE;
	for (int i=0; i<state->cc_sp; i++) if (state->cc_stack[i] == FALSE) compile_this = FALSE;
	if (Inode::is(P, SPLAT_IST)) {
		I6Errors::set_current_location_near_splat(P);
		text_stream *S = SplatInstruction::splatter(P);
		switch (SplatInstruction::plm(P)) {
			case CONSTANT_PLM:
			case GLOBAL_PLM:
			case ARRAY_PLM:
			case ROUTINE_PLM:
			case DEFAULT_PLM:
			case STUB_PLM:
				@<Symbol definition@>;
				break;
			case IFDEF_PLM: @<Deal with an IFDEF@>; break;
			case IFNDEF_PLM: @<Deal with an IFNDEF@>; break;
			case IFTRUE_PLM: @<Deal with an IFTRUE@>; break;
			case IFNOT_PLM: @<Deal with an IFNOT@>; break;
			case ENDIF_PLM: @<Deal with an ENDIF@>; break;
		}
	}
	if (compile_this == FALSE) NodePlacement::remove(P);
}

@ In order to answer whether or not a symbol is defined... we must look for it.
Note that definitions only count if they are in active code. Here, |Y| is added
to the dictionary when it is reached:
= (text as Inform 6)
	Constant X = 1;
	#Ifdef X;
	Constant Y = 2;
	#Endif;
=
But here it is not:
= (text as Inform 6)
	Constant X = 1;
	#Ifndef X;
	Constant Y = 2;
	#Endif;
=

@<Symbol definition@> =
	if (compile_this) {
		TEMPORARY_TEXT(ident)
		@<Extract second token into ident@>;
		LOGIF(RESOLVING_CONDITIONAL_COMPILATION, "I6 defines %S here\n", ident);
		Dictionaries::create(state->I6_level_symbols, ident);
		DISCARD_TEXT(ident)
	}

@<Deal with an IFDEF@> =
	TEMPORARY_TEXT(ident)
	@<Extract rest of text into ident@>;
	int result = FALSE;
	text_stream *symbol_name = ident;
	text_stream *identifier = ident;
	@<Throw an error for what looks like a configuration identifier@>;
	@<Decide whether symbol defined@>;
	@<Stack up the result@>;
	compile_this = FALSE;
	DISCARD_TEXT(ident)

@<Deal with an IFNDEF@> =
	TEMPORARY_TEXT(ident)
	@<Extract rest of text into ident@>;
	int result = FALSE;
	text_stream *symbol_name = ident;
	text_stream *identifier = ident;
	@<Throw an error for what looks like a configuration identifier@>;
	@<Decide whether symbol defined@>;
	result = (result)?FALSE:TRUE;
	@<Stack up the result@>;
	compile_this = FALSE;
	DISCARD_TEXT(ident)

@<Decide whether symbol defined@> =
	inter_symbol *symbol = LargeScale::architectural_symbol(I, symbol_name);
	if (symbol) {
		result = (InterSymbol::defined_elsewhere(symbol))?FALSE:TRUE;
	} else {
		if (Dictionaries::find(state->I6_level_symbols, symbol_name)) result = TRUE;
	}
	LOGIF(RESOLVING_CONDITIONAL_COMPILATION,
		"Must decide if %S defined: %s\n", symbol_name, (result)?"yes":"no");
	if (Log::aspect_switched_on(RESOLVING_CONDITIONAL_COMPILATION_DA)) LOG_INDENT;

@ The following can test |#Iftrue S == W| only for non-negative integers |W|. It
wouldn't be too hard to test other cases, but we just don't need to. The standard
Inform kits use this only to test |#Iftrue WORDSIZE == 4| or |#Iftrue WORDSIZE == 2|.

@<Deal with an IFTRUE@> =
	TEMPORARY_TEXT(ident)
	@<Extract rest of text into ident@>;
	int result = NOT_APPLICABLE;
	text_stream *cond = ident;
	match_results mr2 = Regexp::create_mr();
	if (Regexp::match(&mr2, cond, L" *(%C+?) *== *(%d+) *")) {
		text_stream *identifier = mr2.exp[0];
		@<Throw an error for what looks like a configuration identifier@>;
		inter_symbol *symbol = LargeScale::architectural_symbol(I, identifier);
		if (symbol) {
			int V = InterSymbol::evaluate_to_int(symbol);
			int W = Str::atoi(mr2.exp[1], 0);
			if ((V >= 0) && (V == W)) result = TRUE; else result = FALSE;
		}
	}
	if (Regexp::match(&mr2, cond, L" *(%C+?) *>= *(%d+) *")) {
		text_stream *identifier = mr2.exp[0];
		@<Throw an error for what looks like a configuration identifier@>;
		inter_symbol *symbol = LargeScale::architectural_symbol(I, identifier);
		if (symbol) {
			int V = InterSymbol::evaluate_to_int(symbol);
			int W = Str::atoi(mr2.exp[1], 0);
			if ((V >= 0) && (V >= W)) result = TRUE; else result = FALSE;
		}
	}
	if (Regexp::match(&mr2, cond, L" *(%C+?) *> *(%d+) *")) {
		text_stream *identifier = mr2.exp[0];
		@<Throw an error for what looks like a configuration identifier@>;
		inter_symbol *symbol = LargeScale::architectural_symbol(I, identifier);
		if (symbol) {
			int V = InterSymbol::evaluate_to_int(symbol);
			int W = Str::atoi(mr2.exp[1], 0);
			if ((V >= 0) && (V > W)) result = TRUE; else result = FALSE;
		}
	}
	if (Regexp::match(&mr2, cond, L" *(%C+?) *<= *(%d+) *")) {
		text_stream *identifier = mr2.exp[0];
		@<Throw an error for what looks like a configuration identifier@>;
		inter_symbol *symbol = LargeScale::architectural_symbol(I, identifier);
		if (symbol) {
			int V = InterSymbol::evaluate_to_int(symbol);
			int W = Str::atoi(mr2.exp[1], 0);
			if ((V >= 0) && (V <= W)) result = TRUE; else result = FALSE;
		}
	}
	if (Regexp::match(&mr2, cond, L" *(%C+?) *< *(%d+) *")) {
		text_stream *identifier = mr2.exp[0];
		@<Throw an error for what looks like a configuration identifier@>;
		inter_symbol *symbol = LargeScale::architectural_symbol(I, identifier);
		if (symbol) {
			int V = InterSymbol::evaluate_to_int(symbol);
			int W = Str::atoi(mr2.exp[1], 0);
			if ((V >= 0) && (V < W)) result = TRUE; else result = FALSE;
		}
	}
	if (result == NOT_APPLICABLE) {
		I6Errors::issue(
			"conditional compilation is too difficult: #iftrue on '%S' "
			"(can only test SYMBOL == DECIMALVALUE, or >, <, >=, <=, where "
			"the DECIMALVALUE is non-negative, and even then only for a few "
			"symbols, of which 'WORDSIZE' is the most useful)", cond);
		result = FALSE;
	}
	LOGIF(RESOLVING_CONDITIONAL_COMPILATION, "Must decide if %S: ", cond);
	LOGIF(RESOLVING_CONDITIONAL_COMPILATION, "%s\n", (result)?"true":"false");
	if (Log::aspect_switched_on(RESOLVING_CONDITIONAL_COMPILATION_DA)) LOG_INDENT;
	@<Stack up the result@>;
	compile_this = FALSE;
	DISCARD_TEXT(ident)

@<Throw an error for what looks like a configuration identifier@> =
	LOOP_THROUGH_TEXT(pos, identifier)
		if (Str::get(pos) == '`') {
			if ((Str::suffix_eq(identifier, I"_CFGF", 5)) ||
				(Str::suffix_eq(identifier, I"_CFGV", 5)))
				I6Errors::issue(
					"#iftrue, #iffalse, #ifdef and #ifndef should not be used with kit "
					"configuration values such as '%S', since those values are not known "
					"when the kit is being compiled: use regular 'if (S)' or 'if (S == V)'",
					identifier);
			break;
		}

@<Stack up the result@> =
	if (state->cc_sp >= MAX_CC_STACK_SIZE) {
		state->cc_sp = MAX_CC_STACK_SIZE;
		I6Errors::issue(
			"conditional compilation wrongly structured: too many nested #ifdef or #iftrue", NULL);
	} else {
		state->cc_stack[state->cc_sp++] = result;
	}

@<Deal with an IFNOT@> =
	LOGIF(RESOLVING_CONDITIONAL_COMPILATION, "ifnot\n");
	if (state->cc_sp == 0)
		I6Errors::issue("conditional compilation wrongly structured: #ifnot at top level", NULL);
	else
		state->cc_stack[state->cc_sp-1] = (state->cc_stack[state->cc_sp-1])?FALSE:TRUE;
	compile_this = FALSE;

@<Deal with an ENDIF@> =
	if (Log::aspect_switched_on(RESOLVING_CONDITIONAL_COMPILATION_DA)) LOG_OUTDENT;
	LOGIF(RESOLVING_CONDITIONAL_COMPILATION, "endif\n");
	state->cc_sp--;
	if (state->cc_sp < 0) {
		state->cc_sp = 0;
		I6Errors::issue("conditional compilation wrongly structured: too many #endif", NULL);
	}
	compile_this = FALSE;

@ That just leaves some dull code to tokenise the directive. E.g., the second
token of |#Iftrue FROG == 2| is |FROG|; the "rest of text" is |FROG == 2|.

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
