[Templates::] Template Services.

Behaviour specific to copies of the template genre.

@ =
typedef struct inform_template {
	struct inbuild_copy *as_copy;
	struct semantic_version_number version;
	MEMORY_MANAGEMENT
} inform_template;

inform_template *Templates::new_it(text_stream *name, pathname *P) {
	inform_template *T = CREATE(inform_template);
	T->as_copy = NULL;
	T->version = VersionNumbers::null();
	return T;
}
