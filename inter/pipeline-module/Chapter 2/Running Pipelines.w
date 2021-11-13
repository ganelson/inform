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
	struct linked_list *requirements_list; /* of |inter_library| */
	struct inter_tree *repository;
	struct inter_pipeline *pipeline;
	struct target_vm *for_VM;
} pipeline_step_ephemera;

void RunningPipelines::clean_step(pipeline_step *step) {
	step->ephemera.parsed_filename = NULL;
	step->ephemera.to_stream = NULL;
	step->ephemera.to_debugging_log = FALSE;
	step->ephemera.from_memory = FALSE;
	step->ephemera.the_PP = NULL;
	step->ephemera.repository = NULL;
	step->ephemera.pipeline = NULL;
	step->ephemera.requirements_list = NEW_LINKED_LIST(inter_library);
	step->ephemera.for_VM = NULL;
}

@ This outer layer is all just instrumentation, really: we run through the
steps in turn, timing how long each one took us.

=
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
	int active = TRUE;
	stopwatch_timer *prep_timer = NULL;
	pipeline_step *step;
	LOOP_OVER_LINKED_LIST(step, pipeline_step, S->steps)
		if (active) {
			if (prep_timer == NULL)
				prep_timer = Time::start_stopwatch(pipeline_timer, I"step preparation");
			else
				Time::resume_stopwatch(prep_timer);
			@<Prepare this step@>;
			Time::stop_stopwatch(prep_timer);
			TEMPORARY_TEXT(STAGE_NAME)
			WRITE_TO(STAGE_NAME, "inter step %d/%d: ", ++step_count, step_total);
			ParsingPipelines::write_step(STAGE_NAME, step);
			Log::new_stage(STAGE_NAME);
			stopwatch_timer *step_timer =
				Time::start_stopwatch(pipeline_timer, STAGE_NAME);
			DISCARD_TEXT(STAGE_NAME)
			@<Run this step@>;
			Time::stop_stopwatch(step_timer);
		}
	Time::stop_stopwatch(pipeline_timer);
}

@<Prepare this step@> =
	if (S->ephemera.repositories[step->repository_argument] == NULL)
		S->ephemera.repositories[step->repository_argument] = InterTree::new();
	inter_tree *I = S->ephemera.repositories[step->repository_argument];
	if (I == NULL) internal_error("no repository");
	RunningPipelines::prepare_to_run(I);
	RunningPipelines::lint(I);

	RunningPipelines::clean_step(step);
	step->ephemera.the_PP = PP;
	step->ephemera.repository = I;
	step->ephemera.pipeline = S;
	step->ephemera.requirements_list = requirements_list;
	step->ephemera.for_VM = VM;
	if ((VM) && (step->take_generator_argument_from_VM)) {
		step->generator_argument = Generators::find_for(VM);
		if (step->generator_argument == NULL) {
			#ifdef PROBLEMS_MODULE
			Problems::fatal("Unable to guess target format");
			#endif
			#ifndef PROBLEMS_MODULE
			Errors::fatal("Unable to guess target format");
			exit(1);
			#endif
		}
	}
	
	step->package_argument = NULL;
	if (Str::len(step->package_URL_argument) > 0) {
		step->package_argument =
			Inter::Packages::by_url(step->ephemera.repository, step->package_URL_argument);
		if (step->package_argument == NULL) {
			RunningPipelines::error_with("no such package as '%S'", step->package_URL_argument);
			continue;
		}
	}
	
@<Run this step@> =
	int skip_step = FALSE;

	if ((step->step_stage->stage_arg == FILE_STAGE_ARG) ||
		(step->step_stage->stage_arg == TEXT_OUT_STAGE_ARG) ||
		(step->step_stage->stage_arg == OPTIONAL_TEXT_OUT_STAGE_ARG) ||
		(step->step_stage->stage_arg == EXT_FILE_STAGE_ARG) ||
		(step->step_stage->stage_arg == EXT_TEXT_OUT_STAGE_ARG)) {
		if (Str::len(step->step_argument) == 0) {
			if (step->step_stage->stage_arg == OPTIONAL_TEXT_OUT_STAGE_ARG) {
				skip_step = TRUE;
			} else {
				#ifdef PROBLEMS_MODULE
				Problems::fatal("No filename given in pipeline step");
				#endif
				#ifndef PROBLEMS_MODULE
				Errors::fatal("No filename given in pipeline step");
				exit(1);
				#endif
			}
		} else {
			if (Str::eq(step->step_argument, I"*log")) {
				step->ephemera.to_debugging_log = TRUE;
			} else if (Str::eq(step->step_argument, I"*memory")) {
				S->ephemera.repositories[step->repository_argument] = S->ephemera.memory_repository;
				skip_step = TRUE;
			} else {
				int slashes = FALSE;
				LOOP_THROUGH_TEXT(pos, step->step_argument)
					if (Str::get(pos) == '/')
						slashes = TRUE;
				if (slashes) step->ephemera.parsed_filename = Filenames::from_text(step->step_argument);
				else step->ephemera.parsed_filename = Filenames::in(P, step->step_argument);
			}
		}
	}

	text_stream text_output_struct; /* For any text file we might write */
	text_stream *T = &text_output_struct;
	if (step->ephemera.to_debugging_log) {
		step->ephemera.to_stream = DL;
	} else if ((step->step_stage->stage_arg == TEXT_OUT_STAGE_ARG) ||
		(step->step_stage->stage_arg == OPTIONAL_TEXT_OUT_STAGE_ARG) ||
		(step->step_stage->stage_arg == EXT_TEXT_OUT_STAGE_ARG)) {
		if ((step->ephemera.parsed_filename) &&
			(STREAM_OPEN_TO_FILE(T, step->ephemera.parsed_filename, ISO_ENC) == FALSE)) {
			#ifdef PROBLEMS_MODULE
			Problems::fatal_on_file("Can't open output file", step->ephemera.parsed_filename);
			#endif
			#ifndef PROBLEMS_MODULE
			Errors::fatal_with_file("Can't open output file", step->ephemera.parsed_filename);
			exit(1);
			#endif
		}
		step->ephemera.to_stream = T;
	}

	if (skip_step == FALSE)
		active = (*(step->step_stage->execute))(step);

	if (((step->step_stage->stage_arg == TEXT_OUT_STAGE_ARG) ||
		(step->step_stage->stage_arg == EXT_TEXT_OUT_STAGE_ARG)) &&
		(step->ephemera.to_debugging_log == FALSE)) {
		STREAM_CLOSE(T);
	}

@h Following.

=
inter_symbol *unchecked_kind_symbol = NULL;
inter_symbol *unchecked_function_symbol = NULL;
inter_symbol *typeless_int_symbol = NULL;
inter_symbol *list_of_unchecked_kind_symbol = NULL;
inter_symbol *object_kind_symbol = NULL;
inter_symbol *action_kind_symbol = NULL;
inter_symbol *truth_state_kind_symbol = NULL;
inter_symbol *direction_kind_symbol = NULL;

inter_symbol *verb_directive_reverse_symbol = NULL;
inter_symbol *verb_directive_slash_symbol = NULL;
inter_symbol *verb_directive_divider_symbol = NULL;
inter_symbol *verb_directive_result_symbol = NULL;
inter_symbol *verb_directive_special_symbol = NULL;
inter_symbol *verb_directive_number_symbol = NULL;
inter_symbol *verb_directive_noun_symbol = NULL;
inter_symbol *verb_directive_multi_symbol = NULL;
inter_symbol *verb_directive_multiinside_symbol = NULL;
inter_symbol *verb_directive_multiheld_symbol = NULL;
inter_symbol *verb_directive_held_symbol = NULL;
inter_symbol *verb_directive_creature_symbol = NULL;
inter_symbol *verb_directive_topic_symbol = NULL;
inter_symbol *verb_directive_multiexcept_symbol = NULL;

inter_symbol *code_ptype_symbol = NULL;
inter_symbol *plain_ptype_symbol = NULL;
inter_symbol *submodule_ptype_symbol = NULL;
inter_symbol *function_ptype_symbol = NULL;
inter_symbol *action_ptype_symbol = NULL;
inter_symbol *command_ptype_symbol = NULL;
inter_symbol *property_ptype_symbol = NULL;
inter_symbol *to_phrase_ptype_symbol = NULL;

void RunningPipelines::prepare_to_run(inter_tree *I) {

	code_ptype_symbol = InterSymbolsTables::url_name_to_symbol(I, NULL, I"/_code");
	plain_ptype_symbol = InterSymbolsTables::url_name_to_symbol(I, NULL, I"/_plain");
	submodule_ptype_symbol = InterSymbolsTables::url_name_to_symbol(I, NULL, I"/_submodule");
	function_ptype_symbol = InterSymbolsTables::url_name_to_symbol(I, NULL, I"/_function");
	action_ptype_symbol = InterSymbolsTables::url_name_to_symbol(I, NULL, I"/_action");
	command_ptype_symbol = InterSymbolsTables::url_name_to_symbol(I, NULL, I"/_command");
	property_ptype_symbol = InterSymbolsTables::url_name_to_symbol(I, NULL, I"/_property");
	to_phrase_ptype_symbol = InterSymbolsTables::url_name_to_symbol(I, NULL, I"/_to_phrase");

	unchecked_kind_symbol = Inter::Packages::search_resources_exhaustively(I, I"K_unchecked");
	unchecked_function_symbol = Inter::Packages::search_resources_exhaustively(I, I"K_unchecked_function");
	typeless_int_symbol = Inter::Packages::search_resources_exhaustively(I, I"K_typeless_int");
	list_of_unchecked_kind_symbol = Inter::Packages::search_resources_exhaustively(I, I"K_list_of_values");
	object_kind_symbol = Inter::Packages::search_resources_exhaustively(I, I"K_object");
	action_kind_symbol = Inter::Packages::search_resources_exhaustively(I, I"K_action_name");
	truth_state_kind_symbol = Inter::Packages::search_resources_exhaustively(I, I"K_truth_state");
	direction_kind_symbol = Inter::Packages::search_resources_exhaustively(I, I"K3_direction");

	verb_directive_reverse_symbol = Inter::Packages::search_resources_exhaustively(I, I"VERB_DIRECTIVE_REVERSE");
	verb_directive_slash_symbol = Inter::Packages::search_resources_exhaustively(I, I"VERB_DIRECTIVE_SLASH");
	verb_directive_divider_symbol = Inter::Packages::search_resources_exhaustively(I, I"VERB_DIRECTIVE_DIVIDER");
	verb_directive_result_symbol = Inter::Packages::search_resources_exhaustively(I, I"VERB_DIRECTIVE_RESULT");
	verb_directive_special_symbol = Inter::Packages::search_resources_exhaustively(I, I"VERB_DIRECTIVE_SPECIAL");
	verb_directive_number_symbol = Inter::Packages::search_resources_exhaustively(I, I"VERB_DIRECTIVE_NUMBER");
	verb_directive_noun_symbol = Inter::Packages::search_resources_exhaustively(I, I"VERB_DIRECTIVE_NOUN");
	verb_directive_multi_symbol = Inter::Packages::search_resources_exhaustively(I, I"VERB_DIRECTIVE_MULTI");
	verb_directive_multiinside_symbol = Inter::Packages::search_resources_exhaustively(I, I"VERB_DIRECTIVE_MULTIINSIDE");
	verb_directive_multiheld_symbol = Inter::Packages::search_resources_exhaustively(I, I"VERB_DIRECTIVE_MULTIHELD");
	verb_directive_held_symbol = Inter::Packages::search_resources_exhaustively(I, I"VERB_DIRECTIVE_HELD");
	verb_directive_creature_symbol = Inter::Packages::search_resources_exhaustively(I, I"VERB_DIRECTIVE_CREATURE");
	verb_directive_topic_symbol = Inter::Packages::search_resources_exhaustively(I, I"VERB_DIRECTIVE_TOPIC");
	verb_directive_multiexcept_symbol = Inter::Packages::search_resources_exhaustively(I, I"VERB_DIRECTIVE_MULTIEXCEPT");
}

void RunningPipelines::lint(inter_tree *I) {
	InterTree::traverse(I, RunningPipelines::lint_visitor, NULL, NULL, -PACKAGE_IST);
}

void RunningPipelines::lint_visitor(inter_tree *I, inter_tree_node *P, void *state) {
	inter_ti c = Inode::get_package(P)->index_n;
	inter_ti a = Inode::get_package_alt(P);
	if (c != a) {
		LOG("Frame gives package as $6, but its location is in package $6\n",
			Inode::ID_to_package(P, c),
			Inode::ID_to_package(P, a));
		WRITE_TO(STDERR, "Frame gives package as %d, but its location is in package %d\n",
			Inode::ID_to_package(P, c)->index_n,
			Inode::ID_to_package(P, a)->index_n);
		internal_error("misplaced package");
	}

	Produce::guard(Inter::Defn::verify_children_inner(P));
}

inter_symbol *RunningPipelines::uks(void) {
	if (unchecked_kind_symbol == NULL) internal_error("no unchecked kind symbol");
	return unchecked_kind_symbol;
}

void RunningPipelines::error(char *erm) {
	#ifdef PROBLEMS_MODULE
	TEMPORARY_TEXT(full)
	WRITE_TO(full, "%s", erm);
	do_not_locate_problems = TRUE;
	Problems::quote_stream(1, full);
	Problems::issue_problem_begin(NULL, erm);
	Problems::issue_problem_segment("I was unable to perform final code-generation: %1");
	Problems::issue_problem_end();
	do_not_locate_problems = FALSE;
	DISCARD_TEXT(full)
	#endif
	#ifndef PROBLEMS_MODULE
	Errors::fatal(erm);
	exit(1);
	#endif
}

void RunningPipelines::error_with(char *erm, text_stream *quoted) {
	#ifdef PROBLEMS_MODULE
	TEMPORARY_TEXT(full)
	WRITE_TO(full, erm, quoted);
	do_not_locate_problems = TRUE;
	Problems::quote_stream(1, full);
	Problems::issue_problem_begin(NULL, erm);
	Problems::issue_problem_segment("I was unable to perform final code-generation: %1");
	Problems::issue_problem_end();
	do_not_locate_problems = FALSE;
	DISCARD_TEXT(full)
	#endif
	#ifndef PROBLEMS_MODULE
	Errors::fatal_with_text(erm, quoted);
	exit(1);
	#endif
}

@h Current architecture.

=
inter_architecture *current_architecture = NULL;
int RunningPipelines::set_architecture(text_stream *name) {
	current_architecture = Architectures::from_codename(name);
	if (current_architecture) return TRUE;
	return FALSE;
}

inter_architecture *RunningPipelines::get_architecture(void) {
	return current_architecture;
}
