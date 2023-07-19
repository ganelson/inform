[DocumentationRenderer::] Documentation Renderer.

To render a passage of extension documentation as HTML.

@h Textual renderer.
This very cheap renderer can be used to debug trees for logging purposes:

=
void DocumentationRenderer::as_plain_text(text_stream *OUT, heterogeneous_tree *T) {
	WRITE("%S\n", T->type->name);
	WRITE("--------\n");
	INDENT;
	Trees::traverse_from(T->root, &DocumentationRenderer::textual_visit, (void *) DL, 0);
	OUTDENT;
	WRITE("--------\n");
}

int DocumentationRenderer::textual_visit(tree_node *N, void *state, int L) {
	text_stream *OUT = (text_stream *) state;
	for (int i=0; i<L; i++) WRITE("    ");
	if (N->type == heading_TNT) {
		cdoc_heading *H = RETRIEVE_POINTER_cdoc_heading(N->content);
		WRITE("Heading H%d level %d: '%S - %S'\n", H->ID, H->level, H->count, H->name);
	} else if (N->type == example_TNT) {
		cdoc_example *E = RETRIEVE_POINTER_cdoc_example(N->content);
		WRITE("Example %c: '%S' (%d star(s))\n", E->letter, E->name, E->star_count);
	} else if (N->type == phrase_defn_TNT) {
		cdoc_phrase_defn *E = RETRIEVE_POINTER_cdoc_phrase_defn(N->content);
		WRITE("Phrase definition (tag '%S') [ %S ]\n", E->tag, E->prototype);
	} else if (N->type == passage_TNT) {
		WRITE("Passage\n");
	} else if (N->type == paragraph_TNT) {
		cdoc_paragraph *E = RETRIEVE_POINTER_cdoc_paragraph(N->content);
		WRITE("Paragraph: %d chars\n", Str::len(E->content));
		for (int i=0; i<L+1; i++) { INDENT; }
		WRITE("%S\n", E->content);
		for (int i=0; i<L+1; i++) { OUTDENT; }
	} else if (N->type == code_sample_TNT) {
		WRITE("Code sample\n");
	} else if (N->type == code_line_TNT) {
		cdoc_code_line *E = RETRIEVE_POINTER_cdoc_code_line(N->content);
		WRITE("Code line: ");
		for (int i=0; i<E->indentation; i++) WRITE("    ");
		WRITE("%S\n", E->content);
	} else WRITE("Unknown node\n");
	return TRUE;
}

@h Website renderer.
We will make several HTML files, but only one at a time:

=
text_stream DOCF_struct;
text_stream *DOCF = NULL;

text_stream *DocumentationRenderer::open_subpage(pathname *P, text_stream *leaf) {
	if (P == NULL) return STDOUT;
	if (DOCF) internal_error("nested DC writes");
	filename *F = Filenames::in(P, leaf);
	SVEXPLAIN(2, "(writing documentation to file %f)\n", F);
	DOCF = &DOCF_struct;
	if (STREAM_OPEN_TO_FILE(DOCF, F, UTF8_ENC) == FALSE) {
		SVEXPLAIN(1, "(note: unable to write file %f)\n", F);
		DOCF = NULL;
		return NULL; /* if we lack permissions, e.g., then write no documentation */
	}
	return DOCF;
}

void DocumentationRenderer::close_subpage(void) {
	if (DOCF == NULL) internal_error("no DC page open");
	if (DOCF != STDOUT) STREAM_CLOSE(DOCF);
	DOCF = NULL;
}

@ Our tree is turned into a tiny website, with a single index page for everything
except the examples, and then up to 26 pages holding the content of examples A to Z.

=
void DocumentationRenderer::as_HTML(pathname *P, compiled_documentation *cd, text_stream *extras) {
	if (cd) {
		text_stream *OUT = DocumentationRenderer::open_subpage(P, I"index.html");
		if (OUT) {
			DocumentationRenderer::render_index_page(OUT, cd, extras);
			DocumentationRenderer::close_subpage();
		}
		for (int eg=1; eg<=cd->total_examples; eg++) {
			TEMPORARY_TEXT(leaf)
			WRITE_TO(leaf, "eg%d.html", eg);
			OUT = DocumentationRenderer::open_subpage(P, leaf);
			if (OUT) {
				DocumentationRenderer::render_example_page(OUT, cd, eg);
				DocumentationRenderer::close_subpage();
			}
			DISCARD_TEXT(leaf)
		}
		for (int ch=1; ch<=cd->total_headings[1]; ch++) {
			TEMPORARY_TEXT(leaf)
			WRITE_TO(leaf, "chapter%d.html", ch);
			OUT = DocumentationRenderer::open_subpage(P, leaf);
			if (OUT) {
				DocumentationRenderer::render_chapter_page(OUT, cd, ch);
				DocumentationRenderer::close_subpage();
			}
			DISCARD_TEXT(leaf)
		}
	}
}

@ =
void DocumentationRenderer::render_index_page(OUTPUT_STREAM, compiled_documentation *cd,
	text_stream *extras) {
	DocumentationRenderer::render_header(OUT, cd->title, NULL);
	if (cd->associated_extension) {
		DocumentationRenderer::render_extension_details(OUT, cd->associated_extension);
	}

	HTML_TAG("hr");
	if (cd->total_headings[1] > 0) { /* there are chapters */
		DocumentationRenderer::render_toc(OUT, cd);
		HTML_OPEN("em");
		DocumentationRenderer::render_text(OUT, I"Click on Chapter, Section or Example numbers to read");
		HTML_CLOSE("em");
		if (cd->tree->root->child->type == passage_TNT) {
			HTML_TAG("hr");
			HTML_OPEN_WITH("p", "class=\"extensionsubheading\"");
			WRITE("introduction");
			HTML_CLOSE("p");
			for (tree_node *C = cd->tree->root->child; C; C = C->next) {
				if (C->type == heading_TNT) {
					cdoc_heading *E = RETRIEVE_POINTER_cdoc_heading(C->content);
					if (E->level == 1) break;
				}
				DocumentationRenderer::render_body(OUT, cd, C);
			}
		}
	} else { /* there are only sections and examples, or not even that */
		HTML_OPEN_WITH("p", "class=\"extensionsubheading\"");
		WRITE("documentation");
		HTML_CLOSE("p");
		if (cd->empty) {
			HTML_OPEN("p");
			DocumentationRenderer::render_text(OUT, I"None is provided.");
			HTML_CLOSE("p");
		} else {
			DocumentationRenderer::render_body(OUT, cd, cd->tree->root);
		}
	}
	WRITE("%S", extras);

	@<Enter the small print@>;
	WRITE("These documentation pages are first generated when an extension is "
		"installed, and refreshed each time the project successfully translates.");
	@<Exit the small print@>;
	DocumentationRenderer::render_footer(OUT);
}

@<Enter the small print@> =
	HTML_TAG("hr")
	HTML_OPEN("p")
	HTML_OPEN("em");

@<Exit the small print@> =
	HTML_CLOSE("em");
	HTML_CLOSE("p");

@

=
void DocumentationRenderer::render_example_page(OUTPUT_STREAM, compiled_documentation *cd, int eg) {
	TEMPORARY_TEXT(title)
	WRITE_TO(title, "Example %c", 'A' + eg - 1);
	DocumentationRenderer::render_header(OUT, cd->title, title);
	DISCARD_TEXT(title)
	DocumentationRenderer::render_example(OUT, cd, eg);
	DocumentationRenderer::render_footer(OUT);
}

void DocumentationRenderer::render_chapter_page(OUTPUT_STREAM, compiled_documentation *cd, int ch) {
	TEMPORARY_TEXT(title)
	WRITE_TO(title, "Chapter %d", ch);
	DocumentationRenderer::render_header(OUT, cd->title, title);
	DISCARD_TEXT(title)
	DocumentationRenderer::render_chapter(OUT, cd, ch);
	@<Enter the small print@>;
	WRITE("This is Chapter %d of %d", ch, cd->total_headings[1]);
	if (ch > 1) {
		WRITE(" &bull; ");
		HTML_OPEN_WITH("a", "href=\"chapter%d.html\"", ch-1);
		WRITE("Chapter %d", ch-1);
		HTML_CLOSE("a");
	}
	if (ch < cd->total_headings[1]) {
		WRITE(" &bull; ");
		HTML_OPEN_WITH("a", "href=\"chapter%d.html\"", ch+1);
		WRITE("Chapter %d", ch+1);
		HTML_CLOSE("a");
	}
	@<Exit the small print@>;
	DocumentationRenderer::render_footer(OUT);
}

@ Each of these pages is equipped with the same Javascript and CSS.

=
void DocumentationRenderer::render_header(OUTPUT_STREAM, text_stream *title, text_stream *ptitle) {
	InformPages::header(OUT, title, JAVASCRIPT_FOR_ONE_EXTENSION_IRES, NULL);
	ExtensionWebsite::add_home_breadcrumb(NULL);
	ExtensionWebsite::add_breadcrumb(title, I"index.html");
	if (Str::len(ptitle) > 0) ExtensionWebsite::add_breadcrumb(ptitle, NULL);
	ExtensionWebsite::titling_and_navigation(OUT,
		I"Documentation provided by the extension author");
}

void DocumentationRenderer::render_footer(OUTPUT_STREAM) {
	InformPages::footer(OUT);
}

@ This function is the only one which assumes our documentation comes from an
extension.

=
void DocumentationRenderer::render_extension_details(OUTPUT_STREAM, inform_extension *E) {
	inbuild_edition *edition = E->as_copy->edition;
	inbuild_work *work = edition->work;

	HTML_OPEN_WITH("p", "class=\"extensionsubheading\"");
	WRITE("about this extension");
	HTML_CLOSE("p");
	
	HTML_OPEN("p");
	WRITE("This is ");
	Works::write_to_HTML_file(OUT, work, TRUE);
	semantic_version_number V = E->as_copy->edition->version;
	if (VersionNumbers::is_null(V)) WRITE(", which gives no version number");
	else WRITE(", version %v", &V);
	WRITE(".");
	HTML_CLOSE("p");

	if (Str::len(E->rubric_as_lexed) > 0) {
		HTML_OPEN("p");
		DocumentationRenderer::render_text(OUT, E->rubric_as_lexed);
		HTML_CLOSE("p");
	}

	if (Str::len(E->extra_credit_as_lexed) > 0) {
		HTML_OPEN("p");
		HTML_OPEN("em");
		DocumentationRenderer::render_text(OUT, E->extra_credit_as_lexed);
		HTML_CLOSE("em");
		HTML_CLOSE("p");
	}
	compatibility_specification *C = E->as_copy->edition->compatibility;
	if (Str::len(C->parsed_from) > 0) {
		HTML_OPEN_WITH("p", "class=\"extensionsubheading\"");
		WRITE("compatibility");
		HTML_CLOSE("p");
		HTML_OPEN("p");
		DocumentationRenderer::render_text(OUT, C->parsed_from);
		HTML_CLOSE("p");
	}
}

@ Now for the Table of Contents, which shows chapters, sections and examples
in a hierarchical fashion.

=
void DocumentationRenderer::render_toc(OUTPUT_STREAM, compiled_documentation *cd) {
	HTML_OPEN("div");
	HTML_OPEN_WITH("p", "class=\"extensionsubheading\"");
	WRITE("contents");
	HTML_CLOSE("p");
	HTML_OPEN_WITH("ul", "class=\"extensioncontents\"");
	Trees::traverse_from(cd->tree->root, &DocumentationRenderer::toc_visitor, (void *) OUT, 0);
	HTML_CLOSE("ul");
	HTML_CLOSE("div");
}

void DocumentationRenderer::link_to(OUTPUT_STREAM, cdoc_heading *H) {
	TEMPORARY_TEXT(ch)
	if (H->level == 1) {
		WRITE_TO(ch, "chapter%S.html", H->count);
	} else if (H->level == 2) {
		for (int i=0; i<Str::len(H->count); i++) {
			wchar_t c = Str::get_at(H->count, i);
			if (c == '.') {
				WRITE_TO(ch, "chapter");
				for (int j=0; j<i; j++)
					PUT_TO(ch, Str::get_at(H->count, j));
				WRITE_TO(ch, ".html");
				break;
			}
		}
		WRITE_TO(ch, "#section%d", H->ID);
	}
	HTML_OPEN_WITH("a", "style=\"text-decoration: none\" href=%S", ch);
	DISCARD_TEXT(ch)
}

int DocumentationRenderer::toc_visitor(tree_node *N, void *state, int L) {
	text_stream *OUT = (text_stream *) state;
	if (N->type == heading_TNT) {
		cdoc_heading *H = RETRIEVE_POINTER_cdoc_heading(N->content);
		if (L > 0) {
			HTML_OPEN_WITH("li", "class=\"exco%d\"", L);
			HTML::begin_span(OUT, I"indexblack");
			HTML_OPEN("b");
			DocumentationRenderer::link_to(OUT, H);
			if (H->level == 1) WRITE("Chapter %S: ", H->count);
			else WRITE("Section %S: ", H->count);
			HTML_CLOSE("a");
			HTML_CLOSE("b");
			HTML::end_span(OUT);
			DocumentationRenderer::render_text(OUT, H->name);
			HTML_CLOSE("li");
		}
	}
	if (N->type == example_TNT) {
		HTML_OPEN_WITH("li", "class=\"exco%d\"", L);
		cdoc_example *E = RETRIEVE_POINTER_cdoc_example(N->content);
		TEMPORARY_TEXT(link)
		WRITE_TO(link, "style=\"text-decoration: none\" href=\"eg%d.html#eg%d\"",
			E->number, E->number);
		HTML::begin_span(OUT, I"indexblack");
		HTML_OPEN_WITH("a", "%S", link);
		WRITE("Example %c &mdash; ", E->letter);
		DocumentationRenderer::render_text(OUT, E->name);
		HTML_CLOSE("a");
		HTML::end_span(OUT);
		DISCARD_TEXT(link)
		HTML_CLOSE("li");
	}
	return TRUE;
}

void DocumentationRenderer::render_body(OUTPUT_STREAM, compiled_documentation *cd,
	tree_node *from) {
	HTML_OPEN_WITH("div", "class=\"documentation\"");
	Trees::traverse_from(from, &DocumentationRenderer::body_visitor, (void *) OUT, 0);
	HTML_CLOSE("div");
}

void DocumentationRenderer::render_example(OUTPUT_STREAM, compiled_documentation *cd, int eg) {
	HTML_OPEN("div");
	tree_node *EN = DocumentationTree::find_example(cd->tree, eg);
	if (EN == NULL) {
		WRITE("Example %d is missing", eg);
	} else {
		DocumentationRenderer::render_example_heading(OUT, EN, EN->child);
	}
	HTML_CLOSE("div");
	@<Enter the small print@>;
	WRITE("This example is drawn from ");
	tree_node *H = EN->parent;
	if (H->type == heading_TNT) {
		cdoc_heading *E = RETRIEVE_POINTER_cdoc_heading(H->content);
		if (E->level == 1) {
			DocumentationRenderer::link_to(OUT, E);
			WRITE("Chapter %S", E->count);
			HTML_CLOSE("a");
		} else if (E->level == 2) {
			DocumentationRenderer::link_to(OUT, E);
			WRITE("Section %S", E->count);
			HTML_CLOSE("a");
		} else {
			HTML_OPEN_WITH("a", "href=\"index.html\"");
			WRITE("the introduction");
			HTML_CLOSE("a");
		}
	}
	@<Exit the small print@>;
}

void DocumentationRenderer::render_chapter(OUTPUT_STREAM, compiled_documentation *cd, int ch) {
	HTML_OPEN("div");
	tree_node *CN = DocumentationTree::find_chapter(cd->tree, ch);
	if (CN == NULL) {
		WRITE("Chapter %d is missing", ch);
	} else {
		DocumentationRenderer::render_body(OUT, cd, CN);
	}
	HTML_CLOSE("div");
}

int DocumentationRenderer::body_visitor(tree_node *N, void *state, int L) {
	text_stream *OUT = (text_stream *) state;
	if (N == NULL) return FALSE;
	if (N->type == heading_TNT) {
		cdoc_heading *H = RETRIEVE_POINTER_cdoc_heading(N->content);
		if (H->level > 0) @<Typeset the heading of this chapter or section@>;
	}
	if (N->type == example_TNT) {
		DocumentationRenderer::render_example_heading(OUT, N, NULL);
		return FALSE;
	}
	if (N->type == source_error_TNT) {
		cdoc_source_error *E = RETRIEVE_POINTER_cdoc_source_error(N->content);
		HTML_OPEN_WITH("p", "class=\"documentationerrorbox\"");
		HTML::begin_span(OUT, I"documentationerror");
		WRITE("Error: "); DocumentationRenderer::render_text(OUT, E->error_message);
		HTML_CLOSE("span");
		HTML_CLOSE("p");
		return TRUE;
	}
	if (N->type == phrase_defn_TNT) {
		HTML_OPEN_WITH("div", "class=\"definition\"");
		HTML_OPEN_WITH("p", "class=\"defnprototype\"");
		cdoc_phrase_defn *P = RETRIEVE_POINTER_cdoc_phrase_defn(N->content);
		HTML_OPEN("b");
		int bl = 0;
		for (int i=0; i<Str::len(P->prototype); i++) {
			wchar_t c = Str::get_at(P->prototype, i);
			if (c == '(') { bl++; if (bl == 1) HTML_CLOSE("b"); }
			PUT(c);
			if (c == ')') { bl--; if (bl == 0) HTML_OPEN("b"); }
		}
		if (bl <= 0) HTML_CLOSE("b");
		HTML_CLOSE("p");
		Trees::traverse_from(N->child, &DocumentationRenderer::body_visitor, state, L);
		HTML_CLOSE("div");
		return FALSE;
	}
	if (N->type == paragraph_TNT) {
		cdoc_paragraph *P = RETRIEVE_POINTER_cdoc_paragraph(N->content);
		HTML_OPEN("p");
		DocumentationRenderer::render_text(OUT, P->content);
		HTML_CLOSE("p");
	}
	if (N->type == code_sample_TNT) {
		cdoc_code_sample *S = RETRIEVE_POINTER_cdoc_code_sample(N->content);
		HTML_OPEN("blockquote");
		if (S->with_paste_marker) @<Render the paste icon@>;
		@<Render the body of the code sample@>;
		HTML_CLOSE("blockquote");
		return FALSE;
	}
	return TRUE;
}

@<Typeset the heading of this chapter or section@> =
	HTML_TAG("hr");
	if (H->level == 1) {
		HTML_OPEN("h2");
		HTML::begin_span(OUT, I"indexdullred");
	}
	if (H->level == 2) {
		HTML_OPEN("h3");
		HTML_OPEN("span");
	}
	HTML_OPEN_WITH("span", "id=docsec%d", H->ID);
	if (H->level == 1) WRITE("Chapter %S: ", H->count);
	else WRITE("Section %S: ", H->count);
	DocumentationRenderer::render_text(OUT, H->name);
	HTML_CLOSE("span");
	HTML_CLOSE("span");
	if (H->level == 1) HTML_CLOSE("h2");
	if (H->level == 2) HTML_CLOSE("h3");

@<Render the paste icon@> =
	TEMPORARY_TEXT(matter)
	for (tree_node *M = N; M; ) {
		if (M->type == code_sample_TNT) {
			cdoc_code_sample *S = RETRIEVE_POINTER_cdoc_code_sample(M->content);
			for (tree_node *C = M->child; C; C = C->next) {
				cdoc_code_line *L = RETRIEVE_POINTER_cdoc_code_line(C->content);
				for (int i=0; i<L->indentation; i++) WRITE_TO(matter, "\t");
				DocumentationRenderer::render_text(matter, L->content);
				if (C->next) WRITE_TO(matter, "\n");
			}
			M = S->continuation;
			if (M) WRITE_TO(matter, "\n\n");
		} else break;
	}
	TEMPORARY_TEXT(paste)
	WRITE_TO(paste, "<span class=\"paste\">%cV</span>", 0x2318);
	/* the Unicode for "place of interest", the Swedish castle which became the Apple action symbol */
	PasteButtons::paste_text_using(OUT, matter, paste);
	DISCARD_TEXT(paste)
	WRITE("&nbsp;");
	DISCARD_TEXT(matter)

@<Render the body of the code sample@> =
	programming_language *pl = S->language;
	if (pl) {
		Painter::reset_syntax_colouring(pl);
		for (tree_node *C = N->child; C; C = C->next) {
			cdoc_code_line *L = RETRIEVE_POINTER_cdoc_code_line(C->content);
			Painter::syntax_colour(pl, NULL, L->content, L->colouring, FALSE);
		}
		if (Str::eq(pl->language_name, I"Inform")) {
			int ts = FALSE;
			for (tree_node *C = N->child; C; C = C->next) {
				cdoc_code_line *L = RETRIEVE_POINTER_cdoc_code_line(C->content);
				for (int i=0; i<Str::len(L->colouring); i++) {
					if (Str::get_at(L->colouring, i) == STRING_COLOUR) {
						wchar_t c = Str::get_at(L->content, i);
						if (c == '[') ts = TRUE;
						if (ts) Str::put_at(L->colouring, i, EXTRACT_COLOUR);
						if (c == ']') ts = FALSE;
					} else ts = FALSE;
				}
			}
		}
	}
	HTML::begin_span(OUT, I"indexdullblue");
	int tabulating = FALSE;
	for (tree_node *C = N->child; C; C = C->next) {
		cdoc_code_line *L = RETRIEVE_POINTER_cdoc_code_line(C->content);
		if (L->tabular) {
			if (tabulating) {
				@<Begin new row of I7 table in extension documentation@>;
			} else {
				@<Begin I7 table in extension documentation@>;
				tabulating = TRUE;
			}
			int cell_from = 0, cell_to = 0, i = 0;
			@<Begin table cell for I7 table in extension documentation@>;
			for (; i<Str::len(L->content); i++) {
				if (Str::get_at(L->content, i) == '\t') {
					@<End table cell for I7 table in extension documentation@>;
					while (Str::get_at(L->content, i) == '\t') i++;
					@<Begin table cell for I7 table in extension documentation@>;
					i--;
				} else {
					cell_to++;
				}
			}
			@<End table cell for I7 table in extension documentation@>;
			@<End row of I7 table in extension documentation@>;
		} else {
			if (tabulating) {
				@<End I7 table in extension documentation@>;
				tabulating = FALSE;
			}
			for (int i=0; i<L->indentation; i++) WRITE("&nbsp;&nbsp;&nbsp;&nbsp;");
			DocumentationRenderer::syntax_coloured_code(OUT, L->content, L->colouring,
				0, Str::len(L->content));
			if ((C->next) && (RETRIEVE_POINTER_cdoc_code_line(C->next->content)->tabular == FALSE)) HTML_TAG("br");
		}
		WRITE("\n");
	}
	if (tabulating) @<End I7 table in extension documentation@>;
	HTML_CLOSE("span");

@ Unsurprisingly, I7 tables are set (after their titling lines) as HTML tables,
and this is fiddly but elementary in the usual way of HTML tables:

@<Begin I7 table in extension documentation@> =
	HTML::end_span(OUT);
	HTML_TAG("br");
	HTML::begin_plain_html_table(OUT);
	HTML::first_html_column(OUT, 0);

@<End table cell for I7 table in extension documentation@> =
	DocumentationRenderer::syntax_coloured_code(OUT, L->content, L->colouring,
		cell_from, cell_to);
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
	HTML::end_html_row(OUT);
	HTML::end_html_table(OUT);
	HTML::begin_span(OUT, I"indexdullblue");

@ An example is set with a two-table header, and followed optionally by a
table of its inset copy, shaded to distinguish it from the rest of the
page. The heading is constructed with a main table of one row of two cells,
in the following section. The left-hand cell then contains a further table,
in the next section.

=
void DocumentationRenderer::render_example_heading(OUTPUT_STREAM, tree_node *EN,
	tree_node *passage_node) {
	cdoc_example *E = RETRIEVE_POINTER_cdoc_example(EN->content);
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
	HTML::end_span(OUT);
	HTML_CLOSE("b");

	if (passage_node == NULL) HTML_CLOSE("a"); /* Link does not cover body, only heading */

	if (passage_node)
		Trees::traverse_from(passage_node, &DocumentationRenderer::body_visitor, (void *) OUT, 0);

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

@

=
void DocumentationRenderer::render_text(OUTPUT_STREAM, text_stream *text) {
	WRITE("%S", text);
}

void DocumentationRenderer::syntax_coloured_code(OUTPUT_STREAM, text_stream *text,
	text_stream *colouring, int from, int to) {
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
		PUT(c);
	}
	if (current_col) HTML_CLOSE("span");
}
