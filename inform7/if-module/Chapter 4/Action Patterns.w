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

@ When we parse action patterns, we record why they fail, in order to make
it easier to produce helpful error messages. (We can't simply fire off
errors at the time they occur, because text is often parsed in several
contexts at once, so just because it fails this one does not mean it is
wrong.) PAPF stands for "parse action pattern failure".

@d MISC_PAPF 1
@d NOPARTICIPLE_PAPF 2
@d MIXEDNOUNS_PAPF 3
@d WHEN_PAPF 4
@d WHENOKAY_PAPF 5
@d IMMISCIBLE_PAPF 6

= (early code)
int pap_failure_reason; /* one of the above */
int permit_trying_omission = FALSE; /* allow the keyword 'trying' to be omitted */
int permit_nonconstant_action_parameters = TRUE;

@ NB: Next time this is rewritten - (1) handle in, in the presence of, with
STV clauses; (2) get this right:

	The Rocky Promontory by the Waterfall is a room.

	Instead of going in the Rocky Promontory by the Waterfall:
		say "Where did you want to go?"

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

int ActionPatterns::is_unspecific(action_pattern *ap) {
	action_name *an = ActionPatterns::required_action(ap);
	if (an == NULL) return TRUE;
	if ((ActionSemantics::must_have_noun(an)) && (APClauses::get_noun(ap) == NULL)) return TRUE;
	if ((ActionSemantics::must_have_second(an)) && (APClauses::get_second(ap) == NULL)) return TRUE;
	if ((ActionSemantics::can_have_noun(an)) &&
		(ActionPatterns::ap_clause_is_unspecific(APClauses::get_noun(ap)))) return TRUE;
	if ((ActionSemantics::can_have_second(an)) &&
		(ActionPatterns::ap_clause_is_unspecific(APClauses::get_second(ap)))) return TRUE;
	if (ActionPatterns::ap_clause_is_unspecific(APClauses::get_actor(ap))) return TRUE;
	return FALSE;
}

int ActionPatterns::ap_clause_is_unspecific(parse_node *spec) {
	if (spec == NULL) return FALSE;
	if (Specifications::is_description(spec) == FALSE) return FALSE;
	return TRUE;
}

int ActionPatterns::is_overspecific(action_pattern *ap) {
	for (ap_clause *apoc = (ap)?(ap->ap_clauses):NULL; apoc; apoc = apoc->next)
		if ((apoc->clause_ID != NOUN_AP_CLAUSE) &&
			(apoc->clause_ID != SECOND_AP_CLAUSE) &&
			(apoc->clause_ID != ACTOR_AP_CLAUSE))
			if (apoc->clause_spec)
				return TRUE;
	if (APClauses::has_any_actor(ap)) return TRUE;
	if (ap->duration) return TRUE;
	return FALSE;
}

void ActionPatterns::suppress_action_testing(action_pattern *ap) {
	if ((ap->duration == NULL) && (ap->action_list))
		ActionNameLists::suppress_action_testing(ap->action_list);
}

@ We are allowed to give names to certain kinds of behaviour by "categorising"
an action.

=
void ActionPatterns::categorise_as(action_pattern *ap, wording W) {
	LOGIF(ACTION_PATTERN_PARSING, "Categorising the action:\n$A...as %W\n", ap, W);

	if (<article>(W)) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_NamedAPIsArticle),
			"there's only an article here",
			"not a name, so I'm not sure what this action is supposed to be.");
		return;
	}

	if (APClauses::get_actor(ap)) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_NamedAPWithActor),
			"behaviour characterised by named action patterns can only specify the action",
			"not the actor: as a result, it cannot include requests to other people to "
			"do things.");
		return;
	}

	NamedActionPatterns::add(ap, W);
}

parse_node *ActionPatterns::nullify_nonspecific_references(parse_node *spec) {
	if (spec == NULL) return spec;
	if (Node::is(spec, UNKNOWN_NT)) return NULL;
	return spec;
}

@ And an anticlimactic little routine for putting objects
into action patterns in the noun or second noun position.

=
void ActionPatterns::put_action_object_into_ap(action_pattern *ap, int C, wording W) {
	parse_node *spec = NULL;
	int any_flag = FALSE;
	if (<action-operand>(W)) {
		if (<<r>>) spec = <<rp>>;
		else { any_flag = TRUE; spec = Specifications::from_kind(K_thing); }
	}
	if (spec == NULL) spec = Specifications::new_UNKNOWN(W);
	if ((K_understanding) && (Rvalues::is_CONSTANT_of_kind(spec, K_text)))
		Node::set_kind_of_value(spec, K_understanding);
	Node::set_text(spec, W);
	LOGIF(ACTION_PATTERN_PARSING, "PAOIA (clause %d) %W = $P\n", C, W, spec);
	APClauses::set_val(ap, C, spec);
	if (any_flag) APClauses::set_opt(APClauses::clause(ap, C), DO_NOT_VALIDATE_APCOPT);
	else APClauses::clear_opt(APClauses::clause(ap, C), DO_NOT_VALIDATE_APCOPT);
}

@ =
int ActionPatterns::refers_to_past(action_pattern *ap) {
	if (ap->duration) return TRUE;
	return FALSE;
}

void ActionPatterns::convert_to_present_tense(action_pattern *ap) {
	ap->duration = NULL;
}

int ActionPatterns::pta_acceptable(parse_node *spec) {
	instance *I;
	if (spec == NULL) return TRUE;
	if (Specifications::is_description(spec) == FALSE) return TRUE;
	I = Specifications::object_exactly_described_if_any(spec);
	if (I) return TRUE;
	return FALSE;
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
