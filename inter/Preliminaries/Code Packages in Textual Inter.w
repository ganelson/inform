Code Packages in Textual Inter.

How executable functions are expressed in textual inter programs.

@h Code packages.
To recap: a file of textual inter has a brief global section at the top, and
is then a hierarchiy of package definitions. Each package begins with a
symbols table, but then has contents which depend on its type. This section
covers the possible contents for a code package, that is, one whose type
is |_code|.

Note that |package| is a data statement, not a code statement, and it follows
that there is no way for a code package to contain sub-packages. Conceptually,
a code package is a single executable function.

@h Local variables.
The statement |local NAME KIND| gives the code package a local variable;
the |NAME| must be a private |misc| symbol in the package's symbols table.
Local variable definitions should be made after the symbols table and before
the |.begin| label (see below). When the function is called at run-time, its
earliest-defined locals will hold any arguments from the function call.
So for example, if:

	|package Double _code|
	|    symbol private misc x|
	|    local x K_number|

then a call |Double(6)| would begin executing with |x| equal to 6.

@h Labels.
Like labels in any assembly language, these are named reference points in the
code; they are written |NAME|, where |NAME| must be a private |label| symbol
in the package's symbols table, and must begin with a full stop |.|.

All code packages must begin with the special label |.begin|, and close with
the special label |.end|; intervening code is indented. Thus:

	|package HelloWorld _code|
	|    symbol private label .begin|
	|    symbol private label .end|
	|    .begin|
	|        inv !print|
	|            val K_text "Hello World!\n"|
	|    .end|

The use of other labels does not change indentation in this way; |.begin|
and |.end| are special.

@h Primitive invocations.
Other than labels and locals, code is a series of "invocations". An invocation
is a use of either another function, or of a primitive.

Recall that the global section at the top of the inter file will likely have
declared a number of primitives, with the notation:

	|primitive PRIMITIVE IN -> OUT|

Primitives are, in effect, built-in functions. |IN| can either be |void| or
can be a list of one or more terms which are all either |ref|, |val|, |lab| or
|code|. |OUT| can be either |void| or else a single term which is either
|ref| or |val|. For example,

	|primitive !plus val val -> val|

declares that the signature of the primitive |!plus| is |val val -> val|,
meaning that it takes two values and produces another as result, while

	|primitive !ifelse val code code -> void|

says that |!ifelse| consumes a value and two blocks of code, and produces
nothing. Of course, |!plus| adds the values, whereas |!ifelse| evaluates
the value and then executes one of the two code blocks depending on
the result. But the statement |primitive| specifies only names and
signatures, not meanings.

The third term type, |lab|, means "the name of a label". This must be an
explicit name: labels are not values, which is why the signature for
|!jump| is |primitive !jump lab -> void| and not |primitive !jump val -> void|.

The final term type, |ref|, means "a reference to a value", and is in
effect an lvalue rather than an rvalue: for example,

	|primitive !pull ref -> void|

is the prototype of a primitive which pulls a value from the stack and
stores it in whatever is referred to by the |ref| (typically, a variable).

Convention. Inform defines a standard set of around 90 primitives. Although
their names and prototypes are not part of the inter specification as such,
you will only be able to use Inter's "compile to I6" feature if those are
the primitives you use, so in effect this is the standard set. Details of
these primitives and what they do will appear below.

@ A primitive is invoked by |inv PRIMITIVE|, with any necessary inputs,
matching the |IN| part of its signature, occurring on subsequent lines
indented one tab stop in. For example:

	|inv !plus|
	|    val K_number 2|
	|    val K_number 2|

would compute |2+2|. This brings up the issue of "context". Code statements
are always parsed in a given context, the context being what they are
expected to produce or do. In this example:

	|inv !print|
	|    val K_text "Hello World!\n"|

the invocation of |!print| occurs at the top level of the function, in what
is called "void" context; but the |val| statement occurs in value context,
because it appears where the |!print| invocation expects to find a text value.
It is an error to use a statement in the wrong context. For example, this:

	|    .begin|
	|        inv !plus|
	|            val K_number 2|
	|            val K_number 2|
	|    .end|

is an error, because it makes no sense to evaluate |!plus| in a void context:
the sum would just be thrown away unused. The context in which an |inv|
statement is allowed depends on the |OUT| part of the signature of its
primitive. Comparing the declarations of |!print| and |!plus|, we see:

	|primitive !print val -> void|
	|primitive !plus val val -> val|

so that |!print| can only be invoked in a void context, and |!plus| in a
value context.

@h Function invocations.
The same statement, |inv|, is also used to call functions which are not
primitive: that is, functions which are defined by code packages.

To do so, though, we need a value identifying the function. This is
done as follows. Suppose:

	|kind K_number int32|
	|kind K_number_to_number K_number -> K_number|
	|package Double_B _code|
	|    symbol private misc x|
	|    symbol private label .begin|
	|    symbol private label .end|
	|    local x K_number|
	|    .begin|
	|        inv !return|
	|            inv !plus|
	|                val K_number x|
	|                val K_number x|
	|    .end|
	|constant Double K_number_to_number = Double_B|

The value |Double| now evaluates to this function, and that's what we
can invoke. Thus:

	|inv Double|
	|    val K_number 17|

compiles to a function call returning the number 34.

It would not make sense, and is an error, to write |inv Double_B|, because
|Double_B| is a package name, not a value; and because there is no way to
know its signature. By contrast, |Double| is indeed a value, and by looking
at its kind |K_number_to_number|, we can see that the signature for the
invocation must be |val -> val|.

@h Val and cast.
As has already been seen in the above examples, |val KIND VALUE| can be
used in value context to supply an argument for a function or primitive.

In general, inter code has very weak type checking. |val KIND VALUE| forces
the |VALUE| to conform to the |KIND|, but no check is made on whether
this kind is appropriate in the current context. For example, the primitive
|!print| requires its one value to be textual, so that the following:

	|inv !print|
	|    val K_number 7|

has undefined behaviour at run-time. Though a terrible idea, this is valid
inter code. This code, on the other hand, will throw an error:

	|inv !print|
	|    val K_number "Seven"|

The inter language does nevertheless provide for compilers which want to
produce much stricter type-checked code, or which need their code-generators
to compile shim code converting values between kinds. The statement:

	|cast KIND1 <- KIND2|

is valid only in value context, and marks that a value of |KIND2| needs to
be interpreted in some way as a value of |KIND1|. For example, one might
imagine something like this:

	|inv !times|
	|    cast K_number <- K_truth_state|
	|        val K_truth_state flag1|
	|    cast K_number <- K_truth_state|
	|        val K_truth_state flag2|

@h Ref, lab and code.
Just as |val| supplies a value as needed by a |val| term in an invocation
signature, so |ref|, |lab| and |code| meet the other possible requirements.
For example, suppose the following signatures:

	!primitive !jump lab -> void|
	!primitive !pull ref -> val|
	!primitive !if val code -> void|

These might be invoked as follows:

	|inv !jump|
	|    lab .end|

Here |.end| is the name of a label in the current function. References to
labels in other functions are impossible, because label names are all |private|
to the current symbols table. No kind is mentioned in a |lab| statement
because labels are not values, and therefore do not have kinds.

	|inv !pull|
	|    ref K_number x|

Here |x| is the name of a variable, but it could be the name of any form of
storage. On the other hand, |ref K_number 10| would be an error, because it
isn't possible to write to the number 10: that is an rvalue but not an lvalue.

	|inv !if|
	|    val K_truth_state flag|
	|    code _ _|
	|        inv !print|
	|            val K_text "Yes!"|

compiles to something like |if (flag) { print "Yes!"; }|. The |code| statement
is similar to a braced code block in a C-like language. Any amount of code
can appear inside it, indented by one further tab stop; this code is all
read in void context. There is no such thing as a code block which returns
a value, and |code| can only be used in code context (i.e. matching the
signature term |code|), not in value context. If what you need is code to
return a value, that should be another function.

@h Concatenate and refcatenate.
Using the mechanisms above, there is no good way to throw away an unwanted
value: it is an error, for example, to evaluate something in void context.
That means there is no sensible way to implement a typical C-style
concatenation such as |A, B, C| -- which evaluates |A|, then |B|, then
|C|, but produces only |C| as the answer, throwing away |A| and |B|.
(One might want to do this because the evaluations have side-effects.)
For that reason, we have:

	|concatenate _ _|
	|    val K_number A|
	|    val K_number B|
	|    val K_number C|

|concatenate| causes any number of indented values to be evaluated,
throwing all away but returning the last. These values can have different
kinds. Unlike |code|, whose contents are read in void mode, the contents
of |concatenate| are read in value mode.

|refcatenate| is the same thing, except that the result is interpreted as
a reference, not a value.
