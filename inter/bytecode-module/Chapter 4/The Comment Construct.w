[Inter::Comment::] The Comment Construct.

Defining the comment construct.

@

@e COMMENT_IST

@d EXTENT_COMMENT_IFR 2

=
void Inter::Comment::define(void) {
	inter_construct *IC = InterConstruct::create_construct(COMMENT_IST, I"comment");
	InterConstruct::specify_syntax(IC, I"WHITESPACE");
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::Comment::read);
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
	*E = Inter::Comment::new(IBM, (inter_ti) ilp->indent_level, eloc, ilp->terminal_comment);
}

inter_error_message *Inter::Comment::new(inter_bookmark *IBM, inter_ti level, inter_error_location *eloc, inter_ti comment_ID) {
	inter_tree_node *P = Inode::new_with_0_data_fields(IBM, COMMENT_IST, eloc, level);
	Inode::attach_comment(P, comment_ID);
	inter_error_message *E = InterConstruct::verify_construct(InterBookmark::package(IBM), P); if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void Inter::Comment::transpose(inter_construct *IC, inter_tree_node *P, inter_ti *grid, inter_ti grid_extent, inter_error_message **E) {
	Inode::attach_comment(P, grid[Inode::get_comment(P)]);
}
