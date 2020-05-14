[AboutPreform::] About Preform.

A brief guide to Preform and how to use it.

@ Preform is a meta-language for writing a simple grammar: it's in some sense
pre-Inform, because it defines the Inform language itself, and has to be read
by the //words// module (on behalf of Inform) before Inform can parse anything.
For example,
= (text as Preform)
	<competitor> ::=
		<ordinal-number> runner |
		runner no <cardinal-number>
=
The |::=| indicates a definition: the following-on lines, divided by the
vertical stroke, are possibilities tried in turn. Each "non-terminal", written
in angle brackets, can in principle match (or not match) against any wording.
When writing code in InC (the slight extension of C granted by inweb: see
//inweb: The InC Dialect//), this can actually be written as a function call:
= (text as C)
	if (<competitor>(W)) ...
=
This function returns |TRUE| if a match is made, and |FALSE| if it is not.
But if a match is indeed made, there are side-effects too, as we shall see.

So, for example, the above grammar would match any of these possibilities:
= (text)
	7th runner
	third runner
	runner no 7
	runner no three
=
but would fail, for example,
= (text)
	runner
	7 runner
	runner no 7th
	ice cream sandwich
=
A small number of nonterminals are "internal", meaning that they are defined
by the Inform compiler modules; all of the rest are defined rather like
|<competitor>|, i.e., with grammar spelled out.

@ Preform grammar is stored in a text file which is read by Inform early in
its run: see //LoadPreform::load//. In principle, different natural language
definitions can be made: thus, French translators could supply a French-localised
Preform grammar. In practice this whole area of Inform needs more work before
it can really advance. Still, the principle is that the user can therefore
modify the underlying grammar used by Inform.

The standard Inform distribution comes with the English Preform: in fact, the
file is in |inform7/Internal/Languages/English/Syntax.preform|. However,
this file is not the "original": it is mechanically generated from the source
code of Inform by //inweb//. For example, the excerpt of grammar might have
come from some (hypothetical) source code looking like this:
= (text as Preform)
	<competitor> ::=
		<ordinal-number> runner |    ==> TRUE
		runner no <cardinal-number>  ==> FALSE
=
Definitions like this one are scattered all across the Inform web, in order
to keep them close to the code which relates to them. //inweb// tears this
code in half lengthways: the left-hand side goes into the |Syntax.preform|
file mentioned above, and is then read into Inform at run-time; and the
right-hand side, which is essentially C, becomes a function definition.
What that function does is to produce suitable results in the event that
the nonterminal makes a successful match against some wording.

@ Each nonterminal, when successfully matched, can provide both or more usually
just one of two results: an integer, to be stored in a variable called |*X|,
and a void pointer, to be stored in |*XP|, which is usually an object.

The example above, |<competitor>|, only results in an integer. The |==>| arrow
is optional, but if present, it says what the integer result is if the given
production is matched. So, for example, "runner bean" or "beetroot" would not
match <competitor>; "4th runner" would match with integer result |TRUE|;
"runner no 17" would match with integer result |FALSE|.

Usually, though, the result(s) of a nonterminal depend on the result(s) of
other nonterminals used to make the match. If that's so, then the expression
to the right of the arrow will have to combine these. In such a compositing expression,
so called because it composes together the various intermediate results into
one final result, |R[1]| is the integer result of the first nonterminal in
the production, |R[2]| the second, and so on; |RP[1]| and so on hold the
pointer results. Here, on both productions, there's just one nonterminal
in the line, <ordinal-number> in the first case, <cardinal-number> in
the second.

Consider the following refinement of <competitor>:
= (text as Preform)
	<competitor> ::=
		the pacemaker |              ==> 1
		<ordinal-number> runner |    ==> R[1]
		runner no <cardinal-number>  ==> R[1]
=
Now "4th runner" matches with integer result 4, because <ordinal-number>
matches "4th" with integer result 4, and that goes into |R[1]|. Similarly,
"runner no 17" ends up with integer result 17. "The pacemaker" matches
with integer result 1; here there are no intermediate results to make use
of, so |R[...]| can't be used.

@ The arrows and expressions are optional, and if they are omitted, then the
result integer is set to the alternative number, counting up from 0. For
example, given the following, "polkadot" matches with result 1, and "green"
with result 2.
= (text as Preform)
	<race-jersey> ::=
		yellow | polkadot | green | white
=
