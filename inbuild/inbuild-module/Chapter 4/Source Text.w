[SourceText::] Source Text.

Code for reading Inform 7 source text, which Inbuild uses for both extensions
and projects.

@ Either way, we use the following code. The |SourceText::read_file| function returns
one of the following values to indicate the source of the source: the value
only really tells us something we didn't know in the case of extensions,
but in that event the Extensions.w routines do indeed want to know this.

@e SEARCH_FAILED_STE from 1
@e OPEN_FAILED_STE

=
typedef struct source_text_error {
	int ste_code;
	struct inbuild_copy *copy;
	struct filename *file;
	struct text_file_position pos;
	struct text_stream *notes;
	MEMORY_MANAGEMENT
} source_text_error;

source_text_error *SourceText::ste(int code, filename *F) {
	source_text_error *ste = CREATE(source_text_error);
	ste->ste_code = code;
	ste->file = F;
	ste->notes = NULL;
	ste->pos = TextFiles::nowhere();
	ste->copy = NULL;
	return ste;
}

source_text_error *SourceText::ste_text(int code, text_stream *NB) {
	source_text_error *ste = CREATE(source_text_error);
	ste->ste_code = code;
	ste->file = NULL;
	ste->notes = Str::duplicate(NB);
	ste->pos = TextFiles::nowhere();
	ste->copy = NULL;
	return ste;
}

source_file *SourceText::read_file(filename *F, text_stream *synopsis,
	int documentation_only, linked_list *errors, int primary) {
	general_pointer ref = STORE_POINTER_inbuild_copy(NULL);
	FILE *handle = Filenames::fopen(F, "r");
	if (handle == NULL) return NULL;
	text_stream *leaf = Filenames::get_leafname(F);
	if (primary) leaf = I"main source text";
	source_file *sf = TextFromFiles::feed_open_file_into_lexer(F, handle,
		leaf, documentation_only, ref);
	if (sf == NULL) {
		source_text_error *ste = SourceText::ste(OPEN_FAILED_STE, F);
		ADD_TO_LINKED_LIST(ste, source_text_error, errors);
	} else {
		fclose(handle);
		if (documentation_only == FALSE) @<Tell console output about the file@>;
	}
	return sf;
}

@ This is where messages like

	|I've also read Standard Rules by Graham Nelson, which is 27204 words long.|

are printed to |stdout| (not |stderr|), in something of an affectionate nod
to \TeX's traditional console output, though occasionally I think silence is
golden and that the messages could go. It's a moot point for almost all users,
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
