About Sentence Diagrams.

Description and examples of the diagrams which this module turns sentences into.

@ First, an acknowledgement: the sentence diagrams in this section are generated
automatically by //linguistics-test//. (This means they are always up to date.)
If you are interested in using //linguistics// in some context other than Inform,
//linguistics-test// may be a good starting point.

@ Every example sentence in this section was passed in turn to the <sentence>
nonterminal, and the trees displayed below were the result. For example:

= (undisplayed text from Figures/simple-raw.txt)

Sentence (1) here made no sense: there was no verb. It was therefore left as
a single |SENTENCE_NT| node with no children. In all other cases, as in (2),
there are three children: verb, subject phrase, and object phrase.[1]

In this tree notation, indentation shows which nodes are children of which
others. The node types, such as |SENTENCE_NT|, are in capitals and all end
in |_NT|. The text leading to the creation of the node then appears in quotes.
After that are "annotations", written in braces.[2] In sentence (2), we see:

(a) The |VERB_NT| node is annotated with its grammatical form -- it is "to be",
in third person singular, active mood, present tense, and a negative sense --
and also its semantic meaning -- the equality relationship "is".
(b) The second |UNPARSED_NOUN_NT| node is annotated with the article used to
introduce it -- the indefinite article, "a", which could be any of masculine,
feminine or neuter, could be either nominative or accusative, but is
certainly singular.

[1] Since "to be" is a copular verb, in sentence (2) we really mean "the
phrase in the object position".

[2] Since the 1850s a variety of tree-diagram schemes for sentence structure
has been proposed: see //Wikipedia -> https://en.wikipedia.org/wiki/Sentence_diagram//.
These tend to be quite large, with many optional features -- no bad thing when
the aim is to explain. But our aim is to process, not to illustrate, and
whereas a typical dependency tree would have nodes for both "not" and "a",
we use annotations instead. We want fairly flat sentence trees with a simple,
predictable shape.

@ Using <sentence> alone tends to result in a lot of |UNPARSED_NOUN_NT| nodes.
This is unsatisfying, but useful, because sometimes the meaning of a verb
affects how those nodes should be parsed further. The idea is that the user
will traverse the tree and parse the |UNPARSED_NOUN_NT| nodes as needed.
Calling the function //Nouns::recognise// on such a node will test to see
if it's a known common or proper noun, and amend it accordingly.

The //linguistics-test// program does this automatically, so from here on,
all examples shown will have that operation done. For example:

= (undisplayed text from Figures/simple.txt)

Here the two |UNPARSED_NOUN_NT| nodes have been recognised as usages of a
proper noun, Beth, and a common noun, sailor, respectively, and they are
annotated with their grammatical usages -- in so far as we can tell. These
two nouns do not inflect with case in English, but they are both singular.

@ Clearly the //linguistics// module needs to know some vocabulary in order
to do this, and in the test runs displayed in this section, it is using a
very limited stock of nouns, verbs and prepositions as follows:

= (undisplayed text from Figures/vocabulary.txt)

We only know that Beth is feminine-gendered and sailor masculine-gendered[1]
because the vocabulary being used by //linguistics-test// says so. It's
important to appreciate that although an English reader might twig that
Beth is a common girl's name, we can't do that.

[1] In the grammatical sense that "she" can refer to Beth and "he" to a
generic identity-unknown sailor. Pronouns in English are a source of real
sensitivity and if //linguistics// were a module to generate text, rather
than recognise it, we would take much more care over this. Our interest
is in grammatical gender, not the assignment of sexes to people.

@ So, then, let us start with simple copular sentences -- that is,
sentences involving the verb "to be", which equate two subjects rather
than having a subject act upon an object. This is why one "ought to" say
"The traitor is I" instead of "The traitor is me", although nobody does.

= (undisplayed text from Figures/copular.txt)

@ Next, regular sentences, that is, those where the verb is not copular
but instead expresses some relationship between a subject and an object
which play different roles.

= (undisplayed text from Figures/regular.txt)

Each |RELATIONSHIP_NT| node expresses that it, and the other term, are
in some non-copular relation to each other. The annotation gives that
relation from the point of view of the node, not from the point of view
of the subject of the sentence. For example, in (4), the subject of the
sentence (woman) is carried by the object (table), but the |RELATIONSHIP_NT|
node is for the table, and so the meaning is "carries", not "carried-by".

@ Possessive verbs need careful handling because of the wide range of
meanings they can carry which may not involve ownership as such (cf. French
"j'ai trente ans", or English "I have mumps"). But syntactically they are
just like other non-copular verbs, and we parse them as such.

= (undisplayed text from Figures/possessive.txt)

@ An unusual feature of English is its use of subject-verb inversion:

= (undisplayed text from Figures/inversion.txt)

It would be easy to auto-fix the inversion in sentence (1), by simply
swapping the "on the table" and "Ming vase" subtrees over, but we want
to preserve the distinction because Inform will make some use of it.

Sentence (2) here is arguably just plain wrong, but we do very occasionally
allow that sort of thing in Inform (for e.g. "east of X is south of Y").

@ Existential sentences, using the defective subject nounphrase "there", are
marked with an additional annotation.

= (undisplayed text from Figures/there.txt)

In sentences (3) and (4) here, the resulting trees are essentially identical
except for the existential annotation.

Note that "there" as an object phrase is also defective, but not considered
existential (it is more likely an anaphora -- "A woman is there" implies a
reference to a location already being discussed, whereas "There is a woman"
does not).

@ Two sorts of adverbs are recognised, for certainty and occurrence, and they
are handled by making additional annotations to the verb node, not by adding
fresh nodes:

= (undisplayed text from Figures/usingadverbs.txt)

@ We can also support imperative verbs, with "special meanings" which are
not necessarily relational, and do not always lead to |RELATIONSHIP_NT|
subtrees. See //Special Meanings//.

= (undisplayed text from Figures/imperatives.txt)

@ That shows the full range of what happens with verb nodes. Turning back
to noun phrases, we can have serial lists:

= (undisplayed text from Figures/composite.txt)

Note that |AND_NT| nodes always have exactly two children, and that the serial
comma is allowed but not required.

|AND_NT| in conjunction with |RELATIONSHIP_NT| can allow for zeugmas.
Zeugma is sometimes thought to be rare in English and to be basically a comedy
effect, as in the famous Flanders and Swann lyric:

>> She made no reply, up her mind, and a dash for the door.

in which three completely different senses of the same verb are used,
but in which the verb appears only once. It might seem reasonable just to
disallow this. Unfortunately, less extreme zeugmas occur all the time:

>> The red door is west of the Dining Room and east of the Ballroom.

@ Now we introduce pronouns to the mix. These are detected automatically
by //linguistics//, and exist in nominative and accusative cases in
English. Note the difference in annotations between "them" and "you",
for example.

= (undisplayed text from Figures/usingpronouns.txt)

@ "Callings" use the special syntax "X called Y", which has to be handled
here in the //linguistics// module so that Y can safely wording which would
otherwise have a structural meaning. ("Called" is to Inform as the backslash
character, making letters literal, is to C.)

= (undisplayed text from Figures/callings.txt)

@ The word "with", often but not always used in conjunction with "kind of":

= (undisplayed text from Figures/withs.txt)
