[ExtensionBundleManager::] Extension Bundle Manager.

Claiming and creating copies of the kit genre: used for kits of precompiled
Inter code.

@h Genre definition.
The |extension_bundle_genre| can be summarised as follows.

=
void ExtensionBundleManager::start(void) {
	extension_bundle_genre = Genres::new(I"extensionbundle", I"extension", TRUE);
	Genres::place_in_class(extension_bundle_genre, 1);
	METHOD_ADD(extension_bundle_genre, GENRE_WRITE_WORK_MTID, ExtensionBundleManager::write_work);
	METHOD_ADD(extension_bundle_genre, GENRE_CLAIM_AS_COPY_MTID, ExtensionBundleManager::claim_as_copy);
	METHOD_ADD(extension_bundle_genre, GENRE_SEARCH_NEST_FOR_MTID, ExtensionBundleManager::search_nest_for);
	METHOD_ADD(extension_bundle_genre, GENRE_COPY_TO_NEST_MTID, ExtensionBundleManager::copy_to_nest);
	METHOD_ADD(extension_bundle_genre, GENRE_CONSTRUCT_GRAPH_MTID, ExtensionBundleManager::construct_graph);
	METHOD_ADD(extension_bundle_genre, GENRE_BUILDING_SOON_MTID, ExtensionBundleManager::building_soon);
	METHOD_ADD(extension_bundle_genre, GENRE_DOCUMENT_MTID, ExtensionBundleManager::document);
	METHOD_ADD(extension_bundle_genre, GENRE_READ_SOURCE_TEXT_FOR_MTID, ExtensionBundleManager::read_source_text_for);
	METHOD_ADD(extension_bundle_genre, GENRE_MODERNISE_MTID, ExtensionBundleManager::modernise);
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
inbuild_copy *ExtensionBundleManager::new_copy(text_stream *name, pathname *P,
	inbuild_nest *N, semantic_version_number apparent_V, int force_renaming) {
	if (eb_copy_cache == NULL) eb_copy_cache = Dictionaries::new(16, FALSE);
	TEMPORARY_TEXT(key)
	WRITE_TO(key, "%p", P);
	inbuild_copy *C = NULL;
	if (Dictionaries::find(eb_copy_cache, key))
		C = Dictionaries::read_value(eb_copy_cache, key);
	if (C == NULL) {
		inbuild_work *work = Works::new_raw(extension_bundle_genre,
			Str::duplicate(name),
			Str::duplicate(Pathnames::directory_name(Pathnames::up(P))));
		inbuild_edition *edition = Editions::new(work, VersionNumbers::null());
		C = Copies::new_in_path(edition, P, N);
		Extensions::scan(C);
		
		if ((force_renaming == FALSE) &&
			(VersionNumbers::ne(apparent_V, C->edition->version)))
			force_renaming = TRUE;

		if ((force_renaming == FALSE) &&
			(Str::ne(name, C->edition->work->title)))
			force_renaming = TRUE;

		if (force_renaming == TRUE) {
			TEMPORARY_TEXT(new_name)
			TEMPORARY_TEXT(new_version)
			WRITE_TO(new_version, "%v", &(C->edition->version));
			LOOP_THROUGH_TEXT(pos, new_version)
				if (Str::get(pos) == '.')
					Str::put(pos, '_');
			WRITE_TO(new_name, "%S-v%S.i7xd", C->edition->work->title, new_version);
			if (Extensions::rename_directory(P, new_name)) {
				Str::clear(key);
				WRITE_TO(key, "%p", P);
				apparent_V = C->edition->version;
				name = C->edition->work->title;
			}
			DISCARD_TEXT(new_name)
			DISCARD_TEXT(new_version)
		}

		Dictionaries::create(eb_copy_cache, key);
		Dictionaries::write_value(eb_copy_cache, key, C);
		if (VersionNumbers::is_null(apparent_V)) {
			if (Nests::get_tag(N) != INTERNAL_NEST_TAG) {
				TEMPORARY_TEXT(error_text)
				WRITE_TO(error_text,
					"an extension in directory format must have a directory name ending "
					"'-vN.i7xd', giving the version number: for example, "
					"'Advanced Algebra-v2_3_6.i7xd'");
				Copies::attach_error(C, CopyErrors::new_T(EXT_BAD_DIRNAME_CE, -1, error_text));
				DISCARD_TEXT(error_text)
			}
		} else if (VersionNumbers::ne(apparent_V, C->edition->version)) {
			TEMPORARY_TEXT(error_text)
			WRITE_TO(error_text,
				"the version number '%v' is not the one implied by the directory "
				"name '%S', which would be '%v'",
				&(C->edition->version), Pathnames::directory_name(P), &apparent_V);
			Copies::attach_error(C, CopyErrors::new_T(EXT_BAD_DIRNAME_CE, -1, error_text));
			DISCARD_TEXT(error_text)
		}
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
void ExtensionBundleManager::dismantle_name(text_stream *name,
	text_stream *to_title, text_stream *to_ext, semantic_version_number *to_V) {
	TEMPORARY_TEXT(ext)
	TEMPORARY_TEXT(title)
	int pos = Str::len(name) - 1, dotpos = -1;
	while (pos >= 0) {
		inchar32_t c = Str::get_at(name, pos);
		if (Platform::is_folder_separator(c)) break;
		if (c == '.') dotpos = pos;
		pos--;
	}
	if (dotpos >= 0) {
		Str::substr(ext, Str::at(name, dotpos+1), Str::end(name));
		Str::substr(title, Str::start(name), Str::at(name, dotpos));
	} else {
		WRITE_TO(title, "%S", name);		
	}
	semantic_version_number V = VersionNumbers::null();
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, title, U"(%c+)-v([0-9_]+)")) {
		Str::clear(title);
		WRITE_TO(title, "%S", mr.exp[0]);
		LOOP_THROUGH_TEXT(pos, mr.exp[1])
			if (Str::get(pos) == '_')
				Str::put(pos, '.');		
		V = VersionNumbers::from_text(mr.exp[1]);
	}
	Regexp::dispose_of(&mr);
	Str::copy(to_title, title);
	Str::copy(to_ext, ext);
	if (to_V) *to_V = V;
	DISCARD_TEXT(ext)
	DISCARD_TEXT(title)
}

inbuild_copy *ExtensionBundleManager::claim_folder_as_copy(pathname *P, inbuild_nest *N) {
	inbuild_copy *C = NULL;
	if (Directories::exists(P)) {
		filename *canary = Filenames::in(P, I"extension_metadata.json");
		TEMPORARY_TEXT(ext)
		TEMPORARY_TEXT(title)
		semantic_version_number V = VersionNumbers::null();
		ExtensionBundleManager::dismantle_name(Pathnames::directory_name(P), title, ext, &V);
		if ((Str::eq_insensitive(ext, I"i7xd")) || (TextFiles::exists(canary))) {
			if (Extensions::alternative_source_file(P) == NULL) {
				TEMPORARY_TEXT(error_text)
				WRITE_TO(error_text,
					"the extension directory '%S' does not contain any source text "
					"(which should be in a '.i7x' file inside a 'Source' subdirectory)",
					Pathnames::directory_name(P));
				Copies::attach_error(C, CopyErrors::new_T(EXT_BAD_DIRNAME_CE, -1, error_text));
				DISCARD_TEXT(error_text)				
			} else {
				int force_renaming = NOT_APPLICABLE;
				int save_repair_mode = repair_mode;
				if (Nests::get_tag(N) == MATERIALS_NEST_TAG) repair_mode = TRUE;
				if (repair_mode) force_renaming = FALSE;
				if (Str::eq_insensitive(ext, I"i7xd") == FALSE) {
					if (Nests::get_tag(N) == MATERIALS_NEST_TAG) {
						force_renaming = TRUE;
					} else {
						TEMPORARY_TEXT(error_text)
						WRITE_TO(error_text,
							"the extension directory '%S' needs to have the extension '.i7xd' added to its name",
							Pathnames::directory_name(P));
						Copies::attach_error(C, CopyErrors::new_T(EXT_BAD_DIRNAME_CE, -1, error_text));
						DISCARD_TEXT(error_text)				
					}
				}
				C = ExtensionBundleManager::new_copy(title, P, N, V, force_renaming);
				@<Police extraneous contents@>;
				repair_mode = save_repair_mode;
			}
		}
		DISCARD_TEXT(ext)
		DISCARD_TEXT(title)
	}
	return C;
}

@<Police extraneous contents@> =
	linked_list *L = Directories::listing(P);
	text_stream *entry;
	LOOP_OVER_LINKED_LIST(entry, text_stream, L) {
		if (Platform::is_folder_separator(Str::get_last_char(entry))) {
			TEMPORARY_TEXT(subdir)
			WRITE_TO(subdir, "%S", entry);
			Str::delete_last_character(subdir);
			if (Str::eq(subdir, I"Source")) {
				@<Police Source contents@>;
			} else if (Str::eq(subdir, I"Materials")) {
				@<Police Materials contents@>;
			} else if (Str::eq(subdir, I"Documentation")) {
				@<Police Documentation contents@>;
			} else if (Str::eq(subdir, I"RTPs")) {
				@<Police RTPs contents@>;
			} else {
				TEMPORARY_TEXT(error_text)
				WRITE_TO(error_text,
					"the extension directory '%S' contains a subdirectory called '%S', "
					"which I don't recognise",
					Pathnames::directory_name(P), subdir);
				Copies::attach_error(C, CopyErrors::new_T(EXT_RANEOUS_CE, -1, error_text));
				DISCARD_TEXT(error_text)				
			}
			DISCARD_TEXT(subdir)
		} else {
			if (Str::eq(entry, I"extension_metadata.json")) continue;
			TEMPORARY_TEXT(error_text)
			WRITE_TO(error_text,
				"the extension directory '%S' contains a file called '%S', "
				"which I don't recognise",
				Pathnames::directory_name(P), entry);
			Copies::attach_error(C, CopyErrors::new_T(EXT_RANEOUS_CE, -1, error_text));
			DISCARD_TEXT(error_text)				
		}
	}

@<Police Source contents@> =
	filename *canonical = Extensions::main_source_file(C);
	pathname *Q = Pathnames::down(P, subdir);
	linked_list *L = Directories::listing(Q);
	text_stream *entry;
	LOOP_OVER_LINKED_LIST(entry, text_stream, L) {
		if (Platform::is_folder_separator(Str::get_last_char(entry))) {
			TEMPORARY_TEXT(subdir)
			WRITE_TO(subdir, "%S", entry);
			Str::delete_last_character(subdir);
			TEMPORARY_TEXT(error_text)
			WRITE_TO(error_text,
				"the 'Source' subdirectory of the extension directory '%S' contains a "
				"further subdirectory called '%S', but should not have further subdirectories",
				Pathnames::directory_name(P), subdir);
			Copies::attach_error(C, CopyErrors::new_T(EXT_RANEOUS_CE, -1, error_text));
			DISCARD_TEXT(error_text)
			DISCARD_TEXT(subdir)
		} else {
			if (Str::eq(entry, Filenames::get_leafname(canonical))) continue;
			TEMPORARY_TEXT(error_text)
			WRITE_TO(error_text,
				"the 'Source' subdirectory of the extension directory '%S' contains a "
				"file called '%S', but should only contain the source text file '%S'",
				Pathnames::directory_name(P), entry, Filenames::get_leafname(canonical));
			Copies::attach_error(C, CopyErrors::new_T(EXT_RANEOUS_CE, -1, error_text));
			DISCARD_TEXT(error_text)				
		}
	}

@<Police Materials contents@> =
	pathname *Q = Pathnames::down(P, subdir);
	linked_list *L = Directories::listing(Q);
	text_stream *entry;
	LOOP_OVER_LINKED_LIST(entry, text_stream, L) {
		if (Platform::is_folder_separator(Str::get_last_char(entry))) {
			TEMPORARY_TEXT(subdir)
			WRITE_TO(subdir, "%S", entry);
			Str::delete_last_character(subdir);
			if (Str::eq(subdir, I"Data")) {
				;
			} else if (Str::eq(subdir, I"Figures")) {
				;
			} else if (Str::eq(subdir, I"Inter")) {
				;
			} else if (Str::eq(subdir, I"Sounds")) {
				;
			} else if (Str::eq(subdir, I"Templates")) {
				;
			} else if (Str::eq(subdir, I"Languages")) {
				;
			} else {
				TEMPORARY_TEXT(error_text)
				WRITE_TO(error_text,
					"the 'Materials' subdirectory of the extension directory '%S' contains a "
					"further subdirectory called '%S', but this is not one of the possibilities "
					"allowed",
					Pathnames::directory_name(P), subdir);
				Copies::attach_error(C, CopyErrors::new_T(EXT_RANEOUS_CE, -1, error_text));
				DISCARD_TEXT(error_text)
			}
			DISCARD_TEXT(subdir)
		} else {
			TEMPORARY_TEXT(error_text)
			WRITE_TO(error_text,
				"the 'Materials' subdirectory of the extension directory '%S' contains a "
				"file called '%S', but should not contain any files, only further subdirectories",
				Pathnames::directory_name(P), entry);
			Copies::attach_error(C, CopyErrors::new_T(EXT_RANEOUS_CE, -1, error_text));
			DISCARD_TEXT(error_text)				
		}
	}

@<Police Documentation contents@> =
	int doc_found = FALSE;
	pathname *Q = Pathnames::down(P, subdir);
	linked_list *L = Directories::listing(Q);
	text_stream *entry;
	LOOP_OVER_LINKED_LIST(entry, text_stream, L) {
		if (Platform::is_folder_separator(Str::get_last_char(entry))) {
			TEMPORARY_TEXT(subdir)
			WRITE_TO(subdir, "%S", entry);
			Str::delete_last_character(subdir);
			if (Str::eq(subdir, I"Examples")) {
				;
			} else if (Str::eq(subdir, I"Tests")) {
				;
			} else if (Str::eq(subdir, I"Images")) {
				;
			} else {
				TEMPORARY_TEXT(error_text)
				WRITE_TO(error_text,
					"the 'Documentation' subdirectory of the extension directory '%S' contains a "
					"further subdirectory called '%S', but this is not one of the possibilities "
					"allowed",
					Pathnames::directory_name(P), subdir);
				Copies::attach_error(C, CopyErrors::new_T(EXT_RANEOUS_CE, -1, error_text));
				DISCARD_TEXT(error_text)
			}
			DISCARD_TEXT(subdir)
		} else {
			if (Str::ends_with(entry, I".md")) { doc_found = TRUE; continue; }
			if (Str::eq(entry, I"contents.txt")) { doc_found = TRUE; continue; }
			if (Str::eq(entry, I"sitemap.txt")) { doc_found = TRUE; continue; }
			TEMPORARY_TEXT(error_text)
			WRITE_TO(error_text,
				"the 'Documentation' subdirectory of the extension directory '%S' contains a "
				"file called '%S', but I don't know what this would mean",
				Pathnames::directory_name(P), entry);
			Copies::attach_error(C, CopyErrors::new_T(EXT_RANEOUS_CE, -1, error_text));
			DISCARD_TEXT(error_text)				
		}
	}
	if (doc_found == FALSE) {
		TEMPORARY_TEXT(error_text)
		WRITE_TO(error_text,
			"the 'Documentation' subdirectory of the extension directory '%S' is optional, "
			"but if it does exist then it needs to contain a file called 'Documentation.md'",
			Pathnames::directory_name(P));
		Copies::attach_error(C, CopyErrors::new_T(METADATA_MALFORMED_CE, -1, error_text));
		DISCARD_TEXT(error_text)				
	}

@<Police RTPs contents@> =
	;

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
					ExtensionBundleManager::search_nest_for_r(Q, N, req, search_results, FALSE);
				}
			}
		}
	} else {
		ExtensionBundleManager::search_nest_for_r(P, N, req, search_results, TRUE);
	}
}

void ExtensionBundleManager::search_nest_for_r(pathname *P, inbuild_nest *N,
	inbuild_requirement *req, linked_list *search_results, int recurse) {
	linked_list *L = Directories::listing(P);
	text_stream *entry;
	LOOP_OVER_LINKED_LIST(entry, text_stream, L) {
		if (Platform::is_folder_separator(Str::get_last_char(entry))) {
			Str::delete_last_character(entry);
			pathname *Q = Pathnames::down(P, entry);
			inbuild_copy *C = ExtensionBundleManager::claim_folder_as_copy(Q, N);
			if ((C) && (Requirements::meets(C->edition, req))) {
				Nests::add_search_result(search_results, N, C, req);
			} else if ((recurse) && (Str::ne(entry, I"Reserved")) && (Str::ne(entry, I"Source"))) {
				ExtensionBundleManager::search_nest_for_r(Q, N, req, search_results, TRUE);
			}
		}
	}
}

@h Copying.
Now the task is to copy an extension bundle into place in a nest. Since it is a
directory, we need to |rsync| it.

=
pathname *ExtensionBundleManager::pathname_in_nest(inbuild_nest *N, inbuild_edition *E) {
	pathname *EX = ExtensionManager::path_within_nest(N);
	TEMPORARY_TEXT(leaf)
	Editions::write_canonical_leaf(leaf, E);
	pathname *P = Pathnames::down(Pathnames::down(EX, E->work->author_name), leaf);
	DISCARD_TEXT(leaf)
	return P;
}

int ExtensionBundleManager::copy_to_nest(inbuild_genre *gen, inbuild_copy *C, inbuild_nest *N,
	int syncing, build_methodology *meth) {
	pathname *dest_eb = ExtensionBundleManager::pathname_in_nest(N, C->edition);
	filename *dest_eb_metadata = Filenames::in(dest_eb, I"extension_metadata.json");
	if (TextFiles::exists(dest_eb_metadata)) {
		if (syncing == FALSE) { Copies::overwrite_error(C, N); return 1; }
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
			Pathnames::create_in_file_system(Pathnames::up(dest_eb));
			Pathnames::create_in_file_system(dest_eb);
		}
	}
	int rv = 0;
	if (meth->methodology == DRY_RUN_METHODOLOGY) {
		TEMPORARY_TEXT(command)
		WRITE_TO(command, "rsync -a --delete ");
		Shell::quote_path(command, C->location_if_path);
		Shell::quote_path(command, dest_eb);
		WRITE_TO(STDOUT, "%S\n", command);
		DISCARD_TEXT(command)
	} else {
		rv = Pathnames::rsync(C->location_if_path, dest_eb);
	}
	return rv;
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

@h Source text.

=
void ExtensionBundleManager::read_source_text_for(inbuild_genre *G, inbuild_copy *C) {
	Extensions::read_source_text_for(ExtensionBundleManager::from_copy(C));
}

@h Documentation.

=
void ExtensionBundleManager::document(inbuild_genre *gen, inbuild_copy *C, pathname *dest,
	filename *sitemap) {
	Extensions::document(Extensions::from_copy(C), dest, sitemap);
}

@h Modernisation.

=
int ExtensionBundleManager::modernise(inbuild_genre *gen, inbuild_copy *C, text_stream *OUT) {
	return Extensions::modernise(Extensions::from_copy(C), OUT);
}
