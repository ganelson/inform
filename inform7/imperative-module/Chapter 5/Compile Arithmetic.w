[Kinds::Compile::] Compile Arithmetic.

To compile code performing an arithmetic operation.

@h Compiling arithmetic.

=
void Kinds::Compile::perform_arithmetic_emit(int op, equation *eqn,
	parse_node *X, equation_node *EX, kind *KX,
	parse_node *Y, equation_node *EY, kind *KY) {
	int binary = TRUE;
	if (Kinds::Dimensions::arithmetic_op_is_unary(op)) binary = FALSE;
	int use_fp = FALSE, promote_X = FALSE, promote_Y = FALSE, reduce_modulo_1440 = FALSE;
	if ((KX) && (KY)) {
		#ifdef IF_MODULE
		kind *KR = Kinds::Dimensions::arithmetic_on_kinds(KX, KY, op);
		kind *KT = TimesOfDay::kind();
		if ((KT) && (Kinds::eq(KR, KT))) reduce_modulo_1440 = TRUE;
		#endif
	}
	@<Choose which form of arithmetic and promotion@>;
	if (reduce_modulo_1440) {
		Produce::inv_call_iname(Emit::tree(), Hierarchy::find(NUMBER_TY_TO_TIME_TY_HL));
		Produce::down(Emit::tree());
	}
	switch (op) {
		case EQUALS_OPERATION: @<Emit set-equals@>; break;
		case PLUS_OPERATION: @<Emit plus@>; break;
		case MINUS_OPERATION: @<Emit minus@>; break;
		case TIMES_OPERATION: @<Emit times@>; break;
		case DIVIDE_OPERATION: @<Emit divide@>; break;
		case REMAINDER_OPERATION: @<Emit remainder@>; break;
		case APPROXIMATION_OPERATION: @<Emit approximation@>; break;
		case ROOT_OPERATION: @<Emit root@>; break;
		case REALROOT_OPERATION: use_fp = TRUE; @<Emit root@>; break;
		case CUBEROOT_OPERATION: @<Emit cube root@>; break;
		case POWER_OPERATION: @<Emit a power of the left operand@>; break;
		case UNARY_MINUS_OPERATION: @<Emit unary minus@>; break;
		case IMPLICIT_APPLICATION_OPERATION: @<Emit function application@>; break;
		default:
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(BelievedImpossible),
				"this doesn't seem to be an arithmetic operation",
				"suggesting a problem with some inline definition.");
			break;
	}
	if (reduce_modulo_1440) Produce::up(Emit::tree());
}

@ The four cases for a binary operation correspond to:

>> pi plus pi, pi plus 3, 3 plus pi, 3 plus 3

respectively. If either operand is real, floating-point arithmetic is used,
and the other operand is promoted from integer to real if necessary.

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

@<Emit plus@> =
	if (use_fp) {
		Produce::inv_call_iname(Emit::tree(), Hierarchy::find(REAL_NUMBER_TY_PLUS_HL));
		Produce::down(Emit::tree());
			if (promote_X) Kinds::FloatingPoint::begin_flotation_emit(KX);
			@<Emit the X-operand@>;
			if (promote_X) Kinds::FloatingPoint::end_flotation_emit(KX);
			if (promote_Y) Kinds::FloatingPoint::begin_flotation_emit(KY);
			@<Emit the Y-operand@>;
			if (promote_Y) Kinds::FloatingPoint::end_flotation_emit(KY);
		Produce::up(Emit::tree());
	} else {
		Produce::inv_primitive(Emit::tree(), PLUS_BIP);
		Produce::down(Emit::tree());
			@<Emit the X-operand@>;
			@<Emit the Y-operand@>;
		Produce::up(Emit::tree());
	}

@<Emit minus@> =
	if (use_fp) {
		Produce::inv_call_iname(Emit::tree(), Hierarchy::find(REAL_NUMBER_TY_MINUS_HL));
		Produce::down(Emit::tree());
			if (promote_X) Kinds::FloatingPoint::begin_flotation_emit(KX);
			@<Emit the X-operand@>;
			if (promote_X) Kinds::FloatingPoint::end_flotation_emit(KX);
			if (promote_Y) Kinds::FloatingPoint::begin_flotation_emit(KY);
			@<Emit the Y-operand@>;
			if (promote_Y) Kinds::FloatingPoint::end_flotation_emit(KY);
		Produce::up(Emit::tree());
	} else {
		Produce::inv_primitive(Emit::tree(), MINUS_BIP);
		Produce::down(Emit::tree());
			@<Emit the X-operand@>;
			@<Emit the Y-operand@>;
		Produce::up(Emit::tree());
	}

@<Emit times@> =
	if (use_fp) {
		Produce::inv_call_iname(Emit::tree(), Hierarchy::find(REAL_NUMBER_TY_TIMES_HL));
		Produce::down(Emit::tree());
			if (promote_X) Kinds::FloatingPoint::begin_flotation_emit(KX);
			@<Emit the X-operand@>;
			if (promote_X) Kinds::FloatingPoint::end_flotation_emit(KX);
			if (promote_Y) Kinds::FloatingPoint::begin_flotation_emit(KY);
			@<Emit the Y-operand@>;
			if (promote_Y) Kinds::FloatingPoint::end_flotation_emit(KY);
		Produce::up(Emit::tree());
	} else {
		Kinds::Scalings::rescale_multiplication_emit_op(KX, KY);
		Produce::inv_primitive(Emit::tree(), TIMES_BIP);
		Produce::down(Emit::tree());
			@<Emit the X-operand@>;
			@<Emit the Y-operand@>;
		Produce::up(Emit::tree());
		Kinds::Scalings::rescale_multiplication_emit_factor(KX, KY);
	}

@<Emit divide@> =
	if (use_fp) {
		Produce::inv_call_iname(Emit::tree(), Hierarchy::find(REAL_NUMBER_TY_DIVIDE_HL));
		Produce::down(Emit::tree());
			if (promote_X) Kinds::FloatingPoint::begin_flotation_emit(KX);
			@<Emit the X-operand@>;
			if (promote_X) Kinds::FloatingPoint::end_flotation_emit(KX);
			if (promote_Y) Kinds::FloatingPoint::begin_flotation_emit(KY);
			@<Emit the Y-operand@>;
			if (promote_Y) Kinds::FloatingPoint::end_flotation_emit(KY);
		Produce::up(Emit::tree());
	} else {
		Produce::inv_call_iname(Emit::tree(), Hierarchy::find(INTEGERDIVIDE_HL));
		Produce::down(Emit::tree());
			Kinds::Scalings::rescale_division_emit_op(KX, KY);
			@<Emit the X-operand@>;
			Kinds::Scalings::rescale_division_emit_factor(KX, KY);
			@<Emit the Y-operand@>;
		Produce::up(Emit::tree());
	}

@<Emit remainder@> =
	if (use_fp) {
		Produce::inv_call_iname(Emit::tree(), Hierarchy::find(REAL_NUMBER_TY_REMAINDER_HL));
		Produce::down(Emit::tree());
			if (promote_X) Kinds::FloatingPoint::begin_flotation_emit(KX);
			@<Emit the X-operand@>;
			if (promote_X) Kinds::FloatingPoint::end_flotation_emit(KX);
			if (promote_Y) Kinds::FloatingPoint::begin_flotation_emit(KY);
			@<Emit the Y-operand@>;
			if (promote_Y) Kinds::FloatingPoint::end_flotation_emit(KY);
		Produce::up(Emit::tree());
	} else {
		Produce::inv_call_iname(Emit::tree(), Hierarchy::find(INTEGERREMAINDER_HL));
		Produce::down(Emit::tree());
			@<Emit the X-operand@>;
			@<Emit the Y-operand@>;
		Produce::up(Emit::tree());
	}

@<Emit approximation@> =
	if (use_fp) {
		Produce::inv_call_iname(Emit::tree(), Hierarchy::find(REAL_NUMBER_TY_APPROXIMATE_HL));
		Produce::down(Emit::tree());
			if (promote_X) Kinds::FloatingPoint::begin_flotation_emit(KX);
			@<Emit the X-operand@>;
			if (promote_X) Kinds::FloatingPoint::end_flotation_emit(KX);
			if (promote_Y) Kinds::FloatingPoint::begin_flotation_emit(KY);
			@<Emit the Y-operand@>;
			if (promote_Y) Kinds::FloatingPoint::end_flotation_emit(KY);
		Produce::up(Emit::tree());
	} else {
		Produce::inv_call_iname(Emit::tree(), Hierarchy::find(ROUNDOFFVALUE_HL));
		Produce::down(Emit::tree());
			@<Emit the X-operand@>;
			@<Emit the Y-operand@>;
		Produce::up(Emit::tree());
	}

@<Emit root@> =
	if (use_fp) {
		Produce::inv_call_iname(Emit::tree(), Hierarchy::find(REAL_NUMBER_TY_ROOT_HL));
		Produce::down(Emit::tree());
			@<Emit the X-operand@>;
		Produce::up(Emit::tree());
	} else {
		Produce::inv_call_iname(Emit::tree(), Hierarchy::find(SQUAREROOT_HL));
		Produce::down(Emit::tree());
			Kinds::Scalings::rescale_root_emit_op(KX, 2);
			@<Emit the X-operand@>;
			Kinds::Scalings::rescale_root_emit_factor(KX, 2);
		Produce::up(Emit::tree());
	}

@<Emit cube root@> =
	if (use_fp) {
		Produce::inv_call_iname(Emit::tree(), Hierarchy::find(REAL_NUMBER_TY_CUBE_ROOT_HL));
		Produce::down(Emit::tree());
			@<Emit the X-operand@>;
		Produce::up(Emit::tree());
	} else {
		Produce::inv_call_iname(Emit::tree(), Hierarchy::find(CUBEROOT_HL));
		Produce::down(Emit::tree());
			Kinds::Scalings::rescale_root_emit_op(KX, 3);
			@<Emit the X-operand@>;
			Kinds::Scalings::rescale_root_emit_factor(KX, 3);
		Produce::up(Emit::tree());
	}

@<Emit set-equals@> =
	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Produce::down(Emit::tree());
		Produce::reference(Emit::tree());
		Produce::down(Emit::tree());
			@<Emit the X-operand@>;
		Produce::up(Emit::tree());
		if (promote_Y) Kinds::FloatingPoint::begin_flotation_emit(KY);
		@<Emit the Y-operand@>;
		if (promote_Y) Kinds::FloatingPoint::end_flotation_emit(KY);
	Produce::up(Emit::tree());

@<Emit unary minus@> =
	if (use_fp) {
		Produce::inv_call_iname(Emit::tree(), Hierarchy::find(REAL_NUMBER_TY_NEGATE_HL));
		Produce::down(Emit::tree());
			@<Emit the X-operand@>;
		Produce::up(Emit::tree());
	} else {
		Produce::inv_primitive(Emit::tree(), UNARYMINUS_BIP);
		Produce::down(Emit::tree());
			@<Emit the X-operand@>;
		Produce::up(Emit::tree());
	}

@ We accomplish powers by repeated multiplication. This is partly because I6
has no "to the power of" function, partly because the powers involved will
always be small, partly because of the need for scaling to come out right.

@<Emit a power of the left operand@> =
	if (use_fp) {
		Produce::inv_call_iname(Emit::tree(), Hierarchy::find(REAL_NUMBER_TY_POW_HL));
		Produce::down(Emit::tree());
			if (promote_X) Kinds::FloatingPoint::begin_flotation_emit(KX);
			@<Emit the X-operand@>;
			if (promote_X) Kinds::FloatingPoint::end_flotation_emit(KX);
			if (promote_Y) Kinds::FloatingPoint::begin_flotation_emit(KY);
			@<Emit the Y-operand@>;
			if (promote_Y) Kinds::FloatingPoint::end_flotation_emit(KY);
		Produce::up(Emit::tree());
	} else {
		int p = 0;
		if (Y) p = Rvalues::to_int(Y);
		else p = Rvalues::to_int(EY->leaf_constant);
		if (p <= 0) Equations::enode_compilation_error(eqn, EY);
		else {
			for (int i=1; i<p; i++) {
				Kinds::Scalings::rescale_multiplication_emit_op(KX, KX);
				Produce::inv_primitive(Emit::tree(), TIMES_BIP);
				Produce::down(Emit::tree());
					@<Emit the X-operand@>;
			}
			@<Emit the X-operand@>;
			for (int i=1; i<p; i++) {
				Produce::up(Emit::tree());
				Kinds::Scalings::rescale_multiplication_emit_factor(KX, KX);
			}
		}
	}

@<Emit function application@> =
	if (use_fp) {
		Produce::inv_primitive(Emit::tree(), INDIRECT1_BIP);
		Produce::down(Emit::tree());
			@<Emit the X-operand@>;
			if (promote_Y) Kinds::FloatingPoint::begin_flotation_emit(KY);
			@<Emit the Y-operand@>;
			if (promote_Y) Kinds::FloatingPoint::end_flotation_emit(KY);
		Produce::up(Emit::tree());
	} else {
		Produce::inv_primitive(Emit::tree(), INDIRECT1_BIP);
		Produce::down(Emit::tree());
			@<Emit the X-operand@>;
			@<Emit the Y-operand@>;
		Produce::up(Emit::tree());
	}

@<Emit the X-operand@> =
	if (X) Specifications::Compiler::emit_to_kind(X, KX); else Equations::enode_compile_by_emission(eqn, EX);

@<Emit the Y-operand@> =
	if (Y) Specifications::Compiler::emit_to_kind(Y, KY); else Equations::enode_compile_by_emission(eqn, EY);

