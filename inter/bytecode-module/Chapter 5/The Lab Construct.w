[LabInstruction::] The Lab Construct.

Defining the Lab construct.

@


=
void LabInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(LAB_IST, I"lab");
	InterInstruction::specify_syntax(IC, I"lab .IDENTIFIER");
	InterInstruction::fix_instruction_length_between(IC, EXTENT_LAB_IFR, EXTENT_LAB_IFR);
	InterInstruction::allow_in_depth_range(IC, 1, INFINITELY_DEEP);
	InterInstruction::permit(IC, INSIDE_CODE_PACKAGE_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, LabInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, LabInstruction::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, LabInstruction::write);
}

@

@d BLOCK_LAB_IFLD 2
@d LABEL_LAB_IFLD 3

@d EXTENT_LAB_IFR 4

=
void LabInstruction::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	inter_package *routine = InterBookmark::package(IBM);
	if (routine == NULL) { *E = InterErrors::plain(I"'lab' used outside function", eloc); return; }
	inter_symbols_table *locals = InterPackage::scope(routine);
	if (locals == NULL) { *E = InterErrors::plain(I"function has no symbols table", eloc); return; }

	inter_symbol *label = InterSymbolsTable::symbol_from_name(locals, ilp->mr.exp[0]);
	if (label == NULL) {
		label = TextualInter::new_symbol(eloc, locals, ilp->mr.exp[0], E);
		if (*E) return;
		InterSymbol::make_label(label);
	}
	if (InterSymbol::is_label(label) == FALSE) { *E = InterErrors::plain(I"not a label", eloc); return; }

	*E = LabInstruction::new(IBM, label, (inter_ti) ilp->indent_level, eloc);
}

inter_error_message *LabInstruction::new(inter_bookmark *IBM, inter_symbol *label, inter_ti level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_2_data_fields(IBM, LAB_IST, 0, InterSymbolsTable::id_from_symbol_at_bookmark(IBM, label), eloc, (inter_ti) level);
	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), P); if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void LabInstruction::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	inter_symbol *label = InterSymbolsTable::symbol_from_ID_in_package(owner, P->W.instruction[LABEL_LAB_IFLD]);
	if (InterSymbol::is_label(label) == FALSE) { *E = Inode::error(P, I"no such label", NULL); return; }
}

void LabInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	inter_package *pack = InterPackage::container(P);
	inter_symbol *label = InterSymbolsTable::symbol_from_ID_in_package(pack, P->W.instruction[LABEL_LAB_IFLD]);
	if (label) {
		WRITE("lab %S", InterSymbol::identifier(label));
	} else { *E = Inode::error(P, I"cannot write lab", NULL); return; }
}

inter_symbol *LabInstruction::label_symbol(inter_tree_node *P) {
	inter_package *pack = InterPackage::container(P);
	inter_symbol *lab = InterSymbolsTable::symbol_from_ID_in_package(pack, P->W.instruction[LABEL_LAB_IFLD]);
	if (lab == NULL) internal_error("bad lab");
	return lab;
}
