[SourceText::] Source Text.

Code for reading Inform 7 source text, which Inbuild uses for both extensions
and projects.

@ This short function is a bridge to the lexer, and is used for reading
text files of source into either projects or extensions. Note that it
doesn't attach the fed text to the copy: the copy may need to contain text
from multiple files and indeed from elsewhere.

=
source_file *SourceText::read_file(inbuild_copy *C, filename *F, text_stream *synopsis,
	int documentation_only, int primary) {
	general_pointer ref = STORE_POINTER_inbuild_copy(NULL);
	FILE *handle = Filenames::fopen(F, "r");
	if (handle == NULL) return NULL;
	text_stream *leaf = Filenames::get_leafname(F);
	if (primary) leaf = I"main source text";
	source_file *sf = TextFromFiles::feed_open_file_into_lexer(F, handle,
		leaf, documentation_only, ref);
	if (sf == NULL) {
		Copies::attach(C, Copies::new_error_on_file(OPEN_FAILED_CE, F));
	} else {
		fclose(handle);
		if (documentation_only == FALSE) @<Tell console output about the file@>;
	}
	return sf;
}

@ This is where messages like

	|I've also read Standard Rules by Graham Nelson, which is 27204 words long.|

are printed to |stdout| (not |stderr|), in something of an affectionate nod
to TeX's traditional console output, though occasionally I think silence is
golden and that these messages could go. It's a moot point for almost all users,
though, because the console output is concealed from them by the Inform
application.

@<Tell console output about the file@> =
	int wc;
	char *message;
	if (primary) message = "I've now read %S, which is %d words long.\n";
	else message = "I've also read %S, which is %d words long.\n";
	wc = TextFromFiles::total_word_count(sf);
	WRITE_TO(STDOUT, message, synopsis, wc);
	STREAM_FLUSH(STDOUT);
	LOG(message, synopsis, wc);
