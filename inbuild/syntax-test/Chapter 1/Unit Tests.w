[Unit::] Unit Tests.

How we shall test it.

@h

=
<dividing-sentence> ::=
	chapter ... |			==> 1
	section ...				==> 2

<structural-sentence> ::=
	...						==> TRUE; return FAIL_NONTERMINAL;

<language-modifying-sentence> ::=
	...						==> TRUE; return FAIL_NONTERMINAL;

@h Syntax tree.

=
parse_node_tree *syntax_tree = NULL;

void Unit::test_tree(text_stream *arg) {
	filename *F = Filenames::from_text(arg);
	feed_t FD = Feeds::begin();
	source_file *sf = TextFromFiles::feed_into_lexer(F, NULL_GENERAL_POINTER);
	wording W = Feeds::end(FD);
	if (sf == NULL) { PRINT("File has failed to open\n"); return; }
	syntax_tree = ParseTree::new_tree();
	PRINT("Read %d words\n", Wordings::length(W));
	Sentences::break(syntax_tree, W);

	text_stream *save_DL = DL;
	DL = STDOUT;
	Streams::enable_debugging(DL);
	ParseTree::log_tree(DL, syntax_tree->root_node);
	DL = save_DL;
}
