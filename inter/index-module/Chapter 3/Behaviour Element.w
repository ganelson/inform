[BehaviourElement::] Behaviour Element.

To write the Behaviour element (Bh) in the index.

@ This simply itemises kinds of action, and what defines them.

=
void BehaviourElement::render(OUTPUT_STREAM, index_session *session) {
	localisation_dictionary *LD = Indexing::get_localisation(session);
	inter_tree *I = Indexing::get_tree(session);
	tree_inventory *inv = Indexing::get_inventory(session);

	int num_naps = InterNodeList::array_len(inv->named_action_pattern_nodes);

	if (num_naps == 0) {
		HTML_OPEN("p");
		Localisation::roman(OUT, LD, I"Index.Elements.Bh.None");
		HTML_CLOSE("p");
	} else {
		InterNodeList::array_sort(inv->named_action_pattern_nodes, MakeSynopticModuleStage::module_order);
		inter_package *pack;
		LOOP_OVER_INVENTORY_PACKAGES(pack, i, inv->named_action_pattern_nodes) {
			text_stream *name = Metadata::read_optional_textual(pack, I"^name");
			HTML_OPEN("p"); WRITE("<b>%S</b>", name);
			IndexUtilities::link_package(OUT, pack);
			HTML_TAG("br");
			WRITE("&nbsp;&nbsp;");
			Localisation::italic(OUT, LD, I"Index.Elements.Bh.Defined");
			inter_tree_node *D = InterPackage::head(pack);
			LOOP_THROUGH_INTER_CHILDREN(C, D) {
				if (C->W.instruction[ID_IFLD] == PACKAGE_IST) {
					inter_package *entry = InterPackage::at_this_head(C);
					if (InterPackage::type(entry) ==
						LargeScale::package_type(I, I"_named_action_pattern_entry")) {
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
