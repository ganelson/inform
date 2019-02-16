[Basics::] Basics.

Some fundamental definitions.

@h Who we are.
This is a command-line tool built on top of the Foundation module. The first
definition we need to make is:

@d INTOOL_NAME "indoc"

=
void Basics::start(void) {
	Foundation::start();
	@<Declare the debugging log aspects@>;
}

void Basics::end(void) {
	Foundation::end();
}

@ Just two logging aspects to add to the usual Foundation stock:

@e SYMBOLS_DA
@e INSTRUCTIONS_DA

@<Declare the debugging log aspects@> =
	Log::declare_aspect(SYMBOLS_DA, L"symbols", FALSE, FALSE);
	Log::declare_aspect(INSTRUCTIONS_DA, L"instructions", FALSE, FALSE);

@h Setting up the memory manager.
We need to itemise the structures we'll want to allocate:

@e indoc_instructions_MT
@e volume_MT
@e chapter_MT
@e section_MT
@e formatted_file_MT
@e indexing_category_MT
@e index_lemma_MT
@e example_index_data_MT
@e image_source_MT
@e image_usage_MT
@e example_MT
@e CSS_tweak_data_MT
@e span_notation_MT
@e dc_metadatum_MT
@e navigation_design_MT

@ And then expand:

=
ALLOCATE_INDIVIDUALLY(indoc_instructions)
ALLOCATE_INDIVIDUALLY(volume)
ALLOCATE_INDIVIDUALLY(chapter)
ALLOCATE_INDIVIDUALLY(section)
ALLOCATE_INDIVIDUALLY(formatted_file)
ALLOCATE_INDIVIDUALLY(indexing_category)
ALLOCATE_INDIVIDUALLY(index_lemma)
ALLOCATE_INDIVIDUALLY(example_index_data)
ALLOCATE_INDIVIDUALLY(image_source)
ALLOCATE_INDIVIDUALLY(image_usage)
ALLOCATE_INDIVIDUALLY(example)
ALLOCATE_INDIVIDUALLY(CSS_tweak_data)
ALLOCATE_INDIVIDUALLY(span_notation)
ALLOCATE_INDIVIDUALLY(dc_metadatum)
ALLOCATE_INDIVIDUALLY(navigation_design)

@h The Unicode for section.
Since this doesn't lie in the ASCII character range, I'll refer to it by
its Unicode number rather than placing the character in question in the
source code directly.

@d SECTION_SYMBOL 167 /* Unicode for a section symbol */
