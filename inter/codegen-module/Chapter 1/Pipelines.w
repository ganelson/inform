[CodeGen::Pipeline::] Pipelines.

To build and run through pipelines of code generation stages.

@h Steps.
A "step" is a single step in a pipeline of commands: it consists of a
choice of stage, together with a choice of argument. The other elements here
are all temporary storage for information needed when the step is run; they
have no meaningful contents when the step is not running.

=
typedef struct pipeline_step {
	struct pipeline_stage *step_stage;
	struct text_stream *step_argument;
	struct code_generation_target *target_argument;
	struct text_stream *package_argument;
	struct filename *parsed_filename;
	struct pathname **the_PP;
	int the_N;
	int to_debugging_log;
	int from_memory;
	int repository_argument;
	struct text_stream *text_out_file;
	struct inter_repository *repository;
	MEMORY_MANAGEMENT
} pipeline_step;

pipeline_step *CodeGen::Pipeline::new_step(void) {
	pipeline_step *step = CREATE(pipeline_step);
	step->step_stage = NULL;
	step->step_argument = NULL;
	step->package_argument = NULL;
	step->repository_argument = -1;
	CodeGen::Pipeline::clean_step(step);
	return step;
}

@ This wipes clean the temporary storage for a step.

=
void CodeGen::Pipeline::clean_step(pipeline_step *step) {
	step->parsed_filename = NULL;
	step->text_out_file = NULL;
	step->the_N = -1;
	step->to_debugging_log = FALSE;
	step->from_memory = FALSE;
	step->the_PP = NULL;
	step->repository = NULL;
}

@ Here we write a textual description to a string, which is useful for
logging:

=
void CodeGen::Pipeline::write_step(OUTPUT_STREAM, pipeline_step *step) {
	WRITE("%S", step->step_stage->stage_name);
	if (step->step_stage->stage_arg != NO_STAGE_ARG) {
		if (step->package_argument) WRITE(" %S", step->package_argument);
		WRITE(":");
		if (step->repository_argument >= 0) WRITE(" %d <-", step->repository_argument);
		if (step->target_argument) WRITE(" %S ->", step->target_argument->target_name);
		WRITE(" %S", step->step_argument);
	}
}

pipeline_step *CodeGen::Pipeline::read_step(text_stream *step, dictionary *D) {
	CodeGen::Stage::make_stages();
	CodeGen::Targets::make_targets();
	pipeline_step *ST = CodeGen::Pipeline::new_step();
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, step, L"(%c+?) *: *(%d) *<- *(%c*)")) {
		ST->repository_argument = Str::atoi(mr.exp[1], 0);
		ST->step_argument = CodeGen::Pipeline::read_parameter(mr.exp[2], D);
		Str::copy(step, mr.exp[0]);
	} else if (Regexp::match(&mr, step, L"(%c+?) *: *(%C*) *-> *(%c*)")) {
		code_generation_target *cgt;
		LOOP_OVER(cgt, code_generation_target)
			if (Str::eq(mr.exp[1], cgt->target_name))
				ST->target_argument = cgt;
		if (ST->target_argument == NULL) {
			WRITE_TO(STDERR, "No such code generation target as '%S'\n", mr.exp[1]);
			internal_error("no such target");
		}
		ST->step_argument = CodeGen::Pipeline::read_parameter(mr.exp[2], D);
		Str::copy(step, mr.exp[0]);
	} else if (Regexp::match(&mr, step, L"(%c+?) *: *(%c*)")) {
		ST->step_argument = CodeGen::Pipeline::read_parameter(mr.exp[1], D);
		Str::copy(step, mr.exp[0]);
	}
	if (Regexp::match(&mr, step, L"(%C+?) (%c+)")) {
		ST->package_argument = CodeGen::Pipeline::read_parameter(mr.exp[1], D);
		Str::copy(step, mr.exp[0]);
	}

	pipeline_stage *stage;
	LOOP_OVER(stage, pipeline_stage)
		if (Str::eq(step, stage->stage_name))
			ST->step_stage = stage;
	if (ST->step_stage == NULL) {
		WRITE_TO(STDERR, "No such step as '%S'\n", step);
		internal_error("no such step code");
	}
	Regexp::dispose_of(&mr);
	return ST;
}

text_stream *CodeGen::Pipeline::read_parameter(text_stream *from, dictionary *D) {
	if (Str::get_first_char(from) == '*') {
		text_stream *find = Dictionaries::get_text(D, from);
		if (find) return Str::duplicate(find);
		WRITE_TO(STDERR, "No such pipeline variable as '%S'\n", from);
		internal_error("no such pipeline variable");		
	}
	return Str::duplicate(from);
}

@h Pipelines.
And then a pipeline is just a linked list of steps.

=
typedef struct codegen_pipeline {
	struct dictionary *variables;
	struct inter_repository *memory_repository;
	struct inter_repository *repositories[10];
	struct linked_list *steps; /* of |pipeline_step| */
	MEMORY_MANAGEMENT
} codegen_pipeline;

dictionary *CodeGen::Pipeline::basic_dictionary(text_stream *leafname) {
	dictionary *D = Dictionaries::new(16, TRUE);
	if (Str::len(leafname) > 0) Str::copy(Dictionaries::create_text(D, I"*out"), leafname);
	Str::copy(Dictionaries::create_text(D, I"*log"), I"*log");
	return D;
}

codegen_pipeline *CodeGen::Pipeline::new(dictionary *D) {
	codegen_pipeline *S = CREATE(codegen_pipeline);
	S->variables = D;
	S->steps = NEW_LINKED_LIST(pipeline_step);
	S->memory_repository = NULL;
	for (int i=0; i<10; i++) S->repositories[i] = NULL;
	return S;
}

codegen_pipeline *CodeGen::Pipeline::parse_from_file(filename *F, dictionary *D) {
	TEMPORARY_TEXT(A);
	TextFiles::read(F, FALSE, "can't open inter pipeline file",
		TRUE, CodeGen::Pipeline::scan_line, NULL, (void *) A);
	codegen_pipeline *S = CodeGen::Pipeline::new(D);
	CodeGen::Pipeline::parse_into(S, A);
	DISCARD_TEXT(A);
	return S;
}

void CodeGen::Pipeline::scan_line(text_stream *line, text_file_position *tfp, void *X) {
	text_stream *A = (text_stream *) X;
	if (Str::len(A) > 0) WRITE_TO(A, ", ");
	WRITE_TO(A, "%S", line);
}

codegen_pipeline *CodeGen::Pipeline::parse(text_stream *instructions, dictionary *D) {
	codegen_pipeline *S = CodeGen::Pipeline::new(D);
	CodeGen::Pipeline::parse_into(S, instructions);
	return S;
}

void CodeGen::Pipeline::parse_into(codegen_pipeline *S, text_stream *instructions) {
	TEMPORARY_TEXT(T);
	LOOP_THROUGH_TEXT(P, instructions)
		if (Characters::is_babel_whitespace(Str::get(P)))
			PUT_TO(T, ' ');
		else
			PUT_TO(T, Str::get(P));
	match_results mr = Regexp::create_mr();
	while (Regexp::match(&mr, T, L" *(%c+?) *,+ *(%c*?) *")) {
		pipeline_step *ST = CodeGen::Pipeline::read_step(mr.exp[0], S->variables);
		if (ST) ADD_TO_LINKED_LIST(ST, pipeline_step, S->steps);
		Str::copy(T, mr.exp[1]);
	}
	if (Regexp::match(&mr, T, L" *(%c+?) *")) {
		pipeline_step *ST = CodeGen::Pipeline::read_step(mr.exp[0], S->variables);
		if (ST) ADD_TO_LINKED_LIST(ST, pipeline_step, S->steps);
	}
}

void CodeGen::Pipeline::set_repository(codegen_pipeline *S, inter_repository *I) {
	S->memory_repository = I;
}

void CodeGen::Pipeline::run(pathname *P, codegen_pipeline *S, int N, pathname **PP) {
	if (S == NULL) return;
	if (S->repositories[0] == NULL) S->repositories[0] = Inter::create(1, 32);
	clock_t start = clock();

	int step_count = 0, step_total = 0;
	pipeline_step *step;
	LOOP_OVER_LINKED_LIST(step, pipeline_step, S->steps) step_total++;

	int active = TRUE, current_repo = 0;
	CodeGen::Pipeline::prepare_to_run(S->repositories[current_repo]);
	LOOP_OVER_LINKED_LIST(step, pipeline_step, S->steps)
		if (active) {
			inter_repository *I = S->repositories[current_repo];
			CodeGen::Pipeline::lint(I);
		
			CodeGen::Pipeline::clean_step(step);
			step->the_N = N;
			step->the_PP = PP;
			step->repository = I;

			TEMPORARY_TEXT(STAGE_NAME);
			WRITE_TO(STAGE_NAME, "inter step %d/%d (at %dcs): ", ++step_count, step_total,
				((int) (clock() - start)) / (CLOCKS_PER_SEC/100));
			CodeGen::Pipeline::write_step(STAGE_NAME, step);
			Log::new_stage(STAGE_NAME);
			DISCARD_TEXT(STAGE_NAME);

			if ((step->step_stage->stage_arg == FILE_STAGE_ARG) ||
				(step->step_stage->stage_arg == TEXT_OUT_STAGE_ARG) ||
				(step->step_stage->stage_arg == EXT_FILE_STAGE_ARG) ||
				(step->step_stage->stage_arg == EXT_TEXT_OUT_STAGE_ARG)) {
				if (Str::eq(step->step_argument, I"*log")) {
					step->to_debugging_log = TRUE;
				} else if (Str::eq(step->step_argument, I"*memory")) {
					step->from_memory = TRUE;
				} else {
					step->parsed_filename = Filenames::from_text(step->step_argument);
					int slashes = FALSE;
					LOOP_THROUGH_TEXT(pos, step->step_argument)
						if (Str::get(pos) == '/')
							slashes = TRUE;
					if (slashes) step->parsed_filename = Filenames::from_text(step->step_argument);
					else step->parsed_filename = Filenames::in_folder(P, step->step_argument);
					LOG("Parsed %S == %f\n", step->step_argument, step->parsed_filename);
				}
			}

			text_stream text_output_struct; /* For any text file we might write */
			text_stream *T = &text_output_struct;
			if (step->to_debugging_log) {
				step->text_out_file = DL;
			} else if ((step->step_stage->stage_arg == TEXT_OUT_STAGE_ARG) ||
				(step->step_stage->stage_arg == EXT_TEXT_OUT_STAGE_ARG)) {
				if (STREAM_OPEN_TO_FILE(T, step->parsed_filename, ISO_ENC) == FALSE) {
					#ifdef PROBLEMS_MODULE
					Problems::Fatal::filename_related("Can't open output file", step->parsed_filename);
					#endif
					#ifndef PROBLEMS_MODULE
					Errors::fatal_with_file("Can't open output file", step->parsed_filename);
					exit(1);
					#endif
				}
				step->text_out_file = T;
			}

			if ((step->from_memory) && (step->repository_argument >= 0))
				S->repositories[step->repository_argument] = S->memory_repository;
			else
				active = (*(step->step_stage->execute))(step);

			if (((step->step_stage->stage_arg == TEXT_OUT_STAGE_ARG) ||
				(step->step_stage->stage_arg == EXT_TEXT_OUT_STAGE_ARG)) &&
				(step->to_debugging_log == FALSE)) {
				STREAM_CLOSE(T);
			}
			
			if (step->repository_argument >= 0) {
				current_repo = step->repository_argument;
				CodeGen::Pipeline::prepare_to_run(S->repositories[current_repo]);
			}
		}
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

inter_symbol *submodule_ptype_symbol = NULL;
inter_symbol *function_ptype_symbol = NULL;
inter_symbol *action_ptype_symbol = NULL;
inter_symbol *command_ptype_symbol = NULL;
inter_symbol *property_ptype_symbol = NULL;
inter_symbol *to_phrase_ptype_symbol = NULL;

inter_symbol *template_symbol = NULL;
inter_package *template_package = NULL;

void CodeGen::Pipeline::prepare_to_run(inter_repository *I) {

	submodule_ptype_symbol = Inter::SymbolsTables::url_name_to_symbol(I, NULL, I"/_submodule");
	function_ptype_symbol = Inter::SymbolsTables::url_name_to_symbol(I, NULL, I"/_function");
	action_ptype_symbol = Inter::SymbolsTables::url_name_to_symbol(I, NULL, I"/_action");
	command_ptype_symbol = Inter::SymbolsTables::url_name_to_symbol(I, NULL, I"/_command");
	property_ptype_symbol = Inter::SymbolsTables::url_name_to_symbol(I, NULL, I"/_property");
	to_phrase_ptype_symbol = Inter::SymbolsTables::url_name_to_symbol(I, NULL, I"/_to_phrase");

	template_symbol = Inter::SymbolsTables::url_name_to_symbol(I, NULL, I"/main/template");
	if (template_symbol) template_package = Inter::Package::which(template_symbol);

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

void CodeGen::Pipeline::lint(inter_repository *I) {
	Inter::traverse_tree(I, CodeGen::Pipeline::visitor, NULL, NULL, -PACKAGE_IST);
}

void CodeGen::Pipeline::visitor(inter_repository *I, inter_frame P, void *state) {
	inter_t c = Inter::Frame::get_package(P);
	inter_t a = Inter::Frame::get_package_alt(P);
	if (c != a) {
		LOG("Frame gives package as $3, but its location is in package $3\n",
			Inter::Packages::from_PID(I, c)->package_name,
			Inter::Packages::from_PID(I, a)->package_name);
		internal_error("zap");
	}

	CodeGen::Link::guard(Inter::Defn::verify_children_inner(P));
}
