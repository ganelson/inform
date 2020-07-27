[BasicNT::] Basic Nonterminals.

A handful of bare minimum Preform syntax.

@h Nonterminal names.
This is a typical internal nonterminal being defined, though it's a bit more
meta than most -- it's a nonterminal which matches against the name of any
nonterminal. (This is used only to parse inclusion requests for the debugging
log.)

Note that we use the |internal 1| to signal that a correct match must have
exactly one word.

=
<preform-nonterminal> internal 1 {
	nonterminal *nt = Nonterminals::detect(Lexer::word(Wordings::first_wn(W)));
	if (nt) { *XP = nt; return TRUE; }
	return FALSE;
}

@h Text positions.
A useful nonterminal which matches no text, but detects the position:

=
<if-start-of-paragraph> internal 0 {
	int w1 = Wordings::first_wn(W);
	if ((w1 == 0) || (compare_word(w1-1, PARBREAK_V))) return TRUE;
	return FALSE;
}

@ And another convenience:

=
<if-not-cap> internal 0 {
	int w1 = Wordings::first_wn(W);
	if (Word::unexpectedly_upper_case(w1) == FALSE) return TRUE;
	return FALSE;
}

@h Balancing.
The following regular (not internal!) nonterminal matches any text in which
braces and brackets are correctly paired.

=
<balanced-text> ::=
	......

@ Inform contains relatively few syntaxes where commas are actually required,
though they can optionally be used in many lists, as here:

>> parma ham, camembert, grapes

But for when we only want to spot comma placements, this can be used. Note
that the comma matches only if not in brackets.

=
<list-comma-division> ::=
	...... , ......

@h Literal numbers.
(Inform itself doesn't use this, but has alternatives for cardinals and
ordinals within the VM-representable range.)

=
<any-integer> internal 1 {
	if (Vocabulary::test_flags(Wordings::first_wn(W), NUMBER_MC)) {
		*X = Vocabulary::get_literal_number_value(Lexer::word(Wordings::first_wn(W)));
		return TRUE;
	}
	return FALSE;
}

@h Literal text.
Text is "with substitutions" if it contains square brackets, used in Inform
for interpolations called "text substitutions".

=
<quoted-text> internal 1 {
	if ((Wordings::nonempty(W)) &&
		(Vocabulary::test_flags(Wordings::first_wn(W), TEXT_MC+TEXTWITHSUBS_MC))) {
		*X = Wordings::first_wn(W); return TRUE;
	}
	return FALSE;
}

<quoted-text-with-subs> internal 1 {
	if ((Wordings::nonempty(W)) &&
		(Vocabulary::test_flags(Wordings::first_wn(W), TEXTWITHSUBS_MC))) {
		*X = Wordings::first_wn(W); return TRUE;
	}
	return FALSE;
}

<quoted-text-without-subs> internal 1 {
	if ((Wordings::nonempty(W)) &&
		(Vocabulary::test_flags(Wordings::first_wn(W), TEXT_MC))) {
		*X = Wordings::first_wn(W); return TRUE;
	}
	return FALSE;
}

@ For finicky technical reasons the easiest way to detect an empty piece
of text |""| is to provide a nonterminal matching it:

=
<empty-text> internal 1 {
	if ((Wordings::nonempty(W)) &&
		(Word::compare_by_strcmp(Wordings::first_wn(W), L"\"\""))) {
		*X = Wordings::first_wn(W); return TRUE;
	}
	return FALSE;
}
