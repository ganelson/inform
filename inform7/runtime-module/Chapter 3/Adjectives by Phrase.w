[Phrases::Phrasal::] Adjectives by Phrase.

Adjectives defined by an I7 phrase.

@ Phrase adjectives.
And here's another one.

=
void Phrases::Phrasal::define_adjective_by_phrase(parse_node *p, phrase *ph, wording *CW,
	kind **K) {
	definition *def;
	*CW = EMPTY_WORDING; *K = K_object;
	if (ph == NULL) return;

	LOOP_OVER(def, definition)
		if ((def->definition_node == p) && (Adjectives::Meanings::get_form(def->am_of_def) == PHRASE_KADJ)) {
			i6_schema *sch = Adjectives::Meanings::set_i6_schema(def->am_of_def, TEST_ADJECTIVE_TASK, FALSE);
			Calculus::Schemas::modify(sch, "(%n(*1))", Phrases::iname(ph));
			*CW = def->domain_calling;
			*K = Adjectives::Meanings::get_domain_forcing(def->am_of_def);
			if ((*K == NULL) || (Kinds::Behaviour::is_object(*K)))
				*K = K_object;
			return;
		}
}

adjective_meaning *Phrases::Phrasal::ADJ_parse(parse_node *q,
	int sense, wording AW, wording DNW, wording CONW, wording CALLW) {
	if (sense != 0) return NULL;
	definition *def = Phrases::Adjectives::def_new(q);
	adjective_meaning *am = Adjectives::Meanings::new(PHRASE_KADJ,
		STORE_POINTER_definition(def), Node::get_text(q));
	def->domain_calling = CALLW;
	def->am_of_def = am;
	Adjectives::Meanings::declare(am, AW, 7);
	Adjectives::Meanings::pass_task_to_support_routine(am, TEST_ADJECTIVE_TASK);
	Adjectives::Meanings::set_domain_text(am, DNW);
	return am;
}

void Phrases::Phrasal::ADJ_compiling_soon(adjective_meaning *am, definition *def, int T) {
}

int Phrases::Phrasal::ADJ_compile(definition *def, int T, int emit_flag, ph_stack_frame *phsf) {
	return FALSE;
}

int Phrases::Phrasal::ADJ_assert(definition *def,
	inference_subject *infs_to_assert_on, parse_node *val_to_assert_on, int parity) {
	return FALSE;
}

int Phrases::Phrasal::ADJ_index(OUTPUT_STREAM, definition *def) {
	return FALSE;
}
