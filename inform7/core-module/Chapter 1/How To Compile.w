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
	BENCH(NameResolution::make_the_tree)
	BENCH(IndexHeadings::write_as_xml)
	BENCH(CompilationUnits::determine)

@ Most of the conceptual infrastructure in Inform is created by Inform source
text in the Basic Inform or Standard Rules extensions, but not basic kinds of
value such as "number", or the verb "to mean", or the meaning relation, and
so on. Those absolute basics are made here.

@<Build a rudimentary set of kinds, relations, verbs and inference subjects@> =
	Task::advance_stage_to(BUILT_IN_STUFF_CSEQ, I"Making built in infrastructure", -1);
	BENCH(InferenceSubjects::make_built_in);
	BENCH(Task::make_built_in_kind_constructors);
	BENCH(BinaryPredicateFamilies::first_stock)
	BENCH(BootVerbs::make_built_in)

@<Pass three times through the major nodes@> =
	Task::advance_stage_to(SEMANTIC_ANALYSIS_CSEQ, I"Pre-pass through major nodes", 1);
	BENCH(MajorNodes::pre_pass)
	BENCH(Task::verify)
	Task::advance_stage_to(ASSERTIONS_PASS_1_CSEQ, I"First pass through major nodes", 2);
	BENCH(MajorNodes::pass_1)
	BENCH(Tables::traverse_to_stock)
	Task::advance_stage_to(ASSERTIONS_PASS_2_CSEQ, I"Second pass through major nodes", -1);
	BENCH(MajorNodes::pass_2)

@<Make the model world@> =
	Task::advance_stage_to(MODEL_CSEQ, I"Making the model world", -1);
	BENCH(RTKinds::kind_declarations)
	BENCH(RTUseOptions::compile)
	BENCH(RTProperties::emit)
	BENCH(RTPropertyValues::allocate_attributes)
	BENCH(PL::Actions::name_all)
	BENCH(NounIdentifiers::name_all)
	BENCH(OrderingInstances::objects_in_definition_sequence)
	Task::advance_stage_to(MODEL_COMPLETE_CSEQ, I"Completing the model world", -1);
	BENCH(World::stages_II_and_III)
	BENCH(World::stage_IV)

@<Tables and grammar@> =
	Task::advance_stage_to(TABLES_CSEQ, I"Tables and grammar", -1);
	BENCH(Measurements::validate_definitions)
	BENCH(BinaryPredicateFamilies::second_stock)
	BENCH(PL::Player::InitialSituation)
	BENCH(Tables::check_tables_for_kind_clashes)
	BENCH(RTTables::compile_print_table_names)
	BENCH(PL::Parsing::traverse)
	BENCH(World::stage_V)

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
	BENCH(RTProperties::annotate_attributes)
	BENCH(Rulebooks::Outcomes::RulebookOutcomePrintingRule)
	BENCH(RTKinds::compile_instance_counts)

@ This proceeds in stages.

@<Generate inter@> =
	Task::advance_stage_to(INTER_CSEQ, I"Generating inter", 4);
	BENCH(RTUseOptions::compile_pragmas)
	BENCH(FundamentalConstants::emit_build_number)
	BENCH(RTExtensions::ShowExtensionVersions_routine)
	BENCH(Kinds::Constructors::emit_constants)
	BENCH(RTUseOptions::TestUseOption_routine)
	BENCH(Activities::compile_activity_constants)
	BENCH(Activities::Activity_before_rulebooks_array)
	BENCH(Activities::Activity_for_rulebooks_array)
	BENCH(Activities::Activity_after_rulebooks_array)
	BENCH(Activities::Activity_atb_rulebooks_array)
	BENCH(RTRelations::compile_defined_relation_constants)
	BENCH(RTKinds::compile_data_type_support_routines)
	BENCH(RTKinds::I7_Kind_Name_routine)
	if (debugging) {
		BENCH(RuntimeModule::compile_debugging_runtime_data_1)
	} else {
		BENCH(RuntimeModule::compile_runtime_data_1)
	}
	BENCH(InferenceSubjects::emit_all)
	BENCH(Tables::complete)
	BENCH(RTTables::compile)
	BENCH(RTEquations::compile_identifiers)
	BENCH(Phrases::Manager::compile_first_block)
	BENCH(Phrases::Manager::compile_rulebooks)
	BENCH(Phrases::Manager::rulebooks_array)
	BENCH(Rulebooks::rulebook_var_creators)
	BENCH(Activities::activity_var_creators)
	BENCH(RTRelations::IterateRelations)
	BENCH(Phrases::Manager::RulebookNames_array)
	BENCH(Phrases::Manager::RulePrintingRule_routine)
	BENCH(RTVerbs::ConjugateVerb)
	BENCH(RTAdjectives::agreements)
	if (debugging) {
		BENCH(RuntimeModule::compile_debugging_runtime_data_2)
		BENCH(InternalTests::InternalTestCases_routine)
	} else {
		BENCH(RuntimeModule::compile_runtime_data_2)
	}

	BENCH(Lists::check)
	BENCH(ConstantLists::compile)
	BENCH(Phrases::invoke_to_begin)
	BENCH(Phrases::Manager::compile_as_needed)
	BENCH(Strings::compile_responses)
	BENCH(Lists::check)
	BENCH(ConstantLists::compile)
	BENCH(RTRelations::compile_defined_relations)
	BENCH(Phrases::Manager::compile_as_needed)
	BENCH(Strings::TextSubstitutions::allow_no_further_text_subs)
	if (debugging) {
		BENCH(RuntimeModule::compile_debugging_runtime_data_3)
	} else {
		BENCH(RuntimeModule::compile_runtime_data_3)
	}
	BENCH(Chronology::past_actions_i6_routines)
	BENCH(Chronology::compile_runtime)
	if (debugging) {
		BENCH(RuntimeModule::compile_debugging_runtime_data_4)
	} else {
		BENCH(RuntimeModule::compile_runtime_data_4)
	}
	BENCH(RTMeasurements::compile_test_functions)
	BENCH(Propositions::Deferred::compile_remaining_deferred)
	BENCH(Calculus::Deferrals::allow_no_further_deferrals)
	BENCH(Lists::check)
	BENCH(ConstantLists::compile)
	BENCH(TextLiterals::compile)
	BENCH(JumpLabels::compile_necessary_storage)
	BENCH(RTKinds::compile_heap_allocator)
	BENCH(Phrases::Constants::compile_closures)
	BENCH(RTKinds::compile_structures)
	BENCH(Rules::check_response_usages)
	BENCH(Phrases::Timed::check_for_unused)
	BENCH(PL::Showme::compile_SHOWME_details)
	BENCH(Phrases::Timed::TimedEventsTable)
	BENCH(Phrases::Timed::TimedEventTimesTable)
	BENCH(PL::Naming::compile_cap_short_name)
	BENCH(RTUseOptions::configure_template)
	BENCH(RTBibliographicData::IFID_text);

@<Generate index and bibliographic file@> =
	Task::advance_stage_to(BIBLIOGRAPHIC_CSEQ, I"Bibliographic work", -1);
	BENCH(PluginCalls::post_compilation);
	BENCH(I6T::produce_index);
