[Inter::PackageType::] The PackageType Construct.

Defining the packagetype construct.

@

@e PACKAGETYPE_IST

=
void Inter::PackageType::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		PACKAGETYPE_IST,
		L"packagetype (_%i+)",
		&Inter::PackageType::read,
		NULL,
		&Inter::PackageType::verify,
		&Inter::PackageType::write,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		I"packagetype", I"packagetypes");
	IC->usage_permissions = OUTSIDE_OF_PACKAGES;
}

@

@d DEFN_PTYPE_IFLD 2

@d EXTENT_PTYPE_IFR 3

=
inter_error_message *Inter::PackageType::read(inter_reading_state *IRS, inter_line_parse *ilp, inter_error_location *eloc) {
	inter_error_message *E = Inter::Defn::vet_level(IRS, PACKAGETYPE_IST, ilp->indent_level, eloc);
	if (E) return E;

	if (ilp->no_annotations > 0) return Inter::Errors::plain(I"__annotations are not allowed", eloc);

	inter_symbol *ptype_name = Inter::Textual::new_symbol(eloc, Inter::Bookmarks::scope(IRS), ilp->mr.exp[0], &E);
	if (E) return E;

	return Inter::PackageType::new_packagetype(IRS, ptype_name, (inter_t) ilp->indent_level, eloc);
}

inter_error_message *Inter::PackageType::new_packagetype(inter_reading_state *IRS, inter_symbol *ptype, inter_t level, inter_error_location *eloc) {
	if (plain_packagetype == NULL) plain_packagetype = ptype;
	else if (code_packagetype == NULL) code_packagetype = ptype;

	inter_frame P = Inter::Frame::fill_1(IRS, PACKAGETYPE_IST, Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, ptype), eloc, level);
	inter_error_message *E = Inter::Defn::verify_construct(P);
	if (E) return E;
	Inter::Frame::insert(P, IRS);
	return NULL;
}

inter_error_message *Inter::PackageType::verify(inter_frame P) {
	if (P.extent < EXTENT_PTYPE_IFR) return Inter::Frame::error(&P, I"p extent wrong", NULL);
	inter_error_message *E = Inter::Verify::defn(P, DEFN_PTYPE_IFLD); if (E) return E;
	return NULL;
}

inter_error_message *Inter::PackageType::write(OUTPUT_STREAM, inter_frame P) {
	inter_symbol *ptype_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_PTYPE_IFLD);
	if (ptype_name) WRITE("packagetype %S", ptype_name->symbol_name);
	else return Inter::Frame::error(&P, I"cannot write packagetype", NULL);
	return NULL;
}
