[BinaryPredicateFamilies::] Binary Predicate Families.

To create sets of relations for different purposes.

@ Want to create a new binary predicate? First you'll need a family for it to
belong to. Some families are small (the equality family contains just the
equality relation), others larger (the map connections family in an IF compilation
has one for each map direction). What unites the members of a family is that
they share an implementation of typechecking, asserting and compilation --
in other words, if two predicates are implemented roughly the same way, then
they should be in the same family, and otherwise not. Inform currently has
a little over 10 different families.

A //bp_family// object is simply a receiver for the method calls providing
the predicate's implementation.

=
typedef struct bp_family {
	struct method_set *methods;
	CLASS_DEFINITION
} bp_family;

bp_family *BinaryPredicateFamilies::new(void) {
	bp_family *f = CREATE(bp_family);
	f->methods = Methods::new_set();
	return f;
}

@ |STOCK_BPF_MTID| is for stocking up on relations. Stage 1 happens very early
in Inform's run, and allows built-in essentials such as equality to be created.
Stage 2 is later on, when the world model is complete but before code is compiled,
and gives an opportunity to make, say, one relation for every value property.

@e STOCK_BPF_MTID

=
VOID_METHOD_TYPE(STOCK_BPF_MTID, bp_family *f, int n)

void BinaryPredicateFamilies::first_stock(void) {
	UnaryPredicateFamilies::stock(1);
	bp_family *f;
	LOOP_OVER(f, bp_family)
		VOID_METHOD_CALL(f, STOCK_BPF_MTID, 1);
}

void BinaryPredicateFamilies::second_stock(void) {
	UnaryPredicateFamilies::stock(2);
	bp_family *f;
	LOOP_OVER(f, bp_family)
		VOID_METHOD_CALL(f, STOCK_BPF_MTID, 2);
}

@ This is for typechecking, and gives the opportunity to reject relationships
such as "if 19 is false", where the terms of the relation do not fit.

@e TYPECHECK_BPF_MTID

=
INT_METHOD_TYPE(TYPECHECK_BPF_MTID, bp_family *f, binary_predicate *bp,
	kind **kinds_of_terms, kind **kinds_required, tc_problem_kit *tck)

int BinaryPredicateFamilies::typecheck(binary_predicate *bp,
	kind **kinds_of_terms, kind **kinds_required, tc_problem_kit *tck) {
	int rv = DECLINE_TO_MATCH;
	INT_METHOD_CALL(rv, bp->relation_family, TYPECHECK_BPF_MTID, bp, kinds_of_terms,
		kinds_required, tck);
	return rv;
}

@ This is for when a relation is asserted to be a true fact about the model
world.

@e ASSERT_BPF_MTID

=
INT_METHOD_TYPE(ASSERT_BPF_MTID, bp_family *f, binary_predicate *bp,
	TERM_DOMAIN_CALCULUS_TYPE *subj0, parse_node *spec0,
	TERM_DOMAIN_CALCULUS_TYPE *subj1, parse_node *spec1) 

int BinaryPredicateFamilies::assert(binary_predicate *bp,
	TERM_DOMAIN_CALCULUS_TYPE *subj0, parse_node *spec0,
	TERM_DOMAIN_CALCULUS_TYPE *subj1, parse_node *spec1) {
	int rv = FALSE;
	INT_METHOD_CALL(rv, bp->relation_family, ASSERT_BPF_MTID, bp, subj0, spec0, subj1, spec1);
	return rv;
}

@ This is for compiling run-time code to either test a relation, make a
relation true from now on, or make it false.

Some constants here enumerate the three cases of what we are to do. This
looks asymmetrical -- shouldn't we also test to see whether an atom is false,
a fourth case?

The answer is that there's no need, since "test false" can be done by
compiling "test true" and then negating. No similar trick can be used to
combine making something true or false into a single operation.

@d NO_ATOM_TASKS 3

@d TEST_ATOM_TASK 1
@d NOW_ATOM_TRUE_TASK 2
@d NOW_ATOM_FALSE_TASK 3

@e SCHEMA_BPF_MTID

=
INT_METHOD_TYPE(SCHEMA_BPF_MTID, bp_family *f, int task, binary_predicate *bp,
	annotated_i6_schema *asch)

i6_schema *BinaryPredicateFamilies::get_schema(int task, binary_predicate *bp,
	annotated_i6_schema *asch) {
	int rv = FALSE;
	INT_METHOD_CALL(rv, bp->relation_family, SCHEMA_BPF_MTID, task, bp, asch);
	if ((rv == FALSE) && (task)) asch->schema = bp->task_functions[task];
	return asch->schema;
}

@ This allows BPs to print a name for themselves other than their |relation_name|
fields, when they are mentioned in problem messages.

@e DESCRIBE_FOR_PROBLEMS_BPF_MTID

=
INT_METHOD_TYPE(DESCRIBE_FOR_PROBLEMS_BPF_MTID, bp_family *f, text_stream *OUT,
	binary_predicate *bp)

void BinaryPredicateFamilies::describe_for_problems(OUTPUT_STREAM, binary_predicate *bp) {
	int success = FALSE;
	INT_METHOD_CALL(success, bp->relation_family, DESCRIBE_FOR_PROBLEMS_BPF_MTID, OUT, bp);
	if (success == NOT_APPLICABLE) return;
	if (success == FALSE) {
		if (WordAssemblages::nonempty(bp->relation_name)) WRITE("the %A", &(bp->relation_name));
		else WRITE("a");
		WRITE(" relation");
	}
	kind *K0 = BinaryPredicates::term_kind(bp, 0); if (K0 == NULL) K0 = K_object;
	kind *K1 = BinaryPredicates::term_kind(bp, 1); if (K1 == NULL) K1 = K_object;
	WRITE(" (between ");
	if (Kinds::eq(K0, K1)) {
		Kinds::Textual::write_plural(OUT, K0);
	} else {
		Kinds::Textual::write_articled(OUT, K0);
		WRITE(" and ");
		Kinds::Textual::write_articled(OUT, K1);
	}
	WRITE(")");
}

@ This can optionally write a super-brief description, usually just one adjective:
something like "one-to-one".

@e DESCRIBE_FOR_INDEX_BPF_MTID

=
VOID_METHOD_TYPE(DESCRIBE_FOR_INDEX_BPF_MTID, bp_family *f, text_stream *OUT, 
	binary_predicate *bp)

void BinaryPredicateFamilies::describe_for_index(OUTPUT_STREAM, binary_predicate *bp) {
	VOID_METHOD_CALL(bp->relation_family, DESCRIBE_FOR_INDEX_BPF_MTID, OUT, bp);
}
