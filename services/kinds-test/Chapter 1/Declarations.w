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

kind *kind_vars[27];

void Declarations::load_from_file(text_stream *arg) {
	filename *F = Filenames::from_text(arg);
	feed_t FD = Feeds::begin();
	source_file *sf = TextFromFiles::feed_into_lexer(F, NULL_GENERAL_POINTER);
	wording W = Feeds::end(FD);
	if (sf == NULL) { PRINT("File has failed to open\n"); return; }
	syntax_tree = SyntaxTree::new();
	Sentences::break(syntax_tree, W);

	for (int i=1; i<=26; i++) {
		kind_vars[i] = Kinds::var_construction(i, NULL);
	}
	kind_checker_mode = MATCH_KIND_VARIABLES_AS_UNIVERSAL;

	SyntaxTree::traverse(syntax_tree, Declarations::parse);
}

@

@d KIND_VARIABLE_FROM_CONTEXT Declarations::kv

=
kind *Declarations::kv(int v) {
	return kind_vars[v];
}

void Declarations::parse(parse_node *p) {
	if (Node::get_type(p) == SENTENCE_NT) {
		wording W = Node::get_text(p);
		<declaration-line>(W);
	}
}

@

@e kind_relationship_CLASS
@d EXACT_PARSING_BITMAP (KIND_SLOW_MC)

=
DECLARE_CLASS(kind_relationship)

typedef struct kind_relationship {
	struct kind *sub;
	struct kind *super;
	CLASS_DEFINITION
} kind_relationship;


@ =
<declaration-line> ::=
	new unit <kind-eval> |                     ==> @<Kind already exists error@>
	new unit ... |                             ==> @<Create new unit@>
	new enum <kind-eval> |                     ==> @<Kind already exists error@>
	new enum ... |                             ==> @<Create new enum@>
	new kind ... of <kind-eval> |              ==> @<Create new base@>
	<kind-eval> * <kind-eval> = <kind-eval> |  ==> @<New arithmetic rule@>
	<k-formal-variable> = <kind-eval> |   ==> @<Set kind variable@>
	<kind-eval> |                              ==> @<Show REPL result@>
	<kind-condition> |                         ==> @<Show kind condition@>
	<kind-eval> compatible with <kind-eval> |  ==> @<Show compatibility@>
	... which varies |                         ==> { -, - }
	...                                        ==> @<Fail with error@>

<kind-eval> ::=
	( <kind-eval> ) |                          ==> { pass 1 }
	<kind-eval> + <kind-eval> |                ==> @<Perform plus@>
	<kind-eval> - <kind-eval> |                ==> @<Perform minus@>
	<kind-eval> * <kind-eval> |                ==> @<Perform times@>
	<kind-eval> over <kind-eval> |             ==> @<Perform divide@>
	<kind-eval> % <kind-eval> |                ==> @<Perform remainder@>
	<kind-eval> to the nearest <kind-eval> |   ==> @<Perform approx@>
	- <kind-eval> |                            ==> @<Perform unary minus@>
	square root of <kind-eval> |               ==> @<Perform square root@>
	real square root of <kind-eval> |          ==> @<Perform real square root@>
	cube root of <kind-eval> |                 ==> @<Perform cube root@>
	join of <kind-eval> and <kind-eval> |      ==> @<Perform join@>
	meet of <kind-eval> and <kind-eval> |      ==> @<Perform meet@>
	first term of <kind-eval> |                ==> @<Extract first term@>
	second term of <kind-eval> |               ==> @<Extract second term@>
	dereference <kind-eval> |                  ==> @<Dereference kind@>
	weaken <kind-eval> |                       ==> @<Weaken kind@>
	super of <kind-eval> |                     ==> @<Super kind@>
	substitute <kind-eval> for <k-formal-variable> in <kind-eval> | ==> @<Substitute@>
	void |                                     ==> { -, K_void }
	<k-kind> |                                 ==> { pass 1 }
	<k-formal-variable>                   ==> { pass 1 }

<kind-condition> ::=
	<kind-eval> <= <kind-eval> |               ==> @<Test le@>
	<kind-eval> is definite                    ==> @<Test definiteness@>

@<Show REPL result@> =
	kind *K = RP[1];
	PRINT("'%<W': %u\n", W, K);

@<Show kind condition@> =
	PRINT("'%<W?': %s\n", W, R[1]?"true":"false");

@<Show compatibility@> =
	kind *K1 = RP[1];
	kind *K2 = RP[2];
	switch (Kinds::compatible(K1, K2)) {
		case NEVER_MATCH:     PRINT("'%<W?': never\n", W); break;
		case ALWAYS_MATCH:    PRINT("'%<W?': always\n", W); break;
		case SOMETIMES_MATCH: PRINT("'%<W?': sometimes\n", W); break;
	}

@<Kind already exists error@> =
	kind *K = RP[1];
	PRINT("Kind already exists: '%u'\n", K);
	==> { fail }

@<Create new unit@> =
	kind *K = Kinds::new_base(GET_RW(<declaration-line>, 1), K_value);
	Kinds::Behaviour::convert_to_unit(K);
	PRINT("'%<W': ok\n", W);

@<Create new enum@> =
	kind *K = Kinds::new_base(GET_RW(<declaration-line>, 1), K_value);
	Kinds::Behaviour::convert_to_enumeration(K);
	PRINT("'%<W': ok\n", W);

@<Create new base@> =
	kind *X = RP[1];
	kind *K = Kinds::new_base(GET_RW(<declaration-line>, 1), X);
	kind_relationship *KR = CREATE(kind_relationship);
	KR->sub = K;
	KR->super = X;
	PRINT("'%<W': ok\n", W);

@<New arithmetic rule@> =
	kind *K1 = (kind *) RP[1];
	kind *K2 = (kind *) RP[2];
	kind *K = (kind *) RP[3];
	Kinds::Dimensions::make_unit_derivation(K1, K2, K);
	PRINT("'%<W': %u\n", W, K);

@<Set kind variable@> =
	kind *KV = RP[1];
	kind *K = RP[2];
	kind_vars[KV->kind_variable_number] = K;
	==> { -, K }
	PRINT("'%<W': %u\n", W, K);

@<No such kind error@> =
	PRINT("No such kind as '%W'\n", W);
	==> { fail }

@<Fail with error@> =
	PRINT("Declaration not understood: '%W'\n", W);
	==> { fail }

@<Perform plus@> =
	int op = PLUS_OPERATION;
	@<Perform arithmetic@>;

@<Perform minus@> =
	int op = MINUS_OPERATION;
	@<Perform arithmetic@>;

@<Perform times@> =
	int op = TIMES_OPERATION;
	@<Perform arithmetic@>;

@<Perform divide@> =
	int op = DIVIDE_OPERATION;
	@<Perform arithmetic@>;

@<Perform remainder@> =
	int op = REMAINDER_OPERATION;
	@<Perform arithmetic@>;

@<Perform approx@> =
	int op = APPROXIMATE_OPERATION;
	@<Perform arithmetic@>;

@<Perform arithmetic@> =
	kind *K1 = RP[1];
	kind *K2 = RP[2];
	==> { - , Kinds::Dimensions::arithmetic_on_kinds(K1, K2, op) }

@<Perform unary minus@> =
 	int op = NEGATE_OPERATION;
	@<Perform unary arithmetic@>;

@<Perform square root@> =
 	int op = ROOT_OPERATION;
	@<Perform unary arithmetic@>;

@<Perform real square root@> =
 	int op = REALROOT_OPERATION;
	@<Perform unary arithmetic@>;

@<Perform cube root@> =
 	int op = CUBEROOT_OPERATION;
	@<Perform unary arithmetic@>;

@<Perform unary arithmetic@> =
	kind *K = RP[1];
	==> { - , Kinds::Dimensions::arithmetic_on_kinds(K, NULL, op) }

@<Perform join@> =
	kind *K1 = RP[1];
	kind *K2 = RP[2];
	==> { - , Latticework::join(K1, K2) }

@<Perform meet@> =
	kind *K1 = RP[1];
	kind *K2 = RP[2];
	==> { - , Latticework::meet(K1, K2) }

@<Extract first term@> =
	kind *K = RP[1];
	switch (Kinds::arity_of_constructor(K)) {
		case 0: ==> { -, NULL }; break;
		case 1: ==> { -, Kinds::unary_construction_material(K) }; break;
		case 2: {
			kind *X, *Y;
			Kinds::binary_construction_material(K, &X, &Y);
			==> { -, X }; break;
		}
	}

@<Extract second term@> =
	kind *K = RP[1];
	switch (Kinds::arity_of_constructor(K)) {
		case 0: ==> { -, NULL }; break;
		case 1: ==> { -, NULL }; break;
		case 2: {
			kind *X, *Y;
			Kinds::binary_construction_material(K, &X, &Y);
			==> { -, Y }; break;
		}
	}

@<Weaken kind@> =
	kind *K = RP[1];
	==> { - , Kinds::weaken(K, K_object) }

@<Dereference kind@> =
	kind *K = RP[1];
	==> { - , Kinds::dereference_properties(K) }

@<Super kind@> =
	kind *K = RP[1];
	==> { - , Latticework::super(K) }

@<Test le@> =
	kind *K1 = RP[1];
	kind *K2 = RP[2];
	==> { Kinds::conforms_to(K1, K2), - }

@<Test definiteness@> =
	kind *K = RP[1];
	==> { Kinds::Behaviour::definite(K), - }

@<Substitute@> =
	kind *K1 = RP[1];
	kind *KV = RP[2];
	kind *K2 = RP[3];
	kind *slate[27];
	for (int i=1; i<=26; i++) slate[i] = NULL;
	slate[KV->kind_variable_number] = K1;
	int changed;
	==> { -, Kinds::substitute(K2, slate, &changed, FALSE) }

@

@d HIERARCHY_GET_SUPER_KINDS_CALLBACK Declarations::super
@d HIERARCHY_ALLOWS_SOMETIMES_MATCH_KINDS_CALLBACK Declarations::sometimes

=
int Declarations::le(kind *K1, kind *K2) {
	while (K1) {
		if (Kinds::eq(K1, K2)) return TRUE;
		K1 = Declarations::super(K1);
	}
	return FALSE;
}
kind *Declarations::super(kind *K1) {
	kind_relationship *KR;
	LOOP_OVER(KR, kind_relationship)
		if (Kinds::eq(K1, KR->sub))
			return KR->super;
	return NULL;
}
int Declarations::sometimes(kind *from) {
	while (from) {
		if (Kinds::eq(from, K_object)) return TRUE;
		from = Latticework::super(from);
	}
	return FALSE;
}
