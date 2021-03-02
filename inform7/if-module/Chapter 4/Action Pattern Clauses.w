[APClauses::] Action Pattern Clauses.

Pattern-matches on individual nouns in an action are called clauses.

@

@e ACTOR_AP_CLAUSE from 1
@e NOUN_AP_CLAUSE
@e SECOND_AP_CLAUSE
@e IN_AP_CLAUSE
@e IN_THE_PRESENCE_OF_AP_CLAUSE
@e WHEN_AP_CLAUSE
@e GOING_FROM_AP_CLAUSE
@e GOING_TO_AP_CLAUSE
@e GOING_BY_AP_CLAUSE
@e GOING_THROUGH_AP_CLAUSE
@e PUSHING_AP_CLAUSE
@e STV_AP_CLAUSE

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

@ =
int APClauses::opt(ap_clause *apoc, int opt) {
	return (((apoc) && (apoc->clause_options)) & opt)?TRUE:FALSE;
}

void APClauses::set_opt(ap_clause *apoc, int opt) {
	if (apoc == NULL) internal_error("no such apoc");
	apoc->clause_options |= opt;
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

ap_clause *APClauses::find_clause(action_pattern *ap, int clause, int make) {
	if (ap) {
		ap_clause *last = NULL;
		for (ap_clause *apoc = ap->ap_clauses; apoc; apoc = apoc->next) {
			if (apoc->clause_ID == clause)
				return apoc;
			last = apoc;
		}
		if (make) {
			ap_clause *new_apoc = APClauses::apoc_new(clause, NULL, NULL);
			if (last == NULL) ap->ap_clauses = new_apoc;
			else last->next = new_apoc;
			return new_apoc;
		}
	} else {
		if (make) internal_error("cannot make clause in null AP");
	}
	return NULL;
}

ap_clause *APClauses::find_stv(action_pattern *ap, stacked_variable *stv) {
	if (ap)
		for (ap_clause *apoc = ap->ap_clauses; apoc; apoc = apoc->next)
			if (apoc->stv_to_match == stv)
				return apoc;
	return NULL;
}

ap_clause *APClauses::apoc_new(int clause, stacked_variable *stv, parse_node *spec) {
	ap_clause *apoc = CREATE(ap_clause);
	apoc->clause_ID = clause;
	apoc->stv_to_match = stv;
	apoc->clause_spec = spec;
	apoc->next = NULL;
	apoc->clause_options = FALSE;
	return apoc;
}

void APClauses::ap_add_optional_clause(action_pattern *ap, stacked_variable *stv,
	wording W) {
	if (stv == NULL) internal_error("no stacked variable for apoc");
	ap_clause *apoc = APClauses::apoc_new(STV_AP_CLAUSE, stv,
		ParseActionPatterns::verified_action_parameter(W));
	int oid = StackedVariables::get_owner_id(apoc->stv_to_match);
	int off = StackedVariables::get_offset(apoc->stv_to_match);
	if (ap->ap_clauses == NULL) {
		ap->ap_clauses = apoc;
		apoc->next = NULL;
	} else {
		ap_clause *oapoc = ap->ap_clauses, *papoc = NULL;
		while (oapoc) {
			if (oapoc->stv_to_match) {
				int ooff = StackedVariables::get_offset(oapoc->stv_to_match);
				if (off < ooff) {
					if (oapoc == ap->ap_clauses) {
						apoc->next = ap->ap_clauses;
						ap->ap_clauses = apoc;
						papoc = NULL;
					} else {
						apoc->next = papoc->next;
						papoc->next = apoc;
						papoc = NULL;
					}
					break;
				}
			}
			papoc = oapoc;
			oapoc = oapoc->next;
		}
		if (papoc) {
			apoc->next = NULL;
			papoc->next = apoc;
		}
	}

	if (oid == 20007 /* i.e., going */ ) {
		switch (off) {
			case 0: ap->from_spec = apoc->clause_spec;
				APClauses::set_opt(apoc, ALLOW_REGION_AS_ROOM_APCOPT); break;
			case 1: ap->to_spec = apoc->clause_spec;
				APClauses::set_opt(apoc, ALLOW_REGION_AS_ROOM_APCOPT); break;
			case 2: ap->through_spec = apoc->clause_spec; break;
			case 3: ap->by_spec = apoc->clause_spec; break;
			case 4: ap->pushing_spec = apoc->clause_spec; break;
		}
	}
	ap->chief_action_owner_id = oid;
}

int APClauses::ap_count_optional_clauses(action_pattern *ap) {
	int n = 0;
	if (ap)
		for (ap_clause *apoc = ap->ap_clauses; apoc; apoc = apoc->next)
			if (apoc->stv_to_match)
				if ((ap->chief_action_owner_id != 20007) ||
					(StackedVariables::get_offset(apoc->stv_to_match) >= 5))
					n++;
	return n;
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
	if (ap1->chief_action_owner_id != ap2->chief_action_owner_id) return 0;

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
