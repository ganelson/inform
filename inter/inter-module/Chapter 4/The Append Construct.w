[Inter::Append::] The Append Construct.

Defining the append construct.

@

@e APPEND_IST

=
void Inter::Append::define(void) {
	Inter::Defn::create_construct(
		APPEND_IST,
		L"append (%i+) \"(%c+)\"",
		&Inter::Append::read,
		NULL,
		&Inter::Append::verify,
		&Inter::Append::write,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		I"append", I"appends");
}

@

@d SYMBOL_APPEND_IFLD 2
@d TEXT_APPEND_IFLD 3

@d EXTENT_APPEND_IFR 4

=
inter_error_message *Inter::Append::read(inter_reading_state *IRS, inter_line_parse *ilp, inter_error_location *eloc) {
	inter_error_message *E = Inter::Defn::vet_level(IRS, APPEND_IST, ilp->indent_level, eloc);
	if (E) return E;

	if (ilp->no_annotations > 0) return Inter::Errors::plain(I"__annotations are not allowed", eloc);

	inter_symbol *symbol = Inter::SymbolsTables::symbol_from_name(Inter::Bookmarks::scope(IRS), ilp->mr.exp[0]);
	if (symbol == NULL) return Inter::Errors::plain(I"no such symbol", eloc);

	inter_t ID = Inter::create_text(IRS->read_into);
	E = Inter::Constant::parse_text(Inter::get_text(IRS->read_into, ID), ilp->mr.exp[1], 0, Str::len(ilp->mr.exp[1]), eloc);
	if (E) return E;

	return Inter::Append::new(IRS, symbol, ID, (inter_t) ilp->indent_level, eloc);
}

inter_error_message *Inter::Append::new(inter_reading_state *IRS, inter_symbol *symbol, inter_t append_text, inter_t level, struct inter_error_location *eloc) {
	inter_frame P = Inter::Frame::fill_2(IRS, APPEND_IST, Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, symbol), append_text, eloc, level);
	inter_error_message *E = Inter::Defn::verify_construct(P); if (E) return E;
	Inter::Frame::insert(P, IRS);
	return NULL;
}

inter_error_message *Inter::Append::verify(inter_frame P) {
	inter_t vcount = P.repo_segment->bytecode[P.index + PREFRAME_VERIFICATION_COUNT]++;

	if (P.extent != EXTENT_APPEND_IFR) return Inter::Frame::error(&P, I"extent wrong", NULL);
	inter_symbol *symbol = Inter::SymbolsTables::symbol_from_frame_data(P, SYMBOL_APPEND_IFLD);
	if (symbol == NULL) return Inter::Frame::error(&P, I"no target name", NULL);
	if (P.data[TEXT_APPEND_IFLD] == 0) return Inter::Frame::error(&P, I"no translation text", NULL);

	if (vcount == 0) {
		inter_t ID = P.data[TEXT_APPEND_IFLD];
		text_stream *S = Inter::get_text(P.repo_segment->owning_repo, ID);
		Inter::Symbols::set_append(symbol, S);
	}
	return NULL;
}

inter_error_message *Inter::Append::write(OUTPUT_STREAM, inter_frame P) {
	inter_symbol *symbol = Inter::SymbolsTables::symbol_from_frame_data(P, SYMBOL_APPEND_IFLD);
	inter_t ID = P.data[TEXT_APPEND_IFLD];
	text_stream *S = Inter::get_text(P.repo_segment->owning_repo, ID);
	WRITE("append %S \"", symbol->symbol_name);
	Inter::Constant::write_text(OUT, S);
	WRITE("\"");
	return NULL;
}
