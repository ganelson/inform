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
	METHOD_ADD(IC, CONSTRUCT_TRANSPOSE_MTID, Inter::Val::transpose);
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
	if (Inter::Annotations::exist(&(ilp->set))) { *E = Inter::Errors::plain(I"__annotations are not allowed", eloc); return; }

	*E = Inter::Defn::vet_level(IBM, VAL_IST, ilp->indent_level, eloc);
	if (*E) return;

	inter_package *routine = Inter::Defn::get_latest_block_package();
	if (routine == NULL) { *E = Inter::Errors::plain(I"'val' used outside function", eloc); return; }
	inter_symbols_table *locals = InterPackage::scope(routine);
	if (locals == NULL) { *E = Inter::Errors::plain(I"function has no symbols table", eloc); return; }

	inter_symbol *val_kind = Inter::Textual::find_symbol(InterBookmark::tree(IBM), eloc, InterBookmark::scope(IBM), ilp->mr.exp[0], KIND_IST, E);
	if (*E) return;

	inter_ti val1 = 0;
	inter_ti val2 = 0;

	inter_symbol *kind_as_value = Inter::Textual::find_symbol(InterBookmark::tree(IBM), eloc, InterBookmark::scope(IBM), ilp->mr.exp[1], KIND_IST, E);
	*E = NULL;
	if (kind_as_value) {
		InterSymbol::to_data(InterBookmark::tree(IBM), InterBookmark::package(IBM), kind_as_value, &val1, &val2);
	} else {
		*E = Inter::Types::read(ilp->line, eloc, InterBookmark::tree(IBM), InterBookmark::package(IBM), val_kind, ilp->mr.exp[1], &val1, &val2, locals);
		if (*E) return;
	}

	*E = Inter::Val::new(IBM, val_kind, ilp->indent_level, val1, val2, eloc);
}

inter_error_message *Inter::Val::new(inter_bookmark *IBM, inter_symbol *val_kind, int level, inter_ti val1, inter_ti val2, inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_4_data_fields(IBM, VAL_IST, 0, InterSymbolsTable::id_from_symbol_at_bookmark(IBM, val_kind), val1, val2, eloc, (inter_ti) level);
	inter_error_message *E = Inter::Defn::verify_construct(InterBookmark::package(IBM), P); if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void Inter::Val::transpose(inter_construct *IC, inter_tree_node *P, inter_ti *grid, inter_ti grid_extent, inter_error_message **E) {
	P->W.instruction[VAL2_VAL_IFLD] = Inter::Types::transpose_value(P->W.instruction[VAL1_VAL_IFLD], P->W.instruction[VAL2_VAL_IFLD], grid, grid_extent, E);
}

void Inter::Val::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	if (P->W.extent != EXTENT_VAL_IFR) { *E = Inode::error(P, I"extent wrong", NULL); return; }
	inter_symbols_table *locals = InterPackage::scope(owner);
	if (locals == NULL) { *E = Inode::error(P, I"function has no symbols table", NULL); return; }
	*E = Inter::Verify::symbol(owner, P, P->W.instruction[KIND_VAL_IFLD], KIND_IST); if (*E) return;
	inter_symbol *val_kind = InterSymbolsTable::symbol_from_ID(InterPackage::scope(owner), P->W.instruction[KIND_VAL_IFLD]);
	*E = Inter::Verify::local_value(P, VAL1_VAL_IFLD, val_kind, locals); if (*E) return;
}

void Inter::Val::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	inter_symbols_table *locals = InterPackage::scope_of(P);
	if (locals == NULL) { *E = Inode::error(P, I"function has no symbols table", NULL); return; }
	inter_symbol *val_kind = InterSymbolsTable::symbol_from_ID_at_node(P, KIND_VAL_IFLD);
	if (val_kind) {
		WRITE("val %S ", val_kind->symbol_name);
		Inter::Types::write(OUT, P, val_kind, P->W.instruction[VAL1_VAL_IFLD], P->W.instruction[VAL2_VAL_IFLD], locals, FALSE);
	} else { *E = Inode::error(P, I"cannot write val", NULL); return; }
}
