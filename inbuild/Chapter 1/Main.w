[Main::] Main.

A command-line interface for Inbuild functions which are not part of the
normal operation of the Inform compiler.

@h Settings variables.
The following will be set at the command line.

=
pathname *path_to_inbuild = NULL;

int inbuild_task = INSPECT_TTASK;
pathname *path_to_tools = NULL;
int dry_run_mode = FALSE, build_trace_mode = FALSE;
inbuild_nest *destination_nest = NULL;
text_stream *filter_text = NULL;

@h Main routine.
When Inbuild is called at the command line, it begins at |main|, like all C
programs.

Inbuild manages "copies", which are instances of programs or resources found
somewhere in the file system. The copies which it acts on in a given run are
called "targets". The task of |main| is to read the command-line arguments,
set the following variables as needed, and produce a list of targets to work
on; then to carry out that work, and then shut down again.

=
int main(int argc, char **argv) {
    @<Start up the modules@>;
	@<Read the command line@>;
	CommandLine::play_back_log();
	@<Complete the list of targets@>;
	@<Act on the targets@>;
	@<Shut down the modules@>;
	if (Errors::have_occurred()) return 1;
	return 0;
}

@<Start up the modules@> =
	Foundation::start(); /* must be started first */
	WordsModule::start();
	SyntaxModule::start();
	HTMLModule::start();
	ArchModule::start();
	SupervisorModule::start();

@ Targets can arise in three ways:
(1) They can be specified at the command line, either as bare names of files
or paths, or with |-contents-of D| for a directory |D|. By the time the code
in this paragraph runs, those targets are already in the list.
(2) They can be specified by a search request |-matching R| where |R| is a
list of requirements to match. We now add anything found that way. (We didn't
do so when reading the command line because at that time the search path for
nests did not yet exist: it is created when |Supervisor::optioneering_complete|
is called.)
(3) One copy is always special to Inbuild: the "project", usually an Inform
project bundle with a pathname like |Counterfeit Monkey.inform|. We go
through a little dance with |Supervisor::optioneering_complete| to ensure that
if a project is already in the target list, Inbuild will use that; and if not,
but the user has specified a project to Inbuild already with |-project| (a
command-line option recognised by |inbuild| but not by us), then we add that
to the target list. Tne net result is that however the user indicates interest
in an Inform project bundle, it becomes both the Inbuild current project, and
also a member of our target list. It follows that we cannot have two project
bundles in the target list, because they cannot both be the current project;
and to avoid the user being confused when only one is acted on, we throw an
error in this case.

@<Complete the list of targets@> =
	linked_list *L = Main::list_of_targets();
	inbuild_copy *D = NULL, *C;
	LOOP_OVER_LINKED_LIST(C, inbuild_copy, L)
		if ((C->edition->work->genre == project_bundle_genre) ||
			(C->edition->work->genre == project_file_genre))
			D = C;
	Supervisor::optioneering_complete(D, FALSE, &Main::load_preform);
	inform_project *proj;
	LOOP_OVER(proj, inform_project)
		Main::add_target(proj->as_copy);
	int count = 0;
	LOOP_OVER_LINKED_LIST(C, inbuild_copy, L)
		if ((C->edition->work->genre == project_bundle_genre) ||
			(C->edition->work->genre == project_file_genre))
			count++;
	if (count > 1)
		Errors::with_text("can only work on one project bundle at a time", NULL);
	if (Str::len(filter_text) > 0) Main::add_search_results_as_targets(filter_text);

@ We make the function call |Supervisor::go_operational| to signal to |inbuild|
that we want to start work now.

@<Act on the targets@> =
	Supervisor::go_operational();
	int use = SHELL_METHODOLOGY;
	if (dry_run_mode) use = DRY_RUN_METHODOLOGY;
	build_methodology *BM;
	if (path_to_tools) BM = BuildMethodology::new(path_to_tools, FALSE, use);
	else BM = BuildMethodology::new(Pathnames::up(path_to_inbuild), TRUE, use);
	if (build_trace_mode) IncrementalBuild::enable_trace();
	linked_list *L = Main::list_of_targets();
	inbuild_copy *C;
	LOOP_OVER_LINKED_LIST(C, inbuild_copy, L)
		@<Carry out the required task on the copy C@>;

@ The list of possible tasks is as follows; they basically all correspond to
utility functions in the //supervisor// module, which we call.

@e INSPECT_TTASK from 1
@e GRAPH_TTASK
@e USE_NEEDS_TTASK
@e BUILD_NEEDS_TTASK
@e ARCHIVE_TTASK
@e ARCHIVE_TO_TTASK
@e USE_MISSING_TTASK
@e BUILD_MISSING_TTASK
@e BUILD_TTASK
@e REBUILD_TTASK
@e COPY_TO_TTASK
@e SYNC_TO_TTASK

@<Carry out the required task on the copy C@> =
	switch (inbuild_task) {
		case INSPECT_TTASK: Copies::inspect(STDOUT, C); break;
		case GRAPH_TTASK: Copies::show_graph(STDOUT, C); break;
		case USE_NEEDS_TTASK: Copies::show_needs(STDOUT, C, TRUE); break;
		case BUILD_NEEDS_TTASK: Copies::show_needs(STDOUT, C, FALSE); break;
		case ARCHIVE_TTASK: {
			inform_project *proj;
			int c = 0;
			LOOP_OVER(proj, inform_project) {
				c++;
				destination_nest = Projects::materials_nest(proj);
			}
			if (c == 0)
				Errors::with_text("no -project in use, so ignoring -archive", NULL);
			else if (c > 1)
				Errors::with_text("multiple projects in use, so ignoring -archive", NULL);
			else 
				Copies::archive(STDOUT, C, destination_nest, BM);
			break;
		}
		case ARCHIVE_TO_TTASK: Copies::archive(STDOUT, C, destination_nest, BM); break;
		case USE_MISSING_TTASK: Copies::show_missing(STDOUT, C, TRUE); break;
		case BUILD_MISSING_TTASK: Copies::show_missing(STDOUT, C, FALSE); break;
		case BUILD_TTASK: Copies::build(STDOUT, C, BM); break;
		case REBUILD_TTASK: Copies::rebuild(STDOUT, C, BM); break;
		case COPY_TO_TTASK: Copies::copy_to(C, destination_nest, FALSE, BM); break;
		case SYNC_TO_TTASK: Copies::copy_to(C, destination_nest, TRUE, BM); break;
	}

@<Shut down the modules@> =
	ArchModule::end();
	SupervisorModule::end();
	HTMLModule::end();
	SyntaxModule::end();
	WordsModule::end();
	Foundation::end(); /* must be ended last */

@ Preform is the crowning jewel of the |words| module, and parses excerpts of
natural-language text against a "grammar". The |inform7| executable makes very
heavy-duty use of Preform, but we use a much coarser grammar, which simply
breaks down source text into sentences, headings and so on. That grammar is
stored in a file called |Syntax.preform| inside the installation of Inbuild,
which is why we need to have worked out |path_to_inbuild| (the pathname at
which we are installed) already. Once the following is run, Preform is ready
for use.

=
void Main::load_preform(inform_language *L) {
	pathname *P = Pathnames::down(path_to_inbuild, I"Tangled");
	filename *S = Filenames::in(P, I"Syntax.preform");
	wording W = Preform::load_from_file(S);
	Preform::parse_preform(W, FALSE);
}

@h Target list.
This where we keep the list of targets, in which no copy occurs more than
once. The following code runs quadratically in the number of targets, but for
Inbuild this number is never likely to be more than about 100 at a time.

=
linked_list *targets = NULL; /* of |inbuild_copy| */

void Main::add_target(inbuild_copy *to_add) {
	if (targets == NULL) targets = NEW_LINKED_LIST(inbuild_copy);
	int found = FALSE;
	inbuild_copy *C;
	LOOP_OVER_LINKED_LIST(C, inbuild_copy, targets)
		if (C == to_add)
			found = TRUE;
	if (found == FALSE) ADD_TO_LINKED_LIST(to_add, inbuild_copy, targets);
}

linked_list *Main::list_of_targets(void) {
	if (targets == NULL) targets = NEW_LINKED_LIST(inbuild_copy);
	return targets;
}

void Main::add_search_results_as_targets(text_stream *req_text) {	
	TEMPORARY_TEXT(errors);
	inbuild_requirement *req = Requirements::from_text(req_text, errors);
	if (Str::len(errors) > 0) {
		Errors::with_text("requirement malformed: %S", errors);
	} else {
		linked_list *L = NEW_LINKED_LIST(inbuild_search_result);
		Nests::search_for(req, Supervisor::shared_nest_list(), L);
		inbuild_search_result *R;
		LOOP_OVER_LINKED_LIST(R, inbuild_search_result, L)
			Main::add_target(R->copy);
	}
	DISCARD_TEXT(errors);
}

void Main::add_directory_contents_targets(pathname *P) {
	scan_directory *D = Directories::open(P);
	TEMPORARY_TEXT(LEAFNAME);
	while (Directories::next(D, LEAFNAME)) {
		TEMPORARY_TEXT(FILENAME);
		WRITE_TO(FILENAME, "%p%c%S", P, FOLDER_SEPARATOR, LEAFNAME);
		Main::add_file_or_path_as_target(FILENAME, FALSE);
		DISCARD_TEXT(FILENAME);
	}
	DISCARD_TEXT(LEAFNAME);
	Directories::close(D);
}

void Main::add_file_or_path_as_target(text_stream *arg, int throwing_error) {
	TEMPORARY_TEXT(ext);
	int pos = Str::len(arg) - 1, dotpos = -1;
	while (pos >= 0) {
		wchar_t c = Str::get_at(arg, pos);
		if (c == FOLDER_SEPARATOR) break;
		if (c == '.') dotpos = pos;
		pos--;
	}
	if (dotpos >= 0)
		Str::substr(ext, Str::at(arg, dotpos+1), Str::end(arg));
	int directory_status = NOT_APPLICABLE;
	if (Str::get_last_char(arg) == FOLDER_SEPARATOR) {
		Str::delete_last_character(arg);
		directory_status = TRUE;
	}
	inbuild_copy *C = NULL;
	inbuild_genre *G;
	LOOP_OVER(G, inbuild_genre)
		if (C == NULL)
			VMETHOD_CALL(G, GENRE_CLAIM_AS_COPY_MTID, &C, arg, ext, directory_status);
	DISCARD_TEXT(ext);
	if (C == NULL) {
		if (throwing_error) Errors::with_text("unable to identify '%S'", arg);
		return;
	}
	Main::add_target(C);
}

@h Command line.
Note the call below to |Supervisor::declare_options|, which adds a whole lot of
other options to the selection defined here.

@d PROGRAM_NAME "inbuild"

@e BUILD_CLSW
@e REBUILD_CLSW
@e GRAPH_CLSW
@e USE_NEEDS_CLSW
@e BUILD_NEEDS_CLSW
@e USE_MISSING_CLSW
@e BUILD_MISSING_CLSW
@e ARCHIVE_CLSW
@e ARCHIVE_TO_CLSW
@e INSPECT_CLSW
@e DRY_CLSW
@e BUILD_TRACE_CLSW
@e TOOLS_CLSW
@e CONTENTS_OF_CLSW
@e MATCHING_CLSW
@e COPY_TO_CLSW
@e SYNC_TO_CLSW

@<Read the command line@> =	
	CommandLine::declare_heading(
		L"[[Purpose]]\n\n"
		L"usage: inbuild [-TASK] TARGET1 TARGET2 ...\n");
	CommandLine::declare_switch(COPY_TO_CLSW, L"copy-to", 2,
		L"copy target(s) to nest X");
	CommandLine::declare_switch(SYNC_TO_CLSW, L"sync-to", 2,
		L"forcibly copy target(s) to nest X, even if prior version already there");
	CommandLine::declare_switch(BUILD_CLSW, L"build", 1,
		L"incrementally build target(s)");
	CommandLine::declare_switch(REBUILD_CLSW, L"rebuild", 1,
		L"completely rebuild target(s)");
	CommandLine::declare_switch(INSPECT_CLSW, L"inspect", 1,
		L"show target(s) but take no action");
	CommandLine::declare_switch(GRAPH_CLSW, L"graph", 1,
		L"show dependency graph of target(s) but take no action");
	CommandLine::declare_switch(USE_NEEDS_CLSW, L"use-needs", 1,
		L"show all the extensions, kits and so on needed to use");
	CommandLine::declare_switch(BUILD_NEEDS_CLSW, L"build-needs", 1,
		L"show all the extensions, kits and so on needed to build");
	CommandLine::declare_switch(USE_MISSING_CLSW, L"use-missing", 1,
		L"show the extensions, kits and so on which are needed to use but missing");
	CommandLine::declare_switch(BUILD_MISSING_CLSW, L"build-missing", 1,
		L"show the extensions, kits and so on which are needed to build but missing");
	CommandLine::declare_switch(ARCHIVE_CLSW, L"archive", 1,
		L"sync copies of all extensions, kits and so on needed for -project into Materials");
	CommandLine::declare_switch(ARCHIVE_TO_CLSW, L"archive-to", 2,
		L"sync copies of all extensions, kits and so on needed into nest X");
	CommandLine::declare_switch(TOOLS_CLSW, L"tools", 2,
		L"make X the directory of intools executables, and exit developer mode");
	CommandLine::declare_boolean_switch(DRY_CLSW, L"dry", 1,
		L"make this a dry run (print but do not execute shell commands)", FALSE);
	CommandLine::declare_boolean_switch(BUILD_TRACE_CLSW, L"build-trace", 1,
		L"show verbose reasoning during -build", FALSE);
	CommandLine::declare_switch(MATCHING_CLSW, L"matching", 2,
		L"apply to all works in nest(s) matching requirement X");
	CommandLine::declare_switch(CONTENTS_OF_CLSW, L"contents-of", 2,
		L"apply to all targets in the directory X");
	Supervisor::declare_options();

	CommandLine::read(argc, argv, NULL, &Main::option, &Main::bareword);

	if (LinkedLists::len(unsorted_nest_list) == 0)
		Supervisor::add_nest(
			Pathnames::from_text(I"inform7/Internal"), INTERNAL_NEST_TAG);

	path_to_inbuild = Pathnames::installation_path("INBUILD_PATH", I"inbuild");

@ Here we handle those options not handled by the //supervisor// module.

=
void Main::option(int id, int val, text_stream *arg, void *state) {
	switch (id) {
		case BUILD_CLSW: inbuild_task = BUILD_TTASK; break;
		case REBUILD_CLSW: inbuild_task = REBUILD_TTASK; break;
		case INSPECT_CLSW: inbuild_task = INSPECT_TTASK; break;
		case GRAPH_CLSW: inbuild_task = GRAPH_TTASK; break;
		case USE_NEEDS_CLSW: inbuild_task = USE_NEEDS_TTASK; break;
		case BUILD_NEEDS_CLSW: inbuild_task = BUILD_NEEDS_TTASK; break;
		case ARCHIVE_TO_CLSW:
			destination_nest = Nests::new(Pathnames::from_text(arg));
			inbuild_task = ARCHIVE_TO_TTASK;
			break;
		case ARCHIVE_CLSW: inbuild_task = ARCHIVE_TTASK; break;
		case USE_MISSING_CLSW: inbuild_task = USE_MISSING_TTASK; break;
		case BUILD_MISSING_CLSW: inbuild_task = BUILD_MISSING_TTASK; break;
		case TOOLS_CLSW: path_to_tools = Pathnames::from_text(arg); break;
		case MATCHING_CLSW: filter_text = Str::duplicate(arg); break;
		case CONTENTS_OF_CLSW:
			Main::add_directory_contents_targets(Pathnames::from_text(arg)); break;
		case DRY_CLSW: dry_run_mode = val; break;
		case BUILD_TRACE_CLSW: build_trace_mode = val; break;
		case COPY_TO_CLSW: inbuild_task = COPY_TO_TTASK;
			destination_nest = Nests::new(Pathnames::from_text(arg));
			break;
		case SYNC_TO_CLSW: inbuild_task = SYNC_TO_TTASK;
			destination_nest = Nests::new(Pathnames::from_text(arg));
			break;
	}
	Supervisor::option(id, val, arg, state);
}

@ This is called for a command-line argument which doesn't appear as
subordinate to any switch; we take it as the name of a copy.

=
void Main::bareword(int id, text_stream *arg, void *state) {
	Main::add_file_or_path_as_target(arg, TRUE);
}

@h Interface to Words module.
We use the mighty Preform natural-language parser only a little when
Inbuild runs on its own, but it needs to be told what C type to use when
identifying natural languages.

@d PREFORM_LANGUAGE_TYPE struct inform_language

@h Interface to Syntax module.
Again, we make a fairly light use of |syntax| when Inbuild runs alone.

@d PARSE_TREE_METADATA_SETUP SourceText::node_metadata
