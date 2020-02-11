[Problems::Using::] Using Problems.

Interface to the Problems module.

@

@d PROBLEMS_HTML_EMITTER HTMLFiles::char_out

@ Inform tops and tails its output of problem messages, and it also prints
non-problem messages when everything was fine. That all happens here:

@d PROBLEMS_INITIAL_REPORTER Problems::Using::start_problems_report
@d PROBLEMS_FINAL_REPORTER Problems::Using::final_report

=
void Problems::Using::start_problems_report(void) {
	if (STREAM_OPEN_TO_FILE(problems_file, filename_of_report, UTF8_ENC) == FALSE)
		Problems::Fatal::filename_related("Can't open problem log", filename_of_report);
	HTMLFiles::html_header(problems_file, I"Translating the Source");
}

void Problems::Using::final_report(int disaster_struck, int problems_count) {
	int total_words = 0;

	if (problem_count > 0) {
		Problems::Buffer::redirect_problem_stream(problems_file);
		Problems::issue_problem_begin("*");
		if (disaster_struck) @<Issue problem summary for an internal error@>
		else @<Issue problem summary for a run with problem messages@>;
		Problems::issue_problem_end();
		Problems::Buffer::redirect_problem_stream(NULL);
	} else {
		int rooms = 0, things = 0;
		HTMLFiles::html_outcome_image(problems_file, "ni_succeeded", "Succeeded");
		#ifdef IF_MODULE
		PL::Spatial::get_world_size(&rooms, &things);
		#endif
		Problems::quote_number(1, &rooms);
		if (rooms == 1) Problems::quote_text(2, "room"); else Problems::quote_text(2, "rooms");
		Problems::quote_number(3, &things);
		if (things == 1) Problems::quote_text(4, "thing"); else Problems::quote_text(4, "things");
		total_words = TextFromFiles::total_word_count(FIRST_OBJECT(source_file));
		Problems::quote_number(5, &total_words);
		@<Issue problem summaries for a run without problems@>;
	}
}

@ One of the slightly annoying things about internal errors is that Inform's
users persistently refer to them as "crashes" on bug report forms. I mean,
the effort we go to! They are entirely clean exits from the program! The
ingratitude of some -- oh, all right.

@<Issue problem summary for an internal error@> =
	Problems::issue_problem_segment(
		"What has happened here is that one of the checks Inform carries "
		"out internally, to see if it is working properly, has failed. "
		"There must be a bug in this copy of Inform. It may be worth "
		"checking whether you have the current, up-to-date version. "
		"If so, please report this problem via www.inform7.com/bugs. %P"
		"As for fixing your source text to avoid this bug, the last thing "
		"you changed is probably the cause, if there is a simple cause. "
		"Your source text might in fact be wrong, and the problem might be "
		"occurring because Inform has failed to find a good way to say so. "
		"But even if your source text looks correct, there are "
		"probably rephrasings which would achieve the same effect.");

@ Singular and plural versions of the same message, really:

@<Issue problem summary for a run with problem messages@> =
	if (problem_count == 1)
		Problems::issue_problem_segment(
			"Because of this problem, the source could not be translated "
			"into a working game. (Correct the source text to "
			"remove the difficulty and click on Go once again.)");
	else
		Problems::issue_problem_segment(
			"Problems occurring in translation prevented the game "
			"from being properly created. (Correct the source text to "
			"remove these problems and click on Go once again.)");
	HTMLFiles::outcome_image_tail(problems_file);

	text_stream *STATUS = ProgressBar::begin_outcome();
	if (STATUS) {
		WRITE_TO(STATUS, "Translation failed: %d problem%s found",
			problem_count, (problem_count==1)?"":"s");
		ProgressBar::end_outcome();
	}

@ The success message needs to take different forms in |stdout| and in
the Problems log file. In the latter, we write as though the subsequent
conversion of Inform's output to a story file via Inform 6 had already been
completed successfully -- this is because the Problems log is intended
to be viewed inside the Inform application, which will instead divert to
an error page if I6 should fail. So although the Problems file contains
an unwarranted claim, if not an actual falsehood, no human eye should see
it unless and until it comes true.

We don't want to make similar claims on |stdout|, where the user -- who
might well not be running in the Inform application, but only on the
command line -- deserves the truth.

@<Issue problem summaries for a run without problems@> =
	Problems::Buffer::redirect_problem_stream(problems_file);
	text_stream *OUT = problems_file;
	HTML_OPEN("p");
	Problems::issue_problem_begin("**");
	Problems::issue_problem_segment(
		"The %5-word source text has successfully been translated "
		"into a world with %1 %2 and %3 %4, and the index has been "
		"brought up to date.");
	Problems::issue_problem_end();
	HTMLFiles::outcome_image_tail(problems_file);

	if (telemetry_recording) {
		Telemetry::ensure_telemetry_file();
		Problems::Buffer::redirect_problem_stream(telmy);
		Problems::issue_problem_begin("**");
		Problems::issue_problem_segment(
			"The %5-word source text has successfully been translated "
			"into a world with %1 %2 and %3 %4, and the index has been "
			"brought up to date.");
		Problems::issue_problem_end();
		WRITE_TO(telmy, "\n");
	}
	Problems::Buffer::redirect_problem_stream(STDOUT);
	WRITE_TO(STDOUT, "\n");
	Problems::issue_problem_begin("**");
	Problems::issue_problem_segment(
		"The %5-word source text has successfully been translated "
		"into an intermediate description which can be run through "
		"Inform 6 to complete compilation. There were %1 %2 and %3 %4.");
	Problems::issue_problem_end();
	STREAM_FLUSH(STDOUT);
	Problems::Buffer::redirect_problem_stream(NULL);

	ProgressBar::final_state_of_progress_bar();
	text_stream *STATUS = ProgressBar::begin_outcome();
	if (STATUS) {
		WRITE_TO(STATUS, "Translation succeeded: %d room%s, %d thing%s",
			rooms, (rooms==1)?"":"s",
			things, (things==1)?"":"s");
		ProgressBar::end_outcome();
	}
