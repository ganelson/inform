[Feeds::] Feeds.

Feeds are conduits for arbitrary text to flow into the lexer, and to
be converted into wordings.

@h Feed sessions.
Each feed has a unique ID. At present only one is ever open at a time, but
we don't want to assume that.

@d feed_t int /* (not a typedef only because it makes trouble for inweb) */

@ There are two ways to make a feed. One is simply to call one of the |feed_text|
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
Some variations on a theme:

=
wording Feeds::feed_C_string(inchar32_t *text) {
	return Feeds::feed_C_string_full(text, FALSE, NULL, FALSE);
}

wording Feeds::feed_text(text_stream *text) {
	return Feeds::feed_text_full(text, FALSE, NULL);
}

wording Feeds::feed_C_string_expanding_strings(inchar32_t *text) {
	return Feeds::feed_C_string_full(text, TRUE, NULL, FALSE);
}

wording Feeds::feed_text_expanding_strings(text_stream *text) {
	return Feeds::feed_text_full(text, TRUE, NULL);
}

wording Feeds::feed_text_punctuated(text_stream *text, inchar32_t *pmarks) {
	wording W = Feeds::feed_text_full(text, FALSE, pmarks);
	return W;
}

@ ...all of which result in calls to these two, which are really the same
function, written two ways:

=
wording Feeds::feed_C_string_full(inchar32_t *text, int expand, inchar32_t *nonstandard,
	int break_at_slashes) {
	@<Set up the lexer@>;
	lexer_break_at_slashes = break_at_slashes;
	for (int i=0; text[i] != 0; i++) {
		int last_cr, cr, next_cr;
		if (i > 0) last_cr = (int) text[i-1]; else last_cr = EOF;
		cr = (int) text[i];
		if (cr != 0) next_cr = (int) text[i+1]; else next_cr = EOF;
		Lexer::feed_triplet(last_cr, cr, next_cr);
	}
	@<Extract results from the lexer@>;
}

wording Feeds::feed_text_full(text_stream *text, int expand, inchar32_t *nonstandard) {
	@<Set up the lexer@>;
	for (int i=0, L=Str::len(text); i<L; i++) {
		int last_cr, cr, next_cr;
		if (i > 0) last_cr = (int) Str::get_at(text, i-1); else last_cr = EOF;
		cr = (int) Str::get_at(text, i);
		if (cr != 0) next_cr = (int) Str::get_at(text, i+1); else next_cr = EOF;
		Lexer::feed_triplet(last_cr, cr, next_cr);
	}
	@<Extract results from the lexer@>;
}

@<Set up the lexer@> =
	Lexer::feed_begins(Lexer::as_if_from_nowhere());
	lexer_divide_strings_at_text_substitutions = expand;
	lexer_allow_I6_escapes = TRUE;
	if (nonstandard) {
		lexer_punctuation_marks = nonstandard;
		lexer_allow_I6_escapes = FALSE;
	} else
		lexer_punctuation_marks = STANDARD_PUNCTUATION_MARKS;

@<Extract results from the lexer@> =
    wording LEXW = Lexer::feed_ends(FALSE, NULL);
	Vocabulary::identify_word_range(LEXW);
	return LEXW;

@ If we want to feed a wording, we could do that by printing it out to a text
stream, then feeding this text; but that would be slow and rather circular, and
would also lose the origin. Much quicker is to splice, and then there's no
need for a feed at all:

=
wording Feeds::feed_wording(wording W) {
	return Lexer::splice_words(W);
}
