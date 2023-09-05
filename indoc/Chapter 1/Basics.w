[Basics::] Basics.

Some fundamental definitions.

@h Who we are.
This is a command-line tool built on top of the Foundation module. The first
definition we need to make is:

@d PROGRAM_NAME "indoc"

=
void Basics::start(int argc, char **argv) {
	Foundation::start(argc, argv);
	@<Declare the debugging log aspects@>;
}

void Basics::end(void) {
	Foundation::end();
}

@ Just two logging aspects to add to the usual Foundation stock:

@e SYMBOLS_DA
@e INSTRUCTIONS_DA

@<Declare the debugging log aspects@> =
	Log::declare_aspect(SYMBOLS_DA, U"symbols", FALSE, FALSE);
	Log::declare_aspect(INSTRUCTIONS_DA, U"instructions", FALSE, FALSE);

@h Setting up the memory manager.
We need to itemise the structures we'll want to allocate:

@e settings_block_CLASS
@e volume_CLASS
@e chapter_CLASS
@e section_CLASS
@e formatted_file_CLASS
@e indexing_category_CLASS
@e index_lemma_CLASS
@e example_index_data_CLASS
@e image_source_CLASS
@e image_usage_CLASS
@e example_CLASS
@e CSS_tweak_data_CLASS
@e span_notation_CLASS
@e dc_metadatum_CLASS
@e navigation_design_CLASS

@ And then expand:

=
DECLARE_CLASS(settings_block)
DECLARE_CLASS(volume)
DECLARE_CLASS(chapter)
DECLARE_CLASS(section)
DECLARE_CLASS(formatted_file)
DECLARE_CLASS(indexing_category)
DECLARE_CLASS(index_lemma)
DECLARE_CLASS(example_index_data)
DECLARE_CLASS(image_source)
DECLARE_CLASS(image_usage)
DECLARE_CLASS(example)
DECLARE_CLASS(CSS_tweak_data)
DECLARE_CLASS(span_notation)
DECLARE_CLASS(dc_metadatum)
DECLARE_CLASS(navigation_design)

@h The Unicode for section.
Since this doesn't lie in the ASCII character range, I'll refer to it by
its Unicode number rather than placing the character in question in the
source code directly.

@d SECTION_SYMBOL 167 /* Unicode for a section symbol */
