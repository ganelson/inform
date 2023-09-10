[Inflect::] Tries and Inflections.

Using tries to inflect word endings.

@h Suffix inflections.
The following inflects the ending of the supplied text. It does so by
running the text through an avinue: see //foundation: Tries and Avinues//,
which is where the asterisk notation is handled.

=
int Inflect::suffix(OUTPUT_STREAM, match_avinue *T, text_stream *from) {
	inchar32_t *result = Tries::search_avinue(T, from);
	return Inflect::follow_suffix_instruction(OUT, from, result);
}

@ The //foundation// code returns a |result| which may be null, if no match
was found. In that event, we leave the text unchanged, just as if the result
had been |0| -- meaning "change nothing".

=
int Inflect::follow_suffix_instruction(OUTPUT_STREAM, text_stream *from,
	inchar32_t *instruction) {
	int success = TRUE;
	if (instruction == NULL) { success = FALSE; instruction = U"0"; }
	TEMPORARY_TEXT(outcome)
	@<Modify the original according to the instruction@>;
	@<Write the output, interpreting plus signs as word breaks@>;
	DISCARD_TEXT(outcome)
	return success;
}

@ In general the result either has an initial digit, in which case it removes
that many terminal letters, or does not, in which case it removes all the
letters (and thus the result text replaces the original entirely).
The special character |+| after a digit means "duplicate the last character";
in other contexts it means "break words here".

For example, the result |3ize| tells us to strike out the last 3 characters and
add "ize".

@<Modify the original according to the instruction@> =
	int back = (int) (instruction[0] - '0');
	if ((back < 0) || (back > 9)) {
		WRITE_TO(outcome, "%w", instruction);
	} else {
		for (int i = 0, len = Str::len(from); i<len-back; i++)
			PUT_TO(outcome, Str::get_at(from, i));
		int j = 1;
		if (instruction[j] == '+') {
			inchar32_t last = Str::get_last_char(outcome); PUT_TO(outcome, last); j++;
		}
		for (; instruction[j]; j++) PUT_TO(outcome, instruction[j]);
	}

@<Write the output, interpreting plus signs as word breaks@> =
	LOOP_THROUGH_TEXT(pos, outcome)
		if (Str::get(pos) == '+') PUT(' ');
		else PUT(Str::get(pos));

@h General tries.
Here we take a word assemblage and apply suffix inflection to the first word
alone, preserving the rest: for example, "make the tea" might become "making
the tea". However, if the result of this inflection contains any |+| signs,
those once again become word boundaries.

=
word_assemblage Inflect::first_word(word_assemblage wa, match_avinue *T) {
	vocabulary_entry **words;
	int no_words;
	WordAssemblages::as_array(&wa, &words, &no_words);
	if (no_words == 0) return wa;

	TEMPORARY_TEXT(unsuffixed)
	TEMPORARY_TEXT(suffixed)
	WRITE_TO(unsuffixed, "%V", words[0]);
	int s = Inflect::suffix(suffixed, T, unsuffixed);
	if (s == FALSE) {
		LOOP_THROUGH_TEXT(pos, unsuffixed)
			if (Str::get(pos) == '+') PUT_TO(suffixed, ' ');
			else PUT_TO(suffixed, Str::get(pos));
	}
	wording W = Feeds::feed_text(suffixed);
	WordAssemblages::truncate(&wa, 1);
	DISCARD_TEXT(suffixed)
	DISCARD_TEXT(unsuffixed)
	return WordAssemblages::join(WordAssemblages::from_wording(W), wa);
}
