[Inter::Metadata::] The Metadata Construct.

Defining the metadata construct.

@

@e METADATA_IST

=
void Inter::Metadata::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		METADATA_IST,
		L"metadata (`%i+): (%c+)",
		I"metadata", I"metadatas");
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::Metadata::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, Inter::Metadata::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::Metadata::write);
}

@

@d DEFN_MD_IFLD 2
@d VAL1_MD_IFLD 3
@d VAL2_MD_IFLD 4

@d EXTENT_MD_IFR 5

=
void Inter::Metadata::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	*E = Inter::Defn::vet_level(IBM, METADATA_IST, ilp->indent_level, eloc);
	if (*E) return;

	inter_symbol *key_name = Inter::Textual::new_symbol(eloc, Inter::Bookmarks::scope(IBM), ilp->mr.exp[0], E);
	if (*E) return;

	text_stream *S = ilp->mr.exp[1];
	if ((Str::begins_with_wide_string(S, L"\"")) && (Str::ends_with_wide_string(S, L"\""))) {
		TEMPORARY_TEXT(parsed_text);
		*E = Inter::Constant::parse_text(parsed_text, S, 1, Str::len(S)-2, eloc);
		inter_t ID = 0;
		if (*E == NULL) {
			ID = Inter::Warehouse::create_text(Inter::Bookmarks::warehouse(IBM), Inter::Bookmarks::package(IBM));
			Str::copy(Inter::get_text(Inter::Bookmarks::tree(IBM), ID), parsed_text);
		}
		DISCARD_TEXT(parsed_text);
		if (*E) return;
		*E = Inter::Metadata::new(IBM, Inter::SymbolsTables::id_from_IRS_and_symbol(IBM, key_name), ID, (inter_t) ilp->indent_level, eloc);
		return;
	}
	*E = Inter::Errors::quoted(I"metadata value must be string", S, eloc);
}

inter_error_message *Inter::Metadata::new(inter_bookmark *IBM, inter_t SID, inter_t TID, inter_t level, inter_error_location *eloc) {
	inter_frame P = Inter::Frame::fill_3(IBM,
		METADATA_IST, SID, LITERAL_TEXT_IVAL, TID, eloc, level);
	inter_error_message *E = Inter::Defn::verify_construct(Inter::Bookmarks::package(IBM), P); if (E) return E;
	Inter::Frame::insert(P, IBM);
	return NULL;
}

void Inter::Metadata::verify(inter_construct *IC, inter_frame P, inter_package *owner, inter_error_message **E) {
	if (P.extent != EXTENT_MD_IFR) { *E = Inter::Frame::error(&P, I"extent wrong", NULL); return; }
	*E = Inter__Verify__defn(owner, P, DEFN_MD_IFLD);
}

void Inter::Metadata::write(inter_construct *IC, OUTPUT_STREAM, inter_frame P, inter_error_message **E) {
	inter_symbol *key_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_MD_IFLD);
	if (key_name) {
		WRITE("metadata %S: ", key_name->symbol_name);
		Inter::Types::write(OUT, &P, NULL,
			P.data[VAL1_MD_IFLD], P.data[VAL1_MD_IFLD+1], Inter::Packages::scope_of(P), FALSE);
	} else {
		{ *E = Inter::Frame::error(&P, I"metadata can't be written", NULL); return; }
	}
}
