[ExtensionIndex::] Index Pages.

To generate the two top-level pages in the extension mini-website.

@h Writing the extensions home page.
There were once two of these, but now there's just one.

=
void ExtensionIndex::write(inform_project *proj, extension_census *C) {
	filename *F = ExtensionWebsite::index_URL(proj, I"Extensions.html");
	if (F == NULL) return;

	linked_list *in_project = NEW_LINKED_LIST(inbuild_search_result);
	@<See what we have installed in the project itself@>;
	linked_list *in_installation = NEW_LINKED_LIST(inbuild_search_result);
	@<See what we have installed built in to Inform@>;

	text_stream HOMEPAGE_struct;
	text_stream *OUT = &HOMEPAGE_struct;
	if (STREAM_OPEN_TO_FILE(OUT, F, UTF8_ENC) == FALSE) return;
	InformPages::header(OUT, I"Extensions", JAVASCRIPT_FOR_EXTENSIONS_IRES, NULL);
	@<Write the body of the HTML@>;
	InformPages::footer(OUT);
	STREAM_CLOSE(OUT);
}

@<See what we have installed in the project itself@> =
	inbuild_nest *materials = Projects::materials_nest(proj);
	if (materials) {
		inbuild_requirement *req = Requirements::anything_of_genre(extension_bundle_genre);
		linked_list *search_list = NEW_LINKED_LIST(inbuild_nest);
		ADD_TO_LINKED_LIST(materials, inbuild_nest, search_list);
		Nests::search_for(req, search_list, in_project);
	}

@<See what we have installed built in to Inform@> =
	inbuild_nest *internal = Supervisor::internal();
	if (internal) {
		inbuild_requirement *req = Requirements::anything_of_genre(extension_bundle_genre);
		linked_list *search_list = NEW_LINKED_LIST(inbuild_nest);
		ADD_TO_LINKED_LIST(internal, inbuild_nest, search_list);
		Nests::search_for(req, search_list, in_installation);
	}

@<Write the body of the HTML@> =
	HTML::begin_html_table(OUT, NULL, TRUE, 0, 4, 0, 0, 0);
	HTML::first_html_column(OUT, 0);
	HTML_TAG_WITH("img",
		"src='inform:/doc_images/extensions@2x.png' border=0 width=150 height=150");
	HTML::next_html_column(OUT, 0);

	HTML_OPEN_WITH("div", "class=\"headingpanellayout headingpanelalt\"");
	HTML_OPEN_WITH("div", "class=\"headingtext\"");
	HTML::begin_span(OUT, I"headingpaneltextalt");
	WRITE("Extensions in this Project");
	HTML::end_span(OUT);
	HTML_CLOSE("div");
	HTML_OPEN_WITH("div", "class=\"headingrubric\"");
	HTML::begin_span(OUT, I"headingpanelrubricalt");
	WRITE("What you have installed and what you have used");
	HTML::end_span(OUT);
	HTML_CLOSE("div");
	HTML_CLOSE("div");
	@<Display the location of installed extensions@>;
	@<Display a warning about any census errors which turned up@>;
	HTML::end_html_row(OUT);
	HTML::end_html_table(OUT);
	HTML_TAG("hr");
	HTML_OPEN("p");
	WRITE("The project currently Includes, or otherwise uses, the following:");
	HTML_CLOSE("p");
	@<Display an alphabetised directory@>;
	HTML_TAG("hr");
	HTML_OPEN("p");
	WRITE("The following are available for use by the project, either by being "
		"installed in it or by being built in to the app, but are not currently used:");
	HTML_CLOSE("p");
	@<Display an alphabetised directory@>;

@ From here on, then, all the code in this section generates the main directory
page, not the index of terms, which is all handled by
//ExtensionDictionary::write_to_HTML//.

@<Display the location of installed extensions@> =
	int nbi = LinkedLists::len(in_installation), nps = LinkedLists::len(in_project);

	HTML_OPEN("p");
	pathname *P = Nests::get_location(Projects::materials_nest(proj));
	P = Pathnames::down(P, I"Extensions");
	PasteButtons::open_file(OUT, P, NULL, PROJECT_SPECIFIC_SYMBOL);
	WRITE("&nbsp;");
	if (nps > 0) {
		WRITE("You have %d extension%s in the .materials folder for the "
			"current project. (Click the purple folder icon to show the location.)",
			nps, (nps==1)?"":"s");
	} else {
		WRITE("There are currently no extensions installed in the .materials folder "
			"for this project. (Click the purple folder icon to show the location. "
			"Extensions should be put in the 'Extensions' subfolder of this: you "
			"can put them there yourself, or use the Inform app to install them "
			"for you.)");
	}
	HTML_CLOSE("p");

	HTML_OPEN("p");
	HTML_TAG_WITH("img", "src='inform:/doc_images/builtin_ext.png' border=0");
	WRITE("&nbsp;");
	WRITE("As well as being able to use extensions installed into its own folder, "
		"projects can use extensions which come built into the Inform app. In "
		"your current installation there are %d of these, marked with a grey folder "
		"icon in the catalogue below.",
		nbi);
	HTML_CLOSE("p");

@ We sometimes position a warning prominently at the top of the listing,
because otherwise its position at the bottom will be invisible unless the user
scrolls a long way:

@<Display a warning about any census errors which turned up@> =
	if ((C->no_census_errors > 0) &&
		(NUMBER_CREATED(extension_census_datum) >= 20)) { /* it's a short page anyway */
		HTML_OPEN("p");
		HTML_TAG_WITH("img", "border=0 src=inform:/doc_images/misinstalled.png");
		WRITE("&nbsp;"
			"<b>Warning</b>. One or more extensions are installed incorrectly: "
			"see details below.");
		HTML_CLOSE("p");
	}

@ The following is an alphabetised directory of extensions by author and then
title, along with some useful information about them, and then a list of
any oddities found in the external extensions area.

@<Display an alphabetised directory@> =
	int key_vms = FALSE, key_override = FALSE, key_builtin = FALSE,
		key_pspec = FALSE, key_bullet = FALSE;
	@<Display the census radio buttons@>;
	int no_entries = NUMBER_CREATED(extension_census_datum);
	extension_census_datum **sorted_census_results = Memory::calloc(no_entries,
		sizeof(extension_census_datum *), EXTENSION_DICTIONARY_MREASON);
	for (int d=1; d<=3; d++) {
		@<Start an HTML division for this sorted version of the census@>;
		@<Sort the census into the appropriate order@>;
		@<Display the sorted version of the census@>;
		HTML_CLOSE("div");
	}
	@<Print the key to any symbols used in the census lines@>;
	@<Transcribe any census errors@>;
	Memory::I7_array_free(sorted_census_results, EXTENSION_DICTIONARY_MREASON,
		no_entries, sizeof(extension_census_datum *));

@ I am the first to admit that this implementation is not inspired. There
are three radio buttons, and number 1 is selected by default.

@<Display the census radio buttons@> =
	HTML_OPEN("p");
	WRITE("Sort this list: ");
	HTML_OPEN_WITH("a",
		"href=\"#\" style=\"text-decoration: none\" "
		"onclick=\"openExtra('disp1', 'plus1'); closeExtra('disp2', 'plus2'); "
		"closeExtra('disp3', 'plus3'); return false;\"");
	HTML_TAG_WITH("img", "border=0 id=\"plus1\" src=inform:/doc_images/extrarbon.png");
	WRITE("&nbsp;By title");
	HTML_CLOSE("a");
	WRITE(" | ");
	HTML_OPEN_WITH("a",
		"href=\"#\" style=\"text-decoration: none\" "
		"onclick=\"closeExtra('disp1', 'plus1'); openExtra('disp2', 'plus2'); "
		"closeExtra('disp3', 'plus3'); return false;\"");
	HTML_TAG_WITH("img", "border=0 id=\"plus2\" src=inform:/doc_images/extrarboff.png");
	WRITE("&nbsp;By author");
	HTML_CLOSE("a");
	WRITE(" | ");
	HTML_OPEN_WITH("a",
		"href=\"#\" style=\"text-decoration: none\" "
		"onclick=\"closeExtra('disp1', 'plus1'); closeExtra('disp2', 'plus2'); "
		"openExtra('disp3', 'plus3'); return false;\"");
	HTML_TAG_WITH("img", "border=0 id=\"plus3\" src=inform:/doc_images/extrarboff.png");
	WRITE("&nbsp;By word count");
	HTML_CLOSE("a");
	HTML_CLOSE("p");

@ Consequently, of the three divisions, number 1 is shown and the others
hidden, by default.

@<Start an HTML division for this sorted version of the census@> =
	char *display = "none";
	if (d == SORT_CE_BY_TITLE) display = "block";
	HTML_OPEN_WITH("div", "id=\"disp%d\" style=\"display: %s;\"", d, display);

@ The key at the foot only explicates those symbols actually used, and
doesn't explicate the "unindexed" symbol at all, since that's actually
just a blank image used for horizontal spacing to keep margins straight.

@<Print the key to any symbols used in the census lines@> =
	if ((key_builtin) || (key_override) || (key_bullet) || (key_vms) || (key_pspec)) {
		HTML_OPEN("p");
		WRITE("Key: ");
		if (key_bullet) {
			HTML_TAG_WITH("img", "%s", INDEXED_SYMBOL);
			WRITE(" Used&nbsp;");
		}
		if (key_builtin) {
			HTML_TAG_WITH("img", "%s", BUILT_IN_SYMBOL);
			WRITE(" Built in&nbsp;");
		}
		if (key_pspec) {
			HTML_TAG_WITH("img", "%s", PROJECT_SPECIFIC_SYMBOL);
			WRITE(" Project specific&nbsp;");
		}
		if (key_override) {
			HTML_TAG_WITH("img", "%s", OVERRIDING_SYMBOL);
			WRITE(" Your version overrides the one built in&nbsp;");
		}
		if (key_vms) {
			#ifdef CORE_MODULE
			HTML_TAG("br");
			ExtensionIndex::write_key(OUT);
			#endif
		}
		HTML_CLOSE("p");
	}

@ Census errors are nothing more than copy errors arising on the copies
of extensions found by the census:

@<Transcribe any census errors@> =
	if (C->no_census_errors > 0) {
		@<Include the headnote explaining what census errors are@>;
		inbuild_search_result *R;
		LOOP_OVER_LINKED_LIST(R, inbuild_search_result, C->raw_data)
			if (LinkedLists::len(R->copy->errors_reading_source_text) > 0) {
				copy_error *CE;
				LOOP_OVER_LINKED_LIST(CE, copy_error,
					R->copy->errors_reading_source_text) {
					#ifdef INDEX_MODULE
					HTML::open_indented_p(OUT, 2, "hanging");
					#endif
					#ifndef INDEX_MODULE
					HTML_OPEN("p");
					#endif
					WRITE("<b>%X</b> - ", R->copy->edition->work);
					CopyErrors::write(OUT, CE);
					HTML_CLOSE("p");
				}
			}
	}

@ We only want to warn people here: not to stop them from using Inform
until they put matters right.

@<Include the headnote explaining what census errors are@> =
	HTML_TAG("hr");
	HTML_OPEN("p");
	HTML_TAG_WITH("img", "border=0 align=\"left\" src=inform:/doc_images/census_problem.png");
	WRITE("<b>Warning</b>. Inform checks the folder of user-installed extensions "
		"each time it translates the source text, in order to keep this directory "
		"page up to date. Each file must be a properly labelled extension (with "
		"its titling line correctly identifying itself), and must be in the right "
		"place - e.g. 'Marbles by Daphne Quilt' must have the filename 'Marbles.i7x' "
		"(or just 'Marbles' with no file extension) and be stored in the folder "
		"'Daphne Quilt'. The title should be at most %d characters long; the "
		"author name, %d. At the last check, these rules were not being followed:",
			MAX_EXTENSION_TITLE_LENGTH, MAX_EXTENSION_AUTHOR_LENGTH);
	HTML_CLOSE("p");

@

@d SORT_CE_BY_TITLE 1
@d SORT_CE_BY_AUTHOR 2
@d SORT_CE_BY_LENGTH 3

@<Sort the census into the appropriate order@> =
	int i = 0;
	extension_census_datum *ecd;
	LOOP_OVER(ecd, extension_census_datum)
		sorted_census_results[i++] = ecd;
	int (*criterion)(const void *, const void *) = NULL;
	switch (d) {
		case SORT_CE_BY_TITLE: criterion = ExtensionCensus::compare_ecd_by_title; break;
		case SORT_CE_BY_AUTHOR: criterion = ExtensionCensus::compare_ecd_by_author; break;
		case SORT_CE_BY_LENGTH: criterion = ExtensionCensus::compare_ecd_by_length; break;
		default: internal_error("no such sorting criterion");
	}
	qsort(sorted_census_results, (size_t) no_entries, sizeof(extension_census_datum *),
		criterion);

@ Standard rows have black text on striped background colours, these being
the usual ones seen in Mac OS X applications such as iTunes.

@<Display the sorted version of the census@> =
	HTML::begin_html_table(OUT, I"stripeone", TRUE, 0, 0, 2, 0, 0);
	@<Show a titling row explaining the census sorting, if necessary@>;
	int stripe = 0;
	TEMPORARY_TEXT(current_author_name)
	for (int i=0; i<no_entries; i++) {
		extension_census_datum *ecd = sorted_census_results[i];
		@<Insert a subtitling row in the census sorting, if necessary@>;
		stripe = 1 - stripe;
		if (stripe == 0)
			HTML::first_html_column_coloured(OUT, 0, I"stripetwo", 0);
		else
			HTML::first_html_column_coloured(OUT, 0, I"stripeone", 0);
		@<Print the census line for this extension@>;
		HTML::end_html_row(OUT);
	}
	DISCARD_TEXT(current_author_name)
	@<Show a final titling row closing the census sorting@>;
	HTML::end_html_table(OUT);

@<Show a titling row explaining the census sorting, if necessary@> =
	switch (d) {
		case SORT_CE_BY_TITLE:
			@<Begin a tinted census line@>;
			WRITE("Extensions in alphabetical order");
			@<End a tinted census line@>;
			break;
		case SORT_CE_BY_LENGTH:
			@<Begin a tinted census line@>;
			WRITE("Extensions in order of word count (longest first)");
			@<End a tinted census line@>;
			break;
	}

@<Insert a subtitling row in the census sorting, if necessary@> =
	if ((d == SORT_CE_BY_AUTHOR) &&
		(Str::ne(current_author_name, ecd->found_as->copy->edition->work->author_name))) {
		Str::copy(current_author_name, ecd->found_as->copy->edition->work->author_name);
		@<Begin a tinted census line@>;
		@<Print the author's line in the extension census table@>;
		@<End a tinted census line@>;
		stripe = 0;
	}

@<Show a final titling row closing the census sorting@> =
	@<Begin a tinted census line@>;
	HTML::begin_span(OUT, I"smaller");
	WRITE("%d extensions installed", no_entries);
	HTML::end_span(OUT);
	@<End a tinted census line@>;

@ Usually white text on a grey background.

@<Begin a tinted census line@> =
	int span = 4;
	if (d == SORT_CE_BY_TITLE) span = 3;
	HTML::first_html_column_coloured(OUT, 0, I"tintedrow", span);
	HTML::begin_span(OUT, I"extensioncensusentry");
	WRITE("&nbsp;");

@<End a tinted census line@> =
	HTML::end_span(OUT);
	HTML::end_html_row(OUT);

@ Used only in "by author".

@<Print the author's line in the extension census table@> =
	WRITE("%S", ecd->found_as->copy->edition->work->raw_author_name);

	extension_census_datum *ecd2;
	int cu = 0, cn = 0, j;
	for (j = i; j < no_entries; j++) {
		ecd2 = sorted_census_results[j];
		if (Str::ne(current_author_name,
			ecd2->found_as->copy->edition->work->author_name)) break;
		if (ExtensionCensus::ecd_used(ecd2)) cu++;
		else cn++;
	}
	WRITE("&nbsp;&nbsp;");
	HTML::begin_span(OUT, I"smaller");
	WRITE("(%d extension%s", cu+cn, (cu+cn==1)?"":"s");
	if ((cu == 0) && (cn == 1)) WRITE(", unused");
	else if ((cu == 0) && (cn == 2)) WRITE(", both unused");
	else if ((cu == 0) && (cn > 2)) WRITE(", all unused");
	else if ((cn == 0) && (cu == 1)) WRITE(", used");
	else if ((cn == 0) && (cu == 2)) WRITE(", both used");
	else if ((cn == 0) && (cu > 2)) WRITE(", all used");
	else if (cn+cu > 0) WRITE(", %d used, %d unused", cu, cn);
	WRITE(")");
	HTML::end_span(OUT);

@

@d UNINDEXED_SYMBOL "border=\"0\" src=\"inform:/doc_images/unindexed_bullet.png\""
@d INDEXED_SYMBOL "border=\"0\" src=\"inform:/doc_images/indexed_bullet.png\""

@<Print the census line for this extension@> =
	@<Print column 1 of the census line@>;
	HTML::next_html_column_nw(OUT, 0);
	if (d != SORT_CE_BY_TITLE) {
		@<Print column 2 of the census line@>;
		HTML::next_html_column_nw(OUT, 0);
	}
	@<Print column 3 of the census line@>;
	HTML::next_html_column_w(OUT, 0);
	@<Print column 4 of the census line@>;

@ The appearance of the line is

>> (bullet) The Title (by The Author) (VM requirement icons)

where all is optional except the title part.

@<Print column 1 of the census line@> =
	char *bulletornot = UNINDEXED_SYMBOL;
	if (ExtensionCensus::ecd_used(ecd)) {
		bulletornot = INDEXED_SYMBOL; key_bullet = TRUE;
	}
	WRITE("&nbsp;");
	HTML_TAG_WITH("img", "%s", bulletornot);

	Works::begin_extension_link(OUT,
		ecd->found_as->copy->edition->work, ExtensionCensus::ecd_rubric(ecd));
	HTML::begin_span(OUT, I"extensionindexentry");
	if (d != SORT_CE_BY_AUTHOR) {
		WRITE("%S", ecd->found_as->copy->edition->work->raw_title);
		if (Str::len(ecd->found_as->copy->edition->work->raw_title) +
			Str::len(ecd->found_as->copy->edition->work->raw_author_name) > 45) {
			HTML_TAG("br");
			WRITE("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;");
		} else {
			WRITE(" ");
		}
		WRITE("by %S", ecd->found_as->copy->edition->work->raw_author_name);
	} else {
		WRITE("%S", ecd->found_as->copy->edition->work->raw_title);
	}
	HTML::end_span(OUT);
	Works::end_extension_link(OUT, ecd->found_as->copy->edition->work);

	compatibility_specification *C = ecd->found_as->copy->edition->compatibility;
	if (Str::len(C->parsed_from) > 0) {
		@<Append icons which signify the VM requirements of the extension@>;
		key_vms = TRUE;
	}

@ VM requirements are parsed by feeding them into the lexer and calling the
same routines as would be used when parsing headings about VM requirements
in a normal run of Inform. Note that because the requirements are in round
brackets, which the lexer will split off as distinct words, we can ignore
the first and last word and just look at what is in between:

@<Append icons which signify the VM requirements of the extension@> =
	WRITE("&nbsp;%S", C->parsed_from);
	#ifdef CORE_MODULE
	ExtensionIndex::write_icons(OUT, C);
	#endif

@<Print column 2 of the census line@> =
	HTML::begin_span(OUT, I"smaller");
	if (VersionNumbers::is_null(ecd->found_as->copy->edition->version) == FALSE)
		WRITE("v&nbsp;%v", &(ecd->found_as->copy->edition->version));
	else
		WRITE("--");
	HTML::end_span(OUT);

@

@d BUILT_IN_SYMBOL "border=\"0\" src=\"inform:/doc_images/builtin_ext.png\""
@d OVERRIDING_SYMBOL "border=\"0\" src=\"inform:/doc_images/override_ext.png\""
@d PROJECT_SPECIFIC_SYMBOL "border=\"0\" src=\"inform:/doc_images/pspec_ext.png\""

@<Print column 3 of the census line@> =
	char *opener = "src='inform:/doc_images/folder4.png' border=0";
	if (Nests::get_tag(ecd->found_as->nest) == INTERNAL_NEST_TAG) {
		opener = BUILT_IN_SYMBOL; key_builtin = TRUE;
	}
	if (ecd->overriding_a_built_in_extension) {
		opener = OVERRIDING_SYMBOL; key_override = TRUE;
	}
	if (Nests::get_tag(ecd->found_as->nest) == MATERIALS_NEST_TAG) {
		opener = PROJECT_SPECIFIC_SYMBOL; key_pspec = TRUE;
	}
	if (Nests::get_tag(ecd->found_as->nest) == INTERNAL_NEST_TAG)
		HTML_TAG_WITH("img", "%s", opener)
	else {
		#ifdef INDEX_MODULE
		pathname *area = ExtensionManager::path_within_nest(ecd->found_as->nest);
		PasteButtons::open_file(OUT, area,
			ecd->found_as->copy->edition->work->raw_author_name, opener);
		#endif
	}

@<Print column 4 of the census line@> =
	inform_extension *E = Extensions::from_copy(ecd->found_as->copy);
	HTML::begin_span(OUT, I"smaller");
	if (d == SORT_CE_BY_LENGTH) {
		if (Extensions::get_word_count(E) == 0)
			WRITE("--");
		else
			WRITE("%d words", Extensions::get_word_count(E));
	} else {
		if (Str::len(ExtensionCensus::ecd_rubric(ecd)) > 0)
			WRITE("%S", ExtensionCensus::ecd_rubric(ecd));
		else
			WRITE("--");
	}
	HTML::end_span(OUT);

@h Icons for virtual machines.
And everything else is cosmetic: printing, or showing icons to signify,
the current VM or some set of permitted VMs. The following plots the
icon associated with a given minor VM, and explicates what the icons mean:

=
void ExtensionIndex::plot_icon(OUTPUT_STREAM, target_vm *VM) {
	if (Str::len(VM->VM_image) > 0) {
		HTML_TAG_WITH("img", "border=0 src=inform:/doc_images/%S", VM->VM_image);
		WRITE("&nbsp;");
	}
}

void ExtensionIndex::write_key(OUTPUT_STREAM) {
	WRITE("Extensions compatible with specific story file formats only: ");
	int i = 0;
	target_vm *VM;
	LOOP_OVER(VM, target_vm) {
		if (TargetVMs::debug_enabled(VM)) continue; /* avoids listing twice */
    	if (i++ > 0) WRITE(", ");
    	ExtensionIndex::plot_icon(OUT, VM);
		TargetVMs::write(OUT, VM);
	}
}

@h Displaying VM restrictions.
Given a word range, we describe the result as concisely as we can with a
row of icons (but do not bother for the common case where some extension
has no restriction on its use).

=
void ExtensionIndex::write_icons(OUTPUT_STREAM, compatibility_specification *C) {
	int something = FALSE, everything = TRUE;
	target_vm *VM;
	LOOP_OVER(VM, target_vm)
		if (Compatibility::test(C, VM))
			something = TRUE;
		else
			everything = FALSE;
	if (something == FALSE) WRITE("none");
	else if (everything == FALSE) {
		WRITE(" ");
		dictionary *shown_already = Dictionaries::new(16, TRUE);
		LOOP_OVER(VM, target_vm)
			if (Compatibility::test(C, VM)) {
				text_stream *icon = VM->VM_image;
				if (Str::len(icon) > 0) {
					if (Dictionaries::find(shown_already, icon) == NULL) {
						ExtensionIndex::plot_icon(OUT, VM);
						WRITE_TO(Dictionaries::create_text(shown_already, icon), "X");
					}
				}
			}
	}
}
