[CProgramControl::] C Program Control.

Generating C code to effect loops, branches and the like.

@

=
void CProgramControl::initialise(code_generation_target *cgt) {
	METHOD_ADD(c_target, COMPILE_PRIMITIVE_MTID, CProgramControl::compile_primitive);
}

int CProgramControl::compile_primitive(code_generation_target *cgt, code_generation *gen,
	inter_symbol *prim_name, inter_tree_node *P) {
	inter_tree *I = gen->from;
	inter_ti bip = Primitives::to_bip(I, prim_name);

	int r = CReferences::compile_primitive(gen, bip, P);
	if (r != NOT_APPLICABLE) return r;
	r = CArithmetic::compile_primitive(gen, bip, P);
	if (r != NOT_APPLICABLE) return r;
	r = CMemoryModel::compile_primitive(gen, bip, P);
	if (r != NOT_APPLICABLE) return r;
	r = CObjectModel::compile_primitive(gen, bip, P);
	if (r != NOT_APPLICABLE) return r;
	r = CLiteralsModel::compile_primitive(gen, bip, P);
	if (r != NOT_APPLICABLE) return r;
	r = CInputOutputModel::compile_primitive(gen, bip, P);
	if (r != NOT_APPLICABLE) return r;
	r = CConditions::compile_primitive(gen, bip, P);
	if (r != NOT_APPLICABLE) return r;
	return CProgramControl::compile_control_primitive(gen, bip, P);
}

int CProgramControl::compile_control_primitive(code_generation *gen, inter_ti bip, inter_tree_node *P) {
	int suppress_terminal_semicolon = FALSE;
	text_stream *OUT = CodeGen::current(gen);
	inter_tree *I = gen->from;
	switch (bip) {
		case PUSH_BIP:			WRITE("i7_push("); INV_A1; WRITE(")"); break;
		case PULL_BIP:			INV_A1; WRITE(" = i7_pull()"); break;
		case BREAK_BIP:			WRITE("break"); break;
		case CONTINUE_BIP:		WRITE("continue"); break;
		case RETURN_BIP: 		@<Generate primitive for return@>; break;
		case JUMP_BIP: 			WRITE("goto "); INV_A1; break;
		case QUIT_BIP: 			WRITE("exit(0)"); break;
		case RESTORE_BIP: 		break; /* we won't support this in C */

		case INDIRECT0_BIP: case INDIRECT0V_BIP:
								WRITE("i7_call_0("); INV_A1; WRITE(")"); break;
		case INDIRECT1_BIP: case INDIRECT1V_BIP:
								WRITE("i7_call_1("); INV_A1; WRITE(", ");
								INV_A2; WRITE(")"); break;
		case INDIRECT2_BIP: case INDIRECT2V_BIP:
								WRITE("i7_call_2("); INV_A1; WRITE(", ");
								INV_A2; WRITE(", "); INV_A3; WRITE(")"); break;
		case INDIRECT3_BIP: case INDIRECT3V_BIP:
								WRITE("i7_call_3("); INV_A1; WRITE(", ");
								INV_A2; WRITE(", "); INV_A3; WRITE(", "); INV_A4; WRITE(")"); break;
		case INDIRECT4_BIP: case INDIRECT4V_BIP:
								WRITE("i7_call_4("); INV_A1; WRITE(", ");
								INV_A2; WRITE(", "); INV_A3; WRITE(", "); INV_A4; WRITE(", ");
								INV_A5; WRITE(")"); break;
		case INDIRECT5_BIP: case INDIRECT5V_BIP:
								WRITE("i7_call_5("); INV_A1; WRITE(", ");
								INV_A2; WRITE(", "); INV_A3; WRITE(", "); INV_A4; WRITE(", ");
								INV_A5; WRITE(", "); INV_A6; WRITE(")"); break;
		case CALLMESSAGE0_BIP: 	WRITE("i7_ccall_0("); INV_A1; WRITE(")"); break;
		case CALLMESSAGE1_BIP: 	WRITE("i7_ccall_1("); INV_A1; WRITE(", ");
								INV_A2; WRITE(")"); break;
		case CALLMESSAGE2_BIP: 	WRITE("i7_ccall_2("); INV_A1; WRITE(", ");
								INV_A2; WRITE(", "); INV_A3; WRITE(")"); break;
		case CALLMESSAGE3_BIP: 	WRITE("i7_ccall_3("); INV_A1; WRITE(", ");
								INV_A2; WRITE(", "); INV_A3; WRITE(", "); INV_A4; WRITE(")"); break;

		case IF_BIP: @<Generate primitive for if@>; break;
		case IFDEBUG_BIP: @<Generate primitive for ifdebug@>; break;
		case IFSTRICT_BIP: @<Generate primitive for ifstrict@>; break;
		case IFELSE_BIP: @<Generate primitive for ifelse@>; break;
		case WHILE_BIP: @<Generate primitive for while@>; break;
		case DO_BIP: @<Generate primitive for do@>; break;
		case FOR_BIP: @<Generate primitive for for@>; break;
		case OBJECTLOOP_BIP: @<Generate primitive for objectloop@>; break;
		case OBJECTLOOPX_BIP: @<Generate primitive for objectloopx@>; break;
		case LOOP_BIP: @<Generate primitive for loop@>; break;
		case SWITCH_BIP: @<Generate primitive for switch@>; break;
		case CASE_BIP: @<Generate primitive for case@>; break;
		case ALTERNATIVECASE_BIP: INV_A1; WRITE(", "); INV_A2; break;
		case DEFAULT_BIP: @<Generate primitive for default@>; break;

		default: internal_error("unimplemented prim");
	}
	return suppress_terminal_semicolon;
}

@<Generate primitive for return@> =
	int rboolean = NOT_APPLICABLE;
	inter_tree_node *V = InterTree::first_child(P);
	if (V->W.data[ID_IFLD] == VAL_IST) {
		inter_ti val1 = V->W.data[VAL1_VAL_IFLD];
		inter_ti val2 = V->W.data[VAL2_VAL_IFLD];
		if (val1 == LITERAL_IVAL) {
			if (val2 == 0) rboolean = FALSE;
			if (val2 == 1) rboolean = TRUE;
		}
	}
	switch (rboolean) {
		case FALSE: WRITE("return 0"); break;
		case TRUE: WRITE("return 1"); break;
		case NOT_APPLICABLE: WRITE("return (i7val) "); CodeGen::FC::frame(gen, V); break;
	}

@<Generate primitive for if@> =
	WRITE("if ("); INV_A1; WRITE(") {\n"); INDENT; INV_A2;
	OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for ifdebug@> =
	WRITE("#ifdef DEBUG\n"); INDENT; INV_A1; OUTDENT; WRITE("#endif\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for ifstrict@> =
	WRITE("#ifdef STRICT_MODE\n"); INDENT; INV_A1; OUTDENT; WRITE("#endif\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for ifelse@> =
	WRITE("if ("); INV_A1; WRITE(") {\n"); INDENT; INV_A2; OUTDENT;
	WRITE("} else {\n"); INDENT; INV_A3; OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for while@> =
	WRITE("while ("); INV_A1; WRITE(") {\n"); INDENT; INV_A2; OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for do@> =
	WRITE("do {"); INV_A2; WRITE("} until (\n"); INDENT; INV_A1; OUTDENT; WRITE(")\n");

@<Generate primitive for for@> =
	WRITE("for (");
	inter_tree_node *INIT = InterTree::first_child(P);
	if (!((INIT->W.data[ID_IFLD] == VAL_IST) && (INIT->W.data[VAL1_VAL_IFLD] == LITERAL_IVAL) && (INIT->W.data[VAL2_VAL_IFLD] == 1))) INV_A1;
	WRITE(";"); INV_A2;
	WRITE(";");
	inter_tree_node *U = InterTree::third_child(P);
	if (U->W.data[ID_IFLD] != VAL_IST)
	CodeGen::FC::frame(gen, U);
	WRITE(") {\n"); INDENT; INV_A4;
	OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for objectloop@> =
	int in_flag = FALSE;
	inter_tree_node *U = InterTree::third_child(P);
	if ((U->W.data[ID_IFLD] == INV_IST) && (U->W.data[METHOD_INV_IFLD] == INVOKED_PRIMITIVE)) {
		inter_symbol *prim = Inter::Inv::invokee(U);
		if ((prim) && (Primitives::to_bip(I, prim) == IN_BIP)) in_flag = TRUE;
	}

	WRITE("for (i7val "); INV_A1;
	WRITE(" = 1; "); INV_A1;
	WRITE(" < i7_max_objects; "); INV_A1;
	WRITE("++) ");
	if (in_flag == FALSE) {
		WRITE("if (i7_ofclass("); INV_A1; WRITE(", "); INV_A2; WRITE(")) ");
	}
	WRITE("if (");
	INV_A3;
	WRITE(") {\n"); INDENT; INV_A4;
	OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for objectloopx@> =
	WRITE("for (i7val "); INV_A1;
	WRITE(" = 1; "); INV_A1;
	WRITE(" < i7_max_objects; "); INV_A1;
	WRITE("++) ");
	WRITE("if (i7_ofclass("); INV_A1; WRITE(", "); INV_A2; WRITE(")) ");
	WRITE(" {\n"); INDENT; INV_A3;
	OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for loop@> =
	WRITE("{\n"); INDENT; INV_A1; OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for switch@> =
	WRITE("switch ("); INV_A1;
	WRITE(") {\n"); INDENT; INV_A2; OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for case@> =
	CProgramControl::caser(gen,  InterTree::first_child(P));
	INDENT; INV_A2; WRITE(";\n"); WRITE("break;\n"); OUTDENT;
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for default@> =
	WRITE("default:\n"); INDENT; INV_A1; WRITE(";\n"); WRITE("break;\n"); OUTDENT;
	suppress_terminal_semicolon = TRUE;

@ =
void CProgramControl::caser(code_generation *gen, inter_tree_node *X) {
	if (X->W.data[ID_IFLD] == INV_IST) {
		if (X->W.data[METHOD_INV_IFLD] == INVOKED_PRIMITIVE) {
			inter_symbol *prim = Inter::Inv::invokee(X);
			inter_ti xbip = Primitives::to_bip(gen->from, prim);
			if (xbip == ALTERNATIVECASE_BIP) {
				CProgramControl::caser(gen, InterTree::first_child(X));
				CProgramControl::caser(gen, InterTree::second_child(X));
				return;
			}
		}
	}
	text_stream *OUT = CodeGen::current(gen);
	WRITE("case ");
	CodeGen::FC::frame(gen, X);
	WRITE(": ");
}
