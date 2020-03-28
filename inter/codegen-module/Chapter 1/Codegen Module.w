[CodegenModule::] Codegen Module.

Setting up the use of this module.

@ This section simoly sets up the module in ways expected by |foundation|, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d CODEGEN_MODULE TRUE

@ To begin with, this module needs to allocate memory:

@e I6T_intervention_MT
@e codegen_pipeline_MT
@e pipeline_step_MT
@e uniqueness_count_MT
@e text_literal_holder_MT
@e routine_body_request_MT
@e pipeline_stage_MT
@e code_generation_target_MT
@e code_generation_MT
@e generated_segment_MT
@e link_instruction_MT

=
ALLOCATE_INDIVIDUALLY(I6T_intervention)
ALLOCATE_INDIVIDUALLY(codegen_pipeline)
ALLOCATE_INDIVIDUALLY(pipeline_step)
ALLOCATE_INDIVIDUALLY(uniqueness_count)
ALLOCATE_INDIVIDUALLY(text_literal_holder)
ALLOCATE_INDIVIDUALLY(routine_body_request)
ALLOCATE_INDIVIDUALLY(pipeline_stage)
ALLOCATE_INDIVIDUALLY(code_generation_target)
ALLOCATE_INDIVIDUALLY(code_generation)
ALLOCATE_INDIVIDUALLY(generated_segment)
ALLOCATE_INDIVIDUALLY(link_instruction)

@ Like all modules, this one must define a |start| and |end| function:

=
void CodegenModule::start(void) {
	@<Register this module's memory allocation reasons@>;
	@<Register this module's stream writers@>;
	@<Register this module's debugging log aspects@>;
	@<Register this module's debugging log writers@>;
}
void CodegenModule::end(void) {
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
@e ELIMINATION_DA
@e CONSTANT_DEPTH_CALCULATION_DA

@<Register this module's debugging log aspects@> =
	Log::declare_aspect(TEMPLATE_READING_DA, L"template reading", FALSE, FALSE);
	Log::declare_aspect(RESOLVING_CONDITIONAL_COMPILATION_DA, L"resolving conditional compilation", FALSE, FALSE);
	Log::declare_aspect(EXTERNAL_SYMBOL_RESOLUTION_DA, L"external symbol resolution", FALSE, FALSE);
	Log::declare_aspect(ELIMINATION_DA, L"code elimination", FALSE, FALSE);
	Log::declare_aspect(CONSTANT_DEPTH_CALCULATION_DA, L"constant depth calculation", FALSE, FALSE);

@<Register this module's debugging log writers@> =
	;
