[Preform::] Preform.

To read in structural definitions of natural language written in a
meta-language called Preform.

@h Definitions.

@h Introduction.

@default PREFORM_LANGUAGE_TYPE void

@ The parser reads source text against a specific language only, if
|language_of_source_text| is set; or, if it isn't, from any language.

=
PREFORM_LANGUAGE_TYPE *language_of_source_text = NULL;
PREFORM_LANGUAGE_TYPE *language_being_read_by_Preform = NULL;

@ Preform is parsed with the regular lexer, using the following set of
characters as word-breaking punctuation marks:

@d PREFORM_PUNCTUATION_MARKS L"{}[]_^?&\\"

@ That's what it would look like in the Preform file, but here is how it's
typed in the Inform source code. Definitions like this one are scattered all
across the Inform web, in order to keep them close to the code which relates to
them. The |inweb| tangler compiles them in two halves: the instructions right
of the |==>| arrows are extracted and compiled into a C routine called the
"compositor" for the nonterminal (see below), while the actual grammar is
extracted and placed into Inform's "Preform.txt" file.

In the document of Preform grammar extracted from Inform's source code to
lay the language out for translators, the |==>| arrows and formulae to the
right of them are omitted -- those represent semantics, not syntax.

= (not code)
	<competitor> ::=
		<ordinal-number> runner |				==> TRUE
		runner no <cardinal-number>				==> FALSE

@ Each nonterminal, when successfully matched, can provide both or more usually
just one of two results: an integer, to be stored in |*X|, and a void pointer,
to be stored in |*XP|. For example, <k-kind> matches if and only if the
text declares a legal kind, such as "number"; its pointer result is to the
kind found, such as |K_number|. But <competitor> only results in an integer.
The |==>| arrow is optional, but if present, it says what the result is if
the given production is matched; the |inweb| tangler, if it sees an expression
on the right of the arrow, assigns that value to the integer result. So,
for example, "runner bean" or "beetroot" would not match <competitor>;
"4th runner" would match with integer result |TRUE|; "runner no 17" would
match with integer result |FALSE|.

Usually, though, the result(s) of a nonterminal depend on the result(s) of
other nonterminals used to make the match. In the compositing expression,
so called because it composes together the various intermediate results into
one final result, |R[1]| is the integer result of the first nonterminal in
the production, |R[2]| the second, and so on; |RP[1]| and so on hold the
pointer results. Here, on both productions, there's just one nonterminal
in the line, <ordinal-number> in the first case, <cardinal-number> in
the second. So the following refinement of <competitor> means that "4th
runner" matches with integer result 4, because <ordinal-number> matches
"4th" with integer result 4, and that goes into |R[1]|. Similarly,
"runner no 17" ends up with integer result 17. "The pacemaker" matches
with integer result 1; here there are no intermediate results to make use
of, so |R[...]| can't be used.

= (not code)
	<competitor> ::=
		the pacemaker |							==> 1
		<ordinal-number> runner |				==> R[1]
		runner no <cardinal-number>				==> R[1]

@ The arrows and expressions are optional, and if they are omitted, then the
result integer is set to the production number, counting up from 0. For
example, given the following, "polkadot" matches with result 1, and "green"
with result 2.

= (not code)
	<race-jersey> ::=
		yellow | polkadot | green | white

@h Implementation.
We must first clarify how word ranges, once matched in the parser, will be
stored. Within each production, word ranges are numbered upwards from 1. Thus:

	|man with ... on his ...|

would, if it matched successfully, generate two word ranges, numbered 1 and 2.
These are stored in memory belonging to the nonterminal; they are usually, but
not always, then retrieved by whatever part of Inform requested the parse,
using the |GET_RW| macro rather than a function call for speed. It's rare,
but a few internal nonterminals also generate word ranges: they use the
corresponding |PUT_RW| macro to do so. Lastly, we can pass word ranges up
from one nonterminal to another, with |INHERIT_RANGES|.

This form of storage incurs very little time or space overhead, and is possible
only because the parser never backtracks. But it also follows that word ranges
are overwritten if a nonterminal calls itself directly or indirectly: that is,
the inner one's results are wiped out by the outer one. But this is no problem,
since we never extract word-ranges from grammar which is recursive.

Word range 0 is reserved in case we ever need it for the entire text matched
by the nonterminal, but at present we don't need that.

@d MAX_RANGES_PER_PRODUCTION 5 /* in fact, one less than this, since range 0 is reserved */
@d GET_RW(nt, N) (nt->range_result[N])
@d PUT_RW(nt, N, W) { nt->range_result[N] = W; }
@d INHERIT_RANGES(from, to) {
	for (int i=1; i<MAX_RANGES_PER_PRODUCTION; i++) /* not copying range 0 */
		to->range_result[i] = from->range_result[i];
}
@d CLEAR_RW(from) {
	for (int i=0; i<MAX_RANGES_PER_PRODUCTION; i++) /* including range 0 */
		from->range_result[i] = EMPTY_WORDING;
}

@ So here's the nonterminal structure. There are a few further complications
for speed reasons:

(a) The minimum and maximum number of words which could ever be a match are
precalculated. For example, if Preform can tell that N will only a run of
between 3 and 7 words inclusive, then it can quickly reject any run of words
outside that range. |INFINITE_WORD_COUNT| is taken as the maximum if N
could in principle match text of any length. (However: note that a maximum of
0 means that the maximum and minimum word counts are disregarded.)

(b) A few internal nonterminals are "voracious". These are given the entire
word range for their productions to eat, and encouraged to eat as much as
they like, returning a word number to show how far they got. While this
effect could be duplicated with suitable grammar and non-voracious nonterminals,
it would be quite a bit slower, since it would have to test every possible
word range.

@d MAX_RESULTS_PER_PRODUCTION 10
@d INFINITE_WORD_COUNT 1000000000

=
typedef struct nonterminal {
	struct vocabulary_entry *nonterminal_id; /* e.g. |"<cardinal-number>"| */
	int voracious; /* if true, scans whole rest of word range */
	int multiplicitous;

	int marked_internal; /* has, or will be given, an internal definition... */
	int (*internal_definition)(wording W, int *result, void **result_p); /* ...this one */

	struct production_list *first_production_list; /* if not internal, this defines it */

	int (*result_compositor)(int *r, void **rp, int *inters, void **inter_ps, wording *interW, wording W);

	struct wording range_result[MAX_RANGES_PER_PRODUCTION]; /* storage for word ranges matched */

	int optimised_in_this_pass; /* have the following been worked out yet? */
	int min_nt_words, max_nt_words; /* for speed */
	struct range_requirement nonterminal_req;
	int nt_req_bit; /* which hashing category the words belong to, or $-1$ if none */

	int number_words_by_production;
	unsigned int flag_words_in_production;

	int watched; /* watch goings-on to the debugging log */
	int nonterminal_tries; /* used only in instrumented mode */
	int nonterminal_matches; /* ditto */
	MEMORY_MANAGEMENT
} nonterminal;

@ Each (external) nonterminal is then defined by lists of productions:
potentially one for each language, though only English is required to define
all of them, and English will always be the first in the list of lists.

=
typedef struct production_list {
	PREFORM_LANGUAGE_TYPE *definition_language;
	struct production *first_production;
	struct production_list *next_production_list;
	struct match_avinue *as_avinue; /* when compiled to a trie rather than for Preform */
	MEMORY_MANAGEMENT
} production_list;

@ So now we reach the production, which encodes a typical "row" of grammar;
see the examples above. A production is another list, of "ptokens" (the
"p" is silent). For example, the production

	|runner no <cardinal-number>|

contains three ptokens. (Note that the stroke sign and the defined-by sign are
not ptokens; they divide up productions, but aren't part of them.)

Like nonterminals, productions also count the minimum and maximum words
matched: in the above example, both are 3.

There's a new idea here as well, though: struts. A "strut" is a run of
ptokens in the interior of the production whose position relative to the
ends is not known. For example, if we match:

	|frogs like ... but not ... to eat|

then we know that in a successful match, "frogs" and "like" must be the
first two words in the text matched, and "eat" and "to" the last two.
They are said to have positions 1, 2, $-1$ and $-2$ respectively: a positive
number is relative to the start of the range, a negative relative to the end,
so that position 1 is always the first word and position $-1$ is the last.

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

@d MAX_STRUTS_PER_PRODUCTION 10
@d MAX_PTOKENS_PER_PRODUCTION 16

=
typedef struct production {
	struct ptoken *first_ptoken; /* the linked list of ptokens */
	int match_number; /* 0 for |/a/|, 1 for |/b/| and so on */

	int no_ranges; /* actually one more, since range 0 is reserved (see above) */

	int min_pr_words, max_pr_words; /* for speed */
	struct range_requirement production_req;

	int no_struts; /* the actual number, this time */
	struct ptoken *struts[MAX_STRUTS_PER_PRODUCTION]; /* first ptoken in strut */
	int strut_lengths[MAX_STRUTS_PER_PRODUCTION]; /* length of the strut in words */

	int production_tries; /* used only in instrumented mode */
	int production_matches; /* ditto */
	struct wording sample_text; /* ditto */

	struct production *next_production; /* within its production list */
	MEMORY_MANAGEMENT
} production;

@ And at the bottom of the chain, the lowly ptoken. Even this can spawn another
list, though: the token |fried/green/tomatoes| is a list of three ptokens joined
by the |alternative_ptoken| links.

There are two modifiers left to represent: the effects of |^| (negation) and
|_| (casing), and they each have flags. If the ptoken is at the head of a list
of alternatives, they apply to all of the alternatives, even though set only
for the headword.

Each ptoken has a |range_starts| and |range_ends| number. This is either $-1$,
or marks that the ptoken occurs as the first or last in a range (or both). For
example, in the production

	|make ... from {rice ... onions} and peppers|

the first |...| ptoken has start and end set to 1; |rice| has start 2; |onions|
has end 2. Note that the second |...|, inside the braces, doesn't start or
end anything; it normally would, but the wider range consumes it.

There are really only three kinds of ptoken, wildcards, fixed words, and
nonterminals, but it's fractionally quicker to differentiate the sorts of
wildcard here, so we'll actually divide them into five. The remaining wildcard,
the |......| form of |...|, is represented as |MULTIPLE_WILDCARD_PTC| but with
the |balanced_wildcard| flag set.

@d SINGLE_WILDCARD_PTC 1
@d MULTIPLE_WILDCARD_PTC 2
@d POSSIBLY_EMPTY_WILDCARD_PTC 3
@d FIXED_WORD_PTC 4
@d NONTERMINAL_PTC 5

=
typedef struct ptoken {
	int ptoken_category; /* one of the |*_PTC| values */

	int negated_ptoken; /* the |^| modifier applies */
	int disallow_unexpected_upper; /* the |_| modifier applies */

	struct nonterminal *nt_pt; /* for |NONTERMINAL_PTC| ptokens */

	struct vocabulary_entry *ve_pt; /* for |FIXED_WORD_PTC| ptokens */
	struct ptoken *alternative_ptoken; /* linked list of other vocabulary ptokens */

	int balanced_wildcard; /* for |MULTIPLE_WILDCARD_PTC| ptokens: brackets balanced? */

	int result_index; /* for |NONTERMINAL_PTC| ptokens: what result number, counting from 1? */
	int range_starts; /* 1, 2, 3, ... if word range 1, 2, 3, ... starts with this */
	int range_ends; /* 1, 2, 3, ... if word range 1, 2, 3, ... ends with this */

	int ptoken_position; /* fixed position in range: 1, 2, ... for left, $-1$, $-2$, ... for right */
	int strut_number; /* if this is part of a strut, what number? or $-1$ if not */

	int ptoken_is_fast; /* can be checked in the fast pass of the parser */

	struct range_requirement token_req;

	struct ptoken *next_ptoken; /* within its production list */
	MEMORY_MANAGEMENT
} ptoken;

@ The parser records the result of the most recently matched nonterminal in the
following global variables:

=
int most_recent_result = 0; /* this is the variable which |inweb| writes |<<r>>| */
void *most_recent_result_p = NULL; /* this is the variable which |inweb| writes |<<rp>>| */

@ Preform's aim is to purge the Inform source code of all English vocabulary,
but we do still the letters "K" and "L", to define the wording of kind constructors.

=
vocabulary_entry *CAPITAL_K_V;
vocabulary_entry *CAPITAL_L_V;

@ Preform can run in an instrumented mode, which collects statistics on the
usage of syntax it sees, but there's a performance hit for this. So it's
enabled only if the constant |INSTRUMENTED_PREFORM| defined to |TRUE|: here's
where to do it.

@ =
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

@h Logging.
Descending these wheels within wheels:

=
void Preform::log_language(void) {
	int detailed = FALSE;
	nonterminal *nt;
	LOOP_OVER(nt, nonterminal) {
		#ifdef INSTRUMENTED_PREFORM
		LOG("%d/%d: ", nt->nonterminal_matches, nt->nonterminal_tries);
		#endif
		LOG("%V: ", nt->nonterminal_id);
		Preform::log_range_requirement(&(nt->nonterminal_req));
		LOG("\n");
		if (nt->internal_definition) LOG("  (internal)\n");
		else {
			production_list *pl;
			for (pl = nt->first_production_list; pl; pl = pl->next_production_list) {
				LOG("  $J:\n", pl->definition_language);
				production *pr;
				for (pr = pl->first_production; pr; pr = pr->next_production) {
					LOG("   "); Preform::log_production(pr, detailed);
					#ifdef INSTRUMENTED_PREFORM
					LOG("      %d/%d: ", pr->production_matches, pr->production_tries);
					if (Wordings::nonempty(pr->sample_text)) LOG("<%W>", pr->sample_text);
					#endif
					LOG(" ==> ");
					Preform::log_range_requirement(&(pr->production_req));
					LOG("\n");
				}
			}
		}
		LOG("  min %d, max %d\n\n", nt->min_nt_words, nt->max_nt_words);
	}
	LOG("%d req bits.\n", no_req_bits);
}

@ =
void Preform::log_production(production *pr, int detailed) {
	if (pr->first_ptoken == NULL) LOG("<empty-production>");
	ptoken *pt;
	for (pt = pr->first_ptoken; pt; pt = pt->next_ptoken) {
		Preform::log_ptoken(pt, detailed);
		LOG(" ");
	}
}

@ =
void Preform::log_ptoken(ptoken *pt, int detailed) {
	if ((detailed) && (pt->ptoken_position != 0)) LOG("(@%d)", pt->ptoken_position);
	if ((detailed) && (pt->strut_number >= 0)) LOG("(S%d)", pt->strut_number);
	if (pt->disallow_unexpected_upper) LOG("_");
	if (pt->negated_ptoken) LOG("^");
	if (pt->range_starts >= 0) { LOG("{"); if (detailed) LOG("%d:", pt->range_starts); }
	ptoken *alt;
	for (alt = pt; alt; alt = alt->alternative_ptoken) {
		if (alt->nt_pt) {
			LOG("%V", alt->nt_pt->nonterminal_id);
			if (detailed) LOG("=%d", alt->result_index);
		} else {
			LOG("%V", alt->ve_pt);
		}
		if (alt->alternative_ptoken) LOG("/");
	}
	if (pt->range_ends >= 0) { if (detailed) LOG(":%d", pt->range_ends); LOG("}"); }
}

@ A less detailed form used in linguistic problem messages:

=
void Preform::write_ptoken(OUTPUT_STREAM, ptoken *pt) {
	if (pt->disallow_unexpected_upper) WRITE("_");
	if (pt->negated_ptoken) WRITE("^");
	if (pt->range_starts >= 0) WRITE("{");
	ptoken *alt;
	for (alt = pt; alt; alt = alt->alternative_ptoken) {
		if (alt->nt_pt) {
			WRITE("%V", alt->nt_pt->nonterminal_id);
		} else {
			WRITE("%V", alt->ve_pt);
		}
		if (alt->alternative_ptoken) WRITE("/");
	}
	if (pt->range_ends >= 0) WRITE("}");
}

@ This is a typical internal nonterminal being defined. It's used only to parse
inclusion requests for the debugging log. Note that we use the "1" to signal
that a correct match must have exactly one word.

=
<preform-nonterminal> internal 1 {
	nonterminal *nt = Preform::detect_nonterminal(Lexer::word(Wordings::first_wn(W)));
	if (nt) { *XP = nt; return TRUE; }
	return FALSE;
}

@ To use which, the debugging log code needs:

=
void Preform::watch(nonterminal *nt, int state) {
	nt->watched = state;
}

@h Building grammar.
So, to begin. Since we can't use Preform to parse Preform, we have to define
its syntactic tokens by hand:

=
vocabulary_entry *AMPERSAND_V;
vocabulary_entry *BACKSLASH_V;
vocabulary_entry *CARET_V;
vocabulary_entry *COLONCOLONEQUALS_V;
vocabulary_entry *QUESTIONMARK_V;
vocabulary_entry *QUOTEQUOTE_V;
vocabulary_entry *SIXDOTS_V;
vocabulary_entry *THREEASTERISKS_V;
vocabulary_entry *THREEDOTS_V;
vocabulary_entry *THREEHASHES_V;
vocabulary_entry *UNDERSCORE_V;
vocabulary_entry *language_V;
vocabulary_entry *internal_V;

@ And off we go.

=
void Preform::begin(void) {
	CAPITAL_K_V      = Vocabulary::entry_for_text(L"k");
	CAPITAL_L_V      = Vocabulary::entry_for_text(L"l");

	@<Register the internal and source-code-referred-to nonterminals@>;

	AMPERSAND_V      = Vocabulary::entry_for_text(L"&");
	BACKSLASH_V      = Vocabulary::entry_for_text(L"\\");
	CARET_V          = Vocabulary::entry_for_text(L"^");
	COLONCOLONEQUALS_V = Vocabulary::entry_for_text(L":" ":=");
	QUESTIONMARK_V     = Vocabulary::entry_for_text(L"?");
	QUOTEQUOTE_V     = Vocabulary::entry_for_text(L"\"\"");
	SIXDOTS_V        = Vocabulary::entry_for_text(L"......");
	THREEASTERISKS_V = Vocabulary::entry_for_text(L"***");
	THREEDOTS_V      = Vocabulary::entry_for_text(L"...");
	THREEHASHES_V    = Vocabulary::entry_for_text(L"###");
	UNDERSCORE_V     = Vocabulary::entry_for_text(L"_");
	language_V         = Vocabulary::entry_for_text(L"language");
    internal_V         = Vocabulary::entry_for_text(L"internal");
}

@ The tangler of |inweb| replaces the |[[nonterminals]]| below with
invocations of the |REGISTER_NONTERMINAL| and |INTERNAL_NONTERMINAL| macros.

@<Register the internal and source-code-referred-to nonterminals@> =
	[[nonterminals]];
	nonterminal *nt;
	LOOP_OVER(nt, nonterminal)
		if ((nt->marked_internal) && (nt->internal_definition == NULL))
			internal_error("internal undefined");

@ These macros connect nonterminals with their mentions in the Inform source
code, and with the compositor routines compiled for them by |inweb|. It invokes
|REGISTER_NONTERMINAL| if it has compiled Preform productions for a nonterminal,
and compiled a compositor routine; the name of which is the nonterminal's name
with a |C| suffix. If it found an internal nonterminal, it invokes
|INTERNAL_NONTERMINAL|, and compiles a routine whose name has the suffix |R|
as the definition.

@d REGISTER_NONTERMINAL(quotedname, identifier)
	identifier = Preform::find_nonterminal(Vocabulary::entry_for_text(quotedname));
	identifier->result_compositor = identifier##C;

@d INTERNAL_NONTERMINAL(quotedname, identifier, min, max)
	identifier = Preform::find_nonterminal(Vocabulary::entry_for_text(quotedname));
	identifier->min_nt_words = min; identifier->max_nt_words = max;
	identifier->internal_definition = identifier##R;
	identifier->marked_internal = TRUE;

@ Parsing Preform is exactly what Preform would do elegantly, but of course,
for chicken-and-egg reasons, we need to do the job by hand. Fortunately the
syntax is very simple.

=
int Preform::parse_preform(wording W, int break_first) {
	if (break_first) {
		TEMPORARY_TEXT(wd);
		WRITE_TO(wd, "%+W", Wordings::one_word(Wordings::first_wn(W)));
		W = Feeds::feed_stream_punctuated(wd, PREFORM_PUNCTUATION_MARKS);
		DISCARD_TEXT(wd);
	}
	int nonterminals_declared = 0;
	LOOP_THROUGH_WORDING(wn, W) {
		if (Lexer::word(wn) == PARBREAK_V) continue;
		#ifdef PREFORM_LANGUAGE_FROM_NAME
		if ((Wordings::last_wn(W) >= wn+1) && (Lexer::word(wn) == language_V)) {
			@<Parse a definition language switch@>;
			continue;
		}
		#endif
		if ((Wordings::last_wn(W) >= wn+1) && (Lexer::word(wn+1) == internal_V)) {
			@<Parse an internal nonterminal declaration@>;
			nonterminals_declared++;
			continue;
		}
		if ((Wordings::last_wn(W) >= wn+2) && (Lexer::word(wn+1) == COLONCOLONEQUALS_V)) {
			@<Parse an external nonterminal declaration@>;
			nonterminals_declared++;
			continue;
		}
		internal_error("language definition failed");
	}
	Preform::optimise_counts();
	return nonterminals_declared;
}

@ We either switch to an existing natural language, or create a new one.

@<Parse a definition language switch@> =
	TEMPORARY_TEXT(lname);
	WRITE_TO(lname, "%W", Wordings::one_word(wn+1));
	PREFORM_LANGUAGE_TYPE *nl = PREFORM_LANGUAGE_FROM_NAME(lname);
	if (nl == NULL) {
		LOG("Missing: %S\n", lname);
		internal_error("tried to define for missing language");
	}
	DISCARD_TEXT(lname);
	language_being_read_by_Preform = nl;
	wn++;

@<Parse an internal nonterminal declaration@> =
	nonterminal *nt = Preform::find_nonterminal(Lexer::word(wn));
	if (nt->first_production_list) internal_error("internal is defined");
	nt->marked_internal = TRUE;
	wn++;

@ The declaration continues until the end of the text, or until we reach a
paragraph break. Internally, it's a list of productions divided by stroke symbols.

@<Parse an external nonterminal declaration@> =
	nonterminal *nt = Preform::find_nonterminal(Lexer::word(wn));
	production_list *pl;
	@<Find or create the production list for this language@>;
	wn += 2;
	int pc = 0;
	while (TRUE) {
		int x = wn;
		while ((x <= Wordings::last_wn(W)) && (Lexer::word(x) != STROKE_V) && (Lexer::word(x) != PARBREAK_V)) x++;
		if (wn < x) {
			production *pr = Preform::new_production(Wordings::new(wn, x-1), nt, pc++);
			wn = x;
			@<Place the new production within the production list@>;
		}
		if ((wn > Wordings::last_wn(W)) || (Lexer::word(x) == PARBREAK_V)) break; /* reached end */
		wn++; /* advance past the stroke and continue */
	}
	wn--;

@<Find or create the production list for this language@> =
	for (pl = nt->first_production_list; pl; pl = pl->next_production_list)
		if (pl->definition_language == language_being_read_by_Preform)
			break;
	if (pl == NULL)	{
		pl = CREATE(production_list);
		pl->definition_language = language_being_read_by_Preform;
		pl->first_production = NULL;
		pl->as_avinue = NULL;
		@<Place the new production list within the nonterminal@>;
	}

@<Place the new production list within the nonterminal@> =
	if (nt->first_production_list == NULL) nt->first_production_list = pl;
	else {
		production_list *p = nt->first_production_list;
		while ((p) && (p->next_production_list)) p = p->next_production_list;
		p->next_production_list = pl;
	}

@<Place the new production within the production list@> =
	if (pl->first_production == NULL) pl->first_production = pr;
	else {
		production *p = pl->first_production;
		while ((p) && (p->next_production)) p = p->next_production;
		p->next_production = pr;
	}

@ Nonterminals are identified by their name-words:

=
nonterminal *Preform::detect_nonterminal(vocabulary_entry *ve) {
	nonterminal *nt;
	LOOP_OVER(nt, nonterminal)
		if (ve == nt->nonterminal_id)
			return nt;
	return NULL;
}

nonterminal *Preform::find_nonterminal(vocabulary_entry *ve) {
	nonterminal *nt = Preform::detect_nonterminal(ve);
	if (nt) return nt;

	nt = CREATE(nonterminal);
	nt->nonterminal_id = ve;

	nt->voracious = FALSE;
	nt->multiplicitous = FALSE;

	nt->optimised_in_this_pass = FALSE;
	nt->min_nt_words = 1; nt->max_nt_words = INFINITE_WORD_COUNT;
	nt->nt_req_bit = -1;

	nt->first_production_list = NULL;
	nt->marked_internal = FALSE;
	nt->internal_definition = NULL;
	nt->result_compositor = NULL;

	nt->number_words_by_production = FALSE;
	nt->flag_words_in_production = 0;

	for (int i=0; i<MAX_RANGES_PER_PRODUCTION; i++)
		nt->range_result[i] = EMPTY_WORDING;

	nt->watched = FALSE;
	nt->nonterminal_tries = 0; nt->nonterminal_matches = 0;
	return nt;
}

@ We now descend to the creation of productions for (external) nonterminals.

=
production *Preform::new_production(wording W, nonterminal *nt, int pc) {
	production *pr = CREATE(production);
	pr->match_number = pc;
	pr->next_production = NULL;

	pr->no_ranges = 1; /* so that they count from 1; range 0 is unused */

	pr->no_struts = 0; /* they will be detected later */

	pr->min_pr_words = 1; pr->max_pr_words = INFINITE_WORD_COUNT;

	pr->production_tries = 0; pr->production_matches = 0;
	pr->sample_text = EMPTY_WORDING;

	ptoken *head = NULL, *tail = NULL;
	@<Parse the row of production tokens into a linked list of ptokens@>;
	pr->first_ptoken = head;
	return pr;
}

@

@d OUTSIDE_PTBRACE 0
@d ABOUT_TO_OPEN_PTBRACE 1
@d INSIDE_PTBRACE 2

@<Parse the row of production tokens into a linked list of ptokens@> =
	int result_count = 1;
	int negation_modifier = FALSE, lower_case_modifier = FALSE;
	int unescaped = TRUE;
	int bracing_mode = OUTSIDE_PTBRACE;
	ptoken *bracing_begins_at = NULL;
	int tc = 0;
	LOOP_THROUGH_WORDING(i, W) {
		if (unescaped) @<Parse the token modifier symbols@>;

		ptoken *pt = Preform::parse_slashed_chain(nt, pr, i, unescaped);
		if (pt == NULL) continue; /* we have set the production match number instead */

		if (pt->ptoken_category == NONTERMINAL_PTC) @<Assign the ptoken a result number@>;

		@<Modify the new token according to the current token modifier settings@>;

		if (tc++ < MAX_PTOKENS_PER_PRODUCTION) {
			if (head == NULL) head = pt; else tail->next_ptoken = pt;
			tail = pt;
		}
	}

@<Parse the token modifier symbols@> =
	if (Lexer::word(i) == CARET_V) { negation_modifier = TRUE; continue; }
	if (Lexer::word(i) == UNDERSCORE_V) { lower_case_modifier = TRUE; continue; }
	if (Lexer::word(i) == BACKSLASH_V) { unescaped = FALSE; continue; }
	switch (bracing_mode) {
		case OUTSIDE_PTBRACE:
			if (Lexer::word(i) == OPENBRACE_V) {
				bracing_mode = ABOUT_TO_OPEN_PTBRACE; continue;
			}
			break;
		case INSIDE_PTBRACE:
			if (Lexer::word(i) == CLOSEBRACE_V) {
				if (bracing_begins_at) {
					int rnum = pr->no_ranges++;
					if ((i+2 <= Wordings::last_wn(W)) && (Lexer::word(i+1) == QUESTIONMARK_V) &&
						(Vocabulary::test_flags(i+2, NUMBER_MC))) {
						rnum = Vocabulary::get_literal_number_value(Lexer::word(i+2));
						i += 2;
					}
					bracing_begins_at->range_starts = rnum;
					tail->range_ends = rnum;
				}
				bracing_mode = OUTSIDE_PTBRACE; bracing_begins_at = NULL; continue;
			}
			break;
	}

@<Modify the new token according to the current token modifier settings@> =
	if (negation_modifier) pt->negated_ptoken = TRUE;
	if (lower_case_modifier) pt->disallow_unexpected_upper = TRUE;

	unescaped = TRUE;
	negation_modifier = FALSE;
	lower_case_modifier = FALSE;

	switch (bracing_mode) {
		case OUTSIDE_PTBRACE:
			if (((pt->ptoken_category == SINGLE_WILDCARD_PTC) ||
				(pt->ptoken_category == MULTIPLE_WILDCARD_PTC) ||
				(pt->ptoken_category == POSSIBLY_EMPTY_WILDCARD_PTC))
				&& (pr->no_ranges < MAX_RANGES_PER_PRODUCTION)) {
				int rnum = pr->no_ranges++;
				pt->range_starts = rnum;
				pt->range_ends = rnum;
			}
			break;
		case ABOUT_TO_OPEN_PTBRACE:
			if (pr->no_ranges < MAX_RANGES_PER_PRODUCTION)
				bracing_begins_at = pt;
			bracing_mode = INSIDE_PTBRACE;
			break;
	}

@<Assign the ptoken a result number@> =
	if (result_count < MAX_RESULTS_PER_PRODUCTION) {
		if ((i+2 <= Wordings::last_wn(W)) && (Lexer::word(i+1) == QUESTIONMARK_V) &&
			(Vocabulary::test_flags(i+2, NUMBER_MC))) {
			pt->result_index = Vocabulary::get_literal_number_value(Lexer::word(i+2));
			i += 2;
		} else {
			pt->result_index = result_count;
		}
		result_count++;
	}

@ =
ptoken *Preform::parse_slashed_chain(nonterminal *nt, production *pr, int wn, int unescaped) {
	wording AW = Wordings::one_word(wn);
	@<Expand the word range if the token text is slashed@>;
	ptoken *pt = NULL;
	@<Parse the word range into a linked list of alternative ptokens@>;
	return pt;
}

@<Expand the word range if the token text is slashed@> =
	wchar_t *p = Lexer::word_raw_text(wn);
	int k, breakme = FALSE;
	if (unescaped) {
		if ((p[0] == '/') && (islower(p[1])) && (p[2] == '/') && (p[3] == 0)) {
			pr->match_number = p[1] - 'a';
			return NULL;
		}
		if ((p[0] == '/') && (islower(p[1])) && (p[2] == p[1]) && (p[3] == '/') && (p[4] == 0)) {
			pr->match_number = p[1] - 'a' + 26;
			return NULL;
		}
		for (k=0; (p[k]) && (p[k+1]); k++)
			if ((k > 0) && (p[k] == '/'))
				breakme = TRUE;
	}
	if (breakme) AW = Feeds::feed_text_full(p, FALSE, L"/"); /* break only at slashes */

@<Parse the word range into a linked list of alternative ptokens@> =
	ptoken *alt = NULL;
	for (; Wordings::nonempty(AW); AW = Wordings::trim_first_word(AW))
		if (Lexer::word(Wordings::first_wn(AW)) != FORWARDSLASH_V) {
			int mode = unescaped;
			if (Wordings::length(AW) > 1) mode = FALSE;
			ptoken *latest = Preform::new_ptoken(Lexer::word(Wordings::first_wn(AW)), mode, nt, pr->match_number);
			if (alt == NULL) pt = latest;
			else alt->alternative_ptoken = latest;
			alt = latest;
		}

@ So we come to the end of the trail: the code to create a single ptoken.
In "escaped" mode, where a backslash has made the text literal, it just
becomes a fixed word; otherwise it could be any of the five categories.

If the text refers to a nonterminal which doesn't yet exist, then this
creates it; that's how we deal with forward references.

=
ptoken *Preform::new_ptoken(vocabulary_entry *ve, int unescaped, nonterminal *nt, int pc) {
	ptoken *pt = CREATE(ptoken);
	pt->next_ptoken = NULL;
	pt->alternative_ptoken = NULL;
	pt->negated_ptoken = FALSE;
	pt->disallow_unexpected_upper = FALSE;

	pt->result_index = 1;
	pt->range_starts = -1; pt->range_ends = -1;

	pt->ptoken_position = 0;
	pt->strut_number = -1;

	pt->ve_pt = NULL;
	pt->nt_pt = NULL;
	pt->balanced_wildcard = FALSE;
	pt->ptoken_is_fast = FALSE;

	wchar_t *p = Vocabulary::get_exemplar(ve, FALSE);
	if ((unescaped) && (p) && (p[0] == '<') && (p[Wide::len(p)-1] == '>')) {
		pt->nt_pt = Preform::find_nonterminal(ve);
		pt->ptoken_category = NONTERMINAL_PTC;
	} else {
		pt->ve_pt = ve;
		pt->ptoken_category = FIXED_WORD_PTC;
		if (unescaped) {
			if (ve == SIXDOTS_V) {
				pt->ptoken_category = MULTIPLE_WILDCARD_PTC;
				pt->balanced_wildcard = TRUE;
			}
			if (ve == THREEDOTS_V) pt->ptoken_category = MULTIPLE_WILDCARD_PTC;
			if (ve == THREEHASHES_V) pt->ptoken_category = SINGLE_WILDCARD_PTC;
			if (ve == THREEASTERISKS_V) pt->ptoken_category = POSSIBLY_EMPTY_WILDCARD_PTC;
		}
	}

	if (pt->ptoken_category == FIXED_WORD_PTC) {
		ve->flags |= (nt->flag_words_in_production);
		if (nt->number_words_by_production) ve->literal_number_value = pc;
	}

	return pt;
}

@h Optimisation calculations.
After each round of fresh Preform grammar, we need to recalculate the various
maximum and minimum lengths, struts, and so on, because those all depend on
knowing the length of text a token will match, and new grammar may have
changed that.

=
int first_round_of_nt_optimisation_made = FALSE;

void Preform::optimise_counts(void) {
	nonterminal *nt;
	LOOP_OVER(nt, nonterminal) {
		Preform::clear_rreq(&(nt->nonterminal_req));
		if (nt->marked_internal) {
			nt->optimised_in_this_pass = TRUE;
		} else {
			nt->optimised_in_this_pass = FALSE;
			nt->min_nt_words = 1; nt->max_nt_words = INFINITE_WORD_COUNT;
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
	LOOP_OVER(nt, nonterminal) Preform::optimise_nt(nt);
	LOOP_OVER(nt, nonterminal) Preform::optimise_nt_reqs(nt);
}

void Preform::optimise_nt(nonterminal *nt) {
	if (nt->optimised_in_this_pass) return;
	nt->optimised_in_this_pass = TRUE;
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
				Preform::ptoken_extrema(pt, &min_t, &max_t);
				min_p += min_t; max_p += max_t;
				if (min_p > INFINITE_WORD_COUNT) min_p = INFINITE_WORD_COUNT;
				if (max_p > INFINITE_WORD_COUNT) max_p = INFINITE_WORD_COUNT;
			}
			pr->min_pr_words = min_p; pr->max_pr_words = max_p;
			if ((min == -1) && (max == -1)) { min = min_p; max = max_p; }
			else {
				if (min_p < min) min = min_p;
				if (max_p > max) max = max_p;
			}
		}
	}
	if (min >= 1) {
		nt->min_nt_words = min; nt->max_nt_words = max;
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
		int L = Preform::ptoken_width(pt);
		if ((posn != 0) && (L != PTOKEN_ELASTIC)) {
			pt->ptoken_position = posn;
			posn += L;
		} else {
			pt->ptoken_position = 0; /* thus clearing any expired positions from earlier */
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
		if (pt->ptoken_position != 0) break; /* don't use a back-end position if there's a front one */
		int L = Preform::ptoken_width(pt);
		if ((posn != 0) && (L != PTOKEN_ELASTIC)) {
			pt->ptoken_position = posn;
			posn -= L;
		} else break;

		ptoken *prevt = NULL;
		for (prevt = pr->first_ptoken; prevt; prevt = prevt->next_ptoken)
			if (prevt->next_ptoken == pt)
				break;
		pt = prevt;
	}

@ By definition, a strut is a maximal sequence of one or more inelastic ptokens
each of which has no known position. (Clearly if one of them has a known
position then all of them have, but we're in no hurry so we don't exploit that.)

@<Compute struts within the production@> =
	pr->no_struts = 0;
	ptoken *pt;
	for (pt = pr->first_ptoken; pt; pt = pt->next_ptoken) {
		if ((pt->ptoken_position == 0) && (Preform::ptoken_width(pt) != PTOKEN_ELASTIC)) {
			if (pr->no_struts >= MAX_STRUTS_PER_PRODUCTION) continue;
			pr->struts[pr->no_struts] = pt;
			pr->strut_lengths[pr->no_struts] = 0;
			while ((pt->ptoken_position == 0) && (Preform::ptoken_width(pt) != PTOKEN_ELASTIC)) {
				pt->strut_number = pr->no_struts;
				pr->strut_lengths[pr->no_struts] += Preform::ptoken_width(pt);
				if (pt->next_ptoken == NULL) break; /* should be impossible */
				pt = pt->next_ptoken;
			}
			pr->no_struts++;
		}
	}

@<Work out which ptokens are fast@> =
	ptoken *pt;
	for (pt = pr->first_ptoken; pt; pt = pt->next_ptoken)
		if ((pt->ptoken_category == FIXED_WORD_PTC) && (pt->ptoken_position != 0)
			&& (pt->range_starts < 0) && (pt->range_ends < 0))
			pt->ptoken_is_fast = TRUE;

@ Weak requirement: one word in range must match one of these bits
Strong ": all bits in this range must be matched by one word

@<Mark the vocabulary's incidence list with this nonterminal@> =
	int first_production = TRUE;
	Preform::clear_rreq(&(nt->nonterminal_req));
	#ifdef PREFORM_CIRCULARITY_BREAKER
	PREFORM_CIRCULARITY_BREAKER(nt);
	#endif
	range_requirement nnt;
	Preform::clear_rreq(&nnt);
	for (pl = nt->first_production_list; pl; pl = pl->next_production_list) {
		production *pr;
		for (pr = pl->first_production; pr; pr = pr->next_production) {
			ptoken *pt;
			for (pt = pr->first_ptoken; pt; pt = pt->next_ptoken) {
				if ((pt->ptoken_category == FIXED_WORD_PTC) && (pt->negated_ptoken == FALSE)) {
					ptoken *alt;
					for (alt = pt; alt; alt = alt->alternative_ptoken)
						Preform::set_nt_incidence(alt->ve_pt, nt);
				}
			}
		}
	}
	for (pl = nt->first_production_list; pl; pl = pl->next_production_list) {
		production *pr;
		for (pr = pl->first_production; pr; pr = pr->next_production) {
			range_requirement prt;
			Preform::clear_rreq(&prt);
			int all = TRUE, first = TRUE;
			ptoken *pt;
			for (pt = pr->first_ptoken; pt; pt = pt->next_ptoken) {
				Preform::clear_rreq(&(pt->token_req));
				if ((pt->ptoken_category == FIXED_WORD_PTC) && (pt->negated_ptoken == FALSE)) {
					ptoken *alt;
					for (alt = pt; alt; alt = alt->alternative_ptoken)
						Preform::set_nt_incidence(alt->ve_pt, nt);
					Preform::atomic_rreq(&(pt->token_req), nt);
				} else all = FALSE;
				int self_referential = FALSE, empty = FALSE;
				if ((pt->ptoken_category == NONTERMINAL_PTC) &&
					(pt->nt_pt->min_nt_words == 0) && (pt->nt_pt->max_nt_words == 0))
					empty = TRUE; /* even if negated, notice */
				if ((pt->ptoken_category == NONTERMINAL_PTC) && (pt->negated_ptoken == FALSE)) {
					/* if (pt->nt_pt == nt) self_referential = TRUE; */
					Preform::optimise_nt(pt->nt_pt);
					pt->token_req = pt->nt_pt->nonterminal_req;
				}
				if ((self_referential == FALSE) && (empty == FALSE)) {
					if (first) {
						prt = pt->token_req;
					} else {
						Preform::concatenate_rreq(&prt, &(pt->token_req));
					}
					first = FALSE;
				}
			}
			if (first_production) {
				nnt = prt;
			} else {
				Preform::disjoin_rreq(&nnt, &prt);
			}
			first_production = FALSE;
			pr->production_req = prt;
		}
	}
	nt->nonterminal_req = nnt;
	#ifdef PREFORM_CIRCULARITY_BREAKER
	PREFORM_CIRCULARITY_BREAKER(nt);
	#endif

@

The constant |AL_BITMAP| used in this code has a pleasingly Arabic sound to it
-- a second-magnitude star, an idiotically tall hotel -- but is in fact a
combination of the meaning codes found in an adjective list.

=
void Preform::optimise_nt_reqs(nonterminal *nt) {
	production_list *pl;
	for (pl = nt->first_production_list; pl; pl = pl->next_production_list) {
		production *pr;
		range_requirement *prev_req = NULL;
		for (pr = pl->first_production; pr; pr = pr->next_production) {
			Preform::optimise_req(&(pr->production_req), prev_req);
			prev_req = &(pr->production_req);
		}
	}
	Preform::optimise_req(&(nt->nonterminal_req), NULL);
}

void Preform::optimise_req(range_requirement *req, range_requirement *prev) {
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
void Preform::mark_nt_as_requiring_itself(nonterminal *nt) {
	nt->nonterminal_req.DS_req |= (Preform::nt_bitmap_bit(nt));
	nt->nonterminal_req.DW_req |= (Preform::nt_bitmap_bit(nt));
}

void Preform::mark_nt_as_requiring_itself_first(nonterminal *nt) {
	nt->nonterminal_req.DS_req |= (Preform::nt_bitmap_bit(nt));
	nt->nonterminal_req.DW_req |= (Preform::nt_bitmap_bit(nt));
	nt->nonterminal_req.FS_req |= (Preform::nt_bitmap_bit(nt));
	nt->nonterminal_req.FW_req |= (Preform::nt_bitmap_bit(nt));
}

void Preform::mark_nt_as_requiring_itself_conj(nonterminal *nt) {
	nt->nonterminal_req.DS_req |= (Preform::nt_bitmap_bit(nt));
	nt->nonterminal_req.DW_req |= (Preform::nt_bitmap_bit(nt));
	nt->nonterminal_req.CS_req |= (Preform::nt_bitmap_bit(nt));
	nt->nonterminal_req.CW_req |= (Preform::nt_bitmap_bit(nt));
	nt->nonterminal_req.FS_req |= (Preform::nt_bitmap_bit(nt));
	nt->nonterminal_req.FW_req |= (Preform::nt_bitmap_bit(nt));
}

void Preform::mark_nt_as_requiring_itself_augmented(nonterminal *nt, int x) {
	nt->nonterminal_req.DS_req |= (Preform::nt_bitmap_bit(nt));
	nt->nonterminal_req.DW_req |= (Preform::nt_bitmap_bit(nt));
	nt->nonterminal_req.CW_req |= (Preform::nt_bitmap_bit(nt) + x);
	nt->nonterminal_req.FW_req |= (Preform::nt_bitmap_bit(nt) + x);
}

void Preform::set_nt_incidence(vocabulary_entry *ve, nonterminal *nt) {
	int R = Vocabulary::get_ntb(ve);
	R |= (Preform::nt_bitmap_bit(nt));
	Vocabulary::set_ntb(ve, R);
}

int Preform::test_nt_incidence(vocabulary_entry *ve, nonterminal *nt) {
	int R = Vocabulary::get_ntb(ve);
	if (R & (Preform::nt_bitmap_bit(nt))) return TRUE;
	return FALSE;
}

@

@d RESERVED_NT_BITS 6

=
int Preform::nt_bitmap_bit(nonterminal *nt) {
	if (nt->nt_req_bit == -1) {
		int b = RESERVED_NT_BITS + ((no_req_bits++)%(32-RESERVED_NT_BITS));
		nt->nt_req_bit = (1 << b);
	}
	return nt->nt_req_bit;
}

void Preform::assign_bitmap_bit(nonterminal *nt, int b) {
	if (nt == NULL) internal_error("null NT");
	nt->nt_req_bit = (1 << b);
}

int Preform::test_word(int wn, nonterminal *nt) {
	int b = Preform::nt_bitmap_bit(nt);
	if ((Vocabulary::get_ntb(Lexer::word(wn))) & b) return TRUE;
	return FALSE;
}

void Preform::mark_word(int wn, nonterminal *nt) {
	Preform::set_nt_incidence(Lexer::word(wn), nt);
}

void Preform::mark_vocabulary(vocabulary_entry *ve, nonterminal *nt) {
	Preform::set_nt_incidence(ve, nt);
}

int Preform::test_vocabulary(vocabulary_entry *ve, nonterminal *nt) {
	int b = Preform::nt_bitmap_bit(nt);
	if ((Vocabulary::get_ntb(ve)) & b) return TRUE;
	return FALSE;
}

int Preform::get_range_disjunction(wording W) {
	int R = 0;
	LOOP_THROUGH_WORDING(i, W)
		R |= Vocabulary::get_ntb(Lexer::word(i));
	return R;
}

int Preform::get_range_conjunction(wording W) {
	int R = 0;
	LOOP_THROUGH_WORDING(i, W) {
		if (i == Wordings::first_wn(W)) R = Vocabulary::get_ntb(Lexer::word(i));
		else R &= Vocabulary::get_ntb(Lexer::word(i));
	}
	return R;
}

@ =
int Preform::nt_bitmap_violates(wording W, range_requirement *req) {
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
void Preform::concatenate_rreq(range_requirement *req, range_requirement *with) {
	req->DS_req = Preform::concatenate_ds(req->DS_req, with->DS_req);
	req->DW_req = Preform::concatenate_dw(req->DW_req, with->DW_req);
	req->CS_req = Preform::concatenate_cs(req->CS_req, with->CS_req);
	req->CW_req = Preform::concatenate_cw(req->CW_req, with->CW_req);
	req->FS_req = Preform::concatenate_fs(req->FS_req, with->FS_req);
	req->FW_req = Preform::concatenate_fw(req->FW_req, with->FW_req);
}

@ The strong requirements are well-defined. Suppose all of the bits of |m1|
are found in X, and all of the bits of |m2| are found in Y. Then clearly
all of the bits in the union of these two sets are found in XY, and that's
the strongest requirement we can make. So:

=
int Preform::concatenate_ds(int m1, int m2) {
	return m1 | m2;
}

@ Similarly, suppose all of the bits of |m1| are found in every word of X,
and all of those of |m2| are in every word of Y. The most which can be said
about every word of XY is to take the intersection, so:

=
int Preform::concatenate_cs(int m1, int m2) {
	return m1 & m2;
}

@ Now suppose that at least one bit of |m1| can be found in X, and one bit
of |m2| can be found in Y. This gives us two pieces of information about
XY, and we can freely choose which to go for: we may as well pick |m1| and
say that one bit of |m1| can be found in XY. In principle we ought to choose
the rarest for best effect, but that's too much work.

=
int Preform::concatenate_dw(int m1, int m2) {
	if (m1 == 0) return m2; /* the case where we have no information about X */
	if (m2 == 0) return m1; /* and about Y */
	return m1; /* the general case discussed above */
}

@ Now suppose that each word of X matches at least one bit of |m1|, and
similarly for Y and |m2|. Then each word of XY matches at least one bit of
the union, so:

=
int Preform::concatenate_cw(int m1, int m2) {
	if (m1 == 0) return 0; /* the case where we have no information about X */
	if (m2 == 0) return 0; /* and about Y */
	return m1 | m2; /* the general case discussed above */
}

@ The first word of XY is the first word of X, so:

=
int Preform::concatenate_fs(int m1, int m2) {
	return m1;
}

int Preform::concatenate_fw(int m1, int m2) {
	return m1;
}

@ The second operation is disjunction: we'll write X/Y, meaning that the text
has to match either X or Y. This is easier, since it amounts to a disguised
form of de Morgan's laws.

=
void Preform::disjoin_rreq(range_requirement *req, range_requirement *with) {
	req->DS_req = Preform::disjoin_ds(req->DS_req, with->DS_req);
	req->DW_req = Preform::disjoin_dw(req->DW_req, with->DW_req);
	req->CS_req = Preform::disjoin_cs(req->CS_req, with->CS_req);
	req->CW_req = Preform::disjoin_cw(req->CW_req, with->CW_req);
	req->FS_req = Preform::disjoin_fs(req->FS_req, with->FS_req);
	req->FW_req = Preform::disjoin_fw(req->FW_req, with->FW_req);
}

@ Suppose all of the bits of |m1| are found in X, and all of the bits of |m2|
are found in Y. Then the best we can say is that all of the bits in the
intersection of these two sets are found in X/Y. (If they have no bits in
common, we can't say anything.)

=
int Preform::disjoin_ds(int m1, int m2) {
	return m1 & m2;
}

@ Similarly, suppose all of the bits of |m1| are found in every word of X,
and all of those of |m2| are in every word of Y. The most which can be said
about every word of XY is to take the intersection, so:

=
int Preform::disjoin_cs(int m1, int m2) {
	return m1 & m2;
}

@ Now suppose that at least one bit of |m1| can be found in X, and one bit
of |m2| can be found in Y. All we can say is that one of these various bits
must be found in X/Y, so:

=
int Preform::disjoin_dw(int m1, int m2) {
	if (m1 == 0) return 0; /* the case where we have no information about X */
	if (m2 == 0) return 0; /* and about Y */
	return m1 | m2; /* the general case discussed above */
}

@ And exactly the same is true for conjunctions:

=
int Preform::disjoin_cw(int m1, int m2) {
	if (m1 == 0) return 0; /* the case where we have no information about X */
	if (m2 == 0) return 0; /* and about Y */
	return m1 | m2; /* the general case discussed above */
}

int Preform::disjoin_fw(int m1, int m2) {
	return Preform::disjoin_cw(m1, m2);
}

int Preform::disjoin_fs(int m1, int m2) {
	return Preform::disjoin_cs(m1, m2);
}

void Preform::clear_rreq(range_requirement *req) {
	req->DS_req = 0; req->DW_req = 0;
	req->CS_req = 0; req->CW_req = 0;
	req->FS_req = 0; req->FW_req = 0;
}

void Preform::atomic_rreq(range_requirement *req, nonterminal *nt) {
	int b = Preform::nt_bitmap_bit(nt);
	req->DS_req = b; req->DW_req = b;
	req->CS_req = b; req->CW_req = b;
	req->FS_req = 0; req->FW_req = 0;
}

void Preform::log_range_requirement(range_requirement *req) {
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
int Preform::ptoken_width(ptoken *pt) {
	int min, max;
	Preform::ptoken_extrema(pt, &min, &max);
	if (min != max) return PTOKEN_ELASTIC;
	return min;
}

@ An interesting point here is that the negation of a ptoken can in principle
have any length, except that we specified |^ example| to match only a single
word -- any word other than "example". So the extrema for |^ example| are
1 and 1, whereas for |^ <sample-nonterminal>| they would have to be 0 and
infinity.

=
void Preform::ptoken_extrema(ptoken *pt, int *min_t, int *max_t) {
	*min_t = 1; *max_t = 1;
	if (pt->negated_ptoken) {
		if (pt->ptoken_category != FIXED_WORD_PTC) { *min_t = 0; *max_t = INFINITE_WORD_COUNT; }
		return;
	}
	switch (pt->ptoken_category) {
		case NONTERMINAL_PTC:
			Preform::optimise_nt(pt->nt_pt); /* recurse as needed to find its extrema */
			*min_t = pt->nt_pt->min_nt_words;
			*max_t = pt->nt_pt->max_nt_words;
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

@h Parsing.
Since I have found that well-known computer programmers look at me strangely
when I tell them that Inform doesn't use |yacc|, or |antlr|, or for that
matter any of the elegant theory of LALR parsers, perhaps an explanation
is called for.

One reason is that I am sceptical that formal grammars specify natural language
terribly well -- which is ironic, considering that the relevant computer
science, dating from the 1950s and 1960s, was strongly influenced by Noam
Chomsky's generative linguistics. Such formal descriptions tend to be too rigid
to be applied universally. The classical use case for |yacc| is to manage
hierarchies of associative operators on different levels: well, natural language
doesn't have those.

Another reason is that |yacc|-style grammars tend to react badly to uncompliant
input: that is, they correctly reject it, but are bad at diagnosing the
problem, and at recovering their wits afterwards. For Inform purposes, this
would be too sloppy: the user more often miscompiles than compiles, and quality
lies in how good our problem messages are in reply.

Lastly, there are two pragmatic reasons. In order to make Preform grammar
extensible, we couldn't use a parser-compiler like |yacc| anyway: we have to
interpret our grammar, not compile code to parse it. And we also want speed;
folk wisdom has it that |yacc| parsers are about half as fast as a shrewdly
hand-coded equivalent. (|gcc| abandoned the use of |bison| for exactly this
reason some years ago.) Until Preform's arrival in February 2011, Inform had a
hard-coded syntax analyser scattered throughout its code, which often made what
were provably the minimum possible number of comparisons. Even Preform's
parser is intentionally lean.

@ Make of that apologia what you will. Speed is important in the following
code, but not critical: I optimised it until profiling showed that Inform spent
only about 6\% of its time here.

=
int ptraci = FALSE; /* in this mode, we trace parsing to the debugging log */
int preform_lookahead_mode = FALSE; /* in this mode, we are looking ahead */
int fail_nonterminal_quantum = 0; /* jump forward by this many words in lookahead */
void *preform_backtrack = NULL; /* position to backtrack from in voracious internal */

int Preform::parse_nt_against_word_range(nonterminal *nt, wording W, int *result,
	void **result_p) {
	time_t start_of_nt = time(0);
	if (nt == NULL) internal_error("can't parse a null nonterminal");
	#ifdef INSTRUMENTED_PREFORM
	nt->nonterminal_tries++;
	#endif
	int success_rval = TRUE; /* what to return in the event of a successful match */
	fail_nonterminal_quantum = 0;

	int teppic = ptraci; /* Teppic saves Ptraci */
	ptraci = nt->watched;

	if (ptraci) {
		if (preform_lookahead_mode) ptraci = FALSE;
		else LOG("%V: <%W>\n", nt->nonterminal_id, W);
	}

	int input_length = Wordings::length(W);
	if ((nt->max_nt_words == 0) ||
		((input_length >= nt->min_nt_words) && (input_length <= nt->max_nt_words))) {
		@<Try to match the input text to the nonterminal@>;
	}

	@<The nonterminal has failed to parse@>;
}

@ The routine ends here...

@<The nonterminal has failed to parse@> =
	if (ptraci) LOG("Failed %V (time %d)\n", nt->nonterminal_id, time(0)-start_of_nt);
	ptraci = teppic;
	return FALSE;

@ ...unless a match was made, in which case it ends here. At this point |Q|
and |QP| will hold the results of the match.

@<The nonterminal has successfully parsed@> =
	if (result) *result = Q; if (result_p) *result_p = QP;
	most_recent_result = Q; most_recent_result_p = QP;
	#ifdef INSTRUMENTED_PREFORM
	nt->nonterminal_matches++;
	#endif
	ptraci = teppic;
	return success_rval;

@ Here we see that a successful voracious NT returns the word number it got
to, rather than |TRUE|. Otherwise this is straightforward: we delegate to
an internal NT, or try all possible productions for an external one.

@d RANGE_OPTIMISATION_LENGTH 10

@<Try to match the input text to the nonterminal@> =
	int unoptimised = FALSE;
	if ((Wordings::empty(W)) || (input_length >= RANGE_OPTIMISATION_LENGTH))
		unoptimised = TRUE;
	if (nt->internal_definition) {
		if (nt->voracious) unoptimised = TRUE;
		if ((unoptimised) || (Preform::nt_bitmap_violates(W, &(nt->nonterminal_req)) == FALSE)) {
			int r, Q; void *QP = NULL;
			if (Wordings::first_wn(W) >= 0) r = (*(nt->internal_definition))(W, &Q, &QP);
			else { r = FALSE; Q = 0; }
			if (r) {
				if (nt->voracious) success_rval = r;
				if (ptraci) LOG("Succeeded %d\n", time(0)-start_of_nt);
				@<The nonterminal has successfully parsed@>;
			}
		} else {
			if (ptraci) {
				LOG("%V: <%W> violates ", nt->nonterminal_id, W);
				Preform::log_range_requirement(&(nt->nonterminal_req));
				LOG("\n");
			}
		}
	} else {
		if ((unoptimised) || (Preform::nt_bitmap_violates(W, &(nt->nonterminal_req)) == FALSE)) {
			void *acc_result = NULL;
			production_list *pl;
			for (pl = nt->first_production_list; pl; pl = pl->next_production_list) {
				PREFORM_LANGUAGE_TYPE *nl = pl->definition_language;
				if ((language_of_source_text == NULL) || (language_of_source_text == nl)) {
					production *pr;
					int last_v = FALSE;
					for (pr = pl->first_production; pr; pr = pr->next_production) {
						int violates = FALSE;
						if (unoptimised == FALSE) {
							if (pr->production_req.ditto_flag) violates = last_v;
							else violates = Preform::nt_bitmap_violates(W, &(pr->production_req));
							last_v = violates;
						}
						if (violates == FALSE) {
							@<Parse the given production@>;
						} else {
							if (ptraci) {
								LOG("production in %V: ", nt->nonterminal_id);
								Preform::log_production(pr, FALSE);
								LOG(": <%W> violates ", W);
								Preform::log_range_requirement(&(pr->production_req));
								LOG("\n");
							}
						}
					}
				}
			}
			if ((nt->multiplicitous) && (acc_result)) {
				int Q = TRUE; void *QP = acc_result;
				@<The nonterminal has successfully parsed@>;
			}
		} else {
			if (ptraci) {
				LOG("%V: <%W> violates ", nt->nonterminal_id, W);
				Preform::log_range_requirement(&(nt->nonterminal_req));
				LOG("\n");
			}
		}
	}

@ So from here on we look only at the external case, where we're parsing the
text against a production.

@<Parse the given production@> =
	if (ptraci) {
		LOG_INDENT;
		@<Log the production match number@>;
		Preform::log_production(pr, FALSE); LOG("\n");
	}
	#ifdef INSTRUMENTED_PREFORM
	pr->production_tries++;
	#endif

	int slow_scan_needed = FALSE;
	#ifdef CORE_MODULE
	parse_node *added_to_result = NULL;
	#endif
	if ((input_length >= pr->min_pr_words) && (input_length <= pr->max_pr_words)) {
		int Q; void *QP = NULL;
		@<Actually parse the given production, going to Fail if we can't@>;

		#ifdef INSTRUMENTED_PREFORM /* record the sentence containing the longest example */
		pr->production_matches++;
		if (Wordings::length(pr->sample_text) < Wordings::length(W)) pr->sample_text = W;
		#endif

		if (ptraci) {
			@<Log the production match number@>;
			LOG("succeeded (%s): ", (slow_scan_needed)?"slowly":"quickly");
			LOG("result: %d\n", Q); LOG_OUTDENT;
		}
		@<The nonterminal has successfully parsed@>;
	}

	Fail:
	if (ptraci) {
		@<Log the production match number@>;
		#ifdef CORE_MODULE
		if (added_to_result) LOG("added to result (%s): $P\n",
			(slow_scan_needed)?"slowly":"quickly", added_to_result);
		else
		#endif
			LOG("failed (%s)\n", (slow_scan_needed)?"slowly":"quickly");
		LOG_OUTDENT;
	}

@<Log the production match number@> =
	if (pr->match_number >= 26) {
		LOG("production /%c%c/: ", 'a'+pr->match_number-26, 'a'+pr->match_number-26);
	} else {
		LOG("production /%c/: ", 'a'+pr->match_number);
	}

@ Okay. So, the strategy is: a fast scan checking the easy things; if that's
not sufficient, a slow scan checking the rest; then making sure brackets
match, if there were any, and last composing the intermediate results into
the final ones. For example, if the production is

	|adjust the <achingly-slow> to the <exhaustive> at once|

then the fast scan verifies the presence of "adjust the" and "at once";
the slow scan next looks for all occurrences of "to the", the single strut
for this production; and only then does it test the two slow nonterminals
on the intervening words, if there are any.

@<Actually parse the given production, going to Fail if we can't@> =
	int checked[MAX_PTOKENS_PER_PRODUCTION];
	int intermediates[MAX_RESULTS_PER_PRODUCTION];
	void *intermediate_ps[MAX_RESULTS_PER_PRODUCTION];
	int parsed_open_pos = -1, parsed_close_pos = -1;

	@<Try a fast scan through the production@>;
	if (slow_scan_needed) @<Try a slow scan through the production@>;

	if ((parsed_open_pos >= 0) && (parsed_close_pos >= 0))
		if (Wordings::paired_brackets(Wordings::new(parsed_open_pos, parsed_close_pos)) == FALSE)
			goto Fail;
	@<Compose and store the result@>;

@ Once we have successfully matched the line, we need to compose the
intermediate results into a final result. If |inweb| has compiled a compositor
routine for the nonterminal, we call it: note that it can then return |FALSE|
to fail the production after all, and can even return |FAIL_NONTERMINAL| to
abandon not just this production, but all of the productions. (This is quite
useful as a way to put exceptional syntaxes into the grammar, since it can
make subsequent productions only available in some cases.)

If there's no compositor then the integer result is the production's number,
and the pointer result is null.

@d FAIL_NONTERMINAL -100000
@d FAIL_NONTERMINAL_TO FAIL_NONTERMINAL+1000

@<Compose and store the result@> =
	if (nt->result_compositor) {
		intermediates[0] = pr->match_number;
		int f = (*(nt->result_compositor))(&Q, &QP, intermediates, intermediate_ps, nt->range_result, W);
		if (f == FALSE) goto Fail;
		if (nt->multiplicitous) {
			#ifdef CORE_MODULE
			added_to_result = QP;
			acc_result = (void *) ParseTree::add_possible_reading((parse_node *) acc_result, QP, W);
			#endif
			goto Fail;
		}
		if ((f >= FAIL_NONTERMINAL) && (f < FAIL_NONTERMINAL_TO)) {
			fail_nonterminal_quantum = f - FAIL_NONTERMINAL;
			@<The nonterminal has failed to parse@>;
		}
	} else {
		Q = pr->match_number; QP = NULL;
	}

@ In the fast scan, we check that all fixed words with known positions
are in those positions.

@<Try a fast scan through the production@> =
	ptoken *pt;
	int wn = -1, tc;
	for (pt = pr->first_ptoken, tc = 0; pt; pt = pt->next_ptoken, tc++) {
		if (pt->ptoken_is_fast) {
			int p = pt->ptoken_position;
			if (p > 0) wn = Wordings::first_wn(W)+p-1;
			else if (p < 0) wn = Wordings::last_wn(W)+p+1;
			if (Preform::parse_fixed_word_ptoken(wn, pt) == FALSE) {
				slow_scan_needed = FALSE;
				goto Fail; /* the word should have been here, and it wasn't */
			}
			if (pt->ve_pt == OPENBRACKET_V) parsed_open_pos = wn;
			if (pt->ve_pt == CLOSEBRACKET_V) parsed_close_pos = wn;
			checked[tc] = wn;
		} else {
			slow_scan_needed = TRUE;
			checked[tc] = -1;
		}
	}
	if ((slow_scan_needed == FALSE) && (wn != Wordings::last_wn(W))) goto Fail; /* input text goes on further */

@ The slow scan is more challenging. We want to loop through all possible
strut positions, where by "possible" we mean that
$$ s_i+\ell_i <= s_{i+1}, \quad i = 0, 1, ..., s $$
and that for each $i$ the $i$-th strut matches the text beginning at $s_i$.

@<Try a slow scan through the production@> =
	int spos[MAX_STRUTS_PER_PRODUCTION]; /* word numbers for where we are trying the struts */
	int NS = pr->no_struts;
	@<Start from the lexicographically earliest strut position@>;
	ptoken *backtrack_token = NULL;
	int backtrack_index = -1, backtrack_to = -1, backtrack_tc = -1;
	while (TRUE) {
		@<Try a slow scan with the current strut positions@>;
		break;
		FailThisStrutPosition: ;
		if (backtrack_token) continue;
		@<Move on to the next strut position@>;
	}

@ We start by finding the lexicographically earliest, i.e., we find the earliest
possible position for $s_0$, then the earliest position from $s_0+\ell_0$ for
$s_1$, and so on. (Our wildcards are not greedy: we match with shortest possible
text rather than longest.)

In all of the code below, the general case with |NS| greater than 1 is actually
valid code for all cases, but experiment shows about a 5\% speed gain from
handling the popular case of one strut separately.

@<Start from the lexicographically earliest strut position@> =
	if (NS == 1) {
		spos[0] = Preform::next_strut_posn_after(W, pr->struts[0], pr->strut_lengths[0], Wordings::first_wn(W));
		if (spos[0] == -1) goto Fail;
	} else if (NS > 1) {
		int s, from = Wordings::first_wn(W);
		for (s=0; s<NS; s++) {
			spos[s] = Preform::next_strut_posn_after(W, pr->struts[s], pr->strut_lengths[s], from);
			if (spos[s] == -1) goto Fail;
			from = spos[s] + pr->strut_lengths[s] + 1;
		}
	}

@ In the general case, we move the final strut forward if we can; if we can't,
we move the penultimate one, then move the final one to the first subsequent
position valid for it; and so on. Ultimately this results in the first strut
being unable to move forwards, at which point, we've lost.

@<Move on to the next strut position@> =
	if (NS == 0) goto Fail;
	else if (NS == 1) {
		spos[0] = Preform::next_strut_posn_after(W, pr->struts[0], pr->strut_lengths[0], spos[0]+1);
		if (spos[0] == -1) goto Fail;
	} else if (NS > 1) {
		int s;
		for (s=NS-1; s>=0; s--) {
			int n = Preform::next_strut_posn_after(W, pr->struts[s], pr->strut_lengths[s], spos[s]+1);
			if (n != -1) { spos[s] = n; break; }
		}
		if (s == -1) goto Fail;
		int from = spos[s] + 1; s++;
		for (; s<NS; s++) {
			spos[s] = Preform::next_strut_posn_after(W, pr->struts[s], pr->strut_lengths[s], from);
			if (spos[s] == -1) goto Fail;
			from = spos[s] + pr->strut_lengths[s] + 1;
		}
	}

@ We can now forget about struts, thankfully, and check the remaining unchecked
ptokens.

@<Try a slow scan with the current strut positions@> =
	int wn = Wordings::first_wn(W), tc;
	ptoken *pt, *nextpt;
	if (backtrack_token) {
		pt = backtrack_token; nextpt = backtrack_token->next_ptoken;
		tc = backtrack_tc; wn = backtrack_to;
		goto Reenter;
	}
	for (pt = pr->first_ptoken, nextpt = (pt)?(pt->next_ptoken):NULL, tc = 0;
		pt;
		pt = nextpt, nextpt = (pt)?(pt->next_ptoken):NULL, tc++) {
		Reenter: ;
		int known_pos = checked[tc];
		if (known_pos >= 0) {
			if (wn > known_pos) goto Fail; /* a theoretical possibility if strut lookahead overreaches */
			wn = known_pos+1;
		} else {
			if (pt->range_starts >= 0) nt->range_result[pt->range_starts] = Wordings::one_word(wn);
			switch (pt->ptoken_category) {
				case FIXED_WORD_PTC: @<Match a fixed word ptoken@>; break;
				case SINGLE_WILDCARD_PTC: @<Match a single wildcard ptoken@>; break;
				case MULTIPLE_WILDCARD_PTC: @<Match a multiple wildcard ptoken@>; break;
				case POSSIBLY_EMPTY_WILDCARD_PTC: @<Match a possibly empty wildcard ptoken@>; break;
				case NONTERMINAL_PTC: @<Match a nonterminal ptoken@>; break;
			}
			if (pt->range_ends >= 0)
				nt->range_result[pt->range_ends] = Wordings::up_to(nt->range_result[pt->range_ends], wn-1);
		}
	}
	if (wn != Wordings::last_wn(W)+1) goto FailThisStrutPosition;

@<Match a fixed word ptoken@> =
	int q = Preform::parse_fixed_word_ptoken(wn, pt);
	if (q == FALSE) goto FailThisStrutPosition;
	if (pt->ve_pt == OPENBRACKET_V) parsed_open_pos = wn;
	if (pt->ve_pt == CLOSEBRACKET_V) parsed_close_pos = wn;
	wn++;

@<Match a single wildcard ptoken@> =
	wn++;

@<Match a multiple wildcard ptoken@> =
	if (wn > Wordings::last_wn(W)) goto FailThisStrutPosition;
	int wt;
	@<Calculate how much to stretch this elastic ptoken@>;
	if (wn > wt) goto FailThisStrutPosition; /* zero length */
	if (pt->balanced_wildcard) {
		int i, bl = 0;
		for (i=wn; i<=wt; i++) {
			if ((Lexer::word(i) == OPENBRACKET_V) || (Lexer::word(i) == OPENBRACE_V)) bl++;
			if ((Lexer::word(i) == CLOSEBRACKET_V) || (Lexer::word(i) == CLOSEBRACE_V)) {
				bl--;
				if (bl < 0) goto FailThisStrutPosition;
			}
		}
		if (bl != 0) goto FailThisStrutPosition;
	}
	wn = wt+1;

@<Match a possibly empty wildcard ptoken@> =
	int wt;
	@<Calculate how much to stretch this elastic ptoken@>;
	wn = wt+1;

@ A voracious nonterminal is offered the entire rest of the word range, and
returns how much it ate. Otherwise, we offer the maximum amount of space
available: if, for word-count reasons, that's never going to match, then
we rely on the recursive call to |Preform::parse_nt_against_word_range| returning a
quick no.

@<Match a nonterminal ptoken@> =
	if ((wn > Wordings::last_wn(W)) && (pt->nt_pt->min_nt_words > 0)) goto FailThisStrutPosition;
	int wt;
	if (pt->nt_pt->voracious) wt = Wordings::last_wn(W);
	else if ((pt->nt_pt->min_nt_words > 0) && (pt->nt_pt->min_nt_words == pt->nt_pt->max_nt_words))
		wt = wn + pt->nt_pt->min_nt_words - 1;
	else @<Calculate how much to stretch this elastic ptoken@>;

	if (pt == backtrack_token) {
		if (ptraci)
			LOG("Reached backtrack position %V: <%W>\n",
				pt->nt_pt->nonterminal_id, Wordings::new(wn, wt));
		preform_backtrack = intermediate_ps[pt->result_index];
	}
	if (ptraci) LOG_INDENT;
	int q = Preform::parse_nt_against_word_range(pt->nt_pt, Wordings::new(wn, wt),
		&(intermediates[pt->result_index]), &(intermediate_ps[pt->result_index]));
	if (ptraci) LOG_OUTDENT;
	if (pt == backtrack_token) { preform_backtrack = NULL; backtrack_token = NULL; }
	if (pt->nt_pt->voracious) {
		if (q > 0) { wt = q; q = TRUE; }
		else if (q < 0) { wt = -q; q = TRUE;
			backtrack_index = pt->result_index; backtrack_to = wn;
			backtrack_token = pt; backtrack_tc = tc;
			if (ptraci)
				LOG("Set backtrack position %V: <%W>\n",
					pt->nt_pt->nonterminal_id, Wordings::new(wn, wt));
		} else { wt = wn; }
	}
	if (pt->negated_ptoken) q = q?FALSE:TRUE;
	if (q == FALSE) goto FailThisStrutPosition;
	if (pt->nt_pt->max_nt_words > 0) wn = wt+1;

@ How much text from the input should this ptoken match? We feed it as much
as possible, and to calculate that, we must either be at the end of the run,
or else know exactly where the next ptoken starts: because its position is
known, or because it's a strut.

This is why two elastic nonterminals in a row won't parse correctly:

	|frog <amphibian> <pond-preference> toad|

Preform is unable to work out where the central boundary will occur. In theory
it should try every possibility. But that's inefficient: in practice the
solution is to write the grammar to minimise these cases, and then to set up
<amphibian> as a voracious token, so that it decides the boundary position
for itself. (If <amphibian> is not voracious, the following calculation
probably gives the wrong answer.)

@<Calculate how much to stretch this elastic ptoken@> =
	ptoken *lookahead = nextpt;
	if (lookahead == NULL) wt = Wordings::last_wn(W);
	else {
		int p = lookahead->ptoken_position;
		if (p > 0) wt = Wordings::first_wn(W)+p-2;
		else if (p < 0) wt = Wordings::last_wn(W)+p;
		else if (lookahead->strut_number >= 0) wt = spos[lookahead->strut_number]-1;
		else if ((lookahead->nt_pt)
			&& (pt->negated_ptoken == FALSE)
			&& (Preform::ptoken_width(pt) == PTOKEN_ELASTIC)) {
			wt = -1;
		 	nonterminal *target = lookahead->nt_pt;
		 	int save_preform_lookahead_mode = preform_lookahead_mode;
		 	preform_lookahead_mode = TRUE;
			for (int j = wn+1; j <= Wordings::last_wn(W); j++) {
				if (Preform::parse_nt_against_word_range(target, Wordings::new(j, Wordings::last_wn(W)), NULL, NULL)) {
					if ((pt->nt_pt == NULL) ||
						(Preform::parse_nt_against_word_range(pt->nt_pt, Wordings::new(wn, j-1), NULL, NULL))) {
						wt = j-1; break;
					}
				} else {
					if (fail_nonterminal_quantum > 0) j += fail_nonterminal_quantum - 1;
				}
			}
			preform_lookahead_mode = save_preform_lookahead_mode;
			if (wt < 0) goto FailThisStrutPosition;
		} else wt = wn;
	}

@ Here we find the next possible match position for the strut beginning |start|
and of width |len| in words, which begins at word |from| or after. Note that
the strut might run up right to the end of the input text: for example, in

	|neckties ... tied ***|

the word "tied" is a strut, because the |***| makes its position uncertain,
but since |***| might match the empty text, "tied" might legally be the
last word in the input text.

=
int Preform::next_strut_posn_after(wording W, ptoken *start, int len, int from) {
	int last_legal_position = Wordings::last_wn(W) - len + 1;
	while (from <= last_legal_position) {
		ptoken *pt;
		int pos = from;
		for (pt = start; pt; pt = pt->next_ptoken) {
			if (pt->ptoken_category == FIXED_WORD_PTC) {
				if (Preform::parse_fixed_word_ptoken(pos, pt)) pos++;
				else break;
			} else {
				int q = Preform::parse_nt_against_word_range(pt->nt_pt,
					Wordings::new(pos, pos+pt->nt_pt->max_nt_words-1),
					NULL, NULL);
				if (pt->negated_ptoken) q = q?FALSE:TRUE;
				if (q) pos += pt->nt_pt->max_nt_words;
				else break;
			}
			if (pos-from >= len) return from;
		}
		from++;
	}
	return -1;
}

@ Finally, a single fixed word, with its annotations and alternatives.

=
int Preform::parse_fixed_word_ptoken(int wn, ptoken *pt) {
	vocabulary_entry *ve = Lexer::word(wn);
	int m = pt->disallow_unexpected_upper;
	ptoken *alt;
	for (alt = pt; alt; alt = alt->alternative_ptoken)
		if ((ve == alt->ve_pt) &&
			((m == FALSE) || (Word::unexpectedly_upper_case(wn) == FALSE)))
			return (pt->negated_ptoken)?FALSE:TRUE;
	return (pt->negated_ptoken)?TRUE:FALSE;
}

@h Reading Preform syntax from a file.

=
wording Preform::load_from_file(filename *F) {
	feed_t id = Feeds::begin();
	if (TextFiles::read(F, FALSE,
		NULL, FALSE, Preform::preform_helper, NULL, NULL) == FALSE)
		internal_error("Unable to open Preform definition");
	return Feeds::end(id);
}

@ We simply feed the lines one at a time:

=
void Preform::preform_helper(text_stream *item_name,
	text_file_position *tfp, void *vnl) {
	WRITE_TO(item_name, "\n");
	Feeds::feed_stream_punctuated(item_name, PREFORM_PUNCTUATION_MARKS);
}
