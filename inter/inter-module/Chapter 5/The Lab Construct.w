[Inter::Lab::] The Lab Construct.

Defining the Lab construct.

@

@e LAB_IST

=
void Inter::Lab::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		LAB_IST,
		L"lab (%C+)",
		&Inter::Lab::read,
		NULL,
		&Inter::Lab::verify,
		&Inter::Lab::write,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		I"lab", I"labs");
	IC->min_level = 1;
	IC->max_level = 100000000;
	IC->usage_permissions = INSIDE_CODE_PACKAGE;
}

@

@d BLOCK_LAB_IFLD 2
@d LABEL_LAB_IFLD 3

@d EXTENT_LAB_IFR 4

=
inter_error_message *Inter::Lab::read(inter_reading_state *IRS, inter_line_parse *ilp, inter_error_location *eloc) {
	if (ilp->no_annotations > 0) return Inter::Errors::plain(I"__annotations are not allowed", eloc);

	inter_error_message *E = Inter::Defn::vet_level(IRS, LAB_IST, ilp->indent_level, eloc);
	if (E) return E;

	inter_symbol *routine = Inter::Defn::get_latest_block_symbol();
	if (routine == NULL) return Inter::Errors::plain(I"'lab' used outside function", eloc);
	inter_symbols_table *locals = Inter::Package::local_symbols(routine);
	if (locals == NULL) return Inter::Errors::plain(I"function has no symbols table", eloc);

	inter_symbol *label = Inter::SymbolsTables::symbol_from_name(locals, ilp->mr.exp[0]);
	if (Inter::Symbols::is_label(label) == FALSE) return Inter::Errors::plain(I"not a label", eloc);

	return Inter::Lab::new(IRS, routine, label, (inter_t) ilp->indent_level, eloc);
}

inter_error_message *Inter::Lab::new(inter_reading_state *IRS, inter_symbol *routine, inter_symbol *label, inter_t level, inter_error_location *eloc) {
	inter_frame P = Inter::Frame::fill_2(IRS, LAB_IST, 0, Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, label), eloc, (inter_t) level);
	inter_error_message *E = Inter::Defn::verify_construct(P); if (E) return E;
	Inter::Frame::insert(P, IRS);
	return NULL;
}

inter_error_message *Inter::Lab::verify(inter_frame P) {
	if (P.extent != EXTENT_LAB_IFR) return Inter::Frame::error(&P, I"extent wrong", NULL);
	inter_package *pack = Inter::Packages::container(P);
	inter_symbol *routine = pack->package_name;
	inter_symbol *label = Inter::SymbolsTables::local_symbol_from_id(routine, P.data[LABEL_LAB_IFLD]);
	if (Inter::Symbols::is_label(label) == FALSE) return Inter::Frame::error(&P, I"no such label", NULL);
	return NULL;
}

inter_error_message *Inter::Lab::write(OUTPUT_STREAM, inter_frame P) {
	inter_package *pack = Inter::Packages::container(P);
	inter_symbol *routine = pack->package_name;
	inter_symbol *label = Inter::SymbolsTables::local_symbol_from_id(routine, P.data[LABEL_LAB_IFLD]);
	if (label) {
		WRITE("lab %S", label->symbol_name);
	} else return Inter::Frame::error(&P, I"cannot write lab", NULL);
	return NULL;
}

inter_symbol *Inter::Lab::label_symbol(inter_frame P) {
	inter_package *pack = Inter::Packages::container(P);
	inter_symbol *routine = pack->package_name;
	if (Inter::Package::is(routine) == FALSE) internal_error("bad lab");
	inter_symbol *lab = Inter::SymbolsTables::local_symbol_from_id(routine, P.data[LABEL_LAB_IFLD]);
	if (lab == NULL) internal_error("bad lab");
	return lab;
}
