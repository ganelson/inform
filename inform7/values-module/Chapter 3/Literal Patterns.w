[LiteralPatterns::] Literal Patterns.

To manage the possible notations with which literal values can be written.

@ Literal patterns (LPs) allow an author to create new notations for
quasi-numerical kinds of value. For example,

>> 16:9 specifies an aspect ratio.

establishes a new notation for writing literals of the kind "aspect ratios".

Each kind of value has a linked list of literal notations which can specify
it, if any. We sometimes need to iterate through the this list, and can do
so with the following macro:

@d LITERAL_FORMS_LOOP(lp, K)
	for (lp = LiteralPatterns::list_of_literal_forms(K); lp;
		lp=lp->next_for_this_kind)

@ LPs with just a single numerical part to them (like "20 yards" rather than
"16:9") are of special interest for holding scientific measurements, and
we provide elaborate extra features for this form of LP.

A given kind can have many different LPs to represent it, and this is
especially convenient for physics -- it means we can give ways to describe
mass (a kind of value) in grams, kilograms or tonnes (all literal patterns).
Among these, one LP is special and is called the "benchmark" for the kind --
it is the default notation, the one considered most natural, and other LPs for
the same kind are scaled relative to this. For instance, the benchmark for
mass might be the notation "1 kg"; the notations "1 g" and "1 tonne" would
then be scaled down by 1000, and up by 1000, respectively.

@ Syntactically, a literal pattern is a series of "tokens", of which more
below. Some tokens are simply fixed lettering or wording, but at least one
must be numerical, and called an "element". For example, "16:9" has three
tokens -- element, fixed |:|, element.

@d MAX_ELEMENTS_PER_LITERAL 8
@d MAX_TOKENS_PER_LITERAL 100

=
typedef struct literal_pattern {
	struct kind *kind_specified; /* the kind of the result: i.e., what it specifies */
	struct literal_pattern *next_for_this_kind; /* continuing list for this kind */
	struct wording prototype_text; /* where the prototype specification is */
	int no_lp_tokens; /* number of tokens in parse_node */
	struct literal_pattern_token lp_tokens[MAX_TOKENS_PER_LITERAL];
	int no_lp_elements; /* how many tokens are numbers */
	struct literal_pattern_element lp_elements[MAX_ELEMENTS_PER_LITERAL];
	int number_signed; /* for instance -10 cm would be allowed if this is set */

	/* used when we have a sequence of alternative notations for the same unit */
	int primary_alternative; /* first of a set of alternatives? */
	struct literal_pattern *next_alternative_lp; /* continuing list of alternatives */
	int singular_form_only; /* print using this notation only for 1 unit */
	int plural_form_only; /* print using this notation for 2 units, 0.5 units, etc. */

	/* used when printing and calculating values */
	struct scaling_transformation scaling; /* how to convert apparent to actual values */
	int equivalent_unit; /* is this just an equivalent to another LP? */
	int benchmark; /* is this the benchmark LP for its kind? */
	int last_resort; /* is this the last possible LP to use when printing a value of the kind? */
	int marked_for_printing; /* used in compiling printing routines */

	struct literal_pattern_compilation_data compilation_data;
	CLASS_DEFINITION
} literal_pattern;

@ There are three sorts of token: character, word and element. Each token can
be a whole word, or only part of a word. For instance, in

>> 28kg net specifies a weight.

we have a sequence of four tokens: an element token, marked as beginning a
word; a character token |k|; a character token |g|; and a word token |net|,
which necessarily begins a word. Word boundaries in the source text must
match those in the specification, so this notation does not match the text
"41 kg net", for instance.

@d WORD_LPT 1
@d CHARACTER_LPT 2
@d ELEMENT_LPT 3

=
typedef struct literal_pattern_token {
	int new_word_at; /* does token start a new word? */
	int lpt_type; /* one of the three constants defined above */
	wchar_t token_char; /* |CHARACTER_LPT| only; the character to match */
	int token_wn; /* |WORD_LPT| only; word number in source text of the prototype */
} literal_pattern_token;

@ A value notated this way is like an old-school Pascal packed integer,
where a small data structure was joined into a single word of data. For
instance, in the "16:9" example, $e_0:e_1$ would be stored as
$e_0r_1+e_1$ where $r_1 = 10$ is one more than the maximum value of $e_1$.
So "4:3" would be stored as $4\cdot(9+1) + 3 = 43$.

More formally, we call the numbers in such a literal its "elements". In the
case of "16:9", there are two elements, $e_0 = 16$ and $e_1 = 9$. The general
formula is:
$$ N = \sum_{i=0}^{n-1} e_i\cdot \prod_{j>i} r_j $$
where $(e_0, e_1, ..., e_{n-1})$ are the values and $r_j$, the "range",
is the constraint such that $0\leq e_j < r_j$.
Note that $r_0$ is never required, since $e_0$ is constrained in size only
by the need for $N$ to fit into a single virtual machine integer. The value
$$ m_i = \prod_{j>i} r_j $$
is called the "multiplier", and note that $m_{n-1} = 1$. Conversely,
$e_i = N/m_0$ if $i=0$, and $N/m_i {\rm ~mod~} r_i$ otherwise.
The rightmost element $e_{n-1}$ is the least significant numerically.

=
typedef struct literal_pattern_element {
	int element_index; /* the value $i$ placing this within its LP, where $0\leq i<n$ */
	int element_range; /* the value $r_i$ for this LP */
	int element_multiplier; /* the value $m_i$ for this LP */

	struct wording element_name; /* if we define a name for the element */

	int is_real; /* store as a real number, not an integer? */
	int without_leading_zeros; /* normally without? */
	int element_optional; /* can we truncate the LP here? */
	int preamble_optional; /* if so, can we lose the preamble as well? */
} literal_pattern_element;

@ For the sake of printing, we can specify which notation is to be used in
printing a value back. For instance,

>> 1 tonne (in tonnes, singular) specifies a mass scaled up by 1000.

assigns the name "in tonnes" to this notation for writing a mass. There can
be several notation associated with "in tonnes":

>> 2 tonnes (in tonnes, plural) specifies a mass scaled up by 1000.

and hence the linked list of LPs associated with a single "literal pattern
name". Moreover, a given kind of value can support multiple named notations;
mass might also support "in kilograms" and "in grams", for instance.

=
typedef struct literal_pattern_name {
	struct wording notation_name; /* name for this notation, if any; e.g. "in centimetres" */
	struct literal_pattern *can_use_this_lp; /* list of LPs used under this name */
	struct literal_pattern_name *next; /* other names for the same kind */
	struct literal_pattern_name *next_with_rp; /* used in parsing only: list applied to one notation */
	int lpn_compiled_already;
	CLASS_DEFINITION
} literal_pattern_name;

@h Creating patterns, tokens and elements.

=
literal_pattern *LiteralPatterns::lp_new(kind *K, wording W) {
	literal_pattern *lp = CREATE(literal_pattern);
	lp->plural_form_only = FALSE;
	lp->singular_form_only = FALSE;
	lp->kind_specified = K;
	lp->prototype_text = W;
	lp->next_for_this_kind = NULL;
	lp->primary_alternative = FALSE;
	lp->next_alternative_lp = NULL;
	lp->no_lp_elements = 0;
	lp->no_lp_tokens = 0;
	lp->number_signed = FALSE;
	lp->scaling = Kinds::Scalings::new(TRUE, LP_SCALED_AT, 1, 1.0, 0, 0.0);
	lp->equivalent_unit = FALSE;
	lp->benchmark = FALSE;
	lp->compilation_data = RTLiteralPatterns::new_compilation_data(lp);
	return lp;
}

@ =
literal_pattern_token LiteralPatterns::lpt_new(int t, int nw) {
	literal_pattern_token lpt;
	lpt.new_word_at = nw;
	lpt.lpt_type = t;
	lpt.token_char = 0;
	lpt.token_wn = -1;
	return lpt;
}

@ =
literal_pattern_element LiteralPatterns::lpe_new(int i, int r, int sgn) {
	literal_pattern_element lpe;
	if (i == 0) lpe.element_range = -1; else lpe.element_range = r;
	lpe.element_multiplier = 1;
	lpe.element_index = i;
	lpe.element_name = EMPTY_WORDING;
	lpe.preamble_optional = FALSE;
	lpe.element_optional = FALSE;
	lpe.without_leading_zeros = FALSE;
	return lpe;
}

@h Listing LPs.
A routine to append a LP to the linked list of LPs for a given kind. But
it's a little more involved because this is where we calculate the scale
factors which relate LPs in the list, and also because we need to keep the
list in a particular order.

=
int PM_ZMachineOverflow2_issued = FALSE;

literal_pattern *LiteralPatterns::list_add(literal_pattern *list_head,
	literal_pattern *new_lp, int using_integer_scaling) {
	if (list_head == NULL) @<Begin a new list with just the new LP in it@>
	else @<Add the new LP to the existing list@>;

	@<Correct the "last resort" flags in the list of LPs@>;
	@<Automatically enable signed literals if there are scaled LPs in the list@>;

	return list_head;
}

@ When the new LP is the first one, it can only be scaled in absolute terms:
"scaled at", which specifies its $M$ value.

@<Begin a new list with just the new LP in it@> =
	Kinds::Scalings::determine_M(&(new_lp->scaling), NULL,
		TRUE, new_lp->equivalent_unit, new_lp->primary_alternative);
	list_head = new_lp;

@ But if other LPs already exist, then absolute scalings are forbidden. The
new LP must be scaled up or down relative to existing notations, or pegged
equivalent to an exact value.

@<Add the new LP to the existing list@> =
	literal_pattern *lp;
	scaling_transformation *benchmark_sc = NULL;
	for (lp = list_head; lp; lp = lp->next_for_this_kind)
		if (lp->benchmark)
			benchmark_sc = &(lp->scaling);
	int rescale_factor = Kinds::Scalings::determine_M(&(new_lp->scaling), benchmark_sc,
		FALSE, new_lp->equivalent_unit, new_lp->primary_alternative);
	if (rescale_factor != 1)
		for (lp = list_head; lp; lp = lp->next_for_this_kind)
			if ((lp != new_lp) && (lp->equivalent_unit == FALSE))
				lp->scaling =
					Kinds::Scalings::enlarge(lp->scaling, rescale_factor);
	list_head = LiteralPatterns::lp_list_add_inner(list_head, new_lp);

	if ((TargetVMs::is_16_bit(Task::vm())) && (PM_ZMachineOverflow2_issued == FALSE))
		for (lp = list_head; lp; lp = lp->next_for_this_kind)
			if (Kinds::Scalings::quantum(lp->scaling) > 32767) {
				StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_ZMachineOverflow2),
					"you've set up literal specifications needing a range of "
					"values too broad to be stored at run-time",
					"at least with the Settings for this project as they currently are. "
					"(Change to Glulx to be allowed to use much larger numbers; "
					"or for really enormous values, use real arithmetic.)");
				PM_ZMachineOverflow2_issued = TRUE;
				break;
			}

@ Within the list, exactly one LP is marked with the |last_resort| flag: the
last one not marked as an equivalent unit. (You can only be equivalent to
something already there, so it's not possible for all the LPs in the list to
be equivalent.)

@<Correct the "last resort" flags in the list of LPs@> =
	literal_pattern *lp, *last_resorter = NULL;
	for (lp = list_head; lp; lp = lp->next_for_this_kind) {
		lp->last_resort = FALSE;
		if (lp->equivalent_unit == FALSE) last_resorter = lp;
	}
	if (last_resorter) last_resorter->last_resort = TRUE;

@ Inform is ordinarily a bit picky about not allowing negative values within
these notations, unless they have explicitly been defined to allow it. That
makes sense for basically combinatorial notations (room 1 to room 64, say)
but would be a nonsense for scientific measurements where we intend to perform
arithmetic. So:

@<Automatically enable signed literals if there are scaled LPs in the list@> =
	int scalings_exist = FALSE;
	literal_pattern *lp;
	for (lp = list_head; lp; lp = lp->next_for_this_kind)
		if (Kinds::Scalings::involves_scale_change(lp->scaling))
			scalings_exist = TRUE;

	if (scalings_exist)
		for (lp = list_head; lp; lp = lp->next_for_this_kind)
			lp->number_signed = TRUE;

@ The actual insertion of the new LP into the list is carried out here, and
is complicated by the fact that we need to keep these in a special order.

=
literal_pattern *LiteralPatterns::lp_list_add_inner(literal_pattern *list_head, literal_pattern *new_lp) {
	literal_pattern *lp, *lp_prev;
	new_lp->next_for_this_kind = NULL;
	if (list_head == NULL) return new_lp;
	lp = list_head; lp_prev = NULL;
	while (lp) {
		if (LiteralPatterns::lp_precedes(new_lp, lp)) {
			new_lp->next_for_this_kind = lp;
			if (lp_prev) lp_prev->next_for_this_kind = new_lp;
			else list_head = new_lp;
			return list_head;
		}
		lp_prev = lp;
		lp = lp->next_for_this_kind;
	}
	lp_prev->next_for_this_kind = new_lp;
	return list_head;
}

@ Highly scaled values come before less scaled ones; otherwise plural forms
come before singular ones; and otherwise an earlier-defined LP comes before
a later one.

=
int LiteralPatterns::lp_precedes(literal_pattern *A, literal_pattern *B) {
	int s = Kinds::Scalings::compare(A->scaling, B->scaling);
	if (s > 0) return TRUE;
	if (s < 0) return FALSE;
	if ((A->primary_alternative) && (B->primary_alternative == FALSE)) return TRUE;
	if ((A->primary_alternative == FALSE) && (B->primary_alternative)) return FALSE;
	if ((A->plural_form_only) && (B->plural_form_only == FALSE)) return TRUE;
	if ((A->plural_form_only == FALSE) && (B->plural_form_only)) return FALSE;
	if ((A->singular_form_only) && (B->singular_form_only == FALSE)) return TRUE;
	if ((A->singular_form_only == FALSE) && (B->singular_form_only)) return FALSE;
	if (A->allocation_id < B->allocation_id) return TRUE;
	return FALSE;
}

@ One member of the list is the "benchmark", as noted above.

=
literal_pattern *LiteralPatterns::get_benchmark(kind *K) {
	literal_pattern *lp;
	LITERAL_FORMS_LOOP(lp, K)
		if (lp->benchmark)
			return lp;
	return NULL;
}

@ And this returns the multiplier of the benchmark, which is important for
performing multiplications.

@d DETERMINE_SCALE_FACTOR_KINDS_CALLBACK LiteralPatterns::scale_factor

=
int LiteralPatterns::scale_factor(kind *K) {
	literal_pattern *benchmark_lp = LiteralPatterns::get_benchmark(K);
	if (benchmark_lp) return Kinds::Scalings::get_integer_multiplier(benchmark_lp->scaling);
	return 1;
}

@h Optional break points.
Sometimes the pattern allows later numerical elements to be skipped, in which
case they are understood to be 0.

=
int LiteralPatterns::at_optional_break_point(literal_pattern *lp, int ec, int tc) {
	if ((ec<lp->no_lp_elements) && /* i.e., if there are still numerical elements to supply */
		(lp->lp_elements[ec].element_optional) && /* but which are optional */
		((lp->lp_elements[ec].preamble_optional) || /* and either the preamble tokens are also optional */
			(lp->lp_tokens[tc].lpt_type == ELEMENT_LPT))) /* or we're at the number token */
		return TRUE;
	return FALSE;
}

@h Matching an LP in the source text.
Given an excerpt |(w1, w2)|, we try to parse it as a constant value written
in the LP notation: if it passes, we return the kind of value, and if not
we return |NULL|.

=
int waive_lp_overflows = FALSE;
int last_LP_problem_at = -1;
double latest_constructed_real = 0.0;

double LiteralPatterns::get_latest_real(void) {
	return latest_constructed_real;
}

kind *LiteralPatterns::match(literal_pattern *lp, wording W, int *found) {
	int matched_number = 0, overflow_16_bit_flag = FALSE, overflow_32_bit_flag = FALSE;
	literal_pattern_element *sign_used_at = NULL, *element_overflow_at = NULL;

	/* if the excerpt is longer than the maximum length of such a notation, give up quickly: */
	if (Wordings::length(W) > Wordings::length(lp->prototype_text)) return NULL;

	@<Try to match the excerpt against the whole prototype or up to an optional break@>;

	if (sign_used_at) @<Check that a negative number can be used in this notation@>;

	if (waive_lp_overflows == FALSE) {
		if (element_overflow_at) @<Report a problem because one element in the notation overflows@>;
		@<Check that the value found lies within the range which the VM can hold@>;
	}

	*found = matched_number;
	return lp->kind_specified;
}

@ Scanning the tokens one at a time. The scan position is represented as a
word number |wn| together with a character position within the word, |wpos|.
The |wpos| value $-1$ means that word |wn| has not yet been started.

@<Try to match the excerpt against the whole prototype or up to an optional break@> =
	int tc, wn = Wordings::first_wn(W), wpos = -1, ec = 0, matched_scaledown = 1, parsed_as_real = FALSE;
	wchar_t *wd = Lexer::word_text(Wordings::first_wn(W));
	for (tc=0; tc<lp->no_lp_tokens; tc++) {
		if (wn > Wordings::last_wn(W)) {
			if ((wpos == -1) /* i.e., if we are cleanly at a word boundary */
				&& (LiteralPatterns::at_optional_break_point(lp, ec, tc))) break;
			return NULL;
		}
		switch (lp->lp_tokens[tc].lpt_type) {
			case WORD_LPT: @<Match a fixed word token within a literal pattern@>; break;
			case CHARACTER_LPT: @<Match a character token within a literal pattern@>; break;
			case ELEMENT_LPT: @<Match an element token within a literal pattern@>; break;
			default: internal_error("unknown literal pattern token type");
		}
	}
	if (wpos >= 0) return NULL; /* we need to end cleanly, not in mid-word */
	if (wn <= Wordings::last_wn(W)) return NULL; /* and we need to have used up all of the excerpt */

	if (parsed_as_real == FALSE) {
		int loses_accuracy = FALSE;
		scaling_transformation sc =
			Kinds::Scalings::contract(lp->scaling, matched_scaledown, &loses_accuracy);
		matched_number = Kinds::Scalings::quanta_to_value(sc, matched_number);
		if (loses_accuracy) @<Report a problem because not enough accuracy is available@>;
		long long int max_16_bit = 32767LL, max_32_bit = 2147483647LL, min_32_bit = -2147483648LL;
		if (matched_number > max_16_bit) overflow_16_bit_flag = TRUE;
		if (matched_number > max_32_bit) overflow_32_bit_flag = TRUE;
		if ((sign_used_at) && (overflow_32_bit_flag == FALSE)) {
			if (matched_number == min_32_bit) overflow_32_bit_flag = TRUE;
			else matched_number = -matched_number;
		}
	} else {
		#pragma clang diagnostic push
		#pragma clang diagnostic ignored "-Wsign-conversion"
		if (sign_used_at) matched_number = matched_number | 0x80000000;
		#pragma clang diagnostic pop
	}

@ A word token matches an exact word (but allowing for variation in casing).

@<Match a fixed word token within a literal pattern@> =
	if (wpos >= 0) return NULL; /* if we're still in the middle of the last word, we must fail */
	if (compare_words(wn, lp->lp_tokens[tc].token_wn) == FALSE) return NULL;
	wn++;

@ A character token matches only a single character -- note the case insensitivity
here, because of the use of |tolower|.

@<Match a character token within a literal pattern@> =
	if (wpos == -1) { wpos = 0; wd = Lexer::word_text(wn); } /* start parsing the interior of a word */
	if (Characters::tolower(wd[wpos++]) != Characters::tolower(lp->lp_tokens[tc].token_char)) return NULL;
	if (wd[wpos] == 0) { wn++; wpos = -1; } /* and stop parsing the interior of a word */

@<Match an element token within a literal pattern@> =
	literal_pattern_element *lpe = &(lp->lp_elements[ec++]); /* fetch details of next number */
	if (wpos == -1) { wpos = 0; wd = Lexer::word_text(wn); } /* start parsing the interior of a word */
	if (wd[wpos] == '-') { sign_used_at = lpe; wpos++; }
	if (Kinds::FloatingPoint::uses_floating_point(lp->kind_specified)) @<Match a real number element token@>
	else @<Match an integer number element token@>;
	if (wd[wpos] == 0) { wn++; wpos = -1; } /* and stop parsing the interior of a word */

@ There are three different sorts of overflow:

(1) The calculation of the packed value exceeding the range which an integer
can store on a 16-bit virtual machine;
(2) Ditto, but on a 32-bit virtual machine; and
(3) One of the numerical elements inside the notation being given out of range.

We report none of these as a problem immediately -- only if the pattern would
otherwise match.

The following assumes that |long long int| is at least 64-bit, so that it
can hold any 32-bit integer multiplied by 10, and also any product of two
32-bit numbers. This is true for all modern |gcc| implementations and is
required by PM_, but was not required by C90, so it is just possible that
this could cause trouble on unusual platforms.

@<Match an integer number element token@> =
	long long int tot = 0, max_32_bit, max_16_bit;
	int digits_found = 0, point_at = -1;
	max_16_bit = 32767LL; if (sign_used_at) max_16_bit = 32768LL;
	max_32_bit = 2147483647LL; if (sign_used_at) max_32_bit = 2147483648LL;
	while ((Characters::isdigit(wd[wpos])) ||
		((wd[wpos] == '.') && (Kinds::Scalings::get_integer_multiplier(lp->scaling) > 1) && (point_at == -1))) {
		if (wd[wpos] == '.') { point_at = digits_found; wpos++; continue; }
		tot = 10*tot + (wd[wpos++] - '0');
		if (tot > max_16_bit) overflow_16_bit_flag = TRUE;
		if (tot > max_32_bit) overflow_32_bit_flag = TRUE;
		digits_found++;
	}
	if ((point_at == 0) || (point_at == digits_found)) return NULL;
	if (digits_found == 0) return NULL;
	while ((point_at > 0) && (point_at < digits_found)) {
		matched_scaledown *= 10; point_at++;
	}
	if ((tot >= lpe->element_range) && (lpe->element_index > 0)) element_overflow_at = lpe;
	tot = (lpe->element_multiplier)*tot;
	if (tot > max_16_bit) overflow_16_bit_flag = TRUE;
	if (tot > max_32_bit) overflow_32_bit_flag = TRUE;
	tot = matched_number + tot;
	if (tot > max_16_bit) overflow_16_bit_flag = TRUE;
	if (tot > max_32_bit) overflow_32_bit_flag = TRUE;
	matched_number = (int) tot;

@ In real arithmetic, though, overflow isn't a problem, since we can use the
infinities to represent arbitrarily large numbers.

@<Match a real number element token@> =
	TEMPORARY_TEXT(real_buffer)
	int point_at = -1, mult_at = -1;
	while ((Characters::isdigit(wd[wpos])) || ((wd[wpos] == '.') && (point_at == -1))) {
		if (wd[wpos] == '.') point_at = Str::len(real_buffer);
		PUT_TO(real_buffer, wd[wpos++]);
	}
	if ((Str::len(real_buffer) == 0) || (point_at == Str::len(real_buffer)-1)) return NULL;
	if (LiteralReals::ismultiplicationsign(wd[wpos])) {
		mult_at = wpos;
		PUT_TO(real_buffer, wd[wpos++]);
		if (wd[wpos] == '1') PUT_TO(real_buffer, wd[wpos++]); else return NULL;
		if (wd[wpos] == '0') PUT_TO(real_buffer, wd[wpos++]); else return NULL;
		if (wd[wpos] == '^') PUT_TO(real_buffer, wd[wpos++]); else return NULL;
		if (wd[wpos] == '+') PUT_TO(real_buffer, wd[wpos++]);
		else if (wd[wpos] == '-') PUT_TO(real_buffer, wd[wpos++]);
		while (Characters::isdigit(wd[wpos])) {
			PUT_TO(real_buffer, wd[wpos++]);
		}
	}
	wording W = Feeds::feed_text(real_buffer);
	DISCARD_TEXT(real_buffer)
	if ((point_at == -1) && (mult_at == -1)) {
		if (<cardinal-number>(Wordings::first_word(W)) == FALSE) return NULL;
		matched_number = <<r>>;
		int signbit = 0;
		if (matched_number < 0) { signbit = 1; matched_number = -matched_number; }
		matched_number = LiteralReals::construct_float(signbit, matched_number, 0, 0);
	} else {
		if (<literal-real-in-digits>(Wordings::first_word(W)) == FALSE) return NULL;
		matched_number = <<r>>;
	}

	latest_constructed_real =
		Kinds::Scalings::real_quanta_to_value(lp->scaling, latest_constructed_real);

	int signbit = FALSE;
	if (latest_constructed_real < 0) {
		latest_constructed_real = -latest_constructed_real;
		signbit = TRUE;
	}
	matched_number = LiteralReals::construct_float(signbit, latest_constructed_real, 0, 0);
	parsed_as_real = TRUE;

@ Problem messages here have a tendency to be repeated, in some situations,
which is annoying. So we have a mechanism to suppress duplicates:

@d ISSUING_LP_PROBLEM
	if (last_LP_problem_at == Wordings::first_wn(W)) return NULL;
	last_LP_problem_at = Wordings::first_wn(W);

@<Check that a negative number can be used in this notation@> =
	if (Kinds::FloatingPoint::uses_floating_point(lp->kind_specified) == FALSE) {
		if (sign_used_at->element_index != 0) {
			ISSUING_LP_PROBLEM;
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_NegationInternal),
				"a negative number can't be used in the middle of a constant",
				"and the minus sign makes it look as if that's what you are "
				"trying here.");
			return NULL;
		}
		if (lp->number_signed == FALSE) {
			ISSUING_LP_PROBLEM;
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_NegationForbidden),
				"the minus sign is not allowed here",
				"since this is a kind of value which only allows positive "
				"values to be written.");
			return NULL;
		}
	}

@ The out of range problem messages:

@<Check that the value found lies within the range which the VM can hold@> =
	if (overflow_32_bit_flag) {
		ISSUING_LP_PROBLEM;
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_EvenOverflow-G),
			"you use a literal specification to make a value which is too large",
			"even for a story file compiled with the Glulx setting. (You can "
			"see the size limits for each way of writing a value on the Kinds "
			"page of the Index.)");
		return NULL;
	}
	if ((overflow_16_bit_flag) && (TargetVMs::is_16_bit(Task::vm()))) {
		ISSUING_LP_PROBLEM;
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_ZMachineOverflow),
			"you use a literal specification to make a value which is too large",
			"at least with the Settings for this project as they currently are. "
			"(Change to Glulx to be allowed to use much larger numbers; "
			"meanwhile, you can see the size limits for each way of writing a "
			"value on the Kinds page of the Index.)");
		return NULL;
	}

@ The more specific problem of an internal overflow:

@<Report a problem because one element in the notation overflows@> =
	int max = element_overflow_at->element_range - 1;
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, W);
	Problems::quote_wording(3, lp->prototype_text);
	Problems::quote_number(4, &max);
	switch (element_overflow_at->element_index) {
		case 0: Problems::quote_text(5, "first"); break;
		case 1: Problems::quote_text(5, "second"); break;
		case 2: Problems::quote_text(5, "third"); break;
		case 3: Problems::quote_text(5, "fourth"); break;
		case 4: Problems::quote_text(5, "fifth"); break;
		case 5: Problems::quote_text(5, "sixth"); break;
		case 6: Problems::quote_text(5, "seventh"); break;
		case 7: Problems::quote_text(5, "eighth"); break;
		case 8: Problems::quote_text(5, "ninth"); break;
		case 9: Problems::quote_text(5, "tenth"); break;
		default: Problems::quote_text(5, "eventual"); break;
	}
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ElementOverflow));
	Problems::issue_problem_segment(
		"In the sentence %1, you use the notation '%2' to write a constant value. "
		"But the notation was specified as '%3', which means that the %5 numerical "
		"part should range between 0 and %4.");
	Problems::issue_problem_end();
	return NULL;

@<Report a problem because not enough accuracy is available@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, W);
	Problems::quote_wording(3, lp->prototype_text);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_LPTooLittleAccuracy));
	Problems::issue_problem_segment(
		"In the sentence %1, you use the notation '%2' to write a constant value. "
		"But to store that, I would need greater accuracy than this kind of "
		"value has - see the Kinds page of the Index for the range it has.");
	Problems::issue_problem_end();
	return NULL;

@h Indexing literal patterns for a given kind.

=
void LiteralPatterns::index_all(OUTPUT_STREAM, kind *K) {
	literal_pattern *lp, *benchmark_lp = LiteralPatterns::get_benchmark(K);
	int B = 1, scalings_exist = FALSE;
	if (benchmark_lp) B = Kinds::Scalings::get_integer_multiplier(benchmark_lp->scaling);

	LITERAL_FORMS_LOOP(lp, K)
		if (Kinds::Scalings::involves_scale_change(lp->scaling))
			scalings_exist = TRUE;

	@<Index the list of possible LPs for the kind, not counting equivalents@>;
	@<Index the list of possible LPs for the kind, only counting equivalents@>;
	@<Index the possible names for these notations, as ways of printing them back@>;
}

@ Each entry in this list is, in principle, a list all by itself -- of
alternatives such as "1 tonne" vs "2 tonnes", which aren't different
enough to be listed separately. Of these exactly one is the "primary"
alternative.

@<Index the list of possible LPs for the kind, not counting equivalents@> =
	int f = FALSE;
	LITERAL_FORMS_LOOP(lp, K)
		if ((lp->primary_alternative) && (lp->equivalent_unit == FALSE)) {
			if (f) HTML_TAG("br")
			else WRITE("<i>Written as:</i>");
			HTML_TAG("br");
			if ((scalings_exist) && (benchmark_lp)) {
				LiteralPatterns::index_lp_possibilities(OUT, lp, benchmark_lp);
			} else {
				WRITE("%+W", lp->prototype_text);
			}
			f = TRUE;
		}

@<Index the list of possible LPs for the kind, only counting equivalents@> =
	int f = FALSE;
	LITERAL_FORMS_LOOP(lp, K)
		if ((lp->primary_alternative) && (lp->equivalent_unit)) {
			HTML_TAG("br");
			if (f == FALSE) {
				WRITE("<i>With these equivalent units:</i>");
				HTML_TAG("br");
			}
			LiteralPatterns::index_lp_possibilities(OUT, lp, benchmark_lp);
			f = TRUE;
		}

@<Index the possible names for these notations, as ways of printing them back@> =
	int f = FALSE;
	literal_pattern_name *lpn;
	LOOP_OVER(lpn, literal_pattern_name)
		if (Wordings::nonempty(lpn->notation_name)) {
			LITERAL_FORMS_LOOP(lp, K) {
				literal_pattern_name *lpn2;
				for (lpn2 = lpn; lpn2; lpn2 = lpn2->next)
					if (lp == lpn2->can_use_this_lp) {
						if (f) WRITE("; ");
						else {
							HTML_TAG("br");
							WRITE("\n<i>Can be printed back:</i>\n");
							HTML_TAG("br");
							WRITE("\n&nbsp;&nbsp;&nbsp;&nbsp;");
						}
						f = TRUE;
						WRITE("%+W", lpn->notation_name);
						goto NextLPN;
					}
			}
			NextLPN: ;
		}

@ And here we list of alternatives followed by the relationship this notation
has to the benchmark, e.g., "where 1 tonne $=$ 1000 kg".

=
void LiteralPatterns::index_lp_possibilities(OUTPUT_STREAM, literal_pattern *lp, literal_pattern *benchmark_lp) {
	WRITE("&nbsp;&nbsp;&nbsp;&nbsp;");
	LiteralPatterns::index_lp_possibility(OUT, lp, benchmark_lp);
	if (lp->equivalent_unit) {
		WRITE(" <i>where</i> ");
		LiteralPatterns::lp_index_quantum_value(OUT, lp, lp->scaling);
		WRITE(" = ");
		LiteralPatterns::lp_index_quantum_value(OUT, benchmark_lp, lp->scaling);
	} else {
		if (Kinds::Scalings::compare(lp->scaling, benchmark_lp->scaling) < 0) {
			WRITE(" <i>where</i> ");
			LiteralPatterns::lp_index_quantum_value(OUT, lp, benchmark_lp->scaling);
			WRITE(" = ");
			LiteralPatterns::lp_index_quantum_value(OUT, benchmark_lp, benchmark_lp->scaling);
		}
		if (Kinds::Scalings::compare(lp->scaling, benchmark_lp->scaling) > 0) {
			WRITE(" <i>where</i> ");
			LiteralPatterns::lp_index_quantum_value(OUT, lp, lp->scaling);
			WRITE(" = ");
			LiteralPatterns::lp_index_quantum_value(OUT, benchmark_lp, lp->scaling);
		}
	}
}

@ This is where the list of alternatives, "1 tonne" followed by "2 tonnes",
say, is produced:

=
void LiteralPatterns::index_lp_possibility(OUTPUT_STREAM, literal_pattern *lp, literal_pattern *benchmark_lp) {
	if (lp == benchmark_lp) WRITE("<b>");
	if (lp->plural_form_only)
		LiteralPatterns::lp_index_quantum_value(OUT, lp, Kinds::Scalings::enlarge(lp->scaling, 2));
	else
		LiteralPatterns::lp_index_quantum_value(OUT, lp, lp->scaling);
	if (lp == benchmark_lp) WRITE("</b>");
	if (lp->next_alternative_lp) {
		WRITE(" <i>or</i> ");
		LiteralPatterns::index_lp_possibility(OUT, lp->next_alternative_lp, benchmark_lp);
	}
}

@h Printing values in an LP's notation to the index at compile-time.
This front-end routine chooses the most appropriate notation to use when
indexing a given value. For instance, a mass of 1000000 is best expressed
as "1 tonne", not "1000000 grams".

=
void LiteralPatterns::index_value(OUTPUT_STREAM, literal_pattern *lp_list, int v) {
	literal_pattern *lp;
	literal_pattern *lp_possibility = NULL;
	int k = 0;
	for (lp = lp_list; lp; lp = lp->next_for_this_kind) {
		if (v == 0) {
			if (lp->benchmark) {
				LiteralPatterns::lp_index_value_specific(OUT, lp, v); return;
			}
		} else {
			if ((lp->primary_alternative) && (lp->equivalent_unit == FALSE)) {
				if ((lp_possibility == NULL) || (Kinds::Scalings::quantum(lp->scaling) != k)) {
					lp_possibility = lp;
					k = Kinds::Scalings::quantum(lp->scaling);
				}
				if (v >= Kinds::Scalings::quantum(lp->scaling)) {
					LiteralPatterns::lp_index_value_specific(OUT, lp, v); return;
				}
			}
		}
	}
	if (lp_possibility) LiteralPatterns::lp_index_value_specific(OUT, lp_possibility, v);
	else LiteralPatterns::lp_index_value_specific(OUT, lp_list, v);
}

@ Here we index the benchmark value. Pursuing our example of mass, if the
benchmark is 1 kilogram, then the following indexes the value 1000 in
kilograms, resulting in "1 kg". (This will always effectively look like
"1 something", whatever the something is.)

=
void LiteralPatterns::index_benchmark_value(OUTPUT_STREAM, kind *K) {
	literal_pattern *lp;
	LITERAL_FORMS_LOOP(lp, K)
		if (lp->benchmark) {
			LiteralPatterns::lp_index_quantum_value(OUT, lp, lp->scaling);
			return;
		}
	WRITE("1");
}

@ We are rather formal when printing values to the index, so we choose not
to make use of optional truncation.

=
void LiteralPatterns::lp_index_quantum_value(OUTPUT_STREAM, literal_pattern *lp, scaling_transformation sc) {
	int v = 0;
	double real_v = 0.0;
	if (Kinds::FloatingPoint::uses_floating_point(lp->kind_specified))
		real_v = Kinds::Scalings::real_quantum(sc);
	else
		v = Kinds::Scalings::quantum(sc);
	LiteralPatterns::lp_index_value_specific_inner(OUT, lp, v, real_v);
}

void LiteralPatterns::lp_index_value_specific(OUTPUT_STREAM, literal_pattern *lp, double alt_value) {
	int v = (int) alt_value;
	double real_v = alt_value;
	LiteralPatterns::lp_index_value_specific_inner(OUT, lp, v, real_v);
}

void LiteralPatterns::lp_index_value_specific_inner(OUTPUT_STREAM, literal_pattern *lp, int v, double real_v) {
	if (lp == NULL) { WRITE("--"); return; }
	int tc, ec;
	for (tc=0, ec=0; tc<lp->no_lp_tokens; tc++) {
		if ((tc>0) && (lp->lp_tokens[tc].new_word_at)) WRITE(" ");
		switch (lp->lp_tokens[tc].lpt_type) {
			case WORD_LPT: @<Index a fixed word token within a literal pattern@>; break;
			case CHARACTER_LPT: @<Index a character token within a literal pattern@>; break;
			case ELEMENT_LPT: @<Index an element token within a literal pattern@>; break;
			default: internal_error("unknown literal pattern token type");
		}
	}
}

@ We parse in a case-insensitive way, but print back case-sensitively --
note that the following uses the raw text of the word.

@<Index a fixed word token within a literal pattern@> =
	if (tc > 0) WRITE(" ");
	WRITE("%<N", lp->lp_tokens[tc].token_wn);

@<Index a character token within a literal pattern@> =
	HTML::put(OUT, (int) lp->lp_tokens[tc].token_char);

@<Index an element token within a literal pattern@> =
	if (Kinds::FloatingPoint::uses_floating_point(lp->kind_specified)) {
		WRITE("%g", Kinds::Scalings::real_value_to_quanta(real_v, lp->scaling));
	} else {
		int remainder;
		Kinds::Scalings::value_to_quanta(v, lp->scaling, &v, &remainder);
		literal_pattern_element *lpe = &(lp->lp_elements[ec]);
		if (ec == 0) WRITE("%d", v/(lpe->element_multiplier));
		else {
			char *prototype = "%d";
			if ((lp->lp_tokens[tc].new_word_at == FALSE) && (lpe->without_leading_zeros == FALSE))
				prototype = LiteralPatterns::leading_zero_prototype(lpe->element_range);
			WRITE(prototype, (v/(lpe->element_multiplier)) % (lpe->element_range));
		}
		if (ec == 0) @<Index the fractional part of the value@>;
	}
	ec++;

@<Index the fractional part of the value@> =
	int ranger = 1, M = Kinds::Scalings::get_integer_multiplier(lp->scaling);
	while (M > ranger) ranger = ranger*10;
	remainder = remainder*(ranger/M);
	while ((remainder > 0) && ((remainder % 10) == 0)) {
		ranger = ranger/10; remainder = remainder/10;
	}
	if (remainder > 0) {
		WRITE(".");
		WRITE(LiteralPatterns::leading_zero_prototype(ranger), remainder);
	}

@ Please don't mention the words "logarithm" or "shift". It works fine.

=
char *LiteralPatterns::leading_zero_prototype(int range) {
	if (range > 1000000000) return "%010d";
	if (range > 100000000) return "%09d";
	if (range > 10000000) return "%08d";
	if (range > 1000000) return "%07d";
	if (range > 100000) return "%06d";
	if (range > 10000) return "%05d";
	if (range > 1000) return "%04d";
	if (range > 100) return "%03d";
	if (range > 10) return "%02d";
	return "%d";
}

@ The grammars for the specify sentence are quite complicated, but aren't used
recursively. So it's more convenient to have them set global variables than to
form a big parse subtree and extract the data from that; these are what they
set.

=
literal_pattern *LiteralPatterns::new_literal_specification_inner(lp_specification *lps,
	parse_node *p, parse_node *q, literal_pattern *owner) {
	int offset = 0, integer_scaling = TRUE;
	kind *K = lps->kind_specified;

	literal_pattern *lp = NULL; /* what we will create, if all goes well */

	if (Kinds::FloatingPoint::uses_floating_point(K)) integer_scaling = FALSE;
	if ((lps->uses_real_arithmetic) && (integer_scaling))
		@<Issue problem message warning that real arithmetic is needed@>;

	@<Check that the new notation does not overlap with that of any existing LP@>;
	@<Check that the kind is acceptable as the owner of a LP@>;
	@<Check that any other value mentioned as an equivalent or scaled equivalent has the right kind@>;
	@<Create the new literal pattern structure@>;
	@<Break down the specification text into tokens and elements@>;
	@<Adopt real arithmetic if this is called for@>;
	@<Calculate the multipliers for packing the elements into a single integer@>;

	if (LiteralPatterns::list_of_literal_forms(K) == NULL) lp->benchmark = TRUE;
	LiteralPatterns::add_literal_pattern(K, lp);

	if (lps->part_np_list) {
		@<Work through parts text to assign names to the individual elements@>;
		@<Check that any notes to do with optional elements are mutually compatible@>;
		LiteralPatterns::define_packing_phrases(lp, K);
	}

	if (owner == NULL) owner = lp;
	else @<Add this new alternative to the list belonging to our owner@>;
	return owner;
}

@<Add this new alternative to the list belonging to our owner@> =
	literal_pattern *alt = owner;
	while ((alt) && (alt->next_alternative_lp)) alt = alt->next_alternative_lp;
	alt->next_alternative_lp = lp;

@

@d PARTS_LPC 1
@d SCALING_LPC 2
@d OFFSET_LPC 3
@d EQUIVALENT_LPC 4

@ That's it for syntax: now back to semantics.

@<Check that any other value mentioned as an equivalent or scaled equivalent has the right kind@> =
	if (lps->equivalent_value) {
		if (Rvalues::is_CONSTANT_of_kind(lps->equivalent_value, K)) {
			lps->scaled_dir = LP_SCALED_UP; lps->scale_factor = Rvalues::to_encoded_notation(lps->equivalent_value);
		} else {
			StandardProblems::sentence_problem_with_note(Task::syntax_tree(), _p_(PM_BadLPEquivalent),
				"the equivalent value needs to be a constant of the same kind "
				"of value as you are specifying",
				"and this seems not to be.",
				"Note that you can only use notations specified in sentences "
				"before the current one.");
		}
	}

	if (lps->offset_value) {
		if (Rvalues::is_CONSTANT_of_kind(lps->offset_value, K)) {
			offset = Rvalues::to_encoded_notation(lps->offset_value);
		} else {
			StandardProblems::sentence_problem_with_note(Task::syntax_tree(), _p_(PM_BadLPOffset),
				"the offset value needs to be a constant of the same kind "
				"of value as you are specifying",
				"and this seems not to be.",
				"Note that you can only use notations specified in sentences "
				"before the current one.");
		}
	}

@ We parse the specification text as if it were a constant value, hoping
for the result |NULL| -- so that it doesn't already mean something else.
During this process, we waive checking of numerical overflows in matching
an LP: this is done so that

>> 3/13 specifies a bar. 2/19 specifies a foo.

reports "2/19" as a duplicate using the following problem message, but
does not throw a problem message as being a bar which is out of range
(because in the bar notation, the number after the slash can be at most
13, so that 19 is illegal).

@<Check that the new notation does not overlap with that of any existing LP@> =
	waive_lp_overflows = TRUE;
	kind *K = NULL; if (<s-literal>(lps->notation_wording)) K = Rvalues::to_kind(<<rp>>);
	waive_lp_overflows = FALSE;
	if (K) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_kind(2, K);
		Problems::quote_wording(3, lps->notation_wording);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_DuplicateUnitSpec));
		Problems::issue_problem_segment(
			"In the sentence %1, it looks as if you intend to give a new meaning "
			"to expressions like '%3', but this is already something I "
			"recognise - specifying %2 - so a more distinctive specification "
			"must be chosen.");
		Problems::issue_problem_end();
		return owner;
	}

@<Issue problem message warning that real arithmetic is needed@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_kind(2, K);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_LPNeedsReal));
	Problems::issue_problem_segment(
		"In the sentence %1, it looks as if you intend to give a real "
		"number as a scale factor for values of %2. However, as you've "
		"defined it here, %2 uses only whole numbers, so this wouldn't "
		"work. %PYou can probably fix this by making the example "
		"amount a real number too - say, writing '1.0 rel specifies...' "
		"instead of '1 rel specifies...'.");
	Problems::issue_problem_end();
	return owner;

@<Check that the kind is acceptable as the owner of a LP@> =
	if (Kinds::Behaviour::is_built_in(K)) {
		if (Kinds::Behaviour::get_index_priority(K) == 0)
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_LPBuiltInKOVHidden),
				"you can only specify ways to write new kinds of value",
				"as created with sentences like 'A weight is a kind of value.', "
				"and not the built-in ones like 'number' or 'time'. (This one is "
				"a kind used behind the scenes by Inform, so it's reserved "
				"for Inform's own use, and you can't do much else with it.)");
		else
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_LPBuiltInKOV),
				"you can only specify ways to write new kinds of value",
				"as created with sentences like 'A weight is a kind of value.', "
				"and not the built-in ones like 'number' or 'time'.");
		return owner;
	}
	if (Kinds::Behaviour::convert_to_unit(K) == FALSE) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_LPEnumeration),
			"this is a kind of value which already has named values",
			"so it can't have a basically numerical form as well.");
		return owner;
	}

@ All the hard work here was done during parsing.

@<Create the new literal pattern structure@> =
	lp = LiteralPatterns::lp_new(K, lps->notation_wording);
	if (lps->equivalent_value) lps->scale_factor_as_double = lps->equivalent_value_as_double;
	if (lps->scale_factor <= 0) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_LPNonpositiveScaling),
			"you can only scale by a positive multiple",
			"so something like 'scaled up by -1' is not allowed.");
		lps->scale_factor = 1;
	}
	lp->scaling = Kinds::Scalings::new(integer_scaling, lps->scaled_dir,
		lps->scale_factor, lps->scale_factor_as_double, offset, lps->offset_value_as_double);
	if (owner == NULL) lp->primary_alternative = TRUE;
	if (lps->equivalent_value) lp->equivalent_unit = TRUE;
	if (lps->notation_options & SINGULAR_LPN) lp->singular_form_only = TRUE;
	if (lps->notation_options & PLURAL_LPN) lp->plural_form_only = TRUE;
	for (literal_pattern_name *lpn = lps->notation_groups; lpn; lpn = lpn->next_with_rp)
		lpn->can_use_this_lp = lp;

@ Each word is either a whole token in itself, or a stream of tokens representing
alphabetic vs numeric pieces of a word:

@<Break down the specification text into tokens and elements@> =
	int i, j, tc, ec;
	for (i=0, tc=0, ec=0; i<Wordings::length(lps->notation_wording); i++) {
		literal_pattern_token new_token;
		int digit_found = FALSE;
		wchar_t *text_of_word = Lexer::word_raw_text(Wordings::first_wn(lps->notation_wording)+i);
		for (j=0; text_of_word[j]; j++) if (Characters::isdigit(text_of_word[j])) digit_found = TRUE;
		if (digit_found)
			@<Break up the word into at least one element token, and perhaps also character tokens@>
		else {
			new_token = LiteralPatterns::lpt_new(WORD_LPT, TRUE);
			new_token.token_wn = Wordings::first_wn(lps->notation_wording)+i;
			@<Add new token to LP@>;
		}
	}
	lp->no_lp_tokens = tc;
	lp->no_lp_elements = ec;
	if (lp->no_lp_elements == 0) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_LPWithoutElement),
			"a way to specify a kind of value must involve numbers",
			"so '10kg specifies a weight' is allowed, but not 'tonne "
			"specifies a weight'.");
		return owner;
	}

@ Bounds checking is easier here since we know that a LP specification will
not ever need to create the maximum conceivable value which a C integer can
hold -- so we need not fool around with long long ints.

@<Break up the word into at least one element token, and perhaps also character tokens@> =
	int j, sgn = 1, next_token_begins_word = TRUE;
	for (j=0; text_of_word[j]; j++) {
		int tot = 0, digit_found = FALSE, point_found = FALSE;
		if ((text_of_word[j] == '-') && (Characters::isdigit(text_of_word[j+1])) && (ec == 0)) {
			sgn = -1; continue;
		}
		while (Characters::isdigit(text_of_word[j++])) {
			digit_found = TRUE;
			if (tot > 999999999) {
				StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_LPElementTooLarge),
					"that specification contains numbers that are too large",
					"and would construct values which could not sensibly "
					"be stored at run-time.");
				return owner;
			}
			tot = 10*tot + (text_of_word[j-1]-'0');
		}
		j--;
		if ((text_of_word[j] == '.') && (text_of_word[j+1] == '0') && (ec == 0)) {
			j += 2; point_found = TRUE;
		}
		if (digit_found) {
			literal_pattern_element new_element = LiteralPatterns::lpe_new(ec, tot+1, sgn);
			if (ec >= MAX_ELEMENTS_PER_LITERAL) {
				StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_LPTooManyElements),
					"that specification contains too many numerical elements",
					"and is too complicated for Inform to handle.");
				return owner;
			}
			new_element.is_real = point_found;
			if (point_found) integer_scaling = FALSE;
			lp->lp_elements[ec++] = new_element;
			if (sgn == -1) lp->number_signed = TRUE;
			new_token = LiteralPatterns::lpt_new(ELEMENT_LPT, next_token_begins_word);
			@<Add new token to LP@>;
			j--;
		} else {
			new_token = LiteralPatterns::lpt_new(CHARACTER_LPT, next_token_begins_word);
			new_token.token_char = text_of_word[j];
			@<Add new token to LP@>;
		}
		sgn = 1; next_token_begins_word = FALSE;
	}

@ In fact counting tokens is not necessarily a good way to measure the
complexity of an LP, since any long run of characters in a word which
also contains a number will splurge the number of tokens. So
|MAX_TOKENS_PER_LITERAL| is set to a high enough value that this will
not really distort matters.

@<Add new token to LP@> =
	if (tc >= MAX_TOKENS_PER_LITERAL) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_LPTooComplicated),
			"that specification is too complicated",
			"and will have to be shortened.");
		return owner;
	}
	lp->lp_tokens[tc++] = new_token;

@<Adopt real arithmetic if this is called for@> =
	if (integer_scaling == FALSE) {
		Kinds::Behaviour::convert_to_real(K);
		Kinds::Scalings::convert_to_real(&(lp->scaling));
	}

@ The elements are created in parsing order, that is, left to right. But
the multipliers can only be calculated by working from right to left, so
this is deferred until all elements exist, at which point we --

@<Calculate the multipliers for packing the elements into a single integer@> =
	int i, m = 1;
	for (i=lp->no_lp_elements-1; i>=0; i--) {
		literal_pattern_element *lpe = &(lp->lp_elements[i]);
		lpe->element_multiplier = m;
		m = m*(lpe->element_range);
	}

@ Today, we have naming of parts:

@<Work through parts text to assign names to the individual elements@> =
	int i;
	parse_node *p;
	for (i=0, p=lps->part_np_list; (i<lp->no_lp_elements) && (p); i++, p = p->next) {
		literal_pattern_element *lpe = &(lp->lp_elements[i]);
		lpe->element_name = Node::get_text(p);
		int O = Annotations::read_int(p, lpe_options_ANNOT);
		if (O & OPTIONAL_LSO) lpe->element_optional = TRUE;
		if (O & PREAMBLE_OPTIONAL_LSO) {
			lpe->element_optional = TRUE; lpe->preamble_optional = TRUE;
		}
		if (O & WITHOUT_LEADING_ZEROS_LSO) lpe->without_leading_zeros = TRUE;
		if ((i == lp->no_lp_elements - 1) && (p->next)) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_LPTooManyPartNames),
				"this gives names for too many parts",
				"that is, for more parts than there are in the pattern.");
			return owner;
		}
		for (int j = 0; j<i; j++)
			if (Wordings::match(lp->lp_elements[i].element_name, lp->lp_elements[j].element_name))
				StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_LPRepeatedPartNames),
					"this repeats a part name",
					"that is, it uses the same name for two different parts "
					"of the pattern.");
	}
	if ((i > 0) && (i != lp->no_lp_elements)) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_LPNotAllNamed),
			"you must supply names for all the parts",
			"if for any");
		return owner;
	}

@ In fact, the test is a simple one: there can be only one element declared
optional, and it must not be the first.

@<Check that any notes to do with optional elements are mutually compatible@> =
	int i, opt_count = 0;
	for (i=0; i<lp->no_lp_elements; i++) if (lp->lp_elements[i].element_optional) {
		opt_count++;
		if (i == 0) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_LPFirstOptional),
				"the first part is not allowed to be optional",
				"since it is needed to identify the value.");
			return owner;
		}
	}
	if (opt_count >= 2) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_LPMultipleOptional),
			"only one part can be called optional",
			"since if any part is omitted then so are all subsequent parts.");
		return owner;
	}

@ Group names are created when first seen; the following recognises one which
has been seen before.

=
<lp-group-name> internal {
	literal_pattern_name *lpn;
	LOOP_OVER(lpn, literal_pattern_name) {
		if (Wordings::match(lpn->notation_name, W)) {
			==> { -, lpn }; return TRUE;
		}
	}
	==> { fail nonterminal };
}

@ And this is the routine which does the creation. The text will actually be
empty where there's an existing literal pattern name. (For instance, each
time we see a literal pattern given as "in Imperial units", we create a
fresh LPN structure, but only the first one to be created contains the
wording.)

=
literal_pattern_name *LiteralPatterns::new_lpn(wording W, literal_pattern_name *existing) {
	if (preform_lookahead_mode) return NULL;
	literal_pattern_name *new = CREATE(literal_pattern_name);
	new->notation_name = W;
	new->can_use_this_lp = NULL;
	new->next = NULL;
	new->next_with_rp = NULL;
	if (existing) {
		while ((existing) && (existing->next)) existing = existing->next;
		existing->next = new;
	}
	return new;
}

@h I7 phrases to print values in specified ways.
When an LP has a name, it's a notation which the source text can request
to be used in saying a value. This is where the corresponding text substitutions
are declared.

=
void LiteralPatterns::define_named_phrases(void) {
	literal_pattern_name *lpn;
	LOOP_OVER(lpn, literal_pattern_name)
		lpn->lpn_compiled_already = FALSE;
	LOOP_OVER(lpn, literal_pattern_name) {
		if (Wordings::nonempty(lpn->notation_name)) {
			literal_pattern_name *lpn2;
			for (lpn2 = lpn; lpn2; lpn2 = lpn2->next)
				if (lpn2->lpn_compiled_already == FALSE)
					@<Compile the printing phrase for this and perhaps subsequent LPs@>;
		}
	}
	ImperativeSubtrees::accept_all();
}

@ These text substitutions correspond exactly neither to the LPs nor to the
names. For instance, "in tonnes" produces a text substitution which takes
in both the LP for "1 tonne" and for "2 tonnes", deciding at run-time
which to use. And on the other hand, "in metric units" may produce text
substitutions for many different kinds, distinguished by type-checking:

>> To say (val - mass) in metric units: ...

>> To say (val - length) in metric units: ...

The following creates one text substitution for each different kind among
the LPs under each named possibility.

@<Compile the printing phrase for this and perhaps subsequent LPs@> =
	kind *K = lpn2->can_use_this_lp->kind_specified;
	TEMPORARY_TEXT(TEMP)
	Kinds::Textual::write(TEMP, K);

	feed_t id = Feeds::begin();
	Feeds::feed_C_string(L"To say ( val - ");
	Feeds::feed_text(TEMP);
	Feeds::feed_C_string(L" ) ");
	Feeds::feed_wording(lpn->notation_name);
	wording XW = Feeds::end(id);
	Sentences::make_node(Task::syntax_tree(), XW, ':');

	id = Feeds::begin();
	TEMPORARY_TEXT(print_rule_buff)
	WRITE_TO(print_rule_buff, " (- {-printing-routine:%S", TEMP);
	WRITE_TO(print_rule_buff, "}({val}, %d); -) ", lpn->allocation_id + 1);
	Feeds::feed_text(print_rule_buff);
	DISCARD_TEXT(print_rule_buff)
	XW = Feeds::end(id);
	Sentences::make_node(Task::syntax_tree(), XW, '.');
	DISCARD_TEXT(TEMP)

	literal_pattern_name *lpn3;
	for (lpn3 = lpn2; lpn3; lpn3 = lpn3->next)
		if (Kinds::eq(K, lpn3->can_use_this_lp->kind_specified))
			lpn3->lpn_compiled_already = TRUE;

@h I7 phrases to pack and unpack the value.
Creating a LP implicitly defines further I7 source text, as follows.

=
void LiteralPatterns::define_packing_phrases(literal_pattern *lp, kind *K) {
	TEMPORARY_TEXT(TEMP)
	Kinds::Textual::write(TEMP, K);
	@<Define phrases to convert from a packed value to individual parts@>;
	@<Define a phrase to convert from numerical parts to a packed value@>;
	ImperativeSubtrees::accept_all();
	DISCARD_TEXT(TEMP)
}

@ First, we automatically create $n$ phrases to unpack the elements given the value.
For instance, defining:
= (text as Inform 7)
$10.99 specifies a price with parts dollars and cents.
=
automatically generates:
= (text as Inform 7)
To define which number is dollars part of ( full - price ) : |(- ({full}/100) -)|.
To define which number is cents part of ( full - price ) : |(- ({full}%100) -)|.
=

@<Define phrases to convert from a packed value to individual parts@> =
	int i;
	for (i=0; i<lp->no_lp_elements; i++) {
		literal_pattern_element *lpe = &(lp->lp_elements[i]);

		feed_t id = Feeds::begin();
		Feeds::feed_C_string(L"To decide which number is ");
		Feeds::feed_wording(lpe->element_name);
		Feeds::feed_C_string(L" part of ( full - ");
		Feeds::feed_text(TEMP);
		Feeds::feed_C_string(L" ) ");
		wording XW = Feeds::end(id);
		Sentences::make_node(Task::syntax_tree(), XW, ':');

		id = Feeds::begin();
		TEMPORARY_TEXT(print_rule_buff)
		if (i==0)
			WRITE_TO(print_rule_buff, " (- ({full}/%d) -) ", lpe->element_multiplier);
		else if (lpe->element_multiplier > 1)
			WRITE_TO(print_rule_buff, " (- (({full}/%d)%%%d) -) ",
				lpe->element_multiplier, lpe->element_range);
		else
			WRITE_TO(print_rule_buff, " (- ({full}%%%d) -) ", lpe->element_range);
		Feeds::feed_text(print_rule_buff);
		XW = Feeds::end(id);
		if (Wordings::phrasual_length(XW) >= MAX_WORDS_PER_PHRASE + 5)
			@<Issue a problem for overly long part names@>
		else
			Sentences::make_node(Task::syntax_tree(), XW, '.');
		DISCARD_TEXT(print_rule_buff)
	}

@ And similarly, a packing phrase to calculate the value given its elements.
For instance, the dollars-and-cents example compiles:
= (text as Inform 7)
To decide which price is price with dollars part ( part0 - a number ) cents part ( part1 - a number) :
		|(- ({part0}*100+{part1}) -).|
=

@<Define a phrase to convert from numerical parts to a packed value@> =
	if (lp->no_lp_elements > 0) {
		feed_t id = Feeds::begin();
		Feeds::feed_C_string(L"To decide which ");
		Feeds::feed_text(TEMP);
		Feeds::feed_C_string(L" is ");
		Feeds::feed_text(TEMP);
		Feeds::feed_C_string(L" with ");
		for (int i=0; i<lp->no_lp_elements; i++) {
			literal_pattern_element *lpe = &(lp->lp_elements[i]);
			TEMPORARY_TEXT(print_rule_buff)
			WRITE_TO(print_rule_buff, " part%d ", i);
			Feeds::feed_wording(lpe->element_name);
			Feeds::feed_C_string(L" part ( ");
			Feeds::feed_text(print_rule_buff);
			Feeds::feed_C_string(L" - a number ) ");
			DISCARD_TEXT(print_rule_buff)
		}
		wording XW = Feeds::end(id);
		if (Wordings::phrasual_length(XW) >= MAX_WORDS_PER_PHRASE + 5) {
			@<Issue a problem for overly long part names@>
		} else {
			Sentences::make_node(Task::syntax_tree(), XW, ':');
			id = Feeds::begin();
			TEMPORARY_TEXT(print_rule_buff)
			WRITE_TO(print_rule_buff, " (- (");
			for (int i=0; i<lp->no_lp_elements; i++) {
				literal_pattern_element *lpe = &(lp->lp_elements[i]);
				if (i>0) WRITE_TO(print_rule_buff, "+");
				if (lpe->element_multiplier != 1)
					WRITE_TO(print_rule_buff, "%d*", lpe->element_multiplier);
				WRITE_TO(print_rule_buff, "{part%d}", i);
			}
			WRITE_TO(print_rule_buff, ") -) ");
			Feeds::feed_text(print_rule_buff);
			XW = Feeds::end(id);
			DISCARD_TEXT(print_rule_buff)
			Sentences::make_node(Task::syntax_tree(), XW, '.');
		}
	}

@<Issue a problem for overly long part names@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_LPPartNamesTooLong),
		"the names for these parts are too long",
		"and will have to be cut down.");

@h The kind's list.
On reading "5 feet 4 inches specifies a height", Inform parses
"5 feet 4 inches" into a |literal_pattern| structure and then calls this
routine to attach it to the kind "height". (Multiple patterns can be
attached to the same kind, and they become alternative syntaxes.)

=
void LiteralPatterns::add_literal_pattern(kind *K, literal_pattern *lp) {
	if (K == NULL) internal_error("can't add LP to null kind");
	K->construct->ways_to_write_literals =
		LiteralPatterns::list_add(
			K->construct->ways_to_write_literals, lp,
			Kinds::FloatingPoint::uses_floating_point(lp->kind_specified));
}

@ And here we find the list of such notations.

=
literal_pattern *LiteralPatterns::list_of_literal_forms(kind *K) {
	if (K == NULL) return NULL;
	return K->construct->ways_to_write_literals;
}

@h Literal patterns in Preform.
Everything is finally set up so that we can define the following, which
recognises any literal written using a pattern. On success, it produces a
specification for an rvalue of the kind in question.

=
<s-literal-unit-notation> internal {
	literal_pattern *lp;
	LOOP_OVER(lp, literal_pattern) {
		int val;
		kind *K = LiteralPatterns::match(lp, W, &val);
		if (K) { ==> { val, Rvalues::from_encoded_notation(K, val, W) }; return TRUE; }
	}
	==> { fail nonterminal };
}
