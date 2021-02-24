[ParsingPlugin::] Parsing Plugin.

A plugin for command-parser support.

@ Inform provides extensive support for a command parser at runtime, and all of
that support is contained in the "parsing" plugin, which occupies this entire
chapter.

=
void ParsingPlugin::start(void) {
	ParsingNodes::nodes_and_annotations();

	PluginManager::plug(PRODUCTION_LINE_PLUG, ParsingPlugin::production_line);
	PluginManager::plug(MAKE_SPECIAL_MEANINGS_PLUG, ParsingPlugin::make_special_meanings);
	PluginManager::plug(NEW_VARIABLE_NOTIFY_PLUG, ParsingPlugin::new_variable_notify);
	PluginManager::plug(NEW_SUBJECT_NOTIFY_PLUG, ParsingPlugin::new_subject_notify);
	PluginManager::plug(NEW_PERMISSION_NOTIFY_PLUG, Visibility::new_permission_notify);
	PluginManager::plug(COMPLETE_MODEL_PLUG, ParsingPlugin::complete_model);
}

int ParsingPlugin::production_line(int stage, int debugging,
	stopwatch_timer *sequence_timer) {
	if (stage == INTER2_CSEQ) {
		BENCH(PL::Parsing::Tokens::General::write_parse_name_routines);
		BENCH(PL::Parsing::Lines::MistakeActionSub_routine);
		BENCH(PL::Parsing::Verbs::prepare);
		BENCH(PL::Parsing::Verbs::compile_conditions);
		BENCH(PL::Parsing::Tokens::Values::number);
		BENCH(PL::Parsing::Tokens::Values::truth_state);
		BENCH(PL::Parsing::Tokens::Values::time);
		BENCH(PL::Parsing::Tokens::Values::compile_type_gprs);
		if (debugging) {
			BENCH(PL::Parsing::TestScripts::write_text);
			BENCH(PL::Parsing::TestScripts::TestScriptSub_routine);
		} else {
			BENCH(PL::Parsing::TestScripts::TestScriptSub_stub_routine);
		}
	}
	if (stage == INTER3_CSEQ) {
		BENCH(PL::Parsing::Tokens::Filters::compile);
	}
	if (stage == INTER4_CSEQ) {
		BENCH(PL::Parsing::Verbs::compile_all);
		BENCH(PL::Parsing::Tokens::Filters::compile);
	}
	return FALSE;
}

int ParsingPlugin::make_special_meanings(void) {
	SpecialMeanings::declare(PL::Parsing::understand_as_SMF, I"understand-as", 1);
	return FALSE;
}

int ParsingPlugin::new_subject_notify(inference_subject *subj) {
	ATTACH_PLUGIN_DATA_TO_SUBJECT(parsing, subj, Visibility::new_data(subj));
	return FALSE;
}

@ A number of global variables are given special treatment here, including
a whole family with names like "the K understood", for different kinds K.
This is an awkward contrivance to bridge Inform 7, which is typed, with the
original Inform 6 parser at runtime, whose data is typeless.

=
<notable-parsing-variables> ::=
	<k-kind> understood |  ==> { 0, RP[1] }
	noun |                 ==> { 1, - }
	location |             ==> { 2, - }
	actor-location |       ==> { 3, - }
	second noun |          ==> { 4, - }
	person asked           ==> { 5, - }

@

= (early code)
nonlocal_variable *real_location_VAR = NULL;
nonlocal_variable *actor_location_VAR = NULL;

nonlocal_variable *I6_noun_VAR = NULL;
nonlocal_variable *I6_second_VAR = NULL;
nonlocal_variable *I6_actor_VAR = NULL;

@ =
int ParsingPlugin::new_variable_notify(nonlocal_variable *var) {
	if (<notable-parsing-variables>(var->name)) {
		switch (<<r>>) {
			case 0:
				if (Kinds::eq(<<rp>>, NonlocalVariables::kind(var))) {
					RTParsing::understood_variable(var);
					NonlocalVariables::allow_to_be_zero(var);
				}
				break;
			case 1: I6_noun_VAR = var; break;
			case 2: real_location_VAR = var; break;
			case 3: actor_location_VAR = var; break;
			case 4: I6_second_VAR = var; break;
			case 5: I6_actor_VAR = var; break;
		}
	}
	return FALSE;
}

@ Once the traverse is done, we can infer values for the two key Inter properties
for parsing:

=
property *P_name = NULL;

property *ParsingPlugin::name_property(void) {
	if (P_name == NULL) internal_error("name property not available yet");
	return P_name;
}

int ParsingPlugin::complete_model(int stage) {
	if (stage == WORLD_STAGE_V) {
		instance *I;
		P_name = ValueProperties::new_nameless(I"name", K_text);
		Hierarchy::make_available(Emit::tree(), RTParsing::name_iname());
		P_parse_name = ValueProperties::new_nameless(I"parse_name", K_value);
		P_action_bitmap = ValueProperties::new_nameless(I"action_bitmap", K_value);
		Hierarchy::make_available(Emit::tree(), RTProperties::iname(P_action_bitmap));

		LOOP_OVER_INSTANCES(I, K_object) {
			inference_subject *subj = Instances::as_subject(I);
			@<Assert the Inter name property@>;
			@<Assert the Inter parse-name property@>;
			@<Assert the Inter action-bitmap property@>;
		}

		kind *K;
		LOOP_OVER_BASE_KINDS(K)
			if (Kinds::Behaviour::is_subkind_of_object(K)) {
				inference_subject *subj = KindSubjects::from_kind(K);
				@<Assert the Inter parse-name property@>;
			}

		inference_subject *subj = KindSubjects::from_kind(K_thing);
		@<Assert the Inter action-bitmap property@>;
	}
	return FALSE;
}

@<Assert the Inter name property@> =
	if (Naming::object_is_privately_named(I) == FALSE) {
		int from_kind = FALSE;
		kind *K = Instances::to_kind(I);
		wording W = Instances::get_name_in_play(I, FALSE);
		if (Wordings::empty(W))
			W = Kinds::Behaviour::get_name_in_play(K, FALSE,
				Projects::get_language_of_play(Task::project()));
		wording PW = Instances::get_name_in_play(I, TRUE);
		if (Wordings::empty(PW)) {
			from_kind = TRUE;
			PW = Kinds::Behaviour::get_name_in_play(K, TRUE,
				Projects::get_language_of_play(Task::project()));
		}
		ValueProperties::assert(P_name, Instances::as_subject(I),
			RTParsing::name_property_array(I, W, PW, from_kind), CERTAIN_CE);
	}

@ We attach numbered parse name routines as properties for any object
where grammar has specified a need. (By default, this will not happen.)

@<Assert the Inter parse-name property@> =
	inter_name *S = PL::Parsing::Tokens::General::compile_parse_name_property(subj);
	if (S)
		ValueProperties::assert(P_parse_name, subj,
			Rvalues::from_iname(S), CERTAIN_CE);

@ The action bitmap is an array of bits attached to each object, one
for each action, which records whether that action has yet applied
successfully to that object. This is used at run-time to handle past
tense conditions such as "the jewels have been taken". Note that
we give the bitmap in the class definition associated with "thing"
to ensure that it will be inherited by all Inter objects of this class,
i.e., all Inter objects corresponding to I7 things.

@<Assert the Inter action-bitmap property@> =
	if (PluginManager::active(actions_plugin))
		if ((K_room == NULL) ||
			(InferenceSubjects::is_within(subj, KindSubjects::from_kind(K_room)) == FALSE)) {
			instance *I = InstanceSubjects::to_instance(subj);
			parse_node *S = PL::Actions::compile_action_bitmap_property(I);
			ValueProperties::assert(P_action_bitmap, subj, S, CERTAIN_CE);
		}
