[PL::Parsing::Tokens::] Grammar Tokens.

To handle grammar at the level of individual tokens. I7 grammar
tokens correspond in a 1-to-1 way with I6 tokens: here we determine the I7
type a token represents (if any) and compile it to its I6 grammar token
equivalent as needed.

@h Definitions.

@ I7 tokens are (at present) stored simply as parse tree nodes of type
|TOKEN_NT|, with meaningful information hidden in annotations. At one
time I thought this was a simple arrangement, but it now seems obfuscatory,
so at some point I plan to create a "grammar token" structure to avoid
these arcane annotations of the parse tree.

|grammar_token_nonliteral_ANNOT| is clear for literal words such as |"into"|
and set for square-bracketed tokens such as |"[something]"|.

|index| stores the GSB scoring contribution made by the token to the
GL sorting algorithm.

The |grammar_token_code_ANNOT| annotation is meaningful only for parse nodes
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

@d NAMED_TOKEN_GTC 1 /* these positive values are used only in parsing */
@d RELATED_GTC 2
@d STUFF_GTC 3
@d ANY_STUFF_GTC 4
@d ANY_THINGS_GTC 5
@d NOUN_TOKEN_GTC -1 /* I6 |noun| */
@d MULTI_TOKEN_GTC -2 /* I6 |multi| */
@d MULTIINSIDE_TOKEN_GTC -3 /* I6 |multiinside| */
@d MULTIHELD_TOKEN_GTC -4 /* I6 |multiheld| */
@d HELD_TOKEN_GTC -5 /* I6 |held| */
@d CREATURE_TOKEN_GTC -6 /* I6 |creature| */
@d TOPIC_TOKEN_GTC -7 /* I6 |topic| */
@d MULTIEXCEPT_TOKEN_GTC -8 /* I6 |multiexcept| */

@ Tokens are created when text such as "drill [something] with [something]"
is parsed, from an Understand sentence or elsewhere. What happens is much
the same as when text with substitutions is read: that produces

>> "drill", something, "with", something

and the following little grammar is used to divide this text up into its
four constituent tokens.

=
<grammar-token-breaking> ::=
	... , ... |				==> NOT_APPLICABLE
	<quoted-text> |			==> TRUE
	...						==> FALSE

@ We use a different punctuation set, in which forward slashes break words,
to handle such as:

>> Understand "get away/off/out" as exiting.

Inform would ordinarily lex the text away/off/out as one single word -- so that
something like "on/off switch" would be regarded as two words not four --
but with slash treated as a punctuation mark, we instead read "away / off /
out", a sequence of five lexical words.

@d GRAMMAR_PUNCTUATION_MARKS L".,:;?!(){}[]/" /* note the slash... */

=
void PL::Parsing::Tokens::break_into_tokens(parse_node *pn, wording W) {
	<grammar-token-breaking>(W);
	switch (<<r>>) {
		case NOT_APPLICABLE: {
			wording LW = GET_RW(<grammar-token-breaking>, 1);
			wording RW = GET_RW(<grammar-token-breaking>, 2);
			PL::Parsing::Tokens::break_into_tokens(pn, LW);
			PL::Parsing::Tokens::break_into_tokens(pn, RW);
			break;
		}
		case TRUE:
			Word::dequote(Wordings::first_wn(W));
			if (*(Lexer::word_text(Wordings::first_wn(W))) == 0) return;
			W = Feeds::feed_text_full(Lexer::word_text(Wordings::first_wn(W)), FALSE, GRAMMAR_PUNCTUATION_MARKS);
			LOOP_THROUGH_WORDING(i, W) {
				parse_node *newpn = NounPhrases::new_raw(Wordings::one_word(i));
				ParseTree::set_type(newpn, TOKEN_NT);
				ParseTree::annotate_int(newpn, grammar_token_literal_ANNOT, TRUE);
				ParseTree::graft(newpn, pn);
			}
			break;
		case FALSE: {
			parse_node *newpn = NounPhrases::new_raw(W);
			ParseTree::set_type(newpn, TOKEN_NT);
			ParseTree::annotate_int(newpn, grammar_token_literal_ANNOT, FALSE);
			ParseTree::graft(newpn, pn);
			break;
		}
	}
}

int PL::Parsing::Tokens::is_literal(parse_node *pn) {
	return ParseTree::int_annotation(pn, grammar_token_literal_ANNOT);
}

@h Multiple tokens.
A multiple token is one which permits multiple matches in the I6 parser: for
instance, permits the use of "all".

=
int PL::Parsing::Tokens::is_multiple(parse_node *pn) {
	switch (ParseTree::int_annotation(pn, grammar_token_code_ANNOT)) {
		case MULTI_TOKEN_GTC:
		case MULTIINSIDE_TOKEN_GTC:
		case MULTIHELD_TOKEN_GTC:
		case MULTIEXCEPT_TOKEN_GTC:
			return TRUE;
	}
	return FALSE;
}

@h Text.

=
int PL::Parsing::Tokens::is_text(parse_node *pn) {
	switch (ParseTree::int_annotation(pn, grammar_token_code_ANNOT)) {
		case TOPIC_TOKEN_GTC:
			return TRUE;
	}
	return FALSE;
}

@h The special tokens.
Do not change any of these GTC numbers without first checking and updating
the discussion of GL sorting in Grammar Lines:

=
int PL::Parsing::Tokens::gsb_for_special_token(int gtc) {
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
char *PL::Parsing::Tokens::i6_token_for_special_token(int gtc) {
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

inter_name *PL::Parsing::Tokens::iname_for_special_token(int gtc) {
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

char *PL::Parsing::Tokens::i6_constant_for_special_token(int gtc) {
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
kind *PL::Parsing::Tokens::kind_for_special_token(int gtc) {
	if (gtc == TOPIC_TOKEN_GTC) return K_understanding;
	return K_object;
}

@ The tokens which aren't literal words in double-quotes are parsed as follows:

=
<grammar-token> ::=
	<named-grammar-token> |				==> NAMED_TOKEN_GTC; <<grammar_verb:named>> = RP[1]
	any things |						==> ANY_THINGS_GTC; <<parse_node:s>> = Specifications::from_kind(K_thing);
	any <s-description> |				==> ANY_STUFF_GTC; <<parse_node:s>> = RP[1]
	anything |							==> ANY_STUFF_GTC; <<parse_node:s>> = Specifications::from_kind(K_thing);
	anybody |							==> ANY_STUFF_GTC; <<parse_node:s>> = Specifications::from_kind(K_person);
	anyone |							==> ANY_STUFF_GTC; <<parse_node:s>> = Specifications::from_kind(K_person);
	anywhere |							==> ANY_STUFF_GTC; <<parse_node:s>> = Specifications::from_kind(K_room);
	something related by reversed <relation-name> |	==> RELATED_GTC; *XP = BinaryPredicates::get_reversal(RP[1])
	something related by <relation-name> |			==> RELATED_GTC; *XP = RP[1]
	something related by ... |			==> @<Issue PM_GrammarBadRelation problem@>
	<standard-grammar-token> |			==> R[1]
	<definite-article> <k-kind> |		==> STUFF_GTC; <<parse_node:s>> = Specifications::from_kind(RP[2])
	<s-description> |					==> STUFF_GTC; <<parse_node:s>> = RP[1]
	<s-type-expression>	|				==> @<Issue PM_BizarreToken problem@>
	...									==> @<Issue PM_UnknownToken problem@>

<standard-grammar-token> ::=
	something |							==> NOUN_TOKEN_GTC
	things |							==> MULTI_TOKEN_GTC
	things inside |						==> MULTIINSIDE_TOKEN_GTC
	things preferably held |			==> MULTIHELD_TOKEN_GTC
	something preferably held |			==> HELD_TOKEN_GTC
	other things |						==> MULTIEXCEPT_TOKEN_GTC
	someone	|							==> CREATURE_TOKEN_GTC
	somebody |							==> CREATURE_TOKEN_GTC
	text |								==> TOPIC_TOKEN_GTC
	topic |								==> @<Issue PM_UseTextNotTopic problem@>
	a topic |							==> @<Issue PM_UseTextNotTopic problem@>
	object |							==> @<Issue PM_UseThingNotObject problem@>
	an object |							==> @<Issue PM_UseThingNotObject problem@>
	something held |					==> @<Issue something held problem message@>
	things held							==> @<Issue things held problem message@>

<named-grammar-token> internal {
	grammar_verb *gv = PL::Parsing::Verbs::named_token_by_name(W);
	if (gv) { *XP = gv; return TRUE; }
	return FALSE;
}

@<Issue PM_GrammarBadRelation problem@> =
	*X = RELATED_GTC; *XP = NULL;
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, W);
	Problems::Issue::handmade_problem(_p_(PM_GrammarBadRelation));
	Problems::issue_problem_segment(
		"The grammar token '%2' in the sentence %1 "
		"invites me to understand names of related things, "
		"but the relation is not one that I know.");
	Problems::issue_problem_end();

@<Issue PM_UseTextNotTopic problem@> =
	*X = TOPIC_TOKEN_GTC;
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, W);
	Problems::Issue::handmade_problem(_p_(PM_UseTextNotTopic));
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

@<Issue PM_UseThingNotObject problem@> =
	*X = MULTI_TOKEN_GTC;
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, W);
	Problems::Issue::handmade_problem(_p_(PM_UseThingNotObject));
	Problems::issue_problem_segment(
		"The grammar token '%2' in the sentence %1 would in some "
		"ways be the right logical way to suggest 'any object at "
		"all here', but Inform uses the special syntax '[thing]' "
		"for that. (Or '[things]' if multiple objects are allowed.)");
	Problems::issue_problem_end();

@<Issue something held problem message@> =
	*X = HELD_TOKEN_GTC;
	PL::Parsing::Tokens::incompatible_change_problem(
		"something held", "something", "something preferably held");

@<Issue things held problem message@> =
	*X = MULTIHELD_TOKEN_GTC;
	PL::Parsing::Tokens::incompatible_change_problem(
			"things held", "things", "things preferably held");

@ Something of an extended mea culpa: but it had the desired effect, in
that nobody complained about what might have been a controversial change.

=
void PL::Parsing::Tokens::incompatible_change_problem(char *token_tried, char *token_instead,
	char *token_better) {
	Problems::quote_source(1, current_sentence);
	Problems::quote_text(2, token_tried);
	Problems::quote_text(3, token_instead);
	Problems::quote_text(4, token_better);
	Problems::Issue::handmade_problem(_p_(PM_ObsoleteHeldTokens));
	Problems::issue_problem_segment(
		"In the sentence %1, you used the '[%2]' as a token, which was "
		"allowed in the early Public Beta versions of Inform 7, but became "
		"out of date in August 2006%|. A change was then made so that if an "
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
	*X = STUFF_GTC;
	LOG("$T", current_sentence);
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, W);
	Problems::quote_kind_of(3, RP[1]);
	Problems::Issue::handmade_problem(_p_(PM_BizarreToken));
	Problems::issue_problem_segment(
		"The grammar token '%2' in the sentence %1 looked to me as "
		"if it might be %3, but this isn't something allowed in "
		"parsing grammar.");
	Problems::issue_problem_end();

@<Issue PM_UnknownToken problem@> =
	*X = STUFF_GTC;
	LOG("$T", current_sentence);
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, W);
	Problems::Issue::handmade_problem(_p_(PM_UnknownToken));
	Problems::issue_problem_segment(
		"I was unable to understand what you meant by the grammar token '%2' "
		"in the sentence %1.");
	Problems::issue_problem_end();

@h Phase II: Determining Grammar.
Slashing does not recurse down to individual tokens, so the first time we
look seriously at tokens is in Phase II.

=
parse_node *PL::Parsing::Tokens::determine(parse_node *pn, int depth, int *score) {
	parse_node *spec = NULL;
	if (ParseTree::int_annotation(pn, grammar_token_literal_ANNOT)) return NULL;

	<<grammar_verb:named>> = NULL;
	<grammar-token>(ParseTree::get_text(pn));
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
	parse_node *val = Rvalues::from_grammar_verb(<<grammar_verb:named>>);
	spec = PL::Parsing::Verbs::determine(<<grammar_verb:named>>, depth+1); /* this is where Phase II recurses */
	ParseTree::set_grammar_value(pn, val);

@<Determine an any grammar token@> =
	spec = <<parse_node:s>>;
	if (Specifications::is_description(spec)) {
		int any_things = FALSE;
		if (<<r>> == ANY_THINGS_GTC) any_things = TRUE;
		ParseTree::annotate_int(pn, grammar_token_code_ANNOT,
			PL::Parsing::Tokens::Filters::new_id(spec, TRUE, any_things));
		ParseTree::set_grammar_value(pn, spec);
	}

@<Determine a related grammar token@> =
	binary_predicate *bp = <<rp>>;
	if (bp) ParseTree::set_grammar_token_relation(pn, bp);

@<Determine a kind grammar token@> =
	spec = <<parse_node:s>>;
	ParseTree::set_grammar_value(pn, spec);
	if (Specifications::is_description_like(spec)) {
		*score = 5;
		ParseTree::annotate_int(pn, grammar_token_code_ANNOT,
			PL::Parsing::Tokens::Filters::new_id(spec, FALSE, FALSE));
	}

@<Determine a special grammar token@> =
	int p = <<r>>;
	kind *K = PL::Parsing::Tokens::kind_for_special_token(p);
	spec = Specifications::from_kind(K);
	ParseTree::set_text(spec, ParseTree::get_text(pn));
	*score = PL::Parsing::Tokens::gsb_for_special_token(p);
	ParseTree::set_grammar_value(pn, spec);
	ParseTree::annotate_int(pn, grammar_token_code_ANNOT, p);

@<Vet the grammar token determination for parseability at run-time@> =
	if (Specifications::is_description(spec)) {
		kind *K = Specifications::to_kind(spec);
		if ((Kinds::Compare::le(K, K_object) == FALSE) &&
			(Kinds::Compare::eq(K, K_understanding) == FALSE) &&
			(Kinds::Behaviour::request_I6_GPR(K) == FALSE)) {
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, ParseTree::get_text(pn));
			Problems::Issue::handmade_problem(_p_(PM_UnparsableKind));
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

@h Phase IV: Compiling Grammar.
Tokens play no direct part in Phase III either, having made their contribution
earlier by recording their GSB scores instead. So we next see them at
compilation time.

In code mode, we compile a test that the token matches, jumping to the
failure label if it doesn't, and setting the I6 local variable |rv| to a
suitable GPR return value if it does match and produces an outcome.
We are allowed to use the I6 local |w| for temporary storage, but
nothing else.

=
int ol_loop_counter = 0;
kind *PL::Parsing::Tokens::compile(gpr_kit *gprk, parse_node *pn, int code_mode,
	inter_symbol *failure_label, int consult_mode) {
	int wn = Wordings::first_wn(ParseTree::get_text(pn));
	parse_node *spec;
	binary_predicate *bp;
	grammar_verb *gv;

	if (ParseTree::int_annotation(pn, grammar_token_literal_ANNOT)) {
		if (code_mode) {
			Produce::inv_primitive(Produce::opcode(IF_BIP));
			Produce::down();
				Produce::inv_primitive(Produce::opcode(NE_BIP));
				Produce::down();
					Produce::inv_call_iname(Hierarchy::find(NEXTWORDSTOPPED_HL));
					TEMPORARY_TEXT(N);
					WRITE_TO(N, "%N", wn);
					Produce::val_dword(N);
					DISCARD_TEXT(N);
				Produce::up();
				@<Then jump to our doom@>;
			Produce::up();
		} else {
			TEMPORARY_TEXT(WT);
			WRITE_TO(WT, "%N", wn);
			Emit::array_dword_entry(WT);
			DISCARD_TEXT(WT);
		}
		return NULL;
	}

	bp = ParseTree::get_grammar_token_relation(pn);
	if (bp) {
		Produce::inv_call_iname(Hierarchy::find(ARTICLEDESCRIPTORS_HL));
		Produce::inv_primitive(Produce::opcode(STORE_BIP));
		Produce::down();
			Produce::ref_symbol(K_value, gprk->w_s);
			Produce::val_iname(K_value, Hierarchy::find(WN_HL));
		Produce::up();
		if (bp == R_containment) {
			Produce::inv_primitive(Produce::opcode(IF_BIP));
			Produce::down();
				Produce::inv_primitive(Produce::opcode(NOT_BIP));
				Produce::down();
					Produce::inv_primitive(Produce::opcode(HAS_BIP));
					Produce::down();
						Produce::val_iname(K_value, Hierarchy::find(SELF_HL));
						Produce::val_iname(K_value, Hierarchy::find(CONTAINER_HL));
					Produce::up();
				Produce::up();
				@<Then jump to our doom@>;
			Produce::up();
		}
		if (bp == R_support) {
			Produce::inv_primitive(Produce::opcode(IF_BIP));
			Produce::down();
				Produce::inv_primitive(Produce::opcode(NOT_BIP));
				Produce::down();
					Produce::inv_primitive(Produce::opcode(HAS_BIP));
					Produce::down();
						Produce::val_iname(K_value, Hierarchy::find(SELF_HL));
						Produce::val_iname(K_value, Hierarchy::find(SUPPORTER_HL));
					Produce::up();
				Produce::up();
				@<Then jump to our doom@>;
			Produce::up();
		}
		if ((bp == a_has_b_predicate) || (bp == R_wearing) ||
			(bp == R_carrying)) {
			Produce::inv_primitive(Produce::opcode(IF_BIP));
			Produce::down();
				Produce::inv_primitive(Produce::opcode(NOT_BIP));
				Produce::down();
					Produce::inv_primitive(Produce::opcode(HAS_BIP));
					Produce::down();
						Produce::val_iname(K_value, Hierarchy::find(SELF_HL));
						Produce::val_iname(K_value, Hierarchy::find(ANIMATE_HL));
					Produce::up();
				Produce::up();
				@<Then jump to our doom@>;
			Produce::up();
		}
		if ((bp == R_containment) ||
			(bp == R_support) ||
			(bp == a_has_b_predicate) ||
			(bp == R_wearing) ||
			(bp == R_carrying)) {
			TEMPORARY_TEXT(L);
			WRITE_TO(L, ".ol_mm_%d", ol_loop_counter++);
			inter_symbol *exit_label = Produce::reserve_label(L);
			DISCARD_TEXT(L);

			Produce::inv_primitive(Produce::opcode(OBJECTLOOP_BIP));
			Produce::down();
				Produce::ref_symbol(K_value, gprk->rv_s);
				Produce::val_iname(K_value, Kinds::RunTime::I6_classname(K_object));
				Produce::inv_primitive(Produce::opcode(IN_BIP));
				Produce::down();
					Produce::val_symbol(K_value, gprk->rv_s);
					Produce::val_iname(K_value, Hierarchy::find(SELF_HL));
				Produce::up();
				Produce::code();
				Produce::down();
					if (bp == R_carrying) {
						Produce::inv_primitive(Produce::opcode(IF_BIP));
						Produce::down();
							Produce::inv_primitive(Produce::opcode(HAS_BIP));
							Produce::down();
								Produce::val_symbol(K_value, gprk->rv_s);
								Produce::val_iname(K_value, Properties::iname(P_worn));
							Produce::up();
							Produce::code();
							Produce::down();
								Produce::inv_primitive(Produce::opcode(CONTINUE_BIP));
							Produce::up();
						Produce::up();
					}
					if (bp == R_wearing) {
						Produce::inv_primitive(Produce::opcode(IF_BIP));
						Produce::down();
							Produce::inv_primitive(Produce::opcode(NOT_BIP));
							Produce::down();
								Produce::inv_primitive(Produce::opcode(HAS_BIP));
								Produce::down();
									Produce::val_symbol(K_value, gprk->rv_s);
									Produce::val_iname(K_value, Properties::iname(P_worn));
								Produce::up();
							Produce::up();
							Produce::code();
							Produce::down();
								Produce::inv_primitive(Produce::opcode(CONTINUE_BIP));
							Produce::up();
						Produce::up();
					}
					Produce::inv_primitive(Produce::opcode(STORE_BIP));
					Produce::down();
						Produce::ref_iname(K_value, Hierarchy::find(WN_HL));
						Produce::val_symbol(K_value, gprk->w_s);
					Produce::up();
					Produce::inv_primitive(Produce::opcode(STORE_BIP));
					Produce::down();
						Produce::ref_iname(K_value, Hierarchy::find(WN_HL));
						Produce::inv_primitive(Produce::opcode(PLUS_BIP));
						Produce::down();
							Produce::val_symbol(K_value, gprk->w_s);
							Produce::inv_call_iname(Hierarchy::find(TRYGIVENOBJECT_HL));
							Produce::down();
								Produce::val_symbol(K_value, gprk->rv_s);
								Produce::val(K_truth_state, LITERAL_IVAL, 1);
							Produce::up();
						Produce::up();
					Produce::up();
					Produce::inv_primitive(Produce::opcode(IF_BIP));
					Produce::down();
						Produce::inv_primitive(Produce::opcode(GT_BIP));
						Produce::down();
							Produce::val_iname(K_value, Hierarchy::find(WN_HL));
							Produce::val_symbol(K_value, gprk->w_s);
						Produce::up();
						Produce::code();
						Produce::down();
							Produce::inv_primitive(Produce::opcode(JUMP_BIP));
							Produce::down();
								Produce::lab(exit_label);
							Produce::up();
						Produce::up();
					Produce::up();
				Produce::up();
			Produce::up();
			Produce::inv_primitive(Produce::opcode(STORE_BIP));
			Produce::down();
				Produce::ref_symbol(K_value, gprk->rv_s);
				Produce::val(K_number, LITERAL_IVAL, 0);
			Produce::up();
			@<Jump to our doom@>;
			Produce::place_label(exit_label);
			Produce::inv_primitive(Produce::opcode(STORE_BIP));
			Produce::down();
				Produce::ref_symbol(K_value, gprk->rv_s);
				Produce::val(K_number, LITERAL_IVAL, 0);
			Produce::up();
		} else if (bp == R_incorporation) {
			TEMPORARY_TEXT(L);
			WRITE_TO(L, ".ol_mm_%d", ol_loop_counter++);
			inter_symbol *exit_label = Produce::reserve_label(L);
			DISCARD_TEXT(L);
			Produce::inv_primitive(Produce::opcode(STORE_BIP));
			Produce::down();
				Produce::ref_symbol(K_value, gprk->rv_s);
				Produce::inv_primitive(Produce::opcode(PROPERTYVALUE_BIP));
				Produce::down();
					Produce::val_iname(K_value, Hierarchy::find(SELF_HL));
					Produce::val_iname(K_value, Hierarchy::find(COMPONENT_CHILD_HL));
				Produce::up();
			Produce::up();
			Produce::inv_primitive(Produce::opcode(WHILE_BIP));
			Produce::down();
				Produce::val_symbol(K_value, gprk->rv_s);
				Produce::code();
				Produce::down();
					Produce::inv_primitive(Produce::opcode(STORE_BIP));
					Produce::down();
						Produce::ref_iname(K_value, Hierarchy::find(WN_HL));
						Produce::val_symbol(K_value, gprk->w_s);
					Produce::up();
					Produce::inv_primitive(Produce::opcode(STORE_BIP));
					Produce::down();
						Produce::ref_iname(K_value, Hierarchy::find(WN_HL));
						Produce::inv_primitive(Produce::opcode(PLUS_BIP));
						Produce::down();
							Produce::val_symbol(K_value, gprk->w_s);
							Produce::inv_call_iname(Hierarchy::find(TRYGIVENOBJECT_HL));
							Produce::down();
								Produce::val_symbol(K_value, gprk->rv_s);
								Produce::val(K_truth_state, LITERAL_IVAL, 1);
							Produce::up();
						Produce::up();
					Produce::up();
					Produce::inv_primitive(Produce::opcode(IF_BIP));
					Produce::down();
						Produce::inv_primitive(Produce::opcode(GT_BIP));
						Produce::down();
							Produce::val_iname(K_value, Hierarchy::find(WN_HL));
							Produce::val_symbol(K_value, gprk->w_s);
						Produce::up();
						Produce::code();
						Produce::down();
							Produce::inv_primitive(Produce::opcode(JUMP_BIP));
							Produce::down();
								Produce::lab(exit_label);
							Produce::up();
						Produce::up();
					Produce::up();
					Produce::inv_primitive(Produce::opcode(STORE_BIP));
					Produce::down();
						Produce::ref_symbol(K_value, gprk->rv_s);
						Produce::inv_primitive(Produce::opcode(PROPERTYVALUE_BIP));
						Produce::down();
							Produce::val_symbol(K_value, gprk->rv_s);
							Produce::val_iname(K_value, Hierarchy::find(COMPONENT_SIBLING_HL));
						Produce::up();
					Produce::up();
				Produce::up();
			Produce::up();
			Produce::inv_primitive(Produce::opcode(STORE_BIP));
			Produce::down();
				Produce::ref_symbol(K_value, gprk->rv_s);
				Produce::val(K_number, LITERAL_IVAL, 0);
			Produce::up();
			@<Jump to our doom@>;
			Produce::place_label(exit_label);
			Produce::inv_primitive(Produce::opcode(STORE_BIP));
			Produce::down();
				Produce::ref_symbol(K_value, gprk->rv_s);
				Produce::val(K_number, LITERAL_IVAL, 0);
			Produce::up();
		} else if (bp == R_equality) {
			Problems::quote_source(1, current_sentence);
			Problems::quote_source(2, pn);
			Problems::Issue::handmade_problem(_p_(PM_RelatedByEquality));
			Problems::issue_problem_segment(
				"The grammar you give in %1 contains a token %2 which would "
				"create a circularity. To follow this, I'd have to compute "
				"forever.");
			Problems::issue_problem_end();
			return K_object;
		} else if ((BinaryPredicates::get_reversal(bp) == R_containment) ||
			(BinaryPredicates::get_reversal(bp) == R_support) ||
			(BinaryPredicates::get_reversal(bp) == a_has_b_predicate) ||
			(BinaryPredicates::get_reversal(bp) == R_wearing) ||
			(BinaryPredicates::get_reversal(bp) == R_carrying)) {
			if (BinaryPredicates::get_reversal(bp) == R_carrying) {
				Produce::inv_primitive(Produce::opcode(IF_BIP));
				Produce::down();
					Produce::inv_primitive(Produce::opcode(HAS_BIP));
					Produce::down();
						Produce::val_iname(K_value, Hierarchy::find(SELF_HL));
						Produce::val_iname(K_value, Properties::iname(P_worn));
					Produce::up();
					@<Then jump to our doom@>;
				Produce::up();
			}
			if (BinaryPredicates::get_reversal(bp) == R_wearing) {
				Produce::inv_primitive(Produce::opcode(IF_BIP));
				Produce::down();
					Produce::inv_primitive(Produce::opcode(NOT_BIP));
					Produce::down();
						Produce::inv_primitive(Produce::opcode(HAS_BIP));
						Produce::down();
							Produce::val_iname(K_value, Hierarchy::find(SELF_HL));
							Produce::val_iname(K_value, Properties::iname(P_worn));
						Produce::up();
					Produce::up();
					@<Then jump to our doom@>;
				Produce::up();
			}
			Produce::inv_primitive(Produce::opcode(STORE_BIP));
			Produce::down();
				Produce::ref_symbol(K_value, gprk->rv_s);
				Produce::inv_call(Packaging::veneer_symbol(PARENT_VSYMB));
				Produce::down();
					Produce::val_iname(K_value, Hierarchy::find(SELF_HL));
				Produce::up();
			Produce::up();

			Produce::inv_primitive(Produce::opcode(STORE_BIP));
			Produce::down();
				Produce::ref_iname(K_value, Hierarchy::find(WN_HL));
				Produce::val_symbol(K_value, gprk->w_s);
			Produce::up();
			Produce::inv_primitive(Produce::opcode(STORE_BIP));
			Produce::down();
				Produce::ref_iname(K_value, Hierarchy::find(WN_HL));
				Produce::inv_primitive(Produce::opcode(PLUS_BIP));
				Produce::down();
					Produce::val_symbol(K_value, gprk->w_s);
					Produce::inv_call_iname(Hierarchy::find(TRYGIVENOBJECT_HL));
					Produce::down();
						Produce::val_symbol(K_value, gprk->rv_s);
						Produce::val(K_truth_state, LITERAL_IVAL, 1);
					Produce::up();
				Produce::up();
			Produce::up();
			Produce::inv_primitive(Produce::opcode(IF_BIP));
			Produce::down();
				Produce::inv_primitive(Produce::opcode(EQ_BIP));
				Produce::down();
					Produce::val_iname(K_value, Hierarchy::find(WN_HL));
					Produce::val_symbol(K_value, gprk->w_s);
				Produce::up();
				@<Then jump to our doom@>;
			Produce::up();
		} else if (BinaryPredicates::get_reversal(bp) == R_incorporation) {
			Produce::inv_primitive(Produce::opcode(STORE_BIP));
			Produce::down();
				Produce::ref_symbol(K_value, gprk->rv_s);
				Produce::inv_primitive(Produce::opcode(PROPERTYVALUE_BIP));
				Produce::down();
					Produce::val_iname(K_value, Hierarchy::find(SELF_HL));
					Produce::val_iname(K_value, Hierarchy::find(COMPONENT_PARENT_HL));
				Produce::up();
			Produce::up();
			Produce::inv_primitive(Produce::opcode(STORE_BIP));
			Produce::down();
				Produce::ref_iname(K_value, Hierarchy::find(WN_HL));
				Produce::val_symbol(K_value, gprk->w_s);
			Produce::up();
			Produce::inv_primitive(Produce::opcode(STORE_BIP));
			Produce::down();
				Produce::ref_iname(K_value, Hierarchy::find(WN_HL));
				Produce::inv_primitive(Produce::opcode(PLUS_BIP));
				Produce::down();
					Produce::val_symbol(K_value, gprk->w_s);
					Produce::inv_call_iname(Hierarchy::find(TRYGIVENOBJECT_HL));
					Produce::down();
						Produce::val_symbol(K_value, gprk->rv_s);
						Produce::val(K_truth_state, LITERAL_IVAL, 1);
					Produce::up();
				Produce::up();
			Produce::up();
			Produce::inv_primitive(Produce::opcode(IF_BIP));
			Produce::down();
				Produce::inv_primitive(Produce::opcode(EQ_BIP));
				Produce::down();
					Produce::val_iname(K_value, Hierarchy::find(WN_HL));
					Produce::val_symbol(K_value, gprk->w_s);
				Produce::up();
				@<Then jump to our doom@>;
			Produce::up();
		} else {
			i6_schema *i6s;
			int reverse = FALSE;
			int continue_loop_on_fail = TRUE;

			i6s = BinaryPredicates::get_test_function(bp);
			LOGIF(GRAMMAR_CONSTRUCTION, "Read I6s $i from $2\n", i6s, bp);
			if ((i6s == NULL) && (BinaryPredicates::get_test_function(BinaryPredicates::get_reversal(bp)))) {
				reverse = TRUE;
				i6s = BinaryPredicates::get_test_function(BinaryPredicates::get_reversal(bp));
				LOGIF(GRAMMAR_CONSTRUCTION, "But read I6s $i from reversal\n", i6s);
			}

			if (i6s) {
				kind *K = BinaryPredicates::term_kind(bp, 1);
				if (Kinds::Compare::lt(K, K_object)) {
					LOGIF(GRAMMAR_CONSTRUCTION, "Term 1 of BP is $u\n", K);
					Produce::inv_primitive(Produce::opcode(OBJECTLOOPX_BIP));
					Produce::down();
						Produce::ref_symbol(K_value, gprk->rv_s);
						Produce::val_iname(K_value, Kinds::RunTime::I6_classname(K));
						Produce::code();
						Produce::down();
							Produce::inv_primitive(Produce::opcode(IF_BIP));
							Produce::down();
								Produce::inv_primitive(Produce::opcode(EQ_BIP));
								Produce::down();
									pcalc_term rv_term = Calculus::Terms::new_constant(
										Lvalues::new_LOCAL_VARIABLE(EMPTY_WORDING, gprk->rv_lv));
									pcalc_term self_term = Calculus::Terms::new_constant(
										Rvalues::new_self_object_constant());
									if (reverse)
										Calculus::Schemas::emit_val_expand_from_terms(i6s, &rv_term, &self_term);
									else
										Calculus::Schemas::emit_val_expand_from_terms(i6s, &self_term, &rv_term);
					continue_loop_on_fail = TRUE;
				} else {
					Problems::quote_source(1, current_sentence);
					Problems::quote_source(2, pn);
					Problems::Issue::handmade_problem(_p_(PM_GrammarValueRelation));
					Problems::issue_problem_segment(
						"The grammar you give in %1 contains a token "
						"which relates things to values - %2. At present, "
						"this is not allowed: only relations between kinds "
						"of object can be used in 'Understand' tokens.");
					Problems::issue_problem_end();
					return K_object;
				}
			} else {
				property *prn = BinaryPredicates::get_i6_storage_property(bp);
				reverse = FALSE;
				if (BinaryPredicates::is_the_wrong_way_round(bp)) reverse = TRUE;
				if (BinaryPredicates::get_form_of_relation(bp) == Relation_VtoO) {
					if (reverse) reverse = FALSE; else reverse = TRUE;
				}
				if (prn) {
					if (reverse) {
						Produce::inv_primitive(Produce::opcode(IF_BIP));
						Produce::down();
							Produce::inv_primitive(Produce::opcode(PROVIDES_BIP));
							Produce::down();
								Produce::val_iname(K_value, Hierarchy::find(SELF_HL));
								Produce::val_iname(K_value, Properties::iname(prn));
							Produce::up();
							Produce::code();
							Produce::down();

								Produce::inv_primitive(Produce::opcode(STORE_BIP));
								Produce::down();
									Produce::ref_symbol(K_value, gprk->rv_s);
									Produce::inv_primitive(Produce::opcode(PROPERTYVALUE_BIP));
									Produce::down();
										Produce::val_iname(K_value, Hierarchy::find(SELF_HL));
										Produce::val_iname(K_value, Properties::iname(prn));
									Produce::up();
								Produce::up();
								Produce::inv_primitive(Produce::opcode(IF_BIP));
								Produce::down();
									Produce::inv_primitive(Produce::opcode(EQ_BIP));
									Produce::down();
										Produce::val_symbol(K_value, gprk->rv_s);

						continue_loop_on_fail = FALSE;
					} else {
						kind *K = BinaryPredicates::term_kind(bp, 1);
						if (Kinds::Compare::le(K, K_object) == FALSE) {
							Problems::quote_source(1, current_sentence);
							Problems::quote_source(2, pn);
							Problems::quote_kind(3, K);
							Problems::Issue::handmade_problem(_p_(PM_GrammarValueRelation2));
							Problems::issue_problem_segment(
								"The grammar you give in %1 contains a token "
								"which relates things to values - %2. (It would "
								"need to match the name of %3, which isn't a kind "
								"of thing.) At present, this is not allowed: only "
								"relations between kinds of object can be used in "
								"'Understand' tokens.");
							Problems::issue_problem_end();
							return K_object;
						}
						Produce::inv_primitive(Produce::opcode(OBJECTLOOPX_BIP));
						Produce::down();
							Produce::ref_symbol(K_value, gprk->rv_s);
							Produce::val_iname(K_value, Kinds::RunTime::I6_classname(K));
							Produce::code();
							Produce::down();
								Produce::inv_primitive(Produce::opcode(IF_BIP));
								Produce::down();
									Produce::inv_primitive(Produce::opcode(EQ_BIP));
									Produce::down();
										Produce::inv_primitive(Produce::opcode(AND_BIP));
										Produce::down();
											Produce::inv_primitive(Produce::opcode(PROVIDES_BIP));
											Produce::down();
												Produce::val_symbol(K_value, gprk->rv_s);
												Produce::val_iname(K_value, Properties::iname(prn));
											Produce::up();
											Produce::inv_primitive(Produce::opcode(EQ_BIP));
											Produce::down();
												Produce::inv_primitive(Produce::opcode(PROPERTYVALUE_BIP));
												Produce::down();
													Produce::val_symbol(K_value, gprk->rv_s);
													Produce::val_iname(K_value, Properties::iname(prn));
												Produce::up();
												Produce::val_iname(K_value, Hierarchy::find(SELF_HL));
											Produce::up();
										Produce::up();
						continue_loop_on_fail = TRUE;
					}
				} else {
					LOG("Trouble with: $2\n", bp);
					LOG("Whose reversal is: $2\n", BinaryPredicates::get_reversal(bp));
					Problems::quote_source(1, current_sentence);
					Problems::quote_source(2, pn);
					Problems::Issue::handmade_problem(_p_(PM_GrammarTokenCowardice));
					Problems::issue_problem_segment(
						"The grammar you give in %1 contains a token "
						"which uses a relation I'm unable to test - %2.");
					Problems::issue_problem_end();
					return K_object;
				}
			}

								Produce::val(K_truth_state, LITERAL_IVAL, 0);
							Produce::up();
							Produce::code();
							Produce::down();
								if (continue_loop_on_fail == FALSE) {
									@<Jump to our doom@>;
								} else {
									Produce::inv_primitive(Produce::opcode(CONTINUE_BIP));
								}
							Produce::up();
						Produce::up();

						Produce::inv_primitive(Produce::opcode(STORE_BIP));
						Produce::down();
							Produce::ref_iname(K_value, Hierarchy::find(WN_HL));
							Produce::val_symbol(K_value, gprk->w_s);
						Produce::up();
						Produce::inv_primitive(Produce::opcode(STORE_BIP));
						Produce::down();
							Produce::ref_iname(K_value, Hierarchy::find(WN_HL));
							Produce::inv_primitive(Produce::opcode(PLUS_BIP));
							Produce::down();
								Produce::val_symbol(K_value, gprk->w_s);
								Produce::inv_call_iname(Hierarchy::find(TRYGIVENOBJECT_HL));
								Produce::down();
									Produce::val_symbol(K_value, gprk->rv_s);
									Produce::val(K_truth_state, LITERAL_IVAL, 1);
								Produce::up();
							Produce::up();
						Produce::up();

						TEMPORARY_TEXT(L);
						WRITE_TO(L, ".ol_mm_%d", ol_loop_counter++);
						inter_symbol *exit_label = Produce::reserve_label(L);
						DISCARD_TEXT(L);

						Produce::inv_primitive(Produce::opcode(IF_BIP));
						Produce::down();
							Produce::inv_primitive(Produce::opcode(GT_BIP));
							Produce::down();
								Produce::val_iname(K_value, Hierarchy::find(WN_HL));
								Produce::val_symbol(K_value, gprk->w_s);
							Produce::up();
							Produce::code();
							Produce::down();
								Produce::inv_primitive(Produce::opcode(JUMP_BIP));
								Produce::down();
									Produce::lab(exit_label);
								Produce::up();
							Produce::up();
						Produce::up();

					Produce::up();
				Produce::up();
				Produce::inv_primitive(Produce::opcode(STORE_BIP));
				Produce::down();
					Produce::ref_symbol(K_value, gprk->rv_s);
					Produce::val(K_number, LITERAL_IVAL, 0);
				Produce::up();
				@<Jump to our doom@>;
				Produce::place_label(exit_label);
				Produce::inv_primitive(Produce::opcode(STORE_BIP));
				Produce::down();
					Produce::ref_symbol(K_value, gprk->rv_s);
					Produce::val(K_number, LITERAL_IVAL, 0);
				Produce::up();
			}
			return NULL;
		}

	spec = ParseTree::get_grammar_value(pn);
	if (spec == NULL) PL::Parsing::Tokens::determine(pn, 10, NULL);
	spec = ParseTree::get_grammar_value(pn);
	if (spec == NULL) {
		LOG("$T", pn);
		internal_error("NULL result of non-preposition token");
	}

	if (Specifications::is_kind_like(spec)) {
		kind *K = ParseTree::get_kind_of_value(spec);
		if ((Kinds::Compare::le(K, K_object) == FALSE) &&
			(Kinds::Compare::eq(K, K_understanding) == FALSE)) {
			if (Kinds::Behaviour::offers_I6_GPR(K)) {
				text_stream *i6_gpr_name = Kinds::Behaviour::get_explicit_I6_GPR(K);
				if (code_mode) {
					Produce::inv_primitive(Produce::opcode(STORE_BIP));
					Produce::down();
						Produce::ref_symbol(K_value, gprk->w_s);
						Produce::inv_call_iname(Hierarchy::find(PARSETOKENSTOPPED_HL));
						Produce::down();
							Produce::val_iname(K_value, Hierarchy::find(GPR_TT_HL));
							if (Str::len(i6_gpr_name) > 0)
								Produce::val_iname(K_value, Produce::find_by_name(i6_gpr_name));
							else
								Produce::val_iname(K_value, Kinds::RunTime::get_kind_GPR_iname(K));
						Produce::up();
					Produce::up();
					Produce::inv_primitive(Produce::opcode(IF_BIP));
					Produce::down();
						Produce::inv_primitive(Produce::opcode(NE_BIP));
						Produce::down();
							Produce::val_symbol(K_value, gprk->w_s);
							Produce::val_iname(K_number, Hierarchy::find(GPR_NUMBER_HL));
						Produce::up();
						@<Then jump to our doom@>;
					Produce::up();
					Produce::inv_primitive(Produce::opcode(STORE_BIP));
					Produce::down();
						Produce::ref_symbol(K_value, gprk->rv_s);
						Produce::val_iname(K_number, Hierarchy::find(GPR_NUMBER_HL));
					Produce::up();
				} else {
					if (Str::len(i6_gpr_name) > 0)
						Emit::array_iname_entry(Produce::find_by_name(i6_gpr_name));
					else
						Emit::array_iname_entry(Kinds::RunTime::get_kind_GPR_iname(K));
				}
				return K;
			}
			/* internal_error("Let an invalid type token through"); */
		}
	}

	if (Descriptions::is_complex(spec)) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_source(2, pn);
		Problems::Issue::handmade_problem(_p_(PM_OverComplexToken));
		Problems::issue_problem_segment(
			"The grammar you give in %1 contains a token "
			"which is just too complicated - %2. %PFor instance, a "
			"token using subordinate clauses - such as '[a person who "
			"can see the player]' will probably not be allowed.");
		Problems::issue_problem_end();
		return K_object;
	} else {
		kind *K = NULL;
		int gtc = ParseTree::int_annotation(pn, grammar_token_code_ANNOT);
		if (gtc < 0) {
			inter_name *i6_token_iname = PL::Parsing::Tokens::iname_for_special_token(gtc);
			K = PL::Parsing::Tokens::kind_for_special_token(gtc);
			if (code_mode) {
				if ((consult_mode) && (gtc == TOPIC_TOKEN_GTC)) {
					Problems::Issue::sentence_problem(_p_(PM_TextTokenRestricted),
						"the '[text]' token is not allowed with 'matches' "
						"or in table columns",
						"as it is just too complicated to sort out: a "
						"'[text]' is supposed to extract a snippet from "
						"the player's command, but here we already have "
						"a snippet, and don't want to snip it further.");
				}
				Produce::inv_primitive(Produce::opcode(STORE_BIP));
				Produce::down();
					Produce::ref_symbol(K_value, gprk->w_s);
					Produce::inv_call_iname(Hierarchy::find(PARSETOKENSTOPPED_HL));
					Produce::down();
						Produce::val_iname(K_value, Hierarchy::find(ELEMENTARY_TT_HL));
						Produce::val_iname(K_value, i6_token_iname);
					Produce::up();
				Produce::up();
				Produce::inv_primitive(Produce::opcode(IF_BIP));
				Produce::down();
					Produce::inv_primitive(Produce::opcode(EQ_BIP));
					Produce::down();
						Produce::val_symbol(K_value, gprk->w_s);
						Produce::val_iname(K_number, Hierarchy::find(GPR_FAIL_HL));
					Produce::up();
					@<Then jump to our doom@>;
				Produce::up();
				Produce::inv_primitive(Produce::opcode(STORE_BIP));
				Produce::down();
					Produce::ref_symbol(K_value, gprk->rv_s);
					Produce::val_symbol(K_value, gprk->w_s);
				Produce::up();
			} else {
				Emit::array_iname_entry(i6_token_iname);
			}
		} else {
			if (Specifications::is_description(spec)) {
				K = Specifications::to_kind(spec);
				if (Descriptions::is_qualified(spec)) {
 					if (code_mode) {
		 				Produce::inv_primitive(Produce::opcode(STORE_BIP));
						Produce::down();
							Produce::ref_symbol(K_value, gprk->w_s);
							Produce::inv_call_iname(Hierarchy::find(PARSETOKENSTOPPED_HL));
							Produce::down();
								PL::Parsing::Tokens::Filters::compile_id(gtc);
							Produce::up();
						Produce::up();
						Produce::inv_primitive(Produce::opcode(IF_BIP));
						Produce::down();
							Produce::inv_primitive(Produce::opcode(EQ_BIP));
							Produce::down();
								Produce::val_symbol(K_value, gprk->w_s);
								Produce::val_iname(K_number, Hierarchy::find(GPR_FAIL_HL));
							Produce::up();
							@<Then jump to our doom@>;
						Produce::up();
						Produce::inv_primitive(Produce::opcode(STORE_BIP));
						Produce::down();
							Produce::ref_symbol(K_value, gprk->rv_s);
							Produce::val_symbol(K_value, gprk->w_s);
						Produce::up();
					} else {
						PL::Parsing::Tokens::Filters::emit_id(gtc);
					}
				} else {
					if (Kinds::Behaviour::offers_I6_GPR(K)) {
						text_stream *i6_gpr_name = Kinds::Behaviour::get_explicit_I6_GPR(K);
						if (code_mode) {
							Produce::inv_primitive(Produce::opcode(STORE_BIP));
							Produce::down();
								Produce::ref_symbol(K_value, gprk->w_s);
								Produce::inv_call_iname(Hierarchy::find(PARSETOKENSTOPPED_HL));
								Produce::down();
									Produce::val_iname(K_value, Hierarchy::find(GPR_TT_HL));
									if (Str::len(i6_gpr_name) > 0)
										Produce::val_iname(K_value, Produce::find_by_name(i6_gpr_name));
									else
										Produce::val_iname(K_value, Kinds::RunTime::get_kind_GPR_iname(K));
								Produce::up();
							Produce::up();
							Produce::inv_primitive(Produce::opcode(IF_BIP));
							Produce::down();
								Produce::inv_primitive(Produce::opcode(NE_BIP));
								Produce::down();
									Produce::val_symbol(K_value, gprk->w_s);
									Produce::val_iname(K_number, Hierarchy::find(GPR_NUMBER_HL));
								Produce::up();
								@<Then jump to our doom@>;
							Produce::up();
							Produce::inv_primitive(Produce::opcode(STORE_BIP));
							Produce::down();
								Produce::ref_symbol(K_value, gprk->rv_s);
								Produce::val_iname(K_number, Hierarchy::find(GPR_NUMBER_HL));
							Produce::up();
						} else {
							if (Str::len(i6_gpr_name) > 0)
								Emit::array_iname_entry(Produce::find_by_name(i6_gpr_name));
							else
								Emit::array_iname_entry(Kinds::RunTime::get_kind_GPR_iname(K));
						}
					} else if (Kinds::Compare::le(K, K_object)) {
						if (code_mode) {
							Produce::inv_primitive(Produce::opcode(STORE_BIP));
							Produce::down();
								Produce::ref_symbol(K_value, gprk->w_s);
								Produce::inv_call_iname(Hierarchy::find(PARSETOKENSTOPPED_HL));
								Produce::down();
									PL::Parsing::Tokens::Filters::compile_id(gtc);
								Produce::up();
							Produce::up();
							Produce::inv_primitive(Produce::opcode(IF_BIP));
							Produce::down();
								Produce::inv_primitive(Produce::opcode(EQ_BIP));
								Produce::down();
									Produce::val_symbol(K_value, gprk->w_s);
									Produce::val_iname(K_number, Hierarchy::find(GPR_FAIL_HL));
								Produce::up();
								@<Then jump to our doom@>;
							Produce::up();
							Produce::inv_primitive(Produce::opcode(STORE_BIP));
							Produce::down();
								Produce::ref_symbol(K_value, gprk->rv_s);
								Produce::val_symbol(K_value, gprk->w_s);
							Produce::up();
						} else {
							PL::Parsing::Tokens::Filters::emit_id(gtc);
						}
						K = K_object;
					} else internal_error("no token for description");
				}
			} else {
				if (ParseTree::is(spec, CONSTANT_NT)) {
					if (Rvalues::is_CONSTANT_of_kind(spec, K_understanding)) {
						gv = Rvalues::to_grammar_verb(spec);
						if (code_mode) {
							Produce::inv_primitive(Produce::opcode(STORE_BIP));
							Produce::down();
								Produce::ref_symbol(K_value, gprk->w_s);
								Produce::inv_call_iname(Hierarchy::find(PARSETOKENSTOPPED_HL));
								Produce::down();
									Produce::val_iname(K_value, Hierarchy::find(GPR_TT_HL));
									Produce::val_iname(K_value, PL::Parsing::Verbs::i6_token_as_iname(gv));
								Produce::up();
							Produce::up();
							Produce::inv_primitive(Produce::opcode(IF_BIP));
							Produce::down();
								Produce::inv_primitive(Produce::opcode(EQ_BIP));
								Produce::down();
									Produce::val_symbol(K_value, gprk->w_s);
									Produce::val_iname(K_number, Hierarchy::find(GPR_FAIL_HL));
								Produce::up();
								@<Then jump to our doom@>;
							Produce::up();

							Produce::inv_primitive(Produce::opcode(IF_BIP));
							Produce::down();
								Produce::inv_primitive(Produce::opcode(NE_BIP));
								Produce::down();
									Produce::val_symbol(K_value, gprk->w_s);
									Produce::val_iname(K_number, Hierarchy::find(GPR_PREPOSITION_HL));
								Produce::up();
								Produce::code();
								Produce::down();
									Produce::inv_primitive(Produce::opcode(STORE_BIP));
									Produce::down();
										Produce::ref_symbol(K_value, gprk->rv_s);
										Produce::val_symbol(K_value, gprk->w_s);
									Produce::up();
								Produce::up();
							Produce::up();
						} else {
							Emit::array_iname_entry(PL::Parsing::Verbs::i6_token_as_iname(gv));
						}
						K = PL::Parsing::Verbs::get_data_type_as_token(gv);
					}
					if (Rvalues::is_object(spec)) {
						if (code_mode) {
							Produce::inv_primitive(Produce::opcode(STORE_BIP));
							Produce::down();
								Produce::ref_symbol(K_value, gprk->w_s);
								Produce::inv_call_iname(Hierarchy::find(PARSETOKENSTOPPED_HL));
								Produce::down();
									PL::Parsing::Tokens::Filters::compile_id(gtc);
								Produce::up();
							Produce::up();
							Produce::inv_primitive(Produce::opcode(IF_BIP));
							Produce::down();
								Produce::inv_primitive(Produce::opcode(EQ_BIP));
								Produce::down();
									Produce::val_symbol(K_value, gprk->w_s);
									Produce::val_iname(K_number, Hierarchy::find(GPR_FAIL_HL));
								Produce::up();
								@<Then jump to our doom@>;
							Produce::up();
							Produce::inv_primitive(Produce::opcode(STORE_BIP));
							Produce::down();
								Produce::ref_symbol(K_value, gprk->rv_s);
								Produce::val_symbol(K_value, gprk->w_s);
							Produce::up();
						} else {
							PL::Parsing::Tokens::Filters::emit_id(gtc);
						}
						K = K_object;
					}
				} else K = K_object;
			}
		}
		return K;
	}
}

@<Then jump to our doom@> =
	Produce::code();
	Produce::down();
		@<Jump to our doom@>;
	Produce::up();

@<Jump to our doom@> =
	Produce::inv_primitive(Produce::opcode(JUMP_BIP));
	Produce::down();
		Produce::lab(failure_label);
	Produce::up();
