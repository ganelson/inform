[ValuesModule::] Values Module.

Setting up the use of this module.

@ This section simply sets up the module in ways expected by //foundation//, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d VALUES_MODULE TRUE

@ Like all modules, this one must define a |start| and |end| function:

@e LITERAL_NOTATIONS_DA
@e OBJECT_CREATIONS_DA
@e PHRASE_USAGE_DA
@e SPECIFICITIES_DA
@e TEXT_SUBSTITUTIONS_DA
@e VARIABLE_CREATIONS_DA
@e TABLES_DA
@e UNICODE_DATA_MREASON
@e LITERAL_PATTERN_MREASON

=
COMPILE_WRITER(instance *, Instances::log)
COMPILE_WRITER(equation *, Equations::log)
COMPILE_WRITER(nonlocal_variable *, NonlocalVariables::log)

void ValuesModule::start(void) {
	Tables::Relations::start();
	Writers::register_writer('I', &Instances::writer);
	Log::declare_aspect(LITERAL_NOTATIONS_DA, L"literal notations", FALSE, FALSE);
	Log::declare_aspect(OBJECT_CREATIONS_DA, L"object creations", FALSE, FALSE);
	Log::declare_aspect(PHRASE_USAGE_DA, L"phrase usage", FALSE, FALSE);
	Log::declare_aspect(SPECIFICITIES_DA, L"specificities", FALSE, FALSE);
	Log::declare_aspect(TEXT_SUBSTITUTIONS_DA, L"text substitutions", FALSE, FALSE);
	Log::declare_aspect(VARIABLE_CREATIONS_DA, L"variable creations", FALSE, FALSE);
	Log::declare_aspect(TABLES_DA, L"table construction", FALSE, FALSE);
	Memory::reason_name(UNICODE_DATA_MREASON, "Unicode data");
	Memory::reason_name(LITERAL_PATTERN_MREASON, "Literal pattern storage");
	REGISTER_WRITER('O', Instances::log);
	REGISTER_WRITER('q', Equations::log);
	REGISTER_WRITER('Z', NonlocalVariables::log);

	InternalTests::make_test_available(I"evaluation",
		&Specifications::perform_evaluation_internal_test, FALSE);
	InternalTests::make_test_available(I"dash",
		&Dash::perform_dash_internal_test, TRUE);
	InternalTests::make_test_available(I"dashlog",
		&Dash::perform_dashlog_internal_test, FALSE);
	InternalTests::make_test_available(I"sentence",
		&SPVerb::perform_sentence_internal_test, TRUE);
	InternalTests::make_test_available(I"description",
		&SPVerb::perform_description_internal_test, TRUE);
}
void ValuesModule::end(void) {
}
