Textual Inter.

A specification of the inter language, as written out in text file form.

@h Textual, Binary, Memory.
Inter code has three representations: as a binary file, as a textual file,
and in memory -- a sort of cross-referenced form of binary. For speed, the
Inform compiler generates memory inter directly, and code-generates from
that, so that the inter is normally never written out to disc. When Inter
performs a conversion, it loads (say) textual inter into memory inter, then
writes that out as binary inter.

The following specification covers the inter language in its textual form:
a UTF-8 encoded text file which conventionally takes the file extension
".intert".

It should be stressed that inter is designed for inspection -- that is, for
people to be able to read. It's not intended as a programming language for
humans to write: the code is verbose and low-level. The idea is that inter
code will be written by programs (such as Inform), but that this code will
be possible for humans to check.

Like assembly language, inter code is line-based: each line is a "statement".
Lines can be of arbitrary length. A line beginning with a |#| (in column 1) is
a comment, and blank lines are ignored.

The term "name" below means a string of one or more English upper or lower
case letters, underscores, or digits, except that it must not begin with
a digit.

As in Python, indentation from the left margin is highly significant, and
should be in the form of tab characters.

Inform follows certain conventions in the inter that it writes, but these
conventions are not part of the specification, and may change. Any paragraph
below which begins with "Convention" records the current practice.

There are three forms of statement: global statements, data statements, and
code statements. We will take these in turn.

@h Global statements.
These statements must appear first in the file, and must be unindented.
There are only four of these:

@ |version NUMBER| indicates that the file was written in that version of
the inter language. At present there has only ever been one version, but
that may not always be true. A |version| statement number must come before
anything else, even other global statements; in particular, there cannot be
two such statements in the same file.

Convention. Inform always opens with the statement: |version 1|

@ |packagetype NAME| declares that |NAME| is the name of a type of package. 
Packages are the main hierarchical organisation for inter files, as we
will see below. Each package has a type as well as a name, and the type
must be one of those declared like this. 

For example, |packagetype _adjective| creates |_adjective| as a possible type
for packages in this file.

The first two package types must be |_plain| and |_code|, in that order.

Convention. All of Inform's package type names begin similarly with an
underscore, to prevent name clashes. Inform uses package types semantically,
to show what kind of thing is being defined in the content of a particular
package. This makes it easier to search a large inter repository for all of
the adjective defimitions, for example: we just need to look for packages of
type |_adjective|.

@ |pragma TARGET "WHATEVER"| does not change the meaning of the inter file;
it simply provides pragmatic advice to the eventual compiler of code
generated from this file. |TARGET| indicates the context for which this
is intended; at present, the only possible choice is |target_I6|, meaning,
"if you are compiling me to Inform 6".

Convention. Inform uses this to pass on ICL (Inform Command Language)
commands to Inform 6, such as memory settings or command-line switches.
For example,

	|pragma target_I6 "$MAX_LABELS=200000"|

(This would be meaningless if we were compiling to some other format.)

@ |primitive PRIMITIVE IN -> OUT| defines a new code statement -- if inter
were an assembly language, these would be the opcodes. For example,

	|primitive !move val val -> void|

defines the primtive |!move| as something which consumes two values and
produces none. |IN| can either be |void| or can be a list of one or more
terms which are all either |ref|, |val| or |code|. |OUT| can be either
|void| or else a single term which is either |ref| or |val|. For
example,

	|primitive !plus val val -> val|

says that |!plus| consumes two values and produces a new one, while

	|primitive !ifelse val code code -> void|

says that |!ifelse| consumes a value and two blocks of code, and produces
nothing. Of course, |!plus| adds the values, whereas |!ifelse| evaluates
the value and then executes one of the two code blocks depending on
the result. But at this stage, we don't see the meaming of these
primitives, only their prototypes.

The third term type, |ref|, means "a reference to a value", and is in
effect an lvalue rather than an rvalue: for example,

	|primitive !pull ref -> void|

is the prototype of a primitive which pulls a value from the stack and
stores it in whatever is referred to by the |ref| (typically, a variable).

Convention. Inform defines a standard set of around 90 primitives. Although
their names and prototypes are not part of the inter specification as such,
you will only be able to use Inter's "compile to I6" feature if those are
the primitives you use, so in effect this is the standard set. Details of
these primitives and what they do will appear below.

@h Package declarations.
After the global area, an inter file should declare a package called |main|,
which must have the package type |_plain|.

The statement |package NAME TYPE| declares a new package, and the |TYPE|
must be one of those declared by |packagetype| statements in the global area.

The declaration line for a package begins at the level of indentation of
the package's owner. For |main|, it should be unindented, and this is the
only package allowed to appear at the top level: all other packages should
be inside |main| in some way.

The contents of the package are then one tab stop in from the declaration. Thus:

	|package main _plain|
	|    ...|
	|    package m1_RBLK1 _code|
	|        ...|
	|    package m1_RBLK2 _code|
	|        ...|

Here, |main| contains two sub-packages, |m1_RBLK1| and |m1_RBLK2|, and
indentation is used to show which package a statement belongs to.

@ After the declaration line, a package definition continues with a set
of symbols definitions. In effect, this is the symbols table for the
package written out explicitly. Each definition is a |symbol| line, in
one of these three forms:

	|symbol private TYPE NAME|
	|symbol public TYPE NAME|
	|symbol external TYPE NAME == SYMBOL|

For example,

	|symbol public misc MEMORY_HEAP_SIZE|
	|symbol external misc AllowInShowme == /main/resources/template/AllowInShowme|

|private| means that the meaning and existence of |NAME| are invisible
from outside the current package; |public| means that other packages are
allowed to refer to |NAME|; and |external| means that this package is
making just such a reference, and that |NAME| in this package is equivalent
to |SYMBOL|, defined elsewhere. It is possible that |SYMBOL| points only to
another symbol which is also |external|, so that we then have to follow
another link to find the original non-external definition. However, it is
a requirement that this process must eventually end. It would be illegal
to write

	|package main _plain|
	|    package A _plain|
	|        symbol external misc S == /main/B/T|
	|    package B _plain|
	|        symbol external misc T == /main/B/S|

The symbol |TYPE| must be one of four possibilities:
(a) |label|, used to mark execution positions in code packages;
(b) |package|, meaning that this is the name of a package;
(c) |packagetype|, meaning that this is a package type;
(d) |misc|, meaning "anything else" -- most symbols have this type.

The run of |symbol| declarations at the top of a module can become quite
long, since it has to give a complete description of all symbols used inside
the module, whether they're defined internally or externally. As a
convenience for people writing test cases by hand, it's in fact optional
to predeclare a symbol in textual inter provided that this symbol is
declared earlier in the file than its first use. However, when Inter
writes out a textual inter file, it always writes the symbols table out
in full, and never exercises this option.

@ Where a local symbol is being equated with an external one, the |SYMBOL|
given is a sort of URL showing the package to look inside. Thus

	|/main/resources/template/AllowInShowme|

means "the symbol |AllowInShowme| in package |template| inside package
|resources| inside package |main|".

@ Optionally, a |private| or |public| symbol can also specify a name it
wishes to be given when the Inter is translated into some other language
(i.e., Inform 6 or similar). This is written like so:

	|symbol private TYPE NAME -> TRANSLATION|

So, for example,

	|symbol public misc launcher -> launcher_U32|

Symbols tabulated as |external| cannot be marked in this way, but of course
the original definition (to which the external link eventually leads) can be.
For example,

	|package main _plain|
	|    package A _plain|
	|        symbol external misc S == /main/B/T|
	|    package B _plain|
	|        symbol public misc T -> FancyName |

would result in the names |S| and |T| both being compiled to the name
|FancyName| in the final code.

Convention. Inform mostly makes use of this feature of inter late in code
generation, essentially to avoid namespace clashes in the final output code,
but it also needs to use it to implement low-level features of the Inform
language such as:

>> The marked for listing property translates into I6 as "workflag".

@ With the package and its symbol table declared, we can then get on with
the definitions of what is inside the package.

A package with the special type |_code| must contain only code statements;
all other packages must contain only data statements. Note that |package|
is itself a data statement, and it follows that |_code| packages cannot
contain sub-packages, but that all others can.

"Data" is a slightly loose phrase for what data statements convey: it
includes metadata, and indeed almost anything other than actual executable
code.

@h Kinds and values.
Inter is a very loosely typed language, in the sense that it is possible
to require that values conform to particular data types. As in Inform, data
types are called "kinds" in this context (which usefully distinguishes them
from "types" of packages, a completely different concept).

No kinds are built in: all must be declared before use. However, these
declarations are able to say something about them, so they aren't entirely
abstract. The syntax is:

	|kind NAME CONTENT|

The |NAME|, like all names, goes into the owning package's symbol table;
other packages wanting to use this kind will have to have an |external|
symbol pointing to this definition.

|CONTENT| must be one of the following:

(a) |unchecked|, meaning that absolutely any data can be referred to by this type;
(b) |int32|, |int16|, |int8|, |int2|, for numerical data stored in these numbers
of bits (which the program may choose to treat as character values, as flags,
as signed or unsigned integers. and so on, as it pleases);
(c) |text|, meaning text;
(d) |enum|, meaning that data of this kind must be equal to one (and only one)
of the enumerated constants with this kind;
(e) |table|, a special sort of data referring to tables made up of columns each
of which has a different kind;
(f) |list of K|, meaning that data must be a list, each of whose terms is
data of kind |K| -- which must be a kind name known to the symbols table
of the package in which this definition occurs;
(g) |column of K|, similarly, but for a table column;
(h) |relation of K1 to K2|, meaning that data must be such a relation, in the
same sort of sense as in Inform;
(i) |description of K|, meaning that data must be a description which either
matches or does not match values of kind |K|;
(j) |struct|, which is similar to |list of K|, but which has entries which do
not all have to have the same kind;
(k) and |routine|, meaning that data must be references to functions.

For example:

	|kind k_boolean int2|
	|kind k_list_of_bool list of k_boolean|
	|kind K_grammatical_tense enum|

@ In the remainder of this specification, |VALUE| means either the name of
a defined |constant| (see below), or else a literal.

A literal |int32|, |int16|, |int8|, or |int2| can be written as any of the
following:
(a) a decimal integer which may begin with a minus sign (and, if so, will be
interpreted as twos-complement signed);
(b) a hexadecimal imteger prefixed with |0x|, which can write the digits
|A| to |F| in either upper or lower case form, but cannot take a minus sign;
(c) a binary integer prefixed with |0b|, which cannot take a minus sign.

For example, |-231|, |0x21BC| and |0b1001001| are all valid. If the literal
supplied is too large to fit into the kind, an error is thrown.

A literal |list| is writtem in braces: |{ V1, V2, ..., Vn }|, where |V1|, 
|V2| and so on must all be acceptable literals for the entry kind of the
list. For example, |{ 2, 3, 5, 7, 11, 13, 17, 19 }|. The same notation is
also accepted for a |struct|, a |column| or a |table|. For example:

	|constant C_egtable_col1 K_column_of_number = { 1, 4, 9, 16 }|
	|constant C_egtable_col2 K_column_of_colour = { I_green, undef, I_red }|
	|constant C_egtable K_table = { C_egtable_col1, C_egtable_col2 }|

A list-like notation can also be used for a "calculated literal". This is
a single value, but which we may not be able to evaluate at inter generation
time. For example, if we do not yet know the value of |X|, we can write
|sum{ X, 1 }| to mean |X+1|. A present, addition is the only operation
catered for in this way.

A literal |text| is written in double quotes, |"like so"|. All characters
within such text must have Unicode values of 32 or above, except for tab (9),
writtem |\t|, and newline (10), written |\n|. In addition, |\"| denotes a
literal double-quote, and |\\| a literal backslash, but these are the only
backslash notations at present allowed.

There are then a number of notations which look like texts, prefixed by
indicative characters.

|r"text"| makes a literal real number: the text is required to take the
same form as a literal real number in Inform 6. The result is valid
for use in an |int32|, where it is interpreted as a float. For example,
|r"$+1.027E+5"|.

|dw"text"| is meaningful only for interactive fiction, and represents the
command parser dictionary entry for the word |text|. This is equivalent
to the Inform 6 constant |'text//'|. |dwp"text"| is the same, but pluralised,
equivalent to Inform 6 |'text//p'|. Again, these can be stored in an |int32|.

|&"text"| makes a literal value called a "glob". This is not a respectful
term, and nor does it deserve one. A glob is a raw Inform 6 expression,
which can't (easily) be compiled for any other target, but is simply
copied literally through. Its kind is |unchecked|, so it can be used
absolutely anywhere.

|^"text"| is not really a value at all, and is called a "divider". This
is really a form of comment used in the middle of long lists. Thus the
list |{ 1, 2, ^"predictable start", 3721, -11706 }| is actually a list of four values
but which should be compiled on two lines with the comment in between:

	|1, 2, ! predictable start|
	|3721, -11706|

(As unnecessary as this feature seems, it does make the code produced by
Inform look a lot more readable when it finally reaches Inform 6.)

The literal |undef| can be used to mean "this is not a value".

Convention. It is intended that Inform will never make use of globs, but
at present about 30 globs persist in typical inter produced by Inform.
None of these are generated by Inform 7 as such: they all arise from the
oddball expressions in the template code which the code generator can't
(yet) assimilate.

Inform generates |undef| values to represent missing entries in tables,
but otherwise makes no use of them.

@h Enumerations and instances.
As noted above, some kinds marked as |enum| are enumerated. This means
that they can have only a finite number of possible values, each of which
is represented in textual inter by a different name.

These values are called "instances" and must also be declared. For example:

	|kind K_grammatical_tense enum|
	|instance I_present_tense K_grammatical_tense|
	|instance I_past_tense K_grammatical_tense|

It is also possible to specify numerical values to be used at run-time:

	|instance I_present_tense K_grammatical_tense = 1|

If so, then such values must all be different (for all instances of that kind).
Enum values must fit into an |int16|.

Enumerations, but no other kinds, may have "subkinds", as in this example:

	|kind K_object enum|
	|kind K1_room <= K_object|

This creates a new |enum| kind |K1_room|. Values of this are a subset of
the values for its parent, |K_object|: thus, an instance of |K1_room| is
automatically also an instance of |K_object|. This new subkind can itself
have subkinds, and so on.

@h Constants.
A constant definition assigns a name to a given value: where that name is
used, it evaluates to this value. The syntax is:

	|constant NAME KIND = VALUE|

where the value given must itself be a constant or literal, and must conform
to the given kind. As always, this is conformance only in the very weak
system of type checking used by Inter: if either the value or the constant
has an |unchecked| kind, then the test is automatically passed.

For example,

	|kind K_number int32|
	|constant favourite_prime K_number = 16339|

Constants can have any kind, including enumerated ones, but if so then that
does not make them instances. For example,

	|kind K_colour enum|
	|instance C_red K_colour|
	|instance C_green K_colour|
	|constant C_favourite K_colour = C_green|

does not make |C_favourite| a new possible colour: it's only a synonym for
the existing |C_green|.
