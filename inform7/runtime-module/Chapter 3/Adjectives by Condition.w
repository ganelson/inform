[Phrases::Condition::] Adjectives by Condition.

Defining an adjective with an I7 condition.

@ This is a family of adjective meanings.

=
adjective_meaning_family *condition_amf = NULL; /* defined by a condition in I7 source text */

void Phrases::Condition::start(void) {
	condition_amf = AdjectiveMeanings::new_family(7);
	METHOD_ADD(condition_amf, GENERATE_IN_SUPPORT_FUNCTION_ADJM_MTID,
		Phrases::Condition::generate_in_support_function);
	METHOD_ADD(condition_amf, CLAIM_DEFINITION_SENTENCE_ADJM_MTID,
		Phrases::Condition::claim_definition);
}

@ =
int Phrases::Condition::claim_definition(adjective_meaning_family *f,
	adjective_meaning **result, parse_node *q,
	int sense, wording AW, wording DNW, wording CONW, wording CALLW) {
	if (sense == 0) return FALSE;
	definition *def = Phrases::Adjectives::def_new(q);
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

int Phrases::Condition::generate_in_support_function(adjective_meaning_family *family,
	adjective_meaning *am, int T, int emit_flag, ph_stack_frame *phsf) {
	definition *def = RETRIEVE_POINTER_definition(am->family_specific_data);
	switch (T) {
		case TEST_ATOM_TASK:
			if (emit_flag) {
				LocalVariables::alias_pronoun(phsf, def->domain_calling);

				if (Wordings::nonempty(def->condition_to_match)) {
					current_sentence = def->node;
					parse_node *spec = NULL;
					if (<s-condition>(def->condition_to_match)) spec = <<rp>>;
					if ((spec == NULL) ||
						(Dash::validate_conditional_clause(spec) == FALSE)) {
						LOG("Error on: %W = $T", def->condition_to_match, spec);
						StandardProblems::definition_problem(Task::syntax_tree(),
							_p_(PM_DefinitionBadCondition),
							def->node,
							"that condition makes no sense to me",
							"although the preamble to the definition was properly "
							"written. There must be something wrong after 'if'.");
					} else {
						if (def->format == -1) {
							Produce::inv_primitive(Emit::tree(), NOT_BIP);
							Produce::down(Emit::tree());
						}
						Specifications::Compiler::emit_as_val(K_number, spec);
						if (def->format == -1) {
							Produce::up(Emit::tree());
						}
					}
				}

				LocalVariables::alias_pronoun(phsf, EMPTY_WORDING);
			}
			return TRUE;
	}
	return FALSE;
}
