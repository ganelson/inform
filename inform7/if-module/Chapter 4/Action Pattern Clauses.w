[APClauses::] Action Pattern Clauses.

Pattern-matches on individual nouns in an action are called clauses.

@h Clause IDs.
Clauses come in types, each with their own ID. Some are hard-wired into
the compiler: |IN_THE_PRESENCE_OF_AP_CLAUSE|, for example. Others arise
from Inform source text adding optional clauses to actions which are based
on matching action variables: see //Action Variables//.

The set of clauses in an //action_pattern// is stored as a linked list
of //ap_clause// objects. Clauses must be listed in increasing ID order,
and cannot contain two clauses with the same ID. The ID numbers will either
be one of the |*_AP_CLAUSE| enumerated values, which are clauses where the
Inform compiler has to do something special involving them, or else will
be determined by //APClauses::clause_ID_for_action_variable// for matching
action variable clauses.

@e PARAMETRIC_AP_CLAUSE from 0
@e ACTOR_AP_CLAUSE
@e NOUN_AP_CLAUSE
@e SECOND_AP_CLAUSE
@e IN_AP_CLAUSE
@e IN_THE_PRESENCE_OF_AP_CLAUSE
@e WHEN_AP_CLAUSE
@e TAIL_AP_CLAUSE

=
int APClauses::clause_ID_for_action_variable(shared_variable *stv) {
	int D = -1;
	PluginCalls::divert_AP_clause_ID(stv, &D); if (D >= 0) return D;
	int oid = SharedVariables::get_owner_id(stv);
	int off = SharedVariables::get_index(stv);
	return 1000*oid + off;
}

void APClauses::write_clause_ID(OUTPUT_STREAM, int C, shared_variable *stv) {
	switch (C) {
		case PARAMETRIC_AP_CLAUSE:         WRITE("parameter"); break;
		case ACTOR_AP_CLAUSE:              WRITE("actor"); break;
		case NOUN_AP_CLAUSE:               WRITE("noun"); break;
		case SECOND_AP_CLAUSE:             WRITE("second"); break;
		case IN_AP_CLAUSE:                 WRITE("in"); break;
		case IN_THE_PRESENCE_OF_AP_CLAUSE: WRITE("in-presence"); break;
		case WHEN_AP_CLAUSE:               WRITE("when"); break;
		case TAIL_AP_CLAUSE:               WRITE("tail"); break;
	}
	PluginCalls::write_AP_clause_ID(OUT, C);
	if (stv) {
		WRITE("{");
		NonlocalVariables::write(OUT, SharedVariables::get_variable(stv));
		WRITE("}");
	}
}

@h Clauses and their ordering.
A single clause is an instance of:

=
typedef struct ap_clause {
	int clause_ID;
	struct shared_variable *stv_to_match; /* can be |NULL| for some built-in clause IDs */
	struct parse_node *clause_spec; /* what the pattern says about this value */
	int clause_options; /* a bitmap of flags: see below */
	struct ap_clause *next; /* in the linked list of clauses for an action pattern */
	CLASS_DEFINITION
} ap_clause;

@ This loop conveniently runs through the clauses for |ap|:

@d LOOP_OVER_AP_CLAUSES(var, ap)
	for (ap_clause *var = (ap)?(ap->ap_clauses):NULL; var; var = var->next)

@ The list is stored in increasing order of clause ID. The only way to add new
clauses is with the following, which finds clause |C| if it exists, and if not
either returns |NULL| or creates clause |C| (inserting at the correct list
position), depending on whether |make| is set.

=
ap_clause *APClauses::find_clause(action_pattern *ap, int C, int make) {
	if (ap) {
		ap_clause *last = NULL;
		LOOP_OVER_AP_CLAUSES(apoc, ap) {
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

@ A more descriptive way to call this function:

=
ap_clause *APClauses::clause(action_pattern *ap, int C) {
	return APClauses::find_clause(ap, C, FALSE);
}

ap_clause *APClauses::ensure_clause(action_pattern *ap, int C) {
	return APClauses::find_clause(ap, C, TRUE);
}

@ Each clause contains a specification. Note that not providing a clause is
almost the same thing as providing one with specification |NULL|. But only
almost, because there could also be options set on it.

=
parse_node *APClauses::spec(action_pattern *ap, int C) {
	ap_clause *apoc = APClauses::clause(ap, C);
	return (apoc)?(apoc->clause_spec):NULL;
}

void APClauses::set_spec(action_pattern *ap, int C, parse_node *val) {
	if (val == NULL) {
		ap_clause *apoc = APClauses::clause(ap, C);
		if (apoc) apoc->clause_spec = val;
	} else {
		ap_clause *apoc = APClauses::ensure_clause(ap, C);
		apoc->clause_spec = val;
	}
}

@ And this uses the //values: Dash// typechecker to validate that a specification
makes sense in a given clause:

=
int APClauses::validate(ap_clause *apoc, kind *K) {
	if ((apoc) && (Dash::validate_parameter(apoc->clause_spec, K) == FALSE))
		return FALSE;
	return TRUE;
}

@h Clause options.
The clause options are a bitmap. Some are meaningful only for one or two
clauses.

@d ALLOW_REGION_AS_ROOM_APCOPT 1
@d ACTOR_IS_NOT_PLAYER_APCOPT  2
@d REQUEST_APCOPT              4

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

@ We can now write:

=
void APClauses::write(OUTPUT_STREAM, action_pattern *ap) {
	int c = 0;
	LOOP_OVER_AP_CLAUSES(apoc, ap) {
		if (c++ > 0) WRITE(" ");
		APClauses::write_clause_ID(OUT, apoc->clause_ID, apoc->stv_to_match);
		WRITE(": ");
		instance *I = Specifications::object_exactly_described_if_any(apoc->clause_spec);
		if (I) {
			Instances::write(OUT, I);
		} else if (Specifications::is_description(apoc->clause_spec)) {
			pcalc_prop *prop = Specifications::to_proposition(apoc->clause_spec);
			Propositions::write(OUT, prop);
		} else {
			WRITE("%P", apoc->clause_spec);
		}
		if (APClauses::opt(apoc, ALLOW_REGION_AS_ROOM_APCOPT)) WRITE("[allow-region]");
		if (APClauses::opt(apoc, ACTOR_IS_NOT_PLAYER_APCOPT)) WRITE("[not-player]");
		if (APClauses::opt(apoc, REQUEST_APCOPT)) WRITE("[request]");
	}
}

@h Actor options.
Two options are used with the actor clause (only), reflecting the unusual ways
it can be used. 

First, the following is for action patterns like "an actor taking the medallion".
Here the requirement on the actor is not ${\it person}(c_a)$ but instead forces
$c_a$ not to be the player. The principled thing might be to set the |clause_spec|
to the proposition ${\it person}(c_a)\land c_a\neq {\it player}$, but that would
be annoying to test for. So we give it an option flag instead:

=
void APClauses::make_actor_anyone_except_player(action_pattern *ap) {
	ap_clause *apoc = APClauses::ensure_clause(ap, ACTOR_AP_CLAUSE);
	APClauses::set_opt(apoc, ACTOR_IS_NOT_PLAYER_APCOPT);
}

int APClauses::actor_is_anyone_except_player(action_pattern *ap) {
	ap_clause *apoc = APClauses::clause(ap, ACTOR_AP_CLAUSE);
	if (APClauses::opt(apoc, ACTOR_IS_NOT_PLAYER_APCOPT)) return TRUE;
	return FALSE;
}

@ Secondly, when the following is set, the action is a request. Thus "asking
Matilda to try taking the medallion" would have this option set, but "Matilda
taking the medallion" would not.

=
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

@h Action variable clauses.
The following functions deal only with clauses which are attached to action
variables:

=
void APClauses::set_action_variable_spec(action_pattern *ap, shared_variable *stv,
	parse_node *spec) {
	if (stv == NULL) internal_error("no shared variable for apoc");
	int C = APClauses::clause_ID_for_action_variable(stv);
	ap_clause *apoc = APClauses::ensure_clause(ap, C);
	apoc->stv_to_match = stv;
	apoc->clause_spec = spec;
	PluginCalls::new_action_variable_clause(ap, apoc);
}

ap_clause *APClauses::advance_to_next_av_clause(ap_clause *apoc) {
	while ((apoc) && (apoc->stv_to_match == NULL)) apoc = apoc->next;
	return apoc;
}

int APClauses::has_action_variable_clauses(action_pattern *ap) {
	if ((ap) && (APClauses::advance_to_next_av_clause(ap->ap_clauses))) return TRUE;
	return FALSE;
}

int APClauses::count_action_variable_clauses(action_pattern *ap) {
	int n = 0;
	if (ap)
		for (ap_clause *apoc = APClauses::advance_to_next_av_clause(ap->ap_clauses); apoc;
			apoc = APClauses::advance_to_next_av_clause(apoc->next))
			n++;
	return n;
}

int APClauses::compare_specificity_of_av_clauses(action_pattern *ap1, action_pattern *ap2) {
	int rct1 = APClauses::count_action_variable_clauses(ap1);
	int rct2 = APClauses::count_action_variable_clauses(ap2);

	if (rct1 > rct2) return 1;
	if (rct1 < rct2) return -1;
	if (rct1 == 0) return 0;

	ap_clause *apoc1 = APClauses::advance_to_next_av_clause(ap1->ap_clauses),
		*apoc2 = APClauses::advance_to_next_av_clause(ap2->ap_clauses);
	while ((apoc1) && (apoc2)) {
		int off1 = SharedVariables::get_index(apoc1->stv_to_match);
		int off2 = SharedVariables::get_index(apoc2->stv_to_match);
		if (off1 == off2) {
			int rv = Specifications::compare_specificity(
				apoc1->clause_spec, apoc2->clause_spec, NULL);
			if (rv != 0) return rv;
			apoc1 = APClauses::advance_to_next_av_clause(apoc1->next);
			apoc2 = APClauses::advance_to_next_av_clause(apoc2->next);
		}
		if (off1 < off2) apoc1 = APClauses::advance_to_next_av_clause(apoc1->next);
		if (off1 > off2) apoc2 = APClauses::advance_to_next_av_clause(apoc2->next);
	}
	return 0;
}

@h Aspects.
Clauses are divided into groups called "aspects", each of which has an ID
in the |*_APCA| enumeration.

@e PARAMETRIC_APCA from 0
@e PRIMARY_APCA
@e IN_APCA
@e PRESENCE_APCA
@e WHEN_APCA
@e TAIL_APCA
@e MISC_APCA

=
int APClauses::aspect(ap_clause *apoc) {
	switch (apoc->clause_ID) {
		case PARAMETRIC_AP_CLAUSE:         return PARAMETRIC_APCA;
		case ACTOR_AP_CLAUSE:              return PRIMARY_APCA;
		case NOUN_AP_CLAUSE:               return PRIMARY_APCA;
		case SECOND_AP_CLAUSE:             return PRIMARY_APCA;
		case IN_AP_CLAUSE:                 return IN_APCA;
		case IN_THE_PRESENCE_OF_AP_CLAUSE: return PRESENCE_APCA;
		case WHEN_AP_CLAUSE:               return WHEN_APCA;
		case TAIL_AP_CLAUSE:               return TAIL_APCA;
	}
	int rv = -1;
	PluginCalls::aspect_of_AP_clause_ID(apoc->clause_ID, &rv);
	if (rv >= 0) return rv;
	return MISC_APCA;
}

@ How many clauses with aspect |A| does the pattern have?

=
int APClauses::number_with_aspect(action_pattern *ap, int A) {
	int c = 0;
	LOOP_OVER_AP_CLAUSES(apoc, ap)
		if (APClauses::aspect(apoc) == A)
			c++;
	return c;
}

@ How many different aspects can be found among the pattern's clauses?

=
int APClauses::count_aspects(action_pattern *ap) {
	int asps[NO_DEFINED_APCA_VALUES];
	for (int a=0; a<NO_DEFINED_APCA_VALUES; a++) asps[a] = FALSE;
	LOOP_OVER_AP_CLAUSES(apoc, ap) asps[APClauses::aspect(apoc)] = TRUE;
	if ((ap) && (ap->duration)) asps[WHEN_APCA] = TRUE;
	int c = 0;
	for (int a=0; a<NO_DEFINED_APCA_VALUES; a++) if (asps[a]) c++;
	return c;
}

@ There are major limitations on which action patterns can be tested in
the past tense. They can only specify primary clauses, and then only with
definite values or descriptions of specific objects.

=
int APClauses::viable_in_past_tense(action_pattern *ap) {
	if (ExplicitActions::ap_overspecific(ap)) return FALSE;
	LOOP_OVER_AP_CLAUSES(apoc, ap)
		if (APClauses::aspect(apoc) == PRIMARY_APCA)
			if (APClauses::pta_acceptable(apoc->clause_spec) == FALSE)
				return FALSE;
	return TRUE;
}

int APClauses::pta_acceptable(parse_node *spec) {
	if (spec == NULL) return TRUE;
	if (Specifications::is_description(spec) == FALSE) return TRUE;
	if (Specifications::object_exactly_described_if_any(spec)) return TRUE;
	return FALSE;
}

@h Specificity.
See //ActionPatterns::compare_specificity//, which calls this to look at clauses.
The code here looks innocent enough but has significant implications for rule
sorting.

=
int APClauses::compare_specificity(action_pattern *ap1, action_pattern *ap2) {
	Specifications::law(I"III.1 - Object To Which Rule Applies");
	int rv = APClauses::cmp_clause(PARAMETRIC_AP_CLAUSE, ap1, ap2); if (rv) return rv;

	int ignore_in = FALSE;
	rv = 0; PluginCalls::compare_AP_specificity(ap1, ap2, &rv, &ignore_in);
	if (rv != 0) return rv;

	if (ignore_in == FALSE) {
		Specifications::law(I"III.2.2 - Action/Where/Room Where Action Takes Place");
		rv = APClauses::cmp_clause(IN_AP_CLAUSE, ap1, ap2); if (rv) return rv;
	}

	Specifications::law(I"III.2.3 - Action/Where/In The Presence Of");

	rv = APClauses::cmp_clause(IN_THE_PRESENCE_OF_AP_CLAUSE, ap1, ap2); if (rv) return rv;

	rv = APClauses::compare_specificity_of_av_clauses(ap1, ap2);
	if (rv != 0) return rv;

	Specifications::law(I"III.3.1 - Action/What/Second Thing Acted On");
	rv = APClauses::cmp_clause(SECOND_AP_CLAUSE, ap1, ap2); if (rv) return rv;

	Specifications::law(I"III.3.2 - Action/What/Thing Acted On");
	rv = APClauses::cmp_clause(NOUN_AP_CLAUSE, ap1, ap2); if (rv) return rv;

	Specifications::law(I"III.3.3 - Action/What/Actor Performing Action");
	rv = APClauses::cmp_clause(ACTOR_AP_CLAUSE, ap1, ap2); if (rv) return rv;

	return 0;
}

int APClauses::cmp_clause(int C, action_pattern *ap1, action_pattern *ap2) {
	return APClauses::cmp_clauses(C, ap1, C, ap2);
}

int APClauses::cmp_clauses(int C1, action_pattern *ap1, int C2, action_pattern *ap2) {
	return Specifications::compare_specificity(
		APClauses::spec(ap1, C1), APClauses::spec(ap2, C2), NULL);
}
