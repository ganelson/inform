[Interpreting::] Interpreting.

Printing out diagrams of the sentences.

@ This is where we could put an interpreter or compiler; we now have a nice
tidy syntax tree to look at. Instead, we'll just print it out.

=
void Interpreting::go(parse_node_tree *syntax_tree) {
	SyntaxTree::traverse(syntax_tree, Interpreting::diagram);
}

int sentence_counter = 1;

void Interpreting::diagram(parse_node *p) {
	if (Node::get_type(p) == SENTENCE_NT) {
		text_stream *save_DL = DL;
		DL = STDOUT;
		Streams::enable_debugging(DL);
		LOG("(%d) %W\n\n", sentence_counter++, Node::get_text(p));
		Node::log_subtree(DL, p);
		LOG("\n");
		DL = save_DL;
	}
}
