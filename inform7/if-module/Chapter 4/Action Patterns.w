[ActionPatterns::] Action Patterns.

An action pattern is a description which may match many actions or
none. The text "doing something" matches every action, while "throwing
something at a door in a dark room" is seldom matched.

@ Action patterns are an unusual feature of Inform as a programming language, and
not only because actions do not really occur in other languages.[1] An AP is
like a tuple of conditions to be applied to a tuple of values: that is, it
is like a condition $\phi(C)$ which applies to a compound structure
$C = (c_1, c_2, ...)$ where $\phi(C) = \phi_1(c_1)\land \phi_2(c_2)\land ...$,
with each $\phi_i$ being a predicate which the term $c_i$ must match.

With an action, $c_1, c_2, ...$ are the action variables: the actor, the
noun, and the second noun are the obvious examples, but there can be others
depending on the action (the //Going// action provides at least five more),
and so on. So, for example, "putting something edible into an open container"
can be seen as the tuple:
$$ (c_a = {\it player}, {\it edible}(c_n), {\it open}(c_s)\land {\it container}(c_s)) $$
where $c_a$, $c_n$ and $c_s$ are the actor, noun and second noun components
of the action being tested. The individual conditions in this tuple are called
the "clauses" of the AP, for want of a better word, and are the topic of the
section //Action Pattern Clauses//.

Complicating this relatively simple picture, the choice of action -- in this
example, "putting it into" -- is not represented by a clause but by a special
structure called an //action_name_list//. There are implementation reasons
for this, but basically it is because the list tends to be a disjunction, i.e.,
a choice of alternative actions, whereas the clauses tend to be conjunctions
of requirements. Finally, APs can also be written in the past tense, or refer
to how often they have occurred before.

[1] Unusual, but not entirely unique. Swift supports what it calls tuple
patterns, for example.

@ A simple special case is used to express the applicability of a rule in a
parameter- rather than action-based rulebook.

For example, the "reaching inside" rulebook in the Standard Rules applies to a
single parameter object. When the author writes "Rule for reaching inside an
open container", say, the applicability of this rule is an AP with |action_list|
set to |NULL| but with |parameter_kind| set to |K_object|, and the tuple of
clauses has just a single term: $({\it open}(c_p) \land{\it container}(c_p))$,
where $c_p$ is the parameter variable.

Such APs are called "parametric", and are actually the easiest to deal with
by far. They have no |action_list|, no |duration|, and the tuple of clauses
is always just a single term. Non-parametric APs are said to be "action-based".

@ All APs arise from parsing natural language text, and retain a memory
of the text they came from; for which, see //Parse Action Patterns//.

=
typedef struct action_pattern {
	struct wording text_of_pattern; /* text giving rise to this AP */

	struct action_name_list *action_list; /* if this is action-based */
	struct kind *parameter_kind; /* if this is parametric */

	struct ap_clause *ap_clauses;

	struct time_period *duration; /* to refer to repetitions in the past */
} action_pattern;

@ Unlike most data structures in the compiler, APs can churn quickly into
and out of existence on the stack during parsing, and so the following
directly returns a |struct|, rather than allocating a permanent object and
returning only a pointer to it.

=
action_pattern ActionPatterns::new(wording W) {
	action_pattern ap;
	ap.ap_clauses = NULL;
	ap.text_of_pattern = W;
	ap.action_list = NULL;
	ap.parameter_kind = NULL;
	ap.duration = NULL;
	return ap;
}

@ Permanent copies can subsequently be made thus:

=
action_pattern *ActionPatterns::perpetuate(action_pattern ap) {
	action_pattern *sap = CREATE(action_pattern);
	*sap = ap;
	return sap;
}

@ =
void ActionPatterns::log(action_pattern *ap) {
	ActionPatterns::write(DL, ap);
}

void ActionPatterns::write(OUTPUT_STREAM, action_pattern *ap) {
	if (ap == NULL) WRITE("<null-ap>");
	else if (ap->parameter_kind) {
		WRITE("<parametric: ");
		APClauses::write(OUT, ap);
		WRITE(">");
	} else {
		WRITE("<action-based: ");
		if (ap->action_list == NULL) WRITE("unspecified");
		else ActionNameLists::log_briefly(ap->action_list);
		if (ap->ap_clauses) { WRITE(" * "); APClauses::write(OUT, ap); }
		if (ap->duration) { WRITE(" * duration: "); Occurrence::log(OUT, ap->duration); }
		WRITE(">");
	}
}

@ Access to the actions mentioned:

=
int ActionPatterns::involves_actions(action_pattern *ap) {
	if ((ap) && (ActionNameLists::nonempty(ap->action_list))) return TRUE;
	return FALSE;
}

int ActionPatterns::covers_action(action_pattern *ap, action_name *an) {
	if (ap == NULL) return TRUE;
	return ActionNameLists::covers_action(ap->action_list, an);
}

action_name *ActionPatterns::single_positive_action(action_pattern *ap) {
	if (ap) return ActionNameLists::single_positive_action(ap->action_list);
	return NULL;
}

int ActionPatterns::is_named(action_pattern *ap) {
	if (ap) return ActionNameLists::is_single_NAP(ap->action_list)?TRUE:FALSE;
	return FALSE;
}

void ActionPatterns::suppress_action_testing(action_pattern *ap) {
	if ((ap->duration == NULL) && (ap->action_list))
		ActionNameLists::suppress_action_testing(ap->action_list);
}

@ And the historical side:

=
int ActionPatterns::refers_to_past(action_pattern *ap) {
	if (ap->duration) return TRUE;
	return FALSE;
}

void ActionPatterns::convert_to_present_tense(action_pattern *ap) {
	ap->duration = NULL;
}

@ This determines whether an action pattern, if tested, would create temporary
variables, as in the example "taking something (called the gift)":

=
int ActionPatterns::makes_callings(action_pattern *ap) {
	LOOP_OVER_AP_CLAUSES(apoc, ap)
		if (Descriptions::makes_callings(apoc->clause_spec))
			return TRUE;
	return FALSE;
}

@ Finally but importantly, one major use of APs is to define the applicability
of rules in rulebooks. These must be sorted in order of increasing breadth of
applicability, and therefore we need a careful measure of which APs are
more specific than which others. For example, "taking the red fish" is more
specific than "taking an animal" which is more specific than "taking or dropping
a thing".

This is a |strcmp|-like function for use in sorting algorithms. The global
variable |c_s_stage_law| is slyly set to whatever is being checked, so that
after this function returns, the value remaining in it must have been the
decisive factor.

=
int ActionPatterns::compare_specificity(action_pattern *ap1, action_pattern *ap2) {
	if ((ap1 == NULL) && (ap2)) return -1;
	if ((ap1) && (ap2 == NULL)) return 1;
	if ((ap1 == NULL) && (ap2 == NULL)) return 0;

	LOGIF(SPECIFICITIES,
		"Comparing specificity of action patterns:\n(1) $A\n(2) $A\n", ap1, ap2);

	int rv = APClauses::compare_specificity(ap1, ap2);
	if (rv != 0) return rv;

	c_s_stage_law = I"III.4.1 - Action/How/What Happens";

	rv = ActionNameLists::compare_specificity(ap1->action_list, ap2->action_list);
	if (rv != 0) return rv;

	c_s_stage_law = I"III.5.1 - Action/When/Duration";

	rv = Occurrence::compare_specificity(ap1->duration, ap2->duration);
	if (rv != 0) return rv;

	c_s_stage_law = I"III.5.2 - Action/When/Circumstances";

	rv = Conditions::compare_specificity_of_CONDITIONs(
		APClauses::spec(ap1, WHEN_AP_CLAUSE), APClauses::spec(ap2, WHEN_AP_CLAUSE));
	if (rv != 0) return rv;

	c_s_stage_law = I"III.6.1 - Action/Name/Is This Named";

	if ((ActionPatterns::is_named(ap1)) && (ActionPatterns::is_named(ap2) == FALSE))
		return 1;
	if ((ActionPatterns::is_named(ap1) == FALSE) && (ActionPatterns::is_named(ap2)))
		return -1;

	return 0;
}
