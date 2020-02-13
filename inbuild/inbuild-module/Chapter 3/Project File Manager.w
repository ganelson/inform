[ProjectFileManager::] Project File Manager.

A project file is a plain text file of Inform 7 source text.

@h Genre definition.

=
inbuild_genre *project_file_genre = NULL;
void ProjectFileManager::start(void) {
	project_file_genre = Model::genre(I"projectfile");
	METHOD_ADD(project_file_genre, GENRE_WRITE_WORK_MTID, ProjectFileManager::write_work);
	METHOD_ADD(project_file_genre, GENRE_CLAIM_AS_COPY_MTID, ProjectFileManager::claim_as_copy);
	METHOD_ADD(project_file_genre, GENRE_SEARCH_NEST_FOR_MTID, ProjectFileManager::search_nest_for);
	METHOD_ADD(project_file_genre, GENRE_COPY_TO_NEST_MTID, ProjectFileManager::copy_to_nest);
	METHOD_ADD(project_file_genre, GENRE_GO_OPERATIONAL_MTID, ProjectFileManager::go_operational);
}

void ProjectFileManager::write_work(inbuild_genre *gen, OUTPUT_STREAM, inbuild_work *work) {
	WRITE("%S", work->title);
}

@ Project copies are annotated with a structure called an |inform_project|,
which stores data about extensions used by the Inform compiler.

=
inform_project *ProjectFileManager::from_copy(inbuild_copy *C) {
	if ((C) && (C->edition->work->genre == project_file_genre)) {
		return RETRIEVE_POINTER_inform_project(C->content);
	}
	return NULL;
}

inbuild_copy *ProjectFileManager::new_copy(text_stream *name, filename *F) {
	inform_project *K = Projects::new_ip(name, F, NULL);
	inbuild_work *work = Works::new(project_file_genre, Str::duplicate(name), NULL);
	inbuild_edition *edition = Model::edition(work, K->version);
	K->as_copy = Model::copy_in_file(edition, F, STORE_POINTER_inform_project(K));
	return K->as_copy;
}

@h Claiming.
Here |arg| is a textual form of a filename or pathname, such as may have been
supplied at the command line; |ext| is a substring of it, and is its extension
(e.g., |jpg| if |arg| is |Geraniums.jpg|), or is empty if there isn't one;
|directory_status| is true if we know for some reason that this is a directory
not a file, false if we know the reverse, and otherwise not applicable.

A project file needs to be a plain text file whose name ends in |.txt|, |.ni|
or |.i7|.

=
void ProjectFileManager::claim_as_copy(inbuild_genre *gen, inbuild_copy **C,
	text_stream *arg, text_stream *ext, int directory_status) {
	if (directory_status == TRUE) return;
	if ((Str::eq_insensitive(ext, I"txt")) ||
		(Str::eq_insensitive(ext, I"ni")) ||
		(Str::eq_insensitive(ext, I"i7"))) {
		filename *F = Filenames::from_text(arg);
		*C = ProjectFileManager::claim_file_as_copy(F);
	}
}

inbuild_copy *ProjectFileManager::claim_file_as_copy(filename *F) {
	inbuild_copy *C = ProjectFileManager::new_copy(Filenames::get_leafname(F), F);
	ProjectFileManager::build_vertex(C);
	Works::add_to_database(C->edition->work, CLAIMED_WDBC);
	return C;
}

@h Searching.
Here we look through a nest to find all projects matching the supplied
requirements; though in fact... projects are not nesting birds.

=
void ProjectFileManager::search_nest_for(inbuild_genre *gen, inbuild_nest *N,
	inbuild_requirement *req, linked_list *search_results) {
}

@h Copying.
Now the task is to copy a project into place in a nest; or would be, if only
projects lived there.

=
void ProjectFileManager::copy_to_nest(inbuild_genre *gen, inbuild_copy *C, inbuild_nest *N,
	int syncing, build_methodology *meth) {
	Errors::with_text("projects (which is what '%S' is) cannot be copied to nests",
		C->edition->work->title);
}

@h Build graph.
The build graph for a project will need further thought.

=
void ProjectFileManager::build_vertex(inbuild_copy *C) {
	Graphs::copy_vertex(C);
}

@ which it will get here:

=
void ProjectFileManager::go_operational(inbuild_genre *G, inbuild_copy *C) {
	Projects::construct_graph(ProjectFileManager::from_copy(C));
}
