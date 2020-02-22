[BuildScripts::] Build Scripts.

Scripts are nothing more than list of build steps.

@h Build scripts.
Simple lists of steps: nothing to see here...

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

void BuildScripts::concatenate(build_script *BT, build_script *BF) {
	build_step *S;
	LOOP_OVER_LINKED_LIST(S, build_step, BF->steps)
		BuildScripts::add_step(BT, S);
}

int BuildScripts::execute(build_vertex *V, build_script *BS, build_methodology *meth) {
	int rv = TRUE;
	build_step *S;
	LOOP_OVER_LINKED_LIST(S, build_step, BS->steps)
		if (rv)
			rv = BuildSteps::execute(V, S, meth);
	return rv;
}
