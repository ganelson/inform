[KindsModule::] Kinds Module.

Setting up the use of this module.

@h Introduction.

@d KINDS_MODULE TRUE

@ To begin with, this module needs to allocate memory:

@e dimensional_rule_array_MT
@e kind_array_MT
@e kind_variable_declaration_MT
@e kind_constructor_MT
@e kind_template_definition_MT
@e kind_macro_definition_MT
@e kind_template_obligation_MT
@e kind_constructor_comparison_schema_array_MT
@e kind_constructor_casting_rule_array_MT
@e kind_constructor_instance_array_MT
@e unit_sequence_array_MT

=
ALLOCATE_IN_ARRAYS(dimensional_rule, 100)
ALLOCATE_IN_ARRAYS(kind, 1000)
ALLOCATE_INDIVIDUALLY(kind_variable_declaration)
ALLOCATE_INDIVIDUALLY(kind_constructor)
ALLOCATE_INDIVIDUALLY(kind_macro_definition)
ALLOCATE_INDIVIDUALLY(kind_template_definition)
ALLOCATE_INDIVIDUALLY(kind_template_obligation)
ALLOCATE_IN_ARRAYS(kind_constructor_casting_rule, 100)
ALLOCATE_IN_ARRAYS(kind_constructor_comparison_schema, 100)
ALLOCATE_IN_ARRAYS(kind_constructor_instance, 100)
ALLOCATE_IN_ARRAYS(unit_sequence, 50)

@h The beginning.
(The client doesn't need to call the start and end routines, because the
foundation module does that automatically.)

=
void KindsModule::start(void) {
	@<Register this module's stream writers@>;
	@<Register this module's debugging log aspects@>;
	@<Register this module's debugging log writers@>;
	@<Register this module's command line switches@>;
}

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

@<Register this module's command line switches@> =
	;

@h The end.

=
void KindsModule::end(void) {
}
