[Problems::Using::] Using Problems.

Interface to the Problems module.

@

@d PROBLEMS_HTML_EMITTER HTML::put

@ Inform tops and tails its output of problem messages, and it also prints
non-problem messages when everything was fine. That all happens here:

@d PROBLEMS_INITIAL_REPORTER Problems::Using::start_problems_report
@d PROBLEMS_FINAL_REPORTER Problems::Using::final_report

=
void Problems::Using::start_problems_report(filename *F) {
	if (STREAM_OPEN_TO_FILE(problems_file, F, UTF8_ENC) == FALSE)
		Problems::Fatal::filename_related("Can't open problem log", F);
	HTML::header(problems_file, I"Translating the Source",
		Supervisor::file_from_installation(CSS_FOR_STANDARD_PAGES_IRES),
		Supervisor::file_from_installation(JAVASCRIPT_FOR_STANDARD_PAGES_IRES));
}

void Problems::Using::final_report(int disaster_struck, int problems_count) {
	int total_words = 0;

	if (problem_count > 0) {
		Problems::Buffer::redirect_problem_stream(problems_file);
		Problems::issue_problem_begin(Task::syntax_tree(), "*");
		if (disaster_struck) @<Issue problem summary for an internal error@>
		else @<Issue problem summary for a run with problem messages@>;
		Problems::issue_problem_end();
		Problems::Buffer::redirect_problem_stream(NULL);
	} else {
		int rooms = 0, things = 0;
		Problems::Using::html_outcome_image(problems_file, "ni_succeeded", "Succeeded");
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
	Problems::Using::outcome_image_tail(problems_file);

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
	Problems::issue_problem_begin(Task::syntax_tree(), "**");
	Problems::issue_problem_segment(
		"The %5-word source text has successfully been translated "
		"into a world with %1 %2 and %3 %4, and the index has been "
		"brought up to date.");
	Problems::issue_problem_end();
	Problems::Using::outcome_image_tail(problems_file);

	if (telemetry_recording) {
		Telemetry::ensure_telemetry_file();
		Problems::Buffer::redirect_problem_stream(telmy);
		Problems::issue_problem_begin(Task::syntax_tree(), "**");
		Problems::issue_problem_segment(
			"The %5-word source text has successfully been translated "
			"into a world with %1 %2 and %3 %4, and the index has been "
			"brought up to date.");
		Problems::issue_problem_end();
		WRITE_TO(telmy, "\n");
	}
	Problems::Buffer::redirect_problem_stream(STDOUT);
	WRITE_TO(STDOUT, "\n");
	Problems::issue_problem_begin(Task::syntax_tree(), "**");
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

@h Outcome images.
These are the two images used on the Problems page to visually indicate
success or failure. We also use special images on special occasions.

@d CENTRED_OUTCOME_IMAGE_STYLE 1
@d SIDE_OUTCOME_IMAGE_STYLE 2

=
int outcome_image_style = SIDE_OUTCOME_IMAGE_STYLE;

@ This callback function is called just as the //problems// module is about
to issue its first problem of the run:

@d FIRST_PROBLEM_CALLBACK Problems::Using::html_outcome_failed

=
void Problems::Using::html_outcome_failed(OUTPUT_STREAM) {
	if (Problems::Issue::internal_errors_have_occurred())
		Problems::Using::html_outcome_image(problems_file, "ni_failed_badly", "Failed");
	else
		Problems::Using::html_outcome_image(problems_file, "ni_failed", "Failed");
}

void Problems::Using::html_outcome_image(OUTPUT_STREAM, char *image, char *verdict) {
	char *vn = "";
	int be_festive = TRUE;
	if (Problems::Issue::internal_errors_have_occurred() == FALSE) be_festive = FALSE;
	if (be_festive) {
		switch (Time::feast()) {
			case CHRISTMAS_FEAST: vn = "_2"; break;
			case EASTER_FEAST: vn = "_3"; break;
		}
		if (vn[0]) outcome_image_style = CENTRED_OUTCOME_IMAGE_STYLE;
	}
	Problems::Issue::issue_problems_banner(OUT, verdict);
	switch (outcome_image_style) {
		case CENTRED_OUTCOME_IMAGE_STYLE:
			HTML_OPEN("p");
			HTML_OPEN("center");
			HTML_TAG_WITH("img", "src=inform:/outcome_images/%s%s.png border=0", image, vn);
			HTML_CLOSE("center");
			HTML_CLOSE("p");
			break;
		case SIDE_OUTCOME_IMAGE_STYLE:
			HTML::begin_html_table(OUT, NULL, TRUE, 0, 4, 0, 0, 0);
			HTML::first_html_column(OUT, 110);
			HTML_TAG_WITH("img",
				"src=inform:/outcome_images/%s%s@2x.png border=1 width=100 height=100", image, vn);
			HTML::next_html_column(OUT, 0);
			break;
	}
	HTML::comment(OUT, I"HEADNOTE");
	HTML_OPEN_WITH("p", "style=\"margin-top:0;\"");
	WRITE("(Each time <b>Go</b> or <b>Replay</b> is clicked, Inform tries to "
		"translate the source text into a working story, and updates this report.)");
	HTML_CLOSE("p");
	HTML::comment(OUT, I"PROBLEMS BEGIN");
}

void Problems::Using::outcome_image_tail(OUTPUT_STREAM) {
	if (outcome_image_style == SIDE_OUTCOME_IMAGE_STYLE) {
		HTML::comment(OUT, I"PROBLEMS END");
		HTML::end_html_row(OUT);
		HTML::end_html_table(OUT);
		HTML::comment(OUT, I"FOOTNOTE");
	}
}
