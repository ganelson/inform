[FinalModule::] Final Module.

Setting up the use of this module.

@ This section simply sets up the module in ways expected by //foundation//, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d FINAL_MODULE TRUE

@ Like all modules, this one must define a `start` and `end` function:

@e CODE_GENERATION_MREASON

@e PROPERTY_ALLOCATION_DA

=
void FinalModule::start(void) {
	Memory::reason_name(CODE_GENERATION_MREASON, "code generation workspace for objects");
	Log::declare_aspect(PROPERTY_ALLOCATION_DA, U"property allocation", FALSE, FALSE);
}
void FinalModule::end(void) {
}
