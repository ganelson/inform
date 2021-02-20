What This Module Does.

An overview of the core module's role and abilities.

@h Prerequisites.
The core module is a part of the Inform compiler toolset. It is
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

@h The Core.
Until 2020, the core module contained almost the entire compiler, but it is
now modularised in such a way that //core// itself only manages the sequence
of operations.

When //supervisor// decides that an Inform project is being compiled, it uses
the //words// and //syntax// modules to build a parse tree for the project and
any extensions it needs, and works out dependencies on kits of Inter code. We
don't need to deal with any of that. For //core//, the business starts when
//supervisor// calls //Task::carry_out//. The process is a long multi-stage one,
run as a production line: see //How To Compile// for a detailed list of steps,
but roughly:
(*) The //assertions// module converts top-level declarations -- sentences like
"The cat is in the hat" or "A truck is a kind of vehicle", for example -- into
a series of logical propositions, making heavy use of the //linguistics// and
//calculus// service modules.
(*) Those propositions are "asserted" as being true by the //knowledge// module,
which draws inferences and then reconciles these into a world model.
(*) Both of those modules are helped by the //values// module, which handles how
values and descriptions are parsed and then stored within the compiler.
(*) Imperative code inside phrase or rule definitions is the business of the
//imperative// module, the part of Inform most resembling a conventional compiler.
(*) The //runtime// module compiles run-time support functions and data structures
needed to make Inform's many concepts work at run-time.
(*) Last and least, the //index// module makes the browsable HTML-format index
for a compiled project, viewable in the Inform user interface applications.

There are then two expansion packs, as it were: the //if// and //multimedia//
modules, which do nothing essential but add support for interactive fiction
and for sound and images respectively. These are implemented very largely
as sets of //Plugins//, an architecture which allows the basic Inform
language to be made more domain-specific.
