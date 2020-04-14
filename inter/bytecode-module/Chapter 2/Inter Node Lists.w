[Inter::Lists::] Inter Node Lists.

To store doubly-linked lists of inter frames.

@

=
typedef struct inter_node_list {
	int storage_used;
	int storage_capacity;
	struct inter_node_list_entry *spare_storage;
	struct inter_node_list_entry *first_in_inl;
	struct inter_node_list_entry *last_in_inl;
	MEMORY_MANAGEMENT
} inter_node_list;

typedef struct inter_node_list_entry {
	struct inter_tree_node *listed_node;
	struct inter_node_list_entry *next_in_inl;
	struct inter_node_list_entry *prev_in_inl;
	MEMORY_MANAGEMENT
} inter_node_list_entry;

@

@d LOOP_THROUGH_INTER_NODE_LIST(F, ifl)
	for (inter_node_list_entry *F##_entry = (ifl)?(ifl->first_in_inl):NULL; F##_entry; F##_entry = F##_entry->next_in_inl)
		if (((F = F##_entry->listed_node), F))

=
inter_node_list *Inter::Lists::new(void) {
	inter_node_list *ifl = CREATE(inter_node_list);
	ifl->spare_storage = NULL;
	ifl->storage_used = 0;
	ifl->storage_capacity = 0;
	ifl->first_in_inl = NULL;
	ifl->last_in_inl = NULL;
	return ifl;
}

void Inter::Lists::add(inter_node_list *FL, inter_tree_node *F) {
	if (F == NULL) internal_error("linked imvalid frame");
	if (FL == NULL) internal_error("bad frame list");
	if (FL->storage_used >= FL->storage_capacity) {
		int new_size = 128;
		while (new_size < 2*FL->storage_capacity) new_size = 2*new_size;
		inter_node_list_entry *storage = (inter_node_list_entry *) Memory::I7_calloc(new_size, sizeof(inter_node_list_entry), INTER_LINKS_MREASON);
		FL->spare_storage = storage;
		FL->storage_used = 0;
		FL->storage_capacity = new_size;
	}

	inter_node_list_entry *entry = &(FL->spare_storage[FL->storage_used ++]);
	entry->listed_node = F;
	entry->next_in_inl = NULL;
	entry->prev_in_inl = FL->last_in_inl;
	if (FL->last_in_inl) FL->last_in_inl->next_in_inl = entry;
	FL->last_in_inl = entry;
	if (FL->first_in_inl == NULL) FL->first_in_inl = entry;
}
