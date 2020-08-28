[Node::] Parse Nodes.

Syntax trees are made of single nodes, each representing one way to understand
a given piece of text.

@h Nodes themselves.
Each node is an instance of this:

=
typedef struct parse_node {
	struct wording text_parsed; /* the text being interpreted by this node */
	node_type_t node_type; /* what the node basically represents */
	struct parse_node_annotation *annotations; /* see //Node Annotations// */

	struct parse_node *down; /* pointers within the current interpretation */
	struct parse_node *next;
	struct parse_node *next_alternative; /* fork to alternative interpretation */

	int score; /* scratch storage for choosing between interpretations */
	int last_seen_on_traverse; /* scratch storage for detecting accidental loops */
	CLASS_DEFINITION
} parse_node;

@h Creation.

=
parse_node *Node::new(node_type_t t) {
	parse_node *pn = CREATE(parse_node);
	pn->node_type = t;
	Node::set_text(pn, EMPTY_WORDING);
	Annotations::clear(pn);
	pn->down = NULL; pn->next = NULL; pn->next_alternative = NULL;
	pn->last_seen_on_traverse = 0;
	Node::set_score(pn, 0);
	return pn;
}

@ The following constructor routines fill out the fields in useful ways.
Here's one if a word range is to be attached:

=
parse_node *Node::new_with_words(node_type_t code_number, wording W) {
	parse_node *pn = Node::new(code_number);
	Node::set_text(pn, W);
	return pn;
}

@ The attached text.

=
wording Node::get_text(parse_node *pn) {
	if (pn == NULL) return EMPTY_WORDING;
	return pn->text_parsed;
}

void Node::set_text(parse_node *pn, wording W) {
	if (pn == NULL) internal_error("tried to set words for null node");
	pn->text_parsed = W;
}

@h Annotations.
It's easily overlooked that the single most useful piece of information
at each node is its node type, accessed as follows:

=
node_type_t Node::get_type(parse_node *pn) {
	if (pn == NULL) return INVALID_NT;
	return pn->node_type;
}
int Node::is(parse_node *pn, node_type_t t) {
	if ((pn) && (pn->node_type == t)) return TRUE;
	return FALSE;
}

@ When setting, we have to preserve the invariant, so we clear away any
annotations no longer relevant to the node's new identity.

=
void Node::set_type(parse_node *pn, node_type_t nt) {
	#ifdef IMMUTABLE_NODE
	node_type_t from = pn->node_type;
	if (IMMUTABLE_NODE(from)) {
		LOG("$P changed to $N\n", pn, nt);
		internal_error("immutable type changed");
	}
	#endif

	pn->node_type = nt;
	Annotations::clear_invalid(pn);
}
void Node::set_type_and_clear_annotations(parse_node *pn, node_type_t nt) {
	pn->node_type = nt;
	Annotations::clear(pn);
}

@ The integer score, used in choosing best matches:

=
int Node::get_score(parse_node *pn) { return pn->score; }
void Node::set_score(parse_node *pn, int s) { pn->score = s; }

@h Composition.
This simply means stringing two nodes together into a list.

=
parse_node *Node::compose(parse_node *A, parse_node *B) {
	if (A == NULL) return B;
	A->next = B;
	return A;
}

@h Copying parse nodes.
If we want to duplicate a parse node, we cannot do so with a shallow bit copy:
the node points to a list of its annotations, and the duplicated node would
therefore point to the same list. If, subsequently, one of the two nodes
were annotated further, then the other would change in synchrony, which
would be the source of mysterious bugs. We therefore need to perform a
deep copy which duplicates not only the node, but also its annotation list.

=
void Node::copy(parse_node *to, parse_node *from) {
	COPY(to, from, parse_node);
	Annotations::copy(to, from);
}

parse_node *Node::duplicate(parse_node *p) {
	parse_node *dup = Node::new(INVALID_NT);
	Node::copy(dup, p);
	return dup;
}

@ This variation preserves links out.

=
void Node::copy_in_place(parse_node *to, parse_node *from) {
	parse_node *next_link = to->next;
	parse_node *alt_link = to->next_alternative;
	parse_node *down_link = to->down;
	Node::copy(to, from);
	to->next = next_link;
	to->next_alternative = alt_link;
	to->down = down_link;
}

@ And to deep-copy a whole subtree:

=
void Node::copy_subtree(parse_node *from, parse_node *to, int level) {
	if ((from == NULL) || (to == NULL)) internal_error("Null deep copy");
	Node::copy(to, from);
	if (from->down) {
		to->down = Node::new(INVALID_NT);
		Node::copy_subtree(from->down, to->down, level+1);
	}
	if ((level>0) && (from->next)) {
		to->next = Node::new(INVALID_NT);
		Node::copy_subtree(from->next, to->next, level);
	}
	if ((level>0) && (from->next_alternative)) {
		to->next_alternative = Node::new(INVALID_NT);
		Node::copy_subtree(from->next_alternative, to->next_alternative, level);
	}
}

@h Child count.

=
int Node::no_children(parse_node *pn) {
	int c=0;
	for (parse_node *p = (pn)?(pn->down):NULL; p; p = p->next) c++;
	return c;
}

@h Detection of subnodes.
This is needed when producing problem messages: we may need to work up from
an arbitrary leaf to the main sentence branch containing it. At any rate,
given a node |PN|, we want to know if another node |to_find| lies beneath
it. (This will never be called when |PN| is the root, and from all other
nodes it will certainly run quickly, since the tree is otherwise neither
wide nor deep.)

=
int Node::contains(parse_node *PN, parse_node *to_find) {
	parse_node *to_try;
	if (PN == to_find) return TRUE;
	for (to_try = PN->down; to_try; to_try = to_try->next)
		if (Node::contains(to_try, to_find))
			return TRUE;
	return FALSE;
}

@h The word range beneath a given node.
Any given node may be the root of a subtree concerning the structure of
a given contiguous range of words in the original source text. The
"left edge" of a node |PN| is the least-numbered word considered by any
node at or below |PN| in the tree; the "right edge" is the highest-numbered
word similarly considered.

The left edge is calculated by taking the minimum value of the word number
for |PN| and the left edges of its children, except that $-1$ is not counted.
(A left edge of $-1$ means no source text is here.)

=
int Node::left_edge_of(parse_node *PN) {
	parse_node *child;
	int l = Wordings::first_wn(Node::get_text(PN)), lc;
	for (child = PN->down; child; child = child->next) {
		lc = Node::left_edge_of(child);
		if ((lc >= 0) && ((l == -1) || (lc < l))) l = lc;
	}
	return l;
}

@ Symmetrically, the right edge is found by taking the maximum word number
for |PN| and the right edges of its children.

=
int Node::right_edge_of(parse_node *PN) {
	parse_node *child;
	int r = Wordings::last_wn(Node::get_text(PN)), rc;
	if (Wordings::first_wn(Node::get_text(PN)) < 0) r = -1;
	for (child = PN->down; child; child = child->next) {
		rc = Node::right_edge_of(child);
		if ((rc >= 0) && ((r == -1) || (rc > r))) r = rc;
	}
	return r;
}

@h Logging the parse tree.
For most trees, logging is a fearsome prospect, but here we only mean printing
out a textual representation to the debugging log.

There are two ways to recurse through it: logging the entire tree as seen from
a given node, or logging just the "subtree" of that node: meaning, itself and
everything beneath it, but not its siblings or alternatives. Each recursion
has its own unique token value, used to prevent infinite loops in the event
that we're logging a badly-formed tree; this should never happen, but since
logging is a diagnostic tool, we want it to work even when Inform is sick.

=
void Node::log_tree(OUTPUT_STREAM, void *vpn) {
	parse_node *pn = (parse_node *) vpn;
	if (pn == NULL) { WRITE("<null-meaning-list>\n"); return; }
	Node::log_subtree_recursively(OUT, pn, 0, 0, 1, FALSE,
		SyntaxTree::new_traverse_token());
}

void Node::summarise_tree(OUTPUT_STREAM, void *vpn) {
	parse_node *pn = (parse_node *) vpn;
	if (pn == NULL) { WRITE("<null-meaning-list>\n"); return; }
	Node::log_subtree_recursively(OUT, pn, 0, 0, 1, TRUE,
		SyntaxTree::new_traverse_token());
}

void Node::log_subtree(OUTPUT_STREAM, void *vpn) {
	parse_node *pn = (parse_node *) vpn;
	if (pn == NULL) { WRITE("<null-parse-node>"); return; }
	WRITE("$P\n", pn);
	if (pn->down) {
		LOG_INDENT;
		Node::log_subtree_recursively(OUT, pn->down, 0, 0, 1, FALSE,
			SyntaxTree::new_traverse_token());
		LOG_OUTDENT;
	}
}

@ Either way, we recurse as follows, being careful not to make recursive calls
to pursue |next| links, since otherwise a source text with more than 100,000
sentences or so will exceed the typical stack size Inform has to run in.

=
void Node::log_subtree_recursively(OUTPUT_STREAM, parse_node *pn, int num,
	int of, int gen, int summarise, int traverse_token) {
	int active = TRUE;
	while (pn) {
		if (pn->last_seen_on_traverse == traverse_token) {
			WRITE("*** Not a tree: %W ***\n", Node::get_text(pn)); return;
		}
		pn->last_seen_on_traverse = traverse_token;
		@<Calculate num and of such that this is [num/of] if they aren't already supplied@>;

		if (pn == NULL) { WRITE("<null-parse-node>\n"); return; }
		if (summarise) {
			if (Node::is(pn, ENDHERE_NT)) active = TRUE;
		}
		if (active) {
			if (of > 1) {
				WRITE("[%d/%d] ", num, of);
				if (Node::get_score(pn) != 0) WRITE("(score %d) ", Node::get_score(pn));
			}
			WRITE("$P\n", pn);
			if (pn->down) {
				LOG_INDENT;
				int recurse = TRUE;
				#ifdef RULE_NT
				if ((summarise) && (Node::is(pn, RULE_NT))) recurse = FALSE;
				#endif
				if (recurse)
					Node::log_subtree_recursively(OUT,
						pn->down, 0, 0, gen+1, summarise, traverse_token);
				LOG_OUTDENT;
			}
			if (pn->next_alternative) Node::log_subtree_recursively(OUT,
				pn->next_alternative, num+1, of, gen+1, summarise, traverse_token);
		}
		if (summarise) {
			if (Node::is(pn, BEGINHERE_NT)) {
				active = FALSE;
				LOG("...\n");
			}
		}

		pn = pn->next; num = 0; of = 0; gen++;
	}
}

@ When the first alternative is called, |Node::log_subtree_recursively|
has arguments 0 and 0 for the possibility. The following code finds out the
correct value for |of|, setting this possibility to be |[1/of]|. When we later
iterate through other alternatives, we pass on correct values of |num| and |of|,
so that this code won't be used again on the same horizontal list of possibilities.

@<Calculate num and of such that this is [num/of] if they aren't already supplied@> =
	if (num == 0) {
		parse_node *pn2;
		for (pn2 = pn, of = 0; pn2; pn2 = pn2->next_alternative, of++) ;
		num = 1;
	}

@ All of those routines make use of the following, which actually performs
the log of a parse node. Note that this always produces exactly one line of
text in the debugging log.

=
void Node::log_node(OUTPUT_STREAM, void *vpn) {
	parse_node *pn = (parse_node *) vpn;
	if (pn == NULL) { WRITE("<null-parse-node>\n"); return; }
	NodeType::log(OUT, (int) pn->node_type);
	if (Wordings::nonempty(Node::get_text(pn))) {
		TEMPORARY_TEXT(text)
		WRITE_TO(text, "%W", Node::get_text(pn));
		Str::truncate(text, 60);
		WRITE("'%S'", text);
		DISCARD_TEXT(text)
	}
	Annotations::write_annotations(OUT, pn);
	int a = 0;
	while ((pn->next_alternative) && (a<9)) a++, pn = pn->next_alternative;
	if (a > 0) WRITE("/%d", a);
}
void Node::write_node(OUTPUT_STREAM, char *format_string, void *vpn) {
	Node::log_node(OUT, vpn);
}
