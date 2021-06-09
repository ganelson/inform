[ExtrasElement::] Extras Element.

To write the Extras element (Xt) in the index.

@

=
void ExtrasElement::render(OUTPUT_STREAM) {
	inter_tree *I = Index::get_tree();
	tree_inventory *inv = Synoptic::inv(I);
	TreeLists::sort(inv->rulebook_nodes, Synoptic::module_order);
	TreeLists::sort(inv->activity_nodes, Synoptic::module_order);

	for (int i=0; i<TreeLists::len(inv->module_nodes); i++) {
		inter_package *E = Inter::Package::defined_by_frame(inv->module_nodes->list[i].node);
		if (Metadata::read_optional_numeric(E, I"^category") == 1)
			@<Index rulebooks occurring in this part of the source text@>;
	}
	for (int i=0; i<TreeLists::len(inv->module_nodes); i++) {
		inter_package *E = Inter::Package::defined_by_frame(inv->module_nodes->list[i].node);
		if (Metadata::read_optional_numeric(E, I"^category") == 2)
			@<Index rulebooks occurring in this part of the source text@>;
	}
}

@<Index rulebooks occurring in this part of the source text@> =
	int c = 0;
	for (int j=0; j<TreeLists::len(inv->rulebook_nodes); j++) {
		if (Synoptic::module_containing(inv->rulebook_nodes->list[j].node) == E) {
			inter_package *pack =
				Inter::Package::defined_by_frame(inv->rulebook_nodes->list[j].node);
			if (Metadata::read_optional_numeric(pack, I"^automatically_generated"))
				continue;
			if (c++ == 0) @<Heading for these@>;
			IndexRules::index_rules_box(OUT, inv, 
				Metadata::read_optional_textual(pack, I"^printed_name"),
				NULL, pack, NULL, 1, TRUE);
		}
	}
	for (int j=0; j<TreeLists::len(inv->activity_nodes); j++) {
		if (Synoptic::module_containing(inv->activity_nodes->list[j].node) == E) {
			inter_package *pack =
				Inter::Package::defined_by_frame(inv->activity_nodes->list[j].node);
			if (c++ == 0) @<Heading for these@>;
			IndexRules::index_activity(OUT, I, pack, 1);
		}
	}

@<Heading for these@> =
	HTML_OPEN("p");
	if (Metadata::read_optional_numeric(E, I"^category") == 1) {
		WRITE("<b>From the source text</b>");
	} else {
		WRITE("<b>From the extension %S</b>",
			Metadata::read_optional_textual(E, I"^credit"));
	}
	HTML_CLOSE("p");
