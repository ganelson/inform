[Main::] Program Control.

What shall we test?

@h Main routine.

@d PROGRAM_NAME "linguistics-test"

@d VERB_MEANING_EQUALITY vc_be
@d VERB_MEANING_POSSESSION vc_have

@e TEST_DIAGRAMS_CLSW

=
int main(int argc, char **argv) {
	Foundation::start();
	WordsModule::start();
	InflectionsModule::start();
	SyntaxModule::start();
	LinguisticsModule::start();

	Unit::start_diagrams();

	CommandLine::declare_heading(L"linguistics-test: a tool for testing the linguistics module\n");

	CommandLine::declare_switch(TEST_DIAGRAMS_CLSW, L"test-diagrams", 2,
		L"test sentence diagrams (from text in X)");

	CommandLine::read(argc, argv, NULL, &Main::respond, &Main::ignore);

	WordsModule::end();
	InflectionsModule::end();
	SyntaxModule::end();
	LinguisticsModule::end();
	Foundation::end();
	return 0;
}

void Main::respond(int id, int val, text_stream *arg, void *state) {
	switch (id) {
		case TEST_DIAGRAMS_CLSW: Main::load(I"Syntax.preform"); Unit::test_diagrams(arg); break;
	}
}

void Main::load(text_stream *leaf) {
	pathname *P = Pathnames::from_text(I"inform7");
	P = Pathnames::down(P, I"linguistics-test");
	P = Pathnames::down(P, I"Tangled");
	filename *S = Filenames::in(P, leaf);
	wording W = Preform::load_from_file(S);
	Preform::parse_preform(W, FALSE);
}

void Main::ignore(int id, text_stream *arg, void *state) {
	Errors::fatal("only switches may be used at the command line");
}
