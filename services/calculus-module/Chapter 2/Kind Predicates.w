[KindPredicates::] Kind Predicates.

To define the predicates for membership of a kind.

@

= (early code)
up_family *kind_up_family = NULL;

@h Family.
This is a minimal representation only: Inform adds other methods to the equality
family to handle its typechecking and so on.

=
void KindPredicates::start(void) {
	kind_up_family = UnaryPredicateFamilies::new();
	METHOD_ADD(kind_up_family, LOG_UPF_MTID, KindPredicates::log_kind);
	#ifdef CORE_MODULE
	METHOD_ADD(kind_up_family, TYPECHECK_UPF_MTID, KindPredicates::typecheck);
	METHOD_ADD(kind_up_family, INFER_KIND_UPF_MTID, KindPredicates::infer_kind);
	METHOD_ADD(kind_up_family, ASSERT_UPF_MTID, KindPredicates::assert);
	METHOD_ADD(kind_up_family, TESTABLE_UPF_MTID, KindPredicates::testable);
	METHOD_ADD(kind_up_family, TEST_UPF_MTID, KindPredicates::test);
	METHOD_ADD(kind_up_family, SCHEMA_UPF_MTID, KindPredicates::get_schema);
	#endif
}

@ For each kind |K|, we have a unary predicate |kind=K(v)| which tests whether
|v| belongs to that kind. This predicate has the special property that its truth
does not change over time. If a value |v| satisfies |kind=K(v)| at then start
of execution, it will do so throughout. That is not true of, say, adjectival
predicates like |open(v)|. Not only is |kind=K(v)| unchanging over time, but
we can determine its truth or falsity (if we know |v|) even at compile time.
We can exploit this in many ways.

=
pcalc_prop *KindPredicates::new_atom(kind *K, pcalc_term t) {
	unary_predicate *up = UnaryPredicates::new(kind_up_family);
	up->assert_kind = K;
	return Atoms::unary_PREDICATE_new(up, t);
}

int KindPredicates::is_kind_atom(pcalc_prop *prop) {
	if ((prop) && (prop->element == PREDICATE_ATOM) && (prop->arity == 1)) {
		unary_predicate *up = RETRIEVE_POINTER_unary_predicate(prop->predicate);
		if (up->family == kind_up_family) return TRUE;
	}
	return FALSE;
}

kind *KindPredicates::get_kind(pcalc_prop *prop) {
	if ((prop) && (prop->element == PREDICATE_ATOM) && (prop->arity == 1)) {
		unary_predicate *up = RETRIEVE_POINTER_unary_predicate(prop->predicate);
		if (up->family == kind_up_family) return up->assert_kind;
	}
	return NULL;
}

@ Composited kind predicates are special in that they represent composites
of quantifiers with common nouns -- for example, "everyone" is a composite
meaning "every person".

=
pcalc_prop *KindPredicates::new_composited_atom(kind *K, pcalc_term t) {
	unary_predicate *up = UnaryPredicates::new(kind_up_family);
	up->assert_kind = K;
	up->composited = TRUE;
	return Atoms::unary_PREDICATE_new(up, t);
}

int KindPredicates::is_composited_atom(pcalc_prop *prop) {
	if ((prop) && (prop->element == PREDICATE_ATOM) && (prop->arity == 1)) {
		unary_predicate *up = RETRIEVE_POINTER_unary_predicate(prop->predicate);
		if (up->family == kind_up_family) {
			if (up->composited) return TRUE;
		}
	}
	return FALSE;
}

void KindPredicates::set_composited(pcalc_prop *prop, int state) {
	if ((prop) && (prop->element == PREDICATE_ATOM) && (prop->arity == 1)) {
		unary_predicate *up = RETRIEVE_POINTER_unary_predicate(prop->predicate);
		if (up->family == kind_up_family) {
			up->composited = state;
		}
	}
}

@ Unarticled kinds are those which were introduced without an article, in
the linguistic sense.

=
int KindPredicates::is_unarticled_atom(pcalc_prop *prop) {
	if ((prop) && (prop->element == PREDICATE_ATOM) && (prop->arity == 1)) {
		unary_predicate *up = RETRIEVE_POINTER_unary_predicate(prop->predicate);
		if (up->family == kind_up_family) {
			if (up->unarticled) return TRUE;
		}
	}
	return FALSE;
}

void KindPredicates::set_unarticled(pcalc_prop *prop, int state) {
	if ((prop) && (prop->element == PREDICATE_ATOM) && (prop->arity == 1)) {
		unary_predicate *up = RETRIEVE_POINTER_unary_predicate(prop->predicate);
		if (up->family == kind_up_family) {
			up->unarticled = state;
		}
	}
}

#ifdef CORE_MODULE
void KindPredicates::infer_kind(up_family *self, unary_predicate *up, kind **K) {
	*K = up->assert_kind;
}
#endif

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
#ifdef CORE_MODULE
int KindPredicates::typecheck(up_family *self, unary_predicate *up,
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
#endif

@ Note that we never assert the kind of non-objects. Typechecking won't allow such
an atom to exist unless it states something already true, so there is no need.

The problem message here is really quite hard to generate, because the
A-parser usually gets there first. "There is a banana which is something which
is not a door." will fall through here, but it isn't exactly an everyday
sentence.

=
#ifdef CORE_MODULE
void KindPredicates::assert(up_family *self, unary_predicate *up,
	int now_negated, pcalc_prop *pl) {
	if (now_negated) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_CantAssertNonKind),
			"that seems to say what kind something doesn't have",
			"which is too vague. You must say what kind it does have.");
		return;
	}
	inference_subject *subj = Propositions::Assert::subject_of_term(pl->terms[0]);
	instance *ox = InferenceSubjects::as_object_instance(subj);
	if (ox) Instances::set_kind(ox, up->assert_kind);
	else {
		kind *K = InferenceSubjects::as_kind(subj);
		if (K) Kinds::make_subkind(K, up->assert_kind);
	}
}
#endif

#ifdef CORE_MODULE
int KindPredicates::testable(up_family *self, unary_predicate *up) {
	return TRUE;
}
#endif

#ifdef CORE_MODULE
int KindPredicates::test(up_family *self, unary_predicate *up,
	TERM_DOMAIN_CALCULUS_TYPE *about) {
	return TRUE;
}
#endif

@ In any type-checked proposition, a "kind" predicate can only exist where it is
always at least sometimes true. In particular, if $K$ is a kind of value, then
the atom $K(v)$ can only exist where $v$ is of that kind of value, so that the
atom is always true when tested. But if $K$ is a kind of object, then $K(O)$
may occur in the proposition for any object $O$, where $O$ need not belong
to $K$ at all: so there is something substantive to check, which we do using
the I6 |ofclass| operator.

=
#ifdef CORE_MODULE
int suppress_C14CantChangeKind = FALSE;
void KindPredicates::get_schema(up_family *self, int task, unary_predicate *up,
	annotated_i6_schema *asch, kind *K) {
	switch(task) {
		case TEST_ATOM_TASK:
			if (Kinds::Behaviour::is_subkind_of_object(up->assert_kind))
				Calculus::Schemas::modify(asch->schema, "*1 ofclass %n",
					Kinds::RunTime::I6_classname(up->assert_kind));
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
#endif

void KindPredicates::log_kind(up_family *self, OUTPUT_STREAM, unary_predicate *up) {
	if (Streams::I6_escapes_enabled(OUT) == FALSE) WRITE("kind=");
	WRITE("%u", up->assert_kind);
	if ((Streams::I6_escapes_enabled(OUT) == FALSE) && (up->composited)) WRITE("_c");
	if ((Streams::I6_escapes_enabled(OUT) == FALSE) && (up->unarticled)) WRITE("_u");
}
