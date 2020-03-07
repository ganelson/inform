[Projects::] Project Services.

An Inform 7 project.

@ =
typedef struct inform_project {
	struct inbuild_copy *as_copy;
	struct semantic_version_number version;
	struct linked_list *source_vertices; /* of |build_vertex| */
	int assumed_to_be_parser_IF;
	struct linked_list *kits_to_include; /* of |inform_kit| */
	struct inform_language *language_of_play;
	struct inform_language *language_of_syntax;
	struct inform_language *language_of_index;
	struct build_vertex *unblorbed_vertex;
	struct build_vertex *blorbed_vertex;
	struct build_vertex *chosen_build_target;
	struct parse_node_tree *syntax_tree;
	int fix_rng;
	MEMORY_MANAGEMENT
} inform_project;

inform_project *Projects::new_ip(text_stream *name, filename *F, pathname *P) {
	inform_project *project = CREATE(inform_project);
	project->as_copy = NULL;
	project->version = VersionNumbers::null();
	project->source_vertices = NEW_LINKED_LIST(build_vertex);
	project->kits_to_include = NEW_LINKED_LIST(inform_kit);
	project->assumed_to_be_parser_IF = TRUE;
	project->language_of_play = NULL;
	project->language_of_syntax = NULL;
	project->language_of_index = NULL;
	project->chosen_build_target = NULL;
	project->unblorbed_vertex = NULL;
	project->blorbed_vertex = NULL;
	project->fix_rng = 0;
	project->syntax_tree = ParseTree::new_tree();
	return project;
}

void Projects::set_to_English(inform_project *proj) {
	if (proj == NULL) internal_error("no project");
	inform_language *E = NULL;
	inbuild_requirement *req = Requirements::any_version_of(Works::new(language_genre, I"English", I""));
	linked_list *L = NEW_LINKED_LIST(inbuild_search_result);
	Nests::search_for(req, Inbuild::nest_list(), L);
	inbuild_search_result *R;
	LOOP_OVER_LINKED_LIST(R, inbuild_search_result, L)
		if (E == NULL)
			E = LanguageManager::from_copy(R->copy);
	proj->language_of_play = E;
	proj->language_of_syntax = E;
	proj->language_of_index = E;
}

void Projects::set_language_of_play(inform_project *proj, inform_language *L) {
	if (proj == NULL) internal_error("no project");
	proj->language_of_play = L;
}
inform_language *Projects::get_language_of_play(inform_project *proj) {
	if (proj == NULL) return NULL;
	return proj->language_of_play;
}

void Projects::set_language_of_index(inform_project *proj, inform_language *L) {
	if (proj == NULL) internal_error("no project");
	proj->language_of_index = L;
}
inform_language *Projects::get_language_of_index(inform_project *proj) {
	if (proj == NULL) return NULL;
	return proj->language_of_index;
}

void Projects::set_language_of_syntax(inform_project *proj, inform_language *L) {
	if (proj == NULL) internal_error("no project");
	proj->language_of_syntax = L;
	#ifdef CORE_MODULE
	English_language = L;
	#endif
}
inform_language *Projects::get_language_of_syntax(inform_project *proj) {
	if (proj == NULL) return NULL;
	return proj->language_of_syntax;
}

void Projects::fix_rng(inform_project *project, int seed) {
	project->fix_rng = seed;
}

void Projects::not_necessarily_parser_IF(inform_project *project) {
	project->assumed_to_be_parser_IF = FALSE;
}

void Projects::set_source_filename(inform_project *project, pathname *P, filename *F) {
	if (P) {
		filename *manifest = Filenames::in_folder(P, I"Contents.txt");
		linked_list *L = NEW_LINKED_LIST(text_stream);
		TextFiles::read(manifest, FALSE,
			NULL, FALSE, Projects::manifest_helper, NULL, (void *) L);
		text_stream *leafname;
		LOOP_OVER_LINKED_LIST(leafname, text_stream, L) {
			build_vertex *S = Graphs::file_vertex(Filenames::in_folder(P, leafname));
			S->annotation = leafname;
			ADD_TO_LINKED_LIST(S, build_vertex, project->source_vertices);
		}
	}
	if ((LinkedLists::len(project->source_vertices) == 0) && (F)) {
		build_vertex *S = Graphs::file_vertex(F);
		S->annotation = I"your source text";
		ADD_TO_LINKED_LIST(S, build_vertex, project->source_vertices);
	}
}

void Projects::manifest_helper(text_stream *text, text_file_position *tfp, void *state) {
	linked_list *L = (linked_list *) state;
	Str::trim_white_space(text);
	wchar_t c = Str::get_first_char(text);
	if ((c == 0) || (c == '#')) return;
	ADD_TO_LINKED_LIST(Str::duplicate(text), text_stream, L);
}

pathname *Projects::path(inform_project *project) {
	if (project == NULL) return NULL;
	return project->as_copy->location_if_path;
}

linked_list *Projects::source(inform_project *project) {
	if (project == NULL) return NULL;
	return project->source_vertices;
}

void Projects::add_kit_dependency(inform_project *project, text_stream *kit_name) {
	RUN_ONLY_BEFORE_PHASE(OPERATIONAL_INBUILD_PHASE)
	if (Projects::uses_kit(project, kit_name)) return;
	linked_list *nest_list = Inbuild::nest_list();
	inform_kit *kit = Kits::load(kit_name, nest_list);
	ADD_TO_LINKED_LIST(kit, inform_kit, project->kits_to_include);
}

int Projects::uses_kit(inform_project *project, text_stream *name) {
	inform_kit *K;
	LOOP_OVER_LINKED_LIST(K, inform_kit, project->kits_to_include)
		if (Str::eq(K->as_copy->edition->work->title, name))
			return TRUE;
	return FALSE;
}

void Projects::finalise_kit_dependencies(inform_project *project) {
	Projects::add_kit_dependency(project, I"BasicInformKit");
	inform_language *L = project->language_of_play;
	if (L) {
		text_stream *kit_name = Languages::kit_name(L);
		Projects::add_kit_dependency(project, kit_name);
	}
	if (project->assumed_to_be_parser_IF)
		Projects::add_kit_dependency(project, I"CommandParserKit");

	int parity = TRUE;
	@<Perform if-this-then-that@>;
	parity = FALSE;
	@<Perform if-this-then-that@>;

	linked_list *sorted = NEW_LINKED_LIST(inform_kit);
	for (int p=0; p<100; p++) {
		inform_kit *K;
		LOOP_OVER_LINKED_LIST(K, inform_kit, project->kits_to_include)
			if (K->priority == p)
				ADD_TO_LINKED_LIST(K, inform_kit, sorted);
	}

	project->kits_to_include = sorted;
	inform_kit *K;
	LOOP_OVER_LINKED_LIST(K, inform_kit, project->kits_to_include)
		LOG("Using Inform kit '%S' (priority %d).\n", K->as_copy->edition->work->title, K->priority);
}

@<Perform if-this-then-that@> =
	int changes_made = TRUE;
	while (changes_made) {
		changes_made = FALSE;
		inform_kit *K;
		LOOP_OVER_LINKED_LIST(K, inform_kit, project->kits_to_include)
			if (Kits::perform_ittt(K, project, parity))
				changes_made = TRUE;
	}

@ =
#ifdef CORE_MODULE
void Projects::load_types(inform_project *project) {
	inform_kit *K;
	LOOP_OVER_LINKED_LIST(K, inform_kit, project->kits_to_include)
		Kits::load_types(K);
}
#endif

#ifdef CORE_MODULE
void Projects::activate_plugins(inform_project *project) {
	LOG("Activate plugins...\n");
	Plugins::Manage::activate(CORE_PLUGIN_NAME);
	inform_kit *K;
	LOOP_OVER_LINKED_LIST(K, inform_kit, project->kits_to_include)
		Kits::activate_plugins(K);
	Plugins::Manage::show(DL, "Included", TRUE);
	Plugins::Manage::show(DL, "Excluded", FALSE);
}
#endif

int Projects::Main_defined(inform_project *project) {
	inform_kit *K;
	LOOP_OVER_LINKED_LIST(K, inform_kit, project->kits_to_include)
		if (K->defines_Main)
			return TRUE;
	return FALSE;
}

text_stream *Projects::index_template(inform_project *project) {
	text_stream *I = NULL;
	inform_kit *K;
	LOOP_OVER_LINKED_LIST(K, inform_kit, project->kits_to_include)
		if (K->index_template)
			I = K->index_template;
	return I;
}

@ Every source text read into Inform is automatically prefixed by a few words
loading the fundamental "extensions" -- text such as "Include Basic Inform by
Graham Nelson." If Inform were a computer, this would be the BIOS which boots
up its operating system. Each kit can contribute such extensions, so there
may be multiple sentences, which we need to count up.

=
void Projects::early_source_text(OUTPUT_STREAM, inform_project *project) {
	inform_kit *K;
	LOOP_OVER_LINKED_LIST(K, inform_kit, project->kits_to_include)
		Kits::early_source_text(OUT, K);
}

#ifdef CODEGEN_MODULE
linked_list *Projects::list_of_inter_libraries(inform_project *project) {
	linked_list *requirements_list = NEW_LINKED_LIST(link_instruction);
	inform_kit *K;
	LOOP_OVER_LINKED_LIST(K, inform_kit, project->kits_to_include) {
LOG("Okay so K is %S\n", K->as_copy->edition->work->title);
		link_instruction *link = CodeGen::LinkInstructions::new(
			K->as_copy->location_if_path, K->attachment_point);
		ADD_TO_LINKED_LIST(link, link_instruction, requirements_list);
	}
	return requirements_list;
}
#endif

pathname *Projects::build_pathname(inform_project *project) {
	pathname *P = Projects::path(project);
	if (P) return Pathnames::subfolder(P, I"Build");
	return Inbuild::transient();
}

void Projects::construct_build_target(inform_project *project, target_vm *VM,
	int releasing, int compile_only) {
	pathname *build_folder = Projects::build_pathname(project);

	build_vertex *inter_V = Graphs::ghost_vertex(I"binary inter in memory");
	Graphs::need_this_to_build(inter_V, project->as_copy->vertex);
	BuildSteps::attach(inter_V, compile_using_inform7_skill,
		Inbuild::nest_list(), releasing, VM, NULL, project->as_copy);

	filename *inf_F = Filenames::in_folder(build_folder, I"auto.inf");
	build_vertex *inf_V = Graphs::file_vertex(inf_F);
	Graphs::need_this_to_build(inf_V, inter_V);
	BuildSteps::attach(inf_V, code_generate_using_inter_skill,
		Inbuild::nest_list(), releasing, VM, NULL, project->as_copy);

	TEMPORARY_TEXT(story_file_leafname);
	WRITE_TO(story_file_leafname, "output.%S", TargetVMs::get_unblorbed_extension(VM));
	filename *unblorbed_F = Filenames::in_folder(build_folder, story_file_leafname);
	DISCARD_TEXT(story_file_leafname);
	project->unblorbed_vertex = Graphs::file_vertex(unblorbed_F);
	Graphs::need_this_to_build(project->unblorbed_vertex, inf_V);
	BuildSteps::attach(project->unblorbed_vertex, compile_using_inform6_skill,
		Inbuild::nest_list(), releasing, VM, NULL, project->as_copy);

	TEMPORARY_TEXT(story_file_leafname2);
	WRITE_TO(story_file_leafname2, "output.%S", TargetVMs::get_blorbed_extension(VM));
	filename *blorbed_F = Filenames::in_folder(build_folder, story_file_leafname2);
	DISCARD_TEXT(story_file_leafname2);
	project->blorbed_vertex = Graphs::file_vertex(blorbed_F);
	project->blorbed_vertex->force_this = TRUE;
	Graphs::need_this_to_build(project->blorbed_vertex, project->unblorbed_vertex);
	BuildSteps::attach(project->blorbed_vertex, package_using_inblorb_skill,
		Inbuild::nest_list(), releasing, VM, NULL, project->as_copy);

	if (compile_only) {
		project->chosen_build_target = inf_V;
		inf_V->force_this = TRUE;
		inter_V->force_this = TRUE;
	} else if (releasing) project->chosen_build_target = project->blorbed_vertex;
	else project->chosen_build_target = project->unblorbed_vertex;
}

void Projects::construct_graph(inform_project *project) {
	RUN_ONLY_IN_PHASE(GOING_OPERATIONAL_INBUILD_PHASE)
	if (project == NULL) return;
	build_vertex *V = project->as_copy->vertex;
	inform_kit *K;
	LOOP_OVER_LINKED_LIST(K, inform_kit, project->kits_to_include) {
		 Graphs::need_this_to_build(V, K->as_copy->vertex);
	}
	build_vertex *S;
	LOOP_OVER_LINKED_LIST(S, build_vertex, project->source_vertices) {
		 Graphs::need_this_to_build(V, S);
	}
	inform_language *L = project->language_of_play;
	if (L) {
		build_vertex *LV = L->as_copy->vertex;
		Graphs::need_this_to_build(V, LV);
	}
	L = project->language_of_syntax;
	if (L) {
		build_vertex *LV = L->as_copy->vertex;
		Graphs::need_this_to_build(V, LV);
	}
	L = project->language_of_index;
	if (L) {
		build_vertex *LV = L->as_copy->vertex;
		Graphs::need_this_to_build(V, LV);
	}
}

@

@e BadTitleSentence_SYNERROR

=
int rstf_run_before = FALSE;
void Projects::read_source_text_for(inform_project *project) {
LOG("Running rstf\n");
	if (rstf_run_before) internal_error("twice!");
	rstf_run_before = TRUE;

	Projects::finalise_kit_dependencies(project);

	parse_node *inclusions_heading = ParseTree::new(HEADING_NT);
	ParseTree::set_text(inclusions_heading, Feeds::feed_text_expanding_strings(L"Implied inclusions"));
	ParseTree::insert_sentence(project->syntax_tree, inclusions_heading);
	#ifdef CORE_MODULE
	ParseTree::annotate_int(inclusions_heading, sentence_unparsed_ANNOT, FALSE);
	ParseTree::annotate_int(inclusions_heading, heading_level_ANNOT, 0);
	Headings::declare(project->syntax_tree, inclusions_heading);
	#endif

	int wc = lexer_wordcount, bwc = -1;
	TEMPORARY_TEXT(early);
	Projects::early_source_text(early, project);
	if (Str::len(early) > 0) Feeds::feed_stream(early);
	DISCARD_TEXT(early);
	inbuild_nest *E = Inbuild::external();
	if (E) Projects::read_further_mandatory_text(
		Filenames::in_folder(E->location, I"Options.txt"));
	wording early_W = Wordings::new(wc, lexer_wordcount-1);
	
	int l = ParseTree::push_attachment_point(project->syntax_tree, inclusions_heading);
	Sentences::break(project->syntax_tree, early_W, FALSE, project->as_copy, bwc);
	ParseTree::pop_attachment_point(project->syntax_tree, l);
	
	wc = lexer_wordcount;
	linked_list *L = Projects::source(project);
	if (L) {
		build_vertex *N;
		LOOP_OVER_LINKED_LIST(N, build_vertex, L) {
			filename *F = N->buildable_if_internal_file;
			if (bwc == -1) bwc = lexer_wordcount;
			N->read_as = SourceText::read_file(project->as_copy, F, N->annotation,
				FALSE, TRUE);
		}
	}
	l = ParseTree::push_attachment_point(project->syntax_tree, project->syntax_tree->root_node);
	Sentences::break(project->syntax_tree, Wordings::new(wc, lexer_wordcount-1), FALSE, project->as_copy, bwc);
	ParseTree::pop_attachment_point(project->syntax_tree, l);

	l = ParseTree::push_attachment_point(project->syntax_tree, project->syntax_tree->root_node);
	parse_node *implicit_heading = ParseTree::new(HEADING_NT);
	ParseTree::set_text(implicit_heading, Feeds::feed_text_expanding_strings(L"Invented sentences"));
	ParseTree::insert_sentence(project->syntax_tree, implicit_heading);
	#ifdef CORE_MODULE
	ParseTree::annotate_int(implicit_heading, sentence_unparsed_ANNOT, FALSE);
	ParseTree::annotate_int(implicit_heading, heading_level_ANNOT, 0);
	Headings::declare(project->syntax_tree, implicit_heading);
	#endif
	ParseTree::pop_attachment_point(project->syntax_tree, l);
	
	ParseTree::push_attachment_point(project->syntax_tree, implicit_heading);
}

@ It might seem sensible to parse the opening sentence of the source text,
the bibliographic sentence giving title and author, by looking at the result
of sentence-breaking above. But this isn't fast enough, because the sentence
also specifies the language used, and we need to know of any non-Engkish
choice immediately. So a special hook in the |syntax| module calls the
following routine as soon as |BIBLIOGRAPHIC_NT| sentence is found; thus,
it happens during the call to |Sentences::break| above.

@ =
void Projects::notify_of_bibliographic_sentence(inform_project *project, parse_node *PN) {
	wording W = ParseTree::get_text(PN);
	if (<titling-line>(W)) {
		text_stream *T = project->as_copy->edition->work->title;
		if (project->as_copy->edition->work->author_name == NULL)
			project->as_copy->edition->work->author_name = Str::new();
		text_stream *A = project->as_copy->edition->work->author_name;
		inform_language *L = <<rp>>;
		if (L) {
			Projects::set_language_of_play(project, L);
			LOG("Language of play: %S\n", L->as_copy->edition->work->title);
		}
		@<Extract title and author name wording@>;
		@<Dequote the title and, perhaps, author name@>;
	} else {
		copy_error *CE = Copies::new_error(SYNTAX_CE, NULL);
		CE->error_subcategory = BadTitleSentence_SYNERROR;
		CE->details_node = PN;
		Copies::attach(project->as_copy, CE);
	}
}

@ This is what the top line of the main source text should look like, if it's
to declare the title and author.

=
<titling-line> ::=
	<plain-titling-line> ( in <natural-language> ) |	==> R[1]; *XP = RP[2];
	<plain-titling-line>								==> R[1]; *XP = NULL;

<plain-titling-line> ::=
	{<quoted-text-without-subs>} by ... |	==> TRUE
	{<quoted-text-without-subs>}			==> FALSE

@<Extract title and author name wording@> =
	wording TW = GET_RW(<plain-titling-line>, 1);
	wording AW = EMPTY_WORDING;
	if (<<r>>) AW = GET_RW(<plain-titling-line>, 2);
	Str::clear(T);
	WRITE_TO(T, "%+W", TW);
	if (Wordings::nonempty(AW)) {
		Str::clear(A);
		WRITE_TO(A, "%+W", AW);
	}

@ The author is sometimes given outside of quotation marks:

>> "The Large Scale Structure of Space-Time" by Lindsay Lohan

But not always:

>> "Greek Rural Postmen and Their Cancellation Numbers" by "will.i.am"

@<Dequote the title and, perhaps, author name@> =
	Str::trim_white_space(T);
	if ((Str::get_first_char(T) == '\"') && (Str::get_last_char(T) == '\"')) {
		Str::delete_first_character(T);
		Str::delete_last_character(T);
		Str::trim_white_space(T);
	}
	LOG("Title: %S\n", T);
	Str::trim_white_space(A);
	if ((Str::get_first_char(A) == '\"') && (Str::get_last_char(A) == '\"')) {
		Str::delete_first_character(A);
		Str::delete_last_character(A);
		Str::trim_white_space(A);
	}
	if (Str::len(A) > 0) LOG("Author: %S\n", A);

@ When Inform reads the (optional!) Options file, very early in its run, it
tries to obey any use options in the file right away -- earlier even than
<structural-sentence>. It spots these, very crudely, as sentences which
match the following (that is, which start with "use"). Note the final full
stop -- it's needed before sentence-breaking has even taken place.

=
<use-option-sentence-shape> ::=
	use ... .

wording options_file_wording = EMPTY_WORDING_INIT;

void Projects::read_further_mandatory_text(filename *F) {
	feed_t id = Feeds::begin();
	TextFiles::read(F, TRUE,
		NULL, FALSE, Projects::read_further_mandatory_text_helper, NULL, NULL);
	options_file_wording = Feeds::end(id);
}

void Projects::read_further_mandatory_text_helper(text_stream *line,
	text_file_position *tfp, void *unused_state) {
	WRITE_TO(line, "\n");
	wording W = Feeds::feed_stream(line);
	if (<use-option-sentence-shape>(W)) {
		#ifdef CORE_MODULE
		UseOptions::set_immediate_option_flags(W, NULL);
		#endif
	}
}

int Projects::draws_from_source_file(inform_project *project, source_file *sf) {
	linked_list *L = Projects::source(project);
	if (L) {
		build_vertex *N;
		LOOP_OVER_LINKED_LIST(N, build_vertex, L)
			if (sf == N->read_as)
				return TRUE;
	}
	return FALSE;
}
