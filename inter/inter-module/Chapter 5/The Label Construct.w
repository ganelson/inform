[Inter::Label::] The Label Construct.

Defining the label construct.

@

@e LABEL_IST

=
void Inter::Label::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		LABEL_IST,
		L"(.%i+)",
		&Inter::Label::read,
		NULL,
		&Inter::Label::verify,
		&Inter::Label::write,
		NULL,
		&Inter::Label::accept_child,
		&Inter::Label::no_more_children,
		NULL,
		I"label", I"labels");
	IC->min_level = 0;
	IC->max_level = 100000000;
	IC->usage_permissions = INSIDE_CODE_PACKAGE;
}

@

@d BLOCK_LABEL_IFLD 2
@d DEFN_LABEL_IFLD 3
@d CODE_LABEL_IFLD 4

@d EXTENT_LABEL_IFR 5

=
inter_error_message *Inter::Label::read(inter_reading_state *IRS, inter_line_parse *ilp, inter_error_location *eloc) {
	if (ilp->no_annotations > 0) return Inter::Errors::plain(I"__annotations are not allowed", eloc);
	inter_error_message *E = Inter::Defn::vet_level(IRS, LABEL_IST, ilp->indent_level, eloc);
	if (E) return E;
	inter_symbol *routine = Inter::Defn::get_latest_block_symbol();
	if (routine == NULL) return Inter::Errors::plain(I"'label' used outside function", eloc);
	inter_symbols_table *locals = Inter::Package::local_symbols(routine);
	if (locals == NULL) return Inter::Errors::plain(I"function has no symbols table", eloc);

	inter_symbol *lab_name = Inter::SymbolsTables::symbol_from_name(locals, ilp->mr.exp[0]);
	if (Inter::Symbols::is_label(lab_name) == FALSE) return Inter::Errors::plain(I"not a label", eloc);

	return Inter::Label::new(IRS, routine, lab_name, (inter_t) ilp->indent_level, eloc);
}

inter_error_message *Inter::Label::new(inter_reading_state *IRS, inter_symbol *routine, inter_symbol *lab_name, inter_t level, inter_error_location *eloc) {
	inter_frame P = Inter::Frame::fill_3(IRS, LABEL_IST, 0, Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, lab_name), Inter::create_frame_list(IRS->read_into), eloc, level);
	inter_error_message *E = Inter::Defn::verify_construct(P); if (E) return E;
	Inter::Frame::insert(P, IRS);
	return NULL;
}

inter_error_message *Inter::Label::verify(inter_frame P) {
	if (P.extent != EXTENT_LABEL_IFR) return Inter::Frame::error(&P, I"extent wrong", NULL);
	inter_package *pack = Inter::Packages::container(P);
	inter_symbol *routine = pack->package_name;
	inter_symbol *lab_name = Inter::SymbolsTables::local_symbol_from_id(routine, P.data[DEFN_LABEL_IFLD]);
	if (Inter::Symbols::is_label(lab_name) == FALSE) {
		return Inter::Frame::error(&P, I"not a label", (lab_name)?(lab_name->symbol_name):NULL);
	}
	if (P.data[LEVEL_IFLD] < 1) return Inter::Frame::error(&P, I"label with bad level", NULL);
	return NULL;
}

inter_error_message *Inter::Label::write(OUTPUT_STREAM, inter_frame P) {
	inter_package *pack = Inter::Packages::container(P);
	inter_symbol *routine = pack->package_name;
	inter_symbol *lab_name = Inter::SymbolsTables::local_symbol_from_id(routine, P.data[DEFN_LABEL_IFLD]);
	if (lab_name) {
		WRITE("%S", lab_name->symbol_name);
	} else return Inter::Frame::error(&P, I"cannot write label", NULL);
	return NULL;
}

inter_error_message *Inter::Label::accept_child(inter_frame P, inter_frame C) {
	if ((C.data[0] != INV_IST) && (C.data[0] != SPLAT_IST) && (C.data[0] != CONCATENATE_IST) && (C.data[0] != LABEL_IST) && (C.data[0] != VAL_IST)) {
		inter_package *pack = Inter::Packages::container(P);
		inter_symbol *routine = pack->package_name;
		inter_symbol *lab_name = Inter::SymbolsTables::local_symbol_from_id(routine, P.data[DEFN_LABEL_IFLD]);
		LOG("C is: "); Inter::Defn::write_construct_text(DL, C);
		return Inter::Frame::error(&C, I"only an inv, a val, a splat, a concatenate or another label can be below a label", lab_name->symbol_name);
	}
	Inter::add_to_frame_list(Inter::find_frame_list(P.repo_segment->owning_repo, P.data[CODE_LABEL_IFLD]), C, NULL);
	return NULL;
}

inter_error_message *Inter::Label::no_more_children(inter_frame P) {
	return NULL;
}
