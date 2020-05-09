[ProjectFileManager::] Project File Manager.

Claiming and creating copies of the projectfile genre: used for Inform 7
source texts stored as stand-alone plain text files, outside the GUI apps.

@h Genre definition.
The |project_file_genre| can be summarised as follows. Copies consist of
single files. These are recognised by having the filename extension |.txt|,
|.ni| or |.i7|. They cannot be stored in nests. Their build graphs are
extensive, having "upstream" vertices representing possible ways to build or
release them, and having numerous "downstream" vertices as well: build edges
run out to the extensions, kits and language definitions that they need.

Note that |project_bundle_genre| and |project_file_genre| are managed
differently, but share the same annotation data structure |inform_project|.
However it is stored in the file system, a project is a project.

=
void ProjectFileManager::start(void) {
	project_file_genre = Genres::new(I"projectfile", FALSE);
	METHOD_ADD(project_file_genre, GENRE_WRITE_WORK_MTID, ProjectFileManager::write_work);
	METHOD_ADD(project_file_genre, GENRE_CLAIM_AS_COPY_MTID, ProjectFileManager::claim_as_copy);
	METHOD_ADD(project_file_genre, GENRE_SEARCH_NEST_FOR_MTID, ProjectFileManager::search_nest_for);
	METHOD_ADD(project_file_genre, GENRE_COPY_TO_NEST_MTID, ProjectFileManager::copy_to_nest);
	METHOD_ADD(project_file_genre, GENRE_READ_SOURCE_TEXT_FOR_MTID, ProjectFileManager::read_source_text_for);
	METHOD_ADD(project_file_genre, GENRE_BUILDING_SOON_MTID, ProjectFileManager::building_soon);
}

void ProjectFileManager::write_work(inbuild_genre *gen, OUTPUT_STREAM, inbuild_work *work) {
	WRITE("%S", work->title);
}

@ Project copies are annotated with a structure called an |inform_project|,
which stores data about extensions used by the Inform compiler.

=
inform_project *ProjectFileManager::from_copy(inbuild_copy *C) {
	if ((C) && (C->edition->work->genre == project_file_genre)) {
		return RETRIEVE_POINTER_inform_project(C->metadata);
	}
	return NULL;
}

inbuild_copy *ProjectFileManager::new_copy(text_stream *name, filename *F) {
	inbuild_work *work = Works::new(project_file_genre, Str::duplicate(name), NULL);
	inbuild_edition *edition = Editions::new(work, VersionNumbers::null());
	inbuild_copy *C = Copies::new_in_file(edition, F);
	Projects::scan(C);
	return C;
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
	return ProjectFileManager::new_copy(Filenames::get_leafname(F), F);
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
As with extensions, the graph for a project is made only on demand, because to make
it would mean fully parsing and partially syntax-analysing its source text.

=
void ProjectFileManager::building_soon(inbuild_genre *gen, inbuild_copy *C, build_vertex **V) {
	inform_project *project = ProjectFileManager::from_copy(C);
	Projects::construct_graph(project);
	*V = project->chosen_build_target;
}

@h Source text.

=
void ProjectFileManager::read_source_text_for(inbuild_genre *G, inbuild_copy *C) {
	Projects::read_source_text_for(ProjectBundleManager::from_copy(C));
}
