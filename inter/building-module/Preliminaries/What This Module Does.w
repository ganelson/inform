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
(c) This module uses other modules drawn from the compiler (see //structure//), and also
uses a module of utility functions called //foundation//.
For more, see //foundation: A Brief Guide to Foundation//.

@h Introduction.
This module is essentially middleware. It acts as a bridge to the low-level
functions in the //bytecode// module, allowing them to be used with much
greater ease and consistency.

This module needs plenty of working data, and stashes that data inside the
|inter_tree| structure it is working on: in a component of that structure called
a //building_site//. Whereas the main data in an |inter_tree| affects the meaning
of the tree, i.e., makes a difference as to what program the tree represents,
the contents of the //building_site// component are only used to make it, and
are ignored by the //final// code-generator.

@h Large-scale architecture.
An inter tree is fundamentally a set of resources stored in a nested set of
|inter_package| boxes.

(*) The following resources are stored at the root level (i.e., not inside of
any package) and nowhere else:
(-*) Package type declarations. See //LargeScale::package_type//.
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

@ Inter code is a nested tree of boxes, |inter_package|s, which contain Inter
code defining various resources, cross-referenced by |inter_symbol|s.

But this tree cannot be magically made all at once. For much of the run of
a tool like //inform7//, a partly-built tree will exist, and this introduces
many potential race conditions -- where, for example, a call to function F
cannot be made until F itself has been made, and so on.

We also want to avoid bugs where one part of the compiler thinks that F will
live in one place, and another part thinks it is somewhere else.

To that end, we use a flexible way to describe naming and positioning
conventions for Inter resources (such as our hypothetical F). In this system,
a //package_request// stands for a package which may or may not already exist;
and an //inter_name//, similarly, is a symbol which may or may not exist yet.
This enables tools like //inform7// to build up elaborate if shadowy worlds
of references to tree positions which will be filled in later.
= (text)
				DEFINITELY MADE		PERHAPS NOT YET MADE
	PACKAGE		inter_package		//package_request//
	SYMBOL		inter_symbol		//inter_name//
=
So, for example, a //package_request// can represent |/main/synoptic/kinds|
either before or after that package has been built. At some point the package
ceases to be virtual and comes into being: this is called "incarnation". But
code in //inform7// using package requests never needs to know when this takes
place, and will function equally well before or after -- so, no race conditions.

And similarly for //inter_name//, which it would perhaps be more consistent
to call a |symbol_request|. But "iname" is now a term used almost ubiquitously
across //inform7// and //inter//, and it doesn't seem worth renaming it now.

@h Medium-scale blueprints.
The above systems make nested packages and symbols within them, but not the
actual content of these boxes, or the definitions which the symbols refer to.
In short, the actual Inter code.

The straightforward way to compile some Inter code is to make calls to functions
in //Producing Inter//, which provide a straightforward if low-level API. For example:
= (text as InC)
	inter_name *iname = HierarchyLocations::iname(I, CCOUNT_PROPERTY_HL);
	Produce::numeric_constant(I, iname, K_value, x);
=
Note that we do not need to say where this code will go. //Producing Inter//
looks at the iname, works out what package request it should go into, incarnates
that into a real |inter_package| if necessary, then incarnates the iname into
a real |inter_symbol| if necessary; and finally emits a |CONSTANT_IST| in the
relevant package, an instruction which defines the symbol.

And similarly for emitting code inside a function body, though then it is
necessary first to say what function (which can be done by calling //Produce::function_body//
with the iname for that function). For example:
= (text as InC)
	Produce::inv_primitive(I, RETURN_BIP);
	Produce::down(I);
		Produce::val(I, K_value, InterValuePairs::number(1));
	Produce::up(I);
=

@ But that is a laborious sort of notation for what, in a C-like language, would
be written just as |return 1|. It would be very painful to have to implement
kits such as BasicInformKit that way. Instead, we write them in a notation which
is very close indeed[1] to Inform 6 syntax.[2]

This means we need to provide what amounts to a pocket Inform-6-to-Inter compiler,
and we do that in this module, using a data structure called an //inter_schema// --
in effect, an annotated syntax tree -- to represent the results of parsing Inform 6
notation. For example, this:
= (text as InC)
	inter_schema *sch = ParsingSchemas::from_text(I"return true;", where);
	EmitInterSchemas::emit(I, ..., sch, ...);
=
generates Inter code equivalent to the example above.[3] But the real power of
the system comes from:

(a) The ability to handle much larger passages of I6 notation - for example, a
function body 10K long -- in an acceptably speed-efficient way; and

(b) The ability to subsctitute values in for placeholders.

As an example of (b), an //inter_schema// is how //inform7// compiles so-called
inline phrase definitions such as:
= (text as Inform 7)
	To say (L - a list of values) in brace notation:
		(- LIST_OF_TY_Say({-by-reference:L}, 1); -).
=
Here, the text |LIST_OF_TY_Say({-by-reference:L}, 1);| is passed through to
//ParsingSchemas::from_text// to make a schema. When the phrase is invoked,
//EmitInterSchemas::emit// is used to generate Inter code from it; and a
reference to the list passed to the invocation as the token |L| is substituted
for the braced clause |{-by-reference:L}|.[4] Schemas are also used as convenient
shorthand in the compiler to express how to, for example, post-increment a
property value.

[1] Some antique syntaxes, such as |for| loops broken with semicolons not colons,
are missing; so are some hardly-used directives; and the superclass |::| operator;
and built-in compiler symbols relevant only to particular virtual machines, such
as |#g$self|, are not there. But really, you will never notice they are gone.

[2] Using Inform 6 notation was very convenient in the years 2004-17, when Inform
generated only I6 code: it became more problematic in 2018, when Inter instructions
were needed instead, and much of this module was written as a response.

[3] Skipping over some of the arguments to the emission function, which basically
tell us how to resolve identifier names into variables, arrays, and so on.

[4] These braced placeholders are, of course, not Inform 6 notation, and
represent an extension of the I6 syntax.

@h Small-scale masonry.
Finally, there are also times when we want to compile explicit code, one
Inter instruction at a time, and for this the Produce API is provided.

This API keeps track of the current write position inside each tree (using
the //code_insertion_point// system), and then provides functions which call
down into //bytecode// for us, making use of that write position. So, for
example, we can write:
= (text as InC)
	Produce::inv_primitive(I, RETURN_BIP);
	Produce::down(I);
		Produce::val(I, K_value, InterValuePairs::number(17));
	Produce::up(I);
=
to produce the Inter code:
= (text as Inter)
	inv !return
		val K_unchecked 17
=
Note the use of //Produce::down// and //Produce::up// to step up and down the
hierarchy: these functions are always called in matching ways.

@ The //pipeline// module makes heavy use of the Produce API. Surprising,
//inform7// calls it in only a few places -- but in fact that is because
it provides still another middleware layer on top. See //runtime: Emit//.
But it's really only a very thin layer, allowing the caller not to have to
pass the |I| argument to every call (because it will always be the Inter tree
being compiled by //inform7//). Despite appearances, then, Produce makes all
of the Inter instructions generated inside either //inter// or //inform7//.
