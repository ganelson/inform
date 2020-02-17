[Genres::] Genres.

The different sorts of work managed by inbuild.

@h Genres.
For example, "kit" and "extension" will both be both genres. There will be
few of these.

=
typedef struct inbuild_genre {
	text_stream *genre_name;
	METHOD_CALLS
	MEMORY_MANAGEMENT
} inbuild_genre;

inbuild_genre *Genres::new(text_stream *name) {
	inbuild_genre *gen;
	LOOP_OVER(gen, inbuild_genre)
		if (Str::eq(gen->genre_name, name))
			return gen;
	gen = CREATE(inbuild_genre);
	gen->genre_name = Str::duplicate(name);
	ENABLE_METHOD_CALLS(gen);
	return gen;
}

text_stream *Genres::name(inbuild_genre *G) {
	if (G == NULL) return I"(none)";
	return G->genre_name;
}

@

@e GENRE_WRITE_WORK_MTID
@e GENRE_CLAIM_AS_COPY_MTID
@e GENRE_SEARCH_NEST_FOR_MTID
@e GENRE_COPY_TO_NEST_MTID
@e GENRE_GO_OPERATIONAL_MTID
@e GENRE_READ_SOURCE_TEXT_FOR_MTID

=
VMETHOD_TYPE(GENRE_WRITE_WORK_MTID,
	inbuild_genre *gen, text_stream *OUT, inbuild_work *work)
VMETHOD_TYPE(GENRE_CLAIM_AS_COPY_MTID,
	inbuild_genre *gen, inbuild_copy **C, text_stream *arg, text_stream *ext,
	int directory_status)
VMETHOD_TYPE(GENRE_SEARCH_NEST_FOR_MTID,
	inbuild_genre *gen, inbuild_nest *N, inbuild_requirement *req,
	linked_list *search_results)
VMETHOD_TYPE(GENRE_COPY_TO_NEST_MTID,
	inbuild_genre *gen, inbuild_copy *C, inbuild_nest *N, int syncing,
	build_methodology *meth)
VMETHOD_TYPE(GENRE_GO_OPERATIONAL_MTID,
	inbuild_genre *gen, inbuild_copy *C)
VMETHOD_TYPE(GENRE_READ_SOURCE_TEXT_FOR_MTID,
	inbuild_genre *gen, inbuild_copy *C)
