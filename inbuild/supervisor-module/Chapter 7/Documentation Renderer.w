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

@

=
typedef struct cd_manifest_item {
	struct filename *source;
	struct text_stream *label;
	struct text_stream *title;
	CLASS_DEFINITION
} cd_manifest_item;

@ Our tree is turned into a tiny website, with a single index page for everything
except the examples, and then up to 26 pages holding the content of examples A to Z.

=
void DocumentationRenderer::as_HTML(pathname *P, compiled_documentation *cd,
	text_stream *extras, inform_project *proj) {
	inbuild_nest *N = Supervisor::internal();
	if (N) {
		pathname *LP = Pathnames::down(Nests::get_location(N), I"PLs");
		Languages::set_default_directory(LP);
	}
	if (cd) {
		DocumentationCompiler::watch_image_use(cd);
		text_stream *OUT = DocumentationRenderer::open_subpage(P, cd->contents_URL_pattern);
		if (OUT) {
			markdown_item *md = NULL;
			if ((cd->markdown_content) && (cd->markdown_content->down) &&
				(cd->markdown_content->down->down) &&
				(cd->markdown_content->down->down->type == FILE_MIT)) {
				filename *F = Markdown::get_filename(cd->markdown_content->down->down);
				if (Str::eq(Filenames::get_leafname(F), cd->contents_URL_pattern))
					md = cd->markdown_content->down->down;
			}
			if (cd->duplex_contents_page) {
				InformPages::header(OUT, I"Contents", JAVASCRIPT_FOR_STANDARD_PAGES_IRES, NULL);
				if (DocumentationCompiler::scold(OUT, cd) == FALSE)
					Manuals::duplex_contents_page(OUT, cd);
			} else {
				DocumentationRenderer::render_index_page(OUT, cd, md, extras, proj);
			}
			DocumentationRenderer::close_subpage();
		}
		linked_list *manifest = NEW_LINKED_LIST(cd_manifest_item);
		int vcount = 0;
		for (markdown_item *vol = cd->markdown_content->down; vol; vol = vol->next) {
			vcount++;
			text_stream *home_URL = DocumentationCompiler::home_URL_at_volume_item(vol);
			if (Str::ne(home_URL, cd->contents_URL_pattern)) {
				text_stream *OUT = DocumentationRenderer::open_subpage(P, home_URL);
				if (OUT) {
					text_stream *volume_title = DocumentationCompiler::title_at_volume_item(cd, vol);
					DocumentationRenderer::render_header(OUT, cd->title, volume_title, cd->within_extension);
					HTML_OPEN("div");
					HTML_OPEN_WITH("p", "class=\"extensionsubheading\"");
					WRITE("contents");
					HTML_CLOSE("p");
					HTML_OPEN_WITH("ul", "class=\"extensioncontents\"");
					DocumentationRenderer::render_toc_from(OUT, vol, FALSE);
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
							DocumentationRenderer::render_extended(OUT, cd, vol->down);
							HTML_CLOSE("div");
						}
					}
				}
			}
			for (markdown_item *prev_md = NULL, *md = vol->down; md; prev_md = md, md = md->next)
				if (md->type == FILE_MIT) {
					filename *F = Markdown::get_filename(md);
					if (Str::ne(Filenames::get_leafname(F), home_URL)) {
						cd_manifest_item *item = CREATE(cd_manifest_item);
						item->source = F;
						item->label = I"-";
						item->title = I"-";
						if ((md->down) && (md->down->type == HEADING_MIT))
							item->title = Str::duplicate(md->down->stashed);
						match_results mr = Regexp::create_mr();
						if ((Regexp::match(&mr, item->title, U"Chapter (%C+):%c*")) ||
							(Regexp::match(&mr, item->title, U"Section (%C+):%c*"))) { 
							item->label = Str::duplicate(mr.exp[0]);
						}
						Regexp::dispose_of(&mr);
						ADD_TO_LINKED_LIST(item, cd_manifest_item, manifest);
						text_stream *OUT = DocumentationRenderer::open_subpage(P, Filenames::get_leafname(F));
						if (OUT) {
							DocumentationRenderer::render_chapter_page(OUT, cd, prev_md, md, md->next, vcount);
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
					if (cd->duplex_contents_page) {
						InformPages::header(OUT, I"Contents", JAVASCRIPT_FOR_STANDARD_PAGES_IRES, NULL);
						Manuals::midnight_banner_for_indexes(OUT, cd, cd->index_title[ix]);
					} else {
						DocumentationRenderer::render_header(OUT, cd->title, cd->index_title[ix], cd->within_extension);
					}
					switch (ix) {
						case GENERAL_INDEX:
							Indexes::write_general_index(OUT, cd);
							break;
						case NUMERICAL_EG_INDEX:
							DocumentationRenderer::render_eg_index(OUT, (primary)?(primary->volume_item):NULL);
							break;
						case THEMATIC_EG_INDEX:
							DocumentationRenderer::render_eg_index(OUT, (secondary)?(secondary->volume_item):NULL);
							break;
						case ALPHABETICAL_EG_INDEX:
							Indexes::write_example_index(OUT, cd);
							break;
					}
					DocumentationRenderer::render_footer(OUT);
					DocumentationRenderer::close_subpage();
				}
			}
		if (Str::len(cd->xrefs_file_pattern) > 0) {
			filename *XF = Filenames::in(P, cd->xrefs_file_pattern);
			text_stream XR_struct;
			text_stream *XR = &XR_struct;
			if (STREAM_OPEN_TO_FILE(XR, XF, UTF8_ENC)) {
				markdown_item *latest_file = NULL;
				DocumentationRenderer::list_tags(XR, cd->markdown_content, &latest_file);
				STREAM_CLOSE(XR);
			}
		}
		if (Str::len(cd->manifest_file_pattern) > 0) {
			filename *MF = Filenames::in(P, cd->manifest_file_pattern);
			text_stream M_struct;
			text_stream *M = &M_struct;
			if (STREAM_OPEN_TO_FILE(M, MF, UTF8_ENC)) {
				cd_manifest_item *item;
				LOOP_OVER_LINKED_LIST(item, cd_manifest_item, manifest)
					WRITE_TO(M, "%f: %S  %S\n", item->source, item->label, item->title);
				STREAM_CLOSE(M);
			}
		}
		cd_image *cdim;
		LOOP_OVER_LINKED_LIST(cdim, cd_image, cd->images)
			if (cdim->used) {
				pathname *Q = P;
				if (Str::len(cdim->prefix) > 0) Q = Pathnames::down(Q, cdim->prefix);
				Pathnames::create_in_file_system(Q);
				filename *T = Filenames::in(Q, cdim->final_leafname);
				BinaryFiles::copy(cdim->source, T, TRUE);
			}
	}
}

@

=
void DocumentationRenderer::render_eg_index(OUTPUT_STREAM, markdown_item *md) {
	markdown_item *pending_chapter = NULL, *pending_section = NULL;
	if (md) DocumentationRenderer::render_eg_index_r(OUT, md, &pending_chapter, &pending_section);
}

void DocumentationRenderer::render_eg_index_r(OUTPUT_STREAM, markdown_item *md,
	markdown_item **pending_chapter, markdown_item **pending_section) {
	if ((md->type == HEADING_MIT) && (Markdown::get_heading_level(md) == 1)) {
		*pending_chapter = md;
		*pending_section = NULL;
	}
	if ((md->type == HEADING_MIT) && (Markdown::get_heading_level(md) == 2)) {
		*pending_section = md;
	}
	if (md->type == INFORM_EXAMPLE_HEADING_MIT) {
		if (*pending_chapter) {
			Markdown::render_extended(OUT, *pending_chapter, InformFlavouredMarkdown::variation());
			*pending_chapter = NULL;
		}
		if (*pending_section) {
			Markdown::render_extended(OUT, *pending_section, InformFlavouredMarkdown::variation());
			*pending_section = NULL;
		}
		Markdown::render_extended(OUT, md, InformFlavouredMarkdown::variation());
	}
	for (markdown_item *ch = md->down; ch; ch = ch->next)
		DocumentationRenderer::render_eg_index_r(OUT, ch, pending_chapter, pending_section);
}

@ =
void DocumentationRenderer::list_tags(OUTPUT_STREAM, markdown_item *md,
	markdown_item **latest_file) {
	if (md->type == FILE_MIT) *latest_file = md;
	if ((md->type == HEADING_MIT) && (Markdown::get_heading_level(md) == 2)) {
		TEMPORARY_TEXT(sname)
		WRITE_TO(sname, "%S", md->stashed);
		if (Str::begins_with(sname, I"Section ")) Str::delete_n_characters(sname, 8);
		int N = DocumentationRenderer::list_actual_tags(OUT, md->down, 1);
		N += DocumentationRenderer::list_actual_tags(OUT, md->down, 2);
		if (N > 0) {
			WRITE("_ ");
			filename *F = Markdown::get_filename(*latest_file);
			Filenames::write_unextended_leafname(OUT, F);
			WRITE(" \"");
			for (int i=0; i<Str::len(sname); i++) {
				inchar32_t c = Str::get_at(sname, i);
				if (c == ':') break;
				PUT(c);
			}
			WRITE("\" \"");
			for (int i=0, colon_count=0; i<Str::len(sname); i++) {
				inchar32_t c = Str::get_at(sname, i);
				if ((c == ':') && (colon_count++ == 0)) { PUT('.'); }
				else { PUT(c); }
			}
			WRITE("\"\n");
		}
	}
	for (markdown_item *ch = md->down; ch; ch = ch->next)
		DocumentationRenderer::list_tags(OUT, ch, latest_file);
}

int DocumentationRenderer::list_actual_tags(OUTPUT_STREAM, markdown_item *md, int pass) {
	int t = 0;
	for (; md; md = md->next) {
		if (md->type == HEADING_MARKER_MIT) {
			int phrasal = FALSE;
			if ((Str::begins_with(md->stashed, I"ph_")) || (Str::begins_with(md->stashed, I"phs_")))
				phrasal = TRUE;
			if (((pass == 1) && (phrasal == FALSE)) ||
				((pass == 2) && (phrasal == TRUE))) {
				t++;
				WRITE("%S ", md->stashed);
			}
		}
		if (md->down) t += DocumentationRenderer::list_actual_tags(OUT, md->down, pass);
	}
	return t;
}

void DocumentationRenderer::render_index_page(OUTPUT_STREAM, compiled_documentation *cd,
	markdown_item *md, text_stream *extras, inform_project *proj) {
	DocumentationRenderer::render_header(OUT, cd->title, NULL, cd->within_extension);
	if (cd->associated_extension) {
		DocumentationRenderer::render_extension_details(OUT, cd, cd->associated_extension, proj);
		HTML_TAG("hr");
	}

	if (DocumentationCompiler::scold(OUT, cd) == FALSE) {
		if (cd->empty) {
			HTML_OPEN("p");
			InformFlavouredMarkdown::render_text(OUT, I"No documentation is provided.");
			HTML_CLOSE("p");
		} else {
			if (LinkedLists::len(cd->volumes) == 1) {
				if (DocumentationRenderer::lowest_h(cd->markdown_content) <= 2) {
					DocumentationRenderer::render_toc(OUT, cd);
					HTML_TAG("hr");
				}
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
				HTML_TAG("hr");
			}

			if (md) {
				HTML_OPEN_WITH("div", "class=\"markdowncontent\"");
				HTML_OPEN("h3");
				WRITE("Documentation");
				HTML_CLOSE("h3");
				DocumentationRenderer::render_extended(OUT, cd, md);
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
	WRITE_TO(title, "Example %S", egc->insignia);
	if ((cd->associated_extension) || (cd->within_extension))
		DocumentationRenderer::render_header(OUT, cd->title, title, cd->within_extension);
	else
		InformPages::header(OUT, title, JAVASCRIPT_FOR_ONE_EXTENSION_IRES, NULL);
	DISCARD_TEXT(title)
	DocumentationRenderer::render_example(OUT, cd, egc);
	DocumentationRenderer::render_footer(OUT);
}

void DocumentationRenderer::render_chapter_page(OUTPUT_STREAM, compiled_documentation *cd,
	markdown_item *prev_file, markdown_item *file_marker, markdown_item *next_file,
	int vcount) {
	TEMPORARY_TEXT(title)
	DocumentationRenderer::file_title(title, file_marker);
	if (cd->duplex_contents_page) {
		InformPages::header(OUT, title, JAVASCRIPT_FOR_ONE_EXTENSION_IRES, NULL);
		Manuals::midnight_section_title(OUT, cd, Markdown::get_filename(prev_file),
			title, Markdown::get_filename(next_file));
		if (vcount == 1) {
			HTML_OPEN_WITH("div", "class=\"duplexleftpage\"");
		} else {
			HTML_OPEN_WITH("div", "class=\"duplexrightpage\"");
		}
	} else {
		DocumentationRenderer::render_header(OUT, cd->title, title, cd->within_extension);
	}
	DISCARD_TEXT(title)
	HTML_OPEN_WITH("div", "class=\"markdowncontent\"");
	DocumentationRenderer::render_extended(OUT, cd, file_marker);
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
	if (cd->duplex_contents_page) {
		HTML_CLOSE("div");
	}
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
void DocumentationRenderer::render_extension_details(OUTPUT_STREAM,
	compiled_documentation *cd, inform_extension *E, inform_project *proj) {
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

	if (Str::len(E->extra_credit_as_lexed) > 0) {
		WRITE(" &quot;");
		InformFlavouredMarkdown::render_text(OUT, E->extra_credit_as_lexed);
		WRITE(" &quot;");
	}

	if (Str::len(E->rubric_as_lexed) > 0) {
		WRITE(" The author gives this summary description:");
	}
	HTML_CLOSE("p");

	if (Str::len(E->rubric_as_lexed) > 0) {
		HTML_OPEN("blockquote");
		HTML_OPEN("em");
		InformFlavouredMarkdown::render_text(OUT, E->rubric_as_lexed);
		HTML_CLOSE("em");
		HTML_CLOSE("blockquote");
	}

	HTML_OPEN("p");
	WRITE("This page is for Inform authors wanting to use the extension.");
	if (cd->compiled_from_extension_scrap == FALSE) {
		WRITE(" If you want to maintain or modify it, you can also ");
		HTML_OPEN_WITH("a", "href=\"metadata.html\" class=\"registrycontentslink\"");
		WRITE("see technical metadata in JSON format");
		HTML_CLOSE("a");
		if ((proj) && (LinkedLists::len(cd->cases) > 0)) {
			WRITE(", or ");
			HTML_OPEN_WITH("a", "href=\"testing.html\" class=\"registrycontentslink\"");
			WRITE("run its %d test case(s)", LinkedLists::len(cd->cases));
			HTML_CLOSE("a");
		}

		int kc = 0;
		linked_list *L = NEW_LINKED_LIST(inbuild_nest);
		inbuild_nest *N = Extensions::materials_nest(E);
		ADD_TO_LINKED_LIST(N, inbuild_nest, L);
		inbuild_requirement *req;
		LOOP_OVER_LINKED_LIST(req, inbuild_requirement, E->kits) {
			inform_kit *K = Kits::find_by_name(req->work->raw_title, L, NULL);
			if (K) {
				if (kc++ == 0) WRITE(", or look at the Inter code it contains, in ");
				else WRITE(" or ");
				HTML_OPEN_WITH("a", "href=\"%S/index.html\" class=\"registrycontentslink\"",
					K->as_copy->edition->work->title);
				WRITE("%S", K->as_copy->edition->work->title);
				HTML_CLOSE("a");
			}
		}
		WRITE(".");
	}
	HTML_CLOSE("p");

	compatibility_specification *C = E->as_copy->edition->compatibility;
	if (Str::len(C->parsed_from) > 0) {
		HTML_OPEN_WITH("p", "class=\"extensionsubheading\"");
		WRITE("compatibility");
		HTML_CLOSE("p");
		HTML_OPEN("p");
		WRITE("The extension says that it is &quot;");
		TEMPORARY_TEXT(proviso)
		WRITE_TO(proviso, "%S", C->parsed_from);
		if ((Str::get_first_char(proviso) == '(') &&
			(Str::get_last_char(proviso) == ')')) {
			Str::delete_first_character(proviso);
			Str::delete_last_character(proviso);
		}
		InformFlavouredMarkdown::render_text(OUT, proviso);
		DISCARD_TEXT(proviso)
		WRITE("&quot;. It can be used only if the choices you made on the Settings ");
		WRITE("panel for your project match this.");
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
			DocumentationRenderer::render_toc_from(OUT, vol, include_examples);
			HTML_CLOSE("ul");
			HTML_CLOSE("li");
		}
	} else {
		DocumentationRenderer::render_toc_from(OUT, cd->markdown_content, include_examples);
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

int DocumentationRenderer::lowest_h(markdown_item *md) {
	int L = 10;
	if (md->type == HEADING_MIT) L = Markdown::get_heading_level(md);
	for (markdown_item *ch = md->down; ch; ch = ch->next)
		if (DocumentationRenderer::lowest_h(ch) < L)
			L = DocumentationRenderer::lowest_h(ch);
	return L;
}

void DocumentationRenderer::render_toc_from(OUTPUT_STREAM, markdown_item *md,
	int include_examples) {
	int min_L = DocumentationRenderer::lowest_h(md);
	DocumentationRenderer::render_toc_r(OUT, md, 0, min_L, include_examples);
}

void DocumentationRenderer::render_toc_r(OUTPUT_STREAM, markdown_item *md,
	int L, int min_L, int include_examples) {
	int adjustment = 0;
	if (min_L == 2) adjustment = 1;
	if ((md->type == HEADING_MIT) && (Markdown::get_heading_level(md) <= 2)) {
		HTML_OPEN_WITH("li", "class=\"exco%d\"", Markdown::get_heading_level(md) - adjustment);
		HTML::begin_span(OUT, I"indexblack");
		HTML_OPEN("b");
		DocumentationRenderer::link_to(OUT, md);
		for (markdown_item *ch = md->down; ch; ch = ch->next)
			DocumentationRenderer::render_extended(OUT, NULL, ch);
		HTML_CLOSE("a");
		HTML_CLOSE("b");
		HTML::end_span(OUT);
		HTML_CLOSE("li");
		WRITE("\n");
	}
	if ((md->type == INFORM_EXAMPLE_HEADING_MIT) && (include_examples)) {
		HTML_OPEN_WITH("li", "class=\"exco%d\"", L - adjustment);
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
		DocumentationRenderer::render_toc_r(OUT, ch, L+1, min_L, include_examples);
}

void DocumentationRenderer::render_example(OUTPUT_STREAM, compiled_documentation *cd,
	IFM_example *egc) {
	markdown_item *alt_EN = egc->header;
	if (alt_EN == NULL) {
		WRITE("Example %d is missing", egc->number);
	} else {
		IFM_example *E = RETRIEVE_POINTER_IFM_example(alt_EN->user_state);
		HTML_OPEN_WITH("div", "class=\"markdowncontent\"");
		InformFlavouredMarkdown::render_example_heading(OUT, E, NULL);

		markdown_item *passage_node = alt_EN->down;
		while (passage_node) {
			DocumentationRenderer::render_extended(OUT, cd, passage_node);
			passage_node = passage_node->next;
		}
		HTML_CLOSE("div");
		@<Enter the small print@>;
		markdown_item *origin = (egc->cue)?(egc->cue->down):NULL;
		while ((origin) && (origin->type == HEADING_MARKER_MIT)) origin = origin->next;
		if (origin) {
			WRITE("This example is drawn from ");
			DocumentationRenderer::link_to(OUT, egc->cue);
			DocumentationRenderer::render_extended(OUT, cd, origin);
			HTML_CLOSE("a");
		}
		@<Exit the small print@>;
	}
}

void DocumentationRenderer::render_extended(OUTPUT_STREAM, compiled_documentation *cd,
	markdown_item *md) {
	if ((cd) && (cd->compiled_from_extension_scrap))
		Markdown::render_bodied_extended(OUT, md,
			InformFlavouredMarkdown::variation());
	else
		Markdown::render_extended(OUT, md,
			InformFlavouredMarkdown::variation());
}
