[TemplateManager::] Template Manager.

Claiming and creating copies of the template genre: used for website and
interpreter templates when releasing an Inform project.

@h Genre definition.
The |template_genre| can be summarised as follows. Website templates
are directories. They are recognised by containing either a metadata file
called |(manifest).txt| or |index.html|, or both. They are stored in
nests, in |N/Templates/Title-vVersion|. Their build graphs are single
vertices with no build or use edges.

=
void TemplateManager::start(void) {
	template_genre = Genres::new(I"template", I"template", TRUE);
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
	return Pathnames::down(N->location, I"Templates");
}

@ Template copies are annotated with a structure called an |inform_template|,
which stores data about extensions used by the Inform compiler.

=
inform_template *TemplateManager::from_copy(inbuild_copy *C) {
	if ((C) && (C->edition->work->genre == template_genre)) {
		return RETRIEVE_POINTER_inform_template(C->metadata);
	}
	return NULL;
}

inbuild_copy *TemplateManager::new_copy(text_stream *name, pathname *P, inbuild_nest *N) {
	inbuild_work *work = Works::new(template_genre, Str::duplicate(name), NULL);
	inbuild_edition *edition = Editions::new(work, VersionNumbers::null());
	inbuild_copy *C = Copies::new_in_path(edition, P, N);
	Templates::scan(C);
	return C;
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
	*C = TemplateManager::claim_folder_as_copy(P, NULL);
}

inbuild_copy *TemplateManager::claim_folder_as_copy(pathname *P, inbuild_nest *N) {
	filename *canary1 = Filenames::in(P, I"(manifest).txt");
	filename *canary2 = Filenames::in(P, I"index.html");
	if ((TextFiles::exists(canary1)) || (TextFiles::exists(canary2)))
		return TemplateManager::new_copy(Pathnames::directory_name(P), P, N);
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
	linked_list *L = Directories::listing(P);
	text_stream *entry;
	LOOP_OVER_LINKED_LIST(entry, text_stream, L) {
		if (Platform::is_folder_separator(Str::get_last_char(entry))) {
			Str::delete_last_character(entry);
			pathname *Q = Pathnames::down(P, entry);
			inbuild_copy *C = TemplateManager::claim_folder_as_copy(Q, N);
			if ((C) && (Requirements::meets(C->edition, req))) {
				Nests::add_search_result(search_results, N, C, req);
			}
		}
	}
}

@h Copying.
Now the task is to copy a template into place in a nest. Since a template is
a folder, we need to |rsync| it.

=
pathname *TemplateManager::pathname_in_nest(inbuild_nest *N, inbuild_edition *E) {
	TEMPORARY_TEXT(leaf)
	Editions::write_canonical_leaf(leaf, E);
	pathname *P = Pathnames::down(TemplateManager::path_within_nest(N), leaf);
	DISCARD_TEXT(leaf)
	return P;
}

int TemplateManager::copy_to_nest(inbuild_genre *gen, inbuild_copy *C, inbuild_nest *N,
	int syncing, build_methodology *meth) {
	pathname *P = TemplateManager::pathname_in_nest(N, C->edition);
	filename *canary1 = Filenames::in(P, I"(manifest).txt");
	filename *canary2 = Filenames::in(P, I"index.html");
	if ((TextFiles::exists(canary1)) || (TextFiles::exists(canary2))) {
		if (syncing == FALSE) { Copies::overwrite_error(C, N); return 1; }
	} else {
		if (meth->methodology == DRY_RUN_METHODOLOGY) {
			TEMPORARY_TEXT(command)
			WRITE_TO(command, "mkdir -p ");
			Shell::quote_path(command, P);
			WRITE_TO(STDOUT, "%S\n", command);
			DISCARD_TEXT(command)
		} else {
			Pathnames::create_in_file_system(N->location);
			Pathnames::create_in_file_system(TemplateManager::path_within_nest(N));
			Pathnames::create_in_file_system(P);
		}
	}
	int rv = 0;
	if (meth->methodology == DRY_RUN_METHODOLOGY) {
		TEMPORARY_TEXT(command)
		WRITE_TO(command, "rsync -a --delete ");
		Shell::quote_path(command, C->location_if_path);
		Shell::quote_path(command, P);
		WRITE_TO(STDOUT, "%S\n", command);
		DISCARD_TEXT(command)
	} else {
		rv = Pathnames::rsync(C->location_if_path, P);
	}
	return rv;
}
