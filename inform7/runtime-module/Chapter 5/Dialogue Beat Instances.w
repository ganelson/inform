[RTDialogueBeats::] Dialogue Beat Instances.

To compile any dialogue details in the instances submodule.

@h Compilation data for dialogue beats.
Each |dialogue_beat| object contains this data:

=
typedef struct dialogue_beat_compilation_data {
	struct parse_node *where_created;
	struct inter_name *available_function;
	struct inter_name *relevant_function;
	struct inter_name *structure_array;
	struct inter_name *beat_array_iname;
} dialogue_beat_compilation_data;

dialogue_beat_compilation_data RTDialogueBeats::new_beat(parse_node *PN, dialogue_beat *db) {
	dialogue_beat_compilation_data dbcd;
	dbcd.where_created = PN;
	dbcd.available_function = NULL;
	dbcd.relevant_function = NULL;
	dbcd.structure_array = NULL;
	dbcd.beat_array_iname = NULL;
	return dbcd;
}

package_request *RTDialogueBeats::package(dialogue_beat *db) {
	if (db->as_instance == NULL) internal_error("not available yet");
	return RTInstances::package(db->as_instance);
}

inter_name *RTDialogueBeats::iname(dialogue_beat *db) {
	return RTInstances::value_iname(db->as_instance);
}

inter_name *RTDialogueBeats::available_fn_iname(dialogue_beat *db) {
	if (db->compilation_data.available_function == NULL)
		db->compilation_data.available_function =
			Hierarchy::make_iname_in(BEAT_AVAILABLE_FN_HL, RTDialogueBeats::package(db));
	return db->compilation_data.available_function;
}

inter_name *RTDialogueBeats::relevant_fn_iname(dialogue_beat *db) {
	if (db->compilation_data.relevant_function == NULL)
		db->compilation_data.relevant_function =
			Hierarchy::make_iname_in(BEAT_RELEVANT_FN_HL, RTDialogueBeats::package(db));
	return db->compilation_data.relevant_function;
}

inter_name *RTDialogueBeats::structure_array_iname(dialogue_beat *db) {
	if (db->compilation_data.structure_array == NULL)
		db->compilation_data.structure_array =
			Hierarchy::make_iname_in(BEAT_STRUCTURE_HL, RTDialogueBeats::package(db));
	return db->compilation_data.structure_array;
}

inter_name *RTDialogueBeats::beat_array_iname(dialogue_beat *db) {
	if (db->compilation_data.beat_array_iname == NULL)
		db->compilation_data.beat_array_iname =
			Hierarchy::make_iname_in(BEAT_ARRAY_HL, RTDialogueBeats::package(db));
	return db->compilation_data.beat_array_iname;
}

@h Compilation of dialogue.

=
void RTDialogueBeats::compile(void) {
	int c = 0;
	dialogue_beat *db;
	LOOP_OVER(db, dialogue_beat) {
		text_stream *desc = Str::new();
		WRITE_TO(desc, "dialogue beat %d", db->allocation_id);
		Sequence::queue(&RTDialogueBeats::beat_compilation_agent, STORE_POINTER_dialogue_beat(db), desc);
		c++;
	}
	inter_name *iname = Hierarchy::find(AFTER_ACTION_HOOK_HL);
	if (c > 0) {
		Emit::iname_constant(iname, K_value, Hierarchy::find(DIRECTOR_AFTER_ACTION_HL));
	} else {
		Emit::iname_constant(iname, K_value, Hierarchy::find(DO_NOTHING_HL));
	}
	Hierarchy::make_available(iname);
}

void RTDialogueBeats::compile_starting_beat_entry(void) {
	dialogue_beat *db, *starting_db = NULL;
	LOOP_OVER(db, dialogue_beat) {
		if (db->starting_beat) starting_db = db;
	}
	if (starting_db)
		EmitArrays::iname_entry(RTInstances::value_iname(starting_db->as_instance));
	else
		EmitArrays::numeric_entry(0);
}

void RTDialogueBeats::beat_compilation_agent(compilation_subtask *ct) {
	dialogue_beat *db = RETRIEVE_POINTER_dialogue_beat(ct->data);
	current_sentence = db->compilation_data.where_created;
	package_request *PR = RTDialogueBeats::package(db);
	inter_name *array_iname = RTDialogueBeats::beat_array_iname(db);
	Hierarchy::apply_metadata_from_iname(PR, BEAT_ARRAY_MD_HL, array_iname);
	int make_availability_function = FALSE, make_relevance_function = FALSE;

	packaging_state save = EmitArrays::begin_word(array_iname, K_value);
	@<Write the availability entry@>;
	@<Write the relevance entry@>;
	@<Write the structure entry@>;
	@<Write the scene entry@>;
	@<Write the first speaker entry@>;
	@<Write the speaker list@>;
	EmitArrays::end(save);

	if (make_availability_function) @<Compile the available function@>;
	if (make_relevance_function) @<Compile the relevant function@>;
	@<Compile the structure array@>;
}

@<Write the availability entry@> =
	int conditions = 0;
	for (parse_node *clause = db->cue_at->down; clause; clause = clause->next) {
		int c = Annotations::read_int(clause, dialogue_beat_clause_ANNOT);
		if ((c == IF_DBC) || (c == UNLESS_DBC)) conditions++;
	}	
	if ((db->immediately_after) ||
		(LinkedLists::len(db->some_time_after) > 0) ||
		(LinkedLists::len(db->some_time_before) > 0) ||
		(conditions > 0) ||
		(db->during_scene)) {
		make_availability_function = TRUE;
		EmitArrays::iname_entry(RTDialogueBeats::available_fn_iname(db));
	} else {
		EmitArrays::numeric_entry(0);
	}

@<Write the relevance entry@> =
	if (LinkedLists::len(db->about_list) > 0) {
		make_relevance_function = TRUE;
		EmitArrays::iname_entry(RTDialogueBeats::relevant_fn_iname(db));
	} else {
		EmitArrays::numeric_entry(0);
	}

@<Write the structure entry@> =
	EmitArrays::iname_entry(RTDialogueBeats::structure_array_iname(db));

@<Write the scene entry@> =
	if (db->as_scene)
		EmitArrays::iname_entry(RTInstances::value_iname(Scenes::get_instance(db->as_scene)));
	else
		EmitArrays::numeric_entry(0);

@<Write the first speaker entry@> =
	int player_speaks = -1;
	linked_list *L = NEW_LINKED_LIST(instance);
	RTDialogueBeats::find_speakers_r(L, db->root, &player_speaks);
	if (player_speaks == 0) EmitArrays::numeric_entry(1);
	else if (LinkedLists::len(L) > 0) {
		instance *I;
		LOOP_OVER_LINKED_LIST(I, instance, L) {
			EmitArrays::iname_entry(RTInstances::value_iname(I));
			break;
		}
	} else EmitArrays::numeric_entry(0);

@<Write the speaker list@> =
	int player_speaks = -1;
	linked_list *L = db->required;
	if ((LinkedLists::len(L) == 0) && (db->requiring_nothing == FALSE)) {
		L = NEW_LINKED_LIST(instance);
		RTDialogueBeats::find_speakers_r(L, db->root, &player_speaks);
	}
	if (player_speaks == 0) EmitArrays::numeric_entry(1);
	instance *I;
	LOOP_OVER_LINKED_LIST(I, instance, L)
		EmitArrays::iname_entry(RTInstances::value_iname(I));
	EmitArrays::numeric_entry(0);

@<Compile the available function@> =
	packaging_state save = Functions::begin(RTDialogueBeats::available_fn_iname(db));
	local_variable *latest = LocalVariables::new_internal_commented(I"latest", I"most recently performed beat");
	LocalVariables::set_kind(latest, K_dialogue_beat);
	inter_symbol *latest_s = LocalVariables::declare(latest);
	if (db->during_scene) @<Check the scene is currently playing@>;
	if (db->immediately_after) @<Check the immediately after condition@>;
	@<Check the after and before conditions@>;
	@<Check the if and unless conditions@>;
	EmitCode::rtrue();
	Functions::end(save);

@<Check the scene is currently playing@> =
	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(NE_BIP);
		EmitCode::down();
			EmitCode::inv(LOOKUP_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_object, Hierarchy::find(SCENE_STATUS_HL));
				EmitCode::val_number((inter_ti) db->during_scene->allocation_id);
			EmitCode::up();
			EmitCode::val_number(1);
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			EmitCode::rfalse();
		EmitCode::up();
	EmitCode::up();

@<Check the immediately after condition@> =
	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(NE_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, latest_s);
			EmitCode::val_number(0);
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			@<Return false if latest does not match the immediately after description@>;
		EmitCode::up();
	EmitCode::up();

@<Return false if latest does not match the immediately after description@> =
	EmitCode::inv(IF_BIP);
	EmitCode::down();
		instance *I = Rvalues::to_instance(db->immediately_after);
		if (I) {
			EmitCode::inv(NE_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, latest_s);
				EmitCode::val_iname(K_dialogue_beat, RTInstances::value_iname(I));
			EmitCode::up();				
		} else {
			pcalc_prop *prop = Propositions::negate(Descriptions::to_proposition(db->immediately_after));
			if (prop) {
				TypecheckPropositions::type_check(prop,
					TypecheckPropositions::tc_no_problem_reporting());
				CompilePropositions::to_test_as_condition(Lvalues::new_LOCAL_VARIABLE(EMPTY_WORDING, latest), prop);
			} else {
				internal_error("cannot test");
			}
		}
		EmitCode::code();
		EmitCode::down();
			EmitCode::rfalse();
		EmitCode::up();
	EmitCode::up();

@<Check the after and before conditions@> =
	parse_node *desc;
	LOOP_OVER_LINKED_LIST(desc, parse_node, db->some_time_after) {
		int negate_me = FALSE;
		@<Work out proposition@>;
	}
	LOOP_OVER_LINKED_LIST(desc, parse_node, db->some_time_before) {
		int negate_me = TRUE;
		@<Work out proposition@>;
	}

@<Work out proposition@> =
	instance *I = Rvalues::to_instance(desc);
	pcalc_prop *prop = NULL;
	adjective *adj = EitherOrProperties::as_adjective(P_performed);
	if (I) {
		prop = AdjectivalPredicates::new_atom(adj, negate_me, Terms::new_constant(desc));
	} else {
		pcalc_prop *exists = Atoms::QUANTIFIER_new(exists_quantifier, 0, 0);
		pcalc_prop *domain = KindPredicates::new_atom(K_dialogue_beat, Terms::new_variable(0));
		pcalc_prop *performed = AdjectivalPredicates::new_atom(adj, negate_me, Terms::new_variable(0));
		pcalc_prop *desc_prop = Descriptions::to_proposition(desc);
		prop = Propositions::concatenate(exists,
					Propositions::concatenate(domain,
						Propositions::concatenate(performed,
							desc_prop)));
	}
	prop = Propositions::negate(prop);
	EmitCode::inv(IF_BIP);
	EmitCode::down();
		TypecheckPropositions::type_check(prop,
			TypecheckPropositions::tc_no_problem_reporting());
		CompilePropositions::to_test_as_condition(NULL, prop);
		EmitCode::code();
		EmitCode::down();
			EmitCode::rfalse();
		EmitCode::up();
	EmitCode::up();

@<Check the if and unless conditions@> =
	current_sentence = db->cue_at;
	for (parse_node *clause = db->cue_at->down; clause; clause = clause->next) {
		wording CW = Node::get_text(clause);
		int c = Annotations::read_int(clause, dialogue_beat_clause_ANNOT);
		switch (c) {
			case IF_DBC:
			case UNLESS_DBC: {
				<dialogue-beat-clause>(CW);
				wording A = GET_RW(<dialogue-beat-clause>, 1);
				if (<s-condition>(A)) {
					parse_node *cond = <<rp>>;
					if (Dash::validate_conditional_clause(cond)) {
						EmitCode::inv(IF_BIP);
						EmitCode::down();
							if (c == IF_DBC) {
								EmitCode::inv(NOT_BIP);
								EmitCode::down();
							}
							CompileValues::to_code_val_of_kind(cond, K_truth_state);
							if (c == IF_DBC) {
								EmitCode::up();
							}
							EmitCode::code();
							EmitCode::down();
								EmitCode::rfalse();
							EmitCode::up();
						EmitCode::up();
					}
				} else {
					Problems::quote_source(1, current_sentence);
					Problems::quote_wording(2, A);
					StandardProblems::handmade_problem(Task::syntax_tree(), _p_(...));
					Problems::issue_problem_segment(
						"This dialogue beat (%1) seems to be performed depending "
						"on whether or not '%2', "
						"but I can't make sense of that condition.");
					Problems::issue_problem_end();
				}
				break;
			}
		}
	}

@<Compile the relevant function@> =
	packaging_state save = Functions::begin(RTDialogueBeats::relevant_fn_iname(db));
	local_variable *pool = LocalVariables::new_internal_commented(I"pool", I"pool of live topics");
	local_variable *set = LocalVariables::new_internal_commented(I"set", I"if true, make these relevant");
	local_variable *iv = LocalVariables::new_internal_commented(I"iv", I"index variable");
	local_variable *topic = LocalVariables::new_internal_commented(I"topic", I"live topic");
	inter_symbol *pool_s = LocalVariables::declare(pool);
	inter_symbol *set_s = LocalVariables::declare(set);
	inter_symbol *iv_s = LocalVariables::declare(iv);
	inter_symbol *topic_s = LocalVariables::declare(topic);
	@<Check the about list against the subject pool@>;
	EmitCode::rfalse();
	Functions::end(save);

@<Check the about list against the subject pool@> =
	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::val_symbol(K_value, set_s);
		EmitCode::code();
		EmitCode::down();
			parse_node *desc;
			LOOP_OVER_LINKED_LIST(desc, parse_node, db->about_list) {
				instance *I = Rvalues::to_instance(desc);
				if (I) {
					EmitCode::call(Hierarchy::find(DIRECTOR_ADD_LIVE_SUBJECT_LIST_HL));
					EmitCode::down();
						EmitCode::val_iname(K_value, RTInstances::value_iname(I));
					EmitCode::up();
				}
			}
			EmitCode::rtrue();
		EmitCode::up();
	EmitCode::up();
	
	inter_symbol *loop_label = EmitCode::reserve_label(I"about_loop");
	EmitCode::place_label(loop_label);
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, topic_s);
		EmitCode::inv(LOOKUP_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, pool_s);
			EmitCode::val_symbol(K_value, iv_s);
		EmitCode::up();
	EmitCode::up();
	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(NE_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, topic_s);
			EmitCode::val_number(0);
		EmitCode::up();		
		EmitCode::code();
		EmitCode::down();
			LOOP_OVER_LINKED_LIST(desc, parse_node, db->about_list) {
				instance *I = Rvalues::to_instance(desc);
				EmitCode::inv(IF_BIP);
				EmitCode::down();
					if (I) {
						EmitCode::inv(EQ_BIP);
						EmitCode::down();
							EmitCode::val_symbol(K_value, topic_s);
							EmitCode::val_iname(K_value, RTInstances::value_iname(I));
						EmitCode::up();		
					} else {
						pcalc_prop *prop = Descriptions::to_unbound_proposition(desc);
						if (prop) {
							TypecheckPropositions::type_check(prop,
								TypecheckPropositions::tc_no_problem_reporting());
							CompilePropositions::to_test_as_condition(
								Lvalues::new_LOCAL_VARIABLE(EMPTY_WORDING, topic), prop);
						} else {
							internal_error("cannot test");
						}
					}	
					EmitCode::code();
					EmitCode::down();
						EmitCode::rtrue();
					EmitCode::up();
				EmitCode::up();					
			}
			EmitCode::inv(POSTINCREMENT_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, iv_s);
			EmitCode::up();
			EmitCode::inv(JUMP_BIP);
			EmitCode::down();
				EmitCode::lab(loop_label);
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();
	EmitCode::rfalse();

@ And this is always present.

@<Compile the structure array@> =
	packaging_state save =
		EmitArrays::begin_word(RTDialogueBeats::structure_array_iname(db), K_value);
	RTDialogueBeats::compile_structure_r(db->root, 1);
	EmitArrays::numeric_entry(0);
	EmitArrays::end(save);

@ =
void RTDialogueBeats::compile_structure_r(dialogue_node *dn, inter_ti depth) {
	while (dn) {
		if (dn->if_line) {
			EmitArrays::numeric_entry(depth + 100);
			EmitArrays::iname_entry(RTInstances::value_iname(dn->if_line->as_instance));
		} else if (dn->if_choice) {
			EmitArrays::numeric_entry(depth + 200);
			EmitArrays::iname_entry(RTInstances::value_iname(dn->if_choice->as_instance));
		} else if (dn->if_decision) {
			EmitArrays::numeric_entry(depth + 300);
			EmitArrays::numeric_entry((inter_ti) (dn->if_decision->decision_type));
		} else internal_error("unimplemented dialogue node compilation");
		if (dn->child_node)
			RTDialogueBeats::compile_structure_r(dn->child_node, depth+1);
		dn = dn->next_node;
	}
}

@ =
void RTDialogueBeats::log_r(dialogue_node *dn) {
	while (dn) {
		if (dn->if_line)
			LOG("Line %d = %W\n",
				dn->if_line->allocation_id, Node::get_text(dn->if_line->compilation_data.where_created));
		if (dn->if_choice)
			LOG("Choice %d = %W\n",
				dn->if_choice->allocation_id, Node::get_text(dn->if_choice->compilation_data.where_created));
		if (dn->child_node) {
			if (dn->child_node->parent_node != dn) LOG("*** Broken parentage ***\n");
			LOG_INDENT;
			RTDialogueBeats::log_r(dn->child_node);
			LOG_OUTDENT;
		}
		dn = dn->next_node;
	}
}

@ =
void RTDialogueBeats::find_speakers_r(linked_list *L, dialogue_node *dn, int *player_speaks) {
	while (dn) {
		if (dn->if_line) {
			if (dn->if_line->speaker_is_player) {
				if (*player_speaks == -1) *player_speaks = LinkedLists::len(L);
			} else {
				instance *I = RTDialogueLines::speaker_instance(dn->if_line);
				if (I) {
					int already_have_this = FALSE;
					instance *J;
					LOOP_OVER_LINKED_LIST(J, instance, L)
						if (I == J) {
							already_have_this = TRUE;
							break;
						}
					if (already_have_this == FALSE)
						ADD_TO_LINKED_LIST(I, instance, L);
				}
			}
		}
		if (dn->child_node)
			RTDialogueBeats::find_speakers_r(L, dn->child_node, player_speaks);
		dn = dn->next_node;
	}
}
