[PackageTypeInstruction::] The PackageType Construct.

Defining the packagetype construct.

@h Definition.
For what this does and why it is used, see //inter: Textual Inter//.

=
void PackageTypeInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(PACKAGETYPE_IST, I"packagetype");
	InterInstruction::defines_symbol_in_fields(IC, DEFN_PTYPE_IFLD, -1);
	InterInstruction::specify_syntax(IC, I"packagetype _IDENTIFIER");
	InterInstruction::fix_instruction_length_between(IC, 3, 3);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, PackageTypeInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, PackageTypeInstruction::write);
	InterInstruction::permit(IC, OUTSIDE_OF_PACKAGES_ICUP);
}

@h Instructions.
In bytecode, the frame of a |packagetype| instruction is laid out with the two
compulsory words |ID_IFLD| and |LEVEL_IFLD|, followed by:

@d DEFN_PTYPE_IFLD 2

=
inter_error_message *PackageTypeInstruction::new(inter_bookmark *IBM, inter_symbol *ptype,
	inter_ti level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_1_data_field(IBM, PACKAGETYPE_IST,
		/* DEFN_PTYPE_IFLD: */ InterSymbolsTable::id_at_bookmark(IBM, ptype),
		eloc, level);
	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), P);
	if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

@h Creating from textual Inter syntax.

=
void PackageTypeInstruction::read(inter_construct *IC, inter_bookmark *IBM,
	inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	inter_symbol *ptype_name =
		TextualInter::new_symbol(eloc, InterBookmark::scope(IBM), ilp->mr.exp[0], E);
	if (*E) return;

	*E = PackageTypeInstruction::new(IBM, ptype_name, (inter_ti) ilp->indent_level, eloc);
}

@h Writing to textual Inter syntax.

=
void PackageTypeInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P) {
	inter_symbol *ptype_name = InterSymbolsTable::symbol_from_ID_at_node(P, DEFN_PTYPE_IFLD);
	WRITE("packagetype %S", InterSymbol::identifier(ptype_name));
}
