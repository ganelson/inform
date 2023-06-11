[Task::] What To Compile.

To receive an instruction to compile something from Inbuild, and then to
sort out the many locations then used in the host filing system.

@h Timers.
We keep track of about how long the compiler spends on each task, for the
sake of better diagnostics.

=
stopwatch_timer *inform7_timer = NULL, *supervisor_timer = NULL;

void Task::start_timers(void) {
	inform7_timer = Time::start_stopwatch(NULL, I"inform7 run");
	supervisor_timer = Time::start_stopwatch(inform7_timer, I"supervisor");
}
void Task::stop_timers(void) {
	Time::stop_stopwatch(inform7_timer);
}
void Task::log_stopwatch(void) {
	Time::log_timing(inform7_timer, inform7_timer->time_taken);
}

@h The task.
When Inbuild (a copy of which is included in the Inform 7 executable) decides
that an Inform source text must be compiled, it calls |Task::carry_out|. By
this point Inbuild will have set up an |inform_project| structure to
represent the program we have to compile; but we will need additional data
about that compilation, and it's stored in the following.

=
typedef struct compile_task_data {
	struct build_step *task;
	struct inform_project *project;
	
	struct pathname *path;
	struct pathname *materials;
	struct pathname *build;
	struct filename *existing_storyfile;
	
	int stage_of_compilation;
	int next_resource_number;

	CLASS_DEFINITION
} compile_task_data;

@ An early and perhaps arguable design decision for inform7 was that it would
compile just one source text in its lifetime as a process: and because of that,
|Task::carry_out| can only in fact be called once, and Inbuild only does so
once. But the following function allows in principle for multiple calls,
against the day when we change our minds about all this.

Something we will never do is attempt to make |inform7| thread-safe in the
sense of being able to compile two source texts simultaneously. The global
|inform7_task| is null when nothing is being compiled, or set to the unique
thing which is being compiled when it is.

=
compile_task_data *inform7_task = NULL;
parse_node_tree *latest_syntax_tree = NULL;

int Task::carry_out(build_step *S) {
	int project_bundle_exists = TRUE;
	Time::stop_stopwatch(supervisor_timer);
	inform_project *project = ProjectBundleManager::from_copy(S->associated_copy);
	if (project == NULL) {
		project = ProjectFileManager::from_copy(S->associated_copy);
		project_bundle_exists = FALSE;
	}
	if (project == NULL) internal_error("no project");
	latest_syntax_tree = project->syntax_tree;

	DocReferences::read_xrefs();
	Task::issue_problems_arising(project->as_copy->vertex);
	Features::allow_activation_functions();
	Features::run_activation_functions();

	if (problem_count > 0) return FALSE;

	if (inform7_task) internal_error("cannot re-enter with new task");
	inform7_task = CREATE(compile_task_data);
	inform7_task->task = S;
	inform7_task->project = project;
	inform7_task->path = S->associated_copy->location_if_path;
	inform7_task->build = Projects::build_path(project);
	if (inform7_task->build) {
		if (Pathnames::create_in_file_system(inform7_task->build) == 0) return FALSE;
	}
	inform7_task->materials = Projects::materials_path(project);
	inform7_task->existing_storyfile = NULL;
	inform7_task->stage_of_compilation = -1;
	inform7_task->next_resource_number = 3;
	
	DefaultLanguage::set(Projects::get_language_of_syntax(project));
	if (project_bundle_exists) Gitignoring::automatic(project);

	int rv = Sequence::carry_out(TargetVMs::debug_enabled(inform7_task->task->for_vm));
	return rv;
}

@ All manner of low-level problems emerge when reading in the text of the
project, or any extensions it uses: these have already been found by inbuild
and are attached to the relevant nodes in the build graph. We issue them
here as Inform problem messages. (Inbuild wasn't able to do that for us
because the Inform problems file wasn't open back then; and besides, it can
only issue stubby Unix-like command line errors.)

=
void Task::issue_problems_arising(build_vertex *V) {
	if (V->type == COPY_VERTEX)
		SourceProblems::issue_problems_arising(V->as_copy);
	build_vertex *W;
	LOOP_OVER_LINKED_LIST(W, build_vertex, V->build_edges)
		Task::issue_problems_arising(W);
	LOOP_OVER_LINKED_LIST(W, build_vertex, V->use_edges)
		Task::issue_problems_arising(W);
}

@ We will keep track of how far along the process has advanced, in very
rough stages. Twenty is plenty.

=
void Task::advance_stage_to(int stage, text_stream *name, int X, int debugging,
	stopwatch_timer *timer) {
	if (inform7_task == NULL) internal_error("there is no current task");
	if (stage <= inform7_task->stage_of_compilation) internal_error("not an advance");
	if (stage >= 20) internal_error("went too far");
	if ((inform7_task->stage_of_compilation >= 0) && (problem_count == 0))
		PluginCalls::production_line(inform7_task->stage_of_compilation, debugging, timer);
	char *roman[] = {
		"I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X",
		"XI", "XII", "XIII", "XIV", "XV", "XVI", "XVII", "XVIII", "XIX", "XX" };
	if (problem_count == 0) {
		Log::new_phase(roman[stage], name);
		if (X >= 0) ProgressBar::update(X, 0);
	}
	inform7_task->stage_of_compilation = stage;
}
int Task::is_before_stage(int stage) {
	if (inform7_task == NULL) internal_error("there is no current task");
	if (inform7_task->stage_of_compilation < stage) return TRUE;
	return FALSE;
}
int Task::is_during_stage(int stage) {
	if (inform7_task == NULL) internal_error("there is no current task");
	if (inform7_task->stage_of_compilation == stage) return TRUE;
	return FALSE;
}
int Task::is_after_stage(int stage) {
	if (inform7_task == NULL) internal_error("there is no current task");
	if (inform7_task->stage_of_compilation > stage) return TRUE;
	return FALSE;
}

@ The current project and the virtual machine we want to compile it for:

=
inform_project *Task::project(void) {
	if (inform7_task == NULL) internal_error("there is no current task");
	return inform7_task->project;
}

target_vm *Task::vm(void) {
	if (inform7_task == NULL) internal_error("there is no current task");
	return inform7_task->task->for_vm;
}

int Task::veto_number(int X) {
	if (((X > 32767) || (X < -32768)) &&
		(TargetVMs::is_16_bit(Task::vm()))) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_LiteralOverflow),
			"you use a number which is too large",
			"at least with the Settings for this project as they currently "
			"are. (Change to Glulx to be allowed to use much larger numbers.)");
		return TRUE;
	}
	return FALSE;
}

inbuild_edition *Task::edition(void) {
	if (inform7_task == NULL) internal_error("there is no current task");
	return inform7_task->project->as_copy->edition;
}

parse_node_tree *Task::syntax_tree(void) {
	return latest_syntax_tree;
}

inform_language *Task::language_of_syntax(void) {
	return Projects::get_language_of_syntax(Task::project());
}

void Task::add_kind_inventions(void) {
	StarTemplates::transcribe_all(Task::syntax_tree());
}

void Task::verify(void) {
	VerifyTree::verify_integrity(Task::syntax_tree());
	VerifyTree::verify_structure(Task::syntax_tree());
}

@ This is part of a scheme to wean authors off of use of an external extensions
area.

=
void Task::warn_about_deprecated_nests(void) {
	inform_project *project = Task::project();
	inform_extension *ext;
	LOOP_OVER_LINKED_LIST(ext, inform_extension, project->extensions_included) {
		inbuild_nest *N = Copies::origin(ext->as_copy);
		if (Nests::is_deprecated(N)) {
			TEMPORARY_TEXT(ename)
			Copies::write_copy(ename, ext->as_copy);
			Problems::quote_stream(1, ename);
			StandardProblems::handmade_warning(Task::syntax_tree(), _p_(Untestable));
			Problems::issue_warning_segment(
				"The extension '%1' was included from an external location, that is, "
				"from outside of this project's materials folder. That's allowed, and "
				"is how most authors managed things until 2023, but we now recommend "
				"moving all extensions needed for a project (other than those built "
				"into Inform itself) into the project's materials folder. "
				"If you do, this warning will go away.");
			Problems::issue_warning_end();
		}
	}
}

@ Resources in a Blorb file have unique ID numbers which are positive integers,
but these are not required to start from 1, nor to be contiguous. For Inform,
ID number 1 is reserved for the cover image (whether or not any cover image
is provided: it is legal for there to be figures but no cover, and vice versa).
Other figures, and sound effects, then mix freely as needed from ID number 3
on upwards. We skip 2 so that it can be guaranteed that no sound resource
has ID 1 or 2: this is to help people trying to play sounds in the Z-machine,
where operand 1 or 2 in the |@sound| opcode signifies not a sound resource
number but a long or short beep. If a genuine sound effect had resource ID
1 or 2, therefore, it would be unplayable on the Z-machine.

=
int Task::get_next_free_blorb_resource_ID(void) {
	if (inform7_task == NULL) internal_error("there is no current task");
	return inform7_task->next_resource_number++;
}

@ This seed is ordinarily 0, causing no fix to occur, but can be set to
a non-zero value to make testing Inform easier.

=
int Task::rng_seed(void) {
	if (inform7_task == NULL) internal_error("there is no current task");
	return inform7_task->project->fix_rng;
}

@ These functions are for steps on the production line which involve
referring something back up to Inbuild.

=
void Task::make_built_in_kind_constructors(void) {
	if (inform7_task == NULL) internal_error("there is no current task");
	Projects::load_built_in_kind_constructors(inform7_task->project);
}

int Task::begin_execution_at_to_begin(void) {
	if (inform7_task == NULL) internal_error("there is no current task");
	if (Projects::Main_defined(inform7_task->project)) return FALSE;
	return TRUE;
}

@h Project-related files and file paths.
An Inform compilation can touch dozens of different files, and the rest
of this section is a tour through the ones which are associated with the
project itself. (Common resources, used for all compilations, or optional
add-ins such as extensions are the business of Inbuild.)

If a project is called, say, Wuthering Heights, and is a "bundle" as created
and compiled by the Inform app, then:

(a) The project path will be |Wuthering Heights.inform|. This looks opaque
on MacOS, as if a file, but on all platforms it is in fact a directory.
(b) Within it is |Wuthering Heights.inform/Build|, the "build folder".
(c) Alongside it is |Wuthering Heights.materials|. This is also a directory,
but is openly accessible even on MacOS.

If Inform is working on a single source text file, not a bundle, then the
project will be the current working directory, but now the build folder will
be the Inbuild transient area, and materials (if present) will again be
alongside.

To begin: what's in the project area? |story.ni| and |auto.inf|, neither
one very helpfully named, are defined in Inbuild rather than here: these
are the I7 source text and its compilation down to I6, respectively.
In addition we have:

The UUID file records an ISBN-like identifying number for the project. This
is read-only for us.

The iFiction record, manifest and blurb file are all files that we generate
to give instructions to the releasing agent Inblorb. This means that they
have no purpose unless Inform is in a release run (with |-release| set on
the command line), but they take no time to generate so we make them anyway.

=
filename *Task::uuid_file(void) {
	if (inform7_task == NULL) internal_error("there is no current task");
	return Filenames::in(inform7_task->path, I"uuid.txt");
}
filename *Task::ifiction_record_file(void) {
	if (inform7_task == NULL) internal_error("there is no current task");
	return Filenames::in(inform7_task->path, I"Metadata.iFiction");
}
filename *Task::manifest_file(void) {
	if (inform7_task == NULL) internal_error("there is no current task");
	return Filenames::in(inform7_task->path, I"manifest.plist");
}
filename *Task::blurb_file(void) {
	if (inform7_task == NULL) internal_error("there is no current task");
	return Filenames::in(inform7_task->path, I"Release.blurb");
}

@ The build folder for a project contains all of the working files created
during the compilation process. The debugging log and Inform problems report
(its HTML file of error messages) are both written there: see the Main Routine
section for details. In addition we have:

=
filename *Task::cblorb_report_file(void) {
	if (inform7_task == NULL) internal_error("there is no current task");
	return Filenames::in(inform7_task->build, I"StatusCblorb.html");
}
filename *Task::parse_tree_file(void) {
	if (inform7_task == NULL) internal_error("there is no current task");
	return Filenames::in(inform7_task->build, I"Parse tree.txt");
}

@ The name of the unblorbed story file is chosen for us by Inbuild, so
we have to extract it from the build graph.

Note that this will return |NULL| if the current run of Inform is to
produce, say, a C program rather than a Glulx or Z-machine story file.

=
filename *Task::storyfile_file(void) {
	if (inform7_task == NULL) internal_error("there is no current task");
	build_vertex *V = inform7_task->project->unblorbed_vertex;
	if (V == NULL) return NULL;
	return V->as_file;
}

@ Deeper inside the|Build| subfolder is an (also ephemeral) |Index| subfolder,
which holds the mini-website of the Index for a project.

The main index files (|Phrasebook.html| and so on) live at the top level,
details on actions live in the subfolder |Details|: see below.

@d PATH_INDEX_CALLBACK Task::index_path

=
pathname *Task::index_path(void) {
	if (inform7_task == NULL) internal_error("there is no current task");
	pathname *P = Pathnames::down(inform7_task->path, I"Index");
	if (Pathnames::create_in_file_system(P)) return P;
	return NULL;
}

@ The XML file of headings is written by the supervisor, but only if we ask
it to, and this is where:

=
void Task::write_XML_headings_file(void) {
	if (inform7_task == NULL) internal_error("there is no current task");
	if (inform7_task->project->stand_alone == FALSE)
		Headings::write_as_XML(Task::syntax_tree(), IndexLocations::xml_headings_filename());
}

@ That's it for the project folder, but other project-related stuff is in
the materials folder, which we turn to next.

Inform is occasionally run in a mode where it performs a release on an
existing story file (for example a 1980s Infocom one) rather than on one
that it has newly generated. This is the filename such a story file would
have by default, if so.

By default the story file will be called something like |story.z8|, but
its leafname is actually declared from the source text of the Inform
project created to do this wrapping-up. So we need a way to set as well
as read this filename. Whatever the leafname, though, it lives in the top
level of materials.

=
int Task::wraps_existing_storyfile(void) {
	if (inform7_task == NULL) internal_error("there is no current task");
	return (inform7_task->existing_storyfile != NULL)?TRUE:FALSE;
}
void Task::set_existing_storyfile(text_stream *name) {
	if (inform7_task == NULL) internal_error("there is no current task");
	if (name == NULL) {
		TEMPORARY_TEXT(leaf)
		WRITE_TO(leaf, "story.%S", TargetVMs::get_unblorbed_extension(Task::vm()));
		inform7_task->existing_storyfile = Filenames::in(inform7_task->materials, leaf);
		DISCARD_TEXT(leaf)
	} else {
		inform7_task->existing_storyfile = Filenames::in(inform7_task->materials, name);
	}
}
filename *Task::existing_storyfile_file(void) {
	if (inform7_task == NULL) internal_error("there is no current task");
	return inform7_task->existing_storyfile;
}

@ Materials is also where cover art lives: it could have either the file
extension |.jpg| or |.png|, and we generate both sets of filenames, even
though at most one will actually work. This is also where we generate the EPS
file of the map, if so requested; a bit anomalously, it's the only file in
Materials but outside Release which we write to.

=
filename *Task::large_cover_art_file(int JPEG) {
	if (inform7_task == NULL) internal_error("there is no current task");
	if (JPEG) return Filenames::in(inform7_task->materials, I"Cover.jpg");
	return Filenames::in(inform7_task->materials, I"Cover.png");
}
filename *Task::epsmap_file(void) {
	if (inform7_task == NULL) internal_error("there is no current task");
	return Filenames::in(inform7_task->materials, I"Inform Map.eps");
}

@ This is also where the originals (not the released copies) of the Figures
and Sounds, if any, live: in their own subfolders, or "departments".

=
pathname *Task::resources_path(void) {
	if (inform7_task == NULL) internal_error("there is no current task");
	return inform7_task->materials;
}

text_stream *Task::figures_department(void) {
	return I"Figures";
}
text_stream *Task::sounds_department(void) {
	return I"Sounds";
}
text_stream *Task::data_department(void) {
	return I"Data";
}

@ On a release run, Inblorb will populate the Release subfolder of Materials;
figures and sounds will be copied into the relevant subfolders. The principle
is that everything in Release can always be thrown away without loss, because
it can all be generated again.

=
pathname *Task::release_path(void) {
	if (inform7_task == NULL) internal_error("there is no current task");
	return Pathnames::down(inform7_task->materials, I"Release");
}
pathname *Task::released_figures_path(void) {
	return Pathnames::down(Task::release_path(), I"Figures");
}
pathname *Task::released_sounds_path(void) {
	return Pathnames::down(Task::release_path(), I"Sounds");
}
pathname *Task::released_interpreter_path(void) {
	return Pathnames::down(Task::release_path(), I"interpreter");
}

@ EPS-format files are vector art, rather than raster art, and are produced
with the intention that authors can tidy them up afterwards using programs
like Adobe Illustrator. By default they aren't produced, so that the following
flag stays |FALSE|:

=
int write_EPS_format_map = FALSE;

int do_not_generate_index = FALSE; /* Set by the |-no-index| command line option */
void Task::disable_or_enable_index(int which) {
	do_not_generate_index = which;
}
int do_not_generate_problems = FALSE; /* Set by the |-no-problems| command line option */
void Task::disable_or_enable_problems(int which) {
	do_not_generate_problems = which;
}
int do_not_update_census = FALSE; /* Set by the |-no-update-census| command line option */
void Task::disable_or_enable_census(int which) {
	do_not_update_census = which;
}

int Task::problems_enabled(void) {
	return do_not_generate_problems?FALSE:TRUE;
}

@ And so, finally, the following triggers the indexing process.

=
int inform7_index_requirements = 0;
void Task::specify_index_requirements(void) {
	inform7_index_requirements = 0;
	if (do_not_generate_index == FALSE)
		inform7_index_requirements |= INDEX_REQUIRED_BIT;
	if (do_not_update_census == FALSE)
		inform7_index_requirements |= CENSUS_UPDATE_REQUIRED_BIT;
	if (write_EPS_format_map)
		inform7_index_requirements |= EPS_MAP_REQUIRED_BIT;
}

int Task::get_index_requirements(void) {
	return inform7_index_requirements;
}
