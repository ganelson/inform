[Main::] Main.

The top level of the program.

@h Nutshell.
We turn the source matter, "rawtext", into a batch of output files using the
chosen format, a process we'll call "rendering". We do this in two passes.

=
pathname *path_to_indoc = NULL; /* where we are installed */
pathname *path_to_indoc_materials = NULL; /* the materials pathname */

settings_block *indoc_settings = NULL;
int no_volumes = 0;
int no_examples = 0;

int main(int argc, char **argv) {
	Basics::start(argc, argv);
	@<Start up indoc@>;
	@<Make a first-pass scan of the rawtext@>;
	@<Render the rawtext as documentation@>;
	if (indoc_settings->html_for_Inform_application)
		@<Work out cross-references for the in-application documentation only@>;
	@<Produce the indexes@>;
	HTMLUtilities::copy_images();
	if (indoc_settings->wrapper == WRAPPER_epub) {
		HTMLUtilities::note_images();
		Scanner::mark_up_ebook();
		Epub::end_construction(indoc_settings->ebook);
	}
	@<Shut down indoc@>;
	Basics::end();
	return 0;
}

@h Starting up.

@<Start up indoc@> =
	PRINT("indoc [[Version Number]] (Inform Tools Suite)\n");
	Nav::start();
	Symbols::start_up_symbols();
	indoc_settings = Instructions::clean_slate();
	Configuration::read_command_line(argc, argv, indoc_settings);
	if (indoc_settings->wrapper == WRAPPER_epub) {
		HTMLUtilities::image_URL(NULL,
			Filenames::get_leafname(indoc_settings->book_cover_image));
		Instructions::apply_ebook_metadata(indoc_settings->ebook);
		pathname *I = Pathnames::from_text(I"images");
		filename *cover_in_situ = Filenames::in(I,
			Filenames::get_leafname(indoc_settings->book_cover_image));
		indoc_settings->destination = Epub::begin_construction(indoc_settings->ebook,
			indoc_settings->destination, cover_in_situ);
	}

	if (NUMBER_CREATED(volume) == 0) { PRINT("indoc: nothing to do\n"); exit(0); }
	if (problem_count > 0) exit(1);

@h First and second passes.
First we look ahead, so to speak, by scanning the examples we are going
to need to insert; then similarly to find the section titles. At this
point, nothing is being output.

@<Make a first-pass scan of the rawtext@> =
	volume *V;
	LOOP_OVER(V, volume) Scanner::scan_rawtext_for_section_titles(V);
	if (indoc_settings->book_contains_examples) Examples::scan_examples();

@ We then work through each volume's rawtext file in turn, writing the output
section by section.

@<Render the rawtext as documentation@> =
	if (indoc_settings->format == HTML_FORMAT) CSS::write_CSS_files(indoc_settings->css_source_file);
	volume *V;
	text_stream *TO = NULL;
	LOOP_OVER(V, volume) TO = Rawtext::process_large_rawtext_file(TO, V);
	Nav::render_navigation_contents_files();

@ The following functions here are for use only when compiling documentation
to go inside the Inform user interface application.

@<Work out cross-references for the in-application documentation only@> =
	Scanner::write_manifest_file(FIRST_OBJECT(volume));
	if (indoc_settings->definitions_filename) Updater::write_definitions_file();
	if (indoc_settings->xrefs_filename)
		Updater::write_xrefs_file(indoc_settings->xrefs_filename);

@ These are automatically generated.

@<Produce the indexes@> =
	if (indoc_settings->format == HTML_FORMAT) {
		if (no_examples > 0) {
			ExamplesIndex::write_alphabetical_examples_index();
			ExamplesIndex::write_numerical_examples_index();
			ExamplesIndex::write_thematic_examples_index();
		}
		if (NUMBER_CREATED(index_lemma) > 0) Indexes::write_general_index();
	}

@h Shutting down.

@<Shut down indoc@> =
	if (problem_count > 0) {
		PRINT("indoc: ended with error%s\n", (problem_count == 1)?"":"s");
		exit(1);
	}
	int s = 0;
	volume *V; LOOP_OVER(V, volume) s += V->vol_section_count;
	PRINT("indoc: done (%d volume%s, %d section%s, %d example%s)\n",
		no_volumes, (problem_count == 1)?"":"s",
		s, (s == 1)?"":"s",
		no_examples, (no_examples == 1)?"":"s");
