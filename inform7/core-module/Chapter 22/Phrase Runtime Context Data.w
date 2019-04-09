[Phrases::Context::] Phrase Runtime Context Data.

To store the circumstances in which a rule phrase should fire.

@h Definitions.

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
typedef struct ph_runtime_context_data {
	struct wording activity_context; /* happens only while any activities go on? */
	struct parse_node *activity_where; /* and who says? */
	struct activity_list *avl;
	#ifdef IF_MODULE
	struct parse_node *during_scene; /* ...happens only during a scene matching this? */
	struct action_pattern ap; /* happens only if the action matches this pattern? */
	int always_test_actor; /* ...even if no AP was given, test that actor is player? */
	int never_test_actor; /* ...for instance, for a parametrised rather than action rulebook */
	int marked_for_anyone; /* any actor is allowed to perform this action */
	#endif
	struct rulebook **compile_for_rulebook; /* ...used for the default outcome */
	int permit_all_outcomes; /* waive the usual restrictions on rule outcomes */
} ph_runtime_context_data;

typedef struct rule_context {
	#ifdef IF_MODULE
	struct action_name *action_context;
	struct scene *scene_context;
	#endif
	#ifndef IF_MODULE
	void *not_used;
	#endif
} rule_context;

@ As we've seen, PHRCDs are really made by translating them from PHUDs, and
the following only blanks out a PHRCD structure ready for that to happen.

=
ph_runtime_context_data Phrases::Context::new(void) {
	ph_runtime_context_data phrcd;
	phrcd.activity_context = EMPTY_WORDING;
	phrcd.activity_where = NULL;
	phrcd.avl = NULL;
	#ifdef IF_MODULE
	phrcd.during_scene = NULL;
	phrcd.ap = PL::Actions::Patterns::new();
	phrcd.always_test_actor = FALSE;
	phrcd.never_test_actor = FALSE;
	phrcd.marked_for_anyone = FALSE;
	#endif
	phrcd.permit_all_outcomes = FALSE;
	phrcd.compile_for_rulebook = NULL;
	return phrcd;
}

@h Access.
Some access routines: first, for actor testing.

=
void Phrases::Context::set_always_test_actor(ph_runtime_context_data *phrcd) {
	#ifdef IF_MODULE
	phrcd->always_test_actor = TRUE;
	#endif
}

void Phrases::Context::clear_always_test_actor(ph_runtime_context_data *phrcd) {
	#ifdef IF_MODULE
	phrcd->always_test_actor = FALSE;
	#endif
}

void Phrases::Context::set_never_test_actor(ph_runtime_context_data *phrcd) {
	#ifdef IF_MODULE
	phrcd->never_test_actor = TRUE;
	#endif
}

void Phrases::Context::set_marked_for_anyone(ph_runtime_context_data *phrcd, int to) {
	#ifdef IF_MODULE
	phrcd->marked_for_anyone = to;
	#endif
}

int Phrases::Context::get_marked_for_anyone(ph_runtime_context_data *phrcd) {
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
int Phrases::Context::within_action_context(ph_runtime_context_data *phrcd,
	action_name *an) {
	if (phrcd == NULL) return FALSE;
	return PL::Actions::Patterns::within_action_context(&(phrcd->ap), an);
}
#endif

#ifdef IF_MODULE
action_name *Phrases::Context::required_action(ph_runtime_context_data *phrcd) {
	if (PL::Actions::Patterns::is_valid(&(phrcd->ap)))
		return PL::Actions::Patterns::required_action(&(phrcd->ap));
	return NULL;
}
#endif

void Phrases::Context::suppress_action_testing(ph_runtime_context_data *phrcd) {
	#ifdef IF_MODULE
	PL::Actions::Patterns::suppress_action_testing(&(phrcd->ap));
	#endif
}

@ The reason we store a whole specification, rather than a scene constant,
here is that we sometimes want rules which happen during "a recurring scene",
or some other description of scenes in general. The following routine
extracts a single specified scene if there is one:

=
#ifdef IF_MODULE
scene *Phrases::Context::get_scene(ph_runtime_context_data *phrcd) {
	if (phrcd == NULL) return NULL;
	if (ParseTreeUsage::is_rvalue(phrcd->during_scene)) {
		instance *q = Rvalues::to_instance(phrcd->during_scene);
		if (q) return PL::Scenes::from_named_constant(q);
	}
	return NULL;
}
#endif

@ This is to do with named outcomes of rules, whereby certain outcomes are
normally limited to the use of rules in particular rulebooks.

=
int Phrases::Context::outcome_restrictions_waived(void) {
	if ((phrase_being_compiled) &&
		(phrase_being_compiled->runtime_context_data.permit_all_outcomes))
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
int Phrases::Context::compare_specificity(ph_runtime_context_data *rcd1,
	ph_runtime_context_data *rcd2) {
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
		ap1 = &(rcd1->ap);
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
		ap2 = &(rcd2->ap);
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
	c_s_stage_law = "I - Number of aspects constrained";
	int rct1 = 0, rct2 = 0;
	#ifdef IF_MODULE
	rct1 = PL::Actions::Patterns::count_aspects(ap1);
	rct2 = PL::Actions::Patterns::count_aspects(ap2);
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
	c_s_stage_law = "III - When/while requirement";
	if ((Wordings::nonempty(AL1W)) && (Wordings::empty(AL2W))) return 1;
	if ((Wordings::empty(AL1W)) && (Wordings::nonempty(AL2W))) return -1;
	if (Wordings::nonempty(AL1W)) {
		int n1 = Activities::count_list(rcd1->avl);
		int n2 = Activities::count_list(rcd2->avl);
		if (n1 > n2) return 1;
		if (n2 > n1) return -1;
	}

@ A more specific action (or parameter) beats a less specific one.

@<Apply comparison law IV@> =
	c_s_stage_law = "IV - Action requirement";
	#ifdef IF_MODULE
	int rv = PL::Actions::Patterns::compare_specificity(ap1, ap2);
	if (rv != 0) return rv;
	#endif

@ A rule with a scene requirement beats one without.

@<Apply comparison law V@> =
	c_s_stage_law = "V - Scene requirement";
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
	phrase *ph = R->defn_as_phrase;
	if (ph) {
		ph_runtime_context_data *rcd = &(ph->runtime_context_data);
		if (Wordings::nonempty(rcd->activity_context)) {
			parse_node *save_cs = current_sentence;
			current_sentence = rcd->activity_where;

			ph_stack_frame *phsf = &(ph->stack_frame);
			Frames::make_current(phsf);

			Frames::set_stvol(phsf, R->listed_stv_owners);
			rcd->avl = Activities::parse_list(rcd->activity_context);
			current_sentence = save_cs;
		}
	}
}

@h Compiling the firing test.
Each rule compiles to a routine, and this routine is called whenever the
opportunity might exist for the rule to fire. The structure of this is
similar to:

	|[ Rule;|
	|    if (some-firing-condition) {|
	|        ...|
	|        return some-default-outcome;|
	|    }|
	|];|

The "test head" is the "if" line here, and the "test tail" is the "}". The
return statement isn't necessarily reached, because even if the firing
condition holds, the "..." code may decide to return in some other way.
It provides only a default to cover rules which don't specify an outcome.

In general the test is more elaborate than a single "if", though not very
much.

=
int Phrases::Context::compile_test_head(phrase *ph, applicability_condition *acl) {
	inter_name *identifier = Phrases::iname(ph);
	ph_runtime_context_data *phrcd = &(ph->runtime_context_data);

	if (Rules::compile_constraint(acl) == TRUE) return TRUE;

	int tests = 0;

	#ifdef IF_MODULE
	if (phrcd->during_scene) @<Compile a scene test head@>;

	if (PL::Actions::Patterns::is_valid(&(phrcd->ap))) @<Compile an action test head@>
	else if (phrcd->always_test_actor == TRUE) @<Compile an actor-is-player test head@>;
	#endif
	if (Wordings::nonempty(phrcd->activity_context)) @<Compile an activity or explicit condition test head@>;

	if ((tests > 0) || (ph->compile_with_run_time_debugging)) {
		Emit::inv_primitive(if_interp);
		Emit::down();
			Emit::val_iname(K_number, InterNames::extern(DEBUGRULES_EXNAMEF));
			Emit::code();
			Emit::down();
				Emit::inv_call(InterNames::to_symbol(InterNames::extern(DBRULE_EXNAMEF)));
				Emit::down();
					Emit::val_iname(K_value, identifier);
					Emit::val(K_number, LITERAL_IVAL, (inter_t) ph->allocation_id);
					Emit::val(K_number, LITERAL_IVAL, 0);
				Emit::up();
			Emit::up();
		Emit::up();
	}

	return FALSE;
}

@ This is almost the up-down reflection of the head, but note that it begins
with the default outcome return (see above).

=
void Phrases::Context::compile_test_tail(phrase *ph, applicability_condition *acl) {

	inter_name *identifier = Phrases::iname(ph);
	ph_runtime_context_data *phrcd = &(ph->runtime_context_data);

	if (phrcd->compile_for_rulebook) {
		rulebook *rb = *(phrcd->compile_for_rulebook);
		if (rb) Rulebooks::Outcomes::compile_default_outcome(Rulebooks::get_outcomes(rb));
	}

	if (Wordings::nonempty(phrcd->activity_context)) @<Compile an activity or explicit condition test tail@>;
	#ifdef IF_MODULE
	if (PL::Actions::Patterns::is_valid(&(phrcd->ap))) @<Compile an action test tail@>
	else if (phrcd->always_test_actor == TRUE) @<Compile an actor-is-player test tail@>;
	if (phrcd->during_scene) @<Compile a scene test tail@>;
	#endif
}

@h Scene test.

@<Compile a scene test head@> =
	Emit::inv_primitive(ifelse_interp);
	Emit::down();
		PL::Scenes::emit_during_clause(phrcd->during_scene);
		Emit::code();
		Emit::down();

	tests++;

@<Compile a scene test tail@> =
	inter_t failure_code = 1;
	@<Compile a generic test fail@>;

@h Action test.

@<Compile an action test head@> =
	Emit::inv_primitive(ifelse_interp);
	Emit::down();
		if (phrcd->never_test_actor)
			PL::Actions::Patterns::emit_pattern_match(phrcd->ap, TRUE);
		else
			PL::Actions::Patterns::emit_pattern_match(phrcd->ap, FALSE);
		Emit::code();
		Emit::down();

	tests++;
	if (PL::Actions::Patterns::object_based(&(phrcd->ap))) {
			Emit::inv_primitive(store_interp);
			Emit::down();
				Emit::ref_iname(K_object, InterNames::find(SELF_NRL));
				Emit::val_iname(K_object, InterNames::extern(NOUN_EXNAMEF));
			Emit::up();
	}

@<Compile an action test tail@> =
	inter_t failure_code = 2;
	@<Compile a generic test fail@>;

@h Actor-is-player test.

@<Compile an actor-is-player test head@> =
	Emit::inv_primitive(ifelse_interp);
	Emit::down();
		Emit::inv_primitive(eq_interp);
		Emit::down();
			Emit::val_iname(K_object, InterNames::extern(ACTOR_EXNAMEF));
			Emit::val_iname(K_object, InterNames::extern(PLAYER_EXNAMEF));
		Emit::up();
		Emit::code();
		Emit::down();

	tests++;

@<Compile an actor-is-player test tail@> =
	inter_t failure_code = 3;
	@<Compile a generic test fail@>;

@h Activity-or-condition test.

@<Compile an activity or explicit condition test head@> =
	Emit::inv_primitive(ifelse_interp);
	Emit::down();
		activity_list *avl = phrcd->avl;
		if (avl) {
			Activities::emit_activity_list(avl);
		} else {
			Problems::Issue::sentence_problem(_p_(PM_BadWhenWhile),
				"I don't understand the 'when/while' clause",
				"which should name activities or conditions.");
			Emit::val(K_truth_state, LITERAL_IVAL, 0);
		}
		Emit::code();
		Emit::down();

		Activities::annotate_list_for_cross_references(avl, ph);
		tests++;

@<Compile an activity or explicit condition test tail@> =
	inter_t failure_code = 4;
	@<Compile a generic test fail@>;

@<Compile a generic test fail@> =
		Emit::up();
		Emit::code();
		Emit::down();
			Emit::inv_primitive(if_interp);
			Emit::down();
				Emit::inv_primitive(gt_interp);
				Emit::down();
					Emit::val_iname(K_number, InterNames::extern(DEBUGRULES_EXNAMEF));
					Emit::val(K_number, LITERAL_IVAL, 1);
				Emit::up();
				Emit::code();
				Emit::down();
					Emit::inv_call(InterNames::to_symbol(InterNames::extern(DBRULE_EXNAMEF)));
					Emit::down();
						Emit::val_iname(K_value, identifier);
						Emit::val(K_number, LITERAL_IVAL, (inter_t) ph->allocation_id);
						Emit::val(K_number, LITERAL_IVAL, failure_code);
					Emit::up();
				Emit::up();
			Emit::up();
		Emit::up();
	Emit::up();
