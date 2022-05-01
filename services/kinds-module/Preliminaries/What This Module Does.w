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
(c) This module uses other modules drawn from the compiler (see //structure//), and also
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

@ One caveat: Inform provides low-level features allowing Inter code to be
injected directly into the compiler's output, bypassing all kind checking.
For instance:

>> To decide which text is (N - a number) as text: (- {N} -).

is analogous to a C function like so:
= (text as C)
	char *number_as_text(int N) {
		return (char *) N;
	}
=
This is a legal C function but the deliberate disregard of type safety -- in
the use of the |(char *)| cast notation -- is a kind of waiver, where the
author chooses to accept the risk. In a similar way, there are no victims of
Inform's |(-| and |-)| notation, only volunteers.

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

@h Dimensional analysis.
Inform subjects all calculations with its "quasinumerical" kinds -- basically,
all those on which calculation can be performed -- to dimensional checking.

Dimension in this sense is a term drawn from physics. The idea is that when
quantities are multiplied together, their natures are combined as well as
the actual numbers involved. For instance, in
$$ v = f\lambda $$
if the frequency $f$ of a wave is measured in Hz (counts per second), and
the wavelength $\lambda$ in m, then the velocity $v$ must be measured
in m/s: and that is indeed a measure of velocity, so this looks right.
We can tell that the formula
$$ v = f^2\lambda $$
must be wrong because it would result in an acceleration. Physicists use the
term "dimensions" much as computer-scientists use the word "type", and Inform
follows suit.

See //Dimensions// for a much fuller discussion.

@h Conformance and compatibility.
One kind $K$ "conforms to" another kind $L$ if values of $K$ can always be used
where values of $L$ are expected. For example, in a typical work of IF produced
by Inform, the kind |vehicle| conforms to |thing|. This idea can also apply
to kinds of kinds: |number| conforms to |arithmetic value| which conforms to
|sayable value|, for example. See //The Lattice of Kinds// for how conformance
produces a hierarchical order among possible kinds.

Conformance is an "is-a" relationship: thus a |vehicle| can safely be stored in
a variable of kind |thing| because a vehicle is a thing. But a |number| cannot
be stored in a |real number| variable directly -- integers and real numbers
have completely different data representations at run-time, so the compiler
must generate conversion code (a "cast") to adapt the |number| value before
it is stored. Sometimes this is possible, sometimes not. A kind $K$ is
"compatible" with $L$ if it is. Clearly conformance implies compatibility,
but not vice versa.

@ The kind |object| is of great significance to Inform, partly for historical
reasons, partly because run-time code represents object values in a unique way.
The lattice of subkinds of |object| is very well-behaved, in that any two
subkinds will always be compatible. All of this means that |object| plays a
unique role in Inform's kind hierarchy.

But not to us. In the //kinds// module, |object| is a kind like any other. It
need not even exist.

@h Kind variables.
The 26 letters A to Z, written in upper case, can serve as kind variables --
placeholders for kinds.[1] In practice A is best avoided because it looks too
much like an indefinite article, but it's very rare to need more than two.[2]
Phrase definitions in the standard Inform extensions use only K and L.

The meaning of text like "list of K" depends on context. If K is currently set to,
say, |number|, then "list of K" means |list of number|; if it has no current
setting, then K remains a placeholder and the result is |list of K|. Note that:
(a) The same variable can occur more than once, as in |phrase K -> K|.
(b) Variables can be constrained to conform to something, as in |arithmetic value of kind K|,
where |K| remains a placeholder but can only be a kind conforming to |arithmetic value|.
(c) If |K| remains unknown then any kind using |K| is necessarily indefinite.
So a variable cannot have the kind |list of K|, for example.
(d) A process called "substitution" enables |list of K| to be transformed to
|list of numbers|, or whatever may be. See //Kinds::substitute//.

[1] Using letters seemed the nearest point of contact with natural
language conventions. In English, we do say pseudo-algebraic things like
"So, let's call our spy Mr X." -- or at least we do if we lead slightly
more exciting lives than the present author. The use of letters emphasises
that this is some kind of reference, not a direct identification.

[2] At one time I was tempted by the syntax used in the early functional
programming language Miranda (1985), which uses rows of asterisks |*|, |**|,
|***|, and so on as needed -- a syntax making clear that nobody expected
to see many of them at once. But asterisks in natural language have an air
of censorship, of something that must not be named: compare Stéphanie de
Genlis's gothic novella "Histoire de la duchesse de C***" (1782).

@h The kinds-test REPL.
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

@ In //kinds-test//, the 26 variables are initially unset, but can be given
values by writing |K = number|, or similar. For example:

= (text from Figures/variables.txt as REPL)

@h Overview of facilities.
A kind is represented by a |kind *| pointer. These actually point to
small trees of //kind// objects -- see //Kinds// -- because many kinds are
constructed out of others: thus |list of texts| is the result of applying the
"list of ..." construction to the kind |text|.[1] Kinds not constructed from
other kinds are called "base kinds". Briefly:

(*) By convention the |NULL| pointer means "kind unknown".

(*) Commonly needed base kinds, like |number| or |text|, have global variables
set equal to them, like |K_number| or |K_text|. See //Familiar Kinds//.

(*) Kinds can otherwise be made with //Kinds::base_construction//,
//Kinds::unary_con// or //Kinds::binary_con//. For example,
|list of numbers| and |relation of numbers to texts| can be made by:
= (text)
	Kinds::unary_con(CON_list_of, K_number)
	Kinds::binary_con(CON_relation, K_number, K_text)
=

(*) Kinds for functions are a bit laborious to put together, so //Kinds::function_kind//
is a convenience.

(*) As with kinds, commonly needed constructors, like |CON_list_of| or
|CON_relation|, are available as global values. Again see //Familiar Kinds//.

(*) Two different |kind *| values can represent the same kind, so don't test
whether $K$ is the same kind as $L$ by the pointer comparison |K == L|. Instead
call //Kinds::eq// or its negation //Kinds::ne//.

(*) Call //Kinds::conforms_to// to test whether $K$ conforms to $L$. This is
either true or not true. To find a kind able to hold values of either $K$ or $L$,
call //Latticework::join//.

(*) Call //Kinds::compatible// to test whether $K$ is compatible with $L$,
but note that the reply is three-valued: always, sometimes or never.

(*) Inform makes frequent use of "weakening", where we deliberately weaken a
kind (i.e., make it less restrictive) by ignoring distinctions between subkinds
of some $W$. For example, the weakening of |list of things| with respect to
|object| is |list of objects|. See //Kinds::weaken//.

(*) An extensive API of functions is provided in //Using Kinds// to test whether
given kinds have given properties. The most important is //Kinds::Behaviour::definite//,
which determines whether $K$ is definite.

(*) New base kinds can be created either by calling //Kinds::new_base//,[2] or in
the process of reading in "Neptune files".[3] New constructors can only
be made the latter way. See //NeptuneFiles::load//, which sends individual commands
to //NeptuneFiles::read_command//, which in turn deals with the low-level code in
the //Kind Constructors// section.[4] See //A Brief Guide to Neptune// for a
manual to the syntax.

(*) It is possible to move kinds within the lattice of kinds, i.e., to change
their hierarchical relationship, even after creation. See //Kinds::make_subkind//.
Inform does this very sparingly and only with kinds of object.[5]

(*) Use //Kinds::Dimensions::arithmetic_on_kinds// to determine what kind, if
any, results from performing an arithmetic operation.

[1] "List of ..." is what is called a "kind constructor". This term follows the
traditional usage of "type constructor", but note that Haskell and some other
functional languages mean something related but different by this.

[2] So, for example, Inform acts on text like "A weight is a kind of value." by
calling //Kinds::new_base//.

[3] Inform's built-in kinds like |number| or |text| all come from such files,
not by calls to //Kinds::new_base//.

[4] Inform stores Neptune files inside kits of Inter, because in practice
built-in kinds always need run-time support written in Inter code, so the two
naturally go together.

[5] For instance, after "Puzzle is a kind of thing. Toy is a kind of thing.
Puzzle is a kind of toy.", Inform moves |puzzle| to be a subkind of |toy|,
when it had been created as a subkind of |thing|. It is very arguable that
allowing this is a bad idea, but that ship has sailed.
