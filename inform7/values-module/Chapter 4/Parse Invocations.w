[ParseInvocations::] Parse Invocations.

To register phrases with the excerpt parser, and to provide the excerpt parser
with help in putting invocations together.

@h Introduction.
"To..." phrases are defined with prototypes: for example, in
>> To add (new entry - K) to (L - list of values of kind K), if absent: ...
the prototype is |add (new entry - K) to (L - list of values of kind K)|. In
this section we define three related functions: one to register the prototype
with the excerpt parser, one to convert any textual match against that to an
invocation subtree, and one to perform more detailed parsing on such a subtree
later on.

@h Registering phrase prototypes with the excerpt parser.

=
void ParseInvocations::register_excerpt(id_body *idb) {
	id_type_data *type_data = &(idb->type_data);
	wording W = type_data->registration_text;
	if (Wordings::empty(W)) return;
	LOGIF(PHRASE_REGISTRATION, "Register phrase <%W> with type:\n$h", W, type_data);
	if (IDTypeData::is_a_say_phrase(idb)) @<Register a say@>
	else @<Register anything else@>;
}

@ Here the prototype is |say ...|, but we trim off the word "say", since it is
not needed when the phrase is invoked in (for example) a text substitution.

@<Register a say@> =
	ParseInvocations::register_phrasal(SAY_PHRASE_MC, idb,
		Wordings::trim_first_word(W));

@ Note that control structures have prototypes such as |if (V - value) is begin|,
in which the keyword "begin" at the end is similarly not registered, since it
is now no longer a compulsory part of the syntax.

@<Register anything else@> =
	switch(IDTypeData::get_mor(type_data)) {
		case DECIDES_NOTHING_MOR:
			if (type_data->as_inline.block_follows != NO_BLOCK_FOLLOWS)
				W = Wordings::trim_last_word(W);
			ParseInvocations::register_phrasal(VOID_PHRASE_MC, idb, W);
			break;
		case DECIDES_CONDITION_MOR:
			ParseInvocations::register_phrasal(COND_PHRASE_MC, idb, W);
			break;
		case DECIDES_VALUE_MOR:
			ParseInvocations::register_phrasal(VALUE_PHRASE_MC, idb, W);
			break;
	}

@ All those possibilities result in a call to the following function, with |mc|
set to the appropriate meaning code and |W| the registration text, perhaps
trimmed a little. Surprisingly, though, this begins a recursion, since the function
calls itself in order to provide for alternate wordings in prototypes:

=
id_body *last_phrase_with_problem_on_prototype = NULL;
void ParseInvocations::register_phrasal(unsigned int phrase_mc, id_body *idb, wording W) {
	@<Vet phrase text for suitability@>;
	@<Look for slash-divided alternative phrasings and recurse to register all variations@>;
	@<With slashes out of the picture, register what we have@>;
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
		if ((i<Wordings::last_wn(W)) &&
			(Lexer::word(i) == CLOSEBRACKET_V) && (Lexer::word(i+1) == OPENBRACKET_V))
			@<Issue problem for brackets jammed up against each other@>;
	}
	if (fixed_words == 0) @<Issue problem for phrase consisting only of tokens@>;

@<Issue problem for quoted text in phrase wording@> =
	if (idb != last_phrase_with_problem_on_prototype) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_QuotedInPhrase),
			"phrases can't be defined with quoted text as part of the fixed wording",
			"so something like 'To go \"voluntarily\" to jail: ...' is not allowed.");
		last_phrase_with_problem_on_prototype = idb;
	}
	return;

@<Issue problem for brackets jammed up against each other@> =
	if (idb != last_phrase_with_problem_on_prototype) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_AdjacentTokens),
			"phrases can't be defined so that they have two bracketed varying elements "
			"immediately next to each other",
			"but instead need at least one fixed word in between. Thus 'To combine "
			"(X - a number) (Y - a number)' is not allowed, but 'To combine (X - a "
			"number) with (Y - a number)' works because of the 'with' dividing the "
			"bracketed terms X and Y.");
		last_phrase_with_problem_on_prototype = idb;
	}
	return;

@<Issue problem for phrase consisting only of tokens@> =
	if (idb != last_phrase_with_problem_on_prototype) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_MustBeOneWord),
			"a 'To...' phrase must contain at least one fixed word",
			"that is, one word other than the bracketed variables. So a declaration "
			"like 'To (N - number): ...' is not allowed.");
		last_phrase_with_problem_on_prototype = idb;
	}
	return;

@ The remaining work is to look out for this sort of thing:
= (text as Inform 7)
To rearrange the deckchairs/loungers on (S - a ship): ...
=
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
= (text as Inform 7)
To rearrange the deckchairs on (S - a ship): ...
To rearrange the loungers on (S - a ship): ...
=
and then recursively call ourselves to handle each individual one. We'll call
the left and right hand sides of "deckchairs/loungers" the A and B forms.

Note than a phrase with many slashed words will register a frightening number of
possibilities -- for example,
= (text as Inform 7)
>> To meld/blend/merge (O - object) onto/into/amongst/with (P - object) quickly/rapidly/pronto: ...
=
will register 36 excerpts. But the hashing in the excerpts parser shouldn't
make the result too slow, and in any case authors do not often do this.

@<This word is divided by a forward slash at the j-position in word i@> =
	TEMPORARY_TEXT(a_form)
	TEMPORARY_TEXT(b_form)
	@<Splice up the A and B forms of the slashed word@>;
	@<Make sure the A form isn't the S-word@>;

	wording AW = EMPTY_WORDING, BW = EMPTY_WORDING;
	@<Splice up the A and B forms of the whole phrase wording@>;
	if (Wordings::nonempty(AW)) ParseInvocations::register_phrasal(phrase_mc, idb, AW);
	if (Wordings::nonempty(BW)) ParseInvocations::register_phrasal(phrase_mc, idb, BW);
	DISCARD_TEXT(a_form)
	DISCARD_TEXT(b_form)
	return;

@ The double-dash means "omit this word altogether".

@<Splice up the A and B forms of the slashed word@> =
	for (int k=0; k<j; k++) PUT_TO(a_form, p[k]);
	for (int k=j+1; p[k]; k++) PUT_TO(b_form, p[k]);
	if (Str::eq_wide_string(a_form, L"--")) Str::clear(a_form);
	if (Str::eq_wide_string(b_form, L"--")) Str::clear(b_form);

@ If we don't check this then hybrids like |To say/adjust (X - an object)| will
confuse two fundamentally different sorts of phrase. ("Say" is allowed after the
first word, though.)

@<Make sure the A form isn't the S-word@> =
	if ((Str::eq_wide_string(a_form, L"say")) &&
		(i == Wordings::first_wn(W)) && (phrase_mc != SAY_PHRASE_MC))
		if (idb != last_phrase_with_problem_on_prototype) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_SaySlashed),
				"'say' is not allowed as the first word of a phrase",
				"even when presented as one of a number of slashed alternatives. "
				"(This is because 'say' is reserved for creating text substitutions.)");
			last_phrase_with_problem_on_prototype = idb;
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

@<With slashes out of the picture, register what we have@> =
	LOGIF(PHRASE_REGISTRATION, "Register phrasal on <%W> with mc %08x\n", W, phrase_mc);
	Lexicon::register(phrase_mc, W, STORE_POINTER_id_body(idb));

@h Converting excerpt parser results to invocation lists.
Suppose, then, that the excerpt parser has identified a phrase which it
thinks may be being invoked in some text. It will have given us this subtree
as its preliminary findings |p|:
= (text)
	VOID_PHRASE_MC "add 17 to the list of small primes, if absent"
	    UNKNOWN_NT "if absent" {is-phrase-option}
	    UNKNOWN_NT "17"
	    UNKNOWN_NT "the list of small primes"
=
and we need to return a two-token invocation subtree -- see //Invocations// for
what these look like.

=
parse_node *ParseInvocations::results_as_invocation(id_body *idb, parse_node *p) {
	if (p == NULL) internal_error("parse against null subtree");
	wording WW = EMPTY_WORDING;
	wording OW = EMPTY_WORDING;
	wording token_text[MAX_TOKENS_PER_PHRASE]; int no_tokens = 0;
	@<Extract all this text from the results subtree@>;

	parse_node *inv = Invocations::new(WW);
	Invocations::invoke_To_phrase(inv, idb);
	for (int i=0; i<no_tokens; i++) @<Create the ith token@>;
	if (Wordings::nonempty(OW)) Invocations::set_phrase_options(inv, OW);

	LOGIF(MATCHING, "Results as invocation: $e\n", inv);
	return inv;
}

@<Extract all this text from the results subtree@> =
	WW = Node::get_text(p);
	p = p->down;
	if (p && (Annotations::read_int(p, is_phrase_option_ANNOT))) {
		OW = Node::get_text(p);
		p = p->next;
	}
	for (; ((p) && (no_tokens<MAX_TOKENS_PER_PHRASE)); p = p->next) {
		if (Node::get_type(p) == UNKNOWN_NT)
			token_text[no_tokens++] = Node::get_text(p);
		else internal_error("Unexpected production in phrase args");
	}
	if (no_tokens > MAX_TOKENS_PER_PHRASE)
		Problems::fatal("MAX_TOKENS_PER_PHRASE exceeded");

@ As can be seen, the way we parse the token text depends on the context,
that is, depends on what we're expecting to find. (This is why the excerpt
parser needs our help in the first place.) See //assertions: Phrase Type Data//
for what these contextual codes mean.

@<Create the ith token@> =
	id_type_data *type_data = &(idb->type_data);
	parse_node *to_match = type_data->token_sequence[i].to_match;
	wording X = Articles::remove_the(token_text[i]);
	kind *K = NULL;

	switch (type_data->token_sequence[i].construct) {
		case NEW_LOCAL_IDTC:
			to_match = Specifications::from_kind(K_value);
			Invocations::attach_token(inv, i, NEW_LOCAL_CONTEXT_NT, X);
			K = IDTypeData::token_kind(type_data, i);
			break;
		case OLD_LOCAL_IDTC:
			to_match = Specifications::from_kind(K_value);
			Invocations::attach_token(inv, i, LVALUE_LOCAL_CONTEXT_NT, X);
			K = IDTypeData::token_kind(type_data, i);
			break;
		case STORAGE_IDTC:
			Invocations::attach_token(inv, i, LVALUE_CONTEXT_NT, X);
			K = Node::get_kind_of_value(to_match);
			break;
		case TABLE_REF_IDTC:
			Invocations::attach_token(inv, i, LVALUE_TR_CONTEXT_NT, X);
			K = Node::get_kind_of_value(to_match);
			break;
		case CONDITION_IDTC:
			Invocations::attach_token(inv, i, CONDITION_CONTEXT_NT, X);
			break;
		case VOID_IDTC:
			Invocations::attach_token(inv, i, VOID_CONTEXT_NT, X);
			break;
		default:
			if (Specifications::is_kind_like(to_match)) {
				Invocations::attach_token(inv, i, RVALUE_CONTEXT_NT, X);
				K = Specifications::to_kind(to_match);
			} else if (Specifications::is_description(to_match)) {
				Invocations::attach_token(inv, i, MATCHING_RVALUE_CONTEXT_NT, X);
				K = Specifications::to_kind(to_match);
			} else if (Node::is(to_match, CONSTANT_NT)) {
				Invocations::attach_token(inv, i, SPECIFIC_RVALUE_CONTEXT_NT, X);
				K = Specifications::to_kind(to_match);
			} else {
				Invocations::attach_token(inv, i, RVALUE_CONTEXT_NT, X); /* doesn't actually happen */
			}
			break;
	}
		
	Invocations::set_token_to_be_parsed_against(inv, i, to_match);
	if (K) Invocations::set_kind_required_by_context(inv, i, K);
	parse_node *as_parsed = Specifications::new_UNKNOWN(X);
	Invocations::set_token_as_parsed(inv, i, as_parsed);

@h A more detailed view later on.
In the invocation subtrees constructed above, the wording in the tokens has
not even been looked at: we now have something like this --
= (text)
	INVOCATION_NT "add 17 to the list of small primes, if absent"
		RVALUE_CONTEXT_NT
		    UNKNOWN_NT "17"
		RVALUE_CONTEXT_NT
	   		UNKNOWN_NT "the list of small primes"
=
It is now time to look inside those |UNKNOWN_NT| nodes.

=
void ParseInvocations::parse_within_inv(parse_node *inv) {
	PreformCache::warn_of_changes();
	int N = Invocations::get_no_tokens(inv);
	for (int i = 0; i < N; i++) {
		parse_node *to_match = Invocations::get_token_to_be_parsed_against(inv, i);
		int cons = -1;
		id_body *idb = Node::get_phrase_invoked(inv);
		if (idb) cons = idb->type_data.token_sequence[i].construct;
		if ((to_match) || (cons == CONDITION_IDTC) || (cons == VOID_IDTC)) {
			parse_node *as_parsed = Invocations::get_token_as_parsed(inv, i);
			wording XW = Node::get_text(as_parsed);
			@<Parse this token@>;
			Node::set_text(as_parsed, XW);
			Invocations::set_token_as_parsed(inv, i, as_parsed);
		}
	}
}

@ For the probable NP context and the let equation context, see
//Type Expressions and Values//. They just mean "what kind of value might
we expect here?" and "is this an equation?" respectively.

@<Parse this token@> =
	kind *save_probable_noun_phrase_context = probable_noun_phrase_context;
	probable_noun_phrase_context = NULL;
	if (Specifications::is_kind_like(to_match))
		probable_noun_phrase_context = Specifications::to_kind(to_match);
	@<Parse within this probable kind@>;
	probable_noun_phrase_context = save_probable_noun_phrase_context;

@<Parse within this probable kind@> =
	int save_let_equation_mode = let_equation_mode;
	let_equation_mode = IDTypeData::is_a_let_equation(idb);
	@<Parse within this equation context@>;
	let_equation_mode = save_let_equation_mode;

@<Parse within this equation context@> =
	if ((K_stored_action) && (Kinds::eq(probable_noun_phrase_context, K_stored_action)))
		@<Parse a stored action@>
	else
		@<Parse any other token@>;

@ This awkward manoeuvre just means that if the actions feature is active, and
therefore |K_stored_action| exists, and if we need to be parsing something to
match that, then we need to parse action patterns in a different context from
the usual one. (The syntax to describe the action used in "if taking a book"
and "try taking a book" looks the same, but in fact the former allows much
more flexibility than the latter, so the action pattern parser needs to be
told if it is supposed to parse only in the more restricted way.)

@<Parse a stored action@> =
	int saved = ParseActionPatterns::enter_mode(PERMIT_TRYING_OMISSION);
	if (<action-pattern>(XW)) {
		as_parsed = AConditions::new_action_TEST_VALUE(<<rp>>, XW);
	} else {
		ParseActionPatterns::exit_mode(PERMIT_TRYING_OMISSION);
		@<Parse any other token@>;
	}
	ParseActionPatterns::restore_mode(saved);

@<Parse any other token@> =
	int t = FALSE; /* redundant assignment to keep the compiler happy */
	if (Specifications::is_description(to_match)) t = <s-value>(XW);
	else if (cons == CONDITION_IDTC)              t = <s-condition>(XW);
	else if (cons == VOID_IDTC)                   t = <s-command>(XW);
	else                                          t = <s-value>(XW);

	if (t) as_parsed = <<rp>>;
	else as_parsed = Specifications::new_UNKNOWN(XW);

	LOGIF(MATCHING, "(%d/%d) Expected kind %u: parsed token %W (cons %d) to $P\n",
		i+1, N, probable_noun_phrase_context, XW, cons, as_parsed);
