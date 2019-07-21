[Inter::Bookmarks::] Bookmarks.

Write positions for inter code being generated.

@ =
typedef struct inter_bookmark {
	struct inter_tree *read_into;
	struct inter_package *current_package;
	struct inter_frame R;
	int placement_wrt_R;
} inter_bookmark;

@ =
inter_bookmark Inter::Bookmarks::at_start_of_this_repository(inter_tree *I) {
	inter_bookmark IBM;
	IBM.read_into = I;
	IBM.current_package = NULL;
	IBM.R = Inter::Frame::around(NULL, -1);
	IBM.placement_wrt_R = AFTER_ICPLACEMENT;
	return IBM;
}

inter_bookmark Inter::Bookmarks::at_end_of_this_package(inter_package *pack) {
	if (pack == NULL) internal_error("no package supplied"); 
	inter_bookmark IBM;
	IBM.read_into = pack->stored_in;
	IBM.current_package = pack;
	IBM.R = Inter::Symbols::defining_frame(pack->package_name);
	IBM.placement_wrt_R = AS_LAST_CHILD_OF_ICPLACEMENT;
	return IBM;
}

inter_bookmark Inter::Bookmarks::after_this_frame(inter_tree *I, inter_frame D) {
	if (Inter::Frame::valid(&D) == FALSE) internal_error("invalid frame supplied");
	inter_bookmark IBM;
	IBM.read_into = I;
	IBM.current_package = Inter::Packages::container(D);
	IBM.R = D;
	IBM.placement_wrt_R = AFTER_ICPLACEMENT;
	return IBM;
}

void Inter::Bookmarks::set_current_package(inter_bookmark *IBM, inter_package *P) {
	if (IBM == NULL) internal_error("no bookmark supplied"); 
	IBM->current_package = P;
	if (P) IBM->R = Inter::Symbols::defining_frame(P->package_name);
	else IBM->R = Inter::Frame::around(NULL, -1);
	IBM->placement_wrt_R = AFTER_ICPLACEMENT;
}

int Inter::Bookmarks::get_placement(inter_bookmark *IBM) {
	if (IBM == NULL) internal_error("no bookmark supplied"); 
	return IBM->placement_wrt_R;
}

void Inter::Bookmarks::set_placement(inter_bookmark *IBM, int p) {
	if (IBM == NULL) internal_error("no bookmark supplied"); 
	IBM->placement_wrt_R = p;
}

inter_frame Inter::Bookmarks::get_ref(inter_bookmark *IBM) {
	if (IBM == NULL) internal_error("no bookmark supplied"); 
	return IBM->R;
}

void Inter::Bookmarks::set_ref(inter_bookmark *IBM, inter_frame F) {
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
		if (IBM->read_into) LOG("%d:", IBM->read_into->allocation_id);
		else LOG("--:");
		if (IBM->current_package == NULL) LOG("--");
		else LOG("$3", IBM->current_package->package_name);
		LOG("(%d)>", Inter::Bookmarks::baseline(IBM));
	}
}

inter_symbols_table *Inter::Bookmarks::scope(inter_bookmark *IBM) {
	if ((IBM) && (IBM->current_package)) return Inter::Packages::scope(IBM->current_package);
	return Inter::get_global_symbols(IBM->read_into);
}

inter_package *Inter::Bookmarks::package(inter_bookmark *IBM) {
	if ((IBM) && (IBM->current_package)) return IBM->current_package;
	return NULL;
}
