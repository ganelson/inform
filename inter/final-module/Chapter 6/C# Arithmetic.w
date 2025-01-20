[CSArithmetic::] C# Arithmetic.

Integer and floating-point calculations translated to C#.

@ Integer arithmetic is handled by the standard operators in C#, so this is very
easy, except that we want to fail gracefully in the case of division by zero:
so if we're compiling a function, we do this with the functions implementing the
opcodes |@div_r| and |@mod_r| instead.

=
int CSArithmetic::invoke_primitive(code_generation *gen, inter_ti bip, inter_tree_node *P) {
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
			WRITE("(System.Convert.ToInt32("); VNODE_1C; WRITE(") * System.Convert.ToInt32("); VNODE_2C; WRITE("))"); break;
		case DIVIDE_BIP:
			if (CSFunctionModel::inside_function(gen)) {
				WRITE("proc.i7_div("); VNODE_1C; WRITE(", "); VNODE_2C; WRITE(")");
			} else {
				WRITE("("); VNODE_1C; WRITE(" / "); VNODE_2C; WRITE(")"); break;
			}
			break; 
		case MODULO_BIP:
			if (CSFunctionModel::inside_function(gen)) {
				WRITE("proc.i7_mod("); VNODE_1C; WRITE(", "); VNODE_2C; WRITE(")");
			} else {
				WRITE("("); VNODE_1C; WRITE(" %% "); VNODE_2C; WRITE(")");
			}
			break;
		case SEQUENTIAL_BIP:
			/* FIXME: This is probably very inefficient. */
			WRITE("/*seq*/new System.Func<int, int, int>((_, i7_val) => i7_val)("); VNODE_1C; WRITE(","); VNODE_2C; WRITE(")"); break;
		case TERNARYSEQUENTIAL_BIP:
			/* FIXME: This is probably very inefficient. */
			WRITE("/*tseq*/new System.Func<int, int, int>((_, _, i7_val) => i7_val)("); VNODE_1C; WRITE(", "); VNODE_2C; WRITE(", ");
			VNODE_3C; WRITE(")"); break;
		case RANDOM_BIP:
			WRITE("proc.i7_random("); VNODE_1C; WRITE(")"); break;
		default: return NOT_APPLICABLE;
	}
	return FALSE;
}

@h add, sub, neg, mul, div, mod.
Also the functions |i7_div| and |i7_mod|, which are just wrappers for their
opcodes but return values rather than copying to pointers.

The implementations of |@div| and |@mod| are borrowed from the glulxe
reference code, to be sure that we have the right sign conventions.

= (text to inform7_cslib.cs)
partial class Process {
	internal void i7_opcode_add(int x, int y, out int z) {
		z = x + y;
	}
	internal void i7_opcode_sub(int x, int y, out int z) {
		z = x - y;
	}
	internal void i7_opcode_neg(int x, out int y) {
		y = -x;
	}
	internal void i7_opcode_mul(int x, int y, out int z) {
		z = x * y;
	}

	internal void i7_opcode_div(int x, int y, out int z) {
		if (y == 0) { Console.WriteLine("Division of {0:D} by 0", x); i7_fatal_exit(); z=0; return; }
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
		z = result;
	}

	internal void i7_opcode_mod(int x, int y, out int z) {
		if (y == 0) { Console.WriteLine("Division of {0:D} by 0", x); z=0; i7_fatal_exit(); return; }
		int result, ax, ay = (y < 0)?(-y):y;
		if (x < 0) {
			ax = (-x);
			result = -(ax % ay);
		} else {
			ax = x;
			result = ax % ay;
		}
		z = result;
	}

	internal int i7_div(int x, int y) {
		int z;
		i7_opcode_div(x, y, out z);
		return z;
	}

	internal int i7_mod(int x, int y) {
		int z;
		i7_opcode_mod(x, y, out z);
		return z;
	}
=

@h fadd, fsub, fmul, fdiv, fmod.
The remaining opcodes are for floating-point arithmetic, and it all seems
straightforward, since we just want to use standard C# |float| arithmetic
throughout, but the devil is in the details. The code below is heavily
indebted to Andrew Plotkin.

= (text to inform7_cslib.cs)
	internal void i7_opcode_fadd(int x, int y, out int z) {
		z = i7_encode_float(i7_decode_float(x) + i7_decode_float(y));
	}
	internal void i7_opcode_fsub(int x, int y, out int z) {
		z = i7_encode_float(i7_decode_float(x) - i7_decode_float(y));
	}
	internal void i7_opcode_fmul(int x, int y, out int z) {
		z = i7_encode_float(i7_decode_float(x) * i7_decode_float(y));
	}
	internal void i7_opcode_fdiv(int x, int y, out int z) {
		z = i7_encode_float(i7_decode_float(x) / i7_decode_float(y));
	}
	internal void i7_opcode_fmod(int x, int y, out int z, out int w) {
		float fx = i7_decode_float(x), fy = i7_decode_float(y);
		float fquot = fx % fy;
		int quot = i7_encode_float(fquot);
		int rem = i7_encode_float((fx-fquot) / fy);
		if (rem == 0x0 || rem == unchecked((int)0x80000000)) {
			/* When the quotient is zero, the sign has been lost in the
			shuffle. We'll set that by hand, based on the original arguments. */
			rem = (x ^ y) & unchecked((int)0x80000000);
		}
		z = quot;
		w = rem;
	}

@h floor, ceil, ftonumn, ftonumz, numtof.
All of which are conversions between integer and floating-point values.

= (text to inform7_cslib.cs)
	internal void i7_opcode_floor(int x, out int y) {
		y = i7_encode_float((float)Math.Floor(i7_decode_float(x)));
	}
	internal void i7_opcode_ceil(int x, out int y) {
		y = i7_encode_float((float)Math.Ceiling(i7_decode_float(x)));
	}

	internal void i7_opcode_ftonumn(int x, out int y) {
		float fx = i7_decode_float(x);
		int result;
		if (Math.Sign(fx) > 1) {
			if (float.IsNaN(fx) || float.IsInfinity(fx) || (fx > 2147483647.0))
				result = 0x7FFFFFFF;
			else
				result = (int) (Math.Round(fx));
		}
		else {
			if (float.IsNaN(fx) || float.IsInfinity(fx) || (fx < -2147483647.0))
				result = unchecked((int)0x80000000);
			else
				result = (int) (Math.Round(fx));
		}
		y = result;
	}

	internal void i7_opcode_ftonumz(int x, out int y) {
		float fx = i7_decode_float(x);
		int result;
		if (Math.Sign(fx) > 1) {
			if (float.IsNaN(fx) || float.IsInfinity(fx) || (fx > 2147483647.0))
				result = 0x7FFFFFFF;
			else
				result = (int) (Math.Truncate(fx));
		}
		else {
			if (float.IsNaN(fx) || float.IsInfinity(fx) || (fx < -2147483647.0))
				result = unchecked((int)0x80000000);
			else
				result = (int) (Math.Truncate(fx));
		}
		y = result;
	}

	internal void i7_opcode_numtof(int x, out int y) {
		y = i7_encode_float((float) x);
	}
=

@h exp, log, pow, sqrt.

= (text to inform7_cslib.cs)
	internal void i7_opcode_exp(int x, out int y) {
		y = i7_encode_float((float)Math.Exp(i7_decode_float(x)));
	}
	internal void i7_opcode_log(int x, out int y) {
		y = i7_encode_float((float)Math.Log(i7_decode_float(x)));
	}
	internal void i7_opcode_pow(int x, int y, out int z) {
		if (i7_decode_float(x) == 1.0f)
			z = i7_encode_float(1.0f);
		else if ((i7_decode_float(y) == 0.0f) || (i7_decode_float(y) == -0.0f))
			z = i7_encode_float(1.0f);
		else if ((i7_decode_float(x) == -1.0f) && float.IsInfinity(i7_decode_float(y)))
			z = i7_encode_float(1.0f);
		else
			z = i7_encode_float((float)Math.Pow(i7_decode_float(x), i7_decode_float(y)));
	}
	internal void i7_opcode_sqrt(int x, out int y) {
		y = i7_encode_float((float)Math.Sqrt(i7_decode_float(x)));
	}
=

@h sin, cos, tan, asin, acos, atan.

= (text to inform7_cslib.cs)
	internal void i7_opcode_sin(int x, out int y) {
		y = i7_encode_float((float)Math.Sin(i7_decode_float(x)));
	}
	internal void i7_opcode_cos(int x, out int y) {
		y = i7_encode_float((float)Math.Cos(i7_decode_float(x)));
	}
	internal void i7_opcode_tan(int x, out int y) {
		y = i7_encode_float((float)Math.Tan(i7_decode_float(x)));
	}

	internal void i7_opcode_asin(int x, out int y) {
		y = i7_encode_float((float)Math.Asin(i7_decode_float(x)));
	}
	internal void i7_opcode_acos(int x, out int y) {
		y = i7_encode_float((float)Math.Acos(i7_decode_float(x)));
	}
	internal void i7_opcode_atan(int x, out int y) {
		y = i7_encode_float((float)Math.Atan(i7_decode_float(x)));
	}

@h jfeq. jfne, jfge, jflt, jisinf, jisnan.
These are branch instructions of the kind which spook anybody who's never
looked at how floating-point arithmetic is actually done. Once you stop
thinking of a |float| as a number and start thinking of it as a sort of fuzzy
uncertainty range all of this becomes more explicable, but still.

= (text to inform7_cslib.cs)
	internal int i7_opcode_jfeq(int x, int y, int z) {
		int result;
		if ((z & 0x7F800000) == 0x7F800000 && (z & 0x007FFFFF) != 0) {
			/* The delta is NaN, which can never match. */
			result = 0;
		} else if ((x == 0x7F800000 || (uint) x == 0xFF800000)
				&& (y == 0x7F800000 || (uint) y == 0xFF800000)) {
			/* Both are infinite. Opposite infinities are never equal,
			even if the difference is infinite, so this is easy. */
			result = (x == y) ? 1 : 0;
		} else {
			float fx = i7_decode_float(y) - i7_decode_float(x);
			float fy = System.Math.Abs(i7_decode_float(z));
			result = (fx <= fy && fx >= -fy) ? 1 : 0;
		}
		return result;
	}

	internal int i7_opcode_jfne(int x, int y, int z) {
		int result;
		if ((z & 0x7F800000) == 0x7F800000 && (z & 0x007FFFFF) != 0) {
			/* The delta is NaN, which can never match. */
			result = 0;
		} else if ((x == 0x7F800000 || (uint) x == 0xFF800000)
				&& (y == 0x7F800000 || (uint) y == 0xFF800000)) {
			/* Both are infinite. Opposite infinities are never equal,
			even if the difference is infinite, so this is easy. */
			result = (x == y) ? 1 : 0;
		} else {
			float fx = i7_decode_float(y) - i7_decode_float(x);
			float fy = System.Math.Abs(i7_decode_float(z));
			result = (fx <= fy && fx >= -fy) ? 1 : 0;
		}
		return result;
	}

	internal int i7_opcode_jfge(int x, int y) {
		if (i7_decode_float(x) >= i7_decode_float(y)) return 1;
		return 0;
	}

	internal int i7_opcode_jflt(int x, int y) {
		if (i7_decode_float(x) < i7_decode_float(y)) return 1;
		return 0;
	}

	internal int i7_opcode_jisinf(int x) {
		if (x == 0x7F800000 || (uint) x == 0xFF800000) return 1;
		return 0;
	}

	internal int i7_opcode_jisnan(int x) {
		if ((x & 0x7F800000) == 0x7F800000 && (x & 0x007FFFFF) != 0) return 1;
		return 0;
	}
}
=
