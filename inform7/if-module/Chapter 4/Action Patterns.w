[PL::Actions::Patterns::] Action Patterns.

An action pattern is a description which may match many actions or
none. The text "doing something" matches every action, while "throwing
something at a door in a dark room" is seldom matched. Here we parse such
text into a data structure called an |action_pattern|.

@h Definitions.

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

	struct action_name_list *action; /* what the behaviour is */
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
	struct time_period duration; /* to hold "for the third time", etc. */

	struct parse_node *parameter_spec; /* alternatively, just this */
	struct kind *parameter_kind; /* of this expected kind */

	int valid; /* recording success or failure in parsing to an AP */

	struct parse_node *entered_into_NAP_here; /* sentence adding it to named behaviour */
	struct action_pattern *next; /* for forming APs into linked lists */
} action_pattern;

typedef struct ap_optional_clause {
	struct stacked_variable *stv_to_match;
	struct parse_node *clause_spec;
	int allow_region_as_room;
	struct ap_optional_clause *next;
	MEMORY_MANAGEMENT
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
action_pattern PL::Actions::Patterns::new(void) {
	action_pattern ap;
	ap.text_of_pattern = EMPTY_WORDING;
	ap.action = NULL;
	ap.test_anl = TRUE;
	ap.actor_spec = NULL;
	ap.noun_spec = NULL; ap.second_spec = NULL; ap.room_spec = NULL;
	ap.noun_any = FALSE; ap.second_any = FALSE; ap.room_any = FALSE;
	ap.parameter_spec = NULL;
	ap.parameter_kind = K_object;
	ap.valid = FALSE;
	ap.next = NULL;
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
	ap.duration = Occurrence::new();
	ap.optional_clauses = NULL;
	ap.chief_action_owner_id = 0;
	ap.entered_into_NAP_here = NULL;
	return ap;
}

ap_optional_clause *PL::Actions::Patterns::apoc_new(stacked_variable *stv, parse_node *spec) {
	ap_optional_clause *apoc = CREATE(ap_optional_clause);
	apoc->stv_to_match = stv;
	apoc->clause_spec = spec;
	apoc->next = NULL;
	apoc->allow_region_as_room = FALSE;
	return apoc;
}

void PL::Actions::Patterns::ap_add_optional_clause(action_pattern *ap, ap_optional_clause *apoc) {
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

int PL::Actions::Patterns::ap_count_optional_clauses(action_pattern *ap) {
	int n = 0;
	ap_optional_clause *apoc;
	for (apoc = ap->optional_clauses; apoc; apoc = apoc->next) {
		if ((ap->chief_action_owner_id != 20007) ||
			(StackedVariables::get_offset(apoc->stv_to_match) >= 5))
			n++;
	}
	return n;
}

int PL::Actions::Patterns::compare_specificity_of_apoc_list(action_pattern *ap1, action_pattern *ap2) {
	int rct1 = PL::Actions::Patterns::ap_count_optional_clauses(ap1);
	int rct2 = PL::Actions::Patterns::ap_count_optional_clauses(ap2);

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

void PL::Actions::Patterns::log(action_pattern *ap) {
	if (ap == NULL) LOG("  [Null]");
	else {
		if (ap->valid != TRUE) LOG("  [Invalid]");
		else LOG("  [Valid]");
		LOG("  Action: ");
		if (ap->action == NULL) LOG("unspecified");
		else PL::Actions::Lists::log_briefly(ap->action);
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
		if (ap->when)
			LOG("  When: $P  ", ap->when);
		if (Occurrence::is_valid(&(ap->duration)))
			LOG("  Duration: $t  ", &(ap->duration));
	}
	LOG("\n");
}

action_pattern *PL::Actions::Patterns::ap_store(action_pattern ap) {
	action_pattern *sap = CREATE(action_pattern);
	*sap = ap;
	return sap;
}

int PL::Actions::Patterns::is_named(action_pattern *ap) {
	if (ap == NULL) return FALSE;
	if (ap->action == NULL) return FALSE;
	if (ap->action->nap_listed == NULL) return FALSE;
	return TRUE;
}

int PL::Actions::Patterns::is_valid(action_pattern *ap) {
	if (ap == NULL) return FALSE;
	return ap->valid;
}

int PL::Actions::Patterns::is_request(action_pattern *ap) {
	if (ap == NULL) return FALSE;
	return ap->request;
}

int PL::Actions::Patterns::within_action_context(action_pattern *ap, action_name *an) {
	action_name_list *anl;
	if (ap == NULL) return TRUE;
	if (ap->action == NULL) return TRUE;
	if (ap->action->nap_listed)
		return PL::Actions::Patterns::Named::within_action_context(ap->action->nap_listed, an);
	for (anl = ap->action; anl; anl = anl->next)
		if (((anl->action_listed == an) && (anl->parity == 1)) ||
			((anl->action_listed != an) && (anl->parity == -1)))
			return TRUE;
	return FALSE;
}

action_name_list *PL::Actions::Patterns::list(action_pattern *ap) {
	if (ap == NULL) return NULL;
	return ap->action;
}

action_name *PL::Actions::Patterns::required_action(action_pattern *ap) {
	if ((ap->action) && (ap->action->next == NULL) && (ap->action->parity == 1) && (ap->action->negate_pattern == FALSE))
		return ap->action->action_listed;
	return NULL;
}

int PL::Actions::Patterns::object_based(action_pattern *ap) {
	if ((ap) && (ap->action)) return TRUE;
	return FALSE;
}

int PL::Actions::Patterns::is_unspecific(action_pattern *ap) {
	action_name *an = PL::Actions::Patterns::required_action(ap);
	if (an == NULL) return TRUE;
	int N = PL::Actions::get_min_parameters(an);
	if ((N > 0) && (ap->noun_spec == NULL)) return TRUE;
	if ((N > 1) && (ap->second_spec == NULL)) return TRUE;
	N = PL::Actions::get_max_parameters(an);
	if ((N > 0) && (PL::Actions::Patterns::ap_clause_is_unspecific(ap->noun_spec))) return TRUE;
	if ((N > 1) && (PL::Actions::Patterns::ap_clause_is_unspecific(ap->second_spec))) return TRUE;
	if (PL::Actions::Patterns::ap_clause_is_unspecific(ap->actor_spec)) return TRUE;
	return FALSE;
}

int PL::Actions::Patterns::ap_clause_is_unspecific(parse_node *spec) {
	if (spec == NULL) return FALSE;
	if (Specifications::is_description(spec) == FALSE) return FALSE;
	return TRUE;
}

int PL::Actions::Patterns::is_overspecific(action_pattern *ap) {
	if (ap->when != NULL) return TRUE;
	if (ap->room_spec != NULL) return TRUE;
	if (ap->presence_spec != NULL) return TRUE;
	if (ap->optional_clauses != NULL) return TRUE;
	if (ap->nowhere_flag) return TRUE;
	if (ap->applies_to_any_actor) return TRUE;
	if (Occurrence::is_valid(&(ap->duration))) return TRUE;
	return FALSE;
}

void PL::Actions::Patterns::suppress_action_testing(action_pattern *ap) {
	if (Occurrence::is_valid(&(ap->duration)) == FALSE) ap->test_anl = FALSE;
}

@ We are allowed to give names to certain kinds of behaviour by "categorising"
an action.

=
void PL::Actions::Patterns::categorise_as(action_pattern *ap, wording W) {
	LOGIF(ACTION_PATTERN_PARSING, "Categorising the action:\n$A...as %W\n", ap, W);

	if (<article>(W)) {
		Problems::Issue::sentence_problem(_p_(PM_NamedAPIsArticle),
			"there's only an article here",
			"not a name, so I'm not sure what this action is supposed to be.");
		return;
	}

	if (ap->actor_spec) {
		Problems::Issue::sentence_problem(_p_(PM_NamedAPWithActor),
			"behaviour characterised by named action patterns can only specify the action",
			"not the actor: as a result, it cannot include requests to other people to "
			"do things.");
		return;
	}

	PL::Actions::Patterns::Named::add(ap, W);
}

parse_node *PL::Actions::Patterns::nullify_nonspecific_references(parse_node *spec) {
	if (spec == NULL) return spec;
	if (ParseTree::is(spec, UNKNOWN_NT)) return NULL;
	return spec;
}

int PL::Actions::Patterns::check_going(parse_node *spec, char *keyword,
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
		Problems::Issue::handmade_problem(_p_(PM_GoingWrongKind));
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
	Problems::quote_wording(2, ParseTree::get_text(spec));
	Problems::quote_text(3, keyword);
	Problems::Issue::handmade_problem(_p_(PM_GoingWithoutObject));
	Problems::issue_problem_segment(
		"In the sentence %1, '%2' seems to be intended as something the player "
		"might be going %3, but it doesn't make sense in that context.");
	Problems::issue_problem_end();
	return FALSE;
}

@ First a much easier, parametric form of parsing, used for the APs which
form the usage conditions for rules in object-based rulebooks.

=
action_pattern PL::Actions::Patterns::parse_parametric(wording W, kind *K) {
	action_pattern ap = PL::Actions::Patterns::new();
	ap.parameter_spec = PL::Actions::Patterns::parse_action_parameter(W);
	ap.parameter_kind = K;
	ap.valid = Dash::validate_parameter(ap.parameter_spec, K);
	return ap;
}

@ A useful utility: parsing a parameter in an action pattern.

=
parse_node *PL::Actions::Patterns::parse_action_parameter(wording W) {
	if (<action-parameter>(W)) return <<rp>>;
	return Specifications::new_UNKNOWN(W);
}

parse_node *PL::Actions::Patterns::parse_verified_action_parameter(wording W) {
	parse_node *spec = PL::Actions::Patterns::parse_action_parameter(W);
	if (ParseTree::is(spec, UNKNOWN_NT)) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, W);
		Problems::Issue::handmade_problem(_p_(PM_BadOptionalAPClause));
		Problems::issue_problem_segment(
			"In %1, I tried to read a description of an action - a complicated "
			"one involving optional clauses; but '%2' wasn't something I "
			"recognised.");
		Problems::issue_problem_end();
	}
	return spec;
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
	asking <action-parameter> to try <action-pattern-core> |				==> ACTOR_REQUESTED; *XP = RP[2]; action_pattern *ap = *XP; ap->request = TRUE; ap->actor_spec = RP[1];
	<action-parameter> trying <action-pattern-core> |						==> ACTOR_NAMED; *XP = RP[2]; ap = *XP; ap->request = FALSE; ap->actor_spec = RP[1];
	an actor trying <action-pattern-core> |												==> ACTOR_EXPLICITLY_UNIVERSAL; *XP = RP[1]; ap = *XP; ap->applies_to_any_actor = TRUE;
	an actor <action-pattern-core> |													==> ACTOR_EXPLICITLY_UNIVERSAL; *XP = RP[1]; ap = *XP; ap->applies_to_any_actor = TRUE;
	trying <action-pattern-core> |														==> ACTOR_EXPLICITLY_PLAYER; *XP = RP[1];
	<action-pattern-core-actor>															==> ACTOR_IMPLICITLY_PLAYER; *XP = RP[1];

@ The second version is for contexts where the AP occurs as a condition: e.g.,
in a sentence like "if we have taken a jewel". Since these can occur in
both tenses and can be negated ("if we are not taking a jewel"), there are
four combinations:

=
<we-are-action-pattern> ::=
	we are asking <action-parameter> to try <action-pattern-core> |		==> ACTOR_REQUESTED; *XP = RP[2]; action_pattern *ap = *XP; ap->request = TRUE; ap->actor_spec = RP[1];
	asking <action-parameter> to try <action-pattern-core> |				==> ACTOR_REQUESTED; *XP = RP[2]; ap = *XP; ap->request = TRUE; ap->actor_spec = RP[1];
	<action-parameter> trying <action-pattern-core> |						==> ACTOR_NAMED; *XP = RP[2]; ap = *XP; ap->request = FALSE; ap->actor_spec = RP[1];
	an actor trying <action-pattern-core> |												==> ACTOR_EXPLICITLY_UNIVERSAL; *XP = RP[1]; ap = *XP; ap->applies_to_any_actor = TRUE;
	an actor <action-pattern-core> |													==> ACTOR_EXPLICITLY_UNIVERSAL; *XP = RP[1]; ap = *XP; ap->applies_to_any_actor = TRUE;
	we are trying <action-pattern-core> |												==> ACTOR_EXPLICITLY_PLAYER; *XP = RP[1];
	trying <action-pattern-core> |														==> ACTOR_EXPLICITLY_PLAYER; *XP = RP[1];
	we are <action-pattern-core> |														==> ACTOR_EXPLICITLY_PLAYER; *XP = RP[1];
	<action-pattern-core-actor>															==> ACTOR_IMPLICITLY_PLAYER; *XP = RP[1];

<action-pattern-negated> ::=
	we are not asking <action-parameter> to try <action-pattern-core> |	==> ACTOR_REQUESTED; *XP = RP[2]; action_pattern *ap = *XP; ap->request = TRUE; ap->actor_spec = RP[1];
	not asking <action-parameter> to try <action-pattern-core> |			==> ACTOR_REQUESTED; *XP = RP[2]; ap = *XP; ap->request = TRUE; ap->actor_spec = RP[1];
	<action-parameter> not trying <action-pattern-core> |					==> ACTOR_NAMED; *XP = RP[2]; ap = *XP; ap->request = FALSE; ap->actor_spec = RP[1];
	an actor not trying <action-pattern-core> |											==> ACTOR_EXPLICITLY_UNIVERSAL; *XP = RP[1]; ap = *XP; ap->applies_to_any_actor = TRUE;
	an actor not <action-pattern-core> |												==> ACTOR_EXPLICITLY_UNIVERSAL; *XP = RP[1]; ap = *XP; ap->applies_to_any_actor = TRUE;
	we are not trying <action-pattern-core> |											==> ACTOR_EXPLICITLY_PLAYER; *XP = RP[1];
	not trying <action-pattern-core> |													==> ACTOR_EXPLICITLY_PLAYER; *XP = RP[1];
	we are not <action-pattern-core> |													==> ACTOR_EXPLICITLY_PLAYER; *XP = RP[1];
	not <action-pattern-core-actor>														==> ACTOR_IMPLICITLY_PLAYER; *XP = RP[1];

<action-pattern-past> ::=
	we have asked <action-parameter> to try <action-pattern-core> |		==> ACTOR_REQUESTED; *XP = RP[2]; action_pattern *ap = *XP; ap->request = TRUE; ap->actor_spec = RP[1];
	<action-parameter> has tried <action-pattern-core> |					==> ACTOR_NAMED; *XP = RP[2]; ap = *XP; ap->request = FALSE; ap->actor_spec = RP[1];
	an actor has tried <action-pattern-core> |											==> ACTOR_EXPLICITLY_UNIVERSAL; *XP = RP[1]; ap = *XP; ap->applies_to_any_actor = TRUE;
	an actor has <action-pattern-past-core> |											==> ACTOR_EXPLICITLY_UNIVERSAL; *XP = RP[1]; ap = *XP; ap->applies_to_any_actor = TRUE;
	we have tried <action-pattern-core> |												==> ACTOR_EXPLICITLY_PLAYER; *XP = RP[1];
	we have <action-pattern-past-core>													==> ACTOR_EXPLICITLY_PLAYER; *XP = RP[1];

<action-pattern-past-negated> ::=
	we have not asked <action-parameter> to try <action-pattern-core> |	==> ACTOR_REQUESTED; *XP = RP[2]; action_pattern *ap = *XP; ap->request = TRUE; ap->actor_spec = RP[1];
	<action-parameter> has not tried <action-pattern-core> |				==> ACTOR_NAMED; *XP = RP[2]; ap = *XP; ap->request = FALSE; ap->actor_spec = RP[1];
	an actor has not tried <action-pattern-core> |										==> ACTOR_EXPLICITLY_UNIVERSAL; *XP = RP[1]; ap = *XP; ap->applies_to_any_actor = TRUE;
	an actor has not <action-pattern-past-core> |										==> ACTOR_EXPLICITLY_UNIVERSAL; *XP = RP[1]; ap = *XP; ap->applies_to_any_actor = TRUE;
	we have not tried <action-pattern-core> |											==> ACTOR_EXPLICITLY_PLAYER; *XP = RP[1];
	we have not <action-pattern-past-core>												==> ACTOR_EXPLICITLY_PLAYER; *XP = RP[1];

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
	<action-pattern-core> |									==> ACTOR_IMPLICITLY_PLAYER; *XP = RP[1];
	<actor-description> <action-pattern-core> 				==> ACTOR_NAMED; *XP = RP[2]; action_pattern *ap = *XP; ap->request = FALSE; ap->actor_spec = RP[1];

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
					int old_state = PL::Actions::Patterns::suppress();
					if (<action-parameter>(Wordings::up_to(W, i-1))) try_stem = <<rp>>;
					PL::Actions::Patterns::resume(old_state);
					int k = 0;
					LOOP_THROUGH_WORDING(j, Wordings::up_to(W, i-1))
						if (Vocabulary::test_flags(j, ACTION_PARTICIPLE_MC)) k++;
					if (k>0) continue;
					I = Rvalues::to_object_instance(try_stem);
					if (Instances::full_name_includes(I, Lexer::word(i))) continue;
					if ((Lvalues::get_storage_form(try_stem) == LOCAL_VARIABLE_NT) ||
						(Lvalues::get_storage_form(try_stem) == NONLOCAL_VARIABLE_NT) ||
						(ParseTree::is(try_stem, CONSTANT_NT)) ||
						(Specifications::is_description(try_stem))) {
						*XP = try_stem;
						return i-1;
					}
				}
			}
	}
	return 0;
}

@ =
int PL::Actions::Patterns::suppress(void) {
	int old_state = suppress_ap_parsing;
	suppress_ap_parsing = TRUE;
	return old_state;
}

void PL::Actions::Patterns::resume(int old_state) {
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
	action_pattern *ap = PL::Actions::Patterns::ap_parse_inner(W, IS_TENSE);
	if (ap) { *XP = ap; return TRUE; }
	return FALSE;
}

<action-pattern-past-core> internal {
	action_pattern *ap = PL::Actions::Patterns::ap_parse_inner(W, HASBEEN_TENSE);
	if (ap) { *XP = ap; return TRUE; }
	return FALSE;
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
action_pattern *PL::Actions::Patterns::ap_parse_inner(wording W, int tense) {
	if (Lexer::word(Wordings::first_wn(W)) == OPENBRACE_V) return NULL;

	if (Wordings::empty(W)) internal_error("PAP on illegal word range");
	unsigned int d = Vocabulary::disjunction_of_flags(W);
	if (((tense == IS_TENSE) && ((d & (ACTION_PARTICIPLE_MC+NAMED_AP_MC)) == 0))) {
		pap_failure_reason = NOPARTICIPLE_PAPF;
		return NULL;
	}
	LOGIF(ACTION_PATTERN_PARSING, "Parse action pattern (tense %d): %W\n", tense, W);
	int duration_set = FALSE;
	time_period duration = Occurrence::parse(W);
	if (Occurrence::is_valid(&duration)) {
		W = Wordings::up_to(W, Occurrence::is_valid(&duration));
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
	if ((duration_set) && (ap)) ap->duration = duration;
	LOGIF(ACTION_PATTERN_PARSING, "PAP result (pfr %d): $A\n", pap_failure_reason, ap);
	return ap;
}

@ Anyway, we are now down to level 3: all action patterns have been whittled
down to a single use of <ap-common-core>. Our next step is to recognise
a condition attached with "when":

=
<ap-common-core> ::=
	<ap-common-core-inner> when/while <condition-in-ap> |	==> 0; *XP = RP[1]; action_pattern *ap = *XP; ap->when = RP[2]; if (pap_failure_reason == MISC_PAPF) pap_failure_reason = WHENOKAY_PAPF;
	<ap-common-core-inner> |								==> 0; *XP = RP[1];
	... when/while <condition-in-ap> |						==> 0; pap_failure_reason = WHENOKAY_PAPF; return FALSE; /* used only to diagnose problems */
	... when/while ...										==> 0; if (pap_failure_reason != WHENOKAY_PAPF) pap_failure_reason = WHEN_PAPF; return FALSE; /* used only to diagnose problems */

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
		*XP = wts;
		return TRUE;
	}
	return FALSE;
}

@ Level 4 now. The optional "in the presence of":

=
<ap-common-core-inner> ::=
	<ap-common-core-inner-inner> in the presence of <action-parameter> |	==> 0; *XP = RP[1]; action_pattern *ap = *XP; ap->presence_spec = RP[2];
	<ap-common-core-inner-inner>											==> 0; *XP = RP[1];

@ Level 5 now. The initial "in" clause, e.g., "in the Pantry", requires
special handling to prevent it from clashing with other interpretations of
"in" elsewhere in the grammar. It's perhaps unexpected that "in the Pantry"
is valid as an AP, but this enables many natural-looking rules to be written
("Report rule in the Pantry: ...", say).

=
<ap-common-core-inner-inner> ::=
	in <action-parameter> |									==> @<Make an actionless action pattern, specifying room only@>
	<ap-common-core-inner-inner-inner>						==> 0; *XP = RP[1];

@<Make an actionless action pattern, specifying room only@> =
	if (Dash::validate_parameter(RP[1], K_object) == FALSE)
		return FALSE; /* the "room" isn't even an object */
	action_pattern ap = PL::Actions::Patterns::new();
	ap.valid = TRUE; ap.text_of_pattern = W;
	ap.room_spec = RP[1];
	*XP = PL::Actions::Patterns::ap_store(ap);

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
	if (Wordings::mismatched_brackets(W)) return FALSE;
	if (scanning_anl_only_mode) {
		action_name_list *anl = PL::Actions::Lists::parse(W, prevailing_ap_tense);
		if (anl == NULL) return FALSE;
		action_pattern ap = PL::Actions::Patterns::new(); ap.valid = TRUE;
		ap.text_of_pattern = W;
		ap.action = anl;
		*XP = PL::Actions::Patterns::ap_store(ap);
		return TRUE;
	} else {
		LOGIF(ACTION_PATTERN_PARSING, "Parsing action pattern: %W\n", W);
		LOG_INDENT;
		action_pattern ap = PL::Actions::Patterns::parse_action_pattern_dash(W);
		LOG_OUTDENT;
		if (PL::Actions::Patterns::is_valid(&ap)) {
			*XP = PL::Actions::Patterns::ap_store(ap);
			return TRUE;
		}
	}
	return FALSE;
}

@ The "operands" of an action pattern are the nouns to which it applies: for
example, in "Kevin taking or dropping something", the operand is "something".
We treat words like "something" specially to avoid them being read as
"some thing" and thus forcing the kind of the operand to be "thing".

=
<action-operand> ::=
	something/anything | 			==> FALSE
	something/anything else | 		==> FALSE
	<action-parameter> 				==> TRUE; *XP = RP[1]

<going-action-irregular-operand> ::=
	nowhere |						==> FALSE
	somewhere						==> TRUE

<understanding-action-irregular-operand> ::=
	something/anything |			==> TRUE
	it								==> FALSE

@ Finally, then, <action-parameter>. Almost anything syntactically matches
here -- a constant, a description, a table entry, a variable, and so on.

=
<action-parameter> ::=
	^<if-nonconstant-action-context> <s-local-variable> |	==> TRUE; return FAIL_NONTERMINAL
	^<if-nonconstant-action-context> <s-global-variable> |	==> TRUE; return FAIL_NONTERMINAL
	<s-local-variable> |									==> TRUE; *XP = RP[1]
	<s-global-variable>	|									==> TRUE; *XP = RP[1]
	<s-type-expression-or-value>							==> TRUE; *XP = RP[1]

<if-nonconstant-action-context> internal 0 {
	return permit_nonconstant_action_parameters;
}

@ We can't put it off any longer. Here goes.

=
action_pattern PL::Actions::Patterns::parse_action_pattern_dash(wording W) {
	int failure_this_call = pap_failure_reason;
	int i, j, k = 0;
	action_name_list *anl = NULL;
	int tense = prevailing_ap_tense;

	action_pattern ap = PL::Actions::Patterns::new(); ap.valid = FALSE;
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
	ap.action = anl;
	if ((anl != NULL) && (anl->nap_listed == NULL) && (anl->action_listed == NULL)) ap.action = NULL;
	ap.valid = TRUE;

	ap.actor_spec = PL::Actions::Patterns::nullify_nonspecific_references(ap.actor_spec);
	ap.noun_spec = PL::Actions::Patterns::nullify_nonspecific_references(ap.noun_spec);
	ap.second_spec = PL::Actions::Patterns::nullify_nonspecific_references(ap.second_spec);
	ap.room_spec = PL::Actions::Patterns::nullify_nonspecific_references(ap.room_spec);

	int ch = Plugins::Call::check_going(ap.from_spec, ap.to_spec, ap.by_spec, ap.through_spec, ap.pushing_spec);
	if (ch == FALSE) ap.valid = FALSE;

	if (ap.valid == FALSE) goto Failed;
	LOGIF(ACTION_PATTERN_PARSING, "Matched action pattern: $A\n", &ap);

@<No valid action pattern has been parsed@> =
	pap_failure_reason = failure_this_call;
	ap.valid = FALSE;
	ap.optional_clauses = NULL;
	ap.from_spec = NULL; ap.to_spec = NULL; ap.by_spec = NULL; ap.through_spec = NULL;
	ap.pushing_spec = NULL; ap.nowhere_flag = FALSE;
	LOGIF(ACTION_PATTERN_PARSING, "Parse action failed: %W\n", W);

@ Special clauses are allowed after "going..."; trim them
away as they are recorded.

@<PAR - (f) Parse Special Going Clauses@> =
	action_name_list *preliminary_anl =
		PL::Actions::Lists::parse(W, tense);
	action_name *chief_an =
		PL::Actions::Lists::get_single_action(preliminary_anl);
	if (chief_an == NULL) {
		int x;
		chief_an = PL::Actions::longest_null(W, tense, &x);
	}
	if (chief_an) {
		stacked_variable *last_stv_specified = NULL;
		i = Wordings::first_wn(W) + 1; j = -1;
		LOGIF(ACTION_PATTERN_PARSING, "Trying special clauses at <%W>\n", Wordings::new(i, Wordings::last_wn(W)));
		while (i < Wordings::last_wn(W)) {
			stacked_variable *stv = NULL;
			if (Word::unexpectedly_upper_case(i) == FALSE)
				stv = PL::Actions::parse_match_clause(chief_an, Wordings::new(i, Wordings::last_wn(W)));
			if (stv != NULL) {
				LOGIF(ACTION_PATTERN_PARSING,
					"Special clauses found on <%W>\n", Wordings::from(W, i));
				if (last_stv_specified == NULL) j = i-1;
				else PL::Actions::Patterns::ap_add_optional_clause(&ap,
					PL::Actions::Patterns::apoc_new(last_stv_specified, PL::Actions::Patterns::parse_verified_action_parameter(Wordings::new(k, i-1))));
				k = i+1;
				last_stv_specified = stv;
			}
			i++;
		}
		if (last_stv_specified != NULL)
			PL::Actions::Patterns::ap_add_optional_clause(&ap,
				PL::Actions::Patterns::apoc_new(last_stv_specified, PL::Actions::Patterns::parse_verified_action_parameter(Wordings::new(k, Wordings::last_wn(W)))));
		if (j >= 0) W = Wordings::up_to(W, j);
	}

@ Extract the information as to which actions are intended:
e.g., from "taking or dropping something", that it will be
taking or dropping.

@<PAR - (i) Parse Initial Action Name List@> =
	anl = PL::Actions::Lists::parse(W, tense);
	if (anl == NULL) goto Failed;
	LOGIF(ACTION_PATTERN_PARSING, "ANL from PAR(i):\n$L\n", anl);

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

	action_name_list *entry = anl;
	int first_position = anl->word_position;
	action_name_list *first_valid = NULL;
	action_pattern trial_ap;
	for (entry = anl; entry; entry = entry->next) {
	LOGIF(ACTION_PATTERN_PARSING, "Entry (%d):\n$L\n", entry->parc, entry);
		@<Fill out the noun, second, room and nowhere fields of the AP as if this action were right@>;
		@<Check the validity of this speculative AP@>;
		if ((trial_ap.valid) && (first_valid == NULL) && (entry->word_position == first_position)) {
			first_valid = entry;
			ap.noun_spec = trial_ap.noun_spec; ap.second_spec = trial_ap.second_spec;
			ap.room_spec = trial_ap.room_spec; ap.nowhere_flag = trial_ap.nowhere_flag;
			ap.valid = TRUE;
		}
		if (trial_ap.valid == FALSE) entry->delete_this_link = TRUE;
	}
	if (first_valid == NULL) goto Failed;

	@<Adjudicate between topic and other actions@>;
	LOGIF(ACTION_PATTERN_PARSING, "List before action winnowing:\n$L\n", anl);
	@<Delete those action names which are to be deleted@>;
	LOGIF(ACTION_PATTERN_PARSING, "List after action winnowing:\n$L\n", anl);

@ For example, "taking inventory or waiting" produces two positions, words
0 and 3, and minimum parameter count 0 in each case. ("Taking inventory"
can be read as "taking (inventory)", par-count 1, or "taking inventory",
par-count 0, so the minimum is 0.)

@<Find the positions of individual action names, and their minimum parameter counts@> =
	action_name_list *entry;
	for (entry = anl; entry; entry = entry->next) {
		int pos = -1;
		@<Find the position word of this particular action name@>;
		if ((position_min_parc[pos] == UNTHINKABLE_POSITION) ||
			(entry->parc < position_min_parc[pos]))
			position_min_parc[pos] = entry->parc;
	}

@<Find the position word of this particular action name@> =
	int i;
	for (i=0; i<no_positions; i++)
		if (entry->word_position == position_at[i])
			pos = i;
	if (pos == -1) {
		if (no_positions == MAX_AP_POSITIONS) goto Failed;
		position_at[no_positions] = entry->word_position;
		position_min_parc[no_positions] = UNTHINKABLE_POSITION;
		pos = no_positions++;
	}

@<Report to the debugging log on the action decomposition@> =
	LOGIF(ACTION_PATTERN_PARSING, "List after action decomposition:\n$L\n", anl);
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
	trial_ap.noun_spec = NULL; trial_ap.second_spec = NULL; trial_ap.room_spec = NULL; trial_ap.nowhere_flag = FALSE;
	if (entry->parc >= 1) {
		if (Wordings::nonempty(entry->parameter[0])) {
			if ((entry->action_listed == going_action) && (<going-action-irregular-operand>(entry->parameter[0]))) {
				if (<<r>> == FALSE) trial_ap.nowhere_flag = TRUE;
				else trial_ap.nowhere_flag = 2;
			} else PL::Actions::Patterns::put_action_object_into_ap(&trial_ap, 1, entry->parameter[0]);
		}
	}

	if (entry->parc >= 2) {
		if (Wordings::nonempty(entry->parameter[1])) {
			if ((entry->action_listed != NULL)
				&& (Kinds::Compare::eq(PL::Actions::get_data_type_of_second_noun(entry->action_listed), K_understanding))
				&& (<understanding-action-irregular-operand>(entry->parameter[1]))) {
				trial_ap.second_spec = Rvalues::from_grammar_verb(NULL); /* Why no GV here? */
				ParseTree::set_text(trial_ap.second_spec, entry->parameter[1]);
			} else {
				PL::Actions::Patterns::put_action_object_into_ap(&trial_ap, 2, entry->parameter[1]);
			}
		}
	}

	if (Wordings::nonempty(entry->in_clause))
		PL::Actions::Patterns::put_action_object_into_ap(&trial_ap, 3, entry->in_clause);

@<Check the validity of this speculative AP@> =
	kind *check_n = K_object;
	kind *check_s = K_object;
	if (entry->action_listed != NULL) {
		check_n = PL::Actions::get_data_type_of_noun(entry->action_listed);
		check_s = PL::Actions::get_data_type_of_second_noun(entry->action_listed);
	}
	trial_ap.valid = TRUE;
	if ((trial_ap.noun_any == FALSE) &&
		(Dash::validate_parameter(trial_ap.noun_spec, check_n) == FALSE))
		trial_ap.valid = FALSE;
	if ((trial_ap.second_any == FALSE) &&
		(Dash::validate_parameter(trial_ap.second_spec, check_s) == FALSE))
		trial_ap.valid = FALSE;
	if ((trial_ap.room_any == FALSE) &&
		(Dash::validate_parameter(trial_ap.room_spec, K_object) == FALSE))
		trial_ap.valid = FALSE;

@<Adjudicate between topic and other actions@> =
	kind *K[2];
	K[0] = NULL; K[1] = NULL;
	action_name_list *entry, *prev = NULL;
	for (entry = anl; entry; prev = entry, entry = entry->next) {
		if ((entry->delete_this_link == FALSE) && (entry->action_listed)) {
			if ((prev == NULL) || (prev->word_position != entry->word_position)) {
				if ((entry->next == NULL) || (entry->next->word_position != entry->word_position)) {
					if ((K[0] == NULL) && (PL::Actions::get_max_parameters(entry->action_listed) >= 1))
						K[0] = PL::Actions::get_data_type_of_noun(entry->action_listed);
					if ((K[1] == NULL) && (PL::Actions::get_max_parameters(entry->action_listed) >= 2))
						K[1] = PL::Actions::get_data_type_of_second_noun(entry->action_listed);
				}
			}
		}
	}
	LOGIF(ACTION_PATTERN_PARSING, "Necessary kinds: $u, $u\n", K[0], K[1]);
	for (entry = anl; entry; prev = entry, entry = entry->next) {
		if ((entry->delete_this_link == FALSE) && (entry->action_listed)) {
			int poor_choice = FALSE;
			if ((K[0]) && (PL::Actions::get_max_parameters(entry->action_listed) >= 1)) {
				kind *L = PL::Actions::get_data_type_of_noun(entry->action_listed);
				if (Kinds::Compare::compatible(L, K[0]) == FALSE) poor_choice = TRUE;
			}
			if ((K[1]) && (PL::Actions::get_max_parameters(entry->action_listed) >= 2)) {
				kind *L = PL::Actions::get_data_type_of_second_noun(entry->action_listed);
				if (Kinds::Compare::compatible(L, K[1]) == FALSE) poor_choice = TRUE;
			}
			if (poor_choice) {
				if (((prev) && (prev->word_position == entry->word_position) &&
					(prev->delete_this_link == FALSE))
					||
					((entry->next) && (entry->next->word_position == entry->word_position) &&
					(entry->next->delete_this_link == FALSE)))
					entry->delete_this_link = TRUE;
			}
		}
	}

@<Delete those action names which are to be deleted@> =
	action_name_list *entry, *prev = NULL;
	int pos = -1, negation_state = (anl)?(anl->negate_pattern):FALSE;
	for (entry = anl; entry; entry = entry->next) {
		if ((entry->delete_this_link) || (pos == entry->word_position)) {
			if (prev == NULL) anl = entry->next;
			else prev->next = entry->next;
		} else {
			prev = entry;
			pos = entry->word_position;
		}
	}
	if (anl) anl->negate_pattern = negation_state;

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
	for (action_name_list *entry = anl; entry; entry = entry->next)
		if (entry->nap_listed == NULL) {
			if (entry->parc > 0) {
				if (no_of_pars > 0) immiscible = TRUE;
				no_of_pars = entry->parc;
			}
			action_name *this = entry->action_listed;
			if (this) {
				if (PL::Actions::is_out_of_world(this)) no_oow++; else no_iw++;

				if (entry->parc >= 1) {
					kind *K = PL::Actions::get_data_type_of_noun(this);
					kind *A = kinds_observed_in_list[0];
					if ((A) && (K) && (Kinds::Compare::eq(A, K) == FALSE))
						immiscible = TRUE;
					kinds_observed_in_list[0] = K;
				}
				if (entry->parc >= 2) {
					kind *K = PL::Actions::get_data_type_of_second_noun(this);
					kind *A = kinds_observed_in_list[1];
					if ((A) && (K) && (Kinds::Compare::eq(A, K) == FALSE))
						immiscible = TRUE;
					kinds_observed_in_list[1] = K;
				}
			}
		}
	if ((no_oow > 0) && (no_iw > 0)) immiscible = TRUE;

	for (action_name_list *entry = anl; entry; entry = entry->next)
		if (entry->action_listed)
			if (no_of_pars > PL::Actions::get_max_parameters(entry->action_listed))
				immiscible = TRUE;

	if (immiscible) {
		failure_this_call = IMMISCIBLE_PAPF;
		goto Failed;
	}

@h Action pattern specificity.
The following is one of NI's standardised comparison routines, which
takes a pair of objects A, B and returns 1 if A makes a more specific
description than B, 0 if they seem equally specific, or $-1$ if B makes a
more specific description than A. This is transitive, and intended to be
used in sorting algorithms.

=
int PL::Actions::Patterns::ap_count_rooms(action_pattern *ap) {
	int c = 0;
	if (ap->room_spec) c += 2;
	if (ap->from_spec) c += 2;
	if (ap->to_spec) c += 2;
	return c;
}

int PL::Actions::Patterns::ap_count_going(action_pattern *ap) {
	int c = 0;
	if (ap->pushing_spec) c += 2;
	if (ap->by_spec) c += 2;
	if (ap->through_spec) c += 2;
	return c;
}

int PL::Actions::Patterns::count_aspects(action_pattern *ap) {
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
	if ((Occurrence::is_valid(&(ap->duration))) || (ap->when))
		c++;
	if (ap->parameter_spec) c++;
	return c;
}

int PL::Actions::Patterns::compare_specificity(action_pattern *ap1, action_pattern *ap2) {
	int rv, suspend_usual_from_and_room = FALSE, rct1, rct2;

	if ((ap1 == NULL) && (ap2)) return -1;
	if ((ap1) && (ap2 == NULL)) return 1;
	if ((ap1 == NULL) && (ap2 == NULL)) return 0;

	LOGIF(SPECIFICITIES,
		"Comparing specificity of action patterns:\n(1) $A(2) $A\n", ap1, ap2);

	if ((ap1->valid == FALSE) && (ap2->valid != FALSE)) return -1;
	if ((ap1->valid != FALSE) && (ap2->valid == FALSE)) return 1;

	c_s_stage_law = "III.1 - Object To Which Rule Applies";

	rv = Specifications::compare_specificity(ap1->parameter_spec, ap2->parameter_spec, NULL);
	if (rv != 0) return rv;

	c_s_stage_law = "III.2.1 - Action/Where/Going In Exotic Ways";

	rct1 = PL::Actions::Patterns::ap_count_going(ap1); rct2 = PL::Actions::Patterns::ap_count_going(ap2);
	if (rct1 > rct2) return 1;
	if (rct1 < rct2) return -1;

	rv = Specifications::compare_specificity(ap1->pushing_spec, ap2->pushing_spec, NULL);
	if (rv != 0) return rv;

	rv = Specifications::compare_specificity(ap1->by_spec, ap2->by_spec, NULL);
	if (rv != 0) return rv;

	rv = Specifications::compare_specificity(ap1->through_spec, ap2->through_spec, NULL);
	if (rv != 0) return rv;

	c_s_stage_law = "III.2.2 - Action/Where/Room Where Action Takes Place";

	rct1 = PL::Actions::Patterns::ap_count_rooms(ap1); rct2 = PL::Actions::Patterns::ap_count_rooms(ap2);
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

	c_s_stage_law = "III.2.3 - Action/Where/In The Presence Of";

	rv = Specifications::compare_specificity(ap1->presence_spec, ap2->presence_spec, NULL);
	if (rv != 0) return rv;

	c_s_stage_law = "III.2.4 - Action/Where/Other Optional Clauses";

	rv = PL::Actions::Patterns::compare_specificity_of_apoc_list(ap1, ap2);
	if (rv != 0) return rv;

	c_s_stage_law = "III.3.1 - Action/What/Second Thing Acted On";

	rv = Specifications::compare_specificity(ap1->second_spec, ap2->second_spec, NULL);
	if (rv != 0) return rv;

	c_s_stage_law = "III.3.2 - Action/What/Thing Acted On";

	rv = Specifications::compare_specificity(ap1->noun_spec, ap2->noun_spec, NULL);
	if (rv != 0) return rv;

	if ((ap1->nowhere_flag) && (ap2->nowhere_flag == FALSE)) return -1;
	if ((ap1->nowhere_flag == FALSE) && (ap2->nowhere_flag)) return 1;

	c_s_stage_law = "III.3.3 - Action/What/Actor Performing Action";

	rv = Specifications::compare_specificity(ap1->actor_spec, ap2->actor_spec, NULL);
	if (rv != 0) return rv;

	c_s_stage_law = "III.4.1 - Action/How/What Happens";

	rv = PL::Actions::Lists::compare_specificity(ap1->action, ap2->action);
	if (rv != 0) return rv;

	c_s_stage_law = "III.5.1 - Action/When/Duration";

	rv = Occurrence::compare_specificity(&(ap1->duration), &(ap2->duration));
	if (rv != 0) return rv;

	c_s_stage_law = "III.5.2 - Action/When/Circumstances";

	rv = Conditions::compare_specificity_of_CONDITIONs(ap1->when, ap2->when);
	if (rv != 0) return rv;

	c_s_stage_law = "III.6.1 - Action/Name/Is This Named";

	if ((PL::Actions::Patterns::is_named(ap1)) && (PL::Actions::Patterns::is_named(ap2) == FALSE))
		return 1;
	if ((PL::Actions::Patterns::is_named(ap1) == FALSE) && (PL::Actions::Patterns::is_named(ap2)))
		return -1;
	return 0;
}

@ And an anticlimactic little routine for putting objects
into action patterns in the noun or second noun position.

=
void PL::Actions::Patterns::put_action_object_into_ap(action_pattern *ap, int pos, wording W) {
	parse_node *spec = NULL;
	int any_flag = FALSE;
	if (<action-operand>(W)) {
		if (<<r>>) spec = <<rp>>;
		else { any_flag = TRUE; spec = Specifications::from_kind(K_thing); }
	}
	if (spec == NULL) spec = Specifications::new_UNKNOWN(W);
	if (Rvalues::is_CONSTANT_of_kind(spec, K_text))
		ParseTree::set_kind_of_value(spec, K_understanding);
	ParseTree::set_text(spec, W);
	LOGIF(ACTION_PATTERN_PARSING, "PAOIA (position %d) %W = $P\n", pos, W, spec);
	switch(pos) {
		case 1: ap->noun_spec = spec; ap->noun_any = any_flag; break;
		case 2: ap->second_spec = spec; ap->second_any = any_flag; break;
		case 3: ap->room_spec = spec; ap->room_any = any_flag; break;
	}
}

@h Compiling action tries.

=
void PL::Actions::Patterns::emit_try(action_pattern *ap, int store_instead) {
	parse_node *spec0 = ap->noun_spec; /* the noun */
	parse_node *spec1 = ap->second_spec; /* the second noun */
	parse_node *spec2 = ap->actor_spec; /* the actor */

	if ((Rvalues::is_CONSTANT_of_kind(spec0, K_understanding)) &&
		(<nominative-pronoun>(ParseTree::get_text(spec0)) == FALSE))
		spec0 = Rvalues::from_wording(ParseTree::get_text(spec0));
	if ((Rvalues::is_CONSTANT_of_kind(spec1, K_understanding)) &&
		(<nominative-pronoun>(ParseTree::get_text(spec1)) == FALSE))
		spec1 = Rvalues::from_wording(ParseTree::get_text(spec1));

	action_name_list *anl = ap->action;
	action_name *an = PL::Actions::Lists::get_singleton_action(anl);
	LOGIF(EXPRESSIONS, "Compiling from action name list:\n$L\n", anl);

	int flag_bits = 0;
	if (Kinds::Compare::eq(Specifications::to_kind(spec0), K_text)) flag_bits += 16;
	if (Kinds::Compare::eq(Specifications::to_kind(spec1), K_text)) flag_bits += 32;
	if (flag_bits > 0) Kinds::RunTime::ensure_basic_heap_present();

	if (ap->request) flag_bits += 1;

	Produce::inv_call_iname(Emit::tree(), Hierarchy::find(TRYACTION_HL));
	Produce::down(Emit::tree());
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_t) flag_bits);
		if (spec2) PL::Actions::Patterns::emit_try_action_parameter(spec2, K_object);
		else Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(PLAYER_HL));
		Produce::val_iname(Emit::tree(), K_action_name, PL::Actions::double_sharp(an));
		if (spec0) PL::Actions::Patterns::emit_try_action_parameter(spec0, PL::Actions::get_data_type_of_noun(an));
		else Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
		if (spec1) PL::Actions::Patterns::emit_try_action_parameter(spec1, PL::Actions::get_data_type_of_second_noun(an));
		else Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
		if (store_instead) {
			Produce::inv_call_iname(Emit::tree(), Hierarchy::find(STORED_ACTION_TY_CURRENT_HL));
			Produce::down(Emit::tree());
				Frames::emit_allocation(K_stored_action);
			Produce::up(Emit::tree());
		}
	Produce::up(Emit::tree());
}

@ Which requires the following. As ever, there have to be hacks to ensure that
text as an action parameter is correctly read as parsing grammar rather than
text when the action expects that.

=
void PL::Actions::Patterns::emit_try_action_parameter(parse_node *spec, kind *required_kind) {
	if (Kinds::Compare::eq(required_kind, K_understanding)) {
		kind *K = Specifications::to_kind(spec);
		if ((Kinds::Compare::compatible(K, K_understanding)) ||
			(Kinds::Compare::compatible(K, K_text))) {
			required_kind = NULL;
		}
	}

	if (Dash::check_value(spec, required_kind)) {
		BEGIN_COMPILATION_MODE;
		COMPILATION_MODE_EXIT(DEREFERENCE_POINTERS_CMODE);
		Specifications::Compiler::emit_as_val(K_object, spec);
		END_COMPILATION_MODE;
	}
}

@h Compiling action patterns.
In the following routines, we compile a single clause in what may be a
complex condition which determines whether a rule should fire. The flag
|f| indicates whether any condition has already been printed, and is
updated as the return value of the routine. (Thus, it's permissible for
the routines to compile nothing and return |f| unchanged.) The simple
case first:

=
int PL::Actions::Patterns::CAP_insert_clause(int f, OUTPUT_STREAM, char *i6_condition) {
	if (f) WRITE(" && ");
	WRITE("(%s)", i6_condition);
	return TRUE;
}

@ The more complex clauses mostly act on a single I6 global variable.
In almost all cases, this falls through to the standard method for
testing a condition: we force it to propositional form, substituting the
global in for the value of free variable 0. However, rule clauses are
allowed a few syntaxes not permitted to ordinary conditions, and these
are handled as exceptional cases first:

(a) A table reference such as "a Queen listed in the Table of Monarchs"
expands.

(b) Writing "from R", where R is a region, tests if the room being gone
from is in R, not if it is equal to R. Similarly for other room-related
clauses such as "through" and "in".

(c) Given a piece of run-time parser grammar, we compile a test against
the standard I6 topic variables: there are two of these, so this is the
exceptional case where the clause doesn't act on a single I6 global,
and in this case we therefore ignore |I6_global_name|.

=
int PL::Actions::Patterns::compile_pattern_match_clause(int f,
	value_holster *VH, nonlocal_variable *I6_global_variable,
	parse_node *spec, kind *verify_as_kind, int adapt_region) {
	if (spec == NULL) return f;

	parse_node *I6_var_TS = NULL;
	if (I6_global_variable)
		I6_var_TS = Lvalues::new_actual_NONLOCAL_VARIABLE(I6_global_variable);

	int is_parameter = FALSE;
	if (I6_global_variable == parameter_object_VAR) is_parameter = TRUE;

	return PL::Actions::Patterns::compile_pattern_match_clause_inner(f,
		VH, I6_var_TS, is_parameter, spec, verify_as_kind, adapt_region);
}

int PL::Actions::Patterns::compile_pattern_match_clause_inner(int f,
	value_holster *VH, parse_node *I6_var_TS, int is_parameter,
	parse_node *spec, kind *verify_as_kind, int adapt_region) {
	int force_proposition = FALSE;

	if (spec == NULL) return f;

	LOGIF(ACTION_PATTERN_COMPILATION, "[MPE on $P: $P]\n", I6_var_TS, spec);
	kind *K = Specifications::to_kind(spec);
	if (Kinds::Behaviour::definite(K) == FALSE) {
		Problems::Issue::sentence_problem(_p_(PM_APClauseIndefinite),
			"that action seems to involve a value which is unclear about "
			"its kind",
			"and that's not allowed. For example, you're not allowed to just "
			"say 'Instead of taking a value: ...' because the taking action "
			"applies to objects; the vaguest you're allowed to be is 'Instead "
			"of taking an object: ...'.");
		return TRUE;
	}

	wording C = Descriptions::get_calling(spec);
	if (Wordings::nonempty(C)) {
		local_variable *lvar =
			LocalVariables::ensure_called_local(C,
				Specifications::to_kind(spec));
		LocalVariables::add_calling_to_condition(lvar);
		Produce::inv_primitive(Emit::tree(), SEQUENTIAL_BIP);
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Produce::down(Emit::tree());
				inter_symbol *lvar_s = LocalVariables::declare_this(lvar, FALSE, 8);
				Produce::ref_symbol(Emit::tree(), K_value, lvar_s);
				Specifications::Compiler::emit_as_val(K_value, I6_var_TS);
			Produce::up(Emit::tree());
	}

	force_proposition = TRUE;

	if (ParseTree::is(spec, UNKNOWN_NT)) {
		if (problem_count == 0) internal_error("MPE found unknown SP");
		force_proposition = FALSE;
	}
	else if (ParseTreeUsage::is_lvalue(spec)) {
		force_proposition = TRUE;
		if (ParseTree::is(spec, TABLE_ENTRY_NT)) {
			if (ParseTree::no_children(spec) != 2) internal_error("MPE with bad no of args");
			LocalVariables::add_table_lookup();

			local_variable *ct_0_lv = LocalVariables::by_name(I"ct_0");
			inter_symbol *ct_0_s = LocalVariables::declare_this(ct_0_lv, FALSE, 8);
			local_variable *ct_1_lv = LocalVariables::by_name(I"ct_1");
			inter_symbol *ct_1_s = LocalVariables::declare_this(ct_1_lv, FALSE, 8);
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Produce::down(Emit::tree());
				Produce::ref_symbol(Emit::tree(), K_value, ct_1_s);
				Produce::inv_call_iname(Emit::tree(), Hierarchy::find(EXISTSTABLEROWCORR_HL));
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), STORE_BIP);
					Produce::down(Emit::tree());
						Produce::ref_symbol(Emit::tree(), K_value, ct_0_s);
						Specifications::Compiler::emit_as_val(K_value, spec->down->next);
					Produce::up(Emit::tree());
					Specifications::Compiler::emit_as_val(K_value, spec->down);
					Specifications::Compiler::emit_as_val(K_value, I6_var_TS);
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
			force_proposition = FALSE;
		}
	}
	else if ((Specifications::is_kind_like(spec)) &&
			(Kinds::Compare::le(Specifications::to_kind(spec), K_object) == FALSE)) {
			force_proposition = FALSE;
		}
	else if (ParseTreeUsage::is_rvalue(spec)) {
		if (Rvalues::is_CONSTANT_of_kind(spec, K_understanding)) {
			if ((<understanding-action-irregular-operand>(ParseTree::get_text(spec))) &&
				(<<r>> == TRUE)) {
				Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1);
			} else {
				Produce::inv_primitive(Emit::tree(), NE_BIP);
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), INDIRECT2_BIP);
					Produce::down(Emit::tree());
						Specifications::Compiler::emit_as_val(K_value, spec);
						Produce::val_iname(Emit::tree(), K_number, Hierarchy::find(CONSULT_FROM_HL));
						Produce::val_iname(Emit::tree(), K_number, Hierarchy::find(CONSULT_WORDS_HL));
					Produce::up(Emit::tree());
					Produce::val_iname(Emit::tree(), K_number, Hierarchy::find(GPR_FAIL_HL));
				Produce::up(Emit::tree());
			}
			force_proposition = FALSE;
		}
		if ((is_parameter == FALSE) &&
			(Rvalues::is_object(spec))) {
			instance *I = Specifications::object_exactly_described_if_any(spec);
			if ((I) && (Instances::of_kind(I, K_region))) {
				LOGIF(ACTION_PATTERN_PARSING,
					"$P on $u : $T\n", spec, verify_as_kind, current_sentence);
				if (adapt_region) {
					Produce::inv_call_iname(Emit::tree(), Hierarchy::find(TESTREGIONALCONTAINMENT_HL));
					Produce::down(Emit::tree());
						Specifications::Compiler::emit_as_val(K_value, I6_var_TS);
						Specifications::Compiler::emit_as_val(K_value, spec);
					Produce::up(Emit::tree());
					force_proposition = FALSE;
				}
			}
		}
	}
	else if (Specifications::is_description(spec)) {
		if ((is_parameter == FALSE) &&
			((Descriptions::to_instance(spec)) &&
			(adapt_region) &&
			(Instances::of_kind(Descriptions::to_instance(spec), K_region)))) {
			Produce::inv_call_iname(Emit::tree(), Hierarchy::find(TESTREGIONALCONTAINMENT_HL));
			Produce::down(Emit::tree());
				Specifications::Compiler::emit_as_val(K_value, I6_var_TS);
				Specifications::Compiler::emit_as_val(K_value, spec);
			Produce::up(Emit::tree());
		}
		force_proposition = FALSE;
	}

	pcalc_prop *prop = NULL;
	if (Specifications::is_description(spec))
		prop = Descriptions::to_proposition(spec);

	if (ParseTreeUsage::is_lvalue(spec))
		LOGIF(ACTION_PATTERN_COMPILATION, "Storage has $D\n", prop);

	if ((force_proposition) && (prop == NULL)) {
		prop = Calculus::Propositions::from_spec(spec);
		LOGIF(ACTION_PATTERN_COMPILATION, "[MPE forced proposition: $D]\n", prop);
		if (prop == NULL) internal_error("MPE unable to force proposition");
		if (verify_as_kind) {
			prop = Calculus::Propositions::concatenate(prop,
				Calculus::Atoms::KIND_new(
					verify_as_kind, Calculus::Terms::new_variable(0)));
			Calculus::Deferrals::prop_verify_descriptive(prop,
				"an action or activity to apply to things matching a given "
				"description", spec);
		}
	}

	if (prop) {
		LOGIF(ACTION_PATTERN_COMPILATION, "[MPE faces proposition: $D]\n", prop);
		Calculus::Propositions::Checker::type_check(prop, Calculus::Propositions::Checker::tc_no_problem_reporting());
		Calculus::Deferrals::emit_test_of_proposition(I6_var_TS, prop);
	}

	if (Wordings::nonempty(C)) {
		Produce::up(Emit::tree());
	}
	return TRUE;
}

@ =
void PL::Actions::Patterns::as_stored_action(value_holster *VH, action_pattern *ap) {
	package_request *PR = Hierarchy::package_in_enclosure(BLOCK_CONSTANTS_HAP);
	inter_name *N = Hierarchy::make_iname_in(BLOCK_CONSTANT_HL, PR);
	packaging_state save = Emit::named_late_array_begin(N, K_value);

	Kinds::RunTime::emit_block_value_header(K_stored_action, FALSE, 6);
	action_name *an = PL::Actions::Lists::get_singleton_action(ap->action);
	Emit::array_action_entry(an);

	int request_bits = ap->request;
	if (ap->noun_spec) {
		if (Rvalues::is_CONSTANT_of_kind(ap->noun_spec, K_understanding)) {
			request_bits = request_bits | 16;
			TEMPORARY_TEXT(BC);
			literal_text *lt = Strings::TextLiterals::compile_literal(NULL, FALSE, ParseTree::get_text(ap->noun_spec));
			Emit::array_iname_entry(lt->lt_sba_iname);
			DISCARD_TEXT(BC);
		} else Specifications::Compiler::emit(ap->noun_spec);
	} else {
		Emit::array_numeric_entry(0);
	}
	if (ap->second_spec) {
		if (Rvalues::is_CONSTANT_of_kind(ap->second_spec, K_understanding)) {
			request_bits = request_bits | 32;
			literal_text *lt = Strings::TextLiterals::compile_literal(NULL, TRUE, ParseTree::get_text(ap->second_spec));
			Emit::array_iname_entry(lt->lt_sba_iname);
		} else Specifications::Compiler::emit(ap->second_spec);
	} else {
		Emit::array_numeric_entry(0);
	}
	if (ap->actor_spec) {
		Specifications::Compiler::emit(ap->actor_spec);
	} else
		Emit::array_iname_entry(Instances::iname(I_yourself));
	Emit::array_numeric_entry((inter_t) request_bits);
	Emit::array_numeric_entry(0);
	Emit::array_end(save);
	if (N) Emit::holster(VH, N);
}

void PL::Actions::Patterns::emit_pattern_match(action_pattern ap, int naming_mode) {
	value_holster VH = Holsters::new(INTER_VAL_VHMODE);
	PL::Actions::Patterns::compile_pattern_match(&VH, ap, naming_mode);
}

@

@e ACTOR_IS_PLAYER_CPMC from 1
@e ACTOR_ISNT_PLAYER_CPMC
@e REQUESTER_EXISTS_CPMC
@e REQUESTER_DOESNT_EXIST_CPMC
@e ACTOR_MATCHES_CPMC
@e ACTION_MATCHES_CPMC
@e NOUN_EXISTS_CPMC
@e NOUN_IS_INP1_CPMC
@e SECOND_EXISTS_CPMC
@e SECOND_IS_INP1_CPMC
@e NOUN_MATCHES_AS_OBJECT_CPMC
@e NOUN_MATCHES_AS_VALUE_CPMC
@e SECOND_MATCHES_AS_OBJECT_CPMC
@e SECOND_MATCHES_AS_VALUE_CPMC
@e PLAYER_LOCATION_MATCHES_CPMC
@e ACTOR_IN_RIGHT_PLACE_CPMC
@e ACTOR_LOCATION_MATCHES_CPMC
@e PARAMETER_MATCHES_CPMC
@e OPTIONAL_CLAUSE_CPMC
@e NOWHERE_CPMC
@e SOMEWHERE_CPMC
@e NOT_NOWHERE_CPMC
@e PRESENCE_OF_MATCHES_CPMC
@e PRESENCE_OF_IN_SCOPE_CPMC
@e LOOP_OVER_SCOPE_WITH_CALLING_CPMC
@e LOOP_OVER_SCOPE_WITHOUT_CALLING_CPMC
@e SET_SELF_TO_ACTOR_CPMC
@e WHEN_CONDITION_HOLDS_CPMC

@d MAX_CPM_CLAUSES 256

@d CPMC_NEEDED(C, A) {
	if (cpm_count >= MAX_CPM_CLAUSES) internal_error("action pattern grossly overcomplex");
	needed[cpm_count] = C;
	needed_apoc[cpm_count] = A;
	cpm_count++;
}

=
void PL::Actions::Patterns::compile_pattern_match(value_holster *VH, action_pattern ap, int naming_mode) {
	int cpm_count = 0, needed[MAX_CPM_CLAUSES];
	ap_optional_clause *needed_apoc[MAX_CPM_CLAUSES];
	LOGIF(ACTION_PATTERN_COMPILATION, "Compiling action pattern:\n  $A", &ap);

	if (Occurrence::is_valid(&(ap.duration))) {
		Chronology::compile_past_action_pattern(VH, ap.duration, ap);
	} else {
		kind *kind_of_noun = K_object;
		kind *kind_of_second = K_object;

		if (naming_mode == FALSE) {
			if (ap.applies_to_any_actor == FALSE) {
				int impose = FALSE;
				if (ap.actor_spec != NULL) {
					impose = TRUE;
					nonlocal_variable *var = Lvalues::get_nonlocal_variable_if_any(ap.actor_spec);
					if ((var) && (var == player_VAR)) impose = FALSE;
					instance *I = Rvalues::to_object_instance(ap.actor_spec);
					if ((I) && (I == I_yourself)) impose = FALSE;
				}
				if (impose) {
					CPMC_NEEDED(ACTOR_ISNT_PLAYER_CPMC, NULL);
					if (ap.request) {
						CPMC_NEEDED(REQUESTER_EXISTS_CPMC, NULL);
					} else {
						CPMC_NEEDED(REQUESTER_DOESNT_EXIST_CPMC, NULL);
					}
					if (ap.actor_spec) {
						CPMC_NEEDED(ACTOR_MATCHES_CPMC, NULL);
					}
				} else {
					CPMC_NEEDED(ACTOR_IS_PLAYER_CPMC, NULL);
				}
			} else {
				if (ap.request) {
					CPMC_NEEDED(REQUESTER_EXISTS_CPMC, NULL);
				} else {
					CPMC_NEEDED(REQUESTER_DOESNT_EXIST_CPMC, NULL);
				}
			}
		}
		if ((ap.action != NULL) && (ap.test_anl)) {
			CPMC_NEEDED(ACTION_MATCHES_CPMC, NULL);
		}
		if ((ap.action == NULL) && (ap.noun_spec)) {
			CPMC_NEEDED(NOUN_EXISTS_CPMC, NULL);
			CPMC_NEEDED(NOUN_IS_INP1_CPMC, NULL);
		}
		if ((ap.action == NULL) && (ap.second_spec)) {
			CPMC_NEEDED(SECOND_EXISTS_CPMC, NULL);
			CPMC_NEEDED(SECOND_IS_INP1_CPMC, NULL);
		}
		if ((ap.action) && (ap.action->action_listed)) {
			kind_of_noun = PL::Actions::get_data_type_of_noun(ap.action->action_listed);
			if (kind_of_noun == NULL) kind_of_noun = K_object;
		}

		if (Kinds::Compare::le(kind_of_noun, K_object)) {
			if (ap.noun_spec) {
				CPMC_NEEDED(NOUN_MATCHES_AS_OBJECT_CPMC, NULL);
			}
		} else {
			if (ap.noun_spec) {
				CPMC_NEEDED(NOUN_MATCHES_AS_VALUE_CPMC, NULL);
			}
		}
		if ((ap.action) && (ap.action->action_listed)) {
			kind_of_second = PL::Actions::get_data_type_of_second_noun(ap.action->action_listed);
			if (kind_of_second == NULL) kind_of_second = K_object;
		}
		if (Kinds::Compare::le(kind_of_second, K_object)) {
			if (ap.second_spec) {
				CPMC_NEEDED(SECOND_MATCHES_AS_OBJECT_CPMC, NULL);
			}
		} else {
			if (ap.second_spec) {
				CPMC_NEEDED(SECOND_MATCHES_AS_VALUE_CPMC, NULL);
			}
		}

		if (ap.room_spec) {
			if ((ap.applies_to_any_actor == FALSE) && (naming_mode == FALSE) &&
				(ap.actor_spec == NULL)) {
				CPMC_NEEDED(PLAYER_LOCATION_MATCHES_CPMC, NULL);
			} else {
				CPMC_NEEDED(ACTOR_IN_RIGHT_PLACE_CPMC, NULL);
				CPMC_NEEDED(ACTOR_LOCATION_MATCHES_CPMC, NULL);
			}
		}

		if (ap.parameter_spec) {
			CPMC_NEEDED(PARAMETER_MATCHES_CPMC, NULL);
		}

		ap_optional_clause *apoc = ap.optional_clauses;
		while (apoc) {
			if (apoc->clause_spec) {
				CPMC_NEEDED(OPTIONAL_CLAUSE_CPMC, apoc);
			}
			apoc = apoc->next;
		}

		if (ap.nowhere_flag) {
			if (ap.nowhere_flag == 1) {
				CPMC_NEEDED(NOWHERE_CPMC, NULL);
			} else {
				CPMC_NEEDED(SOMEWHERE_CPMC, NULL);
			}
		} else {
			if ((ap.to_spec == NULL) &&
				((ap.from_spec != NULL)||(ap.by_spec != NULL)||
				(ap.through_spec != NULL)||(ap.pushing_spec != NULL))) {
				CPMC_NEEDED(NOT_NOWHERE_CPMC, NULL);
			}
		}

		if (ap.presence_spec != NULL) {
			instance *to_be_present =
				Specifications::object_exactly_described_if_any(ap.presence_spec);
			if (to_be_present) {
				CPMC_NEEDED(PRESENCE_OF_MATCHES_CPMC, NULL);
				CPMC_NEEDED(PRESENCE_OF_IN_SCOPE_CPMC, NULL);
			} else {
				wording PC = Descriptions::get_calling(ap.presence_spec);
				if (Wordings::nonempty(PC)) {
					CPMC_NEEDED(LOOP_OVER_SCOPE_WITH_CALLING_CPMC, NULL);
				} else {
					CPMC_NEEDED(LOOP_OVER_SCOPE_WITHOUT_CALLING_CPMC, NULL);
				}
			}
		}
		if (ap.when != NULL) {
			CPMC_NEEDED(SET_SELF_TO_ACTOR_CPMC, NULL);
			CPMC_NEEDED(WHEN_CONDITION_HOLDS_CPMC, NULL);
		}

		@<Compile the condition from these instructions@>;
	}
}

@

@d CPMC_RANGE(ix, F, T) {
	ranges_from[ix] = F; ranges_to[ix] = T; ranges_count[ix] = 0;
	for (int i=0; i<cpm_count; i++)
		if ((needed[i] >= F) && (needed[i] <= T))
			ranges_count[ix]++;
}

@<Compile the condition from these instructions@> =
	int ranges_from[4], ranges_to[4], ranges_count[4];
	CPMC_RANGE(0, ACTOR_IS_PLAYER_CPMC, ACTOR_MATCHES_CPMC);
	CPMC_RANGE(1, ACTION_MATCHES_CPMC, ACTION_MATCHES_CPMC);
	CPMC_RANGE(2, NOUN_EXISTS_CPMC, LOOP_OVER_SCOPE_WITHOUT_CALLING_CPMC);
	CPMC_RANGE(3, SET_SELF_TO_ACTOR_CPMC, WHEN_CONDITION_HOLDS_CPMC);

	int f = FALSE;
	int range_to_compile = 0;
	LocalVariables::begin_condition_emit();

	if (PL::Actions::Lists::negated(ap.action)) {
		if (ranges_count[0] > 0) {
			Produce::inv_primitive(Emit::tree(), AND_BIP);
			Produce::down(Emit::tree());
				range_to_compile = 0;
				@<Emit CPM range@>;
		}
		if (ranges_count[3] > 0) {
			Produce::inv_primitive(Emit::tree(), AND_BIP);
			Produce::down(Emit::tree());
		}
		Produce::inv_primitive(Emit::tree(), NOT_BIP);
		Produce::down(Emit::tree());
		if ((ranges_count[1] == 0) && (ranges_count[2] == 0))
			Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 0);
		else {
			if ((ranges_count[1] > 0) && (ranges_count[2] > 0)) {
				Produce::inv_primitive(Emit::tree(), AND_BIP);
				Produce::down(Emit::tree());
			}
			if (ranges_count[1] > 0) {
				range_to_compile = 1;
				@<Emit CPM range@>;
			}
			if (ranges_count[2] > 0) {
				range_to_compile = 2;
				@<Emit CPM range@>;
			}
			if ((ranges_count[1] > 0) && (ranges_count[2] > 0)) Produce::up(Emit::tree());
		}
		Produce::up(Emit::tree());
		if (ranges_count[3] > 0) {
			range_to_compile = 3;
			@<Emit CPM range@>;
		}
		if (ranges_count[3] > 0) Produce::up(Emit::tree());
		if (ranges_count[0] > 0) Produce::up(Emit::tree());
	} else {
		int downs = 0;
		if (ranges_count[1] > 0) {
			if (ranges_count[0]+ranges_count[2]+ranges_count[3] > 0) {
				Produce::inv_primitive(Emit::tree(), AND_BIP);
				Produce::down(Emit::tree()); downs++;
			}
			range_to_compile = 1;
			@<Emit CPM range@>;
		}
		if (ranges_count[0] > 0) {
			if (ranges_count[2]+ranges_count[3] > 0) {
				Produce::inv_primitive(Emit::tree(), AND_BIP);
				Produce::down(Emit::tree()); downs++;
			}
			range_to_compile = 0;
			@<Emit CPM range@>;
		}
		if (ranges_count[2] > 0) {
			if (ranges_count[3] > 0) {
				Produce::inv_primitive(Emit::tree(), AND_BIP);
				Produce::down(Emit::tree()); downs++;
			}
			range_to_compile = 2;
			@<Emit CPM range@>;
		}
		if (ranges_count[3] > 0) {
			range_to_compile = 3;
			@<Emit CPM range@>;
		}
		while (downs > 0) { Produce::up(Emit::tree()); downs--; }
	}

	if ((ranges_count[0] + ranges_count[1] + ranges_count[2] + ranges_count[3] == 0) &&
		(PL::Actions::Lists::negated(ap.action) == FALSE)) {
		Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1);
	}
	LocalVariables::end_condition_emit();

@<Emit CPM range@> =
	TEMPORARY_TEXT(C);
	WRITE_TO(C, "Range %d from %d to %d", range_to_compile, ranges_from[range_to_compile], ranges_to[range_to_compile]);
	Emit::code_comment(C);
	DISCARD_TEXT(C);
	int downs = 0;
	for (int i=0, done=0; i<cpm_count; i++) {
		int cpmc = needed[i];
		if ((cpmc >= ranges_from[range_to_compile]) && (cpmc <= ranges_to[range_to_compile])) {
			done++;
			if (done < ranges_count[range_to_compile]) {
				Produce::inv_primitive(Emit::tree(), AND_BIP);
				Produce::down(Emit::tree()); downs++;
			}
			ap_optional_clause *apoc = needed_apoc[i];
			@<Emit CPM condition piece@>;
		}
	}
	while (downs > 0) { Produce::up(Emit::tree()); downs--; }

@<Emit CPM condition piece@> =
	TEMPORARY_TEXT(C);
	WRITE_TO(C, "So %d", cpmc);
	Emit::code_comment(C);
	DISCARD_TEXT(C);
	switch (cpmc) {
		case ACTOR_IS_PLAYER_CPMC:
			Produce::inv_primitive(Emit::tree(), EQ_BIP);
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(ACTOR_HL));
				Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(PLAYER_HL));
			Produce::up(Emit::tree());
			break;
		case ACTOR_ISNT_PLAYER_CPMC:
			Produce::inv_primitive(Emit::tree(), NE_BIP);
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(ACTOR_HL));
				Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(PLAYER_HL));
			Produce::up(Emit::tree());
			break;
		case REQUESTER_EXISTS_CPMC:
			Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(ACT_REQUESTER_HL));
			break;
		case REQUESTER_DOESNT_EXIST_CPMC:
			Produce::inv_primitive(Emit::tree(), EQ_BIP);
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(ACT_REQUESTER_HL));
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
			Produce::up(Emit::tree());
			break;
		case ACTOR_MATCHES_CPMC:
			PL::Actions::Patterns::compile_pattern_match_clause(f, VH, I6_actor_VAR, ap.actor_spec, K_object, FALSE);
			break;
		case ACTION_MATCHES_CPMC:
			PL::Actions::Lists::emit(ap.action);
			break;
		case NOUN_EXISTS_CPMC:
			Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(NOUN_HL));
			break;
		case NOUN_IS_INP1_CPMC:
			Produce::inv_primitive(Emit::tree(), EQ_BIP);
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(NOUN_HL));
				Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(INP1_HL));
			Produce::up(Emit::tree());
			break;
		case SECOND_EXISTS_CPMC:
			Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(SECOND_HL));
			break;
		case SECOND_IS_INP1_CPMC:
			Produce::inv_primitive(Emit::tree(), EQ_BIP);
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(SECOND_HL));
				Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(INP2_HL));
			Produce::up(Emit::tree());
			break;
		case NOUN_MATCHES_AS_OBJECT_CPMC:
			PL::Actions::Patterns::compile_pattern_match_clause(f, VH, I6_noun_VAR, ap.noun_spec,
				kind_of_noun, FALSE);
			break;
		case NOUN_MATCHES_AS_VALUE_CPMC:
			PL::Actions::Patterns::compile_pattern_match_clause(f, VH,
				NonlocalVariables::temporary_from_iname(Hierarchy::find(PARSED_NUMBER_HL), kind_of_noun),
				ap.noun_spec, kind_of_noun, FALSE);
			break;
		case SECOND_MATCHES_AS_OBJECT_CPMC:
			PL::Actions::Patterns::compile_pattern_match_clause(f, VH, I6_second_VAR, ap.second_spec,
				kind_of_second, FALSE);
			break;
		case SECOND_MATCHES_AS_VALUE_CPMC:
			PL::Actions::Patterns::compile_pattern_match_clause(f, VH,
				NonlocalVariables::temporary_from_iname(Hierarchy::find(PARSED_NUMBER_HL), kind_of_second),
				ap.second_spec, kind_of_second, FALSE);
			break;
		case PLAYER_LOCATION_MATCHES_CPMC:
			PL::Actions::Patterns::compile_pattern_match_clause(f, VH, real_location_VAR, ap.room_spec, K_object, TRUE);
			break;
		case ACTOR_IN_RIGHT_PLACE_CPMC:
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Produce::down(Emit::tree());
				Produce::ref_iname(Emit::tree(), K_object, Hierarchy::find(ACTOR_LOCATION_HL));
				Produce::inv_call_iname(Emit::tree(), Hierarchy::find(LOCATIONOF_HL));
				Produce::down(Emit::tree());
					Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(ACTOR_HL));
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
			break;
		case ACTOR_LOCATION_MATCHES_CPMC:
			PL::Actions::Patterns::compile_pattern_match_clause(f,
				VH, actor_location_VAR, ap.room_spec, K_object, TRUE);
			break;
		case PARAMETER_MATCHES_CPMC: {
			kind *saved_kind = NonlocalVariables::kind(parameter_object_VAR);
			NonlocalVariables::set_kind(parameter_object_VAR, ap.parameter_kind);
			PL::Actions::Patterns::compile_pattern_match_clause(f, VH,
				parameter_object_VAR, ap.parameter_spec, ap.parameter_kind, FALSE);
			NonlocalVariables::set_kind(parameter_object_VAR, saved_kind);
			break;
		}
		case OPTIONAL_CLAUSE_CPMC: {
			kind *K = StackedVariables::get_kind(apoc->stv_to_match);
			PL::Actions::Patterns::compile_pattern_match_clause(f, VH,
				NonlocalVariables::temporary_from_nve(apoc->stv_to_match->underlying_var->rvalue_nve, K),
				apoc->clause_spec, K, apoc->allow_region_as_room);
			break;
		}
		case NOWHERE_CPMC:
			Produce::inv_primitive(Emit::tree(), EQ_BIP);
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), LOOKUP_BIP);
				Produce::down(Emit::tree());
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(MSTACK_HL));
					Produce::inv_call_iname(Emit::tree(), Hierarchy::find(MSTVON_HL));
					Produce::down(Emit::tree());
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 20007);
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1);
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
			Produce::up(Emit::tree());
			break;
		case SOMEWHERE_CPMC: {
			parse_node *somewhere = Specifications::from_kind(K_room);
			PL::Actions::Patterns::compile_pattern_match_clause(f, VH,
				NonlocalVariables::temporary_from_nve(NonlocalVariables::nve_from_mstack(20007, 1, TRUE),
					K_object),
					somewhere, K_object, FALSE);
			break;
		}
		case NOT_NOWHERE_CPMC:
			Produce::inv_primitive(Emit::tree(), NE_BIP);
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), LOOKUP_BIP);
				Produce::down(Emit::tree());
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(MSTACK_HL));
					Produce::inv_call_iname(Emit::tree(), Hierarchy::find(MSTVON_HL));
					Produce::down(Emit::tree());
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 20007);
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1);
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
			Produce::up(Emit::tree());
			break;
		case PRESENCE_OF_MATCHES_CPMC: {
			instance *to_be_present =
				Specifications::object_exactly_described_if_any(ap.presence_spec);
			PL::Actions::Patterns::compile_pattern_match_clause(FALSE, VH,
				NonlocalVariables::temporary_from_iname(Instances::iname(to_be_present), K_object),
				ap.presence_spec, K_object, FALSE);
			break;
		}
		case PRESENCE_OF_IN_SCOPE_CPMC: {
			instance *to_be_present =
				Specifications::object_exactly_described_if_any(ap.presence_spec);
			Produce::inv_call_iname(Emit::tree(), Hierarchy::find(TESTSCOPE_HL));
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_value, Instances::iname(to_be_present));
				Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(ACTOR_HL));
			Produce::up(Emit::tree());
			break;
		}
		case LOOP_OVER_SCOPE_WITH_CALLING_CPMC: {
			loop_over_scope *los = PL::Actions::ScopeLoops::new(ap.presence_spec);
			wording PC = Descriptions::get_calling(ap.presence_spec);
			local_variable *lvar = LocalVariables::ensure_called_local(PC,
				Specifications::to_kind(ap.presence_spec));
			inter_symbol *lvar_s = LocalVariables::declare_this(lvar, FALSE, 8);
			Produce::inv_primitive(Emit::tree(), SEQUENTIAL_BIP);
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), STORE_BIP);
				Produce::down(Emit::tree());
					Produce::ref_iname(Emit::tree(), K_value, Hierarchy::find(LOS_RV_HL));
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
				Produce::up(Emit::tree());
				Produce::inv_primitive(Emit::tree(), SEQUENTIAL_BIP);
				Produce::down(Emit::tree());
					Produce::inv_call_iname(Emit::tree(), Hierarchy::find(LOOPOVERSCOPE_HL));
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, los->los_iname);
						Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(ACTOR_HL));
					Produce::up(Emit::tree());
					Produce::inv_primitive(Emit::tree(), STORE_BIP);
					Produce::down(Emit::tree());
						Produce::ref_symbol(Emit::tree(), K_value, lvar_s);
						Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(LOS_RV_HL));
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
			break;
		}
		case LOOP_OVER_SCOPE_WITHOUT_CALLING_CPMC: {
			loop_over_scope *los = PL::Actions::ScopeLoops::new(ap.presence_spec);
			Produce::inv_primitive(Emit::tree(), SEQUENTIAL_BIP);
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), STORE_BIP);
				Produce::down(Emit::tree());
					Produce::ref_iname(Emit::tree(), K_value, Hierarchy::find(LOS_RV_HL));
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
				Produce::up(Emit::tree());
				Produce::inv_primitive(Emit::tree(), SEQUENTIAL_BIP);
				Produce::down(Emit::tree());
					Produce::inv_call_iname(Emit::tree(), Hierarchy::find(LOOPOVERSCOPE_HL));
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, los->los_iname);
						Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(ACTOR_HL));
					Produce::up(Emit::tree());
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(LOS_RV_HL));
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
			break;
		}
		case SET_SELF_TO_ACTOR_CPMC:
			Produce::inv_primitive(Emit::tree(), SEQUENTIAL_BIP);
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), STORE_BIP);
				Produce::down(Emit::tree());
					Produce::ref_iname(Emit::tree(), K_value, Hierarchy::find(SELF_HL));
					Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(ACTOR_HL));
				Produce::up(Emit::tree());
				Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1);
			Produce::up(Emit::tree());
			break;
		case WHEN_CONDITION_HOLDS_CPMC:
			Specifications::Compiler::emit_as_val(K_value, ap.when);
			break;
	}

@ =
int PL::Actions::Patterns::refers_to_past(action_pattern *ap) {
	if (Occurrence::is_valid(&(ap->duration))) return TRUE;
	return FALSE;
}

void PL::Actions::Patterns::convert_to_present_tense(action_pattern *ap) {
	Occurrence::make_invalid(&(ap->duration));
}

int PL::Actions::Patterns::pta_acceptable(parse_node *spec) {
	instance *I;
	if (spec == NULL) return TRUE;
	if (Specifications::is_description(spec) == FALSE) return TRUE;
	I = Specifications::object_exactly_described_if_any(spec);
	if (I) return TRUE;
	return FALSE;
}

int PL::Actions::Patterns::makes_callings(action_pattern *ap) {
	if (Descriptions::makes_callings(ap->noun_spec)) return TRUE;
	if (Descriptions::makes_callings(ap->second_spec)) return TRUE;
	if (Descriptions::makes_callings(ap->actor_spec)) return TRUE;
	if (Descriptions::makes_callings(ap->room_spec)) return TRUE;
	if (Descriptions::makes_callings(ap->parameter_spec)) return TRUE;
	if (Descriptions::makes_callings(ap->presence_spec)) return TRUE;
	return FALSE;
}

void PL::Actions::Patterns::emit_past_tense(action_pattern *ap) {
	int bad_form = FALSE;
	Produce::inv_call_iname(Emit::tree(), Hierarchy::find(TESTACTIONBITMAP_HL));
	Produce::down(Emit::tree());
	if (ap->noun_spec == NULL)
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
	else
		Specifications::Compiler::emit_as_val(K_value, ap->noun_spec);
	if (ap->action == NULL)
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_t) -1);
	else {
		if (ap->action->next) bad_form = TRUE;
		if (PL::Actions::can_be_compiled_in_past_tense(ap->action->action_listed) == FALSE)
			bad_form = TRUE;
		Produce::val_iname(Emit::tree(), K_value, PL::Actions::double_sharp(ap->action->action_listed));
	}
	Produce::up(Emit::tree());

	if (PL::Actions::Patterns::pta_acceptable(ap->noun_spec) == FALSE) bad_form = TRUE;
	if (PL::Actions::Patterns::pta_acceptable(ap->second_spec) == FALSE) bad_form = TRUE;
	if (PL::Actions::Patterns::pta_acceptable(ap->actor_spec) == FALSE) bad_form = TRUE;
	if (ap->room_spec) bad_form = TRUE;
	if (ap->parameter_spec) bad_form = TRUE;
	if (ap->presence_spec) bad_form = TRUE;
	if (ap->when) bad_form = TRUE;
	if (ap->optional_clauses) bad_form = TRUE;

	if (bad_form)
		@<Issue too complex PT problem@>;
}

@<Issue too complex PT problem@> =
	Problems::Issue::sentence_problem(_p_(PM_PTAPTooComplex),
		"that is too complex a past tense action",
		"at least for this version of Inform to handle: we may improve "
		"matters in later releases. The restriction is that the "
		"actions used in the past tense may take at most one "
		"object, and that this must be a physical thing (not a "
		"value, in other words). And no details of where or what "
		"else was then happening can be specified.");

@ =
int PL::Actions::Patterns::is_an_action_variable(parse_node *spec) {
	nonlocal_variable *nlv;
	if (spec == NULL) return FALSE;
	if (Lvalues::get_storage_form(spec) != NONLOCAL_VARIABLE_NT) return FALSE;
	nlv = ParseTree::get_constant_nonlocal_variable(spec);
	if (nlv == I6_noun_VAR) return TRUE;
	if (nlv == I6_second_VAR) return TRUE;
	if (nlv == I6_actor_VAR) return TRUE;
	return FALSE;
}
