[UsingProblems::] Using Problems.

Interface to the Problems module.

@

@d PROBLEMS_HTML_EMITTER HTML::put

@ In "silence-is-golden" mode, we want our Problem messages to look more like
traditional Unix errors, even if they're long ones:

@d FORMAT_CONSOLE_PROBLEMS_CALLBACK UsingProblems::console_format

=
void UsingProblems::console_format(int *sig_mode, int *break_width, filename **fallback) {
	if (Main::silence_is_golden()) {
		*sig_mode = TRUE;
		*break_width = 10000000; /* i.e., do not word-wrap problem messages at all */
		if ((inform7_task) && (inform7_task->project))
			*fallback = Projects::get_primary_source(inform7_task->project);
	}
}

@ Inform tops and tails its output of problem messages, and it also prints
non-problem messages when everything was fine. That all happens here:

@d START_PROBLEM_FILE_PROBLEMS_CALLBACK UsingProblems::start_problems_report
@d END_PROBLEM_FILE_PROBLEMS_CALLBACK UsingProblems::end_problems_report
@d INFORMATIONAL_ADDENDA_PROBLEMS_CALLBACK UsingProblems::final_report

=
void UsingProblems::start_problems_report(filename *F, text_stream *P) {
	if (STREAM_OPEN_TO_FILE(P, F, UTF8_ENC) == FALSE)
		Problems::fatal_on_file("Can't open problem log", F);
	InformPages::header(P, I"Translating the Source", JAVASCRIPT_FOR_STANDARD_PAGES_IRES, NULL);
}

void UsingProblems::end_problems_report(OUTPUT_STREAM) {
	InformPages::footer(OUT);
}

void UsingProblems::final_report(int disaster_struck, int problems_count) {
	int total_words = 0;

	if (problem_count > 0) {
		if (problems_file_active) ProblemBuffer::redirect_problem_stream(problems_file);
		Problems::issue_problem_begin(Task::syntax_tree(), "*");
		if (disaster_struck) @<Issue problem summary for an internal error@>
		else @<Issue problem summary for a run with problem messages@>;
		Problems::issue_problem_end();
		if (problems_file_active) ProblemBuffer::redirect_problem_stream(NULL);
	} else {
		int rooms = 0, things = 0;
		if ((problems_file_active) && (Problems::warnings_occurred() == FALSE))
			UsingProblems::html_outcome_image(problems_file, "ni_succeeded", "Succeeded");
		#ifdef IF_MODULE
		Spatial::get_world_size(&rooms, &things);
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
the effort we go to! These are entirely clean exits from the program! The
ingratitude of some -- oh, all right.

@<Issue problem summary for an internal error@> =
	Sequence::backtrace(); /* to the debugging log */
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
	UsingProblems::outcome_image_tail(problems_file);

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
	ProblemBuffer::redirect_problem_stream(problems_file);
	text_stream *OUT = problems_file;
	HTML_OPEN("p");
	
	if (Problems::warnings_occurred()) {
		Problems::issue_problem_begin(Task::syntax_tree(), "**");
		Problems::issue_problem_segment(
			"Although one or more warnings were issued, there were no problems "
			"serious enough to stop translation from going ahead.");
		Problems::issue_problem_end();
	}
	
	Problems::issue_problem_begin(Task::syntax_tree(), "**");
	Problems::issue_problem_segment(
		"The %5-word source text has successfully been translated "
		"into a world with %1 %2 and %3 %4, and the index has been "
		"brought up to date.");
	Problems::issue_problem_end();
	UsingProblems::outcome_image_tail(problems_file);
	HTML_CLOSE("p");

	if (telemetry_recording) {
		Telemetry::ensure_telemetry_file();
		ProblemBuffer::redirect_problem_stream(telmy);
		Problems::issue_problem_begin(Task::syntax_tree(), "**");
		Problems::issue_problem_segment(
			"The %5-word source text has successfully been translated "
			"into a world with %1 %2 and %3 %4, and the index has been "
			"brought up to date.");
		Problems::issue_problem_end();
		WRITE_TO(telmy, "\n");
	}
	ProblemBuffer::redirect_problem_stream(STDOUT);
	WRITE_TO(STDOUT, "\n");
	Problems::issue_problem_begin(Task::syntax_tree(), "**");
	Problems::issue_problem_segment(
		"The %5-word source text has successfully been translated. "
		"There were %1 %2 and %3 %4.");
	Problems::issue_problem_end();
	STREAM_FLUSH(STDOUT);
	ProblemBuffer::redirect_problem_stream(NULL);

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

@d FIRST_PROBLEMS_CALLBACK UsingProblems::html_outcome_failed

=
void UsingProblems::html_outcome_failed(OUTPUT_STREAM) {
	if (StandardProblems::internal_errors_have_occurred())
		UsingProblems::html_outcome_image(problems_file, "ni_failed_badly", "Failed");
	else
		UsingProblems::html_outcome_image(problems_file, "ni_failed", "Problems or Warnings");
}

void UsingProblems::html_outcome_image(OUTPUT_STREAM, char *image, char *verdict) {
	char *vn = "";
	int be_festive = TRUE;
	if (StandardProblems::internal_errors_have_occurred() == FALSE) be_festive = FALSE;
	if (be_festive) {
		switch (Time::feast()) {
			case CHRISTMAS_FEAST: vn = "_2"; break;
			case EASTER_FEAST: vn = "_3"; break;
		}
		if (vn[0]) outcome_image_style = CENTRED_OUTCOME_IMAGE_STYLE;
	}
	StandardProblems::issue_problems_banner(OUT, verdict);
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

void UsingProblems::outcome_image_tail(OUTPUT_STREAM) {
	if (problems_file_active)
		if (outcome_image_style == SIDE_OUTCOME_IMAGE_STYLE) {
			HTML::comment(OUT, I"PROBLEMS END");
			HTML::end_html_row(OUT);
			HTML::end_html_table(OUT);
			HTML::comment(OUT, I"FOOTNOTE");
		}
}

@ This is a more elaborate form of the standard |StandardProblems::sentence_problem|,
used when an assertion sentence has gone wrong. Experience from the early
builds of the Public Beta showed that many people tried syntaxes which
Inform did not recognise, and which cause Inform to misread the primary
verb of the sentence. It would then issue a Problem -- because the sentence
would be peculiar -- but this problem report would itself be odd, and
make little sense to the user. So we look to see if the current sentence
is an assertion with a primary verb: and if it is, we hunt through it
for alternative verbs which might have been intended, and try to produce
a message which diagnoses the problem rather better.

=
void UsingProblems::assertion_problem(parse_node_tree *T, SIGIL_ARGUMENTS,
	char *message, char *explanation) {
	wording RTW = EMPTY_WORDING; /* "rather than" text */
	ACT_ON_SIGIL
	if ((current_sentence == NULL) || (current_sentence->down == NULL) ||
		(Node::get_type(current_sentence->down) != VERB_NT)) {
		LOG("(Assertion error reverting to sentence error.)\n");
		StandardProblems::sentence_problem(T, PASS_SIGIL, message, explanation);
		return;
	}

	LOG("(Assertion error: looking for alternative verbs in <%W>.)\n",
		Node::get_text(current_sentence));
	wording AW = Wordings::trim_both_ends(Node::get_text(current_sentence));
	LOOP_THROUGH_WORDING(i, AW)
		if ((i != Wordings::first_wn(Node::get_text(current_sentence->down))) &&
			(Word::unexpectedly_upper_case(i) == FALSE)) {
			wording W = Wordings::from(Node::get_text(current_sentence), i);
			int j = <nonimperative-verb>(W);
			if (j > 0) RTW = Wordings::new(i, j);
		}
	Problems::quote_source(1, current_sentence);
	Problems::quote_text(2, message);
	Problems::quote_text(3, explanation);
	Problems::issue_problem_begin(T, explanation);
	Problems::issue_problem_segment("You wrote %1: %Sagain, %2.%Lbut %2, %3");
	if (Wordings::nonempty(RTW)) {
		Problems::quote_wording(4, Node::get_text(current_sentence->down));
		Problems::quote_wording(5, RTW);
		Problems::issue_problem_segment( /* see also PM_AmbiguousVerb */
			" %P(It may help to know that I am reading the primary verb here "
			"as '%4', not '%5'.)");
	}
	UsingProblems::diagnose_further();
	Problems::issue_problem_end();
}

void UsingProblems::diagnose_further(void) {
	if (current_sentence == NULL) return;
	if (Wordings::empty(Node::get_text(current_sentence))) return;
	int sqc = 0;
	LOOP_THROUGH_WORDING(i, Node::get_text(current_sentence))
		sqc += Word::singly_quoted(i);
	if (sqc >= 2)
		Problems::issue_problem_segment(
			" %P(I notice what look like single quotation marks in this "
			"sentence. If you meant to write some quoted text, it needs to "
			"be in double quotes, \"like this\" and not 'like this'.)");

	control_structure_phrase *csp =
		ControlStructures::detect(Node::get_text(current_sentence));
	if (csp)
		Problems::issue_problem_segment(
			" %P(The way this sentence starts makes me think it might have been "
			"intended as part of a rule rather than being a statement about the "
			"the way things are at the beginning of play. For example, 'If the "
			"player is in the Penalty Zone, say \"An alarm sounds.\" is not "
			"allowed: it has to be put in the form of a rule showing Inform "
			"what circumstances apply - for example 'Every turn: if the player is "
			"in the Penalty Zone, say \"An alarm sounds.\")");
}
