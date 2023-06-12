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
typedef struct transmigration_details {
	inter_package *migrant;           /* package which is to move between trees */
	inter_tree *origin_tree;          /* tree it moves from */
	inter_tree *destination_tree;     /* tree it moves to */
	inter_package *origin;            /* original parent package of the migrant */
	inter_package *destination;       /* eventual parent package of the migrant */
	inter_bookmark deletion_point;    /* where the migrant's head node starts */
	inter_bookmark insertion_point;   /* where the migrant's head node ends */
	inter_bookmark primitives_point;  /* where primitives are declared in destination tree */
	inter_bookmark ptypes_point;      /* where package types are declared in destination tree */
} transmigration_details;

@ =
void Transmigration::move(inter_package *migrant, inter_package *destination,
	int tidy_origin) {
	inter_package *P = migrant; while (P) P = InterPackage::parent(P); /* make names exist */

	transmigration_details det;
	@<Initialise the transmigration details@>;
	@<Mark the insertion and deletion points with comments@>;
	@<Move the head node of the migrant to its new home@>;
	@<Correct cross-references between the migrant and the rest of the origin tree@>;
	@<Transfer any sockets wired to the migrant@>;
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

@<Initialise the transmigration details@> =
	det.migrant = migrant;
	det.origin = InterPackage::parent(migrant);
	det.destination = destination;
	det.origin_tree = InterPackage::tree(migrant);
	det.destination_tree = InterPackage::tree(destination);

	det.deletion_point = InterBookmark::after_this_node(migrant->package_head);
	det.insertion_point = InterBookmark::at_end_of_this_package(destination);
	inter_tree_node *prims = NULL;
	LOOP_THROUGH_INTER_CHILDREN(F, destination->package_head->tree->root_node)
		if (Inode::is(F, PRIMITIVE_IST))
			prims = F;
	if (prims == NULL) internal_error("destination has no primitives");
	det.primitives_point = InterBookmark::after_this_node(prims);
	inter_tree_node *ptypes = NULL;
	LOOP_THROUGH_INTER_CHILDREN(F, destination->package_head->tree->root_node)
		if (Inode::is(F, PACKAGETYPE_IST))
			ptypes = F;
	if (ptypes == NULL) internal_error("destination has no package types");
	det.ptypes_point = InterBookmark::after_this_node(ptypes);

@<Mark the insertion and deletion points with comments@> =
	Transmigration::comment(&det.deletion_point, InterPackage::baseline(migrant),
		I"Transmigration removed", InterPackage::name(migrant));
	Transmigration::comment(&det.insertion_point, InterPackage::baseline(destination) + 1,
		I"Transmigration inserted", InterPackage::name(migrant));

@ =
void Transmigration::comment(inter_bookmark *IBM, int level, text_stream *action,
	text_stream *content) {
	TEMPORARY_TEXT(C)
	WRITE_TO(C, "%S %S here", action, content);
	CommentInstruction::new(IBM, C, NULL, (inter_ti) level);
	DISCARD_TEXT(C)
}

@ This is the only point anywhere in the Inform tool chain where a node is moved
between packages. What makes it tricky is that the symbol giving the name of the
|migrant| package, which was in the original parent package's symbols table,
must be deleted. A new symbol with the same name must be created in the symbols
table for the destination package, and the bytecode for the |package| instruction
at the node must be altered to conform with this. But when we are done, all is
consistent again.

@<Move the head node of the migrant to its new home@> =
	text_stream *migrant_name = Str::duplicate(InterPackage::name(migrant));
	inter_symbol *OS = InterSymbolsTable::symbol_from_name_not_following(
		InterPackage::parent(migrant)->package_scope, migrant_name);
	if (OS) InterSymbolsTable::remove_symbol(OS);

	NodePlacement::move_to_moving_bookmark(migrant->package_head, &det.insertion_point);
	migrant->package_head->tree = det.destination_tree;
	migrant->package_head->package = destination;

	inter_symbol *NS = InterSymbolsTable::symbol_from_name_creating(
		destination->package_scope, migrant_name);
	PackageInstruction::set_name_symbol(migrant, NS);

	if (InterPackage::container(migrant->package_head) != destination)
		internal_error("transmigration did not take the migrant to the right place");
	inter_symbol *S = PackageInstruction::name_symbol(migrant);
	if (NS != S) internal_error("transmigration of head node and symbol failed");

@ That was the easy part. The migrant package is now inside the destination tree.
Unfortunately:

(*) |migrant| may contain symbols |S ~~> O| wired to symbols |O| still in the origin
tree, because they lay outside |migrant|. This means the destination tree is now
incorrect.

(*) The origin tree may contain symbols |O ~~> S| wired to symbols |S| in the
migrant, which are therefore not in the origin tree any more. This means the origin
tree is now incorrect.

@<Correct cross-references between the migrant and the rest of the origin tree@> =
	InterTree::traverse(det.destination_tree, Transmigration::correct_migrant, &det, migrant, 0);
	if (tidy_origin)
		InterTree::traverse(det.origin_tree, Transmigration::correct_origin, &det, NULL, 0);

@ A further issue is that the original tree may have offered sockets for some
of the definitions in |migrant|. For example, |migrant| might contain some
useful function, which the origin tree was offering for linking. We want to
make an equivalent socket in the destination tree for the same function.

This is important for two reasons: firstly, because after transmigration, the
caller will need to use those sockets (see //Wiring::connect_plugs_to_sockets//),
and secondly, because this may be only one of a series of transmigrations of
Inter kits. All those kits need to see each others' sockets. So we cannot assume
that having transmigrated BasicInformKit (say), we no longer need its resources
to be socketed.

@<Transfer any sockets wired to the migrant@> =
	inter_package *origin_connectors =
		LargeScale::connectors_package_if_it_exists(det.origin_tree);
	if (origin_connectors) {
		inter_symbols_table *T = InterPackage::scope(origin_connectors);
		LOOP_OVER_SYMBOLS_TABLE(S, T) {
			if (InterSymbol::is_socket(S)) {
				inter_symbol *target = Wiring::cable_end(S);
				if ((SymbolAnnotation::get_b(target, PRIVATE_IANN) == FALSE) &&
					(InterSymbol::defined_inside(target, migrant)))
					@<S is a socket wired to a definition in the migrant@>;
			}
		}
	}

@ The difficult case here is where the destination already has a socket of
the same name. This would happen, for instance, if you transmigrated two kits
in turn, and both of them provided a function called |OverlyEagerFn()|: the
first time, a socket would be made in the destination tree; but the second
time we would find that a socket already existed.

This is arguably just a linking error and we should halt. In fact we let it
slide, and allow the destination's original socket to remain as it was. We do
this because the issues involved in linking property/attribute declarations in
WorldModelKit with their Inform 7 counterparts in the main tree are just too
awkward to confront here. (Essentially, this is a situation where the same
declaration is made twice, once in each tree, an issue to confront later. They
will end up meaning the same thing, though, so it's fine to keep using the
existing socket here.)

@<S is a socket wired to a definition in the migrant@> =
	TEMPORARY_TEXT(identifier)
	WRITE_TO(identifier, "%S", InterSymbol::identifier(S));
	LOGIF(INTER_CONNECTORS, "Origin offers socket $3 ~~> $3 in migrant\n", S, target);
	inter_symbol *equivalent = Wiring::find_socket(det.destination_tree, identifier);
	if (equivalent) {
		inter_symbol *e_target = Wiring::cable_end(equivalent);
		if (InterSymbol::is_defined(e_target) == FALSE) {
			LOGIF(INTER_CONNECTORS, "Co-opted undefined socket $3 ~~> $3\n",
				equivalent, e_target);
			Wiring::wire_to(equivalent, target);
			Wiring::wire_to(e_target, target);
		} else {
			LOGIF(INTER_CONNECTORS,
				"There is already a socket %S ~~> $3\n"
				"We use this rather than continue with %S ~~> $3\n",
				identifier, e_target, identifier, target);
		}
	} else {
		Wiring::socket(det.destination_tree, identifier, S);
	}
	DISCARD_TEXT(identifier)

@ Okay, so now for the first cross-referencing fix. The following function traverses
every node inside the |migrant| tree.

First, we amend any source file origin references in provenance instructions. For
that to work, we need the instruction to have its original |P->tree| value,
which records, for every node, the tree to which it belongs.

But then we correct |P->tree|: the need to do this is why the traverse has to
visit every node inside |migrant| (including its own head node). But we
need to work out the |primitive| invoked first, because the interpretation of the
bytecode in the invocation depends on |P->tree|, and will give a meaningful
answer only if |P->tree| is still its original value.

But then there are only two cases of interest: primitive invocations, and package
head nodes.

=
void Transmigration::correct_migrant(inter_tree *I, inter_tree_node *P, void *state) {
	transmigration_details *det = (transmigration_details *) state;
	if (Inode::is(P, PROVENANCE_IST))
		ProvenanceInstruction::migrate(P, det->destination_tree);
	inter_symbol *primitive = InvInstruction::primitive(P);
	P->tree = I;
	if (primitive)
		@<Transfer from a primitive in the origin tree to one in the destination@>;
	if (Inode::is(P, PACKAGE_IST))
		@<This is the headnode of a subpackage of migrant@>;
}

@ Primitive invocations matter because, say, |inv !printnumber| in the migrant
will contain a reference to the origin tree's definition of |!printnumber|; this
must be converted to a reference to the destination's definition of the same thing.

Note that we expect to perform this operation frequently -- there may be, say,
10,000 primitive invocations in the migrant, but always of the same 50 or so
primitives round and around -- so we cache the results.

@<Transfer from a primitive in the origin tree to one in the destination@> =
	inter_symbol *equivalent_primitive = Transmigration::known_equivalent(primitive);
	if (equivalent_primitive == NULL) {
		equivalent_primitive = InterSymbolsTable::symbol_from_name(
			InterTree::global_scope(det->destination_tree), InterSymbol::identifier(primitive));
		if (equivalent_primitive == NULL) @<Duplicate this primitive@>;
		Transmigration::learn_equivalent(primitive, equivalent_primitive);
	}
	if (equivalent_primitive)
		InvInstruction::write_primitive(det->destination_tree, P, equivalent_primitive);

@ In the worst-case scenario, the destination might not even have a declaration
of |!printnumber|. (Actually this is unlikely in practice, because we tend to make
the same set of primitive declarations in every tree.) In this case, we write a
new declaration in the root package of the destination, duplicating the one in
the root package of the origin.

@<Duplicate this primitive@> =
	equivalent_primitive = InterSymbolsTable::symbol_from_name_creating(
		InterTree::global_scope(det->destination_tree), InterSymbol::identifier(primitive));
	inter_tree_node *old_D = primitive->definition;
	inter_tree_node *D = Inode::new_with_2_data_fields(&(det->primitives_point), PRIMITIVE_IST,
		InterSymbolsTable::id_from_symbol(det->destination_tree, NULL, equivalent_primitive),
		old_D->W.instruction[BIP_PRIM_IFLD],
		NULL, 0);
	for (int i=SIGNATURE_PRIM_IFLD; i<old_D->W.extent; i++) {
		Inode::extend_instruction_by(D, 1);
		D->W.instruction[i] = old_D->W.instruction[i];
	}
	inter_error_message *E = VerifyingInter::instruction(
		InterBookmark::package(&(det->primitives_point)), D);
	if (E) {
		InterErrors::issue(E);
		equivalent_primitive = NULL;
	} else {
		NodePlacement::move_to_moving_bookmark(D, &(det->primitives_point));
	}

@<This is the headnode of a subpackage of migrant@> =
	inter_package *pack = PackageInstruction::at_this_head(P);
	if (InterPackage::is_a_linkage_package(pack))
		internal_error("tried to transmigrate /main, /main/connectors or /");
	@<Correct the reference to this package type@>;
	@<Correct outbound wiring from the package's symbols table@>;

@ Package types present the exact same issue as primitive invocations: the types
are given in terms of declarations in the origin tree, and have to be transferred
to matching declarations in the destination.

@<Correct the reference to this package type@> =
	inter_symbol *original_ptype = PackageInstruction::get_type_of(det->origin_tree, P);
	inter_symbol *equivalent_ptype = Transmigration::known_equivalent(original_ptype);
	if (equivalent_ptype == NULL) {
		equivalent_ptype = InterSymbolsTable::symbol_from_name(
			InterTree::global_scope(det->destination_tree), InterSymbol::identifier(original_ptype));
		if (equivalent_ptype == NULL) @<Duplicate this package type@>;
		Transmigration::learn_equivalent(original_ptype, equivalent_ptype);
	}
	PackageInstruction::set_type(det->destination_tree, P, equivalent_ptype);

@<Duplicate this package type@> =
	equivalent_ptype = InterSymbolsTable::symbol_from_name_creating(
		InterTree::global_scope(det->destination_tree), InterSymbol::identifier(original_ptype));
	inter_tree_node *D = Inode::new_with_1_data_field(&(det->ptypes_point), PACKAGETYPE_IST,
		InterSymbolsTable::id_from_symbol(det->destination_tree, NULL, equivalent_ptype), NULL, 0);
	inter_error_message *E = VerifyingInter::instruction(
		InterBookmark::package(&(det->ptypes_point)), D);
	if (E) {
		InterErrors::issue(E);
		equivalent_ptype = NULL;
	} else {
		NodePlacement::move_to_moving_bookmark(D, &(det->ptypes_point));
	}

@ Here |S| is some miscellaneous symbol in our subpackage of |migrant| -- it
can't be either a plug or a socket, since the connectors never migrate -- and
there are three bad possibilities:

@<Correct outbound wiring from the package's symbols table@> =
	inter_symbols_table *T = InterPackage::scope(pack);
	if (T == NULL) internal_error("package with no symbols");
	LOOP_OVER_SYMBOLS_TABLE(S, T) {
		if (Wiring::is_wired(S)) {
			inter_symbol *target = Wiring::cable_end(S);
			inter_package *target_package = InterSymbol::package(target);
			if (target_package ==
				LargeScale::architecture_package(InterPackage::tree(target_package)))
				@<S is wired to an architectural symbol in the origin tree@>
			else if (InterSymbol::is_plug(target))
				@<S is wired to a loose plug in the origin tree@>
			else if (InterSymbol::defined_inside(S, det->migrant) == FALSE)
				@<S is wired to a miscellaneous symbol still in the origin tree@>
		}
	}

@ For example, |S| is wired to |WORDSIZE| in the origin tree, which is (let
us say) a constant equal to 4. We wire it instead to |WORDSIZE| in the destination
tree, which will also be equal to 4 because we only ever transmigrate between
trees with the same Inter architecture.

@<S is wired to an architectural symbol in the origin tree@> =
	inter_symbol *equivalent = Transmigration::known_equivalent(target);
	if (equivalent == NULL) {
		equivalent = LargeScale::find_architectural_symbol(det->destination_tree,
			InterSymbol::identifier(target));
		Transmigration::learn_equivalent(target, equivalent);
	}
	Wiring::wire_to(S, equivalent);					

@ Here |S| is wired to a plug, and it must be a loose plug because |target| is
the cable-end from |S|: if that cable ends in a plug, clearly the plug is not
wired to a socket. That means it is wired to a name, |target ~~> "some_name"|.
We wire |S| instead to a plug seeking |some_name| in the destination tree;
note that this may result in a new plug being made there, or may re-use an
existing one already looking for (or indeed already having found) |"some_name"|.

@<S is wired to a loose plug in the origin tree@> =
	inter_symbol *equivalent = Transmigration::known_equivalent(target);
	if (equivalent == NULL) {
		text_stream *N = Wiring::wired_to_name(target);
		equivalent = Wiring::plug(det->destination_tree, N);
		Transmigration::learn_equivalent(target, equivalent);
	}
	Wiring::wire_to(S, equivalent);					

@ Finally |S| may be wired to some ordinary symbol defined in the origin tree
but outside of |migrant|. Well, that resource is now outside of the destination
tree: and this is exactly what plugs in the destination tree are for.

@<S is wired to a miscellaneous symbol still in the origin tree@> =
	inter_symbol *equivalent = Transmigration::known_equivalent(target);
	if (equivalent == NULL) {
		equivalent = Wiring::plug(det->destination_tree, InterSymbol::identifier(target));
		Transmigration::learn_equivalent(target, equivalent);
	}
	Wiring::wire_to(S, equivalent);

@ Now time for the second sort of correction: references from the origin tree
into the migrant. If we care about those, then we traverse so that the following 
visits every node in the origin tree. Note that at this point the head node
of |migrant| has been removed from the origin tree -- so this visitor can never
visit anything inside |migrant|.

Note that we do not correct references from the origin tree's |/main/connectors|
package, i.e., plugs and sockets wired to something in |migrant|; we handle
those separately (see above).

=
void Transmigration::correct_origin(inter_tree *I, inter_tree_node *P, void *state) {
	transmigration_details *det = (transmigration_details *) state;
	if (Inode::is(P, PACKAGE_IST)) {
		inter_package *pack = PackageInstruction::at_this_head(P);
		if (InterPackage::is_a_linkage_package(pack) == FALSE) {
			inter_symbols_table *T = InterPackage::scope(pack);
			LOOP_OVER_SYMBOLS_TABLE(S, T)
				if (Wiring::is_wired(S)) {
					inter_symbol *target = Wiring::cable_end(S);
					if (InterSymbol::defined_inside(target, det->migrant))
						@<S is wired to a symbol in the migrant@>;
				}
		}
	}
}

@ This is now symmetrical to the case above. |S| is wired to what is now a
resource in a different tree, so it needs to be wired to a plug instead.

@<S is wired to a symbol in the migrant@> =
	inter_symbol *equivalent = Transmigration::known_equivalent(target);
	if (equivalent == NULL) {
		equivalent = Wiring::plug(det->origin_tree, InterSymbol::identifier(S));
		Transmigration::learn_equivalent(target, equivalent);
	}
	Wiring::wire_to(S, equivalent);

@ That just leaves the cache. The idea is that for each different act of
transmigration, we want to cache the symbol conversions made. The following
is fast, but a little wasteful of memory, since it involves storing two fields
in every //inter_symbol//:

=
typedef struct transmigration_data {
	int valid_on_which_transmigration;
	struct inter_symbol *cached_equivalent;
} transmigration_data;

@ =
transmigration_data Transmigration::new_transmigration_data(inter_symbol *S) {
	transmigration_data td;
	td.valid_on_which_transmigration = 0;
	td.cached_equivalent = NULL;
	return td;
}

@ The scheme is that each different act of transmigration has its own unique
ID, counting upwards from 1. 

=
int current_transmigration_count = 1;
void Transmigration::begin_cache_session(void) {
	++current_transmigration_count;
}

@ This count is used only to see if the |cached_equivalent| symbol was set
during the current transmigration (rather than some previous one). Using this
count is quicker, since it saves the time needed to walk through all existing
symbols resetting the |cached_equivalent| fields to |NULL|.

=
void Transmigration::learn_equivalent(inter_symbol *S, inter_symbol *V) {
	S->transmigration.cached_equivalent = V;
	S->transmigration.valid_on_which_transmigration = current_transmigration_count;
}

inter_symbol *Transmigration::known_equivalent(inter_symbol *S) {
	if (S->transmigration.valid_on_which_transmigration == current_transmigration_count)
		return S->transmigration.cached_equivalent;
	return NULL;
}
