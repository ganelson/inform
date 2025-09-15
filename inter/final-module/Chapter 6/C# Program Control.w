[CSProgramControl::] C# Program Control.

Generating C# code to effect loops, branches and the like.

@ This is as good a place as any to provide the general function for compiling
invocations of primitives. There are a lot of primitives, so the actual work is
distributed throughout this chapter.

=
void CSProgramControl::initialise(code_generator *gtr) {
	METHOD_ADD(gtr, INVOKE_PRIMITIVE_MTID, CSProgramControl::invoke_primitive);
}

void CSProgramControl::invoke_primitive(code_generator *gtr, code_generation *gen,
	inter_symbol *prim_name, inter_tree_node *P, int void_context) {
	inter_tree *I = gen->from;
	inter_ti bip = Primitives::to_BIP(I, prim_name);

	int r = CSReferences::invoke_primitive(gen, bip, P);
	if (r == NOT_APPLICABLE) r = CSArithmetic::invoke_primitive(gen, bip, P);
	if (r == NOT_APPLICABLE) r = CSMemoryModel::invoke_primitive(gen, bip, P);
	if (r == NOT_APPLICABLE) r = CSFunctionModel::invoke_primitive(gen, bip, P);
	if (r == NOT_APPLICABLE) r = CSObjectModel::invoke_primitive(gen, bip, P);
	if (r == NOT_APPLICABLE) r = CSInputOutputModel::invoke_primitive(gen, bip, P);
	if (r == NOT_APPLICABLE) r = CSConditions::invoke_primitive(gen, bip, P);
	if (r == NOT_APPLICABLE) r = CSProgramControl::compile_control_primitive(gen, bip, P);
	if ((void_context) && (r == FALSE)) {
		text_stream *OUT = CodeGen::current(gen);
		WRITE(";\n");
	}
}

@ And the rest of this section implements the primitives to do with execution
control: branches, loops and so on.

=
int CSProgramControl::compile_control_primitive(code_generation *gen, inter_ti bip,
	inter_tree_node *P) {
	int suppress_terminal_semicolon = FALSE;
	text_stream *OUT = CodeGen::current(gen);
	inter_tree *I = gen->from;
	switch (bip) {
		case PUSH_BIP:            WRITE("proc.i7_push("); VNODE_1C; WRITE(")"); break;
		case PULL_BIP:            VNODE_1C; WRITE(" = proc.i7_pull()"); break;
		case IF_BIP:              @<Generate primitive for if@>; break;
		case IFDEBUG_BIP:         @<Generate primitive for ifdebug@>; break;
		case IFSTRICT_BIP:        @<Generate primitive for ifstrict@>; break;
		case IFELSE_BIP:          @<Generate primitive for ifelse@>; break;
		case BREAK_BIP:           WRITE("break"); break;
		case CONTINUE_BIP:        WRITE("continue"); break;
		case JUMP_BIP:            WRITE("goto "); VNODE_1C; break;
		case QUIT_BIP:            WRITE("proc.i7_benign_exit()"); break;
		case RESTORE_BIP:         WRITE("proc.i7_opcode_restore(0, NULL)"); break;
		case RETURN_BIP:          WRITE("return System.Convert.ToInt32("); VNODE_1C; WRITE(")"); break;
		case WHILE_BIP:           @<Generate primitive for while@>; break;
		case DO_BIP:              @<Generate primitive for do@>; break;
		case FOR_BIP:             @<Generate primitive for for@>; break;
		case OBJECTLOOP_BIP:      @<Generate primitive for objectloop@>; break;
		case OBJECTLOOPX_BIP:     @<Generate primitive for objectloopx@>; break;
		case SWITCH_BIP:          @<Generate primitive for switch@>; break;
		case CASE_BIP:            @<Generate primitive for case@>; break;
		case DEFAULT_BIP:         @<Generate primitive for default@>; break;
		case ALTERNATIVECASE_BIP: internal_error("misplaced !alternativecase"); break;
		default: internal_error("unimplemented prim");
	}
	return suppress_terminal_semicolon;
}

@<Generate primitive for if@> =
	WRITE("if /*pi*/(System.Convert.ToBoolean("); VNODE_1C; WRITE(")) {\n"); INDENT; VNODE_2C;
	OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for ifdebug@> =
	WRITE("#if DEBUG\n"); INDENT; VNODE_1C; OUTDENT; WRITE("#endif\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for ifstrict@> =
	WRITE("#if STRICT_MODE\n"); INDENT; VNODE_1C; OUTDENT; WRITE("#endif\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for ifelse@> =
	WRITE("if /*pie*/(System.Convert.ToBoolean("); VNODE_1C; WRITE(")) {\n"); INDENT; VNODE_2C; OUTDENT;
	WRITE("} else {\n"); INDENT; VNODE_3C; OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for while@> =
	WRITE("while (System.Convert.ToBoolean("); VNODE_1C; WRITE(")) {\n"); INDENT; VNODE_2C; OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for do@> =
	WRITE("do {"); VNODE_2C; WRITE("} while (!System.Convert.ToBoolean(\n"); INDENT; VNODE_1C; OUTDENT; WRITE("))\n");

@<Generate primitive for for@> =
	WRITE("for (");
	inter_tree_node *INIT = InterTree::first_child(P);
	if (!((Inode::is(INIT, VAL_IST)) &&
		(InterValuePairs::is_number(ValInstruction::value(INIT))) &&
		(InterValuePairs::to_number(ValInstruction::value(INIT)) == 1)))
			VNODE_1C;
	WRITE(";System.Convert.ToBoolean("); VNODE_2C;
	WRITE(");");
	inter_tree_node *U = InterTree::third_child(P);
	if (Inode::isnt(U, VAL_IST))
	Vanilla::node(gen, U);
	WRITE(") {\n"); INDENT; VNODE_4C;
	OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for objectloop@> =
	int in_flag = FALSE;
	inter_tree_node *U = InterTree::third_child(P);
	if ((Inode::is(U, INV_IST)) &&
		(InvInstruction::method(U) == PRIMITIVE_INVMETH)) {
		inter_symbol *prim = InvInstruction::primitive(U);
		if ((prim) && (Primitives::to_BIP(I, prim) == IN_BIP)) in_flag = TRUE;
	}

	WRITE("for ("); VNODE_1C;
	WRITE(" = 1; "); VNODE_1C;
	WRITE(" < i7_max_objects; "); VNODE_1C;
	WRITE("++) ");
	if (in_flag == FALSE) {
		WRITE("if (System.Convert.ToBoolean(proc.i7_ofclass("); VNODE_1C; WRITE(", "); VNODE_2C; WRITE("))) ");
	}
	WRITE("if /*ol*/(System.Convert.ToBoolean(");
	VNODE_3C;
	WRITE(")) {\n"); INDENT; VNODE_4C;
	OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for objectloopx@> =
	WRITE("for ("); VNODE_1C;
	WRITE(" = 1; "); VNODE_1C;
	WRITE(" < i7_max_objects; "); VNODE_1C;
	WRITE("++) ");
	WRITE("if (System.Convert.ToBoolean(proc.i7_ofclass("); VNODE_1C; WRITE(", "); VNODE_2C; WRITE("))) ");
	WRITE(" {\n"); INDENT; VNODE_3C;
	OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for switch@> =
	WRITE("switch ("); VNODE_1C;
	WRITE(") {\n"); INDENT; VNODE_2C; OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@ TODO Inter permits multiple match values to be supplied for a single case in a
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
	CSProgramControl::caser(gen,  InterTree::first_child(P));
	INDENT; VNODE_2C; WRITE(";\n"); WRITE("break;\n"); OUTDENT;
	suppress_terminal_semicolon = TRUE;

@ =
void CSProgramControl::caser(code_generation *gen, inter_tree_node *X) {
	if (Inode::is(X, INV_IST)) {
		if (InvInstruction::method(X) == PRIMITIVE_INVMETH) {
			inter_symbol *prim = InvInstruction::primitive(X);
			inter_ti xbip = Primitives::to_BIP(gen->from, prim);
			if (xbip == ALTERNATIVECASE_BIP) {
				CSProgramControl::caser(gen, InterTree::first_child(X));
				CSProgramControl::caser(gen, InterTree::second_child(X));
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
