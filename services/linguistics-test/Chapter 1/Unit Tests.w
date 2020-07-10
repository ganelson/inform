[Unit::] Unit Tests.

How we shall test it.

@

= (early code)
verb_conjugation *vc_be = NULL;
verb_conjugation *vc_have = NULL;

@h What verb usages we allow.

@d ALLOW_VERB_IN_ASSERTIONS_LINGUISTICS_CALLBACK Unit::allow_in_assertions
@d ALLOW_VERB_LINGUISTICS_CALLBACK Unit::allow_generally

=
int Unit::allow_in_assertions(verb_conjugation *vc, int tense, int sense, int person) {
	if (person == THIRD_PERSON) return TRUE;
	return FALSE;
}

int Unit::allow_generally(verb_conjugation *vc, int tense, int sense, int person) {
	return TRUE;
}

@h Minimal Preform grammar.
Only <dividing-sentence> can ever match, since the others are wired to match
any text but then fail.

=
<dividing-sentence> ::=
	chapter ... |  ==> 1
	section ...    ==> 2

<structural-sentence> ::=
	... ==> TRUE; return FAIL_NONTERMINAL;

<language-modifying-sentence> ::=
	... ==> TRUE; return FAIL_NONTERMINAL;

<comma-divisible-sentence> ::=
	... ==> TRUE; return FAIL_NONTERMINAL;

@

=
<unexceptional-sentence> ::=
	<sentence>				==> @<Report any error@>

@<Report any error@> =
	parse_node *VP_PN = RP[1];
	if (Annotations::read_int(VP_PN, linguistic_error_here_ANNOT) == TwoLikelihoods_LINERROR)
		Errors::nowhere("two certainties");
	*XP = VP_PN;

@ =
<verb-stock> ::=
	... = verb <cardinal-number> ==> R[1]; *XP = Conjugation::conjugate(WordAssemblages::from_wording(FW[1]), DefaultLanguage::get(NULL));

<common-noun-stock> ::=
	... = neuter common noun | ==> NEUTER_GENDER
	... = masculine common noun | ==> MASCULINE_GENDER
	... = feminine common noun ==> FEMININE_GENDER

<proper-noun-stock> ::=
	... = neuter proper noun | ==> NEUTER_GENDER
	... = masculine proper noun | ==> MASCULINE_GENDER
	... = feminine proper noun ==> FEMININE_GENDER

@h Syntax tree.

=
int my_first_verb = TRUE;

parse_node_tree *syntax_tree = NULL;
void Unit::test_diagrams(text_stream *arg) {
	Streams::enable_debugging(STDOUT);
	filename *F = Filenames::from_text(arg);
	feed_t FD = Feeds::begin();
	source_file *sf = TextFromFiles::feed_into_lexer(F, NULL_GENERAL_POINTER);
	wording W = Feeds::end(FD);
	if (sf == NULL) { PRINT("File has failed to open\n"); return; }
	syntax_tree = SyntaxTree::new();
	Sentences::break(syntax_tree, W);

	text_stream *save_DL = DL;
	DL = STDOUT;
	Streams::enable_debugging(DL);
	SyntaxTree::clear_trace(syntax_tree);
	SyntaxTree::traverse(syntax_tree, Unit::diagram);
	Unit::parse_noun_phrases(syntax_tree->root_node);
	Node::log_tree(DL, syntax_tree->root_node);
	DL = save_DL;
}

void Unit::diagram(parse_node *p) {
	if (Node::get_type(p) == SENTENCE_NT) {
		wording W = Node::get_text(p);
		if (<verb-stock>(W)) {
			verb_conjugation *vc = <<rp>>;
			int cop = FALSE;
			if (my_first_verb) { cop = TRUE; }
			verb *vi = Verbs::new_verb(vc, cop);
			my_first_verb = FALSE;
			vc->vc_conjugates = vi;
			VerbUsages::register_all_usages_of_verb(vi, FALSE, <<r>>, p);
			if (vc_be == NULL) vc_be = vc;
			else if (vc_have == NULL) vc_have = vc;
			Verbs::add_form(vi, NULL, NULL, VerbMeanings::regular(vc), SVO_FS_BIT);
		} else if (<common-noun-stock>(W)) {
			wording W = GET_RW(<common-noun-stock>, 1);
			Nouns::new_common_noun(W, <<r>>, ADD_TO_LEXICON_NTOPT + WITH_PLURAL_FORMS_NTOPT,
				NOUN_MC, NULL_GENERAL_POINTER, DefaultLanguage::get(NULL));
		} else if (<proper-noun-stock>(W)) {
			wording W = GET_RW(<proper-noun-stock>, 1);
			Nouns::new_proper_noun(W, <<r>>, ADD_TO_LEXICON_NTOPT + WITH_PLURAL_FORMS_NTOPT,
				NOUN_MC, NULL, DefaultLanguage::get(NULL));
		} else {
			if (<unexceptional-sentence>(W)) {
				parse_node *n = <<rp>>;
				SyntaxTree::graft(syntax_tree, n, p);
			} else {
				PRINT("Failed: %W\n", W);
			}
		}
	}
}

void Unit::parse_noun_phrases(parse_node *p) {
	for (; p; p = p->next) {
		if (Node::get_type(p) == PROPER_NOUN_NT) {
			parse_node *q = Lexicon::retrieve(NOUN_MC, Node::get_text(p));
			if (q) Nouns::set_node_to_be_usage_of_noun(p, Nouns::disambiguate(q, FALSE));
		}
		Unit::parse_noun_phrases(p->down);
	}
}

void Unit::test_pronouns(text_stream *arg) {
	Pronouns::create_small_word_sets();
	Pronouns::test(STDOUT);
}

void Unit::test_articles(text_stream *arg) {
	Articles::create_small_word_sets();
	Articles::test(STDOUT);
}
