[DocumentationCompiler::] Documentation Compiler.

To compile documentation from the textual syntax in an extension into a tree.

@ We will actually wrap the result in the following structure, but
it's really not much more than a tree of Markdown:

=
typedef struct compiled_documentation {
	struct text_stream *title;
	struct text_stream *original;
	struct inform_extension *associated_extension;
	struct inform_extension *within_extension;
	struct markdown_item *alt_tree;
	int empty;
	struct linked_list *examples; /* of |satellite_test_case| */
	struct linked_list *cases; /* of |satellite_test_case| */
	CLASS_DEFINITION
} compiled_documentation;

compiled_documentation *DocumentationCompiler::new_wrapper(text_stream *source) {
	compiled_documentation *cd = CREATE(compiled_documentation);
	cd->title = Str::new();
	cd->original = Str::duplicate(source);
	cd->associated_extension = NULL;
	cd->within_extension = NULL;
	cd->alt_tree = NULL;
	cd->empty = FALSE;
	cd->examples = NEW_LINKED_LIST(IFM_example);
	cd->cases = NEW_LINKED_LIST(satellite_test_case);
	return cd;
}

typedef struct satellite_test_case {
	int is_example;
	struct text_stream *owning_heading;
	struct tree_node *owning_node;
	struct compiled_documentation *owner;
	struct text_stream *short_name;
	struct filename *test_file;
	struct filename *ideal_transcript;
	CLASS_DEFINITION
} satellite_test_case;

@ We can compile either from a file...

=
compiled_documentation *DocumentationCompiler::compile_from_path(pathname *P,
	inform_extension *associated_extension) {
	filename *F = Filenames::in(P, I"Documentation.md");
	if (TextFiles::exists(F) == FALSE) return NULL;
	compiled_documentation *cd =
		DocumentationCompiler::compile_from_file(F, associated_extension);
	if (cd == NULL) return NULL;
	pathname *EP = Pathnames::down(P, I"Examples");
	int egs = TRUE;
	@<Scan EP directory for examples@>;
	egs = FALSE;
	EP = Pathnames::down(P, I"Tests");
	@<Scan EP directory for examples@>;
	int example_number = 0;
	DocumentationCompiler::recursively_renumber_examples_r(cd->alt_tree, &example_number);
	return cd;
}

@<Scan EP directory for examples@> =
	scan_directory *D = Directories::open(EP);
	if (D) {
		TEMPORARY_TEXT(leafname)
		while (Directories::next(D, leafname)) {
			wchar_t first = Str::get_first_char(leafname), last = Str::get_last_char(leafname);
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
			satellite_test_case *stc = CREATE(satellite_test_case);
			stc->is_example = egs;
			stc->owning_heading = NULL;
			stc->owning_node = NULL;
			stc->owner = cd;
			stc->short_name = short_name;
			stc->test_file = F;
			stc->ideal_transcript = NULL;
			TEMPORARY_TEXT(ideal_leafname)
			WRITE_TO(ideal_leafname, "%S-I.txt", stc->short_name);
			filename *IF = Filenames::in(EP, ideal_leafname);
			if (TextFiles::exists(IF)) stc->ideal_transcript = IF;
			DISCARD_TEXT(ideal_leafname)
			if (stc->is_example) {
				@<Scan the example for its header and content@>;
			}
			ADD_TO_LINKED_LIST(stc, satellite_test_case, cd->cases);
		}
		DISCARD_TEXT(leafname)
		Directories::close(D);
	}

@

=
void DocumentationCompiler::recursively_renumber_examples_r(markdown_item *md, int *example_number) {
	if (md->type == INFORM_EXAMPLE_HEADING_MIT) {
		IFM_example *E = RETRIEVE_POINTER_IFM_example(md->user_state);
		int N = ++(*example_number);
		int P = 1;
		while (N > 26) { P += 1, N -= 26; }
		Str::clear(E->insignia);
		if (P > 1) WRITE_TO(E->insignia, "%d", P);
		WRITE_TO(E->insignia, "%c", 'A'+N-1);
	}
	for (markdown_item *ch = md->down; ch; ch = ch->next)
		DocumentationCompiler::recursively_renumber_examples_r(ch, example_number);
}

@

=
typedef struct example_scanning_state {
	int star_count;
	struct text_stream *long_title;
	struct text_stream *body_text;
	struct text_stream *placement;
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
	ess.desc = NULL;
	ess.errors = NEW_LINKED_LIST(markdown_item);
	ess.past_header = FALSE;
	ess.scanning = Str::new(); WRITE_TO(ess.scanning, "%S", Filenames::get_leafname(stc->test_file));
	TextFiles::read(stc->test_file, FALSE, "unable to read file of example", TRUE,
		&DocumentationCompiler::read_example_helper, NULL, &ess);

	markdown_item *alt_placement_node = NULL;
	if (Str::len(ess.placement) == 0) {
		;
	} else {
		alt_placement_node = InformFlavouredMarkdown::find_section(cd->alt_tree, ess.placement);
		if (alt_placement_node == NULL) {
			DocumentationCompiler::example_error(&ess,
				I"example gives a Location which is not the name of any section");
		}
	}

	if (Str::len(ess.desc) == 0) {
		DocumentationCompiler::example_error(&ess,
			I"example does not give its Description");
	}
	IFM_example *eg = InformFlavouredMarkdown::new_example(
		ess.long_title, ess.desc, ess.star_count, LinkedLists::len(cd->examples));
	eg->cue = alt_placement_node;
	ADD_TO_LINKED_LIST(eg, IFM_example, cd->examples);

	markdown_item *eg_header = Markdown::new_item(INFORM_EXAMPLE_HEADING_MIT);
	eg->header = eg_header;
	eg_header->user_state = STORE_POINTER_IFM_example(eg);
	markdown_item *md = alt_placement_node;
	if (md == NULL) {
		md = cd->alt_tree->down;
		if (md == NULL) cd->alt_tree->down = eg_header;
		else {
			while ((md) && (md->next)) md = md->next;
			eg_header->next = md->next; md->next = eg_header;
		}		
	} else {
		if (md->next) md = md->next;
		while ((md) && (md->next) && (md->next->type != HEADING_MIT)) md = md->next;
		eg_header->next = md->next; md->next = eg_header;
	}
	if (Str::len(ess.body_text) > 0) {
		markdown_item *alt_ecd = Markdown::parse_extended(ess.body_text,
			InformFlavouredMarkdown::variation());
		eg_header->down = alt_ecd->down;
	} else {
		DocumentationCompiler::example_error(&ess,
			I"example does not give any actual content");
	} 

	markdown_item *E;
	LOOP_OVER_LINKED_LIST(E, markdown_item, ess.errors)
		Markdown::add_to(E, cd->alt_tree);

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
		if ((Regexp::match(&mr, text, L"Example *: *(%**) *(%c+?)")) ||
			(Regexp::match(&mr, text, L"Example *- *(%**) *(%c+?)"))) {
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
		if (Regexp::match(&mr, text, L"(%C+?) *: *(%c+?)")) {
			if (Str::eq(mr.exp[0], I"Location")) ess->placement = Str::duplicate(mr.exp[1]);
			else if (Str::eq(mr.exp[0], I"Description")) ess->desc = Str::duplicate(mr.exp[1]);
			else {
				DocumentationCompiler::example_error(ess,
					I"unknown datum in header line of example file");
			}
		} else {
			DocumentationCompiler::example_error(ess,
				I"header line of example file is malformed");
		}
		Regexp::dispose_of(&mr);
	} else {
		WRITE_TO(ess->body_text, "%S\n", text);
	}
}

@

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
	else cd->alt_tree = Markdown::parse_extended(source,
		InformFlavouredMarkdown::variation());
	return cd;
}
