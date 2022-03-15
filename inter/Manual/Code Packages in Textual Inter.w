Code Packages in Textual Inter.

How executable functions are expressed in textual inter programs.

@h Code packages.
To recap from //Textual Inter//: an Inter program is a nested hierarchy of
packages. Some of those are special |_code| packages which define functions,
special in several ways:

(*) Their names can be used as values: that's how functions are called. See
|inv| below.

(*) Their names can optionally have types: see //Data Packages in Textual Inter//
for details.

(*) They cannot have subpackages. Conceptually, a code package is a single
function body. Packages are not used for "code blocks", and there are no
nested functions.

(*) They cannot contain |constant|, |variable|, and similar instructions found
in data packages. Instead they can only contain the set of instructions which
are the subject of this section (and which are allowed only in |_code| packages).

@ The basic structure of a function body like this is that it begins with some
local variable declarations, and then has its actual content inside a |code|
block, like so:
= (text as Inter)
	package double _code
	    local x
	    code
	    	inv !return
	    		inv !plus
	    			val x
	    			val x
=
As with its global analogue, |variable|, a |local| instruction can optionally
specify a type:
= (text as Inter)
	local (int32) x
=

There can be at most one |code| instruction at the top level. This is incorrect:
= (text as Inter)
	package fails _code
	    code
	    	inv !enableprinting
	    code
	    	inv !print
	    		val "I am dismal.\n"
=
and should instead be:
= (text as Inter)
	package succeeds _code
	    code
	    	inv !enableprinting
	    	inv !print
	    		val "I am glorious.\n"
=

@ Surprisingly, perhaps, it's legal not to have a |code| block at all. This
function works:
= (text as Inter)
	package succeeds _code
=
But of course it does nothing. If the return value of such a function is used,
it will be 0.

@h Contexts.
At any point inside a function body (except at the very top level), the
instruction used is expected to have a given "category", decided by the
"context" at that point. These categories have names:

(*) |code| context. This means an instruction is expected to do something,
but not produce a resulting value.

(*) |val| context. This means an instruction is expected to produce a value.

(*) |ref| context. This means an instruction is expected to provide a
"reference" to some storage in the program. For example, it could indicate
a global variable, or a particular property of some instance.

(*) |lab| context. This means an instruction is expected to indicate a label
marking a position in that same function.

In a |code| block, the context is initially |code|. For example:
= (text as Inter)
	package double _code
	    local x                             top level has no context
	    code                                top level has no context
	    	inv !jump                       context is code
	    		lab .SkipWarning            context is lab
	    	inv !print                      context is code
	    		val "It'll get bigger!\n"   context is val
	    	.SkipWarning                    context is code
	    	inv !store                      context is code
	    		ref x                       context is ref
	    		inv !plus                   context is val
	    			val x                   context is val
	    			val x                   context is val
	    	inv !return                     context is code
	    		val x                       context is val
=
In this function, the |code| block contains five instructions, each of which
is read in a |code| context. Each of those then has its own expectations which
set the context for its child instructions, and so on. For example, |inv !store|
expects to see two child instructions, the first in |ref| context and the
second in |val| context.

Those uses of |inv !something| are called "primitive invocations". They are
like function calls, but where the function is built in to Inter and is not
itself defined in Inter. Each such has a "signature". For example, the
internal declaration of |!store| is:
= (text as Inter)
	primitive !store ref val -> val
=
So its signature is |ref val -> val|. This expresses that its two children
should be read in |ref| and |val| context, and that its result is a |val|.
(As in most C-like languages, stores are values in Inter, though in
practice those values are often thrown away.)

The standard built-in stock of primitive invocations is described in the
next section, on //Inform Primitives//.

@ How is all this policed? Whereas typechecking of data is often weak in Inter,
signature checking is taken much more seriously. If the context is |code|, then
the only legal primitives to invoke are those where the return part of the
signature is either |void| (no value) or |val| (a value, but which is thrown
away and ignored, as in most C-like languages). Otherwise, |ref| context
requires a |ref| result, and similarly for |val| and |lab|.

For example, |!return| has the signature |val -> void|, which makes it legal
to use in a |code| context as in the above example. But these two attempts
to use it would both be incorrect:
= (text as Inter)
	inv !return
	inv !printnumber
		inv !return
			val 10
=
The first fails because it tries to use |!return| as if it were |void -> void|,
i.e., with no supplied value; the second fails because it tries to use it as if
it were |val -> val|.

@ Some primitives have |code| as one or more of their arguments. For example:
= (text as Inter)
	primitive !ifelse val code code -> void
=
This evaluates the first argument (a value), then executes the second argument
(a code block) if the value is non-zero, or alternatively the third if it is zero.
There is no result. For example:
= (text as Inter)
	inv !ifelse
		val x
		code
			inv !printnumber
				x
		code
			inv !print
				"I refuse to print zeroes on principle."
=

@ Rather like |code|, which executes a run of instructions as if they were a
single instruction, |evaluation| makes a run of evaluations. Thus:
= (text as Inter)
	inv !printnumber
		evaluation
			val 23
			val -1
			val 12
=
prints just "12". The point of this is that there may be side-effects in the
earlier evaluations, of course, though there weren't in this example.

Another converter, so to speak, is |reference|, but this is much more limited
in what it is allowed to do.
= (text as Inter)
	inv !store
		reference
			val x
		val 5
=
is exactly equivalent to:
= (text as Inter)
	inv !store
		ref x
		val 5
=
This is not a very useful example: but consider --
= (text as Inter)
	inv !store
		reference
			inv !propertyvalue
				val Odessa
				val area
		val 5000
=
which changes the property |area| for |Odessa| to 5000. The signature of
|!propertyvalue| is |val val -> val|, and ordinarily it evaluates the property.
But placed under a |reference|, it becomes a reference to where that property
is stored, and thus allows the value to be changed with |!store|. This:
= (text as Inter)
	inv !store
		inv !propertyvalue
			val Odessa
			val area
		val 5000
=
would by contrast be rejected with an error, as trying to use a |val| in a |ref|
context.

|reference| cannot be applied to anything other than storage (a local or global
variable, a memory location or a property value), so for example:
= (text as Inter)
	reference
		val 5
=
is meaningless and will be rejected. There is in general no way to make, say,
a pointer to a function or instance using |reference|. It is much more circumscribed
than the |&| operator in C.

@h Function calls.
This seems a good point to say how to make function calls, since it's almost
exactly the same. This:
= (text as Inter)
	inv !printnumber
		inv double
			val 10
=
prints "20". Note the lack of a |!| in front of the function name: this means
it is a regular function, not a primitive. 

@ Function calls work in a rather assembly-language-like way, and Inter makes
much less effort to type-check these for any kind of safety: so beware. It
allows them to have any of the signatures |void -> val|, |val -> val|,
|val val -> val|, ... and so on: in other words, they can be called with
any number of arguments.

In particular, even if a function is declared with a type it is still legal to
call it with any number of arguments. Again: beware.

Those arguments become the initial values of the local variables. So for
example, if:
= (text as Inter)
	package example _code
	    local x
	    local y
=
then:

(*) a call with no arguments results in |x| and |y| equal to 0 and 0;
(*) a call with argument 7 results in |x| and |y| equal to 7 and 0;
(*) a call with arguments 7 and 81 results in |x| and |y| equal to 7 and 81;
(*) a call with three or more arguments has undefined results and may crash
the program altogether.

@h Val, ref, lab and cast.
We have seen many examples already, but:

(*) |val V| allows us to use any simple value |V| in any |val| context. For
what is meant by a "simple" value, see //Data Packages in Textual Inter//.

(*) |ref R| allows us to refer to any variable, local or global, in a |ref|
context.

(*) |lab L| allows us to refer to any label declared somewhere in the current
function body, in a |lab| context.

@ The |val| and |ref| instructions both allow optional type markers to be placed,
so for example:
= (text as Inter)
	val (int32) x
	ref (text) y
=
Where no type marker is given, the type is always considered |unchecked|.

Types of |val| or |ref| tend not to be checked or looked at anyway, so this
feature is currently little used. For many primitives, some of which are quite
polymorphic, it would be difficult to impose a typechecking regime anyway.
But the ability to mark |val| and |ref| with types is preserved as a hedge
against potential future developments, when Inter might conceivably be
tightened up to typecheck explicitly typed values.

Similarly unuseful for the moment is |cast|. This instruction allows us to
say "consider this value as if it had a different type". For example, if we
are using an enumerated type |city|, we could read the enumeration values as
numbers like so:
= (text as Inter)
	cast int32 <- city
		val (city) Odessa
=
Right now this is no different from:
= (text as Inter)
	val (int32) Odessa
=
but we keep |cast| around as a hedge against future developments, in case we
ever want to typecheck strictly enough that |val (int32) Odessa| is rejected
as a contradiction in terms.

@h Labels and assembly language.
Like labels in C, these are named reference points in the code; they are written
|.NAME|, where |.NAME| must begin with a full stop |.|. Labels are not values;
they cannot be stored, or computed with, or cast. They can only be used in
a |lab| instruction.

@ Two uses of |inv| have already been covered: to call an Inter function, and
to invoke a primitive operation. The third is to execute an "assembly-language
opcode". What we mean by that is the direct use of the instruction set on the
target virtual machine we are expecting our program to run on.

This has always been a feature of Inform 6 code. For example, some real-number
arithmetic functions in BasicInformKit are written to use heavy amounts of
Glulx assembly language, in order to access functionality not present in the
Inform language itself. Here is a sample:
= (text as Inform 6)
	@fdiv sp $40135D8E log10val; ! $40135D8E is log(10)
	@floor log10val fexpo;
	@ftonumn fexpo expo;
=
Those "opcodes" beginning |@| are part of the instruction set for the
Glulx virtual machine: real number arithmetic is impossible on the smaller
Z-machine, so we couldn't meaningfully compile this code to that platform,
and that is just is well because it has a completely different instruction
set of opcodes from Glulx anyway. Still, there's no denying that Inter code
using assembly immediately becomes less portable. This is why it is always
better to use Inter primitives if possible.

Still, BasicInformKit must be compiled to Inter code somehow. We clearly need to
deal with those opcodes somehow. The standard Inform-provided kits use two
different sets of opcodes, as noted: the Z-machine and Glulx instruction sets.
One conceivable way to deal with this would have been to provide primitives
equivalent to every opcode in either set (or at least every opcode used in
the standard Inform kits). But that would hugely increase the set of primitives,
and also incur a certain amount of awkward repetition.

Instead, the Inter specification goes to the opposite extreme. It makes no
assumptions about what assembly opcodes do, or do not, exist. Inter allows
absolutely anything, and would be quite happy to accept, say, |inv @flytothemoon|,
even though this opcode does not exist in any known system of assembly language.[1]

And so the above is in fact compiled to:
= (text as Inform 6)
	inv @fdiv
		assembly stack
		val 0x40135D8E
		val log10val
	inv @floor
		val log10val
		val fexpo
	inv @ftonumn
		val fexpo
		val expo
=
And when the //building// module performed that compilation, it knew nothing
about |@fdiv| and the rest: it just took on trust that this is meaningful.

[1] This can actually be useful, since it means people experimenting with new
hybrid forms of Inform can devise extra opcodes of their own.

@ So, how apparently generous: the Inter specification allows us to invoke
opcodes with arbitrary names. But that does not, of course, mean that those
opcodes can be compiled to code which does anything useful. The //final//
code-generation module probably won't know what to do with our hypothetical
|@flytothemoon| opcode.

In practice, therefore, //final// knows how to deal with the Z-machine
instruction set when compiling for Z via Inform 6, and how to deal with the
Glulx instruction set when compiling either for Glulx via Inform 6 or a
native executable via a C compiler like |clang|. Any further code-generators
are also likely to follow Glulx conventions. So: if you really must use
assembly language in your Inter code, good advice would be --

(1) Use the Glulx instruction set, for better chances of portability.

(2) Only use those opcodes which are also used in the standard Inform kits
somewhere, since those will probably be implemented.

@ If we look at this example in more detail:
= (text as Inter)
	inv @fdiv
		assembly stack
		val 0x40135D8E
		val log10val
=
we see some general features of assembly language. Inter allows any number
of child instructions to be supplied -- here, there are three. Since Inter knows
nothing about the meaning of |@fdiv|, it has no way to know how many are
expected. They should all be usages of |val|, |lab|, or |assembly|.

|val| and |lab| we have seen already. |assembly| is a sort of punctuation
instruction which allows various oddball syntaxes of Z-machine or Glulx
assembly to be imitated in Inter. There are only seven possible |assembly|
instructions. Two are very common:

(*) |assembly stack| is probably the most common, either reading or writing
to the top of the virtual machine's stack.

(*) |assembly store_to| indicates that a storage location follows (either
|assembly stack| or a local or global variable). This is only used in Z-machine
assembly language; Glulx assembly doesn't have this marker.

The other five apply only to "branch instructions", which perform some test
and then either return from the current function or make a jump to a label
(a "branch"), depending on the outcome of the test. By default the instruction
branches on a successful test. But alternatively it can:

(*) |assembly branch_if_false|.

(*) |assembly return_true_if_true|.

(*) |assembly return_false_if_true|

(*) |assembly return_true_if_false|

(*) |assembly return_false_if_false|

So for example the Z-machine instruction |@random sp -> i;| compiles to Inter as:
= (text as Inter)
	inv @fdiv
		assembly stack
		assembly store_to
		val i
=
And note the use of |val i|, not |ref i|, even though the variable is being
written to here. Even Inter's normal rules of category checking do not apply
to assembly language, the lowest of the low.
