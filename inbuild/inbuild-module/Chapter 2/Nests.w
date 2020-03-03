[Nests::] Nests.

Nests are repositories of Inform-related resources.

@

=
typedef struct inbuild_nest {
	struct pathname *location;
	int read_only;
	int tag_value;
	MEMORY_MANAGEMENT
} inbuild_nest;

typedef struct inbuild_search_result {
	struct inbuild_nest *nest;
	struct inbuild_copy *copy;
	MEMORY_MANAGEMENT
} inbuild_search_result;

=
inbuild_nest *Nests::new(pathname *P) {
	inbuild_nest *N = CREATE(inbuild_nest);
	N->location = P;
	N->read_only = FALSE;
	N->tag_value = -1;
	return N;
}

int Nests::get_tag(inbuild_nest *N) {
	if (N == NULL) return -1;
	return N->tag_value;
}

void Nests::set_tag(inbuild_nest *N, int t) {
	if (N == NULL) internal_error("no nest");
	N->tag_value = t;
}

void Nests::protect(inbuild_nest *N) {
	N->read_only = TRUE;
}

void Nests::add_search_result(linked_list *results, inbuild_nest *N, inbuild_copy *C,
	inbuild_requirement *req) {
	inbuild_search_result *R = CREATE(inbuild_search_result);
	R->nest = N;
	R->copy = C;
	C->found_by = req;
	ADD_TO_LINKED_LIST(R, inbuild_search_result, results);
}

void Nests::add_to_search_sequence(linked_list *search_list, inbuild_nest *N) {
	TEMPORARY_TEXT(NS);
	WRITE_TO(NS, "%p", N->location);
	int already_here = FALSE;
	inbuild_nest *M;
	LOOP_OVER_LINKED_LIST(M, inbuild_nest, search_list) {
		TEMPORARY_TEXT(MS);
		WRITE_TO(NS, "%p", M->location);
		if (Str::eq(NS, MS)) already_here = TRUE;
		DISCARD_TEXT(MS);
	}
	DISCARD_TEXT(NS);
	if (already_here) return;
	ADD_TO_LINKED_LIST(N, inbuild_nest, search_list);
}

void Nests::search_for(inbuild_requirement *req, linked_list *search_list, linked_list *results) {
	inbuild_nest *N;
	LOOP_OVER_LINKED_LIST(N, inbuild_nest, search_list) {
		inbuild_genre *G;
		LOOP_OVER(G, inbuild_genre)
			VMETHOD_CALL(G, GENRE_SEARCH_NEST_FOR_MTID, N, req, results);
	}
}

inbuild_search_result *Nests::first_found(inbuild_requirement *req, linked_list *search_list) {
	linked_list *L = NEW_LINKED_LIST(inbuild_search_result);
	Nests::search_for(req, search_list, L);
	inbuild_search_result *search_result;
	LOOP_OVER_LINKED_LIST(search_result, inbuild_search_result, L)
		return search_result;
	return NULL;
}

void Nests::copy_to(inbuild_copy *C, inbuild_nest *destination_nest, int syncing,
	build_methodology *meth) {
	VMETHOD_CALL(C->edition->work->genre, GENRE_COPY_TO_NEST_MTID, C, destination_nest, syncing, meth);
}

void Nests::overwrite_error(inbuild_nest *N, inbuild_copy *C) {
	text_stream *ext = Str::new();
	WRITE_TO(ext, "%X", C->edition->work);
	Errors::with_text("already present (to overwrite, use -sync-to not -copy-to): '%S'", ext);
}
