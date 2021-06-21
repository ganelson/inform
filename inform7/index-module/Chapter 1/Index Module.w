[IndexModule::] Index Module.

Setting up the use of this module.

@ This section simoly sets up the module in ways expected by //foundation//, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d INDEX_MODULE TRUE

@ Like all modules, this one must define a |start| and |end| function:

@e INDEX_SORTING_MREASON
@e MAP_INDEX_MREASON
@e TYPE_TABLES_MREASON

@e faux_instance_CLASS

=
DECLARE_CLASS(faux_instance)

void IndexModule::start(void) {
	Memory::reason_name(INDEX_SORTING_MREASON, "index sorting");
	Memory::reason_name(MAP_INDEX_MREASON, "map in the World index");
	Memory::reason_name(TYPE_TABLES_MREASON, "tables of details of the kinds of values");
}
void IndexModule::end(void) {
}
