[RTTheScore::] The Score.

@

=
void RTTheScore::support(void) {
	table *the_ranking_table = TheScore::ranking_table();
	if (the_ranking_table) {
		inter_name *iname = Hierarchy::find(RANKING_TABLE_HL);
		Emit::iname_constant(iname, K_value, RTTables::identifier(the_ranking_table));
		Hierarchy::make_available(iname);
	} else {
		inter_name *iname = Hierarchy::find(RANKING_TABLE_HL);
		Emit::unchecked_numeric_constant(iname, 0);
		Hierarchy::make_available(iname);
	}
	inter_name *iname = Hierarchy::find(INITIAL_MAX_SCORE_HL);
	Hierarchy::make_available(iname);
	if (VariableSubjects::has_initial_value_set(max_score_VAR)) {
		Emit::initial_value_as_constant(iname, max_score_VAR);
	} else {
		Emit::numeric_constant(iname, 0);
	}
}
