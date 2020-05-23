What This Module Does.

An overview of the inflections module's role and abilities.

@h Prerequisites.
The inflections module is a part of the Inform compiler toolset. It is
presented as a literate program or "web". Before diving in:
(a) It helps to have some experience of reading webs: see //inweb// for more.
(b) The module is written in C, in fact ANSI C99, but this is disguised by the
fact that it uses some extension syntaxes provided by the //inweb// literate
programming tool, making it a dialect of C called InC. See //inweb// for
full details, but essentially: it's C without predeclarations or header files,
and where functions have names like |Tags::add_by_name| rather than |add_by_name|.
(c) This module uses other modules drawn from the //compiler//, and also
uses a module of utility functions called //foundation//.
For more, see //foundation: A Brief Guide to Foundation//.

@h Inflections.
Inflections are modifications of words -- usually word endings or beginnings --
for different circumstances. English is often called an uninflected language,
but this is an exaggeration. For example, we spell the word "tree" as
"trees" when we refer to more than one of them. Inform sometimes needs
to take text in one form and change it to another -- for example, to turn
a singular noun into a plural one -- and ordinary Preform parsing isn't good
enough to express this.

Inform uses a data structure called a "trie" as an efficient way to match
prefix and/or suffix patterns in words, and then to modify them.

Tries are provided as basic data structures by //foundation: Tries and Avinues//,
and the code for initialising them from Preform grammar is provided by
//words: Preform Utilities//.

@ Though tries are, as just mentioned, created from Preform grammar, they're
parsed quite differently. The rules are as follows:

(a) A nonterminal in trie grammar can either be a list of other tries, or it
can be a list of inflection rules. Mixtures of the two are not allowed. For
example <singular-noun-to-its-indefinite-article> is a list of other tries,
while <en-trie-indef-a> contains actual rules.

(b) In a list of tries, each production consists only of a single nonterminal
identifying the trie to make use of. One exception: writing |...| before the
trie's name makes it work on the end of a word instead of the beginning.
Inform attempts to find a match using each trie in turn, until a match is
found. For example:
= (text as Preform)
	<fiddle-with-words> ::=
		<fiddle-with-exceptions> |
		... <fiddle-with-irregular-endings> |
		... <fiddle-with-regular-endings>
=
means try <fiddle-with-exceptions> first (on the whole word), then
<fiddle-with-irregular-endings> (on the tail), and finally <fiddle-with-regular-endings>
(also on the tail).

(c) In a list of inflection rules, each production consists of two words. The
first word is what to match; the second gives instructions on what to turn
it into. An asterisk is used to mean "any string of 0 or more letters";
a digit in the replacement text means "truncate by this many letters and
add...". (As a special case, the replacement text "0" means: make no
change.) Some examples:
= (text as Preform)
	<pluralise> ::=
		lead lead |
		codex codices |
		*mouse 5mice
=
This would pluralise "lead" as "lead", "codex" as "codices", "mouse" as "mice",
and "fieldmouse" as "fieldmice".

Designing a trie is not quite as easy as it looks. It looks as if this is a
sequence of tests to perform in succession, but it's better to think of the
rules all being performed at once. In general, if you need one inflection
rule to take precedence over another, put it in an earlier trie, rather than
putting it earlier in the same trie.

For the implementation of these rules, see //Tries and Inflections//.

@ Once we have that general inflection machinery, most of what we need to
do becomes a simple matter of writing wrapper functions for tries.

(*) //ArticleInflection::preface_by_article// handles the variation of articles:
for example, mutating "a" to "an" when it comes before "orange", thus making
"an orange" rather than "a orange".

(*) //Grading::make_comparative// turns "tall" into "taller".

(*) //Grading::make_superlative// turns "tall" into "tallest".

(*) //Grading::make_quiddity// turns "tall" into "tallness".

(*) //PastParticiples::pasturise_wording// turns "looking away" to "looked away".

(*) //Pluralisation::make// produces a series of allowable plurals for a
word, using a combination of a trie to handle regular pluralisation (for
English, we use Conway's algorithm) and a dictionary of user-supplied
exceptions. 

@ Tries are highly language specific and should not be translated as such:
instead, an appropriate version needs to be written for every language.
The tries for English are in //English Inflections//.

Except at the very top level, translators are free to created new tries
and name them as they please. For example, the Spanish implementation of
= (text as InC)
	<singular-noun-to-its-indefinite-article>
=
may look entirely unlike its English version, but at the top level it still
has to have that name.

Lower-level tries used in the implementation should have names beginning
with a language code: hence the names "en-" used in //English Inflections//.
