[Optimiser::] The Optimiser.

To precalculate data which enables rapid parsing of source text against a
Preform grammar.

@h Optimisation calculations.
After each round of fresh Preform grammar, we need to recalculate the various
maximum and minimum lengths, struts, and so on, because those all depend on
knowing the length of text a token will match, and new grammar may have
changed that.

=
int first_round_of_nt_optimisation_made = FALSE;

typedef struct nonterminal_optimisation_data {
	int optimised_in_this_pass; /* have the following been worked out yet? */
	int min_nt_words, max_nt_words; /* for speed */
	struct range_requirement nonterminal_req;
	int nt_req_bit; /* which hashing category the words belong to, or $-1$ if none */
	int number_words_by_production;
	unsigned int flag_words_in_production;
} nonterminal_optimisation_data;


void Optimiser::initialise_nonterminal_data(nonterminal_optimisation_data *opt) {
	opt->optimised_in_this_pass = FALSE;
	opt->min_nt_words = 1; opt->max_nt_words = INFINITE_WORD_COUNT;
	opt->nt_req_bit = -1;
	opt->number_words_by_production = FALSE;
	opt->flag_words_in_production = 0;
	Optimiser::clear_rreq(&(opt->nonterminal_req));
}

typedef struct ptoken_optimisation_data {
	int ptoken_position; /* fixed position in range: 1, 2, ... for left, -1, -2, ... for right */
	int strut_number; /* if this is part of a strut, what number? or -1 if not */
	int ptoken_is_fast; /* can be checked in the fast pass of the parser */
	struct range_requirement token_req;
} ptoken_optimisation_data;

void Optimiser::initialise_ptoken_data(ptoken_optimisation_data *opt) {
	opt->ptoken_position = 0;
	opt->strut_number = -1;
	opt->ptoken_is_fast = FALSE;
	Optimiser::clear_rreq(&(opt->token_req));
}

typedef struct production_optimisation_data {
	int min_pr_words, max_pr_words;
	struct range_requirement production_req;
	int no_struts;
	struct ptoken *struts[MAX_STRUTS_PER_PRODUCTION]; /* first ptoken in strut */
	int strut_lengths[MAX_STRUTS_PER_PRODUCTION]; /* length of the strut in words */
} production_optimisation_data;

void Optimiser::initialise_production_data(production_optimisation_data *opt) {
	opt->no_struts = 0;
	opt->min_pr_words = 1; opt->max_pr_words = INFINITE_WORD_COUNT;
	Optimiser::clear_rreq(&(opt->production_req));
}

typedef struct range_requirement {
	int no_requirements;
	int ditto_flag;
	int DW_req;
	int DS_req;
	int CW_req;
	int CS_req;
	int FW_req;
	int FS_req;
} range_requirement;

int no_req_bits = 0;


void Optimiser::optimise_counts(void) {
	nonterminal *nt;
	LOOP_OVER(nt, nonterminal) {
		Optimiser::clear_rreq(&(nt->opt.nonterminal_req));
		if (nt->marked_internal) {
			nt->opt.optimised_in_this_pass = TRUE;
		} else {
			nt->opt.optimised_in_this_pass = FALSE;
			nt->opt.min_nt_words = 1; nt->opt.max_nt_words = INFINITE_WORD_COUNT;
		}
	}
	if (first_round_of_nt_optimisation_made == FALSE) {
		first_round_of_nt_optimisation_made = TRUE;
		#ifdef LINGUISTICS_MODULE
		LinguisticsModule::preform_optimiser();
		#endif
		#ifdef PREFORM_OPTIMISER
		PREFORM_OPTIMISER();
		#endif
	}
	LOOP_OVER(nt, nonterminal) Optimiser::optimise_nt(nt);
	LOOP_OVER(nt, nonterminal) Optimiser::optimise_nt_reqs(nt);
}

void Optimiser::optimise_nt(nonterminal *nt) {
	if (nt->opt.optimised_in_this_pass) return;
	nt->opt.optimised_in_this_pass = TRUE;
	@<Compute the minimum and maximum match lengths@>;

	production_list *pl;
	for (pl = nt->first_production_list; pl; pl = pl->next_production_list) {
		production *pr;
		for (pr = pl->first_production; pr; pr = pr->next_production) {
			ptoken *last = NULL; /* this will point to the last ptoken in the production */
			@<Compute front-end ptoken positions@>;
			@<Compute back-end ptoken positions@>;
			@<Compute struts within the production@>;
			@<Work out which ptokens are fast@>;
		}
	}
	@<Mark the vocabulary's incidence list with this nonterminal@>;
}

@ The minimum matched text length for a nonterminal is the smallest of the
minima for its possible productions; for a production, it's the sum of the
minimum match lengths of its tokens.

@<Compute the minimum and maximum match lengths@> =
	int min = -1, max = -1;
	production_list *pl;
	for (pl = nt->first_production_list; pl; pl = pl->next_production_list) {
		production *pr;
		for (pr = pl->first_production; pr; pr = pr->next_production) {
			int min_p = 0, max_p = 0;
			ptoken *pt;
			for (pt = pr->first_ptoken; pt; pt = pt->next_ptoken) {
				int min_t, max_t;
				Optimiser::ptoken_extrema(pt, &min_t, &max_t);
				min_p += min_t; max_p += max_t;
				if (min_p > INFINITE_WORD_COUNT) min_p = INFINITE_WORD_COUNT;
				if (max_p > INFINITE_WORD_COUNT) max_p = INFINITE_WORD_COUNT;
			}
			pr->opt.min_pr_words = min_p; pr->opt.max_pr_words = max_p;
			if ((min == -1) && (max == -1)) { min = min_p; max = max_p; }
			else {
				if (min_p < min) min = min_p;
				if (max_p > max) max = max_p;
			}
		}
	}
	if (min >= 1) {
		nt->opt.min_nt_words = min; nt->opt.max_nt_words = max;
	}

@ A token is "elastic" if it can match text of differing lengths, and
"inelastic" otherwise. For example, in English, <indefinite-article> is
elastic (it always matches a single word). If the first ptoken is inelastic,
we know it must match words 1 to $L_1$ of whatever text is to be matched,
and we give it position 1; if the second is also inelastic, that will match
$L_1+1$ to $L_2$, and it gets position $L_1+1$; and so on. As soon as we
hit an elastic token -- a wildcard like |...|, for example -- this
predictability stops, and we can only assign position 0, which means that
we don't know.

Note that we only assign a nonzero position if we know where the ptoken both
starts and finishes; it's not enough just to know where it starts.

@<Compute front-end ptoken positions@> =
	int posn = 1;
	ptoken *pt;
	for (pt = pr->first_ptoken; pt; pt = pt->next_ptoken) {
		last = pt;
		int L = Optimiser::ptoken_width(pt);
		if ((posn != 0) && (L != PTOKEN_ELASTIC)) {
			pt->opt.ptoken_position = posn;
			posn += L;
		} else {
			pt->opt.ptoken_position = 0; /* thus clearing any expired positions from earlier */
			posn = 0;
		}
	}

@ And similarly from the back end, if there are inelastic ptokens at the end
of the production (and which are separated from the front end by at least one
elastic one).

The following has quadratic running time in the number of tokens in the
production, but this is never larger than about 10.

@<Compute back-end ptoken positions@> =
	int posn = -1;
	ptoken *pt;
	for (pt = last; pt; ) {
		if (pt->opt.ptoken_position != 0) break; /* don't use a back-end position if there's a front one */
		int L = Optimiser::ptoken_width(pt);
		if ((posn != 0) && (L != PTOKEN_ELASTIC)) {
			pt->opt.ptoken_position = posn;
			posn -= L;
		} else break;

		ptoken *prevt = NULL;
		for (prevt = pr->first_ptoken; prevt; prevt = prevt->next_ptoken)
			if (prevt->next_ptoken == pt)
				break;
		pt = prevt;
	}

@ There's a new idea here as well, though: struts. A "strut" is a run of
ptokens in the interior of the production whose position relative to the
ends is not known. For example, if we match:
= (text as Preform)
	frogs like ... but not ... to eat
=
then we know that in a successful match, "frogs" and "like" must be the
first two words in the text matched, and "eat" and "to" the last two.
They are said to have positions 1, 2, -1 and -2 respectively: a positive
number is relative to the start of the range, a negative relative to the end,
so that position 1 is always the first word and position -1 is the last.

But we don't know where "but not" will occur; it could be anywhere in the
middle of the text. So the ptokens for these words have position 0. A run of
such ptokens, not counting wildcards like |...|, is called a strut. We can
think of it as a partition which can slide backwards and forwards. Many
productions have no struts at all; the above example has just one. It has
length 2, not because it contains two ptokens, but because it is always
two words wide.

Finding struts when Preform grammar is read in means that we don't have to
do so much work devising search patterns at parsing time, when speed is
critical.

@ So, then, a strut is a maximal sequence of one or more inelastic ptokens
each of which has no known position. (Clearly if one of them has a known
position then all of them have, but we're in no hurry so we don't exploit that.)

@<Compute struts within the production@> =
	pr->opt.no_struts = 0;
	ptoken *pt;
	for (pt = pr->first_ptoken; pt; pt = pt->next_ptoken) {
		if ((pt->opt.ptoken_position == 0) &&
			(Optimiser::ptoken_width(pt) != PTOKEN_ELASTIC)) {
			if (pr->opt.no_struts >= MAX_STRUTS_PER_PRODUCTION) continue;
			pr->opt.struts[pr->opt.no_struts] = pt;
			pr->opt.strut_lengths[pr->opt.no_struts] = 0;
			while ((pt->opt.ptoken_position == 0) &&
				(Optimiser::ptoken_width(pt) != PTOKEN_ELASTIC)) {
				pt->opt.strut_number = pr->opt.no_struts;
				pr->opt.strut_lengths[pr->opt.no_struts] += Optimiser::ptoken_width(pt);
				if (pt->next_ptoken == NULL) break; /* should be impossible */
				pt = pt->next_ptoken;
			}
			pr->opt.no_struts++;
		}
	}

@<Work out which ptokens are fast@> =
	ptoken *pt;
	for (pt = pr->first_ptoken; pt; pt = pt->next_ptoken)
		if ((pt->ptoken_category == FIXED_WORD_PTC) && (pt->opt.ptoken_position != 0)
			&& (pt->range_starts < 0) && (pt->range_ends < 0))
			pt->opt.ptoken_is_fast = TRUE;

@ Weak requirement: one word in range must match one of these bits
Strong ": all bits in this range must be matched by one word

@<Mark the vocabulary's incidence list with this nonterminal@> =
	int first_production = TRUE;
	Optimiser::clear_rreq(&(nt->opt.nonterminal_req));
	#ifdef PREFORM_CIRCULARITY_BREAKER
	PREFORM_CIRCULARITY_BREAKER(nt);
	#endif
	range_requirement nnt;
	Optimiser::clear_rreq(&nnt);
	for (pl = nt->first_production_list; pl; pl = pl->next_production_list) {
		production *pr;
		for (pr = pl->first_production; pr; pr = pr->next_production) {
			ptoken *pt;
			for (pt = pr->first_ptoken; pt; pt = pt->next_ptoken) {
				if ((pt->ptoken_category == FIXED_WORD_PTC) && (pt->negated_ptoken == FALSE)) {
					ptoken *alt;
					for (alt = pt; alt; alt = alt->alternative_ptoken)
						Optimiser::set_nt_incidence(alt->ve_pt, nt);
				}
			}
		}
	}
	for (pl = nt->first_production_list; pl; pl = pl->next_production_list) {
		production *pr;
		for (pr = pl->first_production; pr; pr = pr->next_production) {
			range_requirement prt;
			Optimiser::clear_rreq(&prt);
			int all = TRUE, first = TRUE;
			ptoken *pt;
			for (pt = pr->first_ptoken; pt; pt = pt->next_ptoken) {
				Optimiser::clear_rreq(&(pt->opt.token_req));
				if ((pt->ptoken_category == FIXED_WORD_PTC) && (pt->negated_ptoken == FALSE)) {
					ptoken *alt;
					for (alt = pt; alt; alt = alt->alternative_ptoken)
						Optimiser::set_nt_incidence(alt->ve_pt, nt);
					Optimiser::atomic_rreq(&(pt->opt.token_req), nt);
				} else all = FALSE;
				int self_referential = FALSE, empty = FALSE;
				if ((pt->ptoken_category == NONTERMINAL_PTC) &&
					(pt->nt_pt->opt.min_nt_words == 0) && (pt->nt_pt->opt.max_nt_words == 0))
					empty = TRUE; /* even if negated, notice */
				if ((pt->ptoken_category == NONTERMINAL_PTC) && (pt->negated_ptoken == FALSE)) {
					/* if (pt->nt_pt == nt) self_referential = TRUE; */
					Optimiser::optimise_nt(pt->nt_pt);
					pt->opt.token_req = pt->nt_pt->opt.nonterminal_req;
				}
				if ((self_referential == FALSE) && (empty == FALSE)) {
					if (first) {
						prt = pt->opt.token_req;
					} else {
						Optimiser::concatenate_rreq(&prt, &(pt->opt.token_req));
					}
					first = FALSE;
				}
			}
			if (first_production) {
				nnt = prt;
			} else {
				Optimiser::disjoin_rreq(&nnt, &prt);
			}
			first_production = FALSE;
			pr->opt.production_req = prt;
		}
	}
	nt->opt.nonterminal_req = nnt;
	#ifdef PREFORM_CIRCULARITY_BREAKER
	PREFORM_CIRCULARITY_BREAKER(nt);
	#endif

@

The constant |AL_BITMAP| used in this code has a pleasingly Arabic sound to it
-- a second-magnitude star, an idiotically tall hotel -- but is in fact a
combination of the meaning codes found in an adjective list.

=
void Optimiser::optimise_nt_reqs(nonterminal *nt) {
	production_list *pl;
	for (pl = nt->first_production_list; pl; pl = pl->next_production_list) {
		production *pr;
		range_requirement *prev_req = NULL;
		for (pr = pl->first_production; pr; pr = pr->next_production) {
			Optimiser::optimise_req(&(pr->opt.production_req), prev_req);
			prev_req = &(pr->opt.production_req);
		}
	}
	Optimiser::optimise_req(&(nt->opt.nonterminal_req), NULL);
}

void Optimiser::optimise_req(range_requirement *req, range_requirement *prev) {
	if ((req->DS_req & req->FS_req) == req->DS_req) req->DS_req = 0;
	if ((req->DW_req & req->FW_req) == req->DW_req) req->DW_req = 0;

	if ((req->CS_req & req->FS_req) == req->FS_req) req->FS_req = 0;
	if ((req->CW_req & req->FW_req) == req->FW_req) req->FW_req = 0;

	if ((req->CS_req & req->DS_req) == req->DS_req) req->DS_req = 0;
	if ((req->CW_req & req->DW_req) == req->DW_req) req->DW_req = 0;

	if ((req->FW_req & req->FS_req) == req->FW_req) req->FW_req = 0;
	if ((req->DW_req & req->DS_req) == req->DW_req) req->DW_req = 0;
	if ((req->CW_req & req->CS_req) == req->CW_req) req->CW_req = 0;
	req->no_requirements = TRUE;
	if ((req->DS_req) || (req->DW_req) || (req->CS_req) || (req->CW_req) || (req->FS_req) || (req->FW_req))
		req->no_requirements = FALSE;

	req->ditto_flag = FALSE;
	if ((prev) &&
		(req->DS_req == prev->DS_req) && (req->DW_req == prev->DW_req) &&
		(req->CS_req == prev->CS_req) && (req->CW_req == prev->CW_req) &&
		(req->FS_req == prev->FS_req) && (req->FW_req == prev->FW_req))
		req->ditto_flag = TRUE;
}

@ =
void Optimiser::mark_nt_as_requiring_itself(nonterminal *nt) {
	nt->opt.nonterminal_req.DS_req |= (Optimiser::nt_bitmap_bit(nt));
	nt->opt.nonterminal_req.DW_req |= (Optimiser::nt_bitmap_bit(nt));
}

void Optimiser::mark_nt_as_requiring_itself_first(nonterminal *nt) {
	nt->opt.nonterminal_req.DS_req |= (Optimiser::nt_bitmap_bit(nt));
	nt->opt.nonterminal_req.DW_req |= (Optimiser::nt_bitmap_bit(nt));
	nt->opt.nonterminal_req.FS_req |= (Optimiser::nt_bitmap_bit(nt));
	nt->opt.nonterminal_req.FW_req |= (Optimiser::nt_bitmap_bit(nt));
}

void Optimiser::mark_nt_as_requiring_itself_conj(nonterminal *nt) {
	nt->opt.nonterminal_req.DS_req |= (Optimiser::nt_bitmap_bit(nt));
	nt->opt.nonterminal_req.DW_req |= (Optimiser::nt_bitmap_bit(nt));
	nt->opt.nonterminal_req.CS_req |= (Optimiser::nt_bitmap_bit(nt));
	nt->opt.nonterminal_req.CW_req |= (Optimiser::nt_bitmap_bit(nt));
	nt->opt.nonterminal_req.FS_req |= (Optimiser::nt_bitmap_bit(nt));
	nt->opt.nonterminal_req.FW_req |= (Optimiser::nt_bitmap_bit(nt));
}

void Optimiser::mark_nt_as_requiring_itself_augmented(nonterminal *nt, int x) {
	nt->opt.nonterminal_req.DS_req |= (Optimiser::nt_bitmap_bit(nt));
	nt->opt.nonterminal_req.DW_req |= (Optimiser::nt_bitmap_bit(nt));
	nt->opt.nonterminal_req.CW_req |= (Optimiser::nt_bitmap_bit(nt) + x);
	nt->opt.nonterminal_req.FW_req |= (Optimiser::nt_bitmap_bit(nt) + x);
}

void Optimiser::set_nt_incidence(vocabulary_entry *ve, nonterminal *nt) {
	int R = Vocabulary::get_ntb(ve);
	R |= (Optimiser::nt_bitmap_bit(nt));
	Vocabulary::set_ntb(ve, R);
}

int Optimiser::test_nt_incidence(vocabulary_entry *ve, nonterminal *nt) {
	int R = Vocabulary::get_ntb(ve);
	if (R & (Optimiser::nt_bitmap_bit(nt))) return TRUE;
	return FALSE;
}

@

@d RESERVED_NT_BITS 6

=
int Optimiser::nt_bitmap_bit(nonterminal *nt) {
	if (nt->opt.nt_req_bit == -1) {
		int b = RESERVED_NT_BITS + ((no_req_bits++)%(32-RESERVED_NT_BITS));
		nt->opt.nt_req_bit = (1 << b);
	}
	return nt->opt.nt_req_bit;
}

void Optimiser::assign_bitmap_bit(nonterminal *nt, int b) {
	if (nt == NULL) internal_error("null NT");
	nt->opt.nt_req_bit = (1 << b);
}

int Optimiser::test_word(int wn, nonterminal *nt) {
	int b = Optimiser::nt_bitmap_bit(nt);
	if ((Vocabulary::get_ntb(Lexer::word(wn))) & b) return TRUE;
	return FALSE;
}

void Optimiser::mark_word(int wn, nonterminal *nt) {
	Optimiser::set_nt_incidence(Lexer::word(wn), nt);
}

void Optimiser::mark_vocabulary(vocabulary_entry *ve, nonterminal *nt) {
	Optimiser::set_nt_incidence(ve, nt);
}

int Optimiser::test_vocabulary(vocabulary_entry *ve, nonterminal *nt) {
	int b = Optimiser::nt_bitmap_bit(nt);
	if ((Vocabulary::get_ntb(ve)) & b) return TRUE;
	return FALSE;
}

int Optimiser::get_range_disjunction(wording W) {
	int R = 0;
	LOOP_THROUGH_WORDING(i, W)
		R |= Vocabulary::get_ntb(Lexer::word(i));
	return R;
}

int Optimiser::get_range_conjunction(wording W) {
	int R = 0;
	LOOP_THROUGH_WORDING(i, W) {
		if (i == Wordings::first_wn(W)) R = Vocabulary::get_ntb(Lexer::word(i));
		else R &= Vocabulary::get_ntb(Lexer::word(i));
	}
	return R;
}

@ =
int Optimiser::nt_bitmap_violates(wording W, range_requirement *req) {
	if (req->no_requirements) return FALSE;
	if (Wordings::length(W) == 1) {
		int bm = Vocabulary::get_ntb(Lexer::word(Wordings::first_wn(W)));
		if (((bm) & (req->FS_req)) != (req->FS_req)) return TRUE;
		if ((((bm) & (req->FW_req)) == 0) && (req->FW_req)) return TRUE;
		if (((bm) & (req->DS_req)) != (req->DS_req)) return TRUE;
		if ((((bm) & (req->DW_req)) == 0) && (req->DW_req)) return TRUE;
		if (((bm) & (req->CS_req)) != (req->CS_req)) return TRUE;
		if ((((bm) & (req->CW_req)) == 0) && (req->CW_req)) return TRUE;
		return FALSE;
	}
	int C_set = ((req->CS_req) | (req->CW_req));
	int D_set = ((req->DS_req) | (req->DW_req));
	int F_set = ((req->FS_req) | (req->FW_req));
	if ((C_set) && (D_set)) {
		int disj = 0;
		LOOP_THROUGH_WORDING(i, W) {
			int bm = Vocabulary::get_ntb(Lexer::word(i));
			disj |= bm;
			if (((bm) & (req->CS_req)) != (req->CS_req)) return TRUE;
			if ((((bm) & (req->CW_req)) == 0) && (req->CW_req)) return TRUE;
			if ((i == Wordings::first_wn(W)) && (F_set)) {
				if (((bm) & (req->FS_req)) != (req->FS_req)) return TRUE;
				if ((((bm) & (req->FW_req)) == 0) && (req->FW_req)) return TRUE;
			}
		}
		if (((disj) & (req->DS_req)) != (req->DS_req)) return TRUE;
		if ((((disj) & (req->DW_req)) == 0) && (req->DW_req)) return TRUE;
	} else if (C_set) {
		LOOP_THROUGH_WORDING(i, W) {
			int bm = Vocabulary::get_ntb(Lexer::word(i));
			if (((bm) & (req->CS_req)) != (req->CS_req)) return TRUE;
			if ((((bm) & (req->CW_req)) == 0) && (req->CW_req)) return TRUE;
			if ((i == Wordings::first_wn(W)) && (F_set)) {
				if (((bm) & (req->FS_req)) != (req->FS_req)) return TRUE;
				if ((((bm) & (req->FW_req)) == 0) && (req->FW_req)) return TRUE;
			}
		}
	} else if (D_set) {
		int disj = 0;
		LOOP_THROUGH_WORDING(i, W) {
			int bm = Vocabulary::get_ntb(Lexer::word(i));
			disj |= bm;
			if ((i == Wordings::first_wn(W)) && (F_set)) {
				if (((bm) & (req->FS_req)) != (req->FS_req)) return TRUE;
				if ((((bm) & (req->FW_req)) == 0) && (req->FW_req)) return TRUE;
			}
		}
		if (((disj) & (req->DS_req)) != (req->DS_req)) return TRUE;
		if ((((disj) & (req->DW_req)) == 0) && (req->DW_req)) return TRUE;
	} else if (F_set) {
		int bm = Vocabulary::get_ntb(Lexer::word(Wordings::first_wn(W)));
		if (((bm) & (req->FS_req)) != (req->FS_req)) return TRUE;
		if ((((bm) & (req->FW_req)) == 0) && (req->FW_req)) return TRUE;
	}
	return FALSE;
}

@ The first operation on RRs is concatenation. Suppose we are required to
match some words against X, then some more against Y.

=
void Optimiser::concatenate_rreq(range_requirement *req, range_requirement *with) {
	req->DS_req = Optimiser::concatenate_ds(req->DS_req, with->DS_req);
	req->DW_req = Optimiser::concatenate_dw(req->DW_req, with->DW_req);
	req->CS_req = Optimiser::concatenate_cs(req->CS_req, with->CS_req);
	req->CW_req = Optimiser::concatenate_cw(req->CW_req, with->CW_req);
	req->FS_req = Optimiser::concatenate_fs(req->FS_req, with->FS_req);
	req->FW_req = Optimiser::concatenate_fw(req->FW_req, with->FW_req);
}

@ The strong requirements are well-defined. Suppose all of the bits of |m1|
are found in X, and all of the bits of |m2| are found in Y. Then clearly
all of the bits in the union of these two sets are found in XY, and that's
the strongest requirement we can make. So:

=
int Optimiser::concatenate_ds(int m1, int m2) {
	return m1 | m2;
}

@ Similarly, suppose all of the bits of |m1| are found in every word of X,
and all of those of |m2| are in every word of Y. The most which can be said
about every word of XY is to take the intersection, so:

=
int Optimiser::concatenate_cs(int m1, int m2) {
	return m1 & m2;
}

@ Now suppose that at least one bit of |m1| can be found in X, and one bit
of |m2| can be found in Y. This gives us two pieces of information about
XY, and we can freely choose which to go for: we may as well pick |m1| and
say that one bit of |m1| can be found in XY. In principle we ought to choose
the rarest for best effect, but that's too much work.

=
int Optimiser::concatenate_dw(int m1, int m2) {
	if (m1 == 0) return m2; /* the case where we have no information about X */
	if (m2 == 0) return m1; /* and about Y */
	return m1; /* the general case discussed above */
}

@ Now suppose that each word of X matches at least one bit of |m1|, and
similarly for Y and |m2|. Then each word of XY matches at least one bit of
the union, so:

=
int Optimiser::concatenate_cw(int m1, int m2) {
	if (m1 == 0) return 0; /* the case where we have no information about X */
	if (m2 == 0) return 0; /* and about Y */
	return m1 | m2; /* the general case discussed above */
}

@ The first word of XY is the first word of X, so:

=
int Optimiser::concatenate_fs(int m1, int m2) {
	return m1;
}

int Optimiser::concatenate_fw(int m1, int m2) {
	return m1;
}

@ The second operation is disjunction: we'll write X/Y, meaning that the text
has to match either X or Y. This is easier, since it amounts to a disguised
form of de Morgan's laws.

=
void Optimiser::disjoin_rreq(range_requirement *req, range_requirement *with) {
	req->DS_req = Optimiser::disjoin_ds(req->DS_req, with->DS_req);
	req->DW_req = Optimiser::disjoin_dw(req->DW_req, with->DW_req);
	req->CS_req = Optimiser::disjoin_cs(req->CS_req, with->CS_req);
	req->CW_req = Optimiser::disjoin_cw(req->CW_req, with->CW_req);
	req->FS_req = Optimiser::disjoin_fs(req->FS_req, with->FS_req);
	req->FW_req = Optimiser::disjoin_fw(req->FW_req, with->FW_req);
}

@ Suppose all of the bits of |m1| are found in X, and all of the bits of |m2|
are found in Y. Then the best we can say is that all of the bits in the
intersection of these two sets are found in X/Y. (If they have no bits in
common, we can't say anything.)

=
int Optimiser::disjoin_ds(int m1, int m2) {
	return m1 & m2;
}

@ Similarly, suppose all of the bits of |m1| are found in every word of X,
and all of those of |m2| are in every word of Y. The most which can be said
about every word of XY is to take the intersection, so:

=
int Optimiser::disjoin_cs(int m1, int m2) {
	return m1 & m2;
}

@ Now suppose that at least one bit of |m1| can be found in X, and one bit
of |m2| can be found in Y. All we can say is that one of these various bits
must be found in X/Y, so:

=
int Optimiser::disjoin_dw(int m1, int m2) {
	if (m1 == 0) return 0; /* the case where we have no information about X */
	if (m2 == 0) return 0; /* and about Y */
	return m1 | m2; /* the general case discussed above */
}

@ And exactly the same is true for conjunctions:

=
int Optimiser::disjoin_cw(int m1, int m2) {
	if (m1 == 0) return 0; /* the case where we have no information about X */
	if (m2 == 0) return 0; /* and about Y */
	return m1 | m2; /* the general case discussed above */
}

int Optimiser::disjoin_fw(int m1, int m2) {
	return Optimiser::disjoin_cw(m1, m2);
}

int Optimiser::disjoin_fs(int m1, int m2) {
	return Optimiser::disjoin_cs(m1, m2);
}

void Optimiser::clear_rreq(range_requirement *req) {
	req->DS_req = 0; req->DW_req = 0;
	req->CS_req = 0; req->CW_req = 0;
	req->FS_req = 0; req->FW_req = 0;
}

void Optimiser::atomic_rreq(range_requirement *req, nonterminal *nt) {
	int b = Optimiser::nt_bitmap_bit(nt);
	req->DS_req = b; req->DW_req = b;
	req->CS_req = b; req->CW_req = b;
	req->FS_req = 0; req->FW_req = 0;
}

void Optimiser::log_range_requirement(range_requirement *req) {
	if (req->DW_req) { LOG(" DW: %08x", req->DW_req); }
	if (req->DS_req) { LOG(" DS: %08x", req->DS_req); }
	if (req->CW_req) { LOG(" CW: %08x", req->CW_req); }
	if (req->CS_req) { LOG(" CS: %08x", req->CS_req); }
	if (req->FW_req) { LOG(" FW: %08x", req->FW_req); }
	if (req->FS_req) { LOG(" FS: %08x", req->FS_req); }
}

@ Now to define elasticity:

@d PTOKEN_ELASTIC -1

=
int Optimiser::ptoken_width(ptoken *pt) {
	int min, max;
	Optimiser::ptoken_extrema(pt, &min, &max);
	if (min != max) return PTOKEN_ELASTIC;
	return min;
}

@ An interesting point here is that the negation of a ptoken can in principle
have any length, except that we specified |^ example| to match only a single
word -- any word other than "example". So the extrema for |^ example| are
1 and 1, whereas for |^ <sample-nonterminal>| they would have to be 0 and
infinity.

=
void Optimiser::ptoken_extrema(ptoken *pt, int *min_t, int *max_t) {
	*min_t = 1; *max_t = 1;
	if (pt->negated_ptoken) {
		if (pt->ptoken_category != FIXED_WORD_PTC) { *min_t = 0; *max_t = INFINITE_WORD_COUNT; }
		return;
	}
	switch (pt->ptoken_category) {
		case NONTERMINAL_PTC:
			Optimiser::optimise_nt(pt->nt_pt); /* recurse as needed to find its extrema */
			*min_t = pt->nt_pt->opt.min_nt_words;
			*max_t = pt->nt_pt->opt.max_nt_words;
			break;
		case MULTIPLE_WILDCARD_PTC:
			*max_t = INFINITE_WORD_COUNT;
			break;
		case POSSIBLY_EMPTY_WILDCARD_PTC:
			*min_t = 0;
			*max_t = INFINITE_WORD_COUNT;
			break;
	}
}

@h Flagging and numbering.
The following is called when a word |ve| is read as part of a production
with match number |pc| for the nonterminal |nt|:

=
void Optimiser::flag_words(vocabulary_entry *ve, nonterminal *nt, int pc) {
	ve->flags |= (nt->opt.flag_words_in_production);
	if (nt->opt.number_words_by_production) ve->literal_number_value = pc;
}

