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

@ The Installer works in two stages. First it is called with |confirmed| false,
and it produces an HTML report on the feasibility of making the installation,
with a clickable Confirm button. Then, assuming the user does click that button,
the Installer is called again, with |confirmed| true. It takes action and also
produces a second report.

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
		if (N > 0) @<Begin report on a damaged extension@>
		else @<Begin report on a valid extension@>;
		if (OUT) {
			build_vertex *V = Copies::construct_project_graph(project->as_copy);
			if (confirmed) @<Make confirmed report@>
			else @<Make unconfirmed report@>;
		}
	} else {
		@<Report on something else@>;
	}
	if (OUT) {
		InbuildReport::end();
	}
	DISCARD_TEXT(pname)
}

@<Report on something else@> =
	OUT = InbuildReport::begin(I"Not an extension...", Genres::name(C->edition->work->genre));
	HTML_OPEN("p");
	WRITE("Despite its file/directory name, this doesn't seem to be an extension, ");
	WRITE("and it can't be installed.");
	HTML_CLOSE("p");

@<Begin report on a valid extension@> =
	TEMPORARY_TEXT(desc)
	Editions::inspect(desc, C->edition);
	OUT = InbuildReport::begin(desc, I"An extension for use in Inform projects");

@<Begin report on a damaged extension@> =
	TEMPORARY_TEXT(desc)
	WRITE_TO(desc, "This may be: ");
	Editions::inspect(desc, C->edition);
	OUT = InbuildReport::begin(I"Warning: Damaged extension", desc);

@<Make unconfirmed report@> =
	if (N > 0) @<Report on damage to extension@>
	else @<Report that extension seems valid@>;
	@<Explain what installation and Inclusion mean@>;
	@<List the extensions currently Included by the project@>;

	linked_list *L = NEW_LINKED_LIST(inbuild_search_result);
	int same = 0, earlier = 0, later = 0;
	@<List the extensions currently installed in the project@>;
	@<Count how many versions of the same extension are already installed@>;
	
	HTML_TAG("hr");
	@<Come to the point@>;
	@<Finish up with a big red or green button@>;

@<Report on damage to extension@> =
	HTML_OPEN("p");
	WRITE("This extension is broken, and needs repair before it can be used. ");
	WRITE("Specifically:");
	HTML_CLOSE("p");
	Copies::list_attached_errors_to_HTML(OUT, C);
	text_stream *rubric = Extensions::get_rubric(Extensions::from_copy(C));
	if (Str::len(rubric) > 0) {
		WRITE("The extension says this about itself:");
		HTML_CLOSE("p");
		HTML_OPEN("blockquote");
		WRITE("%S", rubric);
		HTML_CLOSE("blockquote");
	}

@<Report that extension seems valid@> =
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

@<Explain what installation and Inclusion mean@> =
	HTML_OPEN("p");
	WRITE("Extensions are installed to a project by being put in the 'Extensions' ");
	WRITE("subfolder of its '.materials' folder, which for %S is here: ", pname);
	pathname *area = Projects::materials_path(project);
	PasteButtons::open_file(OUT, area, NULL, "border=\"0\" src=\"inform:/doc_images/folder.png\"");
	WRITE(". But they take effect only if the project's source text has an Include ");
	WRITE("sentence naming them.");
	HTML_CLOSE("p");

@<List the extensions currently Included by the project@> =
	int rc = 0, bic = 0, ic = 0;
	InbuildReport::show_extensions(OUT, V, Graphs::get_unique_graph_scan_count(),
		FALSE, &bic, FALSE, &ic, FALSE, &rc);
	if (ic > 0) {
		HTML_OPEN("p");
		WRITE("The project %S uses the following extensions (on the ", pname);
		WRITE("basis of what it Includes, and what they in turn Include), which it has installed:");
		HTML_CLOSE("p");
		HTML_OPEN("ul");
		InbuildReport::show_extensions(OUT, V, Graphs::get_unique_graph_scan_count(),
			FALSE, &bic, TRUE, &ic, FALSE, &rc);
		HTML_CLOSE("ul");
		if (bic > 0) {
			HTML_OPEN("p");
			WRITE("not counting extensions built into Inform which do not need to be installed (");
			bic = 0;
			InbuildReport::show_extensions(OUT, V, Graphs::get_unique_graph_scan_count(),
				TRUE, &bic, FALSE, &ic, FALSE, &rc);
			WRITE(").");
			HTML_OPEN("p");
		}
	} else if (bic > 0) {
		HTML_OPEN("p");
		WRITE("The project %S uses only extensions ", pname);
		WRITE("built into Inform which do not need to be installed (");
		bic = 0;
		InbuildReport::show_extensions(OUT, V, Graphs::get_unique_graph_scan_count(),
			TRUE, &bic, FALSE, &ic, FALSE, &rc);
		WRITE(").");
		HTML_CLOSE("p");
	}
	if (rc > 0) {
		HTML_OPEN("p");
		WRITE("The project asks to Include the following, not yet installed:");
		HTML_CLOSE("p");
		HTML_OPEN("ul");
		InbuildReport::show_extensions(OUT, V, Graphs::get_unique_graph_scan_count(),
			FALSE, &bic, FALSE, &ic, TRUE, &rc);
		HTML_CLOSE("ul");
	}

@<List the extensions currently installed in the project@> =
	inbuild_requirement *req = Requirements::anything_of_genre(extension_bundle_genre);
	linked_list *search_list = NEW_LINKED_LIST(inbuild_nest);
	ADD_TO_LINKED_LIST(Projects::materials_nest(project), inbuild_nest, search_list);
	Nests::search_for(req, search_list, L);
	inbuild_search_result *search_result;
	int unbroken = 0, broken = 0;
	LOOP_OVER_LINKED_LIST(search_result, inbuild_search_result, L) {
		if (LinkedLists::len(search_result->copy->errors_reading_source_text) > 0)
			broken++;
		else if (InbuildReport::seek_extension_in_graph(search_result->copy, V) == FALSE)
			unbroken++;
	}
	if (unbroken + broken > 0) {
		if (unbroken > 0) {
			HTML_OPEN("p");
			WRITE("The following are currently installed for %S, but not (yet) Included and so not used:", pname);
			HTML_CLOSE("p");
			HTML_OPEN("ul");
			LOOP_OVER_LINKED_LIST(search_result, inbuild_search_result, L) {
				if (LinkedLists::len(search_result->copy->errors_reading_source_text) == 0) {
					if (InbuildReport::seek_extension_in_graph(search_result->copy, V) == FALSE) {
						HTML_OPEN("li");
						Copies::write_copy(OUT, search_result->copy);
						WRITE("&nbsp;&nbsp;");
						TEMPORARY_TEXT(inclusion_text)
						WRITE_TO(inclusion_text, "Include %X.\n\n\n", search_result->copy->edition->work);
						PasteButtons::paste_text(OUT, inclusion_text);
						DISCARD_TEXT(inclusion_text)
						WRITE("&nbsp;<i>Paste 'Include' sentence into Source</i>");
						HTML_CLOSE("li");
					}
				}
			}
			HTML_CLOSE("ul");
		}
		if (broken > 0) {
			HTML_OPEN("p");
			WRITE("Note that the following are installed but are not working:");
			HTML_CLOSE("p");
			HTML_OPEN("ul");
			LOOP_OVER_LINKED_LIST(search_result, inbuild_search_result, L) {
				if (LinkedLists::len(search_result->copy->errors_reading_source_text) > 0) {
					HTML_OPEN("li");
					Copies::write_copy(OUT, search_result->copy);
					Copies::list_attached_errors_to_HTML(OUT, search_result->copy);
					HTML_CLOSE("li");
				}
			}
			HTML_CLOSE("ul");
		}
	}

@<Count how many versions of the same extension are already installed@> =
	inbuild_search_result *search_result;
	LOOP_OVER_LINKED_LIST(search_result, inbuild_search_result, L)
		if (Works::cmp(C->edition->work, search_result->copy->edition->work) == 0) {
			int c = VersionNumbers::cmp(C->edition->version, search_result->copy->edition->version);
			if (c == 0) same++;
			else if (c > 0) earlier++;
			else if (c < 0) later++;
		}

@<Come to the point@> =
	HTML_OPEN("p");
	WRITE("So, then, click the button below to install %S to the Materials folder of %S. ",
		C->edition->work->title, pname);
	WRITE("If you prefer not to, simply do something else: nothing needs to be cancelled.");
	HTML_CLOSE("p");

@<Finish up with a big red or green button@> =
	if (same > 0) {
		HTML_OPEN("p");
		WRITE("<b>Note</b>. The same version of this same extension seems to be installed already. ");
		WRITE("You can go ahead and install, but if you do the old copy will be removed.");
		HTML_CLOSE("p");
		HTML_OPEN_WITH("a", "href='javascript:project().confirmAction()'");
		HTML_OPEN_WITH("button", "class=\"dangerousbutton\"");
		WRITE("Replace %S in %S with this new copy", C->edition->work->title, pname);
		HTML_CLOSE("button");
		HTML_CLOSE("a");
	} else if (earlier > 0) {
		HTML_OPEN("p");
		WRITE("<b>Note</b>. An earlier version of this same extension seems to be installed already. ");
		WRITE("You can go ahead and install, and this new one will take precedence over the old ");
		WRITE("one, but it won't be thrown away. (You can remove it by hand if you want it gone.)");
		HTML_CLOSE("p");
		HTML_OPEN_WITH("a", "href='javascript:project().confirmAction()'");
		HTML_OPEN_WITH("button", "class=\"dangerousbutton\"");
		WRITE("Install this later copy of %S to %S", C->edition->work->title, pname);
		HTML_CLOSE("button");
		HTML_CLOSE("a");
	} else if (later > 0) {
		HTML_OPEN("p");
		WRITE("<b>Note</b>. A later version of this same extension seems to be installed already. ");
		WRITE("You can go ahead and install, but this new one is unlikely to change anything ");
		WRITE("because Inform will normally prefer to use the later version, which is already ");
		WRITE("there. (You can remove it by hand if you want it gone.)");
		HTML_CLOSE("p");
		HTML_OPEN_WITH("a", "href='javascript:project().confirmAction()'");
		HTML_OPEN_WITH("button", "class=\"dangerousbutton\"");
		WRITE("Install this earlier copy of %S to %S", C->edition->work->title, pname);
		HTML_CLOSE("button");
		HTML_CLOSE("a");
	} else if (N > 0) {
		HTML_OPEN_WITH("a", "href='javascript:project().confirmAction()'");
		HTML_OPEN_WITH("button", "class=\"dangerousbutton\"");
		WRITE("Install this anyway");
		HTML_CLOSE("button");
		HTML_CLOSE("a");
	} else {			
		HTML_OPEN_WITH("a", "href='javascript:project().confirmAction()'");
		HTML_OPEN_WITH("button", "class=\"safebutton\"");
		WRITE("Install %S to %S", C->edition->work->title, pname);
		HTML_CLOSE("button");
		HTML_CLOSE("a");
	}

@<Make confirmed report@> =
	WRITE("<p>CONFIRMED - no action implemented yet, though</p>");

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
							if ((*built_in_count) > 1) WRITE(", ");
							Copies::write_copy(OUT, C);
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

@

=
int InbuildReport::seek_extension_in_graph(inbuild_copy *C, build_vertex *V) {
	if (V->type == COPY_VERTEX) {
		inbuild_copy *VC = V->as_copy;
		if (Editions::cmp(C->edition, VC->edition) == 0)
			return TRUE;
	}
	build_vertex *W;
	LOOP_OVER_LINKED_LIST(W, build_vertex, V->build_edges)
		 if (InbuildReport::seek_extension_in_graph(C, W))
		 	return TRUE;
	LOOP_OVER_LINKED_LIST(W, build_vertex, V->use_edges)
		 if (InbuildReport::seek_extension_in_graph(C, W))
		 	return TRUE;
	return FALSE;
}
