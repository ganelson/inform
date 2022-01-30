[AlphabeticElement::] Alphabetic Element.

To write the Alphabetic actions element (A2) in the index.

@ This element is a simple three-column table.

=
void AlphabeticElement::render(OUTPUT_STREAM, index_session *session) {
	localisation_dictionary *LD = Indexing::get_localisation(session);
	tree_inventory *inv = Indexing::get_inventory(session);
	TreeLists::sort(inv->action_nodes, AlphabeticElement::alphabetical_order);

	HTML::begin_html_table(OUT, NULL, FALSE, 0, 0, 0, 0, 0);
	HTML::first_html_column(OUT, 0);
	AlphabeticElement::column(OUT, I"ActionColumn", LD);
	HTML::next_html_column(OUT, 0);
	AlphabeticElement::column(OUT, I"NounColumn", LD);
	HTML::next_html_column(OUT, 0);
	AlphabeticElement::column(OUT, I"SecondColumn", LD);
	HTML::end_html_row(OUT);
	inter_package *an_pack;
	LOOP_OVER_INVENTORY_PACKAGES(an_pack, i, inv->action_nodes) {
		inter_ti oow = Metadata::read_optional_numeric(an_pack, I"^out_of_world");
		inter_ti requires_light = Metadata::read_numeric(an_pack, I"^requires_light");
		inter_ti can_have_noun = Metadata::read_numeric(an_pack, I"^can_have_noun");
		inter_ti can_have_second = Metadata::read_numeric(an_pack, I"^can_have_second");
		inter_ti noun_access = Metadata::read_numeric(an_pack, I"^noun_access");
		inter_ti second_access = Metadata::read_numeric(an_pack, I"^second_access");
		inter_symbol *noun_kind = Metadata::read_symbol(an_pack, I"^noun_kind");
		inter_symbol *second_kind = Metadata::read_symbol(an_pack, I"^second_kind");

		HTML::first_html_column(OUT, 0);
		@<Action column@>;
		HTML::next_html_column(OUT, 0);
		@<Noun column@>;
		HTML::next_html_column(OUT, 0);
		@<Second noun column@>;
		HTML::end_html_row(OUT);
	}
	HTML::end_html_table(OUT);
}

@<Action column@> =
	if (oow) HTML::begin_colour(OUT, I"800000");
	WRITE("%S", Metadata::read_optional_textual(an_pack, I"^name"));
	if (oow) HTML::end_colour(OUT);
	IndexUtilities::detail_link(OUT, "A", i, TRUE);
	if (requires_light) AlphabeticElement::note(OUT, I"Light", LD);

@<Noun column@> =
	if (can_have_noun == 0) {
		WRITE("&mdash;");
	} else {
		if (noun_access == REQUIRES_ACCESS) AlphabeticElement::note(OUT, I"Touchable", LD);
		if (noun_access == REQUIRES_POSSESSION) AlphabeticElement::note(OUT, I"Carried", LD);
		WRITE("<b>");
		IndexUtilities::kind_name(OUT, InterPackage::container(noun_kind->definition), FALSE, FALSE);
		WRITE("</b>");
	}

@<Second noun column@> =
	if (can_have_second == 0) {
		WRITE("&mdash;");
	} else {
		if (second_access == REQUIRES_ACCESS) AlphabeticElement::note(OUT, I"Touchable", LD);
		if (second_access == REQUIRES_POSSESSION) AlphabeticElement::note(OUT, I"Carried", LD);
		WRITE("<b>");
		IndexUtilities::kind_name(OUT, InterPackage::container(second_kind->definition), FALSE, FALSE);
		WRITE("</b>");
	}

@ =
void AlphabeticElement::column(OUTPUT_STREAM, text_stream *key, localisation_dictionary *LD) {
	TEMPORARY_TEXT(full)
	WRITE_TO(full, "Index.Elements.A2.%S", key);
	Localisation::bold(OUT, LD, full);
	DISCARD_TEXT(full)
}

@ =
void AlphabeticElement::note(OUTPUT_STREAM, text_stream *key, localisation_dictionary *LD) {
	TEMPORARY_TEXT(full)
	WRITE_TO(full, "Index.Elements.A2.%S", key);
	Localisation::italic(OUT, LD, full);
	DISCARD_TEXT(full)
}

@ This comparison function sorts actions in alphabetical order of name; by
default the inventory would have them in declaration order.

=
int AlphabeticElement::alphabetical_order(const void *ent1, const void *ent2) {
	itl_entry *E1 = (itl_entry *) ent1;
	itl_entry *E2 = (itl_entry *) ent2;
	if (E1 == E2) return 0;
	inter_tree_node *P1 = E1->node;
	inter_tree_node *P2 = E2->node;
	inter_package *an1_pack = InterPackage::at_this_head(P1);
	inter_package *an2_pack = InterPackage::at_this_head(P2);
	text_stream *an1_name = Metadata::read_optional_textual(an1_pack, I"^name");
	text_stream *an2_name = Metadata::read_optional_textual(an2_pack, I"^name");
	return Str::cmp(an1_name, an2_name);
}
