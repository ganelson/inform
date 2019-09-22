[CodeGen::Architecture::] Architecture.

To deal with multiple inter architectures.

@h Architectures.
These are simply enumerated, for now.

@e NO_ARCHITECTURE from 0
@e A_16_ARCHITECTURE
@e A_16D_ARCHITECTURE
@e A_32_ARCHITECTURE
@e A_32D_ARCHITECTURE

=
int current_architecture = NO_ARCHITECTURE;
int CodeGen::Architecture::set(text_stream *name) {
	int setting = NO_ARCHITECTURE;
	if (Str::eq_insensitive(name, I"16")) setting = A_16_ARCHITECTURE;
	if (Str::eq_insensitive(name, I"32")) setting = A_32_ARCHITECTURE;
	if (Str::eq_insensitive(name, I"16d")) setting = A_16D_ARCHITECTURE;
	if (Str::eq_insensitive(name, I"32d")) setting = A_32D_ARCHITECTURE;
	if (setting == NO_ARCHITECTURE) return FALSE;
	current_architecture = setting;
	return TRUE;
}

text_stream *CodeGen::Architecture::leafname(void) {
	switch (current_architecture) {
		case A_16_ARCHITECTURE: return I"arch-16";
		case A_16D_ARCHITECTURE: return I"arch-16d";
		case A_32_ARCHITECTURE: return I"arch-32";
		case A_32D_ARCHITECTURE: return I"arch-32d";
	}
	return NULL;
}

@h Prepare stage.

=
void CodeGen::Architecture::create_pipeline_stage(void) {
	CodeGen::Stage::new(I"prepare", CodeGen::Architecture::run_prepare_stage, GENERAL_STAGE_ARG, TRUE);
}

int CodeGen::Architecture::run_prepare_stage(pipeline_step *step) {
	switch (current_architecture) {
		case NO_ARCHITECTURE: internal_error("no architecture set");
		case A_16_ARCHITECTURE: return CodeGen::Architecture::run_prepare_stage_inner(step, TRUE, FALSE);
		case A_16D_ARCHITECTURE: return CodeGen::Architecture::run_prepare_stage_inner(step, TRUE, TRUE);
		case A_32_ARCHITECTURE: return CodeGen::Architecture::run_prepare_stage_inner(step, FALSE, FALSE);
		case A_32D_ARCHITECTURE: return CodeGen::Architecture::run_prepare_stage_inner(step, FALSE, TRUE);
	}
	return FALSE;
}

int CodeGen::Architecture::run_prepare_stage_inner(pipeline_step *step, int Z, int D) {
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
	
	if (Str::ne(step->step_argument, I"none")) {
		inter_package *template_p = NULL;
		Inter::Package::new_package_named(&in_main, step->step_argument, FALSE, module_name, 1, NULL, &template_p);
		Site::set_assimilation_package(I, template_p);
	}

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
