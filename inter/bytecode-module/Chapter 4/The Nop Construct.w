[Inter::Nop::] The Nop Construct.

Defining the nop construct.

@

@e NOP_IST

@d EXTENT_NOP_IFR 2

=
void Inter::Nop::define(void) {
	inter_construct *IC = InterConstruct::create_construct(NOP_IST, I"nop");
	InterConstruct::fix_instruction_length_between(IC, EXTENT_NOP_IFR, EXTENT_NOP_IFR);
	InterConstruct::allow_in_depth_range(IC, 0, INFINITELY_DEEP);
	InterConstruct::permit(IC, OUTSIDE_OF_PACKAGES_ICUP);
	InterConstruct::permit(IC, INSIDE_PLAIN_PACKAGE_ICUP);
	InterConstruct::permit(IC, INSIDE_CODE_PACKAGE_ICUP);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::Nop::write);
}

inter_error_message *Inter::Nop::new(inter_bookmark *IBM, inter_ti level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_0_data_fields(IBM, NOP_IST, eloc, level);
	inter_error_message *E = Inter::Verify::instruction(InterBookmark::package(IBM), P);
	if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

@ This in fact prints only in a stack backtrace, not in regular textual output,
where any nop statements are simply ignored.

=
void Inter::Nop::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	WRITE("nop");
}
