[TheScore::] The Score.

A plugin to support the score variables.

@ At one time, all interactive fiction had a scoring system, because that's
what computers did for our entertainment: they rewarded us with points. Having
its distant roots in that period, Inform handles a numerical score with just
a little compiler support, and this is where.

=
void TheScore::start(void) {
	PluginManager::plug(PRODUCTION_LINE_PLUG, TheScore::production_line);
	PluginManager::plug(NEW_VARIABLE_NOTIFY_PLUG, TheScore::new_variable_notify);
}

int TheScore::production_line(int stage, int debugging, stopwatch_timer *sequence_timer) {
	if (stage == MODEL_CSEQ) {
		BENCH(TheScore::max_score_and_ranking_table);
	}
	return FALSE;
}

@ For many years "maximum score" was compiled to a constant, but then people sent
in bug reports asking why it wouldn't change in play. "Score", of course, is
more evidently variable.

= (early code)
nonlocal_variable *score_VAR = NULL;
nonlocal_variable *max_score_VAR = NULL;

@ =
<notable-scoring-variables> ::=
	score |
	maximum score

@ These are marked "initialisable" because of the way they are implemented at
run-time, using special variables in //WorldModelKit// rather than being
storage allocated by I7. Variables stored that way would not ordinarily be
possible to give values to in I7 assertions; but these are.

=
int TheScore::new_variable_notify(nonlocal_variable *var) {
	if (<notable-scoring-variables>(var->name)) {
		switch(<<r>>) {
			case 0:
				score_VAR = var;
				RTVariables::make_initialisable(score_VAR);
				break;
			case 1:
				max_score_VAR = var;
				RTVariables::make_initialisable(max_score_VAR);
				break;
		}
	}
	return FALSE;
}

@ A special rule is that if a table is called "Rankings" and contains a column
of numbers followed by a column of text, then it is used by the run-time
scoring system. In retrospect, Inform really shouldn't support this at the
compiler level (not that it does much), but it does little harm.

=
<rankings-table-name> ::=
	rankings

@ Nothing will happen unless a table has both this magic name, and also the
right shape: two columns, number then text. If so, the maximum score is
initialised to the number in the final row of the table, which is assumed to
be the score corresponding to successful completion and the highest rank.

The test case |Cooking|, an example from the documentation, tests this.

=
table *the_ranking_table = NULL;

void TheScore::max_score_and_ranking_table(void) {
	table *t = NULL;
	LOOP_OVER(t, table)
		if ((<rankings-table-name>(t->table_name_text)) &&
			(Tables::get_no_columns(t) >= 2) &&
			(Kinds::eq(Tables::kind_of_ith_column(t, 0), K_number)) &&
			(Kinds::eq(Tables::kind_of_ith_column(t, 1), K_text)))
			the_ranking_table = t;
	if (the_ranking_table) {
		global_compilation_settings.ranking_table_given = TRUE;
		parse_node *PN = Tables::cells_in_ith_column(the_ranking_table, 0);
		while ((PN != NULL) && (PN->next != NULL)) PN = PN->next;
		if ((PN != NULL) && (max_score_VAR) &&
			(VariableSubjects::has_initial_value_set(max_score_VAR) == FALSE))
			Assertions::PropertyKnowledge::initialise_global_variable(
				max_score_VAR, Node::get_evaluation(PN));
	}
}

table *TheScore::ranking_table(void) {
	return the_ranking_table;
}
