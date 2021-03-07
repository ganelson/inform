[Going::] Going.

Inform provides a little extra support for the "going" action.

@ The "going" action, allowing actors to move from room to room in the spatial
map of the world model, is by far the most intricately implemented. Reflecting
that, we provide quite a lot of hard-wired compiler support for it. This
section is not a plugin as such, but arguably should be: it attempts to contain
everything special to "going" in one place.

Firstly, we have to recognise the action we will treat differently, which
we do by its (English) name in the Standard Rules:

=
<going-action> ::=
	going

@ =
action_name *going_action = NULL;
void Going::notice_new_action_name(action_name *an) {
	if (<going-action>(ActionNameNames::tensed(an, IS_TENSE))) going_action = an;
}

@ The going action variables are identified at runtime by this ID number:

=
int Going::id(void) {
	if (going_action == NULL) return 0;
	return RTActions::action_variable_set_ID(going_action);
}

@ We will need to handle five special AP clauses. Two have the existing |IN_APCA|
aspect, and the other three share a new one.

@e GOING_FROM_AP_CLAUSE
@e GOING_TO_AP_CLAUSE
@e GOING_THROUGH_AP_CLAUSE
@e GOING_BY_AP_CLAUSE
@e PUSHING_AP_CLAUSE

@e GOING_APCA

=
void Going::write_clause_ID(OUTPUT_STREAM, int C) {
	switch (C) {
		case GOING_FROM_AP_CLAUSE:    WRITE("going-from"); break;
		case GOING_TO_AP_CLAUSE:      WRITE("going-to"); break;
		case GOING_THROUGH_AP_CLAUSE: WRITE("going-through"); break;
		case GOING_BY_AP_CLAUSE:      WRITE("going-by"); break;
		case PUSHING_AP_CLAUSE:       WRITE("pushing"); break;
	}
}

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

@ The Standard Rules defines five action variables in sequence for the going
action, and we pick them up here. Note that we do this by their creation
sequence and not by their names -- so this would all stop working if the
Standard Rules were rearranged. Caveat editor.

If we do spot one of these five magic variables, we tie it to a clause with
a special ID number of our choice.

=
int Going::divert_clause_ID(stacked_variable *stv) {
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

@ If we create a "going from" or "going to" clause, we set a flag to show that
they can contain regions or rooms equally well. (Inform's kinds system has no
protocol for this; it could have, but we don't need this to be visible to authors
writing source text.)

=
void Going::new_clause(action_pattern *ap, ap_clause *apoc) {
	if ((apoc->clause_ID == GOING_FROM_AP_CLAUSE) ||
		(apoc->clause_ID == GOING_TO_AP_CLAUSE))
		APClauses::set_opt(apoc, ALLOW_REGION_AS_ROOM_APCOPT);
}

@ Going nowhere is a special syntax:

=
void Going::go_nowhere(action_pattern *ap) {
	APClauses::set_spec(ap, GOING_TO_AP_CLAUSE, Rvalues::new_nothing_object_constant());
}

int Going::going_nowhere(action_pattern *ap) {
	if (Rvalues::is_nothing_object_constant(APClauses::spec(ap, GOING_TO_AP_CLAUSE)))
		return TRUE;
	return FALSE;
}

@ And similarly going somewhere:

=
void Going::go_somewhere(action_pattern *ap) {
	APClauses::set_spec(ap, GOING_TO_AP_CLAUSE, Descriptions::from_kind(K_room, FALSE));
}

int Going::going_somewhere(action_pattern *ap) {
	parse_node *val = APClauses::spec(ap, GOING_TO_AP_CLAUSE);
	if ((Descriptions::is_kind_like(val)) && (Kinds::eq(Descriptions::explicit_kind(val), K_room)))
		return TRUE;
	return FALSE;
}

@ These are recognised by this Preform nonterminal:

=
<going-action-irregular-operand> ::=
	nowhere |    ==> { FALSE, - }
	somewhere    ==> { TRUE, - }

@ Which we intercept thus:

=
int Going::irregular_noun_phrase(action_name *an, action_pattern *ap, wording W) {
	if ((an == going_action) && (<going-action-irregular-operand>(W))) {
		if (<<r>> == FALSE) Going::go_nowhere(ap); else Going::go_somewhere(ap);
		return TRUE;
	}
	return FALSE;
}

@ Here we perform sanity checks on the clauses.

=
int Going::validate(stacked_variable *stv, parse_node *spec) {
	int C = Going::divert_clause_ID(stv);
	char *keyword = NULL; kind *ka = NULL, *kb = NULL;
	switch (C) {
		case GOING_FROM_AP_CLAUSE: keyword = "from"; ka = K_room; kb = K_region; break;
		case GOING_TO_AP_CLAUSE: keyword = "to"; ka = K_room; kb = K_region; break;
		case GOING_BY_AP_CLAUSE: keyword = "by"; ka = K_thing; kb = NULL; break;
		case GOING_THROUGH_AP_CLAUSE: keyword = "through"; ka = K_door; kb = NULL; break;
		case PUSHING_AP_CLAUSE: keyword = "with"; ka = K_thing; kb = NULL; break;
	}
	if (keyword == NULL) return NOT_APPLICABLE;
	return Going::check_clause(spec, keyword, ka, kb);
}

@ Each clause can be within one of up to two kinds, or else can be "nothing"
or unspecified:

=
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

@ Going from, by, through, or with all imply going somewhere rather than nowhere;
if no "going to" destination is specified, we had better check the destination
to make sure it actually exists. So this can be used to see if the need arises:

=
int Going::need_to_check_destination_exists(action_pattern *ap) {
	if ((APClauses::spec(ap, GOING_TO_AP_CLAUSE) == NULL) &&
			((APClauses::spec(ap, GOING_FROM_AP_CLAUSE) != NULL) ||
			(APClauses::spec(ap, GOING_BY_AP_CLAUSE) != NULL) ||
			(APClauses::spec(ap, GOING_THROUGH_AP_CLAUSE) != NULL) ||
			(APClauses::spec(ap, PUSHING_AP_CLAUSE) != NULL)))
		return TRUE;
	return FALSE;
}

@ Specificity checking for the "going" action is quite complicated. We want to
count "going from X" and "going in X" as being essentially the same requirement,
giving neither clause priority over the other, which means some fiddly crossover
code if |ap1| has one and |ap2| the other.

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

	if ((APClauses::spec(ap1, GOING_FROM_AP_CLAUSE)) && (APClauses::spec(ap1, IN_AP_CLAUSE) == NULL)
		&& (APClauses::spec(ap2, IN_AP_CLAUSE)) && (APClauses::spec(ap2, GOING_FROM_AP_CLAUSE) == NULL)) {
		rv = APClauses::cmp_clauses(GOING_FROM_AP_CLAUSE, ap1, IN_AP_CLAUSE, ap2); if (rv) return rv;
		suspend_usual_from_and_room = TRUE;
	}

	if ((APClauses::spec(ap2, GOING_FROM_AP_CLAUSE)) && (APClauses::spec(ap2, IN_AP_CLAUSE) == NULL)
		&& (APClauses::spec(ap1, IN_AP_CLAUSE)) && (APClauses::spec(ap1, GOING_FROM_AP_CLAUSE) == NULL)) {
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
