[Main::] Main.

The top level, which decides what is to be done and then carries
this plan out.

@h Main routine.

@d INTOOL_NAME "inbuild"

=
int main(int argc, char **argv) {
	Foundation::start();
	@<Read the command line@>;
	Foundation::end();
	return 0;
}

@ We use Foundation to read the command line:

@<Read the command line@> =	
	CommandLine::declare_heading(
		L"[[Purpose]]\n\n"
		L"usage: inbuild\n");

	CommandLine::read(argc, argv, NULL, &Main::option, &Main::bareword);

@ =
void Main::option(int id, int val, text_stream *arg, void *state) {
}

void Main::bareword(int id, text_stream *arg, void *state) {
}
