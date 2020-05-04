[Projects::] Project Services.

Behaviour specific to copies of either the projectbundle or projectfile genres.

@h Scanning metadata.
Metadata for pipelines -- or rather, the complete lack of same -- is stored
in the following structure.

=
typedef struct inform_project {
	struct inbuild_copy *as_copy;
	struct semantic_version_number version;
	struct linked_list *source_vertices; /* of |build_vertex| */
	int assumed_to_be_parser_IF;
	struct linked_list *kits_to_include; /* of |kit_dependency| */
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

@ This is called as soon as a new copy |C| of the language genre is created.
It doesn't actually do any scanning to speak of, in fact: we may eventually
learn a lot about the project, but for now we simply initialise to bland
placeholders.

=
void Projects::scan(inbuild_copy *C) {
	inform_project *proj = CREATE(inform_project);
	proj->as_copy = C;
	if (C == NULL) internal_error("no copy to scan");
	Copies::set_metadata(C, STORE_POINTER_inform_project(proj));

	proj->version = VersionNumbers::null();
	proj->source_vertices = NEW_LINKED_LIST(build_vertex);
	proj->kits_to_include = NEW_LINKED_LIST(kit_dependency);
	proj->assumed_to_be_parser_IF = TRUE;
	proj->language_of_play = NULL;
	proj->language_of_syntax = NULL;
	proj->language_of_index = NULL;
	proj->chosen_build_target = NULL;
	proj->unblorbed_vertex = NULL;
	proj->blorbed_vertex = NULL;
	proj->fix_rng = 0;
	proj->syntax_tree = ParseTree::new_tree();
}

@h The project's languages.
All projects are by default in English, which is one reason it plays a special
role compared to other natural languages: the other is that the Basic Inform
and Standard Rules extensions are written in English as well.

=
void Projects::set_to_English(inform_project *proj) {
	if (proj == NULL) internal_error("no project");
	inform_language *E = Languages::internal_English();
	if (E) {
		proj->language_of_play = E;
		proj->language_of_syntax = E;
		proj->language_of_index = E;
	} else internal_error("built-in English language definition can't be found'");
}

@ Inform's ability to work outside of English is limited, at present, but for
the sake of future improvements we want to distinguish three uses of natural
language. In principle, a project could use different languages for each of
these.

First, the "language of play" is the one in which dialogue is printed and parsed
at run-time.

=
void Projects::set_language_of_play(inform_project *proj, inform_language *L) {
	if (proj == NULL) internal_error("no project");
	proj->language_of_play = L;
}
inform_language *Projects::get_language_of_play(inform_project *proj) {
	if (proj == NULL) return NULL;
	return proj->language_of_play;
}

@ Second, the "language of index" is the one in which the Index of a project is
written.

=
void Projects::set_language_of_index(inform_project *proj, inform_language *L) {
	if (proj == NULL) internal_error("no project");
	proj->language_of_index = L;
}
inform_language *Projects::get_language_of_index(inform_project *proj) {
	if (proj == NULL) return NULL;
	return proj->language_of_index;
}

@ Third, the "language of syntax" is the one in which the source text of a
project is written. For the Basic Inform extension, for example, it is English.

=
void Projects::set_language_of_syntax(inform_project *proj, inform_language *L) {
	if (proj == NULL) internal_error("no project");
	proj->language_of_syntax = L;
}
inform_language *Projects::get_language_of_syntax(inform_project *proj) {
	if (proj == NULL) return NULL;
	return proj->language_of_syntax;
}

@h Miscellaneous metadata.
A project marked "fix RNG" will be compiled with the random-number generator
initially set to the seed value at run-time. (This sounds like work too junior
for a build manager to do, but it's controlled by a command-line switch,
and that means it's not beneath our notice.)

=
void Projects::fix_rng(inform_project *project, int seed) {
	project->fix_rng = seed;
}

@ A project with no explicit Inter kit dependencies is assumed to be meant
as a work of traditional parser IF. So, if the user does make an explicit kit
dependency, the following function is called, to tell us not to assume that:

=
void Projects::not_necessarily_parser_IF(inform_project *project) {
	project->assumed_to_be_parser_IF = FALSE;
}

@ The file-system path to the project. For a "bundle" made by the Inform GUI
apps, the bundle itself is a directory (even if this is concealed from the
user on macOS) and the following returns that path. For a loose file of
Inform source text, it's the directory in which the file is found. (This is
a 2020 change of policy: previously it was the CWD. The practical difference
is small, but one likes to minimise the effect of the CWD.)

=
pathname *Projects::path(inform_project *project) {
	if (project == NULL) return NULL;
	if (project->as_copy->location_if_path)
		return project->as_copy->location_if_path;
	return Filenames::up(project->as_copy->location_if_file);
}

pathname *Projects::build_path(inform_project *project) {
	if (project->as_copy->location_if_path)
		return Pathnames::down(Projects::path(project), I"Build");
	return Supervisor::transient();
}

void Projects::set_source_filename(inform_project *project, pathname *P, filename *F) {
	if (P) {
		filename *manifest = Filenames::in(P, I"Contents.txt");
		linked_list *L = NEW_LINKED_LIST(text_stream);
		TextFiles::read(manifest, FALSE,
			NULL, FALSE, Projects::manifest_helper, NULL, (void *) L);
		text_stream *leafname;
		LOOP_OVER_LINKED_LIST(leafname, text_stream, L) {
			build_vertex *S = Graphs::file_vertex(Filenames::in(P, leafname));
			S->source_source = leafname;
			ADD_TO_LINKED_LIST(S, build_vertex, project->source_vertices);
		}
	}
	if ((LinkedLists::len(project->source_vertices) == 0) && (F)) {
		build_vertex *S = Graphs::file_vertex(F);
		S->source_source = I"your source text";
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

linked_list *Projects::source(inform_project *project) {
	if (project == NULL) return NULL;
	return project->source_vertices;
}

typedef struct kit_dependency {
	struct inform_kit *kit;
	struct inform_language *because_of_language;
	struct inform_kit *because_of_kit;
	MEMORY_MANAGEMENT
} kit_dependency;

void Projects::add_kit_dependency(inform_project *project, text_stream *kit_name,
	inform_language *because_of_language, inform_kit *because_of_kit) {
	RUN_ONLY_BEFORE_PHASE(OPERATIONAL_INBUILD_PHASE)
	if (Projects::uses_kit(project, kit_name)) return;
	kit_dependency *kd = CREATE(kit_dependency);
	kd->kit = Kits::find_by_name(kit_name, Supervisor::nest_list());
	kd->because_of_language = because_of_language;
	kd->because_of_kit = because_of_kit;
	ADD_TO_LINKED_LIST(kd, kit_dependency, project->kits_to_include);
}

int Projects::uses_kit(inform_project *project, text_stream *name) {
	kit_dependency *kd;
	LOOP_OVER_LINKED_LIST(kd, kit_dependency, project->kits_to_include)
		if (Str::eq(kd->kit->as_copy->edition->work->title, name))
			return TRUE;
	return FALSE;
}

void Projects::finalise_kit_dependencies(inform_project *project) {
	Projects::add_kit_dependency(project, I"BasicInformKit", NULL, NULL);
	inform_language *L = project->language_of_play;
	if (L) {
		text_stream *kit_name = Languages::kit_name(L);
		Projects::add_kit_dependency(project, kit_name, L, NULL);
	}
	if (project->assumed_to_be_parser_IF)
		Projects::add_kit_dependency(project, I"CommandParserKit", NULL, NULL);

	int parity = TRUE;
	@<Perform if-this-then-that@>;
	parity = FALSE;
	@<Perform if-this-then-that@>;

	linked_list *sorted = NEW_LINKED_LIST(kit_dependency);
	for (int p=0; p<100; p++) {
		kit_dependency *kd;
		LOOP_OVER_LINKED_LIST(kd, kit_dependency, project->kits_to_include)
			if (kd->kit->priority == p)
				ADD_TO_LINKED_LIST(kd, kit_dependency, sorted);
	}
	project->kits_to_include = sorted;

	kit_dependency *kd;
	LOOP_OVER_LINKED_LIST(kd, kit_dependency, project->kits_to_include)
		LOG("Using Inform kit '%S' (priority %d).\n", kd->kit->as_copy->edition->work->title, kd->kit->priority);
}

@<Perform if-this-then-that@> =
	int changes_made = TRUE;
	while (changes_made) {
		changes_made = FALSE;
		kit_dependency *kd;
		LOOP_OVER_LINKED_LIST(kd, kit_dependency, project->kits_to_include)
			if (Kits::perform_ittt(kd->kit, project, parity))
				changes_made = TRUE;
	}

@ =
#ifdef CORE_MODULE
void Projects::load_types(inform_project *project) {
	kit_dependency *kd;
	LOOP_OVER_LINKED_LIST(kd, kit_dependency, project->kits_to_include)
		Kits::load_types(kd->kit);
}
#endif

@h Language element activation.
Note that this function is meaningful only when this module is part of the
|inform7| executable, and it invites us to activate or deactivate language
features according to what our kits tell us.

=
#ifdef CORE_MODULE
void Projects::activate_elements(inform_project *project) {
	LOG("Activate elements...\n");
	Plugins::Manage::activate(CORE_PLUGIN_NAME);
	kit_dependency *kd;
	LOOP_OVER_LINKED_LIST(kd, kit_dependency, project->kits_to_include)
		Kits::activate_elements(kd->kit);
	Plugins::Manage::show(DL, "Included", TRUE);
	Plugins::Manage::show(DL, "Excluded", FALSE);
}
#endif

int Projects::Main_defined(inform_project *project) {
	kit_dependency *kd;
	LOOP_OVER_LINKED_LIST(kd, kit_dependency, project->kits_to_include)
		if (kd->kit->defines_Main)
			return TRUE;
	return FALSE;
}

text_stream *Projects::index_structure(inform_project *project) {
	text_stream *I = NULL;
	kit_dependency *kd;
	LOOP_OVER_LINKED_LIST(kd, kit_dependency, project->kits_to_include)
		if (kd->kit->index_structure)
			I = kd->kit->index_structure;
	return I;
}

@ Every source text read into Inform is automatically prefixed by a few words
loading the fundamental "extensions" -- text such as "Include Basic Inform by
Graham Nelson." If Inform were a computer, this would be the BIOS which boots
up its operating system. Each kit can contribute such extensions, so there
may be multiple sentences, which we need to count up.

=
void Projects::early_source_text(OUTPUT_STREAM, inform_project *project) {
	kit_dependency *kd;
	LOOP_OVER_LINKED_LIST(kd, kit_dependency, project->kits_to_include)
		Kits::early_source_text(OUT, kd->kit);
}

#ifdef CODEGEN_MODULE
linked_list *Projects::list_of_inter_libraries(inform_project *project) {
	linked_list *requirements_list = NEW_LINKED_LIST(link_instruction);
	kit_dependency *kd;
	LOOP_OVER_LINKED_LIST(kd, kit_dependency, project->kits_to_include) {
		inform_kit *K = kd->kit;
		link_instruction *link = CodeGen::LinkInstructions::new(
			K->as_copy->location_if_path, K->attachment_point);
		ADD_TO_LINKED_LIST(link, link_instruction, requirements_list);
	}
	return requirements_list;
}
#endif

void Projects::construct_build_target(inform_project *project, target_vm *VM,
	int releasing, int compile_only) {
	pathname *build_folder = Projects::build_path(project);
	filename *inf_F = Filenames::in(build_folder, I"auto.inf");

	build_vertex *inter_V = Graphs::file_vertex(inf_F);
	Graphs::need_this_to_build(inter_V, project->as_copy->vertex);
	BuildSteps::attach(inter_V, compile_using_inform7_skill,
		Supervisor::nest_list(), releasing, VM, NULL, project->as_copy);

	build_vertex *inf_V = Graphs::file_vertex(inf_F);
	Graphs::need_this_to_build(inf_V, inter_V);
	BuildSteps::attach(inf_V, code_generate_using_inter_skill,
		Supervisor::nest_list(), releasing, VM, NULL, project->as_copy);

	TEMPORARY_TEXT(story_file_leafname);
	WRITE_TO(story_file_leafname, "output.%S", TargetVMs::get_unblorbed_extension(VM));
	filename *unblorbed_F = Filenames::in(build_folder, story_file_leafname);
	DISCARD_TEXT(story_file_leafname);
	project->unblorbed_vertex = Graphs::file_vertex(unblorbed_F);
	Graphs::need_this_to_build(project->unblorbed_vertex, inf_V);
	BuildSteps::attach(project->unblorbed_vertex, compile_using_inform6_skill,
		Supervisor::nest_list(), releasing, VM, NULL, project->as_copy);

	TEMPORARY_TEXT(story_file_leafname2);
	WRITE_TO(story_file_leafname2, "output.%S", TargetVMs::get_blorbed_extension(VM));
	filename *blorbed_F = Filenames::in(build_folder, story_file_leafname2);
	DISCARD_TEXT(story_file_leafname2);
	project->blorbed_vertex = Graphs::file_vertex(blorbed_F);
	project->blorbed_vertex->always_build_this = TRUE;
	Graphs::need_this_to_build(project->blorbed_vertex, project->unblorbed_vertex);
	BuildSteps::attach(project->blorbed_vertex, package_using_inblorb_skill,
		Supervisor::nest_list(), releasing, VM, NULL, project->as_copy);

	if (compile_only) {
		project->chosen_build_target = inf_V;
		inf_V->always_build_this = TRUE;
	} else if (releasing) project->chosen_build_target = project->blorbed_vertex;
	else project->chosen_build_target = project->unblorbed_vertex;
}

void Projects::graph_dependent_kit(inform_project *project, build_vertex *V, kit_dependency *kd, int use) {
	build_vertex *KV = kd->kit->as_copy->vertex;
	if (use) Graphs::need_this_to_use(V, KV);
	else Graphs::need_this_to_build(V, KV);
	kit_dependency *kd2;
	LOOP_OVER_LINKED_LIST(kd2, kit_dependency, project->kits_to_include)
		if ((kd2->because_of_kit == kd->kit) && (kd2->because_of_language == NULL))
			Projects::graph_dependent_kit(project, KV, kd2, TRUE);
}

void Projects::graph_dependent_language(inform_project *project, build_vertex *V, inform_language *L, int use) {
	build_vertex *LV = L->as_copy->vertex;
	if (use) Graphs::need_this_to_use(V, LV);
	else Graphs::need_this_to_build(V, LV);
	kit_dependency *kd2;
	LOOP_OVER_LINKED_LIST(kd2, kit_dependency, project->kits_to_include)
		if ((kd2->because_of_kit == NULL) && (kd2->because_of_language == L))
			Projects::graph_dependent_kit(project, LV, kd2, TRUE);
}

void Projects::construct_graph(inform_project *project) {
	RUN_ONLY_IN_PHASE(GRAPH_CONSTRUCTION_INBUILD_PHASE)
	if (project == NULL) return;
	build_vertex *V = project->as_copy->vertex;
	build_vertex *S;
	LOOP_OVER_LINKED_LIST(S, build_vertex, project->source_vertices) {
		 Graphs::need_this_to_build(V, S);
	}
	kit_dependency *kd;
	LOOP_OVER_LINKED_LIST(kd, kit_dependency, project->kits_to_include)
		if ((kd->because_of_kit == NULL) && (kd->because_of_language == NULL))
			Projects::graph_dependent_kit(project, V, kd, FALSE);
	inform_language *L = project->language_of_play;
	if (L) Projects::graph_dependent_language(project, V, L, FALSE);
	L = project->language_of_syntax;
	if (L) Projects::graph_dependent_language(project, V, L, FALSE);
	L = project->language_of_index;
	if (L) Projects::graph_dependent_language(project, V, L, FALSE);
}

@

@e BadTitleSentence_SYNERROR

=
void Projects::read_source_text_for(inform_project *project) {
	Projects::finalise_kit_dependencies(project);

	parse_node *inclusions_heading = ParseTree::new(HEADING_NT);
	ParseTree::set_text(inclusions_heading,
		Feeds::feed_text_expanding_strings(L"Implied inclusions"));
	ParseTree::insert_sentence(project->syntax_tree, inclusions_heading);
	ParseTree::annotate_int(inclusions_heading, sentence_unparsed_ANNOT, FALSE);
	ParseTree::annotate_int(inclusions_heading, heading_level_ANNOT, 0);
	ParseTree::annotate_int(inclusions_heading, implied_heading_ANNOT, TRUE);
	Headings::declare(project->syntax_tree, inclusions_heading);

	int wc = lexer_wordcount;
	TEMPORARY_TEXT(early);
	Projects::early_source_text(early, project);
	if (Str::len(early) > 0) Feeds::feed_stream(early);
	DISCARD_TEXT(early);
	inbuild_nest *E = Supervisor::external();
	if (E) Projects::read_further_mandatory_text(
		Filenames::in(E->location, I"Options.txt"));
	wording early_W = Wordings::new(wc, lexer_wordcount-1);
	
	int l = ParseTree::push_attachment_point(project->syntax_tree, inclusions_heading);
	Sentences::break_into_project_copy(project->syntax_tree, early_W, project->as_copy);
	ParseTree::pop_attachment_point(project->syntax_tree, l);
	
	wc = lexer_wordcount;
	int start_set = FALSE;
	linked_list *L = Projects::source(project);
	if (L) {
		build_vertex *N;
		LOOP_OVER_LINKED_LIST(N, build_vertex, L) {
			filename *F = N->as_file;
			if (start_set == FALSE) {
				start_set = TRUE;
				Sentences::set_start_of_source(lexer_wordcount);
			}
			N->as_source_file = SourceText::read_file(project->as_copy, F, N->source_source,
				FALSE, TRUE);
		}
	}
	l = ParseTree::push_attachment_point(project->syntax_tree, project->syntax_tree->root_node);
	Sentences::break_into_project_copy(project->syntax_tree, Wordings::new(wc, lexer_wordcount-1), project->as_copy);
	ParseTree::pop_attachment_point(project->syntax_tree, l);

	l = ParseTree::push_attachment_point(project->syntax_tree, project->syntax_tree->root_node);
	parse_node *implicit_heading = ParseTree::new(HEADING_NT);
	ParseTree::set_text(implicit_heading, Feeds::feed_text_expanding_strings(L"Invented sentences"));
	ParseTree::insert_sentence(project->syntax_tree, implicit_heading);
	ParseTree::annotate_int(implicit_heading, sentence_unparsed_ANNOT, FALSE);
	ParseTree::annotate_int(implicit_heading, heading_level_ANNOT, 0);
	Headings::declare(project->syntax_tree, implicit_heading);
	ParseTree::pop_attachment_point(project->syntax_tree, l);
	
	ParseTree::push_attachment_point(project->syntax_tree, implicit_heading);
	
	#ifdef CORE_MODULE
	Projects::activate_elements(project);
	#endif
	Inclusions::traverse(project->as_copy, project->syntax_tree);
	Headings::satisfy_dependencies(project->syntax_tree, project->as_copy);

	#ifndef CORE_MODULE
	Copies::list_attached_errors(STDERR, project->as_copy);
	#endif
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
		copy_error *CE = CopyErrors::new(SYNTAX_CE, BadTitleSentence_SYNERROR);
		CopyErrors::supply_node(CE, PN);
		Copies::attach_error(project->as_copy, CE);
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
			if (sf == N->as_source_file)
				return TRUE;
	}
	return FALSE;
}
