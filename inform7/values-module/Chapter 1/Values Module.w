[ValuesModule::] Values Module.

Setting up the use of this module.

@ This section simoly sets up the module in ways expected by //foundation//, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d VALUES_MODULE TRUE

@ Like all modules, this one must define a |start| and |end| function:

@e OBJECT_CREATIONS_DA
@e SPECIFICITIES_DA
@e TEXT_SUBSTITUTIONS_DA
@e VARIABLE_CREATIONS_DA
@e TABLES_DA

=
COMPILE_WRITER(instance *, Instances::log)
COMPILE_WRITER(equation *, Equations::log)
COMPILE_WRITER(nonlocal_variable *, NonlocalVariables::log)

void ValuesModule::start(void) {
	Tables::Relations::start();
	Writers::register_writer('I', &Instances::writer);
	Log::declare_aspect(OBJECT_CREATIONS_DA, L"object creations", FALSE, FALSE);
	Log::declare_aspect(SPECIFICITIES_DA, L"specificities", FALSE, FALSE);
	Log::declare_aspect(TEXT_SUBSTITUTIONS_DA, L"text substitutions", FALSE, FALSE);
	Log::declare_aspect(VARIABLE_CREATIONS_DA, L"variable creations", FALSE, FALSE);
	Log::declare_aspect(TABLES_DA, L"table construction", FALSE, FALSE);
	REGISTER_WRITER('B', Tables::log);
	REGISTER_WRITER('C', Tables::Columns::log);
	REGISTER_WRITER('O', Instances::log);
	REGISTER_WRITER('q', Equations::log);
	REGISTER_WRITER('Z', NonlocalVariables::log);
}
void ValuesModule::end(void) {
}
