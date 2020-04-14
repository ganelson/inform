[BuildScripts::] Build Scripts.

Scripts are nothing more than lists of build steps.

@h Build scripts.
Suppose the incremental build algorithm has decided it wants to build node
|V| in the graph: it does so by calling |BuildScripts::execute| on the script
attached to |V|. This is only a list of steps:

=
typedef struct build_script {
	struct linked_list *steps; /* of |build_step| */
	MEMORY_MANAGEMENT
} build_script;

build_script *BuildScripts::new(void) {
	build_script *BS = CREATE(build_script);
	BS->steps = NEW_LINKED_LIST(build_step);
	return BS;
}

void BuildScripts::add_step(build_script *BS, build_step *S) {
	ADD_TO_LINKED_LIST(S, build_step, BS->steps);
}

int BuildScripts::script_length(build_script *BS) {
	if (BS == NULL) return 0;
	return LinkedLists::len(BS->steps);
}

@ We execute the steps in sequence, of course. As soon as any step fails,
returning |FALSE|, the script halts and returns |FALSE|. An empty script
always succeeds and returns |TRUE|.

=
int BuildScripts::execute(build_vertex *V, build_script *BS, build_methodology *BM) {
	int rv = TRUE;
	build_step *S;
	LOOP_OVER_LINKED_LIST(S, build_step, BS->steps)
		if (rv)
			rv = BuildSteps::execute(V, S, BM);
	return rv;
}
