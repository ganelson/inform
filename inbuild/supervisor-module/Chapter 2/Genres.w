[Genres::] Genres.

The different sorts of work managed by inbuild.

@h Genres.
Each different genre of work managed by Inbuild is represented by an instance
of the following structure. (At present, then, there are exactly seven
instances of it: nothing the user can do at the command line can change
that total.) A work unambiguously specifies what genre it has by means
of a non-null pointer to |inbuild_genre|. Moreover, the rules for how Inbuild
manages works of this genre are expressed by methods attached to the structure.
For example, to copy a work, Inbuild calls the |GENRE_COPY_TO_NEST_MTID|
method attached to its |inbuild_genre|.

Each genre has its own section of code: for example, |Kit Manager| defines
the instance |kit_genre| and provides its method functions.

=
typedef struct inbuild_genre {
	text_stream *genre_name;
	text_stream *metadata_type_name;
	int stored_in_nests;
	int genre_class;
	struct method_set *methods;
	CLASS_DEFINITION
} inbuild_genre;

inbuild_genre *Genres::new(text_stream *name, text_stream *md, int nested) {
	inbuild_genre *gen = CREATE(inbuild_genre);
	gen->genre_name = Str::duplicate(name);
	gen->metadata_type_name = Str::duplicate(md);
	gen->stored_in_nests = nested;
	gen->genre_class = 0;
	gen->methods = Methods::new_set();
	return gen;
}

text_stream *Genres::name(inbuild_genre *G) {
	if (G == NULL) return I"(none)";
	return G->genre_name;
}

text_stream *Genres::metadata_type_name(inbuild_genre *G) {
	if (G == NULL) return I"(none)";
	return G->metadata_type_name;
}

@ Some genres of work, such as kits and extensions, can be stored in nests;
others, such as Inform projects, cannot. Whether a copy can be stored in a
nest depends only on its genre.

=
int Genres::stored_in_nests(inbuild_genre *G) {
	if (G == NULL) return FALSE;
	return G->stored_in_nests;
}

@ The requirements parser needs to identify genres by name, so:

=
inbuild_genre *Genres::by_name(text_stream *name) {
	inbuild_genre *G;
	LOOP_OVER(G, inbuild_genre)
		if (Str::eq_insensitive(G->genre_name, name))
			return G;
	return NULL;
}

@ When searching, treat these as equivalently good:

=
int Genres::equivalent(inbuild_genre *G1, inbuild_genre *G2) {
	if (G1 == G2) return TRUE;
	if ((G1->genre_class != 0) && (G1->genre_class == G2->genre_class)) return TRUE;
	return FALSE;
}

void Genres::place_in_class(inbuild_genre *G, int c) {
	G->genre_class = c;
}

@ For sorting of search results:

=
int Genres::cmp(inbuild_genre *G1, inbuild_genre *G2) {
	if ((G1 == NULL) || (G2 == NULL)) internal_error("bad genre match");
	if (G1->allocation_id < G2->allocation_id) return -1;
	if (G1->allocation_id > G2->allocation_id) return 1;
	return 0;
}

@h Method functions.
And here are the method functions which a genre can, optionally, provide.
All of these act on a given work, or a given copy of a work, having the
genre in question.

First, this writes text sufficient to identify a work: e.g., "Locksmith
by Emily Short".

@e GENRE_WRITE_WORK_MTID

=
VOID_METHOD_TYPE(GENRE_WRITE_WORK_MTID,
	inbuild_genre *gen, text_stream *OUT, inbuild_work *work)

@ This looks at a textual file locator, which might be a pathname or a
filename, to see if it might refer to a copy of a work of the given genre.
If it does, an |inbuild_copy| is created, and the pointer |*C| is set to
point to it. If not, no error is issued, and |*C| is left unchanged.

Errors can, however, be produced if Inbuild is pretty sure that the object
in the file system is intended to be such a copy, but is damaged in some way:
an extension with a malformed titling line, for example. Such errors are
attached to the copy for later issuing.

@e GENRE_CLAIM_AS_COPY_MTID

=
VOID_METHOD_TYPE(GENRE_CLAIM_AS_COPY_MTID,
	inbuild_genre *gen, inbuild_copy **C, text_stream *arg, text_stream *ext,
	int directory_status)

@ This searches the nest |N| for anything which (a) looks like a copy of a
work of our genre, and (b) meets the given requirements. If a genre does
not provide this method, then nothing of that genre can ever appear in
|-matching| search results.

@e GENRE_SEARCH_NEST_FOR_MTID

=
VOID_METHOD_TYPE(GENRE_SEARCH_NEST_FOR_MTID,
	inbuild_genre *gen, inbuild_nest *N, inbuild_requirement *req,
	linked_list *search_results)

@ Some genres of work involve Inform source text -- Inform projects and
extensions, for example. Reading in source text is fairly fast, but it's not
an instant process, and we don't automatically perform it. (When an extension
is scanned for metadata during claiming, only the opening line is looked at.)

This method should exist only for such genres, and it should read the source
text. It will never be called twice on the same copy.

Text should actually be read by feeding it into the lexer. Inbuild will take
of it from there.

@e GENRE_READ_SOURCE_TEXT_FOR_MTID

=
VOID_METHOD_TYPE(GENRE_READ_SOURCE_TEXT_FOR_MTID,
	inbuild_genre *gen, inbuild_copy *C)

@ At the Graph Construction phase of Inbuild, each copy is offered the chance
to finalise its internal representation. For example, this may be when its
build graph is constructed, because we can now know for sure that there are
no further unsuspected dependencies.

This method is optional, and is called exactly once on every copy (whose genre
provides it) which has been claimed by Inbuild.

@e GENRE_CONSTRUCT_GRAPH_MTID

=
VOID_METHOD_TYPE(GENRE_CONSTRUCT_GRAPH_MTID,
	inbuild_genre *gen, inbuild_copy *C)

@ This method is called when a copy is about to be built or have its graph
described, for example by |-graph|, |-build| and |-rebuild|. Nothing actually
needs to be done, but if any work is needed before building can take place,
now's the time; and the vertex to build from can be altered by setting |*V|.
(This is used to create upstream targets for Inform projects, such as the
blorbed release version. It affects |-graph|, |-build| and |-rebuild| but
is ignored for other inspection options such as |-use-missing|.)

@e GENRE_BUILDING_SOON_MTID

=
VOID_METHOD_TYPE(GENRE_BUILDING_SOON_MTID,
	inbuild_genre *gen, inbuild_copy *C, build_vertex **V)

@ This duplicates, or syncs, a copy |C| of a work in our genre, placing it
at a canonical location inside the given nest |N|. In effect, it implements
the Inbuild command-line options |-copy-to N| and |-sync-to N|.

@e GENRE_COPY_TO_NEST_MTID

=
VOID_METHOD_TYPE(GENRE_COPY_TO_NEST_MTID,
	inbuild_genre *gen, inbuild_copy *C, inbuild_nest *N, int syncing,
	build_methodology *meth)

@ This writes documentation on the edition (if it provides any).

@e GENRE_DOCUMENT_MTID

=
VOID_METHOD_TYPE(GENRE_DOCUMENT_MTID,
	inbuild_genre *gen, inbuild_copy *C, pathname *dest, filename *sitemap)

@ This performs some sort of automatic-update to the latest format:

@e GENRE_MODERNISE_MTID

=
INT_METHOD_TYPE(GENRE_MODERNISE_MTID,
	inbuild_genre *gen, inbuild_copy *C, text_stream *OUT)
