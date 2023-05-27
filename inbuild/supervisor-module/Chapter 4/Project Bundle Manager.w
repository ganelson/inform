[ProjectBundleManager::] Project Bundle Manager.

Claiming and creating copies of the projectbundle genre: used for Inform 7
projects as created by the GUI apps.

@h Genre definition.
The |project_bundle_genre| can be summarised as follows. Copies consist of
directories, which are Inform project bundles: for example,
|Counterfeit Monkey.inform| might be such a bundle. They are recognised by
being directories and having names ending in |.inform|. They cannot be
stored in nests. Their build graphs are extensive, having "upstream" vertices
representing possible ways to build or release them, and having numerous
"downstream" vertices as well: build edges run out to the extensions, kits
and language definitions that they need.

Note that |project_bundle_genre| and |project_file_genre| are managed
differently, but share the same annotation data structure |inform_project|.
However it is stored in the file system, a project is a project.

=
void ProjectBundleManager::start(void) {
	project_bundle_genre = Genres::new(I"projectbundle", FALSE);
	METHOD_ADD(project_bundle_genre, GENRE_WRITE_WORK_MTID, ProjectBundleManager::write_work);
	METHOD_ADD(project_bundle_genre, GENRE_CLAIM_AS_COPY_MTID, ProjectBundleManager::claim_as_copy);
	METHOD_ADD(project_bundle_genre, GENRE_SEARCH_NEST_FOR_MTID, ProjectBundleManager::search_nest_for);
	METHOD_ADD(project_bundle_genre, GENRE_COPY_TO_NEST_MTID, ProjectBundleManager::copy_to_nest);
	METHOD_ADD(project_bundle_genre, GENRE_READ_SOURCE_TEXT_FOR_MTID, ProjectBundleManager::read_source_text_for);
	METHOD_ADD(project_bundle_genre, GENRE_BUILDING_SOON_MTID, ProjectBundleManager::building_soon);
}

void ProjectBundleManager::write_work(inbuild_genre *gen, OUTPUT_STREAM, inbuild_work *work) {
	WRITE("%S", work->title);
}

@ Project copies are annotated with a structure called an |inform_project|,
which stores data about extensions used by the Inform compiler.

=
inform_project *ProjectBundleManager::from_copy(inbuild_copy *C) {
	if ((C) && (C->edition->work->genre == project_bundle_genre)) {
		return RETRIEVE_POINTER_inform_project(C->metadata);
	}
	return NULL;
}

inbuild_copy *ProjectBundleManager::new_copy(text_stream *name, pathname *P) {
	inbuild_work *work = Works::new(project_bundle_genre, Str::duplicate(name), NULL);
	inbuild_edition *edition = Editions::new(work, VersionNumbers::null());
	inbuild_copy *C = Copies::new_in_path(edition, P, NULL);
	Projects::scan(C);
	return C;
}

@h Claiming.
Here |arg| is a textual form of a filename or pathname, such as may have been
supplied at the command line; |ext| is a substring of it, and is its extension
(e.g., |jpg| if |arg| is |Geraniums.jpg|), or is empty if there isn't one;
|directory_status| is true if we know for some reason that this is a directory
not a file, false if we know the reverse, and otherwise not applicable.

A project needs to be a directory whose name ends in |.inform|.

=
void ProjectBundleManager::claim_as_copy(inbuild_genre *gen, inbuild_copy **C,
	text_stream *arg, text_stream *ext, int directory_status) {
	if (directory_status == FALSE) return;
	if (Str::eq_insensitive(ext, I"inform")) {
		pathname *P = Pathnames::from_text(arg);
		*C = ProjectBundleManager::claim_folder_as_copy(P);
	}
}

inbuild_copy *ProjectBundleManager::claim_folder_as_copy(pathname *P) {
	if (Directories::exists(P) == FALSE) return NULL;
	inbuild_copy *C = ProjectBundleManager::new_copy(Pathnames::directory_name(P), P);
	@<Police extraneous contents@>;
	return C;
}

@<Police extraneous contents@> =
	int uuid_found = FALSE, source_found = FALSE;
	linked_list *L = Directories::listing(P);
	text_stream *entry;
	LOOP_OVER_LINKED_LIST(entry, text_stream, L) {
		if (Platform::is_folder_separator(Str::get_last_char(entry))) {
			TEMPORARY_TEXT(subdir)
			WRITE_TO(subdir, "%S", entry);
			Str::delete_last_character(subdir);
			if (Str::eq_insensitive(subdir, I"Source")) {
				@<Police Source contents@>;
			} else if (Str::eq_insensitive(subdir, I"Build")) {
				@<Police Build contents@>;
			} else if (Str::eq_insensitive(subdir, I"Index")) {
				@<Police Index contents@>;
			} else if (Str::eq_insensitive(subdir, I"Details")) {
				@<Police spurious Details contents@>;
			} else {
				TEMPORARY_TEXT(error_text)
				WRITE_TO(error_text,
					"the project directory '%S' contains a subdirectory called '%S', "
					"which I don't recognise",
					Pathnames::directory_name(P), subdir);
				Copies::attach_error(C, CopyErrors::new_T(PROJECT_MALFORMED_CE, -1, error_text));
				DISCARD_TEXT(error_text)				
			}
			DISCARD_TEXT(subdir)
		} else {
			if (Str::eq_insensitive(entry, I"manifest.plist")) continue;
			if (Str::eq_insensitive(entry, I"Metadata.iFiction")) continue;
			if (Str::eq_insensitive(entry, I"notes.rtf")) continue;
			if (Str::eq_insensitive(entry, I"Release.blurb")) continue;
			if (Str::eq_insensitive(entry, I"Settings.plist")) continue;
			if (Str::eq_insensitive(entry, I"Skein.skein")) continue;
			if (Str::eq_insensitive(entry, I"uuid.txt")) { uuid_found = TRUE; continue; }
			TEMPORARY_TEXT(error_text)
			WRITE_TO(error_text,
				"the project directory '%S' contains a file called '%S', "
				"which I don't recognise",
				Pathnames::directory_name(P), entry);
			Copies::attach_error(C, CopyErrors::new_T(PROJECT_MALFORMED_CE, -1, error_text));
			DISCARD_TEXT(error_text)				
		}
	}
	if (uuid_found == FALSE) {
		TEMPORARY_TEXT(error_text)
		WRITE_TO(error_text,
			"the project directory '%S' does not contain a 'uuid.txt' file",
			Pathnames::directory_name(P));
		Copies::attach_error(C, CopyErrors::new_T(METADATA_MALFORMED_CE, -1, error_text));
		DISCARD_TEXT(error_text)				
	}
	if (source_found == FALSE) {
		TEMPORARY_TEXT(error_text)
		WRITE_TO(error_text,
			"the project directory '%S' does not contain a 'story.ni' source file in a "
			"'Source' subdirectory",
			Pathnames::directory_name(P));
		Copies::attach_error(C, CopyErrors::new_T(METADATA_MALFORMED_CE, -1, error_text));
		DISCARD_TEXT(error_text)				
	}

@<Police Source contents@> =
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
				"the 'Source' subdirectory of the project directory '%S' contains a "
				"further subdirectory called '%S', but should not have further subdirectories",
				Pathnames::directory_name(P), subdir);
			Copies::attach_error(C, CopyErrors::new_T(PROJECT_MALFORMED_CE, -1, error_text));
			DISCARD_TEXT(error_text)
			DISCARD_TEXT(subdir)
		} else {
			if (Str::eq_insensitive(entry, I"story.ni")) { source_found = TRUE; continue; }
			TEMPORARY_TEXT(error_text)
			WRITE_TO(error_text,
				"the 'Source' subdirectory of the project directory '%S' contains a "
				"file called '%S', but should only contain the source text file 'story.ni'",
				Pathnames::directory_name(P), entry);
			Copies::attach_error(C, CopyErrors::new_T(PROJECT_MALFORMED_CE, -1, error_text));
			DISCARD_TEXT(error_text)				
		}
	}

@<Police Build contents@> =
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
				"the 'Build' subdirectory of the project directory '%S' contains a "
				"further subdirectory called '%S', but should not have further subdirectories",
				Pathnames::directory_name(P), subdir);
			Copies::attach_error(C, CopyErrors::new_T(PROJECT_MALFORMED_CE, -1, error_text));
			DISCARD_TEXT(error_text)
			DISCARD_TEXT(subdir)
		}
	}

@<Police Index contents@> =
	pathname *Q = Pathnames::down(P, subdir);
	linked_list *L = Directories::listing(Q);
	text_stream *entry;
	LOOP_OVER_LINKED_LIST(entry, text_stream, L) {
		if (Platform::is_folder_separator(Str::get_last_char(entry))) {
			TEMPORARY_TEXT(subdir)
			WRITE_TO(subdir, "%S", entry);
			Str::delete_last_character(subdir);
			if (Str::eq_insensitive(subdir, I"Details")) {
				Q = Pathnames::down(Q, subdir);
				@<Check for non-HTML files@>;
			} else {
				TEMPORARY_TEXT(error_text)
				WRITE_TO(error_text,
					"the 'Index' subdirectory of the project directory '%S' contains a "
					"further subdirectory called '%S', but can only have one, 'Details'",
					Pathnames::directory_name(P), subdir);
				Copies::attach_error(C, CopyErrors::new_T(PROJECT_MALFORMED_CE, -1, error_text));
				DISCARD_TEXT(error_text)
			}
			DISCARD_TEXT(subdir)
		}
	}
	@<Check for non-HTML files@>;

@<Check for non-HTML files@> =
	linked_list *L = Directories::listing(Q);
	text_stream *entry;
	LOOP_OVER_LINKED_LIST(entry, text_stream, L) {
		if (Platform::is_folder_separator(Str::get_last_char(entry)) == FALSE) {
			TEMPORARY_TEXT(ext)
			Filenames::write_extension(ext, Filenames::from_text(entry));
			if ((Str::eq_insensitive(ext, I".html") == FALSE) &&
				(Str::eq_insensitive(ext, I".xml") == FALSE)) {
				TEMPORARY_TEXT(error_text)
				WRITE_TO(error_text,
					"the 'Index' subdirectory of the project directory '%S' contains a "
					"file called '%S', but can only contain HTML and XML files",
					Pathnames::directory_name(P), entry);
				Copies::attach_error(C, CopyErrors::new_T(PROJECT_MALFORMED_CE, -1, error_text));
				DISCARD_TEXT(error_text)
			}
		}
	}

@ For now, we will allow a subdirectory called Details to exist, because a bug
in intest at one point caused the temporary workspace projects used when testing Inform
to be created with such a subdirectory.

@<Police spurious Details contents@> =
	;

@h Searching.
Here we look through a nest to find all projects matching the supplied
requirements; though in fact... projects are not nesting birds.

=
void ProjectBundleManager::search_nest_for(inbuild_genre *gen, inbuild_nest *N,
	inbuild_requirement *req, linked_list *search_results) {
}

@h Copying.
Now the task is to copy a project into place in a nest; or would be, if only
projects lived there.

=
void ProjectBundleManager::copy_to_nest(inbuild_genre *gen, inbuild_copy *C, inbuild_nest *N,
	int syncing, build_methodology *meth) {
	Errors::with_text("projects (which is what '%S' is) cannot be copied to nests",
		C->edition->work->title);
}

@h Build graph.
As with extensions, the graph for a project is made only on demand, because to make
it would mean fully parsing and partially syntax-analysing its source text.

=
void ProjectBundleManager::building_soon(inbuild_genre *gen, inbuild_copy *C, build_vertex **V) {
	inform_project *project = ProjectBundleManager::from_copy(C);
	Projects::construct_graph(project);
	*V = project->chosen_build_target;
}

@h Source text.

=
void ProjectBundleManager::read_source_text_for(inbuild_genre *G, inbuild_copy *C) {
	Projects::read_source_text_for(ProjectBundleManager::from_copy(C));
}
