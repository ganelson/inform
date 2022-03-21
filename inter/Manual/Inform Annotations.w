Inform Annotations.

The standard set of symbol annotations used within Inform.

@h Status.
The Inter specification allows for any number of annotations to be used;
none are required. The ones listed below are those used in the Inform toolchain
at present.

As a general guideline, annotations are best used for temporary storage during
complex operations (optimisation, code generation, and so on), rather than for
information which changes the functionality of a program. But this is only a
guideline, and several of the cases below could be argued to break it.

What is certainly true is that we want to avoid annotations if there are better
ways to achieve the same thing. At one time there were over 30 in use, but the
figure is now below 10.

@h Translation.
The final code we generate is itself (probably) the source code of a program
in some other language -- C, for example. That means that most of the symbols
in our Inter program will be "translated" into identifiers in that final
program. For example, the Inter declaration:
= (text as Inter)
	constant BakersDozen = 13
=
might ultimately be compiled to:
= (text as C)
	#define CON_019900_BKRSDZN 13
=
An exaggerated example, perhaps, but the point is that it's normally none of
our business what identifiers the final code-generator chooses to use.

However, we can override its choice like so:
= (text as Inter)
	constant BakersDozen = 13 __translation="BAKERS_DOZEN"
=
And now it would come out as:
= (text as C)
	#define BAKERS_DOZEN 13
=

The |__translation| annotation is sometimes added by the final code-generator
itself, to keep track of its translation decisions, but can also be added by
the Inform 7 front-end compiler. Ideally it wouldn't ever do so, but this is
the only sensible way to implement the low-level language feature:
= (text as Inform 7)
The tally is a number that varies. The tally translates into Inter as "SHAZAM".
=
And this is in turn is a feature we can't simply abolish, or not without
inventing some similar bodge, because it's needed in order to reconcile the
natural-language names for certain standard properties (e.g., "lighted")
with their kit-source equivalents (e.g. |lit|).

@h Append.
Like the |insert| instruction (see //Data Packages in Textual Inter//), the
|__append| annotation subverts Inter by writing some code in raw Inform 6
syntax. This can be added to any definition of an instance of an object type,
or to the type itself.

For example, the I7 source text:
= (text as Inform 7)
Include (- has door, -) when defining a door.
=
leads to:
= (text as Inter)
	kind K4_door <= K1_thing __append=" has door, "
=

Whereas to some extent |insert| can work even if the target is not I6, the
|__append| annotation ties the program to I6 only. At some point we may
simply abolish the "Include... when defining..." feature from I7, and then
we'll gladly remove |__append|. Consider it deprecated already.

@h Assimilation markers.
Every symbol (other than a function name) whose definition was assimilated from
Inform 6-syntax code in the source of a kit is given the boolean annotation
|__assimilated|.

In addition, if the definition is of a fake action or an object, the annotation
|__fake_action| or |__object| will be applied. For example:

= (text as Inform 6)
Constant Dozen = 12;
Fake_action PluralFound;
Object thedark "(darkness object)";
=
assimilates to:
= (text as Inter)
	package Dozen_con _plain
		constant Dozen = 12 __assimilated
	package ##PluralFound_con _plain
		constant ##PluralFound = 0 __assimilated __fake_action
	package thedark_con _plain
		constant thedark = 0 __assimilated __object
=
See the Inter test case |Assim|.

These three markers are applied only during assimilation, and thus only by Inter.
The main Inform 7 compiler never applies them.

It would be feasible to combine these three annotations into a single one, say
|__assimilated_from="DIRECTIVE"|, marking everything with the I6 directive it
came from. But while that would be elegant it would cost storage and time.
Boolean annotations are cheaper, and |__assimilated| occurs a lot.

@h Miscellaneous code-generation storage.
As noted above, the main use case intended for annotations is as a way for
optimisation or code-generation pipeline steps to attach notes to the tree.
These are of no significance once those steps are complete, and do not change
the meaning of the program.

They can also come or go without notice; they are not really part of the Inter
specification at all. But briefly, the current set used is:

|__inner_property_name="NAME"| is used by //final: Vanilla Objects// to mark
which property name belongs to which two-word property array.

|__object_kind_counter=NUMBER| is used by //pipeline: Kinds// to number off
the kinds of object found in the program.

|__array_address=NUMBER| is used by //final: C Memory Model// to mark the
address in process memory of each array.

|__global_offset=NUMBER| is used by //final: Inform 6 Global Variables// to
mark where in its array of global variables a given variable lives.
