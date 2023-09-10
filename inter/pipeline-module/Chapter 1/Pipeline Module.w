[PipelineModule::] Pipeline Module.

Setting up the use of this module.

@ This section simply sets up the module in ways expected by //foundation//, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d PIPELINE_MODULE TRUE

@ This module defines the following classes:

@e inter_pipeline_CLASS
@e pipeline_step_CLASS
@e uniqueness_count_CLASS
@e text_literal_holder_CLASS
@e function_body_request_CLASS
@e pipeline_stage_CLASS
@e attachment_instruction_CLASS
@e tree_inventory_CLASS
@e tree_inventory_item_CLASS

=
DECLARE_CLASS(inter_pipeline)
DECLARE_CLASS(pipeline_step)
DECLARE_CLASS(uniqueness_count)
DECLARE_CLASS(text_literal_holder)
DECLARE_CLASS(function_body_request)
DECLARE_CLASS(pipeline_stage)
DECLARE_CLASS(attachment_instruction)
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
	Log::declare_aspect(TEMPLATE_READING_DA,
		U"template reading", FALSE, FALSE);
	Log::declare_aspect(RESOLVING_CONDITIONAL_COMPILATION_DA,
		U"resolving conditional compilation", FALSE, FALSE);
	Log::declare_aspect(EXTERNAL_SYMBOL_RESOLUTION_DA,
		U"external symbol resolution", FALSE, FALSE);
	Log::declare_aspect(ELIMINATION_DA,
		U"code elimination", FALSE, FALSE);

@<Register this module's debugging log writers@> =
	;

@ Somewhere, we need to store the architecture set on the command line of either
//inter// or //inform7// (whichever one we are currently running inside). This
is where:

=
inter_architecture *architecture_set_at_command_line = NULL;
int PipelineModule::set_architecture(text_stream *name) {
	architecture_set_at_command_line = Architectures::from_codename(name);
	if (architecture_set_at_command_line) return TRUE;
	return FALSE;
}

void PipelineModule::set_architecture_to(inter_architecture *A) {
	architecture_set_at_command_line = A;
}

inter_architecture *PipelineModule::get_architecture(void) {
	return architecture_set_at_command_line;
}
