[Main::] Main.

A command-line interface for Inter functions which are not part of the
normal operation of the Inform compiler.

@h Settings variables.
The following will be set at the command line.

=
pathname *path_to_inter = NULL;

pathname *kit_to_build = NULL;
pathname *domain_path = NULL;
linked_list *inter_file_list = NULL; /* of |filename| */
filename *output_file = NULL;
dictionary *pipeline_vars = NULL;
filename *pipeline_as_file = NULL;
text_stream *pipeline_as_text = NULL;
pathname *internal_path = NULL;
text_stream *output_format = NULL; /* for any |-o| output */
int tracing = FALSE;

void Main::add_pipeline_variable(text_stream *name, text_stream *value) {
	Str::copy(Dictionaries::create_text(pipeline_vars, name), value);
}
void Main::add_pipeline_variable_from_filename(text_stream *name, filename *F) {
	TEMPORARY_TEXT(fullname)
	WRITE_TO(fullname, "%f", F);
	Main::add_pipeline_variable(name, fullname);
	DISCARD_TEXT(fullname)
}

@h Main routine.
When Inter is called at the command line, it begins at |main|, like all C
programs.

Inter can do three different things: build a kit, run a pipeline of
code generation stages, and verify/transcode files of Inter code. In fact,
though, that's really only two different things, because kit-building is
also done with a pipeline.

=
int main(int argc, char **argv) {
    @<Start up the modules@>;
	@<Begin with an empty file list and variables dictionary@>;
	@<Read the command line@>;
	if (kit_to_build) @<Select the build-kit pipeline@>;
	@<Run the pipeline@>;
	@<Shut down the modules@>;
	if (Errors::have_occurred()) return 1;
	return 0;
}

@<Start up the modules@> =
	Foundation::start(argc, argv); /* must be started first */
	ArchModule::start();
	BytecodeModule::start();
	BuildingModule::start();
	PipelineModule::start();
	FinalModule::start();
	IndexModule::start();

@<Begin with an empty file list and variables dictionary@> =
	inter_file_list = NEW_LINKED_LIST(filename);
	pipeline_vars = ParsingPipelines::basic_dictionary(I"output.i6");
	internal_path = Pathnames::from_text(I"inform7/Internal");

@<Select the build-kit pipeline@> =
	inter_architecture *A = PipelineModule::get_architecture();
	if (A == NULL) Errors::fatal("no -architecture given");

	pathname *path_to_pipelines = Pathnames::down(path_to_inter, I"Pipelines");
	pipeline_as_file = Filenames::in(path_to_pipelines, I"build-kit.interpipeline");
	pipeline_as_text = NULL; 

	Main::add_pipeline_variable(I"*kit",
		Pathnames::directory_name(kit_to_build));
	Main::add_pipeline_variable_from_filename(I"*out",
		Architectures::canonical_binary(kit_to_build, A));

@<Run the pipeline@> =
	if ((pipeline_as_file) && (pipeline_as_text))
		Errors::fatal("-pipeline-text and -pipeline-file are mutually exclusive");
	if (Str::len(output_format) == 0) output_format = I"Text";
	target_vm *VM = TargetVMs::find(output_format);
	if (VM == NULL) Errors::fatal("unrecognised compilation -format");
	inter_architecture *A = PipelineModule::get_architecture();
	if (A == NULL)
		PipelineModule::set_architecture(
			Architectures::to_codename(TargetVMs::get_architecture(VM)));

	inter_tree *I = InterTree::new();
	if (LinkedLists::len(inter_file_list) > 0) {
		if (LinkedLists::len(inter_file_list) > 1)
			Errors::fatal("only one file of Inter can be supplied");
		filename *F;
		LOOP_OVER_LINKED_LIST(F, filename, inter_file_list)
			Main::add_pipeline_variable_from_filename(I"*in", F);
	}
	if (output_file) {
		Main::add_pipeline_variable_from_filename(I"*out", output_file);
	}
	inter_pipeline *SS = NULL;
	@<Compile the pipeline@>;
	if (SS) {
		linked_list *req_list = NEW_LINKED_LIST(attachment_instruction);
		RunningPipelines::run(domain_path, SS, I, kit_to_build, req_list, VM, tracing);
	}

@<Compile the pipeline@> =
	if (pipeline_as_file) {
		SS = ParsingPipelines::from_file(pipeline_as_file, pipeline_vars, NULL);
		if (SS == NULL) Errors::fatal("pipeline could not be parsed");
	} else if (pipeline_as_text) {
		SS = ParsingPipelines::from_text(pipeline_as_text, pipeline_vars);
		if (SS == NULL) Errors::fatal("pipeline could not be parsed");
	} else if (output_file) {
		SS = ParsingPipelines::from_text(I"read <- *in, generate -> *out", pipeline_vars);
		if (SS == NULL) Errors::fatal("pipeline could not be parsed");
	} else if (LinkedLists::len(inter_file_list) > 0) {
		SS = ParsingPipelines::from_text(I"read <- *in", pipeline_vars);
		if (SS == NULL) Errors::fatal("pipeline could not be parsed");
	}

@<Shut down the modules@> =
	BytecodeModule::end();
	BuildingModule::end();
	PipelineModule::end();
	FinalModule::end();
	ArchModule::end();
	IndexModule::end();
	Foundation::end(); /* must be ended last */

@h Command line.

@d PROGRAM_NAME "inter"

@e PIPELINE_CLSW
@e PIPELINE_FILE_CLSW
@e PIPELINE_VARIABLE_CLSW
@e DOMAIN_CLSW
@e ARCHITECTURE_CLSW
@e BUILD_KIT_CLSW
@e INTERNAL_CLSW
@e CONSTRUCTS_CLSW
@e ANNOTATIONS_CLSW
@e PRIMITIVES_CLSW
@e FORMAT_CLSW
@e O_CLSW
@e TRACE_CLSW

@<Read the command line@> =
	CommandLine::declare_heading(
		L"[[Purpose]]\n\n"
		L"usage: inter file1 file2 ... [options]\n");

	CommandLine::declare_switch(O_CLSW, L"o", 2,
		L"code-generate to file X");
	CommandLine::declare_textual_switch(FORMAT_CLSW, L"format", 1,
		L"code-generate -o output to format X (default is Text)");
	CommandLine::declare_switch(PIPELINE_CLSW, L"pipeline-text", 2,
		L"specify pipeline textually, with X being a comma-separated list of stages");
	CommandLine::declare_switch(PIPELINE_FILE_CLSW, L"pipeline-file", 2,
		L"specify pipeline as file X");
	CommandLine::declare_switch(PIPELINE_VARIABLE_CLSW, L"variable", 2,
		L"set pipeline variable X (in form name=value)");
	CommandLine::declare_switch(DOMAIN_CLSW, L"domain", 2,
		L"specify folder to read/write inter files from/to");
	CommandLine::declare_switch(INTERNAL_CLSW, L"internal", 2,
		L"specify folder of internal Inform resources");
	CommandLine::declare_switch(ARCHITECTURE_CLSW, L"architecture", 2,
		L"generate Inter with architecture X");
	CommandLine::declare_switch(BUILD_KIT_CLSW, L"build-kit", 2,
		L"build Inter kit X for the current architecture");
	CommandLine::declare_switch(CONSTRUCTS_CLSW, L"constructs", 1,
		L"print out table of all constructs in the Inter language");
	CommandLine::declare_switch(ANNOTATIONS_CLSW, L"annotations", 1,
		L"print out table of all symbol annotations in the Inter language");
	CommandLine::declare_switch(PRIMITIVES_CLSW, L"primitives", 1,
		L"print out table of all primitive invocations in the Inter language");
	CommandLine::declare_boolean_switch(TRACE_CLSW, L"trace", 1,
		L"print out all pipeline steps as they are followed", FALSE);

	CommandLine::read(argc, argv, NULL, &Main::respond, &Main::add_file);

	path_to_inter = Pathnames::installation_path("INTER_PATH", I"inter");

@ =
void Main::respond(int id, int val, text_stream *arg, void *state) {
	switch (id) {
		case O_CLSW: output_file = Filenames::from_text(arg); break;
		case FORMAT_CLSW: output_format = Str::duplicate(arg); break;
		case PIPELINE_CLSW: pipeline_as_text = Str::duplicate(arg); break;
		case PIPELINE_FILE_CLSW: pipeline_as_file = Filenames::from_text(arg); break;
		case PIPELINE_VARIABLE_CLSW: @<Add a pipeline variable to the dictionary@>; break;
		case DOMAIN_CLSW: domain_path = Pathnames::from_text(arg); break;
		case BUILD_KIT_CLSW: kit_to_build = Pathnames::from_text(arg); break;
		case INTERNAL_CLSW: internal_path = Pathnames::from_text(arg); break;
		case ARCHITECTURE_CLSW:
			if (PipelineModule::set_architecture(arg) == FALSE)
				Errors::fatal("no such -architecture");
			break;
		case CONSTRUCTS_CLSW:  InterInstruction::show_constructs(STDOUT); break;
		case ANNOTATIONS_CLSW: SymbolAnnotation::show_annotations(STDOUT); break;
		case PRIMITIVES_CLSW:  Primitives::show_primitives(STDOUT); break;
		case TRACE_CLSW: tracing = (val)?TRUE:FALSE; break;
	}
}

@<Add a pipeline variable to the dictionary@> =
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, arg, L"(%c+)=(%c+)")) {
		if (Str::get_first_char(arg) != '*') {
			Errors::fatal("-variable names must begin with '*'");
		} else {
			Main::add_pipeline_variable(mr.exp[0], mr.exp[1]);
		}
	} else {
		Errors::fatal("-variable should take the form 'name=value'");
	}
	Regexp::dispose_of(&mr);

@ =
void Main::add_file(int id, text_stream *arg, void *state) {
	filename *F = Filenames::from_text(arg);
	ADD_TO_LINKED_LIST(F, filename, inter_file_list);
}

@ The modules included in |inter| make use of the Inform 7 module |kinds|,
but when we are using |inter| on its own, kinds have no meaning for us.
We are required to create a |kind| type, in order for |kinds| to compile;
but no instances of this kind will ever in fact exist. |K_value| is a
global constant meaning "any kind at all", and that also must exist.

= (early code)
typedef void kind;
kind *K_value = NULL;

@ This is where the //html// module can find CSS files and similar resources:

@d INSTALLED_FILES_HTML_CALLBACK Main::internal_path

=
pathname *Main::internal_path(void) {
	return internal_path;
}
