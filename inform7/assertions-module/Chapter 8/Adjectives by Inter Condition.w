[AdjectivesByInterCondition::] Adjectives by Inter Condition.

Defining an adjective with an Inter condition.

@ A simple adjective meaning family where a named function defined from an
Inter kit can perform the test, with the following syntax.

This is an old Inform feature which may now be somewhat redundant: it's better
to use //Adjectives by Inter Function//. The distinction is that here the
function is expected to return |true| or |false| and takes no arguments.

=
<inform6-condition-adjective-definition> ::=
	i6/inter condition <quoted-text-without-subs> says so ( ... ) ==> { pass 1 }

@ Which leads us to a simple set of adjectives:

=
adjective_meaning_family *inter_condition_amf = NULL; /* defined by an explicit Inter function */

void AdjectivesByInterCondition::start(void) {
	inter_condition_amf = AdjectiveMeanings::new_family(4);
	METHOD_ADD(inter_condition_amf, CLAIM_DEFINITION_SENTENCE_ADJM_MTID,
		AdjectivesByInterCondition::claim_definition);
}

int AdjectivesByInterCondition::claim_definition(adjective_meaning_family *f,
	adjective_meaning **result, parse_node *q,
	int sense, wording AW, wording DNW, wording CONW, wording CALLW) {
	if (sense != 1) return FALSE;
	if (Wordings::nonempty(CALLW)) return FALSE;
	if (!(<inform6-condition-adjective-definition>(CONW))) return FALSE;
	int text_wn = <<r>>;
	wording IN = GET_RW(<inform6-condition-adjective-definition>, 1);

	definition *def = AdjectivalDefinitionFamily::new_definition(q);
	adjective_meaning *am =
		AdjectiveMeanings::new(inter_condition_amf,
			STORE_POINTER_definition(def), IN);
	def->am_of_def = am;
	adjective *adj = Adjectives::declare(AW, NULL);
	AdjectiveAmbiguity::add_meaning_to_adjective(am, adj);
	AdjectiveMeaningDomains::set_from_text(am, DNW);
	RTAdjectives::set_schemas_for_raw_Inter_condition(am, text_wn);
	*result = am;
	return TRUE;
}
