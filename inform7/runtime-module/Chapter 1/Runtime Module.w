[RuntimeModule::] Runtime Module.

Setting up the use of this module.

@ This section simoly sets up the module in ways expected by //foundation//, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d RUNTIME_MODULE TRUE

@ Like all modules, this one must define a |start| and |end| function:

@e EMIT_ARRAY_MREASON
@e PARTITION_MREASON
@e RELATION_CONSTRUCTION_MREASON

=
void RuntimeModule::start(void) {
	Memory::reason_name(EMIT_ARRAY_MREASON, "emitter array storage");
	Memory::reason_name(PARTITION_MREASON, "initial state for relations in groups");
	Memory::reason_name(RELATION_CONSTRUCTION_MREASON, "relation bitmap storage");
}
void RuntimeModule::end(void) {
}
