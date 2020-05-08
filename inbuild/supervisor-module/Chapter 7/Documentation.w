[ExtensionDocumentation::] Documentation.

To generate HTML documentation for extensions.

@ Each extension gets its own page in the external documentation area, but
this page can have two forms:

First, the deluxe version, produced if a project |proj| has successfully used
the extension on this run and we therefore know a lot about the extension --

=
void ExtensionDocumentation::write_detailed(inform_extension *E, inform_project *proj) {
	ExtensionDocumentation::write(NULL, E, FALSE, proj);
}

@ Second, the ordinaire version, where a census has detected the extension
but Inform has apparently never used it. |force_update| here is |TRUE| if a
full |-census| run is under way, |FALSE| if this is instead merely an update,
in which case we do not overwrite an existing documentation file. See below.

=
void ExtensionDocumentation::write_sketchy(extension_census_datum *ecd, int force_update) {
	ExtensionDocumentation::write(ecd, NULL, force_update, NULL);
}

@ Thus we pass two arguments, |ecd| and |E|, to |ExtensionDocumentation::write|:
one is a valid pointer, the other null. If |E| is valid, we can write a full
page: if |ecd| is valid, only a sketchy one.

The outer shell routine calls the inner one first to generate the main
page of the documentation (where |eg_number| is |-1|), then uses its return
value (the number of examples provided, which may be 0) to generate
associated files for each example. For instance, we might end up making,
in sequence,
= (text)
	Documentation/Extensions/Emily Short/Locksmith.html
	Documentation/Extensions/Emily Short/Locksmith-eg1.html
	Documentation/Extensions/Emily Short/Locksmith-eg2.html
	Documentation/Extensions/Emily Short/Locksmith-eg3.html
	Documentation/Extensions/Emily Short/Locksmith-eg4.html
=
where these are pathnames relative to the external resources area.

=
void ExtensionDocumentation::write(extension_census_datum *ecd,
	inform_extension *E, int force_update, inform_project *proj) {
	int c, eg_count;
	eg_count = ExtensionDocumentation::write_page(ecd, E, -1, force_update, proj);
	for (c=1; c<=eg_count; c++)
		ExtensionDocumentation::write_page(ecd, E, c, force_update, proj);
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
int ExtensionDocumentation::write_page(extension_census_datum *ecd,
	inform_extension *E, int eg_number, int force_update, inform_project *proj) {
	inbuild_work *work = NULL;
	if (ecd) work = ecd->found_as->copy->edition->work;
	else if (E) work = E->as_copy->edition->work;
	else internal_error("write_page incorrectly called");

	TEMPORARY_TEXT(leaf);
	Str::copy(leaf, work->title);
	if (eg_number > 0) WRITE_TO(leaf, "-eg%d", eg_number);
	filename *F = ExtensionDocumentation::location(leaf, work->author_name);
	int page_exists_already = TextFiles::exists(F);
	LOGIF(EXTENSIONS_CENSUS, "Write %s (%X)/%d %s: %f\n",
		(ecd)?"ecd":" ef", work, eg_number,
		(page_exists_already)?"exists":"does not exist", F);

	if (ecd) {
		if ((page_exists_already == FALSE) || (force_update))
			@<Convert ECD to a text-only E@>;
		return 0; /* ensure no requests sent for further pages about the ECD: see below */
	}

	if (Pathnames::create_in_file_system(Filenames::up(F)) == 0) return 0;
	text_stream DOCF_struct;
	text_stream *OUT = &DOCF_struct;
	if (STREAM_OPEN_TO_FILE(OUT, F, UTF8_ENC) == FALSE)
		return 0; /* if we lack permissions, e.g., then write no documentation */

	int no_egs = 0;
	@<Write the actual extension documentation page@>;
	STREAM_CLOSE(OUT);
	DISCARD_TEXT(leaf);
	return no_egs;
}

@ The reader may wonder why we perform the conversion in this slightly recursive
way, by calling our parent routine again. Wouldn't it be simpler just to set
|ecd| to null and let events take their course? The answer is that this would
fail if there were examples, because we would return (say) 3 for the number
of examples, and then the routine would be called 3 more times -- but with
the original ECD as argument each time: that would mean reading the file
thrice more, reconverting to E each time. So we restart the process from
our E, and return 0 in response to the ECD call to prevent further ECD calls.

@<Convert ECD to a text-only E@> =
	Feeds::feed_text(L"This sentence provides a firebreak, no more. ");
	E = ExtensionDocumentation::obtain_extension(work, proj);
	if (E == NULL) return 0; /* shouldn't happen: it was there only moments ago */
	Copies::get_source_text(E->as_copy);
	ExtensionDocumentation::write(NULL, E, force_update, proj);

@<Write the actual extension documentation page@> =
	HTML::declare_as_HTML(OUT, FALSE);

	HTML::begin_head(OUT, NULL);
	HTML::title(OUT, I"Extension");
	HTML::incorporate_javascript(OUT, TRUE,
		Supervisor::file_from_installation(JAVASCRIPT_FOR_ONE_EXTENSION_IRES));
	HTML::incorporate_CSS(OUT,
		Supervisor::file_from_installation(CSS_FOR_STANDARD_PAGES_IRES));
	HTML::end_head(OUT);

	HTML::begin_body(OUT, NULL);
	HTML::incorporate_HTML(OUT,
		Supervisor::file_from_installation(EXTENSION_DOCUMENTATION_MODEL_IRES));
	@<Write documentation for a specific extension into the page@>;
	HTML::end_body(OUT);

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
	if (E) @<Write up the rubric, if any@>;
	if (E) @<Write up the table of contents for the supplied documentation, if any@>;
	#ifdef CORE_MODULE
	if (E) Extensions::Files::document_in_detail(OUT, E);
	#endif
	HTML_TAG("hr");
	if (E) @<Write up the supplied documentation, if any@>;

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
		ExtensionCensus::write_icons(OUT, C);
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
		HTML::Documentation::set_table_of_contents(E->documentation_text, OUT, leaf);
		HTML_CLOSE("p");
	}

@<Write up the supplied documentation, if any@> =
	if (Wordings::nonempty(E->documentation_text))
		no_egs = HTML::Documentation::set_body_text(E->documentation_text, OUT,
			eg_number, leaf);
	else {
		HTML_OPEN("p");
		WRITE("The extension provides no documentation.");
		HTML_CLOSE("p");
	}

@ This is where we load an extension purely to look at its supplied
documentation.

=
inform_extension *ExtensionDocumentation::obtain_extension(inbuild_work *work,
	inform_project *proj) {
	inbuild_requirement *req = Requirements::any_version_of(work);
	inform_extension *E;
	LOOP_OVER(E, inform_extension)
		if (Requirements::meets(E->as_copy->edition, req))
			return E;

	inbuild_search_result *R = Nests::search_for_best(req, Projects::nest_list(proj));
	if (R) {
		inform_extension *E = ExtensionManager::from_copy(R->copy);
		if (Nests::get_tag(R->nest) == INTERNAL_NEST_TAG)
			E->loaded_from_built_in_area = TRUE;
		return E;
	}
	return NULL;
}

@ The documentation goes into |Documentation/Extensions/AUTHOR/TITLE.html|,
inside the transient area.

Everything fails safely (and without errors) if this can't be made. Some
Inform users working clandestinely on thumb drives at their places of work say
that they can't write extension documentation because they lack the necessary
file-system privileges. It would be a pity to deprive them of Inform over this.

=
pathname *ExtensionDocumentation::path(void) {
	pathname *P = Supervisor::transient();
	if ((P == NULL) || (Pathnames::create_in_file_system(P) == 0)) return NULL;
	P = Pathnames::down(P, I"Documentation");
	if (Pathnames::create_in_file_system(P) == 0) return NULL;
	P = Pathnames::down(P, I"Extensions");
	if (Pathnames::create_in_file_system(P) == 0) return NULL;
	return P;
}

filename *ExtensionDocumentation::location(text_stream *title, text_stream *author) {
	pathname *P = ExtensionDocumentation::path();
	if (P == NULL) return NULL;

	TEMPORARY_TEXT(leaf);
	WRITE_TO(leaf, "%S.html", title);
	filename *F = Filenames::in(Pathnames::down(P, author), leaf);
	DISCARD_TEXT(leaf);
	return F;
}
