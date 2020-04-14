[Languages::] Language Services.

Behaviour specific to copies of the language genre.

@ Inform can read and write text in multiple natural languages, though it
needs help to do so. Each natural language known to Inform comes from a
small resource folder called its "bundle", and also has an extension
associated with it: this includes English. Bundles for common languages
are included as part of the default distribution for Inform, but the
extension is only included for English.

Each natural language whose bundle can be located generates an instance
of the following structure.

=
typedef struct inform_language {
	struct inbuild_copy *as_copy;
	struct semantic_version_number version;
	struct wording instance_name; /* instance name, e.g., "German language" */
	struct instance *nl_instance; /* instance, e.g., "German language" */
	struct wording language_field[MAX_LANGUAGE_FIELDS]; /* contents of the |about.txt| fields */
	int adaptive_person; /* which person (one of constants below) text subs are written from */
	MEMORY_MANAGEMENT
} inform_language;

inform_language *Languages::new_il(text_stream *name, pathname *P) {
	inform_language *L = CREATE(inform_language);
	L->as_copy = NULL;
	L->version = VersionNumbers::null();
	TEMPORARY_TEXT(sentence_format);
	WRITE_TO(sentence_format, "%S language", name);
	L->instance_name = Feeds::feed_stream(sentence_format);
	DISCARD_TEXT(sentence_format);
	L->nl_instance = NULL;
	L->adaptive_person = -1; /* i.e., none yet specified */
	for (int n=0; n<MAX_LANGUAGE_FIELDS; n++) L->language_field[n] = EMPTY_WORDING;
	@<Read the about.txt file for the bundle@>;
	LOG("Found language bundle '%S' (%p)\n", name, P);
	return L;
}

pathname *Languages::path_to_bundle(inform_language *L) {
	return L->as_copy->location_if_path;
}

@ Within the bundle folder is a file called |about.txt|, which sets numbered
fields to excerpts of text. The following are the field numbers:

@d NAME_IN_ENGLISH_LFIELD 1		/* e.g. "German" */
@d NAME_NATIVE_LFIELD 2			/* e.g. "Deutsch" */
@d CUE_NATIVE_LFIELD 3			/* e.g. "in deutscher Sprache" */
@d ISO_639_CODE_LFIELD 4		/* e.g. "de": an ISO 639-1 code */
@d TRANSLATOR_LFIELD 5			/* e.g. "Team GerX" */
@d KIT_LFIELD 6					/* e.g. "GermanLanguageKit" */
@d MAX_LANGUAGE_FIELDS 7		/* one more than the highest number above */

@ If we can't find the file, it doesn't matter except that all of the excerpts
remain empty. But we may as well tell the debugging log.

@d MAX_BUNDLE_ABOUT_LINE_LENGTH 256  /* which is far more than necessary, really */

@<Read the about.txt file for the bundle@> =
	filename *about_file = Filenames::in_folder(P, I"about.txt");

	if (TextFiles::read(about_file, FALSE,
		NULL, FALSE, Languages::about_helper, NULL, L) == FALSE)
		LOG("Can't find about file: %f\n", about_file);

@ The format of the file is very simple. Each line is introduced by a number
from 1 to |MAX_LANGUAGE_FIELDS| minus one, and then contains text which
extends for the rest of the line.

=
void Languages::about_helper(text_stream *item_name,
	text_file_position *tfp, void *vnl) {
	inform_language *L = (inform_language *) vnl;
	wording W = Feeds::feed_stream(item_name);
	if (Wordings::nonempty(W)) {
		vocabulary_entry *ve = Lexer::word(Wordings::first_wn(W));
		int field = -1;
		if ((ve) && (Vocabulary::test_vflags(ve, NUMBER_MC)))
			field = Vocabulary::get_literal_number_value(ve);
		if ((field >= 1) && (field < MAX_LANGUAGE_FIELDS)) {
			L->language_field[field] =
				Wordings::new(Wordings::first_wn(W)+1, Wordings::last_wn(W));
		} else LOG("Warning: couldn't read about.txt line: %S\n", item_name);
	}
}

@h Logging.

=
void Languages::log(OUTPUT_STREAM, char *opts, void *vL) {
	inform_language *L = (inform_language *) vL;
	if (L == NULL) { LOG("<null-language>"); }
	else { LOG("%S", L->as_copy->edition->work->title); }
}

@h Language code.
This is used when we write the bibliographic data for the work of IF we're
making; this enables online databases like IFDB, and smart interpreters, to
detect the language of play for a story file without actually running it.

=
void Languages::write_ISO_code(OUTPUT_STREAM, inform_language *L) {
	#ifdef CORE_MODULE
	if (L == NULL) L = English_language;
	#endif
	if (Wordings::nonempty(L->language_field[ISO_639_CODE_LFIELD]))
		WRITE("%+W", L->language_field[ISO_639_CODE_LFIELD]);
	else WRITE("en");
}

@h Kit.
Each language needs its own kit of Inter code, named as follows:

=
text_stream *Languages::kit_name(inform_language *L) {
	text_stream *T = Str::new();
	if (Wordings::nonempty(L->language_field[KIT_LFIELD]))
		WRITE_TO(T, "%+W", L->language_field[KIT_LFIELD]);
	else
		WRITE_TO(T, "%+WLanguageKit", L->language_field[NAME_IN_ENGLISH_LFIELD]);
	return T;
}

@h Finding by name.
Given the name of a natural language (e.g., "German") we find the
corresponding structure, if it exists. We perform this check case
insensitively.

=
inform_language *Languages::from_name(text_stream *name) {
	inform_language *L;
	LOOP_OVER(L, inform_language)
		if (Str::eq_insensitive(L->as_copy->edition->work->title, name))
			return L;
	return NULL;
}

@h English.
This finds the built-in definition of the English language.

=
inform_language *Languages::internal_English(void) {
	inbuild_requirement *req =
		Requirements::any_version_of(Works::new(language_genre, I"English", I""));
	inbuild_nest *I = Inbuild::internal();
	if (I) {
		linked_list *L = NEW_LINKED_LIST(inbuild_nest);
		ADD_TO_LINKED_LIST(I, inbuild_nest, L);
		inbuild_search_result *R = Nests::search_for_best(req, L);
		if (R) return LanguageManager::from_copy(R->copy);
	}
	return NULL;
}
