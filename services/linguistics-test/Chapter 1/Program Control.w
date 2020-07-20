[Main::] Program Control.

What shall we test?

@ A simple command line:

@d PROGRAM_NAME "linguistics-test"

@e VOCABULARY_CLSW
@e TEST_DIAGRAMS_CLSW
@e RAW_DIAGRAMS_CLSW
@e TEST_ARTICLES_CLSW
@e TEST_PRONOUNS_CLSW

=
int main(int argc, char **argv) {
	Foundation::start(argc, argv);
	WordsModule::start();
	InflectionsModule::start();
	SyntaxModule::start();
	LexiconModule::start();
	LinguisticsModule::start();

	pathname *P = Pathnames::from_text(I"services");
	P = Pathnames::down(P, I"linguistics-test");
	P = Pathnames::down(P, I"Tangled");
	filename *S = Filenames::in(P, I"Syntax.preform");
	LoadPreform::load(S, NULL);

	CommandLine::declare_heading(
		L"linguistics-test: a tool for testing the linguistics module\n");

	CommandLine::declare_switch(TEST_DIAGRAMS_CLSW, L"diagram", 2,
		L"test sentence diagrams from text in X");
	CommandLine::declare_switch(RAW_DIAGRAMS_CLSW, L"raw", 2,
		L"test raw sentence diagrams from text in X");
	CommandLine::declare_switch(VOCABULARY_CLSW, L"vocabulary", 2,
		L"read vocabulary from file X for use in -diagram tests");
	CommandLine::declare_switch(TEST_ARTICLES_CLSW, L"test-articles", 2,
		L"test pronoun stock (ignoring X)");
	CommandLine::declare_switch(TEST_PRONOUNS_CLSW, L"test-pronouns", 2,
		L"test pronoun stock (ignoring X)");

	CommandLine::read(argc, argv, NULL, &Main::respond, &Main::ignore);

	WordsModule::end();
	InflectionsModule::end();
	SyntaxModule::end();
	LexiconModule::end();
	LinguisticsModule::end();
	Foundation::end();
	return 0;
}

void Main::respond(int id, int val, text_stream *arg, void *state) {
	switch (id) {
		case VOCABULARY_CLSW: Banking::load_from_file(arg); break;
		case RAW_DIAGRAMS_CLSW:
			Interpreting::go(Diagramming::test_diagrams(arg, TRUE));
			break;
		case TEST_DIAGRAMS_CLSW:
			Interpreting::go(Diagramming::test_diagrams(arg, FALSE));
			break;
		case TEST_ARTICLES_CLSW:
			Articles::create_small_word_sets();
			Articles::test(STDOUT);
			break;
		case TEST_PRONOUNS_CLSW:
			Pronouns::create_small_word_sets();
			Pronouns::test(STDOUT);
			break;
	}
}

void Main::ignore(int id, text_stream *arg, void *state) {
	Errors::fatal("only switches may be used at the command line");
}
