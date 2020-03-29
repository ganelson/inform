[Graphs::] Build Graphs.

Graphs in which vertices correspond to files or copies, and arrows to
dependencies between them.

@h Build graphs.
These are directed acyclic graphs which show what depends on what in the
building process. If an arrow leads from A to B, then B must be built before
A can be built.

There can be two sorts of vertex in such a graph: copy vertices, each of which
belongs to a single copy, and internal vertices, each of which represents
a different file inside the copy.

@e COPY_VERTEX from 1
@e REQUIREMENT_VERTEX
@e FILE_VERTEX
@e GHOST_VERTEX

=
typedef struct build_vertex {
	int type; /* one of the |*_VERTEX| values above */
	struct inbuild_copy *buildable_if_copy;
	struct filename *buildable_if_internal_file;
	struct inbuild_requirement *findable;
	struct text_stream *annotation;
	struct source_file *read_as;
	struct linked_list *build_edges; /* of |build_vertex| */
	struct linked_list *use_edges; /* of |build_vertex| */
	struct build_script *script;
	int last_described;
	int built;
	int force_this;
	MEMORY_MANAGEMENT
} build_vertex;

build_vertex *Graphs::file_vertex(filename *F) {
	build_vertex *V = CREATE(build_vertex);
	V->type = FILE_VERTEX;
	V->buildable_if_copy = NULL;
	V->buildable_if_internal_file = F;
	V->build_edges = NEW_LINKED_LIST(build_vertex);
	V->use_edges = NEW_LINKED_LIST(build_vertex);
	V->script = BuildScripts::new();
	V->annotation = NULL;
	V->read_as = NULL;
	V->last_described = 0;
	V->built = FALSE;
	V->force_this = FALSE;
	return V;
}

build_vertex *Graphs::copy_vertex(inbuild_copy *C) {
	if (C == NULL) internal_error("no copy");
	if (C->vertex == NULL) {
		C->vertex = Graphs::file_vertex(NULL);
		C->vertex->type = COPY_VERTEX;
		C->vertex->buildable_if_copy = C;
	}
	return C->vertex;
}

build_vertex *Graphs::req_vertex(inbuild_requirement *R) {
	if (R == NULL) internal_error("no requirement");
	build_vertex *V = Graphs::file_vertex(NULL);
	V->type = REQUIREMENT_VERTEX;
	V->findable = R;
	return V;
}

build_vertex *Graphs::ghost_vertex(text_stream *S) {
	build_vertex *V = Graphs::file_vertex(NULL);
	V->type = GHOST_VERTEX;
	V->annotation = Str::duplicate(S);
	return V;
}

void Graphs::need_this_to_build(build_vertex *from, build_vertex *to) {
	if (from == NULL) internal_error("no from");
	if (to == NULL) internal_error("no to");
	if (from == to) internal_error("graph node depends on itself");
	build_vertex *V;
	LOOP_OVER_LINKED_LIST(V, build_vertex, from->build_edges)
		if (V == to) return;
	// Graphs::describe(STDOUT, from, FALSE); PRINT(" needs ");
	// Graphs::describe(STDOUT, to, FALSE); PRINT("\n");
	ADD_TO_LINKED_LIST(to, build_vertex, from->build_edges);
}

void Graphs::need_this_to_use(build_vertex *from, build_vertex *to) {
	if (from == NULL) internal_error("no from");
	if (to == NULL) internal_error("no to");
	if (from == to) internal_error("graph node depends on itself");
	build_vertex *V;
	LOOP_OVER_LINKED_LIST(V, build_vertex, from->use_edges)
		if (V == to) return;
	ADD_TO_LINKED_LIST(to, build_vertex, from->use_edges);
}

int description_round = 1;
void Graphs::describe(OUTPUT_STREAM, build_vertex *V, int recurse) {
	Graphs::describe_r(OUT, 0, V, recurse, NULL, NOT_A_GB, description_round++);
}
void Graphs::describe_r(OUTPUT_STREAM, int depth, build_vertex *V,
	int recurse, pathname *stem, int which, int description_round) {
	for (int i=0; i<depth; i++) WRITE("  ");
	if (which == BUILD_GB) WRITE("--build-> ");
	if (which == USE_GB)   WRITE("--use---> ");
	Graphs::describe_vertex(OUT, V);
	WRITE(" ");
	if (V->last_described == description_round) { WRITE("q.v.\n"); return; }
	TEMPORARY_TEXT(T);
	switch (V->type) {
		case COPY_VERTEX: Copies::write_copy(T, V->buildable_if_copy); break;
		case REQUIREMENT_VERTEX: Requirements::write(T, V->findable); break;
		case FILE_VERTEX: WRITE("%f", V->buildable_if_internal_file); break;
		case GHOST_VERTEX: WRITE("(%S)", V->annotation); break;
	}
	TEMPORARY_TEXT(S);
	WRITE_TO(S, "%p", stem);
	if (Str::prefix_eq(T, S, Str::len(S))) {
		WRITE("... "); Str::substr(OUT, Str::at(T, Str::len(S)), Str::end(T));
	} else {
		WRITE("%S", T);
	}
	DISCARD_TEXT(S);
	DISCARD_TEXT(T);
	WRITE("\n");
	if (recurse) {
		if (V->buildable_if_copy) stem = V->buildable_if_copy->location_if_path;
		if (V->buildable_if_internal_file)
			stem = Filenames::get_path_to(V->buildable_if_internal_file);
		build_vertex *W;
		LOOP_OVER_LINKED_LIST(W, build_vertex, V->build_edges)
			Graphs::describe_r(OUT, depth+1, W, TRUE, stem, BUILD_GB, description_round);
		LOOP_OVER_LINKED_LIST(W, build_vertex, V->use_edges)
			Graphs::describe_r(OUT, depth+1, W, TRUE, stem, USE_GB, description_round);
	}
}

void Graphs::describe_vertex(OUTPUT_STREAM, build_vertex *V) {
	if (V == NULL) WRITE("<none>");
	else switch (V->type) {
		case COPY_VERTEX: WRITE("[c%d]", V->allocation_id); break;
		case REQUIREMENT_VERTEX: WRITE("[r%d]", V->allocation_id); break;
		case FILE_VERTEX: WRITE("[f%d]", V->allocation_id); break;
		case GHOST_VERTEX: WRITE("[g%d]", V->allocation_id); break;
	}
}

void Graphs::show_needs(OUTPUT_STREAM, build_vertex *V, int uses_only) {
	Graphs::show_needs_r(OUT, V, 0, 0, uses_only);
}

void Graphs::show_needs_r(OUTPUT_STREAM, build_vertex *V, int depth, int true_depth, int uses_only) {
	if (V->type == COPY_VERTEX) {
		for (int i=0; i<depth; i++) WRITE("  ");
		inbuild_copy *C = V->buildable_if_copy;
		WRITE("%S: ", C->edition->work->genre->genre_name);
		Copies::write_copy(OUT, C); WRITE("\n");
		depth++;
	}
	if (V->type == REQUIREMENT_VERTEX) {
		for (int i=0; i<depth; i++) WRITE("  ");
		WRITE("missing %S: ", V->findable->work->genre->genre_name);
		Works::write(OUT, V->findable->work);
		if (VersionNumberRanges::is_any_range(V->findable->version_range) == FALSE) {
			WRITE(", need version in range "); VersionNumberRanges::write_range(OUT, V->findable->version_range);
		} else {
			WRITE(", any version will do");
		}
		WRITE("\n");
		depth++;
	}
	build_vertex *W;
	if (uses_only == FALSE)
		LOOP_OVER_LINKED_LIST(W, build_vertex, V->build_edges)
			Graphs::show_needs_r(OUT, W, depth, true_depth+1, uses_only);
	if ((V->type == COPY_VERTEX) && ((true_depth > 0) || (uses_only))) {
		LOOP_OVER_LINKED_LIST(W, build_vertex, V->use_edges)
			Graphs::show_needs_r(OUT, W, depth, true_depth+1, uses_only);
	}
}

int Graphs::show_missing(OUTPUT_STREAM, build_vertex *V, int uses_only) {
	return Graphs::show_missing_r(OUT, V, 0, uses_only);
}

int Graphs::show_missing_r(OUTPUT_STREAM, build_vertex *V, int true_depth, int uses_only) {
	int N = 0;
	if (V->type == REQUIREMENT_VERTEX) {
		WRITE("missing %S: ", V->findable->work->genre->genre_name);
		Works::write(OUT, V->findable->work);
		if (VersionNumberRanges::is_any_range(V->findable->version_range) == FALSE) {
			WRITE(", need version in range "); VersionNumberRanges::write_range(OUT, V->findable->version_range);
		} else {
			WRITE(", any version will do");
		}
		WRITE("\n");
		N = 1;
	}
	build_vertex *W;
	if (uses_only == FALSE)
		LOOP_OVER_LINKED_LIST(W, build_vertex, V->build_edges)
			N += Graphs::show_missing_r(OUT, W, true_depth+1, uses_only);
	if ((V->type == COPY_VERTEX) && ((true_depth > 0) || (uses_only))) {
		LOOP_OVER_LINKED_LIST(W, build_vertex, V->use_edges)
			N += Graphs::show_missing_r(OUT, W, true_depth+1, uses_only);
	}
	return N;
}

void Graphs::archive(OUTPUT_STREAM, build_vertex *V, inbuild_nest *N, build_methodology *BM) {
	Graphs::archive_r(OUT, V, 0, N, BM);
}

void Graphs::archive_r(OUTPUT_STREAM, build_vertex *V, int true_depth, inbuild_nest *N, build_methodology *BM) {
	if (V->type == COPY_VERTEX) {
		inbuild_copy *C = V->buildable_if_copy;
		if ((Genres::stored_in_nests(C->edition->work->genre)) &&
			((Str::ne(C->edition->work->title, I"English")) ||
				(Str::len(C->edition->work->author_name) > 0))) {
			WRITE("%S: ", C->edition->work->genre->genre_name);
			Copies::write_copy(OUT, C);

			pathname *P = C->location_if_path;
			if (C->location_if_file) P = Filenames::get_path_to(C->location_if_file);
			TEMPORARY_TEXT(nl);
			TEMPORARY_TEXT(cl);
			WRITE_TO(nl, "%p/", N->location);
			WRITE_TO(cl, "%p/", P);
			if (Str::prefix_eq(cl, nl, Str::len(nl))) {
				WRITE(" -- already there\n");
			} else {
				WRITE(" -- archiving\n");
				Copies::copy_to(C, N, TRUE, BM);
			}
			DISCARD_TEXT(nl);
			DISCARD_TEXT(cl);
		}
	}
	build_vertex *W;
	LOOP_OVER_LINKED_LIST(W, build_vertex, V->build_edges)
		Graphs::archive_r(OUT, W, true_depth+1, N, BM);
	if ((V->type == COPY_VERTEX) && (true_depth > 0)) {
		LOOP_OVER_LINKED_LIST(W, build_vertex, V->use_edges)
			Graphs::archive_r(OUT, W, true_depth+1, N, BM);
	}
}

time_t Graphs::timestamp_for(build_vertex *V) {
	time_t latest = (time_t) 0;

	if (V->buildable_if_internal_file) {
		char transcoded_pathname[4*MAX_FILENAME_LENGTH];
		TEMPORARY_TEXT(FN);
		WRITE_TO(FN, "%f", V->buildable_if_internal_file);
		Str::copy_to_locale_string(transcoded_pathname, FN, 4*MAX_FILENAME_LENGTH);
		DISCARD_TEXT(FN);
		struct stat filestat;
		if (stat(transcoded_pathname, &filestat) != -1) latest = filestat.st_mtime;
	} else {
		latest = Graphs::time_of_most_recent_ingredient(V);
	}

	return latest;
}

time_t Graphs::time_of_most_recent_ingredient(build_vertex *V) {
	time_t latest = (time_t) 0;

	build_vertex *W;
	LOOP_OVER_LINKED_LIST(W, build_vertex, V->build_edges) {
		time_t inner = Graphs::timestamp_for(W);
		if ((latest == (time_t) 0) || (difftime(inner, latest) > 0))
			latest = inner;
	}

	return latest;
}

time_t Graphs::time_of_most_recent_used_resource(build_vertex *V) {
	time_t latest = (time_t) 0;

	build_vertex *W;
	LOOP_OVER_LINKED_LIST(W, build_vertex, V->use_edges) {
		time_t inner = Graphs::timestamp_for(W);
		if ((latest == (time_t) 0) || (difftime(inner, latest) > 0))
			latest = inner;
	}

	return latest;
}

@

@d NOT_A_GB 0
@d BUILD_GB 1
@d FORCE_GB 2
@d USE_GB 4

=
int Graphs::build(OUTPUT_STREAM, build_vertex *V, build_methodology *meth) {
	int changes = 0;
	return Graphs::build_r(OUT, BUILD_GB, V, meth, &changes);
}
int Graphs::rebuild(OUTPUT_STREAM, build_vertex *V, build_methodology *meth) {
	int changes = 0;
	return Graphs::build_r(OUT, BUILD_GB + FORCE_GB, V, meth, &changes);
}
int trace_ibg = FALSE;
int Graphs::build_r(OUTPUT_STREAM, int gb, build_vertex *V, build_methodology *meth, int *changes) {
	if (trace_ibg) { WRITE_TO(STDOUT, "Visit: "); Graphs::describe(STDOUT, V, FALSE); }

	if (V->built) return TRUE;

	int changes_so_far = *changes;
	if (trace_ibg) { STREAM_INDENT(STDOUT); }
	int rv = TRUE;
	build_vertex *W;
	LOOP_OVER_LINKED_LIST(W, build_vertex, V->build_edges)
		if (rv)
			rv = Graphs::build_r(OUT, gb | USE_GB, W, meth, changes);
	if (gb & USE_GB)
		LOOP_OVER_LINKED_LIST(W, build_vertex, V->use_edges)
			if (rv)
				rv = Graphs::build_r(OUT, gb & (BUILD_GB + FORCE_GB), W, meth, changes);
	if (trace_ibg) { STREAM_OUTDENT(STDOUT); }
	if (rv) {
		int needs_building = FALSE;
		if ((gb & FORCE_GB) || (V->force_this)) needs_building = TRUE;
		else if ((V->type == GHOST_VERTEX) && (*changes > changes_so_far)) needs_building = TRUE;
		else @<Decide based on timestamps@>;

		if ((needs_building) && (BuildScripts::script_length(V->script) > 0)) {
			if (trace_ibg) { WRITE_TO(STDOUT, "Build: "); Graphs::describe(STDOUT, V, FALSE); }
			(*changes)++;
			rv = BuildScripts::execute(V, V->script, meth);
		} else {
			if (trace_ibg) { WRITE_TO(STDOUT, "No Build\n"); }
		}
	}
	V->built = rv;
	return rv;
}

@<Decide based on timestamps@> =
	time_t last_built_at = Graphs::timestamp_for(V);
	if (trace_ibg) { WRITE_TO(STDOUT, "Last built at: %08x\n", last_built_at); }
	if (last_built_at == (time_t) 0)
		needs_building = TRUE;
	else {
		time_t time_of_most_recent = Graphs::time_of_most_recent_ingredient(V);
		if (time_of_most_recent != (time_t) 0) {
			if (trace_ibg) { WRITE_TO(STDOUT, "Most recent: %08x\n", time_of_most_recent); }
			if (difftime(time_of_most_recent, last_built_at) > 0)
				needs_building = TRUE;
		}
		if (gb & USE_GB) {
			time_t time_of_most_recent_used = Graphs::time_of_most_recent_used_resource(V);
			if (time_of_most_recent_used != (time_t) 0) {
				if (trace_ibg) { WRITE_TO(STDOUT, "Most recent use: %08x\n", time_of_most_recent_used); }
				if (difftime(time_of_most_recent_used, last_built_at) > 0)
					needs_building = TRUE;
			}
		}
	}
