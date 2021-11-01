[CLiteralsModel::] C Literals.

Text and dictionary words translated to C.

@h Introduction.
This section will be a long one because Inter needs a wide range of literal
values, and some are quite troublesome to deal with. We take the word "literal"
broadly rather than, well, literally: we include under this heading a variety
of ingredients of expressions which can legally be used as constants.

=
void CLiteralsModel::initialise(code_generator *cgt) {
	METHOD_ADD(cgt, COMPILE_DICTIONARY_WORD_MTID, CLiteralsModel::compile_dictionary_word);
	METHOD_ADD(cgt, COMPILE_LITERAL_NUMBER_MTID, CLiteralsModel::compile_literal_number);
	METHOD_ADD(cgt, COMPILE_LITERAL_REAL_MTID, CLiteralsModel::compile_literal_real);
	METHOD_ADD(cgt, COMPILE_LITERAL_TEXT_MTID, CLiteralsModel::compile_literal_text);
	METHOD_ADD(cgt, COMPILE_LITERAL_SYMBOL_MTID, CLiteralsModel::compile_literal_symbol);
	METHOD_ADD(cgt, NEW_ACTION_MTID, CLiteralsModel::new_action);
}

typedef struct C_generation_literals_model_data {
	int true_action_count;
	int fake_action_count;
	struct linked_list *actions; /* of |text_stream| */

	int text_count;
	struct linked_list *texts; /* of |text_stream| */

	int verb_count;
	struct linked_list *verbs; /* of |vanilla_dword| */
	struct linked_list *verb_grammar; /* of |text_stream| */
} C_generation_literals_model_data;

void CLiteralsModel::initialise_data(code_generation *gen) {
	C_GEN_DATA(litdata.text_count) = 0;
	C_GEN_DATA(litdata.texts) = NEW_LINKED_LIST(text_stream);
	C_GEN_DATA(litdata.verb_count) = 0;
	C_GEN_DATA(litdata.true_action_count) = 0;
	C_GEN_DATA(litdata.fake_action_count) = 0;
	C_GEN_DATA(litdata.verbs) = NEW_LINKED_LIST(vanilla_dword);
	C_GEN_DATA(litdata.actions) = NEW_LINKED_LIST(text_stream);
	C_GEN_DATA(litdata.verb_grammar) = NEW_LINKED_LIST(text_stream);
}

void CLiteralsModel::begin(code_generation *gen) {
	CLiteralsModel::initialise_data(gen);
	CLiteralsModel::begin_text(gen);
}

void CLiteralsModel::end(code_generation *gen) {
	CLiteralsModel::end_text(gen);
	VanillaConstants::compile_dictionary_table(gen);
	CLiteralsModel::compile_verb_table(gen);
	CLiteralsModel::compile_actions_table(gen);
}

@h Symbols.
The following function expresses that a named constant can be used as a value in C
just by naming it. That seems too obvious to need a function, but one can imagine
languages where it is not true.

=
void CLiteralsModel::compile_literal_symbol(code_generator *cgt, code_generation *gen,
	inter_symbol *aliased) {
	text_stream *OUT = CodeGen::current(gen);
	text_stream *S = Inter::Symbols::name(aliased);
	Generators::mangle(gen, OUT, S);
}

@h Integers.
This is simple for once. A generator is not obliged to take the |hex_mode| hint
and show the number in hex in the code it generates; functionally, decimal would
be just as good. But since we can easily do so, why not.

=
void CLiteralsModel::compile_literal_number(code_generator *cgt,
	code_generation *gen, inter_ti val, int hex_mode) {
	text_stream *OUT = CodeGen::current(gen);
	if (hex_mode) WRITE("0x%x", val);
	else WRITE("%d", val);
}

@h Real numbers.
This is not at all simple, but the helpful //VanillaConstants::textual_real_to_uint32//
does all the work for us.

=
void CLiteralsModel::compile_literal_real(code_generator *cgt,
	code_generation *gen, text_stream *textual) {
	uint32_t n = VanillaConstants::textual_real_to_uint32(textual);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("(i7word_t) 0x%08x", n);
}

@h Texts.
These are sometimes being used in |inv !print| or |inv !box|, in which case they
are never needed as values -- they're just printed. If that's the case, we
render directly as a double-quoted C text literal.

Otherwise, we are in |REGULAR_LTM| mode. In that case, a text must be represented
by a value which is "of the class String", meaning, a value in a range which
begins at the constant |I7VAL_STRINGS_BASE|; subject to that requirement, we
have freedom to do more or less what we like, but we will make the smallest
range of String values possible. Each text will have a unique ID number counting
upwards from |I7VAL_STRINGS_BASE|. The actual text this represents will be an
entry in the |i7_texts| array, which can be accessed using the
|i7_text_to_C_string| function.

(This is in contrast to the Inform 6 situation, where texts are represented by
addresses of compressed text in memory, so that the values are not consecutive
and the range they spread out over can be very large.)

= (text to inform7_clib.h)
char *i7_text_to_C_string(i7word_t str);
=

= (text to inform7_clib.c)
char *i7_texts[];
char *i7_text_to_C_string(i7word_t str) {
	return i7_texts[str - I7VAL_STRINGS_BASE];
}
=

The |i7_texts| array is written one entry at a time as we go along, and is
started here:

=
void CLiteralsModel::begin_text(code_generation *gen) {
}

void CLiteralsModel::compile_literal_text(code_generator *cgt, code_generation *gen,
	text_stream *S, int no_special_characters) {
	text_stream *OUT = CodeGen::current(gen);
	if (gen->literal_text_mode == REGULAR_LTM) {
		WRITE("(I7VAL_STRINGS_BASE + %d)", C_GEN_DATA(litdata.text_count)++);
		text_stream *OUT = Str::new();
		@<Compile the text@>;
		ADD_TO_LINKED_LIST(OUT, text_stream, C_GEN_DATA(litdata.texts));
	} else {
		@<Compile the text@>;
	}
}

@<Compile the text@> =
	WRITE("\"");
	if (no_special_characters) @<Print text almost raw@>
	else @<Print text expanding out at, caret and tilde@>;
	WRITE("\"");

@ Tabs become spaces, but there shouldn't be any tabs here anyway; |NEWLINE_IN_STRING|
characters become actual newlines, which is what they mean anyway. Otherwise, though,
this simply prints out the text in a form which a C compiler will accept between
double-quotes.

@<Print text almost raw@> =
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

@ All of that is true here too, but we also convert the traditional Inform 6
notations for |@dd...| or |@{hh...}| giving character literals in decimal or
hex, and |~| for a double-quote, and |^| for a newline.

@<Print text expanding out at, caret and tilde@> =
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

@ =
int CLiteralsModel::hex_val(wchar_t c) {
	if ((c >= '0') && (c <= '9')) return c - '0';
	if ((c >= 'a') && (c <= 'f')) return c - 'a' + 10;
	if ((c >= 'A') && (c <= 'F')) return c - 'A' + 10;
	return -1;
}

@ At the end of the run, when there can be no further texts, we must close
the |i7_texts| array:

=
void CLiteralsModel::end_text(code_generation *gen) {
	segmentation_pos saved = CodeGen::select(gen, c_quoted_text_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#define i7_mgl_Grammar__Version 2\n");
	WRITE("char *i7_texts[] = {\n");
	text_stream *T;
	LOOP_OVER_LINKED_LIST(T, text_stream, C_GEN_DATA(litdata.texts))
		WRITE("%S, ", T);
	WRITE("\"\" };\n");
	CodeGen::deselect(gen, saved);
}

int CLiteralsModel::size_of_String_area(code_generation *gen) {
	return C_GEN_DATA(litdata.text_count);
}

@h Action names.
These are used when processing changes to the model world in interactive fiction;
they do not exist in Basic Inform programs.

True actions count upwards from 0; fake actions independently count upwards
from 4096. These are defined just as constants, with mangled names:

=
void CLiteralsModel::new_action(code_generator *cgt, code_generation *gen,
	text_stream *name, int true_action) {
	int N;
	if (true_action) {
		N = C_GEN_DATA(litdata.true_action_count)++;
		CObjectModel::define_header_constant_for_action(gen, name, name, N);
		ADD_TO_LINKED_LIST(Str::duplicate(name), text_stream, C_GEN_DATA(litdata.actions));
	} else {
		N = 4096 + C_GEN_DATA(litdata.fake_action_count)++;
	}
	TEMPORARY_TEXT(O)
	TEMPORARY_TEXT(M)
	WRITE_TO(O, "##%S", name);
	CNamespace::mangle(cgt, M, O);

	segmentation_pos saved = CodeGen::select(gen, c_actions_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#define %S %d\n", M, N);
	CodeGen::deselect(gen, saved);

	DISCARD_TEXT(O)
	DISCARD_TEXT(M)
}

@ We also need to make a metadata table called the |#actions_table| which
gives, for each (true) action, a function to carry it out. The name of this
function is always given with a |Sub| suffix: this once stood for subroutine,
and shows just how far back into the history of Inform 1 this all goes.

(It is the absence of such a function which makes a fake action fake.)

=
void CLiteralsModel::compile_actions_table(code_generation *gen) {
	CMemoryModel::begin_array(NULL, gen, I"#actions_table", NULL, NULL,
		TABLE_ARRAY_FORMAT, NULL);
	text_stream *an;
	LOOP_OVER_LINKED_LIST(an, text_stream, C_GEN_DATA(litdata.actions)) {
		TEMPORARY_TEXT(O)
		WRITE_TO(O, "%SSub", an);
		TEMPORARY_TEXT(M)
		CNamespace::mangle(NULL, M, O);
		CMemoryModel::array_entry(NULL, gen, M, TABLE_ARRAY_FORMAT);
		DISCARD_TEXT(O)
		DISCARD_TEXT(M)
	}
	CMemoryModel::end_array(NULL, gen, TABLE_ARRAY_FORMAT, NULL);	
}

@h Dictionary words.
These are used when parsing command grammar in interactive fiction; they do not
exist in Basic Inform programs.

At runtime, dictionary words are addresses of small fixed-size arrays, and we
have very little flexibility about this because code in CommandParserKit makes
many assumptions about these arrays. So we will closely imitate what the Inform 6
compiler would automatically do.

In the array |DW|, the bytes |DW->1| to |DW->9| are the characters of the word,
with trailing nulls padding it out if the word is shorter than that. If it's
longer, then the text is truncated to 9 characters only. This means printing
out the text of a dictionary word is a somewhat faithless operation.[1] Still,
Inter provides a primitive to do that, and here is the implementation.

[1] It would get every word in this footnote right except for dictionary, which
would print as dictionar.

= (text to inform7_clib.h)
void i7_print_dword(i7process_t *proc, i7word_t at);
=

= (text to inform7_clib.c)
void i7_print_dword(i7process_t *proc, i7word_t at) {
	for (i7byte_t i=1; i<=9; i++) {
		i7byte_t c = i7_read_byte(proc, at+i);
		if (c == 0) break;
		i7_print_char(proc, c);
	}
}
=

@ We will use the convenient Vanilla mechanism for compiling dictionary words,
so there is very little to do:

=
void CLiteralsModel::compile_dictionary_word(code_generator *cgt, code_generation *gen,
	text_stream *S, int pluralise) {
	text_stream *OUT = CodeGen::current(gen);
	vanilla_dword *dw = VanillaConstants::text_to_dword(gen, S, pluralise);
	dw->nounlike = TRUE;
	CNamespace::mangle(cgt, OUT, dw->identifier);
}

void CLiteralsModel::verb_grammar(code_generator *cgt, code_generation *gen,
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
				vanilla_dword *dw = VanillaConstants::text_to_dword(gen, glob_text, FALSE);
				dw->verb_number = verbnum; dw->verblike = TRUE;
				if (Inter::Symbols::read_annotation(array_s, METAVERB_IANN) == 1) dw->meta = TRUE;
				synonyms++;
				if (synonyms == 1) {
					ADD_TO_LINKED_LIST(dw, vanilla_dword, C_GEN_DATA(litdata.verbs));
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
			int lookahead = 0, slash_before = FALSE, slash_after = FALSE;
			if (i > DATA_CONST_IFLD) {
				inter_ti val1 = P->W.data[i-2], val2 = P->W.data[i-1];
				if (Inter::Symbols::is_stored_in_data(val1, val2)) {
					inter_symbol *aliased = InterSymbolsTables::symbol_from_data_pair_and_table(val1, val2, Inter::Packages::scope_of(P));
					if (aliased == NULL) internal_error("bad aliased symbol");
					if (Str::eq(aliased->symbol_name, I"VERB_DIRECTIVE_SLASH")) {
						slash_before = TRUE;
					}
				}
			}
			if (i+2 < P->W.extent) {
				inter_ti val1 = P->W.data[i+2], val2 = P->W.data[i+3];
				if (Inter::Symbols::is_stored_in_data(val1, val2)) {
					inter_symbol *aliased = InterSymbolsTables::symbol_from_data_pair_and_table(val1, val2, Inter::Packages::scope_of(P));
					if (aliased == NULL) internal_error("bad aliased symbol");
					if (Str::eq(aliased->symbol_name, I"VERB_DIRECTIVE_SLASH")) {
						slash_after = TRUE;
					}
				}
			}
			if (slash_before) lookahead += 0x10;
			if (slash_after) lookahead += 0x20;
				
			if (Inter::Symbols::is_stored_in_data(val1, val2)) {
				inter_symbol *aliased = InterSymbolsTables::symbol_from_data_pair_and_table(val1, val2, Inter::Packages::scope_of(P));
				if (aliased == NULL) internal_error("bad aliased symbol");
				if (Str::eq(aliased->symbol_name, I"VERB_DIRECTIVE_SLASH")) continue;
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

				if (Str::eq(aliased->symbol_name, I"VERB_DIRECTIVE_NOUN")) {
					CLiteralsModel::grammar_byte(gen, 1 + lookahead);
					CLiteralsModel::grammar_word(gen, 0);
					continue;
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
				CNamespace::mangle(cgt, MG, Inter::Symbols::name(aliased));
				CLiteralsModel::grammar_word_textual(gen, MG);
				DISCARD_TEXT(MG)
				continue;
			}
			if (val1 == DWORD_IVAL) {
				text_stream *glob_text = Inter::Warehouse::get_text(InterTree::warehouse(I), val2);
				vanilla_dword *dw = VanillaConstants::text_to_dword(gen, glob_text, FALSE);
				dw->preplike = TRUE;
				CLiteralsModel::grammar_byte(gen, 0x42 + lookahead);
				TEMPORARY_TEXT(MG)
				CNamespace::mangle(cgt, MG, dw->identifier);
				CLiteralsModel::grammar_word_textual(gen, MG);
				DISCARD_TEXT(MG)
				continue;
			}
			if (val1 == PDWORD_IVAL) {
				text_stream *glob_text = Inter::Warehouse::get_text(InterTree::warehouse(I), val2);
				vanilla_dword *dw = VanillaConstants::text_to_dword(gen, glob_text, TRUE);
				dw->preplike = TRUE;
				CLiteralsModel::grammar_byte(gen, 0x42 + lookahead);
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
	CMemoryModel::begin_array(NULL, gen, I"#grammar_table", NULL, NULL, WORD_ARRAY_FORMAT, NULL);
	TEMPORARY_TEXT(N)
	WRITE_TO(N, "%d", C_GEN_DATA(litdata.verb_count) - 1);
	CMemoryModel::array_entry(NULL, gen, N, WORD_ARRAY_FORMAT);
	DISCARD_TEXT(N)
	vanilla_dword *dw; int c = 1;
	LOOP_OVER_LINKED_LIST(dw, vanilla_dword, C_GEN_DATA(litdata.verbs)) {
		TEMPORARY_TEXT(N)
		WRITE_TO(N, "(i7_ss_grammar_table_cont+%d /* %d: %S */ )", dw->grammar_table_offset, c++, dw->text);
		CMemoryModel::array_entry(NULL, gen, N, WORD_ARRAY_FORMAT);
		DISCARD_TEXT(N)
	}
	CMemoryModel::end_array(NULL, gen, WORD_ARRAY_FORMAT, NULL);
	CMemoryModel::begin_array(NULL, gen, I"#grammar_table_cont", NULL, NULL, BYTE_ARRAY_FORMAT, NULL);
	text_stream *entry;
	LOOP_OVER_LINKED_LIST(entry, text_stream, C_GEN_DATA(litdata.verb_grammar)) {
		CMemoryModel::array_entry(NULL, gen, entry, BYTE_ARRAY_FORMAT);
	}
	CMemoryModel::end_array(NULL, gen, BYTE_ARRAY_FORMAT, NULL);
}
