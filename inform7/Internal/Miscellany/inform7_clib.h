/* This is a library of C code to support Inform or other Inter programs compiled
   tp ANSI C. It was generated mechanically from the Inter source code, so to
   change it, edit that and not this. */

#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <time.h>
#include <ctype.h>

void i7_fatal_exit(void) {
	printf("*** Fatal error: halted ***\n");
	int x = 0; printf("%d", 1/x);
	exit(1);
}

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
	if ((byte_position < 0) || (byte_position >= i7_himem)) {
		printf("Memory access out of range: %d\n", byte_position);
		i7_fatal_exit();
	}
	return             (i7val) data[byte_position + 3]      +
	            0x100*((i7val) data[byte_position + 2]) +
		      0x10000*((i7val) data[byte_position + 1]) +
		    0x1000000*((i7val) data[byte_position + 0]);
}
#define I7BYTE_0(V) ((V & 0xFF000000) >> 24)
#define I7BYTE_1(V) ((V & 0x00FF0000) >> 16)
#define I7BYTE_2(V) ((V & 0x0000FF00) >> 8)
#define I7BYTE_3(V)  (V & 0x000000FF)

i7val i7_write_word(i7byte data[], i7val array_address, i7val array_index, i7val new_val, int way) {
	i7val old_val = i7_read_word(data, array_address, array_index);
	i7val return_val = new_val;
	switch (way) {
		case i7_lvalue_PREDEC:   return_val = old_val-1;   new_val = old_val-1; break;
		case i7_lvalue_POSTDEC:  return_val = old_val; new_val = old_val-1; break;
		case i7_lvalue_PREINC:   return_val = old_val+1;   new_val = old_val+1; break;
		case i7_lvalue_POSTINC:  return_val = old_val; new_val = old_val+1; break;
		case i7_lvalue_SETBIT:   new_val = old_val | new_val; return_val = new_val; break;
		case i7_lvalue_CLEARBIT: new_val = old_val &(~new_val); return_val = new_val; break;
	}
	int byte_position = array_address + 4*array_index;
	if ((byte_position < 0) || (byte_position >= i7_himem)) {
		printf("Memory access out of range: %d\n", byte_position);
		i7_fatal_exit();
	}
	data[byte_position]   = I7BYTE_0(new_val);
	data[byte_position+1] = I7BYTE_1(new_val);
	data[byte_position+2] = I7BYTE_2(new_val);
	data[byte_position+3] = I7BYTE_3(new_val);
	return return_val;
}
void glulx_mcopy(i7val x, i7val y, i7val z) {
    if (z < y)
		for (i7val i=0; i<x; i++) i7mem[z+i] = i7mem[y+i];
    else
		for (i7val i=x-1; i>=0; i--) i7mem[z+i] = i7mem[y+i];
}

void glulx_malloc(i7val x, i7val y) {
	printf("Unimplemented: glulx_malloc.\n");
	i7_fatal_exit();
}

void glulx_mfree(i7val x) {
	printf("Unimplemented: glulx_mfree.\n");
	i7_fatal_exit();
}
i7val i7_mgl_sp = 0;
#define I7_ASM_STACK_CAPACITY 128
i7val i7_asm_stack[I7_ASM_STACK_CAPACITY];
int i7_asm_stack_pointer = 0;

void i7_debug_stack(char *N) {
//	printf("Called %s: stack %d ", N, i7_asm_stack_pointer);
//	for (int i=0; i<i7_asm_stack_pointer; i++) printf("%d -> ", i7_asm_stack[i]);
//	printf("\n");
}

i7val i7_pull(void) {
	if (i7_asm_stack_pointer <= 0) { printf("Stack underflow\n"); int x = 0; printf("%d", 1/x); return (i7val) 0; }
	return i7_asm_stack[--i7_asm_stack_pointer];
}

void i7_push(i7val x) {
	if (i7_asm_stack_pointer >= I7_ASM_STACK_CAPACITY) { printf("Stack overflow\n"); return; }
	i7_asm_stack[i7_asm_stack_pointer++] = x;
}
void glulx_accelfunc(i7val x, i7val y) {
	printf("Unimplemented: glulx_accelfunc.\n");
	i7_fatal_exit();
}

void glulx_accelparam(i7val x, i7val y) {
	printf("Unimplemented: glulx_accelparam.\n");
	i7_fatal_exit();
}

void glulx_copy(i7val x, i7val *y) {
	i7_debug_stack("glulx_copy");
	if (y) *y = x;
}

void glulx_gestalt(i7val x, i7val y, i7val *z) {
	*z = 1;
}

int glulx_jeq(i7val x, i7val y) {
	if (x == y) return 1;
	return 0;
}

void glulx_nop(void) {
}

int glulx_jleu(i7val x, i7val y) {
	i7uval ux, uy;
	*((i7val *) &ux) = x; *((i7val *) &uy) = y;
	if (ux <= uy) return 1;
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

void glulx_quit(void) {
	i7_fatal_exit();
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
	i7_fatal_exit();
}

void glulx_streamunichar(i7val x) {
	i7_print_char(x);
}

void glulx_ushiftr(i7val x, i7val y, i7val z) {
	printf("Unimplemented: glulx_ushiftr.\n");
	i7_fatal_exit();
}

void glulx_aload(i7val x, i7val y, i7val *z) {
	printf("Unimplemented: glulx_aload\n");
	i7_fatal_exit();
}

void glulx_aloadb(i7val x, i7val y, i7val *z) {
	printf("Unimplemented: glulx_aloadb\n");
	i7_fatal_exit();
}

void glulx_aloads(i7val x, i7val y, i7val *z) {
	printf("Unimplemented: glulx_aloads\n");
	i7_fatal_exit();
}

void glulx_binarysearch(i7val l1, i7val l2, i7val l3, i7val l4, i7val l5, i7val l6, i7val l7, i7val *s1) {
	printf("Unimplemented: glulx_binarysearch\n");
	i7_fatal_exit();
}

void glulx_shiftl(i7val x, i7val y, i7val *z) {
	printf("Unimplemented: glulx_shiftl\n");
	i7_fatal_exit();
}
/* Return a random number in the range 0 to 2^32-1. */
uint32_t i7_random() {
	return (random() << 16) ^ random();
}

void glulx_random(i7val x, i7val *y) {
	uint32_t value;
	if (x == 0) value = i7_random();
	else if (x >= 1) value = i7_random() % (uint32_t) (x);
	else value = -(i7_random() % (uint32_t) (-x));
	*y = (i7val) value;
}

i7val fn_i7_mgl_random(int n, i7val x) {
	i7val r;
	glulx_random(x, &r);
	return r+1;
}

/* Set the random-number seed; zero means use as random a source as
   possible. */
void glulx_setrandom(i7val s) {
	uint32_t seed;
	*((i7val *) &seed) = s;
	if (seed == 0) seed = time(NULL);
	srandom(seed);
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
	if (result) return 1;
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
	return 0;
}

int glulx_jfge(i7val x, i7val y) {
	if (decode_float(x) >= decode_float(y)) return 1;
	return 0;
}

int glulx_jflt(i7val x, i7val y) {
	if (decode_float(x) < decode_float(y)) return 1;
	return 0;
}

int glulx_jisinf(i7val x) {
    if (x == 0x7F800000 || x == 0xFF800000) return 1;
	return 0;
}

int glulx_jisnan(i7val x) {
    if ((x & 0x7F800000) == 0x7F800000 && (x & 0x007FFFFF) != 0) return 1;
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
	if (cl_id == i7_mgl_Object) {
		if (i7_metaclass_of[id] == i7_mgl_Object) return 1;
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
		i7_fatal_exit();
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
		case i7_lvalue_PREDEC:   new_val = val-1; i7_write_prop_value(obj, pr, val-1); break;
		case i7_lvalue_POSTDEC:  new_val = val; i7_write_prop_value(obj, pr, val-1); break;
		case i7_lvalue_PREINC:   new_val = val+1; i7_write_prop_value(obj, pr, val+1); break;
		case i7_lvalue_POSTINC:  new_val = val; i7_write_prop_value(obj, pr, val+1); break;
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

void glulx_call(i7val fn_ref, i7val varargc, i7val *z) {
	i7val args[10]; for (int i=0; i<10; i++) args[i] = 0;
	for (int i=0; i<varargc; i++) args[i] = i7_pull();
	i7val rv = i7_gen_call(fn_ref, args, varargc, 0);
	if (z) *z = rv;
}
#define i7_bold 1
#define i7_roman 2
#define i7_underline 3
#define i7_reverse 4

void i7_style(int what) {
}

void i7_font(int what) {
}

#define fileusage_Data (0x00)
#define fileusage_SavedGame (0x01)
#define fileusage_Transcript (0x02)
#define fileusage_InputRecord (0x03)
#define fileusage_TypeMask (0x0f)

#define fileusage_TextMode   (0x100)
#define fileusage_BinaryMode (0x000)

#define filemode_Write (0x01)
#define filemode_Read (0x02)
#define filemode_ReadWrite (0x03)
#define filemode_WriteAppend (0x05)

typedef struct i7_fileref {
	i7val usage;
	i7val name;
	i7val rock;
	FILE *handle;
} i7_fileref;

i7_fileref filerefs[128];
int i7_no_filerefs = 0;

i7val i7_do_glk_fileref_create_by_name(i7val usage, i7val name, i7val rock) {
	if (i7_no_filerefs >= 128) {
		fprintf(stderr, "Out of streams\n"); i7_fatal_exit();
	}
	int id = i7_no_filerefs++;
	filerefs[id].usage = usage;
	filerefs[id].name = name;
	filerefs[id].rock = rock;
	filerefs[id].handle = NULL;
	return id;
}

int i7_fseek(int id, int pos, int origin) {
	if ((id < 0) || (id >= 128)) { fprintf(stderr, "Too many files\n"); i7_fatal_exit(); }
	if (filerefs[id].handle == NULL) { fprintf(stderr, "File not open\n"); i7_fatal_exit(); }
// printf("Seek to %d wrt %d\n", pos, origin);
	return fseek(filerefs[id].handle, pos, origin);
}

int i7_ftell(int id) {
	if ((id < 0) || (id >= 128)) { fprintf(stderr, "Too many files\n"); i7_fatal_exit(); }
	if (filerefs[id].handle == NULL) { fprintf(stderr, "File not open\n"); i7_fatal_exit(); }
	int t = i7_ftell(filerefs[id].handle);
// printf("Tell gives %d\n", t);
	return t;
}

int i7_fopen(int id, int mode) {
	if ((id < 0) || (id >= 128)) { fprintf(stderr, "Too many files\n"); i7_fatal_exit(); }
	if (filerefs[id].handle) { fprintf(stderr, "File already open\n"); i7_fatal_exit(); }
	char *c_mode = "r";
	switch (mode) {
		case filemode_Write: c_mode = "w"; break;
		case filemode_Read: c_mode = "r"; break;
		case filemode_ReadWrite: c_mode = "r+"; break;
		case filemode_WriteAppend: c_mode = "r+"; break;
	}
	FILE *h = fopen("marzipan.txt", c_mode);
	if (h == NULL) return 0;
	filerefs[id].handle = h;
// printf("Open mode %s\n", c_mode);
	if (mode == filemode_WriteAppend) i7_fseek(id, 0, SEEK_END);
	return 1;
}

void i7_fclose(int id) {
	if ((id < 0) || (id >= 128)) { fprintf(stderr, "Too many files\n"); i7_fatal_exit(); }
	if (filerefs[id].handle == NULL) { fprintf(stderr, "File not open\n"); i7_fatal_exit(); }
	fclose(filerefs[id].handle);
	filerefs[id].handle = NULL;
// printf("Close\n");
}

i7val i7_do_glk_fileref_does_file_exist(i7val id) {
	if ((id < 0) || (id >= 128)) { fprintf(stderr, "Too many files\n"); i7_fatal_exit(); }
	if (filerefs[id].handle) return 1;
	if (i7_fopen(id, filemode_Read)) {
		i7_fclose(id); return 1;
	}
	return 0;
}

void i7_fputc(int c, int id) {
	if ((id < 0) || (id >= 128)) { fprintf(stderr, "Too many files\n"); i7_fatal_exit(); }
	if (filerefs[id].handle == NULL) { fprintf(stderr, "File not open\n"); i7_fatal_exit(); }
	fputc(c, filerefs[id].handle);
// printf("Put %c\n", c);
}

int i7_fgetc(int id) {
	if ((id < 0) || (id >= 128)) { fprintf(stderr, "Too many files\n"); i7_fatal_exit(); }
	if (filerefs[id].handle == NULL) { fprintf(stderr, "File not open\n"); i7_fatal_exit(); }
	int c = fgetc(filerefs[id].handle);
// printf("Get %c\n", c);
	return c;
}

typedef struct i7_stream {
	FILE *to_file;
	i7val to_file_id;
	wchar_t *to_memory;
	size_t memory_used;
	size_t memory_capacity;
	i7val previous_id;
	i7val write_here_on_closure;
	size_t write_limit;
	int active;
	int encode_UTF8;
	int char_size;
	int chars_read;
	int read_position;
	int end_position;
} i7_stream;

#define I7_MAX_STREAMS 128

i7_stream i7_memory_streams[I7_MAX_STREAMS];

i7val i7_stdout_id = 0, i7_stderr_id = 1, i7_str_id = 0;

i7val i7_do_glk_stream_get_current(void) {
	return i7_str_id;
}

void i7_do_glk_stream_set_current(i7val id) {
	if ((id < 0) || (id >= I7_MAX_STREAMS)) { fprintf(stderr, "Stream ID %d out of range\n", id); i7_fatal_exit(); }
	i7_str_id = id;
}

i7_stream i7_new_stream(FILE *F) {
	i7_stream S;
	S.to_file = F;
	S.to_file_id = -1;
	S.to_memory = NULL;
	S.memory_used = 0;
	S.memory_capacity = 0;
	S.write_here_on_closure = 0;
	S.write_limit = 0;
	S.previous_id = 0;
	S.active = 0;
	S.encode_UTF8 = 0;
	S.char_size = 4;
	S.chars_read = 0;
	S.read_position = 0;
	S.end_position = 0;
	return S;
}

void i7_initialise_streams(void) {
	for (int i=0; i<I7_MAX_STREAMS; i++) i7_memory_streams[i] = i7_new_stream(NULL);
	i7_memory_streams[i7_stdout_id] = i7_new_stream(stdout);
	i7_memory_streams[i7_stdout_id].active = 1;
	i7_memory_streams[i7_stdout_id].encode_UTF8 = 1;
	i7_memory_streams[i7_stderr_id] = i7_new_stream(stderr);
	i7_memory_streams[i7_stderr_id].active = 1;
	i7_memory_streams[i7_stderr_id].encode_UTF8 = 1;
	i7_do_glk_stream_set_current(i7_stdout_id);
}

i7val i7_open_stream(FILE *F) {
	for (int i=0; i<I7_MAX_STREAMS; i++)
		if (i7_memory_streams[i].active == 0) {
			i7_memory_streams[i] = i7_new_stream(F);
			i7_memory_streams[i].active = 1;
			i7_memory_streams[i].previous_id = i7_str_id;
			return i;
		}
	fprintf(stderr, "Out of streams\n"); i7_fatal_exit();
	return 0;
}

i7val i7_do_glk_stream_open_memory(i7val buffer, i7val len, i7val fmode, i7val rock) {
	if (fmode != 1) { fprintf(stderr, "Only file mode 1 supported, not %d\n", fmode); i7_fatal_exit(); }
	i7val id = i7_open_stream(NULL);
	i7_memory_streams[id].write_here_on_closure = buffer;
	i7_memory_streams[id].write_limit = (size_t) len;
	i7_memory_streams[id].char_size = 1;
			i7_str_id = id;
	return id;
}

i7val i7_do_glk_stream_open_memory_uni(i7val buffer, i7val len, i7val fmode, i7val rock) {
	if (fmode != 1) { fprintf(stderr, "Only file mode 1 supported, not %d\n", fmode); i7_fatal_exit(); }
	i7val id = i7_open_stream(NULL);
	i7_memory_streams[id].write_here_on_closure = buffer;
	i7_memory_streams[id].write_limit = (size_t) len;
	i7_memory_streams[id].char_size = 4;
			i7_str_id = id;
	return id;
}

i7val i7_do_glk_stream_open_file(i7val fileref, i7val usage, i7val rock) {
	i7val id = i7_open_stream(NULL);
	i7_memory_streams[id].to_file_id = fileref;
	if (i7_fopen(fileref, usage) == 0) return 0;
	return id;
}

#define seekmode_Start (0)
#define seekmode_Current (1)
#define seekmode_End (2)

void i7_do_glk_stream_set_position(i7val id, i7val pos, i7val seekmode) {
	if ((id < 0) || (id >= I7_MAX_STREAMS)) { fprintf(stderr, "Stream ID %d out of range\n", id); i7_fatal_exit(); }
	i7_stream *S = &(i7_memory_streams[id]);
	if (S->to_file_id >= 0) {
		int origin;
		switch (seekmode) {
			case seekmode_Start: origin = SEEK_SET; break;
			case seekmode_Current: origin = SEEK_CUR; break;
			case seekmode_End: origin = SEEK_END; break;
			default: fprintf(stderr, "Unknown seekmode\n"); i7_fatal_exit();
		}
		i7_fseek(S->to_file_id, pos, origin);
	} else {
		fprintf(stderr, "glk_stream_set_position supported only for file streams\n"); i7_fatal_exit();
	}
}

i7val i7_do_glk_stream_get_position(i7val id) {
	if ((id < 0) || (id >= I7_MAX_STREAMS)) { fprintf(stderr, "Stream ID %d out of range\n", id); i7_fatal_exit(); }
	i7_stream *S = &(i7_memory_streams[id]);
	if (S->to_file_id >= 0) {
		return (i7val) i7_ftell(S->to_file_id);
	}
	return (i7val) S->memory_used;
}

void i7_do_glk_stream_close(i7val id, i7val result) {
	if ((id < 0) || (id >= I7_MAX_STREAMS)) { fprintf(stderr, "Stream ID %d out of range\n", id); i7_fatal_exit(); }
	if (id == 0) { fprintf(stderr, "Cannot close stdout\n"); i7_fatal_exit(); }
	if (id == 1) { fprintf(stderr, "Cannot close stderr\n"); i7_fatal_exit(); }
	i7_stream *S = &(i7_memory_streams[id]);
	if (S->active == 0) { fprintf(stderr, "Stream %d already closed\n", id); i7_fatal_exit(); }
	if (i7_str_id == id) i7_str_id = S->previous_id;
	if (S->write_here_on_closure != 0) {
		if (S->char_size == 4) {
			for (size_t i = 0; i < S->write_limit; i++)
				if (i < S->memory_used)
					i7_write_word(i7mem, S->write_here_on_closure, i, S->to_memory[i], i7_lvalue_SET);
				else
					i7_write_word(i7mem, S->write_here_on_closure, i, 0, i7_lvalue_SET);
		} else {
			for (size_t i = 0; i < S->write_limit; i++)
				if (i < S->memory_used)
					i7mem[S->write_here_on_closure + i] = S->to_memory[i];
				else
					i7mem[S->write_here_on_closure + i] = 0;
		}
	}
	if (result == -1) {
		i7_push(S->chars_read);
		i7_push(S->memory_used);
	} else if (result != 0) {
		i7_write_word(i7mem, result, 0, S->chars_read, i7_lvalue_SET);
		i7_write_word(i7mem, result, 1, S->memory_used, i7_lvalue_SET);
	}
	if (S->to_file_id >= 0) i7_fclose(S->to_file_id);
	S->active = 0;
	S->memory_used = 0;
}

i7val i7_do_glk_char_to_upper(i7val c) {
	return toupper(c);
}

void i7_do_glk_put_char_stream(i7val stream_id, i7val x) {
	i7_stream *S = &(i7_memory_streams[stream_id]);
	if (S->to_file) {
		unsigned int c = (unsigned int) x;
		if (S->encode_UTF8) {
			if (c >= 0x800) {
				fputc(0xE0 + (c >> 12), S->to_file);
				fputc(0x80 + ((c >> 6) & 0x3f), S->to_file);
				fputc(0x80 + (c & 0x3f), S->to_file);
			} else if (c >= 0x80) {
				fputc(0xC0 + (c >> 6), S->to_file);
				fputc(0x80 + (c & 0x3f), S->to_file);
			} else fputc((int) c, S->to_file);
		} else {
			fputc((int) c, S->to_file);
		}
	} else if (S->to_file_id >= 0) {
		i7_fputc((int) x, S->to_file_id);
		S->end_position++;
	} else {
		if (S->memory_used >= S->memory_capacity) {
			size_t needed = 4*S->memory_capacity;
			if (needed == 0) needed = 1024;
			wchar_t *new_data = (wchar_t *) calloc(needed, sizeof(wchar_t));
			if (new_data == NULL) { fprintf(stderr, "Out of memory\n"); i7_fatal_exit(); }
			for (size_t i=0; i<S->memory_used; i++) new_data[i] = S->to_memory[i];
			free(S->to_memory);
			S->to_memory = new_data;
		}
		S->to_memory[S->memory_used++] = (wchar_t) x;
	}
}

i7val i7_do_glk_get_char_stream(i7val stream_id) {
	i7_stream *S = &(i7_memory_streams[stream_id]);
	if (S->to_file_id >= 0) {
		S->chars_read++;
		return i7_fgetc(S->to_file_id);
	}
	return 0;
}

void i7_print_char(i7val x) {
	i7_do_glk_put_char_stream(i7_str_id, x);
}

void i7_print_C_string(char *c_string) {
	if (c_string)
		for (int i=0; c_string[i]; i++)
			i7_print_char((i7val) c_string[i]);
}

void i7_print_decimal(i7val x) {
	char room[32];
	sprintf(room, "%d", (int) x);
	i7_print_C_string(room);
}

#define i7_glk_exit 0x0001
#define i7_glk_set_interrupt_handler 0x0002
#define i7_glk_tick 0x0003
#define i7_glk_gestalt 0x0004
#define i7_glk_gestalt_ext 0x0005
#define i7_glk_window_iterate 0x0020
#define i7_glk_window_get_rock 0x0021
#define i7_glk_window_get_root 0x0022
#define i7_glk_window_open 0x0023
#define i7_glk_window_close 0x0024
#define i7_glk_window_get_size 0x0025
#define i7_glk_window_set_arrangement 0x0026
#define i7_glk_window_get_arrangement 0x0027
#define i7_glk_window_get_type 0x0028
#define i7_glk_window_get_parent 0x0029
#define i7_glk_window_clear 0x002A
#define i7_glk_window_move_cursor 0x002B
#define i7_glk_window_get_stream 0x002C
#define i7_glk_window_set_echo_stream 0x002D
#define i7_glk_window_get_echo_stream 0x002E
#define i7_glk_set_window 0x002F
#define i7_glk_window_get_sibling 0x0030
#define i7_glk_stream_iterate 0x0040
#define i7_glk_stream_get_rock 0x0041
#define i7_glk_stream_open_file 0x0042
#define i7_glk_stream_open_memory 0x0043
#define i7_glk_stream_close 0x0044
#define i7_glk_stream_set_position 0x0045
#define i7_glk_stream_get_position 0x0046
#define i7_glk_stream_set_current 0x0047
#define i7_glk_stream_get_current 0x0048
#define i7_glk_stream_open_resource 0x0049
#define i7_glk_fileref_create_temp 0x0060
#define i7_glk_fileref_create_by_name 0x0061
#define i7_glk_fileref_create_by_prompt 0x0062
#define i7_glk_fileref_destroy 0x0063
#define i7_glk_fileref_iterate 0x0064
#define i7_glk_fileref_get_rock 0x0065
#define i7_glk_fileref_delete_file 0x0066
#define i7_glk_fileref_does_file_exist 0x0067
#define i7_glk_fileref_create_from_fileref 0x0068
#define i7_glk_put_char 0x0080
#define i7_glk_put_char_stream 0x0081
#define i7_glk_put_string 0x0082
#define i7_glk_put_string_stream 0x0083
#define i7_glk_put_buffer 0x0084
#define i7_glk_put_buffer_stream 0x0085
#define i7_glk_set_style 0x0086
#define i7_glk_set_style_stream 0x0087
#define i7_glk_get_char_stream 0x0090
#define i7_glk_get_line_stream 0x0091
#define i7_glk_get_buffer_stream 0x0092
#define i7_glk_char_to_lower 0x00A0
#define i7_glk_char_to_upper 0x00A1
#define i7_glk_stylehint_set 0x00B0
#define i7_glk_stylehint_clear 0x00B1
#define i7_glk_style_distinguish 0x00B2
#define i7_glk_style_measure 0x00B3
#define i7_glk_select 0x00C0
#define i7_glk_select_poll 0x00C1
#define i7_glk_request_line_event 0x00D0
#define i7_glk_cancel_line_event 0x00D1
#define i7_glk_request_char_event 0x00D2
#define i7_glk_cancel_char_event 0x00D3
#define i7_glk_request_mouse_event 0x00D4
#define i7_glk_cancel_mouse_event 0x00D5
#define i7_glk_request_timer_events 0x00D6
#define i7_glk_image_get_info 0x00E0
#define i7_glk_image_draw 0x00E1
#define i7_glk_image_draw_scaled 0x00E2
#define i7_glk_window_flow_break 0x00E8
#define i7_glk_window_erase_rect 0x00E9
#define i7_glk_window_fill_rect 0x00EA
#define i7_glk_window_set_background_color 0x00EB
#define i7_glk_schannel_iterate 0x00F0
#define i7_glk_schannel_get_rock 0x00F1
#define i7_glk_schannel_create 0x00F2
#define i7_glk_schannel_destroy 0x00F3
#define i7_glk_schannel_create_ext 0x00F4
#define i7_glk_schannel_play_multi 0x00F7
#define i7_glk_schannel_play 0x00F8
#define i7_glk_schannel_play_ext 0x00F9
#define i7_glk_schannel_stop 0x00FA
#define i7_glk_schannel_set_volume 0x00FB
#define i7_glk_sound_load_hint 0x00FC
#define i7_glk_schannel_set_volume_ext 0x00FD
#define i7_glk_schannel_pause 0x00FE
#define i7_glk_schannel_unpause 0x00FF
#define i7_glk_set_hyperlink 0x0100
#define i7_glk_set_hyperlink_stream 0x0101
#define i7_glk_request_hyperlink_event 0x0102
#define i7_glk_cancel_hyperlink_event 0x0103
#define i7_glk_buffer_to_lower_case_uni 0x0120
#define i7_glk_buffer_to_upper_case_uni 0x0121
#define i7_glk_buffer_to_title_case_uni 0x0122
#define i7_glk_buffer_canon_decompose_uni 0x0123
#define i7_glk_buffer_canon_normalize_uni 0x0124
#define i7_glk_put_char_uni 0x0128
#define i7_glk_put_string_uni 0x0129
#define i7_glk_put_buffer_uni 0x012A
#define i7_glk_put_char_stream_uni 0x012B
#define i7_glk_put_string_stream_uni 0x012C
#define i7_glk_put_buffer_stream_uni 0x012D
#define i7_glk_get_char_stream_uni 0x0130
#define i7_glk_get_buffer_stream_uni 0x0131
#define i7_glk_get_line_stream_uni 0x0132
#define i7_glk_stream_open_file_uni 0x0138
#define i7_glk_stream_open_memory_uni 0x0139
#define i7_glk_stream_open_resource_uni 0x013A
#define i7_glk_request_char_event_uni 0x0140
#define i7_glk_request_line_event_uni 0x0141
#define i7_glk_set_echo_line_event 0x0150
#define i7_glk_set_terminators_line_event 0x0151
#define i7_glk_current_time 0x0160
#define i7_glk_current_simple_time 0x0161
#define i7_glk_time_to_date_utc 0x0168
#define i7_glk_time_to_date_local 0x0169
#define i7_glk_simple_time_to_date_utc 0x016A
#define i7_glk_simple_time_to_date_local 0x016B
#define i7_glk_date_to_time_utc 0x016C
#define i7_glk_date_to_time_local 0x016D
#define i7_glk_date_to_simple_time_utc 0x016E
#define i7_glk_date_to_simple_time_local 0x016F

void glulx_glk(i7val glk_api_selector, i7val varargc, i7val *z) {
	i7_debug_stack("glulx_glk");
	i7val args[4] = { 0, 0, 0, 0 }, argc = 0;
	while (varargc > 0) {
		i7val v = i7_pull();
		if (argc < 4) args[argc++] = v;
		varargc--;
	}

	int rv = 0;
	switch (glk_api_selector) {
		case i7_glk_gestalt:
			rv = 1; break;
		case i7_glk_window_iterate:
			rv = 0; break;
		case i7_glk_window_open:
			rv = 1; break;
		case i7_glk_set_window:
			rv = 0; break;
		case i7_glk_stream_iterate:
			rv = 0; break;
		case i7_glk_fileref_iterate:
			rv = 0; break;
		case i7_glk_stylehint_set:
			rv = 0; break;
		case i7_glk_schannel_iterate:
			rv = 0; break;
		case i7_glk_schannel_create:
			rv = 0; break;
		case i7_glk_stream_get_position:
			rv = i7_do_glk_stream_get_position(args[0]); break;
		case i7_glk_stream_close:
			i7_do_glk_stream_close(args[0], args[1]); break;
		case i7_glk_stream_set_current:
			i7_do_glk_stream_set_current(args[0]); break;
		case i7_glk_stream_get_current:
			rv = i7_do_glk_stream_get_current(); break;
		case i7_glk_stream_open_memory:
			rv = i7_do_glk_stream_open_memory(args[0], args[1], args[2], args[3]); break;
		case i7_glk_stream_open_memory_uni:
			rv = i7_do_glk_stream_open_memory_uni(args[0], args[1], args[2], args[3]); break;
		case i7_glk_char_to_upper:
			rv = i7_do_glk_char_to_upper(args[0]); break;
		case i7_glk_fileref_create_by_name:
			rv = i7_do_glk_fileref_create_by_name(args[0], args[1], args[2]); break;
		case i7_glk_fileref_does_file_exist:
			rv = i7_do_glk_fileref_does_file_exist(args[0]); break;
		case i7_glk_stream_open_file:
			rv = i7_do_glk_stream_open_file(args[0], args[1], args[2]); break;
		case i7_glk_fileref_destroy:
			rv = 0; break;
		case i7_glk_stream_set_position:
			i7_do_glk_stream_set_position(args[0], args[1], args[2]); break;
		case i7_glk_put_char_stream:
			i7_do_glk_put_char_stream(args[0], args[1]); break;
		case i7_glk_get_char_stream:
			rv = i7_do_glk_get_char_stream(args[0]); break;
		default:
			printf("Unimplemented: glulx_glk %d.\n", glk_api_selector); i7_fatal_exit();
			break;
	}
	if (z) *z = rv;
}

void i7_print_def_art(i7val x) {
	fn_i7_mgl_DefArt(1, x, 0);
}

void i7_print_cdef_art(i7val x) {
	fn_i7_mgl_CDefArt(1, x, 0);
}

void i7_print_indef_art(i7val x) {
	fn_i7_mgl_IndefArt(1, x, 0);
}

void i7_print_cindef_art(i7val x) {
	fn_i7_mgl_CIndefArt(1, x, 0);
}

void i7_print_name(i7val x) {
	fn_i7_mgl_PrintShortName(1, x, 0);
}

void i7_print_object(i7val x) {
	printf("Unimplemented: i7_print_object.\n");
	i7_fatal_exit();
}

void i7_print_property(i7val x) {
	printf("Unimplemented: i7_print_property.\n");
	i7_fatal_exit();
}

void i7_print_box(i7val x) {
	printf("Unimplemented: i7_print_box.\n");
	i7_fatal_exit();
}

void i7_read(i7val x) {
	printf("Unimplemented: i7_read.\n");
	i7_fatal_exit();
}
