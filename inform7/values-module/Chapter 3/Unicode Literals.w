[UnicodeLiterals::] Unicode Literals.

To manage the names assigned to Unicode character values.

@ The following is called only on excerpts from the source where it is a
fairly safe bet that a Unicode character is referred to. For example, when
the player types either of these:

>> "[unicode 321]odz Churchyard"
>> "[unicode Latin capital letter L with stroke]odz Churchyard"

...then the text after the word "unicode" is parsed by <s-unicode-character>.

=
<s-unicode-character> ::=
	<cardinal-number-unlimited> | ==> { -, Rvalues::from_Unicode(UnicodeLiterals::max(R[1]), W) }
	<unicode-character-name>      ==> { -, Rvalues::from_Unicode(R[1], W) }

<unicode-character-name> internal {
	parse_node *p = Lexicon::retrieve(MISCELLANEOUS_MC, W);
	if ((p) && (Node::get_type(p) == PROPER_NOUN_NT)) {
		int N = Vocabulary::get_literal_number_value(
			Lexer::word(Wordings::first_wn(Node::get_text(p))));
		==> { N, - };
		return TRUE;
	}
	==> { fail nonterminal };
}

@ And here is the range check:

=
int UnicodeLiterals::max(int cc) {
	if ((cc < 0) || (cc >= 0x10000)) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_UnicodeOutOfRange),
			"Inform can only handle Unicode characters in the 16-bit range",
			"from 0 to 65535.");
		return 65;
	}
	return cc;
}
