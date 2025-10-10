[Main::] Main.

The command-line interface for the Inform 7 compiler tool.

@ On some platforms the core Inform compiler is a separate command-line tool,
so that execution should begin with |main()|, as in all C programs. But some
Inform UI applications need to compile it into the body of a larger program:
those should define the symbol |SUPPRESS_MAIN| and call |Main::deputy|
when they want I7 to run.

@d PROGRAM_NAME "inform7"

=
#ifndef SUPPRESS_MAIN
int main(int argc, char *argv[]) {
	return Main::deputy(argc, argv);
}
#endif

@ And so the //Main::deputy// function now has the opportunity to be head
honcho, and for the first fifteen years of Inform 7, it was exactly that. In
2020, though, it was deposed in a boardroom coup by a new CEO, the //supervisor//
module. High-level decisions on what to compile, where to put the result, and
so on, are all now taken by //supervisor//. Even the command line is very largely
read and dealt with by //supervisor// and not by this section after all. The
upshot is that //Main::deputy// is now a manager in name only, reduced to the
equivalent of unlocking the doors and turning the lights on in the morning.

=
int silence_is_golden = FALSE;
int index_explicitly_set = FALSE, problems_explicitly_set = FALSE;
pathname *diagnostics_path = NULL;
text_stream *log_to_project = NULL;

int Main::deputy(int argc, char *argv[]) {
	@<Start up@>;
	int proceed = Main::read_command_line(argc, argv);
	Pathnames::set_path_to_LP_resources(Nests::get_location(Supervisor::internal_if_set()));
	PluginCalls::start();
	if (proceed) {
		if (silence_is_golden)
			ProgressBar::enable_or_disable(FALSE); /* disable */
		else
			PRINT("Inform 7 v[[Version Number]] has started.\n", FALSE, TRUE);
		inform_project *proj = NULL;
		@<Find the project identified for us by Inbuild@>;
		@<Open the debugging log and the problems report@>;
		@<Build the project@>;
	}

	@<Post mortem logging@>;
	if (proceed) @<Shutdown and rennab@>;
	if (problem_count > 0) ProblemSigils::exit(1);
	@<Shut down the modules@>;
	return 0;
}

@ We need to make sure that internal errors, though they should never happen,
are reported as problem messages (fed to our HTML problems report) rather than
simply causing an abrupt exit with only a plain text error written to |stderr|.
See the |problems| module for more.

@<Start up@> =
    @<Start up the modules@>;
	Errors::set_internal_handler(&StandardProblems::internal_error_fn);
	Task::start_timers();

@<Start up the modules@> =
	Foundation::start(argc, argv); /* must be started first */
	LiterateModule::start();
	WordsModule::start();
	InflectionsModule::start();
	SyntaxModule::start();
	LexiconModule::start();
	LinguisticsModule::start();
	KindsModule::start();
	CalculusModule::start();
	ProblemsModule::start();
	CoreModule::start();
	AssertionsModule::start();
	KnowledgeModule::start();
	ImperativeModule::start();
	RuntimeModule::start();
	ValuesModule::start();
	IFModule::start();
	MultimediaModule::start();
	HTMLModule::start();
	IndexModule::start();
	ArchModule::start();
	BytecodeModule::start();
	BuildingModule::start();
	PipelineModule::start();
	FinalModule::start();
	SupervisorModule::start();

@ The //supervisor// would happily send us instructions to compile multiple
projects, but we can only accept one; and in fact the //inform7// command line
isn't set up to allow more, so this error is not easy to generate.

@<Find the project identified for us by Inbuild@> =
	inform_project *P;
	LOOP_OVER(P, inform_project) {
		if (proj) Problems::fatal("Multiple projects given on the command line");
		proj = P;
	}
	if ((proj) && (proj->stand_alone)) {
		if (index_explicitly_set == FALSE)
			Task::disable_or_enable_index(TRUE); /* disable it */
		if (problems_explicitly_set == FALSE)
			Task::disable_or_enable_problems(TRUE); /* disable it */
		ProgressBar::enable_or_disable(FALSE); /* disable it */
		if (Log::get_debug_log_filename() == NULL)
			Log::set_aspect_from_command_line(I"nothing", TRUE);
	}
	if (silence_is_golden) Task::disable_or_enable_problems(TRUE); /* disable it */

@ //supervisor// supplies us with a folder in which to write the debugging log
and the Problems report (the HTML version of our error messages or success
message, which is displayed in the Inform app when a compilation has finished).
This folder will usually be the |Build| subfolder of the project folder,
but we won't assume that. Remember, //supervisor// knows best.

@<Open the debugging log and the problems report@> =
	if (((proj) && (proj->stand_alone == FALSE)) || (Log::get_debug_log_filename())) {
		if (proj) {
			pathname *build_folder = Projects::build_path(proj);
			if (Pathnames::create_in_file_system(build_folder) == 0)
				Problems::fatal(
					"Unable to create Build folder for project: is it read-only?");
			filename *DF = Filenames::in(build_folder, I"Debug log.txt");
			Log::set_debug_log_filename(DF);
		}
		Log::open();
		LOG("inform7 was called as:");
		for (int i=0; i<argc; i++) LOG(" %s", argv[i]);
		LOG("\n");
		CommandLine::play_back_log();
		if (Str::len(log_to_project) > 0)
			if (Log::set_aspect_from_command_line(log_to_project, FALSE) == FALSE)
				Problems::fatal("Unknown -log-to-project setting");
	}
	if (proj) {
		if (Task::problems_enabled()) {
			pathname *build_folder = Projects::build_path(proj);
			filename *PF = Filenames::in(build_folder, I"Problems.html");
			StandardProblems::start_problems_report(PF);
		} else {
			StandardProblems::start_problems_report(NULL);
		}

		HTML::set_link_abbreviation_path(Projects::path(proj));
	}

@ The compiler is now ready for use. We ask //supervisor// to go ahead and
build that project: it will incrementally build some of the resources needed,
if any of them are, and then call upon //core// to perform the actual
compilation.

@<Build the project@> =
	Supervisor::go_operational();
	if (proj) {
		InterSkill::echo_kit_building();
		Copies::build(STDOUT, proj->as_copy, BuildMethodology::stay_in_current_process());
		Task::stop_timers();
	}

@ Diagnostics files fall into the category of "be careful what you wish for";
they can be rather lengthy.

@<Post mortem logging@> =
	if ((problem_count == 0) && (diagnostics_path)) {
		Main::write_diagnostics(
			I"timings-diagnostics.txt", &Task::log_stopwatch);
		Main::write_diagnostics(
			I"memory-diagnostics.txt", &Memory::log_statistics);
		Main::write_diagnostics(
			I"syntax-diagnostics.txt", &Main::log_task_syntax_tree);
		Main::write_diagnostics(
			I"syntax-summary.txt", &Main::log_task_syntax_summary);
		Main::write_diagnostics(
			I"preform-diagnostics.txt", &Instrumentation::log);
		Main::write_diagnostics(
			I"preform-summary.txt", &Main::log_preform_summary);
		Main::write_diagnostics(
			I"documentation-diagnostics.txt", &DocReferences::log_statistics);
		Main::write_diagnostics(
			I"verbs-diagnostics.txt", &VerbUsages::log_all);
		Main::write_diagnostics(
			I"excerpts-diagnostics.txt", &FromLexicon::statistics);
		Main::write_diagnostics(
			I"stock-diagnostics.txt", &Stock::log_all);
	}

@<Shutdown and rennab@> =
	if (silence_is_golden == FALSE) {
		ProblemBuffer::write_reports(FALSE);
		LOG("Total of %d files written as streams.\n", total_file_writes);
		Writers::log_escape_usage();
		WRITE_TO(STDOUT, "Inform 7 has finished.\n");
	}

@<Shut down the modules@> =
	WordsModule::end();
	InflectionsModule::end();
	SyntaxModule::end();
	LexiconModule::end();
	LinguisticsModule::end();
	KindsModule::end();
	CalculusModule::end();
	ProblemsModule::end();
	MultimediaModule::end();
	CoreModule::end();
	AssertionsModule::end();
	KnowledgeModule::end();
	ImperativeModule::end();
	RuntimeModule::end();
	ValuesModule::end();
	IFModule::end();
	IndexModule::end();
	HTMLModule::end();
	BytecodeModule::end();
	ArchModule::end();
	BuildingModule::end();
	PipelineModule::end();
	FinalModule::end();
	SupervisorModule::end();
	LiterateModule::end();
	Foundation::end(); /* must be ended last */

@ =
void Main::write_diagnostics(text_stream *leafname, void (*write_fn)(void)) {
	filename *F = Filenames::in(diagnostics_path, leafname);
	text_stream diagnostics_file;
	if (STREAM_OPEN_TO_FILE(&diagnostics_file, F, ISO_ENC) == FALSE)
		internal_error("can't open diagnostics file");
	text_stream *save_DL = DL;
	DL = &diagnostics_file;
	Streams::enable_debugging(DL);
	(*write_fn)();
	DL = save_DL;
	STREAM_CLOSE(&diagnostics_file);
}

void Main::log_task_syntax_tree(void) {
	Node::log_tree(DL, Task::syntax_tree()->root_node);
}

void Main::log_preform_summary(void) {
	Instrumentation::log_nt(<s-literal>, TRUE);
}

void Main::log_task_syntax_summary(void) {
	Node::summarise_tree(DL, Task::syntax_tree()->root_node);
}

@h Command line processing.
The bulk of the command-line options are both registered and processed by
//supervisor// rather than here: in particular, every switch ever used by the
Inform UI apps is really a command to //supervisor// not to |inform7|.

=
int Main::read_command_line(int argc, char *argv[]) {
	CommandLine::declare_heading(
		U"inform7: a compiler from source text to Inter code\n\n"
		U"Usage: inform7 [OPTIONS]\n");

	@<Register command-line arguments@>;
	Supervisor::declare_options();
	
	int sub = CommandLine::read(argc, argv, NULL, &Main::switch, &Main::bareword);
	if (sub != NO_CLSUB) {
		if (shared_internal_nest == NULL) {
			pathname *path_to_inform = Pathnames::installation_path("INFORM7_PATH", I"inform7");
			Supervisor::add_nest(Pathnames::down(path_to_inform, I"Internal"), INTERNAL_NEST_TAG);
		}
		Supervisor::optioneering_complete(NULL, TRUE, &CorePreform::load);
	}
	return (sub != NO_CLSUB)?TRUE:FALSE;
}

@ What remains here are just some eldritch options for testing the |inform7|
compiler via Delia scripts in |intest|.

@e INFORM_TESTING_CLSG

@e CRASHALL_CLSW
@e DIAGNOSTICS_CLSW
@e INDEX_CLSW
@e PROBLEMS_CLSW
@e CENSUS_UPDATE_CLSW
@e PROGRESS_CLSW
@e REQUIRE_PROBLEM_CLSW
@e SIGILS_CLSW
@e TEST_OUTPUT_CLSW
@e SILENCE_CLSW
@e CHECK_RESOURCES_CLSW
@e INBUILD_VERBOSE_CLSW
@e INBUILD_VERBOSITY_CLSW
@e LOG_TO_PROJECT_CLSW

@<Register command-line arguments@> =
	CommandLine::begin_group(INFORM_TESTING_CLSG, I"for testing and debugging inform7");
	CommandLine::declare_boolean_switch(CRASHALL_CLSW, U"crash-all", 1,
		U"intentionally crash on Problem messages, for backtracing", FALSE);
	CommandLine::declare_boolean_switch(INDEX_CLSW, U"index", 1,
		U"produce an Index", TRUE);
	CommandLine::declare_boolean_switch(PROBLEMS_CLSW, U"problems", 1,
		U"produce (an HTML) Problems report page", TRUE);
	CommandLine::declare_boolean_switch(CENSUS_UPDATE_CLSW, U"census-update", 1,
		U"withdrawn: previously, 'update the extensions census'", TRUE);
	CommandLine::declare_boolean_switch(PROGRESS_CLSW, U"progress", 1,
		U"display progress percentages", TRUE);
	CommandLine::declare_boolean_switch(SIGILS_CLSW, U"sigils", 1,
		U"print Problem message sigils", FALSE);
	CommandLine::declare_boolean_switch(CHECK_RESOURCES_CLSW, U"resource-checking", 1,
		U"check that figures, sounds and similar resources exist at compile-time", TRUE);
	CommandLine::declare_boolean_switch(DIAGNOSTICS_CLSW, U"diagnostics", 2,
		U"if no problems occur, write diagnostics files to directory X", FALSE);
	CommandLine::declare_switch(REQUIRE_PROBLEM_CLSW, U"require-problem", 2,
		U"return 0 unless exactly this Problem message is generated");
	CommandLine::declare_switch(LOG_TO_PROJECT_CLSW, U"log-to-project", 2,
		U"like -log X, but writing the debugging log into the project");
	CommandLine::declare_switch(TEST_OUTPUT_CLSW, U"test-output", 2,
		U"write output of internal tests to file X");
	CommandLine::declare_boolean_switch(SILENCE_CLSW, U"silence", 1,
		U"practice 'silence is golden': print only Unix-style errors", FALSE);
	CommandLine::declare_boolean_switch(INBUILD_VERBOSE_CLSW, U"inbuild-verbose", 1,
		U"equivalent to -inbuild-verbosity=1", FALSE);
	CommandLine::declare_numerical_switch(INBUILD_VERBOSITY_CLSW, U"inbuild-verbosity", 1,
		U"how much inbuild should explain: lowest is 0 (default), highest is 3");
	CommandLine::end_group();

@ Three of the five options here actually configure the |problems| module
rather than |core|.

=
void Main::switch(int id, int val, text_stream *arg, void *state) {
	switch (id) {
		case CRASHALL_CLSW: debugger_mode = val;
			ProblemSigils::crash_on_problems(val); break;
		case INDEX_CLSW:
			Task::disable_or_enable_index(val?FALSE:TRUE);
			Task::disable_or_enable_extensions_update(val?FALSE:TRUE);
			index_explicitly_set = TRUE; break;
		case PROBLEMS_CLSW: Task::disable_or_enable_problems(val?FALSE:TRUE);
			problems_explicitly_set = TRUE; break;
		case CENSUS_UPDATE_CLSW:
			WRITE_TO(STDOUT, "(ignoring -census-update and -no-census-update, "
				"which have been withdrawn)\n");
			break;
		case PROGRESS_CLSW: ProgressBar::enable_or_disable(val); break;
		case SIGILS_CLSW: ProblemSigils::echo_sigils(val); break;
		case REQUIRE_PROBLEM_CLSW: ProblemSigils::require(arg); break;
		case DIAGNOSTICS_CLSW: diagnostics_path = Pathnames::from_text(arg); break;
		case CHECK_RESOURCES_CLSW: ResourceFinder::set_mode(val); break;
		case TEST_OUTPUT_CLSW: InternalTests::set_file(Filenames::from_text(arg)); break;
		case LOG_TO_PROJECT_CLSW: log_to_project = Str::duplicate(arg); break;
		case SILENCE_CLSW: silence_is_golden = TRUE; break;
		case INBUILD_VERBOSE_CLSW: Supervisor::set_verbosity(1); break;
		case INBUILD_VERBOSITY_CLSW: Supervisor::set_verbosity(val); break;
	}
	Supervisor::option(id, val, arg, state);
}

void Main::bareword(int id, text_stream *opt, void *state) {
	if (Str::is_whitespace(opt) == FALSE) {
		if (Str::get_last_char(opt) == FOLDER_SEPARATOR)
			Errors::fatal_with_text(
				"to compile a project in a directory, use '-project %S'", opt);
		filename *F = Filenames::from_text(opt);
		if (Supervisor::set_I7_source(F) == FALSE)
			Errors::fatal_with_text("unknown command line argument: %S (see -help)", opt);
	}
}

int Main::silence_is_golden(void) {
	return silence_is_golden;
}
