[Inter::Marker::] The Marker Construct.

Defining the marker construct.

@

@e MARKER_IST

@d MARK_MARKER_IFLD 2

@d EXTENT_MARKER_IFR 3

=
void Inter::Marker::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		MARKER_IST,
		L"marker (%i+)",
		I"marker", I"markers");
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::Marker::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, Inter::Marker::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::Marker::write);
}

void Inter::Marker::read(inter_construct *IC, inter_reading_state *IRS, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	*E = Inter::Defn::vet_level(IRS, MARKER_IST, ilp->indent_level, eloc);
	if (*E) return;
	if (ilp->no_annotations > 0) { *E = Inter::Errors::plain(I"__annotations are not allowed", eloc); return; }

	inter_symbol *mark_name = Inter::Textual::new_symbol(eloc, Inter::Bookmarks::scope(IRS), ilp->mr.exp[0], E);
	if (*E) return;
	*E = Inter::Marker::new(IRS, mark_name, (inter_t) ilp->indent_level, eloc);
}

inter_error_message *Inter::Marker::new(inter_reading_state *IRS, inter_symbol *mark, inter_t level, inter_error_location *eloc) {
	inter_frame P = Inter::Frame::fill_1(IRS, MARKER_IST, Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, mark), eloc, level);
	inter_error_message *E = Inter::Defn::verify_construct(IRS->current_package, P); if (E) return E;
	Inter::Frame::insert(P, IRS);
	mark->following_symbol = Inter::Bookmarks::snapshot(IRS);
	return NULL;
}

void Inter::Marker::verify(inter_construct *IC, inter_frame P, inter_package *owner, inter_error_message **E) {
	*E = Inter__Verify__defn(owner, P, MARK_MARKER_IFLD);
}

void Inter::Marker::write(inter_construct *IC, OUTPUT_STREAM, inter_frame P, inter_error_message **E) {
	inter_symbol *mark = Inter::SymbolsTables::symbol_from_frame_data(P, MARK_MARKER_IFLD);
	if (mark) {
		WRITE("marker %S", mark->symbol_name);
	} else { *E = Inter::Frame::error(&P, I"cannot write marker", NULL); return; }
}
