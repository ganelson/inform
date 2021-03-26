[RuleFamily::] Rule Family.

Imperative definitions of rules.

@

=
imperative_defn_family *RULE_EFF_family = NULL; /* "Before taking a container, ..." */

typedef struct rule_family_data {
	struct wording reduced_stem;
	struct wording constant_name;
	struct wording pattern;
	int not_in_rulebook;
	int event_time;
	struct wording event_name;
	struct linked_list *uses_as_event; /* of |use_as_event| */
	struct wording rule_parameter; /* text of object or action parameter */
	struct wording whenwhile; /* when/while for action/activity rulebooks */
	#ifdef IF_MODULE
	struct parse_node *during_scene_spec; /* what scene is currently under way */
	#endif
	struct rulebook *owning_rulebook; /* the primary booking for the phrase will be here */
	int owning_rulebook_placement; /* ...and with this placement value: see Rulebooks */
	CLASS_DEFINITION
} rule_family_data;

@

=
void RuleFamily::create_family(void) {
	RULE_EFF_family = ImperativeDefinitions::new_family(I"RULE_EFF");
	METHOD_ADD(RULE_EFF_family, CLAIM_IMP_DEFN_MTID, RuleFamily::claim);
	METHOD_ADD(RULE_EFF_family, ASSESS_IMP_DEFN_MTID, RuleFamily::assess);
	METHOD_ADD(RULE_EFF_family, NEW_PHRASE_IMP_DEFN_MTID, RuleFamily::new_phrase);
	METHOD_ADD(RULE_EFF_family, TO_RCD_IMP_DEFN_MTID, RuleFamily::to_rcd);
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
		rfd->uses_as_event = NEW_LINKED_LIST(use_as_event);
		rfd->rule_parameter = EMPTY_WORDING;
		rfd->whenwhile = EMPTY_WORDING;
		rfd->reduced_stem = EMPTY_WORDING;
		#ifdef IF_MODULE
		rfd->during_scene_spec = NULL;
		#endif
		rfd->owning_rulebook = NULL;
		rfd->owning_rulebook_placement = MIDDLE_PLACEMENT;

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

void RuleFamily::assess(imperative_defn_family *self, imperative_defn *id) {
	rule_family_data *rfd = RETRIEVE_POINTER_rule_family_data(id->family_specific_data);
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
		if (form) rfd->whenwhile = GET_RW(<rule-preamble-finer>, 2);
		#ifdef IF_MODULE
		rfd->during_scene_spec = during_spec;
		#endif
		rfd->owning_rulebook = parsed_rm->matched_rulebook;
		if (rfd->owning_rulebook == NULL) internal_error("rulebook stem misparsed");
		rfd->owning_rulebook_placement = parsed_rm->placement_requested;
		@<Disallow the definite article for anonymous rules@>;
		@<Cut off the bud from the stem@>;
	}
	rfd->reduced_stem = W;

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

	if (Wordings::nonempty(CW)) rfd->rule_parameter = CW;

	if ((rfd->owning_rulebook) &&
		(Rulebooks::runs_during_activities(rfd->owning_rulebook) == FALSE) &&
		(Rulebooks::action_focus(rfd->owning_rulebook)) &&
		(Wordings::nonempty(rfd->rule_parameter)) &&
		(Wordings::nonempty(rfd->whenwhile))) {
		rfd->rule_parameter =
			Wordings::new(Wordings::first_wn(rfd->rule_parameter),
				Wordings::last_wn(rfd->whenwhile));
		rfd->whenwhile = EMPTY_WORDING;
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
		RuleFamily::to_rule(id);
	else
		Rules::request_automatic_placement(RuleFamily::to_rule(id));
	new_ph->compile_with_run_time_debugging = TRUE;
}

@h The late-morning creations.
A little later on, we've made a rule phrase, and it now has a proper PHUD.
If the rule is an anonymous one, such as:

>> Instead of jumping: say "Don't."

then we need to call |Rules::obtain| to create a nameless |rule| structure
to be connected to it. But if the phrase has an explicit name:

>> Instead of swimming (this is the avoid water rule): say "Don't."

then we have a predeclared rule called "avoid water rule" already, so we
connect this existing one to the phrase.

=
rule *RuleFamily::to_rule(imperative_defn *id) {
	rule_family_data *rfd = RETRIEVE_POINTER_rule_family_data(id->family_specific_data);
	wording W = EMPTY_WORDING;
	int explicitly = FALSE;
	@<Find the name of the phrase, and whether or not it's explicitly given@>;

	rule *R = NULL;
	if (Wordings::nonempty(W)) R = Rules::by_name(W);
	if (R) @<Check that this isn't duplicating the name of a rule already made@>
	else R = Rules::obtain(W, explicitly);
	if (Wordings::empty(W))
		Hierarchy::markup_wording(R->compilation_data.rule_package, RULE_NAME_HMD, Node::get_text(id->at));
	Rules::set_imperative_definition(R, id);
	phrase *ph = id->defines;
	package_request *P = RTRules::package(R);
	ph->ph_iname = Hierarchy::make_localised_iname_in(RULE_FN_HL, P, ph->owning_module);

	@<Do some tedious business for indexing the rule later on@>;

	return R;
}

@<Find the name of the phrase, and whether or not it's explicitly given@> =
	if (Wordings::nonempty(rfd->event_name)) {
		W = Articles::remove_the(rfd->event_name);
	} else if (Wordings::nonempty(rfd->constant_name)) {
		W = Articles::remove_the(rfd->constant_name);
		explicitly = TRUE;
	}

@<Check that this isn't duplicating the name of a rule already made@> =
	imperative_defn *existing_id = Rules::get_imperative_definition(R);
	if ((existing_id) && (existing_id != id)) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, W);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_DuplicateRuleName));
		Problems::issue_problem_segment(
			"You wrote %1, but this would give a name ('%2') to a "
			"new rule which already belongs to an existing one.");
		Problems::issue_problem_end();
	}

@ This is simply to make the rule's entry in the Index more helpful.

@<Do some tedious business for indexing the rule later on@> =
	wording IX = rfd->rule_parameter;
	if (Wordings::nonempty(rfd->whenwhile)) {
		if (Wordings::first_wn(rfd->whenwhile) == Wordings::last_wn(rfd->rule_parameter) + 1) {
			IX = Wordings::new(Wordings::first_wn(rfd->rule_parameter), Wordings::last_wn(rfd->whenwhile));
		} else {
			IX = rfd->whenwhile;
		}
	}
	IXRules::set_italicised_index_text(R, IX);

@ =
int RuleFamily::get_timing_of_event(imperative_defn *id) {
	if (id->family != RULE_EFF_family) return NOT_A_TIMED_EVENT;
	rule_family_data *rfd = RETRIEVE_POINTER_rule_family_data(id->family_specific_data);
	return rfd->event_time;
}

@ For example, for the rule

>> Instead of taking the box while the skylight is open: ...

this returns "taking the box".

=
wording RuleFamily::get_prewhile_text(imperative_defn *id) {
	if (id->family != RULE_EFF_family) return EMPTY_WORDING;
	rule_family_data *rfd = RETRIEVE_POINTER_rule_family_data(id->family_specific_data);
	if (Wordings::nonempty(rfd->rule_parameter)) {
		wording E = rfd->rule_parameter;
		if (<when-while-clause>(E)) E = GET_RW(<when-while-clause>, 1);
		return E;
	}
	return EMPTY_WORDING;
}

@ =
<when-while-clause> ::=
	... when/while ...

@h Miscellaneous.
Some access routines.

=
int RuleFamily::get_rulebook_placement(imperative_defn *id) {
	if (id->family != RULE_EFF_family) return MIDDLE_PLACEMENT;
	rule_family_data *rfd = RETRIEVE_POINTER_rule_family_data(id->family_specific_data);
	return rfd->owning_rulebook_placement;
}

rulebook *RuleFamily::get_rulebook(imperative_defn *id) {
	if (id->family != RULE_EFF_family) return NULL;
	rule_family_data *rfd = RETRIEVE_POINTER_rule_family_data(id->family_specific_data);
	return rfd->owning_rulebook;
}

void RuleFamily::set_rulebook(imperative_defn *id, rulebook *rb) {
	if (id->family != RULE_EFF_family) internal_error("cannot set rulebook: not a rule");
	rule_family_data *rfd = RETRIEVE_POINTER_rule_family_data(id->family_specific_data);
	rfd->owning_rulebook = rb;
}

linked_list *RuleFamily::get_uses_as_event(imperative_defn *id) {
	if (id->family != RULE_EFF_family) return NULL;
	rule_family_data *rfd = RETRIEVE_POINTER_rule_family_data(id->family_specific_data);
	return rfd->uses_as_event;
}

int NAP_problem_explained = FALSE; /* pertains to Named Action Patterns */
int issuing_ANL_problem = FALSE; /* pertains to Action Name Lists */

void RuleFamily::to_rcd(imperative_defn_family *self, imperative_defn *id, ph_runtime_context_data *rcd) {
	rule_family_data *rfd = RETRIEVE_POINTER_rule_family_data(id->family_specific_data);
	if (rfd->not_in_rulebook)
		rcd->permit_all_outcomes = TRUE;
	else
		@<Finish work parsing the conditions for the rule to fire@>;
}

@ All of this is just dumb copying...

@<Finish work parsing the conditions for the rule to fire@> =
	
	rcd->compile_for_rulebook = &(rfd->owning_rulebook);

	if (Wordings::nonempty(rfd->rule_parameter)) @<Parse what used to be the bud into the PHRCD@>;

	if (Wordings::nonempty(rfd->whenwhile)) {
		rcd->activity_context =
			Wordings::new(
				Wordings::first_wn(rfd->whenwhile) + 1,
				Wordings::last_wn(rfd->whenwhile));
		rcd->activity_where = current_sentence;
	}

	#ifdef IF_MODULE
	if (rfd->during_scene_spec) rcd->during_scene = rfd->during_scene_spec;
	#endif

@ ...except for this:

@<Parse what used to be the bud into the PHRCD@> =
	#ifdef IF_MODULE
	if (Rulebooks::action_focus(rfd->owning_rulebook)) {
		int saved = ParseActionPatterns::enter_mode(PERMIT_TRYING_OMISSION);
		if (Rules::all_action_processing_variables())
			Frames::set_stvol(
				Frames::current_stack_frame(), Rules::all_action_processing_variables());
		if (<action-pattern>(rfd->rule_parameter)) rcd->ap = <<rp>>;
		Frames::remove_nonphrase_stack_frame();
		ParseActionPatterns::restore_mode(saved);

		if (rcd->ap == NULL)
			@<Issue a problem message for a bad action@>;
	} else {
		kind *pk = Rulebooks::get_focus_kind(rfd->owning_rulebook);
		rcd->ap = ActionPatterns::parse_parametric(rfd->rule_parameter, pk);
		if (rcd->ap == NULL) {
			if (Wordings::nonempty(rfd->whenwhile)) {
				wording F = Wordings::up_to(rfd->rule_parameter, Wordings::last_wn(rfd->whenwhile));
				rcd->ap = ActionPatterns::parse_parametric(F, pk);
				if (rcd->ap) {
					rfd->rule_parameter = F;
					rfd->whenwhile = EMPTY_WORDING;
				}
			}
		}
		if (rcd->ap == NULL) @<Issue a problem message for a bad parameter@>;
	}
	#endif
	#ifndef IF_MODULE
	kind *pk = Rulebooks::get_focus_kind(rfd->owning_rulebook);
	@<Issue a problem message for a bad parameter@>;
	#endif

@ All that's left is to issue a "good" problem message, but this is quite
a large undertaking, because the situation as we currently know it is just
that something's wrong with the rule preamble -- which covers an enormous
range of different faults.

The "PAP failure reason" is a sort of error code set by the action pattern
parser, recording how it most recently failed.

@<Issue a problem message for a bad action@> =
	LOG("Bad action pattern: %W = $A\nPAP failure reason: %d\n",
		rfd->rule_parameter, rcd->ap, pap_failure_reason);
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, rfd->rule_parameter);
	if (<action-problem-diagnosis>(rfd->rule_parameter) == FALSE)
		switch(pap_failure_reason) {
			case MIXEDNOUNS_PAPF: @<Issue PM_APWithDisjunction problem@>; break;
			case NOPARTICIPLE_PAPF: @<Issue PM_APWithNoParticiple problem@>; break;
			case IMMISCIBLE_PAPF: @<Issue PM_APWithImmiscible problem@>; break;
			case WHEN_PAPF: @<Issue PM_APWithBadWhen problem@>; break;
			default: @<Issue PM_APUnknown problem@>; break;
		}

@<Issue PM_APWithDisjunction problem@> =
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_APWithDisjunction));
	Problems::issue_problem_segment(
		"You wrote %1, which seems to introduce a rule, but the "
		"circumstances ('%2') seem to be too general for me to "
		"understand in a single rule. I can understand a choice of "
		"of actions, in a list such as 'taking or dropping the ball', "
		"but there can only be one set of noun(s) supplied. So 'taking "
		"the ball or taking the bat' is disallowed. You can get around "
		"this by using named actions ('Taking the ball is being "
		"mischievous. Taking the bat is being mischievous. Instead of "
		"being mischievous...'), or it may be less bother just to "
		"write more than one rule.");
	Problems::issue_problem_end();

@<Issue PM_APWithNoParticiple problem@> =
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_APWithNoParticiple));
	Problems::issue_problem_segment(
		"You wrote %1, which seems to introduce a rule taking effect "
		"only '%2'. But this does not look like an action, since "
		"there is no sign of a participle ending '-ing' (as in "
		"'taking the brick', say) - which makes me think I have "
		"badly misunderstood what you intended.");
	Problems::issue_problem_end();

@<Issue PM_APWithImmiscible problem@> =
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_APWithImmiscible));
	Problems::issue_problem_segment(
		"You wrote %1, which seems to introduce a rule taking effect "
		"only '%2'. But this is a combination of actions which cannot "
		"be mixed. The only alternatives where 'or' is allowed are "
		"cases where a choice of actions is given but applying to "
		"the same objects in each case. (So 'taking or dropping the "
		"CD' is allowed, but 'dropping the CD or inserting the CD "
		"into the jewel box' is not, because the alternatives there "
		"would make different use of objects from each other.)");
	Problems::issue_problem_end();

@<Issue PM_APWithBadWhen problem@> =
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_APWithBadWhen));
	wording Q = rfd->rule_parameter;
	int diagnosis = 0;
	if (<action-when-diagnosis>(Q)) {
		Q = Wordings::new(<<cw1>>, <<cw2>>);
		diagnosis = <<r>>;
	}
	Problems::quote_wording(2, Q);
	Problems::quote_text(3, "so I am unable to accept this rule.");
	if (diagnosis == 2) {
		Problems::quote_text(3,
			"perhaps because 'nothing' tends not to be allowed in Inform conditions? "
			"(Whereas 'no thing' is usually allowed.)");
	}
	if (diagnosis == 3) {
		Problems::quote_text(3,
			"perhaps because 'nowhere' tends not to be allowed in Inform conditions? "
			"(Whereas 'no room' is usually allowed.)");
	}
	Problems::issue_problem_segment(
		"You wrote %1, which seems to introduce a rule taking effect "
		"only '%2'. But this condition did not make sense, %3");
	if (diagnosis == 1)
		Problems::issue_problem_segment(
			"%PIt might be worth mentioning that a 'when' condition tacked on to "
			"an action like this is not allowed to mention or use 'called' values.");
	if (diagnosis == 4)
		Problems::issue_problem_segment(
			"%PThe problem might be that 'and' has been followed by 'when' or "
			"'while'. For example, to make a rule with two conditions, this is "
			"okay: 'Instead of jumping when Peter is happy and Peter is in the "
			"location'; but the same thing with '...and when Peter is...' is not allowed.");
	Problems::issue_problem_end();

@<Issue PM_APUnknown problem@> =
	Problems::quote_wording(2, rfd->rule_parameter);
	if (pap_failure_reason == WHENOKAY_PAPF)
		Problems::quote_text(3,
			"The part after 'when' (or 'while') was fine, but the earlier words");
	else Problems::quote_text(3, "But that");
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_APUnknown));
	Problems::issue_problem_segment(
		"You wrote %1, which seems to introduce a rule taking effect only if the "
		"action is '%2'. %3 did not make sense as a description of an action.");
	@<See if it starts with a valid action name, at least@>;
	@<See if this might be a when-for confusion@>;
	@<Break down the action list and say which are okay@>;
	Problems::issue_problem_segment(
		" I am unable to place this rule into any rulebook.");
	Problems::issue_problem_end();

@<See if it starts with a valid action name, at least@> =
	action_name *an;
	LOOP_OVER(an, action_name)
		if ((Wordings::length(rfd->rule_parameter) < Wordings::length(ActionNameNames::tensed(an, IS_TENSE))) &&
			(Wordings::match(rfd->rule_parameter,
				Wordings::truncate(ActionNameNames::tensed(an, IS_TENSE), Wordings::length(rfd->rule_parameter))))) {
			Problems::quote_wording(3, ActionNameNames::tensed(an, IS_TENSE));
			Problems::issue_problem_segment(
				" I notice that there's an action called '%3', though: perhaps "
				"this is what you meant?");
			break;
		}

@<See if this might be a when-for confusion@> =
	if (pap_failure_reason == WHENOKAY_PAPF) {
		time_period *duration = Occurrence::parse(rfd->reduced_stem);
		if (duration) {
			Problems::quote_wording(3, Occurrence::used_wording(duration));
			Problems::issue_problem_segment(
				" (I wonder if this might be because '%3', which looks like a "
				"condition on the timing, is the wrong side of the 'when...' "
				"clause?)");
		}
	}

@ If the action pattern contains what looks like a list of action names, as
for example

>> Instead of taking or dropping the magnet: ...

then the anl-diagnosis grammar will parse this and return N equal to 2, the
apparent number of action names. We then run the grammar again, but this time
allowing it to print comments on each apparent action name it sees.

@<Break down the action list and say which are okay@> =
	issuing_ANL_problem = FALSE; NAP_problem_explained = FALSE;
	<anl-diagnosis>(rfd->rule_parameter);
	int N = <<r>>;
	if (N > 1) {
		int positive = TRUE;
		ActionNameLists::parse(rfd->rule_parameter, IS_TENSE, &positive);
		if (positive == FALSE)
			Problems::issue_problem_segment(
				" This looks like a list of actions to avoid: ");
		else
			Problems::issue_problem_segment(
				" Looking at this as a list of alternative actions: ");
		issuing_ANL_problem = TRUE; NAP_problem_explained = FALSE;
		<anl-diagnosis>(rfd->rule_parameter);
		Problems::issue_problem_segment(" so");
	}

@ We have a much easier time if the rulebook was value-focused, so that
the only possible problem is that the value was wrong.

@<Issue a problem message for a bad parameter@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, rfd->rule_parameter);
	Problems::quote_kind(3, pk);
	<parametric-problem-diagnosis>(rfd->reduced_stem);

@ And that is the end of the code as such, but we still have to define the
three diagnosis grammars we needed.

@ Parametric rules are those applying to values not actions, and the following
is used to choose a problem message if the value makes no sense.

=
<parametric-problem-diagnosis> ::=
	when the play begins/ends |    ==> @<Issue PM_WhenThePlay problem@>
	...									==> @<Issue PM_BadParameter problem@>

@<Issue PM_WhenThePlay problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_WhenThePlay),
		"there's no scene called 'the play'",
		"so I think you need to remove 'the' - Inform has two "
		"special rulebooks, 'When play begins' and 'When play ends', "
		"and I think you probably mean to refer to one of those.");

@<Issue PM_BadParameter problem@> =
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_BadParameter));
	Problems::issue_problem_segment(
		"You wrote %1, but the description of the thing(s) to which the rule "
		"applies ('%2') did not make sense. This is %3 based rulebook, so "
		"that should have described %3.");
	Problems::issue_problem_end();

@ And here we choose a problem message if a rule applying to an action is used,
but the action isn't one we recognise.

=
<action-problem-diagnosis> ::=
	in the presence of ... |    ==> @<Issue PM_NonActionInPresenceOf problem@>
	in ...							==> @<Issue PM_NonActionIn problem@>


@<Issue PM_NonActionInPresenceOf problem@> =
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_NonActionInPresenceOf));
	Problems::issue_problem_segment(
		"You wrote %1, but 'in the presence of...' is a clause which can "
		"only be used to talk about an action: so, for instance, 'waiting "
		"in the presence of...' is needed. "
		"This problem arises especially with 'every turn' rules, where "
		"'every turn in the presence of...' looks plausible but doesn't "
		"work. This could be fixed by writing 'Every turn doing something "
		"in the presence of...', but a neater solution talks about the "
		"current situation instead: 'Every turn when the player can "
		"see...'.");
	Problems::issue_problem_end();

@<Issue PM_NonActionIn problem@> =
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_NonActionIn));
	Problems::issue_problem_segment(
		"You wrote %1, but 'in...' used in this way should really belong "
		"to an action: for instance, 'Before waiting in the Library'. "
		"Rules like 'Every turn in the Library' don't work, because "
		"'every turn' is not an action; what's wanted is 'Every turn "
		"when in the Library'.");
	Problems::issue_problem_end();

@ The following is used to choose a problem when the trouble with the rule
occurred in a when/while condition at the end; while all five cases produce
the PM_APWithBadWhen problem, they each provide different clues as to what
might have gone wrong.

=
<action-when-diagnosis> ::=
	... called ... {when/while ...} |   ==> { 1, -, <<cw1>> = Wordings::first_wn(WR[3]), <<cw2>> = Wordings::last_wn(WR[3]) }
	... {when/while *** nothing ***} |  ==> { 2, -, <<cw1>> = Wordings::first_wn(WR[2]), <<cw2>> = Wordings::last_wn(WR[2]) }
	... {when/while *** nowhere ***} |  ==> { 3, -, <<cw1>> = Wordings::first_wn(WR[2]), <<cw2>> = Wordings::last_wn(WR[2]) }
	... and {when/while ...} |          ==> { 4, -, <<cw1>> = Wordings::first_wn(WR[2]), <<cw2>> = Wordings::last_wn(WR[2]) }
	... {when/while ...}                ==> { 5, -, <<cw1>> = Wordings::first_wn(WR[2]), <<cw2>> = Wordings::last_wn(WR[2]) }

@ =
<anl-diagnosis> ::=
	<anl-inner-diagnosis> when/while ... |        ==> { pass 1 }
	<anl-inner-diagnosis>						  ==> { pass 1 }

<anl-inner-diagnosis> ::=
	<anl-entry-diagnosis> <anl-tail-diagnosis> |  ==> { R[1] + R[2], - }
	<anl-entry-diagnosis>                         ==> { pass 1 }

<anl-tail-diagnosis> ::=
	, _or <anl-inner-diagnosis> |                 ==> { pass 1 }
	_,/or <anl-inner-diagnosis>                   ==> { pass 1 }

<anl-entry-diagnosis> ::=
	......											==> @<Diagnose problem with this ANL entry@>

@<Diagnose problem with this ANL entry@> =
	if ((issuing_ANL_problem) && (!preform_lookahead_mode)) {
		Problems::quote_wording(4, W);
		#ifdef IF_MODULE
		if (<action-pattern>(W) == FALSE) {
			Problems::issue_problem_segment("'%4' did not make sense; ");
			return TRUE;
		}
		action_pattern *ap = <<rp>>;
		int form = <<r>>;
		if (APClauses::is_request(ap)) {
			Problems::issue_problem_segment(
				"'%4' would make sense as an action on its own, but 'or' can't "
				"be used in combination with 'asking... to try...' actions; ");
			return TRUE;
		}

		if (ActionPatterns::refers_to_past(ap)) {
			Problems::issue_problem_segment(
				"'%4' would make sense as an action on its own, but 'or' can't "
				"be used in combination with actions with time periods attached; ");
			return TRUE;
		}
		if (<named-action-pattern>(W)) {
			if (NAP_problem_explained == FALSE)
				Problems::issue_problem_segment(
					"'%4' only made sense as a named kind of action, which can "
					"be used on its own but not in an action list; ");
			else
				Problems::issue_problem_segment(
					"'%4' is another named kind of action; ");
			NAP_problem_explained = TRUE;
			return TRUE;
		}
		if (form == ACTOR_EXP_PLAYER) {
			Problems::issue_problem_segment(
				"'%4' would have been okay except for using the word 'trying', "
				"which isn't allowed in a list like this; ");
			return TRUE;
		}
		#endif
		Problems::issue_problem_segment("'%4' was okay; ");
	}
	==> { 1, - };
