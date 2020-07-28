[ExParser::] Architecture of the S-Parser.

Top-level structure of the S-parser, which turns text into S-nodes.

@h Introduction.
The purpose of the S-parser is to turn excerpts of text into specification
nodes. Nonterminals here almost all have names beginning with the "s-" prefix,
which indicates that their results are S-nodes.

The simplest nonterminal in the S-grammar is <s-plain-text>, which
accepts any non-empty piece of text. (The same can be said exactly of
<np-unparsed>, and the difference is purely to do with how Inform stores
the results: <np-unparsed> makes nodes in the main parse tree, a rather
permanent structure, whereas <s-plain-text> makes an S-node.)

=
<s-plain-text> internal {
	*XP = Specifications::new_UNKNOWN(W);
	return TRUE;
}

@ And here is a curious variation, which is needed because equations are
parsed with completely different spacing rules, and don't respect words. It
matches any non-empty text where one of the words contains an equals sign
as one of its characters: thus

>> V = fl
>> F=ma

both match this, the first example being three words long, the second only one.

=
<s-plain-text-with-equals> internal {
	LOOP_THROUGH_WORDING(i, W) {
		wchar_t *p = Lexer::word_raw_text(i);
		for (int j=0; p[j]; j++)
			if (p[j] == '=') {
				*XP = Specifications::new_UNKNOWN(W);
				return TRUE;
			}
	}
	return FALSE;
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
	parse_node *spec = ExParser::parse_with_cache(W, 0, <s-value-uncached>);
	if (Node::is(spec, UNKNOWN_NT)) return FALSE;
	*XP = spec;
	return TRUE;
}

@ <s-condition> looks for a condition -- anything legal after an
"if", in short. This includes sentence-like excerpts such as "six
animals have been in the Stables".

=
<s-condition> internal {
	LocalVariables::make_necessary_callings(W);
	parse_node *spec = ExParser::parse_with_cache(W, 1, <s-condition-uncached>);
	if (Node::is(spec, UNKNOWN_NT)) return FALSE;
	*XP = spec;
	return TRUE;
}

@ <s-non-action-condition> is the same, but disallowing action patterns
as conditions, so for example "taking something" would not match.

=
<s-non-action-condition> internal {
	LocalVariables::make_necessary_callings(W);
	#ifdef IF_MODULE
	int old_state = PL::Actions::Patterns::suppress();
	#endif
	parse_node *spec = ExParser::parse_with_cache(W, 2, <s-condition-uncached>);
	#ifdef IF_MODULE
	PL::Actions::Patterns::resume(old_state);
	#endif
	if (Node::is(spec, UNKNOWN_NT)) return FALSE;
	*XP = spec;
	return TRUE;
}

@ <s-type-expression> is for where we expect to find the "type" of something
-- for instance, the kind of value to be stored in a variable, or the
specification of a phrase argument.

=
<s-type-expression> internal {
	parse_node *spec = ExParser::parse_with_cache(W, 3, <s-type-expression-uncached>);
	if (Node::is(spec, UNKNOWN_NT)) return FALSE;
	*XP = spec;
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
	parse_node *spec = ExParser::parse_with_cache(W, 4, <s-descriptive-type-expression-uncached>);
	if (Node::is(spec, UNKNOWN_NT)) return FALSE;
	*XP = spec;
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
	if (t) { *X = <<r>>; *XP = <<rp>>; }
	return t;
}

@ That's it for the cached nonterminals, but we will also define a convenient
super-nonterminal which matches almost any meaningful reference to data, so
it's frequently used as a way of finding out whether a new name will clash
with some existing meaning.

=
<s-type-expression-or-value> ::=
	<s-type-expression> |  ==> { pass 1 }
	<s-value>              ==> { pass 1 }

@ One further convenience is for text which describes an explicit action in
a noun-like way.

=
<s-explicit-action> internal {
	#ifdef IF_MODULE
	parse_node *S = NULL;
	int p = permit_trying_omission;
	permit_trying_omission = TRUE;
	if (<s-condition-uncached>(W)) S = <<rp>>;
	permit_trying_omission = p;
	if (S) {
		if (Rvalues::is_CONSTANT_of_kind(S, K_stored_action)) {
			*XP = S; return TRUE;
		} else if (Conditions::is_TEST_ACTION(S)) {
			*XP = S->down;
			return TRUE;
		} else return FALSE;
	}
	#endif
	return FALSE;
}

<s-constant-action> internal {
	#ifdef IF_MODULE
	parse_node *S = NULL;
	int p = permit_trying_omission;
	permit_trying_omission = TRUE;
	int p2 = permit_nonconstant_action_parameters;
	permit_nonconstant_action_parameters = FALSE;
	if (<s-condition-uncached>(W)) S = <<rp>>;
	permit_trying_omission = p;
	permit_nonconstant_action_parameters = p2;
	if (S) {
		if (Rvalues::is_CONSTANT_of_kind(S, K_stored_action)) {
			*XP = S; return TRUE;
		} else if (Conditions::is_TEST_ACTION(S)) {
			*XP = S->down;
			return TRUE;
		} else return FALSE;
	}
	#endif
	return FALSE;
}

@h The cache.
The above nonterminals are called pretty frequently on overlapping or
coinciding runs of text. Inform runs substantially faster if the results of
parsing the most recent expressions are cached; so, for instance, if Inform
parses the text in words 507 to 511 once, it need not do so again in the same
context.

@ The cache takes the form of a modest ring buffer for each of the contexts:

@d MAXIMUM_CACHE_SIZE 20 /* a Goldilocks value: too high slows us down, too low doesn't cache enough */
@d NUMBER_OF_CACHED_NONTERMINALS 5

=
typedef struct expression_cache {
	struct expression_cache_entry pe_cache[MAXIMUM_CACHE_SIZE];
	int pe_cache_size; /* number of entries used, 0 to |MAXIMUM_CACHE_SIZE| */
	int pe_cache_posn; /* next write position, 0 to |pe_cache_size| minus 1 */
} expression_cache;

typedef struct expression_cache_entry {
	struct wording cached_query; /* the word range whose parsing this is */
	struct parse_node *cached_result; /* and the result (quite possibly |UNKNOWN_NT|) */
} expression_cache_entry;

int expression_cache_has_been_used = FALSE;
expression_cache contextual_cache[NUMBER_OF_CACHED_NONTERMINALS];

@ =
parse_node *ExParser::parse_with_cache(wording W, int context, nonterminal *nt) {
	if (Wordings::empty(W)) return Specifications::new_UNKNOWN(W);
	if ((context < 0) || (context >= NUMBER_OF_CACHED_NONTERMINALS))
		internal_error ("bad expression parsing context");
	@<Check the expression cache to see if we already know the answer@>;

	int unwanted = 0; parse_node *spec = NULL;
	int plm = preform_lookahead_mode;
	preform_lookahead_mode = FALSE;
	if (Preform::parse_nt_against_word_range(nt, W, &unwanted, (void **) &spec)) {
		if (Wordings::empty(Node::get_text(spec))) Node::set_text(spec, W);
	} else spec = Specifications::new_UNKNOWN(W);
	preform_lookahead_mode = plm;

	@<Write the newly discovered specification to the cache for future use@>;
	VerifyTree::verify_structure_from(spec);

	return spec;
}

@ The following seeks a previously cached answer:

@<Check the expression cache to see if we already know the answer@> =
	expression_cache *ec = &(contextual_cache[context]);
	if (expression_cache_has_been_used == FALSE) {
		ExParser::warn_expression_cache(); /* this empties all the caches */
		expression_cache_has_been_used = TRUE;
	}
	for (int i=0; i<ec->pe_cache_size; i++)
		if (Wordings::eq(W, ec->pe_cache[i].cached_query))
			return ec->pe_cache[i].cached_result;

@ The cache expands until it reaches |MAXIMUM_CACHE_SIZE|; after that,
entries are written in a position cycling through the ring. In either case
it takes |MAXIMUM_CACHE_SIZE| further parses (not found in the cache) to
overwrite the one we put down now.

@<Write the newly discovered specification to the cache for future use@> =
	expression_cache *ec = &(contextual_cache[context]);
	ec->pe_cache[ec->pe_cache_posn].cached_query = W;
	ec->pe_cache[ec->pe_cache_posn].cached_result = spec;
	ec->pe_cache_posn++;
	if (ec->pe_cache_size < MAXIMUM_CACHE_SIZE) ec->pe_cache_size++;
	if (ec->pe_cache_posn == MAXIMUM_CACHE_SIZE) ec->pe_cache_posn = 0;

@ As with all caches, we have to be careful that the information does not fall
out of date. There are two things which can go wrong: the S-node in the cache
might be altered, perhaps as a result of the type-checker trying to force a
round peg into a square hole; or the stock of Inform's defined names might
change, so that the same text now has to be read differently.

The first problem can't be fixed here. It's tempting to try something like
flagging S-nodes which have been altered, and then ensuring that the
cache never serves up an altered result. But that fails for timing reasons --
by the time the S-node might be altered, pointers to it may exist
in multiple data structures already, because the cache might have served
it more than once by that time. (Not just a theoretical possibility -- tests
show that this does, albeit rarely, happen.) The brute force solution is to
serve a copy of the cache entry, and thus never send out the same pointer
twice. But this more than doubles the memory required to store S-nodes,
which is unacceptable, and also slows Inform down, because allocating memory
for all those copies is laborious. We therefore just have to be very careful
about modifying S-nodes which have arisen from parsing.

The second problem is easier. We require other parts of Inform which make
or unmake name definitions to warn us, by calling this routine. Definitions
are made and unmade relatively rarely, so the performance hit is small.

=
void ExParser::warn_expression_cache(void) {
	for (int i=0; i<NUMBER_OF_CACHED_NONTERMINALS; i++) {
		contextual_cache[i].pe_cache_size = 0;
		contextual_cache[i].pe_cache_posn = 0;
	}
}

@h Void phrases.
The S-parser is also used by the main code compiler to turn phrases into
S-nodes, using <s-command> and <s-say-command>. These however need a
wrapper: instead of turning text into an S-node, we take text from an
existing node (in the structural parse tree for a routine), turn that
into a new S-node with an invocation list below it, then glue the list
back into the original tree but throw away the S-node head.

=
void ExParser::parse_void_phrase(parse_node *p) {
	ExParser::parse_phrase_inner(p, FALSE);
}
void ExParser::parse_say_term(parse_node *p) {
	ExParser::parse_phrase_inner(p, TRUE);
}
void ExParser::parse_phrase_inner(parse_node *p, int as_say_term) {
	if (p == NULL) internal_error("no node to parse");
	p->down = NULL;
	if (Wordings::nonempty(Node::get_text(p))) {
		parse_node *results = NULL;
		if ((as_say_term == FALSE) && (<s-command>(Node::get_text(p)))) results = <<rp>>;
		if ((as_say_term) && (<s-say-command>(Node::get_text(p)))) results = <<rp>>;
		if ((results) && (results->down)) p->down = results->down->down;
	}
}
