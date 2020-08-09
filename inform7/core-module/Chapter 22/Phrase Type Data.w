[Phrases::TypeData::] Phrase Type Data.

To create, manage, compare the logical specificity of, and assist
excerpt parsing concerning, the type of a To phrase. This involves whether
it is void, determines a condition or returns a value (and if so, what
kind of value); and also what parameters it takes (possibly values, possible
other types used by inline definitions) and their types in turn.

@ Inform is an unusual language in that it does not distinguish between
functions, control structures and keywords: they are all phrases. This
means that the functional description of what a phrase does has to be more
than just a kind like |phrase number -> text|. For example, "if ..., ..."
is a phrase in Inform, but it has no kind as such: the first "..." is a
condition, the second "..." a phrase invocation, and neither one of those
is a value, so neither one has a kind. It follows that we are going to
need a rather larger data structure to describe what a phrase does than
simply a kind, and that's what we create in this section.

Here's a simple example from the Standard Rules:

>> To sort (T - table name) in (TC - table column) order: ...

The "word sequence" for this consists of five "words": sort, 0, in, 1,
order. That is, we store five integers: the word numbers for "sort", "in"
and "order", and then very low integers represent tokens rather than fixed
wording. (It follows from this that a phrase can't be defined in the first
ten words of the source text, but that's okay, because those words can
never be from the author's own source text anyway -- they contain the
instruction to load the Standard Rules.)

The tokens are the variably-worded parts written with brackets. The "token
sequence" consists of two tokens, "T - table name" and "TC - table column".

@d MAX_TOKENS_PER_PHRASE 10
@d MAX_WORDS_PER_PHRASE 32 /* the most the excerpt parser can hold anyway */

=
typedef struct ph_type_data {
	struct wording registration_text; /* words used to register the excerpt meaning */
	int word_sequence[MAX_WORDS_PER_PHRASE]; /* the "word sequence": see above */
	int no_words; /* length of the word sequence */

	struct phrase_token token_sequence[MAX_TOKENS_PER_PHRASE];
	int no_tokens;

	int manner_of_return; /* one of the |*_MOR| values */
	struct kind *return_kind; /* |NULL| except in the |DECIDES_VALUE_MOR| case */

	struct say_details as_say; /* used only for "say" phrases, that is, text substitutions */
	struct inline_details as_inline; /* side effects for phrases like C keywords */

	int now_deprecated; /* is this a phrase likely to be withdrawn in future? */
} ph_type_data;

@ The two tokens of our example phrase, then, are each stored in one of these:

@d STANDARD_PT_CONSTRUCT 1 /* e.g., |12|, |number|, |open door| */
@d NEW_LOCAL_PT_CONSTRUCT 2 /* e.g., |nonexisting number variable| */
@d EXISTING_LOCAL_PT_CONSTRUCT 3 /* e.g., |existing number variable| */
@d CONDITION_PT_CONSTRUCT 4 /* e.g., |a condition| */
@d STORAGE_PT_CONSTRUCT 5 /* e.g., |storage| */
@d TABLE_REFERENCE_PT_CONSTRUCT 6 /* e.g., |table-reference| */
@d KIND_NAME_PT_CONSTRUCT 7 /* e.g., |name of kind| */
@d VOID_PT_CONSTRUCT 8 /* e.g., or in fact only, |phrase| */

=
typedef struct phrase_token {
	struct wording token_name; /* name */
	struct parse_node *to_match; /* what we expect to find here */
	struct kind *token_kind;
	int construct; /* one of the above values */
} phrase_token;

@ At first sight that structure looks a bit redundant. Why do we store both a
specification, telling the matcher what to allow, and also a kind?

The answer is that the kinds hierarchy is not rich enough. "Door" is a kind,
but "open door" is not, and nor is "even number", or

>> a woman in a lighted room

It seems at first appealing to decide that "open door" (say) ought to be
a kind, but no variable with this kind would be safe: merely by opening a
door somewhere during play, the player could make its current value no
longer fit its kind.

In order to preserve type safety, Inform forces its storage objects
(variables, table entries, and so on) to have fixed kinds decided at compile
time. We are allowed to create a "number that varies", but not an "even
number that varies", because the former is a kind and the latter is not.
This is rather like C, where variables might be declared like so:
= (text as C)
	int width, height; char *name;
=
In C, the range of types which can be stored is the same as the range of
types which can be function arguments, so for instance:
= (text as C)
	int area(int width, int height) { return width*height; }
=
But whereas Inform's variables are much like C's, Inform's phrase definitions
are not like C's functions, and they can have much more general arguments:

>> To jemmy open (the barrier - a closed door): ...

>> To repeat (P - a phrase) indefinitely: ...

We therefore need a much more general way to describe what text can appear
in phrase arguments than a kind can provide, and this is what leads us to
the idea of a "specification". In fact, though, even these examples are
not general enough. Natural language is very slippery about concepts which,
in most computing theories, are formally separate. Consider for instance
the overloaded definition of a phrase like this one:

>> To appreciate (composer - a person): ...

>> To appreciate (composer - Alessandro Striggio): ...

The early design of Inform did not permit this, since it clearly confused
values and types, but this lack was in fact reported as a bug -- always a
sign that users considered it a natural thing to do. Specifications therefore
needed to be able to represent not only vague descriptions like "person",
but also explicit identities like "Alessandro Striggio".

Moreover we can't store the specification alone, because then these can't be
represented:

>> (tally - arithmetic value of kind K)
>> (name of a kind of enumerated value)

@ Say phrases -- text substitutions, that is -- need more:

=
typedef struct say_details {
	int say_phrase; /* one of the three |*_SAY_PHRASE| values */
	int say_phrase_running_on; /* ignore implied newlines in previous invocation */
	int say_phrase_stream_position; /* one of the |SSP_*| values above */
	int say_phrase_stream_token_at; /* word number of say stream token name */
	int say_phrase_stream_closing_token_at; /* ditto for choice of ending */
	int say_control_structure; /* one of the four |*_SAY_CS| values below */
} say_details;

@ These are for "say control structures", as in "fish [if day is Friday]of
course[end if]" -- the "[if ...]" and "[end if]" both being say phrases which
are control structures.

@d NO_SAY_CS 0
@d IF_SAY_CS 1
@d OTHERWISE_SAY_CS 2
@d OTHERWISE_IF_SAY_CS 3
@d END_IF_SAY_CS 4

@ The say stream is the sequence of successive invocations in a single say,
or in a piece of text with substitutions. Some say phrases are compound in that
they must occur in a given sequence.

The following markers are used to identify such say phrases:

@d SSP_NONE 0
@d SSP_START 1
@d SSP_MIDDLE 2
@d SSP_END 3

@ Inline phrase definitions are used to implement what, in other languages,
would be control-structure keywords, so inline phrases sometimes need bells,
whistles and doodads which regular phrases don't.

=
typedef struct inline_details {
	int invoked_inline_not_as_call; /* if |FALSE|, none of the rest applies */

	int let_phrase; /* one of the |*_LET_PHRASE| values below */
	int assignment_phrase; /* |TRUE| if this has to be typechecked as an assignment */
	int arithmetical_operation; /* |-1|, or one of the |*_OPERATION| constants */

	int block_follows; /* for inline phrases only: followed by a begin... end block? */
	wchar_t *only_in_loop; /* if not null, the phrase can only be used in this block */
} inline_details;

@ Where:

@d NOT_A_LET_PHRASE 0 /* needs to be 0 so that |let_phrase| can be a C condition */
@d ASSIGNMENT_LET_PHRASE 1 /* the regular "let" */
@d EQUATION_LET_PHRASE 2 /* "let" inviting Inform to solve an equation */

@h Creation.

=
ph_type_data Phrases::TypeData::new(void) {
	ph_type_data phtd;
	phtd.registration_text = EMPTY_WORDING;

	phtd.manner_of_return = DECIDES_NOTHING_MOR;
	phtd.return_kind = NULL;

	phtd.no_words = 0;
	phtd.no_tokens = 0;

	phtd.as_say = Phrases::TypeData::new_say_details();
	phtd.as_inline = Phrases::TypeData::new_inline_details();

	phtd.now_deprecated = FALSE;
	return phtd;
}

@ And the manner of return is set shortly after that:

=
void Phrases::TypeData::set_mor(ph_type_data *phtd, int mor, kind *K) {
	phtd->manner_of_return = mor;
	phtd->return_kind = K;
}

int Phrases::TypeData::get_mor(ph_type_data *phtd) {
	return phtd->manner_of_return;
}

kind *Phrases::TypeData::get_return_kind(ph_type_data *phtd) {
	if (phtd->manner_of_return == DECIDES_CONDITION_MOR) return K_truth_state;
	return phtd->return_kind;
}

@ =
char *Phrases::TypeData::describe_manner_of_return(int mor, ph_type_data *phtd, kind **K) {
	switch (mor) {
		case DECIDES_NOTHING_MOR: return "no value resulting";
		case DECIDES_VALUE_MOR:
			if ((phtd) && (phtd->return_kind) && (K)) *K = phtd->return_kind;
			return "a phrase to decide a value";
		case DECIDES_CONDITION_MOR: return "a phrase to make a decision";
		case DECIDES_NOTHING_AND_RETURNS_MOR:
			return "a phrase providing an outcome to a rulebook";
	}
	return "some phrase"; /* should never actually be needed */
}

@h The kind of a phrase.
As noted above, phrases can be such that "kind" is meaningless (consider "if",
or "now"), but it might be tempting to think that for function-like phrases,
at least, the kind tells you everything about when they apply. But this isn't
true. Consider:

>> To barricade (D - a door): ...
>> To barricade (D - a closed door): ...

These both have the same kind, |phrase door -> nothing|, and that's reasonable
because they're safe to use in the same circumstances. But they will apply
in different circumstances at run-time.

A further subtlety comes with phrases like:

>> To juxtapose (name of kind of value K) with (alpha - K) and (beta - K): ...

What's the kind of this? From the point of view of compilation, it's
= (text)
	phrase (K, K) -> nothing
=
but this is not quite right, because it doesn't make clear how Inform is to
infer the kind K -- should it take it from the value supplied as alpha, or
beta? This makes a difference in some cases of ambiguity. The answer of
course is neither: for example, when Inform reads

>> juxtapose numbers with 12 and 31;

it sets K to "number" from the explicit text "numbers", rather than inferring
it from the 12 or the 31. So, internally, Inform regards the kind of this
phrase as
= (text)
	phrase (K, K, K) -> nothing
=
even though it will compile actual function calls to "juxtapose" with two
rather than three arguments. (This is all a sort of poor man's second-order
logic, since one argument is in effect a kind rather than a value.)

=
kind *Phrases::TypeData::kind(ph_type_data *phtd) {
	kind *argument_kinds[MAX_TOKENS_PER_PHRASE];
	int i, j = 0;
	for (i=0; i<phtd->no_tokens; i++)
		argument_kinds[j++] = phtd->token_sequence[i].token_kind;
	kind *R = Phrases::TypeData::get_return_kind(phtd);
	return Kinds::function_kind(j, argument_kinds, R);
}

@ Whence:

=
int Phrases::TypeData::contains_variables(ph_type_data *phtd) {
	return
		Kinds::contains(
			Phrases::TypeData::kind(phtd),
			CON_KIND_VARIABLE);
}

@ More specifically:

=
int Phrases::TypeData::tokens_contain_variable(ph_type_data *phtd, int v) {
	for (int i=0; i<phtd->no_tokens; i++)
		if (Kinds::Behaviour::involves_var(phtd->token_sequence[i].token_kind, v))
			return TRUE;
	return FALSE;
}

@h The tokens.

=
int Phrases::TypeData::get_no_tokens(ph_type_data *phtd) {
	return phtd->no_tokens;
}

@ =
int Phrases::TypeData::index_of_token_creating_a_variable(ph_type_data *phtd) {
	int i;
	for (i=0; i<phtd->no_tokens; i++)
		if (phtd->token_sequence[i].construct == NEW_LOCAL_PT_CONSTRUCT)
			return i;
	return -1;
}

@ This odd-looking question is asked when handling the ambiguity between the
name of a property ("carrying capacity", say) as a value in its own right,
and the same name metonymically referring to the value of the property for
a given instance ("carrying capacity of the player", say).

=
int Phrases::TypeData::preamble_requires_property_value(ph_type_data *phtd) {
	int i;
	for (i=0; i<phtd->no_tokens; i++) {
		if (Lvalues::get_storage_form(phtd->token_sequence[i].to_match)
			== PROPERTY_VALUE_NT)
			return FALSE;
	}
	return TRUE;
}

@h Deprecation.
Phrases which are "deprecated" are those defined by the Standard Rules, or
other extensions in the standard Inform installation, which we now think are
redundant or a bad idea: we don't want to withdraw them without warning, so
the procedure is to deprecate them in one major build and withdraw them
in the next.

=
int Phrases::TypeData::deprecated(ph_type_data *phtd) {
	return phtd->now_deprecated;
}

void Phrases::TypeData::deprecate_phrase(ph_type_data *phtd) {
	phtd->now_deprecated = TRUE;
}

@h Adding token names to a stack frame.
Suppose Inform is compiling code to represent this:

>> To sort (T - table name) in (TC - table column) order: ...

On the stack frame for this code, "T" and "TC" will need to be local
variables -- that is, they will need to be locally available as names,
referring to the values which the phrase was called with.

In that simple example, the phrase preamble makes clear what the kinds of
"T" and "TC" should be, but it isn't always so simple. For example:

>> To add (new entry - K) to (L - list of values of kind K): ...

Here the preamble allows a wide range of kinds, and Inform compiles
different versions of the code for each value of K actually needed. So
the following routine is called with a particular kind to be used. For
instance, if the source text ever contains an invocation like:

>> add 14 to the list of scores;

then at some point Inform will have to compile a version of the phrase
which has the kind:
= (text)
	phrase (number, list of numbers) -> nothing
=
The routine below then dismantles that kind to extract the kinds of the
arguments, "number" and then "list of numbers", and creates local
variables "new entry" and "L" with those kinds.

=
void Phrases::TypeData::into_stack_frame(ph_stack_frame *phsf,
	ph_type_data *phtd, kind *kind_in_this_compilation, int first) {
	if (Kinds::get_construct(kind_in_this_compilation) != CON_phrase)
		internal_error("no function kind");

	kind *args = NULL, *ret = NULL;
	Kinds::binary_construction_material(kind_in_this_compilation, &args, &ret);

	int i;
	for (i=0; i<phtd->no_tokens; i++) {
		kind *K;
		if (Kinds::get_construct(args) != CON_TUPLE_ENTRY) internal_error("bad tupling");
		Kinds::binary_construction_material(args, &K, &args);
		if (first) {
			LocalVariables::add_call_parameter(phsf, phtd->token_sequence[i].token_name, K);
		} else {
			local_variable *lvar = LocalVariables::get_ith_parameter(i);
			if (lvar) LocalVariables::set_kind(lvar, K);
		}
	}

	if (Kinds::Compare::eq(ret, K_nil)) Frames::set_kind_returned(phsf, NULL);
	else Frames::set_kind_returned(phsf, ret);
}

@h Comparison of PHTDs.
This is used when sorting "To..." phrases in order of logical priority:
see Phrases for the return codes.

=
int Phrases::TypeData::comparison(ph_type_data *phtd1, ph_type_data *phtd2) {

	if (phtd1 == phtd2) return EQUAL_PH;

	@<Loop construct keywords have priority@>;
	@<More fixed words beats fewer@>;
	@<More tokens beats fewer@>;
	@<Next use alphabetical order, counting tokens as after the Zs@>;
	@<Finally try comparing the to-match specifications of the tokens@>;

	return INCOMPARABLE_PH;
}

@<Loop construct keywords have priority@> =
	int i = Phrases::TypeData::inline_type_data_comparison(phtd1, phtd2);
	if (i != EQUAL_PH) return i;

@<More fixed words beats fewer@> =
	int fw1 = phtd1->no_words - phtd1->no_tokens;
	int fw2 = phtd2->no_words - phtd2->no_tokens;
	if (fw1 > fw2) return BEFORE_PH;
	if (fw1 < fw2) return AFTER_PH;

@<More tokens beats fewer@> =
	if (phtd1->no_tokens > phtd2->no_tokens) return BEFORE_PH;
	if (phtd1->no_tokens < phtd2->no_tokens) return AFTER_PH;

@ At this point the two phrases have the same number of words and tokens,
but the words may be different and/or the tokens in different places.
We might for example be comparing these two:

>> To grab (the prize - an object) swiftly: ...
>> To grab at (the rosette - an object): ...

We alphabetical order, placing "grab ZZZZZZ swiftly" after "grab at ZZZZZZ".

@<Next use alphabetical order, counting tokens as after the Zs@> =
	int i;
	for (i=0; i<phtd1->no_words; i++) {
		if (phtd1->word_sequence[i] < MAX_TOKENS_PER_PHRASE) {
			if (phtd2->word_sequence[i] >= MAX_TOKENS_PER_PHRASE)
				return AFTER_PH;
		} else {
			if (phtd2->word_sequence[i] < MAX_TOKENS_PER_PHRASE) return BEFORE_PH;
			int x = Wide::cmp(
				Lexer::word_raw_text(phtd1->word_sequence[i]),
				Lexer::word_raw_text(phtd2->word_sequence[i]));
			if (x > 0) return AFTER_PH;
			if (x < 0) return BEFORE_PH;
		}
	}

@ Now our two phrases have identical wording, and tokens in the same positions,
but may have different specifications for them. For example:

>> To grab at (the rosette - an object): ...
>> To grab at (the rosette - a thing on the table): ...

We give priority to the second of these, because it's more specific. On
the other hand these are simply incomparable:

>> To grab at (the rosette - an object): ...
>> To grab at (the prime - a number): ...

@<Finally try comparing the to-match specifications of the tokens@> =
	int i, possibly_subschema = TRUE, possibly_superschema = TRUE;
	for (i=0; i<phtd1->no_tokens; i++) {
		parse_node *spec1 = phtd1->token_sequence[i].to_match;
		parse_node *spec2 = phtd2->token_sequence[i].to_match;
		@<See if the ith token rules out being a sub- or superschema@>;
	}
	if ((possibly_subschema) || (possibly_superschema))
		@<These are worryingly similar in wording, so check the return kinds@>;
	if (possibly_subschema) return SUBSCHEMA_PH;
	if (possibly_superschema) return SUPERSCHEMA_PH;

@ We need to watch out for this sort of thing:

>> To decide what number is my special value: decide on 4.
>> To decide what person is my special value: decide on the player.

which makes "my special value" of a kind which can't be decided; but
we can't just compare the return kinds, because that might pick up
false positives in the case of kind variables, etc.

@<These are worryingly similar in wording, so check the return kinds@> =
	if ((phtd1->manner_of_return != phtd2->manner_of_return) ||
		((Kinds::Compare::eq(phtd1->return_kind, phtd2->return_kind) == FALSE) &&
			(Kinds::Behaviour::definite(phtd1->return_kind))))
		return CONFLICTED_PH;

@ We delegate to |Specifications::compare_specificity| to decide what's more
specific, but note that this routine can return 0 (meaning, equally
specific) for two different reasons: because the specifications are basically
the same as each other, or because they're completely different but have
about the same complexity. The |wont_mix| flag is set in the latter case.

Because the test is made by seeing if one specification matches another, we
also protect it from the special "nonexisting variable" tokens,
used only in inline phrase preambles. It would otherwise think "existing
variable" is more specific than "new variable", which isn't helpful.

@<See if the ith token rules out being a sub- or superschema@> =
	if ((phtd1->token_sequence[i].construct == NEW_LOCAL_PT_CONSTRUCT) &&
		(phtd2->token_sequence[i].construct != NEW_LOCAL_PT_CONSTRUCT)) {
		possibly_superschema = FALSE;
	} else if ((phtd1->token_sequence[i].construct != NEW_LOCAL_PT_CONSTRUCT) &&
		(phtd2->token_sequence[i].construct == NEW_LOCAL_PT_CONSTRUCT)) {
		possibly_subschema = FALSE;
	} else {
		int wont_mix = FALSE;
		int r = Specifications::compare_specificity(spec1, spec2, &wont_mix);
		if (wont_mix) { possibly_subschema = FALSE; possibly_superschema = FALSE; }
		else if (r < 0) possibly_subschema = FALSE;
		else if (r > 0) possibly_superschema = FALSE;
	}

@h Say phrases.

@d NOT_A_SAY_PHRASE 0 /* needs to be 0 so that |sd.say_phrase| can be a C condition */
@d A_MISCELLANEOUS_SAY_PHRASE 1
@d THE_PRIMORDIAL_SAY_PHRASE 2

=
say_details Phrases::TypeData::new_say_details(void) {
	say_details sd;
	sd.say_phrase = NOT_A_SAY_PHRASE;
	sd.say_phrase_running_on = FALSE;
	sd.say_control_structure = NO_SAY_CS;
	sd.say_phrase_stream_position = SSP_NONE;
	sd.say_phrase_stream_token_at = -1;
	sd.say_phrase_stream_closing_token_at = -1;
	return sd;
}

int first_say_made = FALSE;

void Phrases::TypeData::make_sd(say_details *sd, int ro, int cs, int pos, int at, int cat) {
	sd->say_phrase = A_MISCELLANEOUS_SAY_PHRASE;
	if (first_say_made == FALSE) {
		sd->say_phrase = THE_PRIMORDIAL_SAY_PHRASE;
		first_say_made = TRUE;
	}
	sd->say_phrase_running_on = ro;
	if (cs >= 0) sd->say_control_structure = cs;
	if (pos >= 0) sd->say_phrase_stream_position = pos;
	if (at >= 0) sd->say_phrase_stream_token_at = at;
	if (cat >= 0) sd->say_phrase_stream_closing_token_at = cat;
}

void Phrases::TypeData::log_say_details(say_details sd) {
	switch (sd.say_phrase) {
		case NOT_A_SAY_PHRASE: break;
		case A_MISCELLANEOUS_SAY_PHRASE: LOG("  A_MISCELLANEOUS_SAY_PHRASE\n"); break;
		case THE_PRIMORDIAL_SAY_PHRASE: LOG("  THE_PRIMORDIAL_SAY_PHRASE\n"); break;
		default: LOG("  <invalid say phrase status>\n"); break;
	}
	if (sd.say_phrase_running_on)
		LOG("  running on from previous say invocation without implied newline\n");
	switch (sd.say_control_structure) {
		case NO_SAY_CS: break;
		case IF_SAY_CS: LOG("  IF_SAY_CS\n"); break;
		case END_IF_SAY_CS: LOG("  END_IF_SAY_CS\n"); break;
		case OTHERWISE_SAY_CS: LOG("  OTHERWISE_SAY_CS\n"); break;
		case OTHERWISE_IF_SAY_CS: LOG("  OTHERWISE_IF_SAY_CS\n"); break;
		default: LOG("  <invalid say phrase status>\n"); break;
	}
}

int Phrases::TypeData::is_a_say_phrase(phrase *ph) {
	if ((ph) && (ph->type_data.as_say.say_phrase)) return TRUE;
	return FALSE;
}

int Phrases::TypeData::is_a_say_X_phrase(ph_type_data *phtd) {
	if (phtd->as_say.say_phrase == NOT_A_SAY_PHRASE) return FALSE;
	if ((phtd->no_words == 2) && (phtd->word_sequence[1] < MAX_TOKENS_PER_PHRASE))
		return TRUE;
	return FALSE;
}

int Phrases::TypeData::is_a_spare_say_X_phrase(ph_type_data *phtd) {
	if (phtd->as_say.say_phrase == NOT_A_SAY_PHRASE) return FALSE;
	if ((phtd->no_words == 2) && (phtd->word_sequence[1] < MAX_TOKENS_PER_PHRASE)) {
		kind *K = phtd->token_sequence[0].token_kind;
		if ((K) && (Kinds::Behaviour::definite(K) == FALSE)) return FALSE;
		return TRUE;
	}
	return FALSE;
}

int Phrases::TypeData::is_the_primordial_say(ph_type_data *phtd) {
	if (phtd->as_say.say_phrase == THE_PRIMORDIAL_SAY_PHRASE) return TRUE;
	return FALSE;
}

void Phrases::TypeData::get_say_data(say_details *sd,
	int *say_cs, int *ssp_tok, int *ssp_ctok, int *ssp_pos) {
	*say_cs = sd->say_control_structure;
	*ssp_tok = sd->say_phrase_stream_token_at;
	*ssp_ctok = sd->say_phrase_stream_closing_token_at;
	*ssp_pos = sd->say_phrase_stream_position;
}

int Phrases::TypeData::preface_for_say_HTML(OUTPUT_STREAM, say_details sd, int paste_format) {
	if (sd.say_phrase) {
		if (sd.say_phrase != THE_PRIMORDIAL_SAY_PHRASE) {
			switch (paste_format) {
				case PASTE_PHRASE_FORMAT: WRITE("["); break;
				case INDEX_PHRASE_FORMAT: WRITE("say \"["); break;
			}
		} else {
			switch (paste_format) {
				case PASTE_PHRASE_FORMAT: WRITE("say \"\""); return NOT_APPLICABLE;
				case INDEX_PHRASE_FORMAT: WRITE("say \""); break;
			}
		}
		return TRUE;
	}
	return FALSE;
}

void Phrases::TypeData::epilogue_for_say_HTML(OUTPUT_STREAM, say_details sd, int paste_format) {
	if (sd.say_phrase) {
		if (sd.say_phrase != THE_PRIMORDIAL_SAY_PHRASE) {
			if (paste_format == PASTE_PHRASE_FORMAT) WRITE("]");
			else if (paste_format == INDEX_PHRASE_FORMAT) WRITE("]\"");
		} else {
			if (paste_format == INDEX_PHRASE_FORMAT) WRITE("\"");
		}
	}
}

int Phrases::TypeData::ssp_matches(ph_type_data *phtd, int ssp_tok, int list_pos,
	wording *W) {
	int this_tok = phtd->as_say.say_phrase_stream_token_at;
	int this_pos = phtd->as_say.say_phrase_stream_position;
	if (this_tok == -1) return FALSE;
	if (this_pos != list_pos) return FALSE;
	if (compare_words(ssp_tok, this_tok) == FALSE) return FALSE;
	*W = Wordings::trim_first_word(phtd->registration_text); /* to remove the word "say" */
	return TRUE;
}

@h Inline phrases.
On some platforms, notably Android, |inline| is a reserved word in some versions
of |gcc|, so we need to be careful not to call any variables or structure members
by than name.

@d NO_BLOCK_FOLLOWS 0 				/* this needs to be 0, to make if conditions work */
@d MISCELLANEOUS_BLOCK_FOLLOWS 1
@d CONDITIONAL_BLOCK_FOLLOWS 2
@d LOOP_BODY_BLOCK_FOLLOWS 3

=
inline_details Phrases::TypeData::new_inline_details(void) {
	inline_details id;

	id.invoked_inline_not_as_call = FALSE;

	id.let_phrase = NOT_A_LET_PHRASE;
	id.block_follows = NO_BLOCK_FOLLOWS;
	id.only_in_loop = NULL;
	id.assignment_phrase = FALSE;
	id.arithmetical_operation = -1;

	return id;
}

@ =
int no_lets_made = 0;

void Phrases::TypeData::make_id(inline_details *id, int op, int assgn, int let, int blk, int only_in) {
	id->arithmetical_operation = op;
	id->assignment_phrase = assgn;
	if ((let == ASSIGNMENT_LET_PHRASE) && (no_lets_made++ >= 3)) let = NOT_A_LET_PHRASE;
	id->let_phrase = let;
	id->block_follows = blk;
	if (only_in == -1) id->only_in_loop = L"loop";
	else if (only_in > 0) id->only_in_loop = Lexer::word_text(only_in);
}

@ =
void Phrases::TypeData::log_inline_details(inline_details id) {
	if (id.block_follows) LOG("  block follows\n");
	if (id.let_phrase != NOT_A_LET_PHRASE) LOG("  let phrase (%d)\n", id.let_phrase);
	if (id.only_in_loop) LOG("  may only be used in a %w body\n", id.only_in_loop);
	switch (id.invoked_inline_not_as_call) {
		case TRUE: LOG("  invoked inline\n"); break;
		case FALSE: LOG("  invoked by I6 function call\n"); break;
	}
}

@ =
void Phrases::TypeData::make_inline(ph_type_data *phtd) {
	phtd->as_inline.invoked_inline_not_as_call = TRUE;
}

int Phrases::TypeData::invoked_inline(phrase *ph) {
	return ph->type_data.as_inline.invoked_inline_not_as_call;
}

@ =
int Phrases::TypeData::is_a_let_assignment(phrase *ph) {
	if (ph->type_data.as_inline.let_phrase == ASSIGNMENT_LET_PHRASE) return TRUE;
	return FALSE;
}

int Phrases::TypeData::is_a_let_equation(phrase *ph) {
	if (ph->type_data.as_inline.let_phrase == EQUATION_LET_PHRASE) return TRUE;
	return FALSE;
}

int Phrases::TypeData::arithmetic_operation(phrase *ph) {
	return ph->type_data.as_inline.arithmetical_operation;
}

int Phrases::TypeData::is_arithmetic_phrase(phrase *ph) {
	if ((Phrases::TypeData::arithmetic_operation(ph) >= 0) &&
		(Phrases::TypeData::arithmetic_operation(ph) < NO_OPERATIONS)) return TRUE;
	return FALSE;
}

int Phrases::TypeData::is_assignment_phrase(phrase *ph) {
	return ph->type_data.as_inline.assignment_phrase;
}

wchar_t *Phrases::TypeData::only_in(phrase *ph) {
	if (ph) return ph->type_data.as_inline.only_in_loop;
	return NULL;
}

int Phrases::TypeData::block_follows(phrase *ph) {
	return ph->type_data.as_inline.block_follows;
}

@h Return value polymorphism.
Inform has two sorts of polymorphism -- that is, there are two ways in which
the kinds of phrases can vary. One is by means of kind variables, the other
is for arithmetic operations such as "plus" or "times": where the range of
kinds which can go in is quite large, and the kind which comes out is then
determined on dimensional grounds. (A number times a length is another
length, but a number plus a length is an error, and so on.)

=
int Phrases::TypeData::return_decided_dimensionally(ph_type_data *phtd) {
	if ((phtd->manner_of_return == DECIDES_VALUE_MOR) &&
		(phtd->as_inline.arithmetical_operation >= 0)) return TRUE;
	return FALSE;
}

@h Tweaking phrase ordering.
Phrases marked for use only within a particular control structure, such as
"otherwise" within "if", automatically precede all other phrases. The idea
is that these are keywords whose effect is so powerful that we don't want
any chance of ambiguities arising due to unwise phrase definitions in the
source text.

=
int Phrases::TypeData::inline_type_data_comparison(ph_type_data *phtd1, ph_type_data *phtd2) {
	if ((phtd1->as_inline.only_in_loop) && (phtd2->as_inline.only_in_loop == FALSE))
		return BEFORE_PH;
	if ((phtd2->as_inline.only_in_loop) && (phtd1->as_inline.only_in_loop == FALSE))
		return AFTER_PH;

	return EQUAL_PH;
}
