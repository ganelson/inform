[CodeGen::Stage::] Stage Control.

To control the stages through which code generation proceeds.

@h Stage sets.

=
typedef struct stage_set {
	struct stage_step *first_step;
	MEMORY_MANAGEMENT
} stage_set;

typedef struct stage_step {
	int step_code;
	struct text_stream *step_argument;
	struct stage_step *next_step;
	MEMORY_MANAGEMENT
} stage_step;

@

@e LINK_STAGESTEP from 1
@e DEPENDENCIES_STAGESTEP
@e LOG_DEPENDENCIES_STAGESTEP
@e EXPORT_STAGESTEP
@e IMPORT_STAGESTEP
@e PLM_STAGESTEP
@e RCC_STAGESTEP
@e ASSIMILATE_STAGESTEP
@e UNIQUE_STAGESTEP
@e RECONCILE_VERBS_STAGESTEP
@e ELIMINATE_REDUNDANT_CODE_STAGESTEP
@e GENERATE_I6_STAGESTEP
@e GENERATE_INTER_STAGESTEP
@e GENERATE_INTER_BINARY_STAGESTEP
@e SUMMARISE_STAGESTEP
@e STOP_STAGESTEP

@h Parsing.

=
int CodeGen::Stage::port(text_stream *instructions) {
	stage_set *S = CodeGen::Stage::parse(instructions, I"nowhere");
	stage_step *SS;
	for (SS = S->first_step; SS; SS = SS->next_step)
		switch (SS->step_code) {
			case EXPORT_STAGESTEP: return 1;
			case IMPORT_STAGESTEP: return -1;
		}
	return 0;
}

stage_set *CodeGen::Stage::new_set(void) {
	stage_set *S = CREATE(stage_set);
	S->first_step = NULL;
	return S;
}

stage_set *CodeGen::Stage::parse(text_stream *instructions, text_stream *leafname) {
	stage_set *S = CodeGen::Stage::new_set();
	CodeGen::Stage::parse_into(S, instructions, leafname);
	return S;
}

void CodeGen::Stage::parse_into(stage_set *S, text_stream *instructions, text_stream *leafname) {
	if (instructions == NULL)
		instructions = I"link:Output.i6t, parse-linked-matter, resolve-conditional-compilation, assimilate, reconcile-verbs, generate-i6:*";
	TEMPORARY_TEXT(T);
	Str::copy(T, instructions);
	match_results mr = Regexp::create_mr();
	while (Regexp::match(&mr, T, L" *(%c+?) *, *(%c*)")) {
		CodeGen::Stage::parse_step(S, mr.exp[0], leafname);
		Str::copy(T, mr.exp[1]);
	}
	if (Regexp::match(&mr, T, L" *(%c+?) *")) {
		CodeGen::Stage::parse_step(S, mr.exp[0], leafname);
	}
}

stage_step *CodeGen::Stage::parse_step(stage_set *S, text_stream *step, text_stream *leafname) {
	stage_step *ST = CREATE(stage_step);
	ST->next_step = NULL;
	if (S->first_step == NULL) S->first_step = ST;
	else {
		stage_step *STP = S->first_step;
		while (STP->next_step) STP = STP->next_step;
		STP->next_step = ST;
	}
	ST->step_argument = NULL;
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, step, L"(%c+?) *: *(%c*)")) {
		ST->step_argument = Str::new();
		Str::copy(ST->step_argument, mr.exp[1]);
		Str::copy(step, mr.exp[0]);
		if (Str::eq(ST->step_argument, I"*")) Str::copy(ST->step_argument, leafname);
	}
	if (Str::eq(step, I"link")) ST->step_code = LINK_STAGESTEP;
	else if (Str::eq(step, I"show-dependencies")) ST->step_code = DEPENDENCIES_STAGESTEP;
	else if (Str::eq(step, I"log-dependencies")) ST->step_code = LOG_DEPENDENCIES_STAGESTEP;
	else if (Str::eq(step, I"export")) ST->step_code = EXPORT_STAGESTEP;
	else if (Str::eq(step, I"import")) ST->step_code = IMPORT_STAGESTEP;
	else if (Str::eq(step, I"parse-linked-matter")) ST->step_code = PLM_STAGESTEP;
	else if (Str::eq(step, I"resolve-conditional-compilation")) ST->step_code = RCC_STAGESTEP;
	else if (Str::eq(step, I"assimilate")) ST->step_code = ASSIMILATE_STAGESTEP;
	else if (Str::eq(step, I"make-identifiers-unique")) ST->step_code = UNIQUE_STAGESTEP;
	else if (Str::eq(step, I"reconcile-verbs")) ST->step_code = RECONCILE_VERBS_STAGESTEP;
	else if (Str::eq(step, I"eliminate-redundant-code")) ST->step_code = ELIMINATE_REDUNDANT_CODE_STAGESTEP;
	else if (Str::eq(step, I"generate-i6")) ST->step_code = GENERATE_I6_STAGESTEP;
	else if (Str::eq(step, I"generate-inter")) ST->step_code = GENERATE_INTER_STAGESTEP;
	else if (Str::eq(step, I"generate-inter-binary")) ST->step_code = GENERATE_INTER_BINARY_STAGESTEP;
	else if (Str::eq(step, I"summarise")) ST->step_code = SUMMARISE_STAGESTEP;
	else if (Str::eq(step, I"stop")) ST->step_code = STOP_STAGESTEP;
	else internal_error("no such step code");
	return ST;
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

void CodeGen::Stage::follow(pathname *P, stage_set *S, inter_repository *I, int N, pathname **PP, pathname *PM, pathname *FM) {
	if (S == NULL) return;
	clock_t start = clock();

	unchecked_kind_symbol = Inter::Packages::search_main_exhaustively(I, I"K_unchecked");
	unchecked_function_symbol = Inter::Packages::search_main_exhaustively(I, I"K_unchecked_function");
	typeless_int_symbol = Inter::Packages::search_main_exhaustively(I, I"K_typeless_int");
	list_of_unchecked_kind_symbol = Inter::Packages::search_main_exhaustively(I, I"K_list_of_values");
	object_kind_symbol = Inter::Packages::search_main_exhaustively(I, I"K_object");
	action_kind_symbol = Inter::Packages::search_main_exhaustively(I, I"K_action_name");
	truth_state_kind_symbol = Inter::Packages::search_main_exhaustively(I, I"K_truth_state");
	direction_kind_symbol = Inter::Packages::search_main_exhaustively(I, I"K3_direction");

	verb_directive_reverse_symbol = Inter::Packages::search_main_exhaustively(I, I"VERB_DIRECTIVE_REVERSE");
	verb_directive_slash_symbol = Inter::Packages::search_main_exhaustively(I, I"VERB_DIRECTIVE_SLASH");
	verb_directive_divider_symbol = Inter::Packages::search_main_exhaustively(I, I"VERB_DIRECTIVE_DIVIDER");
	verb_directive_result_symbol = Inter::Packages::search_main_exhaustively(I, I"VERB_DIRECTIVE_RESULT");
	verb_directive_special_symbol = Inter::Packages::search_main_exhaustively(I, I"VERB_DIRECTIVE_SPECIAL");
	verb_directive_number_symbol = Inter::Packages::search_main_exhaustively(I, I"VERB_DIRECTIVE_NUMBER");
	verb_directive_noun_symbol = Inter::Packages::search_main_exhaustively(I, I"VERB_DIRECTIVE_NOUN");
	verb_directive_multi_symbol = Inter::Packages::search_main_exhaustively(I, I"VERB_DIRECTIVE_MULTI");
	verb_directive_multiinside_symbol = Inter::Packages::search_main_exhaustively(I, I"VERB_DIRECTIVE_MULTIINSIDE");
	verb_directive_multiheld_symbol = Inter::Packages::search_main_exhaustively(I, I"VERB_DIRECTIVE_MULTIHELD");
	verb_directive_held_symbol = Inter::Packages::search_main_exhaustively(I, I"VERB_DIRECTIVE_HELD");
	verb_directive_creature_symbol = Inter::Packages::search_main_exhaustively(I, I"VERB_DIRECTIVE_CREATURE");
	verb_directive_topic_symbol = Inter::Packages::search_main_exhaustively(I, I"VERB_DIRECTIVE_TOPIC");
	verb_directive_multiexcept_symbol = Inter::Packages::search_main_exhaustively(I, I"VERB_DIRECTIVE_MULTIEXCEPT");

	int step_count = 0, step_total = 0;
	for (stage_step *step = S->first_step; step; step = step->next_step) step_total++;

	int active = TRUE;
	for (stage_step *step = S->first_step; ((step) && (active)); step = step->next_step) {
		text_stream text_output_struct; /* The actual I6 code file */
		text_stream *text_out_file = &text_output_struct; /* The actual I6 code file */
		TEMPORARY_TEXT(STAGE_NAME);
		WRITE_TO(STAGE_NAME, "inter step %d/%d (at %dcs): ", ++step_count, step_total,
			((int) (clock() - start)) / (CLOCKS_PER_SEC/100));
		switch (step->step_code) {
			case DEPENDENCIES_STAGESTEP: {
				WRITE_TO(STAGE_NAME, "show-dependencies:%S", step->step_argument);
				Log::new_stage(STAGE_NAME);
				filename *F = CodeGen::Stage::extricate(FM, step->step_argument);
				@<Open the file for text output@>;
				Inter::Graph::show_dependencies(text_out_file, I);
				STREAM_CLOSE(text_out_file);
				break;
			}
			case LOG_DEPENDENCIES_STAGESTEP: {
				WRITE_TO(STAGE_NAME, "log-dependencies");
				Log::new_stage(STAGE_NAME);
				Inter::Graph::show_dependencies(DL, I);
				break;
			}
			case ELIMINATE_REDUNDANT_CODE_STAGESTEP: {
				WRITE_TO(STAGE_NAME, "eliminate-redundant-code");
				Log::new_stage(STAGE_NAME);
				CodeGen::Eliminate::go(I);
				break;
			}
			case EXPORT_STAGESTEP: {
				WRITE_TO(STAGE_NAME, "export:%S", step->step_argument);
				Log::new_stage(STAGE_NAME);
				filename *F = CodeGen::Stage::extricate(FM, step->step_argument);
				@<Open the file for text output@>;
				CodeGen::CacheCM::go(text_out_file, I);
				STREAM_CLOSE(text_out_file);
				break;
			}
			case IMPORT_STAGESTEP:
				WRITE_TO(STAGE_NAME, "import:%S", step->step_argument);
				Log::new_stage(STAGE_NAME);
				filename *F = CodeGen::Stage::extricate(FM, step->step_argument);
				CodeGen::Import::import(I, F); break;
			case LINK_STAGESTEP: {
				WRITE_TO(STAGE_NAME, "link:%S", step->step_argument);
				Log::new_stage(STAGE_NAME);
				inter_reading_state IRS = Inter::Bookmarks::new_IRS(I);
				IRS.current_package = Inter::Packages::main(I);
				IRS.cp_indent = 1;
				CodeGen::Link::link(&IRS, step->step_argument, N, PP, NULL); break;
			}
			case PLM_STAGESTEP:
				WRITE_TO(STAGE_NAME, "parse-linked-matter");
				Log::new_stage(STAGE_NAME);
				CodeGen::PLM::parse(I); break;
			case RCC_STAGESTEP:
				WRITE_TO(STAGE_NAME, "resolve-conditional-compilation");
				Log::new_stage(STAGE_NAME);
				CodeGen::RCC::resolve(I); break;
			case ASSIMILATE_STAGESTEP: {
				WRITE_TO(STAGE_NAME, "assimilate");
				Log::new_stage(STAGE_NAME);
				inter_reading_state IRS = Inter::Bookmarks::new_IRS(I);
				CodeGen::Assimilate::assimilate(&IRS); break;
			}
			case UNIQUE_STAGESTEP:
				WRITE_TO(STAGE_NAME, "make-identifiers-unique");
				Log::new_stage(STAGE_NAME);
				CodeGen::Uniqueness::ensure(I); break;
			case RECONCILE_VERBS_STAGESTEP:
				WRITE_TO(STAGE_NAME, "reconcile-verbs");
				Log::new_stage(STAGE_NAME);
				CodeGen::ReconcileVerbs::reconcile(I); break;
			case GENERATE_I6_STAGESTEP: {
				WRITE_TO(STAGE_NAME, "generate-i6:%S", step->step_argument);
				Log::new_stage(STAGE_NAME);
				filename *F = CodeGen::Stage::extricate(P, step->step_argument);
				@<Open the file for text output@>;
				CodeGen::to_I6(I, text_out_file);
				STREAM_CLOSE(text_out_file);
				break;
			}
			case GENERATE_INTER_STAGESTEP: {
				WRITE_TO(STAGE_NAME, "generate-inter:%S", step->step_argument);
				Log::new_stage(STAGE_NAME);
				filename *F = CodeGen::Stage::extricate(P, step->step_argument);
				@<Open the file for text output@>;
				Inter::Textual::write(text_out_file, I, NULL, 1);
				STREAM_CLOSE(text_out_file);
				break;
			}
			case GENERATE_INTER_BINARY_STAGESTEP: {
				WRITE_TO(STAGE_NAME, "generate-inter-binary:%S", step->step_argument);
				Log::new_stage(STAGE_NAME);
				filename *F = CodeGen::Stage::extricate(P, step->step_argument);
				Inter::Binary::write(F, I);
				break;
			}
			case SUMMARISE_STAGESTEP: {
				WRITE_TO(STAGE_NAME, "summarise:%S", step->step_argument);
				Log::new_stage(STAGE_NAME);
				filename *F = CodeGen::Stage::extricate(P, step->step_argument);
				@<Open the file for text output@>;
				Inter::Summary::write(text_out_file, I);
				STREAM_CLOSE(text_out_file);
				break;
			}
			case STOP_STAGESTEP: active = FALSE; break;
			default: internal_error("unknown stage step");
		}
		DISCARD_TEXT(STAGE_NAME);
	}
}

@<Open the file for text output@> =
	if (STREAM_OPEN_TO_FILE(text_out_file, F, ISO_ENC) == FALSE) {
		#ifdef PROBLEMS_MODULE
		Problems::Fatal::filename_related("Can't open output file", F);
		#endif
		#ifndef PROBLEMS_MODULE
		Errors::fatal_with_file("Can't open output file", F);
		exit(1);
		#endif
	}

@ =
filename *CodeGen::Stage::extricate(pathname *P, text_stream *S) {
	int slashes = FALSE;
	LOOP_THROUGH_TEXT(pos, S)
		if (Str::get(pos) == '/')
			slashes = TRUE;
	if (slashes) return Filenames::from_text(S);
	return Filenames::in_folder(P, S);
}
