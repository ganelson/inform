[Sequence::] How To Compile.

The long production line on which products of Inform are built, one step at a time.

@ Having seen the top management of the factory, we now reach the factory
floor, which is one long production line: around 150 steps must be performed
in sequence to finish making the product. We can picture each of these
steps as carried out by a worker function: each does its work and passes
on to the next.

150 is a great many, so we group the stages into 16 departments, which are,
in order of when they work:

@e STARTED_CSEQ from 0
@e LEXICAL_CSEQ
@e SEMANTIC_LANGUAGE_CSEQ
@e SEMANTIC_I_CSEQ
@e SEMANTIC_II_CSEQ
@e SEMANTIC_III_CSEQ
@e ASSERTIONS_PASS_1_CSEQ
@e ASSERTIONS_PASS_2_CSEQ
@e MODEL_CSEQ
@e MODEL_COMPLETE_CSEQ
@e TABLES_CSEQ
@e PHRASES_CSEQ
@e INTER_CSEQ
@e BIBLIOGRAPHIC_CSEQ
@e FINISHED_CSEQ

@ The aim of this section is to contain as little logic as possible. However,
a few of the steps are carried out only if debugging features are enabled,
or disabled; or only if certain elements of the Inform language are enabled.
For example, a Basic Inform source text is not allowed to contain command
parser grammar in the way that an IF source text would, so the steps to do
with building that grammar are skipped unless the relevant language element
is active.

=
int compiler_booted_up = FALSE;

int Sequence::carry_out(int debugging) {
	clock_t start = clock();
	Task::advance_stage_to(STARTED_CSEQ, I"Starting", -1);

	if (compiler_booted_up == FALSE) {
		@<Boot up the compiler@>;
		compiler_booted_up = TRUE;
	}
	@<Perform textual analysis@>;
	@<Read the assertions in two passes@>;
	@<Make the model world@>;
	@<Tables and grammar@>;
	@<Phrases and rules@>;
	@<Generate inter@>;
	@<Generate index and bibliographic file@>;

	Task::advance_stage_to(FINISHED_CSEQ, I"Ccmplete", -1);
	clock_t end = clock();
	int cpu_time_used = ((int) (end - start)) / (CLOCKS_PER_SEC/100);
	LOG("Compile CPU time: %d centiseconds\n", cpu_time_used);
	if (problem_count > 0) return FALSE;
	return TRUE;
}

@ Here are macros for the unconditional and conditional steps, respectively,
taking place at what we think of as benches in the production line. Continuing
the analogy, there is an ongoing time and motion study: any step which takes
more than 1 centisecond of CPU time is reported to the debugging log. That
isn't necessarily a sign of something wrong: a few of these steps are always
going to take serious computation. But we want to know which ones.

As soon as any step generates problem messages, all subsequent steps are
skipped, so that each of the worker functions can assume that the
part-assembled state they receive is correct so far. This greatly simplifies
error recovery, prevents small errors in the source text leading to
cascades of problem messages, and ensures that we report problems as quickly
as possible.

@d BENCH(routine) {
	if (problem_count == 0) {
		clock_t now = clock();
		routine();
		int cs = ((int) (clock() - now)) / (CLOCKS_PER_SEC/100);
		if (cs > 0) LOG(".... " #routine "() took %dcs\n", cs);
	}
}

@d BENCH_IF(plugin, routine) {
	if ((problem_count == 0) && (Plugins::Manage::plugged_in(plugin))) {
		clock_t now = clock();
		routine();
		int cs = ((int) (clock() - now)) / (CLOCKS_PER_SEC/100);
		if (cs > 0) LOG(".... " #routine "() took %dcs\n", cs);
	}
}

@ Here, then, are the steps in the production line, presented without
commentary. For what they do, see the relevant sections. Note that although
most of these worker functions are in the |core| module, some are not.

@<Boot up the compiler@> =
	BENCH(Emit::begin);
	BENCH(Plugins::Manage::start);
	BENCH(InferenceSubjects::begin);
	BENCH(Index::DocReferences::read_xrefs);

@<Perform textual analysis@> =
	Task::advance_stage_to(LEXICAL_CSEQ, I"Textual analysis", 0);
	BENCH(Task::activate_language_elements)
	BENCH(Extensions::Inclusion::traverse)
	BENCH(Sentences::Headings::satisfy_dependencies)

	Task::advance_stage_to(SEMANTIC_LANGUAGE_CSEQ, I"Initialise language semantics", -1);
	BENCH(Plugins::Manage::start_plugins);
	BENCH(Task::load_types);
	BENCH(BinaryPredicates::make_built_in)
	BENCH(NewVerbs::add_inequalities)

	Task::advance_stage_to(SEMANTIC_I_CSEQ, I"Semantic analysis Ib", -1);
	BENCH(Sentences::VPs::traverse)
	BENCH(Sentences::Rearrangement::tidy_up_ofs_and_froms)
	BENCH(Sentences::RuleSubtrees::register_recently_lexed_phrases)
	BENCH(StructuralSentences::declare_source_loaded)
	BENCH(Kinds::Knowledge::include_templates_for_kinds)

	Task::advance_stage_to(SEMANTIC_II_CSEQ, I"Semantic analysis II", -1);
	BENCH(ParseTreeUsage::verify)
	BENCH(Extensions::Files::check_versions)
	BENCH(Headings::make_tree)
	BENCH(Sentences::Headings::write_as_xml)
	BENCH(Sentences::Headings::write_as_xml)
	BENCH(Modules::traverse_to_define)

	Task::advance_stage_to(SEMANTIC_III_CSEQ, I"Semantic analysis III", -1);
	BENCH(Phrases::Adjectives::traverse)
	BENCH(Equations::traverse_to_create)
	BENCH(Tables::traverse_to_create)
	BENCH(Phrases::Manager::traverse_for_names)

@<Read the assertions in two passes@> =
	Task::advance_stage_to(ASSERTIONS_PASS_1_CSEQ, I"First pass through assertions", 2);
	BENCH(Assertions::Traverse::traverse1)
	BENCH(Tables::traverse_to_stock)
	Task::advance_stage_to(ASSERTIONS_PASS_2_CSEQ, I"Second pass through assertions", -1);
	BENCH(Assertions::Traverse::traverse2)
	BENCH(Kinds::RunTime::kind_declarations)

@<Make the model world@> =
	Task::advance_stage_to(MODEL_CSEQ, I"Making the model world", -1);
	BENCH(UseOptions::compile)
	BENCH(Properties::emit)
	BENCH(Properties::Emit::allocate_attributes)
	BENCH(PL::Actions::name_all)
	BENCH(UseNouns::name_all)
	BENCH(Instances::place_objects_in_definition_sequence)
	Task::advance_stage_to(MODEL_COMPLETE_CSEQ, I"Completing the model world", -1);
	BENCH(World::complete)

@<Tables and grammar@> =
	Task::advance_stage_to(TABLES_CSEQ, I"Tables and grammar", -1);
	BENCH(Properties::Measurement::validate_definitions)
	BENCH(BinaryPredicates::make_built_in_further)
	BENCH(PL::Bibliographic::IFID::define_UUID)
	BENCH(PL::Figures::compile_ResourceIDsOfFigures_array)
	BENCH(PL::Sounds::compile_ResourceIDsOfSounds_array)
	BENCH(PL::Player::InitialSituation)
	BENCH(Tables::check_tables_for_kind_clashes)
	BENCH(Tables::Support::compile_print_table_names)
	BENCH(PL::Parsing::traverse)
	BENCH(World::complete_additions)

@<Phrases and rules@> =
	Task::advance_stage_to(PHRASES_CSEQ, I"Phrases and rules", 3);
	BENCH(LiteralPatterns::define_named_phrases)
	BENCH(Phrases::Manager::traverse)
	BENCH(Phrases::Manager::register_meanings)
	BENCH(Phrases::Manager::parse_rule_parameters)
	BENCH(Phrases::Manager::add_rules_to_rulebooks)
	BENCH(Phrases::Manager::parse_rule_placements)
	BENCH(Equations::traverse_to_stock)
	BENCH(Tables::traverse_to_stock)
	BENCH(Properties::annotate_attributes)
	BENCH(Rulebooks::Outcomes::RulebookOutcomePrintingRule)
	BENCH(Kinds::RunTime::compile_instance_counts)

@<Generate inter@> =
	Task::advance_stage_to(INTER_CSEQ, I"Generating inter", 4);
	BENCH(UseOptions::compile_icl_commands)
	BENCH(FundamentalConstants::emit_build_number)
	BENCH(PL::Bibliographic::compile_constants)
	BENCH(Extensions::Files::ShowExtensionVersions_routine)
	BENCH(Kinds::Constructors::compile_I6_constants)
	BENCH_IF(scoring_plugin, PL::Score::compile_max_score)
	BENCH(UseOptions::TestUseOption_routine)
	BENCH(Activities::compile_activity_constants)
	BENCH(Activities::Activity_before_rulebooks_array)
	BENCH(Activities::Activity_for_rulebooks_array)
	BENCH(Activities::Activity_after_rulebooks_array)
	BENCH(Activities::Activity_atb_rulebooks_array)
	BENCH(Relations::compile_defined_relation_constants)
	BENCH(Kinds::RunTime::compile_data_type_support_routines)
	BENCH(Kinds::RunTime::I7_Kind_Name_routine)
	BENCH(World::Compile::compile)
	BENCH_IF(backdrops_plugin, PL::Backdrops::write_found_in_routines)
	BENCH_IF(map_plugin, PL::Map::write_door_dir_routines)
	BENCH_IF(map_plugin, PL::Map::write_door_to_routines)
	BENCH_IF(parsing_plugin, PL::Parsing::Tokens::General::write_parse_name_routines)
	BENCH_IF(regions_plugin, PL::Regions::write_regional_found_in_routines)
	BENCH(Tables::complete)
	BENCH(Tables::Support::compile)
	BENCH(Equations::compile)
	BENCH_IF(actions_plugin, PL::Actions::Patterns::Named::compile)
	BENCH_IF(actions_plugin, PL::Actions::ActionData)
	BENCH_IF(actions_plugin, PL::Actions::ActionCoding_array)
	BENCH_IF(actions_plugin, PL::Actions::ActionHappened)
	BENCH_IF(actions_plugin, PL::Actions::compile_action_routines)
	BENCH_IF(parsing_plugin, PL::Parsing::Lines::MistakeActionSub_routine)
	BENCH(Phrases::Manager::compile_first_block)
	BENCH(Phrases::Manager::compile_rulebooks)
	BENCH(Phrases::Manager::rulebooks_array)
	BENCH_IF(scenes_plugin, PL::Scenes::DetectSceneChange_routine)
	BENCH_IF(scenes_plugin, PL::Scenes::ShowSceneStatus_routine)
	BENCH(PL::Files::arrays)
	BENCH(Rulebooks::rulebook_var_creators)
	BENCH(Activities::activity_var_creators)
	BENCH(Relations::IterateRelations)
	BENCH(Phrases::Manager::RulebookNames_array)
	BENCH(Phrases::Manager::RulePrintingRule_routine)
	BENCH_IF(parsing_plugin, PL::Parsing::Verbs::prepare)
	BENCH_IF(parsing_plugin, PL::Parsing::Verbs::compile_conditions)
	BENCH_IF(parsing_plugin, PL::Parsing::Tokens::Values::number)
	BENCH_IF(parsing_plugin, PL::Parsing::Tokens::Values::truth_state)
	BENCH_IF(parsing_plugin, PL::Parsing::Tokens::Values::time)
	BENCH_IF(parsing_plugin, PL::Parsing::Tokens::Values::compile_type_gprs)
	BENCH(NewVerbs::ConjugateVerb)
	BENCH(Adjectives::Meanings::agreements)

	if (debugging) {
		BENCH_IF(parsing_plugin, PL::Parsing::TestScripts::write_text)
		BENCH_IF(parsing_plugin, PL::Parsing::TestScripts::TestScriptSub_routine)
		BENCH_IF(parsing_plugin, PL::Parsing::TestScripts::InternalTestCases_routine)
	} else {
		BENCH_IF(parsing_plugin, PL::Parsing::TestScripts::TestScriptSub_stub_routine)
	}

	BENCH(Lists::check)
	BENCH(Lists::compile)
	BENCH(Phrases::invoke_to_begin)
	BENCH(Phrases::Manager::compile_as_needed)
	BENCH(Strings::compile_responses)
	BENCH(Lists::check)
	BENCH(Lists::compile)
	BENCH(Relations::compile_defined_relations)
	BENCH(Phrases::Manager::compile_as_needed)
	BENCH(Strings::TextSubstitutions::allow_no_further_text_subs)
	BENCH_IF(parsing_plugin, PL::Parsing::Tokens::Filters::compile)
	BENCH_IF(actions_plugin, Chronology::past_actions_i6_routines)
	BENCH_IF(chronology_plugin, Chronology::chronology_extents_i6_escape)
	BENCH_IF(chronology_plugin, Chronology::past_tenses_i6_escape)
	BENCH_IF(chronology_plugin, Chronology::allow_no_further_past_tenses)
	BENCH_IF(parsing_plugin, PL::Parsing::Verbs::compile_all)
	BENCH_IF(parsing_plugin, PL::Parsing::Tokens::Filters::compile)
	BENCH(Properties::Measurement::compile_MADJ_routines)
	BENCH(Calculus::Propositions::Deferred::compile_remaining_deferred)
	BENCH(Calculus::Deferrals::allow_no_further_deferrals)
	BENCH(Lists::check)
	BENCH(Lists::compile)
	BENCH(Strings::TextLiterals::compile)
	BENCH(JumpLabels::compile_necessary_storage)
	BENCH(Kinds::RunTime::compile_heap_allocator)
	BENCH(Phrases::Constants::compile_closures)
	BENCH(Kinds::RunTime::compile_structures)
	BENCH(Rules::check_response_usages)
	BENCH(Phrases::Timed::check_for_unused)
	BENCH(PL::Showme::compile_SHOWME_details)
	BENCH(Phrases::Timed::TimedEventsTable)
	BENCH(Phrases::Timed::TimedEventTimesTable)
	BENCH(PL::Naming::compile_cap_short_name)
	BENCH(UseOptions::configure_template)

@<Generate index and bibliographic file@> =
	Task::advance_stage_to(BIBLIOGRAPHIC_CSEQ, I"Bibliographic work", -1);
	BENCH_IF(bibliographic_plugin, PL::Bibliographic::Release::write_ifiction_and_blurb);
	BENCH(NaturalLanguages::produce_index);
