[Main::] Program Control.

What shall we test?

@h Main routine.

@d PROGRAM_NAME "building-test"

@

= (early code)
typedef void kind;
kind *K_value = NULL;

@

@e TEST_CLSW

=
int main(int argc, char **argv) {
	Foundation::start(argc, argv);
	WordsModule::start();
	BuildingModule::start();
	BytecodeModule::start();

	CommandLine::declare_heading(L"building-test: a tool for testing the building module\n");

	CommandLine::declare_switch(TEST_CLSW, L"test", 2,
		L"perform unit tests from file X");

	CommandLine::read(argc, argv, NULL, &Main::respond, &Main::ignore);

	WordsModule::end();
	BuildingModule::end();
	BytecodeModule::end();
	Foundation::end();
	return 0;
}

void Main::respond(int id, int val, text_stream *arg, void *state) {
	switch (id) {
		case TEST_CLSW: Unit::run(Filenames::from_text(arg)); break;
	}
}

void Main::ignore(int id, text_stream *arg, void *state) {
	Errors::fatal("only switches may be used at the command line");
}
