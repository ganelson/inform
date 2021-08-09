#include <stdlib.h>
#include <stdio.h>

typedef int i7val;
typedef unsigned char i7byte;
typedef struct i7varargs {
	i7val args[10];
} i7varargs;

i7val i7_tmp = 0;
int i7_seed = 197;


i7val i7_prop_value(i7val obj, i7val pr) {
	printf("Unimplemented: i7_prop_value.\n");
	return 0;
}

#define i7_cpv_SET 1
#define i7_cpv_PREDEC 2
#define i7_cpv_POSTDEC 3
#define i7_cpv_PREINC 4
#define i7_cpv_POSTINC 5

void i7_assign(i7val owner, i7val prop, i7val val, i7val inst) {
	printf("Unimplemented: i7_assign.\n");
}

i7val i7_change_prop_value(i7val obj, i7val pr, i7val to, int way) {
	i7val val = i7_prop_value(obj, pr), new_val = val;
	switch (way) {
		case i7_cpv_SET:     i7_assign(obj, pr, to, 1); new_val = to; break;
		case i7_cpv_PREDEC:  new_val = val; i7_assign(obj, pr, val-1, 1); break;
		case i7_cpv_POSTDEC: new_val = val-1; i7_assign(obj, pr, new_val, 1); break;
		case i7_cpv_PREINC:  new_val = val; i7_assign(obj, pr, val+1, 1); break;
		case i7_cpv_POSTINC: new_val = val+1; i7_assign(obj, pr, new_val, 1); break;
	}
	return new_val;
}

void i7_give(i7val owner, i7val prop, i7val val) {
	i7_assign(owner, prop, val, 1);
}

i7val i7_prop_len(i7val obj, i7val pr) {
	printf("Unimplemented: i7_prop_len.\n");
	return 0;
}

i7val i7_prop_addr(i7val obj, i7val pr) {
	printf("Unimplemented: i7_prop_addr.\n");
	return 0;
}

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

int i7_ofclass(i7val obj, i7val cl) {
	printf("Unimplemented: i7_ofclass.\n");
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

i7val fn_i7_mgl_metaclass(int n, i7val v) {
	printf("Unimplemented: fn_i7_mgl_metaclass.\n");
	return 0;
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
