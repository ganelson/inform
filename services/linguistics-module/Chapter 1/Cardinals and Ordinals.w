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
don't actually parse against them, although they would give the correct response
if we did. Instead they're scanned for words which are marked with the appropriate
numbers.

=
void Cardinals::preform_optimiser(void) {
	NTI::every_word_in_match_must_have_my_NTI_bit(<cardinal-number>);
	NTI::every_word_in_match_must_have_my_NTI_bit(<ordinal-number>);
	for (int wn = 0; wn < lexer_wordcount; wn++) {
		if (Vocabulary::test_flags(wn, NUMBER_MC))
			Cardinals::mark_as_cardinal(Lexer::word(wn));
		if (Vocabulary::test_flags(wn, ORDINAL_MC))
			Cardinals::mark_as_ordinal(Lexer::word(wn));
	}
}

void Cardinals::mark_as_cardinal(vocabulary_entry *ve) {
	NTI::mark_vocabulary(ve, <cardinal-number>);
}

void Cardinals::mark_as_ordinal(vocabulary_entry *ve) {
	NTI::mark_vocabulary(ve, <ordinal-number>);
}

void Cardinals::enable_in_word_form(void) {
	NTI::give_nt_reserved_incidence_bit(<cardinal-number>, CARDINAL_RES_NT_BIT);
	NTI::give_nt_reserved_incidence_bit(<ordinal-number>, ORDINAL_RES_NT_BIT);

	Nonterminals::make_numbering(<cardinal-number-in-words>);
	Nonterminals::flag_words_with(<cardinal-number-in-words>, NUMBER_MC);

	Nonterminals::make_numbering(<ordinal-number-in-words>);
	Nonterminals::flag_words_with(<ordinal-number-in-words>, ORDINAL_MC);
}

@ Actual parsing is done here. We look at a single word to see if it's a
number literal: either one of the named cases above, or a number written out
in decimal digits, perhaps with a minus sign.

=
<cardinal-number> internal 1 {
	if (Vocabulary::test_flags(Wordings::first_wn(W), NUMBER_MC)) {
		int N = Vocabulary::get_literal_number_value(Lexer::word(Wordings::first_wn(W)));
		@<In Inform 7 only, check that the number is representable in the VM@>;
		==> { N, - };
		return TRUE;
	}
	==> { fail nonterminal };
}

<ordinal-number> internal 1 {
	if (Vocabulary::test_flags(Wordings::first_wn(W), ORDINAL_MC)) {
		int N = Vocabulary::get_literal_number_value(Lexer::word(Wordings::first_wn(W)));
		@<In Inform 7 only, check that the number is representable in the VM@>;
		==> { N, - };
		return TRUE;
	}
	==> { fail nonterminal };
}

@ These mustn't match any number too large to fit into the virtual machine
being compiled to, so "42000", for instance, is not a valid literal if Inform
is parsing text in a work intended for a 16-bit VM.

Why do we catch this here? The answer is probably that it's an excess of
caution, but this is a rare case where the choice of virtual machine affects
the legal syntax for Inform source text -- text originally written for use on
Glulx, which allows for larger integers, might be moved over to a Z-machine
project, with the user not realising the consequences.

@<In Inform 7 only, check that the number is representable in the VM@> =
	#ifdef CORE_MODULE
	if (Task::veto_number(N)) {
		/* to prevent repetitions: */
		Vocabulary::set_literal_number_value(Lexer::word(Wordings::first_wn(W)), 1);
		==> { fail nonterminal };
	}
	#endif

@ A small variation which lifts this restriction on the number range:

=
<cardinal-number-unlimited> internal 1 {
	if (Vocabulary::test_flags(Wordings::first_wn(W), NUMBER_MC)) {
		int N = Vocabulary::get_literal_number_value(Lexer::word(Wordings::first_wn(W)));
		==> { N, - };
		return TRUE;
	}
	==> { fail nonterminal };
}
