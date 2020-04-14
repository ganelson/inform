[Problems::Fatal::] Problems, Level 0.

To handle fatal errors.

@ In my beginning is my end: this lowest level of the error-handling system
deals with systemic collapses.

=
text_stream problems_file_struct; /* The actual report of Problems file */
text_stream *problems_file = &problems_file_struct; /* The actual report of Problems file */

text_stream *probl = NULL; /* Current destination of problem message text */

int it_is_not_worth_adding = FALSE; /* To suppress the "It may be worth adding..." */

int crash_on_all_errors = FALSE;

text_stream *sigil_of_required_problem = NULL;
int sigil_of_required_problem_found = FALSE;

void Problems::Fatal::require(text_stream *sigil) {
	sigil_of_required_problem = Str::duplicate(sigil);
}

void Problems::Fatal::exit(int code) {
	if ((sigil_of_required_problem) && (sigil_of_required_problem_found == FALSE))
		exit(0); /* so that the problem test case will fail in |intest| */
	exit(code);
}

void Problems::Fatal::issue(char *message) {
	WRITE_TO(STDERR, message);
	WRITE_TO(STDERR, "\n");
	STREAM_FLUSH(STDERR);
	if (crash_on_all_errors) Problems::Fatal::force_crash();
	Problems::Fatal::exit(2);
}

void Problems::Fatal::issue_t(char *message, char *fn) {
	WRITE_TO(STDERR, message);
	WRITE_TO(STDERR, "\nOffending filename: <%s>\n", fn);
	STREAM_FLUSH(STDERR);
	if (crash_on_all_errors) Problems::Fatal::force_crash();
	Problems::Fatal::exit(2);
}

void Problems::Fatal::filename_related(char *message, filename *F) {
	WRITE_TO(STDERR, message);
	WRITE_TO(STDERR, "\nOffending filename: <%f>\n", F);
	STREAM_FLUSH(STDERR);
	if (crash_on_all_errors) Problems::Fatal::force_crash();
	Problems::Fatal::exit(2);
}

@ Fatal errors are not necessarily a bad thing. When tracking down why
Inform issues certain problem messages (especially internal errors) it can be
useful to provoke a deliberate crash of the application, in order to
get a stack backtrace into the GNU debugger |gdb| (and/or onto the system
console logs). We can force this using the following variables (which main
sets with the command-line switch "-gdb").

=
void Problems::Fatal::force_crash(void) {
	STREAM_FLUSH(STDOUT);
	STREAM_FLUSH(DL);
	WRITE_TO(STDERR,
		"*** Intentionally crashing to force stack backtrace to console logs ***\n");
	STREAM_FLUSH(STDERR);
	parse_node *PN = NULL; LOG("$T", PN->next);
	Problems::Fatal::exit(1);
}
