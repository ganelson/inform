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
	int pointer_on_operand[16];
	int pushed_result;
} C_generation_assembly_data;

void CAssembly::initialise_data(code_generation *gen) {
	C_GEN_DATA(asmdata.operand_count) = 0;
	C_GEN_DATA(asmdata.operand_branches) = FALSE;
	C_GEN_DATA(asmdata.operand_label) = NULL;
	for (int i=0; i<16; i++)
		C_GEN_DATA(asmdata.pointer_on_operand[i]) = FALSE;
	C_GEN_DATA(asmdata.pushed_result) = FALSE;
}

void CAssembly::begin(code_generation *gen) {
	CAssembly::initialise_data(gen);
}

void CAssembly::end(code_generation *gen) {
}


@

= (text to inform7_clib.h)
i7val i7_mgl_sp = 0;
#define I7_ASM_STACK_CAPACITY 128
i7val i7_asm_stack[I7_ASM_STACK_CAPACITY];
int i7_asm_stack_pointer = 0;

i7val i7_pull(void) {
	if (i7_asm_stack_pointer <= 0) { printf("Stack underflow\n"); return (i7val) 0; }
	return i7_asm_stack[--i7_asm_stack_pointer];
}

void i7_push(i7val x) {
	if (i7_asm_stack_pointer >= I7_ASM_STACK_CAPACITY) { printf("Stack overflow\n"); return; }
	i7_asm_stack[i7_asm_stack_pointer++] = x;
}
=

@

=
void CAssembly::begin_opcode(code_generation_target *cgt, code_generation *gen, text_stream *opcode) {
	text_stream *OUT = CodeGen::current(gen);
	C_GEN_DATA(asmdata.operand_branches) = FALSE;
	C_GEN_DATA(asmdata.pushed_result) = FALSE;
	C_GEN_DATA(asmdata.operand_label) = NULL;
	if (Str::get_at(opcode, 1) == 'j') { C_GEN_DATA(asmdata.operand_branches) = TRUE; }
	if (Str::eq(opcode, I"@return")) WRITE("return ");
	else {
		if (C_GEN_DATA(asmdata.operand_branches)) WRITE("if (");
		CNamespace::mangle_opcode(cgt, OUT, opcode);
	}
	WRITE("("); C_GEN_DATA(asmdata.operand_count) = 0;
	for (int i=0; i<16; i++)
		C_GEN_DATA(asmdata.pointer_on_operand[i]) = FALSE;
	if (Str::eq(opcode, I"@acos")) C_GEN_DATA(asmdata.pointer_on_operand[2]) = TRUE;
	if (Str::eq(opcode, I"@add")) C_GEN_DATA(asmdata.pointer_on_operand[3]) = TRUE;
	if (Str::eq(opcode, I"@aload")) C_GEN_DATA(asmdata.pointer_on_operand[3]) = TRUE;
	if (Str::eq(opcode, I"@aloadb")) C_GEN_DATA(asmdata.pointer_on_operand[3]) = TRUE;
	if (Str::eq(opcode, I"@aloads")) C_GEN_DATA(asmdata.pointer_on_operand[3]) = TRUE;
	if (Str::eq(opcode, I"@asin")) C_GEN_DATA(asmdata.pointer_on_operand[2]) = TRUE;
	if (Str::eq(opcode, I"@atan")) C_GEN_DATA(asmdata.pointer_on_operand[2]) = TRUE;
	if (Str::eq(opcode, I"@binarysearch")) C_GEN_DATA(asmdata.pointer_on_operand[8]) = TRUE;
	if (Str::eq(opcode, I"@ceil")) C_GEN_DATA(asmdata.pointer_on_operand[2]) = TRUE;
	if (Str::eq(opcode, I"@cos")) C_GEN_DATA(asmdata.pointer_on_operand[2]) = TRUE;
	if (Str::eq(opcode, I"@div")) C_GEN_DATA(asmdata.pointer_on_operand[3]) = TRUE;
	if (Str::eq(opcode, I"@exp")) C_GEN_DATA(asmdata.pointer_on_operand[2]) = TRUE;
	if (Str::eq(opcode, I"@fadd")) C_GEN_DATA(asmdata.pointer_on_operand[3]) = TRUE;
	if (Str::eq(opcode, I"@fdiv")) C_GEN_DATA(asmdata.pointer_on_operand[3]) = TRUE;
	if (Str::eq(opcode, I"@floor")) C_GEN_DATA(asmdata.pointer_on_operand[2]) = TRUE;
	if (Str::eq(opcode, I"@fmod")) {
		C_GEN_DATA(asmdata.pointer_on_operand[3]) = TRUE;
		C_GEN_DATA(asmdata.pointer_on_operand[4]) = TRUE;
	}
	if (Str::eq(opcode, I"@fmul")) C_GEN_DATA(asmdata.pointer_on_operand[3]) = TRUE;
	if (Str::eq(opcode, I"@fsub")) C_GEN_DATA(asmdata.pointer_on_operand[3]) = TRUE;
	if (Str::eq(opcode, I"@ftonumn")) C_GEN_DATA(asmdata.pointer_on_operand[2]) = TRUE;
	if (Str::eq(opcode, I"@ftonumz")) C_GEN_DATA(asmdata.pointer_on_operand[2]) = TRUE;
	if (Str::eq(opcode, I"@gestalt")) C_GEN_DATA(asmdata.pointer_on_operand[3]) = TRUE;
	if (Str::eq(opcode, I"@glk")) C_GEN_DATA(asmdata.pointer_on_operand[3]) = TRUE;
	if (Str::eq(opcode, I"@log")) C_GEN_DATA(asmdata.pointer_on_operand[2]) = TRUE;
	if (Str::eq(opcode, I"@mod")) C_GEN_DATA(asmdata.pointer_on_operand[3]) = TRUE;
	if (Str::eq(opcode, I"@mul")) C_GEN_DATA(asmdata.pointer_on_operand[3]) = TRUE;
	if (Str::eq(opcode, I"@neg")) C_GEN_DATA(asmdata.pointer_on_operand[2]) = TRUE;
	if (Str::eq(opcode, I"@numtof")) C_GEN_DATA(asmdata.pointer_on_operand[2]) = TRUE;
	if (Str::eq(opcode, I"@pow")) C_GEN_DATA(asmdata.pointer_on_operand[3]) = TRUE;
	if (Str::eq(opcode, I"@shiftl")) C_GEN_DATA(asmdata.pointer_on_operand[3]) = TRUE;
	if (Str::eq(opcode, I"@sin")) C_GEN_DATA(asmdata.pointer_on_operand[2]) = TRUE;
	if (Str::eq(opcode, I"@sqrt")) C_GEN_DATA(asmdata.pointer_on_operand[2]) = TRUE;
	if (Str::eq(opcode, I"@sub")) C_GEN_DATA(asmdata.pointer_on_operand[3]) = TRUE;
	if (Str::eq(opcode, I"@tan")) C_GEN_DATA(asmdata.pointer_on_operand[2]) = TRUE;
}
void CAssembly::supply_operand(code_generation_target *cgt, code_generation *gen, inter_tree_node *F, int is_label) {
	text_stream *OUT = CodeGen::current(gen);
	if (is_label) {
		C_GEN_DATA(asmdata.operand_label) = F;
	} else {
		if (C_GEN_DATA(asmdata.operand_count)++ > 0) WRITE(", ");
		TEMPORARY_TEXT(write_to)
		CodeGen::select_temporary(gen, write_to);
		CodeGen::FC::frame(gen, F);
		CodeGen::deselect_temporary(gen);
		if (C_GEN_DATA(asmdata.pointer_on_operand[C_GEN_DATA(asmdata.operand_count)])) {
			if (Str::eq(write_to, I"i7_mgl_sp")) { WRITE("&%S", write_to); C_GEN_DATA(asmdata.pushed_result) = TRUE; }
			else if (Str::eq(write_to, I"0")) WRITE("NULL");
			else WRITE("&%S", write_to);
		} else {
			if (Str::eq(write_to, I"i7_mgl_sp")) { WRITE("i7_pull()"); }
			else WRITE("%S", write_to);
		}
		DISCARD_TEXT(write_to)
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
	if (C_GEN_DATA(asmdata.pushed_result)) WRITE("; i7_push(i7_mgl_sp)");
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
	if (x == y) return 1;
	return 0;
}

int glulx_jleu(i7val x, i7val y) {
	printf("Unimplemented: glulx_jleu.\n");
	return 0;
}

int glulx_jnz(i7val x) {
	if (x != 0) return 1;
	return 0;
}

int glulx_jz(i7val x) {
	if (x == 0) return 1;
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


void glulx_quit(void) {
	printf("Unimplemented: glulx_quit.\n");
}

void glulx_random(i7val x, i7val y) {
	printf("Unimplemented: glulx_random.\n");
}

void glulx_setiosys(i7val x, i7val y) {
	// Deliberately ignored: we are using stdout, not glk
}

void i7_print_char(i7val x);
void glulx_streamchar(i7val x) {
	i7_print_char(x);
}

void i7_print_decimal(i7val x);
void glulx_streamnum(i7val x) {
	i7_print_decimal(x);
}

void glulx_streamstr(i7val x) {
	printf("Unimplemented: glulx_streamstr.\n");
}

void glulx_streamunichar(i7val x) {
	i7_print_char(x);
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

