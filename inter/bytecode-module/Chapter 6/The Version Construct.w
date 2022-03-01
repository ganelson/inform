[VersionInstruction::] The Version Construct.

Defining the version construct.

@

=
void VersionInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(VERSION_IST, I"version");
	InterInstruction::specify_syntax(IC, I"version TOKEN");
	InterInstruction::permit(IC, OUTSIDE_OF_PACKAGES_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, VersionInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, VersionInstruction::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, VersionInstruction::write);
}

@

=
void VersionInstruction::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp,
	inter_error_location *eloc, inter_error_message **E) {
	semantic_version_number file_version = VersionNumbers::from_text(ilp->mr.exp[0]);
	if (InterVersion::check_readable(file_version) == FALSE) {
		semantic_version_number current_version = InterVersion::current();
		text_stream *erm = Str::new();
		WRITE_TO(erm,
			"file holds Inter written for specification v%v, but I expect v%v",
			&file_version, &current_version);
		*E = InterErrors::plain(erm, eloc);
	}
}

void VersionInstruction::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	internal_error("VERSION_IST structures cannot exist");
}

void VersionInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	internal_error("VERSION_IST structures cannot exist");
}
