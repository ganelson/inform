[RuleFamily::] Rule Family.

Imperative definitions of rules.

@h Introduction.
This family handles definitions of rules which give explicit Inform 7
source text to show what they do. (It's also possible to create rules which
are implemented by Inter-level functions only, and those do not fall under
this section, because they have no //imperative_defn//.) For example:
= (text as Inform 7)
Every turn:
	say "The grandfather clock ticks reprovingly."
=
Some rules have names, some do not; some indicate explicitly what rulebook
they belong to, and others are placed in rulebooks with separate sentences.
So there's quite a lot to do.

=
imperative_defn_family *rule_idf = NULL; /* "Before taking a container, ..." */
void RuleFamily::create_family(void) {
	rule_idf = ImperativeDefinitionFamilies::new(I"rule-idf", FALSE);
	METHOD_ADD(rule_idf, IDENTIFY_IMP_DEFN_MTID, RuleFamily::identify);
	METHOD_ADD(rule_idf, ASSESS_IMP_DEFN_MTID, RuleFamily::assess);
	METHOD_ADD(rule_idf, ASSESSMENT_COMPLETE_IMP_DEFN_MTID, RuleFamily::assessment_complete);
	METHOD_ADD(rule_idf, ALLOWS_RULE_ONLY_PHRASES_IMP_DEFN_MTID, RuleFamily::allows_rule_only);
	METHOD_ADD(rule_idf, GIVEN_BODY_IMP_DEFN_MTID, RuleFamily::given_body);
	METHOD_ADD(rule_idf, TO_RCD_IMP_DEFN_MTID, RuleFamily::to_rcd);
	METHOD_ADD(rule_idf, COMPILE_IMP_DEFN_MTID, RuleFamily::compile);
}

@ Each family member gets one of the following. In splitting up preambles,
the "usage preamble" is the part indicating when the rule should happen, and
this is divided up into smaller excerpts of text, as in the following examples:
= (text)
rule instead    of          taking or dropping when Miss Bianca is in the Embassy:
<---------------------------- usage_preamble ----------------------------------->
     <- stem ---->          <------------------ applicability ------------------>
     <- ps ->   <- bud ->   <--- prewhile --->      <-------- whenwhile -------->

after examining    an open door during the Hurricane (this is the exit hunting rule):
<----------------- usage preamble ----------------->              <- const name -->
<---- stem ----->  <-- appl -->        <- during -->
<- pruned stem ->  <-- pw ---->
=

=
typedef struct rule_family_data {
	struct wording usage_preamble;
	struct wording pruned_stem;
	struct wording constant_name;
	struct wording prewhile_applicability;
	struct wording applicability;
	struct wording whenwhile;
	struct parse_node *during_spec; /* what scene is currently under way */

	int not_in_rulebook;
	struct rule *defines;
	struct rulebook *owning_rulebook; /* the primary booking for the phrase will be here */
	int owning_rulebook_placement; /* ...and with this placement value: see Rulebooks */
	int permit_all_outcomes; /* waive the usual restrictions on rule outcomes */

	void *plugin_rfd[MAX_PLUGINS]; /* storage for plugins to attach, if they want to */
	CLASS_DEFINITION
} rule_family_data;

rule_family_data *RuleFamily::new_data(void) {
	rule_family_data *rfd = CREATE(rule_family_data);
	rfd->pruned_stem = EMPTY_WORDING;
	rfd->constant_name = EMPTY_WORDING;
	rfd->usage_preamble = EMPTY_WORDING;
	rfd->applicability = EMPTY_WORDING;
	rfd->prewhile_applicability = EMPTY_WORDING;
	rfd->whenwhile = EMPTY_WORDING;
	rfd->during_spec = NULL;
	rfd->not_in_rulebook = FALSE;
	rfd->defines = NULL;
	rfd->owning_rulebook = NULL;
	rfd->owning_rulebook_placement = MIDDLE_PLACEMENT;
	rfd->permit_all_outcomes = FALSE;
	for (int i=0; i<MAX_PLUGINS; i++) rfd->plugin_rfd[i] = NULL;
	return rfd;
}

@ These two macros provide access to plugin-specific rule family data:

@d RFD_PLUGIN_DATA(id, rfd)
	((id##_rfd_data *) rfd->plugin_rfd[id##_plugin->allocation_id])

@d CREATE_PLUGIN_RFD_DATA(id, rfd, creator)
	(rfd)->plugin_rfd[id##_plugin->allocation_id] = (void *) (creator(rfd));

@h Identification.
We are going to claim as our own any definition whose name matches the
following nonterminal -- and because of the last production, this will always
happen. (That's why it is important that we are the last family to claim.)

=
<rule-preamble> ::=
	this is the {... rule} |            ==> { 1, - }
	this is the rule |                  ==> @<Issue PM_NamelessRule problem@>
	this is ... rule |                  ==> @<Issue PM_UnarticledRule problem@>
	this is ... rules |                 ==> @<Issue PM_PluralisedRule problem@>
	... ( this is the {... rule} ) |    ==> { 2, - }
	... ( this is the rule ) |          ==> @<Issue PM_NamelessRule problem@>
	... ( this is ... rule ) |          ==> @<Issue PM_UnarticledRule problem@>
	... ( this is ... rules ) |         ==> @<Issue PM_PluralisedRule problem@>
	...                                 ==> { 3, - }

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

@ Forms 1 and 2 give a rule name; forms 2 and 3 say which rulebook it goes into.

=
void RuleFamily::identify(imperative_defn_family *self, imperative_defn *id) {
	wording W = Node::get_text(id->at);
	if (<rule-preamble>(W)) {
		int form = <<r>>;
		id->family = rule_idf;
		rule_family_data *rfd = RuleFamily::new_data();

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
		if ((form == 2) || (form == 3)) rfd->usage_preamble = GET_RW(<rule-preamble>, 1);

		PluginCalls::new_rule_defn_notify(id, rfd);
	}
}

@h Assessment.
Now we take a closer look at the rule preamble.

=
<rule-preamble-fine> ::=
	<rule-preamble-finer> during <s-scene-description> | ==> { R[1], RP[2] }
	<rule-preamble-finer>                                ==> { R[1], NULL }

<rule-preamble-finer> ::=
	{<rulebook-stem-embellished>} {when/while ...} |     ==> { TRUE, - }
	{<rulebook-stem-embellished>} |                      ==> { FALSE, - }
	...                                                  ==> { NOT_APPLICABLE, - }

<rulebook-stem-embellished> ::=
	<rulebook-stem> *** |
	<article> rule for <rulebook-stem> *** |
	<article> rule <rulebook-stem> *** |
	rule for <rulebook-stem> *** |
	rule <rulebook-stem> ***

<rulebook-bud> ::=
	of/for ... |                                         ==> { TRUE, - }
	rule about/for/on ... |                              ==> { TRUE, - }
	rule                                                 ==> { FALSE, - }

<unrecognised-rule-stem-diagnosis> ::=
	when *** |                                           ==> @<Issue PM_BadRulePreambleWhen@>
	...                                                  ==> @<Issue PM_BadRulePreamble@>

@<Issue PM_BadRulePreambleWhen@> =
	Problems::quote_source(1, current_sentence);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_BadRulePreambleWhen));
	Problems::issue_problem_segment(
		"The punctuation makes me think %1 should be a definition of a phrase or a rule, "
		"but it doesn't begin as it should, with either 'To' (e.g. 'To flood the riverplain:'), "
		"'Definition:', a name for a rule (e.g. 'This is the devilishly cunning rule:'), "
		"'At' plus a time (e.g. 'At 11:12 PM:' or 'At the time when the clock chimes:') or "
		"the name of a rulebook. %P"
		"Perhaps you meant to say that something would only happen when some condition held. "
		"Inform often allows this, but the 'when...' part tends to be at the end, not up "
		"front - for instance, 'Understand \"blue\" as the deep crevasse when the location "
		"is the South Pole.'");
	Problems::issue_problem_end();

@<Issue PM_BadRulePreamble@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_BadRulePreamble),
		"the punctuation here ':' makes me think this should be a definition of a phrase "
		"and it doesn't begin as it should",
		"with either 'To' (e.g. 'To flood the riverplain:'), 'Definition:', a name for a "
		"rule (e.g. 'This is the devilishly cunning rule:'), 'At' plus a time (e.g. 'At "
		"11:12 PM:' or 'At the time when the clock chimes') or the name of a rulebook, "
		"possibly followed by some description of the action or value to apply to (e.g. "
		"'Instead of taking something:' or 'Every turn:').");

@ The crucial nonterminal in the above grammar is <rulebook-stem>, which tries
to make the longest match it can of a rulebook name; if it matches successfully,
then calling |Rulebooks::match| produces a detailed rundown of its findings,
which are too elaborate to pass back in a simple pointer.

=
void RuleFamily::assess(imperative_defn_family *self, imperative_defn *id) {
	rule_family_data *rfd = RETRIEVE_POINTER_rule_family_data(id->family_specific_data);
	if (rfd->not_in_rulebook == FALSE) {
		wording W = rfd->usage_preamble;
		<rule-preamble-fine>(W);
		parse_node *during_spec = <<rp>>;
		int has_when = <<r>>;
		rulebook_match *parsed_rm = Rulebooks::match();
		W = GET_RW(<rule-preamble-finer>, 1);
		if (has_when == NOT_APPLICABLE) {
			<unrecognised-rule-stem-diagnosis>(W);
		} else {
			if (has_when) rfd->whenwhile = GET_RW(<rule-preamble-finer>, 2);
			rfd->during_spec = during_spec;
			rfd->owning_rulebook = parsed_rm->matched_rulebook;
			rfd->owning_rulebook_placement = parsed_rm->placement_requested;
			@<Disallow the definite article for middling rules@>;
			@<Cut off the bud from the stem@>;
			@<Merge the when/while text back into applicability, for actions@>;
		}
		rfd->pruned_stem = W;
	}
}

@ This is a super-pedantic problem message, and might cause problems in languages
other than English.

@<Disallow the definite article for middling rules@> =
	if ((parsed_rm->article_used == definite_article) &&
		(parsed_rm->placement_requested == MIDDLE_PLACEMENT))
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_RuleWithDefiniteArticle),
			"a rulebook can contain any number of rules",
			"so (e.g.) 'the before rule: ...' is disallowed; you should write 'a before "
			"rule: ...' instead.");

@ The bud is not always present at all, and need not always be at the end of the stem,
so we have to be very careful:

@<Cut off the bud from the stem@> =
	wording BUDW = GET_RW(<rulebook-stem-embellished>, 1);
	int b1 = Wordings::first_wn(BUDW), b2 = Wordings::last_wn(BUDW);
	if ((b1 == -1) || (b1 > b2)) {
		b1 = parsed_rm->match_from + parsed_rm->advance_words;
		b2 = parsed_rm->match_from + parsed_rm->advance_words - 1;
	}
	b2 -= parsed_rm->tail_words;
	BUDW = Wordings::new(b1, b2);

	wording APPW = EMPTY_WORDING;

	if (parsed_rm->advance_words != parsed_rm->match_length) {
		if (!((<rulebook-bud>(BUDW)) && (<<r>> == FALSE))) {
			BUDW = Wordings::from(BUDW, parsed_rm->match_from + parsed_rm->match_length);
			if (<rulebook-bud>(BUDW)) {
				if (<<r>>) APPW = GET_RW(<rulebook-bud>, 1);
			} else {
				APPW = BUDW;
			}
		}
	} else {
		if (<rulebook-bud>(BUDW)) {
			if (<<r>>) APPW = GET_RW(<rulebook-bud>, 1);
		} else {
			APPW = BUDW;
		}
	}

	if (<rulebook-bud>(BUDW)) {
		if (<<r>>) APPW = GET_RW(<rulebook-bud>, 1);
	} else if (parsed_rm->advance_words != parsed_rm->match_length) {
		BUDW = Wordings::from(BUDW, parsed_rm->match_from + parsed_rm->match_length);
		if (<rulebook-bud>(BUDW)) {
			if (<<r>>) APPW = GET_RW(<rulebook-bud>, 1);
		} else {
			APPW = BUDW;
		}
	} else {
		APPW = BUDW;
	}

	if (Wordings::nonempty(APPW)) {
		rfd->applicability = APPW;
		rfd->prewhile_applicability = APPW;
	}

@ This unobvious manoeuvre puts the when/while text back again, so that:
= (text)
rule instead of taking or dropping when Miss Bianca is in the Embassy:
                <----- appl -----> <---------- whenwhile ----------->
=
becomes:
= (text)
rule instead of taking or dropping when Miss Bianca is in the Embassy:
                <----- appl ---------------------------------------->
=
This is done only where we now know that the stem specified a rulebook based
on actions, and the reason it's done is that action applicabilities are parsed
with a grammar much more sensitive to ambiguities, and in which "when..."
clauses are therefore better recognised.

@<Merge the when/while text back into applicability, for actions@> =
	if ((rfd->owning_rulebook) &&
		(Rulebooks::runs_during_activities(rfd->owning_rulebook) == FALSE) &&
		(Rulebooks::action_focus(rfd->owning_rulebook)) &&
		(Wordings::nonempty(rfd->applicability)) &&
		(Wordings::nonempty(rfd->whenwhile))) {
		rfd->applicability =
			Wordings::new(Wordings::first_wn(rfd->applicability),
				Wordings::last_wn(rfd->whenwhile));
		rfd->whenwhile = EMPTY_WORDING;
	}

@ Every rule corresponds to a |rule| structure. If the rule is an anonymous
one, such as:

>> Instead of jumping: say "Don't."

then we need to call |Rules::obtain| to create a nameless |rule| structure
to be connected to it. But if the phrase has an explicit name:

>> Instead of swimming (this is the avoid water rule): say "Don't."

then we have a predeclared rule called "avoid water rule" already, so we
connect this existing one to the phrase.

=
void RuleFamily::given_body(imperative_defn_family *self, imperative_defn *id) {
	rule_family_data *rfd = RETRIEVE_POINTER_rule_family_data(id->family_specific_data);
	rule *R = NULL;
	@<Set R to a corresponding rule structure@>;
	rfd->defines = R;
	id->body_of_defn->compilation_data.compile_with_run_time_debugging = TRUE;
	IDTypeData::set_mor(&(id->body_of_defn->type_data),
		DECIDES_NOTHING_AND_RETURNS_MOR, NULL);
	if (rfd->not_in_rulebook) rfd->permit_all_outcomes = TRUE;
}

@<Set R to a corresponding rule structure@> =
	rule_family_data *rfd = RETRIEVE_POINTER_rule_family_data(id->family_specific_data);
	wording W = EMPTY_WORDING;
	int explicitly = FALSE;
	if (Wordings::nonempty(rfd->constant_name)) {
		W = Articles::remove_the(rfd->constant_name);
		explicitly = TRUE;
	}
	if (Wordings::nonempty(W)) R = Rules::by_name(W);
	if (R) @<Check that this isn't duplicating the name of a rule already made@>
	else R = Rules::obtain(W, explicitly);
	Rules::set_imperative_definition(R, id);
	@<Merge the applicability and when/while text for indexing purposes@>;

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

@<Merge the applicability and when/while text for indexing purposes@> =
	wording IX = rfd->applicability;
	if (Wordings::nonempty(rfd->whenwhile)) {
		if (Wordings::first_wn(rfd->whenwhile) == Wordings::last_wn(rfd->applicability) + 1) {
			IX = Wordings::new(Wordings::first_wn(rfd->applicability),
				Wordings::last_wn(rfd->whenwhile));
		} else {
			IX = rfd->whenwhile;
		}
	}
	RTRules::set_italicised_index_text(R, IX);

@ This is to do with named outcomes of rules, whereby certain outcomes are
normally limited to the use of rules in particular rulebooks.

=
int RuleFamily::outcome_restrictions_waived(void) {
	id_body *idb = Functions::defn_being_compiled();
	if (idb == NULL) return FALSE;
	imperative_defn *id = idb->head_of_defn;
	if (id->family != rule_idf) return FALSE;
	rule_family_data *rfd = RETRIEVE_POINTER_rule_family_data(id->family_specific_data);
	return rfd->permit_all_outcomes;
}

@ At the end of the assessment process, we can finally put the rules into their
rulebooks. We make "automatic placements" first -- i.e., those where the usage
preamble specified which rulebook the rule belonged to; and then we make manual
placements, which may move or remove rules already place. See //Rule Placement Requests//
for how sentences specifying this are parsed.

@e TRAVERSE_FOR_RULE_FILING_SMFT

=
void RuleFamily::assessment_complete(imperative_defn_family *self) {
	imperative_defn *id;
	LOOP_OVER(id, imperative_defn)
		if (id->family == rule_idf) {
			rule_family_data *rfd = RETRIEVE_POINTER_rule_family_data(id->family_specific_data);
			if (rfd->not_in_rulebook == FALSE) Rules::request_automatic_placement(rfd->defines);
		}

	int initial_problem_count = problem_count;
	RuleBookings::make_automatic_placements();
	if (initial_problem_count < problem_count) return;

	SyntaxTree::traverse(Task::syntax_tree(), RuleFamily::visit_to_parse_placements);
}

void RuleFamily::visit_to_parse_placements(parse_node *p) {
	if ((Node::get_type(p) == SENTENCE_NT) &&
		(p->down) &&
		(Node::get_type(p->down) == VERB_NT)) {
		prevailing_mood = Annotations::read_int(p->down, verbal_certainty_ANNOT);
		MajorNodes::try_special_meaning(TRAVERSE_FOR_RULE_FILING_SMFT, p->down);
	}
}

@h Runtime context data.

=
int NAP_problem_explained = FALSE; /* pertains to Named Action Patterns */
int issuing_ANL_problem = FALSE; /* pertains to Action Name Lists */
int defective_ANL_clauses = 0; /* ditto */

void RuleFamily::to_rcd(imperative_defn_family *self, imperative_defn *id,
	id_runtime_context_data *rcd) {
	rule_family_data *rfd = RETRIEVE_POINTER_rule_family_data(id->family_specific_data);
	if (rfd->not_in_rulebook == FALSE) {
		if (Wordings::nonempty(rfd->applicability))
			@<Parse the applicability text into the PHRCD@>;
		if (Wordings::nonempty(rfd->whenwhile))
			rcd->activity_context =
				Wordings::from(rfd->whenwhile, Wordings::first_wn(rfd->whenwhile) + 1);
		if (rfd->during_spec) Scenes::set_rcd_spec(rcd, rfd->during_spec);
	}
}

@ Here we try the text first without its when clause, then with, and accept
whichever way works.

@<Parse the applicability text into the PHRCD@> =
	if (Rulebooks::action_focus(rfd->owning_rulebook)) {
		parse_node *save_cs = current_sentence;
		ActionRules::set_ap(rcd, ActionPatterns::parse_action_based(rfd->applicability));
		current_sentence = save_cs;
		if (ActionRules::get_ap(rcd) == NULL) @<Issue a problem message for a bad action@>;
	} else {
		kind *pk = Rulebooks::get_focus_kind(rfd->owning_rulebook);
		ActionRules::set_ap(rcd, ActionPatterns::parse_parametric(rfd->applicability, pk));
		if (ActionRules::get_ap(rcd) == NULL) {
			if (Wordings::nonempty(rfd->whenwhile)) {
				wording F = Wordings::up_to(rfd->applicability, Wordings::last_wn(rfd->whenwhile));
				ActionRules::set_ap(rcd, ActionPatterns::parse_parametric(F, pk));
				if (ActionRules::get_ap(rcd)) {
					rfd->applicability = F;
					rfd->whenwhile = EMPTY_WORDING;
				}
			}
		}
		if (ActionRules::get_ap(rcd) == NULL) @<Issue a problem message for a bad parameter@>;
	}

@ All that's left is to issue a "good" problem message, but this is quite a
large undertaking, because the situation as we currently know it is just that
something's wrong with the rule preamble -- which covers an enormous range of
different faults.

The |pap_failure_reason| is a sort of error code set by the action pattern
parser, recording how it most recently failed.

@<Issue a problem message for a bad action@> =
	LOG("Bad action pattern: %W = $A\nPAP failure reason: %d\n",
		rfd->applicability, ActionRules::get_ap(rcd), pap_failure_reason);
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, rfd->applicability);
	if (<action-problem-diagnosis>(rfd->applicability) == FALSE)
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
		"You wrote %1, which seems to introduce a rule, but the circumstances ('%2') seem "
		"to be too general for me to understand in a single rule. I can understand a "
		"choice of actions, in a list such as 'taking or dropping the ball', but there "
		"can only be one set of noun(s) supplied. So 'taking the ball or taking the bat' "
		"is disallowed. You can get around this by using named actions ('Taking the ball "
		"is being mischievous. Taking the bat is being mischievous. Instead of being "
		"mischievous...'), or it may be less bother just to write more than one rule.");
	Problems::issue_problem_end();

@<Issue PM_APWithNoParticiple problem@> =
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_APWithNoParticiple));
	Problems::issue_problem_segment(
		"You wrote %1, which seems to introduce a rule taking effect only '%2'. But this "
		"does not look like an action, since there is no sign of a participle ending '-ing' "
		"(as in 'taking the brick', say) - which makes me think I have badly misunderstood "
		"what you intended.");
	Problems::issue_problem_end();

@<Issue PM_APWithImmiscible problem@> =
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_APWithImmiscible));
	Problems::issue_problem_segment(
		"You wrote %1, which seems to introduce a rule taking effect only '%2'. But this "
		"is a combination of actions which cannot be mixed. The only alternatives where "
		"'or' is allowed are cases where a choice of actions is given but applying to "
		"the same objects in each case. (So 'taking or dropping the CD' is allowed, but "
		"'dropping the CD or inserting the CD into the jewel box' is not, because the "
		"alternatives there would make different use of objects from each other.)");
	Problems::issue_problem_end();

@<Issue PM_APWithBadWhen problem@> =
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_APWithBadWhen));
	wording Q = rfd->applicability;
	int diagnosis = 0;
	if (<action-when-diagnosis>(Q)) {
		if (<<r>> == 1) Q = GET_RW(<action-when-diagnosis>, 3);
		else Q = GET_RW(<action-when-diagnosis>, 2);
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
		"You wrote %1, which seems to introduce a rule taking effect only '%2'. But this "
		"condition did not make sense, %3");
	if (diagnosis == 1)
		Problems::issue_problem_segment(
			"%PIt might be worth mentioning that a 'when' condition tacked on to "
			"an action like this is not allowed to mention or use 'called' values.");
	if (diagnosis == 4)
		Problems::issue_problem_segment(
			"%PThe problem might be that 'and' has been followed by 'when' or 'while'. "
			"For example, to make a rule with two conditions, this is okay: 'Instead of "
			"jumping when Peter is happy and Peter is in the location'; but the same thing "
			"with '...and when Peter is...' is not allowed.");
	Problems::issue_problem_end();

@<Issue PM_APUnknown problem@> =
	Problems::quote_wording(2, rfd->applicability);
	if (pap_failure_reason == WHENOKAY_PAPF)
		Problems::quote_text(3,
			"The part after 'when' (or 'while') was fine, but the earlier words");
	else Problems::quote_text(3, "But that");
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_APUnknown));
	Problems::issue_problem_segment(
		"You wrote %1, which seems to introduce a rule taking effect only if the action "
		"is '%2'. %3 did not make sense as a description of an action.");
	@<See if it starts with a valid action name, at least@>;
	@<See if this might be a when-for confusion@>;
	@<See if this might be an it-something confusion@>;
	@<Break down the action list and say which are okay@>;
	Problems::issue_problem_segment(
		" I am unable to place this rule into any rulebook.");
	Problems::issue_problem_end();

@<See if it starts with a valid action name, at least@> =
	action_name *an;
	LOOP_OVER(an, action_name)
		if ((Wordings::length(rfd->applicability) <
				Wordings::length(ActionNameNames::tensed(an, IS_TENSE))) &&
			(Wordings::match(rfd->applicability,
				Wordings::truncate(ActionNameNames::tensed(an, IS_TENSE),
					Wordings::length(rfd->applicability))))) {
			Problems::quote_wording(3, ActionNameNames::tensed(an, IS_TENSE));
			Problems::issue_problem_segment(
				" I notice that there's an action called '%3', though: perhaps this is "
				"what you meant?");
			break;
		}

@<See if this might be a when-for confusion@> =
	if (pap_failure_reason == WHENOKAY_PAPF) {
		time_period *duration = Occurrence::parse(rfd->pruned_stem);
		if (duration) {
			Problems::quote_wording(3, Occurrence::used_wording(duration));
			Problems::issue_problem_segment(
				" (I wonder if this might be because '%3', which looks like a condition "
				"on the timing, is the wrong side of the 'when...' clause?)");
		}
	}

@<See if this might be an it-something confusion@> =
	action_name *an;
	LOOP_OVER(an, action_name) {
		wording N = ActionNameNames::tensed(an, IS_TENSE);
		if ((ActionSemantics::max_parameters(an) > 1) &&
			((Wordings::length(rfd->applicability) >= Wordings::length(N)) &&
				(Wordings::match(N,
					Wordings::truncate(rfd->applicability, Wordings::length(N)))))) {
			Problems::quote_wording(3, ActionNameNames::tensed(an, IS_TENSE));
			Problems::issue_problem_segment(
				" (I notice that there's an action called '%3': the 'it' in the name "
				"is meant to be where something is specified about the first thing "
				"it acts on. Try using 'something' rather than 'it'?)");
			break;
		}
	}

@ If the action pattern contains what looks like a list of action names, as for example
"Instead of taking or dropping the magnet: ..." then the <anl-diagnosis> grammar will
 parse this and return N equal to 2, the apparent number of action names. We then
 run the grammar again, but this time allowing it to print comments on each apparent
 action name it sees.

@<Break down the action list and say which are okay@> =
	issuing_ANL_problem = FALSE; NAP_problem_explained = FALSE;
	<anl-diagnosis>(rfd->applicability);
	int N = <<r>>;
	if (N > 1) {
		int positive = TRUE;
		ActionNameLists::parse(rfd->applicability, IS_TENSE, &positive);
		if (positive == FALSE)
			Problems::issue_problem_segment(
				" This looks like a list of actions to avoid: ");
		else
			Problems::issue_problem_segment(
				" Looking at this as a list of alternative actions: ");
		issuing_ANL_problem = TRUE; NAP_problem_explained = FALSE;
		<anl-diagnosis>(rfd->applicability);
		if (defective_ANL_clauses == 0)
			Problems::issue_problem_segment(" but the combination was ambiguous,");
		Problems::issue_problem_segment(" so");
	}

@ We have a much easier time if the rulebook was value-focused, so that
the only possible problem is that the value was wrong.

@<Issue a problem message for a bad parameter@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, rfd->applicability);
	Problems::quote_kind(3, pk);
	<parametric-problem-diagnosis>(rfd->pruned_stem);

@ And that is the end of the code as such, but we still have to define the
three diagnosis grammars we needed.

@ Parametric rules are those applying to values not actions, and the following
is used to choose a problem message if the value makes no sense.

=
<parametric-problem-diagnosis> ::=
	when the play begins/ends |    ==> @<Issue PM_WhenThePlay problem@>
	...                            ==> @<Issue PM_BadParameter problem@>

@<Issue PM_WhenThePlay problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_WhenThePlay),
		"there's no scene called 'the play'",
		"so I think you need to remove 'the' - Inform has two special rulebooks, 'When "
		"play begins' and 'When play ends', and I think you probably mean to refer to "
		"one of those.");

@<Issue PM_BadParameter problem@> =
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_BadParameter));
	Problems::issue_problem_segment(
		"You wrote %1, but the description of the thing(s) to which the rule applies ('%2') "
		"did not make sense. This is %3 based rulebook, so that should have described %3.");
	Problems::issue_problem_end();

@ And here we choose a problem message if a rule applying to an action is used,
but the action isn't one we recognise.

=
<action-problem-diagnosis> ::=
	in the presence of ... |    ==> @<Issue PM_NonActionInPresenceOf problem@>
	in ...                      ==> @<Issue PM_NonActionIn problem@>


@<Issue PM_NonActionInPresenceOf problem@> =
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_NonActionInPresenceOf));
	Problems::issue_problem_segment(
		"You wrote %1, but 'in the presence of...' is a clause which can only be used to "
		"talk about an action: so, for instance, 'waiting in the presence of...' is needed. "
		"This problem arises especially with 'every turn' rules, where 'every turn in the "
		"presence of...' looks plausible but doesn't work. This could be fixed by writing "
		"'Every turn doing something in the presence of...', but a neater solution talks "
		"about the current situation instead: 'Every turn when the player can see...'.");
	Problems::issue_problem_end();

@<Issue PM_NonActionIn problem@> =
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_NonActionIn));
	Problems::issue_problem_segment(
		"You wrote %1, but 'in...' used in this way should really belong to an action: for "
		"instance, 'Before waiting in the Library'. Rules like 'Every turn in the Library' "
		"don't work, because 'every turn' is not an action; what's wanted is 'Every turn "
		"when in the Library'.");
	Problems::issue_problem_end();

@ The following is used to choose a problem when the trouble with the rule
occurred in a when/while condition at the end; while all five cases produce
the PM_APWithBadWhen problem, they each provide different clues as to what
might have gone wrong.

=
<action-when-diagnosis> ::=
	... called ... {when/while ...} |             ==> { 1, - }
	... {when/while *** nothing ***} |            ==> { 2, - }
	... {when/while *** nowhere ***} |            ==> { 3, - }
	... and {when/while ...} |                    ==> { 4, - }
	... {when/while ...}                          ==> { 5, - }

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
	......                                        ==> @<Diagnose problem with this ANL entry@>

@<Diagnose problem with this ANL entry@> =
	if ((issuing_ANL_problem) && (!preform_lookahead_mode)) {
		defective_ANL_clauses++;
		Problems::quote_wording(4, W);
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
		defective_ANL_clauses--;
		Problems::issue_problem_segment("'%4' was okay; ");
	}
	==> { 1, - };

@h Compilation.
The actual compilation of rules is done elsewhere; here we simply make sure
that rule bodies won't be accidentally compiled as if they were phrase bodies.

=
void RuleFamily::compile(imperative_defn_family *self,
	int *total_phrases_compiled, int total_phrases_to_compile) {
	rule *R;
	LOOP_OVER(R, rule) {
		if (R->defn_as_I7_source)
			R->defn_as_I7_source->body_of_defn->compilation_data.
				at_least_one_compiled_form_needed = FALSE;
		Rules::check_constraints_are_typesafe(R);
	}
}

@h Miscellaneous access functions.

=
wording RuleFamily::get_prewhile_text(imperative_defn *id) {
	if (id->family != rule_idf) return EMPTY_WORDING;
	rule_family_data *rfd = RETRIEVE_POINTER_rule_family_data(id->family_specific_data);
	return rfd->prewhile_applicability;
}

int RuleFamily::get_rulebook_placement(imperative_defn *id) {
	if (id->family != rule_idf) return MIDDLE_PLACEMENT;
	rule_family_data *rfd = RETRIEVE_POINTER_rule_family_data(id->family_specific_data);
	return rfd->owning_rulebook_placement;
}

rulebook *RuleFamily::get_rulebook(imperative_defn *id) {
	if (id->family != rule_idf) return NULL;
	rule_family_data *rfd = RETRIEVE_POINTER_rule_family_data(id->family_specific_data);
	return rfd->owning_rulebook;
}

void RuleFamily::set_rulebook(imperative_defn *id, rulebook *rb) {
	if (id->family != rule_idf) internal_error("cannot set rulebook: not a rule");
	rule_family_data *rfd = RETRIEVE_POINTER_rule_family_data(id->family_specific_data);
	rfd->owning_rulebook = rb;
}

int RuleFamily::allows_rule_only(imperative_defn_family *self, imperative_defn *id) {
	return TRUE;
}
