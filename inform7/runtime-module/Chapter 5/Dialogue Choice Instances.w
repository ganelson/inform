[RTDialogueChoices::] Dialogue Choice Instances.

To compile any dialogue details in the instances submodule.

@h Compilation data for dialogue choices.
Each |dialogue_choice| object contains this data:

=
typedef struct dialogue_choice_compilation_data {
	struct parse_node *where_created;
} dialogue_choice_compilation_data;

dialogue_choice_compilation_data RTDialogueChoices::new(parse_node *PN, dialogue_choice *dc) {
	dialogue_choice_compilation_data dlcd;
	dlcd.where_created = PN;
	return dlcd;
}

@h Compilation of dialogue.

=
void RTDialogueChoices::compile(void) {
	dialogue_choice *dc;
	LOOP_OVER(dc, dialogue_choice) {
		text_stream *desc = Str::new();
		WRITE_TO(desc, "dialogue choice %d", dc->allocation_id);
		Sequence::queue(&RTDialogueChoices::choice_compilation_agent,
			STORE_POINTER_dialogue_choice(dc), desc);
	}
}

@ =
void RTDialogueChoices::choice_compilation_agent(compilation_subtask *ct) {
	dialogue_choice *dc = RETRIEVE_POINTER_dialogue_choice(ct->data);
	current_sentence = dc->compilation_data.where_created;
}
