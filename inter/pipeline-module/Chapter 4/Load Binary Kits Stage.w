[LoadBinaryKitsStage::] Load Binary Kits Stage.

Reading other Inter trees as binary files, and attaching them at given points
in the main Inter tree.

@ Inform 7 compiles source text to a single "main" Inter tree. That tree must
then be joined with other Inter trees for kits such as BasicInformKit, a
process called "linking", for want of a better word.[1]

Only the //supervisor// module knows which kits need to be linked in; the main
Inter tree doesn't contain this information.[2]

[1] Unlike the C linking process, it is not symmetrical. One Inter tree is
made by //inter//, and the others by //inter//, for one thing.

[2] Just as a C-compiled binary may be made by linking |alpha.o|, |beta.o| and
|gamma.o| together, but the fact that these are the three |*.o| files needed
to make the finished article is recorded only in the makefile for the program.
It's a matter for the build process and not for the compiler.

@ The list of Inter trees to link with is worked out by the //supervisor//,
which calls the following function to obtain a way to record each "requirement":

=
typedef struct attachment_instruction {
	struct pathname *location;
	struct text_stream *attachment_point;
	CLASS_DEFINITION
} attachment_instruction;

attachment_instruction *LoadBinaryKitsStage::new_requirement(pathname *P, text_stream *attach) {
	attachment_instruction *link = CREATE(attachment_instruction);
	link->location = P;
	link->attachment_point = Str::duplicate(attach);
	return link;
}

@ Linking begins with the following stage. Note that the list of requirements
made by //supervisor// is now stored in |step->ephemera.requirements_list|.

=
void LoadBinaryKitsStage::create_pipeline_stage(void) {
	ParsingPipelines::new_stage(I"load-binary-kits",
		LoadBinaryKitsStage::run, NO_STAGE_ARG, FALSE);
}

int LoadBinaryKitsStage::run(pipeline_step *step) {
	attachment_instruction *req;
	LOOP_OVER_LINKED_LIST(req, attachment_instruction, step->ephemera.requirements_list) {
		inter_tree *sidecar = InterTree::new();
		@<Load the Inter for the kit into the sidecar@>;
		@<Migrate the bulk of the code from the sidecar to the main tree@>;
	}
	inter_tree *I = step->ephemera.tree;
	Wiring::connect_plugs_to_sockets(I);
	return TRUE;
}

@ A kit will, if properly prepared, contain a binary Inter file for each possible
architecture which may be needed. For testing purposes, the following actually
allows a textual Inter file to be used instead, but this isn't intended for
regular users: it would be quite slow to read in.

@<Load the Inter for the kit into the sidecar@> =
	inter_architecture *A = PipelineModule::get_architecture();
	if (A == NULL) Errors::fatal("no -architecture given");
	filename *arch_file = Architectures::canonical_binary(req->location, A);
	if (TextFiles::exists(arch_file) == FALSE)
		internal_error("no arch file for requirement");
	if (Inter::Binary::test_file(arch_file)) Inter::Binary::read(sidecar, arch_file);
	else Inter::Textual::read(sidecar, arch_file);		

@ The "attachment point" for the kit will be something like |/main/BasicInformKit|.
(This point will be different for each different kit in the requirements list:
others might include |/main/CommandParserKit|, and so on.) We take that package out
of the sidecar and put it into the main tree.

@<Migrate the bulk of the code from the sidecar to the main tree@> =
	inter_package *pack = Inter::Packages::by_url(sidecar, req->attachment_point);
	if (pack == NULL) {
		WRITE_TO(STDERR, "sought attachment material at: %S\n", req->attachment_point);
		internal_error("unable to find attachment point package");
	}
	Inter::Transmigration::move(pack,
		Site::main_package(step->ephemera.tree), FALSE);	
