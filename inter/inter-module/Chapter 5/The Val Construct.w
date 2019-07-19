[Inter::Val::] The Val Construct.

Defining the val construct.

@

@e VAL_IST

=
void Inter::Val::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		VAL_IST,
		L"val (%i+) (%c+)",
		I"val", I"vals");
	IC->min_level = 1;
	IC->max_level = 100000000;
	IC->usage_permissions = INSIDE_CODE_PACKAGE;
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::Val::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, Inter::Val::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::Val::write);
}

@

@d BLOCK_VAL_IFLD 2
@d KIND_VAL_IFLD 3
@d VAL1_VAL_IFLD 4
@d VAL2_VAL_IFLD 5

@d EXTENT_VAL_IFR 6

=
void Inter::Val::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	if (ilp->no_annotations > 0) { *E = Inter::Errors::plain(I"__annotations are not allowed", eloc); return; }

	*E = Inter::Defn::vet_level(IBM, VAL_IST, ilp->indent_level, eloc);
	if (*E) return;

	inter_symbol *routine = Inter::Defn::get_latest_block_symbol();
	if (routine == NULL) { *E = Inter::Errors::plain(I"'val' used outside function", eloc); return; }
	inter_symbols_table *locals = Inter::Package::local_symbols(routine);
	if (locals == NULL) { *E = Inter::Errors::plain(I"function has no symbols table", eloc); return; }

	inter_symbol *val_kind = Inter::Textual::find_symbol(IBM->read_into, eloc, Inter::Bookmarks::scope(IBM), ilp->mr.exp[0], KIND_IST, E);
	if (*E) return;

	inter_t val1 = 0;
	inter_t val2 = 0;

	inter_symbol *kind_as_value = Inter::Textual::find_symbol(IBM->read_into, eloc, Inter::Bookmarks::scope(IBM), ilp->mr.exp[1], KIND_IST, E);
	*E = NULL;
	if (kind_as_value) {
		Inter::Symbols::to_data(IBM->read_into, Inter::Bookmarks::package(IBM), kind_as_value, &val1, &val2);
	} else {
		*E = Inter::Types::read(ilp->line, eloc, IBM->read_into, Inter::Bookmarks::package(IBM), val_kind, ilp->mr.exp[1], &val1, &val2, locals);
		if (*E) return;
	}

	*E = Inter::Val::new(IBM, routine, val_kind, ilp->indent_level, val1, val2, eloc);
}

inter_error_message *Inter::Val::new(inter_bookmark *IBM, inter_symbol *routine, inter_symbol *val_kind, int level, inter_t val1, inter_t val2, inter_error_location *eloc) {
	inter_frame P = Inter::Frame::fill_4(IBM, VAL_IST, 0, Inter::SymbolsTables::id_from_IRS_and_symbol(IBM, val_kind), val1, val2, eloc, (inter_t) level);
	inter_error_message *E = Inter::Defn::verify_construct(Inter::Bookmarks::package(IBM), P); if (E) return E;
	Inter::Frame::insert(P, IBM);
	return NULL;
}

void Inter::Val::verify(inter_construct *IC, inter_frame P, inter_package *owner, inter_error_message **E) {
	if (P.extent != EXTENT_VAL_IFR) { *E = Inter::Frame::error(&P, I"extent wrong", NULL); return; }
	inter_symbols_table *locals = Inter::Packages::scope(owner);
	if (locals == NULL) { *E = Inter::Frame::error(&P, I"function has no symbols table", NULL); return; }
	*E = Inter::Verify::symbol(owner, P, P.data[KIND_VAL_IFLD], KIND_IST); if (*E) return;
	inter_symbol *val_kind = Inter::SymbolsTables::symbol_from_id(Inter::Packages::scope(owner), P.data[KIND_VAL_IFLD]);
	*E = Inter::Verify::local_value(P, VAL1_VAL_IFLD, val_kind, locals); if (*E) return;
}

void Inter::Val::write(inter_construct *IC, OUTPUT_STREAM, inter_frame P, inter_error_message **E) {
	inter_symbols_table *locals = Inter::Packages::scope_of(P);
	if (locals == NULL) { *E = Inter::Frame::error(&P, I"function has no symbols table", NULL); return; }
	inter_symbol *val_kind = Inter::SymbolsTables::symbol_from_frame_data(P, KIND_VAL_IFLD);
	if (val_kind) {
		WRITE("val %S ", val_kind->symbol_name);
		Inter::Types::write(OUT, P.repo_segment->owning_repo, val_kind, P.data[VAL1_VAL_IFLD], P.data[VAL2_VAL_IFLD], locals, FALSE);
	} else { *E = Inter::Frame::error(&P, I"cannot write val", NULL); return; }
}
