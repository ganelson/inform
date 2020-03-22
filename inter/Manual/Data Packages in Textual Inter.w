Data Packages in Textual Inter.

How static data, variables and constants are expressed in textual inter programs.

@h Data packages.
To recap: a file of textual inter has a brief global section at the top, and
is then a hierarchiy of package definitions. Each package begins with a
symbols table, but then has contents which depend on its type. This section
covers the possible contents for a data package, that is, one whose type
is not |_code|. Note that, in particular, the |main| package is always a
data package, so there must be at least one in the program.

"Data" is a slightly loose phrase for what data packages contain: it
includes metadata, and indeed almost anything other than actual executable
code. Data packages, unlike code packages, can also contain other packages
(of either sort).

@h Kinds and values.
Inter is a very loosely typed language, in the sense that it is possible
to require that values conform to particular data types. As in Inform, data
types are called "kinds" in this context (which usefully distinguishes them
from "types" of packages, a completely different concept).

No kinds are built in: all must be declared before use. However, these
declarations are able to say something about them, so they aren't entirely
abstract. The syntax is:

	|kind NAME CONTENT|

The |NAME|, like all names, goes into the owning package's symbol table;
other packages wanting to use this kind will have to have an |external|
symbol pointing to this definition.

|CONTENT| must be one of the following:

(a) |unchecked|, meaning that absolutely any data can be referred to by this type;
(b) |int32|, |int16|, |int8|, |int2|, for numerical data stored in these numbers
of bits (which the program may choose to treat as character values, as flags,
as signed or unsigned integers. and so on, as it pleases);
(c) |text|, meaning text;
(d) |enum|, meaning that data of this kind must be equal to one (and only one)
of the enumerated constants with this kind;
(e) |table|, a special sort of data referring to tables made up of columns each
of which has a different kind;
(f) |list of K|, meaning that data must be a list, each of whose terms is
data of kind |K| -- which must be a kind name known to the symbols table
of the package in which this definition occurs;
(g) |column of K|, similarly, but for a table column;
(h) |relation of K1 to K2|, meaning that data must be such a relation, in the
same sort of sense as in Inform;
(i) |description of K|, meaning that data must be a description which either
matches or does not match values of kind |K|;
(j) |struct|, which is similar to |list of K|, but which has entries which do
not all have to have the same kind;
(k) and |routine|, meaning that data must be references to functions.

For example:

	|kind k_boolean int2|
	|kind k_list_of_bool list of k_boolean|
	|kind K_grammatical_tense enum|

@ In the remainder of this specification, |VALUE| means either the name of
a defined |constant| (see below), or else a literal.

A literal |int32|, |int16|, |int8|, or |int2| can be written as any of the
following:
(a) a decimal integer which may begin with a minus sign (and, if so, will be
interpreted as twos-complement signed);
(b) a hexadecimal imteger prefixed with |0x|, which can write the digits
|A| to |F| in either upper or lower case form, but cannot take a minus sign;
(c) a binary integer prefixed with |0b|, which cannot take a minus sign.

For example, |-231|, |0x21BC| and |0b1001001| are all valid. If the literal
supplied is too large to fit into the kind, an error is thrown.

A literal |list| is writtem in braces: |{ V1, V2, ..., Vn }|, where |V1|, 
|V2| and so on must all be acceptable literals for the entry kind of the
list. For example, |{ 2, 3, 5, 7, 11, 13, 17, 19 }|. The same notation is
also accepted for a |struct|, a |column| or a |table|. For example:

	|constant C_egtable_col1 K_column_of_number = { 1, 4, 9, 16 }|
	|constant C_egtable_col2 K_column_of_colour = { I_green, undef, I_red }|
	|constant C_egtable K_table = { C_egtable_col1, C_egtable_col2 }|

A list-like notation can also be used for a "calculated literal". This is
a single value, but which we may not be able to evaluate at inter generation
time. For example, if we do not yet know the value of |X|, we can write
|sum{ X, 1 }| to mean |X+1|. A present, addition is the only operation
catered for in this way.

A literal |text| is written in double quotes, |"like so"|. All characters
within such text must have Unicode values of 32 or above, except for tab (9),
writtem |\t|, and newline (10), written |\n|. In addition, |\"| denotes a
literal double-quote, and |\\| a literal backslash, but these are the only
backslash notations at present allowed.

There are then a number of notations which look like texts, prefixed by
indicative characters.

|r"text"| makes a literal real number: the text is required to take the
same form as a literal real number in Inform 6. The result is valid
for use in an |int32|, where it is interpreted as a float. For example,
|r"$+1.027E+5"|.

|dw"text"| is meaningful only for interactive fiction, and represents the
command parser dictionary entry for the word |text|. This is equivalent
to the Inform 6 constant |'text//'|. |dwp"text"| is the same, but pluralised,
equivalent to Inform 6 |'text//p'|. Again, these can be stored in an |int32|.

|&"text"| makes a literal value called a "glob". This is not a respectful
term, and nor does it deserve one. A glob is a raw Inform 6 expression,
which can't (easily) be compiled for any other target, but is simply
copied literally through. Its kind is |unchecked|, so it can be used
absolutely anywhere.

|^"text"| is not really a value at all, and is called a "divider". This
is really a form of comment used in the middle of long lists. Thus the
list |{ 1, 2, ^"predictable start", 3721, -11706 }| is actually a list of four values
but which should be compiled on two lines with the comment in between:

	|1, 2, ! predictable start|
	|3721, -11706|

(As unnecessary as this feature seems, it does make the code produced by
Inform look a lot more readable when it finally reaches Inform 6.)

The literal |undef| can be used to mean "this is not a value".

Convention. It is intended that Inform will never make use of globs, but
at present about 30 globs persist in typical inter produced by Inform.
None of these are generated by Inform 7 as such: they all arise from the
oddball expressions in the template code which the code generator can't
(yet) assimilate.

Inform generates |undef| values to represent missing entries in tables,
but otherwise makes no use of them.

@ Kinds have "default values": if some piece of storage has to hold a value
of kind |K|, but that value is not specified, then the default is used.
For example, the default |int32| is zero.

This can be controlled using |defaultvalue KIND = VALUE|. For example,

	|defaultvalue K_boolean = 0|

@h Enumerations and instances.
As noted above, some kinds marked as |enum| are enumerated. This means
that they can have only a finite number of possible values, each of which
is represented in textual inter by a different name.

These values are called "instances" and must also be declared. For example:

	|kind K_grammatical_tense enum|
	|instance I_present_tense K_grammatical_tense|
	|instance I_past_tense K_grammatical_tense|

It is also possible to specify numerical values to be used at run-time:

	|instance I_present_tense K_grammatical_tense = 1|

If so, then such values must all be different (for all instances of that kind).
Enum values must fit into an |int16|.

Enumerations, but no other kinds, may have "subkinds", as in this example:

	|kind K_object enum|
	|kind K1_room <= K_object|

This creates a new |enum| kind |K1_room|. Values of this are a subset of
the values for its parent, |K_object|: thus, an instance of |K1_room| is
automatically also an instance of |K_object|. This new subkind can itself
have subkinds, and so on.

@h Properties of instances.
A "property" is a named value attached to all instances of a given kind,
and must be created before use with:

	|property NAME KIND|

which declares that |NAME| is a property whose value has the given |KIND|;
however, it doesn't say which kind(s) can have this property, so we also
have to give one or more "permissions", in the form

	|permission NAME KIND|

And once that is done, actual values can be assigned with:

	|propertyvalue NAME OWNER = VALUE|

where |OWNER| can either be the name of a whole kind, in which case this sets
the default value of the property for instances of that kind, or else the name
of a specific instance, in which case this sets just the property of a single
thing. In either case, it is an error to do this unless the necessary
permission has been established.

The given value is just the initial state; at run-time, it can be changed to
another value (of the same kind).

For example:

	|kind K_object enum|
	|kind K_text text|
	|property P_printed_name K_text|
	|permission P_printed_name K_object|
	|propertyvalue P_printed_name K_object = "something"|
	|instance I_ball K_object|
	|propertyvalue P_printed_name I_ball = "beach ball"|

@h Constants.
A constant definition assigns a name to a given value: where that name is
used, it evaluates to this value. The syntax is:

	|constant NAME KIND = VALUE|

where the value given must itself be a constant or literal, and must conform
to the given kind. As always, this is conformance only in the very weak
system of type checking used by Inter: if either the value or the constant
has an |unchecked| kind, then the test is automatically passed.

For example,

	|kind K_number int32|
	|constant favourite_prime K_number = 16339|

Constants can have any kind, including enumerated ones, but if so then that
does not make them instances. For example,

	|kind K_colour enum|
	|instance C_red K_colour|
	|instance C_green K_colour|
	|constant C_favourite K_colour = C_green|

does not make |C_favourite| a new possible colour: it's only a synonym for
the existing |C_green|.

@ If a constant needs to refer to a function, we seem to run into the limitation
that there's no notation for literal functions. In fact there is, though:
that's what code packages are. For example,

	|kind K_number int32|
	|kind K_number_to_number K_number -> K_number|
	|package R_101_B _code|
	|    ...|
	|constant R_101 K_number_to_number = R_101_B|

defines the constant |R_101|. Note that |R_101_B| is not a value, because
package names are not values; but |R_101| on the other hand is a value, and
can be stored and used at run-time like any other value.

@h Global variables.
Variables are like properties, except that each exists only as a single
value, not attached to any instance in particular: it makes no sense to ask
who the owner is. Variables must be declared as:

	|variable NAME KIND = VALUE|

The given value is just the initial state; at run-time, it can be changed to
another value (of the same kind). For example,

	|variable V_score K_number = 10|

@h Responses.
A "response" is a special sort of property belonging to a function rather than
an instance: it's a piece of text. This can be set with:

	|response NAME MARKER FUNCTION = VALUE|

|NAME| provides a unique symbol name identifying this specific response; this
is needed so that other code elsewhere in the program can alter this response
at run-time. |MARKER| indicates which of 26 possible responses is meant: in
high-level Inform 7 code these are labelled with the letters A to Z, but in
inter, the numbers 0 to 25 must be used. The |VALUE| must be textual, that is,
must be a |text| literal.

@h Metadata.
This has no effect on the code generated, and is simply semantic markup for
the benefit of onlookers. The scheme here is that any package can have a
dictionary of textual key-value pairs, specified by:

	|metadata KEY: VALUE|

Here |KEY| must be a (public) symbol whose name begins with a backtick, and
|VALUE| must be literal text. For example:

	|metadata `name: "blue book"|

@h Append and Link.
Two rather ugly constructs are currently needed in order to implement very
low-level features of Inform 7, at points in I7's design where the normally
subterranean presence of Inform 6 pokes up above the surface:

|append NAME "RAW I6 CODE"| tells Inter to add the given raw code to whatever
it compiles as the definition (in I6) of whatever the symbol |NAME| refers to.
For example, the I7 source text:

>> Include (- has door, -) when defining a door.

results in the following inter being generated:

	|append K4_door " has door, \n"|

|link STAGE "SEGMENT" "PART" "CONTENT" "OTHER"| tells Inter that it needs
to make an alteration to the Inform 6 code inside the I6T template file
|SEGMENT|, at heading |PART|; the |STAGE| must be one of |early|, |before|,
|instead| or |after|. For example:

	|link after "Output.i6t" "I6 Inclusions" "\n[ LITTLE_USED_DO_NOTHING_R; rfalse; ];\n" ""|

@h Nop.
The "nop" statement has no textual representation. It does nothing, and exists
only as a convenience used by Inform when it needs to write simultaneously to
multiple positions within the same node's child list -- the idea being that
a nop statement acts as a divider. For example, by placing the A write
position just before a nop N, and the B write position just after, Inform
will generate A1, A2, A3, ..., N, B1, B2, ..., rather than (say) A1, B1, A2,
A3, B2, ... The extra N is simply ignored in code generation, so it causes
no problems to have it.
