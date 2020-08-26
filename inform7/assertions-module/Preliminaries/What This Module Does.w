What This Module Does.

An overview of the assertions module's role and abilities.

@h Prerequisites.
The assertions module is a part of the Inform compiler toolset. It is
presented as a literate program or "web". Before diving in:
(a) It helps to have some experience of reading webs: see //inweb// for more.
(b) The module is written in C, in fact ANSI C99, but this is disguised by the
fact that it uses some extension syntaxes provided by the //inweb// literate
programming tool, making it a dialect of C called InC. See //inweb// for
full details, but essentially: it's C without predeclarations or header files,
and where functions have names like |Tags::add_by_name| rather than just |add_by_name|.
(c) This module uses other modules drawn from the //compiler//, and also
uses a module of utility functions called //foundation//.
For more, see //foundation: A Brief Guide to Foundation//.

@h Assertions.
Top-level declarations are dealt with thus:
(*) The tree is subdivided into //runtime: Compilation Units//. The project's own
source text is one unit, as is each extension used.
(*) A minimal set of kinds, such as "number", verbs, such as "to mean", relations,
such as "meaning", and so on, is created. See in particular //assertions: Booting Verbs//.
(*) Three passes are made through the "major nodes" of the parse tree, meaning,
assertion sentences and top-level declarations of structures such as tables,
equations and rules. See //Passes through Major Nodes//.
(-0) During the "pre-pass" names of tables and other top-level structures are
recorded, and sentences are classified by //Classifying::sentence//. This is
done by asking the //linguistics// module to diagram them and determine whether
the meaning is "regular" -- a typical sentence asserting some relationship,
such as "the ball is on the table" -- or "special" -- a sentence with some
other purpose, such as "Test ... with ...", often but not always written in
the imperative.
(-1) During "pass 1", noun phrases in these assertion sentences are understood,
which may involve creating new instances or other values. For example, the
sentence "The fedora hat is on the can of Ubuntu cola" may cause new instances
"fedora hat" and "can of Ubuntu cola" to be created. This process is called
"refinement": see //Refine Parse Tree//, which calls //The Creator// to bring
things into being.[1] The function //Assertions::make_coupling// is then
called to draw out information from this pairing of values.
(-2) During "pass 2", //Assertions::make_coupling// is again called, and this
time is able to draw out relationships between values: for example, that the
hat is indeed spatially on top of the can.

= (undisplayed text from Figures/refine-simple.txt)

[1] There really is an Ubuntu cola; it's a fair-trade product which it amuses my
more Linux-aware students to drink.
