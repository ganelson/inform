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
filename *output_textually = NULL;
filename *output_binarily = NULL;
dictionary *pipeline_vars = NULL;
filename *pipeline_as_file = NULL;
text_stream *pipeline_as_text = NULL;
pathname *internal_path = NULL;

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
	if (kit_to_build) @<Set up a pipeline for kit-building@>;
	if ((pipeline_as_file) || (pipeline_as_text))
		@<Run the pipeline@>
	else
		@<Read the list of inter files, and perhaps transcode them@>;
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

@ This pipeline is supplied built in to the installation of |inter|. In fact,
it only ever writes the binary form of the code it produces, so only |*out|
is used. But at times in the past it has been useful to debug with the text
form, which would be written to |*outt|.

@<Set up a pipeline for kit-building@> =
	inter_architecture *A = PipelineModule::get_architecture();
	if (A == NULL) Errors::fatal("no -architecture given");

	pathname *path_to_pipelines = Pathnames::down(path_to_inter, I"Pipelines");
	pipeline_as_file = Filenames::in(path_to_pipelines, I"build-kit.interpipeline");
	pipeline_as_text = NULL; 

	Main::add_pipeline_variable(I"*kit",
		Pathnames::directory_name(kit_to_build));
	Main::add_pipeline_variable_from_filename(I"*out",
		Architectures::canonical_binary(kit_to_build, A));
	Main::add_pipeline_variable_from_filename(I"*outt",
		Architectures::canonical_textual(kit_to_build, A));

@<Run the pipeline@> =
	if (LinkedLists::len(inter_file_list) > 0)
		Errors::fatal("-pipeline-text and -pipeline-file cannot be combined with inter files");
	if ((pipeline_as_file) && (pipeline_as_text))
		Errors::fatal("-pipeline-text and -pipeline-file are mutually exclusive");
	linked_list *inter_paths = NEW_LINKED_LIST(pathname);
	if (kit_to_build) ADD_TO_LINKED_LIST(kit_to_build, pathname, inter_paths);
	inter_pipeline *SS;
	if (pipeline_as_file)
		SS = ParsingPipelines::from_file(pipeline_as_file, pipeline_vars, NULL);
	else
		SS = ParsingPipelines::from_text(pipeline_as_text, pipeline_vars);
	linked_list *requirements_list = NEW_LINKED_LIST(attachment_instruction);
	if (SS) RunningPipelines::run(domain_path, SS, NULL, inter_paths, requirements_list, NULL);
	else Errors::fatal("pipeline could not be parsed");

@<Read the list of inter files, and perhaps transcode them@> =
	inter_tree *I = InterTree::new();
	filename *F;
	LOOP_OVER_LINKED_LIST(F, filename, inter_file_list) {
		if (Inter::Binary::test_file(F))
			Inter::Binary::read(I, F);
		else
			Inter::Textual::read(I, F);
	}
	if (output_textually) {
		text_stream C_struct; text_stream *OUT = &C_struct;
		if (STREAM_OPEN_TO_FILE(OUT, output_textually, UTF8_ENC) == FALSE)
			Errors::fatal_with_file("unable to open textual inter file for output: %f",
				output_textually);
		Inter::Textual::write(OUT, I, NULL, 1);
		STREAM_CLOSE(OUT);
	}
	if (output_binarily) Inter::Binary::write(output_binarily, I);

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

@e TEXTUAL_CLSW
@e BINARY_CLSW
@e PIPELINE_CLSW
@e PIPELINE_FILE_CLSW
@e PIPELINE_VARIABLE_CLSW
@e DOMAIN_CLSW
@e ARCHITECTURE_CLSW
@e BUILD_KIT_CLSW
@e INTERNAL_CLSW

@<Read the command line@> =
	CommandLine::declare_heading(
		L"[[Purpose]]\n\n"
		L"usage: inter file1 file2 ... [options]\n");

	CommandLine::declare_switch(TEXTUAL_CLSW, L"textual", 2,
		L"write to file X in textual format");
	CommandLine::declare_switch(BINARY_CLSW, L"binary", 2,
		L"write to file X in binary format");
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
		
	CommandLine::read(argc, argv, NULL, &Main::respond, &Main::add_file);

	path_to_inter = Pathnames::installation_path("INTER_PATH", I"inter");

@ =
void Main::respond(int id, int val, text_stream *arg, void *state) {
	switch (id) {
		case TEXTUAL_CLSW: output_textually = Filenames::from_text(arg); break;
		case BINARY_CLSW: output_binarily = Filenames::from_text(arg); break;
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
