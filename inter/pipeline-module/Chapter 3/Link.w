[CodeGen::LinkInstructions::] Link.

Inter often needs to assimilate or otherwise deal with architecture-neutral
kits of linkable material, and this is where such requirements are noted.

@h

=
typedef struct link_instruction {
	struct pathname *location;
	struct text_stream *attachment_point;
	CLASS_DEFINITION
} link_instruction;

link_instruction *CodeGen::LinkInstructions::new(pathname *P, text_stream *attach) {
	link_instruction *link = CREATE(link_instruction);
	link->location = P;
	link->attachment_point = Str::duplicate(attach);
	return link;
}

@h Link stage.

=
void CodeGen::LinkInstructions::create_pipeline_stage(void) {
	ParsingPipelines::new_stage(I"link", CodeGen::LinkInstructions::run_link_stage, NO_STAGE_ARG, FALSE);
}

int CodeGen::LinkInstructions::run_link_stage(pipeline_step *step) {
	link_instruction *req;
	LOOP_OVER_LINKED_LIST(req, link_instruction, step->ephemera.requirements_list) {
		inter_architecture *A = RunningPipelines::get_architecture();
		if (A == NULL) Errors::fatal("no -architecture given");
		filename *arch_file = Architectures::canonical_binary(req->location, A);
		if (TextFiles::exists(arch_file) == FALSE) internal_error("no arch file for requirement");

		inter_tree *sidecar = InterTree::new();
		if (Inter::Binary::test_file(arch_file)) Inter::Binary::read(sidecar, arch_file);
		else Inter::Textual::read(sidecar, arch_file);		

		inter_package *pack = Inter::Packages::by_url(sidecar, req->attachment_point);
		if (pack == NULL) {
			WRITE_TO(STDERR, "sought attachment material at: %S in %f\n", req->attachment_point, arch_file);
			internal_error("unable to find attachment point package");
		}
		Inter::Transmigration::move(pack, Site::main_package(step->ephemera.repository), FALSE);	
	}
	return TRUE;
}
