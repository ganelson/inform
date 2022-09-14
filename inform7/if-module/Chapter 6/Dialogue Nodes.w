[DialogueNodes::] Dialogue Nodes.

The structure of a dialogue beat as a tree of nodes, each of which can be
either a line or a choice.

@ Inside any given beat, we have to keep track of the indentation of material
in order to see what is subordinate to what. For example:
= (text as Inform 7)
(About Elsinore.)

Marcellus: "What, has this thing appear'd again to-night?"

Bernardo: "I have seen naught but [list of things in the Battlements]."

    Marcellus: "Horatio says 'tis but our fantasy."
=
Here the lines are at levels 0, 0 and 1. We actually allow them to go in as
far as |MAX_DIALOGUE_NODE_NESTING|, which is a lot of tab stops: no human
author would want that many.

As we go through the beat looking for lines, we track the most recent line
or choice seen at each level. These are called "precursors".

@d MAX_DIALOGUE_NODE_NESTING 25

=
dialogue_node *precursor_dialogue_nodes[MAX_DIALOGUE_NODE_NESTING];

void DialogueNodes::clear_precursors(int from) {
	for (int i=from; i<MAX_DIALOGUE_NODE_NESTING; i++)
		precursor_dialogue_nodes[i] = NULL;
}

@ Other than the connectivity for the tree structure, a node is basically a
union type: it can either be a line or a choice.

=
typedef struct dialogue_node {
	struct dialogue_line *if_line;
	struct dialogue_choice *if_choice;

	struct dialogue_beat *owning_beat;
	struct dialogue_node *parent_node;
	struct dialogue_node *child_node;
	struct dialogue_node *next_node;
	CLASS_DEFINITION
} dialogue_node;

@ And therefore the following should be called with exactly one non-|NULL|
pointer.

=
dialogue_node *DialogueNodes::add_to_current_beat(int L, dialogue_line *dl, dialogue_choice *dc) {
	int w = 0; if (dl) w++; if (dc) w++;
	if (w != 1) internal_error("exactly one should be non-NULL");
	@<See if we are expecting a dialogue node@>;
	@<See if that level of indentation is feasible@>;
	dialogue_node *dn = CREATE(dialogue_node);
	@<Initialise the node@>;
	@<Join the node to the current beat's tree@>;
	@<Make the node a precursor@>;
	return dn;
}

@<Initialise the node@> =
	dn->if_line = dl;
	dn->if_choice = dc;
	dn->owning_beat = current_dialogue_beat;

	if (L > 0) dn->parent_node = precursor_dialogue_nodes[L-1];
	else dn->parent_node = NULL;
		dn->child_node = NULL;
	dn->next_node = NULL;

@<Join the node to the current beat's tree@> =
	if (current_dialogue_beat->root == NULL)
		current_dialogue_beat->root = dn;
	else if (precursor_dialogue_nodes[L])
		precursor_dialogue_nodes[L]->next_node = dn;
	else
		precursor_dialogue_nodes[L-1]->child_node = dn;

@<Make the node a precursor@> =
	precursor_dialogue_nodes[L] = dn;
	DialogueNodes::clear_precursors(L+1);

@ Note that a |DIALOGUE_LINE_NT| or |DIALOGUE_CHOICE_NT| is only made under a
section marked as containing dialogue, so the internal error here should be
impossible to hit.

@<See if we are expecting a dialogue node@> =
	if (dialogue_section_being_scanned == NULL) internal_error("node outside dialogue section");
	if (current_dialogue_beat == NULL) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_LineWithoutBeat),
			"this dialogue material seems to appear before any beat has begun",
			"which is not allowed - every line or choice has to be part of a 'beat', which "
			"has to be introduced with a bracketed paragraph looking like a stage "
			"direction in a play.");
		return NULL;
	}

@<See if that level of indentation is feasible@> =
	if (L >= MAX_DIALOGUE_NODE_NESTING) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_OvernestedLine),
			"this dialogue material is indented further than I can cope with",
			"and indeed further than any human reader could really make sense of.");
		return NULL;
	}
	if ((L > 0) && (precursor_dialogue_nodes[L-1] == NULL)) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_OrphanLine),
			"this dialogue material is indented too far",
			"and should either not be indented at all, or indented by just one tab "
			"stop from the material it is dependent on.");
		return NULL;
	}
