[CGTokens::] Command Grammar Tokens.

CGs are list of CG lines, which are lists of CG tokens.

@

=
typedef struct cg_token {
	struct wording text_of_token;
	int is_literal;
	int slash_class;
	int slash_dash_dash;
	int grammar_token_code;
	struct parse_node *grammar_value; /* 0 or else one of the |*_GTC| values */
	struct binary_predicate *token_relation;
	struct cg_token *next_token;
	CLASS_DEFINITION
} cg_token;

wording CGTokens::text(cg_token *cgt) {
	return cgt?(cgt->text_of_token):(EMPTY_WORDING);
}

@ Tokens with a nonzero |grammar_token_code| correspond closely to what are
also called "tokens" in the runtime command parser.

@d NAMED_TOKEN_GTC 1 /* these positive values are used only in parsing */
@d RELATED_GTC 2
@d STUFF_GTC 3
@d ANY_STUFF_GTC 4
@d ANY_THINGS_GTC 5
@d NOUN_TOKEN_GTC -1        /* I6 |noun| */
@d MULTI_TOKEN_GTC -2       /* I6 |multi| */
@d MULTIINSIDE_TOKEN_GTC -3 /* I6 |multiinside| */
@d MULTIHELD_TOKEN_GTC -4   /* I6 |multiheld| */
@d HELD_TOKEN_GTC -5        /* I6 |held| */
@d CREATURE_TOKEN_GTC -6    /* I6 |creature| */
@d TOPIC_TOKEN_GTC -7       /* I6 |topic| */
@d MULTIEXCEPT_TOKEN_GTC -8 /* I6 |multiexcept| */

=
void CGTokens::log(cg_token *cgt) {
	if (cgt == NULL) LOG("<no-cgt>");
	else {
		LOG("<CGT%d:%W", cgt->allocation_id, cgt->text_of_token);
		if (cgt->slash_class != 0) LOG("/%d", cgt->slash_class);
		if (cgt->slash_dash_dash) LOG("/--");
		switch (cgt->grammar_token_code) {
			case NAMED_TOKEN_GTC:        LOG(" = named token"); break;
			case RELATED_GTC:            LOG(" = related"); break;
			case STUFF_GTC:              LOG(" = stuff"); break;
			case ANY_STUFF_GTC:          LOG(" = any stuff"); break;
			case ANY_THINGS_GTC:         LOG(" = any things"); break;
			case NOUN_TOKEN_GTC:         LOG(" = noun"); break;
			case MULTI_TOKEN_GTC:        LOG(" = multi"); break;
			case MULTIINSIDE_TOKEN_GTC:  LOG(" = multiinside"); break;
			case MULTIHELD_TOKEN_GTC:    LOG(" = multiheld"); break;
			case HELD_TOKEN_GTC:         LOG(" = held"); break;
			case CREATURE_TOKEN_GTC:     LOG(" = creature"); break;
			case TOPIC_TOKEN_GTC:        LOG(" = topic"); break;
			case MULTIEXCEPT_TOKEN_GTC:  LOG(" = multiexcept"); break;
		}
		LOG(">");
	}
}

@ 

|is_literal| is set for literal words such as |"into"|
and clear for square-bracketed tokens such as |"[something]"|.

The |grammar_token_code| annotation is meaningful only for parse nodes
with an evaluation of type |DESCRIPTION|. These are tokens which describe a
range of objects. Examples include "[open container]", which compiles to an
I6 noun filter, "[any container]", which compiles to an I6 scope filter, or
"[things]", one of a small number of special cases compiling to primitive I6
parser tokens. The annotation holds the allocation ID for the noun/scope
filter structure built for the occasion in the former cases, and one of the
following constants in the latter case. (These must all have negative values
in order not to clash with allocation IDs 0, 1, 2, ..., and clearly must all
be different, but otherwise the values are not significant and there is no
preferred order.)

For tokens with any other evaluation, |general_purpose| is always 0, so
that the special values below cannot arise.

@ Tokens are created when text such as "drill [something] with [something]"
is parsed, from an Understand sentence or elsewhere. What happens is much
the same as when text with substitutions is read: that produces

>> "drill", something, "with", something

and the following little grammar is used to divide this text up into its
four constituent tokens.

=
<grammar-token-breaking> ::=
	... , ... |    ==> { NOT_APPLICABLE, - }
	<quoted-text> |    ==> { TRUE, - }
	...						==> { FALSE, - }

@ We use a different punctuation set, in which forward slashes break words,
to handle such as:

>> Understand "get away/off/out" as exiting.

Inform would ordinarily lex the text away/off/out as one single word -- so that
something like "on/off switch" would be regarded as two words not four --
but with slash treated as a punctuation mark, we instead read "away / off /
out", a sequence of five lexical words.

@d GRAMMAR_PUNCTUATION_MARKS L".,:;?!(){}[]/" /* note the slash... */

=
cg_token *CGTokens::break_into_tokens(cg_token *from, wording W) {
	<grammar-token-breaking>(W);
	switch (<<r>>) {
		case NOT_APPLICABLE: {
			wording LW = GET_RW(<grammar-token-breaking>, 1);
			wording RW = GET_RW(<grammar-token-breaking>, 2);
			from = CGTokens::break_into_tokens(from, LW);
			from = CGTokens::break_into_tokens(from, RW);
			break;
		}
		case TRUE:
			Word::dequote(Wordings::first_wn(W));
			if (*(Lexer::word_text(Wordings::first_wn(W))) == 0) return from;
			W = Feeds::feed_C_string_full(Lexer::word_text(Wordings::first_wn(W)), FALSE, GRAMMAR_PUNCTUATION_MARKS);
			LOOP_THROUGH_WORDING(i, W) {
				cg_token *cgt = CGTokens::cgt_of(Wordings::one_word(i), TRUE);
				from = CGTokens::graft(cgt, from);
			}
			break;
		case FALSE: {
			cg_token *cgt = CGTokens::cgt_of(W, FALSE);
			from = CGTokens::graft(cgt, from);
			break;
		}
	}
	return from;
}

cg_token *CGTokens::cgt_of(wording W, int lit) {
	cg_token *cgt = CREATE(cg_token);
	cgt->text_of_token = W;
	cgt->is_literal = lit;
	cgt->slash_dash_dash = FALSE;
	cgt->slash_class = 0;
	cgt->grammar_value = NULL;
	cgt->grammar_token_code = 0;
	cgt->token_relation = NULL;
	cgt->next_token = NULL;
	return cgt;
}

cg_token *CGTokens::graft(cg_token *cgt, cg_token *list) {
	if (list == NULL) return cgt;
	if (cgt == NULL) return list;
	cg_token *x = list;
	while (x->next_token) x = x->next_token;
	x->next_token = cgt;
	return list;
}

int CGTokens::is_literal(cg_token *cgt) {
	return (cgt)?(cgt->is_literal):FALSE;
}

@h Multiple tokens.
A multiple token is one which permits multiple matches in the I6 parser: for
instance, permits the use of "all".

=
int CGTokens::is_multiple(cg_token *cgt) {
	switch (cgt->grammar_token_code) {
		case MULTI_TOKEN_GTC:
		case MULTIINSIDE_TOKEN_GTC:
		case MULTIHELD_TOKEN_GTC:
		case MULTIEXCEPT_TOKEN_GTC:
			return TRUE;
	}
	return FALSE;
}

@h The special tokens.
Do not change any of these GTC numbers without first checking and updating
the discussion of CGL sorting in //Command Grammar Lines//:

=
int CGTokens::gsb_for_special_token(int gtc) {
	switch(gtc) {
        case NOUN_TOKEN_GTC: return 0;
        case MULTI_TOKEN_GTC: return 0;
        case MULTIINSIDE_TOKEN_GTC: return 1;
        case MULTIHELD_TOKEN_GTC: return 2;
        case HELD_TOKEN_GTC: return 3;
        case CREATURE_TOKEN_GTC: return 0;
        case TOPIC_TOKEN_GTC: return -1;
        case MULTIEXCEPT_TOKEN_GTC: return 2;
		default: internal_error("tried to find GSB for invalid GTC");
	}
	return 0; /* to prevent a gcc error: never reached */
}

@ These translate into I6 as follows:

=
char *CGTokens::i6_token_for_special_token(int gtc) {
	switch(gtc) {
		case NOUN_TOKEN_GTC: return "noun";
		case MULTI_TOKEN_GTC: return "multi";
		case MULTIINSIDE_TOKEN_GTC: return "multiinside";
		case MULTIHELD_TOKEN_GTC: return "multiheld";
		case HELD_TOKEN_GTC: return "held";
		case CREATURE_TOKEN_GTC: return "creature";
		case TOPIC_TOKEN_GTC: return "topic";
		case MULTIEXCEPT_TOKEN_GTC: return "multiexcept";
		default: internal_error("tried to find I6 token for invalid GTC");
	}
	return ""; /* to prevent a gcc error: never reached */
}

inter_name *CGTokens::iname_for_special_token(int gtc) {
	switch(gtc) {
		case NOUN_TOKEN_GTC: return VERB_DIRECTIVE_NOUN_iname;
		case MULTI_TOKEN_GTC: return VERB_DIRECTIVE_MULTI_iname;
		case MULTIINSIDE_TOKEN_GTC: return VERB_DIRECTIVE_MULTIINSIDE_iname;
		case MULTIHELD_TOKEN_GTC: return VERB_DIRECTIVE_MULTIHELD_iname;
		case HELD_TOKEN_GTC: return VERB_DIRECTIVE_HELD_iname;
		case CREATURE_TOKEN_GTC: return VERB_DIRECTIVE_CREATURE_iname;
		case TOPIC_TOKEN_GTC: return VERB_DIRECTIVE_TOPIC_iname;
		case MULTIEXCEPT_TOKEN_GTC: return VERB_DIRECTIVE_MULTIEXCEPT_iname;
		default: internal_error("tried to find inter name for invalid GTC");
	}
	return NULL; /* to prevent a gcc error: never reached */
}

char *CGTokens::i6_constant_for_special_token(int gtc) {
	switch(gtc) {
		case NOUN_TOKEN_GTC: return "NOUN_TOKEN";
		case MULTI_TOKEN_GTC: return "MULTI_TOKEN";
		case MULTIINSIDE_TOKEN_GTC: return "MULTIINSIDE_TOKEN";
		case MULTIHELD_TOKEN_GTC: return "MULTIHELD_TOKEN";
		case HELD_TOKEN_GTC: return "HELD_TOKEN";
		case CREATURE_TOKEN_GTC: return "CREATURE_TOKEN";
		case TOPIC_TOKEN_GTC: return "TOPIC_TOKEN";
		case MULTIEXCEPT_TOKEN_GTC: return "MULTIEXCEPT_TOKEN";
		default: internal_error("tried to find I6 constant for invalid GTC");
	}
	return ""; /* to prevent a gcc error: never reached */
}

@ The special tokens all return a value in I6 which needs a kind
to be used in I7: these are defined by the following routine.

=
kind *CGTokens::kind_for_special_token(int gtc) {
	if ((K_understanding) && (gtc == TOPIC_TOKEN_GTC)) return K_understanding;
	return K_object;
}

@ The tokens which aren't literal words in double-quotes are parsed as follows:

=
<grammar-token> ::=
	<named-grammar-token> |                          ==> { NAMED_TOKEN_GTC, -, <<command_grammar:named>> = RP[1] }
	any things |                                     ==> { ANY_THINGS_GTC, -, <<parse_node:s>> = Specifications::from_kind(K_thing) }
	any <s-description> |                            ==> { ANY_STUFF_GTC, -, <<parse_node:s>> = RP[1] }
	anything |                                       ==> { ANY_STUFF_GTC, -, <<parse_node:s>> = Specifications::from_kind(K_thing) }
	anybody |                                        ==> { ANY_STUFF_GTC, -, <<parse_node:s>> = Specifications::from_kind(K_person) }
	anyone |                                         ==> { ANY_STUFF_GTC, -, <<parse_node:s>> = Specifications::from_kind(K_person) }
	anywhere |                                       ==> { ANY_STUFF_GTC, -, <<parse_node:s>> = Specifications::from_kind(K_room) }
	something related by reversed <relation-name> |  ==> { RELATED_GTC, BinaryPredicates::get_reversal(RP[1]) }
	something related by <relation-name> |           ==> { RELATED_GTC, RP[1] }
	something related by ... |                       ==> @<Issue PM_GrammarBadRelation problem@>
	<standard-grammar-token> |                       ==> { R[1], NULL }
	<definite-article> <k-kind> |                    ==> { STUFF_GTC, -, <<parse_node:s>> = Specifications::from_kind(RP[2]) }
	<s-description> |                                ==> { STUFF_GTC, -, <<parse_node:s>> = RP[1] }
	<s-type-expression>	|                            ==> @<Issue PM_BizarreToken problem@>
	...                                              ==> @<Issue PM_UnknownToken problem@>

<standard-grammar-token> ::=
	something |                                      ==> { NOUN_TOKEN_GTC, - }
	things |                                         ==> { MULTI_TOKEN_GTC, - }
	things inside |                                  ==> { MULTIINSIDE_TOKEN_GTC, - }
	things preferably held |                         ==> { MULTIHELD_TOKEN_GTC, - }
	something preferably held |                      ==> { HELD_TOKEN_GTC, - }
	other things |                                   ==> { MULTIEXCEPT_TOKEN_GTC, - }
	someone	|                                        ==> { CREATURE_TOKEN_GTC, - }
	somebody |                                       ==> { CREATURE_TOKEN_GTC, - }
	text |                                           ==> { TOPIC_TOKEN_GTC, - }
	topic |                                          ==> @<Issue PM_UseTextNotTopic problem@>
	a topic |                                        ==> @<Issue PM_UseTextNotTopic problem@>
	object |                                         ==> @<Issue PM_UseThingNotObject problem@>
	an object |                                      ==> @<Issue PM_UseThingNotObject problem@>
	something held |                                 ==> @<Issue something held problem message@>
	things held                                      ==> @<Issue things held problem message@>

<named-grammar-token> internal {
	command_grammar *cg = CommandGrammars::named_token_by_name(W);
	if (cg) {
		==> { -, cg };
		return TRUE;
	}
	==> { fail nonterminal };
}

@<Issue PM_GrammarBadRelation problem@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, W);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_GrammarBadRelation));
	Problems::issue_problem_segment(
		"The grammar token '%2' in the sentence %1 "
		"invites me to understand names of related things, "
		"but the relation is not one that I know.");
	Problems::issue_problem_end();
	==> { RELATED_GTC, NULL };

@<Issue PM_UseTextNotTopic problem@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, W);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_UseTextNotTopic));
	Problems::issue_problem_segment(
		"The grammar token '%2' in the sentence %1 would in some "
		"ways be the right logical way to suggest 'any words at "
		"all here', but Inform in actually uses the special syntax "
		"'[text]' for that. %P"
		"This is partly for historical reasons, but also because "
		"'[text]' is a token which can't be used in every sort of "
		"Understand grammar - for example, it can't be used with 'matches' "
		"or in descriptions of actions or in table columns; it's really "
		"intended only for defining new commands.");
	Problems::issue_problem_end();
	==> { TOPIC_TOKEN_GTC, NULL };

@<Issue PM_UseThingNotObject problem@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, W);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_UseThingNotObject));
	Problems::issue_problem_segment(
		"The grammar token '%2' in the sentence %1 would in some "
		"ways be the right logical way to suggest 'any object at "
		"all here', but Inform uses the special syntax '[thing]' "
		"for that. (Or '[things]' if multiple objects are allowed.)");
	Problems::issue_problem_end();
	==> { MULTI_TOKEN_GTC, NULL };

@<Issue something held problem message@> =
	CGTokens::incompatible_change_problem(
		"something held", "something", "something preferably held");
	==> { HELD_TOKEN_GTC, NULL };

@<Issue things held problem message@> =
	CGTokens::incompatible_change_problem(
			"things held", "things", "things preferably held");
	==> { MULTIHELD_TOKEN_GTC, NULL };

@ Something of an extended mea culpa: but it had the desired effect, in
that nobody complained about what might have been a controversial change.

=
void CGTokens::incompatible_change_problem(char *token_tried, char *token_instead,
	char *token_better) {
	Problems::quote_source(1, current_sentence);
	Problems::quote_text(2, token_tried);
	Problems::quote_text(3, token_instead);
	Problems::quote_text(4, token_better);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ObsoleteHeldTokens));
	Problems::issue_problem_segment(
		"In the sentence %1, you used the '[%2]' as a token, which was "
		"allowed in the early Public Beta versions of Inform 7, but became "
		"out of date in August 2006.%L A change was then made so that if an "
		"action needed to apply to something which was carried, this would "
		"now be specified when the action is created - not in the Understand "
		"line for it. For instance, one might say 'Dismantling is an action "
		"which applies to one carried thing', instead of '...which applies "
		"to one thing', and then write grammar such as 'Understand \"dismantle "
		"[something] as dismantling' instead of '...[something held]...'. "
		"So you probably need to change your '[%2]' token to '[%3]', and "
		"change the action's definition (unless it is a built-in action "
		"such as 'dropping'). An alternative, though, for fine-tuning is to "
		"change it to '[%4]', which allows anything to be Understood, but "
		"in cases of ambiguity tends to guess that something held is more "
		"likely to be what the player means than something not held.");
	Problems::issue_problem_end();
}

@<Issue PM_BizarreToken problem@> =
	LOG("$T", current_sentence);
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, W);
	Problems::quote_kind_of(3, RP[1]);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_BizarreToken));
	Problems::issue_problem_segment(
		"The grammar token '%2' in the sentence %1 looked to me as "
		"if it might be %3, but this isn't something allowed in "
		"parsing grammar.");
	Problems::issue_problem_end();
	==> { STUFF_GTC, - };

@<Issue PM_UnknownToken problem@> =
	LOG("$T", current_sentence);
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, W);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_UnknownToken));
	Problems::issue_problem_segment(
		"I was unable to understand what you meant by the grammar token '%2' "
		"in the sentence %1.");
	Problems::issue_problem_end();
	==> { STUFF_GTC, - };

@h Determining.


=
parse_node *CGTokens::determine(cg_token *cgt, int depth, int *score) {
	if (CGTokens::is_literal(cgt)) return NULL;

	<<command_grammar:named>> = NULL;
	parse_node *spec = NULL;
	<grammar-token>(CGTokens::text(cgt));
	switch (<<r>>) {
		case NAMED_TOKEN_GTC: @<Determine a named grammar token@>; break;
		case ANY_STUFF_GTC: @<Determine an any grammar token@>; break;
		case ANY_THINGS_GTC: @<Determine an any grammar token@>; break;
		case RELATED_GTC: @<Determine a related grammar token@>; break;
		case STUFF_GTC: @<Determine a kind grammar token@>; break;
		default: @<Determine a special grammar token@>; break;
	}
	if (spec) @<Vet the grammar token determination for parseability at run-time@>;
	return spec;
}

@<Determine a named grammar token@> =
	parse_node *val = ParsingPlugin::rvalue_from_command_grammar(<<command_grammar:named>>);
	spec = CommandGrammars::determine(<<command_grammar:named>>, depth+1);
	cgt->grammar_value = val;

@<Determine an any grammar token@> =
	spec = <<parse_node:s>>;
	if (Specifications::is_description(spec)) {
		int any_things = FALSE;
		if (<<r>> == ANY_THINGS_GTC) any_things = TRUE;
		cgt->grammar_token_code = UnderstandFilterTokens::new_id(spec, TRUE, any_things);
		cgt->grammar_value = spec;
	}

@<Determine a related grammar token@> =
	binary_predicate *bp = <<rp>>;
	if (bp) cgt->token_relation = bp;

@<Determine a kind grammar token@> =
	spec = <<parse_node:s>>;
	cgt->grammar_value = spec;
	if (Specifications::is_description_like(spec)) {
		*score = 5;
		cgt->grammar_token_code = UnderstandFilterTokens::new_id(spec, FALSE, FALSE);
	}

@<Determine a special grammar token@> =
	int p = <<r>>;
	kind *K = CGTokens::kind_for_special_token(p);
	spec = Specifications::from_kind(K);
	Node::set_text(spec, CGTokens::text(cgt));
	*score = CGTokens::gsb_for_special_token(p);
	cgt->grammar_value = spec;
	cgt->grammar_token_code = p;

@<Vet the grammar token determination for parseability at run-time@> =
	if (Specifications::is_description(spec)) {
		kind *K = Specifications::to_kind(spec);
		if ((K_understanding) &&
			(Kinds::Behaviour::is_object(K) == FALSE) &&
			(Kinds::eq(K, K_understanding) == FALSE) &&
			(Kinds::Behaviour::request_I6_GPR(K) == FALSE)) {
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, CGTokens::text(cgt));
			StandardProblems::handmade_problem(Task::syntax_tree(),
				_p_(PM_UnparsableKind));
			Problems::issue_problem_segment(
				"The grammar token '%2' in the sentence %1 "
				"invites me to understand values typed by the player during "
				"play but for a kind of value which is beyond my ability. "
				"Generally speaking, the allowable kinds of value are "
				"number, time, text and any new kind of value you may "
				"have created - but not, for instance, scene or rule.");
			Problems::issue_problem_end();
			spec = NULL;
		}
	}
