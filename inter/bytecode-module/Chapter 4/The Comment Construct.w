[Inter::Comment::] The Comment Construct.

Defining the comment construct.

@

@e COMMENT_IST

@d TEXT_COMMENT_IFLD 2
@d EXTENT_COMMENT_IFR 3

=
void Inter::Comment::define(void) {
	inter_construct *IC = InterConstruct::create_construct(COMMENT_IST, I"comment");
	InterConstruct::specify_syntax(IC, I"#ANY");
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::Comment::read);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::Comment::write);
	METHOD_ADD(IC, CONSTRUCT_TRANSPOSE_MTID, Inter::Comment::transpose);
	InterConstruct::allow_in_depth_range(IC, 0, INFINITELY_DEEP);
	InterConstruct::permit(IC, OUTSIDE_OF_PACKAGES_ICUP);
	InterConstruct::permit(IC, INSIDE_PLAIN_PACKAGE_ICUP);
	InterConstruct::permit(IC, INSIDE_CODE_PACKAGE_ICUP);
}

void Inter::Comment::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	*E = InterConstruct::check_level_in_package(IBM, COMMENT_IST, ilp->indent_level, eloc);
	if (*E) return;
	if (SymbolAnnotation::nonempty(&(ilp->set))) { *E = Inter::Errors::plain(I"__annotations are not allowed", eloc); return; }
	inter_ti ID = InterWarehouse::create_text(InterBookmark::warehouse(IBM), InterBookmark::package(IBM));
	WRITE_TO(InterWarehouse::get_text(InterBookmark::warehouse(IBM), ID), "%S", ilp->mr.exp[0]);
	*E = Inter::Comment::new(IBM, (inter_ti) ilp->indent_level, eloc, ID);
}

inter_error_message *Inter::Comment::new(inter_bookmark *IBM, inter_ti level, inter_error_location *eloc, inter_ti comment_ID) {
	inter_tree_node *P = Inode::new_with_1_data_field(IBM, COMMENT_IST, comment_ID, eloc, level);
	inter_error_message *E = InterConstruct::verify_construct(InterBookmark::package(IBM), P); if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void Inter::Comment::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	text_stream *S = Inode::ID_to_text(P, P->W.instruction[TEXT_COMMENT_IFLD]);
	if (Str::len(S) > 0) WRITE("#%S", S);
}

void Inter::Comment::transpose(inter_construct *IC, inter_tree_node *P, inter_ti *grid, inter_ti grid_extent, inter_error_message **E) {
	P->W.instruction[TEXT_COMMENT_IFLD] = grid[P->W.instruction[TEXT_COMMENT_IFLD]];
}
