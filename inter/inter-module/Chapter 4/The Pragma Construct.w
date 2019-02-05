[Inter::Pragma::] The Pragma Construct.

Defining the pragma construct.

@

@e PRAGMA_IST

=
void Inter::Pragma::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		PRAGMA_IST,
		L"pragma (%i+) \"(%c+)\"",
		&Inter::Pragma::read,
		NULL,
		&Inter::Pragma::verify,
		&Inter::Pragma::write,
		NULL,
		NULL,
		NULL,
		NULL,
		I"pragma", I"pragmas"); /* pragmae? pragmata? */
	IC->usage_permissions = OUTSIDE_OF_PACKAGES;
}

@

@d TARGET_PRAGMA_IFLD 2
@d TEXT_PRAGMA_IFLD 3

@d EXTENT_PRAGMA_IFR 4

=
inter_error_message *Inter::Pragma::read(inter_reading_state *IRS, inter_line_parse *ilp, inter_error_location *eloc) {
	inter_error_message *E = Inter::Defn::vet_level(IRS, PRAGMA_IST, ilp->indent_level, eloc);
	if (E) return E;

	if (ilp->no_annotations > 0) return Inter::Errors::plain(I"__annotations are not allowed", eloc);

	inter_symbol *target_name = Inter::SymbolsTables::symbol_from_name(Inter::Bookmarks::scope(IRS), ilp->mr.exp[0]);
	if (target_name == NULL)
		target_name = Inter::Textual::new_symbol(eloc, Inter::Bookmarks::scope(IRS), ilp->mr.exp[0], &E);
	if (E) return E;

	text_stream *S = ilp->mr.exp[1];
	inter_t ID = Inter::create_text(IRS->read_into);
	int literal_mode = FALSE;
	LOOP_THROUGH_TEXT(pos, S) {
		int c = (int) Str::get(pos);
		if (literal_mode == FALSE) {
			if (c == '\\') { literal_mode = TRUE; continue; }
		} else {
			switch (c) {
				case '\\': break;
				case '"': break;
				case 't': c = 9; break;
				case 'n': c = 10; break;
				default: return Inter::Errors::plain(I"no such backslash escape", eloc);
			}
		}
		if (Inter::Constant::char_acceptable(c) == FALSE) return Inter::Errors::quoted(I"bad character in text", S, eloc);
		PUT_TO(Inter::get_text(IRS->read_into, ID), c);
		literal_mode = FALSE;
	}

	return Inter::Pragma::new(IRS, target_name, ID, (inter_t) ilp->indent_level, eloc);
}

inter_error_message *Inter::Pragma::new(inter_reading_state *IRS, inter_symbol *target_name, inter_t pragma_text, inter_t level, struct inter_error_location *eloc) {
	inter_frame P = Inter::Frame::fill_2(IRS, PRAGMA_IST, Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, target_name), pragma_text, eloc, level);
	inter_error_message *E = Inter::Defn::verify_construct(P); if (E) return E;
	Inter::Frame::insert(P, IRS);
	return NULL;
}

inter_error_message *Inter::Pragma::verify(inter_frame P) {
	if (P.extent != EXTENT_PRAGMA_IFR) return Inter::Frame::error(&P, I"extent wrong", NULL);
	inter_symbol *target_name = Inter::SymbolsTables::symbol_from_frame_data(P, TARGET_PRAGMA_IFLD);
	if (target_name == NULL) return Inter::Frame::error(&P, I"no target name", NULL);
	if (P.data[TEXT_PRAGMA_IFLD] == 0) return Inter::Frame::error(&P, I"no pragma text", NULL);
	return NULL;
}

inter_error_message *Inter::Pragma::write(OUTPUT_STREAM, inter_frame P) {
	inter_symbol *target_name = Inter::SymbolsTables::symbol_from_frame_data(P, TARGET_PRAGMA_IFLD);
	inter_t ID = P.data[TEXT_PRAGMA_IFLD];
	text_stream *S = Inter::get_text(P.repo_segment->owning_repo, ID);
	WRITE("pragma %S \"%S\"", target_name->symbol_name, S);
	return NULL;
}
