[InterNodeList::] Inter Node Lists.

Utility functions to store lists of nodes, either as linked lists or flexibly-sized
arrays.

@h Unsortable lists.
Well, these are short and sweet. An //inter_node_list// is just an efficiently
stored linked list of //inter_tree_node//s.

=
typedef struct inter_node_list {
	struct linked_list *the_nodes; /* of |inter_tree_node| */
	CLASS_DEFINITION
} inter_node_list;

inter_node_list *InterNodeList::new(void) {
	inter_node_list *ifl = CREATE(inter_node_list);
	ifl->the_nodes = NULL;
	return ifl;
}

void InterNodeList::add(inter_node_list *FL, inter_tree_node *F) {
	if (F == NULL) internal_error("linked invalid node");
	if (FL == NULL) internal_error("bad node list");
	if (FL->the_nodes == NULL) FL->the_nodes = NEW_LINKED_LIST(inter_tree_node);
	ADD_TO_LINKED_LIST(F, inter_tree_node, FL->the_nodes);
}

@ We can do two things with these: test them for emptiness, and loop through
them. And that's it.

@d LOOP_THROUGH_INTER_NODE_LIST(F, ifl)
	if ((ifl) && (ifl->the_nodes))
		LOOP_OVER_LINKED_LIST(F, inter_tree_node, ifl->the_nodes)

=
int InterNodeList::empty(inter_node_list *FL) {
	if (FL == NULL) return TRUE;
	if (LinkedLists::len(FL->the_nodes) == 0) return TRUE;
	return FALSE;
}

@h Sortable lists.
Unlike an //inter_node_list//, an //inter_node_array// has entries which are
accessible in O(1) time, and can easily be sorted; but it takes more memory.

=
typedef struct inter_node_array {
	int list_extent;
	int list_used;
	struct ina_entry *list;
	CLASS_DEFINITION
} inter_node_array;

typedef struct ina_entry {
	int sort_key;
	struct inter_tree_node *node;
} ina_entry;

@ =
inter_node_array *InterNodeList::new_array(void) {
	inter_node_array *NL = CREATE(inter_node_array);
	NL->list_extent = 0;
	NL->list_used = 0;
	NL->list = NULL;
	return NL;
}

int InterNodeList::array_len(inter_node_array *NL) {
	if (NL == NULL) internal_error("null inter_node_array");
	return NL->list_used;
}

@ These are expected to be fairly large, so the capacity starts out at 128 and
quadruples each time this is exhausted:

=
void InterNodeList::array_add(inter_node_array *NL, inter_tree_node *P) {
	if (NL == NULL) internal_error("null inter_node_array");
	if (NL->list_extent == 0) {
		NL->list_extent = 256;
		NL->list = (ina_entry *)
			(Memory::calloc(NL->list_extent, sizeof(ina_entry), TREE_LIST_MREASON));
	}
	if (NL->list_used >= NL->list_extent) {
		int old_extent = NL->list_extent;
		NL->list_extent *= 4;
		ina_entry *new_list = (ina_entry *)
			(Memory::calloc(NL->list_extent, sizeof(ina_entry), TREE_LIST_MREASON));
		for (int i=0; i<NL->list_used; i++)
			new_list[i] = NL->list[i];
		Memory::I7_free(NL->list, TREE_LIST_MREASON, old_extent);
		NL->list = new_list;
	}
	NL->list[NL->list_used].sort_key = NL->list_used;
	NL->list[NL->list_used++].node = P;
}

@ Note that this defers to the sorting method supplied in |cmp|; that might
choose to use the |sort_key| value, or might not. |sort_key| is initialised to
be the original position in the array, because that can then be used as a last
resort to ensure that the sorting algorithm is stable; most implementations
of |qsort| in the C standard library are variations on quicksort and are unstable.

=
void InterNodeList::array_sort(inter_node_array *NL,
	int (*cmp)(const void *, const void *)) {
	if (NL == NULL) internal_error("null inter_node_array");
	if (NL->list_used > 0)
		qsort(NL->list, (size_t) NL->list_used, sizeof(ina_entry), cmp);
}
