[Main::] Main.

A command-line interface for Inbuild functions which are not part of the
normal operation of the Inform compiler.

@h Settings variables.
The following will be set at the command line.

=
pathname *path_to_inbuild = NULL;

int inbuild_task = INSPECT_TTASK;
pathname *path_to_tools = NULL;
int dry_run_mode = FALSE, build_trace_mode = FALSE, confirmed = FALSE;
int contents_of_used = FALSE, recursive = FALSE;
inbuild_nest *destination_nest = NULL;
inbuild_registry *selected_registry = NULL;
text_stream *filter_text = NULL;
pathname *preprocess_HTML_destination = NULL;
text_stream *preprocess_HTML_app = NULL;
inbuild_copy *to_install = NULL;

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
	if (to_install) @<Perform an extension installation@>
	else @<Act on the targets@>;
	@<Shut down the modules@>;
	if (Errors::have_occurred()) return 1;
	return 0;
}

@<Start up the modules@> =
	Foundation::start(argc, argv); /* must be started first */
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
command-line option recognised by |inform7| but not by us), then we add that
to the target list. Tne net result is that however the user indicates interest
in an Inform project bundle, it becomes both the Inbuild current project, and
also a member of our target list. It follows that we cannot have two project
bundles in the target list, because they cannot both be the current project;
and to avoid the user being confused when only one is acted on, we throw an
error in this case.

@<Complete the list of targets@> =
	linked_list *L = Main::list_of_targets();
	inbuild_copy *D = NULL, *C; int others_exist = FALSE;
	LOOP_OVER_LINKED_LIST(C, inbuild_copy, L)
		if ((C->edition->work->genre == project_bundle_genre) ||
			(C->edition->work->genre == project_file_genre))
			D = C;
		else
			others_exist = TRUE;
	if ((others_exist == FALSE) && (D)) {
		if (D->location_if_path) Supervisor::set_I7_bundle(D->location_if_path);
		if (D->location_if_file) Supervisor::set_I7_source(D->location_if_file);
	}
	if ((LinkedLists::len(unsorted_nest_list) == 0) ||
		((others_exist == FALSE) && (D))) {
		SVEXPLAIN(1, "(in absence of explicit -internal, inventing -internal %p)\n",
			Supervisor::default_internal_path());
		if (path_to_tools) SVEXPLAIN(2, "(note that -tools is %p)\n", path_to_tools);
		Supervisor::add_nest(
			Supervisor::default_internal_path(), INTERNAL_NEST_TAG);
	}
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

@<Perform an extension installation@> =
	Supervisor::go_operational();
	InbuildReport::install(to_install, confirmed, path_to_inbuild);

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
@e USE_LOCATE_TTASK
@e BUILD_LOCATE_TTASK
@e ARCHIVE_TTASK
@e ARCHIVE_TO_TTASK
@e USE_MISSING_TTASK
@e BUILD_MISSING_TTASK
@e BUILD_TTASK
@e REBUILD_TTASK
@e COPY_TO_TTASK
@e SYNC_TO_TTASK

@<Carry out the required task on the copy C@> =
	text_stream *OUT = STDOUT;
	switch (inbuild_task) {
		case INSPECT_TTASK: Copies::inspect(OUT, C); break;
		case GRAPH_TTASK: Copies::show_graph(OUT, C); break;
		case USE_NEEDS_TTASK: Copies::show_needs(OUT, C, TRUE, FALSE); break;
		case BUILD_NEEDS_TTASK: Copies::show_needs(OUT, C, FALSE, FALSE); break;
		case USE_LOCATE_TTASK: Copies::show_needs(OUT, C, TRUE, TRUE); break;
		case BUILD_LOCATE_TTASK: Copies::show_needs(OUT, C, FALSE, TRUE); break;
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
				Copies::archive(OUT, C, destination_nest, BM);
			break;
		}
		case ARCHIVE_TO_TTASK: Copies::archive(OUT, C, destination_nest, BM); break;
		case USE_MISSING_TTASK: Copies::show_missing(OUT, C, TRUE); break;
		case BUILD_MISSING_TTASK: Copies::show_missing(OUT, C, FALSE); break;
		case BUILD_TTASK: Copies::build(OUT, C, BM); break;
		case REBUILD_TTASK: Copies::rebuild(OUT, C, BM); break;
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
heavy-duty use of Preform, and we can use that too provided we have access to
the English Preform syntax file stored inside the core Inform distribution,
that is, in the |-internal| area.

But suppose we can't get that? Well, then we fall back on a much coarser
grammar, which simply breaks down source text into sentences, headings and so
on. That grammar is stored in a file called |Syntax.preform| inside the
installation of Inbuild, which is why we need to have worked out
|path_to_inbuild| (the pathname at which we are installed) already. Once the
following is run, Preform is ready for use.

=
int Main::load_preform(inform_language *L) {
	if (Supervisor::dash_internal_was_used()) {
		filename *F = Filenames::in(Languages::path_to_bundle(L), I"Syntax.preform");
		return LoadPreform::load(F, L);
	} else {
		pathname *P = Pathnames::down(path_to_inbuild, I"Tangled");
		filename *S = Filenames::in(P, I"Syntax.preform");
		return LoadPreform::load(S, NULL);
	}
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

@ The following sorts the list of targets before returning it. This is partly
to improve the quality of the output of |-inspect|, but also to make the
behaviour of //inbuild// more predictable across platforms -- the raw target
list tends to be in order of discovery of the copies, which in turn depends on
the order in which filenames are read from a directory listing.

=
linked_list *Main::list_of_targets(void) {
	if (targets == NULL) targets = NEW_LINKED_LIST(inbuild_copy);
	int no_entries = LinkedLists::len(targets);
	if (no_entries == 0) return targets;
	inbuild_copy **sorted_targets =
		Memory::calloc(no_entries, sizeof(inbuild_copy *), EXTENSION_DICTIONARY_MREASON);
	int i=0;
	inbuild_copy *C;
	LOOP_OVER_LINKED_LIST(C, inbuild_copy, targets) sorted_targets[i++] = C;
	qsort(sorted_targets, (size_t) no_entries, sizeof(inbuild_copy *), Copies::cmp);
	linked_list *result = NEW_LINKED_LIST(inbuild_copy);
	for (int i=0; i<no_entries; i++)
		ADD_TO_LINKED_LIST(sorted_targets[i], inbuild_copy, result);
	Memory::I7_array_free(sorted_targets, EXTENSION_DICTIONARY_MREASON,
		no_entries, sizeof(inbuild_copy *));
	return result;
}

void Main::add_search_results_as_targets(text_stream *req_text) {	
	TEMPORARY_TEXT(errors)
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
	DISCARD_TEXT(errors)
}

void Main::add_directory_contents_targets(pathname *P) {
	linked_list *L = Directories::listing(P);
	text_stream *entry;
	LOOP_OVER_LINKED_LIST(entry, text_stream, L) {
		TEMPORARY_TEXT(FILENAME)
		WRITE_TO(FILENAME, "%p%c%S", P, FOLDER_SEPARATOR, entry);
		Main::add_file_or_path_as_target(FILENAME, FALSE);
		DISCARD_TEXT(FILENAME)
	}
}

inbuild_copy *Main::file_or_path_to_copy(text_stream *arg, int throwing_error) {
	TEMPORARY_TEXT(ext)
	int pos = Str::len(arg) - 1, dotpos = -1;
	while (pos >= 0) {
		wchar_t c = Str::get_at(arg, pos);
		if (Platform::is_folder_separator(c)) break;
		if (c == '.') dotpos = pos;
		pos--;
	}
	if (dotpos >= 0)
		Str::substr(ext, Str::at(arg, dotpos+1), Str::end(arg));
	int directory_status = NOT_APPLICABLE;
	if (Platform::is_folder_separator(Str::get_last_char(arg))) {
		Str::delete_last_character(arg);
		directory_status = TRUE;
	}
	inbuild_copy *C = NULL;
	inbuild_genre *G;
	LOOP_OVER(G, inbuild_genre)
		if (C == NULL)
			VOID_METHOD_CALL(G, GENRE_CLAIM_AS_COPY_MTID, &C, arg, ext, directory_status);
	DISCARD_TEXT(ext)
	if (C == NULL) {
		if (throwing_error) Errors::with_text("unable to identify '%S'", arg);
		return NULL;
	}
	return C;
}

void Main::add_file_or_path_as_target(text_stream *arg, int throwing_error) {
	int is_folder = Platform::is_folder_separator(Str::get_last_char(arg));
	inbuild_copy *C = Main::file_or_path_to_copy(arg, throwing_error);
	if (C) {
		Main::add_target(C);
	} else if ((recursive) && (is_folder)) {
		pathname *P = Pathnames::from_text(arg);
		linked_list *L = Directories::listing(P);
		text_stream *entry;
		LOOP_OVER_LINKED_LIST(entry, text_stream, L) {
			TEMPORARY_TEXT(FILENAME)
			WRITE_TO(FILENAME, "%p%c%S", P, FOLDER_SEPARATOR, entry);
			Main::add_file_or_path_as_target(FILENAME, throwing_error);
			DISCARD_TEXT(FILENAME)
		}
	}
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
@e USE_LOCATE_CLSW
@e BUILD_LOCATE_CLSW
@e USE_MISSING_CLSW
@e BUILD_MISSING_CLSW
@e ARCHIVE_CLSW
@e ARCHIVE_TO_CLSW
@e INSPECT_CLSW
@e DRY_CLSW
@e BUILD_TRACE_CLSW
@e TOOLS_CLSW
@e CONTENTS_OF_CLSW
@e RECURSIVE_CLSW
@e MATCHING_CLSW
@e COPY_TO_CLSW
@e SYNC_TO_CLSW
@e VERSIONS_IN_FILENAMES_CLSW
@e VERIFY_REGISTRY_CLSW
@e BUILD_REGISTRY_CLSW
@e PREPROCESS_HTML_CLSW
@e PREPROCESS_HTML_TO_CLSW
@e PREPROCESS_APP_CLSW
@e REPAIR_CLSW
@e RESULTS_CLSW
@e INSTALL_CLSW
@e CONFIRMED_CLSW
@e VERBOSE_CLSW
@e VERBOSITY_CLSW

@<Read the command line@> =	
	CommandLine::declare_heading(
		L"[[Purpose]]\n\n"
		L"usage: inbuild [-TASK] TARGET1 TARGET2 ...\n");
	CommandLine::declare_switch(COPY_TO_CLSW, L"copy-to", 2,
		L"copy target(s) to nest X");
	CommandLine::declare_switch(SYNC_TO_CLSW, L"sync-to", 2,
		L"forcibly copy target(s) to nest X, even if prior version already there");
	CommandLine::declare_boolean_switch(VERSIONS_IN_FILENAMES_CLSW, L"versions-in-filenames", 1,
		L"append _v number to destination filenames on -copy-to or -sync-to", TRUE);
	CommandLine::declare_switch(BUILD_CLSW, L"build", 1,
		L"incrementally build target(s)");
	CommandLine::declare_switch(REBUILD_CLSW, L"rebuild", 1,
		L"completely rebuild target(s)");
	CommandLine::declare_switch(INSPECT_CLSW, L"inspect", 1,
		L"show target(s) but take no action");
	CommandLine::declare_switch(INSTALL_CLSW, L"install", 1,
		L"install extension within the Inform GUI apps");
	CommandLine::declare_switch(GRAPH_CLSW, L"graph", 1,
		L"show dependency graph of target(s) but take no action");
	CommandLine::declare_switch(USE_NEEDS_CLSW, L"use-needs", 1,
		L"show all the extensions, kits and so on needed to use");
	CommandLine::declare_switch(BUILD_NEEDS_CLSW, L"build-needs", 1,
		L"show all the extensions, kits and so on needed to build");
	CommandLine::declare_switch(USE_LOCATE_CLSW, L"use-locate", 1,
		L"show file paths of all the extensions, kits and so on needed to use");
	CommandLine::declare_switch(BUILD_LOCATE_CLSW, L"build-locate", 1,
		L"show file paths of all the extensions, kits and so on needed to build");
	CommandLine::declare_switch(USE_MISSING_CLSW, L"use-missing", 1,
		L"show the extensions, kits and so on which are needed to use but missing");
	CommandLine::declare_switch(BUILD_MISSING_CLSW, L"build-missing", 1,
		L"show the extensions, kits and so on which are needed to build but missing");
	CommandLine::declare_switch(ARCHIVE_CLSW, L"archive", 1,
		L"sync copies of all extensions, kits and so on needed for -project into Materials");
	CommandLine::declare_switch(ARCHIVE_TO_CLSW, L"archive-to", 2,
		L"sync copies of all extensions, kits and so on needed into nest X");
	CommandLine::declare_switch(TOOLS_CLSW, L"tools", 2,
		L"make X the directory of intools executables");
	CommandLine::declare_boolean_switch(DRY_CLSW, L"dry", 1,
		L"make this a dry run (print but do not execute shell commands)", FALSE);
	CommandLine::declare_boolean_switch(BUILD_TRACE_CLSW, L"build-trace", 1,
		L"show verbose reasoning during -build", FALSE);
	CommandLine::declare_switch(MATCHING_CLSW, L"matching", 2,
		L"apply to all works in nest(s) matching requirement X");
	CommandLine::declare_switch(CONTENTS_OF_CLSW, L"contents-of", 2,
		L"apply to all targets in the directory X");
	CommandLine::declare_boolean_switch(RECURSIVE_CLSW, L"recursive", 1,
		L"run -contents-of recursively to look through subdirectories too", FALSE);
	CommandLine::declare_switch(VERIFY_REGISTRY_CLSW, L"verify-registry", 2,
		L"verify roster.json metadata of registry in the directory X");
	CommandLine::declare_switch(BUILD_REGISTRY_CLSW, L"build-registry", 2,
		L"construct HTML menu pages for registry in the directory X");
	CommandLine::declare_switch(PREPROCESS_HTML_CLSW, L"preprocess-html", 2,
		L"construct HTML page based on X");
	CommandLine::declare_switch(PREPROCESS_HTML_TO_CLSW, L"preprocess-html-to", 2,
		L"set destination for -preprocess-html to be X");
	CommandLine::declare_switch(PREPROCESS_APP_CLSW, L"preprocess-app", 2,
		L"use CSS suitable for app platform X (macos, windows, linux)");
	CommandLine::declare_boolean_switch(REPAIR_CLSW, L"repair", 1,
		L"quietly fix missing or incorrect extension metadata", TRUE);
	CommandLine::declare_switch(RESULTS_CLSW, L"results", 2,
		L"write HTML report file to X (for use within Inform GUI apps)");
	CommandLine::declare_boolean_switch(CONFIRMED_CLSW, L"confirmed", 1,
		L"confirm installation in the Inform GUI apps", TRUE);
	CommandLine::declare_boolean_switch(VERBOSE_CLSW, L"verbose", 1,
		L"equivalent to -verbosity=1", FALSE);
	CommandLine::declare_numerical_switch(VERBOSITY_CLSW, L"verbosity", 1,
		L"how much explanation to print: lowest is 0 (default), highest is 3");
	Supervisor::declare_options();

	CommandLine::read(argc, argv, NULL, &Main::option, &Main::bareword);

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
		case USE_LOCATE_CLSW: inbuild_task = USE_LOCATE_TTASK; break;
		case BUILD_LOCATE_CLSW: inbuild_task = BUILD_LOCATE_TTASK; break;
		case ARCHIVE_TO_CLSW:
			destination_nest = Nests::new(Pathnames::from_text(arg));
			inbuild_task = ARCHIVE_TO_TTASK;
			break;
		case ARCHIVE_CLSW: inbuild_task = ARCHIVE_TTASK; break;
		case USE_MISSING_CLSW: inbuild_task = USE_MISSING_TTASK; break;
		case BUILD_MISSING_CLSW: inbuild_task = BUILD_MISSING_TTASK; break;
		case TOOLS_CLSW:
			path_to_tools = Pathnames::from_text(arg);
			Supervisor::set_tools_location(path_to_tools); break;
		case MATCHING_CLSW: filter_text = Str::duplicate(arg); break;
		case CONTENTS_OF_CLSW: contents_of_used = TRUE;
			Main::add_directory_contents_targets(Pathnames::from_text(arg)); break;
		case RECURSIVE_CLSW: recursive = val;
			if (contents_of_used) Errors::fatal("-recursive must be used before -contents-of");
			break;
		case DRY_CLSW: dry_run_mode = val; break;
		case BUILD_TRACE_CLSW: build_trace_mode = val; break;
		case COPY_TO_CLSW: inbuild_task = COPY_TO_TTASK;
			destination_nest = Nests::new(Pathnames::from_text(arg));
			break;
		case SYNC_TO_CLSW: inbuild_task = SYNC_TO_TTASK;
			destination_nest = Nests::new(Pathnames::from_text(arg));
			break;
		case VERSIONS_IN_FILENAMES_CLSW:
			Editions::set_canonical_leaves_have_versions(val); break;
		case VERIFY_REGISTRY_CLSW:
		case BUILD_REGISTRY_CLSW:
			selected_registry = Registries::new(Pathnames::from_text(arg));
			if (Registries::read_roster(selected_registry) == FALSE) exit(1);
			if (id == BUILD_REGISTRY_CLSW)
				Registries::build(selected_registry);
			break;
		case PREPROCESS_HTML_TO_CLSW:
			preprocess_HTML_destination = Pathnames::from_text(arg);
			break;
		case PREPROCESS_APP_CLSW:
			preprocess_HTML_app = Str::duplicate(arg);
			break;
		case PREPROCESS_HTML_CLSW:
			if (preprocess_HTML_destination == NULL)
				Errors::fatal("must specify -preprocess-html-to P to give destination path P first");
			filename *F = Filenames::from_text(arg);
			filename *T = Filenames::in(preprocess_HTML_destination, Filenames::get_leafname(F));
			Registries::preprocess_HTML(T, F, preprocess_HTML_app);
			break;
		case REPAIR_CLSW: repair_mode = val; break;
		case INSTALL_CLSW: to_install = Main::file_or_path_to_copy(arg, TRUE); break;
		case RESULTS_CLSW: InbuildReport::set_filename(Filenames::from_text(arg)); break;
		case CONFIRMED_CLSW: confirmed = val; break;
		case VERBOSE_CLSW: Supervisor::set_verbosity(1); break;
		case VERBOSITY_CLSW: Supervisor::set_verbosity(val); break;
	}
	Supervisor::option(id, val, arg, state);
}

@ This is called for a command-line argument which doesn't appear as
subordinate to any switch; we take it as the name of a copy.

=
void Main::bareword(int id, text_stream *arg, void *state) {
	Main::add_file_or_path_as_target(arg, TRUE);
}
