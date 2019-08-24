[Phrases::Condition::] Adjectives by Condition.

Defining an adjective with an I7 condition.

@ =
adjective_meaning *Phrases::Condition::ADJ_parse(parse_node *q,
	int sense, wording AW, wording DNW, wording CONW, wording CALLW) {
	if (sense == 0) return NULL;
	definition *def = Phrases::Adjectives::def_new(q);
	adjective_meaning *am =
		Adjectives::Meanings::new(CONDITION_KADJ, STORE_POINTER_definition(def),
			ParseTree::get_text(q));
	def->condition_to_match = CONW;
	def->format = sense;
	def->domain_calling = CALLW;
	def->am_of_def = am;
	Adjectives::Meanings::declare(am, AW, 6);
	Adjectives::Meanings::pass_task_to_support_routine(am, TEST_ADJECTIVE_TASK);
	Adjectives::Meanings::set_domain_text(am, DNW);
	return am;
}

void Phrases::Condition::ADJ_compiling_soon(adjective_meaning *am,
	definition *def, int T) {
}

int Phrases::Condition::ADJ_compile(definition *def, int T,
	int emit_flag, ph_stack_frame *phsf) {
	switch (T) {
		case TEST_ADJECTIVE_TASK:
			if (emit_flag) {
				LocalVariables::alias_pronoun(phsf, def->domain_calling);

				if (Wordings::nonempty(def->condition_to_match)) {
					current_sentence = def->node;
					parse_node *spec = NULL;
					if (<s-condition>(def->condition_to_match))
						spec = <<rp>>;
					if ((spec == NULL) ||
						(Dash::validate_conditional_clause(spec) == FALSE)) {
						LOG("Error on: %W = $T", def->condition_to_match, spec);
						Problems::Issue::definition_problem(_p_(PM_DefinitionBadCondition),
							def->node,
							"that condition makes no sense to me",
							"although the preamble to the definition was properly "
							"written. There must be something wrong after 'if'.");
					} else {
						if (def->format == -1) { Produce::inv_primitive(Produce::opcode(NOT_BIP)); Produce::down(); }
						Specifications::Compiler::emit_as_val(K_number, spec);
						if (def->format == -1) Produce::up();
					}
				}

				LocalVariables::alias_pronoun(phsf, EMPTY_WORDING);
			}
			return TRUE;
		case NOW_ADJECTIVE_TRUE_TASK:
			return FALSE;
		case NOW_ADJECTIVE_FALSE_TASK:
			return FALSE;
	}
	return FALSE;
}

int Phrases::Condition::ADJ_assert(definition *def,
	inference_subject *infs_to_assert_on, parse_node *val_to_assert_on, int parity) {
	return FALSE;
}

int Phrases::Condition::ADJ_index(OUTPUT_STREAM, definition *def) {
	return FALSE;
}
