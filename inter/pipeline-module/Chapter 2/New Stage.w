[NewStage::] New Stage.

This stage takes an empty tree and equips it with just the absolute basics, so
that it is ready to have substantive material added at a later stage.

@ =
void NewStage::create_pipeline_stage(void) {
	ParsingPipelines::new_stage(I"new", NewStage::run, NO_STAGE_ARG, FALSE);
}

int NewStage::run(pipeline_step *step) {
	inter_tree *I = step->ephemera.tree;
	LargeScale::begin_new_tree(I);
	LargeScale::make_architectural_definitions(I, PipelineModule::get_architecture());
	return TRUE;
}
