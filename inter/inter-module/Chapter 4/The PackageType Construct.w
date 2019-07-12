[Inter::PackageType::] The PackageType Construct.

Defining the packagetype construct.

@

@e PACKAGETYPE_IST

=
void Inter::PackageType::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		PACKAGETYPE_IST,
		L"packagetype (_%i+)",
		I"packagetype", I"packagetypes");
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::PackageType::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, Inter::PackageType::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::PackageType::write);
	IC->usage_permissions = OUTSIDE_OF_PACKAGES;
}

@

@d DEFN_PTYPE_IFLD 2

@d EXTENT_PTYPE_IFR 3

=
void Inter::PackageType::read(inter_construct *IC, inter_reading_state *IRS, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	*E = Inter::Defn::vet_level(IRS, PACKAGETYPE_IST, ilp->indent_level, eloc);
	if (*E) return;

	if (ilp->no_annotations > 0) { *E = Inter::Errors::plain(I"__annotations are not allowed", eloc); return; }

	inter_symbol *ptype_name = Inter::Textual::new_symbol(eloc, Inter::Bookmarks::scope(IRS), ilp->mr.exp[0], E);
	if (*E) return;

	*E = Inter::PackageType::new_packagetype(IRS, ptype_name, (inter_t) ilp->indent_level, eloc);
}

inter_error_message *Inter::PackageType::new_packagetype(inter_reading_state *IRS, inter_symbol *ptype, inter_t level, inter_error_location *eloc) {
	if (plain_packagetype == NULL) plain_packagetype = ptype;
	else if (code_packagetype == NULL) code_packagetype = ptype;

	inter_frame P = Inter::Frame::fill_1(IRS, PACKAGETYPE_IST, Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, ptype), eloc, level);
	inter_error_message *E = Inter::Defn::verify_construct(IRS->current_package, P);
	if (E) return E;
	Inter::Frame::insert(P, IRS);
	return NULL;
}

void Inter::PackageType::verify(inter_construct *IC, inter_frame P, inter_package *owner, inter_error_message **E) {
	if (P.extent < EXTENT_PTYPE_IFR) { *E = Inter::Frame::error(&P, I"p extent wrong", NULL); return; }
	*E = Inter__Verify__defn(owner, P, DEFN_PTYPE_IFLD);
}

void Inter::PackageType::write(inter_construct *IC, OUTPUT_STREAM, inter_frame P, inter_error_message **E) {
	inter_symbol *ptype_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_PTYPE_IFLD);
	if (ptype_name) WRITE("packagetype %S", ptype_name->symbol_name);
	else { *E = Inter::Frame::error(&P, I"cannot write packagetype", NULL); return; }
}
