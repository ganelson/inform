[Inter::Lab::] The Lab Construct.

Defining the Lab construct.

@

@e LAB_IST

=
void Inter::Lab::define(void) {
	inter_construct *IC = InterConstruct::create_construct(LAB_IST, I"lab");
	InterConstruct::specify_syntax(IC, I"lab .IDENTIFIER");
	InterConstruct::allow_in_depth_range(IC, 1, INFINITELY_DEEP);
	InterConstruct::permit(IC, INSIDE_CODE_PACKAGE_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::Lab::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, Inter::Lab::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::Lab::write);
}

@

@d BLOCK_LAB_IFLD 2
@d LABEL_LAB_IFLD 3

@d EXTENT_LAB_IFR 4

=
void Inter::Lab::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	if (SymbolAnnotation::nonempty(&(ilp->set))) { *E = Inter::Errors::plain(I"__annotations are not allowed", eloc); return; }

	*E = InterConstruct::check_level_in_package(IBM, LAB_IST, ilp->indent_level, eloc);
	if (*E) return;

	inter_package *routine = TextualInter::get_latest_block_package();
	if (routine == NULL) { *E = Inter::Errors::plain(I"'lab' used outside function", eloc); return; }
	inter_symbols_table *locals = InterPackage::scope(routine);
	if (locals == NULL) { *E = Inter::Errors::plain(I"function has no symbols table", eloc); return; }

	inter_symbol *label = InterSymbolsTable::symbol_from_name(locals, ilp->mr.exp[0]);
	if (InterSymbol::is_label(label) == FALSE) { *E = Inter::Errors::plain(I"not a label", eloc); return; }

	*E = Inter::Lab::new(IBM, label, (inter_ti) ilp->indent_level, eloc);
}

inter_error_message *Inter::Lab::new(inter_bookmark *IBM, inter_symbol *label, inter_ti level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_2_data_fields(IBM, LAB_IST, 0, InterSymbolsTable::id_from_symbol_at_bookmark(IBM, label), eloc, (inter_ti) level);
	inter_error_message *E = InterConstruct::verify_construct(InterBookmark::package(IBM), P); if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void Inter::Lab::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	if (P->W.extent != EXTENT_LAB_IFR) { *E = Inode::error(P, I"extent wrong", NULL); return; }
	inter_symbol *label = InterSymbolsTable::symbol_from_ID_in_package(owner, P->W.instruction[LABEL_LAB_IFLD]);
	if (InterSymbol::is_label(label) == FALSE) { *E = Inode::error(P, I"no such label", NULL); return; }
}

void Inter::Lab::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	inter_package *pack = InterPackage::container(P);
	inter_symbol *label = InterSymbolsTable::symbol_from_ID_in_package(pack, P->W.instruction[LABEL_LAB_IFLD]);
	if (label) {
		WRITE("lab %S", label->symbol_name);
	} else { *E = Inode::error(P, I"cannot write lab", NULL); return; }
}

inter_symbol *Inter::Lab::label_symbol(inter_tree_node *P) {
	inter_package *pack = InterPackage::container(P);
	inter_symbol *lab = InterSymbolsTable::symbol_from_ID_in_package(pack, P->W.instruction[LABEL_LAB_IFLD]);
	if (lab == NULL) internal_error("bad lab");
	return lab;
}
