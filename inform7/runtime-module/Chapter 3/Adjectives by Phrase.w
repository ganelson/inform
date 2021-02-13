[Phrases::Phrasal::] Adjectives by Phrase.

Adjectives defined by an I7 phrase.

@ Phrase adjectives.
And here's another one.

=
adjective_meaning_family *phrase_amf = NULL; /* defined by an explicit but nameless rule */

void Phrases::Phrasal::start(void) {
	phrase_amf = AdjectiveMeanings::new_family(6);
	METHOD_ADD(phrase_amf, PARSE_ADJM_MTID, Phrases::Phrasal::ADJ_parse);
}

void Phrases::Phrasal::define_adjective_by_phrase(parse_node *p, phrase *ph, wording *CW,
	kind **K) {
	definition *def;
	*CW = EMPTY_WORDING; *K = K_object;
	if (ph == NULL) return;

	LOOP_OVER(def, definition)
		if ((def->definition_node == p) && (AdjectiveMeanings::get_form(def->am_of_def) == phrase_amf)) {
			i6_schema *sch = AdjectiveMeanings::set_i6_schema(def->am_of_def, TEST_ADJECTIVE_TASK, FALSE);
			Calculus::Schemas::modify(sch, "(%n(*1))", Phrases::iname(ph));
			*CW = def->domain_calling;
			*K = AdjectiveMeanings::get_domain_forcing(def->am_of_def);
			if ((*K == NULL) || (Kinds::Behaviour::is_object(*K)))
				*K = K_object;
			return;
		}
}

int Phrases::Phrasal::ADJ_parse(adjective_meaning_family *f,
	adjective_meaning **result, parse_node *q,
	int sense, wording AW, wording DNW, wording CONW, wording CALLW) {
	if (sense != 0) return FALSE;
	definition *def = Phrases::Adjectives::def_new(q);
	adjective_meaning *am = AdjectiveMeanings::new(phrase_amf,
		STORE_POINTER_definition(def), Node::get_text(q));
	def->domain_calling = CALLW;
	def->am_of_def = am;
	adjective *adj = Adjectives::declare(AW, NULL);
	AdjectiveAmbiguity::add_meaning_to_adjective(am, adj);
	AdjectiveMeanings::pass_task_to_support_routine(am, TEST_ADJECTIVE_TASK);
	AdjectiveMeanings::set_domain_text(am, DNW);
	*result = am;
	return TRUE;
}
