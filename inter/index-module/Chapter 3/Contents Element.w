[ContentsElement::] Contents Element.

To write the Contents element (C) in the index.

@ This is a hierarchical contents page.

=
void ContentsElement::render(OUTPUT_STREAM, index_session *session) {
	localisation_dictionary *LD = Indexing::get_localisation(session);
	inter_tree *I = Indexing::get_tree(session);
	tree_inventory *inv = Indexing::get_inventory(session);
	TreeLists::sort(inv->extension_nodes, MakeSynopticModuleStage::category_order);
	TreeLists::sort(inv->heading_nodes, MakeSynopticModuleStage::module_order);

	@<Write a sort of half-title page@>;
	@<Index the headings@>;
	@<Index the extensions@>;
}

@<Write a sort of half-title page@> =
	HTML_OPEN("p");
	WRITE("<b>");
	inter_package *pack = Inter::Packages::by_url(I, I"/main/completion/bibliographic");
	text_stream *title = Metadata::read_optional_textual(pack, I"^title");
	text_stream *author = Metadata::read_optional_textual(pack, I"^author");
	if (Str::len(title) > 0) {
		if (Str::len(author) > 0)
			Localisation::roman_tt(OUT, LD, I"Index.Elements.C.Titling", title, author);
		else
			Localisation::roman_t(OUT, LD, I"Index.Elements.C.AnonymousTitling", title);
	}
	WRITE("</b>");
	HTML_CLOSE("p");

@<Index the headings@> =
	HTML_OPEN("p");
	Localisation::roman(OUT, LD, I"Index.Elements.C.ContentsHeading");
	HTML_CLOSE("p");
	int min_positive_level = 10, entries_written = 0;
	inter_package *heading_pack;
	LOOP_OVER_INVENTORY_PACKAGES(heading_pack, i, inv->heading_nodes)
		if (Metadata::read_numeric(heading_pack, I"^indexable")) {
			int L = (int) Metadata::read_numeric(heading_pack, I"^level");
			if ((L > 0) && (L < min_positive_level)) min_positive_level = L;
		}
	LOOP_OVER_INVENTORY_PACKAGES(heading_pack, i, inv->heading_nodes)
		if (Metadata::read_numeric(heading_pack, I"^indexable")) {
			@<Index this entry in the contents@>;
			entries_written++;
		}

	if (entries_written == 0) {
		HTML_OPEN("p");
		WRITE("(");
		Localisation::roman(OUT, LD, I"Index.Elements.C.NoContents");
		WRITE(")");
		HTML_CLOSE("p");
		WRITE("\n");
	}

@<Index this entry in the contents@> =
	int L = (int) Metadata::read_numeric(heading_pack, I"^level");
	/* indent to correct tab position */
	HTML_OPEN_WITH("ul", "class=\"leaders\""); WRITE("\n");
	int ind_used = (int) Metadata::read_numeric(heading_pack, I"^indentation");
	if (L == 0) ind_used = 1;
	HTML_OPEN_WITH("li", "class=\"leaded indent%d\"", ind_used);
	HTML_OPEN("span");
	WRITE("%S", Metadata::read_textual(heading_pack, I"^text"));
	HTML_CLOSE("span");
	HTML_OPEN("span");
	if (L > min_positive_level) HTML::begin_colour(OUT, I"808080");
	ContentsElement::word_count(OUT, heading_pack, LD);
	if (L > min_positive_level) HTML::end_colour(OUT);
	/* place a link to the relevant line of the primary source text */
	IndexUtilities::link_package(OUT, heading_pack);
	HTML_CLOSE("span");
	HTML_CLOSE("li");
	HTML_CLOSE("ul");
	WRITE("\n");
	text_stream *summary = Metadata::read_optional_textual(heading_pack, I"^summary");
	if (Str::len(summary) > 0) {
		HTML::open_indented_p(OUT, ind_used+1, "hanging");
		HTML::begin_colour(OUT, I"808080");
		WRITE("<i>%S</i>", summary);
		HTML::end_colour(OUT);
		HTML_CLOSE("p");
	}

@<Index the extensions@> =
	HTML_OPEN("p");
	Localisation::roman(OUT, LD, I"Index.Elements.C.ExtensionsHeading");
	HTML_CLOSE("p");
	ContentsElement::index_extensions_included_by(OUT, inv, NULL, FALSE, LD);
	inter_package *ext_pack;
	LOOP_OVER_INVENTORY_PACKAGES(ext_pack, i, inv->extension_nodes) {
		inter_symbol *by_id =
			Metadata::read_optional_symbol(ext_pack, I"^included_by");
		if (by_id) ContentsElement::index_extensions_included_by(OUT, inv, by_id,
			NOT_APPLICABLE, LD);
	}
	ContentsElement::index_extensions_included_by(OUT, inv, NULL, TRUE, LD);

@ This is called recursively to show how extensions have included each other:

=
void ContentsElement::index_extensions_included_by(OUTPUT_STREAM, tree_inventory *inv,
	inter_symbol *owner_id, int auto_included, localisation_dictionary *LD) {
	int show_head = TRUE;
	inter_package *pack;
	LOOP_OVER_INVENTORY_PACKAGES(pack, i, inv->extension_nodes) {
		inter_symbol *by_id = Metadata::read_optional_symbol(pack, I"^included_by");
		if (by_id == owner_id) {
			if ((auto_included != NOT_APPLICABLE) &&
				((int) Metadata::read_optional_numeric(pack, I"^auto_included") != auto_included))
				continue;
			if (show_head) {
				HTML::open_indented_p(OUT, 2, "hanging");
				HTML::begin_colour(OUT, I"808080");
				if (auto_included == TRUE)
					Localisation::roman(OUT, LD, I"Index.Elements.C.IncludedAutomatically");
				else if (auto_included == FALSE)
					Localisation::roman(OUT, LD, I"Index.Elements.C.IncludedFromSource");
				else {
					inter_package *owner_pack = Inter::Packages::container(owner_id->definition);
					Localisation::roman_t(OUT, LD, I"Index.Elements.C.IncludedBy",
						Metadata::read_optional_textual(owner_pack, I"^title"));
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
		Localisation::roman_t(OUT, LD, I"Index.Elements.C.Version", v);
		HTML_CLOSE("span");
		WRITE(" ");
	}
	text_stream *ec = Metadata::read_optional_textual(pack, I"^extra_credit");
	if (Str::len(ec) > 0) {
		HTML_OPEN_WITH("span", "class=\"smaller\"");
		WRITE("(%S) ", ec);
		HTML_CLOSE("span");
	}
	HTML_CLOSE("span");
	HTML_OPEN("span");
	ContentsElement::word_count(OUT, pack, LD);
	if (by_id == NULL) {
		int at = (int) Metadata::read_optional_numeric(pack, I"^included_at");
		if (at > 0) IndexUtilities::link(OUT, at);
	}
	HTML_CLOSE("span");
	HTML_CLOSE("li");
	HTML_CLOSE("ul");
	WRITE("\n");

@ =
void ContentsElement::word_count(OUTPUT_STREAM, inter_package *pack,
	localisation_dictionary *LD) {
	Localisation::roman_i(OUT, LD, I"Index.Elements.C.Words",
		(int) Metadata::read_numeric(pack, I"^word_count"));
}
