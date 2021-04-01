[RuntimeContextData::] Runtime Context Data.

To store the circumstances in which a rule phrase should fire.

@h Introduction.
Runtime context data (RCD) is a set of restrictions on when a body of code can run.
It's intended for rules, but in principle available for any imperative definition.
For example,

>> Before taking a container when the player is in the Box Room: ...

can take effect only if the action is "taking a container" and the condition
about the location applies. Those two restrictions are both stored in its RCD.

=
typedef struct id_runtime_context_data {
	struct wording activity_context; /* text used to parse... */
	struct activity_list *avl; /* happens only while these activities go on */
	struct action_pattern *ap; /* happens only if the action or parameter matches this */
	void *plugin_rcd[MAX_PLUGINS]; /* storage for plugins to attach, if they want to */
} id_runtime_context_data;

id_runtime_context_data RuntimeContextData::new(void) {
	id_runtime_context_data phrcd;
	phrcd.activity_context = EMPTY_WORDING;
	phrcd.avl = NULL;
	phrcd.ap = NULL;
	for (int i=0; i<MAX_PLUGINS; i++) phrcd.plugin_rcd[i] = NULL;
	PluginCalls::new_rcd_notify(&phrcd);
	return phrcd;
}

id_runtime_context_data *RuntimeContextData::of(imperative_defn *id) {
	if (id == NULL) return NULL;
	return &(id->body_of_defn->runtime_context_data);
}

@ For the more interesting clauses, see //if: Scenes// and //if: Rules Predicated on Actions//,
where the scenes and actions plugins make use of the following extensibility:

@d RCD_PLUGIN_DATA(id, rcd)
	((id##_rcd_data *) rcd->plugin_rcd[id##_plugin->allocation_id])

@d CREATE_PLUGIN_RCD_DATA(id, rcd, creator)
	(rcd)->plugin_rcd[id##_plugin->allocation_id] = (void *) (creator(rcd));

@h Specificity.
The following is one of Inform's standardised comparison routines, which
takes a pair of objects A, B and returns 1 if A makes a more specific
description than B, 0 if they seem equally specific, or $-1$ if B makes a
more specific description than A. This is transitive, and intended to be
used in sorting algorithms.

In this case, laws I to V are applied in turn until one is decisive. If
all of them fail to decide, we return 0.

=
int RuntimeContextData::compare_specificity(id_runtime_context_data *rcd1,
	id_runtime_context_data *rcd2) {
	action_pattern *ap1 = NULL, *ap2 = NULL;
	parse_node *sc1 = NULL, *sc2 = NULL;
	wording AL1W = EMPTY_WORDING, AL2W = EMPTY_WORDING;
	@<Extract these from the PHRCDs under comparison@>;
	@<Apply comparison law I@>;
	@<Apply comparison law II@>;
	@<Apply comparison law III@>;
	@<Apply comparison law IV@>;
	@<Apply comparison law V@>;
	return 0;
}

@<Extract these from the PHRCDs under comparison@> =
	if (rcd1) {
		sc1 = Scenes::get_rcd_spec(rcd1); ap1 = ActionRules::get_ap(rcd1);
		AL1W = rcd1->activity_context;
	}
	if (rcd2) {
		sc2 = Scenes::get_rcd_spec(rcd2); ap2 = ActionRules::get_ap(rcd2);
		AL2W = rcd2->activity_context;
	}

@ More constraints beats fewer.

@<Apply comparison law I@> =
	Specifications::law(I"I - Number of aspects constrained");
	int rct1 = APClauses::count_aspects(ap1);
	int rct2 = APClauses::count_aspects(ap2);
	if (sc1) rct1++; if (sc2) rct2++;
	if (Wordings::nonempty(AL1W)) rct1++; if (Wordings::nonempty(AL2W)) rct2++;
	if (rct1 > rct2) return 1;
	if (rct1 < rct2) return -1;

@ If both have scene requirements, a narrow requirement beats a broad one.

@<Apply comparison law II@> =
	if ((sc1) && (sc2)) {
		int rv = Specifications::compare_specificity(sc1, sc2, NULL);
		if (rv != 0) return rv;
	}

@ More when/while conditions beats fewer.

@<Apply comparison law III@> =
	Specifications::law(I"III - When/while requirement");
	if ((Wordings::nonempty(AL1W)) && (Wordings::empty(AL2W))) return 1;
	if ((Wordings::empty(AL1W)) && (Wordings::nonempty(AL2W))) return -1;
	if (Wordings::nonempty(AL1W)) {
		int n1 = RuntimeContextData::activity_list_count(rcd1->avl);
		int n2 = RuntimeContextData::activity_list_count(rcd2->avl);
		if (n1 > n2) return 1;
		if (n2 > n1) return -1;
	}

@ A more specific action (or parameter) beats a less specific one.

@<Apply comparison law IV@> =
	Specifications::law(I"IV - Action requirement");
	int rv = ActionPatterns::compare_specificity(ap1, ap2);
	if (rv != 0) return rv;

@ A rule with a scene requirement beats one without.

@<Apply comparison law V@> =
	Specifications::law(I"V - Scene requirement");
	if ((sc1 != NULL) && (sc2 == NULL)) return 1;
	if ((sc1 == NULL) && (sc2 != NULL)) return -1;

@h Activity lists.
The activity list part of a RCD is a list of activities, one of which must
be currently running for the rule to fire. For example, in:

>> Rule for printing the name of the lemon sherbet while listing contents: ...

the activity list is just "listing contents". These are like action patterns,
but much simpler to parse -- an or-divided list of activities can be given,
with or without operands; "not" can be used to negate the list; and ordinary
conditions are also allowed, as here:

>> Rule for printing the name of the sack while the sack is not carried: ...

where "the sack is not carried" is also a <run-time-context> even though
it mentions no activities.

=
typedef struct activity_list {
	struct activity *activity; /* what activity */
	struct parse_node *acting_on; /* the parameter */
	struct parse_node *only_when; /* condition for when this applies */
	int ACL_parity; /* |+1| if meant positively, |-1| if negatively */
	struct activity_list *next; /* next in activity list */
} activity_list;

@ The "count" of an activity list is a measure of its complexity:

=
int RuntimeContextData::activity_list_count(activity_list *avl) {
	int n = 0;
	while (avl) {
		n += 10;
		if (avl->only_when) n += Conditions::count(avl->only_when);
		avl = avl->next;
	}
	return n;
}

@ There's a tricky race condition here: the activity list has to be parsed
with the correct rulebook variables or it won't parse; but the rulebook
variables won't be known until the rule is booked; and in order to book the
rule, Inform needs to sort it into logical sequence with others already in the
same rulebook; and that requires knowledge of the conditions of usage; which
in turn requires the activity list. So the following function is called at the
last possible moment in the booking process.

=
void RuntimeContextData::ensure_avl(rule *R) {
	imperative_defn *id = Rules::get_imperative_definition(R);
	if (id) {
		id_body *idb = id->body_of_defn;
		id_runtime_context_data *rcd = &(idb->runtime_context_data);
		if (Wordings::nonempty(rcd->activity_context)) {
			parse_node *save_cs = current_sentence;
			current_sentence = id->at;

			stack_frame *phsf = &(idb->compilation_data.id_stack_frame);
			Frames::make_current(phsf);

			Frames::set_shared_variable_access_list(phsf, R->variables_visible_in_definition);
			rcd->avl = RuntimeContextData::parse_avl(rcd->activity_context);
			current_sentence = save_cs;
		}
	}
}

@ Which calls down to:

=
int parsing_al_conditions = TRUE;

activity_list *RuntimeContextData::parse_avl(wording W) {
	int save_pac = parsing_al_conditions;
	parsing_al_conditions = TRUE;
	int rv = <run-time-context>(W);
	parsing_al_conditions = save_pac;
	if (rv) return <<rp>>;
	return NULL;
}

@ Which in turn uses the following Preform grammar.

The direct handling of "something" below is to avoid Inform from reading it
as "some thing", with the implication that a |K_thing| value is meant. When
people talk about "factorising something", where "factorising" is an activity
on numbers, for example, they mean "something" to stand for "any number", not
for "any physical object". Kind-checking means that only a number is possible
anyway, so we can safely just ignore the word "something".

=
<run-time-context> ::=
	not <activity-list-unnegated> |              ==> { 0, RP[1] }; @<Flip the activity list parities@>;
	<activity-list-unnegated>                    ==> { 0, RP[1] }

<activity-list-unnegated> ::=
	... |                                        ==> { lookahead }
	<activity-list-entry> <activity-tail> |      ==> @<Join the activity lists@>;
	<activity-list-entry>                        ==> { 0, RP[1] }

<activity-tail> ::=
	, _or <run-time-context> |                   ==> { 0, RP[1] }
	_,/or <run-time-context>                     ==> { 0, RP[1] }

<activity-list-entry> ::=
	<activity-name> |                            ==> @<Make one-entry AL without operand@>
	<activity-name> of/for <activity-operand> |  ==> @<Make one-entry AL with operand@>
	<activity-name> <activity-operand> |         ==> @<Make one-entry AL with operand@>
	^<if-parsing-al-conditions> ... |            ==> @<Make one-entry AL with unparsed text@>
	<if-parsing-al-conditions> <s-condition>     ==> @<Make one-entry AL with condition@>

<activity-operand> ::=
	something/anything |                         ==> { FALSE, Specifications::new_UNKNOWN(W) }
	something/anything else |                    ==> { FALSE, Specifications::new_UNKNOWN(W) }
	<s-type-expression-or-value>                 ==> { TRUE, RP[1] }

<if-parsing-al-conditions> internal 0 {
	if (parsing_al_conditions) return TRUE;
	==> { fail nonterminal };
}

@<Flip the activity list parities@> =
	activity_list *al = *XP;
	for (; al; al=al->next) {
		al->ACL_parity = (al->ACL_parity)?FALSE:TRUE;
	}

@<Join the activity lists@> =
	activity_list *al1 = RP[1], *al2 = RP[2];
	al1->next = al2;
	==> { -, al1 };

@<Make one-entry AL without operand@> =
	activity_list *al;
	@<Make one-entry AL@>;
	al->activity = RP[1];

@<Make one-entry AL with operand@> =
	activity *an = RP[1];
	if (an->activity_on_what_kind == NULL) return FALSE;
	if ((R[2]) && (Dash::validate_parameter(RP[2], an->activity_on_what_kind) == FALSE))
		return FALSE;
	activity_list *al;
	@<Make one-entry AL@>;
	al->activity = an;
	al->acting_on = RP[2];

@<Make one-entry AL with unparsed text@> =
	parse_node *cond = Specifications::new_UNKNOWN(EMPTY_WORDING);
	activity_list *al;
	@<Make one-entry AL@>;
	al->only_when = cond;

@<Make one-entry AL with condition@> =
	parse_node *cond = RP[2];
	if (Dash::validate_conditional_clause(cond) == FALSE) return FALSE;
	activity_list *al;
	@<Make one-entry AL@>;
	al->only_when = cond;

@<Make one-entry AL@> =
	al = CREATE(activity_list);
	al->acting_on = NULL;
	al->only_when = NULL;
	al->next = NULL;
	al->ACL_parity = TRUE;
	al->activity = NULL;
	==> { -, al };
