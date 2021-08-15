[CLiteralsModel::] C Literals.

Text and dictionary words translated to C.

@h Setting up the model.

=
void CLiteralsModel::initialise(code_generation_target *cgt) {
	METHOD_ADD(cgt, COMPILE_DICTIONARY_WORD_MTID, CLiteralsModel::compile_dictionary_word);
	METHOD_ADD(cgt, COMPILE_LITERAL_NUMBER_MTID, CLiteralsModel::compile_literal_number);
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
