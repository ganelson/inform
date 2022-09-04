[Dialogue::] Dialogue.

To manage dialogue beats and lines.

@

@d MAX_DIALOGUE_LINE_NESTING 25

=
heading *dialogue_section_being_scanned = NULL;
dialogue_beat *current_dialogue_beat = NULL;
dialogue_line *precursor_dialogue_lines[MAX_DIALOGUE_LINE_NESTING];

void Dialogue::note_heading(heading *h) {
	if (h->holds_dialogue) dialogue_section_being_scanned = h;
	else dialogue_section_being_scanned = NULL;
	current_dialogue_beat = NULL;
	for (int i=0; i<MAX_DIALOGUE_LINE_NESTING; i++)
		precursor_dialogue_lines[i] = NULL;
}

@

=
typedef struct dialogue_beat {
	struct parse_node *cue_at;
	struct heading *under_heading;
	struct dialogue_line *opening_line;
	struct dialogue_beat_compilation_data compilation_data;
	CLASS_DEFINITION
} dialogue_beat;

typedef struct dialogue_line {
	struct parse_node *line_at;
	struct dialogue_beat *owning_beat;
	struct dialogue_line *parent_line;
	struct dialogue_line *child_line;
	struct dialogue_line *next_line;
	struct dialogue_line_compilation_data compilation_data;
	CLASS_DEFINITION
} dialogue_line;

@

=
dialogue_beat *Dialogue::create_cue(parse_node *PN) {
	if (dialogue_section_being_scanned == NULL) internal_error("cue outside dialogue section");
	if (Annotations::read_int(PN, dialogue_level_ANNOT) > 0) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_IndentedBeat),
			"this dialogue beat seems to be indented",
			"which in dialogue would mean that it is part of something above it. "
			"But all beats (unlike lines) are free-standing, and should not be "
			"indented.");
	}
	dialogue_beat *db = CREATE(dialogue_beat);
	db->cue_at = PN;
	db->under_heading = dialogue_section_being_scanned;
	db->opening_line = NULL;
	db->compilation_data = RTDialogue::new_beat(PN, db);
	current_dialogue_beat = db;
	for (int i=0; i<MAX_DIALOGUE_LINE_NESTING; i++)
		precursor_dialogue_lines[i] = NULL;
	return db;
}

dialogue_line *Dialogue::create_line(parse_node *PN) {
	if (dialogue_section_being_scanned == NULL) internal_error("line outside dialogue section");
	int L = Annotations::read_int(PN, dialogue_level_ANNOT);
	if (L < 0) L = 0;
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
	if (current_dialogue_beat == NULL) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_LineWithoutBeat),
			"this dialogue line seems to appear before any beat has begun",
			"which is not allowed - every line has to be part of a 'beat', which "
			"has to be introduced with a bracketed paragraph looking like a stage "
			"direction in a play.");
		return NULL;
	}
	dialogue_line *dl = CREATE(dialogue_line);
	dl->line_at = PN;
	dl->owning_beat = current_dialogue_beat;
	dl->parent_line = NULL;
	if (L > 0) dl->parent_line = precursor_dialogue_lines[L-1];
	dl->child_line = NULL;
	dl->next_line = NULL;
	dl->compilation_data = RTDialogue::new_line(PN, dl);

	if (current_dialogue_beat->opening_line == NULL)
		current_dialogue_beat->opening_line = dl;
	else if (precursor_dialogue_lines[L])
		precursor_dialogue_lines[L]->next_line = dl;
	else
		precursor_dialogue_lines[L-1]->child_line = dl;

	precursor_dialogue_lines[L] = dl;
	for (int i=L+1; i<MAX_DIALOGUE_LINE_NESTING; i++) precursor_dialogue_lines[i] = NULL;

	return dl;
}
