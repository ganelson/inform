[Properties::ComparativeRelations::] Comparative Relations.

When a measurement adjective like "tall" is defined, so is a
comparative relation like "taller than".

@h Definitions.

@ This section handles the |PROPERTY_COMPARISON_KBP| relations. Unlike the
other relations to do with property values, these do not correspond exactly
with the properties. Some properties, like "carrying capacity", might
never be compared with measurement adjectives; others, like "height", might
be compared with more than one ("short", "tall").

@h Initial stock.
There is no initial stock of these, since there are no value properties yet
when Inform starts up.

=
void Properties::ComparativeRelations::REL_create_initial_stock(void) {
}

@h Second stock.
When an adjective is defined so that it performs an inequality comparison
of a property value, like so:

>> Definition: A woman is tall if her height is 68 or more.

...Inform automatically generates a comparative form (here "taller than").
This is where our comparative relations come from, but the work is done in
the previous section.

=
void Properties::ComparativeRelations::REL_create_second_stock(void) {
	Properties::Measurement::create_comparatives();
}

@h Typechecking.
Because of the ambiguity between absolute and relative comparisons (see
below), we'll typecheck this asymmetrically; the left term is typechecked
as usual, but the right is more leniently handled.

=
int Properties::ComparativeRelations::REL_typecheck(binary_predicate *bp,
	kind **kinds_of_terms, kind **kinds_required, tc_problem_kit *tck) {

	if ((kinds_required[0]) &&
		(Kinds::Compare::compatible(kinds_of_terms[0], kinds_required[0]) == NEVER_MATCH)) {
		LOG("Term 0 is $u not $u\n", kinds_of_terms[0], kinds_required[0]);
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
int Properties::ComparativeRelations::REL_assert(binary_predicate *bp,
		inference_subject *infs0, parse_node *spec0,
		inference_subject *infs1, parse_node *spec1) {
	return FALSE;
}

@h Compilation.
We need do nothing special: these relations can be compiled from their schemas.

=
int Properties::ComparativeRelations::REL_compile(int task, binary_predicate *bp,
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
	if ((Kinds::Compare::eq(st[0], st[1]) == FALSE) &&
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
int Properties::ComparativeRelations::REL_describe_for_problems(OUTPUT_STREAM, binary_predicate *bp) {
	return FALSE;
}
