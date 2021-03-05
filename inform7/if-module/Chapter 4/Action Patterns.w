[ActionPatterns::] Action Patterns.

An action pattern is a description which may match many actions or
none. The text "doing something" matches every action, while "throwing
something at a door in a dark room" is seldom matched.

@ Action patterns are essentially a conjunction of specifications -- the
action must be this, and the noun must be that, and... While
they allow disjunction in the choice of action, all of that code is a
matter for the action name list to handle. The AP structure is a list
of conditions all of which must apply at once.

One surprising point is that the AP is used not only for action
patterns, but also in a slightly generalised role, as the condition
for a rule to be applied. Most rules are indeed predicated on actions
-- "instead of eating the cake" -- but some are instead in
"parametrised" rulebooks, which means they apply to a parameter
object instead of an action -- "reaching inside the cabinet".

=
typedef struct action_pattern {
	struct wording text_of_pattern; /* text giving rise to this AP */

	struct action_name_list *action_list; /* if this is action-based */
	struct kind *parameter_kind; /* if this is parametric */

	struct ap_clause *ap_clauses;

	struct time_period *duration; /* to refer to repetitions in the past */

	int valid; /* recording success or failure in parsing to an AP */
} action_pattern;

@ =
action_pattern ActionPatterns::new(void) {
	action_pattern ap;
	ap.ap_clauses = NULL;
	ap.text_of_pattern = EMPTY_WORDING;
	ap.action_list = NULL;
	ap.parameter_kind = NULL;
	ap.valid = FALSE;
	ap.duration = NULL;
	return ap;
}

@

=
typedef struct explicit_action {
	int request;
	struct action_name *action;
	struct parse_node *actor;
	struct parse_node *first_noun;
	struct parse_node *second_noun;
	struct action_pattern *as_described;
} explicit_action;


void ActionPatterns::log(action_pattern *ap) {
	ActionPatterns::write(DL, ap);
}

void ActionPatterns::write(OUTPUT_STREAM, action_pattern *ap) {
	if (ap == NULL) WRITE("<null-ap>");
	else if (ap->valid != TRUE) WRITE("<invalid>");
	else {
		WRITE("<action: ");
		if (ap->action_list == NULL) WRITE("unspecified");
		else ActionNameLists::log_briefly(ap->action_list);
		APClauses::write(OUT, ap);
		if (ap->duration) { WRITE(" duration: "); Occurrence::log(OUT, ap->duration); }
		WRITE(">");
	}
}

action_pattern *ActionPatterns::ap_store(action_pattern ap) {
	action_pattern *sap = CREATE(action_pattern);
	*sap = ap;
	return sap;
}

int ActionPatterns::is_named(action_pattern *ap) {
	if (ap) {
		anl_item *item = ActionNameLists::first_item(ap->action_list);
		if ((item) && (item->nap_listed)) return TRUE;
	}
	return FALSE;
}

int ActionPatterns::is_valid(action_pattern *ap) {
	if (ap == NULL) return FALSE;
	return ap->valid;
}

int ActionPatterns::within_action_context(action_pattern *ap, action_name *an) {
	if (ap == NULL) return TRUE;
	return ActionNameLists::covers_action(ap->action_list, an);
}

action_name_list *ActionPatterns::list(action_pattern *ap) {
	if (ap == NULL) return NULL;
	return ap->action_list;
}

action_name *ActionPatterns::required_action(action_pattern *ap) {
	if (ap) return ActionNameLists::single_positive_action(ap->action_list);
	return NULL;
}

int ActionPatterns::object_based(action_pattern *ap) {
	if ((ap) && (ActionNameLists::nonempty(ap->action_list))) return TRUE;
	return FALSE;
}

explicit_action *ActionPatterns::to_explicit_action(action_pattern *ap, int *reason) {
	if (ActionPatterns::is_unspecific(ap)) { *reason = 1; return NULL; }
	if (ActionPatterns::is_overspecific(ap)) { *reason = 2; return NULL; }
	*reason = 0;
	explicit_action *ea = CREATE(explicit_action);
	ea->action = ActionNameLists::get_the_one_true_action(ap->action_list);
	ea->request = APClauses::is_request(ap);
	ea->actor = APClauses::get_val(ap, ACTOR_AP_CLAUSE);
	ea->first_noun = APClauses::get_val(ap, NOUN_AP_CLAUSE);
	ea->second_noun = APClauses::get_val(ap, SECOND_AP_CLAUSE);
	ea->as_described = ap;
	return ea;
}

void ActionPatterns::make_ACTION_node(parse_node *p, action_pattern *ap) {
	Node::set_type(p, ACTION_NT);
	Node::set_action_meaning(p, ap);
	p->down = NULL;
}

int ActionPatterns::is_unspecific(action_pattern *ap) {
	action_name *an = ActionPatterns::required_action(ap);
	if (an == NULL) return TRUE;
	if ((ActionSemantics::must_have_noun(an)) && (APClauses::get_val(ap, NOUN_AP_CLAUSE) == NULL)) return TRUE;
	if ((ActionSemantics::must_have_second(an)) && (APClauses::get_val(ap, SECOND_AP_CLAUSE) == NULL)) return TRUE;
	if ((ActionSemantics::can_have_noun(an)) &&
		(ActionPatterns::ap_clause_is_unspecific(APClauses::get_val(ap, NOUN_AP_CLAUSE)))) return TRUE;
	if ((ActionSemantics::can_have_second(an)) &&
		(ActionPatterns::ap_clause_is_unspecific(APClauses::get_val(ap, SECOND_AP_CLAUSE)))) return TRUE;
	if (ActionPatterns::ap_clause_is_unspecific(APClauses::get_val(ap, ACTOR_AP_CLAUSE))) return TRUE;
	return FALSE;
}

int ActionPatterns::ap_clause_is_unspecific(parse_node *spec) {
	if (spec == NULL) return FALSE;
	if (Specifications::is_description(spec) == FALSE) return FALSE;
	return TRUE;
}

int ActionPatterns::is_overspecific(action_pattern *ap) {
	for (ap_clause *apoc = (ap)?(ap->ap_clauses):NULL; apoc; apoc = apoc->next)
		if ((APClauses::aspect(apoc) != PRIMARY_APCA) && (apoc->clause_spec))
			return TRUE;
	if (APClauses::has_any_actor(ap)) return TRUE;
	if (ap->duration) return TRUE;
	return FALSE;
}

void ActionPatterns::suppress_action_testing(action_pattern *ap) {
	if ((ap->duration == NULL) && (ap->action_list))
		ActionNameLists::suppress_action_testing(ap->action_list);
}

parse_node *ActionPatterns::nullify_nonspecific_references(parse_node *spec) {
	if (spec == NULL) return spec;
	if (Node::is(spec, UNKNOWN_NT)) return NULL;
	return spec;
}

@ =
int ActionPatterns::refers_to_past(action_pattern *ap) {
	if (ap->duration) return TRUE;
	return FALSE;
}

void ActionPatterns::convert_to_present_tense(action_pattern *ap) {
	ap->duration = NULL;
}

int ActionPatterns::makes_callings(action_pattern *ap) {
	for (ap_clause *apoc = ap->ap_clauses; apoc; apoc = apoc->next)
		if (Descriptions::makes_callings(apoc->clause_spec))
			return TRUE;
	return FALSE;
}

int ActionPatterns::compare_specificity(action_pattern *ap1, action_pattern *ap2) {
	if ((ap1 == NULL) && (ap2)) return -1;
	if ((ap1) && (ap2 == NULL)) return 1;
	if ((ap1 == NULL) && (ap2 == NULL)) return 0;

	LOGIF(SPECIFICITIES,
		"Comparing specificity of action patterns:\n(1) $A(2) $A\n", ap1, ap2);

	if ((ap1->valid == FALSE) && (ap2->valid != FALSE)) return -1;
	if ((ap1->valid != FALSE) && (ap2->valid == FALSE)) return 1;

	int rv = APClauses::compare_specificity(ap1, ap2);
	if (rv != 0) return rv;

	c_s_stage_law = I"III.4.1 - Action/How/What Happens";

	rv = ActionNameLists::compare_specificity(ap1->action_list, ap2->action_list);
	if (rv != 0) return rv;

	c_s_stage_law = I"III.5.1 - Action/When/Duration";

	rv = Occurrence::compare_specificity(ap1->duration, ap2->duration);
	if (rv != 0) return rv;

	c_s_stage_law = I"III.5.2 - Action/When/Circumstances";

	rv = Conditions::compare_specificity_of_CONDITIONs(APClauses::get_val(ap1, WHEN_AP_CLAUSE), APClauses::get_val(ap2, WHEN_AP_CLAUSE));
	if (rv != 0) return rv;

	c_s_stage_law = I"III.6.1 - Action/Name/Is This Named";

	if ((ActionPatterns::is_named(ap1)) && (ActionPatterns::is_named(ap2) == FALSE))
		return 1;
	if ((ActionPatterns::is_named(ap1) == FALSE) && (ActionPatterns::is_named(ap2)))
		return -1;

	return 0;
}
