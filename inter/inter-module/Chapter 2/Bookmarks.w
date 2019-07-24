[Inter::Bookmarks::] Bookmarks.

Write positions for inter code being generated.

@ =
typedef struct inter_bookmark {
	struct inter_package *current_package;
	struct inter_frame *R;
	int placement_wrt_R;
} inter_bookmark;

@ =
inter_bookmark Inter::Bookmarks::at_start_of_this_repository(inter_tree *I) {
	inter_bookmark IBM;
	IBM.current_package = I->root_package;
	IBM.R = I->root_definition_frame;
	IBM.placement_wrt_R = AFTER_ICPLACEMENT;
	return IBM;
}

inter_tree *Inter::Bookmarks::tree(inter_bookmark *IBM) {
	if (IBM == NULL) return NULL;
	if (IBM->current_package == NULL) internal_error("no package");
	return IBM->current_package->stored_in;
}

inter_warehouse *Inter::Bookmarks::warehouse(inter_bookmark *IBM) {
	return Inter::warehouse(Inter::Bookmarks::tree(IBM));
}

inter_bookmark Inter::Bookmarks::at_end_of_this_package(inter_package *pack) {
	if (pack == NULL) internal_error("no package supplied"); 
	inter_bookmark IBM;
	IBM.current_package = pack;
	IBM.R = Inter::Symbols::definition(pack->package_name);
	IBM.placement_wrt_R = AS_LAST_CHILD_OF_ICPLACEMENT;
	return IBM;
}

inter_bookmark Inter::Bookmarks::after_this_frame(inter_tree *I, inter_frame *D) {
	if (D == NULL) internal_error("invalid frame supplied");
	inter_bookmark IBM;
	IBM.current_package = Inter::Packages::container(D);
	if (IBM.current_package == NULL) IBM.current_package = I->root_package;
	IBM.R = D;
	IBM.placement_wrt_R = AFTER_ICPLACEMENT;
	return IBM;
}

void Inter::Bookmarks::set_current_package(inter_bookmark *IBM, inter_package *P) {
	if (IBM == NULL) internal_error("no bookmark supplied"); 
	if (P == NULL) internal_error("invalid package supplied");
	IBM->current_package = P;
	if (Inter::Packages::is_rootlike(P)) {
		IBM->R = P->stored_in->root_definition_frame;
		IBM->placement_wrt_R = AS_LAST_CHILD_OF_ICPLACEMENT;
	} else {
		inter_frame *D = Inter::Symbols::definition(P->package_name);
		IBM->R = D;
		IBM->placement_wrt_R = AFTER_ICPLACEMENT;
	}
}

int Inter::Bookmarks::get_placement(inter_bookmark *IBM) {
	if (IBM == NULL) internal_error("no bookmark supplied"); 
	return IBM->placement_wrt_R;
}

void Inter::Bookmarks::set_placement(inter_bookmark *IBM, int p) {
	if (IBM == NULL) internal_error("no bookmark supplied"); 
	IBM->placement_wrt_R = p;
}

inter_frame *Inter::Bookmarks::get_ref(inter_bookmark *IBM) {
	if (IBM == NULL) internal_error("no bookmark supplied"); 
	return IBM->R;
}

void Inter::Bookmarks::set_ref(inter_bookmark *IBM, inter_frame *F) {
	if (IBM == NULL) internal_error("no bookmark supplied"); 
	IBM->R = F;
}

inter_bookmark Inter::Bookmarks::snapshot(inter_bookmark *IBM) {
	return *IBM;
}

int Inter::Bookmarks::baseline(inter_bookmark *IBM) {
	if ((IBM) && (IBM->current_package))
		return Inter::Packages::baseline(IBM->current_package);
	return 0;
}

void Inter::Bookmarks::log(OUTPUT_STREAM, void *virs) {
	inter_bookmark *IBM = (inter_bookmark *) virs;
	if (IBM == NULL) WRITE("<null-bookmark>");
	else {
		LOG("<bookmark:");
		if (IBM->current_package == NULL) LOG("--");
		else LOG("$3", IBM->current_package->package_name);
		LOG("(%d)>", Inter::Bookmarks::baseline(IBM));
	}
}

inter_symbols_table *Inter::Bookmarks::scope(inter_bookmark *IBM) {
	if ((IBM) && (IBM->current_package)) return Inter::Packages::scope(IBM->current_package);
	return Inter::get_global_symbols(Inter::Bookmarks::tree(IBM));
}

inter_package *Inter::Bookmarks::package(inter_bookmark *IBM) {
	if ((IBM) && (IBM->current_package)) return IBM->current_package;
	return NULL;
}
