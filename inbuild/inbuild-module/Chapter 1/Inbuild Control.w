[Inbuild::] Inbuild Control.

The top-level controller through which client tools use this module.

@h Phases.
Although nothing at all clever happens in this section, it requires careful
sequencing to avoid invisible errors coming in because function X assumes
that function Y has already been called, or perhaos that it never will
be again. The client tool ("the tool") has to work in the following way
to avoid those problems.

Firstly, the inbuild module runs through the following phases in sequence:

@e CONFIGURATION_INBUILD_PHASE from 1
@e PRETINKERING_INBUILD_PHASE
@e TINKERING_INBUILD_PHASE
@e NESTED_INBUILD_PHASE
@e PROJECTED_INBUILD_PHASE
@e GOING_OPERATIONAL_INBUILD_PHASE
@e OPERATIONAL_INBUILD_PHASE

@d RUN_ONLY_IN_PHASE(P)
	if (inbuild_phase < P) internal_error("too soon");
	if (inbuild_phase > P) internal_error("too late");
@d RUN_ONLY_FROM_PHASE(P)
	if (inbuild_phase < P) internal_error("too soon");
@d RUN_ONLY_BEFORE_PHASE(P)
	if (inbuild_phase >= P) internal_error("too late");

=
int inbuild_phase = CONFIGURATION_INBUILD_PHASE;

@ Initially, then, we are in the configuration phase. This is when command
line processing should be done, and the tool should use the following routines
to add and process command line switches handled by inbuild:

@e INBUILD_CLSG

@e NEST_CLSW
@e INTERNAL_CLSW
@e EXTERNAL_CLSW
@e TRANSIENT_CLSW
@e KIT_CLSW
@e PROJECT_CLSW
@e SOURCE_CLSW
@e DEBUG_CLSW
@e FORMAT_CLSW
@e RELEASE_CLSW
@e CENSUS_CLSW
@e PIPELINE_CLSW
@e PIPELINE_FILE_CLSW
@e PIPELINE_VARIABLE_CLSW

=
void Inbuild::declare_options(void) {
	RUN_ONLY_IN_PHASE(CONFIGURATION_INBUILD_PHASE)
	CommandLine::begin_group(INBUILD_CLSG);
	CommandLine::declare_switch(NEST_CLSW, L"nest", 2,
		L"add the nest at pathname X to the search list");
	CommandLine::declare_switch(INTERNAL_CLSW, L"internal", 2,
		L"use X as the location of built-in material such as the Standard Rules");
	CommandLine::declare_switch(EXTERNAL_CLSW, L"external", 2,
		L"use X as the user's home for installed material such as extensions");
	CommandLine::declare_switch(TRANSIENT_CLSW, L"transient", 2,
		L"use X for transient data such as the extensions census");
	CommandLine::declare_switch(KIT_CLSW, L"kit", 2,
		L"load the Inform kit called X");
	CommandLine::declare_switch(PROJECT_CLSW, L"project", 2,
		L"work within the Inform project X");
	CommandLine::declare_boolean_switch(DEBUG_CLSW, L"debug", 1,
		L"compile with debugging features even on a Release");
	CommandLine::declare_boolean_switch(RELEASE_CLSW, L"release", 1,
		L"compile a version suitable for a Release build");
	CommandLine::declare_textual_switch(FORMAT_CLSW, L"format", 1,
		L"compile I6 code suitable for the virtual machine X");
	CommandLine::declare_switch(SOURCE_CLSW, L"source", 2,
		L"use file X as the Inform source text");
	CommandLine::declare_boolean_switch(CENSUS_CLSW, L"census", 1,
		L"perform an extensions census");
	CommandLine::declare_switch(PIPELINE_CLSW, L"pipeline", 2,
		L"specify code-generation pipeline");
	CommandLine::declare_switch(PIPELINE_FILE_CLSW, L"pipeline-file", 2,
		L"specify code-generation pipeline from file X");
	CommandLine::declare_switch(PIPELINE_VARIABLE_CLSW, L"variable", 2,
		L"set pipeline variable X (in form name=value)");
	CommandLine::end_group();
	
	Inbuild::set_defaults();
}

text_stream *inter_processing_file = NULL;
text_stream *inter_processing_pipeline = NULL;
dictionary *pipeline_vars = NULL;
pathname *shared_transient_resources = NULL;
int this_is_a_debug_compile = FALSE; /* Destined to be compiled with debug features */
int this_is_a_release_compile = FALSE; /* Omit sections of source text marked not for release */
text_stream *story_filename_extension = NULL; /* What story file we will eventually have */
int census_mode = FALSE; /* Running only to update extension documentation */

void Inbuild::set_defaults(void) {
	inter_processing_pipeline = Str::new();
	inter_processing_file = I"compile";
}

void Inbuild::option(int id, int val, text_stream *arg, void *state) {
	RUN_ONLY_IN_PHASE(CONFIGURATION_INBUILD_PHASE)
	switch (id) {
		case DEBUG_CLSW: this_is_a_debug_compile = val; break;
		case FORMAT_CLSW: story_filename_extension = Str::duplicate(arg); break;
		case RELEASE_CLSW: this_is_a_release_compile = val; break;
		case NEST_CLSW: Inbuild::add_nest(Pathnames::from_text(arg), GENERIC_NEST_TAG); break;
		case INTERNAL_CLSW: Inbuild::add_nest(Pathnames::from_text(arg), INTERNAL_NEST_TAG); break;
		case EXTERNAL_CLSW: Inbuild::add_nest(Pathnames::from_text(arg), EXTERNAL_NEST_TAG); break;
		case TRANSIENT_CLSW: shared_transient_resources = Pathnames::from_text(arg); break;
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
		case PIPELINE_CLSW: inter_processing_pipeline = Str::duplicate(arg); break;
		case PIPELINE_FILE_CLSW: inter_processing_file = Str::duplicate(arg); break;
		case PIPELINE_VARIABLE_CLSW: {
			match_results mr = Regexp::create_mr();
			if (Regexp::match(&mr, arg, L"(%c+)=(%c+)")) {
				if (Str::get_first_char(arg) != '*') {
					Errors::fatal("-variable names must begin with '*'");
				} else {
					#ifdef CODEGEN_MODULE
					if (pipeline_vars == NULL)
						pipeline_vars = CodeGen::Pipeline::basic_dictionary(I"output.z8");
					Str::copy(Dictionaries::create_text(pipeline_vars, mr.exp[0]), mr.exp[1]);
					#endif
				}
			} else {
				Errors::fatal("-variable should take the form 'name=value'");
			}
			Regexp::dispose_of(&mr);
			break;
		}
	}
}

@ Once the tool has finished with the command line, it should call this
function. Inbuild rapidly runs through the next few phases as it does so.
From the "nested" phase, the final list of nests in the search path for
finding kits, extensions and so on exists; from the "projected" phase,
the main Inform project exists. As we shall see, Inbuild deals with only
one Inform project at a time, though it may be handling many kits and
extensions, and so on, which are needed by that project.

=
target_vm *current_target_VM = NULL;
inbuild_copy *Inbuild::optioneering_complete(inbuild_copy *C, int compile_only) {
	RUN_ONLY_IN_PHASE(CONFIGURATION_INBUILD_PHASE)

	#ifdef CODEGEN_MODULE
	if (pipeline_vars == NULL)
		pipeline_vars = CodeGen::Pipeline::basic_dictionary(I"output.z8");
	#endif

	target_vm *VM = NULL;
	text_stream *ext = story_filename_extension;
	if (Str::len(ext) == 0) ext = I"ulx";
	int with_debugging = FALSE;
	if ((this_is_a_release_compile == FALSE) || (this_is_a_debug_compile))
		with_debugging = TRUE;
	VM = TargetVMs::find(ext, with_debugging);

	inbuild_phase = PRETINKERING_INBUILD_PHASE;
	inform_project *project = Inbuild::create_shared_project(C);
	
	inbuild_phase = TINKERING_INBUILD_PHASE;
	Inbuild::sort_nest_list();
	inbuild_phase = NESTED_INBUILD_PHASE;
	if (project) Projects::set_to_English(project);
	Inbuild::pass_kit_requests();
	inbuild_phase = PROJECTED_INBUILD_PHASE;

	if (project) {
		Projects::construct_build_target(project, VM, this_is_a_release_compile, compile_only);
		current_target_VM = VM;
		return project->as_copy;
	} else {
		return NULL;
	}
}

target_vm *Inbuild::current_vm(void) {
	return current_target_VM;
}
int Inbuild::currently_releasing(void) {
	return this_is_a_release_compile;
}

@ Inbuild is now in the "projected" phase, then. The idea is that this
is a short interval during which the tool can if it wishes add further
kit dependencies to the main project. Once that sort of thing is done,
the tool should call the following, which puts Inbuild into its
final "operational" phase -- at this point Inbuild is fully configured
and ready for use.

The brief "going operational" phase is used, for example, to build out
dependency graphs.

=
inform_project *Inbuild::go_operational(void) {
	RUN_ONLY_IN_PHASE(PROJECTED_INBUILD_PHASE)
	inbuild_phase = GOING_OPERATIONAL_INBUILD_PHASE;
	inbuild_copy *C;
	LOOP_OVER(C, inbuild_copy)
		Copies::go_operational(C);
	inbuild_phase = OPERATIONAL_INBUILD_PHASE;
	if (census_mode) Extensions::Census::handle_census_mode();
	return Inbuild::project();
}

@h The nest list.
Nests used by the Inform and Inbuild tools are tagged with the following
comstamts, except that no nest is ever tagged |NOT_A_NEST_TAG|.
(There used to be quite a good joke here, but refactoring of the
code removed its premiss. Literate programming is like that sometimes.)

@e NOT_A_NEST_TAG from 0
@e MATERIALS_NEST_TAG
@e EXTERNAL_NEST_TAG
@e GENERIC_NEST_TAG
@e INTERNAL_NEST_TAG

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

@ The transient area is used for ephemera such as dynamically written
documentation and telemetry files. |-transient| sets it, but otherwise
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

int Inbuild::set_I7_bundle(text_stream *loc) {
	RUN_ONLY_FROM_PHASE(CONFIGURATION_INBUILD_PHASE)
	if (Str::len(project_bundle_request) > 0) return FALSE;
	project_bundle_request = Str::duplicate(loc);
	pathname *pathname_of_bundle = Pathnames::from_text(project_bundle_request);
	pathname *materials = Inbuild::pathname_of_materials(pathname_of_bundle);
	TEMPORARY_TEXT(leaf);
	WRITE_TO(leaf, "%s-settings.txt", INTOOL_NAME);
	filename *expert_settings = Filenames::in_folder(materials, leaf);
	LOG("Speculatively %f\n", expert_settings);
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
	RUN_ONLY_FROM_PHASE(PROJECTED_INBUILD_PHASE)
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
			Projects::add_kit_dependency(shared_project, kit_name);
			Projects::not_necessarily_parser_IF(shared_project);
		}
	}
}

@h Installation.
Inform and its associated tools need to be able to see certain files stored
in the internal nest: if they aren't there, then Inform is not properly
installed on disc.

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
		case CBLORB_REPORT_MODEL_IRES: return Filenames::in_folder(models, I"CblorbModel.html");
		case DOCUMENTATION_SNIPPETS_IRES: return Filenames::in_folder(misc, I"definitions.html");
		case INTRO_BOOKLET_IRES: return Filenames::in_folder(misc, I"IntroductionToIF.pdf");
		case INTRO_POSTCARD_IRES: return Filenames::in_folder(misc, I"Postcard.pdf");
		case LARGE_DEFAULT_COVER_ART_IRES: return Filenames::in_folder(misc, I"Cover.jpg");
		case SMALL_DEFAULT_COVER_ART_IRES: return Filenames::in_folder(misc, I"Small Cover.jpg");
		case DOCUMENTATION_XREFS_IRES: return Filenames::in_folder(models, I"xrefs.txt");
		case JAVASCRIPT_FOR_STANDARD_PAGES_IRES: return Filenames::in_folder(models, I"main.js");
		case JAVASCRIPT_FOR_EXTENSIONS_IRES: return Filenames::in_folder(models, I"extensions.js");
		case JAVASCRIPT_FOR_ONE_EXTENSION_IRES: return Filenames::in_folder(models, I"extensionfile.js");
		case CSS_FOR_STANDARD_PAGES_IRES: return Filenames::in_folder(models, I"main.css");
		case EXTENSION_DOCUMENTATION_MODEL_IRES: return Filenames::in_folder(models, I"extensionfile.html");
	}
	internal_error("unknown installation resource file");
	return NULL;
}
