What This Module Does.

An overview of the imperative module's role and abilities.

@h Prerequisites.
The imperative module is a part of the Inform compiler toolset. It is
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

@h About this layer of Inform.
The //runtime// and //imperative// modules (see //imperative: What This Module Does//)
jointly make up a layer of Inform whose task is to take the conceptual structures
now build up -- rules, phrases, tables, the world model -- and turn them into
Inter code. For the bigger picture, see //compiler//.

Neither module is in charge of the other. //runtime// makes extensive use of
//imperative: Functions//, while //imperative// uses //runtime: Emit// and
//runtime: Hierarchy//. The demarcation line is that:

(*) //imperative// provides general mechanisms for compiling Inter functions,
and uses them to construct the functions needed for rules and phrases.
(*) //runtime// organises the hierarchical structure of the Inter code being
made, and compiles the Inter representations of data structures like rulebooks
or tables, and any Inter functions needed to manage them at runtime.
