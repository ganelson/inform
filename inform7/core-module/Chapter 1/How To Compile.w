[Sequence::] How To Compile.

The long production line on which products of Inform are built, one step at a time.

@ Having seen the top management of the factory, we now reach the factory
floor, which is one long production line: around 130 steps must be performed
in sequence to finish making the product. We can picture each of these
steps as carried out by a worker function: each does its work and passes
on to the next.

130 is a great many, so we group the stages into 12 departments, which are,
in order of when they work:

@e SUBDIVIDING_CSEQ from 0
@e BUILT_IN_STUFF_CSEQ
@e SEMANTIC_ANALYSIS_CSEQ
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
int Sequence::carry_out(int debugging) {
	stopwatch_timer *sequence_timer =
		Time::start_stopwatch(inform7_timer, I"compilation to Inter");
	@<Divide into compilation units@>;
	@<Build a rudimentary set of kinds, relations, verbs and inference subjects@>;
	@<Pass three times through the major nodes@>;
	@<Make the model world@>;
	@<Tables and grammar@>;
	@<Phrases and rules@>;
	@<Generate inter@>;
	@<Generate index and bibliographic file@>;

	Task::advance_stage_to(FINISHED_CSEQ, I"Ccmplete", -1);
	int cpu_time_used = Time::stop_stopwatch(sequence_timer);
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
		TEMPORARY_TEXT(name)
		WRITE_TO(name, "//");
		WRITE_TO(name, #routine);
		WRITE_TO(name, "//");
		for (int i=0; i<Str::len(name)-1; i++)
			if ((Str::get_at(name, i) == '_') && (Str::get_at(name, i+1) == '_')) {
				Str::put_at(name, i, ':'); Str::put_at(name, i+1, ':');
			}
		stopwatch_timer *st = Time::start_stopwatch(sequence_timer, name);
		DISCARD_TEXT(name)
		routine();
		int cs = Time::stop_stopwatch(st);
		if (cs > 0) LOG(".... " #routine "() took %dcs\n", cs);
	}
}

@d BENCH_IF(plugin, routine) {
	if ((problem_count == 0) && (Plugins::Manage::plugged_in(plugin))) {
		TEMPORARY_TEXT(name)
		WRITE_TO(name, "//");
		WRITE_TO(name, #routine);
		WRITE_TO(name, "//");
		for (int i=0; i<Str::len(name)-1; i++)
			if ((Str::get_at(name, i) == '_') && (Str::get_at(name, i+1) == '_')) {
				Str::put_at(name, i, ':'); Str::put_at(name, i+1, ':');
			}
		stopwatch_timer *st = Time::start_stopwatch(sequence_timer, name);
		DISCARD_TEXT(name)
		routine();
		int cs = Time::stop_stopwatch(st);
		if (cs > 0) LOG(".... " #routine "() took %dcs\n", cs);
	}
}

@ Here, then, are the steps in the production line, presented without
commentary. For what they do, see the relevant sections. Note that although
most of these worker functions are in the |core| module, some are not.

Before anything else can be done, we must create an empty Inter hierarchy
into which we will "emit" an Inter program. No actual code will be emitted for
some time yet, but identifier names and type declarations need somewhere to go.
We then break the source into "compilation units" -- basically, one for the
main source text and one for each extension -- because the Inter hierarchy
will divide according to these units.

@<Divide into compilation units@> =
	Task::advance_stage_to(SUBDIVIDING_CSEQ, I"Dividing source into compilation units", -1);
	BENCH(CompilationSettings::initialise_gcs)
	BENCH(Emit::begin);
	BENCH(Sentences::Headings::make_the_tree)
	BENCH(Sentences::Headings::write_as_xml)
	BENCH(CompilationUnits::determine)

@ Most of the conceptual infrastructure in Inform is created by Inform source
text in the Basic Inform or Standard Rules extensions, but not basic kinds of
value such as "number", or the verb "to mean", or the meaning relation, and
so on. Those absolute basics are made here.

@<Build a rudimentary set of kinds, relations, verbs and inference subjects@> =
	Task::advance_stage_to(BUILT_IN_STUFF_CSEQ, I"Making built in infrastructure", -1);
	BENCH(InferenceSubjects::make_built_in);
	BENCH(Task::make_built_in_kind_constructors);
	BENCH(BinaryPredicates::make_built_in)
	BENCH(BootVerbs::make_built_in)

@<Pass three times through the major nodes@> =
	Task::advance_stage_to(SEMANTIC_ANALYSIS_CSEQ, I"Pre-pass through major nodes", 1);
	BENCH(MajorNodes::pre_pass)
	BENCH(ParseTreeUsage::verify)
	Task::advance_stage_to(ASSERTIONS_PASS_1_CSEQ, I"First pass through major nodes", 2);
	BENCH(MajorNodes::pass_1)
	BENCH(Tables::traverse_to_stock)
	Task::advance_stage_to(ASSERTIONS_PASS_2_CSEQ, I"Second pass through major nodes", -1);
	BENCH(MajorNodes::pass_2)

@<Make the model world@> =
	Task::advance_stage_to(MODEL_CSEQ, I"Making the model world", -1);
	BENCH(Kinds::RunTime::kind_declarations)
	BENCH(RTUseOptions::compile)
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
	BENCH(RTUseOptions::compile_pragmas)
	BENCH(FundamentalConstants::emit_build_number)
	BENCH(PL::Bibliographic::compile_constants)
	BENCH(Extensions::Files::ShowExtensionVersions_routine)
	BENCH(Kinds::Constructors::compile_I6_constants)
	BENCH_IF(scoring_plugin, PL::Score::compile_max_score)
	BENCH(RTUseOptions::TestUseOption_routine)
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
	BENCH(VerbsAtRunTime::ConjugateVerb)
	BENCH(Adjectives::Meanings::agreements)

	if (debugging) {
		BENCH_IF(parsing_plugin, PL::Parsing::TestScripts::write_text)
		BENCH_IF(parsing_plugin, PL::Parsing::TestScripts::TestScriptSub_routine)
		BENCH_IF(parsing_plugin, InternalTests::InternalTestCases_routine)
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
	BENCH(RTUseOptions::configure_template)

@<Generate index and bibliographic file@> =
	Task::advance_stage_to(BIBLIOGRAPHIC_CSEQ, I"Bibliographic work", -1);
	BENCH_IF(bibliographic_plugin, PL::Bibliographic::Release::write_ifiction_and_blurb);
	BENCH(I6T::produce_index);
