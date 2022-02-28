[RelationsElement::] Relations Element.

To write the Relations element (Rl) in the index.

@ A four-column table of relations.

=
void RelationsElement::render(OUTPUT_STREAM, index_session *session) {
	localisation_dictionary *LD = Indexing::get_localisation(session);
	tree_inventory *inv = Indexing::get_inventory(session);
	InterNodeList::array_sort(inv->relation_nodes, MakeSynopticModuleStage::module_order);

	HTML_OPEN("p");
	HTML::begin_plain_html_table(OUT);
	HTML::first_html_column(OUT, 0); 
	Localisation::italic(OUT, LD, I"Index.Elements.Rl.NameColumn");
	HTML::next_html_column(OUT, 0);
	Localisation::italic(OUT, LD, I"Index.Elements.Rl.CategoryColumn");
	HTML::next_html_column(OUT, 0);
	Localisation::italic(OUT, LD, I"Index.Elements.Rl.FromColumn");
	HTML::next_html_column(OUT, 0);
	Localisation::italic(OUT, LD, I"Index.Elements.Rl.ToColumn");
	HTML::end_html_row(OUT);
	inter_package *pack;
	LOOP_OVER_INVENTORY_PACKAGES(pack, i, inv->relation_nodes) {
		text_stream *name = Metadata::optional_textual(pack, I"^name");
		text_stream *type = Metadata::optional_textual(pack, I"^description");
		if ((Str::len(type) == 0) || (Str::len(name) == 0)) continue;
		HTML::first_html_column(OUT, 0);
		WRITE("%S", name);
		IndexUtilities::link_package(OUT, pack);
		HTML::next_html_column(OUT, 0);
		if (Str::len(type) > 0) WRITE("%S", type); else WRITE("--");
		HTML::next_html_column(OUT, 0);
		text_stream *term0 = Metadata::optional_textual(pack, I"^term0");
		if (Str::len(term0) > 0) WRITE("%S", term0); else WRITE("--");
		HTML::next_html_column(OUT, 0);
		text_stream *term1 = Metadata::optional_textual(pack, I"^term1");
		if (Str::len(term1) > 0) WRITE("%S", term1); else WRITE("--");
		HTML::end_html_row(OUT);
	}
	HTML::end_html_table(OUT);
	HTML_CLOSE("p");
}
