[CoreMain::] Main Routine.

As with all C programs, Inform begins execution in a |main| routine,
reading command-line arguments to modify its behaviour.

@h Flags.
These flags are set by command-line parameters. |for_release| will be set
when Inform is used in a run started by clicking on the Release button in the
application. |rng_seed_at_start_of_play| is not used by the application,
but the |intest| program makes use of this feature to make repeated
tests of the Z-machine story file produce identical sequences of random
numbers: without this, we would have difficulty comparing a transcript of
text produced by the story file on one compilation from another.

|story_filename_extension| is also set as a result of information passed
from the application via the command line to Inform. In order for Inform to
write good releasing instructions, it needs to know the story file format
(".z5", ".z8", etc.) of the finally produced story file. But since Inform 7
compiles only to Inter and thence to Inform 6 code, and does not run I6
itself, it has no way of telling what the application intends to do on this.
So the application is required to give Inform advance notice of this via a
command-line option.

=
int this_is_a_debug_compile = FALSE; /* Destined to be compiled with debug features */
int this_is_a_release_compile = FALSE; /* Omit sections of source text marked not for release */
int existing_story_file = FALSE; /* Ignore source text to blorb existing story file? */
int rng_seed_at_start_of_play = 0; /* The seed value, or 0 if not seeded */
int census_mode = FALSE; /* Inform running only to update extension documentation */
text_stream *story_filename_extension = NULL; /* What story file we will eventually have */
int show_progress_indicator = TRUE; /* Produce percentage of progress messages */
int scoring_option_set = NOT_APPLICABLE; /* Whether in this case a score is kept at run time */
int disable_import = FALSE;
int do_not_generate_index = FALSE; /* Set by the |-noindex| command line option */

@ This flag is set by the use option "Use no deprecated features", and makes
Inform strict in rejecting syntaxes we intend to get rid of later on.

=
int no_deprecated_features = FALSE; /* forbid syntaxes marked as deprecated? */

@ Broadly speaking, what Inform does can be divided into two halves: in
the first half, it reads all the assertions, makes all the objects and
global variables and constructs the model world; in the second half,
it compiles the phrases and grammar to go with it.
|model_world_constructed| records which of these halves we are
currently in: |FALSE| in the first half, |TRUE| in the second.

If there were a third stage, it would be indexing, and during that
period |indexing_stage| is |TRUE|. But by that time the compilation of
Inform 6 code is complete.

=
int text_loaded_from_source = FALSE; /* Lexical scanning is done */
int model_world_under_construction = FALSE; /* World model is being constructed */
int model_world_constructed = FALSE; /* World model is now constructed */
int indexing_stage = FALSE; /* Everything is done except indexing */

@ =
int report_clock_time = FALSE;
time_t right_now;
text_stream *inter_processing_file = NULL;
text_stream *inter_processing_pipeline = NULL;
dictionary *pipeline_vars = NULL;
pathname *path_to_inform7 = NULL;

int CoreMain::main(int argc, char *argv[]) {
	clock_t start = clock();
	@<Banner and startup@>;
	@<Register command-line arguments@>;
	int proceed = CommandLine::read(argc, argv, NULL, &CoreMain::switch, &CoreMain::bareword);
	if (proceed) {
		@<Establish our location in the file system@>;
		@<With that done, configure all other settings@>;
		@<Open the debugging log and the problems report@>;
		@<Boot up the compiler@>;
		if (census_mode)
			Extensions::Files::handle_census_mode();
		else {
			@<Work out our kit requirements@>;
			@<Perform lexical analysis@>;
			@<Perform semantic analysis@>;
			@<Read the assertions in two passes@>;
			@<Make the model world@>;
			@<Tables and grammar@>;
			@<Phrases and rules@>;
			@<Generate inter@>;
			@<Convert inter to Inform 6@>;
			@<Generate metadata@>;
			@<Post mortem logging@>;
		}
	}
	clock_t end = clock();
	@<Shutdown and rennab@>;
	if (problem_count > 0) Problems::Fatal::exit(1);
	return 0;
}

@ It is the dawn of time...

@<Banner and startup@> =
	Errors::set_internal_handler(&Problems::Issue::internal_error_fn);
	story_filename_extension = I"ulx";
	inter_processing_pipeline = Str::new();
	inter_processing_file = I"compile";

	PRINT("%B build %B has started.\n", FALSE, TRUE);
	STREAM_FLUSH(STDOUT);

@ Note that the locations manager is also allowed to process command-line
arguments in order to set certain pathnames or filenames, so the following
list is not exhaustive.

@e CASE_CLSW
@e CENSUS_CLSW
@e CLOCK_CLSW
@e DEBUG_CLSW
@e FORMAT_CLSW
@e CRASHALL_CLSW
@e NOINDEX_CLSW
@e NOPROGRESS_CLSW
@e RELEASE_CLSW
@e REQUIRE_PROBLEM_CLSW
@e RNG_CLSW
@e SIGILS_CLSW
@e PIPELINE_CLSW
@e PIPELINE_FILE_CLSW
@e PIPELINE_VARIABLE_CLSW

@<Register command-line arguments@> =
	CommandLine::declare_heading(
		L"inform7: a compiler from source text to Inform 6 code\n\n"
		L"Usage: inform7 [OPTIONS] [SOURCETEXT]\n");

	CommandLine::declare_textual_switch(FORMAT_CLSW, L"format", 1,
		L"compile I6 code suitable for the virtual machine X");
	CommandLine::declare_boolean_switch(CENSUS_CLSW, L"census", 1,
		L"perform an extensions census (rather than compile)");
	CommandLine::declare_boolean_switch(CLOCK_CLSW, L"clock", 1,
		L"time how long inform7 takes to run");
	CommandLine::declare_boolean_switch(DEBUG_CLSW, L"debug", 1,
		L"compile with debugging features even on a Release");
	CommandLine::declare_boolean_switch(CRASHALL_CLSW, L"crash-all", 1,
		L"crash intentionally on Problem messages (for debugger backtraces)");
	CommandLine::declare_boolean_switch(NOINDEX_CLSW, L"noindex", 1,
		L"don't produce an Index");
	CommandLine::declare_boolean_switch(NOPROGRESS_CLSW, L"noprogress", 1,
		L"don't display progress percentages");
	CommandLine::declare_boolean_switch(RELEASE_CLSW, L"release", 1,
		L"compile a version suitable for a Release build");
	CommandLine::declare_boolean_switch(RNG_CLSW, L"rng", 1,
		L"fix the random number generator of the story file (for testing)");
	CommandLine::declare_boolean_switch(SIGILS_CLSW, L"sigils", 1,
		L"print Problem message sigils (for testing)");
	CommandLine::declare_switch(CASE_CLSW, L"case", 2,
		L"make any source links refer to the source in extension example X");
	CommandLine::declare_switch(REQUIRE_PROBLEM_CLSW, L"require-problem", 2,
		L"return 0 unless exactly this Problem message is generated (for testing)");
	CommandLine::declare_switch(PIPELINE_CLSW, L"pipeline", 2,
		L"specify code-generation pipeline");
	CommandLine::declare_switch(PIPELINE_FILE_CLSW, L"pipeline-file", 2,
		L"specify code-generation pipeline from file X");
	CommandLine::declare_switch(PIPELINE_VARIABLE_CLSW, L"variable", 2,
		L"set pipeline variable X (in form name=value)");
	Inbuild::declare_options();

@<Establish our location in the file system@> =
	path_to_inform7 = Pathnames::installation_path("INFORM7_PATH", I"inform7");

@<With that done, configure all other settings@> =
	Inbuild::optioneering_complete(NULL);
	VirtualMachines::set_identifier(story_filename_extension);
	if (Locations::set_defaults(census_mode) == FALSE)
		Problems::Fatal::issue("Unable to create folders in local file system");
	Log::set_debug_log_filename(filename_of_debugging_log);
	NaturalLanguages::default_to_English();

@<Open the debugging log and the problems report@> =
	Log::open();
	LOG("Inform called as:");
	for (int i=0; i<argc; i++) LOG(" %s", argv[i]);
	LOG("\n");
	CommandLine::play_back_log();
	Problems::Issue::start_problems_report();

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
	COMPILATION_STEP(Semantics::read_preform, I"Semantics::read_preform")
	COMPILATION_STEP(Plugins::Manage::start, I"Plugins::Manage::start")
	COMPILATION_STEP(InferenceSubjects::begin, I"InferenceSubjects::begin")
	COMPILATION_STEP(Index::DocReferences::read_xrefs, I"Index::DocReferences::read_xrefs")
	doc_references_top = lexer_wordcount - 1;

@<Work out our kit requirements@> =
	Inbuild::go_operational();

@<Perform lexical analysis@> =
	ProgressBar::update_progress_bar(0, 0);
	if (problem_count == 0) CoreMain::go_to_log_phase(I"Lexical analysis");
	COMPILATION_STEP(SourceFiles::read_primary_source_text, I"SourceFiles::read_primary_source_text")
	COMPILATION_STEP(Sentences::RuleSubtrees::create_standard_csps, I"Sentences::RuleSubtrees::create_standard_csps")

@<Perform semantic analysis@> =
	ProgressBar::update_progress_bar(1, 0);
	if (problem_count == 0) CoreMain::go_to_log_phase(I"Semantic analysis Ia");
	Projects::activate_plugins(Inbuild::project());
	COMPILATION_STEP(ParseTreeUsage::plant_parse_tree, I"ParseTreeUsage::plant_parse_tree")
	COMPILATION_STEP(StructuralSentences::break_source, I"StructuralSentences::break_source")
	COMPILATION_STEP(Extensions::Inclusion::traverse, I"Extensions::Inclusion::traverse")
	COMPILATION_STEP(Sentences::Headings::satisfy_dependencies, I"Sentences::Headings::satisfy_dependencies")

	if (problem_count == 0) CoreMain::go_to_log_phase(I"Initialise language semantics");
	COMPILATION_STEP(Plugins::Manage::start_plugins, I"Plugins::Manage::start_plugins");
	Projects::load_types(Inbuild::project());
	COMPILATION_STEP(BinaryPredicates::make_built_in, I"BinaryPredicates::make_built_in")
	COMPILATION_STEP(NewVerbs::add_inequalities, I"NewVerbs::add_inequalities")

	if (problem_count == 0) CoreMain::go_to_log_phase(I"Semantic analysis Ib");
	COMPILATION_STEP(Sentences::VPs::traverse, I"Sentences::VPs::traverse")
	COMPILATION_STEP(Sentences::Rearrangement::tidy_up_ofs_and_froms, I"Sentences::Rearrangement::tidy_up_ofs_and_froms")
	COMPILATION_STEP(Sentences::RuleSubtrees::register_recently_lexed_phrases, I"Sentences::RuleSubtrees::register_recently_lexed_phrases")
	COMPILATION_STEP(StructuralSentences::declare_source_loaded, I"StructuralSentences::declare_source_loaded")
	COMPILATION_STEP(Kinds::Interpreter::include_templates_for_kinds, I"Kinds::Interpreter::include_templates_for_kinds")

	if (problem_count == 0) CoreMain::go_to_log_phase(I"Semantic analysis II");
	COMPILATION_STEP(ParseTreeUsage::verify, I"ParseTreeUsage::verify")
	COMPILATION_STEP(Extensions::Files::check_versions, I"Extensions::Files::check_versions")
	COMPILATION_STEP(Sentences::Headings::make_tree, I"Sentences::Headings::make_tree")
	COMPILATION_STEP(Sentences::Headings::write_as_xml, I"Sentences::Headings::write_as_xml")
	COMPILATION_STEP(Sentences::Headings::write_as_xml, I"Sentences::Headings::write_as_xml")
	COMPILATION_STEP(Modules::traverse_to_define, I"Modules::traverse_to_define")

	if (problem_count == 0) CoreMain::go_to_log_phase(I"Semantic analysis III");
	COMPILATION_STEP(Phrases::Adjectives::traverse, I"Phrases::Adjectives::traverse")
	COMPILATION_STEP(Equations::traverse_to_create, I"Equations::traverse_to_create")
	COMPILATION_STEP(Tables::traverse_to_create, I"Tables::traverse_to_create")
	COMPILATION_STEP(Phrases::Manager::traverse_for_names, I"Phrases::Manager::traverse_for_names")

@<Read the assertions in two passes@> =
	ProgressBar::update_progress_bar(2, 0);
	if (problem_count == 0) CoreMain::go_to_log_phase(I"First pass through assertions");
	if (problem_count == 0) Assertions::Traverse::traverse(1);
	COMPILATION_STEP(Tables::traverse_to_stock, I"Tables::traverse_to_stock")
	if (problem_count == 0) CoreMain::go_to_log_phase(I"Second pass through assertions");
	if (problem_count == 0) Assertions::Traverse::traverse(2);
	COMPILATION_STEP(Kinds::RunTime::kind_declarations, I"Kinds::RunTime::kind_declarations")

@<Make the model world@> =
	if (problem_count == 0) CoreMain::go_to_log_phase(I"Making the model world");
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
	if (problem_count == 0) CoreMain::go_to_log_phase(I"Tables and grammar");
	COMPILATION_STEP(Tables::check_tables_for_kind_clashes, I"Tables::check_tables_for_kind_clashes")
	COMPILATION_STEP(Tables::Support::compile_print_table_names, I"Tables::Support::compile_print_table_names")
	COMPILATION_STEP(PL::Parsing::traverse, I"PL::Parsing::traverse")
	COMPILATION_STEP(World::complete_additions, I"World::complete_additions")

@<Phrases and rules@> =
	ProgressBar::update_progress_bar(3, 0);
	if (problem_count == 0) CoreMain::go_to_log_phase(I"Phrases and rules");
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
	if (problem_count == 0) CoreMain::go_to_log_phase(I"Generating inter");
	COMPILATION_STEP(UseOptions::compile_icl_commands, I"UseOptions::compile_icl_commands")
	COMPILATION_STEP(VirtualMachines::compile_build_number, I"VirtualMachines::compile_build_number")
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
	if ((this_is_a_release_compile == FALSE) || (this_is_a_debug_compile)) {
		COMPILATION_STEP_IF(parsing_plugin, PL::Parsing::TestScripts::write_text, I"PL::Parsing::TestScripts::write_text")
		COMPILATION_STEP_IF(parsing_plugin, PL::Parsing::TestScripts::TestScriptSub_routine, I"PL::Parsing::TestScripts::TestScriptSub_routine")
		COMPILATION_STEP_IF(parsing_plugin, PL::Parsing::TestScripts::InternalTestCases_routine, I"PL::Parsing::TestScripts::InternalTestCases_routine")
	} else {
		COMPILATION_STEP_IF(parsing_plugin, PL::Parsing::TestScripts::TestScriptSub_stub_routine, I"PL::Parsing::TestScripts::TestScriptSub_stub_routine")
	}

	COMPILATION_STEP(Lists::check, I"Lists::check")
	COMPILATION_STEP(Lists::compile, I"Lists::compile")
	if (Projects::Main_defined(Inbuild::project()) == FALSE)
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

@<Convert inter to Inform 6@> =
	if ((problem_count == 0) && (existing_story_file == FALSE)) {
		clock_t front_end = clock();
		LOG("Front end elapsed time: %dcs\n", ((int) (front_end - start)) / (CLOCKS_PER_SEC/100));
		CoreMain::go_to_log_phase(I"Converting inter to Inform 6");
		if (existing_story_file == FALSE) {
			if ((this_is_a_release_compile == FALSE) || (this_is_a_debug_compile)) {
				if (VirtualMachines::is_16_bit())
					CodeGen::Architecture::set(I"16d");
				else
					CodeGen::Architecture::set(I"32d");
			} else {
				if (VirtualMachines::is_16_bit())
					CodeGen::Architecture::set(I"16");
				else
					CodeGen::Architecture::set(I"32");
			}
			@<Ensure inter pipeline variables dictionary@>;
			Str::copy(Dictionaries::create_text(pipeline_vars, I"*in"), I"*memory");
			Str::copy(Dictionaries::create_text(pipeline_vars, I"*out"), Filenames::get_leafname(filename_of_compiled_i6_code));
			
			codegen_pipeline *SS = NULL;
			if (Str::len(inter_processing_pipeline) > 0) {
				SS = CodeGen::Pipeline::parse(inter_processing_pipeline, pipeline_vars);
				if (SS == NULL)
					Problems::Fatal::issue("The Inter pipeline description contained errors");
			} else {
				inbuild_requirement *req =
					Requirements::any_version_of(Works::new(pipeline_genre, inter_processing_file, NULL));
				linked_list *L = NEW_LINKED_LIST(inbuild_search_result);
				Nests::search_for(req, Inbuild::nest_list(), L);
				if (LinkedLists::len(L) == 0) {
					WRITE_TO(STDERR, "Sought pipeline '%S'\n", inter_processing_file);
					Problems::Fatal::issue("The Inter pipeline could not be found");
				} else {
					inbuild_search_result *R;
					LOOP_OVER_LINKED_LIST(R, inbuild_search_result, L) {
						inbuild_copy *C = R->copy;
						filename *F = C->location_if_file;
						SS = CodeGen::Pipeline::parse_from_file(F, pipeline_vars);
						if (SS == NULL)
							Problems::Fatal::filename_related("This Inter pipeline contains errors", F);
						break;
					}
				}
			}
			CodeGen::Pipeline::set_repository(SS, Emit::tree());
			CodeGen::Pipeline::run(Filenames::get_path_to(filename_of_compiled_i6_code),
				SS, Kits::inter_paths(), Projects::list_of_inter_libraries(Inbuild::project()));
		}
		LOG("Back end elapsed time: %dcs\n", ((int) (clock() - front_end)) / (CLOCKS_PER_SEC/100));
	}
	if (problem_count == 0) CoreMain::go_to_log_phase(I"Compilation now complete");

	pipeline_vars = CodeGen::Pipeline::basic_dictionary(I"output.i6");

@<Ensure inter pipeline variables dictionary@> =
	if (pipeline_vars == NULL)
		pipeline_vars = CodeGen::Pipeline::basic_dictionary(
			Filenames::get_leafname(filename_of_compiled_i6_code));

@ Metadata.

@<Generate metadata@> =
	if (Plugins::Manage::plugged_in(bibliographic_plugin))
		PL::Bibliographic::Release::write_ifiction_and_blurb();
	if (problem_count == 0)
		NaturalLanguages::produce_index();

@<Post mortem logging@> =
	if (problem_count == 0) {
		TemplateReader::report_unacted_upon_interventions();
//		ParseTreeUsage::write_main_source_to_log();
//		Memory::log_statistics();
//		Preform::log_language();
//		Index::DocReferences::log_statistics();
//		NewVerbs::log_all();
	}

@<Shutdown and rennab@> =
	if (proceed) {
		Problems::write_reports(FALSE);

		LOG("Total of %d files written as streams.\n", total_file_writes);
		int cpu_time_used = ((int) (end - start)) / (CLOCKS_PER_SEC/100);
		LOG("CPU time: %d centiseconds\n", cpu_time_used);
		Writers::log_escape_usage();

		WRITE_TO(STDOUT, "%s has finished", HUMAN_READABLE_INTOOL_NAME);
		if (report_clock_time)
			WRITE_TO(STDOUT, ": %d centiseconds used", cpu_time_used);
		WRITE_TO(STDOUT, ".\n");
	}


@ =
int no_log_phases = 0;
void CoreMain::go_to_log_phase(text_stream *argument) {
	char *phase_names[] = {
		"I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X",
		"XI", "XII", "XIII", "XIV", "XV", "XVI", "XVII", "XVIII", "XIX", "XX", "XXI", "XXII" };
	Log::new_phase(phase_names[no_log_phases], argument);
	if (no_log_phases < 21) no_log_phases++;
}

@ =
void CoreMain::switch(int id, int val, text_stream *arg, void *state) {
	switch (id) {
		/* Miscellaneous boolean settings */
		case CENSUS_CLSW: census_mode = val; break;
		case CLOCK_CLSW: report_clock_time = val; break;
		case CRASHALL_CLSW: debugger_mode = val; crash_on_all_errors = val; break;
		case DEBUG_CLSW: this_is_a_debug_compile = val; break;
		case NOINDEX_CLSW: do_not_generate_index = val; break;
		case NOPROGRESS_CLSW: show_progress_indicator = val?FALSE:TRUE; break;
		case RELEASE_CLSW: this_is_a_release_compile = val; break;
		case RNG_CLSW:
			if (val) rng_seed_at_start_of_play = -16339;
			else rng_seed_at_start_of_play = 0;
			break;
		case SIGILS_CLSW: echo_problem_message_sigils = val; break;

		/* Other settings */
		case FORMAT_CLSW: story_filename_extension = Str::duplicate(arg); break;
		case CASE_CLSW: HTMLFiles::set_source_link_case(arg); break;
		case REQUIRE_PROBLEM_CLSW: Problems::Fatal::require(arg); break;
		case PIPELINE_CLSW: inter_processing_pipeline = Str::duplicate(arg); break;
		case PIPELINE_FILE_CLSW: inter_processing_file = Str::duplicate(arg); break;
		case PIPELINE_VARIABLE_CLSW: {
			match_results mr = Regexp::create_mr();
			if (Regexp::match(&mr, arg, L"(%c+)=(%c+)")) {
				if (Str::get_first_char(arg) != '*') {
					Errors::fatal("-variable names must begin with '*'");
				} else {
					@<Ensure inter pipeline variables dictionary@>;
					Str::copy(Dictionaries::create_text(pipeline_vars, mr.exp[0]), mr.exp[1]);
				}
			} else {
				Errors::fatal("-variable should take the form 'name=value'");
			}
			Regexp::dispose_of(&mr);
			break;
		}
	}
	Inbuild::option(id, val, arg, state);
}

int CoreMain::census_mode(void) {
	return census_mode;
}

void CoreMain::bareword(int id, text_stream *opt, void *state) {
	if (Inbuild::set_I7_source(opt) == FALSE)
		Errors::fatal_with_text("unknown command line argument: %S (see -help)", opt);
}

void CoreMain::disable_importation(void) {
	disable_import = TRUE;
}

void CoreMain::set_inter_pipeline(wording W) {
	inter_processing_pipeline = Str::new();
	WRITE_TO(inter_processing_pipeline, "%W", W);
	Str::delete_first_character(inter_processing_pipeline);
	Str::delete_last_character(inter_processing_pipeline);
	LOG("Setting pipeline %S\n", inter_processing_pipeline);
}
