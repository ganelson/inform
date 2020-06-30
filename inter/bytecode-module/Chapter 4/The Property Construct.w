[Inter::Property::] The Property Construct.

Defining the property construct.

@

@e PROPERTY_IST

=
void Inter::Property::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		PROPERTY_IST,
		L"property (%i+) (%i+)",
		I"property", I"properties");
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::Property::read);
	METHOD_ADD(IC, CONSTRUCT_TRANSPOSE_MTID, Inter::Property::transpose);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, Inter::Property::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::Property::write);
}

@

@d DEFN_PROP_IFLD 2
@d KIND_PROP_IFLD 3
@d PERM_LIST_PROP_IFLD 4

@d EXTENT_PROP_IFR 5

=
void Inter::Property::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	*E = Inter::Defn::vet_level(IBM, PROPERTY_IST, ilp->indent_level, eloc);
	if (*E) return;

	inter_symbol *prop_name = Inter::Textual::new_symbol(eloc, Inter::Bookmarks::scope(IBM), ilp->mr.exp[0], E);
	if (*E) return;
	inter_symbol *prop_kind = Inter::Textual::find_symbol(Inter::Bookmarks::tree(IBM), eloc, Inter::Bookmarks::scope(IBM), ilp->mr.exp[1], KIND_IST, E);
	if (*E) return;

	Inter::Annotations::copy_set_to_symbol(&(ilp->set), prop_name);

	*E = Inter::Property::new(IBM, Inter::SymbolsTables::id_from_IRS_and_symbol(IBM, prop_name), Inter::SymbolsTables::id_from_IRS_and_symbol(IBM, prop_kind), (inter_ti) ilp->indent_level, eloc);
}

inter_error_message *Inter::Property::new(inter_bookmark *IBM, inter_ti PID, inter_ti KID, inter_ti level, inter_error_location *eloc) {
	inter_warehouse *warehouse = Inter::Bookmarks::warehouse(IBM);
	inter_ti L1 = Inter::Warehouse::create_frame_list(warehouse);
	Inter::Warehouse::attribute_resource(warehouse, L1, Inter::Bookmarks::package(IBM));
	inter_tree_node *P = Inode::fill_3(IBM, PROPERTY_IST, PID, KID, L1, eloc, level);
	inter_error_message *E = Inter::Defn::verify_construct(Inter::Bookmarks::package(IBM), P);
	if (E) return E;
	Inter::Bookmarks::insert(IBM, P);
	return NULL;
}

void Inter::Property::transpose(inter_construct *IC, inter_tree_node *P, inter_ti *grid, inter_ti grid_extent, inter_error_message **E) {
	P->W.data[PERM_LIST_PROP_IFLD] = grid[P->W.data[PERM_LIST_PROP_IFLD]];
}

void Inter::Property::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	if (P->W.extent != EXTENT_PROP_IFR) { *E = Inode::error(P, I"extent wrong", NULL); return; }
	*E = Inter::Verify::defn(owner, P, DEFN_PROP_IFLD); if (*E) return;
	*E = Inter::Verify::symbol(owner, P, P->W.data[KIND_PROP_IFLD], KIND_IST);
}

inter_ti Inter::Property::permissions_list(inter_symbol *prop_name) {
	if (prop_name == NULL) return 0;
	inter_tree_node *D = Inter::Symbols::definition(prop_name);
	if (D == NULL) return 0;
	return D->W.data[PERM_LIST_PROP_IFLD];
}

void Inter::Property::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	inter_symbol *prop_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_PROP_IFLD);
	inter_symbol *prop_kind = Inter::SymbolsTables::symbol_from_frame_data(P, KIND_PROP_IFLD);
	if ((prop_name) && (prop_kind)) {
		WRITE("property %S %S", prop_name->symbol_name, prop_kind->symbol_name);
		Inter::Symbols::write_annotations(OUT, P, prop_name);
	} else { *E = Inode::error(P, I"cannot write property", NULL); return; }
}

inter_symbol *Inter::Property::kind_of(inter_symbol *prop_symbol) {
	if (prop_symbol == NULL) return NULL;
	inter_tree_node *D = Inter::Symbols::definition(prop_symbol);
	if (D == NULL) return NULL;
	if (D->W.data[ID_IFLD] != PROPERTY_IST) return NULL;
	return Inter::SymbolsTables::symbol_from_frame_data(D, KIND_PROP_IFLD);
}
