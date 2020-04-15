[Inform6Skill::] Inform6 Skill.

The skill of compiling Inform 6 into a story file for the target VM.

@ This can only be performed via the shell, as the Inform 6 compiler is never
part of the executables of the more modern Inform tools, and so can't be
called as a function.

=
build_skill *compile_using_inform6_skill = NULL;

void Inform6Skill::create(void) {
	compile_using_inform6_skill =
		BuildSteps::new_skill(I"compile using inform6");
	METHOD_ADD(compile_using_inform6_skill, BUILD_SKILL_COMMAND_MTID,
		Inform6Skill::inform6_via_shell);
}

int Inform6Skill::inform6_via_shell(build_skill *skill, build_step *S,
	text_stream *command, build_methodology *BM) {
	Shell::quote_file(command, BM->to_inform6);

	inform_project *project = ProjectBundleManager::from_copy(S->associated_copy);
	if (project == NULL) project = ProjectFileManager::from_copy(S->associated_copy);
	if (project == NULL) internal_error("no project");
	
	pathname *build = Pathnames::down(project->as_copy->location_if_path, I"Build");
	filename *inf_F = Filenames::in(build, I"auto.inf");

	WRITE_TO(command, "-kE2S");
	if (TargetVMs::debug_enabled((S->for_vm))) WRITE_TO(command, "D");
	text_stream *ext = TargetVMs::get_unblorbed_extension(S->for_vm);
	if (Str::eq(ext, I"ulx")) ext = I"G";
	WRITE_TO(command, "w%S ", ext);

	Shell::quote_file(command, inf_F);
	Shell::quote_file(command, S->vertex->as_file);
	return TRUE;
}
