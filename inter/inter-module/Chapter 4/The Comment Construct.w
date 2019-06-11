[Inter::Comment::] The Comment Construct.

Defining the constant construct.

@

@e COMMENT_IST

@d EXTENT_COMMENT_IFR 2

=
void Inter::Comment::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		COMMENT_IST,
		L" *",
		&Inter::Comment::read,
		NULL,
		&Inter::Comment::verify,
		&Inter::Comment::write,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		I"comment", I"comments");
	IC->min_level = 0;
	IC->max_level = 100000000;
	IC->usage_permissions = OUTSIDE_OF_PACKAGES + INSIDE_PLAIN_PACKAGE + INSIDE_CODE_PACKAGE;
}

inter_error_message *Inter::Comment::read(inter_reading_state *IRS, inter_line_parse *ilp, inter_error_location *eloc) {
	inter_error_message *E = Inter::Defn::vet_level(IRS, COMMENT_IST, ilp->indent_level, eloc);
	if (E) return E;
	if (ilp->no_annotations > 0) return Inter::Errors::plain(I"__annotations are not allowed", eloc);
	return Inter::Comment::new(IRS, (inter_t) ilp->indent_level, eloc, ilp->terminal_comment);
}

inter_error_message *Inter::Comment::new(inter_reading_state *IRS, inter_t level, inter_error_location *eloc, inter_t comment_ID) {
	inter_frame P = Inter::Frame::fill_0(IRS, COMMENT_IST, eloc, level);
	Inter::Frame::attach_comment(P, comment_ID);
	inter_error_message *E = Inter::Defn::verify_construct(P); if (E) return E;
	Inter::Frame::insert(P, IRS);
	return NULL;
}

inter_error_message *Inter::Comment::verify(inter_frame P) {
	return NULL;
}

inter_error_message *Inter::Comment::write(OUTPUT_STREAM, inter_frame P) {
	return NULL;
}
