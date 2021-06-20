[GroupedElement::] Grouped Element.

To write the Grouped actions element (A1) in the index.

@ =
void GroupedElement::render(OUTPUT_STREAM) {
	inter_tree *I = Index::get_tree();
	tree_inventory *inv = Synoptic::inv(I);
	TreeLists::sort(inv->action_nodes, GroupedElement::grouped_order);

	for (int i=0; i<TreeLists::len(inv->action_nodes); i++) {
		inter_package *an_pack = Inter::Package::defined_by_frame(inv->action_nodes->list[i].node);
		WRITE("<p>%S</p>", Metadata::read_optional_textual(an_pack, I"^name"));
	}
}

int GroupedElement::grouped_order(const void *ent1, const void *ent2) {
	itl_entry *E1 = (itl_entry *) ent1;
	itl_entry *E2 = (itl_entry *) ent2;
	if (E1 == E2) return 0;
	inter_tree_node *P1 = E1->node;
	inter_tree_node *P2 = E2->node;
	inter_package *an1_pack = Inter::Package::defined_by_frame(P1);
	inter_package *an2_pack = Inter::Package::defined_by_frame(P2);
	text_stream *an1_name = Metadata::read_optional_textual(an1_pack, I"^name");
	text_stream *an2_name = Metadata::read_optional_textual(an2_pack, I"^name");
	return Str::cmp(an1_name, an2_name);
}
