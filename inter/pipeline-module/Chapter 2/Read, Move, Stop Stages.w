[SimpleStages::] Read, Move, Stop Stages.

Four simple pipeline stages.

@ =
void SimpleStages::create_pipeline_stages(void) {
	ParsingPipelines::new_stage(I"stop", SimpleStages::run_stop_stage, NO_STAGE_ARG, FALSE);
	ParsingPipelines::new_stage(I"read", SimpleStages::run_read_stage, FILE_STAGE_ARG, TRUE);
	ParsingPipelines::new_stage(I"move", SimpleStages::run_move_stage, GENERAL_STAGE_ARG, TRUE);
}

@h Read.

=
int SimpleStages::run_read_stage(pipeline_step *step) {
	filename *F = step->ephemera.parsed_filename;
	if (BinaryInter::test_file(F)) BinaryInter::read(step->ephemera.tree, F);
	else TextualInter::read(step->ephemera.tree, F);
	return TRUE;
}

@h Move.

=
int SimpleStages::run_move_stage(pipeline_step *step) {
	match_results mr = Regexp::create_mr();
	inter_package *pack = NULL;
	if (Regexp::match(&mr, step->step_argument, U"(%d):(%c+)")) {
		int from_rep = Str::atoi(mr.exp[0], 0);
		if (step->ephemera.pipeline->ephemera.trees[from_rep] == NULL) {
			PipelineErrors::error_with(step, "there is no Inter tree in slot %S", mr.exp[0]);
			return FALSE;
		}
		pack = InterPackage::from_URL(
			step->ephemera.pipeline->ephemera.trees[from_rep], mr.exp[1]);
		if (pack == NULL) {
			PipelineErrors::error_with(step, "that tree has no such package as '%S'", mr.exp[1]);
			return FALSE;
		}
	} else {
		PipelineErrors::error_with(step,
			"destination should take the form 'N:URL', not '%S'", mr.exp[1]);
		return FALSE;
	}
	Regexp::dispose_of(&mr);
	Transmigration::move(pack, LargeScale::main_package(step->ephemera.tree), FALSE);
	return TRUE;
}

@h Stop.
The "stop" stage is special, in that it always returns false, thus stopping
the pipeline:

=
int SimpleStages::run_stop_stage(pipeline_step *step) {
	return FALSE;
}
