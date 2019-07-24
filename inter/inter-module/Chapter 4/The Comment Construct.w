[Inter::Comment::] The Comment Construct.

Defining the comment construct.

@

@e COMMENT_IST

@d EXTENT_COMMENT_IFR 2

=
void Inter::Comment::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		COMMENT_IST,
		L" *",
		I"comment", I"comments");
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::Comment::read);
	IC->min_level = 0;
	IC->max_level = 100000000;
	IC->usage_permissions = OUTSIDE_OF_PACKAGES + INSIDE_PLAIN_PACKAGE + INSIDE_CODE_PACKAGE;
}

void Inter::Comment::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	*E = Inter::Defn::vet_level(IBM, COMMENT_IST, ilp->indent_level, eloc);
	if (*E) return;
	if (ilp->no_annotations > 0) { *E = Inter::Errors::plain(I"__annotations are not allowed", eloc); return; }
	*E = Inter::Comment::new(IBM, (inter_t) ilp->indent_level, eloc, ilp->terminal_comment);
}

inter_error_message *Inter::Comment::new(inter_bookmark *IBM, inter_t level, inter_error_location *eloc, inter_t comment_ID) {
	inter_tree_node *P = Inter::Node::fill_0(IBM, COMMENT_IST, eloc, level);
	Inter::Node::attach_comment(P, comment_ID);
	inter_error_message *E = Inter::Defn::verify_construct(Inter::Bookmarks::package(IBM), P); if (E) return E;
	Inter::Tree::insert_node(P, IBM);
	return NULL;
}
