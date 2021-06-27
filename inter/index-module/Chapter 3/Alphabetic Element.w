[AlphabeticElement::] Alphabetic Element.

To write the Alphabetic actions element (A2) in the index.

@ =
void AlphabeticElement::render(OUTPUT_STREAM) {
	inter_tree *I = Index::get_tree();
	tree_inventory *inv = Synoptic::inv(I);
	TreeLists::sort(inv->action_nodes, AlphabeticElement::alphabetical_order);

	HTML::begin_html_table(OUT, NULL, FALSE, 0, 0, 0, 0, 0);
	HTML::first_html_column(OUT, 0);
	WRITE("<b>action</b>");
	HTML::next_html_column(OUT, 0);
	WRITE("<b>noun</b>");
	HTML::next_html_column(OUT, 0);
	WRITE("<b>second noun</b>");
	HTML::end_html_row(OUT);
	for (int i=0; i<TreeLists::len(inv->action_nodes); i++) {
		inter_package *an_pack = Inter::Package::defined_by_frame(inv->action_nodes->list[i].node);
		HTML::first_html_column(OUT, 0);
		inter_ti oow = Metadata::read_optional_numeric(an_pack, I"^out_of_world");
		inter_ti requires_light = Metadata::read_numeric(an_pack, I"^requires_light");
		inter_ti can_have_noun = Metadata::read_numeric(an_pack, I"^can_have_noun");
		inter_ti can_have_second = Metadata::read_numeric(an_pack, I"^can_have_second");
		inter_ti noun_access = Metadata::read_numeric(an_pack, I"^noun_access");
		inter_ti second_access = Metadata::read_numeric(an_pack, I"^second_access");
		inter_symbol *noun_kind = Metadata::read_symbol(an_pack, I"^noun_kind");
		inter_symbol *second_kind = Metadata::read_symbol(an_pack, I"^second_kind");
		if (oow) HTML::begin_colour(OUT, I"800000");
		WRITE("%S", Metadata::read_optional_textual(an_pack, I"^name"));
		if (oow) HTML::end_colour(OUT);
		Index::detail_link(OUT, "A", i, TRUE);

		if (requires_light) WRITE(" <i>requires light</i>");

		HTML::next_html_column(OUT, 0);
		if (can_have_noun == 0) {
			WRITE("&mdash;");
		} else {
			if (noun_access == REQUIRES_ACCESS) WRITE("<i>touchable</i> ");
			if (noun_access == REQUIRES_POSSESSION) WRITE("<i>carried</i> ");
			WRITE("<b>");
			ChartElement::index_kind(OUT, Inter::Packages::container(noun_kind->definition), FALSE, FALSE);
			WRITE("</b>");
		}

		HTML::next_html_column(OUT, 0);
		if (can_have_second == 0) {
			WRITE("&mdash;");
		} else {
			if (second_access == REQUIRES_ACCESS) WRITE("<i>touchable</i> ");
			if (second_access == REQUIRES_POSSESSION) WRITE("<i>carried</i> ");
			WRITE("<b>");
			ChartElement::index_kind(OUT, Inter::Packages::container(second_kind->definition), FALSE, FALSE);
			WRITE("</b>");
		}
		HTML::end_html_row(OUT);
	}
	HTML::end_html_table(OUT);
}

int AlphabeticElement::alphabetical_order(const void *ent1, const void *ent2) {
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
