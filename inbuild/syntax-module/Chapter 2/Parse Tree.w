[ParseTree::] Parse Tree.

To parse trees which decompose the meaning of excerpts of text,
and which allow annotations to be made at each node.

@h Trees store meanings.
Most algorithms for parsing natural language involve the construction of
trees, in which the original words appear as leaves at the top of the tree,
while the grammatical functions they serve appear as the branches and trunk:
thus the word "orange", as an adjective, might be growing from a branch
which represents a noun clause ("the orange envelope"), growing in turn from
a trunk which in turn might represent a assertion sentence:

>> The card is in the orange envelope.

Inform goes further than this. The result of parsing any piece of text is
always a tree, so that a common data structure is used for every meaning
which is stored inside Inform.

The tree is stored as a collection of "parse nodes", with |next| and
|down| links between them to represent siblings and children.

Some text is ambiguous. Because of that, the tree needs to be capable of
representing multiple interpretations of the same wording. So nodes also
have a |next_alternative| link, which -- if used -- forks the tree into
different possible readings.

@d MAX_ATTACHMENT_STACK_SIZE 100 /* must be at least the number of heading levels plus 3 */

=
typedef struct parse_node_tree {
	struct parse_node *root_node;
	int attachment_sp;
	struct parse_node *attachment_stack_parent[MAX_ATTACHMENT_STACK_SIZE];
	struct parse_node *one_off_attachment_point;
	MEMORY_MANAGEMENT
} parse_node_tree;

parse_node_tree *ParseTree::new_tree(void) {
	parse_node_tree *T = CREATE(parse_node_tree);
	T->root_node = ParseTree::new(ROOT_NT);
	T->attachment_sp = 0;
	T->one_off_attachment_point = NULL;
	ParseTree::push_attachment_point(T, T->root_node);
	return T;
}

@ It turns out to be convenient to have a mechanism for inserting sentences,
the main large-scale structural nodes, into the tree. These come in a
stream in the source text, but can attach at different levels in the tree,
since each sentence needs to be a child of the relevant heading node
under which it falls. We therefore keep a stack of open headings:

=
int ParseTree::push_attachment_point(parse_node_tree *T, parse_node *to) {
	int l = T->attachment_sp;
	if (T->attachment_sp >= MAX_ATTACHMENT_STACK_SIZE) internal_error("attachment stack overflow");
	T->attachment_stack_parent[T->attachment_sp++] = to;
	return l;
}

void ParseTree::pop_attachment_point(parse_node_tree *T, int l) {
	T->attachment_sp = l;
}

@ In addition, we can temporarily override this system:

=
void ParseTree::set_attachment_point_one_off(parse_node_tree *T, parse_node *to) {
	T->one_off_attachment_point = to;
}

@h Structural vs specifications.
Each node has a "node type". About half of the node types are called
"structural", with the remainder being "specifications". Structural nodes
represent the large-scale structure of the source text: from headings down to
code points in routines. The shape of the above assertion sentence, for
example, is made up of structural nodes.

Specification nodes represent data rather than structure. For example, in

>> The tally is a number that varies. The tally is 124.

the value "124" is stored as a single specification node, of node type
|CONSTANT_NT|. But more elaborate possibilities exist:

>> tally is 124 and the player is in the Library

is stored as a tree of three specification nodes:

	|LOGICAL_AND_NT|
		|TEST_PROPOSITION_NT "tally is 124"|
		|TEST_PROPOSITION_NT "the player is in the Library"|

The tree is heavily annotated, so that nodes can carry more meaning than
just their type alone. For example, the |CONSTANT_NT| node for "124"
is annotated with the kind |K_number|, showing what kind of constant it
represents. The |TEST_PROPOSITION_NT| nodes are annotated with
logical propositions. There's a huge variety of different annotations
used in different contexts, most of them relevant only for certain node
types. Some of these point to structures which in turn point back to
the tree: for example, the proposition "tally is 124" is stored as
a |pcalc_prop| structure which indirectly contains the values "tally"
and "124", which are both represented as parse nodes.

@h Node types.
The basic meaning of a node is represented by its "node type". Though
they are only used fleetingly, and never remain in either the structural
tree or as stored values, every valid meaning code (i.e., every |*_MC|
constant) is also a valid node type. Since meaning codes are integers
with a single bit set, and we need up to 31 of them, we enumerate
node types as values with bit 32 set. That being so, node types have
to be stored unsigned, and for portability we define:

@d node_type_t unsigned int /* (not a typedef only because it makes trouble for inweb) */

@ We now run through the enumeration, in a sequence which must exactly match
that in the table of metadata below.

Structural node types are enumerated first:

@d BASE_OF_ENUMERATED_NTS    		0x80000000

@e INVALID_NT from 0x80000000    /* No node with this node type should ever exist */

@e ROOT_NT              			/* Only one such node exists: the tree root */
@e INCLUSION_NT         			/* Holds a block of source material */
@e HEADING_NT           			/* "Chapter VIII: Never Turn Your Back On A Shreve" */
@e INCLUDE_NT           			/* "Include School Rules by Argus Filch" */
@e BEGINHERE_NT         			/* "The Standard Rules begin here" */
@e ENDHERE_NT           			/* "The Standard Rules end here" */
@e SENTENCE_NT          			/* "The Garden is a room" */

@e AMBIGUITY_NT   		    	/* Marks an ambiguous set of readings in the tree */

@h The structure.
Finally, then, the data structure.

=
typedef struct parse_node {
	struct wording text_parsed; /* the text being interpreted by this node */

	node_type_t node_type; /* what the node basically represents */
	struct parse_node_annotation *annotations; /* linked list of miscellaneous annotations */

	struct parse_node *down; /* pointers within the current interpretation */
	struct parse_node *next;

	int score; /* used to choose most likely interpretation */
	struct parse_node *next_alternative; /* fork to alternative interpretation */

	int log_time; /* used purely as a defensive measure when writing debugging log */
	MEMORY_MANAGEMENT
} parse_node;

@h Where we currently are in the text.
Inform makes many traverses through the big parse tree, often modifying as it
goes, and keeps track of its position so that it can make any problem messages
correctly refer to the location of the faulty text in the original source
files.

During such traverses, |current_sentence| is always the subtree being looked
at: it is always a child of the tree root, and is usually a |SENTENCE_NT|
node, hence the name.

= (early code)
parse_node *current_sentence = NULL;

@ The parse tree annotations are miscellaneous, and many are needed only
at a few unusual nodes. Rather than have the structure grow large, we
store annotations in the following:

=
typedef struct parse_node_annotation {
	int kind_of_annotation;
	int annotation_integer;
	general_pointer annotation_pointer;
	struct parse_node_annotation *next_annotation;
} parse_node_annotation;

@

@e heading_level_ANNOT from 1 /* int: for HEADING nodes, a hierarchical level, 0 (highest) to 9 (lowest) */
@e language_element_ANNOT /* |int|: this node is not really a sentence, but a language definition Use */
@e sentence_unparsed_ANNOT /* int: set if verbs haven't been sought yet here */
@e suppress_heading_dependencies_ANNOT /* int: ignore extension dependencies on this heading node */
@e embodying_heading_ANNOT /* |heading|: for parse nodes of headings */
@e inclusion_of_extension_ANNOT /* |inform_extension|: for parse nodes of headings */
@e implied_heading_ANNOT /* int: set only for the heading of implied inclusions */

@d MAX_ANNOT_NUMBER (NO_DEFINED_ANNOT_VALUES+1)

@ Access routines will be needed for some of these, and the following
constructs them:

@d DECLARE_ANNOTATION_FUNCTIONS(annotation_name, pointer_type)
void ParseTree::set_##annotation_name(parse_node *pn, pointer_type *bp);
pointer_type *ParseTree::get_##annotation_name(parse_node *pn);

@h Node metadata.
With such a profusion of node types, we need a systematic way to organise
information about them.

The following structure is used only for a row in a table of what we
might call metadata about node types: information on where each node type
can appear, and what restrictions apply to its use. We also store textual
names for the node types here, as this is convenient for logging.

=
typedef struct parse_tree_node_type {
	node_type_t identity;
	char *node_type_name; /* text of name of type, such as |"INVOCATION_LIST_NT"| */
	int min_children; /* minimum legal number of child nodes */
	int max_children; /* maximum legal number of child nodes */
	int category; /* one of the |*_NCAT| values below */
	int node_flags; /* bitmap of node flags */
} parse_tree_node_type;

@ The categories are:

@e INVALID_NCAT from 0
@e L1_NCAT
@e L2_NCAT

@ The bitmap of node flags begins with:

@d DONT_VISIT_NFLAG     	0x00000001 /* not visited in traverses */
@d TABBED_CONTENT_NFLAG		0x00000002 /* contains tab-delimited lists */

@ Various modules conventionally use this global setting to toggle debugging
log output:

=
int trace_sentences = FALSE;

@h The metadata table.
Note that the sequence here must exactly match the enumeration above.

@d INFTY 1000000000 /* if ever a node has more than a billion children, we are in trouble anyway */

=
parse_tree_node_type parse_tree_node_types[NO_DEFINED_NT_VALUES];

void ParseTree::md(parse_tree_node_type ptnt) {
	if (ParseTree::valid_type(ptnt.identity) == FALSE) internal_error("set bad metadata");
	parse_tree_node_types[ptnt.identity - BASE_OF_ENUMERATED_NTS] = ptnt;
}

@ =
void ParseTree::metadata_setup(void) {
	ParseTree::md((parse_tree_node_type) { INVALID_NT, "(INVALID_NT)",		0, INFTY,	INVALID_NCAT, 0 });
	ParseTree::md((parse_tree_node_type) { ROOT_NT, "ROOT_NT",				0, INFTY,	L1_NCAT, DONT_VISIT_NFLAG });
	ParseTree::md((parse_tree_node_type) { INCLUSION_NT, "INCLUSION_NT",	0, INFTY,	L1_NCAT, DONT_VISIT_NFLAG });
	ParseTree::md((parse_tree_node_type) { HEADING_NT, "HEADING_NT",		0, INFTY,	L1_NCAT, 0 });
	ParseTree::md((parse_tree_node_type) { INCLUDE_NT, "INCLUDE_NT",		0, 0,		L2_NCAT, 0 });
	ParseTree::md((parse_tree_node_type) { BEGINHERE_NT, "BEGINHERE_NT",	0, 0,		L2_NCAT, 0 });
	ParseTree::md((parse_tree_node_type) { ENDHERE_NT, "ENDHERE_NT",		0, 0,		L2_NCAT, 0 });
	ParseTree::md((parse_tree_node_type) { SENTENCE_NT, "SENTENCE_NT",		0, INFTY,	L2_NCAT, 0 });
	ParseTree::md((parse_tree_node_type) { AMBIGUITY_NT, "AMBIGUITY_NT",	0, INFTY,	L1_NCAT, 0 });
	#ifdef UNKNOWN_NT
	ParseTree::md((parse_tree_node_type) { UNKNOWN_NT, "UNKNOWN_NT", 0, INFTY, L3_NCAT, 0 });
	#endif
	#ifdef PARSE_TREE_METADATA_SETUP
	PARSE_TREE_METADATA_SETUP();
	#endif
}

@ We can only retrieve metadata on enumerated node types, not on meaning
codes such as |RULE_MC|, for which the following will return |NULL|.

=
parse_tree_node_type *ParseTree::node_metadata(node_type_t t) {
	if ((t >= BASE_OF_ENUMERATED_NTS) && (t < BASE_OF_ENUMERATED_NTS+NO_DEFINED_NT_VALUES)) {
		parse_tree_node_type *metadata = &(parse_tree_node_types[t - BASE_OF_ENUMERATED_NTS]);
		if ((metadata == NULL) || (metadata->identity != t)) {
			WRITE_TO(STDERR, "unable to locate node type %08x\n", t);
			internal_error("node type metadata lookup incorrect");
		}
		return metadata;
	}
	return NULL;
}

@ =
int ParseTree::valid_type(node_type_t t) {
	if ((t >= BASE_OF_ENUMERATED_NTS) && (t < BASE_OF_ENUMERATED_NTS+NO_DEFINED_NT_VALUES)) return TRUE;
	return FALSE;
}

int ParseTree::cat(node_type_t t) {
	parse_tree_node_type *metadata = ParseTree::node_metadata(t);
	if (metadata) return metadata->category;
	return INVALID_NCAT;
}

int ParseTree::top_level(node_type_t t) {
	parse_tree_node_type *metadata = ParseTree::node_metadata(t);
	if ((metadata) && (metadata->category == L1_NCAT)) return TRUE;
	return FALSE;
}

int ParseTree::visitable(node_type_t t) {
	if (ParseTree::test_flag(t, DONT_VISIT_NFLAG)) return FALSE;
	return TRUE;
}

int ParseTree::test_flag(node_type_t t, int f) {
	parse_tree_node_type *metadata = ParseTree::node_metadata(t);
	if ((metadata) && ((metadata->node_flags) & f)) return TRUE;
	return FALSE;
}

@h Logging node types.
And also making node names available to the machinery for producing internal
errors when incorrect node types are encountered, though we hope this will
never be used.

=
void ParseTree::log_type(OUTPUT_STREAM, int it) {
	node_type_t t = (node_type_t) it;
	parse_tree_node_type *metadata = ParseTree::node_metadata(t);
	if (metadata) WRITE("%s", metadata->node_type_name);
	else {
	#ifdef CORE_MODULE
		UseExcerptMeanings::log_meaning_code(OUT, t);
	#else
		WRITE("?%08x_NT", t);
	#endif
	}
}

char *ParseTree::get_type_name(node_type_t t) {
	parse_tree_node_type *metadata = ParseTree::node_metadata(t);
	if (metadata == NULL) return "?";
	return metadata->node_type_name;
}

@h Creation.

=
parse_node *ParseTree::new(node_type_t t) {
	parse_node *pn = CREATE(parse_node);
	pn->node_type = t;
	ParseTree::set_text(pn, EMPTY_WORDING);
	pn->annotations = NULL;
	pn->down = NULL; pn->next = NULL; pn->next_alternative = NULL;
	pn->log_time = 0;
	ParseTree::set_score(pn, 0);
	return pn;
}

@ The following constructor routines fill out the fields in useful ways.
Here's one if a word range is to be attached:

=
parse_node *ParseTree::new_with_words(node_type_t code_number, wording W) {
	parse_node *pn = ParseTree::new(code_number);
	ParseTree::set_text(pn, W);
	return pn;
}

@ The attached text.

=
wording ParseTree::get_text(parse_node *pn) {
	if (pn == NULL) return EMPTY_WORDING;
	return pn->text_parsed;
}

void ParseTree::set_text(parse_node *pn, wording W) {
	if (pn == NULL) internal_error("tried to set words for null node");
	pn->text_parsed = W;
}

@h Annotations.
It's easily overlooked that the single most useful piece of information
at each node is its node type, accessed as follows:

=
node_type_t ParseTree::get_type(parse_node *pn) {
	if (pn == NULL) return INVALID_NT;
	return pn->node_type;
}
int ParseTree::is(parse_node *pn, node_type_t t) {
	if ((pn) && (pn->node_type == t)) return TRUE;
	return FALSE;
}

@ When setting, we have to preserve the invariant, so we clear away any
annotations no longer relevant to the node's new identity.

=
void ParseTree::set_type(parse_node *pn, node_type_t nt) {
	#ifdef IMMUTABLE_NODE
	node_type_t from = pn->node_type;
	if (IMMUTABLE_NODE(from)) {
		LOG("$P changed to $N\n", pn, nt);
		internal_error("immutable type changed");
	}
	#endif

	pn->node_type = nt;
	while ((pn->annotations) &&
		(!(ParseTree::annotation_allowed(nt, pn->annotations->kind_of_annotation))))
		pn->annotations = pn->annotations->next_annotation;
	for (parse_node_annotation *pna = pn->annotations; pna; pna = pna->next_annotation)
		if ((pna->next_annotation) &&
		(!(ParseTree::annotation_allowed(nt, pna->next_annotation->kind_of_annotation))))
		pna->next_annotation = pna->next_annotation->next_annotation;
}
void ParseTree::set_type_and_clear_annotations(parse_node *pn, node_type_t nt) {
	pn->node_type = nt; pn->annotations = NULL;
}

@ The integer score, used in choosing best matches:

=
int ParseTree::get_score(parse_node *pn) { return pn->score; }
void ParseTree::set_score(parse_node *pn, int s) { pn->score = s; }

@ Beyond that, we have to attach something. A blank annotation is like a
blank luggage ticket, waiting to be filled out and attached to some suitcase:

=
parse_node_annotation *ParseTree::pna_new(int koa) {
	parse_node_annotation *pna = CREATE(parse_node_annotation);
	pna->kind_of_annotation = koa;
	pna->annotation_integer = 0;
	pna->annotation_pointer = NULL_GENERAL_POINTER;
	pna->next_annotation = NULL;
	return pna;
}

@ Annotations are identified by an enumerated range of constants (KOA here
stands for "kind of annotation"). Each node is permitted an arbitrary
selection of these, storing them as a linked list: it will always be short
(worst case about 5), so there is no need for a more efficient algorithm
to search this list.

=
int ParseTree::has_annotation(parse_node *PN, int koa) {
	parse_node_annotation *pna;
	if (PN)
		for (pna=PN->annotations; pna; pna=pna->next_annotation)
			if (pna->kind_of_annotation == koa)
				return TRUE;
	return FALSE;
}

@ Reading annotations is similar. We need two variant forms: one for reading
integer-valued annotations (which is most of them, as it happens) and the
other for reading pointers to structures.

=
int ParseTree::int_annotation(parse_node *PN, int koa) {
	parse_node_annotation *pna;
	if (PN)
		for (pna=PN->annotations; pna; pna=pna->next_annotation)
			if (pna->kind_of_annotation == koa)
				return pna->annotation_integer;
	return 0;
}

general_pointer ParseTree::pn_pointer_annotation(parse_node *PN, int koa) {
	parse_node_annotation *pna;
	if (PN)
		for (pna=PN->annotations; pna; pna=pna->next_annotation)
			if (pna->kind_of_annotation == koa)
				return pna->annotation_pointer;
	return NULL_GENERAL_POINTER;
}

@ Integer-valued annotations are set with the following routine. Note that
any second or subsequent annotation with the same KOA as an existing one
overwrites it.

=
void ParseTree::annotate_int(parse_node *PN, int koa, int v) {
	parse_node_annotation *newpna, *pna, *final = NULL;
	if (PN == NULL) internal_error("annotated null PN");
	for (pna=PN->annotations; pna; pna=pna->next_annotation) {
		if (pna->kind_of_annotation == koa) {
			/* an annotation with this KOA exists already: overwrite it */
			pna->annotation_integer = v;
			return;
		}
		if (pna->next_annotation == NULL) final = pna;
	}
	/* no annotation with this KOA exists: create a new one and add to end of node's list */
	newpna = ParseTree::pna_new(koa); newpna->annotation_integer = v;
	if (final) final->next_annotation = newpna; else PN->annotations = newpna;
}

@ Again, almost identical code handles the case of pointer-valued annotations:

=
void ParseTree::pn_annotate_pointer(parse_node *PN, int koa, general_pointer data) {
	if (PN == NULL) internal_error("annotated null PN");
	parse_node_annotation *newpna, *pna, *final = NULL;
	for (pna=PN->annotations; pna; pna=pna->next_annotation) {
		if (pna->kind_of_annotation == koa) {
			/* an annotation with this KOA exists already: overwrite it */
			pna->annotation_pointer = data;
			return;
		}
		if (pna->next_annotation == NULL) final = pna;
	}
	/* no annotation with this KOA exists: create a new one and add to end of node's list */
	newpna = ParseTree::pna_new(koa); newpna->annotation_pointer = data;
	if (final) final->next_annotation = newpna; else PN->annotations = newpna;
}

@ It turns out to be convenient to access annotations with standard-form
get and set functions, for pointers, to avoid difficulties with null
pointers (which would throw run-time errors as being invalid if the store
and retrieve routines were allowed to work on them). It's also less verbose.

@d MAKE_ANNOTATION_FUNCTIONS(annotation_name, pointer_type)
void ParseTree::set_##annotation_name(parse_node *pn, pointer_type *bp) {
	ParseTree::pn_annotate_pointer(pn, annotation_name##_ANNOT,
		STORE_POINTER_##pointer_type(bp));
}
pointer_type *ParseTree::get_##annotation_name(parse_node *pn) {
	pointer_type *pt = NULL;
	if (ParseTree::has_annotation(pn, annotation_name##_ANNOT))
		pt = RETRIEVE_POINTER_##pointer_type(
			ParseTree::pn_pointer_annotation(pn, annotation_name##_ANNOT));
	return pt;
}

@h Copying parse nodes.
If we want to duplicate a parse node, we cannot do so with a shallow bit copy:
the node points to a list of its annotations, and the duplicated node would
therefore point to the same list. If, subsequently, one of the two nodes
were annotated further, then the other would change in synchrony, which
would be the source of mysterious bugs. We therefore need to perform a
deep copy which duplicates not only the node, but also its annotation list.

=
void ParseTree::copy(parse_node *to, parse_node *from) {
	COPY(to, from, parse_node);
	to->annotations = NULL;
	parse_node_annotation *pna, *latest = NULL;
	for (pna=from->annotations; pna; pna=pna->next_annotation) {
		parse_node_annotation *pna_copy = CREATE(parse_node_annotation);
		*pna_copy = *pna;
		#ifdef PARSE_TREE_COPIER
		PARSE_TREE_COPIER(pna_copy, pna);
		#endif
		pna_copy->next_annotation = NULL;
		if (to->annotations == NULL) to->annotations = pna_copy;
		else latest->next_annotation = pna_copy;
		latest = pna_copy;
	}
}

parse_node *ParseTree::duplicate(parse_node *p) {
	parse_node *dup = ParseTree::new(INVALID_NT);
	ParseTree::copy(dup, p);
	return dup;
}

@ This variation preserves links out.

=
void ParseTree::copy_in_place(parse_node *to, parse_node *from) {
	parse_node *next_link = to->next;
	parse_node *alt_link = to->next_alternative;
	parse_node *down_link = to->down;
	ParseTree::copy(to, from);
	to->next = next_link;
	to->next_alternative = alt_link;
	to->down = down_link;
}

@ And to deep-copy a whole subtree:

=
void ParseTree::copy_subtree(parse_node *from, parse_node *to, int level) {
	if ((from == NULL) || (to == NULL)) internal_error("Null deep copy");
	ParseTree::copy(to, from);
	if (from->down) {
		to->down = ParseTree::new(INVALID_NT);
		ParseTree::copy_subtree(from->down, to->down, level+1);
	}
	if ((level>0) && (from->next)) {
		to->next = ParseTree::new(INVALID_NT);
		ParseTree::copy_subtree(from->next, to->next, level);
	}
	if ((level>0) && (from->next_alternative)) {
		to->next_alternative = ParseTree::new(INVALID_NT);
		ParseTree::copy_subtree(from->next_alternative, to->next_alternative, level);
	}
}

@h Child count.

=
int ParseTree::no_children(parse_node *pn) {
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
int ParseTree::contains(parse_node *PN, parse_node *to_find) {
	parse_node *to_try;
	if (PN == to_find) return TRUE;
	for (to_try = PN->down; to_try; to_try = to_try->next)
		if (ParseTree::contains(to_try, to_find))
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
int ParseTree::left_edge_of(parse_node *PN) {
	parse_node *child;
	int l = Wordings::first_wn(ParseTree::get_text(PN)), lc;
	for (child = PN->down; child; child = child->next) {
		lc = ParseTree::left_edge_of(child);
		if ((lc >= 0) && ((l == -1) || (lc < l))) l = lc;
	}
	return l;
}

@ Symmetrically, the right edge is found by taking the maximum word number
for |PN| and the right edges of its children.

=
int ParseTree::right_edge_of(parse_node *PN) {
	parse_node *child;
	int r = Wordings::last_wn(ParseTree::get_text(PN)), rc;
	if (Wordings::first_wn(ParseTree::get_text(PN)) < 0) r = -1;
	for (child = PN->down; child; child = child->next) {
		rc = ParseTree::right_edge_of(child);
		if ((rc >= 0) && ((r == -1) || (rc > r))) r = rc;
	}
	return r;
}

@ Every node in the tree is indirectly a child of the root node. Such trees
tends to be very wide: since each sentence in the original source text is a 
different child of the root, the root may have 5000 or so children, though
the maximum depth of the tree might be only 10.

That means that perpetually scanning through them in order to add another one
on the end is inefficient: so we cache the "last sentence" in the tree,
meaning, the youngest child of root. (But we must only do this when we are not
also performing surgery on the tree at the same time, which is why it is not
always allowed.)

=
parse_node *youngest_child_of_root = NULL; /* youngest child of tree root */
int allow_last_sentence_cacheing = FALSE;

void ParseTree::enable_last_sentence_cacheing(void) {
	youngest_child_of_root = NULL; /* because this may have changed since last enabled */
	allow_last_sentence_cacheing = TRUE;
}

void ParseTree::disable_last_sentence_cacheing(void) {
	allow_last_sentence_cacheing = FALSE;
}

@ Now the metaphors get mixed. The routine below is called |ParseTree::graft|
by analogy with gardening, where the rootstock of one plant is joined to a
scion (or cutting) of another, so that a root chosen for strength can be
combined with the fruits or blossom of the scion. This is fairly apt for
the process of joining one subtree onto a node of another. But since
gardening lacks words to describe branches as being eldest or youngest,
and so on, for the actual body of the routine we talk about family trees
instead.

|ParseTree::graft| returns the node for which |newborn| is the immediate sibling,
that is, it returns the previously youngest child of the |parent| (or |NULL|
if it previously had no children).

=
parse_node *ParseTree::graft(parse_node_tree *T, parse_node *newborn, parse_node *parent) {
	parse_node *elder = NULL;
	if (newborn == NULL) internal_error("newborn is null in tree ParseTree::graft");
	if (parent == NULL) internal_error("parent is null in tree ParseTree::graft");
	/* is the new node to be the only child of the old? */
	if (parent->down == NULL) { parent->down = newborn; return NULL; }
	/* can last sentence cacheing save us a long search through many children of root? */
	if ((parent == T->root_node) && (allow_last_sentence_cacheing)) {
		if (youngest_child_of_root) {
			elder = youngest_child_of_root;
			elder->next = newborn;
			youngest_child_of_root = newborn;
			return elder;
		}
		/* we don't know who's the youngest child now, but we know who soon will be: */
		youngest_child_of_root = newborn;
	}
	/* find youngest child of attach node... */
	for (elder = parent->down; elder->next; elder = elder->next) ;
	/* ...and make the new node its younger sibling */
	elder->next = newborn; return elder;
}

@ No speed worries on the much smaller trees with alternative readings:

=
parse_node *ParseTree::graft_alternative(parse_node *newborn, parse_node *parent) {
	if (newborn == NULL) internal_error("newborn is null in tree ParseTree::graft_alternative");
	if (parent == NULL) internal_error("parent is null in tree ParseTree::graft_alternative");
	/* is the new node to be the only child of the old? */
	if (parent->down == NULL) { parent->down = newborn; return NULL; }
	/* find youngest child of attach node... */
	parse_node *elder = NULL;
	for (elder = parent->down; elder->next_alternative; elder = elder->next_alternative) ;
	/* ...and make the new node its younger sibling */
	elder->next_alternative = newborn; return elder;
}

@ And we can loop through these like so:

@d LOOP_THROUGH_ALTERNATIVES(p, from)
	for (p = from; p; p = p->next_alternative)

@ Sentences are attached as so: at the one-off point if set, or at the
relevant stacked position.

=
void ParseTree::insert_sentence(parse_node_tree *T, parse_node *new) {
	if (T->one_off_attachment_point) {
		parse_node *L = T->one_off_attachment_point->next;
		T->one_off_attachment_point->next = new;
		new->next = L;
		T->one_off_attachment_point = new;
	} else {
		if (T->attachment_sp == 0) internal_error("no attachment point");
		if (ParseTree::get_type(new) == HEADING_NT) @<Adjust attachment point for a heading@>;
		parse_node *sentence_attachment_point = T->attachment_stack_parent[T->attachment_sp-1];
		ParseTree::graft(T, new, sentence_attachment_point);
		if (ParseTree::get_type(new) == HEADING_NT) ParseTree::push_attachment_point(T, new);
	}
}

@ When what's attached is a heading node, that changes the stack, of course:

@<Adjust attachment point for a heading@> =
	int heading_level = ParseTree::int_annotation(new, heading_level_ANNOT);
	if (heading_level > 0)
		for (int i = T->attachment_sp-1; i>=0; i--) {
			parse_node *P = T->attachment_stack_parent[i];
			if ((ParseTree::get_type(P) == HEADING_NT) &&
				(ParseTree::int_annotation(P, heading_level_ANNOT) >= heading_level))
				T->attachment_sp = i;
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
int pn_log_token = 0;

void ParseTree::log_tree(OUTPUT_STREAM, void *vpn) {
	parse_node *pn = (parse_node *) vpn;
	if (pn == NULL) { WRITE("<null-meaning-list>\n"); return; }
	ParseTree::log_subtree_recursively(OUT, pn, 0, 0, 1, ++pn_log_token);
}

void ParseTree::log_subtree(OUTPUT_STREAM, void *vpn) {
	parse_node *pn = (parse_node *) vpn;
	if (pn == NULL) { WRITE("<null-parse-node>"); return; }
	WRITE("$P\n", pn);
	if (pn->down) {
		LOG_INDENT;
		ParseTree::log_subtree_recursively(OUT, pn->down, 0, 0, 1, ++pn_log_token);
		LOG_OUTDENT;
	}
}

@ Either way, we recurse as follows, being careful not to make recursive calls
to pursue |next| links, since otherwise a source text with more than 100,000
sentences or so will exceed the typical stack size Inform has to run in.

=
void ParseTree::log_subtree_recursively(OUTPUT_STREAM, parse_node *pn, int num, int of, int gen, int ltime) {
	while (pn) {
		if (pn->log_time == ltime) {
			WRITE("*** Not a tree: %W ***\n", ParseTree::get_text(pn)); return;
		}
		pn->log_time = ltime;
		@<Calculate num and of such that this is [num/of] if they aren't already supplied@>;

		if (pn == NULL) { WRITE("<null-parse-node>\n"); return; }
		if (of > 1) {
			WRITE("[%d/%d] ", num, of);
			if (ParseTree::get_score(pn) != 0) WRITE("(score %d) ", ParseTree::get_score(pn));
		}
		WRITE("$P\n", pn);
		if (pn->down) {
			LOG_INDENT;
			ParseTree::log_subtree_recursively(OUT, pn->down, 0, 0, gen+1, ltime);
			LOG_OUTDENT;
		}
		if (pn->next_alternative) ParseTree::log_subtree_recursively(OUT, pn->next_alternative, num+1, of, gen+1, ltime);

		pn = pn->next; num = 0; of = 0; gen++;
	}
}

@ When the first alternative is called, |ParseTree::log_subtree_recursively|
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
void ParseTree::log_node(OUTPUT_STREAM, void *vpn) {
	parse_node *pn = (parse_node *) vpn;
	if (pn == NULL) { WRITE("<null-parse-node>\n"); return; }
	#ifdef PARSE_TREE_LOGGER
	PARSE_TREE_LOGGER(OUT, pn);
	#else
	ParseTree::log_type(OUT, (int) pn->node_type);
	if (Wordings::nonempty(ParseTree::get_text(pn))) WRITE("'%W'", ParseTree::get_text(pn));
	#ifdef LINGUISTICS_MODULE
	Diagrams::log_node(OUT, pn);
	#endif
	switch(pn->node_type) {
		case HEADING_NT: WRITE(" (level %d)", ParseTree::int_annotation(pn, heading_level_ANNOT)); break;
	}
	#endif
	int a = 0;
	while ((pn->next_alternative) && (a<9)) a++, pn = pn->next_alternative;
	if (a > 0) WRITE("/%d", a);
}

@ This is occasionally useful:

=
void ParseTree::log_with_annotations(parse_node *pn) {
	LOG("Diagnosis $P", pn);
	for (parse_node_annotation *pna = pn->annotations; pna; pna = pna->next_annotation)
		LOG("-%d", pna->kind_of_annotation);
	LOG("\n");
}

@ Inform also has a mechanism for dumping the entire parse tree to a file,
really just for testing purposes:

=
void ParseTree::write_to_file(parse_node_tree *T, filename *F) {
	text_stream parse_tree_file;
	if (STREAM_OPEN_TO_FILE(&parse_tree_file, F, ISO_ENC) == FALSE)
		internal_error("can't open file to write parse tree");

	text_stream *save_DL = DL;
	DL = &parse_tree_file;
	Streams::enable_debugging(DL);
	ParseTree::log_tree(DL, T->root_node);
	DL = save_DL;

	STREAM_CLOSE(&parse_tree_file);
}

@h General traversals.
It's convenient to have a general system for traversing the tree, visiting
each node in the connected component of the tree root. Unlike the logging
routine above, these all assume that the tree is well-formed.

=
void ParseTree::traverse(parse_node_tree *T, void (*visitor)(parse_node *)) {
	ParseTree::traverse_from(T->root_node, visitor);
}
void ParseTree::traverse_from(parse_node *pn, void (*visitor)(parse_node *)) {
	parse_node *SCS = current_sentence;
	for (; pn; pn = pn->next) {
		if (ParseTree::top_level(pn->node_type)) ParseTree::traverse_from(pn->down, visitor);
		if (ParseTree::visitable(pn->node_type)) {
			if (ParseTree::sentence_node(pn->node_type)) current_sentence = pn;
			(*visitor)(pn);
		}
	}
	current_sentence = SCS;
}
void ParseTree::traverse_dfirst(parse_node_tree *T, void (*visitor)(parse_node *)) {
	ParseTree::traverse_dfirst_from(T->root_node, visitor);
}
void ParseTree::traverse_dfirst_from(parse_node *pn, void (*visitor)(parse_node *)) {
	parse_node *SCS = current_sentence;
	for (; pn; pn = pn->next) {
		ParseTree::traverse_dfirst_from(pn->down, visitor);
		if (ParseTree::sentence_node(pn->node_type)) current_sentence = pn;
		(*visitor)(pn);
	}
	current_sentence = SCS;
}
void ParseTree::traverse_wfirst(parse_node_tree *T, void (*visitor)(parse_node *)) {
	ParseTree::traverse_wfirst_from(T->root_node, visitor);
}
void ParseTree::traverse_wfirst_from(parse_node *pn, void (*visitor)(parse_node *)) {
	parse_node *SCS = current_sentence;
	for (; pn; pn = pn->next) {
		if (ParseTree::sentence_node(pn->node_type)) current_sentence = pn;
		ParseTree::traverse_wfirst_from(pn->down, visitor);
		(*visitor)(pn);
	}
	current_sentence = SCS;
}
void ParseTree::traverse_with_stream(parse_node_tree *T, text_stream *OUT, void (*visitor)(text_stream *, parse_node *)) {
	ParseTree::traverse_from_with_stream(OUT, T->root_node, visitor);
}
void ParseTree::traverse_from_with_stream(text_stream *OUT, parse_node *pn, void (*visitor)(text_stream *, parse_node *)) {
	parse_node *SCS = current_sentence;
	for (; pn; pn = pn->next) {
		if (ParseTree::top_level(pn->node_type))
			ParseTree::traverse_from_with_stream(OUT, pn->down, visitor);
		if (ParseTree::visitable(pn->node_type)) {
			if (ParseTree::sentence_node(pn->node_type)) current_sentence = pn;
			(*visitor)(OUT, pn);
		}
	}
	current_sentence = SCS;
}
void ParseTree::traverse_int(parse_node_tree *T, void (*visitor)(parse_node *, int *), int *X) {
	ParseTree::traverse_from_int(T->root_node, visitor, X);
}
void ParseTree::traverse_from_int(parse_node *pn, void (*visitor)(parse_node *, int *), int *X) {
	parse_node *SCS = current_sentence;
	for (; pn; pn = pn->next) {
		if (ParseTree::top_level(pn->node_type)) ParseTree::traverse_from_int(pn->down, visitor, X);
		if (ParseTree::visitable(pn->node_type)) {
			if (ParseTree::sentence_node(pn->node_type)) current_sentence = pn;
			(*visitor)(pn, X);
		}
	}
	current_sentence = SCS;
}
void ParseTree::traverse_int_int(parse_node_tree *T, void (*visitor)(parse_node *, int *, int *), int *X, int *Y) {
	ParseTree::traverse_from_int_int(T->root_node, visitor, X, Y);
}
void ParseTree::traverse_from_int_int(parse_node *pn, void (*visitor)(parse_node *, int *, int *), int *X, int *Y) {
	parse_node *SCS = current_sentence;
	for (; pn; pn = pn->next) {
		if (ParseTree::top_level(pn->node_type)) ParseTree::traverse_from_int_int(pn->down, visitor, X, Y);
		if (ParseTree::visitable(pn->node_type)) {
			if (ParseTree::sentence_node(pn->node_type)) current_sentence = pn;
			(*visitor)(pn, X, Y);
		}
	}
	current_sentence = SCS;
}
void ParseTree::traverse_ppn(parse_node_tree *T, void (*visitor)(parse_node *, parse_node **), parse_node **X) {
	ParseTree::traverse_from_ppn(T->root_node, visitor, X);
}
void ParseTree::traverse_from_ppn(parse_node *pn, void (*visitor)(parse_node *, parse_node **), parse_node **X) {
	parse_node *SCS = current_sentence;
	for (; pn; pn = pn->next) {
		if (ParseTree::top_level(pn->node_type)) ParseTree::traverse_from_ppn(pn->down, visitor, X);
		if (ParseTree::visitable(pn->node_type)) {
			if (ParseTree::sentence_node(pn->node_type)) current_sentence = pn;
			(*visitor)(pn, X);
		}
	}
	current_sentence = SCS;
}
void ParseTree::traverse_ppni(parse_node_tree *T, void (*visitor)(parse_node_tree *, parse_node *, parse_node *, int *), int *N) {
	ParseTree::traverse_from_ppni(T, T->root_node, visitor, NULL, N);
}
void ParseTree::traverse_from_ppni(parse_node_tree *T, parse_node *pn, void (*visitor)(parse_node_tree *, parse_node *, parse_node *, int *), parse_node *last_h0, int *N) {
	parse_node *SCS = current_sentence;
	for (; pn; pn = pn->next) {
		if (ParseTree::top_level(pn->node_type)) {
			parse_node *H0 = last_h0;
			if ((ParseTree::is(pn, HEADING_NT)) && (ParseTree::int_annotation(pn, heading_level_ANNOT) == 0))
				H0 = pn;
			ParseTree::traverse_from_ppni(T, pn->down, visitor, H0, N);
		}
		if (ParseTree::visitable(pn->node_type)) {
			if (ParseTree::sentence_node(pn->node_type)) current_sentence = pn;
			(*visitor)(T, pn, last_h0, N);
		}
	}
	current_sentence = SCS;
}
void ParseTree::traverse_up_to_ip(parse_node_tree *T, parse_node *end, void (*visitor)(parse_node *, PARSE_TREE_TRAVERSE_TYPE **), PARSE_TREE_TRAVERSE_TYPE **X) {
	ParseTree::traverse_from_up_to_ip(end, T->root_node, visitor, X);
}
int ParseTree::traverse_from_up_to_ip(parse_node *end, parse_node *pn, void (*visitor)(parse_node *, PARSE_TREE_TRAVERSE_TYPE **), PARSE_TREE_TRAVERSE_TYPE **X) {
	parse_node *SCS = current_sentence;
	for (; pn; pn = pn->next) {
		if (pn == end) { current_sentence = SCS; return TRUE; }
		if (ParseTree::top_level(pn->node_type)) {
			if (ParseTree::traverse_from_up_to_ip(end, pn->down, visitor, X)) {
				current_sentence = SCS; return TRUE;
			}
		}
		if (ParseTree::visitable(pn->node_type)) {
			if (ParseTree::sentence_node(pn->node_type)) current_sentence = pn;
			(*visitor)(pn, X);
		}
	}
	current_sentence = SCS;
	return FALSE;
}
int ParseTree::traverse_ppn_nocs(parse_node_tree *T, int (*visitor)(parse_node *, parse_node *, parse_node **), parse_node **X) {
	return ParseTree::traverse_from_ppn_nocs(T->root_node, visitor, NULL, X);
}
int ParseTree::traverse_from_ppn_nocs(parse_node *pn, int (*visitor)(parse_node *, parse_node *, parse_node **), parse_node *from, parse_node **X) {
	for (; pn; pn = pn->next) {
		if (ParseTree::visitable(pn->node_type)) {
			if ((*visitor)(pn, from, X)) { return TRUE; }
		}
		if (ParseTree::top_level(pn->node_type)) {
			int res = ParseTree::traverse_from_ppn_nocs(pn->down, visitor, pn, X);

			if (res) {
				return TRUE;
			}
		}
	}
	return FALSE;
}

@ This provides a way for users of the module to indicate what's a sentence:

=
int ParseTree::sentence_node(node_type_t t) {
	#ifdef SENTENCE_NODE
	return SENTENCE_NODE(t);
	#endif
	#ifndef SENTENCE_NODE
	return FALSE;
	#endif
}

@h Verify integrity.
The first duty of a tree is to contain no loops, and the following checks
that (rejecting even undirected loops). In addition, it checks that each
node has an enumerated node type, rather than a meaning code.

=
int tree_stats_size = 0, tree_stats_depth = 0, tree_stats_width = 0;

void ParseTree::verify_integrity(parse_node *p, int worth_logging) {
	tree_stats_size = 0; tree_stats_depth = 0; tree_stats_width = 1;
	ParseTree::verify_tree_integrity_recursively(p->down, p, "down", 0, ++pn_log_token);
	if (worth_logging)
		LOGIF(VERIFICATIONS, "[Initial parse tree has %d nodes, width %d and depth %d.]\n",
			tree_stats_size, tree_stats_width, tree_stats_depth);
}

@ The verification traverse is a very cautious manoeuvre: we step through
the tree, testing each branch with our outstretched foot in case it might
be illusory or broken. At the first sign of trouble we panic.

=
void ParseTree::verify_tree_integrity_recursively(parse_node *p,
	parse_node *from, char *way, int depth, int ltime) {
	int width;
	pointer_sized_int probably_an_address = (pointer_sized_int) p;
	depth++; if (depth > tree_stats_depth) tree_stats_depth = depth;
	for (width = 0; p; p = p->next, width++) {
		if ((probably_an_address == 0) || (probably_an_address == -1)) {
			LOG("Link %s broken from:\n$P", way, from);
			Errors::set_internal_handler(NULL);
			internal_error("Link broken in parse tree");
		}
		if (p->log_time == ltime) {
			LOG("Cycle found in parse tree, found %s from:\n$P", way, from);
			Errors::set_internal_handler(NULL);
			internal_error("Cycle found in parse tree");
		}
		p->log_time = ltime;
		node_type_t t = ParseTree::get_type(p);
		if (ParseTree::valid_type(t)) tree_stats_size++;
		else {
			LOG("Invalid node type (%08x) found %s from:\n$P", (int) t, way, from);
			Errors::set_internal_handler(NULL);
			internal_error("Link broken in parse tree");
		}
		if (p->next_alternative)
			ParseTree::verify_tree_integrity_recursively(p->next_alternative, p, "alt", depth, ltime);
		if (p->down)
			ParseTree::verify_tree_integrity_recursively(p->down, p, "down", depth, ltime);
	}
	if (width > tree_stats_width) tree_stats_width = width;
}

@h Verify structure.
The parse tree is a complicated structure, arbitrarily wide and deep, and
containing many different node types, each subject to its own rules of usage.
(For instance, a |SENTENCE_NT| node cannot legally be beneath a
|PROPER_NOUN_NT| one.) This is both good and bad: bad because complexity is
always the enemy of program correctness, good because it gives us an
independent opportunity to test a great deal of what earlier code has done.
If, given every test case, we always construct a well-formed tree, we must be
doing something right.

The collection of rules like this which the tree must satisfy is called its
"invariant", and is expressed by the code below. Note that this is
verification, not an attempt to correct matters. If any test fails, Inform
will stop with an internal error. (If there are multiple failures, we
itemise them to the debugging log, and only produce a single internal error
at the end.)

We protect ourselves by first checking that the tree is intact as a
structure: once we know the tree is safe to climb over, we can wander
about counting children with impunity.

=
void ParseTree::verify(parse_node_tree *T) {
	LOGIF(VERIFICATIONS, "[Verifying initial parse tree]\n");
	if (T->root_node == NULL) {
		Errors::set_internal_handler(NULL);
		internal_error("Root of parse tree NULL");
	}
	ParseTree::verify_structure(T->root_node);
	LOGIF(VERIFICATIONS, "[Initial parse tree correct.]\n");
}

int node_errors = 0;
void ParseTree::verify_structure(parse_node *p) {
	ParseTree::verify_integrity(p, FALSE);
	ParseTree::make_parentage_allowed_table();
	ParseTree::make_annotation_allowed_table();
	node_errors = 0;
	ParseTree::verify_structure_recursively(p, NULL);
	if (node_errors > 0) {
		LOG("[Verification failed: %d node errors]\n", node_errors);
		Errors::set_internal_handler(NULL);
		internal_error("Parse tree broken");
	}
}

@ Note that on every call to the following routine, (i) |p| is a valid
parse node and (ii) either |p| is the tree root, in which case |parent| is
|NULL|, or |parent| is the unique node having |p| (or an alternative to |p|)
among its children.

=
void ParseTree::verify_structure_recursively(parse_node *p, parse_node *parent) {
	node_type_t t = ParseTree::get_type(p);
	parse_tree_node_type *metadata = ParseTree::node_metadata(t);
	if (metadata == NULL) internal_error("broken tree should have been reported");

	@<Check rule (1) of the invariant@>;
	@<Check rule (2) of the invariant@>;
	if (parent) @<Check rule (3) of the invariant@>;

	int children_count = 0;
	for (parse_node *q=p->down; q; q=q->next, children_count++)
		ParseTree::verify_structure_recursively(q, p);

	@<Check rule (4) of the invariant@>;

	if (p->next_alternative)
		ParseTree::verify_structure_recursively(p->next_alternative, parent);
}

@ Rule (1): no INVALID nodes.

@<Check rule (1) of the invariant@> =
	if (t == INVALID_NT) {
		LOG("N%d is $N, which is not allowed except temporarily\n", p->allocation_id, t);
		@<Log this invariant failure@>
	}

@ Rule (2): all annotations must be legal for the given node type.

@<Check rule (2) of the invariant@> =
	for (parse_node_annotation *pna=p->annotations; pna; pna=pna->next_annotation)
		if (!(ParseTree::annotation_allowed(t, pna->kind_of_annotation))) {
			LOG("N%d is $N, which is not allowed to have annotation %d\n",
				p->allocation_id, t, pna->kind_of_annotation, p);
			LOG("Node %08x, ann %d\n", t, pna->kind_of_annotation);
			@<Log this invariant failure@>
		}

@ Rule (3): can this combination of parent and child exist?

@<Check rule (3) of the invariant@> =
	node_type_t t_parent = ParseTree::get_type(parent);
	int child_category = metadata->category;
	parse_tree_node_type *metadata_parent = ParseTree::node_metadata(t_parent);
	if (metadata_parent == NULL) internal_error("broken tree should have been reported");
	int parent_category = metadata_parent->category;

	if (!(ParseTree::parentage_allowed(t_parent, parent_category, t, child_category))) {
		LOG("N%d is $N (category %d): should not be a child of $N (category %d)\n",
			p->allocation_id, t, child_category, t_parent, parent_category);
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

@<Log this invariant failure@> =
	if (ParseTree::is(parent, ROOT_NT)) LOG("Failing subtree:\n$T", p);
	else LOG("Failing subtree:\n$T", parent);
	node_errors++;

@h Parentage rules.
It's mostly the case that node category determines whether one node can be
parent to another:

=
int parentage_allowed_set_up = FALSE;
int parentage_allowed[NO_DEFINED_NCAT_VALUES][NO_DEFINED_NCAT_VALUES];

void ParseTree::make_parentage_allowed_table(void) {
	if (parentage_allowed_set_up == FALSE) {
		parentage_allowed_set_up = TRUE;
		for (int i = 0; i < NO_DEFINED_NCAT_VALUES; i++)
			for (int j = 0; j < NO_DEFINED_NCAT_VALUES; j++)
				parentage_allowed[i][j] = FALSE;
		parentage_allowed[L1_NCAT][L1_NCAT] = TRUE;
	}
}

@ But there are exceptions. Note that an |L2_NCAT| node can have no parent
at all, according to the broad rules above: in fact, it can, but only if
the parent is |HEADING_NT|.

=
int ParseTree::parentage_allowed(node_type_t t_parent, int cat_parent,
	node_type_t t_child, int cat_child) {

	if (parentage_allowed[cat_parent][cat_child]) return TRUE;

	#ifdef PARENTAGE_EXCEPTIONS
	if (PARENTAGE_EXCEPTIONS(t_parent, cat_parent, t_child, cat_child)) return TRUE;
	#endif

	if ((t_parent == AMBIGUITY_NT) || (t_child == AMBIGUITY_NT)) return TRUE;

	return FALSE;
}

@h Annotation rules.
This is on an altogether grander scale.

@d LOOP_OVER_NODE_TYPES(t)
	for (node_type_t t=BASE_OF_ENUMERATED_NTS; t<BASE_OF_ENUMERATED_NTS+NO_DEFINED_NT_VALUES; t++)

=
int annotation_allowed_set_up = FALSE;
int annotation_allowed[NO_DEFINED_NT_VALUES][MAX_ANNOT_NUMBER+1];

void ParseTree::allow_annotation(node_type_t t, int annot) {
	annotation_allowed[t - BASE_OF_ENUMERATED_NTS][annot] = TRUE;
}
void ParseTree::allow_annotation_to_category(int cat, int annot) {
	LOOP_OVER_NODE_TYPES(t)
		if (ParseTree::cat(t) == cat)
			ParseTree::allow_annotation(t, annot);
}

@ The eagle-eyed observer will note that the |meaning| annotation is never
allowed. In fact it does exist, but only for meaning-coded parse nodes, which
never exist inside trees and are used only as parsing intermediates. So we
never see this annotation here.

=
void ParseTree::make_annotation_allowed_table(void) {
	if (annotation_allowed_set_up == FALSE) {
		annotation_allowed_set_up = TRUE;
		ParseTree::allow_annotation(HEADING_NT, heading_level_ANNOT);
		ParseTree::allow_annotation(SENTENCE_NT, language_element_ANNOT);
		ParseTree::allow_annotation_to_category(L1_NCAT, sentence_unparsed_ANNOT);
		ParseTree::allow_annotation_to_category(L2_NCAT, sentence_unparsed_ANNOT);
		#ifdef ANNOTATION_PERMISSIONS_WRITER
		ANNOTATION_PERMISSIONS_WRITER();
		#endif
	}
}

int ParseTree::annotation_allowed(node_type_t t, int annot) {
	if ((annot <= 0) || (annot > MAX_ANNOT_NUMBER))
		internal_error("annotation number out of range");
	if ((t >= BASE_OF_ENUMERATED_NTS) && (t < BASE_OF_ENUMERATED_NTS+NO_DEFINED_NT_VALUES))
		return annotation_allowed[t - BASE_OF_ENUMERATED_NTS][annot];
	return FALSE;
}

@h Ambiguity subtrees.

=
parse_node *ParseTree::add_possible_reading(parse_node *existing, parse_node *reading, wording W) {
	if (existing == NULL) return reading;
#ifdef CORE_MODULE
	if (ParseTree::is(reading, UNKNOWN_NT)) return existing;
#endif
	if (ParseTree::is(reading, AMBIGUITY_NT)) reading = reading->down;

	if (ParseTree::is(existing, AMBIGUITY_NT)) {
		#ifdef CORE_MODULE
		if (ParseTreeUsage::is_phrasal(reading))
			for (parse_node *E = existing->down; E; E = E->next_alternative)
				if (ParseTree::get_type(reading) == ParseTree::get_type(E)) {
					ParseTree::add_pr_inv(E, reading);
					return existing;
				}
		#endif
		parse_node *L = existing->down;
		while ((L) && (L->next_alternative)) L = L->next_alternative;
		L->next_alternative = reading;
		return existing;
	}

	#ifdef CORE_MODULE
	if ((ParseTreeUsage::is_phrasal(reading)) &&
		(ParseTree::get_type(reading) == ParseTree::get_type(existing))) {
		ParseTree::add_pr_inv(existing, reading);
		return existing;
	}
	#endif

	parse_node *A = ParseTree::new_with_words(AMBIGUITY_NT, W);
	A->down = existing;
	A->down->next_alternative = reading;
	return A;
}

#ifdef CORE_MODULE
void ParseTree::add_pr_inv(parse_node *E, parse_node *reading) {
	for (parse_node *N = reading->down->down, *next_N = (N)?(N->next_alternative):NULL; N;
		N = next_N, next_N = (N)?(N->next_alternative):NULL)
		ParseTree::add_single_pr_inv(E, N);
}

void ParseTree::add_single_pr_inv(parse_node *E, parse_node *N) {
	E = E->down->down;
	if (Invocations::eq(E, N)) return;
	while ((E) && (E->next_alternative)) {
		E = E->next_alternative;
		if (Invocations::eq(E, N)) return;
	}
	E->next_alternative = N; N->next_alternative = NULL;
}
#endif
