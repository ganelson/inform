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
where the user has insufficient permissions to alter it. NI itself neither
reads from, nor writes to, any file in the built-in documentation area.

Documentation for the installed extensions does, however, change: it is
written by NI as and when necessary. This is the material making up the
"external" area, and it needs to be somewhere which the user certainly
has the necessary permissions to write to. For instance:

|~/Library/Inform/Documentation/| (OS X)

|My Documents\Inform\Documentation\| (Windows)

Pages in these two areas, built-in and external, need to link to each other by
links: in addition, pages in the external area need access to images stored in
the built-in area.

The other HTML files written by NI are stored within the relevant
project's bundle: these are the report of Problems (if any) and the
Index. They, too, need access to images stored in the built-in area.

The problem we face is that these three mini-websites -- the built-in
documentation, the external documentation, and the project-specific
pages -- are written by tools which cannot know the correct file URLs.
(For instance, it would not even help for the application to tell NI
where the built-in area is: because the HTML written by NI would then
cease to work if the user moved the application elsewhere in the
filing system after NI had run.)

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
is the only place in NI where "source:" is used.

Source which is generated internally to NI cannot be opened in the Source
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
		if (pathname_of_project) {
			TEMPORARY_TEXT(pp);
			WRITE_TO(pp, "%p", pathname_of_project);
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
	if (internal_error_thrown == FALSE) {
		switch (Time::feast()) {
			case CHRISTMAS_FEAST: vn = "_2"; break;
			case EASTER_FEAST: vn = "_3"; break;
		}
		if (vn[0]) outcome_image_style = CENTRED_OUTCOME_IMAGE_STYLE;
	}
	Problems::Issue::issue_problems_banner(OUT, verdict);
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
		Filenames::in_folder(pathname_of_HTML_models, I"main.css"));
	HTML::incorporate_javascript(OUT, TRUE,
		Filenames::in_folder(pathname_of_HTML_models, I"main.js"));
	Index::scripting(OUT);
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
		if (charcode != SOURCE_REF_CHAR) { PUT_TO(source_ref_fields[source_ref_field], charcode); return; }
	}
	switch(charcode) {
		case '"': WRITE("&quot;"); return;
		case '<': WRITE("&lt;"); return;
		case '>': WRITE("&gt;"); return;
		case '&': WRITE("&amp;"); break;
		case NEWLINE_IN_STRING: HTML_TAG("br"); return;
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

@h Bibliographic text.
"Bibliographic text" is text used in bibliographic data about the work
of IF compiled: for instance, in the iFiction record, or in the Library
Card section of the HTML index. Note that the exact output format depends
on global variables, which allow the bibliographic text writing code to
configure NI for its current purposes. On non-empty strings this routine
therefore splits into one of three independent methods.

=
void HTMLFiles::compile_bibliographic_text(OUTPUT_STREAM, wchar_t *p) {
	if (p == NULL) return;
	if (TEST_COMPILATION_MODE(COMPILE_TEXT_TO_XML_CMODE))
		@<Compile bibliographic text as XML respecting Treaty of Babel rules@>;
	if (TEST_COMPILATION_MODE(TRUNCATE_TEXT_CMODE))
		@<Compile bibliographic text as a truncated filename@>;
	if (TEST_COMPILATION_MODE(COMPILE_TEXT_TO_I6_CMODE))
		@<Compile bibliographic text as an I6 string@>
	@<Compile bibliographic text as HTML@>;
}

@ This looks like a standard routine for converting ISO Latin-1 to UTF-8
with XML escapes, but there are a few conventions on whitespace, too, in order
to comply with a strict reading of the Treaty of Babel. (This is intended
for fields in iFiction records.)

@<Compile bibliographic text as XML respecting Treaty of Babel rules@> =
	int i = 0, i2 = Wide::len(p)-1, snl, wsc;
	if ((p[0] == '"') && (p[i2] == '"')) { i++; i2--; } /* omit surrounding double-quotes */
	while (Characters::is_babel_whitespace(p[i])) i++; /* omit leading whitespace */
	while ((i2>=0) && (Characters::is_babel_whitespace(p[i2]))) i2--; /* omit trailing whitespace */
	for (snl = FALSE, wsc = 0; i<=i2; i++) {
		switch(p[i]) {
			case ' ': case '\x0a': case '\x0d': case '\t':
				snl = FALSE;
				wsc++;
				int k = i;
				while ((p[k] == ' ') || (p[k] == '\x0a') || (p[k] == '\x0d') || (p[k] == '\t')) k++;
				if ((wsc == 1) && (p[k] != NEWLINE_IN_STRING)) WRITE(" ");
				break;
			case NEWLINE_IN_STRING:
				if (snl) break;
				WRITE("<br/>");
				snl = TRUE; wsc = 1; break;
			case '[':
				if ((p[i+1] == '\'') && (p[i+2] == ']')) {
					i += 2;
					WRITE("'"); break;
				}
				int n = CompiledText::expand_unisub(OUT, p, i);
				if (n >= 0) { i = n; break; }
				/* and otherwise fall through to the default case */
			default:
				snl = FALSE;
				wsc = 0;
				switch(p[i]) {
					case '&': WRITE("&amp;"); break;
					case '<': WRITE("&lt;"); break;
					case '>': WRITE("&gt;"); break;
					default: PUT(p[i]); break;
				}
				break;
		}
	}
	return;

@ In the HTML version, we want to respect the forcing of newlines, and
also the |[']| escape to obtain a literal single quotation mark.

@<Compile bibliographic text as HTML@> =
	int i, whitespace_count=0;
	if (p[0] == '"') p++;
	for (i=0; p[i]; i++) {
		if ((p[i] == '"') && (p[i+1] == 0)) break;
		switch(p[i]) {
			case ' ': case '\x0a': case '\x0d': case '\t':
				whitespace_count++;
				if (whitespace_count == 1) PUT(' ');
				break;
			case NEWLINE_IN_STRING:
				while (p[i+1] == NEWLINE_IN_STRING) i++;
				PUT('<');
				PUT('p');
				PUT('>');
				whitespace_count = 1;
				break;
			case '[':
				if ((p[i+1] == '\'') && (p[i+2] == ']')) {
					i += 2;
					PUT('\''); break;
				}
				int n = CompiledText::expand_unisub(OUT, p, i);
				if (n >= 0) { i = n; break; }
				/* and otherwise fall through to the default case */
			default:
				whitespace_count = 0;
				PUT(p[i]);
				break;
		}
	}
	return;

@ In the Inform 6 string version, we suppress the forcing of newlines, but
otherwise it's much the same.

@<Compile bibliographic text as an I6 string@> =
	int i, whitespace_count=0;
	if (p[0] == '"') p++;
	for (i=0; p[i]; i++) {
		if ((p[i] == '"') && (p[i+1] == 0)) break;
		switch(p[i]) {
			case ' ': case '\x0a': case '\x0d': case '\t': case NEWLINE_IN_STRING:
				whitespace_count++;
				if (whitespace_count == 1) PUT(' ');
				break;
			case '[':
				if ((p[i+1] == '\'') && (p[i+2] == ']')) {
					i += 2;
					PUT('\''); break;
				} /* and otherwise fall through to the default case */
			default:
				whitespace_count = 0;
				PUT(p[i]);
				break;
		}
	}
	return;

@ This code is used to work out a good filename for something given a name
inside NI. For instance, if a project is called

>> "St. Bartholemew's Fair: \'Etude for a Push-Me/Pull-You Machine"

then what would be a good filename for its released story file?

In the filename version we must forcibly truncate the text to ensure
that it does not exceed a certain length, and must also make it filename-safe,
omitting characters used as folder separators on various platforms and
(for good measure) removing accents from accented letters, so that we can
arrive at a sequence of ASCII characters. Each run of whitespace is also
converted to a single space. If this would result in an empty text or only
a single space, we return the text "story" instead.

Our example (if not truncated) then emerges as:

	|St- Bartholemew's Fair- Etude for a Push-Me-Pull-You Machine|

Note that we do not write any filename extension (e.g., |.z5|) here.

We change possible filename separators or extension indicators to hyphens,
and remove accents from each possible ISO Latin-1 accented letter. This does
still mean that the OE and AE digraphs will simply be omitted, while the
German eszet will be barbarously shortened to a single "s", but life is
just too short to care overmuch about this.

@<Compile bibliographic text as a truncated filename@> =
	int i, pos = STREAM_EXTENT(OUT), whitespace_count=0, black_chars_written = 0;
	int N = 100;
	#ifdef IF_MODULE
	N = BIBLIOGRAPHIC_TEXT_TRUNCATION;
	#endif
	if (p[0] == '"') p++;
	for (i=0; p[i]; i++) {
		if (STREAM_EXTENT(OUT) - pos >= N) break;
		if ((p[i] == '"') && (p[i+1] == 0)) break;
		switch(p[i]) {
			case ' ': case '\x0a': case '\x0d': case '\t': case NEWLINE_IN_STRING:
				whitespace_count++;
				if (whitespace_count == 1) PUT(' ');
				break;
			case '?': case '*':
				if ((p[i+1]) && (p[i+1] != '\"')) PUT('-');
				break;
			default: {
				int charcode = p[i];
				charcode = Characters::make_filename_safe(charcode);
				whitespace_count = 0;
				if (charcode < 128) {
					PUT(charcode); black_chars_written++;
				}
				break;
			}
		}
	}
	if (black_chars_written == 0) WRITE("story");
	return;
