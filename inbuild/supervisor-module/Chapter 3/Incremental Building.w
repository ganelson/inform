[IncrementalBuild::] Incremental Building.

Deciding what is the least possible amount which needs to be built, in what
order, to arrive at a working version of a copy.

@h Timestamps.
We want to assign a timestamp to every vertex in the graph, whose meaning is
that what it represents has been up-to-date since that time.

For a file vertex, we take that from the file system's timestamp. For a
copy vertex, we do the same for a copy which is a single file (such as an
extension), but for a copy which is a directory containing a composite of
resources, there's no good way to know. (Perhaps we could scan the files
in it recursively, but then we have to worry about hidden files, symlinks,
and all of that.) Instead, we use the build graph itself to decide; for
example, the timestamp for a kit is the most recent timestamp of any of its
binary Inter files, because those are its build-dependencies.

=
time_t IncrementalBuild::timestamp(build_vertex *V) {
	switch (V->type) {
		case FILE_VERTEX:
			return Filenames::timestamp(V->as_file);
		case COPY_VERTEX:
			if (V->as_copy->location_if_file)
				return Filenames::timestamp(V->as_copy->location_if_file);
			return IncrementalBuild::time_of_latest_build_dependency(V);
		default:
			return Platform::never_time();
	}
}

@ The following compares two times: it returns 1 if |t1| is later, -1 if
|t2| is later, and 0 if they are identical.

Note that we never apply the C standard library function |difftime| in
the case of the never-time, which we consider to be before all other times.
(On most platforms it will be the C epoch of 1970, and |difftime| alone
would be fine, but we're being careful.)

=
int IncrementalBuild::timecmp(time_t t1, time_t t2) {
	if (t1 == Platform::never_time()) {
		if (t2 == Platform::never_time()) return 0;
		return -1;
	}
	if (t2 == Platform::never_time()) {
		return 1;
	}
	if (t1 == t2) return 0;
	if (difftime(t1, t2) > 0) return 1;
	return -1;
}

@ We then take the latest timestamp of any build dependency:

=
time_t IncrementalBuild::time_of_latest_build_dependency(build_vertex *V) {
	time_t latest = Platform::never_time();

	build_vertex *W;
	LOOP_OVER_LINKED_LIST(W, build_vertex, V->build_edges) {
		time_t t = IncrementalBuild::timestamp(W);
		if (IncrementalBuild::timecmp(t, latest) > 0) latest = t;
	}

	return latest;
}

@ And of any use dependency:

=
time_t IncrementalBuild::time_of_latest_use_dependency(build_vertex *V) {
	time_t latest = Platform::never_time();

	build_vertex *W;
	LOOP_OVER_LINKED_LIST(W, build_vertex, V->use_edges) {
		time_t t = IncrementalBuild::timestamp(W);
		if (IncrementalBuild::timecmp(t, latest) > 0) latest = t;
	}

	return latest;
}

@h Build process.
This is a recursive process, beginning at the node representing what we want
to build. As we recurse, we pass a bitmap of the following:

@d BUILD_DEPENDENCIES_MATTER_GB 1 /* We will need all your build dependencies too */
@d USE_DEPENDENCIES_MATTER_GB 2 /* We will need all your use dependencies too */
@d IGNORE_TIMESTAMPS_GB 4 /* Don't be incremental: trust nothing, rebuild everything */
@d FOR_ONE_GENERATION_IGNORE_TIMESTAMPS_GB 8 /* Don't be incremental: trust nothing, rebuild everything */

=
int IncrementalBuild::build(OUTPUT_STREAM, build_vertex *V, build_methodology *meth) {
	return IncrementalBuild::begin_recursion(OUT,
		BUILD_DEPENDENCIES_MATTER_GB, V, meth);
}
int IncrementalBuild::rebuild(OUTPUT_STREAM, build_vertex *V, build_methodology *meth) {
	return IncrementalBuild::begin_recursion(OUT,
		BUILD_DEPENDENCIES_MATTER_GB + IGNORE_TIMESTAMPS_GB, V, meth);
}

@ This is called when Inbuild's |-trace| switch is set at the command line.

=
int trace_ibg = FALSE;
void IncrementalBuild::enable_trace(void) {
	trace_ibg = TRUE;
}

@ We want to be very sure that this recursion does not lock up, or perform
unnecessary work by performing the same node twice. To do this we apply the
|built| flag to a node when it has been built; but to make this is not left
over from last time around, we only regard it when the |last_built_in_generation| count
for the node is set to the current "generation", a unique number incremented
for each time we recurse.

=
int no_build_generations = 0;
int IncrementalBuild::begin_recursion(OUTPUT_STREAM, int gb, build_vertex *V,
	build_methodology *BM) {
	int changes = 0;
	text_stream *T = NULL;
	if (trace_ibg) T = STDOUT;
	no_build_generations++;
	WRITE_TO(T, "Incremental build %d:\n", no_build_generations);
	int rv = IncrementalBuild::recurse(OUT, T, gb, V, BM, &changes,
		no_build_generations, Supervisor::shared_nest_list());
	WRITE_TO(T, "%d change(s)\n", changes);
	return rv;
}

int IncrementalBuild::recurse(OUTPUT_STREAM, text_stream *T, int gb, build_vertex *V,
	build_methodology *BM, int *changes, int generation, linked_list *search_list) {
	if (T) {
		WRITE_TO(T, "Visit %c%c%c: ",
			(gb & BUILD_DEPENDENCIES_MATTER_GB)?'b':'.',
			(gb & USE_DEPENDENCIES_MATTER_GB)?'u':'.',
			(gb & IGNORE_TIMESTAMPS_GB)?'i':'.');
		Graphs::describe(T, V, FALSE);
	}

	if (V->last_built_in_generation == generation) return V->build_result;
	int rv = TRUE;
	@<Build this node if necessary, setting rv to its success or failure@>;
	V->build_result = rv;
	V->last_built_in_generation = generation;
	return rv;
}

@ In everything which follows, |rv| (prosaically, this stands only for "return
value") remains |TRUE| until the first active step fails, at which point no
other active steps are ever taken, nor are any recursions made. In effect,
the first failure halts the process.

We are recursing depth-first, that is, we build the things needed to build
|V| before we build |V| itself.

A point of difference between this algorithm and |make| is that we do not
halt with an error if a node has no way to be built. This is because the
graphs are here are built by Inbuild itself, not by a possibly erroneous
makefile whose author has forgotten something and whose intentions are not
clear. Here, if a node has no build script attached, it must be because it
needs no action taken.

@<Build this node if necessary, setting rv to its success or failure@> =
	if (V->as_copy) {
		inform_project *proj = Projects::from_copy(V->as_copy);
		if (proj) search_list = Projects::nest_list(proj);
	}
	
	if (T) STREAM_INDENT(T);
	if (gb & BUILD_DEPENDENCIES_MATTER_GB) @<Build the build dependencies of the node@>;
	if (gb & USE_DEPENDENCIES_MATTER_GB) @<Build the use dependencies of the node@>;
	if (T) STREAM_OUTDENT(T);
	if ((rv) && (Graphs::can_be_built(V))) @<Build the node itself, if necessary@>;

@ Suppose V needs W (for whatever reason), and that W can only be used with X.
It follows that we will have to build X as well as W, since the process of
building V is itself a use of W, and therefore of X. So we always enable the
|USE_DEPENDENCIES_MATTER_GB| bit when recursing through an edge.

@<Build the build dependencies of the node@> =
	int b = gb | USE_DEPENDENCIES_MATTER_GB;
	if (b & FOR_ONE_GENERATION_IGNORE_TIMESTAMPS_GB) b -= FOR_ONE_GENERATION_IGNORE_TIMESTAMPS_GB;
	if (V->always_build_dependencies) b |= FOR_ONE_GENERATION_IGNORE_TIMESTAMPS_GB;
	build_vertex *W;
	LOOP_OVER_LINKED_LIST(W, build_vertex, V->build_edges)
		if (rv)
			rv = IncrementalBuild::recurse(OUT, T,
				b, W, BM, changes, generation, search_list);

@<Build the use dependencies of the node@> =
	int b = gb | USE_DEPENDENCIES_MATTER_GB;
	if (b & FOR_ONE_GENERATION_IGNORE_TIMESTAMPS_GB) b -= FOR_ONE_GENERATION_IGNORE_TIMESTAMPS_GB;
	build_vertex *W;
	LOOP_OVER_LINKED_LIST(W, build_vertex, V->use_edges)
		if (rv)
			rv = IncrementalBuild::recurse(OUT, T,
				b | USE_DEPENDENCIES_MATTER_GB, W, BM, changes, generation, search_list);

@ Now for the node |V| itself.

@<Build the node itself, if necessary@> =
	int needs_building = FALSE;
	if ((gb & IGNORE_TIMESTAMPS_GB) || (gb & FOR_ONE_GENERATION_IGNORE_TIMESTAMPS_GB) ||
		(V->always_build_this)) {
		WRITE_TO(T, "Ignoring timestamps and simply building: ");
		Graphs::describe(T, V, FALSE);
		needs_building = TRUE;
	} else {
		if (V->never_build_this) {
			WRITE_TO(T, "Ignoring timestamps and simply trusting: ");
			Graphs::describe(T, V, FALSE);
		} else {
			@<Decide based on timestamps@>;
		}
	}

	if (needs_building) {
		if (T) { WRITE_TO(T, "Build: "); Graphs::describe(T, V, FALSE); }
		(*changes)++;
		rv = BuildScripts::execute(V, V->script, BM, search_list);
	} else {
		if (T) { WRITE_TO(T, "No build\n"); }
	}

@ This is where the incremental promise is finally kept. If the timestamp of
|V| is definitely before later than that of everything it depends on, then
it would be redundant to recreate it.

Note that equal timestamps force rebuilding. File timestamping is quite coarse
on some systems, so equal timestamps might only mean that the two files were
created during the same second.

@<Decide based on timestamps@> =
	time_t last_up_to_date_at = IncrementalBuild::timestamp(V);
	if (last_up_to_date_at == Platform::never_time())
		needs_building = TRUE;
	else {
		if (T) { WRITE_TO(T, "Last built at: %s\n", ctime(&last_up_to_date_at)); }
		if (gb & BUILD_DEPENDENCIES_MATTER_GB) {
			time_t t = IncrementalBuild::time_of_latest_build_dependency(V);
			if (T) { WRITE_TO(T, "Most recent build dependency: %s\n", ctime(&t)); }
			if (IncrementalBuild::timecmp(t, last_up_to_date_at) >= 0)
				needs_building = TRUE;
		}
		if (gb & USE_DEPENDENCIES_MATTER_GB) {
			time_t t = IncrementalBuild::time_of_latest_use_dependency(V);
			if (T) { WRITE_TO(T, "Most recent use dependency: %s\n", ctime(&t)); }
			if (IncrementalBuild::timecmp(t, last_up_to_date_at) >= 0)
				needs_building = TRUE;
		}
	}
