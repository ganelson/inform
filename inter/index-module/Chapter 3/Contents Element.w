[ContentsElement::] Contents Element.

To write the Contents element (C) in the index.

@h The index.

=
void ContentsElement::render(OUTPUT_STREAM, localisation_dictionary *LD) {
	inter_tree *I = InterpretIndex::get_tree();
	tree_inventory *inv = Synoptic::inv(I);
	TreeLists::sort(inv->extension_nodes, Synoptic::category_order);
	TreeLists::sort(inv->heading_nodes, Synoptic::module_order);

	HTML_OPEN("p");
	WRITE("<b>");
	inter_package *pack = Inter::Packages::by_url(I, I"/main/completion/bibliographic");
	text_stream *title = Metadata::read_optional_textual(pack, I"^title");
	text_stream *author = Metadata::read_optional_textual(pack, I"^author");
	if ((Str::len(title) > 0) || (Str::len(author) > 0)) {
		WRITE("%S by %S", title, author);
	}	
	WRITE("</b>");
	HTML_CLOSE("p");
	HTML_OPEN("p");
	WRITE("CONTENTS");
	HTML_CLOSE("p");

	@<Index the headings@>;
	@<Index the extensions@>;
}

@<Index the headings@> =
	int min_positive_level = 10;
	for (int i=0; i<TreeLists::len(inv->heading_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(inv->heading_nodes->list[i].node);
		if (Metadata::read_numeric(pack, I"^indexable") == 0) continue;
		int L = (int) Metadata::read_numeric(pack, I"^level");
		if ((L > 0) && (L < min_positive_level)) min_positive_level = L;
	}

	for (int i=0; i<TreeLists::len(inv->heading_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(inv->heading_nodes->list[i].node);
		if (Metadata::read_numeric(pack, I"^indexable") == 0) continue;
		@<Index this entry in the contents@>;
	}

	if (TreeLists::len(inv->heading_nodes) == 1) {
		HTML_OPEN("p"); WRITE("(This would look more like a contents page if the source text "
			"were divided up into headings.");
		IndexUtilities::DocReferences::link(OUT, I"HEADINGS");
		WRITE(")");
		HTML_CLOSE("p");
		WRITE("\n");
	}

@<Index this entry in the contents@> =
	int L = (int) Metadata::read_numeric(pack, I"^level");
	/* indent to correct tab position */
	HTML_OPEN_WITH("ul", "class=\"leaders\""); WRITE("\n");
	int ind_used = (int) Metadata::read_numeric(pack, I"^indentation");
	if (L == 0) ind_used = 1;
	HTML_OPEN_WITH("li", "class=\"leaded indent%d\"", ind_used);
	HTML_OPEN("span");
	WRITE("%S", Metadata::read_textual(pack, I"^text"));
	HTML_CLOSE("span");
	HTML_OPEN("span");
	if (L > min_positive_level) HTML::begin_colour(OUT, I"808080");
	WRITE("%d words", Metadata::read_numeric(pack, I"^word_count"));
	if (L > min_positive_level) HTML::end_colour(OUT);
	/* place a link to the relevant line of the primary source text */
	IndexUtilities::link_package(OUT, pack);
	HTML_CLOSE("span");
	HTML_CLOSE("li");
	HTML_CLOSE("ul");
	WRITE("\n");
	text_stream *summary = Metadata::read_optional_textual(pack, I"^summary");
	if (Str::len(summary) > 0) {
		HTML::open_indented_p(OUT, ind_used+1, "hanging");
		HTML::begin_colour(OUT, I"808080");
		WRITE("<i>%S</i>", summary);
		HTML::end_colour(OUT);
		HTML_CLOSE("p");
	}

@h Indexing extensions in the Contents index.
The routine below places a list of extensions used in the Contents index,
giving only minimal entries about them.

=
@<Index the extensions@> =
	HTML_OPEN("p"); WRITE("EXTENSIONS"); HTML_CLOSE("p");
	ContentsElement::index_extensions_included_by(OUT, inv, NULL, FALSE);
	for (int i=0; i<TreeLists::len(inv->extension_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(inv->extension_nodes->list[i].node);
		inter_symbol *by_id = Metadata::read_optional_symbol(pack, I"^included_by");
		if (by_id) ContentsElement::index_extensions_included_by(OUT, inv, by_id, NOT_APPLICABLE);
	}
	ContentsElement::index_extensions_included_by(OUT, inv, NULL, TRUE);

@

=
void ContentsElement::index_extensions_included_by(OUTPUT_STREAM, tree_inventory *inv,
	inter_symbol *owner_id, int auto_included) {
	int show_head = TRUE;
	for (int i=0; i<TreeLists::len(inv->extension_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(inv->extension_nodes->list[i].node);
		inter_symbol *by_id = Metadata::read_optional_symbol(pack, I"^included_by");
		if (by_id == owner_id) {
			if ((auto_included != NOT_APPLICABLE) &&
				((int) Metadata::read_optional_numeric(pack, I"^auto_included") != auto_included))
				continue;
			if (show_head) {
				HTML::open_indented_p(OUT, 2, "hanging");
				HTML::begin_colour(OUT, I"808080");
				WRITE("Included ");
				if (auto_included == TRUE) WRITE("automatically by Inform");
				else if (auto_included == FALSE) WRITE("from the source text");
				else {
					inter_package *owner_pack = Inter::Packages::container(owner_id->definition);
					WRITE("by the extension %S", Metadata::read_optional_textual(owner_pack, I"^title"));
				}
				HTML::end_colour(OUT);
				HTML_CLOSE("p");
				show_head = FALSE;
			}
			@<Index this extension@>;
		}
	}
}

@<Index this extension@> =
	inter_symbol *by_id = Metadata::read_optional_symbol(pack, I"^included_by");
	HTML_OPEN_WITH("ul", "class=\"leaders\"");
	HTML_OPEN_WITH("li", "class=\"leaded indent2\"");
	HTML_OPEN("span");
	WRITE("%S ", Metadata::read_textual(pack, I"^title"));
	if (Metadata::read_optional_numeric(pack, I"^standard") == 0) {
		IndexUtilities::link_package(OUT, pack); WRITE("&nbsp;&nbsp;");
	}

	if (auto_included != TRUE) WRITE("by %S ", Metadata::read_textual(pack, I"^author"));
	text_stream *v = Metadata::read_textual(pack, I"^version");
	if (Str::len(v) > 0) {
		HTML_OPEN_WITH("span", "class=\"smaller\"");
		WRITE("version %S ", v);
		HTML_CLOSE("span");
	}
	text_stream *ec = Metadata::read_optional_textual(pack, I"^extra_credit");
	if (Str::len(ec) > 0) {
		HTML_OPEN_WITH("span", "class=\"smaller\"");
		WRITE("(%S) ", ec);
		HTML_CLOSE("span");
	}
	HTML_CLOSE("span");
	HTML_OPEN("span");
	WRITE("%d words", (int) Metadata::read_numeric(pack, I"^word_count"));
	if (by_id == NULL) {
		int at = (int) Metadata::read_optional_numeric(pack, I"^included_at");
		if (at > 0) IndexUtilities::link(OUT, at);
	}
	HTML_CLOSE("span");
	HTML_CLOSE("li");
	HTML_CLOSE("ul");
	WRITE("\n");
