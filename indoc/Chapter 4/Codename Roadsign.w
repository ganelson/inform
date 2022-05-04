[Roadsign::] Codename Roadsign.

The "roadsign" style of navigational gadgets.

@h Creation.

=
navigation_design *Roadsign::create(void) {
	navigation_design *ND = Nav::new(I"roadsign", TRUE, FALSE);
	METHOD_ADD(ND, RENDER_VOLUME_TITLE_MTID, Roadsign::roadsign_volume_title);
	METHOD_ADD(ND, RENDER_CHAPTER_TITLE_MTID, Roadsign::roadsign_chapter_title);
	METHOD_ADD(ND, RENDER_SECTION_TITLE_MTID, Roadsign::roadsign_section_title);
	METHOD_ADD(ND, RENDER_INDEX_TOP_MTID, Roadsign::roadsign_navigation_index_top);
	METHOD_ADD(ND, RENDER_NAV_MIDDLE_MTID, Roadsign::roadsign_navigation_middle);
	METHOD_ADD(ND, RENDER_EXAMPLE_TOP_MTID, Roadsign::roadsign_navigation_example_top);
	return ND;
}

@h Top.
At the front end of a section, before any of its text.

=
void Roadsign::roadsign_volume_title(navigation_design *self, text_stream *OUT, volume *V) {
	@<Render a volume heading@>;
	@<Render a chapter-contents table@>;
	HTML_OPEN("p"); HTML_CLOSE("p");
	@<Render the volume-top roadsign@>;
}

@<Render a volume heading@> =
	TEMPORARY_TEXT(partn)
	if (no_volumes > 1) Roadsign::roman_numeral(partn, V->allocation_id);
	HTML_OPEN_WITH("p", "class=\"volumeheading\"");
	WRITE("%S%S", partn, V->vol_title);
	HTML_CLOSE("p");
	DISCARD_TEXT(partn)

@ Some cumbersome Perl to produce a balanced two-column chapter listing:

@<Render a chapter-contents table@> =
	HTML_OPEN_WITH("table", "class=\"centredtable\"");
	int nch = V->vol_chapter_count;
	int rows = nch/2;
	if (2 * rows < nch) rows++;

	for (int rc = 0; rc < rows; rc++) {
		chapter *C = V->chapters[rc];
		chapter *OC = V->chapters[rc + rows];
		HTML_OPEN("tr");
		HTML_OPEN("td");
		HTML::begin_link_with_class(OUT, I"standardlink", C->chapter_URL);
		HTML_OPEN_WITH("span", "class=\"chapterlisting\"");
		WRITE("%S", C->chapter_full_title);
		HTML_CLOSE("span");
		HTML::end_link(OUT);
		WRITE("&#160;&#160;&#160;</td>");
		if (OC) {
			HTML_OPEN("td");
			HTML::begin_link_with_class(OUT, I"standardlink", OC->chapter_URL);
			HTML_OPEN_WITH("span", "class=\"chapterlisting\"");
			WRITE("%S", OC->chapter_full_title);
			HTML_CLOSE("span");
			HTML::end_link(OUT);
			WRITE("&#160;&#160;&#160;</td>");
		}
		HTML_CLOSE("tr");
	}
	HTML_CLOSE("table");

@<Render the volume-top roadsign@> =
	Roadsign::roadsign_begin(OUT, 1);
	TEMPORARY_TEXT(txt)
	WRITE_TO(txt, "Start reading here: %c%S", SECTION_SYMBOL, V->sections[0]->title);
	Roadsign::roadsign_add_direction(OUT, I"arrow-right.png", txt, V->chapters[0]->chapter_URL);
	if (no_volumes > 1) {
		for (int v = 0; v < no_volumes; v++) {
			TEMPORARY_TEXT(icon)
			if (v < V->allocation_id) WRITE_TO(icon, "arrow-up");
			if (v > V->allocation_id) WRITE_TO(icon, "arrow-down");
			if (Str::len(icon) > 0) {
				volume *LV = volumes[v];
				TEMPORARY_TEXT(txt)
				Roadsign::roman_numeral(txt, v);
				WRITE_TO(txt, "%S", LV->vol_title);
				TEMPORARY_TEXT(img)
				WRITE_TO(img, "%S.png", icon);
				Roadsign::roadsign_add_direction(OUT, img, txt, LV->vol_URL);
				DISCARD_TEXT(txt)
				DISCARD_TEXT(img)
			}
			DISCARD_TEXT(icon)
		}
	}
	if ((no_examples > 0) && (NUMBER_CREATED(index_lemma) > 0)) {
		Roadsign::roadsign_add_direction(OUT, I"arrow-down-right.png",
			I"Indexes of the examples and definitions", indoc_settings->examples_alphabetical_leafname);
	} else if (no_examples > 0) {
		Roadsign::roadsign_add_direction(OUT, I"arrow-down-right.png",
			I"Indexes of the examples", indoc_settings->examples_alphabetical_leafname);
	} else if (NUMBER_CREATED(index_lemma) > 0) {
		Roadsign::roadsign_add_direction(OUT, I"arrow-down-right.png",
			I"Index of definitions", indoc_settings->definitions_index_leafname);
	}
	Roadsign::roadsign_end(OUT, 1);

@ =
void Roadsign::roadsign_chapter_title(navigation_design *self, text_stream *OUT, volume *V, chapter *C) {
	@<Render a chapter heading@>;
	@<Render a section-contents listing@>;
	Roadsign::roadsign_chapter_jumps(OUT, V, C, 0);
}

@<Render a chapter heading@> =
	HTML_OPEN_WITH("p", "class=\"chapterheading\"");
	if (Str::len(C->chapter_anchor) > 0) HTML::anchor(OUT, C->chapter_anchor);
	WRITE("%S", C->chapter_full_title);
	HTML_CLOSE("p");

@<Render a section-contents listing@> =
	HTML_OPEN_WITH("p", "class=\"chaptercontents\"");
	int lcount = 0;
	for (section *S = V->sections[0]; S; S = S->next_section)
		if (S->in_which_chapter == C) {
			if (lcount++ > 0) WRITE("; ");
			HTML::begin_link_with_class(OUT, I"standardlink", S->section_URL);
			HTML_OPEN_WITH("span", "class=\"chaptercontentsitem\"");
			WRITE("%c%S", SECTION_SYMBOL, S->title);
			HTML_CLOSE("span");
			HTML::end_link(OUT);
		}
	HTML_CLOSE("p");

@ =
void Roadsign::roadsign_section_title(navigation_design *self, text_stream *OUT, volume *V, chapter *C, section *S) {
	HTML_OPEN_WITH("p", "class=\"sectionheading\"");
	if (Str::len(S->section_anchor) > 0) HTML::anchor(OUT, S->section_anchor);
	WRITE("%c%S", SECTION_SYMBOL, S->title);
	HTML_CLOSE("p");
}

@h Index top.
And this is a variant for index pages, such as the index of examples.

=
void Roadsign::roadsign_navigation_index_top(navigation_design *self, text_stream *OUT, text_stream *filename, text_stream *title) {
	HTML_OPEN_WITH("p", "class=\"chapterheading\"");
	WRITE("%S", title);
	HTML_CLOSE("p");
	Roadsign::roadsign_begin(OUT, 1);
	if (no_examples > 0) {
		if (Str::ne(filename, indoc_settings->examples_alphabetical_leafname))
			Roadsign::roadsign_add_direction(OUT, I"arrow-right.png",
				I"Examples in Alphabetical Order", indoc_settings->examples_alphabetical_leafname);
		if (Str::ne(filename, indoc_settings->examples_thematic_leafname))
			Roadsign::roadsign_add_direction(OUT, I"arrow-right.png",
				I"Examples in Thematic Order", indoc_settings->examples_thematic_leafname);
		if (Str::ne(filename, indoc_settings->examples_numerical_leafname))
			Roadsign::roadsign_add_direction(OUT, I"arrow-right.png",
				I"Examples in Numerical Order", indoc_settings->examples_numerical_leafname);
	}
	if (NUMBER_CREATED(index_lemma) > 0)
		if (Str::ne(filename, indoc_settings->definitions_index_leafname))
			Roadsign::roadsign_add_direction(OUT, I"arrow-right.png",
				I"General Index", indoc_settings->definitions_index_leafname);

	for (int v = 0; v < no_volumes; v++) {
		volume *V = volumes[v];
		TEMPORARY_TEXT(text)
		Roadsign::roman_numeral(text, v);
		WRITE_TO(text, "%S", V->vol_title);
		if (no_volumes == 1) Str::copy(text, I"Contents");
		Roadsign::roadsign_add_direction(OUT, I"arrow-up-left.png", text, V->vol_URL);
		DISCARD_TEXT(text)
	}
	Roadsign::roadsign_end(OUT, 1);

	HTMLUtilities::ruled_line(OUT);
}

@h Middle.
At the middle part, when the text is over, but before any example cues.

=
void Roadsign::roadsign_navigation_middle(navigation_design *self, text_stream *OUT, volume *V, section *S) {
	HTMLUtilities::ruled_line(OUT);
	HTML::begin_div_with_class_S(OUT, I"roadsigns", __FILE__, __LINE__);
	chapter *C = S->in_which_chapter;
	Roadsign::roadsign_begin(OUT, 0);
	@<Add home, back and forward directions to the roadsign@>;
	if (indoc_settings->examples_mode == EXMODE_open_internal)
		@<Add directions to this section's examples to the roadsign@>;
	Roadsign::roadsign_end(OUT, 0);
	HTMLUtilities::ruled_line(OUT);
	HTML::end_div(OUT);
}

@<Add home, back and forward directions to the roadsign@> =
	TEMPORARY_TEXT(txt)
	WRITE_TO(txt, "Start of %S", C->chapter_full_title);
	Roadsign::roadsign_add_direction(OUT, I"arrow-up.png", txt, C->chapter_URL);
	DISCARD_TEXT(txt)

	if (S->previous_section) {
		chapter *to_chap = S->previous_section->in_which_chapter;
		TEMPORARY_TEXT(link)
		WRITE_TO(link, "Back to ");
		if (to_chap != C)
			WRITE_TO(link, "Chapter %d: %S: ", to_chap->chapter_number, to_chap->chapter_title);
		WRITE_TO(link, "%c%S", SECTION_SYMBOL, S->previous_section->title);
		Roadsign::roadsign_add_direction(OUT, I"arrow-left.png",
			link, S->previous_section->section_URL);
		DISCARD_TEXT(link)
	}
	if (S->next_section) {
		chapter *to_chap = S->next_section->in_which_chapter;
		TEMPORARY_TEXT(link)
		WRITE_TO(link, "Onward to ");
		if (to_chap != C)
			WRITE_TO(link, "Chapter %d: %S: ", to_chap->chapter_number, to_chap->chapter_title);
		WRITE_TO(link, "%c%S", SECTION_SYMBOL, S->next_section->title);
		Roadsign::roadsign_add_direction(OUT, I"arrow-right.png",
			link, S->next_section->section_URL);
		DISCARD_TEXT(link)
	}

@<Add directions to this section's examples to the roadsign@> =
	example *E;
	LOOP_OVER(E, example) {
		if (E->example_belongs_to_section[V->allocation_id] == S) {
			TEMPORARY_TEXT(stars)
			for (int starcc=0; starcc < E->ex_star_count; starcc++)
				HTMLUtilities::asterisk_image(stars, I"asterisk.png");
			TEMPORARY_TEXT(pn)
			Str::copy(pn, E->ex_public_name);
			Rawtext::escape_HTML_characters_in(pn);
			TEMPORARY_TEXT(text)
			WRITE_TO(text, "Example %d: %S <b>%S</b>&#160;&#160;&#160; %S",
				E->example_position[0], stars, pn, E->ex_outline);
			TEMPORARY_TEXT(url)
			Examples::goto_example_url(url, E, V);
			Roadsign::roadsign_add_direction(OUT, I"arrow-down.png", text, url);
			DISCARD_TEXT(text)
			DISCARD_TEXT(stars)
			DISCARD_TEXT(url)
		}
	}

@h Example top.
This is reached before the first example is rendered, provided at least
one example will be:

=
void Roadsign::roadsign_navigation_example_top(navigation_design *self, text_stream *OUT, volume *V, section *S) {
	if (indoc_settings->examples_granularity == CHAPTER_GRANULARITY)
		Roadsign::roadsign_chapter_jumps(OUT, V, S->in_which_chapter, TRUE);
}

@h Utility routines.

=
void Roadsign::roadsign_chapter_jumps(OUTPUT_STREAM, volume *V, chapter *C, int bottom) {
	Roadsign::roadsign_begin(OUT, 1);
	int chc = V->vol_chapter_count;
	if ((chc > 1) && (bottom == FALSE)) {
		TEMPORARY_TEXT(text)
		WRITE_TO(text, "Contents of <i>%S</i>", V->vol_title);
		Roadsign::roadsign_add_direction(OUT, I"arrow-up-left.png", text, V->vol_URL);
		DISCARD_TEXT(text)
		if (C->previous_chapter)
			Roadsign::roadsign_add_direction(OUT, I"arrow-left.png",
				C->previous_chapter->chapter_full_title, C->previous_chapter->chapter_URL);
	}
	if (bottom == 1)
		Roadsign::roadsign_add_direction(OUT, I"arrow-up.png",
			I"Start of this chapter", C->chapter_URL);
	if (C->next_chapter)
		Roadsign::roadsign_add_direction(OUT, I"arrow-right.png",
			C->next_chapter->chapter_full_title, C->next_chapter->chapter_URL);
	if (no_examples > 0)
		Roadsign::roadsign_add_direction(OUT, I"arrow-down-right.png",
			I"Indexes of the examples",
			indoc_settings->examples_alphabetical_leafname);

	Roadsign::roadsign_end(OUT, 1);
}

@ And at a lower level: here's how a roadsign is made, as a table of links.

=
void Roadsign::roadsign_begin(OUTPUT_STREAM, int centred) {
	if (centred) HTML_OPEN_WITH("table", "class=\"centredtable\"")
	else HTML_OPEN("table");
}

@ This is a 2-column table: the link image in column 1, the text in column 2.

=
void Roadsign::roadsign_add_direction(OUTPUT_STREAM, text_stream *icon, text_stream *text, text_stream *url) {
	HTML_OPEN("tr");
	HTML_OPEN_WITH("td", "class=\"roadsigndirection\"");
	HTML::begin_link_with_class(OUT, I"standardlink", url);
	HTMLUtilities::image_element(OUT, icon);
	HTML::end_link(OUT);
	HTML_CLOSE("td");
	HTML_OPEN("td");
	HTML::begin_link_with_class(OUT, I"standardlink", url);
	WRITE("%S", text);
	HTML::end_link(OUT);
	HTML_CLOSE("td");
	HTML_CLOSE("tr");
}

@ =
void Roadsign::roadsign_end(OUTPUT_STREAM, int cent) {
	HTML_CLOSE("table");
}

@h Ecce romani.

=
void Roadsign::roman_numeral(OUTPUT_STREAM, int v) {
	if (v == 0) WRITE("Part I. ");
	if (v == 1) WRITE("Part II. ");
	if (v == 2) WRITE("Part III. ");
	if (v == 3) WRITE("Part IV. ");
	if (v == 4) WRITE("Part V. ");
	if (v == 5) WRITE("Part VI. ");
	if (v == 6) WRITE("Part VII. ");
	if (v == 7) WRITE("Part VIII. ");
	if (v == 8) WRITE("Part IX. ");
	if (v == 9) WRITE("Part X. ");
}
