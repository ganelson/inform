[Task::] What To Compile.

To receive an instruction to compile something from Inbuild, and then to
sort out the many locations then used in the host filing system.

@h Task data.
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
	
	int next_resource_number;

	MEMORY_MANAGEMENT
} compile_task_data;

@ An early and perhaps arguable design decision for inform7 was that it would
compile just one source text in its lifetime as a process: and because of that,
|Task::carry_out| can only in fact be called once, and Inbuild only does so
once. But the following routine allows in principle for multiple calls,
against the day when we change our minds about all this.

Something we will never do is attempt to make |inform7| thread-safe in the
sense of being able to compile two source texts simultaneously. The global
|inform7_task| is null when nothing is being compiled, or set to the unique
thing which is being compiled when it is.

=
compile_task_data *inform7_task = NULL;

int Task::carry_out(build_step *S) {
	inform_project *project = ProjectBundleManager::from_copy(S->associated_copy);
	if (project == NULL) project = ProjectFileManager::from_copy(S->associated_copy);
	if (project == NULL) internal_error("no project");

	if (inform7_task) internal_error("cannot re-enter with new task");
	inform7_task = CREATE(compile_task_data);
	inform7_task->task = S;
	inform7_task->project = project;
	inform7_task->path = S->associated_copy->location_if_path;
	inform7_task->build = Inbuild::transient();
	if (inform7_task->path)
		inform7_task->build = Pathnames::subfolder(inform7_task->path, I"Build");
	if (Pathnames::create_in_file_system(inform7_task->build) == 0) return FALSE;
	inform7_task->materials = Inbuild::materials();
	Task::set_existing_storyfile(NULL);
	inform7_task->next_resource_number = 3;

	inform_language *E = NaturalLanguages::English();
	Projects::set_language_of_syntax(project, E);
	Projects::set_language_of_index(project, E);
	Projects::set_language_of_play(project, E);

	int rv = Sequence::carry_out(inform7_task);
	inform7_task = NULL;
	return rv;
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

@h Project-related files and file paths.

=
filename *Task::uuid_file(void) {
	if (inform7_task == NULL) internal_error("there is no current task");
	return Filenames::in_folder(inform7_task->path, I"uuid.txt");
}
filename *Task::ifiction_record_file(void) {
	if (inform7_task == NULL) internal_error("there is no current task");
	return Filenames::in_folder(inform7_task->path, I"Metadata.iFiction");
}
filename *Task::manifest_file(void) {
	if (inform7_task == NULL) internal_error("there is no current task");
	return Filenames::in_folder(inform7_task->path, I"manifest.plist");
}
filename *Task::blurb_file(void) {
	if (inform7_task == NULL) internal_error("there is no current task");
	return Filenames::in_folder(inform7_task->path, I"Release.blurb");
}

filename *Task::cblorb_report_file(void) {
	if (inform7_task == NULL) internal_error("there is no current task");
	return Filenames::in_folder(inform7_task->build, I"StatusCblorb.html");
}
filename *Task::parse_tree_file(void) {
	if (inform7_task == NULL) internal_error("there is no current task");
	return Filenames::in_folder(inform7_task->build, I"Parse tree.txt");
}
filename *Task::storyfile_file(void) {
	if (inform7_task == NULL) internal_error("there is no current task");
	build_vertex *V = inform7_task->project->unblorbed_vertex;
	if (V == NULL) internal_error("project graph not ready");
	return V->buildable_if_internal_file;
}

@ Location of index files.
Filenames within the |Index| subfolder. Filenames in |Details| have the form
|N_S| where |N| is the integer supplied and |S| the leafname; for instance,
|21_A.html| provides details page number 21 about actions, derived from the
leafname |A.html|.

=
pathname *Task::index_path(void) {
	if (inform7_task == NULL) internal_error("there is no current task");
	pathname *P = Pathnames::subfolder(inform7_task->build, I"Index");
	if (Pathnames::create_in_file_system(P)) return P;
	return NULL;
}
pathname *Task::index_details_path(void) {
	pathname *P = Pathnames::subfolder(Task::index_path(), I"Details");
	if (Pathnames::create_in_file_system(P)) return P;
	return NULL;
}
filename *Task::xml_headings_file(void) {
	return Filenames::in_folder(Task::index_path(), I"Headings.xml");
}
filename *Task::index_file(text_stream *leafname, int sub) {
	if (sub >= 0) {
		TEMPORARY_TEXT(full_leafname);
		WRITE_TO(full_leafname, "%d_%S", sub, leafname);
		filename *F = Filenames::in_folder(Task::index_details_path(), full_leafname);
		DISCARD_TEXT(full_leafname);
		return F;
	} else {
		return Filenames::in_folder(Task::index_path(), leafname);
	}
}

void Task::set_existing_storyfile(text_stream *name) {
	if (inform7_task == NULL) internal_error("there is no current task");
	if (name == NULL) {
		TEMPORARY_TEXT(leaf);
		WRITE_TO(leaf, "story.%S", TargetVMs::get_unblorbed_extension(Task::vm()));
		inform7_task->existing_storyfile = Filenames::in_folder(inform7_task->materials, leaf);
		DISCARD_TEXT(leaf);
	} else {
		inform7_task->existing_storyfile = Filenames::in_folder(inform7_task->materials, name);
	}
}
filename *Task::existing_storyfile_file(void) {
	if (inform7_task == NULL) internal_error("there is no current task");
	return inform7_task->existing_storyfile;
}
filename *Task::large_cover_art_file(int JPEG) {
	if (inform7_task == NULL) internal_error("there is no current task");
	if (JPEG) return Filenames::in_folder(inform7_task->materials, I"Cover.jpg");
	return Filenames::in_folder(inform7_task->materials, I"Cover.png");
}
filename *Task::epsmap_file(void) {
	if (inform7_task == NULL) internal_error("there is no current task");
	return Filenames::in_folder(inform7_task->materials, I"Inform Map.eps");
}

pathname *Task::figures_path(void) {
	if (inform7_task == NULL) internal_error("there is no current task");
	return Pathnames::subfolder(inform7_task->materials, I"Figures");
}
pathname *Task::sounds_path(void) {
	if (inform7_task == NULL) internal_error("there is no current task");
	return Pathnames::subfolder(inform7_task->materials, I"Sounds");
}

pathname *Task::release_path(void) {
	if (inform7_task == NULL) internal_error("there is no current task");
	return Pathnames::subfolder(inform7_task->materials, I"Release");
}
pathname *Task::released_figures_path(void) {
	return Pathnames::subfolder(Task::release_path(), I"Figures");
}
pathname *Task::released_sounds_path(void) {
	return Pathnames::subfolder(Task::release_path(), I"Sounds");
}
pathname *Task::released_interpreter_path(void) {
	return Pathnames::subfolder(Task::release_path(), I"interpreter");
}

@h Establishing the defaults.
Inform's file access happens inside four different areas: the internal
resources area, usually inside the Inform application; the external resources
area, which is where the user (or the application acting on the user's behalf)
installs extensions; the project bundle, say |Example.inform|; and, alongside
that, the materials folder, |Example.materials|.

=
int Task::set_more_defaults(void) {
	@<Internal resources@>;
	@<External resources@>;
	@<Project resources@>;
	@<Materials resources@>;
	return TRUE;
}

@h Internal resources.
Inform needs a whole pile of files to have been installed on the host computer
before it can run: everything from the Standard Rules to a PDF file explaining
what interactive fiction is. They're never written to, only read. They are
referred to as "internal" or "built-in", and they occupy a folder called the
"internal resources" folder.

Unfortunately we don't know where it is. Typically this compiler will be an
executable sitting somewhere inside a user interface application, and the
internal resources folder will be somewhere else inside it. But we don't
know how to find that folder, and we don't want to make any assumptions.
Inform therefore requires on every run that it be told via the |-internal|
switch where the internal resources folder is.

@<Internal resources@> =

	@<Miscellaneous other stuff@>;

@ Most of these files are to help Inblorb to perform a release. The
documentation models are used when making extension documentation; the
leafname is platform-dependent so that Windows can use different models
from everybody else.

The documentation snippets file is generated by |indoc| and contains
brief specifications of phrases, extracted from the manual "Writing with
Inform". This is used to generate the Phrasebook index.

@<Miscellaneous other stuff@> =
	;

@h External resources.
This is where the user can install downloaded extensions, new interpreters,
website templates and so on; so-called "permanent" external resources, since
the user expects them to stay put once installed. But there is also a
"transient" external resources area, for more ephemeral content, such as
the mechanically generated extension documentation. On most platforms the
permanent and transient external areas will be the same, but some mobile
operating systems are aggressive about wanting to delete ephemeral files
used by applications.

The locations of the permanent and transient external folders can be set
using |-external| and |-transient| respectively. If no |-external| is
specified, the location depends on the platform settings: for example on
Mac OS X it will typically be

	|/Library/Users/hclinton/Library/Inform|

If |-transient| is not specified, it's the same folder, i.e., Inform does
not distinguish between permanent and transient external resources.

@<External resources@> =
	@<Transient telemetry@>;

@ Telemetry is not as sinister as it sounds: the app isn't sending data out
on the Internet, only (if requested) logging what it's doing to a local file.
This was provided for classroom use, so that teachers can see what their
students have been getting stuck on.

@<Transient telemetry@> =
	;

@h Project resources.
Although on some platforms it may look like a single file, an Inform project
is a folder whose name has the dot-extension |.inform|. We'll call this the
"project folder", and it contains a whole bundle of useful files.

The UUID file records an ISBN-like identifying number for the project. This
is read-only for us.

The iFiction record, manifest and blurb file are all files that we generate
to give instructions to the releasing agent Inblorb. This means that they
have no purpose unless Inform is in a release run (with |-release| set on
the command line), but they take no time to generate so we make them anyway.

@<Project resources@> =
	@<The Build folder within the project@>;
	@<The Index folder within the project@>;


@ The build folder for a project contains all of the working files created
during the compilation process. The opening part here may be a surprise:
In extension census mode, Inform is running not to compile something but to
extract details of all the extensions installed. But it still needs somewhere
to write its temporary and debugging files, and there is no project bundle
to write into. To get round this, we use the transient data area as if it
were indeed a project bundle.

Briefly: we aim to compile the source text to an Inform 6 program; we issue
an HTML report on our success or failure, listing problem messages if they
occurred; we track our progress in the debugging log. We don't produce the
story file ourselves, I6 will do that, but we do need to know what it's
called; and similarly for the report which the releasing tool Inblorb
will produce if this is a Release run.

@<The Build folder within the project@> =
	;

@ We're going to write into the Index folder, so we must ensure it exists.
The main index files (|Phrasebook.html| and so on) live at the top level,
details on actions live in the subfolder |Details|: see below.

An oddity in the Index folder is an XML file recording where the headings
are in the source text: this is for the benefit of the user interface
application, if it wants it, but is not linked to or used by the HTML of
the index as seen by the user.

@<The Index folder within the project@> =
	;

@h Materials resources.

@<Materials resources@> =
	@<Figures and sounds@>;
	@<The Release folder@>;
	@<Existing story file@>;

@ This is where cover art lives: it could have either the file extension |.jpg|
or |.png|, and we generate both sets of filenames, even though at most one will
actually work. This is also where we generate the EPS file of the map, if
so requested; a bit anomalously, it's the only file in Materials but outside
Release which we write to.

This is also where the originals (not the released copies) of the Figures
and Sounds, if any, live: in their own subfolders.

@<Figures and sounds@> =
	;

@ On a release run, Inblorb will populate the Release subfolder of Materials;
figures and sounds will be copied into the relevant subfolders. The principle
is that everything in Release can always be thrown away without loss, because
it can all be generated again.

@<The Release folder@> =
	;

@ Inform is occasionally run in a mode where it performs a release on an
existing story file (for example a 1980s Infocom one) rather than on one
that it has newly generated. This is the filename such a story file would
have by default, if so.

@<Existing story file@> =
	;
