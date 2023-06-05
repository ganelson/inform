[Provenance::] Text Provenance.

Recording where fragments of text originally came from.

@ Inter code sometimes needs to contain fragments of not-yet-parsed Inform 6
syntax code, in the form of |SPLAT_IST| and |INSERT_IST| instructions. In order
for it to be possible to relate errors in those fragments to the original text
files they came from, we need to record their "provenance".

This is only a wrapper for saying something like "line 17 in |whatever.txt|".
Line numbers count from 1 at the top of a text file.

=
typedef struct text_provenance {
	struct text_stream *textual_filename;
	int line_number;
} text_provenance;

@ This provides a "don't know, or, it didn't come from a text file, I made it up"
value:

=
text_provenance Provenance::nowhere(void) {
	text_provenance nowhere;
	nowhere.textual_filename = NULL;
	nowhere.line_number = 0;
	return nowhere;
}

int Provenance::is_somewhere(text_provenance where) {
	if (Str::len(where.textual_filename) > 0) return TRUE;
	return FALSE;
}

@ Composing:

=
text_provenance Provenance::at_file_and_line(text_stream *file, int line) {
	text_provenance somewhere;
	somewhere.textual_filename = Str::duplicate(file);
	somewhere.line_number = line;
	return somewhere;
}

@ Decomposing:

=
int Provenance::get_line(text_provenance where) {
	if (Provenance::is_somewhere(where)) return where.line_number;
	return 0;
}

filename *Provenance::get_filename(text_provenance where) {
	if (Provenance::is_somewhere(where))
		return Filenames::from_text(where.textual_filename);
	return NULL;
}

@ Altering in place:

=
void Provenance::set_line(text_provenance *where, int lc) {
	if ((where) && (Provenance::is_somewhere(*where)))
		where->line_number = lc;
}

void Provenance::advance_line(text_provenance *where, int by) {
	if ((where) && (Provenance::is_somewhere(*where)))
		where->line_number += by;
}

@ Writing to text:

=
void Provenance::write(OUTPUT_STREAM, text_provenance at) {
	if (Provenance::is_somewhere(at)) {
		TextualInter::write_text(OUT, at.textual_filename);
		WRITE(" %d", at.line_number);
	} else {
		WRITE("<nowhere>");
	}
}
