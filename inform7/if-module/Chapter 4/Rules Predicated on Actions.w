[ActionRules::] Rules Predicated on Actions.

Rules can be set to run only if the action matches a given pattern.

@ Many rules are predicated on action patterns: "Instead of opening a closed
door", say, is a rule in the "instead of opening" rulebook which is predicated
on the action applying to "a closed door". This is stored in the following
actions-plugin corner of the //assertions: Runtime Context Data// for the rule.

=
typedef struct actions_rcd_data {
	int always_test_actor; /* ...even if no AP was given, test that actor is player? */
	int never_test_actor; /* ...for instance, for a parametrised rather than action rulebook */
	int marked_for_anyone; /* any actor is allowed to perform this action */
	CLASS_DEFINITION
} actions_rcd_data;

actions_rcd_data *ActionRules::new_rcd_data(id_runtime_context_data *idrcd) {
	actions_rcd_data *ard = CREATE(actions_rcd_data);
	ard->always_test_actor = FALSE;
	ard->never_test_actor = FALSE;
	ard->marked_for_anyone = FALSE;
	return ard;
}

@ Note that if the actions plugin is inactive, then this never runs...

=
int ActionRules::new_rcd(id_runtime_context_data *idrcd) {
	CREATE_PLUGIN_RCD_DATA(actions, idrcd, ActionRules::new_rcd_data)
	return FALSE;
}

@ ...with the result that |arcd| is always null in the function below.

=
void ActionRules::set_always_test_actor(id_runtime_context_data *idrcd) {
	actions_rcd_data *arcd = RCD_PLUGIN_DATA(actions, idrcd);
	if (arcd) arcd->always_test_actor = TRUE;
}

int ActionRules::get_always_test_actor(id_runtime_context_data *idrcd) {
	actions_rcd_data *arcd = RCD_PLUGIN_DATA(actions, idrcd);
	if (arcd) return arcd->always_test_actor;
	return FALSE;
}

void ActionRules::clear_always_test_actor(id_runtime_context_data *idrcd) {
	actions_rcd_data *arcd = RCD_PLUGIN_DATA(actions, idrcd);
	if (arcd) arcd->always_test_actor = FALSE;
}

void ActionRules::set_never_test_actor(id_runtime_context_data *idrcd) {
	actions_rcd_data *arcd = RCD_PLUGIN_DATA(actions, idrcd);
	if (arcd) arcd->never_test_actor = TRUE;
}

int ActionRules::get_never_test_actor(id_runtime_context_data *idrcd) {
	actions_rcd_data *arcd = RCD_PLUGIN_DATA(actions, idrcd);
	if (arcd) return arcd->never_test_actor;
	return TRUE;
}

void ActionRules::set_marked_for_anyone(id_runtime_context_data *idrcd, int to) {
	actions_rcd_data *arcd = RCD_PLUGIN_DATA(actions, idrcd);
	if (arcd) arcd->marked_for_anyone = to;
}

int ActionRules::get_marked_for_anyone(id_runtime_context_data *idrcd) {
	actions_rcd_data *arcd = RCD_PLUGIN_DATA(actions, idrcd);
	if (arcd) return arcd->marked_for_anyone;
	return FALSE;
}

@ The following all make use the action pattern |idrcd->ap| in the RCD. This
seems a little odd: why isn't it in the //actions_rcd_data//? The answer is
that it needs to exist even when the actions plugin is inactive, because it's
still used for parsing predicates for non-action-based rulebooks.

=
void ActionRules::set_ap(id_runtime_context_data *idrcd, action_pattern *ap) {
	if (idrcd) idrcd->ap = ap;
}

action_pattern *ActionRules::get_ap(id_runtime_context_data *idrcd) {
	if (idrcd) return idrcd->ap;
	return NULL;
}

int ActionRules::within_action_context(id_runtime_context_data *idrcd, action_name *an) {
	if (idrcd == NULL) return FALSE;
	actions_rcd_data *arcd = RCD_PLUGIN_DATA(actions, idrcd);
	if (arcd) return ActionPatterns::covers_action(idrcd->ap, an);
	return FALSE;
}

action_name *ActionRules::required_action(id_runtime_context_data *idrcd) {
	if (idrcd == NULL) return FALSE;
	actions_rcd_data *arcd = RCD_PLUGIN_DATA(actions, idrcd);
	if ((arcd) && (idrcd->ap)) return ActionPatterns::single_positive_action(idrcd->ap);
	return NULL;
}

void ActionRules::suppress_action_testing(id_runtime_context_data *idrcd) {
	if (idrcd->ap) ActionPatterns::suppress_action_testing(idrcd->ap);
}

