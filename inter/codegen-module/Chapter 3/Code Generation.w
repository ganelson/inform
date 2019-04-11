[CodeGen::] Code Generation.

To generate I6 code from intermediate code.

@h Hello.

@d MAX_REPOS_AT_ONCE 8

=
typedef struct text_literal_holder {
	struct text_stream *definition_code;
	struct text_stream *literal_content;
	MEMORY_MANAGEMENT
} text_literal_holder;

void CodeGen::to_I6(inter_repository *I, OUTPUT_STREAM) {
	if (I == NULL) internal_error("no inter to generate from");

	inter_repository *repos[MAX_REPOS_AT_ONCE];
	int no_repos = CodeGen::repo_list(I, repos);

	for (int j=0; j<no_repos; j++) {
		inter_repository *I = repos[j];
		inter_frame P;
		LOOP_THROUGH_FRAMES(P, I)
			if (P.data[ID_IFLD] == IMPORT_IST) {
				inter_symbol *imp_name = Inter::SymbolsTables::symbol_from_frame_data(P, SYMBOL_IMPORT_IFLD);
				inter_symbol *exp_name = Inter::Symbols::get_bridge(imp_name);
				if (exp_name) {
					inter_repository *repo = Inter::Symbols::defining_frame(exp_name).repo_segment->owning_repo;
					int found = FALSE;
					for (int i=0; i<no_repos; i++) if (repos[i] == repo) found = TRUE;
					if (found == FALSE) {
						if (no_repos >= MAX_REPOS_AT_ONCE)
							internal_error("too many repos to import");
						repos[no_repos++] = repo;
					}
				}
			}
	}

	for (int j=0; j<no_repos; j++) {
		inter_repository *I = repos[j];
		CodeGen::Var::set_translates(I);
	}

	LOG("Generating I6 from %d repository/ies\n", no_repos);

	Inter::Symbols::clear_transient_flags();

	text_stream *early_matter = Str::new();
	text_stream *summations_at_eof = Str::new();
	text_stream *attributes_at_eof = Str::new();
	text_stream *arrays_at_eof = Str::new();
	text_stream *main_matter = Str::new();
	text_stream *code_at_eof = Str::new();
	text_stream *verbs_at_eof = Str::new();
	text_stream *routines_at_eof = Str::new();
	int properties_written = FALSE;
	int variables_written = FALSE;

	for (int j=0; j<no_repos; j++) {
		inter_repository *I = repos[j];
		inter_frame P;
		LOOP_THROUGH_FRAMES(P, I) {
			inter_package *outer = Inter::Packages::container(P);
			if ((outer == NULL) || (outer->codelike_package == FALSE)) {
				text_stream *TO = main_matter;
				switch (P.data[ID_IFLD]) {
					case CONSTANT_IST: {
						inter_symbol *con_name =
							Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_CONST_IFLD);
						if (Inter::Packages::container(P) == Inter::Packages::main(I)) {
							WRITE_TO(STDERR, "Bad constant: %S\n", con_name->symbol_name);
							internal_error("constant defined in main");
						}
						TO = early_matter;
						if (Inter::Symbols::read_annotation(con_name, TEXT_LITERAL_IANN) == 1) {
							text_literal_holder *tlh = CREATE(text_literal_holder);
							tlh->definition_code = Str::new();
							inter_t ID = P.data[DATA_CONST_IFLD];
							tlh->literal_content = Inter::get_text(P.repo_segment->owning_repo, ID);
							TO = tlh->definition_code;
						}
						if (Inter::Symbols::read_annotation(con_name, LATE_IANN) == 1) TO = code_at_eof;
						if (Inter::Symbols::read_annotation(con_name, BUFFERARRAY_IANN) == 1) TO = arrays_at_eof;
						if (Inter::Symbols::read_annotation(con_name, BYTEARRAY_IANN) == 1) TO = arrays_at_eof;
						if (Inter::Symbols::read_annotation(con_name, STRINGARRAY_IANN) == 1) TO = arrays_at_eof;
						if (Inter::Symbols::read_annotation(con_name, TABLEARRAY_IANN) == 1) TO = arrays_at_eof;
						if (P.data[FORMAT_CONST_IFLD] == CONSTANT_SUM_LIST) TO = summations_at_eof;
						if (P.data[FORMAT_CONST_IFLD] == CONSTANT_INDIRECT_LIST) TO = arrays_at_eof;
						if ((P.data[FORMAT_CONST_IFLD] == CONSTANT_DIRECT) && (P.data[DATA_CONST_IFLD] == GLOB_IVAL)) TO = summations_at_eof;
						if (Inter::Symbols::read_annotation(con_name, VERBARRAY_IANN) == 1) TO = verbs_at_eof;
						if (Inter::Constant::is_routine(con_name)) {
							TO = routines_at_eof;
						}
						CodeGen::frame(TO, I, P); break;
					}
					case PRAGMA_IST:
						CodeGen::frame(early_matter, I, P); break;
					case INSTANCE_IST:
						CodeGen::frame(TO, I, P); break;
					case SPLAT_IST:
						if (P.data[PLM_SPLAT_IFLD] != OBJECT_PLM) CodeGen::frame(TO, I, P);
						break;
					case PROPERTYVALUE_IST:
						@<Property knowledge@>;
						break;
					case VARIABLE_IST:
						if (variables_written == FALSE) {
							variables_written = TRUE;
							CodeGen::Var::knowledge(TO, I);
						}
						break;
					case IMPORT_IST: {
						inter_symbol *imp_name =
							Inter::SymbolsTables::symbol_from_frame_data(P, SYMBOL_IMPORT_IFLD);
						inter_symbol *exp_name = Inter::Symbols::get_bridge(imp_name);
						if (exp_name) {
							WRITE_TO(early_matter, "Constant %S = %S;\n", CodeGen::name(imp_name), CodeGen::name(exp_name));
						}
						break;
					}
				}
			}
		}
	}

	int NR = 0;
	for (int j=0; j<no_repos; j++) {
		inter_repository *I = repos[j];
		inter_frame P;
		LOOP_THROUGH_FRAMES(P, I) {
			if (P.data[ID_IFLD] == RESPONSE_IST) {
				inter_symbol *resp_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_RESPONSE_IFLD);
				WRITE_TO(early_matter, "Constant %S = %d;\n", CodeGen::name(resp_name), ++NR);
			}
		}
	}
	if (NR > 0) {
		WRITE_TO(early_matter, "Constant NO_RESPONSES = %d;\n", NR);
		WRITE_TO(main_matter, "Array ResponseTexts --> ");
		for (int j=0; j<no_repos; j++) {
			inter_repository *I = repos[j];
			inter_frame P;
			LOOP_THROUGH_FRAMES(P, I) {
				if (P.data[ID_IFLD] == RESPONSE_IST) {
					NR++;
					CodeGen::literal(main_matter, I, NULL, Inter::Packages::scope_of(P), P.data[VAL1_RESPONSE_IFLD], P.data[VAL1_RESPONSE_IFLD+1], FALSE);
					WRITE_TO(main_matter, " ");
				}
			}
		}
		WRITE_TO(main_matter, "0 0;\n");
	}

	if (properties_written == FALSE) { text_stream *TO = main_matter; @<Property knowledge@>; }

	WRITE("%S", early_matter);

	int no_tlh = NUMBER_CREATED(text_literal_holder);
	text_literal_holder **sorted = (text_literal_holder **)
			(Memory::I7_calloc(no_tlh, sizeof(text_literal_holder *), CODE_GENERATION_MREASON));
	int i = 0;
	text_literal_holder *tlh;
	LOOP_OVER(tlh, text_literal_holder) sorted[i++] = tlh;

	qsort(sorted, (size_t) no_tlh, sizeof(text_literal_holder *),
		CodeGen::compare_tlh);
	for (int i=0; i<no_tlh; i++) {
		text_literal_holder *tlh = sorted[i];
		WRITE("! TLH %d <%S>\n", tlh->allocation_id, tlh->literal_content);
		WRITE("%S", tlh->definition_code);
	}
	
	WRITE("%S", summations_at_eof);
	WRITE("%S", attributes_at_eof);
	WRITE("%S", arrays_at_eof);
	WRITE("%S", main_matter);
	WRITE("%S", routines_at_eof);
	WRITE("%S", code_at_eof);
	WRITE("%S", verbs_at_eof);
}

@<Property knowledge@> =
	if (properties_written == FALSE) {
		for (int j=0; j<no_repos; j++) {
			inter_repository *I = repos[j];
			inter_frame P;
			LOOP_THROUGH_FRAMES(P, I) {
				if ((P.data[ID_IFLD] == SPLAT_IST) && (P.data[PLM_SPLAT_IFLD] == OBJECT_PLM))
					CodeGen::frame(TO, I, P);
			}
		}
		properties_written = TRUE;
		CodeGen::IP::knowledge(TO, I, code_at_eof, attributes_at_eof);
	}

@ =
int CodeGen::repo_list(inter_repository *I, inter_repository **repos) {
	int no_repos = 0;
	repos[no_repos++] = I;

	for (int j=0; j<no_repos; j++) {
		inter_repository *J = repos[j];
		inter_frame P;
		LOOP_THROUGH_FRAMES(P, J)
			if (P.data[ID_IFLD] == IMPORT_IST) {
				inter_symbol *imp_name = Inter::SymbolsTables::symbol_from_frame_data(P, SYMBOL_IMPORT_IFLD);
				inter_symbol *exp_name = Inter::Symbols::get_bridge(imp_name);
				if (exp_name) {
					inter_repository *repo = Inter::Symbols::defining_frame(exp_name).repo_segment->owning_repo;
					int found = FALSE;
					for (int i=0; i<no_repos; i++) if (repos[i] == repo) found = TRUE;
					if (found == FALSE) {
						if (no_repos >= MAX_REPOS_AT_ONCE)
							internal_error("too many repos to import");
						repos[no_repos++] = repo;
					}
				}
			}
	}

	for (int j=0; j<no_repos; j++) {
		inter_repository *J = repos[j];
		if (J != I) J->main_repo = I;
	}
	return no_repos;
}

void CodeGen::frame(OUTPUT_STREAM, inter_repository *I, inter_frame P) {
	switch (P.data[ID_IFLD]) {
		case SYMBOL_IST: break;
		case CONSTANT_IST: CodeGen::constant(OUT, I, P); break;
		case INSTANCE_IST: CodeGen::IP::instance(OUT, I, P); break;
		case SPLAT_IST: CodeGen::splat(OUT, I, P); break;
		case LOCAL_IST: CodeGen::local(OUT, I, P); break;
		case LABEL_IST: CodeGen::label(OUT, I, P); break;
		case CODE_IST: CodeGen::code(OUT, I, P); break;
		case EVALUATION_IST: CodeGen::evaluation(OUT, I, P); break;
		case REFERENCE_IST: CodeGen::reference(OUT, I, P); break;
		case PACKAGE_IST: CodeGen::block(OUT, I, P); break;
		case INV_IST: CodeGen::inv(OUT, I, P); break;
		case CAST_IST: CodeGen::cast(OUT, I, P); break;
		case VAL_IST:
		case REF_IST: CodeGen::val(OUT, I, P); break;
		case LAB_IST: CodeGen::lab(OUT, I, P); break;
		case PRAGMA_IST: CodeGen::pragma(OUT, I, P); break;
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

void CodeGen::constant(OUTPUT_STREAM, inter_repository *I, inter_frame P) {
	inter_symbol *con_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_CONST_IFLD);

	if (Inter::Symbols::read_annotation(con_name, INLINE_ARRAY_IANN) == 1) return;

	if (Inter::Symbols::read_annotation(con_name,ACTION_IANN) == 1) {
		if (Inter::Symbols::read_annotation(con_name, FAKE_ACTION_IANN) == 1) {
			WRITE("Fake_action %S;\n", con_name->symbol_name);
		}
		return;
	}

	if (Str::eq(con_name->symbol_name, I"nothing")) return;

	if (Str::eq(con_name->symbol_name, I"##TheSame")) return;
	if (Str::eq(con_name->symbol_name, I"##PluralFound")) return;
	if (Str::eq(con_name->symbol_name, I"parent")) return;
	if (Str::eq(con_name->symbol_name, I"child")) return;
	if (Str::eq(con_name->symbol_name, I"sibling")) return;
	if (Str::eq(con_name->symbol_name, I"thedark")) return;
	if (Str::eq(con_name->symbol_name, I"ResponseTexts")) return;
	if (Str::eq(con_name->symbol_name, I"FLOAT_NAN")) return;

	if (Str::eq(con_name->symbol_name, I"Release")) {
		inter_t val1 = P.data[DATA_CONST_IFLD];
		inter_t val2 = P.data[DATA_CONST_IFLD + 1];
		WRITE("Release ");
		CodeGen::literal(OUT, I, NULL, Inter::Packages::scope_of(P), val1, val2, FALSE);
		WRITE(";\n");
		return;
	}

	if (Str::eq(con_name->symbol_name, I"Story")) {
		inter_t val1 = P.data[DATA_CONST_IFLD];
		inter_t val2 = P.data[DATA_CONST_IFLD + 1];
		WRITE("Global Story = ");
		CodeGen::literal(OUT, I, NULL, Inter::Packages::scope_of(P), val1, val2, FALSE);
		WRITE(";\n");
		return;
	}

	if (Str::eq(con_name->symbol_name, I"Serial")) {
		inter_t val1 = P.data[DATA_CONST_IFLD];
		inter_t val2 = P.data[DATA_CONST_IFLD + 1];
		WRITE("Serial ");
		CodeGen::literal(OUT, I, NULL, Inter::Packages::scope_of(P), val1, val2, FALSE);
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

	int ifndef_me = FALSE;
	if ((Str::eq(con_name->symbol_name, I"WORDSIZE")) ||
		(Str::eq(con_name->symbol_name, I"TARGET_ZCODE")) ||
		(Str::eq(con_name->symbol_name, I"TARGET_GLULX")) ||
		(Str::eq(con_name->symbol_name, I"DICT_WORD_SIZE")) ||
		(Str::eq(con_name->symbol_name, I"DEBUG")))
		ifndef_me = TRUE;
	if (Inter::Constant::is_routine(con_name)) {
		WRITE("[ %S", CodeGen::name(con_name));
		inter_symbol *code_block = Inter::Constant::code_block(con_name);
		void_level = Inter::Defn::get_level(P) + 2;
		if (code_block) {
			inter_frame D = Inter::Symbols::defining_frame(code_block);
			CodeGen::frame(OUT, I, D);
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
				CodeGen::literal(OUT, I, con_name, Inter::Packages::scope_of(P), P.data[i], P.data[i+1], unsub);
				if ((do_not_bracket == FALSE) && (P.data[i] != DIVIDER_IVAL)) WRITE(")");
			}
			WRITE(";\n");
			break;
		}
		case CONSTANT_SUM_LIST:
			WRITE("Constant %S = ", CodeGen::name(con_name));
			for (int i=DATA_CONST_IFLD; i<P.extent; i=i+2) {
				if (i>DATA_CONST_IFLD) WRITE(" + ");
				int bracket = TRUE;
				if ((P.data[i] == LITERAL_IVAL) || (Inter::Symbols::is_stored_in_data(P.data[i], P.data[i+1]))) bracket = FALSE;
				if (bracket) WRITE("(");
				CodeGen::literal(OUT, I, con_name, Inter::Packages::scope_of(P), P.data[i], P.data[i+1], FALSE);
				if (bracket) WRITE(")");
			}
			WRITE(";\n");
			break;
		case CONSTANT_DIRECT: {
			inter_t val1 = P.data[DATA_CONST_IFLD];
			inter_t val2 = P.data[DATA_CONST_IFLD + 1];
			if (ifndef_me) WRITE("#ifndef %S; ", CodeGen::name(con_name));
			WRITE("Constant %S = ", CodeGen::name(con_name));
			CodeGen::literal(OUT, I, con_name, Inter::Packages::scope_of(P), val1, val2, FALSE);
			WRITE(";");
			if (ifndef_me) WRITE(" #endif;");
			WRITE("\n");
			break;
		}
		default: internal_error("ungenerated constant format");
	}
}

void CodeGen::literal(OUTPUT_STREAM, inter_repository *I, inter_symbol *con_name, inter_symbols_table *T, inter_t val1, inter_t val2, int unsub) {
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
		CodeGen::compile_to_I6_text(OUT, glob_text);
	} else if (val1 == GLOB_IVAL) {
		text_stream *glob_text = Inter::get_text(I, val2);
		WRITE("%S", glob_text);
	} else internal_error("unimplemented direct constant");
}

void CodeGen::pragma(OUTPUT_STREAM, inter_repository *I, inter_frame P) {
	inter_symbol *target_symbol = Inter::SymbolsTables::symbol_from_frame_data(P, TARGET_PRAGMA_IFLD);
	if (target_symbol == NULL) internal_error("bad pragma");
	if (Str::eq(target_symbol->symbol_name, I"target_I6")) {
		inter_t ID = P.data[TEXT_PRAGMA_IFLD];
		text_stream *S = Inter::get_text(P.repo_segment->owning_repo, ID);
		WRITE("!%% %S\n", S);
	}
}

@

@d URL_SYMBOL_CHAR 0x00A7

=
void CodeGen::splat(OUTPUT_STREAM, inter_repository *I, inter_frame P) {
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

void CodeGen::local(OUTPUT_STREAM, inter_repository *I, inter_frame P) {
	inter_package *pack = Inter::Packages::container(P);
	inter_symbol *routine = pack->package_name;
	inter_symbol *var_name = Inter::SymbolsTables::local_symbol_from_id(routine, P.data[DEFN_LOCAL_IFLD]);
	WRITE(" %S", var_name->symbol_name);
}

void CodeGen::label(OUTPUT_STREAM, inter_repository *I, inter_frame P) {
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
		CodeGen::frame(OUT, I, F);
}

void CodeGen::block(OUTPUT_STREAM, inter_repository *I, inter_frame P) {
	inter_symbol *block = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_PACKAGE_IFLD);
	inter_frame_list *ifl = Inter::Package::code_list(block);
	if (ifl == NULL) internal_error("block without code list");
	inter_frame F;
	LOOP_THROUGH_INTER_FRAME_LIST(F, ifl)
		CodeGen::frame(OUT, I, F);
}

void CodeGen::code(OUTPUT_STREAM, inter_repository *I, inter_frame P) {
	int old_level = void_level;
	void_level = Inter::Defn::get_level(P) + 1;
	inter_frame_list *ifl = Inter::find_frame_list(P.repo_segment->owning_repo, P.data[CODE_CODE_IFLD]);
	if (ifl) {
		inter_frame F;
		LOOP_THROUGH_INTER_FRAME_LIST(F, ifl)
			CodeGen::frame(OUT, I, F);
	}
	void_level = old_level;
}

void CodeGen::evaluation(OUTPUT_STREAM, inter_repository *I, inter_frame P) {
	int old_level = void_level;
	inter_frame_list *ifl = Inter::find_frame_list(P.repo_segment->owning_repo, P.data[CODE_EVAL_IFLD]);
	if (ifl) {
		inter_frame F;
		LOOP_THROUGH_INTER_FRAME_LIST(F, ifl)
			CodeGen::frame(OUT, I, F);
	}
	void_level = old_level;
}

void CodeGen::reference(OUTPUT_STREAM, inter_repository *I, inter_frame P) {
	int old_level = void_level;
	inter_frame_list *ifl = Inter::find_frame_list(P.repo_segment->owning_repo, P.data[CODE_RCE_IFLD]);
	if (ifl) {
		inter_frame F;
		LOOP_THROUGH_INTER_FRAME_LIST(F, ifl)
			CodeGen::frame(OUT, I, F);
	}
	void_level = old_level;
}

@

@e NOT_BIP from 1
@e AND_BIP
@e OR_BIP
@e BITWISEAND_BIP
@e BITWISEOR_BIP
@e BITWISENOT_BIP
@e EQ_BIP
@e NE_BIP
@e GT_BIP
@e GE_BIP
@e LT_BIP
@e LE_BIP
@e OFCLASS_BIP
@e HAS_BIP
@e HASNT_BIP
@e IN_BIP
@e NOTIN_BIP
@e SEQUENTIAL_BIP
@e TERNARYSEQUENTIAL_BIP
@e PLUS_BIP
@e MINUS_BIP
@e UNARYMINUS_BIP
@e TIMES_BIP
@e DIVIDE_BIP
@e MODULO_BIP
@e RANDOM_BIP
@e RETURN_BIP
@e MOVE_BIP
@e GIVE_BIP
@e TAKE_BIP
@e JUMP_BIP
@e QUIT_BIP
@e BREAK_BIP
@e CONTINUE_BIP
@e STYLEROMAN_BIP
@e FONT_BIP
@e STYLEBOLD_BIP
@e STYLEUNDERLINE_BIP
@e PRINT_BIP
@e PRINTCHAR_BIP
@e PRINTNAME_BIP
@e PRINTNUMBER_BIP
@e PRINTADDRESS_BIP
@e PRINTSTRING_BIP
@e PRINTNLNUMBER_BIP
@e PRINTDEF_BIP
@e PRINTCDEF_BIP
@e PRINTINDEF_BIP
@e PRINTCINDEF_BIP
@e BOX_BIP
@e PUSH_BIP
@e PULL_BIP
@e PREINCREMENT_BIP
@e POSTINCREMENT_BIP
@e PREDECREMENT_BIP
@e POSTDECREMENT_BIP
@e STORE_BIP
@e SETBIT_BIP
@e CLEARBIT_BIP
@e IF_BIP
@e IFDEBUG_BIP
@e IFELSE_BIP
@e WHILE_BIP
@e FOR_BIP
@e OBJECTLOOP_BIP
@e OBJECTLOOPX_BIP
@e LOOKUP_BIP
@e LOOKUPBYTE_BIP
@e LOOKUPREF_BIP
@e LOOP_BIP
@e SWITCH_BIP
@e CASE_BIP
@e DEFAULT_BIP
@e INDIRECT0V_BIP
@e INDIRECT1V_BIP
@e INDIRECT2V_BIP
@e INDIRECT3V_BIP
@e INDIRECT4V_BIP
@e INDIRECT5V_BIP
@e INDIRECT0_BIP
@e INDIRECT1_BIP
@e INDIRECT2_BIP
@e INDIRECT3_BIP
@e INDIRECT4_BIP
@e INDIRECT5_BIP
@e PROPERTYADDRESS_BIP
@e PROPERTYLENGTH_BIP
@e PROVIDES_BIP
@e PROPERTYVALUE_BIP

=
inter_t CodeGen::built_in_primitive(inter_repository *I, inter_symbol *symb) {
	if (symb == NULL) return 0;
	int B = Inter::Symbols::read_annotation(symb, BIP_CODE_IANN);
	inter_t bip = (B > 0)?((inter_t) B):0;
	if (bip != 0) return bip;
	if (Str::eq(symb->symbol_name, I"!not")) bip = NOT_BIP;
	if (Str::eq(symb->symbol_name, I"!and")) bip = AND_BIP;
	if (Str::eq(symb->symbol_name, I"!or")) bip = OR_BIP;
	if (Str::eq(symb->symbol_name, I"!bitwiseand")) bip = BITWISEAND_BIP;
	if (Str::eq(symb->symbol_name, I"!bitwiseor")) bip = BITWISEOR_BIP;
	if (Str::eq(symb->symbol_name, I"!bitwisenot")) bip = BITWISENOT_BIP;
	if (Str::eq(symb->symbol_name, I"!eq")) bip = EQ_BIP;
	if (Str::eq(symb->symbol_name, I"!ne")) bip = NE_BIP;
	if (Str::eq(symb->symbol_name, I"!gt")) bip = GT_BIP;
	if (Str::eq(symb->symbol_name, I"!ge")) bip = GE_BIP;
	if (Str::eq(symb->symbol_name, I"!lt")) bip = LT_BIP;
	if (Str::eq(symb->symbol_name, I"!le")) bip = LE_BIP;
	if (Str::eq(symb->symbol_name, I"!ofclass")) bip = OFCLASS_BIP;
	if (Str::eq(symb->symbol_name, I"!has")) bip = HAS_BIP;
	if (Str::eq(symb->symbol_name, I"!hasnt")) bip = HASNT_BIP;
	if (Str::eq(symb->symbol_name, I"!in")) bip = IN_BIP;
	if (Str::eq(symb->symbol_name, I"!notin")) bip = NOTIN_BIP;
	if (Str::eq(symb->symbol_name, I"!sequential")) bip = SEQUENTIAL_BIP;
	if (Str::eq(symb->symbol_name, I"!ternarysequential")) bip = TERNARYSEQUENTIAL_BIP;
	if (Str::eq(symb->symbol_name, I"!plus")) bip = PLUS_BIP;
	if (Str::eq(symb->symbol_name, I"!minus")) bip = MINUS_BIP;
	if (Str::eq(symb->symbol_name, I"!unaryminus")) bip = UNARYMINUS_BIP;
	if (Str::eq(symb->symbol_name, I"!times")) bip = TIMES_BIP;
	if (Str::eq(symb->symbol_name, I"!divide")) bip = DIVIDE_BIP;
	if (Str::eq(symb->symbol_name, I"!modulo")) bip = MODULO_BIP;
	if (Str::eq(symb->symbol_name, I"!random")) bip = RANDOM_BIP;
	if (Str::eq(symb->symbol_name, I"!return")) bip = RETURN_BIP;
	if (Str::eq(symb->symbol_name, I"!jump")) bip = JUMP_BIP;
	if (Str::eq(symb->symbol_name, I"!give")) bip = GIVE_BIP;
	if (Str::eq(symb->symbol_name, I"!take")) bip = TAKE_BIP;
	if (Str::eq(symb->symbol_name, I"!move")) bip = MOVE_BIP;
	if (Str::eq(symb->symbol_name, I"!quit")) bip = QUIT_BIP;
	if (Str::eq(symb->symbol_name, I"!break")) bip = BREAK_BIP;
	if (Str::eq(symb->symbol_name, I"!continue")) bip = CONTINUE_BIP;
	if (Str::eq(symb->symbol_name, I"!font")) bip = FONT_BIP;
	if (Str::eq(symb->symbol_name, I"!styleroman")) bip = STYLEROMAN_BIP;
	if (Str::eq(symb->symbol_name, I"!stylebold")) bip = STYLEBOLD_BIP;
	if (Str::eq(symb->symbol_name, I"!styleunderline")) bip = STYLEUNDERLINE_BIP;
	if (Str::eq(symb->symbol_name, I"!print")) bip = PRINT_BIP;
	if (Str::eq(symb->symbol_name, I"!printchar")) bip = PRINTCHAR_BIP;
	if (Str::eq(symb->symbol_name, I"!printname")) bip = PRINTNAME_BIP;
	if (Str::eq(symb->symbol_name, I"!printnumber")) bip = PRINTNUMBER_BIP;
	if (Str::eq(symb->symbol_name, I"!printaddress")) bip = PRINTADDRESS_BIP;
	if (Str::eq(symb->symbol_name, I"!printstring")) bip = PRINTSTRING_BIP;
	if (Str::eq(symb->symbol_name, I"!printnlnumber")) bip = PRINTNLNUMBER_BIP;
	if (Str::eq(symb->symbol_name, I"!printdef")) bip = PRINTDEF_BIP;
	if (Str::eq(symb->symbol_name, I"!printcdef")) bip = PRINTCDEF_BIP;
	if (Str::eq(symb->symbol_name, I"!printindef")) bip = PRINTINDEF_BIP;
	if (Str::eq(symb->symbol_name, I"!printcindef")) bip = PRINTCINDEF_BIP;
	if (Str::eq(symb->symbol_name, I"!box")) bip = BOX_BIP;
	if (Str::eq(symb->symbol_name, I"!push")) bip = PUSH_BIP;
	if (Str::eq(symb->symbol_name, I"!pull")) bip = PULL_BIP;
	if (Str::eq(symb->symbol_name, I"!preincrement")) bip = PREINCREMENT_BIP;
	if (Str::eq(symb->symbol_name, I"!postincrement")) bip = POSTINCREMENT_BIP;
	if (Str::eq(symb->symbol_name, I"!predecrement")) bip = PREDECREMENT_BIP;
	if (Str::eq(symb->symbol_name, I"!postdecrement")) bip = POSTDECREMENT_BIP;
	if (Str::eq(symb->symbol_name, I"!store")) bip = STORE_BIP;
	if (Str::eq(symb->symbol_name, I"!setbit")) bip = SETBIT_BIP;
	if (Str::eq(symb->symbol_name, I"!clearbit")) bip = CLEARBIT_BIP;
	if (Str::eq(symb->symbol_name, I"!if")) bip = IF_BIP;
	if (Str::eq(symb->symbol_name, I"!ifdebug")) bip = IFDEBUG_BIP;
	if (Str::eq(symb->symbol_name, I"!ifelse")) bip = IFELSE_BIP;
	if (Str::eq(symb->symbol_name, I"!while")) bip = WHILE_BIP;
	if (Str::eq(symb->symbol_name, I"!for")) bip = FOR_BIP;
	if (Str::eq(symb->symbol_name, I"!objectloop")) bip = OBJECTLOOP_BIP;
	if (Str::eq(symb->symbol_name, I"!objectloopx")) bip = OBJECTLOOPX_BIP;
	if (Str::eq(symb->symbol_name, I"!lookup")) bip = LOOKUP_BIP;
	if (Str::eq(symb->symbol_name, I"!lookupbyte")) bip = LOOKUPBYTE_BIP;
	if (Str::eq(symb->symbol_name, I"!lookupref")) bip = LOOKUPREF_BIP;
	if (Str::eq(symb->symbol_name, I"!loop")) bip = LOOP_BIP;
	if (Str::eq(symb->symbol_name, I"!switch")) bip = SWITCH_BIP;
	if (Str::eq(symb->symbol_name, I"!case")) bip = CASE_BIP;
	if (Str::eq(symb->symbol_name, I"!default")) bip = DEFAULT_BIP;
	if (Str::eq(symb->symbol_name, I"!indirect0v")) bip = INDIRECT0V_BIP;
	if (Str::eq(symb->symbol_name, I"!indirect1v")) bip = INDIRECT1V_BIP;
	if (Str::eq(symb->symbol_name, I"!indirect2v")) bip = INDIRECT2V_BIP;
	if (Str::eq(symb->symbol_name, I"!indirect3v")) bip = INDIRECT3V_BIP;
	if (Str::eq(symb->symbol_name, I"!indirect4v")) bip = INDIRECT4V_BIP;
	if (Str::eq(symb->symbol_name, I"!indirect5v")) bip = INDIRECT5V_BIP;
	if (Str::eq(symb->symbol_name, I"!indirect0")) bip = INDIRECT0_BIP;
	if (Str::eq(symb->symbol_name, I"!indirect1")) bip = INDIRECT1_BIP;
	if (Str::eq(symb->symbol_name, I"!indirect2")) bip = INDIRECT2_BIP;
	if (Str::eq(symb->symbol_name, I"!indirect3")) bip = INDIRECT3_BIP;
	if (Str::eq(symb->symbol_name, I"!indirect4")) bip = INDIRECT4_BIP;
	if (Str::eq(symb->symbol_name, I"!indirect5")) bip = INDIRECT5_BIP;
	if (Str::eq(symb->symbol_name, I"!propertyaddress")) bip = PROPERTYADDRESS_BIP;
	if (Str::eq(symb->symbol_name, I"!propertylength")) bip = PROPERTYLENGTH_BIP;
	if (Str::eq(symb->symbol_name, I"!provides")) bip = PROVIDES_BIP;
	if (Str::eq(symb->symbol_name, I"!propertyvalue")) bip = PROPERTYVALUE_BIP;
	if (bip != 0) {
		Inter::Symbols::annotate_i(I, symb, BIP_CODE_IANN, bip);
		return bip;
	}
	return 0;
}

void CodeGen::inv(OUTPUT_STREAM, inter_repository *I, inter_frame P) {
	int suppress_terminal_semicolon = FALSE;
	inter_frame_list *ifl = Inter::Inv::children_of_frame(P);
	if (ifl == NULL) internal_error("cast without code list");

	switch (P.data[METHOD_INV_IFLD]) {
		case INVOKED_PRIMITIVE: {
			inter_symbol *prim = Inter::Inv::invokee(P);
			if (prim == NULL) internal_error("bad prim");
			inter_t bip = CodeGen::built_in_primitive(I, prim);
			switch (bip) {
				case RETURN_BIP: @<Generate primitive for return@>; break;
				case JUMP_BIP: @<Generate primitive for jump@>; break;
				case MOVE_BIP: @<Generate primitive for move@>; break;
				case GIVE_BIP: @<Generate primitive for give@>; break;
				case TAKE_BIP: @<Generate primitive for take@>; break;
				case QUIT_BIP: @<Generate primitive for quit@>; break;
				case BREAK_BIP: @<Generate primitive for break@>; break;
				case CONTINUE_BIP: @<Generate primitive for continue@>; break;
				case NOT_BIP: @<Generate primitive for not@>; break;
				case AND_BIP: @<Generate primitive for and@>; break;
				case OR_BIP: @<Generate primitive for or@>; break;
				case BITWISEAND_BIP: @<Generate primitive for bitwiseand@>; break;
				case BITWISEOR_BIP: @<Generate primitive for bitwiseor@>; break;
				case BITWISENOT_BIP: @<Generate primitive for bitwisenot@>; break;
				case EQ_BIP: @<Generate primitive for eq@>; break;
				case NE_BIP: @<Generate primitive for ne@>; break;
				case GT_BIP: @<Generate primitive for gt@>; break;
				case GE_BIP: @<Generate primitive for ge@>; break;
				case LT_BIP: @<Generate primitive for lt@>; break;
				case LE_BIP: @<Generate primitive for le@>; break;
				case OFCLASS_BIP: @<Generate primitive for ofclass@>; break;
				case HAS_BIP: @<Generate primitive for has@>; break;
				case HASNT_BIP: @<Generate primitive for hasnt@>; break;
				case IN_BIP: @<Generate primitive for in@>; break;
				case NOTIN_BIP: @<Generate primitive for notin@>; break;
				case SEQUENTIAL_BIP: @<Generate primitive for sequential@>; break;
				case TERNARYSEQUENTIAL_BIP: @<Generate primitive for ternarysequential@>; break;
				case PLUS_BIP: @<Generate primitive for plus@>; break;
				case MINUS_BIP: @<Generate primitive for minus@>; break;
				case UNARYMINUS_BIP: @<Generate primitive for unaryminus@>; break;
				case TIMES_BIP: @<Generate primitive for times@>; break;
				case DIVIDE_BIP: @<Generate primitive for divide@>; break;
				case MODULO_BIP: @<Generate primitive for modulo@>; break;
				case RANDOM_BIP: @<Generate primitive for random@>; break;
				case FONT_BIP: @<Generate primitive for font@>; break;
				case STYLEROMAN_BIP: @<Generate primitive for styleroman@>; break;
				case STYLEBOLD_BIP: @<Generate primitive for stylebold@>; break;
				case STYLEUNDERLINE_BIP: @<Generate primitive for styleunderline@>; break;
				case PRINT_BIP: @<Generate primitive for print@>; break;
				case PRINTCHAR_BIP: @<Generate primitive for printchar@>; break;
				case PRINTNAME_BIP: @<Generate primitive for printname@>; break;
				case PRINTNUMBER_BIP: @<Generate primitive for printnumber@>; break;
				case PRINTADDRESS_BIP: @<Generate primitive for printaddress@>; break;
				case PRINTSTRING_BIP: @<Generate primitive for printstring@>; break;
				case PRINTNLNUMBER_BIP: @<Generate primitive for printnlnumber@>; break;
				case PRINTDEF_BIP: @<Generate primitive for printdef@>; break;
				case PRINTCDEF_BIP: @<Generate primitive for printcdef@>; break;
				case PRINTINDEF_BIP: @<Generate primitive for printindef@>; break;
				case PRINTCINDEF_BIP: @<Generate primitive for printcindef@>; break;
				case BOX_BIP: @<Generate primitive for box@>; break;
				case PUSH_BIP: @<Generate primitive for push@>; break;
				case PULL_BIP: @<Generate primitive for pull@>; break;
				case PREINCREMENT_BIP: @<Generate primitive for preincrement@>; break;
				case POSTINCREMENT_BIP: @<Generate primitive for postincrement@>; break;
				case PREDECREMENT_BIP: @<Generate primitive for predecrement@>; break;
				case POSTDECREMENT_BIP: @<Generate primitive for postdecrement@>; break;
				case STORE_BIP: @<Generate primitive for store@>; break;
				case SETBIT_BIP: @<Generate primitive for setbit@>; break;
				case CLEARBIT_BIP: @<Generate primitive for clearbit@>; break;
				case IF_BIP: @<Generate primitive for if@>; break;
				case IFDEBUG_BIP: @<Generate primitive for ifdebug@>; break;
				case IFELSE_BIP: @<Generate primitive for ifelse@>; break;
				case WHILE_BIP: @<Generate primitive for while@>; break;
				case FOR_BIP: @<Generate primitive for for@>; break;
				case OBJECTLOOP_BIP: @<Generate primitive for objectloop@>; break;
				case OBJECTLOOPX_BIP: @<Generate primitive for objectloopx@>; break;
				case LOOP_BIP: @<Generate primitive for loop@>; break;
				case LOOKUP_BIP: @<Generate primitive for lookup@>; break;
				case LOOKUPBYTE_BIP: @<Generate primitive for lookupbyte@>; break;
				case LOOKUPREF_BIP: @<Generate primitive for lookupref@>; break;
				case SWITCH_BIP: @<Generate primitive for switch@>; break;
				case CASE_BIP: @<Generate primitive for case@>; break;
				case DEFAULT_BIP: @<Generate primitive for default@>; break;
				case INDIRECT0V_BIP: @<Generate primitive for indirect0v@>; break;
				case INDIRECT1V_BIP: @<Generate primitive for indirect1v@>; break;
				case INDIRECT2V_BIP: @<Generate primitive for indirect2v@>; break;
				case INDIRECT3V_BIP: @<Generate primitive for indirect3v@>; break;
				case INDIRECT4V_BIP: @<Generate primitive for indirect4v@>; break;
				case INDIRECT5V_BIP: @<Generate primitive for indirect5v@>; break;
				case INDIRECT0_BIP: @<Generate primitive for indirect0@>; break;
				case INDIRECT1_BIP: @<Generate primitive for indirect1@>; break;
				case INDIRECT2_BIP: @<Generate primitive for indirect2@>; break;
				case INDIRECT3_BIP: @<Generate primitive for indirect3@>; break;
				case INDIRECT4_BIP: @<Generate primitive for indirect4@>; break;
				case INDIRECT5_BIP: @<Generate primitive for indirect5@>; break;
				case PROPERTYADDRESS_BIP: @<Generate primitive for propertyaddress@>; break;
				case PROPERTYLENGTH_BIP: @<Generate primitive for propertylength@>; break;
				case PROVIDES_BIP: @<Generate primitive for provides@>; break;
				case PROPERTYVALUE_BIP: @<Generate primitive for propertyvalue@>; break;
				default: LOG("Prim: %S\n", prim->symbol_name); internal_error("unimplemented prim");
			}
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
				CodeGen::frame(OUT, I, F);
			}
			WRITE(")");
			break;
		}
		case INVOKED_OPCODE: {
			inter_t ID = P.data[INVOKEE_INV_IFLD];
			text_stream *S = Inter::get_text(P.repo_segment->owning_repo, ID);
			WRITE("%S", S);
			inter_frame F;
			LOOP_THROUGH_INTER_FRAME_LIST(F, ifl) {
				WRITE(" ");
				CodeGen::frame(OUT, I, F);
			}
			break;
		}
		default: internal_error("bad inv");
	}
	if ((Inter::Defn::get_level(P) == void_level) &&
		(suppress_terminal_semicolon == FALSE)) WRITE(";\n");
}

void CodeGen::cast(OUTPUT_STREAM, inter_repository *I, inter_frame P) {
	inter_frame_list *ifl = Inter::Cast::children_of_frame(P);
	if (ifl == NULL) internal_error("cast without code list");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
}

void CodeGen::lab(OUTPUT_STREAM, inter_repository *I, inter_frame P) {
	inter_package *pack = Inter::Packages::container(P);
	inter_symbol *routine = pack->package_name;
	if (Inter::Package::is(routine) == FALSE) internal_error("bad lab");
	inter_symbol *lab = Inter::SymbolsTables::local_symbol_from_id(routine, P.data[LABEL_LAB_IFLD]);
	if (lab == NULL) internal_error("bad lab");
	text_stream *S = CodeGen::name(lab);
		LOOP_THROUGH_TEXT(pos, S)
			if (Str::get(pos) != '.')
				PUT(Str::get(pos));
}

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
			CodeGen::literal(OUT, IRS->read_into, NULL, NULL, val1, val2, FALSE);
			break;
	}
}

void CodeGen::val(OUTPUT_STREAM, inter_repository *I, inter_frame P) {
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
				CodeGen::literal(OUT, I, NULL, NULL, val1, val2, FALSE);
				return;
		}
	}
	internal_error("bad val");
}

@<Generate primitive for return@> =
	int rboolean = NOT_APPLICABLE;
	inter_frame V = Inter::top_of_frame_list(ifl);
	if (V.data[ID_IFLD] == VAL_IST) {
		inter_t val1 = V.data[VAL1_VAL_IFLD];
		inter_t val2 = V.data[VAL2_VAL_IFLD];
		if (val1 == LITERAL_IVAL) {
			if (val2 == 0) rboolean = FALSE;
			if (val2 == 1) rboolean = TRUE;
		}
	}
	switch (rboolean) {
		case FALSE: WRITE("rfalse"); break;
		case TRUE: WRITE("rtrue"); break;
		case NOT_APPLICABLE: WRITE("return "); CodeGen::frame(OUT, I, V); break;
	}

@<Generate primitive for jump@> =
	WRITE("jump ");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));

@<Generate primitive for quit@> =
	WRITE("quit");

@<Generate primitive for break@> =
	WRITE("break");

@<Generate primitive for continue@> =
	WRITE("continue");

@<Generate primitive for modulo@> =
	WRITE("(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE("%%");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE(")");

@<Generate primitive for random@> =
	WRITE("random(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(")");

@<Generate primitive for font@> =
	WRITE("if (");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(") { font on; } else { font off; }");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for eq@> =
	WRITE("(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE("==");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE(")");

@<Generate primitive for ne@> =
	WRITE("(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(" ~= ");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE(")");

@<Generate primitive for gt@> =
	WRITE("(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(">");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE(")");

@<Generate primitive for ge@> =
	WRITE("(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(">=");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE(")");

@<Generate primitive for lt@> =
	WRITE("(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE("<");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE(")");

@<Generate primitive for le@> =
	WRITE("(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE("<=");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE(")");

@<Generate primitive for ofclass@> =
	WRITE("(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(" ofclass ");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE(")");

@<Generate primitive for move@> =
	WRITE("move ");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(" to ");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));

@<Generate primitive for give@> =
	WRITE("give ");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(" ");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));

@<Generate primitive for take@> =
	WRITE("give ");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(" ~");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));

@<Generate primitive for has@> =
	WRITE("(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(" has ");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE(")");

@<Generate primitive for hasnt@> =
	WRITE("(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(" hasnt ");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE(")");

@<Generate primitive for in@> =
	WRITE("(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(" in ");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE(")");

@<Generate primitive for notin@> =
	WRITE("(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(" notin ");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE(")");

@<Generate primitive for sequential@> =
	WRITE("(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(",");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE(")");

@ Here we need some gymnastics. We need to produce a value which the
sometimes shaky I6 expression parser will accept, which turns out to be
quite a constraint. If we were compiling to C, we might try this:

	|(a, b, c)|

using the serial comma operator -- that is, where the expression |(a, b)|
evaluates |a| then |b| and returns the value of |b|, discarding |a|.
Now I6 does support the comma operator, and this makes a workable scheme,
right up to the point where some of the token values themselves include
invocations of functions, because I6's syntax analyser won't always
allow the serial comma to be mixed in the same expression with the
function argument comma, i.e., I6 is unable properly to handle expressions
like this one:

	|(a(b, c), d)|

where the first comma constructs a list and the second is the operator.
(Many such expressions work fine, but not all.) That being so, the scheme
I actually use is:

	|(c) + 0*((b) + (a))|

Because I6 evaluates the leaves in an expression tree right-to-left, not
left-to-right, the parameter assignments happen first, then the conditions,
then the result.


@<Generate primitive for ternarysequential@> =
	WRITE("(\n"); INDENT;
	WRITE("! This value evaluates third (i.e., last)\n");
	CodeGen::frame(OUT, I, Inter::third_in_frame_list(ifl));
	OUTDENT; WRITE("+\n"); INDENT;
	WRITE("0*(\n"); INDENT;
	WRITE("! The following condition evaluates second\n");
	WRITE("((\n"); INDENT;
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	OUTDENT; WRITE("\n))\n");
	OUTDENT; WRITE("+\n"); INDENT;
	WRITE("! The following assignments evaluate first\n");
	WRITE("(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(")");
	OUTDENT; WRITE(")\n");
	OUTDENT; WRITE(")\n");

@<Generate primitive for plus@> =
	WRITE("(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE("+");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE(")");

@<Generate primitive for not@> =
	WRITE("(~~(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE("))");

@<Generate primitive for and@> =
	WRITE("((");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(")");
	WRITE("&&");
	WRITE("(");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE("))");

@<Generate primitive for or@> =
	WRITE("((");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(")||(");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE("))");


@<Generate primitive for bitwiseand@> =
	WRITE("((");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(")&(");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE("))");

@<Generate primitive for bitwiseor@> =
	WRITE("((");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(")|(");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE("))");

@<Generate primitive for bitwisenot@> =
	WRITE("(~(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE("))");

@<Generate primitive for minus@> =
	WRITE("(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE("-");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE(")");

@<Generate primitive for unaryminus@> =
	WRITE("(-(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE("))");

@<Generate primitive for times@> =
	WRITE("(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE("*");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE(")");

@<Generate primitive for divide@> =
	WRITE("(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE("/");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE(")");

@<Generate primitive for styleroman@> =
	WRITE("style roman");

@<Generate primitive for stylebold@> =
	WRITE("style bold");

@<Generate primitive for styleunderline@> =
	WRITE("style underline");

@<Generate primitive for print@> =
	WRITE("print ");
	CodeGen::enter_print_mode();
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	CodeGen::exit_print_mode();

@<Generate primitive for printchar@> =
	WRITE("print (char) ");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));

@<Generate primitive for printname@> =
	WRITE("print (name) ");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));

@<Generate primitive for printnumber@> =
	WRITE("print ");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));

@<Generate primitive for printaddress@> =
	WRITE("print (address) ");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));

@<Generate primitive for printstring@> =
	WRITE("print (string) ");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));

@<Generate primitive for printnlnumber@> =
	WRITE("print (number) ");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));

@<Generate primitive for printdef@> =
	WRITE("print (the) ");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));

@<Generate primitive for printcdef@> =
	WRITE("print (The) ");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));

@<Generate primitive for printindef@> =
	WRITE("print (a) ");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));

@<Generate primitive for printcindef@> =
	WRITE("print (A) ");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));

@<Generate primitive for box@> =
	WRITE("box ");
	CodeGen::enter_box_mode();
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	CodeGen::exit_box_mode();

@<Generate primitive for push@> =
	WRITE("@push ");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));

@<Generate primitive for pull@> =
	WRITE("@pull ");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));

@<Generate primitive for preincrement@> =
	WRITE("++(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(")");

@<Generate primitive for postincrement@> =
	WRITE("(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(")++");

@<Generate primitive for predecrement@> =
	WRITE("--(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(")");

@<Generate primitive for postdecrement@> =
	WRITE("(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(")--");

@<Generate primitive for store@> =
	WRITE("(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(" = ");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE(")");

@<Generate primitive for setbit@> =
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(" = ");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(" | ");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));

@<Generate primitive for clearbit@> =
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(" = ");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(" &~ (");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE(")");

@<Generate primitive for if@> =
	WRITE("if (");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(") {\n"); INDENT;
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for ifdebug@> =
	WRITE("#ifdef DEBUG;\n"); INDENT;
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	OUTDENT; WRITE("#endif;\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for ifelse@> =
	WRITE("if (");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(") {\n"); INDENT;
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	OUTDENT; WRITE("} else {\n"); INDENT;
	CodeGen::frame(OUT, I, Inter::third_in_frame_list(ifl));
	OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for while@> =
	WRITE("while (");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(") {\n"); INDENT;
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for for@> =
	WRITE("for (");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(":");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE(":");
	inter_frame U = Inter::third_in_frame_list(ifl);
	if (U.data[ID_IFLD] != VAL_IST)
	CodeGen::frame(OUT, I, U);
	WRITE(") {\n"); INDENT;
	CodeGen::frame(OUT, I, Inter::fourth_in_frame_list(ifl));
	OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for objectloop@> =
	int in_flag = FALSE;
	inter_frame U = Inter::third_in_frame_list(ifl);
	if ((U.data[ID_IFLD] == INV_IST) && (U.data[METHOD_INV_IFLD] == INVOKED_PRIMITIVE)) {
		inter_symbol *prim = Inter::Inv::invokee(U);
		if ((prim) && (CodeGen::built_in_primitive(I, prim) == IN_BIP)) in_flag = TRUE;
	}

	WRITE("objectloop ");
	if (in_flag == FALSE) {
		WRITE("(");
		CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
		WRITE(" ofclass ");
		CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
		WRITE(" && ");
	}
	CodeGen::frame(OUT, I, Inter::third_in_frame_list(ifl));
	if (in_flag == FALSE) {
		WRITE(")");
	}
	WRITE(" {\n"); INDENT;
	CodeGen::frame(OUT, I, Inter::fourth_in_frame_list(ifl));
	OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for objectloopx@> =
	WRITE("objectloop (");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(" ofclass ");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE(") {\n"); INDENT;
	CodeGen::frame(OUT, I, Inter::third_in_frame_list(ifl));
	OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for loop@> =
	WRITE("{\n"); INDENT;
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for lookup@> =
	WRITE("(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE("-->");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE(")");

@<Generate primitive for lookupbyte@> =
	WRITE("(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE("->");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE(")");

@<Generate primitive for lookupref@> =
	WRITE("(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE("-->");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE(")");

@<Generate primitive for switch@> =
	WRITE("switch (");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(") {\n"); INDENT;
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for case@> =
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(":\n"); INDENT;
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE(";\n");
	OUTDENT;
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for default@> =
	WRITE("default:\n"); INDENT;
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(";\n");
	OUTDENT;
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for indirect0v@> =
	WRITE("(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(")()");

@<Generate primitive for indirect1v@> =
	WRITE("(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(")(");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE(")");

@<Generate primitive for indirect2v@> =
	WRITE("(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(")(");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE(",");
	CodeGen::frame(OUT, I, Inter::third_in_frame_list(ifl));
	WRITE(")");

@<Generate primitive for indirect3v@> =
	WRITE("(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(")(");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE(",");
	CodeGen::frame(OUT, I, Inter::third_in_frame_list(ifl));
	WRITE(",");
	CodeGen::frame(OUT, I, Inter::fourth_in_frame_list(ifl));
	WRITE(")");

@<Generate primitive for indirect4v@> =
	WRITE("(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(")(");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE(",");
	CodeGen::frame(OUT, I, Inter::third_in_frame_list(ifl));
	WRITE(",");
	CodeGen::frame(OUT, I, Inter::fourth_in_frame_list(ifl));
	WRITE(",");
	CodeGen::frame(OUT, I, Inter::fifth_in_frame_list(ifl));
	WRITE(")");

@<Generate primitive for indirect5v@> =
	WRITE("(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(")(");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE(",");
	CodeGen::frame(OUT, I, Inter::third_in_frame_list(ifl));
	WRITE(",");
	CodeGen::frame(OUT, I, Inter::fourth_in_frame_list(ifl));
	WRITE(",");
	CodeGen::frame(OUT, I, Inter::fifth_in_frame_list(ifl));
	WRITE(",");
	CodeGen::frame(OUT, I, Inter::sixth_in_frame_list(ifl));
	WRITE(")");

@<Generate primitive for indirect0@> =
	WRITE("(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(")()");

@<Generate primitive for indirect1@> =
	WRITE("(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(")(");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE(")");

@<Generate primitive for indirect2@> =
	WRITE("(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(")(");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE(",");
	CodeGen::frame(OUT, I, Inter::third_in_frame_list(ifl));
	WRITE(")");

@<Generate primitive for indirect3@> =
	WRITE("(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(")(");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE(",");
	CodeGen::frame(OUT, I, Inter::third_in_frame_list(ifl));
	WRITE(",");
	CodeGen::frame(OUT, I, Inter::fourth_in_frame_list(ifl));
	WRITE(")");

@<Generate primitive for indirect4@> =
	WRITE("(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(")(");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE(",");
	CodeGen::frame(OUT, I, Inter::third_in_frame_list(ifl));
	WRITE(",");
	CodeGen::frame(OUT, I, Inter::fourth_in_frame_list(ifl));
	WRITE(",");
	CodeGen::frame(OUT, I, Inter::fifth_in_frame_list(ifl));
	WRITE(")");

@<Generate primitive for indirect5@> =
	WRITE("(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(")(");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE(",");
	CodeGen::frame(OUT, I, Inter::third_in_frame_list(ifl));
	WRITE(",");
	CodeGen::frame(OUT, I, Inter::fourth_in_frame_list(ifl));
	WRITE(",");
	CodeGen::frame(OUT, I, Inter::fifth_in_frame_list(ifl));
	WRITE(",");
	CodeGen::frame(OUT, I, Inter::sixth_in_frame_list(ifl));
	WRITE(")");

@<Generate primitive for propertyaddress@> =
	WRITE("(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(".& ");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE(")");

@<Generate primitive for propertylength@> =
	WRITE("(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(".# ");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE(")");

@<Generate primitive for provides@> =
	WRITE("(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(" provides ");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE(")");

@<Generate primitive for propertyvalue@> =
	WRITE("(");
	CodeGen::frame(OUT, I, Inter::top_of_frame_list(ifl));
	WRITE(".");
	CodeGen::frame(OUT, I, Inter::second_in_frame_list(ifl));
	WRITE(")");

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

void CodeGen::append(OUTPUT_STREAM, inter_repository *I, inter_symbol *symb) {
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

void CodeGen::compile_to_I6_text(OUTPUT_STREAM, text_stream *S) {
	WRITE("\"");
	int esc_char = FALSE;
	LOOP_THROUGH_TEXT(pos, S) {
		wchar_t c = Str::get(pos);
		if (box_mode) {
			switch(c) {
				case '@': WRITE("@{40}"); break;
				case '"': WRITE("~"); break;
				case '^': WRITE("@{5E}"); break;
				case '~': WRITE("@{7E}"); break;
				case '\\': WRITE("@{5C}"); break;
				case '\t': WRITE(" "); break;
				case '\n': WRITE("\"\n\""); break;
				case NEWLINE_IN_STRING: WRITE("\"\n\""); break;
				default: PUT(c);
			}
		} else {
			switch(c) {
				case '@':
					if (printing_mode) {
						WRITE("@@64"); esc_char = TRUE; continue;
					}
					WRITE("@{40}"); break;
				case '"': WRITE("~"); break;
				case '^':
					if (printing_mode) {
						WRITE("@@94"); esc_char = TRUE; continue;
					}
					WRITE("@{5E}"); break;
				case '~':
					if (printing_mode) {
						WRITE("@@126"); esc_char = TRUE; continue;
					}
					WRITE("@{7E}"); break;
				case '\\': WRITE("@{5C}"); break;
				case '\t': WRITE(" "); break;
				case '\n': WRITE("^"); break;
				case NEWLINE_IN_STRING: WRITE("^"); break;
				default: {
					if (esc_char) WRITE("@{%02x}", c);
					else PUT(c);
				}
			}
			esc_char = FALSE;
		}
	}
	WRITE("\"");
}
