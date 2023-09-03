[DocumentationRenderer::] Documentation Renderer.

To render a passage of extension documentation as HTML.

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
	inbuild_nest *N = Supervisor::internal();
	if (N) {
		pathname *LP = Pathnames::down(Nests::get_location(N), I"PLs");
		Languages::set_default_directory(LP);
	}
	if (cd) {
		text_stream *OUT = DocumentationRenderer::open_subpage(P, I"index.html");
		if (OUT) {
			markdown_item *md = NULL;
			if ((cd->markdown_content) && (cd->markdown_content->down) &&
				(cd->markdown_content->down->down) &&
				(cd->markdown_content->down->down->type == FILE_MIT)) {
				filename *F = Markdown::get_filename(cd->markdown_content->down->down);
				if (Str::eq(Filenames::get_leafname(F), I"index.html"))
					md = cd->markdown_content->down->down;
			}
			DocumentationRenderer::render_index_page(OUT, cd, md, extras);
			DocumentationRenderer::close_subpage();
		}
		for (markdown_item *vol = cd->markdown_content->down; vol; vol = vol->next) {
			text_stream *home_URL = DocumentationCompiler::home_URL_at_volume_item(vol);
			if (Str::ne(home_URL, I"index.html")) {
				text_stream *OUT = DocumentationRenderer::open_subpage(P, home_URL);
				if (OUT) {
					text_stream *volume_title = DocumentationCompiler::title_at_volume_item(cd, vol);
					DocumentationRenderer::render_header(OUT, cd->title, volume_title, cd->within_extension);
					HTML_OPEN("div");
					HTML_OPEN_WITH("p", "class=\"extensionsubheading\"");
					WRITE("contents");
					HTML_CLOSE("p");
					HTML_OPEN_WITH("ul", "class=\"extensioncontents\"");
					DocumentationRenderer::render_toc_r(OUT, vol, 0, FALSE);
					DocumentationRenderer::close_subpage();
					HTML_CLOSE("ul");
					HTML_CLOSE("div");
					if ((vol->down) && (vol->down->type == FILE_MIT)) {
						filename *F = Markdown::get_filename(vol->down);
						if (Str::eq(Filenames::get_leafname(F), home_URL)) {
							HTML_TAG("hr");
							HTML_OPEN_WITH("p", "class=\"extensionsubheading\"");
							WRITE("introduction");
							HTML_CLOSE("p");
							HTML_OPEN_WITH("div", "class=\"markdowncontent\"");
							Markdown::render_extended(OUT, vol->down, InformFlavouredMarkdown::variation());
							HTML_CLOSE("div");
						}
					}
				}
			}
			for (markdown_item *prev_md = NULL, *md = vol->down; md; prev_md = md, md = md->next)
				if (md->type == FILE_MIT) {
					filename *F = Markdown::get_filename(md);
					if (Str::ne(Filenames::get_leafname(F), home_URL)) {
						text_stream *OUT = DocumentationRenderer::open_subpage(P, Filenames::get_leafname(F));
						if (OUT) {
							DocumentationRenderer::render_chapter_page(OUT, cd, prev_md, md, md->next);
							DocumentationRenderer::close_subpage();
						}
					}
				}
		}
		IFM_example *egc;
		LOOP_OVER_LINKED_LIST(egc, IFM_example, cd->examples) {
			OUT = DocumentationRenderer::open_subpage(P, egc->URL);
			if (OUT) {
				DocumentationRenderer::render_example_page(OUT, cd, egc);
				DocumentationRenderer::close_subpage();
			}
		}
		cd_volume *primary = NULL;
		cd_volume *secondary = NULL;
		cd_volume *vol;
		LOOP_OVER_LINKED_LIST(vol, cd_volume, cd->volumes) {
			if (primary == NULL) primary = vol;
			else if (secondary == NULL) secondary = vol;
		}
		for (int ix=0; ix<NO_CD_INDEXES; ix++)
			if (cd->include_index[ix]) {
				text_stream *OUT = DocumentationRenderer::open_subpage(P, cd->index_URL_pattern[ix]);
				if (OUT) {
					DocumentationRenderer::render_header(OUT, cd->title, cd->index_title[ix], cd->within_extension);
					switch (ix) {
						case GENERAL_INDEX:
							Indexes::write_general_index(OUT, cd);
							break;
						case NUMERICAL_EG_INDEX:
							Indexes::render_eg_index(OUT, (primary)?(primary->volume_item):NULL);
							break;
						case THEMATIC_EG_INDEX:
							Indexes::render_eg_index(OUT, (secondary)?(secondary->volume_item):NULL);
							break;
						case ALPHABETICAL_EG_INDEX:
							Indexes::write_example_index(OUT, cd);
							break;
					}
					DocumentationRenderer::render_footer(OUT);
					DocumentationRenderer::close_subpage();
				}
			}
	}
}

@ =
void DocumentationRenderer::render_index_page(OUTPUT_STREAM, compiled_documentation *cd,
	markdown_item *md, text_stream *extras) {
	DocumentationRenderer::render_header(OUT, cd->title, NULL, cd->within_extension);
	if (cd->associated_extension) {
		DocumentationRenderer::render_extension_details(OUT, cd->associated_extension);
	}

	HTML_TAG("hr");
	if (DocumentationCompiler::scold(OUT, cd) == FALSE) {
		HTML_OPEN_WITH("p", "class=\"extensionsubheading\"");
		WRITE("documentation");
		HTML_CLOSE("p");
		if (cd->empty) {
			HTML_OPEN("p");
			InformFlavouredMarkdown::render_text(OUT, I"None is provided.");
			HTML_CLOSE("p");
		} else {
			if (LinkedLists::len(cd->volumes) == 1) {
				DocumentationRenderer::render_toc(OUT, cd);
			} else {
				HTML_OPEN("p");
				InformFlavouredMarkdown::render_text(OUT, I"The following manuals are provided:");
				HTML_CLOSE("p");
				HTML_OPEN("ul");
				cd_volume *vol;
				LOOP_OVER_LINKED_LIST(vol, cd_volume, cd->volumes) {
					HTML_OPEN_WITH("li", "class=\"exco1\"");
					HTML_OPEN_WITH("a", "style=\"text-decoration: none\" href=\"%S\"",
						vol->home_URL);
					InformFlavouredMarkdown::render_text(OUT, vol->title);
					HTML_CLOSE("a");
					HTML_CLOSE("li");
				}
				DocumentationRenderer::render_toc_indexes(OUT, cd);
				HTML_CLOSE("ul");
			}
			if (md) {
				HTML_TAG("hr");
				HTML_OPEN_WITH("p", "class=\"extensionsubheading\"");
				WRITE("introduction");
				HTML_CLOSE("p");
				HTML_OPEN_WITH("div", "class=\"markdowncontent\"");
				Markdown::render_extended(OUT, md, InformFlavouredMarkdown::variation());
				HTML_CLOSE("div");
			}
		}
		WRITE("%S", extras);
	}

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
void DocumentationRenderer::render_example_page(OUTPUT_STREAM, compiled_documentation *cd,
	IFM_example *egc) {
	TEMPORARY_TEXT(title)
	WRITE_TO(title, "Example %d", egc->number);
	DocumentationRenderer::render_header(OUT, cd->title, title, cd->within_extension);
	DISCARD_TEXT(title)
	DocumentationRenderer::render_example(OUT, cd, egc);
	DocumentationRenderer::render_footer(OUT);
}

void DocumentationRenderer::render_chapter_page(OUTPUT_STREAM, compiled_documentation *cd,
	markdown_item *prev_file, markdown_item *file_marker, markdown_item *next_file) {
	TEMPORARY_TEXT(title)
	DocumentationRenderer::file_title(title, file_marker);
	DocumentationRenderer::render_header(OUT, cd->title, title, cd->within_extension);
	DISCARD_TEXT(title)
	HTML_OPEN_WITH("div", "class=\"markdowncontent\"");
	Markdown::render_extended(OUT, file_marker, InformFlavouredMarkdown::variation());
	HTML_CLOSE("div");
	@<Enter the small print@>;
	if (prev_file) {
		WRITE(" &bull; ");
		HTML_OPEN_WITH("a", "href=\"%f\"", Markdown::get_filename(prev_file));
		DocumentationRenderer::file_title(OUT, prev_file);
		HTML_CLOSE("a");
	}
	if (next_file) {
		WRITE(" &bull; ");
		HTML_OPEN_WITH("a", "href=\"%f\"", Markdown::get_filename(next_file));
		DocumentationRenderer::file_title(OUT, next_file);
		HTML_CLOSE("a");
	}
	@<Exit the small print@>;
	DocumentationRenderer::render_footer(OUT);
}

void DocumentationRenderer::file_title(OUTPUT_STREAM, markdown_item *file_marker) {
	if ((file_marker->down) && (file_marker->down->type == HEADING_MIT))
		InformFlavouredMarkdown::render_text(OUT, file_marker->down->stashed);
	else
		WRITE("Preface");
}

@ Each of these pages is equipped with the same Javascript and CSS.

=
void DocumentationRenderer::render_header(OUTPUT_STREAM, text_stream *title, text_stream *ptitle,
	inform_extension *within) {
	InformPages::header(OUT, title, JAVASCRIPT_FOR_ONE_EXTENSION_IRES, NULL);
	ExtensionWebsite::add_home_breadcrumb(NULL);
	if (within) {
		ExtensionWebsite::add_breadcrumb(within->as_copy->edition->work->title,
			I"../index.html");
	}
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
		InformFlavouredMarkdown::render_text(OUT, E->rubric_as_lexed);
		HTML_CLOSE("p");
	}

	if (Str::len(E->extra_credit_as_lexed) > 0) {
		HTML_OPEN("p");
		HTML_OPEN("em");
		InformFlavouredMarkdown::render_text(OUT, E->extra_credit_as_lexed);
		HTML_CLOSE("em");
		HTML_CLOSE("p");
	}
	compatibility_specification *C = E->as_copy->edition->compatibility;
	if (Str::len(C->parsed_from) > 0) {
		HTML_OPEN_WITH("p", "class=\"extensionsubheading\"");
		WRITE("compatibility");
		HTML_CLOSE("p");
		HTML_OPEN("p");
		InformFlavouredMarkdown::render_text(OUT, C->parsed_from);
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
	int include_examples = TRUE;
	if (cd->include_index[NUMERICAL_EG_INDEX]) include_examples = FALSE;
	if (LinkedLists::len(cd->volumes) > 1) {
		for (markdown_item *vol = cd->markdown_content->down; vol; vol = vol->next) {
			HTML_OPEN_WITH("li", "class=\"exco0\"");
			HTML_OPEN("b");
			WRITE("%S", vol->stashed);
			HTML_CLOSE("b");
			HTML_OPEN_WITH("ul", "class=\"extensioncontents\"");
			DocumentationRenderer::render_toc_r(OUT, vol, 0, include_examples);
			HTML_CLOSE("ul");
			HTML_CLOSE("li");
		}
	} else {
		DocumentationRenderer::render_toc_r(OUT, cd->markdown_content, 0, include_examples);
	}
	
	DocumentationRenderer::render_toc_indexes(OUT, cd);

	HTML_CLOSE("ul");
	HTML_CLOSE("div");
}

void DocumentationRenderer::render_toc_indexes(OUTPUT_STREAM, compiled_documentation *cd) {
	for (int ix=0; ix<NO_CD_INDEXES; ix++)
		if (cd->include_index[ix]) {
			HTML_OPEN_WITH("li", "class=\"exco1\"");
			HTML_OPEN("b");
			HTML_OPEN_WITH("a", "style=\"text-decoration: none\" href=\"%S\"",
				cd->index_URL_pattern[ix]);
			WRITE("%S", cd->index_title[ix]);
			HTML_CLOSE("a");
			HTML_CLOSE("b");
			HTML_CLOSE("li");
		}
}

void DocumentationRenderer::link_to(OUTPUT_STREAM, markdown_item *md) {
	if (md->type != HEADING_MIT) internal_error("not a heading");
	text_stream *ch = MarkdownVariations::URL_for_heading(md);
	HTML_OPEN_WITH("a", "style=\"text-decoration: none\" href=%S", ch);
}

void DocumentationRenderer::render_toc_r(OUTPUT_STREAM, markdown_item *md, int L,
	int include_examples) {
	if ((md->type == HEADING_MIT) && (Markdown::get_heading_level(md) <= 2)) {
		if (L > 0) {
			HTML_OPEN_WITH("li", "class=\"exco%d\"", Markdown::get_heading_level(md));
			HTML::begin_span(OUT, I"indexblack");
			HTML_OPEN("b");
			DocumentationRenderer::link_to(OUT, md);
			for (markdown_item *ch = md->down; ch; ch = ch->next)
				Markdown::render_extended(OUT, ch, InformFlavouredMarkdown::variation());
			HTML_CLOSE("a");
			HTML_CLOSE("b");
			HTML::end_span(OUT);
			HTML_CLOSE("li");
			WRITE("\n");
		}
	}
	if ((md->type == INFORM_EXAMPLE_HEADING_MIT) && (include_examples)) {
		HTML_OPEN_WITH("li", "class=\"exco%d\"", L);
		IFM_example *E = RETRIEVE_POINTER_IFM_example(md->user_state);
		TEMPORARY_TEXT(link)
		WRITE_TO(link, "style=\"text-decoration: none\" href=\"%S#eg%S\"",
			E->URL, E->insignia);
		HTML::begin_span(OUT, I"indexblack");
		HTML_OPEN_WITH("a", "%S", link);
		WRITE("Example %S &mdash; ", E->insignia);
		InformFlavouredMarkdown::render_text(OUT, E->name);
		HTML_CLOSE("a");
		HTML::end_span(OUT);
		DISCARD_TEXT(link)
		HTML_CLOSE("li");
		WRITE("\n");
	}
	for (markdown_item *ch = md->down; ch; ch = ch->next)
		DocumentationRenderer::render_toc_r(OUT, ch, L+1, include_examples);
}

void DocumentationRenderer::render_example(OUTPUT_STREAM, compiled_documentation *cd,
	IFM_example *egc) {
	markdown_item *alt_EN = egc->header;
	if (alt_EN == NULL) {
		WRITE("Example %d is missing", egc->number);
	} else {
		IFM_example *E = RETRIEVE_POINTER_IFM_example(alt_EN->user_state);
		HTML_OPEN_WITH("div", "class=\"markdowncontent\"");
		InformFlavouredMarkdown::render_example_heading(OUT, E, TRUE);
		markdown_item *passage_node = alt_EN->down;
		while (passage_node) {
			Markdown::render_extended(OUT, passage_node,
				InformFlavouredMarkdown::variation());
			passage_node = passage_node->next;
		}
		HTML_CLOSE("div");
		@<Enter the small print@>;
		if (egc->cue) {
			WRITE("This example is drawn from ");
			DocumentationRenderer::link_to(OUT, egc->cue);
			Markdown::render_extended(OUT, egc->cue->down,
				InformFlavouredMarkdown::variation());
			HTML_CLOSE("a");
		}
		@<Exit the small print@>;
	}
}
