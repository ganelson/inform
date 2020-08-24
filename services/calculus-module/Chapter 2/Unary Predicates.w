[UnaryPredicates::] Unary Predicates.

A lightweight structure to represent a unary predicate, which is either true
or false when applied to a single term.

@ These are relatively small and quick to make, and are parametrised in various
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
	unary_predicate *au = CREATE(unary_predicate);
	au->family = f;
	au->assert_kind = NULL;
	au->lcon = 0;
	au->calling_name = EMPTY_WORDING;
	return au;
}

unary_predicate *UnaryPredicates::copy(unary_predicate *au_from) {
	unary_predicate *au = CREATE(unary_predicate);
	au->family = au_from->family;
	au->assert_kind = au_from->assert_kind;
	au->composited = au_from->composited;
	au->unarticled = au_from->unarticled;
	au->calling_name = au_from->calling_name;
	au->lcon = au_from->lcon;
	return au;
}

void UnaryPredicates::log(unary_predicate *au) {
	UnaryPredicateFamilies::log(DL, au);
}
