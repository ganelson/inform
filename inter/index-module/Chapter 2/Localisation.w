[Localisation::] Localisation.

Utility functions for standing text which may vary by language.

@ Localisation here means storing fixed wordings of text so that they can
produced in multiple languages. At present this is used only for the index,
but it could conceivably have other uses, so we won't assume that.

The idea here is that the user of these functions creates a "localisation
dictionary" by calling |Localisation::new|, and then stocks this from one
or more text files. In general, it's best to stock first with the English
language default, and then stock second with the target language: this
is because the English version is complete, in that it supplies text for
every need, whereas the Hungarian translation (say) may not be. The net
result is that English will be used for any texts where no translation
is available.

It would be elegant to handle this using |inform_language| objects, but
those exist only in the //supervisor// module, which is a part of //inform7//
but not of //inter//: and this indexing module has to work in both.

For now, a |localisation_dictionary| object is just a wrapper for a simple
|dictionary| of key-value pairs, but it may become more elaborate later.

=
typedef struct localisation_dictionary {
	struct dictionary *texts;
	CLASS_DEFINITION
} localisation_dictionary;

localisation_dictionary *Localisation::new(void) {
	localisation_dictionary *D = CREATE(localisation_dictionary);
	D->texts = Dictionaries::new(256, TRUE);
	return D;
}

@ We think of the dictionary as structured into a hierarchy: for example,
a typical entry might be |Index.Pages.Kinds.Caption|. At present, we do not
take advantage of this to make a more efficient search (one could imagine
a tree structure of dictionaries): we just use these path-like identifiers
as keys to a single dictionary. If we ever need really large localisatiom
dictionaries, we might revisit this.

=
text_stream *Localisation::read(localisation_dictionary *D, text_stream *key) {
	return Dictionaries::get_text(D->texts, key);
}

void Localisation::define(localisation_dictionary *D,
	text_stream *key, text_stream *value) {
	text_stream *to = Dictionaries::create_text(D->texts, key);
	WRITE_TO(to, "%S", value);
}

@ As noted above, the user is more likely to stock a dictionary by calling the
following to read it in from a UTF-8-encoded Unicode text file. Lines are assumed
to be terminated with either |0x0a| or |0x0d|.

The format is simple:
(*) If the first non-whitespace character on a line is a |#|, then the line is
a comment and is ignored.
(*) If the first non-whitespace character on a line is a |%|, then the line is
expected to take the form |%KEY = ...|, where |...| is the text value for this
key. This text continues on what may be multiple lines until the next key;
and any white space at the start or end is ignored.

So, for example:
= (text)
# This is a comment line
	%Index.Elements.Cm.Title = Commands
	%Index.Elements.Cm.Heading =
		Commands which the player can type
=

And the following function reads such a file into an existing dictionary. Note
that it can be used to read several files in turn into the same dictionary;
if later files define the same keys as earlier ones, their new texts override
the earlier ones.

=
int Localisation::stock_from_file(filename *localisation_file, localisation_dictionary *D) {
	FILE *Input_File = Filenames::fopen(localisation_file, "r");
	if (Input_File == NULL) {
		LOG("Failed to load localisation file at: %f\n", localisation_file);
		return FALSE;
	}
	int col = 1, line = 1, nwsol = FALSE; /* "non white space on line" */
	unicode_file_buffer ufb = TextFiles::create_ufb();
	wchar_t cr;
	TEMPORARY_TEXT(key)
	TEMPORARY_TEXT(value)
	do {
		@<Read next character@>;
		if (cr == EOF) break;
		if ((cr == '#') && (nwsol == FALSE)) @<Read up to end of line as a comment@>
		else if ((cr == '%') && (nwsol == FALSE)) @<Read up to the next white space as a key@>
		else if (Characters::is_whitespace(cr) == FALSE) nwsol = TRUE;
		if (cr == EOF) break;
		if (Str::len(key) > 0) {
			if ((Characters::is_whitespace(cr) == FALSE) || (Str::len(value) > 0))
				PUT_TO(value, cr);
		} else {
			if (Characters::is_whitespace(cr) == FALSE) {
				Localisation::error(localisation_file, line, col,
					I"extraneous matter appears before first %key");
			}
		}
	} while (cr != EOF);
	if (Str::len(key) > 0) @<Write key-value pair@>;
	DISCARD_TEXT(key)
	DISCARD_TEXT(value)
	fclose(Input_File);
	return TRUE;
}

@<Read next character@> =
	cr = TextFiles::utf8_fgetc(Input_File, NULL, FALSE, &ufb);
	col++;
	if ((cr == 10) || (cr == 13)) { col = 0; nwsol = FALSE; line++; }

@<Read up to the next white space as a key@> =
	if (Str::len(key) > 0) @<Write key-value pair@>;
	Str::clear(key);
	Str::clear(value);
	while (TRUE) {
		@<Read next character@>;
		if ((cr == '=') || (cr == EOF)) break;
		if (Characters::is_whitespace(cr) == FALSE) PUT_TO(key, cr);
	}
	if (cr == '=') {
		while (TRUE) {
			@<Read next character@>;
			if (Characters::is_whitespace(cr)) continue;
			break;
		}
	}		
	
@<Read up to end of line as a comment@> =
	while (col != 0) @<Read next character@>;

@<Write key-value pair@> =
	Str::trim_white_space(value);
	Str::trim_all_white_space_at_end(value);
	if (Str::len(value) == 0) {
		TEMPORARY_TEXT(err)
		WRITE_TO(err, "key '%%%S' has no text", key);
		Localisation::error(localisation_file, line, col, err);
		DISCARD_TEXT(err)
	} else {
		Localisation::define(D, key, value);
	}

@ The function above is very forgiving, in that it never throws syntax errors.
None of this is intended for Inform's end users to play with. Still, translators
working on localisation files can see any defects by looking at the debugging log:

=
void Localisation::error(filename *F, int line, int col, text_stream *err) {
	LOG("Localisation file error: %f, line %d:%d: %S\n",
		F, line, col, err);
}

@

=
void Localisation::write_0(OUTPUT_STREAM, localisation_dictionary *D, text_stream *key) {
	text_stream *vals[10];
	@<Vacate the vals@>;
	Localisation::write_general(OUT, D, key, vals);
}

void Localisation::write_1(OUTPUT_STREAM, localisation_dictionary *D, text_stream *key,
	text_stream *val1) {
	text_stream *vals[10];
	@<Vacate the vals@>;
	vals[1] = val1;
	Localisation::write_general(OUT, D, key, vals);
}

void Localisation::write_2(OUTPUT_STREAM, localisation_dictionary *D, text_stream *key,
	text_stream *val1, text_stream *val2) {
	text_stream *vals[10];
	@<Vacate the vals@>;
	vals[1] = val1; vals[2] = val2;
	Localisation::write_general(OUT, D, key, vals);
}

@<Vacate the vals@> =
	for (int i=0; i<10; i++) vals[i] = NULL;

@

=
void Localisation::write_general(OUTPUT_STREAM, localisation_dictionary *D,
	text_stream *key, text_stream **vals) {
	text_stream *prototype = Localisation::read(D, key);
	for (int i=0; i<Str::len(prototype); i++) {
		wchar_t c = Str::get_at(prototype, i);
		if (c == '*') {
			wchar_t nc = Str::get_at(prototype, i+1);
			int n = ((int) nc - (int) '0');
			if ((n >= 0) && (n <= 9)) WRITE("%S", vals[n]);
			else PUT(nc);
			i++;
		} else {
			PUT(c);
		}
	}
}
