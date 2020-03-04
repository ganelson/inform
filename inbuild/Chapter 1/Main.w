[Main::] Main.

The top level, which decides what is to be done and then carries
this plan out.

@h Main routine.

@d INTOOL_NAME "inbuild"

@e INSPECT_TTASK from 1
@e GRAPH_TTASK
@e BUILD_TTASK
@e REBUILD_TTASK
@e COPY_TO_TTASK
@e SYNC_TO_TTASK

=
pathname *path_to_inbuild = NULL;
pathname *path_to_tools = NULL;

int inbuild_task = INSPECT_TTASK;
int dry_run_mode = FALSE;
linked_list *targets = NULL; /* of |inbuild_copy| */
inbuild_nest *destination_nest = NULL;
text_stream *filter_text = NULL;
text_stream *unit_test = NULL;
linked_list *inbuild_nest_list = NULL;

int main(int argc, char **argv) {
	Foundation::start();
	WordsModule::start();
	SyntaxModule::start();
	HTMLModule::start();
	ArchModule::start();
	InbuildModule::start();
	targets = NEW_LINKED_LIST(inbuild_copy);
	@<Read the command line@>;
	
	if (Str::len(unit_test) > 0) dry_run_mode = TRUE;
	int use = SHELL_METHODOLOGY;
	if (dry_run_mode) use = DRY_RUN_METHODOLOGY;
	build_methodology *BM;
	if (path_to_tools) BM = BuildMethodology::new(path_to_tools, FALSE, use);
	else BM = BuildMethodology::new(Pathnames::up(path_to_inbuild), TRUE, use);
	if (Str::len(unit_test) > 0) {
		if (Str::eq(unit_test, I"compatibility")) Compatibility::test(STDOUT);
		else if (Str::eq(unit_test, I"semver")) VersionNumbers::test(STDOUT);
		else Errors::with_text("no such unit test: %S", unit_test);
	} else {
		if (Str::len(filter_text) > 0) {
			TEMPORARY_TEXT(errors);
			inbuild_requirement *req = Requirements::from_text(filter_text, errors);
			if (Str::len(errors) > 0) {
				Errors::with_text("requirement malformed: %S", errors);
			} else {
				linked_list *L = NEW_LINKED_LIST(inbuild_search_result);
				Nests::search_for(req, inbuild_nest_list, L);
				inbuild_search_result *R;
				LOOP_OVER_LINKED_LIST(R, inbuild_search_result, L) {
					ADD_TO_LINKED_LIST(R->copy, inbuild_copy, targets);
				}
			}
			DISCARD_TEXT(errors);
		}
		inbuild_copy *C;
		LOOP_OVER_LINKED_LIST(C, inbuild_copy, targets) {
			switch (inbuild_task) {
				case INSPECT_TTASK: Copies::inspect(STDOUT, C); break;
				case GRAPH_TTASK: Copies::show_graph(STDOUT, C); break;
				case BUILD_TTASK: Copies::build(STDOUT, C, BM); break;
				case REBUILD_TTASK: Copies::rebuild(STDOUT, C, BM); break;
				case COPY_TO_TTASK: if (destination_nest) Nests::copy_to(C, destination_nest, FALSE, BM); break;
				case SYNC_TO_TTASK: if (destination_nest) Nests::copy_to(C, destination_nest, TRUE, BM); break;
			}
		}
	}
	ArchModule::end();
	InbuildModule::end();
	HTMLModule::end();
	SyntaxModule::end();
	WordsModule::end();
	Foundation::end();
	return 0;
}

@ We use Foundation to read the command line:

@e BUILD_CLSW
@e REBUILD_CLSW
@e GRAPH_CLSW
@e INSPECT_CLSW
@e DRY_CLSW
@e TOOLS_CLSW
@e CONTENTS_OF_CLSW
@e MATCHING_CLSW
@e COPY_TO_CLSW
@e SYNC_TO_CLSW
@e UNIT_TEST_CLSW

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
	CommandLine::declare_switch(TOOLS_CLSW, L"tools", 2,
		L"make X the directory of intools executables, and exit developer mode");
	CommandLine::declare_boolean_switch(DRY_CLSW, L"dry", 1,
		L"make this a dry run (print but do not execute shell commands)", FALSE);
	CommandLine::declare_switch(MATCHING_CLSW, L"matching", 2,
		L"apply to all works in nest(s) matching requirement X");
	CommandLine::declare_switch(CONTENTS_OF_CLSW, L"contents-of", 2,
		L"apply to all targets in the directory X");
	CommandLine::declare_switch(UNIT_TEST_CLSW, L"unit-test", 2,
		L"perform unit test X (for debugging inbuild only)");
	Inbuild::declare_options();

	CommandLine::read(argc, argv, NULL, &Main::option, &Main::bareword);

	if (LinkedLists::len(unsorted_nest_list) == 0)
		Inbuild::add_nest(
			Pathnames::from_text(I"inform7/Internal"), INTERNAL_NEST_TAG);

	path_to_inbuild = Pathnames::installation_path("INBUILD_PATH", I"inbuild");
	pathname *P = Pathnames::subfolder(path_to_inbuild, I"Tangled");
	filename *S = Filenames::in_folder(P, I"Syntax.preform");
	wording W = Preform::load_from_file(S);
	Preform::parse_preform(W, FALSE);
	
	CommandLine::play_back_log();
	inbuild_copy *proj = NULL, *C;
	LOOP_OVER_LINKED_LIST(C, inbuild_copy, targets)
		if (C->edition->work->genre == project_bundle_genre) {
			if (Str::len(project_bundle_request) > 0)
				Errors::with_text("can only work on one project bundle at a time, so ignoring '%S'", C->edition->work->title);
			else if (proj) Errors::with_text("can only work on one project bundle at a time, so ignoring '%S'", C->edition->work->title);
			else proj = C;
		}
	
	proj = Inbuild::optioneering_complete(proj, FALSE);
	if (proj) {
		int found = FALSE;
		LOOP_OVER_LINKED_LIST(C, inbuild_copy, targets)
			if (C == proj)
				found = TRUE;
		if (found == FALSE) ADD_TO_LINKED_LIST(proj, inbuild_copy, targets);
	}
	inbuild_nest_list = Inbuild::nest_list();
	Inbuild::go_operational();

@ =
void Main::option(int id, int val, text_stream *arg, void *state) {
	switch (id) {
		case BUILD_CLSW: inbuild_task = BUILD_TTASK; break;
		case REBUILD_CLSW: inbuild_task = REBUILD_TTASK; break;
		case INSPECT_CLSW: inbuild_task = INSPECT_TTASK; break;
		case GRAPH_CLSW: inbuild_task = GRAPH_TTASK; break;
		case TOOLS_CLSW: path_to_tools = Pathnames::from_text(arg); break;
		case MATCHING_CLSW: filter_text = Str::duplicate(arg); break;
		case CONTENTS_OF_CLSW: Main::load_many(Pathnames::from_text(arg)); break;
		case DRY_CLSW: dry_run_mode = val; break;
		case COPY_TO_CLSW: inbuild_task = COPY_TO_TTASK;
			destination_nest = Nests::new(Pathnames::from_text(arg));
			break;
		case SYNC_TO_CLSW: inbuild_task = SYNC_TO_TTASK;
			destination_nest = Nests::new(Pathnames::from_text(arg));
			break;
		case UNIT_TEST_CLSW: unit_test = Str::duplicate(arg); break;
	}
	Inbuild::option(id, val, arg, state);
}

void Main::bareword(int id, text_stream *arg, void *state) {
	Main::load_one(arg, TRUE);
}

void Main::load_many(pathname *P) {
	scan_directory *D = Directories::open(P);
	TEMPORARY_TEXT(LEAFNAME);
	while (Directories::next(D, LEAFNAME)) {
		TEMPORARY_TEXT(FILENAME);
		WRITE_TO(FILENAME, "%p%c%S", P, FOLDER_SEPARATOR, LEAFNAME);
		Main::load_one(FILENAME, FALSE);
		DISCARD_TEXT(FILENAME);
	}
	DISCARD_TEXT(LEAFNAME);
	Directories::close(D);
}

void Main::load_one(text_stream *arg, int throwing_error) {
	inbuild_copy *C = Copies::claim(arg);
	if (C == NULL) {
		if (throwing_error) Errors::with_text("unable to identify '%S'", arg);
		return;
	}
	ADD_TO_LINKED_LIST(C, inbuild_copy, targets);
}

@ Since we want to include the words module, we have to define the following
structure and initialiser:

@d VOCABULARY_MEANING_INITIALISER Main::ignore

=
typedef struct vocabulary_meaning {
	int enigmatic_number;
} vocabulary_meaning;

@

=
vocabulary_meaning Main::ignore(vocabulary_entry *ve) {
	vocabulary_meaning vm;
	vm.enigmatic_number = 90125;
	return vm;
}

@

@d PREFORM_LANGUAGE_TYPE void
@d PARSE_TREE_TRAVERSE_TYPE void
@d SENTENCE_NODE Main::sentence_level
@d PARSE_TREE_METADATA_SETUP SourceText::node_metadata

=
int Main::sentence_level(node_type_t t) {
	return FALSE;
}
