[SParser::] Enter the S-Parser.

The top-level nonterminals of the S-parser, which turns text into specifications.

@h Introduction.
The purpose of the S-parser is to turn excerpts of text into specification
nodes. Nonterminals here almost all have names beginning with the "s-" prefix,
which indicates that their results are specifications. The simplest example is:

=
<s-plain-text> internal {
	==> { -, Specifications::new_UNKNOWN(W) };
	return TRUE;
}

@ And here is a curious variation, which is needed because equations are
parsed with completely different spacing rules, and don't respect word
boundaries. It matches any non-empty text where one of the words contains an
equals sign as one of its characters.

=
<s-plain-text-with-equals> internal {
	LOOP_THROUGH_WORDING(i, W) {
		wchar_t *p = Lexer::word_raw_text(i);
		for (int j=0; p[j]; j++)
			if (p[j] == '=') {
				==> { -, Specifications::new_UNKNOWN(W) };
				return TRUE;
			}
	}
	==> { fail nonterminal };
}

@h Top-level nonterminals.
These five nonterminals are the most useful and powerful, so they're the
main junction between the S-parser and the rest of Inform.

These are coded as internals for efficiency's sake. We will often reparse the
same wording over and over, so we cache the results. But <s-value> matches
exactly the same text as <s-value-uncached>, and so on for the other four.

<s-value> looks for source text which can be evaluated -- a constant, a
variable or other storage object, or a phrase to decide a value.

=
<s-value> internal {
	parse_node *spec = PreformCache::parse(W, 0, <s-value-uncached>);
	if (Node::is(spec, UNKNOWN_NT)) { ==> { fail nonterminal }; }
	==> { -, spec };
	return TRUE;
}

@ <s-condition> looks for a condition -- anything legal after an
"if", in short. This includes sentence-like excerpts such as "six
animals have been in the Stables".

=
<s-condition> internal {
	LocalVariables::make_necessary_callings(W);
	parse_node *spec = PreformCache::parse(W, 1, <s-condition-uncached>);
	if (Node::is(spec, UNKNOWN_NT)) { ==> { fail nonterminal }; }
	==> { -, spec };
	return TRUE;
}

@ <s-non-action-condition> is the same, but disallowing action patterns
as conditions, so for example "taking something" would not match.

=
<s-non-action-condition> internal {
	LocalVariables::make_necessary_callings(W);
	#ifdef IF_MODULE
	int old_state = ParseActionPatterns::enter_mode(SUPPRESS_AP_PARSING);
	#endif
	parse_node *spec = PreformCache::parse(W, 2, <s-condition-uncached>);
	#ifdef IF_MODULE
	ParseActionPatterns::restore_mode(old_state);
	#endif
	if (Node::is(spec, UNKNOWN_NT)) { ==> { fail nonterminal }; }
	==> { -, spec };
	return TRUE;
}

@ <s-type-expression> is for where we expect to find the "type" of something
-- for instance, the kind of value to be stored in a variable, or the
specification of a phrase argument.

=
<s-type-expression> internal {
	parse_node *spec = PreformCache::parse(W, 3, <s-type-expression-uncached>);
	if (Node::is(spec, UNKNOWN_NT)) { ==> { fail nonterminal }; }
	==> { -, spec };
	return TRUE;
}

@ <s-descriptive-type-expression> is the same thing, with one difference: it
allows nounless descriptions, such as "open opaque fixed in place", and to
this end it treats bare adjective names as descriptions rather than values. If
we have said "Colour is a kind of value. The colours are red, green and taupe.
A thing has a colour.", then "green" is parsed by <s-descriptive-type-expression>
as a description meaning "any thing which is green", but by <s-type-expression>
and <s-value> as a constant value of the kind "colour".

=
<s-descriptive-type-expression> internal {
	parse_node *spec =
		PreformCache::parse(W, 4, <s-descriptive-type-expression-uncached>);
	if (Node::is(spec, UNKNOWN_NT)) { ==> { fail nonterminal }; }
	==> { -, spec };
	return TRUE;
}

@ The following internal is just a shell for <s-descriptive-type-expression>,
but it temporarily changes the parsing mode to phrase token parsing, so that
kind variables will be read as formal prototypes.

=
<s-phrase-token-type> internal {
	int s = kind_parsing_mode;
	kind_parsing_mode = PHRASE_TOKEN_KIND_PARSING;
	int t = <s-descriptive-type-expression>(W);
	kind_parsing_mode = s;
	if (t) { ==> { <<r>>, <<rp>> }; return TRUE; }
	==> { fail nonterminal };
}

@ We will also define a convenient super-nonterminal which matches almost any
meaningful reference to data, so it's a convenient way of finding out whether
a new name will clash with some existing meaning.

=
<s-type-expression-or-value> ::=
	<s-type-expression> |  ==> { pass 1 }
	<s-value>              ==> { pass 1 }

@h Void phrases.
The S-parser is also used by the main code compiler to turn phrases into
S-nodes, using <s-command> and <s-say-command>. These however need a
wrapper: instead of turning text into an S-node, we take text from an
existing node (in the structural parse tree for a routine), turn that
into a new S-node with an invocation list below it, then glue the list
back into the original tree but throw away the S-node head.

=
void SParser::parse_void_phrase(parse_node *p) {
	SParser::parse_phrase_inner(p, FALSE);
}
void SParser::parse_say_term(parse_node *p) {
	SParser::parse_phrase_inner(p, TRUE);
}
void SParser::parse_phrase_inner(parse_node *p, int as_say_term) {
	if (p == NULL) internal_error("no node to parse");
	p->down = NULL;
	if (Wordings::nonempty(Node::get_text(p))) {
		parse_node *results = NULL;
		if ((as_say_term == FALSE) && (<s-command>(Node::get_text(p)))) results = <<rp>>;
		if ((as_say_term) && (<s-say-command>(Node::get_text(p)))) results = <<rp>>;
		if ((results) && (results->down)) p->down = results->down->down;
	}
}

@h Actions.
These are meaningful only for interactive fiction, and serve the "if" module:

=
<s-explicit-action> internal {
	#ifdef IF_MODULE
	parse_node *S = NULL;
	int saved = ParseActionPatterns::enter_mode(PERMIT_TRYING_OMISSION);
	if (<s-condition-uncached>(W)) S = <<rp>>;
	ParseActionPatterns::restore_mode(saved);
	if (S) {
		if (Rvalues::is_CONSTANT_of_kind(S, K_stored_action)) {
			==> { -, S };
			return TRUE;
		} else if (AConditions::is_action_TEST_VALUE(S)) {
			==> { -, S->down };
			return TRUE;
		} else {
			==> { fail nonterminal };
		}
	}
	#endif
	==> { fail nonterminal };
}

<s-constant-action> internal {
	#ifdef IF_MODULE
	parse_node *S = NULL;
	int was = ParseActionPatterns::enter_mode(
		FORBID_NONCONSTANT_ACTION_PARAMETERS + PERMIT_TRYING_OMISSION);
	if (<s-condition-uncached>(W)) S = <<rp>>;
	ParseActionPatterns::restore_mode(was);
	if (S) {
		if (Rvalues::is_CONSTANT_of_kind(S, K_stored_action)) {
			==> { -, S };
			return TRUE;
		} else if (AConditions::is_action_TEST_VALUE(S)) {
			==> { -, S->down };
			return TRUE;
		} else {
			==> { fail nonterminal };
		}
	}
	#endif
	==> { fail nonterminal };
}
