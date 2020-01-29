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

=
typedef struct build_graph {
	struct inbuild_copy *buildable_if_copy;
	struct filename *buildable_if_internal_file;
	struct linked_list *arrows; /* of pointers to other |build_graph| nodes */
	struct build_script *script;
	time_t timestamp;
	MEMORY_MANAGEMENT
} build_graph;

build_graph *Graphs::internal_vertex(filename *F) {
	build_graph *G = CREATE(build_graph);
	G->buildable_if_copy = NULL;
	G->buildable_if_internal_file = F;
	G->arrows = NEW_LINKED_LIST(build_graph);
	G->timestamp = (time_t) 0;
	G->script = BuildSteps::new_script();
	return G;
}

build_graph *Graphs::copy_vertex(inbuild_copy *C) {
	if (C == NULL) internal_error("no copy");
	if (C->graph == NULL) {
		C->graph = Graphs::internal_vertex(NULL);
		C->graph->buildable_if_copy = C;
	}
	return C->graph;
}

void Graphs::arrow(build_graph *from, build_graph *to) {
	if (from == NULL) internal_error("no from");
	if (to == NULL) internal_error("no to");
	if (from == to) internal_error("graph node depends on itself");
	build_graph *G;
	LOOP_OVER_LINKED_LIST(G, build_graph, from->arrows)
		if (G == to) return;
	ADD_TO_LINKED_LIST(to, build_graph, from->arrows);
}

void Graphs::describe(OUTPUT_STREAM, build_graph *G, int recurse) {
	Graphs::describe_r(OUT, 0, G, recurse);
}
void Graphs::describe_r(OUTPUT_STREAM, int depth, build_graph *V, int recurse) {
	for (int i=0; i<depth; i++) WRITE("  ");
	if (V->buildable_if_copy) {
		WRITE("[copy%d] ", V->allocation_id);
		Model::write_work(OUT, V->buildable_if_copy->edition->work);
		inbuild_version_number N = V->buildable_if_copy->edition->version;
		if (VersionNumbers::is_null(N) == FALSE) {
			WRITE(" v"); VersionNumbers::to_text(OUT, N);
		}
		WRITE("\n");
	} else {
		Graphs::update_timestamp(V);
		WRITE("[int%d] %f", V->allocation_id, V->buildable_if_internal_file);
		if (V->timestamp != (time_t) 0) WRITE(" %s", ctime(&(V->timestamp)));
		else WRITE("\n");
	}
	if (recurse) {
		build_graph *W;
		LOOP_OVER_LINKED_LIST(W, build_graph, V->arrows)
			Graphs::describe_r(OUT, depth+1, W, TRUE);
	}
}

void Graphs::update_timestamp(build_graph *V) {
	if (V == NULL) return;
	if (V->buildable_if_internal_file == NULL) return;
	char transcoded_pathname[4*MAX_FILENAME_LENGTH];
	TEMPORARY_TEXT(FN);
	WRITE_TO(FN, "%f", V->buildable_if_internal_file);
	Str::copy_to_locale_string(transcoded_pathname, FN, 4*MAX_FILENAME_LENGTH);
	DISCARD_TEXT(FN);
    struct stat filestat;
	if (stat(transcoded_pathname, &filestat) == -1) { V->timestamp = (time_t) 0; return; }
	V->timestamp = filestat.st_mtime;
}

void Graphs::build(build_graph *G, build_methodology *meth) {
	Graphs::build_r(FALSE, G, meth);
}
void Graphs::rebuild(build_graph *G, build_methodology *meth) {
	Graphs::build_r(TRUE, G, meth);
}
void Graphs::build_r(int forcing_build, build_graph *V, build_methodology *meth) {
	int needs_building = forcing_build;
	if (V->buildable_if_internal_file)
		if (TextFiles::exists(V->buildable_if_internal_file) == FALSE)
			needs_building = TRUE;
	build_graph *W;
	LOOP_OVER_LINKED_LIST(W, build_graph, V->arrows)
		Graphs::build_r(forcing_build, W, meth);
	if (needs_building == FALSE) {
		Graphs::update_timestamp(V);
		LOOP_OVER_LINKED_LIST(W, build_graph, V->arrows) {
			Graphs::update_timestamp(W);
			double since = difftime(V->timestamp, W->timestamp);
			if (since < 0) { needs_building = TRUE; break; }
		}
	}
	if (needs_building) BuildSteps::execute(V->script, meth);
}
