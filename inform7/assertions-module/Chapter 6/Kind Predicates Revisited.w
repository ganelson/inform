[KindPredicatesRevisited::] Kind Predicates Revisited.

To define how the kind predicates behave in the Inform language.

@ Recall that for every kind |K| the //calculus// module makes a built-in
unary predicate |kind=K(t)|, which is true if and only if |t| has kind |K|.
See //calculus: Kind Predicates// for details.

In this section, we give this family of UPs the necessary method calls to
be asserted and compiled from.

=
void KindPredicatesRevisited::start(void) {
	METHOD_ADD(kind_up_family, TYPECHECK_UPF_MTID, KindPredicatesRevisited::typecheck);
	METHOD_ADD(kind_up_family, ASSERT_UPF_MTID, KindPredicatesRevisited::assert);
	METHOD_ADD(kind_up_family, SCHEMA_UPF_MTID, KindPredicatesRevisited::get_schema);
}

@ We will reject any "kind" applied to a constant if it necessarily fails --
even when the sense of the proposition is arguably correct. For example:
= (text)
	1. 100 is not a text
	<< NOT< text('100') NOT> >>
	Failed: proposition would not type-check
	Term '100' is number not text
=
"100 is not a number" would pass, on the other hand. It is obviously false,
but not meaningless.

=
int KindPredicatesRevisited::typecheck(up_family *self, unary_predicate *up,
	pcalc_prop *prop, variable_type_assignment *vta, tc_problem_kit *tck) {
	kind *need_to_find = up->assert_kind;
	if (Kinds::Behaviour::is_object(need_to_find)) need_to_find = K_object;
	kind *actually_find = Propositions::Checker::kind_of_term(&(prop->terms[0]), vta, tck);
	if (Kinds::compatible(actually_find, need_to_find) == NEVER_MATCH) {
		if (tck->log_to_I6_text)
			LOG("Term $0 is %u not %u\n", &(prop->terms[0]), actually_find, need_to_find);
		Propositions::Checker::issue_kind_typecheck_error(actually_find, need_to_find, tck, prop);
		return NEVER_MATCH;
	}
	return ALWAYS_MATCH;
}

@ Note that we never assert the kind of non-objects. Typechecking won't allow such
an atom to exist unless it states something already true, so there is no need.

The problem message here is really quite hard to generate, because the
A-parser usually gets there first. "There is a banana which is something which
is not a door." will fall through here, but it isn't exactly an everyday
sentence.

=
void KindPredicatesRevisited::assert(up_family *self, unary_predicate *up,
	int now_negated, pcalc_prop *pl) {
	if (now_negated) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_CantAssertNonKind),
			"that seems to say what kind something doesn't have",
			"which is too vague. You must say what kind it does have.");
		return;
	}
	inference_subject *subj = Assert::subject_of_term(pl->terms[0]);
	instance *ox = InstanceSubjects::to_object_instance(subj);
	if (ox) Instances::set_kind(ox, up->assert_kind);
	else {
		kind *K = KindSubjects::to_kind(subj);
		if (K) Kinds::make_subkind(K, up->assert_kind);
	}
}

@ In any type-checked proposition, a "kind" predicate can only exist where it is
always at least sometimes true. In particular, if $K$ is a kind of value, then
the atom $K(v)$ can only exist where $v$ is of that kind of value, so that the
atom is always true when tested. But if $K$ is a kind of object, then $K(O)$
may occur in the proposition for any object $O$, where $O$ need not belong
to $K$ at all: so there is something substantive to check, which we do using
the I6 |ofclass| operator.

=
int suppress_C14CantChangeKind = FALSE;
void KindPredicatesRevisited::get_schema(up_family *self, int task, unary_predicate *up,
	annotated_i6_schema *asch, kind *K) {
	switch(task) {
		case TEST_ATOM_TASK:
			if (Kinds::Behaviour::is_subkind_of_object(up->assert_kind))
				Calculus::Schemas::modify(asch->schema, "*1 ofclass %n",
					RTKinds::I6_classname(up->assert_kind));
			else {
				if ((Kinds::get_construct(up->assert_kind) == CON_list_of) &&
					(problem_count == 0)) {
					Problems::quote_source(1, current_sentence);
					Problems::quote_kind(2, up->assert_kind);
					StandardProblems::handmade_problem(Task::syntax_tree(),
						_p_(PM_CantCheckListContents));
					Problems::issue_problem_segment(
						"In %1, you use a list which might or might not match a "
						"definition requiring %2. But there's no efficient way to "
						"tell during play whether the list actually contains that, "
						"without laboriously checking every entry. Because "
						"in general this would be a bad idea, this usage is "
						"not allowed.");
					Problems::issue_problem_end();
				}
				Calculus::Schemas::modify(asch->schema, "true");
			}
			break;
		case NOW_ATOM_TRUE_TASK:
		case NOW_ATOM_FALSE_TASK:
			if (suppress_C14CantChangeKind == FALSE) {
				StandardProblems::sentence_problem(Task::syntax_tree(),
					_p_(PM_CantChangeKind),
					"the kind of something is fixed",
					"and cannot be changed during play with a 'now'.");
				asch->schema = NULL;
			} else Calculus::Schemas::modify(asch->schema, " ");
			break;
	}
}
