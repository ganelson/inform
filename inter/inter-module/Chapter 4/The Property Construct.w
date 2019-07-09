[Inter::Property::] The Property Construct.

Defining the property construct.

@

@e PROPERTY_IST

=
void Inter::Property::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		PROPERTY_IST,
		L"property (%i+) (%i+)",
		I"property", I"properties");
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::Property::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, Inter::Property::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::Property::write);
}

@

@d DEFN_PROP_IFLD 2
@d KIND_PROP_IFLD 3
@d PERM_LIST_PROP_IFLD 4

@d EXTENT_PROP_IFR 5

=
void Inter::Property::read(inter_construct *IC, inter_reading_state *IRS, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	*E = Inter::Defn::vet_level(IRS, PROPERTY_IST, ilp->indent_level, eloc);
	if (*E) return;

	inter_symbol *prop_name = Inter::Textual::new_symbol(eloc, Inter::Bookmarks::scope(IRS), ilp->mr.exp[0], E);
	if (*E) return;
	inter_symbol *prop_kind = Inter::Textual::find_symbol(IRS->read_into, eloc, Inter::Bookmarks::scope(IRS), ilp->mr.exp[1], KIND_IST, E);
	if (*E) return;

	for (int i=0; i<ilp->no_annotations; i++)
		Inter::Symbols::annotate(IRS->read_into, prop_name, ilp->annotations[i]);

	*E = Inter::Property::new(IRS, Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, prop_name), Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, prop_kind), (inter_t) ilp->indent_level, eloc);
}

inter_error_message *Inter::Property::new(inter_reading_state *IRS, inter_t PID, inter_t KID, inter_t level, inter_error_location *eloc) {
	inter_frame P = Inter::Frame::fill_3(IRS, PROPERTY_IST, PID, KID, Inter::create_frame_list(IRS->read_into), eloc, level);
	inter_error_message *E = Inter::Defn::verify_construct(P);
	if (E) return E;
	Inter::Frame::insert(P, IRS);
	return NULL;
}

void Inter::Property::verify(inter_construct *IC, inter_frame P, inter_error_message **E) {
	if (P.extent != EXTENT_PROP_IFR) { *E = Inter::Frame::error(&P, I"extent wrong", NULL); return; }
	*E = Inter::Verify::defn(P, DEFN_PROP_IFLD); if (*E) return;
	*E = Inter::Verify::symbol(P, P.data[KIND_PROP_IFLD], KIND_IST);
}

inter_t Inter::Property::permissions_list(inter_symbol *prop_name) {
	if (prop_name == NULL) return 0;
	inter_frame D = Inter::Symbols::defining_frame(prop_name);
	if (Inter::Frame::valid(&D) == FALSE) return 0;
	return D.data[PERM_LIST_PROP_IFLD];
}

void Inter::Property::write(inter_construct *IC, OUTPUT_STREAM, inter_frame P, inter_error_message **E) {
	inter_symbol *prop_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_PROP_IFLD);
	inter_symbol *prop_kind = Inter::SymbolsTables::symbol_from_frame_data(P, KIND_PROP_IFLD);
	if ((prop_name) && (prop_kind)) {
		WRITE("property %S %S", prop_name->symbol_name, prop_kind->symbol_name);
		Inter::Symbols::write_annotations(OUT, P.repo_segment->owning_repo, prop_name);
	} else { *E = Inter::Frame::error(&P, I"cannot write property", NULL); return; }
}

inter_symbol *Inter::Property::kind_of(inter_symbol *prop_symbol) {
	if (prop_symbol == NULL) return NULL;
	inter_frame D = Inter::Symbols::defining_frame(prop_symbol);
	if (Inter::Frame::valid(&D) == FALSE) return NULL;
	if (D.data[ID_IFLD] != PROPERTY_IST) return NULL;
	return Inter::SymbolsTables::symbol_from_frame_data(D, KIND_PROP_IFLD);
}
