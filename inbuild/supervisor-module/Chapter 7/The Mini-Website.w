[ExtensionWebsite::] The Mini-Website.

To refresh the mini-website of available extensions presented in the
Inform GUI applications.

@ The Inform GUI apps present HTML in-app documentation on extensions: in
effect, a mini-website showing all the extensions available to the current
user, and giving detailed documentation on each one. The code in this
chapter of //supervisor// runs only if and when we want to generate or
update that website, and plays no part in Inform compilation or building
as such: it lives in //supervisor// because it's essentially concerned
with managing resources (i.e., extensions in nests).

A principle used throughout is that we fail safe and silent: if we can't
write the documentation website for any reason (permissions failures, for
example) then we make no complaint. It's a convenience for the user, but not
an essential. This point of view was encouraged by many Inform users working
clandestinely on thumb drives at their places of work, and whose employers
had locked their computers down fairly heavily.

@ The site has a very simple structure: there is an index page, and then
each visible extension is given its own page(s) concerning that extension alone.

Note that the "census" gives us a list of all extensions normally visible
to the project: those it has installed, and those built into the app. But
the project might also still be using an extension from the legacy external
area, so we have to document everything it uses as well as everything in
the census, to be on the safe side.

=
void ExtensionWebsite::update(inform_project *proj) {
	LOGIF(EXTENSIONS_CENSUS, "Updating extensions documentation for project\n");
	HTML::set_link_abbreviation_path(Projects::path(proj));

	inform_extension *E;
	LOOP_OVER_LINKED_LIST(E, inform_extension, proj->extensions_included)
		ExtensionWebsite::document_extension(E, proj);

	linked_list *census = Projects::perform_census(proj);
	inbuild_search_result *res;
	LOOP_OVER_LINKED_LIST(res, inbuild_search_result, census)
		ExtensionWebsite::document_extension(Extensions::from_copy(res->copy), proj);

	ExtensionIndex::write(proj);
}

@ The top-level index page is at this filename.

The distinction between these two calls is that |ExtensionWebsite::index_page_filename|
returns just the filename, and produces |NULL| only if there is no materials folder,
which certainly means we wouldn't want to be writing documentation to it;
but |ExtensionWebsite::cut_way_for_index_page| cuts its way through the file-system
with a machete in order to ensure that its parent directory will indeed exist.
That returns |NULL| if this fails because e.g. the file system objects.

=
filename *ExtensionWebsite::index_page_filename(inform_project *proj) {
	if (proj == NULL) internal_error("no project");
	pathname *P = ExtensionWebsite::path_to_site(proj, FALSE, FALSE);
	if (P == NULL) return NULL;
	return Filenames::in(P, I"Extensions.html");
}

filename *ExtensionWebsite::cut_way_for_index_page(inform_project *proj) {
	if (proj == NULL) internal_error("no project");
	pathname *P = ExtensionWebsite::path_to_site(proj, FALSE, TRUE);
	if (P == NULL) return NULL;
	return Filenames::in(P, I"Extensions.html");
}

@ And this finds, or if |use_machete| is set, also makes way for, the directory
in which our mini-website is to be built.

=
pathname *ExtensionWebsite::path_to_site(inform_project *proj, int relative, int use_machete) {
	if (relative) use_machete = FALSE; /* just for safety's sake */
	pathname *P = NULL;
	if (relative == FALSE) {
		if (proj == NULL) internal_error("no project");
		P = Projects::materials_path(proj);
		if (P == NULL) return NULL;
	}
	P = Pathnames::down(P, I"Extensions");
	if ((use_machete) && (Pathnames::create_in_file_system(P) == 0)) return NULL;
	P = Pathnames::down(P, I"Reserved");
	if ((use_machete) && (Pathnames::create_in_file_system(P) == 0)) return NULL;
	P = Pathnames::down(P, I"Documentation");
	if ((use_machete) && (Pathnames::create_in_file_system(P) == 0)) return NULL;
	return P;
}

@ And similarly for pages which hold individual extension documentation. Note
that if |eg_number| is positive, it should be 1, 2, 3, ... up to the number of
examples provided in the extension.

=
filename *ExtensionWebsite::page_filename(inform_project *proj, inbuild_edition *edition,
	int eg_number) {
	if (proj == NULL) internal_error("no project");
	return ExtensionWebsite::page_filename_inner(proj, edition, eg_number, FALSE, FALSE);
}

filename *ExtensionWebsite::page_filename_relative_to_materials(inbuild_edition *edition,
	int eg_number) {
	return ExtensionWebsite::page_filename_inner(NULL, edition, eg_number, TRUE, FALSE);
}

filename *ExtensionWebsite::cut_way_for_page(inform_project *proj,
	inbuild_edition *edition, int eg_number) {
	if (proj == NULL) internal_error("no project");
	return ExtensionWebsite::page_filename_inner(proj, edition, eg_number, FALSE, TRUE);
}

@ All of which use this private utility function:

=
filename *ExtensionWebsite::page_filename_inner(inform_project *proj, inbuild_edition *edition,
	int eg_number, int relative, int use_machete) {
	if (relative) use_machete = FALSE; /* just for safety's sake */
	TEMPORARY_TEXT(leaf)
	Editions::write_canonical_leaf(leaf, edition);
	
	pathname *P = ExtensionWebsite::path_to_site(proj, relative, use_machete);
	if (P == NULL) return NULL;
	P = Pathnames::down(P, edition->work->author_name);
	if ((use_machete) && (Pathnames::create_in_file_system(P) == 0)) return NULL;
	P = Pathnames::down(P, leaf);
	if ((use_machete) && (Pathnames::create_in_file_system(P) == 0)) return NULL;
	Str::clear(leaf);
	if (eg_number > 0) WRITE_TO(leaf, "eg%d.html", eg_number);
	else WRITE_TO(leaf, "index.html");

	filename *F = Filenames::in(P, leaf);
	DISCARD_TEXT(leaf)
	return F;
}

@ And this is where extension documentation is kicked off.

=
void ExtensionWebsite::document_extension(inform_extension *E, inform_project *proj) {
	if (E == NULL) internal_error("no extension");
	if (proj == NULL) internal_error("no project");
	if (E->documented_on_this_run) return;
	inbuild_edition *edition = E->as_copy->edition;
	inbuild_work *work = edition->work;
	if (LinkedLists::len(E->as_copy->errors_reading_source_text) > 0) {
		LOG("Not writing documentation on %X because it has copy errors\n", work);
	} else {
		LOG("Writing documentation on %X\n", work);
		inbuild_edition *edition = E->as_copy->edition;
		filename *F = ExtensionWebsite::cut_way_for_page(proj, edition, -1);
		if (F == NULL) return;
		pathname *P = Filenames::up(F);
		if (Pathnames::create_in_file_system(P) == 0) return;
		compiled_documentation *doc = Extensions::get_documentation(E);
		TEMPORARY_TEXT(OUT)
		#ifdef CORE_MODULE
		TEMPORARY_TEXT(details)
		IndexExtensions::document_in_detail(details, E);
		if (Str::len(details) > 0) {
			HTML_TAG("hr"); /* ruled line at top of extras */
			HTML_OPEN_WITH("p", "class=\"extensionsubheading\"");
			WRITE("defined these in the last run");
			HTML_CLOSE("p");
			HTML_OPEN("div");
			HTML_CLOSE("div");
			WRITE("%S", details);
		}
		DISCARD_TEXT(details)
		#endif
		DocumentationRenderer::as_HTML(P, doc, OUT);
		DISCARD_TEXT(OUT)
	}
	E->documented_on_this_run = TRUE;
}

text_stream *EXW_breadcrumb_titles[5] = { NULL, NULL, NULL, NULL, NULL };
text_stream *EXW_breakcrumb_URLs[5] = { NULL, NULL, NULL, NULL, NULL };
int no_EXW_breadcrumbs = 0;

void ExtensionWebsite::add_home_breadcrumb(text_stream *title) {
	if (title == NULL) title = I"Extensions";
	ExtensionWebsite::add_breadcrumb(title,
		I"inform:/Extensions/Reserved/Documentation/Extensions.html");
}

void ExtensionWebsite::add_breadcrumb(text_stream *title, text_stream *URL) {
	if (no_EXW_breadcrumbs >= 5) internal_error("too many breadcrumbs");
	EXW_breadcrumb_titles[no_EXW_breadcrumbs] = Str::duplicate(title);
	EXW_breakcrumb_URLs[no_EXW_breadcrumbs] = Str::duplicate(URL);
	no_EXW_breadcrumbs++;
}

void ExtensionWebsite::titling_and_navigation(OUTPUT_STREAM, text_stream *subtitle) {
 	HTML_OPEN_WITH("div", "class=\"headingpanellayout headingpanelalt\"");
	HTML_OPEN_WITH("div", "class=\"headingtext\"");
	HTML::begin_span(OUT, I"headingpaneltextalt");
	for (int i=0; i<no_EXW_breadcrumbs; i++) {
		if (i>0) WRITE(" &gt; ");
		if ((i != no_EXW_breadcrumbs-1) && (Str::len(EXW_breakcrumb_URLs[i]) > 0)) {
			HTML_OPEN_WITH("a", "href=\"%S\" class=\"registrycontentslink\"", EXW_breakcrumb_URLs[i]);
		}
		DocumentationRenderer::render_text(OUT, EXW_breadcrumb_titles[i]);
		if ((i != no_EXW_breadcrumbs-1) && (Str::len(EXW_breakcrumb_URLs[i]) > 0)) {
			HTML_CLOSE("a");
		}
	}
	HTML::end_span(OUT);
	HTML_CLOSE("div");
	HTML_OPEN_WITH("div", "class=\"headingrubric\"");
	HTML::begin_span(OUT, I"headingpanelrubricalt");
	DocumentationRenderer::render_text(OUT, subtitle);
	HTML::end_span(OUT);
	HTML_CLOSE("div");
	HTML_CLOSE("div");
	no_EXW_breadcrumbs = 0;
}

@ This is a new-look paste button, using a "command-V" ideograph rather than
a somewhat enigmatic icon.

=
void ExtensionWebsite::paste_button(OUTPUT_STREAM, text_stream *matter) {
	TEMPORARY_TEXT(paste)
	ExtensionWebsite::paste_ideograph(paste);
	PasteButtons::paste_text_using(OUT, matter, paste);
	DISCARD_TEXT(paste)
	WRITE("&nbsp;");
}
void ExtensionWebsite::paste_ideograph(OUTPUT_STREAM) {
	/* the Unicode for "place of interest", the Swedish castle which became the Apple action symbol */
	WRITE("<span class=\"paste\">%cV</span>", 0x2318);
}
