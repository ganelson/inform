[Main::] Program Control.

What shall we test?

@h Main routine.

@d PROGRAM_NAME "problems-test"

@e TEST_PROBLEMS_CLSW

=
int main(int argc, char **argv) {
	Foundation::start();
	CommandLine::set_locale(argc, argv);
	WordsModule::start();
	SyntaxModule::start();
	ProblemsModule::start();

	CommandLine::declare_heading(L"problems-test: a tool for testing the problems module\n");

	CommandLine::declare_switch(TEST_PROBLEMS_CLSW, L"test-problems", 2,
		L"test that problems can be issued");

	CommandLine::read(argc, argv, NULL, &Main::respond, &Main::ignore);

	WordsModule::end();
	SyntaxModule::end();
	Foundation::end();
	ProblemsModule::end();
	return 0;
}

void Main::respond(int id, int val, text_stream *arg, void *state) {
	switch (id) {
		case TEST_PROBLEMS_CLSW: Main::load(I"Syntax.preform"); Unit::test_problems(arg); break;
	}
}

void Main::load(text_stream *leaf) {
	pathname *P = Pathnames::from_text(I"services");
	P = Pathnames::down(P, I"problems-test");
	P = Pathnames::down(P, I"Tangled");
	filename *S = Filenames::in(P, leaf);
	LoadPreform::load(S, NULL);
}

void Main::ignore(int id, text_stream *arg, void *state) {
	Errors::fatal("only switches may be used at the command line");
}
