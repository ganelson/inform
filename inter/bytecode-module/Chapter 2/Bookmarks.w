[Inter::Bookmarks::] Bookmarks.

Write positions for inter code being generated.

@ 

=
typedef struct inter_bookmark {
	struct inter_tree_node *R;
	int placement_wrt_R;
} inter_bookmark;

inter_bookmark Inter::Bookmarks::at_start_of_this_repository(inter_tree *I) {
	inter_bookmark IBM;
	IBM.R = I->root_node;
	IBM.placement_wrt_R = AFTER_NODEPLACEMENT;
	return IBM;
}

inter_bookmark Inter::Bookmarks::at_end_of_this_package(inter_package *pack) {
	if (pack == NULL) internal_error("no package supplied"); 
	inter_bookmark IBM;
	IBM.R = Inter::Packages::definition(pack);
	IBM.placement_wrt_R = AS_LAST_CHILD_OF_NODEPLACEMENT;
	return IBM;
}

inter_bookmark Inter::Bookmarks::after_this_node(inter_tree *I, inter_tree_node *D) {
	if (D == NULL) internal_error("invalid frame supplied");
	inter_bookmark IBM;
	IBM.R = D;
	IBM.placement_wrt_R = AFTER_NODEPLACEMENT;
	return IBM;
}

inter_bookmark Inter::Bookmarks::first_child_of_this_node(inter_tree *I, inter_tree_node *D) {
	if (D == NULL) internal_error("invalid frame supplied");
	inter_bookmark IBM;
	IBM.R = D;
	IBM.placement_wrt_R = AS_FIRST_CHILD_OF_NODEPLACEMENT;
	return IBM;
}

void Inter::Bookmarks::set_current_package(inter_bookmark *IBM, inter_package *P) {
	if (IBM == NULL) internal_error("no bookmark supplied"); 
	if (P == NULL) internal_error("invalid package supplied");
	inter_tree_node *D = Inter::Packages::definition(P);
	if (D == NULL) D = Inter::Packages::tree(P)->root_node;
	IBM->R = InterTree::last_child(D);
	IBM->placement_wrt_R = AFTER_NODEPLACEMENT;
	if (IBM->R == NULL) {
		IBM->R = D;
		IBM->placement_wrt_R = AS_FIRST_CHILD_OF_NODEPLACEMENT;
	}
}

inter_tree *Inter::Bookmarks::tree(inter_bookmark *IBM) {
	if (IBM == NULL) return NULL;
	return IBM->R->tree;
}

inter_warehouse *Inter::Bookmarks::warehouse(inter_bookmark *IBM) {
	return InterTree::warehouse(Inter::Bookmarks::tree(IBM));
}

int Inter::Bookmarks::get_placement(inter_bookmark *IBM) {
	if (IBM == NULL) internal_error("no bookmark supplied"); 
	return IBM->placement_wrt_R;
}

void Inter::Bookmarks::set_placement(inter_bookmark *IBM, int p) {
	if (IBM == NULL) internal_error("no bookmark supplied"); 
	IBM->placement_wrt_R = p;
}

inter_tree_node *Inter::Bookmarks::get_ref(inter_bookmark *IBM) {
	if (IBM == NULL) internal_error("no bookmark supplied"); 
	return IBM->R;
}

void Inter::Bookmarks::set_ref(inter_bookmark *IBM, inter_tree_node *F) {
	if (IBM == NULL) internal_error("no bookmark supplied"); 
	IBM->R = F;
}

inter_bookmark Inter::Bookmarks::snapshot(inter_bookmark *IBM) {
	return *IBM;
}

int Inter::Bookmarks::baseline(inter_bookmark *IBM) {
	inter_package *pack = Inter::Bookmarks::package(IBM);
	if (pack) return Inter::Packages::baseline(pack);
	return 0;
}

void Inter::Bookmarks::log(OUTPUT_STREAM, void *virs) {
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
		if (IBM->R) WRITE("%d", IBM->R->W.index);
		LOG("(%d)>", Inter::Bookmarks::baseline(IBM));
	}
}

inter_symbols_table *Inter::Bookmarks::scope(inter_bookmark *IBM) {
	inter_package *pack = Inter::Bookmarks::package(IBM);
	if (pack) return Inter::Packages::scope(pack);
	return InterTree::global_scope(Inter::Bookmarks::tree(IBM));
}

inter_package *Inter::Bookmarks::package(inter_bookmark *IBM) {
	if (IBM == NULL) return NULL;
	inter_package *pack = IBM->R->package;
	if ((IBM->placement_wrt_R == AS_FIRST_CHILD_OF_NODEPLACEMENT) ||
		(IBM->placement_wrt_R == AS_LAST_CHILD_OF_NODEPLACEMENT)) {
		inter_package *R_defined = Inter::Package::defined_by_frame(IBM->R);
		if (R_defined) pack = R_defined;
	}
	return pack;
}

void Inter::Bookmarks::insert(inter_bookmark *IBM, inter_tree_node *F) {
	if (F == NULL) internal_error("no frame to insert");
	if (IBM == NULL) internal_error("nowhere to insert");
	inter_package *pack = Inter::Bookmarks::package(IBM);
	inter_tree *I = Inter::Packages::tree(pack);
	LOGIF(INTER_FRAMES, "Insert frame %F\n", *F);
	inter_ti F_level = F->W.data[LEVEL_IFLD];
	if (F_level == 0) {
		if (InterTree::parent(Inter::Bookmarks::get_ref(IBM)) == NULL)
			InterTree::move_node(F, AS_LAST_CHILD_OF_NODEPLACEMENT, I->root_node);
		else
			InterTree::move_node(F, Inter::Bookmarks::get_placement(IBM), Inter::Bookmarks::get_ref(IBM));
		if ((Inter::Bookmarks::get_placement(IBM) == AFTER_NODEPLACEMENT) ||
			(Inter::Bookmarks::get_placement(IBM) == IMMEDIATELY_AFTER_NODEPLACEMENT)) {
			Inter::Bookmarks::set_ref(IBM, F);
		}
	} else {
		if ((Inter::Bookmarks::get_placement(IBM) == AFTER_NODEPLACEMENT) ||
			(Inter::Bookmarks::get_placement(IBM) == IMMEDIATELY_AFTER_NODEPLACEMENT)) {
			while (F_level < Inter::Bookmarks::get_ref(IBM)->W.data[LEVEL_IFLD]) {
				inter_tree_node *R = Inter::Bookmarks::get_ref(IBM);
				inter_tree_node *PR = InterTree::parent(R);
				if (PR == NULL) internal_error("bubbled up out of tree");
				Inter::Bookmarks::set_ref(IBM, PR);
			}
			if (F_level > Inter::Bookmarks::get_ref(IBM)->W.data[LEVEL_IFLD] + 1) internal_error("bubbled down off of tree");
			if (F_level == Inter::Bookmarks::get_ref(IBM)->W.data[LEVEL_IFLD] + 1) {
				if (Inter::Bookmarks::get_placement(IBM) == IMMEDIATELY_AFTER_NODEPLACEMENT) {
					InterTree::move_node(F, AS_FIRST_CHILD_OF_NODEPLACEMENT, Inter::Bookmarks::get_ref(IBM));
					Inter::Bookmarks::set_placement(IBM, AFTER_NODEPLACEMENT);
				} else {
					InterTree::move_node(F, AS_LAST_CHILD_OF_NODEPLACEMENT, Inter::Bookmarks::get_ref(IBM));
				}
			} else {
				InterTree::move_node(F, AFTER_NODEPLACEMENT, Inter::Bookmarks::get_ref(IBM));
			}
			Inter::Bookmarks::set_ref(IBM, F);
			return;
		}
		InterTree::move_node(F, Inter::Bookmarks::get_placement(IBM), Inter::Bookmarks::get_ref(IBM));
		if (Inter::Bookmarks::get_placement(IBM) == AS_FIRST_CHILD_OF_NODEPLACEMENT) {
			Inter::Bookmarks::set_ref(IBM, F);
			Inter::Bookmarks::set_placement(IBM, AFTER_NODEPLACEMENT);
		}
	}
}

