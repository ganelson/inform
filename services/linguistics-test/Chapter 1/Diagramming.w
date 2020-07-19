[Diagramming::] Diagramming.

Turning a file of natural language into a syntax tree.

@ Everything is now set up to read in a text file, break it into sentences,
and then hand each one to //linguistics// in turn to construct syntax diagrams.

We need to tell //linguistics// which parts of a verb we will allow in these
sentences -- the answer being, all of them. (Inform is more restrictive.)

@d ALLOW_VERB_IN_ASSERTIONS_LINGUISTICS_CALLBACK Diagramming::allow_in_assertions

=
int Diagramming::allow_in_assertions(verb_conjugation *vc, int tense, int sense, int person) {
	return TRUE;
}

@ And so here goes.

=
parse_node_tree *syntax_tree = NULL;
parse_node_tree *Diagramming::test_diagrams(text_stream *arg) {
	syntax_tree = SyntaxTree::new();
	@<Turn the file into a syntax tree@>;
	@<Use the linguistics module on each sentence@>;
	return syntax_tree;
}

@<Turn the file into a syntax tree@> =
	filename *F = Filenames::from_text(arg);
	feed_t FD = Feeds::begin();
	source_file *sf = TextFromFiles::feed_into_lexer(F, NULL_GENERAL_POINTER);
	wording W = Feeds::end(FD);
	if (sf == NULL) { PRINT("File has failed to open\n"); return NULL; }
	Sentences::break(syntax_tree, W);

@<Use the linguistics module on each sentence@> =	
	SyntaxTree::traverse(syntax_tree, Diagramming::diagram);
	Diagramming::parse_noun_phrases(syntax_tree->root_node);

@ The work of the //words// and //syntax// modules means that we now have a
rudimentary syntax tree, in which each sentence is just a single |SENTENCE_NT|
node without children. We look for these, and apply <sentence>, the most
powerful nonterminal from the //linguistics// module, to them. All being well
(i.e., if any sentence structure can be found), this returns a subtree of
further nodes, which we graft below the |SENTENCE_NT|.

=
void Diagramming::diagram(parse_node *p) {
	if (Node::get_type(p) == SENTENCE_NT) {
		wording W = Node::get_text(p);
		if (<sentence>(W)) {
			parse_node *n = <<rp>>;
			if (Annotations::read_int(p, linguistic_error_here_ANNOT) == TwoLikelihoods_LINERROR)
				Errors::nowhere("sentence has two certainties");
			else
				SyntaxTree::graft(syntax_tree, n, p);
		} else {
			Errors::nowhere("sentence failed to parse");
		}
	}
}

@ That sorts out the verbs and prepositions, but the noun phrases are not
by default parsed: they are simply left as |UNPARSED_NOUN_NT| nodes.

=
void Diagramming::parse_noun_phrases(parse_node *p) {
	for (; p; p = p->next) {
		if (Node::get_type(p) == UNPARSED_NOUN_NT) {
			parse_node *q = Lexicon::retrieve(NOUN_MC, Node::get_text(p));
			if (q) Nouns::set_node_to_be_usage_of_noun(p, Nouns::disambiguate(q, FALSE));
		}
		Diagramming::parse_noun_phrases(p->down);
	}
}
