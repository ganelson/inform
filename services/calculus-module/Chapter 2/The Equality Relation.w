[Calculus::Equality::] The Equality Relation.

To define that prince among predicates, the equality relation.

@ This predicate plays a very special role in our calculus, and must always
exist.

= (early code)
bp_family *equality_bp_family = NULL;
bp_family *spatial_bp_family = NULL;

binary_predicate *R_equality = NULL;
binary_predicate *a_has_b_predicate = NULL;

@h Family.
This is a minimal representation only: Inform adds other methods to the equality
family to handle its typechecking and so on.

=
void Calculus::Equality::start(void) {
	equality_bp_family = BinaryPredicateFamilies::new();
	METHOD_ADD(equality_bp_family, STOCK_BPF_MTID, Calculus::Equality::stock);
	METHOD_ADD(equality_bp_family, DESCRIBE_FOR_PROBLEMS_BPF_MTID, Calculus::Equality::REL_describe_for_problems);
	METHOD_ADD(equality_bp_family, DESCRIBE_FOR_INDEX_BPF_MTID, Calculus::Equality::REL_describe_briefly);

	spatial_bp_family = BinaryPredicateFamilies::new();
	#ifndef IF_MODULE
	METHOD_ADD(spatial_bp_family, STOCK_BPF_MTID, Calculus::Equality::stock_spatial);
	#endif
}

@h Initial stock.
This relation is hard-wired in, and it is made in a slightly special way
since (alone among binary predicates) it has no distinct reversal.

=
void Calculus::Equality::stock(bp_family *self, int n) {
	if (n == 1) {
		R_equality = BinaryPredicates::make_equality(equality_bp_family,
			PreformUtilities::wording(<relation-names>, EQUALITY_RELATION_NAME));
		BinaryPredicates::set_index_details(R_equality, "value", "value");
	}
}

void Calculus::Equality::stock_spatial(bp_family *self, int n) {
	if (n == 1) {
		a_has_b_predicate =
			BinaryPredicates::make_pair(spatial_bp_family,
				BinaryPredicates::full_new_term(NULL, NULL, EMPTY_WORDING, NULL),
				BinaryPredicates::new_term(NULL),
				I"has", I"is-had-by",
				NULL, NULL,
				PreformUtilities::wording(<relation-names>, POSSESSION_RELATION_NAME));
	}
}

@h Problem message text.

=
int Calculus::Equality::REL_describe_for_problems(bp_family *self, OUTPUT_STREAM, binary_predicate *bp) {
	return FALSE;
}
void Calculus::Equality::REL_describe_briefly(bp_family *self, OUTPUT_STREAM, binary_predicate *bp) {
	WRITE("equality");
}
