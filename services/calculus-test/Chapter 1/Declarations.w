[Declarations::] Declarations.

Reading declarations from a file.

@h Keeping the syntax module happy.
We are going to need to use the sentence-breaking apparatus from the //syntax//
module, which means that the following four nonterminals need to exist. But in
fact they are really just placeholders -- they are wired so that they can never
match any text.

=
<dividing-sentence> ::=
	... ==> { fail }

<structural-sentence> ::=
	... ==> { fail }

<language-modifying-sentence> ::=
	... ==> { fail }

<comma-divisible-sentence> ::=
	... ==> { fail }

@h REPL variables.

@e repl_var_CLASS
@e named_function_CLASS

=
DECLARE_CLASS(repl_var)
DECLARE_CLASS(named_function)

typedef struct repl_var {
	struct wording name;
	struct pcalc_prop *val;
	CLASS_DEFINITION
} repl_var;

typedef struct named_function {
	struct wording name;
	struct binary_predicate *bp;
	int side;
	CLASS_DEFINITION
} named_function;

<new-repl-variable> internal {
	repl_var *rv;
	LOOP_OVER(rv, repl_var)
		if (Wordings::match(rv->name, W)) {
			==> { -, rv }; return TRUE;
		}
	rv = CREATE(repl_var);
	rv->val = NULL;
	rv->name = W;
	==> { -, rv }; return TRUE;
}

<repl-variable> internal {
	repl_var *rv;
	LOOP_OVER(rv, repl_var)
		if (Wordings::match(rv->name, W)) {
			==> { -, rv }; return TRUE;
		}
	return FALSE;
}

<named-function> internal {
	named_function *nf;
	LOOP_OVER(nf, named_function)
		if (Wordings::match(nf->name, W)) {
			==> { -, nf }; return TRUE;
		}
	return FALSE;
}

@h A sort of REPL.
The following function reads a file whose name is in |arg|, feeds it into
the lexer, builds a syntax tree of its sentences, and then walks through
that tree, applying the Preform nonterminal <declaration-line> to each
sentence. In effect, this is a read-evaluate-print loop.

=
parse_node_tree *syntax_tree = NULL;
text_stream *test_err = NULL;

void Declarations::load_from_file(text_stream *arg) {
	filename *F = Filenames::from_text(arg);
	feed_t FD = Feeds::begin();
	source_file *sf = TextFromFiles::feed_into_lexer(F, NULL_GENERAL_POINTER);
	wording W = Feeds::end(FD);
	if (sf == NULL) { PRINT("File has failed to open\n"); return; }
	syntax_tree = SyntaxTree::new();
	Sentences::break(syntax_tree, W);
	BinaryPredicateFamilies::first_stock();
	test_err = Str::new();
	SyntaxTree::traverse(syntax_tree, Declarations::parse);
}

void Declarations::parse(parse_node *p) {
	if (Node::get_type(p) == SENTENCE_NT) {
		wording W = Node::get_text(p);
		<declaration-line>(W);
	}
}

@ =
<declaration-line> ::=
	new unary ### |                            ==> @<Create new unary@>
	new binary ### ( ### , ### ) |             ==> @<Create new binary@>
	set <new-repl-variable> to <evaluation> |  ==> @<Set REPL var@>
	term <term> |                              ==> @<Show term@>
	constant underlying <term> |               ==> @<Show const underlying@>
	variable underlying <term> |               ==> @<Show var underlying@>
	<evaluation> |                             ==> @<Show result@>
	<test> |                                   ==> @<Show result of test@>
	...                                        ==> @<Fail with error@>

<evaluation> ::=
	( <evaluation> ) |                         ==> { pass 1 }
	<evaluation> concatenate <evaluation> |    ==> { -, Calculus::Propositions::concatenate(RP[1], RP[2]) }
	<evaluation> conjoin <evaluation> |        ==> { -, Calculus::Propositions::conjoin(RP[1], RP[2]) }
	<repl-variable> |                          ==> { -, Calculus::Propositions::copy(((repl_var *) RP[1])->val) }
	<proposition>                              ==> { pass 1 }

<test> ::=
	<evaluation> is syntactically valid |      ==> { Calculus::Propositions::is_syntactically_valid(RP[1], test_err), - }
	<evaluation> is well-formed                ==> { Calculus::Variables::is_well_formed(RP[1], test_err), - }

<proposition> ::=
	<< <atoms> >> |              ==> { pass 1 }
	<< <quantification> >> |                   ==> { pass 1 }
	<< >>                                      ==> { -, NULL }

<atoms> ::=
	<quantification> \: <atoms> |      ==> { -, Calculus::Propositions::concatenate(RP[1], RP[2]) }
	<quantification> in< <atoms> in> \: <atoms> |  ==> @<Make domain@>;
	not< <atoms> not> |                ==> { -, Calculus::Propositions::negate(RP[1]) }
	<atomic-proposition> \^ <atoms> |  ==> { -, Calculus::Propositions::concatenate(RP[1], RP[2]) }
	<atomic-proposition>                             ==> { pass 1 }

<atomic-proposition> ::=
	<adjective-name> ( <term> ) |              ==> { -, Atoms::from_adjective(RP[1], FALSE, *((pcalc_term *) RP[2])) }
	( <term> == <term> ) |                     ==> { -, Atoms::binary_PREDICATE_new(R_equality, *((pcalc_term *) RP[1]), *((pcalc_term *) RP[2])) }
	<relation-name> ( <term> , <term> ) |      ==> { -, Atoms::binary_PREDICATE_new(RP[1], *((pcalc_term *) RP[2]), *((pcalc_term *) RP[3])) }
	kind = <k-kind> ( <term> ) |               ==> { -, Atoms::KIND_new(RP[1], *((pcalc_term *) RP[2])) }
	called = ... ( <term> ) |                  ==> { -, Atoms::CALLED_new(WR[1], *((pcalc_term *) RP[1]), NULL) }
	everywhere ( <term> ) |                    ==> { -, Atoms::EVERYWHERE_new(*((pcalc_term *) RP[1])) }
	nowhere ( <term> ) |                       ==> { -, Atoms::NOWHERE_new(*((pcalc_term *) RP[1])) }
	here ( <term> ) |                          ==> { -, Atoms::HERE_new(*((pcalc_term *) RP[1])) }
	is-a-kind ( <term> ) |                     ==> { -, Atoms::ISAKIND_new(*((pcalc_term *) RP[1]), NULL) }
	is-a-var ( <term> ) |                      ==> { -, Atoms::ISAVAR_new(*((pcalc_term *) RP[1])) }
	is-a-const ( <term> ) |                    ==> { -, Atoms::ISACONST_new(*((pcalc_term *) RP[1])) }
	not< |                                     ==> { -, Atoms::new(NEGATION_OPEN_ATOM) }
	not> |                                     ==> { -, Atoms::new(NEGATION_CLOSE_ATOM) }
	in< |                                      ==> { -, Atoms::new(DOMAIN_OPEN_ATOM) }
	in>                                        ==> { -, Atoms::new(DOMAIN_CLOSE_ATOM) }

<term> ::=
	<pcvar> |                                  ==> { -, Declarations::stash(Terms::new_variable(R[1])) }
	<cardinal-number> |                        ==> { -, Declarations::stash(Terms::new_constant(Declarations::number_to_value(W, R[1]))) }
	<named-function> ( <term> )                ==> { -, Declarations::stash(Terms::new_function(((named_function *) RP[1])->bp, *((pcalc_term *) RP[2]), ((named_function *) RP[1])->side)) }

<quantification> ::=
	<quantifier> <pcvar>                       ==> { -, Atoms::QUANTIFIER_new(RP[1], R[2], R[1]) }

<quantifier> ::=
	ForAll |                                   ==> { 0, for_all_quantifier }
	NotAll |                                   ==> { 0, not_for_all_quantifier }
	Exists |                                   ==> { 0, exists_quantifier }
	DoesNotExist |                             ==> { 0, not_exists_quantifier }
	AllBut <cardinal-number> |                 ==> { R[1], all_but_quantifier }
	NotAllBut <cardinal-number> |              ==> { R[1], not_all_but_quantifier }
	Proportion>=80% |                          ==> { R[1], almost_all_quantifier }
	Proportion<20% |                           ==> { R[1], almost_no_quantifier }
	Proportion>50% |                           ==> { R[1], most_quantifier }
	Proportion<=50% |                          ==> { R[1], under_half_quantifier }
	Card>= <cardinal-number> |                 ==> { R[1], at_least_quantifier }
	Card<= <cardinal-number> |                 ==> { R[1], at_most_quantifier }
	Card= <cardinal-number> |                  ==> { R[1], exactly_quantifier }
	Card< <cardinal-number> |                  ==> { R[1], less_than_quantifier }
	Card> <cardinal-number> |                  ==> { R[1], more_than_quantifier }
	Card~= <cardinal-number>                   ==> { R[1], other_than_quantifier }

<pcvar> ::=
	x |                                        ==> { 0, - }
	y |                                        ==> { 1, - }
	z                                          ==> { 2, - }

@<Make domain@> =
	==> { -, Calculus::Propositions::quantify_using(RP[1], RP[2], RP[3]) }

@<Create new unary@> =
	Adjectives::declare(GET_RW(<declaration-line>, 1), NULL);
	PRINT("'%<W': ok\n", W);

@<Create new binary@> =
	Declarations::new(GET_RW(<declaration-line>, 1),
		K_number, GET_RW(<declaration-line>, 2), K_number, GET_RW(<declaration-line>, 3));
	PRINT("'%<W': ok\n", W);

@<Set REPL var@> =
	pcalc_prop *P = RP[2];
	repl_var *rv = RP[1];
	rv->val = P;
	PRINT("'%<W': %W set to ", W, rv->name);
	Calculus::Propositions::write(STDOUT, P);
	PRINT("\n");

@<Show term@> =
	pcalc_term *T = RP[1];
	PRINT("'%<W': ", W);
	Terms::write(STDOUT, T);
	PRINT("\n");

@<Show const underlying@> =
	pcalc_term *T = RP[1];
	PRINT("'%<W': ", W);
	parse_node *val = Terms::constant_underlying(T);
	if (val == NULL) PRINT("--"); else PRINT("'%W'", Node::get_text(val));
	PRINT("\n");

@<Show var underlying@> =
	pcalc_term *T = RP[1];
	PRINT("'%<W': ", W);
	int v = Terms::variable_underlying(T);
	if (v < 0) PRINT("--"); else PRINT("%c", pcalc_vars[v]);
	PRINT("\n");

@<Show result@> =
	pcalc_prop *P = RP[1];
	PRINT("'%<W': ", W);
	Calculus::Propositions::write(STDOUT, P);
	PRINT("\n");

@<Show result of test@> =
	PRINT("'%<W': ", W);
	if (R[1]) PRINT("true"); else {
		PRINT("false");
		if (Str::len(test_err) > 0) PRINT(" - %S", test_err);
	}
	Str::clear(test_err);
	PRINT("\n");

@<Fail with error@> =
	PRINT("Declaration not understood: '%W'\n", W);
	==> { fail }

@ =
bp_family *test_bp_family = NULL;

void Declarations::new(wording W, kind *k0, wording f0, kind *k1, wording f1) {
	if (test_bp_family == NULL)
		test_bp_family = BinaryPredicateFamilies::new();
	bp_term_details t0 =
		BinaryPredicates::new_term(TERM_DOMAIN_FROM_KIND_FUNCTION(k0));
	bp_term_details t1 =
		BinaryPredicates::new_term(TERM_DOMAIN_FROM_KIND_FUNCTION(k1));
	text_stream *S = Str::new();
	WRITE_TO(S, "%W", W);
	binary_predicate *bp =
		BinaryPredicates::make_pair(test_bp_family, t0, t1, S, NULL, NULL,
			Calculus::Schemas::new("%S(*1, *2)", S),
			WordAssemblages::from_wording(W));
	TEMPORARY_TEXT(f0n)
	TEMPORARY_TEXT(f1n)
	WRITE_TO(f0n, "%W", f0);
	WRITE_TO(f1n, "%W", f1);
	if (Str::ne(f0n, I"none")) {
		named_function *nf = CREATE(named_function);
		nf->bp = bp;
		nf->name = f0;
		nf->side = 1;
		BinaryPredicates::set_term_function(&(bp->term_details[0]),
			Calculus::Schemas::new("%S(*1)", f0n));
	}
	if (Str::ne(f1n, I"none")) {
		named_function *nf = CREATE(named_function);
		nf->bp = bp;
		nf->name = f1;
		nf->side = 0;
		BinaryPredicates::set_term_function(&(bp->term_details[1]),
			Calculus::Schemas::new("%S(*1)", f1n));
	}
	DISCARD_TEXT(f0n)
	DISCARD_TEXT(f1n)
}

int stashed = 0;
pcalc_term stashed_terms[1000];

pcalc_term *Declarations::stash(pcalc_term t) {
	if (stashed == 1000) internal_error("too many terms in test case");
	stashed_terms[stashed] = t;
	return &(stashed_terms[stashed++]);
}

parse_node *Declarations::number_to_value(wording W, int n) {
	return Diagrams::new_UNPARSED_NOUN(W);
}
