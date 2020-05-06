[Phrases::RawPhrasal::] Adjectives by Raw Phrase.

Defining an adjective with an I6 routine.

@ I6-defined routine adjectives.
This little grammar catches definitions delegated to Inform 6 routines.

=
<inform6-routine-adjective-definition> ::=
	i6 routine {<quoted-text-without-subs>} says so ( ... ) |    ==> FALSE
	i6 routine {<quoted-text-without-subs>} makes it so ( ... )	==> TRUE

@ So here's a set of adjectives...

=
adjective_meaning *Phrases::RawPhrasal::ADJ_parse(parse_node *q,
	int sense, wording AW, wording DNW, wording CONW, wording CALLW) {
	int setting = FALSE;
	wording EW = EMPTY_WORDING, RW = EMPTY_WORDING;
	if (<inform6-routine-adjective-definition>(CONW)) {
		setting = <<r>>;
		RW = GET_RW(<inform6-routine-adjective-definition>, 1);
		EW = GET_RW(<inform6-routine-adjective-definition>, 2);
	} else return NULL;

	if (sense != 1) return NULL;
	if (Wordings::nonempty(CALLW)) return NULL;

	int rname_wn = Wordings::first_wn(RW);
	Word::dequote(rname_wn);

	definition *def = Phrases::Adjectives::def_new(q);
	adjective_meaning *am =
		Adjectives::Meanings::new(I6_ROUTINE_KADJ, STORE_POINTER_definition(def), EW);
	def->am_of_def = am;
	Adjectives::Meanings::declare(am, AW, 9);
	Adjectives::Meanings::set_domain_text(am, DNW);
	if (setting) {
		i6_schema *sch = Adjectives::Meanings::set_i6_schema(am, TEST_ADJECTIVE_TASK, TRUE);
		Calculus::Schemas::modify(sch, "*=-(%N(*1, -1))", rname_wn);
		sch = Adjectives::Meanings::set_i6_schema(am, NOW_ADJECTIVE_TRUE_TASK, TRUE);
		Calculus::Schemas::modify(sch, "*=-(%N(*1, true))", rname_wn);
		sch = Adjectives::Meanings::set_i6_schema(am, NOW_ADJECTIVE_FALSE_TASK, TRUE);
		Calculus::Schemas::modify(sch, "*=-(%N(*1, false))", rname_wn);
	} else {
		Adjectives::Meanings::pass_task_to_support_routine(am, TEST_ADJECTIVE_TASK);
		i6_schema *sch = Adjectives::Meanings::set_i6_schema(am, TEST_ADJECTIVE_TASK, TRUE);
		Calculus::Schemas::modify(sch, "*=-(%N(*1))", rname_wn);
	}
	return am;
}

void Phrases::RawPhrasal::ADJ_compiling_soon(adjective_meaning *am, definition *def, int T) {
}

int Phrases::RawPhrasal::ADJ_compile(definition *def, int T, int emit_flag, ph_stack_frame *phsf) {
	return FALSE;
}

int Phrases::RawPhrasal::ADJ_assert(definition *def,
	inference_subject *infs_to_assert_on, parse_node *val_to_assert_on, int parity) {
	return FALSE;
}

int Phrases::RawPhrasal::ADJ_index(OUTPUT_STREAM, definition *def) {
	return FALSE;
}
