[InterSkill::] Inter Skill.

The skills of kit assimilation and of code generation from Inter.

@h Creation.
Note that code generation can only be done internally, and only in fact within
the |inform7| compiler: this is because the Inter code which it generates from
is being held in memory by |inform7|.

=
build_skill *assimilate_using_inter_skill = NULL;
build_skill *code_generate_using_inter_skill = NULL;

void InterSkill::create(void) {
	assimilate_using_inter_skill =
		BuildSteps::new_skill(I"assimilate using inter");
	METHOD_ADD(assimilate_using_inter_skill, BUILD_SKILL_COMMAND_MTID,
		InterSkill::assimilate_via_shell);
	METHOD_ADD(assimilate_using_inter_skill, BUILD_SKILL_INTERNAL_MTID,
		InterSkill::assimilate_internally);

	code_generate_using_inter_skill =
		BuildSteps::new_skill(I"code generate using inter");
	METHOD_ADD(code_generate_using_inter_skill, BUILD_SKILL_INTERNAL_MTID,
		InterSkill::code_generate_internally);
}

@h Assimilation.

=
int InterSkill::assimilate_via_shell(build_skill *skill, build_step *S,
	text_stream *command, build_methodology *BM, linked_list *search_list) {
	inter_architecture *A = S->for_arch;
	if (A == NULL) internal_error("no architecture given");
	pathname *kit_path = S->associated_copy->location_if_path;
	Shell::quote_file(command, BM->to_inter);
	WRITE_TO(command, "-architecture %S ", Architectures::to_codename(A));
	WRITE_TO(command, "-assimilate ");
	Shell::quote_path(command, kit_path);
	return TRUE;
}

@ Something to watch out for here is that, when running internally as part of
|inform7|, we use the copy of the |assimilate| pipeline inside the installation
of |inform7| (it will be in the internal nest). When we perform assimilation
from the command line using the |inter| tool, we use the |assimilate| pipeline
supplied in the |inter| installation. But those two files are in fact the same,
or should be, so the effect is the same.

=
int InterSkill::assimilate_internally(build_skill *skill, build_step *S,
	build_methodology *BM, linked_list *search_list) {
	#ifdef PIPELINE_MODULE
	inter_architecture *A = S->for_arch;
	if (A == NULL) internal_error("no architecture given");

	pathname *kit_path = S->associated_copy->location_if_path;
	dictionary *pipeline_vars = CodeGen::Pipeline::basic_dictionary(NULL);
	inbuild_requirement *req =
		Requirements::any_version_of(
			Works::new(pipeline_genre, I"assimilate.interpipeline", NULL));
	inbuild_search_result *R =
		Nests::search_for_best(req, search_list);
	if (R == NULL) {
		Errors::nowhere("assimilate pipeline could not be found");
		return FALSE;
	}
	filename *pipeline_as_file = R->copy->location_if_file;

	filename *assim = Architectures::canonical_binary(kit_path, A);
	filename *assim_t = Architectures::canonical_textual(kit_path, A);
	TEMPORARY_TEXT(fullname)
	WRITE_TO(fullname, "%f", assim);
	Str::copy(Dictionaries::create_text(pipeline_vars, I"*out"), fullname);
	Str::clear(fullname);
	WRITE_TO(fullname, "%f", assim_t);
	Str::copy(Dictionaries::create_text(pipeline_vars, I"*outt"), fullname);
	DISCARD_TEXT(fullname)
	Str::copy(Dictionaries::create_text(pipeline_vars, I"*kit"),
		Pathnames::directory_name(kit_path));

	linked_list *inter_paths = NEW_LINKED_LIST(pathname);
	ADD_TO_LINKED_LIST(S->associated_copy->location_if_path, pathname, inter_paths);
	codegen_pipeline *SS =
		CodeGen::Pipeline::parse_from_file(pipeline_as_file, pipeline_vars);
	if (SS) {
		linked_list *requirements_list = NEW_LINKED_LIST(inter_library);
		CodeGen::Pipeline::run(NULL, SS, inter_paths, requirements_list, S->for_vm);
		return TRUE;
	} else {
		Errors::nowhere("assimilate pipeline could not be parsed");
		return FALSE;
	}
	#endif
	return FALSE;
}

@h Code generation.
This can only be done internally, for reasons given above, and only when the
//pipeline// module is present in the current executable (which in practice means:
only inside //inform7//).

Recall that the |inter_pipeline_name| is managed in Inbuild Control, but that
it defaults to |compile|.

=
int InterSkill::code_generate_internally(build_skill *skill, build_step *S,
	build_methodology *BM, linked_list *search_list) {
	inform_project *project = ProjectBundleManager::from_copy(S->associated_copy);
	if (project == NULL) project = ProjectFileManager::from_copy(S->associated_copy);
	if (project == NULL) internal_error("no project");
	#ifdef PIPELINE_MODULE
	clock_t back_end = clock();
	CodeGen::Architecture::set(
		Architectures::to_codename(
			TargetVMs::get_architecture(S->for_vm)));
	Str::copy(Dictionaries::create_text(pipeline_vars, I"*in"), I"*memory");
	Str::copy(Dictionaries::create_text(pipeline_vars, I"*out"),
		Filenames::get_leafname(S->vertex->as_file));
	
	filename *F = inter_pipeline_file;
	if (F == NULL) {
		inbuild_requirement *req =
			Requirements::any_version_of(
				Works::new(pipeline_genre, inter_pipeline_name, NULL));
		inbuild_search_result *R = Nests::search_for_best(req, search_list);
		if (R == NULL) {
			Errors::with_text("inter pipeline '%S' could not be found",
				inter_pipeline_name);
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
	CodeGen::Pipeline::run(Filenames::up(S->vertex->as_file),
		SS, Kits::inter_paths(Projects::nest_list(project)),
		Projects::list_of_link_instructions(project), S->for_vm);
	LOG("Back end elapsed time: %dcs\n",
		((int) (clock() - back_end)) / (CLOCKS_PER_SEC/100));
	#ifdef CORE_MODULE
	Hierarchy::log();
	return TRUE;
	#endif
	#endif
	#ifndef CORE_MODULE
	return FALSE;
	#endif
}
