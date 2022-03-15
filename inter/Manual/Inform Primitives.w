Inform Primitives.

The standard set of primitive invocations used within Inform.

@h What standard means.
To recap from //Code Packages in Textual Inter//, primitives are like built-in
atomic operations. The Inter specification allows for any desired set of
primitives to be used, provided they are declared. However, in practice
the //building// module of Inter defines a standard set of 95 or so primitives
which are used across the Inform tool-chain, and:

(*) The front end of the Inform compiler invokes only (a subset of) this
standard set of primitives.
(*) The back end guarantees to be able to perform final code-generation to
any supported platform on the whole of this standard set.

That means the standard set is (for now at least) the only game in town, and
the following catalogue runs through it. Textual Inter code does not need
to declare primitives if they belong to this standard set, but the
declarations they have behind the scenes are all listed below.

(See //building: Inter Primitives// for where in the //inter// source code
these primitives are defined.)

@h Arithmetic.
The following are standard integer arithmetic operations, using signed
twos-complement integers:

(a) |primitive !plus val val -> val|. 16 or 32-bit integer addition.
(b) |primitive !minus val val -> val|. 16 or 32-bit integer subtraction.
(c) |primitive !unaryminus val -> val|. Equivalent to performing |0 - x|.
(d) |primitive !times val val -> val|.  16 or 32-bit integer multiplication.
(e) |primitive !divide val val -> val|. 16 or 32-bit integer division.
(f) |primitive !modulo val val -> val|. Remainder after such a division.

@h Logical operators.
In general, the value 0 is false, and all other values are true.

(a) |primitive !not val -> val|. True if the value is false, and vice versa.
(b) |primitive !and val val -> val|. True if both are true: doesn't evaluate the
second if the first is false.
(c) |primitive !or val val -> val|. True if either is true: doesn't evaluate the
second if the first is true.

@h Bitwise operators.
These differ in that they do not "short circuit", and do not squash values
down to just 0 or 1.

(a) |primitive !bitwiseand val val -> val|.
(a) |primitive !bitwiseor val val -> val|. 
(a) |primitive !bitwisenot val -> val|. 

@h Numerical comparison.
These are comparisons of signed integers. (If Inform needs to compare unsigned
integers, it calls a routine in the I6 template.)

(a) |primitive !eq val val -> val|. 
(b) |primitive !ne val val -> val|. 
(c) |primitive !gt val val -> val|. 
(d) |primitive !ge val val -> val|. 
(e) |primitive !lt val val -> val|. 
(f) |primitive !le val val -> val|. 

This is a special operation allowing the comparisons to test for multiple
possibilities at once. (Old-school Inform 6 users will recognise it as the
|or| operator.)

(a) |!alternative val val -> val|

For example,
= (text as Inter)
	inv !eq
		val x
		inv !alternative
			val 2
			val 7
=
tests whether |x| equals either 2 or 7.

@h Sequential evaluation.
The reason for the existence of |!ternarysequential| is that it's a convenient
shorthand, and also that it helps the code generator with I6 generation,
because I6 has problems with the syntax of complicated sequential evals.

(a) |primitive !sequential val val -> val|. Evaluates the first, then the second
value, producing that second value.
(a) |primitive !ternarysequential val val val -> val|.  Evaluates the first,
then the second, then the third value, producing that third value.

@h Random.
This is essentially the built-in |random| function of Inform 6, given an Inter
disguise. See the Inform 6 Designer's Manual for a specification.

(a) |!primitive random val -> val|. 

@h Printing.
These print data of various kinds:

(a) |primitive !print val -> void|. Print text.
(b) |primitive !printnumber val -> void|. Print a (signed) number in decimal.
(c) |primitive !printchar val -> void|. Print a character value.
(d) |primitive !printnl void -> void|. Print a newline. (This is needed because
some of our VMs use character 10 for newline, and crash on 13, and others vice versa.)
(e) |primitive !printdword val -> void|. Print a dictionary word.
(f) |primitive !printstring val -> void|. Print a packed string.

There are also two primitive ways to change the visual style of text:

(a) |primitive !font val -> void|. Change to fixed-width font if value is 1, or regular if 0.
(b) |primitive !style val -> void|. Change to this text style.

The effect of these will depend on the platform the final Inter code is generated
for. If the value supplied to |!style| is 0, 1, 2 or 3, then this should make an
effort to achieve roman, bold, italic, or reverse-video type, respectively, and
that should apply across all platforms. Use of any other value is likely to be
less portable. On C, for example, all other uses of |!style| are (Inform) text
values which supply names for styles.

Then there is a primitive for a rum feature of Inform 6 allowing for the display of
"box quotations" on screen:

(a) |primitive !box val -> void|. 

And another largely pointless primitive for issuing a run of a certain number of
spaces, for users too lazy to write their own loops:

(a) |primitive !spaces val -> void|.

On some platforms, active steps need to be taken before text can actually appear:
for example, those using the Glk input/output framework. As a convenience, this
primitive will do anything which might be necessary. //inform7// doesn't use
this, instead compiling its own code to activate Glk, but it's useful to have
this opcode for making small Inter test cases work:

(a) !primitive !enableprinting void -> void|.

@h Stack access.
The stack is not directly accessible anywhere in memory, so the only access
is via the following.

(a) |primitive !push val -> void|. Push value onto the stack.
(b) |primitive !pull ref -> void|. Pull value from the stack and write it into
the storage referred to. Values on the stack have unchecked kinds: it's up to
the author not to pull an inappropriate value.

@h Accessing storage.
Here the |ref| term is a refernce to a piece of storage: a property of an
instance, or a global variable, or an entry in memory, for example.

(a) |primitive !store ref val -> val|. Put the value in |ref|.
(b) |primitive !setbit ref val -> void|. Set bits in the mask |val| in |ref|.
(c) |primitive !clearbit ref val -> void|. Clear bits in the mask |val| in |ref|.
(d) |primitive !postincrement ref -> val|. Performs the equivalent of |ref++|.
(e) |primitive !preincrement ref -> val|. Performs the equivalent of |++ref|.
(f) |primitive !postdecrement ref -> val|. Performs the equivalent of |ref--|.
(g) |primitive !predecrement ref -> val|. Performs the equivalent of |--ref|.

Memory can be accessed with the following. The first value is the address of
the array; the second is an offset, that is, with 0 being the first entry,
1 the second, and so on. "Word" in this context means either an |int16| or
an |int32|, depending on what virtual machine are compiling to.

(a) |primitive !lookup val val -> val|. Find word at this word offset.
(b) |primitive !lookupbyte val val -> val|. Find byte at this byte offset.

Properties, like memory, can be converted to |ref| in order to write to them,
and are accessible with |propertyvalue|. Their existence can be tested with
|propertyexists|; the other two opcodes here are for the handful of "inline
property values", where a property stores not a single value but a small array.
In each of the four ternary property primitives, the operands are |K|, the
weak kind ID of the owner; |O|, the owner; and |P|, the property. For properties
of objects, |K| will always be |OBJECT_TY|.

|propertyarray| and |propertylength| both produce 0 (but not a run-time error)
if called on a property value which does not exist, or is not an inline array.
In particular, they always produce 0 if the owner |O| is not an object, since
only objects can have inline property values.

(a) |primitive !propertyvalue  val val val -> val|.
(b) |primitive !propertyarray  val val val -> val|. 
(c) |primitive !propertylength val val val -> val|. 
(d) |primitive !propertyexists val val val -> val|. 

@h Indirect function calls.
Invocations of functions can only be made with |inv| when the function is
specified as a constant, and when its signature is therefore known. If
we need to call "whatever function this variable refers to", we have to
use one of the following. They differ only in their signatures. The
first value is the function address, and subsequent ones are arguments.

(a) |primitive !indirect0v val -> void|. 
(b) |primitive !indirect1v val val -> void|. 
(c) |primitive !indirect2v val val val -> void|. 
(d) |primitive !indirect3v val val val val -> void|. 
(e) |primitive !indirect4v val val val val val -> void|. 
(f) |primitive !indirect5v val val val val val val -> void|. 
(g) |primitive !indirect0 val -> val|. 
(h) |primitive !indirect1 val val -> val|. 
(i) |primitive !indirect2 val val val -> val|. 
(j) |primitive !indirect3 val val val val -> val|. 
(k) |primitive !indirect4 val val val val val -> val|. 
(l) |primitive !indirect5 val val val val val val -> val|. 

@h Message function calls.
These are the special form of function call from Inform 6 with the syntax
|a.b()|, |a.b(c)|, |a.b(c, d)| or |a.b(c, d, e)|. In effect, they look up a
property value which is a function, and call it. But because they have very
slightly different semantics from indirect function calls, they appear here
as primitives of their own. Inform 7 never compiles these, but kit assimilation
may do. To get an idea of how to handle these, see for example
//final: C Function Model//, which compiles them to C.

(a) |primitive !message0 val val -> val|.
(b) |primitive !message1 val val val -> val|.
(c) |primitive !message2 val val val val -> val|.
(d) |primitive !message3 val val val val val -> val|.

@h External function calls.
The following calls a function which is not part of the program itself, and
which is assumed to be provided by code written in a different programming
language. It cannot be used when Inter is being generated to Inform 6
code, because I6 has no ability to link with external code; but it can be
used when generating C, for example.

The first value must be a literal double-quoted text, and is the name of
the external function. The second value is an argument to pass to it; and
the result is whatever value it returns.

(a) |primitive !externalcall val val -> val|.

@h Control flow.
The simplest control statement is an "if". Note that a different primitive
is used if there is an "else" attached: it would be impossible to use the
same primitive for both because they couldn't have the same signature.

|!ifdebug| is an oddity: it executes the code only if the program is
being compiled in "debugging mode". (In Inform, that would mean that the
story file is being made inside the application, or else released in a
special testing configuration.) While the same effect could be achieved
using conditional compliation splats, this is much more efficient.
Similarly for |!ifstrict|, which tests for "strict mode", in which run-time
checking of program correctness is performed, but at some performance cost.

(a) |primitive !if val code -> void|. 
(b) |primitive !ifelse val code code -> void|. 
(c) |primitive !ifdebug code -> void|. 
(d) |primitive !ifstrict code -> void|. 

There are then several loops.

(a) |primitive !while val code -> void|. Similar to |while| in C.
(b) |primitive !do val code -> void|. A do/until loop, where the test of |val|
comes at the end of each iteration. Note that this is do/until, not do/while.
(c) |primitive !for val val val code -> void|. Similar to |for| in C.
(d) |primitive !objectloopx ref val code -> void|. A loop over instances,
stored in the variable |ref|, of the kind of object |val|.
(e) |primitive !objectloop ref val val code -> void|. A more general form,
where the secomd |val| is a condition to be evaluated which decides whether
to execute the code for given |ref| value.

A switch statement takes a value, and then executes at most one of an
arbitrary number of possible code segments. This can't be implemented with
a single primitive, because its signature would have to be of varying
lengths with different uses (since some switches have many cases, some few).
Instead: a |switch| takes a single |code|, but that |code| can in turn
contain only invocations of |!case|, followed optionally by one of |!default|.

(a) |primitive !switch val code -> void|. 
(b) |primitive !case val code -> void|. 
(c) |primitive !default code -> void|. 
(d) |primitive !alternativecase val val -> val|.

This looks a little baroque, but it works in practice:
= (text as Inter)
	inv !switch
	    val K_number X
	    code
	        inv !case
	            val K_number 1
	            code
	                inv !print
	                    val K_text "One!"
	        inv !case
				inv !alternativecase
		            val K_number 2
		            val K_number 7
	            code
	                inv !print
	                    val K_text "Either two or seven!"
	        inv !default
	            code
	                inv !print
	                    val K_text "Something else!"
=
As in most C-like languages, there are primitives for:

(a) |primitive !break void -> void|. Exit the innermost switch case or loop.
(b) |primitive !continue void -> void|. Complete the current iteration of
the innermost loop.

Two ways to terminate what's happening:

(a) |primitive !return val -> void|. Finish the current function, giving the
supplied value as the result if the function is being executed in a value
context, and throwing it away if not.
(b) |primitive !quit void -> void|. Halt the whole program immediately.

This is a sort of termination, too, loading in a fresh program state from a
file; something which may not be very meaningful in all platforms. Note that
there is no analogous |!restart| or |!save| primitive: those are handled by
assembly language instead. This may eventually go, too.

(a) |primitive !restore lab -> void|.

And, lastly, the lowest-level way to travel:

(a) |primitive !jump lab -> void|. Jumo to this label in the current function.

@h Interactive fiction-only primitives.
The following would make no sense in a general-purpose program. Most mirror
very low-level I6 features. First, the spatial containment object tree:

(a) |primitive !move val val -> void|. Moves first to second (both are objects).
(b) |primitive !remove val -> void|. Removes object from containment tree.
(c) |primitive !in val val -> val|. Tests if first is in second (both are objects).
(d) |primitive !notin val val -> val|. Negation of same.
(e) |primitive !child val -> val|. Finds the child node of an object.
(f) |primitive !children val -> val|. The number of children: which may be 0.
(g) |primitive !parent val -> val|. Finds the parent of an object.
(h) |primitive !sibling val -> val|. Finds the sibling of an object.

Object class membership:

(a) |primitive !ofclass val val -> val|. Does the first belong to the enumerated
subkind whose weak type ID is the second value?
(b) |primitive !metaclass val -> val|. Returns |Class|, |Object|, |Routine|,
|String| or 0 depending on the value supplied: see the Inform 6 Designer's Manual
for more on this.
