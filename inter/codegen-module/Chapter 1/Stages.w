[CodeGen::Stage::] Stages.

To create the stages through which code generation proceeds.

@h Stages.
Each possible pipeline stage is represented by a single instance of the
following. Some stages are invoked with an argument, often the filename to
write output to; others are not.

@e NO_STAGE_ARG from 1
@e FILE_STAGE_ARG
@e TEXT_OUT_STAGE_ARG
@e TEMPLATE_FILE_STAGE_ARG

=
typedef struct pipeline_stage {
	struct text_stream *stage_name;
	int (*execute)(void *);
	int port_direction;
	int stage_arg; /* one of the |*_ARG| values above */
	MEMORY_MANAGEMENT
} pipeline_stage;

pipeline_stage *CodeGen::Stage::new(text_stream *name, int (*X)(struct stage_step *), int arg) {
	pipeline_stage *stage = CREATE(pipeline_stage);
	stage->stage_name = Str::duplicate(name);
	stage->execute = (int (*)(void *)) X;
	stage->port_direction = 0;
	stage->stage_arg = arg;
	return stage;
}

@ Supplying this as the execute routine for a stage marks it as disabled.

=
int CodeGen::Stage::stage_disabled(stage_step *step) {
	WRITE_TO(step->text_out_file, "Currently disabled\n");
	return TRUE;
}

@h Creation.
To add a new pipeline stage, put the code for it into a new section in
Chapter 2, and then add a call to its |create_pipeline_stage| routine
to the routine below.

=
int stages_made = FALSE;
void CodeGen::Stage::make_stages(void) {
	if (stages_made == FALSE) {
		stages_made = TRUE;
		CodeGen::Stage::new(I"stop", CodeGen::Stage::run_stop_stage, NO_STAGE_ARG);

		CodeGen::Stage::new(I"show-dependencies", CodeGen::Stage::run_show_dependencies_stage, TEXT_OUT_STAGE_ARG);
		CodeGen::Stage::new(I"log-dependencies", CodeGen::Stage::run_log_dependencies_stage, NO_STAGE_ARG);
		CodeGen::Stage::new(I"generate-inter", CodeGen::Stage::run_generate_inter_stage, TEXT_OUT_STAGE_ARG);
		CodeGen::Stage::new(I"generate-inter-binary", CodeGen::Stage::run_generate_inter_binary_stage, FILE_STAGE_ARG);
		CodeGen::Stage::new(I"summarise", CodeGen::Stage::run_summarise_stage, TEXT_OUT_STAGE_ARG);
		pipeline_stage *ex = CodeGen::Stage::new(I"export", CodeGen::Stage::stage_disabled, TEXT_OUT_STAGE_ARG);
		ex->port_direction = 1;

		CodeGen::create_pipeline_stage();
		CodeGen::Assimilate::create_pipeline_stage();
		CodeGen::Eliminate::create_pipeline_stage();
		CodeGen::Externals::create_pipeline_stage();
		CodeGen::Import::create_pipeline_stage();
		CodeGen::Inventory::create_pipeline_stage();
		CodeGen::Link::create_pipeline_stage();
		CodeGen::PLM::create_pipeline_stage();
		CodeGen::RCC::create_pipeline_stage();
		CodeGen::ReconcileVerbs::create_pipeline_stage();
		CodeGen::Uniqueness::create_pipeline_stage();
	}	
}

@ The "stop" stage is special, in that it always returns false, thus stopping
the pipeline:

=
int CodeGen::Stage::run_stop_stage(stage_step *step) {
	return FALSE;
}

@ The remaining stages declared here are all just wrappers for features of the
Inter module. (It doesn't seem worth making 10-line sections for each of them.)

=
int CodeGen::Stage::run_show_dependencies_stage(stage_step *step) {
	Inter::Graph::show_dependencies(step->text_out_file, step->repository);
	return TRUE;
}

int CodeGen::Stage::run_log_dependencies_stage(stage_step *step) {
	Inter::Graph::show_dependencies(DL, step->repository);
	return TRUE;
}

int CodeGen::Stage::run_generate_inter_stage(stage_step *step) {
	Inter::Textual::write(step->text_out_file, step->repository, NULL, 1);
	return TRUE;
}

int CodeGen::Stage::run_generate_inter_binary_stage(stage_step *step) {
	Inter::Binary::write(step->parsed_filename, step->repository);
	return TRUE;
}

int CodeGen::Stage::run_summarise_stage(stage_step *step) {
	Inter::Summary::write(step->text_out_file, step->repository);
	return TRUE;
}
