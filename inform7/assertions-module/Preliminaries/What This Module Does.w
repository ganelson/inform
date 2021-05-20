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
This module's task is to read the declarative sentences in the source text,
such as "Mrs Jones is wearing a trilby hat" or "Brightness is a kind of value",
which assert that something is true. These are converted into propositions
in predicate calculus, which are sent in a stream to the //knowledge// module.
Those propositions may be mutually inconsistent, or not even be self-consistent
or meaningful: but that is for //knowledge// to worry about. Our task is just
to provide a list of supposedly true statements.

Between the //linguistics// and //calculus// modules we have extensive
equipment for parsing regular sentences already, so it would seem simple
to act on a sentence like "Mr Herries knows Howarth." And so it would be if
people called "Mr Herries" and "Howarth" were already known to exist.
Unfortunately, this may be the first mention of them, and that makes things
much more complicated.

Even if they do exist, they may be referred to ambiguously. If there are
two different people both called Kassava, who is meant by "Carter knows
Kassava"? This depends on context: see //Name Resolution//.

Though it is rather under-developed at present, Inform also has minimal
support for "anaphora", that is, for cross-references between sentences using
pronouns such as "it". See //Anaphoric References//, but don't expect much.

@ So, then, top-level declarations are dealt with like so:
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

= (undisplayed text from Figures/Refine-BIP.txt)

[1] There really is an Ubuntu cola; it's a fair-trade product which it amuses my
more Linux-aware students to drink.

@h Special meanings.
In the same way that programming languages have a few "reserved words" which
cue up built-in language features, even though they may look like user-defined
functions or variables, Inform has a few verbs with "special meanings", which
make requests directly to the compiler. These occupy //Chapter 3//, which is
really just a catalogue of ways to ask for things.

All that we do is parse such sentences and then make a call to some
appropriate function, usually in one of the other modules. For example, the
section //New Activity Requests// dismantles sentences like "Counting is an
activity on numbers", but calls the //knowledge// module to do the actual
making of the new activity.

@h Regular meanings.
As noted above, //Assertions::make_coupling// is called on each regular
assertion: coupling being a lingistic term for placing subject and object into
a relationship with each other. What it does is to split into cases according to
the subject and object phrases of a sentence. These can take 12 different forms,
so there are $12\times 12 = 144$ possible combinations of subject with object,
and a $12\times 12$ matrix is used to determine which of 42 cases the sentence
falls into.

Each case then leads either to a proposition being formed, or to
a problem message being issued. Most of the easier cases are dealt with in
the (admittedly quite long) //Assertions// section, but harder ones are
delegated to the remaining sections in //Chapter 4//.

The brief story above implied that each sentence is turned into a single
proposition, as if this part of Inform can act as a sort of pipeline: text
in, proposition out. But it is not quite so simple, and for the hardest
sentences we must store notes on what to add later. For example, in
//Assemblies//, a sentence like "In every container is a coin" cannot
take immediate effect. It clearly creates a whole lot of coin instances,
but we don't yet know what is a container and what is not. That will
depend on conclusions to be drawn by the //knowledge// module later on.
Similarly, though a little easier, //Implications// like "Something worn is
usually wearable" do not immediately lead to propositions being drawn up.

@h Imperative definitions.
At the top level, Inform source text consists of more than just assertion
sentences: other constructions are made with different syntaxes. The most
obvious of these are "imperative definitions", which are lists of instructions
for what to do in different circumstances. They take the form
= (text as Inform 7)
a preamble text:
    first instruction;
    second instruction;
    ...
    last instruction.
=
The preamble is parsed into an //imperative_defn//, which falls into one of
a small range of //Imperative Definition Families//: the most important being
the //Rule Family//, for interactive-fiction-style rules, and //To Phrase Family//,
for declaring new "To..." phrases. Each definition is eventually joined to an
//id_body// representing the list of what to do, and this may be compiled to
one or more functions in the final output.

//Rules// need more infrastructure, since they must live inside //Rulebooks//
to take effect. Rulebooks contain //Booking Lists// of //Rule Bookings// to
hold these; it all takes some juggling because of the features Inform has to
allow authors to move rules around or customise their applicability. Finally,
we introduce //Activities//, which are really just triplets of related rulebooks.

@h Other gadgets.
And there are a few other constructions, too. Actions are left to //if: Actions Plugin//,
but even Basic Inform has //Tables// (and their //Table Columns//), along with
the quirkier inclusion of //Equations//.

@h Making use of the calculus module.
//Chapter 8// simply stocks up our predicate calculus system with some
basic unary and binary predicates, and provides a few shorthand functions
to make commonly-needed propositions (see //Calculus Utilities//).

More specialised predicates will also be added by other modules, so the
roster here is not complete, but these are the essentials.
