[Calculus::Equality::] The Equality Relation.

To define that prince among predicates, the equality relation; and also its
less noble sidekick, the "has" relation.

@ Equality is the only relation in its family; but in Inform, there will be other
relations besides "has" in the spatial family.

= (early code)
bp_family *equality_bp_family = NULL;
bp_family *spatial_bp_family = NULL;
bp_family *empty_bp_family = NULL;

binary_predicate *R_equality = NULL;
binary_predicate *a_has_b_predicate = NULL;
binary_predicate *R_empty = NULL;

@h Family.
This is a minimal representation only, for when the calculus module is used
in a non-Inform context: whereas Inform adds other methods to the equality
family to handle its typechecking in //assertions: The Equality Relation Revisited//.

=
void Calculus::Equality::start(void) {
	equality_bp_family = BinaryPredicateFamilies::new();
	METHOD_ADD(equality_bp_family, STOCK_BPF_MTID,
		Calculus::Equality::stock);
	METHOD_ADD(equality_bp_family, DESCRIBE_FOR_PROBLEMS_BPF_MTID,
		Calculus::Equality::describe_for_problems);
	METHOD_ADD(equality_bp_family, DESCRIBE_FOR_INDEX_BPF_MTID,
		Calculus::Equality::describe_for_index);

	spatial_bp_family = BinaryPredicateFamilies::new();
	#ifndef IF_MODULE
	METHOD_ADD(spatial_bp_family, STOCK_BPF_MTID,
		Calculus::Equality::stock_spatial);
	#endif

	empty_bp_family = BinaryPredicateFamilies::new();
	METHOD_ADD(empty_bp_family, STOCK_BPF_MTID,
		Calculus::Equality::stock_empty);
	METHOD_ADD(empty_bp_family, DESCRIBE_FOR_PROBLEMS_BPF_MTID,
		Calculus::Equality::describe_empty_for_problems);
	METHOD_ADD(empty_bp_family, DESCRIBE_FOR_INDEX_BPF_MTID,
		Calculus::Equality::describe_empty_for_index);
}

@h Initial stock.
Note the unique one-off way in which equality is made.

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
				BPTerms::new_full(NULL, NULL, EMPTY_WORDING, NULL),
				BPTerms::new(NULL),
				I"has", I"is-had-by",
				NULL, NULL,
				PreformUtilities::wording(<relation-names>, POSSESSION_RELATION_NAME));
	}
}

void Calculus::Equality::stock_empty(bp_family *self, int n) {
	if (n == 1) {
		R_empty = BinaryPredicates::make_equality(empty_bp_family,
			PreformUtilities::wording(<relation-names>, EMPTY_RELATION_NAME));
		BinaryPredicates::set_index_details(R_equality, "value", "value");
	}
}

@h Problem message text.

=
int Calculus::Equality::describe_for_problems(bp_family *self, OUTPUT_STREAM,
	binary_predicate *bp) {
	return FALSE;
}
void Calculus::Equality::describe_for_index(bp_family *self, OUTPUT_STREAM,
	binary_predicate *bp) {
	WRITE("equality");
}
int Calculus::Equality::describe_empty_for_problems(bp_family *self, OUTPUT_STREAM,
	binary_predicate *bp) {
	return FALSE;
}
void Calculus::Equality::describe_empty_for_index(bp_family *self, OUTPUT_STREAM,
	binary_predicate *bp) {
	WRITE("never-holding");
}
