[Nonterminals::] Nonterminals.

The angle-bracketed terms appearing in Preform grammar.

@h How nonterminals are stored.
Each different nonterminal defined in the |Syntax.preform| code read in,
such as <any-integer>, is going to correspond to a global variable in the
program reading it in, such as |any_integer_NTM|. On the face of it, this is
impossible. How can what happens at run-time affect what variables are named
at compile time?

The answer is that the //inweb// literate programming tool looks through the
complete source code, sees the Preform nonterminals described in it, and
inserts declarations of the corresponding variables into the "tangled" form
of the source code sent to a C compiler to make the actual program. (This is
a feature of //inweb// available only for programs written in InC.)

In particular, the tangler of |inweb| replaces the |[[nonterminals]]| below with
invocations of the |REGISTER_NONTERMINAL| and |INTERNAL_NONTERMINAL| macros.
For example, it inserts the C line:
= (text as C)
	INTERNAL_NONTERMINAL(L"<any-integer>", any_integer_NTM, 1, 1);
=
since this is an "internal" nonterminal; and the macro will then expand
to code which sets up |any_integer_NTM| -- see below.

=
void Nonterminals::register(void) {
	/* The following is not valid C, but causes Inweb to insert lines which are */
	[[nonterminals]];
	/* Back to regular C now */
	nonterminal *nt;
	LOOP_OVER(nt, nonterminal)
		if ((nt->marked_internal) && (nt->internal_definition == NULL))
			internal_error("internal nonterminal has no definition function");
}

@ So, then, //inweb// tangles out code which uses the |REGISTER_NONTERMINAL|
macro for any standard nonterminal, and also tangles a compositor function for
it; the name of which is the nonterminal's name with a |C| suffix. For example,
suppose //inweb// sees the following in the web it is tangling:
= (text as Preform)
	<competitor> ::=
		the pacemaker |              ==> 1
		<ordinal-number> runner |    ==> R[1]
		runner no <cardinal-number>  ==> R[1]
=
It then tangles this macro usage into //Nonterminals::register// above:
= (text as C)
	REGISTER_NONTERMINAL(L"<competitor>", competitor_NTM);
=
And it also tangles matching declarations for:
(a) the global variable |competitor_NTM|, of type |nonterminal *|;
(b) the "compositor function" |competitor_NTMC|, which is a function to
deal with what happens when a successful match is made against the grammar --
this incorporates the material which //inweb// finds to the right of the |==>|
markers in the Preform definition.

But if we left things at that, we would find ourselves at run-time with
a null variable, a function not called from anywhere, and an instance
somewhere in memory of a nonterminal read in from Preform syntax and
called |"<competitor>"|, but which has no apparent connection to either
the function or the variable. We clearly need to join these together.

And so the |REGISTER_NONTERMINAL| macro expands to code which initialises the
variable to the nonterminal having its name, and then connects that to the
compositor function:

@d REGISTER_NONTERMINAL(quotedname, identifier)
	identifier = Nonterminals::find(Vocabulary::entry_for_text(quotedname));
	identifier->compositor_fn = identifier##C;

@ For example, this might expand to:
= (text as C)
	competitor_NTM = Nonterminals::find(Vocabulary::entry_for_text(L"<competitor>"));
	competitor_NTM->compositor_fn = competitor_NTMC;
=
Note that it is absolutely necessary that |Nonterminals::find| does
return a nonterminal. But we can be sure that it does, since the function creates
a nonterminal object of that name even if one does not already exist.

@ The position for internal nonterminals (i.e. those defined by a function
written by the programmer, not by Preform grammar lines) is similar:
(a) again there is a global variable, say |any_integer_NTM|, of type |nonterminal *|;
(b) but now there is no compositor, and instead there is a function |any_integer_NTMR|
which actually performs the parse directly.

The |INTERNAL_NONTERMINAL| macro similarly initialises and connects these
declarations. |min| and |max| are conveniences for speedy parsing, and supply
the minimum and maximum number of words that the nonterminal can match; these
are needed because the Preform optimiser can't see inside |any_integer_NTMR| to
calculate those bounds for itself. |max| can be infinity, in which case we
use the constant |INFINITE_WORD_COUNT| for it.

@d INFINITE_WORD_COUNT 1000000000

@d INTERNAL_NONTERMINAL(quotedname, identifier, min, max)
	identifier = Nonterminals::find(Vocabulary::entry_for_text(quotedname));
	identifier->min_nt_words = min; identifier->max_nt_words = max;
	identifier->internal_definition = identifier##R;
	identifier->marked_internal = TRUE;

@ So, then, the following rather lengthy class declaration shows what goes
into a nonterminal. Note that nonterminals are uniquely identifiable by their
names: there can be only one called, say, <any-integer>. This is why its
textual name is referred to as an "ID".

=
typedef struct nonterminal {
	struct vocabulary_entry *nonterminal_id; /* e.g. |"<any-integer>"| */

	/* For internal nonterminals */
	int marked_internal; /* has, or will be given, an internal definition... */
	int (*internal_definition)(wording W, int *result, void **result_p); /* ...this one */
	int voracious; /* if true, scans whole rest of word range */

	/* For regular nonterminals */
	struct production_list *first_production_list; /* if not internal, this defines it */
	int (*compositor_fn)(int *r, void **rp, int *i_s, void **i_ps, wording *i_W, wording W);
	int multiplicitous; /* if true, matches are alternative syntax tree readings */

	/* Storage for most recent correct match */
	struct wording range_result[MAX_RANGES_PER_PRODUCTION]; /* storage for word ranges matched */

	/* Optimiser data */
	int optimised_in_this_pass; /* have the following been worked out yet? */
	int min_nt_words, max_nt_words; /* for speed */
	struct range_requirement nonterminal_req;
	int nt_req_bit; /* which hashing category the words belong to, or $-1$ if none */
	int number_words_by_production;
	unsigned int flag_words_in_production;

	/* For debugging only */
	int watched; /* watch goings-on to the debugging log */
	int nonterminal_tries; /* for statistics collected in instrumented mode */
	int nonterminal_matches; /* ditto */
	CLASS_DEFINITION
} nonterminal;

@ A few notes on this are in order:

(a) As noted above, every nonterminal is either "internal" or "regular". If
internal, it is defined by a function; if regular, it is defined by lines
of grammar (called "productions") and a compositor function.

(b) A few internal nonterminals are "voracious". These are given the entire
word range for their productions to eat, and encouraged to eat as much as they
like, returning a word number to show how far they got. While this effect
could be duplicated with non-voracious nonterminals, that would be quite a bit
slower, since it would have to test every possible word range.

(c) A few regular nonterminals are "multiplicitous". These composite their
results in a way special to the Inform compiler's syntax tree, by stacking
them up as alternative possible readings of the same text. Ordinarily, the
result of parsing text against a nonterminal is that the first grammar line
matching that text determines the meaning, but for a multiplicitous nonterminal,
every line matching the text determines one of perhaps many possible meanings.

(d) The optimisation data helps the parser to reject non-matching text quickly.
For example, if the optimiser can determine that <competitor> only ever matches
texts of between 3 and 7 words in length, it can quickly reject any run of
words outside that range. (However: note that a maximum of 0 means that the
maximum and minimum word counts are disregarded.) The other fields are harder
to explain -- see //The Optimiser//.

@ So, then, as noted above, nonterminals are identified by their name-words.
The following is not especially fast but doesn't need to be: it's used only
when Preform grammar is parsed, not when Inform text is parsed.

=
nonterminal *Nonterminals::detect(vocabulary_entry *name_word) {
	nonterminal *nt;
	LOOP_OVER(nt, nonterminal)
		if (name_word == nt->nonterminal_id)
			return nt;
	return NULL;
}

@ And the following always returns one, creating it if necessary:

=
nonterminal *Nonterminals::find(vocabulary_entry *name_word) {
	nonterminal *nt = Nonterminals::detect(name_word);
	if (nt == NULL) {
		nt = CREATE(nonterminal);
		nt->nonterminal_id = name_word;

		nt->marked_internal = FALSE; /* by default, nonterminals are regular */
		nt->internal_definition = NULL;
		nt->voracious = FALSE;

		for (int i=0; i<MAX_RANGES_PER_PRODUCTION; i++)
			nt->range_result[i] = EMPTY_WORDING;

		nt->first_production_list = NULL;
		nt->compositor_fn = NULL;
		nt->multiplicitous = FALSE;
		nt->optimised_in_this_pass = FALSE;
		nt->min_nt_words = 1; nt->max_nt_words = INFINITE_WORD_COUNT;
		nt->nt_req_bit = -1;
		nt->number_words_by_production = FALSE;
		nt->flag_words_in_production = 0;

		nt->watched = FALSE;
		nt->nonterminal_tries = 0; nt->nonterminal_matches = 0;
	}
	return nt;
}

@h Word ranges in a nonterminal.
We now need to define the macros |GET_RW| and |PUT_RW|, which get and set 
the results of a successful match against a nonterminal (see //About Preform//
for more on this).

We do so by giving each nonterminal a small array of |wording|s, which are
lightweight structures incurring little time or space overhead. The fact that
they are attached to the NT itself, rather than, say, being placed on a
parsing stack of some kind, makes them faster to access, but is possible only
because the parser never backtracks. Similarly, results word ranges are
overwritten if a nonterminal calls itself directly or indirectly: that is, the
inner one's results are wiped out by the outer one. But this is no problem,
since we never extract word-ranges from grammar which is recursive.

Word range 0 is reserved in case we ever need it for the entire text matched
by the nonterminal, though at present we don't need that.

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

@h Other results.
The parser records the result of the most recently matched nonterminal in the
following global variables -- which, unlike word ranges, are not attached to
any single NT.

//inweb// translates the notation |<<r>>| and |<<rp>>| to these variable names:

=
int most_recent_result = 0; /* the variable which |inweb| writes |<<r>>| */
void *most_recent_result_p = NULL; /* the variable which |inweb| writes |<<rp>>| */

@h Watching.
A "watched" nonterminal is one which the Preform parser logs its usage of;
this is helpful when debugging.

=
void Nonterminals::watch(nonterminal *nt, int state) {
	nt->watched = state;
}
