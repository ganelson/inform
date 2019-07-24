[Inter::Bookmarks::] Bookmarks.

Write positions for inter code being generated.

@ 

@e BEFORE_ICPLACEMENT from 0
@e AFTER_ICPLACEMENT
@e IMMEDIATELY_AFTER_ICPLACEMENT
@e AS_FIRST_CHILD_OF_ICPLACEMENT
@e AS_LAST_CHILD_OF_ICPLACEMENT
@e NOWHERE_ICPLACEMENT

=
typedef struct inter_bookmark {
	struct inter_tree_node *R;
	int placement_wrt_R;
} inter_bookmark;

inter_bookmark Inter::Bookmarks::at_start_of_this_repository(inter_tree *I) {
	inter_bookmark IBM;
	IBM.R = I->root_node;
	IBM.placement_wrt_R = AFTER_ICPLACEMENT;
	return IBM;
}

inter_bookmark Inter::Bookmarks::at_end_of_this_package(inter_package *pack) {
	if (pack == NULL) internal_error("no package supplied"); 
	inter_bookmark IBM;
	IBM.R = Inter::Symbols::definition(pack->package_name);
	IBM.placement_wrt_R = AS_LAST_CHILD_OF_ICPLACEMENT;
	return IBM;
}

inter_bookmark Inter::Bookmarks::after_this_frame(inter_tree *I, inter_tree_node *D) {
	if (D == NULL) internal_error("invalid frame supplied");
	inter_bookmark IBM;
	IBM.R = D;
	IBM.placement_wrt_R = AFTER_ICPLACEMENT;
	return IBM;
}

void Inter::Bookmarks::set_current_package(inter_bookmark *IBM, inter_package *P) {
	if (IBM == NULL) internal_error("no bookmark supplied"); 
	if (P == NULL) internal_error("invalid package supplied");
	inter_tree_node *D = Inter::Symbols::definition(P->package_name);
	if (D == NULL) D = P->stored_in->root_node;
	IBM->R = Inter::Tree::last_child(D);
	IBM->placement_wrt_R = AFTER_ICPLACEMENT;
	if (IBM->R == NULL) {
		IBM->R = D;
		IBM->placement_wrt_R = AS_FIRST_CHILD_OF_ICPLACEMENT;
	}
}

inter_tree *Inter::Bookmarks::tree(inter_bookmark *IBM) {
	if (IBM == NULL) return NULL;
	return IBM->R->tree;
}

inter_warehouse *Inter::Bookmarks::warehouse(inter_bookmark *IBM) {
	return Inter::Tree::warehouse(Inter::Bookmarks::tree(IBM));
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
			case BEFORE_ICPLACEMENT: WRITE("before:"); break;
			case AFTER_ICPLACEMENT: WRITE("after:"); break;
			case IMMEDIATELY_AFTER_ICPLACEMENT: WRITE("immediately-after:"); break;
			case AS_FIRST_CHILD_OF_ICPLACEMENT: WRITE("first-child:"); break;
			case AS_LAST_CHILD_OF_ICPLACEMENT: WRITE("last-child:"); break;
			case NOWHERE_ICPLACEMENT: WRITE("nowhere"); break;
			default: WRITE("?:"); break;
		}
		if (IBM->placement_wrt_R != NOWHERE_ICPLACEMENT) {
			if (IBM->R) WRITE("%d", IBM->R->W.index);
		}
		LOG("(%d)>", Inter::Bookmarks::baseline(IBM));
	}
}

inter_symbols_table *Inter::Bookmarks::scope(inter_bookmark *IBM) {
	inter_package *pack = Inter::Bookmarks::package(IBM);
	if (pack) return Inter::Packages::scope(pack);
	return Inter::Tree::global_scope(Inter::Bookmarks::tree(IBM));
}

inter_package *Inter::Bookmarks::package(inter_bookmark *IBM) {
	if (IBM == NULL) return NULL;
	inter_package *pack = IBM->R->package;
	if ((IBM->placement_wrt_R == AS_FIRST_CHILD_OF_ICPLACEMENT) ||
		(IBM->placement_wrt_R == AS_LAST_CHILD_OF_ICPLACEMENT)) {
		inter_package *R_defined = Inter::Package::defined_by_frame(IBM->R);
		if (R_defined) pack = R_defined;
	}
	return pack;
}

void Inter::Bookmarks::insert(inter_bookmark *IBM, inter_tree_node *F) {
	if (F == NULL) internal_error("no frame to insert");
	if (IBM == NULL) internal_error("nowhere to insert");
	inter_package *pack = Inter::Bookmarks::package(IBM);
	inter_tree *I = pack->stored_in;
	LOGIF(INTER_FRAMES, "Insert frame %F\n", *F);
	inter_t F_level = F->W.data[LEVEL_IFLD];
	if (F_level == 0) {
		Inter::Tree::place(F, AS_LAST_CHILD_OF_ICPLACEMENT, I->root_node);
		if ((Inter::Bookmarks::get_placement(IBM) == AFTER_ICPLACEMENT) ||
			(Inter::Bookmarks::get_placement(IBM) == IMMEDIATELY_AFTER_ICPLACEMENT)) {
			Inter::Bookmarks::set_ref(IBM, F);
		}
	} else {
		if (Inter::Bookmarks::get_placement(IBM) == NOWHERE_ICPLACEMENT) internal_error("bad wrt");
		if ((Inter::Bookmarks::get_placement(IBM) == AFTER_ICPLACEMENT) ||
			(Inter::Bookmarks::get_placement(IBM) == IMMEDIATELY_AFTER_ICPLACEMENT)) {
			while (F_level < Inter::Bookmarks::get_ref(IBM)->W.data[LEVEL_IFLD]) {
				inter_tree_node *R = Inter::Bookmarks::get_ref(IBM);
				inter_tree_node *PR = Inter::Tree::parent(R);
				if (PR == NULL) internal_error("bubbled up out of tree");
				Inter::Bookmarks::set_ref(IBM, PR);
			}
			if (F_level > Inter::Bookmarks::get_ref(IBM)->W.data[LEVEL_IFLD] + 1) internal_error("bubbled down off of tree");
			if (F_level == Inter::Bookmarks::get_ref(IBM)->W.data[LEVEL_IFLD] + 1) {
				if (Inter::Bookmarks::get_placement(IBM) == IMMEDIATELY_AFTER_ICPLACEMENT) {
					Inter::Tree::place(F, AS_FIRST_CHILD_OF_ICPLACEMENT, Inter::Bookmarks::get_ref(IBM));
					Inter::Bookmarks::set_placement(IBM, AFTER_ICPLACEMENT);
				} else {
					Inter::Tree::place(F, AS_LAST_CHILD_OF_ICPLACEMENT, Inter::Bookmarks::get_ref(IBM));
				}
			} else {
				Inter::Tree::place(F, AFTER_ICPLACEMENT, Inter::Bookmarks::get_ref(IBM));
			}
			Inter::Bookmarks::set_ref(IBM, F);
			return;
		}
		Inter::Tree::place(F, Inter::Bookmarks::get_placement(IBM), Inter::Bookmarks::get_ref(IBM));
		if (Inter::Bookmarks::get_placement(IBM) == AS_FIRST_CHILD_OF_ICPLACEMENT) {
			Inter::Bookmarks::set_ref(IBM, F);
			Inter::Bookmarks::set_placement(IBM, AFTER_ICPLACEMENT);
		}
	}
}

