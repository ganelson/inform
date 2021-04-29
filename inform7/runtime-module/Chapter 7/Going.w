[RTGoing::] Going.

Tweaks to compiling APs for the going action.

@h Compiling action tries.

@e NOWHERE_CPMC
@e SOMEWHERE_CPMC
@e NOT_NOWHERE_CPMC

=
int RTGoing::set_pattern_match_requirements(action_pattern *ap, int *cpm, int needed[MAX_CPM_CLAUSES],
	ap_clause *needed_apoc[MAX_CPM_CLAUSES]) {
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

int RTGoing::compile_pattern_match_clause(value_holster *VH, action_pattern *ap, int cpmc) {
	switch (cpmc) {
		case NOWHERE_CPMC:
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::inv(LOOKUP_BIP);
				EmitCode::down();
					EmitCode::val_iname(K_value, Hierarchy::find(MSTACK_HL));
					EmitCode::call(Hierarchy::find(MSTVON_HL));
					EmitCode::down();
						EmitCode::val_iname(K_value, GoingPlugin::id());
						EmitCode::val_number(1);
					EmitCode::up();
				EmitCode::up();
				EmitCode::val_number(0);
			EmitCode::up();
			return TRUE;
		case SOMEWHERE_CPMC: {
			parse_node *somewhere = Specifications::from_kind(K_room);
			RTActionPatterns::compile_pattern_match_clause(VH,
				RTTemporaryVariables::from_nve(RTVariables::nve_from_named_mstack(GoingPlugin::id(), 1, TRUE),
					K_object),
					somewhere, K_object, FALSE);
			return TRUE;
		}
		case NOT_NOWHERE_CPMC:
			EmitCode::inv(NE_BIP);
			EmitCode::down();
				EmitCode::inv(LOOKUP_BIP);
				EmitCode::down();
					EmitCode::val_iname(K_value, Hierarchy::find(MSTACK_HL));
					EmitCode::call(Hierarchy::find(MSTVON_HL));
					EmitCode::down();
						EmitCode::val_iname(K_value, GoingPlugin::id());
						EmitCode::val_number(1);
					EmitCode::up();
				EmitCode::up();
				EmitCode::val_number(0);
			EmitCode::up();
			return TRUE;
	}
	return FALSE;
}
