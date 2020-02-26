[CoreMain::] Main Routine.

As with all C programs, Inform begins execution in a |main| routine,
reading command-line arguments to modify its behaviour.

@h Flags.
These are not all of the options, because Inform shares a whole range of
options with inbuild: see that module for more.

=
int existing_story_file = FALSE; /* Ignore source text to blorb existing story file? */
int show_progress_indicator = TRUE; /* Produce percentage of progress messages */
int scoring_option_set = NOT_APPLICABLE; /* Whether in this case a score is kept at run time */
int do_not_generate_index = FALSE; /* Set by the |-noindex| command line option */

@ This flag is set by the use option "Use no deprecated features", and makes
Inform strict in rejecting syntaxes we intend to get rid of later on.

=
int no_deprecated_features = FALSE; /* forbid syntaxes marked as deprecated? */

@ Broadly speaking, what Inform does can be divided into two halves: in
the first half, it reads all the assertions, makes all the objects and
global variables and constructs the model world; in the second half,
it compiles the phrases and grammar to go with it.
|model_world_constructed| records which of these halves we are
currently in: |FALSE| in the first half, |TRUE| in the second.

=
int text_loaded_from_source = FALSE; /* Lexical scanning is done */
int model_world_under_construction = FALSE; /* World model is being constructed */
int model_world_constructed = FALSE; /* World model is now constructed */

@ =
time_t right_now;
pathname *path_to_inform7 = NULL;

int CoreMain::main(int argc, char *argv[]) {
	@<Banner and startup@>;
	int proceed = CoreMain::read_command_line(argc, argv);
	if (proceed) {
		@<Open the debugging log and the problems report@>;
		@<Open the telemetry@>;
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
	STREAM_FLUSH(STDOUT);

@<Open the debugging log and the problems report@> =
	filename *DF, *PF;
	inform_project *project = Inbuild::project();
	if (project) {
		pathname *build_folder = Pathnames::subfolder(Projects::path(project), I"Build");
		if (Pathnames::create_in_file_system(build_folder) == 0)
			Problems::Fatal::issue("Unable to create Build folder for project: is it read-only?");
		DF = Filenames::in_folder(build_folder, I"Debug log.txt");
		PF = Filenames::in_folder(build_folder, I"Problems.html");
	} else {
		pathname *transient_folder = Inbuild::transient();
		DF = Filenames::in_folder(transient_folder, I"Debug log.txt");
		PF = Filenames::in_folder(transient_folder, I"Problems.html");
	}
	Log::set_debug_log_filename(DF);
	Log::open();
	LOG("inform7 was called as:");
	for (int i=0; i<argc; i++) LOG(" %s", argv[i]);
	LOG("\n");
	CommandLine::play_back_log();

	Problems::Issue::start_problems_report(PF);

@ Telemetry is not as sinister as it sounds: the app isn't sending data out
on the Internet, only (if requested) logging what it's doing to a local file.
This was provided for classroom use, so that teachers can see what their
students have been getting stuck on.

@<Open the telemetry@> =
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
//		ParseTreeUsage::write_main_source_to_log();
//		Memory::log_statistics();
//		Preform::log_language();
//		Index::DocReferences::log_statistics();
//		NewVerbs::log_all();
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

@e CRASHALL_CLSW
@e NOINDEX_CLSW
@e NOPROGRESS_CLSW
@e REQUIRE_PROBLEM_CLSW
@e SIGILS_CLSW

@<Register command-line arguments@> =
	CommandLine::declare_heading(
		L"inform7: a compiler from source text to Inform 6 code\n\n"
		L"Usage: inform7 [OPTIONS] [SOURCETEXT]\n");

	CommandLine::declare_boolean_switch(CRASHALL_CLSW, L"crash-all", 1,
		L"crash intentionally on Problem messages (for debugger backtraces)");
	CommandLine::declare_boolean_switch(NOINDEX_CLSW, L"noindex", 1,
		L"don't produce an Index");
	CommandLine::declare_boolean_switch(NOPROGRESS_CLSW, L"noprogress", 1,
		L"don't display progress percentages");
	CommandLine::declare_boolean_switch(SIGILS_CLSW, L"sigils", 1,
		L"print Problem message sigils (for testing)");
	CommandLine::declare_switch(REQUIRE_PROBLEM_CLSW, L"require-problem", 2,
		L"return 0 unless exactly this Problem message is generated (for testing)");
	Inbuild::declare_options();

@=
void CoreMain::switch(int id, int val, text_stream *arg, void *state) {
	switch (id) {
		case CRASHALL_CLSW: debugger_mode = val; crash_on_all_errors = val; break;
		case NOINDEX_CLSW: do_not_generate_index = val; break;
		case NOPROGRESS_CLSW: show_progress_indicator = val?FALSE:TRUE; break;
		case SIGILS_CLSW: echo_problem_message_sigils = val; break;
		case REQUIRE_PROBLEM_CLSW: Problems::Fatal::require(arg); break;
	}
	Inbuild::option(id, val, arg, state);
}

void CoreMain::bareword(int id, text_stream *opt, void *state) {
	if (Inbuild::set_I7_source(opt) == FALSE)
		Errors::fatal_with_text("unknown command line argument: %S (see -help)", opt);
}

void CoreMain::set_inter_pipeline(wording W) {
	inter_processing_pipeline = Str::new();
	WRITE_TO(inter_processing_pipeline, "%W", W);
	Str::delete_first_character(inter_processing_pipeline);
	Str::delete_last_character(inter_processing_pipeline);
	LOG("Setting pipeline %S\n", inter_processing_pipeline);
}
