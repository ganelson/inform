[LanguageManager::] Language Manager.

Claiming and creating copies of the language genre: used for bundles of
natural language metadata in the Inform 7 compiler.

@h Genre definition.
The |language_genre| can be summarised as follows. Language definitions
consist of directories, containing metadata in |D/about.txt|. They are
recognised by having this metadata file in place. They are stored in
nests, in |N/Languages/Title-vVersion|. Their build graphs are single
vertices with no build or use edges.

=
void LanguageManager::start(void) {
	language_genre = Genres::new(I"language", I"language", TRUE);
	METHOD_ADD(language_genre, GENRE_WRITE_WORK_MTID, LanguageManager::write_work);
	METHOD_ADD(language_genre, GENRE_CLAIM_AS_COPY_MTID, LanguageManager::claim_as_copy);
	METHOD_ADD(language_genre, GENRE_SEARCH_NEST_FOR_MTID, LanguageManager::search_nest_for);
	METHOD_ADD(language_genre, GENRE_COPY_TO_NEST_MTID, LanguageManager::copy_to_nest);
	METHOD_ADD(language_genre, GENRE_CONSTRUCT_GRAPH_MTID, LanguageManager::construct_graph);
}

void LanguageManager::write_work(inbuild_genre *gen, OUTPUT_STREAM, inbuild_work *work) {
	WRITE("%S", work->title);
}

@ Languages live in the |Inter| subdirectory of a nest:

=
pathname *LanguageManager::path_within_nest(inbuild_nest *N) {
	if (N == NULL) internal_error("no nest");
	return Pathnames::down(N->location, I"Languages");
}

@ Language copies are annotated with a structure called an |inform_language|,
which stores data about extensions used by the Inform compiler.

=
inform_language *LanguageManager::from_copy(inbuild_copy *C) {
	if ((C) && (C->edition->work->genre == language_genre)) {
		return RETRIEVE_POINTER_inform_language(C->metadata);
	}
	return NULL;
}

dictionary *language_copy_cache = NULL;
inbuild_copy *LanguageManager::new_copy(text_stream *name, pathname *P, inbuild_nest *N) {
	if (language_copy_cache == NULL) language_copy_cache = Dictionaries::new(16, FALSE);
	TEMPORARY_TEXT(key)
	WRITE_TO(key, "%p", P);
	inbuild_copy *C = NULL;
	if (Dictionaries::find(language_copy_cache, key))
		C = Dictionaries::read_value(language_copy_cache, key);
	if (C == NULL) {
		inbuild_work *work = Works::new(language_genre, Str::duplicate(name), NULL);
		inbuild_edition *edition = Editions::new(work, VersionNumbers::null());
		C = Copies::new_in_path(edition, P, N);
		Languages::scan(C);
		Dictionaries::create(language_copy_cache, key);
		Dictionaries::write_value(language_copy_cache, key, C);
	}
	DISCARD_TEXT(key)
	return C;
}

@h Claiming.
Here |arg| is a textual form of a filename or pathname, such as may have been
supplied at the command line; |ext| is a substring of it, and is its extension
(e.g., |jpg| if |arg| is |Geraniums.jpg|), or is empty if there isn't one;
|directory_status| is true if we know for some reason that this is a directory
not a file, false if we know the reverse, and otherwise not applicable.

A language needs to be a directory whose name ends in |Language|, and which contains
a valid metadata file. The name should be in English text, without accents.

=
void LanguageManager::claim_as_copy(inbuild_genre *gen, inbuild_copy **C,
	text_stream *arg, text_stream *ext, int directory_status) {
	if (directory_status == FALSE) return;
	pathname *P = Pathnames::from_text(arg);
	text_stream *name = Pathnames::directory_name(P);
	int acceptable = TRUE;
	LOOP_THROUGH_TEXT(pos, name) {
		inchar32_t c = Str::get(pos);
		if ((c < 32) || (c > 126)) acceptable = FALSE; /* contains non-ASCII */
		if (Platform::is_folder_separator(c)) { Str::put(pos, 0); break; }
	}
	if (Str::len(name) == 0) acceptable = FALSE; /* i.e., an empty text */
	if (acceptable) {
		*C = LanguageManager::claim_folder_as_copy(P, NULL);
	}
}

inbuild_copy *LanguageManager::claim_folder_as_copy(pathname *P, inbuild_nest *N) {
	filename *canary = Filenames::in(P, I"about.txt");
	if (TextFiles::exists(canary))
		return LanguageManager::new_copy(Pathnames::directory_name(P), P, N);
	canary = Filenames::in(P, I"language_metadata.json");
	if (TextFiles::exists(canary))
		return LanguageManager::new_copy(Pathnames::directory_name(P), P, N);
	return NULL;
}

@h Searching.
Here we look through a nest to find all languages matching the supplied
requirements.

=
void LanguageManager::search_nest_for(inbuild_genre *gen, inbuild_nest *N,
	inbuild_requirement *req, linked_list *search_results) {
	pathname *P = LanguageManager::path_within_nest(N);
	linked_list *L = Directories::listing(P);
	text_stream *entry;
	LOOP_OVER_LINKED_LIST(entry, text_stream, L) {
		if (Platform::is_folder_separator(Str::get_last_char(entry))) {
			Str::delete_last_character(entry);
			pathname *Q = Pathnames::down(P, entry);
			inbuild_copy *C = LanguageManager::claim_folder_as_copy(Q, N);
			if ((C) && (Requirements::meets(C->edition, req))) {
				Nests::add_search_result(search_results, N, C, req);
			}
		}
	}
}

@h Copying.
Now the task is to copy a language into place in a nest. Since a language is a folder,
we need to |rsync| it.

=
pathname *LanguageManager::pathname_in_nest(inbuild_nest *N, inbuild_edition *E) {
	TEMPORARY_TEXT(leaf)
	Editions::write_canonical_leaf(leaf, E);
	pathname *P = Pathnames::down(LanguageManager::path_within_nest(N), leaf);
	DISCARD_TEXT(leaf)
	return P;
}

int LanguageManager::copy_to_nest(inbuild_genre *gen, inbuild_copy *C, inbuild_nest *N,
	int syncing, build_methodology *meth) {
	pathname *dest_language = LanguageManager::pathname_in_nest(N, C->edition);
	filename *dest_language_metadata = Filenames::in(dest_language, I"about.txt");
	if (TextFiles::exists(dest_language_metadata)) {
		if (syncing == FALSE) { Copies::overwrite_error(C, N); return 1; }
	} else {
		if (meth->methodology == DRY_RUN_METHODOLOGY) {
			TEMPORARY_TEXT(command)
			WRITE_TO(command, "mkdir -p ");
			Shell::quote_path(command, dest_language);
			WRITE_TO(STDOUT, "%S\n", command);
			DISCARD_TEXT(command)
		} else {
			Pathnames::create_in_file_system(N->location);
			Pathnames::create_in_file_system(LanguageManager::path_within_nest(N));
			Pathnames::create_in_file_system(dest_language);
		}
	}
	int rv = FALSE;
	if (meth->methodology == DRY_RUN_METHODOLOGY) {
		TEMPORARY_TEXT(command)
		WRITE_TO(command, "rsync -a --delete ");
		Shell::quote_path(command, C->location_if_path);
		Shell::quote_path(command, dest_language);
		WRITE_TO(STDOUT, "%S\n", command);
		DISCARD_TEXT(command)
	} else {
		rv = Pathnames::rsync(C->location_if_path, dest_language);
	}
	return rv;
}

void LanguageManager::construct_graph(inbuild_genre *G, inbuild_copy *C) {
	Languages::construct_graph(LanguageManager::from_copy(C));
}
