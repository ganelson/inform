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
