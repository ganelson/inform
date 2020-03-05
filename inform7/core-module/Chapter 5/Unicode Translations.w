[UnicodeTranslations::] Unicode Translations.

To manage the names assigned to Unicode character values.

@ There are no data structures here; Unicode names are simply a category of
excerpt meanings, so we read a "translates into Unicode as" sentence as
a new name and its meaning to be.

=
void UnicodeTranslations::unicode_translates(parse_node *pn) {
	if (<translates-into-unicode-sentence-object>(ParseTree::get_text(pn->next->next)) == FALSE) return;
	int cc = <<r>>;
	if (UnicodeTranslations::char_in_range(cc) == FALSE) return;

	<translates-into-unicode-sentence-subject>(ParseTree::get_text(pn->next));
	if ((<<r>> != -1) && (<<r>> != cc)) {
		Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_UnicodeAlready),
			"this Unicode character name has already been translated",
			"so there must be some duplication somewhere.");
		return;
	}

	Nouns::new_proper_noun(ParseTree::get_text(pn->next), NEUTER_GENDER,
		REGISTER_SINGULAR_NTOPT + PARSE_EXACTLY_NTOPT,
		MISCELLANEOUS_MC,
		NounPhrases::new_raw(ParseTree::get_text(pn->next->next)));
}

@ The following parses the subject noun phrase of sentences like

>> leftwards harpoon with barb upwards translates into Unicode as 8636.

The subject "leftwards harpoon with barb upwards" is parsed against the
Unicode character names known already to make sure that this new translation
doesn't disagree with an existing one (that is, doesn't translate to a
different code number).

=
<translates-into-unicode-sentence-subject> ::=
	<unicode-character-name> |			==> R[1]
	...									==> -1

@ And this parses the object noun phrase of such sentences -- a decimal
number. I was tempted to allow hexadecimal here, but life's too short.
Unicode translation sentences are really only technicalities needed by
the built-in extensions anyway; Inform authors never type them.

=
<translates-into-unicode-sentence-object> ::=
	<cardinal-number-unlimited> |		==> R[1]
	...									==> @<Issue PM_UnicodeNonLiteral problem@>

@<Issue PM_UnicodeNonLiteral problem@> =
	Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_UnicodeNonLiteral),
		"a Unicode character name must be translated into a literal decimal "
		"number written out in digits",
		"which this seems not to be.");
	return FALSE;

@ The following is called only on excerpts from the source where it is a
fairly safe bet that a Unicode character is referred to. For example, when
the player types either of these:

>> "[unicode 321]odz Churchyard"
>> "[unicode Latin capital letter L with stroke]odz Churchyard"

...then the text after the word "unicode" is parsed by <s-unicode-character>.

=
<s-unicode-character> ::=
	<cardinal-number-unlimited> |	==> Rvalues::from_Unicode_point(R[1], W); if (!(UnicodeTranslations::char_in_range(R[1]))) return FALSE;
	<unicode-character-name>		==> Rvalues::from_Unicode_point(R[1], W)

<unicode-character-name> internal {
	parse_node *p = ExParser::parse_excerpt(MISCELLANEOUS_MC, W);
	if ((p) && (ParseTree::get_type(p) == PROPER_NOUN_NT)) {
		*X = Vocabulary::get_literal_number_value(Lexer::word(Wordings::first_wn(ParseTree::get_text(p))));
		return TRUE;
	}
	return FALSE;
}

@ And here is the range check:

=
int UnicodeTranslations::char_in_range(int cc) {
	if ((cc < 0) || (cc >= 0x10000)) {
		Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_UnicodeOutOfRange),
			"Inform can only handle Unicode characters in the 16-bit range",
			"from 0 to 65535.");
		return FALSE;
	}
	return TRUE;
}
