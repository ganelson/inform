[BuildSteps::] Build Steps.

A build step is a task which exercises one of the build skills.

@h Build skills.
A "skill" is a single atomic task which we know how to perform. For example,
assimilating a binary for a kit is a skill.

Each different skill is an instance of:

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

@ Skills provide two method functions: one constructs a shell command to
perform the skill, and the other performs the skill directly by calling some
function within the current executable. These methods are optional, and if
one is absent then the skill can't be performed that way.

@e BUILD_SKILL_COMMAND_MTID
@e BUILD_SKILL_INTERNAL_MTID

=
VMETHOD_TYPE(BUILD_SKILL_COMMAND_MTID,
	build_skill *S, build_step *BS, text_stream *command, build_methodology *meth)
IMETHOD_TYPE(BUILD_SKILL_INTERNAL_MTID,
	build_skill *S, build_step *BS, build_methodology *meth)

@h Build steps.
These are essentially just skills, but with a docket of contextual data. The
idea is that a function outside the |supervisor| module can carry out a skill
for us using only the contextual information in this structure, without having
to access any of |inbuild|'s variables directly.

=
typedef struct build_step {
	struct build_skill *what_to_do;
	struct build_vertex *vertex; /* what to do it to */
	struct linked_list *search_path; /* of |inbuild_nest| */
	struct target_vm *for_vm;
	struct inter_architecture *for_arch;
	int for_release;
	struct inbuild_copy *associated_copy; /* e.g., the Inform project causing this work */
	MEMORY_MANAGEMENT
} build_step;

@ We build scripts for a vertex by attaching one step at a time to it:

=
build_step *BuildSteps::attach(build_vertex *vertex, build_skill *to_do, linked_list *search,
	int rel, target_vm *VM, inter_architecture *arch, inbuild_copy *assoc) {
	build_step *S = CREATE(build_step);
	S->what_to_do = to_do;
	S->vertex = vertex;
	S->search_path = search;
	S->for_vm = VM;
	S->for_arch = arch;
	if ((VM) && (arch == NULL)) S->for_arch = TargetVMs::get_architecture(VM);
	S->for_release = rel;
	S->associated_copy = assoc;
	BuildScripts::add_step(vertex->script, S);
	return S;
}

@h Execution.
Note that this prints a log of shell commands generated to |stdout| when
we are running inside Inbuild at the command line, but not when we are running
inside the |inform7| executable, where we are silent throughout.

=
int BuildSteps::execute(build_vertex *V, build_step *S, build_methodology *BM) {
	int rv = TRUE;
	TEMPORARY_TEXT(command);
	@<Work out a shell command, and perhaps print or call it@>;
	@<Perform the skill internally if that's called for@>;
	#ifndef CORE_MODULE
	if (rv == FALSE) WRITE_TO(STDERR, "Build failed at '%S'\n", command);
	#endif
	DISCARD_TEXT(command);
	return rv;
}

@<Work out a shell command, and perhaps print or call it@> =
	VMETHOD_CALL(S->what_to_do, BUILD_SKILL_COMMAND_MTID, S, command, BM);
	if (Str::len(command) > 0) rv = BuildSteps::shell(command, BM);

@<Perform the skill internally if that's called for@> =
	if (BM->methodology == INTERNAL_METHODOLOGY) {
		int returned = 0;
		IMETHOD_CALL(returned, S->what_to_do, BUILD_SKILL_INTERNAL_MTID, S, BM);
		if (returned != TRUE) rv = FALSE;
	}

@ This prints a shell command to |stdout| (except when inside |inform7|)
and also executes it if the methodology allows, returning the result. Note
that shell commands return 0 to indicate happiness.

=
int BuildSteps::shell(text_stream *command, build_methodology *BM) {
	int rv = TRUE;
	#ifndef CORE_MODULE
	WRITE_TO(STDOUT, "%S\n", command);
	#endif
	if (BM->methodology == SHELL_METHODOLOGY)
		rv = (Shell::run(command) == 0)?TRUE:FALSE;
	return rv;
}
