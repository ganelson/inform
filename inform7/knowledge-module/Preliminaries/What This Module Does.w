What This Module Does.

An overview of the knowledge module's role and abilities.

@h Prerequisites.
The knowledge module is a part of the Inform compiler toolset. It is
presented as a literate program or "web". Before diving in:
(a) It helps to have some experience of reading webs: see //inweb// for more.
(b) The module is written in C, in fact ANSI C99, but this is disguised by the
fact that it uses some extension syntaxes provided by the //inweb// literate
programming tool, making it a dialect of C called InC. See //inweb// for
full details, but essentially: it's C without predeclarations or header files,
and where functions have names like |Tags::add_by_name| rather than just |add_by_name|.
(c) This module uses other modules drawn from the compiler (see //structure//), and also
uses a module of utility functions called //foundation//.
For more, see //foundation: A Brief Guide to Foundation//.

@h The Model.
This module's task is to build the "model world", the initial state of the
world as it is chosen by an Inform author.[1] This consists of:

(*) Kinds, such as "vehicle", created in source text.
(*) Instances of kinds, such as a specific lorry in a fictional world being
created with Inform.
(*) Permanently existing variables, which have kinds and initial values.
(*) Either-or properties, which individual instances might or might not have:
for example, the lorry might be "parked" or "not parked".
(*) Properties with values, which some instances will have and some will not,
and with differing values: for example, the colour of the lorry might be "yellow".
(*) Relationships between instances. For example, a specific person might
"know how to drive" the yellow lorry, or might not.

But the model does not contain:

(*) Kinds, such as "number", built in to Inform.[2]
(*) Values, such as the number 176, which exist without anyone getting to
choose whether they should exist or not.
(*) Temporary variables used during phrases or activities, but not existing
at the start of play.
(*) Adjectives such as "even" as applied to numbers, or "empty" as applied
to containers, whose truth or falsity is determined by something other than
the author's whim. An author cannot choose that 176 is odd, and whether a
container is empty depends only on whether there is something in it.
(*) Relationships which are, similarly, determined by an algorithm and not
by a specific authorial choice. Like it or not, 176 is "greater than" 8.

[1] The term "model" is drawn partly from interactive fiction, but also from
model theory in the sense of logic, where a "model" is a specific solution
showing that a set of logical propositions can all simultaneously be true.

[2] Properly speaking, kinds created by Neptune files inside kits rather than
being declared in source text.

@ The model is constructed entirely from a stream of logical propositions
sent here by the //assertions// module. Those propositions may be mutually
inconsistent -- either flatly contradictory or just impossible to reconcile.

The stream of supposed truthful statements comes to this module through calls
to either //Assert::true// or //Assert::true_about//. These reduce a
proposition to a set of facts concerning things in the model; as we have
seen, the model includes kinds, variables, instances and relations, and so
we need a unified type for "something you can know a fact about". That
type is called //inference_subject//. Each subject has its own list of known
facts: we call such a fact an //inference// because it has (usually) been
inferred from a proposition.

//Chapter 3// implements our system of properties: each different value
or either-or property is a //property// object. There might be a puritan
case for abolishing this type in favour of regarding either-or properties
as special cases of |unary_predicate| and value properties as special cases
of |binary_predicate| (by identifying a predicate with its setting relation),
but I do not think this would clarify anything.

//Chapter 4// gives a general API for dealing with //Inference Subjects//,
and then works systematically through the various categories of these.
Kinds and binary predicates already exist from other modules (see
//kinds: Chapter 2: Kinds// and //calculus: Chapter 3: Binary Predicates//
respectively), but //Instances// and //Nonlocal Variables// are new.

Finally, //Chapter 5// deals with the actual inferences, and with how the
model world is constructed. The core of Inform does nothing very interesting
here, but plugins from the //if// module add some domain-specific savvy.
