[Pipelines::] Pipeline Services.

Behaviour specific to copies of the pipeline genre.

@ =
typedef struct inform_pipeline {
	struct inbuild_copy *as_copy;
	struct semantic_version_number version;
	MEMORY_MANAGEMENT
} inform_pipeline;

inform_pipeline *Pipelines::new_ip(text_stream *name, filename *F) {
	inform_pipeline *T = CREATE(inform_pipeline);
	T->as_copy = NULL;
	T->version = VersionNumbers::null();
	return T;
}
