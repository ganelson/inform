[Inter::Transmigration::] Transmigration.

To move packages between repositories.

@ =
int ipct_cache_count = 0;
void Inter::Transmigration::cache(inter_symbol *S, inter_symbol *V) {
	S->linked_to = V;
	S->link_time = ipct_cache_count;
}

inter_symbol *Inter::Transmigration::cached_equivalent(inter_symbol *S) {
	if (S->link_time == ipct_cache_count) return S->linked_to;
	return NULL;
}

void Inter::Transmigration::move(inter_package *migrant, inter_package *destination, int tidy_origin) {
	Inter::Packages::make_names_exist(migrant);
	inter_tree *origin_tree = Inter::Packages::tree(migrant);
	inter_tree *destination_tree = Inter::Packages::tree(destination);
	inter_package *origin = Inter::Packages::parent(migrant);
	inter_bookmark deletion_point, insertion_point, primitives_point, ptypes_point;
	@<Create these bookmarks@>;
	@<Mark the insertion and deletion points with comments@>;
	@<Physically move the subtree to its new home@>;
	@<Correct any references from the migrant to the origin@>;
	if (tidy_origin) @<Correct any references from the origin to the migrant@>;
	inter_package *connectors = LargeScale::connectors_package_if_it_exists(origin_tree);
	if (connectors) {
		inter_symbols_table *T = Inter::Packages::scope(connectors);
		if (T == NULL) internal_error("package with no symbols");
		for (int i=0; i<T->size; i++) {
			inter_symbol *symb = T->symbol_array[i];
			if ((symb) && (Inter::Symbols::get_scope(symb) == SOCKET_ISYMS)) {
				inter_symbol *target = Wiring::cable_end(symb);
				inter_package *target_package = target->owning_table->owning_package;
				while ((target_package) && (target_package != migrant)) {
					target_package = Inter::Packages::parent(target_package);
				}
				if (target_package == migrant) {
					LOGIF(INTER_CONNECTORS, "Origin offers socket inside migrant: $3 == $3\n", symb, target);
					inter_symbol *equivalent = Wiring::find_socket(destination_tree, symb->symbol_name);
					if (equivalent) {
						inter_symbol *e_target = Wiring::cable_end(equivalent);
						if (!Inter::Symbols::is_defined(e_target)) {
							LOGIF(INTER_CONNECTORS, "Able to match with $3 ~~> $3\n", equivalent, Wiring::cable_end(equivalent));
							Wiring::wire_to(equivalent, target);
							Wiring::wire_to(e_target, target);
						} else {
							LOGIF(INTER_CONNECTORS, "Clash of sockets\n");
						}
					} else {
						Wiring::socket(destination_tree, symb->symbol_name, symb);
					}
				}
			}
		}
	}
}

@<Log sockets in origin tree@> =
	LOG("\n\n\nList of sockets in origin tree:\n");
	inter_package *connectors = LargeScale::connectors_package_if_it_exists(origin_tree);
	if (connectors) {
		inter_symbols_table *T = Inter::Packages::scope(connectors);
		if (T == NULL) internal_error("package with no symbols");
		for (int i=0; i<T->size; i++) {
			inter_symbol *symb = T->symbol_array[i];
			if ((symb) && (Inter::Symbols::get_scope(symb) == SOCKET_ISYMS)) {
				LOG("$3\n", symb);
			}
		}
	}
	LOG("---\n\n");

@<Create these bookmarks@> =
	deletion_point = InterBookmark::after_this_node(migrant->package_head);
	insertion_point = InterBookmark::at_end_of_this_package(destination);
	inter_tree_node *prims = NULL;
	LOOP_THROUGH_INTER_CHILDREN(F, destination->package_head->tree->root_node)
		if (F->W.data[ID_IFLD] == PRIMITIVE_IST)
			prims = F;
	if (prims == NULL) internal_error("dest has no prims");
	primitives_point = InterBookmark::after_this_node(prims);
	inter_tree_node *ptypes = NULL;
	LOOP_THROUGH_INTER_CHILDREN(F, destination->package_head->tree->root_node)
		if (F->W.data[ID_IFLD] == PACKAGETYPE_IST)
			ptypes = F;
	if (ptypes == NULL) internal_error("dest has no prims");
	ptypes_point = InterBookmark::after_this_node(ptypes);

@<Mark the insertion and deletion points with comments@> =
	inter_ti C1 = Inter::Warehouse::create_text(InterBookmark::warehouse(&deletion_point), InterBookmark::package(&deletion_point));
	WRITE_TO(Inter::Warehouse::get_text(InterBookmark::warehouse(&deletion_point), C1), 
		"Exported %S here", Inter::Packages::name(migrant));
	Inter::Comment::new(&deletion_point, (inter_ti) Inter::Packages::baseline(migrant), NULL, C1);

	inter_ti C2 = Inter::Warehouse::create_text(InterBookmark::warehouse(&insertion_point), InterBookmark::package(&insertion_point));
	WRITE_TO(Inter::Warehouse::get_text(InterBookmark::warehouse(&insertion_point), C2), 
		"Imported %S here", Inter::Packages::name(migrant));
	Inter::Comment::new(&insertion_point, (inter_ti) Inter::Packages::baseline(destination) + 1, NULL, C2);

@<Physically move the subtree to its new home@> =
	Inter::Packages::remove_subpackage_name(Inter::Packages::parent(migrant), migrant);
	Inter::Packages::add_subpackage_name(destination, migrant);
	NodePlacement::move_to_moving_bookmark(migrant->package_head, &insertion_point);

@ =
typedef struct ipct_state {
	inter_package *migrant;
	inter_package *destination;
	inter_bookmark *primitives_point;
	inter_bookmark *ptypes_point;
	inter_tree *origin_tree;
	inter_tree *destination_tree;
} ipct_state;

@<Initialise the IPCT state@> =
	ipct_cache_count++;
	ipct.migrant = migrant;
	ipct.destination = destination;
	ipct.origin_tree = origin_tree;
	ipct.destination_tree = destination_tree;
	ipct.primitives_point = &primitives_point;
	ipct.ptypes_point = &ptypes_point;

@<Correct any references from the migrant to the origin@> =
	ipct_state ipct;
	@<Initialise the IPCT state@>;
	InterTree::traverse(destination->package_head->tree,
		Inter::Transmigration::correct_migrant, &ipct, migrant, 0);

@ =
void Inter::Transmigration::correct_migrant(inter_tree *I, inter_tree_node *P, void *state) {
	ipct_state *ipct = (ipct_state *) state;
	P->tree = I;
	if ((P->W.data[ID_IFLD] == INV_IST) && (P->W.data[METHOD_INV_IFLD] == INVOKED_PRIMITIVE)) {
		inter_symbol *primitive =
			InterSymbolsTables::symbol_from_id(InterTree::global_scope(ipct->origin_tree), P->W.data[INVOKEE_INV_IFLD]);
		if (primitive) @<Correct the reference to this primitive@>;
	}
	if (P->W.data[ID_IFLD] == PACKAGE_IST) {
		inter_package *pack = Inter::Package::defined_by_frame(P);
		if (pack == NULL) internal_error("no package defined here");
		if (Inter::Packages::is_linklike(pack)) return;
		@<Correct the reference to this package type@>;
		inter_symbols_table *T = Inter::Packages::scope(pack);
		if (T == NULL) internal_error("package with no symbols");
		for (int i=0; i<T->size; i++) {
			inter_symbol *symb = T->symbol_array[i];
			if (Wiring::is_wired(symb)) {
				inter_symbol *target = Wiring::cable_end(symb);
				if (Inter::Symbols::read_annotation(target, ARCHITECTURAL_IANN) > 0) {
					Wiring::wire_to(symb,
						LargeScale::find_architectural_symbol(ipct->destination->package_head->tree, target->symbol_name, Produce::kind_to_symbol(NULL)));
				} else if (Inter::Symbols::get_scope(target) == PLUG_ISYMS) {
					inter_symbol *equivalent = Inter::Transmigration::cached_equivalent(target);
					if (equivalent == NULL) {
						text_stream *N = Wiring::wired_to_name(target);
						equivalent = Wiring::find_plug(ipct->destination->package_head->tree, N);
						if (equivalent == NULL)
							equivalent = Wiring::plug(ipct->destination->package_head->tree, N);
						Inter::Transmigration::cache(target, equivalent);
					}
					Wiring::wire_to(symb, equivalent);					
				} else {
					inter_package *target_package = target->owning_table->owning_package;
					while ((target_package) && (target_package != ipct->migrant)) {
						target_package = Inter::Packages::parent(target_package);
					}
					if (target_package != ipct->migrant)
						@<Correct the reference to this symbol@>;
				}
			}
		}
	}
}

@<Correct the reference to this primitive@> =
	inter_symbol *equivalent_primitive = Inter::Transmigration::cached_equivalent(primitive);
	if (equivalent_primitive == NULL) {
		equivalent_primitive = InterSymbolsTables::symbol_from_name(InterTree::global_scope(ipct->destination_tree), primitive->symbol_name);
		if (equivalent_primitive == NULL) @<Duplicate this primitive@>;
		if (equivalent_primitive) Inter::Transmigration::cache(primitive, equivalent_primitive);
	}
	if (equivalent_primitive)
		P->W.data[INVOKEE_INV_IFLD] = InterSymbolsTables::id_from_symbol_inner(InterTree::global_scope(ipct->destination_tree), NULL, equivalent_primitive);

@<Duplicate this primitive@> =
	equivalent_primitive = InterSymbolsTables::symbol_from_name_creating(InterTree::global_scope(ipct->destination_tree), primitive->symbol_name);
	inter_tree_node *D = Inode::new_with_1_data_field(ipct->primitives_point, PRIMITIVE_IST, InterSymbolsTables::id_from_symbol_inner(InterTree::global_scope(ipct->destination_tree), NULL, equivalent_primitive), NULL, 0);
	inter_tree_node *old_D = primitive->definition;
	for (int i=CAT_PRIM_IFLD; i<old_D->W.extent; i++) {
		if (Inode::extend(D, (inter_ti) 1) == FALSE) internal_error("can't extend");
		D->W.data[i] = old_D->W.data[i];
	}
	inter_error_message *E = Inter::Defn::verify_construct(InterBookmark::package(ipct->primitives_point), D);
	if (E) {
		Inter::Errors::issue(E);
		equivalent_primitive = NULL;
	} else {
		NodePlacement::move_to_moving_bookmark(D, ipct->primitives_point);
	}

@<Correct the reference to this package type@> =
	inter_symbol *original_ptype =
		InterSymbolsTables::symbol_from_id(
			InterTree::global_scope(ipct->origin_tree), P->W.data[PTYPE_PACKAGE_IFLD]);
	inter_symbol *equivalent_ptype = Inter::Transmigration::cached_equivalent(original_ptype);
	if (equivalent_ptype == NULL) {
		equivalent_ptype = InterSymbolsTables::symbol_from_name(InterTree::global_scope(ipct->destination_tree), original_ptype->symbol_name);
		if (equivalent_ptype == NULL) @<Duplicate this package type@>;
		if (equivalent_ptype) Inter::Transmigration::cache(original_ptype, equivalent_ptype);
	}
	if (equivalent_ptype)
		P->W.data[PTYPE_PACKAGE_IFLD] = InterSymbolsTables::id_from_symbol_inner(InterTree::global_scope(ipct->destination_tree), NULL, equivalent_ptype);

@<Duplicate this package type@> =
	equivalent_ptype = InterSymbolsTables::symbol_from_name_creating(InterTree::global_scope(ipct->destination_tree), original_ptype->symbol_name);
	inter_tree_node *D = Inode::new_with_1_data_field(ipct->ptypes_point, PACKAGETYPE_IST, InterSymbolsTables::id_from_symbol_inner(InterTree::global_scope(ipct->destination_tree), NULL, equivalent_ptype), NULL, 0);
	inter_error_message *E = Inter::Defn::verify_construct(InterBookmark::package(ipct->ptypes_point), D);
	if (E) {
		Inter::Errors::issue(E);
		equivalent_ptype = NULL;
	} else {
		NodePlacement::move_to_moving_bookmark(D, ipct->ptypes_point);
	}

@<Correct the reference to this symbol@> =
	inter_symbol *equivalent = Inter::Transmigration::cached_equivalent(target);
	if (equivalent == NULL) {
		TEMPORARY_TEXT(URL)
		InterSymbolsTables::symbol_to_url_name(URL, target);
		equivalent = InterSymbolsTables::url_name_to_symbol(ipct->destination->package_head->tree, NULL, URL);
		if ((equivalent == NULL) && (Inter::Kind::is(target)))
			equivalent = Inter::Packages::search_resources(ipct->destination->package_head->tree, target->symbol_name);
		if (equivalent == NULL)
			equivalent = Wiring::plug(ipct->destination_tree, target->symbol_name);
		DISCARD_TEXT(URL)
		Inter::Transmigration::cache(target, equivalent);
	}
	Wiring::wire_to(symb, equivalent);

@<Correct any references from the origin to the migrant@> =
	ipct_state ipct;
	@<Initialise the IPCT state@>;
	InterTree::traverse(origin->package_head->tree,
		Inter::Transmigration::correct_origin, &ipct, NULL, 0);

@ =
void Inter::Transmigration::correct_origin(inter_tree *I, inter_tree_node *P, void *state) {
	ipct_state *ipct = (ipct_state *) state;
	if (P->W.data[ID_IFLD] == PACKAGE_IST) {
		inter_package *pack = Inter::Package::defined_by_frame(P);
		if (pack == NULL) internal_error("no package defined here");
		if (Inter::Packages::is_linklike(pack)) return;
		inter_symbols_table *T = Inter::Packages::scope(pack);
		if (T == NULL) internal_error("package with no symbols");
		for (int i=0; i<T->size; i++) {
			inter_symbol *symb = T->symbol_array[i];
			if (Wiring::is_wired(symb)) {
				inter_symbol *target = Wiring::cable_end(symb);
				inter_package *target_package = target->owning_table->owning_package;
				while ((target_package) && (target_package != ipct->migrant)) {
					target_package = Inter::Packages::parent(target_package);
				}
				if (target_package == ipct->migrant)
					@<Correct the origin reference to this migrant symbol@>;
			}
		}
	}
}

@<Correct the origin reference to this migrant symbol@> =
	inter_symbol *equivalent = Inter::Transmigration::cached_equivalent(target);
	if (equivalent == NULL) {
		TEMPORARY_TEXT(URL)
		InterSymbolsTables::symbol_to_url_name(URL, target);
		equivalent = Wiring::plug(ipct->origin_tree, URL);
		DISCARD_TEXT(URL)
		Inter::Transmigration::cache(target, equivalent);
	}
	Wiring::wire_to(symb, equivalent);
