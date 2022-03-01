[PackageTypeInstruction::] The PackageType Construct.

Defining the packagetype construct.

@


=
void PackageTypeInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(PACKAGETYPE_IST, I"packagetype");
	InterInstruction::defines_symbol_in_fields(IC, DEFN_PTYPE_IFLD, -1);
	InterInstruction::specify_syntax(IC, I"packagetype _IDENTIFIER");
	InterInstruction::fix_instruction_length_between(IC, EXTENT_PTYPE_IFR, EXTENT_PTYPE_IFR);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, PackageTypeInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, PackageTypeInstruction::write);
	InterInstruction::permit(IC, OUTSIDE_OF_PACKAGES_ICUP);
}

@

@d DEFN_PTYPE_IFLD 2

@d EXTENT_PTYPE_IFR 3

=
void PackageTypeInstruction::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	inter_symbol *ptype_name = TextualInter::new_symbol(eloc, InterBookmark::scope(IBM), ilp->mr.exp[0], E);
	if (*E) return;

	*E = PackageTypeInstruction::new_packagetype(IBM, ptype_name, (inter_ti) ilp->indent_level, eloc);
}

inter_error_message *PackageTypeInstruction::new_packagetype(inter_bookmark *IBM, inter_symbol *ptype, inter_ti level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_1_data_field(IBM, PACKAGETYPE_IST, InterSymbolsTable::id_from_symbol_at_bookmark(IBM, ptype), eloc, level);
	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), P);
	if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void PackageTypeInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	inter_symbol *ptype_name = InterSymbolsTable::symbol_from_ID_at_node(P, DEFN_PTYPE_IFLD);
	if (ptype_name) WRITE("packagetype %S", InterSymbol::identifier(ptype_name));
	else { *E = Inode::error(P, I"cannot write packagetype", NULL); return; }
}
