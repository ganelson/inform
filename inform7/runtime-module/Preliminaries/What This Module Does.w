What This Module Does.

An overview of the runtime module's role and abilities.

@h Prerequisites.
The runtime module is a part of the Inform compiler toolset. It is
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

@h The Inter hierarchy.
Inter code is an intermediate-level representation of the program we are to
compile. Inter can exist in binary or textual forms: see //inter: Manual// for
a general introduction to programming it in textual form. We will compile
binary Inter for speed, but they are really very similar.

The top of the final hierarchy might look like this:
= (text)
version number                  version 1
package type declarations       packagetype _plain
                                packagetype _code
                                ...
pragmas                         pragma target_I6 "$ALLOC_CHUNK_SIZE=32000"
                                ...
primitive declarations          primitive !font val -> void
                                ...
main                            package main _plain
									package veneer _module
									package generic _module
									package synoptic _module
									package basic_inform_by_graham_nelson _module
									package english_language_by_graham_nelson _module
									package standard_rules_by_graham_nelson _module
									package BasicInformKit _module
									package EnglishLanguageKit _module
									package WorldModelKit _module
									package CommandParserKit _module
									package connectors _linkage
									package template _plain
=
The modest amount of global material is the same on every compilation, and just
sets up our conventions. Inter also requires the top-level package to be |main|.
But it's our decision to then subdivide |main| up into packages called "modules",
which have the package type |_module|. These come from several sources:

(*) The |veneer| module is named after the veneer system in Inform 6, and provides
access to its (very modest) facilities.
(*) The |generic| module contains definitions which are built-in to the language:
for example, kinds like |K_number|.
(*) Each compilation unit of Inform 7 source text produces one module. See
//Compilation Units//; in particular, each included extension is a compilation unit.
(*) Each included kit of Inter code is a module.
(*) The |synoptic| module contains material which gathers up references from all
of the other modules.

Modules then have sub-departments called submodules, which are packages of type
|_submodule|. For example, the rules created in any given compilation unit live
in the |rules| submodule of its module; the properties in |properties|; and
so on. This is all very orderly, but there are a great many different structures
to compile for a large number of different reasons. The //Hierarchy// section
of code provides a detailed specification of exactly where everything goes.
