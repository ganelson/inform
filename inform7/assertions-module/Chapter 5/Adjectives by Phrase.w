[Phrases::Phrasal::] Adjectives by Phrase.

Adjectives defined by an I7 phrase.

@ Phrase adjectives.
And here's another one.

=
adjective_meaning_family *phrase_amf = NULL; /* defined by an explicit but nameless rule */

void Phrases::Phrasal::start(void) {
	phrase_amf = AdjectiveMeanings::new_family(6);
	METHOD_ADD(phrase_amf, CLAIM_DEFINITION_SENTENCE_ADJM_MTID, Phrases::Phrasal::claim_definition);
}

int Phrases::Phrasal::is_defined_by_phrase(adjective_meaning *am) {
	if ((am) && (am->family == phrase_amf)) return TRUE;
	return FALSE;
}

void Phrases::Phrasal::define_adjective_by_phrase(parse_node *p, id_body *idb, wording *CW,
	kind **K) {
	definition *def;
	*CW = EMPTY_WORDING; *K = K_object;
	if (idb == NULL) return;

	if (Node::is(p->next, DEFN_CONT_NT)) p = p->next;

	LOOP_OVER(def, definition)
		if ((def->node == p) && (Phrases::Phrasal::is_defined_by_phrase(def->am_of_def))) {
			RTAdjectives::set_schemas_for_I7_phrase(def->am_of_def, idb);
			*CW = def->domain_calling;
			AdjectiveMeaningDomains::determine_if_possible(def->am_of_def);
			*K = AdjectiveMeaningDomains::get_kind(def->am_of_def);
			if ((*K == NULL) || (Kinds::Behaviour::is_object(*K))) *K = K_object;
			return;
		}
}

int Phrases::Phrasal::claim_definition(adjective_meaning_family *f,
	adjective_meaning **result, parse_node *q,
	int sense, wording AW, wording DNW, wording CONW, wording CALLW) {
	if (sense != 0) return FALSE;
	definition *def = AdjectivalDefinitionFamily::new_definition(q);
	adjective_meaning *am = AdjectiveMeanings::new(phrase_amf,
		STORE_POINTER_definition(def), Node::get_text(q));
	def->domain_calling = CALLW;
	def->am_of_def = am;
	adjective *adj = Adjectives::declare(AW, NULL);
	AdjectiveAmbiguity::add_meaning_to_adjective(am, adj);
	AdjectiveMeanings::perform_task_via_function(am, TEST_ATOM_TASK);
	AdjectiveMeaningDomains::set_from_text(am, DNW);
	*result = am;
	return TRUE;
}
