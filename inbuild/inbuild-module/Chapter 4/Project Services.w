[Projects::] Project Services.

An Inform 7 project.

@ =
typedef struct inform_project {
	struct inbuild_copy *as_copy;
	struct inbuild_version_number version;
	struct filename *source_text;
	MEMORY_MANAGEMENT
} inform_project;

inform_project *Projects::new_ip(text_stream *name, filename *F, pathname *P) {
	inform_project *T = CREATE(inform_project);
	T->as_copy = NULL;
	T->version = VersionNumbers::null();
	return T;
}

void Projects::set_source_filename(inform_project *project, filename *F) {
	project->source_text = F;
}

pathname *Projects::path(inform_project *project) {
	if (project == NULL) return NULL;
	return project->as_copy->location_if_path;
}

filename *Projects::source(inform_project *project) {
	if (project == NULL) return NULL;
	return project->source_text;
}
