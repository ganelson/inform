[Declensions::] Declensions.

Declensions are sets of inflected variations of a common stem
according to grammatical case.

@ The traditional term "declension" refers to the set of inflected forms of a
word which does not serve as a verb: nouns, adjectives and pronouns all have
"declensions". These forms generally vary according to gender, number and
also "case", which expresses context.

The //inflections// module uses the term "declension" in a more limited sense:
it is just the set of variations by case. Variations by gender and number are
taken care of by what are less elegantly called //Lexical Clusters//.

At any rate, a //declension// object is a set of wordings, one for each case:

=
typedef struct declension {
	NATURAL_LANGUAGE_WORDS_TYPE *within_language;
	struct wording wording_cased[MAX_GRAMMATICAL_CASES];
	lcon_ti lcon_cased[MAX_GRAMMATICAL_CASES];
} declension;

@ Cases in a language are itemised in the special nonterminal <grammatical-case-names>:

=
int Declensions::no_cases(NATURAL_LANGUAGE_WORDS_TYPE *nl) {
	nonterminal *nt = <grammatical-case-names>;
	for (production_list *pl = nt->first_pl; pl; pl = pl->next_pl) {
		if ((pl->definition_language == NULL) || (pl->definition_language == nl)) {
			int c = 0;
			for (production *pr = pl->first_pr; pr; pr = pr->next_pr) c++;
			if (c >= MAX_GRAMMATICAL_CASES)
				Declensions::error(nt, nl, I"too many cases");
			return c;
		}
	}
	Declensions::error(nt, nl, I"not provided for this language");
	return -1;
}

@ The following is useful for debugging:

=
void Declensions::writer(OUTPUT_STREAM, declension *D, declension *AD) {
	nonterminal *nt = <grammatical-case-names>;
	int nc = Declensions::no_cases(D->within_language);
	for (production_list *pl = nt->first_pl; pl; pl = pl->next_pl) {
		if ((pl->definition_language == NULL) ||
			(pl->definition_language == D->within_language)) {
			int c = 0;
			for (production *pr = pl->first_pr; pr; pr = pr->next_pr) {
				if ((pr->first_pt == NULL) ||
					(pr->first_pt->ptoken_category != FIXED_WORD_PTC) ||
					(pr->first_pt->next_pt != NULL))
					Declensions::error(nt, D->within_language, I"too complex");
				if (c > 0) WRITE(", ");
				WRITE("%w: %W %W", Vocabulary::get_exemplar(pr->first_pt->ve_pt, TRUE),
					AD->wording_cased[c], D->wording_cased[c]);
				c++;
				if (c >= nc) break;
			}
			WRITE("\n");
			return;
		}
	}
	Declensions::error(nt, D->within_language, I"not provided for this language");
}

@ And this function extracts the right form for a given case |c|:

=
wording Declensions::in_case(declension *D, int c) {
	if ((c < 0) || (c >= Declensions::no_cases(D->within_language)))
		internal_error("case out of range");
	return D->wording_cased[c];
}

@ So much for using declensions; now to generate them. They are inflected from
the stem by special Preform nonterminals:

=
declension Declensions::of_noun(wording W, NATURAL_LANGUAGE_WORDS_TYPE *nl,
	int gen, int num) {
	nl = DefaultLanguage::get(nl);
	declension D = Declensions::decline_inner(W, nl, gen, num, <noun-declension>);
	@<Fix the origin@>;
	return D;
}

declension Declensions::of_article(wording W, NATURAL_LANGUAGE_WORDS_TYPE *nl,
	int gen, int num) {
	nl = DefaultLanguage::get(nl);
	declension D = Declensions::decline_inner(W, nl, gen, num, <article-declension>);
	@<Fix the origin@>;
	return D;
}

@ If a word comes from a given file and line number in the source text, then
we will say that so does any inflected form of it:

@<Fix the origin@> =
	for (int c = 0; c < Declensions::no_cases(nl); c++)
		LOOP_THROUGH_WORDING(i, D.wording_cased[c])
			Lexer::set_word_location(i, Lexer::word_location(Wordings::first_wn(W)));

@ For the format of the table expressed by the nonterminal |nt|, see
//What This Module Does//.

=
declension Declensions::decline_inner(wording W, NATURAL_LANGUAGE_WORDS_TYPE *nl,
	int gen, int num, nonterminal *nt) {
	nl = DefaultLanguage::get(nl);
	declension D;
	D.within_language = nl;
	int count = 0;
	for (production_list *pl = nt->first_pl; pl; pl = pl->next_pl) {
		if ((pl->definition_language == NULL) || (pl->definition_language == nl)) {
			count++;
			for (production *pr = pl->first_pr; pr; pr = pr->next_pr) {
				if ((pr->first_pt == NULL) ||
					(pr->first_pt->ptoken_category != FIXED_WORD_PTC) ||
					(pr->first_pt->next_pt == NULL) ||
					(pr->first_pt->next_pt->ptoken_category != NONTERMINAL_PTC))
					Declensions::error(nt, nl, I"line malformed");
				wchar_t *gender_letter = Vocabulary::get_exemplar(pr->first_pt->ve_pt, FALSE);
				if ((gender_letter[0] == '*') ||
					((gender_letter[0] == 'm') && (gen == MASCULINE_GENDER)) ||
					((gender_letter[0] == 'f') && (gen == FEMININE_GENDER)) ||
					((gender_letter[0] == 'n') && (gen == NEUTER_GENDER))) 
					@<Decline according to this row in declension NT@>;
			}
		}
	}
	if (count == 0) Declensions::error(nt, nl,
		I"noun declensions seem not to be provided for this language");
	else Declensions::error(nt, nl,
		I"noun declension table exists but was unterminated");
	return D;
}

@<Decline according to this row in declension NT@> =
	int found = FALSE;
	nonterminal *gnt = pr->first_pt->next_pt->nt_pt;
	if (pr->first_pt->next_pt->next_pt == NULL) {
		D = Declensions::decline_from_irregulars(W, nl, gnt, gen, num, &found);
	} else {
		if ((pr->first_pt->next_pt->next_pt->ptoken_category != NONTERMINAL_PTC) ||
			(pr->first_pt->next_pt->next_pt->next_pt != NULL))
			Declensions::error(nt, nl, I"line must end with two nonterminals");
		nonterminal *tnt = pr->first_pt->next_pt->next_pt->nt_pt;
		D = Declensions::decline_from_groups(W, nl, gnt, tnt, gen, num, &found);
	}
	if (found) return D;

@ This is for the two-token form of row, |gender table|:

=
declension Declensions::decline_from_irregulars(wording W, NATURAL_LANGUAGE_WORDS_TYPE *nl,
	nonterminal *gnt, int gen, int num, int *found) {
	*found = FALSE;
	declension D;
	D.within_language = nl;
	if (Wordings::length(W) == 1)
		for (production_list *pl = gnt->first_pl; pl; pl = pl->next_pl)
			if ((pl->definition_language == NULL) || (pl->definition_language == nl))
				for (production *pr = pl->first_pr; pr; pr = pr->next_pr) {
					vocabulary_entry *stem = pr->first_pt->ve_pt;
					if (stem == Lexer::word(Wordings::first_wn(W))) {
						*found = TRUE;
						int c = 0, nc = Declensions::no_cases(nl);
						for (ptoken *pt = pr->first_pt->next_pt; pt; pt = pt->next_pt) {
							if (pt->ptoken_category != FIXED_WORD_PTC)
								Declensions::error(gnt, nl,
									I"nonterminals are not allowed in irregular declensions");
							if (((num == SINGULAR_NUMBER) && (c < nc)) || ((num == PLURAL_NUMBER) && (c >= nc))) {
								TEMPORARY_TEXT(stem)
								TEMPORARY_TEXT(result)
								WRITE_TO(stem, "%W", W);
								Inflect::follow_suffix_instruction(result, stem,
									Vocabulary::get_exemplar(pt->ve_pt, TRUE));
								D.wording_cased[c%nc] = Feeds::feed_text(result);
								D.lcon_cased[c%nc] = Declensions::lcon(gen, num, c%nc);
								DISCARD_TEXT(stem)
								DISCARD_TEXT(result)
							}
							c++;
						}
						if (c < 2*nc) Declensions::error(gnt, nl,
							I"too few cases in irregular declension");
						if (c > 2*nc) Declensions::error(gnt, nl,
							I"too many cases in irregular declension");
						return D;
					}
				}
	return D;
}

@ And this is for the three-token form of row, |gender grouper table|:

=
declension Declensions::decline_from_groups(wording W, NATURAL_LANGUAGE_WORDS_TYPE *nl,
	nonterminal *gnt, nonterminal *nt, int gen, int num, int *found) {
	declension D;
	D.within_language = nl;
	TEMPORARY_TEXT(from)
	WRITE_TO(from, "%+W", W);
	match_avinue *group_trie = PreformUtilities::define_trie(gnt, TRIE_END,
		DefaultLanguage::get(nl));
	wchar_t *result = Tries::search_avinue(group_trie, from);
	DISCARD_TEXT(from)
	if (result == NULL) {
		*found = FALSE;
	} else {
		*found = TRUE;
		int group;
		@<Set the group number@>;
		for (production_list *pl = nt->first_pl; pl; pl = pl->next_pl)
			if ((pl->definition_language == NULL) || (pl->definition_language == nl))
				for (production *pr = pl->first_pr; pr; pr = pr->next_pr) {
					if ((pr->first_pt == NULL) ||
						(pr->first_pt->ptoken_category != NONTERMINAL_PTC) ||
						(pr->first_pt->next_pt != NULL))
						internal_error("noun declension nonterminal malformed");
					if (--group == 0)
						return Declensions::decline_from(W, nl, pr->first_pt->nt_pt, gen, num);
				}
		internal_error("noun declension nonterminal has too few groups");
	}
	return D;
}

@<Set the group number@> =
	group = result[0] - '0';
	if ((group <= 0) || (group > 9))
		internal_error("noun declension grouper result not a group number");
	if (result[1]) {
		int u = result[1] - '0';
		if ((u < 0) || (u > 9))
			internal_error("noun declension grouper result not a group number");
		group = group*10 + u;
		if (result[2]) internal_error("noun declension grouper result too high");
	}

@ We have now found the actual declension table NT; if there are $N$ cases
in the language, there will be $2N$ productions in this table, each of which
consists of a single word giving the rewriting instruction to use.

=
declension Declensions::decline_from(wording W, NATURAL_LANGUAGE_WORDS_TYPE *nl,
	nonterminal *nt, int gen, int num) {
	int c = 0, nc = Declensions::no_cases(nl);
	declension D;
	D.within_language = nl;
	for (production_list *pl = nt->first_pl; pl; pl = pl->next_pl) {
		if ((pl->definition_language == NULL) || (pl->definition_language == nl)) {
			for (production *pr = pl->first_pr; pr; pr = pr->next_pr) {
				if ((pr->first_pt == NULL) ||
					(pr->first_pt->ptoken_category != FIXED_WORD_PTC) ||
					(pr->first_pt->next_pt != NULL))
					internal_error("<noun-declension> too complex");
				if (((c < nc) && (num == SINGULAR_NUMBER)) || ((c >= nc) && (num == PLURAL_NUMBER))) {
					TEMPORARY_TEXT(stem)
					TEMPORARY_TEXT(result)
					WRITE_TO(stem, "%+W", W);
					Inflect::follow_suffix_instruction(result, stem,
						Vocabulary::get_exemplar(pr->first_pt->ve_pt, TRUE));
					D.wording_cased[c%nc] = Feeds::feed_text(result);
					D.lcon_cased[c%nc] = Declensions::lcon(gen, num, c%nc);
					DISCARD_TEXT(stem)
					DISCARD_TEXT(result)
				}
				c++;
			}
			if (c < 2*nc) internal_error("too few cases in declension");
			if (c > 2*nc) internal_error("too many cases in declension");
			return D;
		}
	}
	internal_error("declination unavailable");
	return D;
}

@ Where, finally:

=
lcon_ti Declensions::lcon(int gen, int num, int c) {
	lcon_ti l = Lcon::base();
	l = Lcon::set_number(l, num);
	l = Lcon::set_gender(l, gen);
	l = Lcon::set_case(l, c);
	return l;
}

@

=
void Declensions::error(nonterminal *nt, NATURAL_LANGUAGE_WORDS_TYPE *nl, text_stream *err) {
	#ifdef PREFORM_ERROR_INFLECTIONS_CALLBACK
	PREFORM_ERROR_INFLECTIONS_CALLBACK(nt, nl, err);
	#endif
	#ifndef PREFORM_ERROR_INFLECTIONS_CALLBACK
	WRITE_TO(STDERR, "Declension error in Preform syntax ");
	if (nt) WRITE_TO(STDERR, "in the nonterminal '%V'", nt->nonterminal_id);
	WRITE_TO(STDERR, ": %S\n", err);
	internal_error("halted with Preform syntax error");
	#endif
}
