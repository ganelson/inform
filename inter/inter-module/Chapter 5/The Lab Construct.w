[Inter::Lab::] The Lab Construct.

Defining the Lab construct.

@

@e LAB_IST

=
void Inter::Lab::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		LAB_IST,
		L"lab (%C+)",
		I"lab", I"labs");
	IC->min_level = 1;
	IC->max_level = 100000000;
	IC->usage_permissions = INSIDE_CODE_PACKAGE;
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::Lab::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, Inter::Lab::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::Lab::write);
}

@

@d BLOCK_LAB_IFLD 2
@d LABEL_LAB_IFLD 3

@d EXTENT_LAB_IFR 4

=
void Inter::Lab::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	if (ilp->no_annotations > 0) { *E = Inter::Errors::plain(I"__annotations are not allowed", eloc); return; }

	*E = Inter::Defn::vet_level(IBM, LAB_IST, ilp->indent_level, eloc);
	if (*E) return;

	inter_symbol *routine = Inter::Defn::get_latest_block_symbol();
	if (routine == NULL) { *E = Inter::Errors::plain(I"'lab' used outside function", eloc); return; }
	inter_symbols_table *locals = Inter::Package::local_symbols(routine);
	if (locals == NULL) { *E = Inter::Errors::plain(I"function has no symbols table", eloc); return; }

	inter_symbol *label = Inter::SymbolsTables::symbol_from_name(locals, ilp->mr.exp[0]);
	if (Inter::Symbols::is_label(label) == FALSE) { *E = Inter::Errors::plain(I"not a label", eloc); return; }

	*E = Inter::Lab::new(IBM, routine, label, (inter_t) ilp->indent_level, eloc);
}

inter_error_message *Inter::Lab::new(inter_bookmark *IBM, inter_symbol *routine, inter_symbol *label, inter_t level, inter_error_location *eloc) {
	inter_tree_node *P = Inter::Frame::fill_2(IBM, LAB_IST, 0, Inter::SymbolsTables::id_from_IRS_and_symbol(IBM, label), eloc, (inter_t) level);
	inter_error_message *E = Inter::Defn::verify_construct(Inter::Bookmarks::package(IBM), P); if (E) return E;
	Inter::insert(P, IBM);
	return NULL;
}

void Inter::Lab::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	if (P->W.extent != EXTENT_LAB_IFR) { *E = Inter::Frame::error(P, I"extent wrong", NULL); return; }
	inter_symbol *routine = owner->package_name;
	inter_symbol *label = Inter::SymbolsTables::local_symbol_from_id(routine, P->W.data[LABEL_LAB_IFLD]);
	if (Inter::Symbols::is_label(label) == FALSE) { *E = Inter::Frame::error(P, I"no such label", NULL); return; }
}

void Inter::Lab::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	inter_package *pack = Inter::Packages::container(P);
	inter_symbol *routine = pack->package_name;
	inter_symbol *label = Inter::SymbolsTables::local_symbol_from_id(routine, P->W.data[LABEL_LAB_IFLD]);
	if (label) {
		WRITE("lab %S", label->symbol_name);
	} else { *E = Inter::Frame::error(P, I"cannot write lab", NULL); return; }
}

inter_symbol *Inter::Lab::label_symbol(inter_tree_node *P) {
	inter_package *pack = Inter::Packages::container(P);
	inter_symbol *routine = pack->package_name;
	if (Inter::Package::is(routine) == FALSE) internal_error("bad lab");
	inter_symbol *lab = Inter::SymbolsTables::local_symbol_from_id(routine, P->W.data[LABEL_LAB_IFLD]);
	if (lab == NULL) internal_error("bad lab");
	return lab;
}
