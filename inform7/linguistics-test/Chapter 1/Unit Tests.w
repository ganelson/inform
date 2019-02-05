[Unit::] Unit Tests.

A selection of tests for, or demonstrations of, syntax features.

@

= (early code)
verb_conjugation *vc_be = NULL;
verb_conjugation *vc_have = NULL;

@h What verb usages we allow.

@d ALLOW_VERB_USAGE_IN_ASSERTIONS Unit::allow_in_assertions
@d ALLOW_VERB_USAGE_GENERALLY Unit::allow_generally

=
int Unit::allow_in_assertions(verb_conjugation *vc, int tense, int sense, int person) {
	if ((person == THIRD_PERSON_SINGULAR) || (person == THIRD_PERSON_PLURAL)) return TRUE;
	return FALSE;
}

int Unit::allow_generally(verb_conjugation *vc, int tense, int sense, int person) {
	return TRUE;
}

@h

=
<dividing-sentence> ::=
	chapter ... |			==> 1
	section ...				==> 2

<structural-sentence> ::=
	...						==> TRUE; return FAIL_NONTERMINAL;

<language-modifying-sentence> ::=
	...						==> TRUE; return FAIL_NONTERMINAL;

<unexceptional-sentence> ::=
	<sentence>				==> @<Report any error@>

@<Report any error@> =
	parse_node *VP_PN = RP[1];
	if (ParseTree::int_annotation(VP_PN, linguistic_error_here_ANNOT) == TwoLikelihoods_LINERROR)
		Errors::nowhere("two certainties");
	*XP = VP_PN;

@ =
<stock> ::=
	verb <cardinal-number> ...	==> R[1]; *XP = Conjugation::conjugate(WordAssemblages::from_wording(FW[1]), English_language);

@h Syntax tree.

@e UNKNOWN_NT

=
int my_first_verb = TRUE;

void Unit::start_diagrams(void) {
	trace_sentences = TRUE;
	ParseTree::md((parse_tree_node_type) { UNKNOWN_NT, "UNKNOWN_NT", 0, INFTY, L2_NCAT, 0 });
}

void Unit::test_diagrams(text_stream *arg) {
	Streams::enable_debugging(STDOUT);
	filename *F = Filenames::from_text(arg);
	feed_t FD = Feeds::begin();
	source_file *sf = TextFromFiles::feed_into_lexer(F, NULL_GENERAL_POINTER);
	wording W = Feeds::end(FD);
	if (sf == NULL) { PRINT("File has failed to open\n"); return; }
	ParseTree::plant_parse_tree();
	PRINT("Read %d words\n", Wordings::length(W));
	Sentences::break(W, NULL);

	text_stream *save_DL = DL;
	DL = STDOUT;
	Streams::enable_debugging(DL);
	ParseTree::traverse(Unit::diagram);
	ParseTree::log_tree(DL, tree_root);
	DL = save_DL;
}

void Unit::diagram(parse_node *p) {
	if (ParseTree::get_type(p) == SENTENCE_NT) {
		wording W = ParseTree::get_text(p);
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
				ParseTree::graft(<<rp>>, p);
			} else {
				PRINT("Failed: %W\n", W);
			}
		}
	}
}
