[BehaviourElement::] Behaviour Element.

To write the Behavuour element (Bh) in the index.

@ This simply itemises kinds of action, and what defines them.

=
void BehaviourElement::render(OUTPUT_STREAM) {
	inter_tree *I = Index::get_tree();
	tree_inventory *inv = Synoptic::inv(I);

	int num_naps = TreeLists::len(inv->named_action_pattern_nodes);

	if (num_naps == 0) {
		HTML_OPEN("p");
		WRITE("No names for kinds of action have yet been defined.");
		HTML_CLOSE("p");
	} else {
		TreeLists::sort(inv->named_action_pattern_nodes, Synoptic::module_order);
		for (int i=0; i<TreeLists::len(inv->named_action_pattern_nodes); i++) {
			inter_package *pack = Inter::Package::defined_by_frame(inv->named_action_pattern_nodes->list[i].node);
			text_stream *name = Metadata::read_optional_textual(pack, I"^name");
			int at = (int) Metadata::read_optional_numeric(pack, I"^at");
			HTML_OPEN("p"); WRITE("<b>%S</b>", name);
			Index::link(OUT, at);
			HTML_TAG("br");
			WRITE("&nbsp;&nbsp;<i>defined as any of the following acts:</i>\n");
			inter_tree_node *D = Inter::Packages::definition(pack);
			LOOP_THROUGH_INTER_CHILDREN(C, D) {
				if (C->W.data[ID_IFLD] == PACKAGE_IST) {
					inter_package *entry = Inter::Package::defined_by_frame(C);
					if (Inter::Packages::type(entry) == PackageTypes::get(I, I"_named_action_pattern_entry")) {
						text_stream *text = Metadata::read_optional_textual(entry, I"^text");
						int at = (int) Metadata::read_optional_numeric(entry, I"^at");
						HTML_TAG("br");
						WRITE("&nbsp;&nbsp;&nbsp;&nbsp;%S", text);
						Index::link(OUT, at);
					}
				}
			}
			HTML_CLOSE("p");
		}
	}
}

