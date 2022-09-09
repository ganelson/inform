[DialogueLines::] Dialogue Lines.

To manage dialogue lines.

@h Scanning within a beat.
Inside any given beat, we have to keep track of the indentation of lines in
order to see what is subordinate to what. For example:
= (text as Inform 7)
(About Elsinore.)

Marcellus: "What, has this thing appear'd again to-night?"

Bernardo: "I have seen naught but [list of things in the Battlements]."

    Marcellus: "Horatio says 'tis but our fantasy."
=
Here the lines are at levels 0, 0 and 1. We actually allow them to go in as
far as |MAX_DIALOGUE_LINE_NESTING|, which is a lot of tab stops: no human
author would want that many.

As we go through the beat looking for lines, we track the most recent line
seen at each level. These are called "precursors".

@d MAX_DIALOGUE_LINE_NESTING 25

=
dialogue_line *precursor_dialogue_lines[MAX_DIALOGUE_LINE_NESTING];

void DialogueLines::clear_precursors(void) {
	for (int i=0; i<MAX_DIALOGUE_LINE_NESTING; i++)
		precursor_dialogue_lines[i] = NULL;
}

@h Scanning the dialogue lines in pass 0.
Lines have already been parsed a little. For example,
= (text as Inform 7)
	Marcellus (this is the phantom line): "What, has this thing appear'd again to-night?"
=
will have become:
= (text)
	DIALOGUE_LINE_NT
		DIALOGUE_SPEAKER_NT "Marcellus"
		DIALOGUE_SPEECH_NT ""What, has this thing appear'd again to-night?""
		DIALOGUE_CLAUSE_NT "this is the phantom line"
=
Here we have a simple tree where the beat node has at least two child nodes:
exactly one each of |DIALOGUE_SPEAKER_NT| and |DIALOGUE_SPEECH_NT|, and then
any number of |DIALOGUE_CLAUSE_NT| nodes (including none at all).

=
dialogue_line *DialogueLines::new(parse_node *PN) {
	@<See if we are expecting a dialogue line@>;
	int L = Annotations::read_int(PN, dialogue_level_ANNOT);
	if (L < 0) L = 0;
	@<See if that level of indentation is feasible@>;
	dialogue_line *dl = CREATE(dialogue_line);
	@<Initialise the line@>;
	@<Parse the clauses just enough to classify them@>;
	@<Look for a line name@>;
	@<Build the tree structure@>;
	@<Add the line to the world model@>;
	return dl;
}

@ Note that a |DIALOGUE_LINE_NT| is only made under a section marked as containing
dialogue, so the internal error here should be impossible to hit.

@<See if we are expecting a dialogue line@> =
	if (dialogue_section_being_scanned == NULL) internal_error("line outside dialogue section");
	if (current_dialogue_beat == NULL) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_LineWithoutBeat),
			"this dialogue line seems to appear before any beat has begun",
			"which is not allowed - every line has to be part of a 'beat', which "
			"has to be introduced with a bracketed paragraph looking like a stage "
			"direction in a play.");
		return NULL;
	}

@<See if that level of indentation is feasible@> =
	if (L >= MAX_DIALOGUE_LINE_NESTING) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_OvernestedLine),
			"this dialogue line is indented further than I can cope with",
			"and indeed further than any human reader could really make sense of.");
		return NULL;
	}
	if ((L > 0) && (precursor_dialogue_lines[L-1] == NULL)) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_OrphanLine),
			"this dialogue line is indented too far",
			"and should either not be indented at all, or indented by just one tab "
			"stop from the line it is dependent on.");
		return NULL;
	}

@ =
typedef struct dialogue_line {
	struct wording line_name;
	struct instance *as_instance;
	struct parse_node *line_at;
	struct wording speaker_text;
	struct wording speech_text;
	struct dialogue_beat *owning_beat;
	struct dialogue_line *parent_line;
	struct dialogue_line *child_line;
	struct dialogue_line *next_line;
	struct dialogue_line_compilation_data compilation_data;
	CLASS_DEFINITION
} dialogue_line;

@<Initialise the line@> =
	dl->line_name = EMPTY_WORDING;
	dl->line_at = PN;
	dl->owning_beat = current_dialogue_beat;
	dl->parent_line = NULL;
	if (L > 0) dl->parent_line = precursor_dialogue_lines[L-1];
	dl->child_line = NULL;
	dl->next_line = NULL;
	dl->compilation_data = RTDialogue::new_line(PN, dl);
	dl->speaker_text = EMPTY_WORDING;
	dl->speech_text = EMPTY_WORDING;

@<Parse the clauses just enough to classify them@> =
	for (parse_node *clause = PN->down; clause; clause = clause->next) {
		wording CW = Node::get_text(clause);
		if (Node::is(clause, DIALOGUE_CLAUSE_NT)) {
			<dialogue-line-clause>(CW);
			Annotations::write_int(clause, dialogue_line_clause_ANNOT, <<r>>);
		} else if (Node::is(clause, DIALOGUE_SPEAKER_NT)) {
			dl->speaker_text = CW;
		} else if (Node::is(clause, DIALOGUE_SPEECH_NT)) {
			dl->speech_text = CW;
		} else internal_error("damaged DIALOGUE_LINE_NT subtree");
	}

@ As with the analogous clauses for //Dialogue Beats//, each clause can be one
of the following possibilities:

@e LINE_NAME_DLC from 1
@e GENERIC_DLC

@<Look for a line name@> =
	int dialogue_line_name_count = 0;
	for (parse_node *clause = PN->down; clause; clause = clause->next) {
		wording CW = Node::get_text(clause);
		switch (Annotations::read_int(clause, dialogue_line_clause_ANNOT)) {
			case LINE_NAME_DLC:	
				<dialogue-line-clause>(CW);
				dl->line_name = GET_RW(<dialogue-line-clause>, 1);
				dialogue_line_name_count++;
				break;
		}
	}
	if (dialogue_line_name_count > 1)
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_LineNamedTwice),
			"this dialogue line seems to be named more than once",
			"which is not allowed. It can be anonymous, but otherwise can only have "
			"one name.");

@ Using:

=
<dialogue-line-clause> ::=
	this is the { ... line } |      ==> { LINE_NAME_DLC, - }
	...                             ==> { GENERIC_DLC, - }

@ =
void DialogueLines::write_dlc(OUTPUT_STREAM, int c) {
	switch(c) {
		case LINE_NAME_DLC: WRITE("LINE_NAME"); break;
		case GENERIC_DLC: WRITE("GENERIC"); break;
		default: WRITE("?"); break;
	}
}

@ The whole point of the indentation on lines is to provide a hierarchy of
lines within a beat, and this is where we use precursors to sort that out:

@<Build the tree structure@> =
	if (current_dialogue_beat->opening_line == NULL)
		current_dialogue_beat->opening_line = dl;
	else if (precursor_dialogue_lines[L])
		precursor_dialogue_lines[L]->next_line = dl;
	else
		precursor_dialogue_lines[L-1]->child_line = dl;

	precursor_dialogue_lines[L] = dl;
	for (int i=L+1; i<MAX_DIALOGUE_LINE_NESTING; i++) precursor_dialogue_lines[i] = NULL;

@ Each line produces an instance of the kind |dialogue line|, using the name
given in its clauses if one was.

@<Add the line to the world model@> =
	if (K_dialogue_line == NULL) internal_error("DialogueKit has not created K_dialogue_line");
	wording W = dl->line_name;
	if (Wordings::empty(W)) {
		TEMPORARY_TEXT(faux_name)
		WRITE_TO(faux_name, "line-%d", dl->allocation_id + 1);
		W = Feeds::feed_text(faux_name);
		DISCARD_TEXT(faux_name)
	}
	pcalc_prop *prop = Propositions::Abstract::to_create_something(K_dialogue_line, W);
	Assert::true(prop, CERTAIN_CE);
	dl->as_instance = Instances::latest();
