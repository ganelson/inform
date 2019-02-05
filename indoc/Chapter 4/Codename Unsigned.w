[Unsigned::] Codename Unsigned.

The "unsigned" style of navigational gadgets.

@h Top.
At the front end of a section, before any of its text.

=
void Unsigned::unsigned_volume_title(OUTPUT_STREAM, volume *V) {
	@<Render a volume heading@>;
	@<Render a chapter-contents table@>;
}

@<Render a volume heading@> =
	TEMPORARY_TEXT(partn);
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
void Unsigned::unsigned_chapter_title(OUTPUT_STREAM, volume *V, chapter *C) {
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
void Unsigned::unsigned_section_title(OUTPUT_STREAM, volume *V, section *S) {
	HTML_OPEN_WITH("p", "class=\"sectionheading\"");
	if (Str::len(S->section_anchor) > 0) HTML::anchor(OUT, S->section_anchor);
	WRITE("%c%S", SECTION_SYMBOL, S->title);
	HTML_CLOSE("p");
}

@h Index top.
And this is a variant for index pages, such as the index of examples.

=
void Unsigned::unsigned_navigation_index_top(OUTPUT_STREAM, text_stream *filename, text_stream *title) {
	HTMLUtilities::ruled_line(OUT);
}

@h Middle.
At the middle part, when the text is over, but before any example cues.

=
void Unsigned::unsigned_navigation_middle(OUTPUT_STREAM, volume *V, section *S) {
	HTMLUtilities::ruled_line(OUT);
}

@h Example top.
This is reached before the first example is rendered, provided at least
one example will be:

=
void Unsigned::unsigned_navigation_example_top(OUTPUT_STREAM, volume *V, section *S) {
}

@h Example bottom.
Any closing ornament at the end of examples? This is reached after the
last example is rendered, provided at least one example has been.

=
void Unsigned::unsigned_navigation_example_bottom(OUTPUT_STREAM, volume *V, section *S) {
}

@h Bottom.
At the end of the section, after any example cues and perhaps also example
bodied. (In a section with no examples, this immediately follows the middle.)

=
void Unsigned::unsigned_navigation_bottom(OUTPUT_STREAM, volume *V, section *S) {
}

@h Contents page.
Roadsign doesn't use a standalone contents page.

=
void Unsigned::unsigned_navigation_contents_files(void) {
}
