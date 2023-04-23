[Unit::] Unit Tests.

How we shall test it.

@h Minimal Preform grammar.
Only |<dividing-sentence>| can ever match, since the others are wired to match
any text but then fail.

=
<dividing-sentence> ::=
	volume ... |                        ==> { 1, - }
	book ... |                          ==> { 2, - }
	part ... |                          ==> { 3, - }
	chapter ... |                       ==> { 4, - }
	section ... ( dialog ) |            ==> { 6, - }
	section ... ( dialogue ) |          ==> { 6, - }
	section ...                         ==> { 5, - }

<structural-sentence> ::=
	... ==> { fail }

<language-modifying-sentence> ::=
	... ==> { fail }

<comma-divisible-sentence> ::=
	... ==> { fail }

@h Syntax tree.

=
parse_node_tree *syntax_tree = NULL;

void Unit::test_tree(text_stream *arg) {
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
	Node::log_tree(DL, syntax_tree->root_node);
	DL = save_DL;
}
