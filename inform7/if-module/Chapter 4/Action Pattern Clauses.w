[APClauses::] Action Pattern Clauses.

Pattern-matches on individual nouns in an action are called clauses.

@

@e PARAMETRIC_AP_CLAUSE from 0
@e ACTOR_AP_CLAUSE
@e NOUN_AP_CLAUSE
@e SECOND_AP_CLAUSE
@e IN_AP_CLAUSE
@e IN_THE_PRESENCE_OF_AP_CLAUSE
@e WHEN_AP_CLAUSE

=
typedef struct ap_clause {
	int clause_ID;
	struct stacked_variable *stv_to_match;
	struct parse_node *clause_spec;
	int clause_options;
	struct ap_clause *next;
	CLASS_DEFINITION
} ap_clause;

@ The clause options are a bitmap. Some are meaningful only for one or two
clauses.

@d ALLOW_REGION_AS_ROOM_APCOPT 1
@d DO_NOT_VALIDATE_APCOPT 2
@d ACTOR_IS_NOT_PLAYER_APCOPT 4
@d REQUEST_APCOPT 8

@ =
int APClauses::opt(ap_clause *apoc, int opt) {
	if (apoc == NULL) return FALSE;
	if ((apoc->clause_options & opt) != 0) return TRUE;
	return FALSE;
}

void APClauses::set_opt(ap_clause *apoc, int opt) {
	if (apoc == NULL) internal_error("no such apoc");
	if ((apoc->clause_options & opt) == 0) apoc->clause_options += opt;
}

void APClauses::clear_opt(ap_clause *apoc, int opt) {
	if (apoc == NULL) internal_error("no such apoc");
	if (apoc->clause_options & opt) apoc->clause_options -= opt;
}

parse_node *APClauses::get_actor(action_pattern *ap) {
	return APClauses::get_val(ap, ACTOR_AP_CLAUSE);
}

void APClauses::set_actor(action_pattern *ap, parse_node *val) {
	APClauses::set_val(ap, ACTOR_AP_CLAUSE, val);
}

parse_node *APClauses::get_noun(action_pattern *ap) {
	return APClauses::get_val(ap, NOUN_AP_CLAUSE);
}

void APClauses::set_noun(action_pattern *ap, parse_node *val) {
	APClauses::set_val(ap, NOUN_AP_CLAUSE, val);
}

parse_node *APClauses::get_second(action_pattern *ap) {
	return APClauses::get_val(ap, SECOND_AP_CLAUSE);
}

void APClauses::set_second(action_pattern *ap, parse_node *val) {
	APClauses::set_val(ap, SECOND_AP_CLAUSE, val);
}

parse_node *APClauses::get_presence(action_pattern *ap) {
	return APClauses::get_val(ap, IN_THE_PRESENCE_OF_AP_CLAUSE);
}

void APClauses::set_presence(action_pattern *ap, parse_node *val) {
	APClauses::set_val(ap, IN_THE_PRESENCE_OF_AP_CLAUSE, val);
}

parse_node *APClauses::get_room(action_pattern *ap) {
	return APClauses::get_val(ap, IN_AP_CLAUSE);
}

void APClauses::set_room(action_pattern *ap, parse_node *val) {
	APClauses::set_val(ap, IN_AP_CLAUSE, val);
}

void APClauses::go_nowhere(action_pattern *ap) {
	APClauses::set_val(ap, GOING_TO_AP_CLAUSE, Rvalues::new_nothing_object_constant());
}

void APClauses::go_somewhere(action_pattern *ap) {
	APClauses::set_val(ap, GOING_TO_AP_CLAUSE, Descriptions::from_kind(K_room, FALSE));
}

int APClauses::going_nowhere(action_pattern *ap) {
	if (Rvalues::is_nothing_object_constant(APClauses::get_val(ap, GOING_TO_AP_CLAUSE))) return TRUE;
	return FALSE;
}

int APClauses::going_somewhere(action_pattern *ap) {
	parse_node *val = APClauses::get_val(ap, GOING_TO_AP_CLAUSE);
	if ((Descriptions::is_kind_like(val)) && (Kinds::eq(Descriptions::explicit_kind(val), K_room)))
		return TRUE;
	return FALSE;
}

void APClauses::any_actor(action_pattern *ap) {
	ap_clause *apoc = APClauses::ensure_clause(ap, ACTOR_AP_CLAUSE);
	APClauses::set_opt(apoc, ACTOR_IS_NOT_PLAYER_APCOPT);
}

int APClauses::has_any_actor(action_pattern *ap) {
	ap_clause *apoc = APClauses::clause(ap, ACTOR_AP_CLAUSE);
	if (APClauses::opt(apoc, ACTOR_IS_NOT_PLAYER_APCOPT)) return TRUE;
	return FALSE;
}

void APClauses::set_request(action_pattern *ap) {
	ap_clause *apoc = APClauses::ensure_clause(ap, ACTOR_AP_CLAUSE);
	APClauses::set_opt(apoc, REQUEST_APCOPT);
}

void APClauses::clear_request(action_pattern *ap) {
	ap_clause *apoc = APClauses::ensure_clause(ap, ACTOR_AP_CLAUSE);
	APClauses::clear_opt(apoc, REQUEST_APCOPT);
}

int APClauses::is_request(action_pattern *ap) {
	ap_clause *apoc = APClauses::clause(ap, ACTOR_AP_CLAUSE);
	if (APClauses::opt(apoc, REQUEST_APCOPT)) return TRUE;
	return FALSE;
}

parse_node *APClauses::get_val(action_pattern *ap, int C) {
	ap_clause *apoc = APClauses::clause(ap, C);
	return (apoc)?(apoc->clause_spec):NULL;
}

void APClauses::set_val(action_pattern *ap, int C, parse_node *val) {
	if (val == NULL) {
		ap_clause *apoc = APClauses::clause(ap, C);
		if (apoc) apoc->clause_spec = val;
	} else {
		ap_clause *apoc = APClauses::ensure_clause(ap, C);
		apoc->clause_spec = val;
	}
}

void APClauses::nullify_nonspecific(action_pattern *ap, int C) {
	ap_clause *apoc = APClauses::clause(ap, C);
	if (apoc) apoc->clause_spec = ActionPatterns::nullify_nonspecific_references(apoc->clause_spec);
}

ap_clause *APClauses::clause(action_pattern *ap, int C) {
	return APClauses::find_clause(ap, C, FALSE);
}

ap_clause *APClauses::ensure_clause(action_pattern *ap, int C) {
	return APClauses::find_clause(ap, C, TRUE);
}

ap_clause *APClauses::find_clause(action_pattern *ap, int C, int make) {
	if (ap) {
		ap_clause *last = NULL;
		for (ap_clause *apoc = ap->ap_clauses; apoc; apoc = apoc->next) {
			if (apoc->clause_ID == C) return apoc;
			if (apoc->clause_ID > C) {
				if (make) @<Make a new clause@>
				else return NULL;
			}
			last = apoc;
		}
		if (make) {
			ap_clause *apoc = NULL;
			@<Make a new clause@>;
		}
	} else {
		if (make) internal_error("cannot make clause in null AP");
	}
	return NULL;
}

@<Make a new clause@> =
	ap_clause *new_apoc = CREATE(ap_clause);
	new_apoc->clause_ID = C;
	new_apoc->stv_to_match = NULL;
	new_apoc->clause_spec = NULL;
	new_apoc->clause_options = 0;
	if (last == NULL) ap->ap_clauses = new_apoc; else last->next = new_apoc;
	new_apoc->next = apoc;
	return new_apoc;

@ =
void APClauses::ap_add_optional_clause(action_pattern *ap, stacked_variable *stv,
	wording W) {
	if (stv == NULL) internal_error("no stacked variable for apoc");
	parse_node *spec = ParseActionPatterns::verified_action_parameter(W);
	int oid = StackedVariables::get_owner_id(stv);
	int off = StackedVariables::get_offset(stv);
	
	int C = 1000*oid + off;
	int D = Going::divert(ap, stv); if (D >= 0) C = D;
	ap_clause *apoc = APClauses::ensure_clause(ap, C);
	apoc->stv_to_match = stv;
	apoc->clause_spec = spec;
	Going::new_clause(ap, apoc);
}

int APClauses::has_stv_clauses(action_pattern *ap) {
	if ((ap) && (APClauses::nudge_to_stv_apoc(ap->ap_clauses))) return TRUE;
	return FALSE;
}

int APClauses::compare_specificity_of_apoc_list(action_pattern *ap1, action_pattern *ap2) {
	int rct1 = APClauses::ap_count_optional_clauses(ap1);
	int rct2 = APClauses::ap_count_optional_clauses(ap2);

	if (rct1 > rct2) return 1;
	if (rct1 < rct2) return -1;
	if (rct1 == 0) return 0;

	ap_clause *apoc1 = APClauses::nudge_to_stv_apoc(ap1->ap_clauses),
		*apoc2 = APClauses::nudge_to_stv_apoc(ap2->ap_clauses);
	while ((apoc1) && (apoc2)) {
		int off1 = StackedVariables::get_offset(apoc1->stv_to_match);
		int off2 = StackedVariables::get_offset(apoc2->stv_to_match);
		if (off1 == off2) {
			int rv = Specifications::compare_specificity(apoc1->clause_spec, apoc2->clause_spec, NULL);
			if (rv != 0) return rv;
			apoc1 = APClauses::nudge_to_stv_apoc(apoc1->next);
			apoc2 = APClauses::nudge_to_stv_apoc(apoc2->next);
		}
		if (off1 < off2) apoc1 = APClauses::nudge_to_stv_apoc(apoc1->next);
		if (off1 > off2) apoc2 = APClauses::nudge_to_stv_apoc(apoc2->next);
	}
	return 0;
}

int APClauses::ap_count_optional_clauses(action_pattern *ap) {
	int n = 0;
	if (ap)
		for (ap_clause *apoc = APClauses::nudge_to_stv_apoc(ap->ap_clauses); apoc;
			apoc = APClauses::nudge_to_stv_apoc(apoc->next))
			n++;
	return n;
}

ap_clause *APClauses::nudge_to_stv_apoc(ap_clause *apoc) {
	while ((apoc) && (apoc->stv_to_match == NULL)) apoc = apoc->next;
	return apoc;
}

int APClauses::validate(ap_clause *apoc, kind *K) {
	if ((apoc) &&
		(APClauses::opt(apoc, DO_NOT_VALIDATE_APCOPT) == FALSE) &&
		(Dash::validate_parameter(apoc->clause_spec, K) == FALSE))
		return FALSE;
	return TRUE;
}

void APClauses::write(OUTPUT_STREAM, action_pattern *ap) {
	for (ap_clause *apoc = (ap)?(ap->ap_clauses):NULL; apoc; apoc = apoc->next) {
		switch (apoc->clause_ID) {
			case PARAMETRIC_AP_CLAUSE:         WRITE("parameter"); break;
			case ACTOR_AP_CLAUSE:              WRITE("actor"); break;
			case NOUN_AP_CLAUSE:               WRITE("noun"); break;
			case SECOND_AP_CLAUSE:             WRITE("second"); break;
			case IN_AP_CLAUSE:                 WRITE("in"); break;
			case IN_THE_PRESENCE_OF_AP_CLAUSE: WRITE("in-presence"); break;
			case WHEN_AP_CLAUSE:               WRITE("when"); break;
		}
		Going::write(OUT, apoc->clause_ID);
		if (apoc->stv_to_match) {
			WRITE("{");
			NonlocalVariables::write(OUT,
				StackedVariables::get_variable(apoc->stv_to_match));
			WRITE("}");
		}
		WRITE(": %P", apoc->clause_spec);
		if (APClauses::opt(apoc, ALLOW_REGION_AS_ROOM_APCOPT)) WRITE("[allow-region]");
		if (APClauses::opt(apoc, DO_NOT_VALIDATE_APCOPT)) WRITE("[no-validate]");
		if (APClauses::opt(apoc, ACTOR_IS_NOT_PLAYER_APCOPT)) WRITE("[not-player]");
		if (APClauses::opt(apoc, REQUEST_APCOPT)) WRITE("[request]");
	}
}

@h Action pattern specificity.
The following is one of Inform's standardised comparison routines, which
takes a pair of objects A, B and returns 1 if A makes a more specific
description than B, 0 if they seem equally specific, or $-1$ if B makes a
more specific description than A. This is transitive, and intended to be
used in sorting algorithms.

=
int APClauses::count_aspects(action_pattern *ap) {
	if (ap == NULL) return 0;
	int c = Going::count_aspects(ap);
	if ((APClauses::get_noun(ap)) ||
		(APClauses::get_second(ap)) ||
		(APClauses::get_actor(ap)))
		c++;
	if (APClauses::get_presence(ap)) c++;
	if ((ap->duration) || (APClauses::get_val(ap, WHEN_AP_CLAUSE))) c++;
	if (APClauses::get_val(ap, PARAMETRIC_AP_CLAUSE)) c++;
	return c;
}

int APClauses::compare_specificity(action_pattern *ap1, action_pattern *ap2) {
	c_s_stage_law = I"III.1 - Object To Which Rule Applies";

	int rv = Specifications::compare_specificity(APClauses::get_val(ap1, PARAMETRIC_AP_CLAUSE), APClauses::get_val(ap2, PARAMETRIC_AP_CLAUSE), NULL);
	if (rv != 0) return rv;

	int claim = FALSE;
	rv = Going::compare_specificity(ap1, ap2, &claim);
	if (rv != 0) return rv;

	if (claim == FALSE) {
		c_s_stage_law = I"III.2.2 - Action/Where/Room Where Action Takes Place";
		rv = Specifications::compare_specificity(APClauses::get_room(ap1), APClauses::get_room(ap2), NULL);
		if (rv != 0) return rv;
	}

	c_s_stage_law = I"III.2.3 - Action/Where/In The Presence Of";

	rv = Specifications::compare_specificity(APClauses::get_presence(ap1), APClauses::get_presence(ap2), NULL);
	if (rv != 0) return rv;

	rv = APClauses::compare_specificity_of_apoc_list(ap1, ap2);
	if (rv != 0) return rv;

	c_s_stage_law = I"III.3.1 - Action/What/Second Thing Acted On";

	rv = Specifications::compare_specificity(APClauses::get_second(ap1), APClauses::get_second(ap2), NULL);
	if (rv != 0) return rv;

	c_s_stage_law = I"III.3.2 - Action/What/Thing Acted On";

	rv = Specifications::compare_specificity(APClauses::get_noun(ap1), APClauses::get_noun(ap2), NULL);
	if (rv != 0) return rv;

	c_s_stage_law = I"III.3.3 - Action/What/Actor Performing Action";

	rv = Specifications::compare_specificity(APClauses::get_actor(ap1), APClauses::get_actor(ap2), NULL);
	if (rv != 0) return rv;

	return 0;
}
