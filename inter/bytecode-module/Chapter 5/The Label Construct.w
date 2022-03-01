[LabelInstruction::] The Label Construct.

Defining the label construct.

@


=
void LabelInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(LABEL_IST, I"label");
	InterInstruction::defines_symbol_in_fields(IC, DEFN_LABEL_IFLD, -1);
	InterInstruction::specify_syntax(IC, I".IDENTIFIER");
	InterInstruction::fix_instruction_length_between(IC, EXTENT_LABEL_IFR, EXTENT_LABEL_IFR);
	InterInstruction::allow_in_depth_range(IC, 0, INFINITELY_DEEP);
	InterInstruction::permit(IC, INSIDE_CODE_PACKAGE_ICUP);
	InterInstruction::permit(IC, CAN_HAVE_CHILDREN_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, LabelInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, LabelInstruction::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, LabelInstruction::write);
}

@

@d BLOCK_LABEL_IFLD 2
@d DEFN_LABEL_IFLD 3

@d EXTENT_LABEL_IFR 4

=
void LabelInstruction::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	inter_package *routine = InterBookmark::package(IBM);
	if (routine == NULL) { *E = InterErrors::plain(I"'label' used outside function", eloc); return; }
	inter_symbols_table *locals = InterPackage::scope(routine);
	if (locals == NULL) { *E = InterErrors::plain(I"function has no symbols table", eloc); return; }

	inter_symbol *lab_name = InterSymbolsTable::symbol_from_name(locals, ilp->mr.exp[0]);
	if (lab_name == NULL) {
		lab_name = TextualInter::new_symbol(eloc, locals, ilp->mr.exp[0], E);
		if (*E) return;
	} else if (InterSymbol::is_defined(lab_name)) {
		*E = InterErrors::plain(I"label defined in function once already", eloc);
		return;
	}
	InterSymbol::make_label(lab_name);
	*E = LabelInstruction::new(IBM, lab_name, (inter_ti) ilp->indent_level, eloc);
}

inter_error_message *LabelInstruction::new(inter_bookmark *IBM, inter_symbol *lab_name, inter_ti level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_2_data_fields(IBM, LABEL_IST, 0, InterSymbolsTable::id_from_symbol_at_bookmark(IBM, lab_name), eloc, level);
	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), P); if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void LabelInstruction::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	inter_symbol *lab_name = InterSymbolsTable::symbol_from_ID_in_package(owner, P->W.instruction[DEFN_LABEL_IFLD]);
	if (InterSymbol::is_label(lab_name) == FALSE) {
		*E = Inode::error(P, I"not a label", (lab_name)?(InterSymbol::identifier(lab_name)):NULL);
		return;
	}
	if (P->W.instruction[LEVEL_IFLD] < 1) { *E = Inode::error(P, I"label with bad level", NULL); return; }
}

void LabelInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	inter_package *pack = InterPackage::container(P);
	inter_symbol *lab_name = InterSymbolsTable::symbol_from_ID_in_package(pack, P->W.instruction[DEFN_LABEL_IFLD]);
	if (lab_name) {
		WRITE("%S", InterSymbol::identifier(lab_name));
	} else { *E = Inode::error(P, I"cannot write label", NULL); return; }
}
