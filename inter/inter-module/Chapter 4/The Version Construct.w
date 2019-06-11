[Inter::Version::] The Version Construct.

Defining the version construct.

@

@e VERSION_IST

=
void Inter::Version::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		VERSION_IST,
		L"version (%d+)",
		&Inter::Version::read,
		NULL,
		&Inter::Version::verify,
		&Inter::Version::write,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		I"version", I"versions");
	IC->usage_permissions = OUTSIDE_OF_PACKAGES;
}

@

@d NUMBER_VERSION_IFLD 2

@d EXTENT_VERSION_IFR 3

=
inter_error_message *Inter::Version::read(inter_reading_state *IRS, inter_line_parse *ilp, inter_error_location *eloc) {
	inter_error_message *E = Inter::Defn::vet_level(IRS, VERSION_IST, ilp->indent_level, eloc);
	if (E) return E;

	if (ilp->no_annotations > 0) return Inter::Errors::plain(I"__annotations are not allowed", eloc);

	return Inter::Version::new(IRS, Str::atoi(ilp->mr.exp[0], 0), (inter_t) ilp->indent_level, eloc);
}

inter_error_message *Inter::Version::new(inter_reading_state *IRS, int V, inter_t level, inter_error_location *eloc) {
	inter_frame P = Inter::Frame::fill_1(IRS, VERSION_IST, (inter_t) V, eloc, level);
	inter_error_message *E = Inter::Defn::verify_construct(P); if (E) return E;
	Inter::Frame::insert(P, IRS);
	return NULL;
}

inter_error_message *Inter::Version::verify(inter_frame P) {
	if (P.extent != EXTENT_VERSION_IFR) return Inter::Frame::error(&P, I"extent wrong", NULL);
	if (P.data[NUMBER_VERSION_IFLD] < 1) return Inter::Frame::error(&P, I"version out of range", NULL);
	return NULL;
}

inter_error_message *Inter::Version::write(OUTPUT_STREAM, inter_frame P) {
	WRITE("version %d", P.data[NUMBER_VERSION_IFLD]);
	return NULL;
}
