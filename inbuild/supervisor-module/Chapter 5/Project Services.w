[Projects::] Project Services.

Behaviour specific to copies of either the projectbundle or projectfile genres.

@h Scanning metadata.
Metadata for projects is stored in the following structure.

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
	struct linked_list *kit_names_to_include; /* of |JSON_value| */
	struct linked_list *kits_to_include; /* of |kit_dependency| */
	struct text_stream *name_of_language_of_play;
	struct inform_language *language_of_play;
	struct text_stream *name_of_language_of_syntax;
	struct inform_language *language_of_syntax;
	struct text_stream *name_of_language_of_index;
	struct inform_language *language_of_index;
	struct build_vertex *unblorbed_vertex;
	struct build_vertex *blorbed_vertex;
	struct build_vertex *chosen_build_target;
	struct parse_node_tree *syntax_tree;
	struct linked_list *extensions_included; /* of |inform_extension| */
	struct linked_list *activations; /* of |element_activation| */
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
	proj->kit_names_to_include = NEW_LINKED_LIST(JSON_value);
	proj->kits_to_include = NEW_LINKED_LIST(kit_dependency);
	proj->name_of_language_of_play = I"English";
	proj->language_of_play = NULL;
	proj->name_of_language_of_syntax = I"English";
	proj->language_of_syntax = NULL;
	proj->name_of_language_of_index = NULL;
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
	proj->activations = NEW_LINKED_LIST(element_activation);
	Projects::scan_bibliographic_data(proj);
	filename *F = Filenames::in(M, I"project_metadata.json");
	if (TextFiles::exists(F)) {
		JSONMetadata::read_metadata_file(C, F, NULL, NULL);
		if (C->metadata_record) {
			JSON_value *is = JSON::look_up_object(C->metadata_record, I"is");
			if (is) {
				JSON_value *version = JSON::look_up_object(is, I"version");
				if (version) {
					proj->version = VersionNumbers::from_text(version->if_string);
				}
			}
			@<Extract activations@>;
			JSON_value *project_details =
				JSON::look_up_object(C->metadata_record, I"project-details");
			if (project_details) {
				@<Extract the project details@>;
			}
			JSON_value *needs = JSON::look_up_object(C->metadata_record, I"needs");
			if (needs) {
				JSON_value *E;
				LOOP_OVER_LINKED_LIST(E, JSON_value, needs->if_list)
					@<Extract this requirement@>;
			}
		}
	} else {
		SVEXPLAIN(2, "(no JSON metadata file found at %f)\n", F);
	}
}

@<Extract activations@> =
	JSON_value *activates = JSON::look_up_object(C->metadata_record, I"activates");
	if (activates) {
		JSON_value *E;
		LOOP_OVER_LINKED_LIST(E, JSON_value, activates->if_list)
			Projects::activation(proj, E->if_string, TRUE);
	}
	JSON_value *deactivates = JSON::look_up_object(C->metadata_record, I"deactivates");
	if (deactivates) {
		JSON_value *E;
		LOOP_OVER_LINKED_LIST(E, JSON_value, deactivates->if_list)
			Projects::activation(proj, E->if_string, FALSE);
	}

@<Extract the project details@> =
	;

@<Extract this requirement@> =
	JSON_value *if_clause = JSON::look_up_object(E, I"if");
	JSON_value *unless_clause = JSON::look_up_object(E, I"unless");
	if ((if_clause) || (unless_clause)) {
		TEMPORARY_TEXT(err)
		WRITE_TO(err, "a project's needs must be unconditional");
		Copies::attach_error(C, CopyErrors::new_T(METADATA_MALFORMED_CE, -1, err));
		DISCARD_TEXT(err)	
	}
	JSON_value *need_clause = JSON::look_up_object(E, I"need");
	if (need_clause) {
		JSON_value *need_type = JSON::look_up_object(need_clause, I"type");
		JSON_value *need_version_range = JSON::look_up_object(need_clause, I"version-range");
		if (need_version_range) {
			TEMPORARY_TEXT(err)
			WRITE_TO(err, "version ranges on project dependencies are not yet implemented");
			Copies::attach_error(C, CopyErrors::new_T(METADATA_MALFORMED_CE, -1, err));
			DISCARD_TEXT(err)
		}
		if (Str::eq(need_type->if_string, I"kit")) {
			ADD_TO_LINKED_LIST(need_clause, JSON_value, proj->kit_names_to_include);
		} else if (Str::eq(need_type->if_string, I"extension")) {
			;
		} else {
			TEMPORARY_TEXT(err)
			WRITE_TO(err, "a project can only have kits or extensions as dependencies");
			Copies::attach_error(C, CopyErrors::new_T(METADATA_MALFORMED_CE, -1, err));
			DISCARD_TEXT(err)
		}
	}

@ Language elements can similarly be activated or deactivated, though the
latter may not be useful in practice:

=
void Projects::activation(inform_project *proj, text_stream *name, int act) {
	element_activation *EA = CREATE(element_activation);
	EA->element_name = Str::duplicate(name);
	EA->activate = act;
	ADD_TO_LINKED_LIST(EA, element_activation, proj->activations);
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

void Projects::add_language_extension_nest(inform_project *proj) {
	if ((proj->language_of_play) && (proj->language_of_play->belongs_to)) {
		inform_extension *E = proj->language_of_play->belongs_to;
		inbuild_nest *N = Extensions::materials_nest(E);
		if (N) ADD_TO_LINKED_LIST(N, inbuild_nest, proj->search_list);
	}
}

@ Since there are two ways projects can be stored:

=
inform_project *Projects::from_copy(inbuild_copy *C) {
	inform_project *project = ProjectBundleManager::from_copy(C);
	if (project == NULL) project = ProjectFileManager::from_copy(C);
	return project;
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
		@<Try the source file set at the command line, if any was@>;
	if (LinkedLists::len(proj->source_vertices) == 0)
		@<Fall back on the traditional choice@>;
	return proj->source_vertices;
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

@ Further source files may become apparent when headings are read in the
source text we already have, and which refer to specific files in the |Source|
subdirectory of the materials directory; so those are added here. (This happens
safely before the full graph for the project is made, so they do appear in
that dependency graph.)

=
void Projects::add_heading_source(inform_project *proj, text_stream *path) {
	pathname *P = NULL;
	if (proj->as_copy->location_if_path)
		P = Pathnames::down(Projects::materials_path(proj), I"Source");
	if (P) {
		build_vertex *S = Graphs::file_vertex(Filenames::in(P, path));
		S->source_source = Str::duplicate(path);
		ADD_TO_LINKED_LIST(S, build_vertex, proj->source_vertices);
	}
}

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

@h Version.

=
semantic_version_number Projects::get_version(inform_project *proj) {
	if (proj == NULL) return VersionNumbers::null();
	return proj->version;
}

@h The project's languages.
Inform's ability to work outside of English is limited, at present, but for
the sake of future improvements we want to distinguish three uses of natural
language. In principle, a project could use different languages for each of
these.

First, the "language of play" is the one in which dialogue is printed and parsed
at run-time.

=
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
inform_language *Projects::get_language_of_syntax(inform_project *proj) {
	if (proj == NULL) return NULL;
	return proj->language_of_syntax;
}

@ And this is where the languages of play and syntax are set, using metadata
previously extracted by //Projects::scan_bibliographic_data//. Note that they
are set only once, and can't be changed after that.

=
void Projects::set_languages(inform_project *proj) {
	if (proj == NULL) internal_error("no project");

	text_stream *name = proj->name_of_language_of_syntax;
	inform_language *L = Languages::find_for(name, Projects::nest_list(proj));
	if (L) {
		if (Languages::supports(L, WRITTEN_LSUPPORT)) {
			proj->language_of_syntax = L;
			Projects::add_language_extension_nest(proj);
		} else {
			TEMPORARY_TEXT(err)
			WRITE_TO(err,
				"this project asks to be 'written in' a language which does not support that");
			Copies::attach_error(proj->as_copy,
				CopyErrors::new_T(LANGUAGE_DEFICIENT_CE, -1, err));
			DISCARD_TEXT(err)
		}
	} else {
		build_vertex *RV = Graphs::req_vertex(
			Requirements::any_version_of(Works::new(language_genre, name, I"")));
		Graphs::need_this_to_build(proj->as_copy->vertex, RV);
	}

	name = proj->name_of_language_of_play;
	L = Languages::find_for(name, Projects::nest_list(proj));
	if (L) {
		if (Languages::supports(L, PLAYED_LSUPPORT)) {
			proj->language_of_play = L;
			Projects::add_language_extension_nest(proj);
		} else {
			TEMPORARY_TEXT(err)
			WRITE_TO(err,
				"this project asks to be 'played in' a language which does not support that");
			Copies::attach_error(proj->as_copy,
				CopyErrors::new_T(LANGUAGE_DEFICIENT_CE, -1, err));
			DISCARD_TEXT(err)
		}
	} else {
		build_vertex *RV = Graphs::req_vertex(
			Requirements::any_version_of(Works::new(language_genre, name, I"")));
		Graphs::need_this_to_build(proj->as_copy->vertex, RV);
	}

	if (Str::len(proj->name_of_language_of_index) == 0)
		proj->language_of_index = proj->language_of_syntax;
	else {
		name = proj->name_of_language_of_index;
		L = Languages::find_for(name, Projects::nest_list(proj));
		if (L) {
			if (Languages::supports(L, INDEXED_LSUPPORT)) {
				proj->language_of_index = L;
				Projects::add_language_extension_nest(proj);
			} else {
				TEMPORARY_TEXT(err)
				WRITE_TO(err,
					"this project asks to be 'indexed in' a language which does not support that");
				Copies::attach_error(proj->as_copy,
					CopyErrors::new_T(LANGUAGE_DEFICIENT_CE, -1, err));
				DISCARD_TEXT(err)
			}
		} else {
			build_vertex *RV = Graphs::req_vertex(
				Requirements::any_version_of(Works::new(language_genre, name, I"")));
			Graphs::need_this_to_build(proj->as_copy->vertex, RV);
		}
	}
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
int Projects::add_kit_dependency(inform_project *project, text_stream *kit_name,
	inform_language *because_of_language, inform_kit *because_of_kit,
	inbuild_requirement *req, linked_list *nests) {
	if (Projects::uses_kit(project, kit_name)) return TRUE;
	if (nests == NULL) nests = Projects::nest_list(project);
	inform_kit *K = Kits::find_by_name(kit_name, nests, req);
	if (K) {
		kit_dependency *kd = CREATE(kit_dependency);
		kd->kit = K;
		kd->because_of_language = because_of_language;
		kd->because_of_kit = because_of_kit;
		ADD_TO_LINKED_LIST(kd, kit_dependency, project->kits_to_include);
		return TRUE;
	} else {
		build_vertex *RV = Graphs::req_vertex(
			Requirements::any_version_of(Works::new_raw(kit_genre, kit_name, I"")));
		Graphs::need_this_to_build(project->as_copy->vertex, RV);
		LOG("Required but could not find kit %S\n", kit_name);
		return FALSE;
	}
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
int forcible_basic_mode = FALSE;

void Projects::enter_forcible_basic_mode(void) {
	forcible_basic_mode = TRUE;
}

void Projects::finalise_kit_dependencies(inform_project *project) {
	@<Add dependencies for the standard kits@>;
	int parity = TRUE; @<Perform if-this-then-that@>;
	parity = FALSE; @<Perform if-this-then-that@>;
	@<Sort the kit dependency list into priority order@>;
	@<Log what the dependencies actually were@>;
	@<Police forcible basic mode@>;
}

@ Note that //CommandParserKit//, if depended, will cause a further dependency
on //WorldModelKit//, through the if-this-then-that mechanism.

@<Add dependencies for the standard kits@> =
	int no_word_from_JSON = TRUE;
	JSON_value *need;
	LOOP_OVER_LINKED_LIST(need, JSON_value, project->kit_names_to_include) {
		JSON_value *need_title = JSON::look_up_object(need, I"title");
		inbuild_work *work = Works::new_raw(kit_genre, need_title->if_string, I"");
		JSON_value *need_version = JSON::look_up_object(need, I"version");
		inbuild_requirement *req;
		if (need_version)
			req = Requirements::new(work,
				VersionNumberRanges::compatibility_range(
					VersionNumbers::from_text(need_version->if_string)));
		else
			req = Requirements::any_version_of(work);
		Projects::add_kit_dependency(project, need_title->if_string, NULL, NULL, req, NULL);
	}
	if (LinkedLists::len(project->kits_to_include) > 0) no_word_from_JSON = FALSE;
	Projects::add_kit_dependency(project, I"BasicInformKit", NULL, NULL, NULL, NULL);
	
	if (TargetVMs::is_16_bit(Supervisor::current_vm()))
		Projects::add_kit_dependency(project, I"Architecture16Kit", NULL, NULL, NULL, NULL);
	else	
		Projects::add_kit_dependency(project, I"Architecture32Kit", NULL, NULL, NULL, NULL);
	
	inform_language *L = project->language_of_play;
	if (L) {
		Languages::add_kit_dependencies_to_project(L, project);
	} else {
		Copies::attach_error(project->as_copy,
			CopyErrors::new_T(LANGUAGE_UNAVAILABLE_CE, -1,
				project->name_of_language_of_play));
	}
	if ((no_word_from_JSON) && (forcible_basic_mode == FALSE))
		Projects::add_kit_dependency(project, I"CommandParserKit", NULL, NULL, NULL, NULL);

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

@<Police forcible basic mode@> =
	if (forcible_basic_mode) {
		int basic = TRUE;
		kit_dependency *kd;
		LOOP_OVER_LINKED_LIST(kd, kit_dependency, project->kits_to_include)
			if ((Str::eq(kd->kit->as_copy->edition->work->title, I"CommandParserKit")) ||
				(Str::eq(kd->kit->as_copy->edition->work->title, I"WorldModelKit")) ||
				(Str::eq(kd->kit->as_copy->edition->work->title, I"DialogueKit")))
				basic = FALSE;
		if (basic == FALSE) {
			TEMPORARY_TEXT(err)
			WRITE_TO(err,
				"the project_metadata.json file shows this cannot be built in basic mode");
			Copies::attach_error(project->as_copy,
				CopyErrors::new_T(METADATA_MALFORMED_CE, -1, err));
			DISCARD_TEXT(err)
		}
	}

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
void Projects::activate_elements(inform_project *project) {
	Features::activate_bare_minimum();
	element_activation *EA;
	LOOP_OVER_LINKED_LIST(EA, element_activation, project->activations) {
		compiler_feature *P = Features::from_name(EA->element_name);
		if (P == NULL) {
			TEMPORARY_TEXT(err)
			WRITE_TO(err, "project metadata refers to unknown compiler feature '%S'", EA->element_name);
			Copies::attach_error(project->as_copy, CopyErrors::new_T(METADATA_MALFORMED_CE, -1, err));
			DISCARD_TEXT(err)	
		} else {
			if (EA->activate) Features::activate(P);
			else if (Features::deactivate(P) == FALSE) {
				TEMPORARY_TEXT(err)
				WRITE_TO(err, "project metadata asks to deactivate mandatory compiler feature '%S'",
					EA->element_name);
				Copies::attach_error(project->as_copy, CopyErrors::new_T(METADATA_MALFORMED_CE, -1, err));
				DISCARD_TEXT(err)	
			}
		}
	}
	kit_dependency *kd;
	LOOP_OVER_LINKED_LIST(kd, kit_dependency, project->kits_to_include)
		Kits::activate_elements(kd->kit);
	LOG("Included by the end of the kit stage: "); Features::list(DL, TRUE, NULL);
	LOG("\n");
}

void Projects::activate_extension_elements(inform_project *project) {
	inform_extension *ext;
	LOOP_OVER_LINKED_LIST(ext, inform_extension, project->extensions_included)
		Extensions::activate_elements(ext, project);
	kit_dependency *kd;
	LOOP_OVER_LINKED_LIST(kd, kit_dependency, project->kits_to_include)
		Kits::activate_elements(kd->kit);
	
	LOG("Included by the end of the extension stage: "); Features::list(DL, TRUE, NULL);
	LOG("\n");
	LOG("Excluded: "); Features::list(DL, FALSE, NULL);
	LOG("\n");
}

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

@ We can find a kit as used by a project:

=
inform_kit *Projects::get_linked_kit(inform_project *project, text_stream *name) {
	kit_dependency *kd;
	LOOP_OVER_LINKED_LIST(kd, kit_dependency, project->kits_to_include) {
		inform_kit *kit = kd->kit;
		if (Str::eq_insensitive(kit->as_copy->edition->work->title, name))
			return kit;
	}
	return NULL;
}

@ And find an exhaustive collection:

=
linked_list *Projects::list_of_kit_configurations(inform_project *project) {
	linked_list *L = NEW_LINKED_LIST(kit_configuration);
	kit_dependency *kd;
	LOOP_OVER_LINKED_LIST(kd, kit_dependency, project->kits_to_include) {
		inform_kit *kit = kd->kit;
		kit_configuration *kc;
		LOOP_OVER_LINKED_LIST(kc, kit_configuration, kit->configurations)
			ADD_TO_LINKED_LIST(kc, kit_configuration, L);
	}
	return L;
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

@h Detecting dialogue.
There's an awkward timing issue with detecting dialogue in the source text.
The rule is that an Inform project should depend on DialogueKit if it contains
content under a dialogue section, but not otherwise. That in turn activates
the "dialogue" compiler feature. On the other hand, the source text also has
material placed under headings which are for use with dialogue only. So we
can't read the entire source text first and then decide: we have to switch
on the dialogue feature the moment any dialogue matter is found. This is
done by having the //syntax// module call the following:

=
inform_project *project_being_scanned = NULL;
void Projects::dialogue_present(void) {
	if (project_being_scanned) {
		Projects::add_kit_dependency(project_being_scanned, I"DialogueKit", NULL, NULL, NULL, NULL);
		Projects::activate_elements(project_being_scanned);
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
		project_being_scanned = proj;
		Copies::get_source_text(proj->as_copy);
		project_being_scanned = NULL;
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
		inform_extension *E = Extensions::from_copy(V->as_copy);
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
	inform_language *E = Languages::find_for(I"English", Projects::nest_list(proj));
	if (E == NULL) return;
	Languages::read_Preform_definition(E, proj->search_list);
	if ((proj->language_of_syntax) && (proj->language_of_syntax != E)) {
		if (Languages::read_Preform_definition(
			proj->language_of_syntax, proj->search_list) == FALSE) {
			copy_error *CE = CopyErrors::new_T(SYNTAX_CE, UnavailableLOS_SYNERROR,
				proj->language_of_syntax->as_copy->edition->work->title);
			Copies::attach_error(proj->as_copy, CE);
		}
	}
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
	Headings::place_implied_level_0(proj->syntax_tree, inclusions_heading, proj->as_copy);

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
		SVEXPLAIN(1, "(from %f)\n", F);
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
	Headings::place_implied_level_0(proj->syntax_tree, implicit_heading, proj->as_copy);
	SyntaxTree::pop_bud(proj->syntax_tree, l);
	SyntaxTree::push_bud(proj->syntax_tree, implicit_heading); /* never popped */

@ The ordering here is, as so often in this section of code, important. We
have to know which language elements are in use before we can safely look
for Include... sentences, because some of those sentences are conditional
on that. We have to perform the tree surgery asked for by Include... in
place of... instructions after the sweep for inclusions.

@<Post-process the syntax tree@> =
	Projects::activate_elements(proj);
	Inclusions::traverse(proj->as_copy, proj->syntax_tree);
	Headings::satisfy_dependencies(proj, proj->syntax_tree, proj->as_copy);
	Projects::activate_extension_elements(proj);

@h The bibliographic sentence.
It might seem sensible to parse the opening sentence of the source text,
the bibliographic sentence giving title and author, by looking at the result
of sentence-breaking: in other words, to wait until the syntax tree for a
project has been read in.

But this isn't fast enough, because the sentence also specifies the language
of syntax, and we need to know of any non-English choice immediately. We
don't even want to use Preform to parse the sentence, either, because we might
want to load a different Preform file depending on that non-English choice.

So the following rapid scan catches just the first sentence of the first
source file of the project.

@e BadTitleSentence_SYNERROR

=
void Projects::scan_bibliographic_data(inform_project *proj) {
	linked_list *L = Projects::source(proj);
	build_vertex *N;
	LOOP_OVER_LINKED_LIST(N, build_vertex, L) {
		filename *F = N->as_file;
		FILE *SF = Filenames::fopen_caseless(F, "r");
		if (SF == NULL) break; /* no source means no bibliographic data */
		@<Read the opening sentence@>;
		fclose(SF);
		break; /* so that we look only at the first source file */
	}
}

@<Read the opening sentence@> =
	TEMPORARY_TEXT(bibliographic_sentence)
	TEMPORARY_TEXT(bracketed)
	@<Capture the opening sentence and its bracketed part@>;
	if ((Str::len(bibliographic_sentence) > 0) &&
		(Str::get_first_char(bibliographic_sentence) == '"'))
		@<The opening sentence is bibliographic, so scan it@>;
	DISCARD_TEXT(bibliographic_sentence)
	DISCARD_TEXT(bracketed)

@ A bibliographic sentence can optionally give a language, by use of "(in ...)":

>> "Bonjour Albertine" by Marcel Proust (in French)

If so, the following writes |"Bonjour Albertine" by Marcel Proust| to the
text |bibliographic_sentence| and |in French| to the text |bracketed|. If not,
the whole thing goes into |bibliographic_sentence| and |bracketed| is empty.

@<Capture the opening sentence and its bracketed part@> =
	int c, commented = FALSE, quoted = FALSE, rounded = FALSE, content_found = FALSE;
	while ((c = TextFiles::utf8_fgetc(SF, NULL, NULL)) != EOF) {
		if (c == 0xFEFF) continue; /* skip the optional Unicode BOM pseudo-character */
		if (commented) {
			if (c == ']') commented = FALSE;
		} else {
			if (quoted) {
				if (rounded) PUT_TO(bracketed, c);
				else PUT_TO(bibliographic_sentence, c);
				if (c == '"') quoted = FALSE;
			} else {
				if (c == '[') commented = TRUE;
				else {
					if (Characters::is_whitespace(c) == FALSE) content_found = TRUE;
					if (rounded) {
						if (c == '"') quoted = TRUE;
						if ((c == '\x0a') || (c == '\x0d') || (c == '\n')) c = ' ';
						if (c == ')') rounded = FALSE;
						else PUT_TO(bracketed, c);
					} else {
						if (c == '(') rounded = TRUE;
						else {
							if ((c == '\x0a') || (c == '\x0d') || (c == '\n')) {
								if (content_found) break;
								c = ' ';
								PUT_TO(bibliographic_sentence, c);
							} else {
								PUT_TO(bibliographic_sentence, c);
							}
							if (c == '"') quoted = TRUE;
						}
					}
				}
			}
		}
	}
	Str::trim_white_space(bibliographic_sentence);			
	Str::trim_white_space(bracketed);			
	if (Str::get_last_char(bibliographic_sentence) == '.')
		Str::delete_last_character(bibliographic_sentence);

@ The author is sometimes given outside of quotation marks:

>> "The Large Scale Structure of Space-Time" by Lindsay Lohan

But not always:

>> "Greek Rural Postmen and Their Cancellation Numbers" by "will.i.am"

@<The opening sentence is bibliographic, so scan it@> =
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, bibliographic_sentence, L"\"([^\"]+)\" by \"([^\"]+)\"")) {
		text_stream *title = mr.exp[0];
		text_stream *author = mr.exp[1];
		@<Set title and author@>;
	} else if (Regexp::match(&mr, bibliographic_sentence, L"\"([^\"]+)\" by ([^\"]+)")) {
		text_stream *title = mr.exp[0];
		text_stream *author = mr.exp[1];
		@<Set title and author@>;
	} else if (Regexp::match(&mr, bibliographic_sentence, L"\"([^\"]+)\"")) {
		text_stream *title = mr.exp[0];
		text_stream *author = NULL;
		@<Set title and author@>;
	} else {
		@<Flag bad bibliographic sentence@>;
	}
	Regexp::dispose_of(&mr);
	if (Str::len(bracketed) > 0) {
		int okay = TRUE;
		match_results mr2 = Regexp::create_mr();
		while (Regexp::match(&mr2, bracketed, L"(%c+?),(%c+)")) {
			okay = (okay && (Projects::parse_language_clauses(proj, mr2.exp[0])));
			bracketed = Str::duplicate(mr2.exp[1]);
		}
		okay = (okay && (Projects::parse_language_clauses(proj, bracketed)));
		if (okay == FALSE) @<Flag bad bibliographic sentence@>;
		Regexp::dispose_of(&mr2);
	}

@<Set title and author@> =
	if (Str::len(title) > 0) {
		text_stream *T = proj->as_copy->edition->work->title;
		Str::clear(T);
		WRITE_TO(T, "%S", title);
	}
	if (Str::len(author) > 0) {
		if (proj->as_copy->edition->work->author_name == NULL)
			proj->as_copy->edition->work->author_name = Str::new();
		text_stream *A = proj->as_copy->edition->work->author_name;
		Str::clear(A);
		WRITE_TO(A, "%S", author);
	}

@<Flag bad bibliographic sentence@> =
	copy_error *CE = CopyErrors::new(SYNTAX_CE, BadTitleSentence_SYNERROR);
	Copies::attach_error(proj->as_copy, CE);

@

=
int Projects::parse_language_clauses(inform_project *proj, text_stream *clause) {
	int verdict = FALSE;
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, clause, L"(%c+?) in (%c+)")) {
		text_stream *what = mr.exp[0];
		text_stream *language_name = mr.exp[1];
		verdict = Projects::parse_language_clause(proj, what, language_name);
	} else if (Regexp::match(&mr, clause, L" *in (%c+)")) {
		text_stream *what = I"played";
		text_stream *language_name = mr.exp[0];
		verdict = Projects::parse_language_clause(proj, what, language_name);
	} else if (Regexp::match(&mr, clause, L" *")) {
		verdict = TRUE;
	}
	Regexp::dispose_of(&mr);
	return verdict;
}

int Projects::parse_language_clause(inform_project *proj, text_stream *what, text_stream *language_name) {
	match_results mr = Regexp::create_mr();
	int verdict = FALSE;
	if (Regexp::match(&mr, what, L"(%c+?), and (%c+)")) {
		verdict = ((Projects::parse_language_clause(proj, mr.exp[0], language_name)) &&
					(Projects::parse_language_clause(proj, mr.exp[1], language_name)));
	} else if (Regexp::match(&mr, what, L"(%c+?), (%c+)")) {
		verdict = ((Projects::parse_language_clause(proj, mr.exp[0], language_name)) &&
					(Projects::parse_language_clause(proj, mr.exp[1], language_name)));
	} else if (Regexp::match(&mr, what, L"(%c+?) and (%c+)")) {
		verdict = ((Projects::parse_language_clause(proj, mr.exp[0], language_name)) &&
					(Projects::parse_language_clause(proj, mr.exp[1], language_name)));
	} else {
		if (Regexp::match(&mr, what, L" *written *")) @<Set language of syntax@>
		else if (Regexp::match(&mr, what, L" *played *")) @<Set language of play@>
		else if (Regexp::match(&mr, what, L" *indexed *")) @<Set language of index@>
	}
	Regexp::dispose_of(&mr);
	return verdict;
}

@<Set language of play@> =
	proj->name_of_language_of_play = Str::duplicate(language_name);
	Str::trim_white_space(proj->name_of_language_of_play);
	verdict = TRUE;

@<Set language of syntax@> =
	proj->name_of_language_of_syntax = Str::duplicate(language_name);
	Str::trim_white_space(proj->name_of_language_of_syntax);
	verdict = TRUE;

@<Set language of index@> =
	proj->name_of_language_of_index = Str::duplicate(language_name);
	Str::trim_white_space(proj->name_of_language_of_index);
	verdict = TRUE;
