[CodeGen::FC::] Frame Control.

To manage the final-code process, at the frame level.

@

@ =
int query_labels_mode = FALSE, negate_label_mode = FALSE;
int void_level = 3;
code_generation *temporary_generation = NULL;

void CodeGen::FC::prepare(code_generation *gen) {
	query_labels_mode = FALSE;
	negate_label_mode = FALSE;
	void_level = 3;
	temporary_generation = NULL;
}

void CodeGen::FC::iterate(code_generation *gen) {
	inter_repository *I = gen->from;
	if (I) {
		inter_frame P;
		LOOP_THROUGH_FRAMES(P, I) {
			inter_package *outer = Inter::Packages::container(P);
			if ((outer == NULL) || (outer->codelike_package == FALSE)) {
				generated_segment *saved =
					CodeGen::select(gen, CodeGen::Targets::general_segment(gen, P));
				switch (P.data[ID_IFLD]) {
					case CONSTANT_IST:
					case PRAGMA_IST:
					case INSTANCE_IST:
					case PROPERTYVALUE_IST:
					case VARIABLE_IST:
					case SPLAT_IST:
						CodeGen::FC::frame(gen, P);
						break;
				}
				CodeGen::deselect(gen, saved);
			}
		}
	}
}

void CodeGen::FC::frame(code_generation *gen, inter_frame P) {
	switch (P.data[ID_IFLD]) {
		case SYMBOL_IST: break;
		case CONSTANT_IST: {
			inter_package *outer = Inter::Packages::container(P);
			inter_symbol *con_name =
				Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_CONST_IFLD);
			if ((outer) && (CodeGen::Eliminate::gone(outer->package_name)) && (Inter::Constant::code_block(con_name) == NULL)) {
				LOG("Yeah, so reject $3\n", outer->package_name);
				return;
			}
			if (Inter::Symbols::read_annotation(con_name, OBJECT_IANN) == 1) break;
			inter_repository *I = gen->from;
			if (Inter::Packages::container(P) == Inter::Packages::main(I)) {
				WRITE_TO(STDERR, "Bad constant: %S\n", con_name->symbol_name);
				internal_error("constant defined in main");
			}
			if (Inter::Symbols::read_annotation(con_name, TEXT_LITERAL_IANN) == 1) {
				inter_t ID = P.data[DATA_CONST_IFLD];
				text_stream *S = CodeGen::CL::literal_text_at(gen,
					Inter::get_text(P.repo_segment->owning_repo, ID));
				CodeGen::select_temporary(gen, S);
				CodeGen::CL::constant(gen, P);
				CodeGen::deselect_temporary(gen);
			} else {
				CodeGen::CL::constant(gen, P);
			}
			break;
		}
		case VARIABLE_IST: CodeGen::Var::knowledge(gen); break;
		case INSTANCE_IST: CodeGen::IP::instance(gen, P); break;
		case SPLAT_IST: CodeGen::FC::splat(gen, P); break;
		case LOCAL_IST: CodeGen::FC::local(gen, P); break;
		case LABEL_IST: CodeGen::FC::label(gen, P); break;
		case CODE_IST: CodeGen::FC::code(gen, P); break;
		case EVALUATION_IST: CodeGen::FC::evaluation(gen, P); break;
		case REFERENCE_IST: CodeGen::FC::reference(gen, P); break;
		case PACKAGE_IST: CodeGen::FC::block(gen, P); break;
		case INV_IST: CodeGen::FC::inv(gen, P); break;
		case CAST_IST: CodeGen::FC::cast(gen, P); break;
		case VAL_IST:
		case REF_IST: CodeGen::FC::val(gen, P); break;
		case LAB_IST: CodeGen::FC::lab(gen, P); break;
		case PRAGMA_IST: CodeGen::FC::pragma(gen, P); break;
		case PROPERTYVALUE_IST: CodeGen::IP::write_properties(gen); break;
		case NOP_IST: break;
		default:
			Inter::Defn::write_construct_text(DL, P);
			internal_error("unimplemented\n");
	}
}

void CodeGen::FC::pragma(code_generation *gen, inter_frame P) {
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
void CodeGen::FC::splat(code_generation *gen, inter_frame P) {
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
			WRITE("%S", CodeGen::CL::name(symb));
			DISCARD_TEXT(T);
		} else PUT(c);
	}
}

void CodeGen::FC::local(code_generation *gen, inter_frame P) {
	inter_package *pack = Inter::Packages::container(P);
	inter_symbol *routine = pack->package_name;
	inter_symbol *var_name = Inter::SymbolsTables::local_symbol_from_id(routine, P.data[DEFN_LOCAL_IFLD]);
	CodeGen::Targets::declare_local_variable(gen, P, var_name);
}

void CodeGen::FC::label(code_generation *gen, inter_frame P) {
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
		CodeGen::FC::frame(gen, F);
}

void CodeGen::FC::block(code_generation *gen, inter_frame P) {
	inter_symbol *block = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_PACKAGE_IFLD);
	inter_frame_list *ifl = Inter::Package::code_list(block);
	if (ifl == NULL) internal_error("block without code list");
	inter_frame F;
	LOOP_THROUGH_INTER_FRAME_LIST(F, ifl)
		CodeGen::FC::frame(gen, F);
}

void CodeGen::FC::code(code_generation *gen, inter_frame P) {
	int old_level = void_level;
	void_level = Inter::Defn::get_level(P) + 1;
	inter_frame_list *ifl = Inter::find_frame_list(P.repo_segment->owning_repo, P.data[CODE_CODE_IFLD]);
	if (ifl) {
		inter_frame F;
		LOOP_THROUGH_INTER_FRAME_LIST(F, ifl)
			CodeGen::FC::frame(gen, F);
	}
	void_level = old_level;
}

void CodeGen::FC::evaluation(code_generation *gen, inter_frame P) {
	int old_level = void_level;
	inter_frame_list *ifl = Inter::find_frame_list(P.repo_segment->owning_repo, P.data[CODE_EVAL_IFLD]);
	if (ifl) {
		inter_frame F;
		LOOP_THROUGH_INTER_FRAME_LIST(F, ifl)
			CodeGen::FC::frame(gen, F);
	}
	void_level = old_level;
}

void CodeGen::FC::reference(code_generation *gen, inter_frame P) {
	int old_level = void_level;
	inter_frame_list *ifl = Inter::find_frame_list(P.repo_segment->owning_repo, P.data[CODE_RCE_IFLD]);
	if (ifl) {
		inter_frame F;
		LOOP_THROUGH_INTER_FRAME_LIST(F, ifl)
			CodeGen::FC::frame(gen, F);
	}
	void_level = old_level;
}

void CodeGen::FC::cast(code_generation *gen, inter_frame P) {
	inter_frame_list *ifl = Inter::Cast::children_of_frame(P);
	if (ifl == NULL) internal_error("cast without code list");
	CodeGen::FC::frame(gen, Inter::top_of_frame_list(ifl));
}

void CodeGen::FC::lab(code_generation *gen, inter_frame P) {
	inter_package *pack = Inter::Packages::container(P);
	inter_symbol *routine = pack->package_name;
	if (Inter::Package::is(routine) == FALSE) internal_error("bad lab");
	inter_symbol *lab = Inter::SymbolsTables::local_symbol_from_id(routine, P.data[LABEL_LAB_IFLD]);
	if (lab == NULL) internal_error("bad lab");
	text_stream *OUT = CodeGen::current(gen);
	if (query_labels_mode) PUT('?');
	if (negate_label_mode) PUT('~');
	text_stream *S = CodeGen::CL::name(lab);
	LOOP_THROUGH_TEXT(pos, S)
		if (Str::get(pos) != '.')
			PUT(Str::get(pos));
}

void CodeGen::FC::val_from(OUTPUT_STREAM, inter_reading_state *IRS, inter_t val1, inter_t val2) {
	if (Inter::Symbols::is_stored_in_data(val1, val2)) {
		inter_symbol *symb = Inter::SymbolsTables::symbol_from_data_pair_and_table(
			val1, val2, Inter::Bookmarks::scope(IRS));
		if (symb == NULL) internal_error("bad symbol");
		WRITE("%S", CodeGen::CL::name(symb));
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
				temporary_generation =
					CodeGen::new_generation(NULL, IRS->read_into, NULL, CodeGen::I6::target());
			}
			CodeGen::select_temporary(temporary_generation, OUT);
			CodeGen::CL::literal(temporary_generation, NULL, NULL, val1, val2, FALSE);
			CodeGen::deselect_temporary(temporary_generation);
			break;
	}
}

void CodeGen::FC::val(code_generation *gen, inter_frame P) {
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
			WRITE("%S", CodeGen::CL::name(symb));
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
				CodeGen::CL::literal(gen, NULL, NULL, val1, val2, FALSE);
				return;
		}
	}
	internal_error("bad val");
}

@

@d INV_A1 CodeGen::FC::frame(gen, Inter::top_of_frame_list(ifl))
@d INV_A1_PRINTMODE CodeGen::CL::enter_print_mode(); INV_A1; CodeGen::CL::exit_print_mode();
@d INV_A1_BOXMODE CodeGen::CL::enter_box_mode(); INV_A1; CodeGen::CL::exit_box_mode();
@d INV_A2 CodeGen::FC::frame(gen, Inter::second_in_frame_list(ifl))
@d INV_A3 CodeGen::FC::frame(gen, Inter::third_in_frame_list(ifl))
@d INV_A4 CodeGen::FC::frame(gen, Inter::fourth_in_frame_list(ifl))
@d INV_A5 CodeGen::FC::frame(gen, Inter::fifth_in_frame_list(ifl))
@d INV_A6 CodeGen::FC::frame(gen, Inter::sixth_in_frame_list(ifl))

=
void CodeGen::FC::inv(code_generation *gen, inter_frame P) {
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
			WRITE("%S(", CodeGen::CL::name(routine));
			inter_frame F;
			int argc = 0;
			LOOP_THROUGH_INTER_FRAME_LIST(F, ifl) {
				if (argc++ > 0) WRITE(", ");
				CodeGen::FC::frame(gen, F);
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
				CodeGen::FC::frame(gen, F);
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

