What This Module Does.

An overview of the syntax module's role and abilities.

@h Prerequisites.
The syntax module is a part of the Inform compiler toolset. It is
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

@h Syntax trees.
Most algorithms for parsing natural language involve the construction of
trees, in which the original words appear as leaves at the top of the tree,
while the grammatical functions they serve appear as the branches and trunk:
thus the word "orange", as an adjective, might be growing from a branch
which represents a noun clause ("the orange envelope"), growing in turn from
a trunk which in turn might represent a assertion sentence:

>> The card is in the orange envelope.

The Inform tools represent syntax trees by //parse_node_tree// structures
(see //SyntaxTree::new//), but there are very few of these: the entire
source text compiled by //inform7// is just one syntax tree. When //supervisor//
manages extensions, it may generate one //parse_node_tree// object for each
extension whose text it reads. Still -- there are few trees.

But there are many nodes. Syntax trees are made up of //parse_node// structures.
While these are in principle individual nodes, they effectively represent
subtrees, because they carry with them links to the nodes below. A //parse_node//
object can therefore equally represent "orange", "the orange envelope", or
"now the card is in the orange envelope".

Meaning is an ambiguous thing, and so the tree needs to be capable of
representing multiple interpretations of the same wording. So nodes have not
only |next| and |down| links to other nodes, but also |next_alternative| links,
which -- if used -- fork the syntax tree into different possible readings.

@ The main trunk of the tree can be grown in any sequence: call //SyntaxTree::push_bud//
to begin "budding" from a particular branch, and //SyntaxTree::pop_bud// to go back
to where you were. These are also used automatically to ensure that sentences
arriving at //SyntaxTree::graft_sentence// are grafted under the headings to
which they belong. Thus, the sentences
= (text as Inform 7)
	Chapter 20
	Section 1
	The cat is in the cardboard box.
	Section 2
	The ball of yarn is here.
=
would actually be grafted like so:
= (text)
	RESULT                                      BUD STACK BEFORE THIS
	Chapter 20                                  (empty)
	    Section 1                               Chapter 20
            The cat is in the cardboard box.    Chapter 20 > Section 1
	    Section 2                               Chapter 20 > Section 1
            The ball of yarn is here.           Chapter 20 > Section 2
=
But it is also possible to graft smaller (not-whole-sentence) cuttings onto 
each other using //SyntaxTree::graft//, which doesn't involve the bud stack
at all.

@ An extensive suite of functions is provided to make it easy to traverse
a syntax tree, calling a visitor function on each node: see //SyntaxTree::traverse//.
