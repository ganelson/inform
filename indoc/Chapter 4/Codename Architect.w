[Architect::] Codename Architect.

The "architect" style of navigational gadgets.

@h Top.
At the front end of a section, before any of its text.

Architect doesn't have volume or chapter titles as such, since the banner
heading includes these anyway.

=
void Architect::architect_volume_title(OUTPUT_STREAM, volume *V) {
}

void Architect::architect_chapter_title(OUTPUT_STREAM, volume *V, chapter *C) {
}

@ =
void Architect::architect_section_title(OUTPUT_STREAM, volume *V, section *S) {
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
void Architect::architect_navigation_index_top(OUTPUT_STREAM, text_stream *filename, text_stream *title) {
	Architect::architect_banner(OUT, title, 0, NULL, NULL, NULL);
}

@h Middle.
At the middle part, when the text is over, but before any example cues.

=
void Architect::architect_navigation_middle(OUTPUT_STREAM, volume *V, section *S) {
	HTMLUtilities::ruled_line(OUT);
}

@h Example top.
This is reached before the first example is rendered, provided at least
one example will be:

=
void Architect::architect_navigation_example_top(OUTPUT_STREAM, volume *V, section *S) {
}

@h Example bottom.
Any closing ornament at the end of examples? This is reached after the
last example is rendered, provided at least one example has been.

=
void Architect::architect_navigation_example_bottom(OUTPUT_STREAM, volume *V, section *S) {
}

@h Bottom.
At the end of the section, after any example cues and perhaps also example
bodied. (In a section with no examples, this immediately follows the middle.)

=
void Architect::architect_navigation_bottom(OUTPUT_STREAM, volume *V, section *S) {
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
void Architect::architect_banner(OUTPUT_STREAM, text_stream *title, volume *V,
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
void Architect::architect_navigation_contents_files(void) {
	Midnight::write_contents_page(volumes[0]);
}
