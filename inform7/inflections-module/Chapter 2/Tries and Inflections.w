[Inflections::] Tries and Inflections.

Using tries to inflect word endings.

@h Suffix inflections.
The following inflects the ending of the supplied text. It does so by
running the text through an avinue (a sequence of tries), whose result
is an instruction on how to modify that text: for example, the result
|"3ize"| tells us to strike out the last 3 characters and add "ize".
The special character |+| means "duplicate the last character" and
is useful for inflections which double consonants, such as "big" to
"bigger", which can be done with the instruction |"0+er"|.

If there's no initial digit, the result replaces the original entirely;
if the result is null, i.e., if the avinue finds nothing, the result is
the same as the original.

=
int Inflections::suffix_inflection(OUTPUT_STREAM, match_avinue *T, text_stream *from) {
	wchar_t *result = Tries::search_avinue(T, from);
	return Inflections::follow_suffix_instruction(OUT, from, result);
}

int Inflections::follow_suffix_instruction(OUTPUT_STREAM, text_stream *from, wchar_t *instruction) {
	int success = TRUE;
	if (instruction == NULL) { success = FALSE; instruction = L"0"; }
	int back = instruction[0] - '0';
	TEMPORARY_TEXT(outcome);
	if ((back < 0) || (back > 9)) {
		WRITE_TO(outcome, "%w", instruction);
	} else {
		for (int i = 0, len = Str::len(from); i<len-back; i++) PUT_TO(outcome, Str::get_at(from, i));
		int j = 1;
		if (instruction[j] == '+') { int last = Str::get_last_char(outcome); PUT_TO(outcome, last); j++; }
		for (; instruction[j]; j++) PUT_TO(outcome, instruction[j]);
	}

	LOOP_THROUGH_TEXT(pos, outcome)
		if (Str::get(pos) == '+') PUT(' ');
		else PUT(Str::get(pos));
	DISCARD_TEXT(outcome);
	return success;
}

@h General tries.
Here we take a word assemblage and apply suffix inflection to the first word
alone, preserving the rest. However, if the result of this inflection contains
any |+| signs, those become word boundaries. This allows for inflections which
do more than simply fiddle with the final letters.

=
word_assemblage Inflections::apply_trie_to_wa(word_assemblage wa, match_avinue *T) {
	vocabulary_entry **words;
	int no_words;
	WordAssemblages::as_array(&wa, &words, &no_words);
	if (no_words == 0) return wa;

	TEMPORARY_TEXT(unsuffixed);
	TEMPORARY_TEXT(suffixed);
	WRITE_TO(unsuffixed, "%V", words[0]);
	int s = Inflections::suffix_inflection(suffixed, T, unsuffixed);
	if (s == FALSE) {
		LOOP_THROUGH_TEXT(pos, unsuffixed)
			if (Str::get(pos) == '+') PUT_TO(suffixed, ' ');
			else PUT_TO(suffixed, Str::get(pos));
	}
	wording W = Feeds::feed_stream(suffixed);
	WordAssemblages::truncate(&wa, 1);
	DISCARD_TEXT(suffixed);
	DISCARD_TEXT(unsuffixed);
	return WordAssemblages::join(WordAssemblages::from_wording(W), wa);
}
