[Relations::Universal::] The Universal Relation.

To define the universal relation, which can apply and therefore
subsumes all other relations.

@h Definitions.

@d VERB_MEANING_UNIVERSAL_CALCULUS_RELATION R_universal

= (early code)
binary_predicate *R_universal = NULL;
binary_predicate *R_meaning = NULL;

@h Family.

=
bp_family *universal_bp_family = NULL;

void Relations::Universal::start(void) {
	universal_bp_family = BinaryPredicateFamilies::new();
	METHOD_ADD(universal_bp_family, STOCK_BPF_MTID, Relations::Universal::stock);
	METHOD_ADD(universal_bp_family, TYPECHECK_BPF_MTID, Relations::Universal::typecheck);
	METHOD_ADD(universal_bp_family, ASSERT_BPF_MTID, Relations::Universal::assert);
	METHOD_ADD(universal_bp_family, SCHEMA_BPF_MTID, Relations::Universal::schema);
	METHOD_ADD(universal_bp_family, DESCRIBE_FOR_PROBLEMS_BPF_MTID, Relations::Universal::describe_for_problems);
}

@h Initial stock.
There are just two relations of this kind, and both are hard-wired in.

=
void Relations::Universal::stock(bp_family *self, int n) {
	if (n == 1) {
		R_universal =
			BinaryPredicates::make_pair(universal_bp_family,
				BPTerms::new(NULL), BPTerms::new(NULL),
				I"relates", NULL, NULL, NULL,
				PreformUtilities::wording(<relation-names>, UNIVERSAL_RELATION_NAME));
		R_meaning =
			BinaryPredicates::make_pair(universal_bp_family,
				BPTerms::new(NULL), BPTerms::new(NULL),
				I"means", NULL, NULL, NULL,
				PreformUtilities::wording(<relation-names>, MEANING_RELATION_NAME));
	}
}

@h Typechecking.
Universality is tricky to check.

=
int Relations::Universal::typecheck(bp_family *self, binary_predicate *bp,
	kind **kinds_of_terms, kind **kinds_required, tc_problem_kit *tck) {
	if (bp == R_meaning) {
		if (Kinds::eq(kinds_of_terms[0], K_verb) == FALSE) {
			Problems::quote_kind(4, kinds_of_terms[0]);
			StandardProblems::tcp_problem(_p_(...), tck,
				"that asks whether something means something, and in Inform 'to mean' "
				"means that a particular relation is the meaning of a given verb. "
				"Here, though, we have %4 rather than the name of a verb.");
			return NEVER_MATCH;
		}
		if (Kinds::get_construct(kinds_of_terms[1]) != CON_relation) {
			Problems::quote_kind(4, kinds_of_terms[1]);
			StandardProblems::tcp_problem(_p_(...), tck,
				"that asks whether something means something, and in Inform 'to mean' "
				"means that a particular relation is the meaning of a given verb. "
				"Here, though, we have %4 rather than the name of a relation.");
			return NEVER_MATCH;
		}
	} else {
		if (Kinds::get_construct(kinds_of_terms[0]) != CON_relation) {
			Problems::quote_kind(4, kinds_of_terms[0]);
			StandardProblems::tcp_problem(_p_(BelievedImpossible), tck,
				"that asks whether something relates something, and in Inform 'to relate' "
				"means that a particular relation applies between two things. Here, though, "
				"we have %4 rather than the name of a relation.");
			return NEVER_MATCH;
		}
		if (Kinds::get_construct(kinds_of_terms[1]) != CON_combination) {
			Problems::quote_kind(4, kinds_of_terms[1]);
			StandardProblems::tcp_problem(_p_(BelievedImpossible), tck,
				"that asks whether something relates something, and in Inform 'to relate' "
				"means that a particular relation applies between two things. Here, though, "
				"we have %4 rather than the combination of the two things.");
			return NEVER_MATCH;
		}
		kind *rleft = NULL, *rright = NULL;
		Kinds::binary_construction_material(kinds_of_terms[0], &rleft, &rright);
		kind *cleft = NULL, *cright = NULL;
		Kinds::binary_construction_material(kinds_of_terms[1], &cleft, &cright);
		if (Kinds::compatible(cleft, rleft) == NEVER_MATCH) {
			Problems::quote_kind(5, kinds_of_terms[0]);
			Problems::quote_kind(4, cleft);
			StandardProblems::tcp_problem(_p_(BelievedImpossible), tck,
				"that applies a relation to values of the wrong kinds: we have %5, but "
				"the left-hand value here is %4.");
			return NEVER_MATCH;
		}
		if (Kinds::compatible(cright, rright) == NEVER_MATCH) {
			Problems::quote_kind(5, kinds_of_terms[0]);
			Problems::quote_kind(4, cright);
			StandardProblems::tcp_problem(_p_(BelievedImpossible), tck,
				"that applies a relation to values of the wrong kinds: we have %5, but "
				"the right-hand value here is %4.");
			return NEVER_MATCH;
		}
	}

	return ALWAYS_MATCH;
}

@h Assertion.
This can't be asserted; it's for use at run-time only.

=
int Relations::Universal::assert(bp_family *self, binary_predicate *bp,
		inference_subject *infs0, parse_node *spec0,
		inference_subject *infs1, parse_node *spec1) {
	return FALSE;
}

@h Compilation.
Run-time is too late to change which verbs mean what, so this relation
can't be changed at compile time, but the universal relation can.

=
int Relations::Universal::schema(bp_family *self, int task, binary_predicate *bp,
	annotated_i6_schema *asch) {
	if (bp == R_meaning) {
		switch(task) {
			case TEST_ATOM_TASK:
				Calculus::Schemas::modify(asch->schema, "*=-(ComparePV(*1(CV_MEANING), *2)==0)");
				return TRUE;
		}
	} else {
		switch(task) {
			case TEST_ATOM_TASK:
				Calculus::Schemas::modify(asch->schema, "*=-((RlnGetF(*1, RR_HANDLER))(*1, RELS_TEST, *&))");
				return TRUE;
			case NOW_ATOM_TRUE_TASK:
				Calculus::Schemas::modify(asch->schema, "*=-((RlnGetF(*1, RR_HANDLER))(*1, RELS_ASSERT_TRUE, *&))");
				return TRUE;
			case NOW_ATOM_FALSE_TASK:
				Calculus::Schemas::modify(asch->schema, "*=-((RlnGetF(*1, RR_HANDLER))(*1, RELS_ASSERT_FALSE, *&))");
				return TRUE;
		}
	}
	return FALSE;
}

@h Problem message text.
Nothing special is needed here.

=
int Relations::Universal::describe_for_problems(bp_family *self, OUTPUT_STREAM, binary_predicate *bp) {
	return FALSE;
}
