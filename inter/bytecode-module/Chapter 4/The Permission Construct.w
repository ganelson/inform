[Inter::Permission::] The Permission Construct.

Defining the permission construct.

@

@e PERMISSION_IST

=
void Inter::Permission::define(void) {
	inter_construct *IC = InterConstruct::create_construct(PERMISSION_IST, I"permission");
	InterConstruct::specify_syntax(IC, I"permission IDENTIFIER IDENTIFIER OPTIONALIDENTIFIER");
	InterConstruct::permit(IC, INSIDE_PLAIN_PACKAGE_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::Permission::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, Inter::Permission::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::Permission::write);
}

@

@d DEFN_PERM_IFLD 2
@d PROP_PERM_IFLD 3
@d OWNER_PERM_IFLD 4
@d STORAGE_PERM_IFLD 5

@d EXTENT_PERM_IFR 6

=
int pp_counter = 1;
void Inter::Permission::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	*E = InterConstruct::check_level_in_package(IBM, PERMISSION_IST, ilp->indent_level, eloc);
	if (*E) return;

	if (SymbolAnnotation::nonempty(&(ilp->set))) { *E = Inter::Errors::plain(I"__annotations are not allowed", eloc); return; }

	inter_symbol *prop_name = Inter::Textual::find_symbol(InterBookmark::tree(IBM), eloc, InterBookmark::scope(IBM), ilp->mr.exp[0], PROPERTY_IST, E);
	if (*E) return;
	inter_symbol *owner_name = Inter::Textual::find_KOI(eloc, InterBookmark::scope(IBM), ilp->mr.exp[1], E);
	if (*E) return;

	if (Inter::Kind::is(owner_name)) {
		if (Inter::Types::is_enumerated(Inter::Kind::data_type(owner_name)) == FALSE)
			{ *E = Inter::Errors::quoted(I"not a kind which can have property values", ilp->mr.exp[1], eloc); return; }

		inter_node_list *FL =
			InterWarehouse::get_node_list(
				InterBookmark::warehouse(IBM),
				Inter::Kind::permissions_list(owner_name));
		if (FL == NULL) internal_error("no permissions list");

		inter_tree_node *X;
		LOOP_THROUGH_INTER_NODE_LIST(X, FL) {
			inter_symbol *prop_allowed = InterSymbolsTable::symbol_from_ID_at_node(X, PROP_PERM_IFLD);
			if (prop_allowed == prop_name)
				{ *E = Inter::Errors::quoted(I"permission already given", ilp->mr.exp[0], eloc); return; }
		}
	} else {
		inter_node_list *FL =
			InterWarehouse::get_node_list(
				InterBookmark::warehouse(IBM),
				Inter::Instance::permissions_list(owner_name));
		if (FL == NULL) internal_error("no permissions list");

		inter_tree_node *X;
		LOOP_THROUGH_INTER_NODE_LIST(X, FL) {
			inter_symbol *prop_allowed = InterSymbolsTable::symbol_from_ID_at_node(X, PROP_PERM_IFLD);
			if (prop_allowed == prop_name)
				{ *E = Inter::Errors::quoted(I"permission already given", ilp->mr.exp[0], eloc); return; }
		}
	}

	TEMPORARY_TEXT(ident)
	WRITE_TO(ident, "pp_auto_%d", pp_counter++);
	inter_symbol *pp_name = Inter::Textual::new_symbol(eloc, InterBookmark::scope(IBM), ident, E);
	DISCARD_TEXT(ident)
	if (*E) return;

	inter_symbol *store = NULL;
	if (Str::len(ilp->mr.exp[2]) > 0) {
		store = Inter::Textual::find_symbol(InterBookmark::tree(IBM), eloc, InterBookmark::scope(IBM), ilp->mr.exp[2], CONSTANT_IST, E);
		if (*E) return;
	}

	*E = Inter::Permission::new(IBM, InterSymbolsTable::id_from_symbol_at_bookmark(IBM, prop_name), InterSymbolsTable::id_from_symbol_at_bookmark(IBM, owner_name),
		InterSymbolsTable::id_from_symbol_at_bookmark(IBM, pp_name), (store)?(InterSymbolsTable::id_from_symbol_at_bookmark(IBM, store)):0, (inter_ti) ilp->indent_level, eloc);
}

inter_error_message *Inter::Permission::new(inter_bookmark *IBM, inter_ti PID, inter_ti KID,
	inter_ti PPID, inter_ti SID, inter_ti level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_4_data_fields(IBM, PERMISSION_IST, PPID, PID, KID, SID, eloc, level);
	inter_error_message *E = InterConstruct::verify_construct(InterBookmark::package(IBM), P); if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void Inter::Permission::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	inter_ti vcount = Inode::bump_verification_count(P);

	if (P->W.extent != EXTENT_PERM_IFR) { *E = Inode::error(P, I"extent wrong", NULL); return; }

	*E = Inter::Verify::defn(owner, P, DEFN_PERM_IFLD); if (*E) return;
	*E = Inter::Verify::symbol(owner, P, P->W.instruction[PROP_PERM_IFLD], PROPERTY_IST); if (*E) return;
	*E = Inter::Verify::symbol_KOI(owner, P, P->W.instruction[OWNER_PERM_IFLD]); if (*E) return;
	if (P->W.instruction[STORAGE_PERM_IFLD]) {
		*E = Inter::Verify::symbol(owner, P, P->W.instruction[STORAGE_PERM_IFLD], CONSTANT_IST); if (*E) return;
	}
	inter_symbol *prop_name = InterSymbolsTable::symbol_from_ID(InterPackage::scope(owner), P->W.instruction[PROP_PERM_IFLD]);;
	inter_symbol *owner_name = InterSymbolsTable::symbol_from_ID(InterPackage::scope(owner), P->W.instruction[OWNER_PERM_IFLD]);;

	if (vcount == 0) {
		inter_node_list *FL = NULL;

		if (Inter::Kind::is(owner_name)) {
			if (Inter::Types::is_enumerated(Inter::Kind::data_type(owner_name)) == FALSE)
				{ *E = Inode::error(P, I"property permission for non-enumerated kind", NULL); return; }
			FL = Inode::ID_to_frame_list(P, Inter::Kind::permissions_list(owner_name));
			if (FL == NULL) internal_error("no permissions list");
			inter_tree_node *X;
			LOOP_THROUGH_INTER_NODE_LIST(X, FL) {
				inter_symbol *prop_X = InterSymbolsTable::symbol_from_ID_at_node(X, PROP_PERM_IFLD);
				inter_symbol *prop_P = InterSymbolsTable::symbol_from_ID(InterPackage::scope(owner), P->W.instruction[PROP_PERM_IFLD]);;
				if (prop_X == prop_P) { *E = Inode::error(P, I"duplicate permission", prop_name->symbol_name); return; }
				inter_symbol *owner_X = InterSymbolsTable::symbol_from_ID_at_node(X, OWNER_PERM_IFLD);
				inter_symbol *owner_P = InterSymbolsTable::symbol_from_ID(InterPackage::scope(owner), P->W.instruction[OWNER_PERM_IFLD]);;
				if (owner_X != owner_P) { *E = Inode::error(P, I"kind permission list malformed", owner_name->symbol_name); return; }
			}
		} else {
			FL = Inode::ID_to_frame_list(P, Inter::Instance::permissions_list(owner_name));
			if (FL == NULL) internal_error("no permissions list");
			inter_tree_node *X;
			LOOP_THROUGH_INTER_NODE_LIST(X, FL) {
				inter_symbol *prop_X = InterSymbolsTable::symbol_from_ID_at_node(X, PROP_PERM_IFLD);
				inter_symbol *prop_P = InterSymbolsTable::symbol_from_ID(InterPackage::scope(owner), P->W.instruction[PROP_PERM_IFLD]);;
				if (prop_X == prop_P) { *E = Inode::error(P, I"duplicate permission", prop_name->symbol_name); return; }
				inter_symbol *owner_X = InterSymbolsTable::symbol_from_ID_at_node(X, OWNER_PERM_IFLD);
				inter_symbol *owner_P = InterSymbolsTable::symbol_from_ID(InterPackage::scope(owner), P->W.instruction[OWNER_PERM_IFLD]);;
				if (owner_X != owner_P) { *E = Inode::error(P, I"instance permission list malformed", owner_name->symbol_name); return; }
			}
		}

		InterNodeList::add(FL, P);

		FL = Inode::ID_to_frame_list(P, Inter::Property::permissions_list(prop_name));
		InterNodeList::add(FL, P);
	}
}

void Inter::Permission::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	inter_symbol *prop_name = InterSymbolsTable::symbol_from_ID_at_node(P, PROP_PERM_IFLD);
	inter_symbol *owner_name = InterSymbolsTable::symbol_from_ID_at_node(P, OWNER_PERM_IFLD);
	if ((prop_name) && (owner_name)) {
		WRITE("permission %S %S", prop_name->symbol_name, owner_name->symbol_name);
		if (P->W.instruction[STORAGE_PERM_IFLD]) {
			inter_symbol *store = InterSymbolsTable::symbol_from_ID_at_node(P, STORAGE_PERM_IFLD);
			WRITE(" %S", store->symbol_name);
		}
	} else { *E = Inode::error(P, I"cannot write permission", NULL); return; }
}
