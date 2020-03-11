[Main::] Program Control.

The top level, which decides what is to be done and then carries
this plan out.

@h Main routine.

@e TEST_TREE_CLSW

=
int main(int argc, char **argv) {
	Foundation::start();
	WordsModule::start();
	SyntaxModule::start();

	CommandLine::declare_heading(L"syntax-test: a tool for testing the syntax module\n");

	CommandLine::declare_switch(TEST_TREE_CLSW, L"test-tree", 2,
		L"test the syntax tree (from text in X)");

	CommandLine::read(argc, argv, NULL, &Main::respond, &Main::ignore);

	WordsModule::end();
	SyntaxModule::end();
	Foundation::end();
	return 0;
}

void Main::respond(int id, int val, text_stream *arg, void *state) {
	switch (id) {
		case TEST_TREE_CLSW: Main::load(I"Syntax.preform"); Unit::test_tree(arg); break;
	}
}

void Main::load(text_stream *leaf) {
	pathname *P = Pathnames::from_text(I"inform7");
	P = Pathnames::subfolder(P, I"syntax-test");
	P = Pathnames::subfolder(P, I"Tangled");
	filename *S = Filenames::in_folder(P, leaf);
	wording W = Preform::load_from_file(S);
	Preform::parse_preform(W, FALSE);
}

void Main::ignore(int id, text_stream *arg, void *state) {
	Errors::fatal("only switches may be used at the command line");
}
