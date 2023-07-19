[DocumentationCompiler::] Documentation Compiler.

To compile documentation from the textual syntax in an extension into a tree.

@ We will actually wrap the result in the following structure, but
it's really not much more than the tree produced by //Documentation Tree//:

=
typedef struct compiled_documentation {
	struct text_stream *title;
	struct text_stream *original;
	struct inform_extension *associated_extension;
	struct heterogeneous_tree *tree;
	int total_headings[3];
	int total_examples;
	int empty;
	CLASS_DEFINITION
} compiled_documentation;

compiled_documentation *DocumentationCompiler::new_wrapper(text_stream *source) {
	compiled_documentation *cd = CREATE(compiled_documentation);
	cd->title = Str::new();
	cd->original = Str::duplicate(source);
	cd->associated_extension = NULL;
	cd->tree = DocumentationTree::new();
	cd->total_examples = 0;
	cd->total_headings[0] = 1;
	cd->total_headings[1] = 0;
	cd->total_headings[2] = 0;
	cd->empty = FALSE;
	return cd;
}

@ We can compile either from a file...

=
compiled_documentation *DocumentationCompiler::compile_from_file(filename *F,
	inform_extension *associated_extension) {
	TEMPORARY_TEXT(temp)
	TextFiles::read(F, FALSE, "unable to read file of documentation", TRUE,
		&DocumentationCompiler::read_file_helper, NULL, temp);
	compiled_documentation *cd =
		DocumentationCompiler::compile(temp, associated_extension);
	DISCARD_TEXT(temp)
	return cd;
}

void DocumentationCompiler::read_file_helper(text_stream *text, text_file_position *tfp,
	void *v_state) {
	text_stream *contents = (text_stream *) v_state;
	WRITE_TO(contents, "%S\n", text);
}

@ ...or from text:

=
compiled_documentation *DocumentationCompiler::compile(text_stream *source,
	inform_extension *associated_extension) {
	SVEXPLAIN(1, "(compiling documentation: %d chars)\n", Str::len(source));
	compiled_documentation *cd = DocumentationCompiler::new_wrapper(source);
	cd->associated_extension = associated_extension;
	if (cd->associated_extension)
		WRITE_TO(cd->title, "%X", cd->associated_extension->as_copy->edition->work);
	if (Str::is_whitespace(source)) cd->empty = TRUE;
	else @<Parse the source@>;
	if (cd->empty) {
		SVEXPLAIN(1, "(resulting tree is empty)\n");
	} else {
		SVEXPLAIN(1, "(resulting tree has %d chapter(s), %d section(s) and %d example(s))\n", 
			cd->total_headings[1], cd->total_headings[2], cd->total_examples);
	}
	return cd;
}

@ The source material is line-based, with semantic content sometimes spreading
across multiple lines, so we'll need to keep track of some state as we read
one line at a time:

@<Parse the source@> =
	int chapter_number = 0, section_number = 0;

	tree_node *current_headings[4]; /* Most recent headings of levels 0, 1, 2 */
	current_headings[0] = cd->tree->root; /* This will never change */
	current_headings[1] = NULL; /* Latest chapter, if any */
	current_headings[2] = NULL; /* Latest section in most recent thing of lower level */
	current_headings[3] = NULL; /* Latest example in most recent thing of lower level */
	
	tree_node *current_passage = NULL,     /* passage being assembled, if any */
			  *current_phrase_defn = NULL, /* again, if any */
			  *current_paragraph = NULL,
			  *current_code = NULL,
			  *last_paste_code = NULL;     /* last code sample with a paste button */

	int pending_code_sample_blanks = 0, code_is_tabular = FALSE; /* used only when assembling code samples */
	programming_language *default_language = DocumentationCompiler::get_language(I"Inform");
	programming_language *language = default_language;

	@<Parse the source linewise@>;

@ Leading space on a line is removed but not ignored: it is converted into an
indentation level, measured as a tab count, using the exchange rate 4 spaces
to 1 tab.

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
	@<Check for runaway phrase definitions@>;
	@<Complete passage if in one@>;
	DISCARD_TEXT(line)

@ Trailing space is ignored and removed.

Lines which are unindented and take the following shapes are headings:
= (text)
	Chapter: Survey and Prospecting
	Section: Black Gold
	Example: *** Gelignite Anderson - A Tale of the Texas Oilmen
=
where in each case the colon can equally be a hyphen, and with optional
space either side.

Otherwise, lines are divided into blanks, which always end paragraphs but
may either end or continue code samples; unindented lines, which are always
part of paragraphs; or indented ones, which are always part of code samples.

@<Line read@> =
	Str::trim_white_space(line);
	if (Str::len(line) == 0) {
		if (current_paragraph) @<Complete paragraph or code@>;
		if (current_code) @<Insert line break in code@>;
	} else if (indentation == 0) {
		match_results mr = Regexp::create_mr();
		if ((Regexp::match(&mr, line, L"Section *: *(%c+?)")) ||
			(Regexp::match(&mr, line, L"Section *- *(%c+?)"))) {
			@<Insert a section heading@>;
		} else if ((Regexp::match(&mr, line, L"Chapter *: *(%c+?)")) ||
			(Regexp::match(&mr, line, L"Chapter *- *(%c+?)"))) {
			@<Insert a chapter heading@>;
		} else if ((Regexp::match(&mr, line, L"Example *: *(%**) *(%c+?)")) ||
			(Regexp::match(&mr, line, L"Example *- *(%**) *(%c+?)"))) {
			@<Insert an example heading@>;
		} else if (Regexp::match(&mr, line, L"{defn *(%c*?)} *(%c+)")) {
			@<Begin a phrase definition@>;
		} else if (Regexp::match(&mr, line, L"{end}")) {
			@<End a phrase definition@>;
		} else {
			if (current_paragraph == NULL) @<Begin paragraph@>;
			@<Insert space in paragraph@>;
			@<Insert line in paragraph@>;
		}
		Regexp::dispose_of(&mr);
	} else {
		if (current_code == NULL) {		
			if ((Str::get_at(line, 0) == '{') && (Str::get_at(line, 1) == 'a') &&
				(Str::get_at(line, 2) == 's') && (Str::get_at(line, 3) == ' ') &&
				(Str::get_at(line, Str::len(line)-1) == '}')) {
				Str::delete_n_characters(line, 4);
				Str::delete_last_character(line);
				Str::trim_white_space(line);
				language = DocumentationCompiler::get_language(line);
				if (language == NULL) {
					@<Complete paragraph or code@>;
					@<Begin passage if not already in one@>;
					TEMPORARY_TEXT(err)
					WRITE_TO(err, "cannot find a language called '%S'", line);
					tree_node *E = DocumentationTree::new_source_error(cd->tree, err);
					Trees::make_child(E, current_passage);
					DISCARD_TEXT(err)
				}
			} else {
				@<Begin code@>;
				@<Insert line in code sample@>;
			}
		} else {
			@<Insert line in code sample@>;
		}
	}

@<Insert a chapter heading@> =
	@<Complete passage if in one@>;
	chapter_number++;
	section_number = 0;
	int level = 1, id = cd->total_headings[0] + cd->total_headings[1] + cd->total_headings[2];
	cd->total_headings[1]++;
	tree_node *new_node = DocumentationTree::new_heading(cd->tree, mr.exp[0], level,
		id, chapter_number, section_number);
	@<Place this new structural node in the tree@>;

@<Insert a section heading@> =
	@<Complete passage if in one@>;
	section_number++;
	int level = 2, id = cd->total_headings[0] + cd->total_headings[1] + cd->total_headings[2];
	cd->total_headings[2]++;
	tree_node *new_node = DocumentationTree::new_heading(cd->tree, mr.exp[0], level,
		id, chapter_number, section_number);
	@<Place this new structural node in the tree@>;

@<Insert an example heading@> =
	@<Complete passage if in one@>;
	int level = 3, star_count = Str::len(mr.exp[0]);
	tree_node *new_node = DocumentationTree::new_example(cd->tree, mr.exp[1],
		star_count, ++(cd->total_examples));
	@<Place this new structural node in the tree@>;
	if (star_count == 0) {
		@<Begin passage if not already in one@>;
		tree_node *E = DocumentationTree::new_source_error(cd->tree,
			I"this example should be marked (before the title) '*', '**', '***' or '****' for difficulty");
		Trees::make_child(E, current_passage);
	}
	if (star_count > 4) {
		@<Begin passage if not already in one@>;
		tree_node *E = DocumentationTree::new_source_error(cd->tree,
			I"four stars '****' is the maximum difficulty rating allowed");
		Trees::make_child(E, current_passage);
	}

@<Begin a phrase definition@> =
	@<Check for runaway phrase definitions@>;
	if (current_phrase_defn == NULL) {
		@<Begin passage if not already in one@>;
		@<Complete paragraph or code@>;
		current_phrase_defn =
			DocumentationTree::new_phrase_defn(cd->tree, mr.exp[0], mr.exp[1]);
		Trees::make_child(current_phrase_defn, current_passage);
		@<Complete passage if in one@>;
	}

@<End a phrase definition@> =
	if (current_phrase_defn) {
		@<Complete passage if in one@>;
		current_passage = current_phrase_defn->parent;
		current_phrase_defn = NULL;
	} else {
		@<Begin passage if not already in one@>;
		tree_node *E = DocumentationTree::new_source_error(cd->tree,
			I"{end} without {defn}");
		Trees::make_child(E, current_passage);
	}
	language = default_language;

@<Place this new structural node in the tree@> =
	@<Check for runaway phrase definitions@>;
	for (int j=level-1; j>=0; j--)
		if (current_headings[j]) {
			Trees::make_child(new_node, current_headings[j]);
			break;
		}
	current_headings[level] = new_node;
	for (int j=level+1; j<4; j++) current_headings[j] = NULL;
	language = default_language;

@<Check for runaway phrase definitions@> =
	if (current_phrase_defn) {
		@<Begin passage if not already in one@>;
		tree_node *E = DocumentationTree::new_source_error(cd->tree,
			I"{defn} has no {end}");
		Trees::make_child(E, current_passage);
		current_phrase_defn = NULL;
	}

@<Begin passage if not already in one@> =
	if (current_passage == NULL) {
		current_passage = DocumentationTree::new_passage(cd->tree);
		if (current_phrase_defn)
			Trees::make_child(current_passage, current_phrase_defn);
		else for (int j=3; j>=0; j--)
			if (current_headings[j]) {
				Trees::make_child(current_passage, current_headings[j]);
				break;
			}
		current_paragraph = NULL;
	}

@<Complete passage if in one@> =
	if (current_passage) {
		@<Complete paragraph or code@>;
		current_passage = NULL;
	}

@<Complete paragraph or code@> =
	if (current_paragraph) @<Complete paragraph@>
	if (current_code) @<Complete code@>

@ Line breaks are treated as spaces in the content of a paragraph, so that
|P->content| here can be a long text but one which contains no line breaks.

@<Begin paragraph@> =
	@<Complete paragraph or code@>;
	@<Begin passage if not already in one@>;
	current_paragraph = DocumentationTree::new_paragraph(cd->tree, NULL);
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

@ Line breaks are more significant in code samples, of course. Blank lines
at the end of a code sample are stripped out; and they cannot appear at the start
of a code sample either, since a non-blank indented line is needed to trigger one.

@<Begin code@> =
	@<Complete paragraph or code@>;
	@<Begin passage if not already in one@>;

	int paste_me = FALSE, continue_me = FALSE;
	if ((Str::get_at(line, 0) == '*') &&
		(Str::get_at(line, 1) == ':')) {
		Str::delete_first_character(line);
		Str::delete_first_character(line);
		Str::trim_white_space(line);
		paste_me = TRUE;
	} else if ((Str::get_at(line, 0) == '*') &&
		(Str::get_at(line, 1) == '*') &&
		(Str::get_at(line, 2) == ':')) {
		Str::delete_first_character(line);
		Str::delete_first_character(line);
		Str::delete_first_character(line);
		Str::trim_white_space(line);
		continue_me = TRUE;
	}
	current_code = DocumentationTree::new_code_sample(cd->tree, paste_me, language);
	if (continue_me) {
		if (last_paste_code) {
			cdoc_code_sample *S = RETRIEVE_POINTER_cdoc_code_sample(last_paste_code->content);
			S->continuation = current_code;
		} else {
			tree_node *E = DocumentationTree::new_source_error(cd->tree, I"cannot continue a paste here");
			Trees::make_child(E, current_passage);
		}
	}
	if ((paste_me) || (continue_me)) {
		last_paste_code = current_code;
	} else {
		last_paste_code = NULL;
	}
	Trees::make_child(current_code, current_passage);
	pending_code_sample_blanks = 0;
	code_is_tabular = FALSE;

@<Insert line break in code@> =
	if (current_code->child) {
		pending_code_sample_blanks++;
		code_is_tabular = FALSE;
	}

@<Insert line in code sample@> =
	for (int i=0; i<pending_code_sample_blanks; i++)
		Trees::make_child(DocumentationTree::new_code_line(cd->tree, NULL, 0, FALSE), current_code);
	pending_code_sample_blanks = 0;
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, line, L"Table %c*")) {
		code_is_tabular = TRUE;
	}
	Regexp::dispose_of(&mr);
	Trees::make_child(DocumentationTree::new_code_line(cd->tree, line, indentation-1, code_is_tabular),
		current_code);

@<Complete code@> =
	if (current_code) {
		current_code = NULL;
		code_is_tabular = FALSE;
	}

@

=
programming_language *DocumentationCompiler::get_language(text_stream *name) {
	inbuild_nest *N = Supervisor::internal();
	if (N == NULL) return NULL;
	pathname *LP = Pathnames::down(Nests::get_location(N), I"PLs");
	Languages::set_default_directory(LP);
	programming_language *pl = Languages::find_by_name(name, NULL, FALSE);
	if (pl == NULL) LOG("Did not load %S!\n", name);
	return pl;
}
