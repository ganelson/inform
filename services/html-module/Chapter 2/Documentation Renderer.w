[DocumentationRenderer::] Documentation Renderer.

To render a passage of extension documentation as HTML.

@h Disclaimer.
The following code originated as a port of a simplified version of an early
form of the Inform documentation tool //indoc//: in general, that will do a
better all-round job, but this cut-down version is adequate for what we use
it for, which is to make extension documentation pages. Those use a much
simplified range of syntax compared to the full gamut known to //indoc//.

@h Links and leafnames.
Matters are complicated because an extension typically has not only a
run of source text, but also up to 26 examples: suppose there are $X$
of these. The extension then needs to produce $X+1$ pages of HTML: the
primary one, which just has the body text, and then $X$ variants which
duplicate the primary one except that one of the examples is opened up
to reveal its content. Each of these pages will have $X$ anchor points
named |#eg1| up to |#egX|, for the positions of the examples.

The pages will typically be filenamed with the extension title, followed
by |-eg1|, |-eg2|, ..., in the case of the example variants, and then
|.html|.

The following routine prints the leafname part of an HTML reference to the
extension documentation, at anchor point |to_example_anchor| (or if 0 then
at the top) of the version with example |to_example_variant| opened (or if
0 then the original with all examples closed). What complicates it is that
the base leafname might be any of the above variant filenames, so we may
need to strip off an existing ending. For instance, if we are in example 2
and want to link to anchor 5 on example 4, the base leafname might be
|Gusher-eg2| and we need to remove the |-eg2| and replace with |-eg4|
before we can add the |#eg5|.

This will fail if anyone's extension has a title ending in |-eg| followed
by a number. I believe I can live with the guilt.

=
void DocumentationRenderer::href_of_example(OUTPUT_STREAM, text_stream *base_leafname,
	int to_example_variant, int to_example_anchor) {
	for (int i=0, L = Str::len(base_leafname); i<L; i++) {
		if ((Str::includes_wide_string_at(base_leafname, L"-eg", i)) &&
			(Characters::isdigit(Str::get_at(base_leafname, i+3)))) break;
		PUT(Str::get_at(base_leafname, i));
	}
	if (to_example_variant > 0) WRITE("-eg%d", to_example_variant);
	WRITE(".html");
	if (to_example_anchor > 0) WRITE("#eg%d", to_example_anchor);
}

@ The extension documentation text can optionally include section and
chapter headings, and also examples. Here we parse the opening of a paragraph
to see if it might be a heading. For instance, a paragraph consisting of

>> Section: Black Gold

matches successfully and sets the level to 2 and the name to the word range
"Black Gold".

=
<extension-documentation-heading> ::=
	Chapter : ... |  ==> { 1, - }
	Chapter - ... |  ==> { 1, - }
	Section : ... |  ==> { 2, - }
	Section - ... |  ==> { 2, - }

@ =
int DocumentationRenderer::extension_documentation_heading(wording W, int *level, wording *HW) {
	if (<extension-documentation-heading>(W)) {
		*level = <<r>>;
		W = Wordings::trim_first_word(Wordings::trim_first_word(W));
		int end = Wordings::first_wn(W);
		while ((end<=Wordings::last_wn(W)) && (Lexer::word(end) != PARBREAK_V)) end++;
		end--;
		*HW = Wordings::up_to(W, end);
		return TRUE;
	}
	return FALSE;
}

@ And here we do the same to identify an example, which has to satisfy a
more exacting specification: a paragraph in the shape

>> Example: *** Gelignite Anderson - A Tale of the Texas Oilmen

which would result in the name being set to the range "Gelignite Anderson",
an asterisk count of 3, and the rubric being "A Tale of the Texas Oilmen".

Note the unusual use of the Preform escape character |\| below: this is
because |***| is a reserved token in Preform, whereas we want the literal
text of three asterisks in a row.

=
<extension-example-header> ::=
	example : <row-of-asterisks> ... - ... |  ==> { pass 1 }
	example : ... - ...                       ==> { 0, - }

<row-of-asterisks> ::=
	* |     ==> { 1, - }
	** |    ==> { 2, - }
	\*** |  ==> { 3, - }
	****    ==> { 4, - }

@ =
int DocumentationRenderer::extension_documentation_example(wording W,
	int *asterisks, wording *egn, wording *egr) {
	if (Wordings::length(W) > 10) return FALSE; /* not enough space */
	if (<extension-example-header>(W)) {
		wording NW = GET_RW(<extension-example-header>, 1);
		wording RW = Wordings::first_word(GET_RW(<extension-example-header>, 2));
		int r2 = Wordings::first_wn(RW);
		while ((r2 <= Wordings::last_wn(W)) &&
			((Lexer::word(r2) == PARBREAK_V) == FALSE)) r2++;
		if (r2 >= Wordings::last_wn(W)) return FALSE;
		r2--;
		/* a successful match has now been made */
		*asterisks = <<r>>; *egn = NW; *egr = RW;
		return TRUE;
	}
	return FALSE;
}

@h The table of contents.
The user sees chapters as A subheadings, numbered upwards from 1, and sees
sections as B subheadings, numbered from 1 within each chapter. It is legal to
have only A subheadings; only B subheadings; or a mixture of the two.

If a scan can find any headings at all then we will wish to typeset a table of
contents up front. The following routine looks for what material might go into
a TOC, and sets one if it finds anything: otherwise, it sets nothing and has
no effect. Because of the compulsory paragraph break following the divider
line in the extension, we can safely assume that every headng will follow a
paragraph break word, even one right at the top of the extension's
documentation.

(Examples are included in the table of contents only if they occur after the
first heading, which I think is reasonable enough: there can be at most 26 per
extension, enabling them to be lettered as Example A to Example Z.)

=
void DocumentationRenderer::table_of_contents(wording W, OUTPUT_STREAM, text_stream *base_leafname) {
	int heading_count = 0, chapter_count = 0, section_count = 0, example_count = 0;
	LOOP_THROUGH_WORDING(i, W) {
		int edhl, asterisks;
		wording NW = EMPTY_WORDING, RUBW = EMPTY_WORDING;
		if (Lexer::word(i) == PARBREAK_V) {
			while (Lexer::word(i) == PARBREAK_V) i++;
			if (i>Wordings::last_wn(W)) break;
			if (DocumentationRenderer::extension_documentation_heading(
				Wordings::from(W, i), &edhl, &NW)) {
				heading_count++;
				if (heading_count == 1) {
					HTML_CLOSE("p");
					HTML_TAG("hr"); /* ruled line at top of TOC */
					HTML_OPEN("p");
				}
				if (edhl == 1) {
					chapter_count++; section_count = 0;
					if (chapter_count > 1) HTML_TAG("br"); /* skip a line between chapters */
				}
				if (edhl == 2) section_count++;
				@<Typeset the table of contents entry for this heading@>;
				i = Wordings::last_wn(NW); continue;
			}
			if ((heading_count > 0) && (example_count < 26) &&
				(DocumentationRenderer::extension_documentation_example(
					Wordings::from(W, i), &asterisks, &NW, &RUBW))) {
				if (++example_count == 1) {
					HTML_TAG("br");
					HTML_OPEN("b");
					WRITE("Examples");
					HTML_CLOSE("b");
					HTML_TAG("br");
				}
				@<Typeset the table of contents entry for this example@>;
				i = Wordings::last_wn(RUBW); continue;
			}
		}
	}
	if (heading_count > 0) {
		HTML_CLOSE("p");
		HTML_TAG("hr"); /* ruled line at foot of TOC, if there is one */
		HTML_OPEN("p");
	}
}

@ Internally, we are numbering all headings independently upwards from 1, and
we set anchor points in the documentation called |#docsec1|, |#docsec2|,
and so on: some of these will be chapter headings, some section headings.
These are the destinations of links from heading lines in the TOC.

@<Typeset the table of contents entry for this heading@> =
	switch (edhl) {
		case 1:
			HTML::begin_colour(OUT, I"000000");
			HTML_OPEN("b");
			HTML_OPEN_WITH("a",
				"style=\"text-decoration: none\" href=#docsec%d", heading_count);
			WRITE("Chapter %d: ", chapter_count);
			HTML_CLOSE("a");
			HTML_CLOSE("b");
			HTML::end_colour(OUT);
			break;
		case 2:
			if (chapter_count > 0) /* if there are chapters as well as sections... */
				WRITE("&nbsp;&nbsp;&nbsp;"); /* ...then set an indentation before entry */
			HTML::begin_colour(OUT, I"000000");
			HTML_OPEN_WITH("a", "style=\"text-decoration: none\" href=#docsec%d", heading_count);
			WRITE("Section ");
			if (chapter_count > 0) /* if there are chapters as well as sections... */
				WRITE("%d.%d: ", chapter_count, section_count); /* quote in form S.C */
			else
				WRITE("%d: ", section_count); /* otherwise quote section number only */
			HTML_CLOSE("a");
			HTML::end_colour(OUT);
			break;
		default: internal_error("unable to set this heading level in extension TOC");
	}
	DocumentationRenderer::set_body_text(NW, OUT, EDOC_FRAGMENT_ONLY, NULL);
	HTML_TAG("br");

@ The TOC entries for examples are similar. Here the link is to the variant
page in the current family which has the given example open, and moreover,
to the anchor in that page corresponding to the top of the example: thus as
far as the user is concerned it opens the example and goes there.

@<Typeset the table of contents entry for this example@> =
	WRITE("&nbsp;&nbsp;&nbsp;"); /* always indent TOC entries for examples */
	TEMPORARY_TEXT(link)
	WRITE_TO(link, "style=\"text-decoration: none\" href=\"");
	DocumentationRenderer::href_of_example(link, base_leafname, example_count, example_count);
	WRITE_TO(link, "\"");
	HTML::begin_colour(OUT, I"000000");
	HTML_OPEN_WITH("a", "%S", link);
	PUT('A'+example_count-1); /* the letter A to Z */
	DocumentationRenderer::set_body_text(NW, OUT, EDOC_FRAGMENT_ONLY, NULL);
	HTML_CLOSE("a");
	HTML::end_colour(OUT);
	HTML_TAG("br");

@

=
<table-sentence> ::=
	<if-start-of-paragraph> table ...

@h Setting the body text.

@d EDOC_ALL_EXAMPLES_CLOSED -1 /* do not change this without also changing Extensions */
@d EDOC_FRAGMENT_ONLY -2 /* must differ from this and from all example variant numbers */

=
int DocumentationRenderer::set_body_text(wording W, OUTPUT_STREAM,
	int example_which_is_open, text_stream *base_leafname) {
	int heading_count = 0, chapter_count = 0, section_count = 0, example_count = 0;
	int mid_example = FALSE, skipping_text_of_an_example = FALSE,
		start_table_next_line = FALSE, mid_I7_table = FALSE, row_of_table_is_empty = FALSE,
		mid_displayed_source_text = FALSE, indentation = 0, close_I6_position = -1;
	HTML_OPEN("p");
	LOOP_THROUGH_WORDING(i, W) {
		int edhl, asterisks;
		wording NW = EMPTY_WORDING, RUBW = EMPTY_WORDING;
		if (Lexer::word(i) == PARBREAK_V) { /* the lexer records this to mean a paragraph break */
			@<Handle a paragraph break@>;
			while (Lexer::word(i) == PARBREAK_V) i++;
			if (i>Wordings::last_wn(W)) break; /* treat multiple paragraph breaks as one */
			@<Determine indentation of new paragraph@>;
			if (DocumentationRenderer::extension_documentation_heading(Wordings::from(W, i), &edhl, &NW)) {
				heading_count++;
				if (edhl == 1) {
					chapter_count++; section_count = 0;
					if (chapter_count > 1) {
						HTML_CLOSE("p");
						HTML_TAG("hr"); /* rule a line between chapters */
					}
				}
				if (edhl == 2) section_count++;
				@<Typeset the heading of this chapter or section@>;
				i = Wordings::last_wn(NW); continue;
			}
			if ((example_count < 26) && (DocumentationRenderer::extension_documentation_example(
					Wordings::from(W, i), &asterisks, &NW, &RUBW))) {
				skipping_text_of_an_example = FALSE;
				if (mid_example) @<Close the previous example's text@>;
				mid_example = FALSE;
				example_count++;
				@<Typeset the heading of this example@>;
				if (example_count == example_which_is_open) {
					@<Open the new example's text@>;
					mid_example = TRUE;
				} else skipping_text_of_an_example = TRUE;
				i = Wordings::last_wn(RUBW); continue;
			}
		}
		if (skipping_text_of_an_example) continue;

		@<Handle a line or column break, if there is one@>;
		@<Transcribe an ordinary word of the documentation@>;
		if (close_I6_position == i) WRITE(" -)");
	}
	if (mid_example) @<Close the previous example's text@>;
	if (example_which_is_open != EDOC_FRAGMENT_ONLY) @<Handle a paragraph break@>;
	HTML_CLOSE("p");
	return example_count;
}

@h Typesetting the standard matter.
A paragraph break might mean the end of displayed matter (and if so, then also
the end of any table being displayed). Otherwise, it just means a paragraph
break, and a chance to restore our tired variables.

@<Handle a paragraph break@> =
	if (mid_displayed_source_text)  {
		HTML::end_colour(OUT);
		if (mid_I7_table) @<End I7 table in extension documentation@>;
		HTML_CLOSE("blockquote");
	} else {
		HTML_CLOSE("p");
	}
	WRITE("\n");
	HTML_OPEN("p");
	mid_displayed_source_text = FALSE; mid_I7_table = FALSE;

@ The indentation setting is made here because a tab anywhere else does
not mean a paragraph has been indented. Here |i| is at the number of the
first word after the paragraph break; the break character corresponding
to it is the one before that word, so describes the kind of whitespace
between the paragraph break and the first nonwhitespace of the new
paragraph.

@<Determine indentation of new paragraph@> =
	indentation = 0; if (Lexer::break_before(i) == '\t') indentation = 1;

@ Positions for paste icons in extension documentation are marked with
asterisk and colon:

=
<extension-documentation-paste-marker> ::=
	* : ...

@ Two lower-level sorts of breaks can also occur in the middle of a paragraph:
line breaks, indicated by newlines plus some tabs, and column breaks inside
I7 source tables, indicated by tabs. We have to deal with those before we
can move on to the subsequent word.

@<Handle a line or column break, if there is one@> =
	if (Lexer::indentation_level(i) > 0) indentation = Lexer::indentation_level(i);

	if (indentation > 0) @<Handle the start of a line which is indented@>;
	if (<extension-documentation-paste-marker>(Wordings::from(W, i))) {
		wording W = GET_RW(<extension-documentation-paste-marker>, 1);
		@<Incorporate an icon linking to a Javascript function to paste the text which follows@>;
		i++; continue;
	}
	indentation = 0;
	if ((mid_I7_table) && ((Lexer::break_before(i) == '\t') || (Lexer::indentation_level(i) == 1))) {
		if (row_of_table_is_empty == FALSE)
			@<End table cell for I7 table in extension documentation@>;
		@<Begin table cell for I7 table in extension documentation@>;
		row_of_table_is_empty = FALSE;
	}

@ See Javascript Pastes for further explanation of the general method here.

@<Transcribe an ordinary word of the documentation@> =
	wchar_t *p = Lexer::word_raw_text(i); int j;
	if ((i>Wordings::first_wn(W))
		&& ((p[1] != 0) || (Lexer::is_punctuation(p[0]) == FALSE)
			|| (p[0] == '(') || (p[0] == '{') || (p[0] == '}'))
		&& (compare_word(i-1, OPENBRACKET_V)==FALSE))
		WRITE(" "); /* restore normal spacing around punctuation */
	for (j=0; p[j]; j++) HTML::put(OUT, p[j]); /* set the actual word */
	if (Lexer::word(i) == OPENI6_V) close_I6_position = i+1; /* ensure I6 literals are closed */

@ A paste causes the same material to be set twice: once in the argument to
the Javascript paste function (which is passed to the application when the
user clicks on the paste icon, and thus ends up in the Source panel), and
once also in the HTML documentation. That's why the code here ranges forward
to see how far it should go (to the next paragraph break which is not followed
by further tabbed matter, or in other words, to the end of the display),
but does not advance |i| commensurately.

@<Incorporate an icon linking to a Javascript function to paste the text which follows@> =
	int x = i+2, y = Wordings::last_wn(W), j;
	for (j=x; j<=y; j++) /* first find the end of the quoted passage */
		if (Lexer::word(j) == PARBREAK_V) {
			int possible_end = j-1;
			while (Lexer::word(j) == PARBREAK_V) j++;
			if ((j<y) && ((Lexer::break_before(j) == '\t') || (Lexer::indentation_level(j) > 0))) continue;
			y = possible_end; break;
		}
	PasteButtons::paste_W(OUT, Wordings::new(x, y));

@ The first step of indentation is handled using the |<blockquote>| tag;
within that, further tab stops are simulated by printing a row of four
non-breaking spaces for each indentation level above 1. A paragraph
of indented (i.e., display matter) beginning with the word "Table" is
taken to be an I7 table, and we remember that the next line break will
take us past the titling line and into the table entries, which we will
need to achieve with an HTML |<table>|.

@<Handle the start of a line which is indented@> =
	int j;
	if (mid_displayed_source_text) {
		if (start_table_next_line) {
			start_table_next_line = FALSE;
			mid_I7_table = TRUE;
			@<Begin I7 table in extension documentation@>;
		} else {
			if (mid_I7_table) @<Begin new row of I7 table in extension documentation@>
			else HTML_TAG("br");
		}
		if (mid_I7_table) row_of_table_is_empty = TRUE;
	} else {
		HTML_OPEN("blockquote");
		HTML::begin_colour(OUT, I"000080");
		mid_displayed_source_text = TRUE;
		if (<table-sentence>(Wordings::from(W, i)))
			start_table_next_line = TRUE;
	}
	indentation--;
	for (j=0; j<indentation; j++) WRITE("&nbsp;&nbsp;&nbsp;&nbsp;");

@h Typesetting the headings.
That is thankfully all for the tormented logic of all those changes of state:
from here to the rest of the section, all we do is to generate pretty HTML,
and without altering any variables or causing any side-effects at all.
First, the headings. Recall that heading number |N| is required to be at
anchor |#docsecN|.

@<Typeset the heading of this chapter or section@> =
	HTML_OPEN("p");
	switch (edhl) {
		case 1:
			HTML::begin_colour(OUT, I"800000");
			break;
		case 2:
			HTML::begin_colour(OUT, I"000000");
			break;
	}
	HTML_OPEN("b");
	HTML_OPEN_WITH("span", "id=docsec%d", heading_count);
	switch (edhl) {
		case 1:
			WRITE("Chapter %d: ", chapter_count);
			break;
		case 2:
			WRITE("Section ");
			if (chapter_count > 0) WRITE("%d.", chapter_count);
			WRITE("%d: ", section_count);
			break;
	}
	DocumentationRenderer::set_body_text(NW, OUT, EDOC_FRAGMENT_ONLY, NULL);
	HTML_CLOSE("span");
	HTML_CLOSE("b");
	HTML::end_colour(OUT);

@ An example is set with a two-table header, and followed optionally by a
table of its inset copy, shaded to distinguish it from the rest of the
page. The heading is constructed with a main table of one row of two cells,
in the following section. The left-hand cell then contains a further table,
in the next section.

@<Typeset the heading of this example@> =
	HTML_OPEN("hr"); /* rule a line before the example heading */
	HTML_OPEN("p");
	HTML_OPEN_WITH("a", "name=eg%d", example_count); /* provide the anchor point */
	HTML::begin_plain_html_table(OUT);
	HTML_OPEN("tr");

	/* Left hand cell: the oval icon */
	HTML_OPEN_WITH("td", "halign=\"left\" valign=\"top\" cellpadding=0 cellspacing=0 width=38px");
	@<Typeset the lettered oval example icon@>;
	HTML_CLOSE("td");

	/* Right hand cell: the asterisks and title, with rubric underneath */
	HTML_OPEN_WITH("td", "cellpadding=0 cellspacing=0 halign=\"left\" valign=\"top\"");
	@<Incorporate link to the example opened up@>;
	while (asterisks-- > 0)
		HTML_TAG_WITH("img", "border=\"0\" src='inform:/doc_images/asterisk.png'");
	HTML_OPEN("b");
	HTML::begin_colour(OUT, I"505050");
	WRITE("&nbsp;Example&nbsp;");
	HTML::end_colour(OUT);
	HTML::begin_colour(OUT, I"000000");
	DocumentationRenderer::set_body_text(NW, OUT, EDOC_FRAGMENT_ONLY, base_leafname);
	HTML::end_colour(OUT);
	HTML_CLOSE("b");
	HTML_CLOSE("a"); /* end the textual link */
	HTML_TAG("br");
	DocumentationRenderer::set_body_text(RUBW, OUT, EDOC_FRAGMENT_ONLY, base_leafname);
	HTML_OPEN("p");

	HTML_CLOSE("td");
	HTML_CLOSE("tr");
	HTML::end_html_table(OUT);
	HTML_OPEN("p");

@ The little oval icon with its superimposed boldface letter is much harder to
get right on all browsers than it looks, and the following is the result of
some pretty grim experimentation. Basically, we make a tight, borderless,
one-cell-in-one-row table, use CSS to make a transparent PNG image of an oval
the background image for the table, then put a boldface letter in the centre
of its one and only cell. (Things were even worse when IE6 for Windows still
had its infamous PNG transparency bug.)

@<Typeset the lettered oval example icon@> =
	HTML::begin_plain_html_table(OUT);
	HTML_OPEN_WITH("tr", "class=\"oval\"");
	HTML_OPEN_WITH("td", "width=38px height=30px align=\"left\" valign=\"center\"");
	@<Incorporate link to the example opened up@>;
	HTML_OPEN_WITH("div",
		"class=\"paragraph Body\" style=\"line-height: 1px; margin-bottom: 0px; "
		"margin-top: 0px; padding-bottom: 0pt; padding-top: 0px; text-align: center; "
		"color: #202020; font-size: 14px; line-height: 1px;\"");
	HTML_OPEN("b");
	PUT('A' + example_count - 1);
	HTML_CLOSE("b");
	HTML_CLOSE("div");
	HTML_CLOSE("a");
	HTML_CLOSE("td");
	HTML_CLOSE("tr");
	HTML::end_html_table(OUT);

@ Clicking on the example banner opens it up, if it's currently closed, or
closes it up, if it's currently open.

@<Incorporate link to the example opened up@> =
	TEMPORARY_TEXT(url)
	WRITE_TO(url, "href=\"");
	if (example_count == example_which_is_open) /* this example currently open */
		DocumentationRenderer::href_of_example(url, base_leafname, EDOC_ALL_EXAMPLES_CLOSED, example_count);
	else /* this example not yet open */
		DocumentationRenderer::href_of_example(url, base_leafname, example_count, example_count);
	WRITE_TO(url, "\" style=\"text-decoration: none\"");
	HTML_OPEN_WITH("a", "%S", url);
	DISCARD_TEXT(url)

@h Typesetting I7 tables in displayed source text.
Unsurprisingly, I7 tables are set (after their titling lines) as HTML tables,
and this is fiddly but elementary in the usual way of HTML tables:

@<Begin I7 table in extension documentation@> =
	HTML::end_colour(OUT);
	HTML_TAG("br");
	HTML::begin_plain_html_table(OUT);
	HTML::first_html_column(OUT, 0);

@<End table cell for I7 table in extension documentation@> =
	HTML::end_colour(OUT);
	HTML::next_html_column(OUT, 0);

@<Begin table cell for I7 table in extension documentation@> =
	HTML::begin_colour(OUT, I"000080");

@<Begin new row of I7 table in extension documentation@> =
	HTML::end_html_row(OUT);
	HTML::first_html_column(OUT, 0);

@<End I7 table in extension documentation@> =
	HTML::end_html_row(OUT);
	HTML::end_html_table(OUT);

@h Typesetting the body of an example.
This is done just the way all other extension documentation material is
handled, except that it is inside an inset box: which is provided by
a shaded HTML table, containing just one row, which contains just one
cell. Here the inset table begins:

@<Open the new example's text@> =
	HTML::begin_html_table(OUT, "#f0f0f0", TRUE, 0, 0, 0, 0, 0);
	HTML::first_html_column(OUT, 0);
	HTML_OPEN("p");

@ And here the inset table ends:

@<Close the previous example's text@> =
	HTML::end_html_row(OUT);
	HTML::end_html_table(OUT);
	HTML_OPEN("p");
