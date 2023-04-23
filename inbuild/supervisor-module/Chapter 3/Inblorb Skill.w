[InblorbSkill::] Inblorb Skill.

The skill of packaging a story file and associated resources into a blorb.

@ =
build_skill *package_using_inblorb_skill = NULL;

void InblorbSkill::create(void) {
	package_using_inblorb_skill =
		BuildSteps::new_skill(I"package using inblorb");
	METHOD_ADD(package_using_inblorb_skill, BUILD_SKILL_COMMAND_MTID,
		InblorbSkill::inblorb_via_shell);
}

int InblorbSkill::inblorb_via_shell(build_skill *skill, build_step *S,
	text_stream *command, build_methodology *BM, linked_list *search_list) {
	inform_project *project = Projects::from_copy(S->associated_copy);
	if (project == NULL) internal_error("no project");

	Shell::quote_file(command, BM->to_inblorb);
	filename *blurb = Filenames::in(S->associated_copy->location_if_path,
		I"Release.blurb");
	Shell::quote_file(command, blurb);
	Shell::quote_file(command, S->vertex->as_file);
	return TRUE;
}
