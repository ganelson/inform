[Assertions::] Introduction to Assertions.

A general introduction to how the A-parser deals with assertions.

@ Previously, on "Inform"... The text has been read in, broken into a
stream of identified words, broken further into sentences organised under
headings, and then parsed into a basic tree. That last part was the work of
the A-parser, the simpler and more rigid of the two parsers we use. The
A-parser is divided in half. The lower level gets as
far as it can on a context-free basis, building only a simple tree. The
upper level, which forms this chapter, "refines" the tree (making it
more detailed), and then acts upon it. The task was delayed until now
because we needed to be able to parse expressions (using the S-parser),
and so to form logical propositions and to identify kinds of value.
But now we pick up the thread of assertions exactly where it was left off.

@ Recall that the "model" is the collection of objects and
named values, together with their relations to each other and to abstract
values, including their properties. For instance, we want to turn the source:

>> The Wine Emporium is a room. A cask is a kind of thing. A cask is always fixed in place.

>> The Vouvray cask and the Muscadet cask are casks in the Wine Emporium.

into a model with four objects (the Emporium, the player, and two different
casks), with various properties (names, for instance) and relations between
them (the player and both casks being in the Emporium).

Inform would be a more elegant program if it only needed to create the model,
but it also has to create a whole lot of other stuff: tables, equations,
kinds, kinds of value, test scripts and so on, not to mention rules,
rulebooks, actions and activities to sort out how they will change in play.

@ The main work of this chapter is to go through each of the source text's
sentences in turn, refining its tree and then acting on it.

"Verb Phrases" has already identified the primary verb in
each sentence. A few primary verbs are reserved for fixed-form syntaxes
which are easy for us to handle -- for instance,

>> [1] Test distros with "wear hat / open can".

When we find a sentence like that, we simply delegate handling it to the
relevant part of Inform. Sentences like this are inflexible and easy to parse,
but have no effect on the model. Though they sometimes make data of a sort,
it's not data which can participate in relations. (For instance, this one
creates a test script, which is not even a value, just a preprogrammed setup
for the TEST command.)

Delegating out work on conceptually boring sentences like this is the task of
"Traverse for Assertions", an exercise in clearing the field so that we can
spend the rest of the chapter concentrating on sentences about the model.
For example:

>> [2] The fedora hat is on the can of Ubuntu cola.

There really is an Ubuntu cola; it's a fair-trade product which it amuses my
more Linux-aware students to drink. This might be called a "genuine assertion",
because it describes objects and relationships within the model. It will lead
to two objects being created, and a relation between them being initially true.

But as well as genuine assertions, we also have "faux assertions". These
use "to be" or "to have" as their primary verbs, and that means we
can't tell them from genuine assertions. What makes them faux is that, like
sentence [1] above, they're talking about processes or data outside of the
model. For example,

>> [3] Printing the name of something is an activity.

Once again, if we find a sentence like that, we simply take direct action
by calling the relevant section of Inform -- here, the one in charge of
activities.

@ So how are we to tell cases [2] and [3] apart? They both have the same
primary verb, "to be". This is really why the initial assertion parser
stopped where it did, because at that stage we didn't have the means to
answer the question.

The answer, clearly, is that we have to parse the noun phrases. This is done
in "Refine Parse Tree", which tries to identify what each noun phrase refers
to, and often decomposes it into shorter phrases in the process. The "Refine
Parse Tree" step applies the S-parser, which among much else recognises the
names of kinds of value like "activity".

An interesting point about refining the parse tree is that noun phrases often
talk about things in the model which do not yet exist. [2], for instance,
might be the first mention of either the hat or the can, or both. With a
little care we can work out what seems to be new here, and to create it --
this is the work of "The Creator".

We can then roughly categorise the two noun phrases on either side of
"to be" -- for instance: name I don't recognise on the left, name of
kind of value on the right. There are currently 14 categories, which means
that we could potentially divide sentences like [2] and [3] into $14^2 = 196$
cases. In fact many of these cases are more or less the same, so we "only"
need to handle about 60 actually different outcomes, and about half of
those will be problem messages of one sort or another. This massive
exercise in dividing into cases occupies "Make Assertions".

@ So although this chapter is called "Assertions", a great deal of the
work is devoted to dealing with sentences which aren't assertions. We have
to get rid of obvious non-assertion sentences, but also unobvious faux
assertions, and of course malformed sentences, which each need to receive
helpful to-the-point Problem messages.

But sooner or later we run into the real thing. The golden rule is that
{\it nobody is allowed to change the model except by asserting that some
proposition is true}. If we want a blue kingfisher to exist, we can't
call some object-creation routine; we write a proposition declaring that
an object exists of kind "animal" which is called "blue kingfisher",
and then we call |Calculus::Propositions::Assert::assert_true|. What happens
as a result, and how all of that is reconciled (if it is), doesn't concern
the A-parser. And the same is true if we need to handle a sentence like:

>> The blue kingfisher is in the upper tree fork.

We convert this to a proposition, and then assert that the proposition
holds. Whether that's logically possible is not our concern.

@ The rest of the chapter provides two nifty gadgets for generalising
assertions -- both of them ways to make one assertion beget others, and
therefore to make creating complex arrangements simpler. These are
"assemblies", brought about by sentences like:

>> A steering wheel is part of every vehicle.

And also "implications", brought about by sentences like:

>> An open lockable door is usually unlocked.

Although tricky to get right, they don't do anything conceptually hard --
they are just abbreviations for what would otherwise be verbose piles of
assertion sentences.

@ So to sum up: this upper level of the A-parser will go through the
sentences, act on all of the exceptional cases (declaring test cases,
activities, rules and so on), and convert the genuine assertions into
logical propositions about the model. These it will declare to be true.

As for how the model somehow emerges from that, the A-parser knows nothing.
That story will be taken up in a later chapter.
