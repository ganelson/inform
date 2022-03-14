[CommentInstruction::] The Comment Construct.

Defining the comment construct.

@h Definition.
Comments are present in Inter bytecode as actual instructions, enabling them
to be preserved in binary Inter files. But they have no effect on the meaning
or execution of a program.

=
void CommentInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(COMMENT_IST, I"comment");
	InterInstruction::specify_syntax(IC, I"#ANY");
	InterInstruction::data_extent_always(IC, 1);
	METHOD_ADD(IC, CONSTRUCT_TRANSPOSE_MTID, CommentInstruction::transpose);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, CommentInstruction::verify);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, CommentInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, CommentInstruction::write);
	InterInstruction::allow_in_depth_range(IC, 0, INFINITELY_DEEP);
	InterInstruction::permit(IC, OUTSIDE_OF_PACKAGES_ICUP);
	InterInstruction::permit(IC, INSIDE_PLAIN_PACKAGE_ICUP);
	InterInstruction::permit(IC, INSIDE_CODE_PACKAGE_ICUP);
}

@h Instructions.
In bytecode, the frame of an |comment| instruction is laid out with the
compulsory words -- see //Inter Nodes// -- followed by:

@d TEXT_COMMENT_IFLD (DATA_IFLD + 0)

=
inter_error_message *CommentInstruction::new(inter_bookmark *IBM, text_stream *commentary,
	inter_error_location *eloc, inter_ti level) {
	inter_tree_node *P = Inode::new_with_1_data_field(IBM, COMMENT_IST,
		/* TEXT_COMMENT_IFLD: */ InterWarehouse::create_text_at(IBM, commentary),
		eloc, level);
	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), P);
	if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void CommentInstruction::transpose(inter_construct *IC, inter_tree_node *P,
	inter_ti *grid, inter_ti grid_extent, inter_error_message **E) {
	P->W.instruction[TEXT_COMMENT_IFLD] = grid[P->W.instruction[TEXT_COMMENT_IFLD]];
}

@ Verification consists only of sanity checks.

=
void CommentInstruction::verify(inter_construct *IC, inter_tree_node *P,
	inter_package *owner, inter_error_message **E) {
	*E = VerifyingInter::text_field(owner, P, TEXT_COMMENT_IFLD);
	if (*E) return;
}

@h Creating from textual Inter syntax.

=
void CommentInstruction::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp,
	inter_error_location *eloc, inter_error_message **E) {
	text_stream *commentary = ilp->mr.exp[0];
	*E = CommentInstruction::new(IBM, commentary, eloc, (inter_ti) ilp->indent_level);
}

@h Writing to textual Inter syntax.
The empty comment is printed back as a blank line, rather than a lone |#|.

=
void CommentInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P) {
	text_stream *S = Inode::ID_to_text(P, P->W.instruction[TEXT_COMMENT_IFLD]);
	if (Str::len(S) > 0) WRITE("#%S", S);
}
