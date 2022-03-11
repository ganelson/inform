[PropertyInstruction::] The Property Construct.

Defining the property construct.

@h Definition.
For what this does and why it is used, see //inter: Textual Inter//.

=
void PropertyInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(PROPERTY_IST, I"property");
	InterInstruction::defines_symbol_in_fields(IC, DEFN_PROP_IFLD, TYPE_PROP_IFLD);
	InterInstruction::specify_syntax(IC, I"property TOKENS");
	InterInstruction::fix_instruction_length_between(IC, 5, 5);
	InterInstruction::permit(IC, INSIDE_PLAIN_PACKAGE_ICUP);
	InterInstruction::permit(IC, CAN_HAVE_ANNOTATIONS_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, PropertyInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_TRANSPOSE_MTID, PropertyInstruction::transpose);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, PropertyInstruction::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, PropertyInstruction::write);
}

@h Instructions.
In bytecode, the frame of a |property| instruction is laid out with the two
compulsory words |ID_IFLD| and |LEVEL_IFLD|, followed by:

@d DEFN_PROP_IFLD 2
@d TYPE_PROP_IFLD 3
@d PERM_LIST_PROP_IFLD 4

=
inter_error_message *PropertyInstruction::new(inter_bookmark *IBM, inter_symbol *prop_s,
	inter_type prop_type, inter_ti level, inter_error_location *eloc) {
	inter_package *pack = InterBookmark::package(IBM);
	inter_warehouse *warehouse = InterBookmark::warehouse(IBM);
	inter_tree_node *P = Inode::new_with_3_data_fields(IBM, PROPERTY_IST,
		/* DEFN_PROP_IFLD: */      InterSymbolsTable::id_from_symbol_at_bookmark(IBM, prop_s),
		/* TYPE_PROP_IFLD: */      InterTypes::to_TID_at(IBM, prop_type),
		/* PERM_LIST_PROP_IFLD: */ InterWarehouse::create_node_list(warehouse, pack),
		eloc, level);
	inter_error_message *E = VerifyingInter::instruction(pack, P);
	if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void PropertyInstruction::transpose(inter_construct *IC, inter_tree_node *P,
	inter_ti *grid, inter_ti grid_extent, inter_error_message **E) {
	P->W.instruction[PERM_LIST_PROP_IFLD] = grid[P->W.instruction[PERM_LIST_PROP_IFLD]];
}

@ Verification consists only of sanity checks.

=
void PropertyInstruction::verify(inter_construct *IC, inter_tree_node *P,
	inter_package *owner, inter_error_message **E) {
	*E = VerifyingInter::TID_field(owner, P, TYPE_PROP_IFLD);
	if (*E) return;
	*E = VerifyingInter::node_list_field(owner, P, PERM_LIST_PROP_IFLD);
	if (*E) return;
}

@h Creating from textual Inter syntax.

=
void PropertyInstruction::read(inter_construct *IC, inter_bookmark *IBM,
	inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	text_stream *type_text = NULL, *name_text = ilp->mr.exp[0];
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, name_text, L"%((%c+)%) (%c+)")) {
		type_text = mr.exp[0]; name_text = mr.exp[1];
	}
	inter_symbols_table *scope = InterBookmark::scope(IBM);
	inter_symbol *prop_name = TextualInter::new_symbol(eloc, scope, name_text, E);
	inter_type prop_type = InterTypes::unchecked();
	if (*E == NULL) prop_type = InterTypes::parse_simple(scope, eloc, type_text, E);
	Regexp::dispose_of(&mr);
	if (*E) return;

	SymbolAnnotation::copy_set_to_symbol(&(ilp->set), prop_name);
	*E = PropertyInstruction::new(IBM, prop_name, prop_type,
		(inter_ti) ilp->indent_level, eloc);
}

@h Writing to textual Inter syntax.

=
void PropertyInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P,
	inter_error_message **E) {
	inter_symbol *prop_name = InterSymbolsTable::symbol_from_ID_at_node(P, DEFN_PROP_IFLD);
	WRITE("property ");
	TextualInter::write_optional_type_marker(OUT, P, TYPE_PROP_IFLD);
	WRITE("%S", InterSymbol::identifier(prop_name));
	SymbolAnnotation::write_annotations(OUT, P, prop_name);
}

@h Access functions.

=
inter_symbol *PropertyInstruction::property(inter_tree_node *P) {
	if (P == NULL) return NULL;
	if (P->W.instruction[ID_IFLD] != PROPERTY_IST) return NULL;
	return InterSymbolsTable::symbol_from_ID_at_node(P, DEFN_PROP_IFLD);
}

inter_ti PropertyInstruction::permissions_list(inter_symbol *prop_name) {
	if (prop_name == NULL) return 0;
	inter_tree_node *D = InterSymbol::definition(prop_name);
	if (D == NULL) return 0;
	return D->W.instruction[PERM_LIST_PROP_IFLD];
}
