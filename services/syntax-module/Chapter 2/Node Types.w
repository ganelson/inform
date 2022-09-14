[NodeType::] Node Types.

Each node in a syntax tree has a type, which informs whether it can have
child nodes, and what in general terms it means.

@h Node types.
Each node has a "node type". Some of those are defined here with |*_NT|
names -- these are the "enumerated" node types. But every |*_MC| code,
as defined in the //words// module and by its clients, is also a valid
node type. (See //words: Vocabulary//.) The following is guaranteed to
be able to hold any node type:

=
@d node_type_t unsigned int /* (not a typedef because it makes trouble for //inweb//) */

@ In practice, then, we hold node types as unsigned integers, and we will
assume that these are at least 32 bits wide but perhaps no wider. Our
enumerated codes all have bit 32 set, and therefore no |*_MC| can have.

@d ENUMERATED_NT_BASE 0x80000000

@e INVALID_NT from 0x80000000   /* No node with this node type should ever exist */

@d LOOP_OVER_ENUMERATED_NTS(t)
	for (node_type_t t=ENUMERATED_NT_BASE; t<ENUMERATED_NT_BASE+NO_DEFINED_NT_VALUES; t++)

=
int NodeType::is_enumerated(node_type_t t) {
	if ((t >= ENUMERATED_NT_BASE) &&
		(t < ENUMERATED_NT_BASE+NO_DEFINED_NT_VALUES)) return TRUE;
	return FALSE;
}

@h Metadata on node types.
With what will be a profusion of node types, we need a systematic way to organise
information about them, and here it is:

@d INFTY 2000000000 /* if a node has more than two billion children, we are in trouble anyway */

=
typedef struct node_type_metadata {
	node_type_t identity;
	struct text_stream *node_type_name; /* name such as |"HEADING_NT"| */
	int min_children; /* minimum legal number of child nodes */
	int max_children; /* maximum legal number of child nodes, or |INFTY| */
	int category; /* one of the |*_NCAT| values below */
	int node_flags; /* bitmap of node flags */
} node_type_metadata;

@ The following categories certainly exist, and //core: Inform-Only Nodes and Annotations//
adds further ones. The idea is that |L1_NCAT|, |L2_NCAT| and so on down are nodes
of different "levels", with lower numbers being higher in the tree and more
structurally significant. Categories are used to decide which nodes are allowed
to be children of which others, thus enforcing this hierarchy.

@e INVALID_NCAT from 0   /* No node with this category should ever exist */
@e L1_NCAT
@e L2_NCAT
@e UNKNOWN_NCAT

=
int parentage_allowed[NO_DEFINED_NCAT_VALUES][NO_DEFINED_NCAT_VALUES];

void NodeType::make_parentage_allowed_table(void) {
	for (int i = 0; i < NO_DEFINED_NCAT_VALUES; i++)
		for (int j = 0; j < NO_DEFINED_NCAT_VALUES; j++)
			parentage_allowed[i][j] = FALSE;
	NodeType::allow_parentage_for_categories(L1_NCAT, L1_NCAT);
	#ifdef PARENTAGE_PERMISSIONS_SYNTAX_CALLBACK
	PARENTAGE_PERMISSIONS_SYNTAX_CALLBACK();
	#endif
	#ifdef MORE_PARENTAGE_PERMISSIONS_SYNTAX_CALLBACK
	MORE_PARENTAGE_PERMISSIONS_SYNTAX_CALLBACK();
	#endif
	#ifdef EVEN_MORE_PARENTAGE_PERMISSIONS_SYNTAX_CALLBACK
	EVEN_MORE_PARENTAGE_PERMISSIONS_SYNTAX_CALLBACK();
	#endif
}

@ The callback function |PARENTAGE_PERMISSIONS_SYNTAX_CALLBACK| should
call this as needed to fill in more permissions:

=
void NodeType::allow_parentage_for_categories(int A, int B) {
	parentage_allowed[A][B] = TRUE;
}

@ The bitmap of node flags currently contains only two which are used by
the syntax module, but we'll reserve two others for use by other modules:

@d DONT_VISIT_NFLAG 0x00000001 /* not visited in traverses */
@d TABBED_NFLAG     0x00000002 /* contains tab-delimited lists */
@d PHRASAL_NFLAG    0x00000004 /* compiles to a function call */
@d ASSERT_NFLAG     0x00000008 /* allow this on either side of an assertion? */

@ And the metadata is stored in this table, whose indexes are offset by
|ENUMERATED_NT_BASE|. We can therefore only retrieve metadata on
enumerated node types, not on meaning codes such as |RULE_MC|, for which
the following function will return |NULL|.

=
int any_node_types_created = FALSE;
int node_type_created[NO_DEFINED_NT_VALUES];
node_type_metadata node_type_metadatas[NO_DEFINED_NT_VALUES];

node_type_metadata *NodeType::get_metadata(node_type_t t) {
	if (NodeType::is_enumerated(t)) {
		if ((any_node_types_created == FALSE) ||
			(node_type_created[t - ENUMERATED_NT_BASE] == FALSE))
			return NULL;
		node_type_metadata *metadata =
			&(node_type_metadatas[t - ENUMERATED_NT_BASE]);
		if (metadata->identity != t) {
			WRITE_TO(STDERR, "unable to locate node type %08x\n", t);
			internal_error("node type metadata lookup incorrect");
		}
		return metadata;
	}
	return NULL;
}

@h Logging.
In the event that metadata isn't available, because the node is not
enumerated, we allow a callback function (if provided) to do the job for us.

=
void NodeType::log(OUTPUT_STREAM, int it) {
	node_type_t t = (node_type_t) it;
	node_type_metadata *metadata = NodeType::get_metadata(t);
	if (metadata) WRITE("%S", metadata->node_type_name);
	else {
	#ifdef LOG_UNENUMERATED_NODE_TYPES_SYNTAX_CALLBACK
		LOG_UNENUMERATED_NODE_TYPES_SYNTAX_CALLBACK(OUT, t);
	#endif
	#ifndef LOG_UNENUMERATED_NODE_TYPES_SYNTAX_CALLBACK
		WRITE("?%08x_NT", t);
	#endif
	}
}

@h Creation.

=
void NodeType::new(node_type_t identity, text_stream *node_type_name, int min_children,
	int max_children, int category, int node_flags) {
	if (NodeType::is_enumerated(identity) == FALSE) internal_error("set bad metadata");
	node_type_metadata *ptnt =
		&(node_type_metadatas[identity - ENUMERATED_NT_BASE]);
	ptnt->identity = identity;
	ptnt->node_type_name = node_type_name;
	ptnt->min_children = min_children;
	ptnt->max_children = max_children;
	ptnt->category = category;
	ptnt->node_flags = node_flags;
	if (any_node_types_created == FALSE) {
		for (int i=0; i<NO_DEFINED_NT_VALUES; i++)
			node_type_created[i] = FALSE;
		any_node_types_created = TRUE;
	}
	node_type_created[identity - ENUMERATED_NT_BASE] = TRUE;
}

@h Basic properties.

=
int NodeType::category(node_type_t t) {
	node_type_metadata *metadata = NodeType::get_metadata(t);
	if (metadata) return metadata->category;
	return INVALID_NCAT;
}

int NodeType::is_top_level(node_type_t t) {
	if (NodeType::category(t) == L1_NCAT) return TRUE;
	return FALSE;
}

int NodeType::has_flag(node_type_t t, int f) {
	node_type_metadata *metadata = NodeType::get_metadata(t);
	if ((metadata) && ((metadata->node_flags) & f)) return TRUE;
	return FALSE;
}

text_stream *NodeType::get_name(node_type_t t) {
	node_type_metadata *metadata = NodeType::get_metadata(t);
	if (metadata == NULL) return I"?";
	return metadata->node_type_name;
}

@ This provides a way for users of the module to indicate what's a sentence:

=
int NodeType::is_sentence(node_type_t t) {
	#ifdef IS_SENTENCE_NODE_SYNTAX_CALLBACK
	return IS_SENTENCE_NODE_SYNTAX_CALLBACK(t);
	#endif
	#ifndef IS_SENTENCE_NODE_SYNTAX_CALLBACK
	return FALSE;
	#endif
}

@h Node types used by the syntax module.
The //syntax// module uses only the following node types, but our client modules
add substantially more. The three callback functions provide opportunities to
do this. All a bit clumsy, but it works.

@e ROOT_NT          /* Only one such node exists per syntax tree: its root */
@e INCLUSION_NT     /* Holds a block of source material */
@e HEADING_NT       /* "Chapter VIII: Never Turn Your Back On A Shreve" */
@e INCLUDE_NT       /* "Include School Rules by Argus Filch" */
@e BEGINHERE_NT     /* "The Standard Rules begin here" */
@e ENDHERE_NT       /* "The Standard Rules end here" */
@e SENTENCE_NT      /* "The Garden is a room" */
@e AMBIGUITY_NT     /* Marks an ambiguous set of readings in the tree */
@e UNKNOWN_NT       /* "arfle barfle gloop" */
@e DIALOGUE_CUE_NT  /* A dialogue cue under a dialogue Section heading */
@e DIALOGUE_CHOICE_NT /* A branch point in dialogue */
@e DIALOGUE_LINE_NT /* A line of dialogue under a dialogue Section heading */
@e DIALOGUE_SPEAKER_NT /* "James" in "James: "Hello!"" */
@e DIALOGUE_SPEECH_NT /* ""Hello!"" in "James: "Hello!"" */
@e DIALOGUE_SELECTION_NT /* "instead of examining a door" */
@e DIALOGUE_CLAUSE_NT /* A bracketed term used in a cue or line */

=
void NodeType::metadata_setup(void) {
	NodeType::new(INVALID_NT, I"(INVALID_NT)",                     0, INFTY, INVALID_NCAT, 0);

	NodeType::new(ROOT_NT, I"ROOT_NT",                             0, INFTY, L1_NCAT, DONT_VISIT_NFLAG);
	NodeType::new(INCLUSION_NT, I"INCLUSION_NT",                   0, INFTY, L1_NCAT, DONT_VISIT_NFLAG);
	NodeType::new(HEADING_NT, I"HEADING_NT",                       0, INFTY, L1_NCAT, 0);
	NodeType::new(INCLUDE_NT, I"INCLUDE_NT",                       0, 0,     L2_NCAT, 0);
	NodeType::new(BEGINHERE_NT, I"BEGINHERE_NT",                   0, 0,     L2_NCAT, 0);
	NodeType::new(ENDHERE_NT, I"ENDHERE_NT",                       0, 0,     L2_NCAT, 0);
	NodeType::new(SENTENCE_NT, I"SENTENCE_NT",                     0, INFTY, L2_NCAT, 0);
	NodeType::new(AMBIGUITY_NT, I"AMBIGUITY_NT",                   0, INFTY, L1_NCAT, 0);
	NodeType::new(UNKNOWN_NT, I"UNKNOWN_NT",                       0, INFTY, UNKNOWN_NCAT, 0);

	NodeType::new(DIALOGUE_CUE_NT, I"DIALOGUE_CUE_NT",             0, INFTY, L2_NCAT, 0);
	NodeType::new(DIALOGUE_CHOICE_NT, I"DIALOGUE_CHOICE_NT",       0, INFTY, L2_NCAT, 0);
	NodeType::new(DIALOGUE_LINE_NT, I"DIALOGUE_LINE_NT",           0, INFTY, L2_NCAT, 0);
	NodeType::new(DIALOGUE_SPEAKER_NT, I"DIALOGUE_SPEAKER_NT",     0, INFTY, L2_NCAT, 0);
	NodeType::new(DIALOGUE_SPEECH_NT, I"DIALOGUE_SPEECH_NT",       0, INFTY, L2_NCAT, 0);
	NodeType::new(DIALOGUE_SELECTION_NT, I"DIALOGUE_SELECTION_NT", 0, INFTY, L2_NCAT, 0);
	NodeType::new(DIALOGUE_CLAUSE_NT, I"DIALOGUE_CLAUSE_NT",       0, INFTY, L2_NCAT, 0);

	#ifdef NODE_METADATA_SETUP_SYNTAX_CALLBACK
	NODE_METADATA_SETUP_SYNTAX_CALLBACK();
	#endif
	#ifdef MORE_NODE_METADATA_SETUP_SYNTAX_CALLBACK
	MORE_NODE_METADATA_SETUP_SYNTAX_CALLBACK();
	#endif
	#ifdef EVEN_MORE_NODE_METADATA_SETUP_SYNTAX_CALLBACK
	EVEN_MORE_NODE_METADATA_SETUP_SYNTAX_CALLBACK();
	#endif
}

@h Parentage rules.
It's mostly the case that node category determines whether one node can be
parent to another, but there are exceptions.

=
int NodeType::parentage_allowed(node_type_t t_parent, node_type_t t_child) {
	node_type_metadata *metadata_parent = NodeType::get_metadata(t_parent);
	if (metadata_parent == NULL) return FALSE;
	node_type_metadata *metadata_child = NodeType::get_metadata(t_child);
	if (metadata_child == NULL) return FALSE;

	int cat_child = metadata_child->category;
	int cat_parent = metadata_parent->category;

	if (parentage_allowed[cat_parent][cat_child]) return TRUE;
	if ((t_parent == HEADING_NT) && (cat_child == L2_NCAT)) return TRUE;
	if ((t_parent == DIALOGUE_LINE_NT) &&
		((t_child == DIALOGUE_SPEAKER_NT) || (t_child == DIALOGUE_SPEECH_NT) ||
			(t_child == DIALOGUE_CLAUSE_NT)))
		return TRUE;
	if ((t_parent == DIALOGUE_CUE_NT) && (t_child == DIALOGUE_CLAUSE_NT))
		return TRUE;
	if ((t_parent == DIALOGUE_CHOICE_NT) &&
		((t_child == DIALOGUE_CLAUSE_NT) || (t_child == DIALOGUE_SELECTION_NT)))
		return TRUE;
	#ifdef PARENTAGE_EXCEPTIONS_SYNTAX_CALLBACK
	if (PARENTAGE_EXCEPTIONS_SYNTAX_CALLBACK(t_parent, cat_parent, t_child, cat_child))
		return TRUE;
	#endif
	if ((t_parent == AMBIGUITY_NT) || (t_child == AMBIGUITY_NT)) return TRUE;
	return FALSE;
}
