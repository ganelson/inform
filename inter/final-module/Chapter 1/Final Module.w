[FinalModule::] Final Module.

Setting up the use of this module.

@ This section simoly sets up the module in ways expected by //foundation//, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d FINAL_MODULE TRUE

@ This module defines the following classes:

@e code_generator_CLASS
@e code_generation_CLASS
@e generated_segment_CLASS
@e vanilla_function_CLASS
@e I6_generation_data_CLASS
@e C_generation_data_CLASS
@e vanilla_dword_CLASS
@e C_property_CLASS
@e C_pv_pair_CLASS
@e C_property_owner_CLASS
@e C_supported_opcode_CLASS

=
DECLARE_CLASS(code_generator)
DECLARE_CLASS(code_generation)
DECLARE_CLASS(generated_segment)
DECLARE_CLASS(vanilla_function)
DECLARE_CLASS(I6_generation_data)
DECLARE_CLASS(C_generation_data)
DECLARE_CLASS(vanilla_dword)
DECLARE_CLASS(C_property)
DECLARE_CLASS(C_pv_pair)
DECLARE_CLASS(C_property_owner)
DECLARE_CLASS(C_supported_opcode)

@ Like all modules, this one must define a |start| and |end| function:

=
void FinalModule::start(void) {
	@<Register this module's memory allocation reasons@>;
	@<Register this module's stream writers@>;
	@<Register this module's debugging log aspects@>;
	@<Register this module's debugging log writers@>;
}
void FinalModule::end(void) {
}

@

@e CODE_GENERATION_MREASON

@<Register this module's memory allocation reasons@> =
	Memory::reason_name(CODE_GENERATION_MREASON, "code generation workspace for objects");

@<Register this module's stream writers@> =
	;

@e PROPERTY_ALLOCATION_DA

@<Register this module's debugging log aspects@> =
	Log::declare_aspect(PROPERTY_ALLOCATION_DA, L"property allocation", FALSE, FALSE);

@<Register this module's debugging log writers@> =
	;
