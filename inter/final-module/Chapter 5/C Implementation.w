[CTarget::] C Implementation.

To generate I6 code from intermediate code.

@h Target.

= (text to inform7_clib.h)
#include <stdlib.h>
#include <stdio.h>

typedef struct i7varargs {
	i7val args[10];
} i7varargs;

i7val i7_mgl_self = 0;
i7val i7_mgl_sp = 0;
#define i7_mgl_Grammar__Version 2
i7val i7_mgl_debug_flag = 0;

i7val i7_tmp = 0;
int i7_seed = 197;

#define i7_cpv_SET 1
#define i7_cpv_PREDEC 2
#define i7_cpv_POSTDEC 3
#define i7_cpv_PREINC 4
#define i7_cpv_POSTINC 5

#define I7BYTE_3(V) ((V & 0xFF000000) >> 24)
#define I7BYTE_2(V) ((V & 0x00FF0000) >> 16)
#define I7BYTE_1(V) ((V & 0x0000FF00) >> 8)
#define I7BYTE_0(V) (V & 0x000000FF)

i7val i7_lookup(i7byte i7bytes[], i7val offset, i7val ind) {
	ind = offset + 4*ind;
	return ((i7val) i7bytes[ind]) + 0x100*((i7val) i7bytes[ind+1]) +
		0x10000*((i7val) i7bytes[ind+2]) + 0x1000000*((i7val) i7bytes[ind+3]);
}

i7val write_i7_lookup(i7byte i7bytes[], i7val offset, i7val ind, i7val V, int way) {
	i7val val = i7_lookup(i7bytes, offset, ind);
	i7val RV = V;
	switch (way) {
		case i7_cpv_PREDEC:  RV = val; V = val-1; break;
		case i7_cpv_POSTDEC: RV = val-1; V = val-1; break;
		case i7_cpv_PREINC:  RV = val; V = val+1; break;
		case i7_cpv_POSTINC: RV = val+1; V = val+1; break;
	}
	ind = offset + 4*ind;
	i7bytes[ind]   = I7BYTE_0(V);
	i7bytes[ind+1] = I7BYTE_1(V);
	i7bytes[ind+2] = I7BYTE_2(V);
	i7bytes[ind+3] = I7BYTE_3(V);
	return RV;
}

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

void glulx_exp(i7val x, i7val y) {
	printf("Unimplemented: glulx_exp.\n");
}

void glulx_fadd(i7val x, i7val y, i7val z) {
	printf("Unimplemented: glulx_fadd.\n");
}

void glulx_fdiv(i7val x, i7val y, i7val z) {
	printf("Unimplemented: glulx_fdiv.\n");
}

void glulx_floor(i7val x, i7val y) {
	printf("Unimplemented: glulx_floor.\n");
}

void glulx_fmod(i7val x, i7val y, i7val z, i7val w) {
	printf("Unimplemented: glulx_fmod.\n");
}

void glulx_fmul(i7val x, i7val y, i7val z) {
	printf("Unimplemented: glulx_fmul.\n");
}

void glulx_fsub(i7val x, i7val y, i7val z) {
	printf("Unimplemented: glulx_fsub.\n");
}

void glulx_ftonumn(i7val x, i7val y) {
	printf("Unimplemented: glulx_ftonumn.\n");
}

void glulx_ftonumz(i7val x, i7val y) {
	printf("Unimplemented: glulx_ftonumz.\n");
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

int glulx_jfeq(i7val x, i7val y, i7val z) {
	printf("Unimplemented: glulx_jfeq.\n");
	return 0;
}

int glulx_jfge(i7val x, i7val y) {
	printf("Unimplemented: glulx_jfge.\n");
	return 0;
}

int glulx_jflt(i7val x, i7val y) {
	printf("Unimplemented: glulx_jflt.\n");
	return 0;
}

int glulx_jisinf(i7val x) {
	printf("Unimplemented: glulx_jisinf.\n");
	return 0;
}

int glulx_jisnan(i7val x) {
	printf("Unimplemented: glulx_jisnan.\n");
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

void glulx_log(i7val x, i7val y) {
	printf("Unimplemented: glulx_log.\n");
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

void glulx_setrandom(i7val x) {
	i7_seed = (int) x;
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

void glulx_acos(i7val x, i7val *y) {
	printf("Unimplemented: glulx_acos\n");
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

void glulx_asin(i7val x, i7val *y) {
	printf("Unimplemented: glulx_asin\n");
}

void glulx_atan(i7val x, i7val *y) {
	printf("Unimplemented: glulx_atan\n");
}

void glulx_binarysearch(i7val l1, i7val l2, i7val l3, i7val l4, i7val l5, i7val l6, i7val l7, i7val *s1) {
	printf("Unimplemented: glulx_binarysearch\n");
}

void glulx_ceil(i7val x, i7val *y) {
	printf("Unimplemented: glulx_ceil\n");
}

void glulx_cos(i7val x, i7val *y) {
	printf("Unimplemented: glulx_cos\n");
}

void glulx_pow(i7val x, i7val y, i7val *z) {
	printf("Unimplemented: glulx_pow\n");
}

void glulx_shiftl(i7val x, i7val y, i7val *z) {
	printf("Unimplemented: glulx_shiftl\n");
}

void glulx_sin(i7val x, i7val *y) {
	printf("Unimplemented: glulx_sin\n");
}

void glulx_sqrt(i7val x, i7val *y) {
	printf("Unimplemented: glulx_sqrt\n");
}

void glulx_tan(i7val x, i7val *y) {
	printf("Unimplemented: glulx_tan\n");
}



int i7_has(i7val obj, i7val attr) {
	printf("Unimplemented: i7_has.\n");
	return 0;
}

void i7_print_address(i7val x) {
	printf("Unimplemented: i7_print_address.\n");
}

void i7_print_char(i7val x) {
	printf("%c", (int) x);
}

void i7_print_def_art(i7val x) {
	printf("Unimplemented: i7_print_def_art.\n");
}

void i7_print_cdef_art(i7val x) {
	printf("Unimplemented: i7_print_cdef_art.\n");
}

void i7_print_indef_art(i7val x) {
	printf("Unimplemented: i7_print_indef_art.\n");
}

void i7_print_name(i7val x) {
	printf("Unimplemented: i7_print_name.\n");
}

void i7_print_object(i7val x) {
	printf("Unimplemented: i7_print_object.\n");
}

void i7_print_property(i7val x) {
	printf("Unimplemented: i7_print_property.\n");
}

int i7_provides(i7val obj, i7val prop) {
	printf("Unimplemented: i7_provides.\n");
	return 0;
}

i7val i7_pull(void) {
	printf("Unimplemented: i7_pull.\n");
	return (i7val) 0;
}

void i7_push(i7val x) {
	printf("Unimplemented: i7_push.\n");
}

#define i7_bold 1
#define i7_roman 2

void i7_style(int what) {
}

i7val fn_i7_mgl_random(int n, i7val v) {
	if (i7_seed < 1000) return ((i7val) ((i7_seed++) % n));
	i7_seed = i7_seed*i7_seed;
	return (((i7_seed*i7_seed) & 0xFF00) / 0x100) % n;
}

i7val i7_gen_call(i7val fn_ref, i7val *args, int argc, int call_message) {
	printf("Unimplemented: i7_gen_call.\n");
	return 0;
}

i7val i7_call_0(i7val fn_ref) {
	i7val args[10]; for (int i=0; i<10; i++) args[i] = 0;
	return i7_gen_call(fn_ref, args, 0, 0);
}

i7val fn_i7_mgl_indirect(int n, i7val v) {
	return i7_call_0(v);
}

i7val i7_call_1(i7val fn_ref, i7val v) {
	i7val args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v;
	return i7_gen_call(fn_ref, args, 1, 0);
}

i7val i7_call_2(i7val fn_ref, i7val v, i7val v2) {
	i7val args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v; args[1] = v2;
	return i7_gen_call(fn_ref, args, 2, 0);
}

i7val i7_call_3(i7val fn_ref, i7val v, i7val v2, i7val v3) {
	i7val args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v; args[1] = v2; args[2] = v3;
	return i7_gen_call(fn_ref, args, 3, 0);
}

i7val i7_call_4(i7val fn_ref, i7val v, i7val v2, i7val v3, i7val v4) {
	i7val args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v; args[1] = v2; args[2] = v3; args[3] = v4;
	return i7_gen_call(fn_ref, args, 4, 0);
}

i7val i7_call_5(i7val fn_ref, i7val v, i7val v2, i7val v3, i7val v4, i7val v5) {
	i7val args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v; args[1] = v2; args[2] = v3; args[3] = v4; args[4] = v5;
	return i7_gen_call(fn_ref, args, 5, 0);
}

i7val i7_ccall_0(i7val fn_ref) {
	i7val args[10]; for (int i=0; i<10; i++) args[i] = 0;
	return i7_gen_call(fn_ref, args, 0, 1);
}

i7val i7_ccall_1(i7val fn_ref, i7val v) {
	i7val args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v;
	return i7_gen_call(fn_ref, args, 1, 1);
}

i7val i7_ccall_2(i7val fn_ref, i7val v, i7val v2) {
	i7val args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v; args[1] = v2;
	return i7_gen_call(fn_ref, args, 2, 1);
}

i7val i7_ccall_3(i7val fn_ref, i7val v, i7val v2, i7val v3) {
	i7val args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v; args[1] = v2; args[2] = v3;
	return i7_gen_call(fn_ref, args, 3, 1);
}

i7val fn_i7_mgl_Z__Region(int argc, i7val x) {
	printf("Unimplemented: fn_i7_mgl_Z__Region.\n");
	return 0;
}

i7val fn_i7_mgl_CP__Tab(int argc, i7val x) {
	printf("Unimplemented: fn_i7_mgl_CP__Tab.\n");
	return 0;
}

i7val fn_i7_mgl_RA__Pr(int argc, i7val x) {
	printf("Unimplemented: fn_i7_mgl_RA__Pr.\n");
	return 0;
}

i7val fn_i7_mgl_RL__Pr(int argc, i7val x) {
	printf("Unimplemented: fn_i7_mgl_RL__Pr.\n");
	return 0;
}

i7val fn_i7_mgl_OC__Cl(int argc, i7val x) {
	printf("Unimplemented: fn_i7_mgl_OC__Cl.\n");
	return 0;
}

i7val fn_i7_mgl_RV__Pr(int argc, i7val x) {
	printf("Unimplemented: fn_i7_mgl_RV__Pr.\n");
	return 0;
}

i7val fn_i7_mgl_OP__Pr(int argc, i7val x) {
	printf("Unimplemented: fn_i7_mgl_OP__Pr.\n");
	return 0;
}

i7val fn_i7_mgl_CA__Pr(int argc, i7val x) {
	printf("Unimplemented: fn_i7_mgl_CA__Pr.\n");
	return 0;
}

i7val i7_mgl_sharp_classes_table = 0;
i7val i7_mgl_NUM_ATTR_BYTES = 0;
i7val i7_mgl_sharp_cpv__start = 0;
i7val i7_mgl_sharp_identifiers_table = 0;
i7val i7_mgl_sharp_globals_array = 0;
i7val i7_mgl_sharp_gself = 0;
i7val i7_mgl_sharp_dict_par2 = 0;
i7val i7_mgl_sharp_dictionary_table = 0;
i7val i7_mgl_sharp_grammar_table = 0;

#define i7_mgl_FLOAT_NAN 0
=

@

=

void CTarget::begin_memory(code_generation *gen) {
	generated_segment *saved = CodeGen::select(gen, c_header_matter_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("i7byte i7mem[];\n");
	CodeGen::deselect(gen, saved);
	
	saved = CodeGen::select(gen, c_mem_I7CGS);
	OUT = CodeGen::current(gen);
	WRITE("i7byte i7mem[] = {\n");
	CodeGen::deselect(gen, saved);
}

void CTarget::end_memory(code_generation *gen) {
	generated_segment *saved = CodeGen::select(gen, c_mem_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("0, 0 };\n");
	CodeGen::deselect(gen, saved);

	saved = CodeGen::select(gen, c_predeclarations_I7CGS);
	OUT = CodeGen::current(gen);
	WRITE("char *dqs[] = {\n%S\"\" };\n", C_GEN_DATA(double_quoted_C));
	CodeGen::deselect(gen, saved);
}

void CTarget::begin_dictionary_words(code_generation *gen) {
}

void CTarget::end_dictionary_words(code_generation *gen) {
	generated_segment *saved = CodeGen::select(gen, c_predeclarations_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	for (int i=0; i<C_GEN_DATA(C_dword_count); i++) {
		WRITE("#define i7_s_dword_%d %d\n", i, 2*i);
		WRITE("#define i7_p_dword_%d %d\n", i, 2*i + 1);
	}
	CodeGen::deselect(gen, saved);
}

void CTarget::end_functions(code_generation *gen) {
	generated_segment *saved = CodeGen::select(gen, c_globals_array_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#ifdef i7_defined_i7_mgl_I7S_Comp\n");
	WRITE("#ifndef fn_i7_mgl_I7S_Comp\n");
	WRITE("i7val fn_i7_mgl_I7S_Comp(int argc, i7val a1, i7val a2, i7val a3, i7val a4, i7val a5) {\n");
	WRITE("    return i7_call_5(i7_mgl_I7S_Comp, a1, a2, a3, a4, a5);\n");
	WRITE("}\n");
	WRITE("#endif\n");
	WRITE("#endif\n");
	WRITE("#ifdef i7_defined_i7_mgl_I7S_Swap\n");
	WRITE("#ifndef fn_i7_mgl_I7S_Swap\n");
	WRITE("i7val fn_i7_mgl_I7S_Swap(int argc, i7val a1, i7val a2, i7val a3) {\n");
	WRITE("    return i7_call_3(i7_mgl_I7S_Swap, a1, a2, a3);\n");
	WRITE("}\n");
	WRITE("#endif\n");
	WRITE("#endif\n");
	CodeGen::deselect(gen, saved);
}

void CTarget::fix_locals(code_generation *gen) {
	InterTree::traverse(gen->from, CTarget::sweep_for_locals, gen, NULL, LOCAL_IST);
}

void CTarget::sweep_for_locals(inter_tree *I, inter_tree_node *P, void *state) {
	inter_package *pack = Inter::Packages::container(P);
	inter_symbol *var_name =
		InterSymbolsTables::local_symbol_from_id(pack, P->W.data[DEFN_LOCAL_IFLD]);
	TEMPORARY_TEXT(T)
	WRITE_TO(T, "local_%S", var_name->symbol_name);
	Inter::Symbols::set_translate(var_name, T);
	DISCARD_TEXT(T)
}

int CTarget::general_segment(code_generation_target *cgt, code_generation *gen, inter_tree_node *P) {
	switch (P->W.data[ID_IFLD]) {
		case CONSTANT_IST: {
			inter_symbol *con_name =
				InterSymbolsTables::symbol_from_frame_data(P, DEFN_CONST_IFLD);
			int choice = c_early_matter_I7CGS;
			if (Str::eq(con_name->symbol_name, I"DynamicMemoryAllocation")) choice = c_very_early_matter_I7CGS;
			if (Inter::Symbols::read_annotation(con_name, LATE_IANN) == 1) choice = c_code_at_eof_I7CGS;
			if (Inter::Symbols::read_annotation(con_name, BUFFERARRAY_IANN) == 1) choice = c_arrays_at_eof_I7CGS;
			if (Inter::Symbols::read_annotation(con_name, BYTEARRAY_IANN) == 1) choice = c_arrays_at_eof_I7CGS;
			if (Inter::Symbols::read_annotation(con_name, TABLEARRAY_IANN) == 1) choice = c_arrays_at_eof_I7CGS;
			if (P->W.data[FORMAT_CONST_IFLD] == CONSTANT_INDIRECT_LIST) choice = c_arrays_at_eof_I7CGS;
			if (Inter::Symbols::read_annotation(con_name, VERBARRAY_IANN) == 1) choice = c_verbs_at_eof_I7CGS;
			if (Inter::Constant::is_routine(con_name)) choice = c_functions_at_eof_I7CGS;
			return choice;
		}
	}
	return CTarget::default_segment(cgt);
}

int CTarget::default_segment(code_generation_target *cgt) {
	return c_main_matter_I7CGS;
}
int CTarget::constant_segment(code_generation_target *cgt, code_generation *gen) {
	return c_early_matter_I7CGS;
}
int CTarget::basic_constant_segment(code_generation_target *cgt, code_generation *gen, int depth) {
	if (depth >= 10) depth = 10;
	return c_constants_1_I7CGS + depth - 1;
}
int CTarget::property_segment(code_generation_target *cgt) {
	return c_predeclarations_I7CGS;
}
int CTarget::tl_segment(code_generation_target *cgt) {
	return c_text_literals_code_I7CGS;
}

void CTarget::offer_pragma(code_generation_target *cgt, code_generation *gen,
	inter_tree_node *P, text_stream *tag, text_stream *content) {
}

void CTarget::mangle(code_generation_target *cgt, OUTPUT_STREAM, text_stream *identifier) {
	if (Str::get_first_char(identifier) == '(') WRITE("%S", identifier);
	else if (Str::get_first_char(identifier) == '#') {
		WRITE("i7_mgl_sharp_");
		LOOP_THROUGH_TEXT(pos, identifier)
			if ((Str::get(pos) != '#') && (Str::get(pos) != '$'))
				PUT(Str::get(pos));
	} else WRITE("i7_mgl_%S", identifier);
}

int C_write_lookup_mode = FALSE;

int CTarget::compile_primitive(code_generation_target *cgt, code_generation *gen,
	inter_symbol *prim_name, inter_tree_node *P) {
	text_stream *OUT = CodeGen::current(gen);
	int suppress_terminal_semicolon = FALSE;
	inter_tree *I = gen->from;
	inter_ti bip = Primitives::to_bip(I, prim_name);
	switch (bip) {
		case INVERSION_BIP:		break; /* we won't support this in C */

		case PLUS_BIP:			WRITE("("); INV_A1; WRITE(" + "); INV_A2; WRITE(")"); break;
		case MINUS_BIP:			WRITE("("); INV_A1; WRITE(" - "); INV_A2; WRITE(")"); break;
		case UNARYMINUS_BIP:	WRITE("(-("); INV_A1; WRITE("))"); break;
		case TIMES_BIP:			WRITE("("); INV_A1; WRITE("*"); INV_A2; WRITE(")"); break;
		case DIVIDE_BIP:		WRITE("("); INV_A1; WRITE("/"); INV_A2; WRITE(")"); break;
		case MODULO_BIP:		WRITE("("); INV_A1; WRITE("%%"); INV_A2; WRITE(")"); break;
		case BITWISEAND_BIP:	WRITE("(("); INV_A1; WRITE(")&("); INV_A2; WRITE("))"); break;
		case BITWISEOR_BIP:		WRITE("(("); INV_A1; WRITE(")|("); INV_A2; WRITE("))"); break;
		case BITWISENOT_BIP:	WRITE("(~("); INV_A1; WRITE("))"); break;

		case NOT_BIP:			WRITE("(~~("); INV_A1; WRITE("))"); break;
		case AND_BIP:			WRITE("(("); INV_A1; WRITE(") && ("); INV_A2; WRITE("))"); break;
		case OR_BIP: 			WRITE("(("); INV_A1; WRITE(") || ("); INV_A2; WRITE("))"); break;
		case EQ_BIP: 			@<Generate comparison@>; break;
		case NE_BIP: 			@<Generate comparison@>; break;
		case GT_BIP: 			@<Generate comparison@>; break;
		case GE_BIP: 			@<Generate comparison@>; break;
		case LT_BIP: 			@<Generate comparison@>; break;
		case LE_BIP: 			@<Generate comparison@>; break;
		case OFCLASS_BIP:		@<Generate comparison@>; break;
		case HAS_BIP:			@<Generate comparison@>; break;
		case HASNT_BIP:			@<Generate comparison@>; break;
		case IN_BIP:			@<Generate comparison@>; break;
		case NOTIN_BIP:			@<Generate comparison@>; break;
		case PROVIDES_BIP:		@<Generate comparison@>; break;
		case ALTERNATIVE_BIP:	INV_A1; WRITE(" or "); INV_A2; break;

		case PUSH_BIP:			WRITE("i7_push("); INV_A1; WRITE(")"); break;
		case PULL_BIP:			INV_A1; WRITE(" = i7_pull()"); break;
		case PREINCREMENT_BIP:	@<Generate primitive for store@>; break;
		case POSTINCREMENT_BIP:	@<Generate primitive for store@>; break;
		case PREDECREMENT_BIP:	@<Generate primitive for store@>; break;
		case POSTDECREMENT_BIP:	@<Generate primitive for store@>; break;
		case STORE_BIP:			@<Generate primitive for store@>; break;
		case SETBIT_BIP:		INV_A1; WRITE(" = "); INV_A1; WRITE(" | "); INV_A2; break;
		case CLEARBIT_BIP:		INV_A1; WRITE(" = "); INV_A1; WRITE(" &~ ("); INV_A2; WRITE(")"); break;
		case LOOKUP_BIP:		if (C_write_lookup_mode) {
									C_write_lookup_mode = FALSE;
									@<Generate primitive for lookupref@>;
								} else {
									@<Generate primitive for lookup@>;
								}
								break;
		case LOOKUPBYTE_BIP:	@<Generate primitive for lookupbyte@>; break;
		case LOOKUPREF_BIP:		@<Generate primitive for lookupref@>; break;
		case PROPERTYADDRESS_BIP: WRITE("i7_prop_addr("); INV_A1; WRITE(", "); INV_A2; WRITE(")"); break;
		case PROPERTYLENGTH_BIP: WRITE("i7_prop_len("); INV_A1; WRITE(", "); INV_A2; WRITE(")"); break;
		case PROPERTYVALUE_BIP:	if (C_write_lookup_mode) {
									C_write_lookup_mode = FALSE;
									WRITE("i7_change_prop_value("); INV_A1; WRITE(", "); INV_A2; WRITE(", ");
								} else {
									WRITE("i7_read_prop_value("); INV_A1; WRITE(", "); INV_A2; WRITE(")");
								}
								break;
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
		case MESSAGE0_BIP: 		WRITE("i7_call_0(i7_read_prop_value("); INV_A1; WRITE(", "); INV_A2; WRITE("))"); break;
		case MESSAGE1_BIP: 		WRITE("i7_call_1(i7_read_prop_value("); INV_A1; WRITE(", "); INV_A2; WRITE("), ");
								INV_A3; WRITE(")"); break;
		case MESSAGE2_BIP: 		WRITE("i7_call_2(i7_read_prop_value("); INV_A1; WRITE(", "); INV_A2; WRITE("), ");
								INV_A3; WRITE(", "); INV_A4; WRITE(")"); break;
		case MESSAGE3_BIP: 		WRITE("i7_call_3(i7_read_prop_value("); INV_A1; WRITE(", "); INV_A2; WRITE("), ");
								INV_A3; WRITE(", "); INV_A4; WRITE(", "); INV_A5; WRITE(")"); break;
		case CALLMESSAGE0_BIP: 	WRITE("i7_ccall_0("); INV_A1; WRITE(")"); break;
		case CALLMESSAGE1_BIP: 	WRITE("i7_ccall_1("); INV_A1; WRITE(", ");
								INV_A2; WRITE(")"); break;
		case CALLMESSAGE2_BIP: 	WRITE("i7_ccall_2("); INV_A1; WRITE(", ");
								INV_A2; WRITE(", "); INV_A3; WRITE(")"); break;
		case CALLMESSAGE3_BIP: 	WRITE("i7_ccall_3("); INV_A1; WRITE(", ");
								INV_A2; WRITE(", "); INV_A3; WRITE(", "); INV_A4; WRITE(")"); break;

		case SPACES_BIP:		WRITE("for (int j = "); INV_A1; WRITE("; j >= 0; j--) printf(\" \")"); break;
		case FONT_BIP:
			WRITE("if ("); INV_A1; WRITE(") { i7_font(1); } else { i7_font(0); }");
			suppress_terminal_semicolon = TRUE;
			break;
		case STYLEROMAN_BIP: WRITE("i7_style(i7_roman)"); break;
		case STYLEBOLD_BIP: WRITE("i7_style(i7_bold)"); break;
		case STYLEUNDERLINE_BIP: WRITE("i7_style(i7_underline)"); break;
		case STYLEREVERSE_BIP: WRITE("i7_style(i7_reverse)"); break;

		case MOVE_BIP: WRITE("i7_move("); INV_A1; WRITE(", "); INV_A2; WRITE(")"); break;
		case REMOVE_BIP: WRITE("i7_move("); INV_A1; WRITE(", 0)"); break;
		case GIVE_BIP: WRITE("i7_give("); INV_A1; WRITE(", "); INV_A2; WRITE(", 1)"); break;
		case TAKE_BIP: WRITE("i7_give("); INV_A1; WRITE(", "); INV_A2; WRITE(", 0)"); break;

		case ALTERNATIVECASE_BIP: INV_A1; WRITE(", "); INV_A2; break;
		case SEQUENTIAL_BIP: WRITE("("); INV_A1; WRITE(","); INV_A2; WRITE(")"); break;
		case TERNARYSEQUENTIAL_BIP: @<Generate primitive for ternarysequential@>; break;

		case PRINT_BIP: WRITE("printf(\"%%s\", "); INV_A1_PRINTMODE; WRITE(")"); break;
		case PRINTRET_BIP: WRITE("printf(\"%%s\", "); INV_A1_PRINTMODE; WRITE("); return 1"); break;
		case PRINTCHAR_BIP: WRITE("i7_print_char("); INV_A1; WRITE(")"); break;
		case PRINTNAME_BIP: WRITE("i7_print_name("); INV_A1; WRITE(")"); break;
		case PRINTOBJ_BIP: WRITE("i7_print_object("); INV_A1; WRITE(")"); break;
		case PRINTPROPERTY_BIP: WRITE("i7_print_property("); INV_A1; WRITE(")"); break;
		case PRINTNUMBER_BIP: WRITE("printf(\"%%d\", (int) "); INV_A1; WRITE(")"); break;
		case PRINTADDRESS_BIP: WRITE("i7_print_address("); INV_A1; WRITE(")"); break;
		case PRINTSTRING_BIP: WRITE("printf(\"%%s\", dqs["); INV_A1; WRITE(" - I7VAL_STRINGS_BASE])"); break;
		case PRINTNLNUMBER_BIP: WRITE("i7_print_number("); INV_A1; WRITE(")"); break;
		case PRINTDEF_BIP: WRITE("i7_print_def_art("); INV_A1; WRITE(")"); break;
		case PRINTCDEF_BIP: WRITE("i7_print_cdef_art("); INV_A1; WRITE(")"); break;
		case PRINTINDEF_BIP: WRITE("i7_print_indef_art("); INV_A1; WRITE(")"); break;
		case PRINTCINDEF_BIP: WRITE("i7_print_cindef_art("); INV_A1; WRITE(")"); break;
		case BOX_BIP: WRITE("i7_print_box("); INV_A1_BOXMODE; WRITE(")"); break;

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
		case DEFAULT_BIP: @<Generate primitive for default@>; break;

		case RANDOM_BIP: WRITE("fn_i7_mgl_random(1, "); INV_A1; WRITE(")"); break;

		case READ_BIP: WRITE("i7_read("); INV_A1; WRITE(", "); INV_A2; WRITE(")"); break;

		default: LOG("Prim: %S\n", prim_name->symbol_name); internal_error("unimplemented prim");
	}
	return suppress_terminal_semicolon;
}

@<Generate comparison@> =
	CTarget::comparison(cgt, gen, bip, InterTree::first_child(P), InterTree::second_child(P));

@<Generate primitive for store@> =
	text_stream *store_form = NULL;
	switch (bip) {
		case PREINCREMENT_BIP:	store_form = I"i7_cpv_PREINC"; break;
		case POSTINCREMENT_BIP:	store_form = I"i7_cpv_POSTINC"; break;
		case PREDECREMENT_BIP:	store_form = I"i7_cpv_PREDEC"; break;
		case POSTDECREMENT_BIP:	store_form = I"i7_cpv_POSTDEC"; break;
		case STORE_BIP:			store_form = I"i7_cpv_SET"; break;
	}
	inter_tree_node *ref = InterTree::first_child(P);
	if (CTarget::basically_an_array_write(gen->from, ref)) {
		WRITE("("); C_write_lookup_mode = TRUE; INV_A1; C_write_lookup_mode = FALSE;
		if (bip == STORE_BIP) { INV_A2; } else { WRITE("0"); }
		WRITE(", %S))", store_form);
	} else if (CTarget::basically_a_property_write(gen->from, ref)) {
		WRITE("("); C_write_lookup_mode = TRUE; INV_A1; C_write_lookup_mode = FALSE;
		if (bip == STORE_BIP) { INV_A2; } else { WRITE("0"); }
		WRITE(", %S))", store_form);
	} else {
		switch (bip) {
			case PREINCREMENT_BIP:	WRITE("++("); INV_A1; WRITE(")"); break;
			case POSTINCREMENT_BIP:	WRITE("("); INV_A1; WRITE(")++"); break;
			case PREDECREMENT_BIP:	WRITE("--("); INV_A1; WRITE(")"); break;
			case POSTDECREMENT_BIP:	WRITE("("); INV_A1; WRITE(")--"); break;
			case STORE_BIP:			WRITE("("); INV_A1; WRITE(" = "); INV_A2; WRITE(")"); break;
		}
	}

@<Generate primitive for lookup@> =
	WRITE("i7_lookup(i7mem, "); INV_A1; WRITE(", "); INV_A2; WRITE(")");

@<Generate primitive for lookupref@> =
	WRITE("write_i7_lookup(i7mem, "); INV_A1; WRITE(", "); INV_A2; WRITE(", ");
	
@<Generate primitive for lookupbyte@> =
	WRITE("i7mem["); INV_A1; WRITE(" + "); INV_A2; WRITE("]");

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

@<Generate primitive for ternarysequential@> =
	WRITE("(");
	INV_A1;
	WRITE(", ");
	INV_A2;
	WRITE(", ");
	INV_A3;
	WRITE(")");

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
	CTarget::caser(cgt, gen,  InterTree::first_child(P));
	INDENT; INV_A2; WRITE(";\n"); WRITE("break;\n"); OUTDENT;
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for default@> =
	WRITE("default:\n"); INDENT; INV_A1; WRITE(";\n"); WRITE("break;\n"); OUTDENT;
	suppress_terminal_semicolon = TRUE;

@ =
void CTarget::caser(code_generation_target *cgt, code_generation *gen, inter_tree_node *X) {
	if (X->W.data[ID_IFLD] == INV_IST) {
		if (X->W.data[METHOD_INV_IFLD] == INVOKED_PRIMITIVE) {
			inter_symbol *prim = Inter::Inv::invokee(X);
			inter_ti xbip = Primitives::to_bip(gen->from, prim);
			if (xbip == ALTERNATIVECASE_BIP) {
				CTarget::caser(cgt, gen, InterTree::first_child(X));
				CTarget::caser(cgt, gen, InterTree::second_child(X));
				return;
			}
		}
	}
	text_stream *OUT = CodeGen::current(gen);
	WRITE("case ");
	CodeGen::FC::frame(gen, X);
	WRITE(": ");
}

void CTarget::comparison(code_generation_target *cgt, code_generation *gen,
	inter_ti bip, inter_tree_node *X, inter_tree_node *Y) {
	CTarget::comparison_r(cgt, gen, bip, X, Y, 0);
}

void CTarget::comparison_r(code_generation_target *cgt, code_generation *gen,
	inter_ti bip, inter_tree_node *X, inter_tree_node *Y, int depth) {
	if (Y->W.data[ID_IFLD] == INV_IST) {
		if (Y->W.data[METHOD_INV_IFLD] == INVOKED_PRIMITIVE) {
			inter_symbol *prim = Inter::Inv::invokee(Y);
			inter_ti ybip = Primitives::to_bip(gen->from, prim);
			if (ybip == ALTERNATIVE_BIP) {
				text_stream *OUT = CodeGen::current(gen);
				if (depth == 0) { WRITE("(i7_tmp = "); CodeGen::FC::frame(gen, X); WRITE(", ("); }
				CTarget::comparison_r(cgt, gen, bip, NULL, InterTree::first_child(Y), depth+1);
				WRITE(" || ");
				CTarget::comparison_r(cgt, gen, bip, NULL, InterTree::second_child(Y), depth+1);
				if (depth == 0) { WRITE("))"); }
				return;
			}
		}
	}
	text_stream *OUT = CodeGen::current(gen);
	switch (bip) {
		case EQ_BIP: 			WRITE("("); @<Compile first compared@>; WRITE(" == "); @<Compile second compared@>; WRITE(")"); break;
		case NE_BIP: 			WRITE("("); @<Compile first compared@>; WRITE(" != "); @<Compile second compared@>; WRITE(")"); break;
		case GT_BIP: 			WRITE("("); @<Compile first compared@>; WRITE(" > "); @<Compile second compared@>; WRITE(")"); break;
		case GE_BIP: 			WRITE("("); @<Compile first compared@>; WRITE(" >= "); @<Compile second compared@>; WRITE(")"); break;
		case LT_BIP: 			WRITE("("); @<Compile first compared@>; WRITE(" < "); @<Compile second compared@>; WRITE(")"); break;
		case LE_BIP: 			WRITE("("); @<Compile first compared@>; WRITE(" <= "); @<Compile second compared@>; WRITE(")"); break;
		case OFCLASS_BIP:		WRITE("(i7_ofclass("); @<Compile first compared@>; WRITE(", "); @<Compile second compared@>; WRITE("))"); break;
		case HAS_BIP:			WRITE("(i7_has("); @<Compile first compared@>; WRITE(", "); @<Compile second compared@>; WRITE("))"); break;
		case HASNT_BIP:			WRITE("(i7_has("); @<Compile first compared@>; WRITE(", "); @<Compile second compared@>; WRITE(") == FALSE)"); break;
		case IN_BIP:			WRITE("(i7_in("); @<Compile first compared@>; WRITE(", "); @<Compile second compared@>; WRITE("))"); break;
		case NOTIN_BIP:			WRITE("(i7_in("); @<Compile first compared@>; WRITE(", "); @<Compile second compared@>; WRITE(") == FALSE)"); break;
		case PROVIDES_BIP:		WRITE("(i7_provides("); @<Compile first compared@>; WRITE(", "); @<Compile second compared@>; WRITE("))"); break;
	}
}

@<Compile first compared@> =
	if (X) CodeGen::FC::frame(gen, X); else WRITE("i7_tmp");

@<Compile second compared@> =
	CodeGen::FC::frame(gen, Y);

@

=
void CTarget::compile_dictionary_word(code_generation_target *cgt, code_generation *gen,
	text_stream *S, int pluralise) {
	text_stream *OUT = CodeGen::current(gen);
	text_stream *val = Dictionaries::get_text(C_GEN_DATA(C_vm_dictionary), S);
	if (val) {
		WRITE("%S", val);
	} else {
		WRITE_TO(Dictionaries::create_text(C_GEN_DATA(C_vm_dictionary), S),
			"i7_%s_dword_%d", (pluralise)?"p":"s", C_GEN_DATA(C_dword_count)++);
		val = Dictionaries::get_text(C_GEN_DATA(C_vm_dictionary), S);
		WRITE("%S", val);
	}
}

@

=
void CTarget::compile_literal_number(code_generation_target *cgt,
	code_generation *gen, inter_ti val, int hex_mode) {
	text_stream *OUT = CodeGen::current(gen);
	if (hex_mode) WRITE("0x%x", val);
	else WRITE("%d", val);
}

@

=
void CTarget::compile_literal_text(code_generation_target *cgt, code_generation *gen,
	text_stream *S, int printing_mode, int box_mode) {
	text_stream *OUT = CodeGen::current(gen);
	
	if (printing_mode == FALSE) {
		WRITE("(I7VAL_STRINGS_BASE + %d)", C_GEN_DATA(no_double_quoted_C_strings)++);
		OUT = C_GEN_DATA(double_quoted_C);
	}
	
	WRITE("\"");
	LOOP_THROUGH_TEXT(pos, S) {
		wchar_t c = Str::get(pos);
		if (box_mode) {
			switch(c) {
				case '"': WRITE("\\\""); break;
				case '\\': WRITE("\\\\"); break;
				case '\t': WRITE(" "); break;
				case '\n': WRITE("\\n\"\n\""); break;
				case NEWLINE_IN_STRING: WRITE("\"\n\""); break;
				default: PUT(c);
			}
		} else {
			switch(c) {
				case '"': WRITE("\\\""); break;
				case '\\': WRITE("\\\\"); break;
				case '\t': WRITE(" "); break;
				case '\n': WRITE("\\n"); break;
				case NEWLINE_IN_STRING: WRITE("\\n"); break;
				default: PUT(c); break;
			}
		}
	}
	WRITE("\"");
	if (printing_mode == FALSE) WRITE(",\n");
}

@

=
int CTarget::prepare_variable(code_generation_target *cgt, code_generation *gen,
	inter_tree_node *P, inter_symbol *var_name, int k) {
	if (Inter::Symbols::read_annotation(var_name, EXPLICIT_VARIABLE_IANN) != 1) {
		if (Inter::Symbols::read_annotation(var_name, ASSIMILATED_IANN) != 1) {
			text_stream *S = Str::new();
			WRITE_TO(S, "(");
			CTarget::mangle(cgt, S, I"Global_Vars");
			WRITE_TO(S, "[%d])", k);
			Inter::Symbols::set_translate(var_name, S);
		}
		k++;
	}
	return k;
}

int CTarget::declare_variable(code_generation_target *cgt, code_generation *gen,
	inter_tree_node *P, inter_symbol *var_name, int k, int of) {
	if (Inter::Symbols::read_annotation(var_name, ASSIMILATED_IANN) == 1) {
		generated_segment *saved = CodeGen::select(gen, c_globals_array_I7CGS);
		text_stream *OUT = CodeGen::current(gen);
		WRITE("i7val ");
		CTarget::mangle(cgt, OUT, CodeGen::CL::name(var_name));
		WRITE(" = "); 
		CodeGen::CL::literal(gen, NULL, Inter::Packages::scope_of(P), P->W.data[VAL1_VAR_IFLD], P->W.data[VAL2_VAR_IFLD], FALSE);
		WRITE(";\n");
		WRITE("#define i7_defined_");
		CTarget::mangle(cgt, OUT, CodeGen::CL::name(var_name));
		WRITE(" 1;\n");
		CodeGen::deselect(gen, saved);
	}
	if (Inter::Symbols::read_annotation(var_name, EXPLICIT_VARIABLE_IANN) != 1) {
		if (k == 0) CTarget::begin_array(cgt, gen, I"Global_Vars", WORD_ARRAY_FORMAT);
		TEMPORARY_TEXT(val)
		CodeGen::select_temporary(gen, val);
		CodeGen::CL::literal(gen, NULL, Inter::Packages::scope_of(P), P->W.data[VAL1_VAR_IFLD], P->W.data[VAL2_VAR_IFLD], FALSE);
		CodeGen::deselect_temporary(gen);
		CTarget::array_entry(cgt, gen, val, WORD_ARRAY_FORMAT);
		DISCARD_TEXT(val)
		k++;
		if (k == of) {
			if (k < 2) {
				CTarget::array_entry(cgt, gen, I"0", WORD_ARRAY_FORMAT);
				CTarget::array_entry(cgt, gen, I"0", WORD_ARRAY_FORMAT);
			}
			CTarget::end_array(cgt, gen, WORD_ARRAY_FORMAT);
		}
	}
	return k;
}

void CTarget::begin_constant(code_generation_target *cgt, code_generation *gen, text_stream *const_name, int continues, int ifndef_me) {
	text_stream *OUT = CodeGen::current(gen);
	if (ifndef_me) {
		WRITE("#ifndef ");
		CTarget::mangle(cgt, OUT, const_name);
		WRITE("\n");
	}
	WRITE("#define ");
	CTarget::mangle(cgt, OUT, const_name);
	if (continues) WRITE(" ");
}
void CTarget::end_constant(code_generation_target *cgt, code_generation *gen, text_stream *const_name, int ifndef_me) {
	text_stream *OUT = CodeGen::current(gen);
	WRITE("\n");
	if (ifndef_me) WRITE("#endif\n");
}

text_stream *C_fn_prototype = NULL;
int C_fn_parameter_count = 0;

typedef struct final_c_function {
	struct text_stream *identifier_as_constant;
	int uses_vararg_model;
	int max_arity;
	CLASS_DEFINITION
} final_c_function;

final_c_function *CTarget::create_fcf(text_stream *unmangled_name) {
	final_c_function *fcf = CREATE(final_c_function);
	fcf->max_arity = 0;
	fcf->uses_vararg_model = FALSE;
	fcf->identifier_as_constant = Str::duplicate(unmangled_name);
	return fcf;
}

void CTarget::declare_fcf(code_generation *gen, final_c_function *fcf) {
	generated_segment *saved = CodeGen::select(gen, c_predeclarations_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#define ");
	CTarget::mangle(NULL, OUT, fcf->identifier_as_constant);
	WRITE(" (I7VAL_FUNCTIONS_BASE + %d)\n", fcf->allocation_id);
	CodeGen::deselect(gen, saved);
}

void CTarget::begin_functions(code_generation *gen) {
	CTarget::add_main(gen);
	CTarget::make_veneer_fcf(gen, I"Z__Region");
	CTarget::make_veneer_fcf(gen, I"CP__Tab");
	CTarget::make_veneer_fcf(gen, I"RA__Pr");
	CTarget::make_veneer_fcf(gen, I"RL__Pr");
	CTarget::make_veneer_fcf(gen, I"OC__Cl");
	CTarget::make_veneer_fcf(gen, I"RV__Pr");
	CTarget::make_veneer_fcf(gen, I"OP__Pr");
	CTarget::make_veneer_fcf(gen, I"CA__Pr");
}

void CTarget::add_main(code_generation *gen) {
	generated_segment *saved = CodeGen::select(gen, c_stubs_at_eof_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("void i7_initializer(void);\n");
	WRITE("int main(int argc, char **argv) { i7_initializer(); ");
	WRITE("fn_"); CTarget::mangle(NULL, OUT, I"Main");
	WRITE("(0); return 0; }\n");
	CodeGen::deselect(gen, saved);
}

void CTarget::make_veneer_fcf(code_generation *gen, text_stream *unmangled_name) {
	final_c_function *fcf = CTarget::create_fcf(unmangled_name);
	CTarget::declare_fcf(gen, fcf);
}

final_c_function *C_fn_being_found = NULL;

void CTarget::begin_function(code_generation_target *cgt, int pass, code_generation *gen, inter_symbol *fn) {
	text_stream *fn_name = CodeGen::CL::name(fn);
	C_fn_parameter_count = 0;
	if (pass == 1) {
		C_fn_being_found = CTarget::create_fcf(fn_name);
		fn->translation_data = STORE_POINTER_final_c_function(C_fn_being_found);
		if (C_fn_prototype == NULL) C_fn_prototype = Str::new();
		Str::clear(C_fn_prototype);
		WRITE_TO(C_fn_prototype, "i7val fn_");
		CTarget::mangle(cgt, C_fn_prototype, fn_name);
		WRITE_TO(C_fn_prototype, "(int __argc");
	}
	if (pass == 2) {
		C_fn_being_found = RETRIEVE_POINTER_final_c_function(fn->translation_data);
		text_stream *OUT = CodeGen::current(gen);
		WRITE("i7val fn_");
		CTarget::mangle(cgt, OUT, fn_name);
		WRITE("(int __argc");
	}
}

void CTarget::begin_function_code(code_generation_target *cgt, code_generation *gen) {
	text_stream *OUT = CodeGen::current(gen);
	WRITE(") {");
	if (C_fn_being_found) {
		if (FALSE) {
			WRITE("printf(\"called %S\\n\");\n", C_fn_being_found->identifier_as_constant);
		}
	}
}

void CTarget::place_label(code_generation_target *cgt, code_generation *gen, text_stream *label_name) {
	text_stream *OUT = CodeGen::current(gen);
	LOOP_THROUGH_TEXT(pos, label_name)
		if (Str::get(pos) != '.')
			PUT(Str::get(pos));
	WRITE(": ;\n", label_name);
}

void CTarget::end_function(code_generation_target *cgt, int pass, code_generation *gen, inter_symbol *fn) {
	if (pass == 1) {
		WRITE_TO(C_fn_prototype, ")");

		generated_segment *saved = CodeGen::select(gen, c_predeclarations_I7CGS);
		text_stream *OUT = CodeGen::current(gen);
		WRITE("%S;\n", C_fn_prototype);
		CodeGen::deselect(gen, saved);

		final_c_function *fcf = RETRIEVE_POINTER_final_c_function(fn->translation_data);
		CTarget::declare_fcf(gen, fcf);
	}
	if (pass == 2) {
		text_stream *OUT = CodeGen::current(gen);
		WRITE("return 1;\n");
		WRITE("\n}\n");
	}
}

void CTarget::begin_function_call(code_generation_target *cgt, code_generation *gen, inter_symbol *fn, int argc) {
	inter_tree_node *D = fn->definition;
	if ((D) && (D->W.data[ID_IFLD] == CONSTANT_IST) && (D->W.data[FORMAT_CONST_IFLD] == CONSTANT_DIRECT)) {
		inter_ti val1 = D->W.data[DATA_CONST_IFLD];
		inter_ti val2 = D->W.data[DATA_CONST_IFLD + 1];
		if (Inter::Symbols::is_stored_in_data(val1, val2)) {
			inter_symbol *aliased = InterSymbolsTables::symbol_from_data_pair_and_table(val1, val2, Inter::Packages::scope_of(D));
			if (aliased) fn = aliased;
		}
	}

	text_stream *fn_name = CodeGen::CL::name(fn);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("fn_");
	CTarget::mangle(cgt, OUT, fn_name);
	WRITE("(%d", argc);
	if (GENERAL_POINTER_IS_NULL(fn->translation_data) == FALSE) {
		final_c_function *fcf = RETRIEVE_POINTER_final_c_function(fn->translation_data);
		if (fcf->uses_vararg_model) {
			WRITE(", %d, (i7varargs) { ", argc);
		}
	}	
}
void CTarget::argument(code_generation_target *cgt, code_generation *gen, inter_tree_node *F, inter_symbol *fn, int argc, int of_argc) {
	text_stream *OUT = CodeGen::current(gen);
	if (GENERAL_POINTER_IS_NULL(fn->translation_data) == FALSE) {
		final_c_function *fcf = RETRIEVE_POINTER_final_c_function(fn->translation_data);
		if ((argc > 0) || (fcf->uses_vararg_model == FALSE)) WRITE(", ");
		CodeGen::FC::frame(gen, F);
	} else {
		WRITE(", ");
		CodeGen::FC::frame(gen, F);
	}
}
void CTarget::end_function_call(code_generation_target *cgt, code_generation *gen, inter_symbol *fn, int argc) {
	if (GENERAL_POINTER_IS_NULL(fn->translation_data)) {
		text_stream *OUT = CodeGen::current(gen);
		WRITE(")");
		WRITE(" /* %S has null */", CodeGen::CL::name(fn));
	} else {
		final_c_function *fcf = RETRIEVE_POINTER_final_c_function(fn->translation_data);
		text_stream *OUT = CodeGen::current(gen);
		if (fcf->uses_vararg_model) {
			for (int i = argc; i < 10; i++) {
				if (i > 0) WRITE(", ");
				WRITE("0");
			}
			WRITE(" }");
			for (int i = 1; i < fcf->max_arity; i++) WRITE(", 0");
		} else {
			while (argc < fcf->max_arity) {
				WRITE(", 0");
				argc++;
			}
		}
		WRITE(")");
	}
}

int C_operand_count = 0, C_operand_branches = FALSE; inter_tree_node *C_operand_label = NULL;
int C_pointer_on_operand = -1;
void CTarget::begin_opcode(code_generation_target *cgt, code_generation *gen, text_stream *opcode) {
	text_stream *OUT = CodeGen::current(gen);
	C_operand_branches = FALSE;
	C_operand_label = NULL;
	if (Str::get_at(opcode, 1) == 'j') { C_operand_branches = TRUE; }
	if (Str::eq(opcode, I"@return")) WRITE("return ");
	else {
		if (C_operand_branches) WRITE("if (");
		WRITE("glulx_");
		LOOP_THROUGH_TEXT(pos, opcode)
			if (Str::get(pos) != '@')
				PUT(Str::get(pos));
	}
	WRITE("("); C_operand_count = 0;
	C_pointer_on_operand = -1;
	if (Str::eq(opcode, I"@acos")) C_pointer_on_operand = 2;
	if (Str::eq(opcode, I"@aload")) C_pointer_on_operand = 3;
	if (Str::eq(opcode, I"@aloadb")) C_pointer_on_operand = 3;
	if (Str::eq(opcode, I"@aloads")) C_pointer_on_operand = 3;
	if (Str::eq(opcode, I"@asin")) C_pointer_on_operand = 2;
	if (Str::eq(opcode, I"@atan")) C_pointer_on_operand = 2;
	if (Str::eq(opcode, I"@binarysearch")) C_pointer_on_operand = 8;
	if (Str::eq(opcode, I"@ceil")) C_pointer_on_operand = 2;
	if (Str::eq(opcode, I"@cos")) C_pointer_on_operand = 2;
	if (Str::eq(opcode, I"@gestalt")) C_pointer_on_operand = 3;
	if (Str::eq(opcode, I"@glk")) C_pointer_on_operand = 3;
	if (Str::eq(opcode, I"@pow")) C_pointer_on_operand = 3;
	if (Str::eq(opcode, I"@shiftl")) C_pointer_on_operand = 3;
	if (Str::eq(opcode, I"@sin")) C_pointer_on_operand = 2;
	if (Str::eq(opcode, I"@sqrt")) C_pointer_on_operand = 2;
	if (Str::eq(opcode, I"@tan")) C_pointer_on_operand = 2;

}
void CTarget::supply_operand(code_generation_target *cgt, code_generation *gen, inter_tree_node *F, int is_label) {
	text_stream *OUT = CodeGen::current(gen);
	if (is_label) {
		C_operand_label = F;
	} else {
		if (C_operand_count++ > 0) WRITE(", ");
		if (C_operand_count == C_pointer_on_operand) {
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
void CTarget::end_opcode(code_generation_target *cgt, code_generation *gen) {
	text_stream *OUT = CodeGen::current(gen);
	WRITE(")");
	if (C_operand_branches) {
		if (negate_label_mode) WRITE(" == FALSE");
		WRITE(") goto ");
		if (C_operand_label == NULL) internal_error("no branch label");
		CodeGen::FC::frame(gen, C_operand_label);
	}
}

void CTarget::declare_local_variable(code_generation_target *cgt, int pass,
	code_generation *gen, inter_tree_node *P, inter_symbol *var_name) {
	TEMPORARY_TEXT(name)
	CTarget::mangle(cgt, name, CodeGen::CL::name(var_name));
	C_fn_parameter_count++;
	if (pass == 1) {
		if (Str::eq(var_name->symbol_name, I"_vararg_count")) {
			C_fn_being_found->uses_vararg_model = TRUE;
			WRITE_TO(C_fn_prototype, ", i7val %S", name);
			WRITE_TO(C_fn_prototype, ", i7varargs ");
			CTarget::mangle(cgt, C_fn_prototype, I"_varargs");
		} else {
			WRITE_TO(C_fn_prototype, ", i7val %S", name);
		}
		C_fn_being_found->max_arity++;
	}
	if (pass == 2) {
		text_stream *OUT = CodeGen::current(gen);
		if (Str::eq(var_name->symbol_name, I"_vararg_count")) {
			WRITE(", i7val %S", name);
			WRITE(", i7varargs ");
			CTarget::mangle(cgt, OUT, I"_varargs");
		} else {
			WRITE(", i7val %S", name);
		}
	}
	DISCARD_TEXT(name)
}

int C_array_entry_count = 0;
text_stream *C_array_name = NULL;

void CTarget::begin_array(code_generation_target *cgt, code_generation *gen, text_stream *array_name, int format) {
	generated_segment *saved = CodeGen::select(gen, c_predeclarations_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#define ");
	CTarget::mangle(cgt, OUT, array_name);
	WRITE(" %d // An array in format %d\n", C_GEN_DATA(extent_of_i7mem), format);
	CodeGen::deselect(gen, saved);

	if (C_array_name == NULL) C_array_name = Str::new();
	Str::clear(C_array_name); WRITE_TO(C_array_name, "%S", array_name);
	C_array_entry_count = 0;

	if ((format == TABLE_ARRAY_FORMAT) || (format == BUFFER_ARRAY_FORMAT)) {
		TEMPORARY_TEXT(extname)
		WRITE_TO(extname, "xt_%S", array_name);
		CTarget::array_entry(cgt, gen, extname, format);
		DISCARD_TEXT(extname)
	}
}

void CTarget::array_entry(code_generation_target *cgt, code_generation *gen, text_stream *entry, int format) {
	generated_segment *saved = CodeGen::select(gen, c_mem_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	if ((format == TABLE_ARRAY_FORMAT) || (format == WORD_ARRAY_FORMAT)) {
		WRITE("    I7BYTE_0(%S), I7BYTE_1(%S), I7BYTE_2(%S), I7BYTE_3(%S),\n",
			entry, entry, entry, entry);
		C_GEN_DATA(extent_of_i7mem) += 4;
	} else {
		WRITE("    (i7byte) %S,\n", entry);
		C_GEN_DATA(extent_of_i7mem) += 1;
	}
	CodeGen::deselect(gen, saved);
	C_array_entry_count++;
}

void CTarget::end_array(code_generation_target *cgt, code_generation *gen, int format) {
	generated_segment *saved = CodeGen::select(gen, c_predeclarations_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	if ((format == TABLE_ARRAY_FORMAT) || (format == BUFFER_ARRAY_FORMAT)) {
		WRITE("#define xt_%S %d\n", C_array_name, C_array_entry_count-1);
	}
	CodeGen::deselect(gen, saved);
}

int CTarget::basically_an_array_write(inter_tree *I, inter_tree_node *P) {
	int reffed = FALSE;
	while (P->W.data[ID_IFLD] == REFERENCE_IST) {
		P = InterTree::first_child(P);
		reffed = TRUE;
	}
	if (P->W.data[ID_IFLD] == INV_IST) {
		if (P->W.data[METHOD_INV_IFLD] == INVOKED_PRIMITIVE) {
			inter_symbol *prim = Inter::Inv::invokee(P);
			inter_ti bip = Primitives::to_bip(I, prim);
			if (bip == LOOKUPREF_BIP) return TRUE;
			if ((bip == LOOKUP_BIP) && (reffed)) return TRUE;
		}
	}
	return FALSE;
}

int CTarget::basically_a_property_write(inter_tree *I, inter_tree_node *P) {
	int reffed = FALSE;
	while (P->W.data[ID_IFLD] == REFERENCE_IST) {
		P = InterTree::first_child(P);
		reffed = TRUE;
	}
	if (P->W.data[ID_IFLD] == INV_IST) {
		if (P->W.data[METHOD_INV_IFLD] == INVOKED_PRIMITIVE) {
			inter_symbol *prim = Inter::Inv::invokee(P);
			inter_ti bip = Primitives::to_bip(I, prim);
			if (bip == PROPERTYVALUE_BIP) return TRUE;
		}
	}
	return FALSE;
}

void CTarget::new_fake_action(code_generation_target *cgt, code_generation *gen, text_stream *name) {
	generated_segment *saved = CodeGen::select(gen, c_predeclarations_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#define i7_ss_%S %d\n", name, C_GEN_DATA(C_action_count)++);
	CodeGen::deselect(gen, saved);
}
