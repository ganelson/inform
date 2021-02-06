How To Include This Module.

What to do to make use of the syntax module in a new command-line tool.

@h Status.
The syntax module provided as one of the "services" suite of modules, which means
that it was built with a view to potential incorporation in multiple tools.
It can be found, for example, in //inform7//, //inbuild// and //syntax-test//,
among others. //syntax-test// may be useful as a minimal example of a tool
using //syntax//.

By convention, the modules considered as "services" have no dependencies on
other modules except for //foundation// and other "services" modules.

A tool can import //syntax// only if it also imports //foundation// and
//words//.

@h Importing the module.
We'll use the term "parent" to mean the tool which is importing //syntax//,
that is, which will include its code and be able to use it. As with any
imported module,
(*) The contents page of the parent's web must identify and locate the
module:
= (text as Inweb)
Import: somepath/syntax
=
(*) The parent must call |SyntaxModule::start()| just after it starts up, and
|SyntaxModule::end()| just before it shuts down. (But just after, and just
before, the corresponding calls to //foundation//.)

But in addition, the parent of //syntax// must define some Preform grammar:

(*) |<language-modifying-sentence>| to recognise sentences modifying the
language which is currently being parsed;
(*) |<structural-sentence>| to recognise structurally important sentences;
(*) |<dividing-sentence>| to recognise sentences which divide up the text,
normally headings;
(*) |<comma-divisible-sentence>| to recognise sentences where a comma plays
a role normally expected to be played by a colon.

Though compulsory, these don't need to do much: see //syntax-test: Unit Tests//.

@h Using callbacks.
Shared modules like this one are tweaked in behaviour by defining "callback
functions". This means that the parent might provide a function of its own
which would answer a question put to it by the module, or take some action
on behalf of the module: it's a callback in the sense that the parent is
normally calling the module, but then the module calls the parent back to
ask for data or action.

The parent must indicate which function to use by defining a constant with
a specific name as being equal to that function's name. A fictional example
would be
= (text as Inweb)
	@d EXPRESS_SURPRISE_SYNTAX_CALLBACK Emotions::gosh
	
	=
	void Emotions::gosh(text_stream *OUT) {
	    WRITE("Good gracious!\n");
	}
=
The syntax module has many callbacks, but they are all optional. The following
alphabetical list has references to fuller explanations:

(*) |AMBIGUITY_JOIN_SYNTAX_CALLBACK| can rearrange ambiguous readings as
added to a syntax tree: see //SyntaxTree::add_reading//.

(*) |ANNOTATION_COPY_SYNTAX_CALLBACK| can perform deep rather than shallow
copies of node annotations when these are essential: see //Annotations::copy//.

(*) |ANNOTATION_PERMISSIONS_SYNTAX_CALLBACK|, |MORE_ANNOTATION_PERMISSIONS_SYNTAX_CALLBACK|
and |EVEN_MORE_ANNOTATION_PERMISSIONS_SYNTAX_CALLBACK| gives permission for nodes
of given types to have annotations with given IDs, and effectively provides a
way to create custom annotations: see //Annotations::make_annotation_allowed_table//.

(*) |BEGIN_OR_END_HERE_SYNTAX_CALLBACK| is called when a new extension beginning
or ending sentence is found in the source text being broken into sentences:
see //Sentences::make_node//.

(*) |DIVIDE_AT_COLON_SYNTAX_CALLBACK| is called to ask permission to break a
sentence at a colon. See //Sentences::break_inner//.

(*) |IS_SENTENCE_NODE_SYNTAX_CALLBACK| is asked whether a given node represents
a regular sentence or not: see //NodeType::is_sentence//.

(*) |LANGUAGE_ELEMENT_SYNTAX_CALLBACK| is called when a sentence is found matching
the nonterminal |<language-modifying-sentence>|: see //Sentences::make_node//.

(*) |LOG_UNENUMERATED_NODE_TYPES_SYNTAX_CALLBACK| is called to log a node type
not recognised as one of the enumerated |*_NT| values: see //NodeType::log//.

(*) |NEW_HEADING_SYNTAX_CALLBACK| is called when a new heading sentence is found
in the source text being broken into sentences: see //Sentences::make_node//.

(*) |NEW_HEADING_TREE_SYNTAX_CALLBACK| is called when a new syntax tree is being
created, and needs to be given a matching tree of headings: see //SyntaxTree::new//.

(*) |NODE_METADATA_SETUP_SYNTAX_CALLBACK|, |MORE_NODE_METADATA_SETUP_SYNTAX_CALLBACK|
and |EVEN_MORE_NODE_METADATA_SETUP_SYNTAX_CALLBACK| adds new syntax tree node
types: see //NodeType::metadata_setup//.

(*) |PARENTAGE_EXCEPTIONS_SYNTAX_CALLBACK| allows exceptions to the rules about
which nodes in a syntax tree can be parents of which other nodes: see
//NodeType::parentage_allowed//.

(*) |PARENTAGE_PERMISSIONS_SYNTAX_CALLBACK|, |MORE_PARENTAGE_PERMISSIONS_SYNTAX_CALLBACK|
and |EVEN_MORE_PARENTAGE_PERMISSIONS_SYNTAX_CALLBACK| adds permissions for nodes
to be parents of each other: see //NodeType::make_parentage_allowed_table//.

(*) |PROBLEM_SYNTAX_CALLBACK| is called when a syntax error is found, and can
prevent this from being issued to the terminal as an error message: see
//Sentences::syntax_problem//.

(*) |NEW_NONSTRUCTURAL_SENTENCE_SYNTAX_CALLBACK| is called when a new, regular
sentence is found in the source text being broken into sentences: see
//Sentences::make_node//.

(*) |UNKNOWN_PREFORM_RESULT_SYNTAX_CALLBACK| is used only by the Preform cache:
if this isn't being used, it's sufficient to return a null pointer. See
//Simple Preform Cache//.
