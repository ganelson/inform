[Phrases::Parser::] Parse Invocations.

To register phrases with the excerpt parser, and to provide the
excerpt parser with help in putting invocations together.

@h Parsing of phrases.
The control structures of Inform are defined in the Standard Rules. Before
the coming of Python-style indentation to Inform, blocks of code were closed
with "end..." phrases: "end if", "end repeat" and "end while". In fact these
are still valid, for the benefit of partially sighted users, and the
following construction makes the end phrase for a given control structure.

=
<end-phrase-construction> ::=
	end ...

@ This section aims to take text like

>> add 17 to the list of small primes;

which the excerpt parser can see is a possible usage of a phrase such as

>> To add (new entry - K) to (L - list of values of kind K), if absent: ...

and to help the excerpt parser by putting together an invocation.

To even make that possible, though, we must first register each "To..."
phrase definition with the excerpt parser:

=
void Phrases::Parser::register_excerpt(phrase *ph) {
	ph_type_data *phtd = &(ph->type_data);
	if (Wordings::empty(phtd->registration_text)) return;
	LOGIF(PHRASE_REGISTRATION, "Register phrase <%W> with type:\n$h", phtd->registration_text, phtd);
	wording W = phtd->registration_text;
	switch(phtd->manner_of_return) {
		case DECIDES_NOTHING_MOR:
			if (Phrases::TypeData::is_a_say_phrase(ph))
				Phrases::Parser::register_phrasal(SAY_PHRASE_MC, ph, Wordings::trim_first_word(W));
			else if (phtd->as_inline.block_follows != NO_BLOCK_FOLLOWS)
				Phrases::Parser::register_phrasal(VOID_PHRASE_MC, ph, Wordings::trim_last_word(W));
			else
				Phrases::Parser::register_phrasal(VOID_PHRASE_MC, ph, W);
			break;
		case DECIDES_CONDITION_MOR: Phrases::Parser::register_phrasal(COND_PHRASE_MC, ph, W); break;
		case DECIDES_VALUE_MOR: Phrases::Parser::register_phrasal(VALUE_PHRASE_MC, ph, W); break;
	}
}

@ At this point, then, we've identified the meaning code (MC) to register
the phrase under, and must make the actual registration.

=
phrase *last_phrase_where_rp_problemed = NULL;
void Phrases::Parser::register_phrasal(unsigned int phrase_mc, phrase *ph, wording W) {
	LOGIF(PHRASE_REGISTRATION, "Register phrasal on <%W>: $u\n", W,
		Phrases::TypeData::kind(&(ph->type_data)));

	@<Vet phrase text for suitability@>;
	@<Look for slash-divided alternative phrasings and recurse to register all variations@>;

	ExcerptMeanings::register(phrase_mc, W, STORE_POINTER_phrase(ph));
}

@ Some sanity checks first:

@<Vet phrase text for suitability@> =
	int bl = 0, fixed_words = 0;
	if (phrase_mc == SAY_PHRASE_MC) fixed_words++;
	LOOP_THROUGH_WORDING(i, W) {
		if (Lexer::word(i) == OPENBRACKET_V) bl++;
		else if (Lexer::word(i) == CLOSEBRACKET_V) bl--;
		else if (bl == 0) {
			fixed_words++;
			if (Vocabulary::test_flags(i, TEXT_MC+TEXTWITHSUBS_MC))
				@<Issue problem for quoted text in phrase wording@>;
		}
		if ((i<Wordings::last_wn(W)) && (Lexer::word(i) == CLOSEBRACKET_V) && (Lexer::word(i+1) == OPENBRACKET_V))
			@<Issue problem for brackets jammed up against each other@>;
	}
	if (fixed_words == 0) @<Issue problem for phrase consisting only of tokens@>;

@<Issue problem for quoted text in phrase wording@> =
	if (ph != last_phrase_where_rp_problemed) {
		Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_QuotedInPhrase),
			"phrases can't be defined with quoted text as part of the fixed wording",
			"so something like 'To go \"voluntarily\" to jail: ...' is not allowed.");
		last_phrase_where_rp_problemed = ph;
	}
	return;

@<Issue problem for brackets jammed up against each other@> =
	if (ph != last_phrase_where_rp_problemed) {
		Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_AdjacentTokens),
			"phrases can't be defined so that they have two bracketed varying elements "
			"immediately next to each other",
			"but instead need at least one fixed word in between. Thus 'To combine "
			"(X - a number) (Y - a number)' is not allowed, but 'To combine (X - a "
			"number) with (Y - a number)' works because of the 'with' dividing the "
			"bracketed terms X and Y.");
		last_phrase_where_rp_problemed = ph;
	}
	return;

@<Issue problem for phrase consisting only of tokens@> =
	if (ph != last_phrase_where_rp_problemed) {
		Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_MustBeOneWord),
			"a 'To...' phrase must contain at least one fixed word",
			"that is, one word other than the bracketed variables. So a declaration "
			"like 'To (N - number): ...' is not allowed.");
		last_phrase_where_rp_problemed = ph;
	}
	return;

@ The remaining work is to look out for this sort of thing:

>> To rearrange the deckchairs/loungers on (S - a ship): ...

where the slash indicates an alternative wording:

@<Look for slash-divided alternative phrasings and recurse to register all variations@> =
	int bl = 0;
	LOOP_THROUGH_WORDING(i, W) {
		if (Lexer::word(i) == OPENBRACKET_V) bl++;
		else if (Lexer::word(i) == CLOSEBRACKET_V) bl--;
		else if (bl == 0) {
			wchar_t *p;
			if (phrase_mc == SAY_PHRASE_MC) p = Lexer::word_raw_text(i);
			else p = Lexer::word_text(i);
			for (int j=0; p[j]; j++)
				if ((j>0) && (p[j-1] != '/') && (p[j] == '/') &&
					(p[j+1]) && (p[j+1] != '/'))
					@<This word is divided by a forward slash at the j-position in word i@>;
		}
	}

@ What we do is to reconstruct this as two different registrations:

>> To rearrange the deckchairs on (S - a ship): ...
>> To rearrange the loungers on (S - a ship): ...

and then recursively call ourselves to handle each individual one. We'll
call the left and right hand sides of "deckchairs/loungers" the A and
B forms.

Note than a phrase with many slashed words will register a frightening
number of possibilities -- for example,

>> To meld/blend/merge (O - object) onto/into/amongst/with (P - object) quickly/rapidly/pronto: ...

will register 36 excerpts. But the hashing in the excerpts parser shouldn't
make the result too slow.

@<This word is divided by a forward slash at the j-position in word i@> =
	TEMPORARY_TEXT(a_form);
	TEMPORARY_TEXT(b_form);
	@<Splice up the A and B forms of the slashed word@>;
	@<Make sure the A form isn't the S-word@>;

	wording AW = EMPTY_WORDING, BW = EMPTY_WORDING;
	@<Splice up the A and B forms of the whole phrase wording@>;
	if (Wordings::nonempty(AW)) Phrases::Parser::register_phrasal(phrase_mc, ph, AW);
	if (Wordings::nonempty(BW)) Phrases::Parser::register_phrasal(phrase_mc, ph, BW);
	DISCARD_TEXT(a_form);
	DISCARD_TEXT(b_form);
	return;

@ The double-dash means "omit this word altogether".

@<Splice up the A and B forms of the slashed word@> =
	for (int k=0; k<j; k++) PUT_TO(a_form, p[k]);
	for (int k=j+1; p[k]; k++) PUT_TO(b_form, p[k]);
	if (Str::eq_wide_string(a_form, L"--")) Str::clear(a_form);
	if (Str::eq_wide_string(b_form, L"--")) Str::clear(b_form);

@ If we don't check this then hybrids like

>> To say/adjust (X - an object): ...

will confuse two different sorts of phrase. ("Say" is allowed after the first
word, though.)

@<Make sure the A form isn't the S-word@> =
	if ((Str::eq_wide_string(a_form, L"say")) &&
		(i == Wordings::first_wn(W)) && (phrase_mc != SAY_PHRASE_MC))
		if (ph != last_phrase_where_rp_problemed) {
			Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_SaySlashed),
				"'say' is not allowed as the first word of a phrase",
				"even when presented as one of a number of slashed alternatives. "
				"(This is because 'say' is reserved for creating text substitutions.)");
			last_phrase_where_rp_problemed = ph;
		}

@<Splice up the A and B forms of the whole phrase wording@> =
	feed_t id = Feeds::begin();
	if (i > Wordings::first_wn(W)) Feeds::feed_wording(Wordings::up_to(W, i-1));
	if (Str::len(a_form) > 0) Feeds::feed_text_expanding_strings(a_form);
	if (i < Wordings::last_wn(W)) Feeds::feed_wording(Wordings::from(W, i+1));
	AW = Feeds::end(id);

	id = Feeds::begin();
	if (i > Wordings::first_wn(W)) Feeds::feed_wording(Wordings::up_to(W, i-1));
	if (Str::len(b_form) > 0) Feeds::feed_text_expanding_strings(b_form);
	if (i < Wordings::last_wn(W)) Feeds::feed_wording(Wordings::from(W, i+1));
	BW = Feeds::end(id);

@h Parsing invocations.
So, then, at this point the excerpt parser has identified a phrase which it
thinks may be being invoked in some text. For example, it may have read:

>> advance the pawn by 2;

and guessed that this is an invocation of

>> To advance (the piece - a chess piece) by (N - a number): ...

An S-node will have been constructed for the possibility that this is correct,
identifying the text of any phrase options used (here there are none) and the
text of the tokens, "the pawn" and "2".

We now take over, and construct an invocation structure on this basis.
Note that there's no reason to suppose this will pass type-checking:
we would be just as happy with

>> advance "frangipane" by 10:21 PM;

because our only aim here is to document the possibility for later checking.

The invocation is marked as "unproven", meaning that the typechecker hasn't
yet vetted it, unless it's a fixed wording with nothing to check:

>> To shed my skin: ...

because then our purely textual match is sufficient.

=
parse_node *Phrases::Parser::parse_against(phrase *ph, parse_node *p) {
	if (p == NULL) internal_error("parse against null subtree");
	wording WW = EMPTY_WORDING;
	wording OW = EMPTY_WORDING;
	wording token_text[15]; int no_tokens = 0;
	@<Extract all this text from the subtree@>;

	parse_node *inv = Invocations::new();
	Invocations::set_word_range(inv, WW);
	Node::set_phrase_invoked(inv, ph);

	Dash::suspend_validation(FALSE);
	ph_type_data *phtd = &(ph->type_data);
	int i;
	for (i=0; i<no_tokens; i++) @<Parse the ith token into the invocation@>;
	if (Wordings::nonempty(OW)) Invocations::set_phrase_options(inv, OW);
	Dash::suspend_validation(FALSE);

	LOGIF(MATCHING, "Parse against to invocation: $e\n", inv);

	return inv;
}

@ We will never actually hit the 15 tokens limit, because it's impossible to
register phrases with more than that number of tokens anyway.

@<Extract all this text from the subtree@> =
	WW = Node::get_text(p);
	p = p->down;
	if (p && (Annotations::read_int(p, is_phrase_option_ANNOT))) {
		OW = Node::get_text(p);
		p = p->next;
	}
	for (; ((p) && (no_tokens<15)); p = p->next) {
		if (Node::get_type(p) == UNKNOWN_NT)
			token_text[no_tokens++] = Node::get_text(p);
		else internal_error("Unexpected production in phrase args");
	}
	if (no_tokens > MAX_TOKENS_PER_PHRASE)
		Problems::Fatal::issue("MAX_TOKENS_PER_PHRASE exceeded");

@ As can be seen, the way we parse the token text depends on the context,
that is, depends on what we're expecting to find. (This is why the excerpt
parser needs our help in the first place.)

@<Parse the ith token into the invocation@> =
	parse_node *to_match = phtd->token_sequence[i].to_match;

	wording X = Articles::remove_the(token_text[i]);

	if (phtd->token_sequence[i].construct == NEW_LOCAL_PT_CONSTRUCT) {
		to_match = Specifications::from_kind(K_value);
		Invocations::make_token(inv, i, NEW_LOCAL_CONTEXT_NT, X, phtd->token_sequence[i].token_kind);
	}
	else if (phtd->token_sequence[i].construct == EXISTING_LOCAL_PT_CONSTRUCT) {
		to_match = Specifications::from_kind(K_value);
		Invocations::make_token(inv, i, LVALUE_LOCAL_CONTEXT_NT, X, phtd->token_sequence[i].token_kind);
	}
	else if (phtd->token_sequence[i].construct == STORAGE_PT_CONSTRUCT)
		Invocations::make_token(inv, i, LVALUE_CONTEXT_NT, X, Node::get_kind_of_value(to_match));
	else if (phtd->token_sequence[i].construct == TABLE_REFERENCE_PT_CONSTRUCT)
		Invocations::make_token(inv, i, LVALUE_TR_CONTEXT_NT, X, Node::get_kind_of_value(to_match));
	else if (phtd->token_sequence[i].construct == CONDITION_PT_CONSTRUCT)
		Invocations::make_token(inv, i, CONDITION_CONTEXT_NT, X, NULL);
	else if (phtd->token_sequence[i].construct == VOID_PT_CONSTRUCT)
		Invocations::make_token(inv, i, VOID_CONTEXT_NT, X, NULL);
	else if (Specifications::is_kind_like(to_match))
		Invocations::make_token(inv, i, RVALUE_CONTEXT_NT, X, Specifications::to_kind(to_match));
	else if (Specifications::is_description(to_match))
		Invocations::make_token(inv, i, MATCHING_RVALUE_CONTEXT_NT, X, Specifications::to_kind(to_match));
	else if (Node::is(to_match, CONSTANT_NT))
		Invocations::make_token(inv, i, SPECIFIC_RVALUE_CONTEXT_NT, X, Specifications::to_kind(to_match));
	else Invocations::make_token(inv, i, RVALUE_CONTEXT_NT, X, NULL); /* doesn't actually happen */
	Invocations::set_token_to_be_parsed_against(inv, i, to_match);
	parse_node *as_parsed = Specifications::new_UNKNOWN(X);
	Invocations::set_token_as_parsed(inv, i, as_parsed);

@ =
void Phrases::Parser::parse_within_inv(parse_node *inv) {
	ExParser::warn_expression_cache();
	int N = Invocations::get_no_tokens(inv);
	for (int i = 0; i < N; i++) {
		parse_node *to_match = Invocations::get_token_to_be_parsed_against(inv, i);
		int cons = -1;
		phrase *ph = Node::get_phrase_invoked(inv);
		if (ph) cons = ph->type_data.token_sequence[i].construct;
		if ((to_match) || (cons == CONDITION_PT_CONSTRUCT) || (cons == VOID_PT_CONSTRUCT)) {
			parse_node *as_parsed = Invocations::get_token_as_parsed(inv, i);
			wording XW = Node::get_text(as_parsed);
			#ifdef IF_MODULE
				int pto = permit_trying_omission;
				if ((Specifications::is_kind_like(to_match)) &&
					(Kinds::Compare::eq(Specifications::to_kind(to_match), K_stored_action))) {
					permit_trying_omission = TRUE;
					@<Parse the action in a try phrase@>;
				} else {
					permit_trying_omission = FALSE;
			#endif
					@<Parse any other token@>;
			#ifdef IF_MODULE
				}
				permit_trying_omission = pto;
			#endif
			Node::set_text(as_parsed, XW);
			Invocations::set_token_as_parsed(inv, i, as_parsed);
		}
	}
}

@<Parse the action in a try phrase@> =
	if (<action-pattern>(XW))
		as_parsed = Conditions::new_TEST_ACTION(<<rp>>, XW);
	else {
		permit_trying_omission = FALSE;
		@<Parse any other token@>;
	}

@<Parse any other token@> =
	kind *save_probable_noun_phrase_context = probable_noun_phrase_context;
	int save_let_equation_mode = let_equation_mode;

	probable_noun_phrase_context = NULL;
	if (Specifications::is_kind_like(to_match))
		probable_noun_phrase_context =
			Specifications::to_kind(to_match);

	let_equation_mode = Phrases::TypeData::is_a_let_equation(ph);

	int t = FALSE; /* redundant assignment to keep |gcc| happy */
	if (Specifications::is_description(to_match))
		t = <s-value>(XW);
	else if (cons == CONDITION_PT_CONSTRUCT)
		t = <s-condition>(XW);
	else if (cons == VOID_PT_CONSTRUCT)
		t = <s-command>(XW);
	else
		t = <s-value>(XW);

	if (t) as_parsed = <<rp>>;
	else as_parsed = Specifications::new_UNKNOWN(XW);

	LOGIF(MATCHING, "(%d/%d) Expected kind $u: parsed token %W (cons %d) to $P\n",
		i+1, N, probable_noun_phrase_context, XW, cons, as_parsed);

	probable_noun_phrase_context = save_probable_noun_phrase_context;
	let_equation_mode = save_let_equation_mode;
