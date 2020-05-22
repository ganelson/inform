[NTI::] Nonterminal Incidences.

To work out bitmaps of nonterminal incidences in grammar.

@h Introduction.
The "nonterminal incidences" system provides one of two optimisations enabling
the Preform parser quickly to reject non-matches, the other being
//Length Extremes//, which is easier to understand.

It may elucidate both to see the actual optimisation data for nonterminals
as used in a typical run of Inform 7 -- see //inform7: Performance Metrics//.

@h Incidence bits.
Each NT is assigned an "incidence bit", but this is generated on demand;
|nt_incidence_bit| is -1 until it is allocated, and is otherwise an integer in
which only one bit is set, and always in the lowest 32 bits (since we won't
assume integers are any larger than that).

The lowest 6 bits are reserved -- see //NTI::give_nt_reserved_incidence_bit//
below -- but bits 7 to 32 are free, and the following function cycles through
those 26 possibilities. Those 26 don't have any semantic significance; they
simply divide up the nonterminals into 26 different bins of roughly equal
sizes, in the same sort of way that keys are divided up in hash tables.

@d RESERVED_NT_BITS 6

=
int no_req_bits = 0;
int NTI::nt_incidence_bit(nonterminal *nt) {
	if (nt->opt.nt_incidence_bit == -1) {
		int b = RESERVED_NT_BITS + ((no_req_bits++)%(32-RESERVED_NT_BITS));
		nt->opt.nt_incidence_bit = (1 << b);
	}
	return nt->opt.nt_incidence_bit;
}

@h The NTI of a word.
The vocabulary system provides an integer called the "nonterminal incidence",
or NTI, attached to each different word in our vocabulary. We can read this
with //Vocabulary::get_nti// and write it with //Vocabulary::set_nti//; if
we don't, it remains 0.

The NTI for a word will be a bitmap of the incidence bits for each NT whose
grammar includes that word.

So, for example, if the word "plus" appears in the grammar defining
<edwardian-trousers> and <arithmetic-operation>, but no others, then
its NTI would be the incidence bit for <edwardian-trousers> together
with that for <arithmetic-operation>.

To build that, we'll use the following:

=
void NTI::mark_vocabulary(vocabulary_entry *ve, nonterminal *nt) {
	int R = Vocabulary::get_nti(ve);
	R |= (NTI::nt_incidence_bit(nt));
	Vocabulary::set_nti(ve, R);
}

int NTI::test_vocabulary(vocabulary_entry *ve, nonterminal *nt) {
	int R = Vocabulary::get_nti(ve);
	if (R & (NTI::nt_incidence_bit(nt))) return TRUE;
	return FALSE;
}

@ Versions for words identified by their position in the lexer stream:

=
void NTI::mark_word(int wn, nonterminal *nt) {
	NTI::mark_vocabulary(Lexer::word(wn), nt);
}

int NTI::test_word(int wn, nonterminal *nt) {
	return NTI::test_vocabulary(Lexer::word(wn), nt);
}

@ It turns out to be fast to take a wording and to logical-or ("disjoin")
or logical-and ("conjoin") their NTI bitmaps together:

=
int NTI::get_range_disjunction(wording W) {
	int R = 0;
	LOOP_THROUGH_WORDING(i, W)
		R |= Vocabulary::get_nti(Lexer::word(i));
	return R;
}

int NTI::get_range_conjunction(wording W) {
	int R = 0;
	LOOP_THROUGH_WORDING(i, W) {
		if (i == Wordings::first_wn(W)) R = Vocabulary::get_nti(Lexer::word(i));
		else R &= Vocabulary::get_nti(Lexer::word(i));
	}
	return R;
}

@h Range requirements.
The NTI bitmaps for words are not easy to put together, but provided this
can be done correctly then we can benefit from systematic criteria to reject
doomed matches quickly when parsing. For example, suppose we have grammar:
= (text as Preform)
	<recipe> ::=
	    pan-fried <fish> |
	    <fish> veronique |
	    battered <fish>
=
and we are trying to match the text "galvanised zinc". The Optimiser has
already determined that the word "galvanised" is not used anywhere in the
grammar for <fish>, and similarly the word "zinc" -- so neither word has
the incidence bit for <fish> in its NTI. But the Optimiser can also see that
each of the three productions involves <fish> somewhere -- not always in
the same position, but somewhere. It therefore knows that for a wording to
match, one of the words must have the <fish> incidence bit. And since
neither "galvanised" nor "zinc" have it, the wording "galvanised zinc"
cannot be a match.

@ That example was contrived, but when this idea is taken further in a
more systematic way it produces very large speed gains, because it allows
a few fast bitwise operations to avoid the need for slow parsing processes
to reach an inevitably doomed conclusion.

The above idea can be applied equally well to matching text against a
nonterminal, production or ptoken, so all three have a //nti_constraint//
object. A NTIC encodes six rules, applying to a word range in three ways:

(a) D for "disjunction", or logical or. One of the words must satisfy this.
(b) C for "conjunction", or logical and. All of the words must satisfy this.
(c) F for "first". The first word must satisfy this.

And a rule can apply to the NTI bits in two ways:

(i) W for "weak". A word passes if it has one of these NTI bits.
(ii) S for "strong". A word passes if it has all of these NTI bits.

That makes six combinations in all: DW, DS, CW, CS, FW, and FS.

For example, suppose a NTIC has |DS_req| set to |0x280| -- i.e., to a bitmap
in which bits 7 and 9 are set (counting upwards from 0). This is then saying
that a word range such as "sense and prejudice" can only be a match if one
of the three words "sense", "and" or "prejudice" has both bits 7 and 9 set.

=
typedef struct nti_constraint {
	int there_are_no_requirements; /* if set, ignore all six bitmaps */
	int DW_req; /* one of the words has one of these bits */
	int DS_req; /* one of the words has all of these bits */
	int CW_req; /* all of the words have one of these bits */
	int CS_req; /* all of the words have all of these bits */
	int FW_req; /* the first word has one of these bits */
	int FS_req; /* the first word has all of these bits */
	int ditto_flag; /* this production has the same constraint as the previous one */
} nti_constraint;

@ And the following applies the NTIC test. Speed is critical here: we perform
only those tests which can have any effect, where the bitmap is non-zero. Note
that a return value of |TRUE| means that the wording does not match.

=
int NTI::nt_bitmap_violates(wording W, nti_constraint *ntic) {
	if (ntic->there_are_no_requirements) return FALSE;
	if (Wordings::length(W) == 1) @<Perform C, D and F tests on a single word@>
	else {
		int C_set = ((ntic->CS_req) | (ntic->CW_req));
		int D_set = ((ntic->DS_req) | (ntic->DW_req));
		int F_set = ((ntic->FS_req) | (ntic->FW_req));
		if ((C_set) && (D_set)) @<Perform C, D and F tests@>
		else if (C_set) @<Perform C and F tests@>
		else if (D_set) @<Perform D and F tests@>
		else if (F_set) @<Perform F test@>;
	}
	return FALSE;
}

@<Perform C, D and F tests on a single word@> =
	int bm = Vocabulary::get_nti(Lexer::word(Wordings::first_wn(W)));
	if (((bm) & (ntic->FS_req)) != (ntic->FS_req)) return TRUE;
	if ((((bm) & (ntic->FW_req)) == 0) && (ntic->FW_req)) return TRUE;
	if (((bm) & (ntic->DS_req)) != (ntic->DS_req)) return TRUE;
	if ((((bm) & (ntic->DW_req)) == 0) && (ntic->DW_req)) return TRUE;
	if (((bm) & (ntic->CS_req)) != (ntic->CS_req)) return TRUE;
	if ((((bm) & (ntic->CW_req)) == 0) && (ntic->CW_req)) return TRUE;

@<Perform C, D and F tests@> =
	int disj = 0;
	LOOP_THROUGH_WORDING(i, W) {
		int bm = Vocabulary::get_nti(Lexer::word(i));
		disj |= bm;
		if (((bm) & (ntic->CS_req)) != (ntic->CS_req)) return TRUE;
		if ((((bm) & (ntic->CW_req)) == 0) && (ntic->CW_req)) return TRUE;
		if ((i == Wordings::first_wn(W)) && (F_set)) {
			if (((bm) & (ntic->FS_req)) != (ntic->FS_req)) return TRUE;
			if ((((bm) & (ntic->FW_req)) == 0) && (ntic->FW_req)) return TRUE;
		}
	}
	if (((disj) & (ntic->DS_req)) != (ntic->DS_req)) return TRUE;
	if ((((disj) & (ntic->DW_req)) == 0) && (ntic->DW_req)) return TRUE;

@<Perform C and F tests@> =
	LOOP_THROUGH_WORDING(i, W) {
		int bm = Vocabulary::get_nti(Lexer::word(i));
		if (((bm) & (ntic->CS_req)) != (ntic->CS_req)) return TRUE;
		if ((((bm) & (ntic->CW_req)) == 0) && (ntic->CW_req)) return TRUE;
		if ((i == Wordings::first_wn(W)) && (F_set)) {
			if (((bm) & (ntic->FS_req)) != (ntic->FS_req)) return TRUE;
			if ((((bm) & (ntic->FW_req)) == 0) && (ntic->FW_req)) return TRUE;
		}
	}

@<Perform D and F tests@> =
	int disj = 0;
	LOOP_THROUGH_WORDING(i, W) {
		int bm = Vocabulary::get_nti(Lexer::word(i));
		disj |= bm;
		if ((i == Wordings::first_wn(W)) && (F_set)) {
			if (((bm) & (ntic->FS_req)) != (ntic->FS_req)) return TRUE;
			if ((((bm) & (ntic->FW_req)) == 0) && (ntic->FW_req)) return TRUE;
		}
	}
	if (((disj) & (ntic->DS_req)) != (ntic->DS_req)) return TRUE;
	if ((((disj) & (ntic->DW_req)) == 0) && (ntic->DW_req)) return TRUE;

@<Perform F test@> =
	int bm = Vocabulary::get_nti(Lexer::word(Wordings::first_wn(W)));
	if (((bm) & (ntic->FS_req)) != (ntic->FS_req)) return TRUE;
	if ((((bm) & (ntic->FW_req)) == 0) && (ntic->FW_req)) return TRUE;

@h Basic range requirements.
Determining the NTIC for a given nonterminal, production or ptoken involves
some work, and we build them iteratively, starting from something simple.
This NTIC means "no restriction":

=
nti_constraint NTI::unconstrained(void) {
	nti_constraint ntic;
	ntic.there_are_no_requirements = FALSE;
	ntic.ditto_flag = FALSE;
	ntic.DS_req = 0; ntic.DW_req = 0;
	ntic.CS_req = 0; ntic.CW_req = 0;
	ntic.FS_req = 0; ntic.FW_req = 0;
	return ntic;
}

@ And this "atomic" NTIC expresses the idea that every word must be flagged
with the incidence bit for a specific NT:

=
nti_constraint NTI::each_word_must_have(nonterminal *nt) {
	nti_constraint ntic;
	ntic.there_are_no_requirements = FALSE;
	ntic.ditto_flag = FALSE;
	int b = NTI::nt_incidence_bit(nt);
	ntic.DS_req = b; ntic.DW_req = b;
	ntic.CS_req = b; ntic.CW_req = b;
	ntic.FS_req = 0; ntic.FW_req = 0;
	return ntic;
}

@h Concatenation of range requirements.
Suppose we are going to match some words X, then some more words Y.
The X words have to satisfy |X_ntic| and the Y words |Y_ntic|. The following
function alters |X_ntic| so that it is now a requirement for "match X and
then Y", or XY for short.

=
void NTI::concatenate_rreq(nti_constraint *X_ntic, nti_constraint *Y_ntic) {
	X_ntic->DS_req = NTI::concatenate_ds(X_ntic->DS_req, Y_ntic->DS_req);
	X_ntic->DW_req = NTI::concatenate_dw(X_ntic->DW_req, Y_ntic->DW_req);
	X_ntic->CS_req = NTI::concatenate_cs(X_ntic->CS_req, Y_ntic->CS_req);
	X_ntic->CW_req = NTI::concatenate_cw(X_ntic->CW_req, Y_ntic->CW_req);
	X_ntic->FS_req = NTI::concatenate_fs(X_ntic->FS_req, Y_ntic->FS_req);
	X_ntic->FW_req = NTI::concatenate_fw(X_ntic->FW_req, Y_ntic->FW_req);
}

@ The strong requirements are well-defined. Suppose all of the bits of |m1|
are found in X, and all of the bits of |m2| are found in Y. Then clearly
all of the bits in the union of these two sets are found in XY, and that's
the strongest requirement we can make. So:

=
int NTI::concatenate_ds(int m1, int m2) {
	return m1 | m2;
}

@ Similarly, suppose all of the bits of |m1| are found in every word of X,
and all of those of |m2| are in every word of Y. The most which can be said
about every word of XY is to take the intersection, so:

=
int NTI::concatenate_cs(int m1, int m2) {
	return m1 & m2;
}

@ Now suppose that at least one bit of |m1| can be found in X, and one bit
of |m2| can be found in Y. This gives us two pieces of information about
XY, and we can freely choose which to go for: we may as well pick |m1| and
say that one bit of |m1| can be found in XY. In principle we ought to choose
the rarest for best effect, but that's too much work.

=
int NTI::concatenate_dw(int m1, int m2) {
	if (m1 == 0) return m2; /* the case where we have no information about X */
	if (m2 == 0) return m1; /* and about Y */
	return m1; /* the general case discussed above */
}

@ Now suppose that each word of X matches at least one bit of |m1|, and
similarly for Y and |m2|. Then each word of XY matches at least one bit of
the union, so:

=
int NTI::concatenate_cw(int m1, int m2) {
	if (m1 == 0) return 0; /* the case where we have no information about X */
	if (m2 == 0) return 0; /* and about Y */
	return m1 | m2; /* the general case discussed above */
}

@ The first word of XY is the first word of X, so these are much easier:

=
int NTI::concatenate_fs(int m1, int m2) {
	return m1;
}

int NTI::concatenate_fw(int m1, int m2) {
	return m1;
}

@h Disjunction of range requirements.
The second operation is disjunction. Again we have words X with requirement
|X_ntic| and Y with |Y_ntic|, but this time we want to change |X_ntic| so that
it is the requirement for "match either X or Y", or X/Y for short.

This amounts to a disguised form of de Morgan's laws.

=
void NTI::disjoin_rreq(nti_constraint *X_ntic, nti_constraint *Y_ntic) {
	X_ntic->DS_req = NTI::disjoin_ds(X_ntic->DS_req, Y_ntic->DS_req);
	X_ntic->DW_req = NTI::disjoin_dw(X_ntic->DW_req, Y_ntic->DW_req);
	X_ntic->CS_req = NTI::disjoin_cs(X_ntic->CS_req, Y_ntic->CS_req);
	X_ntic->CW_req = NTI::disjoin_cw(X_ntic->CW_req, Y_ntic->CW_req);
	X_ntic->FS_req = NTI::disjoin_fs(X_ntic->FS_req, Y_ntic->FS_req);
	X_ntic->FW_req = NTI::disjoin_fw(X_ntic->FW_req, Y_ntic->FW_req);
}

@ Suppose all of the bits of |m1| are found in X, and all of the bits of |m2|
are found in Y. Then the best we can say is that all of the bits in the
intersection of these two sets are found in X/Y. (If they have no bits in
common, we can't say anything.)

=
int NTI::disjoin_ds(int m1, int m2) {
	return m1 & m2;
}

@ Similarly, suppose all of the bits of |m1| are found in every word of X,
and all of those of |m2| are in every word of Y. The most which can be said
about every word of XY is to take the intersection, so:

=
int NTI::disjoin_cs(int m1, int m2) {
	return m1 & m2;
}

@ Now suppose that at least one bit of |m1| can be found in X, and one bit
of |m2| can be found in Y. All we can say is that one of these various bits
must be found in X/Y, so:

=
int NTI::disjoin_dw(int m1, int m2) {
	if (m1 == 0) return 0; /* the case where we have no information about X */
	if (m2 == 0) return 0; /* and about Y */
	return m1 | m2; /* the general case discussed above */
}

@ And exactly the same is true for conjunctions:

=
int NTI::disjoin_cw(int m1, int m2) {
	if (m1 == 0) return 0; /* the case where we have no information about X */
	if (m2 == 0) return 0; /* and about Y */
	return m1 | m2; /* the general case discussed above */
}

int NTI::disjoin_fw(int m1, int m2) {
	return NTI::disjoin_cw(m1, m2);
}

int NTI::disjoin_fs(int m1, int m2) {
	return NTI::disjoin_cs(m1, m2);
}

@h Range requirement simplification.
Once the bitmaps in all the necessary requirements have been made, the following
is used to simplify them -- paring down any logical redundancy in them, so
that the simplest possible tests will be applied by //NTI::nt_bitmap_violates//.

=
void NTI::simplify_requirement(nti_constraint *ntic) {
	@<Remove a disjunction test contained in a first-word test@>;
	@<Remove a first-word test contained in a conjunction test@>;
	@<Remove a disjunction test contained in a conjunction test@>;
	@<Remove any weak test which partially duplicates a strong one@>;

	ntic->ditto_flag = FALSE;
	ntic->there_are_no_requirements = TRUE;
	if ((ntic->DS_req) || (ntic->DW_req) || (ntic->CS_req) ||
		(ntic->CW_req) || (ntic->FS_req) || (ntic->FW_req))
		ntic->there_are_no_requirements = FALSE;
}

@ Suppose the NTIC says "one of these words has to have bit X", a disjunction
test, but also "the first word has to have bit X", a first word text. Then we
can get rid of the disjunction test -- it is implied by the first word text,
and is both slower and weaker.

@<Remove a disjunction test contained in a first-word test@> =
	if ((ntic->DS_req & ntic->FS_req) == ntic->DS_req) ntic->DS_req = 0;
	if ((ntic->DW_req & ntic->FW_req) == ntic->DW_req) ntic->DW_req = 0;

@ Suppose the NTIC says "every word has to have X" but also "the first word
has to have X". Then we get rid of the first word test, which is implied
and is weaker.

@<Remove a first-word test contained in a conjunction test@> =
	if ((ntic->CS_req & ntic->FS_req) == ntic->FS_req) ntic->FS_req = 0;
	if ((ntic->CW_req & ntic->FW_req) == ntic->FW_req) ntic->FW_req = 0;

@ Now suppose we have both "one of these words has to have X" and also
"all of these words have to have X". We get rid of the "some of" test.

@<Remove a disjunction test contained in a conjunction test@> =
	if ((ntic->CS_req & ntic->DS_req) == ntic->DS_req) ntic->DS_req = 0;
	if ((ntic->CW_req & ntic->DW_req) == ntic->DW_req) ntic->DW_req = 0;

@ Finally suppose we have "a word must have some bits from set A" and
also "a word must have all of the bits from set B", where B is a superset
of A. Then the first, weak, test can go, since it is implied by the strong one.

@<Remove any weak test which partially duplicates a strong one@> =
	if ((ntic->FW_req & ntic->FS_req) == ntic->FW_req) ntic->FW_req = 0;
	if ((ntic->DW_req & ntic->DS_req) == ntic->DW_req) ntic->DW_req = 0;
	if ((ntic->CW_req & ntic->CS_req) == ntic->CW_req) ntic->CW_req = 0;

@ The "ditto flag" on a requirement is used when there are two requirements,
here |prev| then |ntic|, representing alternatives for parsing the same text --
i.e., it must match either |prev| or |ntic|. If these two requirements are
the same, we needn't check the second one after the first has been checked.
So we give |ntic| the ditto flag, to say "same as the one before".

=
void NTI::simplify_pair(nti_constraint *ntic, nti_constraint *prev) {
	NTI::simplify_requirement(ntic);
	if ((prev) &&
		(ntic->DS_req == prev->DS_req) && (ntic->DW_req == prev->DW_req) &&
		(ntic->CS_req == prev->CS_req) && (ntic->CW_req == prev->CW_req) &&
		(ntic->FS_req == prev->FS_req) && (ntic->FW_req == prev->FW_req))
		ntic->ditto_flag = TRUE;
}

@ Whence:

=
void NTI::simplify_nt(nonterminal *nt) {
	for (production_list *pl = nt->first_pl; pl; pl = pl->next_pl) {
		nti_constraint *prev_req = NULL;
		for (production *pr = pl->first_pr; pr; pr = pr->next_pr) {
			NTI::simplify_pair(&(pr->opt.pr_ntic), prev_req);
			prev_req = &(pr->opt.pr_ntic);
		}
	}
	NTI::simplify_requirement(&(nt->opt.nt_ntic));
}

@h Calculations.
We now have all the apparatus we need, so:

=
void NTI::calculate_constraint(nonterminal *nt) {
	@<Mark up fixed wording in the grammar for NT with the NT's incidence bit@>;
	@<Calculate requirement for NT@>;
}

@<Mark up fixed wording in the grammar for NT with the NT's incidence bit@> =
	for (production_list *pl = nt->first_pl; pl; pl = pl->next_pl)
		for (production *pr = pl->first_pr; pr; pr = pr->next_pr)
			for (ptoken *pt = pr->first_pt; pt; pt = pt->next_pt)
				if ((pt->ptoken_category == FIXED_WORD_PTC) && (pt->negated_ptoken == FALSE))
					for (ptoken *alt = pt; alt; alt = alt->alternative_ptoken)
						NTI::mark_vocabulary(alt->ve_pt, nt);

@ The requirement for a NT is a disjunction of the requirements for the productions.

@<Calculate requirement for NT@> =
	nti_constraint nnt = nt->opt.nt_ntic;
	int first_pr = TRUE;
	for (production_list *pl = nt->first_pl; pl; pl = pl->next_pl) {
		for (production *pr = pl->first_pr; pr; pr = pr->next_pr) {
			@<Calculate requirement for production@>;
			if (first_pr) nnt = pr->opt.pr_ntic;
			else NTI::disjoin_rreq(&nnt, &(pr->opt.pr_ntic));
			first_pr = FALSE;
		}
	}
	nt->opt.nt_ntic = nnt;

@ The requirement for a production is a concatenation of the requirements for the
ptokens.

@<Calculate requirement for production@> =
	nti_constraint prt = NTI::unconstrained();
	int first = TRUE;
	for (ptoken *pt = pr->first_pt; pt; pt = pt->next_pt) {
		int empty = FALSE;
		nti_constraint tok_ntic = NTI::unconstrained();
		@<Calculate requirement for ptoken@>;
		if (empty == FALSE) {
			if (first) prt = tok_ntic;
			else NTI::concatenate_rreq(&prt, &tok_ntic);
			first = FALSE;
		}
	}
	pr->opt.pr_ntic = prt;

@ We're down to atoms, now, and:
(a) We must ignore an empty ptoken, that is, one which matches text of width
0, as some positional internal NTs like <if-start-of-paragraph> do. Such a
ptoken can't constrain the wording of a match at all.
(b) For a ptoken which is a non-negated word, the NTIC is that the word
matching it has to have the current NT's bit. In other words, if |zephyr|
occurs in the grammar for the NT <wind>, then the atomic NTIC for this word
where it comes up is just a requirement that the word it matches against must
have the <wind> bit. (Which the word "zephyr" certainly does, because we
marked all the words in the <wind> grammar with the <wind> bit already.)
(c) For a ptoken which is a non-negated use of another NT, the constraint
is just the constraint of that NT.
(d) Nothing can be deduced from a negated ptoken: for example, all we know
about the ptoken |^mistral| is that it matches something which is not the
word "mistral", and that tells us nothing about the bits that it has.

@<Calculate requirement for ptoken@> =
	if ((pt->ptoken_category == NONTERMINAL_PTC) &&
		(pt->nt_pt->opt.nt_extremes.min_words == 0) && (pt->nt_pt->opt.nt_extremes.max_words == 0))
		empty = TRUE; /* even if negated, notice */
	if ((pt->ptoken_category == FIXED_WORD_PTC) && (pt->negated_ptoken == FALSE))
		tok_ntic = NTI::each_word_must_have(nt);
	if ((pt->ptoken_category == NONTERMINAL_PTC) && (pt->negated_ptoken == FALSE)) {
		Optimiser::optimise_nonterminal(pt->nt_pt);
		tok_ntic = pt->nt_pt->opt.nt_ntic;
	}

@h Customisation.
The above algorithm calculates sensible constraints for regular nonterminals,
but since it can't look inside the workings of internal nonterminals, those
currently have no constraints.

So the parent (i.e., the tool using //words//) may want to intervene. It does
that at two points:

(a) When it starts up, it can call //NTI::give_nt_reserved_incidence_bit// --
see below -- or //Nonterminals::make_numbering// or //Nonterminals::flag_words_with//.

(b) When //The Optimiser// runs, it calls two callback functions which have
a chance to add NTI constraints to nonterminals.

@ To take (a) first: as we've seen, each NT is assigned an NTI bit, handed
out more or less at random, dividing the stock of NTs into about 26 roughly
equal subsets. But it turns out to be efficient to fix the NTI bits for some
internal NTs so that they are in common: for example, in Inform, making sure
<definite-article> and <indefinite-article> have the same NTI bit as each
other means that a single bit means "an article".

This is what the six reserved bits are for: the parent can use these in any
way it pleases, of course, but the names are meant to be suggestive of some
basic linguistic categories.

@d CARDINAL_RES_NT_BIT 0
@d ORDINAL_RES_NT_BIT 1
@d ARTICLE_RES_NT_BIT 2
@d ADJECTIVE_RES_NT_BIT 3
@d PROPER_NOUN_RES_NT_BIT 4
@d COMMON_NOUN_RES_NT_BIT 5

=
void NTI::give_nt_reserved_incidence_bit(nonterminal *nt, int b) {
	if (nt == NULL) internal_error("null NT");
	if ((b < 0) || (b >= RESERVED_NT_BITS)) internal_error("assigned bad bit");
	nt->opt.nt_incidence_bit = (1 << b);
}

@ Now for opportunity (b). //words// provides for up to two callback functions
which have the opportunity to add constraints:

=
void NTI::ask_parent_to_add_constraints(void) {
	#ifdef PREFORM_OPTIMISER_WORDS_CALLBACK
	PREFORM_OPTIMISER_WORDS_CALLBACK();
	#endif
	#ifdef MORE_PREFORM_OPTIMISER_WORDS_CALLBACK
	MORE_PREFORM_OPTIMISER_WORDS_CALLBACK();
	#endif
}

@ Those callback functions, if supplied, should consist of calls to the
following functions.

=
void NTI::one_word_in_match_must_have_my_NTI_bit(nonterminal *nt) {
	nt->opt.nt_ntic.DS_req |= (NTI::nt_incidence_bit(nt));
}

void NTI::first_word_in_match_must_have_my_NTI_bit(nonterminal *nt) {
	nt->opt.nt_ntic.FS_req |= (NTI::nt_incidence_bit(nt));
}

void NTI::every_word_in_match_must_have_my_NTI_bit(nonterminal *nt) {
	nt->opt.nt_ntic.CS_req |= (NTI::nt_incidence_bit(nt));
}

void NTI::every_word_in_match_must_have_my_NTI_bit_or_this_one(nonterminal *nt, int x) {
	nt->opt.nt_ntic.CW_req |= (NTI::nt_incidence_bit(nt) + x);
}
