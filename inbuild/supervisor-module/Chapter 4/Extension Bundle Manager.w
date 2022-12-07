[ExtensionBundleManager::] Extension Bundle Manager.

Claiming and creating copies of the kit genre: used for kits of precompiled
Inter code.

@h Genre definition.
The |extension_bundle_genre| can be summarised as follows. Kits consist of directories,
containing metadata in |D/kit_metadata.json|, but which are also valid Inweb
webs of Inform 6 source text. They are recognised by having directory names
ending in |Kit|, and by having a metadata file in place. They are stored in
nests, in |N/Inter/Title-vVersion|. Their build graphs are quite extensive,
with build edges to Inter binaries for each architecture with which they
are compatible, and use edges to extensions or other kits as laid out in
the metadata file.

=
void ExtensionBundleManager::start(void) {
	extension_bundle_genre = Genres::new(I"extensionbundle", TRUE);
	Genres::place_in_class(extension_bundle_genre, 1);
	METHOD_ADD(extension_bundle_genre, GENRE_WRITE_WORK_MTID, ExtensionBundleManager::write_work);
	METHOD_ADD(extension_bundle_genre, GENRE_CLAIM_AS_COPY_MTID, ExtensionBundleManager::claim_as_copy);
	METHOD_ADD(extension_bundle_genre, GENRE_SEARCH_NEST_FOR_MTID, ExtensionBundleManager::search_nest_for);
	METHOD_ADD(extension_bundle_genre, GENRE_COPY_TO_NEST_MTID, ExtensionBundleManager::copy_to_nest);
	METHOD_ADD(extension_bundle_genre, GENRE_CONSTRUCT_GRAPH_MTID, ExtensionBundleManager::construct_graph);
	METHOD_ADD(extension_bundle_genre, GENRE_BUILDING_SOON_MTID, ExtensionBundleManager::building_soon);
}

void ExtensionBundleManager::write_work(inbuild_genre *gen, OUTPUT_STREAM, inbuild_work *work) {
	WRITE("%S", work->title);
}

@ Extensions live in their namesake subdirectory of a nest:

=
pathname *ExtensionBundleManager::path_within_nest(inbuild_nest *N) {
	if (N == NULL) internal_error("no nest");
	return Pathnames::down(N->location, I"Extensions");
}

@ Extension copies are annotated with a structure called an |inform_extension|,
which stores data about extensions used by the Inform compiler.

=
inform_extension *ExtensionBundleManager::from_copy(inbuild_copy *C) {
	if ((C) && (C->edition->work->genre == extension_bundle_genre)) {
		return RETRIEVE_POINTER_inform_extension(C->metadata);
	}
	return NULL;
}

dictionary *eb_copy_cache = NULL;
inbuild_copy *ExtensionBundleManager::new_copy(text_stream *name, pathname *P, inbuild_nest *N) {
	if (eb_copy_cache == NULL) eb_copy_cache = Dictionaries::new(16, FALSE);
	TEMPORARY_TEXT(key)
	WRITE_TO(key, "%p", P);
	inbuild_copy *C = NULL;
	if (Dictionaries::find(eb_copy_cache, key))
		C = Dictionaries::read_value(eb_copy_cache, key);
	if (C == NULL) {
		inbuild_work *work = Works::new_raw(extension_bundle_genre,
			Str::duplicate(Pathnames::directory_name(P)),
			Str::duplicate(Pathnames::directory_name(Pathnames::up(P))));
		inbuild_edition *edition = Editions::new(work, VersionNumbers::null());
		C = Copies::new_in_path(edition, P, N);
		Extensions::scan(C);
		Dictionaries::create(eb_copy_cache, key);
		Dictionaries::write_value(eb_copy_cache, key, C);
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

An extension bundle can be recognised by containing a valid metadata file.

=
void ExtensionBundleManager::claim_as_copy(inbuild_genre *gen, inbuild_copy **C,
	text_stream *arg, text_stream *ext, int directory_status) {
	if (directory_status == FALSE) return;
	pathname *P = Pathnames::from_text(arg);
	*C = ExtensionBundleManager::claim_folder_as_copy(P, NULL);
}

@ And so we truncate to that length when turning the directory name into the
copy name.

=
inbuild_copy *ExtensionBundleManager::claim_folder_as_copy(pathname *P, inbuild_nest *N) {
	filename *canary = Filenames::in(P, I"extension_metadata.json");
	if (TextFiles::exists(canary)) {
		text_stream *name = Str::duplicate(Pathnames::directory_name(P));
		return ExtensionBundleManager::new_copy(name, P, N);
	}
	return NULL;
}

@h Searching.
Here we look through a nest to find all extension bundles:

=
void ExtensionBundleManager::search_nest_for(inbuild_genre *gen, inbuild_nest *N,
	inbuild_requirement *req, linked_list *search_results) {
	if ((req->work->genre) &&
		((req->work->genre != extension_bundle_genre) && (req->work->genre != extension_genre)))
		return;
	pathname *P = ExtensionManager::path_within_nest(N);
	if (Str::len(req->work->author_name) > 0) {
		linked_list *L = Directories::listing(P);
		text_stream *entry;
		LOOP_OVER_LINKED_LIST(entry, text_stream, L) {
			if (Platform::is_folder_separator(Str::get_last_char(entry))) {
				Str::delete_last_character(entry);
				if ((Str::ne(entry, I"Reserved")) &&
					(Str::eq_insensitive(entry, req->work->author_name))) {
					pathname *Q = Pathnames::down(P, entry);
					ExtensionBundleManager::search_nest_for_r(Q, N, req, search_results);
				}
			}
		}
	} else {
		ExtensionBundleManager::search_nest_for_r(P, N, req, search_results);
	}
}

void ExtensionBundleManager::search_nest_for_r(pathname *P, inbuild_nest *N,
	inbuild_requirement *req, linked_list *search_results) {
	linked_list *L = Directories::listing(P);
	text_stream *entry;
	LOOP_OVER_LINKED_LIST(entry, text_stream, L) {
		if (Platform::is_folder_separator(Str::get_last_char(entry))) {
			Str::delete_last_character(entry);
			pathname *Q = Pathnames::down(P, entry);
			inbuild_copy *C = ExtensionBundleManager::claim_folder_as_copy(Q, N);
			if ((C) && (Requirements::meets(C->edition, req))) {
				Nests::add_search_result(search_results, N, C, req);
			}
		}
	}
}

@h Copying.
Now the task is to copy an extension bundle into place in a nest. Since it is a
directory, we need to |rsync| it.

=
pathname *ExtensionBundleManager::pathname_in_nest(inbuild_nest *N, inbuild_edition *E) {
	TEMPORARY_TEXT(leaf)
	Editions::write_canonical_leaf(leaf, E);
	pathname *P = Pathnames::down(ExtensionBundleManager::path_within_nest(N), leaf);
	DISCARD_TEXT(leaf)
	return P;
}

void ExtensionBundleManager::copy_to_nest(inbuild_genre *gen, inbuild_copy *C, inbuild_nest *N,
	int syncing, build_methodology *meth) {
	pathname *dest_eb = ExtensionBundleManager::pathname_in_nest(N, C->edition);
	filename *dest_eb_metadata = Filenames::in(dest_eb, I"extension_metadata.json");
	if (TextFiles::exists(dest_eb_metadata)) {
		if (syncing == FALSE) { Copies::overwrite_error(C, N); return; }
	} else {
		if (meth->methodology == DRY_RUN_METHODOLOGY) {
			TEMPORARY_TEXT(command)
			WRITE_TO(command, "mkdir -p ");
			Shell::quote_path(command, dest_eb);
			WRITE_TO(STDOUT, "%S\n", command);
			DISCARD_TEXT(command)
		} else {
			Pathnames::create_in_file_system(N->location);
			Pathnames::create_in_file_system(ExtensionBundleManager::path_within_nest(N));
			Pathnames::create_in_file_system(dest_eb);
		}
	}
	if (meth->methodology == DRY_RUN_METHODOLOGY) {
		TEMPORARY_TEXT(command)
		WRITE_TO(command, "rsync -a --delete ");
		Shell::quote_path(command, C->location_if_path);
		Shell::quote_path(command, dest_eb);
		WRITE_TO(STDOUT, "%S\n", command);
		DISCARD_TEXT(command)
	} else {
		Pathnames::rsync(C->location_if_path, dest_eb);
	}
}

@h Build graph.

=
void ExtensionBundleManager::building_soon(inbuild_genre *gen, inbuild_copy *C,
	build_vertex **V) {
	*V = C->vertex;
}

void ExtensionBundleManager::construct_graph(inbuild_genre *G, inbuild_copy *C) {
	Extensions::construct_graph(ExtensionBundleManager::from_copy(C));
}
