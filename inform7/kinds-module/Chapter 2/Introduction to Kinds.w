[Types::] Introduction to Kinds.

A general introduction to kinds.

@h Values, kinds and safety.
Inform is like most programming languages in that it deals with a rich
variety of values, that is, individual pieces of data. The number
17, the time "3:15 PM" and the "Entire Game" (a named scene) are all
examples of values. Every value is ultimately represented by a single word
in memory at run-time, thus occupying either 16 bits in the Z-machine or
32 bits in the Glulx virtual machine, depending on our compilation target.
Some values are self-contained enough that this single word is enough, and
are called word values; others, pointer values, use their word
to hold a pointer to a larger array of data stored somewhere else. For
instance, times are word values; lists of times are pointer values.

The usage of values is monitored by constant checking of the "kind of
value", or simply kind for short. Inform's "kind" is directly
equivalent to what most languages would call a "type". Except for the
use of "kind" instead of "type", I have tried to follow conventional
jargon in this source code: see for instance the definitions in Michael L.
Scott "Programming Language Pragmatics" (second edition, 2006),
chapter 7. Thus the process of making sure that a number is never used
where a scene is required, and so forth, is called kind checking
(rather than "type checking"), and is done by ensuring "kind
compatibility" (rather than "type compatibility"), but the idea is the
same. Successful kind checking ensures what is called safety.

Inform is a high-level language designed for reliability and ease of use.
Accordingly:

(a) Inform does not provide values of kinds used in low-level languages which
provide efficiency at the price of increased hazard and finickiness. There
are no pointers, no arrays with unchecked boundaries, no union kinds, no
exceptions, no labels, no jump or |goto| instructions.

(b) All values are first-class, whatever their kind. They can all
be passed to phrases, returned by phrases or stored in variables. All
copies and comparisons are deep: that is, to copy a pointer value
replicates its entire contents, and to compare two pointer values is to
examine their complete contents.

(c) All memory management is automatic. The author of an Inform source text
never needs to know whether a given value is stored as a word or as a pointer
to data on the heap. (Indeed, this isn't even shown on the Kinds index page.)

@h A strongly typed language mixing static and dynamic typing.
Programming languages with types are often classified by two criteria.
One is how rigorously they maintain safety, with safer languages being
strongly typed, and more libertarian ones weakly typed.
The other is when types are checked, with statically typed languages
being checked at compile time, dynamically typed languages being
checked at run-time. Both strong/weak and static/dynamic are really ranges
of possibilities.

(a) Inform is a strongly typed language, in that any source text which
produces no Problem messages is guaranteed safe -- but see the caveat
about Inform 6 inclusions below.

(b) Inform is a hybrid between being statically and dynamically typed. At
compile time, Inform determines that the usage is either certainly safe or
else conditionally safe dependent on specific checks to be made at
run-time, which it compiles explicit code to carry out. Because of this,
Problem messages about safety violations can be issued either at compile
time or at run-time.

@h Casting and coercion.
It is not always unsafe to use data of one kind in place of another. When this
is permitted, it is called an implicit cast, and we say the compiler is
casting the value. Casts can be either "converting" or "non-converting".
In a non-converting cast, the data can be left exactly as it
is. For instance, a "vehicle" is stored at run-time as an object number, and
so is a "thing", so any vehicle value is already a thing value. But to use a
"snippet" as a "text" requires substantial code to extract the compressed,
read-only string from the text and store it instead as a list of characters on
the heap -- this is a converting cast. At present, Inform uses converting
casts only when $K_F$ is the kind of a word value and $K_T$ is the kind of a
pointer value. But this may change.

Inform has no syntaxes to "coerce" data in violation of the ordinary
rules: thus, it's more strongly typed than C, where the syntax |(int) X|
forces a value |X| to be interpreted as an integer, with undefined
consequences. Any conversions must be performed by type-safe phrases given
definitions in the usual way.

However, it's worth noting that while Inform 7 source text is strongly
typed, Inform 6 is a typeless language, so that safety can be circumvented
easily by defining a phrase inline using an insertion of I6 code. For instance:

>> To decide which text is (N - a number) as text: (- \{N\} -).

is analogous to a C function like so:

	|char *number_as_text(int N) {|
	|	return (char *) N;|
	|}|

This is completely unsafe, even though the innocent user who calls
|number_as_text| may have no idea of the danger. Even worse things can
be done if C functions are used to wrap, say, x86 assembly language for
efficiency's sake. Defining phrases with Inform 6 inclusions is the
equivalent in Inform 7.

@ Kinds are formed from base kinds, complete in themselves, and
(proper) constructors, used to make more elaborate kinds out of
existing simpler ones. For example, "number" is a base kind and "list of
K" is a constructor, enabling us to make "list of numbers" or "list of
lists of texts".

Note that this term follows the traditional usage of the term "type
constructor", not the related but different meaning used by Haskell and
some other functional languages.

@ Base kinds form a hierarchy for purposes of inherited knowledge. Thus if the
source text says:

>> A wheelbarrow is a kind of vehicle. The blue garden barrow is a wheelbarrow.

then the value "blue garden barrow" has kind "wheelbarrow", which is
within "vehicle", within "thing", within "object", within "value".
As this example suggests, knowledge and property ownership passes through
a single-inheritance hierarchy; that is, each kind inherits directly from
only one other kind.

@ Inform also supports kinds of kinds, which are analogous to
typeclasses in Haskell. Examples of these are "arithmetic value" and
indeed simply "value". These can be constructed upon just as base kinds
can: for instance, "list of relations of numbers to values" can be
formed. We say that something like this is not definite, because it
can't be used as the kind of a variable. (A variable whose kind was
"value" could never be safe to use.) But in other respects indefinite
kinds are much like definite ones, and share the same data structure
within Inform (just as kinds of object share the same data structure as
actual objects).

All we can do with an indefinite kind is to test compatibility with it, but
that little is still very useful. We can determine whether a value can
have addition applied to it by testing whether its kind is compatible
with "arithmetic value", for instance. When this happens, we say that
the kind is an instance of the kind of kind.

Being an instance of something is not the same as inheriting from it.
It's meaningless to ask if "number" inherits from "arithmetic value",
because "arithmetic value" is indefinite, isn't a subject for
knowledge and doesn't have properties.

Whereas a kind can directly inherit from only one other kind, it can be
an instance of any number of kinds of kind. "Number" is an instance of
"value", "word value" and "arithmetic value", for example.

@ Some languages are designed with the mantra that "everything is a value",
but Inform is not. The use of a phrase such as

>> award 5 points;

does not evaluate to some "void" or "nil" kind (Inform doesn't have such
a thing), and the use of a condition such as

>> five women are in the Atrium

does not evaluate to a Boolean kind, even though Inform does have one
("truth state", to which conditions can be converted, but only
explicitly). I take the view that testing conditions and void execution
are conceptually different from evaluation, and that the "let's make
everything a value" design goal may make formal reasoning about programs
easier, but it also makes compilers accept a great deal of probably
mistaken code without issuing error messages -- a bad idea for Inform's
intended users.
