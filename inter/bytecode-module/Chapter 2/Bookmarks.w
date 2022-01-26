[InterBookmark::] Bookmarks.

Write positions for inter code being generated.

@ A bookmark does not record an actual position in an Inter tree -- if we needed
that, a pointer to the relevant |inter_tree_node| would do fine -- but to a
hypothetical position. It describes where to put a node which has not yet been
put into position.

It does this by recording not only a reference node |R| but a relationship
which the hypothetical new position will have with respect to it:

@e BEFORE_NODEPLACEMENT from 0
@e AFTER_NODEPLACEMENT
@e IMMEDIATELY_AFTER_NODEPLACEMENT
@e AS_FIRST_CHILD_OF_NODEPLACEMENT
@e AS_LAST_CHILD_OF_NODEPLACEMENT

=
typedef struct inter_bookmark {
	struct inter_tree_node *R;
	int placement_wrt_R; /* one of the |*_NODEPLACEMENT| values */
} inter_bookmark;

@ Bookmarks are used to mark positions in an Inter tree, though they are oftem
used in a way which causes them to move forwards through that tree, much as
a bookmark will migrate through a book as it is slowly read.

Because of this, the bookmark structure is one of the few in the Inform tool
chain to be used sometimes as a value and sometimes a reference -- that is,
we make use both of |inter_bookmark| and |inter_bookmark *| as types. So a
function which simply needs to know where to do something will take the
type |inter_bookmark| as an argument -- see //NodePlacement::move_to//, for
example -- whereas a function which does something but then nudges the
bookmark onwards will take an |inter_bookmark *|, as in the caee of
//NodePlacement::move_to_moving_bookmark//.

Dereferencing a bookmark pointer to a bookmark value is called taking a
"snapshot". The idea is that the original is likely to move on, but we want
to preserve the position it is currently at. For clarity of the code, we
give this a name as a function:

=
inter_bookmark InterBookmark::snapshot(inter_bookmark *IBM) {
	return *IBM;
}

@ We can also take a snapshot but change the placement:

=
inter_bookmark InterBookmark::shifted(inter_bookmark *IBM, int new_placement) {
	inter_bookmark new_IBM = InterBookmark::snapshot(IBM);
	new_IBM.placement_wrt_R = new_placement;
	return new_IBM;
}

@ Of course, we can only snapshot a bookmark already existing somewhere else,
so we still need creator functions:

=
inter_bookmark InterBookmark::at_start_of_this_repository(inter_tree *I) {
	return InterBookmark::after_this_node(I->root_node);
}

inter_bookmark InterBookmark::after_this_node(inter_tree_node *D) {
	return InterBookmark::new(D, AFTER_NODEPLACEMENT);
}

inter_bookmark InterBookmark::at_end_of_root(inter_tree *I) {
	return InterBookmark::last_child_of(I->root_node);
}

inter_bookmark InterBookmark::at_end_of_this_package(inter_package *pack) {
	if (pack == NULL) internal_error("no package supplied"); 
	return InterBookmark::last_child_of(Inter::Packages::definition(pack));
}

inter_bookmark InterBookmark::last_child_of(inter_tree_node *D) {
	return InterBookmark::new(D, AS_LAST_CHILD_OF_NODEPLACEMENT);
}

inter_bookmark InterBookmark::immediately_after(inter_tree_node *D) {
	return InterBookmark::new(D, IMMEDIATELY_AFTER_NODEPLACEMENT);
}

inter_bookmark InterBookmark::first_child_of(inter_tree_node *D) {
	return InterBookmark::new(D, AS_FIRST_CHILD_OF_NODEPLACEMENT);
}

inter_bookmark InterBookmark::new(inter_tree_node *D, int placement) {
	if (D == NULL) internal_error("no node in bookmark");
	inter_bookmark IBM;
	IBM.R = D;
	IBM.placement_wrt_R = placement;
	return IBM;
}

@ Note that this moves the bookmark, not whatever node in the tree the bookmark
is (or was) marking.

=
void InterBookmark::move_into_package(inter_bookmark *IBM, inter_package *P) {
	if (IBM == NULL) internal_error("no bookmark supplied"); 
	if (P == NULL) internal_error("invalid package supplied");
	inter_tree_node *D = Inter::Packages::definition(P);
	if (D == NULL) D = Inter::Packages::tree(P)->root_node;
	if (InterTree::last_child(D)) {
		IBM->R = InterTree::last_child(D);
		IBM->placement_wrt_R = AFTER_NODEPLACEMENT;
	} else {
		IBM->R = D;
		IBM->placement_wrt_R = AS_FIRST_CHILD_OF_NODEPLACEMENT;
	}
}

@ Following the same conventions, this function returns the package into which
a node moved to the bookmark would then live. In particular,
|InterBookmark::package(InterBookmark::move_into_package(IBM, P))| is always
equal to |P|.

=
inter_package *InterBookmark::package(inter_bookmark *IBM) {
	if (IBM == NULL) return NULL;
	inter_package *pack = IBM->R->package;
	if ((IBM->placement_wrt_R == AS_FIRST_CHILD_OF_NODEPLACEMENT) ||
		(IBM->placement_wrt_R == AS_LAST_CHILD_OF_NODEPLACEMENT)) {
		inter_package *R_defined = Inter::Package::defined_by_frame(IBM->R);
		if (R_defined) pack = R_defined;
	}
	return pack;
}

@ Some convenience functions:

=
inter_tree *InterBookmark::tree(inter_bookmark *IBM) {
	if (IBM == NULL) return NULL;
	return IBM->R->tree;
}

inter_warehouse *InterBookmark::warehouse(inter_bookmark *IBM) {
	return InterTree::warehouse(InterBookmark::tree(IBM));
}

int InterBookmark::baseline(inter_bookmark *IBM) {
	inter_package *pack = InterBookmark::package(IBM);
	if (pack) return Inter::Packages::baseline(pack);
	return 0;
}

inter_symbols_table *InterBookmark::scope(inter_bookmark *IBM) {
	inter_package *pack = InterBookmark::package(IBM);
	if (pack) return Inter::Packages::scope(pack);
	return InterTree::global_scope(InterBookmark::tree(IBM));
}

@ Logging:

=
void InterBookmark::log(OUTPUT_STREAM, void *virs) {
	inter_bookmark *IBM = (inter_bookmark *) virs;
	if (IBM == NULL) WRITE("<null-bookmark>");
	else {
		LOG("<");
		switch (IBM->placement_wrt_R) {
			case BEFORE_NODEPLACEMENT: WRITE("before:"); break;
			case AFTER_NODEPLACEMENT: WRITE("after:"); break;
			case IMMEDIATELY_AFTER_NODEPLACEMENT: WRITE("immediately-after:"); break;
			case AS_FIRST_CHILD_OF_NODEPLACEMENT: WRITE("first-child:"); break;
			case AS_LAST_CHILD_OF_NODEPLACEMENT: WRITE("last-child:"); break;
			default: WRITE("?:"); break;
		}
		if (IBM->R) WRITE("%d", IBM->R->W.index); else WRITE("<NO-NODE>");
		LOG("(%d)>", InterBookmark::baseline(IBM));
	}
}
