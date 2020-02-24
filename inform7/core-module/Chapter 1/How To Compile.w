[Sequence::] How To Compile.

To configure the many locations used in the host filing system.

@ =
int no_compile_tasks_carried_out = 0;

int Sequence::carry_out(compile_task_data *ctd) {
	if (no_compile_tasks_carried_out == 0) @<Boot up the compiler@>;
	
	clock_t start = clock();
	@<Perform lexical analysis@>;
	@<Perform semantic analysis@>;
	@<Read the assertions in two passes@>;
	@<Make the model world@>;
	@<Tables and grammar@>;
	@<Phrases and rules@>;
	@<Generate inter@>;
	@<Generate index and bibliographic file@>;
	clock_t end = clock();
	int cpu_time_used = ((int) (end - start)) / (CLOCKS_PER_SEC/100);
	LOG("Compile CPU time: %d centiseconds\n", cpu_time_used);
	if (problem_count > 0) return FALSE;
	return TRUE;
}

@

@d COMPILATION_STEP(routine, mark) {
	if (problem_count == 0) {
		clock_t now = clock();
		routine();
		int cs = ((int) (clock() - now)) / (CLOCKS_PER_SEC/100);
		if (cs > 0) LOG(".... " #routine "() took %dcs\n", cs);
	}
}

@d COMPILATION_STEP_IF(plugin, routine, mark) {
	if ((problem_count == 0) && (Plugins::Manage::plugged_in(plugin))) {
		clock_t now = clock();
		routine();
		int cs = ((int) (clock() - now)) / (CLOCKS_PER_SEC/100);
		if (cs > 0) LOG(".... " #routine "() took %dcs\n", cs);
	}
}

@<Boot up the compiler@> =
	Emit::begin();
	Semantics::read_preform();
	Plugins::Manage::start();
	InferenceSubjects::begin();
	Index::DocReferences::read_xrefs();
	doc_references_top = lexer_wordcount - 1;

@<Perform lexical analysis@> =
	ProgressBar::update_progress_bar(0, 0);
	if (problem_count == 0) Sequence::go_to_log_phase(I"Lexical analysis");
	SourceFiles::read(Task::project()->as_copy);
	COMPILATION_STEP(Sentences::RuleSubtrees::create_standard_csps, I"Sentences::RuleSubtrees::create_standard_csps")

@<Perform semantic analysis@> =
	ProgressBar::update_progress_bar(1, 0);
	if (problem_count == 0) Sequence::go_to_log_phase(I"Semantic analysis Ia");
	Projects::activate_plugins(Task::project());
	COMPILATION_STEP(ParseTreeUsage::plant_parse_tree, I"ParseTreeUsage::plant_parse_tree")
	COMPILATION_STEP(StructuralSentences::break_source, I"StructuralSentences::break_source")
	COMPILATION_STEP(Extensions::Inclusion::traverse, I"Extensions::Inclusion::traverse")
	COMPILATION_STEP(Sentences::Headings::satisfy_dependencies, I"Sentences::Headings::satisfy_dependencies")

	if (problem_count == 0) Sequence::go_to_log_phase(I"Initialise language semantics");
	COMPILATION_STEP(Plugins::Manage::start_plugins, I"Plugins::Manage::start_plugins");
	Projects::load_types(Task::project());
	COMPILATION_STEP(BinaryPredicates::make_built_in, I"BinaryPredicates::make_built_in")
	COMPILATION_STEP(NewVerbs::add_inequalities, I"NewVerbs::add_inequalities")

	if (problem_count == 0) Sequence::go_to_log_phase(I"Semantic analysis Ib");
	COMPILATION_STEP(Sentences::VPs::traverse, I"Sentences::VPs::traverse")
	COMPILATION_STEP(Sentences::Rearrangement::tidy_up_ofs_and_froms, I"Sentences::Rearrangement::tidy_up_ofs_and_froms")
	COMPILATION_STEP(Sentences::RuleSubtrees::register_recently_lexed_phrases, I"Sentences::RuleSubtrees::register_recently_lexed_phrases")
	COMPILATION_STEP(StructuralSentences::declare_source_loaded, I"StructuralSentences::declare_source_loaded")
	COMPILATION_STEP(Kinds::Interpreter::include_templates_for_kinds, I"Kinds::Interpreter::include_templates_for_kinds")

	if (problem_count == 0) Sequence::go_to_log_phase(I"Semantic analysis II");
	COMPILATION_STEP(ParseTreeUsage::verify, I"ParseTreeUsage::verify")
	COMPILATION_STEP(Extensions::Files::check_versions, I"Extensions::Files::check_versions")
	COMPILATION_STEP(Sentences::Headings::make_tree, I"Sentences::Headings::make_tree")
	COMPILATION_STEP(Sentences::Headings::write_as_xml, I"Sentences::Headings::write_as_xml")
	COMPILATION_STEP(Sentences::Headings::write_as_xml, I"Sentences::Headings::write_as_xml")
	COMPILATION_STEP(Modules::traverse_to_define, I"Modules::traverse_to_define")

	if (problem_count == 0) Sequence::go_to_log_phase(I"Semantic analysis III");
	COMPILATION_STEP(Phrases::Adjectives::traverse, I"Phrases::Adjectives::traverse")
	COMPILATION_STEP(Equations::traverse_to_create, I"Equations::traverse_to_create")
	COMPILATION_STEP(Tables::traverse_to_create, I"Tables::traverse_to_create")
	COMPILATION_STEP(Phrases::Manager::traverse_for_names, I"Phrases::Manager::traverse_for_names")

@<Read the assertions in two passes@> =
	ProgressBar::update_progress_bar(2, 0);
	if (problem_count == 0) Sequence::go_to_log_phase(I"First pass through assertions");
	if (problem_count == 0) Assertions::Traverse::traverse(1);
	COMPILATION_STEP(Tables::traverse_to_stock, I"Tables::traverse_to_stock")
	if (problem_count == 0) Sequence::go_to_log_phase(I"Second pass through assertions");
	if (problem_count == 0) Assertions::Traverse::traverse(2);
	COMPILATION_STEP(Kinds::RunTime::kind_declarations, I"Kinds::RunTime::kind_declarations")

@<Make the model world@> =
	if (problem_count == 0) Sequence::go_to_log_phase(I"Making the model world");
	COMPILATION_STEP(UseOptions::compile, I"UseOptions::compile")
	COMPILATION_STEP(Properties::emit, I"Properties::emit")
	COMPILATION_STEP(Properties::Emit::allocate_attributes, I"Properties::Emit::allocate_attributes")
	COMPILATION_STEP(PL::Actions::name_all, I"PL::Actions::name_all")
	COMPILATION_STEP(UseNouns::name_all, I"UseNouns::name_all")
	COMPILATION_STEP(World::complete, I"World::complete")
	COMPILATION_STEP(Properties::Measurement::validate_definitions, I"Properties::Measurement::validate_definitions")
	COMPILATION_STEP(BinaryPredicates::make_built_in_further, I"BinaryPredicates::make_built_in_further")
	COMPILATION_STEP(PL::Bibliographic::IFID::define_UUID, I"PL::Bibliographic::IFID::define_UUID")
	COMPILATION_STEP(PL::Figures::compile_ResourceIDsOfFigures_array, I"PL::Figures::compile_ResourceIDsOfFigures_array")
	COMPILATION_STEP(PL::Sounds::compile_ResourceIDsOfSounds_array, I"PL::Sounds::compile_ResourceIDsOfSounds_array")
	COMPILATION_STEP(PL::Player::InitialSituation, I"PL::Player::InitialSituation")

@<Tables and grammar@> =
	if (problem_count == 0) Sequence::go_to_log_phase(I"Tables and grammar");
	COMPILATION_STEP(Tables::check_tables_for_kind_clashes, I"Tables::check_tables_for_kind_clashes")
	COMPILATION_STEP(Tables::Support::compile_print_table_names, I"Tables::Support::compile_print_table_names")
	COMPILATION_STEP(PL::Parsing::traverse, I"PL::Parsing::traverse")
	COMPILATION_STEP(World::complete_additions, I"World::complete_additions")

@<Phrases and rules@> =
	ProgressBar::update_progress_bar(3, 0);
	if (problem_count == 0) Sequence::go_to_log_phase(I"Phrases and rules");
	COMPILATION_STEP(LiteralPatterns::define_named_phrases, I"LiteralPatterns::define_named_phrases")
	COMPILATION_STEP(Phrases::Manager::traverse, I"Phrases::Manager::traverse")
	COMPILATION_STEP(Phrases::Manager::register_meanings, I"Phrases::Manager::register_meanings")
	COMPILATION_STEP(Phrases::Manager::parse_rule_parameters, I"Phrases::Manager::parse_rule_parameters")
	COMPILATION_STEP(Phrases::Manager::add_rules_to_rulebooks, I"Phrases::Manager::add_rules_to_rulebooks")
	COMPILATION_STEP(Phrases::Manager::parse_rule_placements, I"Phrases::Manager::parse_rule_placements")
	COMPILATION_STEP(Equations::traverse_to_stock, I"Equations::traverse_to_stock")
	COMPILATION_STEP(Tables::traverse_to_stock, I"Tables::traverse_to_stock")
	COMPILATION_STEP(Properties::annotate_attributes, I"Properties::annotate_attributes")
	COMPILATION_STEP(Rulebooks::Outcomes::RulebookOutcomePrintingRule, I"Rulebooks::Outcomes::RulebookOutcomePrintingRule")
	COMPILATION_STEP(Kinds::RunTime::compile_instance_counts, I"Kinds::RunTime::compile_instance_counts")

@ This is where we hand over to regular template files -- containing code
passed through as I6 source, as well as a few further commands -- starting
with "Output.i6t".

@<Generate inter@> =
	ProgressBar::update_progress_bar(4, 0);
	if (problem_count == 0) Sequence::go_to_log_phase(I"Generating inter");
	COMPILATION_STEP(UseOptions::compile_icl_commands, I"UseOptions::compile_icl_commands")
	COMPILATION_STEP(FundamentalConstants::emit_build_number, I"FundamentalConstants::emit_build_number")
	COMPILATION_STEP(PL::Bibliographic::compile_constants, I"PL::Bibliographic::compile_constants")
	COMPILATION_STEP(Extensions::Files::ShowExtensionVersions_routine, I"Extensions::Files::ShowExtensionVersions_routine")
	COMPILATION_STEP(Kinds::Constructors::compile_I6_constants, I"Kinds::Constructors::compile_I6_constants")
	COMPILATION_STEP_IF(scoring_plugin, PL::Score::compile_max_score, I"PL::Score::compile_max_score")
	COMPILATION_STEP(UseOptions::TestUseOption_routine, I"UseOptions::TestUseOption_routine")
	COMPILATION_STEP(Activities::compile_activity_constants, I"Activities::compile_activity_constants")
	COMPILATION_STEP(Activities::Activity_before_rulebooks_array, I"Activities::Activity_before_rulebooks_array")
	COMPILATION_STEP(Activities::Activity_for_rulebooks_array, I"Activities::Activity_for_rulebooks_array")
	COMPILATION_STEP(Activities::Activity_after_rulebooks_array, I"Activities::Activity_after_rulebooks_array")
	COMPILATION_STEP(Activities::Activity_atb_rulebooks_array, I"Activities::Activity_atb_rulebooks_array")
	COMPILATION_STEP(Relations::compile_defined_relation_constants, I"Relations::compile_defined_relation_constants")
	COMPILATION_STEP(Kinds::RunTime::compile_data_type_support_routines, I"Kinds::RunTime::compile_data_type_support_routines")
	COMPILATION_STEP(Kinds::RunTime::I7_Kind_Name_routine, I"Kinds::RunTime::I7_Kind_Name_routine")
	COMPILATION_STEP(World::Compile::compile, I"World::Compile::compile")
	COMPILATION_STEP_IF(backdrops_plugin, PL::Backdrops::write_found_in_routines, I"PL::Backdrops::write_found_in_routines")
	COMPILATION_STEP_IF(map_plugin, PL::Map::write_door_dir_routines, I"PL::Map::write_door_dir_routines")
	COMPILATION_STEP_IF(map_plugin, PL::Map::write_door_to_routines, I"PL::Map::write_door_to_routines")
	COMPILATION_STEP_IF(parsing_plugin, PL::Parsing::Tokens::General::write_parse_name_routines, I"PL::Parsing::Tokens::General::write_parse_name_routines")
	COMPILATION_STEP_IF(regions_plugin, PL::Regions::write_regional_found_in_routines, I"PL::Regions::write_regional_found_in_routines")
	COMPILATION_STEP(Tables::complete, I"Tables::complete")
	COMPILATION_STEP(Tables::Support::compile, I"Tables::Support::compile")
	COMPILATION_STEP(Equations::compile, I"Equations::compile")
	COMPILATION_STEP_IF(actions_plugin, PL::Actions::Patterns::Named::compile, I"PL::Actions::Patterns::Named::compile")
	COMPILATION_STEP_IF(actions_plugin, PL::Actions::ActionData, I"PL::Actions::ActionData")
	COMPILATION_STEP_IF(actions_plugin, PL::Actions::ActionCoding_array, I"PL::Actions::ActionCoding_array")
	COMPILATION_STEP_IF(actions_plugin, PL::Actions::ActionHappened, I"PL::Actions::ActionHappened")
	COMPILATION_STEP_IF(actions_plugin, PL::Actions::compile_action_routines, I"PL::Actions::compile_action_routines")
	COMPILATION_STEP_IF(parsing_plugin, PL::Parsing::Lines::MistakeActionSub_routine, I"PL::Parsing::Lines::MistakeActionSub_routine")
	COMPILATION_STEP(Phrases::Manager::compile_first_block, I"Phrases::Manager::compile_first_block")
	COMPILATION_STEP(Phrases::Manager::compile_rulebooks, I"Phrases::Manager::compile_rulebooks")
	COMPILATION_STEP(Phrases::Manager::rulebooks_array, I"Phrases::Manager::rulebooks_array")
	COMPILATION_STEP_IF(scenes_plugin, PL::Scenes::DetectSceneChange_routine, I"PL::Scenes::DetectSceneChange_routine")
	COMPILATION_STEP_IF(scenes_plugin, PL::Scenes::ShowSceneStatus_routine, I"PL::Scenes::ShowSceneStatus_routine")
	COMPILATION_STEP(PL::Files::arrays, I"PL::Files::arrays")
	COMPILATION_STEP(Rulebooks::rulebook_var_creators, I"Rulebooks::rulebook_var_creators")
	COMPILATION_STEP(Activities::activity_var_creators, I"Activities::activity_var_creators")
	COMPILATION_STEP(Relations::IterateRelations, I"Relations::IterateRelations")
	COMPILATION_STEP(Phrases::Manager::RulebookNames_array, I"Phrases::Manager::RulebookNames_array")
	COMPILATION_STEP(Phrases::Manager::RulePrintingRule_routine, I"Phrases::Manager::RulePrintingRule_routine")
	COMPILATION_STEP_IF(parsing_plugin, PL::Parsing::Verbs::prepare, I"PL::Parsing::Verbs::prepare")
	COMPILATION_STEP_IF(parsing_plugin, PL::Parsing::Verbs::compile_conditions, I"PL::Parsing::Verbs::compile_conditions")
	COMPILATION_STEP_IF(parsing_plugin, PL::Parsing::Tokens::Values::number, I"PL::Parsing::Tokens::Values::number")
	COMPILATION_STEP_IF(parsing_plugin, PL::Parsing::Tokens::Values::truth_state, I"PL::Parsing::Tokens::Values::truth_state")
	COMPILATION_STEP_IF(parsing_plugin, PL::Parsing::Tokens::Values::time, I"PL::Parsing::Tokens::Values::time")
	COMPILATION_STEP_IF(parsing_plugin, PL::Parsing::Tokens::Values::compile_type_gprs, I"PL::Parsing::Tokens::Values::compile_type_gprs")
	COMPILATION_STEP(NewVerbs::ConjugateVerb, I"NewVerbs::ConjugateVerb")
	COMPILATION_STEP(Adjectives::Meanings::agreements, I"Adjectives::Meanings::agreements")
	if (TargetVMs::debug_enabled(Task::vm())) {
		COMPILATION_STEP_IF(parsing_plugin, PL::Parsing::TestScripts::write_text, I"PL::Parsing::TestScripts::write_text")
		COMPILATION_STEP_IF(parsing_plugin, PL::Parsing::TestScripts::TestScriptSub_routine, I"PL::Parsing::TestScripts::TestScriptSub_routine")
		COMPILATION_STEP_IF(parsing_plugin, PL::Parsing::TestScripts::InternalTestCases_routine, I"PL::Parsing::TestScripts::InternalTestCases_routine")
	} else {
		COMPILATION_STEP_IF(parsing_plugin, PL::Parsing::TestScripts::TestScriptSub_stub_routine, I"PL::Parsing::TestScripts::TestScriptSub_stub_routine")
	}

	COMPILATION_STEP(Lists::check, I"Lists::check")
	COMPILATION_STEP(Lists::compile, I"Lists::compile")
	if (Projects::Main_defined(Task::project()) == FALSE)
		COMPILATION_STEP(Phrases::invoke_to_begin, I"Phrases::invoke_to_begin")
	COMPILATION_STEP(Phrases::Manager::compile_as_needed, I"Phrases::Manager::compile_as_needed")
	COMPILATION_STEP(Strings::compile_responses, I"Strings::compile_responses")
	COMPILATION_STEP(Lists::check, I"Lists::check")
	COMPILATION_STEP(Lists::compile, I"Lists::compile")
	COMPILATION_STEP(Relations::compile_defined_relations, I"Relations::compile_defined_relations")
	COMPILATION_STEP(Phrases::Manager::compile_as_needed, I"Phrases::Manager::compile_as_needed")
	COMPILATION_STEP(Strings::TextSubstitutions::allow_no_further_text_subs, I"Strings::TextSubstitutions::allow_no_further_text_subs")
	COMPILATION_STEP_IF(parsing_plugin, PL::Parsing::Tokens::Filters::compile, I"PL::Parsing::Tokens::Filters::compile")
	COMPILATION_STEP_IF(actions_plugin, Chronology::past_actions_i6_routines, I"Chronology::past_actions_i6_routines")
	COMPILATION_STEP_IF(chronology_plugin, Chronology::chronology_extents_i6_escape, I"Chronology::chronology_extents_i6_escape")
	COMPILATION_STEP_IF(chronology_plugin, Chronology::past_tenses_i6_escape, I"Chronology::past_tenses_i6_escape")
	COMPILATION_STEP_IF(chronology_plugin, Chronology::allow_no_further_past_tenses, I"Chronology::allow_no_further_past_tenses")
	COMPILATION_STEP_IF(parsing_plugin, PL::Parsing::Verbs::compile_all, I"PL::Parsing::Verbs::compile_all")
	COMPILATION_STEP_IF(parsing_plugin, PL::Parsing::Tokens::Filters::compile, I"PL::Parsing::Tokens::Filters::compile")
	COMPILATION_STEP(Properties::Measurement::compile_MADJ_routines, I"Properties::Measurement::compile_MADJ_routines")
	COMPILATION_STEP(Calculus::Propositions::Deferred::compile_remaining_deferred, I"Calculus::Propositions::Deferred::compile_remaining_deferred")
	COMPILATION_STEP(Calculus::Deferrals::allow_no_further_deferrals, I"Calculus::Deferrals::allow_no_further_deferrals")
	COMPILATION_STEP(Lists::check, I"Lists::check")
	COMPILATION_STEP(Lists::compile, I"Lists::compile")
	COMPILATION_STEP(Strings::TextLiterals::compile, I"Strings::TextLiterals::compile")
	COMPILATION_STEP(JumpLabels::compile_necessary_storage, I"JumpLabels::compile_necessary_storage")
	COMPILATION_STEP(Kinds::RunTime::compile_heap_allocator, I"Kinds::RunTime::compile_heap_allocator")
	COMPILATION_STEP(Phrases::Constants::compile_closures, I"Phrases::Constants::compile_closures")
	COMPILATION_STEP(Kinds::RunTime::compile_structures, I"Kinds::RunTime::compile_structures")
	COMPILATION_STEP(Rules::check_response_usages, I"Rules::check_response_usages")
	COMPILATION_STEP(Phrases::Timed::check_for_unused, I"Phrases::Timed::check_for_unused")
	COMPILATION_STEP(PL::Showme::compile_SHOWME_details, I"PL::Showme::compile_SHOWME_details")
	COMPILATION_STEP(Phrases::Timed::TimedEventsTable, I"Phrases::Timed::TimedEventsTable")
	COMPILATION_STEP(Phrases::Timed::TimedEventTimesTable, I"Phrases::Timed::TimedEventTimesTable")
	COMPILATION_STEP(PL::Naming::compile_cap_short_name, I"PL::Naming::compile_cap_short_name")
	COMPILATION_STEP(UseOptions::configure_template, I"UseOptions::configure_template")

@ Metadata.

@<Generate index and bibliographic file@> =
	if (Plugins::Manage::plugged_in(bibliographic_plugin))
		PL::Bibliographic::Release::write_ifiction_and_blurb();
	if (problem_count == 0)
		NaturalLanguages::produce_index();


@ =
int no_log_phases = 0;
void Sequence::go_to_log_phase(text_stream *argument) {
	char *phase_names[] = {
		"I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X",
		"XI", "XII", "XIII", "XIV", "XV", "XVI", "XVII", "XVIII", "XIX", "XX", "XXI", "XXII" };
	Log::new_phase(phase_names[no_log_phases], argument);
	if (no_log_phases < 21) no_log_phases++;
}
