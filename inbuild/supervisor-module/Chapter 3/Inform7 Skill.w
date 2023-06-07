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
	text_stream *command, build_methodology *BM, linked_list *search_list) {
	inform_project *project = Projects::from_copy(S->associated_copy);
	if (project == NULL) internal_error("no project");

	Shell::quote_file(command, BM->to_inform7);

	WRITE_TO(command, "-format=%S ", TargetVMs::get_full_format_text(S->for_vm));

	inbuild_nest *N;
	linked_list *L = Projects::nest_list(project);
	LOOP_OVER_LINKED_LIST(N, inbuild_nest, L) {
		switch (Nests::get_tag(N)) {
			case MATERIALS_NEST_TAG: continue;
			case EXTENSION_NEST_TAG: continue;
			case EXTERNAL_NEST_TAG:
				if (Nests::is_deprecated(N)) WRITE_TO(command, "-deprecated-external ");
				else WRITE_TO(command, "-external ");
				break;
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

@ Note that we create the Materials folder in the file system if it doesn't
already exist, but only for projects in bundles. (If we did this for projects
in single files, the result would be that batch-testing Inform via //intest//
would create thousands of unwanted folders. Still, it's a slightly arbitrary
way to do things. The UI apps for Inform tend to create missing Materials
folders anyway; maybe we should leave well be.)

=
int Inform7Skill::inform7_internally(build_skill *skill, build_step *S,
	build_methodology *BM, linked_list *search_list) {
	inform_project *project = Projects::from_copy(S->associated_copy);
	if (project == NULL) internal_error("no project");

	if (S->associated_copy->edition->work->genre == project_bundle_genre)
		Pathnames::create_in_file_system(Projects::materials_path(project));
	#ifdef CORE_MODULE
	return Task::carry_out(S);
	#endif
	#ifndef CORE_MODULE
	return FALSE;
	#endif
}
