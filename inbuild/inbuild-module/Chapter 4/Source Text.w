[SourceText::] Source Text.

Code for reading Inform 7 source text, which Inbuild uses for both extensions
and projects.

@ This short function is a bridge to the lexer, and is used for reading
text files of source into either projects or extensions. Note that it
doesn't attach the fed text to the copy: the copy may need to contain text
from multiple files and indeed from elsewhere.

=
inbuild_copy *currently_lexing_into = NULL;

source_file *SourceText::read_file(inbuild_copy *C, filename *F, text_stream *synopsis,
	int documentation_only, int primary) {
	currently_lexing_into = C;
	general_pointer ref = STORE_POINTER_inbuild_copy(NULL);
	FILE *handle = Filenames::fopen(F, "r");
	source_file *sf = NULL;
	if (handle) {
		text_stream *leaf = Filenames::get_leafname(F);
		if (primary) leaf = I"main source text";
		sf = TextFromFiles::feed_open_file_into_lexer(F, handle,
			leaf, documentation_only, ref);
		if (sf == NULL) {
			Copies::attach(C, Copies::new_error_on_file(OPEN_FAILED_CE, F));
		} else {
			fclose(handle);
			if (documentation_only == FALSE) @<Tell console output about the file@>;
		}
	}
	currently_lexing_into = NULL;
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

@

@d LEXER_PROBLEM_HANDLER SourceText::lexer_problem_handler

=
void SourceText::lexer_problem_handler(int err, text_stream *desc, wchar_t *word) {
	if (err == MEMORY_OUT_LEXERERROR)
		Errors::fatal("Out of memory: unable to create lexer workspace");
	TEMPORARY_TEXT(erm);
	switch (err) {
		case STRING_TOO_LONG_LEXERERROR:
			WRITE_TO(erm, "Too much text in quotation marks: %w", word);
            break;
		case WORD_TOO_LONG_LEXERERROR:
			WRITE_TO(erm, "Word too long: %w", word);
			break;
		case I6_TOO_LONG_LEXERERROR:
			WRITE_TO(erm, "I6 inclusion too long: %w", word);
			break;
		case STRING_NEVER_ENDS_LEXERERROR:
			WRITE_TO(erm, "Quoted text never ends: %S", desc);
			break;
		case COMMENT_NEVER_ENDS_LEXERERROR:
			WRITE_TO(erm, "Square-bracketed text never ends: %S", desc);
			break;
		case I6_NEVER_ENDS_LEXERERROR:
			WRITE_TO(erm, "I6 inclusion text never ends: %S", desc);
			break;
		default:
			internal_error("unknown lexer error");
    }
    if (currently_lexing_into) {
    	copy_error *CE = Copies::new_error(LEXER_CE, erm);
    	CE->error_subcategory = err;
    	CE->details = Str::duplicate(desc);
    	CE->word = word;
    	Copies::attach(currently_lexing_into, CE);
    }
	DISCARD_TEXT(erm);
}
