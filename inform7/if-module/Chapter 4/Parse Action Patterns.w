[ParseActionPatterns::] Parse Action Patterns.

Turning text into APs.

@ First a much easier, parametric form of parsing, used for the APs which
form the usage conditions for rules in object-based rulebooks.

=
action_pattern ParseActionPatterns::parametric(wording W, kind *K) {
	action_pattern ap = ActionPatterns::new();
	ap.parameter_spec = ParseActionPatterns::parameter(W);
	ap.parameter_kind = K;
	ap.valid = Dash::validate_parameter(ap.parameter_spec, K);
	return ap;
}

@ A useful utility: parsing a parameter in an action pattern.

=
parse_node *ParseActionPatterns::parameter(wording W) {
	if (<action-parameter>(W)) return <<rp>>;
	return Specifications::new_UNKNOWN(W);
}

parse_node *ParseActionPatterns::verified_action_parameter(wording W) {
	parse_node *spec = ParseActionPatterns::parameter(W);
	if (Node::is(spec, UNKNOWN_NT)) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, W);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_BadOptionalAPClause));
		Problems::issue_problem_segment(
			"In %1, I tried to read a description of an action - a complicated "
			"one involving optional clauses; but '%2' wasn't something I "
			"recognised.");
		Problems::issue_problem_end();
	}
	return spec;
}

@ =
int scanning_anl_only_mode = FALSE;
action_name_list *ParseActionPatterns::list_of_actions_only(wording W, int *anyone) {
	*anyone = FALSE;
	action_name_list *anl = NULL;
	int s = scanning_anl_only_mode;
	scanning_anl_only_mode = TRUE;
	int s2 = permit_trying_omission;
	permit_trying_omission = TRUE;
	if (<action-pattern>(W)) {
		anl = ActionPatterns::list(<<rp>>);
		if ((anl) && (anl->entries)) {
			if (<<r>> == ACTOR_EXPLICITLY_UNIVERSAL)
				*anyone = TRUE;
		}
	}
	scanning_anl_only_mode = s;
	permit_trying_omission = s2;
	return anl;
}

@ The main action pattern parser is called only by the following shell
routine, which exists in order to change some parsing rules.

Match "doing it" as a repetition of the previous successfully
matched action pattern.

=
int suppress_ap_parsing = FALSE;
wording last_successful_wording = EMPTY_WORDING_INIT;
int prevailing_ap_tense = IS_TENSE;


@ In fact these codes aren't used any more:

@d ACTOR_REQUESTED 0
@d ACTOR_NAMED 1
@d ACTOR_EXPLICITLY_UNIVERSAL 2
@d ACTOR_EXPLICITLY_PLAYER 3
@d ACTOR_IMPLICITLY_PLAYER 4

@ Action patterns are textual descriptions which act as predicates on actions,
that is, they are descriptions which are true of some actions and false of
others. For example,

>> taking something in a dark room

won't be true of taking the ball in the Beach, or of dropping the torch in the
Cellars. Although precisely described actions are valid as APs:

>> taking the beach ball

(which is true for this one action and false for all others), APs can be both
more general -- as above -- and even more specific:

>> taking the beach ball in the presence of a lifeguard

...which might not be true even if the current action is "taking the beach
ball".

APs can be very flexible and have the most complicated syntax in Inform. It's
not practical to make the Preform grammar as explicit as one might like, but
we'll do our best. The top level establishes who the actor will be, and whether
it is an actual action or merely a request to perform the action. There are
two versions of this: the first is for contexts where the AP might occur as
a noun (e.g., in a sentence like "Taking a jewel is felonious behaviour.").
These are always present tense, and can't be negated.

=
<action-pattern> ::=
	asking <action-parameter> to try <action-pattern-core> |    ==> { ACTOR_REQUESTED, RP[2] }; action_pattern *ap = *XP; ap->request = TRUE; APClauses::set_actor(ap, RP[1]);
	<action-parameter> trying <action-pattern-core> |    ==> { ACTOR_NAMED, RP[2] }; ap = *XP; ap->request = FALSE; APClauses::set_actor(ap, RP[1]);
	an actor trying <action-pattern-core> |    ==> { ACTOR_EXPLICITLY_UNIVERSAL, RP[1] }; ap = *XP; ap->applies_to_any_actor = TRUE;
	an actor <action-pattern-core> |    ==> { ACTOR_EXPLICITLY_UNIVERSAL, RP[1] }; ap = *XP; ap->applies_to_any_actor = TRUE;
	trying <action-pattern-core> |    ==> { ACTOR_EXPLICITLY_PLAYER, RP[1] };
	<action-pattern-core-actor>															==> { ACTOR_IMPLICITLY_PLAYER, RP[1] };

@ The second version is for contexts where the AP occurs as a condition: e.g.,
in a sentence like "if we have taken a jewel". Since these can occur in
both tenses and can be negated ("if we are not taking a jewel"), there are
four combinations:

=
<we-are-action-pattern> ::=
	we are asking <action-parameter> to try <action-pattern-core> |    ==> { ACTOR_REQUESTED, RP[2] }; action_pattern *ap = *XP; ap->request = TRUE; APClauses::set_actor(ap, RP[1]);
	asking <action-parameter> to try <action-pattern-core> |    ==> { ACTOR_REQUESTED, RP[2] }; ap = *XP; ap->request = TRUE; APClauses::set_actor(ap, RP[1]);
	<action-parameter> trying <action-pattern-core> |    ==> { ACTOR_NAMED, RP[2] }; ap = *XP; ap->request = FALSE; APClauses::set_actor(ap, RP[1]);
	an actor trying <action-pattern-core> |    ==> { ACTOR_EXPLICITLY_UNIVERSAL, RP[1] }; ap = *XP; ap->applies_to_any_actor = TRUE;
	an actor <action-pattern-core> |    ==> { ACTOR_EXPLICITLY_UNIVERSAL, RP[1] }; ap = *XP; ap->applies_to_any_actor = TRUE;
	we are trying <action-pattern-core> |    ==> { ACTOR_EXPLICITLY_PLAYER, RP[1] };
	trying <action-pattern-core> |    ==> { ACTOR_EXPLICITLY_PLAYER, RP[1] };
	we are <action-pattern-core> |    ==> { ACTOR_EXPLICITLY_PLAYER, RP[1] };
	<action-pattern-core-actor>															==> { ACTOR_IMPLICITLY_PLAYER, RP[1] };

<action-pattern-negated> ::=
	we are not asking <action-parameter> to try <action-pattern-core> |    ==> { ACTOR_REQUESTED, RP[2] }; action_pattern *ap = *XP; ap->request = TRUE; APClauses::set_actor(ap, RP[1]);
	not asking <action-parameter> to try <action-pattern-core> |    ==> { ACTOR_REQUESTED, RP[2] }; ap = *XP; ap->request = TRUE; APClauses::set_actor(ap, RP[1]);
	<action-parameter> not trying <action-pattern-core> |    ==> { ACTOR_NAMED, RP[2] }; ap = *XP; ap->request = FALSE; APClauses::set_actor(ap, RP[1]);
	an actor not trying <action-pattern-core> |    ==> { ACTOR_EXPLICITLY_UNIVERSAL, RP[1] }; ap = *XP; ap->applies_to_any_actor = TRUE;
	an actor not <action-pattern-core> |    ==> { ACTOR_EXPLICITLY_UNIVERSAL, RP[1] }; ap = *XP; ap->applies_to_any_actor = TRUE;
	we are not trying <action-pattern-core> |    ==> { ACTOR_EXPLICITLY_PLAYER, RP[1] };
	not trying <action-pattern-core> |    ==> { ACTOR_EXPLICITLY_PLAYER, RP[1] };
	we are not <action-pattern-core> |    ==> { ACTOR_EXPLICITLY_PLAYER, RP[1] };
	not <action-pattern-core-actor>														==> { ACTOR_IMPLICITLY_PLAYER, RP[1] };

<action-pattern-past> ::=
	we have asked <action-parameter> to try <action-pattern-core> |    ==> { ACTOR_REQUESTED, RP[2] }; action_pattern *ap = *XP; ap->request = TRUE; APClauses::set_actor(ap, RP[1]);
	<action-parameter> has tried <action-pattern-core> |    ==> { ACTOR_NAMED, RP[2] }; ap = *XP; ap->request = FALSE; APClauses::set_actor(ap, RP[1]);
	an actor has tried <action-pattern-core> |    ==> { ACTOR_EXPLICITLY_UNIVERSAL, RP[1] }; ap = *XP; ap->applies_to_any_actor = TRUE;
	an actor has <action-pattern-past-core> |    ==> { ACTOR_EXPLICITLY_UNIVERSAL, RP[1] }; ap = *XP; ap->applies_to_any_actor = TRUE;
	we have tried <action-pattern-core> |    ==> { ACTOR_EXPLICITLY_PLAYER, RP[1] };
	we have <action-pattern-past-core>													==> { ACTOR_EXPLICITLY_PLAYER, RP[1] };

<action-pattern-past-negated> ::=
	we have not asked <action-parameter> to try <action-pattern-core> |    ==> { ACTOR_REQUESTED, RP[2] }; action_pattern *ap = *XP; ap->request = TRUE; APClauses::set_actor(ap, RP[1]);
	<action-parameter> has not tried <action-pattern-core> |    ==> { ACTOR_NAMED, RP[2] }; ap = *XP; ap->request = FALSE; APClauses::set_actor(ap, RP[1]);
	an actor has not tried <action-pattern-core> |    ==> { ACTOR_EXPLICITLY_UNIVERSAL, RP[1] }; ap = *XP; ap->applies_to_any_actor = TRUE;
	an actor has not <action-pattern-past-core> |    ==> { ACTOR_EXPLICITLY_UNIVERSAL, RP[1] }; ap = *XP; ap->applies_to_any_actor = TRUE;
	we have not tried <action-pattern-core> |    ==> { ACTOR_EXPLICITLY_PLAYER, RP[1] };
	we have not <action-pattern-past-core>												==> { ACTOR_EXPLICITLY_PLAYER, RP[1] };

@ There is one more tweak at this top level. Inform allows an ambiguous but
shorter and more natural syntax in which the actor's name simply appears at
the front of the AP:

>> Raffles taking a jewel

Here there are no textual markers like "trying" to separate the actor's
name ("Raffles") from the action itself ("taking a jewel"), and all
we can do is search out possibilities. If it's possible to match the action
without an initial actor name, that takes priority, to ensure that this
actorless possibility can always be written.

=
<action-pattern-core-actor> ::=
	<action-pattern-core> |    ==> { ACTOR_IMPLICITLY_PLAYER, RP[1] };
	<actor-description> <action-pattern-core> 				==> { ACTOR_NAMED, RP[2] }; action_pattern *ap = *XP; ap->request = FALSE; APClauses::set_actor(ap, RP[1]);

@ And this voracious token matches the actor's name as an initial excerpt,
which is much faster than exhaustive searching. It tries to break just before
any "-ing" word (i.e., participle) which is not inside parentheses; but only
if the resulting name matches <action-parameter> as a constant,
variable, or description; and there is no match if the text is the name of an
instance but the "-ing" word could also be read as part of that same name.
For example, if we read the text

>> angry waiting man taking the fish

where "angry waiting man" is the name of an individual person, then we don't
break this after "angry" (with the action "waiting") even though "angry"
would match as an abbreviated form of the name of "angry waiting man".

=
<actor-description> internal ? {
	if (permit_trying_omission) {
		int bl = 0;
		LOOP_THROUGH_WORDING(i, W)
			if (i > Wordings::first_wn(W)) {
				if (Lexer::word(i) == OPENBRACKET_V) bl++;
				if (Lexer::word(i) == CLOSEBRACKET_V) bl--;
				if ((bl == 0) && (<probable-participle>(Wordings::one_word(i)))) {
					if (<k-kind>(Wordings::up_to(W, i-1))) continue;
					parse_node *try_stem = NULL;
					instance *I;
					int old_state = ParseActionPatterns::suppress();
					if (<action-parameter>(Wordings::up_to(W, i-1))) try_stem = <<rp>>;
					ParseActionPatterns::resume(old_state);
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

@ =
int ParseActionPatterns::suppress(void) {
	int old_state = suppress_ap_parsing;
	suppress_ap_parsing = TRUE;
	return old_state;
}

void ParseActionPatterns::resume(int old_state) {
	suppress_ap_parsing = old_state;
}

@ That completes the top level, and we can forget about actors. All of those
productions come down now to just two nonterminals, one for the present tense,

>> taking or dropping a container

and one for the past,

>> taken or dropped a container

These are written as internals so that they can set a flag to change the
current tense as appropriate, but they don't otherwise do much:

(a) They trim away an indication of duration using <historical-reference>, so
that, e.g., "taking the box for the third time" has "for the third time"
trimmed away;

(b) They match <action-pronominal> as the most recently parsed action pattern;

(c) But otherwise they hand over to <ap-common-core> to do the work.

=
<action-pattern-core> internal {
	if (suppress_ap_parsing) return FALSE;
	action_pattern *ap = ParseActionPatterns::inner(W, IS_TENSE);
	if (ap) { ==> { -, ap }; return TRUE; }
	==> { fail nonterminal };
}

<action-pattern-past-core> internal {
	action_pattern *ap = ParseActionPatterns::inner(W, HASBEEN_TENSE);
	if (ap) { ==> { -, ap }; return TRUE; }
	==> { fail nonterminal };
}

@ "Doing it" is not the happiest of syntaxes. The idea is for this to be
a sort of pronoun for actions, allowing for anaphora, but to parse such things
naturally in all cases is wishful thinking. It enables us to write, e.g.:

>> Instead of Peter taking the box for the second time, try Jane doing it.

where "doing it" will refer to "taking the box". But I wonder if the
possibility for confusion is too great; perhaps we should just cut this idea.

=
<action-pronominal> ::=
	doing it

@ =
action_pattern *ParseActionPatterns::inner(wording W, int tense) {
	if (Lexer::word(Wordings::first_wn(W)) == OPENBRACE_V) return NULL;

	if (Wordings::empty(W)) internal_error("PAP on illegal word range");
	unsigned int d = Vocabulary::disjunction_of_flags(W);
	if (((tense == IS_TENSE) && ((d & (ACTION_PARTICIPLE_MC+NAMED_AP_MC)) == 0))) {
		pap_failure_reason = NOPARTICIPLE_PAPF;
		return NULL;
	}
	LOGIF(ACTION_PATTERN_PARSING, "Parse action pattern (tense %d): %W\n", tense, W);
	int duration_set = FALSE;
	time_period *duration = Occurrence::parse(W);
	if (duration) {
		W = Occurrence::unused_wording(duration);
		duration_set = TRUE;
	}
	int s = prevailing_ap_tense;
	prevailing_ap_tense = tense;
	action_pattern *ap = NULL;
	pap_failure_reason = MISC_PAPF;
	if (<action-pronominal>(W)) {
		if (Wordings::nonempty(last_successful_wording)) {
			LOGIF(ACTION_PATTERN_PARSING, "Doing it refers to %W\n", W);
			if (<ap-common-core>(last_successful_wording))
				ap = <<rp>>;
		}
	} else {
		if (<ap-common-core>(W)) {
			ap = <<rp>>;
			last_successful_wording = W;
			LOGIF(ACTION_PATTERN_PARSING, "Last successful W set to: %W\n",
				last_successful_wording);
		}
	}
	prevailing_ap_tense = s;
	if (ap) ap->duration = duration;
	LOGIF(ACTION_PATTERN_PARSING, "PAP result (pfr %d): $A\n", pap_failure_reason, ap);
	return ap;
}

@ Anyway, we are now down to level 3: all action patterns have been whittled
down to a single use of <ap-common-core>. Our next step is to recognise
a condition attached with "when":

=
<ap-common-core> ::=
	<ap-common-core-inner> when/while <condition-in-ap> |  ==> { 0, RP[1] }; action_pattern *ap = *XP; APClauses::set_val(ap, WHEN_AP_CLAUSE, RP[2]); if (pap_failure_reason == MISC_PAPF) pap_failure_reason = WHENOKAY_PAPF;
	<ap-common-core-inner> |                               ==> { 0, RP[1] };
	... when/while <condition-in-ap> |                     ==> { 0, NULL }; pap_failure_reason = WHENOKAY_PAPF; return FALSE; /* used only to diagnose problems */
	... when/while ...                                     ==> { 0, NULL }; if (pap_failure_reason != WHENOKAY_PAPF) pap_failure_reason = WHEN_PAPF; return FALSE; /* used only to diagnose problems */

@ <condition-in-ap> is really just <spec-condition> in disguise -- i.e.,
it matches a standard Inform condition -- but it's implemented as an internal
to enable Inform to set up a stack frame if there isn't one already, and so on.

=
<condition-in-ap> internal {
	ph_stack_frame *phsf = NULL;
	if (Frames::current_stack_frame() == NULL) phsf = Frames::new_nonphrasal();
	StackedVariables::append_owner_list(
		Frames::get_stvol(),
		all_nonempty_stacked_action_vars);
	LOGIF(ACTION_PATTERN_PARSING, "A when clause <%W> is suspected.\n", W);
	parse_node *wts = NULL;
	int s = pap_failure_reason;
	int pto = permit_trying_omission;
	permit_trying_omission = FALSE;
	if (<s-condition>(W)) wts = <<rp>>;
	pap_failure_reason = s;
	permit_trying_omission = pto;
	if (phsf) Frames::remove_nonphrase_stack_frame();
	if ((wts) && (Dash::validate_conditional_clause(wts))) {
		LOGIF(ACTION_PATTERN_PARSING, "When clause validated: $P.\n", wts);
		==> { -, wts };
		return TRUE;
	}
	==> { fail nonterminal };
}

@ Level 4 now. The optional "in the presence of":

=
<ap-common-core-inner> ::=
	<ap-common-core-inner-inner> in the presence of <action-parameter> |    ==> { 0, RP[1] }; APClauses::set_presence(RP[1], RP[2]);
	<ap-common-core-inner-inner>											==> { 0, RP[1] };

@ Level 5 now. The initial "in" clause, e.g., "in the Pantry", requires
special handling to prevent it from clashing with other interpretations of
"in" elsewhere in the grammar. It's perhaps unexpected that "in the Pantry"
is valid as an AP, but this enables many natural-looking rules to be written
("Report rule in the Pantry: ...", say).

=
<ap-common-core-inner-inner> ::=
	in <action-parameter> |             ==> @<Make an actionless action pattern, specifying room only@>
	<ap-common-core-inner-inner-inner>  ==> { 0, RP[1] };

@<Make an actionless action pattern, specifying room only@> =
	if (Dash::validate_parameter(RP[1], K_object) == FALSE) {
		==> { fail production }; /* the "room" isn't even an object */
	}
	action_pattern ap = ActionPatterns::new();
	ap.valid = TRUE; ap.text_of_pattern = W;
	APClauses::set_room(&ap, RP[1]);
	==> { 0, ActionPatterns::ap_store(ap) };

@ And that's as far down as we go: to level 6. Most of the complexity is gone
now, but what's left can't very efficiently be written in Preform. Essentially
we apply <action-list> to the text and then parse the operands using
<action-operand>, though it's a bit more involved because we also recognise
optional suffixes special to individual actions, like the "from the cage" in
"exiting from the cage", and we fail the result if it produces
inconsistencies between alternative actions (e.g., "taking or waiting the
box" makes no sense since only one is transitive).

=
<ap-common-core-inner-inner-inner> internal {
	if (Wordings::mismatched_brackets(W)) { ==> { fail nonterminal }; }
	if (scanning_anl_only_mode) {
		action_name_list *list = ActionNameLists::parse(W, prevailing_ap_tense, NULL);
		if (list == NULL) { ==> { fail nonterminal }; }
		action_pattern ap = ActionPatterns::new(); ap.valid = TRUE;
		ap.text_of_pattern = W;
		ap.action_list = list;
		==> { -, ActionPatterns::ap_store(ap) };
		return TRUE;
	} else {
		LOGIF(ACTION_PATTERN_PARSING, "Parsing action pattern: %W\n", W);
		LOG_INDENT;
		action_pattern ap = ParseActionPatterns::dash(W);
		LOG_OUTDENT;
		if (ActionPatterns::is_valid(&ap)) {
			==> { -, ActionPatterns::ap_store(ap) };
			return TRUE;
		}
	}
	==> { fail nonterminal };
}

@ The "operands" of an action pattern are the nouns to which it applies: for
example, in "Kevin taking or dropping something", the operand is "something".
We treat words like "something" specially to avoid them being read as
"some thing" and thus forcing the kind of the operand to be "thing".

=
<action-operand> ::=
	something/anything | 			==> { FALSE, - }
	something/anything else | 		==> { FALSE, - }
	<action-parameter> 				==> { TRUE, RP[1] }

<going-action-irregular-operand> ::=
	nowhere |    ==> { FALSE, - }
	somewhere						==> { TRUE, - }

<understanding-action-irregular-operand> ::=
	something/anything |    ==> { TRUE, - }
	it								==> { FALSE, - }

@ Finally, then, <action-parameter>. Almost anything syntactically matches
here -- a constant, a description, a table entry, a variable, and so on.

=
<action-parameter> ::=
	^<if-nonconstant-action-context> <s-local-variable> |    ==> { fail }
	^<if-nonconstant-action-context> <s-global-variable> |    ==> { fail }
	<s-local-variable> |    ==> { TRUE, RP[1] }
	<s-global-variable>	|    ==> { TRUE, RP[1] }
	<s-type-expression-or-value>							==> { TRUE, RP[1] }

<if-nonconstant-action-context> internal 0 {
	return permit_nonconstant_action_parameters;
}

@ We can't put it off any longer. Here goes.

=
action_pattern ParseActionPatterns::dash(wording W) {
	int failure_this_call = pap_failure_reason;
	int i, j, k = 0;
	action_name_list *list = NULL;
	int tense = prevailing_ap_tense;

	action_pattern ap = ActionPatterns::new(); ap.valid = FALSE;
	ap.text_of_pattern = W;

	@<PAR - (f) Parse Special Going Clauses@>;
	@<PAR - (i) Parse Initial Action Name List@>;
	@<PAR - (j) Parse Parameters@>;
	@<PAR - (k) Verify Mixed Action@>;
	@<With one small proviso, a valid action pattern has been parsed@>;
	return ap;

	Failed: ;
	@<No valid action pattern has been parsed@>;
	return ap;
}

@<With one small proviso, a valid action pattern has been parsed@> =
	pap_failure_reason = 0;
	ap.text_of_pattern = W;
	ap.action_list = list;
	anl_item *item = ActionNameLists::first_item(ap.action_list);
	if ((item) && (item->nap_listed == NULL) && (item->action_listed == NULL))
		ap.action_list = NULL;
	ap.valid = TRUE;

	APClauses::set_actor(&ap, ActionPatterns::nullify_nonspecific_references(APClauses::get_actor(&ap)));
	APClauses::set_noun(&ap, ActionPatterns::nullify_nonspecific_references(APClauses::get_noun(&ap)));
	APClauses::set_second(&ap, ActionPatterns::nullify_nonspecific_references(APClauses::get_second(&ap)));
	APClauses::nullify_nonspecific(&ap, IN_AP_CLAUSE);

	int ch = PluginCalls::check_going(APClauses::get_val(&ap, GOING_FROM_AP_CLAUSE), APClauses::get_val(&ap, GOING_TO_AP_CLAUSE), APClauses::get_val(&ap, GOING_BY_AP_CLAUSE), APClauses::get_val(&ap, GOING_THROUGH_AP_CLAUSE), APClauses::get_val(&ap, PUSHING_AP_CLAUSE));
	if (ch == FALSE) ap.valid = FALSE;

	if (ap.valid == FALSE) goto Failed;
	LOGIF(ACTION_PATTERN_PARSING, "Matched action pattern: $A\n", &ap);

@<No valid action pattern has been parsed@> =
	pap_failure_reason = failure_this_call;
	ap.valid = FALSE;
	ap.ap_clauses = NULL;
	ap.nowhere_flag = FALSE;
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
				else APClauses::ap_add_optional_clause(&ap, last_stv_specified, Wordings::new(k, i-1));
				k = i+1;
				last_stv_specified = stv;
			}
			i++;
		}
		if (last_stv_specified != NULL)
			APClauses::ap_add_optional_clause(&ap, last_stv_specified, Wordings::new(k, Wordings::last_wn(W)));
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
	LOOP_THROUGH_ANL(entry, list) {
		LOGIF(ACTION_PATTERN_PARSING, "Entry (%d):\n$8\n", ActionNameLists::parc(entry), entry);
		@<Fill out the noun, second, room and nowhere fields of the AP as if this action were right@>;
		@<Check the validity of this speculative AP@>;
		if ((trial_ap.valid) && (one_was_valid == FALSE) && (ActionNameLists::word_position(entry) == first_position)) {
			one_was_valid = TRUE;
			APClauses::set_noun(&ap, APClauses::get_noun(&trial_ap));
			APClauses::set_second(&ap, APClauses::get_second(&trial_ap));
			APClauses::set_room(&ap, APClauses::get_room(&trial_ap));
			ap.nowhere_flag = trial_ap.nowhere_flag;
			ap.valid = TRUE;
		}
		if (trial_ap.valid == FALSE) ActionNameLists::mark_for_deletion(entry);
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
	APClauses::set_room(&trial_ap, NULL); trial_ap.nowhere_flag = FALSE;
	if (Wordings::nonempty(ActionNameLists::par(entry, 0))) {
		if ((ActionNameLists::action(entry) == going_action) && (<going-action-irregular-operand>(ActionNameLists::par(entry, 0)))) {
			if (<<r>> == FALSE) trial_ap.nowhere_flag = TRUE;
			else trial_ap.nowhere_flag = 2;
		} else ActionPatterns::put_action_object_into_ap(&trial_ap, 1, ActionNameLists::par(entry, 0));
	}

	if (Wordings::nonempty(ActionNameLists::par(entry, 1))) {
		if ((ActionNameLists::action(entry) != NULL)
			&& (K_understanding)
			&& (Kinds::eq(ActionSemantics::kind_of_second(ActionNameLists::action(entry)), K_understanding))
			&& (<understanding-action-irregular-operand>(ActionNameLists::par(entry, 1)))) {
			parse_node *val = Rvalues::from_grammar_verb(NULL); /* Why no GV here? */
			Node::set_text(val, ActionNameLists::par(entry, 1));
			APClauses::set_second(&trial_ap, val);
		} else {
			ActionPatterns::put_action_object_into_ap(&trial_ap, 2, ActionNameLists::par(entry, 1));
		}
	}

	if (Wordings::nonempty(ActionNameLists::in_clause(entry)))
		ActionPatterns::put_action_object_into_ap(&trial_ap, 3,
			ActionNameLists::in_clause(entry));

@<Check the validity of this speculative AP@> =
	kind *check_n = K_object;
	kind *check_s = K_object;
	if (ActionNameLists::action(entry) != NULL) {
		check_n = ActionSemantics::kind_of_noun(ActionNameLists::action(entry));
		check_s = ActionSemantics::kind_of_second(ActionNameLists::action(entry));
	}
	trial_ap.valid = TRUE;
	if (APClauses::validate(APClauses::clause(&trial_ap, NOUN_AP_CLAUSE), check_n) == FALSE)
		trial_ap.valid = FALSE;
	if (APClauses::validate(APClauses::clause(&trial_ap, SECOND_AP_CLAUSE), check_s) == FALSE)
		trial_ap.valid = FALSE;
	if (APClauses::validate(APClauses::clause(&trial_ap, IN_AP_CLAUSE), K_object) == FALSE)
		trial_ap.valid = FALSE;

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
