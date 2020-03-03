[Unit::] Unit Tests.

A selection of tests for, or demonstrations of, syntax features.

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
void Unit::test_tree(text_stream *arg) {
	filename *F = Filenames::from_text(arg);
	feed_t FD = Feeds::begin();
	source_file *sf = TextFromFiles::feed_into_lexer(F, NULL_GENERAL_POINTER);
	wording W = Feeds::end(FD);
	if (sf == NULL) { PRINT("File has failed to open\n"); return; }
	ParseTree::plant_parse_tree();
	PRINT("Read %d words\n", Wordings::length(W));
	Sentences::break(W, FALSE, NULL);

	text_stream *save_DL = DL;
	DL = STDOUT;
	Streams::enable_debugging(DL);
	ParseTree::log_tree(DL, tree_root);
	DL = save_DL;
}
