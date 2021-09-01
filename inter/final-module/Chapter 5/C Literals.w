[CLiteralsModel::] C Literals.

Text and dictionary words translated to C.

@h Setting up the model.

=
void CLiteralsModel::initialise(code_generation_target *cgt) {
	METHOD_ADD(cgt, COMPILE_DICTIONARY_WORD_MTID, CLiteralsModel::compile_dictionary_word);
	METHOD_ADD(cgt, COMPILE_LITERAL_NUMBER_MTID, CLiteralsModel::compile_literal_number);
	METHOD_ADD(cgt, COMPILE_LITERAL_REAL_MTID, CLiteralsModel::compile_literal_real);
	METHOD_ADD(cgt, COMPILE_LITERAL_TEXT_MTID, CLiteralsModel::compile_literal_text);
	METHOD_ADD(cgt, NEW_ACTION_MTID, CLiteralsModel::new_action);
}

typedef struct C_generation_literals_model_data {
	text_stream *double_quoted_C;
	int no_double_quoted_C_strings;
	int C_dword_count;
	int verb_count;
	int C_action_count;
	int C_fake_action_count;
	struct linked_list *words; /* of |C_dword| */
	struct linked_list *verbs; /* of |C_dword| */
	struct linked_list *actions; /* of |text_stream| */
	struct linked_list *verb_grammar; /* of |text_stream| */
	struct dictionary *C_vm_dictionary; /* ditto */
} C_generation_literals_model_data;

void CLiteralsModel::initialise_data(code_generation *gen) {
	C_GEN_DATA(litdata.double_quoted_C) = Str::new();
	C_GEN_DATA(litdata.no_double_quoted_C_strings) = 0;
	C_GEN_DATA(litdata.C_dword_count) = 0;
	C_GEN_DATA(litdata.verb_count) = 0;
	C_GEN_DATA(litdata.C_action_count) = 0;
	C_GEN_DATA(litdata.C_fake_action_count) = 4096;
	C_GEN_DATA(litdata.words) = NEW_LINKED_LIST(C_dword);
	C_GEN_DATA(litdata.verbs) = NEW_LINKED_LIST(C_dword);
	C_GEN_DATA(litdata.actions) = NEW_LINKED_LIST(text_stream);
	C_GEN_DATA(litdata.verb_grammar) = NEW_LINKED_LIST(text_stream);

	C_GEN_DATA(litdata.C_vm_dictionary) = Dictionaries::new(1024, FALSE);
}

void CLiteralsModel::begin(code_generation *gen) {
	CLiteralsModel::initialise_data(gen);
}

void CLiteralsModel::end(code_generation *gen) {
	CLiteralsModel::compile_dwords(gen);
	CLiteralsModel::compile_verb_table(gen);
	CLiteralsModel::compile_actions_table(gen);
	generated_segment *saved = CodeGen::select(gen, c_predeclarations_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("char *dqs[] = {\n%S\"\" };\n", C_GEN_DATA(litdata.double_quoted_C));
	WRITE("#define i7_mgl_Grammar__Version 2\n");
	CodeGen::deselect(gen, saved);
}

@

=
typedef struct C_dword {
	struct text_stream *text;
	struct text_stream *identifier;
	int pluralise;
	int meta;
	int preplike;
	int nounlike;
	int verblike;
	int verb_number;
	int grammar_table_offset;
	CLASS_DEFINITION
} C_dword;

C_dword *CLiteralsModel::text_to_dword(code_generation *gen, text_stream *S, int pluralise) {
	TEMPORARY_TEXT(K)
	LOOP_THROUGH_TEXT(pos, S)
		PUT_TO(K, Characters::tolower(Str::get(pos)));
	while (Str::get_last_char(K) == '/') Str::delete_last_character(K);
	C_dword *dw;
	if (Dictionaries::find(C_GEN_DATA(litdata.C_vm_dictionary), K)) {
		dw = Dictionaries::read_value(C_GEN_DATA(litdata.C_vm_dictionary), K);
		if (pluralise) dw->pluralise = TRUE;
	} else {
		dw = CREATE(C_dword);
		dw->text = Str::duplicate(K);
		dw->identifier = Str::new();
		WRITE_TO(dw->identifier,
			"i7_dword_%d", C_GEN_DATA(litdata.C_dword_count)++);
		dw->pluralise = pluralise;
		dw->meta = FALSE;
		dw->preplike = FALSE;
		dw->nounlike = FALSE;
		dw->verblike = FALSE;
		dw->verb_number = 0;
		dw->grammar_table_offset = 0;
		ADD_TO_LINKED_LIST(dw, C_dword, C_GEN_DATA(litdata.words));
		Dictionaries::create(C_GEN_DATA(litdata.C_vm_dictionary), K);
		Dictionaries::write_value(C_GEN_DATA(litdata.C_vm_dictionary), K, dw);
	}
	DISCARD_TEXT(K)
	return dw;
}

void CLiteralsModel::compile_dwords(code_generation *gen) {
	int dictlen = C_GEN_DATA(litdata.C_dword_count);

	generated_segment *saved = CodeGen::select(gen, c_predeclarations_I7CGS);
	CMemoryModel::begin_array(NULL, gen, I"#dictionary_table", NULL, NULL, BYTE_ARRAY_FORMAT);
	for (int b=0; b<4; b++) {
		TEMPORARY_TEXT(N)
		WRITE_TO(N, "I7BYTE_%d(%d)", b, dictlen);
		CMemoryModel::array_entry(NULL, gen, N, BYTE_ARRAY_FORMAT);
		DISCARD_TEXT(N)
	}
	CMemoryModel::end_array(NULL, gen, BYTE_ARRAY_FORMAT);

	if (dictlen == 0) return;
	C_dword **sorted = (C_dword **)
		(Memory::calloc(dictlen, sizeof(C_dword *), CODE_GENERATION_MREASON));
	C_dword *dw; int i=0;
	LOOP_OVER_LINKED_LIST(dw, C_dword, C_GEN_DATA(litdata.words)) sorted[i++] = dw;
	qsort(sorted, (size_t) LinkedLists::len(C_GEN_DATA(litdata.words)), sizeof(C_dword *), CLiteralsModel::compare_dwords);
	for (int i=0; i<dictlen; i++) {
		dw = sorted[i];
		CMemoryModel::begin_array(NULL, gen, sorted[i]->identifier, NULL, NULL, BYTE_ARRAY_FORMAT);
		TEMPORARY_TEXT(N)
		WRITE_TO(N, "%d", Str::len(dw->text));
		CMemoryModel::array_entry(NULL, gen, N, BYTE_ARRAY_FORMAT);
		DISCARD_TEXT(N);
		for (int i=0; i<9; i++) {
			TEMPORARY_TEXT(N)
			if (i < Str::len(dw->text))
				WRITE_TO(N, "'%c'", Str::get_at(dw->text, i));
			else
				WRITE_TO(N, "0");
			CMemoryModel::array_entry(NULL, gen, N, BYTE_ARRAY_FORMAT);
			DISCARD_TEXT(N);
		}
		TEMPORARY_TEXT(DP1H)
		TEMPORARY_TEXT(DP1L)
		TEMPORARY_TEXT(DP2H)
		TEMPORARY_TEXT(DP2L)
		int f = 0;
		if (dw->verblike) f += 1;
		if (dw->meta) f += 2;
		if (dw->pluralise) f += 4;
		if (dw->preplike) f += 8;
		if (dw->nounlike) f += 128;
		WRITE_TO(DP1H, "((%d)/256)", f);
		WRITE_TO(DP1L, "((%d)%%256)", f);
		WRITE_TO(DP2H, "((%d)/256)", 0xFFFF - dw->verb_number);
		WRITE_TO(DP2L, "((%d)%%256)", 0xFFFF - dw->verb_number);
		CMemoryModel::array_entry(NULL, gen, DP1H, BYTE_ARRAY_FORMAT);
		CMemoryModel::array_entry(NULL, gen, DP1L, BYTE_ARRAY_FORMAT);
		CMemoryModel::array_entry(NULL, gen, DP2H, BYTE_ARRAY_FORMAT);
		CMemoryModel::array_entry(NULL, gen, DP2L, BYTE_ARRAY_FORMAT);
		CMemoryModel::array_entry(NULL, gen, I"0", BYTE_ARRAY_FORMAT);
		CMemoryModel::array_entry(NULL, gen, I"0", BYTE_ARRAY_FORMAT);
		DISCARD_TEXT(DP1H)
		DISCARD_TEXT(DP1L)
		DISCARD_TEXT(DP2H)
		DISCARD_TEXT(DP2L)
		CMemoryModel::end_array(NULL, gen, BYTE_ARRAY_FORMAT);
	}
	Memory::I7_free(sorted, CODE_GENERATION_MREASON, dictlen);
	CodeGen::deselect(gen, saved);
}

int CLiteralsModel::compare_dwords(const void *ent1, const void *ent2) {
	text_stream *tx1 = (*((const C_dword **) ent1))->text;
	text_stream *tx2 = (*((const C_dword **) ent2))->text;
	return Str::cmp_insensitive(tx1, tx2);
}

void CLiteralsModel::compile_dictionary_word(code_generation_target *cgt, code_generation *gen,
	text_stream *S, int pluralise) {
	text_stream *OUT = CodeGen::current(gen);
	C_dword *dw = CLiteralsModel::text_to_dword(gen, S, pluralise);
	CNamespace::mangle(cgt, OUT, dw->identifier);
}

void CLiteralsModel::verb_grammar(code_generation_target *cgt, code_generation *gen,
	inter_symbol *array_s, inter_tree_node *P) {
	inter_tree *I = gen->from;
	int verbnum = C_GEN_DATA(litdata.verb_count)++;
	
	inter_symbol *line_actions[128];
	int line_reverse[128];
	
	int lines = 0;
	for (int i=DATA_CONST_IFLD; i<P->W.extent; i=i+2) {
		inter_ti val1 = P->W.data[i], val2 = P->W.data[i+1];
		if (Inter::Symbols::is_stored_in_data(val1, val2)) {
			inter_symbol *aliased = InterSymbolsTables::symbol_from_data_pair_and_table(val1, val2, Inter::Packages::scope_of(P));
			if (aliased == NULL) internal_error("bad aliased symbol");
			if (Str::eq(aliased->symbol_name, I"VERB_DIRECTIVE_DIVIDER")) {
				line_reverse[lines] = FALSE;
				line_actions[lines++] = NULL;
			}
			if (Str::eq(aliased->symbol_name, I"VERB_DIRECTIVE_RESULT")) {
				inter_ti val1 = P->W.data[i+2], val2 = P->W.data[i+3];
				inter_symbol *res = InterSymbolsTables::symbol_from_data_pair_and_table(val1, val2, Inter::Packages::scope_of(P));
				if (res == NULL) internal_error("bad aliased symbol");
				line_actions[lines-1] = res;
			}
			if (Str::eq(aliased->symbol_name, I"VERB_DIRECTIVE_REVERSE")) {
				inter_ti val1 = P->W.data[i], val2 = P->W.data[i+1];
				inter_symbol *res = InterSymbolsTables::symbol_from_data_pair_and_table(val1, val2, Inter::Packages::scope_of(P));
				if (res == NULL) internal_error("bad aliased symbol");
				line_reverse[lines-1] = TRUE;
			}
		}
	}
	
	int address = LinkedLists::len(C_GEN_DATA(litdata.verb_grammar));
	CLiteralsModel::grammar_byte(gen, lines); /* no grammar lines */

	int stage = 1, synonyms = 0, started = FALSE;
	lines = 0;
	for (int i=DATA_CONST_IFLD; i<P->W.extent; i=i+2) {
		inter_ti val1 = P->W.data[i], val2 = P->W.data[i+1];
		if (stage == 1) {
			if (val1 == DWORD_IVAL) {
				text_stream *glob_text = Inter::Warehouse::get_text(InterTree::warehouse(I), val2);
				C_dword *dw = CLiteralsModel::text_to_dword(gen, glob_text, FALSE);
				dw->verb_number = verbnum; dw->verblike = TRUE;
				if (Inter::Symbols::read_annotation(array_s, METAVERB_IANN) == 1) dw->meta = TRUE;
				synonyms++;
				if (synonyms == 1) {
					ADD_TO_LINKED_LIST(dw, C_dword, C_GEN_DATA(litdata.verbs));
				}
				dw->grammar_table_offset = address;
			} else if (Inter::Symbols::is_stored_in_data(val1, val2)) {
				inter_symbol *aliased = InterSymbolsTables::symbol_from_data_pair_and_table(val1, val2, Inter::Packages::scope_of(P));
				if (aliased == NULL) internal_error("bad aliased symbol");
				if (Str::eq(aliased->symbol_name, I"VERB_DIRECTIVE_DIVIDER")) { stage = 2; i -= 2; continue; }
				else internal_error("not a divider");
			} else {
				internal_error("not a dword");
			}
		}
		if (stage == 2) {
			if (Inter::Symbols::is_stored_in_data(val1, val2)) {
				inter_symbol *aliased = InterSymbolsTables::symbol_from_data_pair_and_table(val1, val2, Inter::Packages::scope_of(P));
				if (aliased == NULL) internal_error("bad aliased symbol");
				if (Str::eq(aliased->symbol_name, I"VERB_DIRECTIVE_DIVIDER")) {
					if (started) CLiteralsModel::grammar_byte_textual(gen, I"i7_mgl_ENDIT_TOKEN");
					TEMPORARY_TEXT(NT)
					CNamespace::mangle(cgt, NT, line_actions[lines]->symbol_name);
					TEMPORARY_TEXT(A)
					TEMPORARY_TEXT(B)
					WRITE_TO(A, "I7BYTE_2(%S)", NT);
					WRITE_TO(B, "I7BYTE_3(%S)", NT);
					CLiteralsModel::grammar_byte_textual(gen, A); /* action (big end) */
					CLiteralsModel::grammar_byte_textual(gen, B); /* action (lil end) */
					DISCARD_TEXT(A)
					DISCARD_TEXT(B)
					DISCARD_TEXT(NT)
					if (line_reverse[lines])
						CLiteralsModel::grammar_byte(gen, 1);
					else
						CLiteralsModel::grammar_byte(gen, 0);
					lines++;
					started = TRUE;
					continue;
				}
				if (Str::eq(aliased->symbol_name, I"VERB_DIRECTIVE_RESULT")) {
					i += 2;
					continue;
				}
				if (Str::eq(aliased->symbol_name, I"VERB_DIRECTIVE_REVERSE")) continue;

				int lookahead = 0;
				if (i+2 < P->W.extent) {
					inter_ti laval1 = P->W.data[i+2], laval2 = P->W.data[i+3];
					if (Inter::Symbols::is_stored_in_data(laval1, laval2)) {
						inter_symbol *aliased =
							InterSymbolsTables::symbol_from_data_pair_and_table(laval1, laval2, Inter::Packages::scope_of(P));
						if (Str::eq(aliased->symbol_name, I"VERB_DIRECTIVE_SLASH")) {
							i += 2;
							lookahead = 0x20;
						}
					}
				}
				
				if (Str::eq(aliased->symbol_name, I"VERB_DIRECTIVE_HELD")) {
					CLiteralsModel::grammar_byte(gen, 1 + lookahead);
					CLiteralsModel::grammar_word(gen, 1);
					continue;
				}
				if (Str::eq(aliased->symbol_name, I"VERB_DIRECTIVE_MULTI")) {
					CLiteralsModel::grammar_byte(gen, 1 + lookahead);
					CLiteralsModel::grammar_word(gen, 2);
					continue;
				}
				if (Str::eq(aliased->symbol_name, I"VERB_DIRECTIVE_MULTIHELD")) {
					CLiteralsModel::grammar_byte(gen, 1 + lookahead);
					CLiteralsModel::grammar_word(gen, 3);
					continue;
				}
				if (Str::eq(aliased->symbol_name, I"VERB_DIRECTIVE_MULTIEXCEPT")) {
					CLiteralsModel::grammar_byte(gen, 1 + lookahead);
					CLiteralsModel::grammar_word(gen, 4);
					continue;
				}
				if (Str::eq(aliased->symbol_name, I"VERB_DIRECTIVE_MULTIINSIDE")) {
					CLiteralsModel::grammar_byte(gen, 1 + lookahead);
					CLiteralsModel::grammar_word(gen, 5);
					continue;
				}
				if (Str::eq(aliased->symbol_name, I"VERB_DIRECTIVE_CREATURE")) {
					CLiteralsModel::grammar_byte(gen, 1 + lookahead);
					CLiteralsModel::grammar_word(gen, 6);
					continue;
				}
				if (Str::eq(aliased->symbol_name, I"VERB_DIRECTIVE_SPECIAL")) {
					CLiteralsModel::grammar_byte(gen, 1 + lookahead);
					CLiteralsModel::grammar_word(gen, 7);
					continue;
				}
				if (Str::eq(aliased->symbol_name, I"VERB_DIRECTIVE_NUMBER")) {
					CLiteralsModel::grammar_byte(gen, 1 + lookahead);
					CLiteralsModel::grammar_word(gen, 8);
					continue;
				}
				if (Str::eq(aliased->symbol_name, I"VERB_DIRECTIVE_TOPIC")) {
					CLiteralsModel::grammar_byte(gen, 1 + lookahead);
					CLiteralsModel::grammar_word(gen, 9);
					continue;
				}
				int bc = 0x86;				
				if (Inter::Symbols::read_annotation(aliased, SCOPE_FILTER_IANN) == 1)
					bc = 0x85;
				if (Inter::Symbols::read_annotation(aliased, NOUN_FILTER_IANN) == 1)
					bc = 0x83;
				CLiteralsModel::grammar_byte(gen, bc + lookahead);
				TEMPORARY_TEXT(MG)
				CNamespace::mangle(cgt, MG, CodeGen::CL::name(aliased));
				CLiteralsModel::grammar_word_textual(gen, MG);
				DISCARD_TEXT(MG)
				continue;
			}
			if (val1 == DWORD_IVAL) {
				text_stream *glob_text = Inter::Warehouse::get_text(InterTree::warehouse(I), val2);
				C_dword *dw = CLiteralsModel::text_to_dword(gen, glob_text, FALSE);
				CLiteralsModel::grammar_byte(gen, 0x42);
				TEMPORARY_TEXT(MG)
				CNamespace::mangle(cgt, MG, dw->identifier);
				CLiteralsModel::grammar_word_textual(gen, MG);
				DISCARD_TEXT(MG)
				continue;
			}
			if (val1 == PDWORD_IVAL) {
				text_stream *glob_text = Inter::Warehouse::get_text(InterTree::warehouse(I), val2);
				C_dword *dw = CLiteralsModel::text_to_dword(gen, glob_text, TRUE);
				CLiteralsModel::grammar_byte(gen, 0x42);
				TEMPORARY_TEXT(MG)
				CNamespace::mangle(cgt, MG, dw->identifier);
				CLiteralsModel::grammar_word_textual(gen, MG);
				DISCARD_TEXT(MG)
				continue;
			}
		}
	}
	if (started) CLiteralsModel::grammar_byte_textual(gen, I"i7_mgl_ENDIT_TOKEN");
}

void CLiteralsModel::grammar_byte(code_generation *gen, int N) {
	TEMPORARY_TEXT(NT)
	WRITE_TO(NT, "%d", N);
	CLiteralsModel::grammar_byte_textual(gen, NT);
	DISCARD_TEXT(NT)
}

void CLiteralsModel::grammar_word(code_generation *gen, int N) {
	TEMPORARY_TEXT(NT)
	WRITE_TO(NT, "%d", N);
	CLiteralsModel::grammar_word_textual(gen, NT);
	DISCARD_TEXT(NT)
}

void CLiteralsModel::grammar_word_textual(code_generation *gen, text_stream *NT) {
	for (int b=0; b<4; b++) {
		TEMPORARY_TEXT(BT)
		WRITE_TO(BT, "I7BYTE_%d(%S)", b, NT);
		CLiteralsModel::grammar_byte_textual(gen, BT);
		DISCARD_TEXT(BT)
	}
}

void CLiteralsModel::grammar_byte_textual(code_generation *gen, text_stream *NT) {
	NT = Str::duplicate(NT);
	ADD_TO_LINKED_LIST(NT, text_stream, C_GEN_DATA(litdata.verb_grammar));
}

void CLiteralsModel::compile_verb_table(code_generation *gen) {
	CMemoryModel::begin_array(NULL, gen, I"#grammar_table", NULL, NULL, WORD_ARRAY_FORMAT);
	TEMPORARY_TEXT(N)
	WRITE_TO(N, "%d", C_GEN_DATA(litdata.verb_count) - 1);
	CMemoryModel::array_entry(NULL, gen, N, WORD_ARRAY_FORMAT);
	DISCARD_TEXT(N)
	C_dword *dw; int c = 1;
	LOOP_OVER_LINKED_LIST(dw, C_dword, C_GEN_DATA(litdata.verbs)) {
		TEMPORARY_TEXT(N)
		WRITE_TO(N, "(i7_ss_grammar_table_cont+%d /* %d: %S */ )", dw->grammar_table_offset, c++, dw->text);
		CMemoryModel::array_entry(NULL, gen, N, WORD_ARRAY_FORMAT);
		DISCARD_TEXT(N)
	}
	CMemoryModel::end_array(NULL, gen, WORD_ARRAY_FORMAT);
	CMemoryModel::begin_array(NULL, gen, I"#grammar_table_cont", NULL, NULL, BYTE_ARRAY_FORMAT);
	text_stream *entry;
	LOOP_OVER_LINKED_LIST(entry, text_stream, C_GEN_DATA(litdata.verb_grammar)) {
		CMemoryModel::array_entry(NULL, gen, entry, BYTE_ARRAY_FORMAT);
	}
	CMemoryModel::end_array(NULL, gen, BYTE_ARRAY_FORMAT);

	CMemoryModel::begin_array(NULL, gen, I"#actions_table", NULL, NULL, WORD_ARRAY_FORMAT);
	CMemoryModel::end_array(NULL, gen, WORD_ARRAY_FORMAT);
}

void CLiteralsModel::new_action(code_generation_target *cgt, code_generation *gen, text_stream *name, int true_action) {
	generated_segment *saved = CodeGen::select(gen, c_predeclarations_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	if (true_action) {
		WRITE("#define i7_ss_%S %d\n", name, C_GEN_DATA(litdata.C_action_count)++);
		ADD_TO_LINKED_LIST(Str::duplicate(name), text_stream, C_GEN_DATA(litdata.actions));
	} else {
		WRITE("#define i7_ss_%S %d\n", name, C_GEN_DATA(litdata.C_fake_action_count)++);
	}
	CodeGen::deselect(gen, saved);
}

void CLiteralsModel::compile_actions_table(code_generation *gen) {
	CMemoryModel::begin_array(NULL, gen, I"#actions_table", NULL, NULL, WORD_ARRAY_FORMAT);
	TEMPORARY_TEXT(N)
	WRITE_TO(N, "%d", C_GEN_DATA(litdata.C_action_count));
	CMemoryModel::array_entry(NULL, gen, N, WORD_ARRAY_FORMAT);
	DISCARD_TEXT(N)
	text_stream *an;
	LOOP_OVER_LINKED_LIST(an, text_stream, C_GEN_DATA(litdata.actions)) {
		TEMPORARY_TEXT(N)
		WRITE_TO(N, "i7_mgl_%SSub", an);
		CMemoryModel::array_entry(NULL, gen, N, WORD_ARRAY_FORMAT);
		DISCARD_TEXT(N)
	}
	CMemoryModel::end_array(NULL, gen, WORD_ARRAY_FORMAT);	
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
			internal_error("bad floating-point literal");
		}
		if (exposign) { expo = -expo; }
	}
	if (intcount + fraccount == 0) {
		WRITE_TO(STDERR, "Floating-point literal '%S' must have digits", textual);
		internal_error("bad floating-point literal");
	}
	uint32_t n = CLiteralsModel::construct_float(signbit, intv, fracv, expo);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("(i7val) 0x%08x", n);
}

@

=
int CLiteralsModel::hex_val(wchar_t c) {
	if ((c >= '0') && (c <= '9')) return c - '0';
	if ((c >= 'a') && (c <= 'f')) return c - 'a' + 10;
	if ((c >= 'A') && (c <= 'F')) return c - 'A' + 10;
	return -1;
}
void CLiteralsModel::compile_literal_text(code_generation_target *cgt, code_generation *gen,
	text_stream *S, int printing_mode, int box_mode, int escape_mode) {
	text_stream *OUT = CodeGen::current(gen);
	
	if (printing_mode == FALSE) {
		WRITE("(I7VAL_STRINGS_BASE + %d)", C_GEN_DATA(litdata.no_double_quoted_C_strings)++);
		OUT = C_GEN_DATA(litdata.double_quoted_C);
	}
	WRITE("\"");
	if (escape_mode == FALSE) {
		for (int i=0; i<Str::len(S); i++) {
			wchar_t c = Str::get_at(S, i);
			switch(c) {
				case '@': {
					if (Str::get_at(S, i+1) == '@') {
						int cc = 0; i++;
						while (Characters::isdigit(Str::get_at(S, ++i)))
							cc = 10*cc + (Str::get_at(S, i) - '0');
						if ((cc == '\n') || (cc == '\"') || (cc == '\\')) PUT('\\');
						PUT(cc);
						i--;
					} else if (Str::get_at(S, i+1) == '{') {
						int cc = 0; i++;
						while ((Str::get_at(S, ++i) != '}') && (Str::get_at(S, i) != 0))
							cc = 16*cc + CLiteralsModel::hex_val(Str::get_at(S, i));
						if ((cc == '\n') || (cc == '\"') || (cc == '\\')) PUT('\\');
						PUT(cc);
					} else WRITE("@");
					break;
				}
				case '~': case '"': WRITE("\\\""); break;
				case '\\': WRITE("\\\\"); break;
				case '\t': WRITE(" "); break;
				case '^': case '\n': WRITE("\\n"); break;
				case NEWLINE_IN_STRING: WRITE("\\n"); break;
				default: PUT(c); break;
			}
		}
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
		case PRINTDWORD_BIP:  WRITE("i7_print_C_string((char *) (i7mem + "); INV_A1; WRITE("))"); break;
		default:              return NOT_APPLICABLE;
	}
	return FALSE;
}
