[InblorbSkill::] Inblorb Skill.

A build step is a task such as running inform7 or inblorb on some file.

@ =
build_skill *package_using_inblorb_skill = NULL;

void InblorbSkill::create(void) {
	package_using_inblorb_skill = BuildSteps::new_skill(I"package using inblorb");
	METHOD_ADD(package_using_inblorb_skill, BUILD_SKILL_COMMAND_MTID, InblorbSkill::inblorb_via_shell);
}

int InblorbSkill::inblorb_via_shell(build_skill *skill, build_step *S, text_stream *command, build_methodology *meth) {
	if (command == NULL) internal_error("not available in-app");
	WRITE_TO(command, "echo 'Not done yet'");
	return TRUE;
}
