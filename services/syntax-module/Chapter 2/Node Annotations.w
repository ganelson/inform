[Annotations::] Node Annotations.

Attaching general-purpose data to nodes in the syntax tree.

@h Annotations.
The parse tree annotations are miscellaneous, and many are needed only at a
few unusual nodes. Rather than have the structure grow large, we store
annotations in the following.

=
typedef struct parse_node_annotation {
	int annotation_id; /* one of the |*_ANNOT| values */
	int annotation_integer; /* if this is an integer annotation, or ... */
	general_pointer annotation_pointer; /* ... if it holds an object */
	struct parse_node_annotation *next_annotation;
} parse_node_annotation;

@ A new annotation is like a blank luggage ticket, waiting to be filled out
and attached to some suitcase. All is has is its ID:

=
parse_node_annotation *Annotations::new(int id) {
	parse_node_annotation *pna = CREATE(parse_node_annotation);
	pna->annotation_id = id;
	pna->annotation_integer = 0;
	pna->annotation_pointer = NULL_GENERAL_POINTER;
	pna->next_annotation = NULL;
	return pna;
}

@ Each node has a linked list of //parse_node_annotation// objects, but for
speed and to reduce memory usage we implement this by hand rather than using
the linked list class from //foundation//. A node |N| has a list |N->annotations|,
which points to its first //parse_node_annotation//, or is |NULL| if the node
is unannotated.

=
void Annotations::clear(parse_node *PN) {
	PN->annotations = NULL;
}

@h Reading annotations.
Though there will be many such lists, each one will always be short (worst case
about 5), so a more efficient search algorithm would not pay its overheads.

=
int Annotations::node_has(parse_node *PN, int id) {
	parse_node_annotation *pna;
	if (PN)
		for (pna=PN->annotations; pna; pna=pna->next_annotation)
			if (pna->annotation_id == id)
				return TRUE;
	return FALSE;
}

@ Reading annotations is similar. We need two variant forms: one for reading
integer-valued annotations (which is most of them, as it happens) and the
other for reading pointers to objects.

=
int Annotations::read_int(parse_node *PN, int id) {
	parse_node_annotation *pna;
	if (PN)
		for (pna=PN->annotations; pna; pna=pna->next_annotation)
			if (pna->annotation_id == id)
				return pna->annotation_integer;
	return 0;
}

general_pointer Annotations::read_object(parse_node *PN, int id) {
	parse_node_annotation *pna;
	if (PN)
		for (pna=PN->annotations; pna; pna=pna->next_annotation)
			if (pna->annotation_id == id)
				return pna->annotation_pointer;
	return NULL_GENERAL_POINTER;
}

@h Writing annotations.
Note that any second or subsequent annotation with the same ID as an existing
one (on the same node) overwrites it, but this is not an error.

Again, integers first:

=
void Annotations::write_int(parse_node *PN, int id, int v) {
	parse_node_annotation *newpna, *pna, *final = NULL;
	if (PN == NULL) internal_error("annotated null PN");
	for (pna=PN->annotations; pna; pna=pna->next_annotation) {
		if (pna->annotation_id == id) {
			/* an annotation with this id exists already: overwrite it */
			pna->annotation_integer = v;
			return;
		}
		if (pna->next_annotation == NULL) final = pna;
	}
	/* no annotation with this id exists: create a new one and add to end of node's list */
	newpna = Annotations::new(id); newpna->annotation_integer = v;
	if (final) final->next_annotation = newpna; else PN->annotations = newpna;
}

@ And now objects:

=
void Annotations::write_object(parse_node *PN, int id, general_pointer data) {
	if (PN == NULL) internal_error("annotated null PN");
	parse_node_annotation *newpna, *pna, *final = NULL;
	for (pna=PN->annotations; pna; pna=pna->next_annotation) {
		if (pna->annotation_id == id) {
			/* an annotation with this id exists already: overwrite it */
			pna->annotation_pointer = data;
			return;
		}
		if (pna->next_annotation == NULL) final = pna;
	}
	/* no annotation with this id exists: create a new one and add to end of node's list */
	newpna = Annotations::new(id); newpna->annotation_pointer = data;
	if (final) final->next_annotation = newpna; else PN->annotations = newpna;
}

@h Setters and getters.
It's a nuisance to use //Annotations::read_object// and //Annotations::write_object//
directly because of the need to wrap and unwrap the objects into |general_pointers|s,
so we use macros to make convenient get and set functions.

@d MAKE_ANNOTATION_FUNCTIONS(annotation_name, pointer_type)
void Node::set_##annotation_name(parse_node *pn, pointer_type *bp) {
	Annotations::write_object(pn, annotation_name##_ANNOT,
		STORE_POINTER_##pointer_type(bp));
}
pointer_type *Node::get_##annotation_name(parse_node *pn) {
	pointer_type *pt = NULL;
	if (Annotations::node_has(pn, annotation_name##_ANNOT))
		pt = RETRIEVE_POINTER_##pointer_type(
			Annotations::read_object(pn, annotation_name##_ANNOT));
	return pt;
}

@ Access routines will be needed for some of these, and the following
constructs them:

@d DECLARE_ANNOTATION_FUNCTIONS(annotation_name, pointer_type)
void Node::set_##annotation_name(parse_node *pn, pointer_type *bp);
pointer_type *Node::get_##annotation_name(parse_node *pn);

@h Copying annotations.
For the most part, an annotation can be copied directly from one node to
another: if it's an integer, or a pointer to an immutable sort of object.
But this sort of shallow copy won't always suffice, and so we allow for
a callback function to deep-copy the data inside the annotation if it
wants to.

=
void Annotations::copy(parse_node *to, parse_node *from) {
	to->annotations = NULL;
	for (parse_node_annotation *pna = from->annotations, *latest = NULL;
		pna; pna=pna->next_annotation) {
		parse_node_annotation *pna_copy = CREATE(parse_node_annotation);
		*pna_copy = *pna;
		#ifdef ANNOTATION_COPY_SYNTAX_CALLBACK
		ANNOTATION_COPY_SYNTAX_CALLBACK(pna_copy, pna);
		#endif
		pna_copy->next_annotation = NULL;
		if (to->annotations == NULL) to->annotations = pna_copy;
		else latest->next_annotation = pna_copy;
		latest = pna_copy;
	}
}

@h Annotations used by the syntax module.

@e heading_level_ANNOT from 1 /* int: for HEADING nodes, a hierarchical level, 0 (highest) to 9 (lowest) */
@e language_element_ANNOT /* int: this node is not really a sentence, but a language definition Use */
@e suppress_heading_dependencies_ANNOT /* int: ignore extension dependencies on this heading node */
@e implied_heading_ANNOT /* int: set only for the heading of implied inclusions */

@d MAX_ANNOT_NUMBER (NO_DEFINED_ANNOT_VALUES+1)

@h Annotation permissions.
As a piece of defensive coding, //syntax// will not allow arbitrary annotations
to be made: only annotations appropriate to the type of the node in question.
For example, attempting to give an |heading_level_ANNOT| to a |SENTENCE_NT|
node will throw an internal error -- it must mean a bug in Inform.

=
void Annotations::make_annotation_allowed_table(void) {
	Annotations::allow(HEADING_NT, heading_level_ANNOT);
	Annotations::allow(SENTENCE_NT, language_element_ANNOT);
	#ifdef ANNOTATION_PERMISSIONS_SYNTAX_CALLBACK
	ANNOTATION_PERMISSIONS_SYNTAX_CALLBACK();
	#endif
	#ifdef MORE_ANNOTATION_PERMISSIONS_SYNTAX_CALLBACK
	MORE_ANNOTATION_PERMISSIONS_SYNTAX_CALLBACK();
	#endif
	#ifdef EVEN_MORE_ANNOTATION_PERMISSIONS_SYNTAX_CALLBACK
	EVEN_MORE_ANNOTATION_PERMISSIONS_SYNTAX_CALLBACK();
	#endif
}

@ The |ANNOTATION_PERMISSIONS_SYNTAX_CALLBACK| function, if it exists, is
expected also to call the following:

=
int annotation_allowed[NO_DEFINED_NT_VALUES][MAX_ANNOT_NUMBER+1];

void Annotations::allow(node_type_t t, int annot) {
	annotation_allowed[t - ENUMERATED_NT_BASE][annot] = TRUE;
}
void Annotations::allow_for_category(int cat, int annot) {
	LOOP_OVER_ENUMERATED_NTS(t)
		if (NodeType::category(t) == cat)
			Annotations::allow(t, annot);
}

@ And this allows the following. Note that nodes with the temporary |*_MC|
types (i.e., those of an unenumerated node type) cannot be annotated.

=
int Annotations::is_allowed(node_type_t t, int annot) {
	if ((annot <= 0) || (annot > MAX_ANNOT_NUMBER))
		internal_error("annotation number out of range");
	if (NodeType::is_enumerated(t))
		return annotation_allowed[t - ENUMERATED_NT_BASE][annot];
	return FALSE;
}

@ The following removes any annotation not currently valid for the node; this
is rarely used by Inform, but is needed when a node changes its type.

=
void Annotations::clear_invalid(parse_node *pn) {
	node_type_t nt = Node::get_type(pn); 
	while ((pn->annotations) &&
		(!(Annotations::is_allowed(nt, pn->annotations->annotation_id))))
		pn->annotations = pn->annotations->next_annotation;
	for (parse_node_annotation *pna = pn->annotations; pna; pna = pna->next_annotation)
		if ((pna->next_annotation) &&
		(!(Annotations::is_allowed(nt, pna->next_annotation->annotation_id))))
		pna->next_annotation = pna->next_annotation->next_annotation;
}
