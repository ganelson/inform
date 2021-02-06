What This Module Does.

An overview of the values module's role and abilities.

@h Prerequisites.
The values module is a part of the Inform compiler toolset. It is
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

@h For want of a better word.
What is a value? In the compiler for an orthodox programming language this is
relatively easy to answer,[1] but natural language often resists categorisation.
Even basic attempts to divide, say, nouns from verbs sometimes break down.

So although this module is called //values//, it actually looks after ways of
describing data in general, and this involves a wide range of concepts:
literals, named constants, variables, conditions, descriptions and so on. 
The umbrella term we will use is "specification", for want of anything better.

Until around 2016, the Inform source had a C type called |type_specification|,
since it had its origins in specifying the "type" of phrase tokens,[2] but "type
specification" was never a happy phrase, and coding with |type_specification|
was never really satisfactory. It has now been removed, and what we now call just
"specifications" are stored directly as fragments of the parse tree: that is,
as |parse_node| pointers. This new scheme removed complexity,[3] and is faster,
while consuming less memory. There are demerits too,[4] but the die is cast.

[1] Though, for example: are functions values? How about pointers to functions?
Parameters passed by reference, or pass-throughs? Are types also values? How
about type classes? Conditions? Exceptions? And if the answer is no, why can
they often be used as if it were yes?

[2] Inform phrases include even structural language features like "if", and
are not simply function calls: so their tokens can be conditions, lvalues,
or descriptions as well as rvalues. The "type" of such a token must therefore
be broader than simply a kind, because only values have kinds.

[3] A fairly convoluted conversion layer of code once existed in order to
turn pieces of parse tree into |type_specification| objects, but that entire
layer has now gone, and all of its bugs and edge cases went with it.

[4] The main demerit is that while all specifications are |parse_node|s, not
all |parse_node|s are specifications -- chapter subheadings, for example. So
the use of the |parse_node| type in source code does not communicate whether
we're trying to work with specifications, or doing general parsing.

@ Given that these disparate ideas are hard to unify, it might seem clearer
not to unify them at all -- if they are different concepts, represent that
by using different C types inside Inform.

The reason we need to unify is that Inform's concept of a phrase is much
broader than the concept of a function in a C-like language. Whereas an
argument of a C function must be an rvalue, Inform phrases can take arguments
(they are actually called tokens) which can be lvalues or descriptions. This
allows basic structural features such as "if" to be defined as phrases. But it
also means that we need a single type able to represent phrase token
requirements inside the Inform source code.

@h Taxonomy.
Specifications fall into four categories: rvalues, lvalues, conditions and
descriptions. Various functions, such as //Specifications::is_condition//,
exist to determine whether a given |parse_node| is one of these.

@ "Rvalues" specify pieces of data at run-time. Numbers, texts and instances
are all examples of rvalues, but so are usages of phrases to decide
values (i.e., function calls). See //Rvalues//.

These mostly come from parsing source text, but we can also manufacture them
directly. If we need the number 17 as a constant, for example, we can call
//Rvalues::from_int// to make a suitable |parse_node|, even if "17" is never
mentioned in the source text read in. And a wide range of other functions
exist to make constant rvalues of all kinds: //Rvalues::from_Unicode//,
for example.

@ "Lvalues" specify places to store data, such as variables, or table entries.
See //Lvalues//.

Functions such as //Lvalues::new_LOCAL_VARIABLE// allow us to take
a |local_variable| pointer and make an lvalue from it.

These traditional computer-science terms, "lvalue" and "rvalue", are based
on L for left, R for right, in an assignment operation like |v = 5|.
Here |v| is on the left and is an l-value: it's a variable, that is, a named
place to store data. The |5| is an r-value, and is the data which will be
stored. Of course, |v| can also occur on the right, as in the assignment
|w = v| where one variable is copied into another. But in this source code
we would call |v| an lvalue wherever it appears -- we mean only that it has
the potential to be written to.[1]

[1] We have to treat lvalues in this slightly unusual way because, contrary to
C-like languages, we have no syntactic way to mark that the name of a variable
means its value rather than its identity -- in C, this would be |name| versus
|&name|, with the "pointer to" marker |&| distinguishing the cases. We must
instead look to the context. Even C sometimes does that -- when C writes |v = 5|,
it would arguably be more consistent to say something like |store(&v, 5)|.

@ "Conditions" express a state of being which might, or might not, be true:
Inform allows these to be tested with "if" and brought about with "now".

Whereas in C-like languages conditions are rvalues and vice versa --
you can write |a = b == c|, or |if (7)| -- this often feels a little rum,
and in natural language even more so. In Inform, then, a condition is not an
rvalue, and an rvalue is not a condition.

Possible states are stored as propositions in predicate calculus with no
free variables: the function //Conditions::new_TEST_PROPOSITION// makes
a condition out of a proposition.

@ "Descriptions" express a state of something which is not directly specified,
which again might, or might not, be true. For example, "an open door" is
a description: some objects are, and some objects are not, open doors.

Descriptions are stored as propositions in predicate calculus with one
free variable: the function //Descriptions::from_proposition// makes
a description out of a proposition.

Note that the name of a kind, such as "number", can also be seen as a
description: //Descriptions::from_kind// turns $K$ into the description $K(x)$.

@h Dash.
Suppose that a specification has been written in a particular context. Does
it make sense there? This is what the //Dash// algorithm exists to check.

If all we needed to know was "is it okay to store an rvalue of kind $K_1$ in
an lvalue of kind $K_2$", then we could just use the functions in
//kinds: The Lattice of Kinds//. But specifications are more than just rvalues,
so they need a wider set of checks. For example, if an author writes "if $X$",
Dash has to check that $X$ is indeed a condition. Inform authors get to
know Dash pretty well, because it can issue nearly 100 different problem
messages, including most of the ones authors run into most often.

Though Dash is used mainly to check tokens of phrases, it can also be used
to verify individual specifications with direct function calls: for example,
//Dash::check_condition// and //Dash::check_value// determine whether a
specification is indeed a condition or an lvalue/rvalue of a given kind.

Dash aims to be pragmatic rather than clever[1], and its goal is to issue
good problem messages rather than, say, to have good running time on heroically
large composite expressions -- those essentially never arise in natural language.

[1] In particular it does not need a constraint-satisfaction algorithm, as is
needed by the almost-Turing complete type systems in some languages.

@h Literals.
//Chapter 3// then works through different ways to write constant values in
source text, which we loosely call "literals". What makes them literal is that
they explicitly state values rather than simply naming them. Thus "15" is a
literal but "the score" is not, even if it is a variable which happens to have
the value 15.

The linguistics module has built-in support for parsing numbers, so we don't
need to do that basic digit-parsing here: see //linguistics: Cardinals and Ordinals//
for details. But we will also want //Literal Lists// in braces, //Unicode Literals//
for character names, and //Times of Day//; and also user-defined notations
for user-defined kinds. For example:

>> 16:9 specifies an aspect ratio.

would establish a new notation for the kind "aspect ratio", supposing that
had already been created. See //Literal Patterns//.

@h Grammar.
What remains, then, is the general Preform grammar for Inform's expressions
and conditions -- the so-called "S-parser", since it produces specifications.
This is the content of //Chapter 4//.
