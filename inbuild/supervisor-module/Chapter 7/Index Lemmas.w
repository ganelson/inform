[IndexLemmas::] Index Lemmas.

To scan a Markdown tree of documentation and accumulate a set of index lemmas.

@ Whereas a term is a hypothetical index entry, a lemma is an actual one,
and consists of a (categorised) term together with some locations at which it
can be found. We represent locations as follows:

=
typedef struct cd_index_location {
	int volume_number;
	struct markdown_item *latest;
	struct IFM_example *example;
} cd_index_location;

cd_index_location IndexLemmas::nowhere(void) {
	cd_index_location posn;
	posn.volume_number = -1;
	posn.example = NULL;
	posn.latest = NULL;
	return posn;
}

int IndexLemmas::somewhere(cd_index_location posn) {
	if ((posn.volume_number >= 0) && ((posn.example) || (posn.latest)))
		return TRUE;
	return FALSE;
}

@ There are two sorts of location a lemma can have: positions in the Markdown
text, and cross-references to other lemmas, although they are actually stored
not as lemmas but as categorised terms for timing reasons. (That is, so that
one lemma can cross-reference another which does not yet exist but which will
be created later.)

=
typedef struct index_lemma {
	struct categorised_term term; /* term of lemma */
	struct linked_list *references; /* of |index_reference| */
	struct linked_list *cross_references; /* of |index_cross_reference| */
	struct text_stream *sorting_key; /* final reading order is alphabetic on this */
	int lemma_source; /* one of the |*_LEMMASOURCE| constants */
	CLASS_DEFINITION
} index_lemma;

typedef struct index_reference {
	struct cd_index_location posn;
	CLASS_DEFINITION
} index_reference;

typedef struct index_cross_reference {
	struct categorised_term P;
	CLASS_DEFINITION
} index_cross_reference;

void IndexLemmas::add_reference(index_lemma *il, cd_index_location posn) {
	index_reference *ref = CREATE(index_reference);
	ref->posn = posn;
	ADD_TO_LINKED_LIST(ref, index_reference, il->references);
}

void IndexLemmas::add_cross_reference(index_lemma *il, categorised_term see) {
	index_cross_reference *xref = CREATE(index_cross_reference);
	xref->P = see;
	ADD_TO_LINKED_LIST(xref, index_cross_reference, il->cross_references);
}

@ The following guarantees that every lemma comes from a term; every lemma is
stored in the dictionary; and that if a lemma exists for a term, then it exists
for each initial sub-term. Thus, if a lemma exists for "food: dairy products:
soured cream", then lemmas for "food" and "food: dairy products" also exist.

=
index_lemma *IndexLemmas::ensure(compiled_documentation *cd, categorised_term P,
	int lemma_source) {
	index_lemma *il = NULL;
	int N = IndexTerms::subterms(P);
	for (int i = 1; i <= N; i++) {
		categorised_term PT = IndexTerms::truncated(P, i);
		il = IndexingData::retrieve_lemma(cd, PT);
		if (il == NULL) {
			il = CREATE(index_lemma);
			il->term = PT;
			il->references = NEW_LINKED_LIST(index_reference);
			il->cross_references = NEW_LINKED_LIST(index_cross_reference);
			il->sorting_key = Str::new();
			il->lemma_source = lemma_source;
			IndexingData::store_lemma(cd, il);
		}
	}
	return il;
}

@ The following scan is slightly deceptive. It looks as if it works through the
main Markdown tree for the documentation, and then through individual trees
for the examples in turn. In fact the second scan (though examples) only does
anything if the examples in question are not placed anywhere in the tree;
for the main Inform documentation, that's never true, but for extension
documentation it can be.

=
void IndexLemmas::scan_documentation(compiled_documentation *cd) {
	cd_index_location posn = IndexLemmas::nowhere();
	posn.latest = cd->markdown_content;
	IndexLemmas::scan_documentation_r(cd, cd->markdown_content, &posn);
	IFM_example *E;
	LOOP_OVER_LINKED_LIST(E, IFM_example, cd->examples) {
		cd_index_location posn = IndexLemmas::nowhere();
		posn.latest = cd->markdown_content;
		posn.example = E;
		IndexLemmas::scan_documentation_r(cd, E->header, &posn);
	}
}

@ The scanner works through the tree, tracking the currently enclosing volume,
chapter or section heading, and example heading, in search of |INDEX_MARKER_MIT|
Markdown nodes. Note that the scan descends through examples only where they are
underneath a subheading; that will be true for examples located in a section,
but not for stand-alone ones, which do not have |INFORM_EXAMPLE_HEADING_MIT| nodes.

=
void IndexLemmas::scan_documentation_r(compiled_documentation *cd, markdown_item *md,
	cd_index_location *posn) {
	if ((md->type == INFORM_EXAMPLE_HEADING_MIT) && (posn->latest)) {
		IFM_example *save_E = posn->example;
		IFM_example *E = RETRIEVE_POINTER_IFM_example(md->user_state);
		IndexLemmas::index_example_header(cd, *posn, E->name, EG_NAME_LEMMASOURCE);
		if ((Str::len(E->ex_index) > 0) && (Str::ne(E->ex_index, E->name)))
			IndexLemmas::index_example_header(cd, *posn, E->ex_index, EG_ALT_LEMMASOURCE);

		posn->example = E;
		for (markdown_item *ch = md->down; ch; ch=ch->next) 
			IndexLemmas::scan_documentation_r(cd, ch, posn);
		posn->example = save_E;
	} else if (md) {
		switch (md->type) {
			case VOLUME_MIT:
				posn->volume_number++;
				break;
			case HEADING_MIT:
				if (Markdown::get_heading_level(md) <= 2) posn->latest = md;
				break;
			case INDEX_MARKER_MIT:
				IndexLemmas::index_marker(cd, md, *posn);
				break;
		}
		for (markdown_item *ch = md->down; ch; ch=ch->next)
			IndexLemmas::scan_documentation_r(cd, ch, posn);
	}
}

@ Note that exactly one entry of source |EG_NAME_LEMMASOURCE| is made
per example, but that in addition a bonus entry can be made if the example
file asks for it, of source |EG_ALT_LEMMASOURCE|.

@d BODY_LEMMASOURCE 0
@d EG_NAME_LEMMASOURCE 1
@d EG_ALT_LEMMASOURCE 2

=
void IndexLemmas::index_example_header(compiled_documentation *cd, cd_index_location posn,
	text_stream *text, int lemma_source) {
	normalised_term N = IndexTerms::parse_normalised(cd, text);
	IndexLemmas::make(cd, N, posn, NULL, lemma_source);
}

@ Every other entry will have source |BODY_LEMMASOURCE|, and will arise from an
index-marker Markdown node, i.e., from a usage of |^{caret and braces}| in the
documentation source. The node is |md|, and |posn| is where it lives.

=
void IndexLemmas::index_marker(compiled_documentation *cd, markdown_item *md,
	cd_index_location posn) {
	int carets = md->details;
	text_stream *term_to_index = md->stashed;
	TEMPORARY_TEXT(see)
	TEMPORARY_TEXT(alphabetise_as)
	@<Parse the alphabetisation and see@>;
	normalised_term N;
	if (carets == 1) N = IndexTerms::parse_normalised_adjusting(cd, term_to_index, md->next);
	else N = IndexTerms::parse_normalised(cd, term_to_index);
	if (carets < 3) IndexLemmas::make(cd, N, posn, NULL, BODY_LEMMASOURCE);
	@<Deal with alphabetisation@>;
	@<Deal with see@>;

	DISCARD_TEXT(see)
	DISCARD_TEXT(alphabetise_as)
}

@ Note that this is not a passive operation: we are modifying the stashed text
inside the Markdown node. (And in some cases, |IndexTerms::parse_normalised_adjusting|
modifies the plain node following it, too.)

@<Parse the alphabetisation and see@> =
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, term_to_index, U"(%c+?) *<-- *(%c+) *")) {
		Str::copy(term_to_index, mr.exp[0]); Str::copy(see, mr.exp[1]);
	}
	if (Regexp::match(&mr, term_to_index, U"(%c+?) *--> *(%c+) *")) {
		Str::copy(term_to_index, mr.exp[0]); Str::copy(alphabetise_as, mr.exp[1]);
	}
	Regexp::dispose_of(&mr);

@<Deal with alphabetisation@> =
	if (Str::len(alphabetise_as) > 0)
		IndexingData::make_exception(cd,
			IndexTerms::categorise(cd, N), alphabetise_as);

@<Deal with see@> =
	match_results mr = Regexp::create_mr();
	while (Regexp::match(&mr, see, U" *(%c+) *<-- *(%c+?) *")) {
		Str::copy(see, mr.exp[0]);
		IndexLemmas::see(cd, mr.exp[1], N);
	}
	if (Str::len(see) > 0) IndexLemmas::see(cd, see, N);
	Regexp::dispose_of(&mr);

@ =
void IndexLemmas::see(compiled_documentation *cd, text_stream *see, normalised_term N) {
	categorised_term P = IndexTerms::categorise(cd, N);
	normalised_term SN = IndexTerms::parse_normalised(cd, see);
	IndexLemmas::make(cd, SN, IndexLemmas::nowhere(), &P, BODY_LEMMASOURCE);
}

@ Some categories cause their terms to be relocated, and this is automatically
handled in the categorisation process, but others cause them to be _both_
relocated _and_ still in the original, unrelocated position. For those, we
need to make two different categorisations, and create at both.

=
void IndexLemmas::make(compiled_documentation *cd, normalised_term N,
	cd_index_location posn, categorised_term *see, int lemma_source) {
	categorised_term P = IndexTerms::categorise(cd, N);
	indexing_category *ic = IndexTerms::final_category(cd, P);
	if ((ic) && (ic->cat_alsounder == TRUE)) {
		categorised_term P = IndexTerms::categorise_unrelocated(cd, N);
		@<Make at P@>;
	}
	@<Make at P@>;
}

@<Make at P@> =
	if (IndexTerms::erroneous(P) == FALSE) {
		index_lemma *il = IndexLemmas::ensure(cd, P, lemma_source);
		if (IndexLemmas::somewhere(posn)) IndexLemmas::add_reference(il, posn);
		if (see) IndexLemmas::add_cross_reference(il, *see);
	}

@ When created, lemmas have no sorting keys: those are made later.

=
void IndexLemmas::make_sorting_key(compiled_documentation *cd, index_lemma *il) {
	TEMPORARY_TEXT(sort_key)
	text_stream *except = IndexingData::find_exception(cd, il->term);
	if (Str::len(except) > 0) 
		WRITE_TO(sort_key, "%S", except);
	else
		IndexTerms::serialise(sort_key, cd, il->term);

	/* ensure subentries follow main entries */
	if (Str::get_first_char(sort_key) != ':')
		Regexp::replace(sort_key, U": *", U"ZZZZZZZZZZZZZZZZZZZZZZ", REP_REPEATING);
	IndexLemmas::improve_alphabetisation(cd, sort_key);

	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, sort_key, U"a/%C+ (%c*)")) Str::copy(sort_key, mr.exp[0]);
	if (Regexp::match(&mr, sort_key, U"the/%C+ (%c*)")) Str::copy(sort_key, mr.exp[0]);

	if (cd->id.use_letter_alphabetisation == FALSE)
		Regexp::replace(sort_key, U" ", U"aaaaaaaaaaaaaaaaaaaaaa", REP_REPEATING);

	TEMPORARY_TEXT(un)
	Str::copy(un, sort_key);
	if ((Str::begins_with(sort_key, I"( )") == FALSE) &&
		(Str::begins_with(sort_key, I"((-") == FALSE) &&
		(Str::begins_with(sort_key, I"((+") == FALSE))
		Regexp::replace(un, U"%(%c*?%)", NULL, REP_REPEATING);
	Regexp::replace(un, U" ", NULL, REP_REPEATING);
	if (Str::get_first_char(sort_key) != ',')
		Regexp::replace(un, U",", NULL, REP_REPEATING);
	inchar32_t f = ' ';
	if (Characters::isalpha(Str::get_first_char(sort_key)))
		f = Str::get_first_char(sort_key);
	WRITE_TO(il->sorting_key, "%c_%S=___=%S=___=%07d",
		f, un, sort_key, il->allocation_id);

	DISCARD_TEXT(un)
	DISCARD_TEXT(sort_key)
	Regexp::dispose_of(&mr);
}

@ We flatten the casing and remove the singular articles; we count initial
small numbers as words, so that "3 Wise Monkeys" is filed as if it were "Three
Wise Monkeys"; with parts of multipart examples, such as "Disappointment
Bay 3", we insert zeroes before the 3 so that up to 99 parts can appear and
alphabetical sorting will agree with numerical.

=
void IndexLemmas::improve_alphabetisation(compiled_documentation *cd, text_stream *sort_key) {
	LOOP_THROUGH_TEXT(pos, sort_key)
		Str::put(pos, Characters::tolower(Str::get(pos)));
	Regexp::replace(sort_key, U"a ", NULL, REP_ATSTART);
	Regexp::replace(sort_key, U"an ", NULL, REP_ATSTART);
	Regexp::replace(sort_key, U"the ", NULL, REP_ATSTART);
	LOOP_THROUGH_TEXT(pos, sort_key)
		Str::put(pos, Characters::tolower(Characters::remove_accent(Str::get(pos))));
	Regexp::replace(sort_key, U"%[ *%]", U"____SQUARES____", REP_REPEATING);
	Regexp::replace(sort_key, U"%[", NULL, REP_REPEATING);
	Regexp::replace(sort_key, U"%]", NULL, REP_REPEATING);
	Regexp::replace(sort_key, U"____SQUARES____", U"[]", REP_REPEATING);
	Regexp::replace(sort_key, U"%(", NULL, REP_REPEATING);
	Regexp::replace(sort_key, U"%)", NULL, REP_REPEATING);
	Regexp::replace(sort_key, U"1 ", U"one ", REP_ATSTART);
	Regexp::replace(sort_key, U"2 ", U"two ", REP_ATSTART);
	Regexp::replace(sort_key, U"3 ", U"three ", REP_ATSTART);
	Regexp::replace(sort_key, U"4 ", U"four ", REP_ATSTART);
	Regexp::replace(sort_key, U"5 ", U"five ", REP_ATSTART);
	Regexp::replace(sort_key, U"6 ", U"six ", REP_ATSTART);
	Regexp::replace(sort_key, U"7 ", U"seven ", REP_ATSTART);
	Regexp::replace(sort_key, U"8 ", U"eight ", REP_ATSTART);
	Regexp::replace(sort_key, U"9 ", U"nine ", REP_ATSTART);
	Regexp::replace(sort_key, U"10 ", U"ten ", REP_ATSTART);
	Regexp::replace(sort_key, U"11 ", U"eleven ", REP_ATSTART);
	Regexp::replace(sort_key, U"12 ", U"twelve ", REP_ATSTART);
	TEMPORARY_TEXT(x)
	Str::copy(x, sort_key);
	Str::clear(sort_key);
	match_results mr = Regexp::create_mr();
	while (Regexp::match(&mr, x, U"(%c*?)(%d+)(%c*)")) {
		WRITE_TO(sort_key, "%S", mr.exp[0]);
		Str::copy(x, mr.exp[2]);
		WRITE_TO(sort_key, "%08d", Str::atoi(mr.exp[1], 0));
	}
	WRITE_TO(sort_key, "%S", x);
	DISCARD_TEXT(x)
}

int IndexLemmas::cmp(const void *ent1, const void *ent2) {
	const index_lemma *L1 = *((const index_lemma **) ent1);
	const index_lemma *L2 = *((const index_lemma **) ent2);
	return Str::cmp(L1->sorting_key, L2->sorting_key);
}
