[Inter::Bookmarks::] Bookmarks.

Write positions for inter code being generated.

@ =
typedef struct inter_reading_state {
	struct inter_repository *read_into;
	struct inter_package *current_package;
	int cp_indent;
	int latest_indent;
	struct inter_frame R;
	int placement_wrt_R;
} inter_reading_state;

@ =
inter_reading_state Inter::Bookmarks::new_IRS(inter_repository *I) {
	inter_reading_state IRS;
	IRS.read_into = I;
	IRS.current_package = NULL;
	IRS.cp_indent = 0;
	IRS.latest_indent = 0;
	IRS.R = Inter::Frame::around(NULL, -1);
	IRS.placement_wrt_R = AFTER_ICPLACEMENT;
	return IRS;
}

inter_reading_state Inter::Bookmarks::snapshot(inter_reading_state *IRS) {
	inter_reading_state IRS2 = *IRS;
	return IRS2;
}

inter_reading_state Inter::Bookmarks::from_package(inter_package *pack) {
	inter_reading_state IRS = Inter::Bookmarks::new_IRS(pack->stored_in);
	IRS.current_package = pack;
	IRS.cp_indent = Inter::Packages::baseline(pack);
	inter_frame D = Inter::Symbols::defining_frame(pack->package_name);
	IRS.R = D;
	IRS.placement_wrt_R = AS_LAST_CHILD_OF_ICPLACEMENT;
	return IRS;
}

inter_reading_state Inter::Bookmarks::from_frame(inter_frame D) {
	inter_reading_state IRS = Inter::Bookmarks::new_IRS(D.repo_segment->owning_repo);
	IRS.current_package = Inter::Packages::container(D);
	IRS.cp_indent = Inter::Packages::baseline(IRS.current_package);
	IRS.R = D;
	IRS.placement_wrt_R = AFTER_ICPLACEMENT;
	return IRS;
}

void Inter::Bookmarks::log(OUTPUT_STREAM, void *virs) {
	inter_reading_state *IRS = (inter_reading_state *) virs;
	if (IRS == NULL) WRITE("<null-bookmark>");
	else {
		LOG("<bookmark:");
		if (IRS->read_into) LOG("%d:", IRS->read_into->allocation_id);
		else LOG("--:");
		if (IRS->current_package == NULL) LOG("--");
		else LOG("$6", IRS->current_package);
		LOG("(%d)>", IRS->cp_indent);
	}
}

inter_symbols_table *Inter::Bookmarks::scope(inter_reading_state *IRS) {
	if ((IRS) && (IRS->current_package)) return Inter::Packages::scope(IRS->current_package);
	return Inter::get_global_symbols(IRS->read_into);
}

inter_package *Inter::Bookmarks::package(inter_reading_state *IRS) {
	if ((IRS) && (IRS->current_package)) return IRS->current_package;
	return NULL;
}
