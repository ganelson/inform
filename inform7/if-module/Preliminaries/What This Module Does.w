What This Module Does.

An overview of the if module's role and abilities.

@h Prerequisites.
The if module is a part of the Inform compiler toolset. It is presented as a
literate program or "web". Before diving in:
(a) It helps to have some experience of reading webs: see //inweb// for more.
(b) The module is written in C, in fact ANSI C99, but this is disguised by the
fact that it uses some extension syntaxes provided by the //inweb// literate
programming tool, making it a dialect of C called InC. See //inweb// for
full details, but essentially: it's C without predeclarations or header files,
and where functions have names like |Tags::add_by_name| rather than just |add_by_name|.
(c) This module uses other modules drawn from the compiler (see //structure//), and also
uses a module of utility functions called //foundation//.
For more, see //foundation: A Brief Guide to Foundation//.

@h So many plugins.
This module consists entirely of plugins, and when they are all inactive,
as for example with a Basic Inform project, it's as if the module does not exist
at all: it does nothing.

The module is divided into four substantive parts, which form Chapters 2 to 5,
and are largely independent of each other:

(*) //Chapter 2: Bibliographic Data// is a single plugin, "bibliographic data".
This manages metadata on projects, notably the Interactive Fiction ID, and
follows a number of Internet standards for such things. //Release Instructions//
collates release details included in the source text, and acts as a bridge to
the releasing agent //inblorb//.
(*) //Chapter 3: Space and Time//, by contrast, is made up of many individual
plugins, which can independently be active or not: collectively they form the
usual model world for interactive fiction, but it's possible, for example,
to remove the concept of a geographical map, or of scenes, and still have
the rest.
(*) //Chapter 4: Actions// is the single plugin "actions", which provides a
framework for how agents in the world model can perform simple tasks such as
picking things up, or going from place to place.
(*) //Chapter 5: Command Parser// is the single plugin "parsing", and
provides for command parsing. Projects using other mechanisms for having
the reader interact with them do not need this, and can deactivate the plugin.
