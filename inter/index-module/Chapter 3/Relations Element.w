[RelationsElement::] Relations Element.

To write the Relations element (Rl) in the index.

@ A big table of relations.

=
void RelationsElement::render(OUTPUT_STREAM, localisation_dictionary *LD) {
	inter_tree *I = InterpretIndex::get_tree();
	tree_inventory *inv = Synoptic::inv(I);
	TreeLists::sort(inv->relation_nodes, Synoptic::module_order);

	HTML_OPEN("p");
	HTML::begin_plain_html_table(OUT);
	HTML::first_html_column(OUT, 0); WRITE("<i>name</i>");
	HTML::next_html_column(OUT, 0); WRITE("<i>category</i>");
	HTML::next_html_column(OUT, 0); WRITE("<i>relates this...</i>");
	HTML::next_html_column(OUT, 0); WRITE("<i>...to this</i>");
	HTML::end_html_row(OUT);
	for (int i=0; i<TreeLists::len(inv->relation_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(inv->relation_nodes->list[i].node);
		text_stream *name = Metadata::read_optional_textual(pack, I"^name");
		text_stream *type = Metadata::read_optional_textual(pack, I"^description");
		if ((Str::len(type) == 0) || (Str::len(name) == 0)) continue;
		HTML::first_html_column(OUT, 0);
		WRITE("%S", name);
		int at = (int) Metadata::read_optional_numeric(pack, I"^at");
		if (at > 0) Index::link(OUT, at);
		HTML::next_html_column(OUT, 0);
		if (Str::len(type) > 0) WRITE("%S", type); else WRITE("--");
		HTML::next_html_column(OUT, 0);
		text_stream *term0 = Metadata::read_optional_textual(pack, I"^term0");
		if (Str::len(term0) > 0) WRITE("%S", term0); else WRITE("--");
		HTML::next_html_column(OUT, 0);
		text_stream *term1 = Metadata::read_optional_textual(pack, I"^term1");
		if (Str::len(term1) > 0) WRITE("%S", term1); else WRITE("--");
		HTML::end_html_row(OUT);
	}
	HTML::end_html_table(OUT);
	HTML_CLOSE("p");
}
