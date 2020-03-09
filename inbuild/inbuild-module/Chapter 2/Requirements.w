[Requirements::] Requirements.

A requirement is a way to specify some subset of works: for example, those
with a given title, and/or version number.

@ A null minimum version means "no minimum", a null maximum means "no maximum".

=
typedef struct inbuild_requirement {
	struct inbuild_work *work;
	struct semver_range *version_range;
	MEMORY_MANAGEMENT
} inbuild_requirement;

inbuild_requirement *Requirements::new(inbuild_work *work, semver_range *R) {
	inbuild_requirement *req = CREATE(inbuild_requirement);
	req->work = work;
	req->version_range = R;
	return req;
}

inbuild_requirement *Requirements::any_version_of(inbuild_work *work) {
	return Requirements::new(work, VersionNumbers::any_range());
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
			semantic_version_number V = VersionNumbers::from_text(value);
			if (VersionNumbers::is_null(V)) {
				if (Str::len(errors) == 0)
					WRITE_TO(errors, "not a valid version number: '%S'", value);
			}
			req->version_range = VersionNumbers::compatibility_range(V);
		} else if (Str::eq(clause, I"min")) {
			semantic_version_number V = VersionNumbers::from_text(value);
			if (VersionNumbers::is_null(V)) {
				if (Str::len(errors) == 0)
					WRITE_TO(errors, "not a valid version number: '%S'", value);
			}
			req->version_range = VersionNumbers::at_least_range(V);
		} else if (Str::eq(clause, I"max")) {
			semantic_version_number V = VersionNumbers::from_text(value);
			if (VersionNumbers::is_null(V)) {
				if (Str::len(errors) == 0)
					WRITE_TO(errors, "not a valid version number: '%S'", value);
			}
			req->version_range = VersionNumbers::at_most_range(V);
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
	if (VersionNumbers::is_any_range(req->version_range) == FALSE) {
		if (claused) WRITE(","); claused = TRUE;
		WRITE("range="); VersionNumbers::write_range(OUT, req->version_range);
	}
	if (claused == FALSE) WRITE("all");
}

int Requirements::meets(inbuild_edition *edition, inbuild_requirement *req) {
	if (req == NULL) return TRUE;
	if (req->work) {
		if (req->work->genre) {
			if (req->work->genre != edition->work->genre)
				return FALSE;
		}
		if (Str::len(req->work->title) > 0) {
			if (Str::ne_insensitive(req->work->title, edition->work->title))
				return FALSE;
		}
		if (Str::len(req->work->author_name) > 0) {
			if (Str::ne_insensitive(req->work->author_name, edition->work->author_name))
				return FALSE;
		}
	}
	return VersionNumbers::in_range(edition->version, req->version_range);
}
