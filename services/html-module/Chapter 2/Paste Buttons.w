[PasteButtons::] Paste Buttons.

HTML for a button which, when clicked, pastes Inform source text into
the Source panel of the application, or opens a file or folder on the host
computer.

@h Pastes and their notation.
A paste button is intended to be such that the user clicks it, and some
text is inserted at the current cursor position in the Source panel of the
Inform application.

This is done with Javascript which looks something like this:
= (text)
	var myProject = window.Project;
	myProject.selectView('source');
	myProject.pasteCode('Trying Taking Manhattan');
=

@ The challenges here are that (a) the code to be pasted may be, say, as much
as 5K in size, and that (b) it needs to include some special characters,
escaped in a way which the app has to deal with correctly. This has proved
a challenge because, historically, different Javascript implementations
have handled escape characters in quoted text differently. (For instance, some
allowing a double-quote |"| to appear as a literal in single-quoted text, others
requiring |&quot;| to be used, and others not recognising HTML entities such as
|&quot;| at all.)

To avoid this issue, Inform adopted a notation of its own in 2007. All
Inform GUI apps have to follow this rule when reading the argument to
|pasteCode|:

Each instance of |[=0xHHHH=]| is replaced with the Unicode character whose
hexadecimal code is |HHHH|; there will always be four digits, with leading
zeros as needed, and |A| to |F| will be written in upper case. The only
Unicode characters with codes below |0x0020| which must be handled are
newline, |0x000A|, and tab, |0x0009|.

And any Inform tool generating such an argument -- either the renderer below,
or the one in //indoc//, which also generates pastes -- must use this notation
to escape every instance of the following problematic characters:

(a) every tab is escaped to |[=0x0009=]|;
(b) every newline is escaped to |[=0x000A=]|;
(c) every double quotation mark is escaped to |[=0x0022=]|;
(d) every ampersand is escaped to |[=0x0026=]|;
(e) every single quotation mark is escaped to |[=0x0027=]|;
(f) every less than sign is escaped to |[=0x003C=]|;
(g) every greater than sign is escaped to |[=0x003E=]|;
(h) every backslash is escaped to |[=0x005C=]|.

It may also choose to escape other character codes, as it prefers, but will
never generate any codes below |0x0020| other than newline, |0x000A|, and tab,
|0x0009|.

The app can therefore assume that none of these problematic characters occur
in raw form in the argument to |pasteCode|.

=
void PasteButtons::put_code_char(OUTPUT_STREAM, inchar32_t c) {
	switch(c) {
		case '\t': WRITE("[=0x0009=]"); return;
		case '\n': case NEWLINE_IN_STRING: WRITE("[=0x000A=]"); return;
		case '"': WRITE("[=0x0022=]"); return;
		case '&': WRITE("[=0x0026=]"); return;
		case '\'': WRITE("[=0x0027=]"); return;
		case '<': WRITE("[=0x003C=]"); return;
		case '>': WRITE("[=0x003E=]"); return;
		case '\\': WRITE("[=0x005C=]"); return;
		default: PUT(c); return;
	}
}

@h Buttons.
The button is simply an image with a link using the |javascript:| protocol
to call a suitable function.

=
void PasteButtons::paste_W(OUTPUT_STREAM, wording W) {
	PasteButtons::paste_inner(OUT, Wordings::first_wn(W), Wordings::last_wn(W), NULL, NULL);
}
void PasteButtons::paste_text(OUTPUT_STREAM, text_stream *alt_stream) {
	PasteButtons::paste_inner(OUT, -1, -1, alt_stream, NULL);
}
void PasteButtons::paste_text_using(OUTPUT_STREAM, text_stream *alt_stream,
	text_stream *paste_icon) {
	PasteButtons::paste_inner(OUT, -1, -1, alt_stream, paste_icon);
}
void PasteButtons::paste_inner(OUTPUT_STREAM, int from, int to, text_stream *alt_stream,
	text_stream *paste_icon) {
	TEMPORARY_TEXT(link)
	WRITE_TO(link, "class=\"pastelink\" href=\"javascript:pasteCode(");
	PasteButtons::argument(link, from, to, alt_stream);
	WRITE_TO(link, ")\"");
	HTML_OPEN_WITH("a", "%S", link);
	DISCARD_TEXT(link)
	if (Str::len(paste_icon) == 0) {
		HTML_TAG_WITH("img", "border=0 src=inform:/doc_images/paste.png");
	} else {
		WRITE("%S", paste_icon);
	}
	HTML_CLOSE("a");
}

@ This is a new-look paste button, using a "command-V" ideograph rather than
a somewhat enigmatic icon.

=
void PasteButtons::paste_text_new_style(OUTPUT_STREAM, text_stream *matter) {
	TEMPORARY_TEXT(paste)
	PasteButtons::paste_ideograph(paste);
	PasteButtons::paste_text_using(OUT, matter, paste);
	DISCARD_TEXT(paste)
	WRITE("&nbsp;");
}
void PasteButtons::paste_ideograph(OUTPUT_STREAM) {
	/* the Unicode for "place of interest", the Swedish castle which became the Apple action symbol */
	WRITE("<span class=\"paste\">%cV</span>", 0x2318);
}

@ In the following, the source of the text can be either a range of words
from the lexer (as for instance when a portion of an extension is being
typeset as documentation, with an example that can be pasted), or can
be a C string: if the latter, then its encoding must be ISO Latin-1.
The conversion to UTF-8 is performed in |PasteButtons::put_code_char| below.

=
void PasteButtons::argument(OUTPUT_STREAM, int from, int to, text_stream *alt_stream) {
	WRITE("'");
	if (alt_stream)
		LOOP_THROUGH_TEXT(pos, alt_stream)
			PasteButtons::put_code_char(OUT, Str::get(pos));
	if (from >= 0) @<Write word range as Javascript string@>;
	WRITE("'");
}

@ Writing a word range is much harder. In effect, we have to provide an
inverse function for the lexer, which converted raw source text to nicely
packaged up words.

See Lexer for details of how words are stored, and in particular for the
|lw_break| character, which is |'\t'| when the word followed a tab, but is
|'1'| to |'9'| when it followed a newline plus that many tabs. We need
this because lexing has otherwise removed whitespace from the source, and
we need it back again if we're to paste a faithful Javascript representation:
otherwise the tabs used as column-dividers in tables will not come through,
for instance. Moreover, indentation from the left margin is used to make
prettier pastes (which respect the layout of the original examples from
which the paste has been made), and for that we need the |'1'| to |'9'|
possibilities.

Note that we expect the material pasted to be indented at 1 tab stop from
the margin already, because it will almost always be a source text within
an example, where any matter unindented will be commentary rather than
source text. Thus a single tab after a newline is not significant, and we
only need to supply extra Javascript tabs when the indentation is 2 tab
stops or more.

@<Write word range as Javascript string@> =
	int i, suppress_space = FALSE, follows_paragraph_break = FALSE;
	int close_I6_position = -1;
	for (i=from; i<=to; i++) {
		int j;
		inchar32_t *p = Lexer::word_raw_text(i);
		if (Lexer::word(i) == PARBREAK_V) { /* marker for a paragraph break */
			PasteButtons::put_code_char(OUT, '\n');
			PasteButtons::put_code_char(OUT, '\n');
			suppress_space = TRUE;
			follows_paragraph_break = TRUE;
			while (Lexer::word(i) == PARBREAK_V) i++; i--; /* elide multiple breaks */
			continue;
		}
		int indentation = Lexer::indentation_level(i);
		if (indentation > 0) { /* number of tab stops of indentation on this para */
			PasteButtons::put_code_char(OUT, '\n');
			for (j=0; j<indentation-1; j++) PasteButtons::put_code_char(OUT, '\t');
			suppress_space = TRUE;
		}
		if ((Lexer::break_before(i) == '\t') && (follows_paragraph_break == FALSE)) {
			PasteButtons::put_code_char(OUT, '\t');
			suppress_space = TRUE;
		}
		follows_paragraph_break = FALSE;
		if (suppress_space==FALSE)
			@<Restore inter-word spaces unless this would be unnatural@>;
		suppress_space = FALSE;
		for (j=0; p[j]; j++) PasteButtons::put_code_char(OUT, p[j]);
		@<Insert a close-literal-I6 escape sequence if necessary@>;
	}
	PasteButtons::put_code_char(OUT, '\n');
	PasteButtons::put_code_char(OUT, '\n');

@ The lexer also broke words around punctuation marks, so that, for instance,
"fish, finger" would have been lexed as |fish , finger| -- three words.
But we want to restore the more natural spacing.

@<Restore inter-word spaces unless this would be unnatural@> =
	if ((i>from)
		&& ((p[1] != 0) || (Lexer::is_punctuation(p[0]) == FALSE) ||
			(p[0] == '(') || (p[0] == '{') || (p[0] == '}'))
		&& (compare_word(i-1, OPENBRACKET_V)==FALSE))
		PasteButtons::put_code_char(OUT, ' ');

@ Finally, the lexer rendered a literal I6 inclusion in the form |(- self=2;|
as a sequence of two lexical words: |(-| and then |self=2;|. In order
to paste back safely, we must supplement this with the closure |-)| once
again:

@<Insert a close-literal-I6 escape sequence if necessary@> =
	if (Lexer::word(i) == OPENI6_V) close_I6_position = i+1;
	if (close_I6_position == i) {
		PasteButtons::put_code_char(OUT, '-');
		PasteButtons::put_code_char(OUT, ')');
		PasteButtons::put_code_char(OUT, ' ');
	}

@h File-opener buttons.
Nothing to do with pastes: this is a completely different sort of button,
though also powered by Javascript. It opens a file or folder on the host
filing system.

=
void PasteButtons::open_file(OUTPUT_STREAM, pathname *P, text_stream *leaf, char *contents) {
	TEMPORARY_TEXT(fn)
	if (leaf) WRITE_TO(fn, "%f", Filenames::in(P, leaf));
	else WRITE_TO(fn, "%p", P);

	#ifdef PLATFORM_WINDOWS
	LOOP_THROUGH_TEXT(pos, fn) if (Str::get(pos) == '\\') Str::put(pos, '/');
	#endif

	HTML_OPEN_WITH("a", "href='javascript:project().openFile(\"%S\")'", fn);
	HTML_TAG_WITH("img", "%s", contents);
	HTML_CLOSE("a");
	DISCARD_TEXT(fn)
}
