[Main::] Main.

The top level, which decides what is to be done and then carries
this plan out.

@h Main routine.

@e TEXTUAL_CLSW
@e BINARY_CLSW
@e PIPELINE_CLSW
@e PIPELINE_FILE_CLSW
@e PIPELINE_VARIABLE_CLSW
@e DOMAIN_CLSW
@e TEMPLATE_CLSW
@e TEST_CLSW
@e ARCHITECTURE_CLSW
@e ASSIMILATE_CLSW

=
pathname *path_to_inter = NULL;
pathname *path_to_pipelines = NULL;
pathname *template_path = NULL;
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
	Foundation::start();
	InterModule::start();
	BuildingModule::start();
	CodegenModule::start();

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
	CommandLine::declare_switch(PIPELINE_CLSW, L"pipeline", 2,
		L"specify pipeline textually");
	CommandLine::declare_switch(PIPELINE_FILE_CLSW, L"pipeline-file", 2,
		L"specify pipeline from file X");
	CommandLine::declare_switch(PIPELINE_VARIABLE_CLSW, L"variable", 2,
		L"set pipeline variable X (in form name=value)");
	CommandLine::declare_switch(TEMPLATE_CLSW, L"template", 2,
		L"specify folder holding i6t template files");
	CommandLine::declare_switch(TEST_CLSW, L"test", 2,
		L"perform unit tests from file X");
	CommandLine::declare_switch(DOMAIN_CLSW, L"domain", 2,
		L"specify folder to read/write inter files from/to");
	CommandLine::declare_switch(ARCHITECTURE_CLSW, L"architecture", 2,
		L"generate inter with architecture X");
	CommandLine::declare_switch(ASSIMILATE_CLSW, L"assimilate", 2,
		L"assimilate I6T code into inter inside template X");

	pipeline_vars = CodeGen::Pipeline::basic_dictionary(I"output.i6");
		
	CommandLine::read(argc, argv, NULL, &Main::respond, &Main::add_file);

	if (template_action == ASSIMILATE_CLSW) {
		inter_library *lib = CodeGen::Libraries::new(template_path);
		text_stream *attach = CodeGen::Libraries::URL(lib);
		text_stream *name = CodeGen::Architecture::leafname();
		if (Str::len(name) == 0) Errors::fatal("no -architecture given");
		pipeline_as_file = Filenames::in_folder(path_to_pipelines, I"assimilate.interpipeline");
		TEMPORARY_TEXT(leafname);
		WRITE_TO(leafname, "%S.interb", name);
		filename *assim = Filenames::in_folder(template_path, leafname);
		TEMPORARY_TEXT(fullname);
		WRITE_TO(fullname, "%f", assim);
		Str::copy(Dictionaries::create_text(pipeline_vars, I"*out"), fullname);
		Str::clear(leafname);
		Str::clear(fullname);
		WRITE_TO(leafname, "%S.intert", name);
		filename *assim_t = Filenames::in_folder(template_path, leafname);
		WRITE_TO(fullname, "%f", assim_t);
		Str::copy(Dictionaries::create_text(pipeline_vars, I"*outt"), fullname);
		DISCARD_TEXT(leafname);
		DISCARD_TEXT(fullname);
		match_results mr = Regexp::create_mr();
		if (Regexp::match(&mr, attach, L"/main/(%c+)")) {
			Str::copy(Dictionaries::create_text(pipeline_vars, I"*attach"), mr.exp[0]);
		}
		Regexp::dispose_of(&mr);
	}

	Main::act();

	InterModule::end();
	BuildingModule::end();
	CodegenModule::end();
	Foundation::end();

	if (Errors::have_occurred()) return 1;
	return 0;
}

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
		case TEMPLATE_CLSW: template_path = Pathnames::from_text(arg); pipeline_as_text = NULL; break;
		case ASSIMILATE_CLSW: template_path = Pathnames::from_text(arg);
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
			Errors::fatal("-pipeline and -pipeline-file cannot be combined with inter file parameters");
		int NO_FS_AREAS = 0;
		pathname *pathname_of_inter_resources[1];
		if (template_path) { NO_FS_AREAS = 1; pathname_of_inter_resources[0] = template_path; }
		codegen_pipeline *SS;
		if (pipeline_as_file) SS = CodeGen::Pipeline::parse_from_file(pipeline_as_file, pipeline_vars);
		else SS = CodeGen::Pipeline::parse(pipeline_as_text, pipeline_vars);
		if (SS) CodeGen::Pipeline::run(domain_path, SS, NO_FS_AREAS, pathname_of_inter_resources, requirements_list);
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
