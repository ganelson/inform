[ImperativeModule::] Imperative Module.

Setting up the use of this module.

@ This section simoly sets up the module in ways expected by //foundation//, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d IMPERATIVE_MODULE TRUE

@ Like all modules, this one must define a |start| and |end| function:

@e INV_LIST_MREASON
@e DESCRIPTION_COMPILATION_DA
@e EXPRESSIONS_DA
@e LOCAL_VARIABLES_DA
@e PHRASE_COMPARISONS_DA
@e PHRASE_COMPILATION_DA
@e PHRASE_CREATIONS_DA
@e PHRASE_REGISTRATION_DA

=
COMPILE_WRITER(parse_node *, Invocations::log_list)
COMPILE_WRITER(parse_node *, Invocations::log)
COMPILE_WRITER(id_type_data *, IDTypeData::log)
COMPILE_WRITER(local_variable *, LocalVariables::log)
COMPILE_WRITER(id_body *, ImperativeDefinitions::log_body)

void ImperativeModule::start(void) {
	Writers::register_writer('L', &LocalVariables::writer);
	REGISTER_WRITER('E', Invocations::log_list);
	REGISTER_WRITER('e', Invocations::log);
	REGISTER_WRITER('h', IDTypeData::log);
	REGISTER_WRITER('k', LocalVariables::log);
	REGISTER_WRITER('R', ImperativeDefinitions::log_body);
	Memory::reason_name(INV_LIST_MREASON, "lists for type-checking invocations");
	Log::declare_aspect(DESCRIPTION_COMPILATION_DA, L"description compilation", FALSE, FALSE);
	Log::declare_aspect(EXPRESSIONS_DA, L"expressions", FALSE, FALSE);
	Log::declare_aspect(LOCAL_VARIABLES_DA, L"local variables", FALSE, FALSE);
	Log::declare_aspect(PHRASE_COMPARISONS_DA, L"phrase comparisons", FALSE, FALSE);
	Log::declare_aspect(PHRASE_COMPILATION_DA, L"phrase compilation", FALSE, FALSE);
	Log::declare_aspect(PHRASE_CREATIONS_DA, L"phrase creations", FALSE, FALSE);
	Log::declare_aspect(PHRASE_REGISTRATION_DA, L"phrase registration", FALSE, FALSE);
}
void ImperativeModule::end(void) {
}
