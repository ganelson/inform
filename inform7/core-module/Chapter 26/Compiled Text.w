[CompiledText::] Compiled Text.

To compile string constants and comments.

@ We now take a wide Unicode string and compile a double-quoted I6 string
constant which will print out the same content, or initialise a string array.

A subtly different set of escape characters are used here. It's all trickier
than it might be because of some unfortunate design choices in I6. For
instance, an |@| character can't be escaped as |@{40}| because that
would be expanded too early in the string-reading process, so that it
would still be read as an escape-character |@|, not a literal one.
We therefore have to use |@@64|. This unfortunately goes wrong, however,
when the immediately following character is a decimal digit, because then
we might construct, e.g., |@@647|, and I6 will throw an error: no valid
character has ZSCII code 647. We therefore use the |@{...}| escape to
represent any digit following an |@@| escape. Since no digit is itself
an escape character with side-effects, a vicious circle is avoided.

Initialisation of I6 string arrays has different conventions again: these
behave more like dictionary words and the |@@| escape is not allowed.

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
void CompiledText::from_wide_string(OUTPUT_STREAM, wchar_t *p, int options) {
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
						@<Apply Inform 7's convention on interpreting single quotation marks@>
					else WRITE("'");
					break;
				case '[':
					if ((options & CT_RECOGNISE_APOSTROPHE_SUBSTITUTION) &&
						(p[i+1] == '\'') && (p[i+2] == ']')) { i += 2; WRITE("'"); }
					else if (options & CT_RECOGNISE_UNICODE_SUBSTITUTION) {
						int n = CompiledText::expand_unisub(OUT, p, i);
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

void CompiledText::from_wide_string_for_emission(OUTPUT_STREAM, wchar_t *p) {
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
				@<Rawly apply Inform 7's convention on interpreting single quotation marks@>
				break;
			default:
				WRITE("%c", p[i]);
				break;
		}
	}
}

void CompiledText::bq_from_wide_string(OUTPUT_STREAM, wchar_t *p) {
	int i, from = 0, to = Wide::len(p), esc_digit = FALSE;
	if ((p[0] == '"') && (p[to-1] == '"')) {
		from++; to--;
	}
	for (i=from; i<to; i++) {
		switch(p[i]) {
/*			case '\n':
				WRITE("\n");
				break;
			case '\t':
				WRITE("\n");
				break;
			case NEWLINE_IN_STRING:
				WRITE("\n");
				break;
			case '"': WRITE("~"); break;
			case '@':
				WRITE("@@64"); esc_digit = TRUE; continue;
			case '^':
				WRITE("^");
				break;
			case '~':
				WRITE("@@126"); esc_digit = TRUE; continue;
			case '\\': WRITE("@{5C}"); break;
			case '\'':
				WRITE("'");
				break;
*/
			case '[': {
				int n = CompiledText::expand_unisub(OUT, p, i);
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

@<Apply Inform 7's convention on interpreting single quotation marks@> =
	if ((i==from) && (p[i+1] == 's') && ((to == 3) || (p[i+2] == ' ')))
		WRITE("'"); /* allow apostrophe if appending e.g. "'s nose" to "Jane" */
	else if ((i>0) && (p[i+1]) &&
		(CompiledText::alphabetic(p[i-1])) &&
		(CompiledText::alphabetic(p[i+1])))
		WRITE("'"); /* allow apostrophe sandwiched between two letters */
	else {
		WRITE("~"); /* and otherwise convert to double-quote */
	}

@<Rawly apply Inform 7's convention on interpreting single quotation marks@> =
	if ((i==from) && (p[i+1] == 's') && ((to == 3) || (p[i+2] == ' ')))
		WRITE("'"); /* allow apostrophe if appending e.g. "'s nose" to "Jane" */
	else if ((i>0) && (p[i+1]) &&
		(CompiledText::alphabetic(p[i-1])) &&
		(CompiledText::alphabetic(p[i+1])))
		WRITE("'"); /* allow apostrophe sandwiched between two letters */
	else {
		WRITE("\""); /* and otherwise convert to double-quote */
	}

@ =
void CompiledText::from_stream(OUTPUT_STREAM, text_stream *p, int options) {
	int i, from = 0, to = Str::len(p), esc_digit = FALSE;
	if ((options & CT_DEQUOTE) && (Str::get_at(p, from) == '"') && (Str::get_at(p, to-1) == '"')) {
		from++; to--;
	}
	if (options & CT_RAW) {
		for (i=from; i<to; i++) {
			int c = Str::get_at(p, i);
			if ((i == from) && (options & CT_CAPITALISE))
				WRITE("%c", Characters::toupper(c));
			else
				WRITE("%c", c);
		}
	} else {
		for (i=from; i<to; i++) {
			int c = Str::get_at(p, i);
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
					else WRITE("%c", c);
					break;
				case '@':
					if (options & CT_I6) {
						if (options & CT_FOR_ARRAY) WRITE("@{40}");
						else { WRITE("@@64"); esc_digit = TRUE; continue; }
					} else WRITE("%c", c);
					break;
				case '^':
					if (options & CT_I6) {
						if (options & CT_BOX_QUOTATION) WRITE("\"\n\"");
						else if (options & CT_FOR_ARRAY) WRITE("@{5E}");
						else { WRITE("@@94"); esc_digit = TRUE; continue; }
					} else WRITE("%c", c);
					break;
				case '~':
					if (options & CT_I6) {
						if (options & CT_FOR_ARRAY) WRITE("@{7E}");
						else { WRITE("@@126"); esc_digit = TRUE; continue; }
					} else WRITE("%c", c);
					break;
				case '\\':
					if (options & CT_I6) {
						WRITE("@{5C}");
					} else WRITE("%c", c);
					break;
				case '\'':
					if (options & CT_EXPAND_APOSTROPHES)
						@<Apply Inform 7's convention on interpreting single quotation marks, stream version@>
					else WRITE("'");
					break;
				case '[':
					if ((options & CT_RECOGNISE_APOSTROPHE_SUBSTITUTION) &&
						(Str::get_at(p, i+1) == '\'') && (Str::get_at(p, i+2) == ']')) { i += 2; WRITE("'"); }
					else if (options & CT_RECOGNISE_UNICODE_SUBSTITUTION) {
						int n = CompiledText::expand_unisub_S(OUT, p, i);
						if (n == -1) WRITE("["); else i = n;
					} else WRITE("[");
					break;
				default:
					if ((i==from) && (options & CT_CAPITALISE))
						WRITE("%c", Characters::toupper(c));
					else if ((esc_digit) && (Characters::isdigit(c)))
						WRITE("@{%02x}", c);
					else
						WRITE("%c", c);
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

@<Apply Inform 7's convention on interpreting single quotation marks, stream version@> =
	if ((i==from) && (Str::get_at(p, i+1) == 's') && ((to == 3) || (Str::get_at(p, i+2) == ' ')))
		WRITE("'"); /* allow apostrophe if appending e.g. "'s nose" to "Jane" */
	else if ((i>0) && (Str::get_at(p, i+1)) &&
		(CompiledText::alphabetic(Str::get_at(p, i-1))) &&
		(CompiledText::alphabetic(Str::get_at(p, i+1))))
		WRITE("'"); /* allow apostrophe sandwiched between two letters */
	else {
		if (options & CT_I6) WRITE("~"); /* and otherwise convert to double-quote */
		else WRITE("\"");
	}

@ Where we must tiresomely use this:

=
int CompiledText::alphabetic(int letter) {
	return isalpha(Characters::remove_accent(letter));
}

@ This looks for "[unicode 8212]" and turns it into an em-dash, for example.

@d MAX_UNISUB_LENGTH 128

=
int CompiledText::expand_unisub(OUTPUT_STREAM, wchar_t *p, int i) {
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
			PUT(Rvalues::to_Unicode_point(<<rp>>));
			return j;
		} else return -1;
	} else return -1;
}

int CompiledText::expand_unisub_S(OUTPUT_STREAM, text_stream *p, int i) {
	if (Str::includes_wide_string_at(p, L"unicode ", i+1)) {
		TEMPORARY_TEXT(substitution_buffer)
		int j = i+9;
		while (Str::get_at(p, j) == ' ') j++;
		while ((Str::get_at(p, j)) && (Str::get_at(p, j) != ']'))
			PUT_TO(substitution_buffer, Str::get_at(p, j++));
		if (Str::get_at(p, j) == ']') {
			wording XW = Feeds::feed_text(substitution_buffer);
			if (<s-unicode-character>(XW) == FALSE) return -1;
			PUT(Rvalues::to_Unicode_point(<<rp>>));
			return j;
		} else return -1;
	} else return -1;
}

@ A convenient package for the above:

=
void CompiledText::from_text_with_options(OUTPUT_STREAM, wording W, int opts, int raw) {
	LOOP_THROUGH_WORDING(j, W) {
		wchar_t *p;
		if (raw) p = Lexer::word_raw_text(j); else p = Lexer::word_text(j);
		CompiledText::from_wide_string(OUT, p, opts);
		if (j<Wordings::last_wn(W)) WRITE(" ");
	}
}

@ Whence:

=
void CompiledText::comment(OUTPUT_STREAM, wording W) {
	CompiledText::from_text_with_options(OUT, W, 0, FALSE);
}

void CompiledText::from_text(OUTPUT_STREAM, wording W) {
	CompiledText::from_text_with_options(OUT, W, 0, TRUE);
}

@ This doesn't really belong here, or anywhere else, really:

=
void CompiledText::divider_comment(void) {
	Produce::comment(Emit::tree(), I"----------------------------------------------------------------------------------------------------");
}
