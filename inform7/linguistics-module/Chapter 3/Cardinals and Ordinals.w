[Cardinals::] Cardinals and Ordinals.

To parse integers seen from a grammatical point of view.

@h Cardinal and ordinal numbers.
We read a few low numbers in text, but larger numbers only in digits. Textual
numbers run from 0 to 12 since that's what clocks need.

By a cardinal we mean a number such as |five| or |351|.

=
<cardinal-number-in-words> ::=
	zero |
	one |
	two |
	three |
	four |
	five |
	six |
	seven |
	eight |
	nine |
	ten |
	eleven |
	twelve

@ And by an ordinal we mean a number such as |fifth| or |351st|; note that
this is not a noun, and isn't allowed as a constant value in Inform.

=
<ordinal-number-in-words> ::=
	zeroth |
	first |
	second |
	third |
	fourth |
	fifth |
	sixth |
	seventh |
	eighth |
	ninth |
	tenth |
	eleventh |
	twelfth

@ Those two nonterminals here simply supply text: for efficiency reasons we
don't actually parse them, although they would give the correct response if
we did. Instead they're scanned for words which are marked with the appropriate
numbers.

=
void Cardinals::preform_optimiser(void) {
	Optimiser::mark_nt_as_requiring_itself_conj(<cardinal-number>);
	Optimiser::mark_nt_as_requiring_itself_conj(<ordinal-number>);
	for (int wn = 0; wn < lexer_wordcount; wn++) {
		if (Vocabulary::test_flags(wn, NUMBER_MC))
			Cardinals::mark_as_cardinal(Lexer::word(wn));
		if (Vocabulary::test_flags(wn, ORDINAL_MC))
			Cardinals::mark_as_ordinal(Lexer::word(wn));
	}
}

void Cardinals::mark_as_cardinal(vocabulary_entry *ve) {
	Optimiser::set_nt_incidence(ve, <cardinal-number>);
}

void Cardinals::mark_as_ordinal(vocabulary_entry *ve) {
	Optimiser::set_nt_incidence(ve, <ordinal-number>);
}

void Cardinals::enable_in_word_form(void) {
	Optimiser::assign_bitmap_bit(<cardinal-number>, 0);
	Optimiser::assign_bitmap_bit(<ordinal-number>, 1);

	<cardinal-number-in-words>->opt.number_words_by_production = TRUE;
	<cardinal-number-in-words>->opt.flag_words_in_production = NUMBER_MC;

	<ordinal-number-in-words>->opt.number_words_by_production = TRUE;
	<ordinal-number-in-words>->opt.flag_words_in_production = ORDINAL_MC;
}

@ Actual parsing is done here. We look at a single word to see if it's a
number literal: either one of the named cases above, or a number written out
in decimal digits, perhaps with a minus sign.

=
<cardinal-number> internal 1 {
	if (Vocabulary::test_flags(Wordings::first_wn(W), NUMBER_MC)) {
		*X = Vocabulary::get_literal_number_value(Lexer::word(Wordings::first_wn(W)));
		@<In Inform 7 only, check that the number is representable in the VM@>;
		return TRUE;
	}
	return FALSE;
}

<ordinal-number> internal 1 {
	if (Vocabulary::test_flags(Wordings::first_wn(W), ORDINAL_MC)) {
		*X = Vocabulary::get_literal_number_value(Lexer::word(Wordings::first_wn(W)));
		@<In Inform 7 only, check that the number is representable in the VM@>;
		return TRUE;
	}
	return FALSE;
}

@ These mustn't match any number too large to fit into the virtual machine
being compiled to, so "42000", for instance, is not a valid literal if Inform
is parsing text in a work intended for the 16-bit Z-machine.

Why do we catch this here? The answer is probably that it's an excess of
caution, but this is a rare case where the choice of virtual machine affects
the legal syntax for Inform source text -- text originally written for use on
Glulx, which allows for larger integers, might be moved over to a Z-machine
project, with the user not realising the consequences.

@<In Inform 7 only, check that the number is representable in the VM@> =
	#ifdef CORE_MODULE
	if (FundamentalConstants::veto_number(*X)) {
		/* to prevent repetitions: */
		Vocabulary::set_literal_number_value(Lexer::word(Wordings::first_wn(W)), 1);
		return FALSE;
	}
	#endif

@ A small variation which lifts this restriction on the number range:

=
<cardinal-number-unlimited> internal 1 {
	if (Vocabulary::test_flags(Wordings::first_wn(W), NUMBER_MC)) {
		*X = Vocabulary::get_literal_number_value(Lexer::word(Wordings::first_wn(W)));
		return TRUE;
	}
	return FALSE;
}
