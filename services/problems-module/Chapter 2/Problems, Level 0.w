[ProblemSigils::] Problems, Level 0.

To handle fatal errors and establish how problem sigils work.

@h Sudden exits.
In my beginning is my end: this lowest level of the error-handling system
deals with systemic collapses, and it begins with the exit itself. Note that
the exit code depends on whether the parent tool, perversely perhaps, actually
wants to have issued a given problem -- this is used when testing Inform.

By convention our exit codes are 0 for success, 1 for failure, and 2 for a
filing-system-related failure.

=
text_stream *sigil_of_required_problem = NULL;

int sigil_of_required_problem_found = FALSE;
int echo_problem_message_sigils = FALSE;
int crash_on_all_problems = FALSE;

void ProblemSigils::exit(int code) {
	if ((sigil_of_required_problem) && (sigil_of_required_problem_found == FALSE))
		exit(0); /* so that the problem test case will fail in |intest| */
	exit(code);
}

@ The following function has had an amusing evolution over the years. It does
something nobody is ever supposed to do: deliberately crashes the process.
At one time it executed |int x = 1/0;|, but compilers got wise to that, or
else would detect that such an expression had no side effects and was not used.
What we now do is to dereference a null pointer, while apparently trying to make
use of the result.

=
void ProblemSigils::force_crash(void) {
	STREAM_FLUSH(STDOUT);
	STREAM_FLUSH(DL);
	WRITE_TO(STDERR,
		"*** Intentionally crashing to force stack backtrace to console logs ***\n");
	STREAM_FLUSH(STDERR);
	parse_node *PN = NULL; LOG("$T", PN->next);
	ProblemSigils::exit(1); /* should never in fact be reached */
}

@h Configuration.
Inform calls this in response to its |-require-problem| command line switch:

=
void ProblemSigils::require(text_stream *sigil) {
	sigil_of_required_problem = Str::duplicate(sigil);
}

@ And this in response to |-sigils|, which causes the sigil of any problem to
be echoed to standard output (i.e., printed). Again, this is useful in testing.

=
void ProblemSigils::echo_sigils(int state) {
	echo_problem_message_sigils = state;
}

@ And this in response to |-crash-all|, an ugly expedient for working with
Inform in the debugger.

=
void ProblemSigils::crash_on_problems(int state) {
	crash_on_all_problems = state;
}

@h Sigils.
Every problem message in Inform is identified by a sigil, a short alphanumeric
symbol. The |_p_| notation is used to write these; this expands to the name in
double quotes followed by the source section and line number at which it is
generated.

@d _p_(sigil) #sigil, __FILE__, __LINE__

@ That means that when a |_p_| argument is given to a function, it is actually
a list of three arguments, matching the |SIGIL_ARGUMENTS| prototype. |SIGIL_ARGUMENTS|
appears as a pseudo-argument in the function prototypes of the many of the
functions in this module as a result.

Each such function should either |ACT_ON_SIGIL| itself or else pass over to
another problem function, using |PASS_SIGIL| as the pseudo-argument.

@d SIGIL_ARGUMENTS char *sigil, char *file, int line
@d PASS_SIGIL sigil, file, line

@ We will maintain the following variables. The distinction is that the
"unlinked" one holds the sigil of a message which is next up to be hyperlinked
to documentation; |sigil_of_latest_unlinked_problem| is then emptied when this
is done, whereas |sigil_of_latest_problem| keeps its value until the next
problem is issued.

=
text_stream *sigil_of_latest_problem = NULL;
text_stream *sigil_of_latest_unlinked_problem = NULL;

@ So, then, the following long macro is how a function "acts" on a sigil:

@d ACT_ON_SIGIL
	LOG("Problem %s issued from %s, line %d\n", sigil, file, line);
	if (sigil_of_latest_unlinked_problem == NULL)
		sigil_of_latest_unlinked_problem = Str::new();
	else
		Str::clear(sigil_of_latest_unlinked_problem);
	WRITE_TO(sigil_of_latest_unlinked_problem, "%s", sigil);
	if (sigil_of_latest_problem == NULL)
		sigil_of_latest_problem = Str::new();
	else
		Str::clear(sigil_of_latest_problem);
	WRITE_TO(sigil_of_latest_problem, "%s", sigil);
	if (Str::eq(sigil_of_required_problem, sigil_of_latest_problem))
		sigil_of_required_problem_found = TRUE;
	if (echo_problem_message_sigils) {
		if (Str::get_first_char(sigil_of_latest_problem) == 'W')
			WRITE_TO(STDERR, "Warning__ %S\n", sigil_of_latest_problem);
		else
			WRITE_TO(STDERR, "Problem__ %S\n", sigil_of_latest_problem);
	}
