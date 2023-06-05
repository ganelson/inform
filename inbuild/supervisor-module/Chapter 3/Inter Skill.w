[InterSkill::] Inter Skill.

The skills of kit building and of code generation from Inter.

@h Creation.
Note that code generation can only be done internally, and only in fact within
the |inform7| compiler: this is because the Inter code which it generates from
is being held in memory by |inform7|.

=
build_skill *build_kit_using_inter_skill = NULL;
build_skill *code_generate_using_inter_skill = NULL;

void InterSkill::create(void) {
	build_kit_using_inter_skill =
		BuildSteps::new_skill(I"build kit using inter");
	METHOD_ADD(build_kit_using_inter_skill, BUILD_SKILL_COMMAND_MTID,
		InterSkill::build_kit_via_shell);
	METHOD_ADD(build_kit_using_inter_skill, BUILD_SKILL_INTERNAL_MTID,
		InterSkill::build_kit_internally);

	code_generate_using_inter_skill =
		BuildSteps::new_skill(I"code generate using inter");
	METHOD_ADD(code_generate_using_inter_skill, BUILD_SKILL_INTERNAL_MTID,
		InterSkill::code_generate_internally);
}

@h Assimilation.

=
int InterSkill::build_kit_via_shell(build_skill *skill, build_step *S,
	text_stream *command, build_methodology *BM, linked_list *search_list) {
	inter_architecture *A = S->for_arch;
	if (A == NULL) internal_error("no architecture given");
	pathname *kit_path = S->associated_copy->location_if_path;
	Shell::quote_file(command, BM->to_inter);
	WRITE_TO(command, "-architecture %S ", Architectures::to_codename(A));
	WRITE_TO(command, "-build-kit ");
	Shell::quote_path(command, kit_path);
	return TRUE;
}

@ Something to watch out for here is that, when running internally as part of
|inform7|, we use the copy of the |build-kit| pipeline inside the installation
of |inform7| (it will be in the internal nest). When we build kits from the
command line using the |inter| tool, we use the |build-kit| pipeline supplied
in the |inter| installation. But those two files are in fact the same, or
should be, so the effect is the same.

=
int echo_kit_building = FALSE;
void InterSkill::echo_kit_building(void) {
	echo_kit_building = TRUE;
}

int InterSkill::build_kit_internally(build_skill *skill, build_step *S,
	build_methodology *BM, linked_list *search_list) {
	#ifdef PIPELINE_MODULE
	inter_architecture *A = S->for_arch;
	if (A == NULL) internal_error("no architecture given");

	pathname *kit_path = S->associated_copy->location_if_path;
	dictionary *pipeline_vars = ParsingPipelines::basic_dictionary(NULL);
	filename *pipeline_as_file =
		InterSkill::filename_of_pipeline(I"build-kit", search_list);
	if (pipeline_as_file == NULL) {
		Errors::nowhere("build-kit pipeline could not be found");
		return FALSE;
	}
	
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

	inter_pipeline *SS =
		ParsingPipelines::from_file(pipeline_as_file, pipeline_vars, search_list);
	if (SS) {
		inter_architecture *saved_A = PipelineModule::get_architecture();
		PipelineModule::set_architecture_to(A);
		if (echo_kit_building)
			WRITE_TO(STDOUT, "(Building %S for architecture %S)\n",
				S->associated_copy->edition->work->title,
				Architectures::to_codename(A));
		#ifdef CORE_MODULE
		SourceProblems::kit_notification(S->associated_copy->edition->work->title,
			Architectures::to_codename(A));
		#endif
		linked_list *requirements_list = NEW_LINKED_LIST(attachment_instruction);
		I6Errors::reset_count();
		RunningPipelines::run(NULL, SS, NULL, S->associated_copy->location_if_path,
			requirements_list, S->for_vm, FALSE);
		PipelineModule::set_architecture_to(saved_A);
		#ifdef CORE_MODULE
		SourceProblems::kit_notification(NULL, NULL);
		#endif
		return (I6Errors::errors_occurred())?FALSE:TRUE;
	} else {
		Errors::nowhere("build-kit pipeline could not be parsed");
		return FALSE;
	}
	#endif
	return FALSE;
}

filename *InterSkill::filename_of_pipeline(text_stream *name, linked_list *search_list) {
	inbuild_requirement *req =
		Requirements::any_version_of(
			Works::new(pipeline_genre, name, NULL));
	inbuild_search_result *R = Nests::search_for_best(req, search_list);
	if (R == NULL) return NULL;
	return R->copy->location_if_file;
}

@h Code generation.
This can only be done internally, for reasons given above, and only when the
//pipeline// module is present in the current executable (which in practice means:
only inside //inform7//).

Recall that the |inter_pipeline_name| is managed in Inbuild Control, but that
it defaults to |compile|.

=
inform_project *interskill_associated_project = NULL;
int interskill_debugging_flag = FALSE;

int InterSkill::code_generate_internally(build_skill *skill, build_step *S,
	build_methodology *BM, linked_list *search_list) {
	inform_project *project = Projects::from_copy(S->associated_copy);
	if (project == NULL) internal_error("no project");
	#ifdef PIPELINE_MODULE
	clock_t back_end = clock();
	interskill_associated_project = project;
	PipelineModule::set_architecture(
		Architectures::to_codename(
			TargetVMs::get_architecture(S->for_vm)));
	Str::copy(Dictionaries::create_text(pipeline_vars, I"*in"), I"*memory");
	Str::copy(Dictionaries::create_text(pipeline_vars, I"*out"),
		Filenames::get_leafname(S->vertex->as_file));
	if (interskill_debugging_flag)
		Str::copy(Dictionaries::create_text(pipeline_vars, I"*tout"), I"*log");
	
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
	inter_pipeline *pipeline = ParsingPipelines::from_file(F, pipeline_vars, search_list);
	if (pipeline == NULL) {
		Errors::nowhere("inter pipeline file could not be parsed");
		return FALSE;
	}
	RunningPipelines::run(Filenames::up(S->vertex->as_file), pipeline, Emit::tree(), NULL,
		Projects::list_of_attachment_instructions(project), S->for_vm, FALSE);

	LOG("Back end elapsed time: %dcs\n",
		((int) (clock() - back_end)) / ((int) (CLOCKS_PER_SEC/100)));
	#ifdef CORE_MODULE
	Hierarchy::log();
	return TRUE;
	#endif
	#endif
	#ifndef CORE_MODULE
	return FALSE;
	#endif
	interskill_associated_project = NULL;
}

inform_project *InterSkill::get_associated_project(void) {
	return interskill_associated_project;
}

void InterSkill::set_debugging(void) {
	interskill_debugging_flag = TRUE;
}
