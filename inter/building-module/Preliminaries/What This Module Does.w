What This Module Does.

An overview of the building module's role and abilities.

@h Prerequisites.
The building module is a part of the Inform compiler toolset. It is
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

@h Services for builders.
This module is essentially middleware. It does none of the proactive business
of compiling, but instead acts as a bridge to the low-level functions in
the //bytecode// module, allowing them to be used with much greater ease.

In particular, Inter code is fundamentally a mass of |inter_package|s, which
cross-reference each other using |inter_symbol|s. But of course it cannot all
be made simultaneously. What we need is a more flexible way to describe things
in the Inter tree: both those which have already been made, and also those
which are yet to be made. So:
= (text)
				DEFINITELY MADE		PERHAPS NOT YET MADE
	PACKAGE		inter_package		package_request
	SYMBOL		inter_symbol		inter_name
=
So, for example, a //package_request// can represent |/main/synoptic/kinds|
either before or after that package has been built. At some point the package
ceases to be virtual and comes into being: this is called "incarnation".

And similarly for //inter_name//, which it would perhaps be more consistent
to call a |symbol_request|.

@ Since what is built by the code in this module is Inter code, which forms up
into trees, the metaphor should perhaps be "garden", but in fact we call a
context for making Inter a //building_site//.

