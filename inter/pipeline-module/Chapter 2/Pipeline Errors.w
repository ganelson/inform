[PipelineErrors::] Pipeline Errors.

To issue problem messages when parsing or running erroneous pipelines.

@h Syntax errors.

=
void PipelineErrors::syntax(text_file_position *tfp, text_stream *syntax,
	char *erm) {
	#ifdef CORE_MODULE
	@<Begin syntax problem message using the module of the same name@>;
	TEMPORARY_TEXT(full)
	WRITE_TO(full, "%s", erm);
	@<End syntax problem message using the module of the same name@>;
	DISCARD_TEXT(full)
	#endif
	#ifndef CORE_MODULE
	Errors::in_text_file(erm, tfp);
	#endif
}

void PipelineErrors::syntax_with(text_file_position *tfp, text_stream *syntax,
	char *erm, text_stream *quoted) {
	TEMPORARY_TEXT(full)
	WRITE_TO(full, erm, quoted);
	#ifdef CORE_MODULE
	@<Begin syntax problem message using the module of the same name@>;
	@<End syntax problem message using the module of the same name@>;
	#endif
	#ifndef CORE_MODULE
	Errors::in_text_file_S(full, tfp);
	#endif
	DISCARD_TEXT(full)
}

@<Begin syntax problem message using the module of the same name@> =
	do_not_locate_problems = TRUE;
	Problems::issue_problem_begin(NULL, erm);
	Problems::issue_problem_segment(
		"I was nearly done, and about to run through the 'pipeline' of "
		"code-generation steps, but it turned out to have a syntax error. "
		"(The built-in pipelines do not have syntax errors, so this must be "
		"because you are experimenting with a non-standard pipeline,) "
		"Specifically:");
	Problems::issue_problem_end();

@<End syntax problem message using the module of the same name@> =
	Problems::issue_problem_begin(Task::syntax_tree(), "****");
	int N = tfp->line_count;
	Problems::quote_number(1, &N);
	Problems::quote_stream(2, syntax);
	Problems::quote_stream_tinted_red(3, full);
	Problems::issue_problem_begin(Task::syntax_tree(), "****");
	Problems::issue_problem_segment("Line %1 '%2': %3");
	Problems::issue_problem_end();
	do_not_locate_problems = FALSE;

@h Execution errors.

=
void PipelineErrors::error(pipeline_step *step, char *erm) {
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

void PipelineErrors::error_with(pipeline_step *step, char *erm, text_stream *quoted) {
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
	if (Log::aspect_switched_on(INTER_DA))
		TextualInter::write(DL, Emit::tree(), NULL);

@h Errors in kit source.
Errors like this used to be basically failed assertions, but inevitably people
reported that as a bug (0001596). It was never intended that Inform 6-syntax
hacking should be part of the outside-facing Inform language; but if you leave
power tools just lying around, people will eventually pick them up and wonder
what the red button marked "danger" does.

=
int kit_error_count = 0;
text_stream *kit_error_filename = NULL;
int kit_error_line_number = 0;

void PipelineErrors::set_kit_error_location(text_stream *file, inter_ti line) {
	kit_error_filename = file;
	kit_error_line_number = (int) line;
}

void PipelineErrors::kit_error(char *message, text_stream *quote) {
	#ifdef CORE_MODULE
	SourceProblems::I6_level_error(message, quote, kit_error_filename,
		kit_error_line_number);
	#endif
	#ifndef CORE_MODULE
	if (Str::len(kit_error_filename) > 0) {
		filename *F = Filenames::from_text(kit_error_filename);
		TEMPORARY_TEXT(M)
		WRITE_TO(M, message, quote);
		Errors::at_position_S(M, F, kit_error_line_number);
		DISCARD_TEXT(M)
	} else {
		Errors::with_text(message, quote);
	}
	#endif
	kit_error_count++;
}

void PipelineErrors::reset_errors(void) {
	kit_error_count = 0;
}

int PipelineErrors::errors_occurred(void) {
	if (kit_error_count != 0) return TRUE;
	return FALSE;
}
