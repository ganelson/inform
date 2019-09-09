[CodeGen::Stage::] Stages.

To create the stages through which code generation proceeds.

@h Stages.
Each possible pipeline stage is represented by a single instance of the
following. Some stages are invoked with an argument, often the filename to
write output to; others are not.

@e NO_STAGE_ARG from 1
@e GENERAL_STAGE_ARG
@e FILE_STAGE_ARG
@e TEXT_OUT_STAGE_ARG
@e EXT_FILE_STAGE_ARG
@e EXT_TEXT_OUT_STAGE_ARG
@e TEMPLATE_FILE_STAGE_ARG

=
typedef struct pipeline_stage {
	struct text_stream *stage_name;
	int (*execute)(void *);
	int stage_arg; /* one of the |*_ARG| values above */
	int takes_repository;
	MEMORY_MANAGEMENT
} pipeline_stage;

pipeline_stage *CodeGen::Stage::new(text_stream *name, int (*X)(struct pipeline_step *), int arg, int tr) {
	pipeline_stage *stage = CREATE(pipeline_stage);
	stage->stage_name = Str::duplicate(name);
	stage->execute = (int (*)(void *)) X;
	stage->stage_arg = arg;
	stage->takes_repository = tr;
	return stage;
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
		CodeGen::Stage::new(I"stop", CodeGen::Stage::run_stop_stage, NO_STAGE_ARG, FALSE);

		CodeGen::Stage::new(I"wipe", CodeGen::Stage::run_wipe_stage, NO_STAGE_ARG, FALSE);
		CodeGen::Stage::new(I"prepare", CodeGen::Stage::run_prepare_stage, NO_STAGE_ARG, FALSE);
		CodeGen::Stage::new(I"prepare-z", CodeGen::Stage::run_preparez_stage, NO_STAGE_ARG, FALSE);
		CodeGen::Stage::new(I"prepare-zd", CodeGen::Stage::run_preparezd_stage, NO_STAGE_ARG, FALSE);
		CodeGen::Stage::new(I"prepare-g", CodeGen::Stage::run_prepareg_stage, NO_STAGE_ARG, FALSE);
		CodeGen::Stage::new(I"prepare-gd", CodeGen::Stage::run_preparegd_stage, NO_STAGE_ARG, FALSE);
		CodeGen::Stage::new(I"read", CodeGen::Stage::run_read_stage, FILE_STAGE_ARG, TRUE);
		CodeGen::Stage::new(I"move", CodeGen::Stage::run_move_stage, GENERAL_STAGE_ARG, TRUE);

		CodeGen::create_pipeline_stage();
		CodeGen::Assimilate::create_pipeline_stage();
		CodeGen::Eliminate::create_pipeline_stage();
		CodeGen::Externals::create_pipeline_stage();
		CodeGen::Inspection::create_pipeline_stage();
		CodeGen::Labels::create_pipeline_stage();
		CodeGen::MergeTemplate::create_pipeline_stage();
		CodeGen::PLM::create_pipeline_stage();
		CodeGen::RCC::create_pipeline_stage();
		CodeGen::ReconcileVerbs::create_pipeline_stage();
		CodeGen::Uniqueness::create_pipeline_stage();
	}	
}

@ The "stop" stage is special, in that it always returns false, thus stopping
the pipeline:

=
int CodeGen::Stage::run_stop_stage(pipeline_step *step) {
	return FALSE;
}

int CodeGen::Stage::run_wipe_stage(pipeline_step *step) {
	Inter::Warehouse::wipe();
	return TRUE;
}

@

@e NO_ARCHITECTURE from 0
@e Z_ARCHITECTURE
@e ZD_ARCHITECTURE
@e G_ARCHITECTURE
@e GD_ARCHITECTURE

=
int current_architecture = NO_ARCHITECTURE;
int CodeGen::Stage::set_architecture(text_stream *name) {
	int setting = NO_ARCHITECTURE;
	if (Str::eq_insensitive(name, I"z")) setting = Z_ARCHITECTURE;
	if (Str::eq_insensitive(name, I"g")) setting = G_ARCHITECTURE;
	if (Str::eq_insensitive(name, I"zd")) setting = ZD_ARCHITECTURE;
	if (Str::eq_insensitive(name, I"gd")) setting = GD_ARCHITECTURE;
	if (setting == NO_ARCHITECTURE) return FALSE;
	current_architecture = setting;
	return TRUE;
}

int CodeGen::Stage::run_prepare_stage(pipeline_step *step) {
	switch (current_architecture) {
		case NO_ARCHITECTURE: internal_error("no architecture set");
		case Z_ARCHITECTURE: return CodeGen::Stage::run_prepare_stage_inner(step, TRUE, FALSE);
		case ZD_ARCHITECTURE: return CodeGen::Stage::run_prepare_stage_inner(step, TRUE, TRUE);
		case G_ARCHITECTURE: return CodeGen::Stage::run_prepare_stage_inner(step, FALSE, FALSE);
		case GD_ARCHITECTURE: return CodeGen::Stage::run_prepare_stage_inner(step, FALSE, TRUE);
	}
	return FALSE;
}

int CodeGen::Stage::run_preparez_stage(pipeline_step *step) {
	return CodeGen::Stage::run_prepare_stage_inner(step, TRUE, FALSE);
}
int CodeGen::Stage::run_preparezd_stage(pipeline_step *step) {
	return CodeGen::Stage::run_prepare_stage_inner(step, TRUE, TRUE);
}
int CodeGen::Stage::run_prepareg_stage(pipeline_step *step) {
	return CodeGen::Stage::run_prepare_stage_inner(step, FALSE, FALSE);
}
int CodeGen::Stage::run_preparegd_stage(pipeline_step *step) {
	return CodeGen::Stage::run_prepare_stage_inner(step, FALSE, TRUE);
}

int CodeGen::Stage::run_prepare_stage_inner(pipeline_step *step, int Z, int D) {
	inter_tree *I = step->repository;
	Packaging::initialise_state(I);
	Packaging::outside_all_packages(I);
	PackageTypes::get(I, I"_plain");
	PackageTypes::get(I, I"_code");
	PackageTypes::get(I, I"_linkage");
	inter_symbol *module_name = PackageTypes::get(I, I"_module");
	PackageTypes::get(I, I"_submodule");
	PackageTypes::get(I, I"_function");
	PackageTypes::get(I, I"_action");
	PackageTypes::get(I, I"_command");
	PackageTypes::get(I, I"_property");
	PackageTypes::get(I, I"_to_phrase");
	inter_package *main_p = Site::main_package(I);
	inter_bookmark in_main = Inter::Bookmarks::at_end_of_this_package(main_p);
	inter_package *generic_p = NULL;
	Inter::Package::new_package_named(&in_main, I"generic", FALSE, module_name, 1, NULL, &generic_p);
	inter_bookmark in_generic = Inter::Bookmarks::at_end_of_this_package(generic_p);
	inter_symbol *unchecked_kind_symbol = Inter::SymbolsTables::create_with_unique_name(Inter::Bookmarks::scope(&in_generic), I"K_unchecked");
	Inter::Kind::new(&in_generic,
		Inter::SymbolsTables::id_from_symbol(I, generic_p, unchecked_kind_symbol),
		UNCHECKED_IDT,
		0,
		BASE_ICON, 0, NULL,
		(inter_t) Inter::Bookmarks::baseline(&in_generic) + 1, NULL);
	inter_symbol *typeless_int_symbol = Inter::SymbolsTables::create_with_unique_name(Inter::Bookmarks::scope(&in_generic), I"K_typeless_int");
	Inter::Kind::new(&in_generic,
		Inter::SymbolsTables::id_from_symbol(I, generic_p, typeless_int_symbol),
		INT32_IDT,
		0,
		BASE_ICON, 0, NULL,
		(inter_t) Inter::Bookmarks::baseline(&in_generic) + 1, NULL);
	inter_symbol *truth_state_kind_symbol = Inter::SymbolsTables::create_with_unique_name(Inter::Bookmarks::scope(&in_generic), I"K_truth_state");
	Inter::Kind::new(&in_generic,
		Inter::SymbolsTables::id_from_symbol(I, generic_p, truth_state_kind_symbol),
		INT2_IDT,
		0,
		BASE_ICON, 0, NULL,
		(inter_t) Inter::Bookmarks::baseline(&in_generic) + 1, NULL);
	inter_symbol *action_name_kind_symbol = Inter::SymbolsTables::create_with_unique_name(Inter::Bookmarks::scope(&in_generic), I"K_action_name");
	Inter::Kind::new(&in_generic,
		Inter::SymbolsTables::id_from_symbol(I, generic_p, action_name_kind_symbol),
		INT32_IDT,
		0,
		BASE_ICON, 0, NULL,
		(inter_t) Inter::Bookmarks::baseline(&in_generic) + 1, NULL);
	inter_t operands[2];
	operands[0] = Inter::SymbolsTables::id_from_IRS_and_symbol(&in_generic, unchecked_kind_symbol);
	operands[1] = Inter::SymbolsTables::id_from_IRS_and_symbol(&in_generic, unchecked_kind_symbol);
	inter_symbol *unchecked_function_symbol = Inter::SymbolsTables::create_with_unique_name(Inter::Bookmarks::scope(&in_generic), I"K_unchecked_function");
	Inter::Kind::new(&in_generic,
		Inter::SymbolsTables::id_from_symbol(I, generic_p, unchecked_function_symbol),
		ROUTINE_IDT,
		0,
		FUNCTION_ICON, 2, operands,
		(inter_t) Inter::Bookmarks::baseline(&in_generic) + 1, NULL);
	inter_symbol *list_of_unchecked_kind_symbol = Inter::SymbolsTables::create_with_unique_name(Inter::Bookmarks::scope(&in_generic), I"K_list_of_values");
	Inter::Kind::new(&in_generic,
		Inter::SymbolsTables::id_from_symbol(I, generic_p, list_of_unchecked_kind_symbol),
		LIST_IDT,
		0,
		LIST_ICON, 1, operands,
		(inter_t) Inter::Bookmarks::baseline(&in_generic) + 1, NULL);
	
	inter_package *template_p = NULL;
	Inter::Package::new_package_named(&in_main, I"template", FALSE, module_name, 1, NULL, &template_p);

	inter_bookmark *in_veneer = Site::veneer_booknark(I);
	inter_package *veneer_p = Inter::Packages::veneer(I);
	inter_symbol *vi_unchecked = Inter::SymbolsTables::create_with_unique_name(Inter::Bookmarks::scope(in_veneer), I"K_unchecked");
	Inter::SymbolsTables::equate(vi_unchecked, unchecked_kind_symbol);
	inter_symbol *con_name = Inter::SymbolsTables::create_with_unique_name(Inter::Bookmarks::scope(in_veneer), I"WORDSIZE");
	Inter::Constant::new_numerical(in_veneer,
		Inter::SymbolsTables::id_from_symbol(I, veneer_p, con_name),
		Inter::SymbolsTables::id_from_symbol(I, veneer_p, vi_unchecked),
		LITERAL_IVAL, (Z)?2:4,
		(inter_t) Inter::Bookmarks::baseline(in_veneer) + 1, NULL);
	inter_symbol *target_name;
	if (Z) target_name = Inter::SymbolsTables::create_with_unique_name(Inter::Bookmarks::scope(in_veneer), I"TARGET_ZCODE");
	else target_name = Inter::SymbolsTables::create_with_unique_name(Inter::Bookmarks::scope(in_veneer), I"TARGET_GLULX");
	Inter::Constant::new_numerical(in_veneer,
		Inter::SymbolsTables::id_from_symbol(I, veneer_p, target_name),
		Inter::SymbolsTables::id_from_symbol(I, veneer_p, vi_unchecked),
		LITERAL_IVAL, 1,
		(inter_t) Inter::Bookmarks::baseline(in_veneer) + 1, NULL);
	if (D) {
		inter_symbol *D_name = Inter::SymbolsTables::create_with_unique_name(Inter::Bookmarks::scope(in_veneer), I"DEBUG");
		Inter::Constant::new_numerical(in_veneer,
			Inter::SymbolsTables::id_from_symbol(I, veneer_p, D_name),
			Inter::SymbolsTables::id_from_symbol(I, veneer_p, vi_unchecked),
			LITERAL_IVAL, 1,
			(inter_t) Inter::Bookmarks::baseline(in_veneer) + 1, NULL);
	}
	inter_symbol *P_name = Inter::SymbolsTables::create_with_unique_name(Inter::Bookmarks::scope(in_veneer), I"PLUGIN_FILES");
	Inter::Constant::new_numerical(in_veneer,
		Inter::SymbolsTables::id_from_symbol(I, veneer_p, P_name),
		Inter::SymbolsTables::id_from_symbol(I, veneer_p, vi_unchecked),
		LITERAL_IVAL, 1,
		(inter_t) Inter::Bookmarks::baseline(in_veneer) + 1, NULL);
	return TRUE;
}

int CodeGen::Stage::run_read_stage(pipeline_step *step) {
	filename *F = step->parsed_filename;
	if (Inter::Binary::test_file(F)) Inter::Binary::read(step->repository, F);
	else Inter::Textual::read(step->repository, F);
	return TRUE;
}

int CodeGen::Stage::run_move_stage(pipeline_step *step) {
	match_results mr = Regexp::create_mr();
	inter_package *pack = NULL;
	if (Regexp::match(&mr, step->step_argument, L"(%d):(%c+)")) {
		int from_rep = Str::atoi(mr.exp[0], 0);
		if (step->pipeline->repositories[from_rep] == NULL)
			internal_error("no such repository");
		pack = Inter::Packages::by_url(
			step->pipeline->repositories[from_rep], mr.exp[1]);
	}
	Regexp::dispose_of(&mr);
	if (pack == NULL) internal_error("not a package");
	Inter::Transmigration::move(pack, Site::main_package(step->repository), FALSE);

	return TRUE;
}
