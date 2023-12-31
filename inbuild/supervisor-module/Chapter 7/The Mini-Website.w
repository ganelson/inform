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
		compiled_documentation *doc = Extensions::get_documentation(E, NULL);
		TEMPORARY_TEXT(OUT)
		#ifdef CORE_MODULE
		TEMPORARY_TEXT(details)
		IndexExtensions::document_in_detail(details, E);
/*		if (Str::len(details) > 0) {
			HTML_TAG("hr");
			HTML_OPEN_WITH("p", "class=\"extensionsubheading\"");
			WRITE("defined these in the last run");
			HTML_CLOSE("p");
			HTML_OPEN("div");
			WRITE("%S", details);
			HTML_CLOSE("div");
		}
*/
		if (E->as_copy->edition->work->genre == extension_bundle_genre) {
			@<Add internals@>;
			if (proj) @<Add testing page@>;
		}
		DISCARD_TEXT(details)
		#endif
		DocumentationRenderer::as_HTML(P, doc, OUT, proj);
		DISCARD_TEXT(OUT)
	}
	E->documented_on_this_run = TRUE;
}

@<Add internals@> =
	text_stream *MD = DocumentationRenderer::open_subpage(P, I"metadata.html");
	TEMPORARY_TEXT(title)
	WRITE_TO(title, "%X", E->as_copy->edition->work);
	DocumentationRenderer::render_header(MD, title, I"Metadata", NULL);
	DISCARD_TEXT(title)
	ExtensionWebsite::write_metadata_page(MD, E);
	DocumentationRenderer::close_subpage();

	linked_list *L = NEW_LINKED_LIST(inbuild_nest);
	inbuild_nest *N = Extensions::materials_nest(E);
	ADD_TO_LINKED_LIST(N, inbuild_nest, L);
	inbuild_requirement *req;
	LOOP_OVER_LINKED_LIST(req, inbuild_requirement, E->kits) {
		inform_kit *K = Kits::find_by_name(req->work->raw_title, L, NULL);
		if (K) @<Create documentation on K@>;
	}
	
@<Create documentation on K@> =
	pathname *KP = Pathnames::down(P, req->work->raw_title);
	if (Pathnames::create_in_file_system(KP)) {
		pathname *KD = Pathnames::down(K->as_copy->location_if_path, I"Documentation");
		compiled_documentation *doc =
			DocumentationCompiler::compile_from_path(KD, NULL, NULL);
		if (doc == NULL) {
			text_stream *OUT = DocumentationRenderer::open_subpage(KP, I"index.html");
			DocumentationRenderer::render_header(OUT, K->as_copy->edition->work->title, NULL, E);
			HTML_OPEN("p");
			WRITE("The kit %S does not provide any internal documentation.",
				K->as_copy->edition->work->title);
			HTML_CLOSE("p");							
			DocumentationRenderer::close_subpage();
		} else {
			doc->within_extension = E;
			DocumentationRenderer::as_HTML(KP, doc, NULL, proj);
		}
	}

@<Add testing page@> =
	if (doc) {
		text_stream *MD = DocumentationRenderer::open_subpage(P, I"testing.html");
		TEMPORARY_TEXT(title)
		WRITE_TO(title, "%X", E->as_copy->edition->work);
		DocumentationRenderer::render_header(MD, title, I"Testing", NULL);
		DISCARD_TEXT(title)
		ExtensionWebsite::write_testing_page(MD, doc, E, proj);
		DocumentationRenderer::close_subpage();
	}

@ =
void ExtensionWebsite::write_metadata_page(OUTPUT_STREAM, inform_extension *E) {
	if (E->as_copy->metadata_record) {
		HTML_OPEN("p");
		WRITE("Metadata for extensions, that is, the detail of what they are and "
			"what they need, is stored in an Internet-standard format called JSON. "
			"The following is the metadata on %X:", E->as_copy->edition->work);
		HTML_CLOSE("p");
		HTML_OPEN("pre");
		JSON::encode(OUT, E->as_copy->metadata_record);
		HTML_CLOSE("pre");
	} else {
		HTML_OPEN("p");
		WRITE("For some reason, no JSON metadata is available for this extension.");
		HTML_CLOSE("p");
	}
}

@ =
void ExtensionWebsite::write_testing_page(OUTPUT_STREAM, compiled_documentation *cd,
	inform_extension *E, inform_project *proj) {
	HTML_OPEN("p");
	WRITE("The extension ");
	Works::write_to_HTML_file(OUT, E->as_copy->edition->work, TRUE);
	semantic_version_number V = E->as_copy->edition->version;
	if (VersionNumbers::is_null(V)) WRITE(", which gives no version number");
	else WRITE(", version %v", &V);
	WRITE(", provides ");
	int no_cases = LinkedLists::len(cd->cases);
	if (no_cases == 0) WRITE("no test cases");
	if (no_cases == 1) WRITE("one test case");
	if (no_cases > 1) WRITE("%d test cases", no_cases);
	if (no_cases > 0) {
		WRITE(" which can be tried with the links tabulated here:");
		HTML_CLOSE("p");
		HTML_OPEN_WITH("div", "class=\"markdowncontent\"");
		HTML_OPEN("table");
		HTML_OPEN("tr");
		HTML_OPEN_WITH("th", "align=\"left\"");
		WRITE("Name of test");
		HTML_CLOSE("th");
		HTML_OPEN_WITH("th", "align=\"left\"");
		WRITE("Source");
		HTML_CLOSE("th");
		HTML_OPEN_WITH("th", "align=\"left\"");
		WRITE("Test");
		HTML_CLOSE("th");
		HTML_OPEN_WITH("th", "align=\"left\"");
		WRITE("Bless");
		HTML_CLOSE("th");
		HTML_OPEN_WITH("th", "align=\"left\"");
		WRITE("Rebless");
		HTML_CLOSE("th");
		HTML_OPEN_WITH("th", "align=\"left\"");
		WRITE("Curse");
		HTML_CLOSE("th");
		HTML_CLOSE("tr");
		satellite_test_case *stc;
		LOOP_OVER_LINKED_LIST(stc, satellite_test_case, cd->cases) {
			ExtensionWebsite::test_table_row(OUT, E, proj,
				(stc->as_example)?(stc->as_example->name):(stc->short_name),
				stc->short_name, stc->as_example);
		}
		if (no_cases == 2)
			ExtensionWebsite::test_table_row(OUT, E, proj, I"both at once", I"all", NULL);
		if (no_cases > 2)
			ExtensionWebsite::test_table_row(OUT, E, proj, I"all at once", I"all", NULL);
		HTML_CLOSE("table");
		HTML_CLOSE("div");
	}
}

void ExtensionWebsite::test_table_row(OUTPUT_STREAM, inform_extension *E,
	inform_project *proj, text_stream *title, text_stream *case_id, IFM_example *eg) {
	HTML_OPEN("tr");
	HTML_OPEN_WITH("td", "align=\"left\"");
	if (Str::ne(case_id, I"all")) HTML_OPEN("em");
	InformFlavouredMarkdown::render_text(OUT, title);
	if (Str::ne(case_id, I"all")) HTML_CLOSE("em");
	HTML_CLOSE("td");
	HTML_OPEN_WITH("td", "align=\"left\"");
	if (eg) {
		TEMPORARY_TEXT(link)
		WRITE_TO(link, "style=\"text-decoration: none\" href=\"%S#eg%S\"",
			eg->URL, eg->insignia);
		HTML::begin_span(OUT, I"indexblack");
		HTML_OPEN_WITH("a", "%S", link);
		WRITE("Example %S", eg->insignia);		
		HTML_CLOSE("a");
		HTML::end_span(OUT);
		DISCARD_TEXT(link)		
	} else {
		WRITE("&mdash;");
	}
	
	HTML_CLOSE("td");
	HTML_OPEN_WITH("td", "align=\"left\"");
	ExtensionInstaller::open_test_link(OUT, proj, E, I"-test", case_id);
	WRITE("test");
	ExtensionInstaller::close_test_link(OUT, proj, E, I"-test", case_id);
	HTML_CLOSE("td");
	HTML_OPEN_WITH("td", "align=\"left\"");
	ExtensionInstaller::open_test_link(OUT, proj, E, I"-bless", case_id);
	WRITE("bless");
	ExtensionInstaller::close_test_link(OUT, proj, E, I"-bless", case_id);
	HTML_CLOSE("td");
	HTML_OPEN_WITH("td", "align=\"left\"");
	ExtensionInstaller::open_test_link(OUT, proj, E, I"-rebless", case_id);
	WRITE("rebless");
	ExtensionInstaller::close_test_link(OUT, proj, E, I"-rebless", case_id);
	HTML_CLOSE("td");
	HTML_OPEN_WITH("td", "align=\"left\"");
	ExtensionInstaller::open_test_link(OUT, proj, E, I"-curse", case_id);
	WRITE("curse");
	ExtensionInstaller::close_test_link(OUT, proj, E, I"-curse", case_id);
	HTML_CLOSE("td");
	HTML_CLOSE("tr");
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
		InformFlavouredMarkdown::render_text(OUT, EXW_breadcrumb_titles[i]);
		if ((i != no_EXW_breadcrumbs-1) && (Str::len(EXW_breakcrumb_URLs[i]) > 0)) {
			HTML_CLOSE("a");
		}
	}
	HTML::end_span(OUT);
	HTML_CLOSE("div");
	HTML_OPEN_WITH("div", "class=\"headingrubric\"");
	HTML::begin_span(OUT, I"headingpanelrubricalt");
	InformFlavouredMarkdown::render_text(OUT, subtitle);
	HTML::end_span(OUT);
	HTML_CLOSE("div");
	HTML_CLOSE("div");
	no_EXW_breadcrumbs = 0;
}
