[PL::Parsing::TestScripts::] Test Scripts.

A rudimentary but useful testing system built in to IF produced
by Inform, allowing short sequences of commands to be concisely noted in
the source text and tried out in the Inform application using the TEST
command.

@h Definitions.

@ Test scenarios are used for the "TEST" command: they consist of a string of
commands in text format, with a few stipulations on place and possessions
attached.

@d MAX_LENGTH_OF_SCRIPT 10000 /* including length byte, so the max no of chars is one less */
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
	MEMORY_MANAGEMENT
} test_scenario;

@ =
typedef struct internal_test_case {
	int itc_code; /* one of the above |*_INTT| values */
	struct wording text_supplying_the_case;
	struct parse_node *itc_defined_at;
	MEMORY_MANAGEMENT
} internal_test_case;

@ Internal test cases are numbered thus:

@d NO_INTT -2
@d EXTERNAL_INTT -1
@d HEADLINE_INTT 0
@d SENTENCE_INTT 1
@d DESCRIPTION_INTT 2
@d DIMENSIONS_INTT 3
@d EVALUATION_INTT 4
@d EQUATION_INTT 5
@d VERB_INTT 6
@d ADJECTIVE_INTT 7
@d ING_INTT 8
@d KIND_INTT 9
@d MAP_INTT 10
@d DASH_INTT 11
@d DASHLOG_INTT 12

@ The following grammar handles Test sentences such as:

>> Test me with "open box/get ball".

Though it isn't openly documented, Inform also supports internal test cases,
whose names are suffixed by "(internal)". These exist because the test
suite for Inform is made up of end-to-end tests, and sometimes these make
it hard to see what any given component has done.

=
<test-sentence-subject> ::=
	<internal-test-case-name> ( internal ) |	==> R[1]
	### ( internal ) |							==> @<Issue PM_UnknownInternalTest problem@>
	<quoted-text> |								==> @<Issue PM_TestQuoted problem@>
	###	|										==> EXTERNAL_INTT
	...											==> @<Issue PM_TestMultiWord problem@>

@ These test case names are in English only and may change at any time
without notice.

=
<internal-test-case-name> ::=
	headline |
	sentence |
	description |
	dimensions |
	evaluation |
	equation |
	verb |
	adjective |
	participle |
	kind |
	map |
	dash |
	dashlog

@ =
test_scenario *ts_being_parsed = NULL;

@ The object NP is usually just a quoted script, but it can be more elaborate:

>> Test me with "x egg" in Timbuktu holding the egg.

=
<test-sentence-object> ::=
	<quoted-text> |									==> TRUE; @<Process the quoted test script@>
	<quoted-text> <test-case-circumstance-list> |	==> TRUE; @<Process the quoted test script@>
	...												==> @<Issue PM_TestBadRequirements problem@>

<test-case-circumstance-list> ::=
	... |														==> 0; return preform_lookahead_mode;
	<test-case-circumstance-list> <test-case-circumstance> |	==> 0
	<test-case-circumstance>									==> 0

<test-case-circumstance> ::=
	in <instance-of-object> |				==> @<Process the in-test requirement@>
	holding/and/, <instance-of-object> |	==> @<Process the holding requirement@>
	in ... |								==> @<Issue PM_TestBadRequirements problem@>
	holding/and/, ... |						==> @<Issue PM_TestBadRequirements problem@>
	with ...								==> @<Issue PM_TestDoubleWith problem@>

@<Process the quoted test script@> =
	int i, x1 = R[1];
    Word::dequote(x1);
    wchar_t *p = Lexer::word_text(x1++);
    TEMPORARY_TEXT(individual_command);
    Str::clear(ts_being_parsed->text_of_script);
    for (i=0; p[i]; i++) {
    	int c = Characters::tolower(p[i]);
    	if (c == ' ') {
    		int l;
    		if (Str::len(individual_command) == 0) continue;
    		for (l=i+1; p[l]; l++) if (p[l] != ' ') break;
    		if ((p[l] == '/') || (p[l] == 0)) continue;
    	}

    	if (c == '/') {
    		PL::Parsing::TestScripts::check_test_command(individual_command);
    		Str::clear(individual_command);
		} else {
			PUT_TO(individual_command, c);
		}
    	PUT_TO(ts_being_parsed->text_of_script, c);
    }
    if (Str::len(individual_command) > 0)
		PL::Parsing::TestScripts::check_test_command(individual_command);
    int L = Str::len(ts_being_parsed->text_of_script);
    if (Str::get_at(ts_being_parsed->text_of_script, L-1) == '/')
    	Str::put_at(ts_being_parsed->text_of_script, L-1, ' ');
    DISCARD_TEXT(individual_command);

@<Process the in-test requirement@> =
	ts_being_parsed->place = RP[1];

@<Process the holding requirement@> =
	if (ts_being_parsed->no_possessions >= MAX_POSSESSIONS_PER_SCENARIO) {
		@<Issue PM_TestBadRequirements problem@>;
	} else
		ts_being_parsed->possessions[ts_being_parsed->no_possessions++] = RP[1];

@<Issue PM_TestBadRequirements problem@> =
	Problems::Issue::sentence_problem(_p_(PM_TestBadRequirements),
		"I didn't recognise the requirements for this test scenario",
		"which should be 'test ... with ... in ...' or '... "
		"holding ...'");

@<Issue PM_TestQuoted problem@> =
	*X = FALSE;
   	Problems::Issue::sentence_problem(_p_(PM_TestQuoted),
		"test scenarios must have unquoted names",
		"so 'test garden with ...' is allowed but not 'test \"garden\" with...'");

@<Issue PM_TestMultiWord problem@> =
	*X = FALSE;
   	Problems::Issue::sentence_problem(_p_(PM_TestMultiWord),
		"test scenarios must have single-word names",
		"so 'test garden with ...' is allowed but not 'test garden gate with...'");

@<Issue PM_UnknownInternalTest problem@> =
	*X = NO_INTT;
	Problems::Issue::sentence_problem(_p_(PM_UnknownInternalTest),
		"that's an internal test case which I don't know",
		"so I am taking no action.");

@<Issue PM_TestDoubleWith problem@> =
	Problems::Issue::sentence_problem(_p_(PM_TestDoubleWith),
		"the second 'with' should be 'holding'",
		"as in 'test frogs with \"get frogs\" holding net' rather than "
		"'test frogs with \"get frogs\" with net'.");

@ =
int PL::Parsing::TestScripts::test_with_SMF(int task, parse_node *V, wording *NPs) {
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	wording O2W = (NPs)?(NPs[2]):EMPTY_WORDING;
	switch (task) { /* "Test me with..." */
		case ACCEPT_SMFT:
			ParseTree::annotate_int(V, verb_id_ANNOT, SPECIAL_MEANING_VB);
			<nounphrase>(O2W);
			V->next = <<rp>>;
			<nounphrase>(OW);
			V->next->next = <<rp>>;
			return TRUE;
		case TRAVERSE2_SMFT:
			PL::Parsing::TestScripts::new_test_text(V);
			break;
	}
	return FALSE;
}

void PL::Parsing::TestScripts::new_test_text(parse_node *PN) {
	if (<test-sentence-subject>(ParseTree::get_text(PN->next))) {
		switch (<<r>>) {
			case NO_INTT: return;
			case EXTERNAL_INTT: @<Create a test script@>; break;
			default: PL::Parsing::TestScripts::new_internal(<<r>>, ParseTree::get_text(PN->next->next));
				break;
		}
	}
}

@<Create a test script@> =
	wording XW = GET_RW(<test-sentence-subject>, 1);

 	test_scenario *test;
    LOOP_OVER(test, test_scenario) {
    	if (Wordings::match(XW, test->name)) {
    		Problems::quote_source(1, test->sentence_test_declared_at);
    		Problems::quote_source(2, current_sentence);
    		Problems::Issue::handmade_problem(_p_(PM_TestDuplicate));
			Problems::issue_problem_segment(
				"Two test scripts have been set up with the same name: "
				"%1 and %2.");
			Problems::issue_problem_end();
    	}
	}

	test = CREATE(test_scenario);
    test->name = XW;
    test->sentence_test_declared_at = current_sentence;
    test->place = NULL;
    test->no_possessions = 0;
    test->text_of_script = Str::new();

	package_request *PR = Packaging::request_resource(Modules::find(current_sentence), GRAMMAR_SUBPACKAGE);
	package_request *PR2 = Packaging::request(Packaging::supply_iname(PR, TEST_PR_COUNTER), PR, test_ptype);
	test->text_iname = InterNames::one_off(I"script", PR2);
	test->req_iname = InterNames::one_off(I"requirements", PR2);
	Inter::Symbols::set_flag(InterNames::to_symbol(test->text_iname), MAKE_NAME_UNIQUE);
	Inter::Symbols::set_flag(InterNames::to_symbol(test->req_iname), MAKE_NAME_UNIQUE);

	ts_being_parsed = test;
    <test-sentence-object>(ParseTree::get_text(PN->next->next));

@ =
void PL::Parsing::TestScripts::check_test_command(text_stream *p) {
	if (Str::eq_wide_string(p, L"undo")) {
		Problems::Issue::sentence_problem(_p_(PM_TestContainsUndo),
			"this test script contains an UNDO command",
			"which the story file has no way to automate the running of. "
			"(An UNDO is such a complete reversion to the previous state "
			"that it would necessarily lose where it had got to in the "
			"script, and might even go round in circles indefinitely.)");
		return;
	}
	if (Str::len(p) > MAX_LENGTH_OF_COMMAND) {
		Problems::Issue::sentence_problem(_p_(PM_TestCommandTooLong),
			"this test script contains a command which is too long",
			"and cannot be fed into Inform for automatic testing. "
			"(The format for a test script is a sequence of commands, "
			"divided up by slashes '/': maybe you forgot these divisions?)");
		return;
	}
}

void PL::Parsing::TestScripts::write_text(void) {
	test_scenario *test;
	LOOP_OVER(test, test_scenario) {
		packaging_state save = Packaging::enter_home_of(test->text_iname);
		Emit::named_byte_array_begin(test->text_iname, K_text);
		TEMPORARY_TEXT(tttext);
		CompiledText::from_stream(tttext, test->text_of_script,
			CT_EXPAND_APOSTROPHES + CT_RECOGNISE_APOSTROPHE_SUBSTITUTION);
		WRITE_TO(tttext, "||||");
		Emit::array_text_entry(tttext);
		DISCARD_TEXT(tttext);
		Emit::array_end();

		Emit::named_array_begin(test->req_iname, K_value);
		if (test->place == NULL) Emit::array_numeric_entry(0);
		else Emit::array_iname_entry(Instances::iname(test->place));
		for (int j=0; j<test->no_possessions; j++) {
			if (test->possessions[j] == NULL) Emit::array_numeric_entry(0);
			else Emit::array_iname_entry(Instances::iname(test->possessions[j]));
		}
		Emit::array_numeric_entry(0);
		Emit::array_end();
		Packaging::exit(save);
	}
}

void PL::Parsing::TestScripts::NO_TEST_SCENARIOS_constant(void) {
	if (NUMBER_CREATED(test_scenario) > 0) {
		package_request *PR = Packaging::request_resource(NULL, BASICS_SUBPACKAGE);
		inter_name *iname = InterNames::iname(NO_TEST_SCENARIOS_INAME);
		Packaging::house(iname, PR);
		packaging_state save = Packaging::enter_home_of(iname);
		Emit::named_numeric_constant(iname, (inter_t) NUMBER_CREATED(test_scenario));
		Packaging::exit(save);
	}
}

void PL::Parsing::TestScripts::TestScriptSub_stub_routine(void) {
	inter_name *iname = InterNames::find(TESTSCRIPTSUB_NRL);
	packaging_state save = Routines::begin(iname);
	Emit::rfalse();
	Routines::end(save);
}

void PL::Parsing::TestScripts::TestScriptSub_routine(void) {
	inter_name *iname = InterNames::find(TESTSCRIPTSUB_NRL);
	packaging_state save = Routines::begin(iname);
	if (NUMBER_CREATED(test_scenario) == 0) {
		Emit::inv_primitive(print_interp);
		Emit::down();
			Emit::val_text(I">--> No test scripts exist for this game.\n");
		Emit::up();
	} else {
		Emit::inv_primitive(switch_interp);
		Emit::down();
			Emit::val_iname(K_object, InterNames::extern(SPECIALWORD_EXNAMEF));
			Emit::code();
			Emit::down();
				test_scenario *test;
				LOOP_OVER(test, test_scenario) {
					Emit::inv_primitive(case_interp);
					Emit::down();
						TEMPORARY_TEXT(W);
						WRITE_TO(W, "%w", Lexer::word_raw_text(Wordings::first_wn(test->name)));
						Emit::val_dword(W);
						DISCARD_TEXT(W);
						Emit::code();
						Emit::down();
							Emit::inv_call(InterNames::to_symbol(InterNames::extern(TESTSTART_EXNAMEF)));
							Emit::down();
								Emit::val_iname(K_value, test->text_iname);
								Emit::val_iname(K_value, test->req_iname);
								int l = 0;
								text_stream *p = test->text_of_script;
								for (int i=0, L = Str::len(p); i<L; i++, l++)
									if (Str::includes_wide_string_at(p, L"[']", i))
										l -= 2;
								Emit::val(K_number, LITERAL_IVAL, (inter_t) l);
							Emit::up();
						Emit::up();
					Emit::up();
				}
				Emit::inv_primitive(default_interp);
				Emit::down();
					Emit::code();
					Emit::down();
						Emit::inv_primitive(print_interp);
						Emit::down();
							Emit::val_text(I">--> The following tests are available:\n");
						Emit::up();
						LOOP_OVER(test, test_scenario) {
							TEMPORARY_TEXT(T);
							WRITE_TO(T, "'test %w'\n",
								Lexer::word_raw_text(Wordings::first_wn(test->name)));
							Emit::inv_primitive(print_interp);
							Emit::down();
								Emit::val_text(T);
							Emit::up();
							DISCARD_TEXT(T);
						}
						Emit::inv_primitive(print_interp);
						Emit::down();
							Emit::val_text(I"\n");
						Emit::up();
					Emit::up();
				Emit::up();
			Emit::up();
		Emit::up();
	}

	Routines::end(save);
}

@ =
void PL::Parsing::TestScripts::new_internal(int code, wording W) {
	internal_test_case *itc = CREATE(internal_test_case);
	itc->itc_code = code;
	itc->text_supplying_the_case = W;
	itc->itc_defined_at = current_sentence;
}

text_stream *itc_save_DL = NULL, *itc_save_OUT = NULL;

void PL::Parsing::TestScripts::InternalTestCases_routine(void) {
	package_request *PR = Packaging::synoptic_resource(GRAMMAR_SUBPACKAGE);
	inter_name *iname = Packaging::function(
		InterNames::one_off(I"run_tests_fn", PR),
		PR,
		InterNames::iname(InternalTestCases_INAME));
	packaging_state save = Routines::begin(iname);
	internal_test_case *itc; int n = 0;
	LOOP_OVER(itc, internal_test_case) {
		n++;
		if (itc->itc_code == HEADLINE_INTT) {
			n = 0;
			Emit::inv_primitive(stylebold_interp);
			TEMPORARY_TEXT(T);
			WRITE_TO(T, "\n%+W\n", itc->text_supplying_the_case);
			Emit::inv_primitive(print_interp);
			Emit::down();
				Emit::val_text(T);
			Emit::up();
			DISCARD_TEXT(T);
			Emit::inv_primitive(styleroman_interp);
			continue;
		}
		TEMPORARY_TEXT(C);
		WRITE_TO(C, "%d. %+W\n", n, itc->text_supplying_the_case);
		Emit::inv_primitive(print_interp);
		Emit::down();
			Emit::val_text(C);
		Emit::up();
		DISCARD_TEXT(C);

		TEMPORARY_TEXT(OUT);
		itc_save_OUT = OUT;
		current_sentence = itc->itc_defined_at;
		switch (itc->itc_code) {
			case SENTENCE_INTT: {
				int SV_not_SN = TRUE;
				@<Perform an internal test of the sentence converter@>;
				break;
			}
			case DESCRIPTION_INTT: {
				int SV_not_SN = FALSE;
				@<Perform an internal test of the sentence converter@>;
				break;
			}
			case EVALUATION_INTT: {
				parse_node *spec = NULL;
				if (<s-value>(itc->text_supplying_the_case)) spec = <<rp>>;
				else spec = Specifications::new_UNKNOWN(itc->text_supplying_the_case);
				Dash::check_value(spec, NULL);
				kind *K = Specifications::to_kind(spec);
				WRITE("Kind of value: ");
				@<Begin reporting on the internal test case@>;
				Kinds::Textual::log(K);
				if (Kinds::Behaviour::is_quasinumerical(K))
					LOG(" scaled at k=%d", Kinds::Behaviour::scale_factor(K));
				@<End reporting on the internal test case@>;
				WRITE("\nPrints as: ");
				Emit::inv_primitive(print_interp);
				Emit::down();
					Emit::val_text(OUT);
				Emit::up();

				Emit::inv_primitive(indirect1v_interp);
				Emit::down();
					Emit::val_iname(K_value, Kinds::Behaviour::get_iname(K));
					Specifications::Compiler::emit_as_val(K_value, spec);
				Emit::up();

				Str::clear(OUT);
				WRITE("\n");
				break;
			}
			case DIMENSIONS_INTT:
				@<Begin reporting on the internal test case@>;
				Kinds::Dimensions::log_unit_analysis();
				@<End reporting on the internal test case@>;
				break;
			case EQUATION_INTT:
				Equations::internal_test(itc->text_supplying_the_case);
				break;
			case VERB_INTT:
				Conjugation::test(OUT, itc->text_supplying_the_case, language_of_play);
				break;
			case ADJECTIVE_INTT:
				Adjectives::test_adjective(OUT, itc->text_supplying_the_case);
				break;
			case ING_INTT:
				Conjugation::test_participle(OUT, itc->text_supplying_the_case);
				break;
			case KIND_INTT:
				@<Begin reporting on the internal test case@>;
				Kinds::Compare::log_poset(
					Vocabulary::get_literal_number_value(
						Lexer::word(
							Wordings::first_wn(
								itc->text_supplying_the_case))));
				@<End reporting on the internal test case@>;
				break;
			#ifdef IF_MODULE
			case MAP_INTT:
				@<Begin reporting on the internal test case@>;
				PL::SpatialMap::log_spatial_layout();
				@<End reporting on the internal test case@>;
				break;
			#endif
			case DASH_INTT:
				@<Begin reporting on the internal test case@>;
				Dash::experiment(itc->text_supplying_the_case, FALSE);
				@<End reporting on the internal test case@>;
				break;
			case DASHLOG_INTT:
				Dash::experiment(itc->text_supplying_the_case, TRUE);
				break;
		}
		WRITE("\n");
		Emit::inv_primitive(print_interp);
		Emit::down();
			Emit::val_text(OUT);
		Emit::up();
		DISCARD_TEXT(OUT);
	}
	Routines::end(save);
}

void PL::Parsing::TestScripts::begin_internal_reporting(void) {
	@<Begin reporting on the internal test case@>;
}

void PL::Parsing::TestScripts::end_internal_reporting(void) {
	@<End reporting on the internal test case@>;
}

@<Perform an internal test of the sentence converter@> =
	parse_node *p = NULL;
	pcalc_prop *prop = NULL;
	int tc = FALSE;

	if (SV_not_SN) {
		if (<s-sentence>(itc->text_supplying_the_case)) p = <<rp>>;
	} else {
		if (<s-descriptive-np>(itc->text_supplying_the_case)) p = <<rp>>;
	}
	if (p) {
		prop = Specifications::to_proposition(p);
		tc = Calculus::Propositions::Checker::type_check(prop, Calculus::Propositions::Checker::tc_no_problem_reporting());
	}
	@<Begin reporting on the internal test case@>; Streams::enable_I6_escapes(DL);
	if (p == NULL) LOG("Failed: not a condition");
	else {
		LOG("$D\n", prop);
		if (tc == FALSE) LOG("Failed: proposition would not type-check\n");
		Calculus::Propositions::Checker::type_check(prop, Calculus::Propositions::Checker::tc_problem_logging());
	}
	Streams::disable_I6_escapes(DL); @<End reporting on the internal test case@>;

@<Begin reporting on the internal test case@> =
	itc_save_DL = DL; DL = itc_save_OUT;
	Streams::enable_debugging(DL); // Streams::enable_I6_escapes(DL);

@<End reporting on the internal test case@> =
	Streams::disable_debugging(DL); // Streams::disable_I6_escapes(DL);
	DL = itc_save_DL;

@ =
void PL::Parsing::TestScripts::emit_showme(parse_node *spec) {
	TEMPORARY_TEXT(OUT);
	itc_save_OUT = OUT;
	if (ParseTree::is(spec, PROPERTY_VALUE_NT))
		spec = Lvalues::underlying_property(spec);
	kind *K = Specifications::to_kind(spec);
	if (ParseTree::is(spec, CONSTANT_NT) == FALSE)
		WRITE("\"%+W\" = ", ParseTree::get_text(spec));
	@<Begin reporting on the internal test case@>;
	Kinds::Textual::log(K);
	@<End reporting on the internal test case@>;
	WRITE(": ");
	Emit::inv_primitive(print_interp);
	Emit::down();
		Emit::val_text(OUT);
	Emit::up();
	DISCARD_TEXT(OUT);

	if (Kinds::get_construct(K) == CON_list_of) {
		Emit::inv_call(InterNames::to_symbol(InterNames::extern(LISTOFTYSAY_EXNAMEF)));
		Emit::down();
			Specifications::Compiler::emit_as_val(K_value, spec);
			Emit::val(K_number, LITERAL_IVAL, 1);
		Emit::up();
	} else {
		BEGIN_COMPILATION_MODE;
		COMPILATION_MODE_EXIT(DEREFERENCE_POINTERS_CMODE);
		Emit::inv_call(InterNames::to_symbol(Kinds::Behaviour::get_iname(K)));
		Emit::down();
			Specifications::Compiler::emit_as_val(K_value, spec);
		Emit::up();
		END_COMPILATION_MODE;
	}
	Emit::inv_primitive(print_interp);
	Emit::down();
		Emit::val_text(I"\n");
	Emit::up();
}

@<Perform an internal test of the sentence converter@> =
	parse_node *p = NULL;
	pcalc_prop *prop = NULL;
	int tc = FALSE;

	if (SV_not_SN) {
		if (<s-sentence>(itc->text_supplying_the_case)) p = <<rp>>;
	} else {
		if (<s-descriptive-np>(itc->text_supplying_the_case)) p = <<rp>>;
	}
	if (p) {
		prop = Specifications::to_proposition(p);
		tc = Calculus::Propositions::Checker::type_check(prop, Calculus::Propositions::Checker::tc_no_problem_reporting());
	}
	@<Begin reporting on the internal test case@>; Streams::enable_I6_escapes(DL);
	if (p == NULL) LOG("Failed: not a condition");
	else {
		LOG("$D\n", prop);
		if (tc == FALSE) LOG("Failed: proposition would not type-check\n");
		Calculus::Propositions::Checker::type_check(prop, Calculus::Propositions::Checker::tc_problem_logging());
	}
	Streams::disable_I6_escapes(DL); @<End reporting on the internal test case@>;
