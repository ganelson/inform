[RTDialogueLines::] Dialogue.

To compile any dialogue details in the instances submodule.

@h Compilation data for dialogue lines.
Each |dialogue_line| object contains this data:

=
typedef struct dialogue_line_compilation_data {
	struct parse_node *where_created;
} dialogue_line_compilation_data;

dialogue_line_compilation_data RTDialogueLines::new(parse_node *PN, dialogue_line *dl) {
	dialogue_line_compilation_data dlcd;
	dlcd.where_created = PN;
	return dlcd;
}

@h Compilation of dialogue.

=
void RTDialogueLines::compile(void) {
	dialogue_line *dl;
	LOOP_OVER(dl, dialogue_line) {
		text_stream *desc = Str::new();
		WRITE_TO(desc, "dialogue line %d", dl->allocation_id);
		Sequence::queue(&RTDialogueLines::line_compilation_agent, STORE_POINTER_dialogue_line(dl), desc);
	}
}

@ =
void RTDialogueLines::line_compilation_agent(compilation_subtask *ct) {
	dialogue_line *dl = RETRIEVE_POINTER_dialogue_line(ct->data);
	current_sentence = dl->compilation_data.where_created;
}
