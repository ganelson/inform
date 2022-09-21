[DialogueRelations::] Dialogue Relations.

Binary predicates for spatial relationships.

@ So this section of code is all about the following:

= (early code)
binary_predicate *R_dialogue_containment = NULL;

@ These relations are all hard-wired in:

=
void DialogueRelations::start(void) {
	METHOD_ADD(dialogue_bp_family, STOCK_BPF_MTID, DialogueRelations::stock);
	METHOD_ADD(dialogue_bp_family, TYPECHECK_BPF_MTID, DialogueRelations::typecheck);
	METHOD_ADD(dialogue_bp_family, ASSERT_BPF_MTID, DialogueRelations::assert);
	METHOD_ADD(dialogue_bp_family, DESCRIBE_FOR_INDEX_BPF_MTID,
		DialogueRelations::describe_for_index);
}

void DialogueRelations::stock(bp_family *self, int n) {
	if (n == 1) {
		R_dialogue_containment =
			BinaryPredicates::make_pair(spatial_bp_family,
				BPTerms::new(KindSubjects::from_kind(K_dialogue_beat)),
				BPTerms::new(KindSubjects::from_kind(K_dialogue_line)),
				I"dialogue-contains", I"in-dialogue",
				NULL, Calculus::Schemas::new("DirectorTestLineContainment(*2,*1)"),
				PreformUtilities::wording(<relation-names>,
					DIALOGUE_CONTAINMENT_RELATION_NAME));
		BinaryPredicates::set_index_details(R_dialogue_containment, NULL, "dialogue line");
	}
}

@ No special rules apply to typechecking:

=
int DialogueRelations::typecheck(bp_family *self, binary_predicate *bp,
		kind **kinds_of_terms, kind **kinds_required, tc_problem_kit *tck) {
	return DECLINE_TO_MATCH;
}

@ "In" requires delicate handling, because of the way that English uses it
sometimes transitively and sometimes not. "The passport is in the desk", "The
passport is in the Dining Room" and "The passport is in Venezuela" place the
same object in a container, a room or a region respectively.

=
int DialogueRelations::assert(bp_family *self, binary_predicate *bp,
		inference_subject *infs0, parse_node *spec0,
		inference_subject *infs1, parse_node *spec1) {
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_AssertedDialogueContainment),
		"this asks to specify how dialogue is structured",
		"but that has to be done by writing a script in which the structure "
		"is implicit.");
	return TRUE;
}

@h Cursory description.

=
void DialogueRelations::describe_for_index(bp_family *self, OUTPUT_STREAM,
	binary_predicate *bp) {
	WRITE("dialogue");
}
