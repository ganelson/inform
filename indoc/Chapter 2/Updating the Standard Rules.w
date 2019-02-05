[Updater::] Updating the Standard Rules.

Rewriting the documentation cross-references in the Standard Rules
extension, a feature used only for Inform's in-application documentation.

@h Documentation symbols.
These are non-whitespaced tags, such as |kind_thing|, which are associated
with specific numbered files of HTML documentation.

This hash holds all known references to the Inform documentation provided
to the Standard Rules:

=
void Updater::add_reference_symbol(text_stream *symbol_name, volume *V, section *S) {
	if (S->no_doc_reference_symbols >= MAX_DRS_PER_SECTION)
		Errors::fatal("too many documentation reference symbols in this section");
	S->doc_reference_symbols[S->no_doc_reference_symbols++] = Str::duplicate(symbol_name);
	Indexes::index_notify_of_symbol(symbol_name, V, S);
}

@h The Standard Rules.
The following feature is used only in Inform's master build process, that is,
by me: it updates the Standard Rules source text to reconcile documentation
references. "Documentation references" are tags such as |kind_person| (see the
example rawtext above): the idea is that when the Inform compiler wants to
compile a link to in-application documentation on, say, the kind "person", it
refers to the location internally using a tag, in this case |kind_person|. The
Standard Rules contain a large number of dull sentences such as:

	|Document kind_person at doc45 "3.17" "Men, women and animals".|

which enable Inform to produce accurate links to the current documentation.
This insulates the Inform compiler from its manual, and means the manual
can be heavily rewritten without need to recompile the compiler.

What we do here is to filter an input file (presumably Inform's Standard Rules)
looking for a contiguous block of lines in the form

	|Document ... at doc12.|

We then replace this whole block of lines with a fresh one of our own making,
which contains up to date information on which documentation symbols occur
in which files.

=
void Updater::rewrite_standard_rules_file(void) {
	PRINT("indoc: rewriting documentation references in Standard Rules\n");
	TEMPORARY_TEXT(spool);
	TextFiles::read(standard_rules_filename, FALSE, "can't open Standard Rules file",
		TRUE, Updater::rewrite_helper, NULL, spool);

	text_stream SR;
	text_stream *OUT = &SR;
	if (Streams::open_to_file(OUT, standard_rules_filename, UTF8_ENC) == FALSE)
		Errors::fatal_with_file("can't write Standard Rules file", standard_rules_filename);

	int first_time = 0;
	for (int i=0, L=Str::len(spool); i<L; ) {
		TEMPORARY_TEXT(line);
		while (i<L) {
			int c = Str::get_at(spool, i++);
			if (c == '\n') break;
			PUT_TO(line, c);
		}
		if (Regexp::match(NULL, line, L" *Document %c* at doc%d+%c*")) {
			if (0 == (first_time++))
				@<Write a new set of Document sentences to replace the old set@>;
		} else {
			WRITE("%S\n", line);
		}
		DISCARD_TEXT(line);
	}
	Streams::close(OUT);
	DISCARD_TEXT(spool);
}

@<Write a new set of Document sentences to replace the old set@> =
	section *S;
	LOOP_OVER(S, section)
		if (S->no_doc_reference_symbols > 0) {
			WRITE("Document ");
			for (int i=0; i<S->no_doc_reference_symbols; i++)
				WRITE("%S ", S->doc_reference_symbols[i]);
			WRITE("at doc%d \"%S\" \"%S\".\n",
				S->allocation_id + 1, S->label, S->title);
		}

@ =
void Updater::rewrite_helper(text_stream *line, text_file_position *tfp, void *v_OUT) {
	text_stream *OUT = (text_stream *) v_OUT;
	WRITE("%S\n", line);
}

@h Definitions File.
When writing HTML documentation to be placed inside the application, we
also write a one-off file containing all of the phrase definitions, which
the Inform index-generator can use:

=
void Updater::write_definitions_file(void) {
	text_stream DEFNS;
	text_stream *OUT = &DEFNS;
	if (Streams::open_to_file(OUT, SET_definitions_filename, UTF8_ENC) == FALSE)
		Errors::fatal_with_file("can't write definitions file", SET_definitions_filename);
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
