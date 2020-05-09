[Pipelines::] Pipeline Services.

Behaviour specific to copies of the pipeline genre.

@h Scanning metadata.
Metadata for pipelines -- or rather, the complete lack of same -- is stored
in the following structure.

=
typedef struct inform_pipeline {
	struct inbuild_copy *as_copy;
	struct semantic_version_number version;
	CLASS_DEFINITION
} inform_pipeline;

@ This is called as soon as a new copy |C| of the language genre is created.

=
void Pipelines::scan(inbuild_copy *C) {
	inform_pipeline *P = CREATE(inform_pipeline);
	P->as_copy = C;
	P->version = VersionNumbers::null();
	if (C == NULL) internal_error("no copy to scan");
	Copies::set_metadata(C, STORE_POINTER_inform_pipeline(P));
}
