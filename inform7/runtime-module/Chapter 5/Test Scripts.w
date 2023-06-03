[RTTestCommand::] Test Scripts.

To compile the tests submodule for a compilation unit, which contains
_test packages.

@h Compilation data.
Each |test_scenario| object contains this data:

=
typedef struct test_scenario_compilation_data {
	struct package_request *ts_package;
	struct inter_name *text_iname; /* name at runtime for the text of the commands */
	struct inter_name *req_iname; /* ditto for the array of requirements */
} test_scenario_compilation_data;

test_scenario_compilation_data RTTestCommand::new_compilation_data(test_scenario *test) {
	test_scenario_compilation_data tscd;
	tscd.ts_package = NULL;
	tscd.text_iname = NULL;
	tscd.req_iname = NULL;
	return tscd;
}

@ The package and its inames are created on demand:

=
package_request *RTTestCommand::package(test_scenario *test) {
	if (test->compilation_data.ts_package == NULL)
		test->compilation_data.ts_package =
			Hierarchy::local_package_to(TESTS_HAP, test->sentence_test_declared_at);
	return test->compilation_data.ts_package;
}

inter_name *RTTestCommand::text_iname(test_scenario *test) {
	if (test->compilation_data.text_iname == NULL)
		test->compilation_data.text_iname =
			Hierarchy::make_iname_in(SCRIPT_HL, RTTestCommand::package(test));
	return test->compilation_data.text_iname;
}

inter_name *RTTestCommand::req_iname(test_scenario *test) {
	if (test->compilation_data.req_iname == NULL)
		test->compilation_data.req_iname =
			Hierarchy::make_iname_in(REQUIREMENTS_HL, RTTestCommand::package(test));
	return test->compilation_data.req_iname;
}

@h Compilation.

=
void RTTestCommand::compile(void) {
	test_scenario *test;
	LOOP_OVER(test, test_scenario) {
		text_stream *desc = Str::new();
		WRITE_TO(desc, "test scenario '%W'", test->name);
		Sequence::queue(&RTTestCommand::compilation_agent,
			STORE_POINTER_test_scenario(test), desc);
	}
}

@ An individual test scenario is compiled here:

=
void RTTestCommand::compilation_agent(compilation_subtask *t) {
	test_scenario *test = RETRIEVE_POINTER_test_scenario(t->data);
	Hierarchy::apply_metadata_from_wording(RTTestCommand::package(test),
		TEST_NAME_MD_HL, test->name);
	int l = 0;
	text_stream *p = test->text_of_script;
	for (int i=0, L = Str::len(p); i<L; i++, l++)
		if (Str::includes_wide_string_at(p, L"[']", i))
			l -= 2;
	Hierarchy::apply_metadata_from_number(RTTestCommand::package(test),
		TEST_LENGTH_MD_HL, (inter_ti) l);

	packaging_state save;
	if (TargetVMs::is_16_bit(Task::vm()))
		save = EmitArrays::begin_byte(RTTestCommand::text_iname(test), K_text);
	else
		save = EmitArrays::begin_word(RTTestCommand::text_iname(test), K_text);
	TEMPORARY_TEXT(tttext)
	TranscodeText::from_stream(tttext, test->text_of_script,
		CT_EXPAND_APOSTROPHES + CT_RECOGNISE_APOSTROPHE_SUBSTITUTION);
	WRITE_TO(tttext, "||||");
	LOOP_THROUGH_TEXT(pos, tttext)
		EmitArrays::numeric_entry((inter_ti) Str::get(pos));
	DISCARD_TEXT(tttext)
	EmitArrays::end(save);

	save = EmitArrays::begin_word(RTTestCommand::req_iname(test), K_value);
	if (test->place == NULL) EmitArrays::numeric_entry(0);
	else EmitArrays::iname_entry(RTInstances::value_iname(test->place));
	for (int j=0; j<test->no_possessions; j++) {
		if (test->possessions[j] == NULL) EmitArrays::numeric_entry(0);
		else EmitArrays::iname_entry(RTInstances::value_iname(test->possessions[j]));
	}
	EmitArrays::numeric_entry(0);
	EmitArrays::end(save);
}
