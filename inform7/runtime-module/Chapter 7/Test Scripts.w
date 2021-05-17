[TestCommand::] Test Scripts.

A rudimentary but useful testing system built in to IF produced
by Inform, allowing short sequences of commands to be concisely noted in
the source text and tried out in the Inform application using the TEST
command.

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
	struct inter_name *text_iname; /* name at runtime for the text of the commands */
	struct inter_name *req_iname; /* ditto for the array of requirements */
	CLASS_DEFINITION
} test_scenario;

@ =
test_scenario *TestCommand::new_scenario(wording XW) {
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

	test = CREATE(test_scenario);
    test->name = XW;
    test->sentence_test_declared_at = current_sentence;
    test->place = NULL;
    test->no_possessions = 0;
    test->text_of_script = Str::new();
	package_request *P = Hierarchy::local_package(TESTS_HAP);
	test->text_iname = Hierarchy::make_iname_in(SCRIPT_HL, P);
	test->req_iname = Hierarchy::make_iname_in(REQUIREMENTS_HL, P);
	return test;
}

void TestCommand::add_script_to_scenario(test_scenario *test, wchar_t *p) {
    TEMPORARY_TEXT(individual_command)
    Str::clear(test->text_of_script);
    for (int i=0; p[i]; i++) {
    	int c = Characters::tolower(p[i]);
    	if (c == ' ') {
    		int l;
    		if (Str::len(individual_command) == 0) continue;
    		for (l=i+1; p[l]; l++) if (p[l] != ' ') break;
    		if ((p[l] == '/') || (p[l] == 0)) continue;
    	}

    	if (c == '/') {
    		TestCommand::check_test_command(individual_command);
    		Str::clear(individual_command);
		} else {
			PUT_TO(individual_command, c);
		}
    	PUT_TO(test->text_of_script, c);
    }
    if (Str::len(individual_command) > 0)
		TestCommand::check_test_command(individual_command);
    int L = Str::len(test->text_of_script);
    if (Str::get_at(test->text_of_script, L-1) == '/')
    	Str::put_at(test->text_of_script, L-1, ' ');
    DISCARD_TEXT(individual_command)
}

void TestCommand::add_location_to_scenario(test_scenario *test, instance *I) {
	test->place = I;
}

void TestCommand::add_possession_to_scenario(test_scenario *test, instance *I) {
	if (test->no_possessions >= MAX_POSSESSIONS_PER_SCENARIO)
		@<Issue PM_TooManyRequirements problem@>
	else
		test->possessions[test->no_possessions++] = I;
}

@<Issue PM_TooManyRequirements problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TooManyRequirements),
		"There are too many requirements for this test scenario",
		"so the player will have to hold a little less.");

@ =
void TestCommand::check_test_command(text_stream *p) {
	if (Str::eq_wide_string(p, L"undo")) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TestContainsUndo),
			"this test script contains an UNDO command",
			"which the story file has no way to automate the running of. "
			"(An UNDO is such a complete reversion to the previous state "
			"that it would necessarily lose where it had got to in the "
			"script, and might even go round in circles indefinitely.)");
		return;
	}
	if (Str::len(p) > MAX_LENGTH_OF_COMMAND) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TestCommandTooLong),
			"this test script contains a command which is too long",
			"and cannot be fed into Inform for automatic testing. "
			"(The format for a test script is a sequence of commands, "
			"divided up by slashes '/': maybe you forgot these divisions?)");
		return;
	}
}

void TestCommand::write_text(void) {
	test_scenario *test;
	LOOP_OVER(test, test_scenario) {
		packaging_state save = EmitArrays::begin_byte(test->text_iname, K_text);
		TEMPORARY_TEXT(tttext)
		TranscodeText::from_stream(tttext, test->text_of_script,
			CT_EXPAND_APOSTROPHES + CT_RECOGNISE_APOSTROPHE_SUBSTITUTION);
		WRITE_TO(tttext, "||||");
		EmitArrays::text_entry(tttext);
		DISCARD_TEXT(tttext)
		EmitArrays::end(save);

		save = EmitArrays::begin(test->req_iname, K_value);
		if (test->place == NULL) EmitArrays::numeric_entry(0);
		else EmitArrays::iname_entry(RTInstances::value_iname(test->place));
		for (int j=0; j<test->no_possessions; j++) {
			if (test->possessions[j] == NULL) EmitArrays::numeric_entry(0);
			else EmitArrays::iname_entry(RTInstances::value_iname(test->possessions[j]));
		}
		EmitArrays::numeric_entry(0);
		EmitArrays::end(save);
	}
}

void TestCommand::TestScriptSub_stub_routine(void) {
	inter_name *iname = Hierarchy::find(TESTSCRIPTSUB_HL);
	Hierarchy::make_available(iname);
	packaging_state save = Functions::begin(iname);
	EmitCode::rfalse();
	Functions::end(save);
}

void TestCommand::TestScriptSub_routine(void) {
	inter_name *iname = Hierarchy::find(TESTSCRIPTSUB_HL);
	Hierarchy::make_available(iname);
	packaging_state save = Functions::begin(iname);
	if (NUMBER_CREATED(test_scenario) == 0) {
		EmitCode::inv(PRINT_BIP);
		EmitCode::down();
			EmitCode::val_text(I">--> No test scripts exist for this game.\n");
		EmitCode::up();
	} else {
		EmitCode::inv(SWITCH_BIP);
		EmitCode::down();
			EmitCode::val_iname(K_object, Hierarchy::find(SPECIAL_WORD_HL));
			EmitCode::code();
			EmitCode::down();
				test_scenario *test;
				LOOP_OVER(test, test_scenario) {
					EmitCode::inv(CASE_BIP);
					EmitCode::down();
						TEMPORARY_TEXT(W)
						WRITE_TO(W, "%w", Lexer::word_raw_text(Wordings::first_wn(test->name)));
						EmitCode::val_dword(W);
						DISCARD_TEXT(W)
						EmitCode::code();
						EmitCode::down();
							EmitCode::call(Hierarchy::find(TESTSTART_HL));
							EmitCode::down();
								EmitCode::val_iname(K_value, test->text_iname);
								EmitCode::val_iname(K_value, test->req_iname);
								int l = 0;
								text_stream *p = test->text_of_script;
								for (int i=0, L = Str::len(p); i<L; i++, l++)
									if (Str::includes_wide_string_at(p, L"[']", i))
										l -= 2;
								EmitCode::val_number((inter_ti) l);
							EmitCode::up();
						EmitCode::up();
					EmitCode::up();
				}
				EmitCode::inv(DEFAULT_BIP);
				EmitCode::down();
					EmitCode::code();
					EmitCode::down();
						EmitCode::inv(PRINT_BIP);
						EmitCode::down();
							EmitCode::val_text(I">--> The following tests are available:\n");
						EmitCode::up();
						LOOP_OVER(test, test_scenario) {
							TEMPORARY_TEXT(T)
							WRITE_TO(T, "'test %w'\n",
								Lexer::word_raw_text(Wordings::first_wn(test->name)));
							EmitCode::inv(PRINT_BIP);
							EmitCode::down();
								EmitCode::val_text(T);
							EmitCode::up();
							DISCARD_TEXT(T)
						}
						EmitCode::inv(PRINT_BIP);
						EmitCode::down();
							EmitCode::val_text(I"\n");
						EmitCode::up();
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();
	}

	Functions::end(save);
}
