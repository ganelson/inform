[RTSpatial::] Here, Nowhere and Everywhere.

Almost a Beatles song, but really a set of schemas for compiling the meaning
of the unary predicates here, nowhere and everywhere.

@ Here. In fact, at present "here" predicates are never included in propositions to
be compiled, so this code is never used. But the following would be correct if we
ever change our minds about that.

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

@ Everywhere.

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

@ Nowhere.

=
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
			Calculus::Schemas::modify(asch->schema,
				"MoveObject(*1, real_location, 1, false);");
			break;
	}
}
