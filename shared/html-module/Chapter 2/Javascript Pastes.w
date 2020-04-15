[HTML::Javascript::] Javascript Pastes.

To write valid HTML for a paste icon which, when clicked, calls
a Javascript function which will paste Inform source text into the Source
panel of the application.

@h Definitions.

@ The application is required to provide a Javascript function to copy text
into the source window. Broadly speaking, the application needs to support
Javascript in the following form:
= (text)
	var myProject = external.Project;
	myProject.selectView('source');
	myProject.pasteCode('Trying Taking Manhattan');
=
This for Windows: for OS X, the same code but |window.Project| rather
than |external.Project|.

As this implies, the details unfortunately differ on different platforms:
(a) Model 1 - paste in OS X style, directly within the HREF of a link.
(b) Model 2 - paste in Windows style, defining a function and calling that.

In model 2 we define a Javascript function for each individual paste
because this protects against long paste texts overflowing what Windows
considers the maximum permitted length of a link: the WebKit rendering
engine in OS X has no such limit, apparently. This means that for Windows
we define numerous copies of the Javascript code above. In model 1, we
never need to compile fresh Javascript functions because the template file
|ExtensionFileModel.html| for OS X contains a definition of the single
Javascript function:
= (text)
	<script language="JavaScript">
	function pasteCode(code) {
		var myProject = project();
		myProject.selectView('source');
		myProject.pasteCode(code);
	}
	</script>
=
and we can simply call |href="javascript:pasteCode(...)"| from any link.

The text pasted may in some cases be quite long (say, 5K or more) and the
code below should work whatever its length. It will of course be UTF-8 encoded,
since all HTML produced by Inform is.

@ We have found that different Javascript implementations handle escape
characters in quoted text differently. (For instance, some allow a
double-quote |"| to appear as a literal in single-quoted text, others
require |&quot;| to be used, others still do not recognise HTML entities
like |&quot;| and treat them as literal text.) To avoid these tiresome
platform dependencies a single new escape-character syntax was added in
November 2007. This puts obligations both on Inform (and |indoc|, which also
generates HTML with Javascript pastes), to make use of the escape syntax,
and also on the application, to understand and act on it.

The application must implement |myProject.pasteCode(code)| such that every
instance of |[=0xHHHH=]| is replaced with the Unicode character whose
hexadecimal code is |HHHH|. There will always be four digits, with leading
zeros as needed, and |A| to |F| will be written in upper case. The only
Unicode characters with codes below |0x0020| which must be handled are
newline, |0x000A|, and tab, |0x0009|.

The generator (Inform or |indoc|) must always escape every instance of the
following characters:

(a) every tab is escaped to |[=0x0009=]|;
(b) every newline is escaped to |[=0x000A=]|;
(c) every double quotation mark is escaped to |[=0x0022=]|;
(d) every ampersand is escaped to |[=0x0026=]|;
(e) every single quotation mark is escaped to |[=0x0027=]|;
(f) every less than sign is escaped to |[=0x003C=]|;
(g) every greater than sign is escaped to |[=0x003E=]|;
(h) every backslash is escaped to |[=0x005C=]|.

It may also choose to escape other character codes, as it prefers. Other
characters are generated as literal UTF-8. In no case will any character
with code below |0x0020| be passed as a literal.

@ At the top level, the form of link used depends on the Javascript model.
Note that model 0 results in no material at all being output. The actual
text to be passed is all set via |HTML::Javascript::javascript_string_out| below, and which
does not depend on the model.

=
int javascript_fn_counter = 1000;
void HTML::Javascript::paste_W(OUTPUT_STREAM, wording W) {
	HTML::Javascript::paste_inner(OUT, Wordings::first_wn(W), Wordings::last_wn(W), NULL);
}
void HTML::Javascript::paste_stream(OUTPUT_STREAM, text_stream *alt_stream) {
	HTML::Javascript::paste_inner(OUT, -1, -1, alt_stream);
}
void HTML::Javascript::paste_inner(OUTPUT_STREAM, int from, int to, text_stream *alt_stream) {
	#ifndef WINDOWS_JAVASCRIPT /* OS X style, with long function arguments allowed in links */
		TEMPORARY_TEXT(link);
		WRITE_TO(link, "href=\"javascript:pasteCode(");
		HTML::Javascript::javascript_string_out(link, from, to, alt_stream);
		WRITE_TO(link, ")\"");
		HTML_OPEN_WITH("a", "%S", link);
		DISCARD_TEXT(link);
		HTML_TAG_WITH("img", "border=0 src=inform:/doc_images/paste.png");
		HTML_CLOSE("a");
	#endif

	#ifdef WINDOWS_JAVASCRIPT /* Windows style, with long function arguments in links unreliable */
		WRITE("<script language=\"JavaScript\">\n");
		WRITE("function pasteCode%d(code) {\n", javascript_fn_counter); INDENT;
		WRITE("var myProject = project();\n\n");
		WRITE("myProject.selectView('source');\n");
		WRITE("myProject.pasteCode(");
		OUTDENT; HTML::Javascript::javascript_string_out(OUT, from, to, alt_stream);
		WRITE(");\n");
		WRITE("}\n");
		WRITE("</script>\n");
		HTML_OPEN_WITH("a", "href=\"javascript:pasteCode%d()\"", javascript_fn_counter++);
		HTML_TAG_WITH("img", "border=0 src=inform:/doc_images/paste.png");
		HTML_CLOSE("a");
	#endif
}

@ Though the Javascript function is called |openFile|, it can equally well
compile a link to open a folder on the host filing system.

=
void HTML::Javascript::open_file(OUTPUT_STREAM, pathname *P, text_stream *leaf, char *contents) {
	TEMPORARY_TEXT(fn);
	if (leaf) WRITE_TO(fn, "%f", Filenames::in(P, leaf));
	else WRITE_TO(fn, "%p", P);

	#ifdef WINDOWS_JAVASCRIPT
	LOOP_THROUGH_TEXT(pos, fn) if (Str::get(pos) == '\\') Str::put(pos, '/');
	#endif

	HTML_OPEN_WITH("a", "href='javascript:project().openFile(\"%S\")'", fn);
	HTML_TAG_WITH("img", "%s", contents);
	HTML_CLOSE("a");
	DISCARD_TEXT(fn);
}

@ In the following, the source of the text can be either a range of words
from the lexer (as for instance when a portion of an extension is being
typeset as documentation, with an example that can be pasted), or can
be a C string: if the latter, then its encoding must be ISO Latin-1.
The conversion to UTF-8 is performed in |HTML::Javascript::javascript_char_out| below.

=
void HTML::Javascript::javascript_string_out(OUTPUT_STREAM, int from, int to, text_stream *alt_stream) {
	WRITE("'");
	if (alt_stream) @<Write stream as Javascript string@>;
	if (from >= 0) @<Write word range as Javascript string@>;
	WRITE("'");
}

@ The art of leadership is delegation.

@<Write stream as Javascript string@> =
	LOOP_THROUGH_TEXT(pos, alt_stream)
		HTML::Javascript::javascript_char_out(OUT, Str::get(pos));

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
		wchar_t *p = Lexer::word_raw_text(i);
		if (Lexer::word(i) == PARBREAK_V) { /* marker for a paragraph break */
			HTML::Javascript::javascript_char_out(OUT, '\n');
			HTML::Javascript::javascript_char_out(OUT, '\n');
			suppress_space = TRUE;
			follows_paragraph_break = TRUE;
			while (Lexer::word(i) == PARBREAK_V) i++; i--; /* elide multiple breaks */
			continue;
		}
		int indentation = Lexer::indentation_level(i);
		if (indentation > 0) { /* number of tab stops of indentation on this para */
			HTML::Javascript::javascript_char_out(OUT, '\n');
			for (j=0; j<indentation-1; j++) HTML::Javascript::javascript_char_out(OUT, '\t');
			suppress_space = TRUE;
		}
		if ((Lexer::break_before(i) == '\t') && (follows_paragraph_break == FALSE)) {
			HTML::Javascript::javascript_char_out(OUT, '\t');
			suppress_space = TRUE;
		}
		follows_paragraph_break = FALSE;
		if (suppress_space==FALSE)
			@<Restore inter-word spaces unless this would be unnatural@>;
		suppress_space = FALSE;
		for (j=0; p[j]; j++) HTML::Javascript::javascript_char_out(OUT, p[j]);
		@<Insert a close-literal-I6 escape sequence if necessary@>;
	}
	HTML::Javascript::javascript_char_out(OUT, '\n');
	HTML::Javascript::javascript_char_out(OUT, '\n');

@ The lexer also broke words around punctuation marks, so that, for instance,
"fish, finger" would have been lexed as |fish , finger| -- three words.
But we want to restore the more natural spacing.

@<Restore inter-word spaces unless this would be unnatural@> =
	if ((i>from)
		&& ((p[1] != 0) || (Lexer::is_punctuation(p[0]) == FALSE) ||
			(p[0] == '(') || (p[0] == '{') || (p[0] == '}'))
		&& (compare_word(i-1, OPENBRACKET_V)==FALSE))
		HTML::Javascript::javascript_char_out(OUT, ' ');

@ Finally, the lexer rendered a literal I6 inclusion in the form

>> (- self=2; -)

as a sequence of two lexical words: |(-| and then |self=2;|. In order
to paste back safely, we must supplement this with the closure "-)" once
again:

@<Insert a close-literal-I6 escape sequence if necessary@> =
	if (Lexer::word(i) == OPENI6_V) close_I6_position = i+1;
	if (close_I6_position == i) {
		HTML::Javascript::javascript_char_out(OUT, '-');
		HTML::Javascript::javascript_char_out(OUT, ')');
		HTML::Javascript::javascript_char_out(OUT, ' ');
	}

@h Individual characters.
Note that every character within the single quotes of a Javascript string
is produced through the following routine. It escapes certain awkward
characters, but need not convert from ISO Latin-1 to UTF-8 since that will
happen automatically downstream of us when the output is written as a
UTF-8 encoded HTML file.

=
void HTML::Javascript::javascript_char_out(OUTPUT_STREAM, int c) {
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
