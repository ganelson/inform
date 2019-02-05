[Main::] Main.

The top level of the program.

@h Definitions.

@ Indoc is one of the earliest Inform tools, and it spent much of its
life as a hacky Perl script: like all too many quick-fix Perl scripts, it
was still in use ten years later. In 2012, I spent some time tidying it up
to generate better HTML, and moved it over to literate code. This took an
exasperatingly long time, not least because the original had produced
typically sloppy turn-of-the-century HTML, with tables for layout and
no CSS, and with many now-deprecated tags and elements. The 2012 edition,
by contrast, needed to produce validatable XHTML 1.1 Strict in order to
make EPUBs which read roughly correctly in today's ebook-readers, and
when they call this Strict they're not kidding. It took something like
four weeks of spare evenings.

Just as I was finishing up, the programmer and commentator John Siracusa
described an almost identical web-content-and-ebook generation task on his
podcast (Hypercritical 85): "My solution for this is... I was trying to
think of a good analogy for what happens when you're a programmer and you
have this sort of task in front of you. Is it, the cobbler's children have
no shoes? ... You would expect someone who is a programmer to make some
awesome system which would generate these three things. But when you're a
programmer, you have the ability to do whatever you want really, really
quickly in the crappiest possible way... And that's what I did. I wrote a
series of incredibly disgusting Perl scripts."

This made me feel better. Nevertheless, in 2016, I rewrote in C.

@h Nutshell.
We turn the source matter, "rawtext", into a batch of output files using the
chosen format, a process we'll call "rendering". We do this in two passes.

=
int main(int argc, char **argv) {
	Foundation::start();
	Log::declare_aspect(SYMBOLS_DA, L"symbols", FALSE, FALSE);
	Log::declare_aspect(INSTRUCTIONS_DA, L"instructions", FALSE, FALSE);

	@<Start up indoc@>;
	@<Make a first-pass scan of the rawtext@>;
	@<Render the rawtext as documentation@>;
	if (SET_html_for_Inform_application == 1)
		@<Work out cross-references for the in-application documentation only@>;
	@<Produce the indexes@>;
	HTMLUtilities::copy_images();
	if (SET_wrapper == WRAPPER_epub) {
		HTMLUtilities::note_images();
		Scanner::mark_up_ebook();
		Epub::end_construction(SET_ebook);
	}
	@<Shut down indoc@>;
	return 0;
}

@h Starting up.

@<Start up indoc@> =
	PRINT("indoc [[Build Number]] (Inform Tools Suite)\n");
	Symbols::start_up_symbols();
	Configuration::read_command_line(argc, argv);
	if (SET_wrapper == WRAPPER_epub) {
		HTMLUtilities::image_URL(NULL, Filenames::get_leafname(book_cover_image));
		Instructions::apply_ebook_metadata();
		pathname *I = Pathnames::from_text(I"images");
		filename *cover_in_situ = Filenames::in_folder(I, Filenames::get_leafname(book_cover_image));
		SET_destination = Epub::begin_construction(SET_ebook,
			SET_destination, cover_in_situ);
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
	if (book_contains_examples == 1) Examples::scan_examples();

@ We then work through each volume's rawtext file in turn, writing the output
section by section.

@<Render the rawtext as documentation@> =
	if (SET_format == HTML_FORMAT) CSS::write_CSS_files(SET_css_source_file);
	volume *V;
	text_stream *TO = NULL;
	LOOP_OVER(V, volume) TO = Rawtext::process_large_rawtext_file(TO, V);
	Gadgets::render_navigation_contents_files();

@ The following functions here are for use only when compiling documentation
to go inside the Inform user interface application.

@<Work out cross-references for the in-application documentation only@> =
	Scanner::write_manifest_file(FIRST_OBJECT(volume));
	if (SET_definitions_filename) Updater::write_definitions_file();
	if (standard_rules_filename) Updater::rewrite_standard_rules_file();

@ These are automatically generated.

@<Produce the indexes@> =
	if (SET_format == HTML_FORMAT) {
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
