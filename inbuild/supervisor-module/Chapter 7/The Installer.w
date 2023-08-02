[ExtensionInstaller::] The Installer.

To install or uninstall an extension into an Inform project, producing an
HTML page as a report on what happened.

@h Making the report page.
Both the installer and uninstaller make use of:

=
filename *inbuild_report_HTML = NULL;

void ExtensionInstaller::set_filename(filename *F) {
	inbuild_report_HTML = F;
}

text_stream inbuild_report_file_struct; /* The actual report file */
text_stream *inbuild_report_file = NULL; /* As a |text_stream *| */

text_stream *ExtensionInstaller::begin(text_stream *title, text_stream *subtitle) {
	if (inbuild_report_HTML == NULL) return NULL;
	inbuild_report_file = &inbuild_report_file_struct;
	if (STREAM_OPEN_TO_FILE(inbuild_report_file, inbuild_report_HTML, UTF8_ENC) == FALSE)
		Errors::fatal("can't open report file");

	text_stream *OUT = inbuild_report_file;
	InformPages::header(OUT, title, JAVASCRIPT_FOR_STANDARD_PAGES_IRES, NULL);
	ExtensionWebsite::add_home_breadcrumb(NULL);
	ExtensionWebsite::add_breadcrumb(title, NULL);
	ExtensionWebsite::titling_and_navigation(OUT, subtitle);
	return OUT;
}

void ExtensionInstaller::end(void) {
	if (inbuild_report_file) {
		text_stream *OUT = inbuild_report_file;
		HTML_TAG("hr");
		InformPages::footer(OUT);
	}
	inbuild_report_file = NULL;
}

@h The installer.
This works in two stages. First it is called with |confirmed| false,
and it produces an HTML report on the feasibility of making the installation,
with a clickable Confirm button. Then, assuming the user does click that button,
the Installer is called again, with |confirmed| true. It takes action and also
produces a second report.

=
void ExtensionInstaller::install(inbuild_copy *C, int confirmed, pathname *to_tool, int meth) {
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
			Copies::get_source_text(project->as_copy, I"graphing for installer");
			build_vertex *V = Copies::construct_project_graph(project->as_copy);
			if (confirmed) @<Make confirmed report@>
			else @<Make unconfirmed report@>;
		}
	} else {
		@<Report on something else@>;
	}
	if (OUT) {
		ExtensionInstaller::end();
	}
	DISCARD_TEXT(pname)
}

@<Report on something else@> =
	OUT = ExtensionInstaller::begin(I"Not an extension...", Genres::name(C->edition->work->genre));
	HTML_OPEN("p");
	WRITE("Despite its file/directory name, this doesn't seem to be an extension, ");
	WRITE("and it can't be installed or uninstalled.");
	HTML_CLOSE("p");

@<Begin report on a valid extension@> =
	TEMPORARY_TEXT(desc)
	TEMPORARY_TEXT(version)
	Works::write(desc, C->edition->work);
	semantic_version_number V = C->edition->version;
	if (VersionNumbers::is_null(V)) {
		WRITE_TO(version, "An extension");
	} else {
		WRITE_TO(version, "Version %v of an extension", &V);
	}
	OUT = ExtensionInstaller::begin(desc, version);
	DISCARD_TEXT(desc)
	DISCARD_TEXT(version)

@<Begin report on a damaged extension@> =
	TEMPORARY_TEXT(desc)
	WRITE_TO(desc, "This may be: ");
	Editions::inspect(desc, C->edition);
	OUT = ExtensionInstaller::begin(I"Warning: Damaged extension", desc);

@<Make unconfirmed report@> =
	if (N > 0) @<Report on damage to extension@>
	else @<Report that extension seems valid@>;
	HTML_TAG("hr");
	@<Explain about extensions@>;

	linked_list *L = NEW_LINKED_LIST(inbuild_search_result);
	int same = 0, earlier = 0, later = 0;
	@<Search the extensions currently installed in the project@>;
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
	@<Make documentation@>;

@<Explain about extensions@> =
	HTML_OPEN("p");
	WRITE("Extensions are additional Inform features, often contributed by Inform "
		"authors from around the world. Authors download them as needed. Each "
		"project wanting to use an extension must install it into the 'Extensions' "
		"subfolder of its '.materials' folder. Authors are free to do that by hand, but "
		"this installer is more convenient. For more on extensions, see: ");
	DocReferences::link(OUT, I"EXTENSIONS");
	HTML_CLOSE("p");
	HTML_OPEN("p");
	WRITE("The '.materials' folder for %S is here: ", pname);
	pathname *area = Projects::materials_path(project);
	PasteButtons::open_file(OUT, area, NULL, "border=\"0\" src=\"inform:/doc_images/folder.png\"");
	HTML_CLOSE("p");

@<List the extensions currently Included by the project@> =
	int rc = 0, bic = 0, ic = 0;
	ExtensionInstaller::show_extensions(OUT, V, Graphs::get_unique_graph_scan_count(),
		FALSE, &bic, FALSE, &ic, FALSE, &rc);
	if (ic > 0) {
		HTML_OPEN("p");
		WRITE("The project %S uses the following extensions (on the ", pname);
		WRITE("basis of what it Includes, and what they in turn Include), which it has installed:");
		HTML_CLOSE("p");
		HTML_OPEN("ul");
		ExtensionInstaller::show_extensions(OUT, V, Graphs::get_unique_graph_scan_count(),
			FALSE, &bic, TRUE, &ic, FALSE, &rc);
		HTML_CLOSE("ul");
		if (bic > 0) {
			HTML_OPEN("p");
			WRITE("not counting extensions built into Inform which do not need to be installed (");
			bic = 0;
			ExtensionInstaller::show_extensions(OUT, V, Graphs::get_unique_graph_scan_count(),
				TRUE, &bic, FALSE, &ic, FALSE, &rc);
			WRITE(").");
			HTML_OPEN("p");
		}
	} else if (bic > 0) {
		HTML_OPEN("p");
		WRITE("Installing extensions is not the same thing as actually using them. "
			"The project %S uses only extensions ", pname);
		WRITE("built into Inform which do not need to be installed (");
		bic = 0;
		ExtensionInstaller::show_extensions(OUT, V, Graphs::get_unique_graph_scan_count(),
			TRUE, &bic, FALSE, &ic, FALSE, &rc);
		WRITE(") and are included automatically.");
		HTML_CLOSE("p");
		HTML_OPEN("p");
		WRITE("Except for those ones, "
		"extensions take effect only if the source contains a sentence like "
		"'Include EXTENSION TITLE by EXTENSION AUTHOR.' At present, the source "
		"doesn't contain any sentences like that.");
		HTML_CLOSE("p");
	}
	if (rc > 0) {
		HTML_OPEN("p");
		WRITE("The project asks to Include the following, not yet installed:");
		HTML_CLOSE("p");
		HTML_OPEN("ul");
		ExtensionInstaller::show_extensions(OUT, V, Graphs::get_unique_graph_scan_count(),
			FALSE, &bic, FALSE, &ic, TRUE, &rc);
		HTML_CLOSE("ul");
	}

@<Search the extensions currently installed in the project@> =
	inbuild_requirement *req = Requirements::anything_of_genre(extension_bundle_genre);
	linked_list *search_list = NEW_LINKED_LIST(inbuild_nest);
	ADD_TO_LINKED_LIST(Projects::materials_nest(project), inbuild_nest, search_list);
	Nests::search_for(req, search_list, L);

@<List the extensions currently installed in the project@> =
	inbuild_search_result *search_result;
	int unused = 0, broken = 0;
	LOOP_OVER_LINKED_LIST(search_result, inbuild_search_result, L) {
		if (LinkedLists::len(search_result->copy->errors_reading_source_text) > 0)
			broken++;
		else if (ExtensionInstaller::seek_extension_in_graph(search_result->copy, V) == FALSE)
			unused++;
	}
	if (unused + broken > 0) {
		if (unused > 0) {
			HTML_OPEN("p");
			WRITE("The following are currently installed for %S, but not (yet) "
				"Included and so not used. (You can click the 'paste' buttons to "
				"paste a suitable Include sentence into the source text.)", pname);
			HTML_CLOSE("p");
			HTML_OPEN("ul");
			LOOP_OVER_LINKED_LIST(search_result, inbuild_search_result, L) {
				if (LinkedLists::len(search_result->copy->errors_reading_source_text) == 0) {
					if (ExtensionInstaller::seek_extension_in_graph(search_result->copy, V) == FALSE) {
						HTML_OPEN("li");
						Copies::write_copy(OUT, search_result->copy);
						WRITE("&nbsp;&nbsp;");
						TEMPORARY_TEXT(inclusion_text)
						WRITE_TO(inclusion_text, "Include %X.\n\n\n", search_result->copy->edition->work);
						ExtensionWebsite::paste_button(OUT, inclusion_text);
						DISCARD_TEXT(inclusion_text)
						WRITE("&nbsp;<i>'Include'</i>");
						HTML_CLOSE("li");
					}
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

@<Make documentation@> =
	ExtensionWebsite::document_extension(Extensions::from_copy(C), project);
	HTML_OPEN("p");
	WRITE("Documentation about %S ", C->edition->work->title);
	TEMPORARY_TEXT(link)
	TEMPORARY_TEXT(URL)
	WRITE_TO(URL, "%f", ExtensionWebsite::page_filename(project, C->edition, 0));
	WRITE_TO(link, "href='");
	Works::escape_apostrophes(link, URL);
	WRITE_TO(link, "' style=\"text-decoration: none\"");
	HTML_OPEN_WITH("a", "%S", link);
	DISCARD_TEXT(link)
	WRITE("can be read here.");
	HTML_CLOSE("a");
	HTML_CLOSE("p");
	
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
	build_methodology *BM = BuildMethodology::new(Pathnames::up(to_tool), TRUE, meth);
	int no_trashed = 0;
	TEMPORARY_TEXT(trash_report)
	@<Trash any identically-versioned copies currently present@>;
	@<Copy the new one into place@>;
	HTML_OPEN("p");
	WRITE("This extension has now been installed in the materials folder for %S, as:", pname);
	HTML_CLOSE("p");
	HTML_OPEN("ul");
	HTML_OPEN("li");
	HTML_OPEN("p");
	if (C->edition->work->genre == extension_bundle_genre) {
		pathname *P = ExtensionBundleManager::pathname_in_nest(Projects::materials_nest(project), C->edition);
		WRITE("the folder ");
		HTML_OPEN("b");
		Pathnames::to_text_relative(OUT, Pathnames::up(Projects::materials_path(project)), P);
		HTML_CLOSE("b");
	} else {
		filename *F = ExtensionManager::filename_in_nest(Projects::materials_nest(project), C->edition);
		WRITE("the file ");
		HTML_OPEN("b");
		Filenames::to_text_relative(OUT, F, Pathnames::up(Projects::materials_path(project)));
		HTML_CLOSE("b");
	}
	HTML_CLOSE("li");
	HTML_CLOSE("ul");
	if (Str::len(trash_report) > 0) {
		HTML_OPEN("p");
		WRITE("Since an extension with the same title, author name and version number "
			"was already installed in this project, some tidying-up was needed:");
		HTML_CLOSE("p");
		HTML_OPEN("ul");
		WRITE("%S", trash_report);
		HTML_CLOSE("ul");
	}
	HTML_TAG("hr");
	DISCARD_TEXT(trash_report)

	ExtensionWebsite::update(project);

	linked_list *L = NEW_LINKED_LIST(inbuild_search_result);
	@<List the extensions currently Included by the project@>;
	@<Search the extensions currently installed in the project@>;
	@<List the extensions currently installed in the project@>;
	inbuild_search_result *search_result;
	int broken = 0;
	LOOP_OVER_LINKED_LIST(search_result, inbuild_search_result, L)
		if (LinkedLists::len(search_result->copy->errors_reading_source_text) > 0)
			broken++;
	if (broken > 0) {
		HTML_TAG("hr");
		HTML_OPEN("p");
		WRITE("Although installed, the following have errors and will not work. "
			"They may need to be repaired, or may simply not be extensions at all:");
		HTML_CLOSE("p");
		HTML_OPEN("ul");
		LOOP_OVER_LINKED_LIST(search_result, inbuild_search_result, L) {
			if (LinkedLists::len(search_result->copy->errors_reading_source_text) > 0) {
				HTML_OPEN("li");
				Copies::write_copy(OUT, search_result->copy);
				if (search_result->copy->location_if_file) {
					HTML_TAG("br");
					WRITE("at ");
					Filenames::to_text_relative(OUT, search_result->copy->location_if_file,
						Pathnames::up(Projects::materials_path(project)));
				} else if (search_result->copy->location_if_path) {
					HTML_TAG("br");
					WRITE("at ");
					Pathnames::to_text_relative(OUT, Pathnames::up(Projects::materials_path(project)),
						search_result->copy->location_if_path);
				}
				Copies::list_attached_errors_to_HTML(OUT, search_result->copy);
				HTML_CLOSE("li");
			}
		}
		HTML_CLOSE("ul");
	}

@<Trash any identically-versioned copies currently present@> =
	linked_list *L = NEW_LINKED_LIST(inbuild_search_result);
	@<Search the extensions currently installed in the project@>;
	inbuild_search_result *search_result;
	LOOP_OVER_LINKED_LIST(search_result, inbuild_search_result, L)
		if ((Works::cmp(C->edition->work, search_result->copy->edition->work) == 0) &&
			(VersionNumbers::cmp(C->edition->version, search_result->copy->edition->version) == 0))
			no_trashed += ExtensionInstaller::trash(trash_report, project, search_result->copy, BM);

@<Copy the new one into place@> =
	Copies::copy_to(C, Projects::materials_nest(project), TRUE, BM);

@h The uninstaller.
This works in two stages, exactly like the installer, but it's much simpler.

=
void ExtensionInstaller::uninstall(inbuild_copy *C, int confirmed, pathname *to_tool, int meth) {
	inform_project *project = Supervisor::project_set_at_command_line();
	if (project == NULL) Errors::fatal("-project not set at command line");
	TEMPORARY_TEXT(pname)
	WRITE_TO(pname, "'%S'", project->as_copy->edition->work->title);
	text_stream *OUT = NULL;
	if ((C->edition->work->genre == extension_genre) ||
		(C->edition->work->genre == extension_bundle_genre)) {
		if (OUT) {
			@<Begin uninstaller report@>;
			if (confirmed) @<Make confirmed uninstaller report@>
			else @<Make unconfirmed uninstaller report@>;
		}
	} else {
		@<Report on something else@>;
	}
	if (OUT) {
		ExtensionInstaller::end();
	}
	DISCARD_TEXT(pname)
}

@<Begin uninstaller report@> =
	TEMPORARY_TEXT(desc)
	TEMPORARY_TEXT(version)
	Works::write(desc, C->edition->work);
	semantic_version_number V = C->edition->version;
	if (VersionNumbers::is_null(V)) {
		WRITE_TO(version, "An extension");
	} else {
		WRITE_TO(version, "Version %v of an extension", &V);
	}
	OUT = ExtensionInstaller::begin(desc, version);
	DISCARD_TEXT(desc)
	DISCARD_TEXT(version)

@<Make unconfirmed uninstaller report@> =
	HTML_OPEN("p");
	WRITE("Click the red button to confirm that you would like to uninstall this "
		"extension from the materials folder for %S: ", pname);
	if (C->edition->work->genre == extension_bundle_genre) {
		pathname *P = ExtensionBundleManager::pathname_in_nest(Projects::materials_nest(project), C->edition);
		WRITE("the folder ");
		HTML_OPEN("b");
		Pathnames::to_text_relative(OUT, Pathnames::up(Projects::materials_path(project)), P);
		HTML_CLOSE("b");
	} else {
		filename *F = ExtensionManager::filename_in_nest(Projects::materials_nest(project), C->edition);
		WRITE("the file ");
		HTML_OPEN("b");
		Filenames::to_text_relative(OUT, F, Pathnames::up(Projects::materials_path(project)));
		HTML_CLOSE("b");
	}
	WRITE(" which is in nest %p", Nests::get_location(C->nest_of_origin));
	HTML_CLOSE("p");
	HTML_OPEN_WITH("a", "href='javascript:project().confirmAction()'");
	HTML_OPEN_WITH("button", "class=\"dangerousbutton\"");
	WRITE("Uninstall %S", C->edition->work->title);
	HTML_CLOSE("button");
	HTML_CLOSE("a");

@<Make confirmed uninstaller report@> =
	build_methodology *BM = BuildMethodology::new(Pathnames::up(to_tool), TRUE, meth);
	TEMPORARY_TEXT(trash_report)
	ExtensionInstaller::trash(trash_report, project, C, BM);
	HTML_OPEN("p");
	WRITE("Uninstalling this extension from the materials folder for %S:", pname);
	HTML_CLOSE("p");
	HTML_OPEN("ul");
	WRITE("%S", trash_report);
	HTML_CLOSE("ul");
	HTML_TAG("hr");
	DISCARD_TEXT(trash_report)
	ExtensionWebsite::update(project);

@h Moving to trash.

=
int ExtensionInstaller::trash(OUTPUT_STREAM, inform_project *proj, inbuild_copy *C,
	build_methodology *BM) {
	int succeeded = FALSE;
	HTML_OPEN("li");
	pathname *super_trash_folder =
		Pathnames::down(
			Pathnames::down(
				Pathnames::down(
					Projects::materials_path(proj),
					I"Extensions"),
				I"Reserved"),
			I"Trash");
	TEMPORARY_TEXT(dateleaf)
	WRITE_TO(dateleaf, "Trashed on %04d-%02d-%02d at %02d%02d", the_present->tm_year+1900,
		the_present->tm_mon, the_present->tm_mday, the_present->tm_hour, the_present->tm_min);
	DISCARD_TEXT(dateleaf)
	pathname *trash_folder = Pathnames::down(super_trash_folder, dateleaf);
	TEMPORARY_TEXT(reported)
	Pathnames::to_text_relative(reported, Pathnames::up(Projects::materials_path(proj)), trash_folder);
	if (C->location_if_file) {
		TEMPORARY_TEXT(leaf)
		int n = 1;
		filename *TF = NULL;
		do {
			Str::clear(leaf);
			Filenames::write_unextended_leafname(leaf, C->location_if_file);
			if (n > 1) WRITE_TO(leaf, " %d", n);
			n++;
			WRITE_TO(leaf, ".i7x");
			TF = Filenames::in(trash_folder, leaf);
		} while (TextFiles::exists(TF));
		DISCARD_TEXT(leaf)
		if (BM->methodology == DRY_RUN_METHODOLOGY) {
			WRITE("This is only a dry run, but I now want to create the directory "
				"%p as a trash folder and move the file %f to become %f. ",
				trash_folder, C->location_if_file, TF);			
		} else {
			if ((Pathnames::create_in_file_system(super_trash_folder) == FALSE) ||
				(Pathnames::create_in_file_system(trash_folder) == FALSE)) {
				WRITE("I tried to move the copy installed as '%S' to the trash (%S), "
					"but was unable to create this trash directory, perhaps because "
					"of some file-system problem? ",
					Filenames::get_leafname(C->location_if_file),
					reported);
			} else if (Filenames::move_file(C->location_if_file, TF)) {
				WRITE("I have moved the copy previously installed as '%S' to the "
					"project's trash. (If you need it, you can find it in %S.) ",
					Filenames::get_leafname(C->location_if_file),
					reported);
				C->location_if_file = TF;
				succeeded = TRUE;
			} else {
				WRITE("I tried to move the copy installed as '%S' to the trash (%S), "
					"but was unable to, perhaps because of some file-system problem? ",
					Filenames::get_leafname(C->location_if_file),
					reported);
			}
		}
	} else {
		TEMPORARY_TEXT(leaf)
		int n = 1;
		pathname *TD = NULL;
		do {
			Str::clear(leaf);
			WRITE_TO(leaf, "%S", Pathnames::directory_name(C->location_if_path));
			if (n > 1) WRITE_TO(leaf, " %d", n);
			n++;
			WRITE_TO(leaf, ".i7xd");
			TD = Pathnames::down(trash_folder, leaf);
		} while (Directories::exists(TD));
		DISCARD_TEXT(leaf)
		if (BM->methodology == DRY_RUN_METHODOLOGY) {
			WRITE("This is only a dry run, but I now want to create the directory "
				"%p as a trash folder and move the directory %p to become %p. ",
				trash_folder, C->location_if_path, TD);			
		} else {
			if ((Pathnames::create_in_file_system(super_trash_folder) == FALSE) ||
				(Pathnames::create_in_file_system(trash_folder) == FALSE)) {
				WRITE("I tried to move the copy installed as '%S' to the trash (%S), "
					"but was unable to create this trash directory, perhaps because "
					"of some file-system problem? ",
					Pathnames::directory_name(C->location_if_path),
					reported);
			} else if (Pathnames::move_directory(C->location_if_path, TD)) {
				WRITE("I have moved the copy previously installed as '%S' to the "
					"project's trash. (If you need it, you can find it in %S.) ",
					Pathnames::directory_name(C->location_if_path),
					reported);
				C->location_if_path = TD;
				succeeded = TRUE;
			} else {
				WRITE("I tried to move the copy installed as '%S' to the trash (%S), "
					"but was unable to, perhaps because of some file-system problem? ",
					Pathnames::directory_name(C->location_if_path),
					reported);
			}
		}
	}
	HTML_CLOSE("li");
	return succeeded;
}

@

=
void ExtensionInstaller::show_extensions(OUTPUT_STREAM, build_vertex *V, int scan_count,
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
							WRITE("%S v%v", C->edition->work->title, &(C->edition->version));
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
		ExtensionInstaller::show_extensions(OUT, W, scan_count, built_in, built_in_count,
			installed, installed_count, required, requirements_count);
	LOOP_OVER_LINKED_LIST(W, build_vertex, V->use_edges)
		ExtensionInstaller::show_extensions(OUT, W, scan_count, built_in, built_in_count,
			installed, installed_count, required, requirements_count);
}

@

=
int ExtensionInstaller::seek_extension_in_graph(inbuild_copy *C, build_vertex *V) {
	if (V->type == COPY_VERTEX) {
		inbuild_copy *VC = V->as_copy;
		if (Editions::cmp(C->edition, VC->edition) == 0)
			return TRUE;
	}
	build_vertex *W;
	LOOP_OVER_LINKED_LIST(W, build_vertex, V->build_edges)
		 if (ExtensionInstaller::seek_extension_in_graph(C, W))
		 	return TRUE;
	LOOP_OVER_LINKED_LIST(W, build_vertex, V->use_edges)
		 if (ExtensionInstaller::seek_extension_in_graph(C, W))
		 	return TRUE;
	return FALSE;
}

@

=
void ExtensionInstaller::install_button(OUTPUT_STREAM, inform_project *proj,
	inbuild_copy *C) {			
	TEMPORARY_TEXT(URL)
	if (C->location_if_file)
		WRITE_TO(URL, "%f", C->location_if_file);
	else
		WRITE_TO(URL, "%p", C->location_if_path);
	HTML_OPEN_WITH("a", "class=\"registrycontentslink\" href='javascript:project().install(\"%S\")'", URL);
	DISCARD_TEXT(URL)
	ExtensionInstaller::install_icon(OUT);
	HTML_CLOSE("a");
}

void ExtensionInstaller::install_icon(OUTPUT_STREAM) {
	WRITE("<span class=\"paste\">%c%c</span>", 0x2B06, 0xFE0F); /* Unicode "up arrow" */
}

void ExtensionInstaller::uninstall_button(OUTPUT_STREAM, inform_project *proj,
	inbuild_copy *C) {
	TEMPORARY_TEXT(URL)
	if (C->location_if_file)
		WRITE_TO(URL, "%f", C->location_if_file);
	else
		WRITE_TO(URL, "%p", C->location_if_path);
	HTML_OPEN_WITH("a", "class=\"registrycontentslink\" href='javascript:project().uninstall(\"%S\")'", URL);
	DISCARD_TEXT(URL)
	ExtensionInstaller::uninstall_icon(OUT);
	HTML_CLOSE("a");
}

void ExtensionInstaller::uninstall_icon(OUTPUT_STREAM) {
	WRITE("<span class=\"paste\">%c%c</span>", 0x2198, 0xFE0F); /* Unicode "down right arrow" */
}
