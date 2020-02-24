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
	linked_list *L = NEW_LINKED_LIST(inbuild_search_result);
	Nests::search_for(req, Inbuild::nest_list(), L);
	filename *pipeline_as_file = NULL;
	inbuild_search_result *R;
	LOOP_OVER_LINKED_LIST(R, inbuild_search_result, L) {
		pipeline_as_file = R->copy->location_if_file;
		break;
	}
	if (pipeline_as_file == NULL) {
		Errors::nowhere("assimilate pipeline could not be found");
		return FALSE;
	}

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
	#ifdef CORE_MODULE
	int rv = CoreMain::task2(S);
	return rv;
	#endif
	return FALSE;
}
