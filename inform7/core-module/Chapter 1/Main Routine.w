[CoreMain::] Main Routine.

The top level of the Inform 7 compiler, reading command line arguments
and preparing the way.

@h The Management.
All C programs begin execution in |main|, but the function below is not it.
This is because the compiler proper is a tiny wrapper around a collection of
modules, of which //core// is only one. |main| is found in that wrapper. On the
other hand, |main| simply starts up the modules and hands straight over to us.

So the |CoreMain::main| function certainly has the opportunity to be head
honcho, and for the first fifteen years of Inform 7, it was exactly that. In
2020, though, it was deposed in a boardroom coup by a new CEO, the //supervisor//
module. High-level decisions on what to compile, where to put the result, and
so on, are all now taken by //supervisor//. Even the command line is very largely
read and dealt with by //supervisor// and not by //core//, as we shall see. The
upshot is that //CoreMain::main// is now a manager in name only, reduced to the
equivalent of unlocking the doors and turning the lights on in the morning.

=
pathname *path_to_inform7 = NULL;
pathname *diagnostics_path = NULL;
stopwatch_timer *inform7_timer = NULL, *supervisor_timer = NULL;

int CoreMain::main(int argc, char *argv[]) {
	@<Banner and startup@>;
	int proceed = CoreMain::read_command_line(argc, argv);
	if (proceed) {
		inform_project *project = NULL;
		@<Find the project identified for us by Inbuild@>;
		@<Open the debugging log and the problems report@>;
		@<Name the telemetry@>;
		@<Build the project@>;
	}

	@<Post mortem logging@>;
	if (proceed) @<Shutdown and rennab@>;
	if (problem_count > 0) ProblemSigils::exit(1);
	return 0;
}

@ The very first thing we do is to make sure internal errors, though they
should never happen, are reported as problem messages (fed to our HTML
problems report) rather than simply causing an abrupt exit with only a
plain text error written to |stderr|. See the |problems| module for more.

@<Banner and startup@> =
	Errors::set_internal_handler(&StandardProblems::internal_error_fn);
	PRINT("Inform 7 v[[Version Number]] has started.\n", FALSE, TRUE);
	Plugins::Manage::start();
	inform7_timer = Time::start_stopwatch(NULL, I"inform7 run");
	supervisor_timer = Time::start_stopwatch(inform7_timer, I"supervisor");

@ The //supervisor// would happily send us instructions to compile multiple
projects, but we can only accept one; and in fact the //inform7// command line
isn't set up to allow more, so this error is not easy to generate.

@<Find the project identified for us by Inbuild@> =
	inform_project *proj;
	LOOP_OVER(proj, inform_project) {
		if (project) 
			Problems::fatal(
				"Multiple projects given on the command line");
		project = proj;
	}

@ //supervisor// supplies us with a folder in which to write the debugging log
and the Problems report (the HTML version of our error messages or success
message, which is displayed in the Inform app when a compilation has finished).
This folder will usually be the |Build| subfolder of the project folder,
but we won't assume that. Remember, //supervisor// knows best.

@<Open the debugging log and the problems report@> =
	pathname *build_folder = Projects::build_path(project);
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

	HTML::set_link_abbreviation_path(Projects::path(project));

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
build that project.

But the art of leadership is delegation and what //supervisor// then does is to
call //core// back again to do the actual work: see the What To Compile section.
That sounds like an unnecessary round trip, but in fact it's not, because
//supervisor// also incrementally builds some of the resources we will be using.
That business is helpfully invisible to us: so it turns out that CEOs do
something, after all.

@<Build the project@> =
	Supervisor::go_operational();
	if (project) {
		Copies::build(STDOUT, project->as_copy,
			BuildMethodology::stay_in_current_process());
		Time::stop_stopwatch(inform7_timer);
	}

@ Diagnostics files fall into the category of "be careful what you wish for";
they can be rather lengthy.

@<Post mortem logging@> =
	if (problem_count == 0) {
		TemplateReader::report_unacted_upon_interventions();
		if (diagnostics_path) {
			CoreMain::write_diagnostics(
				I"timings-diagnostics.txt", &CoreMain::log_stopwatch);
			CoreMain::write_diagnostics(
				I"memory-diagnostics.txt", &Memory::log_statistics);
			CoreMain::write_diagnostics(
				I"syntax-diagnostics.txt", &CoreMain::log_task_syntax_tree);
			CoreMain::write_diagnostics(
				I"syntax-summary.txt", &CoreMain::log_task_syntax_summary);
			CoreMain::write_diagnostics(
				I"preform-diagnostics.txt", &Instrumentation::log);
			CoreMain::write_diagnostics(
				I"preform-summary.txt", &CoreMain::log_preform_summary);
			CoreMain::write_diagnostics(
				I"documentation-diagnostics.txt", &Index::DocReferences::log_statistics);
			CoreMain::write_diagnostics(
				I"verbs-diagnostics.txt", &NewVerbs::log_all);
			CoreMain::write_diagnostics(
				I"excerpts-diagnostics.txt", &FromLexicon::statistics);
		}
	}

@<Shutdown and rennab@> =
	ProblemBuffer::write_reports(FALSE);
	LOG("Total of %d files written as streams.\n", total_file_writes);
	Writers::log_escape_usage();
	WRITE_TO(STDOUT, "Inform 7 has finished.\n");

@ =
void CoreMain::write_diagnostics(text_stream *leafname, void (*write_fn)(void)) {
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

void CoreMain::log_task_syntax_tree(void) {
	Node::log_tree(DL, Task::syntax_tree()->root_node);
}

void CoreMain::log_preform_summary(void) {
	Instrumentation::log_nt(<s-literal>, TRUE);
}

void CoreMain::log_task_syntax_summary(void) {
	Node::summarise_tree(DL, Task::syntax_tree()->root_node);
}

void CoreMain::log_stopwatch(void) {
	Time::log_timing(inform7_timer, inform7_timer->time_taken);
}

@h Command line processing.
The bulk of the command-line options are both registered and processed by
//supervisor// rather than here: in particular, every switch ever used by the
Inform UI apps is really a command to //supervisor// not to |inform7|.

=
int CoreMain::read_command_line(int argc, char *argv[]) {
	CommandLine::declare_heading(
		L"inform7: a compiler from source text to Inter code\n\n"
		L"Usage: inform7 [OPTIONS]\n");

	@<Register command-line arguments@>;
	Supervisor::declare_options();
	int proceed = CommandLine::read(argc, argv, NULL, &CoreMain::switch, &CoreMain::bareword);
	if (proceed) {
		path_to_inform7 = Pathnames::installation_path("INFORM7_PATH", I"inform7");
		Supervisor::optioneering_complete(NULL, TRUE, &Semantics::read_preform);
	}
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
	CommandLine::end_group();

@ Three of the five options here actually configure the |problems| module
rather than |core|.

=
int show_progress_indicator = TRUE; /* Produce percentage of progress messages */
int do_not_generate_index = FALSE; /* Set by the |-no-index| command line option */
int do_not_update_census = FALSE; /* Set by the |-no-update-census| command line option */

void CoreMain::switch(int id, int val, text_stream *arg, void *state) {
	switch (id) {
		case CRASHALL_CLSW: debugger_mode = val;
			ProblemSigils::crash_on_problems(val); break;
		case INDEX_CLSW: do_not_generate_index = val?FALSE:TRUE; break;
		case CENSUS_UPDATE_CLSW: do_not_update_census = val?FALSE:TRUE; break;
		case PROGRESS_CLSW: show_progress_indicator = val; break;
		case SIGILS_CLSW: ProblemSigils::echo_sigils(val); break;
		case REQUIRE_PROBLEM_CLSW: ProblemSigils::require(arg); break;
		case DIAGNOSTICS_CLSW: diagnostics_path = Pathnames::from_text(arg); break;
	}
	Supervisor::option(id, val, arg, state);
}

void CoreMain::bareword(int id, text_stream *opt, void *state) {
	if (Supervisor::set_I7_source(opt) == FALSE)
		Errors::fatal_with_text("unknown command line argument: %S (see -help)", opt);
}
