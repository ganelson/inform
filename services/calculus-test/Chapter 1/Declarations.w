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

@h A sort of REPL.
The following function reads a file whose name is in |arg|, feeds it into
the lexer, builds a syntax tree of its sentences, and then walks through
that tree, applying the Preform nonterminal <declaration-line> to each
sentence. In effect, this is a read-evaluate-print loop.

=
parse_node_tree *syntax_tree = NULL;

void Declarations::load_from_file(text_stream *arg) {
	filename *F = Filenames::from_text(arg);
	feed_t FD = Feeds::begin();
	source_file *sf = TextFromFiles::feed_into_lexer(F, NULL_GENERAL_POINTER);
	wording W = Feeds::end(FD);
	if (sf == NULL) { PRINT("File has failed to open\n"); return; }
	syntax_tree = SyntaxTree::new();
	Sentences::break(syntax_tree, W);
	BinaryPredicateFamilies::first_stock();
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
	new unary ... |                            ==> @<Create new unary@>
	new binary ... |                           ==> @<Create new binary@>
	<result> |                                 ==> @<Show result@>
	...                                        ==> @<Fail with error@>

<result> ::=
	<proposition> concatenate <proposition> |  ==> { -, Calculus::Propositions::concatenate(RP[1], RP[2]) }
	<proposition> conjoin <proposition> |      ==> { -, Calculus::Propositions::conjoin(RP[1], RP[2]) }
	<proposition>                              ==> { pass 1 }

<proposition> ::=
	<< <atomic-propositions> >> |              ==> { pass 1 }
	<< <quantification> >> |                   ==> { pass 1 }
	<< >>                                      ==> { -, NULL }

<atomic-propositions> ::=
	<quantification> \: <atomic-propositions> |      ==> { -, Calculus::Propositions::concatenate(RP[1], RP[2]) }
	<atomic-proposition> \^ <atomic-propositions> |  ==> { -, Calculus::Propositions::concatenate(RP[1], RP[2]) }
	<atomic-proposition>                             ==> { pass 1 }

<atomic-proposition> ::=
	<adjective-name> ( <term> ) |              ==> { -, Calculus::Atoms::unary_PREDICATE_from_aph_term(RP[1], FALSE, *((pcalc_term *) RP[2])) }
	( <term> == <term> ) |                     ==> { -, Calculus::Atoms::binary_PREDICATE_new(R_equality, *((pcalc_term *) RP[1]), *((pcalc_term *) RP[2])) }
	<relation-name> ( <term> , <term> ) |      ==> { -, Calculus::Atoms::binary_PREDICATE_new(RP[1], *((pcalc_term *) RP[2]), *((pcalc_term *) RP[3])) }
	kind = <k-kind> ( <term> ) |               ==> { -, Calculus::Atoms::KIND_new(RP[1], *((pcalc_term *) RP[2])) }
	called = ... ( <term> ) |                  ==> { -, Calculus::Atoms::CALLED_new(WR[1], *((pcalc_term *) RP[1]), NULL) }
	everywhere ( <term> ) |                    ==> { -, Calculus::Atoms::EVERYWHERE_new(*((pcalc_term *) RP[1])) }
	nowhere ( <term> ) |                       ==> { -, Calculus::Atoms::NOWHERE_new(*((pcalc_term *) RP[1])) }
	here ( <term> ) |                          ==> { -, Calculus::Atoms::HERE_new(*((pcalc_term *) RP[1])) }
	is-a-kind ( <term> ) |                     ==> { -, Calculus::Atoms::ISAKIND_new(*((pcalc_term *) RP[1]), NULL) }
	is-a-var ( <term> ) |                      ==> { -, Calculus::Atoms::ISAVAR_new(*((pcalc_term *) RP[1])) }
	is-a-const ( <term> )                      ==> { -, Calculus::Atoms::ISACONST_new(*((pcalc_term *) RP[1])) }

<term> ::=
	<pcvar>                                    ==> { -, Declarations::stash(Calculus::Terms::new_variable(R[1])) }

<quantification> ::=
	<quantifier> <pcvar>                       ==> { -, Calculus::Atoms::QUANTIFIER_new(RP[1], R[2], R[1]) }

<quantifier> ::=
	exists |                                   ==> { 0, exists_quantifier }
	forall                                     ==> { 0, for_all_quantifier }

<pcvar> ::=
	x |                                        ==> { 0, - }
	y |                                        ==> { 1, - }
	z                                          ==> { 2, - }

@<Create new unary@> =
	Adjectives::declare(GET_RW(<declaration-line>, 1), NULL);
	PRINT("'%<W': ok\n", W);

@<Create new binary@> =
	Declarations::new(GET_RW(<declaration-line>, 1));
	PRINT("'%<W': ok\n", W);

@<Show result@> =
	pcalc_prop *P = RP[1];
	PRINT("'%<W': ", W);
	Calculus::Propositions::write(STDOUT, P);
	PRINT("\n");

@<Fail with error@> =
	PRINT("Declaration not understood: '%W'\n", W);
	==> { fail }

@ =
bp_family *test_bp_family = NULL;

void Declarations::new(wording W) {
	if (test_bp_family == NULL)
		test_bp_family = BinaryPredicateFamilies::new();
	bp_term_details number_term =
		BinaryPredicates::new_term(TERM_DOMAIN_FROM_KIND_FUNCTION(K_number));
	text_stream *S = Str::new();
	WRITE_TO(S, "%W", W);
	BinaryPredicates::make_pair(test_bp_family,
		number_term, number_term,
		S, NULL, NULL, Calculus::Schemas::new("%S(*1, *2)", S),
		WordAssemblages::from_wording(W));
}

int stashed = 0;
pcalc_term stashed_terms[1000];

pcalc_term *Declarations::stash(pcalc_term t) {
	if (stashed == 1000) internal_error("too many terms in test case");
	stashed_terms[stashed] = t;
	return &(stashed_terms[stashed++]);
}
