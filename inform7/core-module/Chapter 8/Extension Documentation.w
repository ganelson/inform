[Extensions::Documentation::] Extension Documentation.

To generate HTML documentation for extensions.

@ Each extension gets its own page in the external documentation area, but
this page can have two forms: the deluxe version, only produced if an
extension is successfully used, and a cut-down placeholder version, used
if Inform has detected the extension but never used it (and so does not really
understand what it entails). The following routine writes both kinds of page.

=
void Extensions::Documentation::write_detailed(inform_extension *E) {
	Extensions::Documentation::write_extension_documentation(NULL, E);
}
void Extensions::Documentation::write_sketchy(extension_census_datum *ecd) {
	Extensions::Documentation::write_extension_documentation(ecd, NULL);
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
void Extensions::Documentation::write_extension_documentation(extension_census_datum *ecd, inform_extension *E) {
	int c, eg_count;
	eg_count = Extensions::Documentation::write_extension_documentation_page(ecd, E, -1);
	for (c=1; c<=eg_count; c++)
		Extensions::Documentation::write_extension_documentation_page(ecd, E, c);
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
	int eg_number) {
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
	filename *name = Locations::of_extension_documentation(leaf, work->author_name);

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

	if (Pathnames::create_in_file_system(
			Pathnames::subfolder(pathname_of_extension_docs_inner, work->author_name)) == 0)
		return 0;

	if (STREAM_OPEN_TO_FILE(DOCF, name, UTF8_ENC) == FALSE)
		return 0; /* if we lack permissions, e.g., then write no documentation */

	@<Write the actual extension documentation page to DOCF@>;
	STREAM_CLOSE(DOCF);
	DISCARD_TEXT(leaf);
	return no_egs;
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
	feed_t id = Feeds::begin();
	Feeds::feed_stream(work->raw_author_name);
	Feeds::feed_text(L" ");
	wording AW = Feeds::end(id);

	id = Feeds::begin();
	Feeds::feed_stream(work->raw_title);
	Feeds::feed_text(L" ");
	wording TW = Feeds::end(id);

	Feeds::feed_text(L"This sentence provides a firebreak, no more. ");
	if (<unsuitable-name>(AW)) return 0;
	if (<unsuitable-name>(TW)) return 0;
	inbuild_requirement *req = Requirements::any_version_of(work);
	E = Extensions::Inclusion::load(req);
	if (E == NULL) return 0; /* shouldn't happen: it was there only moments ago */
	Extensions::Documentation::write_extension_documentation(NULL, E);

@ We now make much the same "paste into the gap in the template" copying
exercise as when generating the home pages for extensions, though with a
different template:

@<Write the actual extension documentation page to DOCF@> =
	text_stream *OUT = DOCF;
	HTML::declare_as_HTML(OUT, FALSE);

	HTML::begin_head(OUT, NULL);
	HTML::title(OUT, I"Extension");
	HTML::incorporate_javascript(OUT, TRUE,
		Filenames::in_folder(pathname_of_HTML_models, I"extensionfile.js"));
	HTML::incorporate_CSS(OUT,
		Filenames::in_folder(pathname_of_HTML_models, I"main.css"));
	HTML::end_head(OUT);

	HTML::begin_body(OUT, NULL);
	HTML::incorporate_HTML(OUT,
		Filenames::in_folder(pathname_of_HTML_models, I"extensionfile.html"));
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
	@<Document and dictionary the definitions made in extension file E@>;
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

@ Nothing can prevent a certain repetitiousness intruding here, but there is
just enough local knowledge required to make it foolhardy to try to automate
this from a dump of the excerpt meanings table (say). The ordering of
paragraphs, as in Roget's Thesaurus, tries to proceed from solid things
through to diffuse linguistic ones. But the reader of the resulting
documentation page could be forgiven for thinking it a miscellany.

@<Document and dictionary the definitions made in extension file E@> =
	Extensions::Dictionary::erase_entries(E);
	if (E) Extensions::Dictionary::time_stamp(E);

	@<Document and dictionary the kinds made in extension@>;
	@<Document and dictionary the objects made in extension@>;

	@<Document and dictionary the global variables made in extension@>;
	@<Document and dictionary the enumerated constant values made in extension@>;

	@<Document and dictionary the kinds of action made in extension@>;
	@<Document and dictionary the actions made in extension@>;

	@<Document and dictionary the verbs made in extension@>;
	@<Document and dictionary the adjectival phrases made in extension@>;
	@<Document and dictionary the property names made in extension@>;

	@<Document and dictionary the use options made in extension@>;

@ Off we go, then. Kinds of object:

@<Document and dictionary the kinds made in extension@> =
	kind *K;
	int kc = 0;
	LOOP_OVER_BASE_KINDS(K) {
		parse_node *S = Kinds::Behaviour::get_creating_sentence(K);
		if (S) {
			if (Lexer::file_of_origin(Wordings::first_wn(ParseTree::get_text(S))) == E->read_into_file) {
				wording W = Kinds::Behaviour::get_name(K, FALSE);
				kc = Extensions::Documentation::document_headword(OUT, kc, E, "Kinds", I"kind", W);
				kind *S = Kinds::Compare::super(K);
				if (S) {
					W = Kinds::Behaviour::get_name(S, FALSE);
					if (Wordings::nonempty(W)) WRITE(" (a kind of %+W)", W);
				}
			}
		}
	}
	if (kc != 0) HTML_CLOSE("p");

@ Actual objects:

@<Document and dictionary the objects made in extension@> =
	instance *I;
	int kc = 0;
	LOOP_OVER_OBJECT_INSTANCES(I) {
		wording OW = Instances::get_name(I, FALSE);
		if ((Instances::get_creating_sentence(I)) && (Wordings::nonempty(OW))) {
			if (Lexer::file_of_origin(
				Wordings::first_wn(ParseTree::get_text(Instances::get_creating_sentence(I))))
					== E->read_into_file) {
				TEMPORARY_TEXT(name_of_its_kind);
				kind *k = Instances::to_kind(I);
				wording W = Kinds::Behaviour::get_name(k, FALSE);
				WRITE_TO(name_of_its_kind, "%+W", W);
				kc = Extensions::Documentation::document_headword(OUT, kc, E,
					"Physical creations", name_of_its_kind, OW);
				WRITE(" (a %S)", name_of_its_kind);
				DISCARD_TEXT(name_of_its_kind);
			}
		}
	}
	if (kc != 0) HTML_CLOSE("p");

@ Global variables:

@<Document and dictionary the global variables made in extension@> =
	nonlocal_variable *q;
	int kc = 0;
	LOOP_OVER(q, nonlocal_variable)
		if ((Wordings::first_wn(q->name) >= 0) &&
			(NonlocalVariables::is_global(q)) &&
			(Lexer::file_of_origin(Wordings::first_wn(q->name)) == E->read_into_file) &&
			(Sentences::Headings::indexed(Sentences::Headings::of_wording(q->name)))) {
			if (<value-understood-variable-name>(q->name) == FALSE)
				kc = Extensions::Documentation::document_headword(OUT,
					kc, E, "Values that vary", I"value", q->name);
		}
	if (kc != 0) HTML_CLOSE("p");

@ Constants:

@<Document and dictionary the enumerated constant values made in extension@> =
	instance *q;
	int kc = 0;
	LOOP_OVER_ENUMERATION_INSTANCES(q) {
		wording NW = Instances::get_name(q, FALSE);
		if ((Wordings::nonempty(NW)) && (Lexer::file_of_origin(Wordings::first_wn(NW)) == E->read_into_file))
			kc = Extensions::Documentation::document_headword(OUT, kc, E, "Values", I"value", NW);
	}
	if (kc != 0) HTML_CLOSE("p");

@ Kinds of action:

@<Document and dictionary the kinds of action made in extension@> =
	#ifdef IF_MODULE
	PL::Actions::Patterns::Named::index_for_extension(OUT, E->read_into_file, E);
	#endif

@ Actions:

@<Document and dictionary the actions made in extension@> =
	#ifdef IF_MODULE
	PL::Actions::Index::index_for_extension(OUT, E->read_into_file, E);
	#endif

@ Verbs (this one we delegate):

@<Document and dictionary the verbs made in extension@> =
	Index::Lexicon::list_verbs_in_file(OUT, E->read_into_file, E);

@ Adjectival phrases:

@<Document and dictionary the adjectival phrases made in extension@> =
	adjectival_phrase *adj;
	int kc = 0;
	LOOP_OVER(adj, adjectival_phrase) {
		wording W = Adjectives::get_text(adj, FALSE);
		if ((Wordings::nonempty(W)) &&
			(Lexer::file_of_origin(Wordings::first_wn(W)) == E->read_into_file))
			kc = Extensions::Documentation::document_headword(OUT, kc, E, "Adjectives", I"adjective", W);
	}
	if (kc != 0) HTML_CLOSE("p");

@ Other adjectives:

@<Document and dictionary the property names made in extension@> =
	property *prn;
	int kc = 0;
	LOOP_OVER(prn, property)
		if ((Wordings::nonempty(prn->name)) &&
			(Properties::is_shown_in_index(prn)) &&
			(Lexer::file_of_origin(Wordings::first_wn(prn->name)) == E->read_into_file))
			kc = Extensions::Documentation::document_headword(OUT, kc, E, "Properties", I"property",
				prn->name);
	if (kc != 0) HTML_CLOSE("p");

@ Use options:

@<Document and dictionary the use options made in extension@> =
	use_option *uo;
	int kc = 0;
	LOOP_OVER(uo, use_option)
		if ((Wordings::first_wn(uo->name) >= 0) &&
			(Lexer::file_of_origin(Wordings::first_wn(uo->name)) == E->read_into_file))
			kc = Extensions::Documentation::document_headword(OUT, kc, E, "Use options", I"use option",
				uo->name);
	if (kc != 0) HTML_CLOSE("p");

@ Finally, the utility routine which keeps count (hence |kc|) and displays
suitable lists, while entering each entry in turn into the extension
dictionary.

=
int Extensions::Documentation::document_headword(OUTPUT_STREAM, int kc, inform_extension *E, char *par_heading,
	text_stream *category, wording W) {
	if (kc++ == 0) { HTML_OPEN("p"); WRITE("%s: ", par_heading); }
	else WRITE(", ");
	WRITE("<b>%+W</b>", W);
	Extensions::Dictionary::new_entry(category, E, W);
	return kc;
}

@ And that at last brings us to a milestone: the end of the Land of Extensions.
We can return to Inform's more usual concerns.
