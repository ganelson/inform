[IdentifierTranslations::] Translate to Identifiers.

To provide a way to map high-level I7 constructs onto explicitly
named identifiers in I6 code.

@h Definitions.

@ Translations can be made in a number of contexts:

@d INVALID_I6TR -1
@d PROPERTY_I6TR 0 /* "The open property translates into I6 as "open"." */
@d NOUN_I6TR 1 /* "The north object translates into I6 as "n\_obj"." */
@d RULE_I6TR 2 /* "The baffling rule translates into I6 as "BAFFLING\_R"." */
@d VARIABLE_I6TR 3 /* "The sludge count variable translates into I6 as "sldgc". */
@d ACTION_I6TR 4 /* "The taking action translates into I6 as "Take". */
@d GRAMMAR_TOKEN_I6TR 5 /* "The grammar token "[whatever]" translates into I6 as "WHATEVER". */

@ I7 provides the ability for the user to specify exactly what identifier name
to use as the I6 image of something, overriding the automatically composed
name above, in some cases. The following routine parses, tidies up and acts
on "... translates into I6 as ..." sentences; it gives their sentence
nodes an annotation marking what sort of thing is being translated.

This parses the subject of "... translates into I6 as ..." sentences,
such as "The yourself object" in

>> The yourself object translates into I6 as "selfobj".

=
<translates-into-i6-sentence-subject> ::=
	... property |    ==> PROPERTY_I6TR
	... object/kind |    ==> NOUN_I6TR
	{... rule} |    ==> RULE_I6TR
	... variable |    ==> VARIABLE_I6TR
	... action |    ==> ACTION_I6TR
	understand token ... |    ==> GRAMMAR_TOKEN_I6TR
	...									==> @<Issue PM_TranslatedUnknownCategory problem@>

@<Issue PM_TranslatedUnknownCategory problem@> =
	*X = INVALID_I6TR;
	Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_TranslatedUnknownCategory),
		"that isn't one of the things which can be translated to I6",
		"and should be '... variable', '... property', '... object', "
		"'... kind', '... rule', or '... action'. For instance, 'The yourself "
		"object translates into I6 as \"selfobj\".'");

@ The object noun phrase is usually just an I6 identifier in quotation marks,
but it's also possible to list literal texts (for the benefit of rules).
Following the optional "with" is an articled list, each entry of which
will be required to pass |<extra-response>|.

=
<translates-into-i6-sentence-object> ::=
	<quoted-text> with <nounphrase-articled-list> |    ==> R[1]; *XP = RP[2];
	<quoted-text>									==> R[1]; *XP = NULL;

@ =
void IdentifierTranslations::as(parse_node *pn) {
	parse_node *p1 = pn->next;
	parse_node *p2 = pn->next->next;
	parse_node *responses_list = NULL;
	int category = INVALID_I6TR;
	<translates-into-i6-sentence-subject>(Node::get_text(p1));
	category = <<r>>;
	if (category == INVALID_I6TR) return;
	wording W = GET_RW(<translates-into-i6-sentence-subject>, 1);

	if (traverse == 1) {
		Annotations::write_int(pn, category_of_I6_translation_ANNOT, INVALID_I6TR);
		@<Ensure that we are translating to a quoted I6 identifier@>;
		Annotations::write_int(pn, category_of_I6_translation_ANNOT, category);
		if (responses_list) SyntaxTree::graft(Task::syntax_tree(), responses_list, p2);
	} else category = Annotations::read_int(pn, category_of_I6_translation_ANNOT);

	@<Take immediate action on the translation where possible@>;
}

@ In some cases, we might as well act now; but in others we will act later,
traversing the parse tree to look for translation sentences of the right sort.

@<Take immediate action on the translation where possible@> =
	switch(category) {
		case PROPERTY_I6TR:
			Properties::translates(W, p2);
			Annotations::write_int(pn, category_of_I6_translation_ANNOT, INVALID_I6TR); break;
		case NOUN_I6TR: break;
		case RULE_I6TR:
			if (traverse == 1) Rules::Placement::declare_I6_written_rule(W, p2);
			if ((traverse == 2) && (p2->down) && (<rule-name>(W)))
				IdentifierTranslations::plus_responses(p2->down, <<rp>>);
			break;
		case VARIABLE_I6TR: if (traverse == 2) NonlocalVariables::translates(W, p2); break;
		#ifdef IF_MODULE
		case ACTION_I6TR: if (traverse == 2) PL::Actions::translates(W, p2); break;
		case GRAMMAR_TOKEN_I6TR: if (traverse == 2) PL::Parsing::Verbs::translates(W, p2); break;
		#endif
	}

@<Ensure that we are translating to a quoted I6 identifier@> =
	int valid = TRUE;
	if (<translates-into-i6-sentence-object>(Node::get_text(p2)) == FALSE) valid = FALSE;
	else responses_list = <<rp>>;
	if (valid) @<Dequote it and see if it's valid@>;
	if (valid == FALSE) {
		Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_TranslatedToNonIdentifier),
			"Inform 7 constructions can only translate into quoted I6 identifiers",
			"which must be strings of 1 to 31 characters drawn from 1, 2, ..., 9, "
			"a or A, b or B, ..., z or Z, or underscore '_', except that the "
			"first character is not allowed to be a digit.");
		return;
	}

@ If it turns out not to be, we simply set |valid| to false.

@<Dequote it and see if it's valid@> =
	int wn = Wordings::first_wn(Node::get_text(p2));
	Node::set_text(p2, Wordings::one_word(wn));
	Word::dequote(wn);
	if (valid) valid = Identifiers::valid(Lexer::word_text(wn));

@ Extra responses look just as they would in running code.

=
<extra-response> ::=
	<quoted-text> ( <response-letter> )				==> R[2];

@ =
void IdentifierTranslations::plus_responses(parse_node *p, rule *R) {
	if (Node::get_type(p) == AND_NT) {
		IdentifierTranslations::plus_responses(p->down, R);
		IdentifierTranslations::plus_responses(p->down->next, R);
	} else {
		if (<extra-response>(Node::get_text(p))) {
			int code = <<r>>;
			response_message *resp = Strings::response_cue(NULL, R,
				code, Node::get_text(p), NULL, TRUE);
			Rules::now_rule_defines_response(R, code, resp);
		} else {
			Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_I6ResponsesAwry),
				"additional information about I6 translation of a rule can "
				"only take the form of a list of responses",
				"each quoted and followed by a bracketed letter.");
		}
	}
}
