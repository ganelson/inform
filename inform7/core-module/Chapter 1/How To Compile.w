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
text_stream *current_sequence_bench = NULL;

int Sequence::carry_out(int debugging) {
	stopwatch_timer *sequence_timer =
		Time::start_stopwatch(inform7_timer, I"compilation to Inter");
	current_sequence_bench = Str::new();
	@<Divide into compilation units@>;
	@<Build a rudimentary set of kinds, relations, verbs and inference subjects@>;
	@<Pass three times through the major nodes@>;
	@<Make the model world@>;
	@<Tables and grammar@>;
	@<Augment model world with low-level properties@>;
	@<Phrases and rules@>;
	@<Run any internal tests@>;
	@<Generate inter, part 1@>
	@<Generate inter, part 2@>
	@<Generate inter, part 3@>
	@<Generate inter, part 4@>
	@<Generate inter, part 5@>
	@<Generate index and bibliographic file@>;
	if (problem_count == 0) Sequence::throw_error_if_subtasks_remain();
	Task::advance_stage_to(FINISHED_CSEQ, I"Complete", -1, debugging, sequence_timer);
	Str::clear(current_sequence_bench);
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
		Str::clear(current_sequence_bench);
		WRITE_TO(current_sequence_bench, "%S", name);
		DISCARD_TEXT(name)
		routine();
		int cs = Time::stop_stopwatch(st);
		if (cs > 0) LOG(".... " #routine "() took %dcs\n", cs);
	}
}

@ Here, then, are the steps in the production line, presented without
commentary. For what they do, see the relevant sections. Note that at the
end of each stage, plugins made by compiler features are allowed to add
further steps; see //Task::advance_stage_to//.

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
	BENCH(GenericModule::compile);
	BENCH(NameResolution::make_the_tree)
	BENCH(Task::write_XML_headings_file)
	BENCH(CompilationUnits::determine)
	BENCH(Task::warn_about_deprecated_nests)

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
	BENCH(Instances::make_instances_from_Neptune);

@<Pass three times through the major nodes@> =
	Task::advance_stage_to(SEMANTIC_ANALYSIS_CSEQ, I"Pre-pass through major nodes",
		1, debugging, sequence_timer);
	BENCH(MajorNodes::pre_pass)
	BENCH(Task::verify)
	Task::advance_stage_to(ASSERTIONS_PASS_1_CSEQ, I"First pass through major nodes",
		2, debugging, sequence_timer);
	BENCH(MajorNodes::pass_1)
	BENCH(Tables::traverse_to_stock)
	BENCH(Dialogue::after_pass_1)
	Task::advance_stage_to(ASSERTIONS_PASS_2_CSEQ, I"Second pass through major nodes",
		-1, debugging, sequence_timer);
	BENCH(MajorNodes::pass_2)
	BENCH(DialogueBeats::decide_cue_topics)

@<Make the model world@> =
	Task::advance_stage_to(MODEL_CSEQ, I"Making the model world",
		-1, debugging, sequence_timer);
	BENCH(RTKindDeclarations::declare_base_kinds)
	BENCH(Translations::traverse_for_late_namings)
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

@<Augment model world with low-level properties@> =
	Task::advance_stage_to(AUGMENT_CSEQ, I"Augment model world",
		-1, debugging, sequence_timer);
	BENCH(World::stage_V)
	BENCH(MappingHints::traverse_for_map_parameters)

@<Phrases and rules@> =
	Task::advance_stage_to(PHRASES_CSEQ, I"Phrases and rules",
		3, debugging, sequence_timer);
	BENCH(LiteralPatterns::define_named_phrases)
	BENCH(ImperativeDefinitions::assess_all)
	BENCH(Equations::traverse_to_stock)
	BENCH(Tables::traverse_to_stock)
	BENCH(RTRulebooks::RulebookOutcomePrintingRule)

@ See //Internal Test Cases// for an explanation of the alarming-looking |exit|
here, which only happens when special runs are made for compiler testing.

@<Run any internal tests@> =
	if ((debugging) && (problem_count == 0)) {
		int tests_run = InternalTests::run(1);
		if (tests_run > 0) exit(0);
	}

@ This proceeds in stages.

@<Generate inter, part 1@> =
	Task::advance_stage_to(INTER1_CSEQ, I"Generating inter (1)",
		4, debugging, sequence_timer);
	BENCH(RTUseOptions::compile)
	BENCH(RTCommandGrammars::compile_non_generic_constants)
	BENCH(Interventions::make_all)
	BENCH(RTKindConstructors::assign_declaration_sequence_numbers)
	BENCH(RTKindConstructors::compile)
	BENCH(RTLiteralPatterns::compile)
	
@<Generate inter, part 2@> =
	Task::advance_stage_to(INTER2_CSEQ, I"Generating inter (2)",
		-1, debugging, sequence_timer);
	BENCH(CompletionModule::compile);
	BENCH(RTProperties::compile)
	BENCH(RTKindConstructors::compile_permissions)
	BENCH(InferenceSubjects::emit_all)
	BENCH(Tables::complete)
	BENCH(RTTables::compile)
	BENCH(RTTableColumns::compile)
	BENCH(RTEquations::compile)
	BENCH(ImperativeDefinitions::compile_first_block)
	BENCH(RTDialogueBeats::compile)
	BENCH(RTDialogueLines::compile)
	BENCH(RTDialogueChoices::compile)
	BENCH(RTRules::compile)
	BENCH(RTRulebooks::compile)
	BENCH(RTRulebooks::compile_nros)
	BENCH(RTActivities::compile)
	BENCH(RTVerbs::compile_conjugations)
	BENCH(RTVerbs::compile_forms)
	BENCH(CompilationUnits::complete_metadata);

@<Generate inter, part 3@> =
	Task::advance_stage_to(INTER3_CSEQ, I"Generating inter (3)",
		-1, debugging, sequence_timer);
	BENCH(PhraseRequests::invoke_to_begin)
	BENCH(Closures::compile_closures)
	BENCH(Sequence::undertake_queued_tasks)
	BENCH(RTRelations::compile)
	BENCH(RTAdjectives::compile_mdef_test_functions)
	BENCH(Sequence::undertake_queued_tasks)
	BENCH(RTPhrasebook::compile_entries);
	BENCH(RTMappingHints::compile)

@<Generate inter, part 4@> =
	Task::advance_stage_to(INTER4_CSEQ, I"Generating inter (4)",
		-1, debugging, sequence_timer);

@<Generate inter, part 5@> =
	Task::advance_stage_to(INTER5_CSEQ, I"Generating inter (5)",
		-1, debugging, sequence_timer);
	BENCH(Sequence::undertake_queued_tasks)
	BENCH(RTKindIDs::compile_structures)
	BENCH(Sequence::undertake_queued_tasks)
	BENCH(Sequence::allow_no_further_queued_tasks)
	BENCH(TheHeap::compile_configuration)
	BENCH(Rules::check_response_usages)
	BENCH(LocalParking::compile_array)
	BENCH(RTBibliographicData::IFID_text)
	BENCH(Sequence::lint_inter)

@<Generate index and bibliographic file@> =
	Task::advance_stage_to(BIBLIOGRAPHIC_CSEQ, I"Bibliographic work",
		-1, debugging, sequence_timer);
	BENCH(Hierarchy::log);
	if ((debugging) && (problem_count == 0)) {
		int tests_run = InternalTests::run(2);
		if (tests_run > 0) exit(0);
	}
	BENCH(Task::specify_index_requirements);
	if (Log::aspect_switched_on(INTER_DA))
		InterSkill::set_debugging();
	if (Log::aspect_switched_on(INFORM_INTER_DA))
		TextualInter::write(DL, Emit::tree(), NULL);
	linked_list *L = Dash::phrases_to_log();
	if (L) {
		LOG("Phrase or rule bodies for which textual Inter was requested by '***':\n");
		int n = 1;
		inter_package *pack;
		LOOP_OVER_LINKED_LIST(pack, inter_package, L) {	
			LOG("\n%d. Package at $6:\n", n++, pack);
			TextualInter::write_package(DL, Emit::tree(), pack);
		}
	}

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

@ The only way to be sure of handling all needs here is to keep on compiling
until the process exhausts itself, and this we do with a queue of tasks to
perform.[1] Suppose we have this queue:
= (text)
	T1 -> T2 -> T3 -> T4 -> ...
=
and we are working on T2. That uncovers the need for three further tasks
X1, X2, X3: those are added immediately after T2 --
= (text)
	T1 -> T2 -> X1 -> X2 -> X3 -> T3 -> T4 -> ...
=
Thus we never reach T3 until T2 has been completely exhausted, including its
secondary tasks. To get a sense of how this works in practice, try:
= (text)
Include task queue in the debugging log.
=

[1] Until 2021 this process is structured as a set of coroutines rather than a
queue. C does not strictly speaking support coroutines, though that hasn't stopped
hackers from using assembly language to manipulate return addresses on the C call
stack, and/or use
//Duff's device -> https://en.wikipedia.org/wiki/Duff%27s_device//. It never
quite came to that here, but it was sometimes difficult to reason about.

@ A task is abstracted as being a call to a function, called the "agent", with
a pointer to the relevant data.

=
typedef struct compilation_subtask {
	struct compilation_subtask *caused_by;
	struct compilation_subtask *next_task;
	void (*agent)(struct compilation_subtask *);
	struct general_pointer data;
	struct parse_node *current_sentence_when_queued;
	struct text_stream *description;
	CLASS_DEFINITION
} compilation_subtask;

compilation_subtask *Sequence::new_subtask(void (*agent)(struct compilation_subtask *),
	general_pointer gp, text_stream *desc) {
	compilation_subtask *t = CREATE(compilation_subtask);
	t->caused_by = NULL;
	t->next_task = NULL;
	t->agent = agent;
	t->data = gp;
	t->current_sentence_when_queued = current_sentence;
	t->description = desc;
	return t;
}

@ Each call to //Sequence::undertake_queued_tasks// works methodically through
the queue until everything is done.

The queue is a linked list of |compilation_subtask| objects in between |first_task|
and |last_task|. (The queue is empty if and only if both are |NULL|.) The queue
only grows, and never has items removed.

A marker called |last_task_undetaken| shows how much progress we have made in
completing the tasks queued: so, when this is equal to |last_task|, there is
nothing to do. Another marker called |current_task| is set only when a task
is under way, and is |NULL| at all other times.

=
compilation_subtask *first_task = NULL, *last_task = NULL, *last_task_undetaken = NULL;
compilation_subtask *current_task = NULL, *current_horizon = NULL;
int task_queue_is_closed = FALSE;

@ The rest of Inform, if it wants to schedule a compilation task, should call
one of these two functions:

=
void Sequence::queue(void (*agent)(struct compilation_subtask *),
	general_pointer gp, text_stream *desc) {
	compilation_subtask *t = Sequence::new_subtask(agent, gp, desc);
	@<Queue the task@>;
}

void Sequence::queue_at(void (*agent)(struct compilation_subtask *),
	general_pointer gp, text_stream *desc, parse_node *at) {
	compilation_subtask *t = Sequence::new_subtask(agent, gp, desc);
	t->current_sentence_when_queued = at;
	@<Queue the task@>;
}

@ New entries are inserted in the queue at two write positions:
(*) after the |last_task|, i.e., at the back, if no task is currently going on; or
(*) after the |current_horizon| marker, i.e., after the current task finishes.

In the case where we are currently in the middle of what was the last task
when it started, these two positions will be the same, so we sometimes need
to advance |last_task| even when |current_horizon| is set.

@<Queue the task@> =
	t->caused_by = current_task;
	if (first_task == NULL) { first_task = t; last_task = t; return; }
	if (current_horizon) {
		t->next_task = current_horizon->next_task;
		current_horizon->next_task = t;
		current_horizon = t;
	} else {
		t->next_task = NULL;
		last_task->next_task = t;
	}
	if (t->next_task == NULL) last_task = t;
	if (t->caused_by) WRITE_TO(t->description, " from [%d]", t->caused_by->allocation_id);
	else WRITE_TO(t->description, " from %S", current_sequence_bench);
	if (task_queue_is_closed) {
		LOG("offending task was: ");
		Sequence::write_task(DL, t);
		internal_error("too late to schedule further compilation tasks");
	}
	if (Log::aspect_switched_on(TASK_QUEUE_DA)) {
		LOG("queued:    ");
		Sequence::write_task(DL, t);
	}

@ Here the chimes of midnight sound:

=
void Sequence::allow_no_further_queued_tasks(void) {
	task_queue_is_closed = TRUE;
}

@ So here is where the work is done, and the |last_task_undetaken| advances:

=
void Sequence::undertake_queued_tasks(void) {
	compilation_subtask *t;
	do {
		t = first_task;
		if (last_task_undetaken) t = last_task_undetaken->next_task;
		if (t) {
			last_task_undetaken = t;
			compilation_subtask *save_task = current_task;
			compilation_subtask *save_horizon = current_horizon;
			parse_node *save = current_sentence;
			current_task = t;
			current_horizon = t;
			current_sentence = t->current_sentence_when_queued;
			(*(t->agent))(t);
			if (Log::aspect_switched_on(TASK_QUEUE_DA)) {
				LOG("completed: ");
				Sequence::write_task(DL, t);
			}
			current_sentence = save;
			current_task = save_task; 
			current_horizon = save_horizon;
			current_sentence = save;
		}
	} while (t);
}	

@ At the end of compilation, the queue ought to be empty, but just in case:

=
void Sequence::throw_error_if_subtasks_remain(void) {
	if (first_task) {
		compilation_subtask *t = first_task;
		if (last_task_undetaken) t = last_task_undetaken->next_task;
		if (t) {
			Sequence::write_from(DL, t);
			internal_error("there are compilation tasks never reached");
		}
	}
}

void Sequence::backtrace(void) {
	compilation_subtask *t = current_task;
	int d = 0;
	while (t) {
		if (d++ == 0) LOG("During compilation task: ");
		else LOG("caused by compilation task: ");
		Sequence::write_task(DL, t);
		t = t->caused_by;
	}
	if (Str::len(current_sequence_bench) > 0)
		LOG("During bench %S\n", current_sequence_bench);
}

@ And these are used for logging:

=
void Sequence::write_from(OUTPUT_STREAM, compilation_subtask *t) {
	while (t) {
		Sequence::write_task(OUT, t);
		t = t->next_task;
	}
}

void Sequence::write_task(OUTPUT_STREAM, compilation_subtask *t) {
	if (t == NULL) WRITE("[NULL]\n");
	else WRITE("[%d] %S\n", t->allocation_id, t->description);
}

@ The final step is to verify that the Inter we have produced is correct:

=
void Sequence::lint_inter(void) {
	InterInstruction::tree_lint(Emit::tree());
}
