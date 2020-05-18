[Optimiser::] The Optimiser.

To precalculate data which enables rapid parsing of source text against a
Preform grammar.

@h Nonterminal optimisation data.
Nonterminals, productions and even ptokens all have packets of precalculated
optimisation data attached.

To begin with, NTs. |min_nt_words| and |max_nt_words| give the minimum and
maximum possible number of words in a matched text: with |INFINITE_WORD_COUNT|
as maximum where there is none. |nonterminal_req| is the "range requirement",
imposing conditions which any matching range of words must conform to: see below.

=
typedef struct nonterminal_optimisation_data {
	int optimised_in_this_pass; /* have the following been worked out yet? */
	int min_nt_words, max_nt_words; /* for speed */
	int nt_incidence_bit; /* which hashing category the words belong to, or $-1$ if none */
	int number_words_by_production; /* this parses names for numbers, like "huit" or "zwei" */
	unsigned int flag_words_in_production; /* all words in the production should get these flags */
	struct range_requirement nonterminal_req;
} nonterminal_optimisation_data;

@ =
void Optimiser::initialise_nonterminal_data(nonterminal_optimisation_data *opt) {
	opt->optimised_in_this_pass = FALSE;
	opt->min_nt_words = 1; opt->max_nt_words = INFINITE_WORD_COUNT;
	opt->nt_incidence_bit = -1;
	opt->number_words_by_production = FALSE;
	opt->flag_words_in_production = 0;
	Optimiser::clear_rreq(&(opt->nonterminal_req));
}

@ Each NT is assigned an "incidence bit", but this is generated on demand;
|nt_incidence_bit| is -1 until it is allocated, and is otherwise an integer in
which only one bit is set, and always in the lowest 32 bits (since we won't
assume integers are any larger than that).

The lowest 6 bits are reserved, but bits 7 to 32 are free, and the following
function cycles through those 26 possibilities. Those 26 don't have any
semantic significance; they simply divide up the nonterminals into 26 different
bins of roughly equal sizes, in the same sort of way that keys are divided up
in hash tables.

@d RESERVED_NT_BITS 6

=
int no_req_bits = 0;
int Optimiser::nt_incidence_bit(nonterminal *nt) {
	if (nt->opt.nt_incidence_bit == -1) {
		int b = RESERVED_NT_BITS + ((no_req_bits++)%(32-RESERVED_NT_BITS));
		nt->opt.nt_incidence_bit = (1 << b);
	}
	return nt->opt.nt_incidence_bit;
}

@ But it is also possible to force the choice to be one of the reserved ones:

=
void Optimiser::give_nt_reserved_incidence_bit(nonterminal *nt, int b) {
	if (nt == NULL) internal_error("null NT");
	if ((b < 0) || (b >= RESERVED_NT_BITS)) internal_error("assigned bad bit");
	nt->opt.nt_incidence_bit = (1 << b);
}

@h Production optimisation data.
Like nonterminals, productions have minimum and maximum word counts, and a
range requirement:

=
typedef struct production_optimisation_data {
	int min_pr_words, max_pr_words;
	struct range_requirement production_req;
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
	opt->min_pr_words = 1; opt->max_pr_words = INFINITE_WORD_COUNT;
	Optimiser::clear_rreq(&(opt->production_req));
}

@h Ptoken optimisation data.
A ptoken is marked with its position relative to the range matching its
production (see above for positions); with the number of the strut it belongs
to, if it does; with a range requirement; and with a |ptoken_is_fast| flag,
which is set if the token is a single fixed word at a known position which is
not an endpoint of a bracing. That sounds a tall order, but in practice many
ptokens are indeed fast.

=
typedef struct ptoken_optimisation_data {
	int ptoken_position; /* fixed position in range: 1, 2, ... for left, -1, -2, ... for right */
	int strut_number; /* if this is part of a strut, what number? or -1 if not */
	int ptoken_is_fast; /* can be checked in the fast pass of the parser */
	struct range_requirement token_req;
} ptoken_optimisation_data;

@ =
void Optimiser::initialise_ptoken_data(ptoken_optimisation_data *opt) {
	opt->ptoken_position = 0;
	opt->strut_number = -1;
	opt->ptoken_is_fast = FALSE;
	Optimiser::clear_rreq(&(opt->token_req));
}

@h The NTI of a word.
The vocabulary system provides an integer called the "nonterminal incidence",
or NTI, attached to each different word in our vocabulary. We can read this
with //Vocabulary::get_nti// and write it with //Vocabulary::set_nti//; if
we don't, it remains 0.

Recall that each NT has an "incidence bit". The NTI for a word will be a
bitmap of the incidence bits for each NT whose grammar includes that word.
So, for example, if the word "plus" appears in the grammar defining
<edwardian-trousers> and <arithmetic-operation>, but no others, then
its NTI would be the incidence bit for <edwardian-trousers> together
with that for <arithmetic-operation>.

To build that, we'll use the following:

=
void Optimiser::mark_vocabulary(vocabulary_entry *ve, nonterminal *nt) {
	int R = Vocabulary::get_nti(ve);
	R |= (Optimiser::nt_incidence_bit(nt));
	Vocabulary::set_nti(ve, R);
}

int Optimiser::test_vocabulary(vocabulary_entry *ve, nonterminal *nt) {
	int R = Vocabulary::get_nti(ve);
	if (R & (Optimiser::nt_incidence_bit(nt))) return TRUE;
	return FALSE;
}

@ Versions for words identified by their position in the lexer stream:

=
void Optimiser::mark_word(int wn, nonterminal *nt) {
	Optimiser::mark_vocabulary(Lexer::word(wn), nt);
}

int Optimiser::test_word(int wn, nonterminal *nt) {
	return Optimiser::test_vocabulary(Lexer::word(wn), nt);
}

@ It turns out to be fast to take a wording and to logical-or ("disjoin")
or logical-and ("conjoin") their NTI bitmaps together:

=
int Optimiser::get_range_disjunction(wording W) {
	int R = 0;
	LOOP_THROUGH_WORDING(i, W)
		R |= Vocabulary::get_nti(Lexer::word(i));
	return R;
}

int Optimiser::get_range_conjunction(wording W) {
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
nonterminal, production or ptoken, so all three have a //range_requirement//
object. A RREQ encodes six rules, applying to a word range in three ways:

(a) D for "disjunction", or logical or. One of the words must satisfy this.
(b) C for "conjunction", or logical and. All of the words must satisfy this.
(c) F for "first". The first word must satisfy this.

And a rule can apply to the NTI bits in two ways:

(i) W for "weak". A word passes if it has one of these NTI bits.
(ii) S for "strong". A word passes if it has all of these NTI bits.

That makes six combinations in all: DW, DS, CW, CS, FW, and FS.

For example, suppose a RREQ has |DS_req| set to |0x280| -- i.e., to a bitmap
in which bits 7 and 9 are set (counting upwards from 0). This is then saying
that a word range such as "sense and prejudice" can only be a match if one
of the three words "sense", "and" or "prejudice" has both bits 7 and 9 set.

=
typedef struct range_requirement {
	int there_are_no_requirements; /* if set, ignore the bitmaps */
	int DW_req; /* one of the words has one of these bits */
	int DS_req; /* one of the words has all of these bits */
	int CW_req; /* all of the words have one of these bits */
	int CS_req; /* all of the words have all of these bits */
	int FW_req; /* the first word has one of these bits */
	int FS_req; /* the first word has all of these bits */
	int ditto_flag;
} range_requirement;

@ And the following applies the RREQ test. Speed is critical here: we perform
only those tests which can have any effect, where the bitmap is non-zero. Note
that a return value of |TRUE| means that the wording does not match.

=
int Optimiser::nt_bitmap_violates(wording W, range_requirement *req) {
	if (req->there_are_no_requirements) return FALSE;
	if (Wordings::length(W) == 1) @<Perform C, D and F tests on a single word@>
	else {
		int C_set = ((req->CS_req) | (req->CW_req));
		int D_set = ((req->DS_req) | (req->DW_req));
		int F_set = ((req->FS_req) | (req->FW_req));
		if ((C_set) && (D_set)) @<Perform C, D and F tests@>
		else if (C_set) @<Perform C and F tests@>
		else if (D_set) @<Perform D and F tests@>
		else if (F_set) @<Perform F test@>;
	}
	return FALSE;
}

@<Perform C, D and F tests on a single word@> =
	int bm = Vocabulary::get_nti(Lexer::word(Wordings::first_wn(W)));
	if (((bm) & (req->FS_req)) != (req->FS_req)) return TRUE;
	if ((((bm) & (req->FW_req)) == 0) && (req->FW_req)) return TRUE;
	if (((bm) & (req->DS_req)) != (req->DS_req)) return TRUE;
	if ((((bm) & (req->DW_req)) == 0) && (req->DW_req)) return TRUE;
	if (((bm) & (req->CS_req)) != (req->CS_req)) return TRUE;
	if ((((bm) & (req->CW_req)) == 0) && (req->CW_req)) return TRUE;

@<Perform C, D and F tests@> =
	int disj = 0;
	LOOP_THROUGH_WORDING(i, W) {
		int bm = Vocabulary::get_nti(Lexer::word(i));
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

@<Perform C and F tests@> =
	LOOP_THROUGH_WORDING(i, W) {
		int bm = Vocabulary::get_nti(Lexer::word(i));
		if (((bm) & (req->CS_req)) != (req->CS_req)) return TRUE;
		if ((((bm) & (req->CW_req)) == 0) && (req->CW_req)) return TRUE;
		if ((i == Wordings::first_wn(W)) && (F_set)) {
			if (((bm) & (req->FS_req)) != (req->FS_req)) return TRUE;
			if ((((bm) & (req->FW_req)) == 0) && (req->FW_req)) return TRUE;
		}
	}

@<Perform D and F tests@> =
	int disj = 0;
	LOOP_THROUGH_WORDING(i, W) {
		int bm = Vocabulary::get_nti(Lexer::word(i));
		disj |= bm;
		if ((i == Wordings::first_wn(W)) && (F_set)) {
			if (((bm) & (req->FS_req)) != (req->FS_req)) return TRUE;
			if ((((bm) & (req->FW_req)) == 0) && (req->FW_req)) return TRUE;
		}
	}
	if (((disj) & (req->DS_req)) != (req->DS_req)) return TRUE;
	if ((((disj) & (req->DW_req)) == 0) && (req->DW_req)) return TRUE;

@<Perform F test@> =
	int bm = Vocabulary::get_nti(Lexer::word(Wordings::first_wn(W)));
	if (((bm) & (req->FS_req)) != (req->FS_req)) return TRUE;
	if ((((bm) & (req->FW_req)) == 0) && (req->FW_req)) return TRUE;

@ Logging:

=
void Optimiser::log_range_requirement(range_requirement *req) {
	if (req->DW_req) { LOG(" DW: %08x", req->DW_req); }
	if (req->DS_req) { LOG(" DS: %08x", req->DS_req); }
	if (req->CW_req) { LOG(" CW: %08x", req->CW_req); }
	if (req->CS_req) { LOG(" CS: %08x", req->CS_req); }
	if (req->FW_req) { LOG(" FW: %08x", req->FW_req); }
	if (req->FS_req) { LOG(" FS: %08x", req->FS_req); }
}

@h Basic range requirements.
Determining the RREQ for a given nonterminal, production or ptoken involves
some work, and we build them iteratively, starting from something simple.
This RREQ means "no restriction":

=
void Optimiser::clear_rreq(range_requirement *req) {
	req->DS_req = 0; req->DW_req = 0;
	req->CS_req = 0; req->CW_req = 0;
	req->FS_req = 0; req->FW_req = 0;
}

@ And this "atomic" RREQ expresses the idea that every word must be flagged
with the incidence bit for a specific NT:

=
void Optimiser::atomic_rreq(range_requirement *req, nonterminal *nt) {
	int b = Optimiser::nt_incidence_bit(nt);
	req->DS_req = b; req->DW_req = b;
	req->CS_req = b; req->CW_req = b;
	req->FS_req = 0; req->FW_req = 0;
}

@h Concatenation of range requirements.
Suppose we are going to match some words X, then some more words Y.
The X words have to satisfy |X_req| and the Y words |Y_req|. The following
function alters |X_req| so that it is now a requirement for "match X and
then Y", or XY for short.

=
void Optimiser::concatenate_rreq(range_requirement *X_req, range_requirement *Y_req) {
	X_req->DS_req = Optimiser::concatenate_ds(X_req->DS_req, Y_req->DS_req);
	X_req->DW_req = Optimiser::concatenate_dw(X_req->DW_req, Y_req->DW_req);
	X_req->CS_req = Optimiser::concatenate_cs(X_req->CS_req, Y_req->CS_req);
	X_req->CW_req = Optimiser::concatenate_cw(X_req->CW_req, Y_req->CW_req);
	X_req->FS_req = Optimiser::concatenate_fs(X_req->FS_req, Y_req->FS_req);
	X_req->FW_req = Optimiser::concatenate_fw(X_req->FW_req, Y_req->FW_req);
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

@ The first word of XY is the first word of X, so these are much easier:

=
int Optimiser::concatenate_fs(int m1, int m2) {
	return m1;
}

int Optimiser::concatenate_fw(int m1, int m2) {
	return m1;
}

@h Disjunction of range requirements.
The second operation is disjunction. Again we have words X with requirement
|X_req| and Y with |Y_req|, but this time we want to change |X_req| so that
it is the requirement for "match either X or Y", or X/Y for short.

This amounts to a disguised form of de Morgan's laws.

=
void Optimiser::disjoin_rreq(range_requirement *X_req, range_requirement *Y_req) {
	X_req->DS_req = Optimiser::disjoin_ds(X_req->DS_req, Y_req->DS_req);
	X_req->DW_req = Optimiser::disjoin_dw(X_req->DW_req, Y_req->DW_req);
	X_req->CS_req = Optimiser::disjoin_cs(X_req->CS_req, Y_req->CS_req);
	X_req->CW_req = Optimiser::disjoin_cw(X_req->CW_req, Y_req->CW_req);
	X_req->FS_req = Optimiser::disjoin_fs(X_req->FS_req, Y_req->FS_req);
	X_req->FW_req = Optimiser::disjoin_fw(X_req->FW_req, Y_req->FW_req);
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

@h Range requirement simplification.
Once the bitmaps in all the necessary requirements have been made, the following
is used to simplify them -- paring down any logical redundancy in them, so
that the simplest possible tests will be applied by //Optimiser::nt_bitmap_violates//.

=
void Optimiser::simplify_requirement(range_requirement *req) {
	@<Remove a disjunction test contained in a first-word test@>;
	@<Remove a first-word test contained in a conjunction test@>;
	@<Remove a disjunction test contained in a conjunction test@>;
	@<Remove any weak test which partially duplicates a strong one@>;

	req->there_are_no_requirements = TRUE;
	if ((req->DS_req) || (req->DW_req) || (req->CS_req) ||
		(req->CW_req) || (req->FS_req) || (req->FW_req))
		req->there_are_no_requirements = FALSE;
}

@ Suppose the RREQ says "one of these words has to have bit X", a disjunction
test, but also "the first word has to have bit X", a first word text. Then we
can get rid of the disjunction test -- it is implied by the first word text,
and is both slower and weaker.

@<Remove a disjunction test contained in a first-word test@> =
	if ((req->DS_req & req->FS_req) == req->DS_req) req->DS_req = 0;
	if ((req->DW_req & req->FW_req) == req->DW_req) req->DW_req = 0;

@ Suppose the RREQ says "every word has to have X" but also "the first word
has to have X". Then we get rid of the first word test, which is implied
and is weaker.

@<Remove a first-word test contained in a conjunction test@> =
	if ((req->CS_req & req->FS_req) == req->FS_req) req->FS_req = 0;
	if ((req->CW_req & req->FW_req) == req->FW_req) req->FW_req = 0;

@ Now suppose we have both "one of these words has to have X" and also
"all of these words have to have X". We get rid of the "some of" test.

@<Remove a disjunction test contained in a conjunction test@> =
	if ((req->CS_req & req->DS_req) == req->DS_req) req->DS_req = 0;
	if ((req->CW_req & req->DW_req) == req->DW_req) req->DW_req = 0;

@ Finally suppose we have "a word must have some bits from set A" and
also "a word must have all of the bits from set B", where B is a superset
of A. Then the first, weak, test can go, since it is implied by the strong one.

@<Remove any weak test which partially duplicates a strong one@> =
	if ((req->FW_req & req->FS_req) == req->FW_req) req->FW_req = 0;
	if ((req->DW_req & req->DS_req) == req->DW_req) req->DW_req = 0;
	if ((req->CW_req & req->CS_req) == req->CW_req) req->CW_req = 0;

@ The "ditto flag" on a requirement is used when there are two requirements,
here |prev| then |req|, representing alternatives for parsing the same text --
i.e., it must match either |prev| or |req|. If these two requirements are
the same, we needn't check the second one after the first has been checked.
So we give |req| the ditto flag, to say "same as the one before".

=
void Optimiser::simplify_pair(range_requirement *req, range_requirement *prev) {
	Optimiser::simplify_requirement(req);
	req->ditto_flag = FALSE;
	if ((prev) &&
		(req->DS_req == prev->DS_req) && (req->DW_req == prev->DW_req) &&
		(req->CS_req == prev->CS_req) && (req->CW_req == prev->CW_req) &&
		(req->FS_req == prev->FS_req) && (req->FW_req == prev->FW_req))
		req->ditto_flag = TRUE;
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
	LOOP_OVER(nt, nonterminal) Optimiser::clear_requirement_and_extrema(nt);
	Optimiser::ask_parent_to_tweak();
	LOOP_OVER(nt, nonterminal) Optimiser::find_requirement_and_extrema(nt);
	LOOP_OVER(nt, nonterminal) Optimiser::simplify_requirements(nt);
}

void Optimiser::clear_requirement_and_extrema(nonterminal *nt) {
	Optimiser::clear_rreq(&(nt->opt.nonterminal_req));
	if (nt->marked_internal) {
		nt->opt.optimised_in_this_pass = TRUE;
	} else {
		nt->opt.optimised_in_this_pass = FALSE;
		nt->opt.min_nt_words = 1; nt->opt.max_nt_words = INFINITE_WORD_COUNT;
	}
}

@ The following is recursively called: looking through the grammar for NT1,
if we find a token for grammar NT2, then we call this function to make sure
all calculations for that have been done. That mustn't loop, so we make sure
only a single call happens per pass.

=
void Optimiser::find_requirement_and_extrema(nonterminal *nt) {
	if (nt->opt.optimised_in_this_pass) return;
	nt->opt.optimised_in_this_pass = TRUE;
	Optimiser::find_extrema(nt);

	for (production_list *pl = nt->first_production_list; pl; pl = pl->next_production_list)
		for (production *pr = pl->first_production; pr; pr = pr->next_production)
			Optimiser::optimise_production(pr);

	Optimiser::find_requirement(nt);
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

@

=
void Optimiser::find_requirement(nonterminal *nt) {
	Optimiser::clear_rreq(&(nt->opt.nonterminal_req));
	#ifdef PREFORM_CIRCULARITY_BREAKER
	PREFORM_CIRCULARITY_BREAKER(nt);
	#endif

	@<Mark up fixed wording in the grammar for NT with the NT's incidence bit@>;

	nt->opt.nonterminal_req = Optimiser::find_requirement_for_nonterminal(nt);
	#ifdef PREFORM_CIRCULARITY_BREAKER
	PREFORM_CIRCULARITY_BREAKER(nt);
	#endif
}

@<Mark up fixed wording in the grammar for NT with the NT's incidence bit@> =
	for (production_list *pl = nt->first_production_list; pl; pl = pl->next_production_list)
		for (production *pr = pl->first_production; pr; pr = pr->next_production)
			for (ptoken *pt = pr->first_ptoken; pt; pt = pt->next_ptoken)
				if ((pt->ptoken_category == FIXED_WORD_PTC) && (pt->negated_ptoken == FALSE))
					for (ptoken *alt = pt; alt; alt = alt->alternative_ptoken)
						Optimiser::mark_vocabulary(alt->ve_pt, nt);

@ =
range_requirement Optimiser::find_requirement_for_nonterminal(nonterminal *nt) {
	range_requirement nnt;
	Optimiser::clear_rreq(&nnt);
	int first_production = TRUE;
	for (production_list *pl = nt->first_production_list; pl; pl = pl->next_production_list) {
		for (production *pr = pl->first_production; pr; pr = pr->next_production) {
			pr->opt.production_req = Optimiser::find_requirement_for_production(pr, nt);
			if (first_production) nnt = pr->opt.production_req;
			else Optimiser::disjoin_rreq(&nnt, &(pr->opt.production_req));
			first_production = FALSE;
		}
	}
	return nnt;
}

range_requirement Optimiser::find_requirement_for_production(production *pr, nonterminal *nt) {
	range_requirement prt;
	Optimiser::clear_rreq(&prt);
	int all = TRUE, first = TRUE;
	for (ptoken *pt = pr->first_ptoken; pt; pt = pt->next_ptoken) {
		Optimiser::clear_rreq(&(pt->opt.token_req));
		if ((pt->ptoken_category == FIXED_WORD_PTC) && (pt->negated_ptoken == FALSE)) {
			ptoken *alt;
			for (alt = pt; alt; alt = alt->alternative_ptoken)
				Optimiser::mark_vocabulary(alt->ve_pt, nt);
			Optimiser::atomic_rreq(&(pt->opt.token_req), nt);
		} else all = FALSE;
		int empty = FALSE;
		if ((pt->ptoken_category == NONTERMINAL_PTC) &&
			(pt->nt_pt->opt.min_nt_words == 0) && (pt->nt_pt->opt.max_nt_words == 0))
			empty = TRUE; /* even if negated, notice */
		if ((pt->ptoken_category == NONTERMINAL_PTC) && (pt->negated_ptoken == FALSE)) {
			Optimiser::find_requirement_and_extrema(pt->nt_pt);
			pt->opt.token_req = pt->nt_pt->opt.nonterminal_req;
		}
		if (empty == FALSE) {
			if (first) prt = pt->opt.token_req;
			else Optimiser::concatenate_rreq(&prt, &(pt->opt.token_req));
			first = FALSE;
		}
	}
	return prt;
}

@ =
void Optimiser::simplify_requirements(nonterminal *nt) {
	production_list *pl;
	for (pl = nt->first_production_list; pl; pl = pl->next_production_list) {
		production *pr;
		range_requirement *prev_req = NULL;
		for (pr = pl->first_production; pr; pr = pr->next_production) {
			Optimiser::simplify_pair(&(pr->opt.production_req), prev_req);
			prev_req = &(pr->opt.production_req);
		}
	}
	Optimiser::simplify_pair(&(nt->opt.nonterminal_req), NULL);
}

void Optimiser::find_extrema(nonterminal *nt) {
	int min = -1, max = -1;
	Optimiser::nonterminal_extrema(nt, &min, &max);
	if (min >= 1) {
		nt->opt.min_nt_words = min; nt->opt.max_nt_words = max;
	}
}

@ The minimum matched text length for a nonterminal is the smallest of the
minima for its possible productions; for a production, it's the sum of the
minimum match lengths of its tokens.

=
void Optimiser::nonterminal_extrema(nonterminal *nt, int *min, int *max) {
	for (production_list *pl = nt->first_production_list; pl; pl = pl->next_production_list)
		for (production *pr = pl->first_production; pr; pr = pr->next_production) {
			int min_p = 0, max_p = 0;
			for (ptoken *pt = pr->first_ptoken; pt; pt = pt->next_ptoken) {
				int min_t, max_t;
				Optimiser::ptoken_extrema(pt, &min_t, &max_t);
				min_p += min_t; max_p += max_t;
				if (min_p > INFINITE_WORD_COUNT) min_p = INFINITE_WORD_COUNT;
				if (max_p > INFINITE_WORD_COUNT) max_p = INFINITE_WORD_COUNT;
			}
			pr->opt.min_pr_words = min_p; pr->opt.max_pr_words = max_p;
			if ((*min == -1) && (*max == -1)) { *min = min_p; *max = max_p; }
			else {
				if (min_p < *min) *min = min_p;
				if (max_p > *max) *max = max_p;
			}
		}
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
			Optimiser::find_requirement_and_extrema(pt->nt_pt); /* recurse as needed to find its extrema */
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

@ Now to define elasticity:

@d PTOKEN_ELASTIC -1

=
int Optimiser::ptoken_width(ptoken *pt) {
	int min, max;
	Optimiser::ptoken_extrema(pt, &min, &max);
	if (min != max) return PTOKEN_ELASTIC;
	return min;
}



@h Flagging and numbering.
The following is called when a word |ve| is read as part of a production
with match number |pc| for the nonterminal |nt|:

=
void Optimiser::flag_words(vocabulary_entry *ve, nonterminal *nt, int pc) {
	ve->flags |= (nt->opt.flag_words_in_production);
	if (nt->opt.number_words_by_production) ve->literal_number_value = pc;
}


@ =
int first_round_of_nt_optimisation_made = FALSE;

void Optimiser::ask_parent_to_tweak(void) {
	if (first_round_of_nt_optimisation_made == FALSE) {
		first_round_of_nt_optimisation_made = TRUE;
		#ifdef FURTHER_PREFORM_OPTIMISER_WORDS_CALLBACK
		FURTHER_PREFORM_OPTIMISER_WORDS_CALLBACK();
		#endif
		#ifdef PREFORM_OPTIMISER_WORDS_CALLBACK
		PREFORM_OPTIMISER_WORDS_CALLBACK();
		#endif
	}
}

void Optimiser::mark_nt_as_requiring_itself(nonterminal *nt) {
	nt->opt.nonterminal_req.DS_req |= (Optimiser::nt_incidence_bit(nt));
	nt->opt.nonterminal_req.DW_req |= (Optimiser::nt_incidence_bit(nt));
}

void Optimiser::mark_nt_as_requiring_itself_first(nonterminal *nt) {
	nt->opt.nonterminal_req.DS_req |= (Optimiser::nt_incidence_bit(nt));
	nt->opt.nonterminal_req.DW_req |= (Optimiser::nt_incidence_bit(nt));
	nt->opt.nonterminal_req.FS_req |= (Optimiser::nt_incidence_bit(nt));
	nt->opt.nonterminal_req.FW_req |= (Optimiser::nt_incidence_bit(nt));
}

void Optimiser::mark_nt_as_requiring_itself_conj(nonterminal *nt) {
	nt->opt.nonterminal_req.DS_req |= (Optimiser::nt_incidence_bit(nt));
	nt->opt.nonterminal_req.DW_req |= (Optimiser::nt_incidence_bit(nt));
	nt->opt.nonterminal_req.CS_req |= (Optimiser::nt_incidence_bit(nt));
	nt->opt.nonterminal_req.CW_req |= (Optimiser::nt_incidence_bit(nt));
	nt->opt.nonterminal_req.FS_req |= (Optimiser::nt_incidence_bit(nt));
	nt->opt.nonterminal_req.FW_req |= (Optimiser::nt_incidence_bit(nt));
}

void Optimiser::mark_nt_as_requiring_itself_augmented(nonterminal *nt, int x) {
	nt->opt.nonterminal_req.DS_req |= (Optimiser::nt_incidence_bit(nt));
	nt->opt.nonterminal_req.DW_req |= (Optimiser::nt_incidence_bit(nt));
	nt->opt.nonterminal_req.CW_req |= (Optimiser::nt_incidence_bit(nt) + x);
	nt->opt.nonterminal_req.FW_req |= (Optimiser::nt_incidence_bit(nt) + x);
}
