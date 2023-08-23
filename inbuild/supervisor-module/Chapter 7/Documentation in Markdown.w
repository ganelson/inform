[DocumentationInMarkdown::] Documentation in Markdown.

To provide a variation on Markdown for extension documentation.

@ Plain CommonMark would not give us the bells and whistles we want, and would
also allow rather more HTML liberty than is a good idea here. So:

@e INFORM_HEADINGS_MARKDOWNFEATURE
@e PASTE_ICONS_MARKDOWNFEATURE

@e INFORM_EXAMPLE_HEADING_MIT
@e INFORM_ERROR_MARKER_MIT

=
markdown_variation *extension_flavoured_Markdown = NULL;

markdown_variation *DocumentationInMarkdown::extension_flavoured_Markdown(void) {
	if (extension_flavoured_Markdown) return extension_flavoured_Markdown;
	extension_flavoured_Markdown = MarkdownVariations::new(I"Inform-flavoured Markdown");
	MarkdownVariations::remove_feature(extension_flavoured_Markdown, HTML_BLOCKS_MARKDOWNFEATURE);
	MarkdownVariations::remove_feature(extension_flavoured_Markdown, INLINE_HTML_MARKDOWNFEATURE);

	markdown_feature *Inform_headings = MarkdownVariations::new_feature(I"Inform_headings", INFORM_HEADINGS_MARKDOWNFEATURE);
	METHOD_ADD(Inform_headings, POST_PHASE_I_MARKDOWN_MTID, DocumentationInMarkdown::Inform_headings_intervene_after_Phase_I);
	MarkdownVariations::add_feature(extension_flavoured_Markdown, INFORM_HEADINGS_MARKDOWNFEATURE);

	markdown_feature *paste_icons = MarkdownVariations::new_feature(I"paste icons", PASTE_ICONS_MARKDOWNFEATURE);
	METHOD_ADD(paste_icons, RENDER_MARKDOWN_MTID, DocumentationInMarkdown::paste_icons_renderer);
	METHOD_ADD(paste_icons, POST_PHASE_I_MARKDOWN_MTID, DocumentationInMarkdown::paste_icons_intervene_after_Phase_I);
	MarkdownVariations::add_feature(extension_flavoured_Markdown, PASTE_ICONS_MARKDOWNFEATURE);

	Markdown::new_container_block_type(INFORM_EXAMPLE_HEADING_MIT, I"INFORM_EXAMPLE_HEADING");
	Markdown::new_leaf_block_type(INFORM_ERROR_MARKER_MIT, I"INFORM_ERROR_MARKER");

	return extension_flavoured_Markdown;
}

@ Markdown paragraphs which take the following shapes are to be headings:
= (text)
	Chapter: Survey and Prospecting
	Section: Black Gold
	Example: *** Gelignite Anderson - A Tale of the Texas Oilmen
=
where in each case the colon can equally be a hyphen, and with optional
space either side.

=
void DocumentationInMarkdown::Inform_headings_intervene_after_Phase_I(markdown_feature *feature,
	markdown_item *tree, md_links_dictionary *link_references) {
	int example_number = 0;
	DocumentationInMarkdown::Inform_headings_r(tree, &example_number);
	DocumentationInMarkdown::regroup_examples_r(tree, &example_number);
	int section_number = 0, chapter_number = 0;
	TEMPORARY_TEXT(latest)
	DocumentationInMarkdown::number_headings_r(tree, &section_number, &chapter_number, latest);
	DISCARD_TEXT(latest)
}

void DocumentationInMarkdown::Inform_headings_r(markdown_item *md, int *example_number) {
	if (md->type == PARAGRAPH_MIT) {
		text_stream *line = md->stashed;
		match_results mr = Regexp::create_mr();
		if ((Regexp::match(&mr, line, L"Section *: *(%c+?)")) ||
			(Regexp::match(&mr, line, L"Section *- *(%c+?)"))) {
			MDBlockParser::change_type(NULL, md, HEADING_MIT);
			Markdown::set_heading_level(md, 2);
			Str::clear(line);
			WRITE_TO(line, "%S", mr.exp[0]);
		} else if ((Regexp::match(&mr, line, L"Chapter *: *(%c+?)")) ||
			(Regexp::match(&mr, line, L"Chapter *- *(%c+?)"))) {
			MDBlockParser::change_type(NULL, md, HEADING_MIT);
			Markdown::set_heading_level(md, 1);
			Str::clear(line);
			WRITE_TO(line, "%S", mr.exp[0]);
		} else if ((Regexp::match(&mr, line, L"Example *: *(%**) *(%c+?)")) ||
			(Regexp::match(&mr, line, L"Example *- *(%**) *(%c+?)"))) {
			MDBlockParser::change_type(NULL, md, INFORM_EXAMPLE_HEADING_MIT);
			int star_count = Str::len(mr.exp[0]);
			cdoc_example *new_eg = DocumentationCompiler::new_example_alone(mr.exp[1], NULL,
				star_count, ++(*example_number));
			if (star_count == 0) {
				markdown_item *E = DocumentationInMarkdown::error_item(
					I"this example should be marked (before the title) '*', '**', '***' or '****' for difficulty");
				E->next = md->next; md->next = E;
			}
			if (star_count > 4) {
				markdown_item *E = DocumentationInMarkdown::error_item(
					I"four stars '****' is the maximum difficulty rating allowed");
				E->next = md->next; md->next = E;
			}
			md->user_state = STORE_POINTER_cdoc_example(new_eg);
		}
		Regexp::dispose_of(&mr);
	}
	for (markdown_item *ch = md->down; ch; ch=ch->next) {
		DocumentationInMarkdown::Inform_headings_r(ch, example_number);
	}
}

markdown_item *DocumentationInMarkdown::error_item(text_stream *text) {
	markdown_item *E = Markdown::new_item(INFORM_ERROR_MARKER_MIT);
	E->stashed = Str::duplicate(text);
	return E;
}

@ =
void DocumentationInMarkdown::regroup_examples_r(markdown_item *md, int *example_number) {
	if (md->type == INFORM_EXAMPLE_HEADING_MIT) {
		if (md->down == NULL) {
			markdown_item *run_from = md->next;
			if (run_from) {
				markdown_item *run_to = run_from, *prev = NULL;
				while (run_to) {
					if (run_to->type == INFORM_EXAMPLE_HEADING_MIT) break;
					if ((run_to->type == HEADING_MIT) && (Markdown::get_heading_level(run_to) <= 2)) break;
					prev = run_to;
					run_to = run_to->next;
				}
				if (prev) {
					md->down = run_from; md->next = run_to; prev->next = NULL;
				}
			}
		}
	}
	for (markdown_item *ch = md->down; ch; ch=ch->next) {
		DocumentationInMarkdown::regroup_examples_r(ch, example_number);
	}
}

@ =
void DocumentationInMarkdown::number_headings_r(markdown_item *md,
	int *section_number, int *chapter_number, text_stream *latest) {
	if (md->type == HEADING_MIT) {
		switch (Markdown::get_heading_level(md)) {
			case 1: {
				md->user_state = STORE_POINTER_text_stream(md->stashed);
				(*chapter_number)++;
				(*section_number) = 0;
				Str::clear(latest);
				WRITE_TO(latest, "Chapter %d: %S", *chapter_number, md->stashed);
				md->stashed = Str::duplicate(latest);
				text_stream *url = Str::new();
				WRITE_TO(url, "chapter%d.html", *chapter_number);
				md->user_state = STORE_POINTER_text_stream(url);
				break;
			}
			case 2: {
				md->user_state = STORE_POINTER_text_stream(md->stashed);
				(*section_number)++;
				Str::clear(latest);
				WRITE_TO(latest, "Section ");
				if (*chapter_number > 0) WRITE_TO(latest, "%d.", *chapter_number);
				WRITE_TO(latest, "%d: %S", *section_number, md->stashed);
				md->stashed = Str::duplicate(latest);
				text_stream *url = Str::new();
				if (*chapter_number > 0)
					WRITE_TO(url, "chapter%d.html", *chapter_number);
				WRITE_TO(url, "#section%d", *section_number);
				md->user_state = STORE_POINTER_text_stream(url);
				break;
			}
		}
	}
	for (markdown_item *ch = md->down; ch; ch=ch->next) {
		DocumentationInMarkdown::number_headings_r(ch, section_number, chapter_number, latest);
	}
}

void DocumentationInMarkdown::paste_icons_intervene_after_Phase_I(markdown_feature *feature,
	markdown_item *tree, md_links_dictionary *link_references) {
	DocumentationInMarkdown::paiapi_r(tree);
}

void DocumentationInMarkdown::paiapi_r(markdown_item *md) {
	markdown_item *current_sample = NULL;
	for (markdown_item *ch = md->down; ch; ch=ch->next) {
		if ((ch->type == CODE_BLOCK_MIT) && (Str::prefix_eq(ch->stashed, I"{*}", 3))) {
			ch->user_state = STORE_POINTER_markdown_item(ch);
			current_sample = ch;
			Str::delete_first_character(ch->stashed);
			Str::delete_first_character(ch->stashed);
			Str::delete_first_character(ch->stashed);
		} else if ((ch->type == CODE_BLOCK_MIT) &&
			(Str::prefix_eq(ch->stashed, I"{**}", 3)) && (current_sample)) {
			ch->user_state = STORE_POINTER_markdown_item(current_sample);
			Str::delete_first_character(ch->stashed);
			Str::delete_first_character(ch->stashed);
			Str::delete_first_character(ch->stashed);
			Str::delete_first_character(ch->stashed);
		}
		DocumentationInMarkdown::paiapi_r(ch);
		if (ch->type == CODE_BLOCK_MIT) {
			TEMPORARY_TEXT(detabbed)
			for (int i=0, margin=0; i<Str::len(ch->stashed); i++) {
				wchar_t c = Str::get_at(ch->stashed, i);
				if (c == '\t') {
					PUT_TO(detabbed, ' '); margin++;
					while (margin % 4 != 0) { PUT_TO(detabbed, ' '); margin++; }
				} else {
					PUT_TO(detabbed, c); margin++;
					if (c == '\n') margin = 0;
				}
			}
			Str::clear(ch->stashed);
			WRITE_TO(ch->stashed, "%S", detabbed);
			DISCARD_TEXT(detabbed);
		}
	}
}

int DocumentationInMarkdown::paste_icons_renderer(markdown_feature *feature, text_stream *OUT,
	markdown_item *md, int mode) {
	if (md->type == HEADING_MIT) {
		int L = Markdown::get_heading_level(md);
		switch (L) {
			case 1: HTML_OPEN("h2"); break;
			case 2: HTML_OPEN("h3"); break;
			case 3: HTML_OPEN("h4"); break;
			case 4: HTML_OPEN("h5"); break;
			default: HTML_OPEN("h6"); break;
		}
		TEMPORARY_TEXT(anchor)
		if (L <= 2) {
			text_stream *url = RETRIEVE_POINTER_text_stream(md->user_state);
			for (int i=0; i<Str::len(url); i++)
				if (Str::get_at(url, i) == '#')
					for (i++; i<Str::len(url); i++)
						PUT_TO(anchor, Str::get_at(url, i));
		}
		if (Str::len(anchor) > 0) {
			HTML_OPEN_WITH("span", "id=%S", anchor);
		} else {
			HTML_OPEN("span");
		}
		DISCARD_TEXT(anchor)
		Markdown::render_extended(OUT, md->down, DocumentationInMarkdown::extension_flavoured_Markdown());
		HTML_CLOSE("span");
		switch (L) {
			case 1: HTML_CLOSE("h2"); break;
			case 2: HTML_CLOSE("h3"); break;
			case 3: HTML_CLOSE("h4"); break;
			case 4: HTML_CLOSE("h5"); break;
			default: HTML_CLOSE("h6"); break;
		}
		return TRUE;
	}
	if (md->type == INFORM_EXAMPLE_HEADING_MIT) {
		cdoc_example *E = RETRIEVE_POINTER_cdoc_example(md->user_state);
		DocumentationInMarkdown::render_example_heading(OUT, E, NULL);
		return TRUE;
	}
	if (md->type == CODE_BLOCK_MIT) {
		DocumentationInMarkdown::render_code_block(OUT, md, mode);
		return TRUE;
	}
	if (md->type == INFORM_ERROR_MARKER_MIT) {
		HTML_OPEN_WITH("p", "class=\"documentationerrorbox\"");
		HTML::begin_span(OUT, I"documentationerror");
		WRITE("Error: %S", md->stashed);
		HTML_CLOSE("span");
		HTML_CLOSE("p");
		return TRUE;
	}
	return FALSE;
}

@ An example is set with a two-table header, and followed optionally by a
table of its inset copy, shaded to distinguish it from the rest of the
page. The heading is constructed with a main table of one row of two cells,
in the following section. The left-hand cell then contains a further table,
in the next section.

=
void DocumentationInMarkdown::render_example_heading(OUTPUT_STREAM, cdoc_example *E,
	markdown_item *passage_node) {
	TEMPORARY_TEXT(link)
	WRITE_TO(link, "style=\"text-decoration: none\" href=\"eg%d.html\"", E->number);

	HTML_TAG("hr"); /* rule a line before the example heading */
	HTML::begin_plain_html_table(OUT);
	HTML_OPEN("tr");

	/* Left hand cell: the oval icon */
	HTML_OPEN_WITH("td", "halign=\"left\" valign=\"top\" cellpadding=0 cellspacing=0 width=38px");
	HTML_OPEN_WITH("span", "id=eg%d", E->number); /* provide the anchor point */
	@<Typeset the lettered oval example icon@>;
	HTML_CLOSE("span"); /* end the textual link */
	HTML_CLOSE("td");

	/* Right hand cell: the asterisks and title, with rubric underneath */
	HTML_OPEN_WITH("td", "cellpadding=0 cellspacing=0 halign=\"left\" valign=\"top\"");

	if (passage_node == NULL) HTML_OPEN_WITH("a", "%S", link);
	for (int asterisk = 0; asterisk < E->star_count; asterisk++)
		PUT(0x2605); /* the Unicode for "black star" emoji */
	/* or 0x2B50 is the Unicode for "star" emoji */
	/* or again, could use the asterisk.png image in the app */
	WRITE("&nbsp; ");
	HTML_OPEN("b");
	HTML::begin_span(OUT, I"indexdarkgrey");
	WRITE("&nbsp;Example&nbsp;");
	HTML::end_span(OUT);
	HTML::begin_span(OUT, I"indexblack");
	DocumentationRenderer::render_text(OUT, E->name);
	HTML_TAG("br");
	DocumentationRenderer::render_text(OUT, E->description);
	HTML::end_span(OUT);
	HTML_CLOSE("b");

	if (passage_node == NULL) HTML_CLOSE("a"); /* Link does not cover body, only heading */

	if (passage_node) {
		while (passage_node) {
			Markdown::render_extended(OUT, passage_node,
				DocumentationInMarkdown::extension_flavoured_Markdown());
			passage_node = passage_node->next;
		}
	}

	HTML_CLOSE("td");
	HTML_CLOSE("tr");
	HTML::end_html_table(OUT);

	DISCARD_TEXT(link)
}

@ The little oval icon with its superimposed boldface letter is much harder to
get right on all browsers than it looks, and the following is the result of
some pretty grim experimentation. Basically, we make a tight, borderless,
one-cell-in-one-row table, use CSS to make a transparent PNG image of an oval
the background image for the table, then put a boldface letter in the centre
of its one and only cell. (Things were even worse when IE6 for Windows still
had its infamous PNG transparency bug.)

@<Typeset the lettered oval example icon@> =
	HTML::begin_plain_html_table(OUT);
	HTML_OPEN_WITH("tr", "class=\"oval\"");
	HTML_OPEN_WITH("td", "width=38px height=30px align=\"left\" valign=\"center\"");
	if (passage_node == NULL) HTML_OPEN_WITH("a", "%S", link);
	HTML_OPEN_WITH("div",
		"class=\"paragraph Body\" style=\"line-height: 1px; margin-bottom: 0px; "
		"margin-top: 0px; padding-bottom: 0pt; padding-top: 0px; text-align: center;\"");
	HTML::begin_span(OUT, I"extensionexampleletter");
	PUT(E->letter);
	HTML::end_span(OUT);
	HTML_CLOSE("div");
	if (passage_node == NULL) HTML_CLOSE("a");
	HTML_CLOSE("td");
	HTML_CLOSE("tr");
	HTML::end_html_table(OUT);

@ =
markdown_item *DocumentationInMarkdown::find_section(markdown_item *tree, text_stream *name) {
	if (Str::len(name) == 0) return NULL;
	markdown_item *result = NULL;
	DocumentationInMarkdown::find(tree, name, &result);
	return result;
}

void DocumentationInMarkdown::find(markdown_item *md, text_stream *name, markdown_item **result) {
	if (md->type == HEADING_MIT) {
		switch (Markdown::get_heading_level(md)) {
			case 1:
			case 2: {
				int i=0;
				for (; i<Str::len(md->stashed); i++)
					if (Str::get_at(md->stashed, i) == ':') { i+=2; break; }
				if (i + Str::len(name) == Str::len(md->stashed)) {
					int fail = FALSE;
					for (int j=0; j<Str::len(name); j++, i++)
						if (Str::get_at(name, j) != Str::get_at(md->stashed, i)) { fail = TRUE; break; }
					if ((fail == FALSE) && (*result == NULL)) *result = md;
				}
				break;
			}
		}
	}
	for (markdown_item *ch = md->down; ch; ch=ch->next) {
		DocumentationInMarkdown::find(ch, name, result);
	}
}

@ =
markdown_item *DocumentationInMarkdown::find_example(markdown_item *tree, int eg) {
	if (eg <= 0) return NULL;
	markdown_item *result = NULL;
	int counter = 0;
	DocumentationInMarkdown::find_e(tree, eg, &result, &counter);
	return result;
}

void DocumentationInMarkdown::find_e(markdown_item *md, int eg, markdown_item **result, int *counter) {
	if (md->type == INFORM_EXAMPLE_HEADING_MIT) {
		(*counter)++;
		if (*counter == eg) *result = md;
	}
	for (markdown_item *ch = md->down; ch; ch=ch->next) {
		DocumentationInMarkdown::find_e(ch, eg, result, counter);
	}
}

void DocumentationInMarkdown::render_code_block(OUTPUT_STREAM, markdown_item *md, int mode) {
	if ((Str::eq_insensitive(md->info_string, I"inform")) ||
		(Str::eq_insensitive(md->info_string, I"inform7")) ||
		(Str::len(md->info_string) == 0)) {
		@<Render as Inform 7 source text@>;
	} else {
		programming_language *pl = NULL;

		if (mode & TAGS_MDRMODE) HTML_OPEN("pre");
		TEMPORARY_TEXT(language)
		for (int i=0; i<Str::len(md->info_string); i++) {
			wchar_t c = Str::get_at(md->info_string, i);
			if ((c == ' ') || (c == '\t')) break;
			PUT_TO(language, c);
		}
		if (Str::len(language) > 0) {
			TEMPORARY_TEXT(language_rendered)
			md->sliced_from = language;
			md->from = 0; md->to = Str::len(language) - 1;
			MDRenderer::slice(language_rendered, md, mode | ENTITIES_MDRMODE);
			if (mode & TAGS_MDRMODE)
				HTML_OPEN_WITH("code", "class=\"language-%S\"", language_rendered);
			pl = DocumentationCompiler::get_language(language_rendered);
			if (pl == NULL) LOG("Unable to find language <%S>\n", language_rendered);
			DISCARD_TEXT(language_rendered)
		} else {
			if (mode & TAGS_MDRMODE) HTML_OPEN("code");
		}
		DISCARD_TEXT(language)

		Painter::reset_syntax_colouring(pl);
		TEMPORARY_TEXT(line)
		TEMPORARY_TEXT(line_colouring)
		for (int k=0; k<Str::len(md->stashed); k++) {
			if (Str::get_at(md->stashed, k) == '\n') {
				@<Render line as code@>;
				Str::clear(line);
				Str::clear(line_colouring);
			} else {
				PUT_TO(line, Str::get_at(md->stashed, k));
			}
			if ((k == Str::len(md->stashed) - 1) && (Str::len(line) > 0)) @<Render line as code@>;
		}
		HTML_CLOSE("span");
		DISCARD_TEXT(line)
		DISCARD_TEXT(line_colouring)
		if (mode & TAGS_MDRMODE) HTML_CLOSE("code");
		if (mode & TAGS_MDRMODE) HTML_CLOSE("pre");
	}
}

@<Render line as code@> =
	if (pl) Painter::syntax_colour(pl, NULL, line, line_colouring, FALSE);
	DocumentationInMarkdown::syntax_coloured_code(OUT, line, line_colouring,
		0, Str::len(line), mode);
	if (mode & TAGS_MDRMODE) WRITE("<br>"); else WRITE(" ");

@<Render as Inform 7 source text@> =
	HTML_OPEN("blockquote");
	if (GENERAL_POINTER_IS_NULL(md->user_state) == FALSE) {
		markdown_item *first = RETRIEVE_POINTER_markdown_item(md->user_state);
		TEMPORARY_TEXT(accumulated)
		for (markdown_item *ch = md; ch; ch = ch->next) {
			if (ch->type == CODE_BLOCK_MIT) {
				if (GENERAL_POINTER_IS_NULL(ch->user_state) == FALSE) {
					markdown_item *latest = RETRIEVE_POINTER_markdown_item(ch->user_state);
					if (first == latest) WRITE_TO(accumulated, "%S", ch->stashed);
				}
			}
		}
		ExtensionWebsite::paste_button(OUT, accumulated);
	}
	TEMPORARY_TEXT(colouring)
	programming_language *default_language = DocumentationCompiler::get_language(I"Inform");
	programming_language *pl = default_language;
	if (pl) {
		Painter::reset_syntax_colouring(pl);
		Painter::syntax_colour(pl, NULL, md->stashed, colouring, FALSE);
		if (Str::eq(pl->language_name, I"Inform")) {
			int ts = FALSE;
			for (int i=0; i<Str::len(colouring); i++) {
				if (Str::get_at(colouring, i) == STRING_COLOUR) {
					wchar_t c = Str::get_at(md->stashed, i);
					if (c == '[') ts = TRUE;
					if (ts) Str::put_at(colouring, i, EXTRACT_COLOUR);
					if (c == ']') ts = FALSE;
				} else ts = FALSE;
			}
		}
	}
	HTML::begin_span(OUT, I"indexdullblue");
	int tabulating = FALSE, tabular = FALSE, line_count = 0;
	TEMPORARY_TEXT(line)
	TEMPORARY_TEXT(line_colouring)
	for (int k=0; k<Str::len(md->stashed); k++) {
		if (Str::get_at(md->stashed, k) == '\n') {
			@<Render line@>;
			Str::clear(line);
			Str::clear(line_colouring);
		} else {
			PUT_TO(line, Str::get_at(md->stashed, k));
			PUT_TO(line_colouring, Str::get_at(colouring, k));
		}
		if (k == Str::len(md->stashed) - 1) @<Render line@>;
	}
	HTML_CLOSE("span");
	if (tabulating) @<End I7 table in extension documentation@>;
	HTML_CLOSE("blockquote");
	DISCARD_TEXT(line)
	DISCARD_TEXT(line_colouring)

@<Render line@> =
	line_count++;
	if (Str::is_whitespace(line)) tabular = FALSE;
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, line, L"Table %c*")) tabular = TRUE;
	Regexp::dispose_of(&mr);
	if (tabular) {
		if (tabulating) {
			@<Begin new row of I7 table in extension documentation@>;
		} else {
			@<Begin I7 table in extension documentation@>;
			tabulating = TRUE;
		}
		int cell_from = 0, cell_to = 0, i = 0;
		@<Begin table cell for I7 table in extension documentation@>;
		for (; i<Str::len(line); i++) {
			if (Str::get_at(line, i) == '\t') {
				@<End table cell for I7 table in extension documentation@>;
				while (Str::get_at(line, i) == '\t') i++;
				@<Begin table cell for I7 table in extension documentation@>;
				i--;
			} else {
				cell_to++;
			}
		}
		@<End table cell for I7 table in extension documentation@>;
		@<End row of I7 table in extension documentation@>;
	} else {
		if (line_count > 1) HTML_TAG("br");
		if (tabulating) {
			@<End I7 table in extension documentation@>;
			tabulating = FALSE;
		}
		int indentation = 1;
		int z=0, spaces = 0;
		for (; z<Str::len(line); z++)
			if (Str::get_at(line, z) == ' ') { spaces++; if (spaces == 4) { indentation++; spaces = 0; } }
			else if (Str::get_at(line, z) == '\t') { indentation++; spaces = 0; }
			else break;
		for (int n=0; n<indentation; n++) WRITE("&nbsp;&nbsp;&nbsp;&nbsp;");
		DocumentationInMarkdown::syntax_coloured_code(OUT, line, line_colouring,
			z, Str::len(line), mode);
	}
	WRITE("\n");

@ Unsurprisingly, I7 tables are set (after their titling lines) as HTML tables,
and this is fiddly but elementary in the usual way of HTML tables:

@<Begin I7 table in extension documentation@> =
	HTML::end_span(OUT);
	HTML_TAG("br");
	HTML::begin_plain_html_table(OUT);
	HTML::first_html_column(OUT, 0);

@<End table cell for I7 table in extension documentation@> =
	DocumentationInMarkdown::syntax_coloured_code(OUT, line, line_colouring,
		cell_from, cell_to, mode);
	HTML::end_span(OUT);
	HTML::next_html_column(OUT, 0);

@<Begin table cell for I7 table in extension documentation@> =
	cell_from = i; cell_to = cell_from;
	HTML::begin_span(OUT, I"indexdullblue");

@<Begin new row of I7 table in extension documentation@> =
	HTML::first_html_column(OUT, 0);

@<End row of I7 table in extension documentation@> =
	HTML::end_html_row(OUT);

@<End I7 table in extension documentation@> =
	HTML::end_html_table(OUT);
	HTML::begin_span(OUT, I"indexdullblue");

@ =
void DocumentationInMarkdown::syntax_coloured_code(OUTPUT_STREAM, text_stream *text,
	text_stream *colouring, int from, int to, int mode) {
	wchar_t current_col = 0;
	for (int i=from; i<to; i++) {
		wchar_t c = Str::get_at(text, i);
		wchar_t col = Str::get_at(colouring, i);
		if (col != current_col) {
			if (current_col) HTML_CLOSE("span");
			text_stream *span_class = NULL;
			switch (col) {
				case DEFINITION_COLOUR: span_class = I"syntaxdefinition"; break;
				case FUNCTION_COLOUR:   span_class = I"syntaxfunction"; break;
				case RESERVED_COLOUR:   span_class = I"syntaxreserved"; break;
				case ELEMENT_COLOUR:    span_class = I"syntaxelement"; break;
				case IDENTIFIER_COLOUR: span_class = I"syntaxidentifier"; break;
				case CHARACTER_COLOUR:  span_class = I"syntaxcharacter"; break;
				case CONSTANT_COLOUR:   span_class = I"syntaxconstant"; break;
				case STRING_COLOUR:     span_class = I"syntaxstring"; break;
				case PLAIN_COLOUR:      span_class = I"syntaxplain"; break;
				case EXTRACT_COLOUR:    span_class = I"syntaxextract"; break;
				case COMMENT_COLOUR:    span_class = I"syntaxcomment"; break;
			}
			HTML_OPEN_WITH("span", "class=\"%S\"", span_class);
			current_col = col;
		}
		MDRenderer::char(OUT, c, mode);
	}
	if (current_col) HTML_CLOSE("span");
}
