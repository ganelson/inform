[PL::Score::] The Score.

A plugin to support the maximum score variable.

@h Definitions.

@ For many years this was a defined I6 constant, but then people sent in bug
reports asking why it wouldn't change in play.

=
nonlocal_variable *max_score_VAR = NULL;

@h Initialisation.

=
void PL::Score::start(void) {
}

@h The maximum score and rankings table.
A special rule is that if a table is called "Rankings" and contains a column
of numbers followed by a column of text, then it is used by the run-time
scoring system. In retrospect, Inform really shouldn't support this at the
compiler level (not that it does much), and in any case it's a very old-school
idea of IF. Still, it does little harm.

=
<rankings-table-name> ::=
	rankings

@ This can only happen if we declare it somehow in I6 code, which
we do with the constant |RANKING_TABLE|. We also set the |MAX_SCORE| variable
equal to the number in the bottom row of the table, which is assumed to be the
score corresponding to successful completion and the highest rank.

=
void PL::Score::compile_max_score(void) {
	int rt_made = FALSE;
	table *t;
	LOOP_OVER(t, table) {
		if ((<rankings-table-name>(t->table_name_text)) &&
			(Tables::get_no_columns(t) >= 2) &&
			(Kinds::Compare::eq(Tables::kind_of_ith_column(t, 0), K_number)) &&
			(Kinds::Compare::eq(Tables::kind_of_ith_column(t, 1), K_text))) {
			inter_name *iname = Hierarchy::find(RANKING_TABLE_HL);
			Emit::named_iname_constant(iname, K_value, Tables::identifier(t));
			parse_node *PN = Tables::cells_in_ith_column(t, 0);
			while ((PN != NULL) && (PN->next != NULL)) PN = PN->next;
			if ((PN != NULL) && (max_score_VAR) &&
				(NonlocalVariables::has_initial_value_set(max_score_VAR) == FALSE))
				Assertions::PropertyKnowledge::initialise_global_variable(
					max_score_VAR, Node::get_evaluation(PN));
			Hierarchy::make_available(Emit::tree(), iname);
			global_compilation_settings.ranking_table_given = TRUE;
			rt_made = TRUE;
			break;
		}
	}
	if (rt_made == FALSE) {
		inter_name *iname = Hierarchy::find(RANKING_TABLE_HL);
		Emit::named_generic_constant(iname, LITERAL_IVAL, 0);
		Hierarchy::make_available(Emit::tree(), iname);
	}
	inter_name *iname = Hierarchy::find(INITIAL_MAX_SCORE_HL);
	Hierarchy::make_available(Emit::tree(), iname);
	if (NonlocalVariables::has_initial_value_set(max_score_VAR)) {
		inter_ti v1 = 0, v2 = 0;
		NonlocalVariables::seek_initial_value(iname, &v1, &v2, max_score_VAR);
		Emit::named_generic_constant(iname, v1, v2);
	} else {
		Emit::named_numeric_constant(iname, 0);
	}
}
