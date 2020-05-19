[SyntaxTree::] Syntax Trees.

To parse trees which decompose the meaning of excerpts of text,
and which allow annotations to be made at each node.

@h Optional headings tree.
Within //inform7// and //inbuild//, the code in this section is augmented by
//supervisor: Headings//, which gives every syntax tree an associated tree of
source headings; but as far as //syntax// is concerned, that's all an optional
extra.

Code using //syntax// in this way must define |HEADING_TREE_SYNTAX_TYPE| as the
class of object to which our |headings| field will point, and callback functions
|NEW_HEADING_TREE_SYNTAX_CALLBACK| and |NEW_HEADING_SYNTAX_CALLBACK| to
initialise and add to it.

@default HEADING_TREE_SYNTAX_TYPE void /* in which case, never used */

@h Syntax trees.
Each //parse_node_tree// object represents a different syntax tree; typically
the entire source text being compiled by //inform7//, including any extensions
it includes, will form a single //parse_node_tree//.

@d MAX_BUD_STACK_SIZE 100 /* must be at least the number of heading levels plus 3 */

=
typedef struct parse_node_tree {
	struct parse_node *root_node;
	int bud_parent_sp;
	struct parse_node *bud_parent_stack[MAX_BUD_STACK_SIZE];
	struct parse_node *last_sentence; /* cached position in tree */
	int allow_last_sentence_cacheing;
	int trace_sentences;
	HEADING_TREE_SYNTAX_TYPE *headings;
	CLASS_DEFINITION
} parse_node_tree;

parse_node_tree *SyntaxTree::new(void) {
	parse_node_tree *T = CREATE(parse_node_tree);
	T->root_node = Node::new(ROOT_NT);
	T->bud_parent_sp = 0;
	T->last_sentence = NULL;
	T->allow_last_sentence_cacheing = FALSE;
	T->trace_sentences = FALSE;
	SyntaxTree::push_bud(T, T->root_node);
	#ifdef NEW_HEADING_TREE_SYNTAX_CALLBACK
	T->headings = NEW_HEADING_TREE_SYNTAX_CALLBACK(T);
	#endif
	return T;
}

@h Buds and grafts.
"Buds" are positions in the tree to which new sentence subtrees can be grafted:

=
int SyntaxTree::push_bud(parse_node_tree *T, parse_node *to) {
	int l = T->bud_parent_sp;
	if (T->bud_parent_sp >= MAX_BUD_STACK_SIZE) internal_error("bud stack overflow");
	T->bud_parent_stack[T->bud_parent_sp++] = to;
	return l;
}

void SyntaxTree::pop_bud(parse_node_tree *T, int l) {
	T->bud_parent_sp = l;
}

@ Sentences are grafted onto the bud position at the top of the stack.

=
void SyntaxTree::graft_sentence(parse_node_tree *T, parse_node *new) {
	if (T->bud_parent_sp == 0) internal_error("no attachment point");
	if (Node::get_type(new) == HEADING_NT) @<Adjust bud point for a heading@>;
	parse_node *sentence_attachment_point = T->bud_parent_stack[T->bud_parent_sp-1];
	SyntaxTree::graft(T, new, sentence_attachment_point);
	if (Node::get_type(new) == HEADING_NT) SyntaxTree::push_bud(T, new);
}

@ When what's attached is a heading node, that changes the stack. The idea
here is that sentences graft beneath the heading to which they belong. If the
current bud point is a heading called "Section 22", and then we reach the
heading sentence "Part 2", this no longer belongs under Section 22, and we
pop the bud stack until we're beneath a heading node superior to Parts.

@<Adjust bud point for a heading@> =
	int heading_level = Annotations::read_int(new, heading_level_ANNOT);
	if (heading_level > 0)
		for (int i = T->bud_parent_sp-1; i>=0; i--) {
			parse_node *P = T->bud_parent_stack[i];
			if ((Node::get_type(P) == HEADING_NT) &&
				(Annotations::read_int(P, heading_level_ANNOT) >= heading_level))
				T->bud_parent_sp = i;
		}

@ Syntax trees for Inform source text have a tendency to be wide. If a source
text is basically a list of 5000 sentences, then there may be a node with 5000
children, even though the maximum depth of the tree might be as low as 10.

Because of that we must be wary of algorithms with quadratic running time in
the width of the tree, and we get around that with a cache. Certain "tree
surgery" operations, when the tree is being rearranged, would throw this,
so the optimisation should be enabled only when needed.

=
void SyntaxTree::enable_last_sentence_cache(parse_node_tree *T) {
	T->last_sentence = NULL; /* because this may have changed since last enabled */
	T->allow_last_sentence_cacheing = TRUE;
}

void SyntaxTree::disable_last_sentence_cache(parse_node_tree *T) {
	T->allow_last_sentence_cacheing = FALSE;
}

@ The function |SyntaxTree::graft| is named by analogy with gardening, where the
rootstock of one plant is joined to a scion (or cutting) of another, so that a
root chosen for strength can be combined with the fruits or blossom of the scion.

|SyntaxTree::graft| returns the node for which |scion| is the immediate sibling,
that is, it returns the previously youngest child of the |rootstock| (or |NULL|
if it previously had no children).

=
parse_node *SyntaxTree::graft(parse_node_tree *T, parse_node *scion, parse_node *rootstock) {
	parse_node *elder = NULL;
	if (scion == NULL) internal_error("scion is null");
	if (rootstock == NULL) internal_error("rootstock is null");
	/* is the new node to be the only child of the old? */
	if (rootstock->down == NULL) { rootstock->down = scion; return NULL; }
	/* can last sentence cacheing save us a long search through many children of root? */
	if ((rootstock == T->root_node) && (T->allow_last_sentence_cacheing)) {
		if (T->last_sentence) {
			elder = T->last_sentence;
			elder->next = scion;
			T->last_sentence = scion;
			return elder;
		}
		/* we don't know who's the youngest child now, but we know who soon will be: */
		T->last_sentence = scion;
	}
	/* find youngest child of rootstock... */
	for (elder = rootstock->down; elder->next; elder = elder->next) ;
	/* ...and make the new node its younger sibling */
	elder->next = scion; return elder;
}

@ No speed worries on the much smaller trees with alternative readings:

=
parse_node *SyntaxTree::graft_alternative(parse_node *scion, parse_node *rootstock) {
	if (scion == NULL) internal_error("scion is null");
	if (rootstock == NULL) internal_error("rootstock is null");
	/* is the new node to be the only child of the old? */
	if (rootstock->down == NULL) { rootstock->down = scion; return NULL; }
	/* find youngest child of rootstock... */
	parse_node *elder = NULL;
	for (elder = rootstock->down; elder->next_alternative; elder = elder->next_alternative) ;
	/* ...and make the new node its younger sibling */
	elder->next_alternative = scion; return elder;
}

@ And we can loop through these like so:

@d LOOP_THROUGH_ALTERNATIVES(p, from)
	for (p = from; p; p = p->next_alternative)

@h Where we currently are in the text.
Inform makes many traverses through the big parse tree, often modifying as it
goes, and keeps track of its position so that it can make any problem messages
correctly refer to the location of the faulty text in the original source files.

During such traverses, |current_sentence| is always the subtree being looked
at: it is always a child of the tree root, and is usually a |SENTENCE_NT|
node, hence the name.

= (early code)
parse_node *current_sentence = NULL;

@h General traversals.
It's convenient to have a general system for traversing a syntax tree, visiting
each node in the connected component of the tree root. C doesn't make this sort
of thing easy, though, so there follows a welter of boringly similar functions
with convoluted type signatures.

All these do basically the same thing. //SyntaxTree::traverse// calls a visitor
function on each node; //SyntaxTree::traverse_from// the same, but from a
chosen start position, rather than the root of the tree.

In this first version, the visitor function has type signature |parse_node * -> void|.

=
void SyntaxTree::traverse(parse_node_tree *T, void (*visitor)(parse_node *)) {
	SyntaxTree::traverse_from(T->root_node, visitor);
}
void SyntaxTree::traverse_from(parse_node *pn, void (*visitor)(parse_node *)) {
	parse_node *SCS = current_sentence;
	for (; pn; pn = pn->next) {
		if (NodeType::is_top_level(pn->node_type)) SyntaxTree::traverse_from(pn->down, visitor);
		if (SyntaxTree::visitable(pn->node_type)) {
			if (NodeType::is_sentence(pn->node_type)) current_sentence = pn;
			(*visitor)(pn);
		}
	}
	current_sentence = SCS;
}

@ Note that any node not "visitable" is omitted, where the following function
is the sole arbiter. This depends only on its node type.

=
int SyntaxTree::visitable(node_type_t t) {
	if (NodeType::has_flag(t, DONT_VISIT_NFLAG)) return FALSE;
	return TRUE;
}

@ And now the same thing, but where the visitor function has the type
signature |text_stream *, parse_node * -> void|.

=
void SyntaxTree::traverse_text(parse_node_tree *T, text_stream *OUT,
	void (*visitor)(text_stream *, parse_node *)) {
	SyntaxTree::traverse_text_from(OUT, T->root_node, visitor);
}
void SyntaxTree::traverse_text_from(text_stream *OUT, parse_node *pn,
	void (*visitor)(text_stream *, parse_node *)) {
	parse_node *SCS = current_sentence;
	for (; pn; pn = pn->next) {
		if (NodeType::is_top_level(pn->node_type))
			SyntaxTree::traverse_text_from(OUT, pn->down, visitor);
		if (SyntaxTree::visitable(pn->node_type)) {
			if (NodeType::is_sentence(pn->node_type)) current_sentence = pn;
			(*visitor)(OUT, pn);
		}
	}
	current_sentence = SCS;
}

@ And now the same thing, but where the visitor function has the type
signature |parse_node *, int * -> void|.

=
void SyntaxTree::traverse_intp(parse_node_tree *T,
	void (*visitor)(parse_node *, int *), int *X) {
	SyntaxTree::traverse_intp_from(T->root_node, visitor, X);
}
void SyntaxTree::traverse_intp_from(parse_node *pn,
	void (*visitor)(parse_node *, int *), int *X) {
	parse_node *SCS = current_sentence;
	for (; pn; pn = pn->next) {
		if (NodeType::is_top_level(pn->node_type))
			SyntaxTree::traverse_intp_from(pn->down, visitor, X);
		if (SyntaxTree::visitable(pn->node_type)) {
			if (NodeType::is_sentence(pn->node_type)) current_sentence = pn;
			(*visitor)(pn, X);
		}
	}
	current_sentence = SCS;
}

@ And the same thing, but where the visitor function has the type signature
|parse_node *, int *, int * -> void|.

=
void SyntaxTree::traverse_intp_intp(parse_node_tree *T,
	void (*visitor)(parse_node *, int *, int *), int *X, int *Y) {
	SyntaxTree::traverse_intp_intp_from(T->root_node, visitor, X, Y);
}
void SyntaxTree::traverse_intp_intp_from(parse_node *pn,
	void (*visitor)(parse_node *, int *, int *), int *X, int *Y) {
	parse_node *SCS = current_sentence;
	for (; pn; pn = pn->next) {
		if (NodeType::is_top_level(pn->node_type))
			SyntaxTree::traverse_intp_intp_from(pn->down, visitor, X, Y);
		if (SyntaxTree::visitable(pn->node_type)) {
			if (NodeType::is_sentence(pn->node_type)) current_sentence = pn;
			(*visitor)(pn, X, Y);
		}
	}
	current_sentence = SCS;
}

@ And now for |parse_node *, parse_node ** -> void|.

=
void SyntaxTree::traverse_nodep(parse_node_tree *T,
	void (*visitor)(parse_node *, parse_node **), parse_node **X) {
	SyntaxTree::traverse_nodep_from(T->root_node, visitor, X);
}
void SyntaxTree::traverse_nodep_from(parse_node *pn,
	void (*visitor)(parse_node *, parse_node **), parse_node **X) {
	parse_node *SCS = current_sentence;
	for (; pn; pn = pn->next) {
		if (NodeType::is_top_level(pn->node_type))
			SyntaxTree::traverse_nodep_from(pn->down, visitor, X);
		if (SyntaxTree::visitable(pn->node_type)) {
			if (NodeType::is_sentence(pn->node_type)) current_sentence = pn;
			(*visitor)(pn, X);
		}
	}
	current_sentence = SCS;
}

@ This is a tricksier sort of traverse, which tells the visitor function the
heading node it belongs to. The visitor function now has type signature
|parse_node_tree *, parse_node *, parse_node *, int * -> void|, where the
two nodes are the one being visited and its heading, respectively.

=
void SyntaxTree::traverse_headingwise(parse_node_tree *T,
	void (*visitor)(parse_node_tree *, parse_node *, parse_node *, int *), int *N) {
	SyntaxTree::traverse_headingwise_from(T, T->root_node, visitor, NULL, N);
}
void SyntaxTree::traverse_headingwise_from(parse_node_tree *T, parse_node *pn,
	void (*visitor)(parse_node_tree *, parse_node *, parse_node *, int *),
	parse_node *last_h0, int *N) {
	parse_node *SCS = current_sentence;
	for (; pn; pn = pn->next) {
		if (NodeType::is_top_level(pn->node_type)) {
			parse_node *H0 = last_h0;
			if ((Node::is(pn, HEADING_NT)) &&
				(Annotations::read_int(pn, heading_level_ANNOT) == 0))
				H0 = pn;
			SyntaxTree::traverse_headingwise_from(T, pn->down, visitor, H0, N);
		}
		if (SyntaxTree::visitable(pn->node_type)) {
			if (NodeType::is_sentence(pn->node_type)) current_sentence = pn;
			(*visitor)(T, pn, last_h0, N);
		}
	}
	current_sentence = SCS;
}

@ And this is another variation: a traverse to find a node with a particular
property. The process halts as soon as the visitor function, which has
signature |parse_node *, parse_node *, parse_node ** -> int|, returns |TRUE|,
and the idea is that the visitor will store its result in the |parse_node *|
pointed to by its last argument.

Note that this one doesn't record its position in |current_sentence|. The
fuss over top-level nodes is to ensure recursion even though top-level
nodes are not visitable; otherwise the function would never find anything
because no visitable nodes would ever be reached.

=
int SyntaxTree::traverse_to_find(parse_node_tree *T,
	int (*visitor)(parse_node *, parse_node *, parse_node **),
	parse_node **X) {
	return SyntaxTree::traverse_to_find_from(T->root_node, visitor, NULL, X);
}
int SyntaxTree::traverse_to_find_from(parse_node *pn,
	int (*visitor)(parse_node *, parse_node *, parse_node **),
	parse_node *from, parse_node **X) {
	for (; pn; pn = pn->next) {
		if (SyntaxTree::visitable(pn->node_type))
			if ((*visitor)(pn, from, X))
				return TRUE;
		if (NodeType::is_top_level(pn->node_type))
			if (SyntaxTree::traverse_to_find_from(pn->down, visitor, pn, X))
				return TRUE;
	}
	return FALSE;
}

@ And still another. This one traverses only up to a given stop position,
and the visitor has signature |parse_node *, void ** -> void|, the idea
being that the final |void **| is a pointer to a general object pointer.
This is the sort of thing which brings C into disrepute, but we don't use
it very much.

=
void SyntaxTree::traverse_up_to_ip(parse_node_tree *T, parse_node *end,
	void (*visitor)(parse_node *, void **), void **X) {
	SyntaxTree::traverse_from_up_to_ip(end, T->root_node, visitor, X);
}
int SyntaxTree::traverse_from_up_to_ip(parse_node *end, parse_node *pn,
	void (*visitor)(parse_node *, void **), void **X) {
	parse_node *SCS = current_sentence;
	for (; pn; pn = pn->next) {
		if (pn == end) { current_sentence = SCS; return TRUE; }
		if (NodeType::is_top_level(pn->node_type)) {
			if (SyntaxTree::traverse_from_up_to_ip(end, pn->down, visitor, X)) {
				current_sentence = SCS; return TRUE;
			}
		}
		if (SyntaxTree::visitable(pn->node_type)) {
			if (NodeType::is_sentence(pn->node_type)) current_sentence = pn;
			(*visitor)(pn, X);
		}
	}
	current_sentence = SCS;
	return FALSE;
}

@h Unconditional traverses.
Finally, here are two traverses which visit every node, not just the "visitable"
ones. Here is a depth-first version (like all of the functions above):

=
void SyntaxTree::traverse_dfirst(parse_node_tree *T, void (*visitor)(parse_node *)) {
	SyntaxTree::traverse_dfirst_from(T->root_node, visitor);
}
void SyntaxTree::traverse_dfirst_from(parse_node *pn, void (*visitor)(parse_node *)) {
	parse_node *SCS = current_sentence;
	for (; pn; pn = pn->next) {
		SyntaxTree::traverse_dfirst_from(pn->down, visitor);
		if (NodeType::is_sentence(pn->node_type)) current_sentence = pn;
		(*visitor)(pn);
	}
	current_sentence = SCS;
}

@ And this is a width-first variant (unlike all of the functions above).

=
void SyntaxTree::traverse_wfirst(parse_node_tree *T, void (*visitor)(parse_node *)) {
	SyntaxTree::traverse_wfirst_from(T->root_node, visitor);
}
void SyntaxTree::traverse_wfirst_from(parse_node *pn, void (*visitor)(parse_node *)) {
	parse_node *SCS = current_sentence;
	for (; pn; pn = pn->next) {
		if (NodeType::is_sentence(pn->node_type)) current_sentence = pn;
		SyntaxTree::traverse_wfirst_from(pn->down, visitor);
		(*visitor)(pn);
	}
	current_sentence = SCS;
}

@h Cautious traverses.
When logging or verifying the tree, we cannot use the carefree functions
above: the tree might be malformed. As a way to detect cycles, we call for
a new "traverse token" -- just a unique integer value -- and mark all nodes
visited with that value.

=
int pn_log_token = 0;

int SyntaxTree::new_traverse_token(void) {
	return ++pn_log_token;
}

@h Toggling log output.
Various modules conventionally use this global setting to toggle debugging
log output:

=
int SyntaxTree::is_trace_set(parse_node_tree *T) {
	return T->trace_sentences;
}

void SyntaxTree::set_trace(parse_node_tree *T) {
	T->trace_sentences = TRUE;
}

void SyntaxTree::clear_trace(parse_node_tree *T) {
	T->trace_sentences = FALSE;
}

void SyntaxTree::toggle_trace(parse_node_tree *T) {
	T->trace_sentences = (T->trace_sentences)?FALSE:TRUE;
}

@h Ambiguity subtrees.
The following function adds a new |reading| to an |existing| interpretation
of some wording |W|, and return the node now representing. For example,
suppose the text "orange" can be read as a noun for fruit, a noun for colour,
or an adjective, resulting in nodes |fruit_node| and |colour_node| and |adj_node|.
Then:
(a) |SyntaxTree::add_reading(NULL, fruit_node, W)| returns |noun_node|,
(b) but |SyntaxTree::add_reading(fruit_node, colour_node, W)| returns this subtree:
= (text)
	AMBIGUITY_NT A
	    fruit_node
		colour_node
=
(c) and |SyntaxTree::add_reading(A, adj_node, W)| returns the subtree:
= (text)
	AMBIGUITY_NT A
	    fruit_node
		colour_node
		adj_node
=
Thus it accumulates possible readings of a given text.

A complication is that the following callback function is offered the chance
to amend this process in individual cases; it's called whenever |reading|
is about to become one of the alternatives to some existing |E|. If it returns
|TRUE|, we assume it has done something of its own already, and do nothing
further.

(//inform7// uses this to rearrange ambiguous phrase invocations to be sorted
out in type-checking: see //core: Dash//.)

=
parse_node *SyntaxTree::add_reading(parse_node *existing, parse_node *reading, wording W) {
	if (existing == NULL) return reading;
	if (Node::is(reading, UNKNOWN_NT)) return existing;
	if (Node::is(reading, AMBIGUITY_NT)) reading = reading->down;
	if (Node::is(existing, AMBIGUITY_NT)) {
		#ifdef AMBIGUITY_JOIN_SYNTAX_CALLBACK
		for (parse_node *E = existing->down; E; E = E->next_alternative)
			if (AMBIGUITY_JOIN_SYNTAX_CALLBACK(E, reading))
				return existing;
		#endif
		parse_node *L = existing->down;
		while ((L) && (L->next_alternative)) L = L->next_alternative;
		L->next_alternative = reading;
		return existing;
	}

	#ifdef AMBIGUITY_JOIN_SYNTAX_CALLBACK
	if (AMBIGUITY_JOIN_SYNTAX_CALLBACK(existing, reading)) return existing;
	#endif

	parse_node *A = Node::new_with_words(AMBIGUITY_NT, W);
	A->down = existing;
	A->down->next_alternative = reading;
	return A;
}
