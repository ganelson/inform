[Main::] Main.

The top level, which decides what is to be done and then carries
this plan out.

@h Main routine.

@d INTOOL_NAME "inter"

@e TEXTUAL_CLSW
@e BINARY_CLSW
@e PIPELINE_CLSW
@e PIPELINE_FILE_CLSW
@e PIPELINE_VARIABLE_CLSW
@e DOMAIN_CLSW
@e TEST_CLSW
@e ARCHITECTURE_CLSW
@e ASSIMILATE_CLSW

=
pathname *path_to_inter = NULL;
pathname *path_to_pipelines = NULL;
pathname *kit_path = NULL;
int template_action = -1;
pathname *domain_path = NULL;
filename *output_textually = NULL;
filename *output_binarily = NULL;
filename *unit_test_file = NULL;
dictionary *pipeline_vars = NULL;
filename *pipeline_as_file = NULL;
text_stream *pipeline_as_text = NULL;
linked_list *requirements_list = NULL;

int main(int argc, char **argv) {
    @<Start up the modules@>;

	path_to_inter = Pathnames::installation_path("INTER_PATH", I"inter");
	path_to_pipelines = Pathnames::subfolder(path_to_inter, I"Pipelines");
	requirements_list = NEW_LINKED_LIST(inter_library);

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
	CommandLine::declare_switch(TEST_CLSW, L"test", 2,
		L"perform unit tests from file X");
	CommandLine::declare_switch(DOMAIN_CLSW, L"domain", 2,
		L"specify folder to read/write inter files from/to");
	CommandLine::declare_switch(ARCHITECTURE_CLSW, L"architecture", 2,
		L"generate Inter with architecture X");
	CommandLine::declare_switch(ASSIMILATE_CLSW, L"assimilate", 2,
		L"assimilate (i.e., build) Inter kit X for the current architecture");

	pipeline_vars = CodeGen::Pipeline::basic_dictionary(I"output.i6");
		
	CommandLine::read(argc, argv, NULL, &Main::respond, &Main::add_file);

	if (template_action == ASSIMILATE_CLSW) {
		inter_architecture *A = CodeGen::Architecture::current();
		if (A == NULL) Errors::fatal("no -architecture given");
		filename *assim = Architectures::canonical_binary(kit_path, A);
		filename *assim_t = Architectures::canonical_textual(kit_path, A);
		pipeline_as_file = Filenames::in_folder(path_to_pipelines, I"assimilate.interpipeline");
		TEMPORARY_TEXT(fullname);
		WRITE_TO(fullname, "%f", assim);
		Str::copy(Dictionaries::create_text(pipeline_vars, I"*out"), fullname);
		Str::clear(fullname);
		WRITE_TO(fullname, "%f", assim_t);
		Str::copy(Dictionaries::create_text(pipeline_vars, I"*outt"), fullname);
		DISCARD_TEXT(fullname);
		Str::copy(Dictionaries::create_text(pipeline_vars, I"*attach"), Pathnames::directory_name(kit_path));
	}

	Main::act();

	@<Shut down the modules@>;

	if (Errors::have_occurred()) return 1;
	return 0;
}

@<Start up the modules@> =
	Foundation::start(); /* must be started first */
	ArchModule::start();
	InterModule::start();
	BuildingModule::start();
	CodegenModule::start();

@<Shut down the modules@> =
	InterModule::end();
	BuildingModule::end();
	CodegenModule::end();
	ArchModule::end();
	Foundation::end(); /* must be ended last */

@ =
void Main::respond(int id, int val, text_stream *arg, void *state) {
	switch (id) {
		case TEXTUAL_CLSW: output_textually = Filenames::from_text(arg); break;
		case BINARY_CLSW: output_binarily = Filenames::from_text(arg); pipeline_as_text = NULL; break;
		case PIPELINE_CLSW: pipeline_as_text = Str::duplicate(arg); break;
		case PIPELINE_FILE_CLSW: pipeline_as_file = Filenames::from_text(arg); break;
		case PIPELINE_VARIABLE_CLSW: {
			match_results mr = Regexp::create_mr();
			if (Regexp::match(&mr, arg, L"(%c+)=(%c+)")) {
				if (Str::get_first_char(arg) != '*') {
					Errors::fatal("-variable names must begin with '*'");
				} else {
					Str::copy(Dictionaries::create_text(pipeline_vars, mr.exp[0]), mr.exp[1]);
				}
			} else {
				Errors::fatal("-variable should take the form 'name=value'");
			}
			Regexp::dispose_of(&mr);
			break;
		}
		case DOMAIN_CLSW: domain_path = Pathnames::from_text(arg); pipeline_as_text = NULL; break;
		case ASSIMILATE_CLSW: kit_path = Pathnames::from_text(arg);
			pipeline_as_text = NULL; template_action = id; break;
		case TEST_CLSW: unit_test_file = Filenames::from_text(arg); break;
		case ARCHITECTURE_CLSW:
			if (CodeGen::Architecture::set(arg) == FALSE)
				Errors::fatal("no such -architecture");
			break;
	}
}

@ =
typedef struct inter_file {
	struct filename *inter_filename;
	MEMORY_MANAGEMENT
} inter_file;

void Main::add_file(int id, text_stream *arg, void *state) {
	inter_file *IF = CREATE(inter_file);
	IF->inter_filename = Filenames::from_text(arg);
}

@ =
void Main::act(void) {
	if ((pipeline_as_file) || (pipeline_as_text)) {
		if (NUMBER_CREATED(inter_file) > 0)
			Errors::fatal("-pipeline-text and -pipeline-file cannot be combined with inter file parameters");
		linked_list *inter_paths = NEW_LINKED_LIST(pathname);
		ADD_TO_LINKED_LIST(kit_path, pathname, inter_paths);
		codegen_pipeline *SS;
		if (pipeline_as_file) SS = CodeGen::Pipeline::parse_from_file(pipeline_as_file, pipeline_vars);
		else SS = CodeGen::Pipeline::parse(pipeline_as_text, pipeline_vars);
		if (SS) CodeGen::Pipeline::run(domain_path, SS, inter_paths, requirements_list);
		else Errors::fatal("pipeline could not be parsed");
	} else if (unit_test_file) {
		UnitTests::run(unit_test_file);
	} else {
		inter_tree *I = Inter::Tree::new();
		inter_file *IF;
		LOOP_OVER(IF, inter_file) {
			if (Inter::Binary::test_file(IF->inter_filename))
				Inter::Binary::read(I, IF->inter_filename);
			else
				Inter::Textual::read(I, IF->inter_filename);
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
	}
}
