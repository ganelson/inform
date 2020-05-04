[ExtensionManager::] Extension Manager.

Claiming and creating copies of the extension genre: used for Inform 7
extensions.

@h Genre definition.
The |extension_genre| can be summarised as follows. Copies consist of single
files. These are recognised by having the filename extension |.i7x|. They are
stored in nests, in |N/Extensions/Author/Title-vVersion.i7x|. Their build
graphs are a single vertex with no build edges, but with use edges to any
further extensions which they Include.

It may seem surprising that we do not provide a |GENRE_CONSTRUCT_GRAPH_MTID|
method. This is for efficiency reasons: we don't want to read and parse the
source text of every extension we ever see, and that's what would be needed
to make the graphs of every such extension. Instead we build out the graph
later on, as needed, just for extensions of interest: see below.

@ =
void ExtensionManager::start(void) {
	extension_genre = Genres::new(I"extension", TRUE);
	METHOD_ADD(extension_genre, GENRE_WRITE_WORK_MTID, ExtensionManager::write_work);
	METHOD_ADD(extension_genre, GENRE_CLAIM_AS_COPY_MTID, ExtensionManager::claim_as_copy);
	METHOD_ADD(extension_genre, GENRE_SEARCH_NEST_FOR_MTID, ExtensionManager::search_nest_for);
	METHOD_ADD(extension_genre, GENRE_COPY_TO_NEST_MTID, ExtensionManager::copy_to_nest);
	METHOD_ADD(extension_genre, GENRE_READ_SOURCE_TEXT_FOR_MTID, ExtensionManager::read_source_text_for);
	METHOD_ADD(extension_genre, GENRE_BUILDING_SOON_MTID, ExtensionManager::building_soon);
}

void ExtensionManager::write_work(inbuild_genre *gen, OUTPUT_STREAM, inbuild_work *work) {
	WRITE("%X", work);
}

@ Extensions live in their namesake subdirectory of a nest:

=
pathname *ExtensionManager::path_within_nest(inbuild_nest *N) {
	if (N == NULL) internal_error("no nest");
	return Pathnames::down(N->location, I"Extensions");
}

@ Extension copies are annotated with a structure called an |inform_extension|,
which stores data about extensions used by the Inform compiler.

=
inform_extension *ExtensionManager::from_copy(inbuild_copy *C) {
	if ((C) && (C->edition->work->genre == extension_genre)) {
		return RETRIEVE_POINTER_inform_extension(C->metadata);
	}
	return NULL;
}

dictionary *ext_copy_cache = NULL;
inbuild_copy *ExtensionManager::new_copy(filename *F) {
	if (ext_copy_cache == NULL) ext_copy_cache = Dictionaries::new(16, FALSE);
	TEMPORARY_TEXT(key);
	WRITE_TO(key, "%f", F);
	inbuild_copy *C = NULL;
	if (Dictionaries::find(ext_copy_cache, key))
		C = Dictionaries::read_value(ext_copy_cache, key);
	if (C == NULL) {
		C = Copies::new_in_file(
				Editions::new(
					Works::new(extension_genre, I"Untitled", I"Anonymous"),
					VersionNumbers::null()),
				F);
		Extensions::scan(C);
		if (Works::is_standard_rules(C->edition->work))
			Extensions::make_standard(ExtensionManager::from_copy(C));
		Dictionaries::create(ext_copy_cache, key);
		Dictionaries::write_value(ext_copy_cache, key, C);
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

An extension, for us, needs to be a file with extension |i7x|, but it needs
also to scan properly -- which means the top line of the file has to be right.
So we'll open it and look.

=
void ExtensionManager::claim_as_copy(inbuild_genre *gen, inbuild_copy **C,
	text_stream *arg, text_stream *ext, int directory_status) {
	if (directory_status == TRUE) return;
	if (Str::eq_insensitive(ext, I"i7x")) {
		filename *F = Filenames::from_text(arg);
		*C = ExtensionManager::claim_file_as_copy(F);
	}
}

inbuild_copy *ExtensionManager::claim_file_as_copy(filename *F) {
	if (TextFiles::exists(F) == FALSE) return NULL;
	inbuild_copy *C = ExtensionManager::new_copy(F);
	Works::add_to_database(C->edition->work, CLAIMED_WDBC);
	return C;
}

@h Searching.
Here we look through a nest to find all extensions matching the supplied
requirements.

For efficiency's sake, since the nest could contain many hundreds of
extensions, we narrow down to the author's subfolder if a specific
author is required.

Nobody should any longer be storing extension files without the file
extension |.i7x|, but this was allowed in the early days of Inform 7,
so we'll quietly allow for it.

=
void ExtensionManager::search_nest_for(inbuild_genre *gen, inbuild_nest *N,
	inbuild_requirement *req, linked_list *search_results) {
	if ((req->work->genre) && (req->work->genre != extension_genre)) return;
	pathname *P = ExtensionManager::path_within_nest(N);
	if (Str::len(req->work->author_name) > 0) {
		pathname *Q = Pathnames::down(P, req->work->author_name);
		ExtensionManager::search_nest_for_r(Q, N, req, search_results);
	} else {
		ExtensionManager::search_nest_for_r(P, N, req, search_results);
	}
}

void ExtensionManager::search_nest_for_r(pathname *P, inbuild_nest *N,
	inbuild_requirement *req, linked_list *search_results) {
	scan_directory *D = Directories::open(P);
	if (D) {
		TEMPORARY_TEXT(LEAFNAME);
		while (Directories::next(D, LEAFNAME)) {
			if (Str::get_last_char(LEAFNAME) == FOLDER_SEPARATOR) {
				Str::delete_last_character(LEAFNAME);
				if (Str::ne(LEAFNAME, I"Reserved")) {
					pathname *Q = Pathnames::down(P, LEAFNAME);
					ExtensionManager::search_nest_for_r(Q, N, req, search_results);
				}
			} else {
				filename *F = Filenames::in(P, LEAFNAME);
				ExtensionManager::search_nest_for_single_file(F, N, req, search_results);
			}
		}
		DISCARD_TEXT(LEAFNAME);
		Directories::close(D);
	}
}

void ExtensionManager::search_nest_for_single_file(filename *F, inbuild_nest *N,
	inbuild_requirement *req, linked_list *search_results) {
	inbuild_copy *C = ExtensionManager::claim_file_as_copy(F);
	if ((C) && (Requirements::meets(C->edition, req))) {
		Nests::add_search_result(search_results, N, C, req);
	}
}

@h Copying.
Now the task is to copy an extension into place in a nest. This is easy,
since an extension is a single file; to sync, we just overwrite.

=
void ExtensionManager::copy_to_nest(inbuild_genre *gen, inbuild_copy *C, inbuild_nest *N,
	int syncing, build_methodology *meth) {
	pathname *E = ExtensionManager::path_within_nest(N);
	TEMPORARY_TEXT(leaf);
	Editions::write_canonical_leaf(leaf, C->edition);
	WRITE_TO(leaf, ".i7x");
	filename *F = Filenames::in(
		Pathnames::down(E, C->edition->work->author_name), leaf);
	DISCARD_TEXT(leaf);

	if (TextFiles::exists(F)) {
		if (syncing == FALSE) { Copies::overwrite_error(C, N); return; }
	} else {
		if (meth->methodology == DRY_RUN_METHODOLOGY) {
			TEMPORARY_TEXT(command);
			WRITE_TO(command, "mkdir -p ");
			Shell::quote_path(command, Filenames::up(F));
			WRITE_TO(STDOUT, "%S\n", command);
			DISCARD_TEXT(command);
		} else {
			Pathnames::create_in_file_system(N->location);
			Pathnames::create_in_file_system(Pathnames::down(N->location, I"Extensions"));
			Pathnames::create_in_file_system(Filenames::up(F));
		}
	}

	TEMPORARY_TEXT(command);
	WRITE_TO(command, "cp -f ");
	Shell::quote_file(command, C->location_if_file);
	Shell::quote_file(command, F);
	BuildSteps::shell(command, meth);
	DISCARD_TEXT(command);
}

@h Build graph.
As far as building goes, the build graph for an extension is just a single vertex: 
you don't need to build an extension at all. But it may well have use edges,
thanks to including other extensions, and because of that we have to read the
source text before we can do anything with the graph.

We don't do this at the going operational stage because that would be
inefficient and might cause VM-related problems -- it would mean that many
extraneous extensions, discovered only when scanning some directory, would
be read in as source text; and some of those might not be compatible with
the current VM settings.

We therefore generate the build graph only on demand.

=
void ExtensionManager::building_soon(inbuild_genre *gen, inbuild_copy *C, build_vertex **V) {
	ExtensionManager::ensure_graphed(C);
	*V = C->vertex;
}

void ExtensionManager::ensure_graphed(inbuild_copy *C) {
	Copies::get_source_text(C);
	Inclusions::traverse(C, ExtensionManager::from_copy(C)->syntax_tree);
	build_vertex *V;
	LOOP_OVER_LINKED_LIST(V, build_vertex, C->vertex->use_edges)
		ExtensionManager::ensure_graphed(V->as_copy);
}

@h Source text.

=
void ExtensionManager::read_source_text_for(inbuild_genre *G, inbuild_copy *C) {
	Extensions::read_source_text_for(ExtensionManager::from_copy(C));
}
