[VanillaConstants::] Vanilla Constants.

How the vanilla code generation strategy handles constants, including literal
texts, lists, and arrays.

@ During the main //Vanilla// traverse, this is called on each constant definition
in the tree:

=
void VanillaConstants::constant(code_generation *gen, inter_tree_node *P) {
	inter_symbol *con_name =
		InterSymbolsTable::symbol_from_ID_at_node(P, DEFN_CONST_IFLD);
	if (con_name == NULL) internal_error("no constant");
	if (InterSymbol::is_metadata_key(con_name) == FALSE) {
		text_stream *S = InterSymbol::identifier(con_name);
		if (SymbolAnnotation::get_b(con_name, FAKE_ACTION_IANN)) {
			@<Declare this constant as a fake action name@>;
		} else if (Str::prefix_eq(S, I"##", 2))  {
			@<Declare this constant as an action name@>;
		} else if (SymbolAnnotation::get_b(con_name, VENEER_IANN)) {
			@<Ignore this constant as part of the veneer@>;
		} else if (SymbolAnnotation::get_b(con_name, OBJECT_IANN)) {
			@<Declare this constant as a pseudo-object@>;
		} else if (Str::eq(InterSymbol::identifier(con_name), I"UUID_ARRAY")) {
			@<Declare this constant as the special UUID string array@>;
		} else switch (ConstantInstruction::list_format(P)) {
			case CONST_LIST_FORMAT_NONE: @<Declare this as an explicit constant@>; break;
			case CONST_LIST_FORMAT_SUM:
			case CONST_LIST_FORMAT_PRODUCT:
			case CONST_LIST_FORMAT_DIFFERENCE:
			case CONST_LIST_FORMAT_QUOTIENT: @<Declare this as a computed constant@>; break;
			default:
				if (ConstantInstruction::is_a_genuine_list_format(
					ConstantInstruction::list_format(P))) {
					@<Declare this as a list constant@>; break;
				}
				internal_error("ungenerated constant format");
		}
	}
}

@<Declare this constant as an action name@> =
	text_stream *fa = Str::duplicate(InterSymbol::identifier(con_name));
	Str::delete_first_character(fa);
	Str::delete_first_character(fa);
	Generators::new_action(gen, fa, TRUE, gen->true_action_count++);
	ADD_TO_LINKED_LIST(fa, text_stream, gen->actions);

@<Declare this constant as a fake action name@> =
	text_stream *fa = Str::duplicate(InterSymbol::identifier(con_name));
	Str::delete_first_character(fa);
	Str::delete_first_character(fa);
	Generators::new_action(gen, fa, FALSE, 4096 + gen->fake_action_count++);

@<Ignore this constant as part of the veneer@> =
	;

@<Declare this constant as a pseudo-object@> =
	Generators::pseudo_object(gen, InterSymbol::trans(con_name));

@<Declare this constant as the special UUID string array@> =
	inter_pair val = ConstantInstruction::constant(P);
	text_stream *S = InterValuePairs::to_text(Inode::tree(P), val);
	segmentation_pos saved;
	TEMPORARY_TEXT(content)
	TEMPORARY_TEXT(length)
	WRITE_TO(content, "UUID://");
	for (int i=0, L=Str::len(S); i<L; i++)
		WRITE_TO(content, "%c", Characters::toupper(Str::get_at(S, i)));
	WRITE_TO(content, "//");
	WRITE_TO(length, "%d", (int) Str::len(content));

	Generators::begin_array(gen, I"UUID_ARRAY", NULL, NULL, BYTE_ARRAY_FORMAT, -1, &saved);
	Generators::array_entry(gen, length, BYTE_ARRAY_FORMAT);
	LOOP_THROUGH_TEXT(pos, content) {
		TEMPORARY_TEXT(ch)
		WRITE_TO(ch, "'%c'", Str::get(pos));
		Generators::array_entry(gen, ch, BYTE_ARRAY_FORMAT);
		DISCARD_TEXT(ch)
	}
	Generators::end_array(gen, BYTE_ARRAY_FORMAT, -1, &saved);
	DISCARD_TEXT(length)
	DISCARD_TEXT(content)

@ Inter supports four sorts of arrays, with behaviour as laid out in this 2x2 grid:
= (text)
			 | entries count 0, 1, 2,...	 | entry 0 is N, then entries count 1, 2, ..., N
-------------+-------------------------------+-----------------------------------------------
byte entries | BYTE_ARRAY_FORMAT             | BUFFER_ARRAY_FORMAT
-------------+-------------------------------+-----------------------------------------------
word entries | WORD_ARRAY_FORMAT             | TABLE_ARRAY_FORMAT
-------------+-------------------------------+-----------------------------------------------
=
Note that if an array assimilated from a kit has exactly one purported entry, then
in fact this should be interpreted as being that many blank entries. This number
must however be carefully evaluated, as it may be another constant name rather
than a literal, or may even be computed.

@<Declare this as a list constant@> =
	int format;
	if (ConstantInstruction::is_a_byte_format(ConstantInstruction::list_format(P))) {
		if (ConstantInstruction::is_a_bounded_format(ConstantInstruction::list_format(P)))
			format = BUFFER_ARRAY_FORMAT;
		else
			format = BYTE_ARRAY_FORMAT;
	} else {
		if (ConstantInstruction::is_a_bounded_format(ConstantInstruction::list_format(P)))
			format = TABLE_ARRAY_FORMAT;
		else
			format = WORD_ARRAY_FORMAT;
	}

	int zero_count = -1;
	int entry_count = ConstantInstruction::list_len(P);
	if (ConstantInstruction::is_a_by_extent_format(ConstantInstruction::list_format(P))) {
		inter_pair val = ConstantInstruction::list_entry(P, 0);
		zero_count = (int) ConstantInstruction::evaluate(InterPackage::scope_of(P), val);
	}

	segmentation_pos saved;
	if (Generators::begin_array(gen, InterSymbol::trans(con_name), con_name, P,
		format, zero_count, &saved)) {
		if (zero_count == -1) {
			for (int i=0; i<entry_count; i++) {
				TEMPORARY_TEXT(entry)
				CodeGen::select_temporary(gen, entry);
				CodeGen::pair(gen, P, ConstantInstruction::list_entry(P, i));
				CodeGen::deselect_temporary(gen);
				Generators::array_entry(gen, entry, format);
				DISCARD_TEXT(entry)
			}
		}
		Generators::end_array(gen, format, zero_count, &saved);
	}

@<Declare this as a computed constant@> =
	Generators::declare_constant(gen, con_name, COMPUTED_GDCFORM, NULL);

@<Declare this as an explicit constant@> =
	inter_pair val = ConstantInstruction::constant(P);
	if (InterValuePairs::is_text(val)) {
		text_stream *S = InterValuePairs::to_text(Inode::tree(P), val);
		VanillaConstants::defer_declaring_literal_text(gen, S, con_name);
	} else {
		Generators::declare_constant(gen, con_name, DATA_GDCFORM, NULL);
	}

@ When called by //Generators::declare_constant//, generators may if they choose
make use of the following convenient function for generating the value to which a
constant name is given.

Note that this assumes that the usual arithmetic operators and brackets can be
used in the syntax for literal quantities: e.g., it may produce |(A + (3 * B))|
for constants |A|, |B|. If the generator is for a language which doesn't allow
that, it will have to make other arrangements.

=
void VanillaConstants::definition_value(code_generation *gen, int form,
	inter_symbol *con_name, text_stream *val) {
	inter_tree_node *P = con_name->definition;
	text_stream *OUT = CodeGen::current(gen);
	switch (form) {
		case RAW_GDCFORM:
			if (Str::len(val) > 0) {
				WRITE("%S", val);
			} else {
				Generators::compile_literal_number(gen, 1, FALSE);
			}
			break;
		case MANGLED_GDCFORM:
			if (Str::len(val) > 0) {
				Generators::mangle(gen, OUT, val);
			} else {
				Generators::compile_literal_number(gen, 1, FALSE);
			}
			break;
		case DATA_GDCFORM:
			CodeGen::pair(gen, P, ConstantInstruction::constant(P));
			break;
		case COMPUTED_GDCFORM: {
			WRITE("(");
			for (int i=0; i<ConstantInstruction::list_len(P); i++) {
				if (i>0) {
					switch (ConstantInstruction::list_format(P)) {
						case CONST_LIST_FORMAT_SUM:        WRITE(" + "); break;
						case CONST_LIST_FORMAT_PRODUCT:    WRITE(" * "); break;
						case CONST_LIST_FORMAT_DIFFERENCE: WRITE(" - "); break;
						case CONST_LIST_FORMAT_QUOTIENT:   WRITE(" / "); break;
					}
				}
				int bracket = TRUE;
				inter_pair operand = ConstantInstruction::list_entry(P, i);
				if ((InterValuePairs::is_number(operand)) ||
					(InterValuePairs::is_symbolic(operand))) bracket = FALSE;
				if (bracket) WRITE("(");
				CodeGen::pair(gen, P, operand);
				if (bracket) WRITE(")");
			}
			WRITE(")");
			break;
		}
		case LITERAL_TEXT_GDCFORM:
			Generators::compile_literal_text(gen, val, FALSE);
			break;
	}
}

@ During the above process, a constant set equal to a text literal is not
immediately declared: instead, the following mechanism is used to stash it for
later.

=
typedef struct text_literal_holder {
	struct text_stream *literal_content;
	struct inter_symbol *con_name;
	CLASS_DEFINITION
} text_literal_holder;

void VanillaConstants::defer_declaring_literal_text(code_generation *gen, text_stream *S,
	inter_symbol *con_name) {
	text_literal_holder *tlh = CREATE(text_literal_holder);
	tlh->literal_content = S;
	tlh->con_name = con_name;
	ADD_TO_LINKED_LIST(tlh, text_literal_holder, gen->text_literals);
}

@ And now it's later. We go through all of the stashed text literals, and sort
them into alphabetical order; and then declare them. What this whole business
achieves, then, is to declare text constants in alphabetical order rather than
in tree order.

=
void VanillaConstants::declare_text_literals(code_generation *gen) {
	int no_tlh = LinkedLists::len(gen->text_literals);
	if (no_tlh > 0) {
		text_literal_holder **sorted = (text_literal_holder **)
			(Memory::calloc(no_tlh, sizeof(text_literal_holder *), CODE_GENERATION_MREASON));
		int i = 0;
		text_literal_holder *tlh;
		LOOP_OVER_LINKED_LIST(tlh, text_literal_holder, gen->text_literals)
			sorted[i++] = tlh;
		qsort(sorted, (size_t) no_tlh, sizeof(text_literal_holder *),
			VanillaConstants::compare_tlh);
		for (int i=0; i<no_tlh; i++) {
			text_literal_holder *tlh = sorted[i];
			Generators::declare_constant(gen, tlh->con_name, LITERAL_TEXT_GDCFORM,
				tlh->literal_content);
		}
	}
}

@ Note that |Str::cmp| is a case-sensitive comparison, so |Zebra| will come
before |armadillo|, for example, |Z| being before |a| in Unicode.

=
int VanillaConstants::compare_tlh(const void *elem1, const void *elem2) {
	const text_literal_holder **e1 = (const text_literal_holder **) elem1;
	const text_literal_holder **e2 = (const text_literal_holder **) elem2;
	if ((*e1 == NULL) || (*e2 == NULL))
		internal_error("Disaster while sorting text literals");
	text_stream *s1 = (*e1)->literal_content;
	text_stream *s2 = (*e2)->literal_content;
	return Str::cmp(s1, s2);
}

@ The remainder of this section is given over to a utility function which
generators may want to use: it turns an Inter-notation text for a real number
into an unsigned 32-bit integer which can represent that number at runtime
(provided we are on a 32-bit computer: the Z-machine need not apply).

No error messages should be printed, of course, because the syntax should have
been checked before the text here entered the Inter hierarchy.

The code below is adapted from additions made by Andrew Plotkin to the Inform 6
compiler to accommodate floating-point arithmetic.

=
uint32_t VanillaConstants::textual_real_to_uint32(text_stream *T) {
	int at = 0;
	wchar_t lookahead = Str::get_at(T, at++);
	int expo=0; double intv=0, fracv=0;
	int expocount=0, intcount=0, fraccount=0, signbit=0;
	if (lookahead == '-') {
		signbit = 1;
		lookahead = Str::get_at(T, at++);
	} else if (lookahead == '+') {
		signbit = 0;
		lookahead = Str::get_at(T, at++);
	}
	while (VanillaConstants::character_digit_value(lookahead) < 10) {
		intv = 10.0*intv + VanillaConstants::character_digit_value(lookahead);
		intcount++;
		lookahead = Str::get_at(T, at++);
	}
	if (lookahead == '.') {
		double fracpow = 1.0;
		lookahead = Str::get_at(T, at++);
		while (VanillaConstants::character_digit_value(lookahead) < 10) {
			fracpow *= 0.1;
			fracv = fracv + fracpow*VanillaConstants::character_digit_value(lookahead);
			fraccount++;
			lookahead = Str::get_at(T, at++);
		}
	}
	if (lookahead == 'e' || lookahead == 'E') {
		int exposign = 0;
		lookahead = Str::get_at(T, at++);
		if (lookahead == '+' || lookahead == '-') {
			exposign = (lookahead == '-');
			lookahead = Str::get_at(T, at++);
		}
		while (VanillaConstants::character_digit_value(lookahead) < 10) {
			expo = 10*expo + VanillaConstants::character_digit_value(lookahead);
			expocount++;
			lookahead = Str::get_at(T, at++);
		}
		if (expocount == 0) {
			WRITE_TO(STDERR, "Floating-point literal '%S' must have digits after the 'e'", T);
			internal_error("bad floating-point literal");
		}
		if (exposign) { expo = -expo; }
	}
	if (intcount + fraccount == 0) {
		WRITE_TO(STDERR, "Floating-point literal '%S' must have digits", T);
		internal_error("bad floating-point literal");
	}
	return VanillaConstants::real_components_to_uint32(signbit, intv, fracv, expo);
}

int VanillaConstants::character_digit_value(wchar_t c) {
	if ((c >= '0') && (c <= '9')) return c - '0';
	return 10;
}

@ And this returns 10 raised to the power |expo|, which is an integer. Andrew
Plotkin refers to this as "cheap" because it avoids the C library |pow10|,
which is awkward on some platforms.

=
#ifndef POW10_RANGE
#define POW10_RANGE (8)
#endif

double VanillaConstants::pow10_cheap(int expo) {
    static double powers[POW10_RANGE*2+1] = {
        0.00000001, 0.0000001, 0.000001, 0.00001, 0.0001, 0.001, 0.01, 0.1,
        1.0,
        10.0, 100.0, 1000.0, 10000.0, 100000.0, 1000000.0, 10000000.0, 100000000.0
    };
    double res = 1.0;
    if (expo < 0) {
        for (; expo < -POW10_RANGE; expo += POW10_RANGE) res *= powers[0];
        return res * powers[POW10_RANGE+expo];
    } else {
        for (; expo > POW10_RANGE; expo -= POW10_RANGE) res *= powers[POW10_RANGE*2];
        return res * powers[POW10_RANGE+expo];
    }
}

@ Finally, this function returns the IEEE-754 single-precision encoding of a
floating-point number from its various components.

See http://www.psc.edu/general/software/packages/ieee/ieee.php for an explanation.

If the magnitude is too large (beyond about 3.4e+38), this returns
an infinite value (0x7f800000 or 0xff800000). If the magnitude is too
small (below about 1e-45), this returns a zero value (0x00000000 or 
0x80000000). If any of the inputs are NaN, this returns NaN.

=
uint32_t VanillaConstants::real_components_to_uint32(int signbit, double intv,
	double fracv, int expo) {

    double absval = (intv + fracv) * VanillaConstants::pow10_cheap(expo);

    uint32_t sign = (signbit ? 0x80000000 : 0x0);
 
    if (isinf(absval)) return sign | 0x7f800000; /* infinity */
    if (isnan(absval)) return sign | 0x7fc00000; /* NaN */

   double mant = frexp(absval, &expo);

    /* Normalize mantissa to be in the range [1.0, 2.0) */
    if (0.5 <= mant && mant < 1.0) {
        mant *= 2.0;
        expo--;
    } else if (mant == 0.0) {
        expo = 0;
    } else {
        return sign | 0x7f800000; /* infinity */
    }

    if (expo >= 128) {
        return sign | 0x7f800000; /* infinity */
    } else if (expo < -126) {
        /* Denormalized (very small) number */
        mant = ldexp(mant, 126 + expo);
        expo = 0;
    } else if (!(expo == 0 && mant == 0.0)) {
        expo += 127;
        mant -= 1.0; /* Get rid of leading 1 */
    }

    mant *= 8388608.0; /* 2^23 */
    uint32_t fbits = (uint32_t)(mant + 0.5); /* round mant to nearest int */
    if (fbits >> 23) {
        /* The carry propagated out of a string of 23 1 bits. */
        fbits = 0;
        expo++;
        if (expo >= 255) return sign | 0x7f800000; /* infinity */
    }

    return (sign) | ((uint32_t)(expo << 23)) | (fbits);
}
