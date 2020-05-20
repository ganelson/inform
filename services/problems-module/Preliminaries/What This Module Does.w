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
(c) This module uses other modules drawn from the //compiler//, and also
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
//Problems::Fatal::require// tells //problems// that the parent tool positively
wants to issue a given problem message. This is useful when testing Inform
on bad source text to check that it reports the badness as we hope.

The parent can also configure //problems// by calling //Problems::Fatal::echo_sigils//
or //Problems::Fatal::crash_on_problems//.

@h Fatal errors.
These are problems which cause an immediate exit of the program as soon as
they are issued, and are typically used for filing-system disasters or
failed assertions (so-called "internal errors").

Facilities for these are very limited:
(*) //Problems::Fatal::issue// for a simple message with fixed wording.
(*) //Problems::Fatal::filename_related// for a message relating to a file.

@h Telemetry.
The //Telemetry// system isn't really to do with problems, except that it
can log them; it is an optional facility to log activity of a tool or app.
This is locally stored rather than sent over any wires, so perhaps there's
no "tele-" about it.
