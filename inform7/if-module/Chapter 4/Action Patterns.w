[ActionPatterns::] Action Patterns.

An action pattern is a description which may match many actions or
none. The text "doing something" matches every action, while "throwing
something at a door in a dark room" is seldom matched. Here we parse such
text into a data structure called an |action_pattern|.

@ Action patterns are essentially a conjunction of specifications -- the
action must be this, and the noun must be that, and... While
they allow disjunction in the choice of action, all of that code is a
matter for the action name list to handle. The AP structure is a list
of conditions all of which must apply at once.

One surprising point is that the AP is used not only for action
patterns, but also in a slightly generalised role, as the condition
for a rule to be applied. Most rules are indeed predicated on actions
-- "instead of eating the cake" -- but some are instead in
"parametrised" rulebooks, which means they apply to a parameter
object instead of an action -- "reaching inside the cabinet". These
not-really-action APs are used in no other context, and employ the
|parameter_spec| field below, ignoring the rest.

=
typedef struct action_pattern {
	struct wording text_of_pattern; /* text giving rise to this AP */

	struct action_name_list *action_list; /* what the behaviour is */
	int test_anl; /* actually test the action when compiled */

	int applies_to_any_actor; /* treat player and other people equally */
	int request; /* a request from the player for someone to do this? */
	struct parse_node *actor_spec;
	struct parse_node *noun_spec;
	int noun_any;
	struct parse_node *second_spec;
	int second_any;
	struct parse_node *presence_spec; /* in the presence of... */
	struct parse_node *room_spec; /* in... */
	int room_any;
	struct parse_node *when; /* when... (any condition here) */
	struct parse_node *from_spec; /* for the "going" action only */
	struct parse_node *to_spec; /* ditto */
	struct parse_node *by_spec; /* ditto */
	struct parse_node *through_spec; /* ditto */
	struct parse_node *pushing_spec; /* ditto */
	int nowhere_flag; /* ditto: a flag for "going nowhere" */
	struct ap_optional_clause *optional_clauses;
	int chief_action_owner_id; /* stacked variable ID number of main action */
	struct time_period *duration; /* to hold "for the third time", etc. */

	struct parse_node *parameter_spec; /* alternatively, just this */
	struct kind *parameter_kind; /* of this expected kind */

	int valid; /* recording success or failure in parsing to an AP */
} action_pattern;

typedef struct ap_optional_clause {
	struct stacked_variable *stv_to_match;
	struct parse_node *clause_spec;
	int allow_region_as_room;
	struct ap_optional_clause *next;
	CLASS_DEFINITION
} ap_optional_clause;

@ When we parse action patterns, we record why they fail, in order to make
it easier to produce helpful error messages. (We can't simply fire off
errors at the time they occur, because text is often parsed in several
contexts at once, so just because it fails this one does not mean it is
wrong.) PAPF stands for "parse action pattern failure".

@d MISC_PAPF 1
@d NOPARTICIPLE_PAPF 2
@d MIXEDNOUNS_PAPF 3
@d WHEN_PAPF 4
@d WHENOKAY_PAPF 5
@d IMMISCIBLE_PAPF 6

= (early code)
int pap_failure_reason; /* one of the above */
int permit_trying_omission = FALSE; /* allow the keyword 'trying' to be omitted */
int permit_nonconstant_action_parameters = TRUE;

@ NB: Next time this is rewritten - (1) handle in, in the presence of, with
STV clauses; (2) get this right:

	The Rocky Promontory by the Waterfall is a room.

	Instead of going in the Rocky Promontory by the Waterfall:
		say "Where did you want to go?"

@ =
action_pattern ActionPatterns::new(void) {
	action_pattern ap;
	ap.text_of_pattern = EMPTY_WORDING;
	ap.action_list = NULL;
	ap.test_anl = TRUE;
	ap.actor_spec = NULL;
	ap.noun_spec = NULL; ap.second_spec = NULL; ap.room_spec = NULL;
	ap.noun_any = FALSE; ap.second_any = FALSE; ap.room_any = FALSE;
	ap.parameter_spec = NULL;
	ap.parameter_kind = K_object;
	ap.valid = FALSE;
	ap.when = NULL;
	ap.presence_spec = NULL;
	ap.from_spec = NULL;
	ap.to_spec = NULL;
	ap.by_spec = NULL;
	ap.through_spec = NULL;
	ap.pushing_spec = NULL;
	ap.nowhere_flag = FALSE;
	ap.request = FALSE;
	ap.applies_to_any_actor = FALSE;
	ap.duration = NULL;
	ap.optional_clauses = NULL;
	ap.chief_action_owner_id = 0;
	return ap;
}

ap_optional_clause *ActionPatterns::apoc_new(stacked_variable *stv, parse_node *spec) {
	ap_optional_clause *apoc = CREATE(ap_optional_clause);
	apoc->stv_to_match = stv;
	apoc->clause_spec = spec;
	apoc->next = NULL;
	apoc->allow_region_as_room = FALSE;
	return apoc;
}

void ActionPatterns::ap_add_optional_clause(action_pattern *ap, ap_optional_clause *apoc) {
	int oid = StackedVariables::get_owner_id(apoc->stv_to_match);
	int off = StackedVariables::get_offset(apoc->stv_to_match);
	if (ap->optional_clauses == NULL) {
		ap->optional_clauses = apoc;
		apoc->next = NULL;
	} else {
		ap_optional_clause *oapoc = ap->optional_clauses, *papoc = NULL;
		while (oapoc) {
			int ooff = StackedVariables::get_offset(oapoc->stv_to_match);
			if (off < ooff) {
				if (oapoc == ap->optional_clauses) {
					apoc->next = ap->optional_clauses;
					ap->optional_clauses = apoc;
					papoc = NULL;
				} else {
					apoc->next = papoc->next;
					papoc->next = apoc;
					papoc = NULL;
				}
				break;
			}
			papoc = oapoc;
			oapoc = oapoc->next;
		}
		if (papoc) {
			apoc->next = NULL;
			papoc->next = apoc;
		}
	}

	if (oid == 20007 /* i.e., going */ ) {
		switch (off) {
			case 0: ap->from_spec = apoc->clause_spec; apoc->allow_region_as_room = TRUE; break;
			case 1: ap->to_spec = apoc->clause_spec; apoc->allow_region_as_room = TRUE; break;
			case 2: ap->through_spec = apoc->clause_spec; break;
			case 3: ap->by_spec = apoc->clause_spec; break;
			case 4: ap->pushing_spec = apoc->clause_spec; break;
		}
	}
	ap->chief_action_owner_id = oid;
}

int ActionPatterns::ap_count_optional_clauses(action_pattern *ap) {
	int n = 0;
	ap_optional_clause *apoc;
	for (apoc = ap->optional_clauses; apoc; apoc = apoc->next) {
		if ((ap->chief_action_owner_id != 20007) ||
			(StackedVariables::get_offset(apoc->stv_to_match) >= 5))
			n++;
	}
	return n;
}

int ActionPatterns::compare_specificity_of_apoc_list(action_pattern *ap1, action_pattern *ap2) {
	int rct1 = ActionPatterns::ap_count_optional_clauses(ap1);
	int rct2 = ActionPatterns::ap_count_optional_clauses(ap2);

	if (rct1 > rct2) return 1;
	if (rct1 < rct2) return -1;
	if (rct1 == 0) return 0;
	if (ap1->chief_action_owner_id != ap2->chief_action_owner_id) return 0;

	ap_optional_clause *apoc1 = ap1->optional_clauses, *apoc2 = ap2->optional_clauses;
	while ((apoc1) && (apoc2)) {
		int off1 = StackedVariables::get_offset(apoc1->stv_to_match);
		int off2 = StackedVariables::get_offset(apoc2->stv_to_match);
		if (off1 == off2) {
			int rv = Specifications::compare_specificity(apoc1->clause_spec, apoc2->clause_spec, NULL);
			if (rv != 0) return rv;
			apoc1 = apoc1->next;
			apoc2 = apoc2->next;
		}
		if (off1 < off2) apoc1 = apoc1->next;
		if (off1 > off2) apoc2 = apoc2->next;
	}
	return 0;
}

void ActionPatterns::log(action_pattern *ap) {
	if (ap == NULL) LOG("  [Null]");
	else {
		if (ap->valid != TRUE) LOG("  [Invalid]");
		else LOG("  [Valid]");
		LOG("  Action: ");
		if (ap->action_list == NULL) LOG("unspecified");
		else ActionNameLists::log_briefly(ap->action_list);
		if (ap->noun_spec) LOG("  Noun: $P", ap->noun_spec);
		if (ap->second_spec) LOG("  Second: $P", ap->second_spec);
		if (ap->from_spec) LOG("  From: $P", ap->from_spec);
		if (ap->to_spec) LOG("  To: $P", ap->to_spec);
		if (ap->by_spec) LOG("  By: $P", ap->by_spec);
		if (ap->through_spec) LOG("  Through: $P", ap->through_spec);
		if (ap->pushing_spec) LOG("  Pushing: $P", ap->pushing_spec);
		if (ap->room_spec) LOG("  Room: $P", ap->room_spec);
		if (ap->parameter_spec) LOG("  Parameter: $P", ap->parameter_spec);
		if (ap->presence_spec) LOG("  Presence: $P", ap->presence_spec);
		if (ap->nowhere_flag) LOG("  Nowhere  ");
		if (ap->when) LOG("  When: $P  ", ap->when);
		if (ap->duration) LOG("  Duration: $t  ", ap->duration);
	}
	LOG("\n");
}

void ActionPatterns::write(OUTPUT_STREAM, action_pattern *ap) {
	if (ap == NULL) WRITE("<null-ap>");
	else if (ap->valid != TRUE) WRITE("<invalid>");
	else {
		WRITE("<action: ");
		if (ap->action_list == NULL) WRITE("unspecified");
		else ActionNameLists::log_briefly(ap->action_list);
		if (ap->noun_spec) WRITE(" noun: %P", ap->noun_spec);
		if (ap->second_spec) WRITE(" second: %P", ap->second_spec);
		if (ap->from_spec) WRITE(" from: %P", ap->from_spec);
		if (ap->to_spec) WRITE(" to: %P", ap->to_spec);
		if (ap->by_spec) WRITE(" by: %P", ap->by_spec);
		if (ap->through_spec) WRITE(" through: %P", ap->through_spec);
		if (ap->pushing_spec) WRITE(" pushing: %P", ap->pushing_spec);
		if (ap->room_spec) WRITE(" room: %P", ap->room_spec);
		if (ap->parameter_spec) WRITE(" parameter: %P", ap->parameter_spec);
		if (ap->presence_spec) WRITE(" presence: %P", ap->presence_spec);
		if (ap->nowhere_flag) WRITE(" nowhere");
		if (ap->when) WRITE(" when: %P", ap->when);
		if (ap->duration) { WRITE(" duration: "); Occurrence::log(OUT, ap->duration); }
		WRITE(">");
	}
}

action_pattern *ActionPatterns::ap_store(action_pattern ap) {
	action_pattern *sap = CREATE(action_pattern);
	*sap = ap;
	return sap;
}

int ActionPatterns::is_named(action_pattern *ap) {
	if (ap) {
		anl_item *item = ActionNameLists::first_item(ap->action_list);
		if ((item) && (item->nap_listed)) return TRUE;
	}
	return FALSE;
}

int ActionPatterns::is_valid(action_pattern *ap) {
	if (ap == NULL) return FALSE;
	return ap->valid;
}

int ActionPatterns::is_request(action_pattern *ap) {
	if (ap == NULL) return FALSE;
	return ap->request;
}

int ActionPatterns::within_action_context(action_pattern *ap, action_name *an) {
	if (ap == NULL) return TRUE;
	return ActionNameLists::covers_action(ap->action_list, an);
}

action_name_list *ActionPatterns::list(action_pattern *ap) {
	if (ap == NULL) return NULL;
	return ap->action_list;
}

action_name *ActionPatterns::required_action(action_pattern *ap) {
	if (ap) return ActionNameLists::single_positive_action(ap->action_list);
	return NULL;
}

int ActionPatterns::object_based(action_pattern *ap) {
	if ((ap) && (ActionNameLists::nonempty(ap->action_list))) return TRUE;
	return FALSE;
}

int ActionPatterns::is_unspecific(action_pattern *ap) {
	action_name *an = ActionPatterns::required_action(ap);
	if (an == NULL) return TRUE;
	if ((ActionSemantics::must_have_noun(an)) && (ap->noun_spec == NULL)) return TRUE;
	if ((ActionSemantics::must_have_second(an)) && (ap->second_spec == NULL)) return TRUE;
	if ((ActionSemantics::can_have_noun(an)) &&
		(ActionPatterns::ap_clause_is_unspecific(ap->noun_spec))) return TRUE;
	if ((ActionSemantics::can_have_second(an)) &&
		(ActionPatterns::ap_clause_is_unspecific(ap->second_spec))) return TRUE;
	if (ActionPatterns::ap_clause_is_unspecific(ap->actor_spec)) return TRUE;
	return FALSE;
}

int ActionPatterns::ap_clause_is_unspecific(parse_node *spec) {
	if (spec == NULL) return FALSE;
	if (Specifications::is_description(spec) == FALSE) return FALSE;
	return TRUE;
}

int ActionPatterns::is_overspecific(action_pattern *ap) {
	if (ap->when != NULL) return TRUE;
	if (ap->room_spec != NULL) return TRUE;
	if (ap->presence_spec != NULL) return TRUE;
	if (ap->optional_clauses != NULL) return TRUE;
	if (ap->nowhere_flag) return TRUE;
	if (ap->applies_to_any_actor) return TRUE;
	if (ap->duration) return TRUE;
	return FALSE;
}

void ActionPatterns::suppress_action_testing(action_pattern *ap) {
	if (ap->duration == NULL) ap->test_anl = FALSE;
}

@ We are allowed to give names to certain kinds of behaviour by "categorising"
an action.

=
void ActionPatterns::categorise_as(action_pattern *ap, wording W) {
	LOGIF(ACTION_PATTERN_PARSING, "Categorising the action:\n$A...as %W\n", ap, W);

	if (<article>(W)) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_NamedAPIsArticle),
			"there's only an article here",
			"not a name, so I'm not sure what this action is supposed to be.");
		return;
	}

	if (ap->actor_spec) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_NamedAPWithActor),
			"behaviour characterised by named action patterns can only specify the action",
			"not the actor: as a result, it cannot include requests to other people to "
			"do things.");
		return;
	}

	NamedActionPatterns::add(ap, W);
}

parse_node *ActionPatterns::nullify_nonspecific_references(parse_node *spec) {
	if (spec == NULL) return spec;
	if (Node::is(spec, UNKNOWN_NT)) return NULL;
	return spec;
}

int ActionPatterns::check_going(parse_node *spec, char *keyword,
	kind *ka, kind *kb) {
	if (spec == NULL) return TRUE;
	if (Specifications::is_description_like(spec)) {
		instance *oref = Specifications::object_exactly_described_if_any(spec);
		if ((oref == NULL) || (ka == NULL) || (Instances::of_kind(oref, ka)) ||
			((kb) && (Instances::of_kind(oref, kb)))) return TRUE;
		Problems::quote_source(1, current_sentence);
		Problems::quote_object(2, oref);
		Problems::quote_text(3, keyword);
		Problems::quote_kind(4, ka);
		Problems::quote_kind(5, Instances::to_kind(oref));
		if (kb) Problems::quote_kind(6, kb);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_GoingWrongKind));
		if (kb)
		Problems::issue_problem_segment(
			"In the sentence %1, %2 seems to be intended as something the "
			"player might be going %3, but this has the wrong kind: %5 "
			"rather than %4 or %6.");
		else
		Problems::issue_problem_segment(
			"In the sentence %1, %2 seems to be intended as something the player "
			"might be going %3, but this has the wrong kind: %5 rather than %4.");
		Problems::issue_problem_end();
		return TRUE;
	}
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, Node::get_text(spec));
	Problems::quote_text(3, keyword);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_GoingWithoutObject));
	Problems::issue_problem_segment(
		"In the sentence %1, '%2' seems to be intended as something the player "
		"might be going %3, but it doesn't make sense in that context.");
	Problems::issue_problem_end();
	return FALSE;
}

@h Action pattern specificity.
The following is one of Inform's standardised comparison routines, which
takes a pair of objects A, B and returns 1 if A makes a more specific
description than B, 0 if they seem equally specific, or $-1$ if B makes a
more specific description than A. This is transitive, and intended to be
used in sorting algorithms.

=
int ActionPatterns::ap_count_rooms(action_pattern *ap) {
	int c = 0;
	if (ap->room_spec) c += 2;
	if (ap->from_spec) c += 2;
	if (ap->to_spec) c += 2;
	return c;
}

int ActionPatterns::ap_count_going(action_pattern *ap) {
	int c = 0;
	if (ap->pushing_spec) c += 2;
	if (ap->by_spec) c += 2;
	if (ap->through_spec) c += 2;
	return c;
}

int ActionPatterns::count_aspects(action_pattern *ap) {
	int c = 0;
	if (ap == NULL) return 0;
	if ((ap->pushing_spec) ||
		(ap->by_spec) ||
		(ap->through_spec))
		c++;
	if ((ap->room_spec) ||
		(ap->from_spec) ||
		(ap->to_spec))
		c++;
	if ((ap->nowhere_flag) ||
		(ap->noun_spec) ||
		(ap->second_spec) ||
		(ap->actor_spec))
		c++;
	if (ap->presence_spec) c++;
	if ((ap->duration) || (ap->when)) c++;
	if (ap->parameter_spec) c++;
	return c;
}

int ActionPatterns::compare_specificity(action_pattern *ap1, action_pattern *ap2) {
	int rv, suspend_usual_from_and_room = FALSE, rct1, rct2;

	if ((ap1 == NULL) && (ap2)) return -1;
	if ((ap1) && (ap2 == NULL)) return 1;
	if ((ap1 == NULL) && (ap2 == NULL)) return 0;

	LOGIF(SPECIFICITIES,
		"Comparing specificity of action patterns:\n(1) $A(2) $A\n", ap1, ap2);

	if ((ap1->valid == FALSE) && (ap2->valid != FALSE)) return -1;
	if ((ap1->valid != FALSE) && (ap2->valid == FALSE)) return 1;

	c_s_stage_law = I"III.1 - Object To Which Rule Applies";

	rv = Specifications::compare_specificity(ap1->parameter_spec, ap2->parameter_spec, NULL);
	if (rv != 0) return rv;

	c_s_stage_law = I"III.2.1 - Action/Where/Going In Exotic Ways";

	rct1 = ActionPatterns::ap_count_going(ap1); rct2 = ActionPatterns::ap_count_going(ap2);
	if (rct1 > rct2) return 1;
	if (rct1 < rct2) return -1;

	rv = Specifications::compare_specificity(ap1->pushing_spec, ap2->pushing_spec, NULL);
	if (rv != 0) return rv;

	rv = Specifications::compare_specificity(ap1->by_spec, ap2->by_spec, NULL);
	if (rv != 0) return rv;

	rv = Specifications::compare_specificity(ap1->through_spec, ap2->through_spec, NULL);
	if (rv != 0) return rv;

	c_s_stage_law = I"III.2.2 - Action/Where/Room Where Action Takes Place";

	rct1 = ActionPatterns::ap_count_rooms(ap1); rct2 = ActionPatterns::ap_count_rooms(ap2);
	if (rct1 > rct2) return 1;
	if (rct1 < rct2) return -1;

	if ((ap1->from_spec) && (ap1->room_spec == NULL)
		&& (ap2->room_spec) && (ap2->from_spec == NULL)) {
		rv = Specifications::compare_specificity(ap1->from_spec, ap2->room_spec, NULL);
		if (rv != 0) return rv;
		suspend_usual_from_and_room = TRUE;
	}

	if ((ap2->from_spec) && (ap2->room_spec == NULL)
		&& (ap1->room_spec) && (ap1->from_spec == NULL)) {
		rv = Specifications::compare_specificity(ap1->room_spec, ap2->from_spec, NULL);
		if (rv != 0) return rv;
		suspend_usual_from_and_room = TRUE;
	}

	if (suspend_usual_from_and_room == FALSE) {
		rv = Specifications::compare_specificity(ap1->from_spec, ap2->from_spec, NULL);
		if (rv != 0) return rv;
	}

	if (suspend_usual_from_and_room == FALSE) {
		rv = Specifications::compare_specificity(ap1->room_spec, ap2->room_spec, NULL);
		if (rv != 0) return rv;
	}

	rv = Specifications::compare_specificity(ap1->to_spec, ap2->to_spec, NULL);
	if (rv != 0) return rv;

	c_s_stage_law = I"III.2.3 - Action/Where/In The Presence Of";

	rv = Specifications::compare_specificity(ap1->presence_spec, ap2->presence_spec, NULL);
	if (rv != 0) return rv;

	c_s_stage_law = I"III.2.4 - Action/Where/Other Optional Clauses";

	rv = ActionPatterns::compare_specificity_of_apoc_list(ap1, ap2);
	if (rv != 0) return rv;

	c_s_stage_law = I"III.3.1 - Action/What/Second Thing Acted On";

	rv = Specifications::compare_specificity(ap1->second_spec, ap2->second_spec, NULL);
	if (rv != 0) return rv;

	c_s_stage_law = I"III.3.2 - Action/What/Thing Acted On";

	rv = Specifications::compare_specificity(ap1->noun_spec, ap2->noun_spec, NULL);
	if (rv != 0) return rv;

	if ((ap1->nowhere_flag) && (ap2->nowhere_flag == FALSE)) return -1;
	if ((ap1->nowhere_flag == FALSE) && (ap2->nowhere_flag)) return 1;

	c_s_stage_law = I"III.3.3 - Action/What/Actor Performing Action";

	rv = Specifications::compare_specificity(ap1->actor_spec, ap2->actor_spec, NULL);
	if (rv != 0) return rv;

	c_s_stage_law = I"III.4.1 - Action/How/What Happens";

	rv = ActionNameLists::compare_specificity(ap1->action_list, ap2->action_list);
	if (rv != 0) return rv;

	c_s_stage_law = I"III.5.1 - Action/When/Duration";

	rv = Occurrence::compare_specificity(ap1->duration, ap2->duration);
	if (rv != 0) return rv;

	c_s_stage_law = I"III.5.2 - Action/When/Circumstances";

	rv = Conditions::compare_specificity_of_CONDITIONs(ap1->when, ap2->when);
	if (rv != 0) return rv;

	c_s_stage_law = I"III.6.1 - Action/Name/Is This Named";

	if ((ActionPatterns::is_named(ap1)) && (ActionPatterns::is_named(ap2) == FALSE))
		return 1;
	if ((ActionPatterns::is_named(ap1) == FALSE) && (ActionPatterns::is_named(ap2)))
		return -1;
	return 0;
}

@ And an anticlimactic little routine for putting objects
into action patterns in the noun or second noun position.

=
void ActionPatterns::put_action_object_into_ap(action_pattern *ap, int pos, wording W) {
	parse_node *spec = NULL;
	int any_flag = FALSE;
	if (<action-operand>(W)) {
		if (<<r>>) spec = <<rp>>;
		else { any_flag = TRUE; spec = Specifications::from_kind(K_thing); }
	}
	if (spec == NULL) spec = Specifications::new_UNKNOWN(W);
	if ((K_understanding) && (Rvalues::is_CONSTANT_of_kind(spec, K_text)))
		Node::set_kind_of_value(spec, K_understanding);
	Node::set_text(spec, W);
	LOGIF(ACTION_PATTERN_PARSING, "PAOIA (position %d) %W = $P\n", pos, W, spec);
	switch(pos) {
		case 1: ap->noun_spec = spec; ap->noun_any = any_flag; break;
		case 2: ap->second_spec = spec; ap->second_any = any_flag; break;
		case 3: ap->room_spec = spec; ap->room_any = any_flag; break;
	}
}

@ =
int ActionPatterns::refers_to_past(action_pattern *ap) {
	if (ap->duration) return TRUE;
	return FALSE;
}

void ActionPatterns::convert_to_present_tense(action_pattern *ap) {
	ap->duration = NULL;
}

int ActionPatterns::pta_acceptable(parse_node *spec) {
	instance *I;
	if (spec == NULL) return TRUE;
	if (Specifications::is_description(spec) == FALSE) return TRUE;
	I = Specifications::object_exactly_described_if_any(spec);
	if (I) return TRUE;
	return FALSE;
}

int ActionPatterns::makes_callings(action_pattern *ap) {
	if (Descriptions::makes_callings(ap->noun_spec)) return TRUE;
	if (Descriptions::makes_callings(ap->second_spec)) return TRUE;
	if (Descriptions::makes_callings(ap->actor_spec)) return TRUE;
	if (Descriptions::makes_callings(ap->room_spec)) return TRUE;
	if (Descriptions::makes_callings(ap->parameter_spec)) return TRUE;
	if (Descriptions::makes_callings(ap->presence_spec)) return TRUE;
	return FALSE;
}

@ =
int ActionPatterns::is_an_action_variable(parse_node *spec) {
	nonlocal_variable *nlv;
	if (spec == NULL) return FALSE;
	if (Lvalues::get_storage_form(spec) != NONLOCAL_VARIABLE_NT) return FALSE;
	nlv = Node::get_constant_nonlocal_variable(spec);
	if (nlv == I6_noun_VAR) return TRUE;
	if (nlv == I6_second_VAR) return TRUE;
	if (nlv == I6_actor_VAR) return TRUE;
	return FALSE;
}
