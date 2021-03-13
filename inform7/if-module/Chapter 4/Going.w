[GoingPlugin::] Going.

A plugin to provide a little extra support for the "going" action.

@ The "going" action, allowing actors to move from room to room in the spatial
map of the world model, is by far the most intricately implemented. Reflecting
that, we provide quite a lot of hard-wired compiler support for it, in the form
of this plugin.

Note that if the actions plugin is not also active, none of the functions
below will ever be called.

=
void GoingPlugin::start(void) {
	PluginManager::plug(NEW_ACTION_NOTIFY_PLUG, GoingPlugin::new_action_notify);
	PluginManager::plug(WRITE_AP_CLAUSE_ID_PLUG, GoingPlugin::write_clause_ID);
	PluginManager::plug(ASPECT_OF_AP_CLAUSE_ID_PLUG, GoingPlugin::aspect);
	PluginManager::plug(DIVERT_AP_CLAUSE_PLUG, GoingPlugin::divert_clause_ID);
	PluginManager::plug(PARSE_AP_CLAUSE_PLUG, GoingPlugin::parse_clause);
	PluginManager::plug(VALIDATE_AP_CLAUSE_PLUG, GoingPlugin::validate);
	PluginManager::plug(NEW_AP_CLAUSE_PLUG, GoingPlugin::new_clause);
	PluginManager::plug(ACT_ON_ANL_ENTRY_OPTIONS_PLUG, GoingPlugin::act_on_options);
	PluginManager::plug(COMPARE_AP_SPECIFICITY_PLUG, GoingPlugin::compare_specificity);

	PluginManager::plug(SET_PATTERN_MATCH_REQUIREMENTS_PLUG,
		RTGoing::set_pattern_match_requirements);
	PluginManager::plug(COMPILE_PATTERN_MATCH_CLAUSE_PLUG,
		RTGoing::compile_pattern_match_clause);
}

@ Firstly, we have to recognise the action we will treat differently, which
we do by its (English) name in the Standard Rules:

=
<going-action> ::=
	going

@ =
action_name *going_action = NULL;
int GoingPlugin::new_action_notify(action_name *an) {
	if (<going-action>(ActionNameNames::tensed(an, IS_TENSE))) going_action = an;
	return FALSE;
}

@ The going action variables are identified at runtime by this ID number:

=
int GoingPlugin::id(void) {
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
int GoingPlugin::write_clause_ID(OUTPUT_STREAM, int C) {
	switch (C) {
		case GOING_FROM_AP_CLAUSE:    WRITE("going-from"); return TRUE;
		case GOING_TO_AP_CLAUSE:      WRITE("going-to"); return TRUE;
		case GOING_THROUGH_AP_CLAUSE: WRITE("going-through"); return TRUE;
		case GOING_BY_AP_CLAUSE:      WRITE("going-by"); return TRUE;
		case PUSHING_AP_CLAUSE:       WRITE("pushing"); return TRUE;
	}
	return FALSE;
}

int GoingPlugin::aspect(int C, int *A) {
	switch (C) {
		case GOING_FROM_AP_CLAUSE:    *A = IN_APCA; return TRUE;
		case GOING_TO_AP_CLAUSE:      *A = IN_APCA; return TRUE;
		case GOING_THROUGH_AP_CLAUSE: *A = GOING_APCA; return TRUE;
		case GOING_BY_AP_CLAUSE:      *A = GOING_APCA; return TRUE;
		case PUSHING_AP_CLAUSE:       *A = GOING_APCA; return TRUE;
	}
	return FALSE;
}

@ The Standard Rules defines five action variables in sequence for the going
action, and we pick them up here. Note that we do this by their creation
sequence and not by their names -- so this would all stop working if the
Standard Rules were rearranged. Caveat editor.

If we do spot one of these five magic variables, we tie it to a clause with
a special ID number of our choice.

=
int GoingPlugin::divert_clause_ID(stacked_variable *stv, int *id) {
	int oid = StackedVariables::get_owner_id(stv);
	int off = StackedVariables::get_offset(stv);
	if ((going_action) && (oid == GoingPlugin::id())) {
		switch (off) {
			case 0: *id = GOING_FROM_AP_CLAUSE; return TRUE;
			case 1: *id = GOING_TO_AP_CLAUSE; return TRUE;
			case 2: *id = GOING_THROUGH_AP_CLAUSE; return TRUE;
			case 3: *id = GOING_BY_AP_CLAUSE; return TRUE;
			case 4: *id = PUSHING_AP_CLAUSE; return TRUE;
		}
	}
	return FALSE;
}

@ If we create a "going from" or "going to" clause, we set a flag to show that
they can contain regions or rooms equally well. (Inform's kinds system has no
protocol for this; it could have, but we don't need this to be visible to authors
writing source text.)

=
int GoingPlugin::new_clause(action_pattern *ap, ap_clause *apoc) {
	if ((apoc->clause_ID == GOING_FROM_AP_CLAUSE) ||
		(apoc->clause_ID == GOING_TO_AP_CLAUSE))
		APClauses::set_opt(apoc, ALLOW_REGION_AS_ROOM_APCOPT);
	return FALSE;
}

@ Going nowhere is a special syntax:

=
void GoingPlugin::go_nowhere(action_pattern *ap) {
	APClauses::set_spec(ap, GOING_TO_AP_CLAUSE, Rvalues::new_nothing_object_constant());
}

int GoingPlugin::going_nowhere(action_pattern *ap) {
	if (Rvalues::is_nothing_object_constant(APClauses::spec(ap, GOING_TO_AP_CLAUSE)))
		return TRUE;
	return FALSE;
}

@ And similarly going somewhere:

=
void GoingPlugin::go_somewhere(action_pattern *ap) {
	APClauses::set_spec(ap, GOING_TO_AP_CLAUSE, Descriptions::from_kind(K_room, FALSE));
}

int GoingPlugin::going_somewhere(action_pattern *ap) {
	parse_node *val = APClauses::spec(ap, GOING_TO_AP_CLAUSE);
	if ((Descriptions::is_kind_like(val)) && (Kinds::eq(Descriptions::explicit_kind(val), K_room)))
		return TRUE;
	return FALSE;
}

@ These are recognised by this Preform nonterminal:

@d NOWHERE_AP_CLAUSE_OPTION   1
@d SOMEWHERE_AP_CLAUSE_OPTION 2

=
<going-action-irregular-operand> ::=
	nowhere |    ==> { NOWHERE_AP_CLAUSE_OPTION, - }
	somewhere    ==> { SOMEWHERE_AP_CLAUSE_OPTION, - }

@ Which we intercept thus, and thus avoid the noun being evaluated, but
instead setting the appropriate entry options bit:

=
int GoingPlugin::parse_clause(action_name *an, anl_clause *c, int *bits) {
	if ((c->clause_ID == NOUN_AP_CLAUSE) && (an) && (an == going_action) &&
		(<going-action-irregular-operand>(c->clause_text))) { *bits |= <<r>>; }
	return FALSE;
}

@ Options bits which we later pick up here, moving the irregular noun phrase
into the |GOING_TO_AP_CLAUSE| instead, where we supply our own evaluation:

=
int GoingPlugin::act_on_options(anl_entry *entry, int entry_options, int *fail) {
	if (entry_options & NOWHERE_AP_CLAUSE_OPTION) {
		wording W = ActionNameLists::get_clause_wording(entry, NOUN_AP_CLAUSE);
		ActionNameLists::truncate_clause(entry, NOUN_AP_CLAUSE, 0);
		if (ActionNameLists::has_clause(entry, GOING_TO_AP_CLAUSE)) *fail = TRUE;
		else {
			ActionNameLists::set_clause_wording(entry, GOING_TO_AP_CLAUSE, W);
			anl_clause *c = ActionNameLists::get_clause(entry, GOING_TO_AP_CLAUSE);
			c->evaluation = Rvalues::new_nothing_object_constant();
		}
	}
	if (entry_options & SOMEWHERE_AP_CLAUSE_OPTION) {
		wording W = ActionNameLists::get_clause_wording(entry, NOUN_AP_CLAUSE);
		ActionNameLists::truncate_clause(entry, NOUN_AP_CLAUSE, 0);
		if (ActionNameLists::has_clause(entry, GOING_TO_AP_CLAUSE)) *fail = TRUE;
		else {
			ActionNameLists::set_clause_wording(entry, GOING_TO_AP_CLAUSE, W);
			anl_clause *c = ActionNameLists::get_clause(entry, GOING_TO_AP_CLAUSE);
			c->evaluation = Descriptions::from_kind(K_room, FALSE);
		}
	}
	return FALSE;
}

@ Here we perform sanity checks on the clauses.

=
int GoingPlugin::validate(action_name *an, anl_clause *c, int *outcome) {
	char *keyword = NULL; kind *ka = NULL, *kb = NULL;
	switch (c->clause_ID) {
		case GOING_FROM_AP_CLAUSE: keyword = "from"; ka = K_room; kb = K_region; break;
		case GOING_TO_AP_CLAUSE: keyword = "to"; ka = K_room; kb = K_region; break;
		case GOING_BY_AP_CLAUSE: keyword = "by"; ka = K_thing; kb = NULL; break;
		case GOING_THROUGH_AP_CLAUSE: keyword = "through"; ka = K_door; kb = NULL; break;
		case PUSHING_AP_CLAUSE: keyword = "with"; ka = K_thing; kb = NULL; break;
	}
	if (keyword == NULL) return FALSE;
	*outcome = GoingPlugin::check_clause(c->evaluation, keyword, ka, kb);
	return TRUE;
}

@ Each clause can be within one of up to two kinds, or else can be "nothing"
or unspecified:

=
parse_node *PM_GoingWrongKind_issued_at = NULL;
parse_node *PM_GoingWithoutObject_issued_at = NULL;
int GoingPlugin::check_clause(parse_node *spec, char *keyword, kind *ka, kind *kb) {
	if (spec == NULL) return TRUE;
	if (Rvalues::is_nothing_object_constant(spec)) return TRUE;
	if (Specifications::is_description_like(spec)) {
		instance *oref = Specifications::object_exactly_described_if_any(spec);
		if ((oref == NULL) || (ka == NULL) || (Instances::of_kind(oref, ka)) ||
			((kb) && (Instances::of_kind(oref, kb)))) return TRUE;
		if (PM_GoingWrongKind_issued_at == current_sentence) return TRUE;
		PM_GoingWrongKind_issued_at = current_sentence;
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
	if (PM_GoingWithoutObject_issued_at == current_sentence) return TRUE;
	PM_GoingWithoutObject_issued_at = current_sentence;
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
int GoingPlugin::need_to_check_destination_exists(action_pattern *ap) {
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
int GoingPlugin::compare_specificity(action_pattern *ap1, action_pattern *ap2, int *rv,
	int *ignore_in) {
	*rv = 0;

	c_s_stage_law = I"III.2.4 - Action/Where/Other Optional Clauses";

	int rct1 = APClauses::number_with_aspect(ap1, GOING_APCA);
	int rct2 = APClauses::number_with_aspect(ap2, GOING_APCA);
	if (rct1 > rct2) { *rv = 1; return TRUE; }
	if (rct1 < rct2) { *rv = -1; return TRUE; }

	*ignore_in = TRUE; 

	*rv = APClauses::cmp_clause(PUSHING_AP_CLAUSE, ap1, ap2); if (*rv) return TRUE;
	*rv = APClauses::cmp_clause(GOING_BY_AP_CLAUSE, ap1, ap2); if (*rv) return TRUE;
	*rv = APClauses::cmp_clause(GOING_THROUGH_AP_CLAUSE, ap1, ap2); if (*rv) return TRUE;
	
	c_s_stage_law = I"III.2.2 - Action/Where/Room Where Action Takes Place";

	rct1 = APClauses::number_with_aspect(ap1, IN_APCA);
	rct2 = APClauses::number_with_aspect(ap2, IN_APCA);
	if (rct1 > rct2) { *rv = 1; return TRUE; }
	if (rct1 < rct2) { *rv = -1; return TRUE; }

	int suspend_usual_from_and_room = FALSE;

	if ((APClauses::spec(ap1, GOING_FROM_AP_CLAUSE)) &&
		(APClauses::spec(ap1, IN_AP_CLAUSE) == NULL) &&
		(APClauses::spec(ap2, IN_AP_CLAUSE)) &&
		(APClauses::spec(ap2, GOING_FROM_AP_CLAUSE) == NULL)) {
		*rv = APClauses::cmp_clauses(GOING_FROM_AP_CLAUSE, ap1, IN_AP_CLAUSE, ap2);
		if (*rv) return TRUE;
		suspend_usual_from_and_room = TRUE;
	}

	if ((APClauses::spec(ap2, GOING_FROM_AP_CLAUSE)) &&
		(APClauses::spec(ap2, IN_AP_CLAUSE) == NULL) &&
		(APClauses::spec(ap1, IN_AP_CLAUSE)) &&
		(APClauses::spec(ap1, GOING_FROM_AP_CLAUSE) == NULL)) {
		*rv = APClauses::cmp_clauses(IN_AP_CLAUSE, ap1, GOING_FROM_AP_CLAUSE, ap2);
		if (*rv) return TRUE;
		suspend_usual_from_and_room = TRUE;
	}

	if (suspend_usual_from_and_room == FALSE) {
		*rv = APClauses::cmp_clause(GOING_FROM_AP_CLAUSE, ap1, ap2); if (*rv) return TRUE;
		*rv = APClauses::cmp_clause(IN_AP_CLAUSE, ap1, ap2); if (*rv) return TRUE;
	}

	*rv = APClauses::cmp_clause(GOING_TO_AP_CLAUSE, ap1, ap2); if (*rv) return TRUE;

	return FALSE;
}
