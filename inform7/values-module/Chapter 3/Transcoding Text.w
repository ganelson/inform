[TranscodeText::] Transcoding Text.

To change the escape-character conventions used in text streams.

@ The functions in this section -- which perhaps doesn't belong in the //values//
module any better than anywhere else -- all work on text to change its encoding.
This is not encoding in the sense of ASCII vs UTF-8, though it can have a bearing
on whether the text can now be written as plain ASCII or not. Rather, it has
to do with whether certain "difficult" characters are expressed as their literal
character codes, or with a sequence of "escape characters".

For example, in some situations |can[']t| means "can't"; and sometimes
"[unicode 65]mazonia" means "Amazonia". The functions here allow the escaping
conventions to be applied or removed.

@ First off, we take a wide Unicode string and convert it to a text stream
using an encoding scheme to mask characters we don't want to appear. The
scheme is expressed as a bitmap of features, each o which can be off or on.

@d CT_CAPITALISE 1 /* capitalise first letter of text */
@d CT_EXPAND_APOSTROPHES 2 /* sometimes regard |'| as |"| */
@d CT_RECOGNISE_APOSTROPHE_SUBSTITUTION 4 /* recognise |[']| as a literal |'| */
@d CT_RECOGNISE_UNICODE_SUBSTITUTION 8 /* recognise |[unicode N]| as a literal char */
@d CT_DEQUOTE 16 /* ignore initial and terminal |"| pair, e.g., render |"fish"| as |fish| */
@d CT_FOR_ARRAY 32 /* force use of |@{xx}| form not |@@ddd| */
@d CT_BOX_QUOTATION 64 /* format line breaks into text for an I6 |box| statement */
@d CT_RAW 128 /* ignore everything except capitalisation and dequoting */
@d CT_I6 256 /* ignore everything except capitalisation and dequoting */
@d CT_EXPAND_APOSTROPHES_RAWLY 512 /* sometimes regard |'| as |"| */

=
void TranscodeText::from_wide_string(OUTPUT_STREAM, inchar32_t *p, int options) {
	int i, from = 0, to = Wide::len(p), esc_digit = FALSE;
	if ((options & CT_DEQUOTE) && (p[0] == '"') && (p[to-1] == '"')) {
		from++; to--;
	}
	if (options & CT_RAW) {
		for (i=from; i<to; i++) {
			if ((i == from) && (options & CT_CAPITALISE))
				PUT(Characters::toupper(p[i]));
			else
				PUT(p[i]);
		}
	} else {
		for (i=from; i<to; i++) {
			switch(p[i]) {
				case '\n':
					if (options & CT_BOX_QUOTATION) WRITE("\n");
					else WRITE(" ");
					break;
				case '\t':
					if (options & CT_BOX_QUOTATION) WRITE("\n");
					else WRITE(" ");
					break;
				case NEWLINE_IN_STRING:
					if (options & CT_BOX_QUOTATION) WRITE("\n");
					else WRITE("^"); break;
				case '"': WRITE("~"); break;
				case '@':
					if (options & CT_FOR_ARRAY) WRITE("@{40}");
					else { WRITE("@@64"); esc_digit = TRUE; continue; }
					break;
				case '^':
					if (options & CT_BOX_QUOTATION) WRITE("^");
					else if (options & CT_FOR_ARRAY) WRITE("@{5E}");
					else { WRITE("@@94"); esc_digit = TRUE; continue; }
					break;
				case '~':
					if (options & CT_FOR_ARRAY) WRITE("@{7E}");
					else { WRITE("@@126"); esc_digit = TRUE; continue; }
					break;
				case '\\': WRITE("@{5C}"); break;
				case '\'':
					if (options & CT_EXPAND_APOSTROPHES)
						@<Apply Inform 7's convention on single quotation marks@>
					else WRITE("'");
					break;
				case '[':
					if ((options & CT_RECOGNISE_APOSTROPHE_SUBSTITUTION) &&
						(p[i+1] == '\'') && (p[i+2] == ']')) { i += 2; WRITE("'"); }
					else if (options & CT_RECOGNISE_UNICODE_SUBSTITUTION) {
						int n = TranscodeText::expand_unisub(OUT, p, i);
						if (n == -1) WRITE("["); else i = n;
					} else WRITE("[");
					break;
				default:
					if ((i==from) && (options & CT_CAPITALISE))
						WRITE("%c", Characters::toupper(p[i]));
					else if ((esc_digit) && (Characters::isdigit(p[i])))
						WRITE("@{%02x}", p[i]);
					else
						WRITE("%c", p[i]);
					break;
			}
			esc_digit = FALSE;
		}
	}
}

@ This much simpler encoder is used when emitting text in a |say "Whatever"|
phrase invocation:

=
void TranscodeText::from_wide_string_for_emission(OUTPUT_STREAM, inchar32_t *p) {
	int i, from = 0, to = Wide::len(p);
	if ((p[0] == '"') && (p[to-1] == '"')) {
		from++; to--;
	}
	for (i=from; i<to; i++) {
		switch(p[i]) {
			case '\n':
				WRITE(" ");
				break;
			case '\t':
				WRITE(" ");
				break;
			case NEWLINE_IN_STRING:
				WRITE("\n");
				break;
			case '\'':
				@<Rawly apply Inform 7's convention on single quotation marks@>
				break;
			default:
				WRITE("%c", p[i]);
				break;
		}
	}
}

@ And this one for the special conventions applying to box quotations:

=
void TranscodeText::bq_from_wide_string(OUTPUT_STREAM, inchar32_t *p) {
	int i, from = 0, to = Wide::len(p), esc_digit = FALSE;
	if ((p[0] == '"') && (p[to-1] == '"')) {
		from++; to--;
	}
	for (i=from; i<to; i++) {
		switch(p[i]) {
			case '[': {
				int n = TranscodeText::expand_unisub(OUT, p, i);
				if (n == -1) WRITE("["); else i = n;
				break;
			}
			default:
				if ((esc_digit) && (Characters::isdigit(p[i])))
					WRITE("@{%02x}", p[i]);
				else
					WRITE("%c", p[i]);
				break;
		}
		esc_digit = FALSE;
	}
}

@ This is where Inform's convention on expanding single quotation marks
to double, provided they appear to be quoting text rather than used as
apostrophes in contractions such as "don't", is implemented. Note the
exceptional case.

@<Apply Inform 7's convention on single quotation marks@> =
	if ((i==from) && (p[i+1] == 's') && ((to == 3) || (p[i+2] == ' ')))
		WRITE("'"); /* allow apostrophe if appending e.g. "'s nose" to "Jane" */
	else if ((i>0) && (p[i+1]) &&
		(Characters::isalphabetic(p[i-1])) &&
		(Characters::isalphabetic(p[i+1])))
		WRITE("'"); /* allow apostrophe sandwiched between two letters */
	else {
		WRITE("~"); /* and otherwise convert to double-quote */
	}

@<Rawly apply Inform 7's convention on single quotation marks@> =
	if ((i==from) && (p[i+1] == 's') && ((to == 3) || (p[i+2] == ' ')))
		WRITE("'"); /* allow apostrophe if appending e.g. "'s nose" to "Jane" */
	else if ((i>0) && (p[i+1]) &&
		(Characters::isalphabetic(p[i-1])) &&
		(Characters::isalphabetic(p[i+1])))
		WRITE("'"); /* allow apostrophe sandwiched between two letters */
	else {
		WRITE("\""); /* and otherwise convert to double-quote */
	}

@ This stream version is essentially the same as //TranscodeText::from_wide_string//,
but with a different input:

=
void TranscodeText::from_stream(OUTPUT_STREAM, text_stream *p, int options) {
	int i, from = 0, to = Str::len(p), esc_digit = FALSE;
	if ((options & CT_DEQUOTE) && (Str::get_at(p, from) == '"') && (Str::get_at(p, to-1) == '"')) {
		from++; to--;
	}
	if (options & CT_RAW) {
		for (i=from; i<to; i++) {
			inchar32_t c = Str::get_at(p, i);
			if ((i == from) && (options & CT_CAPITALISE))
				WRITE("%c", (int) Characters::toupper(c));
			else
				WRITE("%c", (int) c);
		}
	} else {
		for (i=from; i<to; i++) {
			inchar32_t c = Str::get_at(p, i);
			switch(c) {
				case '\n':
					if (options & CT_BOX_QUOTATION) WRITE("\"\n\"");
					else WRITE(" ");
					break;
				case '\t':
					if (options & CT_BOX_QUOTATION) WRITE("\"\n\"");
					else WRITE(" ");
					break;
				case NEWLINE_IN_STRING:
					if (options & CT_BOX_QUOTATION) WRITE("\"\n\"");
					else WRITE("^"); break;
				case '"':
					if (options & CT_I6) WRITE("~");
					else WRITE("%c", (int) c);
					break;
				case '@':
					if (options & CT_I6) {
						if (options & CT_FOR_ARRAY) WRITE("@{40}");
						else { WRITE("@@64"); esc_digit = TRUE; continue; }
					} else WRITE("%c", (int) c);
					break;
				case '^':
					if (options & CT_I6) {
						if (options & CT_BOX_QUOTATION) WRITE("\"\n\"");
						else if (options & CT_FOR_ARRAY) WRITE("@{5E}");
						else { WRITE("@@94"); esc_digit = TRUE; continue; }
					} else WRITE("%c", (int) c);
					break;
				case '~':
					if (options & CT_I6) {
						if (options & CT_FOR_ARRAY) WRITE("@{7E}");
						else { WRITE("@@126"); esc_digit = TRUE; continue; }
					} else WRITE("%c", (int) c);
					break;
				case '\\':
					if (options & CT_I6) {
						WRITE("@{5C}");
					} else WRITE("%c", (int) c);
					break;
				case '\'':
					if (options & CT_EXPAND_APOSTROPHES)
						@<Apply Inform 7's convention on single quotation marks, stream version@>
					else WRITE("'");
					break;
				case '[':
					if ((options & CT_RECOGNISE_APOSTROPHE_SUBSTITUTION) &&
						(Str::get_at(p, i+1) == '\'') && (Str::get_at(p, i+2) == ']')) {
							i += 2; WRITE("'");
					} else if (options & CT_RECOGNISE_UNICODE_SUBSTITUTION) {
						int n = TranscodeText::expand_unisub_S(OUT, p, i);
						if (n == -1) WRITE("["); else i = n;
					} else WRITE("[");
					break;
				default:
					if ((i==from) && (options & CT_CAPITALISE))
						WRITE("%c", (int) Characters::toupper(c));
					else if ((esc_digit) && (Characters::isdigit(c)))
						WRITE("@{%02x}", (int) c);
					else
						WRITE("%c", (int) c);
					break;
			}
			esc_digit = FALSE;
		}
	}
}

@ This is where Inform's convention on expanding single quotation marks
to double, provided they appear to be quoting text rather than used as
apostrophes in contractions such as "don't", is implemented. Note the
exceptional case.

@<Apply Inform 7's convention on single quotation marks, stream version@> =
	if ((i==from) && (Str::get_at(p, i+1) == 's') &&
		((to == 3) || (Str::get_at(p, i+2) == ' ')))
		WRITE("'"); /* allow apostrophe if appending e.g. "'s nose" to "Jane" */
	else if ((i>0) && (Str::get_at(p, i+1)) &&
		(Characters::isalphabetic(Str::get_at(p, i-1))) &&
		(Characters::isalphabetic(Str::get_at(p, i+1))))
		WRITE("'"); /* allow apostrophe sandwiched between two letters */
	else {
		if (options & CT_I6) WRITE("~"); /* and otherwise convert to double-quote */
		else WRITE("\"");
	}

@ This looks for "[unicode 8212]" and turns it into an em-dash, for example.

@d MAX_UNISUB_LENGTH 128

=
int TranscodeText::expand_unisub(OUTPUT_STREAM, inchar32_t *p, int i) {
	if ((p[i+1] == 'u') && (p[i+2] == 'n') && (p[i+3] == 'i') && (p[i+4] == 'c')
		&& (p[i+5] == 'o') && (p[i+6] == 'd') && (p[i+7] == 'e') && (p[i+8] == ' ')) {
		TEMPORARY_TEXT(substitution_buffer)
		int j = i+9;
		while (p[j] == ' ') j++;
		while ((p[j]) && (p[j] != ']'))
			PUT_TO(substitution_buffer, p[j++]);
		if (p[j] == ']') {
			wording XW = Feeds::feed_text(substitution_buffer);
			if (<s-unicode-character>(XW) == FALSE) return -1;
			PUT((inchar32_t) Rvalues::to_Unicode_point(<<rp>>));
			return j;
		} else return -1;
	} else return -1;
}

int TranscodeText::expand_unisub_S(OUTPUT_STREAM, text_stream *p, int i) {
	if (Str::includes_wide_string_at(p, U"unicode ", i+1)) {
		TEMPORARY_TEXT(substitution_buffer)
		int j = i+9;
		while (Str::get_at(p, j) == ' ') j++;
		while ((Str::get_at(p, j)) && (Str::get_at(p, j) != ']'))
			PUT_TO(substitution_buffer, Str::get_at(p, j++));
		if (Str::get_at(p, j) == ']') {
			wording XW = Feeds::feed_text(substitution_buffer);
			if (<s-unicode-character>(XW) == FALSE) return -1;
			PUT((inchar32_t) Rvalues::to_Unicode_point(<<rp>>));
			return j;
		} else return -1;
	} else return -1;
}

@ A convenient package for the above:

=
void TranscodeText::from_text_with_options(OUTPUT_STREAM, wording W, int opts, int raw) {
	LOOP_THROUGH_WORDING(j, W) {
		inchar32_t *p;
		if (raw) p = Lexer::word_raw_text(j); else p = Lexer::word_text(j);
		TranscodeText::from_wide_string(OUT, p, opts);
		if (j<Wordings::last_wn(W)) WRITE(" ");
	}
}

@ With the options all off:

=
void TranscodeText::comment(OUTPUT_STREAM, wording W) {
	TranscodeText::from_text_with_options(OUT, W, 0, FALSE);
}

void TranscodeText::from_text(OUTPUT_STREAM, wording W) {
	TranscodeText::from_text_with_options(OUT, W, 0, TRUE);
}
