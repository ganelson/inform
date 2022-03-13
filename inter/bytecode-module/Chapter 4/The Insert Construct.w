[InsertInstruction::] The Insert Construct.

Defining the insert construct.

@h Definition.
For what this does and why it is used, see //inter: Data Packages in Textual Inter//.
But please use it as little as possible: in an ideal world it would be abolished.

=
void InsertInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(INSERT_IST, I"insert");
	InterInstruction::specify_syntax(IC, I"insert TEXT");
	InterInstruction::fix_instruction_length_between(IC, 3, 3);
	InterInstruction::permit(IC, INSIDE_PLAIN_PACKAGE_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, InsertInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_TRANSPOSE_MTID, InsertInstruction::transpose);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, InsertInstruction::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, InsertInstruction::write);
}

@h Instructions.
In bytecode, the frame of an |insert| instruction is laid out with the
compulsory words -- see //Inter Nodes// -- followed by:

@d TEXT_INSERT_IFLD (DATA_IFLD + 0)

=
inter_error_message *InsertInstruction::new(inter_bookmark *IBM,
	text_stream *text, inter_ti level, struct inter_error_location *eloc) {
	inter_warehouse *warehouse = InterBookmark::warehouse(IBM);
	inter_package *pack = InterBookmark::package(IBM);
	inter_ti ID = InterWarehouse::create_text(warehouse, pack);
	Str::copy(InterWarehouse::get_text(warehouse, ID), text);
	inter_tree_node *P = Inode::new_with_1_data_field(IBM, INSERT_IST,
		/* TEXT_INSERT_IFLD: */ ID,
		eloc, level);
	inter_error_message *E = VerifyingInter::instruction(pack, P); if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void InsertInstruction::transpose(inter_construct *IC, inter_tree_node *P, inter_ti *grid,
	inter_ti grid_extent, inter_error_message **E) {
	P->W.instruction[TEXT_INSERT_IFLD] = grid[P->W.instruction[TEXT_INSERT_IFLD]];
}

@ Verification consists only of sanity checks.

=
void InsertInstruction::verify(inter_construct *IC, inter_tree_node *P,
	inter_package *owner, inter_error_message **E) {
	*E = VerifyingInter::text_field(owner, P, TEXT_INSERT_IFLD);
}

@h Creating from textual Inter syntax.

=
void InsertInstruction::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp,
	inter_error_location *eloc, inter_error_message **E) {
	TEMPORARY_TEXT(raw)
	*E = TextualInter::parse_literal_text(raw, ilp->mr.exp[0], 0, Str::len(ilp->mr.exp[0]), eloc);
	if (*E == NULL)
		*E = InsertInstruction::new(IBM, raw, (inter_ti) ilp->indent_level, eloc);
	DISCARD_TEXT(raw)
}

@h Writing to textual Inter syntax.

=
void InsertInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P) {
	text_stream *insertion = InsertInstruction::insertion(P);
	WRITE("insert ");
	TextualInter::write_text(OUT, insertion);
}

@h Access function.

=
text_stream *InsertInstruction::insertion(inter_tree_node *P) {
	if (P == NULL) return NULL;
	if (Inode::isnt(P, INSERT_IST)) return NULL;
	return Inode::ID_to_text(P, P->W.instruction[TEXT_INSERT_IFLD]);
}
