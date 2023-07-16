[DocumentationCompiler::] Documentation Compiler.

To compile documentation from an extension into a useful internal format
for rendering out.

@

=
typedef struct compiled_documentation {
	struct text_stream *original;
	struct inform_extension *associated_extension;
	struct heterogeneous_tree *content;
	int empty;
	CLASS_DEFINITION
} compiled_documentation;

tree_type *cdoc_tree_TT = NULL;
tree_node_type *heading_TNT = NULL, *example_TNT = NULL,
	*passage_TNT = NULL, *paragraph_TNT = NULL, *code_sample_TNT = NULL, *code_line_TNT = NULL;

typedef struct cdoc_heading {
	struct text_stream *count;
	struct text_stream *name;
	int level; /* 0 = root, 1 = chapter, 2 = section */
	int ID;
	CLASS_DEFINITION
} cdoc_heading;

tree_node *DocumentationCompiler::new_heading(heterogeneous_tree *tree,
	text_stream *title, int level, int ID, int cc, int sc) {
	cdoc_heading *H = CREATE(cdoc_heading);
	H->count = Str::new();
	if (cc > 0) WRITE_TO(H->count, "%d", cc);
	if ((cc > 0) && (sc > 0)) WRITE_TO(H->count, ".");
	if (sc > 0) WRITE_TO(H->count, "%d", sc);
	H->name = Str::duplicate(title);
	H->level = level;
	H->ID = ID;
	return Trees::new_node(tree, heading_TNT, STORE_POINTER_cdoc_heading(H));
}

typedef struct cdoc_example {
	struct text_stream *name;
	int star_count;
	int number;
	char letter;
	CLASS_DEFINITION
} cdoc_example;

tree_node *DocumentationCompiler::new_example(heterogeneous_tree *tree,
	text_stream *title, int star_count, int ecount) {
	cdoc_example *E = CREATE(cdoc_example);
	E->name = Str::duplicate(title);
	E->star_count = star_count;
	E->number = ecount;
	E->letter = 'A' + (char) ecount - 1;
	return Trees::new_node(tree, example_TNT, STORE_POINTER_cdoc_example(E));
}

typedef struct cdoc_passage {
	CLASS_DEFINITION
} cdoc_passage;

tree_node *DocumentationCompiler::new_passage(heterogeneous_tree *tree) {
	cdoc_passage *P = CREATE(cdoc_passage);
	return Trees::new_node(tree, passage_TNT, STORE_POINTER_cdoc_passage(P));
}

typedef struct cdoc_paragraph {
	struct text_stream *content;
	CLASS_DEFINITION
} cdoc_paragraph;

tree_node *DocumentationCompiler::new_paragraph(heterogeneous_tree *tree,
	text_stream *content) {
	cdoc_paragraph *P = CREATE(cdoc_paragraph);
	P->content = Str::duplicate(content);
	return Trees::new_node(tree, paragraph_TNT, STORE_POINTER_cdoc_paragraph(P));
}

typedef struct cdoc_code_sample {
	CLASS_DEFINITION
} cdoc_code_sample;

tree_node *DocumentationCompiler::new_code_sample(heterogeneous_tree *tree) {
	cdoc_code_sample *C = CREATE(cdoc_code_sample);
	return Trees::new_node(tree, code_sample_TNT, STORE_POINTER_cdoc_code_sample(C));
}

typedef struct cdoc_code_line {
	struct text_stream *content;
	int indentation;
	CLASS_DEFINITION
} cdoc_code_line;

tree_node *DocumentationCompiler::new_code_line(heterogeneous_tree *tree,
	text_stream *content, int indentation) {
	cdoc_code_line *C = CREATE(cdoc_code_line);
	C->content = Str::duplicate(content);
	C->indentation = indentation;
	return Trees::new_node(tree, code_line_TNT, STORE_POINTER_cdoc_code_line(C));
}

heterogeneous_tree *DocumentationCompiler::new_tree(void) {
	if (cdoc_tree_TT == NULL) {
		cdoc_tree_TT = Trees::new_type(I"documentation tree", &DocumentationCompiler::verify_root);
		heading_TNT = Trees::new_node_type(I"heading", cdoc_heading_CLASS, &DocumentationCompiler::heading_verifier);
		example_TNT = Trees::new_node_type(I"example", cdoc_example_CLASS, &DocumentationCompiler::example_verifier);
		passage_TNT = Trees::new_node_type(I"passage", cdoc_passage_CLASS, &DocumentationCompiler::passage_verifier);
		paragraph_TNT = Trees::new_node_type(I"paragraph", cdoc_paragraph_CLASS, &DocumentationCompiler::paragraph_verifier);
		code_sample_TNT = Trees::new_node_type(I"code sample", cdoc_code_sample_CLASS, &DocumentationCompiler::code_sample_verifier);
		code_line_TNT = Trees::new_node_type(I"line", cdoc_code_line_CLASS, &DocumentationCompiler::code_line_verifier);
	}
	heterogeneous_tree *tree = Trees::new(cdoc_tree_TT);
	Trees::make_root(tree, DocumentationCompiler::new_heading(tree, I"(root)", 0, 0, 0, 0));
	return tree;
}

int DocumentationCompiler::verify_root(tree_node *N) {
	if ((N == NULL) || (N->type != heading_TNT) || (N->next))
		return FALSE;
	return TRUE;
}

int DocumentationCompiler::heading_verifier(tree_node *N) {
	for (tree_node *C = N->child; C; C = C->next) {
		if ((C->type != heading_TNT) && (C->type != example_TNT) && (C->type != passage_TNT))
			return FALSE;
		if ((C->type == passage_TNT) && (C->next)) return FALSE;
	}
	return TRUE;
}

int DocumentationCompiler::example_verifier(tree_node *N) {
	if ((N->child == NULL) || (N->child->type != passage_TNT) || (N->child->next))
		return FALSE;
	return TRUE;
}

int DocumentationCompiler::passage_verifier(tree_node *N) {
	for (tree_node *C = N->child; C; C = C->next)
		if ((C->type != paragraph_TNT) && (C->type != code_sample_TNT))
			return FALSE;
	return TRUE;
}

int DocumentationCompiler::paragraph_verifier(tree_node *N) {
	if (N->child) return FALSE; /* This must be a leaf node */
	return TRUE;
}

int DocumentationCompiler::code_sample_verifier(tree_node *N) {
	for (tree_node *C = N->child; C; C = C->next)
		if (C->type != code_line_TNT)
			return FALSE;
	if (N->child == NULL) return FALSE;
	return TRUE;
}

int DocumentationCompiler::code_line_verifier(tree_node *N) {
	if (N->child) return FALSE; /* This must be a leaf node */
	return TRUE;
}

@ =
void DocumentationCompiler::show_tree(text_stream *OUT, heterogeneous_tree *T) {
	WRITE("%S\n", T->type->name);
	WRITE("--------\n");
	INDENT;
	Trees::traverse_from(T->root, &DocumentationCompiler::visit, (void *) DL, 0);
	OUTDENT;
	WRITE("--------\n");
}

int DocumentationCompiler::visit(tree_node *N, void *state, int L) {
	text_stream *OUT = (text_stream *) state;
	for (int i=0; i<L; i++) WRITE("    ");
	if (N->type == heading_TNT) {
		cdoc_heading *H = RETRIEVE_POINTER_cdoc_heading(N->content);
		WRITE("Heading H%d level %d: '%S'\n", H->ID, H->level, H->name);
	} else if (N->type == example_TNT) {
		cdoc_example *E = RETRIEVE_POINTER_cdoc_example(N->content);
		WRITE("Example: '%S' (%d star(s))\n", E->name, E->star_count);
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

@

=
compiled_documentation *DocumentationCompiler::compile(text_stream *source,
	inform_extension *associated_extension) {
	if (Str::len(source) == 0) return NULL;
	compiled_documentation *cd = CREATE(compiled_documentation);
	cd->original = Str::duplicate(source);
	cd->associated_extension = associated_extension;
	cd->content = DocumentationCompiler::new_tree();
	tree_node *current_headings[3], *current_holder = NULL,
		*current_passage = cd->content->root, *current_paragraph = NULL, *current_code = NULL;
	current_headings[0] = cd->content->root;
	current_headings[1] = NULL;
	current_headings[2] = NULL;
	int pending_code_sample_blanks = 0, heading_ID = 1, ccount = 0, scount = 0, ecount = 0;
	@<Parse the source linewise@>;
	cd->empty = FALSE;
	if (Str::is_whitespace(source)) cd->empty = TRUE;
	SVEXPLAIN(1, "(compiling documentation: %d chars)\n", Str::len(source));
	SVEXPLAIN(3, "(from source...)\n%S\n(...end of source)\n", source);
DocumentationCompiler::show_tree(DL, cd->content);
	return cd;
}

@<Parse the source linewise@> =
	TEMPORARY_TEXT(line)
	int indentation = 0, space_count = 0;
	for (int i=0; i<Str::len(source); i++) {
		wchar_t c = Str::get_at(source, i);
		if (c == '\n') {
			@<Line read@>;
			Str::clear(line);
			indentation = 0; space_count = 0;
		} else if ((Str::len(line) == 0) && (Characters::is_whitespace(c))) {
			if (c == '\t') indentation++;
			if (c == ' ') space_count++;
			if (space_count == 4) { indentation++; space_count = 0; }
		} else {
			PUT_TO(line, c);
		}
	}
	if (Str::len(line) > 0) @<Line read@>;
	@<Complete passage@>;
	DISCARD_TEXT(line)

@<Line read@> =
	Str::trim_white_space(line);
	if (Str::len(line) == 0) {
		if (current_paragraph) @<Complete paragraph or code@>;
		if (current_code) @<Insert line break in code@>;
	} else if (indentation == 0) {
		match_results mr = Regexp::create_mr();
		if (Regexp::match(&mr, line, L"Section *: *(%c+?)")) {
			scount++;
			tree_node *s_node = DocumentationCompiler::new_heading(cd->content, mr.exp[0], 2, heading_ID++, ccount, scount);
			if (current_headings[1] == NULL) LOG("*** No chapter for section '%S'***\n", mr.exp[0]);
			Trees::make_child(s_node, current_headings[1]);
			current_headings[2] = s_node;
			@<Complete passage@>;
			current_holder = s_node;
		} else if (Regexp::match(&mr, line, L"Chapter *: *(%c+?)")) {
			ccount++;
			scount = 0;
			tree_node *c_node = DocumentationCompiler::new_heading(cd->content, mr.exp[0], 1, heading_ID++, ccount, scount);
			Trees::make_child(c_node, current_headings[0]);
			current_headings[1] = c_node;
			current_headings[2] = NULL;
			@<Complete passage@>;
			current_holder = c_node;
		} else if (Regexp::match(&mr, line, L"Example *: *(%**) *(%c+?)")) {
			ecount++;
			tree_node *e_node = DocumentationCompiler::new_example(cd->content, mr.exp[1], Str::len(mr.exp[0]), ecount);
			for (int j=2; j>=0; j--)
				if (current_headings[j]) {
					Trees::make_child(e_node, current_headings[j]);
					break;
				}
			current_holder = e_node;
			@<Complete passage@>;
		} else {
			if (current_paragraph == NULL) @<Begin paragraph@>;
			@<Insert space in paragraph@>;
			@<Insert line in paragraph@>;
		}
		Regexp::dispose_of(&mr);
	} else {
		if (current_code == NULL) @<Begin code@>
		@<Insert line in code sample@>;
	}

@<Begin passage@> =
	if (current_passage == NULL) {
		current_passage = DocumentationCompiler::new_passage(cd->content);
		Trees::make_child(current_passage, current_holder);
		current_paragraph = NULL;
	}

@<Complete passage@> =
	current_passage = NULL;
	@<Complete paragraph or code@>;

@<Complete paragraph or code@> =
	if (current_paragraph) @<Complete paragraph@>
	if (current_code) @<Complete code@>

@<Begin paragraph@> =
	@<Complete paragraph or code@>;
	@<Begin passage@>;
	current_paragraph = DocumentationCompiler::new_paragraph(cd->content, NULL);
	Trees::make_child(current_paragraph, current_passage);

@<Insert space in paragraph@> =
	cdoc_paragraph *P = RETRIEVE_POINTER_cdoc_paragraph(current_paragraph->content);
	if (Str::len(P->content) > 0) WRITE_TO(P->content, " ");

@<Insert line in paragraph@> =
	cdoc_paragraph *P = RETRIEVE_POINTER_cdoc_paragraph(current_paragraph->content);
	WRITE_TO(P->content, "%S", line);

@<Complete paragraph@> =
	if (current_paragraph) {
		current_paragraph = NULL;
	}

@<Begin code@> =
	@<Complete paragraph or code@>;
	@<Begin passage@>;
	current_code = DocumentationCompiler::new_code_sample(cd->content);
	Trees::make_child(current_code, current_passage);
	pending_code_sample_blanks = 0;

@<Insert line break in code@> =
	if (current_code->child) pending_code_sample_blanks++;

@<Insert line in code sample@> =
	for (int i=0; i<pending_code_sample_blanks; i++)
		Trees::make_child(DocumentationCompiler::new_code_line(cd->content, NULL, 0), current_code);
	pending_code_sample_blanks = 0;
	Trees::make_child(DocumentationCompiler::new_code_line(cd->content, line, indentation-1), current_code);

@<Complete code@> =
	if (current_code) {
		current_code = NULL;
	}

@

=
void DocumentationCompiler::render(pathname *P, compiled_documentation *cd, text_stream *extras) {
	if (cd == NULL) return;
	text_stream *OUT = DocumentationCompiler::open_subpage(P, I"index.html");
	inform_extension *E = cd->associated_extension;
	InformPages::header(OUT, I"Extension", JAVASCRIPT_FOR_ONE_EXTENSION_IRES, NULL);
	HTML::incorporate_HTML(OUT, InstalledFiles::filename(EXTENSION_DOCUMENTATION_MODEL_IRES));
	@<Write documentation for a specific extension into the page@>;
	InformPages::footer(OUT);
	DocumentationCompiler::close_subpage();
}

text_stream DOCF_struct;
text_stream *DOCF = NULL;

text_stream *DocumentationCompiler::open_subpage(pathname *P, text_stream *leaf) {
	if (P == NULL) return STDOUT;
	if (DOCF) internal_error("nested DC writes");
	filename *F = Filenames::in(P, leaf);
	DOCF = &DOCF_struct;
	if (STREAM_OPEN_TO_FILE(DOCF, F, UTF8_ENC) == FALSE)
		return NULL; /* if we lack permissions, e.g., then write no documentation */
	return DOCF;
}

void DocumentationCompiler::close_subpage(void) {
	if (DOCF == NULL) internal_error("no DC page open");
	if (DOCF != STDOUT) STREAM_CLOSE(DOCF);
	DOCF = NULL;
}

@<Write documentation for a specific extension into the page@> =
	if (E) {
		inbuild_edition *edition = E->as_copy->edition;
		inbuild_work *work = edition->work;
		HTML_OPEN("p");
		if (Works::is_standard_rules(work) == FALSE)
			@<Write Javascript paste icon for source text to include this extension@>;
		WRITE("<b>");
		Works::write_to_HTML_file(OUT, work, TRUE);
		WRITE("</b>");
		HTML_CLOSE("p");
		HTML_OPEN("p");
		HTML::begin_span(OUT, I"smaller");
		@<Write up any restrictions on VM usage@>;
		@<Write up the version number, if any, and location@>;
		HTML::end_span(OUT);
		HTML_CLOSE("p");
		@<Write up the rubric, if any@>;
	}
	if (cd->empty) {
		HTML_OPEN("p");
		WRITE("There is no documentation.");
		HTML_CLOSE("p");
	} else {
		@<Write up the table of contents for the supplied documentation, if any@>;
		WRITE("%S", extras);
		@<Write up the supplied documentation, if any@>;
	}

@<Write Javascript paste icon for source text to include this extension@> =
	TEMPORARY_TEXT(inclusion_text)
	WRITE_TO(inclusion_text, "Include %X.\n\n\n", work);
	PasteButtons::paste_text(OUT, inclusion_text);
	DISCARD_TEXT(inclusion_text)
	WRITE("&nbsp;");

@<Write up any restrictions on VM usage@> =
	compatibility_specification *C = E->as_copy->edition->compatibility;
	if (Str::len(C->parsed_from) > 0) {
		WRITE("%S", C->parsed_from);
	}

@<Write up the version number, if any, and location@> =
	semantic_version_number V = E->as_copy->edition->version;
	if (VersionNumbers::is_null(V) == FALSE) WRITE("Version %v", &V);
	if (E->loaded_from_built_in_area) {
		if (VersionNumbers::is_null(V)) { WRITE("Extension"); }
		WRITE(" built in to Inform");
	}

@<Write up the rubric, if any@> =
	if (Str::len(E->rubric_as_lexed) > 0) {
		HTML_OPEN("p"); WRITE("%S", E->rubric_as_lexed); HTML_CLOSE("p");
	}
	if (Str::len(E->extra_credit_as_lexed) > 0) {
		HTML_OPEN("p"); WRITE("<i>%S</i>", E->extra_credit_as_lexed); HTML_CLOSE("p");
	}

@ This appears above the definition paragraphs because it tends to be only
large extensions which provide TOCs: and they, ipso facto, make many definitions.
If the TOC were directly at the top of the supplied documentation, it might
easily be scrolled down off screen when the user first visits the page.

@<Write up the table of contents for the supplied documentation, if any@> =
	Trees::traverse_from(cd->content->root, &DocumentationCompiler::toc, (void *) OUT, 0);

@<Write up the supplied documentation, if any@> =
	HTML_OPEN("pre");
	WRITE("%S\n", cd->original);
	HTML_CLOSE("pre");

@

=
int DocumentationCompiler::toc(tree_node *N, void *state, int L) {
	text_stream *OUT = (text_stream *) state;
	if (N->type == heading_TNT) {
		cdoc_heading *H = RETRIEVE_POINTER_cdoc_heading(N->content);
		if (H->level > 0) {
			if (H->ID == 1) HTML_TAG("hr"); /* ruled line at top of TOC */
			HTML_OPEN("p");
			HTML::begin_span(OUT, I"indexblack");
			HTML_OPEN("b");
			HTML_OPEN_WITH("a", "style=\"text-decoration: none\" href=#docsec%d", H->ID);
			if (H->level == 1) WRITE("Chapter %S: ", H->count);
			else WRITE("Section %S: ", H->count);
			HTML_CLOSE("a");
			HTML_CLOSE("b");
			HTML::end_span(OUT);
			WRITE("%S", H->name);
			HTML_CLOSE("p");
		}
	}
	if (N->type == example_TNT) {
		cdoc_example *E = RETRIEVE_POINTER_cdoc_example(N->content);
		TEMPORARY_TEXT(link)
		WRITE_TO(link, "style=\"text-decoration: none\" href=\"eg%d.html#eg%d\"",
			E->number, E->number);
		HTML::begin_span(OUT, I"indexblack");
		HTML_OPEN_WITH("a", "%S", link);
		PUT(E->letter); /* the letter A to Z */
		WRITE(" &mdash; ");
		WRITE("%S", E->name);
		HTML_CLOSE("a");
		HTML::end_span(OUT);
		DISCARD_TEXT(link)
	}
	return TRUE;
}
