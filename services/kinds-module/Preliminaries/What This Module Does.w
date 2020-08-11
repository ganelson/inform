What This Module Does.

An overview of the kinds module's role and abilities.

@h Prerequisites.
The kinds module is a part of the Inform compiler toolset. It is
presented as a literate program or "web". Before diving in:
(a) It helps to have some experience of reading webs: see //inweb// for more.
(b) The module is written in C, in fact ANSI C99, but this is disguised by the
fact that it uses some extension syntaxes provided by the //inweb// literate
programming tool, making it a dialect of C called InC. See //inweb// for
full details, but essentially: it's C without predeclarations or header files,
and where functions have names like |Tags::add_by_name| rather than |add_by_name|.
(c) This module uses other modules drawn from the //compiler//, and also
uses a module of utility functions called //foundation//.
For more, see //foundation: A Brief Guide to Foundation//.

@h Kinds, definiteness, and safety.
To begin, an overview of the type system used by Inform, since this module
is essentially an isolated implementation of it.

Inform is like most programming languages in that it deals with a rich
variety of values, that is, individual pieces of data. The number
17, the time "3:15 PM" and the "Entire Game" (a named scene) are all
examples of values. Except that Inform uses the word "kind" rather than
"type" for the different sorts of values which exist, I have tried to
follow conventional computer-science terminology in this source code.[1]

Kinds such as |number| are "definite", in that they unambiguously say what
format a piece of data has. If the compiler can prove that a value has a
definite kind, it knows exactly how to print it, initialise it and so on.
Variables, constants, literal values and properties all have definite kinds.

But other kinds, such as |arithmetic value|, merely express a guarantee
that a value can be used in some way. These are "indefinite". In some
contemporary languages this latter meaning would be a "typeclass"
(e.g., Haskell) or "protocol" (e.g., Swift) but not a "type".[2] The
ultimate in indefiniteness is the kind |value|, which expresses only that
something is a piece of data. Phrase tokens can be indefinite, as this
example shows:

>> To display (X - an arithmetic value):

[1] See for instance definitions in Michael L. Scott, "Programming Language
Pragmatics" (second edition, 2006), chapter 7. We will refer to "kind checking"
and "kind compatibility" rather than "type checking" and "type compatibility",
for example.

[2] Swift syntax blurs this distinction and (rightly) encourages users to
make use of protocols in place of types in, for example, function parameters.
We shall do the same.

@ The virtue of knowing that a piece of data has a given kind is that one
can guarantee that it can safely be used in some way. For example, it is
unsafe to divide by a |text|, and an attempt to do so would be meaningless
at best, and liable to crash the compiled program at worst. The compiler
must therefore reject any requests to do so. That can only be done by
constant monitoring of their kinds of all values being dealt with.

Inform is a high-level language designed for ease of use. Accordingly:

(a) Inform does not trade safety for efficiency, as low-level languages
like C do. There are no pointers, no arrays with unchecked boundaries, no
union kinds, no exceptions, no labels, and no explicit type coercions.

(b) All values are first-class, whatever their kind, meaning that they can
be passed to phrases, returned by phrases or stored in variables. All
copies and comparisons are deep: that is, to copy a pointer value
replicates its entire contents, and to compare two pointer values is to
examine their complete contents.

(c) All memory management is automatic. The author of an Inform source text
never needs to know whether a given value is stored as a word or as a pointer
to data on the heap. (Indeed, this isn't even shown on the Kinds index page.)

@h Kinds and knowledge.
Inform uses the kinds system when building its world model of knowledge, and
not only to monitor specific computational operations. For example, if the
source text says:

>> A wheelbarrow is a kind of vehicle. The blue garden barrow is a wheelbarrow.

then the value "blue garden barrow" has kind |wheelbarrow|, which is
within |vehicle|, within |thing|, within |object|. As this example suggests,
knowledge and property ownership passes through a single-inheritance hierarchy;
that is, each kind inherits directly from only one other kind.

@h A strongly typed language mixing static and dynamic typing.
Programming languages with types are often classified by two criteria.
One is how rigorously they maintain safety, with safer languages being
strongly typed, and more libertarian ones weakly typed. The other is when
types are checked, with statically typed languages being checked at compile
time, dynamically typed languages being checked at run-time. Both strong/weak
and static/dynamic are really ranges of possibilities.

(a) Inform is a strongly typed language, in that any source text which
produces no Problem messages is guaranteed safe.

(b) Inform is a hybrid between being statically and dynamically typed. At
compile time, Inform determines that the usage is either certainly safe or
else conditionally safe dependent on specific checks to be made at
run-time, which it compiles explicit code to carry out. Because of this,
Problem messages about safety violations can be issued either at compile
time or at run-time.

@h Casting and coercion.
Using data of one kind where another is expected is called "casting", and is
not always unsafe. Inform has no explicit syntax for casting, so all casts are
implicit -- that is, the user just goes ahead and tries it.

Casts can be either "converting" or "non-converting". In a non-converting cast,
the data can be left exactly as it is. For instance, a |vehicle| is stored at
run-time as an object number, and so is a |thing|, so any |vehicle| value is
already a |thing| value. But to use a "snippet" as a "text" requires substantial
code to extract the compressed, read-only string from the text and store it
instead as a list of characters on the heap -- this is a converting cast.[1]

[1] Some authors use the term "is-a" for what we call a non-converting cast.
Thus a |vehicle| "is-a" |thing|, but a |snippet| is not a |text|.

@ However, it's worth noting that while Inform source text is strongly
typed, Inter is mostly typeless language, so that safety can be circumvented
by defining a phrase inline using an insertion of Inter code. For instance:

>> To decide which text is (N - a number) as text: (- {N} -).

is analogous to a C function like so:
= (text as C)
	char *number_as_text(int N) {
		return (char *) N;
	}
=
This is a legal C program but completely unsafe to run, and even worse can be
done if C functions are used to wrap, say, x86 assembly language. Defining
phrases with Inter inclusions is the equivalent in Inform.

@h What this module offers.
The //kinds// module provides the Inform type system as a stand-alone utility,
and one way to toy with it in isolation is to run test "programs" through the
//kinds-test// tool. This is like a calculator, but for kinds and not values.
A "program" is a series of descriptions of kinds, and the output consists of
their evaluations. As a simple example:
= (text from Figures/basics.txt as REPL)
This is more of a test than it appears. In each line //kinds-test// has read in
the textual description in quotes, parsed it into a //kind// object using the <k-kind>
Preform nonterminal, then printed it out with //Kinds::Textual::write// (or
in fact by using the |%u| string escape, which amounts to the same thing).

@ A kind is represented by a //kind// object. Clearly some, like |number|, are
atomic while others, like |relation of numbers to texts|, are composite. Each
//kind// object is formally a "construction" resulting from applying a
//kind_constructor// to other kinds.[1] Each different possible constructor has
a fixed "arity", the number of other kinds it builds on. For example, to make
the kind |relation of texts to lists of times|, we need four constructions
in a row:
= (text)
	(nothing) --> text
	(nothing) --> time
	time --> list of times
	text, list of times --> relation of texts to lists of times
=
At each step there is only a finite choice of possible "kind constructions"
which can be made, but since there can in principle be an unlimited number
of steps, the set of all possible kinds is infinite. At each step we make
use of 0, 1 or 2 existing kinds to make a new one: this number (0, 1 or 2)
is the "arity" of the construction. These four steps have arities 0, 0, 1, 2,
and use the constructors "text", "time", "list of K" and "relation of K to L".

We will often use the word "base" to refer to arity-0 constructors
(or to the kinds which use them): thus, "text" and "time" are bases,
but "list of K" is not. We call constructors of higher arity "proper".

[1] This term follows the traditional usage of "type constructor". Haskell and
some other functional languages mean something related but different by this.

@ Here is //kinds-test// exercising the construction system. Note that
it has "functions" to extract the first and second term of a construction.
(The REPL language of //kinds-test// has quite a number of functions like
this, for testing different features of //kinds//.)

= (text from Figures/construction.txt as REPL)

@ In principle we could imagine constructors needing arbitrarily large
arity, or needing different arity in different usages, so the scheme of
having fixed arities in the range 0 to 2 looks limited. In practice we get
around that by using "punctuation nodes" in a kind tree. For example,
= (text)
	function K -> L
		CON_TUPLE_ENTRY
			text
			CON_TUPLE_ENTRY
				text
				CON_NIL
		number
=
represents |function (text, text) -> number|. Note two special constructors
used here: |CON_TUPLE_ENTRY| and |CON_NIL|. These are called "punctuation",
and cannot be expressed in Inform source text, or occur in isolation. No
Inform variable can have kind |CON_NIL|, for example.

@h Kind variables.
The 26 letters A to Z, written in upper case, can serve as kind variables --
placeholders for kinds. In practice A is best avoided because it looks too
much like an indefinite article, but it's very rare to need more than two.[1]
Phrase definitions in the standard Inform extensions use only K and L.

The meaning of, say, "list of K" depends on context. If K is currently set to,
say, |number|, then "list of K" means |list of number|; if it has no current
setting, then K remains a placeholder and the result is |list of K|. Note that
the same variable can occur more than once, as for example in |phrase K -> K|.
A kind with variables is always indefinite -- unless one knows what |K| will
be, there's no way to know what format of data a |list of K| value has.

A process called "substitution" enables |list of K| to be transformed to
|list of numbers|, or whatever may be. See //Kinds::substitute//.

The kinds module has to ask the parent tool for the current meanings of these
variables, which may have all kinds of scoping considerations beyond our
understanding here. See //Kinds::variable_from_context//. 

[1] Indeed, in early functional languages type variables were sometimes written
as |*|, |**|, |***|, and so on, a syntax making clear that nobody expected
to see many of them at once. Type variables always have very local scope.

@ In //kinds-test//, the 26 variables are initially unset, but can be given
values by writing |K = number|, or similar. For example:

= (text from Figures/variables.txt as REPL)

@h Conformance.
The set of all kinds has a sort of ordering[1] called "conformance": we write
$K\leq L$ if $K$ conforms to $L$. For any kinds $K, L, M$ not making use of
kind variables[2] it is true that:

(a) $K \leq K$ -- reflexivity.
(b) If $K\leq L$ and $L\leq M$ then $K\leq M$ -- transitivity.
(c) |K_nil| $\leq K \leq$ |value| -- there are top and bottom elements.
(d) If $K \leq L$ then a value of kind $K$ can always be substituted for a
value of kind $L$ without modification -- the Liskov substitution principle.[3]

|K_nil| is a kind which exists only for kind-checking purposes: it represents
"a member of the empty set", and therefore no value can ever have it. This
differs from |K_void|, which means "the absence of a value". A rule producing
no result, for example, has as production kind |K_void|.

[1] It need not be antisymmetric and only has joins to a limited extent, so
it is formally not a semilattice, nor even a partial ordering.

[2] Introducing kind variables complicates the picture, because whether or not
|list of K| conforms to |list of arithmetic values| depends on the current
value of |K| and therefore on the current context.

[3] Also known as strong behavioural subtyping. This only applies to definite
kinds, because no value ever has an indefinite kind.

@ Conformance is tested with the function //Kinds::conforms_to//, and the
following shows it in action.
 
= (text from Figures/conformance.txt as REPL)

Note that:
(a) |number| does not conform to |real number|. It can be cast to a real
number, and this happens implicitly in Inform, but the cast requires explicit
code; so it would violate Liskov substitution to have |number| $\leq$ |real number|.
(b) The "list of K" constructor is covariant, in that $K\leq L$ means
|list of K| $\leq$ |list of L|, whereas the "phrase K -> L" constructor
is contravariant in the first term, covariant in the second. See
//Latticework::order_relation// for more.
 
@ The indefinite |arithmetic kind| used by Inform is a good example of what
in other languages would be called a protocol. Here we see conformance:
 
= (text from Figures/av-conformance.txt as REPL)

Note that |arithmetic value| does not conform to |sayable value| -- it is true
that every value on which arithmetic can be performed can also be said, but
this is not why. This example shows that $K\leq L \Rightarrow K\leq M$ does
not necessarily mean that $L\leq M$.

@h Compatibility.
A related but different question is "compatibility". This asks whether a
value of kind $K$ can be used where $L$ is expected, but

(i) It is now okay if explicit code to perform a conversion would be needed;
(ii) There are now three possible answers -- always, never and sometimes, where
"sometimes" means that code can be compiled which would test compatibility at
run time rather than compile time;
(iii) |value|, anomalously, is compatible with everything.

Note that $K\leq L$ certainly means $K$ is compatible with $L$, but there
are many other compatible cases. For example:

= (text from Figures/compatibility.txt as REPL)

Note that |number| is compatible with |real number|. Run-time code will be
needed to convert the value, but the answer is "always". We also see that
"device" is always compatible with "thing" -- every device is a thing --
but also that "thing" is sometimes compatible with "device". If we pass a
thing to a function expecting to see a device, run-time code can check whether
the value passed is indeed a device, and reject the call with a run-time error
if not.

The anomaly over |value| looks and is odd.


@ We support a sort of hybrid kinds system, in which some base kinds have
subkinds and superkinds, while others do not.

In Inform, |object| sits at the top of a hierarchy of subkinds -- that is,
the kinds allowed to have subkinds are |object| itself, subkinds of |object|,
their subkinds in turn, and so on. In a typical work of parser IF, |woman|
is a subkind of |person| which is a subkind of |thing| which is a subkind of
|object|. On the other hand, |number| and |text|, for example, have no subkinds.
This means that |object| plays a unique role in the Inform type system, in a
way which pervades the compiler's source code. But the //kinds// module itself
takes no position on this, and |object| (which need not even exist) plays no
special role here.

Indeed, by default there are no subkinds at all, unless the parent tool uses
the |HIERARCHY_*_KINDS_CALLBACK| functions -- see //How To Include This Module//.
For convenience, //kinds-test// uses the same convention as Inform, i.e., that
only objects have subkinds.

@h Making new kinds.
When we need a new |kind *| value inside our code, what do we do? The
answer depends on how simple it is.
(a) If it's one of the standard built-in base kinds, we should just use a
preconstructed pointer: for example, |K_number| can be used for |number|.
See //Familiar Kinds//.
(b) And otherwise we call one of the functions //Kinds::base_construction//.
//Kinds::unary_construction// or //Kinds::binary_construction//, according
to whether our constructor has arity 0, 1 or 2.

For example, the following make valid representations of |text|, |list of numbers|
and |relation of numbers to texts| respectively:
= (text)
	K_text
	Kinds::unary_construction(CON_list_of, K_number)
	Kinds::binary_construction(CON_relation, K_number, K_text)
=
For the constructor values |CON_list_of| and so on, again see //Familiar Kinds//.

@h Where kind constructors come from.
The built-in kind constructors, such as "number" or "list of K", are not really
built in. They are read in from configuration files -- these are not written
in Inform source text, and look more like dictionaries of key-value pairs,
though they're simpler in syntax than XML.

Whole files can be read with //KindFiles::load//, or individual commands
issued with //KindCommands::despatch//.

Inform makes use of this by placing such files inside kits of Inter, because
in practice built-in kinds always need some run-time support written in Inter
code.

@h Making new kind constructors.
When Inform acts on sentences like these:

>> A weight is a kind of value. A mammal is a kind of animal.

it in fact makes new //kind_constructor// objects, not new //kind// objects.

"Weight" and "mammal" are base constructors, i.e., they have arity 0.
High-level Inform source is not currently able to define new constructors of
higher arity, though kind configuration files do.
