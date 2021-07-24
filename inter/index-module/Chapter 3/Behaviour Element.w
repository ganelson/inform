[BehaviourElement::] Behaviour Element.

To write the Behaviour element (Bh) in the index.

@ This simply itemises kinds of action, and what defines them.

=
void BehaviourElement::render(OUTPUT_STREAM, localisation_dictionary *LD) {
	inter_tree *I = InterpretIndex::get_tree();
	tree_inventory *inv = Synoptic::inv(I);

	int num_naps = TreeLists::len(inv->named_action_pattern_nodes);

	if (num_naps == 0) {
		HTML_OPEN("p");
		Localisation::write_0(OUT, LD, I"Index.Elements.Bh.None");
		HTML_CLOSE("p");
	} else {
		TreeLists::sort(inv->named_action_pattern_nodes, Synoptic::module_order);
		inter_package *pack;
		LOOP_OVER_INVENTORY_PACKAGES(pack, i, inv->named_action_pattern_nodes) {
			text_stream *name = Metadata::read_optional_textual(pack, I"^name");
			HTML_OPEN("p"); WRITE("<b>%S</b>", name);
			IndexUtilities::link_package(OUT, pack);
			HTML_TAG("br");
			WRITE("&nbsp;&nbsp;<i>");
			Localisation::write_0(OUT, LD, I"Index.Elements.Bh.Defined");
			WRITE(":</i>\n");
			inter_tree_node *D = Inter::Packages::definition(pack);
			LOOP_THROUGH_INTER_CHILDREN(C, D) {
				if (C->W.data[ID_IFLD] == PACKAGE_IST) {
					inter_package *entry = Inter::Package::defined_by_frame(C);
					if (Inter::Packages::type(entry) ==
						PackageTypes::get(I, I"_named_action_pattern_entry")) {
						text_stream *text = Metadata::read_optional_textual(entry, I"^text");
						HTML_TAG("br");
						WRITE("&nbsp;&nbsp;&nbsp;&nbsp;%S", text);
						IndexUtilities::link_package(OUT, entry);
					}
				}
			}
			HTML_CLOSE("p");
		}
	}
}
