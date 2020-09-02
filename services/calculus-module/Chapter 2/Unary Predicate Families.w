[UnaryPredicateFamilies::] Unary Predicate Families.

To create sets of unary predicates for different purposes.

@ Want to create a new unary predicate? First you'll need a family for it to
belong to. A //up_family// object is simply a receiver for the method calls
providing the predicate's implementation. In effect, a family is a collection
of UPs which share an implementation.

=
typedef struct up_family {
	struct method_set *methods;
	CLASS_DEFINITION
} up_family;

up_family *UnaryPredicateFamilies::new(void) {
	up_family *f = CREATE(up_family);
	f->methods = Methods::new_set();
	return f;
}

@ |STOCK_UPF_MTID| is for stocking up on unaries, and happens very early
in Inform's run.

@e STOCK_UPF_MTID

=
VOID_METHOD_TYPE(STOCK_UPF_MTID, up_family *f, int n)

void UnaryPredicateFamilies::stock(int n) {
	up_family *f;
	LOOP_OVER(f, up_family)
		VOID_METHOD_CALL(f, STOCK_UPF_MTID, n);
}

@ This method performs a type-check to see whether the value supplied as the
term of the predicate is acceptable. For example, |even(t)| should reject
|t| if it is a text, because |even| is meaningful only for numbers.

@e TYPECHECK_UPF_MTID

=
typedef struct variable_type_assignment {
	struct kind *assigned_kinds[26]; /* one for each of the 26 variables */
} variable_type_assignment;

INT_METHOD_TYPE(TYPECHECK_UPF_MTID, up_family *f, unary_predicate *up,
	pcalc_prop *prop, variable_type_assignment *vta, tc_problem_kit *tck)

int UnaryPredicateFamilies::typecheck(unary_predicate *up,
	pcalc_prop *prop, variable_type_assignment *vta, tc_problem_kit *tck) {
	int rv = DECLINE_TO_MATCH;
	INT_METHOD_CALL(rv, up->family, TYPECHECK_UPF_MTID, up, prop, vta, tck);
	return rv;
}

@ A unary predicate is "testable" if its truth can be determined at compile
time. (We assume everything can be tested at run time.) For example,
|kind=number(t)| can generally be tested at compile time, but |even(t)| cannot.

@e TESTABLE_UPF_MTID

=
INT_METHOD_TYPE(TESTABLE_UPF_MTID, up_family *f, unary_predicate *up)

int UnaryPredicateFamilies::testable(unary_predicate *up) {
	int rv = FALSE;
	INT_METHOD_CALL(rv, up->family, TESTABLE_UPF_MTID, up);
	return rv;
}

@ And for a testable UP, the following should perform that test. It will never
be called for non-testable ones.

@e TEST_UPF_MTID

=
INT_METHOD_TYPE(TEST_UPF_MTID, up_family *f, unary_predicate *up,
	TERM_DOMAIN_CALCULUS_TYPE *about)

int UnaryPredicateFamilies::test(unary_predicate *up, TERM_DOMAIN_CALCULUS_TYPE *about) {
	int rv = FALSE;
	INT_METHOD_CALL(rv, up->family, TEST_UPF_MTID, up, about);
	return rv;
}

@ Assertion is used in Inform when constructing the model world. The //calculus//
module doesn't really get involved in this, and provides this method only for
Inform's benefit.


@e ASSERT_UPF_MTID

=
VOID_METHOD_TYPE(ASSERT_UPF_MTID, up_family *f, unary_predicate *up,
	int now_negated, pcalc_prop *pl)

void UnaryPredicateFamilies::assert(unary_predicate *up,
	int now_negated, pcalc_prop *pl) {
	VOID_METHOD_CALL(up->family, ASSERT_UPF_MTID, up, now_negated, pl);
}

@ Schemas are used in compilation: see //Compilation Schemas// for more.
Again, the //calculus// module doesn't really get involved in this.

@e SCHEMA_UPF_MTID

=
VOID_METHOD_TYPE(SCHEMA_UPF_MTID, up_family *f, int task, unary_predicate *up,
	annotated_i6_schema *asch, kind *K)

void UnaryPredicateFamilies::get_schema(int task, unary_predicate *up,
	annotated_i6_schema *asch, kind *K) {
	VOID_METHOD_CALL(up->family, SCHEMA_UPF_MTID, task, up, asch, K);
}

@ If the usage of this UP implies the kind of its term, here's where we say so.
The obvious example is |kind=K(t)|, which necessarily means |t| has kind |K|.
But one could also imagine UPs which are appropriate only for, say, real numbers.

@e INFER_KIND_UPF_MTID

=
VOID_METHOD_TYPE(INFER_KIND_UPF_MTID, up_family *f, unary_predicate *up, kind **K)

kind *UnaryPredicateFamilies::infer_kind(unary_predicate *up) {
	kind *K = NULL;
	VOID_METHOD_CALL(up->family, INFER_KIND_UPF_MTID, up, &K);
	return K;
}

@ Logging should be brief: something like |kind=number| is plenty.

@e LOG_UPF_MTID

=
VOID_METHOD_TYPE(LOG_UPF_MTID, up_family *f, text_stream *OUT, 
	unary_predicate *up)

void UnaryPredicateFamilies::log(OUTPUT_STREAM, unary_predicate *up) {
	VOID_METHOD_CALL(up->family, LOG_UPF_MTID, OUT, up);
}
