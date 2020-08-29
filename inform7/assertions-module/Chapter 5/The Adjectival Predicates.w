[AdjectivalPredicates::] The Adjectival Predicates.

To define the predicates connected to limguistic adjectives.

@

= (early code)
up_family *adjectival_up_family = NULL;

@

=
void AdjectivalPredicates::start(void) {
	adjectival_up_family = UnaryPredicateFamilies::new();
	METHOD_ADD(adjectival_up_family, TYPECHECK_UPF_MTID, AdjectivalPredicates::typecheck);
	METHOD_ADD(adjectival_up_family, INFER_KIND_UPF_MTID, AdjectivalPredicates::infer_kind);
	METHOD_ADD(adjectival_up_family, ASSERT_UPF_MTID, AdjectivalPredicates::assert);
	METHOD_ADD(adjectival_up_family, TESTABLE_UPF_MTID, AdjectivalPredicates::testable);
	METHOD_ADD(adjectival_up_family, TEST_UPF_MTID, AdjectivalPredicates::test);
	METHOD_ADD(adjectival_up_family, SCHEMA_UPF_MTID, AdjectivalPredicates::get_schema);
	METHOD_ADD(adjectival_up_family, LOG_UPF_MTID, AdjectivalPredicates::log);
}

unary_predicate *AdjectivalPredicates::new_up(adjective *aph, int pos) {
	unary_predicate *au = UnaryPredicates::new(adjectival_up_family);
	au->lcon = Stock::to_lcon(aph->in_stock);
	if (pos) au->lcon = Lcon::set_sense(au->lcon, POSITIVE_SENSE);
	else au->lcon = Lcon::set_sense(au->lcon, NEGATIVE_SENSE);
	return au;
}

pcalc_prop *AdjectivalPredicates::new_atom(adjective *aph, int negated, pcalc_term t) {
	return Atoms::unary_PREDICATE_new(
		AdjectivalPredicates::new_up(aph, (negated)?FALSE:TRUE), t);
}

pcalc_prop *AdjectivalPredicates::new_atom_on_x(adjective *aph, int negated) {
	return AdjectivalPredicates::new_atom(aph, negated, Terms::new_variable(0));
}

void AdjectivalPredicates::log(up_family *self, OUTPUT_STREAM, unary_predicate *up) {
	if (AdjectivalPredicates::parity(up) == FALSE) WRITE("not-");
	wording W = Adjectives::get_nominative_singular(AdjectivalPredicates::to_adjective(up));
	WRITE("%W", W);
}

void AdjectivalPredicates::infer_kind(up_family *self, unary_predicate *up, kind **K) {
	adjective *aph = AdjectivalPredicates::to_adjective(up);
	adjective_meaning *am = Adjectives::Meanings::first_meaning(aph);
	kind *D = Adjectives::Meanings::get_domain(am);
	if (D) *K = D;
}

int AdjectivalPredicates::typecheck(up_family *self, unary_predicate *up,
	pcalc_prop *prop, variable_type_assignment *vta, tc_problem_kit *tck) {
	adjective *aph = AdjectivalPredicates::to_adjective(up);
	kind *K = Propositions::Checker::kind_of_term(&(prop->terms[0]), vta, tck);
	if ((aph) && (Adjectives::Meanings::applicable_to(aph, K) == FALSE)) {
		wording W = Adjectives::get_nominative_singular(aph);
		if (tck->log_to_I6_text) LOG("Adjective '%W' undefined on %u\n", W, K);
		Propositions::Checker::problem(UnaryMisapplied_CALCERROR,
			NULL, W, K, NULL, NULL, tck);
		return NEVER_MATCH;
	}
	return ALWAYS_MATCH;
}

@ Next, asserting $adjective(t)$. We know that $t$ evaluates to a kind
of value over which $adjective$ is defined, or the proposition would
not have survived type-checking. But only some adjectives can be asserted;
"open" can, but "visible" can't, for instance. |Adjectives::Meanings::assert| returns a
success flag.

=
void AdjectivalPredicates::assert(up_family *self, unary_predicate *up,
	int now_negated, pcalc_prop *pl) {
	adjective *aph = AdjectivalPredicates::to_adjective(up);
	int parity = (now_negated)?FALSE:TRUE, found;
	if (AdjectivalPredicates::parity(up) == FALSE) parity = (parity)?FALSE:TRUE;
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

int AdjectivalPredicates::testable(up_family *self, unary_predicate *up) {
	adjective *aph = AdjectivalPredicates::to_adjective(up);
	property *prn = Adjectives::Meanings::has_EORP_meaning(aph, NULL);
	if (prn == NULL) return FALSE;
	return TRUE;
}

int AdjectivalPredicates::test(up_family *self, unary_predicate *up,
	TERM_DOMAIN_CALCULUS_TYPE *about) {
	adjective *aph = AdjectivalPredicates::to_adjective(up);
	int sense = AdjectivalPredicates::parity(up);
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

void AdjectivalPredicates::get_schema(up_family *self, int task, unary_predicate *up,
	annotated_i6_schema *asch, kind *K) {
	int atask = 0; /* redundant assignment to appease |gcc -O2| */
	adjective *aph = AdjectivalPredicates::to_adjective(up);

	if (AdjectivalPredicates::parity(up) == FALSE) asch->negate_schema = TRUE;

	switch(task) {
		case TEST_ATOM_TASK: atask = TEST_ADJECTIVE_TASK; break;
		case NOW_ATOM_TRUE_TASK: atask = NOW_ADJECTIVE_TRUE_TASK; break;
		case NOW_ATOM_FALSE_TASK: atask = NOW_ADJECTIVE_FALSE_TASK; break;
	}

	asch->schema = Adjectives::Meanings::get_i6_schema(aph, K, atask);
}

@ Access:

=
adjective *AdjectivalPredicates::to_adjective(unary_predicate *up) {
	if (up == NULL) return NULL;
	if (up->family != adjectival_up_family) return NULL;
	return Adjectives::from_lcon(up->lcon);
}

int AdjectivalPredicates::parity(unary_predicate *up) {
	if (up == NULL) internal_error("null adjective tested for positivity");
	if (up->family != adjectival_up_family) return TRUE;
	if (Lcon::get_sense(up->lcon) == NEGATIVE_SENSE) return FALSE;
	return TRUE;
}

@ And this is the only non-trivial thing one can do with an adjective use:
reverse its sense.

=
void AdjectivalPredicates::flip_parity(unary_predicate *up) {
	if (up == NULL) internal_error("null adjective flipped");
	if (up->family != adjectival_up_family) internal_error("non-adjective flipped");
	if (Lcon::get_sense(up->lcon) == NEGATIVE_SENSE)
		up->lcon = Lcon::set_sense(up->lcon, POSITIVE_SENSE);
	else
		up->lcon = Lcon::set_sense(up->lcon, NEGATIVE_SENSE);
}
