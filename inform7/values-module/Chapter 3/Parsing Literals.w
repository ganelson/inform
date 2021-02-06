[Literals::] Parsing Literals.

To decide if an excerpt of text is a value referred to notationally
rather than by name.

@ The nonterminal <s-literal> matches any literal, and on success produces
an rvalue specification for the given value. Note that not every constant
is a literal: names of objects, or of rules, for example, are not literals
but they are certainly constants.

Note also that ordinal numbers are not valid as literals: "2nd" is not a noun.

=
<s-literal> ::=
	<cardinal-number> |                    ==> { -, Rvalues::from_int(R[1], W) }
	minus <cardinal-number> |              ==> { -, Rvalues::from_int(-R[1], W) }
	<quoted-text> ( <response-letter> ) |  ==> { -, Rvalues::from_wording(W) }
	<quoted-text> |                        ==> { -, Rvalues::from_wording(W) }
	<s-literal-real-number> |              ==> { pass 1 }
	<s-literal-truth-state> |              ==> { pass 1 }
	<s-literal-list> |                     ==> { pass 1 }
	unicode <s-unicode-character> |        ==> { pass 1 }
	<s-literal-time> |                     ==> { pass 1 }
	<s-literal-unit-notation>              ==> { pass 1 }

@ Response letters A to Z mark certain texts as being responses. These are only
meaningful (and allowed) in the body of rules, but are syntactically valid as
literals anywhere.

=
<response-letter> internal 1 {
	wchar_t *p = Lexer::word_raw_text(Wordings::first_wn(W));
	if ((p) && (p[0] >= 'A') && (p[0] <= 'Z') && (p[1] == 0)) {
		==> { p[0]-'A', - };
		return TRUE;
	}
	==> { fail nonterminal };
}

@ It might seem odd that the truth states count as literals, whereas names of
instances of other kinds (people, say) do not. The argument for this is that
there are always necessarily exactly two truth states, whereas there could
in principle be any number of people, colours, vehicles, and such.

=
<s-literal-truth-state> ::=
	false |  ==> { -, Rvalues::from_boolean(FALSE, W) }
	true     ==> { -, Rvalues::from_boolean(TRUE, W) }
