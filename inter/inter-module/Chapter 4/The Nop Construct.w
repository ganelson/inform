[Inter::Nop::] The Nop Construct.

Defining the nop construct.

@

@e NOP_IST

=
void Inter::Nop::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		NOP_IST, NULL,
		I"nop", I"nops");
	IC->usage_permissions = OUTSIDE_OF_PACKAGES + INSIDE_PLAIN_PACKAGE + INSIDE_CODE_PACKAGE;
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::Nop::write);
}

inter_error_message *Inter::Nop::new(inter_bookmark *IBM, inter_t level, inter_error_location *eloc) {
	inter_tree_node *P = Inter::Frame::fill_0(IBM, NOP_IST, eloc, level);
	inter_error_message *E = Inter::Defn::verify_construct(Inter::Bookmarks::package(IBM), P);
	if (E) return E;
	Inter::insert(P, IBM);
	return NULL;
}

@ This in fact prints only in a stack backtrace, not in regular textual output,
where any nop statements are simply ignored.

=
void Inter::Nop::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	WRITE("nop");
}
