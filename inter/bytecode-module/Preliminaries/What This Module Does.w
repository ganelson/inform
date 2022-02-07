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

@h What is intermediate about inter.
This module is concerned with managing the //inter_tree// data structure in
memory, and with reading and writing it from and to the filing system.

An Inter tree is an expression of a single program. It's an intermediate state
between the source code for that program -- perhaps Inform 7 source text,
perhaps Inform 6-syntax source for a kit -- and the so-called "final" output,
typically a C or I6 program.

In conventional compiler design, a high-level language such as Swift or C# is
parsed first into an abstract syntax tree, or "AST", which is essentially a tree
representation of the syntax but is marked up with semantic information about
what everything in it means. This AST is then compiled down to an intermediate
representation, an "IR", which is a sort of structured list of still-abstract
operations to perform. The IR is then further converted to produce the compiler's
actual output. Thus:
= (text as BoxArt)
  source  ---->   AST   ------------>   IR  ---->  output (e.g., assembly language)
=
In the Inform family of tools, two languages have to be compiled: natural
language by //inform7// and more conventional C-like code by //inter//.
Having very different syntaxes, these have different ASTs:

(*) For I7, a |parse_node_tree|, managed by the //syntax// module.
(*) For Inter, an |inter_schema|, managed by the //building// module.

But these two compiler flows share the same IR -- an //inter_tree// provides the
intermediate representation for both:[1]
= (text as BoxArt)
                 "AST"                 "IR"
  source        syntax   
  text    --->   tree -------+
         INFORM7              \
                               \
                                ---->  Inter  ---->  output (e.g., C or Inform 6 code)
                               /       tree
  kit           Inter         /
  source  --->  schemas -----+
          INTER
=
Because we want to work with hybrid programs, part compiled by one flow and
part by the other, Inter is not quite as low-level as most IRs.[2] It still
contains a great deal of semantic markup, making analysis and optimisation
feasible. (Not very much of this is actually done at present, but see e.g.
//pipeline: Eliminate Redundant Operations Stage//.)

[1] In fact Inter schemas are so useful as a tool for generating short runs of
Inter that the main //inform7// compiler also uses them from time to time, but
not directly to represent the source text.

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
= (text as BoxArt)
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
within that package. For example, if a package |X| contains a definition of a
constant called |pi|, then the definition will occupy an Inter instruction
inside the package, and the identifier name |pi| will be an //inter_symbol//
recorded in its //inter_symbols_table//.
= (text as BoxArt)
    +-------------------------+ 
    | Package X               | 
    |                         | 
    | pi                      |
    | .....                   |
    | constant K_int32 pi = 3 |
    +-------------------------+
=
The symbols table for the root package is special, and represents global
meanings accessible everywhere. But they are used only for concepts needed
by Inter itself, such as the identities of primitives like |!add| or
|!printnumber|. In some sense, they specify the kind of Inter tree we have,
rather than anything about the program it represents. Material from that
program -- a variable, say, or a function -- is not allowed at the root level.

Symbols can be annotated in various ways. See //Annotations//. They also come
in several types, see //InterSymbol::get_type//, and can have a few flags,
see //InterSymbol::get_flag//.

@ The bytecode in a package can only refer to resources using symbols in that
same package. On the face of it, that means packages are so well sealed up
that they might as well all be independent programs, unable to see each other's
variables, constants and functions.

But that is not true because symbols in one package can be "wired" to symbols
in another:[1] see //The Wiring//. We write |S ~~> T| if the symbol |S| is "wired to"
|T|, and we understand this as meaning that |S| means whatever |T| does.
= (text as BoxArt)
    +-----------------+        +-------------------------------+
    | Package X       |        | Package Y                     |
    |                 |        |                               |
    |  earth ~~~~~~~~~~~~~~~~~~~~> earth                       |
    +-----------------+        | .....                         |
                               | variable K_int32 earth = 7    |
                               +-------------------------------+
=
In this example, the symbol |earth| in package |X| is undefined. Instead it is
wired to a different symbol of the same name in package |Y|, which is defined
as the name of a variable declared in that package. (The names do not have to
be the same, but they often are.)

Wiring is directional: |S ~~> T| very definitely does not mean that |T ~~> S|,
and indeed circuits are forbidden, because |S1 ~~> S2 ~~> ... ~~> S1| would
create a circular definition. To change metaphor for a moment, it's as if, on
looking up |S| in the index of a book, we found the entry "|S|, see |T|": we
then have to look up |T| to find, say, "|T|, 125", and turn to page 125. It
would be no good to find instead "|T|, see |S|".

[1] There are fleeting exceptional cases when a symbol can be wired to another
symbol in the same package, but those occur only with sockets and plugs in the
special connectors package, and only temporarily even then.

@ Special symbols called plugs and sockets are used to import or export meanings
from one tree of Inter code to a potential other tree, which will be "linked"
into it later on.

For example, //inform7// compiles a tree of Inter, but then //inter// links
this with a separately compiled Inter tree from //BasicInformKit//. Each both
imports from and exports to the other.
= (text as BoxArt)
    .....................           .......................
    .  Main tree        . ~~~~~~~~> . BasicInformKit tree .
    .                   .           .                     .
    .                   . <~~~~~~~~ .                     .
    .....................           .......................
=
It would be chaotic[1] to allow random symbols in packages all over each tree
to be wired directly to symbols in the other. Instead, every tree has a sort
of embassy package |/main/connectors| (a package called |connectors| which is
a subpackage of |main|) which acts as an intermediary.
= (text as BoxArt)
    ...............................       ..................................
    .  Main tree                  .       .  BasicInformKit tree           .
    .              +------------+ .       . +------------+                 .
    .  other       | connectors | .       . | connectors |                 .
    .  packages ~~~~~~~> plugs ~~~~~~~~~~~~~~> sockets ~~~~~>   other      .
    .            <~~~~ sockets <~~~~~~~~~~~~~~ plugs <~~~~~~~~~ packages   .
    .              +------------+ .       . +------------+                 .
    ...............................       ..................................
=
The connectors package contains only symbols, and they are all either "plugs" or
"sockets". A "plug" is made for every external meaning needed by a tree; a
"socket" is made for each meaning that the tree declares itself but wants to
make available for other trees to access. So if you know the contents of the
connectors package of a tree, you know everything it needs from outside (plugs)
and everything it offers to the outside (sockets).

For further zany ASCII-art like this, see //The Wiring//.

[1] And also slow, and prone to namespace collisions.

@ It is not literally the case that plugs in one tree are wired to sockets in
another, as the diagram above suggests. The actual wiring-together occurs only
when (part of) one tree is merged into another, in what is called //Transmigration//.

Transmigration is by definition the process of moving a package from one tree
to another. Almost the whole design of Inter is motivated by the need to make this
fast -- the hierarchies of packages, the use of wiring, and the existence of sockets
and plugs all came about working backwards from the goal of implementing
transmigration efficiently.

Transmigration is how the //pipeline// for processing Inter links a tree
produced by //inform7// to trees from kits produced by //inter//. This
diagram is also a little simplified, but the idea is right. We start with:
= (text as BoxArt)
    .........................         .........................
    .  Main tree            .         . BasicInformKit tree   .
    .  main                 .         . main                  .
    .    architectural      .         .    architectural      .
    .    basic_inform       .         .    BasicInformKit     .
    .    source_text        .         .    connectors         .
    .    connectors         .         .                       .
    .........................         .........................
=
where all of the substantive content of the BasicInformKit tree is in its
package |/main/BasicInformKit|. Transmigration simply moves that package,
the result being:
= (text)
    .........................         .........................
    .  Main tree            .         . BasicInformKit tree   .
    .  main                 .         . main                  .
    .    architectural      .         .    architectural      .
    .    basic_inform       .         .    connectors         .
    .    source_text        .         .                       .
    .    BasicInformKit     .         .                       .
    .    connectors         .         .                       .
    .........................         .........................
=
The original BasicInformKit tree is reduced to a husk and can be discarded.

Plugs and sockets are important here because when BasicInformKit moves to the
main tree, its plugs looking for meanings in that tree can now be connected
to sockets in it; and conversely, plugs in the main tree hoping to connect
to meanings in BasicInformKit can now connect to the relevant sockets.

There are conventions on what goes in the |main| package of each tree: see
//building: Large-Scale Structure// for more on that. (The |architectural|
package in each tree just makes some definitions establishing the size of
integers, and so on, and for these two trees whose definitions will just be
duplicates of each other.)

@h The warehouse and the building site.
There is a lot of memory to be managed here: Inter trees can be huge, though
there are never more than one or two in memory at once. 

In particular, each //inter_tree// structure contains two pools of data
besides the actual tree:[1]

(a) A "building site", which contains workspace data needed by the //building//
module. //building// is essentially a piece of middleware sitting on top of
this one, and making it easier for the compilers to use our facilities. We
will ignore the building site completely here: it's not our problem.

(b) A "warehouse", which very much is our problem: see //The Warehouse//.
This provides storage for strings, symbols tables and the like, assigning each
one an ID number. Resource number 178, for example, might be a |text_stream|
which is the content of some text literal in a function, while 179 might be
an //inter_symbols_table// belonging to some package.

[1] In real-life botany, trees do not have building sites or warehouses, but
mixing some metaphors cannot really be helped. Trees in nature do not grow
the way they do in computer science.

@h Nodes and instructions.
Each node in an Inter tree represents a single Inter instruction,[1] details of
which are stored as a stretch of bytecode in memory.

This use of both a tree and also a mass of binary bytecode is an attempt to
have our cake and eat it. The tree structure makes it quick and easy to splice,
cut and reorder code; the binary bytecode storage is quick to load from a file.
Still, the result is an unusual hybrid of a data structure.

For example, the tree might start out like this:
= (text as BoxArt)
							...	102	103	104	105	106	107	108	109	...
	node1  -----------------------> [.........]
		node2  -------------------------------> [.....]
		node3  ---------------------------------------> [.........]
=
Here |node1| represents an instruction, with the details stored at bytecode
locations 103 to 105; |node2| points to bytecode at 106 to 107, and so on.
But then we could decide, when optimising code, that we want instructions
|node2| and |node3| performed the other way round. Simple amendments to
the tree structure achieve this without needing to edit the bytecode:
= (text as BoxArt)
							...	102	103	104	105	106	107	108	109	...
	node1  -----------------------> [.........]
		node3  ---------------------------------------> [.........]
		node2  -------------------------------> [.....]
=
Indeed, we could decide that the instruction at |node2| is redundant and cut it:
= (text)
							...	102	103	104	105	106	107	108	109	...
	node1  -----------------------> [.........]
		node3  ---------------------------------------> [.........]
=
It doesn't matter that the resulting bytecode storage is all mixed up in
sequencing; the tree is what gives us the sequence of instructions, and the
order of words in bytecode memory is only significant within a single
instruction.

[1] Well, except for the root node, which has no real meaning. But there is
only one of those.

@ As these diagrams suggest, we can generate Inter instructions quite flexibly,
and are under no obligation to do so in sequence or all at once. (Indeed, we
can add entirely new instructions in the linking process or when optimising
code.)

So it is very useful to have a way to keep "bookmarks" in the tree, as positions
where we are currently writing code, and might want to return to. For this
purpose, we have the //inter_bookmark// type, which can represent any feasible
write position in the tree. (This is not the same thing as representing any
existing node in the tree: see //Bookmarks// for more.)

And this in turn allows for a simple API for //Node Placement//, allowing us
to move or remove nodes in the tree, and to keep track of cursor-like moving
bookmark positions when we generate a stream of new nodes and place them one
after another.
