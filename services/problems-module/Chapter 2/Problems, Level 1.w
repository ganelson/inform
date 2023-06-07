[ProblemBuffer::] Problems, Level 1.

To render problem messages either as plain text or HTML, and write
them out to files.

@h Buffering.
Only one error text needs to be stored in memory at any one time, so we keep
it in a single text stream:

=
text_stream *PBUFF = NULL;

void ProblemBuffer::clear(void) {
	if (PBUFF == NULL) PBUFF = Str::new();
	else Str::clear(PBUFF);
}

@  Roughly speaking, text for problem messages comes from two possible sources:
fairly short standard texts inside Inform, and quotations (direct or indirect)
from the source text. The latter are inserted by the routines in this section,
and they are the ones we should be wary of, since bizarre input might cause
absurdly long quotations to be made. A quotation involves copying text from
word |w1| to |w2|, so there are two dangers: copying a single very long word,
or copying too many of them. We protect against the first by using the
|%<W| escape, which truncates long literals. We protect against the second
overflow hazard by limiting the amount of text we are prepared to quote from
any sentence in one go:

@d QUOTATION_TOLERANCE_LIMIT 100

=
void ProblemBuffer::copy_text(wording W) {
	W = Wordings::truncate(W, QUOTATION_TOLERANCE_LIMIT);
	WRITE_TO(PBUFF, "%<W", W);
}

@ Diverting source quotes.

=
parse_node *redirected_sentence = NULL;
parse_node *redirected_to_A = NULL, *redirected_to_B = NULL;
void ProblemBuffer::redirect_problem_sentence(parse_node *from,
	parse_node *A, parse_node *B) {
	redirected_sentence = from; redirected_to_A = A; redirected_to_B = B;
}

@ These three special character codes are used as a temporary measure to
mask out angle brackets and quotation marks which we don't want to interpret as HTML:

@d PROTECTED_LT_CHAR L'\x01'
@d PROTECTED_GT_CHAR L'\x02'
@d PROTECTED_QUOT_CHAR L'\x03'

=
void ProblemBuffer::copy_source_reference(wording W) {
	if (Wordings::empty(W)) { WRITE_TO(PBUFF, "<no text>"); return; }
	source_file *referred = Lexer::file_of_origin(Wordings::first_wn(W));
	TEMPORARY_TEXT(file)
	if (referred) {
		WRITE_TO(file, "%f", TextFromFiles::get_filename(referred));
		pathname *proj = HTML::get_link_abbreviation_path();
		if (proj) {
			TEMPORARY_TEXT(project_prefix)
			WRITE_TO(project_prefix, "%p", proj);
			if (Str::prefix_eq(file, project_prefix, Str::len(project_prefix)))
				Str::delete_n_characters(file, Str::len(project_prefix));
		}
	} else {
		WRITE_TO(file, "(no file)");
	}
	WRITE_TO(PBUFF, "'");
	ProblemBuffer::copy_text(W);
	text_stream *paraphrase = file;
	#ifdef DESCRIBE_SOURCE_FILE_PROBLEMS_CALLBACK
	paraphrase = DESCRIBE_SOURCE_FILE_PROBLEMS_CALLBACK(paraphrase, referred, file);
	#endif
	WRITE_TO(PBUFF, "' %c%S%c%S%c%d%c",
		SOURCE_REF_CHAR, paraphrase,
		SOURCE_REF_CHAR, file,
		SOURCE_REF_CHAR, Wordings::location(W).line_number,
		SOURCE_REF_CHAR);
	if ((redirected_sentence) &&
		(redirected_to_A) &&
		(redirected_to_B) &&
		(Wordings::eq(Node::get_text(redirected_sentence), W))) {
		WRITE_TO(PBUFF, " (which asserts that ");
		ProblemBuffer::copy_source_reference(
			Node::get_text(redirected_to_A));
		WRITE_TO(PBUFF, " is/are ");
		ProblemBuffer::copy_source_reference(
			Node::get_text(redirected_to_B));
		WRITE_TO(PBUFF, ")");
	}
	DISCARD_TEXT(file)
}

void ProblemBuffer::copy_file_reference(text_stream *file_ref, int line) {
	TEMPORARY_TEXT(file)
	WRITE_TO(file, "%S", file_ref);
	pathname *proj = HTML::get_link_abbreviation_path();
	if (proj) {
		TEMPORARY_TEXT(project_prefix)
		WRITE_TO(project_prefix, "%p", proj);
		if (Str::prefix_eq(file, project_prefix, Str::len(project_prefix)))
			Str::delete_n_characters(file, Str::len(project_prefix));
		DISCARD_TEXT(project_prefix)
	} else {
		WRITE_TO(file, "(no file)");
	}
	text_stream *paraphrase = file;
	#ifdef DESCRIBE_SOURCE_FILE_PROBLEMS_CALLBACK
	paraphrase = DESCRIBE_SOURCE_FILE_PROBLEMS_CALLBACK(paraphrase, NULL, file);
	#endif
	WRITE_TO(PBUFF, " %c%S%c%S%c%d%c",
		SOURCE_REF_CHAR, paraphrase,
		SOURCE_REF_CHAR, file,
		SOURCE_REF_CHAR, line,
		SOURCE_REF_CHAR);
	DISCARD_TEXT(file)
}

@ Once the error message is fully constructed, we will want to output it
to a file: in fact, by default it will go in three directions, to
|stderr|, to the debugging log and of course to the problems file. The main
thing is to word-wrap it, since it is likely to be a paragraph-sized
chunk of text, not a single line. The unprintable |SOURCE_REF_CHAR| and
|FORCE_NEW_PARA_CHAR| are simply filtered out for plain text output: for
HTML, they are dealt with elsewhere.

@d PROBLEM_WORD_WRAP_WIDTH 80

=
int problem_count_at_last_in = 1;
text_stream problems_file_struct; /* The actual report of Problems file */
text_stream *problems_file = &problems_file_struct; /* As a |text_stream *| */
int problems_file_active = FALSE; /* Currently in use */
int currently_issuing_a_warning = FALSE;

#ifndef PROBLEMS_HTML_EMITTER
#define PROBLEMS_HTML_EMITTER PUT_TO
#endif

void ProblemBuffer::output_problem_buffer_to(OUTPUT_STREAM, int indentation) {
	int line_width = 0, html_flag = FALSE;
	int sig_mode = FALSE, break_width = PROBLEM_WORD_WRAP_WIDTH; filename *fallback = NULL;
	#ifdef FORMAT_CONSOLE_PROBLEMS_CALLBACK
	FORMAT_CONSOLE_PROBLEMS_CALLBACK(&sig_mode, &break_width, &fallback);
	#endif
	if (OUT == problems_file) html_flag = TRUE;
	if (sig_mode == FALSE)
		for (int k=0; k<indentation; k++) { WRITE("  "); line_width+=2; }
	TEMPORARY_TEXT(first)
	TEMPORARY_TEXT(second)
	TEMPORARY_TEXT(third)
	@<Extract details of the first source code reference, if there is one@>;
	for (int i=0, L=Str::len(PBUFF); i<L; i++) {
		int c = Str::get_at(PBUFF, i);
		@<In HTML mode, convert drawing-your-attention arrows@>;
		@<In SIG mode, convert drawing-your-attention arrows@>;
		@<In plain text mode, remove bold and italic HTML tags@>;
		if ((html_flag == FALSE) && (c == SOURCE_REF_CHAR))
			@<Issue plain text paraphrase of source reference@>
		else @<Output single character of problem message@>;
	}
	if (html_flag) HTML_CLOSE("p")
	else WRITE("\n");
	DISCARD_TEXT(first)
	DISCARD_TEXT(second)
	DISCARD_TEXT(third)
}

@ In "silence is golden" mode, we will need a filename and line number to
report at: we pick this out as the first source reference in the message.

@<Extract details of the first source code reference, if there is one@> =
	for (int i=0, f=0, L=Str::len(PBUFF); i<L; i++) {
		int c = Str::get_at(PBUFF, i);
		if (c == SOURCE_REF_CHAR) f++;
		else if (f == 1) PUT_TO(first, c);
		else if (f == 2) PUT_TO(second, c);
		else if (f == 3) PUT_TO(third, c);
	}

@ The plain text "may I draw your attention to the following paragraph"
marker,

|>--> Which looks like this.|

is converted into a suitable CSS-styled HTML paragraph with hanging
indentation. And similarly for |>++>|, used to mark continuations.

@<In HTML mode, convert drawing-your-attention arrows@> =
	if ((html_flag) && (Str::includes_wide_string_at(PBUFF, L">-->", i))) {
		if (problem_count > problem_count_at_last_in) {
			HTML_TAG("hr");
		}
		HTML_OPEN_WITH("p", "class=\"hang\"");
		if (currently_issuing_a_warning) WRITE("<b>Warning.</b> ");
		else WRITE("<b>Problem.</b> ");
		i+=3; continue;
	}
	if (Str::includes_wide_string_at(PBUFF, L">++>", i)) {
		if (html_flag) HTML_OPEN_WITH("p", "class=\"in2\"") else WRITE("  ");
		i+=3; continue;
	}
	if (Str::includes_wide_string_at(PBUFF, L">--->", i)) {
		if (html_flag) {
			HTML_CLOSE("p"); HTML_TAG("hr");
		}
		problem_count_at_last_in = problem_count+1;
		i+=4; continue;
	}
	if (Str::includes_wide_string_at(PBUFF, L">+++>", i)) {
		if (html_flag) HTML_OPEN_WITH("p", "halftightin3\"") else WRITE("  ");
		i+=4; continue;
	}
	if (Str::includes_wide_string_at(PBUFF, L">++++>", i)) {
		if (html_flag) HTML_OPEN_WITH("p", "class=\"tightin3\"") else WRITE("  ");
		i+=5; continue;
	}

@<In SIG mode, convert drawing-your-attention arrows@> =
	if ((sig_mode) && (Str::includes_wide_string_at(PBUFF, L">-->", i))) {
		WRITE("\033[1m");
		if (Str::len(second) > 0) {
			WRITE("%p%S:%S: ", HTML::get_link_abbreviation_path(), second, third);
		} else if (fallback) {
			WRITE("%f:1: ", fallback);
		}
		WRITE("\033[31m");
		WRITE("problem: ");
		WRITE("\033[0m");
		i+=3; continue;
	}

@ The problem messages are put together (by Level 2 below) in a plain text
way, but with a little formatting included: in particular, they contain
HTML-style |<i>|, |<b>| and |<span>| tags, which the following code strips
out when writing to plain text format.

@<In plain text mode, remove bold and italic HTML tags@> =
	if (html_flag == FALSE) {
		if (c == PROTECTED_LT_CHAR) {
			while ((i<L) && (Str::get_at(PBUFF, i) != PROTECTED_GT_CHAR)) i++;
			continue;
		}
		if ((c == '<') &&
				((Str::includes_wide_string_at_insensitive(PBUFF, L"<i>", i)) ||
				(Str::includes_wide_string_at_insensitive(PBUFF, L"<b>", i)) ||
				(Str::includes_wide_string_at_insensitive(PBUFF, L"<img>", i)) ||
				(Str::includes_wide_string_at_insensitive(PBUFF, L"<a>", i)) ||
				(Str::includes_wide_string_at_insensitive(PBUFF, L"<font>", i)) ||
				(Str::includes_wide_string_at_insensitive(PBUFF, L"<i ", i)) ||
				(Str::includes_wide_string_at_insensitive(PBUFF, L"<b ", i)) ||
				(Str::includes_wide_string_at_insensitive(PBUFF, L"<img ", i)) ||
				(Str::includes_wide_string_at_insensitive(PBUFF, L"<a ", i)) ||
				(Str::includes_wide_string_at_insensitive(PBUFF, L"<font ", i)) ||
				(Str::includes_wide_string_at_insensitive(PBUFF, L"<span ", i)) ||
				(Str::includes_wide_string_at_insensitive(PBUFF, L"</i>", i)) ||
				(Str::includes_wide_string_at_insensitive(PBUFF, L"</b>", i)) ||
				(Str::includes_wide_string_at_insensitive(PBUFF, L"</img>", i)) ||
				(Str::includes_wide_string_at_insensitive(PBUFF, L"</a>", i)) ||
				(Str::includes_wide_string_at_insensitive(PBUFF, L"</span>", i)) ||
				(Str::includes_wide_string_at_insensitive(PBUFF, L"</font>", i)))) {
			while ((i<L) && (Str::get_at(PBUFF, i) != '>')) i++;
			continue;
		}
	}

@ Okay, so the format for a source reference here is:
= (text)
	XparaphraseXfilenameXnumberX
=
e.g., |Xmain textXsource/story.niX102|, where |X| is the unprintable
|SOURCE_REF_CHAR|. The counter |i| is at the first |X|, and we must now
convert this to something fit for printing to |stdout|, finishing up with |i|
pointing to the last |X|.

We always use the paraphrase, not the filename, on |stdout| because (i) that's
slightly easier to understand for the user, but more importantly (ii) it
makes the output the same on all platforms when only main text and Standard
Rules are referred to, and that simplifies |intest| and the Test Suite quite
a bit, because we don't have to worry about trivial differences between OS X
and Windows caused by the slashes going the wrong way, and so on.

@<Issue plain text paraphrase of source reference@> =
	WRITE("("); line_width++;
	while (Str::get_at(PBUFF, ++i) != SOURCE_REF_CHAR)
		@<Output single character of problem message@>;
	while (Str::get_at(PBUFF, ++i) != SOURCE_REF_CHAR) ;
	WRITE(", line "); line_width += 7;
	while (Str::get_at(PBUFF, ++i) != SOURCE_REF_CHAR)
		@<Output single character of problem message@>;
	WRITE(")"); line_width++;

@<Output single character of problem message@> =
	c = Str::get_at(PBUFF, i);
	if (Characters::is_whitespace(c)) { /* this starts a run of whitespace */
		int l = i; while (Characters::is_whitespace(Str::get_at(PBUFF, l))) l++;
		if (Str::get_at(PBUFF, l) == 0) break; /* omit any trailing spaces */
		i = l - 1; /* skip to final whitespace character of the run */
		if (html_flag) PROBLEMS_HTML_EMITTER(OUT, ' ');
		else @<In plain text mode, wrap the line or print a space as necessary@>;
	} else {
		line_width++;
		if (c == PROTECTED_LT_CHAR) PUT('<');
		else if (c == PROTECTED_GT_CHAR) PUT('>');
		else if (c == PROTECTED_QUOT_CHAR) PUT('"');
		else if (html_flag) PROBLEMS_HTML_EMITTER(OUT, c);
		else if ((c != SOURCE_REF_CHAR) && (c != FORCE_NEW_PARA_CHAR)) WRITE("%c", c);
	}

@ At this point, |l| is the position of the first non-whitespace character
after the sequence of whitespace.

@<In plain text mode, wrap the line or print a space as necessary@> =
	int word_width = 0;
	while ((!Characters::is_whitespace(Str::get_at(PBUFF, l))) && (Str::get_at(PBUFF, l) != 0)
		&& (Str::get_at(PBUFF, l) != SOURCE_REF_CHAR))
		l++, word_width++;
	if (line_width + word_width + 1 >= break_width) {
		WRITE("\n"); line_width = 0;
		for (l=0; l<indentation+1; l++) { line_width+=2; WRITE("  "); }
	} else {
		WRITE(" "); line_width++;
	}

@ The following allows us to route individual messages to only one output of
our choice.

=
text_stream *redirected_problem_text = NULL; /* Current destination of problem message text */
void ProblemBuffer::redirect_problem_stream(text_stream *S) {
	redirected_problem_text = S;
}

int telemetry_recording = FALSE;

void ProblemBuffer::set_telemetry(void) {
	telemetry_recording = TRUE;
}

void ProblemBuffer::output_problem_buffer(int indentation) {
	if (redirected_problem_text == NULL) {
		ProblemBuffer::output_problem_buffer_to(problems_file, indentation);
		WRITE_TO(problems_file, "\n");
		ProblemBuffer::output_problem_buffer_to(STDERR, indentation);
		STREAM_FLUSH(STDERR);
		WRITE_TO(DL, "\n");
		ProblemBuffer::output_problem_buffer_to(DL, indentation);
		WRITE_TO(DL, "\n");
		if (telemetry_recording) {
			WRITE_TO(telmy, "\n");
			ProblemBuffer::output_problem_buffer_to(telmy, indentation);
			WRITE_TO(telmy, "\n");
		}
	} else ProblemBuffer::output_problem_buffer_to(redirected_problem_text, indentation);
}

@h Problems report and index.
That gives us enough infrastructure to produce the final report. Note the use
of error redirection to in order to put pseudo-problem messages -- actually
informational -- into the report. In the case where the run was successful and
there we no Problem messages, we have to be careful to reset |problem_count|
-- it will have been increased by the issuing of these pseudo-problems, and we
need it to remain 0 so that |main()| can finally return back to the operating
system without an error code.

=
int tail_of_report_written = FALSE;
void ProblemBuffer::write_reports(int disaster_struck) {
	if (tail_of_report_written) return;
	tail_of_report_written = TRUE;

	crash_on_all_problems = FALSE;
	#ifdef INFORMATIONAL_ADDENDA_PROBLEMS_CALLBACK
	int pc = problem_count;
	INFORMATIONAL_ADDENDA_PROBLEMS_CALLBACK(disaster_struck, problem_count);
	problem_count = pc;
	#endif
	if (problems_file_active) {
		#ifdef END_PROBLEM_FILE_PROBLEMS_CALLBACK
		END_PROBLEM_FILE_PROBLEMS_CALLBACK(problems_file);
		#endif
		#ifndef END_PROBLEM_FILE_PROBLEMS_CALLBACK
		HTML::footer(problems_file);
		#endif
	}
}
