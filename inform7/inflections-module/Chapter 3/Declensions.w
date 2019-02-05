[Declensions::] Declensions.

Declensions are sets of inflected variations of a common stem
according to grammatical case.

@h Declension.

=
typedef struct declension {
	PREFORM_LANGUAGE_TYPE *within_language;
	struct wording name_cased[MAX_GRAMMATICAL_CASES];
} declension;

@ =
declension Declensions::decline(wording W, PREFORM_LANGUAGE_TYPE *nl, int gen, int num) {
	if (nl == NULL) nl = English_language;
	declension D = Declensions::decline_inner(W, nl, gen, num, <noun-declension>);
	@<Fix the origin@>;
	return D;
}

declension Declensions::decline_article(wording W, PREFORM_LANGUAGE_TYPE *nl, int gen, int num) {
	if (nl == NULL) nl = English_language;
	declension D = Declensions::decline_inner(W, nl, gen, num, <article-declension>);
	@<Fix the origin@>;
	return D;
}

@<Fix the origin@> =
	int nc = Declensions::no_cases(nl);
	for (int c = 0; c < nc; c++)
		LOOP_THROUGH_WORDING(i, D.name_cased[c])
			Lexer::set_word_location(i,
				Lexer::word_location(
					Wordings::first_wn(W)));

@ =
declension Declensions::decline_inner(wording W, PREFORM_LANGUAGE_TYPE *nl, int gen, int num, nonterminal *nt) {
	if (nl == NULL) nl = English_language;
	declension D;
	D.within_language = nl;
	for (production_list *pl = nt->first_production_list; pl; pl = pl->next_production_list) {
		if ((pl->definition_language == NULL) || (pl->definition_language == nl)) {
			for (production *pr = pl->first_production; pr; pr = pr->next_production) {
				if ((pr->first_ptoken == NULL) ||
					(pr->first_ptoken->ptoken_category != FIXED_WORD_PTC) ||
					(pr->first_ptoken->next_ptoken == NULL) ||
					(pr->first_ptoken->next_ptoken->ptoken_category != NONTERMINAL_PTC))
					internal_error("line in <noun-declension> malformed");
				wchar_t *gender_letter = Vocabulary::get_exemplar(pr->first_ptoken->ve_pt, FALSE);
				if ((gender_letter[0] == '*') ||
					((gender_letter[0] == 'm') && (gen == MASCULINE_GENDER)) ||
					((gender_letter[0] == 'f') && (gen == FEMININE_GENDER)) ||
					((gender_letter[0] == 'n') && (gen == NEUTER_GENDER))) {
					int found = FALSE;
					nonterminal *gnt = pr->first_ptoken->next_ptoken->nt_pt;
					if (pr->first_ptoken->next_ptoken->next_ptoken == NULL) {
						D = Declensions::decline_from_irregulars(W, nl, gnt, num, &found);
					} else {
						if ((pr->first_ptoken->next_ptoken->next_ptoken->ptoken_category != NONTERMINAL_PTC) ||
							(pr->first_ptoken->next_ptoken->next_ptoken->next_ptoken != NULL))
							internal_error("this line must end with two nonterminals");
						nonterminal *tnt = pr->first_ptoken->next_ptoken->next_ptoken->nt_pt;
						D = Declensions::decline_from_groups(W, nl, gnt, tnt, num, &found);
					}
					if (found) return D;
				}

			}
		}
	}
	internal_error("no declension table terminated");
	return D;
}

declension Declensions::decline_from_irregulars(wording W, PREFORM_LANGUAGE_TYPE *nl,
	nonterminal *gnt, int num, int *found) {
	*found = FALSE;
	declension D;
	D.within_language = nl;
	if (Wordings::length(W) == 1)
		for (production_list *pl = gnt->first_production_list; pl; pl = pl->next_production_list)
			if ((pl->definition_language == NULL) || (pl->definition_language == nl))
				for (production *pr = pl->first_production; pr; pr = pr->next_production) {
					vocabulary_entry *stem = pr->first_ptoken->ve_pt;
					if (stem == Lexer::word(Wordings::first_wn(W))) {
						*found = TRUE;
						int c = 0, nc = Declensions::no_cases(nl);
						for (ptoken *pt = pr->first_ptoken->next_ptoken; pt; pt = pt->next_ptoken) {
							if (pt->ptoken_category != FIXED_WORD_PTC)
								internal_error("nonterminals are not allowed in irregular declensions");
							if (((num == 1) && (c < nc)) || ((num == 2) && (c >= nc))) {
								TEMPORARY_TEXT(stem);
								TEMPORARY_TEXT(result);
								WRITE_TO(stem, "%W", W);
								Inflections::follow_suffix_instruction(result, stem,
									Vocabulary::get_exemplar(pt->ve_pt, TRUE));
								D.name_cased[c%nc] = Feeds::feed_stream(result);
								DISCARD_TEXT(stem);
								DISCARD_TEXT(result);
							}
							c++;
						}
						if (c < 2*nc) internal_error("too few cases in irregular declension");
						if (c > 2*nc) internal_error("too many cases in irregular declension");
						return D;
					}
				}
	return D;
}

declension Declensions::decline_from_groups(wording W, PREFORM_LANGUAGE_TYPE *nl,
	nonterminal *gnt, nonterminal *nt, int num, int *found) {
	declension D;
	D.within_language = nl;
	TEMPORARY_TEXT(from);
	WRITE_TO(from, "%+W", W);
	match_avinue *group_trie = Preform::Nonparsing::define_trie(gnt, TRIE_END, nl);
	wchar_t *result = Tries::search_avinue(group_trie, from);
	DISCARD_TEXT(from);
	if (result == NULL) {
		*found = FALSE;
	} else {
		*found = TRUE;
		int group = result[0] - '0';
		if ((group <= 0) || (group > 9))
			internal_error("noun declension nonterminal result not a group number");
		for (production_list *pl = nt->first_production_list; pl; pl = pl->next_production_list) {
			if ((pl->definition_language == NULL) || (pl->definition_language == nl)) {
				for (production *pr = pl->first_production; pr; pr = pr->next_production) {
					if ((pr->first_ptoken == NULL) ||
						(pr->first_ptoken->ptoken_category != NONTERMINAL_PTC) ||
						(pr->first_ptoken->next_ptoken != NULL))
						internal_error("noun declension nonterminal malformed");
					if (--group == 0)
						return Declensions::decline_from(W, nl, pr->first_ptoken->nt_pt, num);
				}
			}
		}
		internal_error("noun declension nonterminal has too few groups");
	}
	return D;
}

declension Declensions::decline_from(wording W, PREFORM_LANGUAGE_TYPE *nl, nonterminal *nt, int num) {
	int c = 0, nc = Declensions::no_cases(nl);
	declension D;
	D.within_language = nl;
	for (production_list *pl = nt->first_production_list; pl; pl = pl->next_production_list) {
		if ((pl->definition_language == NULL) || (pl->definition_language == nl)) {
			for (production *pr = pl->first_production; pr; pr = pr->next_production) {
				if ((pr->first_ptoken == NULL) ||
					(pr->first_ptoken->ptoken_category != FIXED_WORD_PTC) ||
					(pr->first_ptoken->next_ptoken != NULL))
					internal_error("<noun-declension> too complex");
				if (((c < nc) && (num == 1)) || ((c >= nc) && (num == 2))) {
					TEMPORARY_TEXT(stem);
					TEMPORARY_TEXT(result);
					WRITE_TO(stem, "%+W", W);
					Inflections::follow_suffix_instruction(result, stem,
						Vocabulary::get_exemplar(pr->first_ptoken->ve_pt, TRUE));
					D.name_cased[c%nc] = Feeds::feed_stream(result);
					DISCARD_TEXT(stem);
					DISCARD_TEXT(result);
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

wording Declensions::in_case(declension *D, int c) {
	if ((c < 0) || (c >= Declensions::no_cases(D->within_language))) internal_error("case out of range");
	return D->name_cased[c];
}

int Declensions::no_cases(PREFORM_LANGUAGE_TYPE *nl) {
	nonterminal *nt = <grammatical-case-names>;
	for (production_list *pl = nt->first_production_list; pl; pl = pl->next_production_list) {
		if ((pl->definition_language == NULL) || (pl->definition_language == nl)) {
			int c = 0;
			for (production *pr = pl->first_production; pr; pr = pr->next_production) c++;
			if (c >= MAX_GRAMMATICAL_CASES)
				internal_error("<grammatical-case-names> lists too many cases");
			return c;
		}
	}
	internal_error("<grammatical-case-names> not provided for this language");
	return -1;
}

void Declensions::writer(OUTPUT_STREAM, declension *D, declension *AD) {
	nonterminal *nt = <grammatical-case-names>;
	int nc = Declensions::no_cases(D->within_language);
	for (production_list *pl = nt->first_production_list; pl; pl = pl->next_production_list) {
		if ((pl->definition_language == NULL) || (pl->definition_language == D->within_language)) {
			int c = 0;
			for (production *pr = pl->first_production; pr; pr = pr->next_production) {
				if ((pr->first_ptoken == NULL) ||
					(pr->first_ptoken->ptoken_category != FIXED_WORD_PTC) ||
					(pr->first_ptoken->next_ptoken != NULL))
					internal_error("<grammatical-case-names> too complex");
				if (c > 0) WRITE(", ");
				WRITE("%w: %W %W", Vocabulary::get_exemplar(pr->first_ptoken->ve_pt, TRUE),
					AD->name_cased[c], D->name_cased[c]);
				c++;
				if (c >= nc) break;
			}
			WRITE("\n");
			return;
		}
	}
	internal_error("<grammatical-case-names> not provided for this language");
}
