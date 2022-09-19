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
union type: it can either be a line, a choice or a decision.

=
typedef struct dialogue_node {
	struct dialogue_line *if_line;
	struct dialogue_choice *if_choice;
	struct dialogue_decision *if_decision;

	struct dialogue_beat *owning_beat;
	struct dialogue_node *parent_node;
	struct dialogue_node *child_node;
	struct dialogue_node *next_node;
	CLASS_DEFINITION
} dialogue_node;

@ The following should be called with exactly one non-|NULL| pointer. (Decision
nodes are created later.)

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
	dn->if_decision = NULL;
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

@

@e BLANK_DDT from 1
@e TEXTUAL_DDT
@e PARSED_COMMAND_DDT
@e CONTROL_DDT

=
typedef struct dialogue_decision {
	CLASS_DEFINITION
	int decision_type; /* one of the |*_DDT| constants above */
	struct dialogue_node *as_node;
} dialogue_decision;

@

=
void DialogueNodes::find_decisions_in_beat(dialogue_beat *db) {
	DialogueNodes::find_decisions_in_beat_r(db, db->root, NULL);
	LOG("Beat has tree:\n");
	DialogueNodes::log_node_tree(db->root);
	DialogueNodes::examine_decisions_in_beat_r(db, db->root, NULL);
}
void DialogueNodes::find_decisions_in_beat_r(dialogue_beat *db, dialogue_node *dn, dialogue_node *parent) {
	if (dn == NULL) return;
	for (dialogue_node *c = dn, *prev = NULL; c; prev = c, c = c->next_node) {
		if (c->if_choice) {
			dialogue_node *d = c;
			if (DialogueNodes::is_divider(c)) {
				if (c->child_node) {
					current_sentence = c->if_choice->choice_at;
					StandardProblems::sentence_problem(Task::syntax_tree(),
						_p_(PM_ChoiceDividerDependent),
						"this choice can't have dependent material",
						"that is, can't have lines or other choices indented below it.");
					c->child_node = NULL;
				}
			} else {
				while ((d) && (d->next_node) && (d->next_node->if_choice) &&
					(DialogueNodes::is_divider(d->next_node) == FALSE)) d = d->next_node;
			}
			dialogue_decision *dd = CREATE(dialogue_decision);
			dd->decision_type = BLANK_DDT;
			dd->as_node = CREATE(dialogue_node);
			dd->as_node->if_line = NULL;
			dd->as_node->if_choice = NULL;
			dd->as_node->if_decision = dd;
			dd->as_node->parent_node = parent;
			if (prev) prev->next_node = dd->as_node;
			else if (parent) parent->child_node = dd->as_node;
			else db->root = dd->as_node;
			dd->as_node->next_node = d->next_node; d->next_node = NULL;
			dd->as_node->child_node = c;
			for (dialogue_node *e = c; e; e = e->next_node)
				e->parent_node = dd->as_node;
			for (dialogue_node *e = c; e; e = e->next_node)
				DialogueNodes::find_decisions_in_beat_r(db, e->child_node, e);
			c = dd->as_node;
		} else {
			DialogueNodes::find_decisions_in_beat_r(db, c->child_node, c);
		}
	}
}

int DialogueNodes::is_divider(dialogue_node *dn) {
	if ((dn) && (dn->if_choice) &&
		((dn->if_choice->selection_type == NEW_CHOICE_DSEL) ||
			(dn->if_choice->selection_type == AGAIN_DSEL) ||
			(dn->if_choice->selection_type == STOP_DSEL) ||
			(dn->if_choice->selection_type == PERFORM_DSEL)))
		return TRUE;
	return FALSE;
}

void DialogueNodes::examine_decisions_in_beat_r(dialogue_beat *db, dialogue_node *dn, dialogue_node *parent) {
	for (dialogue_node *c = dn, *prev = NULL; c; prev = c, c = c->next_node) {
		if (c->if_decision) {
			LOG("Decision %d\n", c->if_decision->allocation_id);
			int t = -1;
			dialogue_node *bad_otherwise = NULL, *mixed_choices = NULL;
			for (dialogue_node *d = c->child_node; d; d = d->next_node) {
				LOG("Option is choice %d\n", (d->if_choice)?(d->if_choice->allocation_id):-1);
				if (d->if_choice->selection_type == OTHERWISE_DSEL) {
					if (t != PARSED_COMMAND_DDT) bad_otherwise = d;
					if (d->next_node) bad_otherwise = d;
				} else {
					int ddt = DialogueNodes::decision_type(d);
					if (t == -1) t = ddt;
					else if (t != ddt) mixed_choices = d;
				}
			}
			if (bad_otherwise) {
				current_sentence = bad_otherwise->if_choice->choice_at;
				StandardProblems::sentence_problem(Task::syntax_tree(),
					_p_(PM_ChoiceOtherwiseUnexpected),
					"this run of choices uses 'otherwise' unexpectedly",
					"since 'otherwise' can only be used as the last option, and "
					"only where the options are written in terms of actions.");
			}
			if (mixed_choices) {
				current_sentence = mixed_choices->if_choice->choice_at;
				StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_ChoicesMixed),
					"this run of choices mixes up the possible sorts of choice",
					"and should either all be action-dependent choices (perhaps "
					"finishing with an 'otherwise'), or else all textual choices.");
			}
			if ((c->child_node) && (c->child_node->if_choice->selection_type == NEW_CHOICE_DSEL)) {
				if ((prev == NULL) || (prev->if_line) ||
					(c->next_node == NULL) || (c->next_node->if_line)) {
					current_sentence = c->child_node->if_choice->choice_at;
					StandardProblems::sentence_problem(Task::syntax_tree(),
						_p_(PM_ChoiceBlankRedundant),
						"this use of '-> another choice' looks redundant",
						"occurring at the start or end of a set of options. "
						"'-> another choice' should be used only where there's "
						"a need to mark a division point between two sets "
						"of options running on from one to the other.");
				}
			}
			c->if_decision->decision_type = t;
		}
		DialogueNodes::examine_decisions_in_beat_r(db, c->child_node, c);
	}
}

void DialogueNodes::log_node_tree(dialogue_node *dn) {
	for (; dn; dn=dn->next_node) {
		DialogueNodes::log_node(dn); LOG("\n");
		if (dn->child_node) {
			LOG_INDENT;
			DialogueNodes::log_node_tree(dn->child_node);
			LOG_OUTDENT;
		}
	}
}

void DialogueNodes::log_node(dialogue_node *dn) {
	if (dn == NULL) LOG("<null>");
	else if (dn->if_line) LOG("line %d %W", dn->if_line->allocation_id, Node::get_text(dn->if_line->line_at));
	else if (dn->if_choice) LOG("choice %d %W", dn->if_choice->allocation_id, Node::get_text(dn->if_choice->choice_at));
	else if (dn->if_decision) LOG("decision %d", dn->if_decision->allocation_id);
}

int DialogueNodes::decision_type(dialogue_node *dn) {
	if ((dn == NULL) || (dn->if_choice == NULL)) return -1;
	switch (dn->if_choice->selection_type) {
		case NEW_CHOICE_DSEL: return PARSED_COMMAND_DDT;
		case TEXTUAL_DSEL: return TEXTUAL_DDT;
		case AGAIN_DSEL: return CONTROL_DDT;
		case STOP_DSEL: return CONTROL_DDT;
		case OTHERWISE_DSEL: return CONTROL_DDT;
		case INSTEAD_OF_DSEL: return PARSED_COMMAND_DDT;
		case AFTER_DSEL: return PARSED_COMMAND_DDT;
		case BEFORE_DSEL: return PARSED_COMMAND_DDT;
		case PERFORM_DSEL: return CONTROL_DDT;
		default: internal_error("unimplemented DSEL");
	}
	return -1;
}
