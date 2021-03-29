[Phrases::Context::] Phrase Runtime Context Data.

To store the circumstances in which a rule phrase should fire.

@ Runtime context data is the context in which a phrase is allowed to run,
though it's only used for rules. For example,

>> Before taking a container when the player is in the Box Room: ...

has the opportunity to fire when the "Before taking" rulebook gets to it.
But the rule only actually does so if the action is "taking a container"
and the condition about the location applies, and these two stipulations
form the PHRCD for the rule. For some simpler rules, like:

>> When play begins: ...

the PHRCD remains empty, because they are guaranteed to fire whenever their
rulebooks reach them.

=
typedef struct id_runtime_context_data {
	struct wording activity_context; /* happens only while any activities go on? */
	struct activity_list *avl;
	#ifdef IF_MODULE
	struct parse_node *during_scene; /* ...happens only during a scene matching this? */
	struct action_pattern *ap; /* happens only if the action matches this pattern? */
	int always_test_actor; /* ...even if no AP was given, test that actor is player? */
	int never_test_actor; /* ...for instance, for a parametrised rather than action rulebook */
	int marked_for_anyone; /* any actor is allowed to perform this action */
	#endif
	int permit_all_outcomes; /* waive the usual restrictions on rule outcomes */
} id_runtime_context_data;

typedef struct rule_context {
	#ifdef IF_MODULE
	struct action_name *action_context;
	struct scene *scene_context;
	#endif
	#ifndef IF_MODULE
	void *not_used;
	#endif
} rule_context;

rule_context Phrases::Context::no_rule_context(void) {
	rule_context rc;
	#ifdef IF_MODULE
	rc.action_context = NULL;
	rc.scene_context = NULL;
	#endif
	#ifndef IF_MODULE
	rc.not_used = NULL;
	#endif
	return rc;
}

int Phrases::Context::phrase_fits_rule_context(id_body *idb, rule_context rc) {
	#ifdef IF_MODULE
	if (rc.scene_context == NULL) return TRUE;
	if (idb == NULL) return FALSE;
	if (Phrases::Context::get_scene(&(idb->runtime_context_data)) != rc.scene_context) return FALSE;
	return TRUE;
	#endif
	#ifndef IF_MODULE
	return TRUE;
	#endif
}

#ifdef IF_MODULE
rule_context Phrases::Context::action_context(action_name *an) {
	rule_context rc;
	rc.action_context = an;
	rc.scene_context = NULL;
	return rc;
}
rule_context Phrases::Context::scene_context(scene *s) {
	rule_context rc;
	rc.action_context = NULL;
	rc.scene_context = s;
	return rc;
}
#endif

@ As we've seen, PHRCDs are really made by translating them from PHUDs, and
the following only blanks out a PHRCD structure ready for that to happen.

=
id_runtime_context_data Phrases::Context::new(void) {
	id_runtime_context_data phrcd;
	phrcd.activity_context = EMPTY_WORDING;
	phrcd.avl = NULL;
	#ifdef IF_MODULE
	phrcd.during_scene = NULL;
	phrcd.ap = NULL;
	phrcd.always_test_actor = FALSE;
	phrcd.never_test_actor = FALSE;
	phrcd.marked_for_anyone = FALSE;
	#endif
	phrcd.permit_all_outcomes = FALSE;
	return phrcd;
}

@h Access.
Some access routines: first, for actor testing.

=
void Phrases::Context::set_always_test_actor(id_runtime_context_data *phrcd) {
	#ifdef IF_MODULE
	phrcd->always_test_actor = TRUE;
	#endif
}

void Phrases::Context::clear_always_test_actor(id_runtime_context_data *phrcd) {
	#ifdef IF_MODULE
	phrcd->always_test_actor = FALSE;
	#endif
}

void Phrases::Context::set_never_test_actor(id_runtime_context_data *phrcd) {
	#ifdef IF_MODULE
	phrcd->never_test_actor = TRUE;
	#endif
}

void Phrases::Context::set_marked_for_anyone(id_runtime_context_data *phrcd, int to) {
	#ifdef IF_MODULE
	phrcd->marked_for_anyone = to;
	#endif
}

int Phrases::Context::get_marked_for_anyone(id_runtime_context_data *phrcd) {
	#ifdef IF_MODULE
	return phrcd->marked_for_anyone;
	#endif
	#ifndef IF_MODULE
	return FALSE;
	#endif
}

@ The required (or not) action:

=
#ifdef IF_MODULE
int Phrases::Context::within_action_context(id_runtime_context_data *phrcd,
	action_name *an) {
	if (phrcd == NULL) return FALSE;
	return ActionPatterns::covers_action(phrcd->ap, an);
}
#endif

#ifdef IF_MODULE
action_name *Phrases::Context::required_action(id_runtime_context_data *phrcd) {
	if (phrcd->ap) return ActionPatterns::single_positive_action(phrcd->ap);
	return NULL;
}
#endif

void Phrases::Context::suppress_action_testing(id_runtime_context_data *phrcd) {
	#ifdef IF_MODULE
	if (phrcd->ap) ActionPatterns::suppress_action_testing(phrcd->ap);
	#endif
}

@ The reason we store a whole specification, rather than a scene constant,
here is that we sometimes want rules which happen during "a recurring scene",
or some other description of scenes in general. The following routine
extracts a single specified scene if there is one:

=
#ifdef IF_MODULE
scene *Phrases::Context::get_scene(id_runtime_context_data *phrcd) {
	if (phrcd == NULL) return NULL;
	if (Rvalues::is_rvalue(phrcd->during_scene)) {
		instance *q = Rvalues::to_instance(phrcd->during_scene);
		if (q) return Scenes::from_named_constant(q);
	}
	return NULL;
}
#endif

@ This is to do with named outcomes of rules, whereby certain outcomes are
normally limited to the use of rules in particular rulebooks.

=
int Phrases::Context::outcome_restrictions_waived(void) {
	if ((id_body_being_compiled) &&
		(id_body_being_compiled->runtime_context_data.permit_all_outcomes))
		return TRUE;
	return FALSE;
}

@h Specificity of phrase runtime contexts.
The following is one of Inform's standardised comparison routines, which
takes a pair of objects A, B and returns 1 if A makes a more specific
description than B, 0 if they seem equally specific, or $-1$ if B makes a
more specific description than A. This is transitive, and intended to be
used in sorting algorithms.

In this case, laws I to V are applied in turn until one is decisive. If
all of them fail to decide, we return 0.

=
int Phrases::Context::compare_specificity(id_runtime_context_data *rcd1,
	id_runtime_context_data *rcd2) {
	#ifdef IF_MODULE
	action_pattern *ap1, *ap2;
	parse_node *sc1, *sc2;
	#endif
	wording AL1W, AL2W;
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
		#ifdef IF_MODULE
		sc1 = rcd1->during_scene;
		ap1 = rcd1->ap;
		#endif
		AL1W = rcd1->activity_context;
	} else {
		#ifdef IF_MODULE
		sc1 = NULL;
		ap1 = NULL;
		#endif
		AL1W = EMPTY_WORDING;
	}
	if (rcd2) {
		#ifdef IF_MODULE
		sc2 = rcd2->during_scene;
		ap2 = rcd2->ap;
		#endif
		AL2W = rcd2->activity_context;
	} else {
		#ifdef IF_MODULE
		sc2 = NULL;
		ap2 = NULL;
		#endif
		AL2W = EMPTY_WORDING;
	}

@ More constraints beats fewer.

@<Apply comparison law I@> =
	c_s_stage_law = I"I - Number of aspects constrained";
	int rct1 = 0, rct2 = 0;
	#ifdef IF_MODULE
	rct1 = APClauses::count_aspects(ap1);
	rct2 = APClauses::count_aspects(ap2);
	if (sc1) rct1++; if (sc2) rct2++;
	#endif
	if (Wordings::nonempty(AL1W)) rct1++; if (Wordings::nonempty(AL2W)) rct2++;

	if (rct1 > rct2) return 1;
	if (rct1 < rct2) return -1;

@ If both have scene requirements, a narrow requirement beats a broad one.

@<Apply comparison law II@> =
	#ifdef IF_MODULE
	if ((sc1) && (sc2)) {
		int rv = Specifications::compare_specificity(sc1, sc2, NULL);
		if (rv != 0) return rv;
	}
	#endif

@ More when/while conditions beats fewer.

@<Apply comparison law III@> =
	c_s_stage_law = I"III - When/while requirement";
	if ((Wordings::nonempty(AL1W)) && (Wordings::empty(AL2W))) return 1;
	if ((Wordings::empty(AL1W)) && (Wordings::nonempty(AL2W))) return -1;
	if (Wordings::nonempty(AL1W)) {
		int n1 = Phrases::Context::count_avl(rcd1->avl);
		int n2 = Phrases::Context::count_avl(rcd2->avl);
		if (n1 > n2) return 1;
		if (n2 > n1) return -1;
	}

@ A more specific action (or parameter) beats a less specific one.

@<Apply comparison law IV@> =
	c_s_stage_law = I"IV - Action requirement";
	#ifdef IF_MODULE
	int rv = ActionPatterns::compare_specificity(ap1, ap2);
	if (rv != 0) return rv;
	#endif

@ A rule with a scene requirement beats one without.

@<Apply comparison law V@> =
	c_s_stage_law = I"V - Scene requirement";
	#ifdef IF_MODULE
	if ((sc1 != NULL) && (sc2 == NULL)) return 1;
	if ((sc1 == NULL) && (sc2 != NULL)) return -1;
	#endif

@h Activity list on demand.
There's a tricky race condition here: the activity list has to be parsed
with the correct rulebook variables or it won't parse; but the rulebook
variables won't be known until the rule is booked; and in order to book
the rule, Inform needs to sort it into logical sequence with others
already in the same rulebook; and that requires knowledge of the
conditions of usage; which in turn requires the activity list. So the
following function is called at the last possible moment in the booking
process.

=
void Phrases::Context::ensure_avl(rule *R) {
	imperative_defn *id = Rules::get_imperative_definition(R);
	if (id) {
		id_body *idb = id->body_of_defn;
		id_runtime_context_data *rcd = &(idb->runtime_context_data);
		if (Wordings::nonempty(rcd->activity_context)) {
			parse_node *save_cs = current_sentence;
			current_sentence = id->at;

			ph_stack_frame *phsf = &(idb->compilation_data.stack_frame);
			Frames::make_current(phsf);

			Frames::set_stvol(phsf, R->variables_visible_in_definition);
			rcd->avl = Phrases::Context::parse_avl(rcd->activity_context);
			current_sentence = save_cs;
		}
	}
}

@ 

=
typedef struct activity_list {
	struct activity *activity; /* what activity */
	struct parse_node *acting_on; /* the parameter */
	struct parse_node *only_when; /* condition for when this applies */
	int ACL_parity; /* |+1| if meant positively, |-1| if negatively */
	struct activity_list *next; /* next in activity list */
} activity_list;

int Phrases::Context::count_avl(activity_list *avl) {
	int n = 0;
	while (avl) {
		n += 10;
		if (avl->only_when) n += Conditions::count(avl->only_when);
		avl = avl->next;
	}
	return n;
}

@ Run-time contexts are seen in the "while" clauses at the end of rules.
For example:

>> Rule for printing the name of the lemon sherbet while listing contents: ...

Here "listing contents" is the context. These are like action patterns, but
much simpler to parse -- an or-divided list of activities can be given, with or
without operands; "not" can be used to negate the list; and ordinary
conditions are also allowed, as here:

>> Rule for printing the name of the sack while the sack is not carried: ...

where "the sack is not carried" is also a <run-time-context> even though
it mentions no activities.

=
<run-time-context> ::=
	not <activity-list-unnegated> |          ==> { 0, RP[1] }; @<Flip the activity list parities@>;
	<activity-list-unnegated>                ==> { 0, RP[1] }

<activity-list-unnegated> ::=
	... |                                    ==> { lookahead }
	<activity-list-entry> <activity-tail> |  ==> @<Join the activity lists@>;
	<activity-list-entry>                    ==> { 0, RP[1] }

<activity-tail> ::=
	, _or <run-time-context> |               ==> { 0, RP[1] }
	_,/or <run-time-context>                 ==> { 0, RP[1] }

<activity-list-entry> ::=
	<activity-name> |                            ==> @<Make one-entry AL without operand@>
	<activity-name> of/for <activity-operand> |  ==> @<Make one-entry AL with operand@>
	<activity-name> <activity-operand> |         ==> @<Make one-entry AL with operand@>
	^<if-parsing-al-conditions> ... |            ==> @<Make one-entry AL with unparsed text@>
	<if-parsing-al-conditions> <s-condition>     ==> @<Make one-entry AL with condition@>

@ The optional operand handles "something" itself in productions (a) and (b)
in order to prevent it from being read as a description at production (c). This
prevents "something" from being read as "some thing", that is, it prevents
Inform from thinking that the operand value must have kind "thing".

If we do reach (c), the expression is required to be a value, or description of
values, of the kind to which the activity applies.

=
<activity-operand> ::=
	something/anything |          ==> { FALSE, Specifications::new_UNKNOWN(W) }
	something/anything else |     ==> { FALSE, Specifications::new_UNKNOWN(W) }
	<s-type-expression-or-value>  ==> { TRUE, RP[1] }

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

@ =
int parsing_al_conditions = TRUE;

@ It's convenient not to look too closely at the condition sometimes.

=
<if-parsing-al-conditions> internal 0 {
	if (parsing_al_conditions) return TRUE;
	==> { fail nonterminal };
}

@ All of which sets up the context for:

=
activity_list *Phrases::Context::parse_avl(wording W) {
	int save_pac = parsing_al_conditions;
	parsing_al_conditions = TRUE;
	int rv = <run-time-context>(W);
	parsing_al_conditions = save_pac;
	if (rv) return <<rp>>;
	return NULL;
}
