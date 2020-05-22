[Optimiser::] The Optimiser.

To precalculate data which enables rapid parsing of source text against a
Preform grammar.

@h Nonterminal optimisation data.
Nonterminals, productions and even ptokens all have packets of precalculated
optimisation data attached.

To begin with, NTs. |nt_ntic| is the "NTI constraint", imposing conditions
which any matching range of words must conform to: see //Nonterminal Incidences//.

=
typedef struct nonterminal_optimisation_data {
	int optimised_in_this_pass; /* have the following been worked out yet? */
	struct length_extremes nt_extremes; /* for any wording matching this */
	int nt_incidence_bit;
	struct nti_constraint nt_ntic;
} nonterminal_optimisation_data;

@ =
void Optimiser::initialise_nonterminal_data(nonterminal_optimisation_data *opt) {
	opt->optimised_in_this_pass = FALSE;
	opt->nt_extremes = LengthExtremes::at_least_one_word();
	opt->nt_incidence_bit = -1; /* meaning "not yet allocated" */
	opt->nt_ntic = NTI::unconstrained();
}

@h Production optimisation data.
Like nonterminals, productions have minimum and maximum word counts, and an
NTI constraint:

=
typedef struct production_optimisation_data {
	struct length_extremes pr_extremes; /* for any wording matching this */
	struct nti_constraint pr_ntic;
	int no_struts;
	struct ptoken *struts[MAX_STRUTS_PER_PRODUCTION]; /* first ptoken in strut */
	int strut_lengths[MAX_STRUTS_PER_PRODUCTION]; /* length of the strut in words */
} production_optimisation_data;

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
middle of the text. The ptokens for such words have position set to 0. A run
of these ptokens, not counting wildcards like |...|, is called a "strut":
here, then, |but not| is a strut. We can think of it as a partition which
can slide backwards and forwards. This strut has length 2, not because it
contains two ptokens, but because it is always two words wide.

=
void Optimiser::initialise_production_data(production_optimisation_data *opt) {
	opt->no_struts = 0;
	opt->pr_extremes = LengthExtremes::at_least_one_word();
	opt->pr_ntic = NTI::unconstrained();
}

@h Ptoken optimisation data.
A ptoken is marked with its position relative to the range matching its
production (see above for positions); with the number of the strut it belongs
to, if it does; and with a |ptoken_is_fast| flag, which is set if the token is
a single fixed word at a known position which is not an endpoint of a bracing.
That sounds a tall order, but in practice many ptokens are indeed fast.

=
typedef struct ptoken_optimisation_data {
	int ptoken_position; /* fixed position in range: 1, 2, ... for left, -1, -2, ... for right */
	int strut_number; /* if this is part of a strut, what number? or -1 if not */
	int ptoken_is_fast; /* can be checked in the fast pass of the parser */
} ptoken_optimisation_data;

@ =
void Optimiser::initialise_ptoken_data(ptoken_optimisation_data *opt) {
	opt->ptoken_position = 0;
	opt->strut_number = -1;
	opt->ptoken_is_fast = FALSE;
}

@h Optimising nonterminals.
That's enough groundwork laid: we now have to calculate all of these NTIs
and range requirements. The process will have to repeated if there are ever
extra Preform nonterminals created, because new grammar throws off the old
results. So the following may in principle be called multiple times.

Two callback functions have a one-time opportunity to tweak the process.

=
void Optimiser::optimise_counts(void) {
	nonterminal *nt;
	LOOP_OVER(nt, nonterminal) Optimiser::clear_requirement_and_extremes(nt);
	NTI::ask_parent_to_add_constraints();
	LOOP_OVER(nt, nonterminal) Optimiser::optimise_nonterminal(nt);
	LOOP_OVER(nt, nonterminal) NTI::simplify_nt(nt);
}

void Optimiser::clear_requirement_and_extremes(nonterminal *nt) {
	nt->opt.nt_ntic = NTI::unconstrained();
	if (nt->marked_internal) {
		nt->opt.optimised_in_this_pass = TRUE;
	} else {
		nt->opt.optimised_in_this_pass = FALSE;
		nt->opt.nt_extremes = LengthExtremes::at_least_one_word();
	}
}

@ Although it's not obvious from here, the following function is recursive,
because it calls //NTI::calculate_constraint//, and that in turn needs all the
nonterminals in the grammar for |nt| to have been optimised already -- to
ensure which, it calls //Optimiser::optimise_nonterminal//. A similar thing
also happens in //LengthExtremes::calculate_for_nt//.

Since we cannot rely on grammar to be well-founded, we rig the function to
ensure that a second call to it on the same nonterminal returns immediately;
there are only finitely many NTs and hangs are therefore impossible.

=
void Optimiser::optimise_nonterminal(nonterminal *nt) {
	if (nt->opt.optimised_in_this_pass) return;
	nt->opt.optimised_in_this_pass = TRUE;

	nt->opt.nt_extremes = LengthExtremes::calculate_for_nt(nt);
	for (production_list *pl = nt->first_pl; pl; pl = pl->next_pl)
		for (production *pr = pl->first_pr; pr; pr = pr->next_pr)
			Optimiser::optimise_production(pr);
	NTI::calculate_constraint(nt);
}


void Optimiser::optimise_production(production *pr) {
	ptoken *last = NULL; /* this will point to the last ptoken in the production */
	@<Compute front-end ptoken positions@>;
	@<Compute back-end ptoken positions@>;
	@<Compute struts within the production@>;
	@<Work out which ptokens are fast@>;
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
	for (pt = pr->first_pt; pt; pt = pt->next_pt) {
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
		for (prevt = pr->first_pt; prevt; prevt = prevt->next_pt)
			if (prevt->next_pt == pt)
				break;
		pt = prevt;
	}

@ So, then, a strut is a maximal sequence of one or more inelastic ptokens
each of which has no known position. (Clearly if one of them has a known
position then all of them have, but we're in no hurry so we don't exploit that.)

@<Compute struts within the production@> =
	pr->opt.no_struts = 0;
	ptoken *pt;
	for (pt = pr->first_pt; pt; pt = pt->next_pt) {
		if ((pt->opt.ptoken_position == 0) &&
			(Optimiser::ptoken_width(pt) != PTOKEN_ELASTIC)) {
			if (pr->opt.no_struts >= MAX_STRUTS_PER_PRODUCTION) continue;
			pr->opt.struts[pr->opt.no_struts] = pt;
			pr->opt.strut_lengths[pr->opt.no_struts] = 0;
			while ((pt->opt.ptoken_position == 0) &&
				(Optimiser::ptoken_width(pt) != PTOKEN_ELASTIC)) {
				pt->opt.strut_number = pr->opt.no_struts;
				pr->opt.strut_lengths[pr->opt.no_struts] += Optimiser::ptoken_width(pt);
				if (pt->next_pt == NULL) break; /* should be impossible */
				pt = pt->next_pt;
			}
			pr->opt.no_struts++;
		}
	}

@<Work out which ptokens are fast@> =
	ptoken *pt;
	for (pt = pr->first_pt; pt; pt = pt->next_pt)
		if ((pt->ptoken_category == FIXED_WORD_PTC) && (pt->opt.ptoken_position != 0)
			&& (pt->range_starts < 0) && (pt->range_ends < 0))
			pt->opt.ptoken_is_fast = TRUE;

@h Width and elasticity.
If the min and max are the same, that's the width of the ptoken, and if not
then it is said to be "elastic" and has no width as such.

@d PTOKEN_ELASTIC -1

=
int Optimiser::ptoken_width(ptoken *pt) {
	length_extremes E = LengthExtremes::calculate_for_pt(pt);
	if (E.min_words != E.max_words) return PTOKEN_ELASTIC;
	return E.min_words;
}
