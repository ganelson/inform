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
by the Inform compiler modules; all of the rest are called "regular" and are
defined rather like <competitor>, i.e., with grammar spelled out.

@ Preform grammar is stored in a text file which is read by Inform early in
its run: see //LoadPreform::load//. In principle, different natural language
definitions can be made: thus, French translators could supply a French-localised
Preform grammar. In practice this whole area of Inform needs more work before
it can fully advance. Still, the principle is that the user can therefore
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
right-hand side, which is essentially C, becomes code which takes action
on any successful match against the grammar.

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
right of the arrow will have to combine these. In such a compositing expression,
so called because it composes together the various intermediate results into
one final result, |R[1]| is the integer result of the first nonterminal in
the production, |R[2]| the second, and so on; |RP[1]| and so on hold the
pointer results. For example, you could make a very crude calculator with:
= (text as Preform)
	<arithmetic> ::=
		<cardinal-number> |                       ==> R[1]
		<cardinal-number> plus <cardinal-number>  ==> R[1]+R[2]
=
Here |R[1]+R[2]| produces a result by composition of the two results of
the <cardinal-number> nontermimal which occurred when parsing the line.
So, for example, "seven" matches <arithmetic> with result 7, and "two plus
three" with result 5.

Or consider the following refinement of <competitor>:
= (text as Preform)
	<competitor> ::=
		the pacemaker |              ==> { 1, - }
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

@ As a convenient abbreviation, a slash character can be used to divide
alternative possibilities for a single word. For example:
= (text as Preform)
	<race-jersey> ::=
		yellow | polkadot/polka-dot | green | white
=
matches "polka-dot" equivalently to "polkadot".

Another convenient notation is the caret |^|, which negates the effect of
a token. For example,
= (text as Preform)
	<competitor> ::=
		the ^adjudicator  ==> { 1, - }
=
matches "the pacemaker", "the cyclist", etc. -- the anything at all, but not
"the adjudicator".

The final modifying notation is the underscore |_|, which forbids unexpected
use of upper casing. Thus
= (text as Preform)
	<race-jersey> ::=
		yellow | polkadot | _green | white
=
means that it will match Yellow, yellow, Polkadot, polkadot, green, White
and white, but not Green (except as the first word of a sentence, where
the use of capitalisation has no significance).

If the modifiers |^| or |_| are given for the first of a series of slashed
alternatives, they apply to all of the alternatives: thus |^cat/dog| matches
any word which is neither "cat" nor "dog".

If these characters are needed in their literal form, a backslash |\| can
be used to escape them. Thus |\_green| actually matches |_green|.

@ So far, the only ingredients of Preform syntax have been nonterminals and
fixed words, but Preform also has "wildcards". For example, in
= (text as Preform)
	<competitor> ::=
	    man with ... on his ...
=
would match, for example, "man with number 17 on his back", or "man with a
chip on his shoulder". |...| matches any non-empty wording, and the text
actually matched is recorded for any successful match. Wordings like this
are numbered upwards from 1 to a maximum of 4, and are usually retrieved by
whatever part of Inform requested the parse, using the |GET_RW| macro. For
example:
= (text)
TEXT                              GET_RW(<competitor>, 1)   GET_RW(<competitor>, 2)
man with number 17 on his back    number 17                 back
man with a chip on his shoulder   a chip                    shoulder
=
A few internal nonterminals also generate word ranges, using |PUT_RW| to do so,
and word ranges can also be inherited up from one nonterminal to another with
|INHERIT_RANGES|: see //Loading Preform// for definitions of these macros.

There are in fact several different wildcards:
(a) |...| matches any non-empty text, as shown above.
(b) |***| matches any text, including possibly the empty text.
(c) |......| matches any non-empty text in which brackets are used in a
balanced way -- thus they would match "alpha beta gamma" or "alpha (the
Greek letter)", but not "alpha (the" or "Greek letter)".
(d) |###| matches any single word, counting words as the lexer does.

It is also possible to use braces to widen ranges. For example,
= (text as Preform)
	<competitor> ::=
	    man with {... on his ...}
=
groups together anything matching |... on his ...| into a single range. There
need not even be a wildcard inside the braces:
= (text as Preform)
	<competitor> ::=
	    {man} with {... on his ...}
=
works fine, and makes two ranges, the first of which is always just "man".

Once again, literal brace characters can be achieved using the |\| escape.

@ The alternative lines (or "productions", as they're called) in a regular
definition are normally given the internal numbers 0, 1, 2, 3... in the
order in which they appear. For example, in
= (text as Preform)
	<competitor> ::=
		the pacemaker |              ==> { 1, - }
		<ordinal-number> runner |    ==> R[1]
		runner no <cardinal-number>  ==> R[1]
=
the |the pacemaker| row is numbered 0, |<ordinal-number> runner| is numbered 1,
and so on. Those "match numbers" have little outward significance, but help
to determine the result when a successful match is made. Consider:
= (text as Preform)
	<letter-score> ::=
		alpha |  ==> { 10, - }
		beta |   ==> { 20, - }
		gamma    ==> { 30, - }
=
Here, matching against "beta" produces 20 -- the result on the same row. But
we can mess with that:
= (text as Preform)
	<letter-score> ::=
		/c/ alpha |  ==> { 10, - }
		/a/ beta |   ==> { 20, - }
		/b/ gamma    ==> { 30, - }
=
The special notation |/X/|, where |X| is a lower-case letter, marks the row
as having a different number from the obvious one. |/a/| means 0, |/b/| means
1, and so on. The practical effect of the above is to achieve the equivalent
of this:
= (text as Preform)
	<letter-score> ::=
		beta |  ==> { 10, - }
		gamma | ==> { 20, - }
		alpha   ==> { 30, - }
=
That might seem a stupidly obfuscatory thing to do, and indeed it is, when
done in the main Inform source code -- which is why we never do it. But
Preform can also be used by translators of Inform to other languages, who might
supply, e.g., a French version of |Syntax.preform|. Or suppose in this instance
that the Inform source code contains <letter-score> but that a translator into
Hebrew wants to override that definition. Her Hebrew version of |Syntax.preform|
could then write:
= (text as Preform)
	<letter-score> ::=
		/a/ aleph |
		/a/ alef |
		/b/ beth
=
This translator wanted to provide two alternative ways to write the Hebrew
version of "alpha", one for "beta", but none for "gamma". Using the remappings
|/a/| and |/b/| here, she is able to make her lines behave as if they were
lines 1, 1, 2 of the original, rather than 1, 2, 3, which would have been the
default.

Because there are a few rather long nonterminal definitions in Inform, the
labelling runs |/a/|, |/b/|, ..., |/z/| and then continues |/aa/|, |/bb/|,
..., |/zz/|, thus allowing for up to 52 productions to be remapped in this way.

@ A similar form if remapping is allowed with word ranges, using a special
notation. Suppose the Inform source contained:
= (text as Preform)
	<coloured-thing> ::=
		{ <race-colour> } { jersey/helmet }		
=
but we want this in French, where adjectives usually come after nouns. So this:
= (text as Preform)
	<coloured-thing> ::=
		{ maillot/casque } { <race-colour> }
=
wouldn't work -- it would set the word ranges the wrong way around. Instead:
= (text as Preform)
	<coloured-thing> ::=
		{ maillot/casque }?2 { <race-colour> }?1
=
says that word range 2 is to be the article of clothing, and word range 1 the
colour.

@ Preform turns out to be a useful notation for patterns of wording, and can
be put to other uses besides parsing source text. For these other uses, see
//Preform Utilities//. Specifically, and in rough order of complexity:

(*) Specifying text being generated by Inform -- see //PreformUtilities::merge//.

(*) Specifying replacements of one set of words by another -- see
//PreformUtilities::find_corresponding_word//.

(*) Specifying miscellaneous entries for the lexicon in the Inform index -- see
//PreformUtilities::enter_lexicon//.

(*) Saying how to build a trie which will detect patterns in a single word and
then modify it -- see //PreformUtilities::define_trie//.

@ Finally, syntax errors in Preform are reported by //PreformUtilities::production_error//.
