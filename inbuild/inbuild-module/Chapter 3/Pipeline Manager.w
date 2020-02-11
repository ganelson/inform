[PipelineManager::] Pipeline Manager.

An Inform 7 pipeline.

@h Genre definition.

= (early code)
inbuild_genre *pipeline_genre = NULL;

@ =
void PipelineManager::start(void) {
	pipeline_genre = Model::genre(I"pipeline");
	METHOD_ADD(pipeline_genre, GENRE_WRITE_WORK_MTID, PipelineManager::write_work);
	METHOD_ADD(pipeline_genre, GENRE_CLAIM_AS_COPY_MTID, PipelineManager::claim_as_copy);
	METHOD_ADD(pipeline_genre, GENRE_SEARCH_NEST_FOR_MTID, PipelineManager::search_nest_for);
	METHOD_ADD(pipeline_genre, GENRE_COPY_TO_NEST_MTID, PipelineManager::copy_to_nest);
}

void PipelineManager::write_work(inbuild_genre *gen, OUTPUT_STREAM, inbuild_work *work) {
	WRITE("%S", work->title);
}

@ Pipelines live in their namesake subdirectory of a nest:

=
pathname *PipelineManager::path_within_nest(inbuild_nest *N) {
	if (N == NULL) internal_error("no nest");
	return Pathnames::subfolder(N->location, I"Pipelines");
}

@ Pipeline copies are annotated with a structure called an |inform_pipeline|,
which stores data about pipelines used by the Inform compiler.

=
inform_pipeline *PipelineManager::from_copy(inbuild_copy *C) {
	if ((C) && (C->edition->work->genre == pipeline_genre)) {
		return RETRIEVE_POINTER_inform_pipeline(C->content);
	}
	return NULL;
}

inbuild_copy *PipelineManager::new_copy(inbuild_edition *edition, filename *F) {
	inform_pipeline *E = Pipelines::new_ip(edition->work->title, F);
	inbuild_copy *C = Model::copy_in_file(edition, F, STORE_POINTER_inform_pipeline(E));
	E->as_copy = C;
	return C;
}

@h Claiming.
Here |arg| is a textual form of a filename or pathname, such as may have been
supplied at the command line; |ext| is a substring of it, and is its extension
(e.g., |jpg| if |arg| is |Geraniums.jpg|), or is empty if there isn't one;
|directory_status| is true if we know for some reason that this is a directory
not a file, false if we know the reverse, and otherwise not applicable.

An pipeline, for us, simply needs to be a file with extension |interpipeline|.

=
void PipelineManager::claim_as_copy(inbuild_genre *gen, inbuild_copy **C,
	text_stream *arg, text_stream *ext, int directory_status) {
	if (directory_status == TRUE) return;
	if (Str::eq_insensitive(ext, I"interpipeline")) {
		filename *F = Filenames::from_text(arg);
		*C = PipelineManager::claim_file_as_copy(F, NULL, FALSE);
	}
}

inbuild_copy *PipelineManager::claim_file_as_copy(filename *F, text_stream *error_text,
	int allow_malformed) {
	if (TextFiles::exists(F) == FALSE) return NULL;
	inbuild_version_number V = VersionNumbers::null();
	TEMPORARY_TEXT(unext);
	Filenames::write_unextended_leafname(unext, F);
	inbuild_copy *C = PipelineManager::new_copy(
		Model::edition(Works::new_raw(pipeline_genre, unext, NULL), V), F);
	DISCARD_TEXT(unext);
	Works::add_to_database(C->edition->work, CLAIMED_WDBC);
	PipelineManager::build_vertex(C);
	return C;
}

@h Searching.
Here we look through a nest to find all pipelines matching the supplied
requirements.

=
void PipelineManager::search_nest_for(inbuild_genre *gen, inbuild_nest *N,
	inbuild_requirement *req, linked_list *search_results) {
	if ((req->work->genre) && (req->work->genre != pipeline_genre)) return;
	pathname *P = PipelineManager::path_within_nest(N);
	scan_directory *D = Directories::open(P);
	if (D) {
		TEMPORARY_TEXT(LEAFNAME);
		while (Directories::next(D, LEAFNAME)) {
			if (Str::get_last_char(LEAFNAME) != FOLDER_SEPARATOR) {
				filename *F = Filenames::in_folder(P, LEAFNAME);
				inbuild_copy *C = PipelineManager::claim_file_as_copy(F, NULL,
					req->allow_malformed);
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
Now the task is to copy a pipeline into place in a nest. This is easy,
since a pipeline is a single file; to sync, we just overwrite.

=
filename *PipelineManager::filename_in_nest(inbuild_nest *N, text_stream *title) {
	pathname *E = PipelineManager::path_within_nest(N);
	TEMPORARY_TEXT(leaf);
	WRITE_TO(leaf, "%S.interpipeline", title);
	filename *F = Filenames::in_folder(E, leaf);
	DISCARD_TEXT(leaf);
	return F;
}

void PipelineManager::copy_to_nest(inbuild_genre *gen, inbuild_copy *C, inbuild_nest *N,
	int syncing, build_methodology *meth) {
	filename *F = PipelineManager::filename_in_nest(N, C->edition->work->title);

	if (TextFiles::exists(F)) {
		if (syncing == FALSE) { Nests::overwrite_error(N, C); return; }
	} else {
		if (meth->methodology == DRY_RUN_METHODOLOGY) {
			TEMPORARY_TEXT(command);
			WRITE_TO(command, "mkdir -p ");
			Shell::quote_path(command, Filenames::get_path_to(F));
			WRITE_TO(STDOUT, "%S\n", command);
			DISCARD_TEXT(command);
		} else {
			Pathnames::create_in_file_system(N->location);
			Pathnames::create_in_file_system(Filenames::get_path_to(F));
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
The build graph for a pipeline is just a single node: you don't need to
build a pipeline at all.

=
void PipelineManager::build_vertex(inbuild_copy *C) {
	Graphs::copy_vertex(C);
}
