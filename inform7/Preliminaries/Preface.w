P/pref: Preface.

An introduction to the reader.

@ Inform 7 is a free open-source system for the design of interactive fiction.
This is the source code to NI, which is the component of I7 used for turning a
natural language description of a model world into a valid implementation
in Inform 6 (I6). This is one of the two uninteractive steps on the
assembly line:
$$ {\it Natural~language} \longrightarrow
{\bf NI} \longrightarrow {\bf I6}
\longrightarrow \cases{\hbox{\it Z-machine~story~file}&\cr
\hbox{\it Glulx~story~file}&\cr} $$
The Inform user interface automates this process and also supplies both
ends: editing the natural language source and running the appropriate
interpreter to play the resulting story file. The three user interfaces,
by Andrew Hunter for Mac OS X, by David Kinder for Windows, and by
Philip Chimento and Adam Thornton for Linux, are not documented here.

There are a further three substantial software layers needed to use I7:

(i) the Standard Rules file, written in I7 source text but with certain
permitted additional syntaxes: this is formally an Extension, though its
presence is essential;

(ii) the |.i6| files, written in a metalanguage resembling that of I6,
which serves both as a repository of useful I6 routines for NI-compiled
programs, and also as a description at the top level of what NI should
do and in what order;

(iii) the "natural" variant of the I6 library, which is fundamentally
the standard I6 library but with large parts of the action verb subroutines
removed, and with numerous minor modifications and hooks added to the parser
and the actions engine.

Any reader who has used I6 can take (iii) for granted, but a reading of (i)
and (ii) might well be more useful in giving an appreciation of I7's internals
than reading the NI source would be.

This is not intended as a manual for Inform 7: {\it Writing with Inform}
and {\it The Inform Recipe Book}, the interleaved volumes of documentation
included in the application and also published online, are the user guide.
Nor is there much comment here on how the design was made: for some of the
early history, see the "white paper" for the Inform 7 project, {\it Natural
Language, Semantic Analysis and Interactive Fiction}, which covers the basic
decisions made. The commentary in the source code assumes that the overall
strategy is wise and gets on with its practical implementation.

@h Basic method.
NI is a large but simple program. First, it reads the source text and
breaks it up lexically into words, quoted matter and punctuation. Then
it divides this stream of words into sentences, marking some out as
headings and others as requests to include extensions, requests which
are immediately carried out. When there is nothing further to input,
sentences are sorted into assertions (statements about the initial state
of the world) and rules (instructions concerning play). Assertions are
generally copular sentences relating things together, such as "two
coins are in a closed box", and these are parsed first into "meaning
list" tree structures and thence into propositions in predicate calculus
which are declared to be true at the start of play. Each such proposition
is then interpreted to extract single facts called "inferences", and
reasonable "common sense" guesses are made to add further facts, which
have a lower level of certainty. When all assertions have been processed,
the many inferences are reconciled to construct a spatial model of the
world which, following Occam's razor, is as simple as it can be,
consistent with the inferences. Only if this can be done without
inconsistency are the remaining data structures built: tables defined in
the source, and the parsing grammar. At last the rules are identified,
placed into relevant rulebooks, sorted by scope of applicability, and
compiled into I6 routines. The final task is to produce a report and an
index.

Though Inform uses propositions in predicate calculus as an intermediate
state to hold the meaning of sentences, it does not store knowledge that
way; though it makes elementary deductions and substitutions, it does not
contain a theorem-prover by unification. In the 1960s divide between the
"scruffy" school of storing domain-specific knowledge (McCarthy, Minksy,
Papert, et al.) versus the "neat" school of purely propositional logic
(Robinson, Kowalski, Colmerauer, et al.), Inform is scruffy. McCarthy
thought that a program with "common sense" is one which "automatically
deduces for itself a sufficiently wide class of immediate consequences of
anything it is told and what it already knows". He wrote that back in 1959
and the "neat" methods have become astonishingly powerful since then --
verifying the proof of the Prime Number Theorem via contour integration,
for instance -- but where the programmer knows in advance what sort of
knowledge the program will be dealing with, I think the scruffy methods
still have it. At any rate, Inform is a working program for its end users,
not an experiment in AI.

@h Organization into chapters.
"I can't help feeling," wrote Michael Frayn recently, "that if someone
had asked me before the universe began how it would turn out, I should have
guessed something a bit less like an old curiosity shop and a bit more like
a formal French garden -- an orderly arrangement of straight avenues,
circular walks, and geometrically shaped trees and hedges." I have an
uneasy feeling that the same might be said about Inform, but at its
most basic level, it is organised in six layers:

(L1) services for memory management, output streams, file input/output, and the
handling of text as a sequence of words;

(L2) the A-parser, which gathers the source text from its various locations
and divides it into sentences whose basic form can be recognised;

(L3) the S-parser, which resolves smaller excerpts of text into meanings, and
the necessary apparatus to describe, manipulate and compile these meanings;

(L4) the world-builder, which uses the A-parser and S-parser in combination
to break down the assertions in the source text to see what facts can be
inferred about the initial state of the world, and then assembles those into
a model, compiling it to a suitable Inform 6 description;

(L5) the change agent, compiling the phrases which are the means by which
the state of the model world changes at run-time; and organising the rules
which use those phrases, and the rulebooks holding those rules; and the
actions and activities which structure those rulebooks, and the run-time
grammar of commands which invoke those actions;

(L6) a thin control layer on top, following instructions from the
command line parameters and from the "template" which lays out Inform's
sequence of operation.

@h Choice of language.
NI is written in a literate programming extension of C called |inweb|.
Besides interspersing documentation, this also provides concise syntax
for parsing natural language; further apparent extensions, for logging
to the debugging log and for automated memory allocation, are in fact
provided by macros which are defined in the NI source.

To compile NI requires use of the Inform Tools, and in particular of
|inweb|. A manual for each of the tools is included in the NI source
(as documentation without code). Having compiled NI, it is important
to check the result with |intest|: testing of bug fixes requires each
change to be checked against a corpus of about 1200 test source texts.
As of November 2008, this takes more than 3 minutes even using all four
processors of a quad-3 GHz Mac Pro: it takes up to an hour on a Power
PC-equipped iMac G4.
