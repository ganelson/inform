[ReconcileVerbsStage::] Reconcile Verbs Stage.

To reconcile clashes between assimilated and originally generated verbs.

@ Suppose that the main source text creates a command verb PURLOIN: this
clashes with the definition of PURLOIN made by //CommandParserKit//, a testing
command intended not to play any part in actual play. What should we do about
that? These two definitions in rival compilation units cannot claim the same
command.

The answer is that the duplicate is prefixed with a |!|, so that in this example
PURLOIN would have the meaning in the source text, and |!PURLOIN| the meaning
in the kit. Note that preference is given to non-meta commands (i.e., those
affecting the world model) over testing commands.

=
void ReconcileVerbsStage::create_pipeline_stage(void) {
	ParsingPipelines::new_stage(I"reconcile-verbs",
		ReconcileVerbsStage::run, NO_STAGE_ARG, FALSE);
}

int ReconcileVerbsStage::run(pipeline_step *step) {
	inter_tree *I = step->ephemera.tree;
	dictionary *observed_verbs = Dictionaries::new(1024, TRUE);
	linked_list *VL = NEW_LINKED_LIST(inter_tree_node);
	InterTree::traverse(I, ReconcileVerbsStage::visitor, VL, NULL, CONSTANT_IST);
	@<Attend to the command verb definitions, non-meta ones first@>;
	return TRUE;
}

void ReconcileVerbsStage::visitor(inter_tree *I, inter_tree_node *P, void *v_VL) {
	linked_list *VL = (linked_list *) v_VL;
	if (ConstantInstruction::list_format(P) == CONST_LIST_FORMAT_GRAMMAR)
		ADD_TO_LINKED_LIST(P, inter_tree_node, VL);
}

@<Attend to the command verb definitions, non-meta ones first@> =
	inter_tree_node *P;
	LOOP_OVER_LINKED_LIST(P, inter_tree_node, VL)
		if (VanillaIF::is_verb_meta(P) == FALSE)
			@<Attend to the verb@>;
	LOOP_OVER_LINKED_LIST(P, inter_tree_node, VL)
		if (VanillaIF::is_verb_meta(P))
			@<Attend to the verb@>;

@<Attend to the verb@> =
	if (ConstantInstruction::list_len(P) > 0) {
		inter_pair val = ConstantInstruction::list_entry(P, 0);
		if (VanillaIF::is_verb_meta(P)) val = ConstantInstruction::list_entry(P, 1);
		if (InterValuePairs::is_dword(val)) {
			text_stream *word_text = InterValuePairs::to_dictionary_word(I, val);
			if (Dictionaries::find(observed_verbs, word_text)) {
				TEMPORARY_TEXT(nv)
				WRITE_TO(nv, "!%S", word_text);
				Str::clear(word_text);
				Str::copy(word_text, nv);
				DISCARD_TEXT(nv)
			}
			Dictionaries::create(observed_verbs, word_text);
		}
	}
