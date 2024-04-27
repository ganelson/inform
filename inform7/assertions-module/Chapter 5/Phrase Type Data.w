[IDTypeData::] Phrase Type Data.

To create, manage, compare the logical specificity of, and assist
excerpt parsing concerning, the type of a To phrase.

@h Introduction.
Each imperative definition, regardless of family, has type data attached.
Only "To..." phrase definitions make full use of this, which is why we use
those as examples throughout, but even rule and adjective definitions set
the "manner of return" (see below).

Type data for a "To..." phrase comes from its prototype text. For example:
= (text as Inform 7)
To sort (T - table name) in (TC - table column) order: ...

Word sequence:             Token sequence:
0  sort                    0  T - table name
1  0                       1  TC - table column
2  in
3  1
4  order
=
The "word sequence" consists of five integers. Values below |MAX_TOKENS_PER_PHRASE|
mean that a token appears in that position; higher values are word numbers in
the lexed source. (So a phrase prototype cannot appear in the first 10 words of
the source text. Those words are always used on inclusion sentences anyway.)
The "token sequence" lists the flexibly-worded "tokens" in the prototype -- the
parts in brackets.

@d MAX_TOKENS_PER_PHRASE 10
@d MAX_WORDS_PER_PHRASE 32 /* the most the excerpt parser can hold anyway */

=
typedef struct id_type_data {
	struct wording registration_text; /* words used to register the excerpt meaning */
	int word_sequence[MAX_WORDS_PER_PHRASE]; /* the "word sequence": see above */
	int no_words; /* length of the word sequence */

	struct id_type_token token_sequence[MAX_TOKENS_PER_PHRASE];
	int no_tokens;

	int manner_of_return; /* one of the |*_MOR| values */
	struct kind *return_kind; /* |NULL| except in the |DECIDES_VALUE_MOR| case */

	struct id_options_data options_data;

	struct say_details as_say; /* used only for "say" phrases, that is, text substitutions */
	struct inline_details as_inline; /* side effects for phrases like C keywords */

	int now_deprecated; /* is this a phrase likely to be withdrawn in future? */
} id_type_data;

@ =
id_type_data IDTypeData::new(void) {
	id_type_data idtd;
	idtd.registration_text = EMPTY_WORDING;
	idtd.manner_of_return = DECIDES_NOTHING_MOR;
	idtd.return_kind = NULL;
	idtd.no_words = 0;
	idtd.no_tokens = 0;
	idtd.as_say = IDTypeData::new_say_details();
	idtd.as_inline = IDTypeData::new_inline_details();
	idtd.now_deprecated = FALSE;
	idtd.options_data = PhraseOptions::new(EMPTY_WORDING);
	return idtd;
}

@ The two tokens of our example phrase, then, are each stored in one of the
following. Note that a token can match a value[1] as well as a kind, or can match
an elaborate description. Because it can also stand for special constructs
not representable with a |parse_node|, such as "name of a kind of enumerated
value", the |construct| field is occasionally not |STANDARD_IDTC|.

[1] The early design of Inform did not permit values as token specifications,
but this lack was in fact reported as a bug -- always a sign that users considered
it a natural thing to do.

@d ERRONEOUS_IDTC       0 /* used only in parsing, never in an IDTT */
@d STANDARD_IDTC        1 /* e.g., |12|, |number|, |open door| */
@d NEW_LOCAL_IDTC       2 /* e.g., |nonexisting number variable| */
@d OLD_LOCAL_IDTC       3 /* e.g., |existing number variable| */
@d CONDITION_IDTC       4 /* e.g., |a condition| */
@d STORAGE_IDTC         5 /* e.g., |storage| */
@d TABLE_REF_IDTC       6 /* e.g., |table-reference| */
@d KIND_NAME_IDTC       7 /* e.g., |name of kind| */
@d VOID_IDTC            8 /* e.g., or in fact only, |phrase| */

=
typedef struct id_type_token {
	int construct; /* one of the |*_IDTC| values above */
	struct wording token_name; /* name */
	struct parse_node *to_match; /* what we expect to find here */
	struct kind *token_kind;
} id_type_token;

void IDTypeData::set_spec(id_type_token *idtt, parse_node *spec) {
	idtt->to_match = spec;
	idtt->token_kind = Specifications::to_kind(spec);
}

kind *IDTypeData::token_kind(id_type_data *idtd, int i) {
	return idtd->token_sequence[i].token_kind;
}

@ It may seem redundant to store both |to_match| and |token_kind|. Surely
the latter is always just the reduction to a kind of the former? But in fact
not, because of the following function: if it performs a kind substitution
of a kind into a kind variable, the two will no longer match exactly. See
//ParsingIDTypeData::parse// for the subtle reason it is needed.

=
void IDTypeData::substitute_spec(id_type_data *idtd, int i, kind **declarations) {
	int changed = FALSE;
	kind *substituted = Kinds::substitute(
		idtd->token_sequence[i].token_kind, declarations, &changed, TRUE);
	if (changed)
		idtd->token_sequence[i].to_match = Specifications::from_kind(substituted);
}

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
would be control-structure keywords; so inline phrases sometimes need bells,
whistles and doodads which regular phrases don't.

=
typedef struct inline_details {
	int invoked_inline_not_as_call; /* if |FALSE|, none of the rest applies */

	int let_phrase; /* one of the |*_LET_PHRASE| values below */
	int assignment_phrase; /* |TRUE| if this has to be typechecked as an assignment */
	int offset_assignment_phrase; /* |TRUE| if similarly, but as an increase/decrease */
	int arithmetical_operation; /* |-1|, or one of the |*_OPERATION| constants */

	int block_follows; /* for inline phrases only: followed by a begin... end block? */
	inchar32_t *only_in_loop; /* if not null, the phrase can only be used in this block */
} inline_details;

@ Where:

@d NOT_A_LET_PHRASE 0 /* needs to be 0 so that |let_phrase| can be a C condition */
@d ASSIGNMENT_LET_PHRASE 1 /* the regular "let" */
@d EQUATION_LET_PHRASE 2 /* "let" inviting Inform to solve an equation */

@h Manner of return.
The "manner of return" (MOR) is similar to the type of value returned by a
function in a C-like language. Thus |DECIDES_NOTHING_MOR| is like being a void
function in C, and |DECIDES_VALUE_MOR| like being a non-void one; |DECIDES_CONDITION_MOR|
is like being a function returning a truth state. The joker in the pack is
|DECIDES_NOTHING_AND_RETURNS_MOR|, which has no analogue in C. It means that
invoking the phrase we are defining will cause an exit from the phrase which
invokes it. If C implemented |return| as a function rather than an inbuilt
keyword, this would be its type.

|DECIDES_NOTHING_AND_RETURNS_MOR| is possible (and meaningful) only for inline
definitions.

@d DONT_KNOW_MOR 1						/* but ask me later */
@d DECIDES_NOTHING_MOR 2				/* e.g., "award 4 points" */
@d DECIDES_VALUE_MOR 3					/* e.g., "square root of 16" */
@d DECIDES_CONDITION_MOR 4				/* e.g., "a random chance of 1 in 3 succeeds" */
@d DECIDES_NOTHING_AND_RETURNS_MOR 5	/* e.g., "continue the action" */

=
void IDTypeData::set_mor(id_type_data *idtd, int mor, kind *K) {
	idtd->manner_of_return = mor;
	idtd->return_kind = K;
}

int IDTypeData::get_mor(id_type_data *idtd) {
	return idtd->manner_of_return;
}

kind *IDTypeData::get_return_kind(id_type_data *idtd) {
	switch (idtd->manner_of_return) {
		case DECIDES_CONDITION_MOR: return K_truth_state;
		case DECIDES_VALUE_MOR: return idtd->return_kind;
	}
	return NULL;
}

@ =
char *IDTypeData::describe_manner_of_return(int mor, id_type_data *idtd, kind **K) {
	switch (mor) {
		case DECIDES_NOTHING_MOR: return "no value resulting";
		case DECIDES_VALUE_MOR:
			if ((idtd) && (idtd->return_kind) && (K)) *K = idtd->return_kind;
			return "a phrase to decide a value";
		case DECIDES_CONDITION_MOR: return "a phrase to make a decision";
		case DECIDES_NOTHING_AND_RETURNS_MOR:
			return "a phrase providing an outcome to a rulebook";
	}
	return "some phrase"; /* should never actually be needed */
}

@h The kind of a definition.
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

What's the kind of this? The eventual result of compiling this will be a
function of kind |phrase (V, V) -> nothing|, where V is the particular kind
it is used for. But this is not the kind of the definition itself, which
clearly has three parameters. If we give it the kind |phrase (K, K) -> nothing|
then Inform will infer the kind K from the parameters supplied as |alpha|
and |beta| in any given invocation. For example, "juxtapose numbers with 12
and 31" would then correctly infer that |K = number|. But in some subtle cases
of ambiguity it infers the wrong answer, and anyway, the idea is to take K
from the kind explicitly named in the |name of kind of value K| parameter.
So, internally, Inform regards the kind of this definition as
|phrase (K, K, K) -> nothing|.

=
kind *IDTypeData::kind(id_type_data *idtd) {
	kind *argument_kinds[MAX_TOKENS_PER_PHRASE];
	for (int i=0; i<idtd->no_tokens; i++)
		argument_kinds[i] = IDTypeData::token_kind(idtd, i);
	kind *R = IDTypeData::get_return_kind(idtd);
	return Kinds::function_kind(idtd->no_tokens, argument_kinds, R);
}

@ It's useful to test whether the definition in fact involves kind variables:

=
int IDTypeData::contains_variables(id_type_data *idtd) {
	return Kinds::contains(IDTypeData::kind(idtd), CON_KIND_VARIABLE);
}

int IDTypeData::token_contains_variable(id_type_data *idtd, int v) {
	for (int i=0; i<idtd->no_tokens; i++)
		if (Kinds::Behaviour::involves_var(IDTypeData::token_kind(idtd, i), v))
			return TRUE;
	return FALSE;
}

@h The tokens.

=
int IDTypeData::get_no_tokens(id_type_data *idtd) {
	return idtd->no_tokens;
}

int IDTypeData::index_of_token_creating_a_variable(id_type_data *idtd) {
	for (int i=0; i<idtd->no_tokens; i++)
		if (idtd->token_sequence[i].construct == NEW_LOCAL_IDTC)
			return i;
	return -1;
}

@ This odd-looking question is asked when handling the ambiguity between the
name of a property ("carrying capacity", say) as a value in its own right,
and the same name metonymically referring to the value of the property for
a given instance ("carrying capacity of the player", say).

=
int IDTypeData::preamble_requires_property_value(id_type_data *idtd) {
	for (int i=0; i<idtd->no_tokens; i++)
		if (Lvalues::get_storage_form(idtd->token_sequence[i].to_match) == PROPERTY_VALUE_NT)
			return FALSE;
	return TRUE;
}

@h Deprecation.
Phrases which are "deprecated" are those defined by the Standard Rules, or
other extensions in the standard Inform installation, which we now think are
redundant or a bad idea: we don't want to withdraw them without warning, so
the procedure is to deprecate them in one major build and withdraw them
in the next.

=
int IDTypeData::deprecated(id_type_data *idtd) {
	return idtd->now_deprecated;
}

void IDTypeData::deprecate_phrase(id_type_data *idtd) {
	idtd->now_deprecated = TRUE;
}

@h Comparison of PHTDs.
This is used when sorting "To..." phrases in order of logical priority.

=
int IDTypeData::comparison(id_type_data *phtd1, id_type_data *phtd2) {
	if (phtd1 == phtd2) return EQUAL_PH;

	@<Loop construct keywords have priority@>;
	@<More fixed words beats fewer@>;
	@<More tokens beats fewer@>;
	@<Next use alphabetical order, counting tokens as after the Zs@>;
	@<Finally try comparing the to-match specifications of the tokens@>;

	return INCOMPARABLE_PH;
}

@<Loop construct keywords have priority@> =
	int i = IDTypeData::inline_type_data_comparison(phtd1, phtd2);
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

We use alphabetical order, placing "grab ZZZZZZ swiftly" after "grab at ZZZZZZ".

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
		((Kinds::eq(phtd1->return_kind, phtd2->return_kind) == FALSE) &&
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
	if ((phtd1->token_sequence[i].construct == NEW_LOCAL_IDTC) &&
		(phtd2->token_sequence[i].construct != NEW_LOCAL_IDTC)) {
		possibly_superschema = FALSE;
	} else if ((phtd1->token_sequence[i].construct != NEW_LOCAL_IDTC) &&
		(phtd2->token_sequence[i].construct == NEW_LOCAL_IDTC)) {
		possibly_subschema = FALSE;
	} else {
		int wont_mix = FALSE;
		int r = Specifications::compare_specificity(spec1, spec2, &wont_mix);
		if (wont_mix) { possibly_subschema = FALSE; possibly_superschema = FALSE; }
		else if (r < 0) possibly_subschema = FALSE;
		else if (r > 0) possibly_superschema = FALSE;
	}

@h Tweaking phrase ordering.
Phrases marked for use only within a particular control structure, such as
"otherwise" within "if", automatically precede all other phrases. The idea
is that these are keywords whose effect is so powerful that we don't want
any chance of ambiguities arising due to unwise phrase definitions in the
source text.

=
int IDTypeData::inline_type_data_comparison(id_type_data *phtd1, id_type_data *phtd2) {
	if ((phtd1->as_inline.only_in_loop) && (phtd2->as_inline.only_in_loop == FALSE))
		return BEFORE_PH;
	if ((phtd2->as_inline.only_in_loop) && (phtd1->as_inline.only_in_loop == FALSE))
		return AFTER_PH;

	return EQUAL_PH;
}

@h Say phrases.

@d NOT_A_SAY_PHRASE 0 /* needs to be 0 so that |sd.say_phrase| can be a C condition */
@d A_MISCELLANEOUS_SAY_PHRASE 1
@d THE_PRIMORDIAL_SAY_PHRASE 2

=
say_details IDTypeData::new_say_details(void) {
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

void IDTypeData::make_sd(say_details *sd, int ro, int cs, int pos, int at, int cat) {
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

void IDTypeData::log_say_details(say_details sd) {
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

int IDTypeData::is_a_say_phrase(id_body *idb) {
	if ((idb) && (idb->type_data.as_say.say_phrase)) return TRUE;
	return FALSE;
}

int IDTypeData::is_a_say_X_phrase(id_type_data *idtd) {
	if (idtd->as_say.say_phrase == NOT_A_SAY_PHRASE) return FALSE;
	if ((idtd->no_words == 2) && (idtd->word_sequence[1] < MAX_TOKENS_PER_PHRASE))
		return TRUE;
	return FALSE;
}

int IDTypeData::is_a_spare_say_X_phrase(id_type_data *idtd) {
	if (idtd->as_say.say_phrase == NOT_A_SAY_PHRASE) return FALSE;
	if ((idtd->no_words == 2) && (idtd->word_sequence[1] < MAX_TOKENS_PER_PHRASE)) {
		kind *K = IDTypeData::token_kind(idtd, 0);
		if ((K) && (Kinds::Behaviour::definite(K) == FALSE)) return FALSE;
		return TRUE;
	}
	return FALSE;
}

int IDTypeData::is_the_primordial_say(id_type_data *idtd) {
	if (idtd->as_say.say_phrase == THE_PRIMORDIAL_SAY_PHRASE) return TRUE;
	return FALSE;
}

void IDTypeData::get_say_data(say_details *sd,
	int *say_cs, int *ssp_tok, int *ssp_ctok, int *ssp_pos) {
	*say_cs = sd->say_control_structure;
	*ssp_tok = sd->say_phrase_stream_token_at;
	*ssp_ctok = sd->say_phrase_stream_closing_token_at;
	*ssp_pos = sd->say_phrase_stream_position;
}

int IDTypeData::preface_for_say_HTML(OUTPUT_STREAM, say_details sd, int paste_format) {
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

void IDTypeData::epilogue_for_say_HTML(OUTPUT_STREAM, say_details sd, int paste_format) {
	if (sd.say_phrase) {
		if (sd.say_phrase != THE_PRIMORDIAL_SAY_PHRASE) {
			if (paste_format == PASTE_PHRASE_FORMAT) WRITE("]");
			else if (paste_format == INDEX_PHRASE_FORMAT) WRITE("]\"");
		} else {
			if (paste_format == INDEX_PHRASE_FORMAT) WRITE("\"");
		}
	}
}

int IDTypeData::ssp_matches(id_type_data *idtd, int ssp_tok, int list_pos,
	wording *W) {
	int this_tok = idtd->as_say.say_phrase_stream_token_at;
	int this_pos = idtd->as_say.say_phrase_stream_position;
	if (this_tok == -1) return FALSE;
	if (this_pos != list_pos) return FALSE;
	if (compare_words(ssp_tok, this_tok) == FALSE) return FALSE;
	*W = Wordings::trim_first_word(idtd->registration_text); /* to remove the word "say" */
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
inline_details IDTypeData::new_inline_details(void) {
	inline_details id;
	id.invoked_inline_not_as_call = FALSE;
	id.let_phrase = NOT_A_LET_PHRASE;
	id.block_follows = NO_BLOCK_FOLLOWS;
	id.only_in_loop = NULL;
	id.assignment_phrase = FALSE;
	id.offset_assignment_phrase = FALSE;
	id.arithmetical_operation = -1;
	return id;
}

@ =
int no_lets_made = 0;

void IDTypeData::make_id(inline_details *id, int op, int assgn, int offset,
	int let, int blk, int only_in) {
	id->arithmetical_operation = op;
	id->assignment_phrase = assgn;
	id->offset_assignment_phrase = offset;
	if ((let == ASSIGNMENT_LET_PHRASE) && (no_lets_made++ >= 3)) let = NOT_A_LET_PHRASE;
	id->let_phrase = let;
	id->block_follows = blk;
	if (only_in == -1) id->only_in_loop = U"loop";
	else if (only_in > 0) id->only_in_loop = Lexer::word_text(only_in);
}

@ =
void IDTypeData::log_inline_details(inline_details id) {
	if (id.block_follows) LOG("  block follows\n");
	if (id.let_phrase != NOT_A_LET_PHRASE) LOG("  let phrase (%d)\n", id.let_phrase);
	if (id.only_in_loop) LOG("  may only be used in a %w body\n", id.only_in_loop);
	switch (id.invoked_inline_not_as_call) {
		case TRUE: LOG("  invoked inline\n"); break;
		case FALSE: LOG("  invoked by I6 function call\n"); break;
	}
}

@ =
void IDTypeData::make_inline(id_type_data *idtd) {
	if (idtd == NULL) internal_error("null idtd");
	idtd->as_inline.invoked_inline_not_as_call = TRUE;
}

int IDTypeData::invoked_inline(id_body *idb) {
	if (idb == NULL) return FALSE;
	return idb->type_data.as_inline.invoked_inline_not_as_call;
}

@ =
int IDTypeData::is_a_let_assignment(id_body *idb) {
	if (idb == NULL) return FALSE;
	if (idb->type_data.as_inline.let_phrase == ASSIGNMENT_LET_PHRASE) return TRUE;
	return FALSE;
}

int IDTypeData::is_a_let_equation(id_body *idb) {
	if (idb == NULL) return FALSE;
	if (idb->type_data.as_inline.let_phrase == EQUATION_LET_PHRASE) return TRUE;
	return FALSE;
}

int IDTypeData::arithmetic_operation(id_body *idb) {
	if (idb == NULL) return -1;
	return idb->type_data.as_inline.arithmetical_operation;
}

int IDTypeData::is_arithmetic_phrase(id_body *idb) {
	if (IDTypeData::arithmetic_operation(idb) == PLUS_OPERATION) return TRUE;
	if (IDTypeData::arithmetic_operation(idb) == MINUS_OPERATION) return TRUE;
	if (IDTypeData::arithmetic_operation(idb) == TIMES_OPERATION) return TRUE;
	if (IDTypeData::arithmetic_operation(idb) == DIVIDE_OPERATION) return TRUE;
	if (IDTypeData::arithmetic_operation(idb) == REMAINDER_OPERATION) return TRUE;
	if (IDTypeData::arithmetic_operation(idb) == APPROXIMATE_OPERATION) return TRUE;
	if (IDTypeData::arithmetic_operation(idb) == ROOT_OPERATION) return TRUE;
	if (IDTypeData::arithmetic_operation(idb) == REALROOT_OPERATION) return TRUE;
	if (IDTypeData::arithmetic_operation(idb) == CUBEROOT_OPERATION) return TRUE;
	return FALSE;
}

int IDTypeData::is_assignment_phrase(id_body *idb) {
	if (idb == NULL) return FALSE;
	return idb->type_data.as_inline.assignment_phrase;
}

int IDTypeData::is_offset_assignment_phrase(id_body *idb) {
	if (idb == NULL) return FALSE;
	return idb->type_data.as_inline.offset_assignment_phrase;
}

inchar32_t *IDTypeData::only_in(id_body *idb) {
	if (idb) return idb->type_data.as_inline.only_in_loop;
	return NULL;
}

int IDTypeData::block_follows(id_body *idb) {
	if (idb == NULL) return FALSE;
	return idb->type_data.as_inline.block_follows;
}

@h Return value polymorphism.
Inform has two sorts of polymorphism -- that is, there are two ways in which
the kinds of phrases can vary. One is by means of kind variables, the other
is for arithmetic operations such as "plus" or "times": where the range of
kinds which can go in is quite large, and the kind which comes out is then
determined on dimensional grounds. (A number times a length is another
length, but a number plus a length is an error, and so on.)

=
int IDTypeData::return_decided_dimensionally(id_type_data *idtd) {
	if ((idtd->manner_of_return == DECIDES_VALUE_MOR) &&
		(idtd->as_inline.arithmetical_operation >= 0)) return TRUE;
	return FALSE;
}

@h Logging.
The debugging log is simple:

=
void IDTypeData::log(id_type_data *idtd) {
	LOG("  IDTD: register as <%W>\n  %s\n", idtd->registration_text,
		IDTypeData::describe_manner_of_return(idtd->manner_of_return, idtd, NULL));
	if (idtd->manner_of_return == DECIDES_VALUE_MOR)
		LOG("  decides value of kind %u\n", idtd->return_kind);
	@<Log the word sequence@>;
	@<Log the token sequence@>;
	IDTypeData::log_inline_details(idtd->as_inline);
	IDTypeData::log_say_details(idtd->as_say);
}

@<Log the word sequence@> =
	LOG("  ");
	for (int i=0; i<idtd->no_words; i++)
		if (idtd->word_sequence[i] < MAX_TOKENS_PER_PHRASE)
			LOG("#%d ", idtd->word_sequence[i]);
		else
			LOG("%N ", idtd->word_sequence[i]);
	LOG("(%d words)\n", idtd->no_words);

@<Log the token sequence@> =
	for (int i=0; i<idtd->no_tokens; i++)
		LOG("  #%d: \"%W\" = $P\n", i,
			idtd->token_sequence[i].token_name, idtd->token_sequence[i].to_match);

@ Abbreviatedly:

=
void IDTypeData::log_briefly(id_type_data *idtd) {
	if (idtd == NULL) { LOG("<null-IDTD>"); return; }
	LOG("\"%W\"", idtd->registration_text);
	switch(idtd->manner_of_return) {
		case DECIDES_CONDITION_MOR: LOG("(=condition)"); break;
		case DECIDES_VALUE_MOR: LOG("(=%u)", idtd->return_kind); break;
	}
}

@h HTML forms.
But the debugging log isn't the only place we want to write out the phrase
type to: it also gets written to HTML, not just openly but also in the
Javascript pasted form. One reason for this is to write entries in the
Phrasebook Index, but another is to show what Inform was trying to do when
issuing a Problem message: usually it has managed partially to match up the
tokens in a phrase, and has a mostly-formed but incorrect invocation as
a result. If such an invocation |inv| is supplied here, than the attempted
match is shown.

@d PASTE_PHRASE_FORMAT 1 /* in the insert-to-source text pasted by a button in the Index */
@d INDEX_PHRASE_FORMAT 2 /* a simpler version good enough for most purposes */

=
void IDTypeData::write_HTML_representation(OUTPUT_STREAM,
	id_type_data *idtd, int paste_format, parse_node *inv) {

	int seq_from = 0, seq_to = idtd->no_words;

	int writing_a_say = IDTypeData::preface_for_say_HTML(OUT, idtd->as_say, paste_format);
	if (writing_a_say == NOT_APPLICABLE) return;
	if (writing_a_say) seq_from = 1; /* skip the first word, which is necessarily "say" in this case */

	if (idtd->as_inline.block_follows) seq_to--; /* skip the last word, which is a block marker */

	if ((paste_format == PASTE_PHRASE_FORMAT) && (writing_a_say == FALSE)) {
		if (idtd->word_sequence[0] < MAX_TOKENS_PER_PHRASE) seq_from++;
		if ((idtd->word_sequence[seq_to-1] < MAX_TOKENS_PER_PHRASE) &&
			(idtd->as_inline.block_follows == NO_BLOCK_FOLLOWS)) seq_to--;
	}
	@<Describe the word sequence@>;
	if (idtd->as_inline.block_follows) {
		if (paste_format) WRITE(":\n");
		else {
			WRITE(":");
			HTML_TAG("br");
			WRITE("&nbsp;&nbsp;&nbsp;");
			HTML_OPEN("i");
			HTML::begin_span(OUT, I"phrasetokenvaluetext");
			WRITE("phrases");
			HTML::end_span(OUT);
			HTML_CLOSE("i");
		}
	}

	IDTypeData::epilogue_for_say_HTML(OUT, idtd->as_say, paste_format);
}

@<Describe the word sequence@> =
	for (int j=seq_from; j<seq_to; j++) {
		if (j > seq_from) WRITE(" ");
		int ix = idtd->word_sequence[j];
		if (ix < MAX_TOKENS_PER_PHRASE)
			@<Describe a token in the word sequence@>
		else
			@<Describe a fixed word in the word sequence@>;
	}

@<Describe a fixed word in the word sequence@> =
	inchar32_t *p = Lexer::word_raw_text(idtd->word_sequence[j]);
	int tinted = FALSE;
	for (int i=0; p[i]; i++) {
		if ((p[i] == '/') && (tinted == FALSE)) {
			tinted = TRUE;
			if (paste_format == PASTE_PHRASE_FORMAT) break;
			HTML::begin_span(OUT, I"phraseword");
		}
		WRITE("%c", p[i]);
	}
	if ((paste_format != PASTE_PHRASE_FORMAT) && (tinted)) HTML::end_span(OUT);

@<Describe a token in the word sequence@> =
	switch (paste_format) {
		case INDEX_PHRASE_FORMAT:
			if (writing_a_say == FALSE) WRITE("(");
			if (inv) {
				parse_node *found = Invocations::get_token_as_parsed(inv, ix);
				if (Node::is(found, UNKNOWN_NT)) {
					HTML::begin_span(OUT, I"indexdullred");
				} else {
					HTML::begin_span(OUT, I"indexdullgreen");
				}
				WRITE("%W", Node::get_text(found));
				HTML::end_span(OUT);
				WRITE(" - ");
				Dash::note_inv_token_text(found,
					(idtd->token_sequence[ix].construct == NEW_LOCAL_IDTC)?TRUE:FALSE);
			}
			@<Describe what the token matches@>;
			if (writing_a_say == FALSE) WRITE(")");
			break;
		case PASTE_PHRASE_FORMAT:
			WRITE("...");
			break;
	}

@<Describe what the token matches@> =
	switch (idtd->token_sequence[ix].construct) {
		case STANDARD_IDTC: {
			parse_node *spec = idtd->token_sequence[ix].to_match;
			if (Specifications::is_kind_like(spec)) {
				HTML::begin_span(OUT, I"phrasetokendesctext");
				Kinds::Textual::write(OUT, Specifications::to_kind(spec));
				HTML::end_span(OUT);
			} else if ((Node::is(spec, CONSTANT_NT)) ||
					(Specifications::is_description(spec))) {
				HTML::begin_span(OUT, I"phrasetokendesctext");
				WRITE("%W", Node::get_text(spec));
				HTML::end_span(OUT);
			} else {
				HTML_OPEN("i");
				HTML::begin_span(OUT, I"phrasetokenvaluetext");
				Specifications::write_out_in_English(OUT, spec);
				HTML::end_span(OUT);
				HTML_CLOSE("i");
			}
			break;
		}
		case NEW_LOCAL_IDTC:
			HTML::begin_span(OUT, I"phrasetokentext");
			WRITE("a new name");
			HTML::end_span(OUT); break;
		case OLD_LOCAL_IDTC:
			HTML::begin_span(OUT, I"phrasetokentext");
			WRITE("a temporary named value");
			if ((IDTypeData::token_kind(idtd, ix)) &&
				(Kinds::eq(IDTypeData::token_kind(idtd, ix), K_value) == FALSE)) {
				WRITE(" holding ");
				Kinds::Textual::write_articled(OUT, IDTypeData::token_kind(idtd, ix));
			}
			HTML::end_span(OUT); break;
		case CONDITION_IDTC:
			HTML::begin_span(OUT, I"phrasetokentext");
			WRITE("a condition");
			HTML::end_span(OUT); break;
		case STORAGE_IDTC:
			HTML::begin_span(OUT, I"phrasetokentext");
			WRITE("a stored value");
			HTML::end_span(OUT); break;
		case TABLE_REF_IDTC:
			HTML::begin_span(OUT, I"phrasetokentext");
			WRITE("a table entry");
			HTML::end_span(OUT); break;
		case KIND_NAME_IDTC:
			HTML::begin_span(OUT, I"phrasetokentext");
			WRITE("name of kind");
			HTML::end_span(OUT); break;
		case VOID_IDTC:
			HTML::begin_span(OUT, I"phrasetokentext");
			WRITE("a phrase");
			HTML::end_span(OUT); break;
	}

@h Problem messages.
Which enables this rather cool depiction used in Problem messages:

=
void IDTypeData::inv_write_HTML_representation(OUTPUT_STREAM, parse_node *inv) {
	id_body *idb = Node::get_phrase_invoked(inv);
	if (idb) {
		id_type_data *idtd = &(idb->type_data);
		if (Wordings::nonempty(ToPhraseFamily::doc_ref(idb->head_of_defn))) {
			TEMPORARY_TEXT(pds)
			WRITE_TO(pds, "%+W",
				Wordings::one_word(Wordings::first_wn(ToPhraseFamily::doc_ref(idb->head_of_defn))));
			DocReferences::link_to(OUT, pds, -1);
			DISCARD_TEXT(pds)
		} else
			IndexUtilities::link_to(OUT,
				Wordings::first_wn(Node::get_text(ImperativeDefinitions::body_at(idb))), FALSE);
		WRITE(" ");
		IDTypeData::write_HTML_representation(OUT, idtd, INDEX_PHRASE_FORMAT, inv);
		WRITE(" ");
		switch (Dash::reading_passed(inv)) {
			case TRUE: HTML_TAG_WITH("img", "border=0 src=inform:/doc_images/tick.png"); break;
			case FALSE: HTML_TAG_WITH("img", "border=0 src=inform:/doc_images/cross.png"); break;
			default: HTML_TAG_WITH("img", "border=0 src=inform:/doc_images/greytick.png"); break;
		}
	}
}


