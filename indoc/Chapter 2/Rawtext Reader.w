[Rawtext::] Rawtext Reader.

Reading the rawtext in, breaking it up into blocks, and sending
them for output as formatted documentation.

@h The rawtext files.
This reads an entire rawtext volume.

=
text_stream *Rawtext::process_large_rawtext_file(OUTPUT_STREAM, volume *V) {
 	rawtext_helper_state rhs;
 	rhs.V = V;
 	rhs.OUT = OUT;
 	OUT = Rawtext::turn_rawtext_into_blocks(OUT, V, FALSE, V->vol_rawtext_filename, NULL);
 	OUT = Renderer::close_formatted_file(OUT);
 	return OUT;
}

@ The other source of rawtext is an Example file. These, however, start with
a three-line header containing metadata -- we need to skip this before
running the rawtext scanner. Examples are rendered as partial files, not as
multi-section rawtext volumes.

=
text_stream *Rawtext::process_example_rawtext_file(OUTPUT_STREAM,
 	volume *V, example *E) {
 	OUT = Rawtext::turn_rawtext_into_blocks(OUT, V, TRUE, E->ex_filename, E);
 	return OUT;
 }

@h The scanner.
And here is the common scanner used for both.

"Rawtext" is the very lightly marked-up form of plain text in which the Inform
manuals are written. Perhaps I should have used Markdown or REST, but those
formats were less well-known in the early 2000s, so rawtext is its own unique
flower.

A rawtext file is divided up into one or more blocks. The first of these
can optionally be introduced by a block heading line; any subsequent ones
must be. (A block ends when a new heading line appears, or at end of file.)

=
text_stream *Rawtext::turn_rawtext_into_blocks(OUTPUT_STREAM,
	volume *V, int render_as_partial_file_only, filename *name, example *E) {
	rawtext_helper_state rhs_structure;
	rawtext_helper_state *rhs = &rhs_structure;
	rhs->OUT = OUT;
	rhs->E = E;
	rhs->V = V;
	rhs->skipping_current_block = FALSE;
 	rhs->no_blocks_written = 0;
 	rhs->this_is_first_block_in_file = TRUE;
 	rhs->partial_only = render_as_partial_file_only;

 	rhs->no_chapters_read_in_current_rawtext = 0;
 	rhs->no_blocks_read_in_current_chapter = 0;
 	rhs->no_pars_read_in_current_block = 0;
 	rhs->title_of_block_being_read = Str::new(); /* Untitled until a block heading found */
	if (E) rhs->skip_opening_lines = 3;
	else rhs->skip_opening_lines = 0;

 	@<Prepare to read a new chapter of rawtext@>;
 	@<Prepare to read a new block of rawtext@>;

 	@<Scan the file and render blocks as they complete@>;

 	@<Render the block just completed, unless it's empty@>;
 	Str::dispose_of(rhs->title_of_block_being_read);
 	return OUT;
}

typedef struct rawtext_helper_state {
	struct text_stream *OUT;
	struct volume *V;
	struct example *E;
	int skipping_current_block;
	int skip_opening_lines;
	int no_blocks_written;
	int this_is_first_block_in_file;
	int no_chapters_read_in_current_rawtext;
	int no_blocks_read_in_current_chapter;
	int no_pars_read_in_current_block;
	int partial_only;
	struct text_stream *title_of_block_being_read;
} rawtext_helper_state;

@<Prepare to read a new chapter of rawtext@> =
 	rhs->no_blocks_read_in_current_chapter = 0;

@<Prepare to read a new block of rawtext@> =
 	rhs->no_blocks_read_in_current_chapter++;
 	rhs->no_pars_read_in_current_block = 0;
 	Renderer::clear_block_buffer();

@<Render the block just completed, unless it's empty@> =
 	if (rhs->no_pars_read_in_current_block > 0) {
		if ((rhs->E) && (no_paras_in_block_buffer > 0)) {
			if ((Str::len(paragraphs[no_paras_in_block_buffer-1].par_texts) == 0) &&
				(paragraphs[no_paras_in_block_buffer-1].par_shortened == FALSE)) {
				no_paras_in_block_buffer--;
			}
		}
 		if (rhs->partial_only) {
 			OUT = Renderer::render_text_of_block(OUT, rhs->V, NULL);
 		} else {
 			index_to_examples = TRUE;
 			OUT = Renderer::render_block(OUT, rhs->V,
 				(rhs->V)?(rhs->V->sections[rhs->no_blocks_written]):NULL);
 		}
 		rhs->OUT = OUT;
 		rhs->this_is_first_block_in_file = FALSE;
 		rhs->no_blocks_written++;
 	}

@<Scan the file and render blocks as they complete@> =
	TextFiles::read(name, FALSE, "can't open rawtext file",
		TRUE, Rawtext::process_large_helper, NULL, rhs);
	OUT = rhs->OUT;

@ =
void Rawtext::process_large_helper(text_stream *rawl, text_file_position *tfp,
	void *v_rhs) {
	rawtext_helper_state *rhs = (rawtext_helper_state *) v_rhs;
 	if (rhs->skip_opening_lines >= 0) {
 		rhs->skip_opening_lines--; return;
 	}
 	int shortened = Str::trim_white_space_at_end(rawl);
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, rawl, L"%[(%c*?)%] (%c*)"))
		@<Deal with a block heading@>
	else if (rhs->skipping_current_block == FALSE) {
		int suppress_p_tag = FALSE;
		TEMPORARY_TEXT(HTML_prefix);
		TEMPORARY_TEXT(css_style);
		match_results mr2 = Regexp::create_mr();
		@<Deal with any permitted markup@>;
		if ((indoc_settings->treat_code_as_verbatim == FALSE) || (Str::get_first_char(rawl) != '\t')) {
			@<Deal with an insert-change-log notation@>;
			@<Deal with an insert-image notation@>;
		}
		int abandon_para = FALSE;
		@<Deal with paragraph tags@>;
		if (abandon_para == FALSE) @<Deal with a regular paragraph@>;
		DISCARD_TEXT(HTML_prefix);
		DISCARD_TEXT(css_style);
		Regexp::dispose_of(&mr2);
	}
	Regexp::dispose_of(&mr);
}

@ Block headings are paragraphs beginning with square-bracketed material:
= (text as Indoc)
	[x] The footwear kind
=
This one is a typical section heading. The |[x]| marks it as being a mere
level-B heading in the book; "The footwear kind" is the text of the title;
the braced |{kind_footwear}| is another documentation reference.

The |x| text is a meaningless placeholder. The way to get this noticed
is to write something like:
= (text as Indoc)
	[Chapter: Bananas] Introduction to soft yellow fruit
=
which creates a new chapter called "Bananas", within which this block will
be the first section.

@<Deal with a block heading@> =
 	text_stream *block_header = mr.exp[0]; /* The text in the square brackets */
 	text_stream *title = mr.exp[1];

 	rhs->skipping_current_block = FALSE;
 	match_results mr2 = Regexp::create_mr();
 	if (Regexp::match(&mr2, block_header, L"{(%c*?):}(%c*?)")) {
 		Str::copy(block_header, mr2.exp[1]);
 		if (Symbols::perform_ifdef(mr2.exp[0]) == FALSE) {
 			rhs->skipping_current_block = TRUE;
 		}
 	}

 	if (rhs->skipping_current_block == FALSE) {
 		text_stream *OUT = rhs->OUT;
		@<Render the block just completed, unless it's empty@>;
		rhs->OUT = OUT;
		@<Take note of documentation references@>;
		Str::copy(rhs->title_of_block_being_read, title);

		if (Regexp::match(&mr2, block_header, L"Chapter: (%c*)")) {
			++(rhs->no_chapters_read_in_current_rawtext);
			@<Prepare to read a new chapter of rawtext@>;
		}
		@<Prepare to read a new block of rawtext@>;
	}
	Regexp::dispose_of(&mr2);

@ Section headings can be marked with braced documentation references:
= (text as Indoc)
	[x] The footwear kind {kind_footwear}
=
@<Take note of documentation references@> =
 	while (Regexp::match(&mr2, title, L"(%c*) {(%C+)} *")) {
 		Str::copy(title, mr2.exp[0]);
 		Updater::add_reference_symbol(mr2.exp[1], rhs->V,
 			(rhs->V)?(rhs->V->sections[rhs->no_blocks_written]):NULL);
 	}

@ Rawtext is not allowed to contain direct HTML markup, but it can contain
"span notations", which can in turn be configured to look like HTML markup.
So, for instance, the Inform documentation uses |<b>...</b>| for bold and
|<i>...</i>| for italic, but this is only because its instructions say so.

(We also look for indexing markup, and we need to do that first, because
smoke-test indexing mode applies direct markup to make its smoky black
rectangles.)

@<Deal with any permitted markup@> =
 	if ((indoc_settings->treat_code_as_verbatim == FALSE) || (Str::get_first_char(rawl) != '\t')) {
 		Indexes::scan_indexingnotations(rawl, rhs->V,
 			(rhs->V)?(rhs->V->sections[rhs->no_blocks_written]):NULL, rhs->E);
 		CSS::expand_spannotations(rawl, MARKUP_SPP);
 	}

 	if (indoc_settings->format == HTML_FORMAT) Regexp::replace(rawl, L"<(%c*?)>", L"&lt;%0&gt;", REP_REPEATING);

 	wchar_t *replacement = L"%1";
 	if (indoc_settings->format == HTML_FORMAT) replacement = L"<span class=\"%0\">%1</span>";
 	Regexp::replace(rawl, L"___mu___(%c*?)___mo___(%c*?)___mc___", replacement, REP_REPEATING);

@ The notation |///6X12.txt///| means "insert the change log for build 6X12 here".
It should be the only thing on its line.

@<Deal with an insert-change-log notation@> =
 	if (Regexp::match(&mr2, rawl, L"(%c*?)///(%c*?.txt)/// *")) {
 		Str::copy(rawl, mr2.exp[0]);
 		if (indoc_settings->format == HTML_FORMAT) {
 			Str::clear(rawl);
 			HTML::hr(rawl, NULL);
 			HTML::open(rawl, "pre", I"class='changelog'");
 			suppress_p_tag = TRUE;
 		}
 		filename *cl = Filenames::in(indoc_settings->change_logs_folder, mr2.exp[1]);
		TextFiles::read(cl, FALSE, "can't open change log file",
			TRUE, Rawtext::process_change_log_helper, NULL, rawl);
 		if (indoc_settings->format == HTML_FORMAT) {
 			WRITE_TO(rawl, "\n");
 			HTML::close(rawl, "pre");
 		}
 	}

@ Where, almost verbatim, we copy from the change log into the raw-line:

=
void Rawtext::process_change_log_helper(text_stream *sml, text_file_position *tfp,
	void *v_rawl) {
	text_stream *rawl = (text_stream *) v_rawl;
	if (indoc_settings->format == HTML_FORMAT) {
		Regexp::replace(sml, L"<", L"&lt;", REP_REPEATING);
		Regexp::replace(sml, L">", L"&gt;", REP_REPEATING);
	}
	WRITE_TO(rawl, "%S\n", sml);
}

@ Images are embedded with the notation
= (text as Indoc)
	///filename.extension///
=
though only one of these may appear in each line. If the form
= (text as Indoc)
	///classname:filename.extension///
=
is used, then the image is styled as |img.classname|.

@<Deal with an insert-image notation@> =
 	while (Regexp::match(&mr2, rawl, L"(%c*?)///(%c*?)///(%c*)")) {
 		text_stream *left = mr2.exp[0];
 		text_stream *name = mr2.exp[1];
 		text_stream *right = mr2.exp[2];
 		TEMPORARY_TEXT(cl);
 		match_results mr3 = Regexp::create_mr();
 		if (Regexp::match(&mr3, name, L"(%c*?): *(%c*)")) {
 			Str::copy(cl, mr3.exp[0]); Str::copy(name, mr3.exp[1]);
  			Regexp::dispose_of(&mr3);
		}
 		TEMPORARY_TEXT(url);
 		HTMLUtilities::image_URL(url, name);
 		Str::clear(rawl);
 		if (indoc_settings->format == HTML_FORMAT) {
 			WRITE_TO(rawl, "%S", left);
 			TEMPORARY_TEXT(details);
 			WRITE_TO(details, "alt=\"%S\" src=\"%S\"", name, url);
 			if (Str::len(cl) > 0) WRITE_TO(details, " class=\"%S\"", cl);
 			HTML::tag_sc(rawl, "img", details);
			DISCARD_TEXT(details);
 			WRITE_TO(rawl, "%S", right);
 		} else {
 			WRITE_TO(rawl, "%S(Image %S here)%S", left, name, right);
 		}
 		DISCARD_TEXT(cl);
 		DISCARD_TEXT(url);
 	}

@ A paragraph beginning with braced material, |{thus}|, is "tagged". There
can be multiple tags, in principle, which is why this is arranged as a loop,
though it's not often needed more than once. Tags are simply markers which
annotate the paragraph, so we extract each in turn from the left-hand side,
then act accordingly.

@<Deal with paragraph tags@> =
	match_results mr3 = Regexp::create_mr();
	match_results mr4 = Regexp::create_mr();
	while (Regexp::match(&mr3, rawl, L"{(%c*?)}(%c*)")) {
 		text_stream *paragraph_tag = mr3.exp[0];
 		Str::copy(rawl, mr3.exp[1]);

 		@<Deal with a conditional paragraph tag@>;
 		@<Deal with a phrase definition paragraph tag@>;
 		@<Deal with a CSS-styling paragraph tag@>;
 		Errors::with_text("{%S} is not a tag I know", paragraph_tag);
 	}
 	Regexp::dispose_of(&mr3);
 	Regexp::dispose_of(&mr4);

@ One use of paragraph tags is to mark a paragraph as being relevant only
to one of the platforms on which Inform runs. (We've already seen this done
for whole blocks of documentation: this is much finer control.) For example,
documentation might say:
= (text as Indoc)
	{Windows}The My Documents folder can be reached using...
=
If we're generating for Windows, we ignore the tag: this looks like a
regular paragraph to us. If we're generating for some other platform, we
throw the whole paragraph away. If we're generating for no specific platform
(for example, for the Inform website), we keep the paragraph but annotate it.

@<Deal with a conditional paragraph tag@> =
 	if (Regexp::match(&mr4, paragraph_tag, L"(%c*):")) {
 		if (Symbols::perform_ifdef(mr4.exp[0])) continue;
 		abandon_para = TRUE; break;
 	}

@ Tags also mark the presence of phrase explanations in the main WWI:
= (text as Indoc)
	{defn ph_letdefault}let (a name not so far used) be (name of kind)
	...
	{end}
=

@<Deal with a phrase definition paragraph tag@> =
 	if (Regexp::match(&mr4, paragraph_tag, L"defn *(%c*?)")) {
 		text_stream *defn = mr4.exp[0];
 		TEMPORARY_TEXT(head);
 		Str::copy(head, rawl);
 		while (Characters::is_whitespace(Str::get_last_char(head)))
 			Str::delete_last_character(head);
 		Updater::add_reference_symbol(defn, rhs->V, (rhs->V)?(rhs->V->sections[rhs->no_blocks_written]):NULL);
 		Str::clear(rawl);
 		HTMLUtilities::definition_box(rawl, head, defn, rhs->V,
 			(rhs->V)?(rhs->V->sections[rhs->no_blocks_written]):NULL);
 		suppress_p_tag = TRUE;
 		continue;
 	}
 	if (Str::eq_wide_string(paragraph_tag, L"end")) {
 		Str::clear(rawl);
 		HTMLUtilities::end_definition_box(rawl);
 		suppress_p_tag = TRUE;
 		continue;
 	}

@<Deal with a CSS-styling paragraph tag@> =
 	if (Regexp::match(&mr4, paragraph_tag, L"(%c*)/")) {
 		Str::copy(css_style, mr4.exp[0]);
 		continue;
 	}

@ Finally, then, we're left with a regular paragraph. It was never a
block heading, and whatever tags it once had have been removed.

@<Deal with a regular paragraph@> =
 	int indentation_count = 0;
 	@<Establish the indentation level@>;
 	@<Treat the text as necessary@>;
 	Renderer::add_para_to_block_buffer(rawl, indentation_count, suppress_p_tag,
 		HTML_prefix, css_style, shortened);
 	rhs->no_pars_read_in_current_block++;

@ Initial tab characters (alone) are read as indentation.

@<Establish the indentation level@> =
 	while (Str::get_first_char(rawl) == '\t') {
 		indentation_count++;
 		Str::delete_first_character(rawl);
 	}

@ In the case of HTML, we need to be careful not to turn double-quotes used
in tag elements into |&quot;| escapes.

@<Treat the text as necessary@> =
 	if (indoc_settings->format == HTML_FORMAT) {
 		TEMPORARY_TEXT(dequotee);
 		Str::copy(dequotee, rawl);
 		Str::clear(rawl);
 		match_results mr4 = Regexp::create_mr();
 		while (Regexp::match(&mr4, dequotee, L"(%c*?)<(%c*?)>(%c*)")) {
 			text_stream *L = mr4.exp[0]; text_stream *M = mr4.exp[1]; text_stream *R = mr4.exp[2];
 			Rawtext::escape_HTML_characters_in(L);
 			WRITE_TO(rawl, "%S<%S>", L, M);
 			Str::copy(dequotee, R);
 		}
 		Rawtext::escape_HTML_characters_in(dequotee);
 		WRITE_TO(rawl, "%S", dequotee);
 	}

@ =
void Rawtext::escape_HTML_characters_in(text_stream *text) {
 	if (indoc_settings->format == HTML_FORMAT) {
		TEMPORARY_TEXT(modified);
		for (int i=0, L=Str::len(text); i<L; i++) {
			int c = Str::get_at(text, i);
			switch (c) {
				case '\"': 		WRITE_TO(modified, "&quot;"); break;
				case '<':		WRITE_TO(modified, "&lt;"); break;
				case '>':		WRITE_TO(modified, "&gt;"); break;
				case '&':
					if (Str::get_at(text, i+1) == '#') { PUT_TO(modified, c); break; }
					int j = i+1;
					while (Characters::isalnum(Str::get_at(text, j))) j++;
					if ((j > i+1) && (Str::get_at(text, j) == ';')) { PUT_TO(modified, c); break; }
					WRITE_TO(modified, "&amp;");
					break;
				default: 		PUT_TO(modified, c); break;
			}
		}
		Str::copy(text, modified);
		DISCARD_TEXT(modified);
 	}
}
