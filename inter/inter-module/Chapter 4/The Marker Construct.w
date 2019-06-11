[Inter::Marker::] The Marker Construct.

Defining the marker construct.

@

@e MARKER_IST

@d MARK_MARKER_IFLD 2

@d EXTENT_MARKER_IFR 3

=
void Inter::Marker::define(void) {
	Inter::Defn::create_construct(
		MARKER_IST,
		L"marker (%i+)",
		&Inter::Marker::read,
		NULL,
		&Inter::Marker::verify,
		&Inter::Marker::write,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		I"marker", I"markers");
}

inter_error_message *Inter::Marker::read(inter_reading_state *IRS, inter_line_parse *ilp, inter_error_location *eloc) {
	inter_error_message *E = Inter::Defn::vet_level(IRS, MARKER_IST, ilp->indent_level, eloc);
	if (E) return E;
	if (ilp->no_annotations > 0) return Inter::Errors::plain(I"__annotations are not allowed", eloc);

	inter_symbol *mark_name = Inter::Textual::new_symbol(eloc, Inter::Bookmarks::scope(IRS), ilp->mr.exp[0], &E);
	if (E) return E;
	return Inter::Marker::new(IRS, mark_name, (inter_t) ilp->indent_level, eloc);
}

inter_error_message *Inter::Marker::new(inter_reading_state *IRS, inter_symbol *mark, inter_t level, inter_error_location *eloc) {
	inter_frame P = Inter::Frame::fill_1(IRS, MARKER_IST, Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, mark), eloc, level);
	inter_error_message *E = Inter::Defn::verify_construct(P); if (E) return E;
	Inter::Frame::insert(P, IRS);
	mark->following_symbol = Inter::Bookmarks::snapshot(IRS);
	return NULL;
}

inter_error_message *Inter::Marker::verify(inter_frame P) {
	inter_error_message *E = Inter::Verify::defn(P, MARK_MARKER_IFLD); if (E) return E;
	return NULL;
}

inter_error_message *Inter::Marker::write(OUTPUT_STREAM, inter_frame P) {
	inter_symbol *mark = Inter::SymbolsTables::symbol_from_frame_data(P, MARK_MARKER_IFLD);
	if (mark) {
		WRITE("marker %S", mark->symbol_name);
	} else return Inter::Frame::error(&P, I"cannot write marker", NULL);
	return NULL;
}
