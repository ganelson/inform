[Midnight::] Codename Midnight.

The "midnight" style of navigational gadgets.

@h Top.
At the front end of a section, before any of its text.

Midnight doesn't have volume or chapter titles as such, since the banner
heading includes these anyway.

=
void Midnight::midnight_volume_title(OUTPUT_STREAM, volume *V) {
}

void Midnight::midnight_chapter_title(OUTPUT_STREAM, volume *V, chapter *C) {
}

@ =
void Midnight::midnight_section_title(OUTPUT_STREAM, volume *V, section *S) {
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
	Midnight::midnight_banner(OUT,
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
void Midnight::midnight_navigation_index_top(OUTPUT_STREAM, text_stream *filename, text_stream *title) {
	Midnight::midnight_banner(OUT, title, 0, NULL, NULL, NULL);
}

@h Middle.
At the middle part, when the text is over, but before any example cues.

=
void Midnight::midnight_navigation_middle(OUTPUT_STREAM, volume *V, section *S) {
	HTMLUtilities::ruled_line(OUT);
}

@h Example top.
This is reached before the first example is rendered, provided at least
one example will be:

=
void Midnight::midnight_navigation_example_top(OUTPUT_STREAM, volume *V, section *S) {
}

@h Example bottom.
Any closing ornament at the end of examples? This is reached after the
last example is rendered, provided at least one example has been.

=
void Midnight::midnight_navigation_example_bottom(OUTPUT_STREAM, volume *V, section *S) {
}

@h Bottom.
At the end of the section, after any example cues and perhaps also example
bodied. (In a section with no examples, this immediately follows the middle.)

=
void Midnight::midnight_navigation_bottom(OUTPUT_STREAM, volume *V, section *S) {
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
top of every Midnight page.

=
void Midnight::midnight_banner(OUTPUT_STREAM, text_stream *title, volume *V,
	text_stream *linkcentre, text_stream *linkleft, text_stream *linkright) {
	TEMPORARY_TEXT(url);
	WRITE_TO(url, "%S.html", indoc_settings->contents_leafname);
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
	if (Str::len(linkcentre) > 0) HTML::begin_link_with_class(OUT, I"standardlink", url);
	HTML_OPEN_WITH("span", "class=\"midnightbannertext\"");
	WRITE("%S", title);
	HTML_CLOSE("span");
	if (Str::len(linkcentre) > 0) HTML::end_link(OUT);
	HTML_CLOSE("td");
	HTML_OPEN_WITH("td", "class=\"midnightbannerrightcell\"");
	TEMPORARY_TEXT(img);
	HTMLUtilities::image_with_id(img, I"Hookup.png", I"hookup");
	HTMLUtilities::general_link(OUT, I"standardlink", url, img);
	DISCARD_TEXT(img);
	if (Str::len(linkright) > 0) {
		TEMPORARY_TEXT(img);
		HTMLUtilities::image_with_id(img, I"Hookright.png", I"hookright");
		HTMLUtilities::general_link(OUT, I"standardlink", linkright, img);
		DISCARD_TEXT(img);
	}
	HTML_CLOSE("td");
	HTML_CLOSE("tr");
	HTML_CLOSE("table");
	DISCARD_TEXT(url);
}

@ And this is a similar design motif used in Midnight contents pages: see below.

=
void Midnight::midnight_contents_column_banner(OUTPUT_STREAM, text_stream *title, volume *V, text_stream *extra) {
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
Midnight provides a contents page of its very own.

=
void Midnight::midnight_navigation_contents_files(void) {
	Midnight::write_contents_page(volumes[0]);
}

@ Contents pages are only produced in some styles, and they're really index
pages of links. In light mode, we get just a simple listing of the contents of
the current volume; in heavy mode, it's a two-column table, with the contents
of each volume side by side.

=
void Midnight::write_contents_page(volume *V) {
	TEMPORARY_TEXT(leafname);
	WRITE_TO(leafname, "%S%S.html", V->vol_prefix, indoc_settings->contents_leafname);
	filename *F = Filenames::in_folder(indoc_settings->destination, leafname);

	text_stream C_struct;
	text_stream *OUT = &C_struct;
	if (Streams::open_to_file(OUT, F, UTF8_ENC) == FALSE)
		Errors::fatal_with_file("can't write contents file", F);
	if (SET_wrapper == WRAPPER_epub)
		Epub::note_page(SET_ebook, F, I"Contents", I"toc");

	TEMPORARY_TEXT(title);
	WRITE_TO(title, "Contents");
	@<Begin the HTML page for the contents@>;
	@<Render any heading at the top of the contents@>;

	for (int column = 0; column < no_volumes; column++) {
		if ((column == V->allocation_id) ||
			(SET_navigation == NAVMODE_midnight) ||
			(SET_navigation == NAVMODE_architect))
			@<Render this column of the contents@>;
	}
	@<Render any tailpiece at the foot of the contents@>;

	@<End the HTML page for the contents@>;
	DISCARD_TEXT(title);
	Streams::close(OUT);
}

@<Begin the HTML page for the contents@> =
	TEMPORARY_TEXT(xxx);
	HTMLUtilities::get_tt_matter(xxx, 1, 1);
	if (Str::len(xxx) > 0) {
		Regexp::replace(xxx, L"%[SUBHEADING%]", NULL, 0);
		wchar_t replacement[1024];
		TEMPORARY_TEXT(rep);
		WRITE_TO(rep, "<title>%S</title>", title);
		Str::copy_to_wide_string(replacement, rep, 1024);
		DISCARD_TEXT(rep);
		Regexp::replace(xxx, L"<title>%c*</title>", replacement, REP_REPEATING);
		WRITE("%S", xxx);
	} else {
		HTMLUtilities::begin_file(OUT, volumes[0]);
		HTMLUtilities::write_title(OUT, title);
		if (SET_javascript == 1) {
			HTML::open_javascript(OUT, FALSE);
			HTMLUtilities::write_javascript_for_buttons(OUT);
			HTMLUtilities::write_javascript_for_contents_buttons(OUT);
			HTML::close_javascript(OUT);
		}
		HTML::end_head(OUT);

		if (SET_navigation == NAVMODE_architect) {
			HTML::begin_body(OUT, "paper architectpapertint");
		} else {
			HTML::begin_body(OUT, "paper midnightpapertint");
		}
	}
	DISCARD_TEXT(xxx);

@<End the HTML page for the contents@> =
	TEMPORARY_TEXT(tail);
	HTMLUtilities::get_tt_matter(tail, 1, 0);
	if (Str::len(tail) > 0) WRITE("%S", tail);
	else HTML::end_body(OUT);
	DISCARD_TEXT(tail);

@<Render any heading at the top of the contents@> =
	if (SET_navigation == NAVMODE_midnight) {
		WRITE("\n\n");
		HTML_OPEN_WITH("table", "class=\"fullwidth\"");
		HTML_OPEN("tr");
	} else if (SET_navigation == NAVMODE_architect) {
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
	} else {
		HTML_OPEN("h2");
		WRITE("%S", V->vol_title);
		HTML_CLOSE("h2");
	}

@<Render this column of the contents@> =
	if ((SET_navigation == NAVMODE_midnight) || (SET_navigation == NAVMODE_architect)) {
		if (no_volumes == 1) HTML_OPEN("td")
		else if (column == 0) HTML_OPEN_WITH("td", "class=\"midnightlefthalfpage\"")
		else HTML_OPEN_WITH("td", "class=\"midnightrighthalfpage\"");
		@<Render a heavyweight column of links@>;
		HTML_CLOSE("td");
	} else @<Render a lightweight list of simple links@>;

@<Render a lightweight list of simple links@> =
	for (section *S = volumes[column]->sections[0]; S; S = S->next_section) {
		chapter *C = S->begins_which_chapter;
		if (C) {
			HTML_OPEN("h3");
			WRITE("Chapter %d. %S", C->chapter_number, C->chapter_title);
			HTML_CLOSE("h3");
		}
		TEMPORARY_TEXT(destination);
		WRITE_TO(destination, "%S", S->section_URL);
		TEMPORARY_TEXT(description);
		WRITE_TO(description, "%S. %S", S->label, S->title);
		HTMLUtilities::general_link(OUT, I"standardlink", destination, description);
		DISCARD_TEXT(description);
		DISCARD_TEXT(destination);
		HTML_TAG("br");
	}

	if (SET_html_for_Inform_application)
		HTMLUtilities::textual_link(OUT, SET_link_to_extensions_index, I"Installed Extensions");
	HTMLUtilities::textual_link(OUT, indoc_settings->examples_alphabetical_leafname, I"Alphabetical Index of Examples");
	HTMLUtilities::textual_link(OUT, indoc_settings->examples_numerical_leafname, I"Numerical Index of Examples");
	HTMLUtilities::textual_link(OUT, indoc_settings->examples_thematic_leafname, I"Thematic Index of Examples");
	if (NUMBER_CREATED(index_lemma) > 0)
		HTMLUtilities::textual_link(OUT, SET_definitions_index_leafname, I"General Index");

	volume *OV = volumes[0];
	if (V == volumes[0]) OV = volumes[1];
	TEMPORARY_TEXT(url);
	WRITE_TO(url, "%Sindex.html", OV->vol_prefix);
	HTMLUtilities::textual_link(OUT, url, OV->vol_title);
	DISCARD_TEXT(url);

@ This is almost as simple, but now the lines linking to sections within a
chapter are grouped into a |<div>| for that chapter, which can be hidden
or revealed -- it contains "extra" material, as we put it.

We assume here that there are fewer than 1000 chapters in each volume;
there are in practice about 25.

@<Render a heavyweight column of links@> =
	volume *X = V;
	if (column == 1) X = volumes[1-V->allocation_id];

	TEMPORARY_TEXT(extra);
	if (indoc_settings->contents_expandable) HTMLUtilities::all_extras_link(extra, X->vol_abbrev);
	Midnight::midnight_contents_column_banner(OUT, X->vol_title, X, extra);
	DISCARD_TEXT(extra);

	int extra_count = 0;
	for (section *S = volumes[column]->sections[0]; S; S = S->next_section) {
		chapter *C = S->begins_which_chapter;
		if (C) {
			if ((extra_count > 0) && (indoc_settings->contents_expandable)) {
				HTML::end_div(OUT);
			}
			@<Render a chapter link@>;
		}
		@<Render a section link@>;
	}
	if ((extra_count > 0) && (indoc_settings->contents_expandable)) {
		HTML::end_div(OUT);
	}
	if ((column == no_volumes - 1) &&
		(SET_html_for_Inform_application == 0) &&
		(no_examples > 0)) {
		HTML_OPEN_WITH("p", "class=\"midnightcontentsA\"");
		WRITE("<i>Index</i>");
		HTML_CLOSE("p");
		@<Render links to example indexes@>;
	}
	if (SET_html_for_Inform_application == 1) {
		if (column == 0) {
			Midnight::mc_link_A(OUT, indoc_settings->examples_numerical_leafname, I"Numerical Index of Examples");
		} else {
			Midnight::mc_link_A(OUT, indoc_settings->examples_thematic_leafname, I"Thematic Index of Examples");
		}
	}

	WRITE("\n");

@<Render a chapter link@> =
	int id = column*1000 + extra_count++;
	HTML_OPEN_WITH("p", "class=\"midnightcontentsA\"");
	if (indoc_settings->contents_expandable) HTMLUtilities::extra_link(OUT, id);
	TEMPORARY_TEXT(thetitle);
	Str::copy(thetitle, C->chapter_title);
	TEMPORARY_TEXT(theprefix);
	if (no_volumes == 1) WRITE_TO(theprefix, "<b>Chapter %d</b>", C->chapter_number);
	else WRITE_TO(theprefix, "<b>%d</b>", C->chapter_number);
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, thetitle, L"Appendix: (%c*)")) {
		Str::clear(theprefix); Str::copy(theprefix, I"Appendix");
		Str::clear(thetitle); Str::copy(thetitle, mr.exp[0]);
	}
	Regexp::dispose_of(&mr);
	TEMPORARY_TEXT(txt);
	WRITE_TO(txt, "%S.&#160;%S", theprefix, thetitle);
	HTMLUtilities::general_link(OUT, I"standardlink", S->section_URL, txt);
	DISCARD_TEXT(txt);
	HTML_CLOSE("p");
	if (indoc_settings->contents_expandable) HTMLUtilities::extra_div_open(OUT, id);
	DISCARD_TEXT(theprefix);
	DISCARD_TEXT(thetitle);

@<Render a section link@> =
	TEMPORARY_TEXT(txt);
	WRITE_TO(txt, "%c%S", SECTION_SYMBOL, S->title);
	Midnight::mc_link_B(OUT, S->section_URL, txt);
	DISCARD_TEXT(txt);

@ In Midnight mode, this is where the extra indexes are listed in the contents:
some in the left-hand (WWI) column, others in the right-hand (RB). This is
done with a second row of the table whose first row contains the chapter
contents cells.

@<Render any tailpiece at the foot of the contents@> =
	if ((SET_navigation == NAVMODE_midnight) || (SET_navigation == NAVMODE_architect)) {
		HTML_CLOSE("tr");

		if ((SET_assume_Public_Library == 0) && (SET_html_for_Inform_application == 1)) {
			HTML_OPEN("tr");
			HTML_OPEN_WITH("td", "class=\"midnightlefthalfpage\"");
			Midnight::midnight_contents_column_banner(OUT, I"Extensions", volumes[0], NULL);
			Midnight::mc_link_A(OUT, SET_link_to_extensions_index, I"Installed Extensions");

			HTML_OPEN_WITH("p", "class=\"midnightcontentsA\"");
			WRITE("<i>for more extensions, visit:</i>");
			HTML_TAG("br");
			WRITE("<b>www.inform7.com</b>");
			HTML_CLOSE("p");
			HTML_CLOSE("td");

			HTML_OPEN_WITH("td", "class=\"midnightrighthalfpage\"");
			if (no_examples > 0) {
				Midnight::midnight_contents_column_banner(OUT, I"Indexes", volumes[1], NULL);
				@<Render links to example indexes@>;
			} else {
				Midnight::midnight_contents_column_banner(OUT, NULL, volumes[1], NULL);
			}
			if (NUMBER_CREATED(index_lemma) > 0) {
				Midnight::mc_link_A(OUT, SET_definitions_index_leafname, I"General Index");
			}
			HTML_CLOSE("td");
			HTML_CLOSE("tr");
		}

		HTML_CLOSE("table");
	}

@<Render links to example indexes@> =
	Midnight::mc_link_A(OUT, indoc_settings->examples_alphabetical_leafname, I"Alphabetical Index of Examples");
	Midnight::mc_link_A(OUT, indoc_settings->examples_numerical_leafname, I"Numerical Index of Examples");
	Midnight::mc_link_A(OUT, indoc_settings->examples_thematic_leafname, I"Thematic Index of Examples");

@ And here are the level A and B contents entry link paragraphs:

=
void Midnight::mc_link_A(OUTPUT_STREAM, text_stream *to, text_stream *text) {
	HTML_OPEN_WITH("p", "class=\"midnightcontentsA\"");
	HTMLUtilities::general_link(OUT, I"standardlink", to, text);
	HTML_CLOSE("p");
}

void Midnight::mc_link_B(OUTPUT_STREAM, text_stream *to, text_stream *text) {
	HTML_OPEN_WITH("p", "class=\"midnightcontentsB\"");
	HTMLUtilities::general_link(OUT, I"standardlink", to, text);
	HTML_CLOSE("p");
}
