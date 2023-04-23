[ParseClauses::] Parse Clauses.

Parsing the clauses part of an AP from source text.

@ For nearly two decades the function below (and its allied code in
//Action Name Lists//) was the most troublesome, and hardest to understand,
code in the whole compiler, a simply awful place reminding me somehow of
Douglas Adams's Frogstar.[1] The AP parser was almost as cranky as the
type-checker, but that at least had the excuse of performing a complicated
function. Periodic improvements clarified only that the action pattern parser
was difficult to predict, and still did odd things in edge cases.

A therapeutic rewrite was finally made in March 2021; the algorithm works
entirely differently but appears to match a superset of cases that the old one
did, and is much easier to specify.

[1] Information about package holidays on the Frogstar can be found in the leaflet
"Sun, Sand, and Suffering on the Most Totally Evil Place in the Galaxy".

=
action_pattern *ParseClauses::ap_seven(wording W) {
	LOGIF(ACTION_PATTERN_PARSING, "Level Seven on: %W\n", W);
	action_name_list *list =
		ActionNameLists::parse(W, ParseActionPatterns::current_tense(), NULL);
	LOGIF(ACTION_PATTERN_PARSING, "Action name list for %W is:\n$L", W, list);
	if (ActionNameLists::length(list) == 0) return NULL;

	@<Reduce the list to the first viable entry at each word position@>;
	LOGIF(ACTION_PATTERN_PARSING, "Reduced to viability:\n$L", list);

	@<Reject the resulting list if two or more entries contain clauses@>;
	@<Reject the resulting list if, given the clauses, two actions are immiscible@>;

	@<Produce and return an action pattern from what survives of the list@>;
}

@ A typical action list might look like the following, which came from the text
"looking or taking inventory in the presence of Hans in the Laboratory". There
are six different options at word position 2 (i.e., the "taking" part) but only
one at position 0 ("looking").
= (text)
(1). +2 taking inventory [in: the laboratory] [in-presence: hans]
(2). +2 taking inventory [in-presence: hans in the laboratory]
(3). +2 taking [noun: inventory] [in: the laboratory] [in-presence: hans]
(4). +2 taking [noun: inventory] [in-presence: hans in the laboratory]
(5). +2 taking [noun: inventory in the presence of hans] [in: the laboratory]
(6). +2 taking [noun: inventory in the presence of hans in the laboratory]
(7). +0 looking
=
Note that it is ordered in such a way that actions with more fixed wording
occur before actions with fewer (at the same word position); and also that
the number of words inside the clauses increases as we go through possibilities
for each action. For (3) to (7), the "taking" options, the clause wording
runs to successively 4, 5, 8 and 9 words.

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
		if (ActionNameLists::word_position(entry) != at) {
			if ((at >= 0) && (viable == NULL)) return NULL;
			at = ActionNameLists::word_position(entry);
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
		PluginCalls::act_on_ANL_entry_options(entry, entry_options, &fail);
		if (fail) { ActionNameLists::mark_for_deletion(entry); continue; }
		@<Typecheck or otherwise validate the clauses@>;
		if (fail) { ActionNameLists::mark_for_deletion(entry); continue; }
		viable = entry;
	}
	if (viable == NULL) return NULL;
	ActionNameLists::remove_entries_marked_for_deletion(list);

@ Now each clause's text must be evaluated: for example, on the clause
|[in-presence: hans]| we will have to evaluate "Hans".

Note the special case for actions whose second noun has the kind |K_understanding|,
meaning that they hold topics of conversation ("ask Hans about cosmic rays").
There is ordinarily no way in Inform to write a literal of this kind, but here
we are allowed to write a text literal instead, and it is automatically converted.

@<Parse the clauses@> =
	int saved_pap = pap_failure_reason;
	LOOP_THROUGH_ANL_CLAUSES(c, entry) {
		if (fail) break;
		LOG_INDENT;
		if (Log::aspect_switched_on(ACTION_PATTERN_PARSING_DA)) {
			LOG("parsing "); ActionNameLists::log_clause(c); LOG(" - ");
		}
		if (Wordings::nonempty(c->clause_text)) {
			int opts = 0; PluginCalls::parse_AP_clause(an, c, &opts);
			if (opts != 0) {
				entry_options |= opts;
			} else if ((c->clause_ID == SECOND_AP_CLAUSE) && (an) && (K_understanding) &&
				(Kinds::eq(ActionSemantics::kind_of_second(an), K_understanding)) &&
				(<understanding-action-irregular-operand>(c->clause_text))) {
				parse_node *val = ParsingPlugin::rvalue_from_command_grammar(NULL);
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
		if (Log::aspect_switched_on(ACTION_PATTERN_PARSING_DA)) {
			if (fail) LOG("fail\n");
			else LOG("$P\n", c->evaluation);
		}
		LOG_OUTDENT;
	}
	pap_failure_reason = saved_pap;

@ The "operands" of an action pattern are the nouns to which it applies: for
example, in "Kevin taking or dropping something", the operand is "something".

=
<action-operand> ::=
	something/anything |       ==> { FALSE, - }
	something/anything else |  ==> { FALSE, - }
	<s-ap-parameter>           ==> { TRUE, RP[1] }

<understanding-action-irregular-operand> ::=
	something/anything |       ==> { TRUE, - }
	it                         ==> { FALSE, - }

@ Supposing that we managed to find values for each clause, we might still
have impossible ones: "putting 101 on false", say, where the noun seems to
be the number 101 and the second noun the truth state "false". So we need
to typecheck each clause.

@<Typecheck or otherwise validate the clauses@> =
	LOOP_THROUGH_ANL_CLAUSES(c, entry) {
		if (fail) break;
		LOG_INDENT;
		if (Log::aspect_switched_on(ACTION_PATTERN_PARSING_DA)) {
			LOG("validating "); ActionNameLists::log_clause(c); LOG(" - ");
		}
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
			int rv = FALSE;
			if (PluginCalls::validate_AP_clause(an, c, &rv)) {
				if (Log::aspect_switched_on(ACTION_PATTERN_PARSING_DA))
					LOG("referred to feature - ");
				if (rv == FALSE) {
					if (Log::aspect_switched_on(ACTION_PATTERN_PARSING_DA)) {
						LOG("failed badly with problem\n");
					}
					LOG_OUTDENT;
					return NULL;
				}
			} else {
				check = SharedVariables::get_kind(c->stv_to_match);
			}
		}
		if (Node::is(c->evaluation, UNKNOWN_NT)) fail = TRUE;
		else {
			if (Log::aspect_switched_on(ACTION_PATTERN_PARSING_DA))
				LOG("using Dash with kind %u - ", check);
			if ((check) && (Dash::validate_parameter(c->evaluation, check) == FALSE))
				fail = TRUE;
		}
		if (Log::aspect_switched_on(ACTION_PATTERN_PARSING_DA)) {
			if (fail) LOG("fail\n"); else LOG("pass\n");
		}
		LOG_OUTDENT;
	}

@ This is where heterogeneous patterns like "dropping a thing or taking a
container" are thrown out: only the last-placed action is allowed to have
clauses.

@<Reject the resulting list if two or more entries contain clauses@> =
	int N = 0;
	LOOP_THROUGH_ANL(entry, list)
		if (entry->parsing_data.anl_clauses)
			N++;
	if (N > 1) {
		pap_failure_reason = MIXEDNOUNS_PAPF;
		LOGIF(ACTION_PATTERN_PARSING, "Rejecting with mixed nouns\n");
		return NULL;
	}

@ And this is where impossible mixtures of actions are thrown out: for
example, if there is an action "setting" whose noun is a number, then
"taking or setting 50" will be thrown out because the two actions here
disagree about the meaning of the noun.

Similarly, "looking or taking a vehicle" is thrown out because looking has
no noun.

This is done in the interests of having a type-safe way to compile the
pattern check, but really it also avoids allowing action patterns which
look like syllepses.

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
		LOGIF(ACTION_PATTERN_PARSING, "Rejecting with immiscible actions\n");
		return NULL;
	}

@ Fanfares and trumpets voluntary:

@<Produce and return an action pattern from what survives of the list@> =
	action_pattern *ap = ActionPatterns::new(W);
	anl_item *first = ActionNameLists::first_item(list);
	if ((first) && ((first->action_listed) || (first->nap_listed))) ap->action_list = list;
	LOOP_THROUGH_ANL(entry, list)
		LOOP_THROUGH_ANL_CLAUSES(c, entry) {
			LOGIF(ACTION_PATTERN_PARSING,
				"Succeeds with clause %d = '%W'\n", c->clause_ID, c->clause_text);
			if (c->stv_to_match)
				APClauses::set_action_variable_spec(ap, c->stv_to_match, c->evaluation);
			else
				APClauses::set_spec(ap, c->clause_ID, c->evaluation);
		}
	return ap;

@h Internal test.
This is an all-singing, all-dancing way to test Level 7 and, along with it, the
action name list parser. In effect, there's a cutesy mini-language for what you
can express in the test wording.

=
void ParseClauses::perform_pattern_internal_test(OUTPUT_STREAM,
	struct internal_test_case *itc) {
	int saved = ParseActionPatterns::enter_mode(PERMIT_TRYING_OMISSION);
	<perform-ap-test>(itc->text_supplying_the_case);
	ParseActionPatterns::restore_mode(saved);
}

@ The mini-language is interpreted: to parse it is to run it. Notably, it also
enables named action patterns to be created, so that we can then parse them
back again:

=
<perform-ap-test> ::=
	list {...} |                  ==> { -, - }; ActionNameLists::test_list(WR[1]);
	<test-ap> |                   ==> @<Write textual AP test result@>
	<test-ap> ~~ <test-ap> |      ==> @<Write comparison AP test result@>
	...                           ==> @<Write failure@>

<test-ap> ::=
	<test-ap> is {...} |          ==> @<Make a named action pattern@>
	<test-register> = <test-ap> | ==> { -, ParseClauses::set_reg(R[1], RP[2]) }
	<action-pattern> |            ==> { pass 1 }
	<test-register> |             ==> { -, ParseClauses::read_reg(R[1]) }
	experimental {...}            ==> { -, ParseClauses::ap_seven(WR[1]) }

<test-register> ::=
	r1 | r2 | r3 | r4 | r5

@<Write textual AP test result@> =
	LOG("%W: $A\n", W, RP[1]);

@<Write comparison AP test result@> =
	int rv = ActionPatterns::compare_specificity(RP[1], RP[2]);
	int rv_converse = ActionPatterns::compare_specificity(RP[2], RP[1]);
	LOG("%W: ", W);
	if (rv > 0) LOG("left is more specific\n");
	if (rv < 0) LOG("right is more specific\n");
	if (rv == 0) LOG("equally specific\n");
	if (rv_converse != -1*rv) LOG("*** Not antisymmetric ***\n");

@<Write failure@> =
	LOG("%W: failed to parse\n", W);

@<Make a named action pattern@> =
	wording W = GET_RW(<test-ap>, 1);
	named_action_pattern *nap = NamedActionPatterns::add(RP[1], W);
	action_pattern *new_ap = ActionPatterns::new(W);
	anl_entry *entry = ActionNameLists::new_entry_at(W);
	entry->item.nap_listed = nap;
	new_ap->action_list = ActionNameLists::new_list(entry, ANL_POSITIVE);
	==> { -, new_ap };

@ This mini-language has a set of 5 "registers", which are really variables,
for stashing test results for use in subsequent tests:

=
int ap_test_register_initialised = FALSE;
action_pattern *ap_test_register[5];

action_pattern *ParseClauses::read_reg(int r) {
	if ((r < 0) || (r >= 5)) internal_error("bad AP register");
	if (ap_test_register_initialised == FALSE) {
		ap_test_register_initialised = TRUE;
		for (int i=0; i<5; i++) ap_test_register[i] = NULL;
	}
	return ap_test_register[r];
}

action_pattern *ParseClauses::set_reg(int r, action_pattern *ap) {
	ParseClauses::read_reg(r);
	ap_test_register[r] = ap;
	return ParseClauses::read_reg(r);
}
