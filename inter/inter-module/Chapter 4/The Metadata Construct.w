[Inter::Metadata::] The Metadata Construct.

Defining the metadata construct.

@

@e METADATA_IST

=
void Inter::Metadata::define(void) {
	Inter::Defn::create_construct(
		METADATA_IST,
		L"metadata (`%i+): (%c+)",
		&Inter::Metadata::read,
		NULL,
		&Inter::Metadata::verify,
		&Inter::Metadata::write,
		NULL,
		NULL,
		NULL,
		NULL,
		I"metadata", I"metadatas");
}

@

@d DEFN_MD_IFLD 2
@d VAL1_MD_IFLD 3
@d VAL2_MD_IFLD 4

@d EXTENT_MD_IFR 5

=
inter_error_message *Inter::Metadata::read(inter_reading_state *IRS, inter_line_parse *ilp, inter_error_location *eloc) {
	inter_error_message *E = Inter::Defn::vet_level(IRS, METADATA_IST, ilp->indent_level, eloc);
	if (E) return E;

	inter_symbol *key_name = Inter::Textual::new_symbol(eloc, Inter::Bookmarks::scope(IRS), ilp->mr.exp[0], &E);
	if (E) return E;

	text_stream *S = ilp->mr.exp[1];
	if ((Str::begins_with_wide_string(S, L"\"")) && (Str::ends_with_wide_string(S, L"\""))) {
		TEMPORARY_TEXT(parsed_text);
		E = Inter::Constant::parse_text(parsed_text, S, 1, Str::len(S)-2, eloc);
		inter_t ID = 0;
		if (E == NULL) {
			ID = Inter::create_text(IRS->read_into);
			Str::copy(Inter::get_text(IRS->read_into, ID), parsed_text);
		}
		DISCARD_TEXT(parsed_text);
		if (E) return E;
		return Inter::Metadata::new(IRS, Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, key_name), ID, (inter_t) IRS->latest_indent, eloc);
	}
	return Inter::Errors::quoted(I"metadata value must be string", S, eloc);
}

inter_error_message *Inter::Metadata::new(inter_reading_state *IRS, inter_t SID, inter_t TID, inter_t level, inter_error_location *eloc) {
	inter_frame P = Inter::Frame::fill_3(IRS,
		METADATA_IST, SID, LITERAL_TEXT_IVAL, TID, eloc, level);
	inter_error_message *E = Inter::Defn::verify_construct(P); if (E) return E;
	Inter::Frame::insert(P, IRS);
	return NULL;
}

inter_error_message *Inter::Metadata::verify(inter_frame P) {
	if (P.extent != EXTENT_MD_IFR) return Inter::Frame::error(&P, I"extent wrong", NULL);
	inter_error_message *E = Inter::Verify::defn(P, DEFN_MD_IFLD); if (E) return E;
	return NULL;
}

inter_error_message *Inter::Metadata::write(OUTPUT_STREAM, inter_frame P) {
	inter_symbol *key_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_MD_IFLD);
	if (key_name) {
		WRITE("metadata %S: ", key_name->symbol_name);
		Inter::Types::write(OUT, P.repo_segment->owning_repo, NULL,
			P.data[VAL1_MD_IFLD], P.data[VAL1_MD_IFLD+1], Inter::Packages::scope_of(P), FALSE);
	} else {
		return Inter::Frame::error(&P, I"metadata can't be written", NULL);
	}
	return NULL;
}
