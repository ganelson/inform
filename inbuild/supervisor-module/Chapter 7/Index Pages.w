[ExtensionIndex::] Index Pages.

To generate the two top-level pages in the extension mini-website.

@h Writing the extensions home page.
There were once two of these, but now there's just one.

=
void ExtensionIndex::write(inform_project *proj) {
	filename *F = ExtensionWebsite::index_URL(proj, I"Extensions.html");
	if (F == NULL) return;

	linked_list *L = NEW_LINKED_LIST(inbuild_search_result);
	linked_list *U = NEW_LINKED_LIST(inbuild_copy);
	linked_list *R = NEW_LINKED_LIST(inbuild_requirement);
	@<See what we have installed and used@>;

	text_stream HOMEPAGE_struct;
	text_stream *OUT = &HOMEPAGE_struct;
	if (STREAM_OPEN_TO_FILE(OUT, F, UTF8_ENC) == FALSE) return;
	InformPages::header(OUT, I"Extensions", JAVASCRIPT_FOR_EXTENSIONS_IRES, NULL);
	@<Write the body of the HTML@>;
	InformPages::footer(OUT);
	STREAM_CLOSE(OUT);
}

@<See what we have installed and used@> =
	linked_list *search_list = NEW_LINKED_LIST(inbuild_nest);
	inbuild_nest *materials = Projects::materials_nest(proj);
	if (materials) ADD_TO_LINKED_LIST(materials, inbuild_nest, search_list);
	inbuild_nest *internal = Supervisor::internal();
	if (internal) ADD_TO_LINKED_LIST(internal, inbuild_nest, search_list);
	if (LinkedLists::len(search_list) > 0) {
		inbuild_requirement *req = Requirements::anything_of_genre(extension_bundle_genre);
		Nests::search_for(req, search_list, L);
	}
	ExtensionIndex::find_used_extensions(proj, U, R);

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
	WRITE("Those installed and those used");
	HTML::end_span(OUT);
	HTML_CLOSE("div");
	HTML_CLOSE("div");
	@<Display the location of installed extensions@>;
	HTML::end_html_row(OUT);
	HTML::end_html_table(OUT);
	HTML_TAG("hr");
	HTML_OPEN("p");
	HTML_OPEN("b");
	WRITE("The project '%S' currently uses...", proj->as_copy->edition->work->title);
	HTML_CLOSE("b");
	HTML_CLOSE("p");
	int usage_state = TRUE;
	@<Display an alphabetised directory@>;
	HTML_TAG("hr");
	HTML_OPEN("p");
	HTML_OPEN("b");
	WRITE("These are available, but are not used by '%S'...", proj->as_copy->edition->work->title);
	HTML_CLOSE("b");
	HTML_CLOSE("p");
	usage_state = FALSE;
	@<Display an alphabetised directory@>;

@ From here on, then, all the code in this section generates the main directory
page, not the index of terms, which is all handled by
//ExtensionDictionary::write_to_HTML//.

@<Display the location of installed extensions@> =
	int nbi = 0, nps = 0;
	inbuild_search_result *ecd;
	LOOP_OVER_LINKED_LIST(ecd, inbuild_search_result, L) {
		if (Nests::get_tag(ecd->nest) == INTERNAL_NEST_TAG) nbi++;
		else nps++;
	}

	HTML_OPEN("p");
	pathname *P = Nests::get_location(Projects::materials_nest(proj));
	P = Pathnames::down(P, I"Extensions");
	PasteButtons::open_file(OUT, P, NULL, PROJECT_SPECIFIC_SYMBOL);
	WRITE("&nbsp;");
	if (nps > 0) {
		WRITE("%d extension%s installed in the .materials folder for the "
			"project '%S'. (Click the purple folder icon to show the location.)",
			nps, (nps==1)?" is":"s are", proj->as_copy->edition->work->title);
	} else {
		WRITE("No extensions are installed in the .materials folder for the "
			"project '%S'. (Click the purple folder icon to show the location. "
			"Extensions should be put in the 'Extensions' subfolder of this: you "
			"can put them there yourself, or use the Inform app to install them "
			"for you.)", proj->as_copy->edition->work->title);
	}
	HTML_CLOSE("p");

	HTML_OPEN("p");
	HTML_TAG_WITH("img", "src='inform:/doc_images/builtin_ext.png' border=0");
	WRITE("&nbsp;");
	WRITE("As well as being able to use extensions installed into its own folder, "
		"any project can use extensions which come built into the Inform app. There "
		"are currently %d.", nbi);
	HTML_CLOSE("p");

@ The following is an alphabetised directory of extensions by author and then
title, along with some useful information about them, and then a list of
any oddities found in the external extensions area.

@<Display an alphabetised directory@> =
	linked_list *key_list = NEW_LINKED_LIST(extensions_key_item);
	if (usage_state == FALSE) @<Display the census radio buttons@>;
	int no_entries = LinkedLists::len(L);
	inbuild_search_result **sorted_census_results = Memory::calloc(no_entries,
		sizeof(inbuild_search_result *), EXTENSION_DICTIONARY_MREASON);
	for (int d=((usage_state)?4:1); d<=((usage_state)?4:3); d++) {
		@<Start an HTML division for this sorted version of the census@>;
		int no_entries_in_set = 0;
		@<Sort the census into the appropriate order@>;
		@<Display the sorted version of the census@>;
		@<Print the key to any symbols used in the census lines@>;
		@<Transcribe any census errors@>;
		HTML_CLOSE("div");
	}
	Memory::I7_array_free(sorted_census_results, EXTENSION_DICTIONARY_MREASON,
		no_entries, sizeof(inbuild_search_result *));

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
	WRITE("&nbsp;By location");
	HTML_CLOSE("a");
	HTML_CLOSE("p");

@ Consequently, of the three divisions, number 1 is shown and the others
hidden, by default.

@<Start an HTML division for this sorted version of the census@> =
	char *display = "none";
	if ((d == SORT_CE_BY_TITLE) || (d == SORT_CE_BY_USAGE)) display = "block";
	HTML_OPEN_WITH("div", "id=\"disp%d\" style=\"display: %s;\"", d, display);

@ The key at the foot only explicates those symbols actually used, and
doesn't explicate the "unindexed" symbol at all, since that's actually
just a blank image used for horizontal spacing to keep margins straight.

@<Print the key to any symbols used in the census lines@> =
	if (LinkedLists::len(key_list) > 0) {
		HTML_OPEN("p");
		WRITE("Key: ");
		extensions_key_item *eki;
		LOOP_OVER_LINKED_LIST(eki, extensions_key_item, key_list) {
			HTML_TAG_WITH("img", "%S", eki->image_URL);
			WRITE("&nbsp;%S &nbsp;&nbsp;", eki->gloss);
		}
		HTML_CLOSE("p");
	}

@ Census errors are nothing more than copy errors arising on the copies
of extensions found by the census:

@<Transcribe any census errors@> =
	int no_census_errors = 0;
	for (int i=0; i<no_entries_in_set; i++) {
		inbuild_search_result *ecd = sorted_census_results[i];
		no_census_errors +=
			LinkedLists::len(ecd->copy->errors_reading_source_text);
	}
	if (no_census_errors > 0) {
		@<Include the headnote explaining what census errors are@>;
		for (int i=0; i<no_entries_in_set; i++) {
			inbuild_search_result *ecd = sorted_census_results[i];
			if (LinkedLists::len(ecd->copy->errors_reading_source_text) > 0) {
				copy_error *CE;
				LOOP_OVER_LINKED_LIST(CE, copy_error,
					ecd->copy->errors_reading_source_text) {
					#ifdef INDEX_MODULE
					HTML::open_indented_p(OUT, 2, "hanging");
					#endif
					#ifndef INDEX_MODULE
					HTML_OPEN("p");
					#endif
					WRITE("<b>%X</b> - ", ecd->copy->edition->work);
					CopyErrors::write(OUT, CE);
					HTML_CLOSE("p");
				}
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
@d SORT_CE_BY_LOCATION 3
@d SORT_CE_BY_USAGE 4

@<Sort the census into the appropriate order@> =
	int i = 0;
	inbuild_search_result *ecd;
	LOOP_OVER_LINKED_LIST(ecd, inbuild_search_result, L) {
		int found = FALSE;
		inbuild_copy *C;
		LOOP_OVER_LINKED_LIST(C, inbuild_copy, U)
			if (C == ecd->copy) {
				found = TRUE;
				break;
			}
		if (found == usage_state) sorted_census_results[i++] = ecd;
	}
	no_entries_in_set = i;
	int (*criterion)(const void *, const void *) = NULL;
	switch (d) {
		case SORT_CE_BY_TITLE: criterion = ExtensionIndex::compare_ecd_by_title; break;
		case SORT_CE_BY_AUTHOR: criterion = ExtensionIndex::compare_ecd_by_author; break;
		case SORT_CE_BY_LOCATION: criterion = ExtensionIndex::compare_ecd_by_location; break;
		case SORT_CE_BY_USAGE: criterion = ExtensionIndex::compare_ecd_by_title; break;
		default: internal_error("no such sorting criterion");
	}
	qsort(sorted_census_results, (size_t) no_entries_in_set, sizeof(inbuild_search_result *),
		criterion);

@ Standard rows have black text on striped background colours, these being
the usual ones seen in Mac OS X applications such as iTunes.

@<Display the sorted version of the census@> =
	HTML::begin_html_table(OUT, I"stripeone", TRUE, 0, 0, 2, 0, 0);
	@<Show a titling row explaining the census sorting, if necessary@>;
	int stripe = 0;
	TEMPORARY_TEXT(current_author_name)
	for (int i=0; i<no_entries_in_set; i++) {
		inbuild_search_result *ecd = sorted_census_results[i];
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
		case SORT_CE_BY_USAGE:
			@<Begin a tinted census line@>;
			WRITE("Extensions in alphabetical order");
			@<End a tinted census line@>;
			break;
		case SORT_CE_BY_LOCATION:
			@<Begin a tinted census line@>;
			WRITE("Extensions grouped by location");
			@<End a tinted census line@>;
			break;
	}

@<Insert a subtitling row in the census sorting, if necessary@> =
	if ((d == SORT_CE_BY_AUTHOR) &&
		(Str::ne(current_author_name, ecd->copy->edition->work->author_name))) {
		Str::copy(current_author_name, ecd->copy->edition->work->author_name);
		@<Begin a tinted census line@>;
		@<Print the author's line in the extension census table@>;
		@<End a tinted census line@>;
		stripe = 0;
	}

@<Show a final titling row closing the census sorting@> =
	@<Begin a tinted census line@>;
	HTML::begin_span(OUT, I"smaller");
	WRITE("%d extensions in total", no_entries_in_set);
	HTML::end_span(OUT);
	@<End a tinted census line@>;

@ Usually white text on a grey background.

@<Begin a tinted census line@> =
	HTML::first_html_column_coloured(OUT, 0, I"tintedrow", 4);
	HTML::begin_span(OUT, I"extensioncensusentry");
	WRITE("&nbsp;");

@<End a tinted census line@> =
	HTML::end_span(OUT);
	HTML::end_html_row(OUT);

@ Used only in "by author".

@<Print the author's line in the extension census table@> =
	WRITE("%S", ecd->copy->edition->work->raw_author_name);

@

@d UNINDEXED_SYMBOL "border=\"0\" src=\"inform:/doc_images/unindexed_bullet.png\""
@d INDEXED_SYMBOL "border=\"0\" src=\"inform:/doc_images/indexed_bullet.png\""
@d PROBLEM_SYMBOL "border=\"0\" height=\"12\" src=\"inform:/doc_images/census_problem.png\""
@d REVEAL_SYMBOL "border=\"0\" src=\"inform:/doc_images/Reveal.png\""
@d HELP_SYMBOL "border=\"0\" src=\"inform:/doc_images/help.png\""
@d PASTE_SYMBOL "border=\"0\" src=\"inform:/doc_images/paste.png\""

@<Print the census line for this extension@> =
	@<Print column 1 of the census line@>;
	HTML::next_html_column_nw(OUT, 0);
	@<Print column 2 of the census line@>;
	HTML::next_html_column_nw(OUT, 0);
	@<Print column 3 of the census line@>;
	HTML::next_html_column_w(OUT, 0);
	@<Print column 4 of the census line@>;

@<Print column 1 of the census line@> =
	HTML::begin_span(OUT, I"extensionindexentry");
	if (d != SORT_CE_BY_AUTHOR) {
		WRITE("%S", ecd->copy->edition->work->raw_title);
		if (Str::len(ecd->copy->edition->work->raw_title) +
			Str::len(ecd->copy->edition->work->raw_author_name) > 45) {
			HTML_TAG("br");
			WRITE("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;");
		} else {
			WRITE(" ");
		}
		WRITE("by %S", ecd->copy->edition->work->raw_author_name);
	} else {
		WRITE("%S", ecd->copy->edition->work->raw_title);
	}
	HTML::end_span(OUT);

	filename *F = ExtensionWebsite::abs_page_URL(proj, ecd->copy->edition, -1);
	if (TextFiles::exists(F)) {
		WRITE(" ");
		TEMPORARY_TEXT(link)
		TEMPORARY_TEXT(URL)
		WRITE_TO(URL, "%f", ExtensionWebsite::rel_page_URL(ecd->copy->edition, -1));
		WRITE_TO(link, "href='inform:/");
		Works::escape_apostrophes(link, URL);
		WRITE_TO(link, "' style=\"text-decoration: none\"");
		HTML_OPEN_WITH("a", "%S", link);
		DISCARD_TEXT(link)
		HTML_TAG_WITH("img", "%s", HELP_SYMBOL);
		ExtensionIndex::add_to_key(key_list, HELP_SYMBOL, I"Documentation (click to read)");
		HTML_CLOSE("a");
	}

	inform_extension *E = Extensions::from_copy(ecd->copy);
	parse_node *at = Extensions::get_inclusion_sentence(E);
	if (at) {
		wording W = Node::get_text(at);
		source_location sl = Lexer::word_location(Wordings::first_wn(W));
		SourceLinks::link(OUT, sl, TRUE);
		ExtensionIndex::add_to_key(key_list, REVEAL_SYMBOL, I"Included here (click to see)");
	}

	if (LinkedLists::len(ecd->copy->errors_reading_source_text) > 0) {
		WRITE(" ");
		HTML_TAG_WITH("img", "%s", PROBLEM_SYMBOL);
		ExtensionIndex::add_to_key(key_list, PROBLEM_SYMBOL, I"Has errors (see below)");
	} else if (usage_state == FALSE) {
		WRITE(" ");
		TEMPORARY_TEXT(inclusion_text)
		WRITE_TO(inclusion_text, "Include %X.\n\n\n", ecd->copy->edition->work);
		PasteButtons::paste_text(OUT, inclusion_text);
		DISCARD_TEXT(inclusion_text)
		ExtensionIndex::add_to_key(key_list, PASTE_SYMBOL,
			I"Source text to Include this (click to paste in)");
	}

	compatibility_specification *C = ecd->copy->edition->compatibility;
	if (Str::len(C->parsed_from) > 0)
		@<Append icons which signify the VM requirements of the extension@>;

@ VM requirements are parsed by feeding them into the lexer and calling the
same routines as would be used when parsing headings about VM requirements
in a normal run of Inform. Note that because the requirements are in round
brackets, which the lexer will split off as distinct words, we can ignore
the first and last word and just look at what is in between:

@<Append icons which signify the VM requirements of the extension@> =
	ExtensionIndex::write_icons(OUT, key_list, C);

@<Print column 2 of the census line@> =
	HTML::begin_span(OUT, I"smaller");
	if (VersionNumbers::is_null(ecd->copy->edition->version) == FALSE)
		WRITE("v&nbsp;%v", &(ecd->copy->edition->version));
	else
		WRITE("--");
	HTML::end_span(OUT);

@

@d BUILT_IN_SYMBOL "border=\"0\" src=\"inform:/doc_images/builtin_ext.png\""
@d PROJECT_SPECIFIC_SYMBOL "border=\"0\" src=\"inform:/doc_images/pspec_ext.png\""
@d ARCH_16_SYMBOL "border=\"0\" src=\"inform:/doc_images/vm_z8.png\""
@d ARCH_32_SYMBOL "border=\"0\" src=\"inform:/doc_images/vm_glulx.png\""

@<Print column 3 of the census line@> =
	char *opener = "src='inform:/doc_images/folder4.png' border=0";
	if (Nests::get_tag(ecd->nest) == INTERNAL_NEST_TAG) {
		opener = BUILT_IN_SYMBOL;
		ExtensionIndex::add_to_key(key_list, BUILT_IN_SYMBOL, I"Built in");
	}
	if (Nests::get_tag(ecd->nest) == MATERIALS_NEST_TAG) {
		opener = PROJECT_SPECIFIC_SYMBOL;
		ExtensionIndex::add_to_key(key_list, PROJECT_SPECIFIC_SYMBOL, I"Installed in .materials");
	}
	if (Nests::get_tag(ecd->nest) == INTERNAL_NEST_TAG)
		HTML_TAG_WITH("img", "%s", opener)
	else {
		#ifdef INDEX_MODULE
		pathname *area = ExtensionManager::path_within_nest(ecd->nest);
		PasteButtons::open_file(OUT, area,
			ecd->copy->edition->work->raw_author_name, opener);
		#endif
	}

@<Print column 4 of the census line@> =
	HTML::begin_span(OUT, I"smaller");
	if (d == SORT_CE_BY_LOCATION) {
		if (Nests::get_tag(ecd->nest) == INTERNAL_NEST_TAG)
			WRITE("Built in to Inform");
		else
			WRITE("Installed in this project");
	} else {
		if (Str::len(ExtensionIndex::ecd_rubric(ecd)) > 0)
			WRITE("%S", ExtensionIndex::ecd_rubric(ecd));
		else
			WRITE("--");
	}
	HTML::end_span(OUT);

@h The key.
There is just no need to do this efficiently in either running time or memory.

=
typedef struct extensions_key_item {
	struct text_stream *image_URL;
	struct text_stream *gloss;
	CLASS_DEFINITION
} extensions_key_item;

void ExtensionIndex::add_to_key(linked_list *L, char *URL, text_stream *gloss) {
	TEMPORARY_TEXT(as_text)
	WRITE_TO(as_text, "%s", URL);
	int found = FALSE;
	extensions_key_item *eki;
	LOOP_OVER_LINKED_LIST(eki, extensions_key_item, L)
		if (Str::eq(eki->image_URL, as_text))
			found = TRUE;
	if (found == FALSE) {
		eki = CREATE(extensions_key_item);
		eki->image_URL = Str::duplicate(as_text);
		eki->gloss = Str::duplicate(gloss);
		ADD_TO_LINKED_LIST(eki, extensions_key_item, L);
	}
	DISCARD_TEXT(as_text)
}

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

@h Displaying VM restrictions.
Given a word range, we describe the result as concisely as we can with a
row of icons (but do not bother for the common case where some extension
has no restriction on its use).

=
void ExtensionIndex::write_icons(OUTPUT_STREAM, linked_list *key_list,
	compatibility_specification *C) {
	int something_16 = FALSE, everything_16 = TRUE, something_32 = FALSE, everything_32 = TRUE;
	target_vm *VM;
	LOOP_OVER(VM, target_vm)
		if (Architectures::is_16_bit(VM->architecture)) {
			if (Compatibility::test(C, VM))
				something_16 = TRUE;
			else
				everything_16 = FALSE;
		} else {
			if (Compatibility::test(C, VM))
				something_32 = TRUE;
			else
				everything_32 = FALSE;
		}
	if ((everything_16) && (everything_32)) return;
	if ((everything_16) && (something_32 == FALSE)) {
		WRITE(" ");
		HTML_TAG_WITH("img", "%s", ARCH_16_SYMBOL);
		ExtensionIndex::add_to_key(key_list, ARCH_16_SYMBOL, I"Z-machine only (16-bit)");
		return;
	}
	if ((everything_32) && (something_16 == FALSE)) {
		WRITE(" ");
		HTML_TAG_WITH("img", "%s", ARCH_32_SYMBOL);
		ExtensionIndex::add_to_key(key_list, ARCH_32_SYMBOL, I"Glulx only (32-bit)");
		return;
	}
	WRITE(" - %S ", C->parsed_from);
	dictionary *shown_already = Dictionaries::new(16, TRUE);
	LOOP_OVER(VM, target_vm)
		if (Compatibility::test(C, VM)) {
			text_stream *icon = VM->VM_image;
			if (Str::len(icon) > 0) {
				if (Dictionaries::find(shown_already, icon) == NULL) {
					ExtensionIndex::plot_icon(OUT, VM);
					WRITE_TO(Dictionaries::create_text(shown_already, icon), "X");
					ExtensionIndex::add_to_key(key_list, ARCH_16_SYMBOL, I"Z-machine only (16-bit)");
					ExtensionIndex::add_to_key(key_list, ARCH_32_SYMBOL, I"Glulx only (32-bit)");
				}
			}
		}
}

@

=
void ExtensionIndex::find_used_extensions(inform_project *proj,
	linked_list *U, linked_list *R) {
	build_vertex *V = Copies::construct_project_graph(proj->as_copy);
	ExtensionIndex::find_used_extensions_r(V, Graphs::get_unique_graph_scan_count(), U, R);
}

void ExtensionIndex::find_used_extensions_r(build_vertex *V, int scan_count,
	linked_list *U, linked_list *R) {
	if (V->type == COPY_VERTEX) {
		inbuild_copy *C = V->as_copy;
		if ((C->edition->work->genre == extension_genre) ||
			(C->edition->work->genre == extension_bundle_genre)) {
			if (C->last_scanned != scan_count) {
				ADD_TO_LINKED_LIST(C, inbuild_copy, U);
				C->last_scanned = scan_count;
			}
		}
	}
	if (V->type == REQUIREMENT_VERTEX) {
		if ((V->as_requirement->work->genre == extension_genre) ||
			(V->as_requirement->work->genre == extension_bundle_genre)) {
			ADD_TO_LINKED_LIST(V->as_requirement, inbuild_requirement, R);
		}
	}
	build_vertex *W;
	LOOP_OVER_LINKED_LIST(W, build_vertex, V->build_edges)
		ExtensionIndex::find_used_extensions_r(W, scan_count, U, R);
	LOOP_OVER_LINKED_LIST(W, build_vertex, V->use_edges)
		ExtensionIndex::find_used_extensions_r(W, scan_count, U, R);
}

@h Sorting criteria.
The following give some sorting criteria, and are functions fit to be
handed to |qsort|.

=
int ExtensionIndex::compare_ecd_by_title(const void *ecd1, const void *ecd2) {
	inbuild_search_result *e1 = *((inbuild_search_result **) ecd1);
	inbuild_search_result *e2 = *((inbuild_search_result **) ecd2);
	inform_extension *E1 = Extensions::from_copy(e1->copy);
	inform_extension *E2 = Extensions::from_copy(e2->copy);
	return Extensions::compare_by_title(E2, E1);
}

int ExtensionIndex::compare_ecd_by_author(const void *ecd1, const void *ecd2) {
	inbuild_search_result *e1 = *((inbuild_search_result **) ecd1);
	inbuild_search_result *e2 = *((inbuild_search_result **) ecd2);
	inform_extension *E1 = Extensions::from_copy(e1->copy);
	inform_extension *E2 = Extensions::from_copy(e2->copy);
	return Extensions::compare_by_author(E2, E1);
}

int ExtensionIndex::compare_ecd_by_location(const void *ecd1, const void *ecd2) {
	inbuild_search_result *e1 = *((inbuild_search_result **) ecd1);
	inbuild_search_result *e2 = *((inbuild_search_result **) ecd2);
	int d = Nests::get_tag(e1->nest) - Nests::get_tag(e2->nest);
	if (d != 0) return d;
	return ExtensionIndex::compare_ecd_by_title(ecd1, ecd2);
}

int ExtensionIndex::ecd_used(inbuild_search_result *ecd) {
	inform_extension *E = Extensions::from_copy(ecd->copy);
	return E->has_historically_been_used;
}

text_stream *ExtensionIndex::ecd_rubric(inbuild_search_result *ecd) {
	return Extensions::get_rubric(Extensions::from_copy(ecd->copy));
}
