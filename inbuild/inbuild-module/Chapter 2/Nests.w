[Nests::] Nests.

Nests are repositories of Inform-related resources.

@

=
typedef struct inbuild_nest {
	struct pathname *location;
	int read_only;
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
	return N;
}

void Nests::protect(inbuild_nest *N) {
	N->read_only = TRUE;
}

void Nests::add_search_result(linked_list *results, inbuild_nest *N, inbuild_copy *C) {
	inbuild_search_result *R = CREATE(inbuild_search_result);
	R->nest = N;
	R->copy = C;
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

void Nests::locate(inbuild_requirement *req, linked_list *search_list, linked_list *results) {
	inbuild_nest *N;
	LOOP_OVER_LINKED_LIST(N, inbuild_nest, search_list) {
		VMETHOD_CALL(req->work->genre, GENRE_LOCATION_IN_NEST_MTID, N, req, results);
	}
}
