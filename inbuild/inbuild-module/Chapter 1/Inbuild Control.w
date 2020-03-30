[Inbuild::] Inbuild Control.

The top-level controller through which client tools use this module.

@h Phases.
The |inbuild| module provides services to whichever program is using it:
recall that the module is included both in |inform7| and in |inbuild| (the
command line tool), so either of those might be what we call "the client".

This section defines how the client communicates with us to get everything
set up correctly. Although nothing at all clever happens in this code, it
requires careful sequencing to avoid invisible errors coming in because
function X assumes that function Y has already been called, or perhaos that
it never will be again. The |inbuild| module therefore runs through a
number of named "phases" on its way to reaching fully-operational status,
at which time the client can freely use its facilities.

@e STARTUP_INBUILD_PHASE from 1
@e CONFIGURATION_INBUILD_PHASE
@e PRETINKERING_INBUILD_PHASE
@e TINKERING_INBUILD_PHASE
@e NESTED_INBUILD_PHASE
@e PROJECTED_INBUILD_PHASE
@e TARGETED_INBUILD_PHASE
@e GRAPH_CONSTRUCTION_INBUILD_PHASE
@e OPERATIONAL_INBUILD_PHASE

@ We're going to use the following assertions to make sure we don't slip up.
Some functions run only in some phases. Phases can be skipped, but not taken
out of turn.

@d RUN_ONLY_IN_PHASE(P)
	if (inbuild_phase < P) internal_error("too soon");
	if (inbuild_phase > P) internal_error("too late");
@d RUN_ONLY_FROM_PHASE(P)
	if (inbuild_phase < P) internal_error("too soon");
@d RUN_ONLY_BEFORE_PHASE(P)
	if (inbuild_phase >= P) internal_error("too late");

=
int inbuild_phase = STARTUP_INBUILD_PHASE;
void Inbuild::enter_phase(int p) {
	if (p <= inbuild_phase) internal_error("phases out of sequence");
	inbuild_phase = p;
}

@h Startup phase.
The following is called when the |inbuild| module starts up.

=
inbuild_genre *extension_genre = NULL;
inbuild_genre *kit_genre = NULL;
inbuild_genre *language_genre = NULL;
inbuild_genre *pipeline_genre = NULL;
inbuild_genre *project_bundle_genre = NULL;
inbuild_genre *project_file_genre = NULL;
inbuild_genre *template_genre = NULL;

void Inbuild::startup(void) {
	ExtensionManager::start();
	KitManager::start();
	LanguageManager::start();
	PipelineManager::start();
	ProjectBundleManager::start();
	ProjectFileManager::start();
	TemplateManager::start();

	InterSkill::create();
	Inform7Skill::create();
	Inform6Skill::create();
	InblorbSkill::create();

	ControlStructures::create_standard();
	
	inbuild_phase = CONFIGURATION_INBUILD_PHASE;
	Inbuild::set_defaults();
}

@h Configuration phase.
Initially, then, we are in the configuration phase. When the client defines
its command-line options, we expect it to call |Inbuild::declare_options|
so that we can define further options -- this provides the large set of
common options found in both |inform7| and |inbuild|, our two possible clients.

=
void Inbuild::declare_options(void) {
	RUN_ONLY_IN_PHASE(CONFIGURATION_INBUILD_PHASE)
	@<Declare Inform-related options@>;
	@<Declare resource-related options@>;
	@<Declare Inter-related options@>;
}

@ These options all predate the 2015-20 reworking of the compiler, and their
names are a series of historical accidents. |-format| in particular works in
a clunky sort of way and should perhaps be deprecated in favour of some
better way to choose a virtual machine to compile to.

@e INBUILD_INFORM_CLSG

@e PROJECT_CLSW
@e DEBUG_CLSW
@e RELEASE_CLSW
@e FORMAT_CLSW
@e SOURCE_CLSW
@e CENSUS_CLSW
@e RNG_CLSW
@e CASE_CLSW

@<Declare Inform-related options@> =
	CommandLine::begin_group(INBUILD_INFORM_CLSG, I"for translating Inform source text to Inter");
	CommandLine::declare_switch(PROJECT_CLSW, L"project", 2,
		L"work within the Inform project X");
	CommandLine::declare_boolean_switch(DEBUG_CLSW, L"debug", 1,
		L"compile with debugging features even on a Release", FALSE);
	CommandLine::declare_boolean_switch(RELEASE_CLSW, L"release", 1,
		L"compile a version suitable for a Release build", FALSE);
	CommandLine::declare_textual_switch(FORMAT_CLSW, L"format", 1,
		L"compile I6 code suitable for the virtual machine X");
	CommandLine::declare_switch(SOURCE_CLSW, L"source", 2,
		L"use file X as the Inform source text");
	CommandLine::declare_boolean_switch(CENSUS_CLSW, L"census", 1,
		L"perform an extensions census", FALSE);
	CommandLine::declare_boolean_switch(RNG_CLSW, L"rng", 1,
		L"fix the random number generator of the story file (for testing)", FALSE);
	CommandLine::declare_switch(CASE_CLSW, L"case", 2,
		L"make any source links refer to the source in extension example X");
	CommandLine::end_group();

@ Again, except for |-nest|, these go back to the mid-2010s.

@e INBUILD_RESOURCES_CLSG

@e NEST_CLSW
@e INTERNAL_CLSW
@e EXTERNAL_CLSW
@e TRANSIENT_CLSW

@<Declare resource-related options@> =
	CommandLine::begin_group(INBUILD_RESOURCES_CLSG, I"for locating resources in the file system");
	CommandLine::declare_switch(NEST_CLSW, L"nest", 2,
		L"add the nest at pathname X to the search list");
	CommandLine::declare_switch(INTERNAL_CLSW, L"internal", 2,
		L"use X as the location of built-in material such as the Standard Rules");
	CommandLine::declare_switch(EXTERNAL_CLSW, L"external", 2,
		L"use X as the user's home for installed material such as extensions");
	CommandLine::declare_switch(TRANSIENT_CLSW, L"transient", 2,
		L"use X for transient data such as the extensions census");
	CommandLine::end_group();

@ These are all new in 2020. They are not formally shared with the |inter| tool,
but |-pipeline-file| and |-variable| have the same effect as they would there.

@e INBUILD_INTER_CLSG

@e KIT_CLSW
@e PIPELINE_CLSW
@e PIPELINE_FILE_CLSW
@e PIPELINE_VARIABLE_CLSW

@<Declare Inter-related options@> =
	CommandLine::begin_group(INBUILD_INTER_CLSG, I"for tweaking code generation from Inter");
	CommandLine::declare_switch(KIT_CLSW, L"kit", 2,
		L"include Inter code from the kit called X");
	CommandLine::declare_switch(PIPELINE_CLSW, L"pipeline", 2,
		L"specify code-generation pipeline by name (default is \"compile\")");
	CommandLine::declare_switch(PIPELINE_FILE_CLSW, L"pipeline-file", 2,
		L"specify code-generation pipeline as file X");
	CommandLine::declare_switch(PIPELINE_VARIABLE_CLSW, L"variable", 2,
		L"set pipeline variable X (in form name=value)");
	CommandLine::end_group();

@ Use of the above options will cause the following global variables to be
set appropriately.

=
filename *inter_pipeline_file = NULL;
dictionary *pipeline_vars = NULL;
pathname *shared_transient_resources = NULL;
int this_is_a_debug_compile = FALSE; /* Destined to be compiled with debug features */
int this_is_a_release_compile = FALSE; /* Omit sections of source text marked not for release */
text_stream *story_filename_extension = NULL; /* What story file we will eventually have */
int census_mode = FALSE; /* Running only to update extension documentation */
int rng_seed_at_start_of_play = 0; /* The seed value, or 0 if not seeded */

void Inbuild::set_defaults(void) {
	RUN_ONLY_IN_PHASE(CONFIGURATION_INBUILD_PHASE)
	#ifdef CODEGEN_MODULE
	pipeline_vars = CodeGen::Pipeline::basic_dictionary(I"output.ulx");
	#endif
	Inbuild::set_inter_pipeline(I"compile");
}

@ The pipeline name can be set not only here but also by |inform7| much
later on (way past the configuration stage), if it reads a sentence like:

>> Use inter pipeline "special".

=
text_stream *inter_pipeline_name = NULL;

void Inbuild::set_inter_pipeline(text_stream *name) {
	if (inter_pipeline_name == NULL) inter_pipeline_name = Str::new();
	else Str::clear(inter_pipeline_name);
	WRITE_TO(inter_pipeline_name, "%S", name);
}

@ |inform7| needs to know this:

=
int Inbuild::currently_releasing(void) {
	return this_is_a_release_compile;
}

@ The |inbuild| module itself doesn't parse command-line options: that's for
the client to do, using code from Foundation. When the client finds an option
it doesn't know about, that will be one of ourse, so it should call the following:

=
void Inbuild::option(int id, int val, text_stream *arg, void *state) {
	RUN_ONLY_IN_PHASE(CONFIGURATION_INBUILD_PHASE)
	switch (id) {
		case DEBUG_CLSW: this_is_a_debug_compile = val; break;
		case FORMAT_CLSW: story_filename_extension = Str::duplicate(arg); break;
		case RELEASE_CLSW: this_is_a_release_compile = val; break;
		case NEST_CLSW:
			Inbuild::add_nest(Pathnames::from_text(arg), GENERIC_NEST_TAG); break;
		case INTERNAL_CLSW:
			Inbuild::add_nest(Pathnames::from_text(arg), INTERNAL_NEST_TAG); break;
		case EXTERNAL_CLSW:
			Inbuild::add_nest(Pathnames::from_text(arg), EXTERNAL_NEST_TAG); break;
		case TRANSIENT_CLSW:
			shared_transient_resources = Pathnames::from_text(arg); break;
		case KIT_CLSW: Inbuild::request_kit(arg); break;
		case PROJECT_CLSW:
			if (Inbuild::set_I7_bundle(arg) == FALSE)
				Errors::fatal_with_text("can't specify the project twice: '%S'", arg);
			break;
		case SOURCE_CLSW:
			if (Inbuild::set_I7_source(arg) == FALSE)
				Errors::fatal_with_text("can't specify the source file twice: '%S'", arg);
			break;
		case CENSUS_CLSW: census_mode = val; break;
		case PIPELINE_CLSW: inter_pipeline_name = Str::duplicate(arg); break;
		case PIPELINE_FILE_CLSW: inter_pipeline_file = Filenames::from_text(arg); break;
		case PIPELINE_VARIABLE_CLSW: @<Set a pipeline variable@>; break;
		case RNG_CLSW: @<Seed the random number generator@>; break;
		case CASE_CLSW: HTMLFiles::set_source_link_case(arg); break;
	}
}

@ Note that the following has no effect unless the |codegen| module is part
of the client. In practice, that will be true for |inform7| but not |inbuild|.

@<Set a pipeline variable@> =
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, arg, L"(%c+)=(%c+)")) {
		if (Str::get_first_char(arg) != '*') {
			Errors::fatal("-variable names must begin with '*'");
		} else {
			#ifdef CODEGEN_MODULE
			Str::copy(Dictionaries::create_text(pipeline_vars, mr.exp[0]), mr.exp[1]);
			#endif
		}
	} else {
		Errors::fatal("-variable should take the form 'name=value'");
	}
	Regexp::dispose_of(&mr);

@ 16339 is a well-known prime number for use in 16-bit random number algorithms,
such as the one used in the Z-machine VM. It works fine in 32-bit cases too.

@<Seed the random number generator@> =
	if (val) rng_seed_at_start_of_play = -16339;
	else rng_seed_at_start_of_play = 0;

@h The Pretinkering, Tinkering, Nested and Projected phases.
Once the tool has finished with the command line, it should call this
function. Inbuild rapidly runs through the next few phases as it does so.
From the "nested" phase, the final list of nests in the search path for
finding kits, extensions and so on exists; from the "projected" phase,
the main Inform project (if there is one) exists.

Recall that Inbuild does not need to be dealing with an Inform 7 project
as a target, but that if it is, then it is the only such. We call this
the "shared project". There will be lots of other copies known to Inbuild --
all the kits and extensions needed to build the shared project -- but only
one project.

The client should set |compile_only| if it just wants to make a basic,
non-incremental compilation of the project. In practice, |inform7| wants
that but |inbuild| does not.

When this call returns to the client, |inbuild| is in the Targeted phase,
which continues until the client calls |Inbuild::go_operational| (see below).

=
inbuild_copy *Inbuild::optioneering_complete(inbuild_copy *C, int compile_only,
	void (*preform_callback)(inform_language *)) {
	RUN_ONLY_IN_PHASE(CONFIGURATION_INBUILD_PHASE)
	inbuild_phase = PRETINKERING_INBUILD_PHASE;

	@<Find the virtual machine@>;
	inform_project *project = Inbuild::create_shared_project(C);
	
	inbuild_phase = TINKERING_INBUILD_PHASE;
	Inbuild::sort_nest_list();

	inbuild_phase = NESTED_INBUILD_PHASE;
	@<Read the definition of the natural language of syntax@>;

	if (project) {
		Inbuild::pass_kit_requests();
		Copies::get_source_text(project->as_copy);
	}

	inbuild_phase = PROJECTED_INBUILD_PHASE;
	if (project)
		Projects::construct_build_target(project,
			Inbuild::current_vm(), this_is_a_release_compile, compile_only);
	
	inbuild_phase = TARGETED_INBUILD_PHASE;
	if (project) return project->as_copy;
	return NULL;
}

@ The VM to be used depends on the settings of all three of |-format|,
|-release| and |-debug|, and those can be given in any order at the command
line, which is why we couldn't work this out earlier:

@<Find the virtual machine@> =
	text_stream *ext = story_filename_extension;
	if (Str::len(ext) == 0) ext = I"ulx";
	int with_debugging = FALSE;
	if ((this_is_a_release_compile == FALSE) || (this_is_a_debug_compile))
		with_debugging = TRUE;
	Inbuild::set_current_vm(TargetVMs::find(ext, with_debugging));

@ The "language of syntax" of a project is the natural language, by default
English, in which its source text is written.

We scan the available natural languages first. To do that it's sufficient to
generate a list of search results for all possible languages: each as it
comes to light will have been recorded as a possibility. We can then simply
ignore the search results. Note that this can only be done in the Nested
phase or after, because we need the nests in order to perform a search.

Once that's done, we ask the client to load the Preform grammar for the
language of the project. For now that's always English, but here is where
we would attempt to detect the language of syntax if we could.

@<Read the definition of the natural language of syntax@> =
	inbuild_requirement *req = Requirements::anything_of_genre(language_genre);
	linked_list *L = NEW_LINKED_LIST(inbuild_search_result);
	Nests::search_for(req, Inbuild::nest_list(), L);
	if (project) {
		Projects::set_to_English(project);
		(*preform_callback)(Projects::get_language_of_syntax(project));
	} else {
		(*preform_callback)(Languages::internal_English());
	}

@ =
target_vm *current_target_VM = NULL;
target_vm *Inbuild::current_vm(void) {
	RUN_ONLY_FROM_PHASE(TINKERING_INBUILD_PHASE)
	return current_target_VM;
}
void Inbuild::set_current_vm(target_vm *VM) {
	RUN_ONLY_IN_PHASE(PRETINKERING_INBUILD_PHASE)
	current_target_VM = VM;
}

@h The Graph Construction and Operational phases.
|inbuild| is now in the Targeted phase, then, meaning that the client has
called |Inbuild::optioneering_complete| and has been making further
preparations of its own. (For example, it could attach further kit
dependencies to the shared project.) The client has one further duty to
perform: to call |Inbuild::go_operational|. After that, everything is ready
for use.

The brief "graph construction" phase is used to build out dependency graphs.
We do that copy by copy. The shared project, if there is one, goes first;
then everything else known to us.

=
inform_project *Inbuild::go_operational(void) {
	RUN_ONLY_IN_PHASE(TARGETED_INBUILD_PHASE)
	inbuild_phase = GRAPH_CONSTRUCTION_INBUILD_PHASE;
	inform_project *P = Inbuild::project();
	if (P) Copies::construct_graph(P->as_copy);
	inbuild_copy *C;
	LOOP_OVER(C, inbuild_copy)
		if ((P == NULL) || (C != P->as_copy))
			Copies::construct_graph(C);
	inbuild_phase = OPERATIONAL_INBUILD_PHASE;
	if (census_mode) Extensions::Census::handle_census_mode();
	return Inbuild::project();
}

@h The nest list.
Nests are directories which hold resources to be used by the Intools, and
one of Inbuild's main roles is to search and manage nests. All nests can
hold extensions, kits, language definitions, and so on.

But among nests three are special, and can hold other things as well.

(a) The "internal" nest is part of the installation of Inform as software.
It contains, for example, the build-in extensions. But it also contains
miscellaneous other files needed by Infomr (see below).

(b) The "external" nest is the one to which the user installs her own
selection of extensions, and so on. On most platforms, the external nest
is also the default home of "transient" storage, for more ephemeral content,
such as the mechanically generated extension documentation. Some mobile
operating systems are aggressive about wanting to delete ephemeral files
used by applications, so |-transient| can be used to divert these.

(c) Every project has its own private nest, in the form of its associated
Materials folder. For example, in |Jane Eyre.inform| is a project, then
alongside it is |Jane Eyre.materials| and this is a nest.

@ Inform customarily has exactly one |-internal| and one |-external| nest,
but in fact any number of each are allowed, including none. However, the
first to be declared are used by the compiler as "the" internal and external
nests, respectively.

The following hold the nests in declaration order.

=
linked_list *unsorted_nest_list = NULL;
inbuild_nest *shared_internal_nest = NULL;
inbuild_nest *shared_external_nest = NULL;
inbuild_nest *shared_materials_nest = NULL;

inbuild_nest *Inbuild::add_nest(pathname *P, int tag) {
	RUN_ONLY_BEFORE_PHASE(TINKERING_INBUILD_PHASE)
	if (unsorted_nest_list == NULL)
		unsorted_nest_list = NEW_LINKED_LIST(inbuild_nest);
	inbuild_nest *N = Nests::new(P);
	Nests::set_tag(N, tag);
	ADD_TO_LINKED_LIST(N, inbuild_nest, unsorted_nest_list);
	if ((tag == EXTERNAL_NEST_TAG) && (shared_external_nest == NULL))
		shared_external_nest = N;
	if ((tag == INTERNAL_NEST_TAG) && (shared_internal_nest == NULL))
		shared_internal_nest = N;
	if (tag == INTERNAL_NEST_TAG) Nests::protect(N);
	return N;
}

@ It is then sorted in tag order. This is so that if we look for, say, an
extension with a given name, then results in a project's materials folder
are given precedence over those in the external folder, and so on.

=
linked_list *shared_nest_list = NULL;
void Inbuild::sort_nest_list(void) {
	RUN_ONLY_IN_PHASE(TINKERING_INBUILD_PHASE)
	shared_nest_list = NEW_LINKED_LIST(inbuild_nest);
	inbuild_nest *N;
	LOOP_OVER_LINKED_LIST(N, inbuild_nest, unsorted_nest_list)
		if (Nests::get_tag(N) == MATERIALS_NEST_TAG)
			ADD_TO_LINKED_LIST(N, inbuild_nest, shared_nest_list);
	LOOP_OVER_LINKED_LIST(N, inbuild_nest, unsorted_nest_list)
		if (Nests::get_tag(N) == EXTERNAL_NEST_TAG)
			ADD_TO_LINKED_LIST(N, inbuild_nest, shared_nest_list);
	LOOP_OVER_LINKED_LIST(N, inbuild_nest, unsorted_nest_list)
		if (Nests::get_tag(N) == GENERIC_NEST_TAG)
			ADD_TO_LINKED_LIST(N, inbuild_nest, shared_nest_list);
	LOOP_OVER_LINKED_LIST(N, inbuild_nest, unsorted_nest_list)
		if (Nests::get_tag(N) == INTERNAL_NEST_TAG)
			ADD_TO_LINKED_LIST(N, inbuild_nest, shared_nest_list);
}

@ And the rest of Inform or Inbuild can now use:

=
linked_list *Inbuild::nest_list(void) {
	RUN_ONLY_FROM_PHASE(NESTED_INBUILD_PHASE)
	if (shared_nest_list == NULL) internal_error("nest list never sorted");
	return shared_nest_list;
}

inbuild_nest *Inbuild::internal(void) {
	RUN_ONLY_FROM_PHASE(NESTED_INBUILD_PHASE)
	return shared_internal_nest;
}

inbuild_nest *Inbuild::external(void) {
	RUN_ONLY_FROM_PHASE(NESTED_INBUILD_PHASE)
	return shared_external_nest;
}

pathname *Inbuild::materials(void) {
	RUN_ONLY_FROM_PHASE(NESTED_INBUILD_PHASE)
	if (shared_materials_nest == NULL) return NULL;
	return shared_materials_nest->location;
}

inbuild_nest *Inbuild::materials_nest(void) {
	RUN_ONLY_FROM_PHASE(NESTED_INBUILD_PHASE)
	return shared_materials_nest;
}

@ As noted above, the transient area is used for ephemera such as dynamically
written documentation and telemetry files. |-transient| sets it, but otherwise
the external nest is used.

=
pathname *Inbuild::transient(void) {
	RUN_ONLY_FROM_PHASE(PROJECTED_INBUILD_PHASE)
	if (shared_transient_resources == NULL)
		if (shared_external_nest)
			return shared_external_nest->location;
	return shared_transient_resources;
}

@h The shared project.
In any single run, each of the Inform tools concerns itself with a single
Inform 7 program. This can be presented to it either in a project bundle
(a directory which contains source, settings, space for an index and for
temporary build files), or as a single file (just a text file containing
source text).

It is also possible o set a folder to be the project bundle, and nevertheless
specify a file somewhere else to be the source text. What you can't do is
specify the bundle twice, or specify the file twice.

=
text_stream *project_bundle_request = NULL;
text_stream *project_file_request = NULL;

int Inbuild::set_I7_source(text_stream *loc) {
	RUN_ONLY_FROM_PHASE(CONFIGURATION_INBUILD_PHASE)
	if (Str::len(project_file_request) > 0) return FALSE;
	project_file_request = Str::duplicate(loc);
	return TRUE;
}

@ If we are given a |-project| on the command line, we can then work out
where its Materials folder is, and therefore where any expert settings files
would be. Note that the name of the expert settings file depends on the name
of the client, i.e., it will be |inform7-settings.txt| or |inbuild-settings.txt|
depending on who's asking.

=
int Inbuild::set_I7_bundle(text_stream *loc) {
	RUN_ONLY_FROM_PHASE(CONFIGURATION_INBUILD_PHASE)
	if (Str::len(project_bundle_request) > 0) return FALSE;
	project_bundle_request = Str::duplicate(loc);
	pathname *pathname_of_bundle = Pathnames::from_text(project_bundle_request);
	pathname *materials = Inbuild::pathname_of_materials(pathname_of_bundle);
	TEMPORARY_TEXT(leaf);
	WRITE_TO(leaf, "%s-settings.txt", INTOOL_NAME);
	filename *expert_settings = Filenames::in_folder(materials, leaf);
	if (TextFiles::exists(expert_settings))
		CommandLine::also_read_file(expert_settings);
	DISCARD_TEXT(leaf);
	return TRUE;
}

@ If a bundle is found, then by default the source text within it is called
|story.ni|. The |.ni| is an anachronism now, but at one time stood for
"natural Inform", the working title for Inform 7 in the early 2000s.

=
inform_project *shared_project = NULL;

inform_project *Inbuild::create_shared_project(inbuild_copy *C) {
	RUN_ONLY_IN_PHASE(PRETINKERING_INBUILD_PHASE)
	filename *filename_of_i7_source = NULL;
	pathname *pathname_of_bundle = NULL;
	if (Str::len(project_bundle_request) > 0) {
		pathname_of_bundle = Pathnames::from_text(project_bundle_request);
	}
	if (Str::len(project_file_request) > 0) {
		filename_of_i7_source = Filenames::from_text(project_file_request);
	}
	if (C) {
		pathname_of_bundle = C->location_if_path;
		filename_of_i7_source = C->location_if_file;
	}
	if ((pathname_of_bundle) && (filename_of_i7_source == NULL))
		filename_of_i7_source =
			Filenames::in_folder(
				Pathnames::subfolder(pathname_of_bundle, I"Source"),
				I"story.ni");
	if (pathname_of_bundle) {
		if (C == NULL) C = ProjectBundleManager::claim_folder_as_copy(pathname_of_bundle);
		shared_project = ProjectBundleManager::from_copy(C);
	} else if (filename_of_i7_source) {
		if (C == NULL) C = ProjectFileManager::claim_file_as_copy(filename_of_i7_source);
		shared_project = ProjectFileManager::from_copy(C);
	}
	@<Create the default externals nest@>;
	@<Create the materials nest@>;
	if (shared_project) {
		pathname *P = (shared_materials_nest)?(shared_materials_nest->location):NULL;
		if (P) P = Pathnames::subfolder(P, I"Source");
		if (Str::len(project_file_request) > 0) P = NULL;
		Projects::set_source_filename(shared_project, P, filename_of_i7_source);
		if (rng_seed_at_start_of_play != 0)
			Projects::fix_rng(shared_project, rng_seed_at_start_of_play);
	}
	return shared_project;
}

@<Create the default externals nest@> =
	inbuild_nest *E = shared_external_nest;
	if (E == NULL) {
		pathname *P = home_path;
		char *subfolder_within = INFORM_FOLDER_RELATIVE_TO_HOME;
		if (subfolder_within[0]) {
			TEMPORARY_TEXT(SF);
			WRITE_TO(SF, "%s", subfolder_within);
			P = Pathnames::subfolder(home_path, SF);
			DISCARD_TEXT(SF);
		}
		P = Pathnames::subfolder(P, I"Inform");
		E = Inbuild::add_nest(P, EXTERNAL_NEST_TAG);
	}

@<Create the materials nest@> =
	pathname *materials = NULL;
	if (pathname_of_bundle) {
		materials = Inbuild::pathname_of_materials(pathname_of_bundle);
		Pathnames::create_in_file_system(materials);
	} else if (filename_of_i7_source) {
		materials = Pathnames::from_text(I"inform.materials");
	}
	if (materials) {
		shared_materials_nest = Inbuild::add_nest(materials, MATERIALS_NEST_TAG);
	}

@ And the rest of Inform or Inbuild can now use:

=
inform_project *Inbuild::project(void) {
	RUN_ONLY_FROM_PHASE(TINKERING_INBUILD_PHASE)
	return shared_project;
}

@ The materials folder sits alongside the project folder and has the same name,
but ending |.materials| instead of |.inform|.

=
pathname *Inbuild::pathname_of_materials(pathname *pathname_of_bundle) {
	TEMPORARY_TEXT(mf);
	WRITE_TO(mf, "%S", Pathnames::directory_name(pathname_of_bundle));
	int i = Str::len(mf)-1;
	while ((i>0) && (Str::get_at(mf, i) != '.')) i--;
	if (i>0) {
		Str::truncate(mf, i);
		WRITE_TO(mf, ".materials");
	}
	pathname *materials = Pathnames::subfolder(Pathnames::up(pathname_of_bundle), mf);
	DISCARD_TEXT(mf);
	return materials;
}

@h Kit requests.
These are triggered by, for example, |-kit MyFancyKit| at the command line.
For timing reasons, we store those up in the configuration phase and then
add them as dependencies only when a project exists.

=
linked_list *kits_requested_at_command_line = NULL;
void Inbuild::request_kit(text_stream *name) {
	RUN_ONLY_IN_PHASE(CONFIGURATION_INBUILD_PHASE)
	if (kits_requested_at_command_line == NULL)
		kits_requested_at_command_line = NEW_LINKED_LIST(text_stream);
	text_stream *kit_name;
	LOOP_OVER_LINKED_LIST(kit_name, text_stream, kits_requested_at_command_line)
		if (Str::eq(kit_name, name))
			return;
	ADD_TO_LINKED_LIST(Str::duplicate(name), text_stream, kits_requested_at_command_line);
}

void Inbuild::pass_kit_requests(void) {
	RUN_ONLY_IN_PHASE(NESTED_INBUILD_PHASE)
	if ((shared_project) && (kits_requested_at_command_line)) {
		text_stream *kit_name;
		LOOP_OVER_LINKED_LIST(kit_name, text_stream, kits_requested_at_command_line) {
			Projects::add_kit_dependency(shared_project, kit_name, NULL, NULL);
			Projects::not_necessarily_parser_IF(shared_project);
		}
	}
}

@h Access to unmanaged Inform resources.
Inform needs a whole pile of files to have been installed on the host computer
before it can run: everything from the Standard Rules to a PDF file explaining
what interactive fiction is. They're never written to, only read. They are
stored in subdirectories called |Miscellany| or |HTML| of the internal nest;
but they're just plain old files, and are not managed by Inbuild as "copies".

Our client can access these files using the following function:

@e CBLORB_REPORT_MODEL_IRES from 1
@e DOCUMENTATION_SNIPPETS_IRES
@e INTRO_BOOKLET_IRES
@e INTRO_POSTCARD_IRES
@e LARGE_DEFAULT_COVER_ART_IRES
@e SMALL_DEFAULT_COVER_ART_IRES
@e DOCUMENTATION_XREFS_IRES
@e JAVASCRIPT_FOR_STANDARD_PAGES_IRES
@e JAVASCRIPT_FOR_EXTENSIONS_IRES
@e JAVASCRIPT_FOR_ONE_EXTENSION_IRES
@e CSS_FOR_STANDARD_PAGES_IRES
@e EXTENSION_DOCUMENTATION_MODEL_IRES

=
filename *Inbuild::file_from_installation(int ires) {
	inbuild_nest *I = Inbuild::internal();
	if (I == NULL) Errors::fatal("Did not set -internal when calling");
	pathname *misc = Pathnames::subfolder(I->location, I"Miscellany");
	pathname *models = Pathnames::subfolder(I->location, I"HTML");
	switch (ires) {
		case DOCUMENTATION_SNIPPETS_IRES: 
				return Filenames::in_folder(misc, I"definitions.html");
		case INTRO_BOOKLET_IRES: 
				return Filenames::in_folder(misc, I"IntroductionToIF.pdf");
		case INTRO_POSTCARD_IRES: 
				return Filenames::in_folder(misc, I"Postcard.pdf");
		case LARGE_DEFAULT_COVER_ART_IRES: 
				return Filenames::in_folder(misc, I"Cover.jpg");
		case SMALL_DEFAULT_COVER_ART_IRES: 
				return Filenames::in_folder(misc, I"Small Cover.jpg");

		case CBLORB_REPORT_MODEL_IRES: 
				return Filenames::in_folder(models, I"CblorbModel.html");
		case DOCUMENTATION_XREFS_IRES: 
				return Filenames::in_folder(models, I"xrefs.txt");
		case JAVASCRIPT_FOR_STANDARD_PAGES_IRES: 
				return Filenames::in_folder(models, I"main.js");
		case JAVASCRIPT_FOR_EXTENSIONS_IRES: 
				return Filenames::in_folder(models, I"extensions.js");
		case JAVASCRIPT_FOR_ONE_EXTENSION_IRES: 
				return Filenames::in_folder(models, I"extensionfile.js");
		case CSS_FOR_STANDARD_PAGES_IRES: 
				return Filenames::in_folder(models, I"main.css");
		case EXTENSION_DOCUMENTATION_MODEL_IRES: 
				return Filenames::in_folder(models, I"extensionfile.html");
		}
	internal_error("unknown installation resource file");
	return NULL;
}

