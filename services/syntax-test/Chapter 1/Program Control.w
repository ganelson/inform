[Main::] Program Control.

What shall we test?

@h Main routine.

@d PROGRAM_NAME "syntax-test"

@e TEST_TREE_CLSW

=
int main(int argc, char **argv) {
	Foundation::start();
	CommandLine::set_locale(argc, argv);
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
	pathname *P = Pathnames::from_text(I"services");
	P = Pathnames::down(P, I"syntax-test");
	P = Pathnames::down(P, I"Tangled");
	filename *S = Filenames::in(P, leaf);
	LoadPreform::load(S, NULL);
}

void Main::ignore(int id, text_stream *arg, void *state) {
	Errors::fatal("only switches may be used at the command line");
}
