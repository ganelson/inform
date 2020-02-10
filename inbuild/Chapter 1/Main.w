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
linked_list *inbuild_nest_list = NULL;

int main(int argc, char **argv) {
	Foundation::start();
	WordsModule::start();
	InbuildModule::start();
	targets = NEW_LINKED_LIST(inbuild_copy);
	@<Read the command line@>;
	
	path_to_inbuild = Pathnames::installation_path("INBUILD_PATH", I"inbuild");
	build_methodology *BM;
	if (path_to_tools) BM = BuildSteps::methodology(path_to_tools, FALSE);
	else BM = BuildSteps::methodology(Pathnames::up(path_to_inbuild), TRUE);
	if (dry_run_mode == FALSE) BM->methodology = SHELL_METHODOLOGY;
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
			case INSPECT_TTASK: 
				WRITE_TO(STDOUT, "%S: ", Model::genre_name(C->edition->work->genre));
				Model::write_copy(STDOUT, C);
				if (C->location_if_path) {
					WRITE_TO(STDOUT, " at path %p", C->location_if_path);
				}
				if (C->location_if_file) {
					WRITE_TO(STDOUT, " in directory %p", Filenames::get_path_to(C->location_if_file));
				}
				WRITE_TO(STDOUT, "\n");
				break;
			case GRAPH_TTASK: Graphs::describe(STDOUT, C->graph, TRUE); break;
			case BUILD_TTASK: Graphs::build(C->graph, BM); break;
			case REBUILD_TTASK: Graphs::rebuild(C->graph, BM); break;
			case COPY_TO_TTASK: if (destination_nest) Nests::copy_to(C, destination_nest, FALSE, BM); break;
			case SYNC_TO_TTASK: if (destination_nest) Nests::copy_to(C, destination_nest, TRUE, BM); break;
		}
	}
	WordsModule::end();
	InbuildModule::end();
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
		L"make this a dry run (print but do not execute shell commands)");
	CommandLine::declare_switch(MATCHING_CLSW, L"matching", 2,
		L"apply to all works in nest(s) matching requirement X");
	CommandLine::declare_switch(CONTENTS_OF_CLSW, L"contents-of", 2,
		L"apply to all targets in the directory X");
	SharedCLI::declare_options();

	CommandLine::read(argc, argv, NULL, &Main::option, &Main::bareword);

	if (LinkedLists::len(unsorted_nest_list) == 0)
		SharedCLI::add_nest(
			Pathnames::from_text(I"inform7/Internal"), INTERNAL_NEST_TAG);
	inbuild_nest_list = SharedCLI::nest_list();

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
	}
	SharedCLI::option(id, val, arg, state);
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
	inbuild_copy *C = Model::claim(arg);
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

@d LEXER_PROBLEM_HANDLER Main::lexer_problem_handler

=
vocabulary_meaning Main::ignore(vocabulary_entry *ve) {
	vocabulary_meaning vm;
	vm.enigmatic_number = 16339;
	return vm;
}

void Main::lexer_problem_handler(int err, text_stream *problem_source_description, wchar_t *word) {
	if (err == MEMORY_OUT_LEXERERROR)
		Errors::fatal("Out of memory: unable to create lexer workspace");
	TEMPORARY_TEXT(word_t);
	if (word) WRITE_TO(word_t, "%w", word);
	switch (err) {
		case STRING_TOO_LONG_LEXERERROR:
			Errors::with_text("Too much text in quotation marks: %S", word_t);
            break;
		case WORD_TOO_LONG_LEXERERROR:
			Errors::with_text("Word too long: %S", word_t);
			break;
		case I6_TOO_LONG_LEXERERROR:
			Errors::with_text("I6 inclusion too long: %S", word_t);
			break;
		case STRING_NEVER_ENDS_LEXERERROR:
			Errors::with_text("Quoted text never ends: %S", problem_source_description);
			break;
		case COMMENT_NEVER_ENDS_LEXERERROR:
			Errors::with_text("Square-bracketed text never ends: %S", problem_source_description);
			break;
		case I6_NEVER_ENDS_LEXERERROR:
			Errors::with_text("I6 inclusion text never ends: %S", problem_source_description);
			break;
		default:
			internal_error("unknown lexer error");
    }
	DISCARD_TEXT(word_t);
}

@

@d PREFORM_LANGUAGE_TYPE void
