[Main::] Program Control.

What shall we test?

@h Main routine.

@d PROGRAM_NAME "arch-test"

@e TEST_COMPATIBILITY_CLSW

=
int main(int argc, char **argv) {
	Foundation::start(argc, argv);
	ArchModule::start();

	CommandLine::declare_heading(U"inexample: a tool for testing foundation facilities\n");

	CommandLine::declare_switch(TEST_COMPATIBILITY_CLSW, U"test-compatibility", 2,
		U"test compatibility checks against various target VMs");

	CommandLine::read(argc, argv, NULL, &Main::respond, &Main::ignore);

	ArchModule::end();
	Foundation::end();
	return 0;
}

void Main::respond(int id, int val, text_stream *arg, void *state) {
	switch (id) {
		case TEST_COMPATIBILITY_CLSW: Unit::test_compatibility(STDOUT); break;
	}
}

void Main::ignore(int id, text_stream *arg, void *state) {
	Errors::fatal("only switches may be used at the command line");
}
