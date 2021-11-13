[PipelineModule::] Pipeline Module.

Setting up the use of this module.

@ This section simoly sets up the module in ways expected by //foundation//, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d PIPELINE_MODULE TRUE

@ This module defines the following classes:

@e I6T_intervention_CLASS
@e inter_pipeline_CLASS
@e pipeline_step_CLASS
@e uniqueness_count_CLASS
@e text_literal_holder_CLASS
@e routine_body_request_CLASS
@e pipeline_stage_CLASS
@e link_instruction_CLASS
@e tree_inventory_CLASS
@e tree_inventory_item_CLASS

=
DECLARE_CLASS(I6T_intervention)
DECLARE_CLASS(inter_pipeline)
DECLARE_CLASS(pipeline_step)
DECLARE_CLASS(uniqueness_count)
DECLARE_CLASS(text_literal_holder)
DECLARE_CLASS(routine_body_request)
DECLARE_CLASS(pipeline_stage)
DECLARE_CLASS(link_instruction)
DECLARE_CLASS(tree_inventory)
DECLARE_CLASS(tree_inventory_item)

@ Like all modules, this one must define a |start| and |end| function:

=
void PipelineModule::start(void) {
	@<Register this module's memory allocation reasons@>;
	@<Register this module's stream writers@>;
	@<Register this module's debugging log aspects@>;
	@<Register this module's debugging log writers@>;
}
void PipelineModule::end(void) {
}

@<Register this module's memory allocation reasons@> =
	;

@<Register this module's stream writers@> =
	;

@

@e TEMPLATE_READING_DA
@e RESOLVING_CONDITIONAL_COMPILATION_DA
@e EXTERNAL_SYMBOL_RESOLUTION_DA
@e ELIMINATION_DA

@<Register this module's debugging log aspects@> =
	Log::declare_aspect(TEMPLATE_READING_DA, L"template reading", FALSE, FALSE);
	Log::declare_aspect(RESOLVING_CONDITIONAL_COMPILATION_DA, L"resolving conditional compilation", FALSE, FALSE);
	Log::declare_aspect(EXTERNAL_SYMBOL_RESOLUTION_DA, L"external symbol resolution", FALSE, FALSE);
	Log::declare_aspect(ELIMINATION_DA, L"code elimination", FALSE, FALSE);

@<Register this module's debugging log writers@> =
	;
