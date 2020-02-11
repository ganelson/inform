[SharedCLI::] Shared CLI.

A subset of command-line options shared by the tools which incorporate this
module.

@h The nest list.
Nests used by the Inform and Inbuild tools are tagged with the following
comstamts, except that no nest is ever tagged |NOT_A_NEST_TAG|.
(There used to be quite a good joke here, but refactoring of the
code removed its premiss. Literate programming is like that sometimes.)

@e NOT_A_NEST_TAG from 0
@e MATERIALS_NEST_TAG
@e EXTERNAL_NEST_TAG
@e GENERIC_NEST_TAG
@e INTERNAL_NEST_TAG

@ Inform customarily has exactly one |-internal| and one |-external| nest,
but in fact any number of each are allowed, including none. However, the
first to be declared are used by the compiler as "the" internal and external
nests, respectively.

The following hold the nests in declaration order.

=
linked_list *unsorted_nest_list = NULL;
inbuild_nest *shared_internal_nest = NULL;
inbuild_nest *shared_external_nest = NULL;
inbuild_nest *shared_materials_nest = NULL;

inbuild_nest *SharedCLI::add_nest(pathname *P, int tag) {
	if (unsorted_nest_list == NULL)
		unsorted_nest_list = NEW_LINKED_LIST(inbuild_nest);
	inbuild_nest *N = Nests::new(P);
	Nests::set_tag(N, tag);
	ADD_TO_LINKED_LIST(N, inbuild_nest, unsorted_nest_list);
	if ((tag == EXTERNAL_NEST_TAG) && (shared_external_nest == NULL))
		shared_external_nest = N;
	if ((tag == INTERNAL_NEST_TAG) && (shared_internal_nest == NULL))
		shared_internal_nest = N;
	if (tag == INTERNAL_NEST_TAG) Nests::protect(N);
	return N;
}

@ It is then sorted in tag order. This is so that if we look for, say, an
extension with a given name, then results in a project's materials folder
are given precedence over those in the external folder, and so on.

=
linked_list *shared_nest_list = NULL;
void SharedCLI::sort_nest_list(void) {
	shared_nest_list = NEW_LINKED_LIST(inbuild_nest);
	inbuild_nest *N;
	LOOP_OVER_LINKED_LIST(N, inbuild_nest, unsorted_nest_list)
		if (Nests::get_tag(N) == MATERIALS_NEST_TAG)
			ADD_TO_LINKED_LIST(N, inbuild_nest, shared_nest_list);
	LOOP_OVER_LINKED_LIST(N, inbuild_nest, unsorted_nest_list)
		if (Nests::get_tag(N) == EXTERNAL_NEST_TAG)
			ADD_TO_LINKED_LIST(N, inbuild_nest, shared_nest_list);
	LOOP_OVER_LINKED_LIST(N, inbuild_nest, unsorted_nest_list)
		if (Nests::get_tag(N) == GENERIC_NEST_TAG)
			ADD_TO_LINKED_LIST(N, inbuild_nest, shared_nest_list);
	LOOP_OVER_LINKED_LIST(N, inbuild_nest, unsorted_nest_list)
		if (Nests::get_tag(N) == INTERNAL_NEST_TAG)
			ADD_TO_LINKED_LIST(N, inbuild_nest, shared_nest_list);
}

@ And the rest of Inform or Inbuild can now use:

=
linked_list *SharedCLI::nest_list(void) {
	if (shared_nest_list == NULL) internal_error("nest list never sorted");
	return shared_nest_list;
}

inbuild_nest *SharedCLI::internal(void) {
	return shared_internal_nest;
}

inbuild_nest *SharedCLI::external(void) {
	return shared_external_nest;
}

pathname *SharedCLI::materials(void) {
	if (shared_materials_nest == NULL) return NULL;
	return shared_materials_nest->location;
}

@ The transient area is used for ephemera such as dynamically written
documentation and telemetry files. |-transient| sets it, but otherwise
the external nest is used.

=
pathname *shared_transient_resources = NULL;
pathname *SharedCLI::transient(void) {
	if (shared_transient_resources == NULL)
		if (shared_external_nest)
			return shared_external_nest->location;
	return shared_transient_resources;
}

@h The shared project.
In any single run, each of the Inform tools concerns itself with a single
Inform 7 program. This can be presented to it either in a project bundle
(a directory which contains source, settings, space for an index and for
temporary build files), or as a single file (just a text file containing
source text).

It is also possible o set a folder to be the project bundle, and nevertheless
specify a file somewhere else to be the source text. What you can't do is
specify the bundle twice, or specify the file twice.

=
text_stream *project_bundle_request = NULL;
text_stream *project_file_request = NULL;

int SharedCLI::set_I7_source(text_stream *loc) {
	if (Str::len(project_file_request) > 0) return FALSE;
	project_file_request = Str::duplicate(loc);
	return TRUE;
}

int SharedCLI::set_I7_bundle(text_stream *loc) {
	if (Str::len(project_bundle_request) > 0) return FALSE;
	project_bundle_request = Str::duplicate(loc);
	return TRUE;
}

@ If a bundle is found, then by default the source text within it is called
|story.ni|. The |.ni| is an anachronism now, but at one time stood for
"natural Inform", the working title for Inform 7 in the early 2000s.

=
inform_project *shared_project = NULL;

void SharedCLI::create_shared_project(void) {
	filename *filename_of_i7_source = NULL;
	pathname *pathname_of_bundle = NULL;
	if (Str::len(project_bundle_request) > 0) {
		pathname_of_bundle = Pathnames::from_text(project_bundle_request);
		filename_of_i7_source =
			Filenames::in_folder(
				Pathnames::subfolder(pathname_of_bundle, I"Source"),
				I"story.ni");
		if (Str::includes(project_bundle_request, I"#2oetMiq9bqxoxY"))
			Kits::request(I"BasicInformKit");
	}
	if (Str::len(project_file_request) > 0) {
		filename_of_i7_source = Filenames::from_text(project_file_request);
	}
	if (pathname_of_bundle) {
		inbuild_copy *C = ProjectBundleManager::claim_folder_as_copy(pathname_of_bundle);
		shared_project = ProjectBundleManager::from_copy(C);
	} else if (filename_of_i7_source) {
		inbuild_copy *C = ProjectFileManager::claim_file_as_copy(filename_of_i7_source);
		shared_project = ProjectFileManager::from_copy(C);
	}
	@<Create the materials nest@>;
	if (shared_project)
		Projects::set_source_filename(shared_project, filename_of_i7_source);
}

@ The materials folder sits alongside the project folder and has the same name,
but ending |.materials| instead of |.inform|.

@<Create the materials nest@> =
	pathname *materials = NULL;
	if (pathname_of_bundle) {
		TEMPORARY_TEXT(mf);
		WRITE_TO(mf, "%S", Pathnames::directory_name(pathname_of_bundle));
		int i = Str::len(mf)-1;
		while ((i>0) && (Str::get_at(mf, i) != '.')) i--;
		if (i>0) {
			Str::truncate(mf, i);
			WRITE_TO(mf, ".materials");
		}
		materials = Pathnames::subfolder(Pathnames::up(pathname_of_bundle), mf);
		DISCARD_TEXT(mf);
		Pathnames::create_in_file_system(materials);
	} else if (filename_of_i7_source) {
		materials = Pathnames::from_text(I"inform.materials");
	}
	if (materials) {
		shared_materials_nest = SharedCLI::add_nest(materials, MATERIALS_NEST_TAG);
	}

@ And the rest of Inform or Inbuild can now use:

=
inform_project *SharedCLI::project(void) {
	return shared_project;
}

@h Command line.
We add the following switches:

@e NEST_CLSW
@e INTERNAL_CLSW
@e EXTERNAL_CLSW
@e TRANSIENT_CLSW
@e KIT_CLSW
@e PROJECT_CLSW
@e SOURCE_CLSW

=
void SharedCLI::declare_options(void) {
	CommandLine::declare_switch(NEST_CLSW, L"nest", 2,
		L"add the nest at pathname X to the search list");
	CommandLine::declare_switch(INTERNAL_CLSW, L"internal", 2,
		L"use X as the location of built-in material such as the Standard Rules");
	CommandLine::declare_switch(EXTERNAL_CLSW, L"external", 2,
		L"use X as the user's home for installed material such as extensions");
	CommandLine::declare_switch(TRANSIENT_CLSW, L"transient", 2,
		L"use X for transient data such as the extensions census");
	CommandLine::declare_switch(KIT_CLSW, L"kit", 2,
		L"load the Inform kit called X");
	CommandLine::declare_switch(PROJECT_CLSW, L"project", 2,
		L"work within the Inform project X");
	CommandLine::declare_switch(SOURCE_CLSW, L"source", 2,
		L"use file X as the Inform source text");
}

void SharedCLI::option(int id, int val, text_stream *arg, void *state) {
	switch (id) {
		case NEST_CLSW: SharedCLI::add_nest(Pathnames::from_text(arg), GENERIC_NEST_TAG); break;
		case INTERNAL_CLSW: SharedCLI::add_nest(Pathnames::from_text(arg), INTERNAL_NEST_TAG); break;
		case EXTERNAL_CLSW: SharedCLI::add_nest(Pathnames::from_text(arg), EXTERNAL_NEST_TAG); break;
		case TRANSIENT_CLSW: shared_transient_resources = Pathnames::from_text(arg); break;
		case KIT_CLSW: Kits::request(arg); break;
		case PROJECT_CLSW:
			if (SharedCLI::set_I7_bundle(arg) == FALSE)
				Errors::fatal_with_text("can't specify the project twice: '%S'", arg);
			break;
		case SOURCE_CLSW:
			if (SharedCLI::set_I7_source(arg) == FALSE)
				Errors::fatal_with_text("can't specify the source file twice: '%S'", arg);
			break;
	}
}

@ The client tool (i.e., Inform or Inbuild) should call this when no further
options remain to be processed.

=
void SharedCLI::optioneering_complete(void) {
	SharedCLI::create_shared_project();
	SharedCLI::sort_nest_list();
}
