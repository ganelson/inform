[Architect::] Codename Architect.

The "architect" style of navigational gadgets.

@h Creation.
Architect doesn't have volume or chapter titles as such, since the banner
heading includes these anyway.

=
navigation_design *Architect::create(void) {
	navigation_design *ND = Gadgets::new(I"architect", FALSE, FALSE);
	ND->columnar = TRUE;
	ND->contents_body_class = I"paper architectpapertint";
	METHOD_ADD(ND, RENDER_SECTION_TITLE_MTID, Architect::architect_section_title);
	METHOD_ADD(ND, RENDER_INDEX_TOP_MTID, Architect::architect_navigation_index_top);
	METHOD_ADD(ND, RENDER_NAV_MIDDLE_MTID, Architect::architect_navigation_middle);
	METHOD_ADD(ND, RENDER_NAV_BOTTOM_MTID, Architect::architect_navigation_bottom);
	METHOD_ADD(ND, RENDER_CONTENTS_MTID, Architect::architect_navigation_contents_files);
	METHOD_ADD(ND, RENDER_CONTENTS_HEADING_MTID, Architect::architect_navigation_contents_heading);
	return ND;
}

@h Top.
At the front end of a section, before any of its text.

=
void Architect::architect_section_title(navigation_design *self, text_stream *OUT, volume *V, chapter *C, section *S) {
	if (S->begins_which_chapter == NULL) {
		TEMPORARY_TEXT(comment);
		WRITE_TO(comment, "START IGNORE %d", S->number_within_volume);
		HTML::comment(OUT, comment);
		DISCARD_TEXT(comment);
	}
	HTML::begin_div_with_class_S(OUT, I"bookheader");
	text_stream *linkleft = NULL;
	text_stream *linkright = NULL;
	@<Work out URLs for the preceding and following sections@>;
	TEMPORARY_TEXT(leaf);
	WRITE_TO(leaf, "%S.html", indoc_settings->contents_leafname);
	Architect::architect_banner(OUT,
		S->in_which_chapter->chapter_full_title, V, leaf, linkleft, linkright);
	HTML::end_div(OUT);
	if (S->begins_which_chapter == NULL) HTML::comment(OUT, I"END IGNORE");

	HTML_OPEN_WITH("p", "class=\"sectionheading\"");
	if (Str::len(S->section_anchor) > 0) HTML::anchor(OUT, S->section_anchor);
	WRITE("%c%S", SECTION_SYMBOL, S->title);
	HTML_CLOSE("p");
}

@<Work out URLs for the preceding and following sections@> =
	if (S->previous_section) linkleft = S->previous_section->section_URL;
	if (S->next_section) linkright = S->next_section->section_URL;

@h Index top.
And this is a variant for index pages, such as the index of examples.

=
void Architect::architect_navigation_index_top(navigation_design *self, text_stream *OUT, text_stream *filename, text_stream *title) {
	Architect::architect_banner(OUT, title, 0, NULL, NULL, NULL);
}

@h Middle.
At the middle part, when the text is over, but before any example cues.

=
void Architect::architect_navigation_middle(navigation_design *self, text_stream *OUT, volume *V, section *S) {
	HTMLUtilities::ruled_line(OUT);
}

@h Bottom.
At the end of the section, after any example cues and perhaps also example
bodied. (In a section with no examples, this immediately follows the middle.)

=
void Architect::architect_navigation_bottom(navigation_design *self, text_stream *OUT, volume *V, section *S) {
	HTML::begin_div_with_class_S(OUT, I"bookfooter");
	HTML_OPEN_WITH("table", "class=\"fullwidth\"");
	HTML_OPEN("tr");
	HTML_OPEN_WITH("td", "class=\"footerprevious\"");
	if (S->previous_section)
		HTMLUtilities::general_link(OUT, I"footerlink", S->previous_section->section_URL, I"Previous");
	HTML_CLOSE("td");
	HTML_OPEN_WITH("td", "class=\"footercontents\"");
	TEMPORARY_TEXT(url);
	WRITE_TO(url, "%S.html", indoc_settings->contents_leafname);
	HTMLUtilities::general_link(OUT, I"footerlink", url, I"Contents");
	DISCARD_TEXT(url);
	HTML_CLOSE("td");
	HTML_OPEN_WITH("td", "class=\"footernext\"");
	if (S->next_section)
		HTMLUtilities::general_link(OUT, I"footerlink", S->next_section->section_URL, I"Next");
	else {
		HTML_OPEN_WITH("span", "class=\"footernonlink\"");
		WRITE("End");
		HTML_CLOSE("span");
	}
	HTML_CLOSE("td");
	HTML_CLOSE("tr");
	HTML_CLOSE("table");
	HTML::end_div(OUT);
}

@h Banners.
These are the black, status-line-like banners with navigation icons at the
top of every Architect page.

=
void Architect::architect_banner(text_stream *OUT, text_stream *title, volume *V,
	text_stream *linkcentre, text_stream *linkleft, text_stream *linkright) {
	HTML_OPEN_WITH("table", "class=\"fullwidth midnightblack\"");
	HTML_OPEN("tr");
	HTML_OPEN_WITH("td", "class=\"midnightbannerleftcell\"");
	if (Str::len(linkleft) > 0) {
		TEMPORARY_TEXT(img);
		HTMLUtilities::image_with_id(img, I"Hookleft.png", I"hookleft");
		HTMLUtilities::general_link(OUT, I"standardlink", linkleft, img);
		DISCARD_TEXT(img);
	}
	HTML_CLOSE("td");
	HTML_OPEN_WITH("td", "class=\"midnightbannercentrecell\"");
	if (Str::len(linkcentre) > 0) {
		TEMPORARY_TEXT(url);
		WRITE_TO(url, "%S.html", indoc_settings->contents_leafname);
		HTML::begin_link_with_class(OUT, I"standardlink", url);
		DISCARD_TEXT(url);
	}
	HTML_OPEN_WITH("span", "class=\"midnightbannertext\"");
	WRITE("%S", title);
	HTML_CLOSE("span");
	if (Str::len(linkcentre) > 0)
		HTML::end_link(OUT);
	HTML_CLOSE("td");
	HTML_OPEN_WITH("td", "class=\"midnightbannerrightcell\"");
	TEMPORARY_TEXT(url);
	TEMPORARY_TEXT(img);
	WRITE_TO(url, "%S.html", indoc_settings->contents_leafname);
	HTMLUtilities::image_with_id(img, I"Hookup.png", I"hookup");
	HTMLUtilities::general_link(OUT, I"standardlink", url, img);
	DISCARD_TEXT(img);
	DISCARD_TEXT(url);
	if (Str::len(linkright) > 0) {
		TEMPORARY_TEXT(img);
		HTMLUtilities::image_with_id(img, I"Hookright.png", I"hookright");
		HTMLUtilities::general_link(OUT, I"standardlink", linkright, img);
		DISCARD_TEXT(img);
	}
	HTML_CLOSE("td");
	HTML_CLOSE("tr");
	HTML_CLOSE("table");
}

@ And this is a similar design motif used in Architect contents pages: see below.

=
void Architect::architect_contents_column_banner(OUTPUT_STREAM,
	text_stream *title, volume *V, text_stream *extra) {
	HTML_OPEN_WITH("table", "class=\"fullwidth midnightblack\"");
	HTML_OPEN("tr");
	HTML_OPEN_WITH("td", "class=\"midnightbannerleftcell\"");
	WRITE("%S", extra);
	HTML_CLOSE("td");
	HTML_OPEN_WITH("td", "class=\"midnightbannercentrecell\"");
	HTML_OPEN_WITH("span", "class=\"midnightbannertext\"");
	WRITE("%S", title);
	HTML_CLOSE("span");
	HTML_CLOSE("td");
	HTML_CLOSE("tr");
	HTML_CLOSE("table");
}

@h Contents page.
Architect provides a contents page of its very own.

=
void Architect::architect_navigation_contents_files(navigation_design *self) {
	Midnight::write_contents_page(self, volumes[0]);
}

void Architect::architect_navigation_contents_heading(navigation_design *self, text_stream *OUT, volume *V) {
	WRITE("\n\n");
	HTML_OPEN_WITH("table", "cellspacing=\"3\" border=\"0\" width=\"100%%\"");
	HTML_OPEN("tr");
	HTML_OPEN_WITH("td", "style=\"width:80px; height:120px;\"");
	HTML_TAG_WITH("img", "src=\"inform:/doc_images/wwi_cover@2x.png\" class=\"thinbordered\" style=\"width:80px; height:120px;\"");
	HTML_CLOSE("td");
	HTML_OPEN_WITH("td", "style=\"width:80px; height:120px;\"");
	HTML_TAG_WITH("img", "src=\"inform:/doc_images/irb_cover@2x.png\" class=\"thinbordered\" style=\"width:80px; height:120px;\"");
	HTML_CLOSE("td");
	HTML_OPEN_WITH("td", "style=\"width:100%%;\"");
	HTML_OPEN_WITH("div", "class=\"headingboxhigh\"");
	HTML_OPEN_WITH("div", "class=\"headingtext\"");
	WRITE("Documentation");
	HTML_CLOSE("div");
	HTML_OPEN_WITH("div", "class=\"headingrubric\"");
	WRITE("Two complete books about Inform:");
	HTML_OPEN("br");
	WRITE("<i>Writing with Inform</i>, a comprehensive introduction");
	HTML_OPEN("br");
	WRITE("<i>The Inform Recipe Book</i>, practical solutions for authors to use");
	HTML_CLOSE("div");
	HTML_CLOSE("div");
	HTML_CLOSE("td");
	HTML_CLOSE("tr");
	HTML_CLOSE("table");
	HTML_OPEN_WITH("table", "class=\"fullwidtharch\"");
	HTML_OPEN("tr");
}
