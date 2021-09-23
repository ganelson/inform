[VanillaCode::] Vanilla Code.

How the vanilla code generation strategy handles the actual code inside functions.

@

=
void VanillaCode::code(code_generation *gen, inter_tree_node *P) {
	int old_level = gen->void_level;
	gen->void_level = Inter::Defn::get_level(P) + 1;
	VNODE_ALLC;
	gen->void_level = old_level;
}

void VanillaCode::block(code_generation *gen, inter_tree_node *P) {
	VNODE_ALLC;
}

void VanillaCode::evaluation(code_generation *gen, inter_tree_node *P) {
	VNODE_ALLC;
}

void VanillaCode::reference(code_generation *gen, inter_tree_node *P) {
	VNODE_ALLC;
}

void VanillaCode::cast(code_generation *gen, inter_tree_node *P) {
	VNODE_ALLC;
}

@

@d URL_SYMBOL_CHAR 0x00A7

=
void VanillaCode::splat(code_generation *gen, inter_tree_node *P) {
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
			WRITE("%S", VanillaConstants::name(symb));
			DISCARD_TEXT(T)
		} else PUT(c);
	}
}

void VanillaCode::label(code_generation *gen, inter_tree_node *P) {
	inter_package *pack = Inter::Packages::container(P);
	inter_symbol *lab_name = InterSymbolsTables::local_symbol_from_id(pack, P->W.data[DEFN_LABEL_IFLD]);
	Generators::place_label(gen, lab_name->symbol_name);
}

void VanillaCode::lab(code_generation *gen, inter_tree_node *P) {
	inter_package *pack = Inter::Packages::container(P);
	inter_symbol *lab = InterSymbolsTables::local_symbol_from_id(pack, P->W.data[LABEL_LAB_IFLD]);
	if (lab == NULL) internal_error("bad lab");
	text_stream *OUT = CodeGen::current(gen);
	text_stream *S = VanillaConstants::name(lab);
	LOOP_THROUGH_TEXT(pos, S)
		if (Str::get(pos) != '.')
			PUT(Str::get(pos));
}

void VanillaCode::val_or_ref(code_generation *gen, inter_tree_node *P, int ref) {
	inter_symbol *val_kind = InterSymbolsTables::symbol_from_frame_data(P, KIND_VAL_IFLD);
	if (val_kind) {
		inter_ti val1 = P->W.data[VAL1_VAL_IFLD];
		inter_ti val2 = P->W.data[VAL2_VAL_IFLD];
		if (Inter::Symbols::is_stored_in_data(val1, val2)) {
			inter_package *pack = Inter::Packages::container(P);
			inter_symbol *symb = InterSymbolsTables::local_symbol_from_id(pack, val2);
			if (symb == NULL) symb = InterSymbolsTables::symbol_from_id(Inter::Packages::scope_of(P), val2);
			if (symb == NULL) internal_error("bad val");
			if ((Str::eq(VanillaConstants::name(symb), I"self")) ||
				((symb->definition) &&
					(symb->definition->W.data[ID_IFLD] == VARIABLE_IST))) {
				Generators::evaluate_variable(gen, symb, (P->W.data[ID_IFLD] == REF_IST)?TRUE:FALSE);
			} else {
				text_stream *OUT = CodeGen::current(gen);
				Generators::mangle(gen, OUT, VanillaConstants::name(symb));
			}
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
				VanillaConstants::literal(gen, NULL, NULL, val1, val2, FALSE);
				return;
		}
	}
	internal_error("bad val");
}

@

@d MAX_OPERANDS_IN_INTER_ASSEMBLY 32

=
void VanillaCode::inv(code_generation *gen, inter_tree_node *P) {
	text_stream *OUT = CodeGen::current(gen);
	int suppress_terminal_semicolon = FALSE;

	switch (P->W.data[METHOD_INV_IFLD]) {
		case INVOKED_PRIMITIVE: {
			inter_symbol *prim = Inter::Inv::invokee(P);
			if (prim == NULL) internal_error("bad prim");
			suppress_terminal_semicolon = Generators::compile_primitive(gen, prim, P);
			break;
		}
		case INVOKED_ROUTINE: {
			inter_symbol *routine = InterSymbolsTables::symbol_from_frame_data(P, INVOKEE_INV_IFLD);
			if (routine == NULL) internal_error("bad routine");
			int argc = 0;
			LOOP_THROUGH_INTER_CHILDREN(F, P) argc++;
			Generators::function_call(gen, routine, P, argc);
			break;
		} 
		case INVOKED_OPCODE: {
			inter_ti ID = P->W.data[INVOKEE_INV_IFLD];
			text_stream *S = Inode::ID_to_text(P, ID);
			inter_tree_node *operands[MAX_OPERANDS_IN_INTER_ASSEMBLY], *label = NULL;
			int operand_count = 0;
			int label_sense = NOT_APPLICABLE;
			LOOP_THROUGH_INTER_CHILDREN(F, P) {
				if (F->W.data[ID_IFLD] == VAL_IST) {
					inter_ti val1 = F->W.data[VAL1_VAL_IFLD];
					inter_ti val2 = F->W.data[VAL2_VAL_IFLD];
					if (Inter::Symbols::is_stored_in_data(val1, val2)) {
						inter_symbol *symb = InterSymbolsTables::symbol_from_id(Inter::Packages::scope_of(F), val2);
						if ((symb) && (Str::eq(symb->symbol_name, I"__assembly_negated_label"))) {
							label_sense = FALSE;
							continue;
						}
					}
				}
				if (F->W.data[ID_IFLD] == LAB_IST) {
					if (label_sense == NOT_APPLICABLE) label_sense = TRUE;
					label = F; continue;
				}
				operands[operand_count++] = F;
			}
			Generators::assembly(gen, S, operand_count, operands, label, label_sense);
			break;
		}
		default: internal_error("bad inv");
	}
	if ((Inter::Defn::get_level(P) == gen->void_level) &&
		(suppress_terminal_semicolon == FALSE)) WRITE(";\n");
}

