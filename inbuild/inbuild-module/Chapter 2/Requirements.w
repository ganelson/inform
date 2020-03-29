[Requirements::] Requirements.

A requirement is a way to specify some subset of works: for example, those
with a given title, and/or version number.

@h Creation.
A requirement is, in effect, the criteria for performing a search. We can
specify the title, and/or the author name, and/or the genre -- all given
in the |work| field below, with those unspecified left blank -- and/or
we can give a semantic version number range:

=
typedef struct inbuild_requirement {
	struct inbuild_work *work;
	struct semver_range *version_range;
	MEMORY_MANAGEMENT
} inbuild_requirement;

@ Here are some creators:

=
inbuild_requirement *Requirements::new(inbuild_work *work, semver_range *R) {
	inbuild_requirement *req = CREATE(inbuild_requirement);
	req->work = work;
	req->version_range = R;
	return req;
}

inbuild_requirement *Requirements::any_version_of(inbuild_work *work) {
	return Requirements::new(work, VersionNumberRanges::any_range());
}

inbuild_requirement *Requirements::anything_of_genre(inbuild_genre *G) {
	return Requirements::any_version_of(Works::new(G, I"", I""));
}

inbuild_requirement *Requirements::anything(void) {
	return Requirements::anything_of_genre(NULL);
}

@ The most involved of the creators parses text. An involved example might be:

	|genre=extension,author=Emily Short,title=Locksmith,min=6.1-alpha.2,max=17.2|

We should return a requirement if this is valid, and write an error message if
it is not. (If the text has multiple things wrong with it, we write only the
first error message arising.)

At the top level, we have a comma-separated list of clauses. Note that the
empty text is legal here, and produces an unlimited requirement.

=
inbuild_requirement *Requirements::from_text(text_stream *T,
	text_stream *errors) {
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

@ Each clause must either be |all| or take the form |term=value|:

=
void Requirements::impose_clause(inbuild_requirement *req, text_stream *T,
	text_stream *errors) {
	Str::trim_white_space(T);
	if (Str::eq(T, I"all")) return;

	TEMPORARY_TEXT(term);
	TEMPORARY_TEXT(value);
	for (int at = 0; at < Str::len(T); at++) {
		wchar_t c = Str::get_at(T, at);
		if (c == '=') {
			Str::substr(term, Str::start(T), Str::at(T, at));
			Str::substr(value, Str::at(T, at+1), Str::end(T));
			break;
		}
	}
	Str::trim_white_space(term);
	Str::trim_white_space(value);
	if ((Str::len(term) > 0) && (Str::len(value) > 0)) {
		@<Deal with a term-value pair@>;
	} else {
		if (Str::len(errors) == 0)
			WRITE_TO(errors, "clause not in the form 'term=value': '%S'", T);
	}
	DISCARD_TEXT(term);
	DISCARD_TEXT(value);
}

@<Deal with a term-value pair@> =
	if (Str::eq(term, I"genre")) {
		inbuild_genre *G = Genres::by_name(value);
		if (G) req->work->genre = G;
		else if (Str::len(errors) == 0)
			WRITE_TO(errors, "not a valid genre: '%S'", value);
	} else if (Str::eq(term, I"title")) {
		Str::copy(req->work->title, value);
	} else if (Str::eq(term, I"author")) {
		Str::copy(req->work->author_name, value);
	} else if (Str::eq(term, I"version")) {
		semantic_version_number V = Requirements::semver(value, errors);
		req->version_range = VersionNumberRanges::compatibility_range(V);
	} else if (Str::eq(term, I"min")) {
		semantic_version_number V = Requirements::semver(value, errors);
		req->version_range = VersionNumberRanges::at_least_range(V);
	} else if (Str::eq(term, I"max")) {
		semantic_version_number V = Requirements::semver(value, errors);
		req->version_range = VersionNumberRanges::at_most_range(V);
	} else {
		if (Str::len(errors) == 0)
			WRITE_TO(errors, "no such term as '%S'", term);
	}

@ =
semantic_version_number Requirements::semver(text_stream *value, text_stream *errors) {
	semantic_version_number V = VersionNumbers::from_text(value);
	if (VersionNumbers::is_null(V))
		if (Str::len(errors) == 0)
			WRITE_TO(errors, "not a valid version number: '%S'", value);
	return V;
}

@h Writing.
This is the inverse of the above function, and uses the same notation.

=
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
	if (VersionNumberRanges::is_any_range(req->version_range) == FALSE) {
		if (claused) WRITE(","); claused = TRUE;
		WRITE("range="); VersionNumberRanges::write_range(OUT, req->version_range);
	}
	if (claused == FALSE) WRITE("all");
}

@h Meeting requirements.
Finally, we actually use these intricacies for something. Given an edition,
we return |TRUE| if it meets the requirements and |FALSE| if it does not.

Note that requirements are based on the edition, not on the copy. If one
copy on file of Version 3.2 of Monkey Puzzle Trees by Capability Brown meets
a requirement, then so will all other copies of it.

=
int Requirements::meets(inbuild_edition *edition, inbuild_requirement *req) {
	if (req == NULL) return TRUE;
	if (req->work) {
		if (req->work->genre)
			if (req->work->genre != edition->work->genre)
				return FALSE;
		if (Str::len(req->work->title) > 0)
			if (Str::ne_insensitive(req->work->title, edition->work->title))
				return FALSE;
		if (Str::len(req->work->author_name) > 0)
			if (Str::ne_insensitive(req->work->author_name, edition->work->author_name))
				return FALSE;
	}
	return VersionNumberRanges::in_range(edition->version, req->version_range);
}
