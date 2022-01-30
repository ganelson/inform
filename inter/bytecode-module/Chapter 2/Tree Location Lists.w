[TreeLists::] Tree Location Lists.

Utility functions for keeping flexible-sized arrays of locations in a tree of
Inter code.

@ Unlike linked lists, these are accessible in O(1) time, and can easily be
sorted by index.

=
typedef struct inter_tree_location_list {
	int list_extent;
	int list_used;
	struct itl_entry *list;
	CLASS_DEFINITION
} inter_tree_location_list;

typedef struct itl_entry {
	int sort_key;
	struct inter_tree_node *node;
} itl_entry;

inter_tree_location_list *TreeLists::new(void) {
	inter_tree_location_list *NL = CREATE(inter_tree_location_list);
	NL->list_extent = 0;
	NL->list_used = 0;
	NL->list = NULL;
	return NL;
}

int TreeLists::len(inter_tree_location_list *NL) {
	if (NL == NULL) internal_error("null inter_tree_location_list");
	return NL->list_used;
}

@ The capacity quadruples each time it is exhausted.

=
void TreeLists::add(inter_tree_location_list *NL, inter_tree_node *P) {
	if (NL == NULL) internal_error("null inter_tree_location_list");
	if (NL->list_extent == 0) {
		NL->list_extent = 256;
		NL->list = (itl_entry *)
			(Memory::calloc(NL->list_extent,
				sizeof(itl_entry), TREE_LIST_MREASON));
	}
	if (NL->list_used >= NL->list_extent) {
		int old_extent = NL->list_extent;
		NL->list_extent *= 4;
		itl_entry *new_list = (itl_entry *)
			(Memory::calloc(NL->list_extent,
				sizeof(itl_entry), TREE_LIST_MREASON));
		for (int i=0; i<NL->list_used; i++)
			new_list[i] = NL->list[i];
		Memory::I7_free(NL->list, TREE_LIST_MREASON, old_extent);
		NL->list = new_list;
	}
	NL->list[NL->list_used].sort_key = NL->list_used;
	NL->list[NL->list_used++].node = P;
}

void TreeLists::sort(inter_tree_location_list *NL, int (*cmp)(const void *, const void *)) {
	if (NL == NULL) internal_error("null inter_tree_location_list");
	if (NL->list_used > 0)
		qsort(NL->list, (size_t) NL->list_used, sizeof(itl_entry), cmp);
}

@ And this macro conveniently loops through packages in a node list of their
definitions:

@d LOOP_OVER_INVENTORY_PACKAGES(pack, i, node_list)
	for (int i=0; i<TreeLists::len(node_list); i++)
		if ((pack = InterPackage::at_this_head(node_list->list[i].node)))
