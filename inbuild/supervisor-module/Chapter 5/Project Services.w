[Projects::] Project Services.

Behaviour specific to copies of either the projectbundle or projectfile genres.

@h Scanning metadata.
Metadata for pipelines -- or rather, the complete lack of same -- is stored
in the following structure.

=
typedef struct inform_project {
	struct inbuild_copy *as_copy;
	int stand_alone; /* rather than being in a .inform project bundle */
	struct inbuild_nest *materials_nest;
	struct linked_list *search_list; /* of |inbuild_nest| */
	struct filename *primary_source;
	struct filename *primary_output;
	struct semantic_version_number version;
	struct linked_list *source_vertices; /* of |build_vertex| */
	struct linked_list *kits_to_include; /* of |kit_dependency| */
	struct inform_language *language_of_play;
	struct inform_language *language_of_syntax;
	struct inform_language *language_of_index;
	struct build_vertex *unblorbed_vertex;
	struct build_vertex *blorbed_vertex;
	struct build_vertex *chosen_build_target;
	struct parse_node_tree *syntax_tree;
	struct linked_list *extensions_included; /* of |inform_extension| */
	int fix_rng;
	int compile_for_release;
	int compile_only;
	CLASS_DEFINITION
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
	proj->stand_alone = FALSE;
	proj->version = VersionNumbers::null();
	proj->source_vertices = NEW_LINKED_LIST(build_vertex);
	proj->kits_to_include = NEW_LINKED_LIST(kit_dependency);
	proj->language_of_play = NULL;
	proj->language_of_syntax = NULL;
	proj->language_of_index = NULL;
	proj->chosen_build_target = NULL;
	proj->unblorbed_vertex = NULL;
	proj->blorbed_vertex = NULL;
	proj->fix_rng = 0;
	proj->compile_for_release = FALSE;
	proj->compile_only = FALSE;
	proj->syntax_tree = SyntaxTree::new();
	pathname *P = Projects::path(proj), *M;
	if (proj->as_copy->location_if_path)
		M = Projects::materialise_pathname(
			Pathnames::up(P), Pathnames::directory_name(P));
	else
		M = Projects::materialise_pathname(
			P, Filenames::get_leafname(proj->as_copy->location_if_file));
	proj->materials_nest = Supervisor::add_nest(M, MATERIALS_NEST_TAG);
	proj->search_list = NEW_LINKED_LIST(inbuild_nest);
	proj->primary_source = NULL;
	proj->extensions_included = NEW_LINKED_LIST(inform_extension);
}

@ The materials folder sits alongside the project and has the same name,
but ending |.materials| instead of |.inform|.

=
pathname *Projects::materialise_pathname(pathname *in, text_stream *leaf) {
	TEMPORARY_TEXT(mf)
	WRITE_TO(mf, "%S", leaf);
	int i = Str::len(mf)-1;
	while ((i>0) && (Str::get_at(mf, i) != '.')) i--;
	if (i>0) {
		Str::truncate(mf, i);
		WRITE_TO(mf, ".materials");
	}
	pathname *materials = Pathnames::down(in, mf);
	DISCARD_TEXT(mf)
	return materials;
}

@ Returns |TRUE| for a project arising from a single file, |FALSE| for a
project in a |.inform| bundle. (Withing the UI apps, then, all projects return
|FALSE| here; it's only command-line use of Inform which involves stand-alone files.)

=
int Projects::stand_alone(inform_project *proj) {
	if (proj == NULL) return FALSE;
	return proj->stand_alone;
}

@ The file-system path to the project. For a "bundle" made by the Inform GUI
apps, the bundle itself is a directory (even if this is concealed from the
user on macOS) and the following returns that path. For a loose file of
Inform source text, it's the directory in which the file is found. (This is
a 2020 change of policy: previously it was the CWD. The practical difference
is small, but one likes to minimise the effect of the CWD.)

=
pathname *Projects::path(inform_project *proj) {
	if (proj == NULL) return NULL;
	if (proj->as_copy->location_if_path)
		return proj->as_copy->location_if_path;
	return Filenames::up(proj->as_copy->location_if_file);
}

pathname *Projects::build_path(inform_project *proj) {
	if (proj->as_copy->location_if_path)
		return Pathnames::down(Projects::path(proj), I"Build");
	return Supervisor::transient();
}

inbuild_nest *Projects::materials_nest(inform_project *proj) {
	if (proj == NULL) return NULL;
	return proj->materials_nest;
}

pathname *Projects::materials_path(inform_project *proj) {
	if (proj == NULL) return NULL;
	return proj->materials_nest->location;
}

@ Each project has its own search list of nests, but this always consists of,
first, its own Materials nest, and then the shared search list. For timing
reasons, this list is created on demand.

=
linked_list *Projects::nest_list(inform_project *proj) {
	if (proj == NULL) return Supervisor::shared_nest_list();
	RUN_ONLY_FROM_PHASE(NESTED_INBUILD_PHASE)
	if (LinkedLists::len(proj->search_list) == 0) {
		ADD_TO_LINKED_LIST(proj->materials_nest, inbuild_nest, proj->search_list);
		inbuild_nest *N;
		linked_list *L = Supervisor::shared_nest_list();
		LOOP_OVER_LINKED_LIST(N, inbuild_nest, L)
			ADD_TO_LINKED_LIST(N, inbuild_nest, proj->search_list);
	}
	return proj->search_list;
}

@h Files of source text.
A project can have multiple files of I7 source text, but more usually it
has a single, "primary", one.

=
void Projects::set_primary_source(inform_project *proj, filename *F) {
	proj->primary_source = F;
}

filename *Projects::get_primary_source(inform_project *proj) {
	return proj->primary_source;
}

@ The following constructs the list of "source vertices" -- vertices in the
build graph representing the source files -- on demand. The reason this isn't
done automatically when the |proj| is created is that we needed to give time
for someone to call //Projects::set_primary_source//, since that will affect
the outcome.

=
linked_list *Projects::source(inform_project *proj) {
	if (proj == NULL) return NULL;
	if (LinkedLists::len(proj->source_vertices) == 0)
		@<Try a set of source files from the Source subdirectory of Materials@>;
	if (LinkedLists::len(proj->source_vertices) == 0)
		@<Try the source file set at the command line, if any was@>;
	if (LinkedLists::len(proj->source_vertices) == 0)
		@<Fall back on the traditional choice@>;
	return proj->source_vertices;
}

@<Try a set of source files from the Source subdirectory of Materials@> =
	pathname *P = NULL;
	if (proj->as_copy->location_if_path)
		P = Pathnames::down(Projects::materials_path(proj), I"Source");
	if (P) {
		filename *manifest = Filenames::in(P, I"Contents.txt");
		linked_list *L = NEW_LINKED_LIST(text_stream);
		TextFiles::read(manifest, FALSE,
			NULL, FALSE, Projects::manifest_helper, NULL, (void *) L);
		text_stream *leafname;
		LOOP_OVER_LINKED_LIST(leafname, text_stream, L) {
			build_vertex *S = Graphs::file_vertex(Filenames::in(P, leafname));
			S->source_source = leafname;
			ADD_TO_LINKED_LIST(S, build_vertex, proj->source_vertices);
		}
	}

@ =
void Projects::manifest_helper(text_stream *text, text_file_position *tfp, void *state) {
	linked_list *L = (linked_list *) state;
	Str::trim_white_space(text);
	wchar_t c = Str::get_first_char(text);
	if ((c == 0) || (c == '#')) return;
	ADD_TO_LINKED_LIST(Str::duplicate(text), text_stream, L);
}

@<Try the source file set at the command line, if any was@> =
	if (proj->primary_source) {
		build_vertex *S = Graphs::file_vertex(proj->primary_source);
		S->source_source = I"your source text";
		ADD_TO_LINKED_LIST(S, build_vertex, proj->source_vertices);
	}

@ If a bundle is found, then by default the source text within it is called
|story.ni|. The |.ni| is an anachronism now, but at one time stood for
"natural Inform", the working title for Inform 7 in the early 2000s.

@<Fall back on the traditional choice@> =
	filename *F = proj->as_copy->location_if_file;
	if (proj->as_copy->location_if_path)
		F = Filenames::in(
				Pathnames::down(proj->as_copy->location_if_path, I"Source"),
				I"story.ni");
	build_vertex *S = Graphs::file_vertex(F);
	S->source_source = I"your source text";
	ADD_TO_LINKED_LIST(S, build_vertex, proj->source_vertices);

@ The //inform7// compiler sometimes wants to know whether a particular
source file belongs to the project or not, so:

=
int Projects::draws_from_source_file(inform_project *proj, source_file *sf) {
	if (proj == NULL) return FALSE;
	linked_list *L = Projects::source(proj);
	if (L == NULL) return FALSE;
	build_vertex *S;
	LOOP_OVER_LINKED_LIST(S, build_vertex, L)
		if (sf == S->as_source_file)
			return TRUE;
	return FALSE;
}

@h The project's languages.
Inform's ability to work outside of English is limited, at present, but for
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

@ And this is where these are decided.

=
void Projects::set_languages(inform_project *proj) {
	if (proj == NULL) internal_error("no project");
	inform_language *E = Languages::find_for(I"English", Projects::nest_list(proj));
	if (E) {
		proj->language_of_play = E;
		proj->language_of_syntax = E;
		proj->language_of_index = E;
	} else internal_error("built-in English language definition can't be found");
}

@h Miscellaneous metadata.
The following function transfers some of the command-line options into settings
for a specific project.

A project marked "fix RNG" will be compiled with the random-number generator
initially set to the seed value at run-time. (This sounds like work too junior
for a build manager to do, but it's controlled by a command-line switch,
and that means it's not beneath our notice.)

=
void Projects::set_compilation_options(inform_project *proj, int r, int co, int rng) {
	proj->compile_for_release = r;
	proj->compile_only = co;
	proj->fix_rng = rng;
	Projects::set_languages(proj);
	Supervisor::pass_kit_requests(proj);
}

int Projects::currently_releasing(inform_project *proj) {
	if (proj == NULL) return FALSE;
	return proj->compile_for_release;
}

@h Kit dependencies.
It is a practical impossibility to compile a story file without at least one
kit of pre-compiled Inter to merge into it, so all projects will depend on
at least one kit, and probably several.

=
typedef struct kit_dependency {
	struct inform_kit *kit;
	struct inform_language *because_of_language;
	struct inform_kit *because_of_kit;
	CLASS_DEFINITION
} kit_dependency;

@ =
void Projects::add_kit_dependency(inform_project *project, text_stream *kit_name,
	inform_language *because_of_language, inform_kit *because_of_kit) {
	if (Projects::uses_kit(project, kit_name)) return;
	kit_dependency *kd = CREATE(kit_dependency);
	kd->kit = Kits::find_by_name(kit_name, Projects::nest_list(project));
	kd->because_of_language = because_of_language;
	kd->because_of_kit = because_of_kit;
	ADD_TO_LINKED_LIST(kd, kit_dependency, project->kits_to_include);
}

@ This can also be used to test on the fly:

=
int Projects::uses_kit(inform_project *project, text_stream *name) {
	kit_dependency *kd;
	LOOP_OVER_LINKED_LIST(kd, kit_dependency, project->kits_to_include)
		if (Str::eq(kd->kit->as_copy->edition->work->title, name))
			return TRUE;
	return FALSE;
}

@ Here's where we decide which kits are included.

=
void Projects::finalise_kit_dependencies(inform_project *project) {
	@<Add dependencies for the standard kits@>;
	int parity = TRUE; @<Perform if-this-then-that@>;
	parity = FALSE; @<Perform if-this-then-that@>;
	@<Sort the kit dependency list into priority order@>;
	@<Log what the dependencies actually were@>;
}

@ At this point //Inbuild Control// has called //Projects::add_kit_dependency//
for any |-kit| options used at the command line, but otherwise no kits have been
depended.

Note that //CommandParserKit//, if depended, will cause a further dependency
on //WorldModelKit//, through the if-this-then-that mechanism.

@<Add dependencies for the standard kits@> =
	int no_word_from_user = TRUE;
	if (LinkedLists::len(project->kits_to_include) > 0) no_word_from_user = FALSE;
	Projects::add_kit_dependency(project, I"BasicInformKit", NULL, NULL);
	inform_language *L = project->language_of_play;
	if (L) {
		text_stream *kit_name = Languages::kit_name(L);
		Projects::add_kit_dependency(project, kit_name, L, NULL);
	}
	if (no_word_from_user)
		Projects::add_kit_dependency(project, I"CommandParserKit", NULL, NULL);

@ We perform this first with |parity| being |TRUE|, then |FALSE|.

@<Perform if-this-then-that@> =
	int changes_made = TRUE;
	while (changes_made) {
		changes_made = FALSE;
		kit_dependency *kd;
		LOOP_OVER_LINKED_LIST(kd, kit_dependency, project->kits_to_include)
			if (Kits::perform_ittt(kd->kit, project, parity))
				changes_made = TRUE;
	}

@ Lower-priority kits are merged into the Inter tree before higher ones,
because of the following sort:

@<Sort the kit dependency list into priority order@> =
	linked_list *sorted = NEW_LINKED_LIST(kit_dependency);
	for (int p=0; p<100; p++) {
		kit_dependency *kd;
		LOOP_OVER_LINKED_LIST(kd, kit_dependency, project->kits_to_include)
			if (kd->kit->priority == p)
				ADD_TO_LINKED_LIST(kd, kit_dependency, sorted);
	}
	project->kits_to_include = sorted;

@<Log what the dependencies actually were@> =
	kit_dependency *kd;
	LOOP_OVER_LINKED_LIST(kd, kit_dependency, project->kits_to_include)
		LOG("Using Inform kit '%S' (priority %d).\n",
			kd->kit->as_copy->edition->work->title, kd->kit->priority);

@h Things to do with kits.
First up: these internal configuration files set up what "text" and "real number"
mean, for example, and are optionally included in kits. The following
reads them in for every kit which is included in the project.

=
#ifdef CORE_MODULE
void Projects::load_built_in_kind_constructors(inform_project *project) {
	kit_dependency *kd;
	LOOP_OVER_LINKED_LIST(kd, kit_dependency, project->kits_to_include)
		Kits::load_built_in_kind_constructors(kd->kit);
}
#endif

@ Next, language element activation: this too is decided by kits.

=
#ifdef CORE_MODULE
void Projects::activate_elements(inform_project *project) {
	PluginManager::activate_bare_minimum();
	kit_dependency *kd;
	LOOP_OVER_LINKED_LIST(kd, kit_dependency, project->kits_to_include)
		Kits::activate_elements(kd->kit);
	LOG("Included: "); PluginManager::list_plugins(DL, TRUE);
	LOG("\n");
	LOG("Excluded: "); PluginManager::list_plugins(DL, FALSE);
	LOG("\n");
}
#endif

@ And so is the question of whether the compiler is expected to compile a
|Main| function, or whether one has already been included in one of the kits.

=
int Projects::Main_defined(inform_project *project) {
	kit_dependency *kd;
	LOOP_OVER_LINKED_LIST(kd, kit_dependency, project->kits_to_include)
		if (kd->kit->defines_Main)
			return TRUE;
	return FALSE;
}

@ The "index structure" is a kind of layout specification for the project
Index. Last kit wins:

=
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

@ The following is for passing requests to //inter//, which does not contain
//supervisor//, and so doesn't use the data structure //inform_kit//. That
means we can't give it a list of kits: we have to give it a list of their
details instead.

=
#ifdef PIPELINE_MODULE
linked_list *Projects::list_of_attachment_instructions(inform_project *project) {
	linked_list *requirements_list = NEW_LINKED_LIST(attachment_instruction);
	kit_dependency *kd;
	LOOP_OVER_LINKED_LIST(kd, kit_dependency, project->kits_to_include) {
		inform_kit *K = kd->kit;
		attachment_instruction *link = LoadBinaryKitsStage::new_requirement(
			K->as_copy->location_if_path, K->attachment_point);
		ADD_TO_LINKED_LIST(link, attachment_instruction, requirements_list);
	}
	return requirements_list;
}
#endif

@h File to write to.

=
void Projects::set_primary_output(inform_project *proj, filename *F) {
	proj->primary_output = F;
}

filename *Projects::get_primary_output(inform_project *proj) {
	if (proj->primary_output) return proj->primary_output;
	if (proj->stand_alone) {
		return Filenames::set_extension(proj->primary_source,
			TargetVMs::get_transpiled_extension(
				Supervisor::current_vm()));
	} else {
		pathname *build_folder = Projects::build_path(proj);
		return Filenames::in(build_folder, I"auto.inf");
	}
}

@h The full graph.
This can be quite grandiose even though most of it will never come to anything,
rather like a family tree for a minor European royal family.

=
void Projects::construct_graph(inform_project *proj) {
	if (proj == NULL) return;
	if (proj->chosen_build_target == NULL) {
		Projects::finalise_kit_dependencies(proj);
		Copies::get_source_text(proj->as_copy);
		build_vertex *V = proj->as_copy->vertex;
		@<Construct the graph upstream of V@>;
		@<Construct the graph downstream of V@>;
		Projects::check_extension_versions(proj);
	}
}

@ So the structure here is a simple chain of dependencies, but note that
they are upstream of the project's vertex |V|, not downstream:
= (text)
	Blorb package --> Story file --> I6 file --> Inter in memory --> Project
	            inblorb        inform6     inter (in inform7)  inform7
=
When looking at pictures like this, we must remember that time runs opposite
to the arrows: that is, these are built from right to left. For example,
the story file is made before the blorb package is made. The make algorithm
builds this list in a depth-first way, rapidly running downstream as it
discovers things it must do, then slowly clawing back upstream, actually
performing those tasks. In the diagram, below each arrow from |A --> B| is
the tool needed to make |A| from |B|.

So where should it start? Not at |V|, the vertex representing the project
itself, but somewhere upstream. The code below looks at the project's
compilation settings and sets |proj->chosen_build_target| to this start
position. In a simple //inform7// usage, we'll have:
= (text)
	Blorb package --> Story file --> I6 file --> Inter in memory --> Project
	                                    ^
	                                    chosen target
=
so that we have a two-stage process: (i) generate inter code in memory,
and (ii) code-generate the I6 source code file from that. But in a more
elaborate use of //inblorb// to incrementally build a project, it will be:
= (text)
	Blorb package --> Story file --> I6 file --> Inter in memory --> Project
	                       ^
	                       chosen target
=
if we are releasing a bare story file, or
= (text)
	Blorb package --> Story file --> I6 file --> Inter in memory --> Project
	   ^
	   chosen target
=
for a release of a blorbed one.

@<Construct the graph upstream of V@> =
	target_vm *VM = Supervisor::current_vm();
	filename *inf_F = Projects::get_primary_output(proj);

	/* vertex for the inter code put together in memory */
	build_vertex *inter_V = Graphs::file_vertex(inf_F);
	Graphs::need_this_to_build(inter_V, V);
	BuildSteps::attach(inter_V, compile_using_inform7_skill,
		proj->compile_for_release, VM, NULL, proj->as_copy);

	/* vertex for the final code file code-generated from that */
	build_vertex *inf_V = Graphs::file_vertex(inf_F);
	inf_V->always_build_dependencies = TRUE;
	Graphs::need_this_to_build(inf_V, inter_V);
	BuildSteps::attach(inf_V, code_generate_using_inter_skill,
		proj->compile_for_release, VM, NULL, proj->as_copy);

	if (Str::eq(TargetVMs::family(VM), I"Inform6")) {
		pathname *build_folder = Projects::build_path(proj);

		TEMPORARY_TEXT(story_file_leafname)
		WRITE_TO(story_file_leafname, "output.%S", TargetVMs::get_unblorbed_extension(VM));
		filename *unblorbed_F = Filenames::in(build_folder, story_file_leafname);
		DISCARD_TEXT(story_file_leafname)
		proj->unblorbed_vertex = Graphs::file_vertex(unblorbed_F);
		Graphs::need_this_to_build(proj->unblorbed_vertex, inf_V);
		BuildSteps::attach(proj->unblorbed_vertex, compile_using_inform6_skill,
			proj->compile_for_release, VM, NULL, proj->as_copy);

		TEMPORARY_TEXT(story_file_leafname2)
		WRITE_TO(story_file_leafname2, "output.%S", TargetVMs::get_blorbed_extension(VM));
		filename *blorbed_F = Filenames::in(build_folder, story_file_leafname2);
		DISCARD_TEXT(story_file_leafname2)
		proj->blorbed_vertex = Graphs::file_vertex(blorbed_F);
		proj->blorbed_vertex->always_build_this = TRUE;
		Graphs::need_this_to_build(proj->blorbed_vertex, proj->unblorbed_vertex);
		BuildSteps::attach(proj->blorbed_vertex, package_using_inblorb_skill,
			proj->compile_for_release, VM, NULL, proj->as_copy);

		if (proj->compile_only) {
			proj->chosen_build_target = inf_V;
			inf_V->always_build_this = TRUE;
		} else if (proj->compile_for_release) proj->chosen_build_target = proj->blorbed_vertex;
		else proj->chosen_build_target = proj->unblorbed_vertex;
	} else {
		proj->chosen_build_target = inf_V;
		inf_V->always_build_this = TRUE;
	}

@ The graph also extends downstream of |V|, representing the things we will
need before we can run //inform7// on the project: and this is not a linear
run of arrows at all, but fans considerably outwards -- to its languages,
kits and extensions, and then to their dependencies in turn.

Note that the following does not create dependencies for extensions used by
the project: that's because //Copies::get_source_text// has already done so.

@<Construct the graph downstream of V@> =
	@<The project depends on its source text@>;
	@<The project depends on the kits it includes@>;
	@<The project depends on the languages it is written in@>;

@<The project depends on its source text@> =
	build_vertex *S;
	LOOP_OVER_LINKED_LIST(S, build_vertex, Projects::source(proj))
		 Graphs::need_this_to_build(V, S);

@<The project depends on the kits it includes@> =
	kit_dependency *kd;
	LOOP_OVER_LINKED_LIST(kd, kit_dependency, proj->kits_to_include)
		if ((kd->because_of_kit == NULL) && (kd->because_of_language == NULL))
			Projects::graph_dependent_kit(proj, V, kd, FALSE);

@<The project depends on the languages it is written in@> =
	inform_language *L = proj->language_of_play;
	if (L) Projects::graph_dependent_language(proj, V, L, FALSE);
	L = proj->language_of_syntax;
	if (L) Projects::graph_dependent_language(proj, V, L, FALSE);
	L = proj->language_of_index;
	if (L) Projects::graph_dependent_language(proj, V, L, FALSE);

@ The point of these two functions is that if A uses B which uses C then we
want the dependencies |A -> B -> C| rather than |A -> B| together with |A -> C|.

=
void Projects::graph_dependent_kit(inform_project *proj,
	build_vertex *V, kit_dependency *kd, int use) {
	build_vertex *KV = kd->kit->as_copy->vertex;
	if (use) Graphs::need_this_to_use(V, KV);
	else Graphs::need_this_to_build(V, KV);
	inbuild_requirement *req;
	LOOP_OVER_LINKED_LIST(req, inbuild_requirement, kd->kit->extensions)
		Kits::add_extension_dependency(KV, req);
	kit_dependency *kd2;
	LOOP_OVER_LINKED_LIST(kd2, kit_dependency, proj->kits_to_include)
		if ((kd2->because_of_kit == kd->kit) && (kd2->because_of_language == NULL))
			Projects::graph_dependent_kit(proj, KV, kd2, TRUE);
}

void Projects::graph_dependent_language(inform_project *proj,
	build_vertex *V, inform_language *L, int use) {
	build_vertex *LV = L->as_copy->vertex;
	if (use) Graphs::need_this_to_use(V, LV);
	else Graphs::need_this_to_build(V, LV);
	kit_dependency *kd2;
	LOOP_OVER_LINKED_LIST(kd2, kit_dependency, proj->kits_to_include)
		if ((kd2->because_of_kit == NULL) && (kd2->because_of_language == L))
			Projects::graph_dependent_kit(proj, LV, kd2, TRUE);
}

@ One last task. It's unlikely, but possible, that an extension has been
included in a project twice, for different reasons, but that the two
inclusions have requirements about the extension's version which can't
both be met. Therefore we run through the downstream vertices and check
each extension against the intersection of all requirements put on it:

=
void Projects::check_extension_versions(inform_project *proj) {
	Projects::check_extension_versions_d(proj, proj->as_copy->vertex);
}

void Projects::check_extension_versions_d(inform_project *proj, build_vertex *V) {
	if ((V->as_copy) && (V->as_copy->edition->work->genre == extension_genre)) {
		inform_extension *E = ExtensionManager::from_copy(V->as_copy);
		if (Extensions::satisfies(E) == FALSE) {
			copy_error *CE = CopyErrors::new_T(SYNTAX_CE, ExtVersionTooLow_SYNERROR,
				I"two incompatible versions");
			CopyErrors::supply_node(CE, Extensions::get_inclusion_sentence(E));
			Copies::attach_error(proj->as_copy, CE);
		}
	}
	build_vertex *W;
	LOOP_OVER_LINKED_LIST(W, build_vertex, V->build_edges)
		Projects::check_extension_versions_d(proj, W);
	LOOP_OVER_LINKED_LIST(W, build_vertex, V->use_edges)
		Projects::check_extension_versions_d(proj, W);
}

@h Reading the source text.
We cannot know what extensions a project needs without reading its source
text, where the Include... sentences are, and of course we cannot parse the
source text to find those unless the Preform grammar is in place.

But then we can make a syntax tree for the project. The large-scale structure is:
= (text)
	root
	    Implied inclusions (level 0 heading)
	    	"Include Basic Inform by Graham Nelson."
	    	...
	    Source text from file 1 (level 0 heading)
	    	...
	    Source text from file 2 (level 0 heading)
	    	...
	    ...
	    Invented sentences (level 0 heading)
	    	"The colour understood is a colour that varies."
=
Once this is made, any Include... sentences are expanded into syntax trees
for the extensions they refer to, in a post-processing phase.

For a real-world example of the result, see //inform7: Performance Metrics//.

=
void Projects::read_source_text_for(inform_project *proj) {
	Languages::read_Preform_definition(proj->language_of_syntax, proj->search_list);
	Sentences::set_start_of_source(sfsm, -1);

	parse_node *inclusions_heading, *implicit_heading;
	@<First an implied super-heading for implied inclusions and the Options@>;
	@<Then the syntax tree from the actual source text@>;
	@<Lastly an implied heading for any inventions by the compiler@>;
	@<Post-process the syntax tree@>;

	#ifndef CORE_MODULE
	Copies::list_attached_errors(STDERR, proj->as_copy);
	#endif
}

@ Under the "Implied inclusions" heading come sentences to include the
extensions required by kits but not explicitly asked for in source text,
like Basic Inform or Standard Rules; and also any sentences in the
|Options.txt| file, if the user has one.

@<First an implied super-heading for implied inclusions and the Options@> =
	inclusions_heading = Node::new(HEADING_NT);
	Node::set_text(inclusions_heading,
		Feeds::feed_C_string_expanding_strings(L"Implied inclusions"));
	SyntaxTree::graft_sentence(proj->syntax_tree, inclusions_heading);
	Headings::place_implied_level_0(proj->syntax_tree, inclusions_heading);

	int wc = lexer_wordcount;
	TEMPORARY_TEXT(early)
	Projects::early_source_text(early, proj);
	if (Str::len(early) > 0) Feeds::feed_text(early);
	DISCARD_TEXT(early)
	inbuild_nest *ext = Supervisor::external();
	if (ext) OptionsFile::read(
		Filenames::in(ext->location, I"Options.txt"));
	wording early_W = Wordings::new(wc, lexer_wordcount-1);
	
	int l = SyntaxTree::push_bud(proj->syntax_tree, inclusions_heading);
	Sentences::break_into_project_copy(proj->syntax_tree, early_W, proj->as_copy, proj);
	SyntaxTree::pop_bud(proj->syntax_tree, l);

@ We don't need to make an implied heading here, because the sentence-breaker
in the //syntax// module does that automatically whenever it detects source
text originating in a different file; which, of course, will now happen, since
up to now the source text hasn't come from a file at all.

The "start of source" is the word number of the first word of the first
source text file for the project, and we notify the sentence-breaker when
it comes.

@<Then the syntax tree from the actual source text@> =
	int wc = lexer_wordcount;
	int start_set = FALSE;
	linked_list *L = Projects::source(proj);
	build_vertex *N;
	LOOP_OVER_LINKED_LIST(N, build_vertex, L) {
		filename *F = N->as_file;
		if (start_set == FALSE) {
			start_set = TRUE;
			Sentences::set_start_of_source(sfsm, lexer_wordcount);
		}
		N->as_source_file =
			SourceText::read_file(proj->as_copy, F, N->source_source, FALSE, TRUE);
	}
	int l = SyntaxTree::push_bud(proj->syntax_tree, proj->syntax_tree->root_node);
	Sentences::break_into_project_copy(
		proj->syntax_tree, Wordings::new(wc, lexer_wordcount-1), proj->as_copy, proj);
	SyntaxTree::pop_bud(proj->syntax_tree, l);

@ Inventions are when the //inform7// compiler makes up extra sentences, not
in the source text as such. They all go under the following implied heading.
Note that we leave the tree with its attachment point under this heading,
ready for those inventions (if in fact there are any).

@<Lastly an implied heading for any inventions by the compiler@> =
	int l = SyntaxTree::push_bud(proj->syntax_tree, proj->syntax_tree->root_node);
	implicit_heading = Node::new(HEADING_NT);
	Node::set_text(implicit_heading,
		Feeds::feed_C_string_expanding_strings(L"Invented sentences"));
	SyntaxTree::graft_sentence(proj->syntax_tree, implicit_heading);
	Headings::place_implied_level_0(proj->syntax_tree, implicit_heading);
	SyntaxTree::pop_bud(proj->syntax_tree, l);
	SyntaxTree::push_bud(proj->syntax_tree, implicit_heading); /* never popped */

@ The ordering here is, as so often in this section of code, important. We
have to know which language elements are in use before we can safely look
for Include... sentences, because some of those sentences are conditional
on that. We have to perform the tree surgery asked for by Include... in
place of... instructions after the sweep for inclusions.

@<Post-process the syntax tree@> =
	#ifdef CORE_MODULE
	Projects::activate_elements(proj);
	#endif
	Inclusions::traverse(proj->as_copy, proj->syntax_tree);
	Headings::satisfy_dependencies(proj, proj->syntax_tree, proj->as_copy);
