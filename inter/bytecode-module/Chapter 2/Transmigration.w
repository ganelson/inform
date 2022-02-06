[Transmigration::] Transmigration.

The act of moving a package from one Inter tree to another.

@ The design of Inter has all been leading up to this: how to move a body of
material in one tree, the |migrant| package, into a different tree entirely,
where it will become part of the |destination| package. Transmigration is
how Inter merges material compiled at different times together. For example,
when a Basic Inform project is compiled:

(*) //inform7// compiles source text into tree 1 of Inter code.
(*) //inter// loads a precompiled copy of BasicInformKit as tree 2.
(*) The package |/main/BasicInformKit| in tree 2, really its entire substantive
content, is transmigrated to |/main| in tree 1; it has become |/main/BasicInformKit|
in tree 1. Tree 2 is left almost empty, and is discarded.
(*) //inter// loads a precompiled copy of BasicInformKitExtras as tree 3.
(*) A similar transmigration moves its content to become |/main/BasicInformKitExtras|
in tree 1, and the remains of tree 3 are discarded.

@ Transmigration is a move, not a copy. The destination tree simply makes a node
link to the subtree making up |migrant|: so, in principle, this is a fast process,
but the devil is in the detail. The |migrant| matter may be full of references
to other resources in the origin tree, and those have to be made good. Read
//The Wiring// before tackling the algorithms below.

Because the operation is a move and not a copy, the origin tree will probably
be left with a gaping hole in it: its symbols may be wired to resources which
are no longer there. It may be that the origin tree is going to be discarded
anyway, so that this doesn't matter. If not, setting |tidy_origin| here will
spend some time and effort making it valid again.

Note that the |/main| and |/main/connectors| packages of a tree cannot be
transmigrated, and nor can the root package |/|. Anything else is fair game
to be a |migrant| here.

=
void Transmigration::move(inter_package *migrant, inter_package *destination,
	int tidy_origin) {
	inter_package *P = migrant; while (P) P = InterPackage::parent(P); /* make names exist */

	inter_tree *origin_tree = InterPackage::tree(migrant);
	inter_tree *destination_tree = InterPackage::tree(destination);

	inter_package *origin = InterPackage::parent(migrant);

	inter_bookmark deletion_point, insertion_point, primitives_point, ptypes_point;
	@<Create these bookmarks@>;

	@<Mark the insertion and deletion points with comments@>;
	@<Move the head node of the migrant to its new home@>;
	@<Correct any references from the migrant to the origin@>;
	if (tidy_origin) @<Correct any references from the origin to the migrant@>;
	@<Reconcile sockets in the origin@>;
}

@ Both trees will have, at the root level, declarations of the Inter primitives
and package types which they use. (See //building: Large-Scale Structure//.)
Now, they will probably both declare exactly the same set of each: but just in
case the |migrant| package uses primitives or package types not declared at
the root of the |destination_tree|, we will need to declare those as extras,
and we make the bookmarks |primitives_point| and |ptypes_point| to mark where
such extra declarations would go.

|deletion_point| and |insertion_point|, more straightforwardly, mark the
position of the |migrant|'s head node in the origin tree before transmigration
and in the destination tree afterwards.

@<Create these bookmarks@> =
	deletion_point = InterBookmark::after_this_node(migrant->package_head);
	insertion_point = InterBookmark::at_end_of_this_package(destination);
	inter_tree_node *prims = NULL;
	LOOP_THROUGH_INTER_CHILDREN(F, destination->package_head->tree->root_node)
		if (F->W.instruction[ID_IFLD] == PRIMITIVE_IST)
			prims = F;
	if (prims == NULL) internal_error("destination has no primitives");
	primitives_point = InterBookmark::after_this_node(prims);
	inter_tree_node *ptypes = NULL;
	LOOP_THROUGH_INTER_CHILDREN(F, destination->package_head->tree->root_node)
		if (F->W.instruction[ID_IFLD] == PACKAGETYPE_IST)
			ptypes = F;
	if (ptypes == NULL) internal_error("dest has no prims");
	ptypes_point = InterBookmark::after_this_node(ptypes);

@<Mark the insertion and deletion points with comments@> =
	Transmigration::comment(&deletion_point, InterPackage::baseline(migrant),
		I"Transmigration removed", InterPackage::name(migrant));
	Transmigration::comment(&insertion_point, InterPackage::baseline(destination) + 1,
		I"Transmigration inserted", InterPackage::name(migrant));

@ =
void Transmigration::comment(inter_bookmark *IBM, int level, text_stream *action,
	text_stream *content) {
	inter_ti C = InterWarehouse::create_text(InterBookmark::warehouse(IBM),
		InterBookmark::package(IBM));
	WRITE_TO(InterWarehouse::get_text(InterBookmark::warehouse(IBM), C), 
		"%S %S here", action, content);
	Inter::Comment::new(IBM, (inter_ti) level, NULL, C);
}

@<Move the head node of the migrant to its new home@> =
	InterPackage::remove_subpackage_name(InterPackage::parent(migrant), migrant);
	InterPackage::add_subpackage_name(destination, migrant);
	NodePlacement::move_to_moving_bookmark(migrant->package_head, &insertion_point);

@ That was the easy part. The migrant package is now inside the destination tree.
Unfortunately:

(*) |migrant| may contain symbols |S ~~> O| wired to symbols |O| still in the origin
tree, because they lay outside |migrant|. This means the destination tree is now
incorrect.

(*) The origin tree may contain symbols |O ~~> S| wired to symbols |S| in the
migrant, which are therefore not in the origin tree any more. This means the origin
tree is now incorrect.

@<Correct any references from the migrant to the origin@> =
	correct_migrant_state cms;
	@<Initialise the IPCT state@>;
	InterTree::traverse(destination->package_head->tree,
		Transmigration::correct_migrant, &cms, migrant, 0);

@ The following state is used during our traverse of the |migrant| subtree;
really, this just allows //Transmigration::correct_migrant// to access our
relevant variables.

=
typedef struct correct_migrant_state {
	inter_package *migrant;
	inter_package *destination;
	inter_bookmark *primitives_point;
	inter_bookmark *ptypes_point;
	inter_tree *origin_tree;
	inter_tree *destination_tree;
} correct_migrant_state;

@<Initialise the IPCT state@> =
	Transmigration::begin_cache_session();
	cms.migrant = migrant;
	cms.destination = destination;
	cms.origin_tree = origin_tree;
	cms.destination_tree = destination_tree;
	cms.primitives_point = &primitives_point;
	cms.ptypes_point = &ptypes_point;

@ =
void Transmigration::correct_migrant(inter_tree *I, inter_tree_node *P, void *state) {
	correct_migrant_state *cms = (correct_migrant_state *) state;
	P->tree = I;
	if ((P->W.instruction[ID_IFLD] == INV_IST) && (P->W.instruction[METHOD_INV_IFLD] == INVOKED_PRIMITIVE)) {
		inter_symbol *primitive =
			InterSymbolsTable::symbol_from_ID(InterTree::global_scope(cms->origin_tree), P->W.instruction[INVOKEE_INV_IFLD]);
		if (primitive) @<Correct the reference to this primitive@>;
	}
	if (P->W.instruction[ID_IFLD] == PACKAGE_IST) {
		inter_package *pack = InterPackage::at_this_head(P);
		if (pack == NULL) internal_error("no package defined here");
		if (InterPackage::is_a_linkage_package(pack)) return;
		@<Correct the reference to this package type@>;
		inter_symbols_table *T = InterPackage::scope(pack);
		if (T == NULL) internal_error("package with no symbols");
		LOOP_OVER_SYMBOLS_TABLE(symb, T) {
			if (Wiring::is_wired(symb)) {
				inter_symbol *target = Wiring::cable_end(symb);
				if (SymbolAnnotation::get_b(target, ARCHITECTURAL_IANN)) {
					Wiring::wire_to(symb,
						LargeScale::find_architectural_symbol(cms->destination->package_head->tree, target->symbol_name, Produce::kind_to_symbol(NULL)));
				} else if (InterSymbol::is_plug(target)) {
					inter_symbol *equivalent = Transmigration::cached_equivalent(target);
					if (equivalent == NULL) {
						text_stream *N = Wiring::wired_to_name(target);
						equivalent = Wiring::plug(cms->destination->package_head->tree, N);
						Transmigration::cache(target, equivalent);
					}
					Wiring::wire_to(symb, equivalent);					
				} else {
					inter_package *target_package = InterSymbol::package(target);
					while ((target_package) && (target_package != cms->migrant)) {
						target_package = InterPackage::parent(target_package);
					}
					if (target_package != cms->migrant)
						@<Correct the reference to this symbol@>;
				}
			}
		}
	}
}

@<Correct the reference to this primitive@> =
	inter_symbol *equivalent_primitive = Transmigration::cached_equivalent(primitive);
	if (equivalent_primitive == NULL) {
		equivalent_primitive = InterSymbolsTable::symbol_from_name(InterTree::global_scope(cms->destination_tree), primitive->symbol_name);
		if (equivalent_primitive == NULL) @<Duplicate this primitive@>;
		if (equivalent_primitive) Transmigration::cache(primitive, equivalent_primitive);
	}
	if (equivalent_primitive)
		P->W.instruction[INVOKEE_INV_IFLD] = InterSymbolsTable::id_from_symbol(cms->destination_tree, NULL, equivalent_primitive);

@<Duplicate this primitive@> =
	equivalent_primitive = InterSymbolsTable::symbol_from_name_creating(InterTree::global_scope(cms->destination_tree), primitive->symbol_name);
	inter_tree_node *D = Inode::new_with_1_data_field(cms->primitives_point, PRIMITIVE_IST, InterSymbolsTable::id_from_symbol(cms->destination_tree, NULL, equivalent_primitive), NULL, 0);
	inter_tree_node *old_D = primitive->definition;
	for (int i=CAT_PRIM_IFLD; i<old_D->W.extent; i++) {
		Inode::extend_instruction_by(D, 1);
		D->W.instruction[i] = old_D->W.instruction[i];
	}
	inter_error_message *E = Inter::Defn::verify_construct(InterBookmark::package(cms->primitives_point), D);
	if (E) {
		Inter::Errors::issue(E);
		equivalent_primitive = NULL;
	} else {
		NodePlacement::move_to_moving_bookmark(D, cms->primitives_point);
	}

@<Correct the reference to this package type@> =
	inter_symbol *original_ptype =
		InterSymbolsTable::symbol_from_ID(
			InterTree::global_scope(cms->origin_tree), P->W.instruction[PTYPE_PACKAGE_IFLD]);
	inter_symbol *equivalent_ptype = Transmigration::cached_equivalent(original_ptype);
	if (equivalent_ptype == NULL) {
		equivalent_ptype = InterSymbolsTable::symbol_from_name(InterTree::global_scope(cms->destination_tree), original_ptype->symbol_name);
		if (equivalent_ptype == NULL) @<Duplicate this package type@>;
		if (equivalent_ptype) Transmigration::cache(original_ptype, equivalent_ptype);
	}
	if (equivalent_ptype)
		P->W.instruction[PTYPE_PACKAGE_IFLD] = InterSymbolsTable::id_from_symbol(cms->destination_tree, NULL, equivalent_ptype);

@<Duplicate this package type@> =
	equivalent_ptype = InterSymbolsTable::symbol_from_name_creating(InterTree::global_scope(cms->destination_tree), original_ptype->symbol_name);
	inter_tree_node *D = Inode::new_with_1_data_field(cms->ptypes_point, PACKAGETYPE_IST, InterSymbolsTable::id_from_symbol(cms->destination_tree, NULL, equivalent_ptype), NULL, 0);
	inter_error_message *E = Inter::Defn::verify_construct(InterBookmark::package(cms->ptypes_point), D);
	if (E) {
		Inter::Errors::issue(E);
		equivalent_ptype = NULL;
	} else {
		NodePlacement::move_to_moving_bookmark(D, cms->ptypes_point);
	}

@<Correct the reference to this symbol@> =
	inter_symbol *equivalent = Transmigration::cached_equivalent(target);
	if (equivalent == NULL) {
		TEMPORARY_TEXT(URL)
		InterSymbolsTable::write_symbol_URL(URL, target);
		equivalent = InterSymbolsTable::URL_to_symbol(cms->destination->package_head->tree, URL);
		if ((equivalent == NULL) && (Inter::Kind::is(target)))
			equivalent = LargeScale::find_symbol_in_tree(cms->destination->package_head->tree, target->symbol_name);
		if (equivalent == NULL)
			equivalent = Wiring::plug(cms->destination_tree, target->symbol_name);
		DISCARD_TEXT(URL)
		Transmigration::cache(target, equivalent);
	}
	Wiring::wire_to(symb, equivalent);

@<Correct any references from the origin to the migrant@> =
	correct_migrant_state cms;
	@<Initialise the IPCT state@>;
	InterTree::traverse(origin->package_head->tree,
		Transmigration::correct_origin, &cms, NULL, 0);

@ =
void Transmigration::correct_origin(inter_tree *I, inter_tree_node *P, void *state) {
	correct_migrant_state *cms = (correct_migrant_state *) state;
	if (P->W.instruction[ID_IFLD] == PACKAGE_IST) {
		inter_package *pack = InterPackage::at_this_head(P);
		if (pack == NULL) internal_error("no package defined here");
		if (InterPackage::is_a_linkage_package(pack)) return;
		inter_symbols_table *T = InterPackage::scope(pack);
		if (T == NULL) internal_error("package with no symbols");
		LOOP_OVER_SYMBOLS_TABLE(symb, T) {
			if (Wiring::is_wired(symb)) {
				inter_symbol *target = Wiring::cable_end(symb);
				inter_package *target_package = InterSymbol::package(target);
				while ((target_package) && (target_package != cms->migrant)) {
					target_package = InterPackage::parent(target_package);
				}
				if (target_package == cms->migrant)
					@<Correct the origin reference to this migrant symbol@>;
			}
		}
	}
}

@<Correct the origin reference to this migrant symbol@> =
	inter_symbol *equivalent = Transmigration::cached_equivalent(target);
	if (equivalent == NULL) {
		TEMPORARY_TEXT(URL)
		InterSymbolsTable::write_symbol_URL(URL, target);
		equivalent = Wiring::plug(cms->origin_tree, URL);
		DISCARD_TEXT(URL)
		Transmigration::cache(target, equivalent);
	}
	Wiring::wire_to(symb, equivalent);

@<Reconcile sockets in the origin@> =
	inter_package *origin_connectors =
		LargeScale::connectors_package_if_it_exists(origin_tree);
	if (origin_connectors) {
		inter_symbols_table *T = InterPackage::scope(origin_connectors);
		if (T == NULL) internal_error("package with no symbols");
		LOOP_OVER_SYMBOLS_TABLE(symb, T) {
			if (InterSymbol::is_socket(symb)) {
				inter_symbol *target = Wiring::cable_end(symb);
				inter_package *target_package = InterSymbol::package(target);
				while ((target_package) && (target_package != migrant)) {
					target_package = InterPackage::parent(target_package);
				}
				if (target_package == migrant) {
					LOGIF(INTER_CONNECTORS, "Origin offers socket inside migrant: $3 == $3\n", symb, target);
					inter_symbol *equivalent = Wiring::find_socket(destination_tree, symb->symbol_name);
					if (equivalent) {
						inter_symbol *e_target = Wiring::cable_end(equivalent);
						if (!InterSymbol::is_defined(e_target)) {
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

@ 

=
typedef struct transmigration_data {
	int link_time;
	struct inter_symbol *linked_to;
} transmigration_data;

transmigration_data Transmigration::new_transmigration_data(inter_symbol *S) {
	transmigration_data td;
	td.link_time = 0;
	td.linked_to = NULL;
	return td;
}

int ipct_cache_count = 0;

void Transmigration::begin_cache_session(void) {
	ipct_cache_count++;
}

void Transmigration::cache(inter_symbol *S, inter_symbol *V) {
	S->transmigration.linked_to = V;
	S->transmigration.link_time = ipct_cache_count;
}

inter_symbol *Transmigration::cached_equivalent(inter_symbol *S) {
	if (S->transmigration.link_time == ipct_cache_count) return S->transmigration.linked_to;
	return NULL;
}
