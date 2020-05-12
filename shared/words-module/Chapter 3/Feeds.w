[Feeds::] Feeds.

Feeds are conduits for arbitrary text to flow into the lexer, and to
be converted into wordings.

@h Definitions.

@ I feel a certain embarrassment about the frequency with which the following
code is needed throughout Inform, to create fresh source text from old. Is
this a shameless hack, sacrificing memory for the sake of a small data
structure to represent wordings? Or is it a deep insight into the
interdependency of lexical analysis and semantic understanding? The reader
must decide.

Each feed has a unique ID. At present only one is ever open at a time, but
we don't want to assume that.

@d feed_t int /* (not a typedef only because it makes trouble for inweb) */

@h Feed sessions.
There are two ways to make a feed. One is simply to call one of the |feed_text|
routines below and use its output. The other is for a multi-stage process,
that is, for when multiple pieces of text need to go into the same feed:
to start such, call |Feeds::begin| and get an ID; to end, call |Feeds::end|
with the corresponding ID back again.

=
feed_t Feeds::begin(void) {
	return (feed_t) lexer_wordcount;
}
wording Feeds::end(feed_t id) {
	return Wordings::new((int) id, lexer_wordcount-1);
}

@h Feeding a feed.
Within a feed session, we can pass two sorts of text into the lexer: first,
raw strings.

=
wording Feeds::feed_C_string(wchar_t *text) {
	return Feeds::feed_C_string_full(text, FALSE, NULL);
}

wording Feeds::feed_text(text_stream *text) {
	return Feeds::feed_text_full(text, FALSE, NULL);
}

wording Feeds::feed_C_string_expanding_strings(wchar_t *text) {
	return Feeds::feed_C_string_full(text, TRUE, NULL);
}

wording Feeds::feed_text_expanding_strings(text_stream *text) {
	return Feeds::feed_text_full(text, TRUE, NULL);
}

wording Feeds::feed_text_punctuated(text_stream *text, wchar_t *pmarks) {
	wording W = Feeds::feed_text_full(text, FALSE, pmarks);
	return W;
}

@ When done, we call |Vocabulary::identify_word_range|, because we are probably
running long after the initial vocabulary identification phase of Inform.

=
wording Feeds::feed_C_string_full(wchar_t *text, int expand_strings, wchar_t *nonstandard) {
	source_location as_if_from_nowhere;
	as_if_from_nowhere.file_of_origin = NULL;
	as_if_from_nowhere.line_number = 1;

	Lexer::feed_begins(as_if_from_nowhere);

	lexer_divide_strings_at_text_substitutions = expand_strings;
	lexer_allow_I6_escapes = TRUE;
	if (nonstandard) {
		lexer_punctuation_marks = nonstandard;
		lexer_allow_I6_escapes = FALSE;
	} else
		lexer_punctuation_marks = STANDARD_PUNCTUATION_MARKS;

	for (int i=0; text[i] != 0; i++) {
		int last_cr, cr, next_cr;
		if (i > 0) last_cr = text[i-1]; else last_cr = EOF;
		cr = text[i];
		if (cr != 0) next_cr = text[i+1]; else next_cr = EOF;
		Lexer::feed_triplet(last_cr, cr, next_cr);
	}

    wording LEXW = Lexer::feed_ends(FALSE, NULL);
	Vocabulary::identify_word_range(LEXW);
	return LEXW;
}

wording Feeds::feed_text_full(text_stream *text, int expand_strings, wchar_t *nonstandard) {
	source_location as_if_from_nowhere;
	as_if_from_nowhere.file_of_origin = NULL;
	as_if_from_nowhere.line_number = 1;

	Lexer::feed_begins(as_if_from_nowhere);

	lexer_divide_strings_at_text_substitutions = expand_strings;
	lexer_allow_I6_escapes = TRUE;
	if (nonstandard) {
		lexer_punctuation_marks = nonstandard;
		lexer_allow_I6_escapes = FALSE;
	} else
		lexer_punctuation_marks = STANDARD_PUNCTUATION_MARKS;

	for (int i=0, L=Str::len(text); i<L; i++) {
		int last_cr, cr, next_cr;
		if (i > 0) last_cr = Str::get_at(text, i-1); else last_cr = EOF;
		cr = Str::get_at(text, i);
		if (cr != 0) next_cr = Str::get_at(text, i+1); else next_cr = EOF;
		Lexer::feed_triplet(last_cr, cr, next_cr);
	}

    wording LEXW = Lexer::feed_ends(FALSE, NULL);
	Vocabulary::identify_word_range(LEXW);
	return LEXW;
}

@ The only other possible action is to splice:

=
wording Feeds::feed_wording(wording W) {
	return Lexer::splice_words(W);
}
