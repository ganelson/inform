[VerifyTree::] Tree Verification.

Did we go wrong anywhere? This section is purely defensive, and tests whether
Inform contains bugs of a kind which lead to malformed syntax trees: that
should never happen even if the source text being compiled is a dumpster fire.

@h Verify integrity.
We can perform two different checks.

The first duty of a tree is to contain no loops, and the following checks
that (rejecting even undirected loops). In addition, it checks that each
node has an enumerated node type, rather than a meaning code.

=
int tree_stats_size = 0, tree_stats_depth = 0, tree_stats_width = 0;

void VerifyTree::verify_integrity(parse_node_tree *T) {
	tree_stats_size = 0; tree_stats_depth = 0; tree_stats_width = 1;
	VerifyTree::verify_integrity_below(T->root_node);
}

void VerifyTree::verify_integrity_below(parse_node *p) {
	VerifyTree::verify_integrity_r(p->down, p, "down", 0,
		SyntaxTree::new_traverse_token());
}

@ The verification traverse is a very cautious manoeuvre: we step through
the tree, testing each branch with our outstretched foot. At the first sign
of trouble we panic.

=
void VerifyTree::verify_integrity_r(parse_node *p,
	parse_node *from, char *way, int depth, int traverse_token) {
	for (int width = 0; p; p = p->next, width++) {
		if (p->last_seen_on_traverse == traverse_token) {
			LOG("Cycle found in parse tree, found %s from:\n$P", way, from);
			Errors::set_internal_handler(NULL);
			internal_error("Cycle found in parse tree");
		}
		p->last_seen_on_traverse = traverse_token;
		node_type_t t = Node::get_type(p);
		if (NodeType::is_enumerated(t)) tree_stats_size++;
		else {
			LOG("Invalid node type (%08x) found %s from:\n$P", (int) t, way, from);
			Errors::set_internal_handler(NULL);
			internal_error("Link broken in parse tree");
		}
		if (p->next_alternative)
			VerifyTree::verify_integrity_r(p->next_alternative,
				p, "alt", depth, traverse_token);
		if (p->down)
			VerifyTree::verify_integrity_r(p->down,
				p, "down", depth+1, traverse_token);
		if (width > tree_stats_width) tree_stats_width = width;
	}
	if (depth > tree_stats_depth) tree_stats_depth = depth;
}

@h Verify structure.
The parse tree is a complicated structure, arbitrarily wide and deep, and
containing many different node types, each subject to its own rules of usage.
In this second check, we ensure that nodes have acceptable parentage and
annotations -- that is, parentage and annotations which fall within the
permissions set up when their node types were created.

If any test fails, Inform will stop with an internal error. (If there are
multiple failures, we itemise them to the debugging log, and only produce
a single internal error at the end.)

We protect ourselves by first checking that the tree is intact as a
structure: once we know the tree is safe to climb over, we can wander
about counting branches with impunity.

=
void VerifyTree::verify_structure(parse_node_tree *T) {
	if (T->root_node == NULL) {
		Errors::set_internal_handler(NULL);
		internal_error("Root of parse tree NULL");
	}
	VerifyTree::verify_structure_from(T->root_node);
}

void VerifyTree::verify_structure_from(parse_node *p) {
	VerifyTree::verify_integrity_below(p);
	int errors_found = VerifyTree::verify_structure_r(p, NULL, 0);
	if (errors_found > 0) {
		LOG("[Verification failed: %d node errors]\n", errors_found);
		Errors::set_internal_handler(NULL);
		internal_error("Parse tree broken");
	}
}

@ Note that on every call to the following routine, (i) |p| is a valid
parse node and (ii) either |p| is the tree root, in which case |parent| is
|NULL|, or |parent| is the unique node having |p| (or an alternative to |p|)
among its children.

=
int VerifyTree::verify_structure_r(parse_node *p, parse_node *parent, int ec) {
	node_type_t t = Node::get_type(p);
	node_type_metadata *metadata = NodeType::get_metadata(t);
	if (metadata == NULL) internal_error("broken tree should have been reported");

	@<Check rule (1) of the invariant@>;
	@<Check rule (2) of the invariant@>;
	if (parent) @<Check rule (3) of the invariant@>;

	int children_count = 0;
	for (parse_node *q=p->down; q; q=q->next, children_count++)
		ec += VerifyTree::verify_structure_r(q, p, ec);

	@<Check rule (4) of the invariant@>;

	if (p->next_alternative)
		ec += VerifyTree::verify_structure_r(p->next_alternative, parent, ec);
	return ec;
}

@ Rule (1): no INVALID nodes.

@<Check rule (1) of the invariant@> =
	if (t == INVALID_NT) {
		LOG("N%d is $N, which is not allowed except temporarily\n",
			p->allocation_id, t);
		@<Log this invariant failure@>
	}

@ Rule (2): all annotations must be legal for the given node type.

@<Check rule (2) of the invariant@> =
	for (parse_node_annotation *pna=p->annotations; pna; pna=pna->next_annotation)
		if (!(Annotations::is_allowed(t, pna->annotation_id))) {
			LOG("N%d is $N, which is not allowed to have annotation %d\n",
				p->allocation_id, t, pna->annotation_id, p);
			LOG("Node %08x, ann %d\n", t, pna->annotation_id);
			@<Log this invariant failure@>
		}

@ Rule (3): can this combination of parent and child exist?

@<Check rule (3) of the invariant@> =
	node_type_t t_parent = Node::get_type(parent);

	if (!(NodeType::parentage_allowed(t_parent, t))) {
		LOG("N%d is $N: should not be a child of $N\n",
			p->allocation_id, t, t_parent);
		@<Log this invariant failure@>
	}

@ Rule (4): The number of children has to be within the given extrema.

@<Check rule (4) of the invariant@> =
	if (children_count < metadata->min_children) {
		LOG("N%d has %d children, but min for $N is %d:\n",
			p->allocation_id, children_count, t, metadata->min_children);
		@<Log this invariant failure@>
	}
	if (children_count > metadata->max_children) {
		LOG("N%d has %d children, but max for $N is %d:\n",
			p->allocation_id, children_count, t, metadata->max_children);
		@<Log this invariant failure@>
	}

@ (Logging the root node produces an absolutely enormous output.)

@<Log this invariant failure@> =
	if (Node::is(parent, ROOT_NT)) LOG("Failing subtree:\n$T", p);
	else LOG("Failing subtree:\n$T", parent);
	ec++;
