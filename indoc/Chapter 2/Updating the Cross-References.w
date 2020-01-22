[Updater::] Updating the Cross-References.

Writing the documentation cross-references to a file used by Inform's
in-application documentation.

@h Documentation symbols.
These are non-whitespaced tags, such as |kind_thing|, which are associated
with specific numbered files of HTML documentation.

This hash holds all known references to the Inform documentation:

=
void Updater::add_reference_symbol(text_stream *symbol_name, volume *V, section *S) {
	if (S->no_doc_reference_symbols >= MAX_DRS_PER_SECTION)
		Errors::fatal("too many documentation reference symbols in this section");
	S->doc_reference_symbols[S->no_doc_reference_symbols++] = Str::duplicate(symbol_name);
	Indexes::index_notify_of_symbol(symbol_name, V, S);
}

@h Cross-references file.
Until January 2020, Inform managed cross-references to its dcumentation in a
clumsy way, with explicit sentences such as:

	|Document kind_person at doc45 "3.17" "Men, women and animals".|

in the Standard Rules extension, which correlated "tags" such as |kind_person|
with named passages in the documentation; in this way, the compiler learned
how to annotate its problem messages and Index with links.

That meant that Indoc had to update the Standard Rules each time it ran, which
was far from elegant. This has now gone, and instead we write a stand-alone
"cross-references file" which Inform reads separately from any extensions.

=
void Updater::write_xrefs_file(filename *F) {
	text_stream SR;
	text_stream *OUT = &SR;
	if (Streams::open_to_file(OUT, F, UTF8_ENC) == FALSE)
		Errors::fatal_with_file("can't write cross-references file", F);

	section *S;
	LOOP_OVER(S, section)
		if (S->no_doc_reference_symbols > 0) {
			for (int i=0; i<S->no_doc_reference_symbols; i++)
				WRITE("%S ", S->doc_reference_symbols[i]);
			WRITE("_ doc%d \"%S\" \"%S\"\n",
				S->allocation_id + 1, S->label, S->title);
		}

	Streams::close(OUT);
}

@h Definitions File.
When writing HTML documentation to be placed inside the application, we
also write a one-off file containing all of the phrase definitions, which
the Inform index-generator can use:

=
void Updater::write_definitions_file(void) {
	text_stream DEFNS;
	text_stream *OUT = &DEFNS;
	if (Streams::open_to_file(OUT, indoc_settings->definitions_filename, UTF8_ENC) == FALSE)
		Errors::fatal_with_file("can't write definitions file", indoc_settings->definitions_filename);
	formatted_file *ftd;
	LOOP_OVER(ftd, formatted_file) {
		definitions_helper_state dhs;
		dhs.transcribe = FALSE;
		dhs.OUT = OUT;
		TextFiles::read(ftd->name, FALSE, "can't reopen written file",
			TRUE, Updater::definitions_helper, NULL, &dhs);
	}

	Streams::close(OUT);
}

typedef struct definitions_helper_state {
	int transcribe;
	struct text_stream *OUT;
} definitions_helper_state;

void Updater::definitions_helper(text_stream *line, text_file_position *tfp, void *v_dhs) {
	definitions_helper_state *dhs = (definitions_helper_state *) v_dhs;
	Str::trim_white_space_at_end(line);
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, line, L" *<!--definition of (%c*?)--%c*")) {
		WRITE_TO(dhs->OUT, "*=%S=*\n", mr.exp[0]);
		dhs->transcribe = TRUE;
	} else if (Regexp::match(&mr, line, L" *<!--end definition--%c*")) {
		dhs->transcribe = FALSE;
	} else if (dhs->transcribe) WRITE_TO(dhs->OUT, "%S\n", line);
	Regexp::dispose_of(&mr);
}
