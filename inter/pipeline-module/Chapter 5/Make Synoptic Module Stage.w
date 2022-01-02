[MakeSynopticModuleStage::] Make Synoptic Module Stage.

Creating a top-level module of synoptic resources.

@ 

=
void MakeSynopticModuleStage::create_pipeline_stage(void) {
	ParsingPipelines::new_stage(I"make-synoptic-module",
		MakeSynopticModuleStage::run, NO_STAGE_ARG, FALSE);
}

int MakeSynopticModuleStage::run(pipeline_step *step) {
	inter_tree *I = step->ephemera.repository;
	tree_inventory *inv = Synoptic::inv(I);

	SynopticText::compile(I, step, inv);
	SynopticActions::compile(I, step, inv);
	SynopticActivities::compile(I, step, inv);
	SynopticChronology::compile(I, step, inv);
	SynopticExtensions::compile(I, step, inv);
	SynopticInstances::compile(I, step, inv);
	SynopticKinds::compile(I, step, inv);
	SynopticMultimedia::compile(I, step, inv);
	SynopticProperties::compile(I, step, inv);
	SynopticRelations::compile(I, step, inv);
	SynopticResponses::compile(I, step, inv);
	SynopticRules::compile(I, step, inv);
	SynopticScenes::compile(I, step, inv);
	SynopticTables::compile(I, step, inv);
	SynopticUseOptions::compile(I, step, inv);
	SynopticVerbs::compile(I, step, inv);
	SynopticTests::compile(I, step, inv);
	return TRUE;
}
