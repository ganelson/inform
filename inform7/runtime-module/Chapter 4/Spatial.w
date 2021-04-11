[RTSpatial::] Spatial.

@ This goes right back to a curious feature of Inform 1, in 1993. To enable
the use of player's holdalls, we must declare a constant |RUCKSACK_CLASS| to
tell some code in |WorldModelKit| to use possessions with this Inter class as
the rucksack pro tem. This is all a bit of a hack, and isn't really fully
general: only the player has the benefit of a "player's holdall" (hence the
name), with other actors oblivious.

=
void RTSpatial::compile_players_holdall(void) {
	if (K_players_holdall) {
		inter_name *iname = Hierarchy::find(RUCKSACK_CLASS_HL);
		Hierarchy::make_available(Emit::tree(), iname);
		Emit::named_iname_constant(iname, K_value,
			RTKinds::I6_classname(K_players_holdall));
	}
}

@ Note that |FoundEverywhere| is a template routine existing
to provide a common value of the I6 |found_in| property -- common that is
to all backdrops which are currently everywhere.

=
void RTSpatial::schema_everywhere(up_family *self, int task, unary_predicate *up,
	annotated_i6_schema *asch, kind *K) {
	switch(task) {
		case TEST_ATOM_TASK:
			Calculus::Schemas::modify(asch->schema, "BackdropEverywhere(*1)");
			break;
		case NOW_ATOM_TRUE_TASK:
			Calculus::Schemas::modify(asch->schema,
				"MoveObject(*1, FoundEverywhere); MoveFloatingObjects();");
			break;
		case NOW_ATOM_FALSE_TASK:
			StandardProblems::sentence_problem(Task::syntax_tree(),
				_p_(PM_CantChangeEverywhere),
				"not being 'everywhere' is not something which can be changed "
				"during play using 'now'",
				"because it's not exact enough about what needs to be done.");
			asch->schema = NULL; break;
	}
}

void RTSpatial::schema_nowhere(up_family *self, int task, unary_predicate *up,
	annotated_i6_schema *asch, kind *K) {
	switch(task) {
		case TEST_ATOM_TASK:
			Calculus::Schemas::modify(asch->schema, "LocationOf(*1) == nothing");
			break;
		case NOW_ATOM_TRUE_TASK:
			Calculus::Schemas::modify(asch->schema, "RemoveFromPlay(*1);");
			break;
		case NOW_ATOM_FALSE_TASK:
			Calculus::Schemas::modify(asch->schema, "MoveObject(*1, real_location, 1, false);");
			break;
	}
}

@ In fact, at present "here" predicates are never included in propositions to
be compiled, so this code is never used.

=
void RTSpatial::schema_here(up_family *self, int task, unary_predicate *up,
	annotated_i6_schema *asch, kind *K) {
	switch(task) {
		case TEST_ATOM_TASK:
			Calculus::Schemas::modify(asch->schema, "LocationOf(*1) == location");
			break;
		case NOW_ATOM_TRUE_TASK:
		case NOW_ATOM_FALSE_TASK:
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(BelievedImpossible),
				"being 'here' is not something which can be changed during play",
				"so it cannot be brought about or cancelled out with 'now'.");
			asch->schema = NULL; break;
	}
}
