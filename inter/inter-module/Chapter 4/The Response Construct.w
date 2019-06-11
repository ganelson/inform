[Inter::Response::] The Response Construct.

Defining the response construct.

@

@e RESPONSE_IST

=
void Inter::Response::define(void) {
	Inter::Defn::create_construct(
		RESPONSE_IST,
		L"response (%i+) (%i+) (%d+) = (%c+)",
		&Inter::Response::read,
		NULL,
		&Inter::Response::verify,
		&Inter::Response::write,
		NULL,
		NULL,
		NULL,
		NULL,
		&Inter::Response::show_dependencies,
		I"response", I"responses");
}

@

@d DEFN_RESPONSE_IFLD 2
@d RULE_RESPONSE_IFLD 3
@d MARKER_RESPONSE_IFLD 4
@d VAL1_RESPONSE_IFLD 5
@d VAL2_RESPONSE_IFLD 6

@d EXTENT_RESPONSE_IFR 7

=
inter_error_message *Inter::Response::read(inter_reading_state *IRS, inter_line_parse *ilp, inter_error_location *eloc) {
	inter_error_message *E = Inter::Defn::vet_level(IRS, RESPONSE_IST, ilp->indent_level, eloc);
	if (E) return E;

	inter_symbol *resp_name = Inter::Textual::new_symbol(eloc, Inter::Bookmarks::scope(IRS), ilp->mr.exp[0], &E);
	if (E) return E;
	inter_symbol *rule_name = Inter::Textual::find_symbol(IRS->read_into, eloc, Inter::Bookmarks::scope(IRS), ilp->mr.exp[1], CONSTANT_IST, &E);
	if (E) return E;

	inter_t n1 = UNDEF_IVAL, n2 = 0;
	E = Inter::Types::read(ilp->line, eloc, IRS->read_into, IRS->current_package, NULL, ilp->mr.exp[2], &n1, &n2, Inter::Bookmarks::scope(IRS));
	if (E) return E;
	if ((n1 != LITERAL_IVAL) || (n2 >= 26))
		return Inter::Errors::plain(I"response marker out of range", eloc);

	inter_symbol *val_name = Inter::Textual::find_symbol(IRS->read_into, eloc, Inter::Bookmarks::scope(IRS), ilp->mr.exp[3], CONSTANT_IST, &E);
	if (E) return E;

	inter_t v1 = 0, v2 = 0;
	Inter::Symbols::to_data(IRS->read_into, IRS->current_package, val_name, &v1, &v2);
	return Inter::Response::new(IRS, Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, resp_name), Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, rule_name), n2, v1, v2, (inter_t) ilp->indent_level, eloc);
}

inter_error_message *Inter::Response::new(inter_reading_state *IRS, inter_t SID, inter_t RID, inter_t marker, inter_t v1, inter_t v2, inter_t level, inter_error_location *eloc) {
	inter_frame P = Inter::Frame::fill_5(IRS, RESPONSE_IST, SID, RID, marker, v1, v2, eloc, level);
	inter_error_message *E = Inter::Defn::verify_construct(P); if (E) return E;
	Inter::Frame::insert(P, IRS);
	return NULL;
}

inter_error_message *Inter::Response::verify(inter_frame P) {
	if (P.extent != EXTENT_RESPONSE_IFR) return Inter::Frame::error(&P, I"extent wrong", NULL);
	inter_error_message *E = Inter::Verify::defn(P, DEFN_RESPONSE_IFLD); if (E) return E;
	if (P.data[MARKER_RESPONSE_IFLD] >= 26) return Inter::Errors::plain(I"response marker out of range", NULL);
	return NULL;
}

inter_error_message *Inter::Response::write(OUTPUT_STREAM, inter_frame P) {
	inter_symbol *resp_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_RESPONSE_IFLD);
	inter_symbol *rule_name = Inter::SymbolsTables::symbol_from_frame_data(P, RULE_RESPONSE_IFLD);
	if ((resp_name) && (rule_name)) {
		WRITE("response %S %S %d = ", resp_name->symbol_name, rule_name->symbol_name, P.data[MARKER_RESPONSE_IFLD]);
		Inter::Types::write(OUT, P.repo_segment->owning_repo, NULL,
			P.data[VAL1_RESPONSE_IFLD], P.data[VAL1_RESPONSE_IFLD+1], Inter::Packages::scope_of(P), FALSE);
	} else {
		return Inter::Frame::error(&P, I"response can't be written", NULL);
	}
	return NULL;
}

void Inter::Response::show_dependencies(inter_frame P, void (*callback)(struct inter_symbol *, struct inter_symbol *, void *), void *state) {
	inter_symbol *resp_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_RESPONSE_IFLD);
	inter_symbol *rule_name = Inter::SymbolsTables::symbol_from_frame_data(P, RULE_RESPONSE_IFLD);
	if ((resp_name) && (rule_name)) {
		(*callback)(rule_name, resp_name, state);
		inter_t v1 = P.data[VAL1_RESPONSE_IFLD], v2 = P.data[VAL1_RESPONSE_IFLD+1];
		inter_symbol *S = Inter::SymbolsTables::symbol_from_data_pair_and_frame(v1, v2, P);
		if (S) (*callback)(resp_name, S, state);
	}
}
