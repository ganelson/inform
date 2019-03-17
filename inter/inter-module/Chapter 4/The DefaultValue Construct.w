[Inter::DefaultValue::] The DefaultValue Construct.

Defining the defaultvalue construct.

@

@e DEFAULTVALUE_IST

=
void Inter::DefaultValue::define(void) {
	Inter::Defn::create_construct(
		DEFAULTVALUE_IST,
		L"defaultvalue (%i+) = (%c+)",
		&Inter::DefaultValue::read,
		NULL,
		&Inter::DefaultValue::verify,
		&Inter::DefaultValue::write,
		NULL,
		NULL,
		NULL,
		&Inter::DefaultValue::show_dependencies,
		I"defaultvalue", I"defaultvalues");
}

@

@d KIND_DEF_IFLD 2
@d VAL1_DEF_IFLD 3
@d VAL2_DEF_IFLD 4

@d EXTENT_DEF_IFR 5

=
inter_error_message *Inter::DefaultValue::read(inter_reading_state *IRS, inter_line_parse *ilp, inter_error_location *eloc) {
	inter_error_message *E = Inter::Defn::vet_level(IRS, DEFAULTVALUE_IST, ilp->indent_level, eloc);
	if (E) return E;

	inter_symbol *con_kind = Inter::Textual::find_symbol(IRS->read_into, eloc, Inter::Bookmarks::scope(IRS), ilp->mr.exp[0], KIND_IST, &E);
	if (E) return E;

	inter_t con_val1 = 0;
	inter_t con_val2 = 0;
	E = Inter::Types::read(ilp->line, eloc, IRS->read_into, IRS->current_package, con_kind, ilp->mr.exp[1], &con_val1, &con_val2, Inter::Bookmarks::scope(IRS));
	if (E) return E;

	return Inter::DefaultValue::new(IRS, Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, con_kind), con_val1, con_val2, (inter_t) ilp->indent_level, eloc);
}

inter_error_message *Inter::DefaultValue::new(inter_reading_state *IRS, inter_t KID, inter_t val1, inter_t val2, inter_t level, inter_error_location *eloc) {
	inter_frame P = Inter::Frame::fill_3(IRS, DEFAULTVALUE_IST, KID, val1, val2, eloc, level);
	inter_error_message *E = Inter::Defn::verify_construct(P); if (E) return E;
	Inter::Frame::insert(P, IRS);
	return NULL;
}

inter_error_message *Inter::DefaultValue::verify(inter_frame P) {
	if (P.extent != EXTENT_DEF_IFR) return Inter::Frame::error(&P, I"extent wrong", NULL);

	inter_error_message *E = Inter::Verify::symbol(P, P.data[KIND_DEF_IFLD], KIND_IST);
	if (E) return E;
	return NULL;
}

inter_error_message *Inter::DefaultValue::write(OUTPUT_STREAM, inter_frame P) {
	inter_symbol *con_kind = Inter::SymbolsTables::symbol_from_frame_data(P, KIND_DEF_IFLD);
	if (con_kind) {
		WRITE("defaultvalue %S = ", con_kind->symbol_name);
		Inter::Types::write(OUT, P.repo_segment->owning_repo, con_kind,
			P.data[VAL1_DEF_IFLD], P.data[VAL1_DEF_IFLD+1], Inter::Packages::scope_of(P), FALSE);
	} else {
		return Inter::Frame::error(&P, I"defaultvalue can't be written", NULL);
	}
	return NULL;
}

void Inter::DefaultValue::show_dependencies(inter_frame P, void (*callback)(struct inter_symbol *, struct inter_symbol *, void *), void *state) {
	inter_symbol *con_kind = Inter::SymbolsTables::symbol_from_frame_data(P, KIND_DEF_IFLD);
	if (con_kind) {
		inter_t v1 = P.data[VAL1_DEF_IFLD], v2 = P.data[VAL1_DEF_IFLD+1];
		inter_symbol *S = Inter::SymbolsTables::symbol_from_data_pair_and_frame(v1, v2, P);
		if (S) (*callback)(con_kind, S, state);
	}
}
