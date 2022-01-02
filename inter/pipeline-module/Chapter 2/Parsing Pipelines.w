[ParsingPipelines::] Parsing Pipelines.

To parse pipelines from text files.

@h How pipelines are stored.
An //inter_pipeline// is a linked list of //pipeline_step//s, together with
some associated storage used when it runs: this is for storing variables and
pointers to trees being worked on.

=
typedef struct inter_pipeline {
	struct linked_list *steps; /* of |pipeline_step| */
	struct dictionary *variables;
	int erroneous; /* a syntax error occurred when parsing this */
	struct pipeline_ephemera ephemera; /* temporary storage when running */
	struct linked_list *search_list; /* used when parsing only */
	struct pathname *local;
	int run_depth;
	CLASS_DEFINITION
} inter_pipeline;

inter_pipeline *ParsingPipelines::new_pipeline(dictionary *D, linked_list *L, pathname *local) {
	inter_pipeline *S = CREATE(inter_pipeline);
	S->variables = D;
	S->steps = NEW_LINKED_LIST(pipeline_step);
	S->erroneous = FALSE;
	S->search_list = L;
	S->local = local;
	S->run_depth = 0;
	RunningPipelines::clean_pipeline(S);
	return S;
}

@ A //pipeline_step// is really only a choice of //pipeline_stage//, but comes
along with a wide variety of options and parameter settings, so that it looks
much more complicated than it actually is.

=
typedef struct pipeline_step {
	struct inter_pipeline *pipeline;
	struct pipeline_stage *step_stage;
	struct text_stream *step_argument;
	struct code_generator *generator_argument;
	int take_generator_argument_from_VM;
	struct text_stream *package_URL_argument;
	int repository_argument;
	struct pipeline_step_ephemera ephemera; /* temporary storage when running */
	CLASS_DEFINITION
} pipeline_step;

pipeline_step *ParsingPipelines::new_step(inter_pipeline *pipeline) {
	pipeline_step *step = CREATE(pipeline_step);
	step->pipeline = pipeline;
	step->step_stage = NULL;
	step->step_argument = NULL;
	step->package_URL_argument = NULL;
	step->repository_argument = 0;
	step->generator_argument = NULL;
	step->take_generator_argument_from_VM = FALSE;
	RunningPipelines::clean_step(step);
	return step;
}

@ And a //pipeline_stage// is simply a choice of what to do. For example,
|eliminate-redundant-labels| is a pipeline stage. This would need to be
combined with details of what tree to apply to in order to become a step.

@e NO_STAGE_ARG from 1
@e GENERAL_STAGE_ARG
@e FILE_STAGE_ARG
@e TEXT_OUT_STAGE_ARG
@e OPTIONAL_TEXT_OUT_STAGE_ARG
@e EXT_FILE_STAGE_ARG
@e EXT_TEXT_OUT_STAGE_ARG
@e TEMPLATE_FILE_STAGE_ARG

=
typedef struct pipeline_stage {
	struct text_stream *stage_name;
	int (*execute)(void *);
	int stage_arg; /* one of the |*_ARG| values above */
	int takes_repository;
	CLASS_DEFINITION
} pipeline_stage;

pipeline_stage *ParsingPipelines::new_stage(text_stream *name,
	int (*X)(struct pipeline_step *), int arg, int tr) {
	pipeline_stage *stage = CREATE(pipeline_stage);
	stage->stage_name = Str::duplicate(name);
	stage->execute = (int (*)(void *)) X;
	stage->stage_arg = arg;
	stage->takes_repository = tr;
	return stage;
}

@ Lumping some of those argument types together:

=
int ParsingPipelines::will_read_a_file(pipeline_step *step) {
	if ((step->step_stage->stage_arg == FILE_STAGE_ARG) ||
		(step->step_stage->stage_arg == EXT_FILE_STAGE_ARG)) return TRUE;
	return FALSE;
}

int ParsingPipelines::will_write_a_file(pipeline_step *step) {
	if ((step->step_stage->stage_arg == TEXT_OUT_STAGE_ARG) ||
		(step->step_stage->stage_arg == OPTIONAL_TEXT_OUT_STAGE_ARG) ||
		(step->step_stage->stage_arg == EXT_TEXT_OUT_STAGE_ARG)) return TRUE;
	return FALSE;
}

@h Parsing.
All pipelines originate as textual descriptions, either from a text file or
supplied on the command line. Here, we turn such a description -- in effect
a program for a very simple programming language -- into an //inter_pipeline//.

=
inter_pipeline *ParsingPipelines::from_file(filename *F, dictionary *D,
	linked_list *search_list) {
	inter_pipeline *S = ParsingPipelines::new_pipeline(D, search_list, Filenames::up(F));
	TextFiles::read(F, FALSE, "can't open inter pipeline file",
		TRUE, ParsingPipelines::scan_line, NULL, (void *) S);
	if (S->erroneous) return NULL;
	return S;
}

void ParsingPipelines::scan_line(text_stream *line, text_file_position *tfp, void *X) {
	inter_pipeline *S = (inter_pipeline *) X;
	ParsingPipelines::parse_line(S, line, tfp);
}

inter_pipeline *ParsingPipelines::from_text(text_stream *instructions, dictionary *D) {
	inter_pipeline *S = ParsingPipelines::new_pipeline(D, NULL, NULL);
	ParsingPipelines::parse_line(S, instructions, NULL);
	if (S->erroneous) return NULL;
	return S;
}

@ Either way, then, a sequence of 1 or more textual lines of description is
passed to the following. It breaks down the line into 1 or more instructions,
divided by commas.

=
void ParsingPipelines::parse_line(inter_pipeline *pipeline, text_stream *instructions,
	text_file_position *tfp) {
	TEMPORARY_TEXT(T)
	LOOP_THROUGH_TEXT(P, instructions)
		if (Characters::is_babel_whitespace(Str::get(P)))
			PUT_TO(T, ' ');
		else
			PUT_TO(T, Str::get(P));
	match_results mr = Regexp::create_mr();
	while (Regexp::match(&mr, T, L" *(%c+?) *,+ *(%c*?) *")) {
		ParsingPipelines::parse_instruction(pipeline, mr.exp[0], tfp);
		Str::copy(T, mr.exp[1]);
	}
	if (Regexp::match(&mr, T, L" *(%c+?) *"))
		ParsingPipelines::parse_instruction(pipeline, mr.exp[0], tfp);
	Regexp::dispose_of(&mr);
	DISCARD_TEXT(T)
}

@ Instructions are mostly steps, but:

(a) A line beginning with an |!| is a comment,
(b) |run pipeline X| means to incorporate pipeline |X| here.

=
void ParsingPipelines::parse_instruction(inter_pipeline *pipeline, text_stream *T,
	text_file_position *tfp) {
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, T, L"!%c*")) {
		;
	} else if (Regexp::match(&mr, T, L"run pipeline (%c*)")) {
		filename *F = NULL;
		#ifdef SUPERVISOR_MODULE
		F = InterSkill::filename_of_pipeline(mr.exp[0], pipeline->search_list);
		#endif
		if (F == NULL) {
			text_stream *leafname = Str::new();
			WRITE_TO(leafname, "%S.interpipeline", mr.exp[0]);
			F = Filenames::in(pipeline->local, leafname);
		}
		if (F == NULL) {
			PipelineErrors::syntax_with(tfp, T,
				"unable to find the pipeline '%S'", mr.exp[0]);
			pipeline->erroneous = TRUE;
		} else {
			if (pipeline->run_depth++ > 100) {
				PipelineErrors::syntax_with(tfp, T,
					"pipeline seems to have become circular: '%S'", mr.exp[0]);
				pipeline->erroneous = TRUE;
			} else {
				TextFiles::read(F, FALSE, "can't open inter pipeline file",
					TRUE, ParsingPipelines::scan_line, NULL, (void *) pipeline);
			}
			pipeline->run_depth--;
		}
	} else {
		pipeline_step *ST = ParsingPipelines::parse_step(pipeline, T, tfp);
		if (ST) ADD_TO_LINKED_LIST(ST, pipeline_step, pipeline->steps);
		else pipeline->erroneous = TRUE;
	}
	Regexp::dispose_of(&mr);
}

@ Finally, an individual textual description |S| of a step is turned into a
//pipeline_step//.

For documentation on the syntax here, see //inter: Pipelines and Stages//.

=
pipeline_step *ParsingPipelines::parse_step(inter_pipeline *pipeline, text_stream *S,
	text_file_position *tfp) {
	dictionary *D = pipeline->variables;
	pipeline_step *step = ParsingPipelines::new_step(pipeline);
	text_stream *syntax = Str::duplicate(S);
	match_results mr = Regexp::create_mr();

	int allow_unknown = FALSE;
	if (Regexp::match(&mr, S, L"optionally-%c+")) allow_unknown = TRUE;

	int left_arrow_used = FALSE;
	if (Regexp::match(&mr, S,      L"(%c+?) *<- *(%c*)"))       @<Left arrow notation@>
	else if (Regexp::match(&mr, S, L"(%c+?) (%C+) *-> *(%c*)")) @<Right arrow notation with generator@>
	else if (Regexp::match(&mr, S, L"(%c+?) *-> *(%c*)"))       @<Right arrow notation without generator@>;

	if (Regexp::match(&mr, S,      L"(%C+?) (%d)"))             @<Repository number as argument@>
	else if (Regexp::match(&mr, S, L"(%C+?) (%d):(%c*)"))       @<Repository number and package as arguments@>
	else if (Regexp::match(&mr, S, L"(%C+?) (%c+)"))            @<Package as argument@>;

	step->step_stage = ParsingPipelines::parse_stage(S);
	@<Make consistency checks@>;
	
	Regexp::dispose_of(&mr);
	return step;
}

@<Left arrow notation@> =
	if (Str::len(mr.exp[1]) > 0) {
		step->step_argument = ParsingPipelines::text_arg(mr.exp[1], D, tfp, syntax, allow_unknown);
		if (step->step_argument == NULL) return NULL;
	} else {
		PipelineErrors::syntax(tfp, syntax, "no source to right of arrow");
		return NULL;
	}
	Str::copy(S, mr.exp[0]);
	left_arrow_used = TRUE;

@<Right arrow notation with generator@> =
	code_generator *cgt = Generators::find(mr.exp[1]);
	if (cgt == NULL) {
		PipelineErrors::syntax_with(tfp, syntax,
			"no such code generation format as '%S'", mr.exp[1]);
		return NULL;
	} else {
		step->generator_argument = cgt;
	}
	step->step_argument = ParsingPipelines::text_arg(mr.exp[2], D, tfp, syntax, allow_unknown);
	if (step->step_argument == NULL) return NULL;
	Str::copy(S, mr.exp[0]);

@<Right arrow notation without generator@> =
	step->generator_argument = NULL;
	step->take_generator_argument_from_VM = TRUE;
	step->step_argument = ParsingPipelines::text_arg(mr.exp[1], D, tfp, syntax, allow_unknown);
	if (step->step_argument == NULL) return NULL;
	Str::copy(S, mr.exp[0]);

@<Repository number as argument@> =
	step->repository_argument = Str::atoi(mr.exp[1], 0);
	Str::copy(S, mr.exp[0]);

@<Repository number and package as arguments@> =
	step->repository_argument = Str::atoi(mr.exp[1], 0);
	if (Str::len(mr.exp[2]) > 0) {
		step->package_URL_argument =
			ParsingPipelines::text_arg(mr.exp[2], D, tfp, syntax, allow_unknown);
		if (step->package_URL_argument == NULL) return NULL;
	}
	Str::copy(S, mr.exp[0]);

@<Package as argument@> =
	step->package_URL_argument =
		ParsingPipelines::text_arg(mr.exp[1], D, tfp, syntax, allow_unknown);
	if (step->package_URL_argument == NULL) return NULL;
	Str::copy(S, mr.exp[0]);

@<Make consistency checks@> =
	if (step->step_stage == NULL) {
		PipelineErrors::syntax_with(tfp, syntax, "no such stage as '%S'", S);
		return NULL;
	}
	if (step->step_stage->takes_repository) {
		if (left_arrow_used == FALSE) {
			PipelineErrors::syntax(tfp, syntax,
				"this stage should take a left arrow and a source");
			return NULL;
		}
	} else {
		if (left_arrow_used) {
			PipelineErrors::syntax(tfp, syntax,
				"this stage should not take a left arrow and a source");
			return NULL;
		}
	}

@ A textual argument beginning with an asterisk means "expand to the value of
this variable", which is required to exist unless |allow_unknown| is set.
If it is, then an empty text results as the argument.

=
text_stream *ParsingPipelines::text_arg(text_stream *from, dictionary *D,
	text_file_position *tfp, text_stream *syntax, int allow_unknown) {
	if (Str::get_first_char(from) == '*') {
		text_stream *find = Dictionaries::get_text(D, from);
		if (find) return Str::duplicate(find);
		if (allow_unknown == FALSE) {
			PipelineErrors::syntax_with(tfp, syntax,
				"no such pipeline variable as '%S'", from);
		} else {
			return I"";
		}
	}
	return Str::duplicate(from);
}

@h Stages.
Stages are a fixed set within this compiler: there's no way for a pipeline
file to specify a new one.

=
pipeline_stage *ParsingPipelines::parse_stage(text_stream *from) {
	static int stages_made = FALSE;
	if (stages_made == FALSE) {
		stages_made = TRUE;
		SimpleStages::create_pipeline_stages();
		CodeGen::create_pipeline_stage();
		NewStage::create_pipeline_stage();
		LoadBinaryKitsStage::create_pipeline_stage();
		CompileSplatsStage::create_pipeline_stage();
		DetectIndirectCallsStage::create_pipeline_stage();
		EliminateRedundantMatterStage::create_pipeline_stage();
		ConnectPlugsStage::create_pipeline_stage();
		EliminateRedundantLabelsStage::create_pipeline_stage();
		EliminateRedundantOperationsStage::create_pipeline_stage();
		MakeSynopticModuleStage::create_pipeline_stage();
		ParsingStages::create_pipeline_stage();
		ResolveConditionalsStage::create_pipeline_stage();
		ReconcileVerbsStage::create_pipeline_stage();
		MakeIdentifiersUniqueStage::create_pipeline_stage();
	}	
	pipeline_stage *stage;
	LOOP_OVER(stage, pipeline_stage)
		if (Str::eq(from, stage->stage_name))
			return stage;
	return NULL;
}

@h Starting a variables dictionary.
Note that the above ways to create a pipeline all expect a dictionary of variable
names and their values to exist. These dictionaries are typically very small,
and by convention the main variable is |*out|, the leafname to write output to.
So the following utility is convenient for getting started.

=
dictionary *ParsingPipelines::basic_dictionary(text_stream *leafname) {
	dictionary *D = Dictionaries::new(16, TRUE);
	if (Str::len(leafname) > 0) Str::copy(Dictionaries::create_text(D, I"*out"), leafname);
	Str::copy(Dictionaries::create_text(D, I"*log"), I"*log");
	return D;
}

@h Back to text.
Here we write a textual description to a string, which is useful for logging:

=
void ParsingPipelines::write_step(OUTPUT_STREAM, pipeline_step *step) {
	WRITE("%S", step->step_stage->stage_name);
	if (step->step_stage->stage_arg != NO_STAGE_ARG) {
		if (step->repository_argument > 0) {
			WRITE(" %d", step->repository_argument);
			if (Str::len(step->package_URL_argument) > 0)
				WRITE(":%S", step->package_URL_argument);
		} else {
			if (Str::len(step->package_URL_argument) > 0)
				WRITE(" %S", step->package_URL_argument);
		}
		if (step->step_stage->takes_repository)
			WRITE(" <- %S", step->step_argument);
		if (step->generator_argument)
			WRITE(" %S -> %S",
				step->generator_argument->generator_name, step->step_argument);
	}
}
