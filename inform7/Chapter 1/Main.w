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
pathname *diagnostics_path = NULL;

int Main::deputy(int argc, char *argv[]) {
    @<Start up the modules@>;
	@<Banner and startup@>;
	int proceed = Main::read_command_line(argc, argv);
	if (proceed) {
		inform_project *proj = NULL;
		@<Find the project identified for us by Inbuild@>;
		@<Open the debugging log and the problems report@>;
		@<Name the telemetry@>;
		@<Build the project@>;
	}

	@<Post mortem logging@>;
	if (proceed) @<Shutdown and rennab@>;
	if (problem_count > 0) ProblemSigils::exit(1);
	@<Shut down the modules@>;
	return 0;
}

@<Start up the modules@> =
	Foundation::start(argc, argv); /* must be started first */
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
	CodegenModule::start();
	SupervisorModule::start();

@ The very first thing we do is to make sure internal errors, though they
should never happen, are reported as problem messages (fed to our HTML
problems report) rather than simply causing an abrupt exit with only a
plain text error written to |stderr|. See the |problems| module for more.

@<Banner and startup@> =
	Errors::set_internal_handler(&StandardProblems::internal_error_fn);
	PRINT("Inform 7 v[[Version Number]] has started.\n", FALSE, TRUE);
	Plugins::Manage::start();
	Task::start_timers();

@ The //supervisor// would happily send us instructions to compile multiple
projects, but we can only accept one; and in fact the //inform7// command line
isn't set up to allow more, so this error is not easy to generate.

@<Find the project identified for us by Inbuild@> =
	inform_project *P;
	LOOP_OVER(P, inform_project) {
		if (proj) Problems::fatal("Multiple projects given on the command line");
		proj = P;
	}

@ //supervisor// supplies us with a folder in which to write the debugging log
and the Problems report (the HTML version of our error messages or success
message, which is displayed in the Inform app when a compilation has finished).
This folder will usually be the |Build| subfolder of the project folder,
but we won't assume that. Remember, //supervisor// knows best.

@<Open the debugging log and the problems report@> =
	pathname *build_folder = Projects::build_path(proj);
	if (Pathnames::create_in_file_system(build_folder) == 0)
		Problems::fatal(
			"Unable to create Build folder for project: is it read-only?");

	filename *DF = Filenames::in(build_folder, I"Debug log.txt");
	Log::set_debug_log_filename(DF);
	Log::open();
	LOG("inform7 was called as:");
	for (int i=0; i<argc; i++) LOG(" %s", argv[i]);
	LOG("\n");
	CommandLine::play_back_log();

	filename *PF = Filenames::in(build_folder, I"Problems.html");
	StandardProblems::start_problems_report(PF);

	HTML::set_link_abbreviation_path(Projects::path(proj));

@ Telemetry is not as sinister as it sounds: the app isn't sending data out
on the Internet, only (if requested) logging what it's doing to a local file.
This was provided for classroom use, so that teachers can see what their
students have been getting stuck on. In any case, it needs to be activated
with a use option, so by default this file will never be written.

@<Name the telemetry@> =
	pathname *P = Pathnames::down(Supervisor::transient(), I"Telemetry");
	if (Pathnames::create_in_file_system(P)) {
		TEMPORARY_TEXT(leafname_of_telemetry)
		int this_month = the_present->tm_mon + 1;
		int this_day = the_present->tm_mday;
		int this_year = the_present->tm_year + 1900;
		WRITE_TO(leafname_of_telemetry,
			"Telemetry %04d-%02d-%02d.txt", this_year, this_month, this_day);
		filename *F = Filenames::in(P, leafname_of_telemetry);
		Telemetry::locate_telemetry_file(F);
		DISCARD_TEXT(leafname_of_telemetry)
	}

@ The compiler is now ready for use. We ask //supervisor// to go ahead and
build that project: it will incrementally build some of the resources needed,
if any of them are, and then call upon //core// to perform the actual
compilation.

@<Build the project@> =
	Supervisor::go_operational();
	if (proj) {
		Copies::build(STDOUT, proj->as_copy, BuildMethodology::stay_in_current_process());
		Task::stop_timers();
	}

@ Diagnostics files fall into the category of "be careful what you wish for";
they can be rather lengthy.

@<Post mortem logging@> =
	if (problem_count == 0) {
		TemplateReader::report_unacted_upon_interventions();
		if (diagnostics_path) {
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
				I"documentation-diagnostics.txt", &Index::DocReferences::log_statistics);
			Main::write_diagnostics(
				I"verbs-diagnostics.txt", &VerbsAtRunTime::log_all);
			Main::write_diagnostics(
				I"excerpts-diagnostics.txt", &FromLexicon::statistics);
			Main::write_diagnostics(
				I"stock-diagnostics.txt", &Stock::log_all);
		}
	}

@<Shutdown and rennab@> =
	ProblemBuffer::write_reports(FALSE);
	LOG("Total of %d files written as streams.\n", total_file_writes);
	Writers::log_escape_usage();
	WRITE_TO(STDOUT, "Inform 7 has finished.\n");

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
	CodegenModule::end();
	SupervisorModule::end();
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
		L"inform7: a compiler from source text to Inter code\n\n"
		L"Usage: inform7 [OPTIONS]\n");

	@<Register command-line arguments@>;
	Supervisor::declare_options();
	int proceed = CommandLine::read(argc, argv, NULL, &Main::switch, &Main::bareword);
	if (proceed) Supervisor::optioneering_complete(NULL, TRUE, &CorePreform::load);
	return proceed;
}

@ What remains here are just some eldritch options for testing the |inform7|
compiler via Delia scripts in |intest|.

@e INFORM_TESTING_CLSG

@e CRASHALL_CLSW
@e DIAGNOSTICS_CLSW
@e INDEX_CLSW
@e CENSUS_UPDATE_CLSW
@e PROGRESS_CLSW
@e REQUIRE_PROBLEM_CLSW
@e SIGILS_CLSW
@e TEST_OUTPUT_CLSW

@<Register command-line arguments@> =
	CommandLine::begin_group(INFORM_TESTING_CLSG, I"for testing and debugging inform7");
	CommandLine::declare_boolean_switch(CRASHALL_CLSW, L"crash-all", 1,
		L"intentionally crash on Problem messages, for backtracing", FALSE);
	CommandLine::declare_boolean_switch(INDEX_CLSW, L"index", 1,
		L"produce an Index", TRUE);
	CommandLine::declare_boolean_switch(CENSUS_UPDATE_CLSW, L"census-update", 1,
		L"update the extensions census", TRUE);
	CommandLine::declare_boolean_switch(PROGRESS_CLSW, L"progress", 1,
		L"display progress percentages", TRUE);
	CommandLine::declare_boolean_switch(SIGILS_CLSW, L"sigils", 1,
		L"print Problem message sigils", FALSE);
	CommandLine::declare_boolean_switch(DIAGNOSTICS_CLSW, L"diagnostics", 2,
		L"if no problems occur, write diagnostics files to directory X", FALSE);
	CommandLine::declare_switch(REQUIRE_PROBLEM_CLSW, L"require-problem", 2,
		L"return 0 unless exactly this Problem message is generated");
	CommandLine::declare_switch(TEST_OUTPUT_CLSW, L"test-output", 2,
		L"write output of internal tests to file X");
	CommandLine::end_group();

@ Three of the five options here actually configure the |problems| module
rather than |core|.

=
void Main::switch(int id, int val, text_stream *arg, void *state) {
	switch (id) {
		case CRASHALL_CLSW: debugger_mode = val;
			ProblemSigils::crash_on_problems(val); break;
		case INDEX_CLSW: I6T::disable_or_enable_index(val?FALSE:TRUE); break;
		case CENSUS_UPDATE_CLSW: Index::disable_or_enable_census(val?FALSE:TRUE); break;
		case PROGRESS_CLSW: ProgressBar::enable_or_disable(val); break;
		case SIGILS_CLSW: ProblemSigils::echo_sigils(val); break;
		case REQUIRE_PROBLEM_CLSW: ProblemSigils::require(arg); break;
		case DIAGNOSTICS_CLSW: diagnostics_path = Pathnames::from_text(arg); break;
		case TEST_OUTPUT_CLSW: InternalTests::set_file(Filenames::from_text(arg)); break;
	}
	Supervisor::option(id, val, arg, state);
}

void Main::bareword(int id, text_stream *opt, void *state) {
	if (Supervisor::set_I7_source(opt) == FALSE)
		Errors::fatal_with_text("unknown command line argument: %S (see -help)", opt);
}
