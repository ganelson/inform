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

@h Loading kinds.

=
void Declarations::load_kinds(text_stream *arg) {
	filename *F = Filenames::from_text(arg);
	TextFiles::read(F, FALSE, "unable to read kinds file", TRUE,
		&Declarations::load_kinds_helper, NULL, NULL);
}

void Declarations::load_kinds_helper(text_stream *text, text_file_position *tfp, void *state) {
	if ((Str::get_first_char(text) == '!') ||
		(Str::get_first_char(text) == 0)) return; /* skip blanks and comments */
	Kinds::Interpreter::despatch_kind_command(NULL, text);
}

@h Loading from a file.
The following function reads a file whose name is in |arg|, feeds it into
the lexer, builds a syntax tree of its sentences, and then walks through
that tree, applying the Preform nonterminal <declaration-line> to each
sentence.

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
	SyntaxTree::traverse(syntax_tree, Declarations::parse);
}

void Declarations::parse(parse_node *p) {
	if (Node::get_type(p) == SENTENCE_NT) {
		wording W = Node::get_text(p);
		<declaration-line>(W);
	}
}

@

@e symbol_CLASS
@d SYMBOL_MC 0x80
@d EXACT_PARSING_BITMAP
	(SYMBOL_MC + KIND_SLOW_MC)

=
DECLARE_CLASS(symbol)

typedef struct symbol {
	wording symbol_name;
	kind *symbol_kind;
	CLASS_DEFINITION
} symbol;

@ =
<declaration-line> ::=
	new unit <k-kind> |                                   ==> @<Kind already exists error@>
	new unit ... |                                        ==> @<Create new unit@>
	new enum <k-kind> |                                   ==> @<Kind already exists error@>
	new enum ... |                                        ==> @<Create new enum@>
	<k-kind> * <k-kind> = <k-kind> |                      ==> @<New arithmetic rule@>
	<existing-symbol> = ... |                             ==> @<Symbol already exists error@>
	... = <existing-kind> |                               ==> @<Create symbol@>
	<existing-symbol> + <existing-symbol> |               ==> @<Show plus@>
	<existing-symbol> - <existing-symbol> |               ==> @<Show minus@>
	<existing-symbol> * <existing-symbol> |               ==> @<Show times@>
	<existing-symbol> over <existing-symbol> |            ==> @<Show divide@>
	<existing-symbol> % <existing-symbol> |               ==> @<Show remainder@>
	<existing-symbol> to the nearest <existing-symbol> |  ==> @<Show approx@>
	- <existing-symbol> |                                 ==> @<Show unary minus@>
	square root of <existing-symbol> |                    ==> @<Show square root@>
	real square root of <existing-symbol> |               ==> @<Show real square root@>
	cube root of <existing-symbol> |                      ==> @<Show cube root@>
	<existing-symbol> |                                   ==> @<Show symbol@>
	... which varies |                                    ==> { -, - }
	...                                                   ==> @<Fail with error@>

<existing-kind> ::=
	<k-kind> |  ==> { pass 1 }
	...         ==> @<No such kind error@>;

<existing-symbol> internal {
	parse_node *results = Lexicon::retrieve(SYMBOL_MC, W);
	if (results) {
		symbol *S = RETRIEVE_POINTER_symbol(Lexicon::get_data(Node::get_meaning(results)));
		if (S) { ==> { -, S }; return TRUE; }
	}
	==> { fail nonterminal };
}

@<Kind already exists error@> =
	kind *K = RP[1];
	PRINT("Kind already exists: '%u'\n", K);
	==> { fail }

@<Create new unit@> =
	kind *K = Kinds::new_base(syntax_tree, GET_RW(<declaration-line>, 1), K_value);
	Kinds::Behaviour::convert_to_unit(syntax_tree, K);

@<Create new enum@> =
	kind *K = Kinds::new_base(syntax_tree, GET_RW(<declaration-line>, 1), K_value);
	Kinds::Behaviour::convert_to_enumeration(syntax_tree, K);

@<New arithmetic rule@> =
	kind *K1 = (kind *) RP[1];
	kind *K2 = (kind *) RP[2];
	kind *K = (kind *) RP[3];
	Kinds::Dimensions::make_unit_derivation(K1, K2, K);
	@<Show result@>;

@<Symbol already exists error@> =
	symbol *S = RP[1];
	PRINT("Symbol already exists: '%W'\n", S->symbol_name);
	==> { fail }

@<Create symbol@> =
	kind *K = RP[1];
	symbol *S = CREATE(symbol);
	S->symbol_name = GET_RW(<declaration-line>, 1);
	S->symbol_kind = K;
	Lexicon::register(SYMBOL_MC, S->symbol_name, STORE_POINTER_symbol(S));
	@<Show result@>;

@<Show symbol@> =
	symbol *S = RP[1];
	kind *K = S->symbol_kind;
	@<Show result@>;

@<Show plus@> =
	int op = PLUS_OPERATION;
	@<Show arithmetic@>;

@<Show minus@> =
	int op = MINUS_OPERATION;
	@<Show arithmetic@>;

@<Show times@> =
	int op = TIMES_OPERATION;
	@<Show arithmetic@>;

@<Show divide@> =
	int op = DIVIDE_OPERATION;
	@<Show arithmetic@>;

@<Show remainder@> =
	int op = REMAINDER_OPERATION;
	@<Show arithmetic@>;

@<Show approx@> =
	int op = APPROXIMATION_OPERATION;
	@<Show arithmetic@>;

@<Show arithmetic@> =
	symbol *S1 = RP[1];
	symbol *S2 = RP[2];
	kind *K = Kinds::Dimensions::arithmetic_on_kinds(S1->symbol_kind, S2->symbol_kind, op);
	@<Show result@>;

@<Show unary minus@> =
 	int op = UNARY_MINUS_OPERATION;
	@<Show unary arithmetic@>;

@<Show square root@> =
 	int op = ROOT_OPERATION;
	@<Show unary arithmetic@>;

@<Show real square root@> =
 	int op = REALROOT_OPERATION;
	@<Show unary arithmetic@>;

@<Show cube root@> =
 	int op = CUBEROOT_OPERATION;
	@<Show unary arithmetic@>;

@<Show unary arithmetic@> =
	symbol *S1 = RP[1];
	kind *K = Kinds::Dimensions::arithmetic_on_kinds(S1->symbol_kind, NULL, op);
	@<Show result@>;

@<Show result@> =
	PRINT("'%W': %u\n", W, K);

@<No such kind error@> =
	PRINT("No such kind as '%W'\n", W);
	==> { fail }

@<Fail with error@> =
	PRINT("Declaration not understood: '%W'\n", W);
	==> { fail }
