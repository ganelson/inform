[ExtrasElement::] Extras Element.

To write the Extras element (Xt) in the index.

@ This is to sweep up rulebooks and activities not covered by other elements,
really, and most of the code here is just to arrange them in some logical order.

=
void ExtrasElement::render(OUTPUT_STREAM, index_session *session) {
	localisation_dictionary *LD = Indexing::get_localisation(session);
	inter_tree *I = Indexing::get_tree(session);
	tree_inventory *inv = Indexing::get_inventory(session);
	TreeLists::sort(inv->rulebook_nodes, MakeSynopticModuleStage::module_order);
	TreeLists::sort(inv->activity_nodes, MakeSynopticModuleStage::module_order);

	inter_package *E;
	LOOP_OVER_INVENTORY_PACKAGES(E, i, inv->module_nodes)
		if (Metadata::read_optional_numeric(E, I"^category") == 1)
			@<Index rulebooks occurring in this part of the source text@>;
	LOOP_OVER_INVENTORY_PACKAGES(E, i, inv->module_nodes)
		if (Metadata::read_optional_numeric(E, I"^category") == 2)
			@<Index rulebooks occurring in this part of the source text@>;
}

@<Index rulebooks occurring in this part of the source text@> =
	int c = 0;
	inter_package *rb_pack;
	LOOP_OVER_INVENTORY_PACKAGES(rb_pack, i, inv->rulebook_nodes)
		if (MakeSynopticModuleStage::module_containing(rb_pack->package_head) == E) {
			if (Metadata::read_optional_numeric(rb_pack, I"^automatically_generated"))
				continue;
			if (c++ == 0) @<Heading for these@>;
			IndexRules::rulebook_box(OUT, inv, 
				Metadata::read_optional_textual(rb_pack, I"^printed_name"),
				NULL, rb_pack, NULL, 1, TRUE, session);
		}
	inter_package *av_pack;
	LOOP_OVER_INVENTORY_PACKAGES(av_pack, i, inv->activity_nodes)
		if (MakeSynopticModuleStage::module_containing(av_pack->package_head) == E) {
			if (c++ == 0) @<Heading for these@>;
			IndexRules::activity_box(OUT, I, av_pack, 1, session);
		}

@<Heading for these@> =
	HTML_OPEN("p");
	WRITE("<b>");
	if (Metadata::read_optional_numeric(E, I"^category") == 1) {
		Localisation::roman(OUT, LD, I"Index.Elements.Xt.FromSourceText");
	} else {
		Localisation::roman_t(OUT, LD, I"Index.Elements.Xt.FromExtension",
			Metadata::read_optional_textual(E, I"^credit"));
	}
	WRITE("</b>");
	HTML_CLOSE("p");
