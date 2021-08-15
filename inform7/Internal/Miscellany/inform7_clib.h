/* This is a library of C code to support Inform or other Inter programs compiled
   tp ANSI C. It was generated mechanically from the Inter source code, so to
   change it, edit that and not this. */

#include <stdlib.h>
#include <stdio.h>
#include <math.h>

#define i7_mgl_Grammar__Version 2
i7val i7_mgl_debug_flag = 0;
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

i7val i7_tmp = 0;

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
#define i7_lvalue_SET 1
#define i7_lvalue_PREDEC 2
#define i7_lvalue_POSTDEC 3
#define i7_lvalue_PREINC 4
#define i7_lvalue_POSTINC 5
#define i7_lvalue_SETBIT 6
#define i7_lvalue_CLEARBIT 7
i7byte i7mem[];
i7val i7_read_word(i7byte data[], i7val array_address, i7val array_index) {
	int byte_position = array_address + 4*array_index;
	return             (i7val) data[byte_position]      +
	            0x100*((i7val) data[byte_position + 1]) +
		      0x10000*((i7val) data[byte_position + 2]) +
		    0x1000000*((i7val) data[byte_position + 3]);
}
#define I7BYTE_3(V) ((V & 0xFF000000) >> 24)
#define I7BYTE_2(V) ((V & 0x00FF0000) >> 16)
#define I7BYTE_1(V) ((V & 0x0000FF00) >> 8)
#define I7BYTE_0(V)  (V & 0x000000FF)

i7val i7_write_word(i7byte data[], i7val array_address, i7val array_index, i7val new_val, int way) {
	i7val old_val = i7_read_word(data, array_address, array_index);
	i7val return_val = new_val;
	switch (way) {
		case i7_lvalue_PREDEC:   return_val = old_val;   new_val = old_val-1; break;
		case i7_lvalue_POSTDEC:  return_val = old_val-1; new_val = old_val-1; break;
		case i7_lvalue_PREINC:   return_val = old_val;   new_val = old_val+1; break;
		case i7_lvalue_POSTINC:  return_val = old_val+1; new_val = old_val+1; break;
		case i7_lvalue_SETBIT:   new_val = old_val | new_val; return_val = new_val; break;
		case i7_lvalue_CLEARBIT: new_val = old_val &(~new_val); return_val = new_val; break;
	}
	int byte_position = array_address + 4*array_index;
	data[byte_position]   = I7BYTE_0(new_val);
	data[byte_position+1] = I7BYTE_1(new_val);
	data[byte_position+2] = I7BYTE_2(new_val);
	data[byte_position+3] = I7BYTE_3(new_val);
	return return_val;
}
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
int i7_seed = 197;

i7val fn_i7_mgl_random(int n, i7val v) {
	if (i7_seed < 1000) return ((i7val) ((i7_seed++) % n));
	i7_seed = i7_seed*i7_seed;
	return (((i7_seed*i7_seed) & 0xFF00) / 0x100) % n;
}

void glulx_setrandom(i7val x) {
	i7_seed = (int) x;
}
void glulx_add(i7val x, i7val y, i7val *z) {
	if (z) *z = x + y;
}

void glulx_sub(i7val x, i7val y, i7val *z) {
	if (z) *z = x - y;
}

void glulx_neg(i7val x, i7val *y) {
	if (y) *y = -x;
}

void glulx_mul(i7val x, i7val y, i7val *z) {
	if (z) *z = x * y;
}

void glulx_div(i7val x, i7val y, i7val *z) {
	if (y == 0) { printf("Division of %d by 0\n", x); if (z) *z = 1; return; }
	int result, ax, ay;
	/* Since C doesn't guarantee the results of division of negative
	   numbers, we carefully convert everything to positive values
	   first. They have to be unsigned values, too, otherwise the
	   0x80000000 case goes wonky. */
	if (x < 0) {
		ax = (-x);
		if (y < 0) {
			ay = (-y);
			result = ax / ay;
		} else {
			ay = y;
			result = -(ax / ay);
		}
	} else {
		ax = x;
		if (y < 0) {
			ay = (-y);
			result = -(ax / ay);
		} else {
			ay = y;
			result = ax / ay;
		}
	}
	if (z) *z = result;
}

i7val glulx_div_r(i7val x, i7val y) {
	i7val z;
	glulx_div(x, y, &z);
	return z;
}

void glulx_mod(i7val x, i7val y, i7val *z) {
	if (y == 0) { printf("Division of %d by 0\n", x); if (z) *z = 0; return; }
	int result, ax, ay;
	if (y < 0) {
		ay = -y;
	} else {
		ay = y;
	}
	if (x < 0) {
		ax = (-x);
		result = -(ax % ay);
	} else {
		ax = x;
		result = ax % ay;
	}
	if (z) *z = result;
}

i7val glulx_mod_r(i7val x, i7val y) {
	i7val z;
	glulx_mod(x, y, &z);
	return z;
}

typedef float gfloat32;

i7val encode_float(gfloat32 val) {
    i7val res;
    *(gfloat32 *)(&res) = val;
    return res;
}

gfloat32 decode_float(i7val val) {
    gfloat32 res;
    *(i7val *)(&res) = val;
    return res;
}

void glulx_exp(i7val x, i7val *y) {
	*y = encode_float(expf(decode_float(x)));
}

void glulx_fadd(i7val x, i7val y, i7val *z) {
	*z = encode_float(decode_float(x) + decode_float(y));
}

void glulx_fdiv(i7val x, i7val y, i7val *z) {
	*z = encode_float(decode_float(x) / decode_float(y));
}

void glulx_floor(i7val x, i7val *y) {
	*y = encode_float(floorf(decode_float(x)));
}

void glulx_fmod(i7val x, i7val y, i7val *z, i7val *w) {
	float fx = decode_float(x);
	float fy = decode_float(y);
	float fquot = fmodf(fx, fy);
	i7val quot = encode_float(fquot);
	i7val rem = encode_float((fx-fquot) / fy);
	if (rem == 0x0 || rem == 0x80000000) {
		/* When the quotient is zero, the sign has been lost in the
		 shuffle. We'll set that by hand, based on the original
		 arguments. */
		rem = (x ^ y) & 0x80000000;
	}
	if (z) *z = quot;
	if (w) *w = rem;
}

void glulx_fmul(i7val x, i7val y, i7val *z) {
	*z = encode_float(decode_float(x) * decode_float(y));
}

void glulx_fsub(i7val x, i7val y, i7val *z) {
	*z = encode_float(decode_float(x) - decode_float(y));
}

void glulx_ftonumn(i7val x, i7val *y) {
	float fx = decode_float(x);
	i7val result;
	if (!signbit(fx)) {
		if (isnan(fx) || isinf(fx) || (fx > 2147483647.0))
			result = 0x7FFFFFFF;
		else
			result = (i7val) (roundf(fx));
	}
	else {
		if (isnan(fx) || isinf(fx) || (fx < -2147483647.0))
			result = 0x80000000;
		else
			result = (i7val) (roundf(fx));
	}
	*y = result;
}

void glulx_ftonumz(i7val x, i7val *y) {
	float fx = decode_float(x);
 	i7val result;
	if (!signbit(fx)) {
		if (isnan(fx) || isinf(fx) || (fx > 2147483647.0))
			result = 0x7FFFFFFF;
		else
			result = (i7val) (truncf(fx));
	}
	else {
		if (isnan(fx) || isinf(fx) || (fx < -2147483647.0))
			result = 0x80000000;
		else
			result = (i7val) (truncf(fx));
	}
	*y = result;
}

void glulx_numtof(i7val x, i7val *y) {
	*y = encode_float((float) x);
}

int glulx_jfeq(i7val x, i7val y, i7val z) {
	int result;
	if ((z & 0x7F800000) == 0x7F800000 && (z & 0x007FFFFF) != 0) {
		/* The delta is NaN, which can never match. */
		result = 0;
	} else if ((x == 0x7F800000 || x == 0xFF800000)
			&& (y == 0x7F800000 || y == 0xFF800000)) {
		/* Both are infinite. Opposite infinities are never equal,
		even if the difference is infinite, so this is easy. */
		result = (x == y);
	} else {
		float fx = decode_float(y) - decode_float(x);
		float fy = fabs(decode_float(z));
		result = (fx <= fy && fx >= -fy);
	}
	if (!result) return 1;
	return 0;
}

int glulx_jfne(i7val x, i7val y, i7val z) {
	int result;
	if ((z & 0x7F800000) == 0x7F800000 && (z & 0x007FFFFF) != 0) {
		/* The delta is NaN, which can never match. */
		result = 0;
	} else if ((x == 0x7F800000 || x == 0xFF800000)
			&& (y == 0x7F800000 || y == 0xFF800000)) {
		/* Both are infinite. Opposite infinities are never equal,
		even if the difference is infinite, so this is easy. */
		result = (x == y);
	} else {
		float fx = decode_float(y) - decode_float(x);
		float fy = fabs(decode_float(z));
		result = (fx <= fy && fx >= -fy);
	}
	if (!result) return 1;
}

int glulx_jfge(i7val x, i7val y) {
	if (isgreaterequal(decode_float(x), decode_float(y))) return 1;
	return 0;
}

int glulx_jflt(i7val x, i7val y) {
	if (isless(decode_float(x), decode_float(y))) return 1;
	return 0;
}

int glulx_jisinf(i7val x) {
	if (isinf(decode_float(x))) return 1;
	return 0;
}

int glulx_jisnan(i7val x) {
	if (isnan(decode_float(x))) return 1;
	return 0;
}

void glulx_log(i7val x, i7val *y) {
	*y = encode_float(logf(decode_float(x)));
}

void glulx_acos(i7val x, i7val *y) {
	*y = encode_float(acosf(decode_float(x)));
}

void glulx_asin(i7val x, i7val *y) {
	*y = encode_float(asinf(decode_float(x)));
}

void glulx_atan(i7val x, i7val *y) {
	*y = encode_float(atanf(decode_float(x)));
}

void glulx_ceil(i7val x, i7val *y) {
	*y = encode_float(ceilf(decode_float(x)));
}

void glulx_cos(i7val x, i7val *y) {
	*y = encode_float(cosf(decode_float(x)));
}

void glulx_pow(i7val x, i7val y, i7val *z) {
	if (decode_float(x) == 1.0f)
		*z = encode_float(1.0f);
	else if ((decode_float(y) == 0.0f) || (decode_float(y) == -0.0f))
		*z = encode_float(1.0f);
	else if ((decode_float(x) == -1.0f) && isinf(decode_float(y)))
		*z = encode_float(1.0f);
	else
		*z = encode_float(powf(decode_float(x), decode_float(y)));
}

void glulx_sin(i7val x, i7val *y) {
	*y = encode_float(sinf(decode_float(x)));
}

void glulx_sqrt(i7val x, i7val *y) {
	*y = encode_float(sqrtf(decode_float(x)));
}

void glulx_tan(i7val x, i7val *y) {
	*y = encode_float(tanf(decode_float(x)));
}
i7val fn_i7_mgl_metaclass(int n, i7val id) {
	if (id <= 0) return 0;
	if (id >= I7VAL_FUNCTIONS_BASE) return i7_mgl_Routine;
	if (id >= I7VAL_STRINGS_BASE) return i7_mgl_String;
	return i7_metaclass_of[id];
}
int i7_ofclass(i7val id, i7val cl_id) {
	if ((id <= 0) || (cl_id <= 0)) return 0;
	if (id >= I7VAL_FUNCTIONS_BASE) {
		if (cl_id == i7_mgl_Routine) return 1;
		return 0;
	}
	if (id >= I7VAL_STRINGS_BASE) {
		if (cl_id == i7_mgl_String) return 1;
		return 0;
	}
	if (id == i7_mgl_Class) {
		if (cl_id == i7_mgl_Class) return 1;
		return 0;
	}
	int cl_found = i7_class_of[id];
	while (cl_found != i7_mgl_Class) {
		if (cl_id == cl_found) return 1;
		cl_found = i7_class_of[cl_found];
	}
	return 0;
}
typedef struct i7_property_set {
	i7val value[i7_no_property_ids];
	int value_set[i7_no_property_ids];
} i7_property_set;
i7_property_set i7_properties[i7_max_objects];

void i7_write_prop_value(i7val owner_id, i7val prop_id, i7val val) {
	if ((owner_id <= 0) || (owner_id >= i7_max_objects) ||
		(prop_id < 0) || (prop_id >= i7_no_property_ids)) {
		printf("impossible property write (%d, %d)\n", owner_id, prop_id);
		exit(1);
	}
	i7_properties[(int) owner_id].value[(int) prop_id] = val;
	i7_properties[(int) owner_id].value_set[(int) prop_id] = 1;
}
i7val i7_read_prop_value(i7val owner_id, i7val prop_id) {
	if ((owner_id <= 0) || (owner_id >= i7_max_objects) ||
		(prop_id < 0) || (prop_id >= i7_no_property_ids)) return 0;
	while (i7_properties[(int) owner_id].value_set[(int) prop_id] == 0) {
		owner_id = i7_class_of[owner_id];
	}
	return i7_properties[(int) owner_id].value[(int) prop_id];
}

i7val i7_change_prop_value(i7val obj, i7val pr, i7val to, int way) {
	i7val val = i7_read_prop_value(obj, pr), new_val = val;
	switch (way) {
		case i7_lvalue_SET:      i7_write_prop_value(obj, pr, to); new_val = to; break;
		case i7_lvalue_PREDEC:   new_val = val; i7_write_prop_value(obj, pr, val-1); break;
		case i7_lvalue_POSTDEC:  new_val = val-1; i7_write_prop_value(obj, pr, new_val); break;
		case i7_lvalue_PREINC:   new_val = val; i7_write_prop_value(obj, pr, val+1); break;
		case i7_lvalue_POSTINC:  new_val = val+1; i7_write_prop_value(obj, pr, new_val); break;
		case i7_lvalue_SETBIT:   new_val = val | new_val; i7_write_prop_value(obj, pr, new_val); break;
		case i7_lvalue_CLEARBIT: new_val = val &(~new_val); i7_write_prop_value(obj, pr, new_val); break;
	}
	return new_val;
}

void i7_give(i7val owner, i7val prop, i7val val) {
	i7_write_prop_value(owner, prop, val);
}

i7val i7_prop_len(i7val obj, i7val pr) {
	printf("Unimplemented: i7_prop_len.\n");
	return 0;
}

i7val i7_prop_addr(i7val obj, i7val pr) {
	printf("Unimplemented: i7_prop_addr.\n");
	return 0;
}

void i7_move(i7val obj, i7val to) {
	printf("Unimplemented: i7_move.\n");
}
int i7_has(i7val obj, i7val attr) {
	if (i7_read_prop_value(obj, attr)) return 1;
	return 0;
}

int i7_provides(i7val owner_id, i7val prop_id) {
	if ((owner_id <= 0) || (owner_id >= i7_max_objects) ||
		(prop_id < 0) || (prop_id >= i7_no_property_ids)) return 0;
	while (owner_id != 1) {
		if (i7_properties[(int) owner_id].value_set[(int) prop_id] == 1)
			return 1;
		owner_id = i7_class_of[owner_id];
	}
	return 0;
}

int i7_in(i7val obj1, i7val obj2) {
	printf("Unimplemented: i7_in.\n");
	return 0;
}
typedef struct i7varargs {
	i7val args[10];
} i7varargs;

i7val i7_mgl_self = 0;

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
#define i7_bold 1
#define i7_roman 2
#define i7_underline 3
#define i7_reverse 4

void i7_style(int what) {
}

void i7_font(int what) {
}

void i7_print_decimal(i7val x) {
	printf("%d", (int) x);
}

void i7_print_char(i7val x) {
	printf("%c", (int) x);
}

void i7_print_C_string(char *c_string) {
	if (c_string)
		for (int i=0; c_string[i]; i++)
			i7_print_char((i7val) c_string[i]);
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

void i7_print_box(i7val x) {
	printf("Unimplemented: i7_print_box.\n");
}

void i7_read(i7val x) {
	printf("Unimplemented: i7_read.\n");
}
