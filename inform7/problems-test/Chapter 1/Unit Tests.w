[Unit::] Unit Tests.

A selection of tests for, or demonstrations of, problems features.

@h

=
parse_node_tree *syntax_tree = NULL;

<dividing-sentence> ::=
	chapter ... |			==> 1
	section ...				==> 2

<structural-sentence> ::=
	...						==> TRUE; return FAIL_NONTERMINAL;

<language-modifying-sentence> ::=
	...						==> TRUE; return FAIL_NONTERMINAL;

<scan-individual-phrase> ::=
	... banana ...			==> @<Issue PM_UnexpectedFruit problem@>;

@<Issue PM_UnexpectedFruit problem@> =
	Problems::quote_wording(1, W);
	Problems::Issue::handmade_problem(syntax_tree, _p_(PM_UnexpectedFruit));
	Problems::issue_problem_segment(
		"The sentence '%1' contained an unexpected fruit item, and now supper "
		"will be ruined.");
	Problems::issue_problem_end();

@h Syntax tree.

=
void Unit::test_problems(text_stream *arg) {
	filename *F = Filenames::from_text(arg);
	feed_t FD = Feeds::begin();
	source_file *sf = TextFromFiles::feed_into_lexer(F, NULL_GENERAL_POINTER);
	wording W = Feeds::end(FD);
	if (sf == NULL) { PRINT("File has failed to open\n"); return; }
	syntax_tree = ParseTree::new_tree();
	PRINT("Read %d words\n", Wordings::length(W));
	Sentences::break(syntax_tree, W, FALSE, NULL, -1);

	ParseTree::traverse(syntax_tree, Unit::scan_tree);
}

void Unit::scan_tree(parse_node *p) {
	if (ParseTree::get_type(p) == SENTENCE_NT) {
		wording W = ParseTree::get_text(p);
		<scan-individual-phrase>(W);
	}
}
