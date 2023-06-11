[Nests::] Nests.

Nests are repositories of Inform-related resources.

@h Creation.
To "create" a nest here does not mean actually altering the file system, for
example by making a directory: nests here are merely notes in memory of
positions in the file system hierarchy which may or may not exist.

=
typedef struct inbuild_nest {
	struct pathname *location;
	int read_only; /* files cannot be written into this nest */
	int tag_value; /* used to indicate whether internal, external, and such */
	int deprecated; /* issue warnings if resources from here are actually used */
	CLASS_DEFINITION
} inbuild_nest;

=
inbuild_nest *Nests::new(pathname *P) {
	inbuild_nest *N = CREATE(inbuild_nest);
	N->location = P;
	N->read_only = FALSE;
	N->tag_value = -1;
	N->deprecated = FALSE;
	return N;
}

@ Nests used by the Inform and Inbuild tools are tagged with the following
constants. (There used to be quite a good joke here, but refactoring of the
code removed its premise. Literate programming is like that sometimes.)

The sequence of the following enumerated values is very significant --
see below for why. Lower-tag-numbered origins are better than later ones.

@e MATERIALS_NEST_TAG from 1
@e EXTERNAL_NEST_TAG
@e GENERIC_NEST_TAG
@e INTERNAL_NEST_TAG
@e EXTENSION_NEST_TAG

=
int Nests::get_tag(inbuild_nest *N) {
	if (N == NULL) return -1;
	return N->tag_value;
}

void Nests::set_tag(inbuild_nest *N, int t) {
	if (N == NULL) internal_error("no nest");
	N->tag_value = t;
}

text_stream *Nests::tag_name(int t) {
	switch (t) {
		case MATERIALS_NEST_TAG: return I"materials";
		case EXTERNAL_NEST_TAG: return I"external";
		case GENERIC_NEST_TAG: return I"generic";
		case INTERNAL_NEST_TAG: return I"internal";
		case EXTENSION_NEST_TAG: return I"extension";
	}
	return I"<unknown nest tag>";
}

@ A nest is read-only if nothing in it should be updated or added to. You
can't install to a read-only nest.

=
void Nests::protect(inbuild_nest *N) {
	N->read_only = TRUE;
}

int Nests::is_protected(inbuild_nest *N) {
	if (N == NULL) return FALSE;
	return N->read_only;
}

@ A nest is deprecated if its resources can be used, but ideally shouldn't be.

=
void Nests::deprecate(inbuild_nest *N) {
	N->deprecated = TRUE;
}

int Nests::is_deprecated(inbuild_nest *N) {
	if (N == NULL) return FALSE;
	return N->deprecated;
}

@ =
pathname *Nests::get_location(inbuild_nest *N) {
	if (N == NULL) return NULL;
	return N->location;
}

@h Search list.
When we search for copies, we do so by looking through nests in a list. The
following builds such lists, removing duplicates -- where duplicates are
shown up by having the same textual form of pathname. (This is not foolproof
by any means: Unix is replete with ways to describe the same directory, thanks
to simlinks, |~| and so on. But in the circumstances arising inside Inbuild,
it will do. In any case, having duplicates would not actually matter: it
would just produce search results which were more copious than needed.)

=
void Nests::add_to_search_sequence(linked_list *search_list, inbuild_nest *N) {
	TEMPORARY_TEXT(NS)
	WRITE_TO(NS, "%p", N->location);
	int already_here = FALSE;
	inbuild_nest *M;
	LOOP_OVER_LINKED_LIST(M, inbuild_nest, search_list) {
		TEMPORARY_TEXT(MS)
		WRITE_TO(NS, "%p", M->location);
		if (Str::eq(NS, MS)) already_here = TRUE;
		DISCARD_TEXT(MS)
	}
	DISCARD_TEXT(NS)
	if (already_here) return;
	ADD_TO_LINKED_LIST(N, inbuild_nest, search_list);
}

@h Search results.
When we search a list of nests for copies satisfying certain requirements,
we create one of these for each hit:

=
typedef struct inbuild_search_result {
	struct inbuild_copy *copy; /* what was found */
	struct inbuild_nest *nest; /* from whence it came */
	CLASS_DEFINITION
} inbuild_search_result;

@ These can be created only as entries in a list:

=
void Nests::add_search_result(linked_list *results, inbuild_nest *N, inbuild_copy *C,
	inbuild_requirement *req) {
	inbuild_search_result *R = CREATE(inbuild_search_result);
	R->nest = N;
	R->copy = C;
	C->found_by = req;
	if (req == NULL) internal_error("bad search result");
	ADD_TO_LINKED_LIST(R, inbuild_search_result, results);
}

@ And here is our search engine, such as it is. For each nest, we ask each
genre's manager to look for copies of that genre:

=
void Nests::search_for(inbuild_requirement *req,
	linked_list *search_list, linked_list *results) {
	text_stream *OUT = STDOUT;
	if (supervisor_verbosity >= 3) {
		WRITE("(search for ");
		Requirements::write(OUT, req);
		WRITE(" in ");
		inbuild_nest *N; int c = 0;
		LOOP_OVER_LINKED_LIST(N, inbuild_nest, search_list) {
			if (c++ > 0) WRITE(", ");
			WRITE("%S nest at %p", Nests::tag_name(N->tag_value), N->location);
		}
		WRITE(")\n");
		INDENT;
	}
	
	inbuild_nest *N;
	LOOP_OVER_LINKED_LIST(N, inbuild_nest, search_list) {
		inbuild_genre *G;
		LOOP_OVER(G, inbuild_genre)
			VOID_METHOD_CALL(G, GENRE_SEARCH_NEST_FOR_MTID, N, req, results);
	}

	if (supervisor_verbosity >= 3) {
		OUTDENT;
		inbuild_search_result *R;
		int c = 1;
		LOOP_OVER_LINKED_LIST(R, inbuild_search_result, results) {
			WRITE("  (Result %d. ", c++);
			Copies::write_copy(OUT, R->copy);
			WRITE(" from %S nest at %p)\n", Nests::tag_name(R->nest->tag_value), R->nest->location);
		}
		WRITE("(search complete with %d result(s))\n", c);
	}
}

@ Oftentimes, we want only the single best result, and won't even look at the
others:

=
inbuild_search_result *Nests::search_for_best(inbuild_requirement *req,
	linked_list *search_list) {
	linked_list *L = NEW_LINKED_LIST(inbuild_search_result);
	Nests::search_for(req, search_list, L);
	inbuild_search_result *best = NULL, *search_result; int c = 1, bc = 0;
	LOOP_OVER_LINKED_LIST(search_result, inbuild_search_result, L) {
		if (Nests::better_result(search_result, best)) {
			best = search_result; bc = c;
		}
		c++;
	}
	SVEXPLAIN(3, "(best result is %d)\n", bc);
	return best;
}

@ Where "better" is defined as follows. This innocent-looking function is
in fact critical to what Inbuild does. It uses tags on nests to prefer copies
in the Materials folder to those in the external nest, and to prefer those in
turn to copies in the internal nest; and within nests of equal importance,
it chooses the earliest hit among those which have the highest-precedence
semantic version numbers.

=
int Nests::better_result(inbuild_search_result *R1, inbuild_search_result *R2) {
	/* Something is better than nothing */
	if (R1 == NULL) return FALSE;
	if (R2 == NULL) return TRUE;

	/* Otherwise, a more important nest beats a less important nest */
	int o1 = Nests::get_tag(R1->nest);
	int o2 = Nests::get_tag(R2->nest);
	if (o1 < o2) return TRUE;
	if (o1 > o2) return FALSE;

	/* Otherwise, a higher semantic version number beats a lower */
	if (VersionNumbers::gt(R1->copy->edition->version, R2->copy->edition->version))
		return TRUE;

	/* Otherwise, better the devil we know */
	return FALSE;
}
