[Instructions::] Instructions.

Instructions of indoc to different output types.

@h Definitions.

@ A few fundamental options set at the command line. Note the default book
folder which |indoc| reads: "Documentation" in the current working directory.

= (early code)
int verbose_mode = 0;
int test_index_mode = 0;
filename *standard_rules_filename = NULL;
pathname *book_folder = NULL;

@ Most configuration is done not from the command line, but by instructions
files, and we store a list of those here:

@d MAX_INSTRUCTIONS_FILES 100

=
filename *instructions_files[MAX_INSTRUCTIONS_FILES];
int no_instructions_files = 0;

@ First, there are two structural settings:

=
int book_contains_examples = FALSE;
filename *book_cover_image = NULL; /* leafname such as |cover-image.png|; by default, none */

@ Otherwise, following settings are made by the instructions; these are their
default values, which ensure that |indoc| will at least run safely, but in
practice several of these are in any case set by the basic instructions file.
See the manual for their meanings.

@d LETTER_ALPHABETIZATION 1
@d WORD_ALPHABETIZATION 2

=
int SET_alphabetization = LETTER_ALPHABETIZATION;

@ =
pathname *SET_change_logs_directory = NULL; /* default set below, as it depends on book folder */
text_stream *SET_contents_leafname = NULL; /* affects Midnight only */
int SET_contents_expandable = FALSE; /* affects Midnight only */
filename *SET_css_source_file = NULL;
filename *SET_definitions_filename = NULL;
text_stream *SET_definitions_index_leafname = NULL;
int destination_override = FALSE;
pathname *SET_destination = NULL;
pathname *SET_examples_directory = NULL; /* default set below, as it depends on book folder */
int SET_examples_granularity = -1; /* meaning "same as granularity" */

@

@d EXMODE_open_internal 1
@d EXMODE_openable_internal 2

=
int SET_examples_mode = EXMODE_open_internal; /* must be one of the above */

@ =
text_stream *SET_examples_alphabetical_leafname = NULL;
text_stream *SET_examples_numerical_leafname = NULL;
text_stream *SET_examples_thematic_leafname = NULL;

@

@d HTML_FORMAT 1
@d PLAIN_FORMAT 2

=
int SET_format = HTML_FORMAT; /* must be one of those */

@ =
int SET_granularity = 3;
int SET_html_for_Inform_application = FALSE;
int SET_images_copy = FALSE;
pathname *SET_images_path = NULL;
int SET_inform_definitions_mode = FALSE;
int SET_javascript = FALSE;
int SET_suppress_fonts = FALSE;
int SET_assume_Public_Library = FALSE;

int SET_retina_images = FALSE;
int SET_support_creation = FALSE;

@

@d PASTEMODE_none 1
@d PASTEMODE_Andrew 2
@d PASTEMODE_David 3

=
int SET_javascript_paste_method = PASTEMODE_none; /* must be one of those */

@ =
text_stream *SET_link_to_extensions_index = NULL;
text_stream *SET_manifest_leafname = NULL;

@

@d NAVMODE_twilight 1
@d NAVMODE_midnight 2
@d NAVMODE_architect 3
@d NAVMODE_roadsign 4
@d NAVMODE_lacuna 5
@d NAVMODE_unsigned 6

=
int SET_navigation = NAVMODE_midnight; /* must be one of the above */

@ =
int SET_toc_granularity = -1; /* meaning "same as granularity" */
filename *SET_top_and_tail = NULL;
filename *SET_top_and_tail_sections = NULL;
int SET_treat_code_as_verbatim = FALSE;

@

@d WRAPPER_none 1
@d WRAPPER_epub 2
@d WRAPPER_zip 3

=
int SET_wrapper = WRAPPER_none; /* must be one of the above */
ebook *SET_ebook = NULL;

@ =
int SET_XHTML = FALSE;

@ =
typedef struct dc_metadatum {
	struct text_stream *dc_key;
	struct text_stream *dc_val;
	MEMORY_MANAGEMENT
} dc_metadatum;

@h Instructions file.
Note that |indoc| reports errors in the instructions file, but doesn't halt on
them until all have been found. (The user may as well get all of the bad news,
not just the beginning of it.)

=
void Instructions::read_instructions(text_stream *target_sought) {
	int found_flag = FALSE; /* was a target of this name actually found? */

	SET_change_logs_directory = Pathnames::subfolder(book_folder, I"Change Logs");
	SET_examples_directory = Pathnames::subfolder(book_folder, I"Examples");
	pathname *Materials = Pathnames::subfolder(Pathnames::from_text(I"indoc"), I"Materials");
	SET_css_source_file = Filenames::in_folder(Materials, I"base.css");
	SET_definitions_index_leafname = Str::duplicate(I"general_index.html");

	for (int ins_file = 0; ins_file < no_instructions_files; ins_file++)
		if (Instructions::read_instructions_from(instructions_files[ins_file], target_sought))
			found_flag = TRUE;

	@<Reconcile any conflicting instructions@>;
	@<Declare the format and wrapper as symbols@>;

	HTMLUtilities::add_image_source(Pathnames::subfolder(Materials, I"images"));

	if (found_flag == FALSE)
		Errors::fatal_with_text("unknown target %S", target_sought);
}

@ The instructions can be either at the top level, which means they apply to
all targets, or grouped in braced blocks relevant to one target only. For
example,

	|superbness = 20|
	|hypercard {|
	|    superbness = 40|
	|}|

applies 20 for all targets except |hypercard|, where it applies 40.

=
int Instructions::read_instructions_from(filename *F, text_stream *desired) {
	ins_helper_state ihs;
	ihs.scanning_target = Str::new();
	ihs.desired_target = desired;
	ihs.found_aim = FALSE;
	TextFiles::read(F, FALSE, "can't open instructions file",
		TRUE, Instructions::read_instructions_helper, NULL, &ihs);
	return ihs.found_aim;
}

typedef struct ins_helper_state {
	int found_aim;
	struct text_stream *desired_target;
	struct text_stream *scanning_target;
} ins_helper_state;

void Instructions::read_instructions_helper(text_stream *cl, text_file_position *tfp,
	void *v_ihs) {
	ins_helper_state *ihs = (ins_helper_state *) v_ihs;
	match_results mr = Regexp::create_mr();

	if (Regexp::match(&mr, cl, L" *#%c*")) { Regexp::dispose_of(&mr); return; }
	if (Regexp::match(&mr, cl, L" *")) { Regexp::dispose_of(&mr); return; }

	if (Regexp::match(&mr, cl, L"(%C+) { *")) {
		if (Str::len(ihs->scanning_target) > 0)
			Errors::in_text_file("second target opened while first is still open", tfp);
		Str::copy(ihs->scanning_target, mr.exp[0]);
		if (Str::eq(ihs->scanning_target, ihs->desired_target)) ihs->found_aim = TRUE;
	} else if (Regexp::match(&mr, cl, L" *} *")) {
		if (Str::len(ihs->scanning_target) == 0)
			Errors::in_text_file("unexpected target end-marker", tfp);
		Str::clear(ihs->scanning_target);
	} else {
		if ((Str::len(ihs->scanning_target) == 0) ||
			(Str::eq(ihs->scanning_target, ihs->desired_target))) {
			if (verbose_mode == 1)
				PRINT("%f, line %d: %S\n", tfp->text_file_filename, tfp->line_count, cl);
			if (Regexp::match(&mr, cl, L" *follow: *(%c*?) *")) {
				if (Instructions::read_instructions_from(
					Filenames::in_folder(book_folder, mr.exp[0]), ihs->desired_target))
					ihs->found_aim = TRUE;
			} else if (Regexp::match(&mr, cl, L" *declare: *(%c*?) *")) {
				Symbols::declare_symbol(mr.exp[0]);
			} else if (Regexp::match(&mr, cl, L" *undeclare: *(%c*?) *")) {
				Symbols::undeclare_symbol(mr.exp[0]);
			} else @<This is an instruction@>;
		}
	}
	Regexp::dispose_of(&mr);
}

@<This is an instruction@> =
	if (Regexp::match(&mr, cl, L" *volume: *(%c*?) *")) {
		@<Disallow this in a specific target@>;
		@<Act on a volume creation@>
	} else if (Regexp::match(&mr, cl, L" *cover: *(%c*?) *")) {
		@<Disallow this in a specific target@>;
		book_cover_image = Instructions::set_file(mr.exp[0]);
	} else if (Regexp::match(&mr, cl, L" *examples *")) {
		@<Disallow this in a specific target@>;
		book_contains_examples = TRUE;
	} else if (Regexp::match(&mr, cl, L" *dc:(%C+): *(%c*?) *")) {
		@<Disallow this in a specific target@>;
		dc_metadatum *dcm = CREATE(dc_metadatum);
		dcm->dc_key = Str::duplicate(mr.exp[0]);
		dcm->dc_val = Str::duplicate(mr.exp[1]);
	} else if (Regexp::match(&mr, cl, L" *css: *(%c*?) *")) {
		@<Act on a CSS tweak@>;
	} else if (Regexp::match(&mr, cl, L" *index: *(%c*?) *")) {
		@<Act on an indexing notation@>;
	} else if (Regexp::match(&mr, cl, L" *images: *(%c*?) *")) {
		HTMLUtilities::add_image_source(Instructions::set_path(mr.exp[0]));
	} else if (Regexp::match(&mr, cl, L" *(%C+) *= *(%c*?) *")) {
		@<Act on an instructions setting@>;
	} else {
		Errors::in_text_file("unknown syntax in instructions file", tfp);
	}

@<Disallow this in a specific target@> =
	if (Str::len(ihs->scanning_target) > 0)
		Errors::in_text_file(
			"structural settings like this one must apply to all targets", tfp);

@ Here's where we parse the specifier part of lines like

	|volume: The Inform Recipe Book (RB) = The Recipe Book.txt|

which reads:

	|The Inform Recipe Book (RB) = The Recipe Book.txt|

@<Act on a volume creation@> =
	@<Disallow this in a specific target@>;
	text_stream *title = mr.exp[0];
	TEMPORARY_TEXT(file);
	TEMPORARY_TEXT(abbrev);
	match_results mr2 = Regexp::create_mr();
	if (Regexp::match(&mr2, title, L"(%c+?) *= *(%c+?)")) { /* the optional filename syntax */
		Str::copy(title, mr2.exp[0]); Str::copy(file, mr2.exp[1]);
	} else {
		WRITE_TO(file, "%S.txt", title);
	}
	if (Regexp::match(&mr2, title, L"(%c*?) *%((%c*?)%)")) { /* the optional abbreviation syntax */
		Str::copy(title, mr2.exp[0]); Str::copy(abbrev, mr2.exp[1]);
	}
	Scanner::create_volume(file, title, abbrev);
	DISCARD_TEXT(file);
	DISCARD_TEXT(abbrev);
	Regexp::dispose_of(&mr2);

@<Act on a CSS tweak@> =
	text_stream *tweak = mr.exp[0];
	match_results mr2 = Regexp::create_mr();
	match_results mr3 = Regexp::create_mr();
	if (Regexp::match(&mr2, tweak, L"(%C+)text(%C+) = (%C+)")) {
		CSS::add_span_notation(mr2.exp[0], mr2.exp[1], mr2.exp[2], MARKUP_SPP);
	} else {
		volume *act_on = NULL;
		if (Regexp::match(&mr2, tweak, L"(%C+) *: *(%c+)")) {
			text_stream *abbrev = mr2.exp[0];
			Str::copy(tweak, mr2.exp[1]);
			volume *V;
			LOOP_OVER(V, volume)
				if (Str::eq(V->vol_abbrev, abbrev))
					act_on = V;
			if (act_on == NULL) Errors::in_text_file("unknown volume abbreviation", tfp);
		}
		if (Regexp::match(&mr2, tweak, L"(%c+?) *{ *")) {
			int plus = 0;
			text_stream *tag = mr2.exp[0];
			TEMPORARY_TEXT(want);
			TEMPORARY_TEXT(ncl);
			while ((TextFiles::read_line(ncl, FALSE, tfp)), (Str::len(ncl) > 0)) {
				Str::trim_white_space(ncl);
				if (Regexp::match(&mr3, ncl, L" *} *")) break;
				WRITE_TO(want, "%S\n", ncl);
			}
			DISCARD_TEXT(ncl);
			if (Regexp::match(&mr3, tag, L"(%c*?) *%+%+ *")) { plus = 2; tag = mr3.exp[0]; }
			else if (Regexp::match(&mr3, tag, L"(%c*?) *%+ *")) { plus = 1; tag = mr3.exp[0]; }
			CSS::request_css_tweak(act_on, tag, want, plus);
			DISCARD_TEXT(want);
		} else Errors::in_text_file("bad CSS tweaking syntax", tfp);
	}
	Regexp::dispose_of(&mr2);
	Regexp::dispose_of(&mr3);

@<Act on an indexing notation@> =
	text_stream *tweak = mr.exp[0];
	match_results mr2 = Regexp::create_mr();
	if (test_index_mode) PRINT("Read in: %S\n", tweak);
	if (Regexp::match(&mr2, tweak, L"^{(%C*)headword(%C*)} = (%C+) *(%c*)")) {
		Indexes::add_indexing_notation(mr2.exp[0], mr2.exp[1], mr2.exp[2], mr2.exp[3]);
	} else if (Regexp::match(&mr2, tweak, L"{(%C+?)} = (%C+) *(%c*)")) {
		Indexes::add_indexing_notation_for_symbols(mr2.exp[0], mr2.exp[1], mr2.exp[2]);
	} else if (Regexp::match(&mr2, tweak, L"definition = (%C+) *(%c*)")) {
		Indexes::add_indexing_notation_for_definitions(mr2.exp[0], mr2.exp[1], NULL);
	} else if (Regexp::match(&mr2, tweak, L"(%C+)-definition = (%C+) *(%c*)")) {
		Indexes::add_indexing_notation_for_definitions(mr2.exp[1], mr2.exp[2], mr2.exp[0]);
	} else if (Regexp::match(&mr2, tweak, L"example = (%C+) *(%c*)")) {
		Indexes::add_indexing_notation_for_examples(mr2.exp[0], mr2.exp[1]);
	} else {
		Errors::in_text_file("bad indexing notation", tfp);
	}
	Regexp::dispose_of(&mr2);

@<Act on an instructions setting@> =
	text_stream *key = mr.exp[0];
	text_stream *val = mr.exp[1];
	@<Deal with braced write values@>;
	@<Set an instructions option@>;

@ The write value can span multiple lines if the first line consists only
of |{| and the last only of |}| (plus leading or trailing white space to
taste). In a multiple-line value, each line is terminated with a newline.

@<Deal with braced write values@> =
	if (Str::eq(val, I"{")) {
		Str::clear(val);
		match_results mr2 = Regexp::create_mr();
		TEMPORARY_TEXT(ncl);
		while ((TextFiles::read_line(ncl, FALSE, tfp)), (Str::len(ncl) > 0)) {
			if (Regexp::match(&mr2, ncl, L" *} *")) break;
			WRITE_TO(val, "%S\n", ncl);
		}
		DISCARD_TEXT(ncl);
		Regexp::dispose_of(&mr2);
	}

@<Set an instructions option@> =
	if (Str::eq_wide_string(key, L"alphabetization")) {
		if (Str::eq_wide_string(val, L"word-by-word")) { SET_alphabetization = WORD_ALPHABETIZATION; }
		else if (Str::eq_wide_string(val, L"letter-by-letter")) { SET_alphabetization = LETTER_ALPHABETIZATION; }
		else Errors::in_text_file("no such alphabetization", tfp);
	}
	else if (Str::eq_wide_string(key, L"assume_Public_Library")) {
		SET_assume_Public_Library = Instructions::set_yn(key, val, tfp); }
	else if (Str::eq_wide_string(key, L"change_logs_directory")) { SET_change_logs_directory = Instructions::set_path(val); }
	else if (Str::eq_wide_string(key, L"contents_leafname")) { SET_contents_leafname = Str::duplicate(val); }
	else if (Str::eq_wide_string(key, L"contents_expandable")) { SET_contents_expandable = Instructions::set_yn(key, val, tfp); }
	else if (Str::eq_wide_string(key, L"css_source_file")) { SET_css_source_file = Instructions::set_file(val); }
	else if (Str::eq_wide_string(key, L"definitions_filename")) { SET_definitions_filename = Instructions::set_file(val); }
	else if (Str::eq_wide_string(key, L"definitions_index_filename")) {
		SET_definitions_index_leafname = Str::duplicate(val); }
	else if (Str::eq_wide_string(key, L"destination")) {
		if (destination_override == FALSE)
			SET_destination = Instructions::set_path(val);
	}
	else if (Str::eq_wide_string(key, L"examples_directory")) { SET_examples_directory = Instructions::set_path(val); }
	else if (Str::eq_wide_string(key, L"examples_alphabetical_leafname")) {
		SET_examples_alphabetical_leafname = Str::duplicate(val); }
	else if (Str::eq_wide_string(key, L"examples_granularity")) {
		SET_examples_granularity = Instructions::set_range(key, val, 1, 3, tfp); }
	else if (Str::eq_wide_string(key, L"examples_mode")) {
		if (Str::eq_wide_string(val, L"open")) { SET_examples_mode = EXMODE_open_internal; }
		else if (Str::eq_wide_string(val, L"openable")) { SET_examples_mode = EXMODE_openable_internal; }
		else Errors::in_text_file("no such examples mode", tfp);
	}
	else if (Str::eq_wide_string(key, L"examples_numerical_leafname")) {
		SET_examples_numerical_leafname = Str::duplicate(val); }
	else if (Str::eq_wide_string(key, L"examples_thematic_leafname")) {
		SET_examples_thematic_leafname = Str::duplicate(val); }
	else if (Str::eq_wide_string(key, L"format")) {
		if (Str::eq_wide_string(val, L"HTML")) { SET_format = HTML_FORMAT; }
		else if (Str::eq_wide_string(val, L"text")) { SET_format = PLAIN_FORMAT; }
		else Errors::in_text_file("no such format", tfp);
	}
	else if (Str::eq_wide_string(key, L"granularity")) { SET_granularity = Instructions::set_range(key, val, 1, 3, tfp); }
	else if (Str::eq_wide_string(key, L"html_for_Inform_application")) {
		SET_html_for_Inform_application = Instructions::set_yn(key, val, tfp); }
	else if (Str::eq_wide_string(key, L"images_path")) { SET_images_path = Instructions::set_path(val); }
	else if (Str::eq_wide_string(key, L"images_copy")) { SET_images_copy = Instructions::set_yn(key, val, tfp); }
	else if (Str::eq_wide_string(key, L"inform_definitions_mode")) {
		SET_inform_definitions_mode = Instructions::set_yn(key, val, tfp); }
	else if (Str::eq_wide_string(key, L"javascript")) { SET_javascript = Instructions::set_yn(key, val, tfp); }
	else if (Str::eq_wide_string(key, L"javascript_paste_method")) {
		if (Str::eq_wide_string(val, L"none")) { SET_javascript_paste_method = PASTEMODE_none; }
		else if (Str::eq_wide_string(val, L"Andrew")) { SET_javascript_paste_method = PASTEMODE_Andrew; }
		else if (Str::eq_wide_string(val, L"David")) { SET_javascript_paste_method = PASTEMODE_David; }
		else Errors::in_text_file("no such Javascript paste mode", tfp);
	}
	else if (Str::eq_wide_string(key, L"link_to_extensions_index")) {
		SET_link_to_extensions_index = Str::duplicate(val); }
	else if (Str::eq_wide_string(key, L"manifest_leafname")) { SET_manifest_leafname = Str::duplicate(val); }
	else if (Str::eq_wide_string(key, L"navigation")) {
		if (Str::eq_wide_string(val, L"twilight")) { SET_navigation = NAVMODE_twilight; }
		else if (Str::eq_wide_string(val, L"midnight")) { SET_navigation = NAVMODE_midnight; }
		else if (Str::eq_wide_string(val, L"architect")) { SET_navigation = NAVMODE_architect; }
		else if (Str::eq_wide_string(val, L"roadsign")) { SET_navigation = NAVMODE_roadsign; }
		else if (Str::eq_wide_string(val, L"unsigned")) { SET_navigation = NAVMODE_unsigned; }
		else if (Str::eq_wide_string(val, L"lacuna")) { SET_navigation = NAVMODE_lacuna; }
		else Errors::in_text_file("no such navigation mode", tfp);
	}
	else if (Str::eq_wide_string(key, L"retina_images")) {
		SET_retina_images = Instructions::set_yn(key, val, tfp); }
	else if (Str::eq_wide_string(key, L"support_creation")) {
		SET_support_creation = Instructions::set_yn(key, val, tfp); }
	else if (Str::eq_wide_string(key, L"suppress_fonts")) {
		SET_suppress_fonts = Instructions::set_yn(key, val, tfp); }
	else if (Str::eq_wide_string(key, L"toc_granularity")) {
		SET_toc_granularity = Instructions::set_range(key, val, 1, 3, tfp); }
	else if (Str::eq_wide_string(key, L"top_and_tail_sections")) {
		SET_top_and_tail_sections = Instructions::set_file(val); }
	else if (Str::eq_wide_string(key, L"top_and_tail")) { SET_top_and_tail = Instructions::set_file(val); }
	else if (Str::eq_wide_string(key, L"treat_code_as_verbatim")) {
		SET_treat_code_as_verbatim = Instructions::set_yn(key, val, tfp); }
	else if (Str::eq_wide_string(key, L"wrapper")) {
		if (Str::eq_wide_string(val, L"EPUB")) { SET_wrapper = WRAPPER_epub; }
		else if (Str::eq_wide_string(val, L"zip")) { SET_wrapper = WRAPPER_zip; }
		else if (Str::eq_wide_string(val, L"none")) { SET_wrapper = WRAPPER_none; }
		else Errors::in_text_file("no such wrapper", tfp);
	}
	else if (Str::eq_wide_string(key, L"XHTML")) { SET_XHTML = Instructions::set_yn(key, val, tfp); }

	else Errors::in_text_file("no such setting", tfp);

@<Reconcile any conflicting instructions@> =
	if (SET_wrapper == WRAPPER_epub) {
		SET_javascript = 0;
		SET_javascript_paste_method = PASTEMODE_none;
		if (SET_examples_mode == EXMODE_openable_internal) {
			SET_examples_mode = EXMODE_open_internal;
		}
		SET_contents_expandable = 0;
		SET_images_copy = 1;
		if ((SET_navigation != NAVMODE_roadsign) &&
			(SET_navigation != NAVMODE_unsigned)) {
			SET_navigation = NAVMODE_roadsign;
		}
		SET_format = HTML_FORMAT;
		SET_XHTML = TRUE;
		SET_ebook = Epub::new(I"untitled ebook", "");
	}

	if (SET_javascript_paste_method != PASTEMODE_none) { SET_javascript = 1; }

	if (SET_examples_granularity == -1) {
		SET_examples_granularity = SET_granularity; }
	if (SET_toc_granularity == -1) {
		SET_toc_granularity = SET_granularity; }

	if (SET_examples_granularity < SET_granularity) {
		SET_examples_granularity = SET_granularity;
		Errors::nowhere("examples granularity can't be less than granularity");
	}
	if (SET_toc_granularity < SET_granularity) {
		SET_toc_granularity = SET_granularity;
		Errors::nowhere("TOC granularity can't be less than granularity");
	}

	if (SET_format == PLAIN_FORMAT) SET_navigation = NAVMODE_lacuna;

@<Declare the format and wrapper as symbols@> =
	if (SET_wrapper == WRAPPER_epub) Symbols::declare_symbol(I"EPUB");
	else if (SET_wrapper == WRAPPER_zip) Symbols::declare_symbol(I"zip");
	else Symbols::declare_symbol(I"unwrapped");

	if (SET_format == HTML_FORMAT) Symbols::declare_symbol(I"HTML");
	if (SET_format == PLAIN_FORMAT) Symbols::declare_symbol(I"text");

@h Parsing values.
Note the Unix-style conveniences for pathnames: an initial |~| means the
home folder, |~~| means the book folder.

=
pathname *Instructions::set_path(text_stream *val) {
	if (Str::get_at(val, 0) == '~') {
		if (Str::get_at(val, 1) == '~') {
			if ((Str::get_at(val, 2) == '/') || (Str::get_at(val, 2) == FOLDER_SEPARATOR)) {
				TEMPORARY_TEXT(t);
				Str::copy_tail(t, val, 3);
				pathname *P = Pathnames::from_text_relative(book_folder, t);
				DISCARD_TEXT(t);
				return P;
			} else if (Str::get_at(val, 2) == 0) return book_folder;
		}
		if ((Str::get_at(val, 1) == '/') || (Str::get_at(val, 1) == FOLDER_SEPARATOR)) {
			TEMPORARY_TEXT(t);
			Str::copy_tail(t, val, 2);
			pathname *P = Pathnames::from_text_relative(home_path, t);
			DISCARD_TEXT(t);
			return P;
		} else if (Str::get_at(val, 1) == 0) return home_path;
	}
	return Pathnames::from_text(val);
}

filename *Instructions::set_file(text_stream *val) {
	if (Str::get_at(val, 0) == '~') {
		if (Str::get_at(val, 1) == '~') {
			if ((Str::get_at(val, 2) == '/') || (Str::get_at(val, 2) == FOLDER_SEPARATOR)) {
				TEMPORARY_TEXT(t);
				Str::copy_tail(t, val, 3);
				filename *F = Filenames::from_text_relative(book_folder, t);
				DISCARD_TEXT(t);
				return F;
			}
		}
		if ((Str::get_at(val, 1) == '/') || (Str::get_at(val, 1) == FOLDER_SEPARATOR)) {
			TEMPORARY_TEXT(t);
			Str::copy_tail(t, val, 2);
			filename *F = Filenames::from_text_relative(home_path, t);
			DISCARD_TEXT(t);
			return F;
		}
	}
	return Filenames::from_text(val);
}

@ An integer value within or at the edges of the given range.

=
int Instructions::set_range(text_stream *key, text_stream *val,
	int min, int max, text_file_position *tfp) {
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, val, L"%d+")) {
		int v = Str::atoi(val, 0);
		Regexp::dispose_of(&mr);
		if ((v >= min) && (v <= max)) return v;
	}
	TEMPORARY_TEXT(ERM);
	WRITE_TO(ERM, "'%S' must a number from %d to %d, not '%S'", key, min, max, val);
	Errors::in_text_file_S(ERM, tfp);
	DISCARD_TEXT(ERM);
	return min;
}

@ A yes-no answer.

=
int Instructions::set_yn(text_stream *key, text_stream *val, text_file_position *tfp) {
	if (Str::eq_wide_string(val, L"yes")) { return 1; }
	if (Str::eq_wide_string(val, L"no")) { return 0; }
	TEMPORARY_TEXT(ERM);
	WRITE_TO(ERM, "'%S' must be 'yes' or 'no', not '%S'", key, val);
	Errors::in_text_file_S(ERM, tfp);
	DISCARD_TEXT(ERM);
	return 0;
}

@ For ebooks only.

=
void Instructions::apply_ebook_metadata(void) {
	dc_metadatum *dcm;
	LOOP_OVER(dcm, dc_metadatum) {
		wchar_t K[1024];
		Str::copy_to_wide_string(K, dcm->dc_key, 1024);
		Epub::attach_metadata(SET_ebook, K, dcm->dc_val);
	}
}
