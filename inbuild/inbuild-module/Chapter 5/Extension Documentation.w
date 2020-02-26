[Extensions::Documentation::] Extension Documentation.

To generate HTML documentation for extensions.

@ Each extension gets its own page in the external documentation area, but
this page can have two forms: the deluxe version, only produced if an
extension is successfully used, and a cut-down placeholder version, used
if Inform has detected the extension but never used it (and so does not really
understand what it entails). The following routine writes both kinds of page.

=
void Extensions::Documentation::write_detailed(inform_extension *E) {
	Extensions::Documentation::write_extension_documentation(NULL, E, FALSE);
}
void Extensions::Documentation::write_sketchy(extension_census_datum *ecd, int census_mode) {
	Extensions::Documentation::write_extension_documentation(ecd, NULL, census_mode);
}

@ Thus we pass two arguments, |ecd| and |ef|, to |Extensions::Documentation::write_extension_documentation|:
one is a valid pointer, the other null. If |ef| is valid, we can write a full
page: if |ecd| is valid, only a sketchy one.

The outer shell routine calls the inner one first to generate the main
page of the documentation (where |eg_number| is |-1|), then uses its return
value (the number of examples provided, which may be 0) to generate
associated files for each example. For instance, we might end up making,
in sequence,

	|Documentation/Extensions/Emily Short/Locksmith.html|
	|Documentation/Extensions/Emily Short/Locksmith-eg1.html|
	|Documentation/Extensions/Emily Short/Locksmith-eg2.html|
	|Documentation/Extensions/Emily Short/Locksmith-eg3.html|
	|Documentation/Extensions/Emily Short/Locksmith-eg4.html|

where these are pathnames relative to the external resources area.

=
void Extensions::Documentation::write_extension_documentation(extension_census_datum *ecd, inform_extension *E, int census_mode) {
	int c, eg_count;
	eg_count = Extensions::Documentation::write_extension_documentation_page(ecd, E, -1, census_mode);
	for (c=1; c<=eg_count; c++)
		Extensions::Documentation::write_extension_documentation_page(ecd, E, c, census_mode);
}

@ Here then is the nub of it. An ECD is not really enough information to go on.
We are not always obliged to make a sketchy page from an ECD: we decide against
in a normal run where a page exists for it already, as otherwise a user with
many extensions installed would detect an annoying slight delay on every run
of Inform -- whereas a slight delay on each census-mode run is acceptable, since
census-mode runs are made only when extensions are installed or uninstalled.
If we do decide to make a page from an ECD, we in fact read the extension into
the lexer so as to make an EF of it. Of course, it won't be a very interesting
EF -- since it wasn't used in compilation there will be no definitions arising
from it, so the top half of its documentation page will be vacant -- but it
will at least provide the extension author's supplied documentation, if there
is any, as well as the correct identifying headings and requirements.

=
int Extensions::Documentation::write_extension_documentation_page(extension_census_datum *ecd, inform_extension *E,
	int eg_number, int census_mode) {
	inbuild_work *work = NULL;
	text_stream DOCF_struct;
	text_stream *DOCF = &DOCF_struct;
	FILE *TEST_DOCF;
	int page_exists_already, no_egs = 0;

	if (ecd) work = ecd->found_as->copy->edition->work; else if (E) work = E->as_copy->edition->work;
	else internal_error("WEDP incorrectly called");
	LOGIF(EXTENSIONS_CENSUS, "WEDP %s (%X)/%d\n", (ecd)?"ecd":" ef", work, eg_number);

	TEMPORARY_TEXT(leaf);
	Str::copy(leaf, work->title);
	if (eg_number > 0) WRITE_TO(leaf, "-eg%d", eg_number);
	filename *name = Extensions::Documentation::location(leaf, work->author_name);

	page_exists_already = FALSE;
	TEST_DOCF = Filenames::fopen(name, "r");
	if (TEST_DOCF) { page_exists_already = TRUE; fclose(TEST_DOCF); }
	LOGIF(EXTENSIONS_CENSUS, "WEDP %s: %f\n", (page_exists_already)?"exists":"does not exist",
		name);

	if (ecd) {
		if ((page_exists_already == FALSE) || (census_mode))
			@<Convert ECD to a text-only EF@>;
		return 0; /* ensure no requests sent for further pages about the ECD: see below */
	}
	if (E == NULL) internal_error("null E in extension documentation writer");

	pathname *P = Extensions::Documentation::path();
	if (P == NULL) return 0;
	if (Pathnames::create_in_file_system(Pathnames::subfolder(P, work->author_name)) == 0)
		return 0;

	if (STREAM_OPEN_TO_FILE(DOCF, name, UTF8_ENC) == FALSE)
		return 0; /* if we lack permissions, e.g., then write no documentation */

	@<Write the actual extension documentation page to DOCF@>;
	STREAM_CLOSE(DOCF);
	DISCARD_TEXT(leaf);
	return no_egs;
}

pathname *Extensions::Documentation::path(void) {
	pathname *P = Inbuild::transient();
	if ((P == NULL) || (Pathnames::create_in_file_system(P) == 0)) return NULL;
	P = Pathnames::subfolder(P, I"Documentation");
	if (Pathnames::create_in_file_system(P) == 0) return NULL;
	P = Pathnames::subfolder(P, I"Extensions");
	if (Pathnames::create_in_file_system(P) == 0) return NULL;
	return P;
}

filename *Extensions::Documentation::location(text_stream *title, text_stream *author) {
	pathname *P = Extensions::Documentation::path();
	if (P == NULL) return NULL;

	TEMPORARY_TEXT(leaf);
	WRITE_TO(leaf, "%S.html", title);
	filename *F = Filenames::in_folder(Pathnames::subfolder(P, author), leaf);
	DISCARD_TEXT(leaf);
	return F;
}

@ The reader may wonder why we perform the conversion in this slightly recursive
way, by calling our parent routine again. Wouldn't it be simpler just to set
|ecd| to null and let events take their course? The answer is that this would
fail if there were examples, because we would return (say) 3 for the number
of examples, and then the routine would be called 3 more times -- but with
the original ECD as argument each time: that would mean reading the file
thrice more, reconverting to EF each time. So we restart the process from
our EF, and return 0 in response to the ECD call to prevent any further ECD
calls.

@<Convert ECD to a text-only EF@> =
	Feeds::feed_text(L"This sentence provides a firebreak, no more. ");
	E = Extensions::Documentation::load(work);
	if (E == NULL) return 0; /* shouldn't happen: it was there only moments ago */
WRITE_TO(STDOUT, "Wel well %X\n", work);
	Copies::read_source_text_for(E->as_copy);
	Extensions::Documentation::write_extension_documentation(NULL, E, census_mode);

@ We now make much the same "paste into the gap in the template" copying
exercise as when generating the home pages for extensions, though with a
different template:

@<Write the actual extension documentation page to DOCF@> =
	text_stream *OUT = DOCF;
	HTML::declare_as_HTML(OUT, FALSE);

	HTML::begin_head(OUT, NULL);
	HTML::title(OUT, I"Extension");
	HTML::incorporate_javascript(OUT, TRUE,
		Inbuild::file_from_installation(JAVASCRIPT_FOR_ONE_EXTENSION_IRES));
	HTML::incorporate_CSS(OUT, Inbuild::file_from_installation(CSS_FOR_STANDARD_PAGES_IRES));
	HTML::end_head(OUT);

	HTML::begin_body(OUT, NULL);
	HTML::incorporate_HTML(OUT, Inbuild::file_from_installation(EXTENSION_DOCUMENTATION_MODEL_IRES));
	@<Write documentation for a specific extension into the page@>;
	HTML::end_body(OUT);

@ And this is the body:

@<Write documentation for a specific extension into the page@> =
	HTML_OPEN("p");
	if (Works::is_standard_rules(work) == FALSE)
		@<Write Javascript paste icon for source text to include this extension@>;
	WRITE("<b>");
	Works::write_to_HTML_file(OUT, work, TRUE);
	WRITE("</b>");
	HTML_CLOSE("p");
	HTML_OPEN("p");
	HTML_OPEN_WITH("span", "class=\"smaller\"");
	@<Write up any restrictions on VM usage@>;
	@<Write up the version number, if any, and location@>;
	HTML_CLOSE("span");
	HTML_CLOSE("p");
	@<Write up the rubric, if any@>;
	@<Write up the table of contents for the extension author's supplied documentation, if any@>;
	#ifdef CORE_MODULE
	Extensions::Files::document_in_detail(OUT, E);
	#endif
	HTML_TAG("hr");
	@<Write up the extension author's supplied documentation, if any@>;

@ UTF-8 transcoding in the following is delegated to |HTML::Javascript::paste|:

@<Write Javascript paste icon for source text to include this extension@> =
	TEMPORARY_TEXT(inclusion_text);
	WRITE_TO(inclusion_text, "Include %X.\n\n\n", work);
	HTML::Javascript::paste_stream(OUT, inclusion_text);
	DISCARD_TEXT(inclusion_text);
	WRITE("&nbsp;");

@<Write up any restrictions on VM usage@> =
	compatibility_specification *C = E->as_copy->edition->compatibility;
	if (Str::len(C->parsed_from) > 0) {
		WRITE("%S&nbsp;", C->parsed_from);
		Extensions::Census::write_icons(OUT, C);
	}

@<Write up the version number, if any, and location@> =
	if (E) {
		semantic_version_number V = E->as_copy->edition->version;
		if (VersionNumbers::is_null(V) == FALSE) WRITE("Version %v", &V);
		if (E->loaded_from_built_in_area) {
			if (VersionNumbers::is_null(V)) { WRITE("Extension"); }
			WRITE(" built in to Inform");
		}
	}

@<Write up the rubric, if any@> =
	if (E) {
		if (Str::len(E->rubric_as_lexed) > 0) {
			HTML_OPEN("p"); WRITE("%S", E->rubric_as_lexed); HTML_CLOSE("p");
		}
		if (Str::len(E->extra_credit_as_lexed) > 0) {
			HTML_OPEN("p"); WRITE("<i>%S</i>", E->extra_credit_as_lexed); HTML_CLOSE("p");
		}
	}

@ This appears above the definition paragraphs because it tends to be only
large extensions which provide TOCs: and they, ipso facto, make many definitions.
If the TOC were directly at the top of the supplied documentation, it might
easily be scrolled down off screen when the user first visits the page.

@<Write up the table of contents for the extension author's supplied documentation, if any@> =
	if (E) {
		if (Wordings::nonempty(E->documentation_text)) {
			HTML_OPEN("p");
			HTML::Documentation::set_table_of_contents(E->documentation_text, OUT, leaf);
			HTML_CLOSE("p");
		}
	}

@<Write up the extension author's supplied documentation, if any@> =
	if (E) {
		if (Wordings::nonempty(E->documentation_text))
			no_egs = HTML::Documentation::set_body_text(E->documentation_text, OUT, eg_number, leaf);
		else {
			HTML_OPEN("p");
			WRITE("The extension provides no documentation.");
			HTML_CLOSE("p");
		}
	}

@

=
inform_extension *Extensions::Documentation::load(inbuild_work *work) {
	inbuild_requirement *req = Requirements::any_version_of(work);
	req->allow_malformed = TRUE;

	inform_extension *E;
	LOOP_OVER(E, inform_extension)
		if (Requirements::meets(E->as_copy->edition, req)) {
			Extensions::must_satisfy(E, req);
			return E;
		}

	linked_list *L = NEW_LINKED_LIST(inbuild_search_result);
	Nests::search_for(req, Inbuild::nest_list(), L);
	inbuild_search_result *search_result;
	LOOP_OVER_LINKED_LIST(search_result, inbuild_search_result, L) {
		E = ExtensionManager::from_copy(search_result->copy);
		int origin = Nests::get_tag(search_result->nest);
		switch (origin) {
			case MATERIALS_NEST_TAG:
			case EXTERNAL_NEST_TAG:
				E->loaded_from_built_in_area = FALSE; break;
			case INTERNAL_NEST_TAG:
				E->loaded_from_built_in_area = TRUE; break;
		}
		return E;
	}
	return NULL;
}
