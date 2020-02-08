[Projects::] Project Services.

An Inform 7 project.

@ =
typedef struct inform_project {
	struct inbuild_copy *as_copy;
	struct inbuild_version_number version;
	MEMORY_MANAGEMENT
} inform_project;

inform_project *Projects::new_ip(text_stream *name, pathname *P) {
	inform_project *T = CREATE(inform_project);
	T->as_copy = NULL;
	T->version = VersionNumbers::null();
	return T;
}
