[IndexModule::] Index Module.

Setting up the use of this module.

@ This section simoly sets up the module in ways expected by //foundation//, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d INDEX_MODULE TRUE

@ Like all modules, this one must define a |start| and |end| function:

@e INDEX_SORTING_MREASON
@e MAP_INDEX_MREASON
@e SCENE_SORTING_MREASON

@e SPATIAL_MAP_DA
@e SPATIAL_MAP_WORKINGS_DA

=
void IndexModule::start(void) {
	Memory::reason_name(INDEX_SORTING_MREASON, "index sorting");
	Memory::reason_name(MAP_INDEX_MREASON, "map in the World index");
	Memory::reason_name(SCENE_SORTING_MREASON, "scene index sorting");
	Log::declare_aspect(SPATIAL_MAP_DA, L"spatial map", FALSE, FALSE);
	Log::declare_aspect(SPATIAL_MAP_WORKINGS_DA, L"spatial map workings", FALSE, FALSE);
}
void IndexModule::end(void) {
}

@

@e localisation_dictionary_CLASS
@e index_page_CLASS
@e index_element_CLASS
@e inter_lexicon_CLASS
@e index_lexicon_entry_CLASS
@e simplified_scene_CLASS
@e simplified_end_CLASS
@e simplified_connector_CLASS
@e command_index_entry_CLASS
@e faux_instance_CLASS
@e connected_submap_CLASS
@e EPS_map_level_CLASS
@e rubric_holder_CLASS

=
DECLARE_CLASS(localisation_dictionary)
DECLARE_CLASS(index_element)
DECLARE_CLASS(index_page)
DECLARE_CLASS(inter_lexicon)
DECLARE_CLASS(index_lexicon_entry)
DECLARE_CLASS(simplified_scene)
DECLARE_CLASS(simplified_end)
DECLARE_CLASS(simplified_connector)
DECLARE_CLASS(command_index_entry)
DECLARE_CLASS(faux_instance)
DECLARE_CLASS(connected_submap)
DECLARE_CLASS(EPS_map_level)
DECLARE_CLASS(rubric_holder)
