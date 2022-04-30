[Renderer::] Renderer.

The general output apparatus for writing a block of documentation.

@ The output mechanism produces documentation in chunks called "blocks", and
it has a buffer which stores one block at a time. Each block contains a
list of paragraphs, numbered from 0.

@d MAX_PARAGRAPHS_PER_BLOCK 1000

=
typedef struct paragraph {
	int par_indentation;
	int par_suppression;
	struct text_stream *par_texts;
	struct text_stream *par_prefix;
	struct text_stream *par_styles;
	int par_shortened;
} paragraph;

@

= (early code)
int no_paras_in_block_buffer = 0;

paragraph paragraphs[MAX_PARAGRAPHS_PER_BLOCK];

@ The blocks are written to a file of "formatted text":

=
filename *current_FTD_filename = NULL; /* with |NULL| meaning that no file is open */
text_stream current_FTD_stream; /* otherwise, this is where the text goes */

@ It's convenient to record all the formatted text filenames written to, and
those are the keys of the following hash:

=
typedef struct formatted_file {
	struct filename *name;
	CLASS_DEFINITION
} formatted_file;

@ Miscellaneously:

=
int index_to_examples = FALSE; /* used to index examples to particular sections */
int unique_code_pos_counter = 0; /* used to uniquely ID code samples */
example *code_example = NULL;

@h Block buffer.
When the scanner starts a new block, it calls this:

=
void Renderer::clear_block_buffer(void) {
 	no_paras_in_block_buffer = 0;
 	index_to_examples = FALSE;
}

@ It then calls this to add paragraphs to the block:

=
void Renderer::add_para_to_block_buffer(text_stream *text, int indentation, int suppression,
	text_stream *prefix, text_stream *style, int shortened) {
	if (no_paras_in_block_buffer >= MAX_PARAGRAPHS_PER_BLOCK)
		Errors::fatal("too many paragraphs in block");
	paragraph *P = &paragraphs[no_paras_in_block_buffer++];
	P->par_indentation = indentation;
	P->par_texts = Str::duplicate(text);
	P->par_suppression = suppression;
	P->par_prefix = Str::duplicate(prefix);
	P->par_styles = Str::duplicate(style);
	P->par_shortened = shortened;
}

@h Top-level renderer.
If the block consists of text from a section, then the scanner calls the
following when the buffer is filled. If, on the other hand, the block
comes from an example, it calls |render_text_of_block| instead, a simpler
routine which doesn't surround the text with navigational gadgets and headings.

=
text_stream *Renderer::render_block(OUTPUT_STREAM, volume *V, section *S) {
	OUT = Renderer::formatted_file_must_be(OUT, V, S);
 	Nav::render_navigation_top(OUT, V, S);
 	Renderer::render_text_of_block(OUT, V, S);
 	Nav::render_navigation_middle(OUT, V, S);
 	@<Render the examples below the text of the block@>;
 	Nav::render_navigation_bottom(OUT, V, S);
 	return OUT;
}

@<Render the examples below the text of the block@> =
 	TEMPORARY_TEXT(form_of_title_to_test)
 	@<Adapt the block title to the form of the title to test@>;
 	int no_examples_rendered_here = 0;
 	for (int n = 0; n < no_examples; n++) {
 		example *E = V->examples_sequence[n];
 		if (E->example_displayed_at_section[V->allocation_id] == S) {
			no_examples_rendered_here++;
			if (no_examples_rendered_here == 1)
				Nav::render_navigation_example_top(OUT, V, S);
			@<Render the example here@>;
			if (indoc_settings->examples_mode == EXMODE_open_internal) HTMLUtilities::ruled_line(OUT);
 		}
 	}

 	if (no_examples_rendered_here > 0)
 		Nav::render_navigation_example_bottom(OUT, V, S);

@ Examples need to connect with particular sections of documentation, but
they do so by title, not by block number, to protect them from renumbering
as sections are added or removed. So if the current block is called
= (text as Indoc)
	2.3. Sailing Ships
=
then we need to look for the text |Sailing Ships| to see if an example
belongs here. (But, owing to a historical accident, in the Recipe Book
section names are capitalised for this purpose.)

@<Adapt the block title to the form of the title to test@> =
 	Str::copy(form_of_title_to_test, S->unlabelled_title);
 	match_results mr = Regexp::create_mr();
 	if (Regexp::match(&mr, form_of_title_to_test, L"(%d+.)* *(%c*)")) {
 		Str::copy(form_of_title_to_test, mr.exp[1]); Regexp::dispose_of(&mr);
 	}
 	if (V->allocation_id == 1)
 		LOOP_THROUGH_TEXT(pos, form_of_title_to_test)
 			Str::put(pos, Characters::toupper(Str::get(pos)));

@<Render the example here@> =
	TEMPORARY_TEXT(index_term)
	WRITE_TO(index_term, "%S=___=!example", E->ex_public_name);
 	Indexes::mark_index_term(index_term, V, NULL, NULL, E, NULL, NULL);
	DISCARD_TEXT(index_term)
 	if (indoc_settings->format == HTML_FORMAT) {
		TEMPORARY_TEXT(comment)
		WRITE_TO(comment, "START EXAMPLE \"%d: %S\" \"e%d\"",
			E->example_position[0], E->ex_public_name, E->allocation_id);
		HTML::comment(OUT, comment);
		DISCARD_TEXT(comment)
 	}
 	Examples::render_example_cue(OUT, E, V, 0);
	code_example = E;
	OUT = Renderer::render_example_body(OUT, E, V, TRUE);
	code_example = NULL;
	if (indoc_settings->format == HTML_FORMAT) HTML::comment(OUT, I"END EXAMPLE");

@ =
text_stream *Renderer::render_example_body(OUTPUT_STREAM, example *E, volume *V, int empty) {
	int hide = FALSE;
	if (indoc_settings->examples_mode == EXMODE_openable_internal) hide = TRUE;
	if (indoc_settings->format == HTML_FORMAT) {
		TEMPORARY_TEXT(id)
		WRITE_TO(id, "example%d", E->allocation_id);
		HTML::begin_div_with_class_and_id_S(OUT, I"egpanel", id, hide);
	}
	OUT = Rawtext::process_example_rawtext_file(OUT, V, E);
	if (indoc_settings->format == HTML_FORMAT) {
		HTML::end_div(OUT);
		if (empty) { HTML_OPEN("p"); HTML_CLOSE("p"); }
	}
	return OUT;
}

@h Rendering text.
The actual contents of the buffer are rendered here, then:

=
text_stream *Renderer::render_text_of_block(OUTPUT_STREAM, volume *V, section *S) {
 	if (indoc_settings->format == PLAIN_FORMAT) @<Render the block buffer as plain text@>
 	else if (indoc_settings->format == HTML_FORMAT) @<Render the block buffer as HTML@>;
 	return OUT;
}

@ Plain text is very plain indeed:

@<Render the block buffer as plain text@> =
 	for (int i=0; i<no_paras_in_block_buffer; i++) {
 		/* Indent using tabs */
 		int ic = paragraphs[i].par_indentation;
 		while (ic > 0) { ic--; WRITE("\t"); }

 		/* Remove any paste markers entirely */
 		text_stream *raw = paragraphs[i].par_texts;
  		match_results mr = Regexp::create_mr();
 		if ((indoc_settings->treat_code_as_verbatim == FALSE) &&
 			(Regexp::match(&mr, raw, L"{%*+} *(%c*)")))
 			WRITE("%S\n", mr.exp[0]);
 		else
 			WRITE("%S\n", raw);
 		Regexp::dispose_of(&mr);
 	}

@ HTML is more work:

@<Render the block buffer as HTML@> =
 	int code_mode = FALSE;
 	int tabular_mode = FALSE;
 	int last_xref_type = 0; /* 0 means "none"; 1 means "to section"; 2 means "to example" */

 	for (int i=0; i<no_paras_in_block_buffer; i++) {
 		paragraph *P = &(paragraphs[i]);
 		if (P->par_indentation == 0) {
 			if (tabular_mode) @<Exit tabular mode@>;
 			if (code_mode) @<Exit code mode@>;
 			@<Look for cross-references and then render@>;
 		} else {
 			if (tabular_mode == FALSE) {
 				if (code_mode == FALSE) @<Enter code mode@>
 				else HTML_TAG("br");
 				if (Regexp::match(NULL, P->par_texts, L"%c*%C\t+%C%c*"))
 					@<Enter tabular mode@>;
 			}
 			if (tabular_mode)
 				@<Render the tab-divided line as an HTML table row@>
 			else
 				@<Render the line in code mode@>;
 		}
 	}
 	if (tabular_mode) @<Exit tabular mode@>;
 	if (code_mode) @<Exit code mode@>;

@h Code mode.
Code mode is when the renderer is working on a displayed quotation of source
code, broken off from the main narrative.

@<Enter code mode@> =
 	code_mode = 1;
 	TEMPORARY_TEXT(id)
 	WRITE_TO(id, "c%d", ++unique_code_pos_counter);
 	if (code_example) WRITE_TO(id, "_%d", code_example->allocation_id);
 	TEMPORARY_TEXT(comment)
 	WRITE_TO(comment, "START CODE \"%S\"", id);
 	HTML::comment(OUT, comment);
 	DISCARD_TEXT(comment)
 	HTML_OPEN_WITH("blockquote", "class=\"code\"");
 	HTML_OPEN_WITH("p", "class=\"quoted\"");
 	HTML::anchor(OUT, id);

@ Quoted code is pretty well passed through in raw form, except for Javascript
paste markers, which occupy a lot of code below but don't actually come up
very much.

@<Render the line in code mode@> =
 	@<Render some indentation@>;
 	TEMPORARY_TEXT(raw)
 	Str::copy(raw, P->par_texts);

 	if (indoc_settings->treat_code_as_verbatim == FALSE) {

 		Regexp::replace(raw, L"{%*%*}", NULL, REP_REPEATING); /* Remove any paste-continuation marker */

 		@<Take note of any named inline example@>;

 		match_results mr = Regexp::create_mr();
 		if (Regexp::match(&mr, raw, L"(%c*?){%*}(%c*)")) {
 			@<Convert this paste marker to a Javascript paste mechanism@>;
 			Regexp::dispose_of(&mr);
 		}
 	}

 	WRITE("%S\n", raw);

@ A distinctly olde-worlde way to indent.

@<Render some indentation@> =
 	int ic = P->par_indentation;
 	while (ic > 1) { ic--; WRITE("&#160;&#160;&#160;&#160;"); }

@<Take note of any named inline example@> =
 	match_results mr = Regexp::create_mr();
 	if ((index_to_examples) &&
 		(Regexp::match(&mr, raw, L"{%*}&quot;(%c*)&quot;%c*")) &&
 		(Str::ne_wide_string(mr.exp[0], L"Midsummer Day"))) {
 		ExamplesIndex::add_to_alphabetic_examples_index(mr.exp[0], S, NULL, TRUE, FALSE);
 		Regexp::dispose_of(&mr);
 	}

@<Exit code mode@> =
 	code_mode = FALSE;
 	HTML_CLOSE("p");
 	HTML_CLOSE("blockquote");
 	HTML::comment(OUT, I"END CODE");

@h Tabular mode.
Tabular mode is not an alternative to code mode: it's a deeper mode within
it, and is used for a display of I7 source text (i.e., code) when it needs
to show a Table.

@<Enter tabular mode@> =
 	tabular_mode = TRUE;
 	HTML_CLOSE("p");
 	HTML_CLOSE("blockquote");
 	HTML_OPEN_WITH("table", "class=\"codetable\"");

@ Within tabular mode, the following renders lines.

Note that any run of one or more tabs is treated as a single column
division, and that leading or trailing tabs are ignored -- so there is no
way to code for an entirely empty cell. (This is fine for Inform documentation
purposes since the only empty cells are trailing ones in the line anyway;
people use the blank marker |--| explicitly if they want blanks.)

@<Render the tab-divided line as an HTML table row@> =
	HTML_OPEN("tr");
	HTML_OPEN_WITH("td", "class=\"quotedtablecell\"");
	HTML_OPEN_WITH("p", "class=\"quoted\"");

 	TEMPORARY_TEXT(row)
 	match_results mr = Regexp::create_mr();
 	Regexp::match(&mr, P->par_texts, L" *(%c*?) *");
 	Str::copy(row, mr.exp[0]); /* Strip leading and trailing space */

 	while (Regexp::match(&mr, row, L"(%c*?)\t+(%c*)")) {
 		WRITE("%S", mr.exp[0]); /* Place a cell division at any run of one or more tabs */
 		HTML_CLOSE("p");
 		HTML_CLOSE("td");
		HTML_OPEN_WITH("td", "class=\"quotedtablecell\"");
 		HTML_OPEN_WITH("p", "class=\"quoted\"");
 		Str::copy(row, mr.exp[1]);
 	}
 	WRITE("%S", row);
 	DISCARD_TEXT(row)
 	Regexp::dispose_of(&mr);
 	HTML_CLOSE("p");
 	HTML_CLOSE("td");
	HTML_CLOSE("tr");

@<Exit tabular mode@> =
 	tabular_mode = FALSE;
 	HTML_CLOSE("table");
 	HTML_OPEN("blockquote");
 	HTML_OPEN("p");

@h Regular mode.
So this is what happens when we're not in either tabular or code mode.

The foot of a block of documentation sometimes contains cross-references
to other blocks (resolved by name), and this is where we recognise and
convert those to HTML links.

@<Look for cross-references and then render@> =
 	match_results mr = Regexp::create_mr();
 	if (Regexp::match(&mr, P->par_texts, L"%((-*)See {(%c*?)} for (%c*?).%) *")) {
 		if (Str::len(mr.exp[0]) == 0) {
 			Renderer::render_cross_reference(OUT, mr.exp[1], mr.exp[2], V, 0);
 		} else {
 			if (last_xref_type == 0) { HTML_TAG("hr"); }
 			Renderer::render_cross_reference(OUT, mr.exp[1], mr.exp[2], V, 1);
 		}
 		last_xref_type = 1;
 	} else if (Regexp::match(&mr, P->par_texts, L"%((-*)See (%c*?) for (%c*?).%) *")) {
 		if (Str::len(mr.exp[0]) == 0) {
 			Renderer::render_cross_reference(OUT, mr.exp[1], mr.exp[2], V, 0);
 		} else {
 			if (last_xref_type == 0) { HTML_TAG("hr"); }
 			Renderer::render_cross_reference(OUT, mr.exp[1], mr.exp[2], V, 1);
 		}
 		last_xref_type = 1;
 	} else if (Regexp::match(&mr, P->par_texts, L"%(See example &quot;(%c*?)&quot;%) *")) {
 		if (last_xref_type == 1) { HTML_TAG("hr"); }
 		Renderer::render_example_cross_reference(OUT, mr.exp[0], V);
 		last_xref_type = 2;
 	} else @<Render a non-quotation paragraph to HTML@>;
  	Regexp::dispose_of(&mr);

@ Blank lines are simply ignored.

@<Render a non-quotation paragraph to HTML@> =
 	if (Regexp::match(NULL, P->par_texts, L" *") == FALSE) {
 		WRITE("%S", P->par_prefix);
 		if (P->par_suppression == TRUE) {
 			WRITE("%S\n", P->par_texts);
 		} else {
 			if (Str::len(P->par_styles) > 0) {
 				TEMPORARY_TEXT(details)
 				WRITE_TO(details, "class=\"%S\"", P->par_styles);
 				HTML::open(OUT, "p", details);
 				DISCARD_TEXT(details)
 				WRITE("%S", P->par_texts);
				HTML_CLOSE("p");
 			} else {
 				HTML_OPEN("p");
 				WRITE("%S", P->par_texts);
				HTML_CLOSE("p");
 			}
 		}
 	}

@h Javascript paste icons.
That's the whole rendering routine, except for the handling of Javascript
paste icons. In rawtext, these look like so:
= (text as Indoc)
	    {*}A useful sentence.
=
The |{*}| is replaced by a button which, when clicked on, performs a Javascript
function call to paste "A useful sentence" into the Inform application's
source text pane. (Note that the "A useful sentence" text is still also
rendered on screen -- it doesn't vanish into the button.) These pastes
can occur only in code mode, and can extend for multiple lines, as we'll
see below.

@<Convert this paste marker to a Javascript paste mechanism@> =
	Str::copy(raw, mr.exp[0]);
	TEMPORARY_TEXT(right)
	Str::copy(right, mr.exp[1]);
	if (indoc_settings->javascript == FALSE) {
 		WRITE_TO(raw, "%S", right);
 	} else {
 		WRITE_TO(raw, "<a href=\"javascript:pasteCode(");
 		TEMPORARY_TEXT(J_text)
 		@<Determine the quoted J-text@>;
 		TEMPORARY_TEXT(titling)
 		if (code_example) {
 			WRITE_TO(titling, "Example - ");
 			LOOP_THROUGH_TEXT(pos, code_example->ex_public_name) {
 				int c = Str::get(pos);
 				if (c == '\'') WRITE_TO(titling, "\\'");
 				else PUT_TO(titling, c);
 			}
 		}
 		Renderer::apply_Inform_escape_characters(titling);
 		WRITE_TO(raw, "'%S\\n'", J_text);
 		WRITE_TO(raw, ")\">");
 		if (indoc_settings->retina_images) HTMLUtilities::image_element_scaled(raw, I"paste@2x.png", 13, 13);
 		else HTMLUtilities::image_element(raw, I"paste.png");
 		WRITE_TO(raw, "</a> ");
 		if ((indoc_settings->support_creation) && (Str::len(titling) > 0)) {
 			WRITE_TO(raw, "<a href=\"javascript:createNewProject");
 			WRITE_TO(raw, "(");
 			WRITE_TO(raw, "'%S\\n', '%S'", J_text, titling);
 			WRITE_TO(raw, ")\">");
 			if (indoc_settings->retina_images) {
 				HTMLUtilities::image_element_scaled(raw, I"create@2x.png", 26, 13);
 			} else {
 				HTMLUtilities::image_element(raw, I"create.png");
 			}
 			WRITE_TO(raw, "</a>");
			WRITE_TO(raw, "&nbsp;&nbsp; ");
 		}
  		WRITE_TO(raw, "%S", right);
 	}

@ The rawtext is doing something like this:
= (text)
	    {*}A ball is in the bag.
	    The bag is on the kitchen table.
	
	This single sentence doesn"t make much of a simulation. Let"s add:
	
	    {**}The stitched seam is part of the ball.
=
The line count |i| points to the first line of this. The paste consists
of the two lines about the bag and the table, but with the stitched seam
line added in, because of the |{**}| continuation marker. The "range" is
down to the last line which is included in the paste.

@<Determine the quoted J-text@> =
 	int up_to; /* one line beyond what will be pasted */
 	@<Find the range of rawtext lines which fall into this paste@>;
 	@<Collate the indented lines in that range into the J-text@>;
 	Renderer::apply_Inform_escape_characters(J_text);

@<Find the range of rawtext lines which fall into this paste@> =
 	for (up_to = i; ((up_to<no_paras_in_block_buffer) &&
 		((paragraphs[up_to].par_indentation > 0) ||
 			(Str::len(paragraphs[up_to].par_texts) == 0))); up_to++) { ; }
 	int extended_range = TRUE;
 	while (extended_range) {
 		extended_range = FALSE;
 		int l;
 		for (l=up_to; ((l<no_paras_in_block_buffer) &&
 			(paragraphs[l].par_indentation == 0)); l++) { ; }
 		if ((l<no_paras_in_block_buffer) &&
 			(Regexp::match(NULL, paragraphs[l].par_texts, L"%c*{%*%*}%c*"))) {
 			for (l++; ((l<no_paras_in_block_buffer) &&
 				((paragraphs[l].par_indentation > 0) ||
 					(Str::len(paragraphs[l].par_texts) == 0))); l++) { ; }
 			up_to = l; extended_range = TRUE;
 		}
 	}

@<Collate the indented lines in that range into the J-text@> =
 	for (int j=i; j<up_to; j++) {
 		int ic = paragraphs[j].par_indentation;
 		TEMPORARY_TEXT(joinbit)
 		while (ic > 1) { ic--; PUT_TO(J_text, '\t'); }
 		if (j == i) Str::copy(joinbit, right);
 		else Str::copy(joinbit, paragraphs[j].par_texts);
 		if ((paragraphs[j].par_indentation == 0) && (Str::len(joinbit) > 0)) {
 			TEMPORARY_TEXT(br)
 			WRITE_TO(br, "[%S]", joinbit);
 			Str::copy(joinbit, br);
 			DISCARD_TEXT(br)
 		}
 		for (int k=0, L = Str::len(joinbit), prev_c = -1; k<L; k++) {
 			int c = Str::get_at(joinbit, k);
 			switch (c) {
 				case '\\': WRITE_TO(J_text, "___backslash___"); break;
 				case '\'': WRITE_TO(J_text, "\\'"); break;
 				case '\t': if (prev_c != '\t') WRITE_TO(J_text, "\\t"); break;
 				case '&': if (Str::includes_wide_string_at(joinbit, L"amp;", k+1)) k += 4;
 					PUT_TO(J_text, c); break;
 				case '{': if (Str::includes_wide_string_at(joinbit, L"**}", k+1)) k += 3;
 					else PUT_TO(J_text, c); break;
 				default: PUT_TO(J_text, c); break;
 			}
 			prev_c = c;
 		}
 		PUT_TO(J_text, '\n');
 		DISCARD_TEXT(joinbit)
 	}

@ =
void Renderer::remove_paste_markers(text_stream *text) {
	for (int i=0, L=Str::len(text); i<L; i++) {
		if ((Str::get_at(text, i) == '{') &&
			(Str::get_at(text, i+1) == '*') &&
			(Str::get_at(text, i+2) == '*') &&
			(Str::get_at(text, i+3) == '}')) {
			Renderer::remove_paste_markers_from(text, i);
			return;
		}
	}
}

void Renderer::remove_paste_markers_from(text_stream *text, int i) {
	TEMPORARY_TEXT(modified)
	for (int j=0; j<i; j++) PUT_TO(modified, Str::get_at(text, j));
	for (int L=Str::len(text); i<L; i++) {
		int c = Str::get_at(text, i);
		if ((c == '{') &&
			(Str::get_at(text, i+1) == '*') &&
			(Str::get_at(text, i+2) == '*') &&
			(Str::get_at(text, i+3) == '}')) i+=3;
		else PUT_TO(modified, c);
	}
	Str::copy(text, modified);
	DISCARD_TEXT(modified)
}

@ =
void Renderer::apply_Inform_escape_characters(text_stream *text) {
	TEMPORARY_TEXT(modified)
	for (int i=0, L=Str::len(text); i<L; i++) {
		int c = Str::get_at(text, i);
		switch (c) {
			case '\\':
				c = Str::get_at(text, ++i);
				if (c == '\'') WRITE_TO(modified, "[=0x0027=]");
				else if (c == 't') WRITE_TO(modified, "[=0x0009=]");
				else WRITE_TO(modified, "\\%c", c);
				break;
			case '\"': 		WRITE_TO(modified, "[=0x0022=]"); break;
			case '\x0a':	WRITE_TO(modified, "[=0x000A=]"); break;
			case '\x0d':	WRITE_TO(modified, "[=0x000A=]"); break;
			case '\t':		WRITE_TO(modified, "[=0x0009=]"); break;
			case '<':		WRITE_TO(modified, "[=0x003C=]"); break;
			case '>':		WRITE_TO(modified, "[=0x003E=]"); break;
			case '_':
				if (Str::includes_wide_string_at(text, L"__backslash___", i+1)) {
					WRITE_TO(modified, "[=0x005C=]"); i+=14;
				} else PUT_TO(modified, c);
				break;
			case '&':
				if (Str::includes_wide_string_at(text, L"quot;", i+1)) {
					WRITE_TO(modified, "[=0x0022=]"); i+=5;
				} else if (Str::includes_wide_string_at(text, L"lt;", i+1)) {
					WRITE_TO(modified, "[=0x003C=]"); i+=3;
				} else if (Str::includes_wide_string_at(text, L"gt;", i+1)) {
					WRITE_TO(modified, "[=0x003E=]"); i+=3;
				} else {
					WRITE_TO(modified, "[=0x0026=]");
				}
				break;
			default:		PUT_TO(modified, c); break;
		}
	}
	Str::copy(text, modified);
	DISCARD_TEXT(modified)
}

@h Rendering cross-references to other sections.
These occur when the rawtext contains paragraphs with a very specific
arrangement:
= (text as Indoc)
	(-See Units for a more sophisticated capacity system.)
=
The idea is that, except for the brackets and dash, the text makes sense as
it stands; but in HTML, we can use the section title ("Units" here) to find
which block is meant, and encode this as a link.

=
void Renderer::render_cross_reference(OUTPUT_STREAM,
 	text_stream *sname, text_stream *reason, volume *V, int quieter) {
 	if (indoc_settings->format == PLAIN_FORMAT)
 		WRITE("(See %S for %S.)\n", sname, reason);

 	if (indoc_settings->format == HTML_FORMAT) {
	  	TEMPORARY_TEXT(dest)
	 	WRITE_TO(dest, "index.html");
	 	@<Identify the reference destination and be sure it exists@>;

 		HTML_OPEN_WITH("p", "class=\"crossreference\"");
 		HTML::begin_link_with_class(OUT, I"xreflink", dest);
 		HTMLUtilities::asterisk_image(OUT, I"xref.png");
 		WRITE("&#160;<i>See </i><b>%S</b>", sname);
 		HTML::end_link(OUT);
 		if (quieter == FALSE) HTML_OPEN("i");
 		WRITE(" for %S", reason);
 		if (quieter == FALSE) HTML_CLOSE("i");
 		HTML_CLOSE("p");
	  	DISCARD_TEXT(dest)
 	}
}

@<Identify the reference destination and be sure it exists@> =
	section *S = (section *) Dictionaries::read_value(V->sections_by_name, sname);
 	if (S) Str::copy(dest, S->section_URL);
 	else Errors::with_text("cross-reference to %S points to no section", sname);

@ And similarly, for cross-referencing to examples by name:
= (text as Indoc)
	(See example "Blink")
=

=
void Renderer::render_example_cross_reference(OUTPUT_STREAM, text_stream *ename, volume *V) {
	example *E = (example *) Dictionaries::read_value(examples_by_name, ename);
 	if (E) Examples::render_example_cue(OUT, E, V, 1);
 	else Errors::with_text("cross-reference to %S points to no section", ename);

}

@h Handling the formatted file.
The idea is that several sections in a row may need to be written to the
same file, or may not. So this routine is called to guarantee that the
right file is open, rather than always to open one.

=
text_stream *Renderer::formatted_file_must_be(OUTPUT_STREAM, volume *V, section *S) {
 	if (Filenames::eq(S->section_filename, current_FTD_filename) == FALSE) {
 		if (current_FTD_filename) OUT = Renderer::close_formatted_file(OUT);
 		current_FTD_filename = S->section_filename;
		OUT = &current_FTD_stream;
		if (Streams::open_to_file(OUT, S->section_filename, UTF8_ENC) == FALSE)
			Errors::fatal_with_file("can't write documentation", S->section_filename);
		if (indoc_settings->wrapper == WRAPPER_epub) {
			ebook_page *page =
				Epub::note_page(indoc_settings->ebook, S->section_filename, S->section_file_title, I"");
			if (S == V->sections[0]) {
				ebook_volume *ev = Epub::starts_volume(indoc_settings->ebook, page, V->vol_title);
				filename *F = Filenames::in(indoc_settings->destination, V->vol_CSS_leafname);
				Epub::use_CSS(ev, F);
			}
			if (S->begins_which_chapter)
				S->begins_which_chapter->ebook_ref =
					Epub::starts_chapter(indoc_settings->ebook, page, S->begins_which_chapter->chapter_full_title, S->begins_which_chapter->chapter_URL);
		}

		formatted_file *ftd = CREATE(formatted_file);
		ftd->name = current_FTD_filename;

 		if (indoc_settings->format == HTML_FORMAT) @<Write the HTML header for the formatted file@>;
 	}
 	return OUT;
}

@ When we certainly want to dispose of the current file:

=
text_stream *Renderer::close_formatted_file(OUTPUT_STREAM) {
 	if (current_FTD_filename) {
 		if (indoc_settings->format == HTML_FORMAT) @<Write the HTML footer for the formatted file@>;
 		Streams::close(&current_FTD_stream);
 		current_FTD_filename = NULL;
 	}
 	return NULL;
}

@ The HTML files are topped and tailed either using a template supplied, or
with a |<head>| we make ourselves.

@<Write the HTML header for the formatted file@> =
 	TEMPORARY_TEXT(top)
 	HTMLUtilities::get_tt_matter(top, 0, 1);
 	if (Str::len(top) > 0) {
 		match_results mr = Regexp::create_mr();
 		if (Regexp::match(&mr, top, L"(%c*?)<title>%c*?</title>(%c*)"))
 			WRITE("%S<title>Inform 7 - %S</title>%S", mr.exp[0], S->section_file_title, mr.exp[1]);
 		else
	 		WRITE("%S", top);
	 	Regexp::dispose_of(&mr);
 	} else {
 		HTMLUtilities::begin_file(OUT, V);
 		HTMLUtilities::write_title(OUT, S->section_file_title);
 		if (indoc_settings->javascript) {
 			HTML::open_javascript(OUT, FALSE);
 			HTMLUtilities::write_javascript_for_buttons(OUT);
 			HTML::close_javascript(OUT);
 		}
 		HTML::end_head(OUT);
 		HTML::begin_body(OUT, I"paper papertint");
 	}
 	if (indoc_settings->javascript) {
 		HTMLUtilities::paste_script(OUT, NULL, 0);
 		HTMLUtilities::create_script(OUT, NULL, 0, NULL);
 	}
  	DISCARD_TEXT(top)

@<Write the HTML footer for the formatted file@> =
 	TEMPORARY_TEXT(tail)
 	HTMLUtilities::get_tt_matter(tail, 0, 0);
 	if (Str::len(tail) > 0) { WRITE("%S", tail); }
 	else { HTML::end_body(OUT); }
  	DISCARD_TEXT(tail)
