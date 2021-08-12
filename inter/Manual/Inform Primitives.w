Inform Primitives.

The standard set of primitive invocations used within Inform.

@h Status.
The Inter specification allows for any number of primitive invocations to
be declared and used; none are built-in or required.

The Inform compiler, however, has a set of around 90 different primitives.
The back end of the compiler can compile those into valid Inform 6 code;
the front end of the compiler is guaranteed to declare and use only (a
subset of) those 90. That gives the following set of primitives a
kind of halfway status: though they are not part of the inter specification,
for the time being they're the only game in town.

@h Arithmetic.
The following are standard integer arithmetic operations:

(a) |primitive !plus val val -> val|. 16 or 32-bit integer addition.
(b) |primitive !minus val val -> val|. 16 or 32-bit integer subtraction.
(c) |primitive !unaryminus val -> val|. Equivalent to performing |0 - x|.
(d) |primitive !times val val -> val|.  16 or 32-bit integer multiplication.
(e) |primitive !divide val val -> val|. 16 or 32-bit integer division.
(f) |primitive !modulo val val -> val|. Remainder after such a division.

@h Logical operators.
In general, the value 0 is false, and all other values are true.

(a) |primitive !not val -> val|. True if the value is false, and vice versa.
(b) |primitive !and val val -> val|. True if both are true: doesn't evaluate the second if the first is false.
(c) |primitive !or val val -> val|. True if either is true: doesn't evaluate the second if the first is true.

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

@h Sequential evaluation.
The reason for the existence of |!ternarysequential| is that it's a convenient
shorthand, and also that it helps the code generator with I6 generation,
because I6 has problems with the syntax of complicated sequential evals.

(a) |primitive !sequential val val -> val|. Evaluates the first, then the second
value, producing that second value.
(a) |primitive !ternarysequential val val val -> val|.  Evaluates the first,
then the second, then the third value, producing that third value.

@h Random numbers.
There is just one primitive for this:

(a) |primitive !random val -> val|. Produce a uniformly random integer in the range 0 up to |val| minus 1.

@h Printing.
These print data of various kinds:

(a) |primitive !print val -> void|. Print text.
(b) |primitive !printnumber val -> void|. Print a (signed) number in decimal.
(c) |primitive !printchar val -> void|. Print a character value, from the ZSCII character set.
(d) |primitive !printdword val -> void|. Print a dictionary word.
(e) |primitive !printstring val -> void|. Print a packed string.

While these correspond to standard I6 library functions, they should probably
be removed from the set of primitives, but there are issues here to do with
the Inform 6 "veneer":

(a) |primitive !printnlnumber val -> void|. Print number but in natural language.
(b) |primitive !printname val -> void|. Print name of an object.
(c) |primitive !printdef val -> void|. Print name of an object, preceded by definite article.
(d) |primitive !printcdef val -> void|. Print name of an object, preceded by capitalised definite article.
(e) |primitive !printindef val -> void|.  Print name of an object, preceded by indefinite article.
(f) |primitive !printcindef val -> void|.  Print name of an object, preceded by capitalised indefinite article.

There are also primitive ways to change the visual style of text:

(a) |primitive !font val -> void|. Change to fixed-width font if value is 1, or regular if 0.
(b) |primitive !stylebold void -> void|. Change to bold type.
(c) |primitive !styleunderline void -> void|. Change to underlined type.
(d) |primitive !styleroman void -> void|. Change to roman (i.e., not bold, not underlined) type.

Lastly, a primitive for a rum feature of Inform 6 allowing for the display of
"box quotations" on screen:

(a) |primitive !box val -> void|. 

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

@h Control flow.
The simplest control statement is an "if". Note that a different primitive
is used if there is an "else" attached: it would be impossible to use the
same primitive for both because they couldn't have the same signature.

|!ifdebug| is an oddity: it executes the code only if the program is
being compiled in "debugging mode". (In Inform, that would mean that the
story file is being made inside the application, or else released in a
special testing configuration.) While the same effect could be achieved
using conditional compliation splats, this is much more efficient.

(a) |primitive !if val code -> void|. 
(b) |primitive !ifelse val code code -> void|. 
(c) |primitive !ifdebug code -> void|. 

There are then several loops.

(a) |primitive !while val code -> void|. Similar to |while| in C.
(b) |primitive !for val val val code -> void|. Similar to |for| in C.
(c) |primitive !objectloopx ref val code -> void|. A loop over instances,
stored in the variable |ref|, of the kind of object |val|.
(d) |primitive !objectloop ref val val code -> void|. A more general form,
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
	            val K_number 2
	            code
	                inv !print
	                    val K_text "Two!"
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

And, lastly, the lowest-level way to travel:

(a) |primitive !jump lab -> void|. Jumo to this label in the current function.

@h Interactive fiction-only primitives.
The following would make no sense in a general-purpose program. Most mirror
very low-level I6 features, and Inform uses them mainly when converting
I6 code into inter: in almost all cases it's better to call routines in the
template rather than to use these. First, the spatial containment object tree:

(a) |primitive !move val val -> void|. Moves first to second (both are objects).
(b) |primitive !in val val -> val|. Tests if first is in second (both are objects).
(c) |primitive !notin val val -> val|. Negation of same.

Object class membership:

(a) |primitive !ofclass val val -> val|. Does the first belong to the enumerated
subkind whose weak type ID is the second value?

Attributes can be handled as follows. The values used to refer to these attributes
can be inter symbols for their properties, but only if those properties are
indeed stored as Z-machine or Glulx attributes at run-time.

(a) |primitive !give val val -> void|. Set the second (an attribute) for the first (an object).
(b) |primitive !take val val -> void|. Unset the second (an attribute) for the first (an object).
(c) |primitive !has val val -> val|. Test if the first (an object) has the second (an attibute).
(d) |primitive !hasnt val val -> val|. Negation of same.

Direct access to virtual machine object properties:

(a) |primitive !propertyvalue val val -> val|.
(b) |primitive !propertyaddress val val -> val|. 
(c) |primitive !propertylength val val -> val|. 
(d) |primitive !provides val val -> val|. 
