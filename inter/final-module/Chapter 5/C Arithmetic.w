[CArithmetic::] C Arithmetic.

Integer and floating-point calculations translated to C.

@ Integer arithmetic is handled by the standard operators in C, so this is very
easy, except that we want to fail gracefully in the case of division by zero:
so if we're compiling a function, we do this with the functions implementing the
opcodes |@div_r| and |@mod_r| instead.

=
int CArithmetic::invoke_primitive(code_generation *gen, inter_ti bip, inter_tree_node *P) {
	text_stream *OUT = CodeGen::current(gen);
	switch (bip) {
		case BITWISEAND_BIP:
			WRITE("(("); VNODE_1C; WRITE(")&("); VNODE_2C; WRITE("))"); break;
		case BITWISEOR_BIP:
			WRITE("(("); VNODE_1C; WRITE(")|("); VNODE_2C; WRITE("))"); break;
		case BITWISENOT_BIP:
			WRITE("(~("); VNODE_1C; WRITE("))"); break;
		case PLUS_BIP:
			WRITE("("); VNODE_1C; WRITE(" + "); VNODE_2C; WRITE(")"); break;
		case MINUS_BIP:
			WRITE("("); VNODE_1C; WRITE(" - "); VNODE_2C; WRITE(")"); break;
		case UNARYMINUS_BIP:
			WRITE("(-("); VNODE_1C; WRITE("))"); break;
		case TIMES_BIP:
			WRITE("("); VNODE_1C; WRITE(" * "); VNODE_2C; WRITE(")"); break;
		case DIVIDE_BIP:
			if (CFunctionModel::inside_function(gen)) {
				WRITE("i7_div(proc, "); VNODE_1C; WRITE(", "); VNODE_2C; WRITE(")");
			} else {
				WRITE("("); VNODE_1C; WRITE(" / "); VNODE_2C; WRITE(")"); break;
			}
			break; 
		case MODULO_BIP:
			if (CFunctionModel::inside_function(gen)) {
				WRITE("i7_mod(proc, "); VNODE_1C; WRITE(", "); VNODE_2C; WRITE(")");
			} else {
				WRITE("("); VNODE_1C; WRITE(" %% "); VNODE_2C; WRITE(")");
			}
			break;
		case SEQUENTIAL_BIP:
			WRITE("("); VNODE_1C; WRITE(","); VNODE_2C; WRITE(")"); break;
		case TERNARYSEQUENTIAL_BIP:
			WRITE("("); VNODE_1C; WRITE(", "); VNODE_2C; WRITE(", ");
			VNODE_3C; WRITE(")"); break;
		case RANDOM_BIP:
			WRITE("i7_fn_random(proc, "); VNODE_1C; WRITE(")"); break;
		default: return NOT_APPLICABLE;
	}
	return FALSE;
}

@h add, sub, neg, mul, div, mod.
Also the functions |i7_div| and |i7_mod|, which are just wrappers for their
opcodes but return values rather than copying to pointers.

The implementations of |@div| and |@mod| are borrowed from the glulxe
reference code, to be sure that we have the right sign conventions.

= (text to inform7_clib.h)
void i7_opcode_add(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z);
void i7_opcode_sub(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z);
void i7_opcode_neg(i7process_t *proc, i7word_t x, i7word_t *y);
void i7_opcode_mul(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z);
void i7_opcode_div(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z);
void i7_opcode_mod(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z);

i7word_t i7_div(i7process_t *proc, i7word_t x, i7word_t y);
i7word_t i7_mod(i7process_t *proc, i7word_t x, i7word_t y);
=

= (text to inform7_clib.c)
void i7_opcode_add(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z) {
	if (z) *z = x + y;
}
void i7_opcode_sub(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z) {
	if (z) *z = x - y;
}
void i7_opcode_neg(i7process_t *proc, i7word_t x, i7word_t *y) {
	if (y) *y = -x;
}
void i7_opcode_mul(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z) {
	if (z) *z = x * y;
}

void i7_opcode_div(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z) {
	if (y == 0) { printf("Division of %d by 0\n", x); i7_fatal_exit(proc); return; }
	int result, ax, ay;
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

void i7_opcode_mod(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z) {
	if (y == 0) { printf("Division of %d by 0\n", x); i7_fatal_exit(proc); return; }
	int result, ax, ay = (y < 0)?(-y):y;
	if (x < 0) {
		ax = (-x);
		result = -(ax % ay);
	} else {
		ax = x;
		result = ax % ay;
	}
	if (z) *z = result;
}

i7word_t i7_div(i7process_t *proc, i7word_t x, i7word_t y) {
	i7word_t z;
	i7_opcode_div(proc, x, y, &z);
	return z;
}

i7word_t i7_mod(i7process_t *proc, i7word_t x, i7word_t y) {
	i7word_t z;
	i7_opcode_mod(proc, x, y, &z);
	return z;
}
=

@h fadd, fsub, fmul, fdiv, fmod.
The remaining opcodes are for floating-point arithmetic, and it all seems
straightforward, since we just want to use standard C |float| arithmetic
throughout, but the devil is in the details. The code below is heavily
indebted to Andrew Plotkin.

= (text to inform7_clib.h)
void i7_opcode_fadd(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z);
void i7_opcode_fsub(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z);
void i7_opcode_fmul(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z);
void i7_opcode_fdiv(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z);
void i7_opcode_fmod(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z, i7word_t *w);
=

= (text to inform7_clib.c)
void i7_opcode_fadd(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z) {
	*z = i7_encode_float(i7_decode_float(x) + i7_decode_float(y));
}
void i7_opcode_fsub(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z) {
	*z = i7_encode_float(i7_decode_float(x) - i7_decode_float(y));
}
void i7_opcode_fmul(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z) {
	*z = i7_encode_float(i7_decode_float(x) * i7_decode_float(y));
}
void i7_opcode_fdiv(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z) {
	*z = i7_encode_float(i7_decode_float(x) / i7_decode_float(y));
}
void i7_opcode_fmod(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z, i7word_t *w) {
	float fx = i7_decode_float(x), fy = i7_decode_float(y);
	float fquot = fmodf(fx, fy);
	i7word_t quot = i7_encode_float(fquot);
	i7word_t rem = i7_encode_float((fx-fquot) / fy);
	if (rem == 0x0 || rem == 0x80000000) {
		/* When the quotient is zero, the sign has been lost in the
		 shuffle. We'll set that by hand, based on the original arguments. */
		rem = (x ^ y) & 0x80000000;
	}
	if (z) *z = quot;
	if (w) *w = rem;
}

@h floor, ceil, ftonumn, ftonumz, numtof.
All of which are conversions between integer and floating-point values.

= (text to inform7_clib.h)
void i7_opcode_floor(i7process_t *proc, i7word_t x, i7word_t *y);
void i7_opcode_ceil(i7process_t *proc, i7word_t x, i7word_t *y);
void i7_opcode_ftonumn(i7process_t *proc, i7word_t x, i7word_t *y);
void i7_opcode_ftonumz(i7process_t *proc, i7word_t x, i7word_t *y);
void i7_opcode_numtof(i7process_t *proc, i7word_t x, i7word_t *y);
=

= (text to inform7_clib.c)
void i7_opcode_floor(i7process_t *proc, i7word_t x, i7word_t *y) {
	*y = i7_encode_float(floorf(i7_decode_float(x)));
}
void i7_opcode_ceil(i7process_t *proc, i7word_t x, i7word_t *y) {
	*y = i7_encode_float(ceilf(i7_decode_float(x)));
}

void i7_opcode_ftonumn(i7process_t *proc, i7word_t x, i7word_t *y) {
	float fx = i7_decode_float(x);
	i7word_t result;
	if (!signbit(fx)) {
		if (isnan(fx) || isinf(fx) || (fx > 2147483647.0))
			result = 0x7FFFFFFF;
		else
			result = (i7word_t) (roundf(fx));
	}
	else {
		if (isnan(fx) || isinf(fx) || (fx < -2147483647.0))
			result = 0x80000000;
		else
			result = (i7word_t) (roundf(fx));
	}
	*y = result;
}

void i7_opcode_ftonumz(i7process_t *proc, i7word_t x, i7word_t *y) {
	float fx = i7_decode_float(x);
 	i7word_t result;
	if (!signbit(fx)) {
		if (isnan(fx) || isinf(fx) || (fx > 2147483647.0))
			result = 0x7FFFFFFF;
		else
			result = (i7word_t) (truncf(fx));
	}
	else {
		if (isnan(fx) || isinf(fx) || (fx < -2147483647.0))
			result = 0x80000000;
		else
			result = (i7word_t) (truncf(fx));
	}
	*y = result;
}

void i7_opcode_numtof(i7process_t *proc, i7word_t x, i7word_t *y) {
	*y = i7_encode_float((float) x);
}
=

@h exp, log, pow, sqrt.

= (text to inform7_clib.h)
void i7_opcode_exp(i7process_t *proc, i7word_t x, i7word_t *y);
void i7_opcode_log(i7process_t *proc, i7word_t x, i7word_t *y);
void i7_opcode_pow(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z);
void i7_opcode_sqrt(i7process_t *proc, i7word_t x, i7word_t *y);
=

= (text to inform7_clib.c)
void i7_opcode_exp(i7process_t *proc, i7word_t x, i7word_t *y) {
	*y = i7_encode_float(expf(i7_decode_float(x)));
}
void i7_opcode_log(i7process_t *proc, i7word_t x, i7word_t *y) {
	*y = i7_encode_float(logf(i7_decode_float(x)));
}
void i7_opcode_pow(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z) {
	if (i7_decode_float(x) == 1.0f)
		*z = i7_encode_float(1.0f);
	else if ((i7_decode_float(y) == 0.0f) || (i7_decode_float(y) == -0.0f))
		*z = i7_encode_float(1.0f);
	else if ((i7_decode_float(x) == -1.0f) && isinf(i7_decode_float(y)))
		*z = i7_encode_float(1.0f);
	else
		*z = i7_encode_float(powf(i7_decode_float(x), i7_decode_float(y)));
}
void i7_opcode_sqrt(i7process_t *proc, i7word_t x, i7word_t *y) {
	*y = i7_encode_float(sqrtf(i7_decode_float(x)));
}
=

@h sin, cos, tan, asin, acos, atan.

= (text to inform7_clib.h)
void i7_opcode_sin(i7process_t *proc, i7word_t x, i7word_t *y);
void i7_opcode_cos(i7process_t *proc, i7word_t x, i7word_t *y);
void i7_opcode_tan(i7process_t *proc, i7word_t x, i7word_t *y);
void i7_opcode_asin(i7process_t *proc, i7word_t x, i7word_t *y);
void i7_opcode_acos(i7process_t *proc, i7word_t x, i7word_t *y);
void i7_opcode_atan(i7process_t *proc, i7word_t x, i7word_t *y);
=

= (text to inform7_clib.c)
void i7_opcode_sin(i7process_t *proc, i7word_t x, i7word_t *y) {
	*y = i7_encode_float(sinf(i7_decode_float(x)));
}
void i7_opcode_cos(i7process_t *proc, i7word_t x, i7word_t *y) {
	*y = i7_encode_float(cosf(i7_decode_float(x)));
}
void i7_opcode_tan(i7process_t *proc, i7word_t x, i7word_t *y) {
	*y = i7_encode_float(tanf(i7_decode_float(x)));
}

void i7_opcode_asin(i7process_t *proc, i7word_t x, i7word_t *y) {
	*y = i7_encode_float(asinf(i7_decode_float(x)));
}
void i7_opcode_acos(i7process_t *proc, i7word_t x, i7word_t *y) {
	*y = i7_encode_float(acosf(i7_decode_float(x)));
}
void i7_opcode_atan(i7process_t *proc, i7word_t x, i7word_t *y) {
	*y = i7_encode_float(atanf(i7_decode_float(x)));
}
=

@h jfeq. jfne, jfge, jflt, jisinf, jisnan.
These are branch instructions of the kind which spook anybody who's never
looked at how floating-point arithmetic is actually done. Once you stop
thinking of a |float| as a number and start thinking of it as a sort of fuzzy
uncertainty range all of this becomes more explicable, but still.

= (text to inform7_clib.h)
int i7_opcode_jfeq(i7process_t *proc, i7word_t x, i7word_t y, i7word_t z);
int i7_opcode_jfne(i7process_t *proc, i7word_t x, i7word_t y, i7word_t z);
int i7_opcode_jfge(i7process_t *proc, i7word_t x, i7word_t y);
int i7_opcode_jflt(i7process_t *proc, i7word_t x, i7word_t y);
int i7_opcode_jisinf(i7process_t *proc, i7word_t x);
int i7_opcode_jisnan(i7process_t *proc, i7word_t x);
=

= (text to inform7_clib.c)
int i7_opcode_jfeq(i7process_t *proc, i7word_t x, i7word_t y, i7word_t z) {
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
		float fx = i7_decode_float(y) - i7_decode_float(x);
		float fy = fabs(i7_decode_float(z));
		result = (fx <= fy && fx >= -fy);
	}
	if (result) return 1;
	return 0;
}

int i7_opcode_jfne(i7process_t *proc, i7word_t x, i7word_t y, i7word_t z) {
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
		float fx = i7_decode_float(y) - i7_decode_float(x);
		float fy = fabs(i7_decode_float(z));
		result = (fx <= fy && fx >= -fy);
	}
	if (!result) return 1;
	return 0;
}

int i7_opcode_jfge(i7process_t *proc, i7word_t x, i7word_t y) {
	if (i7_decode_float(x) >= i7_decode_float(y)) return 1;
	return 0;
}

int i7_opcode_jflt(i7process_t *proc, i7word_t x, i7word_t y) {
	if (i7_decode_float(x) < i7_decode_float(y)) return 1;
	return 0;
}

int i7_opcode_jisinf(i7process_t *proc, i7word_t x) {
    if (x == 0x7F800000 || x == 0xFF800000) return 1;
	return 0;
}

int i7_opcode_jisnan(i7process_t *proc, i7word_t x) {
    if ((x & 0x7F800000) == 0x7F800000 && (x & 0x007FFFFF) != 0) return 1;
	return 0;
}
=
