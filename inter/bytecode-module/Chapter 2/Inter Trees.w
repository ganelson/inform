[InterTree::] Inter Trees.

To manage tree structures of inter code, and manage the movement of nodes
within these trees.

@ An //inter_tree// expresses a single program: see //What This Module Does//
for more. At first sight, it's a very small object, but |root_node| leads
to a massive tree structure, and the |inter_warehouse| and |building_site|
components can also be huge. Note that the latter is managed entirely by
the //building// module, but that everything else here is ours.

=
typedef struct inter_tree {
	struct inter_tree_node *root_node;
	struct inter_package *root_package;
	struct inter_warehouse *housed;
	unsigned int history_bits;
	struct building_site site;
	struct filename *blame_errors_on_this_file;
	int cross_referencing_suspended;
	CLASS_DEFINITION
} inter_tree;

@ The warehouse must be created before anything else can be done, since we can't
make symbols tables without it:

=
inter_tree *InterTree::new(void) {
	inter_tree *I = CREATE(inter_tree);
	I->housed = InterWarehouse::new();
	@<Make the root node and the root package@>;
	I->history_bits = 0;
	I->blame_errors_on_this_file = NULL;
	I->cross_referencing_suspended = FALSE;
	InterTree::set_history(I, CREATED_ITHBIT);
	BuildingModule::clear_data(I);
	return I;
}

@ Now a delicate little dance. The entire content of the tree is contained
inside a special "root package". Packages are visible from the outside but
not the inside, so the root package is effectively invisible: nothing is
outside it. This is why it has no name, and is never referred to by Inter
code written out in textual form. In any case, special restrictions apply
to it, and calling //InterPackage::mark_as_a_root_package// causes those to be
enforced.

Every package has a "head node": the content of the package will be the
children and descendants of that node. The root node for the tree is by
definition the head node for the root package of the tree.

|N| here is the warehouse ID number for the global symbols table of the tree,
which is by definition the symbols table for the root package.

@<Make the root node and the root package@> =
	inter_ti N = InterWarehouse::create_symbols_table(I->housed);
	inter_symbols_table *globals = InterWarehouse::get_symbols_table(I->housed, N);
	inter_ti root_package_ID = InterWarehouse::create_package(I->housed, I);
	I->root_package = InterWarehouse::get_package(I->housed, root_package_ID);
	I->root_node = Inode::new_root_node(I->housed, I);
	I->root_package->package_head = I->root_node;
	InterPackage::mark_as_a_root_package(I->root_package);
	InterPackage::set_scope(I->root_package, globals);
	I->root_node->package = I->root_package;
	InterWarehouse::set_symbols_table_owner(I->housed, N, I->root_package);

@ =
inter_package *InterTree::root_package(inter_tree *I) {
	if (I) return I->root_package;
	return NULL;
}

inter_symbols_table *InterTree::global_scope(inter_tree *I) {
	return InterPackage::scope(I->root_package);
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

inter_tree_node *InterTree::seventh_child(inter_tree_node *P) {
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
			((filter > 0) && (Inode::is(P, (inter_ti) filter))) ||
			((filter < 0) && (Inode::isnt(P, (inter_ti) -filter))))
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
		inter_tree_node *D = InterPackage::head(mp);
		if ((filter == 0) ||
			((filter > 0) && (Inode::is(D, (inter_ti) filter))) ||
			((filter < 0) && (Inode::isnt(D, (inter_ti) -filter))))
			(*visitor)(from, D, state);
		InterTree::traverse_r(from, D, visitor, state, filter);
	}
}
void InterTree::traverse_r(inter_tree *from, inter_tree_node *P,
	void (*visitor)(inter_tree *, inter_tree_node *, void *),
	void *state, int filter) {
	PROTECTED_LOOP_THROUGH_INTER_CHILDREN(C, P) {
		if ((filter == 0) ||
			((filter > 0) && (Inode::is(C, (inter_ti) filter))) ||
			((filter < 0) && (Inode::isnt(C, (inter_ti) -filter))))
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
		LOOP_THROUGH_INTER_CHILDREN(C, InterPackage::head(pack))
			if ((Inode::is(C, PACKAGE_IST)) &&
				(entry = PackageInstruction::at_this_head(C)) &&
				(InterPackage::type(entry) == pack##wanted))

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

@h History of a tree.
In 1964, a Nevada geologist felled a bristlecone pine and was dismayed to find
that it contained 4862 rings, and had therefore germinated in around 2900 BC.
Until just that morning, it had been the oldest tree in the world.

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

@h The file to blame.
The |blame_errors_on_this_file| field for a tree is meaningful only during the
period when an instruction is being read in from a text or binary Inter file.
Such a file is untrustworthy -- we didn't make it ourselves -- and so we
check it in many ways, and need a way to throw error messages if it is corrupt.

Since Inter instructions can come in either from a binary or a text file, we
need a unified way to express positions in these, as an unsigned integer stored
in the preframe for an instruction (see //Inter Nodes//).

By convention, an origin value below |INTER_ERROR_ORIGIN_OFFSET| is a line
number; an origin above that is a binary address within a file (plus
|INTER_ERROR_ORIGIN_OFFSET|). We record such addresses only up to a file
position equivalent to about 179 megabytes; in practice the largest binary
inter files now in existence are about 8 megabytes, so this seems fine for now.

@d INTER_ERROR_ORIGIN_OFFSET 0x10000000

=
inter_ti InterTree::eloc_to_origin_word(inter_tree *tree, inter_error_location *eloc) {
	if (eloc) {
		if (eloc->error_interb) {
			tree->blame_errors_on_this_file = eloc->error_interb;
			inter_ti w = (inter_ti) (INTER_ERROR_ORIGIN_OFFSET + eloc->error_offset);
			if (w & 0x80000000) w = 0;
			return w;
		}
		if (eloc->error_tfp) {
			tree->blame_errors_on_this_file = eloc->error_tfp->text_file_filename;
			return (inter_ti) (eloc->error_tfp->line_count);
		}
	}
	return 0;
}

@ Converting this back into an //inter_error_location// means allocating some
memory, since an //inter_error_location// only holds pointers to the position
data, not the position data itself. So:

=
typedef struct inter_error_stash {
	struct inter_error_location stashed_eloc;
	struct text_file_position stashed_tfp;
	CLASS_DEFINITION
} inter_error_stash;

@ =
inter_error_location *InterTree::origin_word_to_eloc(inter_tree *tree, inter_ti C) {
	if ((tree) && (tree->blame_errors_on_this_file)) {
		inter_error_stash *stash = CREATE(inter_error_stash);
		stash->stashed_tfp = TextFiles::nowhere();
		if (C < INTER_ERROR_ORIGIN_OFFSET) {
			text_file_position *tfp = &(stash->stashed_tfp);
			tfp->text_file_filename = tree->blame_errors_on_this_file;
			tfp->line_count = (int) C;
			stash->stashed_eloc =
				InterErrors::file_location(NULL, tfp);
		} else {
			stash->stashed_eloc =
				InterErrors::interb_location(tree->blame_errors_on_this_file,
					(size_t) (C - INTER_ERROR_ORIGIN_OFFSET));
		}
		return &(stash->stashed_eloc);
	}
	return NULL;
}
