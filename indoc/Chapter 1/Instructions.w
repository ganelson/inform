[Instructions::] Instructions.

Instructions of indoc to different output types.

@h Definitions.
The command-line and Instructions-file-set values provide a large slate of
what used to be global variables in the Perl version of Indoc. Today they
are herded together into an instance of the |settings_block| structure,
and in particular into a global instance of this called |indoc_settings|.

@d LETTER_ALPHABETIZATION 1
@d WORD_ALPHABETIZATION 2

@d EXMODE_open_internal 1
@d EXMODE_openable_internal 2

@d BOOK_GRANULARITY 1
@d CHAPTER_GRANULARITY 2
@d SECTION_GRANULARITY 3
@d SAME_AS_MAIN_GRANULARITY -1

@d HTML_FORMAT 1
@d PLAIN_FORMAT 2

@d PASTEMODE_none 1
@d PASTEMODE_Andrew 2
@d PASTEMODE_David 3

@d WRAPPER_none 1
@d WRAPPER_epub 2
@d WRAPPER_zip 3

=
typedef struct settings_block {
	int verbose_mode;
	int test_index_mode;

	struct pathname *destination; /* path to the directory where documentation will be made */
	int destination_modifiable; /* can |destination| still be changed by instructions? */
	struct text_stream *manifest_leafname; /* within the |destination| directory */
	struct filename *xrefs_filename;
	struct filename *insertion_filename;

	struct pathname *book_folder;
	filename *book_cover_image; /* e.g., |cover-image.png|; by default, none */
	int index_alphabetisation_algorithm; /* one of the |*_ALPHABETIZATION| values above */
	
	int granularity; /* one of the |*_GRANULARITY| values above */
	
	text_stream *contents_leafname;
	int contents_expandable;
	int toc_granularity; /* one of the |*_GRANULARITY| values above */

	int book_contains_examples;
	int examples_mode; /* one of the |EXMODE_*| values above */
	struct text_stream *examples_alphabetical_leafname;
	struct text_stream *examples_numerical_leafname;
	struct text_stream *examples_thematic_leafname;
	struct pathname *examples_directory;
	int examples_granularity; /* one of the |*_GRANULARITY| values above */

	struct pathname *change_logs_folder;
	struct filename *css_source_file;
	struct filename *definitions_filename;
	struct text_stream *definitions_index_leafname;

	int format; /* one of the |*_FORMAT| values above */
	int XHTML; /* a flag: relevant only if |HTML_FORMAT| is chosen */
	int javascript; /* a flag */

	int html_for_Inform_application;
	int images_copy;
	struct pathname *images_path;
	int inform_definitions_mode;
	int suppress_fonts;
	int assume_Public_Library;

	int retina_images;
	int support_creation;

	struct text_stream *link_to_extensions_index;
	struct filename *top_and_tail;
	struct filename *top_and_tail_sections;
	int treat_code_as_verbatim;
	int wrapper; /* one of the |WRAPPER_*| values above */
	struct ebook *ebook;
	struct navigation_design *navigation;

	CLASS_DEFINITION
} settings_block;

@

=
settings_block *Instructions::clean_slate(void) {
	settings_block *settings = CREATE(settings_block);
	settings->verbose_mode = FALSE;
	settings->test_index_mode = FALSE;

	settings->destination = NULL;
	settings->destination_modifiable = TRUE;
	settings->manifest_leafname = NULL;
	settings->xrefs_filename = NULL;
	settings->insertion_filename = NULL;

	settings->book_folder = Pathnames::from_text(I"Documentation");
	settings->book_cover_image = NULL;
	settings->index_alphabetisation_algorithm = LETTER_ALPHABETIZATION;

	settings->granularity = SECTION_GRANULARITY;

	settings->contents_leafname = NULL;
	settings->contents_expandable = FALSE;
	settings->toc_granularity = SAME_AS_MAIN_GRANULARITY;

	settings->book_contains_examples = FALSE;
	settings->examples_mode = EXMODE_open_internal;
	settings->examples_alphabetical_leafname = NULL;
	settings->examples_numerical_leafname = NULL;
	settings->examples_thematic_leafname = NULL;
	settings->examples_directory = NULL;
	settings->examples_granularity = SAME_AS_MAIN_GRANULARITY;

	settings->change_logs_folder = NULL; /* default not set here, as it depends on book folder */
	settings->css_source_file = NULL;
	settings->definitions_filename = NULL;
	settings->definitions_index_leafname = NULL;

	settings->format = HTML_FORMAT;
	settings->XHTML = FALSE;
	settings->javascript = FALSE;

	settings->html_for_Inform_application = FALSE;
	settings->images_copy = FALSE;
	settings->images_path = NULL;
	settings->inform_definitions_mode = FALSE;
	settings->suppress_fonts = FALSE;
	settings->assume_Public_Library = FALSE;

	settings->retina_images = FALSE;
	settings->support_creation = FALSE;

	settings->link_to_extensions_index = NULL;
	settings->top_and_tail = NULL;
	settings->top_and_tail_sections = NULL;
	settings->treat_code_as_verbatim = FALSE;
	settings->wrapper = WRAPPER_none;
	settings->ebook = NULL;

	settings->navigation = Nav::default();

	return settings;
}

@h Instructions file.
Note that |indoc| reports errors in the instructions file, but doesn't halt on
them until all have been found. (The user may as well get all of the bad news,
not just the beginning of it.)

=
void Instructions::read_instructions(text_stream *target_sought, linked_list *L,
	settings_block *settings) {
	int found_flag = FALSE; /* was a target of this name actually found? */

	settings->change_logs_folder = Pathnames::down(settings->book_folder, I"Change Logs");
	settings->examples_directory = Pathnames::down(settings->book_folder, I"Examples");
	settings->css_source_file = Filenames::in(path_to_indoc_materials, I"base.css");
	settings->definitions_index_leafname = Str::duplicate(I"general_index.html");

	filename *F;
	LOOP_OVER_LINKED_LIST(F, filename, L)
		if (Instructions::read_instructions_from(F, target_sought, settings))
			found_flag = TRUE;

	@<Reconcile any conflicting instructions@>;
	@<Declare the format and wrapper as symbols@>;

	HTMLUtilities::add_image_source(Pathnames::down(path_to_indoc_materials, I"images"));

	if (found_flag == FALSE)
		Errors::fatal_with_text("unknown target %S", target_sought);
}

@ The instructions can be either at the top level, which means they apply to
all targets, or grouped in braced blocks relevant to one target only. For
example,
= (text)
	superbness = 20
	hypercard {
	    superbness = 40
	}
=
applies 20 for all targets except |hypercard|, where it applies 40.

=
typedef struct ins_helper_state {
	int found_aim;
	struct settings_block *settings;
	struct text_stream *desired_target;
	struct text_stream *scanning_target;
} ins_helper_state;

int Instructions::read_instructions_from(filename *F, text_stream *desired,
	settings_block *settings) {
	ins_helper_state ihs;
	ihs.scanning_target = Str::new();
	ihs.desired_target = desired;
	ihs.found_aim = FALSE;
	ihs.settings = settings;
		TextFiles::read(F, FALSE, "can't open instructions file",
		TRUE, Instructions::read_instructions_helper, NULL, &ihs);
	return ihs.found_aim;
}

@ =
void Instructions::read_instructions_helper(text_stream *cl, text_file_position *tfp,
	void *v_ihs) {
	ins_helper_state *ihs = (ins_helper_state *) v_ihs;
	settings_block *settings = ihs->settings;
	match_results mr = Regexp::create_mr();

	if (Regexp::match(&mr, cl, U" *#%c*")) { Regexp::dispose_of(&mr); return; }
	if (Regexp::match(&mr, cl, U" *")) { Regexp::dispose_of(&mr); return; }

	if (Regexp::match(&mr, cl, U"(%C+) { *")) {
		if (Str::len(ihs->scanning_target) > 0)
			Errors::in_text_file("second target opened while first is still open", tfp);
		Str::copy(ihs->scanning_target, mr.exp[0]);
		if (Str::eq(ihs->scanning_target, ihs->desired_target)) ihs->found_aim = TRUE;
	} else if (Regexp::match(&mr, cl, U" *} *")) {
		if (Str::len(ihs->scanning_target) == 0)
			Errors::in_text_file("unexpected target end-marker", tfp);
		Str::clear(ihs->scanning_target);
	} else {
		if ((Str::len(ihs->scanning_target) == 0) ||
			(Str::eq(ihs->scanning_target, ihs->desired_target))) {
			if (settings->verbose_mode)
				PRINT("%f, line %d: %S\n", tfp->text_file_filename, tfp->line_count, cl);
			if (Regexp::match(&mr, cl, U" *follow: *(%c*?) *")) {
				if (Instructions::read_instructions_from(
					Filenames::in(settings->book_folder, mr.exp[0]),
					ihs->desired_target, settings))
					ihs->found_aim = TRUE;
			} else if (Regexp::match(&mr, cl, U" *declare: *(%c*?) *")) {
				Symbols::declare_symbol(mr.exp[0]);
			} else if (Regexp::match(&mr, cl, U" *undeclare: *(%c*?) *")) {
				Symbols::undeclare_symbol(mr.exp[0]);
			} else @<This is an instruction@>;
		}
	}
	Regexp::dispose_of(&mr);
}

@<This is an instruction@> =
	if (Regexp::match(&mr, cl, U" *volume: *(%c*?) *")) {
		@<Disallow this in a specific target@>;
		@<Act on a volume creation@>
	} else if (Regexp::match(&mr, cl, U" *cover: *(%c*?) *")) {
		@<Disallow this in a specific target@>;
		settings->book_cover_image = Instructions::set_file(mr.exp[0], settings);
	} else if (Regexp::match(&mr, cl, U" *examples *")) {
		@<Disallow this in a specific target@>;
		settings->book_contains_examples = TRUE;
	} else if (Regexp::match(&mr, cl, U" *dc:(%C+): *(%c*?) *")) {
		@<Disallow this in a specific target@>;
		Instructions::create_ebook_metadata(Str::duplicate(mr.exp[0]), Str::duplicate(mr.exp[1]));
	} else if (Regexp::match(&mr, cl, U" *css: *(%c*?) *")) {
		@<Act on a CSS tweak@>;
	} else if (Regexp::match(&mr, cl, U" *index: *(%c*?) *")) {
		@<Act on an indexing notation@>;
	} else if (Regexp::match(&mr, cl, U" *images: *(%c*?) *")) {
		HTMLUtilities::add_image_source(Instructions::set_path(mr.exp[0], settings));
	} else if (Regexp::match(&mr, cl, U" *(%C+) *= *(%c*?) *")) {
		@<Act on an instructions setting@>;
	} else {
		Errors::in_text_file("unknown syntax in instructions file", tfp);
	}

@<Disallow this in a specific target@> =
	if (Str::len(ihs->scanning_target) > 0)
		Errors::in_text_file(
			"structural settings like this one must apply to all targets", tfp);

@ Here's where we parse the specifier part of lines like
= (text as Indoc)
	volume: The Inform Recipe Book (RB) = The Recipe Book.txt
=
which reads:
= (text as Indoc)
	The Inform Recipe Book (RB) = The Recipe Book.txt
=

@<Act on a volume creation@> =
	@<Disallow this in a specific target@>;
	text_stream *title = mr.exp[0];
	TEMPORARY_TEXT(file)
	TEMPORARY_TEXT(abbrev)
	match_results mr2 = Regexp::create_mr();
	if (Regexp::match(&mr2, title, U"(%c+?) *= *(%c+?)")) { /* the optional filename syntax */
		Str::copy(title, mr2.exp[0]); Str::copy(file, mr2.exp[1]);
	} else {
		WRITE_TO(file, "%S.txt", title);
	}
	if (Regexp::match(&mr2, title, U"(%c*?) *%((%c*?)%)")) { /* the optional abbreviation syntax */
		Str::copy(title, mr2.exp[0]); Str::copy(abbrev, mr2.exp[1]);
	}
	Scanner::create_volume(settings->book_folder, file, title, abbrev);
	DISCARD_TEXT(file)
	DISCARD_TEXT(abbrev)
	Regexp::dispose_of(&mr2);

@<Act on a CSS tweak@> =
	text_stream *tweak = mr.exp[0];
	match_results mr2 = Regexp::create_mr();
	match_results mr3 = Regexp::create_mr();
	if (Regexp::match(&mr2, tweak, U"(%C+)text(%C+) = (%C+)")) {
		CSS::add_span_notation(mr2.exp[0], mr2.exp[1], mr2.exp[2], MARKUP_SPP);
	} else {
		volume *act_on = NULL;
		if (Regexp::match(&mr2, tweak, U"(%C+) *: *(%c+)")) {
			text_stream *abbrev = mr2.exp[0];
			Str::copy(tweak, mr2.exp[1]);
			volume *V;
			LOOP_OVER(V, volume)
				if (Str::eq(V->vol_abbrev, abbrev))
					act_on = V;
			if (act_on == NULL) Errors::in_text_file("unknown volume abbreviation", tfp);
		}
		if (Regexp::match(&mr2, tweak, U"(%c+?) *{ *")) {
			int plus = 0;
			text_stream *tag = mr2.exp[0];
			TEMPORARY_TEXT(want)
			TEMPORARY_TEXT(ncl)
			while ((TextFiles::read_line(ncl, FALSE, tfp)), (Str::len(ncl) > 0)) {
				Str::trim_white_space(ncl);
				if (Regexp::match(&mr3, ncl, U" *} *")) break;
				WRITE_TO(want, "%S\n", ncl);
			}
			DISCARD_TEXT(ncl)
			if (Regexp::match(&mr3, tag, U"(%c*?) *%+%+ *")) { plus = 2; tag = mr3.exp[0]; }
			else if (Regexp::match(&mr3, tag, U"(%c*?) *%+ *")) { plus = 1; tag = mr3.exp[0]; }
			CSS::request_css_tweak(act_on, tag, want, plus);
			DISCARD_TEXT(want)
		} else Errors::in_text_file("bad CSS tweaking syntax", tfp);
	}
	Regexp::dispose_of(&mr2);
	Regexp::dispose_of(&mr3);

@<Act on an indexing notation@> =
	text_stream *tweak = mr.exp[0];
	match_results mr2 = Regexp::create_mr();
	if (settings->test_index_mode) PRINT("Read in: %S\n", tweak);
	if (Regexp::match(&mr2, tweak, U"^{(%C*)headword(%C*)} = (%C+) *(%c*)")) {
		Indexes::add_indexing_notation(mr2.exp[0], mr2.exp[1], mr2.exp[2], mr2.exp[3]);
	} else if (Regexp::match(&mr2, tweak, U"{(%C+?)} = (%C+) *(%c*)")) {
		Indexes::add_indexing_notation_for_symbols(mr2.exp[0], mr2.exp[1], mr2.exp[2]);
	} else if (Regexp::match(&mr2, tweak, U"definition = (%C+) *(%c*)")) {
		Indexes::add_indexing_notation_for_definitions(mr2.exp[0], mr2.exp[1], NULL);
	} else if (Regexp::match(&mr2, tweak, U"(%C+)-definition = (%C+) *(%c*)")) {
		Indexes::add_indexing_notation_for_definitions(mr2.exp[1], mr2.exp[2], mr2.exp[0]);
	} else if (Regexp::match(&mr2, tweak, U"example = (%C+) *(%c*)")) {
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
		TEMPORARY_TEXT(ncl)
		while ((TextFiles::read_line(ncl, FALSE, tfp)), (Str::len(ncl) > 0)) {
			if (Regexp::match(&mr2, ncl, U" *} *")) break;
			WRITE_TO(val, "%S\n", ncl);
		}
		DISCARD_TEXT(ncl)
		Regexp::dispose_of(&mr2);
	}

@<Set an instructions option@> =
	if (Str::eq_wide_string(key, U"alphabetization")) {
		if (Str::eq_wide_string(val, U"word-by-word"))
			settings->index_alphabetisation_algorithm = WORD_ALPHABETIZATION;
		else if (Str::eq_wide_string(val, U"letter-by-letter"))
			settings->index_alphabetisation_algorithm = LETTER_ALPHABETIZATION;
		else Errors::in_text_file("no such alphabetization", tfp);
	}
	else if (Str::eq_wide_string(key, U"assume_Public_Library"))
		settings->assume_Public_Library = Instructions::set_yn(key, val, tfp);
	else if (Str::eq_wide_string(key, U"change_logs_directory"))
		settings->change_logs_folder = Instructions::set_path(val, settings);
	else if (Str::eq_wide_string(key, U"contents_leafname"))
		settings->contents_leafname = Str::duplicate(val);
	else if (Str::eq_wide_string(key, U"contents_expandable"))
		settings->contents_expandable = Instructions::set_yn(key, val, tfp);
	else if (Str::eq_wide_string(key, U"css_source_file")) { settings->css_source_file = Instructions::set_file(val, settings); }
	else if (Str::eq_wide_string(key, U"definitions_filename")) { settings->definitions_filename = Instructions::set_file(val, settings); }
	else if (Str::eq_wide_string(key, U"definitions_index_filename")) {
		settings->definitions_index_leafname = Str::duplicate(val); }
	else if (Str::eq_wide_string(key, U"destination")) {
		if (settings->destination_modifiable)
			settings->destination = Instructions::set_path(val, settings);
	}
	else if (Str::eq_wide_string(key, U"examples_directory")) {
		settings->examples_directory = Instructions::set_path(val, settings); }
	else if (Str::eq_wide_string(key, U"examples_alphabetical_leafname")) {
		settings->examples_alphabetical_leafname = Str::duplicate(val); }
	else if (Str::eq_wide_string(key, U"examples_granularity")) {
		settings->examples_granularity = Instructions::set_range(key, val, 1, 3, tfp); }
	else if (Str::eq_wide_string(key, U"examples_mode")) {
		if (Str::eq_wide_string(val, U"open")) { settings->examples_mode = EXMODE_open_internal; }
		else if (Str::eq_wide_string(val, U"openable")) { settings->examples_mode = EXMODE_openable_internal; }
		else Errors::in_text_file("no such examples mode", tfp);
	}
	else if (Str::eq_wide_string(key, U"examples_numerical_leafname")) {
		settings->examples_numerical_leafname = Str::duplicate(val); }
	else if (Str::eq_wide_string(key, U"examples_thematic_leafname")) {
		settings->examples_thematic_leafname = Str::duplicate(val); }
	else if (Str::eq_wide_string(key, U"format")) {
		if (Str::eq_wide_string(val, U"HTML")) { settings->format = HTML_FORMAT; }
		else if (Str::eq_wide_string(val, U"text")) { settings->format = PLAIN_FORMAT; }
		else Errors::in_text_file("no such format", tfp);
	}
	else if (Str::eq_wide_string(key, U"granularity")) { settings->granularity = Instructions::set_range(key, val, 1, 3, tfp); }
	else if (Str::eq_wide_string(key, U"html_for_Inform_application")) {
		settings->html_for_Inform_application = Instructions::set_yn(key, val, tfp); }
	else if (Str::eq_wide_string(key, U"images_path")) { settings->images_path = Instructions::set_path(val, settings); }
	else if (Str::eq_wide_string(key, U"images_copy")) { settings->images_copy = Instructions::set_yn(key, val, tfp); }
	else if (Str::eq_wide_string(key, U"inform_definitions_mode")) {
		settings->inform_definitions_mode = Instructions::set_yn(key, val, tfp); }
	else if (Str::eq_wide_string(key, U"javascript")) { settings->javascript = Instructions::set_yn(key, val, tfp); }
	else if (Str::eq_wide_string(key, U"link_to_extensions_index")) {
		settings->link_to_extensions_index = Str::duplicate(val); }
	else if (Str::eq_wide_string(key, U"manifest_leafname")) { settings->manifest_leafname = Str::duplicate(val); }
	else if (Str::eq_wide_string(key, U"navigation")) {
		settings->navigation = Nav::parse(val);
		if (settings->navigation == NULL) Errors::in_text_file("no such navigation mode", tfp);
	}
	else if (Str::eq_wide_string(key, U"retina_images")) {
		settings->retina_images = Instructions::set_yn(key, val, tfp); }
	else if (Str::eq_wide_string(key, U"support_creation")) {
		settings->support_creation = Instructions::set_yn(key, val, tfp); }
	else if (Str::eq_wide_string(key, U"suppress_fonts")) {
		settings->suppress_fonts = Instructions::set_yn(key, val, tfp); }
	else if (Str::eq_wide_string(key, U"toc_granularity")) {
		settings->toc_granularity = Instructions::set_range(key, val, 1, 3, tfp); }
	else if (Str::eq_wide_string(key, U"top_and_tail_sections")) {
		settings->top_and_tail_sections = Instructions::set_file(val, settings); }
	else if (Str::eq_wide_string(key, U"top_and_tail")) { settings->top_and_tail = Instructions::set_file(val, settings); }
	else if (Str::eq_wide_string(key, U"treat_code_as_verbatim")) {
		settings->treat_code_as_verbatim = Instructions::set_yn(key, val, tfp); }
	else if (Str::eq_wide_string(key, U"wrapper")) {
		if (Str::eq_wide_string(val, U"EPUB")) { settings->wrapper = WRAPPER_epub; }
		else if (Str::eq_wide_string(val, U"zip")) { settings->wrapper = WRAPPER_zip; }
		else if (Str::eq_wide_string(val, U"none")) { settings->wrapper = WRAPPER_none; }
		else Errors::in_text_file("no such wrapper", tfp);
	}
	else if (Str::eq_wide_string(key, U"XHTML")) { settings->XHTML = Instructions::set_yn(key, val, tfp); }

	else Errors::in_text_file("no such setting", tfp);

@<Reconcile any conflicting instructions@> =
	if (settings->wrapper == WRAPPER_epub) {
		settings->javascript = FALSE;
		if (settings->examples_mode == EXMODE_openable_internal) {
			settings->examples_mode = EXMODE_open_internal;
		}
		settings->contents_expandable = FALSE;
		settings->images_copy = 1;
		settings->navigation = Nav::for_ebook(settings->navigation);
		settings->format = HTML_FORMAT;
		settings->XHTML = TRUE;
		settings->ebook = Epub::new(I"untitled ebook", "");
	}

	if (settings->examples_granularity == SAME_AS_MAIN_GRANULARITY)
		settings->examples_granularity = settings->granularity;
	if (settings->toc_granularity == SAME_AS_MAIN_GRANULARITY)
		settings->toc_granularity = settings->granularity;

	if (settings->examples_granularity < settings->granularity) {
		settings->examples_granularity = settings->granularity;
		Errors::nowhere("examples granularity can't be less than granularity");
	}
	if (settings->toc_granularity < settings->granularity) {
		settings->toc_granularity = settings->granularity;
		Errors::nowhere("TOC granularity can't be less than granularity");
	}

	if (settings->format == PLAIN_FORMAT)
		settings->navigation = Nav::for_plain_text(settings->navigation);

@<Declare the format and wrapper as symbols@> =
	if (settings->wrapper == WRAPPER_epub) Symbols::declare_symbol(I"EPUB");
	else if (settings->wrapper == WRAPPER_zip) Symbols::declare_symbol(I"zip");
	else Symbols::declare_symbol(I"unwrapped");

	if (settings->format == HTML_FORMAT) Symbols::declare_symbol(I"HTML");
	if (settings->format == PLAIN_FORMAT) Symbols::declare_symbol(I"text");

@h Parsing values.
Note the Unix-style conveniences for pathnames: an initial |~| means the
home folder, |~~| means the book folder.

=
pathname *Instructions::set_path(text_stream *val, settings_block *settings) {
	if (Str::get_at(val, 0) == '~') {
		if (Str::get_at(val, 1) == '~') {
			if ((Str::get_at(val, 2) == '/') || (Platform::is_folder_separator(Str::get_at(val, 2)))) {
				TEMPORARY_TEXT(t)
				Str::copy_tail(t, val, 3);
				pathname *P = Pathnames::from_text_relative(settings->book_folder, t);
				DISCARD_TEXT(t)
				return P;
			} else if (Str::get_at(val, 2) == 0) return settings->book_folder;
		}
		if ((Str::get_at(val, 1) == '/') || (Platform::is_folder_separator(Str::get_at(val, 1)))) {
			TEMPORARY_TEXT(t)
			Str::copy_tail(t, val, 2);
			pathname *P = Pathnames::from_text_relative(home_path, t);
			DISCARD_TEXT(t)
			return P;
		} else if (Str::get_at(val, 1) == 0) return home_path;
	}
	return Pathnames::from_text(val);
}

@ =
filename *Instructions::set_file(text_stream *val, settings_block *settings) {
	if (Str::get_at(val, 0) == '~') {
		if (Str::get_at(val, 1) == '~') {
			if ((Str::get_at(val, 2) == '/') || (Platform::is_folder_separator(Str::get_at(val, 2)))) {
				TEMPORARY_TEXT(t)
				Str::copy_tail(t, val, 3);
				filename *F = Filenames::from_text_relative(settings->book_folder, t);
				DISCARD_TEXT(t)
				return F;
			}
		}
		if ((Str::get_at(val, 1) == '/') || (Platform::is_folder_separator(Str::get_at(val, 1)))) {
			TEMPORARY_TEXT(t)
			Str::copy_tail(t, val, 2);
			filename *F = Filenames::from_text_relative(home_path, t);
			DISCARD_TEXT(t)
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
	if (Regexp::match(&mr, val, U"%d+")) {
		int v = Str::atoi(val, 0);
		Regexp::dispose_of(&mr);
		if ((v >= min) && (v <= max)) return v;
	}
	TEMPORARY_TEXT(ERM)
	WRITE_TO(ERM, "'%S' must a number from %d to %d, not '%S'", key, min, max, val);
	Errors::in_text_file_S(ERM, tfp);
	DISCARD_TEXT(ERM)
	return min;
}

@ A yes-no answer.

=
int Instructions::set_yn(text_stream *key, text_stream *val, text_file_position *tfp) {
	if (Str::eq_wide_string(val, U"yes")) { return 1; }
	if (Str::eq_wide_string(val, U"no")) { return 0; }
	TEMPORARY_TEXT(ERM)
	WRITE_TO(ERM, "'%S' must be 'yes' or 'no', not '%S'", key, val);
	Errors::in_text_file_S(ERM, tfp);
	DISCARD_TEXT(ERM)
	return 0;
}

@ For ebooks only.

=
typedef struct dc_metadatum {
	struct text_stream *dc_key;
	struct text_stream *dc_val;
	CLASS_DEFINITION
} dc_metadatum;

void Instructions::create_ebook_metadata(text_stream *key, text_stream *value) {
	dc_metadatum *dcm = CREATE(dc_metadatum);
	dcm->dc_key = Str::duplicate(key);
	dcm->dc_val = Str::duplicate(value);
}

void Instructions::apply_ebook_metadata(ebook *E) {
	dc_metadatum *dcm;
	LOOP_OVER(dcm, dc_metadatum) {
		inchar32_t K[1024];
		Str::copy_to_wide_string(K, dcm->dc_key, 1024);
		Epub::attach_metadata(E, K, dcm->dc_val);
	}
}
