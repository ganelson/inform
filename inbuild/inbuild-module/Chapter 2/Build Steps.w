[BuildSteps::] Build Steps.

Graphs in which vertices correspond to files or copies, and arrows to
dependencies between them.

@h Build graphs.
These are directed acyclic graphs which show what depends on what in the
building process. If an arrow leads from A to B, then B must be built before
A can be built.

There can be two sorts of vertex in such a graph: copy vertices, each of which
belongs to a single copy, and internal vertices, each of which represents
a different file inside the copy.

=
typedef struct build_script {
	struct linked_list *steps; /* of |build_step| */
	MEMORY_MANAGEMENT
} build_script;

typedef struct build_step {
	int what_to_do;
	struct pathname *arg_p1;
	struct text_stream *arg_t1;
	MEMORY_MANAGEMENT
} build_step;

@

@e ASSIMILATE_BSTEP from 1

=
build_script *BuildSteps::new_script(void) {
	build_script *BS = CREATE(build_script);
	BS->steps = NEW_LINKED_LIST(build_step);
	return BS;
}

build_step *BuildSteps::new_step(int to_do, pathname *P, text_stream *T) {
	build_step *S = CREATE(build_step);
	S->what_to_do = to_do;
	S->arg_p1 = P;
	S->arg_t1 = T;
	return S;
}

void BuildSteps::add_step(build_script *BS, build_step *S) {
	ADD_TO_LINKED_LIST(S, build_step, BS->steps);
}

void BuildSteps::concatenate(build_script *BT, build_script *BF) {
	build_step *S;
	LOOP_OVER_LINKED_LIST(S, build_step, BF->steps)
		BuildSteps::add_step(BT, S);
}

@

@e DRY_RUN_METHODOLOGY from 1
@e SHELL_METHODOLOGY
@e INTERNAL_METHODOLOGY

=
typedef struct build_methodology {
	filename *to_inter;
	filename *to_inform6;
	filename *to_inform7;
	filename *to_inblorb;
	int methodology;
	MEMORY_MANAGEMENT
} build_methodology;

build_methodology *BuildSteps::methodology(pathname *tools_path, int dev) {
	build_methodology *meth = CREATE(build_methodology);
	meth->methodology = DRY_RUN_METHODOLOGY;
	pathname *inter_path = tools_path;
	if (dev) {
		inter_path = Pathnames::subfolder(inter_path, I"inter");
		inter_path = Pathnames::subfolder(inter_path, I"Tangled");
	}
	meth->to_inter = Filenames::in_folder(inter_path, I"inter");
	pathname *inform6_path = tools_path;
	if (dev) {
		inform6_path = Pathnames::subfolder(inform6_path, I"inform6");
		inform6_path = Pathnames::subfolder(inform6_path, I"Tangled");
	}
	meth->to_inform6 = Filenames::in_folder(inform6_path, I"inform6");
	pathname *inform7_path = tools_path;
	if (dev) {
		inform7_path = Pathnames::subfolder(inform7_path, I"inform7");
		inform7_path = Pathnames::subfolder(inform7_path, I"Tangled");
	}
	meth->to_inform7 = Filenames::in_folder(inform7_path, I"inform7");
	pathname *inblorb_path = tools_path;
	if (dev) {
		inblorb_path = Pathnames::subfolder(inblorb_path, I"inblorb");
		inblorb_path = Pathnames::subfolder(inblorb_path, I"Tangled");
	}
	meth->to_inblorb = Filenames::in_folder(inblorb_path, I"inblorb");
	return meth;
}

void BuildSteps::execute(build_script *BS, build_methodology *meth) {
	build_step *S;
	LOOP_OVER_LINKED_LIST(S, build_step, BS->steps) {
		TEMPORARY_TEXT(command);
		@<Write a shell command for the step@>;
		BuildSteps::shell(command, meth);
		DISCARD_TEXT(command);
	}
}

@<Write a shell command for the step@> =
	switch (S->what_to_do) {
		case ASSIMILATE_BSTEP:
			Shell::quote_file(command, meth->to_inter);
			WRITE_TO(command, " -architecture %S -assimilate ", S->arg_t1);
			Shell::quote_path(command, S->arg_p1);
			break;
		default: internal_error("unimplemented step");
	}

@ =
void BuildSteps::shell(text_stream *command, build_methodology *meth) {
	switch (meth->methodology) {
		case DRY_RUN_METHODOLOGY:
		case SHELL_METHODOLOGY: {
			WRITE_TO(STDOUT, "%S\n", command);
			if (meth->methodology == SHELL_METHODOLOGY) Shell::run(command);
		}
	}	
}
