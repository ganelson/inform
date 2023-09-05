[Placeholders::] Placeholders.

To manage placeholder variables.

@h Placeholders.
Placeholders are markers such as "[AUTHOR]", found in the template
files for making web pages. ("AUTHOR" would be the name of this one; the use
of capital letters is customary but not required.) Most of these can be set
to arbitrary texts by use of the |placeholder| command in the blurb file, but
a few are "reserved":

@d SOURCE_RPL 1
@d SOURCENOTES_RPL 2
@d SOURCELINKS_RPL 3
@d COVER_RPL 4
@d DOWNLOAD_RPL 5
@d AUXILIARY_RPL 6
@d PAGENUMBER_RPL 7
@d PAGEEXTENT_RPL 8

=
typedef struct placeholder {
	struct text_stream *pl_name; /* such as "[AUTHOR]" */
	struct text_stream *pl_contents; /* current value */
	int reservation; /* one of the |*_RPL| values above, or 0 for unreserved */
	int locked; /* currently being expanded: locked to prevent mise-en-abyme */
	CLASS_DEFINITION
} placeholder;

@h Initial values.
The |BLURB| refers here to back-cover-style text, and not to the "blurb"
file which we are acting on.

=
void Placeholders::initialise(void) {
	Placeholders::set_to(I"SOURCE", I"", SOURCE_RPL);
	Placeholders::set_to(I"SOURCENOTES", I"", SOURCENOTES_RPL);
	Placeholders::set_to(I"SOURCELINKS", I"", SOURCELINKS_RPL);
	Placeholders::set_to(I"COVER", I"", COVER_RPL);
	Placeholders::set_to(I"DOWNLOAD", I"", DOWNLOAD_RPL);
	Placeholders::set_to(I"AUXILIARY", I"", AUXILIARY_RPL);
	Placeholders::set_to(I"PAGENUMBER", I"", PAGENUMBER_RPL);
	Placeholders::set_to(I"PAGEEXTENT", I"", PAGEEXTENT_RPL);
	Placeholders::set_to(I"CBLORBERRORS", I"", 0);
	Placeholders::set_to(I"INBROWSERPLAY", I"", 0);
	Placeholders::set_to(I"INTERPRETERSCRIPTS", I"", 0);
	Placeholders::set_to(I"OTHERCREDITS", I"", 0);
	Placeholders::set_to(I"BLURB", I"", 0);
	Placeholders::set_to(I"TEMPLATE", I"Standard", 0);
	text_stream *V = Str::new();
	WRITE_TO(V, "inblorb [[Version Number]]");
	Placeholders::set_to(I"GENERATOR", V, 0);
	Placeholders::set_to(I"BASE64_TOP", I"", 0);
	Placeholders::set_to(I"BASE64_TAIL", I"", 0);
	Placeholders::set_to(I"JAVASCRIPTPRELUDE", Str::literal(JAVASCRIPT_PRELUDE), 0);
	Placeholders::set_to(I"FONTTAG", Str::literal(FONT_TAG), 0);
	Placeholders::set_to(I"MATERIALSFOLDERPATHOPEN", I"", 0);
	Placeholders::set_to(I"MATERIALSFOLDERPATHFILE", I"", 0);
	Placeholders::set_to(I"BLURB", I"", 0);

	Main::initialise_time_variables();
}

@ We don't need any very efficient system for parsing these names, as there
are typically fewer than 20 placeholders at a time.

=
placeholder *Placeholders::find(text_stream *name) {
	placeholder *wv;
	LOOP_OVER(wv, placeholder)
		if (Str::eq(wv->pl_name, name))
			return wv;
	return NULL;
}

text_stream *Placeholders::read(text_stream *name) {
	placeholder *wv = Placeholders::find(name);
	if (wv) return wv->pl_contents;
	return NULL;
}

@ There are no "types" of these placeholders. When they hold numbers, it's only
as the text of a number written out in decimal, so:

=
void Placeholders::set_to_number(text_stream *var, int v) {
	TEMPORARY_TEXT(temp_digits)
	WRITE_TO(temp_digits, "%d", v);
	Placeholders::set_to(var, temp_digits, 0);
	DISCARD_TEXT(temp_digits)
}

@ And here we set a given placeholder to a given text value. If it doesn't
already exist, it will be created. A reserved placeholder can then never again
be set, and since it will have been set at creation time (above), it follows
that a reserved placeholder cannot be set with the |placeholder| command of a
blurb file.

=
void Placeholders::set_to(text_stream *var, text_stream *text, int reservation) {
	Placeholders::set_to_inner(var, text, reservation, FALSE);
}
void Placeholders::append_to(text_stream *var, text_stream *text) {
	Placeholders::set_to_inner(var, text, 0, TRUE);
}

@ Where:

=
void Placeholders::set_to_inner(text_stream *var, text_stream *text, int reservation, int extend) {
	if (verbose_mode) PRINT("! [%S] <-- \"%S\"\n", var, text);

	placeholder *wv = Placeholders::find(var);
	if ((wv) && (reservation > 0)) { BlorbErrors::error_1S("tried to set reserved variable %S", var); return; }
	if (wv == NULL) {
		wv = CREATE(placeholder);
		if (verbose_mode) PRINT("! Creating [%S]\n", var);
		wv->pl_name = Str::duplicate(var);
		wv->pl_contents = Str::new();
		wv->reservation = reservation;
	}

	if (extend) Str::concatenate(wv->pl_contents, text);
	else Str::copy(wv->pl_contents, text);
}

@ And that just leaves writing the output of these placeholders. The scenario
here is that we're copying HTML over to make a new web page, but we've hit
text in the template like "[AUTHOR]". We output the value of this
placeholder instead of that literal text. The reserved placeholders output as
special gadgets instead of any fixed text, so those all call suitable
routines elsewhere in Inblorb.

If the placeholder name isn't known to us, we print the text back, so that the
original material will be unchanged. (This is in case the original contains
uses of square brackets which aren't for placeholding.)

=
int escape_quotes_mode = 0;
void Placeholders::write(OUTPUT_STREAM, text_stream *var) {
	int multiparagraph_mode = FALSE, eqm = escape_quotes_mode;
	if (Str::get_first_char(var) == '*') { Str::delete_first_character(var); escape_quotes_mode = 1; }
	if (Str::get_first_char(var) == '*') { Str::delete_first_character(var); escape_quotes_mode = 2; }
	if (Str::eq(var, I"BLURB")) multiparagraph_mode = TRUE;
	placeholder *wv = Placeholders::find(var);
	if ((wv == NULL) || (wv->locked)) {
		WRITE("[%S]", var);
	} else {
		wv->locked = TRUE;
		if (multiparagraph_mode) WRITE("<p>");
		switch (wv->reservation) {
			case 0: @<Copy an ordinary unreserved placeholder@>; break;
			case SOURCE_RPL: Websites::expand_SOURCE_or_SOURCENOTES_variable(OUT, FALSE); break;
			case SOURCENOTES_RPL: Websites::expand_SOURCE_or_SOURCENOTES_variable(OUT, TRUE); break;
			case SOURCELINKS_RPL: Websites::expand_SOURCELINKS_variable(OUT); break;
			case COVER_RPL: Links::expand_COVER_variable(OUT); break;
			case DOWNLOAD_RPL: Links::expand_DOWNLOAD_variable(OUT); break;
			case AUXILIARY_RPL: Links::expand_AUXILIARY_variable(OUT); break;
			case PAGENUMBER_RPL: Websites::expand_PAGENUMBER_variable(OUT); break;
			case PAGEEXTENT_RPL: Websites::expand_PAGEEXTENT_variable(OUT); break;
		}
		if (multiparagraph_mode) WRITE("</p>");
		wv->locked = FALSE;
		escape_quotes_mode = eqm;
	}
}

@ Note that the [BLURB] placeholder -- which holds the story description, and is
like a back cover blurb for a book; the name is not related to the release
instructions format -- may consist of multiple paragraphs. If so, then they
will be divided by |<br/>|, since that's the XML convention. But we want to
translate those breaks to |</p><p>|, closing an old paragraph and opening
a new one, because that will make the blurb text much easier to style
with a CSS file. It follows that [BLURB] should always appear in templates
within an HTML paragraph.

@<Copy an ordinary unreserved placeholder@> =
	int L = Str::len(wv->pl_contents);
	for (int i=0; i<L; i++) {
		inchar32_t c = Str::get_at(wv->pl_contents, i);
		if ((c == '<') &&
			(Str::get_at(wv->pl_contents, i+1) == 'b') &&
			(Str::get_at(wv->pl_contents, i+2) == 'r') &&
			(Str::get_at(wv->pl_contents, i+3) == '/') &&
			(Str::get_at(wv->pl_contents, i+4) == '>') && (multiparagraph_mode)) {
			WRITE("</p><p>"); i += 4; continue;
		}
		if (c == '[') {
			TEMPORARY_TEXT(inner_name)
			int expanded = FALSE;
			for (int j = i+1; j<L; j++) {
				inchar32_t c = Str::get_at(wv->pl_contents, j);
				if ((c == '[') || (c == ' ')) break;
				if (c == ']') {
					i = j;
					Placeholders::write(OUT, inner_name);
					expanded = TRUE;
					break;
				}
				PUT_TO(inner_name, c);
			}
			DISCARD_TEXT(inner_name)
			if (expanded) continue;
		}
		if (((c == '\x0a') || (c == '\x0d') || (c == '\x7f')) && (multiparagraph_mode)) {
			WRITE("<p>"); continue;
		}
		if ((escape_quotes_mode == 1) && (c == '\'')) WRITE("&#39;");
		else if ((escape_quotes_mode == 2) && (c == '\'')) WRITE("%%2527");
		else WRITE("%c", c);
	}
