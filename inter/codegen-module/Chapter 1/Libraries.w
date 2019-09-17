[CodeGen::Libraries::] Libraries.

Architecture-neutral blocks of linkable inter material are called libraries.

@h

=
typedef struct inter_library {
	struct pathname *location;
	struct text_stream *attachment_point;
	MEMORY_MANAGEMENT
} inter_library;

inter_library *CodeGen::Libraries::new(pathname *P) {
	inter_library *lib = CREATE(inter_library);
	lib->location = P;
	lib->attachment_point = NULL;
	filename *F = Filenames::in_folder(P, I"library_metadata.txt");
	TextFiles::read(F, FALSE,
		NULL, FALSE, CodeGen::Libraries::read_metadata, NULL, (void *) lib);
	if (lib->attachment_point == NULL)
		Errors::nowhere("library metadata file failed to set attachment point");
	return lib;
}

void CodeGen::Libraries::read_metadata(text_stream *text,
	text_file_position *tfp, void *state) {
	inter_library *lib = (inter_library *) state;
	match_results mr = Regexp::create_mr();
	if ((Str::is_whitespace(text)) || (Regexp::match(&mr, text, L" *#%c*"))) {
		;
	} else if (Regexp::match(&mr, text, L"attach: (%c*)")) {
		lib->attachment_point = Str::duplicate(mr.exp[0]);
	} else {
		Errors::in_text_file("illegible line in library metadata file", tfp);
	}
	Regexp::dispose_of(&mr);
}

inter_library *CodeGen::Libraries::find(text_stream *name, int N, pathname **PP) {
	for (int i=0; i<N; i++) {
		pathname *P = Pathnames::subfolder(PP[i], name);
		filename *F = Filenames::in_folder(P, I"library_metadata.txt");
		if (TextFiles::exists(F)) return CodeGen::Libraries::new(P);
	}
	return NULL;
}

@h Link stage.

=
void CodeGen::Libraries::create_pipeline_stage(void) {
	CodeGen::Stage::new(I"link", CodeGen::Libraries::run_link_stage, NO_STAGE_ARG, FALSE);
}

int CodeGen::Libraries::run_link_stage(pipeline_step *step) {
	inter_library *req;
	LOOP_OVER_LINKED_LIST(req, inter_library, step->requirements_list) {
		TEMPORARY_TEXT(leafname);
		WRITE_TO(leafname, "%S.interb", CodeGen::Architecture::leafname());
		filename *arch_file = Filenames::in_folder(req->location, leafname);
		if (TextFiles::exists(arch_file) == FALSE) internal_error("no arch file for requirement");
		DISCARD_TEXT(leafname);

		inter_tree *sidecar = Inter::Tree::new();
		if (Inter::Binary::test_file(arch_file)) Inter::Binary::read(sidecar, arch_file);
		else Inter::Textual::read(sidecar, arch_file);		

		inter_package *pack = Inter::Packages::by_url(sidecar, req->attachment_point);
		Inter::Transmigration::move(pack, Site::main_package(step->repository), FALSE);	
	}
	return TRUE;
}
