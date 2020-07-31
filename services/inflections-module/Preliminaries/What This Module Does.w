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

@ Though tries are, as just mentioned, created from Preform grammar, they are
parsed quite differently.

In trie grammar, a NT must be either a list of other tries, which are tested
in sequence until one matches, or must be a list of inflection rules. These
cannot be mixed within the same NT.

@ In a list of tries, each production consists only of a single nonterminal
identifying the trie to make use of. One exception: the token |...| before the
trie's name makes it work on the end of a word instead of the beginning.
For example:
= (text as Preform)
	<fiddle-with-words> ::=
		<fiddle-with-exceptions> |
		... <fiddle-with-irregular-endings> |
		... <fiddle-with-regular-endings>
=
means try <fiddle-with-exceptions> first (on the whole text), then
<fiddle-with-irregular-endings> (on the tail), and finally <fiddle-with-regular-endings>
(also on the tail).

@ In a list of inflection rules, each production consists of two tokens. The
first token is what to match; the second gives instructions on what to turn
it into. An asterisk is used to mean "any string of 0 or more letters";
a digit at the start of the replacement text means "truncate by this many
letters and add...". The simplest possible instruction is |0| alone, which
means "truncate 0 letters and add nothing", and therefore leaves the text
unchanged.

Some examples:
= (text as Preform)
	<pluralise> ::=
		lead 0 |
		codex codices |
		*mouse 5mice
=
This would pluralise "lead" as "lead", "codex" as "codices", "mouse" as "mice",
and "fieldmouse" as "fieldmice".

The special character |+| after a digit means "double the last letter", so
that, for example, |0+er| turns "big" to "bigger". In other positions, |+|
means "add another word", so for example |0+er+still| turns "big" to "bigger
still".

Designing a list of inflection rules is not quite as easy as it looks, because
these rules are not applied in succession: it's better to think of the rules
as all being performed at once. In general, if you need one inflection
rule to take precedence over another, put it in an earlier trie (in the list
of tries which includes this one), rather than putting it earlier in the same trie.

For the implementation of these rules, see //Tries and Inflections//.

@ Once we have that general inflection machinery, most of what we need to
do becomes a simple matter of writing wrapper functions for tries, and these
occupy the rest of //Chapter 2//.

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

@h Declensions.
//Declensions// are sets of inflected forms of a noun or adjective according
to their grammatical case. A language should list its cases in a special
nonterminal called <grammatical-case-names>, in which "nominative" or its
equivalent should always come first. For example:

= (text as Preform)
<grammatical-case-names> ::=
	nominative | vocative | accusative | dative | genetive | ablative
=
The function //Declensions::no_cases// returns a count of these for a given
natural language. The actual names of cases are only needed by the function
//Declensions::writer//, which prints out tables of declensions for debugging
purposes.

@ //Declensions::of_noun// and //Declensions::of_article// are functions to
generate declensions, with one form for each case, from a given stem word.
These are done with Preform NTs called <noun-declension> and <article-declension>
respectively; these are currently the only two "declension NTs".

The rule for a "declension NT" is that it must provide a list of possibilities
in the form either |gender table| or |gender grouper table|, where |gender| is:

(*) the letter |m| for masculine,
(*) the letter |f| for feminine,
(*) the letter |n| for neuter/common,
(*) the asterisk |*| for "any gender".

In the two-token form |gender table|, the |table| is a nonterminal for
irregular forms; if the three-token form |gender grouper table|, the |grouper|
is a nonterminal which works out which "group" the word falls into -- groups
are numbered, so perhaps, e.g., the word "device" falls into group 1 -- and
then the |table| provides declensions for the different groups needed.

@ A simple example of using the irregular forms table is provided by the
English language definition of <article-declension>:

= (text as Preform)
<article-declension> ::=
	*    <en-article-declension>

<en-article-declension> ::=
	a    a    a
	     some some |
	the  the  the
	     the  the
=
Here the declension NT is <article-declension> and contains only one possibility,
applying to all genders (hence the |*|). The |table| of irregular forms is then
<en-article-declension>. Each production begins with the possibility against
which the stem is matched -- here, it's going to have to be "a" or "the". There
are then one possibility for each case (nominative and accusative) in each of
the two numbers (singular and plural), making four forms in all. English, of
course, is not very inflected: this would be more interesting for French:
= (text as Preform)
<article-declension> ::=
	m  <fr-masculine-article-declension> |
	f  <fr-feminine-article-declension>

<fr-masculine-article-declension> ::=
	un   un    un
	     des   des |
	le   le    le
	     les   les

<fr-feminine-article-declension> ::=
	un   une   une
	     des   des |
	le   la    la
	     les   les
=

@ So much for irregular forms. Grouped forms are useful for languages like
German, which has about 12 groups of nouns, each with its own way of declining.
For example, there's one group which goes something like:
= (text as Preform)
	Kraft	Kraft	Kraft	Kraft
	Kräfte	Kräfte	Kräften	Kräfte
=
and another which goes like:
= (text as Preform)
	Kamera	Kamera	Kamera	Kamera
	Kameras	Kameras	Kameras	Kameras
=
For German, we might then have
= (text as Preform)
<noun-declension> ::=
	*  <de-noun-grouper> <de-noun-tables>

<de-noun-grouper> ::=
	kraft   1 |
	kamera  2

<de-noun-tables> ::=
	<de-noun-group1-table> |
	<de-noun-group2-table>
=
where for example:
= (text as Preform)
<de-noun-group1-table> ::=
	0 | 0 | 0 | 0 |
	3äfte | 3äfte | 3äften | 3äfte
=
giving inflection rules for the four cases of German in singular and then
in plural. In practice, of course, <de-noun-grouper> will need to sort out
nouns rather better than this, and there are about 12 groups. Groups are
numbered upwards from 1 to, in principle, 99. See //Declensions::decline_from_groups//.

@h Verb conjugations.
This module supplies an extensive system for conjugating verbs. A full set
of inflected forms for a verb, in all its tenses, voices and so on, is stored
in a //verb_conjugation// object. Making these objects is a nontrivial task:
see the function //Conjugation::conjugate//.

Like declensions, verb conjugations rely on a set of tables in special formats,
but which are stored in nonterminals of Preform grammar. There is a full
description of the syntax used in these tables in the section //English Inflections//,
which demonstrates a complete conjugation of English verbs.

@h Naming conventions.
Tries are highly language specific, and would need rewriting for every language.
The tries for English are supplied in //English Inflections//, but that's just
for convenience; other languages should supply them in the Inform source text of
the relevant language extension, or in |Syntax.preform| files.

Except at the very top level, translators are free to created new tries
and name them as they please, but the top-level tries must have the same
names that they have here. For example, the Spanish implementation of
= (text as Preform)
	<singular-noun-to-its-indefinite-article>
=
may look entirely unlike its English version, but at the top level it still
has to have that name.

All lower-level tries used in the implementation should have names beginning
with a language code: hence the names "en-" used in //English Inflections//.
There doesn't need to be any direct Spanish equivalent to
<en-trie-plural-assimilated-classical-inflections>, for example.
