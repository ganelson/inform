[Phrases::RawCondition::] Adjectives by Raw Condition.

Defining an adjective with an I6 condition.

@ This grammar catches definitions delegated to Inform 6 conditions.

=
<inform6-condition-adjective-definition> ::=
	i6 condition <quoted-text-without-subs> says so ( ... )		==> R[1]

@ Which leads us to a simple set of adjectives:

=
adjective_meaning *Phrases::RawCondition::ADJ_parse(parse_node *q,
	int sense, wording AW, wording DNW, wording CONW, wording CALLW) {
	if (sense != 1) return NULL;
	if (Wordings::nonempty(CALLW)) return NULL;
	if (!(<inform6-condition-adjective-definition>(CONW))) return NULL;
	int text_wn = <<r>>;
	wording IN = GET_RW(<inform6-condition-adjective-definition>, 1);

	definition *def = Phrases::Adjectives::def_new(q);
	adjective_meaning *am =
		Adjectives::Meanings::new(I6_CONDITION_KADJ,
			STORE_POINTER_definition(def), IN);
	def->am_of_def = am;
	Adjectives::Meanings::declare(am, AW, 8);
	Adjectives::Meanings::pass_task_to_support_routine(am, TEST_ADJECTIVE_TASK);
	Adjectives::Meanings::set_domain_text(am, DNW);
	i6_schema *sch = Adjectives::Meanings::set_i6_schema(am, TEST_ADJECTIVE_TASK, FALSE);
	Word::dequote(text_wn);
	Calculus::Schemas::modify(sch, "(%N)", text_wn);
	return am;
}

void Phrases::RawCondition::ADJ_compiling_soon(adjective_meaning *am, definition *def, int T) {
}

int Phrases::RawCondition::ADJ_compile(definition *def, int T, int emit_flag, ph_stack_frame *phsf) {
	return FALSE;
}

int Phrases::RawCondition::ADJ_assert(definition *def,
	inference_subject *infs_to_assert_on, parse_node *val_to_assert_on, int parity) {
	return FALSE;
}

int Phrases::RawCondition::ADJ_index(OUTPUT_STREAM, definition *def) {
	return FALSE;
}
