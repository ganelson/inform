[TestCommand::] Test Scripts.

A rudimentary but useful testing system for runnign short sequences of commands
through the command parser at runtime.

@ Test scenarios consist of a string of commands in text format, with a few
stipulations on place and possessions attached.

@d MAX_LENGTH_OF_COMMAND 100 /* any single command must be this long or shorter */
@d MAX_POSSESSIONS_PER_SCENARIO 16

=
typedef struct test_scenario {
	struct wording name; /* in fact a single word identifying the test */
	struct text_stream *text_of_script;
	struct instance *place; /* room we need to be in to perform test */
	int no_possessions; /* number of required possessions of player */
	struct instance *possessions[MAX_POSSESSIONS_PER_SCENARIO]; /* what they are */
	struct parse_node *sentence_test_declared_at;
	struct test_scenario_compilation_data compilation_data;
	CLASS_DEFINITION
} test_scenario;

@ =
test_scenario *TestCommand::new_scenario(wording XW) {
	@<Ensure the new scenario has a different name from existing ones@>;
	test_scenario *test = CREATE(test_scenario);
    test->name = XW;
    test->sentence_test_declared_at = current_sentence;
    test->place = NULL;
    test->no_possessions = 0;
    test->text_of_script = Str::new();
    test->compilation_data = RTTestCommand::new_compilation_data(test);
	return test;
}

@<Ensure the new scenario has a different name from existing ones@> =
	test_scenario *test;
    LOOP_OVER(test, test_scenario) {
    	if (Wordings::match(XW, test->name)) {
    		Problems::quote_source(1, test->sentence_test_declared_at);
    		Problems::quote_source(2, current_sentence);
    		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_TestDuplicate));
			Problems::issue_problem_segment(
				"Two test scripts have been set up with the same name: %1 and %2.");
			Problems::issue_problem_end();
			return test;
    	}
	}

@ The ingredients for a scenario are added one by one:

=
void TestCommand::add_location_to_scenario(test_scenario *test, instance *I) {
	test->place = I;
}

void TestCommand::add_possession_to_scenario(test_scenario *test, instance *I) {
	if (test->no_possessions >= MAX_POSSESSIONS_PER_SCENARIO)
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_TooManyRequirements),
			"There are too many requirements for this test scenario",
			"so the player will have to hold a little less.");
	else
		test->possessions[test->no_possessions++] = I;
}

void TestCommand::add_script_to_scenario(test_scenario *test, inchar32_t *p) {
    TEMPORARY_TEXT(individual_command)
    Str::clear(test->text_of_script);
    for (int i=0; p[i]; i++) {
    	inchar32_t c = Characters::tolower(p[i]);
    	if (c == ' ') {
    		int l;
    		if (Str::len(individual_command) == 0) continue;
    		for (l=i+1; p[l]; l++) if (p[l] != ' ') break;
    		if ((p[l] == '/') || (p[l] == 0)) continue;
    	}

    	if (c == '/') {
    		@<Check an individual command@>;
    		Str::clear(individual_command);
		} else {
			PUT_TO(individual_command, c);
		}
    	PUT_TO(test->text_of_script, c);
    }
    if (Str::len(individual_command) > 0)
		@<Check an individual command@>;
    int L = Str::len(test->text_of_script);
    if (Str::get_at(test->text_of_script, L-1) == '/')
    	Str::put_at(test->text_of_script, L-1, ' ');
    DISCARD_TEXT(individual_command)
}

@<Check an individual command@> =
	if (Str::eq_wide_string(individual_command, U"undo")) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TestContainsUndo),
			"this test script contains an UNDO command",
			"which the story file has no way to automate the running of. "
			"(An UNDO is such a complete reversion to the previous state "
			"that it would necessarily lose where it had got to in the "
			"script, and might even go round in circles indefinitely.)");
		return;
	}
	if (Str::len(individual_command) > MAX_LENGTH_OF_COMMAND) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TestCommandTooLong),
			"this test script contains a command which is too long",
			"and cannot be fed into Inform for automatic testing. "
			"(The format for a test script is a sequence of commands, "
			"divided up by slashes '/': maybe you forgot these divisions?)");
		return;
	}
