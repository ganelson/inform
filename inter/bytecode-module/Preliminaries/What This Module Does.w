What This Module Does.

An overview of the bytecode module's role and abilities.

@h Prerequisites.
The bytecode module is a part of the Inform compiler toolset. It is
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

@h WHat is intermediate about inter.
This module is concerned with managing the //inter_tree// data structure in
memory, and with reading and writing it from and to the filing system.

An Inter tree is an expression of a single program. It's an intermediate state
between the source code for that program -- perhaps Inform 7 source text,
perhaps Inform 6-syntax source for a kit -- and the so-called "final" output,
typically a C or I6 program.

In conventional compiler design, a high-level language such as Swift or C# is
parsed first into an abstract syntax tree, or AST, which is essentially a tree
representation of the syntax but is marked up with semantic information about
what everything in it means. This AST is then compiled down to IR, intermediate
code reducing the AST to a list of still-abstract operations to perform. The IR
is then then further converted to actual code for a particular processor. So
the flow might look like this:
= (text)
  Swift
  source  ---->   AST   ------------>   IR  ---->  Assembly language
=
In the Inform family of tools, two languages have to be compiled: natural
language by Inform 7, and also kit source by Inter (the tool), which looks more
like a conventional programming language. Having very different syntaxes, they
have different ASTs:

(*) For I7, it's a |parse_node_tree| structure: see the //syntax// module.
(*) For Inter, it's an |inter_schema| structure: see the //building// module.

But these two compiler flows share the same IR -- an //inter_tree// provides the
intermediate representation for both:[1]
= (text)
                 "AST"                 "IR"
+-----------------------+
| source        syntax  |
| text    --->   tree -------+
|-----------------------+     \
 INFORM7                       \
                                ---->  Inter  ---->  C, I6, or others
+-----------------------+      /
| kit           inter   |     /
| source  --->  schemas -----+
+-----------------------+
 INTER
=
Because we want to work with hybrid programs, part compiled by one flow and
part by the other, Inter is not quite as low-level as most IRs.[2] It still
contains a great deal of semantic markup, making analysis and optimisation
feasible. (Not very much of this is actually done at present, but see e.g.
//pipeline: Eliminate Redundant Operations Stage//.)

[1] This diagram is a slight simplification, because //inform7// also makes
use of Inter schemas when generating code for certain low-level operations,
such as storing values in properties. But the big picture is right.

[2] Though IRs vary considerably. Microsoft's Common Intermediate Language (CIL),
used as a back-end by C#, has quite low-level bytecode but stores it in a
highly structured object-oriented way.

@ Inter trees can be saved out as files in either binary or textual form;
binary form being much faster to load back in, textual much easier to read
and check over.

It is even possible to write Inter programs by hand, using a text editor. To
get a sense of what that looks like, see the manual //inter: Textual Inter//.

@h Packages.
The main organising idea of Inter trees is the //inter_package//. //Packages// are
like nested boxes: each one can hold either more packages, or Inter instructions
providing code or data, or both.

Each package has a name, and its location can be identified by a "URL". For
example, |/main/BasicInformKit/properties| means "the package |properties|
inside the package |BasicInformKit| inside the package |main|".
= (text)
....................................................
.  top-level material                              .
.  +--------------------------------------------+  .
.  | /main                                      |  .
.  |   +-------------------------------------+  |  .
.  |   | /main/BasicInformKit                |  |  .
.  |   | +---------------------------------+ |  |  .
.  |   | | /main/BasicInformKit/variables  | |  |  .
.  |   | +---------------------------------+ |  |  .
.  |   | +---------------------------------+ |  |  .
.  |   | | /main/BasicInformKit/properties | |  |  .
.  |   | +---------------------------------+ |  |  .
.  |   | ...                                 |  |  .
.  |   +-------------------------------------+  |  .
.  |   ...                                      |  .
.  +--------------------------------------------+  .
....................................................
=
Material at the root level is implemented as if it were in a special package
called the "root package" (the dotted box around everything in the diagram),
which has the empty name and thus the URL |/|. But this is not really a
package, and follows different rules from all others.

For the conventions on how the Inform tool-chain sets up this hierarchy of
packages, see the //building// module: that's not our concern here. We
simply provide infrastructure allowing pretty general hierarchies to be made.

@h Symbols.
Packages provide //Symbols Tables//: in fact, each package has its own
symbols table, which records identifier names and their meanings
within that package. For example, if a package contains a definition of a
constant called |pi|, then the definition will occupy an Inter instruction
inside the package, and the identifier name |pi| will be an //inter_symbol//
recorded in its //inter_symbols_table//.

The symbols table for the root package is special, and represents global
meanings accessible everywhere. But they are used only for concepts needed
by Inter itself, such as the identities of primitives like |!add| or
|!printnumber|. In some sense, they specify the kind of Inter tree we have,
rather than anything about the program it represents. Material from that
program -- a variable, say, or a function -- is not allowed at the root level.

@h The warehouse and the building site.
There is a lot of memory to be managed here: Inter trees can be huge, though
there are never more than one or two in memory at once. 

In particular, each //inter_tree// structure contains two pools of data
besides the actual tree:[1]

(a) A "building site", which contains workspace data needed by the //building//
module. That module is essentially a piece of middleware sitting on top of
this one, and making it easier for the compilers to use our facilities. We
will ignore the building site completely here: it's not our problem.

(b) A "warehouse", which does belong to this module: see //The Warehouse//.
This provides storage for strings, symbols tables and the like, assigning each
one an ID number. Resource number 178, for example, might be a |text_stream|
which is the content of some text literal in a function, while 179 might be
an //inter_symbols_table// belonging to some package.

[1] In real-life botany, trees do not have building sites or warehouses, but
mixing some metaphors cannot really be helped. Trees in nature do not grow
the way they do in computer science.
