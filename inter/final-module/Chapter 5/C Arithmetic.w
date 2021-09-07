[CArithmetic::] C Arithmetic.

Integer and floating-point calculations translated to C.

@ Integer arithmetic is handled by the standard operators in C, so this is very
easy.

=
int CArithmetic::compile_primitive(code_generation *gen, inter_ti bip, inter_tree_node *P) {
	text_stream *OUT = CodeGen::current(gen);
	switch (bip) {
		case PLUS_BIP:				WRITE("("); INV_A1; WRITE(" + "); INV_A2; WRITE(")"); break;
		case MINUS_BIP:				WRITE("("); INV_A1; WRITE(" - "); INV_A2; WRITE(")"); break;
		case UNARYMINUS_BIP:		WRITE("(-("); INV_A1; WRITE("))"); break;
		case TIMES_BIP:				WRITE("("); INV_A1; WRITE(" * "); INV_A2; WRITE(")"); break;
		case DIVIDE_BIP:			if (CFunctionModel::inside_function(gen)) {
										WRITE("glulx_div_r(proc, "); INV_A1; WRITE(", "); INV_A2; WRITE(")");
									} else {
										WRITE("("); INV_A1; WRITE(" / "); INV_A2; WRITE(")"); break;
									}
									break; 
		case MODULO_BIP:			if (CFunctionModel::inside_function(gen)) {
										WRITE("glulx_mod_r(proc, "); INV_A1; WRITE(", "); INV_A2; WRITE(")");
									} else {
										WRITE("("); INV_A1; WRITE(" %% "); INV_A2; WRITE(")");
									}
									break;
		case BITWISEAND_BIP:		WRITE("(("); INV_A1; WRITE(")&("); INV_A2; WRITE("))"); break;
		case BITWISEOR_BIP:			WRITE("(("); INV_A1; WRITE(")|("); INV_A2; WRITE("))"); break;
		case BITWISENOT_BIP:		WRITE("(~("); INV_A1; WRITE("))"); break;
		case SEQUENTIAL_BIP:	    WRITE("("); INV_A1; WRITE(","); INV_A2; WRITE(")"); break;
		case TERNARYSEQUENTIAL_BIP: WRITE("("); INV_A1; WRITE(", "); INV_A2; WRITE(", ");
									INV_A3; WRITE(")"); break;
		case RANDOM_BIP:    	    WRITE("fn_i7_mgl_random(proc, "); INV_A1; WRITE(")"); break;
		default: 					return NOT_APPLICABLE;
	}
	return FALSE;
}

@ Random integers:

= (text to inform7_clib.h)
void glulx_random(i7process *proc, i7val x, i7val *y);
i7val fn_i7_mgl_random(i7process *proc, i7val x);
void glulx_setrandom(i7process *proc, i7val s);
=

= (text to inform7_clib.c)
/* Return a random number in the range 0 to 2^32-1. */
uint32_t i7_random() {
	return (random() << 16) ^ random();
}

void glulx_random(i7process *proc, i7val x, i7val *y) {
	uint32_t value;
	if (x == 0) value = i7_random();
	else if (x >= 1) value = i7_random() % (uint32_t) (x);
	else value = -(i7_random() % (uint32_t) (-x));
	*y = (i7val) value;
}

i7val fn_i7_mgl_random(i7process *proc, i7val x) {
	i7val r;
	glulx_random(proc, x, &r);
	return r+1;
}

/* Set the random-number seed; zero means use as random a source as
   possible. */
void glulx_setrandom(i7process *proc, i7val s) {
	uint32_t seed;
	*((i7val *) &seed) = s;
	if (seed == 0) seed = time(NULL);
	srandom(seed);
}
=

@ Floating-point calculations are not done by primitives but by the use of
Glulx opcodes. (When Inform could only produce code for the Z-machine and Glulx
virtual machines, Glulx was the obe of the two which could handle floating-point.)

We emulate these opcodes with a library of functions as follows.

Note that floating-point numbers are stored in |i7val| values at runtime by
storing |float| (not, alas, |double|) values as if they were four-byte integers.

= (text to inform7_clib.h)
void glulx_add(i7process *proc, i7val x, i7val y, i7val *z);
void glulx_sub(i7process *proc, i7val x, i7val y, i7val *z);
void glulx_neg(i7process *proc, i7val x, i7val *y);
void glulx_mul(i7process *proc, i7val x, i7val y, i7val *z);
void glulx_div(i7process *proc, i7val x, i7val y, i7val *z);
i7val glulx_div_r(i7process *proc, i7val x, i7val y);
void glulx_mod(i7process *proc, i7val x, i7val y, i7val *z);
i7val glulx_mod_r(i7process *proc, i7val x, i7val y);
typedef float gfloat32;
i7val encode_float(gfloat32 val);
gfloat32 decode_float(i7val val);
void glulx_exp(i7process *proc, i7val x, i7val *y);
void glulx_fadd(i7process *proc, i7val x, i7val y, i7val *z);
void glulx_fdiv(i7process *proc, i7val x, i7val y, i7val *z);
void glulx_floor(i7process *proc, i7val x, i7val *y);
void glulx_fmod(i7process *proc, i7val x, i7val y, i7val *z, i7val *w);
void glulx_fmul(i7process *proc, i7val x, i7val y, i7val *z);
void glulx_fsub(i7process *proc, i7val x, i7val y, i7val *z);
void glulx_ftonumn(i7process *proc, i7val x, i7val *y);
void glulx_ftonumz(i7process *proc, i7val x, i7val *y);
void glulx_numtof(i7process *proc, i7val x, i7val *y);
int glulx_jfeq(i7process *proc, i7val x, i7val y, i7val z);
int glulx_jfne(i7process *proc, i7val x, i7val y, i7val z);
int glulx_jfge(i7process *proc, i7val x, i7val y);
int glulx_jflt(i7process *proc, i7val x, i7val y);
int glulx_jisinf(i7process *proc, i7val x);
int glulx_jisnan(i7process *proc, i7val x);
void glulx_log(i7process *proc, i7val x, i7val *y);
void glulx_acos(i7process *proc, i7val x, i7val *y);
void glulx_asin(i7process *proc, i7val x, i7val *y);
void glulx_atan(i7process *proc, i7val x, i7val *y);
void glulx_ceil(i7process *proc, i7val x, i7val *y);
void glulx_cos(i7process *proc, i7val x, i7val *y);
void glulx_pow(i7process *proc, i7val x, i7val y, i7val *z);
void glulx_sin(i7process *proc, i7val x, i7val *y);
void glulx_sqrt(i7process *proc, i7val x, i7val *y);
void glulx_tan(i7process *proc, i7val x, i7val *y);
=

= (text to inform7_clib.c)
void glulx_add(i7process *proc, i7val x, i7val y, i7val *z) {
	if (z) *z = x + y;
}

void glulx_sub(i7process *proc, i7val x, i7val y, i7val *z) {
	if (z) *z = x - y;
}

void glulx_neg(i7process *proc, i7val x, i7val *y) {
	if (y) *y = -x;
}

void glulx_mul(i7process *proc, i7val x, i7val y, i7val *z) {
	if (z) *z = x * y;
}

void glulx_div(i7process *proc, i7val x, i7val y, i7val *z) {
	if (y == 0) { printf("Division of %d by 0\n", x); i7_fatal_exit(proc); return; }
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

i7val glulx_div_r(i7process *proc, i7val x, i7val y) {
	i7val z;
	glulx_div(proc, x, y, &z);
	return z;
}

void glulx_mod(i7process *proc, i7val x, i7val y, i7val *z) {
	if (y == 0) { printf("Division of %d by 0\n", x); i7_fatal_exit(proc); return; }
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

i7val glulx_mod_r(i7process *proc, i7val x, i7val y) {
	i7val z;
	glulx_mod(proc, x, y, &z);
	return z;
}

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

void glulx_exp(i7process *proc, i7val x, i7val *y) {
	*y = encode_float(expf(decode_float(x)));
}

void glulx_fadd(i7process *proc, i7val x, i7val y, i7val *z) {
	*z = encode_float(decode_float(x) + decode_float(y));
}

void glulx_fdiv(i7process *proc, i7val x, i7val y, i7val *z) {
	*z = encode_float(decode_float(x) / decode_float(y));
}

void glulx_floor(i7process *proc, i7val x, i7val *y) {
	*y = encode_float(floorf(decode_float(x)));
}

void glulx_fmod(i7process *proc, i7val x, i7val y, i7val *z, i7val *w) {
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

void glulx_fmul(i7process *proc, i7val x, i7val y, i7val *z) {
	*z = encode_float(decode_float(x) * decode_float(y));
}

void glulx_fsub(i7process *proc, i7val x, i7val y, i7val *z) {
	*z = encode_float(decode_float(x) - decode_float(y));
}

void glulx_ftonumn(i7process *proc, i7val x, i7val *y) {
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

void glulx_ftonumz(i7process *proc, i7val x, i7val *y) {
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

void glulx_numtof(i7process *proc, i7val x, i7val *y) {
	*y = encode_float((float) x);
}

int glulx_jfeq(i7process *proc, i7val x, i7val y, i7val z) {
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

int glulx_jfne(i7process *proc, i7val x, i7val y, i7val z) {
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

int glulx_jfge(i7process *proc, i7val x, i7val y) {
	if (decode_float(x) >= decode_float(y)) return 1;
	return 0;
}

int glulx_jflt(i7process *proc, i7val x, i7val y) {
	if (decode_float(x) < decode_float(y)) return 1;
	return 0;
}

int glulx_jisinf(i7process *proc, i7val x) {
    if (x == 0x7F800000 || x == 0xFF800000) return 1;
	return 0;
}

int glulx_jisnan(i7process *proc, i7val x) {
    if ((x & 0x7F800000) == 0x7F800000 && (x & 0x007FFFFF) != 0) return 1;
	return 0;
}

void glulx_log(i7process *proc, i7val x, i7val *y) {
	*y = encode_float(logf(decode_float(x)));
}

void glulx_acos(i7process *proc, i7val x, i7val *y) {
	*y = encode_float(acosf(decode_float(x)));
}

void glulx_asin(i7process *proc, i7val x, i7val *y) {
	*y = encode_float(asinf(decode_float(x)));
}

void glulx_atan(i7process *proc, i7val x, i7val *y) {
	*y = encode_float(atanf(decode_float(x)));
}

void glulx_ceil(i7process *proc, i7val x, i7val *y) {
	*y = encode_float(ceilf(decode_float(x)));
}

void glulx_cos(i7process *proc, i7val x, i7val *y) {
	*y = encode_float(cosf(decode_float(x)));
}

void glulx_pow(i7process *proc, i7val x, i7val y, i7val *z) {
	if (decode_float(x) == 1.0f)
		*z = encode_float(1.0f);
	else if ((decode_float(y) == 0.0f) || (decode_float(y) == -0.0f))
		*z = encode_float(1.0f);
	else if ((decode_float(x) == -1.0f) && isinf(decode_float(y)))
		*z = encode_float(1.0f);
	else
		*z = encode_float(powf(decode_float(x), decode_float(y)));
}

void glulx_sin(i7process *proc, i7val x, i7val *y) {
	*y = encode_float(sinf(decode_float(x)));
}

void glulx_sqrt(i7process *proc, i7val x, i7val *y) {
	*y = encode_float(sqrtf(decode_float(x)));
}

void glulx_tan(i7process *proc, i7val x, i7val *y) {
	*y = encode_float(tanf(decode_float(x)));
}
=
