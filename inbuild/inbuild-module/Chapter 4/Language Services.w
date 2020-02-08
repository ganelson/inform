[Languages::] Language Services.

An Inform 7 language definition bundle.

@ =
typedef struct inform_language {
	struct inbuild_copy *as_copy;
	struct inbuild_version_number version;
	MEMORY_MANAGEMENT
} inform_language;

inform_language *Languages::new_il(text_stream *name, pathname *P) {
	inform_language *L = CREATE(inform_language);
	L->as_copy = NULL;
	L->version = VersionNumbers::null();
	return L;
}
