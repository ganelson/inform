[KitManager::] Kit Manager.

A kit is a combination of Inter code with an Inform 7 extension.

@h Genre definition.

=
inbuild_genre *kit_genre = NULL;
void KitManager::start(void) {
	kit_genre = Genres::new(I"kit");
	METHOD_ADD(kit_genre, GENRE_WRITE_WORK_MTID, KitManager::write_work);
	METHOD_ADD(kit_genre, GENRE_CLAIM_AS_COPY_MTID, KitManager::claim_as_copy);
	METHOD_ADD(kit_genre, GENRE_SEARCH_NEST_FOR_MTID, KitManager::search_nest_for);
	METHOD_ADD(kit_genre, GENRE_COPY_TO_NEST_MTID, KitManager::copy_to_nest);
	METHOD_ADD(kit_genre, GENRE_GO_OPERATIONAL_MTID, KitManager::go_operational);
}

void KitManager::write_work(inbuild_genre *gen, OUTPUT_STREAM, inbuild_work *work) {
	WRITE("%S", work->title);
}

@ Kits live in the |Inter| subdirectory of a nest:

=
pathname *KitManager::path_within_nest(inbuild_nest *N) {
	if (N == NULL) internal_error("no nest");
	return Pathnames::subfolder(N->location, I"Inter");
}

@ Kit copies are annotated with a structure called an |inform_kit|,
which stores data about extensions used by the Inform compiler.

=
inform_kit *KitManager::from_copy(inbuild_copy *C) {
	if ((C) && (C->edition->work->genre == kit_genre)) {
		return RETRIEVE_POINTER_inform_kit(C->content);
	}
	return NULL;
}

dictionary *kit_copy_cache = NULL;
inbuild_copy *KitManager::new_copy(text_stream *name, pathname *P) {
	if (kit_copy_cache == NULL) kit_copy_cache = Dictionaries::new(16, FALSE);
	TEMPORARY_TEXT(key);
	WRITE_TO(key, "%p", P);
	inbuild_copy *C = NULL;
	if (Dictionaries::find(kit_copy_cache, key))
		C = Dictionaries::read_value(kit_copy_cache, key);
	if (C == NULL) {
		inform_kit *K = Kits::new_ik(name, P);
		inbuild_work *work = Works::new_raw(kit_genre, Str::duplicate(name), NULL);
		inbuild_edition *edition = Copies::edition(work, K->version);
		C = Copies::new_in_path(edition, P, STORE_POINTER_inform_kit(K));
		K->as_copy = C;
		Dictionaries::create(kit_copy_cache, key);
		Dictionaries::write_value(kit_copy_cache, key, C);
	}
	DISCARD_TEXT(key);
	return C;
}

@h Claiming.
Here |arg| is a textual form of a filename or pathname, such as may have been
supplied at the command line; |ext| is a substring of it, and is its extension
(e.g., |jpg| if |arg| is |Geraniums.jpg|), or is empty if there isn't one;
|directory_status| is true if we know for some reason that this is a directory
not a file, false if we know the reverse, and otherwise not applicable.

A kit needs to be a directory whose name ends in |Kit|, and which contains
a valid metadata file.

=
void KitManager::claim_as_copy(inbuild_genre *gen, inbuild_copy **C,
	text_stream *arg, text_stream *ext, int directory_status) {
	if (directory_status == FALSE) return;
		int kitpos = Str::len(arg) - 3;
	if ((kitpos >= 0) && (Str::get_at(arg, kitpos) == 'K') &&
		(Str::get_at(arg, kitpos+1) == 'i') &&
		(Str::get_at(arg, kitpos+2) == 't')) {
		pathname *P = Pathnames::from_text(arg);
		*C = KitManager::claim_folder_as_copy(P);
	}
}

inbuild_copy *KitManager::claim_folder_as_copy(pathname *P) {
	filename *canary = Filenames::in_folder(P, I"kit_metadata.txt");
	if (TextFiles::exists(canary)) {
		inbuild_copy *C = KitManager::new_copy(Pathnames::directory_name(P), P);
		KitManager::build_vertex(C);
		Works::add_to_database(C->edition->work, CLAIMED_WDBC);
		return C;
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
	scan_directory *D = Directories::open(P);
	if (D) {
		TEMPORARY_TEXT(LEAFNAME);
		while (Directories::next(D, LEAFNAME)) {
			if (Str::get_last_char(LEAFNAME) == FOLDER_SEPARATOR) {
				Str::delete_last_character(LEAFNAME);
				pathname *Q = Pathnames::subfolder(P, LEAFNAME);
				inbuild_copy *C = KitManager::claim_folder_as_copy(Q);
				if ((C) && (Requirements::meets(C->edition, req))) {
					Nests::add_search_result(search_results, N, C, req);
				}
			}
		}
		DISCARD_TEXT(LEAFNAME);
		Directories::close(D);
	}
}

@h Copying.
Now the task is to copy a kit into place in a nest. Since a kit is a folder,
we need to |rsync| it.

=
pathname *KitManager::pathname_in_nest(inbuild_nest *N, inbuild_work *W) {
	return Pathnames::subfolder(KitManager::path_within_nest(N), W->title);
}

void KitManager::copy_to_nest(inbuild_genre *gen, inbuild_copy *C, inbuild_nest *N,
	int syncing, build_methodology *meth) {
	pathname *dest_kit = KitManager::pathname_in_nest(N, C->edition->work);
	filename *dest_kit_metadata = Filenames::in_folder(dest_kit, I"kit_metadata.txt");
	if (TextFiles::exists(dest_kit_metadata)) {
		if (syncing == FALSE) { Nests::overwrite_error(N, C); return; }
	} else {
		if (meth->methodology == DRY_RUN_METHODOLOGY) {
			TEMPORARY_TEXT(command);
			WRITE_TO(command, "mkdir -p ");
			Shell::quote_path(command, dest_kit);
			WRITE_TO(STDOUT, "%S\n", command);
			DISCARD_TEXT(command);
		} else {
			Pathnames::create_in_file_system(N->location);
			Pathnames::create_in_file_system(KitManager::path_within_nest(N));
			Pathnames::create_in_file_system(dest_kit);
		}
	}
	if (meth->methodology == DRY_RUN_METHODOLOGY) {
		TEMPORARY_TEXT(command);
		WRITE_TO(command, "rsync -a --delete ");
		Shell::quote_path(command, C->location_if_path);
		Shell::quote_path(command, dest_kit);
		WRITE_TO(STDOUT, "%S\n", command);
		DISCARD_TEXT(command);
	} else {
		Pathnames::rsync(C->location_if_path, dest_kit);
	}
}

@h Build graph.
The build graph for a kit is quite extensive, since a kit contains Inter
binaries for four different architectures; and each of those has a
dependency on every section file of the web of Inform 6 source for the kit.
If there are $S$ sections then the graph has $S+5$ vertices and $4(S+1)$ edges.

=
void KitManager::build_vertex(inbuild_copy *C) {
	Graphs::copy_vertex(C);
}

void KitManager::go_operational(inbuild_genre *G, inbuild_copy *C) {
	Kits::construct_graph(KitManager::from_copy(C));
}

typedef struct kit_contents_section_state {
	struct linked_list *sects; /* of |text_stream| */
	int active;
} kit_contents_section_state;

void KitManager::read_contents(text_stream *text, text_file_position *tfp, void *state) {
	kit_contents_section_state *CSS = (kit_contents_section_state *) state;
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, text, L"Sections"))
		CSS->active = TRUE;
	if ((Regexp::match(&mr, text, L" (%c+)")) && (CSS->active)) {
		WRITE_TO(mr.exp[0], ".i6t");
		ADD_TO_LINKED_LIST(Str::duplicate(mr.exp[0]), text_stream, CSS->sects);
	}
	Regexp::dispose_of(&mr);
}
