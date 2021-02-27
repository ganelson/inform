[IFModule::] IF Module.

Setting up the use of this module.

@ The following constant exists only in tools which use this module:

@d IF_MODULE TRUE

@ Like all modules, this has a start and end function:

=
COMPILE_WRITER(action_pattern *, ActionPatterns::log)
COMPILE_WRITER(grammar_verb *, PL::Parsing::Verbs::log)
COMPILE_WRITER(grammar_line *, PL::Parsing::Lines::log)
COMPILE_WRITER(anl_head *, ActionNameLists::log)
COMPILE_WRITER(action_name_list *, ActionNameLists::log_anl)
COMPILE_WRITER(action_name *, ActionNameNames::log)

void IFModule::start(void) {
	IFModule::create_plugins();
	@<Register this module's debugging log aspects@>;
	@<Register this module's debugging log writers@>;
	ReleaseInstructions::start();
	WherePredicates::start();
	SpatialRelations::start();
	MapRelations::start();
}

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
	Log::declare_aspect(ACTION_PATTERN_COMPILATION_DA, L"action pattern compilation",
		FALSE, FALSE);
	Log::declare_aspect(ACTION_PATTERN_PARSING_DA, L"action pattern parsing", FALSE, FALSE);
	Log::declare_aspect(GRAMMAR_DA, L"grammar", FALSE, FALSE);
	Log::declare_aspect(GRAMMAR_CONSTRUCTION_DA, L"grammar construction", FALSE, FALSE);
	Log::declare_aspect(OBJECT_TREE_DA, L"object tree", FALSE, FALSE);
	Log::declare_aspect(SPATIAL_MAP_DA, L"spatial map", FALSE, FALSE);
	Log::declare_aspect(SPATIAL_MAP_WORKINGS_DA, L"spatial map workings", FALSE, FALSE);

@<Register this module's debugging log writers@> =
	REGISTER_WRITER('A', ActionPatterns::log);
	REGISTER_WRITER('G', PL::Parsing::Verbs::log);
	REGISTER_WRITER('g', PL::Parsing::Lines::log);
	REGISTER_WRITER('L', ActionNameLists::log);
	REGISTER_WRITER('8', ActionNameLists::log_anl);
	REGISTER_WRITER('l', ActionNameNames::log);

@ =
void IFModule::end(void) {
}

@h Plugins.
Except for the current minimal section of code, the //if// module is comprised
of the following plugins. They all belong to an "if" plugin, but that does
nothing except to be a parent to them; it has no activation function.

= (early code)
plugin *actions_plugin, *backdrops_plugin, *bibliographic_plugin, *chronology_plugin,
	*devices_plugin, *map_plugin, *parsing_plugin, *persons_plugin, *player_plugin,
	*regions_plugin, *scenes_plugin, *scoring_plugin, *showme_plugin, *spatial_plugin,
	*times_plugin;

@ =
void IFModule::create_plugins(void) {
	plugin *ifp = PluginManager::new(NULL, I"interactive fiction", NULL);

	/* must be created before the other world model plugins */
	spatial_plugin = PluginManager::new(&Spatial::start, I"spatial model", ifp);

	backdrops_plugin = PluginManager::new(&Backdrops::start, I"backdrops", ifp);
	bibliographic_plugin = PluginManager::new(&BibliographicData::start, I"bibliographic data", ifp);
	chronology_plugin = PluginManager::new(&Chronology::start_plugin, I"chronology", ifp);
	devices_plugin = PluginManager::new(&PL::Devices::start, I"devices", ifp);
	map_plugin = PluginManager::new(&Map::start, I"mapping", ifp);
	persons_plugin = PluginManager::new(&PL::Persons::start, I"persons", ifp);
	player_plugin = PluginManager::new(&Player::start, I"player", ifp);
	regions_plugin = PluginManager::new(&Regions::start, I"regions", ifp);
	scenes_plugin = PluginManager::new(&Scenes::start, I"scenes", ifp);
	scoring_plugin = PluginManager::new(&TheScore::start, I"scoring", ifp);
	times_plugin = PluginManager::new(TimesOfDay::start, I"times of day", ifp);

	actions_plugin = PluginManager::new(&ActionsPlugin::start, I"actions", ifp);

	parsing_plugin = PluginManager::new(&ParsingPlugin::start, I"command", ifp);
	showme_plugin = PluginManager::new(&RTShowmeCommand::start, I"showme", parsing_plugin);
}
