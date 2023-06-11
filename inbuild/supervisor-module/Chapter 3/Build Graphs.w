[Graphs::] Build Graphs.

Graphs in which vertices correspond to files or copies, and edges to
dependencies between them.

@h Build graphs.
See the Inbuild manual for an introduction to the build graph. Properly
speaking, it is a directed acyclic multigraph which us usually disconnected.

There are two colours of edge: build edges and use edges. A build edge between
A and B means that B must exist and be up-to-date before A can be built.
A use edge between A and B means that B must exist and be up-to-date before
A can be used.

There are three colours of vertex: copy, file and requirement. Copy vertices
correspond to copies which the user does have; requirement vertices to copies
which she doesn't have; and file vertices to unmanaged plain files in
the build process. For example, if an Inform project says it wants to include
an extension which isn't anywhere to be seen, then the project itself is a
copy vertex, as are the Standard Rules extension, the CommandParserKit kit,
and such; the missing extension is represneted by a requirement vertex; and
the story file which the project would compile to, if only it could be
compiled, is a file vertex.

@e COPY_VERTEX from 1
@e FILE_VERTEX
@e REQUIREMENT_VERTEX

=
typedef struct build_vertex {
	int type; /* one of the |*_VERTEX| values above */
	struct linked_list *build_edges; /* of |build_vertex| */
	struct linked_list *use_edges; /* of |build_vertex| */

	struct inbuild_copy *as_copy; /* for |COPY_VERTEX| only */
	struct filename *as_file; /* for |FILE_VERTEX| only */
	struct inbuild_requirement *as_requirement; /* for |REQUIREMENT_VERTEX| only */

	struct text_stream *source_source; /* for |FILE_VERTEX| of a file of I7 source text */
	struct source_file *as_source_file; /* for |FILE_VERTEX| of a file of I7 source text */

	int last_described_in_generation; /* used when recursively printing a graph */

	int build_result; /* whether the most recent build of this succeeded... */
	int last_built_in_generation; /* ...in this build generation */
	int always_build_this; /* i.e., don't look at timestamps hoping to skip it */
	int always_build_dependencies; /* if you build this, first always build its dependencies */
	int never_build_this; /* i.e., trust that it is correct regardless of timestamps */
	struct build_script *script; /* how to build what this node represents */

	CLASS_DEFINITION
} build_vertex;

@h Creation.
First, the three colours of vertex.

=
build_vertex *Graphs::file_vertex(filename *F) {
	build_vertex *V = CREATE(build_vertex);
	V->type = FILE_VERTEX;
	V->build_edges = NEW_LINKED_LIST(build_vertex);
	V->use_edges = NEW_LINKED_LIST(build_vertex);

	V->as_copy = NULL;
	V->as_file = F;
	V->as_requirement = NULL;

	V->source_source = NULL;
	V->as_source_file = NULL;

	V->last_described_in_generation = -1;

	V->build_result = NOT_APPLICABLE; /* has never been built */
	V->last_built_in_generation = -1; /* never seen in any generation */
	V->always_build_this = FALSE;
	V->always_build_dependencies = FALSE;
	V->never_build_this = FALSE;
	V->script = BuildScripts::new();
	return V;
}

build_vertex *Graphs::req_vertex(inbuild_requirement *R) {
	if (R == NULL) internal_error("no requirement");
	build_vertex *V = Graphs::file_vertex(NULL);
	V->type = REQUIREMENT_VERTEX;
	V->as_requirement = R;
	return V;
}

@ Note that each copy is assigned exactly one copy vertex, when it is created.
This function should never otherwise be called.

=
build_vertex *Graphs::copy_vertex(inbuild_copy *C) {
	if (C == NULL) internal_error("no copy");
	if (C->vertex) internal_error("already set");
	C->vertex = Graphs::file_vertex(NULL);
	C->vertex->type = COPY_VERTEX;
	C->vertex->as_copy = C;
	return C->vertex;
}

@ Next, the two colours of edge. Note that between A and B there can be
at most one edge of each colour.

=
void Graphs::need_this_to_build(build_vertex *from, build_vertex *to) {
	if (from == NULL) internal_error("no from");
	if (to == NULL) internal_error("no to");
	if (from == to) internal_error("graph node depends on itself");
	build_vertex *V;
	LOOP_OVER_LINKED_LIST(V, build_vertex, from->build_edges)
		if (V == to) return;
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

@ The script attached to a vertex is a list of instructions for how to build
the resource it refers to. Some vertices have no instructions provided, so:

=
int Graphs::can_be_built(build_vertex *V) {
	if (BuildScripts::script_length(V->script) > 0) return TRUE;
	return FALSE;
}

@h Writing.
This is a suitably indented printout of the graph as seen from a given
vertex: it's used by the Inbuild command |-graph|.

=
int no_desc_generations = 1;
void Graphs::describe(OUTPUT_STREAM, build_vertex *V, int recurse) {
	Graphs::describe_r(OUT, 0, V, recurse, NULL, NOT_APPLICABLE, no_desc_generations++);
}
void Graphs::describe_r(OUTPUT_STREAM, int depth, build_vertex *V,
	int recurse, pathname *stem, int following_build_edge, int description_round) {
	for (int i=0; i<depth; i++) WRITE("  ");
	if (following_build_edge == TRUE) WRITE("--build-> ");
	if (following_build_edge == FALSE) WRITE("--use---> ");
	Graphs::describe_vertex(OUT, V);
	WRITE(" ");
	TEMPORARY_TEXT(T)
	switch (V->type) {
		case COPY_VERTEX: Copies::write_copy(T, V->as_copy); break;
		case REQUIREMENT_VERTEX: Requirements::write(T, V->as_requirement); break;
		case FILE_VERTEX: WRITE("%f", V->as_file); break;
	}
	TEMPORARY_TEXT(S)
	WRITE_TO(S, "%p", stem);
	if (Str::prefix_eq(T, S, Str::len(S))) {
		WRITE("... "); Str::substr(OUT, Str::at(T, Str::len(S)), Str::end(T));
	} else {
		WRITE("%S", T);
	}
	DISCARD_TEXT(S)
	DISCARD_TEXT(T)
	if (V->last_described_in_generation == description_round) { WRITE(" q.v.\n"); return; }
	V->last_described_in_generation = description_round;
	WRITE("\n");
	@<Add locations in verbose mode@>;
	if (recurse) {
		if (V->as_copy) stem = V->as_copy->location_if_path;
		if (V->as_file)
			stem = Filenames::up(V->as_file);
		build_vertex *W;
		LOOP_OVER_LINKED_LIST(W, build_vertex, V->build_edges)
			Graphs::describe_r(OUT, depth+1, W, TRUE, stem, TRUE, description_round);
		LOOP_OVER_LINKED_LIST(W, build_vertex, V->use_edges)
			Graphs::describe_r(OUT, depth+1, W, TRUE, stem, FALSE, description_round);
	}
}

@<Add locations in verbose mode@> =
	if ((V->type == COPY_VERTEX) && (supervisor_verbosity > 0)) {
		for (int i=0; i<depth; i++) WRITE("  ");
		WRITE("        > at ");
		inbuild_copy *C = V->as_copy;
		if ((C) && (C->location_if_file)) WRITE("%f", C->location_if_file);
		if ((C) && (C->location_if_path)) WRITE("%p", C->location_if_path);
		WRITE("\n");
	}

@ =
void Graphs::describe_vertex(OUTPUT_STREAM, build_vertex *V) {
	if (V == NULL) WRITE("<none>");
	else switch (V->type) {
		case COPY_VERTEX: WRITE("[c%d]", V->allocation_id); break;
		case REQUIREMENT_VERTEX: WRITE("[r%d]", V->allocation_id); break;
		case FILE_VERTEX: WRITE("[f%d]", V->allocation_id); break;
	}
}

@ A similar but slightly different recursion for |-build-needs| and |-use-needs|.

=
int unique_graph_scan_count = 1;
int Graphs::get_unique_graph_scan_count(void) {
	return unique_graph_scan_count++;
}

void Graphs::show_needs(OUTPUT_STREAM, build_vertex *V, int uses_only, int paths) {
	Graphs::show_needs_r(OUT, V, 0, 0, uses_only, paths, Graphs::get_unique_graph_scan_count());
}

void Graphs::show_needs_r(OUTPUT_STREAM, build_vertex *V,
	int depth, int true_depth, int uses_only, int paths, int scan_count) {
	if (V->type == COPY_VERTEX) {
		inbuild_copy *C = V->as_copy;
		if (C->last_scanned != scan_count) {
			C->last_scanned = scan_count;
			for (int i=0; i<depth; i++) WRITE("  ");
			WRITE("%S: ", C->edition->work->genre->genre_name);
			Copies::write_copy(OUT, C);
			WRITE("\n");
			if (paths) @<Add needs-locations@>;
		}
		depth++;
	}
	if (V->type == REQUIREMENT_VERTEX) {
		if (paths == FALSE) for (int i=0; i<depth; i++) WRITE("  ");
		WRITE("missing %S: ", V->as_requirement->work->genre->genre_name);
		Works::write(OUT, V->as_requirement->work);
		if (VersionNumberRanges::is_any_range(V->as_requirement->version_range) == FALSE) {
			WRITE(", need version in range ");
			VersionNumberRanges::write_range(OUT, V->as_requirement->version_range);
		} else {
			WRITE(", any version will do");
		}
		WRITE("\n");
		depth++;
	}
	build_vertex *W;
	if (uses_only == FALSE)
		LOOP_OVER_LINKED_LIST(W, build_vertex, V->build_edges)
			Graphs::show_needs_r(OUT, W, depth, true_depth+1, uses_only, paths, scan_count);
	if ((V->type == COPY_VERTEX) && ((true_depth > 0) || (uses_only))) {
		LOOP_OVER_LINKED_LIST(W, build_vertex, V->use_edges)
			Graphs::show_needs_r(OUT, W, depth, true_depth+1, uses_only, paths, scan_count);
	}
}

@<Add needs-locations@> =
	for (int i=0; i<depth; i++) WRITE("  ");
	int L = Str::len(C->edition->work->genre->genre_name) + 2;
	for (int i=0; i<L; i++) WRITE(" ");
	if ((C) && (C->location_if_file)) WRITE("at %f", C->location_if_file);
	else if ((C) && (C->location_if_path)) WRITE("at %p", C->location_if_path);
	else WRITE("?unlocated");
	WRITE("\n");

@ And for |-build-missing| and |-use-missing|.

=
int Graphs::show_missing(OUTPUT_STREAM, build_vertex *V, int uses_only) {
	return Graphs::show_missing_r(OUT, V, 0, uses_only);
}

int Graphs::show_missing_r(OUTPUT_STREAM, build_vertex *V,
	int true_depth, int uses_only) {
	int N = 0;
	if (V->type == REQUIREMENT_VERTEX) {
		WRITE("missing %S: ", V->as_requirement->work->genre->genre_name);
		Works::write(OUT, V->as_requirement->work);
		if (VersionNumberRanges::is_any_range(V->as_requirement->version_range) == FALSE) {
			WRITE(", need version in range ");
			VersionNumberRanges::write_range(OUT, V->as_requirement->version_range);
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

@h Archiving.
This isn't simply a matter of printing out, of course, but very similar code
handles |-archive| and |-archive-to N|.

Note that the English language definition, which lives in the internal nest,
cannot be read from any other nest -- so we won't archive it.

=
void Graphs::archive(OUTPUT_STREAM, build_vertex *V, inbuild_nest *N,
	build_methodology *BM) {
	Graphs::archive_r(OUT, V, 0, N, BM);
}

void Graphs::archive_r(OUTPUT_STREAM, build_vertex *V, int true_depth, inbuild_nest *N,
	build_methodology *BM) {
	if (V->type == COPY_VERTEX) {
		inbuild_copy *C = V->as_copy;
		if ((Genres::stored_in_nests(C->edition->work->genre)) &&
			((Str::ne(C->edition->work->title, I"English")) ||
				(Str::len(C->edition->work->author_name) > 0)))
			@<Archive a single copy@>;
	}
	build_vertex *W;
	LOOP_OVER_LINKED_LIST(W, build_vertex, V->build_edges)
		Graphs::archive_r(OUT, W, true_depth+1, N, BM);
	if ((V->type == COPY_VERTEX) && (true_depth > 0)) {
		LOOP_OVER_LINKED_LIST(W, build_vertex, V->use_edges)
			Graphs::archive_r(OUT, W, true_depth+1, N, BM);
	}
}

@ The most delicate thing here is that we don't want to archive something
to |N| if it's already there; but that is difficult to detect.

@<Archive a single copy@> =
	WRITE("%S: ", C->edition->work->genre->genre_name);
	Copies::write_copy(OUT, C);

	pathname *P = C->location_if_path;
	if (C->location_if_file) P = Filenames::up(C->location_if_file);
	TEMPORARY_TEXT(nl)
	TEMPORARY_TEXT(cl)
	WRITE_TO(nl, "%p/", N->location);
	WRITE_TO(cl, "%p/", P);
	if (Str::prefix_eq(cl, nl, Str::len(nl))) {
		WRITE(" -- already there\n");
	} else {
		WRITE(" -- archiving\n");
		Copies::copy_to(C, N, TRUE, BM);
	}
	DISCARD_TEXT(nl)
	DISCARD_TEXT(cl)
