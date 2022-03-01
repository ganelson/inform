[CommentInstruction::] The Comment Construct.

Defining the comment construct.

@


@d TEXT_COMMENT_IFLD 2
@d EXTENT_COMMENT_IFR 3

=
void CommentInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(COMMENT_IST, I"comment");
	InterInstruction::specify_syntax(IC, I"#ANY");
	InterInstruction::fix_instruction_length_between(IC, EXTENT_COMMENT_IFR, EXTENT_COMMENT_IFR);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, CommentInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, CommentInstruction::write);
	METHOD_ADD(IC, CONSTRUCT_TRANSPOSE_MTID, CommentInstruction::transpose);
	InterInstruction::allow_in_depth_range(IC, 0, INFINITELY_DEEP);
	InterInstruction::permit(IC, OUTSIDE_OF_PACKAGES_ICUP);
	InterInstruction::permit(IC, INSIDE_PLAIN_PACKAGE_ICUP);
	InterInstruction::permit(IC, INSIDE_CODE_PACKAGE_ICUP);
}

void CommentInstruction::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	inter_ti ID = InterWarehouse::create_text(InterBookmark::warehouse(IBM), InterBookmark::package(IBM));
	WRITE_TO(InterWarehouse::get_text(InterBookmark::warehouse(IBM), ID), "%S", ilp->mr.exp[0]);
	*E = CommentInstruction::new(IBM, (inter_ti) ilp->indent_level, eloc, ID);
}

inter_error_message *CommentInstruction::new(inter_bookmark *IBM, inter_ti level, inter_error_location *eloc, inter_ti comment_ID) {
	inter_tree_node *P = Inode::new_with_1_data_field(IBM, COMMENT_IST, comment_ID, eloc, level);
	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), P); if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void CommentInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	text_stream *S = Inode::ID_to_text(P, P->W.instruction[TEXT_COMMENT_IFLD]);
	if (Str::len(S) > 0) WRITE("#%S", S);
}

void CommentInstruction::transpose(inter_construct *IC, inter_tree_node *P, inter_ti *grid, inter_ti grid_extent, inter_error_message **E) {
	P->W.instruction[TEXT_COMMENT_IFLD] = grid[P->W.instruction[TEXT_COMMENT_IFLD]];
}
