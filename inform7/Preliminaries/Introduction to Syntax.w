P/syn: Introduction to Syntax.

This is the introduction to the stand-alone document of the English
syntax of Inform.

@h Preface.
"From an engineering perspective, language is kind of a disaster" (Arika
Okrent). Welcome to the scene of a disaster.

The syntax of a language is the collection of rules for how complicated
structures -- sentences, for example -- are built up from simpler ones. These
rules can work in many different ways: they may require us to use punctuation,
word ordering, word modification, or verbal formulae to hold a sentence
together. Every natural language has its own distinctive syntax.

Syntax is not a precise term, even in computing. English sentences really
can't be formed properly without some idea of what the words mean, and
different linguists put the boundary of syntax and semantics in different
places. For Inform purposes, we will use "syntax" to mean the rules of
natural language enforced by its lexical rules (spaces, punctuation, quotation
marks and so on) together with its Preform grammar.

Preform is the name given to both a notation for syntax, and a subsystem of
Inform which parses text against definitions written in that notation.
The purpose of Preform, introduced in early 2011, is to separate
the compiler as far as possible from the definition of the natural language
it reads. Eventually, we would like Inform to read all major European
languages on an equal basis, though this is a very ambitious goal.

@ If you're reading this as part of the {\it English Syntax of Inform}
document, you might like to know how the document is made. Inform is a
"web" according to the "literate programming" doctrine of Donald Knuth:
in fact, at about 160,000 lines of code, it's one of the largest webs ever
written. A literate program is written in a narrative style, laying out
code in as legible a style as possible, and with sketch-proofs and
explanations to justify the choices made, or simply to give the reader
some idea of what is going on.

To use a literate program, you need two preprocessors -- a "weaver" and a
"tangler". The weaver makes a typeset document intended only for human
eyes: an ebook, in effect. If you're reading this as a PDF document, you're
looking at the output from Inform's weaver. The tangler, on the other hand,
makes a traditional computer program which can be fed into a compiler and
eventually run, but which is an illegible mess to the human eye. In Inform's
case, the weaver and tangler are actually both the same program (called
|inweb|), which weaves to \TeX\ and tangles to ANSI C.

Literate programs are subdivided into paragraphs. Knuth, who called these
"sections", traditionally wrote them as $\S 1$, $\S 2$, ..., and so on; up
to $\S 1380$ for \TeX\ and $\S 1215$ for Metafont. That was already quite hard
to navigate, and Inform has about 7000 paragraphs, so I have used a more
hierarchical system. The notation "6/vp.$\S$14" means paragraph 14 in the
section "Verb Phrases" of Chapter 6; it's a sort of postcode to a single
piece of code in the program. The current paragraph belongs to a special
chapter identified as P for "preliminaries", which contains material like
the preliminary pages of a book.

@ The business of weaving and tangling is relevant because of the way the
Preform notations are written. Individual pieces of the syntax are scattered
all over the vast Inform web, in order to keep them close to the code which
uses them. However:

(a) The weaver has a mode in which it weaves together only the paragraphs
which define or talk about Preform grammar, skipping the rest of the program
entirely. This is how the {\it English Syntax of Inform} document is made.

(b) The tangler also treats the Preform definitions in a special way. It
extracts them into a standalone file called |English.preform|, a built-in
resource which Inform; alter this file, and you alter Inform's syntax, though
there are better ways.

Thus, for example, the familiar Inform wording "in the presence of" doesn't
occur anywhere in the Inform compiler; it's part of a Preform definition which
is read in by the compiler. When Inform is reading French, it will use a
different Preform definition ("dans la pr\'esence de", say).

@ Because of all this, the {\it English Syntax of Inform} document is not
somebody's approximate sketch of what Inform is supposed to do. It's the
actual code Inform executes, current to the build code and date on the cover.

That makes it fairly precise, though it's not always laid out in the order you
might choose if you were (say) sitting down to write a BNF definition of the
Inform language. It also comes out as quite a long description. Inform uses
more than 500 Preform nonterminals, which seems an awful lot. Jeff Lee's
elegant Yacc grammar for ANSI C (1985) needed only about 60; C, of course,
is a famously small language, and actual compilers of it generally use a
more extensive grammar -- |gcc| 3.3 used 159 nonterminals, back in the days
when |gcc| still used Yacc instead of a hand-coded parser -- but still: this
makes Inform look maybe twice the size of a typical programming language.

I think that's misleading, though:

(a) Firstly, Inform generally uses different wording for different meanings,
rather than using the same punctuation syntax over and over but with
complicated semantic rules for what it does. (Consider brackets in C++.)
This means syntax is more expressive.

(b) Secondly, real compilers always contain semi-secret syntaxes of one kind
or another -- additional data types for oddball processors, keywords giving
optimisation hints, debugging features, and so on -- which always make what a
compiler actually parses more extensive than the theoretical definition of the
language it compiles. Inform is no exception. For example, it contains several
syntaxes undocumented in the public manual and provided only for the
bootstrapping process which the Standard Rules goes through; these are not for
public use and may change without notice.

(c) Inform uses Preform not only to parse correct syntax, but also to
take a guess at what incorrect syntax was aiming to do, in order to help it
to produce better problem messages. Once again, that means that there is
Preform syntax which isn't part of the public language definition.

(d) Preform notation provides a convenient way to name some of the standard
constructions made by the Standard Rules; this, again, isn't part of the
syntax definition of Inform -- it's a convenience helping the compiler
to implement its semantics.

(e) Preform notation encourages many small definitions rather than a few
large ones.

@ Preform looks like BNF (Backus-Naur form), which has been the traditional
notation for syntax in computer science since 1960. It's actually a very
simple form of BNF, lacking extensions for optional or repeated elements.
BNF is where the jargon words "nonterminal" and "production" come from.

Our language is composed of "nonterminals", each of which is either
"internal" or defined with a list of "productions". A nonterminal is used
to parse a given excerpt of text to see if it matches some pattern, and
well-chosen nonterminals will correspond to traditional linguistic ideas --
<accusative-pronoun> or <s-noun-phrase>, for example. An "internal"
nonterminal tests for a match using a routine hardwired into the compiler,
which means no user of Inform can easily alter it.

For example, here is an imaginary example: a nonterminal with two productions,
which can match text such as "4th runner" or "runner no 17". The |::=|
symbol can be read as "is defined by", and the vertical stroke means "or".
Each of the two productions sits on a single line, though that's good style,
rather than being compulsory.

= (not code)
	<competitor> ::=
		<ordinal-number> runner |
		runner no <cardinal-number>

@ When Inform successfully matches some text against a production, it usually
means that one or more nonterminals have made matches as part of this effort.
For example, a match against "4th runner" means <ordinal-number> has
matched against "4th". Inform usually needs to know the "results" of
each such intermediate match. Results are numbered along the production,
counting upwards from 1. Here's a more interesting example:

	|runner from <town> numbered <cardinal-number>|

This has two results, numbered 1 and 2. Suppose we are translating this into
French, and French word ordering means that these need to occur back to front.
(It doesn't, but just suppose.) If we write

	|coureur no <cardinal-number> de <town>|

This won't work, because Inform will think the town should be result 1 and
the number result 2. So to do this we need a new syntax:

	|coureur no <cardinal-number>?2 de <town>?1|

The |?| suffix followed by a number declares the result number explicitly.
So the original production could equivalently have been written

	|runner from <town>?1 numbered <cardinal-number>?2|

If one of the nonterminals is numbered, then they all must be.

@ Translators giving equivalent definitions for languages other than English
need to match the order of the productions exactly. If the English looks
like so:

= (not code)
	language English

	<competitor> ::=
		<ordinal-number> runner from <origin> |
		runner no <cardinal-number>

@ Then the French will look like so:

= (not code)
	language French

	<competitor> ::=
		<ordinal-number> coureur de <origin> |
		coureur avec numero <cardinal-number>

@ This is sometimes problematic: maybe the productions need to be given in a
different order to parse properly, or maybe two different versions need to be
given. To get around this, a translator can optionally begin a production
with a match number in the form |/a/| to |/z/|. For example, a translator
might supply three French productions to match the two English ones:

	|/a/ <ordinal-number> coureur de la <origin>|
	|/a/ <ordinal-number> coureur du <origin>|
	|/b/ coureur no <cardinal-number>|

If any of the productions are numbered, they all should be. In the English
originals, numbering is always in standard alphabet order; in the Preform
grammar document extracted from the Inform source code, italicised letters
are printed next to each production for convenience.

When 26 productions isn't enough, use |/aa/| to |/zz/|. English never uses more
than 52 productions in any nonterminal, so we never need more than that.

@ It looks as if each production is made up either of nonterminals or fixed
words, but in fact there are other possibilities too.

(a) We can save typing and also speed up the parsing by using a forward
slash |/| to give alternative single fixed words. Thus |wheel/spoke/pedal|
is a single token matching any one of these three words. |/| can only be
used with fixed-word tokens.

Next, there are three wildcards:

(b) The token |###| matches any single word.

(c) The token |***| matches any stretch of one or more words.

(d) The token |...| matches any stretch of one or more words. If it is written
with six dots instead of three, |......|, brackets (round or brace) inside the
word range are required to pair correctly, or there's no match.

There are also three modifiers, which affect how Inform reads the immediately
following token:

(e) An underscore |_| coming before a fixed-word token means informally that
a match has to be made in lower case; more precisely, the word cannot
unexpectedly be in upper case. Thus |_in| matches in the sentences
"A ball is in the bag." and "In the bag is a ball.", but not "On the
shelf is In The Budding Grove." |_in/on| matches either "in" or "on",
but in both cases they would have to be in lower case.

(f) A caret |^| coming before a nonterminal or a fixed-word token negates its
meaning. For instance, |^<competitor>| matches any text which <competitor>
doesn't match; there are no meaningful results from this. |^blancmange|
matches any {\it single} word which is not "blancmange", so it matches
"jelly", but not "confectioner's custard". |^fish/fowl| matches any
single word which is neither "fish" nor "fowl".

(g) A backslash tells Inform to read the next word as its literal textual
contents, regardless of the above rules. So |\***| means the word consisting
of three asterisks, and |\<competitor>| means the word consisting of open
angle, c, o, m, ..., r, close angle. |\ac/dc| means the literal text "ac/dc",
and isn't a choice of two. And, of course, |\\| means an actual backslash.

Material in square brackets, [like this], is comment and is ignored.

@ There is one more syntax, but it takes some explaining. When wildcards
match, Inform can access the words they represent. For instance,

	|man with ... on his shirt|

would match "man with Race Organiser on his shirt" and generate the word
range "Race Organiser" in the process. Wildcards are numbered from 1 in order
of their generation. But braces can be used to affect this, and in effect
to spread or consolidate word ranges. Thus:

	|man with {... sash} on his shirt|

would match "man with marshall's sash on his shirt" while making the word
range "marshall's sash" instead of just "marshall's". This notation is
especially helpful when we need both to check that something matches, and
also record its wording for later:

	|man with {<messy-set-of-official-logos>} on his shirt|

Braces can't be nested; an inner pair of braces would in any case have no
effect, because the outer pair would wipe them out.

@ Ranges raise the same what-if-we-want-them-back-to-front issue as results
do, and we solve the problem the same way. The ranges in:

	|man with ... on his ...|

are numbered 1 and 2 respectively; and the following:

	|homme dont {...}?2 est {...}?1|

tells Preform that when this text is matched, the word ranges are the other
way round compared with the English version.

@ Other punctuation characters have no special meaning -- dashes, round brackets,
full stops, commas, semicolons, colons, asterisks, question marks and so on
are just characters like any other in Preform. So

	|making ( . ) !|

is just a sequence of five fixed-word tokens, and is read in the same literal
way as:

	|making the best of it|

Round brackets do not automatically break words in Preform, so |(c)| is not
the same as |( c )|, even though it would be in Inform.

@ In fact, though, Preform does know that there is something special about
round brackets |(| and |)|. If a production contains a pair of these, and the
position of the |(| is uncertain, then Preform will only match them if they are
correctly paired in the source text being looked at. Thus,

	|friday ... ( ... )|

would match "Friday afternoon (but not Tuesday)", generating word ranges
"afternoon" and "but not Tuesday"; applied to "Friday afternoon (not
(Saturday)" it would generate "afternoon ( not" and "Saturday". This
saves a great deal of time chasing useless possible matches.

@ There are a number of restrictions on what can be written in productions.
We've decided to live with this, since Preform is hardly intended for
general-purpose programming. Among the things which can't be done:

(a) There's no way to make a literal vertical stroke, arrow |==>|, or
open or close squares |[| or |]|; though we can make literal braces
using |\{| and |\}|.

(b) There's no way to make a literal double-quoted piece of text |"thus"|.
This actually causes us a small amount of nuisance and is the reason there's
an internal nonterminal <empty-text> rather than simply writing |""|.

(c) There's no way to make a literal word which contains one of the
characters |_|, |^|, |{|, |}|, |\| but is longer than just that one
character. For instance, you can't make |3^6| or |bat_man|, and |\{robin}|
doesn't work.

The nuisance is worth it to enable us to use Inform's regular lexer to read
Preform text.

@ This seems a good point to go into the names of nonterminals. Each name
must be a single word in angle brackets, and can only include lower case
letters "a" to "z", the digits 0 to 9, and hyphens; it must be at least
three characters long, not counting the brackets; the first of those characters
must be a lower-case letter, and the last must not be a hyphen. In other words,
it must match the regular expression

	|\<[a-z][a-z0-9-]+[a-z0-9]\>|

But those are only the rules; they wouldn't stop us naming the nonterminal for
a description <julie-75>, say. In an attempt to bring order to what
could easily be a confusion of names, the Inform source text follows these
conventions:

(a) There are three subsets of the grammar which handle complicated tasks
mostly isolated from the rest:

(-i) The K-grammar parses kind names, such as "list of relations of numbers".
All nonterminals in the K-grammar begin with <k-...>.

(-ii) The NP-grammar parses noun phrases in assertion sentences, such as
"a container on the table" as it occurs in the sentence "The tupperware
box is a container on the table". All nonterminals in the NP-grammar begin
with <np-...>.

(-iii) The S-grammar parses sentences as they occur in conditions, such as
"an animal has been in the cage" as if occurs in the phrase "if an animal
has been in the cage, ...". All nonterminals in the NP-grammar begin
with <s-...>.

(b) Nonterminals used only to choose which problem message to issue -- used,
that is, to parse text which is already known to be wrong -- have names
ending <...-diagnosis>.

(c) Nonterminals which define names of constructions Inform needs to recognise
in the Standard Rules have named which begin <notable-...>. For example,
Inform needs to recognise the property "description" when it's defined,
because the compiler needs to give this property special handling. Because
the property is only ever created once, and only in English (since the Standard
Rules are in English), nonterminals of the <notable-...> set never need
to be translated into other languages.

(d) Similarly for nonterminals ending in <...-names>, which give
names to (for instance) the built-in relations -- those not defined in the
Standard Rules.

(e) As we shall see, there are about 20 sentence forms which have a special
grammar to them: for example, "Understand ... as ..." sentences. The subject
and object noun phrases for these sentences are parsed with nonterminals
whose names end in <...-sentence-subject> and
<...-sentence-object> respectively; for example,
<understand-sentence-subject>.

(f) A nonterminal ending in <...-construction> is used not to
parse text but to create it; these will be explained as they come up.

(g) A few nonterminals beginning <if-...> exist to test the
current situation; they match if what they're testing is currently true,
and fail otherwise, but they never match any words of the source text.

@ Finally, some notes on how Preform grammar is typeset in the PDF form of
this source code:

(a) For visual clarity, nonterminal names such as |<ordinal-number>| are
typeset as <ordinal-number>, as you've probably guessed.

(b) Italic letters {\it a}, {\it b}, {\it c}, ..., down the columns of
productions are a form of line-numbering. They are provided for the benefit
of anybody needing to refer to the productions individually (see above);
non-translators can ignore them.

(c) Preform is a little more powerful than the description of it given
above. For each production, it also has instructions on what to do if a
successful match is made. These instructions usually just do something
constructive with whatever information was found, but they can be more
flexible. Those instructions are invisible in the {\it English
Syntax of Inform} document, since they concern semantics rather than
syntax, but in some cases there's some explanatory commentary in the
right-hand margin:

(-c1) If a successful match to a production results in a Problem message
being issued, then an arrow and the sigil for the Problem is given in
the right margin. Inform has over 750 problems, each of which is identified
with a unique sigil; for example, |PM_NoSuchPublicRelease|. (You can see
these sigils in the debugging log if you cause a problem.)

(-c2) In a few cases -- mainly when parsing lists, where the computational
complexity of the parser could make longer lists unacceptable slow -- there
are bogus productions which appear to match any text at all. In the margin
next to these is the text {\it match only when looking ahead}. This is a
technicality to do with how the Preform parser works; productions like this
can simply be ignored as far as syntax is concerned.

(-c3) A few productions are marked with a mysterious note such as
{\it actions_plugin}. This means they are to be used only when that part
of the Inform language definition is enabled; see "Plugins" for details.

(-c4) Some productions, when matched, do the reverse of what might be
expected: instead of passing their nonterminal immediately, they fail it
immediately. This is a convenient device to allow certain pieces of text
to be parsed twice -- once to make sure it has a given form (failing the
nonterminal if it doesn't), once to extract information from it.
Productions like this are marked "fail" in the righthand margin.

(-c5) Moreover, some are marked "fail and skip". These are used when
scanning text for certain configurations of words. If there's a match,
not only does the current nonterminal fail, but Preform knows not to
try again from the very next word: instead it advances to the wildcard
text at the end of the production. (This is easier to follow in practical
cases than in general explanations.)
