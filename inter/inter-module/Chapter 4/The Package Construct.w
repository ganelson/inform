[Inter::Package::] The Package Construct.

Defining the package construct.

@

@e PACKAGE_IST

=
void Inter::Package::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		PACKAGE_IST,
		L"package (%i+) (%i+)",
		I"package", I"packages");
	IC->usage_permissions = OUTSIDE_OF_PACKAGES + INSIDE_PLAIN_PACKAGE + CAN_HAVE_CHILDREN;
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::Package::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, Inter::Package::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::Package::write);
	METHOD_ADD(IC, VERIFY_INTER_CHILDREN_MTID, Inter::Package::verify_children);
}

@

@d DEFN_PACKAGE_IFLD 2
@d PTYPE_PACKAGE_IFLD 3
@d SYMBOLS_PACKAGE_IFLD 4
@d PID_PACKAGE_IFLD 5

=
void Inter::Package::read(inter_construct *IC, inter_reading_state *IRS, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	*E = Inter::Defn::vet_level(IRS, PACKAGE_IST, ilp->indent_level, eloc);
	if (*E) return;

	inter_symbol *package_name = Inter::Textual::new_symbol(eloc, Inter::Bookmarks::scope(IRS), ilp->mr.exp[0], E);
	if (*E) return;

	inter_symbol *ptype_name = Inter::Textual::find_symbol(IRS->read_into, eloc, Inter::get_global_symbols(IRS->read_into), ilp->mr.exp[1], PACKAGETYPE_IST, E);
	if (*E) return;

	inter_package *pack = NULL;
	*E = Inter::Package::new_package(IRS, package_name, ptype_name, (inter_t) ilp->indent_level, eloc, &pack);
	if (*E) return;

	Inter::Defn::set_current_package(IRS, pack);
}

inter_error_message *Inter::Package::new_package(inter_reading_state *IRS, inter_symbol *package_name, inter_symbol *ptype_name, inter_t level, inter_error_location *eloc, inter_package **created) {
	inter_t STID = Inter::create_symbols_table(IRS->read_into);
	LOGIF(INTER_SYMBOLS, "Package $3 at IRS $5\n", package_name, IRS);
	inter_frame P = Inter::Frame::fill_4(IRS,
		PACKAGE_IST, Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, package_name), Inter::SymbolsTables::id_from_symbol(IRS->read_into, NULL, ptype_name), STID, 0, eloc, level);
	inter_error_message *E = Inter::Defn::verify_construct(IRS->current_package, P);
	if (E) return E;
	Inter::Frame::insert(P, IRS);

	inter_t PID = Inter::create_package(IRS->read_into);
	inter_package *pack = Inter::Packages::from_PID(IRS->read_into, PID);
	Inter::Packages::set_name(pack, package_name);
	if (ptype_name == code_packagetype) Inter::Packages::make_codelike(pack);
	Inter::Packages::set_scope(pack, Inter::Package::local_symbols(package_name));
	P.data[PID_PACKAGE_IFLD] = PID;

	if (created) *created = pack;

	return NULL;
}

void Inter::Package::verify(inter_construct *IC, inter_frame P, inter_package *owner, inter_error_message **E) {
	*E = Inter__Verify__defn(owner, P, DEFN_PACKAGE_IFLD); if (*E) return;
	inter_symbols_table *T = Inter::Packages::scope(owner);
	if (T == NULL) T = Inter::get_global_symbols(P.repo_segment->owning_repo);
	inter_symbol *package_name = Inter::SymbolsTables::symbol_from_id(T, P.data[DEFN_PACKAGE_IFLD]);
	Inter::Defn::set_latest_package_symbol(package_name);
}

void Inter::Package::write(inter_construct *IC, OUTPUT_STREAM, inter_frame P, inter_error_message **E) {
	inter_symbol *package_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_PACKAGE_IFLD);
	inter_symbol *ptype_name = Inter::SymbolsTables::global_symbol_from_frame_data(P, PTYPE_PACKAGE_IFLD);
	if ((package_name) && (ptype_name)) {
		WRITE("package %S %S", package_name->symbol_name, ptype_name->symbol_name);
	} else {
		if (package_name == NULL) { *E = Inter::Frame::error(&P, I"package can't be written - no name", NULL); return; }
		*E = Inter::Frame::error(&P, I"package can't be written - no type", NULL); return;
	}
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

inter_package *Inter::Package::defined_by_frame(inter_frame D) {
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

void Inter::Package::verify_children(inter_construct *IC, inter_frame P, inter_error_message **E) {
	inter_symbol *ptype_name = Inter::SymbolsTables::global_symbol_from_frame_data(P, PTYPE_PACKAGE_IFLD);
	if (ptype_name == code_packagetype) {
		LOOP_THROUGH_INTER_CHILDREN(C, P) {
			if ((C.data[0] != LABEL_IST) && (C.data[0] != LOCAL_IST) && (C.data[0] != SYMBOL_IST)) {
				*E = Inter::Frame::error(&C, I"only a local or a symbol can be at the top level", NULL);
				return;
			}
		}
	}
}
