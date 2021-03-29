[EquationSolver::] Compile Solutions to Equations.

To compile code to solve an equation involving numerical quantities.

@ We can finally turn to putting equations to use. Firstly, when a named
equation is used, a "where..." clause is sometimes given to make temporary
assignments (see above); what happens is that the S-parser temporarily sets
the usage words of the equation to the relevant text...

=
void EquationSolver::set_usage_notes(equation *eqn, wording W) {
	eqn->usage_text = W;
}

@ ...so that, when we come to solve the equation (i.e., later on in the
invocation compiler), we know where to find these temporary assignments.
They are wiped out once this compilation is over.

=
void EquationSolver::emit_solution(wording W, equation *eqn) {
	if (Wordings::nonempty(eqn->usage_text))
		Equations::eqn_declare_variables_inner(eqn, eqn->usage_text, TRUE);
	EquationSolver::emit_solution_inner(W, eqn);
	Equations::eqn_remove_temp_variables(eqn);
	eqn->usage_text = EMPTY_WORDING;
}

@ With that dance out of the way, we can concentrate on the actual task.
We have to compile code which assigns the correct value to the symbol
specified by $(w_1, w_2)$, according to the equation |eqn|.

=
void EquationSolver::emit_solution_inner(wording W, equation *eqn) {
	equation_symbol *to_solve = NULL;

	@<Identify which symbol in the equation we are solving for@>;
	@<Rearrange the equation so that this symbol is the entire LHS@>;
	@<Identify the symbols in the equation with local variables@>;

	TEMPORARY_TEXT(C)
	WRITE_TO(C, "Solving %n for '$w'", eqn->eqn_iname, to_solve->name);
	Emit::code_comment(C);
	DISCARD_TEXT(C)
	EquationSolver::enode_compile_by_emission(eqn, eqn->parsed_equation);
}

@ Note the case sensitivity here.

@<Identify which symbol in the equation we are solving for@> =
	if (Wordings::length(W) == 1)
		for (equation_symbol *ev = eqn->symbol_list; ev; ev = ev->next)
			if (Wordings::match_cs(W, ev->name))
				to_solve = ev;

	if (to_solve == NULL) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, W);
		Problems::quote_wording(3, eqn->equation_text);
		StandardProblems::handmade_problem(Task::syntax_tree(), 
			_p_(PM_EquationBadTarget));
		Problems::issue_problem_segment(
			"In %1, you asked to let %2 be given by the equation '%3', "
			"but '%2' isn't a symbol in that equation.");
		Problems::issue_problem_end();
		return;
	}

	if (to_solve->var_const) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, W);
		Problems::quote_wording(3, eqn->equation_text);
		Problems::quote_spec(4, to_solve->var_const);
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_EquationConstantTarget));
		Problems::issue_problem_segment(
			"In %1, you asked to let %2 be given by the equation '%3', "
			"but '%2' isn't something which can vary freely in that equation - "
			"it's been set equal to %4.");
		Problems::issue_problem_end();
		return;
	}

@ By far the hardest part of the problem is to rearrange the equation so that
the variable we want to find is the entire left hand side, but this is done
for us by code in //assertions: Equations//, so it looks easy here.

The surprising thing is the fresh round of typechecking: why do we do that?
The answer is not that we doubt whether the equation is still valid -- the
rearranged equation should pass if and only if the original did, if we've
implemented all of this correctly -- but because the alterations made to the
tree mean that the assignments of kinds at each node are now potentially
incorrect. Re-typechecking will recalculate these.

@<Rearrange the equation so that this symbol is the entire LHS@> =
	if (Equations::eqn_rearrange(eqn, to_solve) == FALSE) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, W);
		Problems::quote_wording(3, eqn->equation_text);
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_EquationInsoluble));
		Problems::issue_problem_segment(
			"In %1, you asked to let %2 be given by the equation '%3', "
			"but I am unable to rearrange the equation in any simple way "
			"so that it sets '%2' equal to something else. Maybe you could "
			"write a more explicit equation? (You're certainly better at "
			"maths than I am; I can only make easy deductions.)");
		Problems::issue_problem_end();
		return;
	}
	if (Equations::eqn_typecheck(eqn) == FALSE) return;

@ Suppose we read a phrase such as

>> let PE be given by PE = mgh, where g = 9.801 m/ss;

We can only compile code to do this if we can identify values for the symbols.
"g" is not a problem because a temporary assignment supplies this. For each
symbol |ev| which isn't a constant, we must set |ev->local_map| to the
corresponding local variable.

@<Identify the symbols in the equation with local variables@> =
	equation_symbol *ev;
	for (ev = eqn->symbol_list; ev; ev = ev->next)
		if (ev->var_const == NULL) {
			ev->local_map = LocalVariables::parse(Frames::current_stack_frame(), ev->name);
			ev->promote_local_to_real = FALSE;
			if (ev->local_map == NULL)
				@<Can't find an unset symbol among the local variables@>
			else
				@<Check that the kind of the local variable matches that of the symbol@>;
		}

@ In the above example, finding "PE" should not be a problem: this
is the |to_solve| symbol, and it must be a current local variable name
since the "let" will have created it as such if it didn't already
exist. But things can certainly go wrong with "m" and "h", which
need to exist as local variables in the current stack frame.

@<Can't find an unset symbol among the local variables@> =
	if (ev == to_solve) internal_error("can't find 'let' variable to assign");
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, W);
	Problems::quote_wording(3, eqn->equation_text);
	Problems::quote_wording(4, ev->name);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_EquationSymbolMissing));
	Problems::issue_problem_segment(
		"In %1, you asked to let %2 be given by the equation '%3', "
		"but I can't see what to use for '%4'. The usual idea is "
		"to set the other variables in the equation using 'let': "
		"so adding 'let %4 be ...' before trying to find '%2' "
		"should work.");
	Problems::issue_problem_end();
	return;

@ In the case of the symbol we are setting, the local variable might be one
which has only just been created and thus has no value yet -- not having
set it, Inform hasn't given it a kind more explicit than "value".
We can improve that by giving it the kind of the symbol it is to match.

In all other cases, the local variable already exists and has a fixed kind.
This must exactly match that of the symbol. (Again, if we ever need implicit
casting between quasinumerical kinds, we'll have to return to this.)

@<Check that the kind of the local variable matches that of the symbol@> =
	kind *K = LocalVariables::kind(ev->local_map);
	if (Kinds::eq(K, K_value)) {
		K = ev->var_kind;
		LocalVariables::set_kind(ev->local_map, K);
	}
	if ((Kinds::eq(K, K_number)) &&
		(Kinds::eq(ev->var_kind, K_real_number))) {
		K = K_real_number;
		ev->promote_local_to_real = TRUE;
	}
	if (Kinds::eq(K, ev->var_kind) == FALSE) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, W);
		Problems::quote_wording(3, eqn->equation_text);
		Problems::quote_wording(4, ev->name);
		Problems::quote_kind(5, K);
		Problems::quote_kind(6, ev->var_kind);
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_EquationSymbolWrongKOV));
		Problems::issue_problem_segment(
			"In %1, you asked to let %2 be given by the equation '%3', "
			"but in that equation '%4' is supposedly %6 - whereas right "
			"here, it seems to be %5. Perhaps two different quantities have "
			"ended up with the same symbol in the source text?");
		Problems::issue_problem_end();
		return;
	}

@ Actual compilation is simple, since the tree is set up for it.

=
void EquationSolver::enode_compile_by_emission(equation *eqn, equation_node *tok) {
	int a = 0;
	if (Kinds::FloatingPoint::is_real(tok->gK_before)) a = 1;
	int b = 0;
	if (Kinds::FloatingPoint::is_real(tok->gK_after)) b = 1;
	int f = b - a;
	if (f == 1) Kinds::FloatingPoint::begin_flotation_emit(
		Kinds::FloatingPoint::underlying(tok->gK_before));
	else if (f == -1) Kinds::FloatingPoint::begin_deflotation_emit(
		Kinds::FloatingPoint::underlying(tok->gK_before));
	switch (tok->eqn_type) {
		case SYMBOL_EQN:
			if (tok->leaf_symbol->var_const)
				Specifications::Compiler::emit_as_val(K_value, tok->leaf_symbol->var_const);
			else if (tok->leaf_symbol->local_map) {
				if (tok->leaf_symbol->promote_local_to_real) {
					Produce::inv_call_iname(Emit::tree(),
						Hierarchy::find(NUMBER_TY_TO_REAL_NUMBER_TY_HL));
					Produce::down(Emit::tree());
				}
				inter_symbol *tok_s =
					LocalVariables::declare_this(tok->leaf_symbol->local_map, FALSE, 8);
				Produce::val_symbol(Emit::tree(), K_value, tok_s);
				if (tok->leaf_symbol->promote_local_to_real)
					Produce::up(Emit::tree());
			}
			else if (tok->leaf_symbol->function_notated) {
				inter_name *RS = PhraseRequests::make_iname(
					tok->leaf_symbol->function_notated,
					IDTypeData::kind(
						&(tok->leaf_symbol->function_notated->type_data)));
				Produce::val_iname(Emit::tree(), K_value, RS);
			} else internal_error("uncompilable equation node");
			break;
		case CONSTANT_EQN:
			Specifications::Compiler::emit_as_val(K_value, tok->leaf_constant);
			break;
		case OPERATION_EQN: @<Emit a single operation@>; break;
		default: internal_error("forbidden enode found in parsed equation");
	}
	if (f == 1) Kinds::FloatingPoint::end_flotation_emit(
		Kinds::FloatingPoint::underlying(tok->gK_before));
	else if (f == -1) Kinds::FloatingPoint::end_deflotation_emit(
		Kinds::FloatingPoint::underlying(tok->gK_before));
}

@ And here we handle operation nodes:

@<Emit a single operation@> =
	equation_node *X = tok->enode_operands[0];
	kind *KX = Kinds::FloatingPoint::underlying(X->gK_after);
	equation_node *Y = tok->enode_operands[1];
	kind *KY = (Y)?(Kinds::FloatingPoint::underlying(Y->gK_after)):NULL;
	if (Kinds::FloatingPoint::is_real(X->gK_after)) {
		KX = K_real_number; KY = K_real_number;
	}

	Kinds::Compile::perform_arithmetic_emit(tok->eqn_operation, eqn,
		NULL, X, KX, NULL, Y, KY);

@ =
void EquationSolver::enode_compilation_error(equation *eqn, equation_node *tok) {
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, eqn->equation_text);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_HardIntegerRoot));
	Problems::issue_problem_segment(
		"In %1, you asked me to solve the equation '%2', but that would have "
		"involved taking a tricky root of a whole number. Using real numbers "
		"that would be easy, but with whole numbers I'm unable to get there.");
	Problems::issue_problem_end();
}
