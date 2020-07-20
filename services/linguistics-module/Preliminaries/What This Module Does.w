What This Module Does.

An overview of the linguistics module's role and abilities.

@h Prerequisites.
The linguistics module is a part of the Inform compiler toolset. It is
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

@h Goals and non-goals.
The linguistics module aims to provide Preform grammar capable to taking a
verb phrase of natural language and parsing it into a "diagram" somewhat like
the ones students draw in school grammar classes. For example,

>> most of the heavy bricks have been on top of the wall

becomes a "diagram" -- a fragment of the tree provided by the //syntax//
module -- showing the linguistic structure of the sentence.

This work is done by the nonterminal <sentence> -- see //Verb Phrases//.
Many examples of sentence diagrams can be seen in //About Sentence Diagrams//;
read that first.

To be in a position to parse like this, the module needs a way to accumulate
knowledge about the possible nouns, verbs, adjectives, prepositions and so on
which might appear in such sentences. Where sensible, a design goal here is
for each of these grammatical categories to correspond closely to an object
class of the same name -- that is, //noun//, //verb//, //adjective// and so on.
For example, "brick" and "wall" correspond to two different instances of //noun//,
and "to be" to //verb//. The instances of these grammatical classes, taken
together, form what is called the "stock".

@ To be clear, though:
(a) The stock is a range of possibilities and not a tally of what actually
appears in any given source text being looked at. When Inform compiles a
source text, it may perhaps mention "brick" many times, but the stock would
still just contain one //noun// object for "brick"; equally, the text being
compiled might not contain the verb "to provide", even though the stock has it.
(b) For the most part, it is for the user of this module to create an
appropriate stock. This will never be so large as to meaningfully define the
entire English (or any other) language; it's likely to focus on some narrow
subject area. The stock does not have to be created all at once: it can fill
out over time.[1]
(c) For the most part, it is up to the user to give meanings to terms in the
stock, and the linguistics module tries to impose as few constraints as possible
about those meanings.[2]
(d) Only "for the most part", because certain "fixed" grammatical categories
are an exception -- for example, articles, or cardinal and ordinal
numbers, or determiners. In these categories, the linguistics module provides
the stock and the user cannot change or add to it; and the linguistics
module provides the meanings, too, which the user can read but cannot change.[3]

[1] When Inform reads "A brick is a kind of thing. Two bricks are here.",
for example, the first sentence causes it to create the //noun// for brick,
so that the second sentence is read with a stock which is one term larger.

[2] Verbs are a partial exception in that we need to make some minimal
assumptions about how verb meanings will work -- this is abstracted out in
the section //Verb Meanings//. Even there, though, the user will have to find
her own way to define what verbs actually mean.

[3] For example, the determiner "all of" has a fixed meaning defined here
as the //quantifier// object |for_all_quantifier|; and the cardinal "six"
always means 6.

@ This module is designed to work closely with the //inflections// module,
and the demarcation line between the two is that //inflections// knows nothing
about the meaning or usage of words, while //linguistics// is largely free
to ignore the complications brought in by inflected forms of words.

For example, a single //verb// object represents "to carry", even though it
has many different expressions in words -- "has not carried", "will carry",
and so on. A single //noun// representing "brick" would include its plural
"bricks" and indeed its declension into other cases, in a language which has
noun cases. Our goal here is that the stock should never contain two different
instances which merely represent inflected forms of the same thing.

@h Lcons.
An "lcon" is a reference to something in the linguistic stock, together with
annotations for the grammatical form used on a particular occasion. For
example, an lcon can mean "the indefinite article, in the third person
plural feminine form", where the stock item is just the indefinite article.
Lcons are packed into single integers for efficiency: no memory needs to be
allocated to create lcons, and they copy with value semantics.

Thus the stock is not just a figure of speech, it's actually a data structure:
see //Stock Control//.

@h Cardinals and ordinals.
This module does not aspire to parse the full range of literals understood
by, for example, Inform. But it does provide <cardinal-number> and
<ordinal-number> nonterminals, which can recognise low numbers in words
or arbitrary numbers in digits. See //Cardinals and Ordinals//.

Note that these are not part of the stock. It wouldn't really make sense
for them to be so: we would need a potentially infinite number of them to
accommodate the possible range of integers which appear.

@h Stock for noun phrases.
For convenience we will run through the stock in two sets: those grammatical
categories used in noun phrases, and provided by //Chapter 2//; and those
used in verb phrases, //Chapter 3//. In alphabetical order:

@ Each adjective in the stock is an instance of //adjective//. All senses of
the same adjectival word -- "empty", say -- are represented by the same
//adjective//: it's for the user to manage multiple meanings, and to deduce
which one applies from the context.[1]

The user creates the stock of adjectives by calling //Adjectives::declare//.

[1] In Inform, for example, empty means something different for rulebooks
than for containers. An adjective is a unary predicate applying to something,
and the kind of that thing can be used to decide which meaning applies. See
//core: Adjective Meanings// for how Inform does this.

@ Each article in the stock is an instance of //adjective//. The stock is fixed
at two, both automatically created: the definite and the indefinite article.
See //Articles//.

@ The determiners are a fixed stock of roughly 20, each being an instance of
the class //determiner//. Properly speaking some are families of determiners --
"all but three" and "all but six" are the same //determiner// but with a
different numerical parameter. But others, like "most of", have fixed wording.
The meaning of each determiner is a logical //quantifier//.[1]
See //Determiners and Quantifiers//.

[1] Inform makes heavy use of these quantifiers when representing the meaning
of sentences in predicate calculus, but that's beyond the scope of this module.

@ Each noun in the stock is an instance of //noun//. Unlike with //adjective//,
when the same noun word has multiple meanings, it gets multiple //noun// objects,
one for each meaning.[1] Nouns divide into two subclasses: common nouns, such
as "monument", and proper nouns, such as "Statue of Liberty".[2]

The user creates the stock of adjectives by calling //Nouns::new_proper_noun//
or //Nouns::new_common_noun//.

[1] Because nouns unlike adjectives are not predicates, and therefore are not
always dependent on some other word which will establish which meaning is
intended. Our best option is instead to parse in some context-sensitive way.

[2] Inform source text contains more proper nouns than a grammarian would guess.
The sentence "Mary is carrying a kite" will result in two proper nouns being
added to the stock, "Mary" and "kite", unless "kite" is already known as a
common noun. This is because "the kite", from then on, will be understood
as referring to this one specific object, just as "Mary" will.

@ Each pronoun in the stock is an instance of //pronoun//. The stock is fixed
at three, all automatically created: the subject (he, she), object (him, her)
and possessive (his, her) pronouns. See //Pronouns//.

@h Stock for verb phrases.

Adverb phrases of occurrence refers to wording such as "for the sixth time".
The stock of these is fixed, though as with determiners, each is really a
parametrised family: the two adverb phrases here are the one measuring "times",
that is, repetitions, and the one measuring "turns", a purely
interactive-fictional construction useful to Inform. See //Adverb Phrases of Occurrence//.

@ Adverbs of certainty are words like "usually" or "always". There is a fixed
stock of these, at five certainty levels. See //Adverbs of Certainty//.

@ Prepositions are phrases like "over" or "on top of". Each is an instance of
the //preposition// class. See //Prepositions//.

The user creates the stock of prepositions by calling //Prepositions::make//,
but note that this function is also called when verbs are created, in order
to implement participles like "carrying" as prepositions -- which is not
linguistically ideal, but makes it possible to parse auxiliary uses of 
"to be" efficiently, as in "X is carried by Y".

@ Each verb in the stock is an instance of //verb//. For example, "to carry"
or "to be" might be verbs. One verb in the stock is special and is the
copular verb -- in English, that's "to be". A copular verb is one which has two
interacting subject phrases rather than a subject and an object.[1]

The user creates the stock of adjectives by calling //Verbs::new_verb// or
//Verbs::new_operator_verb//. (Operator verbs are mathematical operators
such as |<=|, which can be added to the stock as if they were regular verbs,
but which do not conjugate or have tenses.)

Each verb has a list of //verb_form// objects, one for each "form" it takes.
A form in this sense is a combination of a verb with prepositions; meanings
correspond to verb forms, not verbs alone. For example, the verb in the
sentences "Peter is hungry" and "Jane will be in the Dining Room" is in
each case "to be", but the forms are different: one is "to be" alone, the
other "to be" plus the preposition "in", which changes the meaning.

The user, then, creates //verb// objects and gives them //verb_form//s,
attaching meanings to each form via the mechanisms in //Verb Meanings//
(which wrap those meanings in //verb_meaning// objects). The linguistics
module then has to provide an efficient way to parse text to find uses
of these verbs, and it does so by constructing intermediate objects.
See //Verb Usages//.

[1] Compare "Peter carries a ball", where Peter and the ball have very
asymmetric roles because the action is done by Peter but to the ball, and
"Peter is the mayor", where two nouns are equated in a symmetrical sort of way.

@h Performance in practice.
The following tabulates the linguistic stock accumulated by a typical Inform 7
compilation (the same one used to generate the data in //inform7: Performance Metrics//).
Within each categpry, items are listed in order of creation.

= (hyperlinked undisplayed text from Figures/stock-diagnostics.txt)
