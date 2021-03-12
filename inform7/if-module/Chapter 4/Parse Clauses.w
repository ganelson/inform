[ParseClauses::] Parse Clauses.

Parsing the clauses part of an AP from source text.

@

=
action_pattern *ParseClauses::ap_seven(wording W) {
	LOGIF(ACTION_PATTERN_PARSING, "Level Seven on: %W\n", W);
	action_name_list *list =
		ActionNameLists::parse(W, ParseActionPatterns::current_tense(), NULL);
	LOGIF(ACTION_PATTERN_PARSING, "List for %W is:\n$L\n", W, list);
	if (ActionNameLists::length(list) == 0) return NULL;

	@<Reduce the list to the first viable entry at each word position@>;
	LOGIF(ACTION_PATTERN_PARSING, "Reduced to viability:\n$L\n", list);

	@<Reject the resulting list if two or more entries contain clauses@>;
	@<Reject the resulting list if, given the clauses, two actions are immiscible@>;

	action_pattern *ap = ActionPatterns::new(W);
	anl_item *first = ActionNameLists::first_item(list);
	if ((first) && ((first->action_listed) || (first->nap_listed))) ap->action_list = list;
	LOOP_THROUGH_ANL(entry, list)
		LOOP_THROUGH_ANL_CLAUSES(c, entry) {
			LOGIF(ACTION_PATTERN_PARSING, "Writing %d '%W'\n", c->clause_ID, c->clause_text);
			if (c->stv_to_match)
				APClauses::set_action_variable_spec(ap, c->stv_to_match, c->evaluation);
			else
				APClauses::set_spec(ap, c->clause_ID, c->evaluation);
		}
	return ap;
}

@ A typical action list might look like the following, which came from the text
"looking or taking inventory in the presence of Hans in the Laboratory". There
are six different options at word position 2 (i.e., the "taking" part) but only
one at position 0 ("looking").
= (text)
(1). +2 taking [noun: inventory] [in: the laboratory] [in-presence: hans]
(2). +2 taking [noun: inventory] [in-presence: hans in the laboratory]
(3). +2 taking [noun: inventory in the presence of hans] [in: the laboratory]
(4). +2 taking [noun: inventory in the presence of hans in the laboratory]
(5). +2 taking inventory [in: the laboratory] [in-presence: hans]
(6). +2 taking inventory [in-presence: hans in the laboratory]
(7). +0 looking
=
Note that it is ordered in such a way that the number of words inside the
clauses increases as we go along, within each action: for (1) to (4), the
"taking" options, this number is successively 4, 5, 8, 9.

We now need to reduce this to a list of just two entries:
= (text)
(1). +2 taking inventory [in: the laboratory] [in-presence: hans]
(2). +0 looking
=
An entry is "viable" if we can make sense of the text in all of its clauses.
As soon as we find a viable entry at a given word position, we ignore all
subsequent possibilities at that position -- so the ordering of the ANL is
crucial: options near the top of the list are preferred to those lower down.

@<Reduce the list to the first viable entry at each word position@> =
	anl_entry *viable = NULL; int at = -1;
	LOOP_THROUGH_ANL(entry, list) {
		if (entry->parsing_data.word_position != at) {
			if ((at >= 0) && (viable == NULL)) return NULL;
			at = entry->parsing_data.word_position;
			viable = NULL;
		} else {
			if (viable) {
				ActionNameLists::mark_for_deletion(entry);
				continue;
			}
		}
		action_name *an = ActionNameLists::action(entry);
		int fail = FALSE, entry_options = 0;
		@<Parse the clauses@>;		
		if (fail) { ActionNameLists::mark_for_deletion(entry); continue; }
		@<Deal with any entry options@>;
		if (fail) { ActionNameLists::mark_for_deletion(entry); continue; }
		@<Typecheck or otherwise validate the clauses@>;
		if (fail) { ActionNameLists::mark_for_deletion(entry); continue; }
		viable = entry;
	}
	if (viable == NULL) return NULL;
	ActionNameLists::remove_entries_marked_for_deletion(list);

@<Parse the clauses@> =
	int saved_pap = pap_failure_reason;
	LOOP_THROUGH_ANL_CLAUSES(c, entry) {
		if (Wordings::nonempty(c->clause_text)) {
			if ((c->clause_ID == NOUN_AP_CLAUSE) && (an) && (an == going_action) && (<going-action-irregular-operand>(c->clause_text))) {
				if (<<r>> == 0) { // nowhere
					entry_options |= 1;
				}
				if (<<r>> == 1) { // somewhere
					entry_options |= 2;
				}
			} else if ((c->clause_ID == SECOND_AP_CLAUSE) && (an) && (K_understanding) &&
				(Kinds::eq(ActionSemantics::kind_of_second(an), K_understanding)) &&
				(<understanding-action-irregular-operand>(c->clause_text))) {
				parse_node *val = ParsingPlugin::rvalue_from_grammar_verb(NULL);
				Node::set_text(val, c->clause_text);
				c->evaluation = val;
			} else if (<action-operand>(c->clause_text)) {
				if (<<r>>) c->evaluation = <<rp>>;
				else c->evaluation = Specifications::from_kind(K_thing);
			} else {
				fail = TRUE;
			}
			if ((K_understanding) && (Rvalues::is_CONSTANT_of_kind(c->evaluation, K_text)))
				Node::set_kind_of_value(c->evaluation, K_understanding);
		}
	}
	pap_failure_reason = saved_pap;

@<Deal with any entry options@> =
	if (entry_options != 0) {
		wording W = ActionNameLists::get_clause_wording(entry, NOUN_AP_CLAUSE);
		ActionNameLists::truncate_clause(entry, NOUN_AP_CLAUSE, 0);
		if (entry_options & 1) {
			if (ActionNameLists::has_clause(entry, GOING_TO_AP_CLAUSE)) fail = TRUE;
			else {
				ActionNameLists::set_clause_wording(entry, GOING_TO_AP_CLAUSE, W);
				anl_clause_text *c = ActionNameLists::get_clause(entry, GOING_TO_AP_CLAUSE);
				c->evaluation = Rvalues::new_nothing_object_constant();
			}
		}
		if (entry_options & 2) {
			if (ActionNameLists::has_clause(entry, GOING_TO_AP_CLAUSE)) fail = TRUE;
			else {
				ActionNameLists::set_clause_wording(entry, GOING_TO_AP_CLAUSE, W);
				anl_clause_text *c = ActionNameLists::get_clause(entry, GOING_TO_AP_CLAUSE);
				c->evaluation = Descriptions::from_kind(K_room, FALSE);
			}
		}
	}

@<Typecheck or otherwise validate the clauses@> =
	LOOP_THROUGH_ANL_CLAUSES(c, entry) {
		kind *check = NULL;
		switch (c->clause_ID) {
			case NOUN_AP_CLAUSE:
				check = K_object;
				if (an) check = ActionSemantics::kind_of_noun(an);
				break;
			case SECOND_AP_CLAUSE:
				check = K_object;
				if (an) check = ActionSemantics::kind_of_second(an);
				break;
			case IN_AP_CLAUSE:
				check = K_object;
				break;
			case IN_THE_PRESENCE_OF_AP_CLAUSE:
				check = K_object;
				break;
		}
		if (c->stv_to_match) {
			int rv = Going::validate(c->stv_to_match, c->evaluation);
			if (rv == FALSE) return NULL;
			if (rv == NOT_APPLICABLE) check = StackedVariables::get_kind(c->stv_to_match);
		}
		if (Node::is(c->evaluation, UNKNOWN_NT)) fail = TRUE;
		else if ((check) && (Dash::validate_parameter(c->evaluation, check) == FALSE))
			fail = TRUE;
	}

@<Reject the resulting list if two or more entries contain clauses@> =
	int N = 0;
	LOOP_THROUGH_ANL(entry, list)
		if (entry->parsing_data.anl_clauses)
			N++;
	if (N > 1) {
		pap_failure_reason = MIXEDNOUNS_PAPF;
		return NULL;
	}

@<Reject the resulting list if, given the clauses, two actions are immiscible@> =
	int immiscible = FALSE, no_oow = 0, no_iw = 0, no_of_pars = 0;

	kind *kinds_observed_in_list[2];
	kinds_observed_in_list[0] = NULL;
	kinds_observed_in_list[1] = NULL;
	LOOP_THROUGH_ANL(entry, list)
		if (ActionNameLists::nap(entry) == NULL) {
			int nouns_in_entry = ActionNameLists::noun_count(entry);
			if (nouns_in_entry > 0) {
				if (no_of_pars > 0) immiscible = TRUE;
				no_of_pars = nouns_in_entry;
			}
			action_name *this = ActionNameLists::action(entry);
			if (this) {
				if (ActionSemantics::is_out_of_world(this)) no_oow++; else no_iw++;

				if (nouns_in_entry >= 1) {
					kind *K = ActionSemantics::kind_of_noun(this);
					kind *A = kinds_observed_in_list[0];
					if ((A) && (K) && (Kinds::eq(A, K) == FALSE))
						immiscible = TRUE;
					kinds_observed_in_list[0] = K;
				}
				if (nouns_in_entry >= 2) {
					kind *K = ActionSemantics::kind_of_second(this);
					kind *A = kinds_observed_in_list[1];
					if ((A) && (K) && (Kinds::eq(A, K) == FALSE))
						immiscible = TRUE;
					kinds_observed_in_list[1] = K;
				}
			}
		}
	if ((no_oow > 0) && (no_iw > 0)) immiscible = TRUE;

	LOOP_THROUGH_ANL(entry, list) {
		action_name *an = ActionNameLists::action(entry);
		if (an) {
			if ((no_of_pars >= 1) && (ActionSemantics::can_have_noun(an) == FALSE))
				immiscible = TRUE;
			if ((no_of_pars >= 2) && (ActionSemantics::can_have_second(an) == FALSE))
				immiscible = TRUE;
		}
	}

	if (immiscible) {
		pap_failure_reason = IMMISCIBLE_PAPF;
		return NULL;
	}

@ The "operands" of an action pattern are the nouns to which it applies: for
example, in "Kevin taking or dropping something", the operand is "something".
We treat words like "something" specially to avoid them being read as
"some thing" and thus forcing the kind of the operand to be "thing".

=
<action-operand> ::=
	something/anything |       ==> { FALSE, - }
	something/anything else |  ==> { FALSE, - }
	<s-ap-parameter>           ==> { TRUE, RP[1] }

<understanding-action-irregular-operand> ::=
	something/anything |       ==> { TRUE, - }
	it                         ==> { FALSE, - }
