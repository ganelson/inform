[LanguageManager::] Language Manager.

A language is a combination of Inter code with an Inform 7 extension.

@h Genre definition.

=
inbuild_genre *language_genre = NULL;
void LanguageManager::start(void) {
	language_genre = Model::genre(I"language");
	METHOD_ADD(language_genre, GENRE_WRITE_WORK_MTID, LanguageManager::write_work);
	METHOD_ADD(language_genre, GENRE_CLAIM_AS_COPY_MTID, LanguageManager::claim_as_copy);
	METHOD_ADD(language_genre, GENRE_SEARCH_NEST_FOR_MTID, LanguageManager::search_nest_for);
	METHOD_ADD(language_genre, GENRE_COPY_TO_NEST_MTID, LanguageManager::copy_to_nest);
}

void LanguageManager::write_work(inbuild_genre *gen, OUTPUT_STREAM, inbuild_work *work) {
	WRITE("%S", work->title);
}

@ Languages live in the |Inter| subdirectory of a nest:

=
pathname *LanguageManager::path_within_nest(inbuild_nest *N) {
	if (N == NULL) internal_error("no nest");
	return Pathnames::subfolder(N->location, I"Languages");
}

@ Language copies are annotated with a structure called an |inform_language|,
which stores data about extensions used by the Inform compiler.

=
inform_language *LanguageManager::from_copy(inbuild_copy *C) {
	if ((C) && (C->edition->work->genre == language_genre)) {
		return RETRIEVE_POINTER_inform_language(C->content);
	}
	return NULL;
}

inbuild_copy *LanguageManager::new_copy(text_stream *name, pathname *P) {
	inform_language *K = Languages::new_il(name, P);
	inbuild_work *work = Works::new(language_genre, Str::duplicate(name), NULL);
	inbuild_edition *edition = Model::edition(work, K->version);
	K->as_copy = Model::copy_in_directory(edition, P, STORE_POINTER_inform_language(K));
	return K->as_copy;
}

@h Claiming.
Here |arg| is a textual form of a filename or pathname, such as may have been
supplied at the command line; |ext| is a substring of it, and is its extension
(e.g., |jpg| if |arg| is |Geraniums.jpg|), or is empty if there isn't one;
|directory_status| is true if we know for some reason that this is a directory
not a file, false if we know the reverse, and otherwise not applicable.

A language needs to be a directory whose name ends in |Language|, and which contains
a valid metadata file.

=
void LanguageManager::claim_as_copy(inbuild_genre *gen, inbuild_copy **C,
	text_stream *arg, text_stream *ext, int directory_status) {
	if (directory_status == FALSE) return;
	pathname *P = Pathnames::from_text(arg);
	*C = LanguageManager::claim_folder_as_copy(P);
}

inbuild_copy *LanguageManager::claim_folder_as_copy(pathname *P) {
	filename *canary = Filenames::in_folder(P, I"about.txt");
	if (TextFiles::exists(canary)) {
		inbuild_copy *C = LanguageManager::new_copy(Pathnames::directory_name(P), P);
		LanguageManager::build_graph(C);
		Works::add_to_database(C->edition->work, CLAIMED_WDBC);
		return C;
	}
	return NULL;
}

@h Searching.
Here we look through a nest to find all languages matching the supplied
requirements.

=
void LanguageManager::search_nest_for(inbuild_genre *gen, inbuild_nest *N,
	inbuild_requirement *req, linked_list *search_results) {
	pathname *P = LanguageManager::path_within_nest(N);
	scan_directory *D = Directories::open(P);
	if (D) {
		TEMPORARY_TEXT(LEAFNAME);
		while (Directories::next(D, LEAFNAME)) {
			if (Str::get_last_char(LEAFNAME) == FOLDER_SEPARATOR) {
				Str::delete_last_character(LEAFNAME);
				pathname *Q = Pathnames::subfolder(P, LEAFNAME);
				inbuild_copy *C = LanguageManager::claim_folder_as_copy(Q);
				if ((C) && (Requirements::meets(C->edition, req))) {
					Nests::add_search_result(search_results, N, C);
				}
			}
		}
		DISCARD_TEXT(LEAFNAME);
		Directories::close(D);
	}
}

@h Copying.
Now the task is to copy a language into place in a nest. Since a language is a folder,
we need to |rsync| it.

=
pathname *LanguageManager::pathname_in_nest(inbuild_nest *N, inbuild_work *W) {
	return Pathnames::subfolder(LanguageManager::path_within_nest(N), W->title);
}

void LanguageManager::copy_to_nest(inbuild_genre *gen, inbuild_copy *C, inbuild_nest *N,
	int syncing, build_methodology *meth) {
	pathname *dest_language = LanguageManager::pathname_in_nest(N, C->edition->work);
	filename *dest_language_metadata = Filenames::in_folder(dest_language, I"about.txt");
	if (TextFiles::exists(dest_language_metadata)) {
		if (syncing == FALSE) { Nests::overwrite_error(N, C); return; }
	} else {
		if (meth->methodology == DRY_RUN_METHODOLOGY) {
			TEMPORARY_TEXT(command);
			WRITE_TO(command, "mkdir -p ");
			Shell::quote_path(command, dest_language);
			WRITE_TO(STDOUT, "%S\n", command);
			DISCARD_TEXT(command);
		} else {
			Pathnames::create_in_file_system(N->location);
			Pathnames::create_in_file_system(LanguageManager::path_within_nest(N));
			Pathnames::create_in_file_system(dest_language);
		}
	}
	if (meth->methodology == DRY_RUN_METHODOLOGY) {
		TEMPORARY_TEXT(command);
		WRITE_TO(command, "rsync -a --delete ");
		Shell::quote_path(command, C->location_if_path);
		Shell::quote_path(command, dest_language);
		WRITE_TO(STDOUT, "%S\n", command);
		DISCARD_TEXT(command);
	} else {
		Pathnames::rsync(C->location_if_path, dest_language);
	}
}

@h Build graph.
The build graph for a language bundle is just a single node: you don't need to
build it at all.

=
void LanguageManager::build_graph(inbuild_copy *C) {
	Graphs::copy_vertex(C);
}
