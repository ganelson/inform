[Main::] Program Control.

What shall we test?

@ A simple command line:

@d PROGRAM_NAME "linguistics-test"

@e VOCABULARY_CLSW
@e TEST_DIAGRAMS_CLSW
@e RAW_DIAGRAMS_CLSW
@e TRACE_DIAGRAMS_CLSW
@e VIABILITY_DIAGRAMS_CLSW
@e SURGERY_CLSW
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
		U"linguistics-test: a tool for testing the linguistics module\n");

	CommandLine::declare_switch(TEST_DIAGRAMS_CLSW, U"diagram", 2,
		U"test sentence diagrams from text in X");
	CommandLine::declare_switch(RAW_DIAGRAMS_CLSW, U"raw", 2,
		U"test raw sentence diagrams from text in X");
	CommandLine::declare_switch(TRACE_DIAGRAMS_CLSW, U"trace", 2,
		U"test raw sentence diagrams from text in X with tracing on");
	CommandLine::declare_switch(VIABILITY_DIAGRAMS_CLSW, U"viability", 2,
		U"show viability map for sentences in X");
	CommandLine::declare_switch(SURGERY_CLSW, U"surgery", 2,
		U"show surgeries performed on sentences in X");
	CommandLine::declare_switch(VOCABULARY_CLSW, U"vocabulary", 2,
		U"read vocabulary from file X for use in -diagram tests");
	CommandLine::declare_switch(TEST_ARTICLES_CLSW, U"test-articles", 2,
		U"test pronoun stock (ignoring X)");
	CommandLine::declare_switch(TEST_PRONOUNS_CLSW, U"test-pronouns", 2,
		U"test pronoun stock (ignoring X)");

	CommandLine::read(argc, argv, NULL, &Main::respond, &Main::ignore);

	WordsModule::end();
	InflectionsModule::end();
	SyntaxModule::end();
	LexiconModule::end();
	LinguisticsModule::end();
	Foundation::end();
	return 0;
}

@ |-trace| turns all verb phrase tracing on; |-viability| just shows the
viability map for each sentence.

@d TRACING_LINGUISTICS_CALLBACK Main::trace_parsing

=
int trace_diagrams_mode = FALSE;
int viability_diagrams_mode = FALSE;
int surgery_mode = FALSE;
int Main::trace_parsing(int A) {
	if (trace_diagrams_mode) return trace_diagrams_mode;
	if (A == VIABILITY_VP_TRACE) return viability_diagrams_mode;
	if (A == SURGERY_VP_TRACE) return surgery_mode;
	return FALSE;
}

@ =
void Main::respond(int id, int val, text_stream *arg, void *state) {
	text_stream *save_DL = DL;
	DL = STDOUT;
	Streams::enable_debugging(DL);
	switch (id) {
		case VOCABULARY_CLSW: Banking::load_from_file(arg); break;
		case TRACE_DIAGRAMS_CLSW:
			trace_diagrams_mode = TRUE;
			Diagramming::test_diagrams(arg, TRUE);
			break;
		case VIABILITY_DIAGRAMS_CLSW:
			viability_diagrams_mode = TRUE;
			Diagramming::test_diagrams(arg, TRUE);
			break;
		case SURGERY_CLSW:
			surgery_mode = TRUE;
			Diagramming::test_diagrams(arg, TRUE);
			break;
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
	DL = save_DL;
}

void Main::ignore(int id, text_stream *arg, void *state) {
	Errors::fatal("only switches may be used at the command line");
}
