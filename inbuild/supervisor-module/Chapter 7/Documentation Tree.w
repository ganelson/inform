[DocumentationTree::] Documentation Tree.

A data structure to hold segments of Inform resource documentation.

@h The tree itself.
We will store the content in a heterogeneous tree: see //foundation: Trees//.

=
tree_type *cdoc_tree_TT = NULL; /* The only tree type we use in this section */

tree_node_type
	*heading_TNT = NULL,
	*example_TNT = NULL,
	*passage_TNT = NULL,
	*phrase_defn_TNT = NULL,
	*paragraph_TNT = NULL,
	*code_sample_TNT = NULL,
	*code_line_TNT = NULL;

heterogeneous_tree *DocumentationTree::new(void) {
	if (cdoc_tree_TT == NULL) {
		cdoc_tree_TT = Trees::new_type(I"documentation tree",
			&DocumentationTree::verify_root);

		heading_TNT = Trees::new_node_type(I"heading", cdoc_heading_CLASS,
			&DocumentationTree::heading_verifier);
		example_TNT = Trees::new_node_type(I"example", cdoc_example_CLASS,
			&DocumentationTree::example_verifier);
		passage_TNT = Trees::new_node_type(I"passage", cdoc_passage_CLASS,
			&DocumentationTree::passage_verifier);
		phrase_defn_TNT = Trees::new_node_type(I"phrase defn", cdoc_phrase_defn_CLASS,
			&DocumentationTree::phrase_defn_verifier);
		paragraph_TNT = Trees::new_node_type(I"paragraph", cdoc_paragraph_CLASS,
			&DocumentationTree::paragraph_verifier);
		code_sample_TNT = Trees::new_node_type(I"code sample", cdoc_code_sample_CLASS,
			&DocumentationTree::code_sample_verifier);
		code_line_TNT = Trees::new_node_type(I"line", cdoc_code_line_CLASS,
			&DocumentationTree::code_line_verifier);
	}
	heterogeneous_tree *tree = Trees::new(cdoc_tree_TT);
	Trees::make_root(tree, DocumentationTree::new_heading(tree, I"(root)", 0, 0, 0, 0));
	return tree;
}

@ The root of the tree is required to be a heading node.

=
int DocumentationTree::verify_root(tree_node *N) {
	if ((N == NULL) || (N->type != heading_TNT) || (N->next))
		return FALSE;
	return TRUE;
}

@ Heading nodes are used for the root (which has ID 0 and level 0) and then for
all chapter and section headings (which have levels 1 and 2 respectively). All
ID numbers are unique. The root heading is the only one with an empty "count",
which is otherwise something like |5| (chapter 5) or |3.4| (section 4 in chapter 3).

=
typedef struct cdoc_heading {
	struct text_stream *count;
	struct text_stream *name;
	int level; /* 0 = root, 1 = chapter, 2 = section */
	int ID;
	CLASS_DEFINITION
} cdoc_heading;

tree_node *DocumentationTree::new_heading(heterogeneous_tree *tree,
	text_stream *title, int level, int ID, int cc, int sc) {
	cdoc_heading *H = CREATE(cdoc_heading);
	H->count = Str::new();
	if (cc > 0) WRITE_TO(H->count, "%d", cc);
	if ((cc > 0) && (sc > 0)) WRITE_TO(H->count, ".");
	if (sc > 0) WRITE_TO(H->count, "%d", sc);
	H->name = Str::duplicate(title);
	H->level = level;
	H->ID = ID;
	return Trees::new_node(tree, heading_TNT, STORE_POINTER_cdoc_heading(H));
}

@ A heading node can only have headings or examples as children, except that
it can have a single passage node as its first child. If so, this is introductory
text.

=
int DocumentationTree::heading_verifier(tree_node *N) {
	for (tree_node *C = N->child; C; C = C->next) {
		if ((C->type != heading_TNT) && (C->type != example_TNT) && (C->type != passage_TNT))
			return FALSE;
		if ((C->type == passage_TNT) && (C->next)) return FALSE;
	}
	return TRUE;
}

@ Example nodes are used for the lettered examples in a documentation segment.
They have a "difficulty rating" in stars, 0 to 4. Numbers are unique from 1, 2, ...;
letters are unique from A, B, C, ...

=
typedef struct cdoc_example {
	struct text_stream *name;
	int star_count;
	int number;
	char letter;
	CLASS_DEFINITION
} cdoc_example;

tree_node *DocumentationTree::new_example(heterogeneous_tree *tree,
	text_stream *title, int star_count, int ecount) {
	cdoc_example *E = CREATE(cdoc_example);
	E->name = Str::duplicate(title);
	E->star_count = star_count;
	E->number = ecount;
	E->letter = 'A' + (char) ecount - 1;
	return Trees::new_node(tree, example_TNT, STORE_POINTER_cdoc_example(E));
}

@ An example node always has a single child: the passage containing its content.

=
int DocumentationTree::example_verifier(tree_node *N) {
	if ((N->child == NULL) || (N->child->type != passage_TNT) || (N->child->next))
		return FALSE;
	return TRUE;
}

@ Passage nodes contain passages of documentation which fall under examples
or headings.

=
typedef struct cdoc_passage {
	CLASS_DEFINITION
} cdoc_passage;

tree_node *DocumentationTree::new_passage(heterogeneous_tree *tree) {
	cdoc_passage *P = CREATE(cdoc_passage);
	return Trees::new_node(tree, passage_TNT, STORE_POINTER_cdoc_passage(P));
}

@ A passage node is essentially a holder for a mixed list of paragraphs,
indented code samples and phrase definitions.

=
int DocumentationTree::passage_verifier(tree_node *N) {
	for (tree_node *C = N->child; C; C = C->next)
		if ((C->type != paragraph_TNT) &&
			(C->type != code_sample_TNT) && (C->type != phrase_defn_TNT))
			return FALSE;
	return TRUE;
}

@ Phrase definition nodes contain little dashed inset boxes formally describing
phrases. The "tag" is optional and is for potential cross-referencing; the
"prototype" is the Inform source text for the phrase definition.

=
typedef struct cdoc_phrase_defn {
	struct text_stream *tag;
	struct text_stream *prototype;
	CLASS_DEFINITION
} cdoc_phrase_defn;

tree_node *DocumentationTree::new_phrase_defn(heterogeneous_tree *tree,
	text_stream *tag, text_stream *prototype) {
	cdoc_phrase_defn *P = CREATE(cdoc_phrase_defn);
	P->tag = Str::duplicate(tag);
	P->prototype = Str::duplicate(prototype);
	return Trees::new_node(tree, phrase_defn_TNT, STORE_POINTER_cdoc_phrase_defn(P));
}

@ An phrase defn node always has a single child: the passage containing its content.

=
int DocumentationTree::phrase_defn_verifier(tree_node *N) {
	if ((N->child == NULL) || (N->child->type != passage_TNT) || (N->child->next))
		return FALSE;
	return TRUE;
}

@ A paragraph node holds a body paragraph of text. It has no children.

=
typedef struct cdoc_paragraph {
	struct text_stream *content;
	CLASS_DEFINITION
} cdoc_paragraph;

tree_node *DocumentationTree::new_paragraph(heterogeneous_tree *tree,
	text_stream *content) {
	cdoc_paragraph *P = CREATE(cdoc_paragraph);
	P->content = Str::duplicate(content);
	return Trees::new_node(tree, paragraph_TNT, STORE_POINTER_cdoc_paragraph(P));
}

int DocumentationTree::paragraph_verifier(tree_node *N) {
	if (N->child) return FALSE; /* This must be a leaf node */
	return TRUE;
}

@ A code sample node holds a single code sample.

=
typedef struct cdoc_code_sample {
	CLASS_DEFINITION
	int with_paste_marker;
} cdoc_code_sample;

tree_node *DocumentationTree::new_code_sample(heterogeneous_tree *tree, int paste_me) {
	cdoc_code_sample *C = CREATE(cdoc_code_sample);
	C->with_paste_marker = paste_me;
	return Trees::new_node(tree, code_sample_TNT, STORE_POINTER_cdoc_code_sample(C));
}

@ A code sample's children form a list of code lines.

=
int DocumentationTree::code_sample_verifier(tree_node *N) {
	for (tree_node *C = N->child; C; C = C->next)
		if (C->type != code_line_TNT)
			return FALSE;
	if (N->child == NULL) return FALSE;
	return TRUE;
}

@ A code line node holds a single line of code, and has no children. The
indentation is relative to the start of the code sample, so usually starts
at 0, and is measured in tab stops.

=
typedef struct cdoc_code_line {
	struct text_stream *content;
	int indentation;
	int tabular;
	CLASS_DEFINITION
} cdoc_code_line;

tree_node *DocumentationTree::new_code_line(heterogeneous_tree *tree,
	text_stream *content, int indentation, int tabular) {
	cdoc_code_line *C = CREATE(cdoc_code_line);
	C->content = Str::duplicate(content);
	C->indentation = indentation;
	C->tabular = tabular;
	return Trees::new_node(tree, code_line_TNT, STORE_POINTER_cdoc_code_line(C));
}

int DocumentationTree::code_line_verifier(tree_node *N) {
	if (N->child) return FALSE; /* This must be a leaf node */
	return TRUE;
}

@ This utility function returns the |eg|th example node, if it exists, and |NULL|
if not.

=
tree_node *DocumentationTree::find_example(heterogeneous_tree *T, int eg) {
	if (eg < 1) return NULL;
	dc_find_example_task task;
	task.to_find_example = eg;
	task.to_find_heading = NULL;
	task.result = NULL;
	Trees::traverse_from(T->root, &DocumentationTree::find_visit, (void *) &task, 0);
	return task.result;
}

tree_node *DocumentationTree::find_chapter(heterogeneous_tree *T, int ch) {
	if (ch < 1) return NULL;
	dc_find_example_task task;
	task.to_find_example = 0;
	task.to_find_heading = Str::new(); WRITE_TO(task.to_find_heading, "%d", ch);
	task.result = NULL;
	Trees::traverse_from(T->root, &DocumentationTree::find_visit, (void *) &task, 0);
	return task.result;
}

typedef struct dc_find_example_task {
	int to_find_example;
	struct text_stream *to_find_heading;
	struct tree_node *result;
} dc_find_example_task;

int DocumentationTree::find_visit(tree_node *N, void *state, int L) {
	dc_find_example_task *task = (dc_find_example_task *) state;
	if (task->result) return FALSE;
	if ((task->to_find_example > 0) && (N->type == example_TNT)) {
		cdoc_example *E = RETRIEVE_POINTER_cdoc_example(N->content);
		if (E->number == task->to_find_example) {
			task->result = N;
			return FALSE;
		}
	}
	if ((task->to_find_heading) && (N->type == heading_TNT)) {
		cdoc_heading *E = RETRIEVE_POINTER_cdoc_heading(N->content);
		if ((E->level == 1) && (Str::eq(E->count, task->to_find_heading))) {
			task->result = N;
			return FALSE;
		}
	}
	return TRUE;
}
