#include <stdlib.h>
#include <stdio.h>

typedef int i7val;
typedef unsigned char i7byte;
typedef struct i7varargs {
	i7val args[10];
} i7varargs;

i7val i7_tmp = 0;

#define I7BYTE_3(V) ((V & 0xFF000000) >> 24)
#define I7BYTE_2(V) ((V & 0x00FF0000) >> 16)
#define I7BYTE_1(V) ((V & 0x0000FF00) >> 8)
#define I7BYTE_0(V) (V & 0x000000FF)

i7val i7_lookup(i7byte i7bytes[], i7val offset, i7val ind) {
	ind = offset + 4*ind;
	return ((i7val) i7bytes[ind]) + 0x100*((i7val) i7bytes[ind+1]) +
		0x10000*((i7val) i7bytes[ind+2]) + 0x1000000*((i7val) i7bytes[ind+3]);
}

void write_i7_lookup(i7byte i7bytes[], i7val offset, i7val ind, i7val V) {
	ind = offset + 4*ind;
	i7bytes[ind]   = I7BYTE_0(V);
	i7bytes[ind+1] = I7BYTE_1(V);
	i7bytes[ind+2] = I7BYTE_2(V);
	i7bytes[ind+3] = I7BYTE_3(V);
}

void glulx_accelfunc(i7val x, i7val y) {
	printf("Unimplemented.\n");
}

void glulx_accelparam(i7val x, i7val y) {
	printf("Unimplemented.\n");
}

void glulx_call(i7val x, i7val i7varargc, i7val z) {
	printf("Unimplemented.\n");
}

void glulx_copy(i7val x, i7val y) {
	printf("Unimplemented.\n");
}

void glulx_div(i7val x, i7val y, i7val z) {
	printf("Unimplemented.\n");
}

void glulx_exp(i7val x, i7val y) {
	printf("Unimplemented.\n");
}

void glulx_fadd(i7val x, i7val y, i7val z) {
	printf("Unimplemented.\n");
}

void glulx_fdiv(i7val x, i7val y, i7val z) {
	printf("Unimplemented.\n");
}

void glulx_floor(i7val x, i7val y) {
	printf("Unimplemented.\n");
}

void glulx_fmod(i7val x, i7val y, i7val z, i7val w) {
	printf("Unimplemented.\n");
}

void glulx_fmul(i7val x, i7val y, i7val z) {
	printf("Unimplemented.\n");
}

void glulx_fsub(i7val x, i7val y, i7val z) {
	printf("Unimplemented.\n");
}

void glulx_ftonumn(i7val x, i7val y) {
	printf("Unimplemented.\n");
}

void glulx_ftonumz(i7val x, i7val y) {
	printf("Unimplemented.\n");
}

void glulx_gestalt(i7val x, i7val y, i7val z) {
	printf("Unimplemented.\n");
}

void glulx_glk(i7val x, i7val i7varargc, i7val z) {
	printf("Unimplemented.\n");
}

int glulx_jeq(i7val x, i7val y) {
	printf("Unimplemented.\n");
	return 0;
}

int glulx_jfeq(i7val x, i7val y, i7val z) {
	printf("Unimplemented.\n");
	return 0;
}

int glulx_jfge(i7val x, i7val y) {
	printf("Unimplemented.\n");
	return 0;
}

int glulx_jflt(i7val x, i7val y) {
	printf("Unimplemented.\n");
	return 0;
}

int glulx_jisinf(i7val x) {
	printf("Unimplemented.\n");
	return 0;
}

int glulx_jisnan(i7val x) {
	printf("Unimplemented.\n");
	return 0;
}

int glulx_jleu(i7val x, i7val y) {
	printf("Unimplemented.\n");
	return 0;
}

int glulx_jnz(i7val x) {
	printf("Unimplemented.\n");
	return 0;
}

int glulx_jz(i7val x) {
	printf("Unimplemented.\n");
	return 0;
}

void glulx_log(i7val x, i7val y) {
	printf("Unimplemented.\n");
}

void glulx_malloc(i7val x, i7val y) {
	printf("Unimplemented.\n");
}

void glulx_mcopy(i7val x, i7val y, i7val z) {
	printf("Unimplemented.\n");
}

void glulx_mfree(i7val x) {
	printf("Unimplemented.\n");
}

void glulx_mod(i7val x, i7val y, i7val z) {
	printf("Unimplemented.\n");
}

void glulx_neg(i7val x, i7val y) {
	printf("Unimplemented.\n");
}

void glulx_numtof(i7val x, i7val y) {
	printf("Unimplemented.\n");
}

void glulx_quit(void) {
	printf("Unimplemented.\n");
}

void glulx_random(i7val x, i7val y) {
	printf("Unimplemented.\n");
}

void glulx_setiosys(i7val x, i7val y) {
	printf("Unimplemented.\n");
}

void glulx_setrandom(i7val x) {
	printf("Unimplemented.\n");
}

void glulx_streamchar(i7val x) {
	printf("%c", (int) x);
}

void glulx_streamnum(i7val x) {
	printf("Unimplemented.\n");
}

void glulx_streamstr(i7val x) {
	printf("Unimplemented.\n");
}

void glulx_streamunichar(i7val x) {
	printf("%c", (int) x);
}

void glulx_sub(i7val x, i7val y, i7val z) {
	printf("Unimplemented.\n");
}

void glulx_ushiftr(i7val x, i7val y, i7val z) {
	printf("Unimplemented.\n");
}

int i7_has(i7val obj, i7val attr) {
	printf("Unimplemented.\n");
	return 0;
}

int i7_ofclass(i7val obj, i7val cl) {
	printf("Unimplemented.\n");
	return 0;
}

void i7_print_address(i7val x) {
	printf("Unimplemented.\n");
}

void i7_print_char(i7val x) {
	printf("%c", (int) x);
}

void i7_print_def_art(i7val x) {
	printf("Unimplemented.\n");
}

void i7_print_indef_art(i7val x) {
	printf("Unimplemented.\n");
}

void i7_print_name(i7val x) {
	printf("Unimplemented.\n");
}

void i7_print_object(i7val x) {
	printf("Unimplemented.\n");
}

void i7_print_property(i7val x) {
	printf("Unimplemented.\n");
}

int i7_provides(i7val obj, i7val prop) {
	printf("Unimplemented.\n");
	return 0;
}

i7val i7_pull(void) {
	printf("Unimplemented.\n");
	return (i7val) 0;
}

void i7_push(i7val x) {
	printf("Unimplemented.\n");
}

i7val i7_prop_value(i7val obj, i7val pr) {
	printf("Unimplemented.\n");
	return 0;
}

i7val i7_prop_len(i7val obj, i7val pr) {
	printf("Unimplemented.\n");
	return 0;
}

i7val i7_prop_addr(i7val obj, i7val pr) {
	printf("Unimplemented.\n");
	return 0;
}

i7val fn_i7_mgl_metaclass(int n, i7val v) {
	printf("Unimplemented.\n");
	return 0;
}

i7val fn_i7_mgl_random(int n, i7val v) {
	printf("Unimplemented.\n");
	return 0;
}

i7val i7_gen_call(i7val fn_ref, i7val *args, int argc, int call_message) {
	printf("Unimplemented.\n");
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
	printf("Unimplemented.\n");
	return 0;
}

i7val fn_i7_mgl_CP__Tab(int argc, i7val x) {
	printf("Unimplemented.\n");
	return 0;
}

i7val fn_i7_mgl_RA__Pr(int argc, i7val x) {
	printf("Unimplemented.\n");
	return 0;
}

i7val fn_i7_mgl_RL__Pr(int argc, i7val x) {
	printf("Unimplemented.\n");
	return 0;
}

i7val fn_i7_mgl_OC__Cl(int argc, i7val x) {
	printf("Unimplemented.\n");
	return 0;
}

i7val fn_i7_mgl_RV__Pr(int argc, i7val x) {
	printf("Unimplemented.\n");
	return 0;
}

i7val fn_i7_mgl_OP__Pr(int argc, i7val x) {
	printf("Unimplemented.\n");
	return 0;
}

i7val fn_i7_mgl_CA__Pr(int argc, i7val x) {
	printf("Unimplemented.\n");
	return 0;
}

i7val i7_mgl_sharp_classes_table = 0;
i7val i7_mgl_NUM_ATTR_BYTES = 0;
i7val i7_mgl_sharp_cpv__start = 0;
i7val i7_mgl_sharp_identifiers_table = 0;
i7val i7_mgl_sharp_globals_array = 0;
i7val i7_mgl_sharp_gself = 0;
