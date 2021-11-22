[LoadBinaryKitsStage::] Load Binary Kits Stage.

Reading other Inter trees as binary files, and attaching them at given points
in the main Inter tree.

@ Linking is not a symmetrical process: one Inter tree remains the primary one --
usually this will be the tree still in memory which was compiled by Inform 7
from source text. That needs to be linked to Inter from, for example, kits
such as |WorldModelKit|. This is a non-trivial process, but begins easily
enough, with each of those secondary Inter trees in turn being read in from
a binary Inter file, and then attached to (i.e., made part of) the primary tree.

The primary tree cannot "know", of itself, where these secondary trees will
live in the file system, so the |load-binary-kits| stage needs to be given instructions
on the side. This is done with the "requirements list" of the step.

=
void LoadBinaryKitsStage::create_pipeline_stage(void) {
	ParsingPipelines::new_stage(I"load-binary-kits",
		LoadBinaryKitsStage::run, NO_STAGE_ARG, FALSE);
}

int LoadBinaryKitsStage::run(pipeline_step *step) {
	attachment_instruction *req;
	LOOP_OVER_LINKED_LIST(req, attachment_instruction, step->ephemera.requirements_list) {
		inter_architecture *A = PipelineModule::get_architecture();
		if (A == NULL) Errors::fatal("no -architecture given");
		filename *arch_file = Architectures::canonical_binary(req->location, A);
		if (TextFiles::exists(arch_file) == FALSE)
			internal_error("no arch file for requirement");

		inter_tree *sidecar = InterTree::new();
		if (Inter::Binary::test_file(arch_file)) Inter::Binary::read(sidecar, arch_file);
		else Inter::Textual::read(sidecar, arch_file);		

		inter_package *pack = Inter::Packages::by_url(sidecar, req->attachment_point);
		if (pack == NULL) {
			WRITE_TO(STDERR, "sought attachment material at: %S in %f\n",
				req->attachment_point, arch_file);
			internal_error("unable to find attachment point package");
		}
		Inter::Transmigration::move(pack,
			Site::main_package(step->ephemera.repository), FALSE);	
	}
	return TRUE;
}

@ And this function is useful when building a requirements list, which is just
a linked list of //attachment_instruction//s.

=
typedef struct attachment_instruction {
	struct pathname *location;
	struct text_stream *attachment_point;
	CLASS_DEFINITION
} attachment_instruction;

attachment_instruction *LoadBinaryKitsStage::new(pathname *P, text_stream *attach) {
	attachment_instruction *link = CREATE(attachment_instruction);
	link->location = P;
	link->attachment_point = Str::duplicate(attach);
	return link;
}
