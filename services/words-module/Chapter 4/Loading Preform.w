[LoadPreform::] Loading Preform.

To read in structural definitions of natural language written in the
meta-language Preform.

@h Reading Preform syntax from a file or text.
The parser reads source text against a specific language only, if
|primary_Preform_language| is set; or, if it isn't, from any language.

@default NATURAL_LANGUAGE_WORDS_TYPE void

=
NATURAL_LANGUAGE_WORDS_TYPE *primary_Preform_language = NULL;

int LoadPreform::load(filename *F, NATURAL_LANGUAGE_WORDS_TYPE *L) {
	primary_Preform_language = L;
	return LoadPreform::parse(LoadPreform::feed_from_Preform_file(F), L);
}

@ We simply feed the lines one at a time. Preform is parsed with the same
lexer as is used for Inform itself, but using the following set of characters
as word-breaking punctuation marks:

@d PREFORM_PUNCTUATION_MARKS L"{}[]_^?&\\"

=
wording LoadPreform::feed_from_Preform_file(filename *F) {
	feed_t id = Feeds::begin();
	if (TextFiles::read(F, FALSE,
		NULL, FALSE, LoadPreform::load_helper, NULL, NULL) == FALSE)
		internal_error("Unable to open Preform definition");
	return Feeds::end(id);
}

void LoadPreform::load_helper(text_stream *item_name, text_file_position *tfp,
	void *unused_state) {
	WRITE_TO(item_name, "\n");
	Feeds::feed_text_punctuated(item_name, PREFORM_PUNCTUATION_MARKS);
}

@ It is also possible to load additional Preform declarations from source
text in Inform, and when that happens, the following is called:

=
int LoadPreform::parse_text(text_stream *wd) {
	wording W = Feeds::feed_text_punctuated(wd, PREFORM_PUNCTUATION_MARKS);
	return LoadPreform::parse(W, primary_Preform_language);
}

@ Either way, then, all that remains is to write //LoadPreform::parse//. But
before we can get to that, we have to create the...

@h Reserved words in Preform.
The ideal tool with which to parse Preform definitions would be Preform, but
then how would we define the grammar required? So we will have to do this
by hand, and in particular, we have to define Preform's syntactic punctuation
marks explicitly. These are, in effect, the reserved words of the Preform
notational language. (Note the absence of the |==>| marker: that's stripped
out by //inweb// and never reaches the |Syntax.preform| file.)

The bare letters K and L are snuck in here for convenience. They aren't
actually used by anything in //words//, but are used for kind variables in
//kinds//.

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

vocabulary_entry *CAPITAL_K_V;
vocabulary_entry *CAPITAL_L_V;

@ =
void LoadPreform::create_punctuation(void) {
	AMPERSAND_V        = Vocabulary::entry_for_text(L"&");
	BACKSLASH_V        = Vocabulary::entry_for_text(L"\\");
	CARET_V            = Vocabulary::entry_for_text(L"^");
	COLONCOLONEQUALS_V = Vocabulary::entry_for_text(L":" ":=");
	QUESTIONMARK_V     = Vocabulary::entry_for_text(L"?");
	QUOTEQUOTE_V       = Vocabulary::entry_for_text(L"\"\"");
	SIXDOTS_V          = Vocabulary::entry_for_text(L"......");
	THREEASTERISKS_V   = Vocabulary::entry_for_text(L"***");
	THREEDOTS_V        = Vocabulary::entry_for_text(L"...");
	THREEHASHES_V      = Vocabulary::entry_for_text(L"###");
	UNDERSCORE_V       = Vocabulary::entry_for_text(L"_");
	language_V         = Vocabulary::entry_for_text(L"language");
    internal_V         = Vocabulary::entry_for_text(L"internal");

	CAPITAL_K_V        = Vocabulary::entry_for_text(L"k");
	CAPITAL_L_V        = Vocabulary::entry_for_text(L"l");
}

@h Parsing Preform.
The syntax of the |Syntax.preform| is, fortunately, very simple. At any given
time, we are parsing definitions for a given natural language |L|: for example,
English.

Note that Preform can contain comments in square brackets; but that the Lexer
has already removed any such.

=
int LoadPreform::parse(wording W, NATURAL_LANGUAGE_WORDS_TYPE *L) {
	NATURAL_LANGUAGE_WORDS_TYPE *current_natural_language = L;
	int declarations = 0;
	LOOP_THROUGH_WORDING(wn, W) {
		if (Lexer::word(wn) == PARBREAK_V) continue;
		if ((Wordings::last_wn(W) >= wn+1) && (Lexer::word(wn) == language_V))
			@<Parse a definition language switch@>
		else if ((Wordings::last_wn(W) >= wn+1) && (Lexer::word(wn+1) == internal_V))
			@<Parse an internal nonterminal declaration@>
		else if ((Wordings::last_wn(W) >= wn+2) && (Lexer::word(wn+1) == COLONCOLONEQUALS_V))
			@<Parse a regular nonterminal declaration@>
		else PreformUtilities::production_error(NULL, NULL,
			"syntax error in Preform declarations");
	}
	Optimiser::optimise_counts();
	return declarations;
}

@ We either switch to an existing natural language, or create a new one.

@<Parse a definition language switch@> =
	TEMPORARY_TEXT(lname)
	WRITE_TO(lname, "%W", Wordings::one_word(wn+1));
	NATURAL_LANGUAGE_WORDS_TYPE *nl = NULL;
	#ifdef PREFORM_LANGUAGE_FROM_NAME_WORDS_CALLBACK
	nl = PREFORM_LANGUAGE_FROM_NAME_WORDS_CALLBACK(lname);
	#endif
	if (nl == NULL) {
		LOG("Missing: %S\n", lname);
		PreformUtilities::production_error(NULL, NULL,
			"tried to define for missing language");
	}
	DISCARD_TEXT(lname)
	current_natural_language = nl;
	wn++;

@ Internal declarations appear as single lines in |Syntax.preform|.

@<Parse an internal nonterminal declaration@> =
	nonterminal *nt = Nonterminals::find(Lexer::word(wn));
	if (nt->first_pl)
		PreformUtilities::production_error(nt, NULL,
			"nonterminal internal in one definition and regular in another");
	nt->marked_internal = TRUE;
	wn++;
	declarations++;

@ Regular declarations are much longer and continue until the end of the text,
or until we reach a paragraph break. The body of such a declaration is a list
of productions divided by stroke symbols.

Note that an empty production is not recorded: e.g., if there are two consecutive
strokes, the gap between them will not be considered as a production, and the
second stroke will simply be ignored. I suppose this is arguably a syntax error
and could be rejected as such, but it does no harm.

@<Parse a regular nonterminal declaration@> =
	nonterminal *nt = Nonterminals::find(Lexer::word(wn));
	if (nt->marked_internal)
		PreformUtilities::production_error(nt, NULL,
			"nonterminal internal in one definition and regular in another");
	production_list *pl = LoadPreform::find_list_for_language(nt, current_natural_language);
	wn += 2; /* advance past the ID word and the |::=| word */
	int pc = 0;
	while (TRUE) {
		int x = wn;
		while ((x <= Wordings::last_wn(W)) && (Lexer::word(x) != STROKE_V) &&
			(Lexer::word(x) != PARBREAK_V)) x++;
		if (wn < x) {
			wording PW = Wordings::new(wn, x-1); wn = x;
			LoadPreform::add_production(LoadPreform::new_production(PW, nt, pc++), pl);
		}
		if ((wn > Wordings::last_wn(W)) || (Lexer::word(x) == PARBREAK_V)) break; /* reached end */
		wn++; /* advance past the stroke and continue */
	}
	wn--;
	declarations++;

@h Production lists.
Regular nonterminals are defined by a list of alternative possibilities
divided by vertical stroke characters; these are called "productions", for
reasons going back to computer science history.

However, the same nonterminal can have multiple lists, one for each language
where it's defined: for example, <competitor> could have one English and
one French definition both in memory at the same time. Each would be an
independent //production_list// object.

=
typedef struct production_list {
	NATURAL_LANGUAGE_WORDS_TYPE *definition_language;
	struct production_list *next_pl; /* in the list of PLs for a NT */
	struct production *first_pr; /* start of linked list of productions */
	struct match_avinue *as_avinue; /* when compiled to a trie rather than for Preform */
	CLASS_DEFINITION
} production_list;

@ =
production_list *LoadPreform::find_list_for_language(nonterminal *nt,
	NATURAL_LANGUAGE_WORDS_TYPE *L) {
	production_list *pl;
	for (pl = nt->first_pl; pl; pl = pl->next_pl)
		if (pl->definition_language == L)
			break;
	if (pl == NULL)	{
		pl = CREATE(production_list);
		pl->definition_language = L;
		pl->first_pr = NULL;
		pl->as_avinue = NULL;
		@<Place the new production list within the nonterminal@>;
	}
	return pl;
}

@<Place the new production list within the nonterminal@> =
	if (nt->first_pl == NULL) nt->first_pl = pl;
	else {
		production_list *p = nt->first_pl;
		while ((p) && (p->next_pl)) p = p->next_pl;
		p->next_pl = pl;
	}

@ It is undeniably clumsy that the linked list of PLs, and also of productions
within each PL, is managed by hand rather than by using //foundation//. But
speed is critical when parsing Inform text from these productions, and we want
to minimise overhead.

=
void LoadPreform::add_production(production *pr, production_list *pl) {
	if (pl->first_pr == NULL) pl->first_pr = pr;
	else {
		production *p = pl->first_pr;
		while ((p) && (p->next_pr)) p = p->next_pr;
		p->next_pr = pr;
	}
}

@h Productions and ptokens.
So now we reach the production, which encodes a typical "row" of grammar:
for example,
= (text as Preform)
	runner no <cardinal-number>
=
is a production. This is implemented as still another list, of "ptokens" (the
"p" is silent): that example has three ptokens. Note that the stroke sign and
the defined-by sign are not ptokens; they divide up productions, but aren't
part of them.

//The Optimiser// calculates data on productions just as it does on nonterminals.
For example, it can see that the above can only match a text if it has exactly
3 words, so it sets both |pr_extremes.min_words| and |pr_extremes.max_words| to 3. For the meaning
of the remaining data, and for what "struts" are, see //The Optimiser//: it
only confuses the picture here.

@d MAX_STRUTS_PER_PRODUCTION 10

=
typedef struct production {
	struct ptoken *first_pt; /* the linked list of ptokens */
	int match_number; /* 0 for |/a/|, 1 for |/b/| and so on: see //About Preform// */

	int no_ranges; /* actually one more, since range 0 is reserved */

	struct production_optimisation_data opt; /* see //The Optimiser// */
	struct production_instrumentation_data ins; /* see //Instrumentation// */

	struct production *next_pr; /* within its production list */
	CLASS_DEFINITION
} production;

@ And at the bottom of God's great chain, the lowly ptoken. Even this can spawn
another list, though: the token |fried/green/tomatoes| is a list of three ptokens
joined by the |alternative_ptoken| links.

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
	/* How to parse text against this ptoken */
	int ptoken_category; /* one of the |*_PTC| values */
	int balanced_wildcard; /* for |MULTIPLE_WILDCARD_PTC| ptokens: brackets balanced? */
	int negated_ptoken; /* the |^| modifier applies */
	int disallow_unexpected_upper; /* the |_| modifier applies */
	struct nonterminal *nt_pt; /* for |NONTERMINAL_PTC| ptokens */
	struct vocabulary_entry *ve_pt; /* for |FIXED_WORD_PTC| ptokens */
	struct ptoken *alternative_ptoken; /* linked list of other vocabulary ptokens */

	/* What results from a successful match against this ptoken */
	int result_index; /* for |NONTERMINAL_PTC| ptokens: what result number, counting from 1? */
	int range_starts; /* 1, 2, 3, ... if word range 1, 2, 3, ... starts with this */
	int range_ends; /* 1, 2, 3, ... if word range 1, 2, 3, ... ends with this */

	struct ptoken_optimisation_data opt; /* see //The Optimiser// */
	struct ptoken_instrumentation_data ins; /* see //Instrumentation// */

	struct ptoken *next_pt; /* within its production list */
	CLASS_DEFINITION
} ptoken;

@ Each ptoken has a |range_starts| and |range_ends| number. This is either -1,
or marks that the ptoken occurs as the first or last in a range (or both). For
example, in the production
= (text as InC)
	make ... from {rice ... onions} and peppers
=
the first |...| ptoken has start and end set to 1; |rice| has start 2; |onions|
has end 2. Note that the second |...|, inside the braces, doesn't start or
end anything; it normally would, but the wider range consumes it.

@h Reading productions.
We read the wording |W| of a production for the nonterminal |nt|, with |pc|
or "production count" being 0 for the first one defined, 1 for the second,
and so on.

=
production *LoadPreform::new_production(wording W, nonterminal *nt, int pc) {
	production *pr = CREATE(production);
	pr->match_number = pc; /* "production count": 0 for first in defn, and so on */
	pr->next_pr = NULL;

	pr->no_ranges = 1; /* so that they count from 1; range 0 is unused */

	Optimiser::initialise_production_data(&(pr->opt));
	Instrumentation::initialise_production_data(&(pr->ins));

	ptoken *head = NULL, *tail = NULL;
	@<Parse the row of production tokens into a linked list of ptokens@>;
	pr->first_pt = head;
	return pr;
}

@ So, then, we have to turn a wording like:
= (text as Preform)
	make ... from {rice ... onions/shallots} and peppers
=
into a sequence of ptokens, setting |head| to the first and |tail| to the last.
This particular example will produce two word ranges: one for the initial |...|,
one for the matter in the braces. Because of that, we need to keep track of
whether we're in braces or not. (Braces cannot be nested.)

The alternative |onions/shallots| is called a "slashed chain" in the code below.

@d OUTSIDE_PTBRACE 0
@d ABOUT_TO_OPEN_PTBRACE 1
@d INSIDE_PTBRACE 2

@<Parse the row of production tokens into a linked list of ptokens@> =
	int result_count = 1;
	int negation_modifier = FALSE, lower_case_modifier = FALSE;
	int unescaped = TRUE;
	int bracing_mode = OUTSIDE_PTBRACE;
	ptoken *bracing_begins_at = NULL;
	int token_count = 0;
	LOOP_THROUGH_WORDING(i, W) {
		if (unescaped) @<Parse the token modifier symbols@>;

		ptoken *pt = LoadPreform::parse_slashed_chain(nt, pr, i, unescaped);
		if (pt) {
			if (pt->ptoken_category == NONTERMINAL_PTC) @<Assign a result number@>;
			@<Modify the new ptoken according to the current modifier settings@>;
			@<Add the new ptoken to the production@>;
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
				if (bracing_begins_at) @<Set a word range to end here@>;
				bracing_mode = OUTSIDE_PTBRACE; bracing_begins_at = NULL; continue;
			}
			break;
	}

@ A bracing can be followed by |? N| to make it have the number |N|, rather
than the next number counting upwards; see //About Preform//.

@<Set a word range to end here@> =
	int rnum = pr->no_ranges++;
	if ((i+2 <= Wordings::last_wn(W)) && (Lexer::word(i+1) == QUESTIONMARK_V) &&
		(Vocabulary::test_flags(i+2, NUMBER_MC))) {
		rnum = Vocabulary::get_literal_number_value(Lexer::word(i+2));
		i += 2;
	}
	if ((rnum < 1) || (rnum >= MAX_RANGES_PER_PRODUCTION)) {
		PreformUtilities::production_error(nt, pr,
			"range number out of range");
		rnum = 1;
	}
	bracing_begins_at->range_starts = rnum;
	tail->range_ends = rnum;

@<Modify the new ptoken according to the current modifier settings@> =
	if (negation_modifier) pt->negated_ptoken = TRUE;
	if (lower_case_modifier) pt->disallow_unexpected_upper = TRUE;

	unescaped = TRUE;
	negation_modifier = FALSE;
	lower_case_modifier = FALSE;

	switch (bracing_mode) {
		case OUTSIDE_PTBRACE:
			if ((pt->ptoken_category == SINGLE_WILDCARD_PTC) ||
				(pt->ptoken_category == MULTIPLE_WILDCARD_PTC) ||
				(pt->ptoken_category == POSSIBLY_EMPTY_WILDCARD_PTC)) {
				int rnum = pr->no_ranges++;
				if ((rnum < 1) || (rnum >= MAX_RANGES_PER_PRODUCTION)) {
					PreformUtilities::production_error(nt, pr,
						"range number out of range");
					rnum = 1;
				}
				pt->range_starts = rnum;
				pt->range_ends = rnum;
			}
			break;
		case ABOUT_TO_OPEN_PTBRACE:
			bracing_begins_at = pt;
			bracing_mode = INSIDE_PTBRACE;
			break;
	}

@ A nonterminal can be followed by |? N| to make it have result number |N|,
rather than the next number counting upwards; see //About Preform//.

@<Assign a result number@> =
	if (result_count < MAX_RESULTS_PER_PRODUCTION) {
		if ((i+2 <= Wordings::last_wn(W)) && (Lexer::word(i+1) == QUESTIONMARK_V) &&
			(Vocabulary::test_flags(i+2, NUMBER_MC))) {
			pt->result_index = Vocabulary::get_literal_number_value(Lexer::word(i+2));
			if ((pt->result_index < 0) ||
				(pt->result_index >= MAX_RESULTS_PER_PRODUCTION)) {
				PreformUtilities::production_error(nt, pr,
					"result number out of range");
				pt->result_index = 1;
			}
			i += 2;
		} else {
			pt->result_index = result_count;
		}
		result_count++;
	} else {
		PreformUtilities::production_error(nt, pr,
			"too many nonterminals for one production to hold");
	}

@<Add the new ptoken to the production@> =
	if (token_count++ < MAX_PTOKENS_PER_PRODUCTION) {
		if (head == NULL) head = pt; else tail->next_pt = pt;
		tail = pt;
	} else {
		PreformUtilities::production_error(nt, pr,
			"too many tokens on production for nonterminal");
	}

@ Here we parse what is, to the Lexer, a single word (at word number |wn|),
but which might actually be a row of possibilities divided by slashes:
for example, |onions/shallots|.

=
ptoken *LoadPreform::parse_slashed_chain(nonterminal *nt, production *pr, int wn,
	int unescaped) {
	wording AW = Wordings::one_word(wn);
	@<Expand the word range if the token text is slashed@>;
	ptoken *pt = NULL;
	@<Parse the word range into a linked list of alternative ptokens@>;
	return pt;
}

@ Should we detect a slash used to indicate alternatives, we have to ask the
Lexer to have another try, but with |/| as a word-breaking character this time.
So, for example, |AW| might then end up as |onions|, |/|, |shallots|.

@<Expand the word range if the token text is slashed@> =
	wchar_t *p = Lexer::word_raw_text(wn);
	int k, breakme = FALSE;
	if (unescaped) {
		@<Look out for production match numbers@>;
		for (k=0; (p[k]) && (p[k+1]); k++)
			if ((k > 0) && (p[k] == '/'))
				breakme = TRUE;
	}
	if (breakme) AW = Feeds::feed_C_string_full(p, FALSE, L"/"); /* break only at slashes */

@ Intercept |/a/| to |/z/| and |/aa/| to |/zz/|, which don't make ptokens at
all, but simply change the production's match number.

@<Look out for production match numbers@> =
	if ((p[0] == '/') && (Characters::islower(p[1])) &&
		(p[2] == '/') && (p[3] == 0)) {
		pr->match_number = p[1] - 'a';
		return NULL; /* i.e., contribute no token */
	}
	if ((p[0] == '/') && (Characters::islower(p[1])) && (p[2] == p[1]) &&
		(p[3] == '/') && (p[4] == 0)) {
		pr->match_number = p[1] - 'a' + 26;
		return NULL; /* i.e., contribute no token */
	}

@ And then we string together the ptokens made into a linked list with links
provided by |->alternative_ptoken|, and return the head of this list.

@<Parse the word range into a linked list of alternative ptokens@> =
	ptoken *alt = NULL;
	for (; Wordings::nonempty(AW); AW = Wordings::trim_first_word(AW))
		if (Lexer::word(Wordings::first_wn(AW)) != FORWARDSLASH_V) {
			int mode = unescaped;
			if (Wordings::length(AW) > 1) mode = FALSE;
			ptoken *latest =
				LoadPreform::new_ptoken(Lexer::word(Wordings::first_wn(AW)),
					mode, nt, pr->match_number);
			if (alt == NULL) pt = latest; /* thus making |pt| the head */
			else alt->alternative_ptoken = latest;
			alt = latest;
		}

@ Finally, then, the bottom-most function here parses what is definitely a
single word into what will definitely be a single ptoken.

In "escaped" mode, where a backslash has made the text literal, it just
becomes a fixed word; otherwise it could be any of the five categories.

=
ptoken *LoadPreform::new_ptoken(vocabulary_entry *ve, int unescaped, nonterminal *nt, int pc) {
	ptoken *pt = CREATE(ptoken);
	@<Begin with a blank ptoken@>;

	wchar_t *p = Vocabulary::get_exemplar(ve, FALSE);
	if ((unescaped) && (p) && (p[0] == '<') && (p[Wide::len(p)-1] == '>'))
		@<This word is a nonterminal name@>
	else
		@<This word is not a nonterminal name@>;
	return pt;
}

@<Begin with a blank ptoken@> =
	pt->next_pt = NULL;

	pt->ptoken_category = FIXED_WORD_PTC;
	pt->balanced_wildcard = FALSE;
	pt->negated_ptoken = FALSE;
	pt->disallow_unexpected_upper = FALSE;
	pt->ve_pt = NULL;
	pt->nt_pt = NULL;
	pt->alternative_ptoken = NULL;

	pt->result_index = 1;
	pt->range_starts = -1; pt->range_ends = -1;

	Optimiser::initialise_ptoken_data(&(pt->opt));
	Instrumentation::initialise_ptoken_data(&(pt->ins));

@ If the text refers to a nonterminal which doesn't yet exist, then this
creates it; that's how we deal with forward references. //Nonterminals::find//
never returns |NULL|.

@<This word is a nonterminal name@> =
	pt->nt_pt = Nonterminals::find(ve);
	pt->ptoken_category = NONTERMINAL_PTC;

@<This word is not a nonterminal name@> =
	pt->ve_pt = ve;
	if (unescaped) {
		if (ve == SIXDOTS_V) {
			pt->ptoken_category = MULTIPLE_WILDCARD_PTC;
			pt->balanced_wildcard = TRUE;
		}
		if (ve == THREEDOTS_V) pt->ptoken_category = MULTIPLE_WILDCARD_PTC;
		if (ve == THREEHASHES_V) pt->ptoken_category = SINGLE_WILDCARD_PTC;
		if (ve == THREEASTERISKS_V) pt->ptoken_category = POSSIBLY_EMPTY_WILDCARD_PTC;
	}
	if (pt->ptoken_category == FIXED_WORD_PTC) Nonterminals::note_word(ve, nt, pc);
