[PragmaInstruction::] The Pragma Construct.

Defining the pragma construct.

@h Definition.
For what this does and why it is used, see //inter: Textual Inter//.

=
void PragmaInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(PRAGMA_IST, I"pragma");
	InterInstruction::specify_syntax(IC, I"pragma IDENTIFIER TEXT");
	InterInstruction::data_extent_always(IC, 2);
	InterInstruction::permit(IC, OUTSIDE_OF_PACKAGES_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, PragmaInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_TRANSPOSE_MTID, PragmaInstruction::transpose);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, PragmaInstruction::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, PragmaInstruction::write);
}

@h Instructions.
In bytecode, the frame of a |pragma| instruction is laid out with the
compulsory words -- see //Inter Nodes// -- followed by:

@d TARGET_PRAGMA_IFLD (DATA_IFLD + 0)
@d TEXT_PRAGMA_IFLD   (DATA_IFLD + 1)

=
inter_error_message *PragmaInstruction::new(inter_bookmark *IBM, text_stream *target_name,
	text_stream *content, inter_ti level, struct inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_2_data_fields(IBM, PRAGMA_IST,
		/* TARGET_PRAGMA_IFLD: */ InterWarehouse::create_text_at(IBM, target_name),
		/* TEXT_PRAGMA_IFLD: */   InterWarehouse::create_text_at(IBM, content),
		eloc, level);
	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), P);
	if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void PragmaInstruction::transpose(inter_construct *IC, inter_tree_node *P, inter_ti *grid,
	inter_ti grid_extent, inter_error_message **E) {
	P->W.instruction[TARGET_PRAGMA_IFLD] = grid[P->W.instruction[TARGET_PRAGMA_IFLD]];
	P->W.instruction[TEXT_PRAGMA_IFLD] = grid[P->W.instruction[TEXT_PRAGMA_IFLD]];
}

@ Verification consists only of sanity checks.

=
void PragmaInstruction::verify(inter_construct *IC, inter_tree_node *P,
	inter_package *owner, inter_error_message **E) {
	*E = VerifyingInter::text_field(owner, P, TARGET_PRAGMA_IFLD);
	if (*E) return;
	*E = VerifyingInter::text_field(owner, P, TEXT_PRAGMA_IFLD);
	if (*E) return;
}

@h Creating from textual Inter syntax.
Note that the target name should be an identifier-like name, without quotes;
whereas the content is parsed as a double-quoted literal.

=
void PragmaInstruction::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp,
	inter_error_location *eloc, inter_error_message **E) {
	text_stream *target_name = ilp->mr.exp[0];
	text_stream *content_token = ilp->mr.exp[1];
	TEMPORARY_TEXT(raw)
	*E = TextualInter::parse_literal_text(raw, content_token, 0, Str::len(content_token), eloc);
	if (*E == NULL)
		*E = PragmaInstruction::new(IBM, target_name, raw, (inter_ti) ilp->indent_level, eloc);
	DISCARD_TEXT(raw)
}

@h Writing to textual Inter syntax.

=
void PragmaInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P) {
	WRITE("pragma %S ", PragmaInstruction::target(P));
	TextualInter::write_text(OUT, PragmaInstruction::content(P));
}

@h Access functions.

=
text_stream *PragmaInstruction::target(inter_tree_node *P) {
	if (P == NULL) return NULL;
	if (Inode::isnt(P, PRAGMA_IST)) return NULL;
	return Inode::ID_to_text(P, P->W.instruction[TARGET_PRAGMA_IFLD]);
}

text_stream *PragmaInstruction::content(inter_tree_node *P) {
	if (P == NULL) return NULL;
	if (Inode::isnt(P, PRAGMA_IST)) return NULL;
	return Inode::ID_to_text(P, P->W.instruction[TEXT_PRAGMA_IFLD]);
}
