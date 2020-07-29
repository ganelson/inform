[Semantics::] Introduction to Semantics.

A general introduction to the S-parser and the data structures
it makes use of.

@ At this point, the text read in by Inform is now a stream of words, each of
which is identified by a pointer to a |vocabulary_entry| structure in its
dictionary. The words are numbered upwards from 0, and we refer to any
contiguous run of words as an "excerpt", often writing |(w1, w2)| to mean
the text starting with word |w1| and continuing to word |w2|. The stream
of words has been divided further into sentences.

Inform has two mechanisms for making sense of this text, the A-parser and
the S-parser.

(A) A stands for "assertion". For instance, "Two men are in Verona." is
an assertion, telling Inform that at the start of play there are to be two
previously unknown men and that they begin in the room called Verona. The
A-parser handles entire sentences.

(S) S stands for "semantics", the study of how already-understood
meanings correspond to excerpts of text within a sentence. The S-parser
handles anything from tiny excerpts like "6" through noun phrases such as
"Verona" to complicated expressions like "the number of men in Verona".

There are many similarities between the A-parser and the S-parser, partly
because A makes use of S, but also because they contain parallel mechanisms
which handle verbs and prepositions similarly. But there are also many
differences. The A-parser will accept "On the dressing table is an amber
comb." even if table and comb have never been mentioned before, whereas
the S-parser can only recognise meanings already defined. On the other
hand, the S-parser will accept conditions like the one in "if there are
fewer than 8 men in Verona, ..." whereas the A-parser would reject
the assertion "There are fewer than 8 men in Verona." as being too vague
to act upon. Similarly, the A-parser works only in the present tense,
whereas the S-parser can handle the past and perfect tenses. (Neither
can handle any future tenses, since a computer cannot either control or
definitely predict the future.)

The A-parser works by applying the S-parser to text at |parse_node| structures
in the parse tree. So we will build the S-parser first, which won't involve
the parse tree at all. We will then go back to the parse tree to write the
A-parser.

@ The S-parser is similar to the expression parser in a regular compiler. It
is in some ways simpler because natural language tends not to form complex
formulae, but in other ways more complicated, because performance issues
are very significant when comparing excerpts of text, and because there are
many more ambiguities to resolve.

Our aim is to turn any excerpt into a |specification| structure inside
Inform. This is a universal holder for both values and descriptions of
values, where "value" is interpreted very broadly. It is usually too
difficult to go directly from text to a |specification|, so we use
a two-stage process:

(1) parse the text to a |parse_node| which holds all possible interpretations
of it, and then
(2) convert the most likely-looking interpretation(s) to a |specification|.

Thus |parse_node| structures are private to the S-parser, whereas
|specification| structures appear all over Inform.

@ Consider the following contrived example.

>> if Mr Fitzwilliam Darcy was carrying at least three things which are in the box, increase the score by 7;

(1) There are |excerpt_meaning| structures for "Mr Fitzwilliam Darcy" and
"Mr Bingham's box", which hold the wording needed to refer to these objects.
In parsing the example sentence, we connect these structures to the excerpts
"Mr Fitzwilliam Darcy" -- an exact match -- and "the box" -- an
abbreviated one. The |excerpt_meaning| structures contain pointers to
further |instance| structures which represent the identities of these
two tangible things, that is, Darcy and his friend's box.
(2) Another |excerpt_meaning| holds the name "score" and points it to a
|nonlocal_variable| structure for the relevant global variable.
(3) And a further |excerpt_meaning| holds the name "things" and points it
to a |instance| structure representing the common identity shared by
all things. Inform treats individual, tangible objects such as Mr Darcy
and intangible categories of objects such as thing by representing both
with the same structure -- |instance|. This mirrors the way that common
and proper nouns are grammatically quite similar in natural language.
(4) The final noun phrase in the above example is "7". There's no
|excerpt_meaning| structure for this -- it would be insanely inefficient
to make such things -- and instead it is parsed directly as a "literal",
being converted immediately into a |specification|, of which more below.
(5) Another |excerpt_meaning| structure holds the wording "if ... , ..."
and is connected to a |phrase| structure for the "if" construction. Here,
the wording includes flexible-sized gaps (written "...") where excerpts
should appear: the S-parser will only recognise this if the excerpts make
sense in themselves. The combination of a |phrase| plus the results of parsing
these gaps is stored in a structure called an |invocation|.
(6) In the example, the first gap is filled by "Mr Fitzwilliam Darcy was
carrying at least three things which are in the box", which the S-parser
detects as being a condition. This is translated into a |pcalc_prop|
structure -- a predicate-calculus proposition, that is, which is a
representation in mathematical logic of the meaning of this sentence.
(-a) "was carrying" is recognised as matching wording in a |verb_usage|
structure. This points to an underlying relation, stored in a |binary_predicate|
structure, but combines it with an indication of tense stored in a |time_period|.
Here the |binary_predicate| is the carrying relation and the |time_period|
is the past tense. (The term "binary predicate" comes from logic once
again; an Inform author would call the same concept a "relation".)
(-b) "are in" is recognised as a usage of the verb "to be" plus "in",
which matches the wording of a |preposition| structure. Here the tense
derives only from the "to be" part: which is "are", so the |time_period|
parsed is the present tense. This makes the |preposition| a simpler
business than the |verb_usage| structure -- it only needs to refer to the
underlying meaning, which is once again a |binary_predicate| structure,
the one for the containment relation.
(-c) "which" is a word introducing a relative clause. A sentence can
only have one primary verb, which in this example is "was carrying".
But other verbs can exist in relative clauses, and the effect of writing
"X which V Y" qualifies X by saying that any noun N matching X must also
satisfy "N V Y", where V is the verb. The relative-clause construction
is an example of syntax built directly into the S-parser. It doesn't come
from any data structures, like the meanings of "score" or "Mr Fitzwilliam
Darcy".
(-d) "at least three things" is an example of a noun phrase which has a
head and a tail. The head, "at least three", is recognised as matching
the wording in a |determiner| structure, "at least (number)", together
with the literal number 3. Once again, the |determiner| describes textual
appearances; it points to another structure, a |quantifier|, to hold the
meaning. This is another logical term, and Inform's debugging log would
write the resulting term as |Card>=3| ("cardinality of at least 3").
Inform only uses |determiner| structures when they quantify, that is, when
they talk about a possible range of objects rather than a single item.
A grammar of English would probably say that the "the" in "the box" is
also grammatically a determiner, but it doesn't get a |determiner| structure
in Inform.
(7) The second gap in the "if ... , ..." excerpt is "increase the score
by 1", which the S-parser detects as a use of yet another |phrase|, this
time referred to by the |excerpt_meaning| structure for "increase ... by
...". It's worth noting that the S-parser doesn't check types, so it would
have been happy to match "increase 2 by 1" -- an impossibility. The
S-parser's job is to find all possible meanings at a textual level,
sometimes producing a list of options: the type-checker will winnow these
out later on.

So parsing the text "if Mr Fitzwilliam Darcy was carrying at least three
things which are in the box, increase the score by 7" is going to result in
a mass of pointers to different structures, and we need an umbrella structure
to hold this mass together. This is what the |parse_node| is for, but as
explained above, it's really only an intermediate state used while the S-parser
is working.

@ One obvious category of word is missing: there are no adjectives in this
example. Inform currently supports many sorts of adjective -- either/or
properties, such as "open"; values of kinds of value which coincide with
properties, such as "green" as a value of a "colour"; and adjectives
defined with conditions or full phrases, such as "invisible" resulting
from "Definition: a thing is invisible if...".

The S-parser treats all adjectives alike -- more or less just as names.
This is because "open" may mean one thing for containers and another
for scenes, for example. The identification of an adjective's name with
its set of possible meanings is via a structure called |adjective|.

@ To sum up. If we write "text" $\rightarrow$ structure used for parsing
$\rightarrow$ structure used to hold meaning, our example is parsed like so:

(1) "Mr Fitzwilliam Darcy" $\rightarrow$ |excerpt_meaning| $\rightarrow$ |instance|

(2) "the score" $\rightarrow$ |excerpt_meaning| $\rightarrow$ |nonlocal_variable|

(3) "things" $\rightarrow$ |excerpt_meaning| $\rightarrow$ |instance|

(4) "7" $\rightarrow$ ...none... $\rightarrow$ |specification|

(5) "if Mr Fitzwilliam Darcy was carrying at least three things which are in the
box, increase the score by 7" $\rightarrow$ |excerpt_meaning| $\rightarrow$
|invocation| (incorporating a |phrase|)

(6) "Mr Fitzwilliam Darcy was carrying at least three things which are in the box"
$\rightarrow$ ...many... $\rightarrow$ |pcalc_prop|
(-a) "was carrying" $\rightarrow$ |verb_usage| $\rightarrow$ |binary_predicate|
plus |time_period|
(-b) "are in" $\rightarrow$ |preposition| $\rightarrow$ |binary_predicate|
plus |time_period|
(-c) "at least three" $\rightarrow$ |determiner| $\rightarrow$ |quantifier| plus
literal number

(7) "increase the score by 7" $\rightarrow$ |excerpt_meaning| $\rightarrow$
|invocation| (incorporating a |phrase|)

(8) Adjectives like the "closed" in "three closed doors" are identified
by name only, with little attempt to detect which sense is meant, so they
pass straight through the S-parser as pointers to |adjective|
structures.

@ To sum up further still, |excerpt_meaning| structures are used to parse
simple nouns and imperative phrases, whereas other specialist structures
(|preposition|, |determiner|, etc.) are used to parse the hinges
which hold sentences together. Once parsed, individual excerpts tend to
have meanings which might be pointers to a bewildering range of structures
(|instance|, |quantifier|, |binary_predicate|, |adjective|,
etc.) but these pointers are held together inside the S-parser by a single
unifying construction: the |parse_node|. And we will eventually turn the
whole thing into a |specification| for the rest of Inform to use.
