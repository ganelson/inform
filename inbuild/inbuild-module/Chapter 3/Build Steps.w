[BuildSteps::] Build Steps.

A build step is a task which exercises one of the build skills.

@h Build skills.

=
typedef struct build_skill {
	struct text_stream *name;
	METHOD_CALLS
	MEMORY_MANAGEMENT
} build_skill;

build_skill *BuildSteps::new_skill(text_stream *name) {
	build_skill *S = CREATE(build_skill);
	S->name = Str::duplicate(name);
	ENABLE_METHOD_CALLS(S);
	return S;
}

@

@e BUILD_SKILL_COMMAND_MTID
@e BUILD_SKILL_INTERNAL_MTID

=
VMETHOD_TYPE(BUILD_SKILL_COMMAND_MTID,
	build_skill *S, build_step *BS, text_stream *command, build_methodology *meth)
IMETHOD_TYPE(BUILD_SKILL_INTERNAL_MTID,
	build_skill *S, build_step *BS, build_methodology *meth)

@h Build steps.

=
typedef struct build_step {
	struct build_skill *what_to_do;
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
build_step *BuildSteps::attach(build_vertex *vertex, build_skill *to_do, linked_list *search,
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
	VMETHOD_CALL(S->what_to_do, BUILD_SKILL_COMMAND_MTID, S, command, meth);
	if ((rv) && (Str::len(command) > 0)) rv = BuildSteps::shell(command, meth);
	if ((rv) && (meth->methodology == INTERNAL_METHODOLOGY)) {
		int returned = 0;
		IMETHOD_CALL(returned, S->what_to_do, BUILD_SKILL_INTERNAL_MTID, S, meth);
		if (returned != TRUE) rv = FALSE;
	}
	#ifndef CORE_MODULE
	if (rv == FALSE) WRITE_TO(STDERR, "Build failed at '%S'\n", command);
	#endif
	DISCARD_TEXT(command);
	return rv;
}

int BuildSteps::shell(text_stream *command, build_methodology *meth) {
	int rv = TRUE;
	#ifndef CORE_MODULE
	WRITE_TO(STDOUT, "%S\n", command);
	#endif
	if (meth->methodology == SHELL_METHODOLOGY) rv = (Shell::run(command) == 0)?TRUE:FALSE;
	return rv;
}
