[ExtensionPages::] Individual Pages.

To generate the individual pages on extensions in the extension mini-website.

@ //ExtensionWebsite::go// calls the following function to make either a
detailed or a sketchy documentation page on an extension, supplying either
a non-null |E| for details, or a non-null |ecd| for a sketch.

The outer shell function calls the inner one first to generate the main
page of the documentation (where |eg_number| is |-1|), then uses its return
value (the number of examples provided, which may be 0) to generate
associated files for each example.w

=
void ExtensionPages::write_page(extension_census_datum *ecd,
	inform_extension *E, int force_update, inform_project *proj) {
	if ((E) && (E->as_copy) &&
		(LinkedLists::len(E->as_copy->errors_reading_source_text) > 0)) {
		LOG("Not writing documentation on %f because errors occurred scanning it\n",
			E->as_copy->location_if_file);
	} else {
		int c, eg_count;
		eg_count = ExtensionPages::write_page_inner(ecd, E, -1, force_update, proj);
		for (c=1; c<=eg_count; c++)
			ExtensionPages::write_page_inner(ecd, E, c, force_update, proj);
	}
}

@ Here then is the nub of it. An ECD is not really enough information to go on.
We are not always obliged to make a sketchy page from an ECD: we decide against
in a normal run where a page exists for it already, as otherwise a user with
many extensions installed would detect an annoying slight delay on every run
of Inform -- whereas a slight delay on each census-mode run is acceptable, since
census-mode runs are made only when extensions are installed or uninstalled.
If we do decide to make a page from an ECD, we in fact read the extension into
the lexer so as to make an E of it. Of course, it won't be a very interesting
E -- since it wasn't used in compilation there will be no definitions arising
from it, so the top half of its documentation page will be vacant -- but it
will at least provide the extension author's supplied documentation, if there
is any, as well as the correct identifying headings and requirements.

=
int ExtensionPages::write_page_inner(extension_census_datum *ecd,
	inform_extension *E, int eg_number, int force_update, inform_project *proj) {
	inbuild_work *work = NULL;
	if (ecd) work = ecd->found_as->copy->edition->work;
	else if (E) work = E->as_copy->edition->work;
	else internal_error("write_page incorrectly called");

	filename *F = ExtensionWebsite::page_URL(work, eg_number);
	if (F == NULL) return 0;
	int page_exists_already = TextFiles::exists(F);
	LOGIF(EXTENSIONS_CENSUS, "Write %s (%X)/%d %s: %f\n",
		(ecd)?"ecd":" ef", work, eg_number,
		(page_exists_already)?"exists":"does not exist", F);

	if (ecd) @<Convert ECD to a text-only E@>;

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

@ The reader may wonder why we perform the conversion in this slightly recursive
way, by calling our parent function again. Wouldn't it be simpler just to set
|ecd| to null and let events take their course? The answer is that this would
fail if there were examples, because we would return (say) 3 for the number
of examples, and then the function would be called 3 more times -- but with
the original ECD as argument each time: that would mean reading the file
thrice more, reconverting to E each time. So we restart the process from
our E, and return 0 in response to the ECD call to prevent further ECD calls.

@<Convert ECD to a text-only E@> =
	if ((page_exists_already == FALSE) || (force_update)) {
		Feeds::feed_C_string(L"This sentence provides a firebreak, no more. ");
		E = ExtensionManager::from_copy(ecd->found_as->copy);
		if (E == NULL) return 0; /* but shouldn't happen: it was there only moments ago */
		Copies::get_source_text(E->as_copy);
		ExtensionPages::write_page(NULL, E, force_update, proj);
	}
	return 0;

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
	HTML_OPEN_WITH("span", "class=\"smaller\"");
	@<Write up any restrictions on VM usage@>;
	if (E) @<Write up the version number, if any, and location@>;
	HTML_CLOSE("span");
	HTML_CLOSE("p");
	if (E) {
		filename *B = ExtensionWebsite::page_URL(work, -1);
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
		WRITE("%S&nbsp;", C->parsed_from);
		ExtensionIndex::write_icons(OUT, C);
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
	if (Wordings::nonempty(E->documentation_text)) {
		HTML_OPEN("p");
		DocumentationRenderer::table_of_contents(E->documentation_text, OUT, leaf);
		HTML_CLOSE("p");
	}

@<Write up the supplied documentation, if any@> =
	if (Wordings::nonempty(E->documentation_text))
		no_egs = DocumentationRenderer::set_body_text(E->documentation_text, OUT,
			eg_number, leaf);
	else {
		HTML_OPEN("p");
		WRITE("The extension provides no documentation.");
		HTML_CLOSE("p");
	}
