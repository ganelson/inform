[RunningPipelines::] Running Pipelines.

To run through pipelines of code generation stages.

@h Ephemeral data.
This is temporary data meaningful only while a pipeline is running; it is
"cleaned", that is, reinitialised, at the start of each pipeline run.

=
typedef struct pipeline_ephemera {
	struct inter_tree *memory_repository;
	struct inter_tree *repositories[10];
} pipeline_ephemera;

void RunningPipelines::clean_pipeline(inter_pipeline *pl) {
	pl->ephemera.memory_repository = NULL;
	for (int i=0; i<10; i++) pl->ephemera.repositories[i] = NULL;
}

@ =
typedef struct pipeline_step_ephemera {
	struct filename *parsed_filename;
	struct linked_list *the_PP; /* of |pathname| */
	int to_debugging_log;
	int from_memory;
	struct text_stream *to_stream;
	struct linked_list *requirements_list; /* of |attachment_instruction| */
	struct inter_tree *repository;
	struct inter_pipeline *pipeline;
	struct target_vm *for_VM;
	struct inter_symbol *cached_symbols[MAX_RPSYM];
	struct inter_package *package_argument;
	int cached_symbols_fetched[MAX_RPSYM];
} pipeline_step_ephemera;

void RunningPipelines::clean_step(pipeline_step *step) {
	step->ephemera.parsed_filename = NULL;
	step->ephemera.to_stream = NULL;
	step->ephemera.to_debugging_log = FALSE;
	step->ephemera.from_memory = FALSE;
	step->ephemera.the_PP = NULL;
	step->ephemera.repository = NULL;
	step->ephemera.pipeline = NULL;
	step->ephemera.requirements_list = NEW_LINKED_LIST(attachment_instruction);
	step->ephemera.for_VM = NULL;
	step->ephemera.package_argument = NULL;
	for (int i=0; i<MAX_RPSYM; i++) {
		step->ephemera.cached_symbols_fetched[i] = FALSE;
		step->ephemera.cached_symbols[i] = NULL;
	}
}

@ This outer layer is all just instrumentation, really: we run through the
steps in turn, timing how long each one took us.

=
pipeline_step *currently_running_pipeline_step = NULL;

void RunningPipelines::run(pathname *P, inter_pipeline *S, inter_tree *I,
	linked_list *PP, linked_list *requirements_list, target_vm *VM) {
	if (S == NULL) return;
	if (I) S->ephemera.memory_repository = I;
	stopwatch_timer *within = NULL;
	#ifdef CORE_MODULE
	within = inform7_timer;
	#endif
	stopwatch_timer *pipeline_timer =
		Time::start_stopwatch(within, I"running Inter pipeline");
	int step_count = 0, step_total = LinkedLists::len(S->steps);
	int active = TRUE; inter_tree *last_linted = NULL;
	stopwatch_timer *prep_timer = NULL;
	pipeline_step *step;
	LOOP_OVER_LINKED_LIST(step, pipeline_step, S->steps)
		if (active)
			@<Run this step, timing and logging it@>;
	Time::stop_stopwatch(pipeline_timer);
}

@<Run this step, timing and logging it@> =
	currently_running_pipeline_step = step;
	if (prep_timer == NULL)
		prep_timer = Time::start_stopwatch(pipeline_timer, I"step preparation");
	else
		Time::resume_stopwatch(prep_timer);
	@<Prepare ephemeral data for this step@>;
	Time::stop_stopwatch(prep_timer);
	TEMPORARY_TEXT(STAGE_NAME)
	WRITE_TO(STAGE_NAME, "inter step %d/%d: ", ++step_count, step_total);
	ParsingPipelines::write_step(STAGE_NAME, step);
	Log::new_stage(STAGE_NAME);
	stopwatch_timer *step_timer =
		Time::start_stopwatch(pipeline_timer, STAGE_NAME);
	DISCARD_TEXT(STAGE_NAME)
	if (active) @<Run this step@>;
	Time::stop_stopwatch(step_timer);
	currently_running_pipeline_step = NULL;

@ Performing a full lint on each new tree of Inter code is a necessary
precaution even though it takes a little time: note that it verifies some
Inter constructs which might otherwise not have been verified. Still, we
avoid repeatedly linting the same tree, since that really would be slow.

@<Prepare ephemeral data for this step@> =
	RunningPipelines::clean_step(step);
	step->ephemera.the_PP = PP;
	if (S->ephemera.repositories[step->repository_argument] == NULL)
		S->ephemera.repositories[step->repository_argument] = InterTree::new();
	inter_tree *I = S->ephemera.repositories[step->repository_argument];
	if (I == NULL) {
		RunningPipelines::error(step, "no Inter tree to apply this step to");
		active = FALSE;
	} else {
		if (I != last_linted) { Inter::Defn::lint(I); last_linted = I; }
	}
	step->ephemera.repository = I;
	step->ephemera.pipeline = S;
	step->ephemera.requirements_list = requirements_list;
	step->ephemera.for_VM = VM;
	if ((VM) && (step->take_generator_argument_from_VM)) {
		step->generator_argument = Generators::find_for(VM);
		if (step->generator_argument == NULL) {
			RunningPipelines::error(step, "unable to guess a suitable code-generator");
			active = FALSE;
		}
	}
	step->ephemera.package_argument = NULL;
	if (Str::len(step->package_URL_argument) > 0) {
		step->ephemera.package_argument =
			Inter::Packages::by_url(step->ephemera.repository, step->package_URL_argument);
		if (step->ephemera.package_argument == NULL) {
			RunningPipelines::error_with(step,
				"pipeline step applied to package which does not exist: '%S'",
				step->package_URL_argument);
			active = FALSE;
		}
	}
	
@<Run this step@> =
	if (ParsingPipelines::will_write_a_file(step)) {
		if (Str::len(step->step_argument) == 0) {
			if (step->step_stage->stage_arg != OPTIONAL_TEXT_OUT_STAGE_ARG) {
				RunningPipelines::error(step, "no filename given in pipeline step");
				active = FALSE;
			}
		} else {
			if (Str::eq(step->step_argument, I"*log")) {
				step->ephemera.to_stream = DL;
				@<Call the stage execution function@>;
			} else {
				@<Work out the filename@>;
				text_stream text_output_struct;
				text_stream *T = &text_output_struct;
				if (STREAM_OPEN_TO_FILE(T, step->ephemera.parsed_filename, ISO_ENC) == FALSE) {
					RunningPipelines::error(step, "unable to open file named in pipeline step");
					active = FALSE;
				} else {
					step->ephemera.to_stream = T;
					@<Call the stage execution function@>;
					STREAM_CLOSE(T);
				}
			}
		}
	} else if (ParsingPipelines::will_read_a_file(step)) {
		if (Str::len(step->step_argument) == 0) {
			RunningPipelines::error(step, "no filename given in pipeline step");
			active = FALSE;
		} else if (Str::eq(step->step_argument, I"*memory")) {
			if (Str::eq(step->step_stage->stage_name, I"read") == FALSE) {
				RunningPipelines::error(step, "'*memory' can be used only on reads");
				active = FALSE;
			} else {
				S->ephemera.repositories[step->repository_argument] =
					S->ephemera.memory_repository;
				/* and do not call the executor function: that does the read */
			}
		} else {
			@<Work out the filename@>;
			@<Call the stage execution function@>;
		}
	} else {
		@<Call the stage execution function@>;
	}

@<Work out the filename@> =
	int contains_slash = FALSE;
	LOOP_THROUGH_TEXT(pos, step->step_argument)
		if (Str::get(pos) == '/')
			contains_slash = TRUE;
	if (contains_slash) step->ephemera.parsed_filename =
		Filenames::from_text(step->step_argument);
	else step->ephemera.parsed_filename =
		Filenames::in(P, step->step_argument);

@ The pipeline stops running (becomes inactive) as soon as one of the stage
functions returns |FALSE|, or as soon as a pipeline processing error occurs, 
whichever comes first.

@<Call the stage execution function@> =
	active = (*(step->step_stage->execute))(step);

@ In an ideal world, we would not track this in a global variable, but it is
not simple to remove the need for this (though, at the same time, it is needed
very little in practice, and never when this code runs in Inform 7).

=
pipeline_step *RunningPipelines::current_step(void) {
	return currently_running_pipeline_step;
}

@h Popular symbols cache.
While working on a repository, the execution functions will frequently need
its most popular symbols -- searching for these is not too slow, but even so,
once is enough. But we cache them on each step, wiping the cache at the end
of the step, since running a step changes the Inter tree and could conceivably
move, add or remove some of these symbols.

=
@e unchecked_kind_RPSYM from 0
@e unchecked_function_RPSYM
@e list_of_unchecked_kind_RPSYM
@e object_kind_RPSYM
@e action_kind_RPSYM
@e truth_state_kind_RPSYM
@e direction_kind_RPSYM

@e verb_directive_reverse_RPSYM
@e verb_directive_slash_RPSYM
@e verb_directive_divider_RPSYM
@e verb_directive_result_RPSYM
@e verb_directive_special_RPSYM
@e verb_directive_number_RPSYM
@e verb_directive_noun_RPSYM
@e verb_directive_multi_RPSYM
@e verb_directive_multiinside_RPSYM
@e verb_directive_multiheld_RPSYM
@e verb_directive_held_RPSYM
@e verb_directive_creature_RPSYM
@e verb_directive_topic_RPSYM
@e verb_directive_multiexcept_RPSYM

@e code_ptype_RPSYM
@e plain_ptype_RPSYM
@e submodule_ptype_RPSYM
@e function_ptype_RPSYM
@e action_ptype_RPSYM
@e command_ptype_RPSYM
@e property_ptype_RPSYM
@e to_phrase_ptype_RPSYM

@d MAX_RPSYM 100

=
inter_symbol *RunningPipelines::get_symbol(pipeline_step *step, int id) {
	if ((id < 0) || (id >= MAX_RPSYM)) internal_error("bad ID");
	if (step == NULL) internal_error("no step");
	inter_tree *I = step->ephemera.repository;
	if (step->ephemera.cached_symbols_fetched[id] == FALSE) {
		step->ephemera.cached_symbols_fetched[id] = TRUE;
		switch (id) {
			case code_ptype_RPSYM:
				step->ephemera.cached_symbols[code_ptype_RPSYM] =
				InterSymbolsTables::url_name_to_symbol(I, NULL, I"/_code"); break;
			case plain_ptype_RPSYM:
				step->ephemera.cached_symbols[plain_ptype_RPSYM] =
				InterSymbolsTables::url_name_to_symbol(I, NULL, I"/_plain"); break;
			case submodule_ptype_RPSYM:
				step->ephemera.cached_symbols[submodule_ptype_RPSYM] =
				InterSymbolsTables::url_name_to_symbol(I, NULL, I"/_submodule"); break;
			case function_ptype_RPSYM:
				step->ephemera.cached_symbols[function_ptype_RPSYM] =
				InterSymbolsTables::url_name_to_symbol(I, NULL, I"/_function"); break;
			case action_ptype_RPSYM:
				step->ephemera.cached_symbols[action_ptype_RPSYM] =
				InterSymbolsTables::url_name_to_symbol(I, NULL, I"/_action"); break;
			case command_ptype_RPSYM:
				step->ephemera.cached_symbols[command_ptype_RPSYM] =
				InterSymbolsTables::url_name_to_symbol(I, NULL, I"/_command"); break;
			case property_ptype_RPSYM:
				step->ephemera.cached_symbols[property_ptype_RPSYM] =
				InterSymbolsTables::url_name_to_symbol(I, NULL, I"/_property"); break;
			case to_phrase_ptype_RPSYM:
				step->ephemera.cached_symbols[to_phrase_ptype_RPSYM] =
				InterSymbolsTables::url_name_to_symbol(I, NULL, I"/_to_phrase"); break;

			case unchecked_kind_RPSYM:
				step->ephemera.cached_symbols[unchecked_kind_RPSYM] =
				Inter::Packages::search_resources(I, I"K_unchecked"); break;
			case unchecked_function_RPSYM:
				step->ephemera.cached_symbols[unchecked_function_RPSYM] =
				Inter::Packages::search_resources(I, I"K_unchecked_function"); break;
			case list_of_unchecked_kind_RPSYM:
				step->ephemera.cached_symbols[list_of_unchecked_kind_RPSYM] =
				Inter::Packages::search_resources(I, I"K_list_of_values"); break;
			case object_kind_RPSYM:
				step->ephemera.cached_symbols[object_kind_RPSYM] =
				Inter::Packages::search_resources(I, I"K_object"); break;
			case action_kind_RPSYM:
				step->ephemera.cached_symbols[action_kind_RPSYM] =
				Inter::Packages::search_resources(I, I"K_action_name"); break;
			case truth_state_kind_RPSYM:
				step->ephemera.cached_symbols[truth_state_kind_RPSYM] =
				Inter::Packages::search_resources(I, I"K_truth_state"); break;
			case direction_kind_RPSYM:
				step->ephemera.cached_symbols[direction_kind_RPSYM] =
				Inter::Packages::search_resources(I, I"K3_direction"); break;

			case verb_directive_reverse_RPSYM:
				step->ephemera.cached_symbols[verb_directive_reverse_RPSYM] =
				Inter::Packages::search_resources(I, I"VERB_DIRECTIVE_REVERSE"); break;
			case verb_directive_slash_RPSYM:
				step->ephemera.cached_symbols[verb_directive_slash_RPSYM] =
				Inter::Packages::search_resources(I, I"VERB_DIRECTIVE_SLASH"); break;
			case verb_directive_divider_RPSYM:
				step->ephemera.cached_symbols[verb_directive_divider_RPSYM] =
				Inter::Packages::search_resources(I, I"VERB_DIRECTIVE_DIVIDER"); break;
			case verb_directive_result_RPSYM:
				step->ephemera.cached_symbols[verb_directive_result_RPSYM] =
				Inter::Packages::search_resources(I, I"VERB_DIRECTIVE_RESULT"); break;
			case verb_directive_special_RPSYM:
				step->ephemera.cached_symbols[verb_directive_special_RPSYM] =
				Inter::Packages::search_resources(I, I"VERB_DIRECTIVE_SPECIAL"); break;
			case verb_directive_number_RPSYM:
				step->ephemera.cached_symbols[verb_directive_number_RPSYM] =
				Inter::Packages::search_resources(I, I"VERB_DIRECTIVE_NUMBER"); break;
			case verb_directive_noun_RPSYM:
				step->ephemera.cached_symbols[verb_directive_noun_RPSYM] =
				Inter::Packages::search_resources(I, I"VERB_DIRECTIVE_NOUN"); break;
			case verb_directive_multi_RPSYM:
				step->ephemera.cached_symbols[verb_directive_multi_RPSYM] =
				Inter::Packages::search_resources(I, I"VERB_DIRECTIVE_MULTI"); break;
			case verb_directive_multiinside_RPSYM:
				step->ephemera.cached_symbols[verb_directive_multiinside_RPSYM] =
				Inter::Packages::search_resources(I, I"VERB_DIRECTIVE_MULTIINSIDE"); break;
			case verb_directive_multiheld_RPSYM:
				step->ephemera.cached_symbols[verb_directive_multiheld_RPSYM] =
				Inter::Packages::search_resources(I, I"VERB_DIRECTIVE_MULTIHELD"); break;
			case verb_directive_held_RPSYM:
				step->ephemera.cached_symbols[verb_directive_held_RPSYM] =
				Inter::Packages::search_resources(I, I"VERB_DIRECTIVE_HELD"); break;
			case verb_directive_creature_RPSYM:
				step->ephemera.cached_symbols[verb_directive_creature_RPSYM] =
				Inter::Packages::search_resources(I, I"VERB_DIRECTIVE_CREATURE"); break;
			case verb_directive_topic_RPSYM:
				step->ephemera.cached_symbols[verb_directive_topic_RPSYM] =
				Inter::Packages::search_resources(I, I"VERB_DIRECTIVE_TOPIC"); break;
			case verb_directive_multiexcept_RPSYM:
				step->ephemera.cached_symbols[verb_directive_multiexcept_RPSYM] =
				Inter::Packages::search_resources(I, I"VERB_DIRECTIVE_MULTIEXCEPT"); break;
		}
	}
	return step->ephemera.cached_symbols[id];
}

@ This variant is more interesting: it tries to find the symbol in the tree,
but if it can't, it makes one and creates a plug for it, expecting the true
definition (and thus a socket) to come later from some other material not yet
linked in.

=
void RunningPipelines::ensure(pipeline_step *step, int id, text_stream *identifier) {
	inter_tree *I = step->ephemera.repository;
	if (RunningPipelines::get_symbol(step, id) == NULL)
		step->ephemera.cached_symbols[id] = Inter::Connectors::plug(I, identifier);
}

@h Error handling.
The moment there is something wrong with the pipeline itself, we come to a
complete halt. It's the kindest way.

=
void RunningPipelines::error(pipeline_step *step, char *erm) {
	#ifdef CORE_MODULE
	@<Begin problem message using the module of the same name@>;
	TEMPORARY_TEXT(full)
	WRITE_TO(full, "%s", erm);
	Problems::quote_stream(1, full);
	DISCARD_TEXT(full)
	@<End problem message using the module of the same name@>;
	#endif
	#ifndef CORE_MODULE
	Errors::fatal(erm);
	exit(1);
	#endif
}

void RunningPipelines::error_with(pipeline_step *step, char *erm, text_stream *quoted) {
	#ifdef CORE_MODULE
	@<Begin problem message using the module of the same name@>;
	TEMPORARY_TEXT(full)
	WRITE_TO(full, erm, quoted);
	Problems::quote_stream(1, full);
	@<End problem message using the module of the same name@>;
	DISCARD_TEXT(full)
	#endif
	#ifndef CORE_MODULE
	Errors::fatal_with_text(erm, quoted);
	exit(1);
	#endif
}

@<Begin problem message using the module of the same name@> =
	do_not_locate_problems = TRUE;
	Problems::issue_problem_begin(NULL, erm);
	Problems::issue_problem_segment(
		"Something went wrong late in compilation, when working through the "
		"'pipeline' of code-generation steps. (This should not normally happen "
		"unless your source text is making use of '(-' and '-)' and getting "
		"that wrong, or unless you are experimenting with non-standard pipelines.) "
		"The pipeline looks like so:");
	Problems::issue_problem_end();

@<End problem message using the module of the same name@> =
	if (step) {
		inter_pipeline *pipeline = step->pipeline;
		pipeline_step *some_step;
		int N = 1;
		LOOP_OVER_LINKED_LIST(some_step, pipeline_step, pipeline->steps) {
			TEMPORARY_TEXT(description)
			ParsingPipelines::write_step(description, some_step);
			Problems::issue_problem_begin(Task::syntax_tree(), "****");
			Problems::quote_number(1, &N);
			if (some_step == step) {
				Problems::quote_stream_tinted_red(2, description);
				Problems::issue_problem_segment("%1. %2");
			} else {
				Problems::quote_stream_tinted_green(2, description);
				Problems::issue_problem_segment("%1. %2");
			}
			DISCARD_TEXT(description)
			Problems::issue_problem_end();
			if (some_step == step) {
				Problems::issue_problem_begin(Task::syntax_tree(), "****");
				Problems::quote_stream(1, full);
				Problems::issue_problem_segment("Problem: %1");
				Problems::issue_problem_end();
			}
			N++;
		}
	}
	do_not_locate_problems = FALSE;
