[RTGoing::] Matching Going Action Patterns.

Tweaks to compiling APs for the going action.

@ We will need three extra CPMCs (see //Matching Action Patterns//).

@e NOWHERE_CPMC
@e SOMEWHERE_CPMC
@e NOT_NOWHERE_CPMC

=
int RTGoing::set_pattern_match_requirements(action_pattern *ap, int *cpm,
	int needed[MAX_CPM_CLAUSES], ap_clause *needed_apoc[MAX_CPM_CLAUSES]) {
	int cpm_count = *cpm;

	if (GoingPlugin::going_nowhere(ap)) {
		CPMC_NEEDED(NOWHERE_CPMC, NULL);
	} else if (GoingPlugin::going_somewhere(ap)) {
		CPMC_NEEDED(SOMEWHERE_CPMC, NULL);
	} else if (GoingPlugin::need_to_check_destination_exists(ap)) {
		CPMC_NEEDED(NOT_NOWHERE_CPMC, NULL);
	}

	*cpm = cpm_count;
	return FALSE;
}

@ The implementation of these three clauses assumes throughout that variable
number 1 in the shared variable set owned by the going action is the "to"
variable, the one storing the room being gone to.

=
int RTGoing::compile_pattern_match_clause(action_pattern *ap, int cpmc) {
	nonlocal_variable_emission nve =
		RTVariables::nve_from_mstack(GoingPlugin::id(), 1, TRUE);
	switch (cpmc) {
		case NOWHERE_CPMC:     @<Compile NOWHERE_CPMC test@>;     return TRUE;
		case NOT_NOWHERE_CPMC: @<Compile NOT_NOWHERE_CPMC test@>; return TRUE;
		case SOMEWHERE_CPMC:   @<Compile SOMEWHERE_CPMC test@>;   return TRUE;
	}
	return FALSE;
}

@ This handles the irregular usage "going nowhere". (The noun for "going" is
ordinarily a direction.)

@<Compile NOWHERE_CPMC test@> =
	EmitCode::inv(EQ_BIP);
	EmitCode::down();
		RTVariables::compile_NVE_as_val(NULL, &nve);
		EmitCode::val_number(0);
	EmitCode::up();

@ The not-nowhere test is needed for patterns like "going from the Dining Room",
which we want to match only where there is some destination: i.e., we don't want
it to match an attemot to go in a direction not available in the map.

@<Compile NOT_NOWHERE_CPMC test@> =
	EmitCode::inv(NE_BIP);
	EmitCode::down();
		RTVariables::compile_NVE_as_val(NULL, &nve);
		EmitCode::val_number(0);
	EmitCode::up();

@ And this handles "going somewhere", testing that the destination is a room.

@<Compile SOMEWHERE_CPMC test@> =
	parse_node *somewhere = Specifications::from_kind(K_room);
	RTActionPatterns::variable_matches_specification(
		TemporaryVariables::from_nve(nve, K_object),
		somewhere, K_object, FALSE);
