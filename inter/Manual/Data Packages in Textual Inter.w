Data Packages in Textual Inter.

How static data, variables and constants are expressed in textual inter programs.

@h Data packages.
To recap from //Textual Inter//: an Inter program is a nested hierarchy of
packages. Some are special |_code| packages which define functions; the rest
we will call "data packages".[1] Note that the compulsory outer |main| package
is a data package. The instructions which can appear in data packages are the
subject of this section.

[1] The term "data" is used rather loosely here. "Anything else packages"
might be a fairer description.

@h Variable and values.
The instruction |variable| seems a good place to begin, since it creates an
easily-understood piece of data. For example:
= (text as Inter)
	variable V_score = 10
=
declares a new variable |V_score|, and assigns it the initial value 10. This
is a global variable, accessible across the whole program.

@ A number of different notations are allowed as numerical values:

(*) A decimal integer, which may begin with a minus sign (and, if so, will be
stored as twos-complement signed); for example, |-231|.

(*) A hexadecimal integer prefixed with |0x|, which can write the digits
|A| to |F| in either upper or lower case form, but cannot take a minus sign;
for example, |0x21BC|.

(*) A binary integer prefixed with |0b|, which cannot take a minus sign;
for example, |0b1001001|.

(*) |r"text"| makes a literal real number: the text is required to use the
same syntax as a literal real number in Inform 6. For example, |r"+1.027E+5"|.
The |E+n| or |E-n| exponent is optional, but if it is used, a |+| or |-| sign
is required; similarly, a |+| or |-| sign is required up front. So |r"1.0"|
and |r"3.7E7"| are both illegal.

Note that Inter does not specify the word size, that is, the maximum range
of integers; many Inter programs are written on the assumption that this will
be 16-bit and would fail if that assumption were wrong, or vice versa, but
other Inter programs work fine whichever is the case. Real numbers, however,
can only be used in 32-bit programs, and even then only have the accuracy
of |float|, not |double|.

@ There are also several forms of text:

(*) Literal text is written in double quotes, |"like so"|. All characters
within such text must have Unicode values of 32 or above, except for tab (9),
written |\t|, and newline (10), written |\n|. In addition, |\"| denotes a
literal double-quote, and |\\| a literal backslash, but these are the only
backslash notations at present allowed.

(*) |dw"text"| is meaningful only for interactive fiction, and represents the
command parser dictionary entry for the word |text|. This is equivalent
to the Inform 6 constant |'text//'|.

(*) |dwp"text"| is the same, but pluralised, equivalent to Inform 6 |'text//p'|.

@ There are two oddball value notations which should be used as little as possible:

(*) |!undef| makes a special "this is not a value" value.

(*) |glob"raw syntax"| is a feature allowing raw code for the final target
language to be smuggled into Inter, which is supposedly target-independent.
For example, |glob"#$magic"| says that the final code-generator should just
print out |#$magic|, in blind faith that this will mean something, when it
wants the value in question. Glob is not a respectful term, but this feature
does not deserve respect, and is not used anywhere in the Inform tool chain.

@h Constant and extended values.
The instruction |constant| defines a name for a given value. For example:
= (text as Inter)
	constant SPEED_LIMIT = 70
=
The name of this constant can then be used wherever a value is needed. Thus:
= (text as Inter)
	package main _plain
		constant SPEED_LIMIT = 70
		variable V_speed = SPEED_LIMIT
=

@ Constants also allow us to write more elaborate values than are normally
allowed -- so-called "extended values". In particular:

(*) A literal |list| is written in braces: |{ V1, V2, ..., Vn }|, where |V1|, 
|V2| and so on are all (unextended) values. The empty list is |{ }|.

(*) A list of bytes, rather than words, is written |bytes{ V1, V2, ..., Vn}|,
in the same way.

(*) Either sort of list can be given with an extent instead. |list of N words|
or |list of N bytes| constructs a list of |N| zero entries. This is not simply
an abbreviation for typing something like |{ 0, 0, 0, 0, 0, 0, 0, 0 }|, because |N|
does not have to be a literal number -- it can be a named symbol defined elsewhere,
or even defined in a different Inter tree to be linked in later.

(*) Prefixing either sort of list with the keyword |bounded| tells Inter that
the first entry (i.e., at index 0) should be the number of entries, not counting
that first entry. (This number is the list's "bound".) Thus |bounded { 70, 15 }|
is equivalent to |{ 2, 70, 15 }|, and |bounded list of 50 bytes| produces a list
of 51 bytes, the first being 50, the next fifty all being 0.

(*) A structure is written |struct{ V1, V2, ..., Vn }|. The empty |struct|
is not legal, and the keyword |bounded| cannot be used.

(*) Calculated values are written |sum{ V1, V2, ..., Vn }|, and similarly
for |product{ }|, |difference{ }| and |quotient{ }|. Empty calculated values
are not legal.

(*) Finally, two special forms of list which are used only in interactive fiction
projects, and whose semantics are identical to regular lists except for the special
ways they are compiled: |grammar{ ... }| makes a list which is the command-parser
grammar for a command verb, and |inline{ ... }| makes a list which is to be the
value of a property compiled "inline".

@ Readers with experience of Inform 6 will recognise that |{ ... }| and |bytes{ ... }|
correspond to I6's |Array -->| and |Array ->| respectively, that |bounded { ... }|
and |bounded bytes{ ... }| correspond to |Array table| and |Array buffer|, and
that |list of N words| and |list of N bytes| correspond to |Array --> N| and
|Array -> N|. Note, however, that Inter does not suffer from the ambiguity of
Inform 6's old syntax here. The Inter list |{ 20 }| is unambiguously a one-entry
list whose one entry is 20; it is quite different from |list of 20 words|.

@ Lists are obviously useful. Here are some examples:
= (text as Inter)
	constant squares = { 1, 4, 9, 16, 25, 36, 49, 64, 81, 100 }
	constant colours = { "red", "green", "blue" }
	constant lists = { squares, colours }
=
The distinction between a |struct| and a |list| is only visible if typechecking
is used (see below); the expectation is that a list would contain a varying
number of entries all of the same type, whereas a struct would contain a fixed
number of entries of perhaps different but predetermined types.

@ Calculated values are an unusual but very useful feature of Inter. Consider:
= (text as Inter)
	constant SPEED_LIMIT = 70
	constant SAFE_SPEED = difference{ SPEED_LIMIT, 5 }
=
This effectively declares that |SAFE_SPEED| will be 65. What makes this useful
is that when two Inter programs are linked together, |SAFE_SPEED| might be
declared in one and |SPEED_LIMIT| in the other, and it all works even though
the compiler of one could see the 70 but not the 5, and the compiler of the
other could see the 5 but not the 70.

@h URL notation.
All identifier names are local to their own packages. So, for example, this:
= (text as Inter)
	package main _plain
		package one _plain
			constant SPEED_LIMIT = 70
			variable V_speed = SPEED_LIMIT
		package two _plain
			variable V_speed = 12
=
is a legal Inter program and contains two different variables. But this:
= (text as Inter)
	package main _plain
		package one _plain
			constant SPEED_LIMIT = 70
		package two _plain
			variable V_speed = SPEED_LIMIT
=
...does not work. The variable |V_speed| is declared in package |two|, where
the constant |SPEED_LIMIT| does not exist.

This might seem to make it impossible for material in one package to refer
to material in any other, but in fact we can, using URL notation:
= (text as Inter)
	package main _plain
		package one _plain
			constant SPEED_LIMIT = 70
		package two _plain
			variable V_speed = /main/one/SPEED_LIMIT
=
Here |/main/one/SPEED_LIMIT| is an absolute "URL" of the symbol |SPEED_LIMIT|.
If we return to the example:
= (text as Inter)
	package main _plain
		package one _plain
			constant SPEED_LIMIT = 70
			variable V_speed = SPEED_LIMIT
		package two _plain
			variable V_speed = 12
=
we see that the two variables have different URLs, |/main/one/V_speed| and
|/main/two/V_speed|.

@h Annotations.
A few of the defined names in Inter can be "annotated".

Many annotations are simply markers temporarily given to these names during
the compilation process, and they usually do not change the meaning of the
program. For example, the final C code generator annotates the names of arrays
with their addresses in (virtual) memory, with the |__array_address| annotation.
In textual format:
= (text as Inter)
	constant my_array = { 1, 2, 4, 8 } __array_address=7718
=
All annotation names begin with a double underscore, |__|. They do not all
express a value: some are boolean flags, where no |=...| part is written.

For the list of standard annotation names in use, see //Inform Annotations//.

@h Metadata constants.
If constant names begin with the magic character |^| then they represent
"metadata", describing the program rather than what it does. They are not
data in the program at all. Thus:
= (text as Inter)
	constant ^author = "Jonas Q. Duckling"
=
is legal, but:
= (text as Inter)
	constant ^author = "Jonas Q. Duckling"
	variable V_high_scorer = ^author
=
is not, because it tries to use a piece of metadata as if it were data.

@h Types in Inter.
Inter is an exceptionally weakly typed language. It allows the user to choose
how much type-checking is done.

Inter assigns a type to every constant, variable and so on. But by default those
types are always a special type called |unchecked|, which means that nothing
is ever forbidden. This is true even if the type seems obvious:
= (text as Inter)
	constant SPEED_LIMIT = 20
=
gives |SPEED_LIMIT| the type |unchecked|, not (say) |int32|. If a storage object
such as a variable has type |unchecked|, then anything can be put into it; and
conversely an |unchecked| value can always be used in any context.

So if we want a constant or variable to have a type, we must give it explicitly:
= (text as Inter)
	constant (int32) SPEED_LIMIT = 20
	variable (text) WARNING = "Slow down."
=
The "type marker" |(int32)|, which is intended to look like the C notation for
a cast, gives an explicit type. The following, however, will be rejected:
= (text as Inter)
	constant (int32) SPEED_LIMIT = 20
	variable (text) WARNING = SPEED_LIMIT
=
This is because |WARNING| has type |text| and cannot hold an |int32|. This is
typechecking in action, and although you must volunteer for it, it is real.
By conscientiously applying type markers throughout your program, you can
use Inter as if it were a typed language.

@ An intentional hole in this type system is that literals which look wrong for
a given type can often be used as them. This, for instance, is perfectly legal:
= (text as Inter)
	constant (text) SPEED_LIMIT = 20
	variable (int32) WARNING = "Slow down."
=
The type of a constant or variable is always either |unchecked| or else is
exactly what is declared in brackets, regardless of what the value after the
equals sign looks as if it ought to be. However, a weaker form of checking
is actually going on under the hood: numerical data has to fit. So for example:
= (text as Inter)
	constant (int2) true = 1
	constant (int2) false = 0
	constant (int2) dunno = 2
=
allows |true| and |false| to be declared, but throws an error on |dunno|,
because 2 is too large a value to be stored in an |int2|. Even this checking
can be circumvented with a named constant of type |unchecked|, as here:
= (text as Inter)
	constant dangerous = 17432
	constant (int2) safe = dangerous
=
This is allowed, and the result may be unhappy, but the user asked for it.

@ Types are like values in that simple ones can be used directly, but to
make more complicated ones you need to give them names. The analogous
instruction to |constant|, which names a value, is |typename|, which names
a type.

The basic types are very limited: |int2|, |int8|, |int16|, |int32|, |real|
and |text|. These are all different from each other, except that an |int16|
can always be used as an |int32| without typechecking errors, but not vice
versa; and so on for other types of integer.

Note that Inter takes no position on whether or not these are signed; the
literal |-6| would be written into an |int8|, an |int16| or an |int32| in
a twos-complement signed way, but Inter treats all these just as bits.

With just five types it really seems only cosmetic to use |typename|:
= (text as Inter)
	typename boolean = int2
	constant (boolean) true = 1
	variable (boolean) V_flag = true
	typename truth_state = boolean
=
But what brings |typename| into its own is that it allows the writing of
more complex types. For example:
= (text as Inter)
	typename bit_stream = list of int2
	constant (bit_stream) signal = { 1, 0, 1, 1, 0, 1 }
	variable (bit_stream) V_buffer = signal
=
|list of T| is allowed only for simple types |T|, so |list of list of int32|,
say, is not allowed: but note that a typename is itself a simple type. So:
= (text as Inter)
	typename bit_stream = list of int2
	typename signal_list = list of bit_stream
	constant (bit_stream) signal1 = { 1, 0, 1, 1, 0, 1 }
	constant (bit_stream) signal2 = { }
	constant (bit_stream) signal3 = { 0, 1, 1 }
	constant (signal_list) log = { signal1, signal2, signal3 }
	variable (signal_list) V_buffer = log
=
will create a variable whose initial contents are a list of three lists of |int2|
values.

@ The "type constructions" allowed are as follows:

(*) |list of T| for any simple type or typename |T|;

(*) |function T1 T2 ... Tn -> T| for any simple types |T1|, |T2|, and so on.
In the special case of no arguments, or no result, the notation |void| is
used, but |void| is not a type.

(*) |struct T1 T2 ... Tn| for any simple types |T1|, |T2|, and so on. There
must be at least one of these, so |struct void| is not allowed.

(*) |enum|, for which see below;

(*) and then a raft of constructions convenient for Inform but which Inter
really knows nothing about: |column of T|, |table of T|, |relation of T1 to T2|,
|description of T|, |rulebook of T|, and |rule T1 -> T2|. Perhaps these ought
to work via a general way for users to create new constructors, but for now
they are hard-wired. They do nothing except to be distinct from each other,
so that Inform can label its data.

Inter applies the usual rules of covariance and contravariance when matching
these types. For example:

(*) |list of int2| matches |list of int32| but not vice versa (covariance
in the entry type);

(*) |function int32 -> void| matches |function int2 -> void| but not vice versa
(contravariance in argument types);

(*) |function text -> int2| matches |function text -> int32| but not vice versa
(covariance in result types).

@ This enables us to declare the type of a function. A typed version of |Hello|
might look like this:
= (text as Inter)
package main _plain
	typename void_function = function void -> void
	package (void_function) Main _code
		code
			inv !enableprinting
			inv !print
				val "Hello, world.\n"
=
And similarly:
= (text as Inter)
	typename ii_i_function = function int32 int32 -> int32
	package (ii_i_function) gcd _code
		...
=
creates a function called |gcd| whose type is |int32 int32 -> int32|.
Note that only |_code| packages are allowed to be marked with a type, because
only |_code| package names are values.

@ As an example of structures:
= (text as Inter)
	typename city_data = struct real real text
	constant (city_data) L = struct{ r"+51.507", r"-0.1275", "London" }
	constant (city_data) P = struct{ r"+48.857", r"+2.3522", "Paris" }
=

@h Enumerations and instances.
That leaves enumerations, which have the enigmatically concise type |enum|.
Only a typename can have this type: it may be concise but it is not simple. (So
|list of enum| is not allowed.) |enum| is special in that each different time
it is declared, it makes a different type. For example:
= (text as Inter)
	typename city = enum
	typename country = enum
	typename nation = country
=
Here there are two different enumerated types: |city| and another one which
can be called either |country| or |nation|.

As in many programming languages, an enumerated type is one which can hold only
a fixed range of values known at compile time: for example, perhaps it can hold
only the values 1, 2, 3, 4. An unusual feature of Inter is that the declaration
does not specify these permitted values. Instead, they must be declared
individually using the |instance| instruction. For example:
= (text as Inter)
	typename city = enum
	instance (city) Berlin
	instance (city) Madrid
	instance (city) Lisbon
=
For obvious reasons, the type marker -- in this case |(city)| -- is compulsory,
not optional as it was for |constant|, |variable| and |package| declarations.

At runtime, the values representing these instances are guaranteed to be different,
but we should not assume anything else about those values. The final code-generator
may choose to number them 1, 2, 3, but it may not. (When enumerations are used by
the Inform 7 tool-chain for objects, the runtime values will be object IDs in the
Z-machine or pointers to objects in Glulx or C, for instance.)

If we need specific numerical values (which must be non-negative), we can specify
that explicitly:
= (text as Inter)
	typename city = enum
	instance (city) Berlin = 1
	instance (city) Madrid = 17
	instance (city) Lisbon = 201
=
You should either specify values for all instances of a given enumeration, or none.

Note that instances do not have to be declared in the same package, or even the
same program, as the enumeration they belong to.

@h Subtypes.
Enumerated types, but no others, can be "subtypes". For example:
= (text as Inter)
	typename K_thing = enum
	typename K_vehicle <= K_thing
	typename K_tractor <= K_vehicle
=
An instance of |K_tractor| is now automatically also an instance of |K_vehicle|,
but the converse is not necessarily true.

The right-hand side of the |<=| sign is only allowed to be an enumerated typename,
and a new typename created in this way is, for obvious reasons, also enumerated.

@h Properties.
Inter supports a simple model of properties and values. (An enumerated typename
is in effect a class, and this is why instances are so called.)

A property is a set of similarly-named variables belonging, potentially, to
any number of owners, each having their own value. As with constants and
variables, properties can optionally have types. For example:
= (text as Inter)
	property population
	property (text) motto
=
Any instance can in principle have its own copy of any property, and so can
an enumerated type as a whole. But this is allowed only if an explicit
permission is granted:
= (text as Inter)
	typename city = enum
	instance (city) Stockholm
	instance (city) Odessa
	permission for city to have population
	permission for Odessa to have motto
=
And we can now use the |propertyvalue| instruction to set these:
= (text as Inter)
	propertyvalue population of Stockholm = 978770
	propertyvalue population of Odessa = 1015826
	propertyvalue motto of Odessa = "Pearl of the Black Sea"
=

@ An optional extended form of |permission| is allowed which enables us to say
that we want the storage for a property to be in a given list. Thus:
= (text as Inter)
	constant population_storage = { 2, 978770, 1015826 }
	typename city = enum
	instance (city) Stockholm
	instance (city) Odessa
	property population
	permission for city to have population population_storage
=
But this is finicky, and has to be set up just right in order to work.[1]

[1] The feature exists in Inter because of Inform 7's ability to define kinds
with tables, so that the storage lists are the columns of the table in
question. Because I7 allows those properties to be modified or read either
qua properties or qua table entries, we cannot avoid giving Inter a similar
ability, even though we might prefer not to.

@h Insert.
Never use |insert|.

@ Well, okay then. This exists to implement very low-level features of Inform 7,
going back to its earliest days as a programming language, when people were
still writing strange hybrid programs partly in I6.

|insert| tells Inter that it needs to add this raw I6-syntax material to the
program:
= (text as Inter)
	insert "\n[ LITTLE_USED_DO_NOTHING_R; rfalse; ];\n"
=

@h Splats.
And never use |splat| either.

@ Well, okay then. We do in fact temporarily make splats when compiling kit
source, written in Inform 6 syntax, into Inter. During that process, there are
times when the source code is only partially digested. Each individual I6-syntax
directive is converted into a "splat" holding its raw text. But this is then
later translated into better Inter, and the splat removed again. For details,
if you really must, see //bytecode: The Splat Construct//.

The name "splat" is chosen as a psychological ploy, to make people feel queasy
about using this. See also "glob" above, which is the analogous construction
for values rather than void-context material.
