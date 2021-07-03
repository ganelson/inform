[Localisation::] Localisation.

Utility functions for standing text which may vary by language.

@ 

=
typedef struct localisation_dictionary {
	struct dictionary *texts;
	CLASS_DEFINITION
} localisation_dictionary;

localisation_dictionary *Localisation::new(void) {
	localisation_dictionary *D = CREATE(localisation_dictionary);
	D->texts = Dictionaries::new(32, TRUE);
	return D;
}

text_stream *Localisation::read(localisation_dictionary *D, text_stream *context, text_stream *key) {
	TEMPORARY_TEXT(true_key)
	WRITE_TO(true_key, "%S-%S", context, key);
	text_stream *text = Dictionaries::get_text(D->texts, true_key);
	DISCARD_TEXT(true_key)
	return text;
}

@ Here we read a localisation file for text used in the Index elements, and write
this into a given dictionary of key-value pairs.

=
void Localisation::stock_from_file(filename *localisation_file, localisation_dictionary *D) {
	FILE *Input_File = Filenames::fopen(localisation_file, "r");
	if (Input_File == NULL) {
		LOG("Filename was %f\n", localisation_file);
		internal_error("unable to open localisation file for the index");
	}
	int col = 1, cr;

	TEMPORARY_TEXT(super_key)
	TEMPORARY_TEXT(key)
	TEMPORARY_TEXT(value)
	do {
		@<Read next character from localisation stream@>;
		if (cr == EOF) break;
		if (cr == '%') @<Read up to the next white space as a key@>;
		if (cr == EOF) break;
		if (Str::len(key) > 0) PUT_TO(value, cr);
	} while (cr != EOF);
	if (Str::len(key) > 0) @<Write key-value pair@>;
	DISCARD_TEXT(super_key)
	DISCARD_TEXT(key)
	DISCARD_TEXT(value)
	fclose(Input_File);
}

@ Localisation files are encoded as ISO Latin-1, not as Unicode UTF-8, so
ordinary |fgetc| is used, and no BOM marker is parsed. Lines are assumed
to be terminated with either |0x0a| or |0x0d|. (Since blank lines are
harmless, we take no trouble over |0a0d| or |0d0a| combinations.)

@<Read next character from localisation stream@> =
	if (Input_File) cr = fgetc(Input_File);
	else cr = EOF;
	col++; if ((cr == 10) || (cr == 13)) col = 0;

@<Read up to the next white space as a key@> =
	if (Str::len(key) > 0) @<Write key-value pair@>;
	Str::clear(key);
	Str::clear(value);
	int double_mode = FALSE;
	while (TRUE) {
		@<Read next character from localisation stream@>;
		if ((cr == '%') && (Str::len(key) == 0)) { double_mode = TRUE; continue; }
		if ((cr == '=') || (cr == EOF)) break;
		if (Characters::is_whitespace(cr)) {
			if (double_mode) break;
			continue;
		}
		PUT_TO(key, cr);
	}
	if (double_mode) {
		Str::clear(super_key);
		WRITE_TO(super_key, "%S", key);
		Str::clear(key);
	} else if (cr == '=') {
		while (TRUE) {
			@<Read next character from localisation stream@>;
			if (Characters::is_whitespace(cr)) continue;
			break;
		}
	}		

@<Write key-value pair@> =
	TEMPORARY_TEXT(true_key)
	WRITE_TO(true_key, "%S-%S", super_key, key);
	text_stream *to = Dictionaries::create_text(D->texts, true_key);
	Str::trim_white_space(value);
	Str::trim_all_white_space_at_end(value);
	WRITE_TO(to, "%S", value);
	DISCARD_TEXT(true_key)
