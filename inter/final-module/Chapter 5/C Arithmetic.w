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
		case TIMES_BIP:				WRITE("("); INV_A1; WRITE("*"); INV_A2; WRITE(")"); break;
		case DIVIDE_BIP:			WRITE("("); INV_A1; WRITE("/"); INV_A2; WRITE(")"); break;
		case MODULO_BIP:			WRITE("("); INV_A1; WRITE("%%"); INV_A2; WRITE(")"); break;
		case BITWISEAND_BIP:		WRITE("(("); INV_A1; WRITE(")&("); INV_A2; WRITE("))"); break;
		case BITWISEOR_BIP:			WRITE("(("); INV_A1; WRITE(")|("); INV_A2; WRITE("))"); break;
		case BITWISENOT_BIP:		WRITE("(~("); INV_A1; WRITE("))"); break;
		case SEQUENTIAL_BIP:	    WRITE("("); INV_A1; WRITE(","); INV_A2; WRITE(")"); break;
		case TERNARYSEQUENTIAL_BIP: WRITE("("); INV_A1; WRITE(", "); INV_A2; WRITE(", ");
									INV_A3; WRITE(")"); break;
		case RANDOM_BIP:    	    WRITE("fn_i7_mgl_random(1, "); INV_A1; WRITE(")"); break;
		default: 					return NOT_APPLICABLE;
	}
	return FALSE;
}

@ Random integers are rather crudely generated for now, in what amounts to a
rudimentary form of von Neumann's middle-square algorithm:

= (text to inform7_clib.h)
int i7_seed = 197;

i7val fn_i7_mgl_random(int n, i7val v) {
	if (i7_seed < 1000) return ((i7val) ((i7_seed++) % n));
	i7_seed = i7_seed*i7_seed;
	return (((i7_seed*i7_seed) & 0xFF00) / 0x100) % n;
}

void glulx_setrandom(i7val x) {
	i7_seed = (int) x;
}
=

@ Floating-point calculations are not done by primitives but by the use of
Glulx opcodes. (When Inform could only produce code for the Z-machine and Glulx
virtual machines, Glulx was the obe of the two which could handle floating-point.)

We emulate these opcodes with a library of functions as follows.

Note that floating-point numbers are stored in |i7val| values at runtime by
storing |float| (not, alas, |double|) values as if they were four-byte integers.

= (text to inform7_clib.h)
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

void glulx_log(i7val x, i7val y) {
	printf("Unimplemented: glulx_log.\n");
}

void glulx_acos(i7val x, i7val *y) {
	printf("Unimplemented: glulx_acos\n");
}

void glulx_asin(i7val x, i7val *y) {
	printf("Unimplemented: glulx_asin\n");
}

void glulx_atan(i7val x, i7val *y) {
	printf("Unimplemented: glulx_atan\n");
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

void glulx_sin(i7val x, i7val *y) {
	printf("Unimplemented: glulx_sin\n");
}

void glulx_sqrt(i7val x, i7val *y) {
	printf("Unimplemented: glulx_sqrt\n");
}

void glulx_tan(i7val x, i7val *y) {
	printf("Unimplemented: glulx_tan\n");
}
=
