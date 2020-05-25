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
	if ((person == THIRD_PERSON_SINGULAR) || (person == THIRD_PERSON_PLURAL)) return TRUE;
	return FALSE;
}

int Unit::allow_generally(verb_conjugation *vc, int tense, int sense, int person) {
	return TRUE;
}

@h Minimal Preform grammar.
Only |<dividing-sentence>| can ever match, since the others are wired to match
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
<stock> ::=
	verb <cardinal-number> ...	==> R[1]; *XP = Conjugation::conjugate(WordAssemblages::from_wording(FW[1]), DefaultLanguage::get(NULL));

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
	PRINT("Read %d words\n", Wordings::length(W));
	Sentences::break(syntax_tree, W);

	text_stream *save_DL = DL;
	DL = STDOUT;
	Streams::enable_debugging(DL);
	SyntaxTree::clear_trace(syntax_tree);
	SyntaxTree::traverse(syntax_tree, Unit::diagram);
	Node::log_tree(DL, syntax_tree->root_node);
	DL = save_DL;
}

void Unit::diagram(parse_node *p) {
	if (Node::get_type(p) == SENTENCE_NT) {
		wording W = Node::get_text(p);
		if (<stock>(W)) {
			verb_conjugation *vc = <<rp>>;
			int cop = FALSE;
			if (my_first_verb) { cop = TRUE; }
			verb_identity *vi = Verbs::new_verb(vc, cop);
			my_first_verb = FALSE;
			vc->vc_conjugates = vi;
			VerbUsages::register_all_usages_of_verb(vi, FALSE, <<r>>);
			if (vc_be == NULL) vc_be = vc;
			else if (vc_have == NULL) vc_have = vc;
			Verbs::add_form(vi, NULL, NULL, VerbMeanings::new(vc, NULL), SVO_FS_BIT);
		} else {
			if (<unexceptional-sentence>(W)) {
				SyntaxTree::graft(syntax_tree, <<rp>>, p);
			} else {
				PRINT("Failed: %W\n", W);
			}
		}
	}
}
