[DocumentationCompiler::] Documentation Compiler.

To compile documentation from the textual syntax in an extension into a tree.

@ A single set of documentation, such as might be associated with a project,
a tool or an extension or kit, is represented by a |compiled_documentation|
object. This section provides just three public functions, for the three
ways to make one of these.

We can compile either from a single one-off file:

=
compiled_documentation *DocumentationCompiler::compile_from_file(filename *F,
	inform_extension *associated_extension, filename *sitemap) {
	TEMPORARY_TEXT(temp)
	TextFiles::write_file_contents(temp, F);
	compiled_documentation *cd =
		DocumentationCompiler::compile_from_text(temp, associated_extension, sitemap);
	DISCARD_TEXT(temp)
	return cd;
}

@ Or from a fragment of text, which happens when a single-file-format extension's
torn-off documentation is found:

=
compiled_documentation *DocumentationCompiler::compile_from_text(text_stream *scrap,
	inform_extension *associated_extension, filename *sitemap) {
	SVEXPLAIN(1, "(compiling documentation: %d chars)\n", Str::len(scrap));
	compiled_documentation *cd = DocumentationCompiler::new_cd(NULL, associated_extension, sitemap);
	cd->compiled_from_extension_scrap = TRUE;
	cd_volume *vol = FIRST_IN_LINKED_LIST(cd_volume, cd->volumes);
	cd_pageset *page = FIRST_IN_LINKED_LIST(cd_pageset, vol->pagesets);
	page->nonfile_content = scrap;
	DocumentationCompiler::compile_inner(cd);
	return cd;
}

@ Or from a path to a directory holding what may be multiple Markdown files and
other resources, which is what happens when compiling the Inform manuals, or
the documentation for a directory-format extension.

=
compiled_documentation *DocumentationCompiler::compile_from_path(pathname *P,
	inform_extension *associated_extension, filename *sitemap) {
	compiled_documentation *cd = DocumentationCompiler::new_cd(P, associated_extension, sitemap);
	DocumentationCompiler::compile_inner(cd);
	return cd;
}

@ Now to take a look inside:

@d NO_CD_INDEXES 4

@d ALPHABETICAL_EG_INDEX 0
@d NUMERICAL_EG_INDEX 1
@d THEMATIC_EG_INDEX 2
@d GENERAL_INDEX 3

=
typedef struct compiled_documentation {
	struct text_stream *title;

	struct inform_extension *associated_extension; /* if an extension */
	struct inform_extension *within_extension; /* if a kit inside an extension */

	struct pathname *domain; /* where the documentation source is */
	struct linked_list *source_files; /* of |cd_source_file| */
	struct linked_list *layout_errors; /* of |cd_layout_error| */
	struct linked_list *images; /* of |cd_image| */
	struct text_stream *images_URL;
	int compiled_from_extension_scrap;

	struct linked_list *volumes; /* of |cd_volume| */
	struct text_stream *contents_URL_pattern;
	int duplex_contents_page;
	struct text_stream *xrefs_file_pattern;
	struct text_stream *manifest_file_pattern;

	struct markdown_item *markdown_content;
	struct md_links_dictionary *link_references;
	int empty;

	struct linked_list *examples; /* of |IFM_example| */
	struct text_stream *example_URL_pattern;
	int examples_lettered; /* the alternative being, numbered */
	struct linked_list *cases; /* of |satellite_test_case| */

	int include_index[NO_CD_INDEXES];
	struct text_stream *index_title[NO_CD_INDEXES];
	struct text_stream *index_URL_pattern[NO_CD_INDEXES];

	struct cd_indexing_data id; /* for indexing the volumes in this cd */

	CLASS_DEFINITION
} compiled_documentation;

@ "Source files" are individual files of Markdown content which are collectively
read to compile the volumes of documentation.

=
typedef struct cd_source_file {
	struct text_stream *leafname;
	struct filename *as_filename;
	int used; /* did the layout file for this cd account for this file? */
	CLASS_DEFINITION
} cd_source_file;

@ A cd contains one or more "volumes". For something simple like an extension,
there will usually just be one volume, with the same title as the whole cd.
For the Inform manual built in to the apps, there will be two volumes,
"Writing with Inform" and "The Recipe Book".

=
typedef struct cd_volume {
	struct text_stream *title;
	struct text_stream *label;
	struct text_stream *home_URL;
	struct linked_list *source_files; /* Markdown source leafnames */
	struct linked_list *pagesets; /* of |cd_pageset| */
	struct markdown_item *volume_item;
	CLASS_DEFINITION
} cd_volume;

cd_volume *DocumentationCompiler::add_volume(compiled_documentation *cd, text_stream *title,
	text_stream *label, text_stream *home_URL) {
	cd_volume *vol = CREATE(cd_volume);
	vol->title = Str::duplicate(title);
	vol->label = Str::duplicate(label);
	vol->home_URL = Str::duplicate(home_URL);
	vol->source_files = NEW_LINKED_LIST(text_stream);
	vol->pagesets = NEW_LINKED_LIST(cd_pageset);
	vol->volume_item = NULL;
	ADD_TO_LINKED_LIST(vol, cd_volume, cd->volumes);
	return vol;
}

cd_volume *DocumentationCompiler::find_volume(compiled_documentation *cd, text_stream *title) {
	text_stream *to_match = Str::duplicate(title);
	if ((Str::get_first_char(to_match) == '\"') && (Str::get_last_char(to_match) == '\"')) {
		Str::delete_first_character(to_match);
		Str::delete_last_character(to_match);
	}
	cd_volume *V;
	LOOP_OVER_LINKED_LIST(V, cd_volume, cd->volumes)
		if ((Str::eq_insensitive(to_match, V->title)) || (Str::eq_insensitive(to_match, V->label)))
			return V;
	return NULL;
}

text_stream *DocumentationCompiler::home_URL_at_volume_item(markdown_item *vol) {
	if ((vol == NULL) || (vol->type != VOLUME_MIT) || (GENERAL_POINTER_IS_NULL(vol->user_state))) return I"index.html";
	cd_volume *cdv = RETRIEVE_POINTER_cd_volume(vol->user_state);
	return cdv->home_URL;
}

text_stream *DocumentationCompiler::title_at_volume_item(compiled_documentation *cd, markdown_item *vol) {
	if ((vol == NULL) || (vol->type != VOLUME_MIT) || (GENERAL_POINTER_IS_NULL(vol->user_state))) return cd->title;
	cd_volume *cdv = RETRIEVE_POINTER_cd_volume(vol->user_state);
	return cdv->title;
}

@ A volume contains one or more "pagesets". These are not as simple as pages.
The source may specify multiple source files, and they may each result in
multiple pages.

"Breaking" means dividing up the content into HTML pages by following its
chapter or section structure:

@e NO_PAGESETBREAKING from 1
@e SECTION_PAGESETBREAKING
@e CHAPTER_PAGESETBREAKING

=
typedef struct cd_pageset {
	struct text_stream *source_specification;
	struct text_stream *page_specification;
	struct text_stream *nonfile_content;
	int breaking;
	CLASS_DEFINITION
} cd_pageset;

cd_pageset *DocumentationCompiler::add_page(cd_volume *vol, text_stream *src, text_stream *dest,
	int breaking) {
	cd_pageset *pages = CREATE(cd_pageset);
	pages->source_specification = Str::duplicate(src);
	pages->page_specification = Str::duplicate(dest);
	pages->nonfile_content = NULL;
	pages->breaking = breaking;
	ADD_TO_LINKED_LIST(pages, cd_pageset, vol->pagesets);
	return pages;
}

@ "Layout errors" occur when the optional configuration file for a cd contains
syntax errors or asks for something ambiguous or impossible:

=
typedef struct cd_layout_error {
	struct text_stream *message;
	struct text_stream *line;
	int line_number;
	CLASS_DEFINITION
} cd_layout_error;

void DocumentationCompiler::layout_error(compiled_documentation *cd,
	text_stream *msg, text_stream *line, text_file_position *tfp) {
	cd_layout_error *err = CREATE(cd_layout_error);
	err->message = Str::duplicate(msg);
	err->line = Str::duplicate(line);
	err->line_number = tfp->line_count;
	ADD_TO_LINKED_LIST(err, cd_layout_error, cd->layout_errors);
}

@ We respond to such errors by writing a list of them into the documentation's
index page and otherwise not producting documentation at all:

=
int DocumentationCompiler::scold(OUTPUT_STREAM, compiled_documentation *cd) {
	int bad_ones = 0;
	cd_source_file *cdsf;
	LOOP_OVER_LINKED_LIST(cdsf, cd_source_file, cd->source_files)
		if (cdsf->used != 1)
			bad_ones++;
	if (bad_ones > 0) {
		HTML_OPEN("p");
		WRITE("No documentation has been produced because the Markdown file(s) "
			"provided did not tally:");
		HTML_CLOSE("p");
		HTML_OPEN("ul");
		LOOP_OVER_LINKED_LIST(cdsf, cd_source_file, cd->source_files)
			if (cdsf->used != 1) {
				HTML_OPEN("li");
				WRITE("The file '%S' ", cdsf->leafname);
				if (cdsf->used == 0) WRITE("is not part of the layout");
				else WRITE("is ambiguous, matching multiple page-sets in the layout");
				HTML_CLOSE("li");
			}
		HTML_CLOSE("ul");
		return TRUE;
	}
	if (LinkedLists::len(cd->layout_errors) == 0) return FALSE;
	HTML_OPEN("p");
	WRITE("No documentation has been produced because the 'contents.txt' or 'sitemap.txt' file was invalid:");
	HTML_CLOSE("p");
	HTML_OPEN("ul");
	cd_layout_error *err;
	LOOP_OVER_LINKED_LIST(err, cd_layout_error, cd->layout_errors) {
		HTML_OPEN("li");
		WRITE("Line %d: ", err->line_number);
		HTML_OPEN("code");
		WRITE("%S", err->line);
		HTML_CLOSE("code");
		HTML_TAG("br");
		WRITE("%S", err->message);
		HTML_CLOSE("li");
	}
	HTML_CLOSE("ul");
	return TRUE;
}

@ "Images" are image files, that is, pictures.

=
typedef struct cd_image {
	struct filename *source;
	struct text_stream *final_leafname;
	struct text_stream *prefix;
	struct text_stream *correct_URL;
	int used;
	CLASS_DEFINITION
} cd_image;

void DocumentationCompiler::add_images(compiled_documentation *cd, pathname *figures,
	text_stream *prefix) {
	linked_list *L = Directories::listing(figures);
	text_stream *entry;
	LOOP_OVER_LINKED_LIST(entry, text_stream, L) {
		if (Platform::is_folder_separator(Str::get_last_char(entry)) == FALSE) {
			cd_image *cdim = CREATE(cd_image);
			cdim->source = Filenames::in(figures, entry);
			LOOP_THROUGH_TEXT(pos, entry)
				Str::put(pos, Characters::tolower(Str::get(pos)));
			cdim->final_leafname = Str::duplicate(entry);
			cdim->correct_URL = Str::new();
			if (Str::len(prefix) > 0) {
				WRITE_TO(cdim->correct_URL, "%S/%S", prefix, entry);
			} else {
				WRITE_TO(cdim->correct_URL, "%S", entry);
			}
			cdim->prefix = Str::duplicate(prefix);
			cdim->used = FALSE;
			ADD_TO_LINKED_LIST(cdim, cd_image, cd->images);
			Markdown::create(cd->link_references, Str::duplicate(entry), cdim->correct_URL, NULL);
		}
	}
}

compiled_documentation *cd_being_watched_for_image_use = NULL;
void DocumentationCompiler::watch_image_use(compiled_documentation *cd) {
	cd_being_watched_for_image_use = cd;
}
void DocumentationCompiler::notify_image_use(text_stream *URL) {
	if (cd_being_watched_for_image_use) {
		cd_image *cdim;
		LOOP_OVER_LINKED_LIST(cdim, cd_image, cd_being_watched_for_image_use->images)
			if (Str::eq(URL, cdim->correct_URL))
				cdim->used = TRUE;
	}
}

@ And we can now create a new cd object.

=
compiled_documentation *DocumentationCompiler::new_cd(pathname *P,
	inform_extension *associated_extension, filename *sitemap) {
	compiled_documentation *cd = CREATE(compiled_documentation);
	@<Initialise the cd structure@>;
	if (P) {
		cd_source_file *Documentation_md_cdsf = NULL;
		@<Find the possible Markdown source files@>;
		@<Read the contents and sitemap files, if they exist@>;
		DocumentationCompiler::add_images(cd, Pathnames::down(P, I"Images"), cd->images_URL);
	}
	IndexingData::add_default_categories(cd);
	if (LinkedLists::len(cd->volumes) == 0) {
		cd_volume *implied = DocumentationCompiler::add_volume(cd, cd->title, NULL, I"index.html");
		ADD_TO_LINKED_LIST(I"Documentation.md", text_stream, implied->source_files);
	}
	cd_volume *V;
	LOOP_OVER_LINKED_LIST(V, cd_volume, cd->volumes) {
		if ((LinkedLists::len(V->source_files) > 0) &&
			(LinkedLists::len(V->pagesets) == 0)) {
			text_stream *sf;
			LOOP_OVER_LINKED_LIST(sf, text_stream, V->source_files) {
				TEMPORARY_TEXT(dest)
				if (LinkedLists::len(cd->volumes) > 1) WRITE_TO(dest, "%S_", V->label);
				WRITE_TO(dest, "chapter#.html");
				DocumentationCompiler::add_page(V, sf, dest, CHAPTER_PAGESETBREAKING);
				DISCARD_TEXT(dest)
			}
		}
	}
	return cd;
}

@<Initialise the cd structure@> =
	cd->title = Str::new();
	cd->associated_extension = associated_extension;
	if (cd->associated_extension)
		WRITE_TO(cd->title, "%X", cd->associated_extension->as_copy->edition->work);
	cd->within_extension = NULL;
	cd->markdown_content = NULL;
	cd->link_references = Markdown::new_links_dictionary();
	cd->empty = FALSE;
	cd->examples = NEW_LINKED_LIST(IFM_example);
	cd->cases = NEW_LINKED_LIST(satellite_test_case);
	cd->id = IndexingData::new_indexing_data();
	cd->examples_lettered = TRUE;
	cd->example_URL_pattern = I"eg_#.html";
	cd->contents_URL_pattern = I"index.html";
	cd->xrefs_file_pattern = NULL;
	cd->manifest_file_pattern = NULL;
	cd->index_URL_pattern[ALPHABETICAL_EG_INDEX] = I"alphabetical_index.html";
	cd->index_URL_pattern[NUMERICAL_EG_INDEX] = I"numerical_index.html";
	cd->index_URL_pattern[THEMATIC_EG_INDEX] = I"thematic_index.html";
	cd->index_URL_pattern[GENERAL_INDEX] = I"general_index.html";
	cd->index_title[ALPHABETICAL_EG_INDEX] = I"Examples in Alphabetical Order";
	cd->index_title[NUMERICAL_EG_INDEX] = I"Examples by Number";
	cd->index_title[THEMATIC_EG_INDEX] = I"Examples by Theme";
	cd->index_title[GENERAL_INDEX] = I"Index";
	cd->include_index[ALPHABETICAL_EG_INDEX] = FALSE;
	cd->include_index[NUMERICAL_EG_INDEX] = FALSE;
	cd->include_index[THEMATIC_EG_INDEX] = FALSE;
	cd->include_index[GENERAL_INDEX] = FALSE;
	cd->layout_errors = NEW_LINKED_LIST(cd_layout_error);
	cd->volumes = NEW_LINKED_LIST(cd_volume);
	cd->compiled_from_extension_scrap = FALSE;
	cd->duplex_contents_page = FALSE;
	cd->source_files = NEW_LINKED_LIST(cd_source_file);
	cd->domain = P;
	cd->images = NEW_LINKED_LIST(cd_image);
	cd->images_URL = I"images";
	
@<Find the possible Markdown source files@> =
	linked_list *L = Directories::listing(P);
	text_stream *entry;
	LOOP_OVER_LINKED_LIST(entry, text_stream, L) {
		if (Platform::is_folder_separator(Str::get_last_char(entry)) == FALSE) {
			if ((Str::ends_with(entry, I".md")) || (Str::ends_with(entry, I".MD"))) {
				cd_source_file *cdsf = CREATE(cd_source_file);
				cdsf->leafname = Str::duplicate(entry);
				cdsf->as_filename = Filenames::in(P, entry);
				cdsf->used = 0;
				ADD_TO_LINKED_LIST(cdsf, cd_source_file, cd->source_files);
				if (Str::eq_insensitive(entry, I"Documentation.md"))
					Documentation_md_cdsf = cdsf;
			}
		}
	}

@<Read the contents and sitemap files, if they exist@> =
	filename *layout_file = Filenames::in(P, I"contents.txt");
	if (TextFiles::exists(layout_file))
		TextFiles::read(layout_file, FALSE, "can't open contents file",
			TRUE, DocumentationCompiler::read_contents_helper, NULL, cd);
	else if (Documentation_md_cdsf) Documentation_md_cdsf->used = TRUE;

	if (sitemap == NULL) sitemap = Filenames::in(P, I"sitemap.txt");
	if (TextFiles::exists(sitemap))
		TextFiles::read(sitemap, FALSE, "can't open sitemap file",
			TRUE, DocumentationCompiler::read_sitemap_helper, NULL, cd);

@ =
void DocumentationCompiler::read_contents_helper(text_stream *cl, text_file_position *tfp,
	void *v_cd) {
	compiled_documentation *cd = (compiled_documentation *) v_cd;
	Str::trim_white_space(cl);
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, cl, U" *#%c*")) { Regexp::dispose_of(&mr); return; }
	if (Regexp::match(&mr, cl, U" *")) { Regexp::dispose_of(&mr); return; }

	if (Regexp::match(&mr, cl, U" *text: *(%c*?)")) {
		@<Act on a text declaration@>;
	} else if (Regexp::match(&mr, cl, U" *volume: *\"(%c*?)\" or \"(%C+)\"")) {
		@<Act on a volume declaration@>;
	} else if (Regexp::match(&mr, cl, U" *index notation: *(%c*?)")) {
		@<Act on an indexing notation@>;
	} else {
		DocumentationCompiler::layout_error(cd, I"unknown syntax in content.txt file", cl, tfp);
	}
	Regexp::dispose_of(&mr);
}

@<Act on a volume declaration@> =
	DocumentationCompiler::add_volume(cd, mr.exp[0], mr.exp[1], NULL);

@<Act on a text declaration@> =
	text_stream *src = I"Documentation.md";
	match_results mr2 = Regexp::create_mr();
	if (Regexp::match(&mr2, mr.exp[0], U"\"(%c*?.md)\"")) {
		src = Str::duplicate(mr2.exp[0]);
	} else if (Regexp::match(&mr2, mr.exp[0], U"\"(%c*?)\"")) {
		DocumentationCompiler::layout_error(cd, I"source file must have filename extension '.md'", cl, tfp);
	} else {
		DocumentationCompiler::layout_error(cd, I"unknown syntax in layout file", cl, tfp);
	}
	Regexp::dispose_of(&mr2);

	int slash_count = 0;
	LOOP_THROUGH_TEXT(pos, src) if ((Str::get(pos) == '/') || (Str::get(pos) == '\\')) slash_count++;
	if (slash_count > 0)
		DocumentationCompiler::layout_error(cd,
			I"text source cannot contain slash characters", cl, tfp);

	int star_count_1 = 0;
	LOOP_THROUGH_TEXT(pos, src) if (Str::get(pos) == '*') star_count_1++;
	if (star_count_1 > 1)
		DocumentationCompiler::layout_error(cd,
			I"source can contain at most one '*'", cl, tfp);

	cd_volume *vol, *last_vol = NULL;
	LOOP_OVER_LINKED_LIST(vol, cd_volume, cd->volumes) last_vol = vol;
	if (last_vol == NULL)
		last_vol = DocumentationCompiler::add_volume(cd, cd->title, NULL, I"index.html");

	if (LinkedLists::len(cd->source_files) > 0) {
		int counter = 0;
		cd_source_file *cdsf;
		LOOP_OVER_LINKED_LIST(cdsf, cd_source_file, cd->source_files) {
			text_stream *entry = cdsf->leafname;
			TEMPORARY_TEXT(prefix_must_be)
			TEMPORARY_TEXT(suffix_must_be)
			if (star_count_1 == 0) WRITE_TO(prefix_must_be, "%S", src);
			else {
				for (int i=0, seg=1; i<Str::len(src); i++)
					if (Str::get_at(src, i) == '*') seg++;
					else if (seg == 1) PUT_TO(prefix_must_be, Str::get_at(src, i));
					else if (seg == 2) PUT_TO(suffix_must_be, Str::get_at(src, i));
			}
			if ((Str::begins_with(entry, prefix_must_be)) &&
				(Str::ends_with(entry, suffix_must_be))) {
				ADD_TO_LINKED_LIST(entry, text_stream, last_vol->source_files);
				counter++;
				cdsf->used++;
			}
			DISCARD_TEXT(prefix_must_be)
			DISCARD_TEXT(suffix_must_be)
		}
		if (counter == 0) 
			DocumentationCompiler::layout_error(cd,
				I"no Markdown file has a name matching this source", cl, tfp);
	} else {
		ADD_TO_LINKED_LIST(I"Documentation.md", text_stream, last_vol->source_files);
	}
	DISCARD_TEXT(src)

@<Act on an indexing notation@> =
	if (IndexingData::parse_category_command(cd, mr.exp[0]) == FALSE)
		DocumentationCompiler::layout_error(cd, I"bad indexing notation", cl, tfp);

@

=
void DocumentationCompiler::read_sitemap_helper(text_stream *cl, text_file_position *tfp,
	void *v_cd) {
	compiled_documentation *cd = (compiled_documentation *) v_cd;
	Str::trim_white_space(cl);
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, cl, U" *#%c*")) { Regexp::dispose_of(&mr); return; }
	if (Regexp::match(&mr, cl, U" *")) { Regexp::dispose_of(&mr); return; }

	if (Regexp::match(&mr, cl, U" *cross-references: to \"(%c*)\"")) {
		cd->xrefs_file_pattern = Str::duplicate(mr.exp[0]);
	} else if (Regexp::match(&mr, cl, U" *manifest: to \"(%c*)\"")) {
		cd->manifest_file_pattern = Str::duplicate(mr.exp[0]);
	} else if (Regexp::match(&mr, cl, U" *images: to \"(%c*)\"")) {
		cd->images_URL = Str::duplicate(mr.exp[0]);
	} else if (Regexp::match(&mr, cl, U" *contents: *(%c+?) to \"(%c*)\"")) {
		if (Str::eq(mr.exp[0], I"standard")) cd->duplex_contents_page = FALSE;
		else if (Str::eq(mr.exp[0], I"duplex")) cd->duplex_contents_page = TRUE;
		else DocumentationCompiler::layout_error(cd, I"'contents:' must be 'standard' or 'duplex'", cl, tfp);
		cd->contents_URL_pattern = Str::duplicate(mr.exp[1]);
	} else if (Regexp::match(&mr, cl, U" *examples: *(%c+?) to \"(%c*)\"")) {
		if (Str::eq(mr.exp[0], I"lettered")) cd->examples_lettered = TRUE;
		else if (Str::eq(mr.exp[0], I"numbered")) cd->examples_lettered = FALSE;
		else DocumentationCompiler::layout_error(cd, I"'examples:' must be 'lettered' or 'numbered'", cl, tfp);
		cd->example_URL_pattern = Str::duplicate(mr.exp[1]);
	} else if (Regexp::match(&mr, cl, U" *pages: *(%c*?) *")) {
		@<Act on a page-set declaration@>;
	} else if (Regexp::match(&mr, cl, U" *volume contents: *\"(%c*?)\" to \"(%c*?)\"")) {
		@<Act on a volume contents declaration@>;
	} else if (Regexp::match(&mr, cl, U" *alphabetical index: *\"(%c*?)\" to \"(%c*?)\" *")) {
		cd->index_title[ALPHABETICAL_EG_INDEX] = Str::duplicate(mr.exp[0]);
		cd->index_URL_pattern[ALPHABETICAL_EG_INDEX] = Str::duplicate(mr.exp[1]);
		cd->include_index[ALPHABETICAL_EG_INDEX] = TRUE;
	} else if (Regexp::match(&mr, cl, U" *numerical index: *\"(%c*?)\" to \"(%c*?)\" *")) {
		cd->index_title[NUMERICAL_EG_INDEX] = Str::duplicate(mr.exp[0]);
		cd->index_URL_pattern[NUMERICAL_EG_INDEX] = Str::duplicate(mr.exp[1]);
		cd->include_index[NUMERICAL_EG_INDEX] = TRUE;
	} else if (Regexp::match(&mr, cl, U" *thematic index: *\"(%c*?)\" to \"(%c*?)\" *")) {
		cd->index_title[THEMATIC_EG_INDEX] = Str::duplicate(mr.exp[0]);
		cd->index_URL_pattern[THEMATIC_EG_INDEX] = Str::duplicate(mr.exp[1]);
		cd->include_index[THEMATIC_EG_INDEX] = TRUE;
	} else if (Regexp::match(&mr, cl, U" *general index: *\"(%c*?)\" to \"(%c*?)\" *")) {
		cd->index_title[GENERAL_INDEX] = Str::duplicate(mr.exp[0]);
		cd->index_URL_pattern[GENERAL_INDEX] = Str::duplicate(mr.exp[1]);
		cd->include_index[GENERAL_INDEX] = TRUE;
	} else {
		DocumentationCompiler::layout_error(cd, I"unknown syntax in layout file", cl, tfp);
	}
	Regexp::dispose_of(&mr);
}

@<Act on a volume contents declaration@> =
	if (Str::eq(mr.exp[1], I"index.html"))
		DocumentationCompiler::layout_error(cd, I"a volume home page cannot be 'index.html'", cl, tfp);
	cd_volume *V = DocumentationCompiler::find_volume(cd, mr.exp[0]);
	if (V) V->home_URL = Str::duplicate(mr.exp[1]);
	else DocumentationCompiler::layout_error(cd, I"unknown volume in sitemap file", cl, tfp);

@<Act on a page-set declaration@> =
	TEMPORARY_TEXT(dest)
	int breaking = NO_PAGESETBREAKING;
	cd_volume *V = NULL;

	text_stream *set = mr.exp[0];
	match_results mr2 = Regexp::create_mr();
	if (Regexp::match(&mr2, set, U"(%c*) to \"(%c*?.html)\"")) {
		Str::clear(dest); WRITE_TO(dest, "%S", mr2.exp[1]);
		Str::clear(set); WRITE_TO(set, "%S", mr2.exp[0]);
	} else if (Regexp::match(&mr2, set, U"(%c*) to \"(%c*?)\"")) {
		DocumentationCompiler::layout_error(cd, I"destination file must have filename extension '.html'", cl, tfp);
	}
	if (Regexp::match(&mr2, set, U"(%c*) by sections")) {
		breaking = SECTION_PAGESETBREAKING;
		Str::clear(set); WRITE_TO(set, "%S", mr2.exp[0]);
	} else if (Regexp::match(&mr2, set, U"(%c*) by chapters")) {
		breaking = CHAPTER_PAGESETBREAKING;
		Str::clear(set); WRITE_TO(set, "%S", mr2.exp[0]);
	} else if (Regexp::match(&mr2, set, U"(%c*) by %c*")) {
		DocumentationCompiler::layout_error(cd, I"pages may be split only 'by sections' or 'by chapters'", cl, tfp);
		Str::clear(set); WRITE_TO(set, "%S", mr2.exp[0]);
	}
	if (Str::ne_insensitive(set, I"all")) {
		V = DocumentationCompiler::find_volume(cd, mr.exp[0]);
		if (V == NULL) {
			TEMPORARY_TEXT(err)
			WRITE_TO(err, "No such volume as '%S': list of known volumes =", mr.exp[0]);
			LOOP_OVER_LINKED_LIST(V, cd_volume, cd->volumes)
				WRITE_TO(err, " '%S'", V->title);
			DocumentationCompiler::layout_error(cd, err, cl, tfp);
			DISCARD_TEXT(err)
		}
	}
	Regexp::dispose_of(&mr2);
	
	int hash_count = 0;
	LOOP_THROUGH_TEXT(pos, dest) if (Str::get(pos) == '#') hash_count++;
	if (hash_count == 0) {
		if (breaking != NO_PAGESETBREAKING)
			DocumentationCompiler::layout_error(cd,
				I"destination must contain a '#' for where the chapter/section number goes", cl, tfp);
	} else if (hash_count == 1) {
		if (breaking == NO_PAGESETBREAKING)
			DocumentationCompiler::layout_error(cd,
				I"destination can only contain a '#' when breaking by chapters or sections", cl, tfp);
	} else {
		DocumentationCompiler::layout_error(cd,
			I"destination can only contain only one '#', and only when breaking by chapters or sections", cl, tfp);
	}

	int slash_count = 0;
	LOOP_THROUGH_TEXT(pos, dest) if ((Str::get(pos) == '/') || (Str::get(pos) == '\\')) slash_count++;
	if (slash_count > 0)
		DocumentationCompiler::layout_error(cd,
			I"no destination filename can (yet) contain slashes", cl, tfp);

	int star_count_2 = 0;
	LOOP_THROUGH_TEXT(pos, dest) if (Str::get(pos) == '*') star_count_2++;
	if (star_count_2 > 1)
		DocumentationCompiler::layout_error(cd,
			I"destination can contain at most one '*'", cl, tfp);

	cd_volume *W;
	LOOP_OVER_LINKED_LIST(W, cd_volume, cd->volumes) {
		if ((V == NULL) || (V == W)) {
			text_stream *sf;
			LOOP_OVER_LINKED_LIST(sf, text_stream, W->source_files) {
				TEMPORARY_TEXT(expanded_dest)
				for (int i=0; i<Str::len(dest); i++)
					if (Str::get_at(dest, i) == '*') {
						for (int j=0; j<Str::len(sf)-3; j++)
							PUT_TO(expanded_dest, Str::get_at(sf, j));
						
					} else {
						PUT_TO(expanded_dest, Str::get_at(dest, i));
					}
				DocumentationCompiler::add_page(W, sf, expanded_dest, breaking);
				DISCARD_TEXT(expanded_dest)
			}
		}
	}
	DISCARD_TEXT(dest)

@ "Satellite test cases" is an umbrella term including both examples and test
cases, all of which are tested when an extension (say) is tested.

=
typedef struct satellite_test_case {
	int is_example;
	struct IFM_example *as_example; /* or |NULL| for a test case which is not an example */
	struct text_stream *owning_heading;
	struct tree_node *owning_node;
	struct compiled_documentation *owner;
	struct text_stream *short_name;
	struct filename *test_file;
	struct filename *ideal_transcript;
	struct text_stream *visible_documentation;
	struct linked_list *example_errors; /* of |markdown_item| */
	struct markdown_item *primary_placement;
	struct markdown_item *secondary_placement;
	CLASS_DEFINITION
} satellite_test_case;

satellite_test_case *DocumentationCompiler::new_satellite(compiled_documentation *cd,
	int is_eg, text_stream *short_name, filename *F) {
	satellite_test_case *stc = CREATE(satellite_test_case);
	stc->is_example = is_eg;
	stc->as_example = NULL;
	stc->owning_heading = NULL;
	stc->owning_node = NULL;
	stc->owner = cd;
	stc->short_name = Str::duplicate(short_name);
	stc->test_file = F;
	stc->ideal_transcript = NULL;
	stc->visible_documentation = Str::new();
	stc->example_errors = NEW_LINKED_LIST(markdown_item);
	stc->primary_placement = NULL;
	stc->secondary_placement = NULL;
	TEMPORARY_TEXT(ideal_leafname)
	WRITE_TO(ideal_leafname, "%S-I.txt", stc->short_name);
	filename *IF = Filenames::in(Filenames::up(F), ideal_leafname);
	if (TextFiles::exists(IF)) stc->ideal_transcript = IF;
	DISCARD_TEXT(ideal_leafname)
	ADD_TO_LINKED_LIST(stc, satellite_test_case, cd->cases);
	return stc;
}

@ Satellites for a cd consist of examples in the |Examples| subdirectory and
tests in the |Tests| one.

=
int DocumentationCompiler::detect_satellites(compiled_documentation *cd) {
	if (cd->domain) {
		pathname *EP = Pathnames::down(cd->domain, I"Examples");
		int egs = TRUE;
		@<Scan EP directory for examples@>;
		egs = FALSE;
		EP = Pathnames::down(cd->domain, I"Tests");
		@<Scan EP directory for examples@>;
	}
	return LinkedLists::len(cd->cases);
}

@<Scan EP directory for examples@> =
	scan_directory *D = Directories::open(EP);
	if (D) {
		TEMPORARY_TEXT(leafname)
		while (Directories::next(D, leafname)) {
			inchar32_t first = Str::get_first_char(leafname), last = Str::get_last_char(leafname);
			if (Platform::is_folder_separator(last)) continue;
			if (first == '.') continue;
			if (first == '(') continue;
			text_stream *short_name = Str::new();
			filename *F = Filenames::in(EP, leafname);
			Filenames::write_unextended_leafname(short_name, F);
			if ((Str::get_at(short_name, Str::len(short_name)-2) == '-') &&
				((Str::get_at(short_name, Str::len(short_name)-1) == 'I')
					|| (Str::get_at(short_name, Str::len(short_name)-1) == 'i')))
				continue;
			satellite_test_case *stc =
				DocumentationCompiler::new_satellite(cd, egs, short_name, F);
			if (stc->is_example)
				@<Scan the example for its header and content@>;
		}
		DISCARD_TEXT(leafname)
		Directories::close(D);
	}

@ Scanning the examples is not a trivial process, because it involves going
through the metadata and also capturing the Markdown material.

=
typedef struct example_scanning_state {
	int star_count;
	struct text_stream *long_title;
	struct text_stream *body_text;
	struct text_stream *placement;
	struct text_stream *recipe_placement;
	struct text_stream *subtitle;
	struct text_stream *index;
	struct text_stream *desc;
	struct linked_list *errors; /* of |markdown_item| */
	struct text_stream *scanning;
	int past_header;
} example_scanning_state;

@<Scan the example for its header and content@> =
	example_scanning_state ess;
	ess.star_count = 1;
	ess.long_title = NULL;
	ess.body_text = Str::new();
	ess.placement = NULL;
	ess.recipe_placement = NULL;
	ess.subtitle = NULL;
	ess.index = NULL;
	ess.desc = NULL;
	ess.errors = NEW_LINKED_LIST(markdown_item);
	ess.past_header = FALSE;
	ess.scanning = Str::new();
	WRITE_TO(ess.scanning, "%S", Filenames::get_leafname(stc->test_file));
	TextFiles::read(stc->test_file, FALSE, "unable to read file of example", TRUE,
		&DocumentationCompiler::read_example_helper, NULL, &ess);

	cd_volume *primary = NULL;
	cd_volume *secondary = NULL;
	cd_volume *vol;
	LOOP_OVER_LINKED_LIST(vol, cd_volume, cd->volumes) {
		if (primary == NULL) primary = vol;
		else if (secondary == NULL) secondary = vol;
	}
	if ((Str::len(ess.placement) > 0) && (primary)) {
		stc->primary_placement =
			InformFlavouredMarkdown::find_section(primary->volume_item, ess.placement);
		if (stc->primary_placement == NULL) {
			text_stream *err = Str::new();
			WRITE_TO(err, "example gives Location '%S', which is not the name of any section", ess.placement);
			DocumentationCompiler::example_error(&ess, err);
		}
	}

	if ((Str::len(ess.recipe_placement) > 0) && (secondary)) {
		stc->secondary_placement =
			InformFlavouredMarkdown::find_section(secondary->volume_item, ess.recipe_placement);
		if (stc->secondary_placement == NULL) {
			text_stream *err = Str::new();
			WRITE_TO(err, "example gives RecipeLocation '%S', which is not the name of any section", ess.recipe_placement);
			DocumentationCompiler::example_error(&ess, err);
		}
	}

	if (Str::len(ess.desc) == 0) {
		DocumentationCompiler::example_error(&ess,
			I"example does not give its Description");
	}
	IFM_example *eg = InformFlavouredMarkdown::new_example(
		ess.long_title, ess.desc, ess.star_count, LinkedLists::len(cd->examples));
	eg->cue = stc->primary_placement;
	eg->secondary_cue = stc->secondary_placement;
	eg->ex_subtitle = ess.subtitle;
	eg->ex_index = ess.index;
	eg->primary_label = (primary)?(primary->label):NULL;
	eg->secondary_label = (secondary)?(secondary->label):NULL;
	ADD_TO_LINKED_LIST(eg, IFM_example, cd->examples);

	stc->as_example = eg;
	stc->visible_documentation = Str::duplicate(ess.body_text);
	stc->example_errors = ess.errors;

@ =
void DocumentationCompiler::example_error(example_scanning_state *ess, text_stream *text) {
	text_stream *err = Str::new();
	WRITE_TO(err, "Example file '%S': %S", ess->scanning, text);
	markdown_item *E = InformFlavouredMarkdown::error_item(err);
	ADD_TO_LINKED_LIST(E, markdown_item, ess->errors);
}

@ =
void DocumentationCompiler::read_example_helper(text_stream *text, text_file_position *tfp,
	void *v_state) {
	example_scanning_state *ess = (example_scanning_state *) v_state;
	if (tfp->line_count == 1) {
		match_results mr = Regexp::create_mr();
		if ((Regexp::match(&mr, text, U"Example *: *(%**) *(%c+?)")) ||
			(Regexp::match(&mr, text, U"Example *- *(%**) *(%c+?)"))) {
			ess->star_count = Str::len(mr.exp[0]);
			if (ess->star_count == 0) {
				DocumentationCompiler::example_error(ess,
					I"this example should be marked (before the title) '*', '**', '***' or '****' for difficulty");
				ess->star_count = 1;
			}
			if (ess->star_count > 4) {
				DocumentationCompiler::example_error(ess,
					I"four stars '****' is the maximum difficulty rating allowed");
				ess->star_count = 4;
			}
			ess->long_title = Str::duplicate(mr.exp[1]);
		} else {
			DocumentationCompiler::example_error(ess,
				I"titling line of example file is malformed");
		}
		Regexp::dispose_of(&mr);
	} else if (ess->past_header == FALSE) {
		if (Str::is_whitespace(text)) { ess->past_header = TRUE; return; }
		match_results mr = Regexp::create_mr();
		if (Regexp::match(&mr, text, U"(%C+?) *: *(%c+?)")) {
			if (Str::eq(mr.exp[0], I"Location")) ess->placement = Str::duplicate(mr.exp[1]);
			else if (Str::eq(mr.exp[0], I"RecipeLocation")) ess->recipe_placement = Str::duplicate(mr.exp[1]);
			else if (Str::eq(mr.exp[0], I"Subtitle")) ess->subtitle = Str::duplicate(mr.exp[1]);
			else if (Str::eq(mr.exp[0], I"Index")) ess->index = Str::duplicate(mr.exp[1]);
			else if (Str::eq(mr.exp[0], I"Description")) ess->desc = Str::duplicate(mr.exp[1]);
		} else {
			DocumentationCompiler::example_error(ess,
				I"header line of example file is malformed");
		}
		Regexp::dispose_of(&mr);
	} else {
		WRITE_TO(ess->body_text, "%S\n", text);
	}
}

@ Stage two of sorting out the satellites is to put special items into the
Markdown tree for the cd which mark the places where the examples are referred
to. Note that an example must appear in the primary volume, and can also appear
in the secondary (if there is one).

=
void DocumentationCompiler::place_example_heading_items(compiled_documentation *cd) {
	satellite_test_case *stc;
	LOOP_OVER_LINKED_LIST(stc, satellite_test_case, cd->cases) {
		IFM_example *eg = stc->as_example;
		if (eg) {
			markdown_item *eg_header = Markdown::new_item(INFORM_EXAMPLE_HEADING_MIT);
			eg->header = eg_header;
			eg_header->user_state = STORE_POINTER_IFM_example(eg);
			markdown_item *md = stc->primary_placement;
			if (md == NULL) {
				md = cd->markdown_content;
				if (md) md = md->down;
				if (md) md = md->down;
				if (md) {
					if (md->down == NULL) md->down = eg_header;
					else {
						md = md->down;
						while ((md) && (md->next)) md = md->next;
						eg_header->next = md->next; md->next = eg_header;
					}
				}
			} else {
				if (md->next) md = md->next;
				while ((md) && (DocumentationCompiler::skippable_item(md->next, eg)))
					md = md->next;
				eg_header->next = md->next; md->next = eg_header;
			}
			
			if (stc->secondary_placement) {
				markdown_item *eg_header = Markdown::new_item(INFORM_EXAMPLE_HEADING_MIT);
				eg->secondary_header = eg_header;
				eg_header->user_state = STORE_POINTER_IFM_example(eg);
				markdown_item *md = stc->secondary_placement;
				if (md->next) md = md->next;
				while ((md) && (DocumentationCompiler::skippable_item(md->next, eg)))
					md = md->next;
				eg_header->next = md->next; md->next = eg_header;
			}

			markdown_item *E;
			LOOP_OVER_LINKED_LIST(E, markdown_item, stc->example_errors)
				Markdown::add_to(E, cd->markdown_content);
		}
	}
}

int DocumentationCompiler::skippable_item(markdown_item *md, IFM_example *by) {
	if (md == NULL) return FALSE;
	if (md->type == HEADING_MIT) {
		if (Markdown::get_heading_level(md) == 1) return FALSE;
		if (Markdown::get_heading_level(md) == 2) return FALSE;
	}
	if (md->type == INFORM_EXAMPLE_HEADING_MIT) {
		IFM_example *already = RETRIEVE_POINTER_IFM_example(md->user_state);
		if (already->star_count > by->star_count) return FALSE;
		if (already->star_count < by->star_count) return TRUE;
		if (Str::cmp(already->name, by->name) > 0) return FALSE;
	}
	return TRUE;
}

@ And lastly, we can number the examples. This is done as a third stage of
processing and not as part of the second because we must also pick up
example headers explicitly written in the source text of a single-file extension,
which do not arise from satellites at all.

Once we do know the sequence, we can work out the insignia for each example,
and from that the URL of the HTML file for it.

=
void DocumentationCompiler::count_examples(compiled_documentation *cd) {
	int example_number = 0;
	DocumentationCompiler::recursively_renumber_examples_r(cd->markdown_content,
		&example_number, cd->examples_lettered);

	IFM_example *eg;
	LOOP_OVER_LINKED_LIST(eg, IFM_example, cd->examples) {
		Str::clear(eg->URL);
		for (int i=0; i<Str::len(cd->example_URL_pattern); i++) {
			inchar32_t c = Str::get_at(cd->example_URL_pattern, i);
			if (c == '#') WRITE_TO(eg->URL, "%S", eg->insignia);
			else PUT_TO(eg->URL, c);
		}
		Markdown::create(cd->link_references, Str::duplicate(eg->name), eg->URL, NULL);
	}
}

void DocumentationCompiler::recursively_renumber_examples_r(markdown_item *md,
	int *example_number, int lettered) {
	if (md->type == INFORM_EXAMPLE_HEADING_MIT) {
		IFM_example *E = RETRIEVE_POINTER_IFM_example(md->user_state);
		if (md == E->header) { /* only look at the primary header */
			Str::clear(E->insignia);
			int N = ++(*example_number);
			if (lettered) {
				int P = 1;
				while (N > 26) { P += 1, N -= 26; }
				if (P > 1) WRITE_TO(E->insignia, "%d", P);
				WRITE_TO(E->insignia, "%c", 'A'+N-1);
			} else {
				WRITE_TO(E->insignia, "%d", N);
			}
		}
	}
	for (markdown_item *ch = md->down; ch; ch = ch->next)
		DocumentationCompiler::recursively_renumber_examples_r(ch, example_number, lettered);
}

@ We are finally in a position to write |DocumentationCompiler::compile_inner|,
the function which all cd compilations funnel through.

What makes this such a complicated dance is that we need to perform Phase I
Markdown parsing on the examples and the volumes first, in order to get the
necessary links to populate the link references dictionary, and only then
perform Phase II on everything.

=
void DocumentationCompiler::compile_inner(compiled_documentation *cd) {
	DocumentationCompiler::watch_image_use(cd);
	/* Phase I parsing */
	DocumentationCompiler::Phase_I_on_volumes(cd);
	DocumentationCompiler::detect_satellites(cd);
	DocumentationCompiler::place_example_heading_items(cd);
	DocumentationCompiler::count_examples(cd);
	satellite_test_case *stc;
	LOOP_OVER_LINKED_LIST(stc, satellite_test_case, cd->cases) {
		IFM_example *eg = stc->as_example;
		if (eg) {	
			if (Str::len(stc->visible_documentation) > 0) {
				markdown_item *alt_ecd = Markdown::parse_block_structure_using_extended(
					stc->visible_documentation, cd->link_references,
					InformFlavouredMarkdown::variation());
				eg->header->down = alt_ecd->down;
			}
		}
	}

	/* Phase II parsing */
	Markdown::parse_all_blocks_inline_using_extended(cd->markdown_content, NULL,
		cd->link_references, InformFlavouredMarkdown::variation());

	/* Indexing */
	IndexLemmas::scan_documentation(cd);
	if (IndexingData::indexing_occurred(cd)) cd->include_index[GENERAL_INDEX] = TRUE;
	if (LinkedLists::len(cd->examples) >= 10) cd->include_index[NUMERICAL_EG_INDEX] = TRUE;
	if (LinkedLists::len(cd->examples) >= 20) cd->include_index[ALPHABETICAL_EG_INDEX] = TRUE;
	DocumentationCompiler::watch_image_use(NULL);
}

@ In addition to regular Phase I parsing of the content in the volumes, we
want to insert |VOLUME_MIT| and |FILE_MIT| items into the tree to mark where
new files and volumes begin.

=
void DocumentationCompiler::Phase_I_on_volumes(compiled_documentation *cd) {
	pathname *P = cd->domain;
	cd_volume *vol;
	LOOP_OVER_LINKED_LIST(vol, cd_volume, cd->volumes) {
		cd_volume *mark_vol = vol;
		cd_pageset *pages;
		LOOP_OVER_LINKED_LIST(pages, cd_pageset, vol->pagesets) {
			TEMPORARY_TEXT(temp)
			if (P) {
				filename *F = Filenames::in(P, pages->source_specification);
				TextFiles::write_file_contents(temp, F);
			} else if (Str::len(pages->nonfile_content) > 0) {
				WRITE_TO(temp, "%S", pages->nonfile_content);
			}
			if (Str::is_whitespace(temp) == FALSE)
				@<Content was found for this pageset@>;
			DISCARD_TEXT(temp)
		}
	}
	
	if (cd->markdown_content == NULL) {
		cd->markdown_content = Markdown::new_item(DOCUMENT_MIT);
		cd->empty = TRUE;
	} else {
		InformFlavouredMarkdown::number_headings(cd->markdown_content);
		MarkdownVariations::assign_URLs_to_headings(cd->markdown_content, cd->link_references);
	}
}

@<Content was found for this pageset@> =
	markdown_item *subtree = Markdown::parse_block_structure_using_extended(temp,
		cd->link_references, InformFlavouredMarkdown::variation());

	if (subtree) {
		switch (pages->breaking) {
			case NO_PAGESETBREAKING:
				DocumentationCompiler::do_not_divide_tree(subtree, pages->page_specification);
				break;
			case SECTION_PAGESETBREAKING:
				DocumentationCompiler::divide_tree_by_sections(subtree, pages->page_specification);
				break;
			case CHAPTER_PAGESETBREAKING:
				DocumentationCompiler::divide_tree_by_chapters(subtree, pages->page_specification);
				break;
		}
		markdown_item *vol_marker = NULL;
		if (mark_vol) {
			vol_marker = Markdown::new_volume_marker(mark_vol->title);
			vol_marker->user_state = STORE_POINTER_cd_volume(mark_vol);
			mark_vol->volume_item = vol_marker;
			mark_vol = NULL;
		}
		if (cd->markdown_content == NULL) {
			cd->markdown_content = subtree;
			if (vol_marker) { vol_marker->next = subtree->down; subtree->down = vol_marker; }
		} else {
			markdown_item *ch = cd->markdown_content->down;
			while ((ch) && (ch->next)) ch = ch->next;
			if (vol_marker) { ch->next = vol_marker; ch = vol_marker; }
			ch->next = subtree->down;
		}
	}

@ The three strategies for breaking up the tree into chapters or sections,
if that's what we were told to do.

=
int DocumentationCompiler::do_not_divide_tree(markdown_item *tree, text_stream *naming) {
	markdown_item *file_marker = Markdown::new_file_marker(Filenames::from_text(naming));
	file_marker->next = tree->down; tree->down = file_marker;
	return TRUE;
}

int DocumentationCompiler::divide_tree_by_sections(markdown_item *tree, text_stream *naming) {
	int N = 1, C = 0;
	for (markdown_item *prev_md = NULL, *md = tree->down; md; prev_md = md, md = md->next) {
		if ((md->type == HEADING_MIT) && (Markdown::get_heading_level(md) == 1)) {
			C++; N = 1;
			if ((md->next) && (md->next->type == HEADING_MIT) &&
				(Markdown::get_heading_level(md->next) == 2)) {
				@<Divide by section here@>;
				prev_md = md; md = md->next;
			}
		} else if ((md->type == HEADING_MIT) && (Markdown::get_heading_level(md) == 2))
			@<Divide by section here@>;
	}
	return TRUE;
}

@<Divide by section here@> =
	TEMPORARY_TEXT(leaf)
	for (int i=0; i<Str::len(naming); i++) {
		inchar32_t c = Str::get_at(naming, i);
		if (c == '#') {
			if (C > 0) WRITE_TO(leaf, "%d_", C);
			WRITE_TO(leaf, "%d", N++);
		} else PUT_TO(leaf, c);
	}
	markdown_item *file_marker = Markdown::new_file_marker(Filenames::from_text(leaf));
	DISCARD_TEXT(leaf)
	if (prev_md) prev_md->next = file_marker; else tree->down = file_marker;
	file_marker->next = md;

@ =
int DocumentationCompiler::divide_tree_by_chapters(markdown_item *tree, text_stream *naming) {
	int N = 1;
	for (markdown_item *prev_md = NULL, *md = tree->down; md; prev_md = md, md = md->next) {
		if ((md->type == HEADING_MIT) && (Markdown::get_heading_level(md) == 1)) {
			TEMPORARY_TEXT(leaf)
			for (int i=0; i<Str::len(naming); i++) {
				inchar32_t c = Str::get_at(naming, i);
				if (c == '#') WRITE_TO(leaf, "%d", N++);
				else PUT_TO(leaf, c);
			}
			markdown_item *file_marker = Markdown::new_file_marker(Filenames::from_text(leaf));
			DISCARD_TEXT(leaf)
			if (prev_md) prev_md->next = file_marker; else tree->down = file_marker;
			file_marker->next = md;
		}
	}
	return TRUE;
}
