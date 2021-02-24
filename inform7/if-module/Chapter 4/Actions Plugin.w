[ActionsPlugin::] Actions Plugin.

A plugin for actions, by which animate characters change the world model.

@ Support for actions is contained in the "actions" plugin, which occupies this
entire chapter.

=
@ =
void ActionsPlugin::start(void) {
	PluginManager::plug(MAKE_SPECIAL_MEANINGS_PLUG, ActionsPlugin::make_special_meanings);
	PluginManager::plug(NEW_BASE_KIND_NOTIFY_PLUG, ActionsPlugin::actions_new_base_kind_notify);
	PluginManager::plug(COMPILE_CONSTANT_PLUG, PL::Actions::actions_compile_constant);
	PluginManager::plug(OFFERED_PROPERTY_PLUG, PL::Actions::actions_offered_property);
	PluginManager::plug(OFFERED_SPECIFICATION_PLUG, PL::Actions::actions_offered_specification);
	PluginManager::plug(TYPECHECK_EQUALITY_PLUG, PL::Actions::actions_typecheck_equality);
	PluginManager::plug(PRODUCTION_LINE_PLUG, ActionsPlugin::production_line);

	Vocabulary::set_flags(Vocabulary::entry_for_text(L"doing"), ACTION_PARTICIPLE_MC);
	Vocabulary::set_flags(Vocabulary::entry_for_text(L"asking"), ACTION_PARTICIPLE_MC);
}

int ActionsPlugin::production_line(int stage, int debugging, stopwatch_timer *sequence_timer) {
	if (stage == INTER1_CSEQ) {
		BENCH(PL::Actions::Patterns::Named::compile);
		BENCH(PL::Actions::ActionData);
		BENCH(PL::Actions::ActionCoding_array);
		BENCH(PL::Actions::ActionHappened);
		BENCH(PL::Actions::compile_action_routines);
	}
	return FALSE;
}

int ActionsPlugin::make_special_meanings(void) {
	SpecialMeanings::declare(PL::Actions::new_action_SMF, I"new-action", 2);
	return FALSE;
}

@ |DESCRIPTION_OF_ACTION| is used in type-checking to represent gerunds: that
is, actions described by what appear to be participles but which are in
context nouns ("if taking something, ...").

|ACTION_NAME|. For those rare occasions where we need to identify the
basic underlying action but none of the nouns, etc., thereto. At run-time,
this stores as the I6 action number: e.g. |##Go| for the going action.

|STORED_ACTION| is just what it says it is: a stored action, which can be
tried later. This is a pointer value; see "StoredAction.i6t".

@ =
int ActionsPlugin::actions_new_base_kind_notify(kind *new_base, text_stream *name, wording W) {
	if (Str::eq_wide_string(name, L"ACTION_NAME_TY")) {
		K_action_name = new_base; return TRUE;
	}
	if (Str::eq_wide_string(name, L"DESCRIPTION_OF_ACTION_TY")) {
		K_description_of_action = new_base; return TRUE;
	}
	if (Str::eq_wide_string(name, L"STORED_ACTION_TY")) {
		K_stored_action = new_base; return TRUE;
	}
	return FALSE;
}
