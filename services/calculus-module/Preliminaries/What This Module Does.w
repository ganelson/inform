What This Module Does.

An overview of the calculus module's role and abilities.

@h Prerequisites.
The calculus module is a part of the Inform compiler toolset. It is
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

@h Notation.
This module deals with propositions in predicate calculus, that is, with
logical statements which are normally written in mathematical notation. To
the end user of Inform, these are invisible: they exist only inside the
compiler and are never typed in or printed out. But for the debugging log,
for unit testing, and for the literate source, we need to do both of these.

The following demonstrates the notation being read in, and then written back
out, by the //calculus-test// module. As with //kinds-test//, this is a REPL:
a read-evaluate-print-loop tool, which reads in calculations, performs them,
and prints the result. Here, the "calculations" consist only of being told
exactly what the proposition is, and then printing it back.

= (text from Figures/notation.txt as REPL)
