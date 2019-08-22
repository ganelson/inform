[CodegenModule::] Codegen Module.

Setting up the use of this module.

@h Introduction.

@d CODEGEN_MODULE TRUE

@h Setting up the memory manager.
We need to itemise the structures we'll want to allocate:

@e I6T_intervention_MT
@e codegen_pipeline_MT
@e pipeline_step_MT
@e uniqueness_count_MT
@e text_literal_holder_MT
@e inter_schema_MT
@e inter_schema_node_MT
@e inter_schema_token_MT
@e routine_body_request_MT
@e pipeline_stage_MT
@e code_generation_target_MT
@e code_generation_MT
@e generated_segment_MT
@e inter_name_array_MT
@e inter_name_generator_array_MT
@e package_request_MT
@e hierarchy_location_MT
@e hierarchy_attachment_point_MT
@e hierarchy_metadatum_MT
@e module_package_MT
@e submodule_identity_MT
@e submodule_request_MT
@e compilation_module_MT

@ With allocation functions:

=
ALLOCATE_INDIVIDUALLY(I6T_intervention)
ALLOCATE_INDIVIDUALLY(codegen_pipeline)
ALLOCATE_INDIVIDUALLY(pipeline_step)
ALLOCATE_INDIVIDUALLY(uniqueness_count)
ALLOCATE_INDIVIDUALLY(text_literal_holder)
ALLOCATE_INDIVIDUALLY(inter_schema)
ALLOCATE_INDIVIDUALLY(inter_schema_node)
ALLOCATE_INDIVIDUALLY(inter_schema_token)
ALLOCATE_INDIVIDUALLY(routine_body_request)
ALLOCATE_INDIVIDUALLY(pipeline_stage)
ALLOCATE_INDIVIDUALLY(code_generation_target)
ALLOCATE_INDIVIDUALLY(code_generation)
ALLOCATE_INDIVIDUALLY(generated_segment)
ALLOCATE_INDIVIDUALLY(hierarchy_location)
ALLOCATE_INDIVIDUALLY(hierarchy_attachment_point)
ALLOCATE_INDIVIDUALLY(hierarchy_metadatum)
ALLOCATE_INDIVIDUALLY(package_request)
ALLOCATE_INDIVIDUALLY(module_package)
ALLOCATE_INDIVIDUALLY(submodule_identity)
ALLOCATE_INDIVIDUALLY(submodule_request)
ALLOCATE_INDIVIDUALLY(compilation_module)
ALLOCATE_IN_ARRAYS(inter_name, 1000)
ALLOCATE_IN_ARRAYS(inter_name_generator, 1000)

#ifdef CORE_MODULE
MAKE_ANNOTATION_FUNCTIONS(explicit_iname, inter_name)
MAKE_ANNOTATION_FUNCTIONS(module, compilation_module)
#endif

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
@e ELIMINATION_DA
@e PACKAGING_DA

@<Register this module's debugging log aspects@> =
	Log::declare_aspect(TEMPLATE_READING_DA, L"template reading", FALSE, FALSE);
	Log::declare_aspect(RESOLVING_CONDITIONAL_COMPILATION_DA, L"resolving conditional compilation", FALSE, FALSE);
	Log::declare_aspect(EXTERNAL_SYMBOL_RESOLUTION_DA, L"external symbol resolution", FALSE, FALSE);
	Log::declare_aspect(SCHEMA_COMPILATION_DA, L"schema compilation", FALSE, FALSE);
	Log::declare_aspect(SCHEMA_COMPILATION_DETAILS_DA, L"schema compilation details", FALSE, FALSE);
	Log::declare_aspect(ELIMINATION_DA, L"code elimination", FALSE, FALSE);
	Log::declare_aspect(PACKAGING_DA, L"packaging", FALSE, FALSE);

@<Register this module's debugging log writers@> =
	Writers::register_logger('1', InterSchemas::log);

@<Register this module's command line switches@> =
	;

@h The end.

=
void CodegenModule::end(void) {
}
