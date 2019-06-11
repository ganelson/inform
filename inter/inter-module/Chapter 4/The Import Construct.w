[Inter::Import::] The Import Construct.

Defining the import construct.

@

@e IMPORT_IST

@d SYMBOL_IMPORT_IFLD 2
@d TEXT_IMPORT_IFLD 3

@d EXTENT_IMPORT_IFR 4

=
void Inter::Import::define(void) {
	Inter::Defn::create_construct(
		IMPORT_IST,
		L"import (%i+) \"(%c+)\"",
		&Inter::Import::read,
		NULL,
		&Inter::Import::verify,
		&Inter::Import::write,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		I"import", I"imports");
}

inter_error_message *Inter::Import::read(inter_reading_state *IRS, inter_line_parse *ilp, inter_error_location *eloc) {
	inter_error_message *E = Inter::Defn::vet_level(IRS, IMPORT_IST, ilp->indent_level, eloc);
	if (E) return E;
	if (ilp->no_annotations > 0) return Inter::Errors::plain(I"__annotations are not allowed", eloc);

	inter_symbol *symbol = Inter::SymbolsTables::symbol_from_name(Inter::Bookmarks::scope(IRS), ilp->mr.exp[0]);
	if (symbol == NULL) return Inter::Errors::plain(I"no such symbol", eloc);

	inter_t ID = Inter::create_text(IRS->read_into);
	E = Inter::Constant::parse_text(Inter::get_text(IRS->read_into, ID), ilp->mr.exp[1], 0, Str::len(ilp->mr.exp[1]), eloc);
	if (E) return E;

	return Inter::Import::new(IRS, symbol, ID, (inter_t) ilp->indent_level, eloc);
}

inter_error_message *Inter::Import::new(inter_reading_state *IRS, inter_symbol *symbol, inter_t translate_text, inter_t level, struct inter_error_location *eloc) {
	inter_frame P = Inter::Frame::fill_2(IRS, IMPORT_IST, Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, symbol), translate_text, eloc, level);
	inter_error_message *E = Inter::Defn::verify_construct(P); if (E) return E;
	Inter::Frame::insert(P, IRS);
	symbol->importation_frame = P;
	return NULL;
}

inter_error_message *Inter::Import::verify(inter_frame P) {
	inter_t vcount = P.repo_segment->bytecode[P.index + PREFRAME_VERIFICATION_COUNT]++;

	if (P.extent != EXTENT_IMPORT_IFR) return Inter::Frame::error(&P, I"extent wrong", NULL);
	inter_symbol *symbol = Inter::SymbolsTables::symbol_from_frame_data(P, SYMBOL_IMPORT_IFLD);
	if (symbol == NULL) return Inter::Frame::error(&P, I"no target name", NULL);
	if (P.data[TEXT_IMPORT_IFLD] == 0) return Inter::Frame::error(&P, I"no translation text", NULL);

	if (vcount == 0) {
		inter_t ID = P.data[TEXT_IMPORT_IFLD];
		text_stream *S = Inter::get_text(P.repo_segment->owning_repo, ID);
		Inter::Symbols::set_export_name(symbol, S);
	}
	return NULL;
}

inter_error_message *Inter::Import::write(OUTPUT_STREAM, inter_frame P) {
	inter_symbol *symbol = Inter::SymbolsTables::symbol_from_frame_data(P, SYMBOL_IMPORT_IFLD);
	inter_t ID = P.data[TEXT_IMPORT_IFLD];
	text_stream *S = Inter::get_text(P.repo_segment->owning_repo, ID);
	WRITE("import %S \"%S\"", symbol->symbol_name, S);
	return NULL;
}
