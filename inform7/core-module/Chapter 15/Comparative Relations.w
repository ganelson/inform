[Properties::ComparativeRelations::] Comparative Relations.

When a measurement adjective like "tall" is defined, so is a
comparative relation like "taller than".

@h Family.
Unlike the other relations to do with property values, these do not correspond
exactly with the properties. Some properties, like "carrying capacity", might
never be compared with measurement adjectives; others, like "height", might
be compared with more than one ("short", "tall").

=
bp_family *property_comparison_bp_family = NULL;

void Properties::ComparativeRelations::start(void) {
	property_comparison_bp_family = BinaryPredicateFamilies::new();
	METHOD_ADD(property_comparison_bp_family, STOCK_BPF_MTID, Properties::ComparativeRelations::stock);
	METHOD_ADD(property_comparison_bp_family, TYPECHECK_BPF_MTID, Properties::ComparativeRelations::REL_typecheck);
	METHOD_ADD(property_comparison_bp_family, ASSERT_BPF_MTID, Properties::ComparativeRelations::REL_assert);
	METHOD_ADD(property_comparison_bp_family, SCHEMA_BPF_MTID, Properties::ComparativeRelations::REL_compile);
	METHOD_ADD(property_comparison_bp_family, DESCRIBE_FOR_PROBLEMS_BPF_MTID, Properties::ComparativeRelations::REL_describe_for_problems);
}

@h Second stock.
When an adjective is defined so that it performs an inequality comparison
of a property value, like so:

>> Definition: A woman is tall if her height is 68 or more.

...Inform automatically generates a comparative form (here "taller than").
This is where our comparative relations come from, but the work is done in
the previous section.

=
void Properties::ComparativeRelations::stock(bp_family *self, int n) {
	if (n == 2) {
		Properties::Measurement::create_comparatives();
	}
}

@h Typechecking.
Because of the ambiguity between absolute and relative comparisons (see
below), we'll typecheck this asymmetrically; the left term is typechecked
as usual, but the right is more leniently handled.

=
int Properties::ComparativeRelations::REL_typecheck(bp_family *self, binary_predicate *bp,
	kind **kinds_of_terms, kind **kinds_required, tc_problem_kit *tck) {

	if ((kinds_required[0]) &&
		(Kinds::compatible(kinds_of_terms[0], kinds_required[0]) == NEVER_MATCH)) {
		LOG("Term 0 is %u not %u\n", kinds_of_terms[0], kinds_required[0]);
		Calculus::Propositions::Checker::issue_bp_typecheck_error(bp,
			kinds_of_terms[0], kinds_of_terms[1], tck);
		return NEVER_MATCH;
	}

	property *prn = Properties::Conditions::get_coinciding_property(kinds_of_terms[1]);
	if ((prn) && (prn != bp->comparative_property)) {
		if (tck->log_to_I6_text)
			LOG("Comparative misapplied to $Y not $Y\n", prn, bp->comparative_property);
		Problems::quote_property(4, bp->comparative_property);
		Problems::quote_property(5, prn);
		StandardProblems::tcp_problem(_p_(PM_ComparativeMisapplied), tck,
			"that ought to make a comparison of %4 not %5.");
		return NEVER_MATCH;
	}
	return ALWAYS_MATCH;
}

@h Assertion.

=
int Properties::ComparativeRelations::REL_assert(bp_family *self, binary_predicate *bp,
		inference_subject *infs0, parse_node *spec0,
		inference_subject *infs1, parse_node *spec1) {
	return FALSE;
}

@h Compilation.
We need do nothing special: these relations can be compiled from their schemas.

=
int Properties::ComparativeRelations::REL_compile(bp_family *self, int task, binary_predicate *bp,
	annotated_i6_schema *asch) {
	if (task == TEST_ATOM_TASK)
		@<Rewrite the annotated schema if it turns out to be an absolute comparison@>;
	return FALSE;
}

@ Normally, "taller than" would relate two people, and compare their heights.
But we also want to allow absolute comparison like this one:

>> if Geoff is taller than 4 foot 5 inches, ...

In that case we need a different schema, where right and left are not handled
so symmetrically; we rewrite the annotated schema on the fly.

@<Rewrite the annotated schema if it turns out to be an absolute comparison@> =
	kind *st[2];
	st[0] = Calculus::Deferrals::Cinders::kind_of_value_of_term(asch->pt0);
	st[1] = Calculus::Deferrals::Cinders::kind_of_value_of_term(asch->pt1);
	if ((Kinds::eq(st[0], st[1]) == FALSE) &&
		(Properties::Conditions::name_can_coincide_with_property(st[1]))) {
		property *prn = Properties::Conditions::get_coinciding_property(st[1]);
		if (prn) {
			Calculus::Schemas::modify(asch->schema,
				"*1.%n %s *2", Properties::iname(prn),
				Properties::Measurement::strict_comparison(bp->comparison_sign));
			return TRUE;
		}
	}

@h Problem message text.

=
int Properties::ComparativeRelations::REL_describe_for_problems(bp_family *self, OUTPUT_STREAM, binary_predicate *bp) {
	return FALSE;
}
