[Calculus::Adjectival::] The Adjectival Predicates.

To define the predicates connected to limguistic adjectives.

@

= (early code)
up_family *adjectival_up_family = NULL;

@

=
void Calculus::Adjectival::start(void) {
	adjectival_up_family = UnaryPredicateFamilies::new();
	#ifdef CORE_MODULE
	METHOD_ADD(adjectival_up_family, TYPECHECK_UPF_MTID, Calculus::Adjectival::typecheck);
	METHOD_ADD(adjectival_up_family, INFER_KIND_UPF_MTID, Calculus::Adjectival::infer_kind);
	METHOD_ADD(adjectival_up_family, ASSERT_UPF_MTID, Calculus::Adjectival::assert);
	METHOD_ADD(adjectival_up_family, TESTABLE_UPF_MTID, Calculus::Adjectival::testable);
	METHOD_ADD(adjectival_up_family, TEST_UPF_MTID, Calculus::Adjectival::test);
	METHOD_ADD(adjectival_up_family, SCHEMA_UPF_MTID, Calculus::Adjectival::get_schema);
	#endif
	METHOD_ADD(adjectival_up_family, LOG_UPF_MTID, Calculus::Adjectival::log);
}

void Calculus::Adjectival::log(up_family *self, OUTPUT_STREAM, unary_predicate *up) {
	if (UnaryPredicates::get_parity(up) == FALSE) WRITE("not-");
	wording W = Adjectives::get_nominative_singular(UnaryPredicates::get_adj(up));
	WRITE("%W", W);
}

#ifdef CORE_MODULE
void Calculus::Adjectival::infer_kind(up_family *self, unary_predicate *up, kind **K) {
	adjective *aph = UnaryPredicates::get_adj(up);
	adjective_meaning *am = Adjectives::Meanings::first_meaning(aph);
	kind *D = Adjectives::Meanings::get_domain(am);
	if (D) *K = D;
}
#endif

#ifdef CORE_MODULE
int Calculus::Adjectival::typecheck(up_family *self, unary_predicate *up,
	pcalc_prop *prop, variable_type_assignment *vta, tc_problem_kit *tck) {
	if (Propositions::Checker::type_check_unary_predicate(prop, vta, tck) == NEVER_MATCH)
		return NEVER_MATCH;
	return DECLINE_TO_MATCH;
}
#endif

@ Next, asserting $adjective(t)$. We know that $t$ evaluates to a kind
of value over which $adjective$ is defined, or the proposition would
not have survived type-checking. But only some adjectives can be asserted;
"open" can, but "visible" can't, for instance. |Adjectives::Meanings::assert| returns a
success flag.

=
#ifdef CORE_MODULE
void Calculus::Adjectival::assert(up_family *self, unary_predicate *up,
	int now_negated, pcalc_prop *pl) {
	adjective *aph = UnaryPredicates::get_adj(up);
	int parity = (now_negated)?FALSE:TRUE, found;
	if (UnaryPredicates::get_parity(up) == FALSE) parity = (parity)?FALSE:TRUE;
	inference_subject *ox = Propositions::Assert::subject_of_term(pl->terms[0]);

	parse_node *ots = Propositions::Assert::spec_of_term(pl->terms[0]);

	kind *domain_of_definition = InferenceSubjects::domain(ox);
	if (domain_of_definition == NULL) {
		instance *inst = InferenceSubjects::as_object_instance(ox);
		if (inst) domain_of_definition = Instances::to_kind(inst);
	}

	inference_subject *try = ox;
	while ((domain_of_definition == NULL) && (try)) {
		domain_of_definition = InferenceSubjects::domain(try);
		try = InferenceSubjects::narrowest_broader_subject(try);
	}
	if (domain_of_definition == NULL)
		domain_of_definition = Node::get_kind_of_value(ots);

	if (ox) found = Adjectives::Meanings::assert(aph, domain_of_definition, ox, NULL, parity);
	else found = Adjectives::Meanings::assert(aph, domain_of_definition, NULL, ots, parity);

	if (found == FALSE) Propositions::Assert::issue_couldnt_problem(aph, parity);
}
#endif

#ifdef CORE_MODULE
int Calculus::Adjectival::testable(up_family *self, unary_predicate *up) {
	adjective *aph = UnaryPredicates::get_adj(up);
	property *prn = Adjectives::Meanings::has_EORP_meaning(aph, NULL);
	if (prn == NULL) return FALSE;
	return TRUE;
}
#endif

#ifdef CORE_MODULE
int Calculus::Adjectival::test(up_family *self, unary_predicate *up,
	TERM_DOMAIN_CALCULUS_TYPE *about) {
	adjective *aph = UnaryPredicates::get_adj(up);
	int sense = UnaryPredicates::get_parity(up);
	property *prn = Adjectives::Meanings::has_EORP_meaning(aph, NULL);
	if (prn) {
		possession_marker *adj = Properties::get_possession_marker(prn);
		if (sense) {
			if (adj->possessed == FALSE) return FALSE;
		} else {
			if (adj->possessed == TRUE) return FALSE;
		}
		return TRUE;
	}
	return FALSE;
}
#endif

#ifdef CORE_MODULE
void Calculus::Adjectival::get_schema(up_family *self, int task, unary_predicate *up,
	annotated_i6_schema *asch, kind *K) {
	int atask = 0; /* redundant assignment to appease |gcc -O2| */
	adjective *aph = UnaryPredicates::get_adj(up);

	if (UnaryPredicates::get_parity(up) == FALSE) asch->negate_schema = TRUE;

	switch(task) {
		case TEST_ATOM_TASK: atask = TEST_ADJECTIVE_TASK; break;
		case NOW_ATOM_TRUE_TASK: atask = NOW_ADJECTIVE_TRUE_TASK; break;
		case NOW_ATOM_FALSE_TASK: atask = NOW_ADJECTIVE_FALSE_TASK; break;
	}

	asch->schema = Adjectives::Meanings::get_i6_schema(aph, K, atask);
}
#endif
