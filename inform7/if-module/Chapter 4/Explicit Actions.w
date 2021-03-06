[ExplicitActions::] Explicit Actions.

An exactly specified action is called "explicit".

@ Explicit actions are used inside the compiler whenever we kmow exactly what
action we are talking about; stored action constants are //explicit_action//
objects in a thin wrapper -- see //Action Kinds//.

=
typedef struct explicit_action {
	int request;
	struct action_name *action;
	struct parse_node *actor;
	struct parse_node *first_noun;
	struct parse_node *second_noun;
	struct action_pattern *as_described;
} explicit_action;

@ The code here is concerned with the question: when is an action pattern a
description of an explicit action? The answer is only if takes the Goldilocks
position of being neither too specific, nor too unspecific:

@d UNDERSPECIFIC_EA_FAILURE 1
@d OVERSPECIFIC_EA_FAILURE 2

=
explicit_action *ExplicitActions::from_action_pattern(action_pattern *ap, int *reason) {
	if (ExplicitActions::ap_underspecific(ap)) { *reason = UNDERSPECIFIC_EA_FAILURE; return NULL; }
	if (ExplicitActions::ap_overspecific(ap)) { *reason = OVERSPECIFIC_EA_FAILURE; return NULL; }
	*reason = 0;
	explicit_action *ea = CREATE(explicit_action);
	ea->action = ActionNameLists::get_the_one_true_action(ap->action_list);
	ea->request = APClauses::is_request(ap);
	ea->actor = APClauses::spec(ap, ACTOR_AP_CLAUSE);
	ea->first_noun = APClauses::spec(ap, NOUN_AP_CLAUSE);
	ea->second_noun = APClauses::spec(ap, SECOND_AP_CLAUSE);
	ea->as_described = ap;
	return ea;
}

@ A pattern is underspecific if it fails to specify nouns required by the
action (example: "taking") or it does specify them, but too vaguely (example:
"taking a thing", or "an actor taking the medallion"):

=
int ExplicitActions::ap_underspecific(action_pattern *ap) {
	action_name *an = ActionPatterns::single_positive_action(ap);
	if (an == NULL) return TRUE;
	if ((ActionSemantics::must_have_noun(an)) &&
		(APClauses::spec(ap, NOUN_AP_CLAUSE) == NULL)) return TRUE;
	if ((ActionSemantics::must_have_second(an)) &&
		(APClauses::spec(ap, SECOND_AP_CLAUSE) == NULL)) return TRUE;
	if ((ActionSemantics::can_have_noun(an)) &&
		(ExplicitActions::clause_unspecific(ap, NOUN_AP_CLAUSE))) return TRUE;
	if ((ActionSemantics::can_have_second(an)) &&
		(ExplicitActions::clause_unspecific(ap, SECOND_AP_CLAUSE))) return TRUE;
	if (ExplicitActions::clause_unspecific(ap, ACTOR_AP_CLAUSE)) return TRUE;
	if (APClauses::actor_is_anyone_except_player(ap)) return TRUE;
	return FALSE;
}

int ExplicitActions::clause_unspecific(action_pattern *ap, int C) {
	parse_node *spec = APClauses::spec(ap, C);
	if (spec == NULL) return FALSE;
	if (Specifications::is_description(spec) == FALSE) return FALSE;
	return TRUE;
}

@ A pattern is overspecific if it contains any extraneous clauses (example:
"taking the medallion in the presence of Matilda"), or refers to past times
(example: "taking the medallion for the third time"):

=
int ExplicitActions::ap_overspecific(action_pattern *ap) {
	LOOP_OVER_AP_CLAUSES(apoc, ap)
		if ((APClauses::aspect(apoc) != PRIMARY_APCA) && (apoc->clause_spec))
			return TRUE;
	if (ap->duration) return TRUE;
	return FALSE;
}
