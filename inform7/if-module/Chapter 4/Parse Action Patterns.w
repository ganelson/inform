[ParseActionPatterns::] Parse Action Patterns.

Turning text into APs.

@h Failure reasons.
Action patterns are complicated to parse and text can fail to match for many
different reasons, so that it can be hard to give a helpful problem message if
the author gets it wrong. (We can't simply fire off errors at the time they
occur, because text is often parsed in several contexts at once, so just
because it fails this one does not mean it is wrong.)  To improve our chances,
the code below sets the following global variable on each failure.

@e MISC_PAPF from 1
@e NOPARTICIPLE_PAPF
@e MIXEDNOUNS_PAPF
@e WHEN_PAPF
@e WHENOKAY_PAPF
@e IMMISCIBLE_PAPF

= (early code)
int pap_failure_reason; /* one of the above */

@h Global modes.
The parser is not contextless, and in particular can run in several globally
set modes:

(*) When we |PERMIT_TRYING_OMISSION|, we allow "Ganatus going east" as well as the
more cumbersome "Ganatus trying going east".
(*) When we |FORBID_NONCONSTANT_ACTION_PARAMETERS|, we disallow the use of local
or global variables in action patterns.
(*) When |SCANNING_ANL_ONLY|, we do not perform a full parse, but only enough to
get as far as the action name list.
(*) When we |SUPPRESS_AP_PARSING|, the nonterminal <action-pattern-core> is
rigged always to fail.

@d PERMIT_TRYING_OMISSION                1
@d FORBID_NONCONSTANT_ACTION_PARAMETERS  2
@d SCANNING_ANL_ONLY                     4
@d SUPPRESS_AP_PARSING                   8

=
int parse_action_pattern_mode = 0;

int ParseActionPatterns::enter_mode(int pm) {
	int was = parse_action_pattern_mode;
	parse_action_pattern_mode |= pm;
	return was;
}

int ParseActionPatterns::exit_mode(int pm) {
	int was = parse_action_pattern_mode;
	if (parse_action_pattern_mode & pm)
		parse_action_pattern_mode -= pm;
	return was;
}

void ParseActionPatterns::restore_mode(int saved) {
	parse_action_pattern_mode = saved;
}

@ =
<if-can-omit-trying> internal 0 {
	if (parse_action_pattern_mode & PERMIT_TRYING_OMISSION) return TRUE;
	==> { fail nonterminal };
}

<if-nonconstant-action-context> internal 0 {
	return (parse_action_pattern_mode & FORBID_NONCONSTANT_ACTION_PARAMETERS)?FALSE:TRUE;
}

<s-ap-parameter> ::=
	^<if-nonconstant-action-context> <s-local-variable> |  ==> { fail }
	^<if-nonconstant-action-context> <s-global-variable> | ==> { fail }
	<s-local-variable> |                                   ==> { pass 1 }
	<s-global-variable>	|                                  ==> { pass 1 }
	<s-type-expression-or-value>                           ==> { pass 1 }

@ In addition, the AP parser runs in a current tense. At present, this is
always either |IS_TENSE| or |HASBEEN_TENSE|, but we'll keep our options open:

=
int prevailing_ap_tense = IS_TENSE;
int ParseActionPatterns::change_tense(int tense) {
	int saved = prevailing_ap_tense;
	prevailing_ap_tense = tense;
	return saved;
}
void ParseActionPatterns::restore_tense(int saved) {
	prevailing_ap_tense = saved;
}
int ParseActionPatterns::current_tense(void) {
	return prevailing_ap_tense;
}

@h Extracting only the action name list.
This might seem redundant, since surely we could just parse the text to an AP
in the ordinary way and then take its action list. But going into |SCANNING_ANL_ONLY|
mode enables us to ignore the text used as parameters; which means that we can
get the list even if we are parsing early in Inform's run, when such text may
still be incomprehensible.

=
action_name_list *ParseActionPatterns::list_of_actions_only(wording W, int *anyone) {
	*anyone = FALSE;
	action_name_list *anl = NULL;
	int saved = ParseActionPatterns::enter_mode(PERMIT_TRYING_OMISSION + SCANNING_ANL_ONLY);
	if (<action-pattern>(W)) {
		action_pattern *ap = (action_pattern *) <<rp>>;
		anl = ap->action_list;
		if ((ActionNameLists::nonempty(anl)) && (<<r>> == ACTOR_EXP_UNIVERSAL))
			*anyone = TRUE;
	}
	ParseActionPatterns::restore_mode(saved);
	return anl;
}

@h Level One.
This is where an action pattern is wrapped up as a test of a condition: see
//Action Conditions// for more on this. The nonterminals here have no
return code, and have return value set to the |parse_node| for the condition,
so that they can be used in the S-parser.

There are two forms of this: the first is for contexts where the AP might
occur as a noun ("Taking a jewel is felonious behaviour."). This makes sense
only in the present tense, and no "we are" or "we have" prefixes are allowed.

To see why this case is not like the others at Level One, imagine a story
where there is an action "setting", something called a "meter", and also a
value called the "meter setting".[1] Clearly the text "meter trying setting"
would be unambiguous, but if we allow "trying" to be omitted then there are
two possible readings of "meter setting" as a noun:

(*) the obvious one to a human reader, i.e., the value of the meter setting;
(*) the action in which the meter is performing a setting.

We reject the second option only by testing the actor to make sure it is a
person: for something inanimate like the meter, it is not.

[1] If that's too much of a stretch for the imagination, see the documentation
example "Witnessed 2", test case |Witnessed|.

=
<s-action-pattern-as-value> internal {
	if (Wordings::mismatched_brackets(W)) { ==> { fail nonterminal }; }
	if (Lexer::word(Wordings::first_wn(W)) == OPENBRACE_V) { ==> { fail nonterminal }; }
	int saved = ParseActionPatterns::enter_mode(0);
	ParseActionPatterns::enter_mode(PERMIT_TRYING_OMISSION);
	action_pattern *ap = NULL;
	if (<action-pattern>(W)) {
		ap = <<rp>>;
		parse_node *supposed_actor = APClauses::spec(ap, ACTOR_AP_CLAUSE);
		if ((supposed_actor) &&
			(Dash::validate_parameter(supposed_actor, K_person) == FALSE)) {
			ParseActionPatterns::exit_mode(PERMIT_TRYING_OMISSION);
			if (<action-pattern>(W)) ap = <<rp>>; else ap = NULL;
		}
	}
	ParseActionPatterns::restore_mode(saved);
	if (ap) {
		==> { -, AConditions::new_action_TEST_VALUE(ap, W) };
		return TRUE;
	}
	==> { fail nonterminal };
}

@ The second form is for contexts where the AP occurs as a condition: e.g.,
in a sentence like "if we have taken a jewel". Since these can occur in
both tenses and can be negated ("if we are not taking a jewel"), there are
four combinations.

=
<s-action-pattern-as-condition> ::=
	<we-are-action-pattern>       ==> { -, AConditions::new_action_TEST_VALUE(RP[1], W) }

<s-action-pattern-as-negated-condition> ::=
	<action-pattern-negated>      ==> { -, AConditions::new_action_TEST_VALUE(RP[1], W) }

<s-past-action-pattern-as-condition> ::=
	<action-pattern-past>         ==> { -, AConditions::new_past_action_TEST_VALUE(RP[1], W) }

<s-past-action-pattern-as-negated-condition> ::=
	<action-pattern-past-negated> ==> { -, AConditions::new_past_action_TEST_VALUE(RP[1], W) }

@h Level Two.
The five s-nonterminals of Level One hand decisions down to five corresponding
nonterminals here. For each of these, the return code is one of the following
five values, and the return pointer is the //action_pattern// structure made.
Our aim here is to determine who will perform the action.

@d ACTOR_REQUESTED 0
@d ACTOR_NAMED 1
@d ACTOR_EXP_UNIVERSAL 2
@d ACTOR_EXP_PLAYER 3
@d ACTOR_IMP_PLAYER 4

=
<action-pattern> ::=
	asking <s-ap-parameter> to try <ap-three-present> |            ==> @<Someone requested@>
	<s-ap-parameter> trying <ap-three-present> |                   ==> @<Someone specific@>
	an actor trying <ap-three-present> |                           ==> @<Anyone except the player@>
	an actor <ap-three-present> |                                  ==> @<Anyone except the player@>
	trying <ap-three-present> |                                    ==> { ACTOR_EXP_PLAYER, RP[1] };
	<ap-three-present> |                                           ==> { ACTOR_IMP_PLAYER, RP[1] };
	<actor-description> <ap-three-present>                         ==> @<Someone specific@>

<we-are-action-pattern> ::=
	we are asking <s-ap-parameter> to try <ap-three-present> |     ==> @<Someone requested@>
	asking <s-ap-parameter> to try <ap-three-present> |            ==> @<Someone requested@>
	<s-ap-parameter> trying <ap-three-present> |                   ==> @<Someone specific@>
	an actor trying <ap-three-present> |                           ==> @<Anyone except the player@>
	an actor <ap-three-present> |                                  ==> @<Anyone except the player@>
	we are trying <ap-three-present> |                             ==> { ACTOR_EXP_PLAYER, RP[1] };
	trying <ap-three-present> |                                    ==> { ACTOR_EXP_PLAYER, RP[1] };
	we are <ap-three-present> |                                    ==> { ACTOR_EXP_PLAYER, RP[1] };
	<ap-three-present> |                                           ==> { ACTOR_IMP_PLAYER, RP[1] };
	<actor-description> <ap-three-present>                         ==> @<Someone specific@>

<action-pattern-negated> ::=
	we are not asking <s-ap-parameter> to try <ap-three-present> | ==> @<Someone requested@>
	not asking <s-ap-parameter> to try <ap-three-present> |        ==> @<Someone requested@>
	<s-ap-parameter> not trying <ap-three-present> |               ==> @<Someone specific@>
	an actor not trying <ap-three-present> |                       ==> @<Anyone except the player@>
	an actor not <ap-three-present> |                              ==> @<Anyone except the player@>
	we are not trying <ap-three-present> |                         ==> { ACTOR_EXP_PLAYER, RP[1] };
	not trying <ap-three-present> |                                ==> { ACTOR_EXP_PLAYER, RP[1] };
	we are not <ap-three-present> |                                ==> { ACTOR_EXP_PLAYER, RP[1] };
	not <ap-three-present> |                                       ==> { ACTOR_IMP_PLAYER, RP[1] };
	not <actor-description> <ap-three-present>                     ==> @<Someone specific@>

<action-pattern-past> ::=
	we have asked <s-ap-parameter> to try <ap-three-present> |     ==> @<Someone requested@>
	<s-ap-parameter> has tried <ap-three-present> |                ==> @<Someone specific@>
	an actor has tried <ap-three-present> |                        ==> @<Anyone except the player@>
	an actor has <ap-three-past> |                                 ==> @<Anyone except the player@>
	we have tried <ap-three-present> |                             ==> { ACTOR_EXP_PLAYER, RP[1] };
	we have <ap-three-past>                                        ==> { ACTOR_EXP_PLAYER, RP[1] };

<action-pattern-past-negated> ::=
	we have not asked <s-ap-parameter> to try <ap-three-present> | ==> @<Someone requested@>
	<s-ap-parameter> has not tried <ap-three-present> |            ==> @<Someone specific@>
	an actor has not tried <ap-three-present> |                    ==> @<Anyone except the player@>
	an actor has not <ap-three-past> |                             ==> @<Anyone except the player@>
	we have not tried <ap-three-present> |                         ==> { ACTOR_EXP_PLAYER, RP[1] };
	we have not <ap-three-past>                                    ==> { ACTOR_EXP_PLAYER, RP[1] };

@<Someone requested@> =
	action_pattern *ap = RP[2];
	APClauses::set_request(ap); APClauses::set_spec(ap, ACTOR_AP_CLAUSE, RP[1]);
	==> { ACTOR_REQUESTED, ap };

@<Someone specific@> =
	action_pattern *ap = RP[2];
	APClauses::clear_request(ap); APClauses::set_spec(ap, ACTOR_AP_CLAUSE, RP[1]);
	==> { ACTOR_NAMED, ap };

@<Anyone except the player@> =
	action_pattern *ap = RP[1]; APClauses::make_actor_anyone_except_player(ap);
	==> { ACTOR_EXP_UNIVERSAL, ap };

@ Note that the three present-tense cases all allow the abbreviated form
"Raffles taking a jewel" rather than the less likely to be ambiguous "Raffles
trying taking a jewel". This is allowed only in |PERMIT_TRYING_OMISSION| mode,
and makes use of the following voracious nonterminal to match the actor's
name -- here, just "Raffles".

The following tries to break just before any "-ing" word (i.e., participle)
which is not inside parentheses; but only if the resulting name matches
<s-ap-parameter> as a constant, variable, or description; and there is no
match if the text is the name of an instance but the "-ing" word could also be
read as part of that same name. For example, if we read the text

>> angry waiting man taking the fish

where "angry waiting man" is the name of an individual person, then we don't
break this after "angry" (with the action "waiting") even though "angry"
would match as an abbreviated form of the name of "angry waiting man".

=
<actor-description> internal ? {
	if (parse_action_pattern_mode & PERMIT_TRYING_OMISSION) {
		int bl = 0;
		LOOP_THROUGH_WORDING(i, W)
			if (i > Wordings::first_wn(W)) {
				if (Lexer::word(i) == OPENBRACKET_V) bl++;
				if (Lexer::word(i) == CLOSEBRACKET_V) bl--;
				if ((bl == 0) && (<probable-participle>(Wordings::one_word(i)))) {
					if (<k-kind>(Wordings::up_to(W, i-1))) continue;
					parse_node *try_stem = NULL;
					instance *I;
					int old_state = ParseActionPatterns::enter_mode(SUPPRESS_AP_PARSING);
					if (<s-ap-parameter>(Wordings::up_to(W, i-1))) try_stem = <<rp>>;
					ParseActionPatterns::restore_mode(old_state);
					int k = 0;
					LOOP_THROUGH_WORDING(j, Wordings::up_to(W, i-1))
						if (Vocabulary::test_flags(j, ACTION_PARTICIPLE_MC)) k++;
					if (k>0) continue;
					I = Rvalues::to_object_instance(try_stem);
					if (I) {
						noun *N = Instances::get_noun(I);
						if (Nouns::nominative_singular_includes(N, Lexer::word(i))) continue;
					}
					if ((Lvalues::get_storage_form(try_stem) == LOCAL_VARIABLE_NT) ||
						(Lvalues::get_storage_form(try_stem) == NONLOCAL_VARIABLE_NT) ||
						(Node::is(try_stem, CONSTANT_NT)) ||
						(Specifications::is_description(try_stem))) {
						==> { -, try_stem };
						return i-1;
					}
				}
			}
	}
	return 0;
}

@h Level Three.
We can forget about actors, and the above five cases reduce to only two, one
for each tense we support.

=
<ap-three-present> internal {
	if (parse_action_pattern_mode & SUPPRESS_AP_PARSING) return FALSE;
	int saved = ParseActionPatterns::change_tense(IS_TENSE);
	action_pattern *ap = ParseActionPatterns::level_three(W);
	ParseActionPatterns::restore_tense(saved);
	if (ap) { ==> { -, ap }; return TRUE; }
	==> { fail nonterminal };
}

<ap-three-past> internal {
	if (parse_action_pattern_mode & SUPPRESS_AP_PARSING) return FALSE;
	int saved = ParseActionPatterns::change_tense(HASBEEN_TENSE);
	action_pattern *ap = ParseActionPatterns::level_three(W);
	ParseActionPatterns::restore_tense(saved);
	if (ap) { ==> { -, ap }; return TRUE; }
	==> { fail nonterminal };
}

@ Other than merging the tenses into one code path, all we do at this level
is to look for any indication of duration. For example, "taking the box for the
third time" has "for the third time" trimmed away, and "taking the box" is
what passes down to Level Four.

=
action_pattern *ParseActionPatterns::level_three(wording W) {
	@<There has to be a participle here somewhere@>;
	LOGIF(ACTION_PATTERN_PARSING, "Parse action pattern (tense %d): %W\n",
		ParseActionPatterns::current_tense(), W);
	time_period *duration = Occurrence::parse(W);
	if (duration) W = Occurrence::unused_wording(duration);
	pap_failure_reason = MISC_PAPF;
	action_pattern *ap = ParseActionPatterns::level_four(W);
	if (ap) ap->duration = duration;
	LOGIF(ACTION_PATTERN_PARSING, "PAP result (pfr %d): $A\n", pap_failure_reason, ap);
	return ap;
}

@ This saves a huge amount of time, since virtually any text gets through Levels
One and Two down to here. "Lady Eustace's Diamonds" cannot be an action pattern
since it contains no words which are part of an action (or named action pattern)
name; so we needn't spend any further time.

@<There has to be a participle here somewhere@> =
	if (Wordings::empty(W)) internal_error("PAP on illegal word range");
	if (Lexer::word(Wordings::first_wn(W)) == OPENBRACE_V) return NULL;
	unsigned int d = Vocabulary::disjunction_of_flags(W);
	if (((ParseActionPatterns::current_tense() == IS_TENSE) &&
		((d & (ACTION_PARTICIPLE_MC+NAMED_AP_MC)) == 0))) {
		pap_failure_reason = NOPARTICIPLE_PAPF;
		return NULL;
	}

@h Level Four.
This level deals only with the pronominal action "doing it", an anaphora which
refers by implication to whatever action pattern was previously discussed before
this one. Parsing this accurately is a fool's errand, and allowing this syntax
in Inform was not a good idea, because the potential for confusion is too great.
That said, it does enable, for example, the cool rule:

>> Instead of Raffles taking the box for the second time, try Bunny doing it.

=
<ap-four-pronominal> ::=
	doing it

@ =
wording pronominal_action_wording = EMPTY_WORDING_INIT;

action_pattern *ParseActionPatterns::level_four(wording W) {
	if (<ap-four-pronominal>(W)) {
		if (Wordings::nonempty(pronominal_action_wording)) {
			LOGIF(ACTION_PATTERN_PARSING, "Pronominal is %W\n", W);
			if (<ap-five>(pronominal_action_wording)) return <<rp>>;
		}
	} else {
		if (<ap-five>(W)) {
			pronominal_action_wording = W;
			LOGIF(ACTION_PATTERN_PARSING, "Set pronominal to: %W\n", W);
			return <<rp>>;
		}
	}
	return NULL;
}

@h Lark's Tongues in Aspic, Part V.
Down here at Level Five, everything has funnelled into a single nonterminal.
Its task is to recognise a condition attached with "when", which goes into a
special clause of its own.

=
<ap-five> ::=
	<ap-six> when/while <ap-five-condition> | ==> @<Succeed with when okay@>;
	<ap-six> |                                ==> { pass 1 };
	... when/while <ap-five-condition> |      ==> @<Fail with when okay@>;
	... when/while ...                        ==> @<Fail with when not okay@>;
	
@<Succeed with when okay@> =
	action_pattern *ap = RP[1]; APClauses::set_spec(ap, WHEN_AP_CLAUSE, RP[2]);
	if (pap_failure_reason == MISC_PAPF) pap_failure_reason = WHENOKAY_PAPF;
	==> { -, ap };

@<Fail with when okay@> =
	pap_failure_reason = WHENOKAY_PAPF;
	return FALSE;

@<Fail with when not okay@> =
	if (pap_failure_reason != WHENOKAY_PAPF) pap_failure_reason = WHEN_PAPF;
	return FALSE;

@ <ap-five-condition> is really just <s-condition> in disguise -- i.e.,
it matches a standard Inform condition -- but it's implemented as an internal
to enable Inform to set up a stack frame if there isn't one already, and so on.

=
<ap-five-condition> internal {
	stack_frame *phsf = NULL;
	if (Frames::current_stack_frame() == NULL) phsf = Frames::new_nonphrasal();
	SharedVariables::append_access_list(
		Frames::get_shared_variable_access_list(), all_nonempty_stacked_action_vars);
	LOGIF(ACTION_PATTERN_PARSING, "A when clause <%W> is suspected.\n", W);
	parse_node *when_cond = NULL;
	int s = pap_failure_reason;
	int saved = ParseActionPatterns::exit_mode(PERMIT_TRYING_OMISSION);
	if (<s-condition>(W)) when_cond = <<rp>>;
	pap_failure_reason = s;
	ParseActionPatterns::restore_mode(saved);
	if (phsf) Frames::remove_nonphrase_stack_frame();
	if ((when_cond) && (Dash::validate_conditional_clause(when_cond))) {
		LOGIF(ACTION_PATTERN_PARSING, "When clause validated: $P.\n", when_cond);
		==> { -, when_cond };
		return TRUE;
	}
	==> { fail nonterminal };
}

@h Level Six.
Much of the complexity is gone now, but much potential ambiguity remains, and
so what's left can't very efficiently be written in Preform.

=
<ap-six> internal {
	if (Wordings::mismatched_brackets(W)) { ==> { fail nonterminal }; }
	if (parse_action_pattern_mode & SCANNING_ANL_ONLY) {
		action_name_list *list = ActionNameLists::parse(W, prevailing_ap_tense, NULL);
		if (list == NULL) { ==> { fail nonterminal }; }
		action_pattern *ap = ActionPatterns::new(W);
		ap->action_list = list;
		==> { -, ap };
		return TRUE;
	} else {
		LOGIF(ACTION_PATTERN_PARSING, "Parsing action pattern: %W\n", W);
		LOG_INDENT;
		action_pattern *ap = ParseClauses::ap_seven(W);
		LOGIF(ACTION_PATTERN_PARSING, "Level Seven on %W gives $A\n", W, ap);
		LOG_OUTDENT;
		if (ap) { ==> { -, ap }; return TRUE; }
	}
	==> { fail nonterminal };
}
