[CLiteralsModel::] C Literals.

Text and dictionary words translated to C.

@h Setting up the model.

=
void CLiteralsModel::initialise(code_generation_target *cgt) {
	METHOD_ADD(cgt, COMPILE_DICTIONARY_WORD_MTID, CLiteralsModel::compile_dictionary_word);
	METHOD_ADD(cgt, COMPILE_LITERAL_NUMBER_MTID, CLiteralsModel::compile_literal_number);
	METHOD_ADD(cgt, COMPILE_LITERAL_REAL_MTID, CLiteralsModel::compile_literal_real);
	METHOD_ADD(cgt, COMPILE_LITERAL_TEXT_MTID, CLiteralsModel::compile_literal_text);
}

typedef struct C_generation_literals_model_data {
	text_stream *double_quoted_C;
	int no_double_quoted_C_strings;
	text_stream *single_quoted_C;
	int C_dword_count;
	struct dictionary *C_vm_dictionary;
} C_generation_literals_model_data;

void CLiteralsModel::initialise_data(code_generation *gen) {
	C_GEN_DATA(litdata.double_quoted_C) = Str::new();
	C_GEN_DATA(litdata.no_double_quoted_C_strings) = 0;
	C_GEN_DATA(litdata.single_quoted_C) = Str::new();
	C_GEN_DATA(litdata.C_dword_count) = 0;
	C_GEN_DATA(litdata.C_vm_dictionary) = Dictionaries::new(1024, TRUE);
}

void CLiteralsModel::begin(code_generation *gen) {
	CLiteralsModel::initialise_data(gen);
}

void CLiteralsModel::end(code_generation *gen) {
	generated_segment *saved = CodeGen::select(gen, c_predeclarations_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	for (int i=0; i<C_GEN_DATA(litdata.C_dword_count); i++) {
		WRITE("#define i7_s_dword_%d %d\n", i, 2*i);
		WRITE("#define i7_p_dword_%d %d\n", i, 2*i + 1);
	}
	CodeGen::deselect(gen, saved);

	saved = CodeGen::select(gen, c_predeclarations_I7CGS);
	OUT = CodeGen::current(gen);
	WRITE("char *dqs[] = {\n%S\"\" };\n", C_GEN_DATA(litdata.double_quoted_C));
	CodeGen::deselect(gen, saved);

	saved = CodeGen::select(gen, c_predeclarations_I7CGS);
	OUT = CodeGen::current(gen);
	WRITE("char *sqs[] = {\n%S\"\" };\n", C_GEN_DATA(litdata.single_quoted_C));
	CodeGen::deselect(gen, saved);
}

@

=
void CLiteralsModel::compile_dictionary_word(code_generation_target *cgt, code_generation *gen,
	text_stream *S, int pluralise) {
	text_stream *OUT = CodeGen::current(gen);
	text_stream *val = Dictionaries::get_text(C_GEN_DATA(litdata.C_vm_dictionary), S);
	if (val) {
		WRITE("%S", val);
	} else {
		WRITE_TO(Dictionaries::create_text(C_GEN_DATA(litdata.C_vm_dictionary), S),
			"i7_%s_dword_%d", (pluralise)?"p":"s", C_GEN_DATA(litdata.C_dword_count)++);
		val = Dictionaries::get_text(C_GEN_DATA(litdata.C_vm_dictionary), S);
		WRITE("%S", val);
		WRITE_TO(C_GEN_DATA(litdata.single_quoted_C), "\"%S\", \"%S\", ", S, S);
	}
}

@

=
void CLiteralsModel::compile_literal_number(code_generation_target *cgt,
	code_generation *gen, inter_ti val, int hex_mode) {
	text_stream *OUT = CodeGen::current(gen);
	if (hex_mode) WRITE("0x%x", val);
	else WRITE("%d", val);
}

/* Return 10 raised to the expo power.
 *
 * I'm avoiding the standard pow() function for a rather lame reason:
 * it's in the libmath (-lm) library, and I don't want to change the
 * build model for the compiler. So, this is implemented with a stupid
 * lookup table. It's faster than pow() for small values of expo.
 * Probably not as fast if expo is 200, but "$+1e200" is an overflow
 * anyway, so I don't expect that to be a problem.
 *
 * (For some reason, frexp() and ldexp(), which are used later on, do
 * not require libmath to be linked in.)
 */

#ifndef POW10_RANGE
#define POW10_RANGE (8)
#endif

double CLiteralsModel::pow10_cheap(int expo)
{
    static double powers[POW10_RANGE*2+1] = {
        0.00000001, 0.0000001, 0.000001, 0.00001, 0.0001, 0.001, 0.01, 0.1,
        1.0,
        10.0, 100.0, 1000.0, 10000.0, 100000.0, 1000000.0, 10000000.0, 100000000.0
    };

    double res = 1.0;

    if (expo < 0) {
        for (; expo < -POW10_RANGE; expo += POW10_RANGE) {
            res *= powers[0];
        }
        return res * powers[POW10_RANGE+expo];
    }
    else {
        for (; expo > POW10_RANGE; expo -= POW10_RANGE) {
            res *= powers[POW10_RANGE*2];
        }
        return res * powers[POW10_RANGE+expo];
    }
}

/* Return the IEEE-754 single-precision encoding of a floating-point
 * number. See http://www.psc.edu/general/software/packages/ieee/ieee.php
 * for an explanation.
 *
 * The number is provided in the pieces it was parsed in:
 *    [+|-] intv "." fracv "e" [+|-]expo
 *
 * If the magnitude is too large (beyond about 3.4e+38), this returns
 * an infinite value (0x7f800000 or 0xff800000). If the magnitude is too
 * small (below about 1e-45), this returns a zero value (0x00000000 or 
 * 0x80000000). If any of the inputs are NaN, this returns NaN (but the
 * lexer should never do that).
 *
 * Note that using a float constant does *not* set the uses_float_features
 * flag (which would cause the game file to be labelled 3.1.2). There's
 * no VM feature here, just an integer. Of course, any use of the float
 * *opcodes* will set the flag.
 *
 * The math functions in this routine require #including <math.h>, but
 * they should not require linking the math library (-lm). At least,
 * they do not on OSX and Linux.
 */
uint32_t CLiteralsModel::construct_float(int signbit, double intv, double fracv, int expo)
{
    double absval = (intv + fracv) * CLiteralsModel::pow10_cheap(expo);
    uint32_t sign = (signbit ? 0x80000000 : 0x0);
    double mant;
    uint32_t fbits;
 
    if (isinf(absval)) {
        return sign | 0x7f800000; /* infinity */
    }
    if (isnan(absval)) {
        return sign | 0x7fc00000;
    }

    mant = frexp(absval, &expo);

    /* Normalize mantissa to be in the range [1.0, 2.0) */
    if (0.5 <= mant && mant < 1.0) {
        mant *= 2.0;
        expo--;
    }
    else if (mant == 0.0) {
        expo = 0;
    }
    else {
        return sign | 0x7f800000; /* infinity */
    }

    if (expo >= 128) {
        return sign | 0x7f800000; /* infinity */
    }
    else if (expo < -126) {
        /* Denormalized (very small) number */
        mant = ldexp(mant, 126 + expo);
        expo = 0;
    }
    else if (!(expo == 0 && mant == 0.0)) {
        expo += 127;
        mant -= 1.0; /* Get rid of leading 1 */
    }

    mant *= 8388608.0; /* 2^23 */
    fbits = (uint32_t)(mant + 0.5); /* round mant to nearest int */
    if (fbits >> 23) {
        /* The carry propagated out of a string of 23 1 bits. */
        fbits = 0;
        expo++;
        if (expo >= 255) {
            return sign | 0x7f800000; /* infinity */
        }
    }

    return (sign) | ((uint32_t)(expo << 23)) | (fbits);
}

int CLiteralsModel::character_digit_value(wchar_t c) {
	if ((c >= '0') && (c <= '9')) return c - '0';
	return 10;
}

void CLiteralsModel::compile_literal_real(code_generation_target *cgt,
	code_generation *gen, text_stream *textual) {
	int at = 0;
	wchar_t lookahead = Str::get_at(textual, at++);
	int expo=0; double intv=0, fracv=0;
	int expocount=0, intcount=0, fraccount=0, signbit=0;
	if (lookahead == '-') {
		signbit = 1;
		lookahead = Str::get_at(textual, at++);
	} else if (lookahead == '+') {
		signbit = 0;
		lookahead = Str::get_at(textual, at++);
	}
	while (CLiteralsModel::character_digit_value(lookahead) < 10) {
		intv = 10.0*intv + CLiteralsModel::character_digit_value(lookahead);
		intcount++;
		lookahead = Str::get_at(textual, at++);
	}
	if (lookahead == '.') {
		double fracpow = 1.0;
		lookahead = Str::get_at(textual, at++);
		while (CLiteralsModel::character_digit_value(lookahead) < 10) {
			fracpow *= 0.1;
			fracv = fracv + fracpow*CLiteralsModel::character_digit_value(lookahead);
			fraccount++;
			lookahead = Str::get_at(textual, at++);
		}
	}
	if (lookahead == 'e' || lookahead == 'E') {
		int exposign = 0;
		lookahead = Str::get_at(textual, at++);
		if (lookahead == '+' || lookahead == '-') {
			exposign = (lookahead == '-');
			lookahead = Str::get_at(textual, at++);
		}
		while (CLiteralsModel::character_digit_value(lookahead) < 10) {
			expo = 10*expo + CLiteralsModel::character_digit_value(lookahead);
			expocount++;
			lookahead = Str::get_at(textual, at++);
		}
		if (expocount == 0) {
			WRITE_TO(STDERR, "Floating-point literal '%S' must have digits after the 'e'", textual);
			exit(1);
		}
		if (exposign) { expo = -expo; }
	}
	if (intcount + fraccount == 0) {
		WRITE_TO(STDERR, "Floating-point literal '%S' must have digits", textual);
		exit(1);
	}
	uint32_t n = CLiteralsModel::construct_float(signbit, intv, fracv, expo);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("(i7val) 0x%08x", n);
}

@

=
void CLiteralsModel::compile_literal_text(code_generation_target *cgt, code_generation *gen,
	text_stream *S, int printing_mode, int box_mode, int escape_mode) {
	text_stream *OUT = CodeGen::current(gen);
	
	if (printing_mode == FALSE) {
		WRITE("(I7VAL_STRINGS_BASE + %d)", C_GEN_DATA(litdata.no_double_quoted_C_strings)++);
		OUT = C_GEN_DATA(litdata.double_quoted_C);
	}
	WRITE("\"");
	if (escape_mode == FALSE) {
		WRITE("%S", S);
	} else {
		LOOP_THROUGH_TEXT(pos, S) {
			wchar_t c = Str::get(pos);
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

int CLiteralsModel::no_strings(code_generation *gen) {
	return C_GEN_DATA(litdata.no_double_quoted_C_strings);
}

int CLiteralsModel::compile_primitive(code_generation *gen, inter_ti bip, inter_tree_node *P) {
	text_stream *OUT = CodeGen::current(gen);
	switch (bip) {
		case PRINTSTRING_BIP: WRITE("i7_print_C_string(dqs["); INV_A1; WRITE(" - I7VAL_STRINGS_BASE])"); break;
		case PRINTDWORD_BIP:  WRITE("i7_print_C_string(sqs["); INV_A1; WRITE("])"); break;
		default:              return NOT_APPLICABLE;
	}
	return FALSE;
}
