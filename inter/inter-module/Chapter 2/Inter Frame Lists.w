[Inter::Lists::] Inter Frame Lists.

To store doubly-linked lists of inter frames.

@

=
typedef struct inter_frame_list {
	int storage_used;
	int storage_capacity;
	struct inter_frame_list_entry *spare_storage;
	struct inter_frame_list_entry *first_in_ifl;
	struct inter_frame_list_entry *last_in_ifl;
	MEMORY_MANAGEMENT
} inter_frame_list;

typedef struct inter_frame_list_entry {
	struct inter_tree_node *listed_frame;
	struct inter_frame_list_entry *next_in_ifl;
	struct inter_frame_list_entry *prev_in_ifl;
	MEMORY_MANAGEMENT
} inter_frame_list_entry;

@

@d LOOP_THROUGH_INTER_FRAME_LIST(F, ifl)
	for (inter_frame_list_entry *F##_entry = (ifl)?(ifl->first_in_ifl):NULL; F##_entry; F##_entry = F##_entry->next_in_ifl)
		if (((F = F##_entry->listed_frame), F))

=
inter_frame_list *Inter::Lists::new(void) {
	inter_frame_list *ifl = CREATE(inter_frame_list);
	ifl->spare_storage = NULL;
	ifl->storage_used = 0;
	ifl->storage_capacity = 0;
	ifl->first_in_ifl = NULL;
	ifl->last_in_ifl = NULL;
	return ifl;
}

void Inter::Lists::add(inter_frame_list *FL, inter_tree_node *F) {
	if (F == NULL) internal_error("linked imvalid frame");
	if (FL == NULL) internal_error("bad frame list");
	if (FL->storage_used >= FL->storage_capacity) {
		int new_size = 128;
		while (new_size < 2*FL->storage_capacity) new_size = 2*new_size;

		inter_frame_list_entry *storage = (inter_frame_list_entry *) Memory::I7_calloc(new_size, sizeof(inter_frame_list_entry), INTER_LINKS_MREASON);
		FL->spare_storage = storage;
		FL->storage_used = 0;
		FL->storage_capacity = new_size;
	}

	inter_frame_list_entry *entry = &(FL->spare_storage[FL->storage_used ++]);
	entry->listed_frame = F;
	entry->next_in_ifl = NULL;
	entry->prev_in_ifl = FL->last_in_ifl;
	if (FL->last_in_ifl) FL->last_in_ifl->next_in_ifl = entry;
	FL->last_in_ifl = entry;
	if (FL->first_in_ifl == NULL) FL->first_in_ifl = entry;
}
