[CodegenModule::] Codegen Module.

Setting up the use of this module.

@ This section simoly sets up the module in ways expected by //foundation//, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d CODEGEN_MODULE TRUE

@ This module defines the following classes:

@e I6T_intervention_CLASS
@e codegen_pipeline_CLASS
@e pipeline_step_CLASS
@e uniqueness_count_CLASS
@e text_literal_holder_CLASS
@e routine_body_request_CLASS
@e pipeline_stage_CLASS
@e code_generation_target_CLASS
@e code_generation_CLASS
@e generated_segment_CLASS
@e link_instruction_CLASS
@e tree_inventory_CLASS
@e tree_inventory_item_CLASS

@e index_page_CLASS
@e index_element_CLASS
@e index_tlexicon_entry_CLASS
@e simplified_scene_CLASS
@e simplified_end_CLASS
@e simplified_connector_CLASS
@e command_index_entry_CLASS
@e faux_instance_CLASS
@e connected_submap_CLASS
@e EPS_map_level_CLASS
@e rubric_holder_CLASS

=
DECLARE_CLASS(I6T_intervention)
DECLARE_CLASS(codegen_pipeline)
DECLARE_CLASS(pipeline_step)
DECLARE_CLASS(uniqueness_count)
DECLARE_CLASS(text_literal_holder)
DECLARE_CLASS(routine_body_request)
DECLARE_CLASS(pipeline_stage)
DECLARE_CLASS(code_generation_target)
DECLARE_CLASS(code_generation)
DECLARE_CLASS(generated_segment)
DECLARE_CLASS(link_instruction)
DECLARE_CLASS(tree_inventory)
DECLARE_CLASS(tree_inventory_item)

DECLARE_CLASS(index_element)
DECLARE_CLASS(index_page)
DECLARE_CLASS(index_tlexicon_entry)
DECLARE_CLASS(simplified_scene)
DECLARE_CLASS(simplified_end)
DECLARE_CLASS(simplified_connector)
DECLARE_CLASS(command_index_entry)
DECLARE_CLASS(faux_instance)
DECLARE_CLASS(connected_submap)
DECLARE_CLASS(EPS_map_level)
DECLARE_CLASS(rubric_holder)

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

@e INDEX_SORTING_MREASON
@e CODE_GENERATION_MREASON
@e SCENE_SORTING_MREASON
@e MAP_INDEX_MREASON

@<Register this module's memory allocation reasons@> =
	Memory::reason_name(CODE_GENERATION_MREASON, "code generation workspace for objects");
	Memory::reason_name(SCENE_SORTING_MREASON, "scene index sorting");
	Memory::reason_name(INDEX_SORTING_MREASON, "index sorting");
	Memory::reason_name(MAP_INDEX_MREASON, "map in the World index");

@<Register this module's stream writers@> =
	;

@

@e TEMPLATE_READING_DA
@e RESOLVING_CONDITIONAL_COMPILATION_DA
@e EXTERNAL_SYMBOL_RESOLUTION_DA
@e ELIMINATION_DA
@e CONSTANT_DEPTH_CALCULATION_DA
@e SPATIAL_MAP_DA
@e SPATIAL_MAP_WORKINGS_DA

@<Register this module's debugging log aspects@> =
	Log::declare_aspect(TEMPLATE_READING_DA, L"template reading", FALSE, FALSE);
	Log::declare_aspect(RESOLVING_CONDITIONAL_COMPILATION_DA, L"resolving conditional compilation", FALSE, FALSE);
	Log::declare_aspect(EXTERNAL_SYMBOL_RESOLUTION_DA, L"external symbol resolution", FALSE, FALSE);
	Log::declare_aspect(ELIMINATION_DA, L"code elimination", FALSE, FALSE);
	Log::declare_aspect(CONSTANT_DEPTH_CALCULATION_DA, L"constant depth calculation", FALSE, FALSE);
	Log::declare_aspect(SPATIAL_MAP_DA, L"spatial map", FALSE, FALSE);
	Log::declare_aspect(SPATIAL_MAP_WORKINGS_DA, L"spatial map workings", FALSE, FALSE);

@<Register this module's debugging log writers@> =
	;
