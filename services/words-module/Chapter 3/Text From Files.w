[TextFromFiles::] Text From Files.

This is where source text is read in, whether from extension files
or from the main source text file, and fed into the lexer.

@h Source files.
Each separate file of text read into the lexer has its identity docketed
in a |source_file| structure, as follows.

=
typedef struct source_file {
	struct filename *name;
	int words_of_source; /* word count, omitting comments and verbatim matter */
	struct wording text_read;
	int words_of_quoted_text; /* word count for text in double-quotes */
	FILE *handle; /* file handle while open */
	general_pointer your_ref; /* for the client to attach some meaning */
	CLASS_DEFINITION
} source_file;

@h Feeding whole files into the lexer.
This is one of the two feeder routines for the lexer, the other being in
Lexical Writing Back.w: see Lexer.w for its obligations.

We feed characters from an open file into the lexer, and continue until there
is nothing left in it. Inform is used on operating systems which between them
use all four of the sequences |0a|, |0d|, |0a0d| and |0d0a| to divide lines in
text files, so each of these is converted to a single |'\n'|. Tabs are treated
as if spaces in most contexts, but not when parsing formatted tables, for
instance, so they are not similarly converted.

=
source_file *TextFromFiles::feed_open_file_into_lexer(filename *F, FILE *handle,
	text_stream *leaf, int documentation_only, general_pointer ref, int mode) {
	source_file *sf = CREATE(source_file);
	sf->words_of_source = 0;
	sf->words_of_quoted_text = 0;
	sf->your_ref = ref;
	sf->name = F;
	sf->handle = handle;
	source_location top_of_file;
	int cr, last_cr, next_cr, read_cr, newline_char = 0;

	unicode_file_buffer ufb = TextFiles::create_filtered_ufb(mode);

	top_of_file.file_of_origin = sf;
	top_of_file.line_number = 1;

	Lexer::feed_begins(top_of_file);
	if (documentation_only) lexer_wait_for_dashes = TRUE;

	last_cr = ' '; cr = ' '; next_cr = TextFiles::utf8_fgetc(sf->handle, NULL, &ufb);
	if (next_cr == 0xFEFF) next_cr = TextFiles::utf8_fgetc(sf->handle, NULL, &ufb); /* Unicode BOM code */
	if (next_cr != EOF)
		while (((read_cr = TextFiles::utf8_fgetc(sf->handle, NULL, &ufb)), next_cr) != EOF) {
			last_cr = cr; cr = next_cr; next_cr = read_cr;
			switch(cr) {
				case '\x0a':
					if (newline_char == '\x0d') {
						newline_char = 0; continue; /* suppress |0x000A| when it follows |0x000D| */
					}
					newline_char = cr; cr = '\n'; /* and otherwise convert to |'\n'| */
					break;
				case '\x0d':
					if (newline_char == '\x0a') {
						newline_char = 0; continue; /* suppress |0x000D| when it follows |0x000A| */
					}
					newline_char = cr; cr = '\n'; /* and otherwise convert to |'\n'| */
					break;
				default:
					newline_char = 0;
					break;
			}
			Lexer::feed_triplet(last_cr, cr, next_cr);
		}

    sf->text_read = Lexer::feed_ends(TRUE, leaf);

    @<Word count the new material@>;
    return sf;
}

@ We word count all source files, both as to their source text and their
quoted text (i.e., their text within double-quotes).

@<Word count the new material@> =
	LOOP_THROUGH_WORDING(wc, sf->text_read)
    	sf->words_of_source += TextFromFiles::word_count(wc);

@ A much simpler version:

=
source_file *TextFromFiles::feed_into_lexer(filename *F, general_pointer ref) {
	FILE *handle = Filenames::fopen(F, "r");
	if (handle == NULL) return NULL;
	source_file *sf = TextFromFiles::feed_open_file_into_lexer(F, handle,
		Filenames::get_leafname(F), FALSE, ref, UNICODE_UFBHM);
	fclose(handle);
	return sf;
}

@ =
int TextFromFiles::word_count(int wc) {
	int N = 0;
	wchar_t *p = Lexer::word_text(wc);
	if (*p == '"') {
		/* inside quoted text, each run of non-whitespace counts as 1 word */
		p++; /* skip opening quotation mark */
		while (*p != 0) {
			while ((*p == ' ') || (*p == NEWLINE_IN_STRING)) p++; /* move past white space */
			if ((*p == '"') || (*p == 0)) break; /* stop if this reaches the end */
			N++; /* otherwise we have a word */
			while ((*p != ' ') && (*p != NEWLINE_IN_STRING)
				&& (*p != '"') && (*p != 0)) p++; /* move to white space or end */
		}
	} else {
		/* outside quoted text, each lexer word not wholly composed of punctuation scores 1 */
		if (Lexer::word(wc) != PARBREAK_V)
			for (; *p != 0; p++)
				if ((Lexer::is_punctuation(*p) == FALSE) && (*p != '|')) {
					N++;
					break;
				}
	}
	return N;
}

@ At present, though, the only use made of these two word counts is via
the following routine, which combines them into one.

=
int TextFromFiles::total_word_count(source_file *sf) {
	if (sf == NULL) return 0;
	return sf->words_of_source + sf->words_of_quoted_text;
}

int TextFromFiles::last_lexed_word(source_file *sf) {
	return Wordings::last_wn(sf->text_read);
}

@ Finally, we translate between the tiresomely many representations of
files we seem to be stuck with. The method used by |TextFromFiles::filename_to_source_file|
looks vulnerable to case-insensitive filename issues, but isn't, because
each filename is present in Inform in only one form.

=
filename *TextFromFiles::get_filename(source_file *sf) {
	if (sf == NULL) internal_error("tried to read filename of null source file");
	return sf->name;
}

source_file *TextFromFiles::filename_to_source_file(text_stream *name2) {
	int l2 = Str::len(name2);
	source_file *sf;
	LOOP_OVER(sf, source_file) {
		TEMPORARY_TEXT(name1)
		WRITE_TO(name1, "%f", sf->name);
		int l1 = Str::len(name1);
		int minl = (l1<l2)?l1:l2;
		if (Str::suffix_eq(name1, name2, minl)) return sf;
	}
	return NULL;
}
