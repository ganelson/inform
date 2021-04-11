[AdjectivesByInterFunction::] Adjectives by Inter Function.

Defining an adjective with an Inter function to test or make it true.

@ A simple adjective meaning family where a named function defined from an
Inter kit can perform the test, or a "now". These are used when the definition
matches the following:

=
<inform6-routine-adjective-definition> ::=
	i6/inter routine/function {<quoted-text-without-subs>} says so ( ... ) |   ==> { FALSE, - }
	i6/inter routine/function {<quoted-text-without-subs>} makes it so ( ... ) ==> { TRUE, - }

@ Implemented as follows:

=
adjective_meaning_family *inter_routine_amf = NULL; /* defined by a named I6 routine */

void AdjectivesByInterFunction::start(void) {
	inter_routine_amf = AdjectiveMeanings::new_family(5);
	METHOD_ADD(inter_routine_amf, CLAIM_DEFINITION_SENTENCE_ADJM_MTID,
		AdjectivesByInterFunction::claim_definition);
}

int AdjectivesByInterFunction::is_by_Inter_function(adjective_meaning *am) {
	if ((am) && (am->family == inter_routine_amf)) return TRUE;
	return FALSE;
}

int AdjectivesByInterFunction::claim_definition(adjective_meaning_family *f,
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
