[CodeGen::] Code Generation.

To generate final code from intermediate code.

@h Pipeline stage.

=
void CodeGen::create_pipeline_stage(void) {
	CodeGen::Stage::new(I"generate", CodeGen::run_pipeline_stage, TEXT_OUT_STAGE_ARG);
}

int CodeGen::run_pipeline_stage(pipeline_step *step) {
	if (step->target_argument == NULL) internal_error("no target specified");

	if (step->target_argument == binary_inter_cgt)
		Inter::Binary::write(step->parsed_filename, step->repository);
	else if (step->target_argument == textual_inter_cgt)
		Inter::Textual::write(step->text_out_file, step->repository, NULL, 1);
	else if (step->target_argument == summary_cgt)
		Inter::Summary::write(step->text_out_file, step->repository);
	else {
		code_generation *gen = CodeGen::new_generation(step->repository, step->target_argument);
		CodeGen::Targets::begin_generation(gen);
		CodeGen::generate(gen);
		CodeGen::write(step->text_out_file, gen);
	}
	return TRUE;
}

@h Generations.
A "generation" is a single act of translating inter code into final code.
That final code will be a text file written in some other programming
language, though probably a low-level one.

The "target" of a generation is the final language: for example, Inform 6.

During a generation, textual output is assembled as a set of "segments".
Different targets may need different segments. This is all to facilitate
rearranging content as necessary to get it to compile in the target language:
for example, one might need to have all constants defined first, then all
arrays, and one could do this by creating two segments, one to accumulate
the constants in, one to accumulate the arrays.

@d MAX_CG_SEGMENTS 100
@d TEMP_CG_SEGMENT 99

=
typedef struct code_generation {
	struct inter_repository *from;
	struct code_generation_target *target;
	struct generated_segment *segments[MAX_CG_SEGMENTS];
	struct generated_segment *current_segment;
	int temporarily_diverted;
	MEMORY_MANAGEMENT
} code_generation;

typedef struct generated_segment {
	struct text_stream *generated_code;
	MEMORY_MANAGEMENT
} generated_segment;

code_generation *CodeGen::new_generation(inter_repository *I, code_generation_target *target) {
	code_generation *gen = CREATE(code_generation);
	gen->from = I;
	gen->target = target;
	gen->current_segment = NULL;
	gen->temporarily_diverted = FALSE;
	for (int i=0; i<MAX_CG_SEGMENTS; i++) gen->segments[i] = NULL;
	return gen;
}

generated_segment *CodeGen::new_segment(void) {
	generated_segment *seg = CREATE(generated_segment);
	seg->generated_code = Str::new();
	return seg;
}

@

=
generated_segment *CodeGen::select(code_generation *gen, int i) {
	generated_segment *saved = gen->current_segment;
	if ((i < 0) || (i >= MAX_CG_SEGMENTS)) internal_error("out of range");
	if (gen->temporarily_diverted) internal_error("poorly timed selection");
	gen->current_segment = gen->segments[i];
	return saved;
}

void CodeGen::select_temporary(code_generation *gen, text_stream *T) {
	if (gen->segments[TEMP_CG_SEGMENT] == NULL) {
		gen->segments[TEMP_CG_SEGMENT] = CodeGen::new_segment();
		gen->segments[TEMP_CG_SEGMENT]->generated_code = NULL;
	}
	if (gen->temporarily_diverted)
		internal_error("nested temporary cgs");
	gen->temporarily_diverted = TRUE;
	gen->segments[TEMP_CG_SEGMENT]->generated_code = T;
}

void CodeGen::deselect(code_generation *gen, generated_segment *saved) {
	if (gen->temporarily_diverted) internal_error("poorly timed deselection");
	gen->current_segment = saved;
}

void CodeGen::deselect_temporary(code_generation *gen) {
	gen->temporarily_diverted = FALSE;
}

text_stream *CodeGen::current(code_generation *gen) {
	if (gen->temporarily_diverted) return gen->segments[TEMP_CG_SEGMENT]->generated_code;
	if (gen->current_segment == NULL) return NULL;
	return gen->current_segment->generated_code;
}

void CodeGen::write(OUTPUT_STREAM, code_generation *gen) {
	for (int i=0; i<MAX_CG_SEGMENTS; i++)
		if ((gen->segments[i]) && (i != TEMP_CG_SEGMENT))
			WRITE("%S", gen->segments[i]->generated_code);
}

typedef struct text_literal_holder {
	struct text_stream *definition_code;
	struct text_stream *literal_content;
	MEMORY_MANAGEMENT
} text_literal_holder;

#ifdef CORE_MODULE
int the_quartet_found = TRUE;
#endif
#ifndef CORE_MODULE
int the_quartet_found = FALSE;
#endif

void CodeGen::generate(code_generation *gen) {
	inter_repository *I = gen->from;

	if (I == NULL) internal_error("no inter to generate from");

	CodeGen::Var::set_translates(I);

	LOG("Generating to %S\n", gen->target->target_name);

	Inter::Symbols::clear_transient_flags();


	int properties_written = FALSE;
	int variables_written = FALSE;

		inter_frame P;
		LOOP_THROUGH_FRAMES(P, I) {
			inter_package *outer = Inter::Packages::container(P);
			if ((outer == NULL) || (outer->codelike_package == FALSE)) {
				generated_segment *saved = CodeGen::select(gen, CodeGen::Targets::general_segment(gen, P));
				switch (P.data[ID_IFLD]) {
					case CONSTANT_IST: {
						inter_symbol *con_name =
							Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_CONST_IFLD);
						if ((outer) && (CodeGen::Eliminate::gone(outer->package_name)) && (Inter::Constant::code_block(con_name) == NULL)) {
							LOG("Yeah, so reject $3\n", outer->package_name);
							continue;
						}
						if (Inter::Symbols::read_annotation(con_name, OBJECT_IANN) == 1) break;
						if (Inter::Packages::container(P) == Inter::Packages::main(I)) {
							WRITE_TO(STDERR, "Bad constant: %S\n", con_name->symbol_name);
							internal_error("constant defined in main");
						}
						if (Inter::Symbols::read_annotation(con_name, TEXT_LITERAL_IANN) == 1) {
							text_literal_holder *tlh = CREATE(text_literal_holder);
							tlh->definition_code = Str::new();
							inter_t ID = P.data[DATA_CONST_IFLD];
							tlh->literal_content = Inter::get_text(P.repo_segment->owning_repo, ID);
							CodeGen::select_temporary(gen, tlh->definition_code);
							CodeGen::frame(gen, P);
							CodeGen::deselect_temporary(gen);
						} else {
							CodeGen::frame(gen, P);
						}
						break;
					}
					case PRAGMA_IST:
						CodeGen::frame(gen, P);
						break;
					case INSTANCE_IST:
						CodeGen::frame(gen, P);
						break;
					case SPLAT_IST:
						internal_error("top-level splat remaining");
						break;
					case PROPERTYVALUE_IST:
						@<Property knowledge@>;
						break;
					case VARIABLE_IST:
						if ((outer) && (CodeGen::Eliminate::gone(outer->package_name))) {
							LOG("Yeah, so reject $3\n", outer->package_name);
							continue;
						}
						if (variables_written == FALSE) {
							variables_written = TRUE;
							CodeGen::Var::knowledge(gen);
						}
						break;
				}
				CodeGen::deselect(gen, saved);
			}
		}

	int NR = 0;
	@<Define constants for the responses@>;
	if (NR > 0) @<Define an array of the responses@>;

	if (properties_written == FALSE) @<Property knowledge@>;

	int no_tlh = NUMBER_CREATED(text_literal_holder);
	text_literal_holder **sorted = (text_literal_holder **)
			(Memory::I7_calloc(no_tlh, sizeof(text_literal_holder *), CODE_GENERATION_MREASON));
	int i = 0;
	text_literal_holder *tlh;
	LOOP_OVER(tlh, text_literal_holder) sorted[i++] = tlh;

	qsort(sorted, (size_t) no_tlh, sizeof(text_literal_holder *), CodeGen::compare_tlh);
	for (int i=0; i<no_tlh; i++) {
		text_literal_holder *tlh = sorted[i];
		generated_segment *saved = CodeGen::select(gen, CodeGen::Targets::tl_segment(gen));
		text_stream *TO = CodeGen::current(gen);
		WRITE_TO(TO, "%S", tlh->definition_code);
		CodeGen::deselect(gen, saved);
	}
	
}

@<Define constants for the responses@> =
	inter_frame P;
	LOOP_THROUGH_FRAMES(P, I) {
		if (P.data[ID_IFLD] == RESPONSE_IST) {
			generated_segment *saved = CodeGen::select(gen, CodeGen::Targets::general_segment(gen, P));
			text_stream *TO = CodeGen::current(gen);
			inter_symbol *resp_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_RESPONSE_IFLD);
			WRITE_TO(TO, "Constant %S = %d;\n", CodeGen::name(resp_name), ++NR);
			CodeGen::deselect(gen, saved);
		}
	}

@<Define an array of the responses@> =
	generated_segment *saved = CodeGen::select(gen, CodeGen::Targets::constant_segment(gen));
	WRITE_TO(CodeGen::current(gen), "Constant NO_RESPONSES = %d;\n", NR);
	CodeGen::deselect(gen, saved);
	saved = CodeGen::select(gen, CodeGen::Targets::default_segment(gen));
	WRITE_TO(CodeGen::current(gen), "Array ResponseTexts --> ");
		inter_frame P;
		LOOP_THROUGH_FRAMES(P, I) {
			if (P.data[ID_IFLD] == RESPONSE_IST) {
				NR++;
				CodeGen::literal(gen, NULL, Inter::Packages::scope_of(P), P.data[VAL1_RESPONSE_IFLD], P.data[VAL1_RESPONSE_IFLD+1], FALSE);
				WRITE_TO(CodeGen::current(gen), " ");
			}
		}
	WRITE_TO(CodeGen::current(gen), "0 0;\n");
	CodeGen::deselect(gen, saved);

@<Property knowledge@> =
	if (properties_written == FALSE) {
		generated_segment *saved = CodeGen::select(gen, CodeGen::Targets::default_segment(gen));
		text_stream *TO = CodeGen::current(gen);
		if (the_quartet_found) {
			WRITE_TO(TO, "Object Compass \"compass\" has concealed;\n");
			WRITE_TO(TO, "Object thedark \"(darkness object)\";\n");
			WRITE_TO(TO, "Object InformParser \"(Inform Parser)\" has proper;\n");
			WRITE_TO(TO, "Object InformLibrary \"(Inform Library)\" has proper;\n");
		}
		properties_written = TRUE;
		CodeGen::IP::knowledge(gen);
		CodeGen::deselect(gen, saved);				
	}

@ =
int query_labels_mode = FALSE, negate_label_mode = FALSE;
void CodeGen::frame(code_generation *gen, inter_frame P) {
	switch (P.data[ID_IFLD]) {
		case SYMBOL_IST: break;
		case CONSTANT_IST: CodeGen::constant(gen, P); break;
		case INSTANCE_IST: CodeGen::IP::instance(gen, P); break;
		case SPLAT_IST: CodeGen::splat(gen, P); break;
		case LOCAL_IST: CodeGen::local(gen, P); break;
		case LABEL_IST: CodeGen::label(gen, P); break;
		case CODE_IST: CodeGen::code(gen, P); break;
		case EVALUATION_IST: CodeGen::evaluation(gen, P); break;
		case REFERENCE_IST: CodeGen::reference(gen, P); break;
		case PACKAGE_IST: CodeGen::block(gen, P); break;
		case INV_IST: CodeGen::inv(gen, P); break;
		case CAST_IST: CodeGen::cast(gen, P); break;
		case VAL_IST:
		case REF_IST: CodeGen::val(gen, P); break;
		case LAB_IST: CodeGen::lab(gen, P); break;
		case PRAGMA_IST: CodeGen::pragma(gen, P); break;
		case NOP_IST: break;
		default:
			Inter::Defn::write_construct_text(DL, P);
			internal_error("unimplemented\n");
	}
}

@

There's a contrivance here to get around an awkward point of I6 syntax:
an array written in the form

	|Array X table 20;|

makes a table with 20 entries, not a table with one entry whose initial value
is 20. We instead compile this as

	|Array X --> 1 20;|

=

int void_level = 3;

void CodeGen::constant(code_generation *gen, inter_frame P) {
	text_stream *OUT = CodeGen::current(gen);
	inter_symbol *con_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_CONST_IFLD);

	if (Inter::Symbols::read_annotation(con_name, INLINE_ARRAY_IANN) == 1) return;
	if (Inter::Symbols::read_annotation(con_name, ACTION_IANN) == 1) return;

	if (Inter::Symbols::read_annotation(con_name, FAKE_ACTION_IANN) == 1) {
		text_stream *fa = Str::duplicate(con_name->symbol_name);
		Str::delete_first_character(fa);
		Str::delete_first_character(fa);
		WRITE("Fake_Action %S;\n", fa);
		return;
	}

	int ifndef_me = FALSE;
	if (Inter::Symbols::read_annotation(con_name, VENEER_IANN) == 1) return;
	if ((Str::eq(con_name->symbol_name, I"WORDSIZE")) ||
		(Str::eq(con_name->symbol_name, I"TARGET_ZCODE")) ||
		(Str::eq(con_name->symbol_name, I"INDIV_PROP_START")) ||
		(Str::eq(con_name->symbol_name, I"TARGET_GLULX")) ||
		(Str::eq(con_name->symbol_name, I"DICT_WORD_SIZE")) ||
		(Str::eq(con_name->symbol_name, I"DEBUG")))
		ifndef_me = TRUE;

	if (Str::eq(con_name->symbol_name, I"thedark")) {
		the_quartet_found = TRUE;
//		WRITE("Object thedark \"(darkness object)\";\n");
		return;
	}
	if (Str::eq(con_name->symbol_name, I"InformLibrary")) {
		the_quartet_found = TRUE;
//		WRITE("Object InformLibrary \"(Inform Library)\" has proper;\n");
		return;
	}
	if (Str::eq(con_name->symbol_name, I"InformParser")) {
		the_quartet_found = TRUE;
//		WRITE("Object InformParser \"(Inform Parser)\" has proper;\n");
		return;
	}
	if (Str::eq(con_name->symbol_name, I"Compass")) {
		the_quartet_found = TRUE;
//		WRITE("Object Compass \"compass\" has concealed;\n");
		return;
	}
	
	if (Str::eq(con_name->symbol_name, I"Release")) {
		inter_t val1 = P.data[DATA_CONST_IFLD];
		inter_t val2 = P.data[DATA_CONST_IFLD + 1];
		WRITE("Release ");
		CodeGen::literal(gen, NULL, Inter::Packages::scope_of(P), val1, val2, FALSE);
		WRITE(";\n");
		return;
	}

	if (Str::eq(con_name->symbol_name, I"Story")) {
		inter_t val1 = P.data[DATA_CONST_IFLD];
		inter_t val2 = P.data[DATA_CONST_IFLD + 1];
		WRITE("Global Story = ");
		CodeGen::literal(gen, NULL, Inter::Packages::scope_of(P), val1, val2, FALSE);
		WRITE(";\n");
		return;
	}

	if (Str::eq(con_name->symbol_name, I"Serial")) {
		inter_t val1 = P.data[DATA_CONST_IFLD];
		inter_t val2 = P.data[DATA_CONST_IFLD + 1];
		WRITE("Serial ");
		CodeGen::literal(gen, NULL, Inter::Packages::scope_of(P), val1, val2, FALSE);
		WRITE(";\n");
		return;
	}

	if (Str::eq(con_name->symbol_name, I"UUID_ARRAY")) {
		inter_t ID = P.data[DATA_CONST_IFLD];
		text_stream *S = Inter::get_text(P.repo_segment->owning_repo, ID);
		WRITE("Array UUID_ARRAY string \"UUID://");
		for (int i=0, L=Str::len(S); i<L; i++) WRITE("%c", Characters::toupper(Str::get_at(S, i)));
		WRITE("//\";\n");
		return;
	}

	if (Inter::Constant::is_routine(con_name)) {
		inter_symbol *code_block = Inter::Constant::code_block(con_name);
		if (CodeGen::Eliminate::gone(code_block) == FALSE) {
			WRITE("[ %S", CodeGen::name(con_name));
			void_level = Inter::Defn::get_level(P) + 2;
			inter_frame D = Inter::Symbols::defining_frame(code_block);
			CodeGen::frame(gen, D);
		}
		return;
	}
	switch (P.data[FORMAT_CONST_IFLD]) {
		case CONSTANT_INDIRECT_TEXT: {
			inter_t ID = P.data[DATA_CONST_IFLD];
			text_stream *S = Inter::get_text(P.repo_segment->owning_repo, ID);
			WRITE("Constant %S = \"%S\";\n", CodeGen::name(con_name), S);
			break;
		}
		case CONSTANT_INDIRECT_LIST: {
			char *format = "-->";
			int do_not_bracket = FALSE, unsub = FALSE;
			int X = (P.extent - DATA_CONST_IFLD)/2;
			if (X == 1) do_not_bracket = TRUE;
			if (Inter::Symbols::read_annotation(con_name, BYTEARRAY_IANN) == 1) format = "->";
			if (Inter::Symbols::read_annotation(con_name, TABLEARRAY_IANN) == 1) {
				format = "table";
				if (P.extent - DATA_CONST_IFLD == 2) format = "--> 1";
			}
			if (Inter::Symbols::read_annotation(con_name, BUFFERARRAY_IANN) == 1) format = "buffer";
			if (Inter::Symbols::read_annotation(con_name, STRINGARRAY_IANN) == 1) { format = "string"; do_not_bracket = TRUE; }
			if (Inter::Symbols::read_annotation(con_name, VERBARRAY_IANN) == 1) {
				WRITE("Verb "); do_not_bracket = TRUE; unsub = TRUE;
				if (Inter::Symbols::read_annotation(con_name, METAVERB_IANN) == 1) WRITE("meta ");
			} else {
				WRITE("Array %S %s", CodeGen::name(con_name), format);
			}
			for (int i=DATA_CONST_IFLD; i<P.extent; i=i+2) {
				WRITE(" ");
				if ((do_not_bracket == FALSE) && (P.data[i] != DIVIDER_IVAL)) WRITE("(");
				CodeGen::literal(gen, con_name, Inter::Packages::scope_of(P), P.data[i], P.data[i+1], unsub);
				if ((do_not_bracket == FALSE) && (P.data[i] != DIVIDER_IVAL)) WRITE(")");
			}
			WRITE(";\n");
			break;
		}
		case CONSTANT_SUM_LIST:
		case CONSTANT_PRODUCT_LIST:
		case CONSTANT_DIFFERENCE_LIST:
		case CONSTANT_QUOTIENT_LIST:
			WRITE("Constant %S = ", CodeGen::name(con_name));
			for (int i=DATA_CONST_IFLD; i<P.extent; i=i+2) {
				if (i>DATA_CONST_IFLD) {
					if (P.data[FORMAT_CONST_IFLD] == CONSTANT_SUM_LIST) WRITE(" + ");
					if (P.data[FORMAT_CONST_IFLD] == CONSTANT_PRODUCT_LIST) WRITE(" * ");
					if (P.data[FORMAT_CONST_IFLD] == CONSTANT_DIFFERENCE_LIST) WRITE(" - ");
					if (P.data[FORMAT_CONST_IFLD] == CONSTANT_QUOTIENT_LIST) WRITE(" / ");
				}
				int bracket = TRUE;
				if ((P.data[i] == LITERAL_IVAL) || (Inter::Symbols::is_stored_in_data(P.data[i], P.data[i+1]))) bracket = FALSE;
				if (bracket) WRITE("(");
				CodeGen::literal(gen, con_name, Inter::Packages::scope_of(P), P.data[i], P.data[i+1], FALSE);
				if (bracket) WRITE(")");
			}
			WRITE(";\n");
			break;
		case CONSTANT_DIRECT: {
			inter_t val1 = P.data[DATA_CONST_IFLD];
			inter_t val2 = P.data[DATA_CONST_IFLD + 1];
			if (ifndef_me) WRITE("#ifndef %S; ", CodeGen::name(con_name));
			WRITE("Constant %S = ", CodeGen::name(con_name));
			CodeGen::literal(gen, con_name, Inter::Packages::scope_of(P), val1, val2, FALSE);
			WRITE(";");
			if (ifndef_me) WRITE(" #endif;");
			WRITE("\n");
			break;
		}
		default: internal_error("ungenerated constant format");
	}
}

int box_mode = FALSE, printing_mode = FALSE;

void CodeGen::enter_box_mode(void) {
	box_mode = TRUE;
}

void CodeGen::exit_box_mode(void) {
	box_mode = FALSE;
}

void CodeGen::enter_print_mode(void) {
	printing_mode = TRUE;
}

void CodeGen::exit_print_mode(void) {
	printing_mode = FALSE;
}

void CodeGen::literal(code_generation *gen, inter_symbol *con_name, inter_symbols_table *T, inter_t val1, inter_t val2, int unsub) {
	inter_repository *I = gen->from;
	text_stream *OUT = CodeGen::current(gen);
	if (val1 == LITERAL_IVAL) {
		int hex = FALSE;
		if (con_name)
			for (int i=0; i<con_name->no_symbol_annotations; i++)
				if (con_name->symbol_annotations[i].annot->annotation_ID == HEX_IANN)
					hex = TRUE;
		if (hex) WRITE("$%x", val2);
		else WRITE("%d", val2);
	} else if (Inter::Symbols::is_stored_in_data(val1, val2)) {
		inter_symbol *aliased = Inter::SymbolsTables::symbol_from_data_pair_and_table(val1, val2, T);
		if (aliased == NULL) internal_error("bad aliased symbol");
		if (aliased == verb_directive_divider_symbol) WRITE("\n\t*");
		else if (aliased == verb_directive_reverse_symbol) WRITE("reverse");
		else if (aliased == verb_directive_slash_symbol) WRITE("/");
		else if (aliased == verb_directive_result_symbol) WRITE("->");
		else if (aliased == verb_directive_special_symbol) WRITE("special");
		else if (aliased == verb_directive_number_symbol) WRITE("number");
		else if (aliased == verb_directive_noun_symbol) WRITE("noun");
		else if (aliased == verb_directive_multi_symbol) WRITE("multi");
		else if (aliased == verb_directive_multiinside_symbol) WRITE("multiinside");
		else if (aliased == verb_directive_multiheld_symbol) WRITE("multiheld");
		else if (aliased == verb_directive_held_symbol) WRITE("held");
		else if (aliased == verb_directive_creature_symbol) WRITE("creature");
		else if (aliased == verb_directive_topic_symbol) WRITE("topic");
		else if (aliased == verb_directive_multiexcept_symbol) WRITE("multiexcept");
		else {
			if ((unsub) && (Inter::Symbols::read_annotation(aliased, SCOPE_FILTER_IANN) == 1))
				WRITE("scope=");
			if ((unsub) && (Inter::Symbols::read_annotation(aliased, NOUN_FILTER_IANN) == 1))
				WRITE("noun=");
			text_stream *S = CodeGen::name(aliased);
			if ((unsub) && (Str::begins_with_wide_string(S, L"##"))) {
				LOOP_THROUGH_TEXT(pos, S)
					if (pos.index >= 2)
						PUT(Str::get(pos));
			} else {
				WRITE("%S", S);
			}
		}
	} else if (val1 == DIVIDER_IVAL) {
		text_stream *divider_text = Inter::get_text(I, val2);
		WRITE(" ! %S\n\t", divider_text);
	} else if (val1 == REAL_IVAL) {
		text_stream *glob_text = Inter::get_text(I, val2);
		WRITE("$%S", glob_text);
	} else if (val1 == DWORD_IVAL) {
		text_stream *glob_text = Inter::get_text(I, val2);
		CodeGen::compile_to_I6_dictionary(OUT, glob_text, FALSE);
	} else if (val1 == PDWORD_IVAL) {
		text_stream *glob_text = Inter::get_text(I, val2);
		CodeGen::compile_to_I6_dictionary(OUT, glob_text, TRUE);
	} else if (val1 == LITERAL_TEXT_IVAL) {
		text_stream *glob_text = Inter::get_text(I, val2);
		CodeGen::Targets::compile_literal_text(gen, glob_text, printing_mode, box_mode);
	} else if (val1 == GLOB_IVAL) {
		text_stream *glob_text = Inter::get_text(I, val2);
		WRITE("%S", glob_text);
	} else internal_error("unimplemented direct constant");
}

void CodeGen::pragma(code_generation *gen, inter_frame P) {
	inter_symbol *target_symbol = Inter::SymbolsTables::symbol_from_frame_data(P, TARGET_PRAGMA_IFLD);
	if (target_symbol == NULL) internal_error("bad pragma");
	if (Str::eq(target_symbol->symbol_name, I"target_I6")) {
		inter_t ID = P.data[TEXT_PRAGMA_IFLD];
		text_stream *S = Inter::get_text(P.repo_segment->owning_repo, ID);
		text_stream *OUT = CodeGen::current(gen);
		WRITE("!%% %S\n", S);
	}
}

@

@d URL_SYMBOL_CHAR 0x00A7

=
void CodeGen::splat(code_generation *gen, inter_frame P) {
	text_stream *OUT = CodeGen::current(gen);
	inter_repository *I = gen->from;
	text_stream *S = Inter::get_text(I, P.data[MATTER_SPLAT_IFLD]);
	int L = Str::len(S);
	for (int i=0; i<L; i++) {
		wchar_t c = Str::get_at(S, i);
		if (c == URL_SYMBOL_CHAR) {
			TEMPORARY_TEXT(T);
			for (i++; i<L; i++) {
				wchar_t c = Str::get_at(S, i);
				if (c == URL_SYMBOL_CHAR) break;
				PUT_TO(T, c);
			}
			inter_symbol *symb = Inter::SymbolsTables::url_name_to_symbol(I, NULL, T);
			WRITE("%S", CodeGen::name(symb));
			DISCARD_TEXT(T);
		} else PUT(c);
	}
}

void CodeGen::local(code_generation *gen, inter_frame P) {
	inter_package *pack = Inter::Packages::container(P);
	inter_symbol *routine = pack->package_name;
	inter_symbol *var_name = Inter::SymbolsTables::local_symbol_from_id(routine, P.data[DEFN_LOCAL_IFLD]);
	text_stream *OUT = CodeGen::current(gen);
	WRITE(" %S", var_name->symbol_name);
}

void CodeGen::label(code_generation *gen, inter_frame P) {
	text_stream *OUT = CodeGen::current(gen);
	inter_package *pack = Inter::Packages::container(P);
	inter_symbol *routine = pack->package_name;
	inter_symbol *lab_name = Inter::SymbolsTables::local_symbol_from_id(routine, P.data[DEFN_LABEL_IFLD]);
	if (Str::eq(lab_name->symbol_name, I".begin")) { WRITE(";\n"); INDENT; }
	else if (Str::eq(lab_name->symbol_name, I".end")) { OUTDENT; WRITE("];\n"); }
	else WRITE("%S;\n", lab_name->symbol_name);
	inter_frame_list *ifl = Inter::find_frame_list(P.repo_segment->owning_repo, P.data[CODE_LABEL_IFLD]);
	if (ifl == NULL) internal_error("block without code list");
	inter_frame F;
	LOOP_THROUGH_INTER_FRAME_LIST(F, ifl)
		CodeGen::frame(gen, F);
}

void CodeGen::block(code_generation *gen, inter_frame P) {
	inter_symbol *block = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_PACKAGE_IFLD);
	inter_frame_list *ifl = Inter::Package::code_list(block);
	if (ifl == NULL) internal_error("block without code list");
	inter_frame F;
	LOOP_THROUGH_INTER_FRAME_LIST(F, ifl)
		CodeGen::frame(gen, F);
}

void CodeGen::code(code_generation *gen, inter_frame P) {
	int old_level = void_level;
	void_level = Inter::Defn::get_level(P) + 1;
	inter_frame_list *ifl = Inter::find_frame_list(P.repo_segment->owning_repo, P.data[CODE_CODE_IFLD]);
	if (ifl) {
		inter_frame F;
		LOOP_THROUGH_INTER_FRAME_LIST(F, ifl)
			CodeGen::frame(gen, F);
	}
	void_level = old_level;
}

void CodeGen::evaluation(code_generation *gen, inter_frame P) {
	int old_level = void_level;
	inter_frame_list *ifl = Inter::find_frame_list(P.repo_segment->owning_repo, P.data[CODE_EVAL_IFLD]);
	if (ifl) {
		inter_frame F;
		LOOP_THROUGH_INTER_FRAME_LIST(F, ifl)
			CodeGen::frame(gen, F);
	}
	void_level = old_level;
}

void CodeGen::reference(code_generation *gen, inter_frame P) {
	int old_level = void_level;
	inter_frame_list *ifl = Inter::find_frame_list(P.repo_segment->owning_repo, P.data[CODE_RCE_IFLD]);
	if (ifl) {
		inter_frame F;
		LOOP_THROUGH_INTER_FRAME_LIST(F, ifl)
			CodeGen::frame(gen, F);
	}
	void_level = old_level;
}

void CodeGen::cast(code_generation *gen, inter_frame P) {
	inter_frame_list *ifl = Inter::Cast::children_of_frame(P);
	if (ifl == NULL) internal_error("cast without code list");
	CodeGen::frame(gen, Inter::top_of_frame_list(ifl));
}

void CodeGen::lab(code_generation *gen, inter_frame P) {
	inter_package *pack = Inter::Packages::container(P);
	inter_symbol *routine = pack->package_name;
	if (Inter::Package::is(routine) == FALSE) internal_error("bad lab");
	inter_symbol *lab = Inter::SymbolsTables::local_symbol_from_id(routine, P.data[LABEL_LAB_IFLD]);
	if (lab == NULL) internal_error("bad lab");
	text_stream *OUT = CodeGen::current(gen);
	if (query_labels_mode) PUT('?');
	if (negate_label_mode) PUT('~');
	text_stream *S = CodeGen::name(lab);
	LOOP_THROUGH_TEXT(pos, S)
		if (Str::get(pos) != '.')
			PUT(Str::get(pos));
}

code_generation *temporary_generation = NULL;
void CodeGen::val_from(OUTPUT_STREAM, inter_reading_state *IRS, inter_t val1, inter_t val2) {
	if (Inter::Symbols::is_stored_in_data(val1, val2)) {
		inter_symbol *symb = Inter::SymbolsTables::symbol_from_data_pair_and_table(
			val1, val2, Inter::Bookmarks::scope(IRS));
		if (symb == NULL) internal_error("bad symbol");
		WRITE("%S", CodeGen::name(symb));
		return;
	}
	switch (val1) {
		case UNDEF_IVAL:
			internal_error("value undefined");
		case LITERAL_IVAL:
		case LITERAL_TEXT_IVAL:
		case GLOB_IVAL:
		case DWORD_IVAL:
		case REAL_IVAL:
		case PDWORD_IVAL:
			if (temporary_generation == NULL) {
				CodeGen::Targets::make_targets();
				temporary_generation = CodeGen::new_generation(IRS->read_into, CodeGen::I6::target());
			}
			CodeGen::select_temporary(temporary_generation, OUT);
			CodeGen::literal(temporary_generation, NULL, NULL, val1, val2, FALSE);
			CodeGen::deselect_temporary(temporary_generation);
			break;
	}
}

void CodeGen::val(code_generation *gen, inter_frame P) {
	inter_symbol *val_kind = Inter::SymbolsTables::symbol_from_frame_data(P, KIND_VAL_IFLD);
	if (val_kind) {
		inter_t val1 = P.data[VAL1_VAL_IFLD];
		inter_t val2 = P.data[VAL2_VAL_IFLD];
		if (Inter::Symbols::is_stored_in_data(val1, val2)) {
			inter_package *pack = Inter::Packages::container(P);
			inter_symbol *routine = pack->package_name;
			inter_symbol *symb = Inter::SymbolsTables::local_symbol_from_id(routine, val2);
			if (symb == NULL) symb = Inter::SymbolsTables::symbol_from_id(Inter::Packages::scope_of(P), val2);
			if (symb == NULL) internal_error("bad val");
			text_stream *OUT = CodeGen::current(gen);
			WRITE("%S", CodeGen::name(symb));
			return;
		}
		switch (val1) {
			case UNDEF_IVAL:
				internal_error("value undefined");
			case LITERAL_IVAL:
			case LITERAL_TEXT_IVAL:
			case GLOB_IVAL:
			case DWORD_IVAL:
			case REAL_IVAL:
			case PDWORD_IVAL:
				CodeGen::literal(gen, NULL, NULL, val1, val2, FALSE);
				return;
		}
	}
	internal_error("bad val");
}

@

@d INV_A1 CodeGen::frame(gen, Inter::top_of_frame_list(ifl))
@d INV_A1_PRINTMODE CodeGen::enter_print_mode(); INV_A1; CodeGen::exit_print_mode();
@d INV_A1_BOXMODE CodeGen::enter_box_mode(); INV_A1; CodeGen::exit_box_mode();
@d INV_A2 CodeGen::frame(gen, Inter::second_in_frame_list(ifl))
@d INV_A3 CodeGen::frame(gen, Inter::third_in_frame_list(ifl))
@d INV_A4 CodeGen::frame(gen, Inter::fourth_in_frame_list(ifl))
@d INV_A5 CodeGen::frame(gen, Inter::fifth_in_frame_list(ifl))
@d INV_A6 CodeGen::frame(gen, Inter::sixth_in_frame_list(ifl))

=
void CodeGen::inv(code_generation *gen, inter_frame P) {
	text_stream *OUT = CodeGen::current(gen);
	int suppress_terminal_semicolon = FALSE;
	inter_frame_list *ifl = Inter::Inv::children_of_frame(P);
	if (ifl == NULL) internal_error("cast without code list");

	switch (P.data[METHOD_INV_IFLD]) {
		case INVOKED_PRIMITIVE: {
			inter_symbol *prim = Inter::Inv::invokee(P);
			if (prim == NULL) internal_error("bad prim");
			suppress_terminal_semicolon = CodeGen::Targets::compile_primitive(gen, prim, ifl);
			break;
		}
		case INVOKED_ROUTINE: {
			inter_symbol *routine = Inter::SymbolsTables::symbol_from_frame_data(P, INVOKEE_INV_IFLD);
			if (routine == NULL) internal_error("bad routine");
			WRITE("%S(", CodeGen::name(routine));
			inter_frame F;
			int argc = 0;
			LOOP_THROUGH_INTER_FRAME_LIST(F, ifl) {
				if (argc++ > 0) WRITE(", ");
				CodeGen::frame(gen, F);
			}
			WRITE(")");
			break;
		}
		case INVOKED_OPCODE: {
			inter_t ID = P.data[INVOKEE_INV_IFLD];
			text_stream *S = Inter::get_text(P.repo_segment->owning_repo, ID);
			WRITE("%S", S);
			inter_frame F; negate_label_mode = FALSE;
			LOOP_THROUGH_INTER_FRAME_LIST(F, ifl) {
				query_labels_mode = TRUE;
				if (F.data[ID_IFLD] == VAL_IST) {
					inter_t val1 = F.data[VAL1_VAL_IFLD];
					inter_t val2 = F.data[VAL2_VAL_IFLD];
					if (Inter::Symbols::is_stored_in_data(val1, val2)) {
						inter_symbol *symb = Inter::SymbolsTables::symbol_from_id(Inter::Packages::scope_of(F), val2);
						if ((symb) && (Str::eq(symb->symbol_name, I"__assembly_negated_label"))) {
							negate_label_mode = TRUE;
							continue;
						}
					}
				}
				WRITE(" ");
				CodeGen::frame(gen, F);
				query_labels_mode = FALSE;
			}
			negate_label_mode = FALSE;
			break;
		}
		default: internal_error("bad inv");
	}
	if ((Inter::Defn::get_level(P) == void_level) &&
		(suppress_terminal_semicolon == FALSE)) WRITE(";\n");
}

@ =
int CodeGen::compare_tlh(const void *elem1, const void *elem2) {
	const text_literal_holder **e1 = (const text_literal_holder **) elem1;
	const text_literal_holder **e2 = (const text_literal_holder **) elem2;
	if ((*e1 == NULL) || (*e2 == NULL))
		internal_error("Disaster while sorting text literals");
	text_stream *s1 = (*e1)->literal_content;
	text_stream *s2 = (*e2)->literal_content;
	return Str::cmp(s1, s2);
}

int CodeGen::compare_kind_symbols(const void *elem1, const void *elem2) {
	const inter_symbol **e1 = (const inter_symbol **) elem1;
	const inter_symbol **e2 = (const inter_symbol **) elem2;
	if ((*e1 == NULL) || (*e2 == NULL))
		internal_error("Disaster while sorting kinds");
	int s1 = CodeGen::kind_sequence_number(*e1);
	int s2 = CodeGen::kind_sequence_number(*e2);
	if (s1 != s2) return s1-s2;
	return (*e1)->allocation_id - (*e2)->allocation_id;
}

int CodeGen::compare_kind_symbols_decl(const void *elem1, const void *elem2) {
	const inter_symbol **e1 = (const inter_symbol **) elem1;
	const inter_symbol **e2 = (const inter_symbol **) elem2;
	if ((*e1 == NULL) || (*e2 == NULL))
		internal_error("Disaster while sorting kinds");
	int s1 = CodeGen::kind_sequence_number_decl(*e1);
	int s2 = CodeGen::kind_sequence_number_decl(*e2);
	if (s1 != s2) return s1-s2;
	return (*e1)->allocation_id - (*e2)->allocation_id;
}

int CodeGen::kind_sequence_number(const inter_symbol *kind_name) {
	int A = 100000000;
	for (int i=0; i<kind_name->no_symbol_annotations; i++)
		if (kind_name->symbol_annotations[i].annot->annotation_ID == SOURCE_ORDER_IANN)
			A = (int) kind_name->symbol_annotations[i].annot_value;
	return A;
}

int CodeGen::kind_sequence_number_decl(const inter_symbol *kind_name) {
	int A = 100000000;
	for (int i=0; i<kind_name->no_symbol_annotations; i++)
		if (kind_name->symbol_annotations[i].annot->annotation_ID == DECLARATION_ORDER_IANN)
			A = (int) kind_name->symbol_annotations[i].annot_value;
	return A;
}

int CodeGen::weak_id(inter_symbol *kind_name) {
	for (int i=0; i<kind_name->no_symbol_annotations; i++)
		if (kind_name->symbol_annotations[i].annot->annotation_ID == WEAK_ID_IANN)
			return (int) kind_name->symbol_annotations[i].annot_value;
	return 0;
}

int CodeGen::pnum(inter_symbol *prop_name) {
	for (int i=0; i<prop_name->no_symbol_annotations; i++)
		if (prop_name->symbol_annotations[i].annot->annotation_ID == SOURCE_ORDER_IANN)
			return (int) prop_name->symbol_annotations[i].annot_value;
	return 0;
}

int CodeGen::marked(inter_symbol *symb_name) {
	return Inter::Symbols::get_flag(symb_name, TRAVERSE_MARK_BIT);
}

void CodeGen::mark(inter_symbol *symb_name) {
	Inter::Symbols::set_flag(symb_name, TRAVERSE_MARK_BIT);
}

void CodeGen::unmark(inter_symbol *symb_name) {
	Inter::Symbols::clear_flag(symb_name, TRAVERSE_MARK_BIT);
}

@ =
int CodeGen::is_kind_of_object(inter_symbol *kind_name) {
	if (kind_name == object_kind_symbol) return FALSE;
	inter_data_type *idt = Inter::Kind::data_type(kind_name);
	if (idt == unchecked_idt) return FALSE;
	if (Inter::Kind::is_a(kind_name, object_kind_symbol)) return TRUE;
	return FALSE;
}

@ Counting kinds of object, not very quickly:

=
inter_t CodeGen::kind_of_object_count(inter_symbol *kind_name) {
	if ((kind_name == NULL) || (kind_name == object_kind_symbol)) return 0;
	for (int i=0; i<kind_name->no_symbol_annotations; i++)
		if (kind_name->symbol_annotations[i].annot->annotation_ID == OBJECT_KIND_COUNTER_IANN)
			return kind_name->symbol_annotations[i].annot_value;
	return 0;
}

void CodeGen::append(code_generation *gen, inter_symbol *symb) {
	text_stream *OUT = CodeGen::current(gen);
	inter_repository *I = gen->from;
	text_stream *S = Inter::Symbols::get_append(symb);
	if (Str::len(S) == 0) return;
	WRITE("    ");
	int L = Str::len(S);
	for (int i=0; i<L; i++) {
		wchar_t c = Str::get_at(S, i);
		if (c == URL_SYMBOL_CHAR) {
			TEMPORARY_TEXT(T);
			for (i++; i<L; i++) {
				wchar_t c = Str::get_at(S, i);
				if (c == URL_SYMBOL_CHAR) break;
				PUT_TO(T, c);
			}
			inter_symbol *symb = Inter::SymbolsTables::url_name_to_symbol(I, NULL, T);
			WRITE("%S", CodeGen::name(symb));
			DISCARD_TEXT(T);
		} else PUT(c);
		if ((c == '\n') && (i != Str::len(S)-1)) WRITE("    ");
	}
}

text_stream *CodeGen::name(inter_symbol *symb) {
	if (symb == NULL) return NULL;
	if (Inter::Symbols::get_translate(symb)) return Inter::Symbols::get_translate(symb);
	return symb->symbol_name;
}

@ =
void CodeGen::compile_to_I6_dictionary(OUTPUT_STREAM, text_stream *S, int pluralise) {
	int n = 0;
	WRITE("'");
	LOOP_THROUGH_TEXT(pos, S) {
		wchar_t c = Str::get(pos);
		switch(c) {
			case '/': if (Str::len(S) == 1) WRITE("@{2F}"); else WRITE("/"); break;
			case '\'': WRITE("^"); break;
			case '^': WRITE("@{5E}"); break;
			case '~': WRITE("@{7E}"); break;
			case '@': WRITE("@{40}"); break;
			default: PUT(c);
		}
		if (n++ > 32) break;
	}
	if (pluralise) WRITE("//p");
	else if (Str::len(S) == 1) WRITE("//");
	WRITE("'");
}
