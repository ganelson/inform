[AdjectivesByCondition::] Adjectives by Condition.

Adjectives defined by a one-line I7 condition.

@ These are adjectives for when the condition is given in a single line, like so --
= (text as Inform 7)
Definition: A container is roomy if its carrying capacity is greater than 10.
=
...but has no special form. The high priority number in the call to
//AdjectiveMeanings::new_family// means that this family is the last in line
when claiming adjectives; it accepts any that are left unclaimed.

=
adjective_meaning_family *condition_amf = NULL; /* defined by a condition in I7 source text */

void AdjectivesByCondition::start(void) {
	condition_amf = AdjectiveMeanings::new_family(7);
	METHOD_ADD(condition_amf, GENERATE_IN_SUPPORT_FUNCTION_ADJM_MTID,
		RTAdjectives::support_for_I7_condition);
	METHOD_ADD(condition_amf, CLAIM_DEFINITION_SENTENCE_ADJM_MTID,
		AdjectivesByCondition::claim_definition);
}

@ =
int AdjectivesByCondition::claim_definition(adjective_meaning_family *f,
	adjective_meaning **result, parse_node *q,
	int sense, wording AW, wording DNW, wording CONW, wording CALLW) {
	if (sense == 0) return FALSE;
	definition *def = AdjectivalDefinitionFamily::new_definition(q);
	adjective_meaning *am =
		AdjectiveMeanings::new(condition_amf, STORE_POINTER_definition(def),
			Node::get_text(q));
	def->condition_to_match = CONW;
	def->format = sense;
	def->domain_calling = CALLW;
	def->am_of_def = am;
	adjective *adj = Adjectives::declare(AW, NULL);
	AdjectiveAmbiguity::add_meaning_to_adjective(am, adj);
	AdjectiveMeanings::perform_task_via_function(am, TEST_ATOM_TASK);
	AdjectiveMeaningDomains::set_from_text(am, DNW);
	*result = am;
	return TRUE;
}
