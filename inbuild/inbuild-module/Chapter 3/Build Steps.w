[BuildSteps::] Build Steps.

A build step is a task such as running inform7 or inblorb on some file.

@h Build steps.

@e ASSIMILATE_BSTEP from 1
@e COMPILE_I7_TO_GEN_BSTEP
@e COMPILE_GEN_TO_STORY_FILE_BSTEP
@e BLORB_STORY_FILE_BSTEP

=
typedef struct build_step {
	int what_to_do;
	struct build_vertex *vertex;
	struct linked_list *search_path; /* of |inbuild_nest| */
	struct target_vm *for_vm;
	struct inter_architecture *for_arch;
	int for_release;
	struct inbuild_copy *associated_copy;
	MEMORY_MANAGEMENT
} build_step;

@

=
build_step *BuildSteps::attach(build_vertex *vertex, int to_do, linked_list *search,
	int rel, target_vm *VM, inter_architecture *arch, inbuild_copy *assoc) {
	build_step *S = CREATE(build_step);
	S->vertex = vertex;
	S->what_to_do = to_do;
	S->search_path = search;
	S->for_vm = VM;
	S->for_arch = arch;
	if ((VM) && (arch == NULL)) S->for_arch = TargetVMs::get_architecture(VM);
	S->for_release = rel;
	S->associated_copy = assoc;
	BuildScripts::add_step(vertex->script, S);
	return S;
}

int BuildSteps::execute(build_vertex *V, build_step *S, build_methodology *meth) {
	int rv = TRUE;
	TEMPORARY_TEXT(command);
	@<Write a shell command for the step@>;
	if (rv) rv = BuildSteps::shell(command, meth);
	if (rv == FALSE) WRITE_TO(STDERR, "Build failed at '%S'\n", command);
	DISCARD_TEXT(command);
	return rv;
}

@<Write a shell command for the step@> =
	switch (S->what_to_do) {
		case ASSIMILATE_BSTEP: rv = BuildSteps::use_inter(S, command, meth); break;
		case COMPILE_I7_TO_GEN_BSTEP: rv = BuildSteps::use_inform7(S, command, meth); break;
		case COMPILE_GEN_TO_STORY_FILE_BSTEP: rv = BuildSteps::use_inform6(S, command, meth); break;
		case BLORB_STORY_FILE_BSTEP: rv = BuildSteps::use_inblorb(S, command, meth); break;
		default: rv = FALSE; Errors::nowhere("unimplemented build step"); break;
	}

@ =
int BuildSteps::shell(text_stream *command, build_methodology *meth) {
	int rv = TRUE;
	WRITE_TO(STDOUT, "%S\n", command);
	if (meth->methodology == SHELL_METHODOLOGY) rv = (Shell::run(command) == 0)?TRUE:FALSE;
	return rv;
}

@ =
int BuildSteps::use_inter(build_step *S, text_stream *command, build_methodology *meth) {
	if (command == NULL) internal_error("not available in-app");
	Shell::quote_file(command, meth->to_inter);
	WRITE_TO(command, "-architecture %S ", Architectures::to_codename(S->for_arch));
	WRITE_TO(command, "-assimilate ");
	Shell::quote_path(command, S->associated_copy->location_if_path);
	return TRUE;
}

@ =
int BuildSteps::use_inform7(build_step *S, text_stream *command, build_methodology *meth) {
	if (command == NULL) internal_error("not available in-app");
	Shell::quote_file(command, meth->to_inform7);

	inform_project *project = ProjectBundleManager::from_copy(S->associated_copy);
	if (project == NULL) project = ProjectFileManager::from_copy(S->associated_copy);
	if (project == NULL) internal_error("no project");

	inform_kit *K;
	LOOP_OVER_LINKED_LIST(K, inform_kit, project->kits_to_include) {
		WRITE_TO(command, "-kit %S ", K->as_copy->edition->work->title);
	}
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

@ =
int BuildSteps::use_inform6(build_step *S, text_stream *command, build_methodology *meth) {
	if (command == NULL) internal_error("not available in-app");
	Shell::quote_file(command, meth->to_inform6);

	inform_project *project = ProjectBundleManager::from_copy(S->associated_copy);
	if (project == NULL) project = ProjectFileManager::from_copy(S->associated_copy);
	if (project == NULL) internal_error("no project");
	
	pathname *build_folder = Pathnames::subfolder(project->as_copy->location_if_path, I"Build");
	filename *inf_F = Filenames::in_folder(build_folder, I"auto.inf");

	WRITE_TO(command, "-kE2S");
	if (TargetVMs::debug_enabled((S->for_vm))) WRITE_TO(command, "D");
	text_stream *ext = TargetVMs::get_unblorbed_extension(S->for_vm);
	if (Str::eq(ext, I"ulx")) ext = I"G";
	WRITE_TO(command, "w%S ", ext);

	Shell::quote_file(command, inf_F);
	Shell::quote_file(command, S->vertex->buildable_if_internal_file);
	return TRUE;
}

@ =
int BuildSteps::use_inblorb(build_step *S, text_stream *command, build_methodology *meth) {
	if (command == NULL) internal_error("not available in-app");
	WRITE_TO(command, "echo 'Not done yet'");
	return TRUE;
}
