[Going::] Going.

Inform provides a little extra support for the "going" action.

@ There are five clauses with non-standard effects:

@e GOING_FROM_AP_CLAUSE
@e GOING_TO_AP_CLAUSE
@e GOING_THROUGH_AP_CLAUSE
@e GOING_BY_AP_CLAUSE
@e PUSHING_AP_CLAUSE

@

=
int Going::compare_specificity(action_pattern *ap1, action_pattern *ap2, int *claim) {
	*claim = TRUE;

	int suspend_usual_from_and_room = FALSE;

	c_s_stage_law = I"III.2.4 - Action/Where/Other Optional Clauses";

	int rct1 = Going::count_other(ap1), rct2 = Going::count_other(ap2);
	if (rct1 > rct2) return 1;
	if (rct1 < rct2) return -1;

	int rv = Specifications::compare_specificity(APClauses::get_val(ap1, PUSHING_AP_CLAUSE), APClauses::get_val(ap2, PUSHING_AP_CLAUSE), NULL);
	if (rv != 0) return rv;

	rv = Specifications::compare_specificity(APClauses::get_val(ap1, GOING_BY_AP_CLAUSE), APClauses::get_val(ap2, GOING_BY_AP_CLAUSE), NULL);
	if (rv != 0) return rv;

	rv = Specifications::compare_specificity(APClauses::get_val(ap1, GOING_THROUGH_AP_CLAUSE), APClauses::get_val(ap2, GOING_THROUGH_AP_CLAUSE), NULL);
	if (rv != 0) return rv;
	
	c_s_stage_law = I"III.2.2 - Action/Where/Room Where Action Takes Place";

	rct1 = Going::count_rooms(ap1); rct2 = Going::count_rooms(ap2);
	if (rct1 > rct2) return 1;
	if (rct1 < rct2) return -1;

	if ((APClauses::get_val(ap1, GOING_FROM_AP_CLAUSE)) && (APClauses::get_room(ap1) == NULL)
		&& (APClauses::get_room(ap2)) && (APClauses::get_val(ap2, GOING_FROM_AP_CLAUSE) == NULL)) {
		rv = Specifications::compare_specificity(APClauses::get_val(ap1, GOING_FROM_AP_CLAUSE), APClauses::get_room(ap2), NULL);
		if (rv != 0) return rv;
		suspend_usual_from_and_room = TRUE;
	}

	if ((APClauses::get_val(ap2, GOING_FROM_AP_CLAUSE)) && (APClauses::get_room(ap2) == NULL)
		&& (APClauses::get_room(ap1)) && (APClauses::get_val(ap1, GOING_FROM_AP_CLAUSE) == NULL)) {
		rv = Specifications::compare_specificity(APClauses::get_room(ap1), APClauses::get_val(ap2, GOING_FROM_AP_CLAUSE), NULL);
		if (rv != 0) return rv;
		suspend_usual_from_and_room = TRUE;
	}

	if (suspend_usual_from_and_room == FALSE) {
		rv = Specifications::compare_specificity(APClauses::get_val(ap1, GOING_FROM_AP_CLAUSE), APClauses::get_val(ap2, GOING_FROM_AP_CLAUSE), NULL);
		if (rv != 0) return rv;

		rv = Specifications::compare_specificity(APClauses::get_room(ap1), APClauses::get_room(ap2), NULL);
		if (rv != 0) return rv;
	}

	rv = Specifications::compare_specificity(APClauses::get_val(ap1, GOING_TO_AP_CLAUSE), APClauses::get_val(ap2, GOING_TO_AP_CLAUSE), NULL);
	if (rv != 0) return rv;

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

int Going::divert(action_pattern *ap, stacked_variable *stv) {
	int oid = StackedVariables::get_owner_id(stv);
	int off = StackedVariables::get_offset(stv);
	if (oid == 20007 /* i.e., going */ ) {
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
int Going::check_going(parse_node *spec, char *keyword,
	kind *ka, kind *kb) {
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

int Going::count_rooms(action_pattern *ap) {
	int c = 0;
	if (APClauses::get_room(ap)) c += 2;
	if (APClauses::get_val(ap, GOING_FROM_AP_CLAUSE)) c += 2;
	if (APClauses::get_val(ap, GOING_TO_AP_CLAUSE)) c += 2;
	return c;
}

int Going::count_other(action_pattern *ap) {
	int c = 0;
	if (APClauses::get_val(ap, PUSHING_AP_CLAUSE)) c += 2;
	if (APClauses::get_val(ap, GOING_BY_AP_CLAUSE)) c += 2;
	if (APClauses::get_val(ap, GOING_THROUGH_AP_CLAUSE)) c += 2;
	return c;
}

int Going::count_aspects(action_pattern *ap) {
	int c = 0;
	if (ap == NULL) return 0;
	if ((APClauses::get_val(ap, PUSHING_AP_CLAUSE)) ||
		(APClauses::get_val(ap, GOING_BY_AP_CLAUSE)) ||
		(APClauses::get_val(ap, GOING_THROUGH_AP_CLAUSE)))
		c++;
	if ((APClauses::get_room(ap)) ||
		(APClauses::get_val(ap, GOING_FROM_AP_CLAUSE)) ||
		(APClauses::get_val(ap, GOING_TO_AP_CLAUSE)))
		c++;
	return c;
}
