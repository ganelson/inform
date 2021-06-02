[IndexModule::] Index Module.

Setting up the use of this module.

@ This section simoly sets up the module in ways expected by //foundation//, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d INDEX_MODULE TRUE

@ Like all modules, this one must define a |start| and |end| function:

@e PHRASE_USAGE_DA
@e INDEX_SORTING_MREASON
@e MAP_INDEX_MREASON
@e TYPE_TABLES_MREASON

=
COMPILE_WRITER(heading *, IXContents::log)

void IndexModule::start(void) {
	REGISTER_WRITER('H', IXContents::log);
	Log::declare_aspect(PHRASE_USAGE_DA, L"phrase usage", FALSE, FALSE);
	Memory::reason_name(INDEX_SORTING_MREASON, "index sorting");
	Memory::reason_name(MAP_INDEX_MREASON, "map in the World index");
	Memory::reason_name(TYPE_TABLES_MREASON, "tables of details of the kinds of values");

	InternalTests::make_test_available(I"map", &PL::SpatialMap::perform_map_internal_test, TRUE);
}
void IndexModule::end(void) {
}
