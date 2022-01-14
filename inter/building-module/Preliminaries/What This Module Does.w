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
This module is essentially middleware. It acts as a bridge to the low-level
functions in the //bytecode// module, allowing them to be used with much
greater ease and consistency.

In particular, the functions here enforce a number of conventions about how an
Inter tree is laid out. Indiscriminate use of //bytecode// functions would allow
other layouts to be made, but we want to be systematic. 

This module needs plenty of working data, and stashes that data inside the
|inter_tree| structure it is working on: in a compoment of that structure called
a //building_site//. Whereas the main data ih an |inter_tree| affects the meaning
of the tree, i.e., makes a difference as to what program the tree represents,
the contents of the //building_site// component are only used to make it, and
are ignored by the //final// code-generator.

@h Structural conventions.
An inter tree is fundamentally a set of resources stored in a nested set of
|inter_package| boxes.

(*) The following resources are stored at the root level (i.e., not inside of
any package) and nowhere else:
(-*) Package type declarations. Inter can support a nearly arbitrary set of
different package types, and the //bytecode// functions make no assumptions.
In //Package Types//, however, we //present a single standard set of package
types used by Inform code.
(-*) Primitive declarations. See //Inter Primitives//. Again, Inter can in
principle support a variety of different "instruction sets", but this module
presents a single standardised instruction set.
(-*) Compiler pragmas. These are marginal tweaks on a platform-by-platform basis
and use of them is minimal, but see //LargeScale::emit_pragma//.

(*) Everything else is inside a single top-level package called |main|, which
has package type |_plain|.

(*) |main| contains only packages, and of only two types:
(-*) "Modules", which are packages of type |_module|. These occur nowhere else
in the tree.
(-*) "Linkages", which are packages of type |_linkage|. These occur nowhere else
in the tree.

(*) //inform7// compiles the material in each compilation unit to a module
named for that unit. That is:
(-*) The module |source_text| contains material from the main source text.
(-*) Each extension included produces a module, named, for example,
|locksmith_by_emily_short|.

(*) Each kit produces a module, named after it. Any Inter tree produced by
//inform7// will always contain the module |BasicInformKit|, for example.

(*) //inform7// generates an additional module called |generic|, holding
generic definitions -- material which is the same regardless of what is
being compiled.

(*) //inform7// generates an additional module called |completion|, holding
resources put together from across different compilation units.[1]

(*) //inter// generates an additional module called |synoptic|, made during
linking, which contains resources collated from or cross-referencing
everything else.

(*) Modules contain only further packages, called "submodules" and with the
package type |_submodule|. The Inform tools use a standard set of names for
such submodules: for example, in any module the resources defining its
global variables are in a submodule called |variables|. (If it defines no
variables, the submodule will not be present.)

(*) There are just two different linkages -- packages with special contents
and which the linking steps of //pipeline// treat differently from modules.
(-*) |architecture| has no subpackages, and contains only constant definitions,
drawn from a fixed and limited set. These definitions depend on, and indeed
express, the target architecture: for example, |WORDSIZE|, the number of
bytes per word, is defined here. Symbols here behave uniquely in linking:
when two trees are linked together, they will each have an |architecture|
package, and symbols in them will simply be identified with each other.
Thus the |WORDSIZE| defined in the main Inform 7 tree will be considered
the same symbol as the |WORDSIZE| defined in the tree for BasicInformKit.
(-*) |connectors| has no subpackages and no resources other than symbols.
It holds plugs and sockets enabling the Inter tree to be linked with other
Inter trees; during linking, these are removed when their purposes has been
served, so that after a successful link, |connectors| will always be empty.

See //Large-Scale Structure// for the code which builds all of the above
packages (though not their contents).

[1] Ideally |completion| would not exist, and everything in it would be made
as part of |synoptic| during linking, but at present this is too difficult.

@ In particular, Inter code is fundamentally a mass of |inter_package|s, which
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

