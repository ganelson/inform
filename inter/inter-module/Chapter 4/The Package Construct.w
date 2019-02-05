[Inter::Package::] The Package Construct.

Defining the package construct.

@

@e PACKAGE_IST

=
void Inter::Package::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		PACKAGE_IST,
		L"package (%i+) (%i+)",
		&Inter::Package::read,
		NULL,
		&Inter::Package::verify,
		&Inter::Package::write,
		NULL,
		&Inter::Package::accept_child,
		&Inter::Package::no_more_children,
		NULL,
		I"package", I"packages");
	IC->usage_permissions = OUTSIDE_OF_PACKAGES + INSIDE_PLAIN_PACKAGE;
}

@

@d DEFN_PACKAGE_IFLD 2
@d PTYPE_PACKAGE_IFLD 3
@d CODE_PACKAGE_IFLD 4
@d SYMBOLS_PACKAGE_IFLD 5
@d PID_PACKAGE_IFLD 6

=
inter_error_message *Inter::Package::read(inter_reading_state *IRS, inter_line_parse *ilp, inter_error_location *eloc) {
	inter_error_message *E = Inter::Defn::vet_level(IRS, PACKAGE_IST, ilp->indent_level, eloc);
	if (E) return E;

	inter_symbol *package_name = Inter::Textual::new_symbol(eloc, Inter::Bookmarks::scope(IRS), ilp->mr.exp[0], &E);
	if (E) return E;

	inter_symbol *ptype_name = Inter::Textual::find_symbol(IRS->read_into, eloc, Inter::get_global_symbols(IRS->read_into), ilp->mr.exp[1], PACKAGETYPE_IST, &E);
	if (E) return E;

	inter_package *pack = NULL;
	E = Inter::Package::new_package(IRS, package_name, ptype_name, (inter_t) ilp->indent_level, eloc, &pack);
	if (E) return E;

	Inter::Defn::set_current_package(IRS, pack);
	return NULL;
}

inter_error_message *Inter::Package::new_package(inter_reading_state *IRS, inter_symbol *package_name, inter_symbol *ptype_name, inter_t level, inter_error_location *eloc, inter_package **created) {
	inter_t STID = Inter::create_symbols_table(IRS->read_into);
	LOGIF(INTER_SYMBOLS, "Package $3 at IRS $5\n", package_name, IRS);
	inter_frame P = Inter::Frame::fill_5(IRS,
		PACKAGE_IST, Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, package_name), Inter::SymbolsTables::id_from_symbol(IRS->read_into, NULL, ptype_name), Inter::create_frame_list(IRS->read_into), STID, 0, eloc, level);
	inter_error_message *E = Inter::Defn::verify_construct(P);
	if (E) return E;
	Inter::Frame::insert(P, IRS);

	inter_t PID = Inter::create_package(IRS->read_into, IRS->current_package);
	inter_package *pack = Inter::Packages::from_PID(IRS->read_into, PID);
	Inter::Packages::set_name(pack, package_name);
	if (ptype_name == code_packagetype) pack->codelike_package = TRUE;
	Inter::Packages::set_scope(pack, Inter::Package::local_symbols(package_name));
	P.data[PID_PACKAGE_IFLD] = PID;

	if (created) *created = pack;

	return NULL;
}

inter_error_message *Inter::Package::verify(inter_frame P) {
	inter_error_message *E = Inter::Verify::defn(P, DEFN_PACKAGE_IFLD); if (E) return E;
	inter_symbol *package_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_PACKAGE_IFLD);
	Inter::Defn::set_latest_package_symbol(package_name);
	return NULL;
}

inter_error_message *Inter::Package::write(OUTPUT_STREAM, inter_frame P) {
	inter_symbol *package_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_PACKAGE_IFLD);
	inter_symbol *ptype_name = Inter::SymbolsTables::global_symbol_from_frame_data(P, PTYPE_PACKAGE_IFLD);
	if ((package_name) && (ptype_name)) {
		WRITE("package %S %S", package_name->symbol_name, ptype_name->symbol_name);
	} else {
		if (package_name == NULL) return Inter::Frame::error(&P, I"package can't be written - no name", NULL);
		return Inter::Frame::error(&P, I"package can't be written - no type", NULL);
	}
	return NULL;
}

inter_error_message *Inter::Package::write_symbols(OUTPUT_STREAM, inter_frame P) {
	inter_symbol *package_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_PACKAGE_IFLD);
	if (package_name) {
		inter_symbols_table *locals = Inter::Package::local_symbols(package_name);
		Inter::SymbolsTables::write_declarations(OUT, locals, (int) (P.data[LEVEL_IFLD] + 1));
	}
	return NULL;
}

int Inter::Package::is(inter_symbol *package_name) {
	if (package_name == NULL) return FALSE;
	inter_frame D = Inter::Symbols::defining_frame(package_name);
	if (Inter::Frame::valid(&D) == FALSE) return FALSE;
	if (D.data[ID_IFLD] != PACKAGE_IST) return FALSE;
	return TRUE;
}

inter_package *Inter::Package::which(inter_symbol *package_name) {
	if (package_name == NULL) return NULL;
	inter_frame D = Inter::Symbols::defining_frame(package_name);
	if (Inter::Frame::valid(&D) == FALSE) return NULL;
	if (D.data[ID_IFLD] != PACKAGE_IST) return NULL;
	return Inter::get_package(D.repo_segment->owning_repo, D.data[PID_PACKAGE_IFLD]);
}

inter_symbol *Inter::Package::type(inter_symbol *package_name) {
	if (package_name == NULL) return NULL;
	inter_frame D = Inter::Symbols::defining_frame(package_name);
	if (Inter::Frame::valid(&D) == FALSE) return NULL;
	if (D.data[ID_IFLD] != PACKAGE_IST) return NULL;
	inter_symbol *ptype_name = Inter::SymbolsTables::global_symbol_from_frame_data(D, PTYPE_PACKAGE_IFLD);
	return ptype_name;
}

inter_symbols_table *Inter::Package::local_symbols(inter_symbol *package_name) {
	if (package_name == NULL) return NULL;
	inter_frame D = Inter::Symbols::defining_frame(package_name);
	if (Inter::Frame::valid(&D) == FALSE) return NULL;
	if (D.data[ID_IFLD] != PACKAGE_IST) return NULL;
	return Inter::get_symbols_table(D.repo_segment->owning_repo, D.data[SYMBOLS_PACKAGE_IFLD]);
}

inter_frame_list *Inter::Package::code_list(inter_symbol *package_name) {
	if (package_name == NULL) return NULL;
	inter_frame D = Inter::Symbols::defining_frame(package_name);
	if (Inter::Frame::valid(&D) == FALSE) return NULL;
	if (D.data[ID_IFLD] != PACKAGE_IST) return NULL;
	return Inter::find_frame_list(D.repo_segment->owning_repo, D.data[CODE_PACKAGE_IFLD]);
}

inter_error_message *Inter::Package::accept_child(inter_frame P, inter_frame C) {
	inter_symbol *ptype_name = Inter::SymbolsTables::global_symbol_from_frame_data(P, PTYPE_PACKAGE_IFLD);
	if (ptype_name == code_packagetype) {
		if ((C.data[0] != LABEL_IST) && (C.data[0] != LOCAL_IST) && (C.data[0] != SYMBOL_IST))
			return Inter::Frame::error(&C, I"only a local or a symbol can be at the top level", NULL);
	}
	Inter::add_to_frame_list(Inter::find_frame_list(P.repo_segment->owning_repo, P.data[CODE_PACKAGE_IFLD]), C, NULL);
	return NULL;
}

inter_error_message *Inter::Package::no_more_children(inter_frame P) {
	return NULL;
}
