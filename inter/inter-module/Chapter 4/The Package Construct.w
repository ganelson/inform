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
	METHOD_ADD(IC, CONSTRUCT_TRANSPOSE_MTID, Inter::Package::transpose);
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
void Inter::Package::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	*E = Inter::Defn::vet_level(IBM, PACKAGE_IST, ilp->indent_level, eloc);
	if (*E) return;

	inter_symbol *package_name = Inter::Textual::new_symbol(eloc, Inter::Bookmarks::scope(IBM), ilp->mr.exp[0], E);
	if (*E) return;

	inter_symbol *ptype_name = Inter::Textual::find_symbol(Inter::Bookmarks::tree(IBM), eloc, Inter::Tree::global_scope(Inter::Bookmarks::tree(IBM)), ilp->mr.exp[1], PACKAGETYPE_IST, E);
	if (*E) return;

	inter_package *pack = NULL;
	*E = Inter::Package::new_package(IBM, package_name, ptype_name, (inter_t) ilp->indent_level, eloc, &pack);
	if (*E) return;

	Inter::Bookmarks::set_current_package(IBM, pack);
}

inter_error_message *Inter::Package::new_package(inter_bookmark *IBM, inter_symbol *package_name, inter_symbol *ptype_name, inter_t level, inter_error_location *eloc, inter_package **created) {
	inter_t STID = Inter::Warehouse::create_symbols_table(Inter::Bookmarks::warehouse(IBM));
	inter_tree_node *P = Inter::Node::fill_4(IBM,
		PACKAGE_IST, Inter::SymbolsTables::id_from_IRS_and_symbol(IBM, package_name), Inter::SymbolsTables::id_from_symbol(Inter::Bookmarks::tree(IBM), NULL, ptype_name), STID, 0, eloc, level);
	inter_error_message *E = Inter::Defn::verify_construct(Inter::Bookmarks::package(IBM), P);
	if (E) return E;
	Inter::Bookmarks::insert(IBM, P);

	inter_t PID = Inter::Warehouse::create_package(Inter::Bookmarks::warehouse(IBM), Inter::Bookmarks::tree(IBM));
	inter_package *pack = Inter::Warehouse::get_package(Inter::Bookmarks::warehouse(IBM), PID);
	pack->package_head = P;
	Inter::Packages::set_name(pack, package_name);
	if (ptype_name == code_packagetype) Inter::Packages::make_codelike(pack);
	if ((linkage_packagetype) && (ptype_name == linkage_packagetype))
		Inter::Packages::make_linklike(pack);
	Inter::Packages::set_scope(pack, Inter::Package::local_symbols(package_name));
	P->W.data[PID_PACKAGE_IFLD] = PID;
	Inter::Warehouse::attribute_resource(Inter::Bookmarks::warehouse(IBM), STID, pack);

	if (created) *created = pack;
	LOGIF(INTER_SYMBOLS, "Package $6 at IBM $5\n", pack, IBM);

	return NULL;
}

void Inter::Package::transpose(inter_construct *IC, inter_tree_node *P, inter_t *grid, inter_t grid_extent, inter_error_message **E) {
	P->W.data[PID_PACKAGE_IFLD] = grid[P->W.data[PID_PACKAGE_IFLD]];
	P->W.data[SYMBOLS_PACKAGE_IFLD] = grid[P->W.data[SYMBOLS_PACKAGE_IFLD]];
}

void Inter::Package::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	*E = Inter::Verify::defn(owner, P, DEFN_PACKAGE_IFLD); if (*E) return;
	inter_symbols_table *T = Inter::Packages::scope(owner);
	if (T == NULL) T = Inter::Node::globals(P);
	inter_symbol *package_name = Inter::SymbolsTables::symbol_from_id(T, P->W.data[DEFN_PACKAGE_IFLD]);
	Inter::Defn::set_latest_package_symbol(package_name);
}

void Inter::Package::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	inter_symbol *package_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_PACKAGE_IFLD);
	inter_symbol *ptype_name = Inter::SymbolsTables::global_symbol_from_frame_data(P, PTYPE_PACKAGE_IFLD);
	if ((package_name) && (ptype_name)) {
		WRITE("package %S %S", package_name->symbol_name, ptype_name->symbol_name);
	} else {
		if (package_name == NULL) { *E = Inter::Node::error(P, I"package can't be written - no name", NULL); return; }
		*E = Inter::Node::error(P, I"package can't be written - no type", NULL); return;
	}
}

inter_error_message *Inter::Package::write_symbols(OUTPUT_STREAM, inter_tree_node *P) {
	inter_symbol *package_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_PACKAGE_IFLD);
	if (package_name) {
		inter_symbols_table *locals = Inter::Package::local_symbols(package_name);
		Inter::SymbolsTables::write_declarations(OUT, locals, (int) (P->W.data[LEVEL_IFLD] + 1));
	}
	return NULL;
}

int Inter::Package::is(inter_symbol *package_name) {
	if (package_name == NULL) return FALSE;
	inter_tree_node *D = Inter::Symbols::definition(package_name);
	if (D == NULL) return FALSE;
	if (D->W.data[ID_IFLD] != PACKAGE_IST) return FALSE;
	return TRUE;
}

inter_package *Inter::Package::which(inter_symbol *package_name) {
	if (package_name == NULL) return NULL;
	inter_tree_node *D = Inter::Symbols::definition(package_name);
	if (D == NULL) return NULL;
	return Inter::Node::ID_to_package(D, D->W.data[PID_PACKAGE_IFLD]);
}

inter_package *Inter::Package::defined_by_frame(inter_tree_node *D) {
	if (D == NULL) return NULL;
	if (D->W.data[ID_IFLD] != PACKAGE_IST) return NULL;
	return Inter::Node::ID_to_package(D, D->W.data[PID_PACKAGE_IFLD]);
}

inter_symbol *Inter::Package::type(inter_symbol *package_name) {
	if (package_name == NULL) return NULL;
	inter_tree_node *D = Inter::Symbols::definition(package_name);
	if (D == NULL) return NULL;
	if (D->W.data[ID_IFLD] != PACKAGE_IST) return NULL;
	inter_symbol *ptype_name = Inter::SymbolsTables::global_symbol_from_frame_data(D, PTYPE_PACKAGE_IFLD);
	return ptype_name;
}

inter_symbols_table *Inter::Package::local_symbols(inter_symbol *package_name) {
	if (package_name == NULL) return NULL;
	inter_tree_node *D = Inter::Symbols::definition(package_name);
	if (D == NULL) return NULL;
	if (D->W.data[ID_IFLD] != PACKAGE_IST) return NULL;
	return Inter::Node::ID_to_symbols_table(D, D->W.data[SYMBOLS_PACKAGE_IFLD]);
}

void Inter::Package::verify_children(inter_construct *IC, inter_tree_node *P, inter_error_message **E) {
	inter_symbol *ptype_name = Inter::SymbolsTables::global_symbol_from_frame_data(P, PTYPE_PACKAGE_IFLD);
	if (ptype_name == code_packagetype) {
		LOOP_THROUGH_INTER_CHILDREN(C, P) {
			if ((C->W.data[0] != LABEL_IST) && (C->W.data[0] != LOCAL_IST) && (C->W.data[0] != SYMBOL_IST)) {
				*E = Inter::Node::error(C, I"only a local or a symbol can be at the top level", NULL);
				return;
			}
		}
	}
}
