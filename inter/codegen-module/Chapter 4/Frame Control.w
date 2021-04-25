[CodeGen::FC::] Frame Control.

To manage the final-code process, at the frame level.

@

=
int query_labels_mode = FALSE, negate_label_mode = FALSE;
int void_level = 3;
code_generation *temporary_generation = NULL;

void CodeGen::FC::prepare(code_generation *gen) {
	query_labels_mode = FALSE;
	negate_label_mode = FALSE;
	void_level = 3;
	temporary_generation = NULL;
}

void CodeGen::FC::iterate(inter_tree *I, inter_tree_node *P, void *state) {
	code_generation *gen = (code_generation *) state;
	inter_package *outer = Inter::Packages::container(P);
	if ((outer == NULL) || (Inter::Packages::is_codelike(outer) == FALSE)) {
		generated_segment *saved =
			CodeGen::select(gen, CodeGen::Targets::general_segment(gen, P));
		switch (P->W.data[ID_IFLD]) {
			case CONSTANT_IST:
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

void CodeGen::FC::frame(code_generation *gen, inter_tree_node *P) {
	switch (P->W.data[ID_IFLD]) {
		case SYMBOL_IST: break;
		case CONSTANT_IST: {
			inter_symbol *con_name =
				InterSymbolsTables::symbol_from_frame_data(P, DEFN_CONST_IFLD);
			if (con_name == NULL) internal_error("no constant");
			if (con_name->metadata_key) break;
			inter_tree *I = gen->from;
			if (Inter::Packages::container(P) == Site::main_package_if_it_exists(I)) {
				WRITE_TO(STDERR, "Bad constant: %S\n", con_name->symbol_name);
				internal_error("constant defined in main");
			}
			if (Inter::Symbols::read_annotation(con_name, TEXT_LITERAL_IANN) == 1) {
				inter_ti ID = P->W.data[DATA_CONST_IFLD];
				text_stream *S = CodeGen::CL::literal_text_at(gen,
					Inode::ID_to_text(P, ID));
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
		case PROPERTYVALUE_IST: CodeGen::IP::write_properties(gen); break;
		case NOP_IST: break;
		case COMMENT_IST: break;
		default:
			Inter::Defn::write_construct_text(DL, P);
			internal_error("unimplemented");
	}
}

@

@d URL_SYMBOL_CHAR 0x00A7

=
void CodeGen::FC::splat(code_generation *gen, inter_tree_node *P) {
	text_stream *OUT = CodeGen::current(gen);
	inter_tree *I = gen->from;
	text_stream *S = Inter::Warehouse::get_text(InterTree::warehouse(I), P->W.data[MATTER_SPLAT_IFLD]);
	int L = Str::len(S);
	for (int i=0; i<L; i++) {
		wchar_t c = Str::get_at(S, i);
		if (c == URL_SYMBOL_CHAR) {
			TEMPORARY_TEXT(T)
			for (i++; i<L; i++) {
				wchar_t c = Str::get_at(S, i);
				if (c == URL_SYMBOL_CHAR) break;
				PUT_TO(T, c);
			}
			inter_symbol *symb = InterSymbolsTables::url_name_to_symbol(I, NULL, T);
			WRITE("%S", CodeGen::CL::name(symb));
			DISCARD_TEXT(T)
		} else PUT(c);
	}
}

void CodeGen::FC::local(code_generation *gen, inter_tree_node *P) {
	inter_package *pack = Inter::Packages::container(P);
	inter_symbol *var_name = InterSymbolsTables::local_symbol_from_id(pack, P->W.data[DEFN_LOCAL_IFLD]);
	CodeGen::Targets::declare_local_variable(gen, P, var_name);
}

void CodeGen::FC::label(code_generation *gen, inter_tree_node *P) {
	text_stream *OUT = CodeGen::current(gen);
	inter_package *pack = Inter::Packages::container(P);
	inter_symbol *lab_name = InterSymbolsTables::local_symbol_from_id(pack, P->W.data[DEFN_LABEL_IFLD]);
	WRITE("%S;\n", lab_name->symbol_name);
}

void CodeGen::FC::block(code_generation *gen, inter_tree_node *P) {
	LOOP_THROUGH_INTER_CHILDREN(F, P)
		CodeGen::FC::frame(gen, F);
}

void CodeGen::FC::code(code_generation *gen, inter_tree_node *P) {
	int old_level = void_level;
	void_level = Inter::Defn::get_level(P) + 1;
	int function_code_block = FALSE;
	inter_tree_node *PAR = InterTree::parent(P);
	if (PAR == NULL) internal_error("misplaced code node");
	if (PAR->W.data[ID_IFLD] == PACKAGE_IST) function_code_block = TRUE;
	text_stream *OUT = CodeGen::current(gen);
	if (function_code_block) { WRITE(";\n"); INDENT; }
	LOOP_THROUGH_INTER_CHILDREN(F, P)
		CodeGen::FC::frame(gen, F);
	void_level = old_level;
	if (function_code_block) { OUTDENT; WRITE("];\n"); }
}

void CodeGen::FC::evaluation(code_generation *gen, inter_tree_node *P) {
	int old_level = void_level;
	LOOP_THROUGH_INTER_CHILDREN(F, P)
		CodeGen::FC::frame(gen, F);
	void_level = old_level;
}

void CodeGen::FC::reference(code_generation *gen, inter_tree_node *P) {
	int old_level = void_level;
	LOOP_THROUGH_INTER_CHILDREN(C, P)
		CodeGen::FC::frame(gen, C);
	void_level = old_level;
}

void CodeGen::FC::cast(code_generation *gen, inter_tree_node *P) {
	LOOP_THROUGH_INTER_CHILDREN(C, P) {
		CodeGen::FC::frame(gen, C);
	}
}

void CodeGen::FC::lab(code_generation *gen, inter_tree_node *P) {
	inter_package *pack = Inter::Packages::container(P);
	inter_symbol *lab = InterSymbolsTables::local_symbol_from_id(pack, P->W.data[LABEL_LAB_IFLD]);
	if (lab == NULL) internal_error("bad lab");
	text_stream *OUT = CodeGen::current(gen);
	if (query_labels_mode) PUT('?');
	if (negate_label_mode) PUT('~');
	text_stream *S = CodeGen::CL::name(lab);
	LOOP_THROUGH_TEXT(pos, S)
		if (Str::get(pos) != '.')
			PUT(Str::get(pos));
}

void CodeGen::FC::val_from(OUTPUT_STREAM, inter_bookmark *IBM, inter_ti val1, inter_ti val2) {
	if (Inter::Symbols::is_stored_in_data(val1, val2)) {
		inter_symbol *symb = InterSymbolsTables::symbol_from_data_pair_and_table(
			val1, val2, Inter::Bookmarks::scope(IBM));
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
					CodeGen::new_generation(NULL, Inter::Bookmarks::tree(IBM), NULL, CodeGen::I6::target());
			}
			CodeGen::select_temporary(temporary_generation, OUT);
			CodeGen::CL::literal(temporary_generation, NULL, NULL, val1, val2, FALSE);
			CodeGen::deselect_temporary(temporary_generation);
			break;
	}
}

void CodeGen::FC::val(code_generation *gen, inter_tree_node *P) {
	inter_symbol *val_kind = InterSymbolsTables::symbol_from_frame_data(P, KIND_VAL_IFLD);
	if (val_kind) {
		inter_ti val1 = P->W.data[VAL1_VAL_IFLD];
		inter_ti val2 = P->W.data[VAL2_VAL_IFLD];
		if (Inter::Symbols::is_stored_in_data(val1, val2)) {
			inter_package *pack = Inter::Packages::container(P);
			inter_symbol *symb = InterSymbolsTables::local_symbol_from_id(pack, val2);
			if (symb == NULL) symb = InterSymbolsTables::symbol_from_id(Inter::Packages::scope_of(P), val2);
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

@d INV_A1 CodeGen::FC::frame(gen, InterTree::first_child(P))
@d INV_A1_PRINTMODE CodeGen::CL::enter_print_mode(); INV_A1; CodeGen::CL::exit_print_mode();
@d INV_A1_BOXMODE CodeGen::CL::enter_box_mode(); INV_A1; CodeGen::CL::exit_box_mode();
@d INV_A2 CodeGen::FC::frame(gen, InterTree::second_child(P))
@d INV_A3 CodeGen::FC::frame(gen, InterTree::third_child(P))
@d INV_A4 CodeGen::FC::frame(gen, InterTree::fourth_child(P))
@d INV_A5 CodeGen::FC::frame(gen, InterTree::fifth_child(P))
@d INV_A6 CodeGen::FC::frame(gen, InterTree::sixth_child(P))

=
void CodeGen::FC::inv(code_generation *gen, inter_tree_node *P) {
	text_stream *OUT = CodeGen::current(gen);
	int suppress_terminal_semicolon = FALSE;

	switch (P->W.data[METHOD_INV_IFLD]) {
		case INVOKED_PRIMITIVE: {
			inter_symbol *prim = Inter::Inv::invokee(P);
			if (prim == NULL) internal_error("bad prim");
			suppress_terminal_semicolon = CodeGen::Targets::compile_primitive(gen, prim, P);
			break;
		}
		case INVOKED_ROUTINE: {
			inter_symbol *routine = InterSymbolsTables::symbol_from_frame_data(P, INVOKEE_INV_IFLD);
			if (routine == NULL) internal_error("bad routine");
			WRITE("%S(", CodeGen::CL::name(routine));
			int argc = 0;
			LOOP_THROUGH_INTER_CHILDREN(F, P) {
				if (argc++ > 0) WRITE(", ");
				CodeGen::FC::frame(gen, F);
			}
			WRITE(")");
			break;
		}
		case INVOKED_OPCODE: {
			inter_ti ID = P->W.data[INVOKEE_INV_IFLD];
			text_stream *S = Inode::ID_to_text(P, ID);
			WRITE("%S", S);
			negate_label_mode = FALSE;
			LOOP_THROUGH_INTER_CHILDREN(F, P) {
				query_labels_mode = TRUE;
				if (F->W.data[ID_IFLD] == VAL_IST) {
					inter_ti val1 = F->W.data[VAL1_VAL_IFLD];
					inter_ti val2 = F->W.data[VAL2_VAL_IFLD];
					if (Inter::Symbols::is_stored_in_data(val1, val2)) {
						inter_symbol *symb = InterSymbolsTables::symbol_from_id(Inter::Packages::scope_of(F), val2);
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

