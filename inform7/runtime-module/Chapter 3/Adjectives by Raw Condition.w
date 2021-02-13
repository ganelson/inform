[Phrases::RawCondition::] Adjectives by Raw Condition.

Defining an adjective with an I6 condition.

@ This grammar catches definitions delegated to Inform 6 conditions.

=
<inform6-condition-adjective-definition> ::=
	i6 condition <quoted-text-without-subs> says so ( ... )		==> { pass 1 }

@ Which leads us to a simple set of adjectives:

=
adjective_meaning_family *inter_condition_amf = NULL; /* defined by an explicit I6 schema */

void Phrases::RawCondition::start(void) {
	inter_condition_amf = AdjectiveMeanings::new_family(4);
	METHOD_ADD(inter_condition_amf, PARSE_ADJM_MTID, Phrases::RawCondition::ADJ_parse);
}

int Phrases::RawCondition::ADJ_parse(adjective_meaning_family *f,
	adjective_meaning **result, parse_node *q,
	int sense, wording AW, wording DNW, wording CONW, wording CALLW) {
	if (sense != 1) return FALSE;
	if (Wordings::nonempty(CALLW)) return FALSE;
	if (!(<inform6-condition-adjective-definition>(CONW))) return FALSE;
	int text_wn = <<r>>;
	wording IN = GET_RW(<inform6-condition-adjective-definition>, 1);

	definition *def = Phrases::Adjectives::def_new(q);
	adjective_meaning *am =
		AdjectiveMeanings::new(inter_condition_amf,
			STORE_POINTER_definition(def), IN);
	def->am_of_def = am;
	adjective *adj = Adjectives::declare(AW, NULL);
	AdjectiveAmbiguity::add_meaning_to_adjective(am, adj);
	AdjectiveMeanings::pass_task_to_support_routine(am, TEST_ADJECTIVE_TASK);
	AdjectiveMeanings::set_domain_text(am, DNW);
	i6_schema *sch = AdjectiveMeanings::set_i6_schema(am, TEST_ADJECTIVE_TASK, FALSE);
	Word::dequote(text_wn);
	Calculus::Schemas::modify(sch, "(%N)", text_wn);
	*result = am;
	return TRUE;
}
