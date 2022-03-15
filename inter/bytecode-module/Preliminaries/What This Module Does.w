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

@h Textual, Binary, Memory.
Inter code has three representations: as a binary file, as a textual file,
and in memory -- a sort of cross-referenced form of binary. Binary or
textual inter files can be read in as memory inter, and memory inter can
be written out as either binary or textual files. Any inter program can
faithfully be represented in any of these forms:
= (text as BoxArt)
  textual                                  textual
  inter   ---+                       +---> inter
              \                     /
               \                   /
                ---->  memory  ----
               /       inter       \
  binary      /                     \      binary
  inter   ---+                       +---> inter
=
Textual Inter is human-readable, but binary Inter loads quickly. Either form,
as stored on an external file whose provenance we do not know, has to be treated
as suspect:

(*) Textual Inter might have been written by a human who blundered.
(*) Binary Inter might have been wrongly constructed by some compiler with
a bug in it.
(*) Binary Inter might have been maliciously constructed to crash us.
(*) Either form might be left over from a previous version of the Inform tool
chain when the specification of the Inter language was slightly different.

So we go to some trouble to verify the syntactic correctness of what is read
in, and use a shared system of //Inter Errors// to report defects. All binary
Inter files are marked with an explicit version number for the version of Inter
they were constructed by. Textual Inter files can also be so marked, but this is
optional, because there is a good chance the textual syntax will not have been
changed. See //The Inter Version//.

@h What textual Inter looks like.
There is a manual for writing //inter: Textual Inter//, and this may now be
worth skimming through. But here is a minimal example:
= (text as Inter)
package main _plain
	package Main _code
		code
			inv !enableprinting
			inv !print
				val "Hello, world.\n"
=
If we read this in and then write it out again, we find, perhaps surprisingly,
four extra instructions:
= (text as Inter)
packagetype _plain
packagetype _code
primitive !enableprinting void -> void
primitive !print val -> void
package main _plain
	package Main _code
		code
			inv !enableprinting
			inv !print
				val "Hello, world.\n"
=
This is because |packagetype| and |primitive| instructions are optional in textual
Inter. When we read |package Main _code|, for example, we deduce that a |_code|
package type is needed, and so we automatically declare it if it is not there
already; and similarly for any primitive like |!enableprinting|, provided that
it is one of those in the standard set. (See //building: Inter Primitives//.)
Nevertheless, those instructions are part of the program, which is why they
are printed out when we write it back as textual Inter.

|packagetype|, |primitive|, |package|, |code|, |inv| and so on are all examples
of //Inter Constructs//. Each has its own textual syntax. Most constructs give
rise to instructions -- for example, every line using the |val| construct
results in a single |VAL_IST| instruction in the program -- but just a few
"pseudo-constructs" such as |version| specify something else.

So it is not true that lines in textual Inter correspond exactly to the
instructions in a program, but it's very nearly true.

@h What binary Inter looks like.
The "hello world" program above would occupy a single //inter_tree// once loaded
in to memory.

The main organising idea of Inter trees is the //inter_package//. //Packages// are
like nested boxes: each one can hold either more packages, or Inter instructions
providing code or data, or both. In the case of "hello world": 
= (text as BoxArt)
....................................................
.  top-level material                              .
.  +--------------------------------------------+  .
.  | /main                               _plain |  .
.  |   +-------------------------------------+  |  .
.  |   | /main/Main                    _code |  |  .
.  |   | code in the Main function           |  |  .
.  |   +-------------------------------------+  |  .
.  +--------------------------------------------+  .
....................................................
=
Each package has a name, and its location can be identified by a "URL". For
example, |/main/BasicInformKit/properties| means "the package |properties|
inside the package |BasicInformKit| inside the package |main|". Every package
also as a "package type". (This is not the same thing as a data type.) |main|
always has type |_plain|; any package holding a function body has type |_code|.
All package types begin with an underscore |_|.

Material at the root level is implemented as if it were in a special package
called the "root package" (the dotted box around everything in the diagram),
which has the empty name and thus the URL |/|. But this is not really a
package, and follows different rules from all others.

For the conventions on how the Inform tool-chain sets up this hierarchy of
packages, see the //building// module: that's not our concern here. We
simply provide infrastructure allowing pretty general hierarchies to be made.

@h Data and types stored within bytecode.
Each instruction occupies a sequence of words called bytecode,[1] called its
"frame": see //Inter Nodes//. The opening word identifies which construct is
used: for example, if this is |PACKAGE_IST| then the instruction is a |package|.
What the remaining words mean depends on the construct, but here are some
typical ingredients:

(*) Many constructs -- |constant|, for example -- define a new symbol.
If so, the symbol ID -- or SID -- will be stored in one of the words;
this is the ID of the symbol in the //inter_symbols_table// belonging
to the package containing the instruction. Some constructs also contain
SIDs for other reasons: for example, |propertyvalue| needs to store the
SID of the property whose value is being recorded.

(*) Values in Inter occupy two consecutive words of bytecode, and these
are called "pairs": see //Inter Value Pairs//.

(*) Some constructs also need to store a type ID, or TID. See //Inter Data Types//.

With both values and types, we need to be able to express an enormous range
of possibilities. This seems impossible. For example, how can we fit the list
|{2, 3, 5, 7, 11, 13, 17, 19}| in two words, or the type |function int32 int2 -> void|
in just one?

In both cases the solution is the same: to use |constant| or |typename| to
assign a symbol to anything complicated, and then refer to that symbol. For
example, we can't have this:
= (text as Inter)
	val (list of int32) { 2, 3, 5, 7, 11, 13, 17, 19 }
=
because both the type and the value are too complicated. But we can have:
= (text as Inter)
	typename list_of_integers = list of int32
	constant (list_of_integers) primes = { 2, 3, 5, 7, 11, 13, 17, 19 }
	...
		val (list_of_integers) primes
=

[1] The term "bytecode" is a misnomer, since this is word-based, not byte-based.
But it is traditional and seems to have been used as far back as the mid-1960s.

@ Constants are useful also for providing metadata about the program. This
is not simply commentary: what makes it "meta" is that it does not literally
compile into the final output. For example:
= (text as Inter)
	constant lucky_number = 7
	constant ^special_constant = lucky_number
=
Here |lucky_number| can be used in the program whenever a value is needed. But
|^special_constant|, whose name begins with the magic metadata caret |^|, cannot
be used as a value. Instead, the idea is that it communicates something to the
code-generation code in //pipeline// and //final// -- indicating the significance,
purpose or origins of something in the program. (//inform7// produces a lot
of metadata like this.)

See //Metadata// for functions to access this metadata.

@h Symbols.
Names of constants, packages, primitives and so on are all examples of "symbols".

Packages provide //Symbols Tables//: in fact, each package has its own symbols
table, recording symbols and their meanings within that package. For example,
if a package |X| contains a definition of a constant called |pi|, then the
definition will occupy an Inter instruction inside the package, and the
identifier name |pi| will be an //inter_symbol// recorded in its //inter_symbols_table//.
= (text as BoxArt)
    +-----------------+ 
    | Package X       | 
    |                 | 
    | pi              |
    | .....           |
    | constant pi = 3 |
    +-----------------+
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

@h What memory Inter looks like.
Inter code stored in memory is not simply a binary copy of what the same thing
would be if stored in a binary Inter file: it is very heavily cross-referenced
for rapid access, editing and rearrangement.

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

@h Wiring.
The bytecode in a package can only refer to resources using symbols in that
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
                               | variable earth = 7            |
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
