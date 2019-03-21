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

defines the primitive |!move| as something which consumes two values and
produces none. (Further details on this will appear in the section on code
packages.)

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

Convention. A conspicuous feature of inter code generated by Inform is that
many symbols have the form |P_Name|, where |P| is some prefix letter showing
what sort of thing is referred to: for example, symbols for kinds all begin
with the prefix |K| (|K_number|, |K_text|, and so on), while variables
begin with |V|, instances with |I|, properties with |P|, and so on. This
is all simply a convention used by Inform for clarity and to reduce the
risk of accidental name clashes; it is not required by inter.

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

@h Splats.
The special statement |splat "TEXT"| or |splat ANNOTATION "TEXT"| allows
raw Inform 6 code (or potentially raw code for any language) to be included
verbatim in inter. Splat is not a respectful term, and nor does it deserve
one. The annotation can be any of: |IFDEF_PLM|, |IFNDEF_PLM|, |IFNOT_PLM|,
|ENDIF_PLM|, |IFTRUE_PLM|, |CONSTANT_PLM|, |ARRAY_PLM|, |GLOBAL_PLM|,
|STUB_PLM|, |ROUTINE_PLM|, |ATTRIBUTE_PLM|, |PROPERTY_PLM|, |VERB_PLM|,
|FAKEACTION_PLM|, |OBJECT_PLM|, |DEFAULT_PLM|, |MYSTERY_PLM|.

Convention. Inform creates no splats, except as needed to convert
Inform 6 template code into inter, in the code-generator.
