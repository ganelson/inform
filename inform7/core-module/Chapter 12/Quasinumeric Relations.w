[Calculus::QuasinumericRelations::] Quasinumeric Relations.

To define the binary predicates corresponding to numerical
comparisons.

@h Definitions.

@ The inequality relations $<$, $>$, $\leq$, and $\geq$, which can be
applied not only to numbers but also to units (height, length and so on).

It might seem redundant to define both |R_numerically_greater_than| (which makes the
numerical test $a>b$) and also |R_numerically_less_than| (which tests $a<b$). Why
not define only one, and get the other meaning free as its reversal? The
answer is that is more convenient not to, because it allows us to give both
of them names.

There is no numerical equality relation $=$ as such: numbers use the same
equality BP as everything else.

= (early code)
binary_predicate *R_numerically_greater_than = NULL;
binary_predicate *R_numerically_less_than = NULL;
binary_predicate *R_numerically_greater_than_or_equal_to = NULL;
binary_predicate *R_numerically_less_than_or_equal_to = NULL;

@h Initial stock.
These relations are all hard-wired in.

=
void Calculus::QuasinumericRelations::REL_create_initial_stock(void) {
	bp_term_details number_term = BinaryPredicates::new_term(Kinds::Knowledge::as_subject(K_number));
	R_numerically_greater_than =
		BinaryPredicates::make_pair(QUASINUMERIC_KBP,
			number_term, number_term,
			I"greater-than", NULL, NULL, NULL, Calculus::Schemas::new("*1 > *2"),
			Preform::Nonparsing::wording(<relation-names>, GT_RELATION_NAME));
	R_numerically_less_than =
		BinaryPredicates::make_pair(QUASINUMERIC_KBP,
			number_term, number_term,
			I"less-than", NULL, NULL, NULL, Calculus::Schemas::new("*1 < *2"),
			Preform::Nonparsing::wording(<relation-names>, LT_RELATION_NAME));
	R_numerically_greater_than_or_equal_to =
		BinaryPredicates::make_pair(QUASINUMERIC_KBP,
			number_term, number_term,
			I"at-least", NULL, NULL, NULL, Calculus::Schemas::new("*1 >= *2"),
			Preform::Nonparsing::wording(<relation-names>, GE_RELATION_NAME));
	R_numerically_less_than_or_equal_to =
		BinaryPredicates::make_pair(QUASINUMERIC_KBP,
			number_term, number_term,
			I"at-most", NULL, NULL, NULL, Calculus::Schemas::new("*1 <= *2"),
			Preform::Nonparsing::wording(<relation-names>, LE_RELATION_NAME));
	BinaryPredicates::set_index_details(R_numerically_greater_than,
		"arithmetic value", "arithmetic value");
	BinaryPredicates::set_index_details(R_numerically_less_than,
		"arithmetic value", "arithmetic value");
	BinaryPredicates::set_index_details(R_numerically_greater_than_or_equal_to,
		"arithmetic value", "arithmetic value");
	BinaryPredicates::set_index_details(R_numerically_less_than_or_equal_to,
		"arithmetic value", "arithmetic value");
}

@h Second stock.
There is none -- this is a family of relations which is all built in.

=
void Calculus::QuasinumericRelations::REL_create_second_stock(void) {
}

@h Typechecking.

=
int Calculus::QuasinumericRelations::REL_typecheck(binary_predicate *bp,
		kind **kinds_of_terms, kind **kinds_required, tc_problem_kit *tck) {
	if ((Kinds::Compare::compatible(kinds_of_terms[0], kinds_of_terms[1]) == NEVER_MATCH) &&
		(Kinds::Compare::compatible(kinds_of_terms[1], kinds_of_terms[0]) == NEVER_MATCH)) {
		if (tck->log_to_I6_text)
			LOG("Unable to apply inequality of $u and $u\n", kinds_of_terms[0], kinds_of_terms[1]);
		Problems::quote_kind(4, kinds_of_terms[0]);
		Problems::quote_kind(5, kinds_of_terms[1]);
		Problems::Issue::tcp_problem(_p_(PM_InequalityFailed), tck,
			"that would mean comparing two kinds of value which cannot mix - "
			"%4 and %5 - so this must be incorrect.");
		return NEVER_MATCH;
	}
	return ALWAYS_MATCH;
}

@h Assertion.
These relations cannot be asserted.

=
int Calculus::QuasinumericRelations::REL_assert(binary_predicate *bp,
		inference_subject *infs0, parse_node *spec0,
		inference_subject *infs1, parse_node *spec1) {
	return FALSE;
}

@h Compilation.
For integer arithmetic, we need do nothing special: these relations can be
compiled from their schemas. But real numbers have to be handled by a function
call in I6.

=
int Calculus::QuasinumericRelations::REL_compile(int task, binary_predicate *bp, annotated_i6_schema *asch) {
	kind *st[2];
	st[0] = Calculus::Deferrals::Cinders::kind_of_value_of_term(asch->pt0);
	st[1] = Calculus::Deferrals::Cinders::kind_of_value_of_term(asch->pt1);
	switch (task) {
		case TEST_ATOM_TASK:
			if ((st[0]) && (st[1])) {
				text_stream *cr = NULL;
				int promote_left = FALSE, promote_right = FALSE;
				if ((Kinds::FloatingPoint::uses_floating_point(st[0])) ||
					(Kinds::FloatingPoint::uses_floating_point(st[1]))) {
					if (Kinds::FloatingPoint::uses_floating_point(st[0]) == FALSE)
						promote_left = TRUE;
					if (Kinds::FloatingPoint::uses_floating_point(st[1]) == FALSE)
						promote_right = TRUE;
					cr = Kinds::Behaviour::get_comparison_routine(K_real_number);
				} else
					cr = Kinds::Behaviour::get_comparison_routine(st[0]);
				if ((Str::len(cr) == 0) || (Str::eq_wide_string(cr, L"signed"))) return FALSE;

				if (promote_left) {
					if (bp == R_numerically_greater_than)
						Calculus::Schemas::modify(asch->schema, "*_2(NUMBER_TY_to_REAL_NUMBER_TY(*1), *2) > 0");
					if (bp == R_numerically_less_than)
						Calculus::Schemas::modify(asch->schema, "*_2(NUMBER_TY_to_REAL_NUMBER_TY(*1), *2) < 0");
					if (bp == R_numerically_greater_than_or_equal_to)
						Calculus::Schemas::modify(asch->schema, "*_2(NUMBER_TY_to_REAL_NUMBER_TY(*1), *2) >= 0");
					if (bp == R_numerically_less_than_or_equal_to)
						Calculus::Schemas::modify(asch->schema, "*_2(NUMBER_TY_to_REAL_NUMBER_TY(*1), *2) <= 0");
				} else if (promote_right) {
					if (bp == R_numerically_greater_than)
						Calculus::Schemas::modify(asch->schema, "*_1(*1, NUMBER_TY_to_REAL_NUMBER_TY(*2)) > 0");
					if (bp == R_numerically_less_than)
						Calculus::Schemas::modify(asch->schema, "*_1(*1, NUMBER_TY_to_REAL_NUMBER_TY(*2)) < 0");
					if (bp == R_numerically_greater_than_or_equal_to)
						Calculus::Schemas::modify(asch->schema, "*_1(*1, NUMBER_TY_to_REAL_NUMBER_TY(*2)) >= 0");
					if (bp == R_numerically_less_than_or_equal_to)
						Calculus::Schemas::modify(asch->schema, "*_1(*1, NUMBER_TY_to_REAL_NUMBER_TY(*2)) <= 0");
				} else {
					if (bp == R_numerically_greater_than)
						Calculus::Schemas::modify(asch->schema, "*_1(*1, *2) > 0");
					if (bp == R_numerically_less_than)
						Calculus::Schemas::modify(asch->schema, "*_1(*1, *2) < 0");
					if (bp == R_numerically_greater_than_or_equal_to)
						Calculus::Schemas::modify(asch->schema, "*_1(*1, *2) >= 0");
					if (bp == R_numerically_less_than_or_equal_to)
						Calculus::Schemas::modify(asch->schema, "*_1(*1, *2) <= 0");
				}
			} else if (problem_count == 0) {
				LOG("$0 and $0; $u and $u\n", &(asch->pt0), &(asch->pt1), st[0], st[1]);
				internal_error("null kind in equality test");
			}
			return TRUE;
	}
	return FALSE;
}

@h Problem message text.

=
int Calculus::QuasinumericRelations::REL_describe_for_problems(OUTPUT_STREAM, binary_predicate *bp) {
	return FALSE;
}
