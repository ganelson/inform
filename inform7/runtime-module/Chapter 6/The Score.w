[RTTheScore::] The Score.

@

=
void RTTheScore::support(table *ranking_table) {
	if (ranking_table) {
		inter_name *iname = Hierarchy::find(RANKING_TABLE_HL);
		Emit::iname_constant(iname, K_value, RTTables::identifier(ranking_table));
		Hierarchy::make_available(Emit::tree(), iname);
		global_compilation_settings.ranking_table_given = TRUE;
	} else {
		inter_name *iname = Hierarchy::find(RANKING_TABLE_HL);
		Emit::unchecked_numeric_constant(iname, 0);
		Hierarchy::make_available(Emit::tree(), iname);
	}
	inter_name *iname = Hierarchy::find(INITIAL_MAX_SCORE_HL);
	Hierarchy::make_available(Emit::tree(), iname);
	if (VariableSubjects::has_initial_value_set(max_score_VAR)) {
		Emit::initial_value_as_constant(iname, max_score_VAR);
	} else {
		Emit::numeric_constant(iname, 0);
	}
}
