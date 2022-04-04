What This Module Does.

An overview of the problems module's role and abilities.

@h Prerequisites.
The problems module is a part of the Inform compiler toolset. It is
presented as a literate program or "web". Before diving in:
(a) It helps to have some experience of reading webs: see //inweb// for more.
(b) The module is written in C, in fact ANSI C99, but this is disguised by the
fact that it uses some extension syntaxes provided by the //inweb// literate
programming tool, making it a dialect of C called InC. See //inweb// for
full details, but essentially: it's C without predeclarations or header files,
and where functions have names like |Tags::add_by_name| rather than |add_by_name|.
(c) This module uses other modules drawn from the compiler (see //structure//), and also
uses a module of utility functions called //foundation//.
For more, see //foundation: A Brief Guide to Foundation//.

@h Problems and their sigils.
The task of this module is to issue error messages which may be lengthy and
quite verbal in nature, and to produce them attractively to the command line,
in an HTML file reporting the result of a run, or both.

Each different problem message has a textual identifier, or "sigil".
For example, |PM_VerbUnknownMeaning| is the sigil for the Inform problem
message issued when the user defines a verb in a way it doesn't understand.
Sigils are in practice referred to using a macro |_p_| defined early on in
//Problems, Level 0//.

Sigils are |char *| constants. The Inform modules use the following naming
conventions for sigils:

(a) A problem which is thought never to be generated has the sigil
|BelievedImpossible|. Inform is quite defensively coded, so there are several
dozen of these -- they are safety nets to catch cases we didn't think of.
(b) A problem which either cannot be tested by //intest//, or is just
impracticable to do so, has the sigil |Untestable|.
(c) A problem which can be tested, but for which nobody has yet written a
test case, has the sigil |...|.
(d) Otherwise a problem should have a unique alphanumeric name beginning with
|PM_|, for "problem message": for example, |PM_NoSuchHieroglyph|. This should
be the same name as that of the test case which exercises it.

Because sigils correspond to test case names, they also have to follow the
conventions on test case naming: in particular, the suffix |-G| means "for
the Glulx virtual machine only", and similarly for |-Z|.

@ In general problems are a bad thing, of course, but a call to
//ProblemSigils::require// tells //problems// that the parent tool positively
wants to issue a given problem message. This is useful when testing Inform
on bad source text to check that it reports the badness as we hope.

The parent can also configure //problems// by calling //ProblemSigils::echo_sigils//
or //ProblemSigils::crash_on_problems//.

@h The story of a non-fatal problem message.
Suppose that the //core// module wants to issue a problem message: what
happens?

This depends on how complicated it is. The //problems// system has three
levels:
(3) //Problems, Level 3// contains functions for problem messages which have
a commonly-needed shape to them: for example, //StandardProblems::sentence_problem//.
The functions in question call down to...
(2) //Problems, Level 2//, which contains functions to accept "quotations" and
a problem message with placeholders in to hold those quotations; after which,
they call down to...
(1) //Problems, Level 1//, where the text of a message is stored in the
"problem buffer" and eventually printed or written to a file.

Most of the problems issued by Inform look like this:
= (text as InC)
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_BadDesk),
		"Inform does not support standing desks",
		"and needs your laptop to be lower than your ribcage at all times.");
=
The sigil for this (hypothetical) problem message is |PM_BadDesk|, and note the
use of the |_p_| macro to refer to it: see //Problems, Level 0// for more. The
first piece of text is always produced, and the second added only on the first
occurrence. //core// doesn't need to do anything more than make this one
function call to Level 3, and //problems// does everything else.

But a significant number of problems are less standard in shape and are
called "handmade", meaning that //core// has to call some Level 2 functions.
For example:
= (text as InC)
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, W);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ScottishPlay));
	Problems::issue_problem_segment(
		"In the sentence %1, it looks as if '%2' might be a reference to a "
		"theatrical work connected with Scotland.");
	Problems::issue_problem_end();
=
What happens, in sequence, is that we
(a) Establish what material should go into the placeholders |%1| and |%2|,
(b) Call //StandardProblems::handmade_problem// to begin work,
(c) Call //Problems::issue_problem_segment// a number of times -- though often
just once -- to put some text into the problem, and
(d) Call //Problems::issue_problem_end// to signal that we are done.

@ As this demonstrates, problem messages are expanded from prototypes using
a |printf|-like formatting system. Unlike |printf|, though, where |%s| means
a string and |%d| a number, here the escape codes do not indicate the type of
the data: they are simply |%1|, |%2|, |%3|, ..., |%9|. This is to prevent
horrendous crashes when type mismatches occur: using a pointer to a phrase
when trying to print a source code reference, for instance.

The placeholders do not need to be used contiguously -- if you want to use
just |%4| and |%7|, feel free.

Four further escape codes switch between problem message versions, as follows:
(*) |%L| means "long form", the version used the first time this message is
generated,
(*) |%S| means "short form", for subsequent times,
(*) |%A| means "both long and short", which is the situation at the start,

Note that the form is reset to |%A| when a new problem message begins, but not
in between calls to //Problems::issue_problem_segment//: i.e., if one segment
leaves things in |%L|, the next segment, if there is one, resumes that way.

For example, |"You wrote %1: %Sagain, %2.%Lbut %2, %3"| is the message
text used by //StandardProblems::sentence_problem//. 
= (text)
	                 "You wrote %1: %Sagain, %2.%Lbut %2, %3"
	on first use --> "You wrote %1: but %2, %3"
	subsequently --> "You wrote %1: again, %2."
=
Here the punctuation; |%3| is expected to end with a full stop and |%2| not to.

Finally, the escape |%P| means "poragraph break here", and is used for adding
subsequent clarifications to long or complicated problems.

@ //Problems, Level 3// contains functions for standardly-shaped problems, then.
A significant amount of this section also deals with internal errors, that is,
failed assertions; while //foundation// provides the basic system for handling
those -- i.e., print and then exit the program -- //core// redirects all
internal errors to //StandardProblems::internal_error_fn//, which ensures that
they pass through our problems machinery here, and are thus properly recorded
in the HTML problems report in the Inform app (if that's what the user is
using).

@ //Problems, Level 2// contains functions for making quotations to fill the
placeholders with content -- see //problem_quotation//.

The mechanism for determining whether an explanation has been given before is
//Problems::explained_before//. The obvious thing would be to go by the sigils
of previously issued messages, but it actually uses the textual token supplied
on the call to //Problems::issue_problem_begin//, which allows for some
variations -- Level 3 functions are able to use this to ensure that particular
kinds of message are always, or are never, explained.

As Level 2 generates problem text, it calls down into //ProblemBuffer::output_problem_buffer//
at Level 1.

Just a few functions at Level 2 issue fatal errors -- that is, problems which
cause an immediate exit of the program as soon as they are issued, and are
typically used for filing-system disasters or failed assertions (so-called
"internal errors").

Facilities for these are very limited:
(*) //Problems::fatal// for a simple message with fixed wording.
(*) //Problems::fatal_on_file// for a message relating to a file.

These routines have to be written with care because a file-system disaster
might mean that the problems file itself cannot be written to.

@ //Problems, Level 1// is concerned with the "problem buffer" |PBUFF|.
This is a text used to hold the problem message as it is assembled from pieces,
and only Level 2 functions should print to it. Even they should call down to
two Level 1 functions when they want to write something other than straightforward
text:
(*) Source text from the lexer can be quoted into it with //ProblemBuffer::copy_text//,
which automatically trims excessive quotes for length.
(*) References to positions in the source text can be inserted with
//ProblemBuffer::copy_source_reference//: there is a sort of protocol for how
this is done, with use of the magic |SOURCE_REF_CHAR| which will be
intercepted later on when the problems file is written out as HTML (see
//foundation: HTML// for details).

@ When a portion of text has been buffered which Level 2 wants to get shot of,
it calls down to //ProblemBuffer::output_problem_buffer// to send this to a
file. By default, the text is actually sent three ways: to the standard
console output, to the debugging log (if there is one), and to the telemetry
file (if there is one). But this can be diverted with
//ProblemBuffer::redirect_problem_stream//, telling it to send problem text
just one way.

@h Telemetry.
The //Telemetry// system isn't really to do with problems, except that it
can log them; it is an optional facility to log activity of a tool or app.
This is locally stored rather than sent over any wires, so perhaps there's
no "tele-" about it.
