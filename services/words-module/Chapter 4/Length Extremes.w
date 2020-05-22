[LengthExtremes::] Length Extremes.

To precalculate data which enables rapid parsing of source text against a
Preform grammar.

@ The "length extremes" system provides one of two optimisations enabling
the Preform parser quickly to reject non-matches, the other being
//Nonterminal Incidences//, which is harder to understand.

It may elucidate both to see the actual optimisation data for nonterminals
as used in a typical run of Inform 7 -- see //inform7: Performance Metrics//.

@ The "extremes" of something to be matched against are the minimum and maximum
number of words in a successful match; with |INFINITE_WORD_COUNT| as maximum
where the number is unlimited.

@d INFINITE_WORD_COUNT 1000000000

=
typedef struct length_extremes {
	int min_words, max_words;
} length_extremes;

@ =
length_extremes LengthExtremes::new(int min, int max) {
	length_extremes E; E.min_words = min; E.max_words = max;
	return E;
}

@ Four useful special cases:

=
length_extremes LengthExtremes::no_words_at_all(void) {
	length_extremes E; E.min_words = 0; E.max_words = 0;
	return E;
}

length_extremes LengthExtremes::any_number_of_words(void) {
	length_extremes E; E.min_words = 0; E.max_words = INFINITE_WORD_COUNT;
	return E;
}

length_extremes LengthExtremes::at_least_one_word(void) {
	length_extremes E; E.min_words = 1; E.max_words = INFINITE_WORD_COUNT;
	return E;
}

length_extremes LengthExtremes::exactly_one_word(void) {
	length_extremes E; E.min_words = 1; E.max_words = 1;
	return E;
}

@ Testing:

=
int LengthExtremes::in_bounds(int match_length, length_extremes E) {
	if ((match_length >= E.min_words) && (match_length <= E.max_words))
		return TRUE;
	return FALSE;
}

@ Concatenation produces the length extremes for the text X followed by the
text Y:

=
length_extremes LengthExtremes::concatenate(length_extremes E_X, length_extremes E_Y) {
	length_extremes E = E_X;
	E.min_words += E_Y.min_words;
	if (E.min_words > INFINITE_WORD_COUNT) E.min_words = INFINITE_WORD_COUNT;
	E.max_words += E_Y.max_words;
	if (E.max_words > INFINITE_WORD_COUNT) E.max_words = INFINITE_WORD_COUNT;
	return E;
}

@ The union provides the wider bounds, whichever they are:

=
length_extremes LengthExtremes::union(length_extremes E_X, length_extremes E_Y) {
	length_extremes E = E_X;
	if (E_Y.min_words < E.min_words) E.min_words = E_Y.min_words;
	if (E_Y.max_words > E.max_words) E.max_words = E_Y.max_words;
	return E;
}

@ The minimum matched text length for a nonterminal is the smallest of the
minima for its possible productions; for a production, it's the sum of the
minimum match lengths of its tokens.

=
length_extremes LengthExtremes::calculate_for_nt(nonterminal *nt) {
	length_extremes E = LengthExtremes::no_words_at_all();
	int first = TRUE;
	for (production_list *pl = nt->first_pl; pl; pl = pl->next_pl)
		for (production *pr = pl->first_pr; pr; pr = pr->next_pr) {
			pr->opt.pr_extremes = LengthExtremes::calculate_for_pr(pr);
			if (first) { E = pr->opt.pr_extremes; first = FALSE; }
			else { E = LengthExtremes::union(E, pr->opt.pr_extremes); }
		}
	return E;
}

length_extremes LengthExtremes::calculate_for_pr(production *pr) {
	length_extremes E = LengthExtremes::no_words_at_all();
	for (ptoken *pt = pr->first_pt; pt; pt = pt->next_pt)
		E = LengthExtremes::concatenate(E, LengthExtremes::calculate_for_pt(pt));
	return E;
}

@ An interesting point here is that the negation of a ptoken can in principle
have any length, except that we specified |^ example| to match only a single
word -- any word other than "example". So the extremes for |^ example| are
1 and 1, whereas for |^ <sample-nonterminal>| they would have to be 0 and
infinity.

=
length_extremes LengthExtremes::calculate_for_pt(ptoken *pt) {
	length_extremes E = LengthExtremes::exactly_one_word();
	if (pt->negated_ptoken) {
		if (pt->ptoken_category != FIXED_WORD_PTC)
			E = LengthExtremes::any_number_of_words();
	} else {
		switch (pt->ptoken_category) {
			case NONTERMINAL_PTC:
				Optimiser::optimise_nonterminal(pt->nt_pt); /* recurse as needed */
				E = pt->nt_pt->opt.nt_extremes; break;
			case MULTIPLE_WILDCARD_PTC:
				E = LengthExtremes::at_least_one_word(); break;
			case POSSIBLY_EMPTY_WILDCARD_PTC:
				E = LengthExtremes::any_number_of_words(); break;
		}
	}
	return E;
}
