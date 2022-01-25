[InterTree::] Inter Trees.

To manage tree structures of inter code, and manage the movement of nodes
within these trees.

@ An //inter_tree// expresses a single program: see //What This Module Does//
for more. At first sight, it's a very small object, but |root_node| leads
to a massive tree structure, and the |inter_warehouse| and |building_site|
compoments can also be huge. Note that the latter is managed entirely by
the //building// module, but that everything else here is ours.

=
typedef struct inter_tree {
	struct inter_tree_node *root_node;
	struct inter_package *root_package;
	struct inter_warehouse *housed;
	unsigned int history_bits;
	struct building_site site;
	CLASS_DEFINITION
} inter_tree;

@ =
inter_tree *InterTree::new(void) {
	inter_tree *I = CREATE(inter_tree);
	@<Make the warehouse@>;
	@<Make the root node and the root package@>;
	I->history_bits = 0;
	InterTree::set_history(I, CREATED_ITHBIT);
	BuildingModule::clear_data(I);
	return I;
}

@ This must be done first, since we can't make symbols tables without it:

@<Make the warehouse@> =
	I->housed = Inter::Warehouse::new();

@ Now a delicate little dance. The entire content of the tree is contained
inside a special "root package". Packages are visible from the outside but
not the inside, so the root package is effectively invisible: nothing is
outside it. This is why it has no name, and is never referred to by Inter
code written out in textual form. In any case, special restrictions apply
to it, and calling //Inter::Packages::make_rootlike// causes those to be
enforced.

Every package has a "head node": the content of the package will be the
children and descendants of that node. The root node for the tree is by
definition the head node for the root package of the tree.

|N| here is the warehouse ID number for the global symbols table of the tree,
which is by definition the symbols table for the root package.

@<Make the root node and the root package@> =
	inter_ti N = Inter::Warehouse::create_symbols_table(I->housed);
	inter_symbols_table *globals = Inter::Warehouse::get_symbols_table(I->housed, N);
	inter_ti root_package_ID = Inter::Warehouse::create_package(I->housed, I);
	I->root_package = Inter::Warehouse::get_package(I->housed, root_package_ID);
	I->root_node = Inode::new_root_node(I->housed, I);
	I->root_package->package_head = I->root_node;
	Inter::Packages::make_rootlike(I->root_package);
	Inter::Packages::set_scope(I->root_package, globals);
	I->root_node->package = I->root_package;
	Inter::Warehouse::attribute_resource(I->housed, N, I->root_package);

@ =
inter_package *InterTree::root_package(inter_tree *I) {
	if (I) return I->root_package;
	return NULL;
}

inter_symbols_table *InterTree::global_scope(inter_tree *I) {
	return Inter::Packages::scope(I->root_package);
}

inter_warehouse *InterTree::warehouse(inter_tree *I) {
	return I->housed;
}

@h Walking along branches of the tree.
For operations on individual nodes, including how to create them, see
//Inter Nodes//. Here, we provide functions for walking through the nodes,
making use of the tree structure between them.

=
inter_tree_node *InterTree::previous(inter_tree_node *F) {
	if (F == NULL) return NULL;
	return F->previous_itn;
}

inter_tree_node *InterTree::next(inter_tree_node *F) {
	if (F == NULL) return NULL;
	return F->next_itn;
}

inter_tree_node *InterTree::first_child(inter_tree_node *F) {
	if (F == NULL) return NULL;
	return F->first_child_itn;
}

inter_tree_node *InterTree::second_child(inter_tree_node *P) {
	if (P == NULL) return NULL;
	P = P->first_child_itn;
	if (P == NULL) return NULL;
	return P->next_itn;
}

inter_tree_node *InterTree::third_child(inter_tree_node *P) {
	if (P == NULL) return NULL;
	P = P->first_child_itn;
	if (P == NULL) return NULL;
	P = P->next_itn;
	if (P == NULL) return NULL;
	return P->next_itn;
}

inter_tree_node *InterTree::fourth_child(inter_tree_node *P) {
	if (P == NULL) return NULL;
	P = P->first_child_itn;
	if (P == NULL) return NULL;
	P = P->next_itn;
	if (P == NULL) return NULL;
	P = P->next_itn;
	if (P == NULL) return NULL;
	return P->next_itn;
}

inter_tree_node *InterTree::fifth_child(inter_tree_node *P) {
	if (P == NULL) return NULL;
	P = P->first_child_itn;
	if (P == NULL) return NULL;
	P = P->next_itn;
	if (P == NULL) return NULL;
	P = P->next_itn;
	if (P == NULL) return NULL;
	P = P->next_itn;
	if (P == NULL) return NULL;
	return P->next_itn;
}

inter_tree_node *InterTree::sixth_child(inter_tree_node *P) {
	if (P == NULL) return NULL;
	P = P->first_child_itn;
	if (P == NULL) return NULL;
	P = P->next_itn;
	if (P == NULL) return NULL;
	P = P->next_itn;
	if (P == NULL) return NULL;
	P = P->next_itn;
	if (P == NULL) return NULL;
	P = P->next_itn;
	if (P == NULL) return NULL;
	return P->next_itn;
}

inter_tree_node *InterTree::last_child(inter_tree_node *F) {
	if (F == NULL) return NULL;
	return F->last_child_itn;
}

inter_tree_node *InterTree::parent(inter_tree_node *F) {
	if (F == NULL) return NULL;
	return F->parent_itn;
}

@ Accessing child nodes one by one -- //InterTree::third_child//, etc. --
can only take you so far. Here's a convenient fast way to loop through:

@d LOOP_THROUGH_INTER_CHILDREN(F, P)
	for (inter_tree_node *F = InterTree::first_child(P); F; F = InterTree::next(F))

@ If we want to do this more slowly, making sure that severing the current
node won't cause the loop to terminate early:

@d PROTECTED_LOOP_THROUGH_INTER_CHILDREN(F, P)
	for (inter_tree_node *F = InterTree::first_child(P), *FN = F?(InterTree::next(F)):NULL;
		F; F = FN, FN = FN?(InterTree::next(FN)):NULL)

@h Traversing an entire tree.
The following traverses through all of the root nodes of a tree, calling the
|visitor| function on each node matching the given type filter. If |filter|
is 0, that's every node; if it is something like |PACKAGE_IST|, then it
visits only nodes of type |PACKAGE_IST|; if it is |-PACKAGE_IST|, it visits
only nodes of types other than |PACKAGE_IST|.

|state| is opaque to us, and is a way for the caller to have persistent state
across visits to different nodes.

=
void InterTree::traverse_root_only(inter_tree *from,
	void (*visitor)(inter_tree *, inter_tree_node *, void *),
	void *state, int filter) {
	PROTECTED_LOOP_THROUGH_INTER_CHILDREN(P, from->root_node) {
		if ((filter == 0) ||
			((filter > 0) && (P->W.data[ID_IFLD] == (inter_ti) filter)) ||
			((filter < 0) && (P->W.data[ID_IFLD] != (inter_ti) -filter)))
			(*visitor)(from, P, state);
	}
}

@ This is similar, but begins at the root of the package |mp|, and recurses
downwards through it and all its subpackages. If |mp| is null, recursion is
from the tree's |/main| package. Note that this does not visit nodes at the
root level, for which see above.

The same filter conventions apply.

=
void InterTree::traverse(inter_tree *from,
	void (*visitor)(inter_tree *, inter_tree_node *, void *),
	void *state, inter_package *mp, int filter) {
	if (mp == NULL) mp = LargeScale::main_package_if_it_exists(from);
	if (mp) {
		inter_tree_node *D = Inter::Packages::definition(mp);
		if ((filter == 0) ||
			((filter > 0) && (D->W.data[ID_IFLD] == (inter_ti) filter)) ||
			((filter < 0) && (D->W.data[ID_IFLD] != (inter_ti) -filter)))
			(*visitor)(from, D, state);
		InterTree::traverse_r(from, D, visitor, state, filter);
	}
}
void InterTree::traverse_r(inter_tree *from, inter_tree_node *P,
	void (*visitor)(inter_tree *, inter_tree_node *, void *),
	void *state, int filter) {
	PROTECTED_LOOP_THROUGH_INTER_CHILDREN(C, P) {
		if ((filter == 0) ||
			((filter > 0) && (C->W.data[ID_IFLD] == (inter_ti) filter)) ||
			((filter < 0) && (C->W.data[ID_IFLD] != (inter_ti) -filter)))
			(*visitor)(from, C, state);
		InterTree::traverse_r(from, C, visitor, state, filter);
	}
}

@ It is also convenient to provide a way to loop through the subpackages of
a package.

@d LOOP_THROUGH_SUBPACKAGES(entry, pack, ptype)
	inter_symbol *pack##wanted =
		(pack)?(LargeScale::package_type(pack->package_head->tree, ptype)):NULL;
	if (pack)
		LOOP_THROUGH_INTER_CHILDREN(C, Inter::Packages::definition(pack))
			if ((C->W.data[ID_IFLD] == PACKAGE_IST) &&
				(entry = Inter::Package::defined_by_frame(C)) &&
				(Inter::Packages::type(entry) == pack##wanted))

@ As a demonstration of this in action:

=
int InterTree::no_subpackages(inter_package *pack, text_stream *ptype) {
	int N = 0;
	if (pack) {
		inter_package *entry;
		LOOP_THROUGH_SUBPACKAGES(entry, pack, ptype) N++;
	}
	return N;
}

@h Movement of nodes.
All modifications of the links between nodes must be made with these functions.

Each node contains pointers to its previous and next child of the same parent;
to its parent node; and to its first child node. There are many implied
invariants in that arrangement (e.g., that if X has a child then the parent of
that child is X), and these two functions guarantee that those invariants
are preserved.

=
void InterTree::remove_node(inter_tree_node *C) {
	@<Extricate C from its current tree position@>;
}

@ |InterTree::move_node(C, how, R)| moves |C| to a new position defined
by the placement |how| with respect to an existing node |R|.

@e BEFORE_NODEPLACEMENT from 0
@e AFTER_NODEPLACEMENT
@e IMMEDIATELY_AFTER_NODEPLACEMENT
@e AS_FIRST_CHILD_OF_NODEPLACEMENT
@e AS_LAST_CHILD_OF_NODEPLACEMENT

=
void InterTree::move_node(inter_tree_node *C, int how, inter_tree_node *R) {
	@<Extricate C from its current tree position@>;
	switch (how) {
		case AS_FIRST_CHILD_OF_NODEPLACEMENT:
			@<Make C the first child of R@>;
			break;
		case AS_LAST_CHILD_OF_NODEPLACEMENT:
			@<Make C the last child of R@>;
			break;
		case AFTER_NODEPLACEMENT:
		case IMMEDIATELY_AFTER_NODEPLACEMENT:
			@<Insert C after R@>;
			break;
		case BEFORE_NODEPLACEMENT:
			@<Insert C before R@>;
			break;
		default:
			internal_error("unimplemented");
	}
}

@<Extricate C from its current tree position@> =
	inter_tree_node *OP = InterTree::parent(C);
	if (OP) {
		if (InterTree::first_child(OP) == C)
			InterTree::set_first_child_UNSAFE(OP, InterTree::next(C));
		if (InterTree::last_child(OP) == C)
			InterTree::set_last_child_UNSAFE(OP, InterTree::previous(C));
	}
	inter_tree_node *OB = InterTree::previous(C);
	inter_tree_node *OD = InterTree::next(C);
	if (OB) {
		InterTree::set_next_UNSAFE(OB, OD);
	}
	if (OD) {
		InterTree::set_previous_UNSAFE(OD, OB);
	}
	InterTree::set_parent_UNSAFE(C, NULL);
	InterTree::set_previous_UNSAFE(C, NULL);
	InterTree::set_next_UNSAFE(C, NULL);

@<Make C the first child of R@> =
	InterTree::set_parent_UNSAFE(C, R);
	inter_tree_node *D = InterTree::first_child(R);
	if (D == NULL) {
		InterTree::set_last_child_UNSAFE(R, C);
		InterTree::set_next_UNSAFE(C, NULL);
	} else {
		InterTree::set_previous_UNSAFE(D, C);
		InterTree::set_next_UNSAFE(C, D);
	}
	InterTree::set_first_child_UNSAFE(R, C);

@<Make C the last child of R@> =
	InterTree::set_parent_UNSAFE(C, R);
	inter_tree_node *B = InterTree::last_child(R);
	if (B == NULL) {
		InterTree::set_first_child_UNSAFE(R, C);
		InterTree::set_previous_UNSAFE(C, NULL);
	} else {
		InterTree::set_next_UNSAFE(B, C);
		InterTree::set_previous_UNSAFE(C, B);
	}
	InterTree::set_last_child_UNSAFE(R, C);

@<Insert C after R@> =
	inter_tree_node *P = InterTree::parent(R);
	if (P == NULL) internal_error("can't move C before R when R is nowhere");
	InterTree::set_parent_UNSAFE(C, P);
	if (InterTree::last_child(P) == R)
		InterTree::set_last_child_UNSAFE(P, C);
	else {
		inter_tree_node *D = InterTree::next(R);
		if (D == NULL) internal_error("inter tree broken");
		InterTree::set_next_UNSAFE(C, D);
		InterTree::set_previous_UNSAFE(D, C);
	}
	InterTree::set_next_UNSAFE(R, C);
	InterTree::set_previous_UNSAFE(C, R);

@<Insert C before R@> =
	inter_tree_node *P = InterTree::parent(R);
	if (P == NULL) internal_error("can't move C before R when R is nowhere");
	InterTree::set_parent_UNSAFE(C, P);
	if (InterTree::first_child(P) == R)
		InterTree::set_first_child_UNSAFE(P, C);
	else {
		inter_tree_node *B = InterTree::previous(R);
		if (B == NULL) internal_error("inter tree broken");
		InterTree::set_previous_UNSAFE(C, B);
		InterTree::set_next_UNSAFE(B, C);
	}
	InterTree::set_next_UNSAFE(C, R);
	InterTree::set_previous_UNSAFE(R, C);

@ The names of these functions are intended to discourage their use. They
should only be used by //InterTree::move_node//.

=
void InterTree::set_previous_UNSAFE(inter_tree_node *F, inter_tree_node *V) {
	if (F) F->previous_itn = V;
}

void InterTree::set_next_UNSAFE(inter_tree_node *F, inter_tree_node *V) {
	if (F) F->next_itn = V;
}

void InterTree::set_first_child_UNSAFE(inter_tree_node *F, inter_tree_node *V) {
	if (F) F->first_child_itn = V;
}

void InterTree::set_last_child_UNSAFE(inter_tree_node *F, inter_tree_node *V) {
	if (F) F->last_child_itn = V;
}

void InterTree::set_parent_UNSAFE(inter_tree_node *F, inter_tree_node *V) {
	if (F) F->parent_itn = V;
}

@h History of a tree.
In 1964, a Nevada geologist felled a bristlecone pine and was dismayed to find
that it contained 4862 rings, and had therefore germinated in around 2900 BC.
Inter trees also record their history, though can safely accommodate only 32
different events, identified as flag bits 0 to 31.

Calling |InterTree::set_history(I, B)| sets flag |B|; |InterTree::test_history|
then tests it. There is purposely no way to clear these flags once set. They
should only be used to record that irrevocable, one-time-only, things have
been done.

@e CREATED_ITHBIT from 0

=
void InterTree::set_history(inter_tree *I, int bit) {
	I->history_bits |= (1 << bit);
}

int InterTree::test_history(inter_tree *I, int bit) {
	if (I->history_bits & (1 << bit)) return TRUE;
	return FALSE;
}
