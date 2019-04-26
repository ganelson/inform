[CodegenModule::] Codegen Module.

Setting up the use of this module.

@h Introduction.

@d CODEGEN_MODULE TRUE

@h Setting up the memory manager.
We need to itemise the structures we'll want to allocate:

@e I6T_intervention_MT
@e stage_set_MT
@e stage_step_MT
@e uniqueness_count_MT
@e text_literal_holder_MT
@e inter_schema_MT
@e inter_schema_node_MT
@e inter_schema_token_MT

@ With allocation functions:

=
ALLOCATE_INDIVIDUALLY(I6T_intervention)
ALLOCATE_INDIVIDUALLY(stage_set)
ALLOCATE_INDIVIDUALLY(stage_step)
ALLOCATE_INDIVIDUALLY(uniqueness_count)
ALLOCATE_INDIVIDUALLY(text_literal_holder)
ALLOCATE_INDIVIDUALLY(inter_schema)
ALLOCATE_INDIVIDUALLY(inter_schema_node)
ALLOCATE_INDIVIDUALLY(inter_schema_token)

@h The beginning.
(The client doesn't need to call the start and end routines, because the
foundation module does that automatically.)

=
void CodegenModule::start(void) {
	@<Register this module's memory allocation reasons@>;
	@<Register this module's stream writers@>;
	@<Register this module's debugging log aspects@>;
	@<Register this module's debugging log writers@>;
	@<Register this module's command line switches@>;
}

@

@e CODE_GENERATION_MREASON

@<Register this module's memory allocation reasons@> =
	Memory::reason_name(CODE_GENERATION_MREASON, "code generation workspace for objects");

@<Register this module's stream writers@> =
	;

@

@e TEMPLATE_READING_DA
@e RESOLVING_CONDITIONAL_COMPILATION_DA
@e EXTERNAL_SYMBOL_RESOLUTION_DA
@e SCHEMA_COMPILATION_DA
@e SCHEMA_COMPILATION_DETAILS_DA

@<Register this module's debugging log aspects@> =
	Log::declare_aspect(TEMPLATE_READING_DA, L"template reading", FALSE, FALSE);
	Log::declare_aspect(RESOLVING_CONDITIONAL_COMPILATION_DA, L"resolving conditional compilation", FALSE, FALSE);
	Log::declare_aspect(EXTERNAL_SYMBOL_RESOLUTION_DA, L"external symbol resolution", FALSE, FALSE);
	Log::declare_aspect(SCHEMA_COMPILATION_DA, L"schema compilation", FALSE, FALSE);
	Log::declare_aspect(SCHEMA_COMPILATION_DETAILS_DA, L"schema compilation details", FALSE, FALSE);

@<Register this module's debugging log writers@> =
	;

@<Register this module's command line switches@> =
	;

@h The end.

=
void CodegenModule::end(void) {
}
