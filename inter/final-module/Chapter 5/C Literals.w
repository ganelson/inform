[CLiteralsModel::] C Literals.

Text and dictionary words translated to C.

@h Introduction.
We take the word "literal" broadly rather than, well, literally: we include
under this heading a variety of ingredients of expressions which can legally be
used as constants.

=
void CLiteralsModel::initialise(code_generator *gtr) {
	METHOD_ADD(gtr, COMPILE_DICTIONARY_WORD_MTID, CLiteralsModel::compile_dictionary_word);
	METHOD_ADD(gtr, COMPILE_LITERAL_NUMBER_MTID, CLiteralsModel::compile_literal_number);
	METHOD_ADD(gtr, COMPILE_LITERAL_REAL_MTID, CLiteralsModel::compile_literal_real);
	METHOD_ADD(gtr, COMPILE_LITERAL_TEXT_MTID, CLiteralsModel::compile_literal_text);
	METHOD_ADD(gtr, COMPILE_LITERAL_SYMBOL_MTID, CLiteralsModel::compile_literal_symbol);
	METHOD_ADD(gtr, NEW_ACTION_MTID, CLiteralsModel::new_action);
}

typedef struct C_generation_literals_model_data {
	int text_count;
	struct linked_list *texts; /* of |text_stream| */
} C_generation_literals_model_data;

void CLiteralsModel::initialise_data(code_generation *gen) {
	C_GEN_DATA(litdata.text_count) = 0;
	C_GEN_DATA(litdata.texts) = NEW_LINKED_LIST(text_stream);
}

void CLiteralsModel::begin(code_generation *gen) {
	CLiteralsModel::initialise_data(gen);
	CLiteralsModel::begin_text(gen);
}

void CLiteralsModel::end(code_generation *gen) {
	CLiteralsModel::end_text(gen);
}

@h Symbols.
The following function expresses that a named constant can be used as a value in C
just by naming it. That seems too obvious to need a function, but one can imagine
languages where it is not true.

=
void CLiteralsModel::compile_literal_symbol(code_generator *gtr, code_generation *gen,
	inter_symbol *aliased) {
	text_stream *OUT = CodeGen::current(gen);
	text_stream *S = InterSymbol::trans(aliased);
	Generators::mangle(gen, OUT, S);
}

@h Integers.
This is simple for once. A generator is not obliged to take the |hex_mode| hint
and show the number in hex in the code it generates; functionally, decimal would
be just as good. But since we can easily do so, why not.

=
void CLiteralsModel::compile_literal_number(code_generator *gtr,
	code_generation *gen, inter_ti val, int hex_mode) {
	text_stream *OUT = CodeGen::current(gen);
	if (hex_mode) WRITE("0x%x", val);
	else WRITE("%d", val);
}

@h Real numbers.
This is not at all simple, but the helpful //VanillaConstants::textual_real_to_uint32//
does all the work for us.

=
void CLiteralsModel::compile_literal_real(code_generator *gtr,
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

void CLiteralsModel::compile_literal_text(code_generator *gtr, code_generation *gen,
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
void CLiteralsModel::new_action(code_generator *gtr, code_generation *gen,
	text_stream *name, int true_action, int N) {
	if (true_action) {
		segmentation_pos saved = CodeGen::select(gen, c_actions_symbols_I7CGS);
		text_stream *OUT = CodeGen::current(gen);
		WRITE("#define %S %d\n", CTarget::symbols_header_identifier(gen, I"A", name), N);
		CodeGen::deselect(gen, saved);
	}
	TEMPORARY_TEXT(O)
	TEMPORARY_TEXT(M)
	WRITE_TO(O, "##%S", name);
	CNamespace::mangle(gtr, M, O);

	segmentation_pos saved = CodeGen::select(gen, c_actions_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#define %S %d\n", M, N);
	CodeGen::deselect(gen, saved);

	DISCARD_TEXT(O)
	DISCARD_TEXT(M)
}

@h Dictionary words.
These are used when parsing command grammar in interactive fiction; they do not
exist in Basic Inform programs.

At runtime, dictionary words are addresses of small fixed-size arrays, and we
have very little flexibility about this because code in CommandParserKit makes
many assumptions about these arrays. So we will closely imitate what the Inform 6
compiler would automatically do.

In the array |DW|, the words |DW->1| to |DW->9| are the characters of the word,
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
	for (i7byte_t i=1; i<=i7_mgl_DICT_WORD_SIZE; i++) {
		i7word_t c = i7_read_word(proc, at, i);
		if (c == 0) break;
		i7_print_char(proc, c);
	}
}
=

@ We will use the convenient Vanilla mechanism for compiling dictionary words,
so there is very little to do:

=
void CLiteralsModel::compile_dictionary_word(code_generator *gtr, code_generation *gen,
	text_stream *S, int pluralise) {
	text_stream *OUT = CodeGen::current(gen);
	vanilla_dword *dw = VanillaIF::text_to_noun_dword(gen, S, pluralise);
	CNamespace::mangle(gtr, OUT, dw->identifier);
}
