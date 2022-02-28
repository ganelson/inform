[Inter::Version::] The Version Construct.

Defining the version construct.

@

@e VERSION_IST

=
void Inter::Version::define(void) {
	inter_construct *IC = InterConstruct::create_construct(VERSION_IST, I"version");
	InterConstruct::specify_syntax(IC, I"version TOKEN");
	InterConstruct::permit(IC, OUTSIDE_OF_PACKAGES_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::Version::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, Inter::Version::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::Version::write);
}

@

=
void Inter::Version::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp,
	inter_error_location *eloc, inter_error_message **E) {
	*E = InterConstruct::check_level_in_package(IBM, VERSION_IST, ilp->indent_level, eloc);
	if (*E) return;

	if (SymbolAnnotation::nonempty(&(ilp->set))) { *E = InterErrors::plain(I"__annotations are not allowed", eloc); return; }

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

void Inter::Version::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	internal_error("VERSION_IST structures cannot exist");
}

void Inter::Version::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	internal_error("VERSION_IST structures cannot exist");
}
