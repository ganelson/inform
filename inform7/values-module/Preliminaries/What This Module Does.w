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

@h There Is No Good Word For This.
What is a value? In the compiler for an orthodox programming language this is
relatively easy to answer,[1] but natural language swirls with meanings which
sometimes seem to resist categorisation. Even the most basic attempts to divide,
say, nouns from verbs sometimes break down.

This module is called //values//, but in fact it handles forms of expression
much broader than that, and there isn't really a good umbrella term to cover
them: literals, named constants, variables, conditions, descriptions and so on.
Until around 2016, the Inform source had a C type called |type_specification|
which unified all of these, but "type specification" was never a good phrase --
|"fish"| or |17 + 2| do not really specify types, after all.

And so we ended up with just "specification". There is, however, no unifying
|specification| type any longer. Instead, all specifications are stored as
fragments of the parse tree: that is, as |parse_node| pointers. This new
scheme removed complexity,[2] and is faster, while consuming less memory;
it has demerits as well,[3] but is now fairly settled.

[1] Though, for example: are functions values? How about pointers to functions?
Parameters passed by reference, or pass-throughs? Are types also values? How
about type classes? Conditions? Exceptions? And if the answer is no, why can
they often be used as if it were yes?

[2] A fairly convoluted conversion layer of code once existed in order to
turn pieces of parse tree into |type_specification| objects, but that entire
layer has now gone, and all of its bugs and edge cases went with it.

[3] The main demerit is that while all specifications are |parse_node|s, not
all |parse_node|s are specifications -- chapter subheadings, for example. So
the use of the |parse_node| type in source code does not communicate whether
we're trying to work with specifications, or doing general parsing.

@h Taxonomy.
We might start with lvalues and rvalues. These traditional terms
are based on L for left, R for right, in an assignment operation like |v = 5|.
Here |v| is on the left and is an l-value: it's a variable, that is, a named
place to store data. The |5| is an r-value, and is the data which will be
stored. Of course, |v| can also occur on the right, as in the assignment
|w = v| where one variable is copied into another. For the avoidance of doubt,
we will call |v| an lvalue wherever it appears -- we mean only that it has
the potential to be written to.[1] For us, then:

(*) An "rvalue" unambiguously specifies a piece of data at run-time.
Numbers, texts and instances are all examples of rvalues, but so are usages
of phrases to decide values (i.e., function calls). See //Rvalues//.
(*) An "lvalue" unambiguously specifies a place to store data, such as
a variable, or a table entry. See //Lvalues//.

Lvalues and rvalues inside the compiler mostly come from parsing source text,
but we can also manufacture them directly. If we need the number 17 as a
constant, for example, we can call //Rvalues::from_int// to make a suitable
|parse_node|, even if "17" is never mentioned in the source text read in.
And a wide range of other functions exist to make constant rvalues of all kinds:
//Rvalues::from_Unicode_point//, for example.

Similarly, functions such as //Lvalues::new_LOCAL_VARIABLE// allow us to take
a |local_variable| pointer and make an lvalue from it.

[1] We have to treat lvalues in this slightly unusual way because, contrary to
C-like languages, we have no syntactic way to mark that the name of a variable
means its value rather than its identity -- in C, this would be |name| versus
|&name|, with the "pointer to" marker |&| distinguishing the cases. We must
instead look to the context. Even C sometimes does that -- when C writes |v = 5|,
it would arguably be more consistent to say something like |store(&v, 5)|.

@ 


