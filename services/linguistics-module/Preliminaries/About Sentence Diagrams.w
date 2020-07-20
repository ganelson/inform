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
have been proposed: see //Wikipedia -> https://en.wikipedia.org/wiki/Sentence_diagram//.
These tend to be quite large, with many optional features -- no bad thing when
the aim is to explain. But our aim is to process, not to illustrate, and
whereas a typical dependency tree would have nodes for both "not" and "a",
we use annotations instead. The aim is to have flattish sentence trees
with a simple, predictable shape.

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

@ An unusual feature of English is its use of subject-verb inversion:

= (undisplayed text from Figures/inversion.txt)

It would be easy to auto-fix the inversion in sentence (1), by simply
swapping the "on the table" and "Ming vase" subtrees over, but we want
to preserve the distinction because Inform will make some use of it.

Sentence (2) here is arguably just plain wrong, but we do very occasionally
allow that sort of thing in Inform (for e.g. "east of X is south of Y").

@ Now we introduce pronouns to the mix. These are detected automatically
by //linguistics//, and exist in nominative and accusative cases in
English. Note the difference in annotations between "them" and "you",
for example.

= (undisplayed text from Figures/usingpronouns.txt)

