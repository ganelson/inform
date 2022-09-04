[RTDialogue::] Dialogue.

To compile the dialogue submodule for a compilation unit, which contains
something to be worked out.

@h Compilation data for dialogue beats.
Each |dialogue_beat| object contains this data:

=
typedef struct dialogue_beat_compilation_data {
	struct parse_node *where_created;
} dialogue_beat_compilation_data;

dialogue_beat_compilation_data RTDialogue::new_beat(parse_node *PN, dialogue_beat *db) {
	dialogue_beat_compilation_data dbcd;
	dbcd.where_created = PN;
	return dbcd;
}

@h Compilation data for dialogue lines.
Each |dialogue_line| object contains this data:

=
typedef struct dialogue_line_compilation_data {
	struct parse_node *where_created;
} dialogue_line_compilation_data;

dialogue_line_compilation_data RTDialogue::new_line(parse_node *PN, dialogue_line *dl) {
	dialogue_line_compilation_data dlcd;
	dlcd.where_created = PN;
	return dlcd;
}

@h Compilation of dialogue.

=
void RTDialogue::compile(void) {
	dialogue_beat *db;
	LOOP_OVER(db, dialogue_beat) {
		text_stream *desc = Str::new();
		WRITE_TO(desc, "dialogue beat %d", db->allocation_id);
		Sequence::queue(&RTDialogue::beat_compilation_agent, STORE_POINTER_dialogue_beat(db), desc);
	}
	dialogue_line *dl;
	LOOP_OVER(dl, dialogue_line) {
		text_stream *desc = Str::new();
		WRITE_TO(desc, "dialogue line %d", dl->allocation_id);
		Sequence::queue(&RTDialogue::line_compilation_agent, STORE_POINTER_dialogue_line(dl), desc);
	}
}

void RTDialogue::beat_compilation_agent(compilation_subtask *ct) {
	dialogue_beat *db = RETRIEVE_POINTER_dialogue_beat(ct->data);
	current_sentence = db->compilation_data.where_created;
	LOG("Beat %d = %W\n", db->allocation_id, Node::get_text(current_sentence));
	RTDialogue::log_r(db->opening_line);
}

void RTDialogue::line_compilation_agent(compilation_subtask *ct) {
	dialogue_line *dl = RETRIEVE_POINTER_dialogue_line(ct->data);
	current_sentence = dl->compilation_data.where_created;
	LOG("Line %d = %W\n", dl->allocation_id, Node::get_text(current_sentence));
}

void RTDialogue::log_r(dialogue_line *dl) {
	while (dl) {
		LOG("Line %d = %W\n",
			dl->allocation_id, Node::get_text(dl->compilation_data.where_created));
		if (dl->child_line) {
			if (dl->child_line->parent_line != dl) LOG("*** Broken parentage ***\n");
			LOG_INDENT;
			RTDialogue::log_r(dl->child_line);
			LOG_OUTDENT;
		}
		dl = dl->next_line;
	}
}
