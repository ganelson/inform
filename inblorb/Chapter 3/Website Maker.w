[Websites::] Website Maker.

To accompany a release with a mini-website.

@h Landmarks in the source.
Making a website is not especially tricky. The difficult part is typesetting
the source text into it, if that's been requested. We will need to do that by
scanning the source text for typographically significant structures:

@d ABBREVIATED_HEADING_LENGTH 1000

=
typedef struct table {
	int table_line_start; /* line number in the source where the table heading appears */
	int table_line_end; /* line number of the blank line which marks the end of the table body */
	MEMORY_MANAGEMENT
} table;

typedef struct heading {
	int heading_line; /* line number in the source at which the heading appears */
	int heading_level; /* a low number makes this a more significant heading than a high number */
	int heading_has_content; /* is there anything other than white space before the next heading? */
	struct segment *heading_to_segment; /* which segment contains the heading */
	struct text_stream *heading_text;
	MEMORY_MANAGEMENT
} heading;

@ Segments are used to divide the source text into pieces of what we hope will
be a manageable size.

It is not true that the source text is partitioned exactly by segments. The
topmost segment begins at the first heading in the source text. So there
will usually be at least a few prefatory lines before this point -- perhaps
the title, some extension inclusions, and so on -- and it's even possible,
if there are no headings at all, for there to be no segments so that the
entire source text is "prefatory". If we have three segments, then, we
will split the source text into four HTML files:

|source0.html| -- "Page 1 of 4", the preface and then contents

|source1.html| -- "Page 2 of 4", first segment (with allocation ID 0)

|source2.html| -- "Page 3 of 4", second segment (with allocation ID 1)

|source3.html| -- "Page 4 of 4", third segment (with allocation ID 2)

Note that the prefatory lines contain no headings, that every heading
belongs to a unique segment (hence the |heading_to_segment| field above)
and that the top line of every segment is always a heading. A single
segment can contain multiple headings, because we run on a heading if it
contains no content except white space: this is so that, e.g.,

>> Part I - Up the Amazon
>> Section I.1 - The lower delta
>> Rickety Jetty is a room. [...]

would be combined into a single segment, rather than a pointlessly short
segment just containing the "Part I" heading followed by a second segment
opening with "Section I.1".

=
typedef struct segment {
	int begins_at; /* line number on which the segment begins */
	int ends_at; /* line number of the last line of the segment, or |MAX_SOURCE_TEXT_LINES| if it runs to the end */
	int documentation; /* is this in the documentation of an extension? */
	struct text_file_position start_position_in_file; /* within the source text */
	struct heading *most_recent_heading; /* or |NULL| if there hasn't been one */
	struct table *most_recent_table; /* or |NULL| if there hasn't been one */
	struct text_stream *segment_url;
	struct text_stream *link_home;
	struct text_stream *link_contents;
	struct text_stream *link_previous;
	struct text_stream *link_next;
	int page_number;
	MEMORY_MANAGEMENT
} segment;

@h Styling with CSS.
We try to give the template files as much freedom as possible to define
whatever CSS styles they need, but the template can't see inside the text of
variables, so Inblorb itself has to choose CSS styles for anything interesting
that is displayed there. We use the following style names, which a CSS file
is required to define:

(a) |columnhead| -- the heading of a column in a Table in I7 source text
(b) |comment| -- comments in I7 source text
(c) |filetype| -- the "(pdf, 150KB)" text annotating links
(d) |heading| -- heading or top line of a Table in I7 source text
(e) |i6code| -- verbatim I6 code in I7 source text
(f) |notecue| -- footnote cues which annotate I7 source text
(g) |notesheading| -- the little "Notes" subheading above the footnotes to source text
(h) |notetext| -- texts of footnotes which annotate I7 source text
(i) |quote| -- double-quoted text in I7 source text
(j) |substitution| -- text substitution inside double-quoted text in I7 source text

In addition it must provide paragraph classes |indent0| to |indent9| for code
which begins at tab positions 0 to 9 (see below). Although "Standard.css"
contains other names of classes, these are only needed because "Standard.html"
or "Standard-Source.html" say so: Inblorb does not mandate them.

@ In case CSS is not available, we use old-fashioned HTML alternatives:

=
void Websites::open_style(OUTPUT_STREAM, char *new) {
	if (new == NULL) return;
	if (use_css_code_styles) {
		WRITE("<span class=\"%s\">", new);
	} else {
		if (strcmp(new, "columnhead") == 0) WRITE("<u>");
		if (strcmp(new, "comment") == 0) WRITE("<font color=#404040>");
		if (strcmp(new, "filetype") == 0) WRITE("<small>");
		if (strcmp(new, "heading") == 0) WRITE("<b>");
		if (strcmp(new, "i6code") == 0) WRITE("<font color=#909090>");
		if (strcmp(new, "notecue") == 0) WRITE("<font color=#404040><sup>");
		if (strcmp(new, "notesheading") == 0) WRITE("<i>");
		if (strcmp(new, "notetext") == 0) WRITE("<font color=#404040>");
		if (strcmp(new, "quote") == 0) WRITE("<font color=#000080>");
		if (strcmp(new, "substitution") == 0) WRITE("<font color=#000080>");
	}
}

void Websites::close_style(OUTPUT_STREAM, char *old) {
	if (old == NULL) return;
	if (use_css_code_styles) {
		WRITE("</span>");
	} else {
		if (strcmp(old, "columnhead") == 0) WRITE("</u>");
		if (strcmp(old, "comment") == 0) WRITE("</font>");
		if (strcmp(old, "filetype") == 0) WRITE("</small>");
		if (strcmp(old, "heading") == 0) WRITE("</b>");
		if (strcmp(old, "i6code") == 0) WRITE("</font>");
		if (strcmp(old, "notecue") == 0) WRITE("</sup></font>");
		if (strcmp(old, "notesheading") == 0) WRITE("</i>");
		if (strcmp(old, "notetext") == 0) WRITE("</font>");
		if (strcmp(old, "quote") == 0) WRITE("</font>");
		if (strcmp(old, "substitution") == 0) WRITE("</font>");
	}
}

@ In what follows, we will need to have a current typographic style for text,
and may need to change it at any point inside the paragraph. We represent the
current style by the global variable |current_style|, which is either |NULL|
(for ordinary text) or the name of one of the styles above.

=
char *current_style = NULL;

void Websites::change_style(OUTPUT_STREAM, char *new) {
	if (current_style) Websites::close_style(OUT, current_style);
	Websites::open_style(OUT, new);
	current_style = new;
}

@ We also use CSS to manage code indentation, when it's available, since this
can handle hanging indentation much better.

The block of source text displayed on a web page should be framed within:

=
void Websites::open_code(OUTPUT_STREAM) {
	if (use_css_code_styles == FALSE) {
		WRITE("<p>");
	}
}

void Websites::close_code(OUTPUT_STREAM) {
	if (use_css_code_styles == FALSE) {
		WRITE("</p>");
	}
}

@ Each individual paragraph of the source text (which looks like a line to us)
should then be framed within:

=
void Websites::open_code_paragraph(OUTPUT_STREAM, int indentation) {
	if (use_css_code_styles) {
		char *classname = "";
		switch (indentation) {
			case 0: classname = "indent0"; break;
			case 1: classname = "indent1"; break;
			case 2: classname = "indent2"; break;
			case 3: classname = "indent3"; break;
			case 4: classname = "indent4"; break;
			case 5: classname = "indent5"; break;
			case 6: classname = "indent6"; break;
			case 7: classname = "indent7"; break;
			case 8: classname = "indent8"; break;
			default: classname = "indent9"; break;
		}
		WRITE("<p class=\"%s\">", classname);
	} else {
		int i;
		for (i=0; i<indentation; i++) WRITE("&nbsp;&nbsp;&nbsp;&nbsp;");
	}
}

void Websites::close_code_paragraph(OUTPUT_STREAM) {
	if (use_css_code_styles) {
		WRITE("</p>");
	} else {
		WRITE("<br>");
	}
}

@ In the age of CSS, old-fashioned elements like |halign| for individual table
cells are deprecated, so:

=
void Websites::open_table_cell(OUTPUT_STREAM) {
	if (use_css_code_styles) {
		WRITE("<td>");
	} else {
		WRITE("<td halign=\"left\" valign=\"top\">");
	}
}

void Websites::close_table_cell(OUTPUT_STREAM) {
	if (use_css_code_styles) {
		WRITE("</td>");
	} else {
		WRITE("&nbsp;&nbsp;</td>");
	}
}

@h Making an HTML page from a template.

=
text_stream *COPYTO = NULL;
void Websites::web_copy(filename *from, filename *to) {
	if ((from == NULL) || (to == NULL) || (from == to))
		BlorbErrors::fatal("files confused in website maker");
	text_stream TO_struct;
	COPYTO = &TO_struct;
	if (STREAM_OPEN_TO_FILE(COPYTO, to, UTF8_ENC) == FALSE) {
		BlorbErrors::error_1f("unable to open file to be written for web site", to);
		return;
	}

	HTML_pages_created++;
	TextFiles::read(from, FALSE, "can't open template file", FALSE, Websites::copy_html_line, 0, NULL);

	STREAM_CLOSE(COPYTO);
	COPYTO = NULL;
}

@ Each line in turn comes here, then.

For this to work we rely on the source template containing a |</head>| tag,
in exactly that casing and spacing, but that's safe enough for the templates
used by Inform.

=
void Websites::copy_html_line(text_stream *line, text_file_position *tfp, void *state) {
	Websites::copy_html_line_r(line, tfp, state);
	PUT_TO(COPYTO, '\n');
}

void Websites::copy_html_line_r(text_stream *line, text_file_position *tfp, void *state) {
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, line, L"(%c*?)%[(%c*?)%](%c*)")) {
		Websites::copy_html_line_r(mr.exp[0], tfp, state);
		Placeholders::write(COPYTO, mr.exp[1]);
		Websites::copy_html_line_r(mr.exp[2], tfp, state);
		Regexp::dispose_of(&mr);
		return;
	}
	if (Regexp::match(&mr, line, L"(%c*?)</head>(%c*)")) {
		Websites::copy_html_line_r(mr.exp[0], tfp, state);
		Placeholders::write(COPYTO, I"INTERPRETERSCRIPTS");
		WRITE_TO(COPYTO, "</head>");
		Websites::copy_html_line_r(mr.exp[1], tfp, state);
		Regexp::dispose_of(&mr);
		return;
	}
	WRITE_TO(COPYTO, "%S", line);
}

@h Rendering the source text as HTML pages.
This is a fiddly operation, which requires us to parse the source text and
then typeset it appealingly in a whole suite of HTML pages. This necessarily
involves loops, but our main aim is to complete the process in $O(N)$
running time, where $N$ is the number of lines in the source text. (Note
that the number of HTML files to be written will also be $O(N)$.)

This is done in two passes. On pass 1, we scan the source text for tables
and headings, and divide the whole into "segments", each of which is
typeset as a single HTML page: segments do not quite correspond to headings,
as we shall see. But we write nothing. On pass 2, we actually write these
HTML pages.

=
filename *source_text = NULL;

void Websites::web_copy_source(filename *template, pathname *website_pathname) {
	source_text = Filenames::from_text(Placeholders::read(I"SOURCELOCATION"));
	Websites::scan_source_text();
	Websites::write_source_text_pages(template, website_pathname);
}

@h Pass 1: scanning the source for tables and headings.
During this scan, we will maintain the following variables:

=
int within_a_table; /* are we inside a Table declaration in the source text? */
int scan_quoted_matter; /* are we inside double-quoted matter in the source text? */
int scan_comment_nesting; /* level of nesting of comments in source text: 0 means "not in a comment" */
text_file_position *latest_line_position; /* |ftell|-reported byte offset of the start of the current line in the source */
table *current_table; /* the Table which started most recently, or |NULL| if none has */
heading *current_heading; /* the heading seen most recently, or |NULL| if none has been */
segment *current_segment; /* the segment which started most recently, or |NULL| if none has */
int position_of_documentation_bar; /* line count of the |---- Documentation ----| line, if there is one */

@ Pass 1 has running time $O(N)$ since it calls |Websites::scan_source_line| exactly once
for each line in the source, and |Websites::scan_source_line| looks only at a single line
and at the current table, heading and segment.

@d MAX_SOURCE_TEXT_LINES 2000000000; /* enough for 300 copies of the Linux kernel source -- plenty! */

=
void Websites::scan_source_text(void) {
	within_a_table = FALSE;
	scan_comment_nesting = 0;
	scan_quoted_matter = FALSE;
	latest_line_position = NULL;
	current_table = NULL;
	current_heading = NULL;
	current_segment = NULL;
	position_of_documentation_bar = MAX_SOURCE_TEXT_LINES;

	TextFiles::read(source_text, FALSE, "can't open source text of project", TRUE, Websites::scan_source_line, NULL, NULL);
	@<Adjust heading levels downwards as far as we can without losing relative hierarchy@>;
}

@ Suppose our source contains only headings at levels 3 and 4: we can reduce these
to levels 0 and 1 without disturbing their relative importance, and that makes it
easier for us to typeset them in a sensible way -- there's no point making any
typographic allowance for three sizes of headings greater than are found anywhere
in the source text.

@<Adjust heading levels downwards as far as we can without losing relative hierarchy@> =
	int minhl = 10;
	heading *h;
	LOOP_OVER(h, heading)
		if (h->heading_level < DOC_LEVEL)
			if (h->heading_level < minhl)
				minhl = h->heading_level;
	LOOP_OVER(h, heading)
		if (h->heading_level < DOC_LEVEL)
			h->heading_level -= minhl;

@ Here we scan each single line. (Lines to us may look like whole paragraphs
to the Inform user; we're dealing with gaps between explicit line break
characters.)

=
void Websites::scan_source_line(text_stream *line, text_file_position *tfp, void *state) {
	int lc = TextFiles::get_line_count(tfp), lv = DULL_LEVEL;
	latest_line_position = tfp;
	if (scan_quoted_matter == FALSE)
		@<Look at the first word on the line to find the level of our interest@>;
	if ((scan_comment_nesting > 0) && (lv != EMPTY_LEVEL)) lv = DULL_LEVEL;
	@<Correct the comment nesting level ready for next time@>;
	if ((lv == DULL_LEVEL) && (current_heading)) current_heading->heading_has_content = TRUE;
	if ((lv == EMPTY_LEVEL) && (within_a_table)) @<End a table here and return@>;
	if (lv == TABLE_LEVEL) @<Start a new table here and return@>;
	if ((lv == EMPTY_LEVEL) || (lv == DULL_LEVEL)) return;
	if (lv == DOC_LEVEL) position_of_documentation_bar = lc;
	@<Place a new heading here@>;
}

@ Looking at the first word, if any, tells whether we are a heading, or the start
of a table, or an empty line, or none of these (in which case a line is perhaps
unfairly called "dull"). We set |lv| accordingly.

@d EMPTY_LEVEL -1
@d DULL_LEVEL 0
@d TABLE_LEVEL 1000
@d DOC_LEVEL 1001
@d EXAMPLE_LEVEL 1002
@d DOC_CHAPTER_LEVEL 1003
@d DOC_SECTION_LEVEL 1004

@<Look at the first word on the line to find the level of our interest@> =
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, line, L" *")) lv = EMPTY_LEVEL;
	else if (Regexp::match(&mr, line, L" *(%C+)%c*?")) {
		if (Str::eq_wide_string(mr.exp[0], L"table")) lv = TABLE_LEVEL;
		if (lc > position_of_documentation_bar) {
			if (Str::eq_wide_string(mr.exp[0], L"chapter:")) lv = DOC_CHAPTER_LEVEL;
			if (Str::eq_wide_string(mr.exp[0], L"section:")) lv = DOC_SECTION_LEVEL;
			if (Str::eq_wide_string(mr.exp[0], L"example:")) lv = EXAMPLE_LEVEL;
		} else {
			if (Str::eq_wide_string(mr.exp[0], L"volume")) lv = 1;
			if (Str::eq_wide_string(mr.exp[0], L"book")) lv = 2;
			if (Str::eq_wide_string(mr.exp[0], L"part")) lv = 3;
			if (Str::eq_wide_string(mr.exp[0], L"chapter")) lv = 4;
			if (Str::eq_wide_string(mr.exp[0], L"section")) lv = 5;
			if (Regexp::match(&mr, line, L" *---- documentation ---- *")) lv = DOC_LEVEL;
		}
	}
	Regexp::dispose_of(&mr);

@<Correct the comment nesting level ready for next time@> =
	LOOP_THROUGH_TEXT(P, line) {
		if (Str::get(P) == '[') scan_comment_nesting++;
		if (Str::get(P) == ']') scan_comment_nesting--;
		if ((scan_comment_nesting == 0) && (Str::get(P) == '\"'))
			scan_quoted_matter = (scan_quoted_matter)?FALSE:TRUE;
	}

@<Start a new table here and return@> =
	current_table = CREATE(table);
	current_table->table_line_start = lc;
	current_table->table_line_end = MAX_SOURCE_TEXT_LINES;
	within_a_table = TRUE;
	return;

@<End a table here and return@> =
	current_table->table_line_end = lc;
	within_a_table = FALSE;
	return;

@<Place a new heading here@> =
	heading *new_h = CREATE(heading);
	new_h->heading_text = Str::duplicate(line);
	new_h->heading_level = lv;
	new_h->heading_line = lc;
	new_h->heading_has_content = FALSE;
	if ((current_heading == NULL) || (current_heading->heading_has_content) ||
		(lv == DOC_LEVEL)) {
		if (current_segment) current_segment->ends_at = lc - 1;
		current_segment = CREATE(segment);
		current_segment->begins_at = lc;
		current_segment->ends_at = MAX_SOURCE_TEXT_LINES;
		current_segment->start_position_in_file = *latest_line_position;
		current_segment->most_recent_heading = current_heading;
		current_segment->most_recent_table = current_table;
		current_segment->documentation = FALSE;
		if (lc >= position_of_documentation_bar) current_segment->documentation = TRUE;
	}
	new_h->heading_to_segment = current_segment;
	current_heading = new_h;

@h Pass 2: writing the source text pages.
Though there is no obvious way that the following routine passes control
to the routines below it, in fact it does: |Websites::web_copy| works on the template
and finds reserved variables such as "[SOURCE]"; expanding those then calls
the routines below.

=
segment *segment_being_written = NULL;
int no_doc_files = 0, no_src_files = 0;

void Websites::write_source_text_pages(filename *template, pathname *website_pathname) {
	TEMPORARY_TEXT(contents_leafname);
	WRITE_TO(contents_leafname, "%S.html", Placeholders::read(I"SOURCEPREFIX"));
	filename *contents_page = Filenames::in_folder(website_pathname, contents_leafname);
	DISCARD_TEXT(contents_leafname);

	@<Devise URLs for the segments@>;
	@<Work out how the segments link together@>;
	@<Generate the prefatory page, which isn't a segment@>;
	@<Generate the segment pages@>;
}

@ Calling these URLs is a bit grand, since they are only leafnames. The
source segments have pages |source_0.html| and so on up; the documentation
pages |doc_0.html| and so on up.

@<Devise URLs for the segments@> =
	segment *seg;
	LOOP_OVER(seg, segment) {
		segment_being_written = seg;
		if (seg->documentation) {
			Str::clear(seg->segment_url);
			WRITE_TO(seg->segment_url, "doc_%d.html", no_doc_files++);
			seg->page_number = no_doc_files;
		} else {
			Str::clear(seg->segment_url);
			WRITE_TO(seg->segment_url, "%S_%d.html",
				Placeholders::read(I"SOURCEPREFIX"), no_src_files++);
			seg->page_number = no_src_files;
		}
	}

@<Work out how the segments link together@> =
	segment *seg, *first_doc_seg = NULL, *first_src_seg = NULL;
	LOOP_OVER(seg, segment) {
		if (seg->documentation) {
			seg->link_home = NULL;
			seg->link_contents = NULL;
			seg->link_previous = NULL;
			seg->link_next = NULL;
			if (first_doc_seg == NULL) first_doc_seg = seg;
		} else {
			seg->link_home = NULL;
			seg->link_contents = NULL;
			seg->link_previous = NULL;
			seg->link_next = NULL;
			if (first_src_seg == NULL) {
				first_src_seg = seg;
				seg->link_previous = contents_leafname;
			}
		}
	}
	LOOP_OVER(seg, segment) {
		if (seg->documentation) {
			seg->link_home = I"index.html";
			seg->link_contents = first_doc_seg->segment_url;
		} else {
			seg->link_home = I"index.html";
			seg->link_contents = contents_leafname;
		}
		segment *before = seg;
		while (TRUE) {
			before = PREV_OBJECT(before, segment);
			if (before == NULL) break;
			if (before->documentation == seg->documentation) {
				seg->link_previous = before->segment_url; break;
			}
		}
		segment *after = seg;
		while (TRUE) {
			after = NEXT_OBJECT(after, segment);
			if (after == NULL) break;
			if (after->documentation == seg->documentation) {
				seg->link_next = after->segment_url; break;
			}
		}
	}

@<Generate the prefatory page, which isn't a segment@> =
	segment_being_written = NULL;
	source_HTML_pages_created++;
	Websites::web_copy(template, contents_page);

@<Generate the segment pages@> =
	segment *seg;
	LOOP_OVER(seg, segment) {
		filename *segment_page = Filenames::in_folder(website_pathname, seg->segment_url);
		segment_being_written = seg;
		source_HTML_pages_created++;
		Websites::web_copy(template, segment_page);
		segment_being_written = NULL;
	}

@ This is what "[PAGENUMBER]" in the template becomes.

=
void Websites::expand_PAGENUMBER_variable(OUTPUT_STREAM) {
	int p = 1;
	if (segment_being_written) {
		p = segment_being_written->page_number;
		if (segment_being_written->documentation == FALSE) p++; /* allow for header page */
	}
	WRITE_TO(COPYTO, "%d", p);
}

@ And similarly "[PAGEEXTENT]".

=
void Websites::expand_PAGEEXTENT_variable(OUTPUT_STREAM) {
	int n = no_src_files + 1;
	if ((segment_being_written) && (segment_being_written->documentation))
		n = no_doc_files;
	if (n == 0) n = 1;
	WRITE_TO(COPYTO, "%d", n);
}

@ And this is what "[SOURCELINKS]" in the template becomes:

=
void Websites::expand_SOURCELINKS_variable(OUTPUT_STREAM) {
	segment *seg = segment_being_written;
	if (seg) {
		if (seg->link_home)
			WRITE_TO(COPYTO, "<li><a href=\"%S\">Home page</a></li>", seg->link_home);
		if (seg->link_contents)
			WRITE_TO(COPYTO, "<li><a href=\"%S\">Beginning</a></li>", seg->link_contents);
		if (seg->link_previous)
			WRITE_TO(COPYTO, "<li><a href=\"%S\">Previous</a></li>", seg->link_previous);
		if (seg->link_next)
			WRITE_TO(COPYTO, "<li><a href=\"%S\">Next</a></li>", seg->link_next);
	} else {
		WRITE_TO(COPYTO, "<li><a href=\"index.html\">Home page</a></li>");
		WRITE_TO(COPYTO, "<li><a href=\"%S.txt\">Complete text</a></li>",
			Placeholders::read(I"SOURCEPREFIX"));
	}
}

@ When working on "[SOURCE]" or "[SOURCENOTES]", we will need to run
through a segment of the source text, one line at a time. As we do so, we'll
maintain the following variables, along with |current_style| (for which
see the CSS discussion above):

=
text_stream *SPAGE = NULL; /* where the output is going */
int SOURCENOTES_mode = FALSE; /* |TRUE| for "[SOURCENOTES]", |FALSE| for "[SOURCE]" */
int quoted_matter = FALSE; /* are we inside double-quoted matter in the source text? */
int i6_matter = FALSE; /* are we inside verbatim I6 code in the source text? */
int comment_nesting = 0; /* nesting level of comments in source text being read: 0 for not in a comment */
int footnote_comment_level = 0; /* ditto, but where the outermost comment is a footnote marker */
int carry_over_indentation = -1; /* indentation carried over for para breaks in quoted text */
int next_footnote_number = 1; /* number to assign to the next footnote which comes up */
heading *latest_heading = NULL; /* a heading which is always behind the current position */
table *latest_table = NULL; /* a table which is always behind the current position */

@ So this is "[SOURCE]" (if |noting_mode| is |FALSE|) or "[SOURCENOTES]"
(if |TRUE|).

=
void Websites::expand_SOURCE_or_SOURCENOTES_variable(OUTPUT_STREAM, int SN) {
	if (SN) @<Typeset the little Notes subheading@>;
	Websites::open_code(OUT);
	@<Initialise the variables to their state at the start of an HTML page@>;
	@<Read the source text and feed it one line at a time to the line-writer@>;
	Websites::close_code(OUT);
}

@ So at the start of the preface or of any segment:

@<Initialise the variables to their state at the start of an HTML page@> =
	next_footnote_number = 1;
	SPAGE = OUT;
	SOURCENOTES_mode = SN;
	quoted_matter = FALSE;
	i6_matter = FALSE;
	comment_nesting = 0;
	footnote_comment_level = 0;
	carry_over_indentation = -1;
	current_style = NULL;
	latest_heading = FIRST_OBJECT(heading);
	latest_table = FIRST_OBJECT(table);

@ We expect any use of "[SOURCENOTES]" to come after the relevant
"[SOURCE]", so that looking at |next_footnote_number| will tell us how many
notes there were.

@<Typeset the little Notes subheading@> =
	if (next_footnote_number == 1) return; /* there were no footnotes at all */
	WRITE("<p>");
	Websites::open_style(OUT, "notesheading");
	if (next_footnote_number == 2) WRITE("Note"); /* just one */
	else WRITE("Notes"); /* more than one */
	Websites::close_style(OUT, "notesheading");
	WRITE("</p>\n");

@ We want to be very careful about running time here. This paragraph will
run about $H$ times, where $H$ is the number of headings (in fact at most $H+1$
times and usually a little less); but we might reasonably expect that $H$
is proportional to $N$, since there's typically a heading every 30 or so
lines in the source text, so that H is about N/30. If we then did the simplest
thing, of opening the source text file and sending every line to
|Websites::write_source_line|, we would make $O(N^2)$ calls, and even though many of
those would quickly return it would be an expensive algorithm.

Instead, we start at the relevant position in the source text for the
current HTML page, and we stop the moment that |Websites::write_source_line| reports
that it has gone past the material of interest. We thus make at most $N+H$
calls to |Websites::write_source_line| (the extra $H$ calls being for one overspill line
per segment, where we realise that we've gone too far).

@<Read the source text and feed it one line at a time to the line-writer@> =
	text_file_position *start = NULL;
	if (segment_being_written) @<Start from just the right place in the source file@>;
	TextFiles::read(source_text, FALSE, "can't open source text", TRUE, Websites::source_write_iterator, start, NULL);

@ The following simulates the effect of running through the uninteresting lines
before the segment begins:

@<Start from just the right place in the source file@> =
	start = &(segment_being_written->start_position_in_file);
	if (segment_being_written->most_recent_heading)
		latest_heading = segment_being_written->most_recent_heading;
	if (segment_being_written->most_recent_table)
		latest_table = segment_being_written->most_recent_table;

@ =
void Websites::source_write_iterator(text_stream *line, text_file_position *tfp, void *state) {
	int done_yet = Websites::write_source_line(line, tfp);
	if (done_yet) TextFiles::lose_interest(tfp);
}

@ And this is where we write lines. We arrive here with exactly the same line
count as the scanner observed before on pass 1, so we can validly compare
our current line count against those stored for tables, headings and segments.

When this routine returns |TRUE|, it signals that there is no further need for
the source text, and that saves reading in all of the remaining lines which
won't be needed.

=
int Websites::write_source_line(text_stream *line, text_file_position *tfp) {
	int line_count = TextFiles::get_line_count(tfp);
	if (segment_being_written == NULL) @<Filter out lines for the preface@>
	else @<Filter out lines for the segments@>;
	if (SOURCENOTES_mode) @<Typeset the line in [SOURCENOTES] mode@>
	else @<Typeset the line in [SOURCE] mode@>;
	return FALSE;
}

@ Recall that the source text is divided into an initial portion containing
no headings -- the "preface" -- and then segments, each of which begins with
a heading.

Here we are handling the case of typesetting the preface. We allow the line
to appear as normal if it is before the first segment; once we reach the
first segment -- if there's a first segment to reach -- we then typeset the
contents listing. (If there's no first segment, then there are no headings,
and there's no need for a contents listing.) If we've output the contents
listing then we are finished writing the preface and don't need to read the
source text further, so we return |TRUE|.

@<Filter out lines for the preface@> =
	segment *first_segment = FIRST_OBJECT(segment);
	if ((first_segment) && (line_count == first_segment->begins_at - 1) && (Str::len(line) == 0))
		return FALSE; /* don't bother to typeset a blank line just before the first segment is reached */

	if ((first_segment) && (line_count == first_segment->begins_at)) {
		if (SOURCENOTES_mode == FALSE) Websites::typeset_contents_listing(TRUE);
		return TRUE;
	}

@ The segment pages are easier: in this case we allow the line only if it
lies inside the segment, and otherwise suppress it. Once we've gone beyond
the segment, we don't need to read any further, so we return |TRUE|.

@<Filter out lines for the segments@> =
	if (line_count < segment_being_written->begins_at) return FALSE;
	if (line_count > segment_being_written->ends_at) return TRUE;
	if (line_count == position_of_documentation_bar + 1)
		Websites::typeset_contents_listing(FALSE);

@ In [SOURCENOTES] mode, we detect footnotes in the form of comments in the
source text marked by asterisks; each one is assigned the next footnote
number, and typeset. All other material is ignored.

@<Typeset the line in [SOURCENOTES] mode@> =
	int i, L = Str::len(line);
	for (i=0; i<L; i++) {
		if ((Str::get_at(line, i) == '[') && (Str::get_at(line, i+1) == '*')) {
			footnote_comment_level = 1;
			WRITE_TO(SPAGE, "<p><a name=\"note%d\"></a>", next_footnote_number);
			Websites::open_style(SPAGE, "notetext");
			WRITE_TO(SPAGE, "<a href=\"#note%dref\">[%d]</a>. ",
				next_footnote_number, next_footnote_number);
			next_footnote_number++;
			i+=2;
		}
		if (footnote_comment_level > 0) {
			if (Str::get_at(line, i) == '[') footnote_comment_level++;
			if (Str::get_at(line, i) == ']') footnote_comment_level--;
			if (footnote_comment_level == 0) {
				Websites::close_style(SPAGE, "notetext");
				WRITE_TO(SPAGE, "</p>\n");
			} else {
				WRITE_TO(SPAGE, "%c", Str::get_at(line, i));
			}
		}
	}
	if (footnote_comment_level > 0) WRITE_TO(SPAGE, " ");

@ In [SOURCE] mode, we need to work out appropriate type styles to embellish
the line, then indent it suitably, then typeset it character by character.

@<Typeset the line in [SOURCE] mode@> =
	int embolden = FALSE, tabulate = FALSE, underline = FALSE;
	@<Decide any typographic embellishments due to the line falling inside a table@>;
	@<The top line of the preface or any segment is in bold@>;
	@<Any heading line is in bold@>;

	if ((tabulate) && (quoted_matter == FALSE)) { WRITE_TO(SPAGE, "<tr>"); Websites::open_table_cell(SPAGE); }

	int start = 0;

	if (footnote_comment_level > 0) {
		for (; Str::get_at(line, start); start++) {
			if (Str::get_at(line, start) == '[') footnote_comment_level++;
			if (Str::get_at(line, start) == ']') footnote_comment_level--;
			if (footnote_comment_level == 0) { start++; break; }
		}
	}
	if ((footnote_comment_level == 0) && (Str::get_at(line, start))) {
		if (tabulate == FALSE) {
			int insteps = 0;
			for (; Str::get_at(line, start) == '\t'; start++) insteps++;
			if (carry_over_indentation < 0) carry_over_indentation = insteps;
			Websites::open_code_paragraph(SPAGE, carry_over_indentation);
		}

		@<Begin typographic embellishments@>;
		@<The documentation requires some corrections@>;

		for (int i=start, L=Str::len(line); i<L; i++) @<Typeset a single character of the source text@>;

		@<End typographic embellishments@>;
		if ((tabulate) && (quoted_matter == FALSE)) { Websites::close_table_cell(SPAGE); WRITE_TO(SPAGE, "</tr>\n"); }
		else Websites::close_code_paragraph(SPAGE);
		if (quoted_matter == FALSE) carry_over_indentation = -1;
	}

@ The type styles are easily applied, so let's do that now. The innermost one
must be colour, since that may change in the course of the line.

@<Begin typographic embellishments@> =
	if (underline) Websites::open_style(SPAGE, "columnhead");
	if (embolden) Websites::open_style(SPAGE, "heading");
	if (current_style) Websites::open_style(SPAGE, current_style);

@ And they end in reverse order, so that they nest properly if need be:

@<End typographic embellishments@> =
	if (current_style) Websites::close_style(SPAGE, current_style);
	if (embolden) Websites::close_style(SPAGE, "heading");
	if (underline) Websites::close_style(SPAGE, "columnhead");

@ The heading line of a source text Table is in bold; the column-headings
line is underlined; and the material inside appears in an HTML table, with
|tabulate| mode set.

The |while| loop here needs a careful look, since on the face of it this
could mean $O(N)$ iterations -- since the number of tables is probably
proportional to $N$ -- made in the course of the current "[SOURCE]"
expansion. Since the number of "[SOURCE]" expansions needed to make the
website is also $O(N)$ -- the number of HTML pages in the site is proportional
to the number of headings, which is also proportional to $N$ -- there's a
risk that this |while| loop makes the whole website algorithm $O(N^2)$.
This is why, on each "[SOURCE]" expansion, |latest_table| is initialised
not to the first table but to the most recent one at the start position of
the current HTML page. Moreover, the loop never goes past the current line
count, which never goes outside the range of lines in the current HTML page.
The result is that over the course of all the "[SOURCE]" expansions
combined, the |while| loop here executes $O(N)$ iterations in total.

@<Decide any typographic embellishments due to the line falling inside a table@> =
	while ((latest_table) && (latest_table->table_line_end < line_count))
		latest_table = NEXT_OBJECT(latest_table, table);
	if (latest_table) {
		int from = latest_table->table_line_start, to = latest_table->table_line_end;
		if (line_count == from) {
			embolden = TRUE;
		} else if ((line_count > from) && (line_count < to)) {
			tabulate = TRUE;
			if (line_count == from + 1) {
				underline = TRUE;
				WRITE_TO(SPAGE, "<table>");
			}
		} else if (line_count == to) {
			WRITE_TO(SPAGE, "</table>");
		}
	}

@<The top line of the preface or any segment is in bold@> =
	if ((line_count == 1) ||
		((segment_being_written) && (line_count == segment_being_written->begins_at)))
			embolden = TRUE;

@ See the discussion of |latest_table| above for why the following |while|
loop also doesn't make our algorithm $O(N^2)$.

@<Any heading line is in bold@> =
	while ((latest_heading) && (latest_heading->heading_line < line_count))
		latest_heading = NEXT_OBJECT(latest_heading, heading);
	if ((latest_heading) && (latest_heading->heading_line == line_count))
		embolden = TRUE;

@<The documentation requires some corrections@> =
	if ((comment_nesting == 0) && (quoted_matter == FALSE) && (i6_matter == FALSE) &&
		(Str::get_at(line, start) == '*') && (Str::get_at(line, start+1) == ':') && (Str::get_at(line, start+2) == ' '))
		start += 3;
	if (line_count == position_of_documentation_bar) Str::copy(line, I"Documentation");

@ We need to do two things: ensure that the character is HTML-safe, which
means escaping out |"|, |<|, |>| and |&| (but nothing else since the HTML
file will use a UTF-8 encoding, the same as that in the source text); and
keep track of the opening and closing of comments and quoted matter.

@<Typeset a single character of the source text@> =
	switch (Str::get_at(line, i)) {
		case '\t':
			/* a multiple tab is equivalent to a single tab in Inform source text */
			while (Str::get_at(line, i+1) == '\t') i++;
			@<Typeset a tab@>;
			break;
		case '"':
			if ((comment_nesting > 0) || (i6_matter)) WRITE_TO(SPAGE, "&quot;");
			else @<Typeset a double quotation mark outside of a comment@>;
			break;
		case '[':
			if (quoted_matter) { WRITE_TO(SPAGE, "["); Websites::change_style(SPAGE, "substitution"); }
			else if (i6_matter) WRITE_TO(SPAGE, "[");
			else @<Typeset an open square bracket outside of a string@>;
			break;
		case ']':
			if (quoted_matter) { Websites::change_style(SPAGE, "quote"); WRITE_TO(SPAGE, "]"); }
			else if (i6_matter) WRITE_TO(SPAGE, "]");
			else @<Typeset a close square bracket outside of a string@>;
			break;
		case '(':
			if ((comment_nesting == 0) && (quoted_matter == FALSE) && (i6_matter == FALSE) &&
				(Str::get_at(line, i+1) == '-')) { i++;
				@<Typeset the opening of I6 verbatim code@>
			} else WRITE_TO(SPAGE, "("); break;
		case '-':
			if ((i6_matter) && (Str::get_at(line, i+1) == ')')) { i++;
				@<Typeset the closing of I6 verbatim code@>
			} else WRITE_TO(SPAGE, "-"); break;
		case '<': WRITE_TO(SPAGE, "&lt;"); break;
		case '>': WRITE_TO(SPAGE, "&gt;"); break;
		case '&': WRITE_TO(SPAGE, "&amp;"); break;
		default: WRITE_TO(SPAGE, "%c", Str::get_at(line, i)); break;
	}

@ Inside a source-text Table, a tab moves to the next column, so we need to typeset a
cell boundary in our HTML |<table>|. Outside of that context, a tab is just white
space and we turn it into a single space.

@<Typeset a tab@> =
	if (tabulate) {
		@<End typographic embellishments@>;
		Websites::close_table_cell(SPAGE);
		Websites::open_table_cell(SPAGE);
		@<Begin typographic embellishments@>;
	} else {
		WRITE_TO(SPAGE, " ");
	}

@ The following enters or exits quoted-matter mode, and is structured so that
the quotation marks are not coloured -- only the material inside them.

Our code in handling quoted and comment matter is greatly simplified by the
fact that a valid Inform text cannot contain mismatched square brackets;
however, as Dave Chapeskie points out, a valid comment can contain mismatched
quotation marks, and this section of code benefits from his careful amendments.

@<Typeset a double quotation mark outside of a comment@> =
	if (quoted_matter) Websites::change_style(SPAGE, NULL);
	WRITE_TO(SPAGE, "&quot;");
	if (quoted_matter == FALSE) Websites::change_style(SPAGE, "quote");
	quoted_matter = (quoted_matter)?FALSE:TRUE;

@ On the other hand, the squares around a comment do pick up the colour
of the commentary within them. Asterisked comments must end in the same paragraph
as they begin.

@<Typeset an open square bracket outside of a string@> =
	if (Str::get_at(line, i+1) == '*') {
		/* advance past the end of the asterisked comment */
		footnote_comment_level++;
		for (i+=2, L=Str::len(line); i<L; ++i) {
			if (Str::get_at(line, i) == '[') footnote_comment_level++;
			if (Str::get_at(line, i) == ']') footnote_comment_level--;
			if (footnote_comment_level == 0) break;
		}
		if (Str::get_at(line, i) == 0) i--;
		@<Typeset a footnote cue@>;
	} else {
		comment_nesting++;
		if (comment_nesting == 1) Websites::change_style(SPAGE, "comment");
		WRITE_TO(SPAGE, "[");
	}

@<Typeset a close square bracket outside of a string@> =
	WRITE_TO(SPAGE, "]");
	comment_nesting--;
	if (comment_nesting == 0) Websites::change_style(SPAGE, NULL);

@ Styling applied to I6 verbatim code does not apply to the purely-I7 markers
"(-" and "-)" around it:

@<Typeset the opening of I6 verbatim code@> =
	WRITE_TO(SPAGE, "(-");
	Websites::change_style(SPAGE, "i6code");
	i6_matter = TRUE;

@<Typeset the closing of I6 verbatim code@> =
	Websites::change_style(SPAGE, NULL);
	WRITE_TO(SPAGE, "-)");
	i6_matter = FALSE;

@ The "cue" of a footnote is the reference in the body of the text, which
is conventionally printed as a superscript number. We leave that to the
span |notecue| if we have CSS, and otherwise render in grey superscript.

@<Typeset a footnote cue@> =
	WRITE_TO(SPAGE, "<a name=\"note%dref\"></a>", next_footnote_number);
	Websites::open_style(SPAGE, "notecue");
	WRITE_TO(SPAGE, "<a href=\"#note%d\">[%d]</a>",
		next_footnote_number, next_footnote_number);
	Websites::close_style(SPAGE, "notecue");
	next_footnote_number++;

@ That just leaves the little contents listings -- one for the source, and
another for the documentation (if any).

=
void Websites::typeset_contents_listing(int source_contents) {
	int benchmark_level = (source_contents)?0:DOC_CHAPTER_LEVEL;
	int current_level = benchmark_level-1, new_level;
	heading *h;
	LOOP_OVER(h, heading)
		if (((source_contents) && (h->heading_line < position_of_documentation_bar)) ||
			((source_contents == FALSE) && (h->heading_line > position_of_documentation_bar))) {
			new_level = h->heading_level;
			if (h->heading_level == EXAMPLE_LEVEL) new_level = DOC_CHAPTER_LEVEL;
			@<Open or close UL tags to move to the new heading level@>;
			WRITE_TO(SPAGE, "<li><a href=\"%S\">%S</a></li>\n",
				h->heading_to_segment->segment_url, h->heading_text);
		}
	new_level = benchmark_level-1;
	@<Open or close UL tags to move to the new heading level@>;
}

@ This is how we obtain our nested UL tags: |current_level| starts and ends at
$b-1$, and can only change its value by executing the following loops. Since
it never changes to a value lower than 0 except when returning to $b-1$ at
the end, we are always inside at least the outermost |<ul>|, and since the
net change over the whole process is 0, there must be as many steps upward
as downward -- so every |<ul>| is closed by a matching |</ul>|.

@<Open or close UL tags to move to the new heading level@> =
	while (new_level > current_level) { WRITE_TO(SPAGE, "<ul>"); current_level++; }
	while (new_level < current_level) { WRITE_TO(SPAGE, "</ul>"); current_level--; }
