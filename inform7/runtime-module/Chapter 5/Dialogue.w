[RTDialogue::] Dialogue.

To compile the dialogue submodule for a compilation unit, which contains
something to be worked out.

@h Compilation data for dialogue beats.
Each |dialogue_beat| object contains this data:

=
typedef struct dialogue_beat_compilation_data {
	struct parse_node *where_created;
	struct inter_name *usage_filter_function;
} dialogue_beat_compilation_data;

dialogue_beat_compilation_data RTDialogue::new_beat(parse_node *PN, dialogue_beat *db) {
	dialogue_beat_compilation_data dbcd;
	dbcd.where_created = PN;
	dbcd.usage_filter_function = NULL;

	return dbcd;
}

inter_name *RTDialogue::beat_filter(dialogue_beat *db) {
	if (db->compilation_data.usage_filter_function == NULL)
		db->compilation_data.usage_filter_function =
			Hierarchy::make_iname_in(BEAT_FILTER_FN_HL, RTInstances::package(db->as_instance));
	return db->compilation_data.usage_filter_function;
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

@h Compilation data for dialogue choices.
Each |dialogue_choice| object contains this data:

=
typedef struct dialogue_choice_compilation_data {
	struct parse_node *where_created;
} dialogue_choice_compilation_data;

dialogue_choice_compilation_data RTDialogue::new_choice(parse_node *PN, dialogue_choice *dc) {
	dialogue_choice_compilation_data dlcd;
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
	LOG("Beat %d = %W name '%W' scene '%W'\n",
		db->allocation_id, Node::get_text(current_sentence), db->beat_name, db->scene_name);
	RTDialogue::log_r(db->root);
	packaging_state save = Functions::begin(RTDialogue::beat_filter(db));
	local_variable *latest = LocalVariables::new_internal_commented(I"latest", I"most recently performed beat");
	LocalVariables::set_kind(latest, K_dialogue_beat);
	local_variable *pool = LocalVariables::new_internal_commented(I"pool", I"pool of live topics");
	inter_symbol *latest_s = LocalVariables::declare(latest);
	inter_symbol *pool_s = LocalVariables::declare(pool);
	if (db->immediately_after) {
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(NE_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, latest_s);
				EmitCode::val_number(0);
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
				@<Return true if latest matches the immediately after description@>;
				EmitCode::rfalse();
			EmitCode::up();
		EmitCode::up();
	}
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, pool_s);
		EmitCode::val_number(0);
	EmitCode::up();
	EmitCode::rfalse();
	Functions::end(save);
}

@<Return true if latest matches the immediately after description@> =
	EmitCode::inv(IF_BIP);
	EmitCode::down();
		LOG("IA cond is $T\n", db->immediately_after);
		instance *I = Rvalues::to_instance(db->immediately_after);
		if (I) {
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, latest_s);
				EmitCode::val_iname(K_dialogue_beat, RTInstances::value_iname(I));
			EmitCode::up();				
		} else {
			pcalc_prop *prop = Descriptions::to_proposition(db->immediately_after);
			if (prop) {
				CompilePropositions::to_test_as_condition(Lvalues::new_LOCAL_VARIABLE(EMPTY_WORDING, latest), prop);
			} else {
				internal_error("cannot test");
			}
		}
		EmitCode::code();
		EmitCode::down();
			EmitCode::rtrue();
		EmitCode::up();
	EmitCode::up();

@ =
void RTDialogue::line_compilation_agent(compilation_subtask *ct) {
	dialogue_line *dl = RETRIEVE_POINTER_dialogue_line(ct->data);
	current_sentence = dl->compilation_data.where_created;
	LOG("Line %d = %W name '%W'\n", dl->allocation_id, Node::get_text(current_sentence), dl->line_name);
}

void RTDialogue::log_r(dialogue_node *dn) {
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
			RTDialogue::log_r(dn->child_node);
			LOG_OUTDENT;
		}
		dn = dn->next_node;
	}
}
