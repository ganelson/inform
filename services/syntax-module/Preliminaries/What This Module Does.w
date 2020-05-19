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

@ The trunk of the tree can be grown in any sequence: call //SyntaxTree::push_bud//
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

@ Meaning is an ambiguous thing, and so the tree needs to be capable of
representing multiple interpretations of the same wording. So nodes have not
only |next| and |down| links to other nodes, but also |next_alternative| links,
which -- if used -- fork the syntax tree into different possible readings.

These are not added to the tree by grafting: that's only done for definite
meanings. Instead, multiple ambiguous readings mostly lie beneath |AMBIGUITY_NT|
nodes -- see //SyntaxTree::add_reading//. For example, we might have:
= (text)
	sun is orange
	    sun
	    AMBIGUITY
	        orange (read as being a fruit)
	        orange (read as being a colour)
=

@ An extensive suite of functions is provided to make it easy to traverse
a syntax tree, calling a visitor function on each node: see //SyntaxTree::traverse//.

@h Nodes.
Syntax trees are made up of //parse_node// structures. While these are in
principle individual nodes, they effectively represent subtrees, because they
carry with them links to the nodes below. A //parse_node// object can
therefore equally represent "orange", "the orange envelope", or "now the card
is in the orange envelope".

Each node carries three essential pieces of information with it:
(1) The text giving rise to it (say, "Section Five - Fruit").
(2) A node type ID, which in broad terms says what kind of reference is being
made (say, |HEADING_NT|). The possible node types are stored in the C type
|node_type_t|, which corresponds to some metadata in a //node_type_metadata//
object: see //Node::get_type// and //NodeType::get_metadata//.
(3) A list of optional annotations, which are either integer or object-valued,
and which give specifics about the meaning (say, the level number in the
hierarchy of headings). See //Node Annotations//.

@h Fussy, defensive, pedantry.
Safe to say that Inform includes bugs: the more defensive coding we can do,
the better. That means not only extensive logging (see //Node::log_tree//)
but also strict verification tests on every tree made (see //Tree Verification//).
(a) The only nodes allowed to exist are those for node types declared
by //NodeType::new//: more generally, see //Node Types// on metadata associated
with these.
(b) A node of type |A| can only be a child of a node of type |B| if
//NodeType::parentage_allowed// says so, and this is (mostly) a matter
of calling //NodeType::allow_parentage_for_categories// -- parentage depends
not on the type per se, but on the category of the type, which groups types
together.
(c) A node of type |A| can only have an annotation with ID |I| if
//Annotations::is_allowed// says so. To declare an annotation legal,
call |Annotations::allow(A, I)|, or |Annotations::allow_for_category(C, I)|
for the category |C| of |A|.
