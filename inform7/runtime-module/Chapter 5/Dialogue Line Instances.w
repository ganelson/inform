[RTDialogueLines::] Dialogue.

To compile any dialogue details in the instances submodule.

@h Compilation data for dialogue lines.
Each |dialogue_line| object contains this data:

=
typedef struct dialogue_line_compilation_data {
	struct parse_node *where_created;
	struct inter_name *available_fn_iname;
	struct inter_name *speaker_fn_iname;
	struct inter_name *mentioning_fn_iname;
	struct inter_name *action_fn_iname;
	struct inter_name *line_array_iname;
} dialogue_line_compilation_data;

dialogue_line_compilation_data RTDialogueLines::new(parse_node *PN, dialogue_line *dl) {
	dialogue_line_compilation_data dlcd;
	dlcd.where_created = PN;
	dlcd.available_fn_iname = NULL;
	dlcd.speaker_fn_iname = NULL;
	dlcd.mentioning_fn_iname = NULL;
	dlcd.action_fn_iname = NULL;
	dlcd.line_array_iname = NULL;
	return dlcd;
}

package_request *RTDialogueLines::package(dialogue_line *dl) {
	if (dl->as_instance == NULL) internal_error("not available yet");
	return RTInstances::package(dl->as_instance);
}

inter_name *RTDialogueLines::line_array_iname(dialogue_line *dl) {
	if (dl->compilation_data.line_array_iname == NULL)
		dl->compilation_data.line_array_iname =
			Hierarchy::make_iname_in(LINE_ARRAY_HL, RTDialogueLines::package(dl));
	return dl->compilation_data.line_array_iname;
}

inter_name *RTDialogueLines::available_fn_iname(dialogue_line *dl) {
	if (dl->compilation_data.available_fn_iname == NULL)
		dl->compilation_data.available_fn_iname =
			Hierarchy::make_iname_in(LINE_AVAILABLE_FN_HL, RTDialogueLines::package(dl));
	return dl->compilation_data.available_fn_iname;
}

inter_name *RTDialogueLines::speaker_fn_iname(dialogue_line *dl) {
	if (dl->compilation_data.speaker_fn_iname == NULL)
		dl->compilation_data.speaker_fn_iname =
			Hierarchy::make_iname_in(LINE_SPEAKER_FN_HL, RTDialogueLines::package(dl));
	return dl->compilation_data.speaker_fn_iname;
}

inter_name *RTDialogueLines::mentioning_fn_iname(dialogue_line *dl) {
	if (dl->compilation_data.mentioning_fn_iname == NULL)
		dl->compilation_data.mentioning_fn_iname =
			Hierarchy::make_iname_in(LINE_MENTIONING_FN_HL, RTDialogueLines::package(dl));
	return dl->compilation_data.mentioning_fn_iname;
}

inter_name *RTDialogueLines::action_fn_iname(dialogue_line *dl) {
	if (dl->compilation_data.action_fn_iname == NULL)
		dl->compilation_data.action_fn_iname =
			Hierarchy::make_iname_in(LINE_ACTION_FN_HL, RTDialogueLines::package(dl));
	return dl->compilation_data.action_fn_iname;
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
	package_request *PR = RTDialogueLines::package(dl);
	inter_name *array_iname = RTDialogueLines::line_array_iname(dl);
	int make_availability_function = FALSE, make_speaker_function = FALSE, make_mentioning_function = FALSE, make_action_function = FALSE;
	int ending = FALSE, ending_finally = FALSE;
	wording EW = EMPTY_WORDING;
	linked_list *now_list = NEW_LINKED_LIST(parse_node);
	linked_list *before_list = NEW_LINKED_LIST(parse_node);
	linked_list *after_list = NEW_LINKED_LIST(parse_node);
	@<Scan the clauses further@>;
	if (ending) make_action_function = TRUE;
	Hierarchy::apply_metadata_from_iname(PR, LINE_ARRAY_MD_HL, array_iname);
	packaging_state save = EmitArrays::begin_word(array_iname, K_value);
	@<Write the availability entry@>;
	@<Write the speaker entry@>;
	@<Write the interlocutor entry@>;
	@<Write the speech entry@>;
	@<Write the style entry@>;
	@<Write the mentioning entry@>;
	@<Write the action entry@>;
	@<Write the flags entry@>;
	EmitArrays::end(save);
	if (make_availability_function) @<Compile the available function@>;
	if (make_speaker_function) @<Compile the speaker function@>;
	if (make_mentioning_function) @<Compile the mentioning function@>;
	if (make_action_function) @<Compile the action function@>;
}

@<Scan the clauses further@> =
	for (parse_node *clause = dl->line_at->down; clause; clause = clause->next) {
		if (Node::is(clause, DIALOGUE_CLAUSE_NT)) {
			wording CW = Node::get_text(clause);
			int c = Annotations::read_int(clause, dialogue_line_clause_ANNOT);
			switch (c) {
				case ENDING_DLC: {
					ending = TRUE;
					break;
				}
				case ENDING_SAYING_DLC: {
					ending = TRUE;
					<dialogue-line-clause>(CW);
					EW = GET_RW(<dialogue-line-clause>, 1);
					break;
				}
				case ENDING_FINALLY_DLC:
					ending = TRUE;
					ending_finally = TRUE;
					break;
				case ENDING_FINALLY_SAYING_DLC: {
					ending = TRUE;
					ending_finally = TRUE;
					<dialogue-line-clause>(CW);
					EW = GET_RW(<dialogue-line-clause>, 1);
					break;
				}
				case NOW_DLC:
					ADD_TO_LINKED_LIST(clause, parse_node, now_list);
					break;
				case BEFORE_DLC:
					ADD_TO_LINKED_LIST(clause, parse_node, before_list);
					break;
				case AFTER_DLC:
					ADD_TO_LINKED_LIST(clause, parse_node, after_list);
					break;
			}
		}
	}

@<Write the availability entry@> =
	int conditions = 0;
	for (parse_node *clause = dl->line_at->down; clause; clause = clause->next) {
		int c = Annotations::read_int(clause, dialogue_line_clause_ANNOT);
		if ((c == IF_DLC) || (c == UNLESS_DLC)) conditions++;
	}	
	if (conditions > 0) {
		make_availability_function = TRUE;
		EmitArrays::iname_entry(RTDialogueLines::available_fn_iname(dl));
	} else {
		EmitArrays::numeric_entry(0);
	}

@<Write the speaker entry@> =
	if (dl->speaker_description) {
		instance *I = Rvalues::to_instance(dl->speaker_description);
		if (I) {
			EmitArrays::iname_entry(RTInstances::value_iname(I));
		} else {
			make_speaker_function = TRUE;
			EmitArrays::iname_entry(RTDialogueLines::speaker_fn_iname(dl));
		}
	} else {
		EmitArrays::numeric_entry(0);
	}

@<Write the interlocutor entry@> =
	if (dl->interlocutor) {
		EmitArrays::iname_entry(RTInstances::value_iname(dl->interlocutor));
	} else {
		EmitArrays::numeric_entry(0);
	}

@<Write the speech entry@> =
	if (<s-literal>(dl->speech_text)) {
		parse_node *text = <<rp>>;
		CompileValues::to_array_entry_of_kind(text, K_text);
	} else {
		internal_error("somehow not a literal text");
	}

@<Write the style entry@> =
	EmitArrays::iname_entry(RTInstances::value_iname(dl->how_performed->as_instance));

@<Write the mentioning entry@> =
	int L = LinkedLists::len(dl->mentioning);
	if (L == 0) {
		EmitArrays::numeric_entry(0);
	} else if ((L == 1) && (Rvalues::to_instance(FIRST_IN_LINKED_LIST(parse_node, dl->mentioning)))) {
		instance *I = Rvalues::to_instance(FIRST_IN_LINKED_LIST(parse_node, dl->mentioning));
		EmitArrays::iname_entry(RTInstances::value_iname(I));
	} else {
		make_mentioning_function = TRUE;
		EmitArrays::iname_entry(RTDialogueLines::mentioning_fn_iname(dl));
	}

@<Write the action entry@> =
	if ((LinkedLists::len(now_list) == 0) &&
		(LinkedLists::len(before_list) == 0) &&
		(LinkedLists::len(after_list) == 0))
		make_action_function = TRUE;
	if (make_action_function) {
		EmitArrays::iname_entry(RTDialogueLines::action_fn_iname(dl));
	} else {
		EmitArrays::numeric_entry(0);
	}

@<Write the flags entry@> =
	inter_ti flags = 0;
	if (dl->narration) flags |= 1;
	if (dl->without_speaking) flags |= 2;
	if (ending) flags |= 4;
	if (ending_finally) flags |= 8;

@<Compile the available function@> =
	packaging_state save = Functions::begin(RTDialogueLines::available_fn_iname(dl));
	@<Check the if and unless conditions@>;
	EmitCode::rtrue();
	Functions::end(save);

@<Check the if and unless conditions@> =
	current_sentence = dl->line_at;
	for (parse_node *clause = dl->line_at->down; clause; clause = clause->next) {
		wording CW = Node::get_text(clause);
		int c = Annotations::read_int(clause, dialogue_line_clause_ANNOT);
		switch (c) {
			case IF_DLC:
			case UNLESS_DLC: {
				<dialogue-beat-clause>(CW);
				wording A = GET_RW(<dialogue-beat-clause>, 1);
				if (<s-condition>(A)) {
					parse_node *cond = <<rp>>;
					if (Dash::validate_conditional_clause(cond)) {
						EmitCode::inv(IF_BIP);
						EmitCode::down();
							if (c == IF_DLC) {
								EmitCode::inv(NOT_BIP);
								EmitCode::down();
							}
							CompileValues::to_code_val_of_kind(cond, K_truth_state);
							if (c == IF_DLC) {
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

@<Compile the speaker function@> =
	packaging_state save = Functions::begin(RTDialogueLines::speaker_fn_iname(dl));
	local_variable *speaker = LocalVariables::new_internal_commented(I"speaker", I"potential speaker");
	inter_symbol *speaker_s = LocalVariables::declare(speaker);
	parse_node *desc = dl->speaker_description;
	instance *I = Rvalues::to_instance(desc);
	EmitCode::inv(IF_BIP);
	EmitCode::down();
		if (I) {
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, speaker_s);
				EmitCode::val_iname(K_value, RTInstances::value_iname(I));
			EmitCode::up();		
		} else {
			pcalc_prop *prop = Descriptions::to_proposition(desc);
			if (prop) {
				TypecheckPropositions::type_check(prop,
					TypecheckPropositions::tc_no_problem_reporting());
				CompilePropositions::to_test_as_condition(
					Lvalues::new_LOCAL_VARIABLE(EMPTY_WORDING, speaker), prop);
			} else {
				internal_error("cannot test");
			}
		}	
		EmitCode::code();
		EmitCode::down();
			EmitCode::rtrue();
		EmitCode::up();
	EmitCode::up();					
	EmitCode::rfalse();
	Functions::end(save);

@<Compile the mentioning function@> =
	packaging_state save = Functions::begin(RTDialogueLines::mentioning_fn_iname(dl));
	local_variable *obj = LocalVariables::new_internal_commented(I"obj", I"mentioned object");
	inter_symbol *obj_s = LocalVariables::declare(obj);
	parse_node *desc;
	LOOP_OVER_LINKED_LIST(desc, parse_node, dl->mentioning) {
		instance *I = Rvalues::to_instance(desc);
		if (I) {
			EmitCode::call(Hierarchy::find(DIRECTOR_ADD_LIVE_SUBJECT_LIST_HL));
			EmitCode::down();
				EmitCode::val_iname(K_value, RTInstances::value_iname(I));
			EmitCode::up();
		} else {
			CompileLoops::through_matches(desc, obj);
			EmitCode::code();
			EmitCode::down();
				EmitCode::call(Hierarchy::find(DIRECTOR_ADD_LIVE_SUBJECT_LIST_HL));
				EmitCode::down();
					EmitCode::val_symbol(K_value, obj_s);
				EmitCode::up();
			EmitCode::up();
			EmitCode::up();
		}	
	}
	Functions::end(save);

@<Compile the action function@> =
	packaging_state save = Functions::begin(RTDialogueLines::action_fn_iname(dl));
	local_variable *task = LocalVariables::new_internal_commented(I"task", I"what to do");
	inter_symbol *task_s = LocalVariables::declare(task);
	local_variable *speaker = LocalVariables::new_internal_commented(I"speaker", I"who says this");
	LocalVariables::set_kind(speaker, K_object);
	EmitCode::inv(SWITCH_BIP);
	EmitCode::down();
		EmitCode::val_symbol(K_value, task_s);
		EmitCode::code();
		EmitCode::down();
			if ((LinkedLists::len(now_list) > 0) || (ending)) {
				EmitCode::inv(CASE_BIP);
				EmitCode::down();
					EmitCode::val_number(1);
					EmitCode::code();
					EmitCode::down();
						parse_node *clause;
						LOOP_OVER_LINKED_LIST(clause, parse_node, now_list)
							@<Take action on this now clause@>;
						if (ending)
							@<Take action to end the story@>;
					EmitCode::up();
				EmitCode::up();
			}
			if (LinkedLists::len(before_list) > 0) {
				EmitCode::inv(CASE_BIP);
				EmitCode::down();
					EmitCode::val_number(2);
					EmitCode::code();
					EmitCode::down();
						parse_node *clause;
						LOOP_OVER_LINKED_LIST(clause, parse_node, before_list)
							@<Take action on this action clause@>;
					EmitCode::up();
				EmitCode::up();
			}
			if (LinkedLists::len(after_list) > 0) {
				EmitCode::inv(CASE_BIP);
				EmitCode::down();
					EmitCode::val_number(3);
					EmitCode::code();
					EmitCode::down();
						parse_node *clause;
						LOOP_OVER_LINKED_LIST(clause, parse_node, after_list)
							@<Take action on this action clause@>;
					EmitCode::up();
				EmitCode::up();
			}
		EmitCode::up();
	EmitCode::up();
	EmitCode::rtrue();
	Functions::end(save);

@<Take action on this now clause@> =
	wording CW = Node::get_text(clause);
	<dialogue-line-clause>(CW);
	wording NW = GET_RW(<dialogue-line-clause>, 1);
	CompileBlocksAndLines::compile_a_now(NW);

@<Take action on this action clause@> =
	wording CW = Node::get_text(clause);
	<dialogue-line-clause>(CW);
	wording AW = GET_RW(<dialogue-line-clause>, 1);
	if (<s-action-pattern-as-value>(AW)) {
		parse_node *supplied = <<rp>>;
		if (Dash::check_value(supplied, K_stored_action)) {
			if (Rvalues::is_CONSTANT_of_kind(supplied, K_stored_action)) {
				explicit_action *ea = Node::get_constant_explicit_action(supplied);
				if (ea->actor == NULL) {
					parse_node *actor = Lvalues::new_LOCAL_VARIABLE(EMPTY_WORDING, speaker);
					Dash::check_value(actor, K_object);
					ea->actor = Lvalues::new_LOCAL_VARIABLE(EMPTY_WORDING, speaker);
				}
				CompileRvalues::compile_explicit_action(ea, FALSE);
			} else {
				EmitCode::call(Hierarchy::find(STORED_ACTION_TY_TRY_HL));
				EmitCode::down();
					CompileValues::to_code_val_of_kind(supplied, K_stored_action);
				EmitCode::up();
			}
			EmitCode::inv(IF_BIP);
			EmitCode::down();
				EmitCode::inv(NE_BIP);
				EmitCode::down();
					EmitCode::val_iname(K_value,
						Hierarchy::find(REASON_THE_ACTION_FAILED_HL));
					EmitCode::val_number(0);
				EmitCode::up();
				EmitCode::code();
				EmitCode::down();
					EmitCode::rfalse();
				EmitCode::up();
			EmitCode::up();
		} else {
			internal_error("oops");
		}
	} else {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, AW);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(...));
		Problems::issue_problem_segment(
			"This dialogue line (%1) wants to try the action '%2', "
			"but I can't make sense of that.");
		Problems::issue_problem_end();
	}

@<Take action to end the story@> =
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_iname(K_value, Hierarchy::find(DEADFLAG_HL));
		if (Wordings::nonempty(EW)) {
			if (<s-literal>(EW)) {
				parse_node *text = <<rp>>;
				CompileValues::to_code_val_of_kind(text, K_text);
			} else {
				internal_error("somehow not a literal text");
			}
		} else {
			EmitCode::val_number(3);
		}
	EmitCode::up();
	if (Wordings::nonempty(EW)) {
		EmitCode::call(Hierarchy::find(BLKVALUEINCREFCOUNTPRIMITIVE_HL));
		EmitCode::down();
			EmitCode::val_iname(K_value, Hierarchy::find(DEADFLAG_HL));
		EmitCode::up();
	}
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_iname(K_value, Hierarchy::find(STORY_COMPLETE_HL));
		if (ending_finally) {
			EmitCode::val_number(1);
		} else {
			EmitCode::val_number(0);
		}
	EmitCode::up();
