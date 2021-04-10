[Phrases::RawPhrasal::] Adjectives by Inter Function.

Defining an adjective with an Inter function to test or make it true.

@ I6-defined routine adjectives.
This little grammar catches definitions delegated to Inform 6 routines.

=
<inform6-routine-adjective-definition> ::=
	i6 routine {<quoted-text-without-subs>} says so ( ... ) |    ==> { FALSE, - }
	i6 routine {<quoted-text-without-subs>} makes it so ( ... )  ==> { TRUE, - }

@ So here's a set of adjectives...

=
adjective_meaning_family *inter_routine_amf = NULL; /* defined by a named I6 routine */

void Phrases::RawPhrasal::start(void) {
	inter_routine_amf = AdjectiveMeanings::new_family(5);
	METHOD_ADD(inter_routine_amf, CLAIM_DEFINITION_SENTENCE_ADJM_MTID, Phrases::RawPhrasal::claim_definition);
}

int Phrases::RawPhrasal::is_by_Inter_function(adjective_meaning *am) {
	if ((am) && (am->family == inter_routine_amf)) return TRUE;
	return FALSE;
}

int Phrases::RawPhrasal::claim_definition(adjective_meaning_family *f,
	adjective_meaning **result, parse_node *q,
	int sense, wording AW, wording DNW, wording CONW, wording CALLW) {
	int setting = FALSE;
	wording EW = EMPTY_WORDING, RW = EMPTY_WORDING;
	if (<inform6-routine-adjective-definition>(CONW)) {
		setting = <<r>>;
		RW = GET_RW(<inform6-routine-adjective-definition>, 1);
		EW = GET_RW(<inform6-routine-adjective-definition>, 2);
	} else return FALSE;

	if (sense != 1) return FALSE;
	if (Wordings::nonempty(CALLW)) return FALSE;

	definition *def = AdjectivalDefinitionFamily::new_definition(q);
	adjective_meaning *am =
		AdjectiveMeanings::new(inter_routine_amf, STORE_POINTER_definition(def), EW);
	def->am_of_def = am;
	adjective *adj = Adjectives::declare(AW, NULL);
	AdjectiveAmbiguity::add_meaning_to_adjective(am, adj);
	AdjectiveMeaningDomains::set_from_text(am, DNW);
	RTAdjectives::set_schemas_for_raw_Inter_function(am, RW, setting);
	*result = am;
	return TRUE;
}
