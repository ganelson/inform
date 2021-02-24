[IFModule::] IF Module.

Setting up the use of this module.

@ This section simoly sets up the module in ways expected by //foundation//, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d IF_MODULE TRUE

@ This module defines the following classes:

@e action_name_CLASS
@e auxiliary_file_CLASS
@e backdrop_found_in_notice_CLASS
@e cached_understanding_CLASS
@e command_index_entry_CLASS
@e connected_submap_CLASS
@e direction_inference_data_CLASS
@e door_dir_notice_CLASS
@e door_to_notice_CLASS
@e EPS_map_level_CLASS
@e found_in_inference_data_CLASS
@e grammar_line_CLASS
@e grammar_verb_CLASS
@e loop_over_scope_CLASS
@e map_data_CLASS
@e named_action_pattern_CLASS
@e noun_filter_token_CLASS
@e parentage_here_inference_data_CLASS
@e parentage_inference_data_CLASS
@e parse_name_notice_CLASS
@e parsing_data_CLASS
@e parsing_pp_data_CLASS
@e part_of_inference_data_CLASS
@e regions_data_CLASS
@e release_instructions_CLASS
@e reserved_command_verb_CLASS
@e rubric_holder_CLASS
@e scene_CLASS
@e slash_gpr_CLASS
@e spatial_data_CLASS

@e action_name_list_CLASS
@e action_pattern_CLASS
@e ap_optional_clause_CLASS
@e scene_connector_CLASS
@e understanding_item_CLASS
@e understanding_reference_CLASS

=
DECLARE_CLASS(action_name)
DECLARE_CLASS(auxiliary_file)
DECLARE_CLASS(backdrop_found_in_notice)
DECLARE_CLASS(cached_understanding)
DECLARE_CLASS(command_index_entry)
DECLARE_CLASS(connected_submap)
DECLARE_CLASS(direction_inference_data)
DECLARE_CLASS(door_dir_notice)
DECLARE_CLASS(door_to_notice)
DECLARE_CLASS(EPS_map_level)
DECLARE_CLASS(found_in_inference_data)
DECLARE_CLASS(grammar_line)
DECLARE_CLASS(grammar_verb)
DECLARE_CLASS(loop_over_scope)
DECLARE_CLASS(map_data)
DECLARE_CLASS(named_action_pattern)
DECLARE_CLASS(noun_filter_token)
DECLARE_CLASS(parentage_here_inference_data)
DECLARE_CLASS(parentage_inference_data)
DECLARE_CLASS(parse_name_notice)
DECLARE_CLASS(parsing_data)
DECLARE_CLASS(parsing_pp_data)
DECLARE_CLASS(part_of_inference_data)
DECLARE_CLASS(regions_data)
DECLARE_CLASS(release_instructions)
DECLARE_CLASS(reserved_command_verb)
DECLARE_CLASS(rubric_holder)
DECLARE_CLASS(scene)
DECLARE_CLASS(slash_gpr)
DECLARE_CLASS(spatial_data)

DECLARE_CLASS_ALLOCATED_IN_ARRAYS(action_name_list, 1000)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(action_pattern, 100)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(ap_optional_clause, 400)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(scene_connector, 1000)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(understanding_item, 100)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(understanding_reference, 100)

@h Plugins.
Note that the "if" plugin itself does nothihg except to be a parent
to all these others; it doesn't even have an activation function.

=
plugin *if_plugin,
	*spatial_plugin, *map_plugin, *persons_plugin,
	*player_plugin, *regions_plugin, *backdrops_plugin,
	*devices_plugin, *showme_plugin,
	*times_plugin, *scenes_plugin, *scoring_plugin,
	*bibliographic_plugin;

@

= (early code)
	plugin *parsing_plugin, *chronology_plugin, *actions_plugin;

@h The beginning.
(The client doesn't need to call the start and end routines, because the
foundation module does that automatically.)

=
COMPILE_WRITER(action_pattern *, PL::Actions::Patterns::log)
COMPILE_WRITER(grammar_verb *, PL::Parsing::Verbs::log)
COMPILE_WRITER(grammar_line *, PL::Parsing::Lines::log)
COMPILE_WRITER(action_name_list *, PL::Actions::ConstantLists::log)
COMPILE_WRITER(action_name *, PL::Actions::log)

void IFModule::start(void) {
	@<Create this module's plugins@>;
	@<Register this module's debugging log aspects@>;
	@<Register this module's debugging log writers@>;
	ReleaseInstructions::start();
	WherePredicates::start();
	PL::SpatialRelations::start();
	PL::MapDirections::start();
}
void IFModule::end(void) {
}

@<Create this module's plugins@> =
	if_plugin = PluginManager::new(NULL, I"interactive fiction", NULL);

	spatial_plugin = PluginManager::new(&PL::Spatial::start, I"spatial model", if_plugin);
	map_plugin = PluginManager::new(&PL::Map::start, I"mapping", if_plugin);
	persons_plugin = PluginManager::new(&PL::Persons::start, I"persons", if_plugin);
	player_plugin = PluginManager::new(&PL::Player::start, I"player", if_plugin);
	scoring_plugin = PluginManager::new(&PL::Score::start, I"scoring", if_plugin);
	regions_plugin = PluginManager::new(&PL::Regions::start, I"regions", if_plugin);
	backdrops_plugin = PluginManager::new(&PL::Backdrops::start, I"backdrops", if_plugin);
	devices_plugin = PluginManager::new(&PL::Devices::start, I"devices", if_plugin);
	showme_plugin = PluginManager::new(&PL::Showme::start, I"showme", if_plugin);
	times_plugin = PluginManager::new(TimesOfDay::start, I"times of day", if_plugin);
	scenes_plugin = PluginManager::new(&PL::Scenes::start, I"scenes", if_plugin);
	bibliographic_plugin = PluginManager::new(&BibliographicData::start, I"bibliographic data", if_plugin);
	chronology_plugin = PluginManager::new(&Chronology::start_plugin, I"chronology", if_plugin);

	actions_plugin = PluginManager::new(&ActionsPlugin::start, I"actions", if_plugin);

	parsing_plugin = PluginManager::new(&ParsingPlugin::start, I"command", if_plugin);

@

@e ACTION_CREATIONS_DA
@e ACTION_PATTERN_COMPILATION_DA
@e ACTION_PATTERN_PARSING_DA
@e GRAMMAR_DA
@e GRAMMAR_CONSTRUCTION_DA
@e OBJECT_TREE_DA
@e SPATIAL_MAP_DA
@e SPATIAL_MAP_WORKINGS_DA

@<Register this module's debugging log aspects@> =
	Log::declare_aspect(ACTION_CREATIONS_DA, L"action creations", FALSE, FALSE);
	Log::declare_aspect(ACTION_PATTERN_COMPILATION_DA, L"action pattern compilation", FALSE, FALSE);
	Log::declare_aspect(ACTION_PATTERN_PARSING_DA, L"action pattern parsing", FALSE, FALSE);
	Log::declare_aspect(GRAMMAR_DA, L"grammar", FALSE, FALSE);
	Log::declare_aspect(GRAMMAR_CONSTRUCTION_DA, L"grammar construction", FALSE, FALSE);
	Log::declare_aspect(OBJECT_TREE_DA, L"object tree", FALSE, FALSE);
	Log::declare_aspect(SPATIAL_MAP_DA, L"spatial map", FALSE, FALSE);
	Log::declare_aspect(SPATIAL_MAP_WORKINGS_DA, L"spatial map workings", FALSE, FALSE);

@<Register this module's debugging log writers@> =
	REGISTER_WRITER('A', PL::Actions::Patterns::log);
	REGISTER_WRITER('G', PL::Parsing::Verbs::log);
	REGISTER_WRITER('g', PL::Parsing::Lines::log);
	REGISTER_WRITER('L', PL::Actions::ConstantLists::log);
	REGISTER_WRITER('l', PL::Actions::log);
