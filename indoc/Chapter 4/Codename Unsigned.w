[Unsigned::] Codename Unsigned.

The "unsigned" style of navigational gadgets.

@h Creation.

=
navigation_design *Unsigned::create(void) {
	navigation_design *ND = Nav::new(I"unsigned", TRUE, FALSE);
	METHOD_ADD(ND, RENDER_VOLUME_TITLE_MTID, Unsigned::unsigned_volume_title);
	METHOD_ADD(ND, RENDER_CHAPTER_TITLE_MTID, Unsigned::unsigned_chapter_title);
	METHOD_ADD(ND, RENDER_SECTION_TITLE_MTID, Unsigned::unsigned_section_title);
	METHOD_ADD(ND, RENDER_INDEX_TOP_MTID, Unsigned::unsigned_navigation_index_top);
	METHOD_ADD(ND, RENDER_NAV_MIDDLE_MTID, Unsigned::unsigned_navigation_middle);
	return ND;
}

@h Top.
At the front end of a section, before any of its text.

=
void Unsigned::unsigned_volume_title(navigation_design *self, text_stream *OUT, volume *V) {
	@<Render a volume heading@>;
	@<Render a chapter-contents table@>;
}

@<Render a volume heading@> =
	TEMPORARY_TEXT(partn)
	if (no_volumes > 1) Roadsign::roman_numeral(partn, V->allocation_id);
	HTML_OPEN_WITH("p", "class=\"volumeheading\"");
	WRITE("%S%S", partn, V->vol_title);
	HTML_CLOSE("p");

@<Render a chapter-contents table@> =
	int nch = V->vol_chapter_count;
	for (int rc = 0; rc < nch; rc++) {
		chapter *C = V->chapters[rc];
		HTML_OPEN("p");
		HTML::begin_link_with_class(OUT, I"standardlink", C->chapter_URL);
		HTML_OPEN_WITH("span", "class=\"chapterlisting\"");
		WRITE("%S", C->chapter_full_title);
		HTML_CLOSE("span");
		HTML::end_link(OUT);
		HTML_CLOSE("p");
	}

@ =
void Unsigned::unsigned_chapter_title(navigation_design *self, text_stream *OUT, volume *V, chapter *C) {
	@<Render a chapter heading@>;
	@<Render a section-contents listing@>;
}

@<Render a chapter heading@> =
	HTML_OPEN_WITH("p", "class=\"chapterheading\"");
	if (Str::len(C->chapter_anchor) > 0) HTML::anchor(OUT, C->chapter_anchor);
	WRITE("%S", C->chapter_full_title);
	HTML_CLOSE("p");

@<Render a section-contents listing@> =
	HTML_OPEN_WITH("p", "class=\"chaptercontents\"");
	int lcount = 0;
	for (section *S = V->sections[0]; S; S = S->next_section) {
		if (S->in_which_chapter == C) {
			if (lcount++ > 0) WRITE("; ");
			HTML::begin_link_with_class(OUT, I"standardlink", S->section_URL);
			HTML_OPEN_WITH("span", "class=\"chaptercontentsitem\"");
			WRITE("%c%S", SECTION_SYMBOL, S->title);
			HTML_CLOSE("span");
			HTML::end_link(OUT);
		}
	}
	HTML_CLOSE("p");

@ =
void Unsigned::unsigned_section_title(navigation_design *self, text_stream *OUT, volume *V, chapter *C, section *S) {
	HTML_OPEN_WITH("p", "class=\"sectionheading\"");
	if (Str::len(S->section_anchor) > 0) HTML::anchor(OUT, S->section_anchor);
	WRITE("%c%S", SECTION_SYMBOL, S->title);
	HTML_CLOSE("p");
}

@h Index top.
And this is a variant for index pages, such as the index of examples.

=
void Unsigned::unsigned_navigation_index_top(navigation_design *self, text_stream *OUT, text_stream *filename, text_stream *title) {
	HTMLUtilities::ruled_line(OUT);
}

@h Middle.
At the middle part, when the text is over, but before any example cues.

=
void Unsigned::unsigned_navigation_middle(navigation_design *self, text_stream *OUT, volume *V, section *S) {
	HTMLUtilities::ruled_line(OUT);
}
