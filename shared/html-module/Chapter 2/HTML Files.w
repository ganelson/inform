[HTMLFiles::] HTML Files.

To provide utilities for writing HTML files such as the problems
report, the extension documentation, the index files and so forth.

@ Inform documentation -- its HTML text and the images, etc., used within
it -- is stored in two areas: "built-in" and "external". The built-in
area is expected to be within the Inform 7 application itself. For
instance, on OS X, this is at:

|...wherever.../Inform.app/Contents/Resources/| and/or

|...wherever.../Inform.app/Contents/Resources/English.lproj/|

(The duplication is a complication to do with localisation which we
can ignore here.) The material stored in this built-in area is fixed: the
Inform application needs to work even if stored on a read-only disc, or
where the user has insufficient permissions to alter it. Inform itself neither
reads from, nor writes to, any file in the built-in documentation area.

Documentation for the installed extensions does, however, change: it is
written by Inform as and when necessary. This is the material making up the
"external" area, and it needs to be somewhere which the user certainly
has the necessary permissions to write to. For instance:

|~/Library/Inform/Documentation/| (OS X)

|My Documents\Inform\Documentation\| (Windows)

Pages in these two areas, built-in and external, need to link to each other by
links: in addition, pages in the external area need access to images stored in
the built-in area.

The other HTML files written by Inform are stored within the relevant
project's bundle: these are the report of Problems (if any) and the
Index. They, too, need access to images stored in the built-in area.

The problem we face is that these three mini-websites -- the built-in
documentation, the external documentation, and the project-specific
pages -- are written by tools which cannot know the correct file URLs.
(For instance, it would not even help for the application to tell Inform
where the built-in area is: because the HTML written by Inform would then
cease to work if the user moved the application elsewhere in the
filing system after Inform had run.)

@h The "inform:" URL scheme.
We solve this by requiring that the Inform 7 application must support
a new URL scheme.

(a) |<inform://...>| is interpreted as a file in the built-in documentation
area, except that

(b) |<inform://Extensions/...whatever...>| should be fetched by first
checking for "...whatever..." in the external area, and then -- if
that fails -- also checking for "...whatever..." in the |ExtnDocs|
subfolder of the built-in area.

For instance, Inform 7 for OS X would look for |inform://Extensions/magic.png|
at the following locations:

(i) |~/Library/Inform/Documentation/magic.png|

(ii) |.../Inform.app/Contents/Resources/ExtnDocs/magic.png|

If no file was found in either place, the link should simply do nothing:
the application is required not to produce a 404 error page, or to
blank out the page currently showing.

@h The "source:" URL scheme.
The other non-standard Inform URL scheme is "source:", which is used
for a link which, when clicked, opens the Source panel with the given
line made visible.

For instance, line 21 of file |Bits and Pieces/marbles.txt| has URL

|source:Bits and Pieces/marbles.txt#line14|

Filenames are given relative to the current project bundle. However, if only
a leafname is supplied, then this is read as a file within the |Source|
subfolder of the project bundle. (Thus it is not possible to have a
source link to a source file at the root of the project bundle: but this is
no loss, since source is not allowed to be kept there.) For instance,
line 14 of file |Source/story.ni| has URL

|source:story.ni#line14|

The following routine writes the clickable source-reference icon, and
is the only place in Inform where "source:" is used.

Source which is generated internally to Inform cannot be opened in the Source
panel, for obvious reasons, so we produce nothing if the location is internal.

=
int source_link_case = 0;
void HTMLFiles::set_source_link_case(text_stream *p) {
	source_link_case = Characters::toupper(Str::get_first_char(p));
}

void HTMLFiles::html_source_link(OUTPUT_STREAM, source_location sl, int nonbreaking_space) {
	if (sl.file_of_origin) {
		TEMPORARY_TEXT(fn);
		WRITE_TO(fn, "%f", TextFromFiles::get_filename(sl.file_of_origin));
		if (Projects::path(Supervisor::project())) {
			TEMPORARY_TEXT(pp);
			WRITE_TO(pp, "%p", Projects::path(Supervisor::project()));
			int N = Str::len(pp);
			if (Str::prefix_eq(fn, pp, N))
				Str::delete_n_characters(fn, N+1);
			DISCARD_TEXT(pp);
		}
		if ((Str::begins_with_wide_string(fn, L"Source")) &&
			(Str::get_at(fn, 6) == FOLDER_SEPARATOR))
			Str::delete_n_characters(fn, 7);
		if (nonbreaking_space) WRITE("&nbsp;"); else WRITE(" ");
		if (source_link_case)
			HTML_OPEN_WITH("a", "href=\"source:%S?case=%c#line%d\"", fn, source_link_case, sl.line_number)
		else
			HTML_OPEN_WITH("a", "href=\"source:%S#line%d\"", fn, sl.line_number);
		HTML_TAG_WITH("img", "border=0 src=inform:/doc_images/Reveal.png");
		HTML_CLOSE("a");
		DISCARD_TEXT(fn);
	}
}

@h Icons with and without tooltips.
Tooltips are the evanescent pop-up windows which appear, a little behind the
mouse arrow, when it is poised waiting over the icon. (We make heavy use of
these in the World index, for instance, to clarify what abbreviations mean.)

=
void HTMLFiles::html_icon_with_tooltip(OUTPUT_STREAM, char *icon_name, char *tip, char *tip2) {
	TEMPORARY_TEXT(img);
	WRITE_TO(img, "border=0 src=inform:/doc_images/%s ", icon_name);
	if (tip) {
		WRITE_TO(img, "title=\"%s", tip); if (tip2) WRITE_TO(img, " %s", tip2); WRITE_TO(img, "\"");
	}
	HTML_TAG_WITH("img", "%S", img);
	DISCARD_TEXT(img);
}

@h Outcome images.
These are the two images used on the Problems page to visually indicate
success or failure. We also use special images on special occasions.

@d CENTRED_OUTCOME_IMAGE_STYLE 1
@d SIDE_OUTCOME_IMAGE_STYLE 2

=
int outcome_image_style = SIDE_OUTCOME_IMAGE_STYLE;

void HTMLFiles::html_outcome_image(OUTPUT_STREAM, char *image, char *verdict) {
	char *vn = "";
	int be_festive = TRUE;
	#ifdef CORE_MODULE
	if (Problems::Issue::internal_errors_have_occurred() == FALSE) be_festive = FALSE;
	#endif
	if (be_festive) {
		switch (Time::feast()) {
			case CHRISTMAS_FEAST: vn = "_2"; break;
			case EASTER_FEAST: vn = "_3"; break;
		}
		if (vn[0]) outcome_image_style = CENTRED_OUTCOME_IMAGE_STYLE;
	}
	#ifdef PROBLEMS_MODULE
	Problems::Issue::issue_problems_banner(OUT, verdict);
	#endif
	switch (outcome_image_style) {
		case CENTRED_OUTCOME_IMAGE_STYLE:
			HTML_OPEN("p");
			HTML_OPEN("center");
			HTML_TAG_WITH("img", "src=inform:/outcome_images/%s%s.png border=0", image, vn);
			HTML_CLOSE("center");
			HTML_CLOSE("p");
			break;
		case SIDE_OUTCOME_IMAGE_STYLE:
			HTML::begin_html_table(OUT, NULL, TRUE, 0, 4, 0, 0, 0);
			HTML::first_html_column(OUT, 110);
			HTML_TAG_WITH("img",
				"src=inform:/outcome_images/%s%s@2x.png border=1 width=100 height=100", image, vn);
			HTML::next_html_column(OUT, 0);
			break;
	}
	HTML::comment(OUT, I"HEADNOTE");
	HTML_OPEN_WITH("p", "style=\"margin-top:0;\"");
	WRITE("(Each time <b>Go</b> or <b>Replay</b> is clicked, Inform tries to "
		"translate the source text into a working story, and updates this report.)");
	HTML_CLOSE("p");
	HTML::comment(OUT, I"PROBLEMS BEGIN");
}

void HTMLFiles::outcome_image_tail(OUTPUT_STREAM) {
	if (outcome_image_style == SIDE_OUTCOME_IMAGE_STYLE) {
		HTML::comment(OUT, I"PROBLEMS END");
		HTML::end_html_row(OUT);
		HTML::end_html_table(OUT);
		HTML::comment(OUT, I"FOOTNOTE");
	}
}

@h Header and footer.

=
void HTMLFiles::html_header(OUTPUT_STREAM, text_stream *title) {
	HTML::declare_as_HTML(OUT, FALSE);
	HTML::begin_head(OUT, NULL);
	HTML::incorporate_CSS(OUT,
		Supervisor::file_from_installation(CSS_FOR_STANDARD_PAGES_IRES));
	HTML::incorporate_javascript(OUT, TRUE,
		Supervisor::file_from_installation(JAVASCRIPT_FOR_STANDARD_PAGES_IRES));
	#ifdef INDEX_MODULE
	Index::scripting(OUT);
	#endif
	HTML::end_head(OUT);
	HTML::begin_body(OUT, NULL);
	HTML::comment(OUT, I"CONTENT BEGINS");
}

void HTMLFiles::html_footer(OUTPUT_STREAM) {
	WRITE("\n");
	HTML::comment(OUT, I"CONTENT ENDS");
	HTML::end_body(OUT);
}

@h HTML paragraphs with indentation.

=
void HTMLFiles::open_para(OUTPUT_STREAM, int depth, char *class) {
	int margin = depth;
	if (margin < 1) internal_error("minimal HTML indentation is 1");
	if (margin > 9) margin = 9;
	HTML_OPEN_WITH("p", "class=\"%sin%d\"", class, margin);
	while (depth > 9) { depth--; WRITE("&nbsp;&nbsp;&nbsp;&nbsp;"); }
}

@h Writing HTML characters.
The following routine is a low-level filter which takes ISO Latin-1
characters one at a time, feeding them out to the given stream with any
unsafe characters converted to suitable HTML elements. (The stream writer
will transcode to UTF-8 encoding, since all HTML file streams written by
Inform are declared as having the UTF-8 character encoding.)

Recall that a source reference is fed into |HTMLFiles::char_out| as the
following stream of characters:

|*source text*Source/story.ni*14*|

(with |SOURCE_REF_CHAR| used in place of the asterisk).

When we notice the trigger character, we cease to output HTML and instead
buffer up the reference until we reach the terminating trigger character:
we then parse a little, tidy up and send it to |HTMLFiles::html_source_link| to be
turned into a |source:| link.

=
text_stream *source_ref_fields[3] = { NULL, NULL, NULL }; /* paraphrase, filename, line */
int source_ref_field = -1; /* which field we are buffering */

void HTMLFiles::char_out(OUTPUT_STREAM, int charcode) {
	if (source_ref_field >= 0) {
		if (source_ref_fields[source_ref_field] == NULL) source_ref_fields[source_ref_field] = Str::new();
		#ifdef PROBLEMS_MODULE
		if (charcode != SOURCE_REF_CHAR) { PUT_TO(source_ref_fields[source_ref_field], charcode); return; }
		#endif
		#ifndef PROBLEMS_MODULE
			PUT_TO(source_ref_fields[source_ref_field], charcode); return;
		#endif
	}
	switch(charcode) {
		case '"': WRITE("&quot;"); return;
		case '<': WRITE("&lt;"); return;
		case '>': WRITE("&gt;"); return;
		case '&': WRITE("&amp;"); break;
		case NEWLINE_IN_STRING: HTML_TAG("br"); return;
		#ifdef PROBLEMS_MODULE
		case FORCE_NEW_PARA_CHAR: HTML_CLOSE("p"); HTML_OPEN_WITH("p", "class=\"in2\"");
			HTMLFiles::html_icon_with_tooltip(OUT, "ornament_flower.png", NULL, NULL);
			WRITE("&nbsp;"); return;
		case SOURCE_REF_CHAR:
			source_ref_field++;
			if (source_ref_field == 3) {
				source_ref_field = -1;
				source_location sl;
				sl.file_of_origin = TextFromFiles::filename_to_source_file(source_ref_fields[1]);
				sl.line_number = Str::atoi(source_ref_fields[2], 0);
				HTMLFiles::html_source_link(OUT, sl, TRUE);
			} else Str::clear(source_ref_fields[source_ref_field]);
			return;
		#endif
		default:
			PUT(charcode);
			return;
	}
}

@h Writing streams in XML-escaped form.

=
void HTMLFiles::write_xml_safe_text(OUTPUT_STREAM, text_stream *txt) {
	LOOP_THROUGH_TEXT(pos, txt) {
		wchar_t c = Str::get(pos);
		switch(c) {
			case '&': WRITE("&amp;"); break;
			case '<': WRITE("&lt;"); break;
			case '>': WRITE("&gt;"); break;
			default: PUT(c); break;
		}
	}
}
