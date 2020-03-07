[Copies::] Copies.

A copy is an instance in the file system of a specific edition of a work.

@h Copies.
A "copy" of a work exists in the file system when we've actually got hold of
some edition of it. For some genres, copies will be files; for others,
directories holding a set of files.

=
typedef struct inbuild_copy {
	struct inbuild_edition *edition;
	struct pathname *location_if_path;
	struct filename *location_if_file;
	general_pointer content; /* the type of which depends on the work's genre */
	struct build_vertex *vertex;
	int source_text_read;
	struct wording source_text;
	struct linked_list *errors_reading_source_text;
	struct inbuild_requirement *found_by;
	MEMORY_MANAGEMENT
} inbuild_copy;

inbuild_copy *Copies::new_p(inbuild_edition *edition, general_pointer ref) {
	inbuild_copy *copy = CREATE(inbuild_copy);
	copy->edition = edition;
	copy->location_if_path = NULL;
	copy->location_if_file = NULL;
	copy->content = ref;
	copy->vertex = NULL;
	copy->source_text_read = FALSE;
	copy->source_text = EMPTY_WORDING;
	copy->errors_reading_source_text = NEW_LINKED_LIST(copy_error);
	copy->found_by = NULL;
	return copy;
}

inbuild_copy *Copies::new_in_file(inbuild_edition *edition, filename *F, general_pointer ref) {
	inbuild_copy *copy = Copies::new_p(edition, ref);
	copy->location_if_file = F;
	return copy;
}

inbuild_copy *Copies::new_in_path(inbuild_edition *edition, pathname *P, general_pointer ref) {
	inbuild_copy *copy = Copies::new_p(edition, ref);
	copy->location_if_path = P;
	return copy;
}

void Copies::set_content(inbuild_copy *C, general_pointer ref) {
	C->content = ref;
}

void Copies::write_copy(OUTPUT_STREAM, inbuild_copy *C) {
	Editions::write(OUT, C->edition);
}

void Copies::inspect_copy(OUTPUT_STREAM, inbuild_copy *C) {
	Editions::inspect(OUT, C->edition);
}

void Copies::go_operational(inbuild_copy *C) {
	VMETHOD_CALL(C->edition->work->genre, GENRE_GO_OPERATIONAL_MTID, C);
}

void Copies::scan(inbuild_copy *C) {
	VMETHOD_CALL(C->edition->work->genre, GENRE_SCAN_COPY_MTID, C);
}

void Copies::build(OUTPUT_STREAM, inbuild_copy *C, build_methodology *BM) {
	VMETHOD_CALL(C->edition->work->genre, GENRE_BUILD_COPY_MTID, OUT, C, BM, FALSE, FALSE);
}
void Copies::rebuild(OUTPUT_STREAM, inbuild_copy *C, build_methodology *BM) {
	VMETHOD_CALL(C->edition->work->genre, GENRE_BUILD_COPY_MTID, OUT, C, BM, TRUE, FALSE);
}
void Copies::show_graph(OUTPUT_STREAM, inbuild_copy *C) {
	VMETHOD_CALL(C->edition->work->genre, GENRE_BUILD_COPY_MTID, OUT, C, NULL, FALSE, TRUE);
}

wording Copies::read_source_text_for(inbuild_copy *C) {
	if (C->source_text_read == FALSE) {
		C->source_text_read = TRUE;
		feed_t id = Feeds::begin();
		VMETHOD_CALL(C->edition->work->genre, GENRE_READ_SOURCE_TEXT_FOR_MTID, C);
		wording W = Feeds::end(id);
		if (Wordings::nonempty(W)) C->source_text = W;
	}
	return C->source_text;
}

inbuild_copy *Copies::claim(text_stream *arg) {
	TEMPORARY_TEXT(ext);
	int pos = Str::len(arg) - 1, dotpos = -1;
	while (pos >= 0) {
		wchar_t c = Str::get_at(arg, pos);
		if (c == FOLDER_SEPARATOR) break;
		if (c == '.') dotpos = pos;
		pos--;
	}
	if (dotpos >= 0)
		Str::substr(ext, Str::at(arg, dotpos+1), Str::end(arg));
	int directory_status = NOT_APPLICABLE;
	if (Str::get_last_char(arg) == FOLDER_SEPARATOR) {
		Str::delete_last_character(arg);
		directory_status = TRUE;
	}
	inbuild_copy *C = NULL;
	inbuild_genre *G;
	LOOP_OVER(G, inbuild_genre)
		if (C == NULL)
			VMETHOD_CALL(G, GENRE_CLAIM_AS_COPY_MTID, &C, arg, ext, directory_status);
	DISCARD_TEXT(ext);
	return C;
}

void Copies::inspect(OUTPUT_STREAM, inbuild_copy *C) {
	WRITE("%S: ", Genres::name(C->edition->work->genre));
	Copies::inspect_copy(STDOUT, C);
	if (C->location_if_path) {
		WRITE(" at path %p", C->location_if_path);
	}
	if (C->location_if_file) {
		WRITE(" in directory %p", Filenames::get_path_to(C->location_if_file));
	}
	int N = LinkedLists::len(C->errors_reading_source_text);
	if (N > 0) {
		WRITE(" - %d error", N);
		if (N > 1) WRITE("s");
	}
	WRITE("\n");
	if (N > 0) {
		INDENT; Copies::list_problems_arising(OUT, C); OUTDENT;
	}
}

@h Errors.
Copies can sometimes exist in a damaged form: for example, they are purportedly
extension files but have a mangled identification line. Each copy structure
therefore has a list attached of errors which occurred in reading it.

@e OPEN_FAILED_CE from 1
@e KIT_MISWORDED_CE
@e EXT_MISWORDED_CE
@e EXT_TITLE_TOO_LONG_CE
@e EXT_AUTHOR_TOO_LONG_CE
@e LEXER_CE
@e SYNTAX_CE

=
typedef struct copy_error {
	int error_category;
	int error_subcategory;
	struct inbuild_copy *copy;
	struct filename *file;
	struct text_file_position pos;
	struct text_stream *notes;
	struct text_stream *details;
	int details_N;
	struct wording details_W;
	struct parse_node *details_node;
	wchar_t *word;
	MEMORY_MANAGEMENT
} copy_error;

copy_error *Copies::new_error(int cat, text_stream *NB) {
	copy_error *CE = CREATE(copy_error);
	CE->error_category = cat;
	CE->error_subcategory = -1;
	CE->file = NULL;
	CE->notes = Str::duplicate(NB);
	CE->details = NULL;
	CE->details_N = -1;
	CE->details_W = EMPTY_WORDING;
	CE->details_node = NULL;
	CE->pos = TextFiles::nowhere();
	CE->copy = NULL;
	CE->word = NULL;
	return CE;
}

copy_error *Copies::new_error_N(int cat, int N) {
	copy_error *CE = Copies::new_error(cat, NULL);
	CE->details_N = N;
	return CE;
}

copy_error *Copies::new_error_on_file(int cat, filename *F) {
	copy_error *CE = Copies::new_error(cat, NULL);
	CE->file = F;
	return CE;
}

void Copies::attach(inbuild_copy *C, copy_error *CE) {
	if (C == NULL) internal_error("no copy to attach to");
	CE->copy = C;
	ADD_TO_LINKED_LIST(CE, copy_error, C->errors_reading_source_text);
}

void Copies::list_problems_arising(OUTPUT_STREAM, inbuild_copy *C) {
	if (C == NULL) return;
	copy_error *CE;
	int c = 1;
	LOOP_OVER_LINKED_LIST(CE, copy_error, C->errors_reading_source_text) {
		WRITE("%d. ", c++); Copies::write_problem(OUT, CE); WRITE("\n");
	}
}

void Copies::write_problem(OUTPUT_STREAM, copy_error *CE) {
	switch (CE->error_category) {
		case OPEN_FAILED_CE: WRITE("unable to open file %f", CE->file); break;
		case EXT_MISWORDED_CE: WRITE("extension misworded: %S", CE->notes); break;
		case KIT_MISWORDED_CE: WRITE("kit has incorrect metadata: %S", CE->notes); break;
		case EXT_TITLE_TOO_LONG_CE: WRITE("title too long: %d characters (max is %d)",
			CE->details_N, MAX_EXTENSION_TITLE_LENGTH); break;
		case EXT_AUTHOR_TOO_LONG_CE: WRITE("author name too long: %d characters (max is %d)",
			CE->details_N, MAX_EXTENSION_AUTHOR_LENGTH); break;
		case LEXER_CE: WRITE("%S", CE->notes); break;
		case SYNTAX_CE:
			switch (CE->error_subcategory) {
				case UnexpectedSemicolon_SYNERROR:
					WRITE("unexpected semicolon in sentence"); break;
				case ParaEndsInColon_SYNERROR:
					WRITE("paragraph ends with a colon"); break;
				case SentenceEndsInColon_SYNERROR:
					WRITE("paragraph ends with a colon and full stop"); break;
				case SentenceEndsInSemicolon_SYNERROR:
					WRITE("paragraph ends with a semicolon and full stop"); break;
				case SemicolonAfterColon_SYNERROR:
					WRITE("paragraph ends with a colon and semicolon"); break;
				case SemicolonAfterStop_SYNERROR:
					WRITE("paragraph ends with a full stop and semicolon"); break;
				case HeadingOverLine_SYNERROR:
					WRITE("heading contains a line break"); break;
				case HeadingStopsBeforeEndOfLine_SYNERROR:
					WRITE("heading stops before end of line"); break;
				case ExtNoBeginsHere_SYNERROR:
					WRITE("extension has no beginning"); break;
				case ExtNoEndsHere_SYNERROR:
					WRITE("extension has no end"); break;
				case ExtSpuriouslyContinues_SYNERROR:
					WRITE("extension continues after end"); break;
				case ExtMultipleBeginsHere_SYNERROR:
					WRITE("extension has multiple 'begins here' sentences"); break;
				case ExtBeginsAfterEndsHere_SYNERROR:
					WRITE("extension has a 'begins here' after its 'ends here'"); break;
				case ExtEndsWithoutBegins_SYNERROR:
					WRITE("extension has an 'ends here' but no 'begins here'"); break;
				case ExtMultipleEndsHere_SYNERROR:
					WRITE("extension has multiple 'ends here' sentences"); break;
				case BadTitleSentence_SYNERROR:
					WRITE("bibliographic sentence at the start is malformed"); break;
				case UnknownLanguageElement_SYNERROR:
					WRITE("unrecognised stipulation about Inform language elements"); break;
				case UnknownVirtualMachine_SYNERROR:
					WRITE("unrecognised stipulation about virtual machine"); break;
				default:
					WRITE("syntax error"); break;
			}
			break;
		default: internal_error("an unknown error occurred");
	}
}
