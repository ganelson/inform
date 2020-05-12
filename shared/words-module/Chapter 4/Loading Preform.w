[LoadPreform::] Loading Preform.

To read in structural definitions of natural language written in the
meta-language Preform.

@h Introduction.
The parser reads source text against a specific language only, if
|language_of_source_text| is set; or, if it isn't, from any language.

@default NATURAL_LANGUAGE_WORDS_TYPE void

=
NATURAL_LANGUAGE_WORDS_TYPE *language_of_source_text = NULL;

void LoadPreform::set_language_of_syntax(NATURAL_LANGUAGE_WORDS_TYPE *L) {
	language_of_source_text = L;
}

@h Reading Preform syntax from a file.

=
wording LoadPreform::load_for_language(filename *F, NATURAL_LANGUAGE_WORDS_TYPE *L) {
	LoadPreform::set_language_to_parse(L);
	return LoadPreform::load(F);
}

wording LoadPreform::load(filename *F) {
	feed_t id = Feeds::begin();
	if (TextFiles::read(F, FALSE,
		NULL, FALSE, LoadPreform::load_helper, NULL, NULL) == FALSE)
		internal_error("Unable to open Preform definition");
	return Feeds::end(id);
}

@ We simply feed the lines one at a time. Preform is parsed with the regular
lexer, using the following set of characters as word-breaking punctuation marks:

@d PREFORM_PUNCTUATION_MARKS L"{}[]_^?&\\"

=
void LoadPreform::load_helper(text_stream *item_name,
	text_file_position *tfp, void *vnl) {
	WRITE_TO(item_name, "\n");
	Feeds::feed_text_punctuated(item_name, PREFORM_PUNCTUATION_MARKS);
}

@h Implementation.
We must first clarify how word ranges, once matched in the parser, will be
stored. Within each production, word ranges are numbered upwards from 1. Thus:
= (text as InC)
	man with ... on his ...
=
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
	CLASS_DEFINITION
} nonterminal;

@ Each (external) nonterminal is then defined by lists of productions:
potentially one for each language, though only English is required to define
all of them, and English will always be the first in the list of lists.

=
typedef struct production_list {
	NATURAL_LANGUAGE_WORDS_TYPE *definition_language;
	struct production *first_production;
	struct production_list *next_production_list;
	struct match_avinue *as_avinue; /* when compiled to a trie rather than for Preform */
	CLASS_DEFINITION
} production_list;

@ So now we reach the production, which encodes a typical "row" of grammar;
see the examples above. A production is another list, of "ptokens" (the
"p" is silent). For example, the production
= (text as InC)
	runner no <cardinal-number>
=
contains three ptokens. (Note that the stroke sign and the defined-by sign are
not ptokens; they divide up productions, but aren't part of them.)

Like nonterminals, productions also count the minimum and maximum words
matched: in the above example, both are 3.

There's a new idea here as well, though: struts. A "strut" is a run of
ptokens in the interior of the production whose position relative to the
ends is not known. For example, if we match:
= (text as InC)
	frogs like ... but not ... to eat
=
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
	CLASS_DEFINITION
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
= (text as InC)
	make ... from {rice ... onions} and peppers
=
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
	CLASS_DEFINITION
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
void LoadPreform::log(void) {
	int detailed = FALSE;
	nonterminal *nt;
	LOOP_OVER(nt, nonterminal) {
		#ifdef INSTRUMENTED_PREFORM
		LOG("%d/%d: ", nt->nonterminal_matches, nt->nonterminal_tries);
		#endif
		LOG("%V: ", nt->nonterminal_id);
		Optimiser::log_range_requirement(&(nt->nonterminal_req));
		LOG("\n");
		if (nt->internal_definition) LOG("  (internal)\n");
		else {
			production_list *pl;
			for (pl = nt->first_production_list; pl; pl = pl->next_production_list) {
				LOG("  $J:\n", pl->definition_language);
				production *pr;
				for (pr = pl->first_production; pr; pr = pr->next_production) {
					LOG("   "); LoadPreform::log_production(pr, detailed);
					#ifdef INSTRUMENTED_PREFORM
					LOG("      %d/%d: ", pr->production_matches, pr->production_tries);
					if (Wordings::nonempty(pr->sample_text)) LOG("<%W>", pr->sample_text);
					#endif
					LOG(" ==> ");
					Optimiser::log_range_requirement(&(pr->production_req));
					LOG("\n");
				}
			}
		}
		LOG("  min %d, max %d\n\n", nt->min_nt_words, nt->max_nt_words);
	}
	LOG("%d req bits.\n", no_req_bits);
}

@ =
void LoadPreform::log_production(production *pr, int detailed) {
	if (pr->first_ptoken == NULL) LOG("<empty-production>");
	ptoken *pt;
	for (pt = pr->first_ptoken; pt; pt = pt->next_ptoken) {
		LoadPreform::log_ptoken(pt, detailed);
		LOG(" ");
	}
}

@ =
void LoadPreform::log_ptoken(ptoken *pt, int detailed) {
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
void LoadPreform::write_ptoken(OUTPUT_STREAM, ptoken *pt) {
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
	nonterminal *nt = LoadPreform::detect_nonterminal(Lexer::word(Wordings::first_wn(W)));
	if (nt) { *XP = nt; return TRUE; }
	return FALSE;
}

@ To use which, the debugging log code needs:

=
void LoadPreform::watch(nonterminal *nt, int state) {
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
void LoadPreform::begin(void) {
	CAPITAL_K_V      = Vocabulary::entry_for_text(L"k");
	CAPITAL_L_V      = Vocabulary::entry_for_text(L"l");
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

	@<Register the internal and source-code-referred-to nonterminals@>;
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
	identifier = LoadPreform::find_nonterminal(Vocabulary::entry_for_text(quotedname));
	identifier->result_compositor = identifier##C;

@d INTERNAL_NONTERMINAL(quotedname, identifier, min, max)
	identifier = LoadPreform::find_nonterminal(Vocabulary::entry_for_text(quotedname));
	identifier->min_nt_words = min; identifier->max_nt_words = max;
	identifier->internal_definition = identifier##R;
	identifier->marked_internal = TRUE;

@ Parsing Preform is exactly what Preform would do elegantly, but of course,
for chicken-and-egg reasons, we need to do the job by hand. Fortunately the
syntax is very simple.

=
NATURAL_LANGUAGE_WORDS_TYPE *language_being_read_by_Preform = NULL;
void LoadPreform::set_language_to_parse(NATURAL_LANGUAGE_WORDS_TYPE *L) {
	language_being_read_by_Preform = L;
}

int LoadPreform::parse(wording W, int break_first) {
	if (break_first) {
		TEMPORARY_TEXT(wd);
		WRITE_TO(wd, "%+W", Wordings::one_word(Wordings::first_wn(W)));
		W = Feeds::feed_text_punctuated(wd, PREFORM_PUNCTUATION_MARKS);
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
	Optimiser::optimise_counts();
	return nonterminals_declared;
}

@ We either switch to an existing natural language, or create a new one.

@<Parse a definition language switch@> =
	TEMPORARY_TEXT(lname);
	WRITE_TO(lname, "%W", Wordings::one_word(wn+1));
	NATURAL_LANGUAGE_WORDS_TYPE *nl = PREFORM_LANGUAGE_FROM_NAME(lname);
	if (nl == NULL) {
		LOG("Missing: %S\n", lname);
		internal_error("tried to define for missing language");
	}
	DISCARD_TEXT(lname);
	language_being_read_by_Preform = nl;
	wn++;

@<Parse an internal nonterminal declaration@> =
	nonterminal *nt = LoadPreform::find_nonterminal(Lexer::word(wn));
	if (nt->first_production_list) internal_error("internal is defined");
	nt->marked_internal = TRUE;
	wn++;

@ The declaration continues until the end of the text, or until we reach a
paragraph break. Internally, it's a list of productions divided by stroke symbols.

@<Parse an external nonterminal declaration@> =
	nonterminal *nt = LoadPreform::find_nonterminal(Lexer::word(wn));
	production_list *pl;
	@<Find or create the production list for this language@>;
	wn += 2;
	int pc = 0;
	while (TRUE) {
		int x = wn;
		while ((x <= Wordings::last_wn(W)) && (Lexer::word(x) != STROKE_V) && (Lexer::word(x) != PARBREAK_V)) x++;
		if (wn < x) {
			production *pr = LoadPreform::new_production(Wordings::new(wn, x-1), nt, pc++);
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
nonterminal *LoadPreform::detect_nonterminal(vocabulary_entry *ve) {
	nonterminal *nt;
	LOOP_OVER(nt, nonterminal)
		if (ve == nt->nonterminal_id)
			return nt;
	return NULL;
}

nonterminal *LoadPreform::find_nonterminal(vocabulary_entry *ve) {
	nonterminal *nt = LoadPreform::detect_nonterminal(ve);
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
production *LoadPreform::new_production(wording W, nonterminal *nt, int pc) {
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

		ptoken *pt = LoadPreform::parse_slashed_chain(nt, pr, i, unescaped);
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
ptoken *LoadPreform::parse_slashed_chain(nonterminal *nt, production *pr, int wn, int unescaped) {
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
	if (breakme) AW = Feeds::feed_C_string_full(p, FALSE, L"/"); /* break only at slashes */

@<Parse the word range into a linked list of alternative ptokens@> =
	ptoken *alt = NULL;
	for (; Wordings::nonempty(AW); AW = Wordings::trim_first_word(AW))
		if (Lexer::word(Wordings::first_wn(AW)) != FORWARDSLASH_V) {
			int mode = unescaped;
			if (Wordings::length(AW) > 1) mode = FALSE;
			ptoken *latest = LoadPreform::new_ptoken(Lexer::word(Wordings::first_wn(AW)), mode, nt, pr->match_number);
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
ptoken *LoadPreform::new_ptoken(vocabulary_entry *ve, int unescaped, nonterminal *nt, int pc) {
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
		pt->nt_pt = LoadPreform::find_nonterminal(ve);
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
