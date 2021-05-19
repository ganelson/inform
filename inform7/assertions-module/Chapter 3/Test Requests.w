[TestRequests::] Test Requests.

Special sentences for requesting unit tests or providing test scripts.

@ The verb "Test ... with ..." has two different uses, one public, letting
users set up test dialogues called "scenarios", and the other undocumented,
for performing unit tests of parts of the compiler. These exist because the
test suite for Inform is made up of end-to-end tests, and sometimes these make
it hard to see what any given component has done.

All sentences in the shape "test ... with ..." are accepted:

=
test_scenario *ts_being_created = NULL;

int TestRequests::test_with_SMF(int task, parse_node *V, wording *NPs) {
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	wording O2W = (NPs)?(NPs[2]):EMPTY_WORDING;
	switch (task) { /* "Test me with..." */
		case ACCEPT_SMFT:
			<np-unparsed>(O2W);
			V->next = <<rp>>;
			<np-unparsed>(OW);
			V->next->next = <<rp>>;
			return TRUE;
		case PASS_2_SMFT:
			@<Create the new test request@>;
			break;
		case ALLOW_IN_OPTIONS_FILE_SMFT:
			return TRUE;
	}
	return FALSE;
}

@ The subject phrase is often just "me", as in, "Test me with...", but in fact
it can generate a range of possibilities.

=
<test-sentence-subject> ::=
	<internal-test-case-name> ( internal ) |  ==> { pass 1 }
	headline ( internal ) |                   ==> { HEADLINE_INTT, - }
	### ( internal ) |                        ==> @<Issue PM_UnknownInternalTest problem@>
	<quoted-text> |                           ==> @<Issue PM_TestQuoted problem@>
	###	|                                     ==> { SCENARIO_INTT, - }
	...                                       ==> @<Issue PM_TestMultiWord problem@>

@<Issue PM_UnknownInternalTest problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_UnknownInternalTest),
		"that's an internal test case which I don't know",
		"so I am taking no action.");
	==> { NO_INTT, - };

@<Issue PM_TestQuoted problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TestQuoted),
		"test scenarios must have unquoted names",
		"so 'test garden with ...' is allowed but not 'test \"garden\" with...'");
	==> { NO_INTT, - };

@<Issue PM_TestMultiWord problem@> =
   	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TestMultiWord),
		"test scenarios must have single-word names",
		"so 'test garden with ...' is allowed but not 'test garden gate with...'");
	==> { NO_INTT, - };

@<Create the new test request@> =
	wording SP = Node::get_text(V->next);
	wording OP = Node::get_text(V->next->next);
	<test-sentence-subject>(SP); /* always passes */
	switch (<<r>>) {
		case NO_INTT: break; /* recover from errors */
		case SCENARIO_INTT: @<Create a test scenario@>; break;
		case HEADLINE_INTT: InternalTests::new(NULL, OP); break;
		default: InternalTests::new(<<rp>>, OP); break;
	}

@<Create a test scenario@> =
	wording XW = GET_RW(<test-sentence-subject>, 1);
 	ts_being_created = TestCommand::new_scenario(XW);
    <test-sentence-object>(OP);

@ The object NP for a scenario is usually just a quoted script, but it can be
more elaborate:

>> Test me with "x egg" in Timbuktu holding the egg.

=
<test-sentence-object> ::=
	<quoted-text> |                                ==> { TRUE, - }; @<Add script@>
	<quoted-text> <test-case-circumstance-list> |  ==> { TRUE, - }; @<Add script@>
	...                                            ==> @<Issue PM_TestBadRequirements problem@>

<test-case-circumstance-list> ::=
	... |                                                     ==> { lookahead }
	<test-case-circumstance-list> <test-case-circumstance> |  ==> { 0, - }
	<test-case-circumstance>                                  ==> { 0, - }

<test-case-circumstance> ::=
	in <instance-of-object> |             ==> @<Add in-test requirement@>
	in ... |                              ==> @<Issue PM_TestBadRequirements problem@>
	holding/and/, <instance-of-object> |  ==> @<Add holding requirement@>
	holding/and/, ... |                   ==> @<Issue PM_TestBadRequirements problem@>
	with ...                              ==> @<Issue PM_TestDoubleWith problem@>

@<Add script@> =
    Word::dequote(Wordings::first_wn(W));
    wchar_t *p = Lexer::word_text(Wordings::first_wn(W));
	TestCommand::add_script_to_scenario(ts_being_created, p);

@<Add in-test requirement@> =
	TestCommand::add_location_to_scenario(ts_being_created, RP[1]);

@<Add holding requirement@> =
	TestCommand::add_possession_to_scenario(ts_being_created, RP[1]);

@<Issue PM_TestDoubleWith problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TestDoubleWith),
		"the second 'with' should be 'holding'",
		"as in 'test frogs with \"get frogs\" holding net' rather than "
		"'test frogs with \"get frogs\" with net'.");

@<Issue PM_TestBadRequirements problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TestBadRequirements),
		"I didn't recognise the requirements for this test scenario",
		"which should be 'test ... with ... in ...' or '... "
		"holding ...'");
