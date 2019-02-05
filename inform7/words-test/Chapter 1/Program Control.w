[Main::] Program Control.

The top level, which decides what is to be done and then carries
this plan out.

@h Main routine.

@e TEST_LEXER_CLSW
@e TEST_PREFORM_CLSW

=
int main(int argc, char **argv) {
	Foundation::start();
	WordsModule::start();

	CommandLine::declare_heading(L"inexample: a tool for testing foundation facilities\n");

	CommandLine::declare_switch(TEST_LEXER_CLSW, L"test-lexer", 2,
		L"test lexing of natural language text from file X");
	CommandLine::declare_switch(TEST_PREFORM_CLSW, L"test-preform", 2,
		L"test Preform parsing a sample grammar against the text in file X");

	CommandLine::read(argc, argv, NULL, &Main::respond, &Main::ignore);

	WordsModule::end();
	Foundation::end();
	return 0;
}

void Main::respond(int id, int val, text_stream *arg, void *state) {
	switch (id) {
		case TEST_LEXER_CLSW: Unit::test_lexer(arg); break;
		case TEST_PREFORM_CLSW: Unit::test_preform(arg); break;
	}
}

void Main::ignore(int id, text_stream *arg, void *state) {
	Errors::fatal("only switches may be used at the command line");
}
