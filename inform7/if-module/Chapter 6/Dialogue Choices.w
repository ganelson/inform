[DialogueChoices::] Dialogue Choices.

To manage dialogue choices.

@h Scanning the dialogue choices in pass 0.
Choices have already been parsed a little. For example,
= (text as Inform 7)
	-- (if the shortbread is carried) "Offer the shortbread"
=
will have become:
= (text)
	DIALOGUE_CHOICE_NT
		DIALOGUE_SELECTION_NT ""Offer the shortbread""
		DIALOGUE_CLAUSE_NT "if the shortbread is carried"
=

@

=
dialogue_choice *DialogueChoices::new(parse_node *PN) {
	int L = Annotations::read_int(PN, dialogue_level_ANNOT);
	if (L < 0) L = 0;
	dialogue_choice *dc = CREATE(dialogue_choice);
	@<Initialise the choice@>;
	dc->as_node = DialogueNodes::add_to_current_beat(L, NULL, dc);
	@<Parse the clauses just enough to classify them@>;
	return dc;
}

@ =
typedef struct dialogue_choice {
	struct dialogue_node *as_node;
	struct parse_node *selection;
	struct dialogue_choice_compilation_data compilation_data;
	CLASS_DEFINITION
} dialogue_choice;

@<Initialise the choice@> =
	dc->as_node = NULL;
	dc->selection = NULL;
	dc->compilation_data = RTDialogue::new_choice(PN, dc);

@<Parse the clauses just enough to classify them@> =
	for (parse_node *clause = PN->down; clause; clause = clause->next) {
		wording CW = Node::get_text(clause);
		if (Node::is(clause, DIALOGUE_CLAUSE_NT)) {
			<dialogue-choice-clause>(CW);
			Annotations::write_int(clause, dialogue_choice_clause_ANNOT, <<r>>);
		} else if (Node::is(clause, DIALOGUE_SELECTION_NT)) {
			dc->selection = clause;
		} else internal_error("damaged DIALOGUE_CHOICE_NT subtree");
	}

@ As with the analogous clauses for //Dialogue Beats//, each clause can be one
of the following possibilities:

@e ANYTHING_DCC from 1

@ Using:

=
<dialogue-choice-clause> ::=
	...                                              ==> { ANYTHING_DCC, - }

@ =
void DialogueChoices::write_dcc(OUTPUT_STREAM, int c) {
	switch(c) {
		case ANYTHING_DCC:              WRITE("ANYTHING"); break;
		default:                        WRITE("?"); break;
	}
}

