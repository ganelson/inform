[RuleFamily::] Rule Family.

Imperative definitions of rules.

@

=
imperative_defn_family *RULE_EFF_family = NULL; /* "Before taking a container, ..." */

typedef struct rule_family_data {
	struct wording constant_name;
	struct wording pattern;
	int not_in_rulebook;
	int event_time;
	struct wording event_name;
	CLASS_DEFINITION
} rule_family_data;

@

=
void RuleFamily::create_family(void) {
	RULE_EFF_family = ImperativeDefinitions::new_family(I"RULE_EFF");
	METHOD_ADD(RULE_EFF_family, CLAIM_IMP_DEFN_MTID, RuleFamily::claim);
	METHOD_ADD(RULE_EFF_family, NEW_PHRASE_IMP_DEFN_MTID, RuleFamily::new_phrase);
}

@ =
<rule-preamble> ::=
	this is the {... rule} |                                  ==> { 1, - }
	this is the rule |                                        ==> @<Issue PM_NamelessRule problem@>
	this is ... rule |                                        ==> @<Issue PM_UnarticledRule problem@>
	this is ... rules |                                       ==> @<Issue PM_PluralisedRule problem@>
	... ( this is the {... rule} ) |                          ==> { 2, - }
	... ( this is the rule ) |                                ==> @<Issue PM_NamelessRule problem@>
	... ( this is ... rule ) |                                ==> @<Issue PM_UnarticledRule problem@>
	... ( this is ... rules ) |                               ==> @<Issue PM_PluralisedRule problem@>
	...                                                       ==> { 3, - }

@<Issue PM_NamelessRule problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_NamelessRule),
		"there are many rules in Inform",
		"so you need to give a name: 'this is the abolish dancing rule', say, "
		"not just 'this is the rule'.");
	==> { FALSE, - }

@<Issue PM_UnarticledRule problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_UnarticledRule),
		"a rule must be given a definite name",
		"which begins with 'the', just to emphasise that it is the only one "
		"with this name: 'this is the promote dancing rule', say, not just "
		"'this is promote dancing rule'.");
	==> { FALSE, - }

@<Issue PM_PluralisedRule problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_PluralisedRule),
		"a rule must be given a definite name ending in 'rule' not 'rules'",
		"since the plural is only used for rulebooks, which can of course "
		"contain many rules at once.");
	==> { FALSE, - }

@ =
<event-rule-preamble> ::=
	at <clock-time> |         ==> { pass 1 }
	at the time when ... |    ==> { NO_FIXED_TIME, - }
	at the time that ... |    ==> @<Issue PM_AtTimeThat problem@>
	at ...					  ==> @<Issue PM_AtWithoutTime problem@>

@<Issue PM_AtTimeThat problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_AtTimeThat),
		"this seems to use 'that' where it should use 'when'",
		"assuming it's trying to apply a rule to an event. (The convention is "
		"that any rule beginning 'At' is a timed one. The time can either be a "
		"fixed time, as in 'At 11:10 AM: ...', or the time when some named "
		"event takes place, as in 'At the time when the clock chimes: ...'.)");

@<Issue PM_AtWithoutTime problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_AtWithoutTime),
		"'at' what time? No description of a time is given",
		"which means that this rule can never have effect. (The convention is "
		"that any rule beginning 'At' is a timed one. The time can either be a "
		"fixed time, as in 'At 11:10 AM: ...', or the time when some named "
		"event takes place, as in 'At the time when the clock chimes: ...'.)");

@

=
void RuleFamily::claim(imperative_defn_family *self, imperative_defn *id) {
	wording W = Node::get_text(id->at);
	if (<rule-preamble>(W)) {
		int form = <<r>>;
		id->family = RULE_EFF_family;
		rule_family_data *rfd = CREATE(rule_family_data);
		rfd->not_in_rulebook = FALSE;
		rfd->constant_name = EMPTY_WORDING;
		rfd->pattern = EMPTY_WORDING;
		rfd->event_time = NOT_A_TIMED_EVENT;
		rfd->event_name = EMPTY_WORDING;

		if (form == 1) rfd->not_in_rulebook = TRUE;
		id->family_specific_data = STORE_POINTER_rule_family_data(rfd);
		if (form == 1) {
			wording RW = GET_RW(<rule-preamble>, 1);
			if (Rules::vet_name(RW)) {
				rfd->constant_name = RW;
				Rules::obtain(RW, TRUE);
			}
		}
		if (form == 2) {
			wording RW = GET_RW(<rule-preamble>, 2);
			if (Rules::vet_name(RW)) {
				rfd->constant_name = RW;
				Rules::obtain(RW, TRUE);
			}
		}
		if ((form == 2) || (form == 3)) rfd->pattern = GET_RW(<rule-preamble>, 1);
		if (form == 3) {
			if (<event-rule-preamble>(W)) {
				rfd->pattern = EMPTY_WORDING;
				rfd->not_in_rulebook = TRUE;
				rfd->event_time = <<r>>;
				if (rfd->event_time == NO_FIXED_TIME)
					rfd->event_name = GET_RW(<event-rule-preamble>, 1);
			}
		}
	}
}

@ =
int RuleFamily::is(imperative_defn *id) {
	if (id->family == RULE_EFF_family) return TRUE;
	return FALSE;
}

int RuleFamily::not_in_rulebook(imperative_defn *id) {
	if (RuleFamily::is(id)) {
		rule_family_data *rfd = RETRIEVE_POINTER_rule_family_data(id->family_specific_data);
		return rfd->not_in_rulebook;
	}
	return FALSE;
}

void RuleFamily::phud(imperative_defn *id, ph_usage_data *phud) {
	rule_family_data *rfd = RETRIEVE_POINTER_rule_family_data(id->family_specific_data);
	phud->timing_of_event = rfd->event_time;
	phud->event_name = rfd->event_name;
	phud->explicit_name = rfd->constant_name;
	if (rfd->not_in_rulebook == FALSE)
		@<Parse the rulebook stem in fine mode@>;

}

@ Much later on, Inform returns to the definition to look at it in fine detail:

=
<rule-preamble-fine> ::=
	<rule-preamble-finer> during <s-scene-description> |  ==> { R[1], RP[2] }
	<rule-preamble-finer>                                 ==> { R[1], NULL }

<rule-preamble-finer> ::=
	{<rulebook-stem-embellished>} {when/while ...} |      ==> { TRUE, - }
	{<rulebook-stem-embellished>} |                       ==> { FALSE, - }
	...													  ==> { NOT_APPLICABLE, - }

<rulebook-stem-embellished> ::=
	<rulebook-stem> *** |
	<article> rule for <rulebook-stem> *** |
	<article> rule <rulebook-stem> *** |
	rule for <rulebook-stem> *** |
	rule <rulebook-stem> ***

<rulebook-bud> ::=
	of/for ... |                                          ==> { TRUE, - }
	rule about/for/on ... |                               ==> { TRUE, - }
	rule                                                  ==> { FALSE, - }

@ That's it for coarse mode. The rest is what happens in fine mode, which
affects rules giving a rulebook and some circumstances:

>> Instead of taking a container: ...

Here "Instead of" is the stem and "taking a container" the bud.

@<Parse the rulebook stem in fine mode@> =
	wording W = rfd->pattern;
	<rule-preamble-fine>(W);
	parse_node *during_spec = <<rp>>;
	int form = <<r>>;
	rulebook_match *parsed_rm = Rulebooks::match();
	W = GET_RW(<rule-preamble-finer>, 1);
	if (form == NOT_APPLICABLE) {
		<unrecognised-rule-stem-diagnosis>(W);
	} else {
		if (form) phud->whenwhile = GET_RW(<rule-preamble-finer>, 2);
		#ifdef IF_MODULE
		phud->during_scene_spec = during_spec;
		#endif
		phud->owning_rulebook = parsed_rm->matched_rulebook;
		if (phud->owning_rulebook == NULL) internal_error("rulebook stem misparsed");
		phud->owning_rulebook_placement = parsed_rm->placement_requested;
		@<Disallow the definite article for anonymous rules@>;
		@<Cut off the bud from the stem@>;
	}
	phud->rule_preamble = W;

@ The bud is not always present at all, and need not always be at the end
of the stem, so we have to be very careful:

@<Cut off the bud from the stem@> =
	wording BUD = GET_RW(<rulebook-stem-embellished>, 1);
	int b1 = Wordings::first_wn(BUD), b2 = Wordings::last_wn(BUD);
	if ((b1 == -1) || (b1 > b2)) {
		b1 = parsed_rm->match_from + parsed_rm->advance_words;
		b2 = parsed_rm->match_from + parsed_rm->advance_words - 1;
	}
	b2 -= parsed_rm->tail_words;
	wording BW = Wordings::new(b1, b2);
	wording CW = EMPTY_WORDING;

	if (parsed_rm->advance_words != parsed_rm->match_length) {
		if (!((<rulebook-bud>(BW)) && (<<r>> == FALSE))) {
			BW = Wordings::from(BW, parsed_rm->match_from + parsed_rm->match_length);
			if (<rulebook-bud>(BW)) {
				if (<<r>>) CW = GET_RW(<rulebook-bud>, 1);
			} else {
				CW = BW;
			}
		}
	} else {
		if (<rulebook-bud>(BW)) {
			if (<<r>>) CW = GET_RW(<rulebook-bud>, 1);
		} else {
			CW = BW;
		}
	}

	if (<rulebook-bud>(BW)) {
		if (<<r>>) CW = GET_RW(<rulebook-bud>, 1);
	} else if (parsed_rm->advance_words != parsed_rm->match_length) {
		BW = Wordings::from(BW, parsed_rm->match_from + parsed_rm->match_length);
		if (<rulebook-bud>(BW)) {
			if (<<r>>) CW = GET_RW(<rulebook-bud>, 1);
		} else {
			CW = BW;
		}
	} else {
		CW = BW;
	}

	if (Wordings::nonempty(CW)) phud->rule_parameter = CW;

	if ((phud->owning_rulebook) &&
		(Rulebooks::runs_during_activities(phud->owning_rulebook) == FALSE) &&
		(Rulebooks::action_focus(phud->owning_rulebook)) &&
		(Wordings::nonempty(phud->rule_parameter)) &&
		(Wordings::nonempty(phud->whenwhile))) {
		phud->rule_parameter =
			Wordings::new(Wordings::first_wn(phud->rule_parameter),
				Wordings::last_wn(phud->whenwhile));
		phud->whenwhile = EMPTY_WORDING;
	}

@ If we can't find a stem, the following chooses which problem to issue:

=
<unrecognised-rule-stem-diagnosis> ::=
	when *** |    ==> @<Issue PM_BadRulePreambleWhen problem@>
	...							==> @<Issue PM_BadRulePreamble problem@>

@<Issue PM_BadRulePreambleWhen problem@> =
	Problems::quote_source(1, current_sentence);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_BadRulePreambleWhen));
	Problems::issue_problem_segment(
		"The punctuation makes me think %1 should be a definition "
		"of a phrase or a rule, but it doesn't begin as it should, "
		"with either 'To' (e.g. 'To flood the riverplain:'), 'Definition:', "
		"a name for a rule (e.g. 'This is the devilishly cunning rule:'), "
		"'At' plus a time (e.g. 'At 11:12 PM:' or 'At the time when "
		"the clock chimes:') or the name of a rulebook. %P"
		"As your rule begins with 'When', it may be worth noting that in "
		"December 2006 the syntax used by Inform for timed events changed: "
		"the old syntax 'When the sky falls in:' to create a named "
		"event, the sky falls in, became 'At the time when the sky "
		"falls in:'. This was changed to avoid confusion with rules "
		"relating to when scenes begin or end. %P"
		"Or perhaps you meant to say that something would only happen "
		"when some condition held. Inform often allows this, but the "
		"'when...' part tends to be at the end, not up front - for "
		"instance, 'Understand \"blue\" as the deep crevasse when the "
		"location is the South Pole.'");
	Problems::issue_problem_end();

@<Issue PM_BadRulePreamble problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_BadRulePreamble),
		"the punctuation here ':' makes me think this should be a definition "
		"of a phrase and it doesn't begin as it should",
		"with either 'To' (e.g. 'To flood the riverplain:'), 'Definition:', "
		"a name for a rule (e.g. 'This is the devilishly cunning rule:'), "
		"'At' plus a time (e.g. 'At 11:12 PM:' or 'At the time when "
		"the clock chimes') or the name of a rulebook, possibly followed "
		"by some description of the action or value to apply to (e.g. "
		"'Instead of taking something:' or 'Every turn:').");

@<Disallow the definite article for anonymous rules@> =
	if ((parsed_rm->article_used == definite_article) &&
		(parsed_rm->placement_requested == MIDDLE_PLACEMENT))
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_RuleWithDefiniteArticle),
			"a rulebook can contain any number of rules",
			"so (e.g.) 'the before rule: ...' is disallowed; you should "
			"write 'a before rule: ...' instead.");

@

=
void RuleFamily::new_phrase(imperative_defn_family *self, imperative_defn *id, phrase *new_ph) {
	rule_family_data *rfd = RETRIEVE_POINTER_rule_family_data(id->family_specific_data);
	if (rfd->not_in_rulebook)
		Phrases::Usage::to_rule(&(new_ph->usage_data), id);
	else
		Rules::request_automatic_placement(
			Phrases::Usage::to_rule(&(new_ph->usage_data), id));
	new_ph->compile_with_run_time_debugging = TRUE;
}
