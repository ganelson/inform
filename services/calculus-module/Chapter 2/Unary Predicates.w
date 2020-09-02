[UnaryPredicates::] Unary Predicates.

A lightweight structure to represent a unary predicate, which is either true
or false when applied to a single term.

@ UPs are relatively small and quick to make, and are parametrised in various
ways. For example, there is no single |kind=K| unary predicate; there is one
for every possible kind |K|.

=
typedef struct unary_predicate {
	struct up_family *family;
	struct kind *assert_kind;
	int composited; /* for kind UPs only: arises from a composite determiner/noun like "somewhere" */
	int unarticled; /* for kind UPs only: arises from an unarticled usage like "vehicle", not "a vehicle" */
	struct wording calling_name; /* for calling UPs only */
	lcon_ti lcon; /* for adjectival UPs only */
} unary_predicate;

@ =
unary_predicate *UnaryPredicates::new(up_family *f) {
	unary_predicate *up = CREATE(unary_predicate);
	up->family = f;
	up->assert_kind = NULL;
	up->lcon = 0;
	up->calling_name = EMPTY_WORDING;
	return up;
}

void UnaryPredicates::log(unary_predicate *up) {
	UnaryPredicateFamilies::log(DL, up);
}

@ When deep-copying propositions, we also deep-copy their unary predicates:

=
unary_predicate *UnaryPredicates::copy(unary_predicate *up_from) {
	unary_predicate *up = CREATE(unary_predicate);
	up->family = up_from->family;
	up->assert_kind = up_from->assert_kind;
	up->composited = up_from->composited;
	up->unarticled = up_from->unarticled;
	up->calling_name = up_from->calling_name;
	up->lcon = up_from->lcon;
	return up;
}
