[Main::] Program Control.

What shall we test?

@h Main routine.

@d PROGRAM_NAME "linguistics-test"

@d VERB_MEANING_EQUALITY vc_be
@d VERB_MEANING_POSSESSION vc_have

@e TEST_DIAGRAMS_CLSW
@e TEST_PRONOUNS_CLSW

=
int main(int argc, char **argv) {
	Foundation::start(argc, argv);
	WordsModule::start();
	InflectionsModule::start();
	SyntaxModule::start();
	LexiconModule::start();
	LinguisticsModule::start();

	CommandLine::declare_heading(L"linguistics-test: a tool for testing the linguistics module\n");

	CommandLine::declare_switch(TEST_DIAGRAMS_CLSW, L"test-diagrams", 2,
		L"test sentence diagrams (from text in X)");
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
		case TEST_DIAGRAMS_CLSW: Main::load(I"Syntax.preform"); Unit::test_diagrams(arg); break;
		case TEST_PRONOUNS_CLSW: Main::load(I"Syntax.preform"); Unit::test_pronouns(arg); break;
	}
}

void Main::load(text_stream *leaf) {
	pathname *P = Pathnames::from_text(I"services");
	P = Pathnames::down(P, I"linguistics-test");
	P = Pathnames::down(P, I"Tangled");
	filename *S = Filenames::in(P, leaf);
	LoadPreform::load(S, NULL);
}

void Main::ignore(int id, text_stream *arg, void *state) {
	Errors::fatal("only switches may be used at the command line");
}
