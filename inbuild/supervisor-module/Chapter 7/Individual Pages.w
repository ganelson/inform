[ExtensionPages::] Individual Pages.

To generate the individual pages on extensions in the extension mini-website.

@ The outer shell function calls the inner one first to generate the main
page of the documentation (where |eg_number| is |-1|), then uses its return
value (the number of examples provided, which may be 0) to generate
associated files for each example.w

=
void ExtensionPages::document_extension(inform_extension *E, int force_update,
	inform_project *proj) {
	int state = SourceText::for_documentation_only(TRUE);
	if (E == NULL) internal_error("no extension");
	if (proj == NULL) internal_error("no project");
	if (E->documented_on_this_run) return;
	if (LinkedLists::len(E->as_copy->errors_reading_source_text) > 0) {
		LOG("Not writing documentation on $X because errors occurred scanning it\n",
			E->as_copy->edition->work);
	} else {
		int c, eg_count;
		eg_count = ExtensionPages::write_page_inner(E, -1, force_update, proj);
		for (c=1; c<=eg_count; c++)
			ExtensionPages::write_page_inner(E, c, force_update, proj);
	}
	E->documented_on_this_run = TRUE;
	SourceText::for_documentation_only(state);
}

@

=
int ExtensionPages::write_page_inner(inform_extension *E, int eg_number,
	int force_update, inform_project *proj) {
	inbuild_edition *edition = E->as_copy->edition;
	inbuild_work *work = edition->work;

	filename *F = ExtensionWebsite::cut_way_for_page(proj, edition, eg_number);
	if (F == NULL) return 0;
	int page_exists_already = TextFiles::exists(F);
	LOGIF(EXTENSIONS_CENSUS, "Write (%X)/%d %s: %f\n",
		work, eg_number, (page_exists_already)?"exists":"does not exist", F);

	if (Pathnames::create_in_file_system(Filenames::up(F)) == 0) return 0;
	text_stream DOCF_struct;
	text_stream *OUT = &DOCF_struct;
	if (STREAM_OPEN_TO_FILE(OUT, F, UTF8_ENC) == FALSE)
		return 0; /* if we lack permissions, e.g., then write no documentation */

	int no_egs = 0;
	@<Write the actual extension documentation page@>;
	STREAM_CLOSE(OUT);
	return no_egs;
}

@<Write the actual extension documentation page@> =
	InformPages::header(OUT, I"Extension", JAVASCRIPT_FOR_ONE_EXTENSION_IRES, NULL);
	HTML::incorporate_HTML(OUT,
		InstalledFiles::filename(EXTENSION_DOCUMENTATION_MODEL_IRES));
	@<Write documentation for a specific extension into the page@>;
	InformPages::footer(OUT);

@<Write documentation for a specific extension into the page@> =
	HTML_OPEN("p");
	if (Works::is_standard_rules(work) == FALSE)
		@<Write Javascript paste icon for source text to include this extension@>;
	WRITE("<b>");
	Works::write_to_HTML_file(OUT, work, TRUE);
	WRITE("</b>");
	HTML_CLOSE("p");
	HTML_OPEN("p");
	HTML::begin_span(OUT, I"smaller");
	@<Write up any restrictions on VM usage@>;
	if (E) @<Write up the version number, if any, and location@>;
	HTML::end_span(OUT);
	HTML_CLOSE("p");
	if (E) {
		filename *B = ExtensionWebsite::cut_way_for_page(proj, edition, -1);
		TEMPORARY_TEXT(leaf)
		Filenames::write_unextended_leafname(leaf, B);
		@<Write up the rubric, if any@>;
		@<Write up the table of contents for the supplied documentation, if any@>;
		#ifdef CORE_MODULE
		IndexExtensions::document_in_detail(OUT, E);
		#endif
		@<Write up the supplied documentation, if any@>;
		DISCARD_TEXT(leaf)
	} else {
		HTML_TAG("hr");
	}

@<Write Javascript paste icon for source text to include this extension@> =
	TEMPORARY_TEXT(inclusion_text)
	WRITE_TO(inclusion_text, "Include %X.\n\n\n", work);
	PasteButtons::paste_text(OUT, inclusion_text);
	DISCARD_TEXT(inclusion_text)
	WRITE("&nbsp;");

@<Write up any restrictions on VM usage@> =
	compatibility_specification *C = E->as_copy->edition->compatibility;
	if (Str::len(C->parsed_from) > 0) {
		WRITE("%S", C->parsed_from);
	}

@<Write up the version number, if any, and location@> =
	semantic_version_number V = E->as_copy->edition->version;
	if (VersionNumbers::is_null(V) == FALSE) WRITE("Version %v", &V);
	if (E->loaded_from_built_in_area) {
		if (VersionNumbers::is_null(V)) { WRITE("Extension"); }
		WRITE(" built in to Inform");
	}

@<Write up the rubric, if any@> =
	if (Str::len(E->rubric_as_lexed) > 0) {
		HTML_OPEN("p"); WRITE("%S", E->rubric_as_lexed); HTML_CLOSE("p");
	}
	if (Str::len(E->extra_credit_as_lexed) > 0) {
		HTML_OPEN("p"); WRITE("<i>%S</i>", E->extra_credit_as_lexed); HTML_CLOSE("p");
	}

@ This appears above the definition paragraphs because it tends to be only
large extensions which provide TOCs: and they, ipso facto, make many definitions.
If the TOC were directly at the top of the supplied documentation, it might
easily be scrolled down off screen when the user first visits the page.

@<Write up the table of contents for the supplied documentation, if any@> =
	wording DW = Extensions::get_documentation_text(E);
	if (Wordings::nonempty(DW)) {
		HTML_OPEN("p");
		DocumentationRenderer::table_of_contents(DW, OUT, leaf);
		HTML_CLOSE("p");
	}

@<Write up the supplied documentation, if any@> =
	wording DW = Extensions::get_documentation_text(E);
	if (Wordings::nonempty(DW))
		no_egs = DocumentationRenderer::set_body_text(DW, OUT, eg_number, leaf);
	else {
		HTML_OPEN("p");
		WRITE("The extension provides no documentation.");
		HTML_CLOSE("p");
	}
