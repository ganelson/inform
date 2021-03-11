[ParseClauses::] Parse Clauses.

Parsing the clauses part of an AP from source text.

@ We can't put it off any longer. Here goes.

=
action_pattern *ParseClauses::parse(wording W) {
	int failure_this_call = pap_failure_reason;
	int i, j, k = 0;
	action_name_list *list = NULL;
	int tense = ParseActionPatterns::current_tense();

	action_pattern ap = ActionPatterns::temporary(W);
	int ap_valid = FALSE;

	@<PAR - (f) Parse Special Going Clauses@>;
	@<PAR - (i) Parse Initial Action Name List@>;
	@<PAR - (j) Parse Parameters@>;
	@<PAR - (k) Verify Mixed Action@>;
	@<With one small proviso, a valid action pattern has been parsed@>;
	return ActionPatterns::perpetuate(ap);

	Failed: ;
	@<No valid action pattern has been parsed@>;
	return NULL;
}

@<With one small proviso, a valid action pattern has been parsed@> =
	pap_failure_reason = 0;
	ap.text_of_pattern = W;
	ap.action_list = list;
	anl_item *item = ActionNameLists::first_item(ap.action_list);
	if ((item) && (item->nap_listed == NULL) && (item->action_listed == NULL))
		ap.action_list = NULL;
	ap_valid = TRUE;

	ParseClauses::nullify_nonspecific(&ap, ACTOR_AP_CLAUSE);
	ParseClauses::nullify_nonspecific(&ap, NOUN_AP_CLAUSE);
	ParseClauses::nullify_nonspecific(&ap, SECOND_AP_CLAUSE);
	ParseClauses::nullify_nonspecific(&ap, IN_AP_CLAUSE);

//	if (Going::check(&ap) == FALSE) ap_valid = FALSE;

	if (ap_valid == FALSE) goto Failed;
	LOGIF(ACTION_PATTERN_PARSING, "Matched action pattern: $A\n", &ap);

@<No valid action pattern has been parsed@> =
	pap_failure_reason = failure_this_call;
	ap_valid = FALSE;
	ap.ap_clauses = NULL;
	LOGIF(ACTION_PATTERN_PARSING, "Parse action failed: %W\n", W);

@ Special clauses are allowed after "going..."; trim them
away as they are recorded.

@<PAR - (f) Parse Special Going Clauses@> =
	action_name_list *preliminary_anl = ActionNameLists::parse(W, tense, NULL);
	action_name *chief_an = ActionNameLists::get_best_action(preliminary_anl);
	if (chief_an == NULL) {
		int x;
		chief_an = ActionNameNames::longest_nounless(W, tense, &x);
	}
	if (chief_an) {
		stacked_variable *last_stv_specified = NULL;
		i = Wordings::first_wn(W) + 1; j = -1;
		LOGIF(ACTION_PATTERN_PARSING, "Trying special clauses at <%W>\n", Wordings::new(i, Wordings::last_wn(W)));
		while (i < Wordings::last_wn(W)) {
			stacked_variable *stv = NULL;
			if (Word::unexpectedly_upper_case(i) == FALSE)
				stv = ActionVariables::parse_match_clause(chief_an, Wordings::new(i, Wordings::last_wn(W)));
			if (stv != NULL) {
				LOGIF(ACTION_PATTERN_PARSING,
					"Special clauses found on <%W>\n", Wordings::from(W, i));
				if (last_stv_specified == NULL) j = i-1;
				else {
					parse_node *spec = ParseClauses::parse_variable_spec(Wordings::new(k, i-1), last_stv_specified);
					APClauses::set_action_variable_spec(&ap, last_stv_specified, spec);
				}
				k = i+1;
				last_stv_specified = stv;
			}
			i++;
		}
		if (last_stv_specified != NULL) {
			parse_node *spec = ParseClauses::parse_variable_spec(Wordings::new(k, Wordings::last_wn(W)), last_stv_specified);
			APClauses::set_action_variable_spec(&ap, last_stv_specified, spec);
		}
		if (j >= 0) W = Wordings::up_to(W, j);
	}

@ Extract the information as to which actions are intended:
e.g., from "taking or dropping something", that it will be
taking or dropping.

@<PAR - (i) Parse Initial Action Name List@> =
	action_name_list *try_list = ActionNameLists::parse(W, tense, NULL);
	if (try_list == NULL) goto Failed;
	list = try_list;
	LOGIF(ACTION_PATTERN_PARSING, "ANL from PAR(i):\n$L\n", list);

@ Now to fill in the gaps. At this point we have the action name
list as a linked list of all possible lexical matches, but want to
whittle it down to remove those which do not semantically make
sense. For instance, "taking inventory" has two possible lexical
matches: "taking inventory" with 0 parameters, or "taking" with
1 parameter "inventory", and we cannot judge without parsing
the expression "inventory". The list passes muster if at least
one match succeeds at the first word position represented in the
list, which is to say the last one lexically, since the list is
reverse-ordered. (This is so that "taking or dropping something"
requires only "dropping" to have its objects specified; "taking",
of course, does not.) We delete all entries in the list at this
crucial word position except for the one matched.

@d MAX_AP_POSITIONS 100
@d UNTHINKABLE_POSITION -1

@<PAR - (j) Parse Parameters@> =
	int no_positions = 0;
	int position_at[MAX_AP_POSITIONS], position_min_parc[MAX_AP_POSITIONS];
	@<Find the positions of individual action names, and their minimum parameter counts@>;
	@<Report to the debugging log on the action decomposition@>;
	@<Find how many different positions have each possible minimum count@>;

	int first_position = ActionNameLists::first_position(list);
	int one_was_valid = FALSE;
	action_pattern trial_ap;
	int trial_ap_valid = FALSE;
	LOOP_THROUGH_ANL(entry, list) {
		LOGIF(ACTION_PATTERN_PARSING, "Entry (%d):\n$8\n", ActionNameLists::parc(entry), entry);
		@<Fill out the noun, second, room and nowhere fields of the AP as if this action were right@>;
		@<Check the validity of this speculative AP@>;
		if ((trial_ap_valid) && (one_was_valid == FALSE) && (ActionNameLists::word_position(entry) == first_position)) {
			one_was_valid = TRUE;
			APClauses::set_spec(&ap, NOUN_AP_CLAUSE, APClauses::spec(&trial_ap, NOUN_AP_CLAUSE));
			APClauses::set_spec(&ap, SECOND_AP_CLAUSE, APClauses::spec(&trial_ap, SECOND_AP_CLAUSE));
			APClauses::set_spec(&ap, IN_AP_CLAUSE, APClauses::spec(&trial_ap, IN_AP_CLAUSE));
			if (Going::going_nowhere(&trial_ap)) Going::go_nowhere(&ap);
			if (Going::going_somewhere(&trial_ap)) Going::go_somewhere(&ap);
			ap_valid = TRUE;
		}
		if (trial_ap_valid == FALSE) ActionNameLists::mark_for_deletion(entry);
	}
	if (one_was_valid == FALSE) goto Failed;

	@<Adjudicate between topic and other actions@>;
	LOGIF(ACTION_PATTERN_PARSING, "List before action winnowing:\n$L\n", list);
	@<Delete those action names which are to be deleted@>;
	LOGIF(ACTION_PATTERN_PARSING, "List after action winnowing:\n$L\n", list);

@ For example, "taking inventory or waiting" produces two positions, words
0 and 3, and minimum parameter count 0 in each case. ("Taking inventory"
can be read as "taking (inventory)", par-count 1, or "taking inventory",
par-count 0, so the minimum is 0.)

@<Find the positions of individual action names, and their minimum parameter counts@> =
	LOOP_THROUGH_ANL(entry, list) {
		int pos = -1;
		@<Find the position word of this particular action name@>;
		if ((position_min_parc[pos] == UNTHINKABLE_POSITION) ||
			(ActionNameLists::parc(entry) < position_min_parc[pos]))
			position_min_parc[pos] = ActionNameLists::parc(entry);
	}

@<Find the position word of this particular action name@> =
	int i;
	for (i=0; i<no_positions; i++)
		if (ActionNameLists::word_position(entry) == position_at[i])
			pos = i;
	if (pos == -1) {
		if (no_positions == MAX_AP_POSITIONS) goto Failed;
		position_at[no_positions] = ActionNameLists::word_position(entry);
		position_min_parc[no_positions] = UNTHINKABLE_POSITION;
		pos = no_positions++;
	}

@<Report to the debugging log on the action decomposition@> =
	LOGIF(ACTION_PATTERN_PARSING, "List after action decomposition:\n$L\n", list);
	for (i=0; i<no_positions; i++) {
		int min = position_min_parc[i];
		LOGIF(ACTION_PATTERN_PARSING, "ANL position %d (word %d): min parc %d\n",
			i, position_at[i], min);
	}

@ The following test is done to reject patterns like "taking ball or dropping
bat", which have a positive minimum parameter count in more than one position;
which means there couldn't be an action pattern which shared the same noun
description.

@<Find how many different positions have each possible minimum count@> =
	int positions_with_min_parc[3];
	for (i=0; i<3; i++) positions_with_min_parc[i] = 0;
	for (i=0; i<no_positions; i++) {
		int min = position_min_parc[i];
		if ((min >= 0) && (min < 3)) positions_with_min_parc[min]++;
	}

	if ((positions_with_min_parc[1] > 1) ||
		(positions_with_min_parc[2] > 1)) {
		failure_this_call = MIXEDNOUNS_PAPF; goto Failed;
	}

@<Fill out the noun, second, room and nowhere fields of the AP as if this action were right@> =
	trial_ap.ap_clauses = NULL;
	if (Wordings::nonempty(ActionNameLists::par(entry, 0))) {
		if (Going::irregular_noun_phrase(ActionNameLists::action(entry), &trial_ap, ActionNameLists::par(entry, 0)) == FALSE)
			ParseClauses::add_clause(&trial_ap, NOUN_AP_CLAUSE, ActionNameLists::par(entry, 0));
	}

	if (Wordings::nonempty(ActionNameLists::par(entry, 1))) {
		if ((ActionNameLists::action(entry) != NULL)
			&& (K_understanding)
			&& (Kinds::eq(ActionSemantics::kind_of_second(ActionNameLists::action(entry)), K_understanding))
			&& (<understanding-action-irregular-operand>(ActionNameLists::par(entry, 1)))) {
			parse_node *val = ParsingPlugin::rvalue_from_grammar_verb(NULL); /* Why no GV here? */
			Node::set_text(val, ActionNameLists::par(entry, 1));
			APClauses::set_spec(&trial_ap, SECOND_AP_CLAUSE, val);
		} else {
			ParseClauses::add_clause(&trial_ap, SECOND_AP_CLAUSE, ActionNameLists::par(entry, 1));
		}
	}

	if (Wordings::nonempty(ActionNameLists::in_clause(entry)))
		ParseClauses::add_clause(&trial_ap, IN_AP_CLAUSE,
			ActionNameLists::in_clause(entry));

@<Check the validity of this speculative AP@> =
	kind *check_n = K_object;
	kind *check_s = K_object;
	if (ActionNameLists::action(entry) != NULL) {
		check_n = ActionSemantics::kind_of_noun(ActionNameLists::action(entry));
		check_s = ActionSemantics::kind_of_second(ActionNameLists::action(entry));
	}
	trial_ap_valid = TRUE;
	if (APClauses::validate(APClauses::clause(&trial_ap, NOUN_AP_CLAUSE), check_n) == FALSE)
		trial_ap_valid = FALSE;
	if (APClauses::validate(APClauses::clause(&trial_ap, SECOND_AP_CLAUSE), check_s) == FALSE)
		trial_ap_valid = FALSE;
	if (APClauses::validate(APClauses::clause(&trial_ap, IN_AP_CLAUSE), K_object) == FALSE)
		trial_ap_valid = FALSE;

@<Adjudicate between topic and other actions@> =
	kind *K[2];
	K[0] = NULL; K[1] = NULL;
	LOOP_THROUGH_ANL_WITH_PREV(entry, prev, next, list) {
		if ((ActionNameLists::marked_for_deletion(entry) == FALSE) && (ActionNameLists::action(entry))) {
			if (ActionNameLists::same_word_position(prev, entry) == FALSE) {
				if (ActionNameLists::same_word_position(entry, next) == FALSE) {
					if ((K[0] == NULL) && (ActionSemantics::can_have_noun(ActionNameLists::action(entry))))
						K[0] = ActionSemantics::kind_of_noun(ActionNameLists::action(entry));
					if ((K[1] == NULL) && (ActionSemantics::can_have_second(ActionNameLists::action(entry))))
						K[1] = ActionSemantics::kind_of_second(ActionNameLists::action(entry));
				}
			}
		}
	}
	LOGIF(ACTION_PATTERN_PARSING, "Necessary kinds: %u, %u\n", K[0], K[1]);
	LOOP_THROUGH_ANL_WITH_PREV(entry, prev, next, list) {
		if ((ActionNameLists::marked_for_deletion(entry) == FALSE) && (ActionNameLists::action(entry))) {
			int poor_choice = FALSE;
			if ((K[0]) && (ActionSemantics::can_have_noun(ActionNameLists::action(entry)))) {
				kind *L = ActionSemantics::kind_of_noun(ActionNameLists::action(entry));
				if (Kinds::compatible(L, K[0]) == FALSE) poor_choice = TRUE;
			}
			if ((K[1]) && (ActionSemantics::can_have_second(ActionNameLists::action(entry)))) {
				kind *L = ActionSemantics::kind_of_second(ActionNameLists::action(entry));
				if (Kinds::compatible(L, K[1]) == FALSE) poor_choice = TRUE;
			}
			if (poor_choice) {
				if (((ActionNameLists::same_word_position(prev, entry)) &&
						(ActionNameLists::marked_for_deletion(prev) == FALSE))
					||
					((ActionNameLists::same_word_position(entry, next)) &&
						(ActionNameLists::marked_for_deletion(next) == FALSE)))
					ActionNameLists::mark_for_deletion(entry);
			}
		}
	}

@<Delete those action names which are to be deleted@> =
	ActionNameLists::remove_entries_marked_for_deletion(list);

@ Not all actions can cohabit. We require that as far as the user has
specified the parameters, the actions in the list must all agree (i) to be
allowed to have such a parameter, and (ii) to be allowed to have a
parameter of the same type. Thus "waiting or taking something" fails
(waiting takes 0 parameters, but we specified one), and so would "painting
or taking something" if painting had to be followed by a colour, say. Note
that the "doing anything" action is always allowed a parameter (this is
the case when the first action name in the list is |NULL|).

@<PAR - (k) Verify Mixed Action@> =
	int immiscible = FALSE, no_oow = 0, no_iw = 0, no_of_pars = 0;

	kind *kinds_observed_in_list[2];
	kinds_observed_in_list[0] = NULL;
	kinds_observed_in_list[1] = NULL;
	LOOP_THROUGH_ANL(entry, list)
		if (ActionNameLists::nap(entry) == NULL) {
			if (ActionNameLists::parc(entry) > 0) {
				if (no_of_pars > 0) immiscible = TRUE;
				no_of_pars = ActionNameLists::parc(entry);
			}
			action_name *this = ActionNameLists::action(entry);
			if (this) {
				if (ActionSemantics::is_out_of_world(this)) no_oow++; else no_iw++;

				if (ActionNameLists::parc(entry) >= 1) {
					kind *K = ActionSemantics::kind_of_noun(this);
					kind *A = kinds_observed_in_list[0];
					if ((A) && (K) && (Kinds::eq(A, K) == FALSE))
						immiscible = TRUE;
					kinds_observed_in_list[0] = K;
				}
				if (ActionNameLists::parc(entry) >= 2) {
					kind *K = ActionSemantics::kind_of_second(this);
					kind *A = kinds_observed_in_list[1];
					if ((A) && (K) && (Kinds::eq(A, K) == FALSE))
						immiscible = TRUE;
					kinds_observed_in_list[1] = K;
				}
			}
		}
	if ((no_oow > 0) && (no_iw > 0)) immiscible = TRUE;

	LOOP_THROUGH_ANL(entry, list)
		if (ActionNameLists::action(entry)) {
			if ((no_of_pars >= 1) && (ActionSemantics::can_have_noun(ActionNameLists::action(entry)) == FALSE))
				immiscible = TRUE;
			if ((no_of_pars >= 2) && (ActionSemantics::can_have_second(ActionNameLists::action(entry)) == FALSE))
				immiscible = TRUE;
		}

	if (immiscible) {
		failure_this_call = IMMISCIBLE_PAPF;
		goto Failed;
	}

@ And an anticlimactic little routine for putting objects
into action patterns in the noun or second noun position.

=
void ParseClauses::add_clause(action_pattern *ap, int C, wording W) {
	parse_node *spec = NULL;
	int any_flag = FALSE;
	if (<action-operand>(W)) {
		if (<<r>>) spec = <<rp>>;
		else { any_flag = TRUE; spec = Specifications::from_kind(K_thing); }
	}
	if (spec == NULL) spec = Specifications::new_UNKNOWN(W);
	if ((K_understanding) && (Rvalues::is_CONSTANT_of_kind(spec, K_text)))
		Node::set_kind_of_value(spec, K_understanding);
	Node::set_text(spec, W);
	LOGIF(ACTION_PATTERN_PARSING, "PAOIA (clause %d) %W = $P\n", C, W, spec);
	APClauses::set_spec(ap, C, spec);
	if (any_flag) APClauses::set_opt(APClauses::clause(ap, C), DO_NOT_VALIDATE_APCOPT);
	else APClauses::clear_opt(APClauses::clause(ap, C), DO_NOT_VALIDATE_APCOPT);
}

void ParseClauses::nullify_nonspecific(action_pattern *ap, int C) {
	ap_clause *apoc = APClauses::clause(ap, C);
	if ((apoc) && (Node::is(apoc->clause_spec, UNKNOWN_NT)))
		apoc->clause_spec = NULL;
}

parse_node *ParseClauses::parse_spec(wording W) {
	if (<s-ap-parameter>(W)) return <<rp>>;
	return Specifications::new_UNKNOWN(W);
}

parse_node *ParseClauses::parse_variable_spec(wording W, stacked_variable *stv) {
	parse_node *spec = ParseClauses::parse_spec(W);
	int rv = Going::validate(stv, spec);
	if (rv == FALSE) return NULL;
	if (rv == NOT_APPLICABLE) {
		if (Dash::validate_parameter(spec, StackedVariables::get_kind(stv)) == FALSE) {
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, W);
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_BadOptionalAPClause));
			Problems::issue_problem_segment(
				"In %1, I tried to read a description of an action - a complicated "
				"one involving optional clauses; but '%2' wasn't something I "
				"recognised.");
			Problems::issue_problem_end();
			spec = NULL;
		}
	}
	return spec;
}

@ The "operands" of an action pattern are the nouns to which it applies: for
example, in "Kevin taking or dropping something", the operand is "something".
We treat words like "something" specially to avoid them being read as
"some thing" and thus forcing the kind of the operand to be "thing".

=
<action-operand> ::=
	something/anything | 			==> { FALSE, - }
	something/anything else | 		==> { FALSE, - }
	<s-ap-parameter> 				==> { TRUE, RP[1] }

<understanding-action-irregular-operand> ::=
	something/anything |    ==> { TRUE, - }
	it								==> { FALSE, - }

@

=
void ParseClauses::list(wording W) {
	LOG("Action name list for: %W\n", W);
	experimental_anl_system = TRUE;
	action_name_list *anl = ActionNameLists::parse(W, IS_TENSE, NULL);
	experimental_anl_system = FALSE;
	LOG("$L\n", anl);
}

@

=
action_pattern *ParseClauses::experiment(wording W) {
	LOG("Experiment on: %W\n", W);
	experimental_anl_system = TRUE;
	action_name_list *anl = ActionNameLists::parse(W, IS_TENSE, NULL);
	experimental_anl_system = FALSE;
	LOG("$L\n", anl);
	action_name *chief_an = ActionNameLists::get_best_action(anl);
	if (chief_an == NULL) chief_an = ActionNameNames::longest_nounless(W, IS_TENSE, NULL);
	LOG("Chief action: $l\n", chief_an);

	action_pattern *ap = ParseClauses::parse(W);
	return ap;
}
