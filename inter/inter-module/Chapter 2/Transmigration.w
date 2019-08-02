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
	LOG("Move $5 to $5\n", migrant, destination);
	inter_package *origin = Inter::Packages::parent(migrant);
	inter_bookmark deletion_point, insertion_point, linkage_point, primitives_point;
	@<Create these bookmarks@>;
	@<Mark the insertion and deletion points with comments@>;
	@<Physically move the subtree to its new home@>;
	@<Correct any references from the migrant to the origin@>;
	if (tidy_origin) @<Correct any references from the origin to the migrant@>;
}

@<Create these bookmarks@> =
	deletion_point =
		Inter::Bookmarks::after_this_node(migrant->package_head->tree, migrant->package_head);
	insertion_point =
		Inter::Bookmarks::at_end_of_this_package(destination);
	linkage_point = Inter::Bookmarks::at_end_of_this_package(migrant);
	inter_tree_node *prims = NULL;
	LOOP_THROUGH_INTER_CHILDREN(F, destination->package_head->tree->root_node)
		if (F->W.data[ID_IFLD] == PRIMITIVE_IST)
			prims = F;
	if (prims == NULL) internal_error("dest has no prims");
	primitives_point = Inter::Bookmarks::after_this_node(destination->package_head->tree, prims);

@<Mark the insertion and deletion points with comments@> =
	inter_t C1 = Inter::Warehouse::create_text(Inter::Bookmarks::warehouse(&deletion_point), Inter::Bookmarks::package(&deletion_point));
	WRITE_TO(Inter::Warehouse::get_text(Inter::Bookmarks::warehouse(&deletion_point), C1), 
		"Exported %S here", Inter::Packages::name(migrant));
	Inter::Comment::new(&deletion_point, (inter_t) Inter::Packages::baseline(migrant), NULL, C1);

	inter_t C2 = Inter::Warehouse::create_text(Inter::Bookmarks::warehouse(&insertion_point), Inter::Bookmarks::package(&insertion_point));
	WRITE_TO(Inter::Warehouse::get_text(Inter::Bookmarks::warehouse(&insertion_point), C2), 
		"Imported %S here", Inter::Packages::name(migrant));
	Inter::Comment::new(&insertion_point, (inter_t) Inter::Packages::baseline(destination) + 1, NULL, C2);

@<Physically move the subtree to its new home@> =
	Inter::Packages::remove_subpackage_name(Inter::Packages::parent(migrant), migrant);
	Inter::Packages::add_subpackage_name(destination, migrant);
	Inter::Bookmarks::insert(&insertion_point, migrant->package_head);

@ =
typedef struct ipct_state {
	inter_package *migrant;
	inter_package *destination;
	inter_package *links;
	inter_bookmark *linkage_point;
	inter_bookmark *primitives_point;
	inter_symbols_table *origin_globals;
	inter_symbols_table *destination_globals;
} ipct_state;

@<Correct any references from the migrant to the origin@> =
	ipct_cache_count++;
	ipct_state ipct;
	ipct.migrant = migrant;
	ipct.destination = destination;
	ipct.links = NULL;
	ipct.origin_globals = Inter::Tree::global_scope(migrant->package_head->tree);
	ipct.destination_globals = Inter::Tree::global_scope(destination->package_head->tree);
	ipct.linkage_point = &linkage_point;
	ipct.primitives_point = &primitives_point;
	Inter::Tree::traverse(destination->package_head->tree,
		Inter::Transmigration::correct_migrant, &ipct, migrant, 0);

@ =
void Inter::Transmigration::correct_migrant(inter_tree *I, inter_tree_node *P, void *state) {
	ipct_state *ipct = (ipct_state *) state;
	P->tree = I;
	if ((P->W.data[ID_IFLD] == INV_IST) && (P->W.data[METHOD_INV_IFLD] == INVOKED_PRIMITIVE)) {
		inter_symbol *primitive =
			Inter::SymbolsTables::symbol_from_id(ipct->origin_globals, P->W.data[INVOKEE_INV_IFLD]);
		if (primitive) @<Correct the reference to this primitive@>;
	}
	if (P->W.data[ID_IFLD] == PACKAGE_IST) {
		inter_package *pack = Inter::Package::defined_by_frame(P);
		if (pack == NULL) internal_error("no package defined here");
		if (Inter::Packages::is_linklike(pack)) return;
		inter_symbols_table *T = Inter::Packages::scope(pack);
		if (T == NULL) internal_error("package with no symbols");
		for (int i=0; i<T->size; i++) {
			inter_symbol *symb = T->symbol_array[i];
			if ((symb) && (symb->equated_to)) {
				inter_symbol *target = symb->equated_to;
				while (target->equated_to) target = target->equated_to;
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

@<Correct the reference to this primitive@> =
	inter_symbol *equivalent_primitive = Inter::Transmigration::cached_equivalent(primitive);
	if (equivalent_primitive == NULL) {
		equivalent_primitive = Inter::SymbolsTables::symbol_from_name(ipct->destination_globals, primitive->symbol_name);
		if (equivalent_primitive == NULL) @<Duplicate this primitive@>;
		if (equivalent_primitive) Inter::Transmigration::cache(primitive, equivalent_primitive);
	}
	if (equivalent_primitive)
		P->W.data[INVOKEE_INV_IFLD] = Inter::SymbolsTables::id_from_symbol_inner(ipct->destination_globals, NULL, equivalent_primitive);

@<Duplicate this primitive@> =
	equivalent_primitive = Inter::SymbolsTables::symbol_from_name_creating(ipct->destination_globals, primitive->symbol_name);
	inter_tree_node *D = Inter::Node::fill_1(ipct->primitives_point, PRIMITIVE_IST, Inter::SymbolsTables::id_from_symbol_inner(ipct->destination_globals, NULL, equivalent_primitive), NULL, 0);
	inter_tree_node *old_D = primitive->definition;
	for (int i=CAT_PRIM_IFLD; i<old_D->W.extent; i++) {
		if (Inter::Node::extend(D, (inter_t) 1) == FALSE) internal_error("can't extend");
		D->W.data[i] = old_D->W.data[i];
	}
	inter_error_message *E = Inter::Defn::verify_construct(Inter::Bookmarks::package(ipct->primitives_point), D);
	if (E) {
		Inter::Errors::issue(E);
		equivalent_primitive = NULL;
	} else {
		Inter::Bookmarks::insert(ipct->primitives_point, D);
	}

@<Correct the reference to this symbol@> =
	inter_symbol *equivalent = Inter::Transmigration::cached_equivalent(target);
	if (equivalent == NULL) {
		TEMPORARY_TEXT(URL);
		Inter::SymbolsTables::symbol_to_url_name(URL, target);
		equivalent = Inter::SymbolsTables::url_name_to_symbol(ipct->destination->package_head->tree, NULL, URL);
		if (equivalent == NULL)
			@<Create a link symbol to represent the unavailability of this symbol@>;
		DISCARD_TEXT(URL);
		Inter::Transmigration::cache(target, equivalent);
	}
	symb->equated_to = equivalent;

@<Create a link symbol to represent the unavailability of this symbol@> =
	if (ipct->links == NULL)
		ipct->links = Inter::Packages::by_name(ipct->migrant, I"links");
	if (ipct->links == NULL) {
		inter_symbol *linkage = Inter::SymbolsTables::url_name_to_symbol(I, NULL, I"/_linkage");
		if (linkage == NULL) internal_error("no linkage ptype");
		Inter::Package::new_package(ipct->linkage_point, I"links", linkage, (inter_t) Inter::Packages::baseline(ipct->migrant) + 1, NULL, &(ipct->links));
	}
	if (ipct->links == NULL) internal_error("couldn't create links");
	Inter::Packages::make_linklike(ipct->links);
	equivalent = Inter::SymbolsTables::create_with_unique_name(Inter::Packages::scope(ipct->links), target->symbol_name);
	Inter::SymbolsTables::link(equivalent, URL);

@<Correct any references from the origin to the migrant@> =
	ipct_cache_count++;
	ipct_state ipct;
	ipct.migrant = migrant;
	ipct.destination = destination;
	ipct.links = NULL;
	ipct.origin_globals = NULL;
	ipct.destination_globals = NULL;
	ipct.linkage_point = &deletion_point;
	ipct.primitives_point = NULL;
	Inter::Tree::traverse(origin->package_head->tree,
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
			if ((symb) && (symb->equated_to)) {
				inter_symbol *target = symb->equated_to;
				while (target->equated_to) target = target->equated_to;
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
		@<Create a link symbol in the origin@>;
		Inter::Transmigration::cache(target, equivalent);
	}
	symb->equated_to = equivalent;

@<Create a link symbol in the origin@> =
	if (ipct->links == NULL)
		ipct->links = Inter::Packages::by_name(Inter::Bookmarks::package(ipct->linkage_point), I"links");
	if (ipct->links == NULL) {
		inter_symbol *linkage = Inter::SymbolsTables::url_name_to_symbol(I, NULL, I"/_linkage");
		if (linkage == NULL) internal_error("no linkage ptype");
		Inter::Package::new_package(ipct->linkage_point, I"links", linkage, (inter_t) Inter::Bookmarks::baseline(ipct->linkage_point)+1, NULL, &(ipct->links));
	}
	if (ipct->links == NULL) internal_error("couldn't create links");
	Inter::Packages::make_linklike(ipct->links);
	equivalent = Inter::SymbolsTables::create_with_unique_name(Inter::Packages::scope(ipct->links), target->symbol_name);
	TEMPORARY_TEXT(URL);
	Inter::SymbolsTables::symbol_to_url_name(URL, target);
	Inter::SymbolsTables::link(equivalent, URL);
	DISCARD_TEXT(URL);
