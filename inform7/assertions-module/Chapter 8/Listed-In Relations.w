[Tables::Relations::] Listed-In Relations.

To define the binary predicates corresponding to table columns,
and which determine whether a given value is listed in that column.

@h Family.

=
bp_family *listed_in_bp_family = NULL;

void Tables::Relations::start(void) {
	listed_in_bp_family = BinaryPredicateFamilies::new();
	METHOD_ADD(listed_in_bp_family, TYPECHECK_BPF_MTID, Tables::Relations::typecheck);
	METHOD_ADD(listed_in_bp_family, ASSERT_BPF_MTID, Tables::Relations::assert);
	METHOD_ADD(listed_in_bp_family, SCHEMA_BPF_MTID, Tables::Relations::schema);
	METHOD_ADD(listed_in_bp_family, DESCRIBE_FOR_PROBLEMS_BPF_MTID, Tables::Relations::describe_for_problems);
}

@h Subsequent creations.
When a column called, say, "pledged delegate count" appears in one or more
tables in the source text, Inform creates a |table_column| structure to
represent the common identity of all table columns with this name. (They
are required all to share the same kind of value in their entries.) For
each different table column, a BP is created to represent the meaning
of "X is a pledged delegate count listed in T". Arguably there should just
be one super-powerful predicate |listed-in(X, C, T)|, but that would need
to be a ternary predicate, not binary, and Inform doesn't at present support
those. So we make a one-parameter family of |listed-in-C(X, T)| binary
predicates instead.

=
binary_predicate *Tables::Relations::make_listed_in_predicate(table_column *tc) {
	binary_predicate *bp = BinaryPredicates::make_pair(listed_in_bp_family,
		BPTerms::new(NULL),
		BPTerms::new(KindSubjects::from_kind(K_table)),
		I"listed_in", I"lists-in", NULL,
		Calculus::Schemas::new("(ct_1=ExistsTableRowCorr(ct_0=*2,%n,*1))",
			RTTables::column_id(tc)), WordAssemblages::lit_0());
	return bp;
}

@ Once again there is a timing constraint. Tables are created quite early
on in Inform's run, but the entries in the columns aren't parsed until much
later. Since the kind of value stored in a column is often determined only
by looking at those values, it follows that we can't specify what goes into
the left-hand term at the time when the column is created. So we fill this
in later, instead:

=
void Tables::Relations::supply_kind_for_listed_in_tc(binary_predicate *bp, kind *K) {
	BPTerms::set_domain(&(bp->term_details[0]), K);
	BPTerms::set_domain(&(bp->reversal->term_details[1]), K);
}

@h Typechecking.

=
int Tables::Relations::typecheck(bp_family *self, binary_predicate *bp,
		kind **kinds_of_terms, kind **kinds_required, tc_problem_kit *tck) {
	return DECLINE_TO_MATCH;
}

@h Assertion.
These relations cannot be asserted.

=
int Tables::Relations::assert(bp_family *self, binary_predicate *bp,
		inference_subject *infs0, parse_node *spec0,
		inference_subject *infs1, parse_node *spec1) {
	return FALSE;
}

@h Compilation.
Note the side-effect here: we ensure that the |ct| local variables will be
present in the current stack frame, since we're going to need them to hold
the table reference for any successful lookup.

=
int Tables::Relations::schema(bp_family *self, int task, binary_predicate *bp, annotated_i6_schema *asch) {
	if (task == TEST_ATOM_TASK) LocalVariables::add_table_lookup();
	return FALSE;
}

@h Problem message text.

=
int Tables::Relations::describe_for_problems(bp_family *self, OUTPUT_STREAM, binary_predicate *bp) {
	WRITE("the listed in relation");
	return TRUE;
}
