[Inform7Skill::] Inform7 Skill.

The skill of turning source text into Inter code.

@ This skill can be performed externally with a shell command to |inform7|, or,
if we are running inside |inform7| anyway, internally with a function call.

=
build_skill *compile_using_inform7_skill = NULL;

void Inform7Skill::create(void) {
	compile_using_inform7_skill =
		BuildSteps::new_skill(I"compile using inform7");
	METHOD_ADD(compile_using_inform7_skill, BUILD_SKILL_COMMAND_MTID,
		Inform7Skill::inform7_via_shell);
	METHOD_ADD(compile_using_inform7_skill, BUILD_SKILL_INTERNAL_MTID,
		Inform7Skill::inform7_internally);
}

int Inform7Skill::inform7_via_shell(build_skill *skill, build_step *S,
	text_stream *command, build_methodology *BM) {
	inform_project *project = ProjectBundleManager::from_copy(S->associated_copy);
	if (project == NULL) project = ProjectFileManager::from_copy(S->associated_copy);
	if (project == NULL) internal_error("no project");

	Shell::quote_file(command, BM->to_inform7);

	kit_dependency *kd;
	LOOP_OVER_LINKED_LIST(kd, kit_dependency, project->kits_to_include)
		WRITE_TO(command, "-kit %S ", kd->kit->as_copy->edition->work->title);

	WRITE_TO(command, "-format=%S ", TargetVMs::get_unblorbed_extension(S->for_vm));

	inbuild_nest *N;
	LOOP_OVER_LINKED_LIST(N, inbuild_nest, S->search_path) {
		switch (Nests::get_tag(N)) {
			case MATERIALS_NEST_TAG: continue;
			case EXTERNAL_NEST_TAG: WRITE_TO(command, "-external "); break;
			case GENERIC_NEST_TAG: WRITE_TO(command, "-nest "); break;
			case INTERNAL_NEST_TAG: WRITE_TO(command, "-internal "); break;
			default: internal_error("mystery nest");
		}
		Shell::quote_path(command, N->location);
	}

	WRITE_TO(command, "-project ");
	Shell::quote_path(command, S->associated_copy->location_if_path);
	return TRUE;
}

int Inform7Skill::inform7_internally(build_skill *skill, build_step *S, build_methodology *BM) {
	#ifdef CORE_MODULE
	return Task::carry_out(S);
	#endif
	#ifndef CORE_MODULE
	return FALSE;
	#endif
}
