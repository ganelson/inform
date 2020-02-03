[Model::] Conceptual Model.

The main concepts of inbuild.

@h Genres.
For example, "kit" and "extension" will both be both genres. There will be
few of these.

@e GENRE_WRITE_WORK_MTID
@e GENRE_LOCATION_IN_NEST_MTID
@e GENRE_COPY_TO_NEST_MTID

=
typedef struct inbuild_genre {
	text_stream *genre_name;
	METHOD_CALLS
	MEMORY_MANAGEMENT
} inbuild_genre;

VMETHOD_TYPE(GENRE_WRITE_WORK_MTID, inbuild_genre *gen, text_stream *OUT, inbuild_work *work)
VMETHOD_TYPE(GENRE_LOCATION_IN_NEST_MTID, inbuild_genre *gen, inbuild_nest *N, inbuild_requirement *req, linked_list *search_results)
VMETHOD_TYPE(GENRE_COPY_TO_NEST_MTID, inbuild_genre *gen, inbuild_copy *C, inbuild_nest *N, int syncing)

@ =
inbuild_genre *Model::genre(text_stream *name) {
	inbuild_genre *gen;
	LOOP_OVER(gen, inbuild_genre)
		if (Str::eq(gen->genre_name, name))
			return gen;
	gen = CREATE(inbuild_genre);
	gen->genre_name = Str::duplicate(name);
	ENABLE_METHOD_CALLS(gen);
	return gen;
}

@h Editions.
An "edition" of a work is a particular version numbered form of it. For
example, release 7 of Bronze by Emily Short would be an edition of Bronze.

=
typedef struct inbuild_edition {
	struct inbuild_work *work;
	struct inbuild_version_number version;
	MEMORY_MANAGEMENT
} inbuild_edition;

inbuild_edition *Model::edition(inbuild_work *work, inbuild_version_number version) {
	inbuild_edition *edition = CREATE(inbuild_edition);
	edition->work = work;
	edition->version = version;
	return edition;
}

@h Requirements.
A "requirement" is when we want to get hold of a work in some edition which
meets a range of possible versions. A null minimum version means "no minimum",
a null maximum means "no maximum".

=
typedef struct inbuild_requirement {
	struct inbuild_work *work;
	struct inbuild_version_number min_version;
	struct inbuild_version_number max_version;
	MEMORY_MANAGEMENT
} inbuild_requirement;

inbuild_requirement *Model::requirement(inbuild_work *work,
	inbuild_version_number min, inbuild_version_number max) {
	inbuild_requirement *req = CREATE(inbuild_requirement);
	req->work = work;
	req->min_version = min;
	req->max_version = max;
	return req;
}

int Model::meets(inbuild_version_number V, inbuild_requirement *req) {
	if (req == NULL) return TRUE;
	if (VersionNumbers::is_null(req->min_version) == FALSE) {
		if (VersionNumbers::is_null(V)) return FALSE;
		if (VersionNumbers::lt(V, req->min_version)) return FALSE;
	}
	if (VersionNumbers::is_null(req->max_version) == FALSE) {
		if (VersionNumbers::is_null(V)) return TRUE;
		if (VersionNumbers::gt(V, req->max_version)) return FALSE;
	}
	return TRUE;
}

int Model::ratchet_minimum(inbuild_version_number V, inbuild_requirement *req) {
	if (req == NULL) internal_error("no requirement");
	if (VersionNumbers::is_null(V)) return FALSE;
	if ((VersionNumbers::is_null(req->min_version)) ||
		(VersionNumbers::gt(V, req->min_version))) {
		req->min_version = V;
		return TRUE;
	}
	return FALSE;
}

@h Copies.
A "copy" of a work exists in the file system when we've actually got hold of
some edition of it. For some genres, copies will be files; for others,
directories holding a set of files.

=
typedef struct inbuild_copy {
	struct inbuild_edition *edition;
	struct pathname *location_if_path;
	struct filename *location_if_file;
	general_pointer content; /* the type of which depends on the work's genre */
	struct build_graph *graph;
	MEMORY_MANAGEMENT
} inbuild_copy;

inbuild_copy *Model::copy_in_file(inbuild_edition *edition, filename *F, general_pointer C) {
	inbuild_copy *copy = CREATE(inbuild_copy);
	copy->edition = edition;
	copy->location_if_path = NULL;
	copy->location_if_file = F;
	copy->content = C;
	copy->graph = NULL;
	return copy;
}

inbuild_copy *Model::copy_in_directory(inbuild_edition *edition, pathname *P, general_pointer C) {
	inbuild_copy *copy = CREATE(inbuild_copy);
	copy->edition = edition;
	copy->location_if_path = P;
	copy->location_if_file = NULL;
	copy->content = C;
	copy->graph = NULL;
	return copy;
}

void Model::write_copy(OUTPUT_STREAM, inbuild_copy *C) {
	Works::write(OUT, C->edition->work);
	inbuild_version_number N = C->edition->version;
	if (VersionNumbers::is_null(N) == FALSE) {
		WRITE(" v"); VersionNumbers::to_text(OUT, N);
	}
}

inbuild_copy *Model::claim(text_stream *arg) {
	TEMPORARY_TEXT(ext);
	int pos = Str::len(arg) - 1, dotpos = -1;
	while (pos >= 0) {
		wchar_t c = Str::get_at(arg, pos);
		if (c == FOLDER_SEPARATOR) break;
		if (c == '.') dotpos = pos;
		pos--;
	}
	if (dotpos >= 0)
		Str::substr(ext, Str::at(arg, dotpos+1), Str::end(arg));
	int directory_status = NOT_APPLICABLE;
	if (Str::get_last_char(arg) == FOLDER_SEPARATOR) {
		Str::delete_last_character(arg);
		directory_status = TRUE;
	}
	inbuild_copy *C = NULL;
	if (C == NULL) C = Kits::claim(arg, ext, directory_status);
	DISCARD_TEXT(ext);
	return C;
}
