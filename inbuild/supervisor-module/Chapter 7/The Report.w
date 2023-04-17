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
	inform_project *project = Supervisor::project_set_at_command_line();
	if (project == NULL) Errors::fatal("-project not set at command line");
	TEMPORARY_TEXT(pname)
	WRITE_TO(pname, "'%S'", project->as_copy->edition->work->title);
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
	DISCARD_TEXT(pname)
}

@<Report on a valid extension@> =
	TEMPORARY_TEXT(desc)
	Editions::inspect(desc, C->edition);
	OUT = InbuildReport::begin(desc, I"An extension for use in Inform projects");
	if (OUT) {
		HTML_OPEN("p");
		WRITE("This looks like a valid extension");
		text_stream *rubric = Extensions::get_rubric(Extensions::from_copy(C));
		if (Str::len(rubric) > 0) {
			WRITE(", and says this about itself:");
			HTML_CLOSE("p");
			HTML_OPEN("blockquote");
			WRITE("%S", rubric);
			HTML_CLOSE("blockquote");
		} else {
			WRITE(", but does not say what it is for.");
			HTML_CLOSE("p");
		}
		if (confirmed) {
			WRITE("<p>CONFIRMED - no action implemented yet, though</p>");
		} else {
			int rc = 0, bic = 0, ic = 0;
			build_vertex *V = Copies::construct_project_graph(project->as_copy);
			InbuildReport::show_extensions(OUT, V, Graphs::get_unique_graph_scan_count(),
				FALSE, &bic, FALSE, &ic, FALSE, &rc);
			if (ic > 0) {
				HTML_OPEN("p");
				WRITE("The project '%S' uses the following extensions (on the ", pname);
				WRITE("basis of what it Includes, and what they in turn Include), which it has installed:");
				HTML_CLOSE("p");
				HTML_OPEN("ul");
				InbuildReport::show_extensions(OUT, V, Graphs::get_unique_graph_scan_count(),
					FALSE, &bic, TRUE, &ic, FALSE, &rc);
				HTML_CLOSE("ul");
				if (bic > 0) {
					HTML_OPEN("p");
					WRITE("not counting extensions built in to every copy of Inform:");
					HTML_OPEN("p");
					HTML_OPEN("ul");
					InbuildReport::show_extensions(OUT, V, Graphs::get_unique_graph_scan_count(),
						TRUE, &bic, FALSE, &ic, FALSE, &rc);
					HTML_CLOSE("ul");
				}
			} else {
				HTML_OPEN("p");
				WRITE("The project '%S' uses only extensions ", pname);
				WRITE("built in to every copy of Inform:");
				HTML_OPEN("p");
				HTML_OPEN("ul");
				InbuildReport::show_extensions(OUT, V, Graphs::get_unique_graph_scan_count(),
					TRUE, &bic, FALSE, &ic, FALSE, &rc);
				HTML_CLOSE("ul");
			}
			if (rc > 0) {
				HTML_OPEN("p");
				WRITE("The project needs the following, not yet installed:");
				HTML_CLOSE("p");
				HTML_OPEN("ul");
				InbuildReport::show_extensions(OUT, V, Graphs::get_unique_graph_scan_count(),
					FALSE, &bic, FALSE, &ic, TRUE, &rc);
				HTML_CLOSE("ul");
			}
			HTML_OPEN("p");
			WRITE("Extensions are installed to a project by being put in the 'Extensions' ");
			WRITE("subfolder of its '.materials' folder, which for '%S' is here: ", pname);
			pathname *area = Projects::materials_path(project);
			PasteButtons::open_file(OUT, area, NULL, "border=\"0\" src=\"inform:/doc_images/folder.png\"");
			HTML_CLOSE("p");		
			HTML_OPEN_WITH("a", "href='javascript:project().confirmAction()'");
			HTML_OPEN_WITH("button", "class=\"safebutton\"");
			WRITE("Click to install %S to %S", C->edition->work->title, pname);
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

@

=
void InbuildReport::show_extensions(OUTPUT_STREAM, build_vertex *V, int scan_count,
	int built_in, int *built_in_count, int installed, int *installed_count,
	int required, int *requirements_count) {
	if (V->type == COPY_VERTEX) {
		inbuild_copy *C = V->as_copy;
		if ((C->edition->work->genre == extension_genre) ||
			(C->edition->work->genre == extension_bundle_genre)) {
			if (C->last_scanned != scan_count) {
				if (required == FALSE) {
					C->last_scanned = scan_count;
					if ((C->nest_of_origin) &&
						(Nests::get_tag(C->nest_of_origin) == INTERNAL_NEST_TAG)) {
						(*built_in_count)++;
						if (built_in) {
							HTML_OPEN("li");
							Copies::write_copy(OUT, C);
							HTML_CLOSE("li");
						}
					} else {
						(*installed_count)++;
						if (installed) {
							HTML_OPEN("li");
							Copies::write_copy(OUT, C);
							HTML_CLOSE("li");
						}
					}
				}
			}
		}
	}
	if (V->type == REQUIREMENT_VERTEX) {
		if ((V->as_requirement->work->genre == extension_genre) ||
			(V->as_requirement->work->genre == extension_bundle_genre)) {
			(*requirements_count)++;
			if (required) {
				HTML_OPEN("li");
				Works::write(OUT, V->as_requirement->work);
				if (VersionNumberRanges::is_any_range(V->as_requirement->version_range) == FALSE) {
					WRITE(" (need version in range ");
					VersionNumberRanges::write_range(OUT, V->as_requirement->version_range);
					WRITE(")");
				} else {
					WRITE(" (any version will do)");
				}
				HTML_CLOSE("li");
			}
		}
	}
	build_vertex *W;
		LOOP_OVER_LINKED_LIST(W, build_vertex, V->build_edges)
			InbuildReport::show_extensions(OUT, W, scan_count, built_in, built_in_count,
				installed, installed_count, required, requirements_count);
		LOOP_OVER_LINKED_LIST(W, build_vertex, V->use_edges)
			InbuildReport::show_extensions(OUT, W, scan_count, built_in, built_in_count,
				installed, installed_count, required, requirements_count);
}
