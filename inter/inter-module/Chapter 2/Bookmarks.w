[Inter::Bookmarks::] Bookmarks.

Write positions for inter code being generated.

@ =
typedef struct inter_reading_state {
	struct inter_repository *read_into;
	struct inter_package *current_package;
	int cp_indent;
	int latest_indent;
	struct inter_frame_list *in_frame_list;
	struct inter_frame_list_entry *pos;
	int pinned_to_end;
} inter_reading_state;

@ =
inter_reading_state Inter::Bookmarks::new_IRS(inter_repository *I) {
	inter_reading_state IRS;
	IRS.read_into = I;
	IRS.current_package = NULL;
	IRS.cp_indent = 0;
	IRS.latest_indent = 0;
	IRS.in_frame_list = &(I->residue);
	IRS.pos = IRS.in_frame_list->last_in_ifl;
	IRS.pinned_to_end = TRUE;
	return IRS;
}

inter_reading_state Inter::Bookmarks::new_IRS_global(inter_repository *I) {
	inter_reading_state IRS;
	IRS.read_into = I;
	IRS.current_package = NULL;
	IRS.cp_indent = 0;
	IRS.latest_indent = 0;
	IRS.in_frame_list = &(I->global_material);
	IRS.pos = IRS.in_frame_list->last_in_ifl;
	IRS.pinned_to_end = TRUE;
	return IRS;
}

inter_reading_state Inter::Bookmarks::snapshot(inter_reading_state *IRS) {
	inter_reading_state IRS2 = *IRS;
	if (IRS2.pos == NULL) internal_error("unanchored bookmark");
	IRS2.pinned_to_end = FALSE;
	return IRS2;
}

inter_reading_state Inter::Bookmarks::from_package(inter_package *pack) {
	inter_reading_state IRS = Inter::Bookmarks::new_IRS(pack->stored_in);
	IRS.pinned_to_end = FALSE;
	IRS.current_package = pack;
	IRS.cp_indent = Inter::Packages::baseline(pack);
	// This is too slow for more than occasional use
	for (inter_frame_list_entry *pos = IRS.in_frame_list->first_in_ifl; pos; pos = pos->next_in_ifl)
		if (pack == Inter::Packages::container(pos->listed_frame)) {
			IRS.pos = pos;
			return IRS;
		}
	return IRS;
}

inter_reading_state Inter::Bookmarks::from_frame(inter_frame D) {
	inter_reading_state IRS = Inter::Bookmarks::new_IRS(D.repo_segment->owning_repo);
	IRS.pinned_to_end = FALSE;
	IRS.current_package = Inter::Packages::container(D);
	IRS.cp_indent = Inter::Packages::baseline(IRS.current_package);
	// This is too slow for more than occasional use
	for (inter_frame_list_entry *pos = IRS.in_frame_list->first_in_ifl; pos; pos = pos->next_in_ifl)
		if (pos->listed_frame.data == D.data) {
			IRS.pos = pos;
			return IRS;
		}
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
		LOG("(%d)", IRS->cp_indent);
		int ix = 0;
		for (inter_frame_list_entry *e = IRS->in_frame_list->first_in_ifl; ((e) && (e != IRS->pos)); e = e->next_in_ifl) ix++;
		LOG(":list %08x, entry %08x = %d>", IRS->in_frame_list, IRS->pos, ix);
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
