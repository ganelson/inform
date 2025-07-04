[TimedRules::] Timed Rules.

A feature to support rules like "At 12:03AM: ...".

@ This feature makes a special set of rules for timed events; the |:timedrules|
test group may be useful in testing it.

Each such rule has a time at which it should spontaneously happen. This is
ordinarily a time of day, such as "At 9:00 AM: ...", represented by a number
from 0 to 1439, measuring minutes since midnight. These negative values have
special significance:

@d NOT_A_TIMED_EVENT -1 /* as for the vast majority of rules */
@d NO_FIXED_TIME -2 /* for phrases like "When the clock strikes: ..." */
@d NOT_AN_EVENT -3 /* not even syntactically */

=
void TimedRules::start(void) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincompatible-function-pointer-types-strict"
	PluginCalls::plug(NEW_RULE_DEFN_NOTIFY_PLUG, TimedRules::new_rule_defn_notify);
	PluginCalls::plug(INLINE_ANNOTATION_PLUG, TimedRules::inline_annotation);
	PluginCalls::plug(PRODUCTION_LINE_PLUG, TimedRules::production_line);
#pragma clang diagnostic pop
}

int TimedRules::production_line(int stage, int debugging, stopwatch_timer *sequence_timer) {
	if (stage == INTER5_CSEQ) {
		BENCH(RTRules::annotate_timed_rules_with_usage)
		BENCH(TimedRules::check_for_unused)
	}
	return FALSE;
}

@ Event rules are recognised by the initial word "At":

=
<event-rule-preamble> ::=
	at <clock-time> |         ==> { pass 1 }
	at the time when ... |    ==> { NO_FIXED_TIME, - }
	at the time that ... |    ==> @<Issue PM_AtTimeThat problem@>
	at ...					  ==> @<Issue PM_AtWithoutTime problem@>

@<Issue PM_AtTimeThat problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_AtTimeThat),
		"this seems to use 'that' where it should use 'when'",
		"assuming it's trying to apply a rule to an event. (The convention is that any "
		"rule beginning 'At' is a timed one. The time can either be a fixed time, as in "
		"'At 11:10 AM: ...', or the time when some named event takes place, as in 'At the "
		"time when the clock chimes: ...'.)");

@<Issue PM_AtWithoutTime problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_AtWithoutTime),
		"'at' what time? No description of a time is given",
		"which means that this rule can never have effect. (The convention is that any "
		"rule beginning 'At' is a timed one. The time can either be a fixed time, as in "
		"'At 11:10 AM: ...', or the time when some named event takes place, as in 'At the "
		"time when the clock chimes: ...'.)");

@ =
int TimedRules::new_rule_defn_notify(imperative_defn *id, rule_family_data *rfd) {
	CREATE_RFD_FEATURE_DATA(timed_rules, rfd, TimedRules::new_rfd_data);
	wording W = rfd->usage_preamble;
	if (<event-rule-preamble>(W)) {
		int t = <<r>>;
		rfd->usage_preamble = EMPTY_WORDING;
		rfd->not_in_rulebook = TRUE;
		RFD_FEATURE_DATA(timed_rules, rfd)->event_time = t;
		if (t == NO_FIXED_TIME) {
			wording EW = GET_RW(<event-rule-preamble>, 1);
			EW = Articles::remove_the(EW);
			RFD_FEATURE_DATA(timed_rules, rfd)->event_name = EW;
			rfd->constant_name = EW;
		}
	}
	return FALSE;
}

@ The above therefore attaches one of these to each set of rule data:

=
typedef struct timed_rules_rfd_data {
	int event_time; /* 0 to 1339, or one of the special values above */
	struct wording event_name; /* if one is given */
	struct linked_list *uses_as_event; /* of |parse_node| */
	CLASS_DEFINITION
} timed_rules_rfd_data;

timed_rules_rfd_data *TimedRules::new_rfd_data(rule_family_data *rfd) {
	timed_rules_rfd_data *trfd = CREATE(timed_rules_rfd_data);
	trfd->event_time = NOT_A_TIMED_EVENT;
	trfd->event_name = EMPTY_WORDING;
	trfd->uses_as_event = NEW_LINKED_LIST(parse_node);
	return trfd;
}

@ And that data can be read back with:

=
linked_list *TimedRules::get_uses_as_event(imperative_defn *id) {
	if (id->family != rule_idf) return NULL;
	rule_family_data *rfd = RETRIEVE_POINTER_rule_family_data(id->family_specific_data);
	return RFD_FEATURE_DATA(timed_rules, rfd)->uses_as_event;
}

int TimedRules::get_timing_of_event(imperative_defn *id) {
	if (id->family != rule_idf) return NOT_A_TIMED_EVENT;
	rule_family_data *rfd = RETRIEVE_POINTER_rule_family_data(id->family_specific_data);
	if (RFD_FEATURE_DATA(timed_rules, rfd) == NULL) return NOT_A_TIMED_EVENT;
	return RFD_FEATURE_DATA(timed_rules, rfd)->event_time;
}

wording TimedRules::get_wording_of_event(imperative_defn *id) {
	if (id->family != rule_idf) return EMPTY_WORDING;
	rule_family_data *rfd = RETRIEVE_POINTER_rule_family_data(id->family_specific_data);
	return RFD_FEATURE_DATA(timed_rules, rfd)->event_name;
}

@ When a rule has no explicit timing, it needs to be triggered by a phrase
like "spawn fresh zombies in 4 turns from now". Here, "spawn fresh zombies"
is the name of the rule. But this has the same kind as any other rule, so
the Dash typechecker is not able to make sure "spawn fresh zombies" is indeed
timed, and not some other rule.

We fix this by defining the trigger phrase to use the inline annotation
|{-mark-event-used:R}| on the rule |R|. That in turn results in the following
being called:

=
int TimedRules::inline_annotation(int annot, parse_node *supplied) {
	if (annot == mark_event_used_ISINC) {
		if (Rvalues::is_CONSTANT_construction(supplied, CON_rule)) {
			rule *R = Rvalues::to_rule(supplied);
			imperative_defn *id = Rules::get_imperative_definition(R);
			if (id) {
				int t = TimedRules::get_timing_of_event(id);
				if (t == NO_FIXED_TIME) {
					linked_list *L = TimedRules::get_uses_as_event(id);
					ADD_TO_LINKED_LIST(current_sentence, parse_node, L);
				} else @<Not an event rule@>;
			} else @<Not an event rule@>;
		} else @<Not an event rule@>;
		return TRUE;
	}
	return FALSE;
}

@<Not an event rule@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, Node::get_text(supplied));
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_NonconstantEvent));
	Problems::issue_problem_segment(
		"You wrote %1, but '%2' isn't the name of any timed event that I know of. "
		"(These need to be set up in a special way, like so - 'At the time when stuff "
		"happens: ...' creates a timed event called 'stuff happens'.)");
	Problems::issue_problem_end();

@ An interesting case where the Problem is arguably only a warning and arguably
shouldn't block compilation. Then again...

=
void TimedRules::check_for_unused(void) {
	imperative_defn *id;
	LOOP_OVER(id, imperative_defn)
		if (TimedRules::get_timing_of_event(id) == NO_FIXED_TIME)
			if (LinkedLists::len(TimedRules::get_uses_as_event(id)) == 0) {
				current_sentence = id->at;
				StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_UnusedTimedEvent),
					"this sets up a timed event which is never used",
					"since you never use any of the phrases which could cause it. (A timed "
					"event is just a name, and it needs other instructions elsewhere before "
					"it can have any effect.)");
			}
}
