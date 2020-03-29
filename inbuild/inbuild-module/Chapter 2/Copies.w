[Copies::] Copies.

A copy is an instance in the file system of a specific edition of a work.

@h Creation.
A "copy" of a work exists in the file system when we've actually got hold of
some edition of it. For some genres, copies will be files; for others,
directories holding a set of files.

A purist view would be that a copy is simply an edition at a location in the
file system. And so it is. But copies are the main things Inbuild works on,
and we will need to generate data about them, some of which is most usefully
stored here.

=
typedef struct inbuild_copy {
	struct inbuild_edition *edition; /* what is this a copy of? */
	struct pathname *location_if_path; /* exactly one of these must be non-|NULL| */
	struct filename *location_if_file;

	general_pointer content; /* the type of which depends on the work's genre */
	struct build_vertex *vertex; /* head vertex of build graph for this copy */
	int source_text_read; /* have we attempted to read Inform source text from this? */
	struct wording source_text; /* the source text we read, if so */
	struct inbuild_requirement *found_by; /* if this was claimed in a search */
	struct linked_list *errors_reading_source_text; /* of |copy_error| */
	MEMORY_MANAGEMENT
} inbuild_copy;

@ Copies are created by the managers for the respective genres, usually when
claiming. If you are a manager, do not call this...

=
inbuild_copy *Copies::new_p(inbuild_edition *edition) {
	inbuild_copy *copy = CREATE(inbuild_copy);
	copy->edition = edition;
	copy->location_if_path = NULL;
	copy->location_if_file = NULL;
	copy->content = NULL_GENERAL_POINTER;
	copy->vertex = NULL;
	copy->source_text_read = FALSE;
	copy->source_text = EMPTY_WORDING;
	copy->found_by = NULL;
	copy->errors_reading_source_text = NEW_LINKED_LIST(copy_error);
	return copy;
}

@ ...call one of these:

=
inbuild_copy *Copies::new_in_file(inbuild_edition *edition, filename *F) {
	inbuild_copy *copy = Copies::new_p(edition);
	copy->location_if_file = F;
	return copy;
}

inbuild_copy *Copies::new_in_path(inbuild_edition *edition, pathname *P) {
	inbuild_copy *copy = Copies::new_p(edition);
	copy->location_if_path = P;
	return copy;
}

@ And then probably follow up by calling this, to attach a pointer to some
additional data specific to your genre:

=
void Copies::set_content(inbuild_copy *C, general_pointer ref) {
	C->content = ref;
}

@h List of errors.
When copies are found to be malformed, error messages are attached to them
for later reporting. These are stored in a list.

=
void Copies::attach_error(inbuild_copy *C, copy_error *CE) {
	if (C == NULL) internal_error("no copy to attach to");
	CopyErrors::supply_attached_copy(CE, C);
	ADD_TO_LINKED_LIST(CE, copy_error, C->errors_reading_source_text);
}

void Copies::list_attached_errors(OUTPUT_STREAM, inbuild_copy *C) {
	if (C == NULL) return;
	copy_error *CE;
	int c = 1;
	LOOP_OVER_LINKED_LIST(CE, copy_error, C->errors_reading_source_text) {
		WRITE("%d. ", c++); CopyErrors::write(OUT, CE); WRITE("\n");
	}
}

@h Writing.

=
void Copies::write_copy(OUTPUT_STREAM, inbuild_copy *C) {
	Editions::write(OUT, C->edition);
}

@h Reading source text.

=
int Copies::source_text_has_been_read(inbuild_copy *C) {
	if (C == NULL) internal_error("no copy");
	return C->source_text_read;
}

wording Copies::get_source_text(inbuild_copy *C) {
	if (C->source_text_read == FALSE) {
		C->source_text_read = TRUE;
		feed_t id = Feeds::begin();
		VMETHOD_CALL(C->edition->work->genre, GENRE_READ_SOURCE_TEXT_FOR_MTID, C);
		wording W = Feeds::end(id);
		if (Wordings::nonempty(W)) C->source_text = W;
	}
	return C->source_text;
}

@h Going operational.

=
void Copies::go_operational(inbuild_copy *C) {
	VMETHOD_CALL(C->edition->work->genre, GENRE_GO_OPERATIONAL_MTID, C);
}

@h Miscellaneous Inbuild commands.
This function implements the command-line instruction to |-inspect|.

=
void Copies::inspect(OUTPUT_STREAM, inbuild_copy *C) {
	WRITE("%S: ", Genres::name(C->edition->work->genre));
	Editions::inspect(OUT, C->edition);
	if (C->location_if_path) {
		WRITE(" at path %p", C->location_if_path);
	}
	if (C->location_if_file) {
		pathname *P = Filenames::get_path_to(C->location_if_file);
		if (P) WRITE(" in directory %p", P);
	}
	int N = LinkedLists::len(C->errors_reading_source_text);
	if (N > 0) {
		WRITE(" - %d error", N);
		if (N > 1) WRITE("s");
	}
	WRITE("\n");
	if (N > 0) {
		INDENT; Copies::list_attached_errors(OUT, C); OUTDENT;
	}
}

@ And here are |-build| and |-rebuild|, though note that |Copies::build|
is also called by the |core| module of the Inform 7 compiler to perform
its main task: building an Inform project.

=
void Copies::build(OUTPUT_STREAM, inbuild_copy *C, build_methodology *BM) {
	build_vertex *V = C->vertex;
	VMETHOD_CALL(C->edition->work->genre, GENRE_BUILDING_SOON_MTID, C, &V);
	Graphs::build(OUT, V, BM);
}
void Copies::rebuild(OUTPUT_STREAM, inbuild_copy *C, build_methodology *BM) {
	build_vertex *V = C->vertex;
	VMETHOD_CALL(C->edition->work->genre, GENRE_BUILDING_SOON_MTID, C, &V);
	Graphs::rebuild(OUT, V, BM);
}

@ Now in quick succession |-graph|, |-build-needs|, |-use-needs|, |-build-missing|,
|-use-missing|:

=
void Copies::show_graph(OUTPUT_STREAM, inbuild_copy *C) {
	build_vertex *V = C->vertex;
	VMETHOD_CALL(C->edition->work->genre, GENRE_BUILDING_SOON_MTID, C, &V);
	Graphs::describe(OUT, V, TRUE);
}
void Copies::show_needs(OUTPUT_STREAM, inbuild_copy *C, int uses_only) {
	build_vertex *V = C->vertex;
	VMETHOD_CALL(C->edition->work->genre, GENRE_BUILDING_SOON_MTID, C, &V);
	Graphs::show_needs(OUT, C->vertex, uses_only);
}
void Copies::show_missing(OUTPUT_STREAM, inbuild_copy *C, int uses_only) {
	build_vertex *V = C->vertex;
	VMETHOD_CALL(C->edition->work->genre, GENRE_BUILDING_SOON_MTID, C, &V);
	int N = Graphs::show_missing(OUT, C->vertex, uses_only);
	if (N == 0) WRITE("Nothing is missing\n");
}

@ And here is |-archive| and |-archive-to N|:

=
void Copies::archive(OUTPUT_STREAM, inbuild_copy *C, inbuild_nest *N, build_methodology *BM) {
	build_vertex *V = C->vertex;
	VMETHOD_CALL(C->edition->work->genre, GENRE_BUILDING_SOON_MTID, C, &V);
	int NM = Graphs::show_missing(OUT, C->vertex, FALSE);
	if (NM > 0) WRITE("Because there are missing resources, -archive is cancelled\n");
	else if (N) Graphs::archive(OUT, C->vertex, N, BM);
}

@ And lastly |-copy-to N| and |-sync-to N|:

=
void Copies::copy_to(inbuild_copy *C, inbuild_nest *destination_nest, int syncing,
	build_methodology *meth) {
	if (destination_nest)
		VMETHOD_CALL(C->edition->work->genre, GENRE_COPY_TO_NEST_MTID, 
			C, destination_nest, syncing, meth);
}

void Copies::overwrite_error(inbuild_copy *C, inbuild_nest *N) {
	text_stream *ext = Str::new();
	WRITE_TO(ext, "%X", C->edition->work);
	Errors::with_text("already present (to overwrite, use -sync-to not -copy-to): '%S'", ext);
}
