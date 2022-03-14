[LocalInstruction::] The Local Construct.

Defining the local construct.

@h Definition.
For what this does and why it is used, see //inter: Textual Inter//.

=
void LocalInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(LOCAL_IST, I"local");
	InterInstruction::defines_symbol_in_fields(IC, DEFN_LOCAL_IFLD, TYPE_LOCAL_IFLD);
	InterInstruction::specify_syntax(IC, I"local TOKENS");
	InterInstruction::data_extent_always(IC, 2);
	InterInstruction::permit(IC, INSIDE_CODE_PACKAGE_ICUP);
	InterInstruction::permit(IC, CAN_HAVE_ANNOTATIONS_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, LocalInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, LocalInstruction::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, LocalInstruction::write);
}

@h Instructions.
In bytecode, the frame of a |local| instruction is laid out with the
compulsory words -- see //Inter Nodes// -- followed by:

@d DEFN_LOCAL_IFLD (DATA_IFLD + 0)
@d TYPE_LOCAL_IFLD (DATA_IFLD + 1)

=
inter_error_message *LocalInstruction::new(inter_bookmark *IBM, inter_symbol *variable_s,
	inter_type var_type, inter_ti level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_2_data_fields(IBM, LOCAL_IST,
		/* DEFN_LOCAL_IFLD: */ InterSymbolsTable::id_at_bookmark(IBM, variable_s),
		/* TYPE_LOCAL_IFLD: */ InterTypes::to_TID_at(IBM, var_type), 
		eloc, level);
	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), P);
	if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

@ Verification consists only of sanity checks.

=
void LocalInstruction::verify(inter_construct *IC, inter_tree_node *P,
	inter_package *owner, inter_error_message **E) {
	*E = VerifyingInter::TID_field(owner, P, TYPE_LOCAL_IFLD);
}

@h Creating from textual Inter syntax.

=
void LocalInstruction::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp,
	inter_error_location *eloc, inter_error_message **E) {
	text_stream *type_text = NULL, *name_text = ilp->mr.exp[0];
	inter_symbol *variable_s = NULL;
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, name_text, L"%((%c+)%) (%c+)")) {
		type_text = mr.exp[0]; name_text = mr.exp[1];
	}
	inter_symbols_table *T = InterBookmark::scope(IBM);
	inter_type var_type = InterTypes::parse_simple(T, eloc, type_text, E);
	if (*E == NULL) variable_s = TextualInter::new_symbol(eloc, T, name_text, E);
	Regexp::dispose_of(&mr);
	if (*E) return;

	InterSymbol::make_local(variable_s);
	SymbolAnnotation::copy_set_to_symbol(&(ilp->set), variable_s);

	*E = LocalInstruction::new(IBM, variable_s, var_type, (inter_ti) ilp->indent_level, eloc);
}

@h Writing to textual Inter syntax.

=
void LocalInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P) {
	WRITE("local ");
	TextualInter::write_optional_type_marker(OUT, P, TYPE_LOCAL_IFLD);
	inter_symbol *variable_s = LocalInstruction::variable(P);
	WRITE("%S", InterSymbol::identifier(variable_s));
	SymbolAnnotation::write_annotations(OUT, P, variable_s);
}

@h Access function.

=
inter_symbol *LocalInstruction::variable(inter_tree_node *P) {
	if (P == NULL) return NULL;
	if (Inode::isnt(P, LOCAL_IST)) return NULL;
	return InterSymbolsTable::symbol_from_ID_at_node(P, DEFN_LOCAL_IFLD);
}
