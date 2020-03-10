[TemplateManager::] Template Manager.

A template is the outline for a website presenting an Inform work.

@h Genre definition.

=
inbuild_genre *template_genre = NULL;
void TemplateManager::start(void) {
	template_genre = Genres::new(I"template", TRUE);
	METHOD_ADD(template_genre, GENRE_WRITE_WORK_MTID, TemplateManager::write_work);
	METHOD_ADD(template_genre, GENRE_CLAIM_AS_COPY_MTID, TemplateManager::claim_as_copy);
	METHOD_ADD(template_genre, GENRE_SEARCH_NEST_FOR_MTID, TemplateManager::search_nest_for);
	METHOD_ADD(template_genre, GENRE_COPY_TO_NEST_MTID, TemplateManager::copy_to_nest);
}

void TemplateManager::write_work(inbuild_genre *gen, OUTPUT_STREAM, inbuild_work *work) {
	WRITE("%S", work->title);
}

@ Templates live in the |Templates| subdirectory of a nest:

=
pathname *TemplateManager::path_within_nest(inbuild_nest *N) {
	if (N == NULL) internal_error("no nest");
	return Pathnames::subfolder(N->location, I"Templates");
}

@ Template copies are annotated with a structure called an |inform_template|,
which stores data about extensions used by the Inform compiler.

=
inform_template *TemplateManager::from_copy(inbuild_copy *C) {
	if ((C) && (C->edition->work->genre == template_genre)) {
		return RETRIEVE_POINTER_inform_template(C->content);
	}
	return NULL;
}

inbuild_copy *TemplateManager::new_copy(text_stream *name, pathname *P) {
	inform_template *K = Templates::new_it(name, P);
	inbuild_work *work = Works::new(template_genre, Str::duplicate(name), NULL);
	inbuild_edition *edition = Editions::new(work, K->version);
	K->as_copy = Copies::new_in_path(edition, P, STORE_POINTER_inform_template(K));
	return K->as_copy;
}

@h Claiming.
Here |arg| is a textual form of a filename or pathname, such as may have been
supplied at the command line; |ext| is a substring of it, and is its extension
(e.g., |jpg| if |arg| is |Geraniums.jpg|), or is empty if there isn't one;
|directory_status| is true if we know for some reason that this is a directory
not a file, false if we know the reverse, and otherwise not applicable.

Templates are slightly hard to recognise in isolation, but they contain
either a manifest file, or else an |index.html|, so that will have to do.

=
void TemplateManager::claim_as_copy(inbuild_genre *gen, inbuild_copy **C,
	text_stream *arg, text_stream *ext, int directory_status) {
	if (directory_status == FALSE) return;
	pathname *P = Pathnames::from_text(arg);
	*C = TemplateManager::claim_folder_as_copy(P);
}

inbuild_copy *TemplateManager::claim_folder_as_copy(pathname *P) {
	filename *canary1 = Filenames::in_folder(P, I"(manifest).txt");
	filename *canary2 = Filenames::in_folder(P, I"index.html");
	if ((TextFiles::exists(canary1)) || (TextFiles::exists(canary2))) {
		inbuild_copy *C = TemplateManager::new_copy(Pathnames::directory_name(P), P);
		TemplateManager::build_vertex(C);
		Works::add_to_database(C->edition->work, CLAIMED_WDBC);
		return C;
	}
	return NULL;
}

@h Searching.
Here we look through a nest to find all kits matching the supplied
requirements.

=
void TemplateManager::search_nest_for(inbuild_genre *gen, inbuild_nest *N,
	inbuild_requirement *req, linked_list *search_results) {
	if ((req->work->genre) && (req->work->genre != template_genre)) return;
	pathname *P = TemplateManager::path_within_nest(N);
	scan_directory *D = Directories::open(P);
	if (D) {
		TEMPORARY_TEXT(LEAFNAME);
		while (Directories::next(D, LEAFNAME)) {
			if (Str::get_last_char(LEAFNAME) == FOLDER_SEPARATOR) {
				Str::delete_last_character(LEAFNAME);
				pathname *Q = Pathnames::subfolder(P, LEAFNAME);
				inbuild_copy *C = TemplateManager::claim_folder_as_copy(Q);
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
Now the task is to copy a template into place in a nest. Since a template is
a folder, we need to |rsync| it.

=
pathname *TemplateManager::pathname_in_nest(inbuild_nest *N, inbuild_edition *E) {
	TEMPORARY_TEXT(leaf);
	Editions::write_canonical_leaf(leaf, E);
	pathname *P = Pathnames::subfolder(TemplateManager::path_within_nest(N), leaf);
	DISCARD_TEXT(leaf);
	return P;
}

void TemplateManager::copy_to_nest(inbuild_genre *gen, inbuild_copy *C, inbuild_nest *N,
	int syncing, build_methodology *meth) {
	pathname *P = TemplateManager::pathname_in_nest(N, C->edition);
	filename *canary1 = Filenames::in_folder(P, I"(manifest).txt");
	filename *canary2 = Filenames::in_folder(P, I"index.html");
	if ((TextFiles::exists(canary1)) || (TextFiles::exists(canary2))) {
		if (syncing == FALSE) { Nests::overwrite_error(N, C); return; }
	} else {
		if (meth->methodology == DRY_RUN_METHODOLOGY) {
			TEMPORARY_TEXT(command);
			WRITE_TO(command, "mkdir -p ");
			Shell::quote_path(command, P);
			WRITE_TO(STDOUT, "%S\n", command);
			DISCARD_TEXT(command);
		} else {
			Pathnames::create_in_file_system(N->location);
			Pathnames::create_in_file_system(TemplateManager::path_within_nest(N));
			Pathnames::create_in_file_system(P);
		}
	}
	if (meth->methodology == DRY_RUN_METHODOLOGY) {
		TEMPORARY_TEXT(command);
		WRITE_TO(command, "rsync -a --delete ");
		Shell::quote_path(command, C->location_if_path);
		Shell::quote_path(command, P);
		WRITE_TO(STDOUT, "%S\n", command);
		DISCARD_TEXT(command);
	} else {
		Pathnames::rsync(C->location_if_path, P);
	}
}

@h Build graph.
The build graph for a template is just a single node: you don't need to
build a template at all.

=
void TemplateManager::build_vertex(inbuild_copy *C) {
	Graphs::copy_vertex(C);
}
