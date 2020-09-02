[KindPredicates::] Kind Predicates.

To define the predicates for membership of a kind.

@ For every kind |K|, the //calculus// module provides a unary predicate |kind=K|,
and these all belong to the family:

= (early code)
up_family *kind_up_family = NULL;

@ At startup, the //calculus// module calls:

=
void KindPredicates::start(void) {
	kind_up_family = UnaryPredicateFamilies::new();
	METHOD_ADD(kind_up_family, LOG_UPF_MTID, KindPredicates::log_kind);
	METHOD_ADD(kind_up_family, INFER_KIND_UPF_MTID, KindPredicates::infer_kind);
	METHOD_ADD(kind_up_family, TESTABLE_UPF_MTID, KindPredicates::testable);
	METHOD_ADD(kind_up_family, TEST_UPF_MTID, KindPredicates::test);
}

@ =
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

void KindPredicates::infer_kind(up_family *self, unary_predicate *up, kind **K) {
	*K = up->assert_kind;
}

@ The following functions express that (i) |kind=K| predicates can always be
determined at compile-time, and that (ii) they are always true. This is because
the test is performed only after a proposition has been type-checked: and if
it passed type-checking, then the kinds must all be okay.

=
int KindPredicates::testable(up_family *self, unary_predicate *up) {
	return TRUE;
}

int KindPredicates::test(up_family *self, unary_predicate *up,
	TERM_DOMAIN_CALCULUS_TYPE *about) {
	return TRUE;
}

@ =
void KindPredicates::log_kind(up_family *self, OUTPUT_STREAM, unary_predicate *up) {
	if (Streams::I6_escapes_enabled(OUT) == FALSE) WRITE("kind=");
	WRITE("%u", up->assert_kind);
	if ((Streams::I6_escapes_enabled(OUT) == FALSE) && (up->composited)) WRITE("_c");
	if ((Streams::I6_escapes_enabled(OUT) == FALSE) && (up->unarticled)) WRITE("_u");
}
