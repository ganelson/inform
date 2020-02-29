[InblorbSkill::] Inblorb Skill.

A build step is a task such as running inform7 or inblorb on some file.

@ =
build_skill *package_using_inblorb_skill = NULL;

void InblorbSkill::create(void) {
	package_using_inblorb_skill = BuildSteps::new_skill(I"package using inblorb");
	METHOD_ADD(package_using_inblorb_skill, BUILD_SKILL_COMMAND_MTID, InblorbSkill::inblorb_via_shell);
}

int InblorbSkill::inblorb_via_shell(build_skill *skill, build_step *S, text_stream *command, build_methodology *meth) {
	inform_project *project = ProjectBundleManager::from_copy(S->associated_copy);
	if (project == NULL) project = ProjectFileManager::from_copy(S->associated_copy);
	if (project == NULL) internal_error("no project");

	Shell::quote_file(command, meth->to_inblorb);
	filename *blurb = Filenames::in_folder(S->associated_copy->location_if_path, I"Release.blurb");
	Shell::quote_file(command, blurb);
	Shell::quote_file(command, S->vertex->buildable_if_internal_file);
	return TRUE;
}
