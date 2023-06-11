[StandardProblems::] Problems, Level 3.

Here we provide some convenient semi-standardised problem messages,
which also serve as examples of how to use the Level 2 problem message
routines.

@ Internal errors are essentially failed assertions, and they should never
occur, whatever the provocation: if they do, they are symptoms of a bug.

=
int internal_error_thrown = FALSE;
int StandardProblems::internal_errors_have_occurred(void) {
	return internal_error_thrown;
}

@ The internal error "functions" used by the rest of Inform are in fact macros,
in order that they can supply the current filename and line number
automatically to the actual internal error functions. The result is, for
instance,
= (text as ConsoleText)
>--> Problem. An internal error has occurred: Unknown verb code. The current
  sentence is "A room is a kind"; the error was detected at line 133 of
  "Chapter 5/Traverse for Objects.w". This should never happen, and I am
  now halting in abject failure.
=

@d internal_error_tree_unsafe(X)
	StandardProblems::internal_error_tu_fn(NULL, X, __FILE__, __LINE__)
@d internal_error_if_node_type_wrong(T, X, Y)
	StandardProblems::nodal_check(T, X, Y, __FILE__, __LINE__)
@d internal_error_on_node_type(X)
	StandardProblems::internal_error_on_node_type_fn(NULL, X, __FILE__, __LINE__)

@ Internal errors are generated much like any other problem message, except
that we use a variant form of the "end" routine which salvages what it can
from the wreckage, then either forces a crash (to make the stack backtrace
visible in a debugger) or simply exits to the operating system with error
code 1:

=
void StandardProblems::internal_error_end(void) {
	Problems::issue_problem_end();
	ProblemBuffer::write_reports(TRUE);
	if (debugger_mode) ProblemSigils::force_crash();
	ProblemSigils::exit(1);
}

@ And now for the functions which the above macros invoke. There are two
versions: one which cites the current sentence, and another which doesn't,
for use if either there is no current sentence (because Inform wasn't traversing
the parse tree at the time) or if the parse tree is unsafe -- it's possible
that the internal error occurred during parse tree construction, so we need
to be cautious.

=
void StandardProblems::internal_error_fn(void *T, char *p,
	char *filename, int linenum) {
	internal_error_thrown = TRUE;
	if (current_sentence == NULL) {
		StandardProblems::internal_error_tu_fn(T, p, filename, linenum);
		return;
	}
	Problems::quote_source(1, current_sentence);
	Problems::quote_text(2, p);
	Problems::quote_text(3, filename);
	Problems::quote_number(4, &linenum);
	Problems::issue_problem_begin(T, p);
	Problems::issue_problem_segment(
		"An internal error has occurred: %2. The current sentence is %1; the "
		"error was detected at line %4 of \"%3\". This should never happen, "
		"and I am now halting in abject failure.");
	StandardProblems::internal_error_end();
}

@ This second sort of internal error comes in two sub-versions, one using
a |char *|, one a |text_stream *|.

=
void StandardProblems::internal_error_tu_fn(void *T, char *p,
	char *filename, int linenum) {
	internal_error_thrown = TRUE;
	Problems::quote_text(1, p);
	Problems::quote_text(2, filename);
	Problems::quote_number(3, &linenum);
	Problems::issue_problem_begin(T, p);
	Problems::issue_problem_segment(
		"An internal error has occurred: %1. The error was detected at "
		"line %3 of \"%2\". This should never happen, and I am now halting "
		"in abject failure.");
	StandardProblems::internal_error_end();
}

void StandardProblems::internal_error_tu_fn_S(void *T, text_stream *p,
	char *filename, int linenum) {
	internal_error_thrown = TRUE;
	Problems::quote_stream(1, p);
	Problems::quote_text(2, filename);
	Problems::quote_number(3, &linenum);
	Problems::issue_problem_begin(T, "");
	Problems::issue_problem_segment(
		"An internal error has occurred: %1. The error was detected at "
		"line %3 of \"%2\". This should never happen, and I am now halting "
		"in abject failure.");
	StandardProblems::internal_error_end();
}

@h Nodal errors.
Very many routines are designed to work only on nodes within the parse
tree of a particular node type. If Inform is in working order, then they will
never be called at any other nodes; but it seems best to check this. Any
failure of such an invariant produces a form of internal error called a
"nodal error".

=
void StandardProblems::nodal_error_fn(parse_node_tree *T, parse_node *pn, char *p,
	char *filename, int linenum) {
	LOG("Internal nodal error at:\n");
	LOG("$T\n", pn);
	StandardProblems::internal_error_fn(T, p, filename, linenum);
}

void StandardProblems::nodal_error_fn_S(parse_node_tree *T, parse_node *pn,
	text_stream *p, char *filename, int linenum) {
	LOG("Internal nodal error at:\n");
	LOG("$T\n", pn);
	StandardProblems::internal_error_tu_fn_S(T, p, filename, linenum);
}

@ Here is a convenient function to check said invariant.

=
void StandardProblems::nodal_check(parse_node_tree *T, parse_node *pn,
	node_type_t node_type_required, char *filename, int linenum) {
	if (pn == NULL) {
		TEMPORARY_TEXT(internal_message)
		WRITE_TO(internal_message, "NULL node found where type %S expected",
			NodeType::get_name(node_type_required));
		StandardProblems::internal_error_tu_fn_S(T, internal_message, filename, linenum);
		DISCARD_TEXT(internal_message)
	} else if (Node::get_type(pn) != node_type_required) {
		TEMPORARY_TEXT(internal_message)
		WRITE_TO(internal_message, "Node of type %S found where type %S expected",
			NodeType::get_name(Node::get_type(pn)),
			NodeType::get_name(node_type_required));
		StandardProblems::nodal_error_fn_S(T, pn, internal_message, filename, linenum);
		DISCARD_TEXT(internal_message)
	}
}

@ Nodal errors also turn up as the default clauses in switch statements which
act on various selections of node types, and those use the |internal_error_on_node_type|
macro, which invokes the following:

=
void StandardProblems::internal_error_on_node_type_fn(parse_node_tree *T,
	parse_node *pn, char *filename, int linenum) {
	TEMPORARY_TEXT(internal_message)
	if (pn == NULL)
		StandardProblems::internal_error_tu_fn(T, "Unexpected NULL node found",
			filename, linenum);
	WRITE_TO(internal_message, "Unexpectedly found node of type %S",
		NodeType::get_name(Node::get_type(pn)));
	StandardProblems::nodal_error_fn_S(T, pn, internal_message, filename, linenum);
	DISCARD_TEXT(internal_message)
}

@ The following routines are relics of an era of horrific, primordial upheaval,
when the S-parser was being debugged. An S-subtree is a portion of the parse
tree which represents a proposition.

=
parse_node *latest_s_subtree = NULL;
void StandardProblems::s_subtree_error_set_position(parse_node_tree *T, parse_node *p) {
	latest_s_subtree = p;
}
void StandardProblems::s_subtree_error(parse_node_tree *T, char *mess) {
	TEMPORARY_TEXT(internal_message)
	WRITE_TO(internal_message, "S-subtree error: %s", mess);
	LOG("%S", internal_message);
	if (latest_s_subtree) LOG("Applied to the subtree:\n$T", latest_s_subtree);
	StandardProblems::internal_error_tu_fn_S(T, internal_message, __FILE__, __LINE__);
	DISCARD_TEXT(internal_message)
}

@h Handmade problems.
Those made without using the convenient shorthand forms below:

=
void StandardProblems::handmade_problem(parse_node_tree *T, SIGIL_ARGUMENTS) {
	ACT_ON_SIGIL
	Problems::issue_problem_begin(T, "");
}
void StandardProblems::handmade_warning(parse_node_tree *T, SIGIL_ARGUMENTS) {
	ACT_ON_SIGIL
	Problems::issue_warning_begin(T, "");
}

@h Limit problems.
Running out of memory, irretrievably: the politest kind of fatal error,
though let's face it, fatal is fatal.

=
void StandardProblems::limit_problem(parse_node_tree *T, SIGIL_ARGUMENTS,
	char *what_has_run_out, int how_many) {
	ACT_ON_SIGIL
	Problems::quote_text(1, what_has_run_out);
	Problems::quote_number(2, &how_many);
	Problems::issue_problem_begin(T, "");
	Problems::issue_problem_segment(
		"I have run out of memory for %1 - there's room for %2, but no more. "
		"This is a 'hard limit', hard in the sense of deadlines, or luck: "
		"there is no getting around it. You will need to rewrite your source "
		"text so that it needs fewer %1.");
	Problems::issue_problem_end();
	ProblemBuffer::write_reports(FALSE);
	ProblemSigils::exit(1);
}

void StandardProblems::memory_allocation_problem(parse_node_tree *T, SIGIL_ARGUMENTS,
	char *what_has_run_out) {
	ACT_ON_SIGIL
	Problems::quote_text(1, what_has_run_out);
	Problems::issue_problem_begin(T, "");
	Problems::issue_problem_segment(
		"I am unable to persuade this computer to let me have memory in "
		"which to store the %1. This rarely happens on a modern desktop or laptop, "
		"but might occur on a small handheld device - if so, it may be a "
		"symptom that the device isn't powerful enough to run me. (See how "
		"I pass the blame?)");
	Problems::issue_problem_end();
	ProblemBuffer::write_reports(FALSE);
	ProblemSigils::exit(1);
}

@h Problem messages unlocated in the source text.
And now the regular problem messages, the ones which are not my fault.
We begin with lexical problems happening when the run is hardly begun:

=
void StandardProblems::lexical_problem(parse_node_tree *T, SIGIL_ARGUMENTS,
	char *message, wchar_t *concerning, char *exp) {
	ACT_ON_SIGIL
	char *lexical_explanation =
		"This is a low-level problem happening when I am still reading in the "
		"source. Such problems sometimes arise because I have been told to "
		"read a source file which is not text at all.";
	if (exp != NULL) lexical_explanation = exp;
	Problems::quote_text(1, message);
	if (concerning) Problems::quote_wide_text(2, concerning);
	else if (current_sentence) Problems::quote_source(2, current_sentence);
	else Problems::quote_text(2, "<text generated internally>");
	Problems::quote_text(3, lexical_explanation);
	Problems::issue_problem_begin(T, lexical_explanation);
	Problems::issue_problem_segment("%1: %2.%L %3");
	Problems::issue_problem_end();
}

void StandardProblems::lexical_problem_S(parse_node_tree *T, SIGIL_ARGUMENTS,
	char *message, text_stream *concerning, char *exp) {
	ACT_ON_SIGIL
	char *lexical_explanation =
		"This is a low-level problem happening when I am still reading in the "
		"source. Such problems sometimes arise because I have been told to "
		"read a source file which is not text at all.";
	if (exp != NULL) lexical_explanation = exp;
	Problems::quote_text(1, message);
	if (concerning) Problems::quote_stream(2, concerning);
	else if (current_sentence) Problems::quote_source(2, current_sentence);
	else Problems::quote_text(2, "<text generated internally>");
	Problems::quote_text(3, lexical_explanation);
	Problems::issue_problem_begin(T, lexical_explanation);
	Problems::issue_problem_segment("%1: %2.%L %3");
	Problems::issue_problem_end();
}

@ Clearly lexical problems cannot cite positions in the source text, and some
other problems can't either, so:

=
void StandardProblems::unlocated_problem(parse_node_tree *T, SIGIL_ARGUMENTS,
	char *message) {
	ACT_ON_SIGIL
	do_not_locate_problems = TRUE;
	Problems::issue_problem_begin(T, message);
	Problems::issue_problem_segment(message);
	Problems::issue_problem_end();
	do_not_locate_problems = FALSE;
}

void StandardProblems::unlocated_problem_on_file(parse_node_tree *T, SIGIL_ARGUMENTS,
	char *message, filename *F) {
	ACT_ON_SIGIL
	do_not_locate_problems = TRUE;
	TEMPORARY_TEXT(fn)
	WRITE_TO(fn, "%f", F);
	Problems::quote_stream(1, fn);
	Problems::issue_problem_begin(T, message);
	Problems::issue_problem_segment(message);
	Problems::issue_problem_end();
	DISCARD_TEXT(fn)
	do_not_locate_problems = FALSE;
}

@h Problem messages keyed to positions in the source text.
The following routine is used to produce more than 300 different problem
messages, making it the most prolific of all the problem routines: perhaps
that isn't surprising, since it simply quotes the entire sentence at fault
(which is always the current sentence) and issues a message.

=
void StandardProblems::sentence_problem(parse_node_tree *T, SIGIL_ARGUMENTS,
	char *message, char *explanation) {
	ACT_ON_SIGIL
	Problems::quote_source(1, current_sentence);
	Problems::quote_text(2, message);
	Problems::quote_text(3, explanation);
	Problems::issue_problem_begin(T, explanation);
	Problems::issue_problem_segment("You wrote %1: %Sagain, %2.%Lbut %2, %3");
	Problems::issue_problem_end();
}

@ And a variant which adds a note in a subsequent paragraph.

=
void StandardProblems::sentence_problem_with_note(parse_node_tree *T, SIGIL_ARGUMENTS,
		char *message, char *explanation, char *note) {
	ACT_ON_SIGIL
	Problems::quote_source(1, current_sentence);
	Problems::quote_text(2, message);
	Problems::quote_text(3, explanation);
	Problems::quote_text(4, note);
	Problems::issue_problem_begin(T, explanation);
	Problems::issue_problem_segment("You wrote %1: %Sagain, %2.%Lbut %2, %3 %P%4");
	Problems::issue_problem_end();
}

@ And this is a variant which draws particular attention to a word range
which is part of the current sentence.

=
void StandardProblems::sentence_in_detail_problem(parse_node_tree *T, SIGIL_ARGUMENTS,
		wording W, char *message, char *explanation) {
	ACT_ON_SIGIL
	Problems::quote_source(1, current_sentence);
	Problems::quote_text(2, message);
	Problems::quote_text(3, explanation);
	Problems::quote_wording(4, W);
	Problems::issue_problem_begin(T, explanation);
	Problems::issue_problem_segment(
		"You wrote %1, and in particular '%4': %Sagain, %2.%Lbut %2, %3");
	Problems::issue_problem_end();
}

@ A not always helpful problem message which is needed in several places, and
therefore is kept here:

=
void StandardProblems::negative_sentence_problem(parse_node_tree *T, SIGIL_ARGUMENTS) {
	StandardProblems::sentence_problem(T, PASS_SIGIL,
		"assertions about the initial state of play must be positive, not negative",
		"so 'The cat is an animal' is fine but not 'The cat is not a container'. "
		"I have only very feeble powers of deduction - sometimes the implications "
		"of a negative statement are obvious to a human reader, but not to me.");
}

@h Definition problems.
Sentence problems are a nuisance for "Definition:" definitions, because
those usually occur when the current sentence is rather unhelpfully just the
word "Definition" alone. So we use this routine instead:

=
void StandardProblems::definition_problem(parse_node_tree *T, SIGIL_ARGUMENTS,
	parse_node *q, char *message, char *explanation) {
	ACT_ON_SIGIL
	Problems::quote_source(1, q);
	Problems::quote_text(2, message);
	Problems::quote_text(3, explanation);
	Problems::issue_problem_begin(T, explanation);
	Problems::issue_problem_segment(
		"You gave as a definition %1: %Sagain, %2.%Lbut %2, %3");
	Problems::issue_problem_end();
}

void StandardProblems::adjective_problem(parse_node_tree *T, SIGIL_ARGUMENTS,
	wording IX, wording D, char *message, char *explanation) {
	ACT_ON_SIGIL
	Problems::quote_wording(1, IX);
	Problems::quote_wording(2, D);
	Problems::quote_text(3, message);
	Problems::quote_text(4, explanation);
	Problems::quote_source(5, current_sentence);
	Problems::issue_problem_begin(T, explanation);
	Problems::issue_problem_segment(
		"In %5 you defined an adjective by '%1' intending that "
		"it would apply to '%2': %Sagain, %3.%Lbut %3, %4");
	Problems::issue_problem_end();
}

@h Creating the Problems report.
We are at last able to print the text which appears at the top of the
Problems report; and this completes the code for errors. In my end is my beginning.

=
void StandardProblems::start_problems_report(filename *F) {
	if (F) {
		#ifdef START_PROBLEM_FILE_PROBLEMS_CALLBACK
		START_PROBLEM_FILE_PROBLEMS_CALLBACK(F, problems_file);
		#endif
		problems_file_active = TRUE;
	} else {
		problems_file_active = FALSE;
	}
}

void StandardProblems::issue_problems_banner(OUTPUT_STREAM, char *verdict) {
	HTML::comment(OUT, I"BANNER BEGINS");
	HTML_OPEN_WITH("table", "cellspacing=\"3\" border=\"0\" width=\"100%%\"");
	HTML_OPEN_WITH("tr", "id=\"surround0\"");
	HTML_OPEN_WITH("td", "style=\"width:100%%\"");
	HTML::comment(OUT, I"HEADING BEGINS");
	text_stream *styling = I"failed";
	if (CStrings::eq(verdict, "Succeeded")) styling = I"succeeded";
	HTML_OPEN_WITH("div", "class=\"headingpanellayout headingpanel%S\"", styling);
	HTML_OPEN_WITH("div", "class=\"headingtext\"");
	HTML::begin_span(OUT, I"headingpaneltext");
	WRITE("Report on Translation: %s", verdict);
	HTML::end_span(OUT);
	HTML_CLOSE("div");
	HTML_OPEN_WITH("div", "class=\"headingrubric\"");
	HTML::begin_span(OUT, I"headingpanelrubric");
	WRITE("Produced by %B", FALSE, TRUE);
	HTML::end_span(OUT);
	HTML_CLOSE("div");
	HTML_CLOSE("div");
	HTML::comment(OUT, I"HEADING ENDS");
	HTML_CLOSE("td");
	HTML_CLOSE("tr");
	HTML_CLOSE("table");
	HTML::comment(OUT, I"BANNER ENDS");
}
