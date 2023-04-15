[InbuildReport::] The Report.

To produce a report page of HTML for use in the Inform GUI apps, when a resource
such as an extension is inspected or installed.

@h HTML page.

=
filename *inbuild_report_HTML = NULL;

void InbuildReport::set_filename(filename *F) {
	inbuild_report_HTML = F;
}

text_stream inbuild_report_file_struct; /* The actual report file */
text_stream *inbuild_report_file = NULL; /* As a |text_stream *| */

text_stream *InbuildReport::begin(text_stream *title, text_stream *subtitle) {
	if (inbuild_report_HTML == NULL) return NULL;
	inbuild_report_file = &inbuild_report_file_struct;
	if (STREAM_OPEN_TO_FILE(inbuild_report_file, inbuild_report_HTML, UTF8_ENC) == FALSE)
		Errors::fatal("can't open report file");
	InformPages::header(inbuild_report_file, title, JAVASCRIPT_FOR_STANDARD_PAGES_IRES, NULL);
	text_stream *OUT = inbuild_report_file;

	HTML::begin_html_table(OUT, NULL, TRUE, 0, 4, 0, 0, 0);
	HTML::first_html_column(OUT, 0);
	HTML_TAG_WITH("img",
		"src='inform:/doc_images/extensions@2x.png' border=0 width=150 height=150");
	HTML::next_html_column(OUT, 0);

	HTML_OPEN_WITH("div", "class=\"headingpanellayout headingpanelalt\"");
	HTML_OPEN_WITH("div", "class=\"headingtext\"");
	HTML::begin_span(OUT, I"headingpaneltextalt");
	WRITE("%S", title);
	HTML::end_span(OUT);
	HTML_CLOSE("div");
	HTML_OPEN_WITH("div", "class=\"headingrubric\"");
	HTML::begin_span(OUT, I"headingpanelrubricalt");
	WRITE("%S", subtitle);
	HTML::end_span(OUT);
	HTML_CLOSE("div");
	HTML_CLOSE("div");

	return OUT;
}

void InbuildReport::end(void) {
	if (inbuild_report_file) {
		text_stream *OUT = inbuild_report_file;
		HTML::end_html_row(OUT);
		HTML::end_html_table(OUT);
		HTML_TAG("hr");
		InformPages::footer(OUT);
	}
	inbuild_report_file = NULL;
}


@ This is used to display HTML within Inform GUI apps, but it does more or less
the same thing as |-inspect| at the command line.

=
void InbuildReport::install(inbuild_copy *C, int confirmed) {
	text_stream *OUT = NULL;
	if ((C->edition->work->genre == extension_genre) ||
		(C->edition->work->genre == extension_bundle_genre)) {
		int N = LinkedLists::len(C->errors_reading_source_text);
		if (N > 0) @<Report on a damaged extension@>
		else @<Report on a valid extension@>;
	} else {
		@<Report on something else@>;
	}
	if (OUT) {
		InbuildReport::end();
	}
}

@<Report on a valid extension@> =
	TEMPORARY_TEXT(desc)
	Editions::inspect(desc, C->edition);
	OUT = InbuildReport::begin(desc, I"An extension for use in Inform projects");
	if (OUT) {
		HTML_OPEN("p");
		WRITE("This looks like a valid extension.");
		HTML_CLOSE("p");
		if (confirmed) {
			WRITE("<p>CONFIRMED - no action implemented yet, though</p>");
		} else {
			HTML_OPEN_WITH("a", "href='javascript:project().confirmAction()'");
			HTML_OPEN_WITH("button", "class=\"safebutton\"");
			WRITE("Click to install to the current project");
			HTML_CLOSE("button");
			HTML_CLOSE("a");
		}
	}

@<Report on a damaged extension@> =
	TEMPORARY_TEXT(desc)
	WRITE_TO(desc, "This may be: ");
	Editions::inspect(desc, C->edition);
	OUT = InbuildReport::begin(I"Warning: Damaged extension", desc);
	if (OUT) {
		HTML_OPEN("p");
		WRITE("This extension is broken, and needs repair before it can be used. ");
		WRITE("Specifically:");
		HTML_CLOSE("p");
		Copies::list_attached_errors_to_HTML(OUT, C);
		HTML_OPEN_WITH("a", "href='javascript:project().confirmAction()'");
		HTML_OPEN_WITH("button", "class=\"dangerousbutton\"");
		WRITE("Install this anyway");
		HTML_CLOSE("button");
		HTML_CLOSE("a");
	}

@<Report on something else@> =
	OUT = InbuildReport::begin(I"Not an extension...", Genres::name(C->edition->work->genre));
	HTML_OPEN("p");
	WRITE("Despite its file/directory name, this doesn't seem to be an extension, ");
	WRITE("and it can't be installed.");
	HTML_CLOSE("p");
