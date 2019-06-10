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
	
	struct filename *parsed_filename;
	struct pathname **the_PP;
	int the_N;
	struct text_stream *text_out_file;
	struct inter_repository *repository;
	MEMORY_MANAGEMENT
} pipeline_step;

pipeline_step *CodeGen::Pipeline::new_step(void) {
	pipeline_step *step = CREATE(pipeline_step);
	step->step_stage = NULL;
	step->step_argument = NULL;
	CodeGen::Pipeline::clean_step(step);
	return step;
}

@ This wipes clean the temporary storage for a step.

=
void CodeGen::Pipeline::clean_step(pipeline_step *step) {
	step->parsed_filename = NULL;
	step->text_out_file = NULL;
	step->the_N = -1;
	step->the_PP = NULL;
	step->repository = NULL;
}

@ Here we write a textual description to a string, which is useful for
logging:

=
void CodeGen::Pipeline::write_step(OUTPUT_STREAM, pipeline_step *step) {
	if (step->step_stage->stage_arg == NO_STAGE_ARG)
		WRITE("%S", step->step_stage->stage_name);
	else
		WRITE("%S:%S", step->step_stage->stage_name, step->step_argument);
}

pipeline_step *CodeGen::Pipeline::read_step(text_stream *step, text_stream *leafname) {
	CodeGen::Stage::make_stages();
	pipeline_step *ST = CodeGen::Pipeline::new_step();
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, step, L"(%c+?) *: *(%c*)")) {
		ST->step_argument = Str::new();
		Str::copy(ST->step_argument, mr.exp[1]);
		Str::copy(step, mr.exp[0]);
		if (Str::eq(ST->step_argument, I"*")) Str::copy(ST->step_argument, leafname);
	}
	pipeline_stage *stage;
	LOOP_OVER(stage, pipeline_stage)
		if (Str::eq(step, stage->stage_name))
			ST->step_stage = stage;
	if (ST->step_stage == NULL) internal_error("no such step code");
	return ST;
}

@h Pipelines.
And then a pipeline is just a linked list of steps.

=
typedef struct codegen_pipeline {
	struct linked_list *steps; /* of |pipeline_step| */
	MEMORY_MANAGEMENT
} codegen_pipeline;

codegen_pipeline *CodeGen::Pipeline::new(void) {
	codegen_pipeline *S = CREATE(codegen_pipeline);
	S->steps = NEW_LINKED_LIST(pipeline_step);
	return S;
}

codegen_pipeline *CodeGen::Pipeline::parse(text_stream *instructions, text_stream *leafname) {
	codegen_pipeline *S = CodeGen::Pipeline::new();
	CodeGen::Pipeline::parse_into(S, instructions, leafname);
	return S;
}

void CodeGen::Pipeline::parse_into(codegen_pipeline *S, text_stream *instructions, text_stream *leafname) {
	if (instructions == NULL)
		instructions = I"link:Output.i6t, parse-linked-matter, resolve-conditional-compilation, assimilate, reconcile-verbs, generate-i6:*";
	TEMPORARY_TEXT(T);
	Str::copy(T, instructions);
	match_results mr = Regexp::create_mr();
	while (Regexp::match(&mr, T, L" *(%c+?) *, *(%c*)")) {
		pipeline_step *ST = CodeGen::Pipeline::read_step(mr.exp[0], leafname);
		ADD_TO_LINKED_LIST(ST, pipeline_step, S->steps);
		Str::copy(T, mr.exp[1]);
	}
	if (Regexp::match(&mr, T, L" *(%c+?) *")) {
		pipeline_step *ST = CodeGen::Pipeline::read_step(mr.exp[0], leafname);
		ADD_TO_LINKED_LIST(ST, pipeline_step, S->steps);
	}
}

int CodeGen::Pipeline::port_direction(codegen_pipeline *pipeline) {
	pipeline_step *SS;
	LOOP_OVER_LINKED_LIST(SS, pipeline_step, pipeline->steps)
		if (SS->step_stage->port_direction != 0)
			return SS->step_stage->port_direction;
	return 0;
}

void CodeGen::Pipeline::run(pathname *P, codegen_pipeline *S, inter_repository *I, int N, pathname **PP, pathname *PM, pathname *FM) {
	if (S == NULL) return;
	clock_t start = clock();

	CodeGen::Pipeline::prepare_to_run(I);

	int step_count = 0, step_total = 0;
	pipeline_step *step;
	LOOP_OVER_LINKED_LIST(step, pipeline_step, S->steps) step_total++;

	int active = TRUE;
	LOOP_OVER_LINKED_LIST(step, pipeline_step, S->steps)
		if (active) {
			text_stream text_output_struct; /* For any text file we might write */
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
				(step->step_stage->stage_arg == TEXT_OUT_STAGE_ARG)) {
				int slashes = FALSE;
				LOOP_THROUGH_TEXT(pos, step->step_argument)
					if (Str::get(pos) == '/')
						slashes = TRUE;
				if (slashes) step->parsed_filename = Filenames::from_text(step->step_argument);
				else step->parsed_filename =  Filenames::in_folder(FM, step->step_argument);
			}

			if (step->step_stage->stage_arg == TEXT_OUT_STAGE_ARG) {
				step->text_out_file = &text_output_struct;
				if (STREAM_OPEN_TO_FILE(step->text_out_file, step->parsed_filename, ISO_ENC) == FALSE) {
					#ifdef PROBLEMS_MODULE
					Problems::Fatal::filename_related("Can't open output file", step->parsed_filename);
					#endif
					#ifndef PROBLEMS_MODULE
					Errors::fatal_with_file("Can't open output file", step->parsed_filename);
					exit(1);
					#endif
				}
			}

			active = (*(step->step_stage->execute))(step);

			if (step->step_stage->stage_arg == TEXT_OUT_STAGE_ARG) {
				STREAM_CLOSE(step->text_out_file);
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

void CodeGen::Pipeline::prepare_to_run(inter_repository *I) {
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
