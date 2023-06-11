[KitManager::] Kit Manager.

Claiming and creating copies of the kit genre: used for kits of precompiled
Inter code.

@h Genre definition.
The |kit_genre| can be summarised as follows. Kits consist of directories,
containing metadata in |D/kit_metadata.json|, but which are also valid Inweb
webs of Inform 6 source text. They are recognised by having directory names
ending in |Kit|, and by having a metadata file in place. They are stored in
nests, in |N/Inter/Title-vVersion|. Their build graphs are quite extensive,
with build edges to Inter binaries for each architecture with which they
are compatible, and use edges to extensions or other kits as laid out in
the metadata file.

=
void KitManager::start(void) {
	kit_genre = Genres::new(I"kit", TRUE);
	METHOD_ADD(kit_genre, GENRE_WRITE_WORK_MTID, KitManager::write_work);
	METHOD_ADD(kit_genre, GENRE_CLAIM_AS_COPY_MTID, KitManager::claim_as_copy);
	METHOD_ADD(kit_genre, GENRE_SEARCH_NEST_FOR_MTID, KitManager::search_nest_for);
	METHOD_ADD(kit_genre, GENRE_COPY_TO_NEST_MTID, KitManager::copy_to_nest);
	METHOD_ADD(kit_genre, GENRE_CONSTRUCT_GRAPH_MTID, KitManager::construct_graph);
	METHOD_ADD(kit_genre, GENRE_BUILDING_SOON_MTID, KitManager::building_soon);
}

void KitManager::write_work(inbuild_genre *gen, OUTPUT_STREAM, inbuild_work *work) {
	WRITE("%S", work->title);
}

@ Kits live in the |Inter| subdirectory of a nest:

=
pathname *KitManager::path_within_nest(inbuild_nest *N) {
	if (N == NULL) internal_error("no nest");
	return Pathnames::down(N->location, I"Inter");
}

@ Kit copies are annotated with a structure called an |inform_kit|,
which stores data about extensions used by the Inform compiler.

=
inform_kit *KitManager::from_copy(inbuild_copy *C) {
	if ((C) && (C->edition->work->genre == kit_genre)) {
		return RETRIEVE_POINTER_inform_kit(C->metadata);
	}
	return NULL;
}

dictionary *kit_copy_cache = NULL;
inbuild_copy *KitManager::new_copy(text_stream *name, pathname *P, inbuild_nest *N) {
	if (kit_copy_cache == NULL) kit_copy_cache = Dictionaries::new(16, FALSE);
	TEMPORARY_TEXT(key)
	WRITE_TO(key, "%p", P);
	inbuild_copy *C = NULL;
	if (Dictionaries::find(kit_copy_cache, key))
		C = Dictionaries::read_value(kit_copy_cache, key);
	if (C == NULL) {
		inbuild_work *work = Works::new_raw(kit_genre, Str::duplicate(name), NULL);
		inbuild_edition *edition = Editions::new(work, VersionNumbers::null());
		C = Copies::new_in_path(edition, P, N);
		Kits::scan(C);
		Dictionaries::create(kit_copy_cache, key);
		Dictionaries::write_value(kit_copy_cache, key, C);
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

A kit needs to be a directory whose name ends in |Kit|, perhaps with a semver
appended to it, and which contains a valid metadata file.

=
void KitManager::claim_as_copy(inbuild_genre *gen, inbuild_copy **C,
	text_stream *arg, text_stream *ext, int directory_status) {
	if (directory_status == FALSE) return;
	if (KitManager::name_len(arg) > 0) {
		pathname *P = Pathnames::from_text(arg);
		*C = KitManager::claim_folder_as_copy(P, NULL);
	}
}

@ So, for example, given |Architecture32Kit-v10_1_0-beta+6V20| this returns
17, the length of the actual name part |Architecture32Kit|.

=
int KitManager::name_len(text_stream *arg) {
	for (int i=0; i<Str::len(arg); i++)
		if ((Str::get_at(arg, i) == 'K') &&
			(Str::get_at(arg, i+1) == 'i') &&
			(Str::get_at(arg, i+2) == 't'))
			if ((Str::get_at(arg, i+3) == 0) ||
				((Str::get_at(arg, i+3) == '-') &&
				(Str::get_at(arg, i+4) == 'v') &&
				(Characters::isdigit(Str::get_at(arg, i+5)))))
				return i+3;
	return -1;
}

@ And so we truncate to that length when turning the directory name into the
copy name.

=
inbuild_copy *KitManager::claim_folder_as_copy(pathname *P, inbuild_nest *N) {
	filename *canary = Filenames::in(P, I"kit_metadata.json");
	if (TextFiles::exists(canary)) {
		text_stream *name = Str::duplicate(Pathnames::directory_name(P));
		int L = KitManager::name_len(name);
		if (L > 0) Str::truncate(name, L);
		return KitManager::new_copy(name, P, N);
	}
	return NULL;
}

@h Searching.
Here we look through a nest to find all kits matching the supplied
requirements.

=
void KitManager::search_nest_for(inbuild_genre *gen, inbuild_nest *N,
	inbuild_requirement *req, linked_list *search_results) {
	if ((req->work->genre) && (req->work->genre != kit_genre)) return;
	pathname *P = KitManager::path_within_nest(N);
	linked_list *L = Directories::listing(P);
	text_stream *entry;
	LOOP_OVER_LINKED_LIST(entry, text_stream, L) {
		if (Platform::is_folder_separator(Str::get_last_char(entry))) {
			Str::delete_last_character(entry);
			pathname *Q = Pathnames::down(P, entry);
			inbuild_copy *C = KitManager::claim_folder_as_copy(Q, N);
			if ((C) && (Requirements::meets(C->edition, req))) {
				Nests::add_search_result(search_results, N, C, req);
			}
		}
	}
}

@h Copying.
Now the task is to copy a kit into place in a nest. Since a kit is a directory,
we need to |rsync| it.

=
pathname *KitManager::pathname_in_nest(inbuild_nest *N, inbuild_edition *E) {
	TEMPORARY_TEXT(leaf)
	Editions::write_canonical_leaf(leaf, E);
	pathname *P = Pathnames::down(KitManager::path_within_nest(N), leaf);
	DISCARD_TEXT(leaf)
	return P;
}

void KitManager::copy_to_nest(inbuild_genre *gen, inbuild_copy *C, inbuild_nest *N,
	int syncing, build_methodology *meth) {
	pathname *dest_kit = KitManager::pathname_in_nest(N, C->edition);
	filename *dest_kit_metadata = Filenames::in(dest_kit, I"kit_metadata.json");
	if (TextFiles::exists(dest_kit_metadata)) {
		if (syncing == FALSE) { Copies::overwrite_error(C, N); return; }
	} else {
		if (meth->methodology == DRY_RUN_METHODOLOGY) {
			TEMPORARY_TEXT(command)
			WRITE_TO(command, "mkdir -p ");
			Shell::quote_path(command, dest_kit);
			WRITE_TO(STDOUT, "%S\n", command);
			DISCARD_TEXT(command)
		} else {
			Pathnames::create_in_file_system(N->location);
			Pathnames::create_in_file_system(KitManager::path_within_nest(N));
			Pathnames::create_in_file_system(dest_kit);
		}
	}
	if (meth->methodology == DRY_RUN_METHODOLOGY) {
		TEMPORARY_TEXT(command)
		WRITE_TO(command, "rsync -a --delete ");
		Shell::quote_path(command, C->location_if_path);
		Shell::quote_path(command, dest_kit);
		WRITE_TO(STDOUT, "%S\n", command);
		DISCARD_TEXT(command)
	} else {
		Pathnames::rsync(C->location_if_path, dest_kit);
	}
}

@h Build graph.

=
void KitManager::building_soon(inbuild_genre *gen, inbuild_copy *C, build_vertex **V) {
	*V = C->vertex;
}

void KitManager::construct_graph(inbuild_genre *G, inbuild_copy *C) {
	Kits::construct_graph(KitManager::from_copy(C));
}
