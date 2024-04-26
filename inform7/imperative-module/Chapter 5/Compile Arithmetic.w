[CompileArithmetic::] Compile Arithmetic.

To compile code performing an arithmetic operation.

@ This section provides a single function to compile Inter code to perform
an arithmetic operation. It implements the |{-arithmetic-operation:X:Y}|
bracing when used in inline invocations, and is also needed for equation
solving; see //Compile Solutions to Equations//. Because of that, the function
is called either with |X| and |Y| set to values, or with |EX| and |EY| set to
equation nodes, but not both. |eqn| is set only for the equations case; but
in both cases |KX| and |KY| are the kinds of the arithmetic operands, and |op|
is the operation number.

For unary operations, |Y|, |EY| and |KY| will all be |NULL|.

What happens is straightforward enough, but we provide a fair range of different
operations, and we have to manage scaling factors and whether the underlying
arithmetic is integer or floating-point.

=
void CompileArithmetic::perform_arithmetic_emit(int op, equation *eqn,
	parse_node *X, equation_node *EX, kind *KX,
	parse_node *Y, equation_node *EY, kind *KY) {
	int binary = TRUE;
	if (Kinds::Dimensions::arithmetic_op_is_unary(op)) binary = FALSE;
	int use_fp = FALSE, promote_X = FALSE, promote_Y = FALSE, demote_result = FALSE;
	kind *KR = Kinds::Dimensions::arithmetic_on_kinds(KX, KY, op);
	if ((KX) && (KY)) {
		if (((Kinds::FloatingPoint::uses_floating_point(KX)) ||
				(Kinds::FloatingPoint::uses_floating_point(KY)))
			&& (Kinds::FloatingPoint::uses_floating_point(KR) == FALSE)
			&& ((op == TIMES_OPERATION) || (op == DIVIDE_OPERATION)))
			demote_result = TRUE;
	}
	@<Choose which form of arithmetic and promotion@>;
	@<Optimise promotions from number to real number@>;
	
	if (demote_result) Kinds::FloatingPoint::begin_deflotation_emit(KR);
	operand_emission_data oed_X, oed_Y;
	@<Set up the operands@>;
	@<Emit the code for the operation@>;
	if (demote_result) Kinds::FloatingPoint::end_deflotation_emit(KR);
}

@ For a binary operation, note that "pi plus pi", "pi plus 3", and "3 plus pi"
must all use floating-point, whereas "3 plus 3" uses integer arithmetic: in
other words, if either operand is real, then real arithmetic must be used.
"Promotion" means converting an integer to a real number (I'm not quite sure
why that is traditionally thought of as being better) -- in "pi plus 3", the
integer 3 is promoted to real.

@<Choose which form of arithmetic and promotion@> =
	if (binary) {
		if (Kinds::FloatingPoint::uses_floating_point(KX)) {
			if (Kinds::FloatingPoint::uses_floating_point(KY)) {
				use_fp = TRUE; promote_X = FALSE; promote_Y = FALSE;
			} else {
				use_fp = TRUE; promote_X = FALSE; promote_Y = TRUE;
			}
		} else {
			if (Kinds::FloatingPoint::uses_floating_point(KY)) {
				use_fp = TRUE; promote_X = TRUE; promote_Y = FALSE;
			} else {
				use_fp = FALSE; promote_X = FALSE; promote_Y = FALSE;
			}
		}
	} else {
		if (Kinds::FloatingPoint::uses_floating_point(KX)) {
			use_fp = TRUE; promote_X = FALSE; promote_Y = FALSE;
		} else {
			use_fp = FALSE; promote_X = FALSE; promote_Y = FALSE;
		}
	}

@ Making this optimisation ensures that if X or Y are literal |K_number| values
then they will be converted to literal |K_real_number| values at compile time
rather than at runtime, saving a function call in cases like
= (text as Inform 7)
	let the magic value be 4 + pi;
=
where there is no need to convert 4 to 4.0 at runtime; we can simply reinterpret
it as a real.

@<Optimise promotions from number to real number@> =
	if ((promote_X) && (Kinds::eq(KX, K_number))) { promote_X = FALSE; KX = K_real_number; }
	if ((promote_Y) && (Kinds::eq(KY, K_number))) { promote_Y = FALSE; KY = K_real_number; }

@<Set up the operands@> =
	oed_X = CompileArithmetic::operand_data(X, EX, KX, promote_X, eqn);
	oed_Y = CompileArithmetic::operand_data(Y, EY, KY, promote_Y, eqn);
	if (use_fp == FALSE) {
		switch (op) {
			case TIMES_OPERATION:    oed_X.rescale_multiply_K = KY; break;
			case DIVIDE_OPERATION:   oed_X.rescale_divide_K = KY; break;
			case ROOT_OPERATION:     oed_X.rescale_root = 2; break;
			case CUBEROOT_OPERATION: oed_X.rescale_root = 3; break;
		}
	}

@<Emit the code for the operation@> =
	switch (op) {
		case EQUALS_OPERATION: @<Emit set-equals@>; break;
		case POWER_OPERATION: @<Emit a power of the left operand@>; break;
		case IMPLICIT_APPLICATION_OPERATION: @<Emit implicit application@>; break;
		case PLUS_OPERATION:
		case MINUS_OPERATION:
		case TIMES_OPERATION:
		case DIVIDE_OPERATION:
		case REMAINDER_OPERATION:
		case APPROXIMATION_OPERATION:
		case ROOT_OPERATION:
		case CUBEROOT_OPERATION:
		case UNARY_MINUS_OPERATION:
			CompileArithmetic::compile_by_schema(op, &oed_X, &oed_Y);
			break;
		case REALROOT_OPERATION:
			CompileArithmetic::compile_by_schema(ROOT_OPERATION, &oed_X, &oed_Y);
			break;
		default:
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(BelievedImpossible),
				"this doesn't seem to be an arithmetic operation",
				"suggesting a problem with some inline definition.");
			break;
	}

@<Emit set-equals@> =
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::reference();
		EmitCode::down();
			CompileArithmetic::compile_operand(&oed_X);
		EmitCode::up();
		CompileArithmetic::compile_operand(&oed_Y);
	EmitCode::up();

@ We accomplish integer powers by repeated multiplication. This is partly
because Inter has no "to the power of" opcode, partly because the powers involved
will always be small, partly because of the need for scaling to come out right.

@<Emit a power of the left operand@> =
	if (use_fp) {
		CompileArithmetic::compile_by_schema(op, &oed_X, &oed_Y);
	} else {
		int p = 0;
		if (Y) p = Rvalues::to_int(Y);
		else p = Rvalues::to_int(EY->leaf_constant);
		if (p <= 0) EquationSolver::issue_problem_on_root(eqn, EY);
		else if (p == 1) CompileArithmetic::compile_operand(&oed_X);
		else {
			for (int i=1; i<p; i++) {
				Kinds::Scalings::rescale_multiplication_emit_op(KX, KX);
				EmitCode::inv(TIMES_BIP);
				EmitCode::down();
					CompileArithmetic::compile_operand(&oed_X);
			}
			CompileArithmetic::compile_operand(&oed_X);
			for (int i=1; i<p; i++) {
				EmitCode::up();
				Kinds::Scalings::rescale_multiplication_emit_factor(KX, KX);
			}
		}
	}

@ This is used in equation solving only; here we are evaluating a mathematical
function like |log pi|, where |X| is the function (in this case |log|) and
|Y| the value (in this case |pi|). Clearly a function cannot be promoted.

@<Emit implicit application@> =
	oed_X.promote_me = FALSE;
	EmitCode::inv(INDIRECT1_BIP);
	EmitCode::down();
		CompileArithmetic::compile_operand(&oed_X);
		CompileArithmetic::compile_operand(&oed_Y);
	EmitCode::up();

@

=
typedef struct operand_emission_data {
	struct parse_node *X;
	struct equation_node *EX;
	struct kind *KX;
	struct equation *eqn;
	int promote_me;
	struct kind *rescale_divide_K;
	struct kind *rescale_multiply_K;
	int rescale_root;
} operand_emission_data;

operand_emission_data CompileArithmetic::operand_data(parse_node *X, equation_node *EX,
	kind *KX, int promote_me, equation *eqn) {
	operand_emission_data oed;
	oed.X = X; oed.EX = EX; oed.KX = KX; oed.promote_me = promote_me; oed.eqn = eqn;
	oed.rescale_divide_K = NULL; oed.rescale_multiply_K = NULL; oed.rescale_root = 0;
	return oed;
}

void CompileArithmetic::compile_by_schema(int op,
	operand_emission_data *oed_X, operand_emission_data *oed_Y) {
	if (oed_X->rescale_multiply_K)
		Kinds::Scalings::rescale_multiplication_emit_op(oed_X->KX, oed_Y->KX);
	TEMPORARY_TEXT(prototype)
	CompileArithmetic::schema(prototype, oed_X->KX, oed_Y->KX, op, I"*1", I"*2");
	i6_schema *sch = Calculus::Schemas::new("%S;", prototype);
	CompileSchemas::with_callbacks_in_val_context(sch, oed_X, oed_Y,
		&CompileArithmetic::compile_operand);
	DISCARD_TEXT(prototype)
	if (oed_X->rescale_multiply_K)
		Kinds::Scalings::rescale_multiplication_emit_factor(oed_X->KX, oed_Y->KX);
}

void CompileArithmetic::compile_operand(void *oed_v) {
	operand_emission_data *oed = (operand_emission_data *) oed_v;
	if (oed->promote_me) Kinds::FloatingPoint::begin_flotation_emit(oed->KX);
	
	if (oed->rescale_divide_K) Kinds::Scalings::rescale_division_emit_op(oed->KX, oed->rescale_divide_K);
	else if (oed->rescale_root) Kinds::Scalings::rescale_root_emit_op(oed->KX, oed->rescale_root);
	
	if (oed->X) CompileValues::to_code_val_of_kind(oed->X, oed->KX);
	else EquationSolver::compile_enode(oed->eqn, oed->EX);
	
	if (oed->rescale_divide_K) Kinds::Scalings::rescale_division_emit_factor(oed->KX, oed->rescale_divide_K);
	else if (oed->rescale_root) Kinds::Scalings::rescale_root_emit_factor(oed->KX, oed->rescale_root);

	if (oed->promote_me) Kinds::FloatingPoint::end_flotation_emit(oed->KX);
}

@

=
void CompileArithmetic::schema(OUTPUT_STREAM, kind *KX, kind *KY,
	int operation, text_stream *X, text_stream *Y) {
	int reducing_modulo_1440 = FALSE;
	#ifdef IF_MODULE
	kind *KT = TimesOfDay::kind();
	if ((KT) && (Kinds::eq(KX, KT))) reducing_modulo_1440 = TRUE;
	#endif
	if (reducing_modulo_1440) WRITE("NUMBER_TY_to_TIME_TY(");
	switch (operation) {
		case PLUS_OPERATION:
			if (Kinds::FloatingPoint::uses_floating_point(KX))
				WRITE("REAL_NUMBER_TY_Plus(%S, %S)", X, Y);
			else
				WRITE("%S + %S", X, Y);
			break;
		case MINUS_OPERATION:
			if (Kinds::FloatingPoint::uses_floating_point(KX))
				WRITE("REAL_NUMBER_TY_Minus(%S, %S)", X, Y);
			else
				WRITE("%S - %S", X, Y);
			break;
		case TIMES_OPERATION:
			if (Kinds::FloatingPoint::uses_floating_point(KX))
				WRITE("REAL_NUMBER_TY_Times(%S, %S)", X, Y);
			else
				WRITE("%S ** %S", X, Y);
			break;
		case DIVIDE_OPERATION:
			if (Kinds::FloatingPoint::uses_floating_point(KX))
				WRITE("REAL_NUMBER_TY_Divide(%S, %S)", X, Y);
			else
				WRITE("IntegerDivide(%S, %S)", X, Y);
			break;
		case REMAINDER_OPERATION:
			if (Kinds::FloatingPoint::uses_floating_point(KX))
				WRITE("REAL_NUMBER_TY_Remainder(%S, %S)", X, Y);
			else
				WRITE("IntegerRemainder(%S, %S)", X, Y);
			break;
		case APPROXIMATION_OPERATION:
			if (Kinds::FloatingPoint::uses_floating_point(KX))
				WRITE("REAL_NUMBER_TY_Approximate(%S, %S)", X, Y);
			else
				WRITE("RoundOffValue(%S, %S)", X, Y);
			break;
		case UNARY_MINUS_OPERATION:
			if (Kinds::FloatingPoint::uses_floating_point(KX))
				WRITE("REAL_NUMBER_TY_Negate(%S)", X);
			else
				WRITE("(-(%S))", X);
			break;
		case REALROOT_OPERATION:
			WRITE("REAL_NUMBER_TY_Root(%S)", X);
			break;
		case ROOT_OPERATION:
			if (Kinds::FloatingPoint::uses_floating_point(KX))
				WRITE("REAL_NUMBER_TY_Root(%S)", X);
			else
				WRITE("SquareRoot(%S)", X);
			break;
		case CUBEROOT_OPERATION:
			if (Kinds::FloatingPoint::uses_floating_point(KX))
				WRITE("REAL_NUMBER_TY_CubeRoot(%S)", X);
			else
				WRITE("CubeRoot(%S)", X);
			break;
		case POWER_OPERATION:
			if (Kinds::FloatingPoint::uses_floating_point(KX))
				WRITE("REAL_NUMBER_TY_Pow(%S, %S)", X, Y);
			else
				internal_error("no integer power function exists");
			break;
		default:
			internal_error("no schema can be provided for this operation");
	}
	if (reducing_modulo_1440) WRITE(")");
}
