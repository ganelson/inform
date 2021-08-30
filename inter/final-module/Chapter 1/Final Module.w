[FinalModule::] Final Module.

Setting up the use of this module.

@ This section simoly sets up the module in ways expected by //foundation//, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d FINAL_MODULE TRUE

@ This module defines the following classes:

@e final_c_function_CLASS
@e kov_value_stick_CLASS
@e I6_generation_data_CLASS
@e C_generation_data_CLASS
@e C_dword_CLASS

=
DECLARE_CLASS(final_c_function)
DECLARE_CLASS(kov_value_stick)
DECLARE_CLASS(I6_generation_data)
DECLARE_CLASS(C_generation_data)
DECLARE_CLASS(C_dword)

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

@<Register this module's debugging log aspects@> =
	;

@<Register this module's debugging log writers@> =
	;
