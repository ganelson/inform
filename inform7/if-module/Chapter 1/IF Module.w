[IFModule::] IF Module.

Setting up the use of this module.

@ The following constant exists only in tools which use this module:

@d IF_MODULE TRUE

@ Like all modules, this has a start and end function:

=
COMPILE_WRITER(action_pattern *, ActionPatterns::log)
COMPILE_WRITER(command_grammar *, CommandGrammars::log)
COMPILE_WRITER(cg_line *, CGLines::log)
COMPILE_WRITER(cg_token *, CGTokens::log)
COMPILE_WRITER(action_name_list *, ActionNameLists::log)
COMPILE_WRITER(anl_entry *, ActionNameLists::log_entry)
COMPILE_WRITER(action_name *, ActionNameNames::log)

void IFModule::start(void) {
	IFModule::create_features();
	@<Register this module's debugging log aspects@>;
	@<Register this module's debugging log writers@>;
	@<Register this module's direct memory usage@>;
	InternalTests::make_test_available(I"pattern",
		&ParseClauses::perform_pattern_internal_test, TRUE);
	ReleaseInstructions::start();
	WherePredicates::start();
	SpatialRelations::start();
	DialogueRelations::start();
	MapRelations::start();
}

@

@e ACTION_CREATIONS_DA
@e ACTION_PATTERN_COMPILATION_DA
@e ACTION_PATTERN_PARSING_DA
@e GRAMMAR_DA
@e GRAMMAR_CONSTRUCTION_DA
@e OBJECT_TREE_DA

@<Register this module's debugging log aspects@> =
	Log::declare_aspect(ACTION_CREATIONS_DA, U"action creations", FALSE, FALSE);
	Log::declare_aspect(ACTION_PATTERN_COMPILATION_DA, U"action pattern compilation",
		FALSE, FALSE);
	Log::declare_aspect(ACTION_PATTERN_PARSING_DA, U"action pattern parsing", FALSE, FALSE);
	Log::declare_aspect(GRAMMAR_DA, U"grammar", FALSE, FALSE);
	Log::declare_aspect(GRAMMAR_CONSTRUCTION_DA, U"grammar construction", FALSE, FALSE);
	Log::declare_aspect(OBJECT_TREE_DA, U"object tree", FALSE, FALSE);

@<Register this module's debugging log writers@> =
	REGISTER_WRITER('A', ActionPatterns::log);
	REGISTER_WRITER('c', CGTokens::log);
	REGISTER_WRITER('G', CommandGrammars::log);
	REGISTER_WRITER('g', CGLines::log);
	REGISTER_WRITER('L', ActionNameLists::log);
	REGISTER_WRITER('l', ActionNameNames::log);

@

@e ACTION_LISTS_MREASON

@<Register this module's direct memory usage@> =
	Memory::reason_name(ACTION_LISTS_MREASON, "action search arrays");

@ =
void IFModule::end(void) {
}

@h Plugins.
Except for the current minimal section of code, the //if// module is comprised
of the following features. They all belong to an "if" feature, but that does
nothing except to be a parent to them; it has no activation function.

= (early code)
compiler_feature *actions_feature, *going_feature,
	*backdrops_feature, *bibliographic_feature, *chronology_feature,
	*devices_feature, *map_feature, *parsing_feature, *persons_feature, *player_feature,
	*regions_feature, *scenes_feature, *scoring_feature, *showme_feature, *spatial_feature,
	*timed_rules_feature, *times_feature;
compiler_feature *performance_styles_feature = NULL;

@ =
void IFModule::create_features(void) {
	compiler_feature *ifp = Features::new(NULL, I"interactive fiction", NULL);

	/* must be created before the other world model features */
	spatial_feature = Features::new(&Spatial::start, I"spatial model", ifp);

	backdrops_feature = Features::new(&Backdrops::start, I"backdrops", ifp);
	bibliographic_feature = Features::new(&BibliographicData::start, I"bibliographic data", ifp);
	chronology_feature = Features::new(&Chronology::start_feature, I"chronology", ifp);
	devices_feature = Features::new(&PL::Devices::start, I"devices", ifp);
	map_feature = Features::new(&Map::start, I"mapping", ifp);
	persons_feature = Features::new(&PL::Persons::start, I"persons", ifp);
	player_feature = Features::new(&Player::start, I"player", ifp);
	regions_feature = Features::new(&Regions::start, I"regions", ifp);
	scenes_feature = Features::new(&Scenes::start, I"scenes", ifp);
	scoring_feature = Features::new(&TheScore::start, I"scoring", ifp);
	timed_rules_feature = Features::new(TimedRules::start, I"timed rules", ifp);
	times_feature = Features::new(TimesOfDay::start, I"times of day", ifp);

	actions_feature = Features::new(&ActionsPlugin::start, I"actions", ifp);
	going_feature = Features::new(&GoingPlugin::start, I"going", actions_feature);

	parsing_feature = Features::new(&ParsingPlugin::start, I"command", ifp);
	showme_feature = Features::new(&RTShowmeCommand::start, I"showme", parsing_feature);
	performance_styles_feature = Features::new(&PerformanceStyles::start,
		I"performance styles", dialogue_feature);
}
