[Inter::Refcatenate::] The Refcatenate Construct.

Defining the Refcatenate construct.

@

@e REFCATENATE_IST

=
void Inter::Refcatenate::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		REFCATENATE_IST,
		L"refcatenate (%i+) (%C+)",
		&Inter::Refcatenate::read,
		NULL,
		&Inter::Refcatenate::verify,
		&Inter::Refcatenate::write,
		NULL,
		&Inter::Refcatenate::accept_child,
		&Inter::Refcatenate::no_more_children,
		&Inter::Refcatenate::show_dependencies,
		I"refcatenate", I"refcatenates");
	IC->min_level = 1;
	IC->max_level = 100000000;
	IC->usage_permissions = INSIDE_CODE_PACKAGE;
}

@

@d BLOCK_RCAT_IFLD 2
@d KIND_RCAT_IFLD 3
@d VAL1_RCAT_IFLD 4
@d VAL2_RCAT_IFLD 5
@d CODE_RCAT_IFLD 6

@d EXTENT_RCAT_IFR 7

=
inter_error_message *Inter::Refcatenate::read(inter_reading_state *IRS, inter_line_parse *ilp, inter_error_location *eloc) {
	if (ilp->no_annotations > 0) return Inter::Errors::plain(I"__annotations are not allowed", eloc);

	inter_error_message *E = Inter::Defn::vet_level(IRS, REFCATENATE_IST, ilp->indent_level, eloc);
	if (E) return E;

	inter_symbol *routine = Inter::Defn::get_latest_block_symbol();
	if (routine == NULL) return Inter::Errors::plain(I"'refcatenate' used outside function", eloc);
	inter_symbols_table *locals = Inter::Package::local_symbols(routine);
	if (locals == NULL) return Inter::Errors::plain(I"function has no symbols table", eloc);

	inter_symbol *val_kind = NULL;

	if (!(Str::eq(ilp->mr.exp[0], I"_"))) {
		val_kind = Inter::Textual::find_symbol(IRS->read_into, eloc, Inter::Bookmarks::scope(IRS), ilp->mr.exp[0], KIND_IST, &E);
		if (E) return E;
	}

	inter_t val1 = 0;
	inter_t val2 = 0;
	if (!(Str::eq(ilp->mr.exp[1], I"_"))) {
		E = Inter::Types::read(ilp->line, eloc, IRS->read_into, IRS->current_package, val_kind, ilp->mr.exp[1], &val1, &val2, locals);
		if (E) return E;
	} else {
		val1 = UNDEF_IVAL;
	}

	return Inter::Refcatenate::new(IRS, routine, val_kind, ilp->indent_level, val1, val2, eloc);
}

inter_error_message *Inter::Refcatenate::new(inter_reading_state *IRS, inter_symbol *routine, inter_symbol *val_kind, int level, inter_t val1, inter_t val2, inter_error_location *eloc) {
	inter_frame P = Inter::Frame::fill_5(IRS, REFCATENATE_IST, 0,
		(val_kind)?(Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, val_kind)):0, val1, val2, Inter::create_frame_list(IRS->read_into), eloc, (inter_t) level);
	inter_error_message *E = Inter::Defn::verify_construct(P); if (E) return E;
	Inter::Frame::insert(P, IRS);
	return NULL;
}

inter_error_message *Inter::Refcatenate::verify(inter_frame P) {
	if (P.extent != EXTENT_RCAT_IFR) return Inter::Frame::error(&P, I"extent wrong", NULL);
	inter_symbols_table *locals = Inter::Packages::scope_of(P);
	if (locals == NULL) return Inter::Frame::error(&P, I"function has no symbols table", NULL);
	if ((P.data[KIND_RCAT_IFLD] != 0) || (P.data[VAL1_RCAT_IFLD] != UNDEF_IVAL)) {
		inter_error_message *E = Inter::Verify::symbol(P, P.data[KIND_RCAT_IFLD], KIND_IST); if (E) return E;
		inter_symbol *val_kind = Inter::SymbolsTables::symbol_from_frame_data(P, KIND_RCAT_IFLD);
		E = Inter::Verify::local_value(P, VAL1_RCAT_IFLD, val_kind, locals); if (E) return E;
	}
	return NULL;
}

inter_error_message *Inter::Refcatenate::write(OUTPUT_STREAM, inter_frame P) {
	inter_symbols_table *locals = Inter::Packages::scope_of(P);
	if (locals == NULL) return Inter::Frame::error(&P, I"function has no symbols table", NULL);
	inter_symbol *val_kind = Inter::SymbolsTables::symbol_from_frame_data(P, KIND_RCAT_IFLD);
	if (val_kind) {
		WRITE("refcatenate %S ", val_kind->symbol_name);
		Inter::Types::write(OUT, P.repo_segment->owning_repo, val_kind, P.data[VAL1_RCAT_IFLD], P.data[VAL2_RCAT_IFLD], locals, FALSE);
	} else {
		WRITE("refcatenate _ _");
	}
	return NULL;
}

void Inter::Refcatenate::show_dependencies(inter_frame P, void (*callback)(struct inter_symbol *, struct inter_symbol *, void *), void *state) {
	inter_package *pack = Inter::Packages::container(P);
	inter_symbol *routine = pack->package_name;
	inter_symbol *val_kind = Inter::SymbolsTables::symbol_from_frame_data(P, KIND_RCAT_IFLD);
	if ((routine) && (val_kind)) {
		(*callback)(routine, val_kind, state);
		inter_t v1 = P.data[VAL1_RCAT_IFLD], v2 = P.data[VAL2_RCAT_IFLD];
		inter_symbol *S = Inter::SymbolsTables::symbol_from_data_pair_and_frame(v1, v2, P);
		if (S) (*callback)(routine, S, state);
	}
}

inter_error_message *Inter::Refcatenate::accept_child(inter_frame P, inter_frame C) {
	if ((C.data[0] != INV_IST) && (C.data[0] != REF_IST) && (C.data[0] != SPLAT_IST) && (C.data[0] != VAL_IST) && (C.data[0] != LABEL_IST))
		return Inter::Frame::error(&C, I"only an inv, a ref, a splat, a val, or a label can be below a refcatenate", NULL);
	Inter::add_to_frame_list(Inter::find_frame_list(P.repo_segment->owning_repo, P.data[CODE_RCAT_IFLD]), C, NULL);
	return NULL;
}

inter_error_message *Inter::Refcatenate::no_more_children(inter_frame P) {
	return NULL;
}

inter_frame_list *Inter::Refcatenate::refcatenate_list(inter_symbol *label_name) {
	if (label_name == NULL) return NULL;
	inter_frame D = Inter::Symbols::defining_frame(label_name);
	if (Inter::Frame::valid(&D) == FALSE) return NULL;
	if (D.data[ID_IFLD] != REFCATENATE_IST) return NULL;
	return Inter::find_frame_list(D.repo_segment->owning_repo, D.data[CODE_RCAT_IFLD]);
}
