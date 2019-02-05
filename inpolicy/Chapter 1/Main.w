[Main::] Main.

The top level, which decides what is to be done and then carries
this plan out.

@h Main routine.

@e SILENCE_CLSW
@e PROBLEMS_CLSW
@e ADVANCE_CLSW

=
int return_happy = TRUE, silence_mode = FALSE;

int main(int argc, char **argv) {
	Foundation::start();

	CommandLine::declare_heading(
		L"[[Purpose]]\n\n"
		L"usage: inpolicy [options]\n");

	CommandLine::declare_boolean_switch(SILENCE_CLSW, L"silence", 1,
		L"print nothing unless there's something wrong");
	CommandLine::declare_switch(PROBLEMS_CLSW, L"check-problems", 1,
		L"check problem test case coverage");
	CommandLine::declare_switch(ADVANCE_CLSW, L"advance-build", 2,
		L"increment daily build code for web X");

	CommandLine::read(argc, argv, NULL, &Main::respond, &Main::disallow);

	Foundation::end();
	if (return_happy) return 0; else return 1;
}

void Main::disallow(int id, text_stream *arg, void *state) {
	Errors::fatal("no arguments are allowed at the command line");
}

@

@d RUNTEST(Routine)
	if (silence_mode) {
		if (Routine(NULL) == FALSE) { return_happy = FALSE; Routine(STDERR); }
	} else {
		if (Routine(STDOUT) == FALSE) return_happy = FALSE;
	}

=
void Main::respond(int id, int val, text_stream *arg, void *state) {
	switch (id) {
		case ADVANCE_CLSW: Inversion::maintain(arg); break;
		case PROBLEMS_CLSW: RUNTEST(Coverage::check); break;
		case SILENCE_CLSW: silence_mode = val; break;
	}
}
