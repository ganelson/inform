[NodePlacement::] Node Placement.

Moving nodes in a tree, adding them to a tree, removing them from a tree.

@ Each node contains pointers to its previous and next child of the same parent;
to its parent node; and to its first child node. There are many implied
invariants in that arrangement (e.g., that if X has a child then the parent of
that child is X), and it would be eaxy to get all this wrong.

All modifications of the links between nodes must therefore be made by one of
only three functions:

(*) |NodePlacement::remove(C)| removes the node |C| from the tree.
(*) |NodePlacement::move_to(C, IBM)| moves the node |C| to the position
bookmarked by |IBM|. |C| can but need not already be in the tree.
(*) |NodePlacement::move_to_moving_bookmark(C, IBM)| moves the node |F| to
the position bookmarked by |IBM|, but also adjusts |IBM| to be the natural
next write position.

=
void NodePlacement::remove(inter_tree_node *C) {
	@<Extricate C from its current tree position@>;
}

void NodePlacement::move_to(inter_tree_node *C, inter_bookmark IBM) {
	@<Extricate C from its current tree position@>;
	switch (IBM.placement_wrt_R) {
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
			NodePlacement::set_first_child_UNSAFE(OP, InterTree::next(C));
		if (InterTree::last_child(OP) == C)
			NodePlacement::set_last_child_UNSAFE(OP, InterTree::previous(C));
	}
	inter_tree_node *OB = InterTree::previous(C);
	inter_tree_node *OD = InterTree::next(C);
	if (OB) {
		NodePlacement::set_next_UNSAFE(OB, OD);
	}
	if (OD) {
		NodePlacement::set_previous_UNSAFE(OD, OB);
	}
	NodePlacement::set_parent_UNSAFE(C, NULL);
	NodePlacement::set_previous_UNSAFE(C, NULL);
	NodePlacement::set_next_UNSAFE(C, NULL);

@<Make C the first child of R@> =
	NodePlacement::set_parent_UNSAFE(C, IBM.R);
	inter_tree_node *D = InterTree::first_child(IBM.R);
	if (D == NULL) {
		NodePlacement::set_last_child_UNSAFE(IBM.R, C);
		NodePlacement::set_next_UNSAFE(C, NULL);
	} else {
		NodePlacement::set_previous_UNSAFE(D, C);
		NodePlacement::set_next_UNSAFE(C, D);
	}
	NodePlacement::set_first_child_UNSAFE(IBM.R, C);

@<Make C the last child of R@> =
	NodePlacement::set_parent_UNSAFE(C, IBM.R);
	inter_tree_node *B = InterTree::last_child(IBM.R);
	if (B == NULL) {
		NodePlacement::set_first_child_UNSAFE(IBM.R, C);
		NodePlacement::set_previous_UNSAFE(C, NULL);
	} else {
		NodePlacement::set_next_UNSAFE(B, C);
		NodePlacement::set_previous_UNSAFE(C, B);
	}
	NodePlacement::set_last_child_UNSAFE(IBM.R, C);

@<Insert C after R@> =
	inter_tree_node *P = InterTree::parent(IBM.R);
	if (P == NULL) internal_error("can't move C before R when R is nowhere");
	NodePlacement::set_parent_UNSAFE(C, P);
	if (InterTree::last_child(P) == IBM.R)
		NodePlacement::set_last_child_UNSAFE(P, C);
	else {
		inter_tree_node *D = InterTree::next(IBM.R);
		if (D == NULL) internal_error("inter tree broken");
		NodePlacement::set_next_UNSAFE(C, D);
		NodePlacement::set_previous_UNSAFE(D, C);
	}
	NodePlacement::set_next_UNSAFE(IBM.R, C);
	NodePlacement::set_previous_UNSAFE(C, IBM.R);

@<Insert C before R@> =
	inter_tree_node *P = InterTree::parent(IBM.R);
	if (P == NULL) internal_error("can't move C before R when R is nowhere");
	NodePlacement::set_parent_UNSAFE(C, P);
	if (InterTree::first_child(P) == IBM.R)
		NodePlacement::set_first_child_UNSAFE(P, C);
	else {
		inter_tree_node *B = InterTree::previous(IBM.R);
		if (B == NULL) internal_error("inter tree broken");
		NodePlacement::set_previous_UNSAFE(C, B);
		NodePlacement::set_next_UNSAFE(B, C);
	}
	NodePlacement::set_next_UNSAFE(C, IBM.R);
	NodePlacement::set_previous_UNSAFE(IBM.R, C);

@ The names of these functions are intended to discourage their use. They
should only be used by //NodePlacement::move_to//.

=
void NodePlacement::set_previous_UNSAFE(inter_tree_node *C, inter_tree_node *V) {
	if (C) C->previous_itn = V;
}

void NodePlacement::set_next_UNSAFE(inter_tree_node *C, inter_tree_node *V) {
	if (C) C->next_itn = V;
}

void NodePlacement::set_first_child_UNSAFE(inter_tree_node *C, inter_tree_node *V) {
	if (C) C->first_child_itn = V;
}

void NodePlacement::set_last_child_UNSAFE(inter_tree_node *C, inter_tree_node *V) {
	if (C) C->last_child_itn = V;
}

void NodePlacement::set_parent_UNSAFE(inter_tree_node *C, inter_tree_node *V) {
	if (C) C->parent_itn = V;
}

@ This is more intricate than //NodePlacement::move_to//. The differences are
basically that:

(*) |IBM| is considered to be a write position which should move along with
each forwards write that is made, as if it's a sort of cursor. By "forwards
write", we mean anything other than |BEFORE_NODEPLACEMENT|; the cursor does
not move backwards. So if we call this function to write A, B, C, ... after R,
the result is ... R, A, B, C..., the cursor advancing one position each time;
and if we call it to write A, B, C, ... before R, the result is ... A, B, C, R,
..., with the cursor staying put at R.

(*) In the two "after" placements, we look at the level assigned to the new
node |C|, which tells us what hierarchical depth it should be at in the tree;
if this is a different level from the bookmark's level, the bookmark is moved
to that new level.

For example, suppose we have this fragment of tree:
= (text)
	Level	6...7...8...
	Nodes	node1
				node2
				node3
					node4 	<--- Bookmark is AFTER_NODEPLACEMENT wrt node4
				node5
			node6
=
If |C| is to be at level 8, the same level as the bookmark, we get:
= (text)
	Level	6...7...8...
	Nodes	node1
				node2
				node3
					node4
					C 		<--- Bookmark is AFTER_NODEPLACEMENT wrt C
				node5
			node6
=
If instead it is to be at level 6:
= (text)
	Level	6...7...8...
	Nodes	node1
				node2
				node3
					node4
				node5
			node6
			C 				<--- Bookmark is AFTER_NODEPLACEMENT wrt C
=
Here, C has "bubbled up" the tree. Finally, if it is to be at level 9:
= (text)
	Level	6...7...8...
	Nodes	node1
				node2
				node3
					node4
						C 	<--- Bookmark is AFTER_NODEPLACEMENT wrt C
				node5
			node6
=
Note that if C is to be at level 10, an internal error is thrown; there is no
way to reach as low as that from |node4|.

=
void NodePlacement::move_to_moving_bookmark(inter_tree_node *C, inter_bookmark *IBM) {
	if (C == NULL) internal_error("no node to insert");
	if (IBM == NULL) internal_error("nowhere to insert");
	NodePlacement::move_to(C, NodePlacement::to_position(C, InterBookmark::snapshot(IBM)));
	if (IBM->placement_wrt_R != BEFORE_NODEPLACEMENT) {
		IBM->R = C;
		IBM->placement_wrt_R = AFTER_NODEPLACEMENT;
	}
}

inter_bookmark NodePlacement::to_position(inter_tree_node *C, inter_bookmark IBM) {
	if (InterTree::parent(IBM.R) == NULL)
		return InterBookmark::at_end_of_root(InterBookmark::tree(&IBM));

	if ((IBM.placement_wrt_R == AFTER_NODEPLACEMENT) ||
		(IBM.placement_wrt_R == IMMEDIATELY_AFTER_NODEPLACEMENT))
		@<Nodes placed after may need to bubble up or down@>

	return IBM;
}

@<Nodes placed after may need to bubble up or down@> =
	inter_tree_node *R = IBM.R;
	inter_ti C_level = C->W.data[LEVEL_IFLD], R_level = R->W.data[LEVEL_IFLD];
	while (C_level < R_level) {
		R = InterTree::parent(R);
		R_level--;
		if (R == NULL) internal_error("bubbled up out of tree");
	}
	if (C_level == R_level) {
		return InterBookmark::after_this_node(R);
	} else if (C_level == R_level + 1) {
		if (IBM.placement_wrt_R == IMMEDIATELY_AFTER_NODEPLACEMENT)
			return InterBookmark::first_child_of(R);
		else
			return InterBookmark::last_child_of(R);
	} else {
		internal_error("bubbled down off of tree"); /* see above for why */
	}
