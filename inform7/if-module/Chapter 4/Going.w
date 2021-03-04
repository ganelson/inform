[Going::] Going.

Inform provides a little extra support for the "going" action.

@

=
<going-action> ::=
	going

@ =
action_name *going_action = NULL;
void Going::notice_new_action_name(action_name *an) {
	if (<going-action>(ActionNameNames::tensed(an, IS_TENSE))) going_action = an;
}

@ There are five clauses with non-standard effects:

@e GOING_FROM_AP_CLAUSE
@e GOING_TO_AP_CLAUSE
@e GOING_THROUGH_AP_CLAUSE
@e GOING_BY_AP_CLAUSE
@e PUSHING_AP_CLAUSE

@e GOING_APCA

=
int Going::aspect(ap_clause *apoc) {
	switch (apoc->clause_ID) {
		case GOING_FROM_AP_CLAUSE:    return IN_APCA;
		case GOING_TO_AP_CLAUSE:      return IN_APCA;
		case GOING_THROUGH_AP_CLAUSE: return GOING_APCA;
		case GOING_BY_AP_CLAUSE:      return GOING_APCA;
		case PUSHING_AP_CLAUSE:       return GOING_APCA;
	}
	return -1;
}

@

=
int Going::compare_specificity(action_pattern *ap1, action_pattern *ap2, int *claim) {
	*claim = TRUE;

	int suspend_usual_from_and_room = FALSE;

	c_s_stage_law = I"III.2.4 - Action/Where/Other Optional Clauses";

	int rct1 = APClauses::number_with_aspect(ap1, GOING_APCA);
	int rct2 = APClauses::number_with_aspect(ap2, GOING_APCA);
	if (rct1 > rct2) return 1;
	if (rct1 < rct2) return -1;

	int rv = APClauses::cmp_clause(PUSHING_AP_CLAUSE, ap1, ap2); if (rv) return rv;

	rv = APClauses::cmp_clause(GOING_BY_AP_CLAUSE, ap1, ap2); if (rv) return rv;
	rv = APClauses::cmp_clause(GOING_THROUGH_AP_CLAUSE, ap1, ap2); if (rv) return rv;
	
	c_s_stage_law = I"III.2.2 - Action/Where/Room Where Action Takes Place";

	rct1 = APClauses::number_with_aspect(ap1, IN_APCA);
	rct2 = APClauses::number_with_aspect(ap2, IN_APCA);
	if (rct1 > rct2) return 1;
	if (rct1 < rct2) return -1;

	if ((APClauses::get_val(ap1, GOING_FROM_AP_CLAUSE)) && (APClauses::get_room(ap1) == NULL)
		&& (APClauses::get_room(ap2)) && (APClauses::get_val(ap2, GOING_FROM_AP_CLAUSE) == NULL)) {
		rv = APClauses::cmp_clauses(GOING_FROM_AP_CLAUSE, ap1, IN_AP_CLAUSE, ap2); if (rv) return rv;
		suspend_usual_from_and_room = TRUE;
	}

	if ((APClauses::get_val(ap2, GOING_FROM_AP_CLAUSE)) && (APClauses::get_room(ap2) == NULL)
		&& (APClauses::get_room(ap1)) && (APClauses::get_val(ap1, GOING_FROM_AP_CLAUSE) == NULL)) {
		rv = APClauses::cmp_clauses(IN_AP_CLAUSE, ap1, GOING_FROM_AP_CLAUSE, ap2); if (rv) return rv;
		suspend_usual_from_and_room = TRUE;
	}

	if (suspend_usual_from_and_room == FALSE) {
		rv = APClauses::cmp_clause(GOING_FROM_AP_CLAUSE, ap1, ap2); if (rv) return rv;
		rv = APClauses::cmp_clause(IN_AP_CLAUSE, ap1, ap2); if (rv) return rv;
	}

	rv = APClauses::cmp_clause(GOING_TO_AP_CLAUSE, ap1, ap2); if (rv) return rv;

	return 0;
}

void Going::write(OUTPUT_STREAM, int C) {
	switch (C) {
		case GOING_FROM_AP_CLAUSE:    WRITE("going-from"); break;
		case GOING_TO_AP_CLAUSE:      WRITE("going-to"); break;
		case GOING_THROUGH_AP_CLAUSE: WRITE("going-through"); break;
		case GOING_BY_AP_CLAUSE:      WRITE("going-by"); break;
		case PUSHING_AP_CLAUSE:       WRITE("pushing"); break;
	}
}

int Going::id(void) {
	if (going_action == NULL) return 0;
	return RTActions::action_variable_set_ID(going_action);
}

int Going::divert(action_pattern *ap, stacked_variable *stv) {
	int oid = StackedVariables::get_owner_id(stv);
	int off = StackedVariables::get_offset(stv);
	if ((going_action) && (oid == Going::id())) {
		switch (off) {
			case 0: return GOING_FROM_AP_CLAUSE;
			case 1: return GOING_TO_AP_CLAUSE;
			case 2: return GOING_THROUGH_AP_CLAUSE;
			case 3: return GOING_BY_AP_CLAUSE;
			case 4: return PUSHING_AP_CLAUSE;
		}
	}
	return -1;
}

void Going::new_clause(action_pattern *ap, ap_clause *apoc) {
	if ((apoc->clause_ID == GOING_FROM_AP_CLAUSE) ||
		(apoc->clause_ID == GOING_TO_AP_CLAUSE))
		APClauses::set_opt(apoc, ALLOW_REGION_AS_ROOM_APCOPT);
}

@ 

=
int Going::check(action_pattern *ap) {
	if (Going::check_clause(APClauses::get_val(ap, GOING_FROM_AP_CLAUSE), "from",
		K_room, K_region) == FALSE) return FALSE;
	if (Going::check_clause(APClauses::get_val(ap, GOING_TO_AP_CLAUSE), "to",
		K_room, K_region) == FALSE) return FALSE;
	if (Going::check_clause(APClauses::get_val(ap, GOING_BY_AP_CLAUSE), "by",
		K_thing, NULL) == FALSE) return FALSE;
	if (Going::check_clause(APClauses::get_val(ap, GOING_THROUGH_AP_CLAUSE), "through",
		K_door, NULL) == FALSE) return FALSE;
	if (Going::check_clause(APClauses::get_val(ap, PUSHING_AP_CLAUSE), "with",
		K_thing, NULL) == FALSE) return FALSE;
	return TRUE;
}

int Going::check_clause(parse_node *spec, char *keyword, kind *ka, kind *kb) {
	if (spec == NULL) return TRUE;
	if (Rvalues::is_nothing_object_constant(spec)) return TRUE;
	if (Specifications::is_description_like(spec)) {
		instance *oref = Specifications::object_exactly_described_if_any(spec);
		if ((oref == NULL) || (ka == NULL) || (Instances::of_kind(oref, ka)) ||
			((kb) && (Instances::of_kind(oref, kb)))) return TRUE;
		Problems::quote_source(1, current_sentence);
		Problems::quote_object(2, oref);
		Problems::quote_text(3, keyword);
		Problems::quote_kind(4, ka);
		Problems::quote_kind(5, Instances::to_kind(oref));
		if (kb) Problems::quote_kind(6, kb);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_GoingWrongKind));
		if (kb)
		Problems::issue_problem_segment(
			"In the sentence %1, %2 seems to be intended as something the "
			"player might be going %3, but this has the wrong kind: %5 "
			"rather than %4 or %6.");
		else
		Problems::issue_problem_segment(
			"In the sentence %1, %2 seems to be intended as something the player "
			"might be going %3, but this has the wrong kind: %5 rather than %4.");
		Problems::issue_problem_end();
		return TRUE;
	}
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, Node::get_text(spec));
	Problems::quote_text(3, keyword);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_GoingWithoutObject));
	Problems::issue_problem_segment(
		"In the sentence %1, '%2' seems to be intended as something the player "
		"might be going %3, but it doesn't make sense in that context.");
	Problems::issue_problem_end();
	return FALSE;
}

void Going::go_nowhere(action_pattern *ap) {
	APClauses::set_val(ap, GOING_TO_AP_CLAUSE, Rvalues::new_nothing_object_constant());
}

void Going::go_somewhere(action_pattern *ap) {
	APClauses::set_val(ap, GOING_TO_AP_CLAUSE, Descriptions::from_kind(K_room, FALSE));
}

int Going::going_nowhere(action_pattern *ap) {
	if (Rvalues::is_nothing_object_constant(APClauses::get_val(ap, GOING_TO_AP_CLAUSE))) return TRUE;
	return FALSE;
}

int Going::going_somewhere(action_pattern *ap) {
	parse_node *val = APClauses::get_val(ap, GOING_TO_AP_CLAUSE);
	if ((Descriptions::is_kind_like(val)) && (Kinds::eq(Descriptions::explicit_kind(val), K_room)))
		return TRUE;
	return FALSE;
}

@ Going from, by, through, or with all imply going somewhere rather than nowhere;
if not "going to" destination is specified, we had better check the destination
to make sure it actually exists. So this can be used to see if the need arises:

=
int Going::in_some_way(action_pattern *ap) {
	if ((APClauses::get_val(ap, GOING_TO_AP_CLAUSE) == NULL) &&
			((APClauses::get_val(ap, GOING_FROM_AP_CLAUSE) != NULL) ||
			(APClauses::get_val(ap, GOING_BY_AP_CLAUSE) != NULL) ||
			(APClauses::get_val(ap, GOING_THROUGH_AP_CLAUSE) != NULL) ||
			(APClauses::get_val(ap, PUSHING_AP_CLAUSE) != NULL)))
		return TRUE;
	return FALSE;
}

@ =
<going-action-irregular-operand> ::=
	nowhere |    ==> { FALSE, - }
	somewhere						==> { TRUE, - }

@ =
int Going::claim_noun(action_name *an, action_pattern *ap, wording W) {
	if ((an == going_action) && (<going-action-irregular-operand>(W))) {
		if (<<r>> == FALSE) Going::go_nowhere(ap);
		else Going::go_somewhere(ap);
		return TRUE;
	}
	return FALSE;
}