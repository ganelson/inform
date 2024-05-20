[IndexTerms::] Index Terms.

Hypothetical index entries with no references to position as yet.

@ A "term" is something which might occur as an index entry: for example,
"rockets: Titan IV". Its individual parts, here "rockets" and "Titan IV",
are called "subterms", and each can have a different category. If this term
were to be placed in a dictionary, "Titan IV" would probably end up as one of
many lemmas under the lemma "rockets".

@d MAX_LEMMA_SUBTERMS 5

=
typedef struct normalised_term {
	int no_subterms;
	struct text_stream *texts[MAX_LEMMA_SUBTERMS];
	struct indexing_category *categories[MAX_LEMMA_SUBTERMS];
} normalised_term;

normalised_term IndexTerms::new_normalised(void) {
	normalised_term N;
	N.no_subterms = 0;
	return N;
}

@ We begin with raw text taken from the documentation source, such as
|rockets++hardware++: ~Titan IV~|. We parse this into its subterms, and
remove any indexing notations, which convey the categories to be used.

The "adjusting" version of this function takes a Markdown node as a further
argument, and actually modifies that node. The idea is to be able to deal
with something like |the ^{~Atlas V~} was...|, where an index marker node
is immediately followed by a plain-text node so that the words "Atlas V"
are both indexed and also included in the body text. We modify such that any
notation we parse from the index marker node (here, the tildes) is removed
from the plain node.

=
normalised_term IndexTerms::parse_normalised(compiled_documentation *cd,
	text_stream *text) {
	normalised_term N = IndexTerms::new_normalised();
	IndexTerms::parse_normalised_prim(&N, cd, text, NULL);
	return N;
}

normalised_term IndexTerms::parse_normalised_adjusting(compiled_documentation *cd,
	text_stream *text, markdown_item *plain_md) {
	normalised_term N = IndexTerms::new_normalised();
	IndexTerms::parse_normalised_prim(&N, cd, text, plain_md);
	return N;
}

void IndexTerms::parse_normalised_prim(normalised_term *N, compiled_documentation *cd,
	text_stream *text, markdown_item *plain_md) {
	TEMPORARY_TEXT(trimmed)
	Str::copy(trimmed, text);
	Str::trim_white_space(trimmed);
	match_results mr = Regexp::create_mr();
	while (Regexp::match(&mr, trimmed, U" *(%c+?) *: *(%c+) *")) {
		IndexTerms::parse_normalised_prim(N, cd, mr.exp[0], NULL);
		Str::clear(trimmed);
		Str::copy(trimmed, mr.exp[1]);
		plain_md = NULL;
	}
	Regexp::dispose_of(&mr);
	if (N->no_subterms >= MAX_LEMMA_SUBTERMS) internal_error("too deep");
	N->texts[N->no_subterms] = Str::new();
	index_markup_notation *imn = IndexMarkupNotations::match(cd, trimmed);
	if (imn == NULL) internal_error("not exhaustive");
	int L = IndexMarkupNotations::left_width(imn), R = IndexMarkupNotations::right_width(imn);
	for (int j=L; j < Str::len(trimmed) - R; j++)
		PUT_TO(N->texts[N->no_subterms], Str::get_at(trimmed, j));
	N->categories[N->no_subterms] = IndexMarkupNotations::category(imn);
	if ((plain_md) && (plain_md->type == PLAIN_MIT)) {
		plain_md->from += L;
		plain_md->to -= R;
	}
	DISCARD_TEXT(trimmed)
	N->no_subterms++;
}

@ A "categorised" term is the next stage of processing. They are made only from
normalised terms, and as data structures look very similar, but making them
different types avoids bugs where we've somehow allowed uncategorised terms
through into the final index.

=
typedef struct categorised_term {
	int no_subterms;
	struct text_stream *texts[MAX_LEMMA_SUBTERMS];
	struct indexing_category *categories[MAX_LEMMA_SUBTERMS];
	int erroneous;
} categorised_term;

categorised_term IndexTerms::new_categorised(void) {
	categorised_term P;
	P.no_subterms = 0;
	P.erroneous = FALSE;
	return P;
}

@ Categorised terms are constructed only from normalised terms, and they make
a deep copy of all of the data.

=
categorised_term IndexTerms::categorise(compiled_documentation *cd,
	normalised_term N) {
	return IndexTerms::categorise_prim(cd, N, TRUE);
}

categorised_term IndexTerms::categorise_unrelocated(compiled_documentation *cd,
	normalised_term N) {
	return IndexTerms::categorise_prim(cd, N, FALSE);
}

categorised_term IndexTerms::categorise_prim(compiled_documentation *cd,
	normalised_term N, int allow_relocation) {
	categorised_term P = IndexTerms::new_categorised();
	P.no_subterms = N.no_subterms;
	for (int i=0, ip=0; i<N.no_subterms; i++, ip++) {
		text_stream *lemma = Str::duplicate(N.texts[i]);
		indexing_category *ic = N.categories[i];
		@<Redirect category names starting with an exclamation@>;
		@<Perform name inversion as necessary@>;
		@<Prefix and suffix as necessary@>;
		@<Relocate under a headword as necessary@>;
		if (ip >= MAX_LEMMA_SUBTERMS) internal_error("too deep");
		P.texts[ip] = lemma;
		P.categories[ip] = ic;
	}
	return P;
}

@ A category beginning |!| is either redirected to a regular category, or
else suppressed as unwanted (because the user didn't set up a redirection).

@<Redirect category names starting with an exclamation@> =
	if (Str::get_first_char(ic->cat_name) == '!') {
		text_stream *redirected =
			Dictionaries::get_text(cd->id.categories_redirect, ic->cat_name);
		if (Str::len(redirected) > 0) Str::copy(ic->cat_name, redirected);
		else P.erroneous = TRUE;
	}

@ This inverts "Sir Robert Cecil" to "Cecil, Sir Robert", but leaves
"Mary, Queen of Scots" alone.

@<Perform name inversion as necessary@> =
	if ((ic->cat_inverted) && (Regexp::match(NULL, lemma, U"%c*,%c*") == FALSE)) {
		match_results mr = Regexp::create_mr();
		if (Regexp::match(&mr, lemma, U"(%c*?) (%C+) *")) {
			Str::clear(lemma);
			WRITE_TO(lemma, "%S, %S", mr.exp[1], mr.exp[0]);
		}
		Regexp::dispose_of(&mr);
	}

@ This, for example, could append "(monarch)" to the name of every lemma
in the category "royalty", so that "James I" becomes "James I (monarch)".

@<Prefix and suffix as necessary@> =
	TEMPORARY_TEXT(rewritten)
	WRITE_TO(rewritten, "%S%S%S", ic->cat_prefix, lemma, ic->cat_suffix);
	Str::copy(lemma, rewritten);
	DISCARD_TEXT(rewritten)

@ And this could automatically reroute the lemma so that it appears as
a subentry under the category's choice of headword: e.g., "James I"
might be placed as as a subentry of "Kings".

@<Relocate under a headword as necessary@> =
	if ((allow_relocation) && (i == 0) && (Str::len(ic->cat_under) > 0)) {
		normalised_term UN = IndexTerms::parse_normalised(cd, ic->cat_under);
		P = IndexTerms::categorise_unrelocated(cd, UN);
		ip = P.no_subterms;
		P.no_subterms += N.no_subterms;
	}

@

=
categorised_term IndexTerms::truncated(categorised_term P, int to) {
	if (to >= P.no_subterms) return P;
	categorised_term PT;
	PT.no_subterms = to;
	for (int j=0; j<to; j++) {
		PT.texts[j] = Str::duplicate(P.texts[j]);
		PT.categories[j] = P.categories[j];
	}
	PT.erroneous = P.erroneous;
	return PT;
}

void IndexTerms::serialise(OUTPUT_STREAM, compiled_documentation *cd, categorised_term P) {
	for (int i=0; i<P.no_subterms; i++) {
		if (i>0) WRITE(":");
		WRITE("%S=___=%S", P.texts[i], P.categories[i]->cat_name);
	}
}

void IndexTerms::paraphrase(OUTPUT_STREAM, compiled_documentation *cd, categorised_term P) {
	for (int i=0; i<P.no_subterms; i++) {
		if (i>0) WRITE(": ");
		WRITE("%S", P.texts[i]);
	}
}

indexing_category *IndexTerms::final_category(compiled_documentation *cd,
	categorised_term P) {
	if (P.no_subterms > 0) return P.categories[P.no_subterms-1];
	return NULL;
}

text_stream *IndexTerms::final_text(compiled_documentation *cd,
	categorised_term P) {
	if (P.no_subterms > 0) return P.texts[P.no_subterms-1];
	return NULL;
}

int IndexTerms::subterms(categorised_term P) {
	return P.no_subterms;
}

int IndexTerms::erroneous(categorised_term P) {
	return P.erroneous;
}
