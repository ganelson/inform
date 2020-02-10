[Pipelines::] Pipeline Services.

A pipeline is a list of steps to be followed by the Inter processor forming
the back end of the Inform compiler.

@ =
typedef struct inform_pipeline {
	struct inbuild_copy *as_copy;
	struct inbuild_version_number version;
	MEMORY_MANAGEMENT
} inform_pipeline;

inform_pipeline *Pipelines::new_ip(text_stream *name, filename *F) {
	inform_pipeline *T = CREATE(inform_pipeline);
	T->as_copy = NULL;
	T->version = VersionNumbers::null();
	return T;
}
