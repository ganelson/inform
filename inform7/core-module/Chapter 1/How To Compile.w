[Sequence::] How To Compile.

The long production line on which products of Inform are built, one step at a time.

@ Having seen the top management of the factory, we now reach the factory
floor, which is one long production line: over 100 steps must be performed
in sequence to finish making the product. We can picture each of these
steps as carried out by a worker function: each does its work and passes
on to the next.

We group the steps into departments, which are in order of when they work:

@e SUBDIVIDING_CSEQ from 0
@e BUILT_IN_STUFF_CSEQ
@e SEMANTIC_ANALYSIS_CSEQ
@e ASSERTIONS_PASS_1_CSEQ
@e ASSERTIONS_PASS_2_CSEQ
@e MODEL_CSEQ
@e MODEL_COMPLETE_CSEQ
@e TABLES_CSEQ
@e AUGMENT_CSEQ
@e PHRASES_CSEQ
@e INTER1_CSEQ
@e INTER2_CSEQ
@e INTER3_CSEQ
@e INTER4_CSEQ
@e INTER5_CSEQ
@e BIBLIOGRAPHIC_CSEQ
@e FINISHED_CSEQ

@ The aim of this section is to contain as little logic as possible other
then the sequence itself.

=
int Sequence::carry_out(int debugging) {
	stopwatch_timer *sequence_timer =
		Time::start_stopwatch(inform7_timer, I"compilation to Inter");
	@<Divide into compilation units@>;
	@<Build a rudimentary set of kinds, relations, verbs and inference subjects@>;
	@<Pass three times through the major nodes@>;
	@<Make the model world@>;
	@<Tables and grammar@>;
	@<Augment model world with low-level properties@>;
	@<Phrases and rules@>;
	@<Generate inter, part 1@>
	@<Generate inter, part 2@>
	@<Generate inter, part 3@>
	@<Generate inter, part 4@>
	@<Generate inter, part 5@>
	@<Generate index and bibliographic file@>;

	Task::advance_stage_to(FINISHED_CSEQ, I"Ccmplete", -1, debugging, sequence_timer);
	int cpu_time_used = Time::stop_stopwatch(sequence_timer);
	LOG("Compile CPU time: %d centiseconds\n", cpu_time_used);
	if (problem_count > 0) return FALSE;
	return TRUE;
}

@ This macro carries out a step at what we think of as "benches" in the
production line: hence the name |BENCH|. Continuing the analogy, there is an
ongoing time and motion study: any step which takes more than 1 centisecond of
CPU time is reported to the debugging log. That isn't necessarily a sign of
something wrong: a few of these steps are always going to take serious
computation. But we want to know which ones.

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
commentary. For what they do, see the relevant sections. Note that at the
end of each stage, plugins are allowed to add further steps; see
//Task::advance_stage_to//.

Before anything else can be done, we must create an empty Inter hierarchy
into which we will "emit" an Inter program. No actual code will be emitted for
some time yet, but identifier names and type declarations need somewhere to go.
We then break the source into "compilation units" -- basically, one for the
main source text and one for each extension -- because the Inter hierarchy
will divide according to these units.

@<Divide into compilation units@> =
	Task::advance_stage_to(SUBDIVIDING_CSEQ, I"Dividing source into compilation units",
		-1, debugging, sequence_timer);
	BENCH(CompilationSettings::initialise_gcs)
	BENCH(Emit::create_emission_tree)
	BENCH(Hierarchy::establish)
	BENCH(Emit::rudimentary_kinds);
	BENCH(RTVerbs::ConjugateVerbDefinitions);
	BENCH(NameResolution::make_the_tree)
	BENCH(IndexHeadings::write_as_xml)
	BENCH(CompilationUnits::determine)

@ Most of the conceptual infrastructure in Inform is created by Inform source
text in the Basic Inform or Standard Rules extensions, but not basic kinds of
value such as "number", or the verb "to mean", or the meaning relation, and
so on. Those absolute basics are made here.

@<Build a rudimentary set of kinds, relations, verbs and inference subjects@> =
	Task::advance_stage_to(BUILT_IN_STUFF_CSEQ, I"Making built in infrastructure",
		-1, debugging, sequence_timer);
	BENCH(InferenceSubjects::make_built_in);
	BENCH(Task::make_built_in_kind_constructors);
	BENCH(BinaryPredicateFamilies::first_stock)
	BENCH(BootVerbs::make_built_in)

@<Pass three times through the major nodes@> =
	Task::advance_stage_to(SEMANTIC_ANALYSIS_CSEQ, I"Pre-pass through major nodes",
		1, debugging, sequence_timer);
	BENCH(MajorNodes::pre_pass)
	BENCH(Task::verify)
	Task::advance_stage_to(ASSERTIONS_PASS_1_CSEQ, I"First pass through major nodes",
		2, debugging, sequence_timer);
	BENCH(MajorNodes::pass_1)
	BENCH(Tables::traverse_to_stock)
	Task::advance_stage_to(ASSERTIONS_PASS_2_CSEQ, I"Second pass through major nodes",
		-1, debugging, sequence_timer);
	BENCH(MajorNodes::pass_2)

@<Make the model world@> =
	Task::advance_stage_to(MODEL_CSEQ, I"Making the model world",
		-1, debugging, sequence_timer);
	BENCH(RTKinds::kind_declarations)
	BENCH(RTProperties::emit)
	BENCH(RTPropertyValues::allocate_attributes)
	BENCH(NounIdentifiers::name_all)
	BENCH(OrderingInstances::objects_in_definition_sequence)
	Task::advance_stage_to(MODEL_COMPLETE_CSEQ, I"Completing the model world",
		-1, debugging, sequence_timer);
	BENCH(World::stages_II_and_III)
	BENCH(World::stage_IV)

@<Tables and grammar@> =
	Task::advance_stage_to(TABLES_CSEQ, I"Tables and grammar",
		-1, debugging, sequence_timer);
	BENCH(Measurements::validate_definitions)
	BENCH(BinaryPredicateFamilies::second_stock)
	BENCH(Tables::check_tables_for_kind_clashes)
	BENCH(RTTables::compile_print_table_names)

@<Augment model world with low-level properties@> =
	Task::advance_stage_to(AUGMENT_CSEQ, I"Augment model world",
		-1, debugging, sequence_timer);
	BENCH(World::stage_V)

@<Phrases and rules@> =
	Task::advance_stage_to(PHRASES_CSEQ, I"Phrases and rules",
		3, debugging, sequence_timer);
	BENCH(LiteralPatterns::define_named_phrases)
	BENCH(ImperativeDefinitions::assess_all)
	BENCH(Equations::traverse_to_stock)
	BENCH(Tables::traverse_to_stock)
	BENCH(RTProperties::annotate_attributes)
	BENCH(RTRules::RulebookOutcomePrintingRule)
	BENCH(RTKinds::compile_instance_counts)

@ This proceeds in stages.

@<Generate inter, part 1@> =
	Task::advance_stage_to(INTER1_CSEQ, I"Generating inter (1)",
		4, debugging, sequence_timer);
	BENCH(RTFundamentalConstants::compile);
	BENCH(RTUseOptions::compile)
	BENCH(RTExtensions::compile_support)
	BENCH(Interventions::make_all)
	BENCH(Kinds::Constructors::emit_constants)
	BENCH(RTActivities::arrays)
	BENCH(RTRelations::compile_defined_relation_constants)
	BENCH(RTKinds::compile_data_type_support_routines)
	BENCH(RTKinds::I7_Kind_Name_routine)
	
@<Generate inter, part 2@> =
	Task::advance_stage_to(INTER2_CSEQ, I"Generating inter (2)",
		-1, debugging, sequence_timer);
	BENCH(InferenceSubjects::emit_all)
	BENCH(Tables::complete)
	BENCH(RTTables::compile)
	BENCH(RTEquations::compile_identifiers)
	BENCH(ImperativeDefinitions::compile_first_block)
	BENCH(RTRules::compile_rulebooks)
	BENCH(RTRules::rulebooks_array_array)
	BENCH(RTRules::rulebook_var_creators)
	BENCH(RTActivities::activity_var_creators)
	BENCH(RTRelations::IterateRelations)
	BENCH(RTRules::RulebookNames_array)
	BENCH(RTRules::RulePrintingRule_routine)
	BENCH(RTVerbs::ConjugateVerb)
	BENCH(RTAdjectives::agreements)
	if (debugging) {
		BENCH(InternalTests::InternalTestCases_routine)
	}

@<Generate inter, part 3@> =
	Task::advance_stage_to(INTER3_CSEQ, I"Generating inter (3)",
		-1, debugging, sequence_timer);
	BENCH(Sequence::compile_literal_resources)
	BENCH(PhraseRequests::invoke_to_begin)
	BENCH(Closures::compile_closures)
	BENCH(Sequence::compile_function_resources)
	BENCH(Strings::compile_responses)
	BENCH(Sequence::compile_literal_resources)
	BENCH(RTRelations::compile_defined_relations)
	BENCH(Sequence::compile_function_resources)
	BENCH(TextSubstitutions::allow_no_further_text_subs)
	BENCH(Deferrals::allow_no_further_deferrals)

@<Generate inter, part 4@> =
	Task::advance_stage_to(INTER4_CSEQ, I"Generating inter (4)",
		-1, debugging, sequence_timer);
	BENCH(Chronology::past_actions_i6_routines)
	BENCH(Chronology::compile_runtime)
	
@<Generate inter, part 5@> =
	Task::advance_stage_to(INTER5_CSEQ, I"Generating inter (5)",
		-1, debugging, sequence_timer);
	BENCH(RTMeasurements::compile_test_functions)
	BENCH(Sequence::compile_literal_resources)
	BENCH(TextLiterals::compile)
	BENCH(RTKinds::compile_heap_allocator)
	BENCH(RTKinds::compile_structures)
	BENCH(Rules::check_response_usages)
	BENCH(LocalParking::compile_array)
	BENCH(RTBibliographicData::IFID_text)

@<Generate index and bibliographic file@> =
	Task::advance_stage_to(BIBLIOGRAPHIC_CSEQ, I"Bibliographic work",
		-1, debugging, sequence_timer);
	BENCH(Hierarchy::log);
	BENCH(InterpretIndex::produce_index);

@ We will define just one of the above steps here, because it works in a way
which breaks the pattern of doing everything just once. For one thing, it's
actually called twice in the above sequence.

The issue here is that each time an imperative definition is compiled to a
function, that can require other resources to be compiled in turn. The
code compiled into the function body can involve calls to functions derived
from other imperative definitions, or even the same one reinterpreted:
= (text as Inform 7)
To expose (X - a value):
	say "You admire [X]."

To advertise (T - text):
	expose T;
	let the price be "the price tag of [a random number between 5 and 10] pounds";
	expose the price.

Every turn:
    advertise "a valuable antique silver coffee pot".
=
Phrases are compiled on demand, but rules are always demanded, so the "every
turn" rule here is compiled; that requires "advertise" to be compiled; which
in turn requires a form of "expose X" to be compiled for X a text. But
"advertise" also needs the text substitution "the price tag of [a random number
between 5 and 10] pounds" to be compiled, and that in turn creates a further
function compilation in order to provide a context for execution of the phrase
"a random number between 5 and 10", which in turn... and so on.

The only way to be sure of handling all needs here is to keep on compiling
until the process exhausts itself, and this we do. The process is structured
as a set of coroutines[1] which each carry out as much as they can of the work
which has arisen since they were last called, then return how much they did.
Each may indirectly create work for the others, so we repeat until they are
all happy.

The result terminates since eventually every "To..." phrase definition will
have been compiled with every possible interpretation of its kinds. After that,
everything fizzles out quickly, because none of the other resources here are
able to create new work for each other. The safety cutout in this function is
just defensive programming, and has never been activated. Typically only
one or two iterations are needed in practical cases.

[1] C does not support coroutines, though that hasn't stopped hackers from using
assembly language to manipulate return addresses on the C call stack, and/or use
//Duff's device -> https://en.wikipedia.org/wiki/Duff%27s_device//. We avoid
all that by using regular C functions which merely imitate coroutines by
cooperatively giving way to each other. They |return| to the central organising
function //Sequence::compile_function_resources//, not directly into each
other's bodies. But I think the term "coroutine" is reasonable just the same.

=
void Sequence::compile_function_resources(void) {
	int repeat = TRUE, iterations = 0;
	while (repeat) {
		repeat = FALSE; iterations++;

		if (PhraseRequests::compilation_coroutine() > 0)       repeat = TRUE;
		if (ListTogether::compilation_coroutine() > 0)         repeat = TRUE;
		if (LoopingOverScope::compilation_coroutine() > 0)     repeat = TRUE;
		if (TextSubstitutions::compilation_coroutine() > 0)    repeat = TRUE;
		if (DeferredPropositions::compilation_coroutine() > 0) repeat = TRUE;

		if ((problem_count > 0) && (iterations > 10)) repeat = FALSE;
	}
	iterations--; /* since the final round is one where everyone does nothing */
	if (iterations > 0)
		LOG(".... Sequence::compile_function_resources completed in %d iteration%s\n",
			iterations, (iterations == 1)?"":"s");
}

@ And very similarly:

=
void Sequence::compile_literal_resources(void) {
	int repeat = TRUE, iterations = 0;
	while (repeat) {
		repeat = FALSE; iterations++;

		if (ListLiterals::compile_support_matter() > 0)        repeat = TRUE;
		if (BoxQuotations::compile_support_matter() > 0)        repeat = TRUE;

		if ((problem_count > 0) && (iterations > 10)) repeat = FALSE;
	}
	iterations--; /* since the final round is one where everyone does nothing */
	if (iterations > 0)
		LOG(".... Sequence::compile_literal_resources completed in %d iteration%s\n",
			iterations, (iterations == 1)?"":"s");
}
