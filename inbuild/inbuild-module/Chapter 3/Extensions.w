[Extensions::] Extensions.

An Inform 7 extension.

@h Kits.

= (early code)
inbuild_genre *extension_genre = NULL;

@ =
void Extensions::start(void) {
	extension_genre = Model::genre(I"extension");
	METHOD_ADD(extension_genre, GENRE_WRITE_WORK_MTID, Extensions::write_work);
	METHOD_ADD(extension_genre, GENRE_LOCATION_IN_NEST_MTID, Extensions::location_in_nest);
	METHOD_ADD(extension_genre, GENRE_COPY_TO_NEST_MTID, Extensions::copy_to_nest);
}

inbuild_copy *Extensions::claim(text_stream *arg, text_stream *ext, int directory_status) {
	if (directory_status == TRUE) return NULL;
	if (Str::eq_insensitive(ext, I"i7x")) {
		// eventually load into a copy here
		
		// Works::add_to_database(...->work, CLAIMED_WDBC);
		return NULL;
	}
	return NULL;
}

void Extensions::write_work(inbuild_genre *gen, OUTPUT_STREAM, inbuild_work *work) {
	WRITE("%X", work);
}

void Extensions::location_in_nest(inbuild_genre *gen, inbuild_nest *N, inbuild_requirement *req, linked_list *search_results) {
	;
}

void Extensions::copy_to_nest(inbuild_genre *gen, inbuild_copy *C, inbuild_nest *N, int syncing) {
	internal_error("unimplemented");
}

typedef struct inform_extension {
	struct inbuild_copy *as_copy;
	struct inbuild_version_number version_loaded; /* As actually loaded */
	#ifdef CORE_MODULE
	struct wording body_text; /* Body of source text supplied in extension, if any */
	int body_text_unbroken; /* Does this contain text waiting to be sentence-broken? */
	struct wording documentation_text; /* Documentation supplied in extension, if any */
	int loaded_from_built_in_area; /* Located within Inform application */
	int authorial_modesty; /* Do not credit in the compiled game */
	struct source_file *read_into_file; /* Which source file loaded this */
	struct text_stream *rubric_as_lexed;
	struct text_stream *extra_credit_as_lexed;
	#endif
	MEMORY_MANAGEMENT
} inform_extension;

inform_extension *Extensions::load_at(text_stream *title, text_stream *author, filename *F) {
	inform_extension *E = CREATE(inform_extension);

	inbuild_work *work = Works::new(extension_genre, title, author);
	inbuild_edition *edition = Model::edition(work, VersionNumbers::null());
	E->as_copy = Model::copy_in_file(edition, F, STORE_POINTER_inform_extension(E));
	
	E->version_loaded = VersionNumbers::null();

	#ifdef CORE_MODULE
	E->body_text = EMPTY_WORDING;
	E->body_text_unbroken = FALSE;
	E->documentation_text = EMPTY_WORDING;
	E->loaded_from_built_in_area = FALSE;
	E->authorial_modesty = FALSE;
	E->rubric_as_lexed = NULL;
	E->extra_credit_as_lexed = NULL;	
	#endif
	return E;
}

inform_extension *Extensions::from_copy(inbuild_copy *C) {
	if ((C) && (C->edition->work->genre == extension_genre)) {
		return RETRIEVE_POINTER_inform_extension(C->content);
	}
	return NULL;
}
