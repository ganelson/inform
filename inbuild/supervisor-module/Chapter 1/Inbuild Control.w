[Supervisor::] Inbuild Control.

Who shall supervise the supervisor? This section of code will.

@h Verbosity.
It is both a strength and a source of anxiety that build managers work in
an autonomous sort of way, doing "whatever is necessary". Some users want
silence while this happens, and others expect detailed explanations.

= (early code)
int supervisor_verbosity = 0;
#define SVEXPLAIN(level, args...) { \
	if (supervisor_verbosity >= level) Writers::printf(STDOUT, args); \
}

@ =
void Supervisor::set_verbosity(int level) {
	if (level < 0) level = 0;
	if (level > 3) level = 3;
	supervisor_verbosity = level;
	if (level > 0) WRITE_TO(STDOUT, "(inbuild verbosity set to %d)\n", level);
}

@h Phases.
The //supervisor// module provides services to the parent tool.

This section defines how the parent communicates with us to get everything
set up correctly. Although nothing at all clever happens in this code, it
requires careful sequencing to avoid invisible errors coming in because
function X assumes that function Y has already been called, or perhaps that
it never will be again. The //supervisor// module therefore runs through a
number of named "phases" on its way to reaching fully-operational status,
at which time the parent can freely use its facilities.

@e STARTUP_INBUILD_PHASE from 1
@e CONFIGURATION_INBUILD_PHASE
@e PRETINKERING_INBUILD_PHASE
@e TINKERING_INBUILD_PHASE
@e NESTED_INBUILD_PHASE
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
void Supervisor::enter_phase(int p) {
	SVEXPLAIN(2, "(Supervisor phase %d: %S -> %d: %S)\n",
		inbuild_phase, Supervisor::phase_name(inbuild_phase), p, Supervisor::phase_name(p));
	inbuild_phase = p;
}

text_stream *Supervisor::phase_name(int p) {
	switch (p) {
		case STARTUP_INBUILD_PHASE: return I"startup";
		case CONFIGURATION_INBUILD_PHASE: return I"configuration";
		case PRETINKERING_INBUILD_PHASE: return I"pretinkering";
		case TINKERING_INBUILD_PHASE: return I"tinkering";
		case NESTED_INBUILD_PHASE: return I"nested";
		case TARGETED_INBUILD_PHASE: return I"targeted";
		case GRAPH_CONSTRUCTION_INBUILD_PHASE: return I"graphing";
		case OPERATIONAL_INBUILD_PHASE: return I"operational";
	}
	return I"<unknown phase>";
}

@h Startup phase.
The following is called when the //supervisor// module starts up.

=
inbuild_genre *extension_genre = NULL;
inbuild_genre *extension_bundle_genre = NULL;
inbuild_genre *kit_genre = NULL;
inbuild_genre *language_genre = NULL;
inbuild_genre *pipeline_genre = NULL;
inbuild_genre *project_bundle_genre = NULL;
inbuild_genre *project_file_genre = NULL;
inbuild_genre *template_genre = NULL;

void Supervisor::start(void) {
	ExtensionManager::start();
	ExtensionBundleManager::start();
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
	
	Supervisor::enter_phase(CONFIGURATION_INBUILD_PHASE);
	Supervisor::set_defaults();
}

@h Configuration phase.
Initially, then, we are in the configuration phase. When the parent defines
its command-line options, we expect it to call |Supervisor::declare_options|
so that we can define further options -- this provides the large set of
common options found in both |inform7| and |inbuild|, our two possible parents.

=
void Supervisor::declare_options(void) {
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
@e BASIC_CLSW
@e DEBUG_CLSW
@e RELEASE_CLSW
@e FORMAT_CLSW
@e SOURCE_CLSW
@e O_CLSW
@e CENSUS_CLSW
@e RNG_CLSW
@e CASE_CLSW

@<Declare Inform-related options@> =
	CommandLine::begin_group(INBUILD_INFORM_CLSG, I"for translating Inform source text to Inter");
	CommandLine::declare_switch(PROJECT_CLSW, L"project", 2,
		L"work within the Inform project X");
	CommandLine::declare_switch(BASIC_CLSW, L"basic", 1,
		L"use Basic Inform language");
	CommandLine::declare_boolean_switch(DEBUG_CLSW, L"debug", 1,
		L"compile with debugging features even on a Release", FALSE);
	CommandLine::declare_boolean_switch(RELEASE_CLSW, L"release", 1,
		L"compile a version suitable for a Release build", FALSE);
	CommandLine::declare_textual_switch(FORMAT_CLSW, L"format", 1,
		L"compile to the format X (default is Inform6/32)");
	CommandLine::declare_switch(SOURCE_CLSW, L"source", 2,
		L"use file X as the Inform source text");
	CommandLine::declare_switch(O_CLSW, L"o", 2,
		L"use file X as the compiled output (not for use with -project)");
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
@e DEPRECATED_EXTERNAL_CLSW
@e TRANSIENT_CLSW

@<Declare resource-related options@> =
	CommandLine::begin_group(INBUILD_RESOURCES_CLSG, I"for locating resources in the file system");
	CommandLine::declare_switch(NEST_CLSW, L"nest", 2,
		L"add the nest at pathname X to the search list");
	CommandLine::declare_switch(INTERNAL_CLSW, L"internal", 2,
		L"use X as the location of built-in material such as the Standard Rules");
	CommandLine::declare_switch(EXTERNAL_CLSW, L"external", 2,
		L"use X as the user's home for installed material such as extensions");
	CommandLine::declare_switch(DEPRECATED_EXTERNAL_CLSW, L"deprecated-external", 2,
		L"same as -external X, but issues warnings if the nest is actually used");
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
filename *transpiled_output_file = NULL;
dictionary *pipeline_vars = NULL;
pathname *shared_transient_resources = NULL;
int this_is_a_debug_compile = FALSE; /* Destined to be compiled with debug features */
int this_is_a_release_compile = FALSE; /* Omit sections of source text marked not for release */
text_stream *output_format = NULL; /* What story file we will eventually have */
int census_mode = FALSE; /* Running only to update extension documentation */
int repair_mode = FALSE; /* Automatically fix missing or damaged extension metadata */
int rng_seed_at_start_of_play = 0; /* The seed value, or 0 if not seeded */

void Supervisor::set_defaults(void) {
	RUN_ONLY_IN_PHASE(CONFIGURATION_INBUILD_PHASE)
	#ifdef PIPELINE_MODULE
	pipeline_vars = ParsingPipelines::basic_dictionary(I"output.ulx");
	#endif
	Supervisor::set_inter_pipeline(I"compile");
}

@ The pipeline name can be set not only here but also by |inform7| much
later on (way past the configuration stage), if it reads a sentence like:

>> Use inter pipeline "special".

=
text_stream *inter_pipeline_name = NULL;

void Supervisor::set_inter_pipeline(text_stream *name) {
	if (inter_pipeline_name == NULL) inter_pipeline_name = Str::new();
	else Str::clear(inter_pipeline_name);
	WRITE_TO(inter_pipeline_name, "%S", name);
	SVEXPLAIN(1, "(inter pipeline name set to %S)\n", name);
}

@ The //supervisor// module itself doesn't parse command-line options: that's for
the parent to do, using code from Foundation. When the parent finds an option
it doesn't know about, that will be one of ours, so it should call the following:

=
int dash_internal_used = FALSE;

void Supervisor::option(int id, int val, text_stream *arg, void *state) {
	RUN_ONLY_IN_PHASE(CONFIGURATION_INBUILD_PHASE)
	switch (id) {
		case DEBUG_CLSW: this_is_a_debug_compile = val; break;
		case FORMAT_CLSW: output_format = Str::duplicate(arg); break;
		case RELEASE_CLSW: this_is_a_release_compile = val; break;
		case NEST_CLSW:
			Supervisor::add_nest(Pathnames::from_text(arg), GENERIC_NEST_TAG); break;
		case INTERNAL_CLSW:
			dash_internal_used = TRUE;
			Supervisor::add_nest(Pathnames::from_text(arg), INTERNAL_NEST_TAG); break;
		case EXTERNAL_CLSW:
			Supervisor::add_nest(Pathnames::from_text(arg), EXTERNAL_NEST_TAG); break;
		case DEPRECATED_EXTERNAL_CLSW:
			Nests::deprecate(Supervisor::add_nest(Pathnames::from_text(arg),
				EXTERNAL_NEST_TAG)); break;
		case TRANSIENT_CLSW:
			shared_transient_resources = Pathnames::from_text(arg); break;
		case BASIC_CLSW: Projects::enter_forcible_basic_mode(); break;
		case KIT_CLSW:
			Errors::fatal("the -kit option has been withdrawn");
			break;
		case PROJECT_CLSW: {
			pathname *P = Pathnames::from_text(arg);
			if (Supervisor::set_I7_bundle(P) == FALSE)
				Errors::fatal_with_text("can't specify the project twice: '%S'", arg);
			break;
		}
		case SOURCE_CLSW: {
			filename *F = Filenames::from_text(arg);
			if (Supervisor::set_I7_source(F) == FALSE)
				Errors::fatal_with_text("can't specify the source file twice: '%S'", arg);
			break;
		}
		case O_CLSW: transpiled_output_file = Filenames::from_text(arg); break;
		case CENSUS_CLSW: census_mode = val; break;
		case PIPELINE_CLSW: inter_pipeline_name = Str::duplicate(arg); break;
		case PIPELINE_FILE_CLSW: inter_pipeline_file = Filenames::from_text(arg); break;
		case PIPELINE_VARIABLE_CLSW: @<Set a pipeline variable@>; break;
		case RNG_CLSW: @<Seed the random number generator@>; break;
		case CASE_CLSW: SourceLinks::set_case(arg); break;
	}
}

int Supervisor::dash_internal_was_used(void) {
	return dash_internal_used;
}

@ Note that the following has no effect unless the //pipeline// module is part
of the parent. In practice, that will be true for |inform7| but not |inbuild|.

@<Set a pipeline variable@> =
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, arg, L"(%c+)=(%c+)")) {
		if (Str::get_first_char(arg) != '*') {
			Errors::fatal("-variable names must begin with '*'");
		} else {
			#ifdef PIPELINE_MODULE
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
finding kits, extensions and so on exists; from the "targeted" phase,
the main Inform project (if there is one) exists as a possible build target.

The parent should set |compile_only| if it just wants to make a basic,
non-incremental compilation of any project. In practice, |inform7| wants
that but |inbuild| does not.

When this call returns to the parent, |inbuild| is in the Targeted phase,
which continues until the parent calls |Supervisor::go_operational| (see below).

=
int (*shared_preform_callback)(inform_language *);

void Supervisor::optioneering_complete(inbuild_copy *C, int compile_only,
	int (*preform_callback)(inform_language *)) {
	RUN_ONLY_IN_PHASE(CONFIGURATION_INBUILD_PHASE)
	Supervisor::enter_phase(PRETINKERING_INBUILD_PHASE);
	shared_preform_callback = preform_callback;

	@<Find the virtual machine@>;
	Supervisor::make_project_from_command_line(C);
	
	Supervisor::create_default_externals();
	Supervisor::enter_phase(TINKERING_INBUILD_PHASE);
	Supervisor::sort_nest_list();

	Supervisor::enter_phase(NESTED_INBUILD_PHASE);
	inform_project *proj;
	LOOP_OVER(proj, inform_project)
		Projects::set_compilation_options(proj,
			this_is_a_release_compile, compile_only, rng_seed_at_start_of_play);
	
	Supervisor::enter_phase(TARGETED_INBUILD_PHASE);
}

@ The VM to be used depends on the settings of all three of |-format|,
|-release| and |-debug|, and those can be given in any order at the command
line, which is why we couldn't work this out earlier:

@<Find the virtual machine@> =
	text_stream *ext = output_format;
	int with_debugging = FALSE;
	if ((this_is_a_release_compile == FALSE) || (this_is_a_debug_compile))
		with_debugging = TRUE;
	if (Str::len(ext) == 0) ext = I"Inform6";
	target_vm *VM = TargetVMs::find_with_hint(ext, with_debugging);
	Supervisor::set_current_vm(VM);
	if (VM == NULL) Errors::fatal("unrecognised compilation format");

@ =
target_vm *current_target_VM = NULL;
target_vm *Supervisor::current_vm(void) {
	RUN_ONLY_FROM_PHASE(TINKERING_INBUILD_PHASE)
	return current_target_VM;
}
void Supervisor::set_current_vm(target_vm *VM) {
	RUN_ONLY_IN_PHASE(PRETINKERING_INBUILD_PHASE)
	current_target_VM = VM;
	SVEXPLAIN(1, "(target VM set to %S)\n", TargetVMs::get_full_format_text(VM));
}

@h The Graph Construction and Operational phases.
|inbuild| is now in the Targeted phase, then, meaning that the parent has
called |Supervisor::optioneering_complete| and has been making further
preparations of its own. (For example, it could attach further kit
dependencies to the shared project.) The parent has one further duty to
perform: to call |Supervisor::go_operational|. After that, everything is ready
for use.

The brief "graph construction" phase is used to build out dependency graphs.
We do that copy by copy.

=
void Supervisor::go_operational(void) {
	RUN_ONLY_IN_PHASE(TARGETED_INBUILD_PHASE)
	Supervisor::enter_phase(GRAPH_CONSTRUCTION_INBUILD_PHASE);
	Copies::graph_everything();
	Supervisor::enter_phase(OPERATIONAL_INBUILD_PHASE);
	if (census_mode) ExtensionWebsite::handle_census_mode();
}

@h The nest list.
Nests are directories which hold resources to be used by the Intools, and
one of Inbuild's main roles is to search and manage nests. All nests can
hold extensions, kits, language definitions, and so on.

But among nests three are special, and can hold other things as well.

(a) The "internal" nest is part of the installation of Inform as software.
It contains, for example, the build-in extensions. But it also contains
miscellaneous other files needed by Inform (see below).

(b) The "external" nest is the one to which the user installs her own
selection of extensions, and so on. On most platforms, the external nest
is also the default home of "transient" storage, for more ephemeral content,
such as the mechanically generated extension documentation. Some mobile
operating systems are aggressive about wanting to delete ephemeral files
used by applications, so |-transient| can be used to divert these.

(c) Every project has its own private nest, in the form of its associated
Materials folder. For example, in |Jane Eyre.inform| is a project, then
alongside it is |Jane Eyre.materials| and this is a nest. The shared nest
list contains no Materials folders; each individual project has its own
search list of nests which contains its own Materials and then the shared
list from there on.

@ Inform customarily has exactly one |-internal| and one |-external| nest,
but in fact any number of each is allowed, including none. However, the
first to be declared are used by the compiler as "the" internal and external
nests, respectively.

The following hold the nests in declaration order.

=
linked_list *unsorted_nest_list = NULL;
inbuild_nest *shared_internal_nest = NULL;
inbuild_nest *shared_external_nest = NULL;

inbuild_nest *Supervisor::add_nest(pathname *P, int tag) {
	RUN_ONLY_BEFORE_PHASE(TINKERING_INBUILD_PHASE)
	if (unsorted_nest_list == NULL)
		unsorted_nest_list = NEW_LINKED_LIST(inbuild_nest);
	inbuild_nest *N = Nests::new(P);
	Nests::set_tag(N, tag);
	int set_shared = FALSE;
	ADD_TO_LINKED_LIST(N, inbuild_nest, unsorted_nest_list);
	if ((tag == EXTERNAL_NEST_TAG) && (shared_external_nest == NULL)) {
		shared_external_nest = N; set_shared = TRUE;
	}
	if ((tag == INTERNAL_NEST_TAG) && (shared_internal_nest == NULL)) {
		shared_internal_nest = N; set_shared = TRUE;
	}
	if (tag == INTERNAL_NEST_TAG) Nests::protect(N);
	SVEXPLAIN(2, "(%S%S nest set at %p)\n",
		(set_shared)?I"shared ":I"", Nests::tag_name(tag), P);
	return N;
}

void Supervisor::create_default_externals(void) {
	RUN_ONLY_BEFORE_PHASE(TINKERING_INBUILD_PHASE)
	inbuild_nest *E = shared_external_nest;
	if (E == NULL) {
		pathname *P = home_path;
		char *subfolder_within = INFORM_FOLDER_RELATIVE_TO_HOME;
		if (subfolder_within[0]) {
			TEMPORARY_TEXT(SF)
			WRITE_TO(SF, "%s", subfolder_within);
			P = Pathnames::down(home_path, SF);
			DISCARD_TEXT(SF)
		}
		P = Pathnames::down(P, I"Inform");
		SVEXPLAIN(1, "(in absence of explicit -external, inventing -external %p)\n", P);
		SVEXPLAIN(2, "(because home path, according to environment variable HOME, is %p)\n", home_path);
		E = Supervisor::add_nest(P, EXTERNAL_NEST_TAG);
	}
}

@ It is then sorted in tag order:

=
linked_list *shared_nest_list = NULL;
void Supervisor::sort_nest_list(void) {
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
	Supervisor::report_nest_list(2, I"unsorted", unsorted_nest_list);
	Supervisor::report_nest_list(1, I"shared", shared_nest_list);
	SVEXPLAIN(1, "(shared internal nest: %p)\n", Nests::get_location(shared_internal_nest));
	SVEXPLAIN(1, "(shared external nest: %p)\n", Nests::get_location(shared_external_nest));
}

void Supervisor::report_nest_list(int level, text_stream *desc, linked_list *L) {
	SVEXPLAIN(level, "(%S nest list:", desc);
	if (LinkedLists::len(L) == 0) { SVEXPLAIN(level, " empty)\n"); return; }
	inbuild_nest *N;
	LOOP_OVER_LINKED_LIST(N, inbuild_nest, L)
		SVEXPLAIN(level, "\n    %S %p",
			Nests::tag_name(Nests::get_tag(N)), Nests::get_location(N));
	SVEXPLAIN(level, ")\n");
}

@ And the rest of Inform or Inbuild can now use:

=
linked_list *Supervisor::shared_nest_list(void) {
	RUN_ONLY_FROM_PHASE(NESTED_INBUILD_PHASE)
	if (shared_nest_list == NULL) internal_error("nest list never sorted");
	return shared_nest_list;
}

inbuild_nest *Supervisor::internal(void) {
	RUN_ONLY_FROM_PHASE(NESTED_INBUILD_PHASE)
	return shared_internal_nest;
}

inbuild_nest *Supervisor::external(void) {
	RUN_ONLY_FROM_PHASE(NESTED_INBUILD_PHASE)
	return shared_external_nest;
}

@ This is the default location for internal resources, to be used if there is
no better indication of where they are.

=
pathname *supervisor_tools_location = NULL;

void Supervisor::set_tools_location(pathname *P) {
	supervisor_tools_location = P;
}

pathname *Supervisor::default_internal_path(void) {
	pathname *P = supervisor_tools_location;
	P = Pathnames::down(P, I"inform7");
	P = Pathnames::down(P, I"Internal");
	return P;
}

@ This tells the //html// module where to find, say, CSS files. Those files
are not managed by //inbuild//, have no versions, or anything fancy: they're
just plain old files.

@d INSTALLED_FILES_HTML_CALLBACK Supervisor::installed_files

=
pathname *Supervisor::installed_files(void) {
	if (shared_internal_nest) return shared_internal_nest->location;
	return Supervisor::default_internal_path();
}

@ As noted above, the transient area is used for ephemera such as dynamically
written documentation and telemetry files. |-transient| sets it, but otherwise
the external nest is used.

=
pathname *Supervisor::transient(void) {
	RUN_ONLY_FROM_PHASE(TINKERING_INBUILD_PHASE)
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

It is also possible to set a folder to be the project bundle, and nevertheless
specify a file somewhere else to be the source text. What you can't do is
specify the bundle twice, or specify the file twice.

=
pathname *project_bundle_request = NULL;
filename *project_file_request = NULL;

int Supervisor::set_I7_source(filename *F) {
	RUN_ONLY_FROM_PHASE(CONFIGURATION_INBUILD_PHASE)
	if (project_file_request) return FALSE;
	project_file_request = F;
	SVEXPLAIN(1, "(set project source file to: %f)\n", project_file_request);
	return TRUE;
}

@ If we are given a |-project| on the command line, we can then work out
where its Materials folder is, and therefore where any expert settings files
would be. Note that the name of the expert settings file depends on the name
of the parent, i.e., it will be |inform7-settings.txt| or |inbuild-settings.txt|
depending on who's asking.

=
int Supervisor::set_I7_bundle(pathname *P) {
	RUN_ONLY_FROM_PHASE(CONFIGURATION_INBUILD_PHASE)
	if (project_bundle_request) return FALSE;
	project_bundle_request = P;
	SVEXPLAIN(1, "(set project bundle path to: %p)\n", project_bundle_request);
	pathname *materials = Projects::materialise_pathname(
		Pathnames::up(P), Pathnames::directory_name(P));
	TEMPORARY_TEXT(leaf)
	WRITE_TO(leaf, "%s-settings.txt", PROGRAM_NAME);
	filename *expert_settings = Filenames::in(materials, leaf);
	if (TextFiles::exists(expert_settings)) {
		SVEXPLAIN(1, "(reading further command-line settings from: %f)\n", expert_settings);
		CommandLine::also_read_file(expert_settings);
	} else {
		SVEXPLAIN(2, "(no command-line settings file found at %f)\n", expert_settings);
	}
	DISCARD_TEXT(leaf)
	return TRUE;
}

@ This is a deceptively simple-looking function, which took a lot of time
to get right. The situation is that the parent tool may already have
identified a copy |C| to be the main Inform project of this run, or it may not.
If it has, we ignore |-project| but apply |-source| to change its source text
location. If it hasn't, we create a project using |-project| if possible,
|-source| if not, and in either case apply |-source| to the result.

=
inform_project *chosen_project = NULL;

void Supervisor::make_project_from_command_line(inbuild_copy *C) {
	RUN_ONLY_IN_PHASE(PRETINKERING_INBUILD_PHASE)

	filename *F = NULL; /* result of |-source| at the command line */
	pathname *P = NULL; /* result of |-project| at the command line */
	if (project_bundle_request) P = project_bundle_request;
	if (project_file_request) F = project_file_request;
	if (C) {
		if (C->location_if_path) {
			SVEXPLAIN(1, "(project identified by parent tool: %p)\n", C->location_if_path);
		} else {
			SVEXPLAIN(1, "(project identified by parent tool: %f)\n", C->location_if_file);
		}
	} else if (P) {
		SVEXPLAIN(1, "(project identified by -project: %p)\n", P);
		C = ProjectBundleManager::claim_folder_as_copy(P);
		if (C == NULL) Errors::fatal("No such Inform project directory");
	} else if (F) {
		SVEXPLAIN(1, "(project identified by -source: %f)\n", F);
		C = ProjectFileManager::claim_file_as_copy(F);
		if (C == NULL) Errors::fatal("No such Inform source file");
	} else {
		SVEXPLAIN(1, "(no designated project)\n");
	}
	if (C) {
		inform_project *proj = Projects::from_copy(C);
		if (proj == NULL) internal_error("chosen project is not a project");
		if (F) {
			Projects::set_primary_source(proj, F);
			Projects::set_primary_output(proj, transpiled_output_file);
			if (transpiled_output_file)
				SVEXPLAIN(1, "(transpiled output redirected to: %f)\n", transpiled_output_file);
		}
		chosen_project = proj;
	}
}

inform_project *Supervisor::project_set_at_command_line(void) {
	return chosen_project;
}
