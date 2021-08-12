[CAssembly::] C Assembly.

The problem of assembly language.

@

=
void CAssembly::initialise(code_generation_target *cgt) {
	METHOD_ADD(cgt, BEGIN_OPCODE_MTID, CAssembly::begin_opcode);
	METHOD_ADD(cgt, SUPPLY_OPERAND_MTID, CAssembly::supply_operand);
	METHOD_ADD(cgt, END_OPCODE_MTID, CAssembly::end_opcode);
}

typedef struct C_generation_assembly_data {
	int operand_count;
	int operand_branches;
	struct inter_tree_node *operand_label;
	int pointer_on_operand;
} C_generation_assembly_data;

void CAssembly::initialise_data(code_generation *gen) {
	C_GEN_DATA(asmdata.operand_count) = 0;
	C_GEN_DATA(asmdata.operand_branches) = FALSE;
	C_GEN_DATA(asmdata.operand_label) = NULL;
	C_GEN_DATA(asmdata.pointer_on_operand) = -1;
}

void CAssembly::begin(code_generation *gen) {
	CAssembly::initialise_data(gen);
}

void CAssembly::end(code_generation *gen) {
}


@

= (text to inform7_clib.h)
i7val i7_mgl_sp = 0;

i7val i7_pull(void) {
	printf("Unimplemented: i7_pull.\n");
	return (i7val) 0;
}

void i7_push(i7val x) {
	printf("Unimplemented: i7_push.\n");
}
=

@

=
void CAssembly::begin_opcode(code_generation_target *cgt, code_generation *gen, text_stream *opcode) {
	text_stream *OUT = CodeGen::current(gen);
	C_GEN_DATA(asmdata.operand_branches) = FALSE;
	C_GEN_DATA(asmdata.operand_label) = NULL;
	if (Str::get_at(opcode, 1) == 'j') { C_GEN_DATA(asmdata.operand_branches) = TRUE; }
	if (Str::eq(opcode, I"@return")) WRITE("return ");
	else {
		if (C_GEN_DATA(asmdata.operand_branches)) WRITE("if (");
		CNamespace::mangle_opcode(cgt, OUT, opcode);
	}
	WRITE("("); C_GEN_DATA(asmdata.operand_count) = 0;
	C_GEN_DATA(asmdata.pointer_on_operand) = -1;
	if (Str::eq(opcode, I"@acos")) C_GEN_DATA(asmdata.pointer_on_operand) = 2;
	if (Str::eq(opcode, I"@aload")) C_GEN_DATA(asmdata.pointer_on_operand) = 3;
	if (Str::eq(opcode, I"@aloadb")) C_GEN_DATA(asmdata.pointer_on_operand) = 3;
	if (Str::eq(opcode, I"@aloads")) C_GEN_DATA(asmdata.pointer_on_operand) = 3;
	if (Str::eq(opcode, I"@asin")) C_GEN_DATA(asmdata.pointer_on_operand) = 2;
	if (Str::eq(opcode, I"@atan")) C_GEN_DATA(asmdata.pointer_on_operand) = 2;
	if (Str::eq(opcode, I"@binarysearch")) C_GEN_DATA(asmdata.pointer_on_operand) = 8;
	if (Str::eq(opcode, I"@ceil")) C_GEN_DATA(asmdata.pointer_on_operand) = 2;
	if (Str::eq(opcode, I"@cos")) C_GEN_DATA(asmdata.pointer_on_operand) = 2;
	if (Str::eq(opcode, I"@gestalt")) C_GEN_DATA(asmdata.pointer_on_operand) = 3;
	if (Str::eq(opcode, I"@glk")) C_GEN_DATA(asmdata.pointer_on_operand) = 3;
	if (Str::eq(opcode, I"@pow")) C_GEN_DATA(asmdata.pointer_on_operand) = 3;
	if (Str::eq(opcode, I"@shiftl")) C_GEN_DATA(asmdata.pointer_on_operand) = 3;
	if (Str::eq(opcode, I"@sin")) C_GEN_DATA(asmdata.pointer_on_operand) = 2;
	if (Str::eq(opcode, I"@sqrt")) C_GEN_DATA(asmdata.pointer_on_operand) = 2;
	if (Str::eq(opcode, I"@tan")) C_GEN_DATA(asmdata.pointer_on_operand) = 2;
}
void CAssembly::supply_operand(code_generation_target *cgt, code_generation *gen, inter_tree_node *F, int is_label) {
	text_stream *OUT = CodeGen::current(gen);
	if (is_label) {
		C_GEN_DATA(asmdata.operand_label) = F;
	} else {
		if (C_GEN_DATA(asmdata.operand_count)++ > 0) WRITE(", ");
		if (C_GEN_DATA(asmdata.operand_count) == C_GEN_DATA(asmdata.pointer_on_operand)) {
			TEMPORARY_TEXT(write_to)
			CodeGen::select_temporary(gen, write_to);
			CodeGen::FC::frame(gen, F);
			CodeGen::deselect_temporary(gen);
			if (Str::eq(write_to, I"0")) WRITE("NULL");
			else WRITE("&%S", write_to);
			DISCARD_TEXT(write_to)
		} else {
			CodeGen::FC::frame(gen, F);
		}
	}
}
void CAssembly::end_opcode(code_generation_target *cgt, code_generation *gen) {
	text_stream *OUT = CodeGen::current(gen);
	WRITE(")");
	if (C_GEN_DATA(asmdata.operand_branches)) {
		if (negate_label_mode) WRITE(" == FALSE");
		WRITE(") goto ");
		if (C_GEN_DATA(asmdata.operand_label) == NULL) internal_error("no branch label");
		CodeGen::FC::frame(gen, C_GEN_DATA(asmdata.operand_label));
	}
}

@

= (text to inform7_clib.h)
void glulx_accelfunc(i7val x, i7val y) {
	printf("Unimplemented: glulx_accelfunc.\n");
}

void glulx_accelparam(i7val x, i7val y) {
	printf("Unimplemented: glulx_accelparam.\n");
}

void glulx_call(i7val x, i7val i7varargc, i7val z) {
	printf("Unimplemented: glulx_call.\n");
}

void glulx_copy(i7val x, i7val y) {
	printf("Unimplemented: glulx_copy.\n");
}

void glulx_div(i7val x, i7val y, i7val z) {
	printf("Unimplemented: glulx_div.\n");
}

void glulx_gestalt(i7val x, i7val y, i7val *z) {
	*z = 1;
}

void glulx_glk(i7val glk_api_selector, i7val i7varargc, i7val *z) {
	int rv = 0;
	switch (glk_api_selector) {
		case 4: // selectpr for glk_gestalt
			rv = 1; break;
		case 32: // selector for glk_window_iterate
			rv = 0; break;
		case 35: // selector for glk_window_open
			rv = 1; break;
		case 47: // selector for glk_set_window
			rv = 0; break;
		case 64: // selector for glk_stream_iterate
			rv = 0; break;
		case 100: // selector for glk_fileref_iterate
			rv = 0; break;
		case 176: // selector for glk_stylehint_set
			rv = 0; break;
		case 240: // selector for glk_schannel_iterate
			rv = 0; break;
		case 242: // selector for glk_schannel_create
			rv = 0; break;
		default:
			printf("Unimplemented: glulx_glk %d.\n", glk_api_selector);
			rv = 0; break;
	}
	if (z) *z = rv;
}

int glulx_jeq(i7val x, i7val y) {
	printf("Unimplemented: glulx_jeq.\n");
	return 0;
}

int glulx_jleu(i7val x, i7val y) {
	printf("Unimplemented: glulx_jleu.\n");
	return 0;
}

int glulx_jnz(i7val x) {
	printf("Unimplemented: glulx_jnz.\n");
	return 0;
}

int glulx_jz(i7val x) {
	printf("Unimplemented: glulx_jz.\n");
	return 0;
}

void glulx_malloc(i7val x, i7val y) {
	printf("Unimplemented: glulx_malloc.\n");
}

void glulx_mcopy(i7val x, i7val y, i7val z) {
	printf("Unimplemented: glulx_mcopy.\n");
}

void glulx_mfree(i7val x) {
	printf("Unimplemented: glulx_mfree.\n");
}

void glulx_mod(i7val x, i7val y, i7val z) {
	printf("Unimplemented: glulx_mod.\n");
}

void glulx_neg(i7val x, i7val y) {
	printf("Unimplemented: glulx_neg.\n");
}

void glulx_numtof(i7val x, i7val y) {
	printf("Unimplemented: glulx_numtof.\n");
}

void glulx_quit(void) {
	printf("Unimplemented: glulx_quit.\n");
}

void glulx_random(i7val x, i7val y) {
	printf("Unimplemented: glulx_random.\n");
}

void glulx_setiosys(i7val x, i7val y) {
	// Deliberately ignored: we are using stdout, not glk
}

void glulx_streamchar(i7val x) {
	printf("%c", (int) x);
}

void glulx_streamnum(i7val x) {
	printf("Unimplemented: glulx_streamnum.\n");
}

void glulx_streamstr(i7val x) {
	printf("Unimplemented: glulx_streamstr.\n");
}

void glulx_streamunichar(i7val x) {
	printf("%c", (int) x);
}

void glulx_sub(i7val x, i7val y, i7val z) {
	printf("Unimplemented: glulx_sub.\n");
}

void glulx_ushiftr(i7val x, i7val y, i7val z) {
	printf("Unimplemented: glulx_ushiftr.\n");
}

void glulx_aload(i7val x, i7val y, i7val *z) {
	printf("Unimplemented: glulx_aload\n");
}

void glulx_aloadb(i7val x, i7val y, i7val *z) {
	printf("Unimplemented: glulx_aloadb\n");
}

void glulx_aloads(i7val x, i7val y, i7val *z) {
	printf("Unimplemented: glulx_aloads\n");
}

void glulx_binarysearch(i7val l1, i7val l2, i7val l3, i7val l4, i7val l5, i7val l6, i7val l7, i7val *s1) {
	printf("Unimplemented: glulx_binarysearch\n");
}

void glulx_shiftl(i7val x, i7val y, i7val *z) {
	printf("Unimplemented: glulx_shiftl\n");
}
=

