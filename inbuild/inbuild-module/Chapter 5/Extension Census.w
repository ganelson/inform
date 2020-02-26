[Extensions::Census::] Extension Census.

To conduct a census of all the extensions installed (whether used
on this run or not), and keep the documentation index for them up to date.

@

=
typedef struct extension_census {
	struct linked_list *search_list; /* of |inbuild_nest| */
	struct linked_list *census_data; /* of |extension_census_datum| */
	struct linked_list *raw_data; /* of |inbuild_search_result| */
	int no_census_errors;
	MEMORY_MANAGEMENT
} extension_census;

extension_census *Extensions::Census::new(void) {
	extension_census *C = CREATE(extension_census);
	C->search_list = Inbuild::nest_list();
	C->census_data = NEW_LINKED_LIST(extension_census_datum);
	C->raw_data = NEW_LINKED_LIST(inbuild_search_result);
	C->no_census_errors = 0;
	return C;
}

pathname *Extensions::Census::internal_path(extension_census *C) {
	inbuild_nest *N = NULL;
	LOOP_OVER_LINKED_LIST(N, inbuild_nest, C->search_list)
		if (Nests::get_tag(N) == INTERNAL_NEST_TAG)
			return ExtensionManager::path_within_nest(N);
	return NULL;
}

pathname *Extensions::Census::external_path(extension_census *C) {
	inbuild_nest *N = NULL;
	LOOP_OVER_LINKED_LIST(N, inbuild_nest, C->search_list)
		if (Nests::get_tag(N) == EXTERNAL_NEST_TAG)
			return ExtensionManager::path_within_nest(N);
	return NULL;
}

@ In addition to the extensions read in, there are the roads not taken: the
ones which I7 has at its disposal, but which the source text never asks to
include. Inform performs a "census" of installed extensions on every run,
essentially by scanning the directories which hold them to see what the
user has installed there.

Each extension discovered will produce a single "extension census datum",
or ECD.

=
typedef struct extension_census_datum {
	struct inbuild_search_result *found_as;
	int built_in; /* found in the Inform 7 application's private stock */
	int project_specific; /* found in the Materials folder for the current project */
	int overriding_a_built_in_extension; /* not built in, but overriding one which is */
	struct extension_census_datum *next; /* next one in lexicographic order */
	MEMORY_MANAGEMENT
} extension_census_datum;

text_stream *Extensions::Census::ecd_rubric(extension_census_datum *ecd) {
	return Extensions::get_rubric(ExtensionManager::from_copy(ecd->found_as->copy));
}

@ This is a narrative section and describes the story of the census. Just as
Caesar Augustus decreed that all the world should be taxed, and that each
should return to his place of birth, so we will open and inspect every
extension we can find, checking that each is in the right place.

Note that if the same extension is found in more than one domain, the first
to be found is considered the definitive version: this is why the external
area is searched first, so that the user can override built-in extensions
by placing his own versions in the external area. (Should this convention
ever be reversed, a matching change would need to be made in the code which
opens extension files in Read Source Text.)

=
void Extensions::Census::perform(extension_census *C) {
	inbuild_requirement *req = Requirements::anything_of_genre(extension_genre);
	Nests::search_for(req, C->search_list, C->raw_data);
	
	inbuild_search_result *R;
	LOOP_OVER_LINKED_LIST(R, inbuild_search_result, C->raw_data) {
		C->no_census_errors += LinkedLists::len(R->copy->errors_reading_source_text);
		int overridden_by_an_extension_already_found = FALSE;
		@<See if already known from existing data@>;
		if (overridden_by_an_extension_already_found == FALSE)
			@<Add to the census data@>;
	}
}

@h Adding the extension to the census, or not.
Recall that the higher-priority external domain is scanned first; the
built-in domain is scanned second. So if we find that our new extension has
the same title and author as one already known, it must be the case that we
are now scanning the built-in area and that the previous one was an extension
which the user had installed to override this built-in extension.

@<See if already known from existing data@> =
	extension_census_datum *other;
	LOOP_OVER_LINKED_LIST(other, extension_census_datum, C->census_data)
		if ((Works::match(R->copy->edition->work, other->found_as->copy->edition->work)) &&
			((other->built_in) || (Nests::get_tag(R->nest) == INTERNAL_NEST_TAG))) {
			other->overriding_a_built_in_extension = TRUE;
			overridden_by_an_extension_already_found = TRUE;
		}

@ Assuming the new extension was not overridden in this way, we come here.
Because we didn't check the version number text for validity, it might
through being invalid be longer than we expect: in case this is so, we
truncate it.

@<Add to the census data@> =
	extension_census_datum *ecd = CREATE(extension_census_datum);
	ecd->found_as = R;
	Works::add_to_database(R->copy->edition->work, INSTALLED_WDBC);
	ecd->built_in = FALSE;
	if (Nests::get_tag(R->nest) == INTERNAL_NEST_TAG) ecd->built_in = TRUE;
	ecd->project_specific = FALSE;
	if (Nests::get_tag(R->nest) == MATERIALS_NEST_TAG) ecd->project_specific = TRUE;
	ecd->overriding_a_built_in_extension = FALSE;
	ecd->next = NULL;

@ And this is where the inclusion of that material into the catalogue is
taken care of. First, we sometimes position a warning prominently at the
top of the listing, because otherwise its position at the bottom will be
invisible unless the user scrolls a long way:

=
void Extensions::Census::warn_about_census_errors(OUTPUT_STREAM, extension_census *C) {
	if (C->no_census_errors == 0) return; /* no need for a warning */
	if (NUMBER_CREATED(extension_census_datum) < 20) return; /* it's a short page anyway */
	HTML_OPEN("p");
	HTML_TAG_WITH("img", "border=0 src=inform:/doc_images/misinstalled.png");
	WRITE("&nbsp;"
		"<b>Warning</b>. One or more extensions are installed incorrectly: "
		"see details below.");
 	HTML_CLOSE("p");
 }

@ =
void Extensions::Census::transcribe_census_errors(OUTPUT_STREAM, extension_census *C) {
	if (C->no_census_errors == 0) return; /* nothing to include, then */
	@<Include the headnote explaining what census errors are@>;
	inbuild_search_result *R;
	LOOP_OVER_LINKED_LIST(R, inbuild_search_result, C->raw_data)
		if (LinkedLists::len(R->copy->errors_reading_source_text) > 0) {
			copy_error *CE;
			LOOP_OVER_LINKED_LIST(CE, copy_error, R->copy->errors_reading_source_text) {
				#ifdef INDEX_MODULE
				HTMLFiles::open_para(OUT, 2, "hanging");
				#endif
				#ifndef INDEX_MODULE
				HTML_OPEN("p");
				#endif
				WRITE("<b>%X</b> - ", R->copy->edition->work);
				Copies::write_problem(OUT, CE);
				HTML_CLOSE("p");
			}
		}
}

@ We only want to warn people here: not to stop them from using Inform
until they put matters right. (Suppose, for instance, they are using an
account not giving them sufficient privileges to modify files in the external
extensions area: they'd then be locked out if anything was amiss there.)

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

@ Here we write the copy for the directory page of the extensions
documentation: the one which the user currently sees by clicking on the
"Installed Extensions" link from the contents page of the documentation.
It contains an alphabetised catalogue of extensions by author and then
title, along with some useful information about them, and then a list of
any oddities found in the external extensions area.

@d SORT_CE_BY_TITLE 1
@d SORT_CE_BY_AUTHOR 2
@d SORT_CE_BY_INSTALL 3
@d SORT_CE_BY_DATE 4
@d SORT_CE_BY_LENGTH 5

=
void Extensions::Census::write_results(OUTPUT_STREAM, extension_census *C) {
	@<Display the location of installed extensions@>;
	Extensions::Census::warn_about_census_errors(OUT, C);
	HTML::end_html_row(OUT);
	HTML::end_html_table(OUT);
	HTML_TAG("hr");
	@<Time stamp the extensions used on this run@>;

	int key_vms = FALSE, key_override = FALSE, key_builtin = FALSE,
		key_pspec = FALSE, key_bullet = FALSE;

	@<Display the census radio buttons@>;

	int no_entries = NUMBER_CREATED(extension_census_datum);
	extension_census_datum **sorted_census_results = Memory::I7_calloc(no_entries,
		sizeof(extension_census_datum *), EXTENSION_DICTIONARY_MREASON);

	for (int d=1; d<=5; d++) {
		@<Start an HTML division for this sorted version of the census@>;
		@<Sort the census into the appropriate order@>;
		@<Display the sorted version of the census@>;
		HTML_CLOSE("div");
	}
	@<Print the key to any symbols used in the census lines@>;
	Extensions::Census::transcribe_census_errors(OUT, C);
	Memory::I7_array_free(sorted_census_results, EXTENSION_DICTIONARY_MREASON,
		no_entries, sizeof(extension_census_datum *));
}

@<Display the location of installed extensions@> =
	int nps = 0, nbi = 0, ni = 0;
	extension_census_datum *ecd;
	LOOP_OVER(ecd, extension_census_datum) {
		if (ecd->project_specific) nps++;
		else if (ecd->built_in) nbi++;
		else ni++;
	}

	HTML_OPEN("p");
	HTML_TAG_WITH("img", "src='inform:/doc_images/builtin_ext.png' border=0");
	WRITE("&nbsp;You have "
		"%d extensions built-in to this copy of Inform, marked with a grey folder "
		"icon in the catalogue below.",
		nbi);
	HTML_CLOSE("p");
	HTML_OPEN("p");
	if (ni == 0) {
		HTML_TAG_WITH("img", "src='inform:/doc_images/folder4.png' border=0");
		WRITE("&nbsp;You have no other extensions installed at present.");
	} else {
		#ifdef INDEX_MODULE
		HTML::Javascript::open_file(OUT, Extensions::Census::external_path(C), NULL,
			"src='inform:/doc_images/folder4.png' border=0");
		#endif
		WRITE("&nbsp;You have %d further extension%s installed. These are marked "
			"with a blue folder icon in the catalogue below. (Click it to see "
			"where the file is stored on your computer.) "
			"For more extensions, visit <b>www.inform7.com</b>.",
			ni, (ni==1)?"":"s");
	}
	HTML_CLOSE("p");
	if (nps > 0) {
		HTML_OPEN("p");
		#ifdef INDEX_MODULE
		HTML::Javascript::open_file(OUT, Extensions::Census::internal_path(C), NULL, PROJECT_SPECIFIC_SYMBOL);
		#endif
		WRITE("&nbsp;You have %d extension%s in the .materials folder for the "
			"current project. (Click the purple folder icon to show the "
			"location.) %s not available to other projects.",
			nps, (nps==1)?"":"s", (nps==1)?"This is":"These are");
		HTML_CLOSE("p");
	}

@ This simply ensures that dates used are updated to today's date for
extensions used in the current run; otherwise they wouldn't show in the
documentation as used today until the next run, for obscure timing reasons.

@<Time stamp the extensions used on this run@> =
	#ifdef CORE_MODULE
	inform_extension *E;
	LOOP_OVER(E, inform_extension)
		Extensions::Dictionary::time_stamp(E);
	#endif

@ I am the first to admit that this implementation is not inspired. There
are five radio buttons, and number 2 is selected by default.

@<Display the census radio buttons@> =
	HTML_OPEN("p");
	WRITE("Sort catalogue: ");
	HTML_OPEN_WITH("a",
		"href=\"#\" style=\"text-decoration: none\" "
		"onclick=\"openExtra('disp1', 'plus1'); closeExtra('disp2', 'plus2'); "
		"closeExtra('disp3', 'plus3'); closeExtra('disp4', 'plus4'); "
		"closeExtra('disp5', 'plus5'); return false;\"");
	HTML_TAG_WITH("img", "border=0 id=\"plus1\" src=inform:/doc_images/extrarboff.png");
	WRITE("&nbsp;By title");
	HTML_CLOSE("a");
	WRITE(" | ");
	HTML_OPEN_WITH("a",
		"href=\"#\" style=\"text-decoration: none\" "
		"onclick=\"closeExtra('disp1', 'plus1'); openExtra('disp2', 'plus2'); "
		"closeExtra('disp3', 'plus3'); closeExtra('disp4', 'plus4'); "
		"closeExtra('disp5', 'plus5'); return false;\"");
	HTML_TAG_WITH("img", "border=0 id=\"plus2\" src=inform:/doc_images/extrarbon.png");
	WRITE("&nbsp;By author");
	HTML_CLOSE("a");
	WRITE(" | ");
	HTML_OPEN_WITH("a",
		"href=\"#\" style=\"text-decoration: none\" "
		"onclick=\"closeExtra('disp1', 'plus1'); closeExtra('disp2', 'plus2'); "
		"openExtra('disp3', 'plus3'); closeExtra('disp4', 'plus4'); "
		"closeExtra('disp5', 'plus5'); return false;\"");
	HTML_TAG_WITH("img", "border=0 id=\"plus3\" src=inform:/doc_images/extrarboff.png");
	WRITE("&nbsp;By installation");
	HTML_CLOSE("a");
	WRITE(" | ");
	HTML_OPEN_WITH("a",
		"href=\"#\" style=\"text-decoration: none\" "
		"onclick=\"closeExtra('disp1', 'plus1'); closeExtra('disp2', 'plus2'); "
		"closeExtra('disp3', 'plus3'); openExtra('disp4', 'plus4'); "
		"closeExtra('disp5', 'plus5'); return false;\"");
	HTML_TAG_WITH("img", "border=0 id=\"plus4\" src=inform:/doc_images/extrarboff.png");
	WRITE("&nbsp;By date used");
	HTML_CLOSE("a");
	WRITE(" | ");
	HTML_OPEN_WITH("a",
		"href=\"#\" style=\"text-decoration: none\" "
		"onclick=\"closeExtra('disp1', 'plus1'); closeExtra('disp2', 'plus2'); "
		"closeExtra('disp3', 'plus3'); closeExtra('disp4', 'plus4'); "
		"openExtra('disp5', 'plus5'); return false;\"");
	HTML_TAG_WITH("img", "border=0 id=\"plus5\" src=inform:/doc_images/extrarboff.png");
	WRITE("&nbsp;By word count");
	HTML_CLOSE("a");
	HTML_CLOSE("p");

@ Consequently, of the five divisions, number 2 is shown and the others
hidden, by default.

@<Start an HTML division for this sorted version of the census@> =
	char *display = "none";
	if (d == SORT_CE_BY_AUTHOR) display = "block";
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
			Extensions::Census::write_key(OUT);
			#endif
		}
		HTML_CLOSE("p");
	}

@<Sort the census into the appropriate order@> =
	int i = 0;
	extension_census_datum *ecd;
	LOOP_OVER(ecd, extension_census_datum)
		sorted_census_results[i++] = ecd;
	int (*criterion)(const void *, const void *) = NULL;
	switch (d) {
		case SORT_CE_BY_TITLE: criterion = Extensions::Census::compare_ecd_by_title; break;
		case SORT_CE_BY_AUTHOR: criterion = Extensions::Census::compare_ecd_by_author; break;
		case SORT_CE_BY_INSTALL: criterion = Extensions::Census::compare_ecd_by_installation; break;
		case SORT_CE_BY_DATE: criterion = Extensions::Census::compare_ecd_by_date; break;
		case SORT_CE_BY_LENGTH: criterion = Extensions::Census::compare_ecd_by_length; break;
		default: internal_error("no such sorting criterion");
	}
	qsort(sorted_census_results, (size_t) no_entries, sizeof(extension_census_datum *),
		criterion);

@ Standard rows have black text on striped background colours, these being
the usual ones seen in Mac OS X applications such as iTunes.

@d FIRST_STRIPE_COLOUR "#ffffff"
@d SECOND_STRIPE_COLOUR "#f3f6fa"

@<Display the sorted version of the census@> =
	HTML::begin_html_table(OUT, FIRST_STRIPE_COLOUR, TRUE, 0, 0, 2, 0, 0);
	@<Show a titling row explaining the census sorting, if necessary@>;
	int stripe = 0;
	TEMPORARY_TEXT(current_author_name);
	int i, current_installation = -1;
	for (i=0; i<no_entries; i++) {
		extension_census_datum *ecd = sorted_census_results[i];
		@<Insert a subtitling row in the census sorting, if necessary@>;
		stripe = 1 - stripe;
		if (stripe == 0)
			HTML::first_html_column_coloured(OUT, 0, SECOND_STRIPE_COLOUR, 0);
		else
			HTML::first_html_column_coloured(OUT, 0, FIRST_STRIPE_COLOUR, 0);
		@<Print the census line for this extension@>;
		HTML::end_html_row(OUT);
	}
	DISCARD_TEXT(current_author_name);
	@<Show a final titling row closing the census sorting@>;
	HTML::end_html_table(OUT);

@<Show a titling row explaining the census sorting, if necessary@> =
	switch (d) {
		case SORT_CE_BY_TITLE:
			@<Begin a tinted census line@>;
			WRITE("Extensions in alphabetical order");
			@<End a tinted census line@>;
			break;
		case SORT_CE_BY_DATE:
			@<Begin a tinted census line@>;
			WRITE("Extensions in order of date used (most recent first)");
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
	if ((d == SORT_CE_BY_INSTALL) && (Extensions::Census::installation_region(ecd) != current_installation)) {
		current_installation = Extensions::Census::installation_region(ecd);
		@<Begin a tinted census line@>;
		@<Print the installation region in the extension census table@>;
		@<End a tinted census line@>;
		stripe = 0;
	}

@<Show a final titling row closing the census sorting@> =
	@<Begin a tinted census line@>;
	HTML_OPEN_WITH("span", "class=\"smaller\"");
	WRITE("%d extensions installed", no_entries);
	HTML_CLOSE("span");
	@<End a tinted census line@>;

@ Black text on a grey background.

@d CENSUS_TITLING_BG "#808080"

@<Begin a tinted census line@> =
	int span = 4;
	if (d == SORT_CE_BY_TITLE) span = 3;
	HTML::first_html_column_coloured(OUT, 0, CENSUS_TITLING_BG, span);
	HTML::begin_colour(OUT, I"ffffff");
	WRITE("&nbsp;");

@<End a tinted census line@> =
	HTML::end_colour(OUT);
	HTML::end_html_row(OUT);

@ Used only in "by author".

@<Print the author's line in the extension census table@> =
	WRITE("%S", ecd->found_as->copy->edition->work->raw_author_name);

	extension_census_datum *ecd2;
	int cu = 0, cn = 0, j;
	for (j = i; j < no_entries; j++) {
		ecd2 = sorted_census_results[j];
		if (Str::ne(current_author_name, ecd2->found_as->copy->edition->work->author_name)) break;
		if (Extensions::Census::ecd_used(ecd2)) cu++;
		else cn++;
	}
	WRITE("&nbsp;&nbsp;");
	HTML_OPEN_WITH("span", "class=\"smaller\"");
	WRITE("%d extension%s", cu+cn, (cu+cn==1)?"":"s");
	if ((cu == 0) && (cn == 1)) WRITE(", unused");
	else if ((cu == 0) && (cn == 2)) WRITE(", both unused");
	else if ((cu == 0) && (cn > 2)) WRITE(", all unused");
	else if ((cn == 0) && (cu == 1)) WRITE(", used");
	else if ((cn == 0) && (cu == 2)) WRITE(", both used");
	else if ((cn == 0) && (cu > 2)) WRITE(", all used");
	else if (cn+cu > 0) WRITE(", %d used, %d unused", cu, cn);
	WRITE(")");
	HTML_CLOSE("span");

@ Used only in "by installation".

@<Print the installation region in the extension census table@> =
	switch (current_installation) {
		case 0:
			WRITE("Supplied in the .materials folder&nbsp;&nbsp;");
			HTML_OPEN_WITH("span", "class=\"smaller\"");
			WRITE("%p", Extensions::Census::internal_path(C));
			HTML_CLOSE("span"); break;
		case 1: WRITE("Built in to Inform"); break;
		case 2: WRITE("User installed but overriding a built-in extension"); break;
		case 3:
			WRITE("User installed&nbsp;&nbsp;");
			HTML_OPEN_WITH("span", "class=\"smaller\"");
			WRITE("%p", Extensions::Census::external_path(C));
			HTML_CLOSE("span"); break;
	}

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
	if (Extensions::Census::ecd_used(ecd)) { bulletornot = INDEXED_SYMBOL; key_bullet = TRUE; }
	WRITE("&nbsp;");
	HTML_TAG_WITH("img", "%s", bulletornot);

	Works::begin_extension_link(OUT, ecd->found_as->copy->edition->work, Extensions::Census::ecd_rubric(ecd));
	if (d != SORT_CE_BY_AUTHOR) {
		HTML::begin_colour(OUT, I"404040");
		WRITE("%S", ecd->found_as->copy->edition->work->raw_title);
		if (Str::len(ecd->found_as->copy->edition->work->raw_title) + Str::len(ecd->found_as->copy->edition->work->raw_author_name) > 45) {
			HTML_TAG("br");
			WRITE("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;");
		} else
			WRITE(" ");
		WRITE("by %S", ecd->found_as->copy->edition->work->raw_author_name);
		HTML::end_colour(OUT);
	} else {
		HTML::begin_colour(OUT, I"404040");
		WRITE("%S", ecd->found_as->copy->edition->work->raw_title);
		HTML::end_colour(OUT);
	}
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
	Extensions::Census::write_icons(OUT, C);
	#endif

@<Print column 2 of the census line@> =
	HTML_OPEN_WITH("span", "class=\"smaller\"");
	if (VersionNumbers::is_null(ecd->found_as->copy->edition->version) == FALSE)
		WRITE("v&nbsp;%v", &(ecd->found_as->copy->edition->version));
	else
		WRITE("--");
	HTML_CLOSE("span");

@

@d BUILT_IN_SYMBOL "border=\"0\" src=\"inform:/doc_images/builtin_ext.png\""
@d OVERRIDING_SYMBOL "border=\"0\" src=\"inform:/doc_images/override_ext.png\""
@d PROJECT_SPECIFIC_SYMBOL "border=\"0\" src=\"inform:/doc_images/pspec_ext.png\""

@<Print column 3 of the census line@> =
	char *opener = "src='inform:/doc_images/folder4.png' border=0";
	if (ecd->built_in) { opener = BUILT_IN_SYMBOL; key_builtin = TRUE; }
	if (ecd->overriding_a_built_in_extension) {
		opener = OVERRIDING_SYMBOL; key_override = TRUE;
	}
	if (ecd->project_specific) {
		opener = PROJECT_SPECIFIC_SYMBOL; key_pspec = TRUE;
	}
	if (ecd->built_in) HTML_TAG_WITH("img", "%s", opener)
	else {
		#ifdef INDEX_MODULE
		pathname *area = ExtensionManager::path_within_nest(ecd->found_as->nest);
		HTML::Javascript::open_file(OUT, area, ecd->found_as->copy->edition->work->raw_author_name, opener);
		#endif
	}

@<Print column 4 of the census line@> =
	HTML_OPEN_WITH("span", "class=\"smaller\"");
	if ((d == SORT_CE_BY_DATE) || (d == SORT_CE_BY_INSTALL)) {
		WRITE("%S", Works::get_usage_date(ecd->found_as->copy->edition->work));
	} else if (d == SORT_CE_BY_LENGTH) {
		if (Works::forgot(ecd->found_as->copy->edition->work))
			WRITE("I did read this, but forgot");
		else if (Works::never(ecd->found_as->copy->edition->work))
			WRITE("I've never read this");
		else
			WRITE("%d words", Works::get_word_count(ecd->found_as->copy->edition->work));
	} else {
		if (Str::len(Extensions::Census::ecd_rubric(ecd)) > 0)
			WRITE("%S", Extensions::Census::ecd_rubric(ecd));
		else
			WRITE("--");
	}
	HTML_CLOSE("span");

@ Two useful measurements:

=
int Extensions::Census::installation_region(extension_census_datum *ecd) {
	if (ecd->project_specific) return 0;
	if (ecd->built_in) return 1;
	if (ecd->overriding_a_built_in_extension) return 2;
	return 3;
}

int Extensions::Census::ecd_used(extension_census_datum *ecd) {
	if ((Works::no_times_used_in_context(ecd->found_as->copy->edition->work, LOADED_WDBC) > 0) ||
		(Works::no_times_used_in_context(ecd->found_as->copy->edition->work, DICTIONARY_REFERRED_WDBC) > 0))
		return TRUE;
	return FALSE;
}

@ The following give the sorting criteria:

=
int Extensions::Census::compare_ecd_by_title(const void *ecd1, const void *ecd2) {
	extension_census_datum *e1 = *((extension_census_datum **) ecd1);
	extension_census_datum *e2 = *((extension_census_datum **) ecd2);
	return Works::compare_by_title(e1->found_as->copy->edition->work, e2->found_as->copy->edition->work);
}

int Extensions::Census::compare_ecd_by_author(const void *ecd1, const void *ecd2) {
	extension_census_datum *e1 = *((extension_census_datum **) ecd1);
	extension_census_datum *e2 = *((extension_census_datum **) ecd2);
	return Works::compare(e1->found_as->copy->edition->work, e2->found_as->copy->edition->work);
}

int Extensions::Census::compare_ecd_by_installation(const void *ecd1, const void *ecd2) {
	extension_census_datum *e1 = *((extension_census_datum **) ecd1);
	extension_census_datum *e2 = *((extension_census_datum **) ecd2);
	int d = Extensions::Census::installation_region(e1) - Extensions::Census::installation_region(e2);
	if (d != 0) return d;
	return Works::compare_by_title(e1->found_as->copy->edition->work, e2->found_as->copy->edition->work);
}

int Extensions::Census::compare_ecd_by_date(const void *ecd1, const void *ecd2) {
	extension_census_datum *e1 = *((extension_census_datum **) ecd1);
	extension_census_datum *e2 = *((extension_census_datum **) ecd2);
	return Works::compare_by_date(e1->found_as->copy->edition->work, e2->found_as->copy->edition->work);
}

int Extensions::Census::compare_ecd_by_length(const void *ecd1, const void *ecd2) {
	extension_census_datum *e1 = *((extension_census_datum **) ecd1);
	extension_census_datum *e2 = *((extension_census_datum **) ecd2);
	return Works::compare_by_length(e1->found_as->copy->edition->work, e2->found_as->copy->edition->work);
}

@h Icons for virtual machines.
And everything else is cosmetic: printing, or showing icons to signify,
the current VM or some set of permitted VMs. The following plots the
icon associated with a given minor VM, and explicates what the icons mean:

=
void Extensions::Census::plot_icon(OUTPUT_STREAM, target_vm *VM) {
	if (Str::len(VM->VM_image) > 0) {
		HTML_TAG_WITH("img", "border=0 src=inform:/doc_images/%S", VM->VM_image);
		WRITE("&nbsp;");
	}
}

void Extensions::Census::write_key(OUTPUT_STREAM) {
	WRITE("Extensions compatible with specific story file formats only: ");
	int i = 0;
	target_vm *VM;
	LOOP_OVER(VM, target_vm) {
		if (VM->with_debugging_enabled) continue; /* avoids listing twice */
    	if (i++ > 0) WRITE(", ");
    	Extensions::Census::plot_icon(OUT, VM);
		TargetVMs::write(OUT, VM);
	}
}

@h Displaying VM restrictions.
Given a word range, we describe the result as concisely as we can with a
row of icons (but do not bother for the common case where some extension
has no restriction on its use).

=
void Extensions::Census::write_icons(OUTPUT_STREAM, compatibility_specification *C) {
	int something = FALSE, everything = TRUE;
	target_vm *VM;
	LOOP_OVER(VM, target_vm)
		if (Compatibility::with(C, VM))
			something = TRUE;
		else
			everything = FALSE;
	if (something == FALSE) WRITE("none");
	if (everything == FALSE)
		LOOP_OVER(VM, target_vm)
			if (Compatibility::with(C, VM))
				Extensions::Census::plot_icon(OUT, VM);
}

@h Updating the documentation.
This is done in the course of taking an extension census, which is called
for in one of two circumstances: when Inform is being run in "census mode" to
notify it that extensions have been installed or uninstalled; or when Inform
has completed the successful compilation of a source text. In the latter
case, it knows quite a lot about the extensions actually used in that
compilation, and so can write detailed versions of their documentation:
since it is updating extension documentation anyway, it conducts a census
as well. (In both cases the extension dictionary is also worked upon.) The
two alternatives are expressed here:

=
void Extensions::Census::handle_census_mode(void) {
	extension_census *C = Extensions::Census::new();
	Extensions::Dictionary::load();
	Extensions::Census::perform(C);
	Extensions::Census::write_top_level_of_extensions_documentation(C);
	Extensions::Census::write_sketchy_documentation_for_extensions_found(TRUE);
}

void Extensions::Census::update_census(void) {
	Extensions::Dictionary::load();
	extension_census *C = Extensions::Census::new();
	Extensions::Census::perform(C);
	Extensions::Census::write_top_level_of_extensions_documentation(C);
	#ifdef CORE_MODULE
	inform_extension *E;
	LOOP_OVER(E, inform_extension) Extensions::Documentation::write_detailed(E);
	#endif
	Extensions::Census::write_sketchy_documentation_for_extensions_found(FALSE);
	Extensions::Dictionary::write_back();
	if (Log::aspect_switched_on(EXTENSIONS_CENSUS_DA)) Works::log_work_hash_table();
}

@ Documenting extensions seen but not used: we run through the census
results in no particular order and create a sketchy page of documentation,
if there's no better one already.

=
void Extensions::Census::write_sketchy_documentation_for_extensions_found(int census_mode) {
	extension_census_datum *ecd;
	LOOP_OVER(ecd, extension_census_datum)
		Extensions::Documentation::write_sketchy(ecd, census_mode);
}

@h Writing the extensions home pages.
Extensions documentation forms a mini-website within the Inform
documentation. There is a top level consisting of two home pages: a
directory of all installed extensions, and an index to the terms defined in
those extensions. A cross-link switches between them. Each of these links
down to the bottom level, where there is a page for every installed
extension (wherever it is installed). The picture is therefore something
like this:

= (not code)
    (Main documentation contents page)
            |
    Extensions.html--ExtIndex.html
            |      \/      |
            |      /\      |
    Nigel Toad/Eggs  Barnabas Dundritch/Neopolitan Iced Cream   ...

@ These pages are stored at the relative pathnames

	|Extensions/Documentation/Extensions.html|
	|Extensions/Documentation/ExtIndex.html|

They are made by inserting content in place of the material between the
HTML anchors |on| and |off| in a template version of the page built in
to the application, with a leafname which varies from platform to
platform, for reasons as always to do with the vagaries of Internet
Explorer 7 for Windows.

=
void Extensions::Census::write_top_level_of_extensions_documentation(extension_census *C) {
	Extensions::Census::write_top_level_extensions_page(I"Extensions.html", 1, C);
	Extensions::Census::write_top_level_extensions_page(I"ExtIndex.html", 2, NULL);
}

@ =
pathname *Extensions::Census::doc_pathname(void) {
	pathname *P = Inbuild::transient();
	if (P == NULL) return NULL;
	if (Pathnames::create_in_file_system(P) == 0) return NULL;
	P = Pathnames::subfolder(P, I"Documentation");
	if (Pathnames::create_in_file_system(P) == 0) return NULL;
	return P;
}

void Extensions::Census::write_top_level_extensions_page(text_stream *leaf, int content, extension_census *C) {
	pathname *P = Extensions::Census::doc_pathname();
	if (P == NULL) return;
	filename *F = Filenames::in_folder(P, leaf);

	text_stream HOMEPAGE_struct;
	text_stream *OUT = &HOMEPAGE_struct;
	if (STREAM_OPEN_TO_FILE(OUT, F, UTF8_ENC) == FALSE) {
		#ifdef CORE_MODULE
		Problems::Fatal::filename_related(
			"Unable to open extensions documentation index for writing", F);
		#endif
		#ifndef CORE_MODULE
		Errors::fatal_with_file("extensions documentation index for writing: %f", F);
		#endif
	}

	HTML::declare_as_HTML(OUT, FALSE);

	HTML::begin_head(OUT, NULL);
	HTML::title(OUT, I"Extensions");
	HTML::incorporate_javascript(OUT, TRUE,
		Inbuild::file_from_installation(JAVASCRIPT_FOR_EXTENSIONS_IRES));
	HTML::incorporate_CSS(OUT,
		Inbuild::file_from_installation(CSS_FOR_STANDARD_PAGES_IRES));
	HTML::end_head(OUT);

	HTML::begin_body(OUT, NULL);
	HTML::begin_html_table(OUT, NULL, TRUE, 0, 4, 0, 0, 0);
	HTML::first_html_column(OUT, 0);
	HTML_TAG_WITH("img", "src='inform:/doc_images/extensions@2x.png' border=0 width=150 height=150");
	HTML::next_html_column(OUT, 0);

	HTML_OPEN_WITH("div", "class=\"headingboxDark\"");
	HTML_OPEN_WITH("div", "class=\"headingtextWhite\"");
	WRITE("Installed Extensions");
	HTML_CLOSE("div");
	HTML_OPEN_WITH("div", "class=\"headingrubricWhite\"");
	WRITE("Bundles of extra rules or phrases to extend what Inform can do");
	HTML_CLOSE("div");
	HTML_CLOSE("div");

	switch (content) {
		case 1: Extensions::Census::write_results(OUT, C); break;
		case 2: Extensions::Dictionary::write_to_HTML(OUT); break;
	}

	HTML::end_body(OUT);
}
