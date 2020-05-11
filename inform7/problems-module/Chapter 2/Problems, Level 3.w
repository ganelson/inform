[Problems::Issue::] Problems, Level 3.

Here we provide some convenient semi-standardised problem messages,
which also serve as examples of how to use the Level 2 problem message
routines.

@ Internal errors are essentially failed assertions, and they should never
occur, whatever the provocation: if they do, they are symptoms of a bug.

=
int internal_error_thrown = FALSE;
int Problems::Issue::internal_errors_have_occurred(void) {
	return internal_error_thrown;
}

@ The internal error "functions" used by the rest of Inform are in fact macros,
in order that they can supply the current filename and line number
automatically to the actual internal error functions. The result is, for
instance,

>> Problem. An internal error has occurred: Unknown verb code. The current sentence is "A room is a kind"; the error was detected at line 133 of "Chapter 5/Traverse for Objects.w". This should never happen, and I am now halting in abject failure.

@d internal_error_tree_unsafe(X) Problems::Issue::internal_error_tu_fn(NULL, X, __FILE__, __LINE__)
@d internal_error_if_node_type_wrong(T, X, Y) Problems::Issue::nodal_check(T, X, Y, __FILE__, __LINE__)
@d internal_error_on_node_type(X) Problems::Issue::internal_error_on_node_type_fn(NULL, X, __FILE__, __LINE__)

@ Internal errors are generated much like any other problem message, except
that we use a variant form of the "end" routine which salvages what it can
from the wreckage, then either forces a crash (to make the stack backtrace
visible in a debugger) or simply exits to the operating system with error
code 1:

=
void Problems::Issue::internal_error_end(void) {
	Problems::issue_problem_end();
	Problems::write_reports(TRUE);
	if (debugger_mode) Problems::Fatal::force_crash();
	Problems::Fatal::exit(1);
}

@ And now for the functions which the above macros invoke. There are two
versions: one which cites the current sentence, and another which doesn't,
for use if either there is no current sentence (because Inform wasn't traversing
the parse tree at the time) or if the parse tree is unsafe -- it's possible
that the internal error occurred during parse tree construction, so we need
to be cautious.

=
void Problems::Issue::internal_error_fn(void *T, char *p, char *filename, int linenum) {
	internal_error_thrown = TRUE;
	if (current_sentence == NULL) {
		Problems::Issue::internal_error_tu_fn(T, p, filename, linenum);
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
	Problems::Issue::internal_error_end();
}

void Problems::Issue::internal_error_tu_fn(void *T, char *p, char *filename, int linenum) {
	internal_error_thrown = TRUE;
	Problems::quote_text(1, p);
	Problems::quote_text(2, filename);
	Problems::quote_number(3, &linenum);
	Problems::issue_problem_begin(T, p);
	Problems::issue_problem_segment(
		"An internal error has occurred: %1. The error was detected at "
		"line %3 of \"%2\". This should never happen, and I am now halting "
		"in abject failure.");
	Problems::Issue::internal_error_end();
}

void Problems::Issue::internal_error_tu_fn_S(void *T, text_stream *p, char *filename, int linenum) {
	internal_error_thrown = TRUE;
	Problems::quote_stream(1, p);
	Problems::quote_text(2, filename);
	Problems::quote_number(3, &linenum);
	Problems::issue_problem_begin(T, "");
	Problems::issue_problem_segment(
		"An internal error has occurred: %1. The error was detected at "
		"line %3 of \"%2\". This should never happen, and I am now halting "
		"in abject failure.");
	Problems::Issue::internal_error_end();
}

@h Nodal errors.
Very many routines are designed to work only on nodes within the parse
tree of a particular node type. If Inform is in working order, then they will
never be called at any other nodes; but it seems best to check this. Any
failure of such an invariant produces a form of internal error called a
"nodal error".

=
void Problems::Issue::nodal_error_fn(parse_node_tree *T, parse_node *pn, char *p, char *filename, int linenum) {
	LOG("Internal nodal error at:\n");
	LOG("$T\n", pn);
	Problems::Issue::internal_error_fn(T, p, filename, linenum);
}

void Problems::Issue::nodal_error_fn_S(parse_node_tree *T, parse_node *pn, text_stream *p, char *filename, int linenum) {
	LOG("Internal nodal error at:\n");
	LOG("$T\n", pn);
	Problems::Issue::internal_error_tu_fn_S(T, p, filename, linenum);
}

@ Here is a convenient function to check said invariant.

=
void Problems::Issue::nodal_check(parse_node_tree *T, parse_node *pn, node_type_t node_type_required, char *filename, int linenum) {
	if (pn == NULL) {
		TEMPORARY_TEXT(internal_message);
		WRITE_TO(internal_message, "NULL node found where type %S expected",
			NodeType::get_name(node_type_required));
		Problems::Issue::internal_error_tu_fn_S(T, internal_message, filename, linenum);
		DISCARD_TEXT(internal_message);
	} else if (Node::get_type(pn) != node_type_required) {
		TEMPORARY_TEXT(internal_message);
		WRITE_TO(internal_message, "Node of type %S found where type %S expected",
			NodeType::get_name(Node::get_type(pn)),
			NodeType::get_name(node_type_required));
		Problems::Issue::nodal_error_fn_S(T, pn, internal_message, filename, linenum);
		DISCARD_TEXT(internal_message);
	}
}

@ Nodal errors also turn up as the default clauses in switch statements which
act on various selections of node types, and those use the |internal_error_on_node_type|
macro, which invokes the following:

=
void Problems::Issue::internal_error_on_node_type_fn(parse_node_tree *T,
	parse_node *pn, char *filename, int linenum) {
	TEMPORARY_TEXT(internal_message);
	if (pn == NULL)
		Problems::Issue::internal_error_tu_fn(T, "Unexpected NULL node found", filename, linenum);
	WRITE_TO(internal_message, "Unexpectedly found node of type %S",
		NodeType::get_name(Node::get_type(pn)));
	Problems::Issue::nodal_error_fn_S(T, pn, internal_message, filename, linenum);
	DISCARD_TEXT(internal_message);
}

@ The following routines are relics of an era of horrific, primordial upheaval,
when the S-parser was being debugged. An S-subtree is a portion of the parse
tree which represents a proposition.

=
parse_node *latest_s_subtree = NULL;
void Problems::Issue::s_subtree_error_set_position(parse_node_tree *T, parse_node *p) {
	latest_s_subtree = p;
}
void Problems::Issue::s_subtree_error(parse_node_tree *T, char *mess) {
	TEMPORARY_TEXT(internal_message);
	WRITE_TO(internal_message, "S-subtree error: %s", mess);
	LOG("%S", internal_message);
	if (latest_s_subtree) LOG("Applied to the subtree:\n$T", latest_s_subtree);
	Problems::Issue::internal_error_tu_fn_S(T, internal_message, __FILE__, __LINE__);
	DISCARD_TEXT(internal_message);
}

@h Sigils.
Every problem message in Inform is identified by a sigil, a short
alphanumeric symbol. The |_p_| notation is used to write these;
see almost every section in later chapters for examples. The naming rules
for sigils are as follows:

(a) A problem which is thought never to be generated has the sigil
|BelievedImpossible|. Inform is quite defensively coded, so there are several
dozen of these -- they are safety nets to catch cases we didn't think of.

(b) A problem which either cannot be tested by |intest|, or is just impracticable
to do so, has the sigil |Untestable|.

(c) A problem which can be tested, but for which nobody has yet written a
test case, has the sigil |...| (these are gradually declining in number, and
eventually, of course, will disappear altogether).

(d) Otherwise a problem should have a unique sigil beginning |C| and then the
chapter number in which it is found: say, |PM_NoSuchHieroglyph|. The sigil
should have the same name as an |intest| test case which demonstrates the
problem.

(e) A sigil which ends |-G| should be used for those few problems which appear
only when the virtual machine is Glulx.

It would be easy for all this to fall out of sync, or for us just to lose track
of odd cases, since there are more than 750 problem messages; so a shell script
called |listproblems.sh| exists to verify that the above rules have been
adhered to.

@ As can be seen, |_p_| is a macro expanding to the sigil's name in double
quotes followed by the source section and line number at which it is generated.
This provides three function arguments matching the |SIGIL_ARGUMENTS| prototype,
which appears as a pseudo-argument in all of the problem routines below.

Each such routine should either |ACT_ON_SIGIL| itself or else pass over to
another problem routine, using |PASS_SIGIL| as the pseudo-argument.

@d _p_(sigil) #sigil, __FILE__, __LINE__

@d SIGIL_ARGUMENTS char *sigil, char *file, int line

@d ACT_ON_SIGIL
	LOG("Problem %s issued from %s, line %d\n", sigil, file, line);
	if (telemetry_recording) {
		Telemetry::ensure_telemetry_file();
		WRITE_TO(telmy, "Problem %s issued from %s, line %d\n", sigil, file, line);
	}
	if (sigil_of_latest_unlinked_problem == NULL) sigil_of_latest_unlinked_problem = Str::new();
	else Str::clear(sigil_of_latest_unlinked_problem);
	if (sigil_of_latest_problem == NULL) sigil_of_latest_problem = Str::new();
	else Str::clear(sigil_of_latest_problem);
	WRITE_TO(sigil_of_latest_unlinked_problem, "%s", sigil);
	WRITE_TO(sigil_of_latest_problem, "%s", sigil);
	if (Str::eq(sigil_of_required_problem, sigil_of_latest_problem))
		sigil_of_required_problem_found = TRUE;
	if (echo_problem_message_sigils) WRITE_TO(STDERR, "Problem__ %S\n", sigil_of_latest_problem);

@d PASS_SIGIL sigil, file, line

=
text_stream *sigil_of_latest_unlinked_problem = NULL;
text_stream *sigil_of_latest_problem = NULL;

void Problems::Issue::problem_documentation_links(OUTPUT_STREAM) {
	if (Str::len(sigil_of_latest_unlinked_problem) == 0) return;
	#ifdef DOCUMENTATION_REFERENCES_PRESENT
	wchar_t *chap = NULL, *sec = NULL;
	wchar_t *leaf = Index::DocReferences::link_if_possible_once(sigil_of_latest_unlinked_problem, &chap, &sec);
	if (leaf) {
		HTML::open_indented_p(OUT, 2, "tight");
		HTML_OPEN_WITH("a", "href=inform:/%w.html", leaf);
		HTML_TAG_WITH("img", "border=0 src=inform:/doc_images/help.png");
		HTML_CLOSE("a");
		WRITE("&nbsp;");
		if ((chap) && (sec)) {
			WRITE("<i>See the manual: %w &gt; %w</i>", chap, sec);
		} else {
			WRITE("<i>See the manual.</i>");
		}
		HTML_CLOSE("p");
		if (telemetry_recording) {
			WRITE_TO(telmy, "See the manual: %w > %w\n\n", chap, sec);
		}
	}
	#endif
	Str::clear(sigil_of_latest_unlinked_problem);
}

text_stream *Problems::Issue::latest_sigil(void) {
	return sigil_of_latest_problem;
}

@ The command-line switch |-sigils| causes the following flag to be set,
which in turn causes the sigil of any problem to be echoed to standard output
(i.e., printed). This is useful in testing, as it makes it easier to be sure
that the test case |PM_NoSuchHieroglyph.txt| does indeed generate the
problem |PM_NoSuchHieroglyph|, and so on.

=
int echo_problem_message_sigils = FALSE;

@h Handmade problems.
Those made without using the convenient shorthand forms below:

=
void Problems::Issue::handmade_problem(parse_node_tree *T, SIGIL_ARGUMENTS) {
	ACT_ON_SIGIL
	Problems::issue_problem_begin(T, "");
}

@h Limit problems.
Running out of memory, irretrievably: the politest kind of fatal error,
though let's face it, fatal is fatal.

=
void Problems::Issue::limit_problem(parse_node_tree *T, SIGIL_ARGUMENTS, char *what_has_run_out, int how_many) {
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
	Problems::write_reports(FALSE);
	Problems::Fatal::exit(1);
}

void Problems::Issue::memory_allocation_problem(parse_node_tree *T, SIGIL_ARGUMENTS, char *what_has_run_out) {
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
	Problems::write_reports(FALSE);
	Problems::Fatal::exit(1);
}

@h Problem messages unlocated in the source text.
And now the regular problem messages, the ones which are not my fault.
We begin with lexical problems happening when the run is hardly begun:

=
void Problems::Issue::lexical_problem(parse_node_tree *T, SIGIL_ARGUMENTS, char *message, wchar_t *concerning, char *exp) {
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
	Problems::issue_problem_segment("%1: %2%L.%%%| %3");
	Problems::issue_problem_end();
}

void Problems::Issue::lexical_problem_S(parse_node_tree *T, SIGIL_ARGUMENTS, char *message, text_stream *concerning, char *exp) {
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
	Problems::issue_problem_segment("%1: %2%L.%%%| %3");
	Problems::issue_problem_end();
}

@ Clearly lexical problems cannot cite positions in the source text, and some
other problems can't either, so:

=
void Problems::Issue::unlocated_problem(parse_node_tree *T, SIGIL_ARGUMENTS, char *message) {
	ACT_ON_SIGIL
	do_not_locate_problems = TRUE;
	Problems::issue_problem_begin(T, message);
	Problems::issue_problem_segment(message);
	Problems::issue_problem_end();
	do_not_locate_problems = FALSE;
}

void Problems::Issue::unlocated_problem_on_file(parse_node_tree *T, SIGIL_ARGUMENTS, char *message, filename *F) {
	ACT_ON_SIGIL
	do_not_locate_problems = TRUE;
	TEMPORARY_TEXT(fn);
	WRITE_TO(fn, "%f", F);
	Problems::quote_stream(1, fn);
	Problems::issue_problem_begin(T, message);
	Problems::issue_problem_segment(message);
	Problems::issue_problem_end();
	DISCARD_TEXT(fn);
	do_not_locate_problems = FALSE;
}

@h Problem messages keyed to positions in the source text.
The following routine is used to produce more than 300 different problem
messages, making it the most prolific of all the problem routines: perhaps
that isn't surprising, since it simply quotes the entire sentence at fault
(which is always the current sentence) and issues a message.

=
void Problems::Issue::sentence_problem(parse_node_tree *T, SIGIL_ARGUMENTS, char *message, char *explanation) {
	ACT_ON_SIGIL
	Problems::quote_source(1, current_sentence);
	Problems::quote_text(2, message);
	Problems::quote_text(3, explanation);
	Problems::issue_problem_begin(T, explanation);
	Problems::issue_problem_segment("You wrote %1: %Sagain, %%%Lbut %%%2%|, %3");
	Problems::issue_problem_end();
}

@ And a variant which adds a note in a subsequent paragraph.

=
void Problems::Issue::sentence_problem_with_note(parse_node_tree *T, SIGIL_ARGUMENTS,
		char *message, char *explanation, char *note) {
	ACT_ON_SIGIL
	Problems::quote_source(1, current_sentence);
	Problems::quote_text(2, message);
	Problems::quote_text(3, explanation);
	Problems::quote_text(4, note);
	Problems::issue_problem_begin(T, explanation);
	Problems::issue_problem_segment("You wrote %1: %Sagain, %%%Lbut %%%2%|, %3 %P%4");
	Problems::issue_problem_end();
}

@ And this is a variant which draws particular attention to a word range
which is part of the current sentence.

=
void Problems::Issue::sentence_in_detail_problem(parse_node_tree *T, SIGIL_ARGUMENTS,
		wording W, char *message, char *explanation) {
	ACT_ON_SIGIL
	Problems::quote_source(1, current_sentence);
	Problems::quote_text(2, message);
	Problems::quote_text(3, explanation);
	Problems::quote_wording(4, W);
	Problems::issue_problem_begin(T, explanation);
	Problems::issue_problem_segment(
		"You wrote %1, and in particular '%4': %Sagain, %%%Lbut %%%2%|, %3");
	Problems::issue_problem_end();
}

@ A not always helpful problem message which is needed in several places, and
therefore is kept here:

=
void Problems::Issue::negative_sentence_problem(parse_node_tree *T, SIGIL_ARGUMENTS) {
	Problems::Issue::sentence_problem(T, PASS_SIGIL,
		"assertions about the initial state of play must be positive, not negative",
		"so 'The cat is an animal' is fine but not 'The cat is not a container'. "
		"I have only very feeble powers of deduction - sometimes the implications "
		"of a negative statement are obvious to a human reader, but not to me.");
}

@ This is a much more elaborate form of the standard |Problems::Issue::sentence_problem|,
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
#ifdef LINGUISTICS_MODULE
void Problems::Issue::assertion_problem(parse_node_tree *T, SIGIL_ARGUMENTS, char *message, char *explanation) {
	wording RTW = EMPTY_WORDING; /* "rather than" text */
	ACT_ON_SIGIL
	if ((current_sentence == NULL) || (current_sentence->down == NULL) ||
		(Node::get_type(current_sentence->down) != AVERB_NT)) {
		LOG("(Assertion error reverting to sentence error.)\n");
		Problems::Issue::sentence_problem(T, PASS_SIGIL, message, explanation);
		return;
	}

	LOG("(Assertion error: looking for alternative verbs in <%W>.)\n",
		Node::get_text(current_sentence));
	wording AW = Wordings::trim_both_ends(Node::get_text(current_sentence));
	LOOP_THROUGH_WORDING(i, AW)
		if ((i != Wordings::first_wn(Node::get_text(current_sentence->down))) &&
			(Word::unexpectedly_upper_case(i) == FALSE)) {
			int j = <meaningful-nonimperative-verb>(Wordings::from(Node::get_text(current_sentence), i));
			if (j > 0) RTW = Wordings::new(i, j);
		}
	Problems::quote_source(1, current_sentence);
	Problems::quote_text(2, message);
	Problems::quote_text(3, explanation);
	Problems::issue_problem_begin(T, explanation);
	Problems::issue_problem_segment("You wrote %1: %Sagain, %%%Lbut %%%2%|, %3");
	if (Wordings::nonempty(RTW)) {
		Problems::quote_wording(4, Node::get_text(current_sentence->down));
		Problems::quote_wording(5, RTW);
		Problems::issue_problem_segment( /* see also PM_AmbiguousVerb */
			" %P(It may help to know that I am reading the primary verb here "
			"as '%4', not '%5'.)");
	}
	Problems::Issue::diagnose_further();
	Problems::issue_problem_end();
}

void Problems::Issue::diagnose_further(void) {
	if (current_sentence == NULL) return;
	if (Wordings::empty(Node::get_text(current_sentence))) return;
	int sqc = 0;
	LOOP_THROUGH_WORDING(i, Node::get_text(current_sentence)) sqc += Word::singly_quoted(i);
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
#endif

@h Definition problems.
Sentence problems are a nuisance for "Definition:" definitions, because
those usually occur when the current sentence is rather unhelpfully just the
word "Definition" alone. So we use this routine instead:

=
void Problems::Issue::definition_problem(parse_node_tree *T, SIGIL_ARGUMENTS, parse_node *q,
		char *message, char *explanation) {
	ACT_ON_SIGIL
	Problems::quote_source(1, q);
	Problems::quote_text(2, message);
	Problems::quote_text(3, explanation);
	Problems::issue_problem_begin(T, explanation);
	Problems::issue_problem_segment("You gave as a definition %1: %Sagain, %%%Lbut %%%2%|, %3");
	Problems::issue_problem_end();
}

void Problems::Issue::adjective_problem(parse_node_tree *T, SIGIL_ARGUMENTS, wording IX, wording D,
		char *message, char *explanation) {
	ACT_ON_SIGIL
	Problems::quote_wording(1, IX);
	Problems::quote_wording(2, D);
	Problems::quote_text(3, message);
	Problems::quote_text(4, explanation);
	Problems::quote_source(5, current_sentence);
	Problems::issue_problem_begin(T, explanation);
	Problems::issue_problem_segment("In %5 you defined an adjective by '%1' intending that "
		"it would apply to '%2': %Sagain, %%%Lbut %%%3%|, %4");
	Problems::issue_problem_end();
}

@h Creating the Problems report.
We are at last able to print the text which appears at the top of the
Problems report; and this completes the code for errors. In my end is my beginning.

=
void Problems::Issue::start_problems_report(filename *F) {
	#ifdef PROBLEMS_INITIAL_REPORTER
	PROBLEMS_INITIAL_REPORTER(F);
	#endif
}

void Problems::Issue::issue_problems_banner(OUTPUT_STREAM, char *verdict) {
	HTML::comment(OUT, I"BANNER BEGINS");
	HTML_OPEN_WITH("table", "cellspacing=\"3\" border=\"0\" width=\"100%%\"");
	HTML_OPEN_WITH("tr", "id=\"surround0\"");
	HTML_OPEN_WITH("td", "style=\"width:100%%\"");
	HTML::comment(OUT, I"HEADING BEGINS");
	HTML_OPEN_WITH("div", "class=\"headingbox%s\"", verdict);
	HTML_OPEN_WITH("div", "class=\"headingtext\"");
	WRITE("Report on Translation: %s", verdict);
	HTML_CLOSE("div");
	HTML_OPEN_WITH("div", "class=\"headingrubric\"");
	WRITE("Produced by %B (build %B)", FALSE, TRUE);
	HTML_CLOSE("div");
	HTML_CLOSE("div");
	HTML::comment(OUT, I"HEADING ENDS");
	HTML_CLOSE("td");
	HTML_CLOSE("tr");
	HTML_CLOSE("table");
	HTML::comment(OUT, I"BANNER ENDS");
}
