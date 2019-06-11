[Inter::Ref::] The Ref Construct.

Defining the ref construct.

@

@e REF_IST

=
void Inter::Ref::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		REF_IST,
		L"ref (%i+) (%C+)",
		&Inter::Ref::read,
		NULL,
		&Inter::Ref::verify,
		&Inter::Ref::write,
		NULL,
		NULL,
		NULL,
		NULL,
		&Inter::Ref::show_dependencies,
		I"ref", I"refs");
	IC->min_level = 1;
	IC->max_level = 100000000;
	IC->usage_permissions = INSIDE_CODE_PACKAGE;
}

@

@d BLOCK_REF_IFLD 2
@d KIND_REF_IFLD 3
@d VAL1_REF_IFLD 4
@d VAL2_REF_IFLD 5

@d EXTENT_REF_IFR 6

=
inter_error_message *Inter::Ref::read(inter_reading_state *IRS, inter_line_parse *ilp, inter_error_location *eloc) {
	if (ilp->no_annotations > 0) return Inter::Errors::plain(I"__annotations are not allowed", eloc);

	inter_error_message *E = Inter::Defn::vet_level(IRS, REF_IST, ilp->indent_level, eloc);
	if (E) return E;

	inter_symbol *routine = Inter::Defn::get_latest_block_symbol();
	if (routine == NULL) return Inter::Errors::plain(I"'ref' used outside function", eloc);
	inter_symbols_table *locals = Inter::Package::local_symbols(routine);
	if (locals == NULL) return Inter::Errors::plain(I"function has no symbols table", eloc);

	inter_symbol *ref_kind = Inter::Textual::find_symbol(IRS->read_into, eloc, Inter::Bookmarks::scope(IRS), ilp->mr.exp[0], KIND_IST, &E);
	if (E) return E;

	inter_t var_val1 = 0;
	inter_t var_val2 = 0;
	E = Inter::Types::read(ilp->line, eloc, IRS->read_into, IRS->current_package, ref_kind, ilp->mr.exp[1], &var_val1, &var_val2, locals);
	if (E) return E;

	return Inter::Ref::new(IRS, routine, ref_kind, ilp->indent_level, var_val1, var_val2, eloc);
}

inter_error_message *Inter::Ref::new(inter_reading_state *IRS, inter_symbol *routine, inter_symbol *ref_kind, int level, inter_t val1, inter_t val2, inter_error_location *eloc) {
	inter_frame P = Inter::Frame::fill_4(IRS, REF_IST, 0, Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, ref_kind), val1, val2, eloc, (inter_t) level);
	inter_error_message *E = Inter::Defn::verify_construct(P); if (E) return E;
	Inter::Frame::insert(P, IRS);
	return NULL;
}

inter_error_message *Inter::Ref::verify(inter_frame P) {
	if (P.extent != EXTENT_REF_IFR) return Inter::Frame::error(&P, I"extent wrong", NULL);
	inter_symbols_table *locals = Inter::Packages::scope_of(P);
	if (locals == NULL) return Inter::Frame::error(&P, I"no symbols table in function", NULL);
	inter_error_message *E = Inter::Verify::symbol(P, P.data[KIND_REF_IFLD], KIND_IST); if (E) return E;
	inter_symbol *ref_kind = Inter::SymbolsTables::symbol_from_frame_data(P, KIND_REF_IFLD);
	E = Inter::Verify::local_value(P, VAL1_REF_IFLD, ref_kind, locals); if (E) return E;
	return NULL;
}

inter_error_message *Inter::Ref::write(OUTPUT_STREAM, inter_frame P) {
	inter_package *pack = Inter::Packages::container(P);
	inter_symbol *routine = pack->package_name;
	inter_symbols_table *locals = Inter::Package::local_symbols(routine);
	if (locals == NULL) return Inter::Frame::error(&P, I"function has no symbols table", NULL);
	inter_symbol *ref_kind = Inter::SymbolsTables::symbol_from_frame_data(P, KIND_REF_IFLD);
	if (ref_kind) {
		WRITE("ref %S ", ref_kind->symbol_name);
		Inter::Types::write(OUT, P.repo_segment->owning_repo, ref_kind, P.data[VAL1_REF_IFLD], P.data[VAL2_REF_IFLD], locals, FALSE);
	} else return Inter::Frame::error(&P, I"cannot write ref", NULL);
	return NULL;
}

void Inter::Ref::show_dependencies(inter_frame P, void (*callback)(struct inter_symbol *, struct inter_symbol *, void *), void *state) {
	inter_package *pack = Inter::Packages::container(P);
	inter_symbol *routine = pack->package_name;
	inter_symbol *ref_kind = Inter::SymbolsTables::symbol_from_frame_data(P, KIND_REF_IFLD);
	if ((routine) && (ref_kind)) {
		(*callback)(routine, ref_kind, state);
		inter_t v1 = P.data[VAL1_REF_IFLD], v2 = P.data[VAL2_REF_IFLD];
		inter_symbol *S = Inter::SymbolsTables::symbol_from_data_pair_and_frame(v1, v2, P);
		if (S) (*callback)(routine, S, state);
	}
}
