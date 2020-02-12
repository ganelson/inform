[Requirements::] Requirements.

A requirement is a way to specify some subset of works: for example, those
with a given title, and/or version number.

@ A null minimum version means "no minimum", a null maximum means "no maximum".

=
typedef struct inbuild_requirement {
	struct inbuild_work *work;
	struct inbuild_version_number min_version;
	struct inbuild_version_number max_version;
	int allow_malformed;
	MEMORY_MANAGEMENT
} inbuild_requirement;

inbuild_requirement *Requirements::new(inbuild_work *work,
	inbuild_version_number min, inbuild_version_number max) {
	inbuild_requirement *req = CREATE(inbuild_requirement);
	req->work = work;
	req->min_version = min;
	req->max_version = max;
	req->allow_malformed = FALSE;
	return req;
}

inbuild_requirement *Requirements::any_version_of(inbuild_work *work) {
	return Requirements::new(work, VersionNumbers::null(), VersionNumbers::null());
}

inbuild_requirement *Requirements::anything_of_genre(inbuild_genre *G) {
	return Requirements::any_version_of(Works::new(G, I"", I""));
}

inbuild_requirement *Requirements::anything(void) {
	return Requirements::anything_of_genre(NULL);
}

inbuild_requirement *Requirements::from_text(text_stream *T, text_stream *errors) {
	inbuild_requirement *req = Requirements::anything();
	int from = 0;
	for (int at = 0; at < Str::len(T); at++) {
		wchar_t c = Str::get_at(T, at);
		if (c == ',') {
			TEMPORARY_TEXT(initial);
			Str::substr(initial, Str::at(T, from), Str::at(T, at));
			Requirements::impose_clause(req, initial, errors);
			DISCARD_TEXT(initial);
			from = at + 1;
		}
	}
	if (from < Str::len(T)) {
		TEMPORARY_TEXT(final);
		Str::substr(final, Str::at(T, from), Str::end(T));
		Requirements::impose_clause(req, final, errors);
		DISCARD_TEXT(final);
	}
	return req;
}

void Requirements::impose_clause(inbuild_requirement *req, text_stream *T, text_stream *errors) {
	Str::trim_white_space(T);
	if (Str::get_last_char(T) == '*') {
		req->allow_malformed = TRUE;
		Str::delete_last_character(T);
		Str::trim_white_space(T);
	}
	if (Str::eq(T, I"all")) return;

	TEMPORARY_TEXT(clause);
	TEMPORARY_TEXT(value);
	for (int at = 0; at < Str::len(T); at++) {
		wchar_t c = Str::get_at(T, at);
		if (c == '=') {
			Str::substr(clause, Str::start(T), Str::at(T, at));
			Str::substr(value, Str::at(T, at+1), Str::end(T));
			break;
		}
	}
	Str::trim_white_space(clause);
	Str::trim_white_space(value);

	if ((Str::len(clause) > 0) && (Str::len(value) > 0)) {
		if (Str::eq(clause, I"genre")) {
			inbuild_genre *G;
			LOOP_OVER(G, inbuild_genre)
				if (Str::eq_insensitive(G->genre_name, value)) {
					req->work->genre = G;
					break;
				}
			if (req->work->genre == NULL) {
				if (Str::len(errors) == 0)
					WRITE_TO(errors, "not a valid genre: '%S'", value);
			}
		} else if (Str::eq(clause, I"title")) Str::copy(req->work->title, value);
		else if (Str::eq(clause, I"author")) Str::copy(req->work->author_name, value);
		else if (Str::eq(clause, I"version")) {
			inbuild_version_number V = VersionNumbers::from_text(value);
			if (VersionNumbers::is_null(V)) {
				if (Str::len(errors) == 0)
					WRITE_TO(errors, "not a valid version number: '%S'", value);
			}
			req->min_version = V;
			req->max_version = V;
		} else if (Str::eq(clause, I"min")) {
			inbuild_version_number V = VersionNumbers::from_text(value);
			if (VersionNumbers::is_null(V)) {
				if (Str::len(errors) == 0)
					WRITE_TO(errors, "not a valid version number: '%S'", value);
			}
			req->min_version = V;
		} else if (Str::eq(clause, I"max")) {
			inbuild_version_number V = VersionNumbers::from_text(value);
			if (VersionNumbers::is_null(V)) {
				if (Str::len(errors) == 0)
					WRITE_TO(errors, "not a valid version number: '%S'", value);
			}
			req->max_version = V;
		} else {
			if (Str::len(errors) == 0)
				WRITE_TO(errors, "no such term as '%S'", clause);
		}
	} else {
		if (Str::len(errors) == 0)
			WRITE_TO(errors, "clause not in the form 'term=value': '%S'", T);
	}

	DISCARD_TEXT(clause);
	DISCARD_TEXT(value);
}

void Requirements::write(OUTPUT_STREAM, inbuild_requirement *req) {
	if (req == NULL) { WRITE("<none>"); return; }
	int claused = FALSE;
	if (req->work->genre) {
		if (claused) WRITE(","); claused = TRUE;
		WRITE("genre=%S", req->work->genre->genre_name);
	}
	if (Str::len(req->work->title) > 0) {
		if (claused) WRITE(","); claused = TRUE;
		WRITE("work=%S", req->work->title);
	}
	if (Str::len(req->work->author_name) > 0) {
		if (claused) WRITE(","); claused = TRUE;
		WRITE("author=%S", req->work->author_name);
	}
	if (VersionNumbers::is_null(req->min_version) == FALSE) {
		if (claused) WRITE(","); claused = TRUE;
		WRITE("min=%v", &(req->min_version));
	}
	if (VersionNumbers::is_null(req->max_version) == FALSE) {
		if (claused) WRITE(","); claused = TRUE;
		WRITE("max=%v", &(req->max_version));
	}
	if (claused == FALSE) WRITE("all");
	if (req->allow_malformed) WRITE("*");
}

int Requirements::meets(inbuild_edition *edition, inbuild_requirement *req) {
	if (req == NULL) return TRUE;
	if (req->work) {
		if (req->work->genre) {
			if (req->work->genre != edition->work->genre)
				return FALSE;
		}
		if ((req->allow_malformed) && (Str::len(edition->work->title) == 0)) return TRUE;
		if (Str::len(req->work->title) > 0) {
			if (Str::ne_insensitive(req->work->title, edition->work->title))
				return FALSE;
		}
		if (Str::len(req->work->author_name) > 0) {
			if (Str::ne_insensitive(req->work->author_name, edition->work->author_name))
				return FALSE;
		}
	}
	if (VersionNumbers::is_null(req->min_version) == FALSE) {
		if (VersionNumbers::is_null(edition->version)) return FALSE;
		if (VersionNumbers::lt(edition->version, req->min_version)) return FALSE;
	}
	if (VersionNumbers::is_null(req->max_version) == FALSE) {
		if (VersionNumbers::is_null(edition->version)) return TRUE;
		if (VersionNumbers::gt(edition->version, req->max_version)) return FALSE;
	}
	return TRUE;
}

int Requirements::ratchet_minimum(inbuild_version_number V, inbuild_requirement *req) {
	if (req == NULL) internal_error("no requirement");
	if (VersionNumbers::is_null(V)) return FALSE;
	if ((VersionNumbers::is_null(req->min_version)) ||
		(VersionNumbers::gt(V, req->min_version))) {
		req->min_version = V;
		return TRUE;
	}
	return FALSE;
}
