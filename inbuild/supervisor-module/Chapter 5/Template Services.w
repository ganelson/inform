[Templates::] Template Services.

Behaviour specific to copies of the template genre.

@h Scanning metadata.
Metadata for website templates -- or rather, the complete lack of same -- is
stored in the following structure.

=
typedef struct inform_template {
	struct inbuild_copy *as_copy;
	struct semantic_version_number version;
	MEMORY_MANAGEMENT
} inform_template;

@ This is called as soon as a new copy |C| of the language genre is created.

=
void Templates::scan(inbuild_copy *C) {
	inform_template *T = CREATE(inform_template);
	T->as_copy = C;
	T->version = VersionNumbers::null();
	if (C == NULL) internal_error("no copy to scan");
	Copies::set_metadata(C, STORE_POINTER_inform_template(T));
}
