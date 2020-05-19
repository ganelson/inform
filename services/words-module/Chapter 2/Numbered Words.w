[Word::] Numbered Words.

Some utilities for handling single words referred to by number.

@h Comparisons.
Comparison of the word at a given numbered position against some known
word, say "rulebook", must be done very quickly. The whole point of the
vocabulary bank identifying each distinct word was to enable this to be
done by a single comparison of pointers: and to avoid the overhead of a
function call, we perform this with macros.

@d compare_word(w, voc) (Lexer::word(w) == (voc))
@d compare_words(w1, w2) (Lexer::word(w1) == Lexer::word(w2))
@d compare_words_cs(w1, w2) (Wide::cmp(Lexer::word_raw_text(w1), Lexer::word_raw_text(w2)) == 0)

@ We can also, more slowly, perform a direct string comparison. If carried
out on the original, raw, text, this will be case sensitive -- which is
usually wrong for Inform purposes. On the treated text, however, we are
comparing a case-normalised version of the original word, which is likely
to be safely case insensitive comparison, provided that the content of |t|
is also normalised.

=
int Word::compare_by_strcmp(int w, wchar_t *t) {
	return (Wide::cmp(Lexer::word_text(w), t) == 0);
}
int Word::compare_raw_by_strcmp(int w, wchar_t *t) {
	return (Wide::cmp(Lexer::word_raw_text(w), t) == 0);
}

@h Correct use of text substitutions.
If a "word" is going to be quoted literal text, then it has to use the
characters |[| and |]| in a matched way, and without nesting them. The
following verifies that.

These rules are quite strict. It could be argued that nested brackets should be
allowed, allowing comments in text substitutions, but the result would be hard
to read and tricky for the user interface applications to syntax-colour.

=
int Word::well_formed_text_routine(wchar_t *fw) {
	int i, escaped = NOT_APPLICABLE;
	for (i=0; fw[i] != 0; i++) {
		if (fw[i] == TEXT_SUBSTITUTION_BEGIN) {
			if (escaped == TRUE) return FALSE;
			escaped = TRUE;
		}
		if (fw[i] == TEXT_SUBSTITUTION_END) {
			if (escaped != TRUE) return FALSE;
			escaped = FALSE;
		}
	}
	if (escaped == NOT_APPLICABLE) return escaped;
	if (escaped) return FALSE;
	return TRUE;
}

int Word::perhaps_ill_formed_text_routine(wchar_t *fw) {
	int i;
	for (i=0; fw[i] != 0; i++) {
		if (fw[i] == TEXT_SUBSTITUTION_BEGIN) return TRUE;
		if (fw[i] == TEXT_SUBSTITUTION_END) return TRUE;
	}
	return FALSE;
}

@h Casing and sentence division.
Casing is only sometimes informative in English: for the first word in
a sentence, we expect to find an upper-case letter, so that there is no
easy way to tell the name of a person or institution from a common noun.
But in other cases an upper case initial letter is unexpected, and can
tell us something.

=
int Word::unexpectedly_upper_case(int wn) {
	if (wn<1) return FALSE;
	if (compare_word(wn-1, FULLSTOP_V)) return FALSE;
	if (compare_word(wn-1, PARBREAK_V)) return FALSE;
	if (compare_word(wn-1, COLON_V)) return FALSE;
	if (isupper(*(Lexer::word_raw_text(wn)))) {
		if (Word::text_ending_sentence(wn-1)) return FALSE;
		return TRUE;
	}
	return FALSE;
}

@ Is the word at |wn| in single quotes? Count the number at the ends.

=
int Word::singly_quoted(int wn) {
	if (wn<1) return FALSE;
	wchar_t *p = Lexer::word_raw_text(wn);
	int qc = 0;
	if (p[0] == '\'') qc++;
	if ((Wide::len(p) > 1) && (p[Wide::len(p)-1] == '\'')) qc++;
	return qc;
}

@ Does the word at |wn| appear to be a piece of quoted text which, because
it ends with punctuation, may also end the sentence which quotes it?

=
int Word::text_ending_sentence(int wn) {
	wchar_t *p = Lexer::word_raw_text(wn);
	if (p[0] != '"') return FALSE;
	p += Wide::len(p) - 2;
	if ((p[0] == '.') && (p[1] == '"')) return TRUE;
	if ((p[0] == '?') && (p[1] == '"')) return TRUE;
	if ((p[0] == '!') && (p[1] == '"')) return TRUE;
	p--;
	if ((p[0] == '.') && (p[1] == ')') && (p[2] == '"')) return TRUE;
	if ((p[0] == '?') && (p[1] == ')') && (p[2] == '"')) return TRUE;
	if ((p[0] == '!') && (p[1] == ')') && (p[2] == '"')) return TRUE;
	if ((p[0] == '.') && (p[1] == '\'') && (p[2] == '"')) return TRUE;
	if ((p[0] == '?') && (p[1] == '\'') && (p[2] == '"')) return TRUE;
	if ((p[0] == '!') && (p[1] == '\'') && (p[2] == '"')) return TRUE;
	return FALSE;
}

@h Dequoting literal text.
A utility for stripping double-quotes from literal text, along with
initial or trailing spaces inside those quotes.

=
void Word::dequote(int wn) {
	wchar_t *previous_text = Lexer::word_text(wn);
	wchar_t *dequoted_text;
	if (previous_text[0] != '"') return;
	Lexer::set_word_raw_text(wn, Lexer::copy_to_memory(Lexer::word_raw_text(wn)));
	dequoted_text = previous_text + 1;
	while (*(dequoted_text) == ' ') dequoted_text++;
	if ((Wide::len(dequoted_text) > 0) &&
		(*(dequoted_text+Wide::len(dequoted_text)-1) == '"'))
		*(dequoted_text+Wide::len(dequoted_text)-1) = 0;
	while ((Wide::len(dequoted_text) > 0) &&
		(*(dequoted_text+Wide::len(dequoted_text)-1) == ' '))
		*(dequoted_text+Wide::len(dequoted_text)-1) = 0;
	Lexer::set_word_text(wn, dequoted_text);
	LOGIF(VOCABULARY, "Dequoting word %d <%w> to <%w>\n",
		wn, previous_text, dequoted_text);
	Vocabulary::identify_word(wn);
	Vocabulary::set_raw_exemplar_to_text(wn);
}

@h Dictionary words.
We take a wide Unicode string and compile an I6 dictionary word constant
to lodge the same text into the virtual machine's parsing dictionary.

A legal I6 dictionary word can take several forms: it can be in single
quotes, |'thus'|, but only if it is more than one character long, since
|'t'| would be the character value of lower-case T instead. (Or it can be
double-quoted |"so"|, but only in grammar or properties; this usage is
deprecated and we avoid it.) Within the dictionary word, |^| is an escape
character meaning a literal single quote, and the notation |@{xx}| is an
escape meaning the character with hexadecimal value |xx|.

Optionally, a dictionary word can end with a pair of slashes and then,
optionally again, markers to indicate that the word is (for instance) a
plural: thus |'newts//p'|. Using no markers, as in |'toads//'|, makes a
word equivalent to that without a marker, but avoids the single-letter
problem -- so the preferred modern way to write a single-character I6
dictionary word is |'t//'|, and this is what the following routine does.
(Note the exceptional case where the word consists only of a |'/'|: here
we cannot write |'///'| because I6 reads this as |//| plus an invalid
marker |/|, and throws an error. We escape the single |/| to avoid this.
In all other cases there's no need to escape a |/|.)

Dictionary words with a literal |~| in are, as it happens, not parsable
by the Z-machine, but the code below -- employing the |@{7E}|
escape -- is in principle legal, and it does work on Glulx.

Very long words can safely be truncated since the virtual machines do not
have indefinitely long dictionary resolution anyway, and we had better do
so because I6 rejects overlong text between single quotation marks.

=
void Word::compile_to_I6_dictionary(OUTPUT_STREAM, wchar_t *p, int pluralise) {
	int c, n = 0;
	WRITE("'");
	for (c=0; p[c] != 0; c++) {
		switch(p[c]) {
			case '/': if (p[1] == 0) WRITE("@{2F}"); else WRITE("/"); break;
			case '\'': WRITE("^"); break;
			case '^': WRITE("@{5E}"); break;
			case '~': WRITE("@{7E}"); break;
			case '@': WRITE("@{40}"); break;
			default: PUT(p[c]);
		}
		if (n++ > 32) break;
	}
	if (pluralise) WRITE("//p");
	else if (Wide::len(p) == 1) WRITE("//");
	WRITE("'");
}
