[CProgramControl::] C Program Control.

Generating C code to effect loops, branches and the like.

@ This is as good a place as any to provide the general function for compiling
invocations of primitives. There are a lot of primitives, so the actual work is
distributed throughout this chapter.

=
void CProgramControl::initialise(code_generator *gtr) {
	METHOD_ADD(gtr, INVOKE_PRIMITIVE_MTID, CProgramControl::invoke_primitive);
}

void CProgramControl::invoke_primitive(code_generator *gtr, code_generation *gen,
	inter_symbol *prim_name, inter_tree_node *P, int void_context) {
	inter_tree *I = gen->from;
	inter_ti bip = Primitives::to_bip(I, prim_name);

	int r = CReferences::invoke_primitive(gen, bip, P);
	if (r == NOT_APPLICABLE) r = CArithmetic::invoke_primitive(gen, bip, P);
	if (r == NOT_APPLICABLE) r = CMemoryModel::invoke_primitive(gen, bip, P);
	if (r == NOT_APPLICABLE) r = CFunctionModel::invoke_primitive(gen, bip, P);
	if (r == NOT_APPLICABLE) r = CObjectModel::invoke_primitive(gen, bip, P);
	if (r == NOT_APPLICABLE) r = CInputOutputModel::invoke_primitive(gen, bip, P);
	if (r == NOT_APPLICABLE) r = CConditions::invoke_primitive(gen, bip, P);
	if (r == NOT_APPLICABLE) r = CProgramControl::compile_control_primitive(gen, bip, P);
	if ((void_context) && (r == FALSE)) {
		text_stream *OUT = CodeGen::current(gen);
		WRITE(";\n");
	}
}

@ And the rest of this section implements the primitives to do with execution
control: branches, loops and so on.

=
int CProgramControl::compile_control_primitive(code_generation *gen, inter_ti bip,
	inter_tree_node *P) {
	int suppress_terminal_semicolon = FALSE;
	text_stream *OUT = CodeGen::current(gen);
	inter_tree *I = gen->from;
	switch (bip) {
		case PUSH_BIP:            WRITE("i7_push(proc, "); VNODE_1C; WRITE(")"); break;
		case PULL_BIP:            VNODE_1C; WRITE(" = i7_pull(proc)"); break;
		case IF_BIP:              @<Generate primitive for if@>; break;
		case IFDEBUG_BIP:         @<Generate primitive for ifdebug@>; break;
		case IFSTRICT_BIP:        @<Generate primitive for ifstrict@>; break;
		case IFELSE_BIP:          @<Generate primitive for ifelse@>; break;
		case BREAK_BIP:           WRITE("break"); break;
		case CONTINUE_BIP:        WRITE("continue"); break;
		case JUMP_BIP:            WRITE("goto "); VNODE_1C; break;
		case QUIT_BIP:            WRITE("i7_benign_exit(proc)"); break;
		case RESTORE_BIP:         WRITE("i7_opcode_restore(proc, 0, NULL)"); break;
		case RETURN_BIP:          WRITE("return (i7word_t) "); VNODE_1C; break;
		case WHILE_BIP:           @<Generate primitive for while@>; break;
		case DO_BIP:              @<Generate primitive for do@>; break;
		case FOR_BIP:             @<Generate primitive for for@>; break;
		case OBJECTLOOP_BIP:      @<Generate primitive for objectloop@>; break;
		case OBJECTLOOPX_BIP:     @<Generate primitive for objectloopx@>; break;
		case LOOP_BIP:            @<Generate primitive for loop@>; break;
		case SWITCH_BIP:          @<Generate primitive for switch@>; break;
		case CASE_BIP:            @<Generate primitive for case@>; break;
		case DEFAULT_BIP:         @<Generate primitive for default@>; break;
		case ALTERNATIVECASE_BIP: internal_error("misplaced !alternativecase"); break;
		default: internal_error("unimplemented prim");
	}
	return suppress_terminal_semicolon;
}

@<Generate primitive for if@> =
	WRITE("if ("); VNODE_1C; WRITE(") {\n"); INDENT; VNODE_2C;
	OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for ifdebug@> =
	WRITE("#ifdef DEBUG\n"); INDENT; VNODE_1C; OUTDENT; WRITE("#endif\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for ifstrict@> =
	WRITE("#ifdef STRICT_MODE\n"); INDENT; VNODE_1C; OUTDENT; WRITE("#endif\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for ifelse@> =
	WRITE("if ("); VNODE_1C; WRITE(") {\n"); INDENT; VNODE_2C; OUTDENT;
	WRITE("} else {\n"); INDENT; VNODE_3C; OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for while@> =
	WRITE("while ("); VNODE_1C; WRITE(") {\n"); INDENT; VNODE_2C; OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for do@> =
	WRITE("do {"); VNODE_2C; WRITE("} while (!(\n"); INDENT; VNODE_1C; OUTDENT; WRITE("))\n");

@<Generate primitive for for@> =
	WRITE("for (");
	inter_tree_node *INIT = InterTree::first_child(P);
	if (!((INIT->W.data[ID_IFLD] == VAL_IST) &&
		(INIT->W.data[VAL1_VAL_IFLD] == LITERAL_IVAL) &&
		(INIT->W.data[VAL2_VAL_IFLD] == 1))) VNODE_1C;
	WRITE(";"); VNODE_2C;
	WRITE(";");
	inter_tree_node *U = InterTree::third_child(P);
	if (U->W.data[ID_IFLD] != VAL_IST)
	Vanilla::node(gen, U);
	WRITE(") {\n"); INDENT; VNODE_4C;
	OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for objectloop@> =
	int in_flag = FALSE;
	inter_tree_node *U = InterTree::third_child(P);
	if ((U->W.data[ID_IFLD] == INV_IST) &&
		(U->W.data[METHOD_INV_IFLD] == INVOKED_PRIMITIVE)) {
		inter_symbol *prim = Inter::Inv::invokee(U);
		if ((prim) && (Primitives::to_bip(I, prim) == IN_BIP)) in_flag = TRUE;
	}

	WRITE("for (i7word_t "); VNODE_1C;
	WRITE(" = 1; "); VNODE_1C;
	WRITE(" < i7_max_objects; "); VNODE_1C;
	WRITE("++) ");
	if (in_flag == FALSE) {
		WRITE("if (i7_ofclass(proc, "); VNODE_1C; WRITE(", "); VNODE_2C; WRITE(")) ");
	}
	WRITE("if (");
	VNODE_3C;
	WRITE(") {\n"); INDENT; VNODE_4C;
	OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for objectloopx@> =
	WRITE("for (i7word_t "); VNODE_1C;
	WRITE(" = 1; "); VNODE_1C;
	WRITE(" < i7_max_objects; "); VNODE_1C;
	WRITE("++) ");
	WRITE("if (i7_ofclass(proc, "); VNODE_1C; WRITE(", "); VNODE_2C; WRITE(")) ");
	WRITE(" {\n"); INDENT; VNODE_3C;
	OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for loop@> =
	WRITE("{\n"); INDENT; VNODE_1C; OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for switch@> =
	WRITE("switch ("); VNODE_1C;
	WRITE(") {\n"); INDENT; VNODE_2C; OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@ Inter permits multiple match values to be supplied for a single case in a
|!switch| primitive: but C does not allow this for its keyword |case|, so we
have to recurse downwards through the possibilities and preface each one by
|case:|. For example,
= (text as Inter)
	inv !switch
		inv !alternativecase
			val K_number 3
			val K_number 7
		...
=
becomes |case 3: case 7:|.

@<Generate primitive for case@> =
	CProgramControl::caser(gen,  InterTree::first_child(P));
	INDENT; VNODE_2C; WRITE(";\n"); WRITE("break;\n"); OUTDENT;
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
	Vanilla::node(gen, X);
	WRITE(": ");
}

@<Generate primitive for default@> =
	WRITE("default:\n"); INDENT; VNODE_1C; WRITE(";\n"); WRITE("break;\n"); OUTDENT;
	suppress_terminal_semicolon = TRUE;
