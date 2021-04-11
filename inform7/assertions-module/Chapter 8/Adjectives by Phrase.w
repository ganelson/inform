[AdjectivesByPhrase::] Adjectives by Phrase.

Adjectives defined by an I7 phrase written out longhand.

@ These are adjectives where a phrase written out explicitly will determine
the answer, like so:
= (text as Inform 7)
Definition: A container is possessed by the Devil:
	if its carrying capacity is 666, decide yes;
	decide no.
=
Adjectival families are mostly chosen by being claimed because of some special
wording, but an adjective falls into this family when //AdjectivalDefinitionFamily::given_body//
sees the body of the definition phrase and calls //AdjectivesByPhrase::define_adjective_by_phrase//
to force the issue.

=
adjective_meaning_family *phrase_amf = NULL; /* defined by an explicit but nameless phrase */

void AdjectivesByPhrase::start(void) {
	phrase_amf = AdjectiveMeanings::new_family(6);
	METHOD_ADD(phrase_amf, CLAIM_DEFINITION_SENTENCE_ADJM_MTID, AdjectivesByPhrase::claim_definition);
}

int AdjectivesByPhrase::is_defined_by_phrase(adjective_meaning *am) {
	if ((am) && (am->family == phrase_amf)) return TRUE;
	return FALSE;
}

void AdjectivesByPhrase::define_adjective_by_phrase(parse_node *p, id_body *idb,
	wording *CW, kind **K) {
	definition *def;
	*CW = EMPTY_WORDING; *K = K_object;
	if (idb == NULL) return;
	if (Node::is(p->next, DEFN_CONT_NT)) p = p->next;
	LOOP_OVER(def, definition)
		if ((def->node == p) &&
			(AdjectivesByPhrase::is_defined_by_phrase(def->am_of_def))) {
			RTAdjectives::set_schemas_for_I7_phrase(def->am_of_def, idb);
			*CW = def->domain_calling;
			AdjectiveMeaningDomains::determine_if_possible(def->am_of_def);
			*K = AdjectiveMeaningDomains::get_kind(def->am_of_def);
			if ((*K == NULL) || (Kinds::Behaviour::is_object(*K))) *K = K_object;
			return;
		}
}

int AdjectivesByPhrase::claim_definition(adjective_meaning_family *f,
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
