[Assertions::Copular::] To Be and To Have.

To handle sentences with primary verb "to be" or "to have".

@h Definitions.

@ "To Be and To Have" ought to be the name of an incomprehensible
book by Sartre which dismisses Heidegger's seminal "To Have and To Be",
or something like that, but instead it is the name of a section which contains
the most important sentence handler: the one for assertions.

This will turn out to be quite a lot of work, occupying four sections of
code in all. For etymological reasons, the English verb "to be" is a mixture
of several different verbs which have blurred together into one: consider "I
am 5", "I am happy" and "I am Chloe". Even the definition occupies some
12 columns of the "Oxford English Dictionary" and they make interesting
reading in clarifying the problem. Most computer programming languages
implement only |=| and |==|, which correspond to OED's meaning 10, "to exist
as the thing known by a certain name; to be identical with". But Inform
implements a much broader set of meanings. For example, its distinction
between spatial and property knowledge reflects the OED's distinction between
meanings 5a ("to have or occupy a place somewhere") and 9b ("to have a
place among the things distinguished by a specified quality") respectively.

"To have" may seem as if it ought to be an entirely different verb from
"to be", but in fact they have heavily overlapping meanings, and we will
implement them with a great deal of common code. (English is unusual in the
way that "to be" has taken over some of the functions which "to have"
has in other languages -- compare the French "j'ai fatigu\'e", literally
"I have tired" rather than "I am tired", which is arguably more logical
since it talks about the possession of a property.)

@ Here, and in the sections which follow, we conventionally write |px| and
|py| for the subtrees representing subject and object sides of the verb. Thus

>> The white marble is in the bamboo box.

will result in |px| representing "white marble" and |py| "in the bamboo
box" (not just a leaf, since it will be a tree showing the containment
relationship as well as the noun).

@ In either case, then, we end up going through |Assertions::Copular::make_assertion| and then to the
following routine, which asserts that subtree |px| "is" |py|.

During traverse 1, this takes place in a three-stage process:

(a) The two subtrees are each individually "refined", which clarifies the
meaning of the noun phrases used in them, and tidies up the tree (see
"Refine Parse Tree").

(b) The Creator is invited to create new objects, variables and so on to
ensure that unrecognised noun phrases are made meaningful (see "The Creator").

(c) In a "there is X" sentence, where |px| is a meaningless placeholder,
we cause X to be created, but otherwise do nothing; otherwise, we call
the massive |Assertions::Maker::make_assertion_recursive| routine (see "Make Assertions").

In traverse 2, only (c) takes place; (a) and (b) are one-time events.
