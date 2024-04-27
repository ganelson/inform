[ParsingIDTypeData::] Parsing Type Data.

To parse the prototype text of a To... phrase into its type data.

@h Introduction.
This section provides just one function to the rest of Inform, //ParsingIDTypeData::parse//,
but it's a doozy. It parses the prototype text of a "To..." phrase into a complete and
correct set of type data for it. Recall that the prototype includes the initial word
"to", as in this example. We divide it further into a front part which gives the
return data; the middle main part, giving the wording needed to invoke the phrase;
and some annotations at the end, called doodads.
= (text as Inform 7)
To decide which number is (N - a number) doubled (deprecated) , slowly or quickly
<--------------------------------- prototype ----------------------------------->
<-- return data --------> <-- main prototype --> <- doodads ->  <--- options --->
=
If we detect phrase options, after a comma, we pass the word range for them
back. The IDTD we write to is factory-fresh except that it has already been
adjusted for an inline definition (if that's the kind of definition this is).

=
void ParsingIDTypeData::parse(id_type_data *idtd, wording XW) {
	int say_flag = FALSE; /* is this going to be a "say" phrase? */

	if (Wordings::nonempty(XW))
		XW = ParsingIDTypeData::phtd_parse_return_data(idtd, XW);        /* trim return from the front */
	if (Wordings::nonempty(XW))
		DocReferences::position_of_symbol(&XW);                   /* trim doc ref from the back */
	if (Wordings::nonempty(XW))
		XW = ParsingIDTypeData::phtd_parse_doodads(idtd, XW, &say_flag); /* and doodads from the back */

	wording OW = EMPTY_WORDING; /* the options wording */
	int cw = -1; /* word number of first comma */
	@<Find the first comma outside of parentheses, if any exists@>;
	if (cw >= 0) {
		int comma_presages_options = TRUE;
		@<Does this comma presage phrase options?@>;
		if (comma_presages_options) {
			if (say_flag) @<Issue a problem: say phrases aren't allowed options@>;
			OW = Wordings::from(XW, cw + 1);
			XW = Wordings::up_to(XW, cw - 1); /* trim preamble range to text before the comma */
		}
	}
	idtd->registration_text = XW;
	ParsingIDTypeData::phtd_main_prototype(idtd);
	PhraseOptions::parse_declared_options(&(idtd->options_data), OW);
}

@<Find the first comma outside of parentheses, if any exists@> =
	int bl = 0;
	LOOP_THROUGH_WORDING(i, XW) {
		if ((Lexer::word(i) == OPENBRACE_V) || (Lexer::word(i) == OPENBRACKET_V)) bl++;
		if ((Lexer::word(i) == CLOSEBRACE_V) || (Lexer::word(i) == CLOSEBRACKET_V)) bl--;
		if ((Lexer::word(i) == COMMA_V) && (bl == 0) &&
			(i>Wordings::first_wn(XW)) && (i<Wordings::last_wn(XW))) { cw = i; break; }
	}

@ In some control structures, comma is implicitly a sort of "then".

@<Does this comma presage phrase options?@> =
	if ((<control-structure-phrase>(XW)) &&
		(ControlStructures::comma_possible(<<rp>>)))
		comma_presages_options = FALSE;

@ If you find the explanation in this message unconvincing, you're not alone.
To be honest my preferred fix would be to delete phrase options from the
language altogether, but there we are; spilt milk.

@<Issue a problem: say phrases aren't allowed options@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_SayWithPhraseOptions),
		"phrase options are not allowed for 'say' phrases",
		"because the commas would lead to ambiguous sentences, and because the content of a "
		"substitution is intended to be something conceptually simple and not needing "
		"clarification.");

@h Return data.
As with C type declarations for functions, Inform phrase prototypes put their
return kinds up at the front, not the back. So we'll parse that first.

Note that <k-kind-prototype> parses <k-kind>, but in a mode which causes
the kind variables to be read as formal prototypes and not as their values.
This allows for tricky definitions like:

>> To decide which K is (name of kind of value K) which relates to (Y - L) by (R - relation of Ks to values of kind L)

where <k-kind-prototype> needs to recognise "K" even though the tokens
haven't yet been parsed, so that we don't yet know it will be meaningful.

@d DEC_RANN 1
@d DEV_RANN 2
@d TOC_RANN 3
@d TOV_RANN 4
@d TO_RANN 5

=
<to-return-data> ::=
	to {decide yes/no} |                             ==> { DEC_RANN, NULL }
	to {decide on ...} |                             ==> { DEV_RANN, NULL }
	to decide whether/if the ... |                   ==> { TOC_RANN, NULL }
	to decide whether/if ... |                       ==> { TOC_RANN, NULL }
	to decide what/which <return-kind> is the ... |  ==> { TOV_RANN, RP[1] }
	to decide what/which <return-kind> is ... |      ==> { TOV_RANN, RP[1] }
	to ...                                           ==> { TO_RANN,  NULL }

<return-kind> ::=
	<k-kind-prototype> |                          ==> { pass 1 }
	...                                              ==> @<Issue PM_UnknownValueToDecide problem@>

@<Issue PM_UnknownValueToDecide problem@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, W);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_UnknownValueToDecide));
	Problems::issue_problem_segment(
		"The phrase you describe in %1 seems to be trying to decide a value, "
		"but '%2' is not a kind that I recognise. (I had expected something "
		"like 'number' or 'object' - see the Kinds index for what's available.)");
	Problems::issue_problem_end();
	==> { -, K_number};

@ A curiosity here is that exactly one phrase definition is allowed to decide
a truth state: "To decide what truth state is whether or not (C - condition)",
from Basic Inform. So we throw a problem only on subsequent tries.

=
int no_truth_state_decisions_allowed = 0;
wording ParsingIDTypeData::phtd_parse_return_data(id_type_data *idtd, wording XW) {
	idtd->return_kind = NULL;
	if (<to-return-data>(XW)) {
		XW = GET_RW(<to-return-data>, 1);
		int mor = -1; kind *K = NULL;
		switch (<<r>>) {
			case DEC_RANN: break;
			case DEV_RANN: break;
			case TOC_RANN: mor = DECIDES_CONDITION_MOR; break;
			case TOV_RANN: mor = DECIDES_VALUE_MOR; K = <<rp>>; break;
			case TO_RANN:  mor = DECIDES_NOTHING_MOR; break;
		}
		if (mor >= 0) IDTypeData::set_mor(idtd, mor, K);
	} else {
		WRITE_TO(STDERR, "XW = %W\n", XW);
		internal_error("to phrase without to");
	}
	if (Kinds::eq(idtd->return_kind, K_truth_state)) {
		if (no_truth_state_decisions_allowed++ > 0) {
			StandardProblems::sentence_problem(Task::syntax_tree(),
				_p_(PM_TruthStateToDecide),
				"phrases are not allowed to decide a truth state",
				"and should be defined with the form 'To decide if ...' rather than "
				"'To decide what truth state is ...'.");
		}
	}
	return XW;
}

@h Doodads.
These are the optional annotations placed at the end of the prototype but which
are not part of what has to be matched. (They're mostly relevant only for inline
definitions of basic language constructs, so many Inform users know nothing of
the syntax below.)

@d NO_ANN 0
@d SAY_ANN 1
@d LET_ANN 2
@d BLOCK_ANN 3
@d IN_LOOP_ANN 4
@d IN_ANN 5
@d CONDITIONAL_ANN 6
@d LOOP_ANN 7

=
<phrase-preamble> ::=
	<phrase-preamble> ( deprecated ) |              ==> { R[1], -, <<deprecated>> = TRUE }
	<say-preamble>	|                               ==> { SAY_ANN, -, <<say-ann>> = R[1] }
	<to-preamble>                                   ==> { pass 1 }

<to-preamble> ::=
	<to-preamble> ( arithmetic operation <cardinal-number> ) | ==> { R[1], -, <<operation>> = R[2] }
	<to-preamble> ( assignment operation ) |        ==> { R[1], -, <<assign>> = TRUE }
	<to-preamble> ( offset assignment operation ) | ==> { R[1], -, <<offset>> = TRUE, <<assign>> = TRUE }
	{let ... be given by ...} |                     ==> { LET_ANN, -, <<eqn>> = TRUE }
	{let ...} |                                     ==> { LET_ANN, -, <<eqn>> = FALSE }
	... -- end |                                    ==> { BLOCK_ANN, - }
	... -- end conditional |                        ==> { CONDITIONAL_ANN, - }
	... -- end loop |                               ==> { LOOP_ANN, - }
	... -- in loop |                                ==> { IN_LOOP_ANN, - }
	... -- in ### |                                 ==> { IN_ANN, - }
	...                                             ==> { NO_ANN, - }

@ Phrases whose definitions begin "To say" are usually but not necessarily text
substitutions.

@d NO_SANN 1
@d CONTROL_SANN 2
@d BEGIN_SANN 3
@d CONTINUE_SANN 4
@d ENDM_SANN 5
@d END_SANN 6

=
<say-preamble> ::=
	<say-preamble> -- running on |       ==> { R[1], -, <<run-on>> = TRUE }
	{say otherwise/else} |               ==> { CONTROL_SANN, -, <<control>> = OTHERWISE_SAY_CS }
	{say otherwise/else if/unless ...} | ==> { CONTROL_SANN, -, <<control>> = OTHERWISE_IF_SAY_CS }
	{say if/unless ...} |                ==> { CONTROL_SANN, -, <<control>> = IF_SAY_CS }
	{say end if/unless} |                ==> { CONTROL_SANN, -, <<control>> = END_IF_SAY_CS }
	{say ...} -- beginning ### |         ==> { BEGIN_SANN, - }
	{say ...} -- continuing ### |        ==> { CONTINUE_SANN, - }
	{say ...} -- ending ### with marker ### | ==> { ENDM_SANN, - }
	{say ...} -- ending ### |            ==> { END_SANN, - }
	{say ...}                            ==> { NO_SANN, - }

@ Since doodads are notated at the back of the prototype text, the following trims
the end off the wording given.

=
wording ParsingIDTypeData::phtd_parse_doodads(id_type_data *idtd, wording W, int *say_flag) {
	<<operation>> = -1; <<assign>> = FALSE; <<offset>> = FALSE;
	<<deprecated>> = FALSE; <<run-on>> = FALSE;
	<phrase-preamble>(W); /* guaranteed to match any non-empty text */
	if (<<r>> == SAY_ANN) W = GET_RW(<say-preamble>, 1);
	else W = GET_RW(<to-preamble>, 1);

	if (<<deprecated>>) IDTypeData::deprecate_phrase(idtd);

	int let = FALSE, blk = NO_BLOCK_FOLLOWS, only_in = 0; /* "nothing unusual" defaults */
	switch (<<r>>) {
		case BLOCK_ANN:			blk = MISCELLANEOUS_BLOCK_FOLLOWS; break;
		case CONDITIONAL_ANN:	blk = CONDITIONAL_BLOCK_FOLLOWS; break;
		case IN_ANN:			@<Set only-in to the first keyword@>; break;
		case IN_LOOP_ANN:		only_in = -1; break;
		case LET_ANN:			if (<<eqn>>) let = EQUATION_LET_PHRASE;
								else let = ASSIGNMENT_LET_PHRASE;
								break;
		case LOOP_ANN:			blk = LOOP_BODY_BLOCK_FOLLOWS; break;
		case SAY_ANN: 			@<We seem to be parsing a "say" phrase@>; break;
	}
	IDTypeData::make_id(&(idtd->as_inline), <<operation>>, <<assign>>, <<offset>>,
		let, blk, only_in);

	@<Vet the phrase for an unfortunate prepositional collision@>;
	return W;
}

@ For example, if the preamble is "To while...", then this sets |only_in|
to the word number of "while".

@<Set only-in to the first keyword@> =
	wording OW = GET_RW(<to-preamble>, 2);
	only_in = Wordings::first_wn(OW);

@ And similarly for the say annotations.

@<We seem to be parsing a "say" phrase@> =
	*say_flag = TRUE;
	int cs = -1, pos = -1, at = -1, cat = -1;
	wording XW = EMPTY_WORDING;
	switch (<<say-ann>>) {
		case CONTROL_SANN:	cs = <<control>>; break;
		case BEGIN_SANN:	pos = SSP_START; XW = GET_RW(<say-preamble>, 2);
							at = Wordings::first_wn(XW); break;
		case CONTINUE_SANN:	pos = SSP_MIDDLE; XW = GET_RW(<say-preamble>, 2);
							at = Wordings::first_wn(XW); break;
		case ENDM_SANN:		pos = SSP_END; XW = GET_RW(<say-preamble>, 2);
							at = Wordings::first_wn(XW);
							XW = GET_RW(<say-preamble>, 3); cat = Wordings::first_wn(XW);
							break;
		case END_SANN:		pos = SSP_END; XW = GET_RW(<say-preamble>, 2);
							at = Wordings::first_wn(XW); break;
	}
	IDTypeData::make_sd(&(idtd->as_say), <<run-on>>, cs, pos, at, cat);

@ The definition remaining after the preamble is removed is then vetted.
This is a possibly controversial point, in fact, because the check in question
is not actually needed. But a definition violating this would be unlikely to
work as the author hoped, and would almost certainly throw a cascade of other
but less helpful problem messages.

@<Vet the phrase for an unfortunate prepositional collision@> =
	<phrase-vetting>(W);

@ =
<phrase-vetting> ::=
	( ...... ) <copular-verb> {<copular-preposition>} ( ...... )  ==> @<Issue PM_MasksRelation@>

@<Issue PM_MasksRelation@> =
	wording RW = GET_RW(<phrase-vetting>, 2);
	preposition *prep = RP[2];
	Problems::quote_source(1, current_sentence);
	if (Prepositions::get_where_pu_created(prep) == NULL)
		Problems::quote_text(4, "This is a relation defined inside Inform.");
	else
		Problems::quote_source(4, Prepositions::get_where_pu_created(prep));
	Problems::quote_wording(2, W);
	Problems::quote_wording(3, RW);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_MasksRelation));
	Problems::issue_problem_segment(
		"I don't want you to define a phrase with the wording you've used in "
		"in %1 because it could be misunderstood. There is already a definition "
		"of what it means for something to be '%3' something else, so this "
		"phrase definition would look too much like testing whether "
		"'X is %3 Y'. (%4.)");
	Problems::issue_problem_end();
	==> { -, K_number };

@h Prototype body.
The main part of the prototype is in the middle, but is parsed last.

@ At this final stage of parsing, all annotations to do with inline or say
behaviour have been stripped away, and what's left is the text which will
form the word and token sequences:

=
void ParsingIDTypeData::phtd_main_prototype(id_type_data *idtd) {
	idtd->no_tokens = 0;
	idtd->no_words = 0;

	wording W = idtd->registration_text;
	int i = Wordings::first_wn(W);
	while (i <= Wordings::last_wn(W)) {
		int word_to_add = 0; /* redundant assignment to keep |gcc| happy */
		<phrase-definition-word-or-token>(Wordings::from(W, i));
		switch (<<r>>) {
			case NOT_APPLICABLE:	return; /* a problem message has been issued */
			case TRUE:				@<Add a token next@>; break;
			case FALSE: 			@<Add a word next@>; break;
		}
		if (idtd->no_words >= MAX_WORDS_PER_PHRASE) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_PhraseTooLong),
				"this phrase has too many words",
				"and needs to be simplified.");
			idtd->registration_text = Wordings::up_to(W, i-1);
			return;
		}
		idtd->word_sequence[idtd->no_words++] = word_to_add;
	}

	@<Sort out the kind variables in this declaration@>;
}

@<Add a word next@> =
	word_to_add = i++;

@<Add a token next@> =
	int C = <<token-construct>>, name_supplied = TRUE;
	if (C < 0) { C = -C; name_supplied = FALSE; }
	if (C == ERRONEOUS_IDTC) return; /* a problem message has been issued */

	parse_node *spec = <<rp>>; /* what is to be matched */

	wording TW = EMPTY_WORDING;
	if (name_supplied) TW = GET_RW(<phrase-token-declaration>, 1); /* the name */

	wording A = GET_RW(<phrase-definition-word-or-token>, 1);
	i = Wordings::first_wn(A);
	W = Wordings::up_to(W, Wordings::last_wn(A)); /* move past this token */

	@<Unless we are inline, phrase tokens have to be or describe values@>;
	@<Phrase tokens cannot be quantified@>;
	@<Fashion a suitable phrase token@>;

@<Fashion a suitable phrase token@> =
	id_type_token pht;
	IDTypeData::set_spec(&pht, spec);
	pht.construct = C;
	pht.token_name = TW;
	word_to_add = idtd->no_tokens;
	if (idtd->no_tokens >= MAX_TOKENS_PER_PHRASE) {
		if (idtd->no_tokens == MAX_TOKENS_PER_PHRASE) {
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, Node::get_text(spec));
			int n = MAX_TOKENS_PER_PHRASE;
			Problems::quote_number(3, &n);
			StandardProblems::handmade_problem(Task::syntax_tree(),
				_p_(PM_TooManyTokens));
			Problems::issue_problem_segment(
				"In %1, I ran out of tokens when I got up to '%2'. "
				"Phrases are only allowed %3 tokens, that is, they "
				"are only allowed %3 bracketed parts in their definitions.");
			Problems::issue_problem_end();
		}
	} else {
		idtd->token_sequence[idtd->no_tokens] = pht;
		idtd->no_tokens++;
	}

@<Unless we are inline, phrase tokens have to be or describe values@> =
	if ((C != STANDARD_IDTC) &&
		(C != KIND_NAME_IDTC) &&
		(idtd->as_inline.invoked_inline_not_as_call == FALSE)) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, Node::get_text(spec));
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_NoninlineUsesNonvalues));
		Problems::issue_problem_segment(
			"In %1, the text '%2' after the hyphen should tell me what kind of "
			"value goes here (like 'a number', or 'a vehicle'), but this is not "
			"a kind: it does describe something I can understand, but not "
			"something which can then be used as a value. (It would be allowed "
			"in low-level, so-called 'inline' phrase definitions, but not in a "
			"standard phrase definition like this one.)");
		Problems::issue_problem_end();
		return;
	}

@<Phrase tokens cannot be quantified@> =
	if (Specifications::is_description(spec)) {
		pcalc_prop *prop = Descriptions::to_proposition(spec);
		if (Binding::number_free(prop) != 1) {
			LOG("Spec is: $T\nProposition is: $D\n", spec, prop);
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, Node::get_text(spec));
			StandardProblems::handmade_problem(Task::syntax_tree(),
				_p_(PM_PhraseTokenQuantified));
			Problems::issue_problem_segment(
				"In %1, the text '%2' after the hyphen should tell me what kind of "
				"value goes here (like 'a number', or 'a vehicle'), but it has to "
				"be a single value, and not a description of what might be multiple "
				"values. So 'N - a number' is fine, but not 'N - three numbers' or "
				"'N - every number'.");
			Problems::issue_problem_end();
			return;
		}
	} else if (Node::is(spec, TEST_VALUE_NT)) spec = spec->down;

@<Sort out the kind variables in this declaration@> =
	int i, t = 0;
	kind *declarations[27];
	int usages[27];
	for (i=1; i<=26; i++) { usages[i] = 0; declarations[i] = NULL; }
	for (i=0; i<idtd->no_tokens; i++)
		t += ParsingIDTypeData::find_kind_variable_domains(IDTypeData::token_kind(idtd, i),
			usages, declarations);
	if (t > 0) {
		int problem_thrown = FALSE;
		for (int v=1; (v<=26) && (problem_thrown == FALSE); v++)
			if ((usages[v] > 0) && (declarations[v] == NULL))
				@<Issue a problem for an undeclared kind variable@>;
		if (problem_thrown == FALSE)
			for (i=0; i<idtd->no_tokens; i++)
				if (IDTypeData::token_kind(idtd, i))
					@<Substitute for any kind variables in the match specification@>;
	}

@<Issue a problem for an undeclared kind variable@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_UndeclaredKindVariable),
		"this phrase uses a kind variable which is not declared",
		"which is not allowed.");
	IDTypeData::set_spec(&(idtd->token_sequence[i]),
		Descriptions::from_kind(Kinds::binary_con(CON_phrase, K_value, K_value), FALSE));
	problem_thrown = TRUE;

@ This following process is much less mysterious than it sounds. Suppose we
have the phrase:

>> To add (purchase - K) to (shopping list - list of arithmetic values of kind K): ...

This tells us that the matcher should accept any list of arithmetic values,
and then set K equal to the kind of the entries, and require that the purchase
agree. According to the |declarations| array already made, K is declared as a
kind of "arithmetic value". What the code in this paragraph does is to change
the |to_match| specifications as if the phrase had read:

>> To add (purchase - arithmetic value) to (shopping list - list of arithmetic values): ...

In other words, we substitute "arithmetic value" in place of K, and thus get
rid of variables from the match specifications entirely. We can safely do
this because the |token_kind| for these two tokens remain
"K" and "list of K" respectively.

@<Substitute for any kind variables in the match specification@> =
	IDTypeData::substitute_spec(idtd, i, declarations);

@ The looks through a kind, returning the number of kind variables it finds. For
lots of straightforward kinds, such as "list of numbers", it returns 0.

=
int ParsingIDTypeData::find_kind_variable_domains(kind *K, int *usages, kind **declarations) {
	int t = 0;
	if (K) {
		int N = Kinds::get_variable_number(K);
		if (N > 0) {
			t++;
			@<A kind variable has been found@>;
		}
		if (Kinds::is_proper_constructor(K)) {
			int a = Kinds::arity_of_constructor(K);
			if (a == 1)
				t += ParsingIDTypeData::find_kind_variable_domains(
					Kinds::unary_construction_material(K), usages, declarations);
			else {
				kind *X = NULL, *Y = NULL;
				Kinds::binary_construction_material(K, &X, &Y);
				t += ParsingIDTypeData::find_kind_variable_domains(X, usages, declarations);
				t += ParsingIDTypeData::find_kind_variable_domains(Y, usages, declarations);
			}
		}
	}
	return t;
}

@ We count how many times each variable appears. It should be given a domain
in exactly one place: for example,

>> To amaze (alpha - an arithmetic value of kind K) with (beta - an enumerated value of kind K): ...

produces the following problem, because the domain of K has been given twice.

@<A kind variable has been found@> =
	usages[N]++;
	kind *dec = Kinds::get_variable_stipulation(K);
	if (dec) {
		if (declarations[N]) {
			StandardProblems::sentence_problem(Task::syntax_tree(),
				_p_(PM_DoublyDeclaredKindVariable),
				"this phrase declares the same kind variable more than once",
				"and ought to declare each variable once each.");
		}
		declarations[N] = dec;
	}

@ The syntax for the body of a phrase definition is that it's a sequence of
fixed single words, which are not brackets, and bracketed token definitions,
occurring in any quantity and any order. For example:

>> begin the (A - activity on value of kind K) activity with (val - K)

is a sequence of word, word, token, word, word, token.

For implementation convenience, we write a grammar which splits off the next
piece of the definition from the front of the text. In production (e), it's
a single word; in production (b), a token definition; and the others all
give problems for misuse of brackets.

=
<phrase-definition-word-or-token> ::=
	( ) *** |                             ==> @<Issue PM_TokenWithEmptyBrackets@>
	( <phrase-token-declaration> ) *** |  ==> { TRUE, RP[1], <<token-construct>> = R[1] }
	( *** |                               ==> @<Issue PM_TokenWithoutCloseBracket@>
	) *** |                               ==> @<Issue PM_TokenWithoutOpenBracket@>
	### ***                               ==> { FALSE, - }

@<Issue PM_TokenWithEmptyBrackets@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TokenWithEmptyBrackets),
		"nothing is between the opening bracket '(' and its matching close bracket ')'",
		"so I can't see what is meant to be the fixed text and what is meant to be "
		"changeable. The idea is to put brackets around whatever varies from one "
		"usage to another: for instance, 'To contribute (N - a number) dollars: ...'.");
	==> { NOT_APPLICABLE, - };

@<Issue PM_TokenWithoutCloseBracket@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TokenWithoutCloseBracket),
		"the opening bracket '(' has no matching close bracket ')'",
		"so I can't see what is meant to be the fixed text and what is meant to be "
		"changeable. The idea is to put brackets around whatever varies from one "
		"usage to another: for instance, 'To contribute (N - a number) dollars: ...'.");
	==> { NOT_APPLICABLE, - };

@<Issue PM_TokenWithoutOpenBracket@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TokenWithoutOpenBracket),
		"a close bracket ')' appears here with no matching open '('",
		"so I can't see what is meant to be the fixed text and what is meant to be "
		"changeable. The idea is to put brackets around whatever varies from one usage "
		"to another: for instance, 'To contribute (N - a number) dollars: ...'.");
	==> { NOT_APPLICABLE, - };

@ Phrase token declarations allow a variety of non-standard constructs.

Note that nested brackets are allowed in the kind indication after
the hyphen, and this is sorely needed with complicated functional kinds.

=
<phrase-token-declaration> ::=
	*** ( *** - ...... |                                ==> @<Issue PM_TokenWithNestedBrackets@>
	...... - a nonexisting variable |                             ==> @<New local@>
	...... - a nonexisting <k-kind-prototype> variable |          ==> @<New local of kind@>
	...... - a nonexisting <k-kind-prototype> that/which varies | ==> @<New local of kind@>
	...... - nonexisting variable |                               ==> @<New local@>
	...... - nonexisting <k-kind-prototype> variable |            ==> @<New local of kind@>
	...... - nonexisting <k-kind-prototype> that/which varies |   ==> @<New local of kind@>
	...... - {an existing variable} |                             ==> @<Existing local@>
	...... - {an existing <k-kind-prototype> variable} |          ==> @<Existing local of kind@>
	...... - {an existing <k-kind-prototype> that/which varies} | ==> @<Existing local of kind@>
	...... - {existing variable} |                                ==> @<Existing local@>
	...... - {existing <k-kind-prototype> variable} |             ==> @<Existing local of kind@>
	...... - {existing <k-kind-prototype> that/which varies} |    ==> @<Existing local of kind@>
	...... - a condition |                                        ==> { CONDITION_IDTC, NULL }
	...... - condition |                                          ==> { CONDITION_IDTC, NULL }
	...... - a phrase |                                           ==> { VOID_IDTC, NULL }
	...... - phrase |                                             ==> { VOID_IDTC, NULL }
	...... - storage |                                            ==> @<Storage@>
	...... - storage of <k-kind-prototype> |                      ==> @<Storage of kind@>
	...... - a table-reference |                                  ==> @<Table ref@>
	...... - table-reference |                                    ==> @<Table ref@>
	...... - <s-phrase-token-type> |                              ==> { STANDARD_IDTC, RP[1] }
	...... - <s-kind-as-name-token> |                             ==> { KIND_NAME_IDTC, RP[1] }
	...... - ...... |                                             ==> @<Issue PM_BadTypeIndication@>
	<s-kind-as-name-token> |                                      ==> { -KIND_NAME_IDTC, RP[1] }
	......                                                        ==> @<Issue PM_TokenMisunderstood@>

@<New local@> =
	==> { NEW_LOCAL_IDTC, Specifications::from_kind(K_value) }

@<New local of kind@> =
	==> { NEW_LOCAL_IDTC, Specifications::from_kind(RP[1]) }

@<Existing local@> =
	==> { OLD_LOCAL_IDTC, ParsingIDTypeData::match(K_value, GET_RW(<phrase-token-declaration>, 2)) }

@<Existing local of kind@> =
	==> { OLD_LOCAL_IDTC, ParsingIDTypeData::match(RP[1], GET_RW(<phrase-token-declaration>, 2)) }

@<Storage@> =
	==> { STORAGE_IDTC, ParsingIDTypeData::match(K_value, GET_RW(<phrase-token-declaration>, 2)) }

@<Storage of kind@> =
	==> { STORAGE_IDTC, ParsingIDTypeData::match(RP[1], GET_RW(<phrase-token-declaration>, 2)) }

@<Table ref@> =
	==> { TABLE_REF_IDTC, ParsingIDTypeData::match(K_value, GET_RW(<phrase-token-declaration>, 2)) }

@<Issue PM_TokenWithNestedBrackets@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TokenWithNestedBrackets),
		"the name of the token inside the brackets '(' and ')' and before the hyphen '-' "
		"itself contains another open bracket '('",
		"which is not allowed.");
	==> { ERRONEOUS_IDTC, NULL };

@<Issue PM_BadTypeIndication@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, GET_RW(<phrase-token-declaration>, 2));
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_BadTypeIndication));
	Problems::issue_problem_segment(
		"In %1, the text '%2' after the hyphen should tell me what kind of value goes here "
		"(like 'a number', or 'a vehicle'), but it's not something I recognise.");
	Problems::issue_problem_end();
	==> { ERRONEOUS_IDTC, NULL };

@<Issue PM_TokenMisunderstood@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TokenMisunderstood),
		"the brackets '(' and ')' here neither say that something varies but has a given "
		"type, nor specify a called name",
		"so I can't make sense of them. For a 'To...' phrase, brackets like this are used "
		"with a hyphen dividing the name for a varying value and the kind it has: for "
		"instance, 'To contribute (N - a number) dollars: ...'. Rules, on the other hand, "
		"use brackets to give names to things or rooms found when matching conditions: "
		"for instance, 'Instead of opening a container in the presence of a man (called "
		"the box-watcher): ...'");
	==> { ERRONEOUS_IDTC, NULL };

@ This nonterminal simply wraps <k-kind-as-name-token> up as a specification.

=
<s-kind-as-name-token> internal {
	int s = kind_parsing_mode;
	kind_parsing_mode = PHRASE_TOKEN_KIND_PARSING;
	int t = <k-kind-as-name-token>(W);
	kind_parsing_mode = s;
	if (t) {
		==> { TRUE, ParsingIDTypeData::match(<<rp>>, W) };
		return TRUE;
	}
	==> { fail nonterminal };
}

@ =
parse_node *ParsingIDTypeData::match(kind *K, wording W) {
	parse_node *S = Specifications::from_kind(K);
	Node::set_text(S, W);
	return S;
}
