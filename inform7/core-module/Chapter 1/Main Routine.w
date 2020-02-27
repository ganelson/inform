[CoreMain::] Main Routine.

As with all C programs, Inform begins execution in a |main| routine,
reading command-line arguments to modify its behaviour.

@ =
time_t right_now;
pathname *path_to_inform7 = NULL;

int CoreMain::main(int argc, char *argv[]) {
	@<Banner and startup@>;
	int proceed = CoreMain::read_command_line(argc, argv);
	if (proceed) {
		@<Open the debugging log and the problems report@>;
		@<Name the telemetry@>;
		inform_project *project = Inbuild::go_operational();
		if (project)
			Copies::build(STDOUT, project->as_copy,
				BuildMethodology::new(NULL, FALSE, INTERNAL_METHODOLOGY));
	}
	@<Post mortem logging@>;
	if (proceed) @<Shutdown and rennab@>;
	if (problem_count > 0) Problems::Fatal::exit(1);
	return 0;
}

@ It is the dawn of time...

@<Banner and startup@> =
	Errors::set_internal_handler(&Problems::Issue::internal_error_fn);
	PRINT("%B build %B has started.\n", FALSE, TRUE);

@<Open the debugging log and the problems report@> =
	pathname *build_folder = Projects::build_pathname(Inbuild::project());
	if (Pathnames::create_in_file_system(build_folder) == 0)
		Problems::Fatal::issue("Unable to create Build folder for project: is it read-only?");

	filename *DF = Filenames::in_folder(build_folder, I"Debug log.txt");
	Log::set_debug_log_filename(DF);
	Log::open();
	LOG("inform7 was called as:");
	for (int i=0; i<argc; i++) LOG(" %s", argv[i]);
	LOG("\n");
	CommandLine::play_back_log();

	filename *PF = Filenames::in_folder(build_folder, I"Problems.html");
	Problems::Issue::start_problems_report(PF);

@ Telemetry is not as sinister as it sounds: the app isn't sending data out
on the Internet, only (if requested) logging what it's doing to a local file.
This was provided for classroom use, so that teachers can see what their
students have been getting stuck on.

@<Name the telemetry@> =
	pathname *P = Pathnames::subfolder(Inbuild::transient(), I"Telemetry");
	if (Pathnames::create_in_file_system(P)) {
		TEMPORARY_TEXT(leafname_of_telemetry);
		int this_month = the_present->tm_mon + 1;
		int this_day = the_present->tm_mday;
		int this_year = the_present->tm_year + 1900;
		WRITE_TO(leafname_of_telemetry,
			"Telemetry %04d-%02d-%02d.txt", this_year, this_month, this_day);
		filename *F = Filenames::in_folder(P, leafname_of_telemetry);
		Telemetry::locate_telemetry_file(F);
		DISCARD_TEXT(leafname_of_telemetry);
	}

@<Post mortem logging@> =
	if (problem_count == 0) {
		TemplateReader::report_unacted_upon_interventions();
		//	ParseTreeUsage::write_main_source_to_log();
		//	Memory::log_statistics();
		//	Preform::log_language();
		//	Index::DocReferences::log_statistics();
		//	NewVerbs::log_all();
	}

@<Shutdown and rennab@> =
	Problems::write_reports(FALSE);
	LOG("Total of %d files written as streams.\n", total_file_writes);
	Writers::log_escape_usage();
	WRITE_TO(STDOUT, "%s has finished.\n", HUMAN_READABLE_INTOOL_NAME);

@h Command Line.

=
int CoreMain::read_command_line(int argc, char *argv[]) {
	@<Register command-line arguments@>;
	int proceed = CommandLine::read(argc, argv, NULL, &CoreMain::switch, &CoreMain::bareword);
	if (proceed) {
		path_to_inform7 = Pathnames::installation_path("INFORM7_PATH", I"inform7");
		Inbuild::optioneering_complete(NULL, TRUE);
	}
	return proceed;
}

@ Note that the locations manager is also allowed to process command-line
arguments in order to set certain pathnames or filenames, so the following
list is not exhaustive.

@e INFORM_TESTING_CLSG

@e CRASHALL_CLSW
@e INDEX_CLSW
@e PROGRESS_CLSW
@e REQUIRE_PROBLEM_CLSW
@e SIGILS_CLSW

@<Register command-line arguments@> =
	CommandLine::declare_heading(
		L"inform7: a compiler from source text to Inform 6 code\n\n"
		L"Usage: inform7 [OPTIONS] [SOURCETEXT]\n");

	CommandLine::begin_group(INFORM_TESTING_CLSG, I"for testing and debugging inform7");
	CommandLine::declare_boolean_switch(CRASHALL_CLSW, L"crash-all", 1,
		L"intentionally crash on Problem messages, for debugger backtracing", FALSE);
	CommandLine::declare_boolean_switch(INDEX_CLSW, L"index", 1,
		L"produce an Index", TRUE);
	CommandLine::declare_boolean_switch(PROGRESS_CLSW, L"progress", 1,
		L"display progress percentages", TRUE);
	CommandLine::declare_boolean_switch(SIGILS_CLSW, L"sigils", 1,
		L"print Problem message sigils", FALSE);
	CommandLine::declare_switch(REQUIRE_PROBLEM_CLSW, L"require-problem", 2,
		L"return 0 unless exactly this Problem message is generated");
	CommandLine::end_group();
	Inbuild::declare_options();

@ =
int show_progress_indicator = TRUE; /* Produce percentage of progress messages */
int do_not_generate_index = FALSE; /* Set by the |-noindex| command line option */

void CoreMain::switch(int id, int val, text_stream *arg, void *state) {
	switch (id) {
		case CRASHALL_CLSW: debugger_mode = val; crash_on_all_errors = val; break;
		case INDEX_CLSW: do_not_generate_index = val?FALSE:TRUE; break;
		case PROGRESS_CLSW: show_progress_indicator = val; break;
		case SIGILS_CLSW: echo_problem_message_sigils = val; break;
		case REQUIRE_PROBLEM_CLSW: Problems::Fatal::require(arg); break;
	}
	Inbuild::option(id, val, arg, state);
}

void CoreMain::bareword(int id, text_stream *opt, void *state) {
	if (Inbuild::set_I7_source(opt) == FALSE)
		Errors::fatal_with_text("unknown command line argument: %S (see -help)", opt);
}
