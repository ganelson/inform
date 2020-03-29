[InterSkill::] Inter Skill.

A build step is a task such as running inform7 or inblorb on some file.

@ =
build_skill *assimilate_using_inter_skill = NULL;
build_skill *code_generate_using_inter_skill = NULL;

void InterSkill::create(void) {
	assimilate_using_inter_skill = BuildSteps::new_skill(I"assimilate using inter");
	METHOD_ADD(assimilate_using_inter_skill, BUILD_SKILL_COMMAND_MTID, InterSkill::assimilate_via_shell);
	METHOD_ADD(assimilate_using_inter_skill, BUILD_SKILL_INTERNAL_MTID, InterSkill::assimilate_internally);
	code_generate_using_inter_skill = BuildSteps::new_skill(I"code generate using inter");
	METHOD_ADD(code_generate_using_inter_skill, BUILD_SKILL_INTERNAL_MTID, InterSkill::code_generate_internally);
}

int InterSkill::assimilate_via_shell(build_skill *skill, build_step *S, text_stream *command, build_methodology *meth) {
	inter_architecture *A = S->for_arch;
	if (A == NULL) internal_error("no architecture given");
	pathname *kit_path = S->associated_copy->location_if_path;
	Shell::quote_file(command, meth->to_inter);
	WRITE_TO(command, "-architecture %S ", Architectures::to_codename(A));
	WRITE_TO(command, "-assimilate ");
	Shell::quote_path(command, kit_path);
	return TRUE;
}

int InterSkill::assimilate_internally(build_skill *skill, build_step *S, build_methodology *meth) {
	#ifdef CODEGEN_MODULE
	inter_architecture *A = S->for_arch;
	if (A == NULL) internal_error("no architecture given");

	pathname *kit_path = S->associated_copy->location_if_path;
	dictionary *pipeline_vars = CodeGen::Pipeline::basic_dictionary(I"output.i6");

	inbuild_requirement *req =
		Requirements::any_version_of(Works::new(pipeline_genre, I"assimilate.interpipeline", NULL));
	inbuild_search_result *R = Nests::search_for_best(req, Inbuild::nest_list());
	if (R == NULL) {
		Errors::nowhere("assimilate pipeline could not be found");
		return FALSE;
	}
	filename *pipeline_as_file = R->copy->location_if_file;

	filename *assim = Architectures::canonical_binary(kit_path, A);
	filename *assim_t = Architectures::canonical_textual(kit_path, A);
	TEMPORARY_TEXT(fullname);
	WRITE_TO(fullname, "%f", assim);
	Str::copy(Dictionaries::create_text(pipeline_vars, I"*out"), fullname);
	Str::clear(fullname);
	WRITE_TO(fullname, "%f", assim_t);
	Str::copy(Dictionaries::create_text(pipeline_vars, I"*outt"), fullname);
	DISCARD_TEXT(fullname);
	Str::copy(Dictionaries::create_text(pipeline_vars, I"*attach"), Pathnames::directory_name(kit_path));

	linked_list *inter_paths = NEW_LINKED_LIST(pathname);
	ADD_TO_LINKED_LIST(S->associated_copy->location_if_path, pathname, inter_paths);
	codegen_pipeline *SS = CodeGen::Pipeline::parse_from_file(pipeline_as_file, pipeline_vars);
	if (SS) {
		linked_list *requirements_list = NEW_LINKED_LIST(inter_library);
		CodeGen::Pipeline::run(NULL, SS, inter_paths, requirements_list);
		return TRUE;
	} else {
		Errors::nowhere("assimilate pipeline could not be parsed");
		return FALSE;
	}
	#endif
	return FALSE;
}

int InterSkill::code_generate_internally(build_skill *skill, build_step *S, build_methodology *meth) {
	#ifdef CODEGEN_MODULE
	clock_t back_end = clock();
	CodeGen::Architecture::set(
		Architectures::to_codename(
			TargetVMs::get_architecture(S->for_vm)));
	Str::copy(Dictionaries::create_text(pipeline_vars, I"*in"), I"*memory");
	Str::copy(Dictionaries::create_text(pipeline_vars, I"*out"),
		Filenames::get_leafname(S->vertex->buildable_if_internal_file));
	
	filename *F = inter_pipeline_file;
	if (F == NULL) {
		inbuild_requirement *req =
			Requirements::any_version_of(Works::new(pipeline_genre, inter_pipeline_name, NULL));
		inbuild_search_result *R = Nests::search_for_best(req, Inbuild::nest_list());
		if (R == NULL) {
			Errors::with_text("inter pipeline '%S' could not be found", inter_pipeline_name);
			return FALSE;
		}
		F = R->copy->location_if_file;
	}
	codegen_pipeline *SS = CodeGen::Pipeline::parse_from_file(F, pipeline_vars);
	if (SS == NULL) {
		Errors::nowhere("inter pipeline file could not be parsed");
		return FALSE;
	}
	CodeGen::Pipeline::set_repository(SS, Emit::tree());
	CodeGen::Pipeline::run(Filenames::get_path_to(S->vertex->buildable_if_internal_file),
		SS, Kits::inter_paths(), Projects::list_of_inter_libraries(Inbuild::project()));
	LOG("Back end elapsed time: %dcs\n", ((int) (clock() - back_end)) / (CLOCKS_PER_SEC/100));
	return TRUE;
	#endif
	#ifndef CORE_MODULE
	return FALSE;
	#endif
}
