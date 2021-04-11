[RTTheScore::] The Score.

@

=
void RTTheScore::support(table *ranking_table) {
	if (ranking_table) {
		inter_name *iname = Hierarchy::find(RANKING_TABLE_HL);
		Emit::named_iname_constant(iname, K_value, RTTables::identifier(ranking_table));
		Hierarchy::make_available(Emit::tree(), iname);
		global_compilation_settings.ranking_table_given = TRUE;
	} else {
		inter_name *iname = Hierarchy::find(RANKING_TABLE_HL);
		Emit::named_generic_constant(iname, LITERAL_IVAL, 0);
		Hierarchy::make_available(Emit::tree(), iname);
	}
	inter_name *iname = Hierarchy::find(INITIAL_MAX_SCORE_HL);
	Hierarchy::make_available(Emit::tree(), iname);
	if (VariableSubjects::has_initial_value_set(max_score_VAR)) {
		inter_ti v1 = 0, v2 = 0;
		RTVariables::seek_initial_value(iname, &v1, &v2, max_score_VAR);
		Emit::named_generic_constant(iname, v1, v2);
	} else {
		Emit::named_numeric_constant(iname, 0);
	}
}
