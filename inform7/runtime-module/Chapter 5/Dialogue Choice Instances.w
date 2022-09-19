[RTDialogueChoices::] Dialogue Choice Instances.

To compile any dialogue details in the instances submodule.

@h Compilation data for dialogue choices.
Each |dialogue_choice| object contains this data:

=
typedef struct dialogue_choice_compilation_data {
	struct parse_node *where_created;
	struct inter_name *choice_array_iname;
	struct inter_name *available_fn_iname;
	struct inter_name *action_match_fn_iname;
} dialogue_choice_compilation_data;

dialogue_choice_compilation_data RTDialogueChoices::new(parse_node *PN, dialogue_choice *dc) {
	dialogue_choice_compilation_data dccd;
	dccd.where_created = PN;
	dccd.choice_array_iname = NULL;
	dccd.available_fn_iname = NULL;
	dccd.action_match_fn_iname = NULL;
	return dccd;
}

package_request *RTDialogueChoices::package(dialogue_choice *dc) {
	if (dc->as_instance == NULL) internal_error("not available yet");
	return RTInstances::package(dc->as_instance);
}

inter_name *RTDialogueChoices::choice_array_iname(dialogue_choice *dc) {
	if (dc->compilation_data.choice_array_iname == NULL)
		dc->compilation_data.choice_array_iname =
			Hierarchy::make_iname_in(CHOICE_ARRAY_HL, RTDialogueChoices::package(dc));
	return dc->compilation_data.choice_array_iname;
}

inter_name *RTDialogueChoices::available_fn_iname(dialogue_choice *dc) {
	if (dc->compilation_data.available_fn_iname == NULL)
		dc->compilation_data.available_fn_iname =
			Hierarchy::make_iname_in(CHOICE_AVAILABLE_FN_HL, RTDialogueChoices::package(dc));
	return dc->compilation_data.available_fn_iname;
}

inter_name *RTDialogueChoices::action_match_fn_iname(dialogue_choice *dc) {
	if (dc->compilation_data.action_match_fn_iname == NULL)
		dc->compilation_data.action_match_fn_iname =
			Hierarchy::make_iname_in(CHOICE_ACTION_MATCH_FN_HL, RTDialogueChoices::package(dc));
	return dc->compilation_data.action_match_fn_iname;
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
	package_request *PR = RTDialogueChoices::package(dc);
	int make_availability_function = FALSE;
	wording APW = EMPTY_WORDING;
	@<Scan the clauses further@>;

	inter_name *array_iname = RTDialogueChoices::choice_array_iname(dc);
	Hierarchy::apply_metadata_from_iname(PR, CHOICE_ARRAY_MD_HL, array_iname);
	packaging_state save = EmitArrays::begin_word(array_iname, K_value);
	@<Write the type entry@>;
	@<Write the availability entry@>;
	@<Write the details entry@>;
	EmitArrays::end(save);

	if (make_availability_function) @<Compile the available function@>;
	if (Wordings::nonempty(APW)) @<Compile the action-matching function@>;
}

@<Scan the clauses further@> =
	for (parse_node *clause = dc->choice_at->down; clause; clause = clause->next) {
		if (Node::is(clause, DIALOGUE_CLAUSE_NT)) {
			int c = Annotations::read_int(clause, dialogue_choice_clause_ANNOT);
			switch (c) {
				 case IF_DCC:
				 case UNLESS_DCC:
					make_availability_function = TRUE;
					break;
			}
		}
	}

@<Write the type entry@> =
	EmitArrays::numeric_entry((inter_ti) dc->selection_type);

@<Write the availability entry@> =
	if (make_availability_function) {
		EmitArrays::iname_entry(RTDialogueChoices::available_fn_iname(dc));
	} else {
		EmitArrays::numeric_entry(0);
	}

@<Write the details entry@> =
	wording CW = Node::get_text(dc->selection);
	switch (dc->selection_type) {
		case TEXTUAL_DSEL:
			if (<s-literal>(CW)) {
				parse_node *text = <<rp>>;
				CompileValues::to_array_entry_of_kind(text, K_text);
			} else {
				internal_error("somehow not a literal text");
			}
			break;
		case PERFORM_DSEL:
			EmitArrays::iname_entry(RTInstances::value_iname(dc->to_perform->as_instance));
			break;
		case INSTEAD_OF_DSEL:
		case AFTER_DSEL:
		case BEFORE_DSEL:
			if (<dialogue-selection>(CW)) {
				APW = GET_RW(<dialogue-selection>, 1);
				EmitArrays::iname_entry(RTDialogueChoices::action_match_fn_iname(dc));
			} else {
				internal_error("somehow didn't reparse");
			}
			break;		
		default:
			EmitArrays::numeric_entry(0);
			break;
	}

@<Compile the available function@> =
	packaging_state save = Functions::begin(RTDialogueChoices::available_fn_iname(dc));
	@<Check the if and unless conditions@>;
	EmitCode::rtrue();
	Functions::end(save);

@<Check the if and unless conditions@> =
	current_sentence = dc->choice_at;
	for (parse_node *clause = dc->choice_at->down; clause; clause = clause->next) {
		wording CW = Node::get_text(clause);
		int c = Annotations::read_int(clause, dialogue_choice_clause_ANNOT);
		switch (c) {
			case IF_DCC:
			case UNLESS_DCC: {
				<dialogue-choice-clause>(CW);
				wording A = GET_RW(<dialogue-choice-clause>, 1);
				if (<s-condition>(A)) {
					parse_node *cond = <<rp>>;
					if (Dash::validate_conditional_clause(cond)) {
						EmitCode::inv(IF_BIP);
						EmitCode::down();
							if (c == IF_DCC) {
								EmitCode::inv(NOT_BIP);
								EmitCode::down();
							}
							CompileValues::to_code_val_of_kind(cond, K_truth_state);
							if (c == IF_DCC) {
								EmitCode::up();
							}
							EmitCode::code();
							EmitCode::down();
								EmitCode::rfalse();
							EmitCode::up();
						EmitCode::up();
					}
				}				
				break;
			}
		}
	}

@<Compile the action-matching function@> =
	packaging_state save = Functions::begin(RTDialogueChoices::action_match_fn_iname(dc));
	if (<s-action-pattern-as-value>(APW)) {
		parse_node *cond = <<rp>>;
		LOG("Match clause $T\n", cond);
		if (Dash::check_condition(cond)) {
			LOG("After dash $T\n", cond);
			EmitCode::inv(IF_BIP);
			EmitCode::down();
				CompileValues::to_code_val_of_kind(cond, K_truth_state);
				EmitCode::code();
				EmitCode::down();
					EmitCode::rtrue();
				EmitCode::up();
			EmitCode::up();
		}
	}
	EmitCode::rfalse();
	Functions::end(save);
