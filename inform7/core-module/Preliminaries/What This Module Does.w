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
The //core// module is the largest and most important part of //inform7//,
while not being included in either //inbuild// or //inter//. It manages the
entire process of compiling an Inform 7 project, doing a good deal of the
work itself, but also calling numerous other modules. Though in theory it is
second-in-command to the //supervisor// module, it always gets essentially the
same, quite vague, orders to follow, so //core// has wide authority.
