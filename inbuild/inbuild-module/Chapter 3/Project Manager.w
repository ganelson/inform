[ProjectManager::] Project Manager.

A project is a folder holding an Inform 7 work.

@h Genre definition.

=
inbuild_genre *project_genre = NULL;
void ProjectManager::start(void) {
	project_genre = Model::genre(I"project");
	METHOD_ADD(project_genre, GENRE_WRITE_WORK_MTID, ProjectManager::write_work);
	METHOD_ADD(project_genre, GENRE_CLAIM_AS_COPY_MTID, ProjectManager::claim_as_copy);
	METHOD_ADD(project_genre, GENRE_SEARCH_NEST_FOR_MTID, ProjectManager::search_nest_for);
	METHOD_ADD(project_genre, GENRE_COPY_TO_NEST_MTID, ProjectManager::copy_to_nest);
}

void ProjectManager::write_work(inbuild_genre *gen, OUTPUT_STREAM, inbuild_work *work) {
	WRITE("%S", work->title);
}

@ Projects live in the |Inter| subdirectory of a nest:

=
pathname *ProjectManager::path_within_nest(inbuild_nest *N) {
	if (N == NULL) internal_error("no nest");
	return Pathnames::subfolder(N->location, I"Inter");
}

@ Project copies are annotated with a structure called an |inform_project|,
which stores data about extensions used by the Inform compiler.

=
inform_project *ProjectManager::from_copy(inbuild_copy *C) {
	if ((C) && (C->edition->work->genre == project_genre)) {
		return RETRIEVE_POINTER_inform_project(C->content);
	}
	return NULL;
}

inbuild_copy *ProjectManager::new_copy(text_stream *name, pathname *P) {
	inform_project *K = Projects::new_ip(name, P);
	inbuild_work *work = Works::new(project_genre, Str::duplicate(name), NULL);
	inbuild_edition *edition = Model::edition(work, K->version);
	K->as_copy = Model::copy_in_directory(edition, P, STORE_POINTER_inform_project(K));
	return K->as_copy;
}

@h Claiming.
Here |arg| is a textual form of a filename or pathname, such as may have been
supplied at the command line; |ext| is a substring of it, and is its extension
(e.g., |jpg| if |arg| is |Geraniums.jpg|), or is empty if there isn't one;
|directory_status| is true if we know for some reason that this is a directory
not a file, false if we know the reverse, and otherwise not applicable.

A project needs to be a directory whose name ends in |,inform|.

=
void ProjectManager::claim_as_copy(inbuild_genre *gen, inbuild_copy **C,
	text_stream *arg, text_stream *ext, int directory_status) {
	if (directory_status == FALSE) return;
	if (Str::eq_insensitive(ext, I"inform")) {
		pathname *P = Pathnames::from_text(arg);
		*C = ProjectManager::claim_folder_as_copy(P);
	}
}

inbuild_copy *ProjectManager::claim_folder_as_copy(pathname *P) {
	inbuild_copy *C = ProjectManager::new_copy(Pathnames::directory_name(P), P);
	ProjectManager::build_graph(C);
	Works::add_to_database(C->edition->work, CLAIMED_WDBC);
	return C;
}

@h Searching.
Here we look through a nest to find all projects matching the supplied
requirements; though in fact... projects are not nesting birds.

=
void ProjectManager::search_nest_for(inbuild_genre *gen, inbuild_nest *N,
	inbuild_requirement *req, linked_list *search_results) {
}

@h Copying.
Now the task is to copy a project into place in a nest; or would be, if only
projects lived there.

=
void ProjectManager::copy_to_nest(inbuild_genre *gen, inbuild_copy *C, inbuild_nest *N,
	int syncing, build_methodology *meth) {
	Errors::with_text("projects (which is what '%S' is) cannot be copied to nests",
		C->edition->work->title);
}

@h Build graph.
The build graph for a project will need further thought.

=
void ProjectManager::build_graph(inbuild_copy *C) {
	Graphs::copy_vertex(C);
}
