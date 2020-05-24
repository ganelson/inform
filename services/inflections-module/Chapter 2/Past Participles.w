[PastParticiples::] Past Participles.

To inflect present into past participles.

@h Constructing past participles.
For example, "turning away" to "turned away".

=
wording PastParticiples::pasturise_wording(wording W) {
	TEMPORARY_TEXT(pasturised);
	TEMPORARY_TEXT(from);
	feed_t id = Feeds::begin();
	LOOP_THROUGH_WORDING(i, W) {
		WRITE_TO(from, "%W", Wordings::one_word(i));
		if (Str::get_first_char(from) == '\"') WRITE_TO(pasturised, "some-long-text");
		else {
			if (PastParticiples::pasturise_text(pasturised, from)) {
				if (i > Wordings::first_wn(W)) Feeds::feed_wording(Wordings::up_to(W, i-1));
				Feeds::feed_text(pasturised);
				if (i < Wordings::last_wn(W)) Feeds::feed_wording(Wordings::from(W, i+1));
				break;
			}
		}
	}
	wording PLW = Feeds::end(id);
	LOGIF(CONSTRUCTED_PAST_PARTICIPLES, "[Past participle of %W is %W]\n", W, PLW);
	DISCARD_TEXT(from);
	DISCARD_TEXT(pasturised);
	return PLW;
}

@h The pasturising trie.
This is the process of turning a present participle, like "turning", to
a past participle, like "turned". Note that it returns |NULL| if it fails
to recognise the word in question as a present participle; this is needed
above. It expects only a single word.

=
int PastParticiples::pasturise_text(OUTPUT_STREAM, text_stream *from) {
	match_avinue *past_trie =
		PreformUtilities::define_trie(<pasturise-participle>, TRIE_START,
			DefaultLanguage::get(NULL));
	return Inflect::suffix(OUT, past_trie, from);
}
