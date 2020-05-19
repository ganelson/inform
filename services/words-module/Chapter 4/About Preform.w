[AboutPreform::] About Preform.

A brief guide to Preform and how to use it.

@h A Manual for Preform.
Preform is a meta-language for writing a simple grammar: it's in some sense
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

@ The material to the right of the |==>| is actually regular C code, and can
do more than simply evaluate one expression. For example, it can also set
the pointer result of the nonterminal; here, let's suppose, that will be a
pointer to a |text_stream|.
= (text as Preform)
	<competitor> ::=
		the pacemaker |              ==> 1; *XP = I"unnumbered";
		<ordinal-number> runner |    ==> R[1]; *XP = I"numbered";
		runner no <cardinal-number>  ==> R[1]; *XP = I"numbered";
=
It can also, if it wants to, kill off a line:
= (text as Preform)
	<competitor> ::=
		the pacemaker |              ==> 1
		<ordinal-number> runner |    ==> 0; return FALSE;
		runner no <cardinal-number>  ==> R[1]
=
Here a match against |<ordinal-number> runner| is forced to fail at the last
hurdle, just as it was about the succeed; it's as if the second row wasn't
there. (This is not useful unconditionally, but with an |if| statement,
it can be.) More extremely:
= (text as Preform)
	<competitor> ::=
		the pacemaker |              ==> 1
		<ordinal-number> runner |    ==> 0; return FAIL_NONTERMINAL;
		runner no <cardinal-number>  ==> R[1]
=
causes any successful match against |<ordinal-number> runner| not only to be
failed, but to prevent any tries against the rows below it. (This is useful
when issuing problem messages, or to put exceptional syntaxes into the grammar,
since it can make subsequent productions only available in some cases.)

Finally, returning |FAIL_NONTERMINAL + Q|, where |Q| is a number between 1
and, currently, 999, performs a fail but applies a "quantum" to the lookahead
going on when Preform is trying to work out what's happening in a difficult
production using the one being referred to. This allows us to nudge past
potential ambiguities; it's not done much in Inform, but see for example
//if: Action Name Lists//.

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
		the ^adjudicator  ==> 1
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
		the pacemaker |              ==> 1
		<ordinal-number> runner |    ==> R[1]
		runner no <cardinal-number>  ==> R[1]
=
the |the pacemaker| row is numbered 0, |<ordinal-number> runner| is numbered 1,
and so on. Those "match numbers" have little outward significance, but help
to determine the result when a successful match is made. Consider:
= (text as Preform)
	<letter-score> ::=
		alpha |  ==> 10
		beta |   ==> 20
		gamma    ==> 30
=
Here, matching against "beta" produces 20 -- the result on the same row. But
we can mess with that:
= (text as Preform)
	<letter-score> ::=
		/c/ alpha |  ==> 10
		/a/ beta |   ==> 20
		/b/ gamma    ==> 30
=
The special notation |/X/|, where |X| is a lower-case letter, marks the row
as having a different number from the obvious one. |/a/| means 0, |/b/| means
1, and so on. The practical effect of the above is to achieve the equivalent
of this:
= (text as Preform)
	<letter-score> ::=
		beta |  ==> 10
		gamma | ==> 20
		alpha   ==> 30
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

@h Implementation notes.
Most organs of the human body are located in a single place -- the heart, the
appendix, the brain -- but others, like the blood vessels or the nervous
system, are distributed throughout. So also with compilers, but Inform is
unusual in having its syntax analyser be one of these distributed organs.
This was a choice, and it was made in the interests of clarity of the
Inform source code to readers.

In any case, it is only the Preform grammar and the connections to it --
compositor functions, calls to single named nonterminals, and so on -- which
are dispersed throughout the body of Inform. The code to manage, internally
store and parse against Preform is all here in //words//, and the code to
represent the meaning of the result makes up //syntax//.

@ The Preform parser which occupies the entire //Preform// section is a
complex or even ingenious algorithm, which is always suspect. The main points
of difficulty are:

(a) The grammar must not be hard-coded since users need to change it, for
translation or other purposes, so it has to be read in from a file. But it
must also be explicitly referred to in the Inform source code. This is achieved
with a sort of symbiotic relationship between the Inform source code and the
pre-processor for it in //inweb//, which takes action at compile time to
build the syntax file |Syntax.preform| read in, by default, at run time. The
arrangement works well in practice, but needs careful explanation. See
//Loading Preform// for how |Syntax.preform| is read in.

(b) The Preform parser has two design goals: to avoid unpredictable spikes on
time or memory when given very long texts to match, and to be as simple as it
can be, consistent with consuming, in aggregate, no more than 5-10% of the
compiler's running time. It is a non-goal to be a fully general natural
language parser -- if it can cope with Inform's needs, then that is enough.

@ So, then, //LoadPreform::load// loads the Preform grammar for a given
natural language from a file. This becomes a collection of //nonterminal//
objects, each of which is either "internal" or "regular". Regular NTs have
a list of //production_list// objects, one for each natural language in
which they are defined. (The same NT can have one definition in English and
another in, say, French.)

What production lists list is //production// objects, and each of those is
in turn a list of //ptoken// objects.[1] These can also be marked as
negated or can have alternatives supplied. Ptokens come in three varieties:
fixed words, uses of other nonterminals, and wildcards.

For example,
= (text as Preform)
	<product-specification> ::=
		weight <cardinal-number> kg |
		height <cardinal-number> cm |
		colour/color ...
=
would be read into objects in memory as follows:
= (text as BoxArt)
	nonterminal                 REGULAR
	  -> production_list                       for its English definition
	    -> production
	      -> ptoken             FIXED WORD     weight
	      -> ptoken             USAGE          <cardinal-number>
	      -> ptoken             FIXED WORD     kg
	    -> production
		  -> ptoken             FIXED WORD     height
		  -> ptoken             USAGE          <cardinal-number>
		  -> ptoken             FIXED WORD     cm
	    -> production
		  -> ptoken             FIXED WORD     colour
		    -> ptoken           FIXED WORD     color
		  -> ptoken             WILDCARD       ...
=
The above grammar fell under the English production list because that was
the current language when it was read in. The current language can be
changed, e.g.,
= (text as Preform)
    language French

	<product-specification> ::=
		poids <cardinal-number> kg |
		hauteur <cardinal-number> cm |
		couleur ...

	language English
=
changes the language to French, supplies a French version, then changes back
to English. There would then be two production lists for <product-specification>.

[1] The "p" is silent.

@ The most technically difficult code occurs in //The Optimiser//, which
precomputes --

(*) //Length Extremes// to constrain the number of words in any match;
(*) //Nonterminal Incidences// to constrain the type of words in any match;
(*) "positions" of tokens and "struts" (runs of dividing words) inside productions.

These are all devices to enable non-matching text to be rejected quickly.
For example, "fox" cannot match |<s-literal> <s-instance-name>| because it
is too short (such a match would need at least two words), and "the fox"
cannot match |<s-adjective> <s-nounphrase>| because it does not contain any
words which are in some contexts adjectives.

@ It will be evident that Inform doesn't use parser-generators such as |yacc|,
|bison| or |antlr|. One reason is that they need the grammar to be fixed and
known at (the compiler's) compile time. Then, too, folk wisdom has it that
|yacc| parsers are typically half as fast as a shrewdly hand-coded equivalent.[1]
In any case the elegant theory of LALR parsing, though ideal for token-based
programming languages, does not specify natural language well.[2]

[1] The |gcc| C compiler abandoned the use of |bison| for exactly this reason.

[2] Which is perhaps ironic, considering that the relevant computer science
was strongly influenced by generative linguistics.
