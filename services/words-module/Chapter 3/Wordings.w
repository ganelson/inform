[Wordings::] Wordings.

To manage contiguous word ranges.

@h Definitions.

@ Wordings are an efficient representation of a multi-word name for
something, using the fact that almost all names derive from contiguous
runs of words in the source text.

Recall that words are numbered from 0 upwards in order of reading into
the lexer. The wording |Wordings::new(A, B)| represents both a positional
marker, at word number |A|, and also some textual content, the text making
up words |A| to |B| inclusive. Different wordings can represent the
same text at different positions in the source text, for example if
"brown spotted owl" occurs multiple times.

=
typedef struct wording {
	int word_A, word_B;
} wording;

@ Note that this applies even to the empty text. A wording holds no text
if both |A| and |B| are negative, or if |A| is larger than |B|. Thus
the wording |(17, 16)| represents the empty text at position 17. (Preform
makes use of this when parsing nonterminals which match conditionally
but consume no text, for example.) When we are representing no text and
no position either, we should use the following constant wording:

@d EMPTY_WORDING ((wording) { -1, -1 })

@ Annoyingly, |gcc| (though not |clang|) rejects this as an initializer, so
we also need:

@d EMPTY_WORDING_INIT { -1, -1 }

@ We will frequently want to loop through the words in a wording, so
the following macro is convenient. Note that the loop body is not executed
if the wording is empty.

@d LOOP_THROUGH_WORDING(i, W)
	if (W.word_A >= 0)
		for (int i=W.word_A; i<=W.word_B; i++)

@h Construction.

=
wording Wordings::new(int A, int B) {
	return (wording) { A, B };
}

wording Wordings::one_word(int A) {
	return (wording) { A, A };
}

@ Note that these two are sometimes used to construct empty wordings either
by moving |A| past |B|, or moving |B| before |A|.

=
wording Wordings::up_to(wording W, int last_wn) {
	if (Wordings::empty(W)) return W;
	W.word_B = last_wn;
	return W;
}

wording Wordings::from(wording W, int first_wn) {
	if (Wordings::empty(W)) return W;
	W.word_A = first_wn;
	return W;
}

@h Reading.

=
int Wordings::length(wording W) {
	if (Wordings::empty(W)) return 0;
	return W.word_B - W.word_A + 1;
}

int Wordings::phrasual_length(wording W) {
	if (Wordings::empty(W)) return 0;
	int bl = 0, n = 0;
	LOOP_THROUGH_WORDING(i, W) {
		if ((Lexer::word(i) == OPENBRACKET_V) || (Lexer::word(i) == OPENBRACE_V)) bl++;
		if ((Lexer::word(i) == CLOSEBRACKET_V) || (Lexer::word(i) == CLOSEBRACE_V)) bl--;
		if (bl == 0) n++;
	}
	return n;
}

int Wordings::first_wn(wording W) {
	return W.word_A;
}

int Wordings::last_wn(wording W) {
	return W.word_B;
}

int Wordings::delta(wording W1, wording W2) {
	return W1.word_A - W2.word_A;
}

@h Manipulation.
Unlike the construction routines above, these never make positional empty
wordings.

=
wording Wordings::truncate(wording W, int max) {
	if (Wordings::length(W) > max) W.word_B = W.word_A + max - 1;
	return W;
}

wording Wordings::first_word(wording W) {
	if (Wordings::empty(W)) return EMPTY_WORDING;
	W.word_B = W.word_A;
	return W;
}

wording Wordings::last_word(wording W) {
	if (Wordings::empty(W)) return EMPTY_WORDING;
	W.word_A = W.word_B;
	return W;
}

wording Wordings::trim_first_word(wording W) {
	if (Wordings::empty(W)) return EMPTY_WORDING;
	W.word_A++;
	if (W.word_A > W.word_B) return EMPTY_WORDING;
	return W;
}

wording Wordings::trim_last_word(wording W) {
	if (Wordings::empty(W)) return EMPTY_WORDING;
	W.word_B--;
	if (W.word_A > W.word_B) return EMPTY_WORDING;
	return W;
}

wording Wordings::trim_both_ends(wording W) {
	if (Wordings::empty(W)) return EMPTY_WORDING;
	W.word_A++; W.word_B--;
	if (W.word_A > W.word_B) return EMPTY_WORDING;
	return W;
}

@h Widening.

=
wording Wordings::union(wording W1, wording W2) {
	if (Wordings::empty(W1)) return W2;
	if (Wordings::empty(W2)) return W1;
	int w1 = W1.word_A; if (w1 > W2.word_A) w1 = W2.word_A; /* the min */
	int w2 = W1.word_B; if (w2 < W2.word_B) w2 = W2.word_B; /* the max */
	return Wordings::new(w1, w2);
}

@h Position.

=
int Wordings::within(wording SMALL, wording BIG) {
	if ((Wordings::nonempty(SMALL)) && (Wordings::nonempty(BIG)) &&
		(SMALL.word_A >= BIG.word_A) && (SMALL.word_B <= BIG.word_B))
		return TRUE;
	return FALSE;
}

source_location Wordings::location(wording W) {
	return Lexer::word_location(W.word_A);
}

@h Emptiness.
See above.

=
int Wordings::empty(wording W) {
	if ((W.word_A >= 0) && (W.word_B >= W.word_A)) return FALSE;
	return TRUE;
}

int Wordings::nonempty(wording W) {
	if ((W.word_A >= 0) && (W.word_B >= W.word_A)) return TRUE;
	return FALSE;
}

@h Comparing wordings.
First, though it's little needed, literal equality: two wordings are the
same only if they represent the same word numbers in the source.

=
int Wordings::eq(wording W1, wording W2) {
	if ((W1.word_A == W2.word_A) && (W1.word_B == W2.word_B))
		return TRUE;
	return FALSE;
}

@ Two wordings are said to "match" if they are nonempty and contain the same text.

The calculation overhead makes it marginally not worth using a hash function
to speed up the following comparison, which requires two excerpts to be
absolutely equal.

=
int Wordings::match(wording W1, wording W2) {
	if ((W1.word_A >= 0) && (W1.word_B >= 0) &&
		(Wordings::match_inner(W1.word_A, W1.word_B, W2.word_A, W2.word_B)))
		return TRUE;
	return FALSE;
}

int Wordings::starts_with(wording W, wording S) {
	if ((Wordings::nonempty(W)) && (Wordings::nonempty(S)) &&
		(Wordings::length(W) >= Wordings::length(S)) &&
		(Wordings::match_inner(W.word_A, W.word_A + S.word_B - S.word_A, S.word_A, S.word_B)))
		return TRUE;
	return FALSE;
}

int Wordings::match_inner(int w1, int w2, int w3, int w4) {
	if (w4-w3 != w2-w1) return FALSE;
	if ((w1<0) || (w3<0)) return FALSE;
	for (int j=0; j<=w2-w1; j++)
		if (compare_words(w1+j, w3+j) == FALSE) return FALSE;
	return TRUE;
}

@ Case sensitively:

=
int Wordings::match_cs(wording W1, wording W2) {
	if ((W1.word_A >= 0) && (W1.word_B >= 0) &&
		(Wordings::match_cs_inner(W1.word_A, W1.word_B, W2.word_A, W2.word_B)))
		return TRUE;
	return FALSE;
}

int Wordings::match_cs_inner(int w1, int w2, int w3, int w4) {
	if (w4-w3 != w2-w1) return FALSE;
	if ((w1<0) || (w3<0)) return FALSE;
	for (int j=0; j<=w2-w1; j++)
		if (compare_words_cs(w1+j, w3+j) == FALSE) return FALSE;
	return TRUE;
}

@ This alternative form is slower, but gets the case where one of the words
holds double-quoted text correctly. (We don't need this often because quoted
text is in general not allowed in identifier names.)

=
int Wordings::match_perhaps_quoted(wording W1, wording W2) {
	int w1 = W1.word_A, w2 = W1.word_B, w3 = W2.word_A, w4 = W2.word_B;
	if (w4-w3 != w2-w1) return FALSE;
	if ((w1<0) || (w3<0)) return FALSE;
	for (int j=0; j<=w2-w1; j++) {
		if (compare_words(w1+j, w3+j) == FALSE) {
			if ((Vocabulary::test_flags(w1+j, (TEXT_MC+TEXTWITHSUBS_MC))) &&
				(Vocabulary::test_flags(w3+j, (TEXT_MC+TEXTWITHSUBS_MC))) &&
				(Wide::cmp(Lexer::word_raw_text(w1+j), Lexer::word_raw_text(w3+j)) == 0))
				continue;
			return FALSE;
		}
	}
	return TRUE;
}

@ And relatedly, used for sorting into alphabetical order, a direct analogue
of |strcmp| but for word ranges:

=
int Wordings::strcmp(wording X, wording Y) {
	int x1 = X.word_A, x2 = X.word_B, y1 = Y.word_A, y2 = Y.word_B;
	if (x1 < 0) { if (y1 < 0) return 0; return -1; }
	if (y1 < 0) return 1;
	int n;
	int l1 = x2 - x1 + 1;
	int l2 = y2 - y1 + 1;
	for (n=0; (n<l1) && (n<l2); n++) {
		int delta = Wide::cmp(Lexer::word_text(x1 + n), Lexer::word_text(y1 + n));
		if (delta != 0) return delta;
	}
	return l1 - l2;
}

@h Bracketing.
We are going to need to look for paired brackets at the outside of an
excerpt reasonably quickly, and the following routine performs that test.

=
int Wordings::paired_brackets(wording W) {
	if ((Lexer::word(Wordings::first_wn(W)) == OPENBRACKET_V) &&
		(Lexer::word(Wordings::last_wn(W)) == CLOSEBRACKET_V) &&
		(Wordings::mismatched_brackets(Wordings::trim_both_ends(W)) == FALSE))
		return TRUE;
	return FALSE;
}

@ For problem detection:

=
int Wordings::mismatched_brackets(wording W) {
	int bl = 0;
	LOOP_THROUGH_WORDING(i, W) {
		if ((Lexer::word(i) == OPENBRACKET_V) || (Lexer::word(i) == OPENBRACE_V)) bl++;
		if ((Lexer::word(i) == CLOSEBRACKET_V) || (Lexer::word(i) == CLOSEBRACE_V)) bl--;
		if (bl < 0) return TRUE;
	}
	if (bl != 0) return TRUE;
	return FALSE;
}

@ For syntax disambiguation:

=
int Wordings::top_level_comma(wording W) {
	int bl = 0;
	LOOP_THROUGH_WORDING(i, W) {
		if ((Lexer::word(i) == OPENBRACKET_V) || (Lexer::word(i) == OPENBRACE_V)) bl++;
		if ((Lexer::word(i) == CLOSEBRACKET_V) || (Lexer::word(i) == CLOSEBRACE_V)) bl--;
		if ((bl == 0) && (Lexer::word(i) == COMMA_V)) return TRUE;
	}
	return FALSE;
}

@h Searching for unusual spacing in ranges.
Looking forward to see how far the current column or row extends,
for formatted tables. The idea is that we have a range |w1| to |w2|,
and that the current column or row extends from |w1| but may run only
part-way through: we look for the first point at which there is a
tab break (for column scanning) or a newline break (for row scanning),
and return the word position just before that break. If we do not find
one, it follows that the entire range holds the current column or row,
and we return |w2|.

=
int Wordings::last_word_of_formatted_text(wording W, int tab_flag) {
	if (Wordings::empty(W)) return -1;
	if (Wordings::length(W) == 1) return Wordings::first_wn(W);
	LOOP_THROUGH_WORDING(i, W)
		if (i > Wordings::first_wn(W))
			if (((tab_flag) && (Lexer::break_before(i) == '\t')) ||
				(Lexer::indentation_level(i) > 0) ||
				(Lexer::break_before(i) == '\n'))
					return i-1;
	return Wordings::last_wn(W);
}

@h The Writer.
The following implements the |%W| escape, which comes in four varieties:

=
void Wordings::writer(OUTPUT_STREAM, char *format_string, wording W) {
	switch (format_string[0]) {
		case 'W': /* bare |%W| means the same as |%-W|, so fall through to... */
		case '-': @<Write the stream with normalised casing@>; break;
		case '+': @<Write the stream raw@>; break;
		case '<': @<Write the stream in an abbreviated raw form@>; break;
		case '~': @<Write the stream in a raw form suitable for use in an I6 literal string@>; break;
		default: internal_error("bad %W modifier");
	}
}

@ Note that the empty wording causes nothing to be written to the stream.

@<Write the stream with normalised casing@> =
	LOOP_THROUGH_WORDING(j, W) {
		WRITE("%N", j);
		if (j<Wordings::last_wn(W)) WRITE(" ");
	}

@ Raw, in this context, means that it retains its original case, but not that
it retains its original spacing. This is sometimes problematic: we need to
go to some trouble to make punctuation look reasonably nice again, to obtain,
say,

>> The auctioneer said: "I'm not through yet -".

in preference to:

>> The auctioneer said : "I'm not through yet -" .

Note that we are not actually preserving the spacing in the original source --
that might have line breaks or other curiosities which we don't want: we are
instead imposing what we think are normal English conventions. While this
will sometimes be wrong, this is only likely to affect the index and problem
messages, so the user is not likely to be bothered.

@<Write the stream raw@> =
	LOOP_THROUGH_WORDING(j, W) {
		WRITE("%<N", j);
		int space = FALSE;
		if (j<Wordings::last_wn(W)) {
			space = TRUE;
			if (compare_word(j+1, COMMA_V)) space = FALSE;
			if (compare_word(j+1, COLON_V)) space = FALSE;
			if (compare_word(j+1, CLOSEBRACKET_V)) space = FALSE;
		}
		if (compare_word(j, OPENBRACKET_V)) space = FALSE;
		if (space) WRITE(" ");
	}

@ A variation on this tries to contain unreasonably long pastes of quoted
literals, and is used in printing out problem messages, where quoting
back the offending source text might make unhelpfully vast paragraphs
in which the actual information is more or less hidden.

@d STRING_TOLERANCE_LIMIT 70

@<Write the stream in an abbreviated raw form@> =
	if (Wordings::empty(W)) {
		WRITE("<no text>");
	} else {
		LOOP_THROUGH_WORDING(i, W) {
			int space = TRUE;
			if (i == Wordings::first_wn(W)) space = FALSE;
			else {
				if (compare_word(i, COMMA_V)) space = FALSE;
				if (compare_word(i, COLON_V)) space = FALSE;
				if (compare_word(i, SEMICOLON_V)) space = FALSE;
				if (compare_word(i, CLOSEBRACE_V)) space = FALSE;
				if (compare_word(i, CLOSEBRACKET_V)) space = FALSE;
				if (compare_word(i-1, OPENBRACE_V)) space = FALSE;
				if (compare_word(i-1, OPENBRACKET_V)) space = FALSE;
			}
			if (space) WRITE(" ");
			wchar_t *p = Lexer::word_raw_text(i);
			int L = Wide::len(p);
			if (L > STRING_TOLERANCE_LIMIT+5) {
				for (int j=0; j<STRING_TOLERANCE_LIMIT/2; j++) PUT(p[j]);
				WRITE(" [...] ");
				for (int j=STRING_TOLERANCE_LIMIT/2; j>0; j--) PUT(p[L-j]);
			} else {
				WRITE("%w", p);
			}
			if ((i >= Wordings::first_wn(W)+1) && (compare_word(i-1, OPENI6_V))) {
				WRITE("-)");
			}
		}
	}

@ Another variation, this time formatted for use in I6 double-quoted text.
Here we don't care about punctuation spacing, because we are only writing
in comments and I6 debugging routines, but we do need to use the I6 escape
|~| for a double-quotation mark.

@<Write the stream in a raw form suitable for use in an I6 literal string@> =
	LOOP_THROUGH_WORDING(j, W) {
		wchar_t *str = Lexer::word_raw_text(j);
		if (j>Wordings::first_wn(W)) WRITE(" ");
		for (int k=0; str[k] != 0; k++) {
			int c = str[k];
			switch (c) {
				case '@': WRITE("@@"); break;
				case '"': WRITE("~"); break;
				case '^': WRITE("[cr]"); break;
				case '\\': WRITE("[backslash]"); break;
				default: PUT(c);
			}
		}
	}
