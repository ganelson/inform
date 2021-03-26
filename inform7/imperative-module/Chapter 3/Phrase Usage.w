[Phrases::Usage::] Phrase Usage.

To parse the preamble of a phrase declaration to a phrase usage
(PHUD) structure containing a mostly textual representation of the
conditions for its usage.

@ And here is the usage data.

=
typedef struct ph_usage_data {
	struct imperative_defn *from;
	struct wording full_preamble; /* e.g. to identify nameless rules in the log */
	struct constant_phrase *constant_phrase_holder; /* for named To... phrases */
	int to_begin; /* used in Basic mode only: this is to be the main phrase */
	int timing_of_event; /* one of two values defined below; or a specific time */
	struct use_as_event *uses_as_event;
	struct wording explicit_name; /* if a named rule, this is its name */
	int explicit_name_used_in_maths; /* if so, this flag means it's like |log()| or |sin()| */
	struct wording explicit_name_for_inverse; /* e.g. |exp| for |log| */
	struct wording whenwhile; /* when/while for action/activity rulebooks */
	struct wording rule_preamble;
	struct wording rule_parameter; /* text of object or action parameter */
	#ifdef IF_MODULE
	struct parse_node *during_scene_spec; /* what scene is currently under way */
	#endif
	struct wording event_name;
	struct rulebook *owning_rulebook; /* the primary booking for the phrase will be here */
	int owning_rulebook_placement; /* ...and with this placement value: see Rulebooks */
} ph_usage_data;

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
rule *Phrases::Usage::to_rule(ph_usage_data *phud, imperative_defn *id) {
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
	if (Wordings::nonempty(phud->event_name)) {
		W = Articles::remove_the(phud->event_name);
	} else if (Wordings::nonempty(phud->explicit_name)) {
		W = Articles::remove_the(phud->explicit_name);
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
	wording IX = phud->rule_parameter;
	if (Wordings::nonempty(phud->whenwhile)) {
		if (Wordings::first_wn(phud->whenwhile) == Wordings::last_wn(phud->rule_parameter) + 1) {
			IX = Wordings::new(Wordings::first_wn(phud->rule_parameter), Wordings::last_wn(phud->whenwhile));
		} else {
			IX = phud->whenwhile;
		}
	}
	IXRules::set_italicised_index_text(R, IX);

@h Parsing.

=
ph_usage_data Phrases::Usage::new(wording W, imperative_defn *id) {
	ph_usage_data phud;
	@<Empty the PHUD@>;

	if (id->family == TO_PHRASE_EFF_family) { ToPhraseFamily::phud(id, &phud); return phud; }
	if (id->family == RULE_EFF_family) { RuleFamily::phud(id, &phud); return phud; }

	return phud;
}

@<Empty the PHUD@> =
	phud.full_preamble = W;
	phud.constant_phrase_holder = NULL;
	phud.from = id;
	phud.explicit_name = EMPTY_WORDING;
	phud.explicit_name_used_in_maths = FALSE;
	phud.rule_preamble = EMPTY_WORDING;
	phud.rule_parameter = EMPTY_WORDING;
	phud.whenwhile = EMPTY_WORDING;
	phud.to_begin = FALSE;
	#ifdef IF_MODULE
	phud.during_scene_spec = NULL;
	#endif
	phud.event_name = EMPTY_WORDING;
	phud.timing_of_event = NOT_A_TIMED_EVENT;
	phud.uses_as_event = NULL;
	phud.owning_rulebook = NULL;
	phud.owning_rulebook_placement = MIDDLE_PLACEMENT;
	phud.explicit_name_for_inverse = EMPTY_WORDING;

@h Extracting the stem.
A couple of routines to read but not really parse the stem and the bud.

=
wording Phrases::Usage::get_preamble_text(ph_usage_data *phud) {
	if (phud->from->family == TO_PHRASE_EFF_family) return phud->rule_preamble;
	return phud->full_preamble;
}

@ For example, for the rule

>> Instead of taking the box while the skylight is open: ...

this returns "taking the box".

=
wording Phrases::Usage::get_prewhile_text(ph_usage_data *phud) {
	if (Wordings::nonempty(phud->rule_parameter)) {
		wording E = phud->rule_parameter;
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
int Phrases::Usage::get_rulebook_placement(ph_usage_data *phud) {
	return phud->owning_rulebook_placement;
}

rulebook *Phrases::Usage::get_rulebook(ph_usage_data *phud) {
	return phud->owning_rulebook;
}

void Phrases::Usage::set_rulebook(ph_usage_data *phud, rulebook *rb) {
	phud->owning_rulebook = rb;

}

int Phrases::Usage::get_timing_of_event(ph_usage_data *phud) {
	return phud->timing_of_event;
}

int Phrases::Usage::has_name_as_constant(ph_usage_data *phud) {
	if ((phud->constant_phrase_holder) &&
		(phud->explicit_name_used_in_maths == FALSE) &&
		(Wordings::nonempty(Nouns::nominative_singular(phud->constant_phrase_holder->name)))) return TRUE;
	return FALSE;
}

wording Phrases::Usage::get_equation_form(ph_usage_data *phud) {
	if (phud->explicit_name_used_in_maths)
		return Wordings::first_word(Nouns::nominative_singular(phud->constant_phrase_holder->name));
	return EMPTY_WORDING;
}

phrase *Phrases::Usage::get_equation_inverse(ph_usage_data *phud) {
	if (Wordings::nonempty(phud->explicit_name_for_inverse)) {
		phrase *ph;
		LOOP_OVER(ph, phrase) {
			wording W = Phrases::Usage::get_equation_form(&(ph->usage_data));
			if (Wordings::nonempty(W))
				if (Wordings::match(W, phud->explicit_name_for_inverse))
					return ph;
		}
	}
	return NULL;
}

@h Logging and indexing.
The length and thoroughness of this may give some hint of how troublesome
it was to debug the preamble-parsing code:

=
void Phrases::Usage::log(ph_usage_data *phud) {
	LOG("PHUD: <%W>: rule attachment mode %S\n", phud->full_preamble, phud->from->family->family_name);
	if (phud->constant_phrase_holder)
		LOG("  Constant name: <%W>\n", Nouns::nominative_singular(phud->constant_phrase_holder->name));
	if (Wordings::nonempty(phud->explicit_name))
		LOG("  Explicit name: <%W>\n", phud->explicit_name);
	if (phud->explicit_name_used_in_maths)
		LOG("  Used functionally in equations\n");
	if (Wordings::nonempty(phud->rule_preamble))
		LOG("  Rule preamble: <%W>\n", phud->rule_preamble);
	if (Wordings::nonempty(phud->rule_parameter))
		LOG("  Rule parameter: <%W>\n", phud->rule_parameter);
	if (Wordings::nonempty(phud->whenwhile))
		LOG("  When/while text: <%W>\n", phud->whenwhile);
	if (Wordings::nonempty(phud->event_name))
		LOG("  Event name: <%W>\n", phud->event_name);
	if (phud->timing_of_event != NOT_A_TIMED_EVENT)
		LOG("  Timed event: at %d\n", phud->timing_of_event);
	#ifdef IF_MODULE
	if (phud->during_scene_spec)
		LOG("  During scene: <$P>\n", phud->during_scene_spec);
	#endif
	if (phud->owning_rulebook) {
		char *place = "<UNKNOWN_NT>";
		LOG("  Owned by rulebook: ");
		Rulebooks::log_name_only(phud->owning_rulebook);
		switch(phud->owning_rulebook_placement) {
			case MIDDLE_PLACEMENT: place = "MIDDLE_PLACEMENT"; break;
			case FIRST_PLACEMENT: place = "FIRST_PLACEMENT"; break;
			case LAST_PLACEMENT: place = "LAST_PLACEMENT"; break;
		}
		LOG("\n  Placement: %s\n", place);
	}
}

void Phrases::Usage::log_rule_name(ph_usage_data *phud) {
	if (Wordings::empty(phud->explicit_name)) {
		if (Wordings::nonempty(phud->full_preamble))
			LOG("\"%W\"", phud->full_preamble);
		else LOG("(nameless)");
	} else LOG("(%W)", phud->explicit_name);
}

@ In our compiled code, it's useful to label routines with I6 comments:

=
void Phrases::Usage::write_I6_comment_describing(ph_usage_data *phud) {
	TEMPORARY_TEXT(C)
	WRITE_TO(C, "%~W:", phud->full_preamble);
	Produce::comment(Emit::tree(), C);
	DISCARD_TEXT(C)
}

@ And similarly:

=
void Phrases::Usage::index_preamble(OUTPUT_STREAM, ph_usage_data *phud) {
	WRITE("%+W", phud->full_preamble);
}

@h How the PHUD translates into a PHRCD.
Recall that in the early afternoon, the PHUD for a rule phrase is translated
into a PHRCD, that is, a set of instructions about the circumstances for
the rule to fire.

As will be seen, about six-sevenths of the code is given over to choosing good
problem messages when the PHUD is malformed -- these are some of the most
seen problems in Inform. A couple of variables are needed just for that:

=
int NAP_problem_explained = FALSE; /* pertains to Named Action Patterns */
int issuing_ANL_problem = FALSE; /* pertains to Action Name Lists */

@ =
ph_runtime_context_data Phrases::Usage::to_runtime_context_data(ph_usage_data *phud) {
	ph_runtime_context_data phrcd = Phrases::Context::new();

	if (RuleFamily::is(phud->from)) {
		if (RuleFamily::not_in_rulebook(phud->from))
			phrcd.permit_all_outcomes = TRUE;
		else
			@<Finish work parsing the conditions for the rule to fire@>;
	}
	return phrcd;
}

@ All of this is just dumb copying...

@<Finish work parsing the conditions for the rule to fire@> =
	phrcd.compile_for_rulebook = &(phud->owning_rulebook);

	if (Wordings::nonempty(phud->rule_parameter)) @<Parse what used to be the bud into the PHRCD@>;

	if (Wordings::nonempty(phud->whenwhile)) {
		phrcd.activity_context =
			Wordings::new(
				Wordings::first_wn(phud->whenwhile) + 1,
				Wordings::last_wn(phud->whenwhile));
		phrcd.activity_where = current_sentence;
	}

	#ifdef IF_MODULE
	if (phud->during_scene_spec) phrcd.during_scene = phud->during_scene_spec;
	#endif

@ ...except for this:

@<Parse what used to be the bud into the PHRCD@> =
	#ifdef IF_MODULE
	if (Rulebooks::action_focus(phud->owning_rulebook)) {
		int saved = ParseActionPatterns::enter_mode(PERMIT_TRYING_OMISSION);
		if (Rules::all_action_processing_variables())
			Frames::set_stvol(
				Frames::current_stack_frame(), Rules::all_action_processing_variables());
		if (<action-pattern>(phud->rule_parameter)) phrcd.ap = <<rp>>;
		Frames::remove_nonphrase_stack_frame();
		ParseActionPatterns::restore_mode(saved);

		if (phrcd.ap == NULL)
			@<Issue a problem message for a bad action@>;
	} else {
		kind *pk = Rulebooks::get_focus_kind(phud->owning_rulebook);
		phrcd.ap = ActionPatterns::parse_parametric(phud->rule_parameter, pk);
		if (phrcd.ap == NULL) {
			if (Wordings::nonempty(phud->whenwhile)) {
				wording F = Wordings::up_to(phud->rule_parameter, Wordings::last_wn(phud->whenwhile));
				phrcd.ap = ActionPatterns::parse_parametric(F, pk);
				if (phrcd.ap) {
					phud->rule_parameter = F;
					phud->whenwhile = EMPTY_WORDING;
				}
			}
		}
		if (phrcd.ap == NULL) @<Issue a problem message for a bad parameter@>;
	}
	#endif
	#ifndef IF_MODULE
	kind *pk = Rulebooks::get_focus_kind(phud->owning_rulebook);
	@<Issue a problem message for a bad parameter@>;
	#endif

@ All that's left is to issue a "good" problem message, but this is quite
a large undertaking, because the situation as we currently know it is just
that something's wrong with the rule preamble -- which covers an enormous
range of different faults.

The "PAP failure reason" is a sort of error code set by the action pattern
parser, recording how it most recently failed.

@<Issue a problem message for a bad action@> =
	Phrases::Usage::log(phud);
	LOG("Bad action pattern: %W = $A\nPAP failure reason: %d\n",
		phud->rule_parameter, phrcd.ap, pap_failure_reason);
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, phud->rule_parameter);
	if (<action-problem-diagnosis>(phud->rule_parameter) == FALSE)
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
	wording Q = phud->rule_parameter;
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
	Problems::quote_wording(2, phud->rule_parameter);
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
		if ((Wordings::length(phud->rule_parameter) < Wordings::length(ActionNameNames::tensed(an, IS_TENSE))) &&
			(Wordings::match(phud->rule_parameter,
				Wordings::truncate(ActionNameNames::tensed(an, IS_TENSE), Wordings::length(phud->rule_parameter))))) {
			Problems::quote_wording(3, ActionNameNames::tensed(an, IS_TENSE));
			Problems::issue_problem_segment(
				" I notice that there's an action called '%3', though: perhaps "
				"this is what you meant?");
			break;
		}

@<See if this might be a when-for confusion@> =
	if (pap_failure_reason == WHENOKAY_PAPF) {
		time_period *duration = Occurrence::parse(phud->rule_preamble);
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
	<anl-diagnosis>(phud->rule_parameter);
	int N = <<r>>;
	if (N > 1) {
		int positive = TRUE;
		ActionNameLists::parse(phud->rule_parameter, IS_TENSE, &positive);
		if (positive == FALSE)
			Problems::issue_problem_segment(
				" This looks like a list of actions to avoid: ");
		else
			Problems::issue_problem_segment(
				" Looking at this as a list of alternative actions: ");
		issuing_ANL_problem = TRUE; NAP_problem_explained = FALSE;
		<anl-diagnosis>(phud->rule_parameter);
		Problems::issue_problem_segment(" so");
	}

@ We have a much easier time if the rulebook was value-focused, so that
the only possible problem is that the value was wrong.

@<Issue a problem message for a bad parameter@> =
	Phrases::Usage::log(phud);
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, phud->rule_parameter);
	Problems::quote_kind(3, pk);
	<parametric-problem-diagnosis>(phud->rule_preamble);

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
