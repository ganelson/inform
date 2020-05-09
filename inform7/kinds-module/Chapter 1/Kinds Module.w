[KindsModule::] Kinds Module.

Setting up the use of this module.

@ This section simoly sets up the module in ways expected by |foundation|, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d KINDS_MODULE TRUE

@ This module defines the following classes:

@e dimensional_rule_CLASS
@e kind_CLASS
@e kind_variable_declaration_CLASS
@e kind_constructor_CLASS
@e kind_template_definition_CLASS
@e kind_macro_definition_CLASS
@e kind_template_obligation_CLASS
@e kind_constructor_comparison_schema_CLASS
@e kind_constructor_casting_rule_CLASS
@e kind_constructor_instance_CLASS
@e unit_sequence_CLASS

=
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(dimensional_rule, 100)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(kind, 1000)
DECLARE_CLASS(kind_variable_declaration)
DECLARE_CLASS(kind_constructor)
DECLARE_CLASS(kind_macro_definition)
DECLARE_CLASS(kind_template_definition)
DECLARE_CLASS(kind_template_obligation)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(kind_constructor_casting_rule, 100)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(kind_constructor_comparison_schema, 100)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(kind_constructor_instance, 100)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(unit_sequence, 50)

@ Like all modules, this one must define a |start| and |end| function:

=
void KindsModule::start(void) {
	@<Register this module's memory allocation reasons@>;
	@<Register this module's stream writers@>;
	@<Register this module's debugging log aspects@>;
	@<Register this module's debugging log writers@>;
}
void KindsModule::end(void) {
}

@<Register this module's memory allocation reasons@> =
	;

@<Register this module's stream writers@> =
	;

@

@e KIND_CHANGES_DA
@e KIND_CHECKING_DA
@e KIND_CREATIONS_DA
@e MATCHING_DA

@<Register this module's debugging log aspects@> =
	Log::declare_aspect(KIND_CHANGES_DA, L"kind changes", FALSE, TRUE);
	Log::declare_aspect(KIND_CHECKING_DA, L"kind checking", FALSE, FALSE);
	Log::declare_aspect(KIND_CREATIONS_DA, L"kind creations", FALSE, FALSE);
	Log::declare_aspect(MATCHING_DA, L"matching", FALSE, FALSE);

@<Register this module's debugging log writers@> =
	;
