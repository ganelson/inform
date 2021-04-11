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
			Produce::inv_primitive(Emit::tree(), EQ_BIP);
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), LOOKUP_BIP);
				Produce::down(Emit::tree());
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(MSTACK_HL));
					Produce::inv_call_iname(Emit::tree(), Hierarchy::find(MSTVON_HL));
					Produce::down(Emit::tree());
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (unsigned int) GoingPlugin::id());
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1);
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
			Produce::up(Emit::tree());
			return TRUE;
		case SOMEWHERE_CPMC: {
			parse_node *somewhere = Specifications::from_kind(K_room);
			RTActionPatterns::compile_pattern_match_clause(VH,
				RTTemporaryVariables::from_nve(RTVariables::nve_from_mstack(GoingPlugin::id(), 1, TRUE),
					K_object),
					somewhere, K_object, FALSE);
			return TRUE;
		}
		case NOT_NOWHERE_CPMC:
			Produce::inv_primitive(Emit::tree(), NE_BIP);
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), LOOKUP_BIP);
				Produce::down(Emit::tree());
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(MSTACK_HL));
					Produce::inv_call_iname(Emit::tree(), Hierarchy::find(MSTVON_HL));
					Produce::down(Emit::tree());
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (unsigned int) GoingPlugin::id());
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1);
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
			Produce::up(Emit::tree());
			return TRUE;
	}
	return FALSE;
}
