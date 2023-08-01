[ExtensionIndex::] Extensions Index Page.

To generate the index page for the extension mini-website, which is the home
page displayed in the Extensions tab for the Inform GUI apps.

@h Writing the extensions home page.
There were once two of these, but now there's just one.

=
void ExtensionIndex::write(inform_project *proj) {
	if (proj == NULL) internal_error("no project");
	filename *F = ExtensionWebsite::cut_way_for_index_page(proj);
	if (F == NULL) return;

	linked_list *L = NEW_LINKED_LIST(inbuild_search_result);
	linked_list *U = NEW_LINKED_LIST(inbuild_copy);
	linked_list *R = NEW_LINKED_LIST(inbuild_requirement);
	int internals_used = 0, materials_used = 0, externals_used = 0;
	int internals_installed = 0, materials_installed = 0;
	@<See what we have installed and used@>;

	text_stream HOMEPAGE_struct;
	text_stream *OUT = &HOMEPAGE_struct;
	if (STREAM_OPEN_TO_FILE(OUT, F, UTF8_ENC) == FALSE) return;
	InformPages::header(OUT, I"Extensions", JAVASCRIPT_FOR_ONE_EXTENSION_IRES, NULL);
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
	inbuild_requirement *req = Requirements::anything_of_genre(extension_bundle_genre);
	if (LinkedLists::len(search_list) > 0) Nests::search_for(req, search_list, L);
	ExtensionIndex::find_used_extensions(proj, U, R);
	inbuild_search_result *res;
	LOOP_OVER_LINKED_LIST(res, inbuild_search_result, L) {
		if (Nests::get_tag(res->nest) == INTERNAL_NEST_TAG) internals_installed++;
		else if (Nests::get_tag(res->nest) == MATERIALS_NEST_TAG) materials_installed++;
	}
	inbuild_copy *C;
	LOOP_OVER_LINKED_LIST(C, inbuild_copy, U)
		if (C->nest_of_origin) {
			switch (Nests::get_tag(C->nest_of_origin)) {
				case INTERNAL_NEST_TAG: internals_used++; break;
				case MATERIALS_NEST_TAG: materials_used++; break;
				default: externals_used++; Nests::add_search_result(L, C->nest_of_origin, C, req); break;
			}
		}

@<Write the body of the HTML@> =
	ExtensionWebsite::add_home_breadcrumb(I"Extensions in this Project");
	ExtensionWebsite::titling_and_navigation(OUT, I"Those installed and those used");

	HTML::begin_html_table(OUT, NULL, TRUE, 0, 4, 0, 0, 0);
	HTML::first_html_column(OUT, 0);
	HTML_TAG_WITH("img",
		"src='inform:/doc_images/extensions@2x.png' border=0 width=150 height=150");
	HTML::next_html_column(OUT, 0);

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
	if ((internals_used < internals_installed) || (materials_used < materials_installed)) {
		HTML_OPEN("p");
		HTML_OPEN("b");
		WRITE("These are available, but are not used by '%S'...", proj->as_copy->edition->work->title);
		HTML_CLOSE("b");
		HTML_CLOSE("p");
		usage_state = FALSE;
		@<Display an alphabetised directory@>;
	}

@<Display the location of installed extensions@> =
	HTML_OPEN("p");
	pathname *P = Nests::get_location(Projects::materials_nest(proj));
	P = Pathnames::down(P, I"Extensions");
	PasteButtons::open_file(OUT, P, NULL, PROJECT_SPECIFIC_SYMBOL);
	WRITE("&nbsp;");
	if (materials_installed > 0) {
		WRITE("%d extension%s installed in the .materials folder for the "
			"project '%S'",
			materials_installed, (materials_installed==1)?" is":"s are",
			proj->as_copy->edition->work->title);
		int i = materials_installed, u = materials_used;
		@<Say how many of those installed are used@>;
		WRITE(" (Click the icon to show the location.)");
	} else {
		WRITE("No extensions are installed in the .materials folder for the "
			"project '%S'. (Click the icon to show the location. "
			"Extensions should be put in the 'Extensions' subfolder of this: you "
			"can put them there yourself, or use the Inform app to install them "
			"for you.)", proj->as_copy->edition->work->title);
	}
	HTML_CLOSE("p");

	HTML_OPEN("p");
	HTML_TAG_WITH("img", BUILT_IN_SYMBOL);
	WRITE("&nbsp;");
	WRITE("The Inform app comes with a small number of built-in extensions, which "
		"you need not install, and which are automatically included if necessary. "
		"'%S' has access to %d", proj->as_copy->edition->work->title, internals_installed);
	int i = internals_installed, u = internals_used;
	@<Say how many of those installed are used@>;
	HTML_CLOSE("p");

	if (externals_used > 0) {
		HTML_OPEN("p");
		HTML_TAG_WITH("img", LEGACY_AREA_SYMBOL);
		WRITE("&nbsp;");
		WRITE("And '%S' still uses %d extension%s from the legacy extensions area. Best "
			"practice is to install %s into .materials instead, which the Inform app "
			"can do for you.",
			proj->as_copy->edition->work->title, externals_used, (externals_used==1)?"":"s", (externals_used==1)?"it":"them");
		HTML_CLOSE("p");
	}

@<Say how many of those installed are used@> =
	if (u == 0) {
		if (i == 1) {
			WRITE(", but it doesn't use it.");
		} else if (i == 2) {
			WRITE(", but it doesn't use either of them.");
		} else {
			WRITE(", but it doesn't use any of them.");
		}
	} else if (u < i) {
		WRITE(", but it uses only %d.", u);
	} else if (u == 1) {
		WRITE(", and it uses it.");
	} else if (u == 2) {
		WRITE(", and it uses both of them.");
	} else {
		WRITE(", and it uses all of them.");
	}		

@ The following is an alphabetised directory of extensions by author and then
title, along with some useful information about them, and then a list of
any oddities found in the external extensions area.

@<Display an alphabetised directory@> =
	linked_list *key_list = NEW_LINKED_LIST(extensions_key_item);
	int no_entries = LinkedLists::len(L);
	inbuild_search_result **sorted_census_results = Memory::calloc(no_entries,
		sizeof(inbuild_search_result *), RESULTS_SORTING_MREASON);
	int d = 3;
	int no_entries_in_set = 0;
	@<Sort the census into the appropriate order@>;
	@<Display the sorted version of the census@>;
	@<Print the key to any symbols used in the census lines@>;
	@<Transcribe any census errors@>;
	Memory::I7_array_free(sorted_census_results, RESULTS_SORTING_MREASON,
		no_entries, sizeof(inbuild_search_result *));

@<Print the key to any symbols used in the census lines@> =
	if (LinkedLists::len(key_list) > 0)
		ExtensionIndex::render_key(OUT, key_list);

@ Census errors are nothing more than copy errors arising on the copies
of extensions found by the census:

@<Transcribe any census errors@> =
	int no_census_errors = 0;
	for (int i=0; i<no_entries_in_set; i++) {
		inbuild_search_result *res = sorted_census_results[i];
		no_census_errors +=
			LinkedLists::len(res->copy->errors_reading_source_text);
	}
	if (no_census_errors > 0) {
		@<Include the headnote explaining what census errors are@>;
		for (int i=0; i<no_entries_in_set; i++) {
			inbuild_search_result *res = sorted_census_results[i];
			if (LinkedLists::len(res->copy->errors_reading_source_text) > 0) {
				copy_error *CE;
				LOOP_OVER_LINKED_LIST(CE, copy_error,
					res->copy->errors_reading_source_text) {
					#ifdef INDEX_MODULE
					HTML::open_indented_p(OUT, 2, "hanging");
					#endif
					#ifndef INDEX_MODULE
					HTML_OPEN("p");
					#endif
					WRITE("<b>%X</b> - ", res->copy->edition->work);
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
	inbuild_search_result *res;
	LOOP_OVER_LINKED_LIST(res, inbuild_search_result, L) {
		int found = FALSE;
		inbuild_copy *C;
		LOOP_OVER_LINKED_LIST(C, inbuild_copy, U)
			if (C == res->copy) {
				found = TRUE;
				break;
			}
		if (found == usage_state) sorted_census_results[i++] = res;
	}
	no_entries_in_set = i;
	int (*criterion)(const void *, const void *) = NULL;
	switch (d) {
		case SORT_CE_BY_TITLE: criterion = ExtensionIndex::compare_res_by_title; break;
		case SORT_CE_BY_AUTHOR: criterion = ExtensionIndex::compare_res_by_author; break;
		case SORT_CE_BY_LOCATION: criterion = ExtensionIndex::compare_res_by_location; break;
		case SORT_CE_BY_USAGE: criterion = ExtensionIndex::compare_res_by_title; break;
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
		inbuild_search_result *res = sorted_census_results[i];
		@<Insert a subtitling row in the census sorting, if necessary@>;
		stripe = 1 - stripe;
		if (stripe == 0)
			HTML::first_html_column_coloured(OUT, 0, I"stripetwo", 0);
		else
			HTML::first_html_column_coloured(OUT, 0, I"stripeone", 0);
		@<Print the census line for this extension@>;
		HTML::end_html_row(OUT);
		if (stripe == 0)
			ExtensionIndex::first_html_column_wrapping(OUT, 0, I"stripetwo", 4, 48, 4);
		else
			ExtensionIndex::first_html_column_wrapping(OUT, 0, I"stripeone", 4, 48, 4);
		@<Print the rubric line for this extension@>;
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
		(Str::ne(current_author_name, res->copy->edition->work->author_name))) {
		Str::copy(current_author_name, res->copy->edition->work->author_name);
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
	WRITE("%S", res->copy->edition->work->raw_author_name);

@<Print the census line for this extension@> =
	@<Print column 1 of the census line@>;
	HTML::next_html_column_nw(OUT, 0);
	@<Print column 2 of the census line@>;
	HTML::next_html_column_nw(OUT, 0);
	@<Print column 3 of the census line@>;
	HTML::next_html_column_w(OUT, 0);
	@<Print column 4 of the census line@>;

@<Print column 1 of the census line@> =
	inform_extension *E = Extensions::from_copy(res->copy);

	HTML::begin_span(OUT, I"extensionindexentry");
	if (LinkedLists::len(res->copy->errors_reading_source_text) == 0) {
		source_location sl = Extensions::top_line_location(E);
		if (sl.file_of_origin) {
			ExtensionIndex::add_to_key(key_list, REVEAL_SYMBOL,
				I"See source text (left of title: the whole extension; right: where it is Included");
			SourceLinks::link(OUT, sl, FALSE);
			WRITE(" ");
		}
	}
	if (d != SORT_CE_BY_AUTHOR) {
		WRITE("%S", res->copy->edition->work->raw_title);
		if (Nests::get_tag(res->nest) != INTERNAL_NEST_TAG)
			WRITE(" by %S", res->copy->edition->work->raw_author_name);
	} else {
		WRITE("%S", res->copy->edition->work->raw_title);
	}
	HTML::end_span(OUT);

	filename *F = ExtensionWebsite::page_filename(proj, res->copy->edition, -1);
	if (TextFiles::exists(F)) {
		WRITE(" ");
		TEMPORARY_TEXT(link)
		TEMPORARY_TEXT(URL)
		WRITE_TO(URL, "%f", ExtensionWebsite::page_filename_relative_to_materials(res->copy->edition, -1));
		WRITE_TO(link, "href='inform:/");
		Works::escape_apostrophes(link, URL);
		WRITE_TO(link, "' style=\"text-decoration: none\"");
		HTML_OPEN_WITH("a", "%S", link);
		DISCARD_TEXT(link)
		HTML_TAG_WITH("img", "%s", HELP_SYMBOL);
		ExtensionIndex::add_to_key(key_list, HELP_SYMBOL, I"Documentation (click to read)");
		HTML_CLOSE("a");
	}

	parse_node *at = Extensions::get_inclusion_sentence(E);
	if (at) {
		wording W = Node::get_text(at);
		source_location sl = Lexer::word_location(Wordings::first_wn(W));
		if (sl.file_of_origin) {
			SourceLinks::link(OUT, sl, TRUE);
			ExtensionIndex::add_to_key(key_list, REVEAL_SYMBOL,
				I"Open source (left of title: the whole extension; right: where it is Included");
		}
	}

	if (LinkedLists::len(res->copy->errors_reading_source_text) > 0) {
		WRITE(" ");
		HTML_TAG_WITH("img", "%s", PROBLEM_SYMBOL);
		ExtensionIndex::add_to_key(key_list, PROBLEM_SYMBOL, I"Has errors (see below)");
	} else {
		if (usage_state == FALSE) {
			WRITE(" ");
			TEMPORARY_TEXT(inclusion_text)
			WRITE_TO(inclusion_text, "Include %X.\n\n\n", res->copy->edition->work);
			ExtensionWebsite::paste_button(OUT, inclusion_text);
			DISCARD_TEXT(inclusion_text)
			ExtensionIndex::add_to_key(key_list, PASTE_SYMBOL,
				I"Source text to Include this (click to paste in)");
		}
	}

	compatibility_specification *C = res->copy->edition->compatibility;
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
	if (VersionNumbers::is_null(res->copy->edition->version) == FALSE)
		WRITE("v&nbsp;%v", &(res->copy->edition->version));
	else
		WRITE("--");
	HTML::end_span(OUT);

@<Print column 3 of the census line@> =
	char *opener = NULL;
	if (Nests::get_tag(res->nest) == INTERNAL_NEST_TAG) {
		opener = BUILT_IN_SYMBOL;
		ExtensionIndex::add_to_key(key_list, BUILT_IN_SYMBOL, I"Built in");
	} else if (Nests::get_tag(res->nest) == MATERIALS_NEST_TAG) {
		opener = PROJECT_SPECIFIC_SYMBOL;
		ExtensionIndex::add_to_key(key_list, PROJECT_SPECIFIC_SYMBOL, I"Installed in .materials");
	} else {
		opener = LEGACY_AREA_SYMBOL;
		ExtensionIndex::add_to_key(key_list, LEGACY_AREA_SYMBOL,
			I"Used from legacy extensions area");
	}
	if (Nests::get_tag(res->nest) == INTERNAL_NEST_TAG)
		HTML_TAG_WITH("img", "%s", opener)
	else {
		#ifdef INDEX_MODULE
		pathname *area = ExtensionManager::path_within_nest(res->nest);
		PasteButtons::open_file(OUT, area,
			res->copy->edition->work->raw_author_name, opener);
		#endif
	}

@<Print column 4 of the census line@> =
	HTML::begin_span(OUT, I"smaller");
	if (d == SORT_CE_BY_LOCATION) {
		if (Nests::get_tag(res->nest) == INTERNAL_NEST_TAG)
			WRITE("Built in to Inform");
		else
			WRITE("Installed in this project");
	} else {
		text_stream *R = Extensions::get_rubric(Extensions::from_copy(res->copy));
		if (Str::len(R) > 0) WRITE("%S", R); else WRITE("--");
	}
	HTML::end_span(OUT);

@<Print the rubric line for this extension@> =
	HTML::begin_span(OUT, I"smaller");
	text_stream *R = Extensions::get_rubric(Extensions::from_copy(res->copy));
	if (Str::len(R) > 0) WRITE("%S", R); else WRITE("--");
	HTML::end_span(OUT);

@ This is just too special-purpose to belong in the foundation module.

=
void ExtensionIndex::first_html_column_wrapping(OUTPUT_STREAM, int width, text_stream *classname,
	int cs, int left_padding, int bottom_padding) {
	if (Str::len(classname) > 0)
		HTML_OPEN_WITH("tr", "class=\"%S\"", classname)
	else
		HTML_OPEN("tr");
	TEMPORARY_TEXT(col)
	WRITE_TO(col, "align=\"left\" valign=\"top\"");
	if (width > 0) WRITE_TO(col, " width=\"%d\"", width);
	if (cs > 0) WRITE_TO(col, " colspan=\"%d\"", cs);
	if ((left_padding > 0) || (bottom_padding > 0)) {
		WRITE_TO(col, " style=\"");
		if (left_padding > 0) WRITE_TO(col, "padding-left: %dpx;", left_padding);
		if (bottom_padding > 0) WRITE_TO(col, "padding-bottom: %dpx;", bottom_padding);
		WRITE_TO(col, "\"");
	}
	HTML_OPEN_WITH("td", "%S", col);
	DISCARD_TEXT(col)
}

@h The key.
There is just no need to do this efficiently in either running time or memory.

@d PROBLEM_SYMBOL "border=\"0\" height=\"12\" src=\"inform:/doc_images/census_problem.png\""
@d REVEAL_SYMBOL "border=\"0\" src=\"inform:/doc_images/Reveal.png\""
@d HELP_SYMBOL "border=\"0\" src=\"inform:/doc_images/help.png\""
@d PASTE_SYMBOL "paste"
@d BUILT_IN_SYMBOL "border=\"0\" src=\"inform:/doc_images/builtin_ext.png\""
@d PROJECT_SPECIFIC_SYMBOL "border=\"0\" src=\"inform:/doc_images/folder4.png\""
@d LEGACY_AREA_SYMBOL "border=\"0\" src=\"inform:/doc_images/pspec_ext.png\""
@d ARCH_16_SYMBOL "border=\"0\" src=\"inform:/doc_images/vm_z8.png\""
@d ARCH_32_SYMBOL "border=\"0\" src=\"inform:/doc_images/vm_glulx.png\""

=
typedef struct extensions_key_item {
	struct text_stream *image_URL;
	struct text_stream *gloss;
	int displayed;
	int ideograph;
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
		eki->displayed = FALSE;
		eki->ideograph = FALSE;
		if (Str::eq(as_text, I"paste")) eki->ideograph = TRUE;
		ADD_TO_LINKED_LIST(eki, extensions_key_item, L);
	}
	DISCARD_TEXT(as_text)
}

void ExtensionIndex::render_key(OUTPUT_STREAM, linked_list *L) {
	HTML_OPEN("p");
	WRITE("Key: ");
	char *sequence[] = {
		PROJECT_SPECIFIC_SYMBOL, BUILT_IN_SYMBOL, LEGACY_AREA_SYMBOL,
		HELP_SYMBOL, REVEAL_SYMBOL, PASTE_SYMBOL, PROBLEM_SYMBOL,
		ARCH_16_SYMBOL, ARCH_32_SYMBOL,
		NULL };
	for (int i=0; sequence[i] != NULL; i++) {
		TEMPORARY_TEXT(as_text)
		WRITE_TO(as_text, "%s", sequence[i]);
		extensions_key_item *eki;
		LOOP_OVER_LINKED_LIST(eki, extensions_key_item, L) {
			if (Str::eq(eki->image_URL, as_text)) {
				ExtensionIndex::render_icon(OUT, eki);
				WRITE("&nbsp;%S &nbsp;&nbsp;", eki->gloss);
				eki->displayed = TRUE;
			}
		}
		DISCARD_TEXT(as_text)
	}
	extensions_key_item *eki;
	LOOP_OVER_LINKED_LIST(eki, extensions_key_item, L) {
		if (eki->displayed == FALSE) {
			ExtensionIndex::render_icon(OUT, eki);
			WRITE("&nbsp;%S &nbsp;&nbsp;", eki->gloss);
			eki->displayed = TRUE;
		}
	}
	HTML_CLOSE("p");
}

void ExtensionIndex::render_icon(OUTPUT_STREAM, extensions_key_item *eki) {
	if (eki->ideograph) {
		ExtensionWebsite::paste_ideograph(OUT);
	} else {
		HTML_TAG_WITH("img", "%S", eki->image_URL);
	}
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
int ExtensionIndex::compare_res_by_title(const void *res1, const void *res2) {
	inbuild_search_result *e1 = *((inbuild_search_result **) res1);
	inbuild_search_result *e2 = *((inbuild_search_result **) res2);
	inform_extension *E1 = Extensions::from_copy(e1->copy);
	inform_extension *E2 = Extensions::from_copy(e2->copy);
	return Extensions::compare_by_title(E2, E1);
}

int ExtensionIndex::compare_res_by_author(const void *res1, const void *res2) {
	inbuild_search_result *e1 = *((inbuild_search_result **) res1);
	inbuild_search_result *e2 = *((inbuild_search_result **) res2);
	inform_extension *E1 = Extensions::from_copy(e1->copy);
	inform_extension *E2 = Extensions::from_copy(e2->copy);
	return Extensions::compare_by_author(E2, E1);
}

int ExtensionIndex::compare_res_by_location(const void *res1, const void *res2) {
	inbuild_search_result *e1 = *((inbuild_search_result **) res1);
	inbuild_search_result *e2 = *((inbuild_search_result **) res2);
	int d = Nests::get_tag(e1->nest) - Nests::get_tag(e2->nest);
	if (d != 0) return d;
	return ExtensionIndex::compare_res_by_title(res1, res2);
}
